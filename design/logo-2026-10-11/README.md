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

## 8. Round two and a half: D-suite with tapers

*Added 11 October 2026 on branch `claude/logo-taper-2026-10-11`. Still design exploration
only: no live asset has changed. Everything is in [`d-taper/`](d-taper/).*

**Start with [`d-taper/compare.png`](d-taper/compare.png)**: round two's D-suite beside T1,
T2 and T3 at 360, 180 and 60 px on both home-screen grounds, then 60 px enlarged 4×, then
1:1 crops of the 1024 px icon at the coil, where the stem meets the leaf, and at the fork.
Then [`suite-row.png`](d-taper/suite-row.png), [`small-sizes.png`](d-taper/small-sizes.png)
and each strength's `in-context.png` ([T1](d-taper/t1/in-context.png),
[T2](d-taper/t2/in-context.png), [T3](d-taper/t3/in-context.png)).

### What Marcus asked

He chose D-suite as round two drew it: D at the suite's median stroke of 0.0654 of the
tile, the sage → moss → green-gold ramp, and the leaf as a warm white outline. Then, in his
words:

> I would like the curling frond on the right to taper off to a thinner size as it spirals
> inwards, and I'm wondering if we should have a slightly thinner taper towards the
> ascending stem that meets the flower, so that the flower looks a bit more chunky by
> comparison to what's just below it.

"The flower" is the white leaf. So:

- **The coil** keeps the full stroke where it leaves the fork and thins as it winds in, to
  a thinner round end at its eye.
- **The stem** thins a little towards the leaf, so the leaf reads chunkier than the stem
  just below it.
- **Unchanged**: the root at the full 0.0654, so the mark still matches the suite where it
  is heaviest; the ramp; the leaf's outline at 0.72 of the base stroke; round ends; curves
  only; no ground line.

### How the taper is drawn

- **A filled outline, not a stroke.** A stroke-width cannot vary along a path. Each tapered
  line is resampled every 0.2 strokes along its centreline, offset by half the local width
  on both sides, and closed at each end by a circular arc at the local width. The offsets
  lie on the envelope of those circles, so each side meets its round end on a tangent. The
  sides are Catmull–Rom curves through round one's `path_d` and the ends are SVG arcs, so
  nothing is straight.
- **The same colour.** The outlines are filled with round two's one even sweep, its vector
  taken from round two's own `bounds()`. The measured hue band is 86°–110° in round two and
  in all three strengths.
- **The width profile is a smoothstep**, 3u² − 2u³. Its slope is zero at both ends, so the
  thinning starts at the fork without a kink and settles into the tip without a pointed
  wedge. The crozier eases from full weight at the fork to its tip over its whole length,
  which puts most of the thinning in the coil. The stem stays full from the root to the
  fork, then eases to its neck at the leaf.
- **One strength parameter, τ.** The coil's tip is 1 − τ of the base stroke and the stem's
  neck 1 − 0.43τ, so the two tapers move together. That meets §3.2a's third condition, one
  taper parameter applied to a profile in code.
- **The leaf stays a stroke**, at 0.72 of the base, as round two drew it.
- **The fork.** The crozier's fill lies over the stem's and starts inside it, as round two's
  strokes did, and both carry the same gradient in the same coordinates, so the overlap
  cannot show. At 1024 px, below the fork, the tapered icons match round two's pixels
  exactly inside the stem and to within 4 levels at its anti-aliased edges. The fork row of
  `compare.png` shows no seam, notch or overlap.
- **The generator.** [`d-taper/make_taper.py`](d-taper/make_taper.py) imports
  `make_logos.py`, `make_sheets.py` and `measure.py` and copies nothing from them. It hands
  round two's `write_candidate()` a tapered `drawing()` for the length of each call, so the
  geometry, placement, ramp and file set are round two's. Change its dials; do not
  hand-edit the SVGs.

### The three strengths

