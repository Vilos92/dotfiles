"""Splitter tests on synthetic audio. Run: uv run --no-project --with numpy --with soundfile --with pytest pytest vocal-samples"""

import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from vocal_samples import POST_ROLL_SECONDS, PRE_ROLL_SECONDS, find_regions, pad_regions  # noqa: E402

RATE = 1000
TONE_FREQUENCY = 50
THRESHOLD_DB = -40.0


def tone(seconds: float, amplitude: float = 1.0) -> np.ndarray:
    t = np.arange(round(seconds * RATE)) / RATE
    return amplitude * np.sin(2 * np.pi * TONE_FREQUENCY * t)


def silence(seconds: float) -> np.ndarray:
    return np.zeros(round(seconds * RATE))


def regions_in_seconds(regions: list[tuple[int, int]]) -> list[tuple[float, float]]:
    return [(start / RATE, end / RATE) for start, end in regions]


def test_long_gap_splits_and_short_gap_merges():
    audio = np.concatenate(
        [
            silence(0.5),
            tone(1),
            silence(0.3),
            tone(1),
            silence(2),
            tone(0.5),
            silence(0.5),
        ]
    )

    regions = find_regions(audio, RATE, THRESHOLD_DB, gap_seconds=1.0)

    assert regions_in_seconds(regions) == [(0.5, 2.8), (4.8, 5.3)]


def test_quiet_sound_above_threshold_is_kept():
    audio = np.concatenate([tone(1), silence(2), tone(1, amplitude=0.05)])

    regions = find_regions(audio, RATE, THRESHOLD_DB, gap_seconds=1.0)

    assert len(regions) == 2


def test_silent_input_has_no_regions():
    assert find_regions(silence(3), RATE, THRESHOLD_DB, gap_seconds=1.0) == []


def test_padding_extends_both_ends():
    padded = pad_regions([(1000, 2000)], total_samples=5000, sample_rate=RATE)

    assert padded == [(1000 - PRE_ROLL_SECONDS * RATE, 2000 + POST_ROLL_SECONDS * RATE)]


def test_padding_stops_at_file_edges():
    assert pad_regions([(5, 4995)], total_samples=5000, sample_rate=RATE) == [(0, 5000)]


def test_padding_never_crosses_the_gap_midpoint():
    padded = pad_regions(
        [(1000, 2000), (2010, 3000)], total_samples=5000, sample_rate=RATE
    )

    assert padded[0][1] == 2005
    assert padded[1][0] == 2005
