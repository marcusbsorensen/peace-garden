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

## What is left

- **The centre dome of a large solitary bloom has a hard bright rim.** Visible
  on the poppy and the lotus in the preview sheet, less so in the app. It is the
  existing centre treatment scaled up rather than anything new, and it is a
  shading question rather than a geometry one.
- **Leaves stay on the main stem's nodes in all three forms.** As specified —
  the branches of an umbel are bare in life, and leaves on them would be a
  fourth thing to tune.
- **`tools/preview` has drifted further.** The branch code in it is a faithful
  mirror written alongside the Swift, but the stems there still lack
  `apexPoint`, the bloom lag and the foot dome. `SeedCore` is authoritative;
  the preview is for judging shape.