| | τ | Coil tip ÷ base | Stem neck ÷ base | Leaf ÷ base | Contrast, thickest ÷ thinnest (§3.2a(2)) | Coil tip at 180 · 60 · 40 px |
|---|---|---|---|---|---|---|
| D-suite, round two | 0 | 1 | 1 | 0.72 | 1 | 11.8 · 3.9 · 2.6 |
| **T1, gentle** | 0.45 | 0.55 | 0.81 | 0.72 | 1.82 | 6.5 · 2.2 · 1.4 |
| **T2, medium** | 0.58 | 0.42 | 0.75 | 0.72 | 2.38 | 4.9 · 1.6 · 1.1 |
| **T3, strong** | 0.70 | 0.30 | 0.70 | 0.72 | 3.33 | 3.5 · 1.2 · 0.8 |

The coil tips are the brief's starting points. The stem necks were fitted to the one
parameter through T2's pair, so T1's neck is 0.81 rather than 0.85 and T3's 0.70 rather
than 0.65. Pfish's contrast, for comparison, is 1.49. The 40 px column matters because the
app ships one 1024 image and iOS scales it down: 40 px is the smallest an iPhone draws it
(a notification on a 2× screen).

### Measured

Round two's `measure()` on each rendered icon, with the stroke at the root taken by round
two's `widths()` on the ink below the fork. Written to
[`d-taper/measurements.json`](d-taper/measurements.json).

| | Stroke at root | Median stroke | Ink box (w × h) | Ink area | Leaf share | Coil at 180 px: clear radius · mouth gap | At 60 px |
|---|---|---|---|---|---|---|---|
| D-suite, round two | 0.0654 | 0.0646 | 0.564 × 0.692 | 0.107 | 23.1 % | 9.8 · 2.8 px | 3.3 · 0.9 px |
| T1 | 0.0654 | 0.0518 | 0.554 × 0.692 | 0.091 | 27.1 % | 12.4 · 5.8 px | 4.1 · 2.0 px |
| T2 | 0.0654 | 0.0459 | 0.551 × 0.692 | 0.087 | 28.4 % | 13.2 · 6.7 px | 4.4 · 2.2 px |
| T3 | 0.0654 | 0.0420 | 0.547 × 0.692 | 0.083 | 29.8 % | 13.9 · 7.5 px | 4.6 · 2.5 px |
| *The suite (§1)* | | *0.052–0.079, median 0.065* | *long side 0.55–0.82* | *0.09–0.14, median 0.11* | *17–24 %* | | |

The clear radius runs from the coil's centre at its tip to the nearest ink. The mouth gap
runs from the tip's round end to the nearest other ink, which is the crozier's own rising
stalk.

- **The root holds the suite's weight in all three**, at 0.0654.
- **The median stroke falls with the taper.** T1 lands on Pfish's 0.052, the lightest in
  the suite. T2 (0.046) and T3 (0.042) fall below the suite's range, T3 almost back to
  today's 0.040.
- **Ink area.** T1's 0.091 stays inside the suite's 0.09–0.14; T2 and T3 fall just under.
- **The leaf's share rises from 23 % to 27–30 %, though the leaf has not changed**: the
  stems lose a fifth (T1) to nearly a third (T3) of their ink. This is the measurable form of "chunkier by
  comparison". It also takes the white past the suite's measured 17–24 %, and past E's
  25.5 %, which round two called the top of the range. §3.6 sets no number.
- **The coil's eye opens.** Round two holds the inner radius at 1.33 strokes; against the
  thinner tip that is 2.4 tip widths in T1, 3.2 in T2 and 4.4 in T3. At 60 px round two's
  tip came within 0.9 px of its own stalk, and the taper more than doubles that gap.

### A heavier leaf: tried, not offered

