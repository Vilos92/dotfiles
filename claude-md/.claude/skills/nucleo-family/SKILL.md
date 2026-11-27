---
name: nucleo-family
description: >-
  Choose a Nucleo icon family only when the user does not name one. An explicit
  family always wins (pixel stays pixel even if the project uses core). When
  none is named, keep the family already used if its size still leaves room;
  otherwise pick from container size or from the screen style (ui, core,
  pixel, sharp, micro). Use before nucleo-icons search.
---

# Nucleo family

Use this skill **only** when the user asks for a Nucleo icon and does **not** name a family. If they name one, do not apply the rules below.

## User choice first

An explicit family always wins, including over icons already in the project. An explicit size always wins too, even when it fills the container. Do not swap it for a smaller size. The user can ask to resize it.

| User says | Family |
|-----------|--------|
| “a pixel calendar icon” while the project uses core | `pixel` |
| “from ui” / “sharp icon” / “use glass” | that family |

Accept `core`, `ui`, `sharp`, `micro`, `pixel`, and free families (`glass`, `arcade`, `isometric`, `flags`, `cursors`, `social-media`, `credit-cards`), plus obvious names (“pixel”, “the UI set”). The family must be installed (`nucleo_list_families`). If it is not installed, say so. Do not substitute the family already in the project.

When **no** family is named, apply the rules below in order. More criteria will be added.

## Room around the icon

The icon canvas must be **smaller** than the box it sits in, so there is space around it. Do not use a canvas equal to or larger than that box.

Read the container from the place you are inserting (button, chip, input, nav item). Use its smaller side (height, if that is what limits the icon).

| Container | Do not use | Use instead |
|-----------|------------|-------------|
| Button about **22–24px** tall | **24px** (core and other 24px families) | **18px**, usually the **ui** family |

Confirm real sizes with `nucleo_list_families` (`ui` is often `18px` and sometimes `12px`; `core` is often `24px` / `32px` / `48px`). Pick an **installed** family that has a canvas smaller than the container. Prefer **ui** at `18px` for controls around 22–24px. Pass that `family` and `size` to search.

If the project already uses a family whose canvas still leaves room, keep that family (next section). If its canvas does not fit, do **not** keep it. Say you switched because the icon would have no room.

If the user named a **size**, use that size. Do not replace it with a smaller one. They can ask to resize it if it does not fit the box.

If you cannot tell how big the container is, and the user did not name a size, skip this rule.

## Already used in the project

If the project already contains a Nucleo icon, **keep using that family** when its size still leaves room. Do not switch families for a new icon. This does not apply when the user named a family, or when that family's canvas does not fit the container.

Look in this order:

1. Nucleo icons already inserted in this conversation.
2. The file you are editing, then nearby files in the same screen or component.
3. The rest of the project: copied Nucleo components (`.tsx`, `.vue`) or pasted Nucleo SVGs (`currentColor`, `data-color="color-2"`, `--nucleo-` / `--nc-` variables).

Match the component or label to an installed family with `nucleo_search_icons` / `nucleo_get_icon` only to learn which family it came from. Do not insert a new icon during this check.

If you find **one** family, pass it as `family` to `nucleo_search_icons` and say which family you kept.

If you find **more than one**, use the family on the screen or file you are editing. If that file has none, use the family of the most recent Nucleo icon in the project. Do not mix families in one screen.

If you find **none**, use the family already chosen by the room rule. If that rule did not apply either, use the style guidelines below.

## Style of the screen

Use this only when the user did not name a family, no existing Nucleo family fits, and the room rule did not already pick one. Match the product, then say which family you chose. It must be installed.

| Family | How it is drawn | Use it for |
|--------|-----------------|------------|
| `ui` | 18px (sometimes 12px), stroke about 1.5, round ends. Outline, glyph, and duo. | Dashboards, apps, and product UI. Also landing pages when the icon must stay small. |
| `core` | 24 / 32 / 48px, stroke 2, geometric, corners can be square or round. Outline and glyph. | Marketing and landing pages, slides, and larger spots. Not a 22–24px control. |
| `pixel` | 24px outline on a square pixel grid, square ends. | Retro and gaming. |
| `sharp` | 24px outline only, stroke 2, square ends, hard corners. | A strong, strict, or technical look. |
| `micro` | 20px filled icons with a heavy stroke. Nucleo calls this Micro Bold. | Dashboards and products that need a small icon with a bolder look. |

Landing pages can be either `ui` or `core`. Prefer `core` when the icon is a hero or feature mark. Prefer `ui` when it sits in a small control.

Free families are not general UI sets. Use one only when the subject or look matches:

| Family | How it is drawn | Use it for |
|--------|-----------------|------------|
| `arcade` | 30px colored dots, pixel-game look | Games, retro, playful marketing |
| `glass` | 24px glossy gradients | Decorative or glass-style UI |
| `isometric` | 24px colored 3D | Illustrations, not interface controls |
| `social-media` | 32px brand marks | That network’s logo |
| `flags` | 32px flags | A country flag |
| `cursors` | 32px pointer art | A cursor |
| `credit-cards` | 32px card brands | A payment mark |

If two families still fit, prefer the one whose size leaves room in the container. Do not pick `pixel`, `sharp`, or a free family for an ordinary app icon.
