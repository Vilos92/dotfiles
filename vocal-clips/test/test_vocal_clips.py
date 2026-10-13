"""Tests on synthetic projects and audio. Run: uv run --no-project --with numpy --with soundfile --with scipy --with pyloudnorm --with pytest pytest vocal-clips"""

import sqlite3
import struct
import sys
from pathlib import Path

import numpy as np
import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import vocal_clips  # noqa: E402
from vocal_clips import plan_names, read_tracks, slugify  # noqa: E402

FLOAT_FORMAT = 0x0004000F
RATE = 100


class Encoder:
    """Writes Audacity's binary project encoding, mirroring ProjectSerializer."""

    def __init__(self) -> None:
        self.ids: dict[str, int] = {}
        self.dict = bytearray([vocal_clips.FT_CHAR_SIZE, 4])
        self.doc = bytearray()

    def _id(self, name: str) -> int:
        if name not in self.ids:
            self.ids[name] = len(self.ids)
            encoded = name.encode("utf-32-le")
            self.dict += (
                struct.pack("<BHH", vocal_clips.FT_NAME, self.ids[name], len(encoded))
                + encoded
            )
        return self.ids[name]

    def start(self, tag: str, **attrs) -> "Encoder":
        self.doc += struct.pack("<BH", vocal_clips.FT_START_TAG, self._id(tag))
        for name, value in attrs.items():
            if isinstance(value, str):
                encoded = value.encode("utf-32-le")
                self.doc += (
                    struct.pack(
                        "<BHi", vocal_clips.FT_STRING, self._id(name), len(encoded)
                    )
                    + encoded
                )
            elif isinstance(value, float):
                self.doc += struct.pack(
                    "<BHdi", vocal_clips.FT_DOUBLE, self._id(name), value, 3
                )
            else:
                self.doc += struct.pack(
                    "<BHi", vocal_clips.FT_INT, self._id(name), value
                )
        return self

    def end(self, tag: str) -> "Encoder":
        self.doc += struct.pack("<BH", vocal_clips.FT_END_TAG, self._id(tag))
        return self


def write_project(path: Path, tracks: list[dict]) -> None:
    """tracks: [{"name", "linked", "clips": [{"offset", "blocks": [samples, ...] or block ids}]}]."""
    connection = sqlite3.connect(path)
    connection.executescript(
        """
        CREATE TABLE project(id INTEGER PRIMARY KEY, dict BLOB, doc BLOB);
        CREATE TABLE autosave(id INTEGER PRIMARY KEY, dict BLOB, doc BLOB);
        CREATE TABLE sampleblocks(blockid INTEGER PRIMARY KEY AUTOINCREMENT, sampleformat INTEGER, samples BLOB);
        """
    )
    encoder = Encoder().start("project", rate=float(RATE))
    for track in tracks:
        encoder.start(
            "wavetrack",
            name=track["name"],
            linked=track.get("linked", 0),
            rate=float(RATE),
        )
        for clip in track["clips"]:
            blocks = clip["blocks"]
            total = sum(len(block) for block in blocks)
            encoder.start(
                "waveclip", name=clip.get("name", "clip"), offset=clip["offset"]
            )
            encoder.start("sequence", numsamples=total)
            start = 0
            for block in blocks:
                if clip.get("silent"):
                    block_id = -1
                else:
                    cursor = connection.execute(
                        "INSERT INTO sampleblocks(sampleformat, samples) VALUES (?, ?)",
                        (FLOAT_FORMAT, np.asarray(block, dtype="<f4").tobytes()),
                    )
                    block_id = cursor.lastrowid
                encoder.start(
                    "waveblock", start=start, length=len(block), blockid=block_id
                ).end("waveblock")
                start += len(block)
            encoder.end("sequence").start("envelope", numpoints=0).end("envelope").end(
                "waveclip"
            )
        encoder.end("wavetrack")
    encoder.end("project")
    connection.execute(
        "INSERT INTO project VALUES (1, ?, ?)",
        (bytes(encoder.dict), bytes(encoder.doc)),
    )
    connection.commit()
    connection.close()


