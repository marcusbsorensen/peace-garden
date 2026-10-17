#!/usr/bin/env python3
"""
Executable reference for Peace Garden's space flora derivation, `peacegarden.space.v1`.

The Swift implementation in Packages/SeedCore/Sources/SeedCore/ZoneC/ must agree with
this file, and Autonaut's tests are held to the file it writes:

    tools/reference/space_flora_vectors.json

A space seed is 16 random bytes, `r`, that Autonaut draws. Peace Garden finds it as
`r || mark` and reads it by its first 16 bytes. The kind and every trait are drawn from
those 16 bytes alone, by name, through SHA-256 under the domain tag below: no key, no
HMAC, no HPKE, nothing a Linux or WebAssembly build lacks. So a draw from `r || mark`
is a draw from `r`.

In Zone C a found seed is crossed with the finder's own Zone C seed. The cross is
`derivation_reference.py`'s, unchanged (encounter, child, checksum), and the plant is
drawn by the same ladder `GeneSource` uses for a hybrid, trait by name:
36% the first parent's draw, 36% the second's, 22% a blend, 6% a draw of its own. The
parents are sorted on their whole seeds, so both phones draw the same plant.

    python3 tools/reference/space_flora_reference.py            # checks everything
    python3 tools/reference/space_flora_reference.py --write    # rewrites the vectors

Run with no argument it asserts the invariants (every kind reachable, a cross
commutative, the ladder's shares, `r || mark` equal to `r`) and that the committed
vectors are what this computes. It needs nothing but the standard library.
"""

import hashlib
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import derivation_reference as dr  # noqa: E402  (the cross itself, and the hash)

DOMAIN = "peacegarden.space.v1"
KEY_LENGTH = 16
VECTORS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "space_flora_vectors.json")

KINDS = ["cluster", "comet", "orbit", "crystal", "nebula"]

# ----------------------------------------------------------------------- kinds

KIND_DATA = {
    "cluster": {
        "letter": "A", "name": "Star Cluster", "form": "umbel",
        "quotation": "A mass of innumerable stars planted together in clusters.",
        "source": "Galileo Galilei, Sidereus Nuncius (1610), tr. Edward Stafford Carlos, "
                  "The Sidereal Messenger (1880)",
    },
    "comet": {
        "letter": "B", "name": "Comet Reed", "form": "reed",
        "quotation": "I'll tell you how the sun rose, — / A ribbon at a time.",
        "source": "Emily Dickinson, \"A Day\", Poems (First Series, 1890)",
    },
    "orbit": {
        "letter": "C", "name": "Orbit Vine", "form": "vine",
        "quotation": "Zero-g and I feel fine.",
        "source": "John Glenn, Friendship 7, 20 February 1962",
    },
    "crystal": {
        "letter": "D", "name": "Crystal Rosette", "form": "succulent",
        "quotation": "It has a stark beauty all its own.",
        "source": "Neil Armstrong, Apollo 11, 20 July 1969",
    },
    "nebula": {
        "letter": "E", "name": "Nebula Moss", "form": "cushion",
        "quotation": "they look like little stars. A whole shower of them coming by.",
        "source": "John Glenn, Friendship 7, 20 February 1962",
    },
}

# -------------------------------------------------------------------- profiles
#
# Ranges are (low, high). Lengths in metres, angles in radians, hues in 0..1.
# Mirrors SpaceFloraProfile.profile(for:) in SpaceFlora.swift line for line.

DEFAULTS = {
    "branchCount": (0, 0), "branchSpread": (0.0, 0.0), "branchAngle": (0.0, 0.0),
    "leafReach": 0.55,
    "rosette": False, "crownLeaves": (0, 0), "crownPitch": (0.0, 0.0),
    "crownRise": 0.55, "crownTaper": 0.5, "crownLengthScale": 1.0,
    "fleshiness": 0.0, "strap": False, "cushion": False,
    "cushionWidth": (0.0, 0.0), "sweep": (0.0, 0.0), "orbit": (0.0, 0.0),
    "bloomsAtNodes": False, "flowerShare": (0.0, 0.0),
    "leafHue": (0.27, 0.33), "leafSaturation": (0.10, 0.22), "leafBrightness": (0.70, 0.86),
}

