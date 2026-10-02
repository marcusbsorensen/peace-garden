# The Cold Frame, built: a pond planted as a pond

Option A of `RESEARCH.md` §*The Cold Frame*, as Marcus chose it on 2 October
2026. Built on the layouts foundation (`tools/layouts/`).

## What was built

**The tank became a pond, and kept its thirty-nine places.** Marcus's choice
of 29 September stands: two frames and thirty-nine places of water, so the
water and the glass fill in step. The frames, the glass, the lids and
everything under glass are as they were.

- **The table**, `tools/layouts/tables/cold_frame_pond.py`, written to
  `PlaceTable.coldFramePond` (Swift) and `ColdFramePondTable` (PHP and the
  page). It holds the pond's outline (`pond`), the inner edge of its shelf
  (`shelf`) and thirty-nine places:
  - **the margin**, fifteen places in five clumps of three, on the shelf
    0.26 m in from the edge, each clump a small scalene triangle about 0.26 m
    across. Listed the west clump first, then farthest-first round the pond,
    a clump's three together;
  - **the open water**, twenty-four on a sunflower from the deepest point,
    centre first. A pond of three lilies is three in the middle, never three
    in a row.
- **The pond** is a wandering kidney, 4.6 m by 3.2 m (12.8 m²), its bay toward
  the frames and 0.15 m short of their fronts. The tank was 4.4 m by 3.16 m.
- **The rule** (`ColdFrame.Ways.place`, ported to `ColdFrame::place`): what
  wants water goes in the pond and nothing else does, oldest plot first, as
  before.
  - **A reed** is offered the margin, clump by clump, then the open water from
    its outer edge in, so the middle stays for the lilies.
  - **A lily** is offered the open water from the deepest point out, then the
    margin.

  A plot's water is full before the next plot's is used, as the tank's was.
  `Frame.tank` is now `Frame.pond`, the same raw value, 4.
- **A lily in the pond holds one place**, as it did in the tank. See below.
- **Plots vary by number: mirrored only**, so the plots alternate and the bay
  leans east and west in turn (`ColdFrame.variants`). The frames stay at the
  back; a mirror changes only which of the two a plot fills first.
- **The service sends the mirrored spot** (`ColdFrame::spotOn` in
  `ColdFrameStore`). `check_cold_frame.php` compares each row's variant and
  spot with the Swift's exactly, holds every water plant inside the pond's
  outline, and checks that a reed is out of the margin, or a lily out of the
  open water, only when its own water is full.
- **The page** (`frame.js`) rebuilds the ground for each plot before its
  plants grow:
  - the pond from the table's outline, mirrored, sunk with its bank;
  - a paler band of shallower water over the shelf;
  - the gravel walked round it from the deepest point;
  - the frames as they were.

| Measured on the table | |
|---|---|
| Nearest two lilies' places | 0.53 m (the tank's rows were 0.62 m apart) |
| A lily's place to the nearest reed's | 0.36 m at least |
| A lily's place to the water's edge | 0.24 m at least |
| A reed's place to the water's edge | 0.11 m at least |

At 500, 18 of 150 reeds stood in the open water, and 1 of 192 lilies in the
margin. Drawn young, one stem stood inside a lotus's pads, as before.

## A lotus takes two places — under glass

The brief for this work said "a lotus takes two places, as already decided".
That rule is kept exactly where it was decided, under glass. In the water, a lily holds one
place, as the tank's did since 27 September: the pond's places were laid for a
lily's pads.

The research proposed "about half a metre apart, a little closer than the
tank's diagonal"; the pond's lilies are 0.53 m apart at the nearest. Two
places a lotus in the pond would need about 27 plots at 1,000 arrivals rather
than 18 (360 lilies × 2 + 312 reeds over 39 places). The two frames would then
stand empty in about half the plots, which is what the bigger tank of 29
September was built to stop.

**If Marcus meant two pond places a lotus, that is a change to make on
purpose,** with a larger pond or fewer lilies to a pond. It is not done here.

## The fill, against the baseline

`layouts-harness --area frame --against tools/layouts/baseline.json`:

| Arrivals | Plots | Places held | Held | Settled plots | Held in settled | Empty in settled |
|---|---|---|---|---|---|---|
| 10 | 2 | 11 of 126 | 8.7% | 0 | — | — |
| 100 | 4 | 101 of 252 | 40.1% | 2 | 69.0% | 39 |
| 1,000 | 18 | 1001 of 1134 | 88.3% | 16 | 94.4% | 56 |

**Every figure is the baseline's, unchanged.** Every plant goes to the same
plot as before and every frame fills as before; only which of a pond's
thirty-nine places a water plant takes has changed.

## Renders

From `/dev/frame` on a local server, headless, cropped to the plot (this
workbench has always drawn only the area's own plants):

- `frame-before-10.jpg`, `frame-after-10.jpg`: plot 0 after ten arrivals,
  the lilies gathered in the middle of the pond;
- `frame-before-full.jpg`, `frame-after-full.jpg`: plot 3 of 500, full;
- `frame-before-three.jpg`, `frame-after-three.jpg`: plots 4, 5 and 6, the
  middle one mirrored.

## What a replant needs

**A replant of the water, and nothing else.** Capacities are unchanged: 24
under glass and 39 in the water. So is plot assignment: replaying the 500
vector arrivals keeps every plant's plot, and every plant under glass keeps
its frame, rank and index.

The water's places keep their numbers but not their meaning. Index *n* was the
tank's *n*th place in its rows; it is now the pond's *n*th: the margin for the
first fifteen, the open water after. Of the 500 vector arrivals, only 22 of
the 342 in the water keep their index on replay.

The service works out positions when it serves them. So a deploy alone moves
every water plant into the pond, but onto its old number: reeds in the open
water and lilies in the reed clumps. `tools/replant` re-files them. It needs
nothing new: the slot's fields are still `frame`, `rank`, `index` and `span`.

## Left open

- **The frames are not set askew**, as the research's drawing had them. Askew
  frames would need their places, boxes, lights, glass and the lids that open
  turned with them. The frames are unchanged here, and straight.
- **Five clumps of three.** Reeds are 46% of the water here and the margin 38%
  of its places, so about two reeds a plot spill into the open water. Six
  clumps of three, with twenty-one in the open water, would match the plants
  better; the research's picture had five.
- **The two places a lotus**, above.
