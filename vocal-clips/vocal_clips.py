#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["numpy", "soundfile"]
# ///
"""Export every clip in an Audacity project as its own WAV file, transcribed.

Usage:
  vocal-clips extract <project.aup3|.aup4> <output directory>
  vocal-clips apply <project output directory> <names.json>

`extract` writes <output directory>/<project name>/ containing clips/ (one
folder per track, one WAV per clip), transcripts/, and manifest.json.
`apply` writes the clips into samples/ under the folder and file names given
in names.json, with low-frequency rumble filtered out. An LLM writes
names.json from the transcripts in manifest.json.
"""

import argparse
import json
import re
import shutil
import sqlite3
import struct
import subprocess
import sys
import unicodedata
from dataclasses import dataclass, field
from pathlib import Path

import numpy as np
import soundfile as sf

# Field types in Audacity's binary project encoding (ProjectSerializer.cpp).
FT_CHAR_SIZE = 0
FT_START_TAG = 1
FT_END_TAG = 2
FT_STRING = 3
FT_INT = 4
FT_BOOL = 5
FT_LONG = 6
FT_LONG_LONG = 7
FT_SIZE_T = 8
FT_FLOAT = 9
FT_DOUBLE = 10
FT_DATA = 11
FT_RAW = 12
FT_PUSH = 13
FT_POP = 14
FT_NAME = 15
# Added in Audacity 4 for binary attributes such as the project thumbnail.
FT_BINARY = 16

STRING_ENCODINGS = {1: "utf-8", 2: "utf-16-le", 4: "utf-32-le"}
# Audacity's sampleFormat values: the width in bytes sits in the high 16 bits.
SAMPLE_FORMATS = {0x00020001: "<i2", 0x00040001: "<i4", 0x0004000F: "<f4"}
INT16_SCALE = 2**15
# int24 samples are stored left-aligned in 32 bits.
INT24_SCALE = 2**31
INT_FORMAT_SCALES = {0x00020001: INT16_SCALE, 0x00040001: INT24_SCALE}

TRANSCRIBE_COMMAND = "parakeet-mlx"
MANIFEST = "manifest.json"
CLIPS_DIR = "clips"
TRANSCRIPTS_DIR = "transcripts"
SAMPLES_DIR = "samples"
MIN_INDEX_WIDTH = 2
MAX_SLUG_LENGTH = 60
# Measured on real takes: 94% of the noise between words sat below 120 Hz, as room
# rumble rather than hiss. An 80 Hz cut lowered the noise floor about 13 dB and left
# speech untouched. Two passes make a steeper 24 dB per octave slope.
DEFAULT_HIGHPASS_HZ = 80
HIGHPASS_PASSES = 2


@dataclass
class Node:
    tag: str
    attrs: dict = field(default_factory=dict)
    children: list["Node"] = field(default_factory=list)

    def find_all(self, tag: str) -> list["Node"]:
        return [child for child in self.children if child.tag == tag]


@dataclass
class Clip:
    name: str
    start: float
    # One array per channel, all the same length.
    channels: list[np.ndarray]


@dataclass
class Track:
    name: str
    rate: int
    clips: list[Clip]


def decode_document(dict_blob: bytes, doc_blob: bytes) -> Node:
    """Decode Audacity's binary-encoded project XML into a tree."""
    names: dict[int, str] = {}
    encoding = STRING_ENCODINGS[1]
    root = Node("#document")
    stack = [root]

    for blob in (dict_blob, doc_blob):
        offset = 0
        while offset < len(blob):
            field_type = blob[offset]
            offset += 1

            if field_type == FT_CHAR_SIZE:
                encoding = STRING_ENCODINGS[blob[offset]]
                offset += 1
            elif field_type == FT_NAME:
                name_id, length = struct.unpack_from("<HH", blob, offset)
                offset += 4
                names[name_id] = blob[offset : offset + length].decode(encoding)
                offset += length
            elif field_type in (FT_PUSH, FT_POP):
                continue
            elif field_type == FT_START_TAG:
                (name_id,) = struct.unpack_from("<H", blob, offset)
                offset += 2
                node = Node(names[name_id])
                stack[-1].children.append(node)
                stack.append(node)
            elif field_type == FT_END_TAG:
                offset += 2
                stack.pop()
            elif field_type in (FT_DATA, FT_RAW):
                (length,) = struct.unpack_from("<i", blob, offset)
                offset += 4 + length
            else:
                offset = _read_attribute(
                    blob, offset, field_type, names, encoding, stack[-1]
                )

    return root


