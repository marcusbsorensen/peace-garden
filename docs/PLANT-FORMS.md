# Plant forms: getting off the tower

Written 1 September 2026 as a build spec, from looking at three plants side by
side and finding they were the same plant three times. **Built 2 September.**
This is the record now rather than the plan; where the two differ, the
difference and the reason for it are below.

## What is live

`Inflorescence` is a property of the archetype, and every archetype claims one.

### `.raceme` — blooms on the axis

What every plant was before this, unchanged, and still the commonest. Six
archetypes: **spire, star, bell, vine, succulent, fern.** It is named so that
the other two read as choices rather than as exceptions.

### `.head` — stalks off the upper stem, a bloom on each

**umbel** and **plume**, separated by one number, `branchSpread`.

- **At 0 — a flat-topped head.** The stalks leave over a short stretch near the
  top, and every tip aims at the same height, so a stalk from lower down simply
  has further to climb and comes out longer. Measured on the umbel that ships:
  five tips within 2.4mm of each other on a 63cm plant, and a head 49cm across.
  That levelling is the whole reason a corymb reads as a table; without it the
  head is a bundle sitting on the tip, which is what the first attempt looked
  like.
- **At 1 — an open spray.** The stalks leave over half the stem, their angles
  vary far more, and their targets are scattered rather than levelled. Measured
  on the plume: tips spread over 16cm, a head 77cm across. Still longer stalks
  low down, because the same climb rule is doing the work — just no table.

Stalks are set out on the golden-angle divergence the leaves use, so they
spiral rather than lining up in a plane. A stalk starts at 45% of the stem's
radius where it leaves it and runs out to a point through `apexPoint`, the same
way the stem's own tip does: a stalk is a stem and should end like one.

### `.solitary` — a bare stem, one much larger bloom

**poppy, orchid, lotus, thistle.** No branching, few leaves, everything in one
terminal flower. Fewer blooms is what buys the size, and the plants should look
like they cost the same.

## Where the build departed from the spec

Three places. Each was a decision the spec had made, and each is recorded here
rather than quietly changed.

### The enum is `Inflorescence`, not `Form`

`Genome.Form` already exists — archetype, symmetry, vigour — and a bare `Form`
inside `Genome` resolves to that one, which is where the new field has to live.
`Inflorescence` has no collision, and `.raceme`, `.head` and `.solitary` are
inflorescence types in the botany the file already borrows from, so the precise
word costs nothing.

### `bloomScale` is 1.7, not 2.2, and three petal scales came down with it

The spec put a solitary's bloom at "around 2.2× the bloom scale of a raceme's"
and flagged it as the number most likely to be wrong first time. It was, but not
by being too large — **by compounding.** Poppy, orchid and lotus already carried
`petalLengthScale` of 1.6, 1.5 and 1.4, which is how a large flower was got when
inflating the petal was the only lever. At 2.2 on top, a poppy came out about
three and a half times a spire's, and what it drew was a satellite dish: the
centre dome is sized off the petal, so the widest, flattest part of the flower
grew fastest of all.

Those three `petalLengthScale`s are 1.0 now — `bloomScale` says the thing they
were saying — and the scale is **1.7**. Thistle is the exception at **2.4**,
because its petals are bracts at 0.4 and stay that way; its head is made of many
small ones, so it needs more of the form's scale to reach the same size.

### Thistle's `nodeScale` came down to 0.55

The spec said a solitary is the existing apex bloom "with `bloomsAtNodes` off and
`nodeScale` down". All four solitary archetypes already had `bloomsAtNodes` off —
the spec's table says poppy "blooms all the way up" and that was never true — so
the only part left to do was thistle's node count, which was still at 1.

## Two defects the tests caught that no render would have

Both are in `testAHeadDividesGraduallyRatherThanAllAtOnce`, which walks
`heightScale` in four hundred steps and asks whether any one of them stands out
from the rest. Neither is visible in a render at any single age, because both
are about the transition between ages.

1. **The tip was quantised to an integration step.** A stalk stopped at the
   sample *after* it crossed its target height, so as the plant grew and the
   stalk lengthened, the step it stopped on jumped from one to the next and the
   whole head snapped outward — about two and a half per cent of the plant, in
   one frame, while somebody is watching the head open. It stops at the
   crossing now, interpolated.
