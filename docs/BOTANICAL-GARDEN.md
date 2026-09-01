# The botanical garden

*The website a plant can be sent to.* Scoped 1 September 2026, not started.

A place you visit rather than a feed you scroll: plants submitted from phones,
laid out in themed areas the way a botanical garden lays out a tropical house
and a rock garden and a water garden, with paths between them.

This is phase 2, and [PHASES.md](PHASES.md) already holds the two questions it
has to answer before any of it is built. Neither is a coding problem and
neither is answered here.

## The thing worth knowing first

**The map already exists in the data.** It does not need commissioning from
imagination.

`Quotes.Theme` has ten cases — beginnings, waiting, renewal, light, pattern,
ground, travel, meeting, kinship, peace — and every one of them carries a
`position`: four numbers, one per `Dimension`.

| Dimension | 0 | 1 |
| --- | --- | --- |
| `company` | solitary | shared |
| `motion` | still | moving |
| `duration` | a moment | a long span |
| `register` | classic | quirky |

So the themes are already points in a four-dimensional space, placed
deliberately, with *waiting* still and long and solitary at one end and
*travel* moving and quirky at the other. Project that to two dimensions and you
have the garden's geography: which areas border which, which are a long walk
apart, where a path between two of them would naturally run.

That is worth doing before anyone draws anything, because a map derived from
the themes will feel *right* in a way an invented one will not — the tropical
house is next to the fernery for a reason, and here the reason is already
written down. It also means the map stays honest if the themes ever change.

Concretely: run a projection (PCA on the ten positions, or MDS on their
pairwise distances) and look at the result. Ten points is small enough to check
by eye and adjust by hand where a projection puts two areas somewhere a visitor
would find odd. The projection proposes; a person disposes.

## What a visitor does

- **Arrives at a map**, not a list. Ten areas, paths between them, drawn in the
  Interfulgent line — organic, unfolding, frond-like, the same vocabulary as
  `UnfurlingBackdrop` and the app icon's spiral. The paths are the interesting
  drawing problem: a path between *kinship* and *peace* should look like it
  grew there.
- **Walks into an area** and finds the plants whose passage came from that
  theme, each drawn live rather than photographed.
- **Looks at one plant**, and sees what the app shows: its name, its age, who
  grew it, the passage and its provenance, and the note if there is one. What a
  shared page says and whose names are on it is already decided — see the
  sharing decisions in `.claude/HANDOVER.md` and [PLACE.md](PLACE.md). **A
  published note never carries the coordinate.**
- **Follows a path** to a neighbouring area, because the neighbour is genuinely
  related along one of the four dimensions and the path can say which.

## The sub-themes

Ten areas is a garden; it is not yet a garden with rooms in it. The
`Dimension` axes give the subdivision for free: within *travel*, the classic end
and the quirky end are visibly different plants with visibly different lines —
Marcus Aurelius at one end, burdock burs and Velcro at the other, which is what
`register` was written to capture. A large area can be walked from one end to
the other rather than being one undifferentiated lawn.

Do not invent a second taxonomy. The one in the code is already load-bearing:
it decides which passage a pair receives, so a garden laid out on the same axes
is showing people the real structure rather than a decoration laid over it.

## What gets built

1. **A renderer in the browser.** The same one the seed landing page needs —
   see [SEEDS-ON-THE-WIND.md](SEEDS-ON-THE-WIND.md). Build it once, for both.
   The drift warning there applies here with more force, because a plant in the
   garden that does not match the plant on the phone is the one failure this
   project cannot survive: the whole claim is that a seed and a birthday
   determine a plant everywhere, forever.
2. **A submission path.** A plant goes from a phone to the garden. What travels
   is a seed, a birthday, a lineage, the names, and optionally a note — all of
   it already in `garden.json`, none of it an appearance. Kilobytes.
3. **A map.** Derived as above, then drawn.
4. **A moderation surface.** Notes are free text written by people, and they
   are published. PHASES.md is right that this is the part with teeth.

## What has to be decided before any of it

Both are in PHASES.md and both are restated here because they gate everything
above.

- **What identity a shared garden needs, when phase 1 deliberately has none.**
  A submitted plant has to be attributable enough to be co-signed by the other
  gardener and revocable by either, and the app currently has no accounts, no
  server and no way to prove you are the person who grew something. The opaque
  contact token agreed at a meeting is the thread to pull.
- **Moderation.** A guest book invites what guest books invite. Free-text
  notes, published, attached to real first names.

A third, smaller, which the map raises on its own: **a plant's theme comes from
its pair, and a pair's theme is rolled from `pairID`.** A plant grown alone has
no pair and therefore no area to stand in. Either the garden holds only plants
grown with somebody — which is a defensible and rather beautiful rule, and
matches *grown from meetings* — or solitary seeds need a theme of their own,
which they already have: each seed carries one as a trait. Decide which, because
it changes what the front page of the garden is *for*.

## What this is not

Not a feed, not a profile, not a follower count, not a map with pins on it
showing where people met. The coordinates stay on the phones that measured
them; that consent was about two phones making no network request, and
publishing them later would be taking something that was never given.
