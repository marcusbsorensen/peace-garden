# Phases

## Phase 1 — this one: the seed, and the meeting

Built:

- A seed minted once per person, from random bytes plus what the phone can see
  of the moment it was drawn.
- A plant derived from that seed: shape, colour, name, pace, all of it.
- Growth in real time, over days, including opening by day or by night.
- 3-D rendering in full colour, standing in a soft pool of light on black,
  turned by dragging, with controls that appear on a tap and see themselves out.
- iPhone and iPad, in any orientation on iPad and in Split View: the plant is
  re-framed to the shape of the viewport rather than to a fixed assumption
  about it.
- A face-to-face exchange between two iPhones: find each other, tap the phones
  together, cross the seeds, agree on the result, and grow a hybrid that
  descends visibly from both parents.
- Keeping the plant with a note about the meeting — the date and time if wanted,
  a place, a line of text.
- Seeds by link, for meeting someone whose phone has never heard of the app: a
  QR code or an AirDrop carrying the seed, and a reply that brings theirs back
  so both people end up with the same plant.
- A local garden of everything grown from meetings.

Not built, deliberately:

- Anything that leaves the phone. There is no server, no account, no sync.
- The shared peace garden and its guest books — phase 2, below.

## Phase 1.5 — refinements that need hardware or a domain

- **An App Clip.** The single biggest change to how the app spreads: a seed
  scanned by someone who has never installed anything, growing on their phone
  seconds later. It needs a domain, an App Store Connect experience and a
  published app — see docs/SEEDS-ON-THE-WIND.md — none of which is code.
- **A seed on a physical tag.** An NFC sticker on a bench or in a café, holding
  a seed anyone passing can pick up. Different social object from a seed handed
  to one person; worth thinking about before building.
- **Nearby Interaction as a second gate.** On iPhones with a U1/U2 chip, require
  the two phones to be within a few centimetres as well as tapped. One extra
  message in the handshake; needs two such devices in a room to develop against.
- **A closed-bud state worth looking at.** The bud is the flower's own petals
  held shut, now wrapped in sepals. Real bud geometry — overlapping scales,
  a swelling that splits — would be better.
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

**A shared page names whoever agreed to be named.** Settled, because it is the
question everything else about sharing hangs from.

A plant belongs to two people, so one of them publishing it is one of them
speaking. The page therefore carries **the gardener who shared it, and nobody
else** — no second name, no placeholder, no "and one other". Until the other
person says yes, the page must not indicate that a second person exists at all:
a greyed-out slot is a disclosure, and the whole point is that it is theirs to
make.

**The invitation.** When A shares, B is told: the plant you made with A is in
the peace garden, and would you like your name on it too. Accepting adds B to
the page. Declining, or ignoring it, leaves the page exactly as it was.

This is the best growth mechanism the app has, and it is worth seeing why: it
travels along a relationship that already exists rather than asking anybody to
invite strangers. B is not being recruited — B is being told about a thing that
is already half theirs.

What it costs, and none of it is optional:

- **A delivery channel.** Phase 1 has no server, no account and no push. The
  cheap version is the right one to start with: B finds out **next time they
  open the app**, by asking the plot service whether anything of theirs has been
  shared. No push permission, no device token, no notification infrastructure,
  and it suits an app nobody needs to be interrupted by. Push is an upgrade,
  not a prerequisite.
- **A way to say no, standing.** A switch in Settings — already built, see
  `SettingsView`, though it has nothing to act on yet. On by default: B and A
  have met in person and made a plant together, which is a stronger tie than
  anything an app usually leans on. Anybody who would rather not hear about it
  turns it off once.
- **A rate limit, and a block.** Left unguarded, re-sharing is a channel A can
  use to reach B over and over. One invitation per plant, and B can block A.
- **Withdrawal, either way and independently.** A can un-share, which takes B's
  name with it. B can remove their name at any time without A being involved
  and without asking. Neither needs the other's agreement to stop.

**Whose note shows on a shared page** is the one part of this still open. The
encounter note is each person's own by an earlier decision, so a page with two
names may carry two accounts of the same meeting. Showing both, attributed, is
probably right and is certainly the most honest; showing only the sharer's is
simpler. Worth deciding before the page is built rather than after.

**Identity.** Phase 1 has no accounts on purpose. A shared garden needs
*something* — enough to prove a plot is yours across a reinstall, and no more
than that. Sign in with Apple, or a device-held key that signs plot updates,
would both work. The seed must not become the login: it is handed to strangers
by design.

The invitation above needs a little more than a plot needs: A's device has to be
able to name B as somebody the service can reach, without A learning anything
about B they did not already have. The obvious shape is that the two phones
exchange an opaque contact token at the meeting, alongside the seed — one more
field in `ExchangePayload`, decided once, and impossible to add retrospectively
to meetings that have already happened.

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
