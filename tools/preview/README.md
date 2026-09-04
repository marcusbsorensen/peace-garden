# tools/preview

`plant_model.py` is a hand-maintained port of `Packages/SeedCore` — the genome,
the growth model and the geometry — and `preview.py` renders it to PNG. It
exists because the Swift needs a Mac with Xcode and this does not, so a plant
can be *looked at* while the maths is being written.

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
holds twelve plants — one per family, found by a recorded deterministic search —
at four ages each: one before it flowers, one at first full opening, and two
half a cycle apart in the flush, well past maturity.

For each it records the genome scalars, the growth state, and **the per-node
bloom placements**: every drawn flower's `t`, its final `budSwell` and
`bloomOpen`, and its `scale`. That last part is the point. It is exactly what
drifted, and it is invisible in a vertex count — a mesh cannot tell a bud from a
small flower.

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

## What it does not cover

Twelve plants is a sample, and it is worth being plain about what a sample of
twelve cannot see.

- **The geometry itself.** The vectors stop at the bloom placements. The stem
  sweep, the leaves and the petals are not compared, and the port is known to be
  behind on several of them — the crozier and the apex point in `build_skeleton`,
  the `leaf.taper.N` stream, the `bloom.lean.N` stream, the `maturity` vertex
  attribute, and twelve palette draws (marbling and leaf venation).
- **Anything rarer than about one seed in twelve.** `stem.nodeCount` is rounded
  half-away-from-zero by Swift and half-to-even by Python's `round`, so the two
  disagree wherever the product lands exactly on a half — lotus, succulent and
  vine, about one seed in twenty-seven. `peace-garden-port-vector-0` is a lotus
  and does not happen to be one of them. Reproduce with the entropy
  `nodecount-30`: SeedCore grows three nodes and the port grows two.
- **The name.** It is recorded and compared, and it does not agree today. See
  below.

## Known divergence: the plant's name

`check_port.py` currently fails on one field, `name.full`, for all twelve
plants, and this is a real finding rather than a flaw in the check.

SeedCore stopped drawing the genus on 3 September 2026 and started reading it
off the flower — `PlantName.roots` maps a family and a merosity to one of the
twenty-four heads — and replaced the two-syllable epithet vocabulary with
`Epithet`, which says only what is checked to be true of the plant. The port
still draws `name.genusHead` and glues together `name.epithetHead` and
`name.epithetTail`, which is what the app did three months ago. Every caption
`preview.py` has printed since is a name no plant in the garden has.

The genus **endings** still agree exactly — *Cerea* against *Selea*, *Fenellea*
against *Ithellea* — because the middle and the tail are still drawn from the
same labels. It is the head and the epithet that have moved.

Bringing the port forward means porting `Epithet.swift`, and `Epithet` reads
`palette.marbling`, which is one of the twelve palette draws the port is also
missing. So it is a real piece of work rather than a line, and it wants doing
deliberately with renders looked at, not folded into something else.