2. **A head's first stalk arrived four millimetres long.** Two guards in a row —
   `vigour > 0.02` and `reach > stemLength * 0.02` — and the coarse one bit
   first, so stalks appeared at a visible length instead of growing out of the
   stem. The reach guard is the only one that binds now, at a thousandth of the
   stem, and it exists solely against degenerate geometry.

Worth noting what made the test able to find them: it asks whether the largest
step is out of line with the typical step, rather than comparing against a fixed
threshold. A fixed number is either looser than a pop or tighter than the growth
itself, and the first two attempts at it were each in turn.

## The one join that was never closed

Three joins on this plant get a lid, and the reasons are written beside each:
the foot of the stem, the base of every stalk, and the growing point, which
closes itself by running its radius out to nothing. **The join between a flower
and the tip it grows from got nothing**, and it is the one join a reader is
looking straight at.

`addBloom` stands the flower off its tip by eight per cent of a petal —
`origin = sample.position + axis * petalLength * 0.08` — so that a bud is a body
rather than a cone closing on a point. Petals and centre are all built from
`origin`; the stem or stalk ends at `sample.position`; nothing was drawn between
them. The sepal collar spanned it where there was one, which is why the sepals
are laid from `sample.position` rather than from `origin` — but
`chance("bloom.hasSepals", 0.7)` means **three plants in ten had an open join**.
Across 400 seeds, 108 of the 357 bloom-bearing plants had no collar.

**It survived this long because it is usually covered by accident.** `addDome`
draws the upper hemisphere only, so the centre's rim is a flat circle at
`origin`, and that circle is two to six times wider than the stand-off is tall.
On an upright head it overhangs the tip and the stalk reads as disappearing
behind the flower rather than stopping short of it. A head that nods far enough
carries the rim away sideways and leaves the join in the open — seven of those
108 nod past 1.2 radians.

The gap itself is not small where it does show: a median of 1.45 per cent of the
plant's height, 3.9 at the ninetieth centile and 7.5 at the worst, which on a
plant drawn seven hundred points tall is ten points, twenty-seven, and fifty-two.

**The fix is the answer the other three joins already take**: a shallow dome in
the stem's own material at `sample.position`, drawn for every bloom. It rises
along the bloom's own `axis` rather than the stem's tangent, because that is the
line the stand-off was taken along, so it spans the gap at any angle a head can
nod to; and it is narrower than the centre above it, so it sits inside the
flower's own footprint. On the seventy per cent that have a collar it is under
it and is never seen.

`testAFixedSeedAlwaysDrawsTheSameMesh` moved, which is the test doing its job:
vertex counts up by 192, 28 and 24 — one receptacle per bloom, and `vector-a`'s
umbel carries eight. **Every width and height was unchanged**, which is the
number worth reading: the dome reaches nowhere the plant did not already reach.

## How it was checked

| | |
| --- | --- |
| **72 SeedCore tests** | Up from 63. Nine new in `PlantFormTests`. |
| **Determinism** | `testAFixedSeedAlwaysDrawsTheSameMesh` pins vertex count and bounds for three fixed seeds, which between them happen to cover all three forms. It is what would notice a renamed `GeneSource` key rather than an added one. |
| **The twelve, side by side** | `tools/preview/archetypes.py`, written for this. The acceptance test the spec asked for: if two tiles share a silhouette, the forms are not carrying enough. |
| **A head over its life** | `archetypes.py --archetype umbel --stages`, plus the continuity test above. |
| **In the app, on a simulator** | All four cases looked at on an iPhone 17 Pro: a raceme (unchanged), a solitary, a flat-topped head, a spray. The joins where a stalk leaves the stem are domed like the foot of the stem and read closed. |
| **Device build** | `generic/platform=iOS`, clean. |
| **The derivation reference** | Still agrees. The new keys are new, so CI's second implementation is untouched. |

To plant a chosen form on a simulator, write the seed into
`Library/Application Support/PeaceGarden/garden.json` in the app's data
container and relaunch; `defaults write app.peacegarden developer.clockShift
-float 3456000` winds it to maturity. Far quicker than reinstalling until the
draw obliges.

