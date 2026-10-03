---
# One file serves both harnesses. omp reads name, description, condition and
# scope. Claude Code reads only paths and ignores the rest.
name: prefer-const
description: "Prefer const and non-mutating patterns over let"
condition:
  - "(^|[\\n;{}])\\s*let\\s+[A-Za-z_$]"
scope: "tool:edit(*.{ts,tsx,mts,cts,js,jsx,mjs,cjs}), tool:write(*.{ts,tsx,mts,cts,js,jsx,mjs,cjs})"
paths:
  - "**/*.{ts,tsx,mts,cts,js,jsx,mjs,cjs}"
---

Avoid `let` and reassignment. Declare values with `const` and compute them
in a single expression instead:

- Conditional value: extract a small function with early returns, or use
  a lookup object, instead of `let x; if (...) x = ...`.
- Building arrays: use `map`/`filter`/`flatMap` instead of `let arr = []` plus `push`.
- Accumulating: use `reduce`, or a helper function, instead of `let total = 0`
  plus a loop.
- Updating objects/arrays: create a new value with spread, `toSorted`,
  `toReversed`, `with`, or `structuredClone` instead of mutating in place.

`let` is acceptable only when reassignment is genuinely clearer (e.g., a
retry loop or a performance-critical hot path). If you keep one, say why.