def _read_attribute(
    blob: bytes,
    offset: int,
    field_type: int,
    names: dict[int, str],
    encoding: str,
    node: Node,
) -> int:
    (name_id,) = struct.unpack_from("<H", blob, offset)
    offset += 2
    name = names[name_id]

    if field_type in (FT_STRING, FT_BINARY):
        (length,) = struct.unpack_from("<i", blob, offset)
        offset += 4
        raw = blob[offset : offset + length]
        # Audacity writes some attributes twice (wavetrack `gain`). Keep the first.
        node.attrs.setdefault(
            name, raw.decode(encoding) if field_type == FT_STRING else raw
        )
        return offset + length

    layouts = {
        FT_INT: "<i",
        FT_BOOL: "<?",
        FT_LONG: "<i",
        FT_LONG_LONG: "<q",
        FT_SIZE_T: "<I",
        # Floats and doubles carry a trailing digit count for display.
        FT_FLOAT: "<fi",
        FT_DOUBLE: "<di",
    }
    if field_type not in layouts:
        raise ValueError(f"unknown field type {field_type} at byte {offset - 3}")
    layout = layouts[field_type]
    node.attrs.setdefault(name, struct.unpack_from(layout, blob, offset)[0])
    return offset + struct.calcsize(layout)


def read_block(
    connection: sqlite3.Connection, block_id: int, length: int
) -> np.ndarray:
    # Audacity stores runs of silence as negative block ids with no row.
    if block_id < 0:
        return np.zeros(length, dtype=np.float32)

    row = connection.execute(
        "SELECT sampleformat, samples FROM sampleblocks WHERE blockid = ?", (block_id,)
    ).fetchone()
    if row is None:
        raise SystemExit(f"error: sample block {block_id} is missing from the project")
    sample_format, samples = row
    if sample_format not in SAMPLE_FORMATS:
        raise SystemExit(f"error: unsupported sample format {sample_format:#x}")

    data = np.frombuffer(samples, dtype=SAMPLE_FORMATS[sample_format])
    if sample_format in INT_FORMAT_SCALES:
        return (data / INT_FORMAT_SCALES[sample_format]).astype(np.float32)
    return data.astype(np.float32)


def read_clip_channel(
    connection: sqlite3.Connection, clip: Node, rate: int
) -> np.ndarray:
    (sequence,) = clip.find_all("sequence")
    total = int(sequence.attrs["numsamples"])
    audio = np.zeros(total, dtype=np.float32)
    for block in sequence.find_all("waveblock"):
        start = int(block.attrs["start"])
        length = int(block.attrs.get("length", total - start))
        samples = read_block(connection, int(block.attrs["blockid"]), length)
        audio[start : start + len(samples)] = samples[: total - start]

    trim_start = round(float(clip.attrs.get("trimLeft", 0)) * rate)
    trim_end = total - round(float(clip.attrs.get("trimRight", 0)) * rate)
    return audio[trim_start:trim_end]


def check_clip_is_plain(track_name: str, clip: Node) -> None:
    """Refuse clips whose sound depends on processing this tool does not reproduce."""
    name = clip.attrs.get("name", "")
    if float(clip.attrs.get("clipStretchRatio", 1.0)) != 1.0:
        raise SystemExit(
            f"error: clip {name!r} in {track_name!r} is time-stretched; render it in Audacity first"
        )
    if int(clip.attrs.get("centShift", 0)) != 0:
        raise SystemExit(
            f"error: clip {name!r} in {track_name!r} is pitch-shifted; render it in Audacity first"
        )


def read_tracks(project: Path) -> tuple[list[Track], list[str]]:
    """Read every wave track and its clips. Returns the tracks and any warnings."""
    warnings = []
    # A single read transaction sees one consistent state even while Audacity has the file open.
    connection = sqlite3.connect(f"file:{project}?mode=ro", uri=True)
    try:
        connection.execute("BEGIN")
        if connection.execute("SELECT count(*) FROM autosave").fetchone()[0]:
            warnings.append(
                "the project has unsaved changes; using the last saved version"
            )
        row = connection.execute("SELECT dict, doc FROM project").fetchone()
        if row is None:
            raise SystemExit(f"error: {project} contains no saved project")
        (project_node,) = decode_document(*row).find_all("project")

        tracks = []
        wave_tracks = project_node.find_all("wavetrack")
        index = 0
        while index < len(wave_tracks):
            first = wave_tracks[index]
            # The left channel of a stereo pair is linked, and the right channel follows it.
            channel_nodes = (
                wave_tracks[index : index + 2]
                if int(first.attrs.get("linked", 0))
                else [first]
            )
            index += len(channel_nodes)

            name = first.attrs["name"]
            rate = round(float(first.attrs["rate"]))
            clips = []
            for clip_index, clip in enumerate(first.find_all("waveclip")):
                check_clip_is_plain(name, clip)
                if clip.find_all("envelope")[0].attrs.get("numpoints", 0):
                    warnings.append(
                        f"clip {clip.attrs['name']!r} has a volume envelope, which is not applied"
                    )
                channels = [
                    read_clip_channel(
                        connection, node.find_all("waveclip")[clip_index], rate
                    )
                    for node in channel_nodes
                ]
                start = float(clip.attrs["offset"]) + float(
                    clip.attrs.get("trimLeft", 0)
                )
                clips.append(Clip(clip.attrs["name"], start, channels))
            if clips:
                tracks.append(Track(name, rate, clips))
        return tracks, warnings
    finally:
        connection.close()


