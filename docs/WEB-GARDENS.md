# The web gardens and the Wild Fields

Asked for 18 September 2026, after the app's Garden screen became a place: a
floating isometric plot, a chosen ground, the sun and moon going round it, lights
to put out, and glow-in-the-dark figures (`ARRANGING.md`). This is the same
direction for the shared garden on the website, which **we curate**, and for the
Wild Fields, which nobody does.

Nothing here is built. The website cannot yet draw a plant (§*What has to exist
first*), and until it can, every decision below is a design and not a garden.

## What was settled

Settled by Marcus, 18 September:

1. **Curating means designing the rules, not placing the plants.** For each of
   the ten areas we design a layout from the real practice of that kind of
   garden, and an arriving plant takes its place by the rule. We place by hand
   only what we choose to show off. This still works at ten thousand plants.
   Placing every plant would not: a queue of arrivals never ends.
2. **An area is many plots**, each the app's own floating square, each one bed
   laid out by the area's rule. One growing plot per area would be unreadable at
   any zoom once it held a thousand plants.
3. **The Wild Fields are uncurated, on purpose.** The gardens are what we look
   after; the wild is what nobody arranges.

## What this reverses

`WEBSITE.md` §*Walking it* settled on 3 September that **a plant's place comes
from its seed and never moves**: each area a 256 × 256 grid, a plant's cell two
slices of its seed hex, collisions allowed. Curating by rule replaces the first
half of that and keeps the second.

- **Kept: a plant never moves.** That was the point of deriving a place: a place
  somebody visited yesterday is still theirs today. It holds here too, and for
  the same reason.
- **Replaced: where it goes comes from the bed, not from the hash.** The seed
  cannot know which bed has room, or whether a tall plant belongs at the back
  of it. So a plant's place is **assigned once, on arrival, and stored**, and
  from then on it is as fixed as a derived one.

What made sorting wrong was that inserting one plant reshuffled everything after
it. Assigning a slot on arrival appends and never reshuffles, so the objection
does not apply. The cost is that a place can no longer be worked out in a
browser from the seed alone: the plot service has to say where a plant stands.
It already has to say which plants exist, so this is one more column, not a new
dependency.

## An area is a map of plots

Each area is a map of floating plots on the app's own projection: 5.2 m squares,
isometric, floating over the same sky. You walk the map, and come down onto a
plot. A plot is what the app's Garden screen is, so everything the app settled
carries over: the ground, the orbit, the shadows, the lights, the zoom.

- **A plot is a bed.** It has a template: slots, each with a role (back of the
  border, a specimen, a row in a drill), a spacing, and fixed structures (a
  hedge line, a frame, a bench, a path).
- **A plot fills, then the next one opens.** An arriving plant takes the first
  open slot whose role fits it (§*Slots and roles*). When no slot in the
  area's newest plot fits, it goes to the next plot, which is opened on the
  map in the area's own order: along the walk, round the crossing, out from
  the orchard's first tree.
- **A plot is never re-laid.** Changing an area's template changes the plots
  opened after the change, never the ones already planted. A curator who wants
  an old bed to look different is asking to move plants, and plants do not move.
- **The map is fixed as each plot opens.** The map of an area grows at its edge;
  what is already there stays where it is.

### Slots and roles

A template says what goes where in terms a plant can answer from its genome,
without anybody looking at it:

| Role | Answered from |
| --- | --- |
| **Height class** — edge, middle, back | Mature height, from `PlantSceneBuilder.matureBounds`. The same number `GardenSprites` frames a plant by. |
| **Habit** — the plant's form | `Genome`'s archetype, and its spread against its height. |
| **Colour** — the flower's hue family | The palette, the way the app's *Colours* arrangement already reads it. |

There is no season to lay out by. A plant's bloom follows the day
(`diurnalFactor`), not the year, so the border books' rule of a succession of
flowering through the summer has nothing to act on.

**Best practice is mostly a rule about height and repetition.** Tall at the back,
low at the edge, and the same colour repeated so the eye travels: every border
book says it and every template below is a version of it. A plant that fits no
open slot in the newest plot takes the nearest slot that fits in the next one,
not a wrong slot in this one. A gap in a bed is a gap a later plant will fill;
a tall plant at the front is there for good.

## The ten areas, and what each is laid out as

Each area already has a name and a theme (`WEBSITE.md`, `strings.js`), and each
name is a real kind of garden with a real way of being laid out. The layout is
the one that kind of garden has always had, which is the whole of what
"best practice" means here: a knot garden laid out like a knot garden, not like
a border with a knot garden's name.