PROFILES = {
    "cluster": dict(
        petals=(6, 9), vigour=(0.8, 1.2),
        inflorescence="head", branchCount=(5, 9), branchSpread=(0.25, 0.75),
        branchAngle=(0.9, 1.3), bloomScale=0.7,
        height=(0.45, 0.95), baseRadius=(0.005, 0.012), taper=(0.3, 0.7), lean=(0.0, 0.35),
        sway=(0.2, 0.9), twist=(0.0, 0.4),
        nodeCount=(2, 5), nodeZone=(0.12, 0.6),
        leavesPerNode=(1, 2), leafLength=(0.06, 0.16), leafWidthRatio=(0.12, 0.3),
        droop=(0.3, 0.9), fold=(0.1, 0.4), pitch=(0.6, 1.1), veinCount=(0, 2), leafTip=(1.2, 2.0),
        crownLeaves=(2, 4), crownPitch=(0.45, 0.8), crownRise=0.4, crownTaper=0.5,
        crownLengthScale=1.4,
        layers=(1, 1), petalLength=(0.025, 0.05), petalWidthRatio=(0.2, 0.4), curl=(0.1, 0.4),
        petalTwist=(-0.2, 0.2), headPitch=(0.0, 0.3), centreRadius=(0.15, 0.3), stamens=(3, 6),
        sepals="none", calyx="lid", outline="pointed", bloomPresence=1.0,
        schemes=["monochrome", "ombre"], petalHue=(0.155, 0.183),
        petalSaturation=(0.25, 0.55), petalBrightness=(0.88, 1.0),
        glow=(0.5, 0.9)),
    "comet": dict(
        petals=(6, 12), vigour=(0.85, 1.25),
        inflorescence="solitary", bloomScale=1.3,
        height=(0.6, 1.2), baseRadius=(0.004, 0.009), taper=(0.5, 0.85), lean=(0.45, 0.75),
        sway=(0.4, 1.0), twist=(0.0, 0.2),
        nodeCount=(1, 2), nodeZone=(0.1, 0.3),
        leavesPerNode=(1, 1), leafLength=(0.3, 0.6), leafWidthRatio=(0.03, 0.07),
        droop=(0.6, 1.1), fold=(0.05, 0.3), pitch=(0.2, 0.5), veinCount=(0, 0), leafTip=(1.6, 2.4),
        rosette=True, crownLeaves=(7, 12), crownPitch=(0.15, 0.55), crownRise=0.5,
        crownTaper=0.35, crownLengthScale=1.5, strap=True, sweep=(0.55, 0.85),
        layers=(2, 3), petalLength=(0.03, 0.06), petalWidthRatio=(0.5, 0.8), curl=(-0.7, -0.4),
        petalTwist=(-0.3, 0.3), headPitch=(0.6, 1.1), centreRadius=(0.25, 0.4), stamens=(0, 0),
        sepals="none", calyx="swelling", outline="rounded", bloomPresence=1.0,
        schemes=["ombre", "monochrome"], petalHue=(0.545, 0.576),
        petalSaturation=(0.2, 0.45), petalBrightness=(0.92, 1.0),
        glow=(0.6, 1.0)),
    "orbit": dict(
        petals=(6, 8), vigour=(0.85, 1.3),
        inflorescence="raceme", bloomScale=0.8,
        height=(0.9, 1.6), baseRadius=(0.003, 0.007), taper=(0.2, 0.6), lean=(0.0, 0.3),
        sway=(0.9, 1.6), twist=(0.55, 0.95),
        nodeCount=(6, 12), nodeZone=(0.2, 0.95),
        leavesPerNode=(1, 1), leafLength=(0.06, 0.12), leafWidthRatio=(0.7, 0.95),
        droop=(0.2, 0.6), fold=(0.1, 0.3), pitch=(0.9, 1.3), veinCount=(2, 4), leafTip=(0.5, 0.9),
        crownLeaves=(0, 2), crownPitch=(0.9, 1.2), crownLengthScale=1.3, orbit=(1.5, 3.0),
        bloomsAtNodes=True,
        layers=(1, 1), petalLength=(0.02, 0.04), petalWidthRatio=(0.6, 0.85), curl=(-0.6, -0.3),
        petalTwist=(-0.2, 0.2), headPitch=(0.2, 0.6), centreRadius=(0.2, 0.35), stamens=(0, 3),
        sepals="appressed", calyx="cup", outline="rounded", bloomPresence=1.0,
        schemes=["analogous", "monochrome"], petalHue=(0.74, 0.80),
        petalSaturation=(0.3, 0.55), petalBrightness=(0.85, 1.0),
        glow=(0.4, 0.8)),
    "crystal": dict(
        petals=(6, 12), vigour=(0.8, 1.2),
        inflorescence="raceme", bloomScale=1.0,
        height=(0.12, 0.3), baseRadius=(0.006, 0.012), taper=(0.3, 0.7), lean=(0.0, 0.2),
        sway=(0.1, 0.4), twist=(0.0, 0.3),
        nodeCount=(7, 13), nodeZone=(0.0, 0.0),
        leavesPerNode=(1, 1), leafLength=(0.1, 0.2), leafWidthRatio=(0.3, 0.5),
        droop=(0.0, 0.15), fold=(0.3, 0.6), pitch=(0.3, 0.75), veinCount=(1, 1), leafTip=(1.8, 2.4),
        rosette=True, crownLeaves=(2, 4), crownPitch=(0.3, 0.75), crownRise=0.5,
        crownTaper=0.45, crownLengthScale=1.0, fleshiness=1.0,
        layers=(1, 2), petalLength=(0.03, 0.06), petalWidthRatio=(0.25, 0.45), curl=(0.0, 0.3),
        petalTwist=(-0.2, 0.2), headPitch=(0.0, 0.4), centreRadius=(0.12, 0.22), stamens=(0, 4),
        sepals="none", calyx="cup", outline="pointed", bloomPresence=0.6,
        schemes=["analogous", "monochrome"], petalHue=(0.62, 0.68),
        petalSaturation=(0.3, 0.55), petalBrightness=(0.88, 1.0),
        leafSaturation=(0.06, 0.16), leafBrightness=(0.78, 0.92),
        glow=(0.4, 0.8)),
    "nebula": dict(
        petals=(6, 9), vigour=(0.8, 1.25),
        inflorescence="raceme", bloomScale=0.5,
        height=(0.08, 0.16), baseRadius=(0.004, 0.008), taper=(0.0, 0.0), lean=(0.0, 0.15),
        sway=(0.0, 0.2), twist=(0.0, 0.0),
        nodeCount=(18, 34), nodeZone=(0.0, 0.0),
        leavesPerNode=(5, 7), leafLength=(0.012, 0.025), leafWidthRatio=(0.3, 0.6),
        droop=(0.0, 0.3), fold=(0.0, 0.2), pitch=(0.3, 0.7), veinCount=(0, 0), leafTip=(0.8, 1.4),
        rosette=True, fleshiness=0.6, cushion=True, cushionWidth=(0.2, 0.38),
        layers=(1, 1), petalLength=(0.008, 0.016), petalWidthRatio=(0.4, 0.7), curl=(0.0, 0.3),
        petalTwist=(-0.2, 0.2), headPitch=(0.0, 0.3), centreRadius=(0.25, 0.4), stamens=(0, 0),
        sepals="none", calyx="lid", outline="rounded", bloomPresence=1.0,
        flowerShare=(0.25, 0.45),
        schemes=["ombre", "analogous"], petalHue=(0.845, 0.90),
        petalSaturation=(0.28, 0.5), petalBrightness=(0.88, 1.0),
        glow=(0.6, 1.0)),
}

