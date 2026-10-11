# The gateways, 10 October 2026

Later the same evening the glyphs on the gateways gave way to miniatures of
each area's own layout: see *The miniatures* at the end, and `minis/`.

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


## The miniatures, later on 10 October

Marcus, on the glyphs on the small plots round the garden section: the mix of
visual languages did not work as he had hoped. He asked for a very simplified
version of each area's actual layout on those slabs instead, so that symbols
and the main view's 3D rendering are not mixed.

So each gateway now shows its area as it is, in the plot's own light and at
the slab's own size: a neighbouring plot seen from further off. The map at
the foot of the page keeps its symbolic glyphs, as decided on 28 September.

### The ones to look at first

- `minis/ten.png`: all ten miniatures side by side, at the gateways' half light.
- `minis/compare-knot-laptop.png`: before above, after below. The Orchard's trees,
  the Seedbed's drills and the Glasshouse's round house beside the Knot Garden.
- `minis/compare-knot-phone.png` and `minis/compare-frame-phone.png`: a phone, before and after.
- `minis/compare-walk-turned.png`: the weakest case, shown so you can judge it. The Long Walk's two
  neighbours show least of themselves: the Coppice beside its yew and the
  Crossing below.
- `minis/cvd.png`: the ten as normal vision, protanopia, deuteranopia and
  tritanopia see them.

Every capture is in `minis/` as `<area>-<view>-<before|after>.png`. The areas
are the Knot Garden, the Cold Frame and the Long Walk, as above, and the
views are `laptop` (1280 × 900), `turned` (a quarter turn clockwise) and
`phone` (390 × 844).

### What each one shows

Each is taken from its area's own plan, never drawn again by hand. The area's
module says its miniature beside its `plan`, from the same plan export and
place table its own page draws from. Plants are left out, and there is no
text.

| Area | On its gateway | Told apart by |
| --- | --- | --- |
| Knot Garden | gravel; the middle ring, four small rings and the edging as low box; the basin | five rings in a softened square |
| Glasshouse | its tiles; the round house, ribs pale on panes the colour of its inside | the dome |
| Cold Frame | gravel; the kidney of water, deep in the middle; two frames with their glazing bars | the kidney |
| Seedbed | tilth; the six drills | curved drills |
| Orchard | meadow; the five trees; the four mown crescents; the dipping pond | five trees |
| Coppice | leaf litter; the glade; the three rides; the spring in its basin | three rides meeting at a glade |
| Crossing | lawn; the four mown ways turning in to the round of paving; the basin | a pinwheel round a ring |
| Quiet Garden | lawn; the four hedges, tall on the far sides; the pool; the bench | a room with a pool |
| Home Ground | trodden paths; the three S-beds of dark soil; the trough | three S-beds |
| Long Walk | turf; the yew, tall on the far side, and the low hedge; the path and its rill; the drifts | a walled walk |

### What changed

- **`mini.js`** lays a miniature from a few kinds of shape: a patch of ground,
  a ribbon along a line, a raised ridge, a round house, a tree and a box. Every
  edge wanders by a seeded noise, so there are no straight lines.
- **Each area's module** says its `miniature` beside its `plan`. A page loads
  only the modules of the areas beside it, once, and the slabs come in whole a
  moment after the plot. The Long Walk's yew and the Quiet Garden's hedges are
  tall on the far side, so those two are laid again for each new turn, and
  kept.
- **The glyph code is gone from the slabs**: its texture, its placement, and
  the cover it was kept clear by. The slabs, their places, the phone's extra
  sky at the sides and the lap below are all unchanged.
- **`check_gateways.mjs`** keeps every direction pin. The glyph checks became
  one check: every open area has a miniature that its own module says.

### Colour blindness

The simulations are Machado (2009) at full severity, in linear sRGB, on the
ten miniatures at the gateways' half light. The figure is how far a
miniature's shapes stand from its own ground in lightness: the median, over
the shapes' pixels, of the difference in CIE L*.

| | normal | protanopia | deuteranopia | tritanopia |
| --- | --- | --- | --- | --- |
| Knot Garden | 7.8 | 7.2 | 8.1 | 7.8 |
| Glasshouse | 4.7 | 4.2 | 5.0 | 4.7 |
| Cold Frame | 16.6 | 16.1 | 16.9 | 16.5 |
| Seedbed | 6.9 | 6.7 | 7.0 | 6.8 |
| Orchard | 4.6 | 4.6 | 4.6 | 4.6 |
| Coppice | 5.0 | 5.0 | 5.0 | 5.0 |
| Crossing | 4.1 | 4.1 | 4.2 | 4.1 |
| Quiet Garden | 6.8 | 7.0 | 6.6 | 6.8 |
| Home Ground | 4.6 | 4.6 | 4.6 | 4.6 |
| Long Walk | 5.0 | 5.0 | 4.9 | 5.0 |

**Every neighbour is recognisable by its form alone.** No simulation moves a
miniature's contrast with its own ground by as much as one L* unit, so
whatever shape a reader with full colour vision sees, a colour-blind reader
sees too. The ten differ by shape, as the table above says.

The contrast is a plot's own and not a symbol's. The pale glyph stood at
7 : 1; these stand 4 to 17 L* off their ground, and the Coppice, the
Crossing, the Home Ground and the Long Walk are the faintest at 4 to 5. The
domes, trees and hedges also stand out against the night.

### Frame time

The frames below are from a phone-sized canvas (390 × 844 at 3×), headless
Chrome on an M4 Max, with main and this branch alternated in one browser.
Each figure is the median of 1,200 draws, each with a one-pixel read so the
GPU's work is counted.

| | main | now |
| --- | --- | --- |
| Knot Garden | 3.2 ms | 0.6 ms |
| Orchard | 3.0 ms | 0.5 ms |
| Long Walk | 2.5 ms | 1.0 ms |
| Crossing | 2.2 ms | 0.6 ms |
| Cold Frame | 2.8 ms | 0.6 ms |

Main searched again for where each glyph would fit on every frame, which was
most of the frame. A miniature is built once and drawn with its slab. It is
520 to 4,131 triangles, the Cold Frame least and the Knot Garden most. A
quarter turn takes what it took on main, within the noise. Nothing drawn
touches the canvas's edge on any of the ten pages, at five window sizes and
four turns.

### Known

- Two miniatures are hidden behind walls, as you decided this evening: the
  Quiet Garden's upper neighbour, behind its yew, and the Glasshouse's,
  behind the house.
- On a phone, at two of the four turns, the Coppice shows only a sliver past
  the Long Walk's yew.
- Below a top-row plot only about 40 cm of the slab's top shows past the rim,
  so all you see of that miniature is its near edge.

### Open question

1. **How bright the gateways are drawn.** `minis/light-knot-laptop.png` shows
   both.
   - **a. Keep them at half light.** Recommended: half light is what says
     *further off*, and every form can still be seen.
   - b. Draw them at 0.7. The faint four, the Coppice, the Crossing, the Home
     Ground and the Long Walk, read more clearly, but the neighbours compete
     more with the plot.


## Miniatures: answered by Marcus, 11 October 2026

The miniatures are drawn at half light, as recommended. He said deploy.
