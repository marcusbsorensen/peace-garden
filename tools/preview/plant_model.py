"""
A port of SeedCore's genome, growth and geometry into Python.

Why this exists: the Swift is the real implementation, but it can only be run on
a Mac with Xcode. This port makes the same plants without one, so the shapes,
the growth stages and the colours can be looked at while the maths is being
written. `preview.py` renders them to PNG.

It is a sketch, not a second source of truth. `SeedCore` is authoritative for
everything here except the derivation primitives, which come from
`tools/reference/derivation_reference.py` and are pinned by test vectors on both
sides.

**It is geometry, and it names nothing.** A plant's binomial is the one thing
about it a render cannot show, so a naming implementation here could never be
checked the way the rest of this file is checked — and when it was tried it fell
three months behind without anything saying so. `SeedCore` names plants;
`Genome` here has no `name`, and the note where it used to be derived says why.

**And it is checked.** `check_port.py` holds the genome, the growth state and
the bloom placements in this file against `vectors.json`, which SeedCore's own
`PortVectorTests` writes. This file drifted three times before that existed, and
the last time it was missing the per-node bloom ceiling and the size taper — so
every spike it ever drew carried identical fully-open heads at even spacing, and
renders that real decisions were taken from were wrong. See `README.md` here.
"""

import math
import sys
from pathlib import Path

# **Optional, and that is deliberate.** numpy is the sweep's dependency and
# nothing else's: the genome, the growth model and the bloom placements are
# plain floats. `check_port.py` runs in a CI job that installs nothing, so
# importing this file has to succeed without numpy present and only the geometry
# below is allowed to want it.
try:
    import numpy as np
except ModuleNotFoundError:  # pragma: no cover — only ever true inside CI
    np = None

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "reference"))
from derivation_reference import (  # noqa: E402
    DOMAIN_TRAIT,
    gene_u64,
    INHERIT_BLEND,
    INHERIT_P0,
    INHERIT_P1,
    MASK64,
    digest,
    gene_unit,
    mix64,
)

GOLDEN = 0x9E3779B97F4A7C15


# --------------------------------------------------------------- gene source

class GeneSource:
    """Mirror of SeedCore/Genome/GeneSource.swift."""

    def __init__(self, seed, parents=None):
        self.seed = seed
        self.parents = tuple(sorted(parents)) if parents else None

    def unit(self, label):
        if self.parents is None:
            return gene_unit(self.seed, label)
        roll = gene_unit(self.seed, "inherit:" + label)
        if roll < INHERIT_P0:
            return gene_unit(self.parents[0], label)
        if roll < INHERIT_P1:
            return gene_unit(self.parents[1], label)
        if roll < INHERIT_BLEND:
            a = gene_unit(self.parents[0], label)
            b = gene_unit(self.parents[1], label)
            return a + (b - a) * gene_unit(self.seed, "blend:" + label)
        return gene_unit(self.seed, "mutate:" + label)

    def value(self, label, lo, hi):
        return lo + self.unit(label) * (hi - lo)

    def integer(self, label, lo, hi):
        span = hi - lo + 1
        return lo + min(span - 1, int(self.unit(label) * span))

    def chance(self, label, probability):
        return self.unit(label) < probability

    def pick(self, label, options):
        return options[min(len(options) - 1, int(self.unit(label) * len(options)))]

    def bell(self, label, lo, hi):
        total = self.unit(label + ".a") + self.unit(label + ".b") + self.unit(label + ".c")
        return lo + (total / 3.0) * (hi - lo)

    def signed(self, label):
        return self.unit(label) * 2.0 - 1.0


class SplitMix64:
    """Mirror of the per-element jitter generator."""

    def __init__(self, seed, label):
        self.state = int.from_bytes(digest(DOMAIN_TRAIT, seed, label.encode())[:8], "big")

    def next(self):
        self.state = (self.state + GOLDEN) & MASK64
        return mix64(self.state)

    def unit(self):
        return (self.next() >> 11) * (2.0 ** -53)

    def value(self, lo, hi):
        return lo + self.unit() * (hi - lo)


def clamp(value, lo, hi):
    return max(lo, min(hi, value))


def rounded(value):
    """Swift's `.rounded()`: to nearest, and halves away from zero.

    **Use this and never the builtin `round` wherever the Swift says
    `.rounded()`.** Python's `round` is half-to-even — banker's rounding — and
    Swift's default rule is half-away-from-zero, so the two disagree on exactly
    the values that land on a half and agree everywhere else. That is a fault
    that hides: it is invisible in almost every plant and wrong in the rest.

    It was wrong in `nodeCount` for as long as this file has existed, and that
    is not a rare corner. `integer("stem.nodeCount", 2...9)` draws a whole
    number, so the product with `nodeScale` is a small rational and lands
    exactly on a half far more often than a continuous trait ever would: fern
    at 9.5, lotus at 1.5, 2.5, 3.5 and 4.5, vine at 8.5, succulent at 10.5.

    Only half of those actually disagree, and which half is worth knowing.
    Half-to-even goes to the *even* neighbour, which is the same answer as
    half-away-from-zero whenever the integer part is odd — 1.5, 3.5 and 9.5 all
    give the same node count either way. The disagreement is exactly the halves
    with an even integer part: 2.5, 4.5, 8.5, 10.5. Over the four thousand
    entropies `nodecount-0` … `nodecount-3999` that is 146 seeds, about one in
    twenty-seven, split lotus 71, vine 40, succulent 35 and no fern at all.
    Entropy `nodecount-30` is the worked example: a lotus drawing 5 against a
    `nodeScale` of 0.5, where SeedCore grows three nodes and this grew two.

    Nothing said so for months, because the twelve sampled vectors happened to
    contain no such seed — a guard can only be green about what it looks at.
    `vectors.json` now carries `nodecount-30` deliberately, for that reason and
    no other.

    **Written out, because both of the short ways are wrong**, and each of them
    was written here first and caught by an exhaustive check against `Decimal`
    before it got any further.

    `math.floor(value + 0.5)` is the usual trick and it rounds up a number that
    is below a half: 0.49999999999999994 + 0.5 is exactly 1.0 in double
    arithmetic, because the true sum is not representable and ties to even.

    Taking `math.floor` and comparing `value - lower` to a half fails on the
    same number with its sign flipped. -0.49999999999999994 floors to -1, and
    the true remainder, 0.50000000000000005…, is precisely halfway between 0.5
    and the next double up — so it ties to even, becomes exactly 0.5, and the
    tie rule then pushes it away from zero to -1 when the answer is 0.

    `math.trunc` has neither problem, and provably rather than by luck. For any
    finite double, `value - trunc(value)` is exact: below one the truncation is
    zero and the subtraction does nothing, and at one or above the two operands
    are within a factor of two of each other, which is Sterbenz's condition for
    an exact difference. So the fraction compared below is the real fraction.

    `Decimal(value).quantize(Decimal(1), rounding=ROUND_HALF_UP)` was also
    tried. It is exactly right and it reads better, and it was still rejected:
    timed against this, it is about ten times slower, on a call that runs once
    per row of every swept tube in the sheet.

    The other four places the Swift says `.rounded()` are here too, and all
    four were checked rather than assumed. `branchCount` multiplies 5 or 7 by a
    continuous `value(0.72...1.34)`, and over the same four thousand seeds it
    never lands on a half — but a trait that is one draw away from doing so is
    not a trait to leave on the wrong rule. `node_indices` takes `0.16 + 0.74 *
    index / (nodeCount - 1)` times 28, which over every `nodeCount` from 1 to 40
    lands on a half exactly once, at `nodeCount` 29 — above the 20 that
    `GenomeTests` declares the ceiling, so unreachable. `build_branches` takes
    `t * 28` over a thousand-step sweep of `branchSpread` and never lands on
    one. `add_tube` cannot: its `v` is `r / (rows - 1)` and the product is `r`.
    """
    truncated = math.trunc(value)
    if abs(value - truncated) < 0.5:
        return truncated
    # A half or more, so step away from zero: 2.5 to 3, and -2.5 to -3.
    return truncated + 1 if value > 0 else truncated - 1


def wrapped_unit(value):
    value = math.fmod(value, 1.0)
    return value + 1.0 if value < 0 else value


# ---------------------------------------------------------------- archetypes

ARCHETYPES = ["spire", "umbel", "fern", "orchid", "lotus", "thistle",
              "vine", "bell", "star", "poppy", "succulent", "plume"]

DEFAULT_PROFILE = dict(
    heightScale=1.0, stemThickness=1.0, nodeScale=1.0, leafLengthScale=1.0,
    leafWidthScale=1.0, leafDroop=1.0, petals=(5, 8), petalLengthScale=1.0,
    petalWidthScale=1.0, petalCurlBias=0.0, headPitchBias=0.0, centreScale=1.0,
    bloomsAtNodes=False, bloomPresence=1.0, swayScale=1.0,
    inflorescence="raceme", bloomScale=1.0, branchSpread=0.0, branchCount=5,
    # What holds a flower from beneath, how its sepals are carried, the outline
    # a petal is cut to and how crumpled it is. The family's rather than the
    # plant's — see `Calyx`, `Sepals` and `PetalOutline` in Archetype.swift.
    calyx="cup", sepals="appressed", petalOutline="rounded", petalCrumple=0.0,
    # The habit: how wide a plant stands for its height. All of it exists
    # because every plant was a stick — see the habit section of
    # `ArchetypeProfile`. Ranges are `(lo, hi)` and inclusive, as the Swift's
    # `ClosedRange`s are.
    rosette=False, crownLeaves=(0, 0), crownLengthScale=1.6, crownPitch=(0.9, 1.3),
    crownTaper=0.5, crownRise=0.55, pads=False, fleshiness=0.0, pinnae=(0, 0),
    leafReach=0.55, nodeZone=(0.16, 0.90),
)

