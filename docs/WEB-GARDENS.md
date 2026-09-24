# The web gardens and the Wild Fields

Asked for 18 September 2026, after the app's Garden screen became a place: a
floating isometric plot, a chosen ground, the sun and moon going round it, lights
to put out, and glow-in-the-dark figures (`ARRANGING.md`). This is the same
direction for the shared garden on the website, which **we curate**, and for the
Wild Fields, which nobody does.

Nothing here is built. The website cannot yet draw a plant (§*What has to exist
first*), and until it can, every decision below is a design and not a garden.

## The plants' shapes changed, 24 September 2026

Every plant was narrow and tall, and Marcus chose to change their shape
everywhere (`docs/PLANT-FORMS.md` §*Habit*, §*What holds a flower from
beneath*, §*A petal's outline*). The garden came down and out: over three
thousand crossings the median height is 0.87 m and the median spread 0.62 m
(measured over six thousand plants before, 1.00 and 0.45), and three plants in
ten are wider than they are tall. A lotus is a water lily 0.34 m tall, a succulent a rosette of 0.28. **Every measured number below was measured again the way it
was first measured, and changed where it changed**, so the cuts, fills and
margins in this document are the new shapes'. Names, areas, hues, colour
families, kinds and habits did not move; only heights did.

- **The cuts:** Long Walk 0.93/1.28 → 0.77/1.20, Quiet Garden 1.13 → 1.09,
  Crossing 0.97/1.43 → 0.91/1.30, Orchard 0.75/1.30 → 0.58/1.20 (the Knot
  Garden's with it), Cold Frame 0.85 → 0.38, Coppice 1.10 → 1.00, and the
  Glasshouse border its own again at 1.14 rather than the Orchard's.
- **The four cuts over all crossings were measured on one sample of three
  hundred** where each area had drawn its own, so the Orchard's crown and the
  walk's back cut, both the tallest quarter, are now one number.
- **The live garden is replanted** when the shapes go live: every stored seed
  grown again, every area's arrivals placed again in order (`tools/replant`).
- Where a design section below records what a simulation found before the
  shapes changed and nothing re-ran it, it says so.

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
| **The Cold Frame** | waiting | Four low glazed frames, two ranks of six young plants in each, hardening off. **Every plant drawn young** — the young stages of what grows elsewhere — and nobody turned away. **Forty-eight a plot; colour claims a frame and the height a plant will grow to orders its ranks**, tallest-to-be at the back under the high side of the glass. | Flat, gravel between, soil inside the frames | Frames of boards, their lights propped open by day |
| **The Home Ground** | ground | The kitchen garden: rectangular beds 1.2 m wide, so no soil is ever stood on, paths between, crops in rows across each bed. | Flat, dark soil | Bed edging, paths |
| **The Seedbed** | beginnings | Straight parallel drills, a label at the end of each row. One plant repeated along a drill, not mixed. | Fine tilth, flat | Row labels |
| **The Coppice** | renewal | Stools in blocks, each block cut in its year of the rotation, so every stage stands at once, from cut stumps to full poles. Woodland flowers in the light between. | Woodland floor, gentle relief | Stools, the cut and the uncut |
| **The Long Walk** | travel | A double border either side of a path: tall at the back, graded to the front, drifts of three and five, the same colour repeated down its length for rhythm. The walk goes on; plots open end to end. | Level, a mown path | The path, a hedge behind each border |
| **The Quiet Garden** | peace | An enclosure: hedged, one tree, one bench, and more lawn than planting. **The fewest plants per plot of any area, by rule.** Room is what it is for. | Lawn | A hedge round, a bench |
| **The Orchard** | kinship | Five trees on a quincunx, meadow beneath, and a guild of four under each. **Twenty a plot, and an arrival goes under the earliest tree with a place left**, so trees are dressed one at a time rather than five at once. The first area whose tallest thing is not something anybody grew. | Meadow, mown into a disc under each tree | The five trees |
| **The Knot Garden** | pattern | Low clipped hedging, curving, woven over and under itself inside a square edging, and eight compartments — four at the sides, four at the corners — each filled with one colour. **Thirty-two a plot, and a plant's colour decides which pair of opposite compartments it stands in**, its height where in the block. The first area whose rule reads anything but a height. | Flat, gravel | The woven hedging and its edging |
| **The Glasshouse** | light | Staging along the sides, pots on it, a central aisle. Tender plants, set close to the glass for the light. | Floor tiles | The benches, the glass |
| **The Crossing** | meeting | Four paths meeting at a centre, four quarters, one feature where they cross: the quadripartite garden, one of the oldest plans there is for a meeting place. Plants face the centre. **Twenty-four a plot, and an arrival goes wherever there is least**, so the four quarters grow together. | Grass, with two paths mown through it | The paths, a round of paving where they cross |

Three things follow from the table:

- **Two areas are neighbours because the two themes are** (`WEBSITE.md`), and
  now the layouts neighbour too. The Cold Frame stands above the Quiet Garden:
  a frame of plants waiting and an enclosure for sitting still, the same
  stillness at two scales. That was never designed; it came out of the themes.
- **The Quiet Garden is the one area where the rule is fewer.** Every other
  template asks how to fit plants in well; this one asks how few a plot can
  hold and still be a garden. It opens more plots than any other area for the
  same number of plants, and that is right: measured at five hundred, fifty-one
  plots against the Long Walk's eleven. **Built 21 September** — §*The Quiet
  Garden, built*.
- **Ten ambassadors, one per area** (`WEBSITE.md` §*The ambassador plants*),
  stand in each area's first plot. **The ten seeds exist, 20 September**
  (`SeedCore/WebGardens/Ambassadors.swift`), and **the Long Walk's is standing
  in it**, the same day — see §*The ambassador, standing*, which also answers
  what a specimen slot is for an area whose plots never reach an end. The other
  nine wait on their areas' rules.

### Structures need drawing properly

A hedge, a glazed frame, a bench, staging, a path edge. **Seven of them exist
now** — the row label for the Seedbed and the glazed frame for the Cold Frame
since this paragraph was first written. The first two were built for the Long Walk and are in the app and the
browser: a hedge (`GardenStructures.swift` — `HedgeLine`, `HedgePiece`,
`HedgeShadow`) and a mown path (`MownPath`), ported to `longwalk.js`. Then
`Organic.bench` for the Quiet Garden, `Organic.roundel` for the Crossing's
paving and `Organic.tree` for the Orchard. **The Knot Garden needed none**: its
woven bands and its edging are `Organic.hedge` at ankle height, which is the
first area built without a structure of its own and the point at which the
hedge stopped being the Long Walk's. It did need the hedge to bend — `bow`,
added on 23 September, stands a run's middle off the straight line between its
ends and leaves both ends flat, which is a sixth thing `Organic` knows how to
draw and the point at which a `Structures/` split is worth doing. The frame, the staging, the bed edging and
the row labels are still to come, and each belongs to an area that is not built
yet. They
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
  from 2.3 m out. Three tiers each side, each in two staggered rows of five
  front slots, four middle and three back, so 48 plants a plot. The tiers have
  different spacings, so they stagger against each other too.
- **Tiers from measurement.** Across 300 crossings of 300 different pairs of
  parents, grown heights run 0.15 to 2.31 m, with thirds at 0.70 and 1.09 m. The
  cuts are at 0.77 m and 1.20 m instead, to match the number of slots in each
  tier (0.93 m and 1.28 m before 24 September 2026). Crossings of one person with forty others ran taller and were half
  bells, so a sample from one gardener is the wrong sample.
- **The rule is that nothing stands in front of something shorter**, not
  "tall ones in the back row". A plant goes to its own tier in the oldest plot
  with room, or else the tier beside it where the heights around it still
  order, or else a new plot. **The test found why.** Filling by row alone, a
  few more tall plants than back slots left eleven of fifteen plots holding
  six to nine plants. Now every plot but the newest four is full.
- **Drifts of colour, capped at five**, then the same colour starts again
  further down the walk. The cap is kept by refusing a slot that would join
  drifts past five, not by scoring it low: at two rows a tier, scoring let a
  plant between two short drifts make one of six. Every plant is unique, so a border here cannot repeat
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
- **No straight line anywhere in the garden** (Marcus, 18 September). Ruled
  edges round delicate flowers are jarring, so the ground's outline and sides,
  the path's verges and ends, and the hedges all wander. The shapes are
  SeedCore's `Organic` (`Morphology/Organic.swift`), so the app and the website
  draw the same ones, pinned in `OrganicTests`. The wander only goes inward
  from the plot's square, up to 0.16 m, so placement tests a point against the
  outline, not the square. Chrome outside the scene is not covered.
- **A hedge is grown, not built**: a loaf section, soft-shouldered, bulging and
  dipping along its length, its top undulating and its ends domed to the
  ground, with a leaf-grain texture. **Replaced 18 September**: it was a clipped
  box, square-ended. It is still drawn in pieces, each sorted by its own depth,
  because one picture cannot be in front of some plants and behind others; the
  pieces are cut from one continuous mesh and share their boundary rings, which
  is what the square ends were for (rounded pieces drew a seam at every joint).
- **A hedge's shadow is one shape on the ground**: its footprint, moved away
  from the light by its height over the light's slope. Sheared per piece like a
  plant's shadow, near noon each piece cast a hairline across the garden.
- **The path is mown in stripes along its length**, as a mower goes. Striped
  across, it read as paving slabs.
- **A hedge's top wanders** by up to 8% of its height over about 0.7 m, one
  line along the whole hedge. **Replaced 18 September**: it was cut level.
  Standing each piece at the hedge's height from its own ground still steps
  the top at every joint, so the top follows the one hedge's line.
- **Yew is picked brighter than yew**, the rule the bank of earth under the plot
  already follows: a vertical face gets the sky and little of the sun, and at
  yew's own darkness the face towards the path was black at midday. Brighter
  alone made it toy-green in the sun, so it is also greyed towards blue.

## The ambassador, standing

**Built 20 September.** *Halula crassicaulis* stands at the head of the Long
Walk's first plot: `LongWalk.ambassador` in SeedCore, `Ambassadors.php` in the
plot service, held to each other by `tools/reference/check_ambassador.php`.

- **There is no specimen slot, and that is the answer rather than a gap.** This
  document asked which slot of a template an ambassador stands in. For a double
  border the honest answer is none: a walk's feature belongs at the end of its
  vista, and this walk has no end — its plots open end to end for as long as
  people go on meeting. What it has is a head. So the ambassador is simply the
  first plant the rule ever placed, and the slot it took is the first slot of
  its own tier at the start of plot 0.
- **It could not have been the tall one at the back.** *Halula* is 1.04 m, the
  middle of a border. Measured across the ten, only *Cyninora contorta* is a
  back-tier plant at all, so a specimen fixed at the back of a border would have
  stood a short plant behind taller ones in nine areas out of ten, which is the
  one rule the Long Walk is built on. **A specimen slot has to be a slot the
  area's own ambassador can actually stand in**, and that is a constraint on
  every template still to be written.
- **It is not a row.** A slot and a nudge are both pure functions of the pinned
  seed, so the placement is derived on each side rather than stored on either:
  the Swift records it, the PHP re-derives it, and the check holds the two
  together. That also makes *nobody put it there and nobody can take it away*
  structural rather than a promise — there is no row for a withdrawal, a report
  or a backup to reach, and `WalkStore` refuses to plant an ambassador's seed at
  all.
- **The rule sees it.** The service hands it to the placement rule ahead of the
  stored arrivals, so every plant shared since has been graded against a border
  with its oldest plant in it. Handing it over afterwards would have drawn a
  plant nothing was placed around.
- **The walk is never empty.** `GET /api/walk` has said one plot since the day
  the garden opened, and `/walk` has had something in it to look at before
  anybody shared anything — which is what an ambassador was for.
- **A planting with no parents grows from its seed.** An ambassador was minted,
  not crossed, so the service sends it with an empty `parents` and no meeting,
  and `longwalk.js` grows it with `pg_grow` rather than `pg_grow_hybrid`. The
  empty list is how the wire says *this plant has no lineage* without a new
  field.

**Flipped while the walk was empty**, the same argument as the area flip the day
before: the walk is append-only, so the ambassador could be its first planting
only until somebody else's plant arrived. It had none.

## The Quiet Garden, built

The rule is in `SeedCore` (`WebGardens/QuietGarden.swift`), where the plot
service, the website and the app can all read it. Built 21 September, with
`QuietGardenTests`, `QuietGardenVectorTests` and
`tools/reference/check_quiet_garden.php`. Live at `/quiet`.

- **The plot:** a 5.2 m square with a hedge round all four sides, its inner face
  2.3 m out, so the room is 4.6 m across. A bench lies across one corner, one
  plant stands beside it, and each of the other three corners holds a group of
  three at the foot of the hedge. **Ten plants a plot**, against the walk's
  forty-eight in the same square. The middle of the room and the middles of all
  four sides stay grass.
- **No tree.** WEB-GARDENS said an enclosure has one. Nothing grown here is a
  tree: heights run 0.15 m to 2.31 m, which is a shrub at best, and a drawn tree
  among plants grown from a genome is the clip art this document warns about.
  Marcus dropped it on 21 September, and **the specimen is the plant by the
  bench** instead.
- **The specimen is the plot's first plant.** Not a reserved slot: a new plot is
  opened by taking its bench slot, so the plant beside the seat is always the
  oldest thing in the room. The same answer the Long Walk reached by a different
  route, and the reason this template can take a 0.55 m ambassador — a plant
  standing alone in grass beside a seat has no height to live up to.
- **A group is one colour, or a tone of it.** A group's colour is set by its
  first plant. An arriving plant takes a group of its own colour, else opens an
  unplanted corner, else joins a group of a colour near its own — the two arcs
  either side, or pale. **The near-colour fallback is not a nicety.** The seven
  families are nothing like evenly drawn: measured over three hundred crossings,
  two of them take 43% of plants between them and pale takes 3.7%, so own-colour
  alone would leave pale groups that never filled and plots that opened for want
  of a match.
- **Nothing stands in front of something shorter**, as on the walk, at the scale
  of a group of three: the back of a group is at least as tall as either arm.
  The cut between back and arm is 1.09 m, the 67th centile of the measured
  spread, because a group is one back and two arms. It is not the walk's 1.20 m
  and should not be — that one divides three tiers in the proportion 5:4:3.
- **How it fills, at five hundred:** 51 plots, 49 of them full, the two at the
  growing end holding seven and four. Of the plants that joined an existing
  group, 188 matched its colour exactly and 109 were a tone of it.
- **The hedge's ends are cut square, not domed.** A free-standing run ends in a
  long shoulder falling to the ground over half its height — a metre on the tall
  ones — which leaves a notch at every corner you can see the sky through. Round
  an enclosure each run carries on into the next, so `Organic.hedge` gained a
  `domed` flag and the four runs overlap by a hedge's thickness.
- **Tall on the two far sides, low on the two near**, the rule Marcus settled for
  the walk on 18 September, now applied four times. Where a tall run meets a low
  one at a corner there is a step, which is what a hedge cut down to keep a view
  actually looks like.
- **The bench is sawn, not grown** (`Organic.bench`): a plank across two plank
  ends, its wander a twentieth of a hedge's and all of it in the softness of the
  edges. A hedge undulates because it grew; a bench was made, and one that
  undulated the same way would read as melted.
- **It has a back, decided 21 September.** Backless it read end-on as a single
  upright panel four tenths of a metre across and nearly square — a slab — and
  two of the four quarter turns put it that way, so half of all views of the
  room had it. A post over each end carries two rails, which puts a shoulder in
  the silhouette; the daylight between the rails is the point of there being two
  of them, since a back in one piece is the same panel the ends already are. The
  back stands on the bench's `+x`, which the room turns to point into the
  corner, so a sitter faces the lawn with the hedges behind them.

**What looking found:** the template was right first time, which the walk's was
not — because it borrowed the walk's shape (a first choice, a near-enough
second, a new plot only when neither fits) rather than inventing one. What
looking *did* change was the drawing: the corner notches, the bench lying along
its corner's diagonal instead of across it, and a room framed so tight that the
page's own prose landed on the lawn.

## The Orchard, built

21 September, the same day as the other three. `SeedCore/WebGardens/Orchard.swift`,
`Server/.api/Orchard.php`, `OrchardStore.php`, `Server/assets/js/orchard.js`,
`/orchard`, `/dev/orchard`, `tools/reference/check_orchard.php`, and
`Organic.tree`.

- **Twenty a plot: five guilds of four.** Between the crossing's twenty-four and
  the room's ten. Four is one place nearest the middle of the plot, two beside
  the trunk and one furthest out, so a guild faces the middle exactly as a
  crossing's quarter does.
- **The rule is *finish one guild, then start the next*** — the Crossing's rule
  turned inside out, and the reason to build a fourth area at all. What it
  guarantees is that **no guild is started while an earlier one stands empty**,
  and that **a free place in an earlier guild is one nobody in a later guild
  could have stood in**. It does *not* guarantee that the counts fall from guild
  to guild: 4 4 4 3 4 is correct, because a guild's last place holds the
  tightest constraint in the plot and may wait a long time for a plant tall
  enough. Both `check_orchard.php` and `OrchardTests` asserted the falsehood
  first, both passed on their own five hundred, and the workbench at
  `/dev/orchard` — which draws a different five hundred — is what showed it. The Crossing
  looks for a plant's own rank across every quarter before it will accept a
  neighbouring rank, because its business is keeping four beds level. This looks
  through every rank of the earliest unfinished guild before it will move to the
  next guild. **The two loops nested the other way round is the whole
  difference**, and it is what the port has to get right: a port with them
  swapped agrees about the first four plants of every plot, about every plot's
  total, and about most placements after that.
- **The five trees are structures, not plantings.** `Organic.tree`, standing in
  every plot from the day it opens, a row in no table — the roundel's move
  again. The alternative, the tallest arrivals becoming the trees, leaves a new
  plot with five empty tree slots and guild places that mean nothing until a tall
  plant happens along. What it costs is that this is the first area where a
  gardener's plant cannot be the tallest thing in the plot; the Quiet Garden's
  bench is the precedent that says an area may hold something nobody planted.
- **The middle guild has no ranks at all**, and it is not a special case bolted
  on. Every rule here orders plants outward from the middle of the plot, and the
  four places under the middle tree are all the same distance from that middle —
  there is no in-front-of among them, because the middle tree is the one you can
  walk all the way round. It is the Crossing's *three sharing an arc* applied to
  a whole guild. It is also what makes the rule work: the first four arrivals go
  under the middle tree whatever they are, so a plot never opens by turning
  somebody away, and the 1.34 m ambassador — the tallest of the ten — has
  somewhere to stand that is not the back of a guild.
- **Cuts at 0.58 m and 1.20 m**, measured at the 25th and 75th centiles of three
  hundred crossings for a guild of 1:2:1 (0.75 m and 1.30 m before 24 September
  2026). The fourth division of one population by a fourth template, and its
  crown is the walk's back cut: both are the tallest quarter.
- **At 500 arrivals: 26 plots, 24 exactly full**, the twenty-fifth holding
  nineteen and the twenty-sixth two. An older plot goes on receiving after a
  newer one opens, because `place` scans plots oldest first every time.
- **Four plants in five get their own rank, where the Crossing gets 95.4%.**
  Preferring the guild over the rank means a guild of four takes whoever arrives
  next rather than waiting for the right height. 321 of 399 in their own rank, 44
  one step out, 34 one step in, none further. **It is not a visual fault**:
  `inOrder` is what guarantees the picture and it holds for every plant. A rank
  is the height a place was meant for; `inOrder` is what a visitor sees.
- **The rule held first time**, as the room's and the crossing's did, and the
  port agreed with the Swift on all five hundred at the first run.
- **What looking found was all in the tree.** `Organic.tree` is the second
  structure that is neither hedge nor bench, and it took four passes, which is
  the roundel's number:
  - **Too big and too low.** A 1.7 m spread on a 1.55 m crown covered the
    planting from every angle — and an orchard where you cannot see the guild is
    five trees. Lifted and narrowed.
  - **A green balloon on a stick.** The lumpiness was set at 0.20 of the radius
    from `wobble`'s -1...1 range, but value noise only touches its ends: a
    typical reading is about a third of the range, so the canopy came out a
    twelfth out of true instead of a fifth. 0.55, and one octave nearly as broad
    as the tree, is what made a canopy lopsided rather than merely bumpy.
  - **Faceted.** Flat shading was tried first, on the roundel's precedent, and
    it made a polyhedron. The roundel is flat because paving *is* faces; a
    canopy is a grown thing and belongs with the hedges, which are smooth. Once
    the lumpiness was strong enough, smooth normals read as foliage.
  - **A star at every treetop**, twice over. The canopy's two poles are one
    point held by twenty-five vertices, and `computeNormals` gave each only its
    own faces; and the per-face colour hash gave tiny touching triangles wildly
    different greens. One averaged normal for the pole ring, and a tone read
    smoothly off each vertex's own height, and it is gone. Both are the same
    fault the roundel had in its third pass: **the mesh showing through its own
    shading.**
- **The mown disc under each tree is the guild made visible.** Grass left long
  between the trees and cut back round each trunk is what an orchard is, and it
  is also the only thing on the page that says which four plants belong to which
  tree — without a line being drawn anywhere.

## The Knot Garden, built

22 September, and curved on 23 September.
`SeedCore/WebGardens/KnotGarden.swift`, `Server/.api/KnotGarden.php`,
`KnotStore.php`, `Server/assets/js/knot.js`, `/knot`, `/dev/knot`,
`tools/reference/check_knot.php`. No new structure: the knot is drawn in
`Organic.hedge`, which is the first time an area has been built without one —
though `Organic.hedge` learned to bend for it.

- **Thirty-two a plot: eight compartments of four.** Between the walk's
  forty-eight in the same square and the crossing's twenty-four. Four to a
  compartment because a block of three does not read as a block, and the
  compartments are blocks — that is what a knot garden's planting is.
- **The first rule that reads a plant's colour.** `PlantTraits` has carried
  `family` since the Long Walk and four areas have graded by height alone. This
  one asks the colour first and the height second: **colour picks the pair of
  opposite compartments, height picks the place within one.** Both fields used
  at last, and the height grammar every other area shares kept rather than
  thrown away.
- **The eight are four mirror pairs, and a pair holds one colour.** Opposite
  compartments across the middle of the plot — north against south, east against
  west, and the two diagonals — so the knot is symmetric in colour, which is
  what a knot garden looks like from above. A plot therefore carries four of the
  seven colour families, eight places each.
- **Nothing is reserved, and that settled what *a slot has a mirror* means.**
  The literal reading — taking a place holds the opposite place open for a
  matching plant — was rejected against a rule already written into four areas'
  comments: nothing in this garden reserves a slot, not even for an ambassador.
  The Orchard had also shown that a merely *constrained* place can wait hundreds
  of arrivals, and a reserved one would wait on a plant nobody has grown. A pair
  is claimed by the first plant to stand in it and filled by whoever of that
  colour arrives next.
- **The worry the brief raised was unfounded, and the number says so.** Seven
  families and four pairs a plot: a rule that claimed pairs greedily would open
  a plot for every colour that turned up and leave the garden half empty. This
  one claims a pair only when a plant needs one, so **at five hundred it is 17
  plots, 66 pairs claimed, 56 of them exactly full, and 92% of every place in
  the garden holding a plant** — the best fill of the five areas. The rarest
  colour is pale, nineteen plants of five hundred and one, and it claimed three
  pairs in the whole garden rather than one in every plot.
- **Four plants in five get the rank their height asks for**: 410 of 501 in their
  own rank, 67 one step out, 24 one step in, none further. Between the
  Crossing's 95.4% and the Orchard's 80%, for a nameable reason — preferring the
  pair over the rank displaces plants as the Orchard's guild-first rule does,
  but a pair holds eight places against a guild's four, so there is twice as
  much room to find the right one.
- **The cuts are the Orchard's 0.58 and 1.20, and are named as the Orchard's.**
  A compartment of four graded outward is the same 1:2:1 a guild is, so it
  divides the same population the same way. This is the first area to share cuts
  with another; re-measuring would have produced the same two numbers and
  presented them as an independent finding, which is a way of making one fact
  look like two.
- **The two compartments of a pair fill together**, which is the Crossing's
  *wherever there is least* asked of two instead of four — and *not* "they never
  differ by more than one", which is false and was this suite's first failure.
  A compartment whose remaining places are the wrong rank is passed over however
  empty it is. The test replays the five hundred arrival by arrival, because
  *which of the two was emptier* is a fact about the moment and the finished
  plot cannot say. At five hundred none of the sixty-six ends more than one
  apart (one did before 24 September 2026).
- **The pattern is a weave.** Two bands each way, crossing four times, inside a
  square edging: four compartments at the sides, four at the corners, and the
  weave closing round a middle that holds no plant. It is a real knot-garden
  plan and it gives eight compartments of one size, which is what a mirror pair
  needs to read as a mirror — the alternative considered, an octagram of a
  square and a diamond, puts the compartments in the star's points, and a
  regular octagram's points are 0.45 m² each, which will not hold four plants at
  any scale that fits a 5.2 m plot.
- **The bands curve, and that is what stopped it reading as a grid** — added on
  23 September, one day after the area opened, because straight interlaced runs
  are a weave the eye has nothing to follow through. `KnotGarden.weave` cuts
  each run into three: an arm, the stretch between its two crossings, and the
  other arm. The inner stretch bows 0.30 m in toward the empty middle, so the
  four of them close round it as a ring of four arcs; the arms bow 0.05 m the
  other way, so a run leaves a crossing turning back and reads as a ribbon
  rather than as a line with a curve let into it.
  - **No plant moved for it.** `Organic.hedge`'s bow is zero at both ends of a
    stretch, so every crossing is where it was, every compartment keeps its four
    corners, and `knot_garden_vectors.json` is untouched.
  - **The inner bow is free and the arm's is paid for.** Nothing is planted in
    the middle, so the inner stretch may bow as far as it likes; an arm has a
    compartment on each side. The nearest place to an arm stood 0.18 m from the
    band's face, of which the nudge already spends 0.09; at 0.05 m of bow a
    nudged plant still stands 0.048 m clear. `KnotGarden.clearance(x:z:)`
    measures it and `KnotGardenTests` holds it.
- **The weave is drawn rather than implied**, and it is drawn the way a real
  knot garden is made: living hedge cannot be woven, so the under-band stops
  square against the over-band's face and starts again beyond it, while the
  over-band carries on through and swells where the two have grown into each
  other. Which does which alternates round the knot, so every run is over at one
  of its two crossings and under at the other.
- **What looking found was all in the band and the ground**, and took three
  passes:
  - **The bands were walls.** 0.22 m through and 0.32 m tall drew nine boxes
    with walls between them, and no crossing read as a crossing because the
    junctions were blobs. Thinner was not enough on its own: what reads as a
    wall is a run **taller than it is broad**. Young clipped box in a knot is a
    ribbon laid on the ground, so it is 0.18 m through and 0.17 m tall, and at
    that the weave reads from every turn.
  - **The gravel was a tiled floor.** A square grid of cells each split on the
    same diagonal and flat-toned draws a checkerboard however small the cells
    are and however hard the tones vary: the eye finds the grid first, because
    the grid is the only thing in the picture that repeats exactly. Jittering
    the lattice by a third of a cell and turning each cell's diagonal with the
    same noise put it right. **It was the grid's regularity that had to go, not
    its size** — the cell is what it was.
  - **Per-face tone, not per-corner.** Grass is a surface and carries its tone
    on the corners of a grid, interpolated, so no cell edge shows. Gravel is a
    heap of stones, and the same smooth interpolation drew wet sand. It is the
    roundel's finding — paving is faces — at a twentieth of the size.
- **The ambassador wanted no accommodation.** *Quina caerulea*, 1.085 m, family
  4, placed by the rule into an empty Knot Garden: it claims the first pair for
  its colour and stands in the north compartment, at one of the two places
  beside the middle of it, because 1.085 m reads as a side rather than a heart.
  Nothing had to be arranged for it — an empty compartment refuses nobody —
  which is worth having confirmed rather than assumed, given what the Orchard's
  1.34 m ambassador cost.

## The Seedbed, built

The sixth area, `beginnings`, and **the first rule in the garden that groups by
sameness**. The five before it all sort by difference: a border graded by
height, a group of three read by rank, a quarter ranked, a crown standing over
its flanks, a pair claimed by colour and then graded. Every one asks *how does
this plant differ from that one*. A nursery row asks the other question, and a
drill sown with one kind is the plainest possible answer to it.

Marcus answered the three questions on 23 September before any code existed:
**six drills of eight**, forty-eight a plot; **a drill is claimed by the kind of
the first plant sown in it**, and only that kind may join it; **a place is taken
in the order of arrival**, filling from the labelled end.

### A kind is the epithet, and that was measured rather than chosen

The obvious reading of *kind* is the plant's name, and it does not work. Over
five hundred crossings **490 binomials are unique**; the genus is nearly as
rare, the commonest standing five times. A drill claimed by either would hold
one plant and wait forever, and the area would be a bed of singletons.

The **epithet** repeats: 46 of them over those five hundred, *rubra* thirty
times, *aurea* twenty-nine. It is also the truer reading. A genus is inherited —
`PlantName` gives a hybrid one parent's genus — where an epithet is chosen by
`Epithet.describing` to say the one thing that is most so about the plant it
names. **A drill of *contorta* is a drill of plants that are actually alike**,
which is what a nursery row means.

So `PlantTraits` carries a third fact. It had held two since the Long Walk —
height and colour family — on the argument that only two can be read without
looking; the kind is a third of exactly that sort, read off the grown plant and
stored with the planting. Nothing but the Seedbed reads it, and the service
never derives it: the phone sends it, the store keeps it in a column, and the
PHP rule compares it as a string. **The port needs to know nothing about
botany.**

### What the rule does

Three steps, oldest plot first: a drill already sown with this kind and not yet
full; failing that the first drill nobody has claimed; failing that a new plot,
first drill. A drill fills from index 0 outward, so reading a drill from its
label is reading it in the order it was sown.

- **A drill is claimed, never reserved**, as the Knot Garden's pairs are, and
  read off the plants rather than stored in a column — a claim that cannot go
  stale, be restored wrong, or disagree with what is standing in it. Were a
  drill held open for each of the 46 kinds, one plot would owe more drills than
  a bed has.
- **Nothing here reads a height, and nothing reads a colour.** This is the only
  area whose placement neither can move, which is why its vector file needs no
  `placementCannotTurn` check: it has no cuts for a plant to stand near. See
  `.claude/HANDOVER.md` §*The libm divergence* for why that matters everywhere
  else. `SeedbedTests` proves it by replaying every arrival with its height
  thrown away and again with one colour for all of them.
- **The nudge is the only one in the garden that differs by direction**: 0.035 m
  across a drill, 0.06 m along it. A drill has to read as a line, and a line
  survives being uneven along its length but not across it.

### The fill, and why it is the loosest in the garden

Five hundred arrivals: **16 plots, 91 drills claimed, 47 of them full, 65% of
places held** — against the Knot Garden's 92%. The waste is inherent and it is
the right waste: a kind that arrives once claims a drill and stands in it alone,
which is what a part-sown seedbed looks like. A bed shows what has been sown,
not what would look tidiest.

### The label

`Organic.rowLabel` — the sixth structure the file knows how to draw, and the
first of the four that the five remaining areas need. A tongue on a short stake,
leaning back 22°, because **seen from the garden's fixed isometric eye a plate
standing upright is a line two pixels wide**. Nothing is written on it: at this
scale a word would be four pixels tall and would fight the plants. The drill's
kind is named in the page's text, where it can be read and translated.

## The Cold Frame, built

The seventh area, `waiting`, 23 September. `SeedCore/WebGardens/ColdFrame.swift`,
`Morphology/Structures/GlazedFrame.swift`, `Server/.api/ColdFrame.php`,
`ColdFrameStore.php`, `Server/assets/js/frame.js`, `framepage.js`, `/frame`,
`/dev/frame`, `tools/reference/check_cold_frame.php`. **The first area that draws
a plant as something other than what it will be.**

Marcus answered its three questions on 23 September, after a measurement that
changed the first one: **every plant, drawn young; four frames of twelve; colour
claims a frame and the grown height orders its ranks.**

### Nobody is turned away, and that was measured

The layout's first reading was *small plants only*. The plants whose names put
them in `waiting` — about 9% of arrivals — grow to **0.33–1.64 m, median 0.85**,
and a low frame holds about 0.4 m, so a height limit would have refused nine in
ten of the area's own plants. With the shapes of 24 September 2026 every one of
them is a lotus or a fern, 0.23–0.82 m, median 0.38, and a limit would still
refuse four in ten. So every plant is admitted and **placed by the
height it will grow to, drawn at an early stage**. The drawn height is never
stored and never read by the rule; it is a matter of drawing.

### The rule

Colour picks the frame, height picks the rank. In order: a frame already
holding this plant's colour family, oldest plot first — its own rank if there
is room and nothing would stand out of order, otherwise the other rank on the
same terms; failing that the first frame nobody has claimed; failing that a new
plot. A rank fills from its west end. The claim is read off the plants, as the
Knot Garden's and the Seedbed's are.

- **The cut is 0.38 m, the median of this area's own plants** (0.85 m before
  24 September 2026), and it is the first cut measured over one area's plants
  rather than all of them. Five hundred `waiting` arrivals took 5,805 crossings
  to find. A borrowed cut would have divided them unevenly — the Orchard's 0.58
  puts 12% at the back, the Long Walk's 0.77 puts 1% — where this one puts
  49.8%. `ColdFrameTests`
  draws its sample the same way, and so does the workbench.
