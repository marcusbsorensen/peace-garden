#!/usr/bin/env python3
"""Hold `plant_model.py` to the plants SeedCore actually grows.

    python3 tools/preview/check_port.py

**`plant_model.py` is a hand-maintained port of `Packages/SeedCore`, and it is
how this garden gets looked at.** Nobody can see a vertex buffer, so the defects
this repository has caught have been caught by rendering a plant in Python and
looking at it: every leaf the same size, a spire of identical heads at even
spacing, a husk wider than the plant was tall. None of those was visible in a
test. All of them were obvious on screen.

Which makes a drifted port worse than no port. A render taken from one is a
decision made about a plant that does not exist, and the port has drifted three
times — most recently by missing the per-node bloom `ceiling` and the size taper
entirely, so every spike it ever drew carried identical fully-open heads at even
spacing. Renders that earlier sessions reasoned from were wrong.

This is the same bargain `tools/site/export.py --check` strikes with the passage
banks. `vectors.json` is committed; SeedCore's `PortVectorTests` says the file is
what the Swift computes, and this says the file is what the port computes. CI
runs both, so neither language can move without the other following it or
somebody deciding, in writing, that it should not.

**When this fails after a deliberate change to the Swift**, re-record the file
first — `PEACE_GARDEN_RECORD_VECTORS=1 swift test --package-path Packages/SeedCore
--filter PortVectorTests` — and then bring `plant_model.py` along until this
passes. It names every field that differs, so what has to change is on screen
rather than to be hunted for.

**A sample is green about what it looks at, and nothing else.** Twelve of the
plants in the file are a fair draw, one family each. Three are not: they are
`nodecount-30`, `nodecount-41` and `nodecount-363`, and they are in the file
because `stem.nodeCount` rounds a half away from zero in Swift and to even in
Python, so the two languages grew a different plant on about one seed in
twenty-seven and no sampled seed happened to be one of them. This check was
green on that for months. When a fault is found that a sample could not see, the
seed that shows it belongs in the file — see `chosenSeeds` in
`PortVectorTests.swift`.

The file also records each plant's `name.full`, and this deliberately does not
compare it. See the note in `TRAITS` below.

Nothing here imports numpy or Pillow. Those are the render's dependencies, and
the CI job that runs this installs nothing — see the note at the top of
`plant_model.py`, which is why the sweep is the only part of it that wants them.
"""

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/preview"))
sys.path.insert(0, str(ROOT / "tools/reference"))

from derivation_reference import mint_seed                       # noqa: E402
from plant_model import (                                        # noqa: E402
    STEM_SEGMENTS,
    Genome,
    bloom_placements,
    growth_state,
    node_indices,
    stalk_count,
)

VECTORS = ROOT / "tools/preview/vectors.json"

# How close two numbers have to be to count as the same number.
#
# One unit in the last place `vectors.json` records, which is six decimals. The
# file cannot be compared exactly: the geometry is `Float` on the Swift side and
# a double here, and a `Float` carries a little over seven significant decimal
# digits — so a bloom's scale legitimately differs in the eighth. Six decimals
# is inside what both languages hold and outside where their disagreement lives.
#
# It is not a fudge for real drift. The smallest thing recorded is the stem's
# base radius, a few thousandths, and the drifts that have actually happened
# here moved values by tenths.
TOLERANCE = 1e-6

# Every genome scalar the file pins, as `name in the file -> attribute here`.
#
# Written out rather than derived from the attribute names, because the two
# vocabularies genuinely differ — SeedCore says `foliage.length` and this file
# says `leafLength` — and a mapping that guessed would go quiet exactly when a
# trait was renamed on one side, which is the failure this whole tool exists to
# stop.
TRAITS = {
    "form.archetype": "archetype",
    "form.merosity": "merosity",
    "form.vigour": "vigour",

    "branching.inflorescence": "inflorescence",
    "branching.count": "branchCount",
    "branching.spread": "branchSpread",

    "stem.height": "height",
    "stem.baseRadius": "baseRadius",
    "stem.taper": "taper",
    "stem.lean": "lean",
    "stem.sway": "sway",
    "stem.twist": "twist",
    "stem.nodeCount": "nodeCount",

    "foliage.leavesPerNode": "leavesPerNode",
    "foliage.length": "leafLength",
    "foliage.widthRatio": "leafWidthRatio",
    "foliage.droop": "leafDroop",
    "foliage.fold": "leafFold",
    "foliage.pitch": "leafPitch",
    "foliage.serration": "serration",
    "foliage.teeth": "teeth",
    "foliage.veinCount": "veinCount",
    "foliage.tipSharpness": "leafTipSharpness",

    "bloom.petalCount": "petalCount",
    "bloom.layers": "layers",
    "bloom.length": "petalLength",
    "bloom.widthRatio": "petalWidthRatio",
    "bloom.curl": "curl",
    "bloom.headPitch": "headPitch",
    "bloom.centreRadius": "centreRadius",

    "tempo.germinationHours": "germinationHours",
    "tempo.seedlingDays": "seedlingDays",
    "tempo.vegetativeDays": "vegetativeDays",
    "tempo.buddingDays": "buddingDays",
    "tempo.bloomDays": "bloomDays",
    "tempo.opensByDay": "opensByDay",

    # `name.full` is deliberately absent, and it is still in `vectors.json`.
    #
    # It stays in the file because it is a genuinely useful label: a reader
    # scanning the vectors wants to know which specimen a block of numbers
    # describes, and *Selea vulgaris* says that where a seed hex does not. It is
    # not compared because the name is Swift's alone. `plant_model.py` grows
    # geometry so that a plant can be looked at, and a name is the one thing
    # about a plant no render shows — so a naming implementation there could
    # never be checked the way everything else in this file is checked, and when
    # there was one it silently fell three months behind. The port now has no
    # opinion about names at all, which is the only state in which it cannot be
    # wrong about them.
    #
    # If the port ever grows one — it would mean porting `Epithet`, and
    # `Epithet` reads `palette.marbling`, which the port also lacks — this line
    # comes back and the recorded name becomes a compared field again.
}

