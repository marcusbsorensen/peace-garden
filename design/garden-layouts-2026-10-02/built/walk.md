# The Long Walk, built: interlocking drifts

Option A of `RESEARCH.md` §*The Long Walk*, as Marcus chose it on 2 October 2026,
with each plot graded cool–hot–cool (his yes to question 5). Built on the
layouts foundation (`tools/layouts/`).

## What was built

**The rule changed.** The tiers' two staggered straight rows are gone, and three
parts of the old rule become lens rules.

- **The table**, `tools/layouts/tables/long_walk_drifts.py`, written to
  `PlaceTable.longWalkDrifts` (Swift), `LongWalkDriftsTable` (PHP) and
  `tables/long_walk_drifts.js`. One feature variant, 48 places in twelve lenses.
  - Each border has six lenses: 5, 3, 5, 3, 5, 3 places on the x− border and
    3, 5, 3, 5, 3, 5 on the x+ one, so a lens of five faces a lens of three.
  - Each lens slants from its back at the hedge, up the walk, to its tip at the
    path's edge, down the walk. It is 1.3 m long along the walk, and each
    overlaps the next like slates.
  - Each lens's spine is bowed by about 5 cm. Its places sit a little either
    side of the spine.
  - Tags: `side`, `lens` (rank from the plot's middle), `tier`, and `along`
    (where the lens comes in its border, 0 to 5 from the head). The table also
    carries each lens's outline, `lens0` to `lens11`.
- **Tiers by depth along a lens.** A lens of five is back, middle, middle,
  front, front; a lens of three is back, middle, front. A plot has 18 front, 18
  middle and 12 back places, where the rows had 20, 16 and 12.

  | Tier | Places | Out from the middle of the path |
  |---|---|---|
  | Front | 18 | 0.90–1.22 m (rows: 0.82–1.08) |
  | Middle | 18 | 1.33–1.69 m (rows: 1.32–1.58) |
  | Back | 12 | 1.78–1.94 m (rows: 1.82–2.08) |

  The cuts (0.75 m, 1.18 m) are unchanged.
- **The rule** (`LongWalk.Walk.place`, `LongWalk::place`) works through the
  plots from the oldest. In each plot it tries, in turn:
  1. a lens its colour has claimed, in its own tier;
  2. a lens nobody has claimed, in its own tier;
  3. a lens its colour has claimed, in the tier beside its own.

  Only then does it open a new plot. In a lens, a plant takes the first free
  place of its tier in table order, the lens's middle first.
  - **A lens is a drift**: it is claimed by the colour family of its first plant,
    read off the plants, and holds only that colour. The cap of five is the
    lens.
  - **Graded cool–hot–cool**: a warm colour (families 0, 1 and 5) claims free
    lenses from the plot's middle out. A cool one claims the same groups of four
    the other way round, ends first.
  - **Repetition**: a colour never claims a lens beside one it already holds.
    That counts the lens before or after it in the same border, and the lens it
    meets across the join with the next or previous plot, as the walk is drawn.
  - **Nothing stands in front of something shorter**: the same check as
    before, by tier, within 1.3 m along the walk on one side.
- **Plots vary by number**: a half turn, a mirror or both, four ways in all
  (`LongWalk.variants`, now read). The path stays where it runs, and the drifts'
  slant changes from plot to plot. Plot 0 is the plan as drawn.
- **The nudge is ±0.05 m** both ways, where it was ±0.10 m and ±0.14 m. The
  places no longer sit on a grid that needs hiding.
  - The nearest two places are 0.365 m apart, and 0.22 m at the worst nudge.
  - The rows' nearest two, across two tiers, were 0.25 m apart, and at the old
    nudge two plants could stand on one spot.
- **The stored shape is the same.** A planting still stores `side`, `tier` and
  `slot_index`; `slot_index` is now the place's number in the table. The
  service works out the spot when it serves a planting:
  `LongWalk::spot($plot, $index, …)` adds the nudge and applies the plot's
  variant.
- **Vectors and checks.**
  - Each row of `long_walk_vectors.json` gains its plot's `variant` and its
    `spot`. `check_long_walk.php` compares both with the Swift's exactly.
  - `check_long_walk.php` also checks that the PHP's own walk has one colour to
    a lens, no colour in two lenses side by side, and nothing in front of
    anything shorter.
  - `placementCannotTurn` now groups heights by plot and side, because a lens
    runs across all three tiers.
- **The ambassador** (*Zephea pallida*, red, front tier) now stands at the tip
  of the first warm lens, in the middle of plot 0, rather than at the plot's
  head. `ambassador_vectors.json` is re-recorded for that one line.
- **The drawing** (`longwalk.js`):
  - Each border is a bed of loam (`COLOUR.bed`) along the hedge. Each lens runs
    out from the bed to the grass verge, so the bed's front is scalloped by the
    drifts' tips and the grass comes in between them.
  - The bed is darker down the middle of each lens, so a part-sown drift's
    slant still shows.
  - The beds come from the table's lens outlines. Each plot's variant comes
    from the module, so a plot turned half round has beds slanting the other
    way, as its plants do.
  - The ground is laid again when the plots on the stage change (`layWalk`,
    called by `growPlots` and `growFromService`).
  - The bed's edge is a field blended over a few centimetres, with no ruled
    line.
  - The path, the rill and the hedges are as they were.
- **The workbench** (`/dev/walk`) takes `?plot=`, as the other areas' do, and
  each plot's line counts how many of its twelve drifts are claimed.

## The fill, against the baseline

`layouts-harness --area travel --against tools/layouts/baseline.json`:

| Arrivals | Plots | Places held | Held | Settled plots | Held in settled | Empty in settled |
|---|---|---|---|---|---|---|
| 10 | 1 | 11 of 48 | 22.9% | 0 | — | — |
| 100 | 3 | 101 of 144 | 70.1% | 1 | 95.8% (100.0%) | 2 (0) |
| 1,000 | **22 (24)** | 1001 of 1056 (1152) | **94.8% (86.9%)** | 20 (22) | **98.9% (92.2%)** | **11 (82)** |

**At a thousand, every figure is better than the baseline.** Two plots fewer;
82 empty settled places become 11. At a hundred, the one settled plot holds 46
of its 48. A lens's last place waits for its colour.

What the drifts look like on the area's own thousand plants (settled plots,
measured by a third copy of the rule in Python that places all 600 vector
arrivals where the Swift does):

