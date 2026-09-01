# Plant forms: getting off the tower

Written 1 September 2026, from looking at three plants side by side and finding
they were the same plant three times. This is a build spec: every decision is
made. Nothing here is started.

## What is wrong today

**Every plant is one unbranched stem.** `PlantSkeleton` is `stem`, `nodes` and
`apex` — a single swept path, leaves at the nodes, blooms either at the tip or
at every node. There is no other topology in `SeedCore`, and no way to express
one.

**`ArchetypeProfile` is fifteen scalar multipliers over that one shape.**
Height, thickness, node scale, leaf length and width and droop, petal count and
length and width and curl, head pitch, centre scale, bloom presence, sway, and a
single `bloomsAtNodes` flag. Twelve archetypes, all of them the same silhouette
at different proportions.

**So four of the twelve names are not true.** They are the app's own words, in
[Archetype.swift](../Packages/SeedCore/Sources/SeedCore/Genome/Archetype.swift):

| Archetype | Says it is | Actually is |
| --- | --- | --- |
| `plume` | *"feathery many-branched inflorescence"* | a raceme with narrow petals |
| `umbel` | *"flat-topped cluster on fine stalks"* | a raceme with small ones |
| `poppy` | *"single crumpled bloom on a bare stem"* | blooms all the way up |
| `orchid` | *"few, large, asymmetric blooms"* | few large blooms, up a stalk |

The vocabulary is already in the code. Only the geometry is missing.

**And it is why a plant reads as too tall.** A tower spends its whole budget on
height because there is nowhere else to spend it. A plant that branches is
shorter and wider for the same amount of plant, which is the real answer to a
stem that runs up into its own name — the framing fix that keeps it out of the
chrome treats the symptom.

## Three forms

One new enum, `Form`, on the archetype rather than on the genome. Three cases,
and every archetype claims one.

### `.raceme` — blooms on the axis

What exists today, unchanged, and it stays the commonest. A single stem with
blooms at the tip or up the nodes. Six archetypes: **spire, star, bell, vine,
succulent, fern.**

Nothing to build. It is named so that the other two are choices rather than
exceptions.

### `.head` — stalks off the upper stem, a bloom on each

The upper stretch of the stem gives off between three and seven stalks, each
sweeping out and up and ending in a bloom. Two archetypes: **umbel, plume.**

One parameter separates the flat cluster from the feathery spray, and it is
worth having as a number rather than as two more cases:

- **`spread` at 0 — a flat-topped head.** Every stalk leaves the stem within a
  short stretch near the top, and **the tips all reach the same height**, so a
  stalk from lower down is a longer stalk. That levelling is the whole reason a
  corymb reads as flat-topped rather than as a bundle; without it the head is a
  fan. This is `umbel`.
- **`spread` at 1 — an open spray.** The stalks leave over a much longer stretch
  of stem, at wider angles, and their tips are *not* levelled. This is `plume`,
  and it is the feathery many-branched thing the enum has been promising.

Stalks are set out on the same golden-angle divergence the leaves use
(`genome.foliage.divergence`), so they spiral round the stem rather than lining
up in a plane. A stalk starts at 45% of the main stem's radius where it leaves
it and runs out to a point through `apexPoint`, the same way the stem's own tip
does — a stalk is a stem, and should end like one.

### `.solitary` — a bare stem, one much larger bloom

No branching, few leaves, and everything the plant has goes into a single
terminal flower at around **2.2× the bloom scale of a raceme's**. Four
archetypes: **poppy, orchid, lotus, thistle.**

This is the form that most changes what the garden looks like, because it is the
one that is not a spike of anything. It is also the cheapest to build — it is
the existing apex bloom, larger, with `bloomsAtNodes` off and `nodeScale` down.

**Fewer blooms is what buys the size.** A spire carries a dozen small flowers
and cannot afford a large one; a poppy carries one and can afford nothing else.
The scale is not decoration, it is the same budget spent differently, and the
plants should look like they cost the same.

## Height comes down with it

`.solitary` and `.head` archetypes drop their `heightScale`, because a plant
that has somewhere else to put its growth stops putting it all upward:

| Archetype | Form | Height now | Height after |
| --- | --- | --- | --- |
| `poppy` | solitary | 1.0 | **0.75** |
| `orchid` | solitary | 1.0 | **0.85** |
| `lotus` | solitary | 0.85 | **0.7** |
| `thistle` | solitary | 1.15 | **0.9** |
| `umbel` | head | 1.1 | **0.9** |
| `plume` | head | 1.25 | **1.05** |

Six of twelve plants get visibly shorter and wider. The other six are towers on
purpose, and a spire that is a spire among poppies is a different thing from a
spire among spires.

## What the geometry needs

### `PlantSkeleton` becomes a tree

```swift
public struct Branch: Sendable {
    /// Where it leaves the main stem.
    public var origin: PathSample
    /// Its own swept path, base to tip.
    public var path: [PathSample]
}

public struct PlantSkeleton: Sendable {
    public var stem: [PathSample]
    public var nodes: [PathSample]
    public var apex: PathSample
    /// Empty for `.raceme` and `.solitary`.
    public var branches: [Branch]
}
```

