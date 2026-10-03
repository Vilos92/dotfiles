---
# One file serves both harnesses. omp reads name, description, condition and
# scope. Claude Code reads only paths and ignores the rest.
name: no-array-mutation
description: "Avoid mutating array methods"
condition:
  - "\\.(push|pop|shift|unshift|splice|sort|reverse)\\("
scope: "tool:edit(*.{ts,tsx,mts,cts,js,jsx,mjs,cjs}), tool:write(*.{ts,tsx,mts,cts,js,jsx,mjs,cjs})"
paths:
  - "**/*.{ts,tsx,mts,cts,js,jsx,mjs,cjs}"
---

Avoid mutating arrays in place. Prefer non-mutating equivalents:

- `push`/`unshift` → spread (`[...arr, x]`) or `concat`
- `splice` → `toSpliced`, or `filter`/`slice`
- `sort` → `toSorted`; `reverse` → `toReversed`
- building up with `push` in a loop → `map`/`filter`/`flatMap`/`reduce`

Mutation is fine on a local array that never escapes the function, if it's
clearly simpler.
