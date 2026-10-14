# The count line's shadow, 14 October 2026

Marcus's 31A: see a soft dark shadow under the garden's count line by day before choosing one. Three strengths are rendered here. **None is chosen**: the branch still ships the line without a shadow (`CountLineShadow.shipping = .none`).

Drawn on an iPhone Air (iOS 26.5 simulator, English, Large) by the mass test's screen harness, the same harness, garden and moments as `design/small-caps-2026-10-14/`.

| File | What it shows |
|------|---------------|
| `shadow-ABC.png` | Rows: seven moments. Columns: no shadow, A, B, C. Each cell is the count line at the screenshot's own pixels, with its contrast under it. |
| `measurements.json` | Every figure, letter by letter. |
| `compose.py` | Makes both from the harness's renders. |

## The three

Every one is black, has no offset, and is cast by the letters themselves: no plate, no edge, nothing straight. By day only; by night the line stays `muted` with no shadow (midnight with B asked for is the same picture as without, to the pixel's rounding).

| | Shadows | How it looks |
|---|---|---|
| **A**, subtle | one: 50% at 2 pt | a slight softening under the letters |
| **B**, medium | one: 75% at 2.5 pt, drawn twice | a soft dusk round the words |
| **C**, tight and haze | 100% at 1 pt, then 85% at 3.5 pt round it | a darker rim hugging the strokes, in a haze |

**B is drawn twice because one shadow cannot do it.** The strokes are about a point wide, so a shadow blurred off them is thin. In tuning, one shadow at 85% held the letters in the sun's halo to 4.1 : 1 at best. The same soft shadow drawn a second time, round the first, is twice as dense and no harder.

## Contrast

The lowest letter of the line, against the sky immediately round it:

| Moment (London, the garden's season for the date) | None (build 9) | A | B | C |
|------|---:|---:|---:|---:|
| 15 October, 07:00 | 3.40 | 3.84 | **5.16** | **5.15** |
| 15 October, 07:30 | 3.24 | 3.72 | **5.17** | **5.11** |
| 15 June, 07:00 | 3.21 | 3.66 | **4.93** | **4.92** |
| 15 June, 12:00 | 3.28 | 3.66 | **4.61** | **4.59** |
| 15 June, 07:00, AX5 | 3.26 | 3.98 | **6.69** | **6.26** |
| 15 October, 12:00 (for reference) | 3.97 | 4.40 | **5.45** | **5.42** |
| 15 October, 17:00 (for reference) | **8.15** | **8.72** | **10.37** | **10.39** |
| Midnight (night, `muted`, no shadow) | **9.61** | | **9.61** with B asked for | |

- **B and C hold 4.5 : 1 at every moment measured.** The lowest is 4.6, at June noon.
- **A does not hold it at any of the four worst moments.** It adds about half a point everywhere.
- **Without a shadow the worst letters are at 3.2 to 3.4**, lower than the 3.7 to 4.0 on the last sheet. That sheet measured the whole line against its box. Here each letter is measured on its own, and the sky behind the line is uneven:
  - On a morning, the sun's halo lies behind *GROW* (October) or *WN F* (June).
  - At noon in June, a cloud's edge stands behind the *14*.
- **AX5:** the label voice stops growing at AX3, so the line is drawn at AX3. Its strokes are thicker there, so each shadow is denser: B is 6.7.
- **Evening:** already 8 : 1 without a shadow. A shadow adds nothing needed there, but one rule for the whole day is simpler than fading it with the light.

### How it was measured

- The letters are found in each moment's render without a shadow, anti-aliased edges included. They stand in the same place in all four renders.
- **The text** is the line's strokes, as before: the mean of its box's most inked 4% of pixels. It is white, 1.0, in every render.
- **The ground** is the pixels between one pixel and two points away from a letter, inside the shadow. Each belongs to the letter nearest it.
- **The figure** is the text against the median of each letter's ground, the lowest of the line's 19 letters.
- The screenshots are read as PNG, with the harness's new `PG_MT_PNG=1`. The harness's JPEG rings right next to a white stroke, which is exactly where this ground is.

`measurements.json` keeps two other figures for each cell:

- **The line's median** (`lineMedian`): the whole line's ground in one median. Without a shadow it reads 4.5 at October 07:30, while the letters in the halo are at 3.2, so it is too kind to stand alone.
- **The last sheet's figure** (`againstBoxMedian`): the text against its whole box. Without a shadow it gives 3.97, 3.82, 3.75 and 4.05 at the four worst moments, against 3.93, 3.78, 3.74 and 4.00 on the last sheet. B gives 5.76, 5.67, 5.33 and 5.39.

## Recommendation: B

- **B and C measure the same.** They are within 0.06 of each other at every moment but AX5, where B is ahead, 6.7 to 6.3.
- **B is the softer of the two.** It reads as one dusk round the words.
- **C's inner shadow reads as an outline close up.** It is full black at a point, hugging the strokes. That is the look Marcus ruled out: an outline, where the shadow should be part of the sky's softness.
- **A is the gentlest but does not do the job.** It leaves the halo letters at 3.7.

Worth looking at on a phone before deciding: at a noon of plain blue sky, B's dusk is visible where nothing was needed. The noon row on the sheet shows it.

## Making one the default

One line in `App/PeaceGarden/Views/PlotView.swift`, in `CountLineShadow`:

```swift
static let shipping: Strength = .none
```

Change `.none` to `.A`, `.B` or `.C`. Nothing else changes: the night already has no shadow, and the Debug switch keeps working for later renders.

The Debug switch, for the renders: `-pgCountShadow A` (or `B`, `C`, `none`), or a stack of `opacity@radius` for tuning, such as `-pgCountShadow 0.75@2.5+0.75@2.5`.

## Tuning

These were tried before A, B and C were settled, at October 07:30 and June 07:00. Each figure is the lowest letter.

| Shadows | Oct 07:30 | June 07:00 |
|---|---:|---:|
| 35% at 2.5 pt (the first A) | 3.62 | 3.57 |
| 55% at 3 pt (the first B) | 3.78 | 3.71 |
| 80% at 1.5 pt | 3.87 | 3.78 |
| 85% at 2 pt | 4.09 | 3.93 |
| 50% at 1 pt + 35% at 5 pt (the first C) | 3.88 | 3.82 |
| 100% at 1 pt + 60% at 5 pt | 4.58 | 4.35 |
| 60% at 2.5 pt, twice | 4.66 | 4.51 |
| 70% at 2 pt, twice | 5.09 | 4.67 |

- B was first set at 65% twice and C's haze at 75%. Both came out under 4.5 at June noon, where the cloud stands behind the *14*: 4.37 and 4.47.
- Raised to 75% twice and 85%, they give 4.61 and 4.59 there.

## How it was made

1. Build: `build-for-testing` of the `MassTestUI` scheme (`tools/masstest/app/masstest.yml`) into `build/DD`, under the shared Xcode lock, with `-jobs 4`.
2. Fixture: `python3 tools/masstest/app/make_garden.py 14 build/fixtures/garden-14.json`.
3. Each cell is one sweep, the four of a moment one after another: `run_tests.sh screens <sim> <out> <clock> PG_MT_FIXTURES=… PG_MT_AUDIT=none PG_MT_PNG=1 PG_MT_CONFIGS=en/L/light PG_MT_SCREENS=garden PG_MT_ARGS='-garden.daylight.v1 byTheClock -developer.clockShift <seconds> -pgCountShadow <none|A|B|C>'`.
   - The largest type uses `PG_MT_CONFIGS=en/AX5/light`. Midnight uses `en/L/dark` with no clock shift.
   - The shift is worked out at the start of each sweep, winding forward to 15 October or 15 June 2027.
4. Compose: `python3 design/count-line-shadow-2026-10-14/compose.py <renders> design/count-line-shadow-2026-10-14`.