for _kind, _profile in PROFILES.items():
    PROFILES[_kind] = {**DEFAULTS, **_profile}


# ------------------------------------------------------------------ the draw

def space_u64(key: bytes, label: str) -> int:
    d = dr.digest(DOMAIN, key, label.encode("utf-8"))
    return dr.mix64(int.from_bytes(d[:8], "big"))


def space_unit(key: bytes, label: str) -> float:
    """Uniform in [0, 1) - 53 significant bits, identical to Swift's."""
    return (space_u64(key, label) >> 11) * (2.0 ** -53)


def leading(seed: bytes) -> bytes:
    """A space seed is read by its first 16 bytes, whatever follows."""
    return seed[:KEY_LENGTH]


class Genes:
    """GeneSource's twin: the same calls over the space domain and a 16-byte key."""

    def __init__(self, key: bytes, parents=None):
        self.key = leading(key)
        self.parents = None if parents is None else (leading(parents[0]), leading(parents[1]))

    def unit(self, label: str) -> float:
        if self.parents is None:
            return space_unit(self.key, label)
        roll = space_unit(self.key, "inherit:" + label)
        if roll < dr.INHERIT_P0:
            return space_unit(self.parents[0], label)
        if roll < dr.INHERIT_P1:
            return space_unit(self.parents[1], label)
        if roll < dr.INHERIT_BLEND:
            a = space_unit(self.parents[0], label)
            b = space_unit(self.parents[1], label)
            return a + (b - a) * space_unit(self.key, "blend:" + label)
        return space_unit(self.key, "mutate:" + label)

    def value(self, label, rng):
        return rng[0] + self.unit(label) * (rng[1] - rng[0])

    def integer(self, label, rng):
        span = rng[1] - rng[0] + 1
        return rng[0] + min(span - 1, int(self.unit(label) * span))

    def chance(self, label, probability):
        return self.unit(label) < probability

    def pick(self, label, options):
        return options[min(len(options) - 1, int(self.unit(label) * len(options)))]

    def bell(self, label, rng):
        total = self.unit(label + ".a") + self.unit(label + ".b") + self.unit(label + ".c")
        return rng[0] + (total / 3.0) * (rng[1] - rng[0])

    def signed(self, label):
        return self.unit(label) * 2.0 - 1.0


