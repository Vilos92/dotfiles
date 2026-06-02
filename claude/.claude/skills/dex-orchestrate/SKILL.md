---
name: dex-orchestrate
description: Run multiple dex tasks in parallel as orchestrated Claude Code subagents. Each task gets its own Sonnet subagent in an isolated git worktree, producing a single squashed commit on a sensibly-named branch ready for IDE review. Trigger when the user lists multiple dex task IDs and asks to "orchestrate", "run in parallel", "knock out these tasks", or hands you an explicit orchestrator prompt referencing dex IDs. Requires `dex` on PATH and a git repo.
---

# dex-orchestrate

You are the orchestrator. The user has given you a list of dex task IDs to work on in parallel. Your job is to spawn one subagent per task in an isolated worktree, wait for all of them to finish, verify dex shows them complete, and report back with branch names + Cursor open commands so the user can review in their IDE.

You do **not** push, open PRs, or merge anything. The user reviews each worktree in Cursor and pushes manually when satisfied.

## Dex invocation

Always pass explicit `--config` and `--storage-path` for the chosen profile (`greg` or `front`):

```sh
dex --config "$HOME/.dex/projects/<profile>/config.toml" \
    --storage-path "$HOME/.dex/task-db/<profile>.jsonl" \
    <subcommand> [args...]
```

## Preconditions

Before spawning anything, verify:

1. **Working directory is a git repo.** Run `git rev-parse --show-toplevel`. If it fails, stop and tell the user.
2. **dex is available.** Run `command -v dex`. If missing, stop.
3. **Dex profile is known.** If the user didn't specify (`greg` vs `front`), ask once — list profiles via `ls "$HOME/.dex/projects"` if you need options. Default to the profile from prior conversation context if obvious.
4. **Repo conventions are discoverable.** `CLAUDE.md` at the repo root is the primary source for validation and workflow (Claude Code reads this file). Also check `AGENTS.md` when present — many repos keep shared details there or import it from `CLAUDE.md`. If both are missing or silent, infer from project tooling (`package.json`, `Makefile`, CI, etc.) or ask the user before spawning.

## Inputs

The user provides:

- A list of dex task IDs (required).
- Optional: per-task model override (default: Sonnet). Use Haiku only for genuinely mechanical tasks; Opus only when ambiguity or architecture decisions are at stake.
- Optional: a richer orchestrator prompt with hand-tuned per-task context. **Prefer this verbatim if given** — the user's hand-authored prompt is higher signal than anything you'd derive from dex alone.

If no IDs are given, ask. Do not guess from `dex ... list`.

## Per-task prompt construction

**Discover validation once per target repo** (before spawning): read that repo's `CLAUDE.md` (and `AGENTS.md` if needed), then manifests/CI if still unclear, to build the ordered list of lint/format/typecheck/test commands subagents must run. Pass that list explicitly in each subagent prompt.

For each dex task ID:

1. **Fetch the task.** `dex --config "$HOME/.dex/projects/<profile>/config.toml" --storage-path "$HOME/.dex/task-db/<profile>.jsonl" show <id>`. If the task isn't found or its description is too thin to act on, **pause and ask the user to flesh it out in dex** rather than guessing. Do not proceed with thin tasks — quality belongs upstream in dex.

2. **Compose the subagent prompt** with the dex task description **verbatim** as the core. Layer on this deterministic boilerplate (do not paraphrase the task itself):
   - "You are in a fresh git worktree. Run `pwd` first to confirm location. Do NOT touch the original repo at `<repo-root>` — only work in your worktree."
   - The full dex task description (verbatim).
   - Reference: "Read `CLAUDE.md` at the repo root for conventions before starting; also read `AGENTS.md` if the repo has one." (Skip this line if neither file exists.)
   - **Branch:** "Create a branch named `agent/<dex-id>-<slug>` where `<slug>` is a short kebab-case version of the dex task title (≤6 words). Check it out before committing."
   - **Validation:** Before commit and `dex complete`, run this ordered command list (from the orchestrator's repo discovery above): `<paste commands here>`. It should cover whatever that repo documents — tests, lint, format checks, typecheck, and related gates in `CLAUDE.md`, `AGENTS.md`, or project scripts. If the list is empty or unclear, read those files and manifests yourself; if still undiscoverable, stop and report back. Run every applicable check, stop on first failure, fix and re-run until green.
   - **Commit:** "Stage all changes and create a **single commit** on the agent branch. Subject line = the dex task title. Body = the one-line summary you'll pass to `dex complete --result`. Do not push."
   - **Dex completion:** "After validations pass AND the commit lands, run `dex --config \"$HOME/.dex/projects/<profile>/config.toml\" --storage-path \"$HOME/.dex/task-db/<profile>.jsonl\" complete <dex-id> --result '<one-sentence summary>'`."
   - **Reporting back:** ask the subagent to return files touched, summary of behavior, validation outcomes, and anything surprising.

3. **Choose the model.** Default Sonnet. Use Haiku only for clearly mechanical tasks (formatting, renaming, file moves). If a task feels Opus-shaped, flag it to the user before spawning — don't escalate silently.

## Spawning

- Use the **Agent tool** with `isolation: "worktree"` and `model: "sonnet"` (or overridden).
- Use `subagent_type: "general-purpose"` unless the task fits a more specialized agent.
- **Spawn all subagents in parallel** — single message with multiple Agent tool blocks.
- Subagents are not allowed to spawn further subagents for this work. If a subagent realizes the task is wrong-sized, it should return to you, not escalate.

## After all subagents return

1. **Verify dex.** Run `dex --config "$HOME/.dex/projects/<profile>/config.toml" --storage-path "$HOME/.dex/task-db/<profile>.jsonl" list` and confirm each orchestrated task is no longer in the list. If any is still pending, surface that — the subagent failed to mark complete.

2. **Report to the user**, one block per task:
   - Dex ID + title
   - Branch name: `agent/<dex-id>-<slug>`
   - Worktree path: `.claude/worktrees/agent-<agent-id>` (returned by the Agent tool)
   - One-line summary of what was built
   - Cursor open command: `cursor <worktree-path>`

3. **Closing reminder:** tell the user they can run `/dex-orchestrate-cleanup` after their PRs merge to sweep finished worktrees. If they need to address CodeRabbit (or other) feedback, they should `cd` into the worktree and run Claude Code there — no need to re-orchestrate.

## Failure modes to handle

- **A subagent fails validation and gives up.** Report which task failed and what the failure was; do NOT mark the dex task complete. Leave the worktree for the user to inspect.
- **A subagent makes no changes.** The worktree auto-cleans; surface this and don't claim the task is done.
- **Conflicting file edits between worktrees.** Worktrees are isolated, so this won't manifest until the user tries to merge two branches. Mention in the closing report if you noticed two tasks touched the same files.
- **User interrupts mid-orchestration.** Subagents already in flight will continue; their results may still arrive. Don't re-spawn already-completed tasks.

## What NOT to do

- Do not push branches or open PRs.
- Do not merge anything to main.
- Do not commit in the main working tree — only inside agent worktrees.
- Do not skip validation. The subagent must validate before committing and before marking dex complete.
- Do not guess validation commands when `CLAUDE.md` / `AGENTS.md` and tooling give no guidance — ask the user.
- Do not paraphrase the dex task description in the subagent prompt — pass it verbatim.
- Do not silently downgrade models. If a task feels too small for Sonnet, ask; if too big, flag.
