---
name: nucleo-icons
description: >-
  Find and insert Nucleo icons using the nucleo-icons MCP server. Works with any
  installed families (core, ui, sharp, micro, pixel, free families like
  social-media / isometric / flags, or any subset).
  Expands abstract requests into concrete search terms and ranks results by
  confidence. Use when the user asks for Nucleo icons, icon search, SVG icons,
  or mentions nucleo.
---

# Nucleo Icons

## Division of labor

| Layer | Responsibility |
|-------|----------------|
| **MCP search** | Exact match on Nucleo labels and tags for **installed** families |
| **You (agent)** | Check installed families, interpret intent, normalize vocabulary, suggest related terms, merge results, rank confidence |

Do not expect the MCP to infer concepts like "project" → folder. That is your job.

## Step 0 — Discover what is installed (always)

Call `nucleo_list_families` before the first search in a conversation.

Use the response:

- `installedFamilies` — families you can search and fetch from now
- `licensedFamilies` — what this product license includes (from `manifest.json`)
- `product` — e.g. `nucleo-core`, `nucleo-bundle`

Only search or fetch icons in **installed** families. If a user asks for a family that is licensed but not installed, tell them to download that family's icon pack.

### Multiple MCP servers

If the user has separate installs (e.g. core MCP + sharp MCP), each server has its own `nucleo_list_families` response. Search each relevant server and merge results. Dedupe by `family` + `id`.

## Workflow

```
- [ ] 0. nucleo_list_families (per MCP server if multiple)
- [ ] 1. Parse request (subject / exact name, style, family preference)
- [ ] 1b. If no family was named → nucleo-family skill, then search only that family
- [ ] 2. If user gave an exact icon name → by-name path (below)
- [ ] 3. Else build literal search query
- [ ] 4. nucleo_search_icons (source: literal, family: all or specific)
- [ ] 5. If weak/no results OR abstract concept → 1–2 expanded searches
- [ ] 6. Merge, dedupe by family+id, rank confidence
- [ ] 7. Present options
- [ ] 8. nucleo_get_icon for the chosen icon
```

## Get by exact name (label)

When the user asks for a specific Nucleo name — e.g. `user-key`, `calendar-check`, “the icon named accessibility” — treat that string as the **label**. Do not expand to synonyms.

1. Pass the name as `query` to `nucleo_search_icons` with `source: "literal"` (and `fill` / `size` / `family` when given).
2. Prefer results with `match.type: "exact_label"`.
3. Or call `nucleo_get_icon` with `label` (+ `family`, and `fill` + `size` when needed).

Examples:

| User says | Tools |
|-----------|--------|
| “Get nucleo icon named `user-key`, outline, 18px” | `search` query=`user-key`, fill=`outline`, size=`18px` → then `get_icon` with that id, **or** `get_icon` family=`ui`, label=`user-key`, fill=`outline`, size=`18px` |
| “Get `user-key` from core” | `search` query=`user-key`, family=`core` (or `get_icon` with family + label; add fill/size if multiple variants) |
| “Filled `user-key` in core, 24px” | fill=`glyph` (filled → glyph), size=`24px`, family=`core` |

Note: “fill” as a **style** means glyph; “core” / “ui” are **families**, not fills.

If the exact name has no match, say so — do not invent a different icon unless the user asks for alternatives.
## Parse the request

Extract:

- **Subject(s)** — what to depict (may be abstract: "project", "security")
- **Modifiers** — fill style, size, family preference (`core`, `ui`, `sharp`, `micro`, `pixel`, …)
- **Multi-part icons** — e.g. "calendar with a checkmark" = two subjects

Respect family preference only if that family is **installed**. Otherwise explain and use installed families.

## Fill styles (from icons.json)

Pass `fill` to `nucleo_search_icons` when the user asks for a style. Canonical values:

| Canonical | Also accept | Typical families | Meaning |
|-----------|-------------|------------------|---------|
| `outline` | stroke | core, ui, pixel, sharp | Mostly stroke |
| `outline-duo` | outline duo | ui | Stroke + some lower-opacity fill |
| `glyph` | filled, fill, solid | core, ui, micro | Mostly filled |
| `glyph-duo` | fill-duo, filled-duo | ui | Fill + one or two soft fills (`0.4` and/or `0.2`) |

Check `nucleo_list_families` — each installed family lists available `fills` and `sizes`.

## Sizes

Pass `size` as `18px`, `24px`, `32px`, `48px`, or a bare number (`24` → `24px`).

Typical sizes by family (confirm via `list_families`):

- **ui** — often `18px` (sometimes `12px`)
- **core** — `24px`, `32px`, `48px`

If the user asks for a size that a family doesn't have, say so and offer the closest installed size.

## Build the literal query

Rewrite user words into terms Nucleo uses in labels/tags:

- `checkmark` → `check`
- `tick` → `check`
- `picture` / `photo` → `image`
- `email` → `mail`
- `gear` / `cog` → `settings`

Join multiple subjects with spaces: `calendar check`

Call `nucleo_search_icons` with `source: "literal"`. If the user named a family, pass it. If they did not, follow the **nucleo-family** skill first and pass the family it chooses. Do not search `family: "all"` while that skill has a chosen family. Pass `fill` / `size` when the user asked for a style or size.

