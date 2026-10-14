# The thin small capitals and the count line, 14 October 2026

Marcus's choices from `design/app-polish-2026-10-14/small-caps-AB.png`, built:

- **29B**: the thin small-capital lines use `Chrome.muted` instead of `Chrome.faint`. These are a plant's place and date (and its written coordinates), the stage caption, and the seed screen's form and row labels.
- **30A**: the garden's count line is white by day (`Chrome.ink`, which is white in the garden's Dark). By night it stays `muted`.

Drawn on an iPhone Air (iOS 26.5 simulator, English, Large) by the mass test's screen harness, the same harness and garden as 26A. Measured off the screenshots in the same way.

| File | What it shows |
|------|---------------|
| `small-caps-before-after.png` | The four places from 26A, before and after, in Dark and Light. The garden is drawn as in Dark in both: Light shows it by day (noon), Dark by night. |
| `count-line-by-hour.png` | The count line after 30A at 24 moments of the day: October, December and June, with the plot turned and at AX3. Then midnight, before and after. |
| `measurements.json` | Every number on both sheets. |
| `compose.py` | Makes all three from the harness's sweeps. |

## Contrast, before and after

These figures are measured off the screenshot against the median of the text's own box. **Strokes** is the mean of the text's most inked 4% of pixels. **Peak**, in brackets, is its darkest (on light) or brightest (on dark) half-percent. Each figure is the lowest of the place's texts.

| Line | Light, before | Light, after | Dark, before | Dark, after |
|------|---:|---:|---:|---:|
| A plant's place and date | 4.87 (5.04) | **6.92** (7.17) | 6.59 (6.79) | **10.73** (10.99) |
| The stage caption | 4.67 (4.84) | **6.49** (6.70) | 6.62 (6.81) | **10.29** (10.53) |
| The seed screen's labels | 4.81 (4.93) | **6.83** (7.01) | 6.52 (6.66) | **10.61** (10.82) |

| The count line | Before (`muted`) | After |
|------|---:|---:|
| By day, October noon | 3.54 (3.62) | **4.92** (4.95), white |
| By night, midnight | 9.84 (10.09) | 9.84 (10.09), `muted` as before |

By arithmetic on the screen's ground, `muted` is 6.8 : 1 in Light and 10.5 : 1 in Dark. `faint` is 4.8 and 6.5.

The accessibility audit (`performAccessibilityAudit`, one run each) flags fewer contrast issues on these texts afterwards:

- Light went from 4 to 3. The count line by day is no longer flagged, and the seed screen's *Created* went from failed to nearly passed.
- Dark went from 3 to 2.

It still flags the stage's *Mature* in both appearances, and the seed screen's *Petals* row, even at 10 : 1 in Dark. So it is measuring something other than the type's grey there. The seed rows are one combined element, and the row's `faint` glyph is the likely thing it reads. 26A also saw these counts move from run to run.

## The count line by day

White falls under 4.5 : 1 for part of the day. **This is the number Marcus asked to see before deciding on a shade.** None has been added.

| Moment (London, the garden's season for the date) | White, as drawn | `muted` over the same sky (before) |
|------|---:|---:|
| 15 October, 06:15 | 6.41 | 4.29 |
| 15 October, 07:00 | **3.93** | 2.88 |
| 15 October, 07:30 | **3.78** | 2.79 |
| 15 October, 08:00 | 4.62 | 3.26 |
| 15 October, 09:00 | 4.76 | 3.34 |
| 14 October, 12:00 (Always day) | 4.92 | 3.43 |
| 15 October, 15:00 | 5.66 | 3.85 |
| 15 October, 17:00 | 8.12 | 5.16 |
| 15 October, 17:45 | 9.83 | 6.12 |
| 15 October, 17:00 and 17:45, plot turned twice | 6.44, 6.81 | 4.30, 4.54 |
| 15 December, 12:00 | 5.11 | 3.55 |
| 15 June, 06:15 | 5.72 | 3.93 |
| 15 June, 07:00 | **3.74** | 2.76 |
| 15 June, 07:30 | **4.03** | 2.92 |
| 15 June, 08:00 | **4.10** | 2.96 |
| 15 June, 09:00 | **4.11** | 2.97 |
| 15 June, 12:00 | **4.00** | 2.90 |
| 15 June, 12:00, plot turned once, twice, three times | **4.17, 4.48, 4.17** | 3.00, 3.17, 3.00 |
| 15 June, 12:00, AX3 (the garden's words stop at AX1) | **4.03** | 2.91 |
| 15 June, 15:00 | 4.64 | 3.28 |
| 15 June, 17:00 | 6.12 | 4.12 |

- **The lowest is 3.7 : 1.** In October the line is under 4.5 for part of the first two hours of the morning: some time after 06:15 until before 08:00, with 3.9 at 07:00 and 3.8 at 07:30. In June it is under 4.5 from some time after 06:15 until some time between noon and 15:00.
- The cause is the sun. It stands beside the heading in the morning, and its halo lightens the sky behind the line. A summer sky is also paler overhead.
- Evenings are darker: 6 to 10 : 1, and 6.4 to 6.8 with the plot turned so that the sun sets on the heading's side.
- At every moment measured, white is 1.35 to 1.6 times what `muted` was.
- The right-hand column is worked out by arithmetic: white at 0.72 laid over the median colour of the line's box in the after screenshot. At October noon it gives 3.43, against the 3.54 measured off the before screenshot.

## How it was made

1. Build: `build-for-testing` of the `MassTestUI` and `MassTestUnit` schemes (`tools/masstest/app/masstest.yml`) into one DerivedData, under the shared Xcode lock, with `-jobs 4`.
2. Fixture: `python3 tools/masstest/app/make_garden.py 14 build/fixtures/garden-14.json`.
3. Before and after, each from its own build: `run_tests.sh screens <sim> <out> <clock> PG_MT_FIXTURES=… PG_MT_AUDIT=en PG_MT_CONFIGS='en/L/dark;en/L/light' PG_MT_SCREENS=stage,seed,garden,plant`.
4. Each moment of the day: the same, with `PG_MT_CONFIGS=en/L/light PG_MT_SCREENS=garden` and `PG_MT_ARGS='-garden.daylight.v1 byTheClock -developer.clockShift <seconds>'`. Add `-garden.turn.v1 <n>` for a turned plot.
   - The shift always winds forward: a launch argument's value cannot begin with a minus, so the October hours are taken on 15 October.
5. Compose: `python3 design/small-caps-2026-10-14/compose.py <renders> design/small-caps-2026-10-14`.

## Left as they were

The B render left the plant screen's own growth caption (the *MATURE* under the date) and its standing line in `faint`, so these are still `faint`. They are the same 10-point small capitals.

The seed screen's rows share their row with the name sheet's *Area* row, so that label is `muted` too.