PROFILE_OVERRIDES = {
    "spire": dict(petals=(4, 6), heightScale=1.35, nodeScale=1.6, petalLengthScale=0.55,
                  bloomsAtNodes=True, leafLengthScale=0.8,
                  crownLeaves=(0, 3), crownPitch=(0.6, 1.0)),
    "umbel": dict(petals=(5, 8), inflorescence="head", branchSpread=0.0, branchCount=5, bloomScale=0.8,
                  heightScale=0.9, petalLengthScale=0.45, centreScale=0.6, leafDroop=1.2,
                  crownLeaves=(2, 5), crownLengthScale=1.7, crownPitch=(0.7, 1.2), leafReach=0.6,
                  calyx="lid", sepals="none"),
    "fern": dict(petals=(3, 5), nodeScale=1.9, leafLengthScale=1.5, leafWidthScale=0.7,
                 leafDroop=1.3, bloomPresence=0.05, swayScale=1.3,
                 rosette=True, crownLeaves=(2, 4), crownLengthScale=2.2, crownPitch=(0.15, 0.45),
                 heightScale=0.32, crownTaper=0.2, pinnae=(9, 15), sepals="none"),
    "orchid": dict(petals=(3, 6), inflorescence="solitary", bloomScale=1.7, heightScale=0.6,
                   stemThickness=0.8, nodeScale=0.6, petalLengthScale=1.0, petalWidthScale=1.3,
                   petalCurlBias=0.25, headPitchBias=0.5, leafLengthScale=1.2,
                   rosette=True, crownLeaves=(1, 3), crownLengthScale=1.7, crownPitch=(0.95, 1.35),
                   leafWidthScale=1.5, calyx="stalk", sepals="none"),
    "lotus": dict(petals=(8, 14), inflorescence="solitary", bloomScale=1.7, heightScale=0.31,
                  stemThickness=1.4, petalLengthScale=0.6, petalWidthScale=1.5, petalCurlBias=-0.3,
                  centreScale=1.7, nodeScale=0.5,
                  rosette=True, pads=True, crownLeaves=(2, 4), crownLengthScale=1.9,
                  leafLengthScale=1.25, sepals="none"),
    "thistle": dict(petals=(13, 21), inflorescence="solitary", bloomScale=2.4, heightScale=0.9,
                    nodeScale=0.55, stemThickness=1.2, petalLengthScale=0.4, petalWidthScale=0.3,
                    petalCurlBias=-0.3, centreScale=1.3,
                    crownLeaves=(3, 7), crownPitch=(1.1, 1.4), leafReach=0.4,
                    calyx="urn", sepals="none", petalOutline="pointed"),
    "vine": dict(petals=(4, 6), heightScale=1.45, stemThickness=0.6, nodeScale=1.7, leafLengthScale=0.65,
                 leafWidthScale=1.1, swayScale=1.8, bloomsAtNodes=True, petalLengthScale=0.5,
                 leafReach=0.3),
    "bell": dict(petals=(5, 10), petalCurlBias=-0.75, petalLengthScale=1.1, headPitchBias=1.0,
                 bloomsAtNodes=True,
                 crownLeaves=(3, 7), crownPitch=(0.95, 1.35), leafLengthScale=1.3,
                 crownLengthScale=2.3, leafReach=0.8, sepals="spreading"),
    "star": dict(petals=(5, 8), petalCurlBias=0.35, petalWidthScale=0.6, centreScale=0.7,
                 crownLeaves=(4, 9), nodeZone=(0.08, 0.85), leafReach=0.8, leafLengthScale=1.25,
                 heightScale=0.9, crownLengthScale=2.3, crownPitch=(0.95, 1.35),
                 calyx="shallowCup", sepals="reflexed", petalOutline="pointed"),
    "poppy": dict(petals=(4, 6), inflorescence="solitary", bloomScale=1.7, heightScale=0.75,
                  nodeScale=0.35, leafLengthScale=1.2, petalLengthScale=1.0, petalWidthScale=1.6,
                  petalCurlBias=-0.35, headPitchBias=0.35, swayScale=1.4,
                  crownLeaves=(3, 6), crownLengthScale=2.0, crownPitch=(0.7, 1.1),
                  nodeZone=(0.05, 0.35), leafReach=0.7, calyx="swelling", sepals="none",
                  pinnae=(5, 8), petalCrumple=1.0),
    "succulent": dict(petals=(8, 12), rosette=True, fleshiness=1.0, crownPitch=(0.95, 1.3),
                      crownLengthScale=1.0, heightScale=0.31, stemThickness=0.9, nodeScale=2.1,
                      leafLengthScale=1.4, leafWidthScale=0.85, leafDroop=0.3,
                      petalLengthScale=0.5, bloomPresence=0.6, crownRise=0.3),
    "plume": dict(petals=(5, 10), inflorescence="head", branchSpread=1.0, branchCount=7, bloomScale=0.8,
                  heightScale=0.75, nodeScale=1.8, petalLengthScale=0.35,
                  petalWidthScale=0.35, leafLengthScale=0.6, leafWidthScale=0.4,
                  crownLeaves=(0, 3)),
}


def profile_for(archetype):
    profile = dict(DEFAULT_PROFILE)
    profile.update(PROFILE_OVERRIDES.get(archetype, {}))
    return profile


# ------------------------------------------------------------- colour model

COLOUR_SCHEMES = ["monochrome", "analogous", "complementary", "split", "bicolour", "ombre"]

FOLIAGE_TONES = {
    "green":    ((0.25, 0.36), (0.42, 0.82), (0.34, 0.72)),
    "olive":    ((0.16, 0.24), (0.38, 0.66), (0.36, 0.66)),
    "burgundy": ((0.96, 1.00), (0.45, 0.75), (0.30, 0.55)),
    "plum":     ((0.76, 0.86), (0.30, 0.58), (0.32, 0.56)),
    "silver":   ((0.40, 0.52), (0.08, 0.22), (0.52, 0.80)),
    "bronze":   ((0.06, 0.11), (0.35, 0.60), (0.34, 0.58)),
}

FOLIAGE_WEIGHTED = (["green"] * 7 + ["olive"] * 3 + ["burgundy"] * 2
                    + ["plum", "silver", "bronze"])

VARIEGATION_WEIGHTED = ["none"] * 7 + ["margin"] * 2 + ["midrib", "speckled"]


def flower_hue(unit, allow_green):
    """Mirror of flowerHue: flowers mostly skip the green the leaves occupy."""
    if allow_green:
        return unit
    band_start, band_width = 0.26, 0.14
    scaled = unit * (1 - band_width)
    return scaled if scaled < band_start else scaled + band_width


def speckle(u, v, seed, frequency):
    cell_u = int(math.floor(u * frequency))
    cell_v = int(math.floor(v * frequency * 2))
    h = mix64(seed ^ ((cell_u * 0x9E3779B9) & MASK64))
    h = mix64(h ^ ((cell_v * 0x85EBCA6B) & MASK64))
    return (h >> 11) * (2.0 ** -53)


def derive_palette(source, seed):
    """Mirror of Genome.Palette.derive."""
    scheme = source.pick("palette.scheme", COLOUR_SCHEMES)
    base_hue = flower_hue(source.unit("palette.petalHue"),
                          source.chance("palette.greenFlower", 0.08))
    base_sat = source.value("palette.petalSaturation", 0.18, 0.95)
    base_bri = source.value("palette.petalBrightness", 0.55, 1.0)
    direction = 1 if source.chance("palette.hueDirection", 0.5) else -1

    tip_hue, tip_sat, tip_bri = base_hue, base_sat, base_bri
    if scheme == "monochrome":
        tip_sat = base_sat * source.value("palette.tipSaturation", 0.45, 1.1)
        tip_bri = base_bri * source.value("palette.tipBrightness", 1.0, 1.35)
    elif scheme == "analogous":
        tip_hue = base_hue + direction * source.value("palette.tipShift", 0.04, 0.11)
        tip_sat = base_sat * source.value("palette.tipSaturation", 0.7, 1.1)
        tip_bri = base_bri * source.value("palette.tipBrightness", 0.95, 1.25)
    elif scheme == "complementary":
        tip_hue = base_hue + 0.5
        tip_sat = base_sat * source.value("palette.tipSaturation", 0.35, 0.7)
        tip_bri = base_bri * source.value("palette.tipBrightness", 1.0, 1.3)
    elif scheme == "split":
        tip_hue = base_hue + 0.5 + direction * source.value("palette.tipShift", 0.06, 0.16)
        tip_sat = base_sat * source.value("palette.tipSaturation", 0.4, 0.8)
        tip_bri = base_bri * source.value("palette.tipBrightness", 1.0, 1.3)
    elif scheme == "bicolour":
        tip_hue = base_hue + direction * source.value("palette.tipShift", 0.22, 0.42)
        tip_sat = base_sat * source.value("palette.tipSaturation", 0.75, 1.15)
        tip_bri = base_bri * source.value("palette.tipBrightness", 0.9, 1.25)
    else:  # ombre
        tip_sat = base_sat * source.value("palette.tipSaturation", 0.08, 0.35)
        tip_bri = min(1.0, base_bri * source.value("palette.tipBrightness", 1.15, 1.5))

    petal_base = (wrapped_unit(base_hue), clamp(base_sat, 0, 1), clamp(base_bri * 0.82, 0, 1))
    petal_tip = (wrapped_unit(tip_hue), clamp(tip_sat, 0, 1), clamp(tip_bri, 0, 1))

    toward_complement = scheme in ("complementary", "split")
    throat_hue = (base_hue + 0.5 + source.signed("palette.throatShift") * 0.06
                  if toward_complement
                  else base_hue + source.signed("palette.throatShift") * 0.08)
    petal_throat = (wrapped_unit(throat_hue),
                    min(1, base_sat * source.value("palette.throatSaturation", 0.9, 1.5) + 0.1),
                    clamp(base_bri * source.value("palette.throatBrightness", 0.5, 0.95), 0, 1))

    petal_vein = (wrapped_unit(base_hue + source.signed("palette.veinShift") * 0.05),
                  min(1, base_sat * 1.25 + 0.08),
                  clamp(base_bri * source.value("palette.veinBrightness", 0.35, 0.7), 0, 1))
    veining = source.bell("palette.veining", 0.15, 0.75) if source.chance("palette.hasVeins", 0.45) else 0.0

    picotee = None
    if source.chance("palette.hasPicotee", 0.18):
        picotee = (wrapped_unit(base_hue + 0.5 + source.signed("palette.picoteeShift") * 0.1),
                   source.value("palette.picoteeSaturation", 0.5, 1.0),
                   source.value("palette.picoteeBrightness", 0.35, 0.9))

    tone = source.pick("palette.foliageTone", FOLIAGE_WEIGHTED)
    hue_range, sat_range, bri_range = FOLIAGE_TONES[tone]
    leaf = (source.value("palette.leafHue", *hue_range),
            source.value("palette.leafSaturation", *sat_range),
            source.value("palette.leafBrightness", *bri_range))

    variegation = source.pick("palette.variegation", VARIEGATION_WEIGHTED)
    leaf_accent = (wrapped_unit(leaf[0] + source.signed("palette.accentShift") * 0.12),
                   leaf[1] * source.value("palette.accentSaturation", 0.1, 0.6),
                   min(1, leaf[2] * source.value("palette.accentBrightness", 1.3, 2.1)))

    stem = (wrapped_unit(leaf[0] + source.signed("palette.stemShift") * 0.06),
            clamp(leaf[1] * source.value("palette.stemSaturation", 0.6, 1.1), 0, 1),
            clamp(leaf[2] * source.value("palette.stemBrightness", 0.62, 1.0), 0, 1))

    centre = (source.unit("palette.centreHue"),
              source.value("palette.centreSaturation", 0.3, 1.0),
              source.value("palette.centreBrightness", 0.6, 1.0))

    return dict(scheme=scheme, petalBase=petal_base, petalTip=petal_tip,
                petalThroat=petal_throat, petalVein=petal_vein, picotee=picotee,
                veining=veining, foliageTone=tone, leaf=leaf, variegation=variegation,
                leafAccent=leaf_accent, stem=stem, centre=centre,
                glow=source.bell("palette.glow", 0, 1),
                sheen=source.value("palette.sheen", 0.05, 0.65),
                speckleSeed=gene_u64(seed, "palette.speckleSeed"))


