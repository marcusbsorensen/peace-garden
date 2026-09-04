# tools/preview

`plant_model.py` is a hand-maintained port of `Packages/SeedCore` — the genome,
the growth model and the geometry — and `preview.py` renders it to PNG. It
exists because the Swift needs a Mac with Xcode and this does not, so a plant
can be *looked at* while the maths is being written.

**It is geometry, and it names nothing.** SeedCore gives every plant a
binomial; the port gives none, on purpose. See "The port does not name plants"
below.

Looking at it is not a convenience. Every defect this repository has caught by
eye was caught here: every leaf the same size, a spire of identical heads at
even spacing, a husk wider than the plant was tall. None of those was visible in
a test, and all of them were obvious on screen.

Which is what makes a drifted port worse than none. A render taken from one is a
decision made about a plant that does not exist, and this file has drifted three
times — most recently by missing the per-node bloom `ceiling` and the bloom size
taper entirely, so every spike it ever drew carried identical fully-open heads at
even spacing. Renders that earlier sessions reasoned from were wrong about it.

## The check

`vectors.json` is committed, and both sides are held against it. It is the same
bargain `tools/site/export.py --check` strikes with the passage banks.

| | says |
|---|---|
| `PortVectorTests` (in the SeedCore suite) | the file is what the **Swift** computes |
| `python3 tools/preview/check_port.py` | the file is what the **port** computes |

CI runs both, in different jobs, so a failure says which side moved. The file
holds fifteen plants at four ages each: one before it flowers, one at first full
opening, and two half a cycle apart in the flush, well past maturity.

For each it records the genome scalars, the growth state, and **the per-node
bloom placements**: every drawn flower's `t`, its final `budSwell` and
`bloomOpen`, and its `scale`. That last part is the point. It is exactly what
drifted, and it is invisible in a vertex count — a mesh cannot tell a bud from a
small flower.

### Twelve found, three chosen

The first twelve are one per family, found by a recorded deterministic search —
a fair sample, and nobody had to pick them.

The last three are picked, and the difference matters. `nodecount-30`,
`nodecount-41` and `nodecount-363` are in the file **because they trigger a
specific class of fault**, not as more sample. A sample can only be green about
what it happens to contain, and for months these twelve were green while the two
languages grew a different number of nodes on about one seed in twenty-seven —
see the next section. The seed that shows a fault a sample could not see belongs
in the file permanently, and it should say in its own docs that that is what it
is for; otherwise the next person shortens the file by deleting it.

`PortVectorTests.chosenSeeds` carries the same note on the Swift side, and
`vectors.json`'s own `note` field says which plants are which, so a reader who
has only the file still knows.

`check_port.py` needs no numpy and no Pillow. Those are the render's
dependencies and the CI job installs nothing, which is why the numpy import in
`plant_model.py` is optional and why the sweep is the only part of the file that
wants it. `bloom_placements`, `node_indices` and `stalk_count` are numpy-free
for the same reason.

## Re-recording

When the Swift changes on purpose, the Swift test goes red first. Re-record:

```sh
PEACE_GARDEN_RECORD_VECTORS=1 swift test \
    --package-path Packages/SeedCore --filter PortVectorTests
python3 tools/preview/check_port.py
```

The check will then fail until `plant_model.py` has been brought along. It names
every field that differs, with the committed value and the port's, so what has
to change is on screen rather than to be hunted for. Commit the two together.

## Halves round away from zero

Swift's `.rounded()` rounds a half **away from zero**. Python's `round` rounds a
half **to even** — banker's rounding. They agree on every other value, which is
precisely what makes the difference dangerous: it is invisible in almost every
plant and wrong in the rest.

`plant_model.rounded` is the port's rule for every `.rounded()` in the Swift.
**Never use the builtin `round` where the Swift says `.rounded()`.** Floors are
a separate matter and stay as they are: the Swift says `.rounded(.down)` in
`Colouring` and the port says `math.floor`, which agree exactly.