Empty rather than optional: every consumer then walks the same list and the two
unbranched forms need no special case.

### `SkeletonBuilder`

`stem(genome:heightScale:segments:)` gains the form and emits the branches. Each
branch is integrated the same way the main stem is — step by step, so its curve
accumulates — rather than evaluated from a formula, for the reason already
recorded on `stem`: it is how a real one gets its shape.

**The levelling is the part to get right.** For `spread` near 0, a branch's
length is whatever reaches the target height from where it started, so it must
be solved for rather than drawn. Solve it by integrating the branch until it
crosses the target height and stopping there, not by scaling a fixed path — a
scaled path changes its curvature and the head stops looking flat.

**Branches grow with the plant.** A branch's length scales with `heightScale`
like everything else, so a head opens outward as the plant grows rather than
arriving whole. Before the plant is tall enough to have an upper stem there are
no branches at all, and a young `.head` plant is a raceme that has not divided
yet — which is what one is.

### `PlantBuilder`

- `addStem` adds a tube per branch, and each branch takes the same base dome
  treatment as the main stem where it joins. A branch leaving a stem is a join
  that will show if it is left open.
- `addBlooms` gains the three cases: raceme as today; head places one bloom at
  each branch tip; solitary places one at the apex at `bloomScale`.
- Leaves stay on the main stem's nodes in all three forms. Leaves on the
  branches of a head is a fourth thing to tune and it buys very little — the
  branches of an umbel are bare in life.

### `ArchetypeProfile`

Two new fields, and one existing one becomes redundant:

```swift
public var form: Form = .raceme
public var bloomScale: Double = 1
public var branchSpread: Double = 0
public var branchCount: Int = 5      // before the seed's own draw scales it
```

`bloomsAtNodes` stays and keeps its meaning for `.raceme`. For the other two
forms it is ignored, and the profile should not set it.

## Nothing new has to cross

Worth stating plainly, because it looks like a gap and is not.

The archetype is drawn from the seed —
`source.pick("form.archetype", from: Archetype.allCases)` in
[Genome.swift:190](../Packages/SeedCore/Sources/SeedCore/Genome/Genome.swift) —
and a crossed seed is a new seed derived from both parents. A hybrid's archetype
is therefore drawn afresh from the child's own seed rather than blended from its
parents', and **the form comes free with it.**

Every new per-plant trait — branch count, spread jitter, branch angle, stalk
length variation — is drawn the same way, `source.value(...)` and
`source.integer(...)` against the child seed. So:

- `Pollination` needs no change at all.
- Both phones derive the same form from the same seed without sending anything,
  which is the guarantee the whole exchange is built on.
- Two plants of the same archetype still differ, because their branch draws
  differ.

**Name the new draws carefully.** `GeneSource` keys are the compatibility
surface: a seed drawn today and a seed drawn after this lands must grow the same
plant, and they will only do so if the existing keys keep their names and their
ranges. Add `stem.branch.*` keys; change nothing that is already there.

## Framing

`PlantSceneBuilder.framing` already takes the greater of the height and width
constraints and already measures width as the larger of the x and z extents,
because the plant turns. A wide head is therefore framed correctly with no
change. Two things to look at rather than assume:

- **A flat-topped head is wide and short**, which is the case the width
  constraint was written for and has never actually been exercised.
- **`matureBounds` builds a whole extra mesh** to decide the camera distance. It
  will now build a branched one. Same cost, once per seed, but it is the first
  time that mesh has been the expensive one.

## Files this touches

- `Packages/SeedCore/Sources/SeedCore/Genome/Archetype.swift` — `Form`, the four
  new profile fields, the per-archetype assignments, the height changes.
- `Packages/SeedCore/Sources/SeedCore/Morphology/PlantSkeleton.swift` —
  `Branch`, the branch list, and the integration that solves for a levelled tip.
- `Packages/SeedCore/Sources/SeedCore/Morphology/PlantBuilder.swift` — branch
  tubes and their joins, and the three bloom cases.
- `Packages/SeedCore/Sources/SeedCore/Genome/Genome.swift` — the `stem.branch.*`
  draws.
- `Packages/SeedCore/Tests/SeedCoreTests/` — see below.

## How to know it is right

**Determinism first, because it is the one thing that cannot be fixed later.**
A seed drawn before this change must grow the same plant after it. The existing
tests cover a fixed seed's genome; extend them so a fixed seed's *mesh* is
covered too — vertex count and bounds are enough to catch a silent change, and
they are what would have caught a renamed `GeneSource` key.

Then: **one plant of each of the twelve archetypes, side by side, at full
bloom.** The whole point of this work is that a stranger can tell them apart. If
two of them are still the same silhouette, the forms are not carrying enough.

Then the growth sequence for a `.head` plant, which is the one with a new
behaviour over time: it should be a plain shoot, then a shoot that divides, then
an opening head — and the division should not appear between one frame and the
next.

Then a `.solitary` plant against a `.raceme` one on the same screen, to see
whether the bloom scale reads as *a large flower* or as *a flower drawn too
big*. That is a judgement, and it is the one number here most likely to be wrong
on the first attempt.
