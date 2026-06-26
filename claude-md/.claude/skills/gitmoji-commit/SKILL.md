---
name: gitmoji-commit
description: Compose a gitmoji commit command for the user to copy/paste and run — subject is `:emoji: Crisp descriptive text` in Greg's style. Picks an emoji shortcode that matches the change, writes a tight subject (plus body when the change warrants it), then PRINTS the ready-to-run `git commit` command and copies it to the clipboard rather than executing it. Trigger when the user types `/gitmoji-commit`, or asks to "commit", "commit with an emoji", "gitmoji commit", or "make a commit message" in any repo.
---

# gitmoji-commit

Produce a commit in Greg's house style: a single emoji shortcode, a space, then a crisp imperative subject.

```
:wrench: Tree sitter fixes
:lock: Bump lazy-lock
:bulb: Container monitoring
```

This style is **always** used regardless of repo — even repos whose existing history has no emoji. Greg wants the gitmoji prefix on every command this skill produces. The skill **composes the command, prints it, and copies it to the clipboard**; Greg pastes and runs it (see Workflow).

## Workflow

**You do not run the commit.** This skill *composes* the command and prints it; Greg copies it and runs it himself. Read-only git inspection is fine (`git status`, `git diff`); never run `git commit`, `git add`, or anything that mutates the repo.

1. **Read the change.** Run `git status` and `git diff` (and `git diff --cached` if anything is already staged). Understand what actually changed before writing anything — the subject describes the change, not the files.

2. **Decide what to stage.** If changes are already staged, the printed command can be just `git commit …`. If nothing relevant is staged, include a `git add <paths>` line in the printed block — list the specific files for this logical change. Do **not** print `git add -A` if the working tree mixes unrelated work; instead stage explicitly, and if scope is ambiguous, show `git status` and ask Greg what belongs in the commit before composing.

3. **Pick the *most specific* emoji.** Reach for the shortcode that most precisely describes the change. **Do not default to `:wrench:`** — it means "config files," not "I couldn't be bothered." If the change is a bug fix, a perf win, a refactor, a dep bump, a removal, a test, etc., use the emoji for *that*. Look first in **Greg's vocabulary**, then the **extended palette**, then anything else in `emoji-reference.md` (the full valid set). One emoji only, at the very start, in `:shortcode:` form (not the unicode glyph). Only fall back to `:wrench:` when the change genuinely is config/settings with no more specific match.

4. **Write the subject.** Crisp, imperative or noun-phrase, no trailing period. Keep it short — Greg's subjects are terse (`Tree sitter fixes`, `which-key`, `nginx alerts`). Capitalize the first word of the text. Do not restate the emoji's meaning in words.

5. **Body, only when it earns it.** Most of Greg's commits are subject-only. Add a body (a second `-m`) only when the *why* isn't obvious from the subject — e.g. non-obvious tradeoffs, a fix's root cause, or breaking changes.