T2 was drawn with the leaf at 0.85 and at 1.0 of the base stroke. Neither reads better.
At 60 px the leaf's eye, about three pixels across at 0.72, narrows to two at 0.85 and to
a one-pixel slit at 1.0, where the leaf starts to read as a solid white shape. The leaf's
share goes to 32 % and 36 %. The taper alone already makes the leaf the
heaviest-looking element, so the leaf stays at round two's 0.72 and there is no separate
option.

### Small sizes: untapered

**The small drawing (16, 32 and 48 px) and the favicon are round two's, untapered, for every
strength.** Their files are identical to `d-suite`'s apart from their titles.

- **§3.2a requires it.** Its fifth condition makes a small variant with the taper dialled
  back "required, not optional", because below about 24 px the thin section nears one
  device pixel and the stroke reads as broken.
- **The numbers.** On the 16 px favicon the base stroke is 1.49 px. Carried down, the coil's
  tip would be 0.82 px (T1), 0.63 px (T2) or 0.45 px (T3); at 32 px, 1.64, 1.25 or 0.90 px.
  The rows beneath the chosen one in `small-sizes.png` show each.
- **Why not a gentler taper.** Holding the tip to a pixel at 16 px allows a tip of at most
  0.67 of the base, Pfish's own ratio. At 16 px a stroke going from 1.5 to 1.0 px shows only
  as a greyer tip, and at 32 px it does not earn a second drawing. Untapered keeps the
  favicon the same whichever strength is chosen, and it is what Pfish does.

### At 60 px: what reads well and what does not

The 60 px row, enlarged 4×, in `compare.png` shows both.

- **Well: T1 and T2.** The coil is open, with a 2 px gap at its mouth, so it reads as a
  crozier uncurling. Round two's coil at the same size nearly closes on its own stalk into a
  "p" with a blob at its eye. The taper mends that.
- **Badly: T3.** Its last quarter turn is about 1.2 px wide and lights as a one-pixel line,
  partly grey, that fades into the eye. The round end is lost and the coil looks drawn with
  a finer pen than the rest. At 40 px it drops below a pixel. It is kept as the bracket that
  shows where the taper stops working, not as a candidate.
- **The stem's taper does not show at 60 px in any strength.** The neck is 3.2, 2.9 or
  2.7 px against 3.9 at the root, under a pixel of difference. At that size the leaf reads
  chunkier because the coil is lighter, not because of the neck. The neck shows at 180 px
  and above, and in the crops.
- **Beside the suite** (`suite-row.png`), T1's ink area (0.091) matches FlagFans' (0.09),
  and it holds its place in the row at 60 px. T2 and T3 are a shade lighter than everything
  beside them, which shows most next to UnCubed and Animal Rescue Centre.

### Recommendation: T2

- **It does what Marcus asked at the sizes he will see it.** The coil thins visibly at 360,
  180 and 60 px. The stem reaches the leaf at about the leaf's own line (0.75 against 0.72),
  so the leaf, a closed shape at the weight of the line that meets it, is the chunkiest
  thing in the mark. T1's neck (0.81) is still heavier than the leaf's line; T3's (0.70) is
  lighter, and its coil breaks up.
- **It holds at 60 px**: the tip is 1.6 px and the mouth gap 2.2 px. At 40 px the tip is
  still 1.1 px.
- **Its costs are known.** The median stroke (0.046) and ink area (0.087) sit just under the
  suite's measured ranges, and the leaf takes 28 % of the ink. The root keeps the suite's
  weight, which is where the brief asked the match to hold.

**T1 is the fallback** if keeping every suite measurement inside its range matters more
than the strength of the effect: its median stroke is Pfish's, its ink area is in range,
and its coil still visibly tapers. T3 is not recommended.

### The decision for Marcus

1. **Which strength?** T2, medium (recommended) · T1, gentle · T3, strong · none: keep
   round two's untapered D-suite.
2. **The small drawing and favicon untapered for every strength, per §3.2a's fifth
   condition?** Yes (recommended) · a gentle taper to Pfish's 0.67.
