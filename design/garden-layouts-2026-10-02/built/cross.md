# The Crossing, built: four ways turning in

Option A of `RESEARCH.md` §*The Crossing*, as Marcus chose it on 2 October
2026. Built on the layouts foundation (`tools/layouts/`).

## What was built

**The rule did not change.** A plant still goes to the emptiest quarter of
the oldest plot with a slot of its rank, `<` not `<=`, the rank beside its own
if it must. Re-recorded, the 500 vector rows keep every plot, quarter, index
and nudge they had. Each row gains only its plot's variant and its spot. What
changed is where a slot stands, and the paths.

- **The table**, `tools/layouts/tables/crossing_ways.py`, written to
  `PlaceTable.crossingWays` (Swift) and `CrossingWaysTable` (PHP and the page).
  It holds 24 places, six to a quarter, and the four paths' centre lines,
  `way0` to `way3`.
- **The four paths turn in.** Each comes onto the plot at the middle of its
  side and turns, evenly, 56° by the time it reaches the paving, all four the
  same way. So they meet the round turning rather than crossing, and each
  quarter is a comma of rough grass wrapped round the basin. Each centre line
  wanders 3.5 cm by its own seed, so the four are not one path turned four
  ways.
- **The paths are narrower, and narrow as they turn in**: 0.45 m half width
  where they come onto the plot, 0.35 m at the round
  (`Crossing.pathHalfWidth`, `pathHalfWidthAtRound`). The straight paths were
  0.6, the Long Walk's figure. A path that turns crosses each arc at a slant
  and covers more of it, and at 0.6 the inner arc had no room for three. The
  research's own drawing stood its inner plants on the mown grass of its
  paths, which were 0.47 m either side of the middle; these stand clear of
  it.
- **Six places a quarter, on three arcs round the basin**: three at 1.95 m,
  two at 2.45 m, one at 2.80 m (1.90, 2.42 and 2.95 before), all facing in.
  - Each arc's places span the stretch of it clear of both paths by 0.23 m.
  - The inner arc is listed middle first, then its ends.
  - The middle arc's two stand where they are furthest from the other four and
    from each other.

  Slot 0 is now the middle of the inner arc; 3 and 4 the middle arc; 5 the
  corner. The ambassador still opens quarter 0 at slot 3.
- **Plots vary by number**: four turns and a mirror, eight ways
  (`Crossing.variants`). A mirror sets the four ways turning the other way.
  Plot 0 is the table as drawn.
- **The service sends the turned spot** (`Crossing::spotOn` in `CrossStore`).
  `check_crossing.php` compares each row's variant and spot with the Swift's
  exactly, and measures every plant against the paths as its plot lays them.
- **The page** (`crossing.js`) rebuilds the ground for each plot before its
  plants grow:
  - four mown paths along the table's centre lines, turned for the plot,
    striped across their width and each kept to the plot's own edge;
  - the paving and the basin as built.
- **The workbench draws only the area's own plants** (`pg_cross_arrive`):
  orchids, bells and cushions, as the harness does. Before, every crossing
  came, lilies and reeds among them.

| Measured | |
|---|---|
| Nearest two places | 0.55 m (0.53 m before) |
| Nearest plant to a path's edge, at 500, after its nudge | 0.08 m |
| Plants inside the plot's edge | by 0.3 m at least |

## The fill, against the baseline

`layouts-harness --area crossing --against tools/layouts/baseline.json`:

| Arrivals | Plots | Places held | Held | Settled plots | Held in settled | Empty in settled |
|---|---|---|---|---|---|---|
| 10 | 1 | 11 of 24 | 45.8% | 0 | — | — |
| 100 | 6 | 101 of 144 | 70.1% | 4 | 87.5% | 12 |
| 1,000 | 46 | 1001 of 1104 | 90.7% | 44 | 92.6% | 78 |

**Every figure is the baseline's, unchanged**, as it must be: the rule is the
same, so the same plants land in the same slots. The 78 settled places left
empty are today's rule's (`BASELINE.md`); this layout neither causes nor
fixes them.

## Renders

From `/dev/cross` on a local server, headless, cropped to the plot. The
befores were drawn with the old layout on the area's own plants, so the same
plants stand in both:

- `cross-before-10.jpg`, `cross-after-10.jpg`: plot 0 after ten arrivals, a
  ring round the basin;
- `cross-before-full.jpg`, `cross-after-full.jpg`: plot 3 of 500, full;
- `cross-before-three.jpg`, `cross-after-three.jpg`: plots 4, 5 and 6, laid
  identically before and three ways after.

## What a replant needs

**Nothing for this area beyond deploying.** Capacities are unchanged (24 a
plot), and so is plot assignment: replaying the rule gives every stored
planting the plot, quarter, index and nudge it already has. All 500 vector rows
do. The service works out where a planting stands when it serves it, from its
stored slot and its plot's variant, so **the deploy re-lays every existing
Crossing plot at once, with no row changed**.

## Left open

- **The path width** is a settled figure that changed: 0.6 m all the way
  became 0.45 m narrowing to 0.35 m. The research's picture had about 0.47.
- **The commas read gently** at the page's scale. The mown paths are a little
  lighter than the rough grass either side, as the straight ones were, and
  their turn is clearest in the inner metre.
- The inner arc stands at 1.95 m, not the research's 1.32 m, which stood
  plants on the paths. So ten plants make a ring a little wider than the
  research drew.