# -------------------------------------------------------------------- genome

class Genome:
    """Mirror of SeedCore/Genome/Genome.swift."""

    def __init__(self, seed, parents=None):
        self.seed = seed
        self.parents = tuple(sorted(parents)) if parents else None
        source = GeneSource(seed, parents)
        self.source = source

        self.archetype = source.pick("form.archetype", ARCHETYPES)
        profile = profile_for(self.archetype)
        self.profile = profile

        self.merosity = "many" if source.chance("bloom.merosity", 0.5) else "few"
        self.vigour = source.bell("form.vigour", 0.74, 1.30)

        self.inflorescence = profile["inflorescence"]
        self.bloomScale = profile["bloomScale"]
        self.branchCount = max(3, min(7, rounded(
            profile["branchCount"] * source.value("stem.branch.count", 0.72, 1.34))))
        self.branchSpread = clamp(
            profile["branchSpread"] + source.signed("stem.branch.spread") * 0.14, 0, 1)
        self.branchAngle = source.value("stem.branch.angle", 1.0, 1.35)

        # Whether the plant flowers, and how long its leaves are, are read here,
        # ahead of the bloom and the foliage they belong to, because on a
        # rosette they decide how tall the stem is. A key gives the same value
        # however often it is read — draws are by label, not by position — so
        # the bloom and foliage below agree with these.
        flowers = source.unit("bloom.present") < profile["bloomPresence"]
        leaf_length = source.value("foliage.length", 0.055, 0.28) * profile["leafLengthScale"] * self.vigour
        # A rosette's leaves are its whole size, so it takes the leaf draw at a
        # little over half strength: the fivefold range that makes one stem
        # leafy and another bare would make one lotus a metre across and the
        # next a saucer. 0.1675 is the middle of `foliage.length`'s draw.
        typical_length = 0.1675 * profile["leafLengthScale"] * self.vigour
        rosette_length = profile["crownLengthScale"] * (leaf_length * 0.6 + typical_length * 0.4)
        drawn_height = source.value("stem.height", 0.44, 1.42) * profile["heightScale"] * self.vigour
        if profile["pads"]:
            # A water lily holds its flower just clear of its pads, so the stem
            # answers to the pads: a quarter of the largest pad's width, and a
            # sliver of the stem draw so no two stand the same.
            self.height = 0.06 + rosette_length * 0.25 + drawn_height * 0.1
        elif profile["rosette"] and not flowers:
            # A rosette that does not flower sends up no stalk: a stub the inner
            # leaves stand round and hide, still a height so that a fern's
            # crozier has something to uncurl from.
            self.height = 0.08 + drawn_height * 0.25
        else:
            self.height = drawn_height
        self.baseRadius = source.value("stem.baseRadius", 0.006, 0.022) * profile["stemThickness"]
        self.taper = source.value("stem.taper", 0.16, 0.86)
        self.lean = source.signed("stem.lean") * 0.75
        self.sway = source.bell("stem.sway", 0, 1.25) * profile["swayScale"]
        self.twist = source.signed("stem.twist") * 0.95
        self.nodeCount = max(1, rounded(source.integer("stem.nodeCount", 2, 9) * profile["nodeScale"]))
        self.sides = source.integer("stem.sides", 6, 9)

        self.leavesPerNode = source.integer("foliage.leavesPerNode", 1, 3)
        self.leafLength = leaf_length
        self.leafWidthRatio = source.value("foliage.widthRatio", 0.13, 0.88) * profile["leafWidthScale"]
        self.leafDroop = source.bell("foliage.droop", 0, 1.15) * profile["leafDroop"]
        self.leafFold = source.value("foliage.fold", 0.02, 0.62)
        self.leafPitch = source.value("foliage.pitch", 0.24, 1.45)
        self.divergence = 2.399963 + source.signed("foliage.divergence") * 0.22
        self.serration = source.bell("foliage.serration", 0, 1.3)
        self.teeth = source.integer("foliage.teeth", 3, 17)
        self.veinCount = source.integer("foliage.veinCount", 2, 9)
        self.veinDepth = source.bell("foliage.veinDepth", 0.2, 1.0) if source.chance("foliage.hasVeins", 0.72) else 0.0
        self.leafTipSharpness = source.value("foliage.tipSharpness", 0.5, 2.4)

        # The habit — `Genome.Habit`. Leaf size answers partly to the stem,
        # which is what stops a tall plant being a twig: measured against 0.9m
        # and held between 0.4 and 1.5. Kept off `leafLength` itself, which the
        # epithets read: a long-leaved plant is long-leaved for its genus.
        reach = profile["leafReach"]
        self.stemLeafScale = (1 - reach) + reach * min(1.5, max(0.4, self.height / 0.9))
        self.rosette = profile["rosette"]
        self.crownCount = ((self.nodeCount * self.leavesPerNode if self.rosette else 0)
                           + source.integer("habit.crownLeaves", *profile["crownLeaves"]))
        # Held to sixty centimetres off a rosette: past that a bell is wearing
        # rhubarb, and it was the one thing making a two-metre spread.
        self.crownLength = (rosette_length if self.rosette
                            else min(0.6, profile["crownLengthScale"] * self.leafLength * self.stemLeafScale))
        self.crownPitch = source.value("habit.crownPitch", *profile["crownPitch"])
        self.crownTaper = profile["crownTaper"]
        self.crownRise = profile["crownRise"]
        self.pads = profile["pads"]
        self.fleshiness = profile["fleshiness"]
        self.pinnae = source.integer("habit.pinnae", *profile["pinnae"])
        self.nodeZone = profile["nodeZone"]

        # The genus has a petal count; the plant does not draw one. See
        # SeedCore's Genome.swift and docs/TAXONOMY.md §1.
        plan = profile["petals"][0 if self.merosity == "few" else 1]
        variance = source.unit("bloom.petalVariant")
        self.petalCount = max(3, plan + (-1 if variance < 0.1 else 1 if variance > 0.9 else 0))
        bloom_scale = 0.75 + 0.45 * min(1.6, self.height)
        self.petalLength = source.value("bloom.length", 0.09, 0.24) * profile["petalLengthScale"] * bloom_scale
        self.layers = source.integer("bloom.layers", 1, 3)
        self.petalWidthRatio = source.value("bloom.widthRatio", 0.25, 0.85) * profile["petalWidthScale"]
        self.curl = clamp(source.signed("bloom.curl") * 0.6 + profile["petalCurlBias"], -1, 1)
        self.bloomTwist = source.signed("bloom.twist") * 0.5
        self.petalTipSharpness = source.value("bloom.tipSharpness", 0.6, 2.4)
        self.headPitch = clamp(source.bell("bloom.headPitch", 0, 0.9) + profile["headPitchBias"], 0, 1.9)
        self.centreRadius = source.value("bloom.centreRadius", 0.1, 0.32) * profile["centreScale"]
        self.stamenCount = source.integer("bloom.stamenCount", 0, 9)
        self.notch = source.value("bloom.notch", 0.35, 1.0) if source.chance("bloom.hasNotch", 0.3) else 0.0
        self.sepalCount = source.integer("bloom.sepalCount", 3, 6) if source.chance("bloom.hasSepals", 0.7) else 0
        self.hasPistil = source.chance("bloom.hasPistil", 0.75)
        self.bloomsAtNodes = profile["bloomsAtNodes"]
        self.bloomPresent = flowers
        self.calyx = profile["calyx"]
        self.sepals = profile["sepals"]
        self.petalOutline = profile["petalOutline"]
        self.crumple = profile["petalCrumple"]

        self.palette = derive_palette(source, seed)
        self.glow = self.palette["glow"]
        self.sheen = self.palette["sheen"]

        self.germinationHours = source.value("tempo.germinationHours", 3, 20)
        self.seedlingDays = source.value("tempo.seedlingDays", 0.6, 2.4)
        self.vegetativeDays = source.value("tempo.vegetativeDays", 2.0, 7.0)
        self.buddingDays = source.value("tempo.buddingDays", 1.0, 4.0)
        self.bloomDays = source.value("tempo.bloomDays", 3.0, 12.0)
        self.opensByDay = source.chance("tempo.opensByDay", 0.7)

        # **There is deliberately no name here.** SeedCore gives every plant a
        # binomial; this port gives none, and that is a decision rather than an
        # omission waiting to be filled in.
        #
        # This file exists to draw geometry so a plant can be looked at. A name
        # is the one thing about a plant that no render shows, so a naming
        # implementation here can never be checked by the means this tool is
        # checked by — and it was not. It sat three months behind: SeedCore
        # stopped drawing the genus on 3 September 2026 and started reading it
        # off the flower (`PlantName.roots` maps a family and a merosity to one
        # of the twenty-four heads), and replaced the glued two-syllable
        # epithet with `Epithet`, which says only what has been checked to be
        # true of the specimen. The port went on gluing `name.epithetHead` to
        # `name.epithetTail` and printing *pallicola* — "pale-dwelling", which
        # is not a thing a plant can be — under captions in `preview.py`.
        #
        # Porting it rather than deleting it was considered and rejected. It is
        # not a line: `Epithet` reads `palette.marbling`, one of twelve palette
        # draws this file does not have, so it is a real piece of work whose
        # only payoff is a string nothing here displays. A wrong name that
        # nobody reads costs nothing until somebody wires it up believing it
        # agrees with the app; the way to make sure that never happens is for
        # the port to have no opinion about names at all.
        #
        # **Removing the draws could not move anything else, and it did not.**
        # `GeneSource` draws by label — `unit(label)` hashes the seed with the
        # name of the trait — so there is no stream whose position a missing
        # draw could shift. That is the same property `Genome.swift` relies on
        # when it adds new keys. It was proved rather than argued: a SHA-256
        # over every position, normal, UV and index of twenty-four plants at
        # sixteen ages each is byte-identical before and after.
        #
        # `SeedCore` remains authoritative for the name, `vectors.json` still
        # records it as a label so a reader can tell which specimen a vector
        # describes, and `check_port.py` deliberately does not compare it.

    @property
    def leafCount(self):
        return self.nodeCount * self.leavesPerNode

    @property
    def daysToBloom(self):
        return self.germinationHours / 24.0 + self.seedlingDays + self.vegetativeDays + self.buddingDays


# -------------------------------------------------------------------- growth

HOUR = 3600.0
DAY = 86400.0
STAGES = ["germinating", "seedling", "growing", "budding", "blooming", "mature"]


def ease_out(t):
    return 1 - (1 - clamp(t, 0, 1)) ** 2.4


def ease_in_out(t):
    x = clamp(t, 0, 1)
    return x * x * (3 - 2 * x)