3. **Shall I make the §3.2a amendment below on `uncubed` `integration` once you have
   chosen?** Yes (recommended) · I'll do it.

**Decided: Marcus chose T2, 11 October.** He then asked for a little more curl in the
coil; see the last subsection of this section.

### Proposed amendment to `suite-brand.md` §3.2a

A proposal only: nothing in `uncubed` has been touched.

**Why it is needed.** §3.2a's first condition asks for modulation mirrored about the mark's
own axis. A growth taper is not mirrored: each stroke thins one way, from where it grows to
its tip. As written, Peace Garden's taper fails the first condition and meets the other
four. The amendment adds a second admissible kind rather than loosening "mirrored", so
irregular modulation stays excluded.

**§3.2, first bullet.** "A mark may carry **deliberate, mirrored stroke modulation** where
it earns it" becomes:

> A mark may carry **deliberate stroke modulation, mirrored or following growth,** where it
> earns it — see §3.2a, which sets the conditions and is not optional.

**§3.2a, condition 1** becomes:

> 1. **It is mirrored about the mark's own axis, or it follows growth.** Mirrored: whatever
>    the top of the form does, the bottom does. Following growth: in a mark drawn as
>    something growing, each modulated stroke is thickest where it grows from and thins
>    steadily towards its free end, and no stroke thickens again. Modulation that is merely
>    irregular is covered by neither.

**§3.2a, Pfish's heading**, "Pfish, the first and so far only app to use it", becomes
"Pfish, the first app to use it", and a second record follows Pfish's:

> **Peace Garden, the second app to use it and the first under the growth clause**
> (Recorded, 2026-10-__):
>
> | | |
> |---|---|
> | Taper strength | τ = 0.58: the crozier's tip at 1 − τ of the base stroke, the stem's neck at 1 − 0.43 τ |
> | Contrast | **2.38** on the crozier (thinnest 0.027, thickest 0.065 of the tile); **1.33** on the stem |
> | Profile | smoothstep along each stroke's length; full weight from the root to the fork; the crozier thins to its eye, the stem to the leaf; follows growth, not mirrored |
> | Small-size variant | the untapered drawing at 16, 32 and 48 px; carried down, the crozier's tip would be **0.63 device pixels** on a 16 px favicon |
> | Weight | still a number: the outline is generated from the centreline and the profile, so a new base stroke is a rerun, not a redraw |

**Knock-on edits to the amendment proposed in §6**, if T2 is chosen: the §3.4 block's
"The stroke is 0.065 of the tile" gains "at the root, tapering under §3.2a"; the §3.6 row's
"about a quarter of the ink" becomes "about 28 % of the ink, 23 % before the taper".

### Files in `d-taper/`

- [`make_taper.py`](d-taper/make_taper.py) writes everything below. Run it alone from the
  worktree root: `python3 design/logo-2026-10-11/d-taper/make_taper.py`. Round two's scripts
  are unchanged.
- `t1/`, `t2/`, `t3/`: each holds `icon-1024.svg`; `d-taper-tN.svg` and
  `d-taper-tN-light-ground.svg`; `d-taper-tN-small.svg` and
  `d-taper-tN-small-light-ground.svg`; `d-taper-tN-favicon.svg`;
  `d-taper-tN-one-colour.svg`; `d-taper-tN-lockup.svg` and
  `d-taper-tN-lockup-light-ground.svg`; and `in-context.png`. There is no contact sheet this
  round; the lockups are in the SVGs.
- `compare.png`, `suite-row.png`, `small-sizes.png` and `measurements.json`.

The sheets were rendered on a Mac without Inter, so their labels are set in the system's SF.
**Every PNG is under 450 KB.**

### Round two and three-quarters: more curl

*Added 11 October 2026. T2's files are unchanged. The three amounts are in `d-taper/c1/`,
`c2/` and `c3/`, written by [`d-taper/make_coil.py`](d-taper/make_coil.py).*