| Area | Theme | How it is laid out | Ground | Structures |
| --- | --- | --- | --- | --- |
| **The Cold Frame** | waiting | Low glazed frames in rows, plants in tight ranks inside them, hardening off. Small plants only: the young stages of what grows elsewhere. | Flat, gravel between | Frames, lids propped open by day and shut at night |
| **The Home Ground** | ground | The kitchen garden: rectangular beds 1.2 m wide, so no soil is ever stood on, paths between, crops in rows across each bed. | Flat, dark soil | Bed edging, paths |
| **The Seedbed** | beginnings | Straight parallel drills, a label at the end of each row. One plant repeated along a drill, not mixed. | Fine tilth, flat | Row labels |
| **The Coppice** | renewal | Stools in blocks, each block cut in its year of the rotation, so every stage stands at once, from cut stumps to full poles. Woodland flowers in the light between. | Woodland floor, gentle relief | Stools, the cut and the uncut |
| **The Long Walk** | travel | A double border either side of a path: tall at the back, graded to the front, drifts of three and five, the same colour repeated down its length for rhythm. The walk goes on; plots open end to end. | Level, a mown path | The path, a hedge behind each border |
| **The Quiet Garden** | peace | An enclosure: hedged, one tree, one bench, and more lawn than planting. **The fewest plants per plot of any area, by rule.** Room is what it is for. | Lawn | A hedge round, a bench |
| **The Orchard** | kinship | Trees on a quincunx, meadow beneath, plants grouped round each tree as its guild. The shrubs and flowers under a tree are chosen to go with it. | Meadow | Tree positions |
| **The Knot Garden** | pattern | Low clipped hedging in an interlaced geometric pattern, each compartment filled with one colour. Symmetrical: a plant's slot has a mirror, and a compartment fills with one colour family. | Flat, gravel | The hedging pattern |
| **The Glasshouse** | light | Staging along the sides, pots on it, a central aisle. Tender plants, set close to the glass for the light. | Floor tiles | The benches, the glass |
| **The Crossing** | meeting | Four paths meeting at a centre, four quarters, one feature where they cross: the quadripartite garden, one of the oldest plans there is for a meeting place. Plants face the centre. | Level | The paths, the centre |

Three things follow from the table:

- **Two areas are neighbours because the two themes are** (`WEBSITE.md`), and
  now the layouts neighbour too. The Cold Frame stands above the Quiet Garden:
  a frame of plants waiting and an enclosure for sitting still, the same
  stillness at two scales. That was never designed; it came out of the themes.
- **The Quiet Garden is the one area where the rule is fewer.** Every other
  template asks how to fit plants in well; this one asks how few a plot can
  hold and still be a garden. It will open more plots than any other area for
  the same number of plants, and that is right.
- **Ten ambassadors, one per area** (`WEBSITE.md` §*The ambassador plants*),
  stand in each area's first plot, in the slot the template marks as the
  specimen: the one place in every area that is hand-placed from the start.

### Structures need drawing properly

A hedge, a glazed frame, a bench, staging, a path edge. None of them exist in
the app, which has ground, plants, lamps and figures and nothing built. They
carry the look of each area, and **they meet the same test the figures did**: a
hedge drawn as a green rectangle is clip art beside plants grown from a genome.
So they are modelled and lit the way the figures are, by the garden's own light
at its hour, and drawn once per turn of the plot. They are also **unnamed**, as
the worlds and the lights are: a named structure is forty-two translations.

## The Long Walk, built

The rule is in `SeedCore` (`WebGardens/LongWalk.swift`), where the plot service,
the website and the app can all read it. Built 18 September, with
`LongWalkTests`.

- **The plot:** a 1.2 m mown path down the middle, a border each side, a hedge
  from 2.3 m out. Three tiers each side, with five front slots, four middle and
  three back, so 24 plants a plot. The tiers have different spacings, so their
  rows stagger by themselves.
- **Tiers from measurement.** Across 300 crossings of 300 different pairs of
  parents, grown heights run 0.21 to 2.22 m, with thirds at 0.85 and 1.19 m. The
  cuts are at 0.93 m and 1.28 m instead, to match the number of slots in each
  tier. Crossings of one person with forty others ran taller and were half
  bells, so a sample from one gardener is the wrong sample.
