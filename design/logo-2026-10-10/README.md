# Peace Garden logo directions — 10 October 2026

Design exploration only. **No live asset has changed**: the app icon set, `tools/icon/`,
`Server/assets/` and the launch moment are as they were. Everything is in this folder, on
branch `claude/logo-2026-10-10`.

Marcus's brief: a mark that is more sophisticated and elegant than the intense spiral and
the bright neon green, that works more like the fiddlehead just drawn for the loading
animation, and that finally agrees with how the app itself looks.

**Start with [`overview.png`](overview.png)**: the current icon and all five directions
side by side, at icon size, small and in the lockup.

## The suite's rules, as found

| Rule | Where |
| --- | --- |
| One dark ground, **`#0D0D1F`**, flat: no gradient, texture or shadow | `interfulgent-hub/docs/2026-10-09-site-and-hub-design.md` §3.7; `tools/icon/make_icon.py` (quoting `suite-brand.md` §3.1) |
| Marks are **single lines of even weight with round ends**; no filled shapes, no drawn squircle | same §3.7; `make_icon.py` (§3.2) |
| **One gradient, bottom-left to top-right**, along the stroke | §3.7; every file in `interfulgent-hub/design/logo/` (`x1,y1` low-left, `x2,y2` high-right) |
| Each app holds **its own band of one hue arc**; Peace Garden's is **140° → 60°** (forest green, lime, yellow), stops held isoluminant | §3.7; `docs/BRAND.md` § Colour |
| Every mark is light shining through darkness ("learning is light that trickles through darkness") | §3.7 |
| One **warm off-white element** beside the gradient: the Interfulgent dot (`#F4EBDD`), UnCubed's exponent (`#F4F3EF`), Pfish's bubbles and Peace Garden's bract (`#FFFFFF`) | `interfulgent-hub/design/logo/*.svg`; `docs/BRAND.md` |
| **Small sizes get their own drawing**, not a shrink: `-small` files are "the small-size drawing below 24 px", with **heavier strokes** (8 → 12 in a 100 box) and simpler geometry (lens radius 19 → 20, dot 10 → 15) | `interfulgent-hub/design/logo/*-small*.svg` |
| **Light-ground versions darken the gradient's stops** (e.g. `#C98A1A → #FFE15A` becomes `#A86F0C → #C98A1A`) and **turn the white element to ink** (`#121110`) | `interfulgent-a-*-small-light-ground-warm.svg` |
| Favicon: the small drawing on a **rounded tile** (`rx 22` in 100), scaled 0.88 | `interfulgent-hub/design/favicon/favicon.svg` |
| Marks are symbolic, not pictorial: a mark may not depict what the app is *about* (it may depict what it *gives*) | `make_icon.py` and `docs/BRAND.md`, quoting `suite-brand.md` §3.5 |

Two things to know. `suite-brand.md` itself lives in `uncubed-integration`, which this run
could not open, so its rules are taken from where Peace Garden's own files quote it. And
the Interfulgent mark's own files sit on near-black **`#121110`** (decision 34), not on
`#0D0D1F`; the apps keep `#0D0D1F`, so every direction here does too.

## Why today's mark clashes with the app

- **Colour.** The mark is 95 % saturated neon (`#06F556 → #DCDC06`) held at 13:1. The app
  has almost no colour in its chrome at all: white at four opacities on black
  (`Chrome.swift`, `docs/CHROME-AND-SETTINGS.md` § Colour), and its plants are muted sage,
  moss, mauve and blush under soft light (`design/plant-screen-2026-10-02/`,
  `app-sky-…`, `app-light-…`). The icon is the loudest thing the app owns.
- **Weight.** A 41-unit stroke at 1024 is a felt-tip; the app draws in hairlines
  (`Chrome.monoline`, 1.2 pt) and its plants are finely built.
- **Shape.** A tight, many-turn spiral reads as a graphic symbol (a snail, a hypnosis
  wheel). The app's own gesture is a tendril *opening* (`design/Motion.dc.html`; the
  fiddlehead), never a coil packed against itself.
