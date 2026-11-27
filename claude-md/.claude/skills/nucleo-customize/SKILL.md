---
name: nucleo-customize
description: >-
  Customize Nucleo icons when inserting or editing them: primary color via
  currentColor, secondary color via data-color="color-2", stroke width for
  core/ui outline and free arcade, duo soft opacity for ui outline-duo/glyph-duo,
  and corners for core outline and arcade. Works for React, Vue, and vanilla. Use when
  the user asks to change icon color, secondary color, stroke width, thickness,
  opacity, corners, rounded/sharp ends, or customize a Nucleo icon.
---

# Nucleo Customize

Use this skill **after** an icon is chosen (via `nucleo-icons` + MCP). One skill covers **React**, **Vue**, and **vanilla** — behavior depends on package `target`. Component targets (`react`, `vue`) share the same prop names (`strokeWidth`, `duoOpacity`, `duoOpacityHigh`, `duoOpacityLow`, `corners`, `uniqueId`).

## Step 0 — Detect package target

Call `nucleo_list_families` (or read `manifest.json` at `NUCLEO_SKILLS_ROOT`).

Use:

| Field | Meaning |
|-------|---------|
| `target` | `react`, `vue`, or `vanilla` (required for correct output) |
| `family` + `fills` | Whether stroke-width customization applies |

If `target` is missing, ask the user whether they use the React, Vue, or vanilla package — do not guess.

Vue vs React syntax (same props): Vue uses `class` not `className`; bind with `:` (`:stroke-width="1"`). Copy `.vue` files, not `.tsx`. Glass: Vue 3.5+ `useId` (already in prepared SFCs).

## What can be customized (now)

| Feature | When it applies | Component (`react` / `vue`) | Vanilla |
|---------|-----------------|-----------------------------|---------|
| **Primary color** | Pro icons with `currentColor`, and free **social-media** | React: `className` / `style.color`; Vue: `class` / `:style="{ color }"` | CSS `color` |
| **Secondary color** | Elements with `data-color="color-2"` (mostly Pro) | Attribute / Tailwind data selector / CSS | CSS attribute selector |
| **Stroke width** | **Only** `core` + `outline`, `ui` + `outline` / `outline-duo`, or free **`arcade`** (default `4`) | Prop `strokeWidth` | CSS var `--nucleo-stroke-width` |
| **Duo opacity** | **Only** `ui` + `outline-duo` or `glyph-duo` (fill-duo) | Outline-duo: `duoOpacity`. Glyph-duo: `duoOpacityHigh` / `duoOpacityLow` (only props whose layers exist) | Outline-duo: `--nucleo-outline-duo-opacity`. Glyph-duo: `--nucleo-glyph-duo-opacity-high` / `--nucleo-glyph-duo-opacity-low` |
| **Corners** | **Only** `core` + `outline`, or free **`arcade`** | Prop `corners` (`"square"` default \| `"round"`) | CSS vars `--nucleo-stroke-linejoin` / `--nucleo-stroke-linecap` / `--nucleo-stroke-linecap-butt` |
| **Arcade colors** | Free **`arcade` only** | `style` CSS vars `--nc-arcade-color-1|2|3` | Same CSS vars on `svg` |
| **Isometric colors** | Free **`isometric` only** | `style` CSS vars `--nc-isometric-color-1|2` | Same CSS vars on `svg` |
| **Glass colors** | Free **`glass` only** | `style` CSS vars `--nc-gradient-*` / `--nc-light` | Same CSS vars on `svg` |

### Free families

| Family | Customization |
|--------|----------------|
| `flags` | **None** — keep painted colors |
| `cursors` | **None** — keep painted colors |
| `credit-cards` | **None** — keep painted colors |
| `social-media` | **Primary color** via `currentColor` (default ink was `#212121`) |
| `isometric` | **2 colors** via `--nc-isometric-color-1|2` (defaults `#212121` / `#2121214D`) |
| `arcade` | **Stroke width** (default `4`), **corners** (`round` \| `square`), **3 colors** via `--nc-arcade-color-1|2|3` |
| `glass` | **5 colors** via `--nc-gradient-1-color-1|2`, `--nc-gradient-2-color-1|2`, `--nc-light` |

If the user asks to recolor `flags`, `cursors`, or `credit-cards`, explain those stay as designed and offer a different free/Pro family instead.

