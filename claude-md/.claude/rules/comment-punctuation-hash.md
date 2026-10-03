---
# One file serves both harnesses. omp reads name, description, condition and
# scope. Claude Code reads only paths and ignores the rest. The Claude Code
# hook in claude-md/.claude/hooks/comment-punctuation.py runs the same check.
name: comment-punctuation-hash
description: "No semicolons or punctuation dashes in # comments"
# Single-quoted so YAML keeps the backslashes. The first pattern matches
# whole-line comments and skips shebangs and leading list bullets. The second
# matches trailing comments, which need whitespace on both sides of the #.
condition:
  - '(^|\n)[ \t]*#[ \t]*[^\s!\-#][^\n]*(;|—|–| -- | - )'
  - '[ \t]#[ \t]+[^\s\-][^\n]*(;|—|–| -- | - )'
scope: "tool:edit(*.{sh,bash,zsh,py,yml,yaml,toml}), tool:write(*.{sh,bash,zsh,py,yml,yaml,toml})"
paths:
  - "**/*.{sh,bash,zsh,py,yml,yaml,toml}"
---

Keep semicolons, and dashes used as punctuation, out of code comments. That
means `;`, the em dash `—`, the en dash `–`, and the ASCII stand-ins ` -- ` and
` - `. Split the thought into two sentences, or use a comma or a colon.

Hyphenated words (`read-only`) and list bullets at the start of a comment line
are fine. This applies to comments only, not to code or strings.
