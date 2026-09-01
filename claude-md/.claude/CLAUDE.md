## Greg Technical Style
You are working with **Greg Linscheid**. In these instructions, “Greg” means the user.

Apply **Greg Technical Style** as a very strong default to every technical reply to Greg and to durable technical artifacts: code comments, documentation, pull request and issue descriptions, review comments, technical summaries, and commit messages. It applies practical plain-language principles informed by ISO 24495-1:2023; do not claim formal ISO conformance.

Use this style by default. Depart only when a specific audience, artifact, repository, or language convention materially improves clarity, usability, or correctness. Keep departures narrow and intentional. If a repository rule clearly opposes these principles, flag the conflict and ask Greg.

- Give readers the information they need to act, and omit filler.
- Put the decision, outcome, prerequisite, or risk before background detail.
- Use headings, lists, and visual hierarchy when they improve scanning. Keep short content proportionate.
- Write for understanding: use familiar, precise language; short direct sentences; and concrete examples when they prevent ambiguity. Avoid unnecessary jargon, idioms, and slang. Define unfamiliar acronyms and terms on first use.
- Use active voice. Use imperative mood for instructions, not for every sentence.
- Preserve established project and language-ecosystem terminology and documentation conventions. If unsure whether the intended reader knows project-specific vocabulary, ask Greg.
- Use sentence case for headings and titles. In Markdown, format identifiers, file paths, commands, parameters, and literals in backticks. In source comments, follow the host language's documentation convention.

