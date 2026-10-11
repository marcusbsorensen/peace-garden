# The icon port — 11 October 2026

Marcus chose variant A of round two and seven-eighths
(`design/logo-2026-10-11/d-taper/coil2-a/`). This branch, `claude/icon-port-2026-10-11`,
ports it into `tools/icon/make_icon.py` and regenerates every icon file from it. Nothing has
been deployed, and no Swift, `project.yml` or version number has changed. The build is for
the owner's Mac.

## Start here

- **`icon-before-after.png`**: today's icon (`main`) beside the new one under the iOS mask
  at 512, 180, 120, 87, 60 and 40 px, on the home screen's dark and light grounds, with 60
  and 40 px also enlarged 3×.
- **`favicon.png`**: the old and new `favicon.ico` at 16, 32 and 48 px, enlarged 4× with the
  true size beneath, and the 16 px in a tab, on a light and a dark tab strip.
- **`suite-row-final.png`**: the new icon beside Pfish, UnCubed, Animal Rescue Centre,
  FlagFans and FreqShift, at 180 and 60 px.
- **`masthead-*.png`**: the site's bar after the change, `header.masthead` at 2× with 12 px
  around it, served by `tools/site/serve.py` and captured with Playwright (Chromium).

| | Desktop, 1280 | Phone, 375 |
|---|---|---|
| Front, dark | `masthead-front-dark-1280.png` | `masthead-front-dark-375.png` |
| Front, light | `masthead-front-light-1280.png` | `masthead-front-light-375.png` |
| Long Walk, an area | `masthead-walk-dark-1280.png` | `masthead-walk-light-375.png` (system light, stays night) |
| Right to left, Arabic | `masthead-front-ar-rtl-dark-1280.png` | `masthead-front-ar-rtl-light-375.png` |

In every shot the mark is 60 × 60. The light pages take `mark-light.svg`, the dark pages
and the area take `mark-dark.svg`, and in Arabic the mark stands at the inline start, on
the right. No page or stylesheet rule changed: the files they point at did.

`make_renders.py` writes all of them. Run it after `tools/icon/make_icon.py`; it reads
today's files from `origin/main` with git. Every PNG is under 450 KB.

## What the port does

- **`make_icon.py` is the one source of truth** and imports nothing from `design/`. It
  carries round two's `grow`, `curl` and the leaf, `meeting()`'s figure with A's dials (fork
  14 of 120, rise 0.24 + 0.32 s over 52 units, coil 1.35 turns from radius 27 to 10), and
  `make_taper.py`'s filled outline with T2's taper (τ 0.58, the crozier's ease-out 2.5, the
  stem's taper from 22/120). `fitted()`, `bare_view()` and `save_raster` keep their jobs.
- **Colours.** Dark stops `#9CC29E`, `#9DC386`, `#A9C263` (saturation 0.24, 0.34, 0.44,
  9.7:1 on `#0D0D1F`); light stops `#397E3D`, `#467D25`, `#60781E` (4.6:1 on `#F6F6F6`);
  leaf `#F4F3EF` on dark and `#121212` on light, stroked at 0.72 of the root's stroke. All
  solved by the script and checked against these values.
- **Filled outlines in the SVG and the PNG.** The SVG writes each path as curves; the PNG
  flattens the same curves and paints each part with supersampled coverage, one even sweep.
- **The favicon is the small drawing, untapered,** on the rounded ground tile, drawn at 16,
  32 and 48 px separately, as §3.2a(5) asks.
- **The app icon catalogue** has one 1024 entry and no dark or tinted appearance entries,
  before and after. The ground travels with the mark, so the one image covers every
  appearance, as BRAND.md records.

## How closely it matches the design

`tools/icon/check_port.py` rasterises each output and its design file at the same size and
compares 8-bit levels per channel (12 of 12 match):

| Output | Against | Size | Mean R · G · B | Max R · G · B |
|---|---|---|---|---|
| `icon.png` | `icon-1024.svg` | 1024 | 0.05 · 0.06 · 0.04 | 63 · 62 · 56 |
| `tools/icon/icon.svg`, `Server/assets/icon.svg` | `icon-1024.svg` | 1024 | 0.00 · 0.00 · 0.00 | 9 · 11 · 8 |
| `icon-180.png` | `icon-1024.svg` | 180 | 0.17 · 0.19 · 0.14 | 38 · 38 · 34 |
| `mark-dark.svg` | `d-taper-coil2-a.svg` | 512 | 0.04 · 0.05 · 0.03 | 117 · 149 · 99 |
| `mark-light.svg` | `d-taper-coil2-a-light-ground.svg` | 512 | 0.05 · 0.03 · 0.05 | 153 · 99 · 160 |
| `favicon.ico` | `d-taper-coil2-a-favicon.svg` | 16 | 0.56–0.68 | 14 |
| | | 32 | 0.43–0.54 | 18 |
| | | 48 | 0.33–0.42 | 30 |

The favicon rows give the range over the dark and the light ground. The large maxima are
edge pixels: 0.05 % or fewer of the pixels are more than 24 levels out anywhere.

**Two deliberate differences.**

- **The round ends.** The design files close each tapered line with one SVG arc across a
  diameter. Which arc is drawn then hangs on rounding, and a radius written to two places a
  hair longer than half the chord flattens the end. In the 100-unit website marks that is
  about a pixel at 512, at the stem's root and the crozier's tip, and those two places are
  the bare marks' maxima above. The port draws each end as two quarter arcs, so it stays
  round.
- **The favicon's corners.** CairoSVG draws a `<rect rx>` with two corners rounder than the
  other two. The check rasterises the design file's tile as arcs instead, which CairoSVG
  draws evenly, and which matches the port's own tile.

## Still showing or describing the old mark

- **Swift draws no copy of the mark.** The launch screen is a colour (`LaunchGround`) with
  no image, and there is no brand image or About screen. The launch moment's
  `Fiddlehead.Palette` already carries the new colours. Two Swift places echo the old icon in
  words or form and were left alone, as asked: the recycling glyph in `Chrome.swift`
  (`/// A recycling turn`, three fronds "each unwinding into the next", described in
  `docs/CHROME-AND-SETTINGS.md` as "the app's own spiral repeated three times"), and the
  history comments in `Fiddlehead.swift` and `LoadingTests.swift` that say what the old icon
  was.
- **Two wasm prototypes** (`tools/wasm/web/front-a.html`, `front-b.html`) still show
  `/assets/icon.svg` in their bar; they are not served pages, and wasm was out of scope.
  They now show the new tiled icon.

## A decision for Marcus: the tab icon

Every page has `<link rel="icon" href="/assets/icon.svg">`, and current browsers take that
SVG over `/favicon.ico`. So **in a tab the site will show the full, tapered drawing on a
square tile, not the favicon's untapered small drawing.** At 16 px the crozier's tip would be
about 0.6 px. Two ways to make the tab show the favicon: write the small drawing to a new
`assets/favicon.svg` and point the pages' `rel="icon"` at it (18 pages, one line each), or
drop the SVG link and let browsers take `favicon.ico`. Neither is done here, because both
change pages and the brief named the files to write.

Marcus chose the small drawing for tabs, 11 October 2026; written as `assets/favicon.svg`.