GROWTH = ["stage", "heightScale", "leafUnfurl", "budSwell", "bloomOpen", "flush", "flushDepth"]
PLACEMENT = ["kind", "index", "t", "budSwell", "bloomOpen", "scale"]


def shown(value):
    """A number written the way the file writes it, and anything else as it is."""
    if isinstance(value, float):
        return f"{value:.6f}"
    return str(value)


def differs(expected, actual):
    """Whether two recorded values disagree.

    Floats within `TOLERANCE`; everything else exactly. `bool` is checked before
    `float` on purpose — in Python a bool *is* an int, so `opensByDay` would
    otherwise be compared as 1.0 against True and never fail.
    """
    if isinstance(expected, bool) or isinstance(actual, bool):
        return expected is not actual
    if isinstance(expected, float) or isinstance(actual, float):
        return abs(float(expected) - float(actual)) > TOLERANCE
    return expected != actual


def compare(problems, where, fields, expected, actual):
    """Every field of one record, appending `(name, expected, actual)` rows."""
    for field in fields:
        if differs(expected[field], actual[field]):
            problems.append((f"{where}.{field}", expected[field], actual[field]))


def check(plant, problems):
    entropy, seed = plant["entropy"], bytes.fromhex(plant["seed"])
    name = f"{plant['genome']['form.archetype']} ({entropy})"

    # The seed is claimed to be what minting that entropy gives. Cheap to check
    # and worth checking: if it ever failed, everything below would be comparing
    # two different plants and every field would look drifted at once.
    minted = mint_seed(entropy.encode())
    if minted != seed:
        problems.append((f"{name}.seed", plant["seed"], minted.hex()))
        return

    genome = Genome(seed)
    for field, attribute in TRAITS.items():
        recorded = plant["genome"][field]
        grown = getattr(genome, attribute)
        if differs(recorded, grown):
            problems.append((f"{name} genome.{field}", recorded, grown))

    for number, sample in enumerate(plant["ages"], start=1):
        age = f"{name} age {number} ({sample['ageSeconds']:.0f}s)"
        growth = growth_state(genome, sample["ageSeconds"], sample["hourOfDay"])
        compare(problems, f"{age} growth", GROWTH, sample["growth"], growth)

        # The nodes' places on the stem and the number of stalks, both without
        # sweeping a stem — see `node_indices` and `stalk_count`.
        placements = bloom_placements(
            genome,
            growth,
            [index / STEM_SEGMENTS for index in node_indices(genome.nodeCount)],
            stalk_count(genome, growth["heightScale"]),
        )
        recorded = sample["blooms"]
        if len(recorded) != len(placements):
            problems.append((f"{age} bloom count", len(recorded), len(placements)))
            continue
        for index, (was, is_) in enumerate(zip(recorded, placements)):
            compare(problems, f"{age} blooms[{index}]", PLACEMENT, was, is_)


def main():
    if not VECTORS.exists():
        sys.exit(
            f"{VECTORS.relative_to(ROOT)} is missing. Record it with\n"
            "  PEACE_GARDEN_RECORD_VECTORS=1 swift test --package-path Packages/SeedCore"
            " --filter PortVectorTests"
        )

    document = json.loads(VECTORS.read_text())
    problems = []
    for plant in document["plants"]:
        check(plant, problems)

    if not problems:
        # The tally is split, because the two halves of the file are not the
        # same kind of thing and a single count reads as though they were. The
        # first twelve are a fair sample, one family each. The rest are seeds
        # somebody chose because they trigger a fault a sample cannot see, and
        # a repeated family in the list is the point of them rather than a sign
        # the search has gone wrong.
        plants = document["plants"]
        sampled = [p for p in plants if p["entropy"].startswith("peace-garden-port-vector-")]
        chosen = [p for p in plants if p not in sampled]
        blooms = sum(len(a["blooms"]) for p in plants for a in p["ages"])
        ages = sum(len(p["ages"]) for p in plants)
        print(f"in step — {len(plants)} plants, {ages} ages, {blooms} blooms")
        print(f"  sample  {', '.join(p['genome']['form.archetype'] for p in sampled)}")
        if chosen:
            print(f"  chosen  " + ", ".join(
                f"{p['entropy']} ({p['genome']['form.archetype']})" for p in chosen))
        return

    print("The port and SeedCore have come apart:")
    # Capped, because a port that has fallen a long way behind produces one line
    # per field per age and drowns the first one — which is usually the cause of
    # all the rest. The roll-up below survives the cap.
    for name, expected, actual in problems[:40]:
        print(f"  • {name}: committed {shown(expected)}, port {shown(actual)}")
    if len(problems) > 40:
        print(f"  … and {len(problems) - 40} more")

    fields = sorted({name.split(" ")[-1] for name, _, _ in problems})
    print(f"\n{len(problems)} differences over {len(fields)} fields: {', '.join(fields)}")
    print(
        "\nIf SeedCore changed on purpose, re-record the vectors with\n"
        "  PEACE_GARDEN_RECORD_VECTORS=1 swift test --package-path Packages/SeedCore"
        " --filter PortVectorTests\n"
        "and then bring tools/preview/plant_model.py along with it."
    )
    sys.exit(1)


if __name__ == "__main__":
    main()