def growth_state(genome, age_seconds, hour_of_day=13.0):
    germination = genome.germinationHours * HOUR
    seedling = germination + genome.seedlingDays * DAY
    growing = seedling + genome.vegetativeDays * DAY
    budding = growing + genome.buddingDays * DAY
    blooming = budding + genome.bloomDays * DAY
    marks = [("germinating", germination), ("seedling", seedling), ("growing", growing),
             ("budding", budding), ("blooming", blooming)]

    age = max(0.0, age_seconds)
    stage, stage_start, stage_end, previous = "mature", blooming, None, 0.0
    for name, end in marks:
        if age < end:
            stage, stage_start, stage_end = name, previous, end
            break
        previous = end

    stage_progress = clamp((age - stage_start) / (stage_end - stage_start), 0, 1) if stage_end else 1.0
    overall = clamp(age / budding, 0, 1)
    height = ease_out(clamp(age / growing, 0, 1))
    leaf_span = max(1.0, growing - germination)
    leaf_unfurl = ease_out(clamp((age - germination) / leaf_span, 0, 1))
    bud_swell = clamp((age - growing) / max(1.0, budding - growing), 0, 1)
    bloom_span = max(1.0, genome.bloomDays * DAY * 0.35)
    bloom_open = ease_in_out(clamp((age - budding) / bloom_span, 0, 1)) if genome.bloomPresent else 0.0

    peak = 13.0 if genome.opensByDay else 1.0
    delta = abs(hour_of_day - peak)
    if delta > 12:
        delta = 24 - delta
    bloom_open *= 0.34 + 0.66 * ease_in_out(1.0 - delta / 12.0)

    # The flowering cycle after maturity. See SeedCore's GrowthModel.
    cycle = max(DAY, genome.bloomDays * DAY * 2.4)
    since_mature = max(0.0, age - blooming)
    flush = (since_mature / cycle) % 1.0
    flush_depth = ease_in_out(clamp(since_mature / cycle, 0, 1)) if genome.bloomPresent else 0.0

    return dict(stage=stage, stageProgress=stage_progress, overall=overall,
                heightScale=max(0.055, height), leafUnfurl=leaf_unfurl,
                budSwell=bud_swell, bloomOpen=bloom_open, age=age,
                flush=flush, flushDepth=flush_depth)


# ------------------------------------------------------------------ geometry

def normalize(v):
    length = np.linalg.norm(v)
    return v / length if length > 1e-12 else np.array([0.0, 1.0, 0.0])


def rotate_axis(v, axis, angle):
    if abs(angle) < 1e-7:
        return v
    axis = normalize(np.asarray(axis, dtype=float))
    return (v * math.cos(angle)
            + np.cross(axis, v) * math.sin(angle)
            + axis * np.dot(axis, v) * (1 - math.cos(angle)))


def rotate_from_to(v, a, b):
    axis = np.cross(a, b)
    sine = np.linalg.norm(axis)
    if sine < 1e-7:
        return v
    return rotate_axis(v, axis / sine, math.atan2(sine, float(np.dot(a, b))))


def arbitrary_perpendicular(v):
    reference = np.array([1.0, 0, 0]) if abs(v[1]) > 0.9 else np.array([0.0, 1.0, 0])
    return normalize(np.cross(v, reference))


class MeshBuilder:
    """Mirror of SeedCore/Morphology/MeshBuilder.swift."""

    def __init__(self):
        self.parts = {}

    def add_surface(self, role, rows, columns, point, flip=False):
        if rows < 2 or columns < 2:
            return
        grid = [[point(c / (columns - 1), r / (rows - 1)) for c in range(columns)] for r in range(rows)]

        positions, normals = [], []
        for r in range(rows):
            for c in range(columns):
                across = grid[r][min(columns - 1, c + 1)] - grid[r][max(0, c - 1)]
                along = grid[min(rows - 1, r + 1)][c] - grid[max(0, r - 1)][c]
                normal = np.cross(along, across)
                if float(np.dot(normal, normal)) < 1e-12:
                    fr = min(rows - 1, 1) if r == 0 else max(0, r - 1)
                    a = grid[fr][min(columns - 1, c + 1)] - grid[fr][max(0, c - 1)]
                    b = grid[min(rows - 1, fr + 1)][c] - grid[max(0, fr - 1)][c]
                    normal = np.cross(b, a)
                    if float(np.dot(normal, normal)) < 1e-12:
                        normal = np.array([0.0, 1.0, 0.0])
                positions.append(grid[r][c])
                normals.append(normalize(normal))

        indices = []
        for r in range(rows - 1):
            for c in range(columns - 1):
                tl = r * columns + c
                tr = tl + 1
                bl = (r + 1) * columns + c
                br = bl + 1
                if flip:
                    indices += [(tl, tr, bl), (tr, br, bl)]
                else:
                    indices += [(tl, bl, tr), (tr, bl, br)]

        part = self.parts.setdefault(role, dict(positions=[], normals=[], uvs=[], indices=[]))
        offset = len(part["positions"])
        part["positions"] += positions
        part["normals"] += normals
        part["uvs"] += [(c / (columns - 1), r / (rows - 1)) for r in range(rows) for c in range(columns)]
        part["indices"] += [(a + offset, b + offset, c + offset) for a, b, c in indices]

    def add_tube(self, role, path, sides):
        if len(path) < 2 or sides < 3:
            return
        columns = sides + 1

        def point(u, v):
            index = min(len(path) - 1, rounded(v * (len(path) - 1)))
            sample = path[index]
            angle = u * 2 * math.pi
            offset = sample["normal"] * math.cos(angle) + sample["binormal"] * math.sin(angle)
            return sample["position"] + offset * sample["radius"]

        self.add_surface(role, len(path), columns, point)

    def add_dome(self, role, centre, axis, side, radius, flatten=0.65, rows=10, columns=16):
        if radius <= 0:
            return
        up = normalize(axis)
        right = normalize(side - up * float(np.dot(side, up)))
        forward = np.cross(up, right)

        def point(u, v):
            polar = v * (math.pi / 2)
            azimuth = u * 2 * math.pi
            ring = math.sin(polar) * radius
            rise = math.cos(polar) * radius * flatten
            return (centre + right * (ring * math.cos(azimuth))
                    + forward * (ring * math.sin(azimuth)) + up * rise)

        self.add_surface(role, rows, columns + 1, point)


def transport_frames(positions, radii, twist):
    if len(positions) < 2:
        return []
    tangents = []
    for index in range(len(positions)):
        previous = positions[max(0, index - 1)]
        following = positions[min(len(positions) - 1, index + 1)]
        delta = following - previous
        tangents.append(np.array([0.0, 1.0, 0.0]) if float(np.dot(delta, delta)) < 1e-12 else normalize(delta))

    normal = arbitrary_perpendicular(tangents[0])
    samples = []
    for index in range(len(positions)):
        if index > 0:
            normal = rotate_from_to(normal, tangents[index - 1], tangents[index])
            normal = normal - tangents[index] * float(np.dot(normal, tangents[index]))
            normal = (arbitrary_perpendicular(tangents[index])
                      if float(np.dot(normal, normal)) < 1e-12 else normalize(normal))
        t = index / (len(positions) - 1)
        twisted = rotate_axis(normal, tangents[index], twist * t)
        samples.append(dict(position=positions[index], tangent=tangents[index], normal=twisted,
                            binormal=normalize(np.cross(tangents[index], twisted)),
                            radius=radii[min(len(radii) - 1, index)], t=t))
    return samples


STEM_SEGMENTS = 28


def node_indices(node_count, segments=STEM_SEGMENTS, zone=(0.16, 0.90)):
    """Which stem samples carry the leaf nodes, as indices into the sweep.

    `zone` is the family's `nodeZone` — where on the stem its nodes sit, as
    fractions of its length. A daisy is leafy nearly from the ground and a
    poppy's few nodes are low with the stem bare above them; `0.16...0.90`,
    the default, is what every plant had before the zone was a profile's.

    The Swift works this in `Float` and this in doubles, and that was checked
    rather than assumed for the two new zones as for the old one: over every
    `nodeCount` from 1 to 40, the only index where the two round differently is
    poppy's zone at 29 nodes, and a poppy grows three at most.

    Split out of `build_skeleton` so a node's place on the stem can be had
    without sweeping one. The sweep is the only part of this file that wants
    numpy, and `check_port.py` runs where there is none — but it still needs
    every node's `t`, because that is what sets a flower's lag, its ceiling and
    its place in the flush wave. The skeleton builder reads its nodes off this
    list, so the two cannot come apart.

    A sample's `t` is its index over `segments`, which is what makes this
    enough on its own: `transport_frames` numbers `positions` from 0 to 1 and
    the stem always has `segments + 1` of them.
    """
    low, span = zone[0], zone[1] - zone[0]
    indices = []
    for index in range(node_count):
        fraction = low + span * 0.53 if node_count == 1 else low + span * index / (node_count - 1)
        indices.append(min(segments, rounded(fraction * segments)))
    return indices


def stalk_count(genome, height_scale):
    """How many stalks a head gives off at this height.

    The guards at the top of `build_branches` and nothing below them — a stalk
    can still be dropped for want of reach, but only while `vigour` is under
    about 0.01, which is a stem a quarter grown. **No flower is ever drawn
    there**: `budSwell` does not leave zero until the plant has stopped
    growing, and `heightScale` is 1 by then. So this is exact everywhere a
    bloom is placed, which is the one thing `check_port.py` asks of it.
    """
    if genome.inflorescence != "head" or genome.branchCount <= 0:
        return 0
    return genome.branchCount if smoothstep((height_scale - 0.25) / (0.7 - 0.25)) > 0.001 else 0


def apex_point(t, span):
    """How much of its full thickness a stem still has at `t`.

    Mirror of `SkeletonBuilder.apexPoint`: the last `span` of a stem or stalk
    runs out to nothing on an ogive, so the tube closes on a point rather than
    showing its own lit inside wall through an open end. Clamped before the
    root, as the Swift is, because `1 - (1 - span)` does not round back to
    `span` and the tip vertex would otherwise be a NaN.
    """
    start = 1 - span
    if t <= start:
        return 1.0
    s = (t - start) / span
    return math.sqrt(max(0.0, 1 - s * s))


def crozier_turn(height_scale):
    """The total turn a young shoot's coiled tip carries, in radians.

    Mirror of `SkeletonBuilder.crozierTurn`. A shoot comes up with its growing
    point curled over and opens as it grows; gone by the time the plant is half
    its height, so a grown plant is exactly as it was before this existed.
    """
    return 1.6 * math.pi * (1 - smoothstep((height_scale - 0.06) / (0.5 - 0.06)))


def _coil_step(t, turn, segments):
    """The coil's share of one integration step: the derivative of `s^1.7`,
    so the shoot leaves the ground almost straight and keeps the curl at its
    growing end. The bottom third stays upright."""
    start = 0.35
    if turn <= 0 or t <= start:
        return 0.0
    span = 1 - start
    s = (t - start) / span
    return turn * 1.7 * s ** 0.7 / (segments * span)


