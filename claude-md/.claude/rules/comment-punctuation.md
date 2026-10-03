---
# One file serves both harnesses. omp reads name, description, condition and
# scope. Claude Code reads only paths and ignores the rest. The Claude Code
# hook in claude-md/.claude/hooks/comment-punctuation.py runs the same check.
name: comment-punctuation
description: "No semicolons or punctuation dashes in // and /* */ comments"
# Single-quoted so YAML keeps the backslashes. Each pattern skips a leading
# list bullet, and the // pattern skips URLs (https://...).
condition:
  - '(^|[^:])//[ \t]*[^\s\-/][^\n]*(;|—|–| -- | - )'
  - '(^|\n)[ \t]*\*[ \t]+[^\s\-*/][^\n]*(;|—|–| -- | - )'
  - '/\*+[ \t]*[^\s\-*][^\n*]*(;|—|–| -- | - )'
scope: "tool:edit(*.{ts,tsx,mts,cts,js,jsx,mjs,cjs}), tool:write(*.{ts,tsx,mts,cts,js,jsx,mjs,cjs})"
paths:
  - "**/*.{ts,tsx,mts,cts,js,jsx,mjs,cjs}"
---

Keep semicolons, and dashes used as punctuation, out of code comments. That
means `;`, the em dash `—`, the en dash `–`, and the ASCII stand-ins ` -- ` and
` - `. Split the thought into two sentences, or use a comma or a colon.

Hyphenated words (`read-only`) and list bullets at the start of a comment line
are fine. This applies to comments only, not to code or strings.