**Start with [`d-taper/curl-compare.png`](d-taper/curl-compare.png)**: T2 as chosen, then
C1, C2 and C3, then today's spiral icon, at 360, 180 and 60 px on both home-screen grounds,
60 px enlarged 4×, and each coil at 1024 px. Then
[`curl-suite-row.png`](d-taper/curl-suite-row.png),
[`c2/in-context.png`](d-taper/c2/in-context.png) and
[`curl-small-sizes.png`](d-taper/curl-small-sizes.png).

**What Marcus asked.** Having chosen T2, he asked, in his words:

> Just try giving it a little bit more of an inward spiralling curl so it's got a tiny more
> similarity to the original app logo.

The original is today's icon, a logarithmic spiral of two turns whose radius grows 2.55
times a turn (`tools/icon/make_icon.py`).

**What changes: the crozier's head, nothing else.** Round two's `meeting()` runs unchanged,
with its one call to `curl()` given new dials. The stalk, the fork, the stem, the leaf, T2's
taper (τ 0.58: coil tip 0.42, stem neck 0.75, leaf 0.72), the ramp, the placement and the
file set are all T2's. The taper still runs from the fork to the tip, so the tip is still the
thinnest point.

**Why the coil grows.** T2's head is a logarithmic spiral whose radius falls from 24 to 16
units over 0.85 turns, 1.61 times a turn. Wound on at that rate, a quarter turn more brings
the tip within 0.4 px of its own stalk at 60 px, and half a turn within 0.3 px: the turns
merge. So each amount winds faster, 2.15 to 2.3 times a turn, towards today's 2.55. The inner
radius is held at 10 units (0.83 strokes, about two tip widths) in all three, so the eye is
the same in each, and the outer radius grows so the first turn keeps its room. C1 stays T2's
size. C2 grows by a seventh and C3 by a third, to the right, which shifts the centred mark a
little to the left (see the 360 px row).

| | Turns | Radius, outer → inner | Inner radius ÷ stroke | Radius gain per turn | Coil size against T2 |
|---|---|---|---|---|---|
| T2, as chosen | 0.85 | 24 → 16 units | 1.33 | 1.61 | 1 |
| **C1, +¼ turn** | 1.10 | 25 → 10 units | 0.83 | 2.30 | 0.99 |
| **C2, +½ turn** | 1.35 | 29 → 10 units | 0.83 | 2.20 | 1.14 |
| **C3, +¾ turn** | 1.60 | 34 → 10 units | 0.83 | 2.15 | 1.32 |

Measured as before, in device pixels. The tip is 1.65 px at 60 px and 1.10 px at 40 px in
all four, since the taper has not changed. The mouth gap runs from the tip's round end to
the nearest other ink: the stalk in T2 and C1, the turn outside it in C2 and C3. In all four
it is the tightest gap in the coil. The eye is measured from the spiral's centre to the
nearest ink. By this measure T2's eye is 4.3 px at 60; §8's 4.4 measured from the tip's
centre of curvature.

| | Mouth gap at 180 · 60 · 40 px | Eye at 180 · 60 · 40 px | Coil to stem · to leaf at 60 px | Coil's lowest ink above the fork |
|---|---|---|---|---|
| T2 | 6.7 · 2.2 · 1.5 | 12.8 · 4.3 · 2.8 | 3.7 · 8.4 px | 0.097 of the tile |
| C1 | 5.3 · 1.8 · 1.2 | 7.2 · 2.4 · 1.6 | 3.7 · 8.4 px | 0.118 |
| C2 | 5.0 · 1.7 · 1.1 | 7.2 · 2.4 · 1.6 | 3.6 · 8.3 px | 0.092 |
| C3 | 5.0 · 1.7 · 1.1 | 7.2 · 2.4 · 1.6 | 3.6 · 8.2 px | 0.061 |