- **The rule is that nothing stands in front of something shorter**, not
  "tall ones in the back row". A plant goes to its own tier in the oldest plot
  with room, or else the tier beside it where the heights around it still
  order, or else a new plot. **The test found why.** Filling by row alone, a
  few more tall plants than back slots left eleven of fifteen plots holding
  six to nine plants. Now every plot but the newest three is full.
- **Drifts of colour, capped at five**, then the same colour starts again
  further down the walk. Every plant is unique, so a border here cannot repeat
  a plant; it repeats a colour.
- **A developer preview**: `-pgPlotSide 5.2` fixes the app's plot at a web
  plot's size, so a Long Walk plot can be looked at in the app's own renderer
  before the website can draw one.

**What looking found:** without the path and the hedges, a Long Walk plot is a
scatter of plants on grass. The rule is right and invisible. The structures are
not dressing; they are how a visitor can see the rule.

**The structures, built the same day** (`GardenStructures.swift`, shown by
`-pgArea longWalk`):

- **The hedges: tall yew behind the far border and low in front of the near
  one**, decided by the view, so they swap as the plot turns. Settled by Marcus.
  Looking down from one side, a 2 m hedge on the near side hid the whole border
  behind it. It isn't how a real garden is built; it is how this one is best
  seen.
- **A hedge is modelled as a clipped box** with a leaf-grain texture, which is
  what a clipped yew is. It is drawn in 0.4 m pieces, each sorted by its own
  depth, because one picture cannot be in front of some plants and behind
  others. The pieces are square-ended: with rounded shoulders, every joint drew
  a seam and the hedge came out as a row of posts.
- **A hedge's shadow is one shape on the ground**: its footprint, moved away
  from the light by its height over the light's slope. Sheared per piece like a
  plant's shadow, near noon each piece cast a hairline across the garden.
- **The path is mown in stripes along its length**, as a mower goes. Striped
  across, it read as paving slabs.
- **A hedge is cut to one top line.** Each piece stands on its own ground and
  is as tall as it takes to reach the hedge's mean ground plus its height.
  Standing each piece at the hedge's height from its own ground stepped the
  top at every joint.
- **Yew is picked brighter than yew**, the rule the bank of earth under the plot
  already follows: a vertical face gets the sky and little of the sun, and at
  yew's own darkness the face towards the path was black at midday. Brighter
  alone made it toy-green in the sun, so it is also greyed towards blue.

## The dressing: what we place by hand

The rules place the plants. What we choose by hand is everything else, per plot:

- **Its ground**, from the app's eight worlds, or new ones made for the areas
  (the Glasshouse has no world yet, and needs a floor).
- **Its lights and figures**: a lantern at the Crossing's centre, fireflies in
  the Orchard's grass, a glow-in-the-dark hare in the Quiet Garden. They are
  `Bed.lamps`, stored as strings, so a web garden can hold a figure the app has
  not heard of.
- **Its specimen**, where the template marks one.
- **Its turn**: which corner faces the visitor when they come down onto it.

Dressing never touches a plant. It can be changed at any time, because nothing
anybody visited depends on where a lantern stood.

## Curating it: the tool

A private page, for us alone:

- **Templates, per area.** Slots, roles, spacing, structures, drawn on a live
  plot with real plants dropped into it to see how it fills. Versioned: a new
  version applies to plots opened after it.
- **A preview that fills.** Run an area's template forward over the next five
  hundred plants that *would* arrive (minted seeds, the way the ambassadors
  were found) and look at the plots it makes. This is how a template is judged
  before it is live, and it is the web's version of what the app learned the
  hard way: **the meadow hides terrain faults** and a garden of fourteen
  hides layout faults. Judge a template at five hundred.
- **Dressing, per plot**, as above.
- **Reports**: hide a plant, suspend a plot, reset a name. `WEBSITE.md`
  §*Moderation* already has these; the tool is where they are done.

## The Wild Fields

The opposite of the gardens, and it should look like it.

- **Unarranged.** A released plant's place comes from its seed, the way the
  garden's did before this document: the old rule was right for the wild. No
  slots, no roles, no templates, no curator.
- **One landscape, not plots.** The gardens float, because a made garden has an
  edge and somebody's work inside it. The wild does not have an edge. It is one
  continuous ground running on past the screen, walked by panning rather than
  by a map, and the relief is a landscape's rather than a bed's.
- **No names, no senders, no dates** (`PHASES.md`), and so nothing on it to tap
  but the plant itself.
- **No lamps.** Nobody put anything out. At night it is lit by the Milky Way,
  and by fireflies that are simply there, which is the one light the wild has
  of its own.
