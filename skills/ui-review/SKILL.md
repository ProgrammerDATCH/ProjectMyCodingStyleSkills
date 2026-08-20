---
name: ui-review
description: >-
  Akokuntaro Coding Skills — David's UI finishing pass. Apply on ANY frontend/UI
  task (Next.js, Vite/React, Streamlit — any stack) BEFORE calling the work done:
  the phone-compact rules (same design as PC with secondary elements shrunk to
  captions or removed, banners halved, prose hidden on phones, trailing icons
  right-aligned, only tables scroll), and the finishing checklist that catches
  what he otherwise sends back — oversized mobile elements, duplicated controls,
  unreachable features. Pair it with coding-principles and the stack skill.
---

# UI review — the finishing pass (David's defaults)

Every one of these rules exists because a "done" UI task came back. Run this pass on any
frontend work before reporting it finished — it is a review lens, not a build guide, so it
applies whatever the stack.

## Phones: same design, radically more compact

Mobile is never a different layout — it is the PC design with everything secondary shrunk
much further than feels natural. The right instinct is "shrink to a caption or remove",
not "shrink 20%".

- **Secondary elements become captions.** A card that supports a primary action (a class
  card above a button, a meta strip under a title) drops to ~8–9px lines, loses any datum
  that is duplicated nearby, and reads clearly subordinate to the action it decorates.
- **Descriptive prose disappears on phones.** Explanatory sentences under page titles are
  desktop furniture: `hidden sm:block` them ALL — every paragraph of the kind, not just the
  one the ticket quoted. A phone opens straight onto the controls.
- **Banners halve.** A hero that stacks identity + meta cards + actions becomes one identity
  row plus one wrapping chips row. Target roughly half its desktop height; when the greeting
  and buttons fight for a row, the greeting takes its own full row (`order-first w-full`).
- **Trailing icon actions hug the right edge.** When a wrapped row leaves an icon button
  (envelope, bell) dangling on the left, give it `ml-auto` so every wrap keeps it right.
- **Only the wide thing scrolls.** A table gets its own `overflow-x-auto` wrapper with a
  `min-width` so its columns stay readable; the card/sheet around it stays page-wide. If a
  header or signature line scrolls away with the table, the wrapper is on the wrong element.
  The page body itself never scrolls horizontally.
- **Component-owned sizing beats ad-hoc pixels.** Anything rendered inside a sized system
  (an isometric platter, a chart card, a grid cell) must join that system's own container-query
  units and slots — a hand-picked `max-w-[250px]` wrapper is wrong at both ends of the range.

## One control per job

If two controls answer the same question, keep the compact one and delete the other — a
drill/search bar makes an eight-select filter panel redundant; a summary tile row that
filters makes a chip row redundant. Rebuilding or porting a page is the moment to prune,
not to faithfully carry the duplication forward.

## Paired visuals are optically equal

Two logos, two markers, two columns that read as a pair must match in INK, not in box:
an asset that carries internal padding or caption text draws smaller at equal box size.
Measure the visible mark and size for that (or use per-asset ink metrics when available).

## The pass itself

Before reporting UI work done, drive it at BOTH widths — a real desktop viewport and a
~390px phone view — and hunt specifically for:

1. Any secondary element larger than its primary action on the phone.
2. Any descriptive prose still visible on the phone.
3. A wrapped row with a stray icon on the wrong side.
4. Horizontal overflow: `scrollWidth > clientWidth` on the document = a bug; on a table
   wrapper = correct.
5. Two controls doing one job.
6. The feature reachable through NAVIGATION as the target role — sidebar/menu entry present
   and landing on the page (a working deep link is not enough).
7. Numbers on screen that must re-add to a total nearby actually re-adding.

Report which widths and roles were driven, and what was deliberately left out.
