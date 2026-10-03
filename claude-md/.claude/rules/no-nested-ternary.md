---
# One file serves both harnesses. omp reads name, description, condition and
# scope. Claude Code reads only paths and ignores the rest.
name: no-nested-ternary
description: "Never nest ternary expressions"
condition:
  - " \\? [^;\\n]* \\? "
  - "\\n\\s*:[^\\n]*\\n\\s*\\? "
scope: "tool:edit(*.{ts,tsx,mts,cts,js,jsx,mjs,cjs}), tool:write(*.{ts,tsx,mts,cts,js,jsx,mjs,cjs})"
paths:
  - "**/*.{ts,tsx,mts,cts,js,jsx,mjs,cjs}"
---

Do not nest ternary expressions (a ternary inside another ternary's branches).
Rewrite it as one of these instead:

- an if/else chain or early returns
- a switch statement
- a lookup object/map
- a small named helper function that returns the value

A single, non-nested ternary is fine.