- **The launch moment now disagrees with it too.** The tap shows a fat neon spiral, the
  launch moment then grows a hairline fiddlehead. Two different drawings of one idea in two
  seconds.

## The five directions

All five keep the suite's rules (ground, monoline, round ends, bottom-left to top-right
gradient, the 140° → 60° band) and change three things: **a calmer ramp**, sage
`#83C599` → moss `#96C37F` → straw `#BBBB6E` (the same three hues at 0.36 saturation,
isoluminant at 9.5:1 instead of 13:1); **a fine stroke** (20–22 at 1024, half today's);
and **the leaf in the suite's existing warm white `#F4F3EF`** (17:1), not `#FFFFFF`.
No direction draws soil or a ground line, and every line is a curve.

1. **A — Fiddlehead.** *(Recommended.)* The loading animation's own drawing (`Fiddlehead.figure`,
   ported line for line), stopped just before its composed pose: a hairline stem from a
   free round end, arching over, the white bract hanging in the last of the curl. The icon
   and the launch moment become one drawing. [`a-fiddlehead/`](a-fiddlehead/)
2. **B — From the edge.** The same frond, taller and less open, its stem coming up from
   below the tile's bottom edge, so it grows *into* the icon from the screen's edge. On a
   bare page the stem fades out instead. The most atmospheric; the weakest when small.
   [`b-from-the-edge/`](b-from-the-edge/)
3. **C — Spiral, unwound.** The gentle change. Today's mark kept recognisable: the
   logarithmic coil (1.45 turns instead of 2, opened out) running into the white leaf,
   but at a hairline, in the calm ramp, without the filled taper and spadix.
   [`c-spiral-unwound/`](c-spiral-unwound/)
4. **D — Meeting.** The fiddlehead with a second crozier, still curled, leaving its stem
   and turning the other way: two lives from one root, which is what the app is about.
   The most to say; the busiest at 16 px. [`d-meeting/`](d-meeting/)
5. **E — Leaf and curl.** The leaf held upright and leaning the way the gradient runs,
   with one curled tendril below. The simplest silhouette and the best at favicon size,
   but the most like a generic "eco" sprout. [`e-leaf-and-curl/`](e-leaf-and-curl/)

## Recommendation: A, the fiddlehead

It is the drawing Marcus already likes, so it answers the brief literally; it makes the
tap, the launch moment and the icon one continuous figure; and it is the most restrained
of the five beside the app's renders (see [`a-fiddlehead/in-context.png`](a-fiddlehead/in-context.png)).
If the change should be gentler, C keeps the spiral; if the mark should say more, D is
the one to take further.

Honest costs of A (and of all five):
- **Fine lines fade at the tiniest sizes.** At 60 px it is clear; at 29 px the stroke is
  half a pixel. 29 px is only drawn on old @1x screens. The favicon has its own heavier
  `-small` drawing, as the suite does.
- **It sits quieter than the suite.** Beside the Interfulgent marks (heavy strokes, warm
  saturated gradients) the new mark is visibly lighter and calmer. That is the point of the
  brief, but it is a departure from "a band of the spectrum of light" at full strength.
- **§3.5.** A plant is closer to pictorial than a spiral is. `docs/BRAND.md` already argues
  that the plant is what the app *gives*, not what it is *about*; a fiddlehead rests wholly
  on that reading. C rests on it least.

## What's in each folder

`<d>` is the folder name, e.g. `a-fiddlehead`.