For `social-media`, use the same primary-color patterns as Pro (`className` / `style.color` / CSS `color`). Do **not** offer stroke width, duo opacity, or corners on social-media.

### Isometric (free)

| CSS variable | Default |
|--------------|---------|
| `--nc-isometric-color-1` | `#212121` |
| `--nc-isometric-color-2` | `#2121214D` |

**React**

```tsx
<BurgerColored24
  style={
    {
      ["--nc-isometric-color-1"]: "#0f172a",
      ["--nc-isometric-color-2"]: "#0f172a4D",
    } as React.CSSProperties
  }
/>
```

**Vanilla**

```css
svg.isometric-icon {
  --nc-isometric-color-1: #0f172a;
  --nc-isometric-color-2: #0f172a4D;
}
```

### Arcade (free)

Defaults match the arcade docs:

| CSS variable | Default |
|--------------|---------|
| `--nc-arcade-color-1` | `#212121` |
| `--nc-arcade-color-2` | `#21212140` |
| `--nc-arcade-color-3` | `#21212100` |

Prepared SVGs/components use `stroke="var(--nc-arcade-color-N, <fallback>)"`. Override on the root element:

**React**

```tsx
<DragUpColored30
  strokeWidth={3}
  corners="round"
  style={
    {
      ["--nc-arcade-color-1"]: "#ff4d4d",
      ["--nc-arcade-color-2"]: "#ff4d4d40",
      ["--nc-arcade-color-3"]: "#ff4d4d00",
    } as React.CSSProperties
  }
/>
```

**Vanilla**

```css
svg.arcade-icon {
  --nc-arcade-color-1: #ff4d4d;
  --nc-arcade-color-2: #ff4d4d40;
  --nc-arcade-color-3: #ff4d4d00;
  --nucleo-stroke-width: 3;
  --nucleo-stroke-linecap: round;
  --nucleo-stroke-linejoin: round;
}
```

- Stroke: React `strokeWidth` prop (default `4`) or `--nucleo-stroke-width`
- Corners: React `corners="round"|"square"` (default square); vanilla same CSS vars as core outline (`--nucleo-stroke-linecap` / `--nucleo-stroke-linejoin`). Square ≈ linecap `square` + linejoin `miter`; round sets both to `round`.

### Glass (free)

| CSS variable | Default |
|--------------|---------|
| `--nc-gradient-1-color-1` | `#575757` |
| `--nc-gradient-1-color-2` | `#151515` |
| `--nc-gradient-2-color-1` | `#E3E3E599` |
| `--nc-gradient-2-color-2` | `#BBBBC099` |
| `--nc-light` | `#FFFFFF` |

Prepared SVGs use these on gradient `stop-color` attributes. Mask luminance fills stay absolute `#FFF` / `#000`.

Glass icons also use internal `id` / `url(#…)` links (gradients, masks, filters, clipPaths). **Two instances of the same icon on one page will collide** unless ids are prefixed.

**React / Vue** — prepared components already handle this: `useId()` prefixes every id/ref by default. Optional `uniqueId` overrides the prefix.

```tsx
<SlidersVerticalColored24 />
<SlidersVerticalColored24 uniqueId="hero-" />
```

```vue
<SlidersVerticalColored24 />
<SlidersVerticalColored24 unique-id="hero-" />
<SlidersVerticalColored24
  :style="{
    '--nc-gradient-1-color-1': '#3b82f6',
    '--nc-gradient-1-color-2': '#1e3a8a',
    '--nc-light': '#ffffff',
  }"
/>
```

```tsx
<SlidersVerticalColored24
  style={
    {
      ["--nc-gradient-1-color-1"]: "#3b82f6",
      ["--nc-gradient-1-color-2"]: "#1e3a8a",
      ["--nc-gradient-2-color-1"]: "#93c5fd99",
      ["--nc-gradient-2-color-2"]: "#60a5fa99",
      ["--nc-light"]: "#ffffff",
    } as React.CSSProperties
  }
/>
```

**Vanilla** — packaged SVGs keep stable source ids. **On every insert**, rewrite ids with a fresh short prefix (e.g. `nc-a7f3-`):

1. Collect every `id="…"` value in the SVG
2. Prefix each `id="…"` and every matching `url(#…)` (also on `mask` / `filter` / `clip-path`) with that prefix
3. Use a **new** prefix each time the same icon is inserted again

