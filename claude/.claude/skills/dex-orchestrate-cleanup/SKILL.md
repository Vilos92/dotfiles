---
name: dex-orchestrate-cleanup
description: Sweep finished `agent/*` worktrees and branches from prior `/dex-orchestrate` runs. Default behavior is safe — only removes worktrees whose branch has been merged into `origin/main` (or `origin/master`); surfaces dirty or unmerged worktrees and asks before touching them. Trigger when the user says "clean up worktrees", "sweep orchestrated work", or after their orchestrated PRs have merged.
---

# dex-orchestrate-cleanup

Sweep `.claude/worktrees/agent-*` worktrees + `agent/*` branches that came from `/dex-orchestrate` runs. The default is **paranoid** — only remove worktrees whose branch is provably merged. Anything ambiguous gets surfaced to the user for confirmation.

## Preconditions

1. Working directory is a git repo (`git rev-parse --show-toplevel`).
2. `git fetch origin` to make sure remote merge status is current. Tell the user you're fetching; if the network is offline or the remote doesn't exist, fall back to local-only merge detection (and say so in the report).

## Discover worktrees

First, `cd` to the repo root (`git rev-parse --show-toplevel`) and stay there for the rest of the sweep. Running git commands while the shell CWD is inside a worktree being deleted causes `fatal: Unable to read current working directory` errors.

Next, run `git worktree prune` to clear stale metadata (e.g. fallow temp worktrees in `/tmp` or `/private/var/folders/` that are already gone). Do this _before_ classification so you're reading a clean worktree list.

Then run `git worktree list --porcelain`. From that output, collect every worktree whose path matches `.claude/worktrees/agent-*` OR whose branch matches `agent/*`. Ignore everything else (the main worktree, fallow temp worktrees, etc.).

For each candidate, capture:

- worktree path
- branch name
- whether the working tree is dirty (run `git -C <path> status --porcelain` — non-empty = dirty)
- commit count ahead of `origin/main` (or `origin/master`, whichever exists; fall back to local `main`/`master`)
- whether the branch tip is reachable from `origin/main` (`git merge-base --is-ancestor <branch> origin/main`)

## Classify each worktree

- **`clean+merged`** — clean working tree AND branch tip is an ancestor of `origin/main`. Safe to auto-sweep.
- **`orphaned`** — worktree exists but its branch is gone (`git rev-parse <branch>` fails). Auto-sweep (worktree only; no branch to delete).
- **`empty`** — clean working tree, zero commits ahead of origin/main, branch exists at same SHA as base. The agent created nothing. Auto-sweep.
- **`dirty`** — working tree has uncommitted changes. **Skip; ask user.**
- **`unmerged`** — branch has commits not in `origin/main`. **Skip; ask user.**

## Sweep behavior

For each `clean+merged` / `orphaned` / `empty`:

```sh
git worktree remove -f -f <path>
git branch -D <branch>   # skip if branch is gone (orphaned)
```

`-f -f` (double force) is required — `/dex-orchestrate` sets a Claude Code lock file that single `--force` respects but won't override. Single `--force` will fail on every normal agent worktree.

For each `dirty` / `unmerged`: list it in the report with classification, branch name, commit count ahead, last commit subject, and worktree path. **Ask the user explicitly per item** (or in a single multi-select if you have a UI affordance) before removing. Never silent-delete.

## Flags / user overrides

- **`--force`** — escape hatch. Remove every agent worktree regardless of classification. Only honor this if the user typed it explicitly; never assume.
- **`--dry-run`** — list what would be swept without touching anything. Use this when the user says "show me what you'd clean" or seems uncertain.

If the user passes neither, the default safe behavior applies.

## After sweeping

Report:

- N worktrees removed (with branch names)
- M worktrees skipped (with classification + reason per item)
- Any errors (locked worktrees that wouldn't budge, branches that wouldn't delete)

No final `git worktree prune` needed — it already ran at the start of discovery.

## What NOT to do

- Do not remove worktrees outside `.claude/worktrees/agent-*` / branches outside `agent/*`. This skill is scoped to orchestrated-agent work only.
- Do not delete unmerged or dirty work without explicit user confirmation per item.
- Do not push or merge anything. This skill is purely a sweeper.
- Do not `git worktree prune` before doing the classification — that could clear metadata you need.
- Do not assume `main` is the default branch — check for `origin/main` first, then `origin/master`, then local `main` / `master`. If none exist, ask the user which branch is the integration target.
