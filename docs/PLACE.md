# Where a meeting happened

A specification, not yet built. Written 31 August 2026. The figurative half is
live; the geographic half is described here because it reverses a decision
recorded in three places and falsifies a sentence currently on screen, and
neither should happen by accident.

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

## What is proposed

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

## Location is told, not inherited

The governing idea, and the thing that keeps this small: a seed cannot be
stamped. A seed is thirty-two bytes derived from two parents and two nonces, and
altering those bytes alters the plant that grows from them. Geographic
provenance is not part of what a plant inherits.

It is part of what its parents chose to say about it. That puts it exactly where
the note, the date and the typed place already live, in `EncounterNote`, which
is local, optional, and never transmitted. Nothing in `SeedCore` changes.

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

**Both-or-neither cannot be done by sending consent alongside coordinates.**
Whoever transmits first has already disclosed. Consent has to be exchanged and
agreed in its own round, and coordinates sent only after both phones hold both
answers. `ExchangeProtocol` already runs in rounds, so this is an extra beat
rather than a new shape.

**One person's consent would disclose the other's location.** Two people at a
face-to-face meeting are standing in the same spot, so my coordinates are also
yours. If I agree and you decline, publishing mine tells anyone reading my garden
exactly where you were, which is the thing you just refused. This is why
one-sided consent must fall back to the figurative place rather than to a
coarsened real one: the fallback is not a lesser feature, it is the only answer
that does not spend somebody else's privacy. The rule of both-or-neither happens
to be the privacy-correct rule as well as the simple one.

## What has to be built

1. `NSLocationWhenInUseUsageDescription` in `project.yml`, and the string that
   goes in it, which is user-facing copy and should be written as such.
2. A standing switch in Seed, off by default, and the dialogue on Meet that
   offers it the first time.
3. A consent round in `ExchangeProtocol`, before any coordinates move.
4. Coordinates on `EncounterNote`, optional, alongside `place`.
5. The rewritten paragraph on the Seed screen.
6. A decision on precision. Coordinates taken at full resolution record a
   doorstep. There is a case for rounding to something that names a place without
   naming an address, and it should be made deliberately rather than defaulting
   to whatever `CLLocation` hands over.

## Open

- **What is shown, once coordinates exist.** A place name asks for reverse
  geocoding, which is a network request, and the app currently makes none. Naming
  the spot from the device alone means showing coordinates, which reads as
  telemetry rather than memory.
- **Whether a kept plant can be edited later**, to add a place or remove one. The
  note can already be written once; consent that cannot be withdrawn is weaker
  than it looks.