| | Stroke at root | Median stroke | Ink box (w × h) | Ink area | Leaf share |
|---|---|---|---|---|---|
| T2 | 0.0654 | 0.0459 | 0.551 × 0.692 | 0.087 | 28.4 % |
| C1 | 0.0654 | 0.0479 | 0.546 × 0.692 | 0.089 | 27.8 % |
| C2 | 0.0654 | 0.0460 | 0.585 × 0.692 | 0.099 | 25.1 % |
| C3 | 0.0654 | 0.0459 | 0.632 × 0.692 | 0.110 | 22.4 % |

- **No coil touches or crowds anything.** Every coil keeps 3.6 px from the stem and 8 px
  from the leaf at 60 px, and stays above the fork it grows from.
- **The eye stays open** at 180 and 60 px: 2.4 px from the centre to the nearest ink at 60.
  It is smaller than T2's 4.3, because the tip now winds in towards the centre.
- **The bigger coils give back some of the ink the taper took.** C3's ink area, 0.110, is the
  suite's median, and its leaf share, 22 %, is back inside the suite's 17–24 %. The same fact
  cuts the other way: the leaf reads less chunky beside a bigger coil, and that contrast was
  why Marcus chose T2.
- The hue band is unchanged, 86°–110°. C3's starts at 85° because its wider box stretches
  the one sweep.

**The small drawing stays round two's.** Its untapered stroke, 1.35 times heavier, leaves no
room for more turns. A fifth of a turn more closes the mouth to 0.27 px on the 16 px favicon.
Keeping the mouth open needs a faster wind and a bigger coil: the best found, a sixth of a
turn more, makes the coil 16 % wider and brings it to 0.1 px above the fork at 16 px. At 16
and 32 px it then reads as a bigger hook, not as more curl. `curl-small-sizes.png` shows
both rows. The small and favicon files in `c1/` to `c3/` are round two's, apart from their
titles.

**What reads well and what does not.**

- **Well, at 360 and 180 px:** C2 and C3 read as spirals, with one full winding inside the
  outer turn, and that is what today's icon is. C1's tip tucks inside the stalk, so the coil
  closes round its eye, but it still reads as T2's curl with the tip turned in.
- **At 60 px** all three hold: no gap is under 1.66 px. C1's inner loop is small, and at
  this size its likeness to today's spiral barely shows.
- **Weak, at 40 px** (a notification on a 2× iPhone, the smallest the icon is drawn): in C2
  and C3 the inner turn runs 1.1 px from the turn outside it, and the two blur into one grey
  band in places. C1 has one such place, near the stalk, where C2 and C3 have half a turn of
  it.
- **Weak, in C3 at every size:** the coil grows by a third and leads the mark; the spiral
  outweighs the leaf.

**Recommendation: C2.**

- It is the smallest amount at which the coil reads as a spiral rather than a hook at 180
  and 60 px, with one full inward winding as today's icon has. That is the likeness Marcus
  asked for.
- It costs a coil a seventh larger, and the gaps hold at 60 px: the mouth is 1.7 px and the
  eye 2.4 px.
- The leaf keeps 25 % of the ink, still above the suite's 17–24 %, so T2's chunkier leaf
  survives.

**C1 is the fallback** if "a little bit more" should stay that small: the same size as T2,
and the safest at 40 px, but the likeness barely shows on a phone. C3 is not recommended,
because the coil takes over the mark and blurs at 40 px.

**The decision for Marcus.**

1. **How much more curl?** C2, half a turn more (recommended) · C1, a quarter turn ·
   C3, three-quarters · none, keep T2's coil.
2. **The small drawing and favicon?** Keep round two's (recommended) · take the extra curl
   with a bigger coil.

**Decided: Marcus chose C2, 11 October**, with an earlier taper and a lower fork; see the
next subsection.