- **At five hundred: 12 plots, 46 frames claimed, 35 of them full, 87% of every
  place holding a plant**, and 472 of 501 plants in the rank their height asks
  for (485 before 24 September 2026: two in five of these plants now stand
  within 5 cm of the cut, and a plant near it is the one sent to the other rank
  when its own is full; no cut near the median does better). Between the two other areas whose places are claimed — the Knot
  Garden's 92% and the Seedbed's 65% — and nearer the Knot's, for its reason: a
  claim is made only when a plant needs one, and seven colour families are
  far fewer than forty-six kinds.
- **The margin holds.** The nearest recorded height to the cut is 0.37 mm clear,
  thirty-seven times the tolerance two hosts are allowed to disagree by, and
  `ColdFrameVectorTests` runs `placementCannotTurn` over plot and frame.

### Drawn young

`ColdFrame.drawn` is not a moment on the plant's own timeline, and cannot be:
`GrowthModel` grows height first and buds only once the height is done, so a
plant young enough to stand under glass has never shown its colour — and colour
is what claims a frame. The state is put together: `heightScale` 0.30,
`leafUnfurl` 0.7, `budSwell` 0.2, nothing open. Each number was measured:

- **Below 0.25, `PlantBuilder` draws the seed's husk** at the foot of the stem.
- **Leaves fully open stood above the glass.** A young plant's leaves are drawn
  at nearly half their grown size on a stem a third of its height.
