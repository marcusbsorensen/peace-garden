# The site's bar: the bare mark, dark and light — 11 October 2026

This is the plumbing for the new logo, not the logo itself. The bar at the top of every
page now carries the drawing **bare beside the wordmark, with no dark tile**: a version for
dark grounds and a version for light ones, both written by `tools/icon/make_icon.py`. The
drawing is still today's spiral and bract, at today's dials and colours. When D-suite's
geometry is settled, porting it into `make_icon.py` changes these files and no page.

## What changed

| Where | Change |
|---|---|
| `tools/icon/make_icon.py` | Writes two new files from the same polylines as the icon. `ramp(light=True)` solves each stop's lightness per hue to `LIGHT_CONTRAST` (4.6:1) on `LIGHT_GROUND` (`#F6F6F6`), round two's `on_light` method. `svg()` takes a ground (or none), a bract ink and a viewBox. New dials: `LIGHT_GROUND`, `LIGHT_INK`, `LIGHT_CONTRAST`, `LIGHT_SATURATION`, `BARE_INSET`, `BARE_SIZE`. Rasters go through `save_raster`, which leaves a file alone when its pixels already match (see below) |
| `Server/assets/mark-dark.svg` | New, generated. The icon's drawing exactly, with no ground, cropped square to its ink with a 4 % inset |
| `Server/assets/mark-light.svg` | New, generated. The same lines; stops `#03822D` · `#2D8003` · `#747403`, each 4.60:1 on `#F6F6F6`; bract in `#121212` (17.3:1) |
| `Server/.pages/*` (18 pages) | The bar's `<img class="mark">` points at the bare mark. The 7 pages that follow the reader (`index`, `s`, `g`, `meanings`, `download`, `privacy`, `t`) use a `<picture>` with a `prefers-color-scheme: light` source. The 11 areas (`body.night`) use `mark-dark.svg` alone |
| `Server/assets/site.css` | The `.mark` comment is rewritten. `border-radius: 22%` is removed, since there is no tile to round and a radius would shave the ink. Size (60 px), gap (12 px) and link behaviour are unchanged |
| `Server/README.md` | "There is one drawing" lists the two new files and why there is now a pair. The tree lists them too |
| `tools/deploy.sh` | `--check` also reads back `/assets/mark-dark.svg` and `/assets/mark-light.svg`. The upload already took them: rsync sends all of `Server/` and excludes only `.DS_Store`, `README.md`, `.well-known/` and `.api/config.php` |

Unchanged, and still used for the tab and the home screen: `assets/icon.svg`,
`assets/icon-180.png` and `favicon.ico`. Re-running the generator leaves them, the app icon
and `tools/icon/icon.svg` byte-identical to `main` (`git status` clean).

## Light and dark: what the site does today

The site **has a light appearance**, with no toggle. `site.css` follows
`prefers-color-scheme`: `#000` ground and white ink on dark, `#F6F6F6` and `#121212` on
light. **The ten areas and the Wild Fields are the exception.** They pin dark with
`body.night` and `<meta name="color-scheme" content="dark">`, because each is lit by its
own sky. So a `<picture>` there would show the light-ground mark on a black page whenever
the reader's system is light. Those pages carry `mark-dark.svg` alone. The `walk-light-*`
shots show it: the system is light and the page stays dark, with the dark mark.

## Screenshots

`before-*` is `main`; `after-*` is this branch. Each is the `header.masthead` at 2× with
12 px around it, served by `tools/site/serve.py` and captured with Playwright (Chromium).

| | Desktop, 1280 | Phone, 375 |
|---|---|---|
| Front, dark | `*-front-dark-1280.png` | `*-front-dark-375.png` |
| Front, light | `*-front-light-1280.png` | `*-front-light-375.png` |
| Long Walk (an area), system dark | `*-walk-dark-1280.png` | `*-walk-dark-375.png` |
| Long Walk, system light (stays night) | `*-walk-light-1280.png` | `*-walk-light-375.png` |
| Right to left | `*-front-ar-rtl-dark-1280.png` (Arabic) | `*-front-ar-rtl-light-375.png` (Arabic), `*-walk-he-rtl-dark-375.png` (Hebrew) |

Measured in the browser, after the change, at 375 px: the mark is 60 × 60, 12 px from the
wordmark and at the same height on `/`, `/s`, `/t` and `/walk`, in English, Arabic and
Hebrew. In right-to-left pages the mark stands at the inline start (the right), the
wordmark after it, with the same 12 px. The mark is a link everywhere except the front page.

## What looked wrong, or may

- **The mark reads larger.** The tiled icon kept its drawing inside the tile's 190-unit
  margin, so the ink was about 63 % of the 60 px box. Bare, it fills the box less a 4 %
  inset, as round two's website marks do. That is `BARE_INSET`, if it wants to be smaller.
- **On light, the taper inside the bract is an olive (`#747403`) inside an ink outline.**
  It is the ramp's top stop at 4.6:1, and it reads darker than the yellow it stands for on
  dark. Expected, and it goes away with the port.
- **Two prototypes still point at `icon.svg`**: `tools/wasm/web/front-a.html` and
  `front-b.html`. They are not served pages, and wasm was out of scope, so they are untouched.
- **The committed rasters don't reproduce byte for byte under Pillow 12.3.** Before any
  change here, running the generator on `main` rewrote `icon.png`, `icon-180.png` and
  `favicon.ico` with identical pixels and different bytes. `save_raster` now compares
  decoded pixels and only writes when they differ, at every `.ico` size. It was tested both
  ways: an identical image is skipped, and a changed one is written.

## For the D-suite port

Replace the geometry (`spiral`, `spathe`, `taper` and their dials) and keep `fitted()`'s
contract: placed polylines on the 1024 grid and a rendered stroke. Then set the colour
dials. Round two's light ramp lifts saturation on light (0.38, 0.54, 0.60 against 0.24,
0.34, 0.44 on dark), so `SATURATION` and `LIGHT_SATURATION` become per-stop tuples, and
`stop_at` already takes a saturation. Set `LIGHT_INK` to the bract colour on light, and the
dark bract to `#F4F3EF`. Round two's bract is stroked, not filled, so `svg()` and `png()`
must draw the new parts in the same order. The bare marks come off the same polylines
through `bare_view()`. No page, stylesheet or deploy rule needs to change. Round two's
small drawing (heavier, for 16 and 32 px) and its favicon on a rounded tile are separate
files, not covered here.
