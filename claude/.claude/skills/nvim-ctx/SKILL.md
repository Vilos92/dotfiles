---
name: nvim-ctx
description: Fetch the current neovim context (open file, cursor position, and active selection) from a running nvim instance, then act on any instructions the user passed alongside the invocation. Trigger when the user types `/nvim-ctx` with or without arguments.
---

# nvim-ctx

## Parsing args

Args follow this shape: `[--session <name>] [instructions...]`

- If args begins with `--session <name>`, extract `<name>` as the tmux session to target and treat the remainder as instructions.
- Otherwise, use no session argument (defaults to current tmux session) and treat all args as instructions.

## Fetching context

Run:

```sh
nvim-ctx [<session>]
```

It outputs JSON with `file`, `start_line`, `end_line`, and `text` (active visual selection if one exists, otherwise the full buffer).

**If `nvim-ctx` fails** (no nvim pane found, nvim not running, socket not found): tell the user briefly what failed and ask them to paste the relevant code instead. Do not proceed as if you have context you don't have.

## After fetching

If instructions were provided, use the context to address them directly — the fetched file/selection is the subject.

If no instructions were provided, briefly surface what you found (file path, line range, whether it's a selection or full buffer) and wait for the user to tell you what they want.

Do not re-read the file with the Read tool just because you have the path — the JSON output already contains the text. Only reach for Read if you need lines outside the reported range.