def test_reads_clips_across_blocks(tmp_path):
    project = tmp_path / "p.aup4"
    write_project(
        project,
        [
            {
                "name": "Lines",
                "clips": [
                    {"offset": 0.0, "blocks": [[0.1, 0.2], [0.3]]},
                    {"offset": 2.5, "blocks": [[0.4]]},
                ],
            },
            {"name": "Empty", "clips": []},
        ],
    )

    tracks, warnings = read_tracks(project)

    assert warnings == []
    assert [track.name for track in tracks] == ["Lines"]
    first, second = tracks[0].clips
    np.testing.assert_allclose(first.channels[0], [0.1, 0.2, 0.3], rtol=1e-6)
    assert second.start == 2.5


def test_joins_stereo_pair_into_one_track(tmp_path):
    project = tmp_path / "p.aup4"
    write_project(
        project,
        [
            {
                "name": "Stereo",
                "linked": 1,
                "clips": [{"offset": 0.0, "blocks": [[0.5, 0.5]]}],
            },
            {"name": "Stereo", "clips": [{"offset": 0.0, "blocks": [[-0.5, -0.5]]}]},
        ],
    )

    (track,) = read_tracks(project)[0]

    left, right = track.clips[0].channels
    np.testing.assert_allclose(left, [0.5, 0.5])
    np.testing.assert_allclose(right, [-0.5, -0.5])


def test_silent_blocks_read_as_zeros(tmp_path):
    project = tmp_path / "p.aup4"
    write_project(
        project,
        [
            {
                "name": "Gap",
                "clips": [{"offset": 0.0, "blocks": [[0.0] * 4], "silent": True}],
            }
        ],
    )

    (track,) = read_tracks(project)[0]

    np.testing.assert_array_equal(track.clips[0].channels[0], np.zeros(4))


def test_slugify_makes_safe_names():
    assert slugify("We'll get him next time, team!") == "we-ll-get-him-next-time-team"
    assert slugify("Café ☕") == "cafe"
    assert slugify("???") == "untitled"


MANIFEST = {
    "tracks": [
        {
            "number": 1,
            "clips": [
                {"number": 1, "file": "clips/t01/t01c01.wav"},
                {"number": 2, "file": "clips/t01/t01c02.wav"},
            ],
        },
        {"number": 2, "clips": [{"number": 1, "file": "clips/t02/t02c01.wav"}]},
    ]
}


def test_plan_names_numbers_folders_and_clips():
    names = {
        "tracks": [
            {"number": 1, "folder": "Zone lost", "clips": ["Zone lost", "Zone lost"]},
            {"number": 2, "folder": "Victory", "clips": ["Victory"]},
        ]
    }

    assert plan_names(MANIFEST, names) == [
        ("clips/t01/t01c01.wav", "01-zone-lost", "01-zone-lost.wav"),
        ("clips/t01/t01c02.wav", "01-zone-lost", "02-zone-lost.wav"),
        ("clips/t02/t02c01.wav", "02-victory", "01-victory.wav"),
    ]


def test_plan_names_rejects_missing_track_and_wrong_clip_count():
    names = {"tracks": [{"number": 1, "folder": "Zone lost", "clips": ["Zone lost"]}]}

    with pytest.raises(SystemExit) as error:
        plan_names(MANIFEST, names)

    assert "no entry for tracks [2]" in str(error.value)
    assert "track 1 has 2 clips but names.json gives 1 names" in str(error.value)


SAMPLE_RATE = 48000


def tone_with_silence(lead: float, voice: float, tail: float) -> np.ndarray:
    """A 300 Hz tone between stretches of quiet noise, shaped (samples, 1)."""
    rng = np.random.default_rng(0)
    total = round((lead + voice + tail) * SAMPLE_RATE)
    audio = rng.normal(0, 1e-4, total)
    start = round(lead * SAMPLE_RATE)
    t = np.arange(round(voice * SAMPLE_RATE)) / SAMPLE_RATE
    audio[start : start + len(t)] += 0.3 * np.sin(2 * np.pi * 300 * t)
    return audio.astype(np.float32)[:, None]