It mattered most in `stem.nodeCount`, which is
`(integer("stem.nodeCount", 2...9) * nodeScale).rounded()`. The left-hand side is
a whole number, so the product is a small rational and lands exactly on a half
far more often than any continuous trait would: fern 9.5, lotus 1.5, 2.5, 3.5 and
4.5, vine 8.5, succulent 10.5.

Only half of those actually disagreed. Half-to-even goes to the *even*
neighbour, which is the same answer as half-away whenever the integer part is
odd — so 1.5, 3.5 and 9.5 were always safe and 2.5, 4.5, 8.5 and 10.5 were not.
Over the four thousand entropies `nodecount-0` … `nodecount-3999` that is 146
seeds, about one in twenty-seven: lotus 71, vine 40, succulent 35, fern none.
The worked example is `nodecount-30`, a lotus where SeedCore grows three nodes
and the port grew two.

Four other places say `.rounded()` in the Swift, and all four are now on the
right rule. None of them was reachably wrong, and that was checked rather than
assumed: `branchCount` never lands on a half over those four thousand seeds;
`node_indices` lands on one exactly once over `nodeCount` 1…40, at 29, which is
above the ceiling of 20 that `GenomeTests` declares; `build_branches` never does
over a thousand-step sweep of `branchSpread`; and `add_tube` cannot, because its
`v` is `r / (rows - 1)` and the product is `r`.

## The port does not name plants

SeedCore names every plant. `plant_model.py` has no `name`, and that is a
decision rather than a gap.

The port draws geometry so a plant can be *looked at*, and a name is the one
thing about a plant that no render shows. So a naming implementation here could
never be checked the way everything else here is checked — and it was not. It
sat three months behind: SeedCore stopped drawing the genus on 3 September 2026
and started reading it off the flower (`PlantName.roots` maps a family and a
merosity to one of the twenty-four heads), and replaced the glued two-syllable
epithet with `Epithet`, which says only what has been checked to be true of the
specimen. The port went on gluing `name.epithetHead` to `name.epithetTail` and
printing *pallicola* — "pale-dwelling", which is not a thing a plant can be —
under `preview.py`'s captions.

Porting it was considered and rejected. `Epithet` reads `palette.marbling`, one
of twelve palette draws the port also lacks, so it is a real piece of work whose
only payoff would be a string nothing here displays. A wrong name nobody reads
costs nothing right up until somebody wires it up believing it agrees with the
app. Having no opinion is the only state the port cannot be wrong in.

Deleting the draws could not move anything else and did not. `GeneSource` draws
by *label* — `unit(label)` hashes the seed with the trait's name — so there is no
stream whose position a missing draw could shift. It was proved rather than
argued: a SHA-256 over every position, normal, UV and index of twenty-four plants
at sixteen ages each is byte-identical before and after.

`vectors.json` still records `name.full`, as a label — it is genuinely useful to
see which specimen a block of numbers describes — and `check_port.py`
deliberately excludes it from the compared set.

## What it does not cover

Fifteen plants is still a sample, and it is worth being plain about what it
cannot see.

- **The geometry itself.** The vectors stop at the bloom placements. The stem
  sweep, the leaves and the petals are not compared, and the port is known to be
  behind on several of them — the crozier and the apex point in `build_skeleton`,
  the `leaf.taper.N` stream, the `bloom.lean.N` stream, the `maturity` vertex
  attribute, and twelve palette draws (marbling and leaf venation).
- **Anything rare that nobody has thought of yet.** The rounding fault was the
  one-in-twenty-seven case, and it is covered now only because somebody went
  looking for it and put the seed in the file. Three chosen seeds do not make a
  sample of fifteen into a proof; they close one hole that had been found.
- **The name**, which is no longer compared and no longer a divergence. It is
  SeedCore's, and the port has nothing to say about it.