- **A bud swollen further is a full-size flower head on a seedling** — at 0.8
  the tallest plant was 0.9 m.

That draws the five hundred **0.05–0.34 m tall**, and `ColdFrameTests` holds
every one under the glass above it with 2 cm to spare. The shortest are young
water lilies, their pads on the soil 0.26 m and more across, so since 24
September 2026 the test's floor on how small a seedling may be asks its larger
extent rather than its height: none is under 0.15 m. The grading does the
rest: the glass is lowest at the front, and the front rank holds the plants
that will grow shortest, whose young stages are shortest too.

**The slope is the ranks' own grading.** A cold frame is built higher at the
back so rain runs off and the glass faces the light, and the rule stands the
plants that will grow tallest at the back. The two were never designed
together, and they agree.

### The frame, and the glass

`Organic.coldFrame`, `frameLights` and `frameGlass` — the seventh structure, in
three pieces because it is three materials. The box is four of the bench's
planks, the ends cut down to the slope; the lights are painted bars resting on
the back wall and propped at the front on a block, which is how a frame is by
day and why there is a gap under the front of the glass. **The garden is lit at
midday on every page**, so the lights are always propped; *shut at night* would
need a page that knows its own hour.

**The glass is the first thing in the garden a reader has to see through.**
`makePlotStage` gained a pass for it: a ground builder may hand back a `glass`
mesh, and it is drawn after the plants, blended and without writing depth.
Every other area returns none and draws exactly as it did. Clear glass is seen
by what it reflects and where it doubles, so each light is glazed in panes
**lapped** down the slope, as a frame light is, with a ripple a couple of
millimetres deep in each — the lap is a line of more light and the ripple a
glint. At 30% opacity the seedlings under it were a milky smudge; at 14% they
read and so does the glass.