def build_skeleton(genome, height_scale, segments=STEM_SEGMENTS):
    length = max(0.01, genome.height * height_scale)
    step = length / segments
    lean_per_step = genome.lean * 0.9 / segments
    sway_amplitude = genome.sway * 0.8

    base_radius = genome.baseRadius * (0.4 + 0.6 * height_scale)
    coil_turn = crozier_turn(height_scale)
    # A growing point is a few stem-diameters long, sized against the stem's
    # thickness rather than its length, or on a spire it is a whisker.
    point_span = min(0.16, max(0.045, base_radius * 5 / length))
    positions = [np.zeros(3)]
    radii = [base_radius]
    direction = np.array([0.0, 1.0, 0.0])
    position = np.zeros(3)

    for index in range(1, segments + 1):
        t = index / segments
        # The crozier bends about the lean's own axis, so a leaning stem
        # relaxes into its lean: one continuous bend from base to tip.
        direction = rotate_axis(direction, np.array([0.0, 0.0, 1.0]),
                                lean_per_step * (0.6 + 0.8 * t) + _coil_step(t, coil_turn, segments))
        direction = rotate_axis(direction, np.array([1.0, 0.0, 0.0]),
                                sway_amplitude * math.cos(t * math.pi * 2.2) / segments)
        direction = normalize(direction)
        position = position + direction * step
        positions.append(position)
        radii.append(base_radius * (1 - (1 - genome.taper) * t) * apex_point(t, point_span))

    samples = transport_frames(positions, radii, genome.twist)
    nodes = [samples[index] for index in node_indices(genome.nodeCount, segments, genome.nodeZone)]
    return dict(stem=samples, nodes=nodes, apex=samples[-1],
                branches=build_branches(genome, samples, height_scale, length),
                pedicels=build_pedicels(genome, nodes, length))


def build_pedicels(genome, nodes, stem_length):
    """Mirror of SkeletonBuilder.pedicels in PlantSkeleton.swift.

    The short stalk a flower at a node stands on. Until 27 September 2026
    neither this file nor SeedCore had one, so a flower at a node was built
    coaxial with the stem at that node and the stem ran up through the middle
    of it and out the top. Keyed by node offset, because a flower too young to
    have swelled is not drawn and its stalk must not be either.
    """
    if not genome.bloomsAtNodes:
        return {}
    pedicels = {}
    for offset, node in enumerate(nodes):
        if node["t"] <= 0.35:
            continue
        jitter = SplitMix64(genome.seed, f"pedicel.{offset}")
        azimuth = genome.divergence * offset + math.pi
        radial = normalize(node["normal"] * math.cos(azimuth)
                           + node["binormal"] * math.sin(azimuth))
        angle = 0.95 + jitter.value(-0.16, 0.16)
        reach = stem_length * 0.082 + node["radius"] * 1.4
        # Nothing to aim at: a pedicel has no target height, so the target is
        # out of reach and the sweep runs its whole length.
        path = _sweep_branch(node, radial, angle, float("inf"), reach, 0.55, genome.taper)
        if len(path) < 3:
            continue
        pedicels[offset] = dict(origin=node, path=path)
    return pedicels


def build_branches(genome, samples, height_scale, stem_length):
    """Mirror of SkeletonBuilder.branches in PlantSkeleton.swift."""
    count = stalk_count(genome, height_scale)
    if count == 0 or len(samples) < 2:
        return []

    vigour = smoothstep((height_scale - 0.25) / (0.7 - 0.25))
    spread = genome.branchSpread
    apex = samples[-1]
    zone_start = 0.78 - 0.33 * spread
    zone_end = 0.95

    branches = []
    for index in range(count):
        fraction = 0.5 if count == 1 else index / (count - 1)
        t = zone_start + (zone_end - zone_start) * fraction
        origin = samples[min(len(samples) - 1, rounded(t * (len(samples) - 1)))]

        jitter = SplitMix64(genome.seed, f"branch.{index}")
        azimuth = genome.divergence * index
        radial = normalize(origin["normal"] * math.cos(azimuth)
                           + origin["binormal"] * math.sin(azimuth))
        angle = (genome.branchAngle
                 + jitter.value(-0.3, 0.3) * (0.2 + 0.8 * spread)) * vigour

        climb = max(0.0, apex["position"][1] - origin["position"][1])
        target_y = apex["position"][1] + spread * climb * jitter.value(-0.5, 0.5)
        # The ceiling comes in with spread: at 0.7 a tall plume's low stalks
        # made it two metres across, the widest plant in the garden by half a
        # metre once everything else had been broadened to meet it.
        ceiling = stem_length * (0.7 - 0.08 * spread)
        reach = min(ceiling, climb * 2.4 + stem_length * 0.2) * vigour
        if reach <= stem_length * 0.002:
            continue

        path = _sweep_branch(origin, radial, angle, target_y, reach,
                             0.85 * (1 - 0.55 * spread), genome.taper)
        if len(path) < 3:
            continue
        branches.append(dict(origin=origin, path=path))
    return branches


def _sweep_branch(origin, radial, angle, target_y, reach, levelling, taper):
    segments = 14
    step = reach / segments
    minimum = reach * 0.34
    up = np.array([0.0, 1.0, 0.0])
    start = normalize(origin["tangent"] * math.cos(angle) + radial * math.sin(angle))

    position = origin["position"] + radial * origin["radius"] * 0.6
    positions = [position]
    travelled = 0.0

    for index in range(1, segments + 1):
        s = index / segments
        turn = levelling * (s ** 1.45)
        direction = normalize(start * (1 - turn) + up * turn)
        previous = position
        position = position + direction * step
        travelled += step
        positions.append(position)
        if travelled < minimum or position[1] < target_y:
            continue
        # Stop at the crossing rather than at the sample after it. See the
        # note in PlantSkeleton.swift: landing on a step quantises the tip.
        rise = position[1] - previous[1]
        if rise > 1e-6:
            crossing = clamp((target_y - previous[1]) / rise, 0, 1)
            positions[-1] = previous + (position - previous) * crossing
            travelled -= step * (1 - crossing)
        break

    # A stalk is a stem and ends like one, through the same ogive.
    base = origin["radius"] * 0.45
    span = min(0.2, max(0.06, base * 5 / max(0.0001, travelled)))
    last = len(positions) - 1
    radii = [base * (1 - (1 - taper) * (i / last)) * apex_point(i / last, span)
             for i in range(len(positions))]
    return transport_frames(positions, radii, 0.0)


def blade_profile(s, sharpness, serration, teeth):
    base = math.sin(math.pi * (clamp(s, 0, 1) ** 0.7))
    shaped = max(0.0, base) ** max(0.3, sharpness)
    if serration <= 0 or teeth <= 0:
        return shaped
    phase = s * teeth
    sawtooth = phase - math.floor(phase)
    return shaped * (1 - serration * 0.22 * (sawtooth ** 1.5))


def build_mesh(genome, growth):
    """Mirror of SeedCore/Morphology/PlantBuilder.swift."""
    builder = MeshBuilder()
    skeleton = build_skeleton(genome, growth["heightScale"])
    builder.add_tube("stem", skeleton["stem"], genome.sides)

    # The domes that close the tubes. `add_tube` closes neither end, so a branch
    # join and the foot of the stem each need a lid; the apex closes itself,
    # because `apex_point` runs the radius out to nothing.
    #
    # **These were missing here for as long as this file has existed.** The port
    # had the tubes and not the lids, which is invisible in every mode that
    # renders the whole plant from a distance — and became visible the moment
    # `preview.py --feet` went and looked at a foot. Kept in step with
    # `PlantBuilder.addStem`, which is where the numbers come from.
    for branch in skeleton.get("branches", []):
        base = branch["path"][0]
        builder.add_tube("stem", branch["path"], max(4, genome.sides - 2))
        builder.add_dome("stem", base["position"], -base["tangent"], base["normal"],
                         base["radius"], flatten=0.5, rows=4,
                         columns=max(5, genome.sides - 2))

    foot = skeleton["stem"][0]
    builder.add_dome("stem", foot["position"], -foot["tangent"], foot["normal"],
                     foot["radius"], flatten=0.45, rows=5,
                     columns=max(6, genome.sides))

    husk = clamp((0.25 - growth["heightScale"]) / 0.23, 0, 1)
    if husk > 0.01:
        # Measured against the shoot as it is now, not against the stem the
        # plant will one day have, and capped so the husk can never be the
        # tallest thing on the plant. See the same note in PlantBuilder.swift.
        shoot_radius = skeleton["stem"][0]["radius"]
        shoot_length = genome.height * growth["heightScale"]
        radius = min(shoot_radius * 2.4, shoot_length * 0.45) * husk
        builder.add_dome("stem", np.array([0.0, shoot_radius * 0.4, 0.0]),
                         np.array([0.0, 1.0, 0.0]), np.array([1.0, 0.0, 0.0]),
                         radius, flatten=0.8, rows=8, columns=12)

    _add_leaves(builder, genome, skeleton, growth)
    _add_blooms(builder, genome, skeleton, growth)
    return builder.parts


def _add_leaves(builder, genome, skeleton, growth):
    """Mirror of `PlantBuilder.addLeaves`: the crown's leaves, then the stem's.

    A rosette carries none on the stem — its node leaves are counted into
    `crownCount` instead — and every other family may carry a few at its foot
    as well as those up the stem. Leaves open from the base upward, and the
    crown is the base, so its leaves are the first out, outermost first.
    """
    crown = genome.crownCount
    on_stem = 0 if genome.rosette else genome.leafCount
    total = crown + on_stem
    if total <= 0 or growth["leafUnfurl"] <= 0:
        return
    opened = total * growth["leafUnfurl"]
    vigour = 0.45 + 0.55 * growth["heightScale"]
    # A crown leaf that stands up grows as the plant's height does, and one
    # lying out grows as a stem leaf does. Tied to `vigour` alone a young fern
    # stood a fifth taller than it had before it had a crown; tied to the
    # height alone a young succulent or lotus shrank to a few centimetres.
    upright = 0.15 + 0.85 * growth["heightScale"]

    foot = skeleton["stem"][0]
    for index in range(crown):
        progress = opened - index
        if progress <= 0:
            return
        _add_crown_leaf(builder, genome, index, crown, foot,
                        min(1.0, progress), vigour, upright)

    # Stem leaves keep the jitter streams they always had, keyed by their own
    # index rather than their place in the opening order, so a crown arriving
    # under a plant does not reshuffle the leaves above it.
    for index in range(on_stem):
        progress = opened - (crown + index)
        if progress <= 0:
            break
        openness = min(1.0, progress)
        node_index = index // max(1, genome.leavesPerNode)
        if node_index >= len(skeleton["nodes"]):
            break
        node = skeleton["nodes"][node_index]

        jitter = SplitMix64(genome.seed, f"leaf.{index}")
        azimuth = genome.divergence * index + jitter.value(-0.12, 0.12)
        # A separate stream, as in the Swift, so the taper was added without
        # shifting the azimuth and scale drawn above it.
        shape = SplitMix64(genome.seed, f"leaf.taper.{index}")
        scale = (openness * vigour * jitter.value(0.86, 1.14)
                 * leaf_taper(node["t"], shape))

        radial = normalize(node["normal"] * math.cos(azimuth) + node["binormal"] * math.sin(azimuth))
        pitch = genome.leafPitch + jitter.value(-0.1, 0.1)
        _add_blade(builder, genome,
                   origin=node["position"] + radial * node["radius"] * 0.8,
                   axis=node["tangent"], radial=radial,
                   length=genome.leafLength * genome.stemLeafScale * scale,
                   pitch=pitch, droop=genome.leafDroop)


