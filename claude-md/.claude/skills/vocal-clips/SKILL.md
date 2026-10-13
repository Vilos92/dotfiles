---
name: vocal-clips
description: Break an Audacity project (.aup3 or .aup4) into one WAV file per clip, transcribe each clip, and name every file and track folder from what is said, using the `vocal-clips` tool. Trigger when Greg asks to export, split, break out, or name the clips or recordings in an Audacity project, or to sort voice takes into named folders.
---

# vocal-clips

`vocal-clips` reads an Audacity project directly. Audacity does not need to
be running, and the project is opened read-only. Each clip in a track is one
recording, and each track becomes one folder. The tool does the mechanical
parts. You do the naming.

## Workflow

1. **Extract.** Run `vocal-clips extract <project> <output dir>`. Ask Greg
   for the output folder if he hasn't named one. This writes
   `<output dir>/<project name>/` with `clips/`, `transcripts/` and
   `manifest.json`, and it takes about two minutes for 100 short clips.
   The first run also downloads the speech model. Pass on any warning it
   prints, such as unsaved changes or an unapplied volume envelope.

2. **Read the transcripts.** One line per track is enough:

   ```sh
   jq -r '.tracks[] | "\(.number): " + ([.clips[].transcript] | join(" | "))' <dir>/manifest.json
   ```

3. **Name everything.** Write `<dir>/names.json`:

   ```json
   {"tracks": [{"number": 4, "folder": "Zone captured", "clips": ["Zone taken", "Zone captured"]}]}
   ```

   - Give every track an entry, and give each one exactly as many clip names
     as it has clips, in order.
   - **Folder:** what the track's clips have in common, in two to five words.
     Usually that's the line being performed.
   - **Clip:** what that clip actually says, shortened to about six words.
     Keep real wording differences between takes ("Zone taken" against "Zone
     captured"). Identical takes get identical names. The tool adds number
     prefixes, so they never collide.
   - **Fix obvious mishearings from context.** Other takes in the same track
     show what was meant. "Take the zout" next to three takes of "take the
     zone" is "take the zone".
   - Name an empty transcript `Untranscribed`, and call a clip that's clearly
     off-script, such as swearing or a false start, an `Outtake`. Keep
     outtakes: Greg removes them himself.
   - Write plain text. The tool turns names into safe, lowercase,
     hyphenated file names.

4. **Apply.** Run `vocal-clips apply <dir> <dir>/names.json`. It writes the
   clips into `<dir>/samples/<NN-folder>/<NN-clip>.wav` and never alters
   `clips/`, so renaming is always safe to redo with `--replace`. Greg loads
   the samples into Ableton and applies effects there, so every step prepares
   takes for an effects chain and changes nothing he would want to shape himself:
   - **High-pass at 80 Hz.** On the first project, room rumble made up nearly
     all the noise, and the cut lowered the noise floor by about 13 dB without
     touching the voice. `--highpass 0` skips it.
   - **Trim** to 30 ms before the voice and 200 ms after, with short fades.
     Breaths next to the line are kept. `--no-trim` skips it.
   - **Level** every take to -20 LUFS with one static gain, so one effects
     chain behaves the same on every take. Boosts stop at +10 dB, and peaks stay
     at or below -1 dBFS. `--loudness` changes the target, and `--no-level`
     skips it.
   - Don't add broadband denoising (`afftdn`) or limiting unless Greg asks.
     Denoising gained only 1 to 3 dB and can smear speech, and limiting
     reshapes transients that his chain should handle.

5. **Report.** Show the folder list and call out any names you guessed or
   corrected, so Greg can listen to those first.

## Leave alone

- **`clips/` and `manifest.json`.** They are the source for `apply`. To fix a
  name, edit `names.json` and re-apply. Re-extracting re-runs transcription,
  but it keeps `names.json` and `samples/`. If the clip counts changed, `apply`
  says which tracks need new names.
- **The project file.** Never write to it. If Greg wants different clip
  boundaries, he changes them in Audacity and saves, and then you extract
  again with `--replace`.