## When to expand (conceptual search)

Run **1–2 additional searches** with `source: "expanded"` when:

- Literal search returns 0 results
- Results are clearly off
- User used an abstract noun (project, workflow, onboarding, analytics)

Pick **concrete nouns** likely to appear as Nucleo labels/tags:

| User says | Also try (max 2) |
|-----------|------------------|
| project | `folder`, `gantt` |
| workflow | `diagram`, `flow` |
| security | `lock`, `shield` |
| analytics | `chart`, `graph` |

## Confidence ranking (internal only)

Use this to decide order and which options to keep. **Do not show** confidence labels, match types (`exact_label`, etc.), or `source` (`literal` / `expanded`) to the user.

**High** — `source: "literal"` and `match.type` is `exact_label`, `label_part`, or `compound_label`; or all concepts matched

**Medium** — `source: "literal"` + `exact_tag`; or `source: "expanded"` with strong visual fit

**Low** — `source: "expanded"` only, or partial multi-concept match

Dedupe by **`family` + `id`**. Keep the highest-confidence entry. Prefer showing distinct labels (and sizes) rather than many duplicates of the same icon at different sizes unless the user asked for a size.

## Present results

Show a short clean list. Include **label**, **family**, **fill**, and **size** only.

**Do not show:**

- icon `id`
- match type (`exact label`, `exact_tag`, …)
- confidence (`high` / `medium` / `low`)
- whether the search was literal or expanded

Format:

```
1. calendar (core) — outline · 24px
2. calendar (core) — outline · 32px
3. calendar (ui) — outline · 18px
```

If you mention a related option (e.g. `calendar-check`), use the same format — no ids, no match explanations.

Include the **family** in every suggestion — the same label can exist in multiple families with different SVGs.

## Insert the icon

`nucleo_get_icon` requires **`family`** and either `id` or exact `label`. With `label`, pass `fill` and `size` when the name has multiple variants. Use `id` only when calling the tool — never display it to the user unless they ask.

### React / Vue package (`target: "react"` or `"vue"`)

Search / get_icon return `component` and `componentPath` (from `icons.json`). Prefer a **component in the user’s project**, not raw SVG. There is no `icons/` folder in component packages.

`componentPath` is **only** where the source lives in the local Nucleo install (under `NUCLEO_SKILLS_ROOT`, e.g. `~/.nucleo/skills`). It is **not** an import path for the app.

**Never** import from `~/.nucleo/skills`, `NUCLEO_SKILLS_ROOT`, or an absolute machine path. Those files are not in the git repo; the project will fail for others and in CI.

**Do this instead:**

1. Read the component from the install: `{NUCLEO_SKILLS_ROOT}/{componentPath}`
   - React example: `core/components/CalendarOutline24.tsx`
   - Vue example: `core/components/CalendarOutline24.vue`
2. Copy it into the project (match existing icon folders, or create one e.g. `src/components/icons/`)
3. Import from that **project-relative** path

```tsx
// React — local to the repo
import { CalendarOutline24 } from "./components/icons/CalendarOutline24";
```

```vue
<!-- Vue — local to the repo -->
<script setup lang="ts">
import CalendarOutline24 from "./components/icons/CalendarOutline24.vue";
</script>
```

```ts
// ❌ never (any target)
import { CalendarOutline24 } from "/Users/you/.nucleo/skills/core/components/CalendarOutline24";
```

Apply **nucleo-customize** on the copied file / usage, not by pointing at the skills install.

### Vanilla package (`target: "vanilla"`)

Use the SVG from get_icon / `{family}/icons/{id}.svg`.

For color, stroke width, opacity, corners, and **glass id prefixing**, follow the **nucleo-customize** skill. Read `target` from `nucleo_list_families` / `manifest.json` (`react` | `vue` | `vanilla`) before inserting.

When inserting free **`glass`** SVGs in vanilla, rewrite every `id` / `url(#…)` with a fresh prefix so multiple instances on the same page do not collide. React and Vue glass components already do this via `useId` / `uniqueId`.

## MCP tools

| Tool | Use |
|------|-----|
| `nucleo_list_families` | Installed + licensed families; call first |
| `nucleo_list_sets` | Browse taxonomy within one family |
| `nucleo_search_icons` | Search; optional `family`, `fill`, `size`, `setLabel`; always set `source` |
| `nucleo_get_icon` | Fetch by `id`, or by exact `label` (+ optional `fill` / `size`) |

## Examples

**Bundle user, any icon**

1. `nucleo_list_families` → core, ui, sharp installed
2. Search `calendar check`, `family: "all"`
3. Pick result; note family in output

**Core-only install**

1. `nucleo_list_families` → only `core`
2. User asks for "UI outline icon" → explain UI not installed; offer core alternatives

**"Outline settings icon, 24px"**

1. Search `settings`, `fill: "outline"`, `size: "24px"`
2. Prefer families that advertise those fills/sizes in `list_families`

**Abstract: "icon for project"**

1. Literal `project` across installed families
2. Expanded `folder`, `gantt` with `source: "expanded"`
3. Merge; folders may be expanded suggestions