def transcribe(clip_files: list[Path], transcripts_dir: Path) -> None:
    transcripts_dir.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            TRANSCRIBE_COMMAND,
            *map(str, clip_files),
            "--output-format",
            "txt",
            "--output-dir",
            str(transcripts_dir),
        ],
        check=True,
    )


def extract(project: Path, output_dir: Path, replace: bool) -> None:
    problems = []
    if not project.is_file():
        problems.append(f"project not found: {project}")
    if shutil.which(TRANSCRIBE_COMMAND) is None:
        problems.append(
            f"`{TRANSCRIBE_COMMAND}` not found on PATH (install it with the brews TUI)"
        )
    if output_dir.exists() and not replace:
        problems.append(
            f"output already exists: {output_dir} (pass --replace to rebuild it)"
        )
    if problems:
        sys.exit("\n".join(f"error: {problem}" for problem in problems))

    tracks, warnings = read_tracks(project)
    for warning in warnings:
        print(f"warning: {warning}", file=sys.stderr)

    if output_dir.exists():
        shutil.rmtree(output_dir)
    clips_dir = output_dir / CLIPS_DIR
    track_width = max(MIN_INDEX_WIDTH, len(str(len(tracks))))
    manifest_tracks = []
    clip_files = []
    for track_number, track in enumerate(tracks, start=1):
        track_id = f"t{track_number:0{track_width}d}"
        (clips_dir / track_id).mkdir(parents=True)
        clip_width = max(MIN_INDEX_WIDTH, len(str(len(track.clips))))
        manifest_clips = []
        for clip_number, clip in enumerate(track.clips, start=1):
            clip_id = f"{track_id}c{clip_number:0{clip_width}d}"
            path = clips_dir / track_id / f"{clip_id}.wav"
            # Float WAV keeps Audacity's 32-bit float samples bit for bit.
            sf.write(path, np.stack(clip.channels, axis=1), track.rate, subtype="FLOAT")
            clip_files.append(path)
            manifest_clips.append(
                {
                    "number": clip_number,
                    "id": clip_id,
                    "file": str(path.relative_to(output_dir)),
                    "audacity_name": clip.name,
                    "start_seconds": round(clip.start, 3),
                    "duration_seconds": round(len(clip.channels[0]) / track.rate, 3),
                }
            )
        manifest_tracks.append(
            {
                "number": track_number,
                "audacity_name": track.name,
                "channels": len(track.clips[0].channels),
                "clips": manifest_clips,
            }
        )

    print(f"Transcribing {len(clip_files)} clips with {TRANSCRIBE_COMMAND}...")
    transcripts_dir = output_dir / TRANSCRIPTS_DIR
    transcribe(clip_files, transcripts_dir)
    for track in manifest_tracks:
        for clip in track["clips"]:
            transcript = transcripts_dir / f"{clip['id']}.txt"
            clip["transcript"] = (
                transcript.read_text().strip() if transcript.is_file() else ""
            )

    manifest = {"project": str(project), "tracks": manifest_tracks}
    (output_dir / MANIFEST).write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Wrote {len(clip_files)} clips from {len(tracks)} tracks to {output_dir}")
    print(f"Transcripts are in {output_dir / MANIFEST}")


def slugify(text: str) -> str:
    """Turn free text into a lowercase, hyphenated, ASCII file name fragment."""
    ascii_text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()
    slug = re.sub(r"[^a-z0-9]+", "-", ascii_text.lower()).strip("-")
    return slug[:MAX_SLUG_LENGTH].rstrip("-") or "untitled"