def clamp(x, lo, hi):
    return min(max(x, lo), hi)


def wrapped(x):
    v = math.fmod(x, 1.0)  # Swift's truncatingRemainder
    return v + 1.0 if v < 0 else v


# --------------------------------------------------------------------- kinds

def kind_of_unit(unit: float) -> str:
    return KINDS[min(len(KINDS) - 1, int(unit * len(KINDS)))]


def kind_of(key: bytes) -> str:
    """The kind the 16 bytes draw, as a plant that is nobody's child."""
    return kind_of_unit(space_unit(leading(key), "space.kind"))


def inherited_kind(genes: Genes, parent_kinds):
    """The ladder, with the blend settled by a coin: a kind cannot be blended.
    Returns the kind and how it came."""
    roll = space_unit(genes.key, "inherit:space.kind")
    if roll < dr.INHERIT_P0:
        return parent_kinds[0], "first parent"
    if roll < dr.INHERIT_P1:
        return parent_kinds[1], "second parent"
    if roll < dr.INHERIT_BLEND:
        coin = space_unit(genes.key, "blend:space.kind")
        return (parent_kinds[0] if coin < 0.5 else parent_kinds[1]), "coin"
    return kind_of_unit(space_unit(genes.key, "mutate:space.kind")), "mutation"


# ---------------------------------------------------------------------- grow

def hsb(h, s, b):
    return [h, s, b]