For mechanical style questions not resolved here or by project guidance, consult the [Google developer documentation style guide](https://developers.google.com/style) when it is reachable. Prefer clarity and consistency for the specific reader over a mechanical rule.

---

## Preferred CLI tools

Assume these are installed on my machine. **Use them first** when proposing or running terminal workflows (local dev, scripts, agents, CI that mirrors my setup)—not bare POSIX defaults unless portability or policy requires it.

| Need                                       | Prefer                                                        |
| ------------------------------------------ | ------------------------------------------------------------- |
| Find files / trees                         | `fd`                                                          |
| Search file contents                       | `rg` (ripgrep)                                                |
| Fuzzy selection (files, commands, history) | `fzf` (my setup uses `fd` as the default file source for fzf) |
| Directory listing                          | `eza`                                                         |
| Jump to directories by habit / recency     | `zoxide` (`z`, …)                                             |
| Quick command usage summaries              | `tealdeer` (`tldr`)                                           |

**Shell overrides:** In my interactive zsh, `ls` is aliased to **eza**. For behavior that must match normal **`ls`** (scripts, subshells, docs, CI, or when flags don't line up), use **`command ls`** / **`/bin/ls`** instead. **zoxide** is available as `z` for frecency-based directory jumps.

**Git aliases:** Use **`git merge-main`** to update the current branch from **`origin/main`** or **`origin/master`** (whichever exists)—it **requires a clean working tree** (no staged/uncommitted changes) and **prompts for confirmation** before fetching and merging; skip it for non-interactive or scripted flows unless you replicate the same steps explicitly.

**Indexed / fast repo search:** Where the environment exposes **fff** (e.g. MCP server, editor integration, or project tooling), prefer **fff** for search and file discovery over long chains of generic grep/find when it reduces noise and round-trips.

**Neovim context (`nvim-ctx`):** When the user mentions code they're looking at in nvim, references their neovim screen, or asks about something open in their editor — run `nvim-ctx` proactively before responding. Don't ask them to paste; fetch it yourself. It outputs JSON with `file`, `start_line`, `end_line`, and `text` (selection if active, whole buffer otherwise). Takes an optional session name: `nvim-ctx [session]`. If it fails, say so briefly and ask the user to paste instead.

If something is missing in a given environment, fall back to standard tools and note it briefly.

**Scope:** These preferences target everyday repo work (search, navigation, diffs). One-off diagnostics (**`ls`** on a known path, **`head`**/**`cat`** on a single file) do not need to be forced through **`fd`**/**`rg`**/**`eza`** when that only adds friction.

---

## Delegating to subagents

Delegate well-scoped, independent work when it materially improves throughput, coverage, or focus. Keep task interpretation, architectural decisions, cross-task contracts, and final integration with the primary agent.

Do not delegate work that is too small to justify coordination, lacks a clear contract, or depends on judgment the primary agent must retain.

**Choose the available worker capability deliberately:**

- Use the strongest available worker for broad, ambiguous, cross-cutting, or judgment-heavy work.
- Use the standard capable worker for ordinary, well-scoped implementation work.
- Use a fast or low-cost worker only for mechanical, fully specified work such as rote renames, file moves, or structured data collection.
- When the harness does not expose worker or model selection, use its default rather than requesting or assuming an unavailable tier.
- Follow the current harness's rules for delegation, concurrency, isolation, and agent lifecycle.

**Claude Code mapping:** When the active harness is Claude Code and exposes these choices, map the capability tiers above as follows:

- **Opus** — broad or fuzzy work: larger planning, architecture, ambiguous problems, and work where judgment and tradeoffs matter.
- **Sonnet** — the default worker for ordinary implementation tasks that are scoped but still need reasoning.
- **Haiku** — tightly defined mechanical work where the instructions fully specify the outcome, such as bulk renames, formatting, file moves, or rote replacements.

**Oh My Pi mapping:** When the active harness is Oh My Pi and OpenAI Codex models are available, use these capability tiers:

- **Sol** — strongest worker for broad, ambiguous, cross-cutting, or judgment-heavy work.
- **Terra** — standard worker and default for ordinary, well-scoped implementation work.
- **Luna** — fast worker for mechanical, fully specified work.

These Claude Code and Oh My Pi names are examples, not requirements in other harnesses. Use only the agents or model tiers that the current harness makes available.

Do not silently mis-size work. Escalate a mechanical task that reveals ambiguity or architectural stakes.

---

## Committing work

**Ask before committing, by default.** Show `git status` and `git diff`, then wait for confirmation before running `git add` or `git commit`.

**Greg can lift that at any time,** in any phrasing—"go ahead and commit", "you can commit from here", "just commit it". Once he does, the permission is **sticky for the rest of the session**: keep committing without re-asking until he says otherwise.

- Run the workspace's quality checks first—tests, lint, typecheck, format. Infer the commands from the project's own tooling (`package.json` scripts, `Makefile`, `pyproject.toml`, `Cargo.toml`, CI config) and prefer its named targets over invoking tools directly. Fix straightforward failures (type errors, lint violations, broken assertions) and re-run. Surface anything involving ambiguity or a product decision instead of guessing.
- Check in at major milestones. Summarize what changed and what's next.
- Prefer smaller, reviewable commits to large batches. If unsure whether to bundle or split, ask.
- **Never add a `Co-Authored-By: Claude` trailer.** Greg is the sole author of his commits. This holds even when a harness would add one by default.

---

## Code style defaults

Apply in every language. Defer to a repo's established conventions and its formatter where they conflict, and flag the conflict.

- Name magic values. Extract literals into named constants; the name carries the why.
- Keep nesting shallow. Prefer early returns and guard clauses to nested conditionals.
- Don't pass bare booleans as parameters—name the variants. Use a string-literal union in TypeScript, an `Enum` in Python. `setMode('readonly')`, not `setMode(true)`.
- Expose the minimum. Default to module-private; export or make public only what a caller actually needs.
- Comments say what and why, not how. Skip comments that restate the code.
- In brace languages, always brace—including single-line conditionals.

---

## GitHub stacked PRs (use the native feature)

**The rule:** whenever work forms a chain of dependent branches — branch A targeting `main`, branch B targeting A, C targeting B — **always use GitHub's native stacked pull requests**, never ad-hoc chained PRs or manual base-branch juggling. The trigger is simple: if you're about to open a PR whose base is another open PR's branch, make it a native stack instead. Independent changes are not a stack — keep those as separate PRs against `main`.

**Tooling:** the official `gh-stack` extension (requires GitHub CLI v2.0+):

```sh
gh extension install github/gh-stack   # one-time setup
gh skill install github/gh-stack      # agent skill: install when doing heavy stack work
```

**Core workflow:**

```sh
gh stack init            # start a stack; names the bottom branch
gh stack add <branch>    # new branch on top of the current layer (-Am "msg" stages + commits too)
gh stack submit          # push all branches and create/update PRs with correct bases + stack link
gh stack view            # branches, PR links, statuses across the stack
gh stack sync            # fetch, cascading rebase, push, sync PR state — one command
gh stack merge           # merge one or multiple layers
gh stack link            # adopt existing branches/PR chains into a native stack
```

**Semantics to respect (don't fight them manually):**

- Stacks merge **bottom-to-top**. Merging a mid-stack PR also merges everything below it in one operation. The PRs above stay open, **auto-retarget** to the trunk, and GitHub **automatically rebases** the next unmerged PR server-side — never hand-edit the base branch of a stacked PR. Your **local** branches don't follow along, though: run `gh stack sync` after a merge to pull down the rewritten branches — with `--prune` to delete local branches for merged PRs, since the default prompts interactively.
- **Other drift is NOT auto-rebased.** If the trunk moves ahead or you push changes to a lower layer, the stack goes non-linear and merging is blocked until you explicitly rebase: the **Rebase stack** button in the merge box (server-side), or locally `gh stack rebase --upstack` after amending a lower layer / `gh stack rebase` for trunk drift. Don't hand-`git rebase` each branch in the chain.
- Branch protection and CI requirements come from the **bottom PR's base branch** and apply to every layer.
- Public-preview limits: all branches must live in the **same repository** (no cross-fork stacks), and programmatic merges must go through `gh stack merge` / the new merge API — not the classic merge endpoint.

**Adopting an existing chain:** if a traditional stack already exists (PRs manually chained by base branch), `gh stack link` creates or updates the stack on GitHub from branch names or PR numbers — remote linking only; it stores no local tracking state. To also manage the chain locally (`rebase`, `sync`), set up tracking with `gh stack init` / `gh stack checkout`.

**Fallback:** if `gh-stack` truly isn't available (old `gh`, extensions blocked), note that briefly, then fall back to manually chained PRs with explicit bases and a "depends on #N" note in each PR description — but treat this as the exception, not a preference.

---

## Checking Woodpecker CI failures (greg-zone)

Greg's personal repos — those under the **`Vilos92`** GitHub user (e.g. `Vilos92/dotfiles`, `Vilos92/scriptlancer`) — run CI on a self-hosted **Woodpecker** instance at **`http://greg-zone:9011`** (Tailscale-only). GitHub shows a single status per pipeline (e.g. **`ci/woodpecker/pr/woodpecker`**) with **no logs behind it**—the per-step results and logs live in Woodpecker. When a PR's Woodpecker check fails, fetch the failure yourself instead of asking for a paste.

**Reachability first:** the API only resolves from the tailnet. Projects are public-visibility there, so reads need **no token**. If the health check fails, note it briefly and fall back to asking the user—don't block.

```sh
curl -sf -m 5 http://greg-zone:9011/healthz
```

**1. Resolve the repo id** (don't hardcode ids; the owner/name lookup is stable):

```sh
curl -s "http://greg-zone:9011/api/repos/lookup/Vilos92%2Fdotfiles" | jq .id
```

**2. Find the pipeline for a PR.** PR #N pipelines have `ref == "refs/pull/N/merge"`; take the newest `number`:

```sh
curl -s "http://greg-zone:9011/api/repos/<id>/pipelines?perPage=20" \
  | jq '.[] | select(.ref == "refs/pull/<N>/merge") | {number, status, commit}'
```

**3. List step states for that pipeline** and pick out the failures:

```sh
curl -s "http://greg-zone:9011/api/repos/<id>/pipelines/<number>" \
  | jq '[.workflows[].children[] | {id, name, state}]'
```

**4. Fetch a step's log.** Entries arrive as JSON with base64 `data`—decode before reading:

```sh
curl -s "http://greg-zone:9011/api/repos/<id>/logs/<number>/<stepId>" \
  | jq -r '.[].data | @base64d'
```

The GitHub check's details link points at the same pipeline in the UI (`http://greg-zone:9011/repos/<id>/pipeline/<number>`) if a human wants to look instead.