def plan_names(manifest: dict, names: dict) -> list[tuple[str, str, str]]:
    """Validate names.json against the manifest. Returns (clip file, folder, file name) per clip."""
    named_tracks = {track["number"]: track for track in names.get("tracks", [])}
    expected = {track["number"] for track in manifest["tracks"]}
    problems = []
    if missing := sorted(expected - named_tracks.keys()):
        problems.append(f"names.json has no entry for tracks {missing}")
    if extra := sorted(named_tracks.keys() - expected):
        problems.append(f"names.json names tracks that do not exist: {extra}")

    track_width = max(MIN_INDEX_WIDTH, len(str(len(manifest["tracks"]))))
    plan = []
    for track in manifest["tracks"]:
        named = named_tracks.get(track["number"])
        if named is None:
            continue
        clip_names = named.get("clips", [])
        if len(clip_names) != len(track["clips"]):
            problems.append(
                f"track {track['number']} has {len(track['clips'])} clips but names.json gives {len(clip_names)} names"
            )
            continue
        folder = f"{track['number']:0{track_width}d}-{slugify(named.get('folder', ''))}"
        clip_width = max(MIN_INDEX_WIDTH, len(str(len(track["clips"]))))
        for clip, clip_name in zip(track["clips"], clip_names):
            plan.append(
                (
                    clip["file"],
                    folder,
                    f"{clip['number']:0{clip_width}d}-{slugify(clip_name)}.wav",
                )
            )

    if problems:
        sys.exit("\n".join(f"error: {problem}" for problem in problems))
    return plan


def write_sample(source: Path, destination: Path, highpass_hz: int) -> None:
    if highpass_hz == 0:
        shutil.copy2(source, destination)
        return
    audio_filter = ",".join([f"highpass=f={highpass_hz}"] * HIGHPASS_PASSES)
    subprocess.run(
        ["ffmpeg", "-v", "error", "-i", str(source), "-af", audio_filter]
        + ["-c:a", "pcm_f32le", str(destination)],
        check=True,
    )


def apply(project_dir: Path, names_path: Path, replace: bool, highpass_hz: int) -> None:
    manifest_path = project_dir / MANIFEST
    if not manifest_path.is_file():
        sys.exit(
            f"error: no {MANIFEST} in {project_dir}; run `vocal-clips extract` first"
        )
    samples_dir = project_dir / SAMPLES_DIR
    if samples_dir.exists() and not replace:
        sys.exit(
            f"error: samples folder already exists: {samples_dir} (pass --replace to rewrite it)"
        )

    if highpass_hz and shutil.which("ffmpeg") is None:
        sys.exit("error: `ffmpeg` not found on PATH (or pass --highpass 0)")

    manifest = json.loads(manifest_path.read_text())
    plan = plan_names(manifest, json.loads(names_path.read_text()))

    if samples_dir.exists():
        shutil.rmtree(samples_dir)
    for clip_file, folder, file_name in plan:
        source = project_dir / clip_file
        (samples_dir / folder).mkdir(parents=True, exist_ok=True)
        write_sample(source, samples_dir / folder / file_name, highpass_hz)
    print(f"Wrote {len(plan)} named clips to {samples_dir}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="vocal-clips",
        description="Export every clip in an Audacity project as its own transcribed WAV file.",
    )
    commands = parser.add_subparsers(dest="command", required=True)

    extract_parser = commands.add_parser(
        "extract",
        help="write one WAV per clip, transcribe them, and write manifest.json",
    )
    extract_parser.add_argument(
        "project", type=Path, help="Audacity project (.aup3 or .aup4)"
    )
    extract_parser.add_argument(
        "output", type=Path, help="folder to create the project's folder in"
    )
    extract_parser.add_argument(
        "--replace",
        action="store_true",
        help="delete and rebuild an existing project folder",
    )

    apply_parser = commands.add_parser(
        "apply",
        help="write the clips into samples/ under the names in names.json, high-passed",
    )
    apply_parser.add_argument(
        "project_dir", type=Path, help="the folder `extract` created"
    )
    apply_parser.add_argument(
        "names", type=Path, help="JSON naming each track's folder and clips"
    )
    apply_parser.add_argument(
        "--replace",
        action="store_true",
        help="delete and rewrite an existing samples folder",
    )
    apply_parser.add_argument(
        "--highpass",
        type=int,
        default=DEFAULT_HIGHPASS_HZ,
        help=f"cut rumble below this frequency in Hz, 0 to copy clips unfiltered (default: {DEFAULT_HIGHPASS_HZ})",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if args.command == "extract":
        project = args.project.expanduser().resolve()
        output_dir = args.output.expanduser().resolve() / project.stem
        extract(project, output_dir, args.replace)
        return
    apply(
        args.project_dir.expanduser().resolve(),
        args.names.expanduser().resolve(),
        args.replace,
        args.highpass,
    )


if __name__ == "__main__":
    main()
