#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["numpy", "soundfile"]
# ///
"""Separate a song's vocals and cut the vocal stem into one WAV file per phrase.

Usage: vocal-samples <input audio file> <output directory>

Writes <output directory>/<input name>/ containing stems/ (the separated
stems) and samples/ (the vocal phrases, named by their start time).
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
import soundfile as sf

# Highest vocal SDR (signal-to-distortion ratio) in `audio-separator -l`.
DEFAULT_MODEL = "vocals_mel_band_roformer.ckpt"
# audio-separator defaults to /tmp, which macOS clears, forcing a re-download.
CACHE_HOME = Path(os.environ.get("XDG_CACHE_HOME", "~/.cache")).expanduser()
MODEL_DIR = Path(
    os.environ.get("AUDIO_SEPARATOR_MODEL_DIR", CACHE_HOME / "audio-separator-models")
).expanduser()

# Silence must last this long to end a sample. Tuned on real stems: breaths
# inside a phrase ran up to about 0.45 s, and breaks between phrases from 0.5 s.
DEFAULT_GAP_SECONDS = 0.5
# Relative to the loudest frame, so quiet and loud stems split alike.
DEFAULT_THRESHOLD_DB = -40.0
# Quiet consonant attacks start below the threshold, and tails decay below it.
PRE_ROLL_SECONDS = 0.02
POST_ROLL_SECONDS = 0.15
FRAME_SECONDS = 0.01

# audio-separator copies the input's bit depth, so a 24-bit input yields 24-bit stems.
INTERMEDIATE_CODEC = "pcm_s24le"
STEM_NAMES = {
    stem: stem.lower()
    for stem in ("Vocals", "Instrumental", "Other", "Drums", "Bass", "Guitar", "Piano")
}
VOCALS_STEM = "vocals"
# Two-stem vocal models call everything else "other", which is the instrumental.
TWO_STEM_RENAMES = {"other.wav": "instrumental.wav"}
REQUIRED_COMMANDS = ("audio-separator", "ffmpeg")
MIN_INDEX_WIDTH = 3


def find_regions(
    mono: np.ndarray, sample_rate: int, threshold_db: float, gap_seconds: float
) -> list[tuple[int, int]]:
    """Return (start, end) sample indices of sounding regions, merging gaps shorter than gap_seconds."""
    frame_length = max(1, round(sample_rate * FRAME_SECONDS))
    frame_count = len(mono) // frame_length
    if frame_count == 0:
        return []

    frames = mono[: frame_count * frame_length].reshape(frame_count, frame_length)
    rms = np.sqrt(np.mean(np.square(frames, dtype=np.float64), axis=1))
    peak = rms.max()
    if peak == 0:
        return []

    sounding = 20 * np.log10(np.maximum(rms, 1e-12) / peak) > threshold_db
    # Edges of each run of sounding frames: +1 marks a start, -1 marks an end.
    edges = np.diff(np.concatenate(([0], sounding.astype(np.int8), [0])))
    starts = np.flatnonzero(edges == 1)
    ends = np.flatnonzero(edges == -1)

    min_gap_frames = gap_seconds / FRAME_SECONDS
    regions: list[list[int]] = []
    for start, end in zip(starts, ends):
        if regions and start - regions[-1][1] < min_gap_frames:
            regions[-1][1] = end
            continue
        regions.append([start, end])

    return [
        (start * frame_length, min(end * frame_length, len(mono)))
        for start, end in regions
    ]


def pad_regions(
    regions: list[tuple[int, int]], total_samples: int, sample_rate: int
) -> list[tuple[int, int]]:
    """Extend each region by the pre-roll and post-roll without crossing into a neighbor's gap half."""
    pre_roll = round(sample_rate * PRE_ROLL_SECONDS)
    post_roll = round(sample_rate * POST_ROLL_SECONDS)
    padded = []
    for index, (start, end) in enumerate(regions):
        floor = 0 if index == 0 else (regions[index - 1][1] + start) // 2
        ceiling = (
            total_samples
            if index == len(regions) - 1
            else (end + regions[index + 1][0]) // 2
        )
        padded.append((max(floor, start - pre_roll), min(ceiling, end + post_roll)))
    return padded


