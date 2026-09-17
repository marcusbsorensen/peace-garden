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

/// Where a plant stands: a DIRECTION on the world, not a position on it.
///
/// Two angles rather than two metres, because the world grows with the
/// garden — see below. A direction still means the same place after the
/// thousandth meeting; a position in metres does not.
public struct Spot: Codable, Equatable, Sendable {
    /// Radians, `-π...π`.
    public var lon: Double
    /// Radians, `-π/2...π/2`.
    public var lat: Double
}
```

A bed was a flat rectangle when this was first written, and `Spot` held
`across` and `into`. The world replaced it, and the two numbers stayed two
numbers — which is why the templates below are unchanged: a template maps
plants onto a surface, and it does not care what shape the surface is.

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

**Night falls by the clock, with an override.** Settled 17 September. A garden
that is dark because it is dark outside is a place; a garden that is dark because
somebody pressed a button is a theme picker. The override exists because this app
is used at two in the morning by people who will want to see their garden in
daylight, and refusing them that would be purity at somebody else's expense.

The override is a standing choice and belongs in Seed with the others, rather
than a control on the garden itself. Whatever it is set to, the chrome has to
stay legible at both ends, which `Chrome` was built for and which is worth
looking at rather than assuming.

## The garden is a little world

Settled 17 September, after the flat bed had been built and looked at. A bed has
an edge, and an edge asks a question the app then has to answer: what is off the
side, and what happens when it is full. **A sphere has no edge.**

It also makes the navigation something the app already does. A plant on the stage
is turned by dragging it — `PlantSceneView` rotates the plant rather than the
camera, so the light stays put — and a garden turned the same way is one gesture
in the app rather than two.

**Up is radial.** A plant near the limb leans away from vertical, because its own
up is the surface under it. That tilt is the single thing that reads as *planet*
rather than *hill*, and it costs one rotation per plant.

### A spot is a direction, not a position

This falls out of the world growing, below, and it is the kind of thing that is
free to get right now and expensive later. `Spot` holds a **direction** — two
angles, or a unit vector — and never a position in metres. A direction survives
the world getting bigger; a position in metres does not, and a garden that
rearranged itself every time somebody met a stranger would be the worst possible
answer to the nicest feature here.

### The world grows with the garden

One more crossing, a little more world. Its size is then a record of how many
people you have met, with no number anywhere and nothing to read.

The two alternatives were a fixed world you fill — which gives the empty state
something to say — and a fixed world that can get crowded, where running out of
room makes you choose what to keep. Both are defensible and the growing one is
kinder, which is the tie-breaker in this app.

### Scale is one decision, not two

The plants are 0.46 to 1.36 metres and that is real: the geometry is SeedCore's.
Fourteen of them on the one-metre slab this started as would be a thicket rather
than a garden. The mockup's world is 2.6 metres in radius, so a tall plant is
about half the radius, and **that ratio is the whole look**: much smaller and it
is a terrarium, much larger and the plants are moss on a globe. Whatever the
growth rule turns out to be, it is a rule about keeping that ratio.

## The ground is chosen, and the worlds have no names

Eight drawn so far, and they are two kinds of thing:

| | |
| --- | --- |
| **Terrain** | Meadow, Hillside, Alpine, Lake, Ravine, Verge — what the ground does |
| **Cultivation** | Raised beds, Formal garden — what a gardener has done to it |

Worth separating before the list grows, because they want opposite rules:
**terrain must never look regular and cultivation should.** You can have an
alpine meadow; a formal garden is not a landform.

**They are chosen by looking, and the app never says their names.** A row of
little worlds, picked the way you pick a plant. That is not only tidier, it is
what lets the list grow: `docs/WEBSITE.md` records the ten area names becoming
420 commissions at a multiplier that is now forty-two, and a named world would
be the same trap on a list Marcus has already described as *landscapes from all
over the Earth*. Unnamed, the fiftieth world costs a render. Named, it costs
forty-two translations and a reading that has barely started.

### Two things the renders taught, which no test would have

The same lesson the husk taught in August, and `tools/preview/README.md` is
already emphatic about why looking is not a convenience.

- **Shading by the radial direction draws a mountain range as a painted ball.**
  Every face takes the sphere's own normal, so the terrain gets no slope shading
  at all. True face normals, from the quad's diagonals, are the entire difference
  between the first alpine world and the second.
- **A feature written as a function of latitude or longitude alone runs the whole
  way round the world and reads as machined.** The first ravine came out as a
  clam shell and the first raised beds as a turned cylinder. A place has to have
  a centre, and a band has to have its pole perpendicular to the view or it hides
  round the silhouette — which is where the first road went, and it was never
  seen at all.

## How it is drawn

The stored spot is a direction whichever way the world is drawn, so the renderer
can change later without touching a single stored garden.

| | | |
| --- | --- | --- |
| **Sprites on a sphere** | Cached plant stills placed by direction, scaled by depth, rotated to the surface | What the mockup does. `ThumbnailRenderer` already renders to a transparent `UIImage` and caches 120. Cheap, and it carries the tilt, the depth order and the lean. |
| **One scene** | Every plant a real mesh on a real displaced sphere | Actually a world. Needs level of detail, and a new framing rule: `PlantSceneBuilder.framing` frames one plant against its own mature bounds, and a world has to be framed against the world. |

The sprite version is not throwaway. It answers the questions this design still
has open — whether the lean reads, whether a dragged plant lands under the
finger, what a crowded world feels like — and none of those need a mesh.

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
will be dropped without anybody noticing. It needs an answer before the grid is
replaced rather than after. The cheapest honest one is that the light finds it: a
plant that has changed since the last visit stands in its own small pool, the way
a plant on the stage already does, and the pool goes out once it has been looked
at. That keeps the answer inside the vocabulary the app already has, and adds no
badge, no count and no red dot.

Not settled. Recorded so that it has to be settled.

## Settled

- **The garden is a little world**, and its size grows with the number of
  meetings. A spot is a direction on it, never a position in metres.
- **The ground is chosen from a set of worlds, and the app never says their
  names.** Terrain and cultivation are different kinds of world and want
  opposite rules.
- **The light is hemispheric, and there is no pool of light on a world.**
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

## Still open

- **What announces a plant that has changed**, above. The one thing the grid did
  that a free layout does not.
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
- **What the world does with the half you cannot see.** Half a sphere is always
  behind it, which is either the best thing here — a garden with somewhere to go
  — or a place to lose a plant in. The Ravine world makes this sharpest: it has a
  bottom you cannot see from anywhere.
- **What the growth rule actually is.** A little more world per meeting, at a
  rate that keeps a tall plant at roughly half the radius. Whether that is
  smooth or in steps, and whether a garden of two hundred plants is still one
  world, are both unanswered.
- **Whether terrain is chosen or drawn from the seed.** Every world in the
  mockup is hand-tuned noise. The gardener's own seed could grow the world, which
  would make it inherited rather than told — and would put it on the wrong side
  of the line this document opens with. Worth deciding on purpose rather than
  drifting into.
- **Whether a plant sits on the terrain or floats over it.** The mockup places
  plants on the sphere and ignores the displacement, so a plant on a peak sinks
  and one in a valley hovers. Real placement needs the height at that direction,
  which the terrain function already knows.
