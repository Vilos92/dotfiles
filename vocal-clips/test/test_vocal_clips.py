"""Tests on synthetic projects. Run: uv run --no-project --with numpy --with soundfile --with pytest pytest vocal-clips"""

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