## Nothing new has to cross

`Pollination` is untouched, and this was true as written. The archetype is drawn
from the seed, a crossed seed is a new seed derived from both parents, and the
form comes free with the archetype the child draws. Every new per-plant trait is
drawn the same way against the child seed, so both phones reach the same head
having sent each other nothing.

`testBothSidesOfAMeetingGrowTheSameForm` says so over sixty meetings.

The new keys are `stem.branch.count`, `stem.branch.spread` and
`stem.branch.angle`. **Nothing already there was renamed**, which is the only
property here that could not have been repaired afterwards.

## Habit: how wide a plant stands

Added 24 September 2026, as a prototype for looking at. **Every plant was a
stick.** Across six thousand seeds the median plant was a metre tall and
forty-five centimetres across, height over spread 2.15, and six in a hundred
were wider than tall — nearly all of them plumes. The inflorescence work above
gave the tops of plants somewhere to go; nothing gave the bottoms anywhere.
Leaves sat only on nodes between 16% and 90% of the way up the stem, and a
leaf's length was drawn without reference to the stem, so spread plateaued near
half a metre whatever the height.

`ArchetypeProfile` now carries a habit as well as an inflorescence, and
`Genome.Habit` is drawn from it under new `habit.` keys:

- **Crown leaves.** Leaves from the foot of the stem, outermost first, each one
  in smaller (`crownTaper`) and more upright than the last, on the golden angle.
  That one rule is a rosette, a fern's vase and a poppy's clump. Most families
  get a few as a basal clump; `rosette` families carry *all* their leaves there
  and their stem becomes a flowering stalk — **succulent, fern, orchid, lotus**.
  A rosette that does not flower keeps only a stub of stem.
- **Crown leaves arch rather than sag.** The old sag pushes a straight midrib
  sideways, which kinks a near-upright blade. An arch turns the midrib along its
  length at constant curvature, capped so the tip never goes below the crown.
- **Pads** (lotus): round, peltate, barely cupped, overlapping, on short
  curved petioles drawn as leaf. The lotus's stem is sized from its pads, so the
  flower — smaller than a pad, opening wide — stands just clear of them: a
  water lily rather than a flower on a stalk over some leaves.
- **Fleshy leaves** (succulent): a second surface bowed the other way, so the
  leaf has a body; smooth (no teeth, veins or deep fold, which crumpled it) and
  pointed. The centre opens rather than standing up (`crownRise`), and the tips
  turn up only a little — both the other way, and a rosette closes into a box.
- **Pinnae** (fern): fronds cut nearly to the midrib, so a frond from the crown
  still reads as a fern rather than an agave.
- **`leafReach`**: stem leaves are scaled by the stem's height, part-way, so a
  tall plant is not a twig. Kept off `foliage.length`, which the epithets read.
- **`nodeZone`**: where the nodes sit, per family — low and short on a poppy.

**Young plants are no taller than they were.** Crown leaves open first, and at
first they grew at the stem leaves' rate, so a young fern came out a fifth taller
than before — over the Cold Frame's glass and level with the Coppice's stars. A
crown leaf now grows with the plant's height by as much as it stands upright:
a fern's fronds wholly, a succulent's lying leaves hardly at all.

A basal leaf is held to sixty centimetres however tall its plant, so that
bells and stars are fuller at the foot without wearing rhubarb.

**Names do not move.** `leafCount` is still nodes times leaves per node, the
count the epithet reads; crown leaves are added on top. No existing key was
renamed or re-ranged, and the archetype draw is untouched. Heights did move for
six families — fern, orchid, lotus, succulent, star, plume — because their
habit changed, and a plume's spray reaches a little less far.

Measured on the same six thousand seeds: height over spread 2.15 → 1.28,
wider than tall 6% → 31%, under half a metre 6% → 22%, widest plant 2.2m →
1.45m, median height 0.99m → 0.85m. Spire, vine and thistle stay towers.

