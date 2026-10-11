# Peace Garden logo: round two — 11 October 2026

Design exploration only. **No live asset has changed**: the app icon set, `tools/icon/`,
`Server/assets/`, the launch moment and `suite-brand.md` are as they were. Everything is in
this folder, on branch `claude/logo-2026-10-11`.

This round refines **D (Meeting)** and **E (Leaf and curl)**. It measures them against the
**Interfulgent app suite** (Pfish, UnCubed, Animal Rescue Centre, FlagFans and FreqShift),
not against the Institute's marks, which was round one's mistake. Each direction is drawn at
the suite's median line weight and again a step lighter.

**Start with [`suite-row.png`](suite-row.png)**: all four candidates in a row with the five
suite apps' real icons and today's Peace Garden icon, at 180 and 60 px, on the home screen's
dark and light grounds. Then see [`hue-map.png`](hue-map.png).

## 1. The suite's line weight and construction, measured

The five icons were copied into [`suite-icons/`](suite-icons/) from each repository's own
app icon set: `pfish-ios` `4a4151e`, `uncubed` `c973d2f33` (its icon is byte-identical to
`main`'s), `animal-rescue-centre` `a4b3b1d`, `flagfans` `ad26403` and `freqshift` `3115682`.
[`measure.py`](measure.py) measures them. Stroke width comes from a distance transform: twice
the ridge distance of each ink pixel to the ground, as a median. The gradient ink and the
white or cream accent are measured separately. Results are in
[`measurements.json`](measurements.json).

| App | Stroke ÷ tile, measured | From source | Ink box ÷ tile (w × h) | Ink ÷ tile area | Ground | Gradient | Light accent: weight ÷ tile · share of ink | Small sizes |
|---|---|---|---|---|---|---|---|---|
| **Pfish** | **0.052** | 7 × 0.62 ÷ 82 = 0.053 (`Tools/make-appicon.py`) | 0.77 × 0.58 | 0.11 | `#0D0D1F` flat | 150° → 188°, `#11CD6F → #12C4DF`, isoluminant ~9.1:1, even sweep | two bubbles, 0.027 · 17 % | The icon *is* the small form. The untapered stroke is §3.2a's small variant; the 1.49 taper is for large surfaces only. Bubbles are sized so the ring stays open at 60 px |
| **UnCubed** | **0.065** | 42.46 before the fit (`icon-generator.py`) | 0.82 × 0.42 | 0.11 | `#0D0D1F` flat | 224° → 300°, one colour per glyph, stops in the gaps | the `³`, fading pink → `#F4F3EF`, 0.052 (0.82 of the letters) · 18 % | One drawing down to 40 px. **No 16 px drawing**: `favicon.ico` carries 32 and 48 only, an open item in `brand.md` §8 |
| **Animal Rescue Centre** | **0.079** | 8 ÷ 100 (`arc-suite-icon.svg`) | 0.61 × 0.58 | 0.14 | `#0D0D1F` flat | 350° → 28°, `#C90021 → #FCC190`, **not** isoluminant (3.2 → 12:1), even sweep | four toe rings in `#FEF9EF`, 0.031 (0.31–0.41 of the heart) · 24 % | No separate small suite drawing found |
| **FlagFans** | **0.062** | 8 × 0.78 ÷ 100 = 0.062 (`ff-suite-icon.svg`) | 0.51 × 0.55 | 0.09 | `#0D0D1F` flat | 28° → 45°, `#B98A62 → #F0C24E`, desaturated (0.59), not isoluminant | the crossbar in cream `#F4EBDD`, 0.042 (0.69 of the stems) · 19 % | No separate small drawing found |
| **FreqShift** | **0.073** ⚠️ | — no source in the repo | 0.43 × 0.71 | 0.09 | ⚠️ `#1B1251` with a visible gradient tile | ~197° → 264°, cyan → violet, even sweep along one stroke | none | Nothing found |
| *Peace Garden today* | *0.040* | 41.47 ÷ 1024 (`make_icon.py`) | 0.43 × 0.63 | 0.09 | `#0D0D1F` | 140° → 60°, `#06F556 → #DCDC06`, isoluminant 13:1, sat 0.95 | bract `#FFFFFF` (filled taper) · 25 % | One drawing |

Where the source gives the stroke, the measurement agrees to within 0.001 of the tile.

⚠️ **FreqShift is the weakest row.** Its repository holds no app icon set and no vector.
The only artefact is `public/freqshift_logo.png`, a 162 px web logo drawn as its own rounded
tile on a gradient purple (`#1B1251`), not on `#0D0D1F`. `suite-brand.md` §2 says its icon
was sampled from the installed app's binary and was `#0D0D1F`, so the web logo may simply
be older than the icon. Its numbers are measured relative to that tile and should be
re-checked against the shipped icon.

### What the suite shares

- **One ground**, `#0D0D1F`, flat (four of four checkable icons).
- **Marks made of strokes with round free ends**, with no fills, shadows or drawn squircle.
- **Strokes between 0.052 and 0.079 of the tile, median 0.065.** Today's Peace Garden icon,
  at 0.040, is the lightest thing in the suite by a long way, and round one's 20 px
  (0.020) would have been lighter still.
- **The mark fills 0.55–0.82 of the tile on its long side (median 0.71)**, and ink covers
  0.09–0.14 of the tile's area (median 0.11).
- **One gradient running bottom-left to top-right.** An even sweep where the coloured
  element is one stroke; per-element stops only for UnCubed's separate glyphs.
- **One light accent on a secondary element**, white or the app's cream, at 0.4–0.82 of
  the main weight and 17–24 % of the ink. FreqShift has none.

### What each app owns

The glyph and its hue band. Whether the stops are isoluminant (Pfish, UnCubed and Peace
Garden are; Animal Rescue Centre and FlagFans are not). Saturation: most run at 0.84–0.94,
FlagFans at a deliberate 0.59. The accent's weight ratio. Pfish alone has stroke modulation.

## 2. What `suite-brand.md` requires, and how each candidate meets it

**Which copy.** `main`'s `suite-brand.md` (last changed at `fbfcb1de`) **does not mention
Peace Garden**, nor Pfish, Animal Rescue Centre or FlagFans. The Peace Garden entry Marcus
refers to is on **`integration`**, last changed at `47ceab47` on 8 October. These rules come
from that copy, read in full.

| Section | Requirement | D-suite · D-light · E-suite · E-light |
|---|---|---|
| §1 | The Institute's brand stays out of the apps; **the suite has no house mark** | ✅ No Interfulgent element. Nothing here is compared with the Institute's marks |
| §3.1 | Ground `#0D0D1F`, flat | ✅ |
| §3.2 | Strokes, never arbitrary fills; **round free ends**; no shadow, bevel or drawn squircle | ✅ Every element is a stroke, the leaf included (round one's filled bract is gone); every end round; iOS supplies the mask |
| §3.3 | One continuous gradient, bottom-left to top-right; an even sweep for one continuous stroke | ✅ One even sweep across the stems' box. The stems are one branching figure, so §3.3's per-element rule does not apply |
| §3.4 | Peace Garden's segment, **140° → 60°**, isoluminant | ✅ **123° → 76°**, inside the band; isoluminant at 9.7:1. The saturation drops, which §3.4 does not govern. **This is what the amendment in §6 records** |
| §3.5 | A mark may not depict what the app is *about*; it may depict what it *gives* | ⚠️ Unchanged from today. Peace Garden's row is ⚠️ and rests on the reading that the plant is what the app hands you. A plant drawing rests on that reading more than today's spiral did |
| §3.6 | White or cream on a **secondary element only**; never the main element | ✅ The leaf is `#F4F3EF`, at 0.72 of the stem's weight, and **23 % (D) or 25.5 % (E) of the ink**. That is level with today's 25 % and Animal Rescue Centre's 24 %. E is at the top of the range |
| §5 | Accessibility, no ads, checkable privacy, never gate the moment of need | Not affected by a logo |

**Where `suite-brand.md` leaves gaps.** Each is noted here rather than filled with a rule.

1. **Line weight.** No section gives a stroke weight or a range. The 0.065 median here is
   measured, not required.
2. **Fill.** No section says how much of the tile a mark should take.
3. **Light-ground versions.** No section covers them. These darken the stops to 4.6:1 on
   `#F6F6F6` and turn the leaf to ink `#121212`, as round one did and as the Interfulgent
   hub files do.
4. **Small sizes.** Only §3.2a, for modulated marks, asks for a small variant. These
   candidates have a small drawing anyway, as round one had.
5. **The accent's weight and share.** §3.6 says "small" and "secondary" and gives no number.
6. **Animal Rescue Centre is in none of §1, §2, §3.4 or §3.5.** Its 355° → 25° span is
   recorded only in its own SVG comment.
7. **§3.4's stated usable arc (150°–340°) still disagrees** with Peace Garden's and
   FlagFans' rows, as the document already says. The new ramp does not make that worse.
8. **FreqShift's ground** in its own repository (§1 above).

## 3. The candidates

Each folder holds `icon-1024.svg`; the website mark `<c>.svg` and `<c>-light-ground.svg`;
`<c>-small.svg` and `<c>-small-light-ground.svg` (the drawing for 16 and 32 px: strokes
1.35 × heavier, fatter leaf, less coil); `<c>-favicon.svg` (the small drawing on the rounded
ground tile); `<c>-one-colour.svg` (`currentColor`); `<c>-lockup.svg` and
`<c>-lockup-light-ground.svg` (the bare mark beside the site's wordmark as set today, with
no tile); `sheet.png` and `in-context.png`.

| Candidate | Stroke ÷ tile | Ink box | Ink area | Leaf share |
|---|---|---|---|---|
| [**D-suite**](d-suite/) | 0.065, the suite's median (UnCubed's) | 0.56 × 0.69 | 0.107 | 23 % |
| [**D-light**](d-light/) | 0.052, a step lighter (Pfish's, the suite's lightest) | 0.56 × 0.69 | 0.088 | 23 % |
| [**E-suite**](e-suite/) | 0.065 | 0.34 × 0.69 | 0.072 | 25.5 % |
| [**E-light**](e-light/) | 0.052 | 0.33 × 0.70 | 0.059 | 25.3 % |

All four were measured by the same code as the suite (`measure.py`), from their rendered
icons. "A step lighter" means Pfish's weight, so the bridge towards the app's fine drawing
never leaves the suite's own range. At 60 px the difference between the two weights is
visible but small: 3.9 px against 3.1 px.

### The colour

| | Hue | Sat | Hex | On `#0D0D1F` |
|---|---|---|---|---|
| Sage (bottom-left) | 123° | 0.24 | `#9CC29E` | 9.71:1 |
| Moss | 97° | 0.34 | `#9DC386` | 9.67:1 |
| Green-gold (top-right) | 76° | 0.44 | `#A9C263` | 9.67:1 |
| Leaf, warm white | — | — | `#F4F3EF` | 17.3:1 |
| *Light ground (`#F6F6F6`)* | 123° · 97° · 76° | 0.38–0.60 | `#397E3D` · `#467D25` · `#60781E` | 4.6:1 each; leaf in `#121212`, 17.3:1 |

- **Against FlagFans.** Round one's straw end `#BBBB6E` (60°) was **ΔE2000 14.2** from
  FlagFans' `#F0C24E`, close enough to read as a neighbour at icon size. So the ramp now ends
  in a paler **green-gold at 76°**, which is **ΔE 19.5** from FlagFans' nearest stop.
- **Against Pfish.** The sage end sits at 123°, 27° below Pfish's 150° start, and at low
  saturation. It is **ΔE 14.2** from Pfish's nearest stop, where round one's 140° sage was
  10.1.
- **No neon.** Mean saturation is 0.33, against 0.95 today. That makes Peace Garden the
  calmest icon in the suite: FlagFans is 0.59, everything else 0.84–0.94. That was the
  brief, but it shows in `suite-row.png`, and it is question 4 below.

## 4. What changed in D and E

**Both.**
- The stroke is **3.3 times heavier**: 0.065 of the tile, against round one's 0.020.
- The leaf is now a **stroked outline at 0.72 of the stem's weight**, which sits between
  FlagFans' 0.69 and UnCubed's 0.82.
- The curls are **log spirals whose eye never closes**: the inner radius is held at about
  1.3 strokes. At the new weight round one's tight coils filled in to dots.
- The ink is **0.69 of the tile high**, against round one's 0.66 and the suite's median 0.71.
- There is still **no ground line**. Each plant grows from a free round end, and every line
  is integrated from a heading, so none is straight.

**D, Meeting.** Round one hung the leaf from a hooked stem, with its head pointing down,
and let the crozier fall off the stem's side.
- Now the tall frond carries its leaf **up and outward** (up-left).
- The second frond branches low on the stem and **rises before it coils**. No part of the
  crozier drops below the fork it grew from, and its open coil rolls outward, away from the
  leaf.
- It is still two lives from one root, and the second frond still offsets the first, which
  is what Marcus liked.

**E, Leaf and curl.**
- **The upright leaf is kept**, leaning the way the gradient runs.
- Round one's tendril rose and then **rolled down below its own start**. It now leaves to
  the left and **sweeps up**, an arm raised with its tip pointing up and away.
- It turns less than a third of a turn, so at the suite's weight it never closes back on
  the stem. A full coil there read as the letter "d".
- The leaf is a little smaller than D's, so the white stays a secondary element.

## 5. Recommendation: D-suite

- **D at the suite's weight sits in the row as a peer.** Its ink box and its 0.107 ink area
  are on the suite's median of 0.11. E is a slender figure (0.34 wide, 0.072 area) and looks
  slighter than its neighbours in `suite-row.png`, even at the same stroke.
- **D says what the app is**: two from one root, both lifting. That was Marcus's reason for
  liking it.
- **It holds at small sizes.** The fork and the coil read at 32 px and still at 16 px
  ([`d-suite/sheet.png`](d-suite/sheet.png)).
- **Its leaf share (23 %) has room**, where E's 25.5 % is at the top of the suite.
- **The suite weight rather than the light one**, because matching the other logos' lines
  was the brief. D-light is the fallback if the heavier line feels too far from the app's
  hairlines in [`d-suite/in-context.png`](d-suite/in-context.png).

E-suite is the runner-up. It is the most aspirational and the simplest, but the slightest
on the home screen.

## 6. What applying the chosen candidate would change

| Where | Change |
|---|---|
| `tools/icon/make_icon.py` | Replace the spiral geometry with the chosen drawing (port `meeting()` or `leaf_and_curl()`, plus `grow`, `curl` and round one's `spathe`). `HUE_FROM`/`HUE_TO` 140/60 → per-stop hues **123.2 / 97.4 / 75.8** with saturations **0.24 / 0.34 / 0.44**. `SATURATION` 0.95 → per stop. `TARGET_CONTRAST` 13 → **9.7**. `STROKE` 48 (41.47 rendered) → **67** rendered at 1024 (0.0654), or 54 for -light. `BRACT` `#FFFFFF` filled → **`#F4F3EF` stroked at 0.72 of the stem**. Drop the taper and spadix dials. It rewrites `tools/icon/icon.svg` |
| `App/PeaceGarden/Resources/Assets.xcassets/AppIcon.appiconset/icon.png` | Regenerated by `make_icon.py` (one 1024 image) |
| `Server/assets/icon.svg`, `Server/assets/icon-180.png` | The new icon and its 180 touch icon |
| `Server/favicon.ico` | From `<c>-favicon.svg`, at 16, 32 and 48 |
| Site masthead (`.mark`/`.wordmark` in `Server/assets/site.css`, `<img class="mark">` in the pages under `Server/.pages/`) | **The bare mark beside the wordmark**, no dark tile: `<c>.svg` on dark and `<c>-light-ground.svg` on light, switched by `prefers-color-scheme`. The wordmark text and font do not change |
| `docs/BRAND.md` | The mark, construction and colour sections |
| Launch moment and waiting mark: `App/PeaceGarden/Views/Loading/Fiddlehead.swift`, `Fiddlehead.Palette` | **`onDark.stem`** `0x06F556, 0x55F306, 0xDCDC06` → **`0x9CC29E, 0x9DC386, 0xA9C263`**. **`onDark.leaf`** `RGB(1, 1, 1)` → **`RGB(hex: 0xF4F3EF)`**. **`onLight.stem`** `0x03842E, 0x2E8203, 0x757503` → **`0x397E3D, 0x467D25, 0x60781E`** (4.6:1 on its `lightGround` 0.965, which is `#F6F6F6`, the ground these were solved on). **`onLight.leaf`** stays `lightInk`. `halo` 0.07 may want lowering, since a glow of a pale sage reads differently from neon; that is for whoever lifts the leaf. Not done here, as the brief says |
| `uncubed/docs/design/suite-brand.md` (on `integration`) | The amendment below. **Not made**: proposed here only |

### The proposed amendment to `suite-brand.md`

**§3.4, the table row**, replacing `| **Peace Garden** | **140° → 60°** | forest green → lime → yellow |`:

> | **Peace Garden** | **123° → 76°** | sage → moss → green-gold (calm, saturation 0.24–0.44) |

**§3.4, a new block after "Peace Garden's segment is Recorded, 2026-08-31"**, which stays
as written:

> **Peace Garden's segment is amended, 2026-10-__, and it narrows within its own band rather
> than moving.**
>
> **123° → 76°**, sage through moss to green-gold, replacing the neon forest green, lime and
> yellow of 2026-08-31. The band is the same part of the spectrum, the green below Pfish and
> above FlagFans, but it is now calm rather than neon. The owner's decision.
>
> - **Saturation 0.24 → 0.34 → 0.44**, against 0.95 before, so Peace Garden is now the
>   least saturated mark in the suite. Its leaf is the suite's warm white `#F4F3EF`, stroked,
>   no longer a filled `#FFFFFF` bract.
> - **All three stops are isoluminant at 9.7:1** on the ground, down from 13:1. The 13:1
>   target was set to keep yellow at full chroma, which a calm ramp no longer wants.
> - **Both ends were moved to clear a neighbour, and measured.** The top stops at 76° rather
>   than 60°: a 60° straw at this saturation was ΔE2000 14.2 from FlagFans' `#F0C24E`, and
>   76° is 19.5. The bottom starts at 123° rather than 140°, which puts it ΔE 14.2 from
>   Pfish's nearest stop (10.1 before) and widens the clearance under Pfish from 10° to 27°.
> - **The stroke is 0.065 of the tile**, the suite's median when measured on 2026-10-11
>   (Pfish 0.052, FlagFans 0.062, UnCubed 0.065, FreqShift ~0.073, Animal Rescue Centre
>   0.079), against 0.040 before.

**§2, Peace Garden's row**: "✅ its own generator, 2026-08-31 · Exact by construction. First
mark to take a hue span below 150°" gains **"Amended 2026-10-__: calm ramp 123° → 76°, see
§3.4"**.

**§3.6, the white-accents table**, gains a row:

> | Peace Garden | the leaf, in `#F4F3EF`, stroked at 0.72 of the stem | about a quarter of the ink, top-left (D) or top-right (E) |

## 7. Decisions for Marcus

1. **Which candidate?** D-suite (recommended) · D-light · E-suite · E-light · none.
2. **The ramp: sage `#9CC29E` → moss `#9DC386` → green-gold `#A9C263` at 9.7:1?** Yes (recommended) · move the gold end further from FlagFans · keep round one's straw.
3. **The leaf as a stroked outline in `#F4F3EF`, at 0.72 of the stem's weight?** Yes (recommended) · same weight as the stem · filled, as today.
4. **Peace Garden becomes the least saturated icon in the suite (0.33 against 0.59–0.94). Is that right?** Yes, calm is the point (recommended) · a touch more chroma, about 0.45 throughout.
5. **The amendment in §6: shall I make it on `uncubed` `integration` once you have chosen?** Yes (recommended) · I'll do it.
6. **`main`'s `suite-brand.md` has no Peace Garden entry, which is only on `integration`. Bring `main` up to date when the amendment lands?** Yes (recommended) · leave it.
7. **FreqShift's repository holds only a 162 px web logo on a purple tile. Should its real icon be added to the repo so the suite can be measured from source?** Yes (recommended) · not needed.

## Files and scripts

- [`measure.py`](measure.py) writes `measurements.json`, from `suite-icons/` and from the
  four candidates' rendered icons.
- [`make_logos.py`](make_logos.py) writes every candidate's SVGs. Change its dials; do not
  hand-edit the SVGs. It reuses round one's spline writer and `spathe`.
- [`make_sheets.py`](make_sheets.py) writes `suite-row.png`, `hue-map.png` and each
  candidate's `sheet.png` and `in-context.png`, using round one's renderer.
- [`colour.py`](colour.py) holds the shared contrast, HSL solving and CIEDE2000 code.

Run them in that order: `make_logos.py`, then `measure.py`, then `make_sheets.py`. They
render with **cairosvg** 2.9 and Pillow (`pip install cairosvg pillow numpy scipy`). The
wordmark falls back to Inter here, since SF is not installed; on Apple devices the SVGs ask
for the system font first. **Every PNG is under 450 KB.**