def format_timestamp(seconds: float) -> str:
    minutes, remainder = divmod(seconds, 60)
    return f"{int(minutes)}m{remainder:04.1f}s"


def check_prerequisites(input_path: Path, song_dir: Path) -> list[str]:
    problems = [
        f"`{command}` not found on PATH"
        for command in REQUIRED_COMMANDS
        if shutil.which(command) is None
    ]
    if not input_path.is_file():
        problems.append(f"input file not found: {input_path}")
    if song_dir.exists():
        problems.append(f"output folder already exists: {song_dir}")
    return problems


def separate(input_path: Path, stems_dir: Path, model: str) -> Path:
    stems_dir.mkdir(parents=True)
    with tempfile.TemporaryDirectory() as temp_dir:
        intermediate = Path(temp_dir) / f"{input_path.stem}.wav"
        subprocess.run(
            [
                "ffmpeg",
                "-v",
                "error",
                "-i",
                str(input_path),
                "-map",
                "0:a:0",
                "-c:a",
                INTERMEDIATE_CODEC,
                str(intermediate),
            ],
            check=True,
        )
        subprocess.run(
            [
                "audio-separator",
                str(intermediate),
                "--model_filename",
                model,
                "--model_file_dir",
                str(MODEL_DIR),
                "--output_dir",
                str(stems_dir),
                "--output_format",
                "WAV",
                "--custom_output_names",
                json.dumps(STEM_NAMES),
                "--log_level",
                "warning",
            ],
            check=True,
        )

    vocals = stems_dir / f"{VOCALS_STEM}.wav"
    if not vocals.is_file():
        raise SystemExit(f"error: model {model} produced no vocal stem in {stems_dir}")

    stems = list(stems_dir.iterdir())
    if len(stems) == 2:
        for stem in stems:
            if stem.name in TWO_STEM_RENAMES:
                stem.rename(stems_dir / TWO_STEM_RENAMES[stem.name])
    return vocals


def write_samples(
    vocals: Path, samples_dir: Path, threshold_db: float, gap_seconds: float
) -> int:
    audio, sample_rate = sf.read(vocals, dtype="float32", always_2d=True)
    subtype = sf.info(vocals).subtype
    regions = find_regions(audio.mean(axis=1), sample_rate, threshold_db, gap_seconds)
    regions = pad_regions(regions, len(audio), sample_rate)

    samples_dir.mkdir(parents=True)
    width = max(MIN_INDEX_WIDTH, len(str(len(regions))))
    for number, (start, end) in enumerate(regions, start=1):
        name = f"{number:0{width}d}_{format_timestamp(start / sample_rate)}.wav"
        sf.write(samples_dir / name, audio[start:end], sample_rate, subtype=subtype)
    return len(regions)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="vocal-samples",
        description="Separate a song's vocals and cut them into one WAV file per phrase.",
    )
    parser.add_argument(
        "input", type=Path, help="audio file to process (any format ffmpeg reads)"
    )
    parser.add_argument(
        "output", type=Path, help="folder to create the song's folder in"
    )
    parser.add_argument(
        "--gap",
        type=float,
        default=DEFAULT_GAP_SECONDS,
        help=f"seconds of silence that end a sample (default: {DEFAULT_GAP_SECONDS})",
    )
    parser.add_argument(
        "--threshold",
        type=float,
        default=DEFAULT_THRESHOLD_DB,
        help=f"dB below the loudest moment that counts as silence (default: {DEFAULT_THRESHOLD_DB})",
    )
    parser.add_argument(
        "--model",
        default=DEFAULT_MODEL,
        help=f"audio-separator model; list them with `audio-separator -l` (default: {DEFAULT_MODEL})",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    input_path = args.input.expanduser().resolve()
    song_dir = args.output.expanduser().resolve() / input_path.stem

    problems = check_prerequisites(input_path, song_dir)
    if problems:
        sys.exit("\n".join(f"error: {problem}" for problem in problems))

    print(f"Separating stems with {args.model} (this takes a few minutes)...")
    vocals = separate(input_path, song_dir / "stems", args.model)
    count = write_samples(vocals, song_dir / "samples", args.threshold, args.gap)
    print(f"Wrote {count} samples to {song_dir / 'samples'}")


if __name__ == "__main__":
    main()
