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

**Shell overrides:** In my interactive zsh, `cd` is hooked to **zoxide** (`z`) and `ls` is aliased to **eza**. For behavior that must match normal **`cd` / `ls`** (scripts, subshells, docs, CI, or when flags don't line up), use **`command cd`**, **`builtin cd`**, or **`command ls`** / **`/bin/ls`** as needed instead of the preferred tools above.

**Git aliases:** Use **`git merge-main`** to update the current branch from **`origin/main`** or **`origin/master`** (whichever exists)—it **requires a clean working tree** (no staged/uncommitted changes) and **prompts for confirmation** before fetching and merging; skip it for non-interactive or scripted flows unless you replicate the same steps explicitly.

**Indexed / fast repo search:** Where the environment exposes **fff** (e.g. MCP server, editor integration, or project tooling), prefer **fff** for search and file discovery over long chains of generic grep/find when it reduces noise and round-trips.

**Neovim context (`nvim-ctx`):** When the user mentions code they're looking at in nvim, references their neovim screen, or asks about something open in their editor — run `nvim-ctx` proactively before responding. Don't ask them to paste; fetch it yourself. It outputs JSON with `file`, `start_line`, `end_line`, and `text` (selection if active, whole buffer otherwise). Takes an optional session name: `nvim-ctx [session]`. If it fails, say so briefly and ask the user to paste instead.

If something is missing in a given environment, fall back to standard tools and note it briefly.

**Scope:** These preferences target everyday repo work (search, navigation, diffs). One-off diagnostics (**`dex dir`**, **`ls`** on a known path, **`head`**/**`cat`** on a single file) do not need to be forced through **`fd`**/**`rg`**/**`eza`** when that only adds friction.

---

## Delegating to subagents

Don't hesitate to spawn a subagent. Whenever you have well-founded confidence that a piece of work is **well-scoped** and matches a subagent's capabilities, hand it off — that's the default, not a last resort. The goal is to keep the main thread focused on the hard thinking while delegated workers grind through the clearly-defined parts.

**Pick the model to match the work:**

- **Opus** — broad or fuzzy work: larger planning, architecture, ambiguous problems, anything where judgment and tradeoffs matter. I'll usually be working with Opus directly for this kind of thing, so reserve subagent-Opus for when a delegated task genuinely carries that weight.
- **Sonnet** — the **default worker**. A strong, capable generalist for ordinary implementation tasks that are scoped but still need real reasoning. When in doubt, this is the pick.
- **Haiku** — tightly-defined mechanical work where the instructions fully specify the outcome: "replace all of these with that," "clean this up," bulk renames, formatting, file moves, rote find-and-replace. Fast and cheap for work that needs little judgment.

**Don't silently mis-size.** If a task feels too small to be worth a Sonnet, drop to Haiku; if a "simple" task turns out to carry real ambiguity or architectural stakes, flag it rather than pushing an underpowered worker at it. Match the model to the actual shape of the work.

---

## Progress tracking with dex

[**dex**](https://dex.rip/) is a local-first task and milestone tracker.

Before using dex, verify it's available:

```sh
command -v dex
```

If `dex` is not found, skip this section entirely and note it briefly—don't block the workflow.

### Invoking dex

Always pass an explicit `--config` and `--storage-path` so tasks come from the intended store. Without both flags, dex may resolve to a different config or DB than you expect (e.g. via `cwd`-based discovery or a default location).

```sh
dex --config "$HOME/.dex/projects/<profile>/config.toml" \
    --storage-path "$HOME/.dex/task-db/<profile>.jsonl" \
    <subcommand> [args...]
```

Examples:

```sh
dex --config "$HOME/.dex/projects/greg/config.toml" \
    --storage-path "$HOME/.dex/task-db/greg.jsonl" list

dex --config "$HOME/.dex/projects/front/config.toml" \
    --storage-path "$HOME/.dex/task-db/front.jsonl" \
    create --title "Follow up"
```

Full CLI reference:

```sh
dex --help
```

**Choosing a profile:** Profiles correspond to folders under `$HOME/.dex/projects/`. The standard ones are `greg` and `front`:

- **greg:** `$HOME/.dex/projects/greg/config.toml`
- **front:** `$HOME/.dex/projects/front/config.toml`

**Discovering available profiles:** Enumerate from `$HOME/.dex/projects`:

```sh
command ls "$HOME/.dex/projects"
# or every project config on disk:
fd -t f config.toml "$HOME/.dex/projects"
```

**Runtime source of truth (any repo):** Dex profiles live only under **`$HOME/.dex/projects/`**. The git repo you have open does **not** change profile locations or names. Do not infer profile from `pwd`, from `GREG_DOTFILES_PATH`, or from whether the project is "work" vs "personal" unless explicitly tied to a profile.

**`--config` means a file, not a registry:** Dex does **not** maintain a separate registry of profile names—folder names under `$HOME/.dex/projects/` are your dotfiles/stow layout, not something `dex` enumerates.

**Task storage vs config (`dex dir`, `--storage-path`):** `--config` alone does not bind tasks to a particular DB. If you're debugging "missing tasks," run `dex dir` with the **same** resolved `--config` + `--storage-path` you plan to use for `list` / `create`—if `dex dir` points somewhere unexpected, your `list` will too.

**Reading `dex --help` efficiently:** Scan **COMMANDS** once. If a verb is not listed, do not assume undocumented aliases unless you have other docs. **`dex config`** needs a key or **`dex config --list`** (use **`-g`** for global settings); bare **`dex config`** errors. **`dex dir`** prints the **resolved** task storage for **this** invocation (**cwd**, optional **`--config`**, optional **`--storage-path`**); it does **not** list profile folders under **`~/.dex/projects`**. Run **`dex --version`** when behavior might depend on release.

**Fast path:** (1) **`ls "$HOME/.dex/projects"`** (or **`fd`**) for profile names. (2) **`dex --help`** only to confirm verbs and flags for task workflows (**list**, **create**, **`dir`**, **`config`**, **`--storage-path`**, …)—**not** to discover profile names. (3) **`dex dir`** before trusting **`list`** output; always pass **`--storage-path <storage-dir>`** so tasks come from a specific store.

**Dotfiles provenance (only when editing personal dotfiles):** In Greg's dotfiles repo, versioned stubs live at **`dex/.dex/projects/greg/config.toml`** (stow package **`dex`**) and, in the **front** submodule, **`front/.dex/projects/front/config.toml`** (stow package **`front`**). Task JSONL may sit under **`dex/.dex/task-db/greg.jsonl/tasks.jsonl`** and **`front/.dex/task-db/front.jsonl/tasks.jsonl`** (a **`*.jsonl`** directory next to **`tasks.jsonl`**); Greg may version those separately from the profile **`config.toml`**. **`--config`** alone does **not** imply dex reads that checkout-local **`task-db`**—confirm with **`dex dir`** and pass **`--storage-path`** to the **storage directory** (see above), not to **`tasks.jsonl`**. Agents in **other** repositories should still use **`$HOME/.dex/projects/...`** for **`--config`** unless the user explicitly asks to work from repo paths.

**Repo-local `.dex/`:** Folders named `.dex/` inside some clone are **not** the default dex profile for agents. Ignore them for normal dex workflows unless the user explicitly opts into repo-local dex; prefer **`$HOME/.dex/projects/<name>/config.toml`** for every `dex --config`.

**When to prompt:** At the start of any significant new task (new feature, refactor, bug investigation, multi-step build, etc.), ask once:

> "Would you like to track this work in dex?"

Don't ask for trivial one-offs, quick lookups, or single-file edits.

**How to work with dex iteratively:**

1. **Define milestones up front.** Before starting, propose a milestone breakdown based on the task scope and confirm it with the user before creating anything in dex.
2. **Tie commits to milestones.** Each commit should map to forward progress on a milestone. Reference the relevant dex milestone or task ID in the commit message where applicable.
3. **Run the workspace's quality checks before committing.** At each milestone boundary, look for and run whatever the project uses—tests, linting, typechecking, formatting checks, etc. Infer the right commands from the project's tooling (e.g. `package.json` scripts, `Makefile`, `pyproject.toml`, `Cargo.toml`, CI config). Prefer running `test`, `lint`, `typecheck`, and `format:check` targets (or their equivalents) rather than invoking tools directly, so the project's own configuration is respected. If checks fail: fix straightforward technical issues (type errors, lint violations, broken assertions) autonomously and re-run to confirm. If a failure involves ambiguity, a product decision, or non-trivial tradeoffs, surface it clearly with enough context for the user to make the call—don't guess or paper over it.
4. **Always pause before staging or committing.** Show the user what files will be added (`git status`, `git diff`) and get explicit confirmation before running `git add` or `git commit`. The user should be able to review changes locally before the work is locked in.
5. **Check in at milestone boundaries.** When a milestone is complete and quality checks pass, surface a short summary of what changed and what's next, then wait for the user to confirm before moving to the next milestone.
6. **Don't rush ahead.** Prefer smaller, reviewable commits over large batches. If unsure whether to bundle or split changes, ask.

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
