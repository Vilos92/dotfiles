---
description: Cull tests and curate comments, then review all tracked and untracked changes against HEAD, or against a base ref with --base. Usage: /review-changes [--base <ref>] [paths or extra focus]
---

Review my work: every tracked change (staged and unstaged) and every untracked file. By default, compare with HEAD, which covers uncommitted work only. With `--base <ref>`, compare with the merge base of `<ref>` and HEAD, which also covers the commits on this branch. First cull low-value tests and clean up comments, then review. Your only output is a report to me.

Arguments from me, if any: $ARGUMENTS

<rules>
- Don't edit files yourself. Only `test-culler` tasks (tests only) and `comment-curator` tasks (comments only) edit.
- Never commit, stash, checkout, reset, `git add`, or `git clean`, and never touch my real index. The snapshot commands below use a temporary index file; those are the only `git add` calls allowed.
- Never post anything to GitHub.
</rules>

<setup>
1. Resolve <from>, the commit every diff starts from:
   - If the arguments start with `--base <ref>`, take `<ref>` out of them. If `<ref>` is a remote-tracking branch such as `origin/main`, refresh it first with `git fetch <remote> +refs/heads/<branch>:refs/remotes/<remote>/<branch>`. If the fetch fails, tell me and stop. Then run `git merge-base <ref> HEAD` and use the printed sha as <from>. If the merge base fails, tell me and stop.
   - Otherwise <from> is `HEAD`.
   The rest of the arguments are paths or extra focus. Treat anything that is not an existing path as extra focus text.
2. Run `git status --porcelain` and `git diff <from> --stat`.
3. Tracked changes: `git diff <from>` shows commits since <from>, staged, and unstaged changes together.
4. Untracked files: `git ls-files --others --exclude-standard`. These have no diff; they are new in full.
5. If I gave paths, limit everything to them.
6. Drop generated files, lockfiles, vendored code, and binaries from both lists.
7. If nothing is left, tell me and stop.
8. Snapshot the pre-curation state without touching my index:
   `GIT_INDEX_FILE="$(mktemp -u)" sh -c 'git add -A && git write-tree'`
   Keep the printed tree id as <before-tree>.
9. Note repo conventions files (CONTRIBUTING.md, AGENTS.md, CLAUDE.md).
</setup>

<curate>
Split the changed and untracked code files into test files (e.g. `*.test.*`, `*.spec.*`, `__tests__/`, `test/`) and source files. Skip `.md` and other non-code files. Every assignment below must include its file list, with untracked files marked as untracked, and "Your diff command is `git diff <from>`."

Two editors must never work on the same file at once, so run this in two phases:

Phase 1, in parallel:

- `test-culler` tasks on the test files, in batches of about 6, keeping a test file with its fixtures and helpers.
- `comment-curator` tasks on the source files, in batches of about 6, keeping related files together.

Phase 2, after every phase 1 task has finished:

- `comment-curator` tasks on the test files that still have changes, in batches of about 6. Running after the culler means no one curates comments in tests that are about to be deleted.

Wait for phase 2 to finish before reviewing, so the reviewers see the final files and line numbers are stable.
Then snapshot again the same way as <after-tree>, and run `git diff --stat <before-tree> <after-tree>`. Confirm the edits were only comment changes, or test and test-fixture removals inside test files. List anything else in the report.
</curate>

<review>
Dispatch reviewer subagents in parallel on the post-curation state: the bundled `reviewer` agent in omp, the `general-purpose` agent in Claude Code. Size the fan-out:
- Under ~400 changed lines: four tasks, one per focus area below.
- Larger: split into coherent file groups and dispatch one task per group per focus area that applies. Cap the total at 10.

Shared context must include:

- "Tracked changes: get the patch with `git diff <from>` (limit with `-- <paths>`). Do not use plain `git diff`; it misses staged changes."
- "Untracked files, new in full, read them directly: <list>."
- "Comments have already been curated. Don't report comment wording or density."
- "Low-value tests have already been culled: <culled table>. Don't ask for those back unless you can name the production failure they'd catch."
- "Review only your assigned focus and files."
- conventions file paths, and my extra focus if I gave one

Focus areas:

- correctness and logic bugs, including callers and consumers outside the changed lines
- tests: missing coverage for new behavior, weak assertions, tests that can't fail
- security: input handling, auth, secrets, injection, unsafe defaults
- consistency with repo conventions and patterns in surrounding code
</review>

<merge>
- Merge duplicate findings across reviewers.
- Re-check every priority 0 and 1 finding against the code yourself. Drop any you can't confirm.
- Drop findings below 0.5 confidence unless they are priority 0.
</merge>

<report>
- Scope: what <from> is (HEAD, or the base ref and merge-base sha), and counts of tracked and untracked files reviewed.
- Test pass: a table of every deleted or trimmed test (file, test, verdict, reason), the kept count, and any gap or red-test notes.
- Comment pass: totals of dropped / trimmed / rewritten / kept, and any `unsure` notes.
- "See `git diff <before-tree> <after-tree>` for exactly what the test and comment passes changed."
- Findings grouped as Blocking (P0), Should fix (P1), Later (P2), Nits (P3), each with file:line, the issue, why it matters, and a suggested fix.
- If there are no significant issues, say so plainly.
</report>