def leaf_taper(t, jitter):
    """How large a stem leaf is for its height up the stem.

    Mirror of `PlantBuilder.leafTaper`: largest low down, smaller toward the
    crown, and the very lowest small again because a seedling's first pair
    stay small. A per-leaf draw on top, wide enough to break the rhythm.
    """
    rise = min(1.0, max(0.0, t / 0.22))
    fall = 1 - 0.62 * min(1.0, max(0.0, (t - 0.2) / 0.8))
    return rise * fall * jitter.value(0.82, 1.2)


def _add_crown_leaf(builder, genome, index, count, foot, openness, lying, upright):
    """One leaf from the crown, at the foot of the stem.

    Mirror of `PlantBuilder.addCrownLeaf`. Outermost first, and each one in
    from it smaller and more upright — a rosette, a fern's vase and a poppy's
    clump alike. Laid round the world's up rather than the stem's tangent,
    because a leaning stem leans from the crown and the crown sits flat.
    """
    # How far in from the outside this leaf is, 0 outermost and 1 at the centre.
    inward = index / (count - 1) if count > 1 else 0.0
    jitter = SplitMix64(genome.seed, f"leaf.crown.{index}")
    azimuth = genome.divergence * index + jitter.value(-0.15, 0.15)
    up = np.array([0.0, 1.0, 0.0])
    radial = np.array([math.cos(azimuth), 0.0, math.sin(azimuth)])
    spread = jitter.value(0.86, 1.14)

    if genome.pads:
        # A pad lies flat, so it grows as a leaf lying out does.
        _add_pad(builder, genome, foot["position"] + radial * foot["radius"] * 0.6,
                 radial, inward,
                 genome.crownLength * (1 - 0.35 * inward) * openness * lying * spread,
                 openness, jitter)
        return

    pitch = genome.crownPitch * (1 - genome.crownRise * inward) + jitter.value(-0.08, 0.08)
    # Upright by the cosine of its angle off vertical: a frond standing
    # straight up grows wholly with the height, a leaf on the soil wholly as a
    # stem leaf does.
    standing = max(0.0, math.cos(pitch))
    size = openness * spread * (lying + (upright - lying) * standing)
    length = genome.crownLength * (1 - genome.crownTaper * inward) * size
    # A rosette is stacked: each leaf in rises from a little higher on the
    # crown than the one outside it.
    lift = genome.crownLength * 0.06 * inward * size if genome.rosette else 0.0
    # Crown leaves arch rather than sag, and a fleshy one turns its tip up a
    # little instead. Capped where the tip comes back to the height it left
    # from, so no leaf is drawn through the ground it grows on.
    turn = -0.18 * genome.fleshiness if genome.fleshiness > 0 else genome.leafDroop * 1.1
    arch = min(turn, math.pi - 2 * pitch - 0.1)
    _add_blade(builder, genome,
               origin=foot["position"] + radial * foot["radius"] * 0.8
               + up * (foot["radius"] + lift),
               axis=up, radial=radial, length=length, pitch=pitch,
               droop=0.0, arch=arch, pinnae=genome.pinnae)


def _add_pad(builder, genome, foot, radial, inward, diameter, openness, jitter):
    """A lotus pad: round, held flat on its own stalk from the middle.

    Mirror of `PlantBuilder.addPad`. The outer pads are the broadest and sit
    lowest, spreading furthest; the inner ones stand a little higher and closer
    in, so neighbours overlap like a water lily's rather than standing up like
    dishes on a table.
    """
    if diameter <= 0.002:
        return
    up = np.array([0.0, 1.0, 0.0])
    radius = diameter * 0.5
    out = diameter * (0.68 - 0.36 * inward) * jitter.value(0.85, 1.15)
    rise = diameter * (0.03 + 0.2 * inward) * jitter.value(0.7, 1.3)
    centre = foot + radial * out + up * rise

    # The stalk climbs first and leans out after, a quadratic through a point
    # above the foot, so it meets the pad from below.
    bend = foot + up * rise * 0.95 + radial * out * 0.15
    stalk_radius = max(0.0008, diameter * 0.016)
    positions, radii = [], []
    for step in range(9):
        t = step / 8
        a = foot + (bend - foot) * t
        b = bend + (centre - bend) * t
        positions.append(a + (b - a) * t)
        radii.append(stalk_radius * (1 - 0.3 * t))
    # A petiole is part of the leaf, and is drawn as one.
    builder.add_tube("leaf", transport_frames(positions, radii, 0.0), 5)

    # Tipped a little outward, and cupped so the rim stands above the middle.
    tilt = jitter.value(0.02, 0.1)
    normal = normalize(up + radial * tilt)
    forward = normalize(radial - normal * float(np.dot(radial, normal)))
    side = normalize(np.cross(normal, forward))
    cup = radius * jitter.value(0.04, 0.1) * openness
    vein_depth = genome.veinDepth

    def point(u, v):
        x = v * 2 - 1
        width = math.sqrt(max(0.0, 1 - x * x))
        y = (u * 2 - 1) * width
        distance = x * x + y * y
        # Faint ribs out from the centre, enough to catch the light.
        rib = vein_depth * radius * 0.03 * (u * 2 - 1) * (u * 2 - 1)
        return (centre + forward * (x * radius) + side * (y * radius)
                + normal * (cup * distance + rib))

    builder.add_surface("leaf", 19, 11, point)


def _add_blade(builder, genome, origin, axis, radial, length, pitch, droop,
               arch=0.0, pinnae=0):
    """A blade from `origin`, leaning `pitch` off `axis` toward `radial`.

    Mirror of `PlantBuilder.addBlade`, shared by the stem's leaves and the
    crown's. **A sagging blade is pushed; an arching one turns**: the sag moves
    each point of a straight midrib off to one side, which is right for a leaf
    held out from a stem and kinks a frond that starts near upright, so a crown
    leaf's midrib turns its own direction a little at a time instead —
    constant curvature, closed-form.
    """
    if length <= 0.001:
        return

    forward = normalize(radial * math.sin(pitch) + axis * math.cos(pitch))
    side = normalize(np.cross(axis, radial))
    up = normalize(np.cross(forward, side))

    fleshiness = genome.fleshiness
    # A fleshy leaf is smooth and runs out to a point: teeth, veins and fold
    # laid over a swollen blade crumple it, and a blunt one reads as a pebble.
    smooth = max(0.0, 1 - fleshiness)
    half_width = length * genome.leafWidthRatio * 0.5
    fold = genome.leafFold * (0.3 + 0.7 * smooth)
    sharpness = max(genome.leafTipSharpness, 1.5 * fleshiness)
    # A pinnate frond is the saw-toothed margin cut nearly to the midrib, with
    # three rows to a leaflet or the cuts alias into a ragged edge.
    serration = 3.6 if pinnae > 0 else genome.serration * smooth
    teeth = pinnae if pinnae > 0 else genome.teeth
    rows = 3 * pinnae + 4 if pinnae > 0 else 19
    vein_count = genome.veinCount
    vein_depth = genome.veinDepth * smooth

    def spine(s):
        if abs(arch) <= 1e-3:
            return forward * (s * length) + up * (-droop * length * s * s * 0.8), up
        heading = pitch + arch * s
        run = length / arch
        position = (radial * (run * (math.cos(pitch) - math.cos(heading)))
                    + axis * (run * (math.sin(heading) - math.sin(pitch))))
        return position, axis * math.sin(heading) - radial * math.cos(heading)

    def point(u, v, thickness):
        s = v
        profile = blade_profile(s, sharpness, serration, teeth)
        across = (u - 0.5) * 2 * half_width * profile
        crease = fold * half_width * profile * (abs(u - 0.5) * 2) ** 2
        vein = (vein_depth * half_width * 0.14
                * math.sin(s * math.pi * 2 * vein_count) * (abs(u - 0.5) * 2))
        # A fleshy leaf is swollen across its middle and thin at the edge.
        x = (u - 0.5) * 2
        swell = thickness * half_width * profile * (1 - x * x)
        midrib, face = spine(s)
        return origin + midrib + face * (crease + vein + swell) + side * across

    builder.add_surface("leaf", rows, 9, lambda u, v: point(u, v, 0.7 * fleshiness))
    # A succulent's leaf has an underside: a second surface bowed the other way
    # and meeting the first at the margin makes the leaf a body, not a sheet.
    if fleshiness > 0:
        builder.add_surface("leaf", rows, 9, lambda u, v: point(u, v, -0.7 * fleshiness),
                            flip=True)


def _flush_factor(position, growth):
    """The travelling wave. See SeedCore's PlantBuilder.flushFactor."""
    depth = growth.get("flushDepth", 0.0)
    if depth <= 0:
        return 1.0
    wave = 0.5 + 0.5 * math.cos(2 * math.pi * (growth.get("flush", 0.0) - position))
    return 1 - depth * 0.55 * (1 - wave)


def _flushed(growth, position):
    factor = _flush_factor(position, growth)
    if factor >= 1:
        return growth
    local = dict(growth)
    local["budSwell"] *= factor
    local["bloomOpen"] *= factor
    return local