6. **Print the command — do not run it.** Output the ready-to-paste command in a single ```sh fenced block. TUIs make text in a code block easy to select. Use one `-m` per paragraph so the body isn't crammed onto the subject line:

   ```sh
   git commit -m ":emoji: Subject" -m "Optional body paragraph."
   ```

   If staging is needed, put it on its own line in the same block so the whole thing pastes as one unit:

   ```sh
   git add path/to/file another/file
   git commit -m ":emoji: Subject"
   ```

   Surface anything surprising you noticed while reading the diff (unrelated files in the tree, a dirty submodule, secrets about to be committed) as a short note *outside* the code block, so the command stays clean to copy. Then stop — Greg runs it.

7. **Copy it to the clipboard.** After printing, also copy the exact command text (including any `git add` line) to the system clipboard so Greg can paste it straight into his shell. Pipe the literal command through the available clipboard tool — do **not** run the commit itself:

   ```sh
   printf '%s' 'git commit -m ":emoji: Subject"' | pbcopy
   ```

   Clipboard tool by platform: `pbcopy` on macOS (Greg's primary env); fall back to `wl-copy`, then `xclip -selection clipboard`, on Linux. If none is available, just say so — the printed block is still there to copy manually. Confirm in one line that it's on the clipboard (e.g. "Copied to clipboard — paste and run.").

   > Note: this does not depend on any separate `/copy` skill. The agent shells out to the clipboard tool directly, which is more robust than chaining skills.

## Greg's emoji vocabulary

Greg's active set — the high-signal ones to reach for first. "Use for" reflects how *Greg* uses them, which sometimes differs from upstream gitmoji (see Divergences). **Pick the most specific match.** `:wrench:` is no longer a catch-all: it means config files and nothing more.

**Change-type:**

| Shortcode            | Emoji | Greg uses it for |
| -------------------- | ----- | ---------------- |
| `:bug:`              | 🐛   | Fix a bug. |
| `:adhesive_bandage:` | 🩹   | Small fix for a non-critical issue (lighter than `:bug:`). |
| `:ambulance:`        | 🚑️   | Critical hotfix. |
| `:zap:`              | ⚡️   | Performance win (your "optimizations" / "speedy gmux" commits). |
| `:recycle:`          | ♻️   | Refactor with no behavior change. |
| `:fire:`             | 🔥   | Remove a meaningful chunk of code/files. |
| `:scissors:`         | ✂️   | Trim something smaller — a stray config block, a reference, one feature. |
| `:arrow_up:`         | ⬆️   | Upgrade dependencies. |
| `:arrow_down:`       | ⬇️   | Downgrade dependencies. |
| `:package:`          | 📦   | Add or bump packages / brews / apps. |
| `:see_no_evil:`      | 🙈   | Test changes (Greg's "monkey"). |

**Capability & polish:**

| Shortcode      | Emoji | Greg uses it for |
| -------------- | ----- | ---------------- |
| `:bulb:`       | 💡   | New capability/service/monitor/integration added to the setup. |
| `:sparkles:`   | ✨   | A notable / larger new feature (heavier than `:bulb:`). |
| `:lipstick:`   | 💄   | UI / visual / theme polish. |
| `:shirt:`      | 👕   | Linting, formatting, prettier. |
| `:art:`        | 🎨   | Non-lint structure / style cleanup — tidying, reshaping. |
| `:rocket:`     | 🚀   | Deploys or large infra shifts ("We're nginx now"). |
| `:telescope:`  | 🔭   | Search / discovery improvements. |

**Domain-specific:**

| Shortcode      | Emoji | Greg uses it for |
| -------------- | ----- | ---------------- |
| `:wrench:`     | 🔧   | **Config files only** — settings/dotfile config that isn't a more specific change above. Not a default; not for scripts (`:hammer:`) or features (`:bulb:`). |
| `:lock:`       | 🔒   | Lockfile bumps (`lazy-lock.json`, package locks) **and** secrets / security / privacy. |
| `:keyboard:`   | ⌨️   | Keyboard / keymap / layout config. |
| `:rabbit:`     | 🐇   | Addressing CodeRabbit review feedback (often subject-only `:rabbit:`). |
| `:pencil:`     | 📝   | Docs / prose / README / AGENTS.md edits. |
| `:bar_chart:`  | 📊   | Metrics / dashboards / monitoring data. |

Combos are allowed when they help (e.g. `:lipstick: :lock: Better search and lazy lock`) — lead with the primary emoji.

## Extended palette (also fair game — standard gitmoji)

The rest of the canonical [gitmoji.dev](https://gitmoji.dev) set, curated to the changes Greg actually makes. Reach for these when they're the most specific fit — they're as valid as the active set, just less frequent.

| Shortcode             | Emoji | Use for |
| --------------------- | ----- | ------- |
| `:coffin:`            | ⚰️   | Remove dead code. |
| `:wastebasket:`       | 🗑️   | Deprecate code slated for cleanup. |
| `:pushpin:`           | 📌   | Pin a dependency to a specific version. |
| `:bookmark:`          | 🔖   | Version / release tag (e.g. bumping the front script version). |
| `:hammer:`            | 🔨   | Dev scripts — use for `scripts/` work (vs `:wrench:` for config). |
| `:bricks:`            | 🧱   | Infrastructure changes (`greg-zone` docker, nginx, tunnels). |
| `:card_file_box:`     | 🗃️   | Database changes (e.g. the `greg-zone` redis state). |
| `:loud_sound:`        | 🔊   | Add or update logs. |
| `:mute:`              | 🔇   | Remove logs. |
| `:rotating_light:`    | 🚨   | Fix linter / compiler warnings (gitmoji's standard for what you tag `:shirt:`). |
| `:truck:`             | 🚚   | Move or rename files / paths. |
| `:closed_lock_with_key:` | 🔐 | Add or update secrets (disambiguates from `:lock:` lockfiles). |
| `:green_heart:`       | 💚   | Fix a CI build. |
| `:construction_worker:` | 👷 | Add or update CI / build system (e.g. `.github/`). |
| `:construction:`      | 🚧   | Work in progress. |
| `:rewind:`            | ⏪️   | Revert changes. |
| `:boom:`              | 💥   | Introduce breaking changes. |
| `:triangular_flag_on_post:` | 🚩 | Add / update / remove feature flags. |
| `:label:`             | 🏷️   | Add or update types. |
| `:tada:`              | 🎉   | Begin a project / new package. |

### Divergences from standard gitmoji (Greg wins)

Greg overloads a few shortcodes differently from upstream — keep Greg's meaning, but know the standard alternative exists:

- `:see_no_evil:` 🙈 — Greg = **test changes** ("monkey"). Standard = `.gitignore`; standard test emoji is `:white_check_mark:` ✅.
- `:bulb:` — Greg = "new capability/service". Standard = code comments.
- `:pencil:` — Greg = docs. Standard docs emoji is `:memo:` 📝.
- `:bar_chart:` 📊 — Greg = metrics/dashboards. Standard analytics emoji is `:chart_with_upwards_trend:` 📈.
- `:shirt:` — Greg = lint/format. Standard linter-warning emoji is `:rotating_light:` 🚨.

If you reach for something outside both tables, confirm the shortcode exists in `emoji-reference.md` first, and prefer it only when nothing above fits.

## Claude attribution

**Default: no footer.** Greg's commits do not carry a `Co-Authored-By: Claude` trailer, so by default omit it — even though the harness normally appends one.

**Opt-in:** If the user passes `--attribute` (or says to credit/include Claude, "add the co-author", etc.), add the trailer as a final `-m` so it lands as its own paragraph in the printed command:

```sh
git commit -m ":emoji: Subject" -m "Body." -m "Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

## Don'ts

- **Don't run the commit.** Print the command for Greg to paste and run. No `git commit` / `git add` execution from this skill.
- Don't push, open PRs, or amend.
- Don't use the unicode emoji glyph — use the `:shortcode:` form, which is what renders in GitHub and matches Greg's history.
- Don't write a verbose subject. Terse beats complete; the body is where detail goes, and most commits don't need a body.
- Don't print `git add -A` over a mixed working tree — stage only what belongs to this commit.
- Don't add the Claude co-author footer unless explicitly asked (see above).