Drawn young at `ColdFrame.drawn` the tallest front and back plants in the Cold
Frame are 0.32m and 0.34m (0.38m and 0.45m before), and at `Coppice.cutDrawn`
the tallest fern is 0.36m, as before. The shortest are lotuses and succulents
at 0.04–0.06m — a bud on a short stalk over pads, a young rosette — under the
0.08m the Cold Frame's test asks of a seedling. A low plant is legible by its width;
whether the frame should ask that of it is for when the areas are re-measured.

**Not yet done**: the areas' cuts, the recorded vectors and the Python port all
still describe the old shapes.

## What holds a flower from beneath

Added 24 September 2026. **The ring under every flower was its centre.** The
centre was a dome sized by the gene alone — a lotus's reached nine-tenths of a
petal — centred on the single point every petal sprang from, so the petals
pierced it and its rim hung outside them. It was open underneath, and the web
lights back faces, so from below it was the inside of a bowl. Nothing green sat
under the petals; seven plants in ten had reflexed sepals whatever they were.

- **The centre is at most a third of a petal**, capped in `addBloom` rather than
  in the gene, so the gene still orders centres and no draw moved.
- **Petals stand on its rim**, at nine-tenths of its radius, shortened by half
  of that so the flower is as wide as it was.
- **A closed body underneath**, from a point on the stalk to just outside the
  centre's rim, where it turns in under it: the centre's dome and it are one
  closed shape, so there is no inside to show from any side. What it is is the
  family's (`Calyx` on `ArchetypeProfile`, carried on `Genome.Bloom`): a small
  green cup (lotus, bell, spire, vine, succulent, plume, fern); a wide shallow
  one (star); a bulbous urn of scales tapering into the stalk (thistle); and in
  the stem's own colour, a swelling (poppy), a thickened stalk (orchid) or a
  bare lid (umbel).
- **Sepals are carried the family's way** (`Sepals`): reflexed on a star, five
  slender spreading lobes on a bell, short lobes held up against the petals on
  spire, vine, succulent and plume, none on poppy, umbel, orchid, thistle,
  lotus and fern. `bloom.hasSepals` still decides which plants show them, except
  a bell, which always has its five.
- **A new mesh role, `calyx`**, for the cup and the sepals: the leaf's own
  colour, fresh, where the stem's came out dark olive. It is last in `MeshRole`
  because the web and the WebAssembly buffer name a role by its index. Every
  place that lists roles has it: `PaletteRamp` (colour and relief), the app's
  `GradientTexture` and `PlantSceneBuilder`, the wasm bake in
  `tools/wasm/.../Exports.swift`, and `ROLES` in `Server/assets/js/plant.js`.

Ported to `tools/preview/plant_model.py` on 24 September 2026, with the habit
above and the petal outline below; see its README for what the port still
lacks.

## A petal's outline

Added 24 September 2026. **Every petal ended in a point.** One profile drew
petals and leaves alike, `bladeProfile`: a lens whose width falls to nothing at
the tip, with the tip gene (0.6 to 2.4, drawn the same for every family) raising
it to a power, so four petals in five were drawn out into a concave needle. It
was sampled at thirteen even rows, so the edge was a polygon of twelve straight
sides and the tip, where a round end has all its curve, was one straight cut.
A poppy or a water lily read as a star of spikes.

- **The outline is the family's** (`PetalOutline` on `ArchetypeProfile`, carried
  on `Genome.Bloom`). Round for ten families; pointed for the star, named for
  its sharp petals, and the thistle, whose florets are spines.
- **A round petal** (`PlantBuilder.petalProfile`) widens from a narrow claw on a
  quarter sine to its widest point, then closes on a quarter superellipse whose
  tangent at the tip is square to the midrib: a round end, never a point, and no
  corner anywhere. The tip gene now says how round: at its bluntest the widest
  point is at 0.62 of the petal and the end fuller than a circle; at its
  sharpest the widest point is at 0.48 and the end a softly pointed oval. The
  widest is as wide as the lens was.
- **It is dished a little across**, its edges turned in toward the flower's
  middle, which is what makes the end read as round from the side.
- **A poppy's is creased** (`petalCrumple`): two soft waves at an angle to the
  midrib, strongest toward the edge and the tip, phased by the petal's place
  round the flower, so no draw is spent.
