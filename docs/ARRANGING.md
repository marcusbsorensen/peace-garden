# Arranging a garden

Written 17 September 2026, as a design settled in conversation and not yet
built. It covers the app's Garden screen only. The site's garden is a different
thing on purpose, and the first section is about why.

## The site's garden is inherited; this one is told

[`docs/PLACE.md`](PLACE.md) draws a line this project keeps coming back to:
what a plant **inherits** against what it is **told**. The seed, the genome, the
name and the theme are inherited — derived, unchangeable, and identical on every
device that holds that plant. The display name, the note, the typed place and
the coordinate are told — local, optional, and theirs to change afterwards.

The garden on peacegarden.app is inherited all the way down. A theme's four
scores project onto two principal components, that gives one of ten areas, and
two slices of the seed hex give a cell inside it. Nobody chooses any of it and it
never moves; [`docs/WEBSITE.md`](WEBSITE.md) §*Walking it* has the whole
derivation and the reason it is baked rather than computed in the browser.

**The garden in the app is told.** A person arranges their own plants, and where
a plant stands is a fact about them rather than about the plant.

That is not a new category and it needs no new promise. An arrangement is local,
never enters `ExchangePayload`, and cannot reach the seed, so it cannot change
what grows. It sits exactly where `EncounterNote` already sits. Anyone later
asking whether layouts should sync between two people's phones is asking whether
the told half should be shared, and the answer to that is in PLACE.md and is no.

Two gardeners who grew the same plant may stand it in quite different places,
and that is the same property as two gardeners remembering one meeting by two
different names.

## A bed

An arrangement is a named thing holding a template and the positions somebody
has moved by hand.

```swift
public struct Bed: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var template: Template
    /// Only the plants somebody has placed. Everything else falls to the
    /// template.
    public var placed: [UUID: Spot]
}

/// Where a plant stands: METRES from the middle of the plot, on the two
/// ground axes.
///
/// Not a fraction of the plot's width, because the plot grows — see below.
/// Metres keep a plant exactly where it was put and let the new ground
/// appear at the edge; a fraction would spread the whole garden apart
/// every time somebody met a stranger.
public struct Spot: Codable, Equatable, Sendable {
    public var x: Double
    public var z: Double
}
```

This has been three things. A fraction across a flat rectangle when the garden
was a bed; two angles when it was briefly a sphere; metres from the centre now
that it is a growing plot. **Two numbers throughout**, which is why the
templates below never changed: a template maps plants onto a surface and does
not care what shape the surface is.

