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

/// Where a plant stands in a bed. Two numbers, across the bed and into it,
/// `0...1` each, so a bed can be drawn at any size and on any device.
public struct Spot: Codable, Equatable, Sendable {
    public var across: Double
    public var into: Double
}
```

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

**This is already in the names.** The genus heads were fixed in August, and
`Quotes.Theme.genusHeads` reads:

| | |
| --- | --- |
| `waiting` | **Nyx**, **Umbr** — night, shade |
| `light` | **El**, **Aur**, **Sel** — sun, dawn, moon |

A plant called *Nyxia* is a night plant by its own name, decided before anybody
asked for a night garden. So this template is a reading of the genus head rather
than a filter invented over the top of one.

It is also the most interesting of the five, because **it cuts across the themes
rather than along them**. `light` splits three ways — El to full day, Aur to
dawn, Sel to the moon — so the plants of one theme end up at opposite ends of the
bed. Thematic and Night-and-day are therefore genuinely different pictures of the
same garden, where Colours and Kinship are each different again for simpler
reasons.

The bed runs from midnight through dawn to noon and back. Every plant has a place
on it, because every genus head belongs to exactly one theme and
`ThemeMappingTests` proves it.

### Colours

Palette hue, swept into drifts rather than laid round a wheel. Drifts are what a
planting plan actually does with colour, and a wheel would make the bed a colour
picker. The palette is on the genome and costs nothing to read.

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
cheaper than it sounds: `StageBackdrop` already takes a single number and turns
it into a pool of light over a ground
([`StageBackdrop.swift:28`](../App/PeaceGarden/Rendering/StageBackdrop.swift#L28)).
A garden-scale version takes a time of day instead of a `presence`.

**Night falls by the clock, with an override.** Settled 17 September. A garden
that is dark because it is dark outside is a place; a garden that is dark because
somebody pressed a button is a theme picker. The override exists because this app
is used at two in the morning by people who will want to see their garden in
daylight, and refusing them that would be purity at somebody else's expense.

The override is a standing choice and belongs in Seed with the others, rather
than a control on the garden itself. Whatever it is set to, the chrome has to
stay legible at both ends, which `Chrome` was built for and which is worth
looking at rather than assuming.

## The renderer is not a fork

Two numbers per plant per bed, whichever way it is drawn. The rendering can
change later without touching a single stored garden, so the cheapest version is
not throwaway work.

| | | |
| --- | --- | --- |
| **Plan view** | Thumbnails standing on a plane seen from above | Nearly free. `ThumbnailRenderer` renders to a transparent `UIImage` and caches 120 of them today. Reads as a planting plan, which is a real drawing a gardener makes. It is a board rather than a place. |
| **Diorama** | The same sprites placed at depth: scaled by distance, fading back into the ground | Roughly the cost of the plan view, and most of the feeling of a bed. `into` becomes depth rather than a second axis on a flat plane. |
| **One scene** | Every plant a real mesh, camera looking across the bed | Actually a garden. Needs level of detail, and a new framing rule: `PlantSceneBuilder.framing` frames one plant against its own mature bounds, and a bed has to be framed against the bed. |

Build the plan view first and the diorama second, because the diorama is the plan
view with `into` drawn instead of ignored. The single scene is a project of its
own and should be decided on its own.

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
- **Whether the diorama's depth is real or apparent**, which decides whether a
  plant can stand behind another and be hidden by it.