def bloom_placements(genome, growth, node_ts, stalks):
    """Every flower this plant carries, in the order they are drawn.

    Mirror of `PlantBuilder.forEachBloom`, and the one part of this file that
    `check_port.py` reads directly, because it is the part that has actually
    gone wrong. Nothing here survives into the mesh as anything a reader could
    recover: `budSwell` and `bloomOpen` become an angle and a length, and
    `scale` is folded into both. Two flowers half a cycle apart differ by a few
    hundred vertices in a plant that has thousands, which is how the last drift
    lasted three revisions.

    Takes the nodes' `t` values and the number of stalks rather than a skeleton,
    so that it can be called without numpy. `_add_blooms` passes the real ones
    off the swept skeleton; `check_port.py` gets them from `node_indices` and
    `stalk_count`.

    `t` is 1 for the crown and for every stalk tip, by construction rather than
    by assumption: each sits on the last sample of its own path, and
    `transport_frames` numbers that one 1.
    """
    if not genome.bloomPresent or growth["budSwell"] <= 0.02:
        return []

    # The crown leads the cycle, so its position in the wave is zero.
    crown = _flushed(growth, 0.0)
    placements = [dict(kind="crown", index=0, t=1.0,
                       budSwell=crown["budSwell"], bloomOpen=crown["bloomOpen"],
                       scale=genome.bloomScale)]

    # A head has no up and down to run a wave along, so its stalks take an even
    # share of the cycle instead.
    for offset in range(stalks):
        size = SplitMix64(genome.seed, f"bloom.size.branch.{offset}")
        local = _flushed(growth, (offset + 1) / (stalks + 1))
        placements.append(dict(kind="branch", index=offset + 1, t=1.0,
                               budSwell=local["budSwell"], bloomOpen=local["bloomOpen"],
                               scale=genome.bloomScale * size.value(0.86, 1.1)))

    if not genome.bloomsAtNodes:
        return placements
    for offset, t in enumerate(node_ts):
        if t <= 0.35:
            continue
        lag = (1 - t) * 0.5
        # **This port was missing the ceiling and the taper entirely**, so every
        # spike it drew carried identical fully-open heads at even spacing —
        # which is precisely the tell SeedCore's own comments record fixing, and
        # which every render taken from this file has therefore been wrong about.
        ceiling = 0.45 + 0.55 * t
        flush = _flush_factor(t, growth)
        bud = min(ceiling, max(0.0, growth["budSwell"] - lag) / max(0.01, 1 - lag)) * flush
        openness = min(ceiling, max(0.0, growth["bloomOpen"] - lag) / max(0.01, 1 - lag)) * flush
        if bud <= 0.02:
            continue
        size = SplitMix64(genome.seed, f"bloom.size.{offset}")
        up = min(1.0, max(0.0, (t - 0.35) / 0.65))
        placements.append(dict(kind="node", index=offset + 1, t=t,
                               budSwell=bud, bloomOpen=openness,
                               scale=(0.4 + 0.34 * up) * size.value(0.88, 1.12)))
    return placements


def _add_blooms(builder, genome, skeleton, growth):
    branches = skeleton.get("branches", [])
    placements = bloom_placements(genome, growth,
                                  [node["t"] for node in skeleton["nodes"]],
                                  len(branches))
    for placement in placements:
        if placement["kind"] == "crown":
            sample = skeleton["apex"]
        elif placement["kind"] == "branch":
            sample = branches[placement["index"] - 1]["path"][-1]
        else:
            # On its stalk, not on the stem.
            pedicel = skeleton.get("pedicels", {}).get(placement["index"] - 1)
            sample = pedicel["path"][-1] if pedicel else skeleton["nodes"][placement["index"] - 1]
            if pedicel:
                base = pedicel["path"][0]
                builder.add_tube("stem", pedicel["path"], max(4, genome.sides - 2))
                builder.add_dome("stem", base["position"], -base["tangent"], base["normal"],
                                 base["radius"], 0.5, 4, max(5, genome.sides - 2))
        # Only the two the placement carries move; a flower's stage, age and
        # phase are the plant's own and pass through untouched.
        local = dict(growth)
        local["budSwell"] = placement["budSwell"]
        local["bloomOpen"] = placement["bloomOpen"]
        _add_bloom(builder, genome, sample, placement["scale"], local, placement["index"])


def _add_bloom(builder, genome, sample, scale, growth, index):
    jitter = SplitMix64(genome.seed, f"bloom.{index}")
    # Every head on a spike used to tip by exactly the same angle in the same
    # plane, so the spike leaned as one object. Its own stream, as in the
    # Swift, so the draws on `jitter` keep their order.
    lean = SplitMix64(genome.seed, f"bloom.lean.{index}")
    nod_axis = normalize(np.cross(sample["tangent"], sample["normal"]))
    axis = normalize(rotate_axis(sample["tangent"], nod_axis,
                                 genome.headPitch + lean.value(-0.22, 0.22)))
    ref_a = arbitrary_perpendicular(axis)
    ref_b = normalize(np.cross(axis, ref_a))

    bud_scale = 0.4 + 0.6 * growth["budSwell"]
    petal_length = genome.petalLength * scale * bud_scale
    if petal_length <= 0.002:
        return

    closed_angle = 0.08
    open_angle = 1.05 + genome.curl * 0.35
    openness = closed_angle + (open_angle - closed_angle) * growth["bloomOpen"]
    # The flower stands off the tip it grows from, so that a bud is a body
    # rather than a cone closing on a point.
    origin = sample["position"] + axis * petal_length * 0.08

    # The receptacle, which is that stand-off closed. Everything the flower is
    # made of is built from `origin`, and the stem or stalk under it ends at
    # `sample["position"]`; nothing was drawn across the gap unless the plant
    # happened to have a sepal collar, which is a seven-in-ten chance. It rises
    # along `axis` rather than the stem's tangent, because that is the line the
    # stand-off was taken along, so it spans the gap at any nod.
    builder.add_dome("stem", sample["position"], axis, ref_a,
                     petal_length * 0.10, flatten=0.9, rows=4,
                     columns=max(5, genome.sides - 2))

    # **The centre is a third of a petal at most, and the petals stand on its
    # rim.** Sized by the gene alone a lotus's centre reached nine-tenths of a
    # petal, and centred on the point every petal sprang from, so the petals
    # pierced it and its rim hung outside them: a ring under every flower.
    # Capped here rather than in the gene, so the gene still orders centres.
    # The petals start at nine-tenths of the rim and are shortened by half of
    # it, so the flower is as wide as it was.
    centre_radius = min(petal_length * genome.centreRadius * 1.6, petal_length * 0.34)
    base_ring = centre_radius * 0.9
    per_layer = max(3, genome.petalCount)

    for layer in range(max(1, genome.layers)):
        layer_fraction = layer / max(1, genome.layers)
        layer_scale = 1.0 - layer_fraction * 0.28
        layer_open = openness * (1.0 - layer_fraction * 0.35)
        for petal in range(per_layer):
            azimuth = 2 * math.pi * (petal + 0.5 * layer) / per_layer + genome.bloomTwist * layer_fraction
            petal_jitter = SplitMix64(genome.seed, f"petal.{index}.{layer}.{petal}")
            _add_petal(builder, genome, origin, axis, ref_a, ref_b,
                       azimuth + petal_jitter.value(-0.05, 0.05), layer_open,
                       (petal_length - base_ring * 0.5) * layer_scale * petal_jitter.value(0.92, 1.08),
                       growth["bloomOpen"],
                       # Inner layers stand a little further in, so they rise
                       # from inside the outer ones rather than through them.
                       base_ring * (1 - layer_fraction * 0.3))

    builder.add_dome("centre", origin, axis, ref_a, centre_radius,
                     flatten=0.55 + jitter.unit() * 0.4, rows=8, columns=14)

    if growth["bloomOpen"] > 0.3 and genome.stamenCount > 0:
        _add_stamens(builder, genome, origin, axis, ref_a, ref_b, centre_radius,
                     petal_length * 0.42 * growth["bloomOpen"])

    if genome.hasPistil and growth["bloomOpen"] > 0.25:
        _add_pistil(builder, genome, origin, axis, ref_a, centre_radius,
                    petal_length * 0.55 * growth["bloomOpen"])

    rim_radius, rim_depth = _add_calyx(builder, genome, origin, axis, ref_a,
                                       centre_radius, petal_length)

    # The sepals, present from the bud onward. A bell always has its five;
    # everyone else has them where `bloom.hasSepals` drew them, carried the way
    # the family carries them.
    sepals = genome.sepals
    count = 5 if sepals == "spreading" else genome.sepalCount
    if count <= 0 or sepals == "none":
        return
    cup_side = origin - axis * rim_depth * 0.25
    if sepals == "reflexed":
        # From partway down the cup, past a right angle to the axis, so they
        # fold back down the stem.
        _add_sepals(builder, genome, count, origin - axis * rim_depth * 0.6, rim_radius * 0.7,
                    axis, ref_a, ref_b, (1.75, 2.25),
                    petal_length * 0.5, petal_length * 0.2, -0.25)
    elif sepals == "spreading":
        _add_sepals(builder, genome, count, cup_side, rim_radius * 0.95,
                    axis, ref_a, ref_b, (1.0, 1.3),
                    petal_length * 0.42, petal_length * 0.07, -0.1)
    elif sepals == "appressed":
        # Short, held up close under the petals, curving in to them.
        _add_sepals(builder, genome, count, cup_side, rim_radius * 0.95,
                    axis, ref_a, ref_b, (0.55, 0.8),
                    petal_length * 0.28, petal_length * 0.13, 0.12)


# How each family's calyx is built: its role, its rim against the centre's
# radius, its depth, and its flare — below 1 a bowl, above 1 a stalk flaring at
# the top. Depth is a function because two of them are measured against the
# petal and three against the rim. Mirror of the switch in `addCalyx`.
CALYX_SHAPES = {
    "lid":        ("stem",  0.92, lambda petal, rim: petal * 0.1,  0.5),
    "swelling":   ("stem",  0.92, lambda petal, rim: petal * 0.22, 1.6),
    "stalk":      ("stem",  0.92, lambda petal, rim: petal * 0.45, 2.2),
    "cup":        ("calyx", 1.04, lambda petal, rim: max(petal * 0.14, rim * 0.45), 0.55),
    "shallowCup": ("calyx", 1.08, lambda petal, rim: rim * 0.32, 0.45),
    "urn":        ("calyx", 1.04, lambda petal, rim: rim * 1.5, 1.0),
}


def _add_calyx(builder, genome, origin, axis, side, centre_radius, petal_length):
    """The closed body under a flower, from a little way down its stalk to just
    outside the centre's rim, where it turns in underneath it.

    Mirror of `PlantBuilder.addCalyx`. **Every flower gets one, because the
    centre alone was a hollow**: a dome open underneath, whose rim the petals
    pierced. It starts from a point on the stalk and ends tucked under the
    centre, so the flower is one body with no inside to show. What it is is the
    family's — a daisy's shallow green cup, a thistle's urn of scales, a
    poppy's swollen stalk-top. Returns the rim's radius and the cup's depth,
    which the sepals are placed from.
    """
    up = normalize(axis)
    right = normalize(side - up * float(np.dot(side, up)))
    forward = np.cross(up, right)
    calyx = genome.calyx

    role, rim_scale, depth_of, flare = CALYX_SHAPES[calyx]
    rim = centre_radius * rim_scale
    depth = depth_of(petal_length, rim)
    base = origin - up * depth
    tuck = centre_radius * 0.85
    # The lip sits just under the petals' bases, so they rest on it rather
    # than fighting it for the same plane.
    lip = depth - centre_radius * 0.04
    urn = calyx == "urn"

    def point(u, v):
        # Taken clockwise, so `add_surface` reads the normals as outward.
        azimuth = -u * 2 * math.pi
        if v < 0.82:
            s = v / 0.82
            height = lip * s
            if urn:
                # Swells to a fifth past the rim two-thirds of the way up, then
                # draws in to it: an urn tapering into the stalk.
                belly = rim * 1.2
                radius = (belly * math.sin(math.pi * 0.5 * s / 0.68) if s < 0.68
                          else belly + (rim - belly) * ((s - 0.68) / 0.32))
                # Scales: rows of bracts overlapping upward, each flaring at its
                # tip, alternate columns half a row out of step.
                column = int(u * 12)
                row = s * 6 + (0 if column % 2 == 0 else 0.5)
                radius *= 1 + 0.09 * (row - math.floor(row)) * s
            else:
                radius = rim * s ** flare
        else:
            # Over the rim and in under the centre.
            w = (v - 0.82) / 0.18
            height = lip
            radius = rim + (tuck - rim) * w
        return (base + up * height + right * (radius * math.cos(azimuth))
                + forward * (radius * math.sin(azimuth)))

    builder.add_surface(role, 25 if urn else 11, 25 if urn else 17, point)
    return rim, depth