| File | What |
| --- | --- |
| `icon-1024.svg` | App icon, full bleed on `#0D0D1F`; iOS applies the mask. The ink stays inside the central ~560 × 680, well clear of the mask's corners |
| `<d>.svg` / `<d>-light-ground.svg` | Website mark, transparent, for dark and for light grounds (`#F6F6F6`; stops at 4.5:1, leaf in ink `#121212`) |
| `<d>-small.svg` / `<d>-small-light-ground.svg` | The drawing below 24 px: shorter stem, larger leaf, stroke 8–9 in 100 |
| `<d>-favicon.svg` | The small drawing on the rounded `#0D0D1F` tile, as the suite's favicon |
| `<d>-tile.svg` | The website mark on its tile, if the masthead keeps a tile |
| `<d>-one-colour.svg` | One colour, `currentColor` (defaults to `#121212`) |
| `<d>-lockup.svg` / `-lockup-light-ground.svg` | The bare mark beside the site's existing wordmark: the system sans (`--sans` in `Server/assets/site.css`), weight 400, tracked 0.18 em, mixed case |
| `sheet.png` | Icon at 1024, 180, 120, 60 and 29 under the iOS mask; favicon at 32 and 16 (and ×4); small, light, dark and one-colour; lockups on dark and light; today's icon and masthead beside each |
| `in-context.png` | The icon beside three of the app's real renders (plant screen, garden at dusk, garden by day) and beside the Interfulgent marks from `interfulgent-hub/design/logo`, on dark and on light |

Made with `make_logos.py` (the drawings; change its dials, do not hand-edit the SVGs) and
`make_sheets.py` (the PNGs), rendered with **cairosvg** 2.x and Pillow. The wordmark
falls back to **Inter** in these renders, since SF is not installed here; on Apple devices
the SVGs ask for the system font first. Every PNG is under 450 KB.

## If Marcus picks one, what changes where

| Where | Change |
| --- | --- |
| `tools/icon/make_icon.py` | Replace the spiral geometry with the chosen drawing (port from `make_logos.py`, which already ports `Fiddlehead.figure`); `SATURATION` 0.95 → 0.36, `TARGET_CONTRAST` 13 → 9.5, `STROKE` 48 → ~20, bract `#FFFFFF` → `#F4F3EF`; drop the taper and spadix dials. It rewrites `tools/icon/icon.svg` |
| `App/PeaceGarden/Resources/Assets.xcassets/AppIcon.appiconset/icon.png` | Regenerated by `make_icon.py` (single 1024 image) |
| `docs/BRAND.md` | The mark, construction and colour sections; the §3.5 note |
| `Server/assets/icon.svg`, `icon-180.png`, `Server/favicon.ico` | The new icon, its 180 touch icon, and a favicon from `<d>-favicon.svg` (a new `favicon-small.svg` as the suite has) |
| Site masthead (`.mark`/`.wordmark` in `Server/assets/site.css`, `<img class="mark">` in each page under `Server/.pages/`) | Either keep the tile (`<d>-tile.svg`) or show the bare mark (`<d>.svg` / `-light-ground.svg` by `prefers-color-scheme`), which needs the light-and-dark pair the CSS comment says the site does not have today. The wordmark text and font do not change |
| Launch moment and waiting mark (`App/PeaceGarden/Views/Loading/`, branch `worktree-agent-a944b9f3f00872bf1`) | Its `Palette.onDark` stem stops move to the calm ramp and the leaf to `#F4F3EF`; `onLight` to the 4.5:1 ramp here. With A, the moment's last frame **is** the icon; with C, D or E the moment still draws the fiddlehead and ends on a different figure |
| `suite-brand.md` (in `uncubed-integration`) | Peace Garden's lower saturation and finer stroke, and its §3.5 row |

## Decisions for Marcus

1. **Which direction?** A (recommended) · B · C · D · E · none, try again.
2. **The calmer ramp — sage, moss, straw at 9.5:1?** Yes (recommended) · a touch brighter · keep today's neon.
3. **The leaf in warm white `#F4F3EF` rather than pure white?** Yes (recommended) · keep `#FFFFFF`.
4. **On the website, the bare mark beside the wordmark, or keep the dark tile?** Bare mark, with light and dark versions (recommended) · keep the tile.
5. **Should the launch moment take the same calm colours, so tap, moment and icon match?** Yes (recommended) · no, keep it as approved.
6. **The plant-shaped mark and §3.5: record Peace Garden in `suite-brand.md` as "the plant is what the app gives"?** Yes (recommended) · no, then C is the only safe choice.