- **Seventeen rows, drawn in toward the tip** (`petalRow`, `v + v² − v³`), for
  every petal including the pointed ones: even at the base and closest at the
  tip, so the rows fall evenly round a round end and a star's taper is a curve
  rather than facets.
- **A petal's length along its midrib is what it was**, so blooms keep their
  reach. Over 3,000 minted seeds the median change in grown height is 0 mm for
  most families, +1 mm lotus, +3 mm poppy, +5 mm orchid (largest 59 mm, a
  nodding poppy), and in spread 0 mm except poppy +3 mm. No gene was added or
  moved. The largest mesh of the 3,000 went from 74,712 triangles to 90,840,
  against the budget test's 120,000.

## What is left

- ~~**The centre dome of a large solitary bloom has a hard bright rim.**~~ It
  was geometry after all, not shading — see "What holds a flower from beneath".
- **Leaves stay on the main stem's nodes in all three forms.** As specified —
  the branches of an umbel are bare in life, and leaves on them would be a
  fourth thing to tune.
- ~~**`tools/preview` has drifted further.**~~ Brought level on 24 September
  2026 with the habit, the calyx and the round petal, and the crozier, the apex
  point, `leaf.taper.N` and `bloom.lean.N` with them; compared by hand against
  SeedCore's own meshes, every vertex count equal and every bound within Float
  precision. It still lacks the `maturity` vertex attribute and twelve palette
  draws. `SeedCore` is authoritative; the preview is for judging shape.

## The web draws a surface, 27 September 2026

Marcus, looking at the Seedbed: *why do the leaves look so artificial and
plastic-like?* Two things were missing, both already written and both dropped
at the wasm boundary rather than absent.

**A leaf's age.** `MeshBuilder.addSurface` has carried a `maturity` per
surface since it was written, and says in its own doc comment why it reaches
the renderer as a vertex attribute: it is the only channel that survives every
leaf on a plant sharing one material. The app has read it all along
(`PlantSceneBuilder.agingModifier`). The wasm encoder wrote positions,
normals, uvs and indices and left it out, so every leaf sampled one texture at
the same coordinates and came out identical to the pixel. Now in the buffer,
and both web shaders tint a young surface from one table ported from
`youngTint` — a leaf to pale yellow-green, a petal in bud to the calyx's
colour, a centre and its stamens pale and dry, a stem and a calyx untouched.

**The relief.** `PaletteRamp.relief` describes veins standing proud of the
blade, the quilting between them, ribbing on a stem and bumps on a floret;
`GradientTexture.renderNormal` and `renderRoughness` bake it, and
`GradientTexture`'s own header says what it is for: *a single scalar roughness
and flat normals give every leaf one uniform sheen, and no amount of colour
detail recovers from that.* The web baked only the diffuse.

- **One texture, not the app's two.** A height field's tangent-space normal
  always points out of its surface, so `nz` is recovered on the page and the
  blue channel carries the roughness — which is read off the same height
  field, so the ridge the light catches and the gloss on it are the same
  ridge. The wire is `(nx+1)/2`, `(ny+1)/2`, roughness, 255.
- **The tangent frame is found per pixel**, from the screen-space derivatives
  of the world position and the texture coordinate. A leaf's vertices carry no
  tangents and adding them would be a third attribute and a change to every
  builder; the derivatives give the same frame for four subtractions.
- **The relief strengths and roughness swings are the app's, unchanged.** Every
  one came down after the app's first render: relief convincing in the
  abstract reads as corrugated iron on a blade the size of a thumb, and
  roughness taken far down on raised ground gives every ridge a specular hot
  enough to burn out the detail it was meant to show.
- **The plant buffer is `PGP3`.** The magic is checked on the page, so a wasm
  and a page that disagree say which they got rather than reading the vertices
  at the wrong stride. Nothing stores the buffer.

**Not done, and deliberately.** The garden's shared `shade()` multiplies sRGB
albedo by light without gamma correcting, where the single-plant viewer does
it properly. Fixing it is three lines and correct, but `shade()` is shared
with every ground in the garden and the light constants were tuned against the
uncorrected path, so it means re-tuning and re-checking ten areas.
