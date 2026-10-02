# Layouts for the ten areas: research and proposals, 2 October 2026

The ten areas place their plants on grids today: rows parallel to a path, blocks of
four, drills, ranks, a lattice of lilies. This document sets out what makes a real
garden pleasing to look at, and proposes two layouts for each area that keep the
area's rule and meaning but drop the grid. It is design only: no site or app code
changed.

**Look at `index.html`** in this folder: each area's *now*, A and B side by side, at
ten plants and as a settled plot. Marcus decides from those pictures. This text is
the reasoning behind them and what each would cost.

## What the pictures are

- **Now** (`<area>-now-10.jpg`, `<area>-now-full.jpg`): the area's workbench on a
  local dev server, captured in headless Chrome at 1280 × 800 (2×) and cropped to
  the plot. *10* is `/dev/<area>?arrivals=10&plot=0`; *full* is
  `?arrivals=500&plot=3`, a settled plot. The Long Walk's are `?from=0&span=1` and
  `?from=2&span=1`.
- **Proposals** (`<area>-a-10.png`, `<area>-a-full.png`, and the same for B): a
  plan, north (z−) up, the page's light from the lower left so shadows fall to the
  upper right. Plants are blobs **coloured by habit** with a dot of their **flower's
  colour family**. Nothing is drawn with a straight line.
  - *10* is plot 0 after the first ten arrivals, the ambassador first.
  - *full* is plot 3 after a thousand arrivals.
  - Two strips: `walk-a-three.png` shows three Long Walk plots end to end, and
    `quiet-a-rooms.png` shows four Quiet Garden rooms turned by their numbers.
- **The plants are invented.** Each area gets a stream of arrivals with the habits
  its genus roots give it (`PlantName.roots`, `Areas.genusHeads`). Heights and
  spreads are near the medians recorded in `docs/WEB-GARDENS.md`, and colour
  families are drawn as unevenly as the garden draws them. Each proposal's rule is
  simulated on that stream (`stats.json`). The numbers are **indicative**: a chosen
  proposal is simulated again on SeedCore's own plants, as every area has been.
- `python3 plans.py <out_dir>` draws every plan again and writes `stats.json`.

| Area | Habits it receives |
|---|---|
| Long Walk | plume, vine, thistle, cushion |
| Quiet Garden | plume, poppy |
| Crossing | orchid, bell, cushion |
| Orchard | vine, thistle |
| Knot Garden | umbel, bell |
| Seedbed | succulent, lotus, spire, reed |
| Cold Frame | lotus, fern, reed |
| Glasshouse | star, poppy, orchid |
| Coppice | fern, star |
| Home Ground | spire, umbel, succulent |

## The principles that matter here

Each principle is named in bold so the proposals can refer to it. Where a source
falls short of the claim, the entry says so.

### From planting design

