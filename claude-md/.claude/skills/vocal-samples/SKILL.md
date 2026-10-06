---
name: vocal-samples
description: Cut a song's vocals into phrase-length WAV samples with the `vocal-samples` tool, choosing the gap and threshold settings for that specific track from its measured silences instead of relying on the defaults. Trigger when Greg asks to extract, chop, or split vocal samples or acapellas from a song or album, to tune `vocal-samples` settings, or says a song's samples came out too long, too short, or too few.
---

# vocal-samples

`vocal-samples <audio file> <output dir>` separates a song's vocals and splits the
vocal stem at silences, writing `<output dir>/<song>/stems/` and `samples/`.
Greg loads the samples into Ableton and makes the fine cuts there, so the goal is
clean phrase-length chunks with nothing lost, not the finest possible split.

## Workflow

1. **Measure.** Run `vocal-samples <file> <dir> --analyze`. The first run on a song
   separates it (about half the song's length, plus a one-time 913 MB model
   download). Later runs reuse `stems/` and take under a second. It prints:
   - the silent gaps in the vocal stem at the current threshold, longest first
   - a table of sample count, short samples, median and longest length, and
     coverage for each threshold and gap pair

2. **Choose the gap.** Gaps fall into two groups: short ones inside a phrase
   (breaths, consonant stops) and longer ones between phrases. Set `--gap`
   between the groups.
   - On the reference tracks, in-phrase gaps ran up to about 0.45 s and phrase
     breaks started at 0.5 s, hence the 0.5 s default.
   - If there is no clear divide, keep 0.5 s.
   - The gap list reflects one threshold. To see gaps at another, re-run
     `--analyze --threshold <dB>`.

3. **Choose the threshold.** Start at -40 dB, the default. Move toward -25 dB
   only when samples are too long to work with: a longest sample over about 60 s,
   or a median over about 20 s.
   - **Coverage is the cost.** It is the share of the song inside some sample.
     A stricter threshold reclassifies quiet vocals (soft tails, backing ad-libs,
     the ends of held notes) as silence and drops them from every sample. Stay
     within about 5 points of the -40 dB coverage unless Greg accepts the loss.
   - A rising `<0.5s` count means the setting is chopping fragments.
   - Avoid -45 and -50 dB. Lower thresholds start counting the faint separation
     residue as sound.

4. **Write.** Run with the chosen `--gap` and `--threshold`. Add
   `--replace-samples` when `samples/` already exists. **That flag deletes the
   existing samples. If Greg may have curated that folder, ask first.**

5. **Report.** State the settings, the evidence for them (the gap divide, sample
   count, median and longest length, coverage versus the default), and the
   output path. If the defaults were already right, say so.

For an album, analyze every track first, then write. Most tracks need only the
defaults.

## Reference results

Measured on *Spirits Having Flown* (Bee Gees, 1979):

| Track | Vocals | Defaults (-40 dB, 0.5 s) | Better choice |
| --- | --- | --- | --- |
| Until | sparse | 21 samples, median 3.1 s, coverage 61% | defaults |
| Tragedy | dense | 16 samples, median 13.4 s, longest 34 s, coverage 67% | defaults |
| Too Much Heaven | near-continuous harmonies | 6 samples, longest 145 s, coverage 91% | -30 dB, 0.5 s: 17 samples, longest 50 s, coverage 87% |

On "Too Much Heaven", -30 dB with a 0.3 s gap gives 45 samples, but it drops coverage to
83% and produces 10 fragments under 0.5 s. Prefer -30 dB with 0.5 s.

## Leave alone

- **The model.** The default, `vocals_mel_band_roformer.ckpt`, has the best vocal
  score available. Change it only if Greg asks. `stems/model.txt` records the
  model, and a mismatch is refused until `stems/` is deleted, which forces a new
  separation.
- **`stems/`.** Never delete it to "start fresh". Re-separating costs minutes and
  changes nothing about the split.
