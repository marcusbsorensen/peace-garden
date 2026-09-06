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

**The wild fields hold what is released.** Settled 5 September 2026, and it is
a requirement on the plot service rather than a feature to add afterwards: a
plot can empty, and what leaves it has somewhere to go.

Phase 1 already lets one plant go — *Release to the wild fields*, held for three
seconds, in `PlantDetailView`. Today that removes it from the phone and the
phrase is a name for the action. In phase 2 it becomes a place: a released plant
stands in a wild area of the shared garden with **no name, no sender and no
date** — the plant alone, which is the only part of it that was never anybody's
to disclose.

Two things follow, and both are cheaper to build in than to add:

- **Releasing is one person's.** The other's copy stays where it is, the same
  rule as deleting above. A plot service that treats a hybrid as one row shared
  between two people has to let one of them stand down from it without the row
  going.
- **A released plant is unattributed for good.** It carries no lineage back to
  either gardener, so the invitation below can never be offered on it and no
  later consent can put a name on it. That is the difference between releasing
  a plant and un-sharing one.

Whether a released plant can be found again by the person who released it is
open. Everything above works either way, and answering it needs a real garden to
look at.

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

**A page with two names shows both notes, attributed.** Settled.

The encounter note is each person's own, written on their own phone and never
sent to the other, so two accounts of one meeting can disagree — one says
Margate and the other says on the winds, one keeps the date and the other does
not. That is the honest record of what happened, and reconciling it would be
inventing a version neither person wrote. The page presents two voices, in the
sharer's order: their share is what made the page.

Three things follow, and the third is the one that bites.

- **Accepting is publishing.** B is not agreeing to a name on a page, B is
  agreeing to publish a note they wrote for themselves. So the invitation has
  to show B their own note as it will appear, let them edit it there — the
  machinery exists, it is "Tell it differently" — and let them accept with
  their name and no note at all. An invitation that publishes prose somebody
  wrote privately, on a yes they gave to a question about their name, is a
  trick.

  **A needs the same screen, and this said only B for a long time.** The
  asymmetry was never argued for; it came from writing the invitation down and
  not the share. A wrote that note for themselves too, before any of this
  existed, and *share this plant* is a question about a plant. So the share flow
  shows A their own note as it will appear, lets them edit it there with the
  same machinery, and lets them share with their name and no note at all. The
  test is one sentence and it applies to both of them: **nothing publishes prose
  on a yes given to a different question.**
- **A note becomes user-generated content shown to strangers.** It joins the
  guest books in needing reporting, blocking and deletion. Two surfaces, not
  one, and the note is the surface people will have written most freely on,
  because until now nobody could read it.
- **The coordinate must not go up with it.** `EncounterNote` can carry one, and
  the consent that put it there was *both of us agree to keep this*, on two
  phones that make no network request — see docs/PLACE.md. That is not consent
  to publish the spot to the internet, and treating it as such would be the
  single worst thing this app could do with the most careful thing in it. A
  published note carries the place as it was *named* and never the coordinate,
  unless somebody is asked that question separately and answers it.

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

## The Winds — a third kind of meeting

Marcus's, 6 September 2026, and unbuilt. Written down while it is fresh rather
than built, because it changes what the app claims rather than adding to it.

**The idea.** Somebody who cannot easily meet a person face to face — housebound,
isolated, or simply not wanting to be seen — sets their seed onto The Winds. It
waits there. Another seed, set free the same way by somebody else, meets it. The
plant that comes of the pair stands in its own part of the shared garden, and it
shows up in both people's apps.

### The sentence that settles it

> **The seeds have met, not the people.**

That is Marcus's, and it is the whole design in six words. The worry it answers
was that a plant grown by two strangers who never met would make the app's
central claim false. It does not, because the claim is about a meeting and a
meeting happened — between two seeds, in a place made for it.

It also produces the taxonomy the app has been missing. **Three kinds of
meeting**, and the app currently ships one and a half:

| | Who is present | Who is addressed | Built |
| --- | --- | --- | --- |
| **The tap** | Two people, one room, phones touched | Each other | Yes |
| **The link** | One person sending | Somebody they chose | Yes |
| **The Winds** | One person casting | Nobody | No |