def _add_sepals(builder, genome, count, origin, ring, axis, ref_a, ref_b,
                pitch, length, width, curve):
    """A whorl of short green blades round the cup.

    Mirror of `PlantBuilder.addSepals`. `pitch` is the angle off the flower's
    axis — past a right angle they fold back down the stalk, well under one
    they stand up against the petals — and `curve` bends each along its
    length, back for negative.
    """
    if length <= 0.002:
        return
    for index in range(count):
        jitter = SplitMix64(genome.seed, f"sepal.{index}")
        azimuth = 2 * math.pi * index / count + jitter.value(-0.1, 0.1)
        radial = normalize(ref_a * math.cos(azimuth) + ref_b * math.sin(azimuth))
        angle = jitter.value(*pitch)
        forward = normalize(radial * math.sin(angle) + axis * math.cos(angle))
        side = normalize(np.cross(axis, radial))
        up = normalize(np.cross(forward, side))
        half_width = width * 0.5
        start = origin + radial * ring

        def point(u, v, start=start, forward=forward, up=up, side=side):
            profile = blade_profile(v, 1.3, 0, 0)
            across = (u - 0.5) * 2 * half_width * profile
            bend = curve * length * v * v
            return start + forward * (v * length) + up * bend + side * across

        builder.add_surface("calyx", 7, 5, point)


def _add_pistil(builder, genome, origin, axis, side, radius, length):
    if length <= 0.002:
        return
    stalk = max(0.0008, length * 0.055)
    base = origin + axis * radius * 0.3
    tip = origin + axis * (radius * 0.4 + length)
    samples = transport_frames([base, (base + tip) * 0.5, tip],
                               [stalk, stalk * 0.9, stalk * 0.75], 0)
    builder.add_tube("stamen", samples, 5)
    builder.add_dome("stamen", tip, axis, side, stalk * 2.2, flatten=1.0, rows=5, columns=10)


def _add_petal(builder, genome, origin, axis, ref_a, ref_b, azimuth, openness, length,
               bloom_open, base_ring):
    """Mirror of `PlantBuilder.addPetal`, on the centre's rim and cut to the
    family's outline."""
    radial = normalize(ref_a * math.cos(azimuth) + ref_b * math.sin(azimuth))
    # Each petal leaves the centre's rim, not its middle.
    origin = origin + radial * base_ring
    forward = normalize(radial * math.sin(openness) + axis * math.cos(openness))
    side = normalize(np.cross(axis, radial))
    up = normalize(np.cross(side, forward))
    half_width = length * genome.petalWidthRatio * 0.5
    curl = genome.curl * bloom_open - (1 - bloom_open) * 0.7
    sharpness = genome.petalTipSharpness
    rounded_outline = genome.petalOutline == "rounded"
    crumple = genome.crumple
    # Where the creases fall, from the petal's own place round the flower, so
    # no two petals of a poppy are creased alike and no draw is spent.
    crease_phase = azimuth * 2.7

    def point(u, v):
        s = petal_row(v)
        profile = (petal_profile(s, sharpness) if rounded_outline
                   else blade_profile(s, sharpness, 0, 0))
        x = (u - 0.5) * 2
        across = x * half_width * profile
        bend = curl * length * s * s * 0.75
        # A round petal is dished a little across its width, its edges turned
        # in toward the flower's middle — which is also what makes the round
        # end read as round from the side.
        dish = -0.22 * half_width * profile * x * x if rounded_outline else 0.0
        # Creased silk: two soft waves at an angle to the midrib, strongest
        # toward the edge and the tip, where a poppy's petal is thinnest.
        crease = 0.0
        if crumple != 0:
            crease = (crumple * half_width * profile * 0.12 * (0.35 + 0.65 * abs(x)) * s
                      * (0.6 * math.sin(math.pi * (3 * s + 1.2 * x) + crease_phase)
                         + 0.4 * math.sin(math.pi * (5 * s - 0.9 * x) + 2 * crease_phase)))
        twist_angle = genome.bloomTwist * s
        local_side = side * math.cos(twist_angle) + up * math.sin(twist_angle)
        local_up = up * math.cos(twist_angle) - side * math.sin(twist_angle)
        # A cleft cut into the very tip, dying away toward the base.
        cleft = genome.notch * length * 0.2 * math.exp(-((x * 2.5) ** 2)) * (s ** 6)
        return (origin + forward * (s * length - cleft) + local_side * across
                + local_up * (bend + dish + crease))

    # Seventeen rows, drawn in toward the tip: thirteen even ones made the edge
    # a polygon and closed the tip in one straight cut, which is where a round
    # end has all its curve.
    builder.add_surface("petal", 17, 9, point)


def petal_row(v):
    """How far along a petal row `v` of its grid stands: `v + v² − v³`.

    Mirror of `PlantBuilder.petalRow`. Even at the base and closest together at
    the tip, which spaces the rows evenly round a round end. Only where the
    rows fall moves; the petal's length is its length.
    """
    return v + v * v - v * v * v


def petal_profile(s, sharpness):
    """Width of a round petal at `s` along it: 0 at the base, 1 at its widest,
    0 at the tip, with no corner anywhere between.

    Mirror of `PlantBuilder.petalProfile`. A quarter sine out of a narrow claw
    to the widest point, then a quarter superellipse whose tangent at the tip
    is square to the midrib — a round end, never a point. The tip gene says
    how round: bluntest, the widest point at 0.62 and the end fuller than a
    circle; sharpest, the widest at 0.48 and an oval running to a soft point.
    """
    k = max(0.0, min(1.0, (sharpness - 0.6) / 1.8))
    widest = 0.62 - 0.14 * k
    fullness = 2.6 - 0.8 * k
    s = max(0.0, min(1.0, s))
    if s <= widest:
        return math.sin(math.pi * 0.5 * s / widest) ** 0.8
    t = (s - widest) / (1 - widest)
    return max(0.0, 1 - t ** fullness) ** (1 / fullness)


def _add_stamens(builder, genome, origin, axis, ref_a, ref_b, radius, length):
    if genome.stamenCount <= 0 or length <= 0.001:
        return
    filament_radius = max(0.0006, length * 0.035)
    for index in range(genome.stamenCount):
        jitter = SplitMix64(genome.seed, f"stamen.{index}")
        azimuth = 2 * math.pi * index / genome.stamenCount + jitter.value(-0.2, 0.2)
        radial = normalize(ref_a * math.cos(azimuth) + ref_b * math.sin(azimuth))
        direction = normalize(axis + radial * jitter.value(0.15, 0.5))
        base = origin + radial * radius * 0.55 + axis * radius * 0.35
        tip = base + direction * length
        samples = transport_frames([base, base + direction * length * 0.5, tip],
                                   [filament_radius, filament_radius * 0.85, filament_radius * 0.7], 0)
        builder.add_tube("stamen", samples, 4)
        builder.add_dome("stamen", tip, direction, radial, filament_radius * 2.6,
                         flatten=1.0, rows=5, columns=8)


# ------------------------------------------------------------------- colours

def hsb_interpolate(a, b, t):
    t = clamp(t, 0, 1)
    delta = b[0] - a[0]
    if delta > 0.5:
        delta -= 1
    if delta < -0.5:
        delta += 1
    return (wrapped_unit(a[0] + delta * t),
            a[1] + (b[1] - a[1]) * t,
            a[2] + (b[2] - a[2]) * t)


def smoothstep(t):
    x = clamp(t, 0, 1)
    return x * x * (3 - 2 * x)


def ramp_colour(role, u, v, palette):
    """Mirror of PaletteRamp.colour."""
    u, v = clamp(u, 0, 1), clamp(v, 0, 1)

    if role == "petal":
        colour = hsb_interpolate(palette["petalBase"], palette["petalTip"], smoothstep(v))
        throat = max(0.0, 1 - v / 0.34) ** 1.6
        colour = hsb_interpolate(colour, palette["petalThroat"], throat * 0.9)
        if palette["veining"] > 0:
            ridges = abs(math.sin(u * math.pi * 5))
            vein = (ridges ** 7) * palette["veining"] * (1 - v * 0.45)
            colour = hsb_interpolate(colour, palette["petalVein"], vein)
        if palette["picotee"] is not None:
            side = 1 - min(u, 1 - u) / 0.16
            tip = (v - 0.86) / 0.14
            edge = clamp(max(side, tip), 0, 1)
            colour = hsb_interpolate(colour, palette["picotee"], edge ** 1.4)
        return colour

    if role == "leaf":
        leaf = palette["leaf"]
        tip = (leaf[0], leaf[1], min(1, leaf[2] * 1.16))
        colour = hsb_interpolate(leaf, tip, v)
        style = palette["variegation"]
        if style == "margin":
            edge = clamp(1 - min(u, 1 - u) / 0.18, 0, 1)
            colour = hsb_interpolate(colour, palette["leafAccent"], (edge ** 1.6) * 0.95)
        elif style == "midrib":
            centre = clamp(1 - abs(u - 0.5) / 0.22, 0, 1)
            colour = hsb_interpolate(colour, palette["leafAccent"], (centre ** 1.8) * 0.9)
        elif style == "speckled":
            if speckle(u, v, palette["speckleSeed"], 4.5) > 0.78:
                colour = hsb_interpolate(colour, palette["leafAccent"], 0.6)
        return colour

    if role == "stem":
        stem = palette["stem"]
        return hsb_interpolate(stem, (stem[0], stem[1], min(1, stem[2] * 1.25)), v)

    if role == "centre":
        centre = palette["centre"]
        return hsb_interpolate(centre, (centre[0], centre[1], max(0, centre[2] * 0.7)), v)

    if role == "calyx":
        # The cup and sepals: the leaf's own colour, fresh — brighter and a
        # little less saturated than the blade, lightening toward the rim. See
        # `PaletteRamp.calyx`. Its own role because the stem's colour came out
        # a dark olive under the petals.
        leaf = palette["leaf"]
        base = (leaf[0], leaf[1], min(1, leaf[2] * 1.05))
        rim = (leaf[0], leaf[1] * 0.88, min(1, leaf[2] * 1.35))
        return hsb_interpolate(base, rim, smoothstep(v))

    return hsb_interpolate(palette["centre"], palette["petalTip"], v)
