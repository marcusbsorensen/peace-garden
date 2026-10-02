# The Orchard, built: a meadow orchard

Option A of `RESEARCH.md` §*The Orchard*, as Marcus chose it on 2 October 2026.
Built on the layouts foundation (`tools/layouts/`).

## What was built

**The rule did not change.** Five guilds of four, one finished before the next
is begun, a guild's places graded outward from the middle of the plot, the
middle tree's four rankless. Re-recorded, the 500 vector rows keep every plot,
slot and nudge they had; each row only gains its plot's variant and its spot.
What changed is where a slot stands.

- **The table**, `tools/layouts/tables/orchard_meadow.py`, written to
  `PlaceTable.orchardMeadow` (Swift) and `OrchardMeadowTable` (PHP). Three
  feature variants, 20 places each, in fill order.
- **The trees stay on the quincunx, each outer one nudged** by up to 0.08 m a
  way, differently in each feature variant. The outer trunks stand 1.74 m out
  (1.70 before). The middle tree is never nudged.
- **An outer guild is a crescent at its tree's drip line, turned toward the
  middle tree.** Its four places stand 0.90 m from their trunk:
  - the understorey on the line to the middle tree;
  - the two flanks 36° either side of that line, at one distance from the
    middle;
  - the crown at the far horn, 72° round.

  So the ranks still read outward: before the trunks' nudge, the understorey
  stands 1.56 m from the middle of the plot, the flanks 1.81 m and the crown
  2.34 m. The crowns horn toward the two pockets on the plot's z axis, so
  two tall crowns frame each of those, and the two x-axis pockets stay low and
  open for the way.
- **The middle tree keeps its ring of four**, on the diagonals, each facing a
  crescent, 0.75 m from the trunk (the old guild radius). Nearer the trunk the
  canopy's underside comes down to 2.23 m. `OrganicTests` now checks the
  clearance at the nearer of the two radii.
- **Fill so every count looks finished.** The ring fills facing the first
  crescent, then opposite, then the other two. The guilds fill far corner
  (the crescent facing the eye before a turn), near corner, then the two
  sides. At ten plants that is the ring and the far crescent, which is
  composed from the start, and two of the near one.
- **Plots vary by number**: four turns, mirrored, and three feature variants,
  24 in all (`Orchard.variants`, `Orchard::VARIANTS`). Plot 0 is the table as
  drawn.
- **The service sends the turned spot** (`Orchard::spot($plot, …)` in
  `OrchardStore`), and `check_orchard.php` compares each row's variant and
  spot with the Swift's exactly.
- **The page** (`orchard.js`) draws each plot from `pg_orchard_layout(plot)`:
  - the five trunks;
  - a mown crescent along each outer guild's arc, its ends rounded and its
    edges wandering;
  - the middle tree's mown disc;
  - **one mown way** in at one edge, through the middle tree's disc and out at
    the other, stopping on the plot's own edge;
  - the dipping pond (0.64 m now, 0.70 before) in a pocket between two crowns,
    0.81 m or more from every place.

  The ground is rebuilt for each plot before its plants are grown.

Spacings, measured on the table:

| | Variant 0 | Variant 1 | Variant 2 |
|---|---|---|---|
| Nearest two places (neighbours in a crescent) | 0.556 m | 0.556 m | 0.556 m |
| Nearest two places of different guilds | 0.803 m | 0.818 m | 0.815 m |
| Least clearance of the worst rim, before the 0.13 m nudge | 0.191 m | 0.195 m | 0.189 m |
| Way's line to the nearest outer place | 0.75 m | 0.69 m | 0.74 m |

The closest two places were 0.90 m apart in the old squares; a crescent's
neighbours are 0.56 m apart, about the Crossing's 0.53. The nudge stays 0.13 m.
At its worst a place now stays 6 cm inside the plot. Before, a crown in a
corner could stand 12 cm past the worst rim.

## The fill, against the baseline

`layouts-harness --area orchard --against tools/layouts/baseline.json`:

| Arrivals | Plots | Places held | Held | Settled plots | Held in settled | Empty in settled |
|---|---|---|---|---|---|---|
| 10 | 1 | 11 of 20 | 55.0% | 0 | — | — |
| 100 | 6 | 101 of 120 | 84.2% | 4 | 98.8% | 1 |
| 1,000 | 51 | 1001 of 1020 | 98.1% | 49 | 99.9% | 1 |

**Every figure is the baseline's, unchanged**, as it must be: the rule is the
same, so the same plants land in the same slots.

## Renders

From `/dev/orchard` on a local server, headless, cropped to the plot:

- `orchard-before-10.jpg`, `orchard-after-10.jpg`: plot 0 with ten plants;
- `orchard-before-full.jpg`, `orchard-after-full.jpg`: plot 3 of 500, full;
- `orchard-before-three.jpg`, `orchard-after-three.jpg`: plots 4, 5 and 6,
  identical before and three variants after.

## What a replant needs

**Nothing for this area beyond deploying.** Capacities are unchanged (20 a
plot), and so is plot assignment: replaying the rule gives every stored planting
the plot, guild, index and nudge it already has. The service works out where a
planting stands when it serves it, from its stored slot and its plot's variant.
So **the deploy re-lays every existing Orchard plot at once, with no row
changed**, and `tools/replant` would write the same rows it reads. Every plant
moves on the page once, on the day the code goes live. That is the move the
replant was always going to make.

## Left open

- **The near tree still hides part of the middle tree's ring before a turn.**
  The camera looks down from the near corner, and the near tree's canopy stands
  between it and the middle. This was so before. Turning the plot shows the
  ring.
- The pond fell in the z+ pocket in all three feature variants. Turns and
  mirrors put it in every pocket across plots, but a variant with the pond in
  the other pocket would add variety.
- The mown way always crosses the plot on the table's x axis, through the open
  pockets; the turns put it on either axis.