def test_trim_keeps_padding_around_voice_and_fades_edges():
    audio = tone_with_silence(lead=1.0, voice=1.0, tail=1.0)

    trimmed = vocal_clips.trim(audio, SAMPLE_RATE)

    expected = 1.0 + vocal_clips.PRE_ROLL_SECONDS + vocal_clips.POST_ROLL_SECONDS
    assert len(trimmed) / SAMPLE_RATE == pytest.approx(expected, abs=0.02)
    assert trimmed[0, 0] == 0
    assert trimmed[-1, 0] == 0


def test_level_hits_target_loudness():
    audio = tone_with_silence(lead=0.2, voice=2.0, tail=0.2) * 0.1

    leveled, gain_db, peak_capped = vocal_clips.level(audio, SAMPLE_RATE, -30.0)

    meter = vocal_clips.pyloudnorm.Meter(SAMPLE_RATE)
    assert meter.integrated_loudness(leveled) == pytest.approx(-30.0, abs=0.1)
    assert gain_db > 0
    assert not peak_capped


def test_level_caps_boost_and_peak():
    quiet = tone_with_silence(lead=0.2, voice=2.0, tail=0.2) * 0.01
    _, boost_db, _ = vocal_clips.level(quiet, SAMPLE_RATE, -20.0)
    assert boost_db == vocal_clips.MAX_BOOST_DB

    loud = tone_with_silence(lead=0.2, voice=2.0, tail=0.2) * 3
    leveled, _, peak_capped = vocal_clips.level(loud, SAMPLE_RATE, 0.0)
    assert peak_capped
    assert vocal_clips.to_db(float(np.abs(leveled).max())) == pytest.approx(
        vocal_clips.PEAK_CEILING_DBFS, abs=0.01
    )


def test_highpass_removes_rumble_and_keeps_voice():
    t = np.arange(SAMPLE_RATE) / SAMPLE_RATE
    rumble = np.sin(2 * np.pi * 30 * t)[:, None].astype(np.float32)
    voice = np.sin(2 * np.pi * 300 * t)[:, None].astype(np.float32)

    def rms(audio: np.ndarray) -> float:
        # Skip the filter's settling time at the start.
        return float(np.sqrt(np.mean(audio[SAMPLE_RATE // 10 :] ** 2)))

    assert rms(vocal_clips.highpass(rumble, SAMPLE_RATE, 80)) < 0.05 * rms(rumble)
    assert rms(vocal_clips.highpass(voice, SAMPLE_RATE, 80)) > 0.95 * rms(voice)


def test_trim_ignores_a_click_far_from_the_voice():
    audio = tone_with_silence(lead=1.5, voice=1.0, tail=0.5)
    click = round(0.2 * SAMPLE_RATE)
    audio[click : click + 48] = 0.5

    trimmed = vocal_clips.trim(audio, SAMPLE_RATE)

    expected = 1.0 + vocal_clips.PRE_ROLL_SECONDS + vocal_clips.POST_ROLL_SECONDS
    assert len(trimmed) / SAMPLE_RATE == pytest.approx(expected, abs=0.02)


def quiet_breath_then_line(breath_amplitude: float) -> np.ndarray:
    """A 0.2 s sound, 1 s of near-silence, then a 1 s line."""
    audio = tone_with_silence(lead=1.5, voice=1.0, tail=0.5)
    start = round(0.3 * SAMPLE_RATE)
    t = np.arange(round(0.2 * SAMPLE_RATE)) / SAMPLE_RATE
    audio[start : start + len(t), 0] += breath_amplitude * np.sin(2 * np.pi * 300 * t)
    return audio


def test_trim_drops_a_quiet_sound_well_before_the_line():
    trimmed = vocal_clips.trim(quiet_breath_then_line(0.01), SAMPLE_RATE)

    expected = 1.0 + vocal_clips.PRE_ROLL_SECONDS + vocal_clips.POST_ROLL_SECONDS
    assert len(trimmed) / SAMPLE_RATE == pytest.approx(expected, abs=0.02)


def test_trim_keeps_a_loud_phrase_before_a_pause():
    trimmed = vocal_clips.trim(quiet_breath_then_line(0.3), SAMPLE_RATE)

    # From the first phrase at 0.3 s through the end of the line.
    expected = 2.2 + vocal_clips.PRE_ROLL_SECONDS + vocal_clips.POST_ROLL_SECONDS
    assert len(trimmed) / SAMPLE_RATE == pytest.approx(expected, abs=0.02)
