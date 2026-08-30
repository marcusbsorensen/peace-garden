# Phases

## Phase 1 — this one: the seed, and the meeting

Built:

- A seed minted once per person, from random bytes plus what the phone can see
  of the moment it was drawn.
- A plant derived from that seed: shape, colour, name, pace, all of it.
- Growth in real time, over days, including opening by day or by night.
- 3-D rendering in full colour, standing in a soft pool of light on black,
  turned by dragging, with controls that appear on a tap and see themselves out.
- A face-to-face exchange between two iPhones: find each other, tap the phones
  together, cross the seeds, agree on the result, and grow a hybrid that
  descends visibly from both parents.
- Keeping the plant with a note about the meeting — the date and time if wanted,
  a place, a line of text.
- A local garden of everything grown from meetings.

Not built, deliberately:

- Anything that leaves the phone. There is no server, no account, no sync.
- The shared peace garden and its guest books — phase 2, below.

## Phase 1.5 — refinements that need hardware

- **Nearby Interaction as a second gate.** On iPhones with a U1/U2 chip, require
  the two phones to be within a few centimetres as well as tapped. One extra
  message in the handshake; needs two such devices in a room to develop against.
- **A closed-bud state worth looking at.** The bud is currently the flower's
  petals held shut. It could be its own geometry, with sepals.
- **Wind.** A slow vertex displacement along the stem would do more for the
  feeling of a living plant than any amount of extra polygons.

## Phase 2 — the shared peace garden

This is where the app stops being local, and every decision gets heavier. The
sketch:

**What a plot is.** Each person has an area of the garden. They choose which of
their plants stand in it. A plant in someone's plot shows its name, its age, and
the note from the meeting that made it — if its owner chose to include one.

**What is uploaded.** A plot entry is a seed, a birthday, a lineage and an
optional note: a few hundred bytes. The geometry is derived on each viewer's
device exactly as it is today, so the network never carries a mesh and a garden
of thousands of plants is still a small download.

**Guest books.** A visitor can leave a line in the guest book of a plot they are
standing in. This is user-generated content shown to strangers, which brings
with it, and none of it is optional: reporting, blocking, moderation, a way to
delete a book entry and a way to delete an account. Budget for that before
building the pretty part.

**Both people, one plant.** A hybrid belongs to two people. Either can show it
in their plot. If one of them deletes it, the other's copy stays — but the
encounter note is each person's own, written on their own phone, and is not
shared unless they show it.

**Identity.** Phase 1 has no accounts on purpose. A shared garden needs
*something* — enough to prove a plot is yours across a reinstall, and no more
than that. Sign in with Apple, or a device-held key that signs plot updates,
would both work. The seed must not become the login: it is handed to strangers
by design.

**What must not change.** The derivation. Every plant already growing on
someone's phone has to keep growing the same way. Phase 2 adds a transport for
seeds; it does not touch what a seed means.

## Open questions

- Does a plant ever die, or go to seed? A garden that only accumulates loses
  the thing that makes a real one worth visiting. But a plant that dies takes a
  memory of a meeting with it.
- Can two people who have already met cross again? Today, yes, and they get a
  different plant each time, because both nonces go into the encounter. Whether
  that should be rate-limited is a product question, not a technical one.
- Should the peace garden be one shared place, or many? One place is the idea.
  One place is also where every moderation problem lives.