**Files.** `make_coil.py` writes `c1/`, `c2/` and `c3/` (T2's file set, prefixed
`d-taper-cN`, with `in-context.png` in `c2/` only), `curl-compare.png`,
`curl-suite-row.png`, `curl-small-sizes.png` and `coil-measurements.json`. Run it after
`make_taper.py`, from the worktree root. `make_taper.py`'s sheet functions now take their
columns and outputs as arguments; its own files come out byte-identical. **Every PNG is
under 450 KB.**

### Round two and seven-eighths: earlier taper, lower fork

**Marcus chose C2, 11 October**, and asked for two changes. In his words:

> We will need to introduce the taper faster so that we don't have the very thick line all
> the way through to the top of that tendril and only narrowing at that point, as it looks
> too heavy in comparison to the relatively small flower head on the left. So perhaps also
> move that tendril a bit down so it splits from the main stem further down, and start the
> taper sooner, on the basis of the extra half turn option.

**Decide from [`d-taper/coil2-choice.png`](d-taper/coil2-choice.png).** It shows A, B and C,
then D (C2 as it is now), then today's icon for reference, on both home-screen grounds, at
240 px and at 60 px. The 1024 px crops of each coil and fork are in
[`coil2-compare.png`](d-taper/coil2-compare.png), and A beside the app is in
[`coil2-a/in-context.png`](d-taper/coil2-a/in-context.png).

**He was right about the weight.** In C2 the tendril is still 0.91 of the base stroke at the
top of its rise, where the stem beside it has already thinned to 0.81. The tendril was the
heavier line at that height.

**What changed, in the tendril only.** The stem, its own taper (neck 0.75) and the leaf are
C2's, point for point.

- **An earlier taper.** The tendril now thins along an ease-out, 1 − (1 − u)^2.5 over its
  length u, starting at the fork. That front-loads the thinning, where round two and a
  half's smoothstep left most of it to the coil. By the top of its rise the tendril is 0.69
  of the base, against the stem's 0.81–0.88 at the same height. It then settles into the
  same tip, 0.42 of the base, without a wedge. A thinner tip would fall under a pixel at
  40 px, so the tip stays at 0.42.
- **A lower fork.** Round two takes the fork 22 of the stem's 120 steps up. Lowering the fork
  alone barely moves the visible split, because the tendril leaves almost parallel to the
  stem. So in A and B it also leaves a little wider and bends a little less, entering the
  coil on much the same heading.
- **A slightly smaller coil.** The thinner turns need less room, so the half turn more fits
  an outer radius of 27 units, not C2's 29. The coil is now about T2's size.

| | Fork (steps of 120) | Fork, above the root's end | Visible split, above the root's end | How the tendril leaves | Taper | Tendril at the top of its rise (stem there) | Tip |
|---|---|---|---|---|---|---|---|
| **A, lower fork** | 14 | 13 % of the mark's height | 34 % | 14° off the stem's line, bending 18° over 52 units | ease-out from the fork | 0.69 (0.84) | 0.42 |
| **B, lowest fork** | 10 | 10 % | 29 % | 17°, bending 17° over 48 units | ease-out from the fork | 0.70 (0.88) | 0.42 |
| **C, fork as now** | 22 | 17 % | 42 % | 8°, bending 23° over 52 units, as C2 | ease-out from the fork | 0.69 (0.81) | 0.42 |
| D, C2 as now | 22 | 17 % | 43 % | as C2 | smoothstep | 0.91 (0.81) | 0.42 |

The visible split is the first point up the tendril whose edge clears the stem's. The angles
are the stalk's headings off vertical, round two's 0.14 and 0.40 radians in C and D.