`Garden` gains `beds: [Bed]`, **optional, so there is no migration**.
`GardenStore` already accepts a file at an older schema and writes it back at the
current one ([`GardenStore.swift:89`](../Packages/SeedCore/Sources/SeedCore/Persistence/GardenStore.swift#L89)),
and an absent `beds` decodes as nothing and is filled with one bed on the
Thematic template. `PollenCard.sharesPlace` is the precedent: optional so that a
card from version 1 decodes as a refusal, and no version number had to move.

**`placed` is sparse, and that is the whole design.** It records only what
somebody has moved. Three things follow, all of them wanted:

- A plant grown tomorrow appears in every bed without being placed, where its
  template says it goes.
- Changing a bed's template re-flows everything except the plants somebody put
  somewhere on purpose.
- *Put it back* is deleting an entry rather than recomputing one, and *reset the
  bed* is emptying the dictionary.

Each bed holds its own `placed`, so moving a plant in Colours does not move it in
Thematic. A hand placement is an opinion about one arrangement, not about the
plant.

## A template is a pure function

```swift
[PlantRecord] -> [UUID: Spot]
```

Deterministic, stored nowhere, one function each. A template that needed state
would be a bed.

Five worth having, and the second is the one that turned out to be already
written.

### Thematic

The site's own map: ten areas, The Cold Frame to The Crossing, in the 5 by 2 plan
that `WEBSITE.md` sets out. `Quotes.Theme.position`
([`Quotes.swift:72`](../App/PeaceGarden/Views/Quotes.swift#L72)) is already in
the app, so this costs the projection and nothing else.

A plant then stands in The Crossing on the phone and in The Crossing on the web.
That agreement is free, and it is the only place the two gardens are allowed to
be the same — the app's default arrangement is the site's arrangement, and every
other template is a departure from it.

**An area is one plant wide, and that changed how its plants are placed.**
Settled 18 September, on a real garden. Five columns across a 5.2 m plot makes an
area 0.92 m wide; a plant is up to a metre across. Scattering each plant from its
own seed therefore stood plants inside one another — the closest pair on the
first garden drawn was 7.5 cm apart — and the cause is the shape of the map
rather than bad luck.

Spreading was measured and does not fix it. Over forty gardens of fourteen,
independent scatter left 82 pairs closer than 20 cm; widening it into a cloud
2.9 m across — by which point the left-to-right gradient the map exists for is
mush — still left 37. **Any position drawn from one plant's seed alone has that
tail, because two seeds know nothing about each other.**

So an area's members are ranked by their own seed hex and laid evenly down its
depth. The closest pair goes to 0.217 m and the pairs under 20 cm go to none.

This is the one template whose spot depends on the other plants, and the
exemption is narrow. **It is not the index trap**: the rank is over seed hexes,
so it is identical on every device and unchanged by the order anything arrived
in. What it costs is that a plant joining an area re-spaces that area — about
three plants in fourteen move, by at most 0.43 m — and nothing outside that area
moves at all, which is what `ArrangementTests` holds it to.

### Night and day

**This is not a filter invented over the top of the plants. It is a trait they
have had since the genome was written.**

`Genome.Tempo.opensByDay` is real
([`Genome.swift:380`](../Packages/SeedCore/Sources/SeedCore/Genome/Genome.swift#L380)),
drawn at `chance("tempo.opensByDay", 0.7)`, so about three plants in ten open at
night rather than by day. `Epithet` already says so out loud where it is the
rarest true thing about a plant: *noctiflora*, and the comment beside it notes
that the word was in the vocabulary before it was ever checked
([`Epithet.swift:297`](../Packages/SeedCore/Sources/SeedCore/Genome/Epithet.swift#L297)).

So the template reads `opensByDay`, and the bed runs from midnight through dawn
to noon and back.

**The genus head is a different axis and must not be used for this.** An earlier
draft of this document had the template reading the name — Nyx and Umbr for night,
Sel for the moon — which is wrong. Those syllables carry the passage *theme*: Nyx
and Umbr mean `waiting`, Sel means `light`, and a theme is a mood rather than a
behaviour. A *Nyxia* may open at noon and nothing is out of order when it does.
The genus names what the plant is about; the epithet names what it does. Reading
the first to arrange a night garden would sort the plants by the wrong fact and
look almost right, which is the worst way to be wrong.

It is also the template that most changes what the garden *is*, rather than only
where things stand — see below.

### Colours

Palette hue, swept into drifts rather than laid round a wheel. Drifts are what a
planting plan actually does with colour, and a wheel would make the bed a colour
picker. The palette is on the genome and costs nothing to read.

**It will look more like Kinship than it sounds.** Fourteen real crossings drawn
for the mockup — one gardener against four peers — came back with the hue
clustered by peer: all three of Ada's plants at 0.11, Jonas's at 0.01 and 0.18,
Sofia's at 0.42 and 0.60. Palette is inherited, so plants grown with one person
already share a parent's colour, and sorting by hue half-sorts by parentage on
its own.

Neither template is wasted by that — Kinship groups and Colours sweeps, so they
read differently even where they agree — but anyone deciding which to build
first should know they are not the two independent pictures the list makes them
look like. Kinship is the one that says something hue cannot: *which* person,
rather than only that two plants came from the same one.

### By meeting

Chronological: a walk through the meetings in the order they happened. Or by
`encounter.place`, which draws on the forty figurative places in `Places.swift`
and groups a garden by where its plants were grown. Both are one sort.

### By kinship

Plants sharing a parent stand together. It reads
[`Lineage.parents`](../Packages/SeedCore/Sources/SeedCore/Genome/Genome.swift#L8)
and groups on whichever of the two is not your own seed — not
`Pollination.pairID`, which hashes the pair into a theme and is the wrong tool
here because it cannot be asked which parent it came from. The parents are
sorted at construction (`Genome.hybrid`), so the grouping is stable without
anything having to sort them again.

**This is the only arrangement that shows something the tile grid cannot show at
all**: which of these plants are related to each other. Two plants grown with the
same person stand side by side without either being labelled with their name, and
someone met five times is five plants in a group rather than five captions
repeating a word.

It also works where a name would not. PLACE.md notes that a theme survives a
rename because it hangs off the parent seeds rather than the told name — so
somebody who introduced themselves differently at the second meeting still lands
in the same group, and the garden is right about a thing its captions are wrong
about. That is the same property, drawn instead of described.

## Three things are called night, and they must not be confused

| | |
| --- | --- |
| **Appearance** | Light or dark, which `Chrome` already resolves against the system ([`Chrome.swift:34`](../App/PeaceGarden/Views/Chrome.swift#L34)). Nothing here changes it. |
| **A night garden** | A bed on the Night-and-day template. A *selection* — which plants, and where they stand. |
| **Night falling** | The same bed, lit differently, because it is night. A *time of day*. |

The third is the one that makes a garden a place rather than a screen, and it is
much cheaper than it sounds, because **half of it is already running**.

`GrowthModel.diurnalFactor`
([`GrowthModel.swift:190`](../Packages/SeedCore/Sources/SeedCore/Growth/GrowthModel.swift#L190))
closes a day-opening flower to about a third overnight and opens a night-opening
one in its place, off the real clock — `state(birth:now:calendar:)` takes the
device's calendar and `GardenView` already passes `model.now`. Its own comment
says why: *a small thing that makes the plant feel like it is living alongside
you.* The thumbnails do it today; `ThumbnailRenderer.key` buckets `bloomOpen`,
which is that number.

So the flowers in the garden already close at midnight. **The ground does not.**
That is the whole of the work: `StageBackdrop` takes a single number and makes a
pool of light over a ground
([`StageBackdrop.swift:28`](../App/PeaceGarden/Rendering/StageBackdrop.swift#L28)),
and a garden-scale version takes an hour instead of a `presence`.

It also means the night bed is not a rearrangement of the same picture. At two in
the morning the night-openers are the plants in flower and the day-openers are
shut, so a garden visited at night is genuinely a different garden — and it was
already that before anybody drew a bed. Nothing in this template makes that
happen; it only stops the arrangement hiding it.

**Night falls by the clock, with an override.** Settled 17 September, built 18
September as `GardenDaylight` — *Follows the hour* or *Always daylight*, in Seed
with the other standing choices. It changes the light and nothing else: a
night-opening flower is still open at two in the morning under a noon sun,
because when a flower opens is a fact about the plant and not about the lamp. A garden
that is dark because it is dark outside is a place; a garden that is dark because
somebody pressed a button is a theme picker. The override exists because this app
is used at two in the morning by people who will want to see their garden in
daylight, and refusing them that would be purity at somebody else's expense.

The override is a standing choice and belongs in Seed with the others, rather
than a control on the garden itself. Whatever it is set to, the chrome has to
stay legible at both ends, which `Chrome` was built for and which is worth
looking at rather than assuming.

## The garden is a floating square plot, seen in isometric

Settled 17 September, after three shapes had been built and looked at: a flat
bed, a sphere, and this.

**The sphere was tried and dropped.** It answered the edge question by not
having one, which is genuinely the cleanest answer available, and it cost two
things that turned out to matter more. Half the garden was always behind it. And
every *cultivated* world fought the surface: rings and spokes on a globe make a
golf ball, latitude bands make a turned cylinder, because latitude bands are not
rows. On a square plot, rows of raised beds are simply rows and a parterre is
four quarters. The moment the ground was flat and square, half the worlds stopped
arguing with it.

So the edge comes back, and it is **drawn rather than hidden**: a square plot
hanging in space, with the soil's depth showing at the cut and rock tapering
away underneath. That is a different thing from a plane that merely stops, and it
answers *what is off the side* by showing the answer.

### Isometric is a simplification, not only a look

A parallel projection has no perspective divide, so one metre is the same number
of pixels everywhere on the plot. Three things fall out, and all three are
subtractions:

- **A plant is the same size wherever it stands.** No per-point scale.
- **Nothing leans.** Up is up, everywhere. The sphere needed a rotation per
  plant to keep a plant standing on the surface under it.
- **Depth order is `x + z`.** Not a sort by distance, not a z-buffer.

The sphere needed a lean, a per-point metre and a ray-sphere unprojection to put
a dragged plant under the finger. None of that exists here. The whole placement
is two lines forward and the same two lines backward.

### A plant stands on the ground, not over it

A square plot **is** a heightmap, so standing a plant on terrain is a lookup
rather than a problem — forty samples a side is about thirteen centimetres on a
five-metre plot, which is finer than a plant's own foot. Drag a plant into the
ravine and it goes down into it.

This was recorded as an open question while the garden was a sphere, where the
terrain displacement was ignored and a plant on a peak sank while one in a
valley hovered. The shape answered it.

The one place it is not free: finding where on the plot a finger is requires
knowing the ground height there, and the ground height requires knowing where on
the plot you are. The inverse runs twice — once at ground zero, once with that
place's own height subtracted — and that is enough.

### The plot grows outward and a plant never moves

One more crossing, a little more ground. Its size is then a record of how many
people you have met, with no number anywhere.

**This is why a spot is in metres and not a fraction.** New ground appears at
the rim and everything already planted stays exactly where it was put. The
oldest plants end up at the heart of the garden and the newest at its edge —
which is what happens in a real garden, and was not designed in.

The alternatives were a fixed plot you fill, which gives the empty state
something to say, and a fixed plot that can get crowded, where running out of
room makes you choose what to keep. Both are defensible; the growing one is
kinder, which is the tie-breaker in this app.

### Scale is one decision, not two

The plants are 0.46 to 1.36 metres and that is real: the geometry is SeedCore's.
Fourteen of them on the one-metre square this started as would be a thicket
rather than a garden.

**That range is the mockup's fourteen crossings and not the range.** Measured
across a hundred and twenty, the tallest is **2.36 metres** — three quarters of
a metre above anything this document had seen, and nearly half the width of the
plot it stands on. It was found by a test written to check that a sprite frame
was big enough, which is exactly the kind of thing no render would have shown:
the first fixed frame cut the head off that plant, and a plant with its head cut
off looks like a tall plant. `PlotTests` now holds both the per-plant frame and
the headroom the plot reserves against the measured range, so the next time a
genome grows past it something says so. The mockup's plot is 5.2 metres square, which holds
fourteen with room to walk between them. Whatever the growth rule turns out to
be, it is a rule about keeping that relationship as the count rises.

## The ground is chosen, and the worlds have no names

Eight drawn so far, and they are two kinds of thing:

| | |
| --- | --- |
| **Terrain** | Meadow, Hillside, Alpine, Lake, Ravine, Verge — what the ground does |
| **Cultivation** | Raised beds, Formal garden — what a gardener has done to it |

Worth separating before the list grows, because they want opposite rules:
**terrain must never look regular and cultivation should.** You can have an
alpine meadow; a formal garden is not a landform.

Eight are drawn: Meadow, Hillside, Alpine, Lake, Ravine, Verge, Raised beds and
Parterre. **They are chosen by looking, and the app never says their names.** A row of
little worlds, picked the way you pick a plant. That is not only tidier, it is
what lets the list grow: `docs/WEBSITE.md` records the ten area names becoming
420 commissions at a multiplier that is now forty-two, and a named world would
be the same trap on a list Marcus has already described as *landscapes from all
over the Earth*. Unnamed, the fiftieth world costs a render. Named, it costs
forty-two translations and a reading that has barely started.

### A fourth, which the app's own drawing taught

**A world's colour is stippled, and a mesh coarser than the atlas turns grain
into a lattice.** The ravine's strata and the scree are drawn as single dark
cells among lighter ones; that is what gives them their texture. Drawing the plot
at sixty-four quads a side and reading one cell per quad picked a dot or a gap,
and the gorge came out as a regular lattice of black diamonds — which reads as
holes in the ground rather than as a sampling fault, and which the meadow, having
no stipple to alias, was perfectly happy to hide.

The plot is drawn at the atlas's own resolution, so a quad is a cell and the
grain is the grain. Anything coarser — the row of little worlds — averages the
colour over the patch its quad covers instead.

### Three things the renders taught, which no test would have

The same lesson the husk taught in August, and `tools/preview/README.md` is
already emphatic about why looking is not a convenience.

- **Shading by the radial direction draws a mountain range as a painted ball.**
  On the sphere, every face took the sphere's own normal and the terrain got no
  slope shading at all. True face normals, from the quad's diagonals, were the
  entire difference between the first alpine world and the second.
- **A feature written as a function of latitude or longitude alone runs the whole
  way round a sphere and reads as machined.** The first ravine came out as a clam
  shell, the first raised beds as a turned cylinder, and the first road hid round
  the silhouette and was never seen at all. This is the observation that
  eventually killed the sphere: the fix is that a place needs a centre, and once
  every world has a centre, the surface may as well be flat.
- **A keel that tapers to nothing at the edge is invisible.** The only part of a
  floating plot's underside you can ever see is the part near the near edges, so
  a plot whose soil thins to a line at the rim reads as a tile rather than as a
  piece of ground with a root under it. The cut has to have real depth exactly
  where it is easiest to economise on.

  **And the rim is not merely the part you see most of — it is the only part you
  see at all.** Looking down at thirty-five degrees, the plot's own surface hides
  everything under it, so the bulge below the middle is never drawn and the rim
  depth is the whole of what *thick* means. At the mockup's 0.40 m it reads as a
  tile with a lip; at 0.95 m it reads as ground with a root. The cut is drawn as
  a bank in cells rather than as two flat faces — humus for a hand's depth, earth
  through the middle, rock coming up from the bottom, stones scattered more
  thickly the deeper it goes, and a floor ragged by a few centimetres. Ground
  that ends in a ruled line is a tile again.

  Two numbers matter and neither is obvious. The cells have to be **coarse**:
  drawn at the terrain's own hundred and twenty-eight columns the variation came
  out as a comb of pinstripes three pixels wide, which reads as moiré rather than
  as soil. And the materials have to be **lighter than they look right in the
  hand**: a cut face is vertical, so it is lit by the sky and by almost none of
  the sun, and colours chosen on their own came out as a black band under the
  plot.

## How it is drawn

The stored spot is two metres on the ground whichever way the plot is drawn, so
the renderer can change later without touching a single stored garden.

| | | |
| --- | --- | --- |
| **Sprites on a heightmap** | Cached plant stills placed at `x, z`, standing at the ground's height there | What the mockup does. `ThumbnailRenderer` already renders to a transparent `UIImage` and caches 120, and isometric means one size for all of them. Cheap in a way the sphere never was. |
| **One scene** | Every plant a real mesh on a real displaced plot | Needs a new framing rule: `PlantSceneBuilder.framing` frames one plant against its own mature bounds, and a plot has to be framed against the plot. An orthographic camera is a one-line change in SceneKit. |

The sprite version is not throwaway. It answers what this design still has open —
what a crowded plot feels like, whether the cut reads as depth, what the ground
choice does to the plants standing on it — and none of that needs a mesh.

## The sun and the moon go round the plot

Settled 17 September. One light, orbiting: the sun up from 06:00 to 18:00,
rising at one corner of the plot and setting at the opposite one, highest at
noon; the moon doing the same twelve hours out of phase. At any hour exactly one
of them is above the horizon, which is why there is one light direction rather
than two.

It casts. The terrain shadows itself and the plants shadow the ground, and both
move as the hour does.

### The ground stops being a picture

This is the consequence, and it is the interesting one. Eight worlds times every
hour is a combinatorial blow-up, and snapping to the nearest of eight renders
makes the sun jump. So **a world ships as what it actually is** — a height and a
colour per cell — and the light is applied where it is drawn.

All eight worlds come to 223 KB that way: less than **one** pre-rendered tile,
because a rendered tile is mostly shading and shading is exactly what is being
thrown away. Terrain self-shadowing is then a march along the light direction
over the heightmap, which is a few hundred thousand operations and imperceptible.

The plants stay sprites, because a plant is a mesh nobody wants to rebuild at
sixty frames a second, but they are rendered at **eight points round the clock**
and crossfaded. That way the hour does two different things to a plant at once,
both of them real: it moves the light on its leaves, and it opens or closes its
flower through `GrowthModel.diurnalFactor`.

### What the ground is made of

The first worlds coloured themselves by height alone — a lerp from a low green
to a high one — which is why they read as tinted relief maps rather than as
places. **Landscape colour barely follows height.** It follows:

| | |
| --- | --- |
| **Slope** | The big one. Steep ground sheds soil, so it is rock and scree; gentle ground holds it, so it is grass. A mountain is grey because it is steep, not because it is high. |
| **Moisture** | Which follows concavity. Water runs into hollows, so a dish is lush and a ridge is bleached. Read off the heightmap's Laplacian, which costs nothing once the heightmap exists. |
| **Height** | For the two lines that genuinely are heights: snow, and water. |
| **Patchiness** | At two scales. A hillside is not a gradient; cover comes in stands and drifts with edges. |
| **Aspect** | A little. A slope turned away from the light stays damp, and damp is where moss lives. |

So the ground is a mix of named **materials** — grass at three wetnesses, moss,
heather, bracken, reed, three rocks, scree, two soils, sand, shingle, snow, two
waters, tarmac, gravel, box — and each world says which it is made of and what
governs where they sit. Alpine's snow is above the line **and** gentle enough to
hold it, which is what stops a snowcap looking painted on. The ravine's walls
carry strata, which is what a gorge actually shows you and half the reason to
cut one.

**The saturation ceiling is enforced, not trusted.** `Chrome`'s rule is that the
plant is the only saturated thing on screen, and a lawn in full chroma takes that
away. Every world's colour passes through one function on the way out that pulls
anything over the ceiling back to it, so a material added later cannot quietly
break the rule by being written too bright.

### The night is a night, and the moon is tonight's moon

Stars, fixed rather than drifting — the one thing that would give away that they
are drawn. They come out as the sun goes down and the plot occludes its own patch
of sky, because it is drawn over them.

**The moon is in the phase it is actually in**, from one synodic month against a
known new moon. The lit part of a disc is a semicircle plus a semi-ellipse whose
x-radius is `R cos(phase)` — *signed*, so it bulges outward for a crescent and
inward for a gibbous, and the two cases are one piece of arithmetic rather than
two drawings. Waning is the same shape mirrored. The dark limb keeps a trace of
earthshine rather than going black.

It ignores the orbit's ellipticity and is a few hours out at worst, which is
finer than a drawing nineteen pixels across can show.

### One light model, written once

`orbit.py` defines the light and exports it; the page reads those same numbers.
Two models that merely look alike is how a plant ends up lit from the left on
ground lit from the right, with nobody able to say why the picture is wrong.

**Built 18 September, and that warning turned out to be about the app rather
than about the page.** The plants were already lit by `PlantSceneBuilder`'s
studio — one hard key, a cold rim, an ambient of about 0.09 — standing on ground
lit hemispherically at noon. Nothing looked broken; the plants simply looked
pasted on. The sprites are now lit by the same function the ground is shaded
with, which is what makes them look like they are standing outside.

### Two things building it taught

- **The shadow goes flat twice a day.** At noon and at midnight the body sits at
  the azimuth where a shadow runs exactly along the screen's horizontal, and a
  shadow with no screen height is a line. That is not a fault — it is what an
  isometric view of that moment is — but it is worth knowing before somebody
  goes looking for the bug. The blur is what keeps it from reading as a drawn
  rule.
- **The override is not a nicety.** Drawn at half past six in the evening the
  garden is very nearly black, which is correct — moonrise is the darkest hour
  of the day — and it is also a garden you cannot look at. Seeing that is what
  settles the argument the override was already written down to win.

### The moon was brighter than the dawn

Worth recording because nothing was broken. The first pass had a full moon
overhead at 0.32 and the sun at the horizon at 0.24, so midnight came out
brighter than sunrise. Both curves peaked correctly at their own maximum; what
nobody had done was make them agree with each other.

The moon is about a hundred thousand times weaker than the sun. A fifth is
already a generous lie so that a night garden can be seen at all — a third was
simply wrong. Midnight now reads 0.150 against sunrise at 0.240 and noon at
0.760, and the darkest hour of the day is moonrise at 18:00, which is correct:
the moon has only just cleared the horizon.

**It is a fault that exists only between two things**, and it only showed up when
both were put on one slider. No test would have had an opinion about it.

## Turning it, and the one gesture conflict

Asked for 17 September: pinch to zoom, two-finger rotate, in the way an iPhone
has taught everybody to expect. Both are `UIPinchGestureRecognizer` and
`UIRotationGestureRecognizer`, and neither is interesting on its own.

**What is interesting: rotation is free for the ground and expensive for the
plants.** The ground is computed rather than pre-rendered, so it draws at any
angle for nothing. The plants are sprites rendered from one camera, so a turned
plot either turns them too — four renders per plant at ninety-degree steps, or
many more for free rotation — or lets them stay billboards facing the viewer,
which is the usual answer and is a real compromise for a plant with a front and
a back. That asymmetry, not the gesture, is what decides whether turning is free
or stepped.

**Ninety-degree steps are the recommendation**, because isometric has four
natural views and stepping between them keeps the ground's own axes aligned to
the screen — which is the property that makes an isometric plot legible at all.
It also answers the ravine, which has a side you cannot see from any one view.

### One finger cannot do two things

Dragging a plant and panning the plot both want a single finger, and this is the
only real conflict in the design.

| | |
| --- | --- |
| **Drag on a plant moves it, drag on the ground pans** | Immediate, no learning. Ambiguous wherever plants are close, and it makes an accidental move one slip away. |
| **Long press to lift, then drag** | The idiom for rearranging on iOS, with a haptic to say the plant is in hand. Costs a beat before every move. |

**Long press, and the beat is worth paying.** Every plant in this garden is a
meeting with somebody. Nudging one by accident while trying to look at it is a
worse failure than waiting a third of a second to pick one up, and the haptic
makes the difference between looking and moving something the person can feel
rather than something they have to be careful about.

## The light is rebuilt, not filtered

`StageBackdrop` is a studio, on purpose: one hard key, a cold rim, and an ambient
of about 0.09, so an unlit face falls to near-black. That is right for a
botanical model kit photographed for its box, and it is exactly wrong outdoors.

The garden light is **hemispheric** — sky from above, bounce from the ground
below — so a shadowed leaf is lit by the sky rather than by nothing. Softer sun,
lower angle, the cold rim cut to a trace. That one change is the whole of the
difference between stark and outdoors, and no amount of filtering gets there,
because the information is not in the rendered pixels to recover.

**On a world there is no pool of light at all.** `StageBackdrop`'s glow is a lamp
behind a subject; a planet is lit by its own sun. The background is space, and it
darkens with the hour rather than closing in.

## What the grid did that this loses

`GardenView`'s own note says it
([`GardenView.swift:100`](../App/PeaceGarden/Views/GardenView.swift#L100)):

> A garden is somewhere to come back to, and what has changed since the last
> visit is the only thing here that moves — a tile that says only who you met
> says nothing about why you would open it today.

That is why the caption carries the stage as well as the gardener. **A garden
somebody has arranged is a garden that never surprises them again.** Everything
is where they put it, which is the point, and it means a plant that has just come
into bloom has no way to say so.

This is the design problem the grid was already solving, and it is the one that
would be dropped without anybody noticing.

**Settled 17 September: the light finds it.** A plant that has changed since it
was last opened stands in its own small pool, the way a plant on the stage
already does, and the pool goes out once the plant has been opened. That keeps
the answer inside the vocabulary the app already has, and adds no badge, no count
and no red dot.

Two things it turns on, both in `GardenVisits`:

- **Opened, not merely on screen.** A pool that went out because the garden was
  looked at is a pool nobody ever saw go out.
- **Growth only, never the bloom.** `GrowthModel.diurnalFactor` shuts a
  day-opening flower overnight and opens a night-opening one in its place, so a
  bucket including `bloomOpen` — which is what a thumbnail's cache key does —
  would light two thirds of the garden every evening and the other third every
  morning. A pool that comes on nightly says nothing at all.

## Settled

- **The garden is a floating square plot, drawn in isometric**, and it grows
  outward with the number of meetings. A spot is metres from the centre, so a
  plant never moves and new ground appears at the edge.
- **A sphere was built and dropped.** It has no edge, which is the cleanest
  answer to the edge question, and it hid half the garden and made every
  cultivated world fight its surface.
- **The ground is chosen from a set of worlds, and the app never says their
  names.** Terrain and cultivation are different kinds of world and want
  opposite rules.
- **The light is hemispheric, and there is no pool of light on a world.**
- **The ground is a mix of named materials, mixed by slope, moisture and
  patchiness** rather than by height, and the saturation ceiling is enforced in
  code.
- **The night has stars, and the moon carries its real phase for the date.**
- **The sun and moon orbit the plot and cast**, so the ground is shipped as
  height and colour per cell and lit where it is drawn, rather than pre-rendered.
  The plants are rendered at eight points round the clock.
- **A turned plot turns its plants: four renders each at ninety-degree steps**,
  not billboards. Settled 18 September. Billboards are the usual answer and are a
  real compromise for a plant with a front and a back, and every plant here is a
  meeting with somebody. It costs four times eight, because a sprite is already
  drawn at eight hours. The turn is of the plot's own axes, so the plant and the
  light rotate together — the sun goes round the plot, not round the screen.
- **The Milky Way is a second light, from far above, at every hour.** Settled 18
  September: the garden has to be somewhat visible at the lowest natural light.
  The moon's curve did not change and is still pinned — 18:00 is still the
  darkest hour of the day. What changed is that there is now light from
  overhead that fades with the sun's strength, adds nothing at noon because the
  sky outshines it, and is only noticed once the sun is gone, which is true of
  the real one. It falls on what faces up, so a bank of earth stays darker than
  the lawn above it.
- **The sky is the one place the saturation ceiling is relaxed.** A sky is not
  chrome, and a blue behind a garden is what says the garden is outdoors. The
  mockup's sky is nearly black at every hour because there the plot is the
  picture and the page around it is a page; in the app it is the whole screen
  behind a garden, and a noon that is dark navy says the garden is underground.
- **An arrangement is told, not inherited.** Local, never transmitted, unable to
  reach the seed. No new promise, and no change to the sentence on Seed.
- **One set of plants, several arrangements of it.** Every plant appears in every
  bed. Beds that own plants — where putting a plant somewhere takes it out of
  everywhere else — were considered and set aside: it is closer to gardening, and
  it raises where new plants land, whether a plant can be in two beds at once,
  and what an empty bed says to somebody who has not understood the rule.
- **Night falls by the clock, with an override** in Seed.
- **Templates are pure functions**, and a bed stores only what was moved by hand.
- **`beds` is optional on `Garden`**, so nothing migrates and no version moves.
- **The ground is chosen, and the choice lives on the bed.** Settled 18
  September. `Bed.world` is an optional row in the world atlas, so nothing
  migrates and no bed written before it has to say anything. Growing the world
  from the gardener's own seed was the alternative and was rejected on this
  document's own opening line: it would have made the ground one more thing about
  somebody that they did not choose.
- **A world is a number, because a world has no name.** The order of the rows in
  the atlas is therefore the file format, the way the trait labels are: a world
  may be added at the end, and none may be reordered or removed.
- **A plant standing where the ground changes keeps its `x` and `z` and is
  simply lower.** A spot is a place on the plot rather than a place on a
  particular surface, so swapping Meadow for Ravine drops a plant into the gorge
  rather than moving it out of the way of one.
- **Thematic ranks an area's plants down its depth** rather than scattering them
  in it, because an area is one plant wide. The only template whose spot depends
  on the other plants, and it still depends on no arrival order.
- **What announces a plant that has changed: the light finds it.** Above. It is
  the one thing the grid did that a free layout does not.
- **The saturation ceiling is 0.28**, enforced by one function every ground
  colour passes through. It is a decision rather than a measurement: the
  generator that held the original number was never committed, and 0.28 sits just
  under `StageBackdrop.saturation`, which is the most saturated thing the app
  already puts behind a plant.

## Still open

- **Whether a bed can be deleted, and what happens to its hand placements.**
  Deleting the last bed has to be impossible, or has to mean something.
- **Whether two plants may stand on one spot.** The site allows it and draws it,
  on the grounds that resolving a collision by probing makes a position depend on
  who arrived first. That reasoning is about *derived* positions and does not
  carry over: somebody dragging one plant onto another is expressing an
  intention, and the question is only whether the app should help them see both.
- **Whether an arrangement survives a plant being released to the Wild Fields.**
  Releasing is the end of a plant's life here; a spot pointing at a plant that has
  gone is the kind of thing that decodes fine and draws nothing.
- **Whether the shadows should be soft, and how soft.** They are drawn hard
  here, with a blur that widens as the light drops. A real shadow's edge softens
  with distance from what cast it, which a single blur cannot say.
- **What zoom is for.** Close enough to read one plant's binomial is a different
  screen from far enough to see the whole plot, and if zoom reaches the first it
  overlaps what `PlantDetailView` already does.
- **What the growth rule actually is.** A little more world per meeting, at a
  rate that keeps a tall plant at roughly half the radius. Whether that is
  smooth or in steps, and whether a garden of two hundred plants is still one
  plot, are both unanswered. A plot that grows in square rings has a natural
  answer to the first and none to the second.
