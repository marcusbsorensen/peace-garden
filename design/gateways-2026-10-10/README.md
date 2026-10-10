# The gateways, 10 October 2026

Marcus, on the small slabs at the edges of an area's view that stand for the
neighbouring areas: they "don't appear to be positioned as per the mini map",
and the brown, terracotta and green they are told apart by are no use to a
colour-blind reader. These are the renders from before and after, headless
Chrome on the dev server, for three areas with different neighbours:

- **the Knot Garden**: neighbours above, left and right;
- **the Cold Frame**: right and below, from the corner of the map;
- **the Long Walk**: left and below, three plots long, behind a yew.

## The three to look at first

- `compare-knot-desktop.png`: before above, after below, each with its own page's map beside it.
- `compare-frame-phone.png`: a phone, before and after.
- `agree-knot.png`: the map and the view side by side. Top row is English, after. The middle row is Arabic before: the map is mirrored, so the Glasshouse sits left of the Knot Garden there and right of it in the view. The bottom row is Arabic after: the two agree.

Every capture is here as `<area>-<view>-<before|after>.png`, where the view is
`desktop` (1280 × 900), `turned` (a quarter turn clockwise), `phone`
(390 × 844) or `night` (23:30 in London). The area pages draw the night sky at
every hour, so day and night differ only in the stars. `compare-*-desktop.png`
pairs each area, and `cvd-knot.png` is the Knot Garden after, as each kind of
colour vision sees it.

## What was wrong

**The map and the gateways each kept their own idea of which way a direction
lies, and under Arabic or Hebrew the two ideas differed.** The map at the foot of
an area page is a CSS grid. A grid's columns follow the writing direction, so in
a right-to-left language the map mirrored. The gateways and the pad's arrows did
not mirror: the Orchard was drawn right of the Knot Garden in the map, left of it
in the view, and Left went to it. The hub's map had the same fault against its
own arrow keys.

**In English the two agreed on direction, at every turn, and could not say
which area was which.** Each slab was told from the others only by its colour.
Drawn at half its light against the night, the browns, the terracotta and the
greens come out almost the same dark olive. On the Knot Garden's page, the
three slabs measure (42, 46, 31), (47, 39, 31) and (59, 41, 31). An eye matching
those to the map's cells by colour pairs them wrongly, and the slab then seems to
be in the wrong place.

What was not wrong:

- **The adjacency.** Both halves already asked `garden.js` for the neighbours.
- **The camera's turn.** A turn moves the camera, not the garden. The pad, the
  gateways and the map all keep the screen's directions, so the east neighbour
  stays on the right at every turn, where the map shows it. The check holds this
  at all four turns.
- **The plot variant.** Nothing applies a plot's turn or mirror to the
  directions, and nothing should: a variant turns a plot's own layout, not the
  map.

## What changed

- **One way round.** `screenWay` in `garden.js` is now the only place that says
  which way a direction lies on the screen. The map's cells (`mapCells` in
  `gates.js`) and the gateways (`areasBeside`, `placeBeside`) both read it. Both
  map grids, the minimap and the hub, are pinned left to right. The names on the
  hub's cards still run in the reader's direction.
- **Each gateway carries its area's glyph.** It is the same drawing as that
  area's cell on the map, laid flat on the slab's top and foreshortened by the
  camera as the ground is. It stays upright on the screen at every turn.
  - It is pale, with a faint ring of shade, and as large as fits up to 1.15 m.
  - It sits on the part of the slab the plot doesn't hide, clear of the plot's
    hedges, trees and frames, and inside the slab's own wandering edge.
  - It isn't drawn below 18 px.
  - The slabs and their places are unchanged, and no words were added.
- **A phone keeps a metre of sky at each side**, so the side gateways have room
  for their glyphs. On a phone the plot draws about 6% smaller. Nothing changes
  on a laptop.
- **The slab below laps 1.25 m instead of 1.7 where there is room.** That shows
  its glyph on a phone and on the Long Walk.
- **The map's own glyphs took the same faint ring.** White on the two gravel
  cells, the Knot Garden's and the Cold Frame's, was only 3 : 1.
- **A check.** `tools/reference/check_gateways.mjs` is in CI. For all ten areas
  it pins each neighbour and its direction, and holds three things to them:
  `garden.js`, the map's cells, and the gateways' placement at four turns on a
  phone, two laptops and a tablet. It also checks that the stylesheet pins both
  grids. It fails against the old code.

## Colour blindness

The simulations use Machado (2009) at full severity, in linear sRGB.

| | glyph against its slab, worst of the ten | pairs of different slab colours under ΔE 10 (of 43) | closest pair |
| --- | --- | --- | --- |
| normal | 7.4 : 1 | 15 | Quiet Garden / Crossing, 1.4 |
| protanopia | 7.4 : 1 | 34 | Glasshouse / Crossing, 1.0 |
| deuteranopia | 7.3 : 1 | 31 | Quiet Garden / Crossing, 1.4 |
| tritanopia | 7.4 : 1 | 14 | Quiet Garden / Crossing, 1.4 |

Measured from the Knot Garden render, each glyph stands at 10.2 to 11.1 : 1
against its slab under all four. Colour alone can't carry identity at half
light, even for normal vision. Shape now carries it at 7 : 1 or better, which is
more than double the 3 : 1 that WCAG asks of a graphic.

## Known

Three glyphs stay hidden because their slabs are hidden:

- the Quiet Garden's upper neighbour, behind its yew (you kept that on 27 September);
- the Glasshouse's upper neighbour, behind the house's ribs;
- on a phone, at two of the four turns, the Coppice past the Long Walk's yew.

## Open questions

1. **The glyph below the four top-row plots** (Cold Frame, Home Ground, Seedbed,
   Coppice) is about 20 px on a laptop and is left out of an 800 px window. Only
   40 cm of that slab's top shows past the plot's rim.
   - **a. Leave it.** Recommended: the map at the foot shows the glyph full size.
   - b. Add 15 cm of sky under every plot. Every plot draws about 1.5% smaller on
     a laptop, and that glyph comes out about 40% larger.
2. **The phone's extra sky at the sides.**
   - **a. Keep it, plots about 6% smaller on a phone.** Recommended.
   - b. Drop it. The plot keeps its size, and the side gateways show no glyph on a
     phone.
3. **Both maps are now left to right in Arabic and Hebrew**, as the pad, the
   glyphs and the gateways already were.
   - **a. Keep.** Recommended.
   - b. Mirror all of them together instead.
4. **The two hidden upper neighbours**, behind the Quiet Garden's yew and the
   Glasshouse.
   - **a. Leave them hidden.** Recommended.
   - b. Lift those two gateways clear above the wall, as ground seen over it.


## Answered by Marcus, 10 October 2026

All four as recommended, so everything stays as built:
- the phone's extra side sky is kept;
- no sky is added under the plots;
- both maps read left to right in Arabic and Hebrew;
- the two neighbours behind walls stay hidden.