```css
svg.glass-icon {
  --nc-gradient-1-color-1: #3b82f6;
  --nc-gradient-1-color-2: #1e3a8a;
  --nc-gradient-2-color-1: #93c5fd99;
  --nc-gradient-2-color-2: #60a5fa99;
  --nc-light: #ffffff;
}
```

### Stroke width — strict rules

Customizable **only** for:

- **core** + fill `outline` (default `2`)
- **ui** + fill `outline` or `outline-duo` (default `1.5`)
- free **`arcade`** (any fill, including `colored`; default `4`)

Arcade is **not** an outline family. Still apply `strokeWidth` / `--nucleo-stroke-width` when the user asks to change thickness.

**Not** customizable for stroke width outside the allowed cases, including:

- `sharp`, `pixel`, `micro`
- free families other than `arcade` (`flags`, `cursors`, `credit-cards`, `social-media`, `isometric`, `glass`)
- `glyph` / `glyph-duo` on Pro families (including core/ui)

If the user asks to change stroke width outside the allowed cases (e.g. sharp or pixel outline), explain it isn’t supported and offer color / size instead. **Never** refuse stroke width or corners on `arcade`.

## Workflow

```
- [ ] 0. Detect target (react | vue | vanilla)
- [ ] 1. Confirm icon family + fill (from search result)
- [ ] 1b. If free family: apply free rules (social-media currentColor; isometric 2 color vars; glass 5 color vars + id prefix; flags/cursors/credit-cards none; arcade stroke+corners+3 color vars)
- [ ] 1c. If free `glass` + vanilla: rewrite all `id` / `url(#…)` with a fresh prefix before insert (React/Vue components already use `useId` / `uniqueId`)
- [ ] 2. Apply primary color if requested (and allowed for that family)
- [ ] 3. Apply secondary color if requested (data-color="color-2" only)
- [ ] 4. Apply stroke width if core outline, ui outline/outline-duo, **or arcade**
- [ ] 5. Apply duo opacity: outline-duo → `duoOpacity`; glyph-duo unnamed single value → `duoOpacityHigh` (0.4 layer) + mention two-layer icons / offer a 0.2 value; named layers → high and/or low as asked
- [ ] 6. Apply corners if core outline **or arcade** (both default to square/miter; set to round if asked)
- [ ] 7. Insert / update code in the project (component targets: copy into the repo; never import from ~/.nucleo/skills)
```

## Primary color

Prepared icons use `currentColor` for primary fills/strokes (elements without a secondary treatment, or the main ink).

**React**

```tsx
<CalendarOutline24 className="text-slate-900" />
// or
<CalendarOutline24 style={{ color: "#0f172a" }} />
```

**Vue**

```vue
<CalendarOutline24 class="text-slate-900" />
<CalendarOutline24 :style="{ color: '#0f172a' }" />
```

**Vanilla**

```html
<svg class="icon" style="color: #0f172a">…</svg>
```

```css
.icon { color: #0f172a; }
```

## Secondary color (`data-color="color-2"`)

Many icons include parts marked `data-color="color-2"`. When the user asks for a **second / secondary / accent** color, style **only** those elements — do not recolor the whole icon.

Match the project’s styling approach. Prefer the same system they already use (Tailwind vs plain CSS).

### Plain CSS (always valid)

Prepared icons already use `fill="currentColor"` / `stroke="currentColor"` on inked parts. For a secondary color, set **`color`** on `[data-color="color-2"]` only — that is enough.

```css
.icon {
  color: #0f172a; /* primary → currentColor on the main parts */
}

.icon [data-color="color-2"] {
  color: #ef4444; /* secondary → currentColor on color-2 parts only */
}
```

For inline SVG without a class:

```html
<svg style="color: #0f172a">…</svg>
```

```css
svg [data-color="color-2"] {
  color: #ef4444;
}
```

Only if something still doesn’t recolor (unusual), fall back to explicit `fill` / `stroke` on that selector. Prefer `color` first.

### Tailwind

Target the attribute with a data variant (syntax may vary slightly by Tailwind version):

```html
<!-- React -->
<CalendarOutline24 className="text-slate-900 **:data-[color=color-2]:text-red-500" />
```

```html
<!-- Vanilla / HTML -->
<svg class="text-slate-900 **:data-[color=color-2]:text-red-500">…</svg>
```

If the project’s Tailwind setup doesn’t support `**:` or that data syntax, fall back to plain CSS (above) or a small wrapper class.

### React without Tailwind

```tsx
<CalendarOutline24
  className="nucleo-icon"
  style={{ color: "#0f172a" }}
/>
```

```css
.nucleo-icon [data-color="color-2"] {
  color: #ef4444;
}
```

## Stroke width

Allowed when **any** of these is true:

- Family is `core` and fill is `outline` (default `2`)
- Family is `ui` and fill is `outline` or `outline-duo` (default `1.5`)
- Family is **`arcade`** (default `4`) — fill is typically `colored`; that does **not** block stroke width

### React (`target: "react"`)

```tsx
<CalendarOutline24 strokeWidth={1} />
```

### Vue (`target: "vue"`)

```vue
<CalendarOutline24 :stroke-width="1" />
```

### Vanilla (`target: "vanilla"`)

Prepared SVGs use a **CSS variable with a fallback** (no inline default on `<svg>`), so a normal stylesheet override works:

```html
<!-- baked in: stroke-width="var(--nucleo-stroke-width, 1.5)" -->
<svg …>…</svg>
```

```css
svg {
  --nucleo-stroke-width: 1; /* overrides the 1.5 / 2 fallback */
}
```

Defaults in the fallback: **core** `2`, **ui** `1.5`, **arcade** `4`.

Do **not** use a component `strokeWidth` prop in vanilla HTML/JS.

## Duo opacity (soft layer)

Applies **only** to **ui** icons with fill `outline-duo` or `glyph-duo` (also called fill-duo).

Prepared icons:

1. Normalize `fill-opacity` / `stroke-opacity` → `opacity`
2. Controllable values depend on fill (other opacities such as `0` / `1` stay fixed)

### Outline-duo — one layer

Controllable: **`0.3`**. Prop **`duoOpacity`** (default `0.3`). Vanilla: `--nucleo-outline-duo-opacity`.

### Glyph-duo — one or two layers

Controllable:

| Layer in the SVG | Default | Component prop | Vanilla CSS var |
|------------------|---------|----------------|-----------------|
| **`0.4`** (higher / stronger soft) | `0.4` | `duoOpacityHigh` | `--nucleo-glyph-duo-opacity-high` |
| **`0.2`** (lower / lighter soft) | `0.2` | `duoOpacityLow` | `--nucleo-glyph-duo-opacity-low` |

Some glyph-duo icons have **both** layers, some only `0.4`, some only `0.2`. Only emit/set the props (or CSS vars) for layers that exist on **that** icon. Do not add a missing layer.

User language:

| User says | What to set |
|-----------|-------------|
| One opacity, **no** “higher/lower” / “0.4 vs 0.2” / “lighter vs stronger” | **`duoOpacityHigh` only** (the 0.4 layer) if that prop exists on the file. If the prepared icon has **only** `duoOpacityLow`, set that instead (it is the only soft layer). Leave the other layer at its default. |
| Explicitly the higher / 0.4 / stronger soft layer | `duoOpacityHigh` / `--nucleo-glyph-duo-opacity-high` |
| Explicitly the lower / 0.2 / lighter soft layer | `duoOpacityLow` / `--nucleo-glyph-duo-opacity-low` |
| Two values, or both layers named | Set high and low as requested |
| Outline-duo + one opacity | `duoOpacity` / `--nucleo-outline-duo-opacity` only |

Whenever the user gives a **single** glyph-duo opacity without saying which layer, after applying the high (0.4) layer:

1. Briefly explain that **some** UI glyph-duo icons have **two** soft opacities (defaults 0.4 and 0.2), not only the icon they are inserting.
2. Ask if they also want a value for the **lower** (0.2) layer — even if the current file has no `duoOpacityLow`. Do not invent a low layer on this icon.

Do **not** use `duoOpacity` on glyph-duo. Do **not** use `duoOpacityHigh` / `duoOpacityLow` on outline-duo. Do not use a generic `opacity` prop for the soft duo layer.

### React (`target: "react"`)

```tsx
<ArrowBoldDownOutlineDuo18 duoOpacity={0.5} strokeWidth={1.5} />
<AccessibilityGlyphDuo18 duoOpacityHigh={0.5} duoOpacityLow={0.15} />
<AlertInfoGlyphDuo18 duoOpacityHigh={0.25} />
```

### Vue (`target: "vue"`)

```vue
<ArrowBoldDownOutlineDuo18 :duo-opacity="0.5" :stroke-width="1.5" />
<AccessibilityGlyphDuo18 :duo-opacity-high="0.5" :duo-opacity-low="0.15" />
<AlertInfoGlyphDuo18 :duo-opacity-high="0.25" />
```

### Vanilla (`target: "vanilla"`)

Defaults are in the `var()` fallback (not inline on `<svg>`):

| Fill | Attribute pattern | Fallback |
|------|-------------------|----------|
| `outline-duo` | `opacity="var(--nucleo-outline-duo-opacity, 0.3)"` | `0.3` |
| `glyph-duo` 0.4 | `opacity="var(--nucleo-glyph-duo-opacity-high, 0.4)"` | `0.4` |
| `glyph-duo` 0.2 | `opacity="var(--nucleo-glyph-duo-opacity-low, 0.2)"` | `0.2` |

```css
svg.outline-duo {
  --nucleo-outline-duo-opacity: 0.2;
}

svg.glyph-duo {
  --nucleo-glyph-duo-opacity-high: 0.5;
  --nucleo-glyph-duo-opacity-low: 0.15;
}
```

Do **not** offer duo opacity for core, sharp, pixel, or non-duo ui fills.

## Corners (core outline and arcade)

Applies to:

- **core** + fill `outline`
- free **`arcade`** (typically fill `colored`)

Do **not** refuse corners on arcade because it is not an outline family.

User language aliases:

| User says | Value |
|-----------|--------|
| round, rounded, soft corners | `round` |
| square, squared, sharp corners, sharper | `square` (default) |

### Rules

| Mode | `stroke-linejoin` | `stroke-linecap` |
|------|-------------------|------------------|
| **round** | `round` | `round` (including `data-cap="butt"` elements) |
| **square** | `miter` | `square`, or **`butt`** if the element has `data-cap="butt"` |

### React (`target: "react"`)

Prepared components expose `corners` (default **`"square"`**):

```tsx
<PrinterOutline32 />
<PrinterOutline32 corners="square" />
<PrinterOutline32 corners="round" strokeWidth={2} />
<DragUpColored30 corners="round" strokeWidth={3} />
```

Do not invent other prop names (`corner`, `linecap`, etc.).

### Vue (`target: "vue"`)

```vue
<PrinterOutline32 />
<PrinterOutline32 corners="round" :stroke-width="2" />
<DragUpColored30 corners="round" :stroke-width="3" />
```

### Vanilla (`target: "vanilla"`)

Prepared **core outline** and **arcade** SVGs use CSS variables with **square** fallbacks (only on elements that already had linecap/linejoin, plus stroked `data-cap="butt"` elements on core):

| Attribute | Pattern | Fallback |
|-----------|---------|----------|
| `stroke-linejoin` | `var(--nucleo-stroke-linejoin, miter)` | `miter` |
| `stroke-linecap` (normal) | `var(--nucleo-stroke-linecap, square)` | `square` |
| `stroke-linecap` + `data-cap="butt"` | `var(--nucleo-stroke-linecap-butt, butt)` | `butt` |

**Square / sharp** (default look — no CSS needed):

```css
/* already the fallbacks; optional explicit: */
svg {
  --nucleo-stroke-linejoin: miter;
  --nucleo-stroke-linecap: square;
  --nucleo-stroke-linecap-butt: butt;
}
```

**Round / soft:**

```css
svg {
  --nucleo-stroke-linejoin: round;
  --nucleo-stroke-linecap: round;
  --nucleo-stroke-linecap-butt: round;
}
```

Do **not** add linecap/linejoin to elements that never had them. Do **not** hand-edit those attributes when CSS vars are enough.

Both React and vanilla default to **square/miter**. Use `corners="round"` (React) or the three CSS vars set to `round` (vanilla) when the user wants soft corners.
### Not supported

Corners are **not** customizable for ui, sharp, pixel, micro, or any glyph/duo fill. Arcade **is** customizable. If asked on an unsupported family, explain and offer color / stroke width (when allowed) instead.

## Decision cheat sheet

| User intent | Allowed? | React | Vanilla |
|-------------|----------|-------|---------|
| Primary color | Always | `color` / `className` | CSS `color` |
| Secondary / accent color | If icon has `data-color="color-2"` | Data selector / CSS | CSS `[data-color="color-2"]` |
| Stroke width on **core `outline`** | Yes | `strokeWidth={…}` | `--nucleo-stroke-width` |
| Stroke width on **ui `outline` / `outline-duo`** | Yes | `strokeWidth={…}` | `--nucleo-stroke-width` |
| Stroke width on **arcade** (any fill, default 4) | Yes | `strokeWidth={…}` | `--nucleo-stroke-width` |
| Stroke width on **sharp / pixel / micro** (any fill) | **No** | Explain + offer color/size | Same |
| Stroke width on **glyph / glyph-duo** | **No** | Explain | Explain |
| Soft opacity on **ui outline-duo** | Yes | `duoOpacity={…}` | `--nucleo-outline-duo-opacity` |
| Soft opacity on **ui glyph-duo** (one value, layer not named) | Yes | `duoOpacityHigh` only; mention some icons also have a 0.2 layer | `--nucleo-glyph-duo-opacity-high`; mention `--nucleo-glyph-duo-opacity-low` |
| Soft opacity on **ui glyph-duo** (higher/lower named, or two values) | Yes | `duoOpacityHigh` / `duoOpacityLow` as asked (only layers on that file) | matching CSS vars |
| Soft opacity on other families/fills | **No** | Explain | Explain |
| Corners on **core outline** | Yes | `corners="round\|square"` | `--nucleo-stroke-linejoin` / `--nucleo-stroke-linecap` / `--nucleo-stroke-linecap-butt` |
| Corners on **arcade** | Yes | `corners="round\|square"` | `--nucleo-stroke-linecap` / `--nucleo-stroke-linejoin` |
| Corners on ui, sharp, pixel, micro, glyph/duo, or other free families | **No** | Explain | Explain |
| Color on free `social-media` | Yes | `className` / `style.color` | CSS `color` |
| Color on free `flags` / `cursors` / `credit-cards` | **No** | Explain | Explain |
| Isometric colors (`--nc-isometric-color-1|2`) | Yes (`isometric` only) | `style={{ ['--nc-isometric-color-1']: '…' }}` | CSS vars on `svg` |
| Arcade colors (`--nc-arcade-color-1|2|3`) | Yes (`arcade` only) | `style={{ ['--nc-arcade-color-1']: '…' }}` | CSS vars on `svg` |
| Glass colors (`--nc-gradient-*` / `--nc-light`) | Yes (`glass` only) | `style={{ ['--nc-gradient-1-color-1']: '…' }}` | CSS vars on `svg` |
| Glass id collisions (gradients/masks) | Yes (`glass` only) | Auto via `useId`; optional `uniqueId` | Prefix every `id` / `url(#…)` on insert |
| Stroke / duo / corners on other free families | **No** | Explain | Explain |

## With nucleo-icons

1. Find the icon (`nucleo-icons` skill + MCP)  
2. For React/Vue: **copy** the component into the project, then import from that local path. Never import from `~/.nucleo/skills` / `componentPath` / absolute install paths. For vanilla: paste the SVG into the project.  
3. Apply this skill’s customizations for the active `target`  
4. Keep user-facing lists free of icon ids and match explanations  

## Examples

**Vue — thinner core/ui outline**

```vue
<SettingsOutline24 :stroke-width="1" class="text-slate-900" />
```

**React — thinner core/ui outline**

```tsx
<SettingsOutline24 strokeWidth={1} className="text-slate-900" />
```

**React — primary + secondary color (Tailwind)**

```tsx
<BellOutline24 className="text-slate-900 **:data-[color=color-2]:text-red-500" />
```

**Vanilla — primary + secondary (CSS)**

```html
<svg class="icon" aria-hidden="true">…</svg>
```

```css
.icon { color: #0f172a; }
.icon [data-color="color-2"] {
  color: #ef4444;
}
```

**Sharp / pixel + “make the stroke thicker”**

Stroke width is only for **core outline**, **ui outline / outline-duo**, and **arcade**. For `sharp`, `pixel`, or other families, explain it isn’t customizable. Offer changing color or picking a different size instead.

**Arcade — thicker stroke + round corners**

```tsx
<DragUpColored30 strokeWidth={3} corners="round" />
```

**Core outline — round / soft corners**

```tsx
<DragDown2fOutline24 corners="round" />
```

Vanilla:

```css
.icon-round {
  --nucleo-stroke-linejoin: round;
  --nucleo-stroke-linecap: round;
  --nucleo-stroke-linecap-butt: round;
}
```
