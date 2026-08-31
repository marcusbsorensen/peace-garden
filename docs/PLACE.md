# Where a meeting happened

Written 31 August 2026 as a specification, and now a record of what was built.
Both halves are live. It is kept because the geographic half reverses a decision
recorded in three places and rewrote a sentence that was on screen, and the
reasoning should outlast the memory of it.

## What is live

Every meeting is offered a place. `Places` holds forty figurative ones, drawn
from the child seed, filled into the note's Where field rather than shown as a
prompt, so leaving it alone keeps it. Someone who would rather record the café
types over it. What they type stays on their phone: `EncounterNote` is built
after the exchange and never enters `ExchangePayload`, so two people at one
meeting may remember it by different names, and that was already true before
this feature existed.

It asks for no permission, sends nothing, and needs no change to any promise. It
is also the only kind of place a seed arriving by link can have, there being no
shared moment to locate.

## What the geographic half does

Real coordinates, when both people want them.

- A dialogue on the **Meet** screen offering to switch location on, so a meeting
  can carry its geographic provenance.
- Off until someone says otherwise. The switch lives in Seed alongside the other
  standing choices.
- **Per meeting, not once.** Having it switched on means the option appears; it
  does not mean it happens. Each crossing is decided separately.
- Coordinates only when **both** people have it on and both say yes to this
  meeting. Any other combination falls back to the figurative place, with the
  free-text field as it is now.

## Told, not inherited

The governing idea, and the thing that keeps this small: a seed cannot be
stamped. A seed is thirty-two bytes derived from two parents and two nonces, and
altering those bytes alters the plant that grows from them. Geographic
provenance is not part of what a plant inherits.

It is part of what its parents chose to say about it. That puts it exactly where
the note, the date and the typed place already live, in `EncounterNote`, which
is local, optional, and never transmitted. Nothing in `SeedCore` changes.

### The name is the precedent

This is not a new category, only a second member of one. A display name is
already told rather than inherited: a father may give a different name to each
mother of his offspring, and his name is nowhere in his DNA. The app has always
behaved that way without saying so. `peerDisplayName` is stored on the note, not
the plant, so two meetings may hold two different names for the same person, and
every use of it is display: the caption in Garden, "with X" in the detail, "Met
X" on the note. Nothing matches, dedupes or identifies on a name.

Two things follow, and both are worth keeping.

**A name is a claim.** It is the only field in the exchange that is asserted
rather than derived, and therefore the only one that cannot be checked. Treating
it as decoration is correct, and anything later tempted to treat it as identity
should use the parent seeds instead.

**A theme survives a rename.** The passage theme hangs off `pairID`, which comes
from the two parent seeds, so someone who introduces themselves differently next
time still shares the same theme with you. Those five mothers would each hold a
different name for one man, and every plant of theirs would draw from one theme.
That was not designed in; it falls out of putting the theme on the inherited side
and the name on the told side, which is the best evidence available that the line
is drawn in the right place.

## What it reverses

Location was excluded on purpose, and the reasoning is written down:

| Where | What it says |
| --- | --- |
| [`GardenModels.swift:23`](../Packages/SeedCore/Sources/SeedCore/Persistence/GardenModels.swift#L23) | "no location permission, no automatic capture. A meeting is theirs to describe or leave blank." |
| [`GardenModels.swift:30`](../Packages/SeedCore/Sources/SeedCore/Persistence/GardenModels.swift#L30) | "A place, if they typed one. Never derived from the device's location." |
| [`EncounterNoteView.swift:8`](../App/PeaceGarden/Views/EncounterNoteView.swift#L8) | "the place is a text field, not the device's location." |

And one promise is made to the person using the app, at
[`SeedView.swift:99`](../App/PeaceGarden/Views/SeedView.swift#L99):

> When you meet someone, your phones exchange this seed, the name above, and a
> random number for that meeting. Nothing else: no account, no contacts, no
> location, and nothing is sent to a server.

That sentence becomes untrue the moment coordinates can cross. Rewriting it is
part of the work, not a follow-up. The honest version says what is exchanged by
default and what can be added by agreement, and it should say it in the positive:
what travels, rather than what does not.

## Two properties that are easy to get wrong

**A coordinate never crosses the air.** The first build sent it on `confirm`, a
round behind the consent flag, so that nobody disclosed before knowing the
answer. That was correct and it was more machinery than the problem needs: each
phone can stamp its own reading, and then there is nothing to send at all. The
wire has no field for a location, which is a stronger guarantee than a rule
about when to fill one in, and it is tested by encoding every message kind and
looking for the words.

**One person's consent would disclose the other's location.** Two people at a
face-to-face meeting are standing in the same spot, so my coordinates are also
yours. If I agree and you decline, publishing mine tells anyone reading my garden
exactly where you were, which is the thing you just refused. This is why
one-sided consent must fall back to the figurative place rather than to a
coarsened real one: the fallback is not a lesser feature, it is the only answer
that does not spend somebody else's privacy. The rule of both-or-neither happens
to be the privacy-correct rule as well as the simple one.

## What was built

1. `NSLocationWhenInUseUsageDescription`, written as the user-facing copy it is.
2. `PlaceKeeping`: the standing switch, off until turned on, and the only place
   the system prompt can be raised. It follows what iOS actually permits, so a
   permission revoked in Settings turns the switch off rather than leaving it
   claiming something it cannot do.
3. The offer on Meet, between the name and the search, shown once. Declining is
   remembered, because an offer repeated at every meeting is not an offer.
4. `sharesPlace` on `PollenCard`, optional so that a card from version 1 decodes
   as a refusal. `PollenCard.permitPlace` is the one place the rule is stated.
5. `Coordinate` on `EncounterNote`, beside the typed place and independent of it.
6. The rewritten paragraph on Seed, next to the switch that changes it, so that
   turning it on and reading what it means are one glance.
7. `EncounterEditView`, and `GardenModel.updateEncounter`, which reach only the
   told half.

**Precision is five decimal places**, about a metre, applied in `Coordinate`'s
initialiser so nothing can store more by forgetting to round. Enough to find the
spot again, and short of claiming an accuracy a phone in a street does not have.

## Settled, having been open

- **Coordinates are shown as numbers and never as a place name.** Naming a spot
  means a request to somebody's geocoder, and this app makes no network request
  at all. The numbers are also the honest record of what was measured, where "the
  Old Quay" is a guess laid over it. A tap opens them in a map, which is where a
  name belongs, and only if the person asks for it.
- **A kept plant can be told differently later.** The name, the place, and
  whether the coordinate is still held. Removing it deletes it rather than hiding
  it, because consent that cannot be withdrawn is not worth much. The seed, the
  lineage and the birthday are unreachable from that screen, so nothing anybody
  writes changes what grows.

- **A published note carries the named place and never the coordinate.** Both
  gardeners' notes now appear on a shared plant page, attributed — see PHASES.md.
  The consent that put a coordinate on a note was *both of us agree to keep
  this*, given about two phones that make no network request. It was never
  consent to publish the spot, and reading it as such would be the worst thing
  this app could do with the most careful thing in it. Publishing the coordinate
  is a separate question, asked separately, or not asked at all.

## Still open

- **Whether the coordinate is ever publishable.** The safe answer above is that
  it is not, and nothing yet needs it to be. If it ever is, it is a new consent
  with its own screen and its own withdrawal, not a checkbox on this one.
