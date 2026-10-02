# The Knot Garden, built: interlaced rings

Option A of `RESEARCH.md` §*The Knot Garden*, as Marcus chose it on 2 October
2026. Built on the layouts foundation (`tools/layouts/`). Laid one way in every
plot, as decided.

## What was built

**The rule did not change.** Colour picks the pair, height picks the place, a
pair's two compartments fill together, nothing reserved. The eight
compartments keep their numbers: the four sides are now the four lenses, the
four corners the four crescents, and the pairs are the opposite ones, as
before. Re-recorded, the 500 vector rows keep every plot, compartment, index
and nudge they had; each row only gains its variant (always plain) and its
spot.

- **The knot**: a ring round the middle (radius 1.48 m) and four small rings
  (0.94 m) woven through it, each crossing it twice, inside a squircle
  edging (half side 2.25 m). Every line strays off its true curve by up to a
  centimetre, so it is formal but hand-laid; nothing is straight.
- **The small rings stand on the diagonals, not on the axes as the
  research's sketch drew them.** Measured, not chosen: on the axes a small
  ring can be no bigger than 0.74 m before it meets its neighbour or the
  edging, and a lens then holds its four plants 0.22 m apart. On the
  diagonals the rings reach into the square's corners, and the lens holds
  them 0.42 m apart, with the 9 cm nudge kept. The picture is the sketch's
  turned an eighth.
- **The table**, `tools/layouts/tables/knot_garden_rings.py`, written to
  `PlaceTable.knotGardenRings` (Swift), `KnotGardenRingsTable` (PHP) and
  `tables/knot_garden_rings.js`. Its 32 places are compartment by
  compartment, the north-east lens and crescent turned by whole quarters, so
  a pair's places are exactly opposite. Its curves are the five rings, the
  edging, and the eight crossings in order round the middle ring.
- **Each compartment is still graded outward**, heart nearest the basin,
  point farthest out, the two sides between at one distance (from the
  middle of the plot):

  | | Heart | Sides | Point |
  |---|---|---|---|
  | Lens | 0.81 m | 1.17 m, 1.05 m apart | 1.22 m |
  | Crescent | 1.74 m | 1.78 m, 1.30 m apart | 2.16 m |

- **The weave.** Going round the middle ring it is over, under, over,
  under, so each small ring is over at one of its two crossings and under at
  the other. An under-band stops 4 cm inside the over-band's face; the
  over-band swells there (2.75 cm thicker each side, 5.5 cm taller, easing
  out over 0.29 m).
- **Fill so every count looks finished**: the lenses are claimed first, and
  they close round the basin, so the first two colours in a plot are four
  ribbons round its heart; the crescents come after.
- **The page** (`knot.js`) sweeps a run of box along each line with the
  section `Organic.hedge` uses, cut where it dives under and swollen where it
  rides over (`knotRuns`), casting its shadow as before. The basin is as it
  was.
- **The service** sends `KnotGarden::spotOf($plot, …)`, the table's place
  plus the nudge, and `check_knot.php` compares each row's variant and spot
  exactly, checks every planted spot is inside its lens or crescent, and
  clear of the box.

Measured on the table (`KnotGardenTests`, and the spec refuses to write a
table that fails them): closest two places 0.42 m (0.56 before); a plant
pushed as hard as its seed can push it stands at least 3 cm clear of the box,
the swellings counted; two small rings 4 cm apart where they come nearest,
and a small ring 4 cm from the edging; the basin has 15 cm round it; the
edging's outer face 2.34 m out at most, inside the 2.38 m the slab's edge can
come to (2.41 m on this slab).

## Measured on real plants

`swift run -c release --package-path tools/layouts/harness layouts-harness
--area knot --against tools/layouts/baseline.json`: **no figure moved.**

| Arrivals | Plots | Held | Settled plots | Held in settled | Empty in settled |
|---|---|---|---|---|---|
| 10 | 1 | 11 of 32, 34.4% | 0 | — | — |
| 100 | 5 | 101 of 160, 63.1% | 3 | 83.3% | 16 |
| 1000 | 33 | 1001 of 1056, 94.8% | 31 | 99.1% | 9 |

The same as the baseline at every count, as it must be: the rule and its
slots are unchanged.

## What a replant needs

**Nothing.** Capacities and plot assignment are unchanged, and the service
works out each planting's spot when it serves it, from the slot and nudge it
stores (`KnotStore::planting`), so a deploy re-lays every existing plot by
itself. A replant would put every plant back in the slot it already holds.

## Left open

- **Diagonals or axes.** If Marcus wants the rings on the axes as sketched,
  it is the spec's one turn, at the price above: lens places 0.22 m apart,
  or the nudge cut to 5 cm for 0.32 m.
- **The map's glyph** for `pattern` (`gates.js`) still draws the old weave.
  Not touched: it is shared.
- `docs/WEB-GARDENS.md` §*The Knot Garden, built* describes the weave of
  bands and the sides and corners; these notes are for folding in.

Renders: `knot-before-10.jpg`, `knot-after-10.jpg` (plot 0, ten plants),
`knot-before-full.jpg`, `knot-after-full.jpg` (plot 3 of 500 arrivals), and
`knot-before-three.jpg`, `knot-after-three.jpg` (plots 3, 4 and 5: laid the
same way, as a fixed area is).