def grow(kind: str, g: Genes, centre_kind):
    """Every drawn trait of a plant of `kind`, flat and named as SeedCore names them."""
    p = PROFILES[kind]
    t = {}

    t["seed"] = dr.digest(DOMAIN, g.key, b"space.seed").hex()

    merosity = "many" if g.chance("space.bloom.merosity", 0.5) else "few"
    vigour = g.bell("space.form.vigour", p["vigour"])
    flowers = g.chance("space.bloom.present", p["bloomPresence"])

    leaf_length = g.value("space.foliage.length", p["leafLength"]) * vigour
    typical = (p["leafLength"][0] + p["leafLength"][1]) * 0.5 * vigour
    rosette_length = p["crownLengthScale"] * (leaf_length * 0.6 + typical * 0.4)
    drawn_height = g.value("space.stem.height", p["height"]) * vigour
    height = (0.08 + drawn_height * 0.25) if (p["rosette"] and not flowers) else drawn_height

    t["form.archetype"] = KIND_DATA[kind]["form"]
    t["form.merosity"] = merosity
    t["form.vigour"] = vigour

    t["branching.inflorescence"] = p["inflorescence"]
    t["branching.count"] = g.integer("space.branch.count", p["branchCount"])
    t["branching.spread"] = clamp(g.value("space.branch.spread", p["branchSpread"]), 0.0, 1.0)
    t["branching.angle"] = g.value("space.branch.angle", p["branchAngle"])
    t["branching.bloomScale"] = p["bloomScale"]

    lean = g.value("space.stem.lean", p["lean"])
    twist = g.value("space.stem.twist", p["twist"])
    t["stem.height"] = height
    t["stem.baseRadius"] = g.value("space.stem.baseRadius", p["baseRadius"])
    t["stem.taper"] = g.value("space.stem.taper", p["taper"])
    t["stem.lean"] = lean if g.chance("space.stem.leanSide", 0.5) else -lean
    t["stem.sway"] = g.bell("space.stem.sway", p["sway"])
    t["stem.twist"] = twist if g.chance("space.stem.twistSide", 0.5) else -twist
    t["stem.nodeCount"] = g.integer("space.stem.nodeCount", p["nodeCount"])
    t["stem.sides"] = g.integer("space.stem.sides", (6, 9))

    vein_count = g.integer("space.foliage.veinCount", p["veinCount"])
    t["foliage.leavesPerNode"] = g.integer("space.foliage.leavesPerNode", p["leavesPerNode"])
    t["foliage.length"] = leaf_length
    t["foliage.widthRatio"] = g.value("space.foliage.widthRatio", p["leafWidthRatio"])
    t["foliage.droop"] = g.bell("space.foliage.droop", p["droop"])
    t["foliage.fold"] = g.value("space.foliage.fold", p["fold"])
    t["foliage.pitch"] = g.value("space.foliage.pitch", p["pitch"])
    t["foliage.divergence"] = 2.399963 + g.signed("space.foliage.divergence") * 0.22
    t["foliage.veinCount"] = vein_count
    t["foliage.veinDepth"] = g.bell("space.foliage.veinDepth", (0.25, 0.9)) if vein_count > 0 else 0.0
    t["foliage.tipSharpness"] = g.value("space.foliage.tipSharpness", p["leafTip"])

    reach = p["leafReach"]
    stem_leaf_scale = (1 - reach) + reach * min(1.5, max(0.4, height / 0.9))
    crown_count = (t["stem.nodeCount"] * t["foliage.leavesPerNode"] if p["rosette"] else 0) \
        + g.integer("space.habit.crownLeaves", p["crownLeaves"])
    t["habit.rosette"] = p["rosette"]
    t["habit.crownCount"] = crown_count
    t["habit.crownLength"] = rosette_length if p["rosette"] \
        else min(0.6, p["crownLengthScale"] * leaf_length * stem_leaf_scale)
    t["habit.crownPitch"] = g.value("space.habit.crownPitch", p["crownPitch"])
    t["habit.crownTaper"] = p["crownTaper"]
    t["habit.crownRise"] = p["crownRise"]
    t["habit.fleshiness"] = p["fleshiness"]
    t["habit.stemLeafScale"] = stem_leaf_scale
    t["habit.strap"] = p["strap"]
    t["habit.cushion"] = p["cushion"]
    t["habit.sweep"] = g.value("space.habit.sweep", p["sweep"])
    t["habit.orbit"] = g.value("space.habit.orbit", p["orbit"])
    t["habit.cushionWidth"] = g.value("space.habit.cushionWidth", p["cushionWidth"]) if p["cushion"] else None
    t["habit.flowerShare"] = g.value("space.bloom.flowerShare", p["flowerShare"]) if p["cushion"] else 0.45

    plan = p["petals"][0] if merosity == "few" else p["petals"][1]
    variance = g.unit("space.bloom.petalVariant")
    petal_count = max(3, plan + (-1 if variance < 0.1 else (1 if variance > 0.9 else 0)))
    stamen_count = g.integer("space.bloom.stamenCount", p["stamens"])
    t["bloom.petalCount"] = petal_count
    t["bloom.layers"] = g.integer("space.bloom.layers", p["layers"])
    t["bloom.length"] = g.value("space.bloom.length", p["petalLength"])
    t["bloom.widthRatio"] = g.value("space.bloom.widthRatio", p["petalWidthRatio"])
    t["bloom.curl"] = g.value("space.bloom.curl", p["curl"])
    t["bloom.twist"] = g.value("space.bloom.twist", p["petalTwist"])
    t["bloom.tipSharpness"] = g.value("space.bloom.tipSharpness", (0.6, 2.4))
    t["bloom.headPitch"] = g.value("space.bloom.headPitch", p["headPitch"])
    t["bloom.centreRadius"] = g.value("space.bloom.centreRadius", p["centreRadius"])
    t["bloom.stamenCount"] = stamen_count
    t["bloom.sepalCount"] = 0 if p["sepals"] == "none" else g.integer("space.bloom.sepalCount", (4, 6))
    t["bloom.hasPistil"] = stamen_count > 0 and g.chance("space.bloom.hasPistil", 0.6)
    t["bloom.atNodes"] = p["bloomsAtNodes"]
    t["bloom.opensFromBelow"] = p["bloomsAtNodes"]
    t["bloom.present"] = flowers
    t["bloom.calyx"] = p["calyx"]
    t["bloom.sepals"] = p["sepals"]
    t["bloom.outline"] = p["outline"]

    t.update(palette(g, p, centre_kind))

    t["tempo.germinationHours"] = g.value("space.tempo.germinationHours", (6.0, 24.0))
    t["tempo.seedlingDays"] = g.value("space.tempo.seedlingDays", (1.0, 3.0))
    t["tempo.vegetativeDays"] = g.value("space.tempo.vegetativeDays", (3.0, 8.0))
    t["tempo.buddingDays"] = g.value("space.tempo.buddingDays", (2.0, 5.0))
    t["tempo.bloomDays"] = g.value("space.tempo.bloomDays", (10.0, 30.0))
    t["tempo.opensByDay"] = False
    return t