- **Drifts.** Plant in long, narrow patches rather than blocks, so neighbouring
  groups overlap along the border. Jekyll argued for "long rather than
  block-shaped patches" so that no plant leaves a square hole
  ([*Colour Schemes for the Flower Garden*, ch. III](https://archive.org/stream/cu31924002831117/cu31924002831117_djvu.txt)).
- **Grading.** Run colour along a border from cool at the ends to hot in the
  middle, as Jekyll's main border at Munstead Wood did
  ([National Trust](https://www.nationaltrust.org.uk/visit/surrey/munstead-wood/the-garden-at-munstead-wood-today)).
- **Matrix and scatter.** A quiet repeated ground with conspicuous plants set in
  it. Oudolf and Kingsbury liken it to a fruitcake
  ([Matrix planting](https://en.wikipedia.org/wiki/Matrix_planting)). Scatter
  plants go in singly, quasi-randomly, to break the regularity of blocks
  ([Paintbox Garden](https://www.thepaintboxgarden.com/piet-oudolf-meadow-maker-part-two/)).
- **Random by shares.** Cassian Schmidt's *Mischpflanzung* places species at
  random in fixed shares by height role: structure plants over 70 cm, companions,
  ground cover. Order comes from the height relief, not from rows
  ([JKI](https://wissen.julius-kuehn.de/mediaPublic/UrbanesGruen/FS/SG/05/FS_5_Stadtgruen_1_Schmidt.pdf)).
  It is the horticultural precedent for placing seed-chosen plants without a grid.
- **Repetition.** Repeating a plant or colour at intervals makes a place read as
  "one place" (Oudolf, in
  [Gardenista](https://www.gardenista.com/posts/10-garden-ideas-to-steal-from-superstar-dutch-designer-piet-oudolf/)).
  Without such devices, intermingling becomes "a functional and aesthetic mess"
  ([Rainer, Thinkingardens](https://thinkingardens.co.uk/articles/mingle-or-clump-by-thomas-rainer/)).
- **Formal frame, loose fill.** A curving clipped hedge holds naturalistic
  planting at Bury Court
  ([Gardens Illustrated](https://www.gardensillustrated.com/gardens/country/south-downs-john-coke)).
  Wirtz clipped evergreens into undulating "clouds", formal mass without straight
  lines ([Jacques Wirtz](https://en.wikipedia.org/wiki/Jacques_Wirtz)).
- **Seen from above.** Knots and broderie parterres were "designed to be seen from
  above" ([English Heritage](https://www.english-heritage.org.uk/learn/histories/perfect-parterres/);
  [Knot garden](https://en.wikipedia.org/wiki/Knot_garden)). The page's eye is the
  eye they were made for.

### From the garden traditions

- **The asymmetric triad.** The main stone stands tallest at the rear, with two
  smaller ones in a scalene triangle, and later stones answer the first
  ([NAJGA](https://najga.org/japanese-garden-garden-rocks/)). Odd-number groupings
  come from this tradition. **No empirical study shows odd numbers are
  preferred.**
- **Ma.** The interval between things is part of the composition
  ([ArchDaily, Isozaki](https://www.archdaily.com/882896/arata-isozaki-on-ma-the-japanese-concept-of-in-between-space)).
- **Hide and reveal (*miegakure*).** A partial view creates expectation
  ([NAJGA](https://najga.org/stroll-garden/)).
- **Roji.** A tea garden's stepping-stone path is laid to give "a sense of
  traveling a considerable distance", with a waiting bench before the tea house
  ([Portland Japanese Garden](https://japanesegarden.org/garden-spaces/tea-garden/)).
- **Chahar bagh.** Four quarters divided by water channels meeting at a central
  pool, with sunk beds ([Paradise garden](https://en.wikipedia.org/wiki/Paradise_garden),
  [Charbagh](https://en.wikipedia.org/wiki/Charbagh)).
- **Clumps, varied.** Brown composed with belts, clumps and single trees
  ([Gardens Trust](https://thegardenstrust.org/history-hub/capability-brown-wimpole-hall/)).
  Price mocked clumps "turned out of one common mould"
  ([Capability Brown](https://en.wikipedia.org/wiki/Capability_Brown)), so no two
  should match.
- **Meadow orchard.** Standards in permanent long grass, often on a quincunx
  ([PTES](https://ptes.org/get-involved/surveys/countryside/traditional-orchard-survey/traditional-orchard-survey-faqs/),
  [The Garden of Cyrus](https://en.wikipedia.org/wiki/The_Garden_of_Cyrus)). Paths
  are mown through the long grass
  ([RHS](https://www.rhs.org.uk/lawns/creating-wildflower-meadows)).
- **Rides and glades.** A coppice brings flowers by letting light to the floor.
  Rides and glades are the sunny places, and a wavy ride edge does more than a
  straight one ([Kent Wildlife Trust](https://www.kentwildlifetrust.org.uk/sites/default/files/2024-01/KWT%20Land%20Mgt%20Advice_Sheet%2010%20-%20Woodland%20management%20-ride%20and%20coppice.pdf),
  [Wildlife Trusts](https://www.wildlifetrusts.org/wildlife/managing-land-wildlife/how-manage-woodland-wildlife)).
- **Pond zones.** Marginals stand on a shallow shelf at the edge; lilies root in
  the deep water and want space round each
  ([RHS](https://www.rhs.org.uk/ponds/pond-plants),
  [Bennetts](https://www.waterlily.co.uk/plants/knowledge-base/pond-plant-advice/how-deep-should-pond-plants-be/)).
- **Lazy beds.** Ridges dug by spade, up to 2.5 m wide, whose channels follow the
  slope of the land ([Lazy bed](https://en.wikipedia.org/wiki/Lazy_bed),
  [Oughterard Heritage](https://www.oughterardheritage.org/content/topics/lazy-beds)).
- **Keyhole beds.** A round bed with a wedge-shaped path to a central basket, so
  the whole bed is within reach; developed in Lesotho in the late 1990s
  ([Keyhole garden](https://en.wikipedia.org/wiki/Keyhole_garden)).

### From environmental psychology

- **Coherence, complexity, legibility, mystery.** The Kaplans' four qualities:
  - coherence: a few repeating themes;
  - complexity: richness;
  - legibility: easy to grasp;
  - mystery: the promise of more if you go on.

  ([Hunter & Askarinejad 2015](https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2015.01228/full).)
  Coherence correlated with preference at about r = 0.46 in Stamps's
  meta-analysis ([abstract](https://www.scirp.org/reference/referencespapers?referenceid=1557751)).
- **Prospect–refuge.** People prefer to see without being seen
  ([Appleton](https://en.wikipedia.org/wiki/Jay_Appleton)). The evidence across 34
  studies is mixed, stronger in natural settings
  ([Dosen & Ostwald 2016](https://link.springer.com/article/10.1186/s40410-016-0033-1)).
  Here only an implied occupant can be in a refuge: the bench.
- **Curves.** Curved forms are preferred to angular ones, with a medium effect
  across 61 studies ([Bar & Neta 2006](https://www.semanticscholar.org/paper/Humans-Prefer-Curved-Visual-Objects-Bar-Neta/52b1c06824f96a513c7e9b0f4fed1289b566c028);
  [Chuquichambi et al. 2022](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC10091794/)).
- **A bold curve, finely wandering.** Penn State warns that "wobbly lines feel
  immature" ([Principles of garden design](https://extension.psu.edu/principles-of-garden-design)).
  So the proposals use one big curve with fine irregularity on it, not jitter at
  every scale.
- **Middle fractal dimension.** Preference peaks around D 1.3–1.5
  ([Spehar et al. 2003](https://www.sciencedirect.com/science/article/abs/pii/S0097849303001547)),
  and about 1.3 for landscape silhouettes
  ([Hagerhall et al. 2004](https://www.landscape-portal.org/fractal-dimensions-of-landscape-silhouette-outlines-as-a-predictor-of-landscape-preferences/)),
  with individual differences ([Street et al. 2016](https://pmc.ncbi.nlm.nih.gov/articles/PMC4877522)).
  Clusters within clusters sit there; a lattice sits near 1.
- **Focal point and rhythm.** One focal point per area, and rhythm from
  repetition ([Penn State](https://extension.psu.edu/principles-of-garden-design)).
  The golden ratio's evidence is conflicting
  ([De Bartolo et al. 2021](https://pmc.ncbi.nlm.nih.gov/articles/PMC9787369/)),
  so nothing here relies on it.

### From placing things deterministically

- **Blue noise.** Bridson's Poisson-disc sampling spreads points evenly with no
  lattice ([Bridson 2007](https://www.researchgate.net/publication/242093366_Fast_Poisson_disk_sampling_in_arbitrary_dimensions)).
  Graphics took it from the layout of photoreceptors in the retina
  ([PBR book](https://pbr-book.org/3ed-2018/Sampling_and_Reconstruction/Further_Reading)).
  Plant ecosystems have been laid out with it
  ([Deussen et al. 1998](https://algorithmicbotany.org/papers/ecosys.sig98.pdf)).
- **The sunflower.** Vogel's spiral puts point *n* at radius c√n and angle
  n × 137.508° ([Vogel 1979](https://www.semanticscholar.org/paper/A-better-way-to-construct-the-sunflower-head-Vogel/34d0e5af61c567be060841fbf39958c070edcdc9)).
  **Every prefix is evenly spread and centred, and adding point n+1 never moves
  point n.** That is exactly the garden's rule that a plant never moves. The golden
  angle is also one of Pattern's own subthemes.

## Three moves for every area

These three do more for how the garden looks at ten plants and at a thousand than
any single layout.

1. **Fill so that every count looks finished.** Most areas fill in reading order:
   - the Long Walk from the head of the plot;
   - the Seedbed from the labelled end;
   - the Glasshouse from the door;
   - the Cold Frame's ranks from the west.

   So a plot with ten plants looks like a half-written page. Order each plot's
   places so that every prefix is spread and centred: the focal place first, then
   the place farthest from those already taken (or the next point of a sunflower).
   The Coppice already does this, filling from the middle outward (2, 1, 3, 0, 4).
   It changes only the order in which free places are offered, so no rule's
   counts change and no plant moves. (**Fill from a centre**, **Blue noise**,
   **Coherence**.)
2. **No two plots alike.** At a thousand arrivals an area is 20 to 100 identical
   plots. A plot can take one of a few variants chosen from its number:
   - turned or mirrored;
   - a feature nudged;
   - a glade or a curve moved.

   The Quiet Garden sketches turn each room by its number (`quiet-a-rooms.png`).
   (**Clumps, varied**, **Complexity**.)
3. **Places as literal tables, made offline.** Every proposal's positions are
   generated once and written into SeedCore and the PHP port as numbers, pinned by
   the vector tests, as the Glasshouse's band edges are. Positions come from blue
   noise inside organic outlines, from spirals and from arcs. With no `sin` or
   `pow` at run time, every host agrees to the bit (`.claude/HANDOVER.md`, *The
   libm divergence*), whatever curves made the table.

Every proposal below assumes all three.

## What a change costs, in general

A layout change touches the area's rule and port and their checks, and usually its
drawing:

- the rule: `Packages/SeedCore/Sources/SeedCore/WebGardens/<Area>.swift`;
- the port: `Server/.api/<Area>.php`;
- the checks: `tools/reference/check_<area>.php` and its vectors;
- the tests: `<Area>Tests.swift` and `<Area>VectorTests.swift`;
- the workbench's plan export: `tools/wasm/Sources/PlantWasm/<Area>.swift`;
- the drawing: `Server/assets/js/<area>.js`, plus `water.js`, and the app's
  `Morphology/Organic.swift` and `Structures/` where a structure is new.

**A plot is never re-laid**, so a new layout reaches the live garden either for
plots opened after it or by replanting everything (`tools/replant`), as when the
plant shapes changed.

- **Layout only** means new place tables and the existing ground features drawn
  along new lines.
- **New drawing** means a structure or ground feature the garden has not drawn
  before.

---

## The Long Walk — *travel*

**Now:** three tiers each side of the path, each two staggered straight rows (5, 4
and 3 a row), so the border reads as ranks of plants. 48 a plot.

### A — Interlocking drifts *(recommended)*

Each border's 24 places sit in six long, thin lenses (5, 3, 5, 3, 5, 3) slanting
from the hedge to the path edge, each overlapping the next like slates.

- **A lens is a drift.** It is claimed by the colour family of its first plant,
  the Knot Garden's claim move, so it stays one colour.
- **The height rule holds.** A lens's back end is back tier and its tip front
  tier, so "nothing stands in front of something shorter" still holds by depth.
- **Each plot is graded.** A warm family claims the free lens nearest the plot's
  middle and a cool one the lens nearest its ends. Each plot runs cool–hot–cool,
  and the walk pulses plot by plot (`walk-a-three.png`).

**Why:** *travel* is the eye carried along. The slant and the repeating colour
carry it. (**Drifts**, **Grading**, **Repetition**, **Coherence**.)

**With 10:** ten strokes of colour round the middle of plot 0, on both sides,
where the built walk shows a gap-toothed row from the head.

**With 1,000:** 23 plots, 95% of settled places held. The built rule run on the
same stream gives 22 plots and 99%. Claiming by colour costs a few points of fill
and makes every drift legible.

**In code:** layout and rule. `LongWalk.swift`'s slot table becomes lenses, and
`place(for:)` gains the lens claim and the warm/cool order. The drift cap of five
becomes the lens. The port, `check_long_walk.php`, the vectors and `LongWalkTests`
all change. **No new drawing.**

### B — The walk that bends

The path swings in an S through each plot, mirrored plot to plot so the walk
meanders.

- The border is deep inside each bend and shallow outside it.
- Places are blue noise; a plant's tier is its distance from the path.
- So the tallest plants stand on the promontories inside the bends and hide the
  next stretch.

**Why:** *travel* as what lies round the bend. (**Hide and reveal**, **Mystery**,
**Curves**, **Blue noise**.)

**With 10:** a few plants either side of a winding path, spread from the middle.

**With 1,000:** 27 plots, 80% held. The shallow outsides of the bends have few
back places, so tall plants wait. That is the price.

**In code:** layout and path geometry. Two mirrored slot tables in
`LongWalk.swift`, the port and checks. `longwalk.js` draws the mown path, its
verges and the rill along the S; the rill already meanders. The gateways and the
neighbours' slabs are unaffected. **Layout only, with a path drawn along a curve.**

## The Quiet Garden — *peace*

**Now:** a specimen by the bench and three groups of three in three corners at the
hedge's foot, a round pool in the middle. Every room is laid the same way round.
Ten a plot, and fifty-one rooms at five hundred arrivals.

### A — An asymmetric room *(recommended)*

The ten become one, five, three and one:

- the specimen by the bench;
- a group of five in the far corner across the water, the view from the seat;
- a group of three along a side, a third of the way;
- one plant alone that repeats the five's colour across the lawn.

The pool sits off-centre toward the bench, with three stepping stones from the
seat to the water. Each room is turned and mirrored by its number, eight ways, so
the rooms differ (`quiet-a-rooms.png`). The live garden never sends this area a
lily (`Areas.genusHeads`), so the pool is still water.

**Why:** *peace* as the pause between things. The lawn is the largest part of the
composition, and the bench looks across open grass and water with the hedge
behind. (**Ma**, **The asymmetric triad**, **Repetition** through the echo,
**Focal point**, **Prospect–refuge**, **No two plots alike**.)

**With 10:** the specimen, then the five's back plant, then the three's: a scalene
triangle across the room by the third arrival. Ten arrivals fill most of room 0
and open room 1, as now.

**With 1,000:** 101 rooms, every settled one full, the same as the built rule on
the same stream.

**In code:** layout and a small rule change. `QuietGarden.swift`'s corners become
groups of five and three plus the echo, which takes the five's colour or a tone of
it, and the rooms turn by plot number. The port, `check_quiet_garden.php`, the
vectors and `quietgarden.js` (the pool's place, the bench by turn) all change.
**New drawing:** three stepping stones, small.

### B — Clumps on a lawn

The hedge is the belt. The plants stand in two free clumps on the lawn, five and
three, each tallest in its middle so it reads from every side. The specimen stands
by the bench and one plant at the water's edge. The pool becomes a long serpentine
water along one side, which the bench looks across.

**Why:** peace as a park in small. (**Clumps, varied**, **Prospect–refuge**,
**Curves**, **Ma**.)

**With 10 and 1,000:** the same counts as A.

**In code:** as A, and a serpentine outline for `sinkPool` in `water.js`, which
today takes a round or plot-shaped rim. **New drawing:** the serpentine water.

## The Crossing — *meeting*

**Now:** two straight mown paths cross at a paved round. Each square quarter of
rough grass holds six places in a fixed 3-2-1 block. From the page it reads as a
chequerboard.

### A — Four ways turning in *(recommended)*

The four paths curve in from the middle of each side and all turn the same way, so
they meet the round tangentially. The quarters become four comma-shaped beds (the
boteh of Persian textiles) wrapped round the centre. Places stand on three arcs
round the basin, three, two and one, all facing in. The rule is unchanged: the
emptiest quarter first.

**Why:** *meeting* as four ways converging and people gathered in a ring. The
four-part plan is kept as a whirl rather than a cross. (**Curves**, **Chahar
bagh**, **Focal point**, **Coherence** through rotational repetition.)

**With 10:** the emptiest-first rule puts the first plants on the inner arcs of all
four beds, so ten make a ring round the basin.

**With 1,000:** 47 plots and 90% held, unchanged: it is the same rule with its
places moved.

**In code:** **Layout only.** `Crossing.swift`'s spots, the port and the vectors
change; ranks and quarters do not. `crossing.js` draws the mown paths along curved
centrelines, and the round stays as built.

### B — Chahar bagh: rills and sunk quarters

The cross is kept, drawn by hand.

- A narrow rill runs down each path from the basin to the plot's edge, the four
  rivers.
- Each quarter is sunk a hand and bounded by an arc round the basin.
- Its six places stand on arcs centred on the basin.

**Why:** the oldest plan for a meeting place, made legible. (**Chahar bagh**,
**Focal point**, **Formal frame, loose fill**.)

**With 10 and 1,000:** as A.

**In code:** layout plus water. `raiseRill` already draws the Long Walk's rill and
can draw four here. **New drawing:** the sunk quarters as relief in `crossing.js`.

## The Orchard — *kinship*

**Now:** five trees on a quincunx, four places round each trunk, a mown disc under
each tree in meadow. From above it reads as the five on a die.

### A — A meadow orchard *(recommended)*

The trees stay on the quincunx, each nudged a little by the plot's number, because
old orchards are never true. Each guild becomes a crescent at its tree's canopy
edge, turned toward the middle tree and graded outward as now. The discs give way
to mown crescents joined by one mown way that wanders through the long grass from
edge to edge. The middle tree keeps its ring of four, which has no ranks.

**Why:** *kinship* as households turned toward each other, and a way that leads on
out of the plot. (**Meadow orchard**, **Curves**, **Mystery**, **No two plots
alike**.)

**With 10:** the middle tree's four, then the first crescent, which is composed
from the start.

**With 1,000:** 51 plots, every settled plot full. The rule is unchanged.

**In code:** layout, with tree positions per plot. `Orchard.swift`'s guild offsets
become crescents and its trees a per-plot table. The port, the vectors and the
`placementCannotTurn` margins change. `orchard.js` draws the mown way, which is new
ground in meadow, and the crescents in place of the discs. **New drawing:** the
mown way, small, as a meadow cut rather than a structure.

### B — Clumps of kin

The five trees are regrouped as a clump of three and a pair, turned by the plot's
number. Each guild stands on the side of its tree away from its clump-mates, so
planting rings each clump, and the meadow sweeps open between them with a mown way.

**Why:** families as clumps of different sizes. (**Clumps, varied**,
**Ma**.)

**With 10 and 1,000:** the same counts as A, 51 plots.

**In code:** as A, with tree positions per variant (structures, not plants).

## The Knot Garden — *pattern*

**Now:** a square edging and two bands each way, bowed, crossing four times. There
are eight compartments of four, each opposite pair one colour, and four plants
stand in a fixed square in each.

### A — Interlaced rings *(recommended)*

A ring round the middle and four rings interlaced with it, over and under in turn,
inside a softened square edging. The eight compartments are the four lenses where
rings overlap and the four outer crescents. Opposite lens and lens, and crescent
and crescent, are the pairs, so the colour rule is untouched. Plants run along each
lens and crescent as a ribbon of colour, and the basin stays in the middle.

**Why:** *pattern* drawn the way knots were meant to be seen, from above, in
curves rather than boxes. (**Seen from above**, **Curves**, **Formal frame, loose
fill**, **Coherence**.)

**With 10:** the first colours claim their pairs and show as matched ribbons. A
fifth colour among the first arrivals opens a second plot, as it would now.

**With 1,000:** 33 plots, 98.5% held. The rule is unchanged.

**In code:** layout plus hedge geometry. `KnotGarden.weave` becomes rings: each
ring is four bowed runs, which `Organic.hedge`'s `bow` can almost draw, or a new
`Organic.ring`. The compartments get new place tables, and `clearance(x:z:)`, the
port, the vectors and `knot.js` change. The under-band stopping against the
over-band is already how the weave is drawn. **New drawing:** hedges round a
circle.

### B — The weave kept, each compartment a mirrored cluster

The present knot stays. The four places in each compartment become a golden-angle
cluster, turned with the compartment so the planting has fourfold symmetry about
the middle. A pair reads as a mirror and a block as a clump.

**Why:** Pattern's own golden angle, in the smallest change that loses the square of
four. (**The sunflower**, **Coherence**.)

**With 10 and 1,000:** as A.

**In code:** **Layout only:** the spot table in `KnotGarden.swift` and the port,
and the vectors.

## The Seedbed — *beginnings*

**Now:** six straight parallel drills of eight, each labelled at the west end.
Flooded drills and dry ones are interleaved in the order they were claimed.

### A — Drills on the contour *(recommended)*

The six drills curve as concentric arcs, the way rows follow a slope. Water kinds
claim drills from the low side and dry kinds from the high side, so the flooded
drills lie together like paddies. The labels stagger along a curve.

**Why:** *beginnings* as worked ground: a nursery is rows, and rows that follow
the land look grown rather than ruled. (**A bold curve, finely wandering**,
**Lazy beds** as precedent, **Coherence**: the water together.)

**With 10:** dry drills at the top, flooded at the bottom, one or two plants each.
A seventh kind opens plot 1, as now.

**With 1,000:** 36 plots, 82% held. The simulation has fewer kinds than the
garden's 46, so the built figure (66% at 500) is the one to trust. Claiming by side
changes no count.

**In code:** layout and one line of rule. `Seedbed.swift`'s drill spots go on arcs
and unclaimed drills are offered by element. The port, the vectors and
`seedbed.js` change (the drills as curved relief, the labels). Flooding along an
arc uses `water.js` as it is. **Layout only.**

### B — The crozier

Six drills spiral out from a small pool, like a shoot unrolling. The labels stand
by the pool, and each drill is sown outward from it.

**Why:** *beginnings* as growth from a point. (**Fill from a centre**, **The
sunflower**, **Curves**.)

**With 10:** plants gather by the pool at the start of each arm, composed.

**With 1,000:** as A.

**In code:** drill spots along spirals, the pool by `sinkPool`, and the labels.
**New drawing:** a pool in the Seedbed, small.

## The Cold Frame — *waiting*

**Now:** two frames of twelve at the back, and a tank of thirty-nine in six
staggered rows of seven and six. Reeds and lilies take the same places.

### A — A pond planted as a pond *(recommended)*

The tank becomes a pond with a wandering, kidney outline. Reeds take the marginal
shelf in five clumps of three, and lilies take the open water on a sunflower from
its deepest point. A pond of three lilies is three in the middle, never three in a
row. There are still 39 water places, about half a metre apart, a little closer
than the tank's diagonal. The frames are unchanged, set a little askew.

**Why:** *waiting* as still water planted the way water is. (**Pond zones**, **The
sunflower**, **Fill from a centre**.)

**With 10:** the ambassador lily in the middle with a few round it, a clump of
reeds at the edge, seedlings under glass.

**With 1,000:** 19 plots, 91% held. Reed fills the margin first and spills into the
open water, as a lily does into the margin, so neither strands a plot.

**In code:** layout and a habit test. `ColdFrame.swift`'s tank becomes margin and
open-water tables, with reed to the margin and lily to the open water, each falling
back to the other. The port, the vectors and `frame.js` change: the pond's outline
for `sinkPool` with its bank. **Layout only, with a new outline.**

### B — Three pools and a stepping-stone path

Three pools of unequal size are linked by stepping stones from the plot's edge to
the frames, which stand at the path's end like the waiting bench of a tea garden.
Lilies fill the largest pool first.

**Why:** *waiting* as the tea garden's waiting place. (**Roji**, **The asymmetric
triad** of three pools, **Ma**.)

**With 10:** the large pool begins and the others wait.

**With 1,000:** 26 plots against A's 19. The three pools hold 27 water places where
the tank holds 39.

**In code:** **New drawing:** stepping stones and three pools. The places change,
and the rule gains a pool order.

## The Glasshouse — *light*

**Now:** a span house with two-deep straight staging along one side, the spectrum
in a line from the door, and the border along the back. Pots stand 0.30 m apart,
and 99% of plants are wider than that (WEB-GARDENS §*The at-scale work*).

### A — The colour wheel *(recommended)*

The house is round. The staging runs round its inside as a ring of 24 pots, with
the twelve hue bands going round as a colour wheel. The door is in the green gap,
the hues these plants avoid, where the bench's two ends already meet. The border
becomes a round bed in the middle, under the dome's height, filled from its
centre. Pots stand 0.43 m apart.

**Why:** *light* as the spectrum, and the area's colour rule legible at a glance,
which is item 3 of the at-scale work. (**Focal point**, **Legibility**,
**Coherence**, **Curves**.)

**With 10:** pots scattered round the ring at their hues; the wheel already reads.

**With 1,000:** 37 plots, 88% held. The rule and the count of places are as built,
so the built fill holds.

**In code:** the largest drawing job of the twenty. **New drawing:** a round
glasshouse in place of `Organic.spanHouse`, and ring staging bent from
`Organic.staging`, in both the app and the site. `Glasshouse.swift`'s spots map
band to angle, and the port, the vectors and `glasshouse.js` change.

### B — A crescent of staging

The span house is kept. The staging curves as a two-step crescent along the sunny
side, the back step higher, and the spectrum runs along it as an arc. There are
ten bands of two pots. The border along the back fills from its middle out.

**Why:** the same spectrum, in the house that exists. (**Curves**, **Focal
point**.)

**With 10:** a short arc of colour.

**With 1,000:** 42 plots against A's 37, because 28 a plot is fewer than 32.

**In code:** the band edges are cut again to ten (a rule change), and the staging
is bent along an arc. **Layout plus bent staging.**

## The Coppice — *renewal*

**Now:** three straight parallel bands divided by two rides, five stools in a line
down each band, and floor places in rows either side.

### A — Coupes round a glade *(recommended)*

Three rides meet at a small sunny glade and curve out to the edge, dividing the
plot into three coupes of unequal size.

- Stools stand scattered in each coupe, as blue noise.
- The stars stand in clumps of three along the ride edges, where the light is.
- The glade, the ride angles and the coupe sizes come from the plot's number.

The rotation is unchanged: one coupe is cut pale each winter.

**Why:** *renewal* as light let in; in a real wood the flowers come where the rides
and glades are. (**Rides and glades**, **Clumps, varied**, **Mystery**, **No two
plots alike**.)

**With 10:** the glade, a few stools and a clump of stars at the first ride.

**With 1,000:** 32 plots, 99% held. The rule is unchanged.

**In code:** layout and ground. `Coppice.swift` gets per-variant place tables
(stools, floor, and the coupe each belongs to). The port, the vectors and
`coppice.js` change: three rides meeting at a glade replace two parallel ones, and
the litter is lighter in the glade. **Layout only, with new ride geometry.**

### B — Sinuous bands

The three bands are kept but curve gently across the plot. Stools stand in a loose
zigzag, and the floor's stars in threes on alternate sides.

**Why:** the present coppice without its rule lines. (**A bold curve, finely
wandering**.)

**With 10 and 1,000:** as A.

**In code:** **Layout only.**

## The Home Ground — *ground*

**Now:** three straight beds 1.2 m wide side by side, crops in rows across, and a
trough at the end of a path. 42 to 90 a plot by crop.

### A — Lazy beds that follow the land *(recommended)*

The three beds curve gently together, as hand-dug ridges follow the ground, with
rows running across the curve. The bow alternates from plot to plot. The rule is
unchanged: the crop claims the bed, tall plants come from the north end and short
from the south.

**Why:** *ground*, the soil and a place you are from, as earth worked by hand.
(**Lazy beds**, **A bold curve, finely wandering**, **No two plots alike**.)

**With 10:** the ambassador's umbel bed begun from both ends, and a second crop
claiming the next bed.

**With 1,000:** 19 plots, every settled bed full.

**In code:** **Layout only:** spots along a curved centreline in
`HomeGround.swift` (a table per variant), the port, the vectors and `ground.js`
(beds as curved relief).

### B — Three keyhole beds

Three round beds, each with a notch, are each claimed by a crop. Crops stand in
arcs, tall at the back of each ring and short at the notch, and the notches face a
shared trough.

**Why:** the kitchen garden gathered round its water. (**Keyhole beds**, **Focal
point**, **Fill from a centre**.)

**With 10:** one bed begun from its back.

**With 1,000:** 24 plots against A's 19, because round beds hold about 49 a plot
against about 69.

**In code:** **New drawing:** keyhole beds as relief, and arcs for places.

---

## Decisions for Marcus

Each question has the recommendation first. The pictures are in `index.html`.

**For every area**

1. Fill so every count looks finished (focal place first, then farthest-first)?
   **Yes** / no.
2. Vary each plot from its number (turned, mirrored, a feature moved)? **Yes,
   where the area allows it** (all but the Knot Garden and the Glasshouse) / yes,
   everywhere / no.
3. When a layout is chosen, replant the live garden so old plots match? **Yes,
   replant** / new plots only.

**Area by area**

4. Long Walk: **A, interlocking drifts** / B, the walk that bends / keep the rows.
5. Long Walk, if A: grade each plot cool–hot–cool? **Yes** / no.
6. Quiet Garden: **A, the asymmetric room** / B, clumps on a lawn / keep the corners.
7. Crossing: **A, four ways turning in** / B, rills and sunk quarters / keep the cross.
8. Orchard: **A, the meadow orchard** / B, clumps of kin / keep the discs.
9. Knot Garden: **A, interlaced rings** / B, the weave with mirrored clusters / keep it.
10. Seedbed: **A, drills on the contour** / B, the crozier / keep straight drills.
11. Cold Frame: **A, the pond planted as a pond** / B, three pools and stepping
    stones / keep the tank.
12. Glasshouse: **A, the colour wheel** / B, the crescent of staging / keep the
    span house.
13. Coppice: **A, coupes round a glade** / B, sinuous bands / keep the bands.
14. Home Ground: **A, lazy beds** / B, keyhole beds / keep straight beds.