## The Glasshouse, chosen

The eighth area, `light`, chosen on 23 September and built on the 24th (below). It
comes before the Home Ground and the Coppice because **it holds the most plants
still waiting for a place** — 12.6% of arrivals, against 11.7% and 8.4% — and
because it reuses the Cold Frame's glass.

**What was measured first** (4,000 crossings): `light` plants are the tallest
in the garden, **0.44–1.88 m, median 1.03 m, none under 0.5 m**. On staging at
bench height a 1.88 m plant would stand 2.7 m, which decided the first answer.

Marcus's three answers:

1. **Staging and a border.** Pots on staging along the sunny side, and the
   tallest in a soil border along the back, where they cannot shade the pots.
   That is how a glasshouse grows its tomatoes.
2. **Thirty-two a plot**: twenty-four pots on the staging, two deep and twelve
   long, and a border of eight. The border takes the tallest quarter, which puts
   the cut near the 75th centile, about 1.26 m. To be measured over this area's
   own plants, as the Cold Frame's was.
3. **A spectrum of colour along the staging.** Each place on the bench stands
   for a band of hue, and a pot takes the free place nearest its own, so a bench
   fills as a run of colour. The first rule that sorts by hue rather than
   claiming by colour family. **The fill is to be simulated before anything is
   built**, and this answer comes back to Marcus if the fill is poor. Two things
   it must settle: where pale plants go, since they have no hue; and how a
   border plant is ordered, since the spectrum is the staging's.

### The fill, simulated

23 September, before any rule was written. 500 `light` plants (3,930 crossings),
twelve positions along the staging with two pots at each, a border of eight.

- **Plants of this area avoid green.** Hues from 100° to 140° hold two plants
  in five hundred, so the circle is cut there: the bench runs from blue-green
  through blue, violet, magenta, red, orange and yellow, and its two ends are
  the colour flowers are least often. Nineteen plants in five hundred are pale
  and have no hue.
- **Bands of equal width fill badly.** Hue is not spread evenly, so the
  crowded bands open new plots while others stand empty: 68% held if a pot must
  have its own band, 82% if it may stand one place off.
- **Bands of equal share fill well.** Each position stands for a twelfth of the
  plants rather than a twelfth of the circle. Plant by plant, a pot looks for
  its own band in every open plot first, then one place off, then opens a new
  plot. Pale plants take any free place.
  - **Measured on a fresh 500 the bands were not fitted to: 18 plots, 87% of
    places held, the staging 92% full, 86% of pots in their own band and none
    more than one place off.** On the sample the bands were fitted to it was 98%
    and 94%, which is how much fitting flatters.
  - The band edges are to be set from a larger sample, so less is fitted.
- **The border cut is the Orchard's 1.30, borrowed and named as such.** The
  75th centile of these plants is 1.294 m. (Since 24 September 2026 the border
  has its own, 1.14; see §*The Glasshouse, built*.) The border fills more loosely than
  the staging, 70% on the fresh sample, because plots are opened by whichever
  runs out first.
- **The border is planted in arrival order from the door end**, Marcus's answer on
  23 September. The spectrum belongs to the staging alone.
- **Hue is exact on every host.** It is drawn from the seed by arithmetic, with
  no `sin` or `pow` in it, so a band edge needs no tolerance, unlike a height
  cut. It does need carrying: `PlantTraits` holds a colour family, not a hue,
  so a hue is a fourth trait, sent by the phone and stored like the Seedbed's
  kind, by both arrival paths.

## The Glasshouse, built

24 September. `SeedCore/WebGardens/Glasshouse.swift`,
`Morphology/Structures/SpanHouse.swift` and `Staging.swift`,
`Server/.api/Glasshouse.php`, `GlasshouseStore.php`,
`Server/assets/js/glasshouse.js`, `glasshousepage.js`, `/glasshouse`,
`/dev/glasshouse`, `tools/reference/check_glasshouse.php`. **The first area
that sorts by hue, and the first whose plants do not all stand on the ground.**

### The rule

Height picks the bed. A plant of 1.14 m or more goes in the border: the next place from the door in the oldest plot with one,
whatever its colour. Anything shorter is potted on the staging:

1. its own band, in every open plot, oldest first;
2. one band off, in every open plot — the neighbour its hue leans to first, and
   never across the cut, where the two ends of the bench are the two ends of
   the spectrum rather than neighbours;
3. a new plot, at its own band.

A pale plant, or one whose hue was never sent, takes the first free pot from
the door. A position fills its row by the glass before its row by the path.

- **The band edges were set from 2,864 hued plants** of the area's own (3,000
  out of 23,259 crossings, less 136 pale), under a label the tests do not use,
  and written in as literals: 166.6°, 190.8°, 215.9°, 239.8°, 265.8°, 291.0°,
  315.7°, 345.4°, 15.7°, 40.3° and 69.6°, as turns past the 114° cut.
- **The border's cut is its own, 1.14 m**: the 75th centile of five hundred of
  the area's plants drawn under a label the tests do not use, 1.139 m. It was
  the Orchard's crown, borrowed, until 24 September 2026; the new shapes brought
  these plants down further than the garden's as a whole (their 75th centile by
  0.16 m, the garden's by 0.09), and the Orchard's new 1.20 would have taken 18%
  of them rather than a quarter. **The band edges stay**: they are cut across
  hue, and no hue moved.
- **On a fresh five hundred: 18 plots, 87% of places held, the staging 89% full
  and the border 81%, and 340 of 372 hued pots in their own band**, none more
  than one off. It was 17 plots and 92% before the shapes changed: the border's
  quarter of these five hundred is 24%, a little under its quarter of the
  places, so the staging opens plots a little ahead of the border. Own band is
  better than the simulation's 86%, because the edges were fitted to six times
  the sample and a pot one band off tries the side its hue leans to first — a
  choice the simulation did not make, taken here because Marcus's answer was
  *the free place nearest its own*.
- **Hue became `PlantTraits.hue`**, a turn of the circle, optional: the phone
  sends it (`WalkArrival.hue`), `walk_offers` gained a nullable `hue` column,
  and a plant without one is placed as a pale one is. `GlasshouseStore::exactly`
  binds it as the shortest text that reads back as the same double, because
  PDO binds a float at fourteen significant digits — harmless for a height,
  and not for a number compared with a band edge exactly. `check_offers.php`
  holds a hue to the bit through the asking.
- **The vector file compares the hue exactly**, under WebAssembly as on the
  Mac, and `placementCannotTurn` checks only the border's cut: nothing here
  weighs one plant's height against another's.

### The house

`Organic.spanHouse` and `spanHouseGlass`: a span house 4.4 m by 3.4 m, eaves
at 2.1 m and ridge at 2.9 m, glazed to the ground, with its sliding door slid
open in the `x−` gable — the end the spectrum and the border both count from.
**The eaves and ridge were set by the plants under them**: a potted plant
stands 0.83 m off the floor and may be 1.30 m tall, and `GlasshouseTests` holds
every one of the five hundred under the roof with a tenth of a metre to spare
(the nearest was 0.23 m clear). Since 24 September 2026 a potted plant is under
1.14 m and the nearest stands 0.39 m under the roof; the house was left as
built, with more air over the pots. `Organic.staging` is five slats on five frames
of legs; `Organic.pot` is a turned clay pot, round by `Organic.turn`, which
sums the board's corner series four times rather than calling `sin`.