- one colour in two lenses side by side: **none**; one colour running on across
  a join: **none**;
- warm plants in the four lenses nearest a plot's middle: **296 of 425** (70%);
  cool plants in the four lenses at its ends: **309 of 524** (59%);
- plants standing a tier from their own: **109 of 949** (11.5%), where the rows
  had **24 of 974**. See *Left open*.

## Renders

From `/dev/walk` on a local server, headless, cropped to the plot. The workbench
invents its own walk, so these are the same plants before and after:

- `walk-before-10.jpg`, `walk-after-10.jpg`: plot 0 after ten arrivals.
  - Before, they stand in a gap-toothed row at the head of the plot.
  - After, they stand round its middle and its ends, in a bed whose drifts
    already slant.
- `walk-before-full.jpg`, `walk-after-full.jpg`: plot 3 of 500, full.
- `walk-before-three.jpg`, `walk-after-three.jpg`: plots 3, 4 and 5 end to end.
  Plots 3 and 5 are mirrored; plot 4 is turned half round and mirrored, so its
  drifts slant the other way down the walk.
- `walk-after-plan-three.jpg`: the same three plots as a plan, from the rule as
  built on the area's own thousand plants. Plants are coloured by family and
  each lens is tinted by the colour that claimed it. The drifts read as drifts
  across all three plots, slanting one way in plots 3 and 5 and the other way in
  plot 4, with no colour running across a join. The flowers in the 3D render
  are small beside their leaves, which is why this plan is here.

## What a replant needs

**The Long Walk needs replanting when this is deployed**, in the same step. The
service works out each plant's spot when it serves it, as the other areas'
services do, but that does not save this area.

- A stored `slot_index` meant a place in a tier's two rows (0–9). Now it means a
  place in the table (0–47). Served after a deploy, an old row would stand at
  whichever table place has its number: often in another tier, and sometimes on
  the same spot as another old row.
- The rule would read old rows' lenses and claims from those same numbers.

So **deploy and replant together**. `tools/replant` replays every arrival
through `LongWalk.Walk` and writes the same columns (`side`, `tier`,
`slot_index`, the nudge), with no schema change and no change to
`Replant/Areas.swift`.

- Capacity is unchanged: 48 a plot.
- Plot assignment changes. The rule fills old plots harder, so the live walk
  will take fewer plots than it does now, and most plants change plot as well
  as place.

## Left open

- **More plants stand a tier from their own**: 11.5% of settled plants, against
  2.5% in the rows. Every one still stands in order: nothing taller is in
  front of it within reach. The cause is that the rule now tries the tier
  beside in an old plot before opening a new one, and that is what fills the
  plots.
  - If Marcus prefers purer tiers, a plant can try its own tier in every plot
    first. Measured: 24 plots, 91.9% of settled places held, 27 a tier off.
  - That is the baseline's plot count, with 0.3 points fewer settled places
    held than the baseline, so it is not built.
  - Other mixes of tiers in a lens were worse on both counts.
- **The near border's bed is mostly hidden** behind the low hedge, from the
  page's eye, as its plants always were.
- **The path is unchanged.** Its verges now meet a scalloped bed edge rather
  than open turf. Bending the path itself was option B.
- **The map glyph** needs no change. The glyphs stay symbolic (Marcus, 28
  September).
- `docs/WEB-GARDENS.md` §*The Long Walk, built* describes the rows, the drift
  cap and the slot order, and needs folding in.