- **A plant stands where it stands.** Collisions are allowed and drawn, as they
  were in the old garden: two released plants in one place are two plants
  growing together, which is a thing a field does.

### Paths that visitors wear

Proposed by Marcus, 18 September: **paths through the Wild Fields grow more
marked the more visitors take a route, and fade as fewer do**, the way a path
through a wild place stays only while people keep walking it and is otherwise
taken back.

It is the right shape for the wild. Nobody curates it, and yet it is not
featureless: its only paths are made by everybody walking, and nobody made any
one of them. A desire line is the one thing in a landscape that is authored by a
crowd.

- **Wear, per ground cell, that decays.** Each cell crossed adds a little wear;
  every cell loses a fixed fraction a day. A half-life of about a month means a
  route walked all summer is a clear path in autumn, and one abandoned in autumn
  is grass again by spring. Drawn as the ground's own colour trodden paler and
  flatter, never as a line on top: a path is where the grass gave up, not
  something laid.
- **Walking is moving, not looking.** Wear comes from the view crossing ground
  while a visitor pans, not from where it rests. Somebody standing to look at a
  plant wears nothing, which is also true of grass.
- **Capped per cell per day**, so one visitor panning back and forth, or a
  script, cannot carve a road. A path is many people, or it is nothing.

**This is the first thing on the site that learns where people go**, and
`WEBSITE.md` says the site has no analytics. The wear can be made to hold
nothing about anyone: the browser sends only which cells were crossed, in
batches, with no cookie, no identifier and no address logged, and the service
keeps a number per cell and nothing else. That is aggregate footfall and not
tracking. **Accepted by Marcus, 18 September, on exactly those terms**: counts
per cell and nothing else, and the privacy page says so before it runs.

### What has to be fixed before it opens

- **`/wild` describes the wrong thing.** Its `wildBody` string describes a seed
  waiting for somebody else, which is *The Winds* and is the opposite of
  release. It has to be rewritten before the page means anything.
- **The privacy page** has to be rewritten first, as `/wild`'s own comment says.
- **Release uploads nothing yet.** `PlantDetailView.release()` animates and
  deletes. Releasing to a place needs the plot service.

## What has to exist first

In order, because each needs the one before:

1. **A plant drawn in a browser.** `WEBSITE.md` §*What renders the plant* settled on
   `SeedCore` compiled to WebAssembly, feeding WebGL, with a CI-checked JavaScript
   port as the fallback, and no third copy of the geometry. The size of the wasm
   is the open question there. Nothing on the web can be judged until this runs.
2. **A plot drawn in a browser.** The ground is 2D arithmetic (`GardenTerrain`
   draws paths into a context) and ports to a canvas directly; the worlds atlas
   is already a file. The sky and orbit are formulas. The plants and figures
   are the WebGL above. Whether a plot is one WebGL scene or sprites laid on a
   canvas the way the app does it is a decision for when (1) runs.
3. **One area's template**, built and judged at five hundred plants. The Long
   Walk is the best first one: its rule is the plainest best practice there is
   (tall at the back, drifts, repetition), and its plots open end to end, so
   the map is a line before it has to be a shape.
4. **The plot service's slot assignment**, append-only.
5. **The structures**, modelled, per area as each area is built.
6. **The curator's tool.**
7. **The Wild Fields**, once release uploads something.

## Open questions

- **Whether the app's Thematic arrangement should use these templates.**
  `ARRANGING.md` has the app's Thematic arrangement reuse the site's ten areas,
  so a plant stands in the Crossing in both. If the Crossing is laid out as a
  quadripartite garden on the web, whether a person's own Crossing is laid out
  the same way in the app is a choice. Doing it would mean the templates live in
  `SeedCore`, where both can read them.
- **Whether plots in an area can be walked between**, or only reached from the
  map. The app's pan stops at the plot's edge.
- **Whether a released plant can be found again** by whoever released it
  (`PHASES.md`, still open). The Wild Fields work either way.
- **How the Coppice shows its rotation.** A coupe cut this year and a coupe
  uncut for seven are both true at once; whether a plot's stage is fixed when it
  opens or turns with the real year is a question about what renewal means here.
- **Whether a plot can be too empty to open.** The Quiet Garden's rule makes a
  plot with three plants correct; a Long Walk plot with three plants is
  unfinished. Opening a plot only when the last is full says nothing about the
  first days of an area, when every area is empty.