The page draws a pot under every planting with a `lift`, which the service
sends beside its spot. So the ground is built again for each plot
(`makePlotStage`'s `rebuild`), and `add` takes a lift. The glass is the Cold
Frame's pass at 5% rather than 7%, because two or three layers of it stand
between the eye and a pot. The floor is quarry tiles, the map's `LOOK.light`
ground, laid on the Knot Garden's jittered lattice with a tone to a tile, so
the grid a tiled floor is shows as tone rather than as ruled lines.

## The Coppice, chosen

The ninth area, `renewal`, designed on 24 September with a simulation and no
code, the way the Glasshouse was, and built the same day (§*The Coppice,
built*). The numbers below are the design's, and the build measures its own. It holds 8.4% of arrivals, the fewest
of the three areas still shut. It also answers the question this document has
carried since it was written (§*Open questions*): how a coppice shows its
rotation.

### What was measured first

`tools/coppice/` grew 4,000 plants whose names put them in the Coppice: 2,000
from 23,791 crossings to measure on, and another 2,000 from 24,054 crossings to
check against.

- **Every plant in the Coppice is a fern or a star.** Its genus heads are `Dros`
  and `Ros`, and `PlantName.roots` gives those two to many-merous ferns and
  many-merous stars and to nothing else. That is not a tendency in a sample. It
  is a fact of the naming table, which is frozen. The split is 48 ferns to 52
  stars in both samples. **This is the first area whose own plants divide by
  habit, and they divide exactly.** The *Habit* row of §*Slots and roles* has
  had nothing to act on until now.
- **A fern has no bloom to speak of.** Its profile sets `bloomPresence` to 0.05.
  A star carries every flower in the area.
- **Ferns are the shorter habit**: 0.22–0.92 m, median 0.49. Stars are
  0.48–1.77 m, median 1.00. A fern spreads 0.67 m, a star 0.79 (the median of
  each; with the shapes before 24 September 2026, 0.31–1.40 and 0.52–1.95 m,
  both about half a metre across).
- **Drawn young, a fern is 0.08–0.38 m tall**, at the Cold Frame's
  `heightScale` of 0.30 with no bud. That makes the shortest star in either
  sample, 0.43 m, taller than the tallest cut fern. The design below rests on
  that fact.
- The ambassador, *Rosea caerulea*, is a star of 0.906 m.

### Three layouts, and the one chosen

A coppice is a wood cut in panels, called coupes. Each year one coupe is cut to
the stool and left to grow back, so every stage stands at once: stumps, poles
waist-high, and poles grown. The flowers come up in the light a cut lets in. The
three layouts considered all show that; they differ in where.

1. **One coupe to a plot.** Each plot would stand at one stage, and plot *n*
   would be cut in year *n* mod 3, so the rotation would show on the map. It is
   the simplest rule of the three. It was rejected because a visitor comes down
   onto a plot and would see one stage there. *Every stage at once* is the
   coppice's picture, so it has to be inside the plot.
2. **Four coupes round a standard.** The plot would be quartered round one tall
   plant left uncut, which is coppice-with-standards, the commonest English
   form. It was rejected on three counts. It is the Crossing's plan with a tree
   where the paving is. The standard is a height place that waits for a tall
   plant, and the Orchard showed that such a place can wait hundreds of
   arrivals. And four coupes need a four-year rotation, which shows only three
   distinct stages.
3. **Three coupes in bands, cut in turn — chosen.** Two rides cross the plot
   and divide it into three long panels side by side. That is what a worked
   coppice looks like from above: cants laid alongside each other and cut in
   sequence, which gives the stepped profile, stumps next to half-grown next to
   grown. Three bands give three stages, and three is as many as a plant's
   growth shows distinctly: young, half-grown and grown.

### What is cut: the ferns

Something in each coupe has to be cut, and three ways of deciding what were
simulated side by side (§*The fill, simulated* has the numbers):

- **By height**, with the tallest 45% on the stools. This fills at 96.2% at two
  thousand. It also cuts 81% of the stars, so the showiest flowers in the wood
  would be out of flower two years in three.
- **The stars on the stools and the ferns on the floor.** The heights stand in
  their natural order, the tall habit growing over the short one, and it fills
  at 96.2%. It cuts 89% of the stars. Colour is the one thing a star has, so
  this was rejected.
- **The ferns on the stools and the stars on the floor — chosen.** It fills at
  97.8% and cuts no star, ever. Every flower in the Coppice is drawn in flower
  every year. A fern loses nothing a visitor could see by being cut, because it
  had no bloom to lose, and a fern growing back from a cut comes up as a fern
  always does, in croziers, which is as plain a picture of renewal as a garden
  has. **In a coupe's cut year every star stands over every fern in it**, with
  0.15 m to spare at the closest. Each winter one band of the plot becomes a
  glade of flowers over new growth, and the other two show the ferns coming
  back. That is also true to the practice: in real woods the cutting is what
  brings the flowers.

**The cost: a grown fern does not overtop the stars.** Measured at five hundred, 5 of 233 ferns on stools stand over the front
row of their coupe in their grown year, and none over the shortest star behind
them. So the rotation reads at knee height, under the flowers, not as poles
over them. What says *coppice* at a glance is the stool, the old cut wood each
fern grows out of (§*The stool*). The fern is what the stool grows.

### The plot

**Thirty-three a plot: three coupes of eleven.** That is five stools down the
middle of each band and three places in the light on either side, a back row
and a front row. The Glasshouse has thirty-two in the same square and the Long
Walk forty-eight.

| | Where, in metres from the middle of the plot |
| --- | --- |
| **Coupes** | Bands along `x`, their middles at `z` −1.80, 0 and +1.80. Coupe 0 is `z−`, the far band before the page is turned |
| **Rides** | Two, their centrelines at `z` ±0.90. Each is 0.48 m wide and wanders up to 0.08 m off its line |
| **Stools** | `x` −1.8, −0.9, 0, 0.9, 1.8, on the coupe's middle |
| **The floor** | `x` −1.35, 0, 1.35, in a back row 0.40 m behind the stools and a front row 0.40 m in front |
| **Nudge** | 0.06 m either way, from the seed |

The nearest two places stand 0.40 m apart before the nudge. At the worst nudge
and the worst wander, every place is 0.18 m clear of the plot's rim and 0.12 m
clear of a ride. `simulate.py` checks both. A row fills from its middle outward:
stools in the order 2, 1, 3, 0, 4, and floor places 1, 0, 2. A coupe holding
three plants then reads as a clump, where filling from one end would make it a
line. Which place a plant takes along its row changes no count, so none of this
needed simulating.

### The rule

An arrival is either a fern or a star, and the two are placed by different
steps.

**A fern:**

1. A free stool in the oldest plot that has one, in whichever of that plot's
   coupes holds fewest ferns on stools. A tie goes to the lowest coupe.
2. Failing that, the floor, by a star's rule below, **but no more than one fern
   to a coupe's floor.** A fern standing on the floor is not cut, just as a fern
   on a woodland floor is not.
3. Failing that, a new plot, on the middle stool of its first coupe.

**A star:**

1. Its own row of the floor, which is the back row from 1.00 m up and the front
   row below. The search runs oldest plot first, and within a plot takes the
   coupe with fewest on its floor.
2. Failing that, the other row on the same terms, but only if nothing would
   stand out of order. Nothing in a coupe's front row may be taller than
   anything in its back row. This is the Cold Frame's `inOrder` asked of a
   floor.
3. Failing that, a new plot, in its own row of the first coupe.

The loops are the Crossing's: row outside, plot inside, and the emptiest coupe
within the plot, with coupes standing in for quarters. That keeps the three
coupes of a plot level, so each of the three stages has plants from a plot's
first few arrivals. That matters more here than anywhere, because one coupe is
always in its cut year.

**The cap of one fern to a coupe's floor was found by the simulation, not
guessed.** Stools make up 45% of the places and ferns 48% of the arrivals, so
some ferns have to stand on the floor. With no ferns allowed there, the floor
fell behind the stools and never caught up, finishing at 94.7%. With no limit,
a long run of ferns took the floor from the stars, and the plots the stars
opened afterwards had stools no fern would come to: 74.9% against 85.4% in that
order. A cap of one keeps the realistic fill where no limit put it, and it
keeps the floor the stars'.

**The traits it reads, and the thresholds:**

- **Habit, a fifth trait.** `PlantTraits` gains the archetype's name, sent by
  the phone and stored in a column by both arrival paths, as the Seedbed's kind
  was and the Glasshouse's hue will be. The rule asks one question of it: is
  this a fern. It is exact on every host, because an archetype is picked from
  seed bytes with no `sin` or `pow` involved, so the test needs no tolerance.
  If the Glasshouse's hue is built first, one `walk_offers` migration can carry
  both.
- **One height cut, 1.00 m**, the median of this area's own stars, measured
  over the area's own plants as the Cold Frame's was (1.10 m before 24 September
  2026). It divides the fresh sample's stars 49.0% to the back. A borrowed cut
  would divide them unevenly: the Orchard's 1.20 would put 28% at the back, the
  Long Walk's 0.77 would put 75%. The nearest of 2,084 stars stands 0.25 mm from
  it. The vector file will
  still need `placementCannotTurn` over plot, coupe and row, because a height
  comes out of `sin`.
- **Colour is not read.** Carpets were considered: the first star on a coupe's
  floor would claim it for its colour family, the way bluebells hold a coupe. It
  held 97.8%, as the rule did, but left 15 places empty in settled plots where
  the rule left 3, and a Coppice whose three bands were three colours
  would ask the eye to read colour stripes where it should read the cut. The
  Knot Garden and the Cold Frame already sort by colour, and the Glasshouse
  will. This one sorts by the year.
- **Arrival order** decides the rest. A place is taken once and never changes,
  as in every area.

The ambassador is a star under 1.00 m, so it opens plot 0 in the front row of
coupe 0. An empty floor refuses nobody.

### The rotation

A coupe's stage is arithmetic on its place in the wood and the year:

    stage = (year − (3 × plot + coupe)) mod 3      0 cut, 1 regrowing, 2 grown

`year` counts the winters since the Coppice opened, so the first coupe of
plot 0 is the first one cut. The coupes are cut in sequence along the wood, so
the stepped profile runs unbroken from the last coupe of one plot into the
first coupe of the next. In
every year a third of the ferns on stools are in each stage: at five hundred it
is 78, 77 and 78 of 233, and it stays that way year after year.

| Stage | The fern on a stool is drawn | Height, measured |
| --- | --- | --- |
| **Cut** | `heightScale` 0.30, `leafUnfurl` 0.6, no bud — the Cold Frame's young state without its bud | 0.08–0.38 m, median 0.20 |
| **Regrowing** | `heightScale` 0.65, `leafUnfurl` 0.9, `budSwell` 0.4 | 0.15–0.65 m, median 0.35 |
| **Grown** | At its best, `Maturity.bloomPreview`, as everywhere else | 0.22–0.92 m, median 0.49 |

The two young stages are the Cold Frame's `drawn` with its numbers changed, so
they are the same kind of thing: a stage assembled for drawing, never stored and
never read by the rule. A star, and a fern on the floor, is drawn at its best
every year.

**The year is the plot service's to say.** It goes out with the plantings, so
two visitors on either side of midnight see one wood, and a check can pin the
year. This would be the first page that knows its date. Every other page is lit
at midday and knows nothing of time.

### The stool

Each fern on a stool stands on one: a low boss of old wood, 0.35–0.45 m across
and about 0.10 m high, its outline wandering, with the cut face on top. The
fern's foot stands on the face. **The face is pale in the year of cutting and
weathers grey over the next two**, so the stool is the one structure in the
garden that shows the year. It is drawn in the same pass as the plant it
carries, so it belongs to a planting and not to the plot: an empty stool place
shows the woodland floor, not a dead stump. It is grown wood that was cut,
so its outline can wander more than a sawn bench's and less than a hedge's.
At 0.45 m across, the widest stool still leaves the nearest floor plant 0.05 m
clear at the worst nudge.

### How it reads from the page's eye

- **The ground is a woodland floor**: leaf litter at `LOOK.renewal`'s `#5e4a33`,
  moss where the ground dips, and gentle relief so that no two stools stand at
  one height. None of the eight worlds is a wood, so this is a new one.
- **The rides are trodden, not mown.** They are litter worn paler, with no
  stripes, and they bow and change width along their length. They meet the rim
  where they meet it, not at a corner of a grid. A coupe has no drawn edge: the
  rides are its only boundary, as the mown paths are the Crossing's. **Nothing
  in the plot is a straight line**: not the rides, not a stool's outline, not a
  shadow. A stool's shadow is its footprint moved away from the light, as a
  hedge's is.
- **Seen at the page's angle, the three bands run corner to corner** across the
  diamond of the plot, one of them open. The cut coupe shows pale stool faces
  and croziers under a stand of stars in flower. The next shows ferns
  half-grown, and the third ferns grown, still under the flowers. The cut moves
  one band a year, so from the page's first view the open band is the far one
  one year, the middle the next, and the near one the third. Turning the plot
  shows the other orders.
- **Back is `z−`**, as in the Cold Frame. The floor's taller row is further
  from the eye before a turn, and a half turn reverses it, as it reverses the
  frames' ranks.
- **Its words belong to the page.** Which stage a coupe is in, *cut this
  winter*, is a string, and a string is forty-two translations
  (§*Structures need drawing properly*). The stool stays unnamed, as every
  structure is.

### The fill, simulated

24 September. `tools/coppice/coppice-sample` is a small Swift tool built
against SeedCore. It grows each arrival and writes down its height, spread,
colour, archetype and the height it is drawn at in each young stage.
`tools/coppice/simulate.py` plants those arrivals by the rule above, and by the
rules it was chosen over, in Python. The rule has not been written in Swift yet,
so there is nothing to call. Both samples are committed, so the script runs
without Swift. The cut was measured on one sample and every number below comes
from the other, unless it says otherwise.

**The realistic stream**, the fresh sample in the order it was drawn:

| Arrivals | Plots | Full | Held | Empty in settled plots |
| --- | --- | --- | --- | --- |
| 250 | 8 | 7 | 95.1% | 0 |
| 500 | 16 | 14 | 94.9% | 0 |
| 1,000 | 31 | 30 | 97.8% | 0 |
| 2,000 | 62 | 59 | 97.8% | 3 of 1,980 |
| 4,000, both samples end to end | 122 | 120 | 99.4% | 0 |

*Settled* means every plot but the newest two, which are where a visitor would
find an empty place in the old part of the wood.

- **At five hundred it holds 94.9%.** That sits between the Knot Garden's 92%
  and the Orchard's 96%, and it rises with the count, because nearly every
  empty place is at the growing end.
- **Fitting does not flatter it.** On the sample the cut was measured on, the
  numbers are 94.9% and 97.8% at five hundred and a thousand, and at two
  thousand 96.2% with 22 settled places empty — worse than the fresh sample,
  which is two samples differing rather than anything the cut did (with the
  shapes before 24 September 2026 the two samples came out alike). The Glasshouse's twelve band edges gained eleven points from
  fitting. The Coppice has one fitted number, a median, and that is the
  difference.
- **The distribution at two thousand**: 59 plots of 33, then 30, 23 and 1 at
  the growing end. In all 60 settled plots the three coupes hold exactly the
  same number of ferns on stools and of plants on the floor.
- **1,042 of 1,087 plants on the floor are in their own row** (95.9%). **Nothing
  stands out of order anywhere**, in any stream tried, with or without the cap.
- **37 of 951 ferns stand on the floor** (3.9%).
- **The worst wait**: one plot stayed unfinished for 120 arrivals.

**Worst cases.** The same two thousand plants in orders no real garden would
send. The longest run of one habit in either realistic stream is 11.

| Order | Held at 1,000 | Held at 2,000 |
| --- | --- | --- |
| Runs of twenty, stars then ferns | 97.8% | 99.4% |
| Runs of sixty | 97.8% | 97.8% |
| Every star first, then every fern | 54.2% (840 stools empty) | 96.2% |
| Every fern first, then every star | 57.2% | 85.4% (74.9% with no cap) |
| Heights sorted within each habit, in windows of a hundred, shortest first / tallest first | 94.8% | 96.2% / 97.8% |
| Heights sorted within each habit over the whole stream, shortest first / tallest first | 94.8% / 97.8% | 71.3% / 68.1% |
| One colour at a time | 97.8% | 97.8% |
| Shuffled | 97.8% | 97.8% |

- **A stool waits for a fern, and a fern always comes.** A thousand stars in a
  row open 56 plots with every stool empty, and the ferns that follow fill them
  back to 96.2%.
- **The one order it cannot recover from is every fern first.** The ferns fill
  the stools and their share of the floor, then run out, and the stars open
  plots with stools no fern will ever come to. The cap is what brings it from
  74.9% to 85.4%.
- **Sorting heights across the whole stream defeats any rule that grades by
  height**, and the Cold Frame and the Crossing grade the same way. Late in a
  sorted stream, half of each new plot's floor wants a plant shorter, or
  taller, than any still to come. Sorted within windows of a hundred, which is a strong
  fashion for tall plants and no more, it makes no difference.

**The rules it was chosen over**, on the fresh sample at two thousand:

| Rule | Held | Settled empty | Stars out of flower two years in three |
| --- | --- | --- | --- |
| **Ferns to stools, stars to the floor, one fern to a coupe's floor** | 97.8% | 3 | none |
| The same, with carpets of one colour | 97.8% | 15 | none |
| The same, with no fern on the floor | 94.7% | 66 | none |
| The same, with any number of ferns on the floor | 97.8% | 2 | none, but 74.9% if the ferns come first |
| The tallest 45% on stools, by height (cut 0.71 m) | 96.2% | 24 | 848 of 1,049 |
| Stars on stools, ferns the floor | 96.2% | 41 | 934 of 1,049 |

**The template's one real number is its stool share.** `simulate.py --sweep`
tried stools from three to seven a coupe and floor rows from two to four. Every
share between 43% and 47% fills well: 95.2% to 98.8% at two thousand. At 50%
and above the stools are left waiting, at 94.7% down to 68.9%. At 40% and below
the ferns crowd onto the floor's front rows and leave the back rows waiting, at
95.2% down to 75.8%. Forty-five a plot, seven stools and four a row, holds
98.8%. It was passed over because a wood that dense is a border. Twenty-one a
plot holds 98.2%, but at seven plants a coupe the stages are too thin to read.

### Decided, 24 September 2026

1. **The rotation turns once a year, at the winter solstice**, taken as
   21 December UTC. Marcus.
2. **Ferns stand on the stools**, and the stars on the floor are never cut.
   Marcus.
3. **The stars' colours are mixed as they arrive**, with no carpets. Marcus.
4. **The stool is a low boss of old wood whose growth is its fern**, with no
   poles of its own. Taken as recommended, open to change.
5. **A plant's own page draws it grown**, whatever its coupe's year. Taken as
   recommended, open to change.
6. **Thirty-three a plot.** Marcus.

## The Coppice, built

24 September, the same day it was designed. `SeedCore/WebGardens/Coppice.swift`,
`Server/.api/Coppice.php`, `CoppiceStore.php`,
`tools/reference/check_coppice.php`. **The first area whose rule reads a
habit, and the first that knows its date.**

### The rule, as built

The rule is §*The rule* above, unchanged. Built, it holds the simulation's
numbers exactly, because the tests draw the design's fresh sample
(`coppice-fresh`) in the same order:

- **At five hundred: 16 plots, 14 full, 94.9% of places held**, nothing empty
  in a settled plot, 259 of 268 plants on the floor in their own row, and 2
  ferns on the floor.
- **The closest star over a cut fern stands 0.15 m clear of it**, and the
  tallest cut fern is 0.36 m (0.23 m and 0.35 m before 24 September 2026). `CoppiceTests` grows every fern on a stool at
  `Coppice.cutDrawn` to hold that.
- **No star is on a stool, no floor holds two ferns, and nothing stands out of
  order**, in the Swift and in the port.

**Habit became `PlantTraits.habit`**, the archetype's name, a string:
`WalkArrival.habit` carries it, `walk_offers` gained a `habit` column that is
emptied when an offer is answered, and the Coppice's table stores it. Empty
where it was never sent, and read as a star's, so an older phone's fern stands
in the light rather than being refused. It is exact on every host, so the
vector file compares it as a word.

**The year is the service's.** `Coppice.year(utcYear:month:day:)` counts the
21 Decembers since the wood opened, so year 0 runs to 21 December 2026 and in
it the first coupe of plot 0 stands cut. `GET /api/coppice/plot/{n}` sends the
year, each coupe's stage in it, and each fern on a stool with its stage; a
star, and a fern on the floor, is sent with no stage, which is *drawn at its
best*.

**Taking back keeps the height and the habit**, which the rule reads of a
coupe's floor, and writes over the family, which it never reads.

### The page

`Morphology/Structures/Stool.swift`, `Server/assets/js/coppice.js`,
`coppicepage.js`, `/coppice`, `/dev/coppice` (with `?year=` and a *Next winter*
button, since the service stays in year 0 until 21 December 2026).

- **The stool** is bark and a cut face, 0.35–0.45 m across from the fern's
  seed, its outline wandering inward only, by up to 3 cm, so no stool is wider
  than the spacing was worked out for. The bark stands 3 cm into the ground so a
  stool on a slope never floats. The face is cream in the cut year, weathering
  the next, grey in the third. Round by `Organic.turn`.
- **The floor rises and falls by up to 5 cm**, level at the rim, and is a
  little lighter in the cut band and a little darker in the grown one, blended
  across the rides. It is read from the service's per-coupe stages, so the open
  band shows before any stool in it has a fern.
- **The rides are 0.48 m wide, give or take 12%**, and wander up to 0.08 m off
  their line. At the narrowest that leaves a floor plant about 8 cm clear of a
  ride, where the design measured 12 cm at a constant width.
- **Stools cast shadows**, their footprints moved away from the light; the
  first page to draw any.
- **No stage words.** *The far band is cut* is wrong after a turn, and the pale
  faces say which band it is. The page's two new strings, `coppiceAbout` and
  `coppiceAway`, are English only for now, as the Glasshouse's were.

## The Crossing, built

21 September, the same day as the Quiet Garden. `SeedCore/WebGardens/Crossing.swift`,
`Server/.api/Crossing.php`, `CrossStore.php`, `Server/assets/js/crossing.js`,
`/cross`, `/dev/cross`, `tools/reference/check_crossing.php`.

- **Twenty-four a plot: four quarters of six.** Between the walk's forty-eight
  in the same square and the room's ten. Six is three along the path edges, two
  behind them and one at the outer corner, so a quarter builds outward from the
  middle of the place.
- **The rule is *wherever there is least*.** An arriving plant goes to the
  emptiest quarter of the oldest plot that has a slot it fits, and a tie goes to
  the lowest-numbered quarter. That is the whole of it, and it is what the area
  is about: a quadripartite garden reads as four ways arriving at one place only
  while all four look equally used. **`<` and not `<=` on that count** is the
  thing the port has to get right, and the only thing it could get wrong while
  agreeing about every number.
- **Cuts at 0.91 m and 1.30 m**, measured at the 50th and 83rd centiles of three
  hundred crossings for a bed of 3:2:1 (0.97 m and 1.43 m before 24 September
  2026). Deliberately neither the walk's 0.77/1.20 nor the room's 1.09: the same
  population divided three ways by three templates.
- **The three at the path rank share an arc**, which is what frees them from
  having to be in order with each other. Only ranks are compared, never
  distances, so the rule never has to say which of three equals stands in front
  of which.
- **At 500 arrivals: 22 plots, 20 full**, the two at the growing end holding 15
  and 6. 478 of 501 plants got a slot of their own rank; the other 23 took the
  rank beside it.
- **The rule held first time**, as the room's did, and for the same reason: it
  borrowed a shape that had already been argued about rather than inventing one.
- **The quarters are grass, not beds.** They were bare soil until Marcus looked
  at a plot holding one plant: four brown quarters read as ground waiting to be
  dug. Grass left rough between mown paths is a garden whether it holds one
  plant or twenty-four, and it means a quarter needs no edge drawn at all — a
  mown path's own wandering edge is the only boundary in the place.
- **A round of paving, and the first structure that is neither hedge nor
  bench.** `Organic.roundel`: a low disc standing proud of the grass with a
  wandering edge and a rim down to the ground. It holds no plant, which is what
  lets the 0.46 m meeting ambassador be a plot's first arrival — the same test
  the Quiet Garden's specimen had to pass.

**What looking found**, all of it in the drawing and all of it about the
paving. It arrived as a bright dish two metres across and went through four
states before it was stone: too big (1.0 m radius against a 1.2 m path, now
0.85), too bright and too blue (a near-neutral albedo under a blue sky ambient
is a blue lid), drawn with its own mesh's rings showing as spokes, and finally
too smooth — **smooth normals over a cambered disc take one broad highlight and
read as a polished cover.** It is the one thing on the page shaded flat, one
normal and one tone a triangle, which is what makes it faces rather than a
surface.

## The dressing: what we place by hand

The rules place the plants. What we choose by hand is everything else, per plot:

- **Its ground**, from the app's eight worlds, or new ones made for the areas
  (the Glasshouse's is quarry tiles, drawn by its page rather than taken from a
  world).
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
  deletes. Releasing to a place needs the plot service. It is also a different
  action from *Show in the peace garden*, which is the Long Walk and is built:
  release is letting a plant go, and the Wild Fields have no asking because a
  released plant is not put anywhere in particular.

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
3. **One area's template**, built and judged at five hundred plants. **Done
   for the Long Walk, 18 September**, in the browser (`/walk`, and
   `/dev/walk` for a walk invented to look at).
   The rule held: every plot full but the growing end, 3% of plants a tier from
   their own. The look did not: one row a tier was about 1.4 plants a square
   metre and read as single stems on turf, with drifts too far apart to read
   as colour. Doubled to two staggered rows a tier (48 a plot, about 2.8 a
   square metre); a partly filled plot is shown as it is. The Long
   Walk is the best first one: its rule is the plainest best practice there is
   (tall at the back, drifts, repetition), and its plots open end to end, so
   the map is a line before it has to be a shape.
4. **The plot service's slot assignment**, append-only. **Done, 19–20
   September.** The service places every arrival by the Long Walk's rule
   (`check_long_walk.php` holds the PHP to the Swift over 600 placements), and
   since 20 September it knows there are ten areas and keeps nine shut:
   `SeedCore/WebGardens/Areas.swift`, `Server/.api/Areas.php`,
   `GET /api/garden`, and a 409 for a plant whose area is not planted yet. A
   table for each area rather than an area column, because `plot`, `side`,
   `tier` and `slot_index` mean a double border on a travel row and would mean
   something else on a knot-garden row.

   **The travel ambassador stands at the head of it**, since 20 September,
   derived rather than stored — §*The ambassador, standing*.

   **The app asks which areas are open** rather than reading a list compiled
   into itself, since 21 September (`PlotService.garden()`), so a phone learns
   that an area has opened on the day rather than at its next update. What it
   was built believing stands in when the service cannot be reached, and errs
   toward *not yet*.

   **A plant is offered to the area its own name belongs to**, from the app,
   since 20 September. That is nine plants in ten refused for now, which the
   app says on the screen before it asks rather than after: a plant whose area
   is still to be planted gets two sentences and no question.
   **A second area, 21 September.** The Quiet Garden is open: its rule is in
   `SeedCore`, its port in `Server/.api/QuietGarden.php`, its plantings in a
   `quiet_garden` table of their own beside the walk's, and `/quiet` draws it.
   An offer now carries the area it is for and is planted there when it is
   answered. That is the point at which *a table for each area* stopped being a
   prediction: the two tables share no column after `encounter`.

5. **The structures**, modelled, per area as each area is built. **The hedge,
   the mown grass and the bench exist**; the glazed frame, the staging, the bed
   edging, the row labels, the tree positions and the knot hedging do not.
6. **The curator's tool.**
7. **The Wild Fields**, once release uploads something.

## The asking, and what a shared plant consents to

**Built 19 September.** Nothing reaches the Long Walk until both gardeners have
said so, and the whole of what stands in for an account is the pair of tokens a
meeting leaves on the two phones. `Server/.api/Offers.php`, `Server/README.md`
§*The plot service*, and `SeedCore`'s `Sharing.swift`.

- **The token is the address, and consent is what it carries.** An offer is
  addressed to the sixteen bytes its recipient minted at that meeting, so only
  that phone can answer it. The service holds a bag of offers keyed by opaque
  bytes and no directory of people at all: it never learns a name, and two
  offers concerning the same pair of gardeners are not linkable.
- **What it does not carry is authenticity.** A service cannot tell two tokens
  minted at a real meeting from two minted by one person on one machine, so it
  cannot tell a real pair of gardeners from somebody planting invented
  crossings. Nobody can plant *somebody else's* plant or answer for them, which
  is the property the address being secret actually buys. Spam is abuse control
  and belongs in front of the service.
- **This supersedes *a plant is published by a plot, proved by a key*** for the
  Long Walk (`WEBSITE.md` §*Who can put a plant there*) and only there. That
  argument is about a page carrying somebody's name, and its premise is that a
  seed is public. A token is not public. A plant's own page, which does carry a
  name, still needs the plot and the sign-in.
- **A plant in the Long Walk carries no name, no note and no date** — the seed,
  both parents and the meeting, which is what a browser needs to grow it. So the
  consent asked on the phone is about one thing: the plant standing where anyone
  walking the garden can come across it. The name-and-note flow `WEBSITE.md`
  specifies is a plant's own page, and it is a second consent with its own
  screen — folding it in here would publish prose on a yes given to a different
  question, which `PHASES.md` forbids.
- **A meeting from before the tokens were kept can never be asked about.** Every
  plant grown before 19 September is in that position. The app says nothing
  about it rather than offering a row that cannot work.
- **A seed that arrived by link leaves no tokens**, because an offer link is
  forwardable and a secret in a forwarded link is held by everybody it reached.
  So a plant grown from a link cannot be shown. Whether the *reply* link should
  carry one — which would let the offerer be reached but not the replier — is
  open, and is a change to the link format.
- **Withdrawing is either gardener's, at any time, without the other.** An
  accepted planting keeps its place, hidden: the walk stays append-only, the
  slot stays taken, and the border is left with a gap, which is what lifting a
  plant out of a border leaves. **Everything else about it is deleted** (24
  September): the seed, both parents, the meeting and the traits the area's
  rule does not read, and the offer keeps only fingerprints (`Server/.api/
  TakenBack.php`, `Offers.php`). An offer nobody answers lapses into a
  withdrawal after thirty days.

## Open questions

- **Whether the app's Thematic arrangement should use these templates.**
  `ARRANGING.md` has the app's Thematic arrangement reuse the site's ten areas,
  so a plant stands in the Crossing in both. If the Crossing is laid out as a
  quadripartite garden on the web, whether a person's own Crossing is laid out
  the same way in the app is a choice. Doing it would mean the templates live in
  `SeedCore`, where both can read them.
- **Whether plots in an area can be walked between**, or only reached from the
  map. The app's pan stops at the plot's edge. The Quiet Garden answered it one
  way for itself by accident: an enclosure is a room, so `/quiet` shows one plot
  and *On* goes into the next rather than panning along a line.
- **Whether a released plant can be found again** by whoever released it
  (`PHASES.md`, still open). The Wild Fields work either way.
- **How the Coppice shows its rotation.** A coupe cut this year and a coupe
  uncut for seven are both true at once; whether a plot's stage is fixed when it
  opens or turns with the real year is a question about what renewal means here.
  **Decided on 24 September**: it turns with the year at the winter solstice,
  and only the ferns on the stools are cut (§*The Coppice, chosen*).
- **Whether a plot can be too empty to open.** The Quiet Garden's rule makes a
  plot with three plants correct; a Long Walk plot with three plants is
  unfinished. Opening a plot only when the last is full says nothing about the
  first days of an area — though no area's first plot is ever quite empty now,
  because its ambassador is in it.

## The Home Ground, chosen

The last area, `ground`, designed on 24 September. Nothing is built. The theme
holds the soil itself, a place you are from, and a kept place, and the name was
chosen because *home ground* carries both the earth and the belonging
(`strings.js`, the comment on `areaGround`). The table above already says what
kind of garden it is: a kitchen garden, rectangular beds 1.2 m wide so no soil
is ever stood on, paths between, crops in rows across each bed. What was left
to choose is what a *crop* is, when every plant is unique.

### The finding that decided it: this area has three crops, and you can see them

The genus is read off the flower (`PlantName.roots`), and the three roots that
mean `ground` belong to three families: **`Cer` is always a spire, `Fen` always
an umbel, `Pell` always a succulent.** Every plant in the Home Ground is one of
three forms, in nearly equal shares, and the three are as unlike each other as
three crops in a vegetable garden. Measured over 2,000 Home Ground plants
(16,990 crossings, 12% of all):

| Root | Form | Share | Height, median (range) | Across, median (90th centile) |
| --- | --- | --- | --- | --- |
| `Cer` — the grain | spire | 32% | 1.35 m (0.59–2.32) | 0.39 m (0.59) |
| `Fen` — the fennel's family | umbel | 35% | 0.93 m (0.40–1.60) | 0.62 m (0.85) |
| `Pell` — the earth's skin | succulent | 33% | 0.47 m (0.19–0.84) | 0.20 m (0.29) |

That is a kitchen garden already standing in the name: spires in a stand, like
a grain; flat umbel heads, which are what carrots, parsnips and fennel are when
they run to seed; low rosettes packed close, like a salad bed. **The crop is the
genus root**, and it is the first reading in the garden that is a fact about a
plant's name and also something a visitor can see without being told.

### Three layouts considered

1. **The rotation — recommended.** Three beds side by side, a crop to a bed,
   rows across each, the tall end away from the sun. A kitchen garden groups
   its crops by family so that a family can move bed together, and here the
   families are the three roots: three beds is a three-course rotation drawn at
   the moment it stands still. Which bed holds which crop is not fixed by the
   plan, as it is not in a rotated garden; it is set by what arrives.
2. **The allotments.** A place you are from, read literally: each plot divided
   into strips, a strip to a gardener, their plants in it. **Rejected on
   privacy first.** A planting carries both its parents' seeds so that a
   browser can grow it, and a gardener's own seed is a parent of every plant
   their meetings make; a strip per seed would gather one person's meetings
   into one place on a public page. That is a map of who met whom, which the
   plot service was built not to hold (§*The asking*: two offers concerning the
   same pair are not linkable). It would also fill worse than the Seedbed:
   most gardeners will share a handful of plants, so most strips would hold
   one or two.
3. **The walled potager.** A kept place, read as *pairidaeza*: four beds round
   a cross of paths, a feature where they meet, a wall round. **Rejected
   because it is two areas already built**: the Crossing's plan inside the
   Quiet Garden's hedge. A kitchen garden's truth is in its beds and rows, not
   in its quarters.

### The plot

- **Three beds, each 1.2 m wide and 4.2 m long**, running the length of the plot
  from −z to +z, their middles at x = −1.65, 0 and +1.65 m. Paths of 0.45 m
  between them and a headland of 0.5 m at each end; the outermost bed edge is
  0.35 m inside the plot, clear of the outline's 0.16 m wander.
- **North is −z**, the end away from the page's midday sun, which lights the
  plot from (−x, +z). A tall row there shades nothing but the headland. A
  kitchen garden puts its runner beans and its sweetcorn at the north end for
  the same reason.
- **The crop sets the spacing**, which is what every seed packet is for. Each
  crop is spaced at about its own median spread, so neighbours meet as a sown
  crop's do:

  | Crop | Across a row | Down the bed | A bed holds |
  | --- | --- | --- | --- |
  | spire | 3, at 0.40 m | 9 rows, 0.45 m apart | 27 |
  | umbel | 2, at 0.60 m | 7 rows, 0.60 m apart | 14 |
  | succulent | 4, at 0.28 m | 13 rows, 0.30 m apart | 52 |

  About half the spires and umbels are wider than the gap to their neighbour,
  and one rosette in eight is, which is a bed at maturity rather than a
  nursery. At most 2% of any crop reaches more than 0.2 m into a path, so the
  paths stay open.
- **A plot therefore holds 42 to 156 plants**, depending on which crops claimed
  its beds; the largest in any simulated run held 93. The Long Walk's page
  already draws three plots of 48, so 93 is inside what a page has done.
- **The nudge is 0.025 m down the bed and 0.05 m along the row.** A row across
  a bed has to read as a row, for the reason a drill does in the Seedbed.

### The rule

Two traits: **the crop decides the bed, the height decides the end.**

1. A bed already sown with this plant's crop and not yet full, oldest plot
   first, beds west to east.
2. Otherwise the first bed nobody has sown, oldest plot first. It takes this
   crop's spacing from then on.
3. Otherwise a new plot, its west bed.

Within the bed, **a plant at least as tall as its crop's cut takes the next
place from the north end** — row by row, west to east along each row — **and a
shorter one the next place from the south end**, east to west, working north.
The bed is full when the two meet.

- **The cuts are each crop's own median**, measured on the 2,000: **spire
  1.346 m, umbel 0.928 m, succulent 0.469 m.** Three cuts rather than one,
  because the three crops barely overlap: a single cut would send nearly every
  rosette to the south end and every spire to the north, and a bed of one crop
  would not be graded at all. The umbel's 0.928 is two millimetres from the
  Long Walk's 0.93, and it is **not** borrowed: the walk's divides the whole
  garden into thirds and this divides one crop in half. The Knot Garden
  refused to make one fact look like two; this is the other side of the same
  rule, two facts that happen to agree.
- **Nothing is ever displaced.** If a bed of a plant's crop has any place left,
  it has a place for this plant, because either end will take it. So the fill
  does not depend on a single height, only on the mix of crops, and no plant
  ever stands at the wrong end.
- **Everything that came in from the north end is at least as tall as
  everything that came in from the south**, in every bed. That is the whole of
  the grading, and it is as much as an append-only bed can promise without
  bands: arrivals come in no order of height, so within each end they stand in
  the order they came.
- **A height is compared only with a cut, never with another plant.** The Long
  Walk, the Orchard and the Cold Frame all ask whether a plant would stand out
  of order against its neighbours; this rule never does. The one place two
  hosts' heights can disagree is at the three cuts, and the nearest of 2,500
  fresh arrivals is 0.09 mm from its cut — nine times `VectorFile.height` — so
  the vector test needs `placementCannotTurn` over the three cuts, as the Cold
  Frame's does.
- **The crop is a fifth trait**, after the Glasshouse's hue. The service cannot
  grow a plant to read its name, so the phone sends the genus root and the
  store keeps it in a column, arriving by both paths as the Seedbed's kind
  does. It is three or four letters, exact on every host, and the PHP port
  compares it as a string and needs to know nothing about botany.
- **The ambassador opens the west bed for umbels.** *Fenunora patentifolia* is
  1.102 m, over the umbel cut, so it takes the first place from the north end
  of the first bed: the north-west corner of plot 0, the head of the garden.
  It is 0.93 m across, wider than nine umbels in ten, and leans a little into
  the row beside it, which the first plant in a bed is allowed to do.

### How it reads in the isometric view

- **The page opens looking up the beds from their south ends.** At the first
  turn the eye is over the (+x, +z) corner, so in every bed the short end is
  nearer than the tall one: the way a gardener looks up a bed. The camera is
  always on a diagonal, so the beds are never seen square-on; two of the four
  turns look up them from the south and two from the north, and in those two
  the spires' north ends stand in front, as every area has turns that are its
  worst.
- **One plot a page**, as the Seedbed shows one: a kitchen garden is a
  rectangle you stand at the end of, and two of them end to end read as one
  garden with a seam.
- **The crop can be told from across the plot.** A spike, a flat head and a
  low rosette are silhouettes nobody takes for each other, so three beds read
  as three crops before anything on the page names them.
- **Everything is soil, and nothing is ruled.** The beds are raised about
  0.08 m and mounded, with soft shoulders down to the path, and their outlines
  wander by a few centimetres (`Organic`), so no bed has a straight edge. The
  paths are the same soil trodden paler and flatter, and **the edge of a path
  is the shoulder of a bed**, not a line drawn between them. No boards: a board
  is a ruled line, and a mounded bed is how a no-dig garden is made anyway.
  The soil is dark, the map's `#4d3b2c` — darker than the Seedbed's tilth,
  which is the same earth raked fine for sowing — and toned per face, as the
  tilth is, because soil is crumbs rather than a surface.
- **No new structure.** The beds are the ground's own relief, as the Seedbed's
  drills are. An empty bed in a new plot is dug ground waiting to be sown,
  which is what an unsown bed in a kitchen garden looks like; the reading the
  Crossing had to escape is the one this area wants.

### The fill, simulated

24 September, before any rule was written. The simulation is **Swift: a small
package at `tools/homeground/` that links SeedCore**, so every height, spread
and root is the garden's own, from `Maturity.bounds` and the name. It is not a
SeedCore test, because nothing about a rule that does not exist yet should run
in CI. `swift run -c release --package-path tools/homeground` prints every
number below; the grown samples are kept in its `.build`, so a second run takes
seconds.

**Four streams**, each placed after the ambassador: the 2,000 the cuts were
measured on; a fresh 500 and a fresh 2,000 they were not; and **a village**:
500 plants from sixty gardeners meeting unevenly, weights falling as one over
rank, every meeting a new crossing of their own two seeds. The village is the
realistic stream and the unkind one. Arrivals come in runs, the crops are no
longer even (39% spire, 42% umbel, 19% succulent) and the heights lean, which
is the Long Walk's warning about a sample drawn from few gardeners.

Six rules were run, to separate what each part of the design buys:

| Rule | Fresh 500 | Fresh 2,000 | Village 500 | Plots with all three crops, fresh 2,000 | Pairs in shading order |
| --- | --- | --- | --- | --- | --- |
| **A** fixed beds (a `Cer`, a `Fen` and a `Pell` bed in every plot), one spacing of 24 a bed, arrival order | 8 plots, 87% held | 31, 90% | 9, **77%** | 25 of 31 | 50% |
| **B** as A, from two ends | 8, 87% | 31, 90% | 9, 77% | 25 of 31 | 77% |
| **C′** claimed beds, one spacing, two ends | 8, 91% | 28, 99% | 8, 91% | 24 of 28 | 77% |
| **C** claimed beds, the crop's spacing, arrival order | 8, 91% | 29, 97% | 9, 92% | 10 of 29 | 50% |
| **D — recommended.** Claimed beds, the crop's spacing, two ends | **8, 91%** | **29, 97%** | **9, 92%** | 10 of 29 | **72–78%** |
| **E** claimed beds, the crop's spacing, three bands of rows | 8, 91% | 29, 96% | 10, **75%** | 11 of 29 | 85–86% |

*Held* is the share of places in sown beds holding a plant. *Pairs in shading
order* is how often, of two plants in one bed standing in different rows, the
northern one is at least as tall; chance is half.

- **D at a fresh 500: 8 plots, 6 of them full, 23 beds sown and 20 full, 91% of
  places held.** At 2,000: 29 plots, 28 full, 97%. In the village: 9 plots, 7
  full, 92%. Within a point of the Knot Garden's 92% at five hundred, the best
  in the garden, and it holds in the stream built to break it.
- **Fixed beds fail the village.** A bed that belongs to a crop in every plot
  waits for that crop, so a garden short of rosettes opens plots for the others
  and leaves a rosette bed half empty in each: 77%. Claiming is the Knot
  Garden's, the Seedbed's and the Cold Frame's move, and it is what makes the
  fill indifferent to the mix.
- **The two ends cost nothing.** C and D put the same plants in the same beds
  and hold the same share; D stands three pairs in four in shading order where
  C stands half. It is grading for free, which is the whole argument for it.
- **Three bands grade better and break in the village.** E stands 85–86% of
  pairs in order and 93–96% of plants in their own band on strangers. But a
  band waits for heights, and when the heights lean the bands run out
  unevenly: 75%, ten plots where D needs nine, and only four of them full.
- **In every bed of every run, everything from the north end is at least as tall
  as everything from the south.** The meeting falls anywhere from 14% to 79% of
  the way down a full bed, which is how uneven the halves of a small crop are.
- **What the crop's spacing costs is variety between plots, not fill.** With
  one spacing a plot usually holds one bed of each crop (24 of 28 plots at
  2,000). With the crop's, an umbel bed is full at 14 and a rosette bed at 52,
  so umbels claim more than half the beds (48 of 86) and only 10 of 29 plots
  hold all three. That is what an allotment looks like — the ground goes to the
  crops that take room, and the salad gets one bed — and it is the price of
  beds that read as crops. At one spacing, 91% of umbels would be wider than
  the gap to their neighbour and half the rosettes less than half as wide as
  theirs: a thicket in one bed and a scatter in another.

### Simulated again on the new shapes, 24 September 2026

The same package, run again after the plants' shapes changed (its samples are
now kept under the name of what the plants grow into, so an old sample cannot
answer for a new SeedCore). **The decided design fills as it did**: rule D holds
8 plots and 91% at a fresh five hundred, 29 plots and 97% at two thousand, and
9 plots and 92% in the village, the same as above, and every bed still stands
everything from its north end at least as tall as everything from its south.
Pairs in shading order are 76%, 76% and 68% (72–78% above); E, three bands,
does worse than it did (83% at a fresh five hundred, 70% and eleven plots in
the village).