def palette(g: Genes, p, centre_kind):
    t = {}
    scheme = g.pick("space.palette.scheme", p["schemes"])
    base_hue = g.value("space.palette.petalHue", p["petalHue"])
    base_sat = g.value("space.palette.petalSaturation", p["petalSaturation"])
    base_bri = g.value("space.palette.petalBrightness", p["petalBrightness"])
    direction = 1.0 if g.chance("space.palette.hueDirection", 0.5) else -1.0

    tip_hue, tip_sat, tip_bri = base_hue, base_sat, base_bri
    if scheme == "analogous":
        tip_hue = base_hue + direction * g.value("space.palette.tipShift", (0.02, 0.06))
        tip_sat = base_sat * g.value("space.palette.tipSaturation", (0.7, 1.1))
        tip_bri = base_bri * g.value("space.palette.tipBrightness", (0.95, 1.25))
    elif scheme == "ombre":
        tip_sat = base_sat * g.value("space.palette.tipSaturation", (0.08, 0.35))
        tip_bri = min(1.0, base_bri * g.value("space.palette.tipBrightness", (1.15, 1.5)))
    else:
        tip_sat = base_sat * g.value("space.palette.tipSaturation", (0.45, 1.1))
        tip_bri = base_bri * g.value("space.palette.tipBrightness", (1.0, 1.35))

    petal_base = hsb(wrapped(base_hue), clamp(base_sat, 0.0, 1.0), clamp(base_bri * 0.82, 0.0, 1.0))
    petal_tip = hsb(wrapped(tip_hue), clamp(tip_sat, 0.0, 1.0), clamp(tip_bri, 0.0, 1.0))
    petal_throat = hsb(
        wrapped(base_hue + g.signed("space.palette.throatShift") * 0.03),
        min(1.0, base_sat * g.value("space.palette.throatSaturation", (0.9, 1.5)) + 0.1),
        clamp(base_bri * g.value("space.palette.throatBrightness", (0.5, 0.95)), 0.0, 1.0))
    petal_vein = hsb(
        wrapped(base_hue + g.signed("space.palette.veinShift") * 0.02),
        min(1.0, base_sat * 1.25 + 0.08),
        clamp(base_bri * g.value("space.palette.veinBrightness", (0.35, 0.7)), 0.0, 1.0))
    veining = g.bell("space.palette.veining", (0.15, 0.75)) if g.chance("space.palette.hasVeins", 0.45) else 0.0

    leaf = hsb(
        g.value("space.palette.leafHue", p["leafHue"]),
        g.value("space.palette.leafSaturation", p["leafSaturation"]),
        g.value("space.palette.leafBrightness", p["leafBrightness"]))
    leaf_vein = hsb(
        clamp(leaf[0] + g.signed("space.palette.leafVeinShift") * 0.02, p["leafHue"][0], p["leafHue"][1]),
        min(1.0, leaf[1] * g.value("space.palette.leafVeinSaturation", (1.05, 1.45))),
        clamp(leaf[2] * g.value("space.palette.leafVeinBrightness", (0.52, 0.86)), 0.0, 1.0))
    leaf_veining = g.bell("space.palette.leafVeining", (0.25, 0.9)) \
        if g.chance("space.palette.hasLeafVeins", 0.88) else 0.0
    stem = hsb(
        clamp(leaf[0] + g.signed("space.palette.stemShift") * 0.03, p["leafHue"][0], p["leafHue"][1]),
        clamp(leaf[1] * g.value("space.palette.stemSaturation", (0.6, 1.1)), 0.0, 1.0),
        clamp(leaf[2] * g.value("space.palette.stemBrightness", (0.62, 1.0)), 0.0, 1.0))

    centre_band = PROFILES[centre_kind]["petalHue"] if centre_kind is not None else p["petalHue"]
    centre = hsb(
        g.value("space.palette.centreHue", centre_band),
        g.value("space.palette.centreSaturation", (0.35, 0.7)),
        g.value("space.palette.centreBrightness", (0.85, 1.0)))

    t["palette.scheme"] = scheme
    t["palette.petalBase"] = petal_base
    t["palette.petalTip"] = petal_tip
    t["palette.petalThroat"] = petal_throat
    t["palette.petalVein"] = petal_vein
    t["palette.veining"] = veining
    t["palette.marbleSeed"] = "%016x" % space_u64(g.key, "space.palette.marbleSeed")
    t["palette.leaf"] = leaf
    t["palette.leafVein"] = leaf_vein
    t["palette.leafVeining"] = leaf_veining
    t["palette.leafQuilting"] = g.bell("space.palette.leafQuilting", (0.05, 0.5))
    t["palette.stem"] = stem
    t["palette.centre"] = centre
    t["palette.glow"] = g.bell("space.palette.glow", p["glow"])
    t["palette.sheen"] = g.value("space.palette.sheen", (0.05, 0.65))
    t["palette.speckleSeed"] = "%016x" % space_u64(g.key, "space.palette.speckleSeed")
    return t