| | Mouth gap at 180 · 60 · 40 px | Eye at 180 · 60 px | Coil to stem · to leaf at 60 px | Coil's lowest ink above its fork | Coil (w × h) | Median stroke | Ink area | Leaf share |
|---|---|---|---|---|---|---|---|---|
| A | 5.0 · 1.7 · 1.1 | 7.2 · 2.4 | 4.6 · 10.9 px | 0.093 of the tile | 0.277 × 0.251 | 0.034 | 0.090 | 27.5 % |
| B | 5.0 · 1.7 · 1.1 | 7.2 · 2.4 | 4.5 · 12.6 px | 0.062 | 0.276 × 0.253 | 0.035 | 0.090 | 27.6 % |
| C | 5.0 · 1.7 · 1.1 | 7.2 · 2.4 | 4.1 · 8.7 px | 0.101 | 0.278 × 0.251 | 0.035 | 0.089 | 27.8 % |
| D | 5.0 · 1.7 · 1.1 | 7.2 · 2.4 | 3.6 · 8.3 px | 0.092 | 0.306 × 0.272 | 0.046 | 0.099 | 25.1 % |

- **The coil's gaps are C2's.** The mouth is 1.7 px at 60 and 1.1 at 40, the eye 2.4 px at
  60, and the tip 1.65 px at 60 and 1.10 at 40.
- **Nothing crowds.** Every coil sits further from the stem than C2's, and further from the
  leaf. Each stays above its own fork, B closest at 0.062 of the tile.
- **The root stays at the suite's 0.0654.** The median stroke falls to about 0.034, half the
  root's, because most of the tendril is now thin. That is under the suite's measured range
  of 0.052–0.079, and it is the measurable form of a lighter tendril.
- **The leaf's share returns to about 27.5 %,** close to T2's, so the leaf again reads
  chunkier than what is below it.

**What reads well and what does not.**

- **Well:** in A, B and C the tendril is plainly the lighter line, and the leaf is the
  heaviest-looking thing in the mark, as Marcus wanted. A's split sits about a fifth lower
  than C2's (34 % of the mark's height, against 43 %), and the tendril leaves at a clearer
  angle.
- **C** shows the earlier taper alone. The tendril is lighter, but it still splits as high
  as C2's, so it answers the first request and not the second.
- **Weak, B:** its fork sits about one stroke above the root's end, the nearest of the three.
  Its coil sits lowest, 46 px below A's at 1024, so the mark's weight moves down. The tendril
  starts to look like a second shoot from the base rather than a branch of the stem.
- **Weak, all three at 40 px:** the coil's gaps are C2's, 1.1 px, so the inner turn still
  blurs into the one outside it in places.

**The small drawing and favicon stay as round two drew them.** They are untapered, by
§3.2a's fifth condition, so the earlier taper does not apply. A lower fork was tried in the
small drawing: at 16 and 32 px it opens the crotch slightly, but the hook then sits level
with its own fork at a fork of 14 steps, and drops below it at 10. That is not better.

**Recommendation: A.** It answers both requests. The tendril is lighter from the fork up and
splits a fifth lower, and the coil keeps C2's half turn at about T2's size. The fork stays
well clear of the root's end, which B does not, and C leaves the split where it was.

**The decision for Marcus.**

1. **Which tendril?** A, lower fork and earlier taper (recommended) · B, lowest fork ·
   C, fork as now with the earlier taper · D, C2 as it is now.

**Files.** [`make_coil2.py`](d-taper/make_coil2.py) writes `coil2-a/`, `coil2-b/` and
`coil2-c/` (T2's file set, prefixed `d-taper-coil2-x`, with `in-context.png` in `coil2-a/`
only), `coil2-choice.png`, `coil2-compare.png` and `coil2-measurements.json`. Run it after
`make_taper.py` and `make_coil.py`. `make_taper.py`'s `Taper` gained two dials: the
tendril's ease-out, and where the stem's taper starts when the fork moves. Its root measure
also gained a fallback for a fork too low for `widths()`. Every earlier file comes out
byte-identical. **Every PNG is under 450 KB.**

Marcus chose A, 11 October 2026; ported to `tools/icon/make_icon.py` on branch `claude/icon-port-2026-10-11`.
