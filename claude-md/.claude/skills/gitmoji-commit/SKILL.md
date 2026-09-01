---
name: gitmoji-commit
description: Compose a commit in Greg's gitmoji style — subject is `:emoji: Crisp descriptive text`. Picks the emoji shortcode that best matches the change, writes a tight subject (plus a body when the change warrants one), then by default prints the ready-to-run `git commit` command and copies it to the clipboard. When Greg asks for the commit to be made, make it instead. Trigger when the user types `/gitmoji-commit`, or asks to "commit", "commit with an emoji", "gitmoji commit", or "make a commit message" in any repo.
---

# gitmoji-commit

Produce a commit in Greg's house style: a single emoji shortcode, a space, then a crisp subject.

```
:wrench: Tree sitter fixes
:lock: Bump lazy-lock
:bulb: Container monitoring
```

Use this style in **every** repo, including ones whose existing history carries no emoji.

Write the subject and body in **Greg Technical Style** (defined in `~/.claude/CLAUDE.md`): outcome first, no filler, plain language, backticks around identifiers and paths.

## Two modes

**Default — compose.** Print the ready-to-run command and copy it to the clipboard. Greg runs it himself.

**On request — commit.** When Greg asks you to make the commit (`--commit`, "just commit it", "go ahead and commit", "commit the damn thing"), run it yourself and **skip the clipboard entirely** — he asked for a commit, not for text to paste. Report the short SHA once it lands.

Permission is sticky. Once Greg grants it in a session, keep committing without asking again until he says otherwise.

Either mode: never push, open a PR, or amend.

## Workflow

1. **Read the change.** Run `git status` and `git diff` (and `git diff --cached` if anything is staged). Understand what actually changed before writing anything — the subject describes the change, not the files.

2. **Decide what to stage.** If the right changes are already staged, `git commit` alone is enough. Otherwise stage the specific files for this logical change. Never use `git add -A` over a working tree that mixes unrelated work; if scope is ambiguous, show `git status` and ask Greg what belongs in the commit before going further.

3. **Pick the *most specific* emoji.** Reach for the shortcode that most precisely describes the change. **Do not default to `:wrench:`** — it means "config files," not "I couldn't be bothered." If the change is a bug fix, a perf win, a refactor, a dep bump, a removal, or a test, use the emoji for *that*. Look first in **Greg's vocabulary**, then the **extended palette**, then anything else in `emoji-reference.md` (the full valid set). One emoji only, at the very start, in `:shortcode:` form — not the unicode glyph. Fall back to `:wrench:` only when the change genuinely is config with no better match.

4. **Write the subject.** Terse. Imperative or noun phrase, no trailing period, first word capitalized. Keep the text after the shortcode to roughly 50 characters — Greg's subjects run short (`Tree sitter fixes`, `which-key`, `nginx alerts`). Don't restate the emoji's meaning in words.

5. **Add a body only when it earns one.** Most of Greg's commits are subject-only. Add a body when the *why* isn't obvious from the subject — a non-obvious tradeoff, a fix's root cause, a breaking change. Explain why, not how; the diff already shows how.

6. **Deliver.**

   **Composing (default).** Print the command in one ```sh block so it is easy to select in a TUI. Use one `-m` per paragraph so the body doesn't collapse onto the subject line:

   ```sh
   git commit -m ":emoji: Subject" -m "Optional body paragraph."
   ```

   Put any staging on its own line in the same block so the whole thing pastes as a unit:

   ```sh
   git add path/to/file another/file
   git commit -m ":emoji: Subject"
   ```

   Then copy the exact command text to the clipboard:

   ```sh
   printf '%s' 'git commit -m ":emoji: Subject"' | pbcopy
   ```

   Clipboard tool by platform: `pbcopy` on macOS (Greg's primary environment); fall back to `wl-copy`, then `xclip -selection clipboard`, on Linux. If none is available, say so — the printed block is still there to copy by hand. Confirm in one line, e.g. "Copied to clipboard — paste and run."

   **Committing (on request).** Run the staging and commit directly. No printed block to copy, no clipboard write. Confirm with the short SHA and subject:

   ```
   Committed 4e10a49 :wrench: Tree sitter fixes
   ```

   Either way, surface anything surprising you noticed while reading the diff — unrelated files in the tree, a dirty submodule, secrets about to be committed — as a short note *outside* the code block, so the command stays clean to copy.

## Greg's emoji vocabulary

Greg's active set — the high-signal ones to reach for first. "Use for" reflects how *Greg* uses them, which sometimes differs from upstream gitmoji (see Divergences). **Pick the most specific match.** `:wrench:` is not a catch-all: it means config files and nothing more.

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

## Attribution

**Never add a `Co-Authored-By: Claude` trailer.** Greg is the sole author of his commits. This holds in both modes, and it holds even when the harness would append one by default — when you run the commit yourself, pass only the `-m` arguments you composed.

There is no opt-in. If Greg asks for co-authorship explicitly, confirm before adding anything.

## Don'ts

- Don't push, open PRs, or amend.
- Don't commit unless Greg asked you to — compose and copy by default.
- Don't write to the clipboard when Greg asked you to commit. He wants the commit, not the text.
- Don't use the unicode emoji glyph — use the `:shortcode:` form, which renders on GitHub and matches Greg's history.
- Don't write a verbose subject. Terse beats complete, and most commits need no body at all.
- Don't `git add -A` over a mixed working tree — stage only what belongs to this commit.
- Don't add a co-author trailer.