# ------------------------------------------------------------------- drawing

def draw(r: bytes):
    """The plant `r` grows: its kind and traits. `r` may be `r || mark`."""
    g = Genes(r)
    kind = kind_of(g.key)
    return {"kind": kind, "traits": grow(kind, g, None)}


def draw_cross(parent_a: bytes, parent_b: bytes, child: bytes):
    """A Zone C cross: parents sorted on their whole seeds, as Pollination sorts them."""
    first, second = sorted([parent_a, parent_b])
    g = Genes(child, parents=(first, second))
    kinds = (kind_of(first), kind_of(second))
    kind, how = inherited_kind(g, kinds)
    centre = kinds[0] if kinds[0] != kind else (kinds[1] if kinds[1] != kind else None)
    return {"kind": kind, "kindFrom": how, "centreKind": centre, "traits": grow(kind, g, centre)}


# ------------------------------------------------------------------- vectors

def sha(label: str) -> bytes:
    return hashlib.sha256(label.encode("utf-8")).digest()


def vector_r(index: int) -> bytes:
    return sha("peace-garden-space-vector-r-%d" % index)[:KEY_LENGTH]


def vector_mark(index: int) -> bytes:
    return sha("peace-garden-space-vector-mark-%d" % index)[:KEY_LENGTH]


def vector_own(index: int) -> bytes:
    return sha("peace-garden-space-vector-own-%d" % index)


def vector_nonce(index: int) -> bytes:
    return sha("peace-garden-space-vector-nonce-%d" % index)[:KEY_LENGTH]


def draw_vectors():
    """Three plants of every kind, found by walking a fixed series: kinds in the
    enum's order, and within a kind the order the series reached them."""
    found = {kind: [] for kind in KINDS}
    index = 0
    while any(len(found[kind]) < 3 for kind in KINDS):
        kind = kind_of(vector_r(index))
        if len(found[kind]) < 3:
            found[kind].append(index)
        index += 1
        assert index < 5000, "a kind could not be reached"
    rows = []
    for kind in KINDS:
        for i in found[kind]:
            r = vector_r(i)
            drawn = draw(r)
            rows.append({"series": i, "r": r.hex(), "kind": drawn["kind"], "traits": drawn["traits"]})
    return rows


def cross_vectors():
    """Crosses chosen to cover what the kind ladder can do: a child of its first
    parent's kind, of its second's, by the coin, and by a draw of its own, with
    parents of one kind and of two. The series is walked and the first of each
    class kept."""
    wanted = [
        ("first parent", True), ("first parent", False),
        ("second parent", True), ("second parent", False),
        ("coin", True), ("coin", False),
        ("mutation", True), ("mutation", False),
    ]
    chosen = {}
    index = 0
    while len(chosen) < len(wanted):
        r = vector_r(1000 + index)
        mark = vector_mark(index)
        own = vector_own(index)
        found_seed = r + mark
        nonce = vector_nonce(index)
        # The same inputs as CrossPollinationResult: the finder's phone holds
        # (own, found, nonce, r); the sender's holds (found, own, r, nonce).
        enc = dr.encounter_id(own, found_seed, nonce, r)
        child = dr.cross(own, found_seed, enc)
        cross = draw_cross(own, found_seed, child)
        same_kind = kind_of(own) == kind_of(found_seed)
        key = (cross["kindFrom"], same_kind)
        if key in wanted and key not in chosen:
            chosen[key] = (index, r, mark, own, nonce, enc, child, cross)
        index += 1
        assert index < 20000, "a class of cross could not be reached"
    rows = []
    for key in wanted:
        index, r, mark, own, nonce, enc, child, cross = chosen[key]
        rows.append({
            "series": index,
            "found": (r + mark).hex(),
            "own": own.hex(),
            "ownNonce": nonce.hex(),
            "encounter": enc.hex(),
            "child": child.hex(),
            "checksum": dr.checksum(child).hex(),
            "ownKind": kind_of(own),
            "foundKind": kind_of(r + mark),
            "kind": cross["kind"],
            "kindFrom": cross["kindFrom"],
            "centreKind": cross["centreKind"],
            "traits": cross["traits"],
        })
    return rows


