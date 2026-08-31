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
"""

import math
import sys
from pathlib import Path

import numpy as np

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


def wrapped_unit(value):
    value = math.fmod(value, 1.0)
    return value + 1.0 if value < 0 else value


# ---------------------------------------------------------------- archetypes

ARCHETYPES = ["spire", "umbel", "fern", "orchid", "lotus", "thistle",
              "vine", "bell", "star", "poppy", "succulent", "plume"]

DEFAULT_PROFILE = dict(
    heightScale=1.0, stemThickness=1.0, nodeScale=1.0, leafLengthScale=1.0,
    leafWidthScale=1.0, leafDroop=1.0, petalCountScale=1.0, petalLengthScale=1.0,
    petalWidthScale=1.0, petalCurlBias=0.0, headPitchBias=0.0, centreScale=1.0,
    bloomsAtNodes=False, bloomPresence=1.0, swayScale=1.0,
)

PROFILE_OVERRIDES = {
    "spire": dict(heightScale=1.35, nodeScale=1.6, petalLengthScale=0.55,
                  petalCountScale=0.7, bloomsAtNodes=True, leafLengthScale=0.8),
    "umbel": dict(heightScale=1.1, petalLengthScale=0.45, petalCountScale=1.4,
                  centreScale=0.6, bloomsAtNodes=True, leafDroop=1.2),
    "fern": dict(heightScale=0.8, nodeScale=1.9, leafLengthScale=1.5, leafWidthScale=0.7,
                 leafDroop=1.5, bloomPresence=0.05, swayScale=1.3),
    "orchid": dict(heightScale=1.0, stemThickness=0.8, nodeScale=0.6, petalCountScale=0.35,
                   petalLengthScale=1.5, petalWidthScale=1.3, petalCurlBias=0.25,
                   headPitchBias=0.5, leafLengthScale=1.2),
    "lotus": dict(heightScale=0.85, stemThickness=1.4, petalLengthScale=1.4,
                  petalWidthScale=1.5, petalCurlBias=-0.55, centreScale=1.7, nodeScale=0.5),
    "thistle": dict(heightScale=1.15, stemThickness=1.2, petalCountScale=2.2,
                    petalLengthScale=0.4, petalWidthScale=0.3, petalCurlBias=-0.3,
                    centreScale=1.3),
    "vine": dict(heightScale=1.45, stemThickness=0.6, nodeScale=1.7, leafLengthScale=0.65,
                 leafWidthScale=1.1, swayScale=1.8, bloomsAtNodes=True, petalLengthScale=0.5),
    "bell": dict(petalCurlBias=-0.75, petalLengthScale=1.1, headPitchBias=1.0,
                 petalCountScale=0.55, bloomsAtNodes=True),
    "star": dict(petalCurlBias=0.35, petalWidthScale=0.6, centreScale=0.7, petalCountScale=0.9),
    "poppy": dict(nodeScale=0.35, leafLengthScale=0.7, petalCountScale=0.3,
                  petalLengthScale=1.6, petalWidthScale=1.6, petalCurlBias=-0.35,
                  headPitchBias=0.35, swayScale=1.4),
    "succulent": dict(heightScale=0.45, stemThickness=1.9, nodeScale=2.1, leafLengthScale=0.55,
                      leafWidthScale=1.6, leafDroop=0.3, petalLengthScale=0.5, bloomPresence=0.6),
    "plume": dict(heightScale=1.25, nodeScale=1.8, petalCountScale=1.8, petalLengthScale=0.35,
                  petalWidthScale=0.35, leafLengthScale=0.6, leafWidthScale=0.4, bloomsAtNodes=True),
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

        self.symmetry = source.integer("form.symmetry", 3, 9)
        self.vigour = source.bell("form.vigour", 0.82, 1.22)

        self.height = source.value("stem.height", 0.55, 1.25) * profile["heightScale"] * self.vigour
        self.baseRadius = source.value("stem.baseRadius", 0.008, 0.019) * profile["stemThickness"]
        self.taper = source.value("stem.taper", 0.28, 0.72)
        self.lean = source.signed("stem.lean") * 0.55
        self.sway = source.bell("stem.sway", 0, 1) * profile["swayScale"]
        self.twist = source.signed("stem.twist") * 0.7
        self.nodeCount = max(1, round(source.integer("stem.nodeCount", 2, 7) * profile["nodeScale"]))
        self.sides = source.integer("stem.sides", 6, 9)

        self.leavesPerNode = source.integer("foliage.leavesPerNode", 1, 3)
        self.leafLength = source.value("foliage.length", 0.09, 0.26) * profile["leafLengthScale"] * self.vigour
        self.leafWidthRatio = source.value("foliage.widthRatio", 0.22, 0.78) * profile["leafWidthScale"]
        self.leafDroop = source.bell("foliage.droop", 0, 1) * profile["leafDroop"]
        self.leafFold = source.value("foliage.fold", 0.05, 0.55)
        self.leafPitch = source.value("foliage.pitch", 0.35, 1.25)
        self.divergence = 2.399963 + source.signed("foliage.divergence") * 0.22
        self.serration = source.bell("foliage.serration", 0, 1)
        self.teeth = source.integer("foliage.teeth", 5, 17)
        self.veinCount = source.integer("foliage.veinCount", 3, 9)
        self.veinDepth = source.bell("foliage.veinDepth", 0.2, 1.0) if source.chance("foliage.hasVeins", 0.72) else 0.0
        self.leafTipSharpness = source.value("foliage.tipSharpness", 0.7, 2.1)

        petal_base = source.integer("bloom.petalCount", 3, 13)
        self.petalCount = max(3, round(petal_base * profile["petalCountScale"]))
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
        self.bloomPresent = source.unit("bloom.present") < profile["bloomPresence"]

        self.palette = derive_palette(source, seed)
        self.glow = self.palette["glow"]
        self.sheen = self.palette["sheen"]

        self.germinationHours = source.value("tempo.germinationHours", 3, 20)
        self.seedlingDays = source.value("tempo.seedlingDays", 0.6, 2.4)
        self.vegetativeDays = source.value("tempo.vegetativeDays", 2.0, 7.0)
        self.buddingDays = source.value("tempo.buddingDays", 1.0, 4.0)
        self.bloomDays = source.value("tempo.bloomDays", 3.0, 12.0)
        self.opensByDay = source.chance("tempo.opensByDay", 0.7)

        self.name = plant_name(source)

    @property
    def leafCount(self):
        return self.nodeCount * self.leavesPerNode

    @property
    def daysToBloom(self):
        return self.germinationHours / 24.0 + self.seedlingDays + self.vegetativeDays + self.buddingDays


GENUS_HEADS = ["Ael", "Aur", "Bel", "Cal", "Cer", "Cyn", "Dros", "El", "Fen", "Hal",
               "Ith", "Lir", "Mel", "Nyx", "Ol", "Pell", "Quin", "Ros", "Sel", "Thal",
               "Umbr", "Ver", "Wyn", "Zeph"]
GENUS_MIDDLES = ["a", "an", "ar", "er", "i", "in", "is", "o", "or", "yr", "ell", "ess", "ol", "un"]
GENUS_TAILS = ["ia", "is", "a", "ea", "ina", "ora", "yne", "era", "ula", "ynth"]
EPITHET_HEADS = ["noct", "vesper", "lum", "umbr", "sol", "aur", "glaci", "pluvi", "stell",
                 "sylv", "mont", "riv", "cine", "ferr", "pall", "seren", "tacit", "viv"]
EPITHET_TAILS = ["urna", "alis", "ata", "ifolia", "escens", "iflora", "ina", "icola",
                 "antha", "aria", "osa", "ula"]

VOWELS = set("aeiouyAEIOUY")


def _join(parts):
    result = ""
    for part in parts:
        if not part:
            continue
        if result and result[-1] in VOWELS and part[0] in VOWELS:
            result = result[:-1]
        result += part
    return result


def plant_name(source):
    head = source.pick("name.genusHead", GENUS_HEADS)
    middle = source.pick("name.genusMiddle", GENUS_MIDDLES) if source.chance("name.hasMiddle", 0.45) else ""
    tail = source.pick("name.genusTail", GENUS_TAILS)
    genus = _join([head, middle, tail])
    epithet = _join([source.pick("name.epithetHead", EPITHET_HEADS),
                     source.pick("name.epithetTail", EPITHET_TAILS)]).lower()
    return f"{genus} {epithet}"


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

    return dict(stage=stage, stageProgress=stage_progress, overall=overall,
                heightScale=max(0.055, height), leafUnfurl=leaf_unfurl,
                budSwell=bud_swell, bloomOpen=bloom_open, age=age)


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
            index = min(len(path) - 1, int(round(v * (len(path) - 1))))
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


def build_skeleton(genome, height_scale, segments=28):
    length = max(0.01, genome.height * height_scale)
    step = length / segments
    lean_per_step = genome.lean * 0.9 / segments
    sway_amplitude = genome.sway * 0.8

    base_radius = genome.baseRadius * (0.4 + 0.6 * height_scale)
    positions = [np.zeros(3)]
    radii = [base_radius]
    direction = np.array([0.0, 1.0, 0.0])
    position = np.zeros(3)

    for index in range(1, segments + 1):
        t = index / segments
        direction = rotate_axis(direction, np.array([0.0, 0.0, 1.0]), lean_per_step * (0.6 + 0.8 * t))
        direction = rotate_axis(direction, np.array([1.0, 0.0, 0.0]),
                                sway_amplitude * math.cos(t * math.pi * 2.2) / segments)
        direction = normalize(direction)
        position = position + direction * step
        positions.append(position)
        radii.append(base_radius * (1 - (1 - genome.taper) * t))

    samples = transport_frames(positions, radii, genome.twist)
    nodes = []
    for index in range(genome.nodeCount):
        fraction = 0.55 if genome.nodeCount == 1 else 0.16 + 0.74 * index / (genome.nodeCount - 1)
        nodes.append(samples[min(len(samples) - 1, int(round(fraction * (len(samples) - 1))))])
    return dict(stem=samples, nodes=nodes, apex=samples[-1])


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
    total = genome.leafCount
    if total <= 0 or growth["leafUnfurl"] <= 0:
        return
    opened = total * growth["leafUnfurl"]
    vigour = 0.45 + 0.55 * growth["heightScale"]

    for index in range(total):
        progress = opened - index
        if progress <= 0:
            break
        openness = min(1.0, progress)
        node_index = index // max(1, genome.leavesPerNode)
        if node_index >= len(skeleton["nodes"]):
            break
        node = skeleton["nodes"][node_index]

        jitter = SplitMix64(genome.seed, f"leaf.{index}")
        azimuth = genome.divergence * index + jitter.value(-0.12, 0.12)
        scale = openness * vigour * jitter.value(0.86, 1.14)
        length = genome.leafLength * scale
        if length <= 0.001:
            continue

        axis = node["tangent"]
        radial = normalize(node["normal"] * math.cos(azimuth) + node["binormal"] * math.sin(azimuth))
        pitch = genome.leafPitch + jitter.value(-0.1, 0.1)
        forward = normalize(radial * math.sin(pitch) + axis * math.cos(pitch))
        side = normalize(np.cross(axis, radial))
        up = normalize(np.cross(forward, side))
        origin = node["position"] + radial * node["radius"] * 0.8
        half_width = length * genome.leafWidthRatio * 0.5

        def point(u, v, origin=origin, forward=forward, up=up, side=side,
                  length=length, half_width=half_width):
            profile = blade_profile(v, genome.leafTipSharpness, genome.serration, genome.teeth)
            across = (u - 0.5) * 2 * half_width * profile
            sag = -genome.leafDroop * length * v * v * 0.8
            crease = genome.leafFold * half_width * profile * (abs(u - 0.5) * 2) ** 2
            vein = (genome.veinDepth * half_width * 0.14
                    * math.sin(v * math.pi * 2 * genome.veinCount) * (abs(u - 0.5) * 2))
            return origin + forward * (v * length) + up * (sag + crease + vein) + side * across

        builder.add_surface("leaf", 19, 9, point)


def _add_blooms(builder, genome, skeleton, growth):
    if not genome.bloomPresent or growth["budSwell"] <= 0.02:
        return
    _add_bloom(builder, genome, skeleton["apex"], 1.0, growth, 0)
    if not genome.bloomsAtNodes:
        return
    for offset, node in enumerate(skeleton["nodes"]):
        if node["t"] <= 0.35:
            continue
        lag = (1 - node["t"]) * 0.5
        local = dict(growth)
        local["budSwell"] = max(0.0, growth["budSwell"] - lag) / max(0.01, 1 - lag)
        local["bloomOpen"] = max(0.0, growth["bloomOpen"] - lag) / max(0.01, 1 - lag)
        if local["budSwell"] <= 0.02:
            continue
        _add_bloom(builder, genome, node, 0.62, local, offset + 1)


def _add_bloom(builder, genome, sample, scale, growth, index):
    jitter = SplitMix64(genome.seed, f"bloom.{index}")
    nod_axis = normalize(np.cross(sample["tangent"], sample["normal"]))
    axis = normalize(rotate_axis(sample["tangent"], nod_axis, genome.headPitch))
    ref_a = arbitrary_perpendicular(axis)
    ref_b = normalize(np.cross(axis, ref_a))

    bud_scale = 0.4 + 0.6 * growth["budSwell"]
    petal_length = genome.petalLength * scale * bud_scale
    if petal_length <= 0.002:
        return

    closed_angle = 0.08
    open_angle = 1.05 + genome.curl * 0.35
    openness = closed_angle + (open_angle - closed_angle) * growth["bloomOpen"]
    origin = sample["position"] + axis * petal_length * 0.08
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
                       petal_length * layer_scale * petal_jitter.value(0.92, 1.08),
                       growth["bloomOpen"])

    centre_radius = petal_length * genome.centreRadius * 1.6
    builder.add_dome("centre", origin, axis, ref_a, centre_radius,
                     flatten=0.55 + jitter.unit() * 0.4, rows=8, columns=14)

    if growth["bloomOpen"] > 0.3 and genome.stamenCount > 0:
        _add_stamens(builder, genome, origin, axis, ref_a, ref_b, centre_radius,
                     petal_length * 0.42 * growth["bloomOpen"])

    if genome.hasPistil and growth["bloomOpen"] > 0.25:
        _add_pistil(builder, genome, origin, axis, ref_a, centre_radius,
                    petal_length * 0.55 * growth["bloomOpen"])

    if genome.sepalCount > 0:
        _add_sepals(builder, genome, sample["position"], axis, ref_a, ref_b,
                    petal_length * 0.5, petal_length * 0.2)


def _add_sepals(builder, genome, origin, axis, ref_a, ref_b, length, width):
    if length <= 0.002:
        return
    for index in range(genome.sepalCount):
        jitter = SplitMix64(genome.seed, f"sepal.{index}")
        azimuth = 2 * math.pi * index / genome.sepalCount + jitter.value(-0.1, 0.1)
        radial = normalize(ref_a * math.cos(azimuth) + ref_b * math.sin(azimuth))
        pitch = jitter.value(1.75, 2.25)
        forward = normalize(radial * math.sin(pitch) + axis * math.cos(pitch))
        side = normalize(np.cross(axis, radial))
        up = normalize(np.cross(forward, side))
        half_width = width * 0.5

        def point(u, v, origin=origin, forward=forward, up=up, side=side,
                  length=length, half_width=half_width):
            profile = blade_profile(v, 1.3, 0, 0)
            across = (u - 0.5) * 2 * half_width * profile
            curve = -0.25 * length * v * v
            return origin + forward * (v * length) + up * curve + side * across

        builder.add_surface("leaf", 7, 5, point)


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


def _add_petal(builder, genome, origin, axis, ref_a, ref_b, azimuth, openness, length, bloom_open):
    radial = normalize(ref_a * math.cos(azimuth) + ref_b * math.sin(azimuth))
    forward = normalize(radial * math.sin(openness) + axis * math.cos(openness))
    side = normalize(np.cross(axis, radial))
    up = normalize(np.cross(side, forward))
    half_width = length * genome.petalWidthRatio * 0.5
    curl = genome.curl * bloom_open - (1 - bloom_open) * 0.7

    def point(u, v):
        profile = blade_profile(v, genome.petalTipSharpness, 0, 0)
        across = (u - 0.5) * 2 * half_width * profile
        bend = curl * length * v * v * 0.75
        twist_angle = genome.bloomTwist * v
        local_side = side * math.cos(twist_angle) + up * math.sin(twist_angle)
        local_up = up * math.cos(twist_angle) - side * math.sin(twist_angle)
        cleft = genome.notch * length * 0.2 * math.exp(-((u - 0.5) * 5) ** 2) * (v ** 6)
        return origin + forward * (v * length - cleft) + local_side * across + local_up * bend

    builder.add_surface("petal", 13, 9, point)


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

    return hsb_interpolate(palette["centre"], palette["petalTip"], v)