The first two are meetings between people. The third is a meeting between seeds,
and saying so is what keeps every existing sentence honest instead of quietly
widening *meeting* until it means nothing.

### What it costs in words

Two strings, and they should be looked at before any code:

- **`tagline` — "A plant grown from a meeting."** Survives untouched. A meeting
  happened; the sentence never said between whom.
- **`about1` — "Peace Garden makes a plant out of two people meeting."** Does
  *not* survive. It is true of the tap and the link and false of The Winds. It
  needs either a widening or a companion sentence, in forty-three languages.

**The privacy page does not survive either.** `privacy1`, written 6 September,
says there is *no server holding a copy*. The Winds is a server holding seeds.
That page is six strings in forty-three languages and it would have to be
rewritten before The Winds ships, not after.

### The tension worth naming now

It was proposed for people who would rather not share information, and the
instinct is right — but the axis needs saying out loud, because it would be an
unpleasant thing to notice later.

The Winds removes **social** exposure: no meeting, no room, no being seen, and
plausibly no name attached to anything. It increases **technical** exposure: a
seed sits on a server until it pairs, which is the one thing phase 1 has
refused to do at all. Those are different axes and both are real. A page
offering The Winds has to be honest about the second while delivering the
first.

### Where the plants stand, and what The Winds is not

**Not an eleventh area of the map.** The ten are a projection of the ten themes'
own positions onto two principal components; an eleventh has no coordinates and
would break the arrangement the arrow keys walk. The Wild Fields is already the
precedent — a named place reached from the menu rather than a cell on the grid —
and wind-grown plants belong somewhere like it.

**The Winds and the Wild Fields are opposites and must not be confused.** The
Wild Fields is where a plant is *released*, at the end of its life with you.
The Winds is where a seed is *cast*, before there is a plant at all. One is
letting go of something grown; the other is offering something ungrown.

**A naming hazard, flagged rather than solved.** `docs/SEEDS-ON-THE-WIND.md`
already uses that phrase for the *link* path — the second kind of meeting, not
the third. If The Winds is the name for the third, that document's title now
points at the wrong one, and a later reader will lose an hour to it.

### What it needs that does not exist

- **A server holding seeds in a queue.** Phase 1 has none, deliberately.
- **A pairing rule**, which is the whole feel of the thing. Random, or in order
  of arrival? That is the difference between a lottery and a queue, and people
  can tell.
- **A way back.** The plant appears in *both* apps, so either the server reaches
  out or each app asks. Phase 1 never does either.
- **An answer for the waiting.** What the app shows between casting and pairing,
  and whether a seed that never pairs expires or waits forever. A promise the
  app cannot keep is worse than no promise.

### The part that is cheaper than it looks

PHASES.md says of guest books: *this is user-generated content shown to
strangers, which brings with it, and none of it is optional: reporting,
blocking, moderation, a way to delete a book entry and a way to delete an
account. Budget for that before building the pretty part.*

**The Winds need not carry any of that.** If a wind-meeting is wordless — no
name, no note, no guest book, nothing either person typed — then there is
nothing to report and nothing to moderate. Two seeds meet and a plant exists.
That makes the third kind of meeting potentially the **cheapest** social feature
in the app, and it is cheap for the same reason it is kind: nobody is on show.

That is an argument for keeping it wordless even when it would be easy to add a
name, and it should be decided on purpose rather than drifted into.

### Questions before any of it is built

- Can a cast seed be withdrawn, and what happens to a pairing already made?
- Does the same seed meet more than once, or is casting it spending it?
- Does either person learn anything about the other at all? If not, what does
  the plant's *with* line say, in a screen built around naming somebody?
- Does the app say a seed is still waiting, and for how long is that bearable?

## Open questions

- Does a plant ever die, or go to seed? A garden that only accumulates loses
  the thing that makes a real one worth visiting. But a plant that dies takes a
  memory of a meeting with it.
- Can two people who have already met cross again? Today, yes, and they get a
  different plant each time, because both nonces go into the encounter. Whether
  that should be rate-limited is a product question, not a technical one.
- Should the peace garden be one shared place, or many? One place is the idea.
  One place is also where every moderation problem lives.