def document():
    return {
        "note": (
            "Generated by tools/reference/space_flora_reference.py --write. The Python is the "
            "source; Packages/SeedCore/Tests/SeedCoreTests/SpaceFloraVectorTests.swift holds "
            "SeedCore to this file on macOS, Linux and WebAssembly, and Autonaut holds itself "
            "to it. A draw is `kind` and `traits` from the 16 bytes `r` alone, named as "
            "SeedCore names a Genome's fields. A cross is the Zone C cross: `found` is "
            "r || mark, `own` the finder's own Zone C seed, `ownNonce` the nonce the finder's "
            "phone drew, and r is the found seed's nonce; encounter, child and checksum are "
            "derivation_reference.py's. Numbers are doubles and match to 1e-12; counts, names "
            "and hex are exact."
        ),
        "domain": DOMAIN,
        "kinds": [{"kind": kind, **KIND_DATA[kind]} for kind in KINDS],
        "draws": draw_vectors(),
        "crosses": cross_vectors(),
    }


def render(doc) -> str:
    return json.dumps(doc, indent=1, ensure_ascii=True) + "\n"


# ---------------------------------------------------------------- invariants

def check_invariants():
    # Every kind reachable, and none much commoner than a fifth.
    counts = {kind: 0 for kind in KINDS}
    for i in range(2000):
        counts[kind_of(vector_r(i))] += 1
    assert all(counts[k] > 300 for k in KINDS), counts

    # A draw from r || mark is a draw from r.
    for i in range(50):
        r = vector_r(i)
        assert draw(r) == draw(r + vector_mark(i)) == draw(r + bytes(16)), i

    # A cross is commutative, whoever holds which seed.
    for i in range(200):
        a, b = vector_own(i), vector_r(i) + vector_mark(i)
        nonce_a, nonce_b = vector_nonce(i), vector_r(i)
        enc_ab = dr.encounter_id(a, b, nonce_a, nonce_b)
        enc_ba = dr.encounter_id(b, a, nonce_b, nonce_a)
        assert enc_ab == enc_ba
        child = dr.cross(a, b, enc_ab)
        assert child == dr.cross(b, a, enc_ba)
        assert draw_cross(a, b, child) == draw_cross(b, a, child), i

    # The kind ladder: a parent's kind 47% each, a draw of its own 6%.
    total = first = second = coin = mutation = 0
    other = 0
    for i in range(6000):
        g = Genes(sha("ladder-%d" % i), parents=(vector_r(i), vector_r(i + 1)))
        kinds = (kind_of(vector_r(i)), kind_of(vector_r(i + 1)))
        kind, how = inherited_kind(g, kinds)
        total += 1
        first += how == "first parent"
        second += how == "second parent"
        coin += how == "coin"
        mutation += how == "mutation"
        other += kind not in kinds
    assert abs(first / total - 0.36) < 0.03 and abs(second / total - 0.36) < 0.03
    assert abs(coin / total - 0.22) < 0.03 and abs(mutation / total - 0.06) < 0.02
    # And a cross of two kinds reaches every kind, by the draw of its own.
    reached = set()
    for i in range(3000):
        g = Genes(sha("reach-%d" % i), parents=(vector_r(0), vector_r(1)))
        reached.add(inherited_kind(g, ("cluster", "cluster"))[0])
    assert reached == set(KINDS), reached
    return counts


def main(argv):
    doc = document()
    text = render(doc)
    if "--write" in argv:
        with open(VECTORS, "w", encoding="utf-8") as handle:
            handle.write(text)
        print("wrote", VECTORS)
        return 0

    counts = check_invariants()
    print("kinds drawn from 2000 seeds:", counts)
    with open(VECTORS, encoding="utf-8") as handle:
        committed = handle.read()
    if committed != text:
        print("tools/reference/space_flora_vectors.json is not what this computes; "
              "run with --write to rewrite it", file=sys.stderr)
        return 1
    print("space flora reference: ok (%d draws, %d crosses)" % (len(doc["draws"]), len(doc["crosses"])))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