What moved is the plants, and it touches two decisions before anything is
built:

| Root | Height, median (range) | Across, median (90th centile) |
| --- | --- | --- |
| `Cer` spire | 1.35 m (0.60–2.32) | 0.47 m (0.70) |
| `Fen` umbel | 0.93 m (0.40–1.60) | 0.67 m (0.95) |
| `Pell` succulent | 0.28 m (0.11–0.61) | 0.38 m (0.51) |

- **The rosettes are nearly twice as wide**, 0.38 m against the 0.28 m they are
  spaced at, so 88% of them are wider than the gap to their neighbour (one in
  eight was), and spires and umbels 63% and 61% (about half were). Six in a
  hundred spires and five in a hundred umbels reach more than 0.2 m into a path
  (2% was the most). *Each crop spaced at about its own median spread* would
  now put rosettes at about 0.38 m, three across and ten rows, thirty a bed:
  worth deciding before the bed is built.
- **The cuts**: spire 1.346 m, umbel 0.932 m, succulent 0.275 m. At the rounded
  umbel cut a fresh arrival in the village stands 0.009 mm from it, under
  `VectorFile.height`, so the built cut will need nudging off it the way the
  other areas' comments describe. The umbel's median is no longer beside the
  Long Walk's cut, which is 0.77 m now; the argument for not borrowing it stands
  without the coincidence.
- The ambassador, *Fenunora patentifolia*, is 1.100 m tall and 1.06 m across.

### Decided, 24 September 2026

Marcus took all five recommendations.

1. **Spacing is the crop's own**: umbels 14 a bed, spires 27, rosettes 52.
2. **A bed fills from both ends**: tall from the north, short from the south.
3. **The paths are trodden soil**, paler than the beds, so the whole plot is
   earth.
4. **The beds are mounded, with no boards**; a path's edge is a bed's shoulder.
5. **The map's glyph shows three beds**, redrawn the same day in `gates.js`
   `LOOK.ground`: three bed outlines, with short upright strokes for the
   spires, flat bars for the umbels' heads and close dots for the rosettes.
