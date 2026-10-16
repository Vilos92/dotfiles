---
# One file serves both harnesses. omp reads name, description, condition and
# scope. Claude Code reads only paths and ignores the rest.
name: no-opaque-conditionals
description: "No conditional spreads, and no ternaries used as control flow"
# Single-quoted so YAML keeps the backslashes. Each pattern allows one level of
# nested parentheses in the condition, such as a function call. The first
# matches `...(x && {`, the other two a ternary with an empty-object branch.
condition:
  - '\.\.\.\((?:[^()]|\([^()]*\))*?&&\s*\{'
  - '\.\.\.\((?:[^()]|\([^()]*\))*?\?[^:]*:\s*\{\s*\}\s*\)'
  - '\.\.\.\((?:[^()]|\([^()]*\))*?\?\s*\{\s*\}\s*:'
scope: "tool:edit(*.{ts,tsx,mts,cts,js,jsx,mjs,cjs}), tool:write(*.{ts,tsx,mts,cts,js,jsx,mjs,cjs})"
paths:
  - "**/*.{ts,tsx,mts,cts,js,jsx,mjs,cjs}"
---

Keep branching out of expressions. A ternary is fine when it fits on one line
and picks between two plain values: `const label = isOpen ? 'Open' : 'Closed'`.

Avoid conditional spreads such as `...(x && {x})` or `...(x ? {x} : {})`. The
reader has to work out which object shape comes out. Instead:

- If the field can be `undefined`, assign it directly: `name: options.name`.
- If the key must be absent, compute the object in a small helper with early
  returns. Assigning `undefined` is not the same as omitting the key when the
  project enables `exactOptionalPropertyTypes`, or when code checks
  `'key' in obj` or `Object.keys`.

Write `if`/`else` instead of a ternary when the ternary spans several lines, or
when a branch calls a function, uses `await`, or has side effects. That is
control flow, not a value pick.

Move a ternary out of a function argument or object literal into a named
`const` first.

Nested ternaries have their own rule, `no-nested-ternary`.
