---
description: Read-only review of a teammate's PR. Usage: /pr-review [pr-number]
---

You are leading a read-only review of a teammate's pull request. Your only output is a report to me.

PR: $ARGUMENTS (if empty, use the PR for the current branch)

<rules>
- Never edit files, commit, push, checkout, stash, rebase, or reset. Don't use the edit or write tools during this review.
- Never post to GitHub: no `gh pr review`, `gh pr comment`, `gh pr merge`, or `gh api` writes.
- Allowed bash: `git fetch`, `git remote -v`, `git diff`, `git log`, `git show`, `git rev-parse`, `gh repo view`, `gh pr view`, `gh pr diff`, read-only `gh api` GETs.
</rules>

<setup>
Do all of this before dispatching reviewers:
1. Run `gh repo view --json nameWithOwner`.
2. Run `gh pr view $ARGUMENTS --json number,title,body,url,baseRefName,headRefName,headRefOid,isCrossRepository`.
3. Run `git remote -v` and pick the remote whose URL matches the PR's base repo (usually `origin`, or `upstream` in a fork workflow). Use it as <base-remote> below. If it's ambiguous, ask me.
4. Run `git fetch <base-remote> <baseRefName>`. Confirm `git rev-parse HEAD` equals headRefOid. If not, tell me the checked-out commit and the PR head commit, and ask how to proceed. Don't check anything out yourself.
5. The diff command is `git diff <base-remote>/<baseRefName>...HEAD` (three dots). Run it with `--stat` to size the PR.
6. Collect existing feedback: `gh pr view <number> --comments` and `gh api repos/{owner}/{repo}/pulls/<number>/comments`.
7. Note repo conventions files (CONTRIBUTING.md, AGENTS.md, CLAUDE.md).
</setup>

<dispatch>
Dispatch reviewer subagents in parallel: the bundled `reviewer` agent in omp, the `general-purpose` agent in Claude Code. Size the fan-out to the PR:
- Small (under ~400 changed lines): four tasks, one per focus area below.
- Large: split the diff into coherent groups of files (by module or directory), and dispatch one task per group per focus area that applies to it. Cap the total at 12.
- If the PR touches areas with specific risks, add a focused task: performance for hot paths, API/backward compatibility for public interfaces, data safety for migrations, concurrency for async or locking code.

Shared context must include:
- PR title and description, base ref, conventions file paths, and the existing review comments
- "Get the patch with `<diff command>`. Do not use plain `git diff`; the branch is committed."
- "Review only your assigned focus area and files. Do not re-raise issues already mentioned in the existing comments."
For file-group tasks, list the files and tell the reviewer to limit the diff with `-- <paths>`.

Focus areas:
- correctness and logic bugs, including callers and consumers outside the diff
- tests: missing coverage for new behavior, weak assertions, tests that can't fail
- security: input handling, auth, secrets, injection, unsafe defaults
- consistency with repo conventions and patterns in surrounding code
</dispatch>

<merge>
- Merge duplicate findings across reviewers.
- Re-check every priority 0 and 1 finding against the code yourself. Drop any you can't confirm.
- Drop findings below 0.5 confidence unless they are priority 0.
</merge>

<report>
- Header: repo name, PR number and title, base and head branches.
- Summary: 2-3 sentences on what the PR does and whether it matches its description.
- Findings grouped as Blocking (P0), Should fix (P1), Later (P2), Nits (P3), each with file:line, the issue, why it matters, and a suggested fix.
- Existing feedback: which prior comments look addressed and which still look open.
- If there are no significant issues, say so plainly.
</report>
