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
        self.bloomsAtNodes = profile["bloomsAtNodes"]
        self.bloomPresent = source.unit("bloom.present") < profile["bloomPresence"]

        petal_hue = source.unit("palette.petalHue")
        hue_shift = source.signed("palette.petalTipShift") * 0.09
        petal_saturation = source.value("palette.petalSaturation", 0.15, 0.95)
        petal_brightness = source.value("palette.petalBrightness", 0.55, 1.0)
        leaf_hue = 0.22 + source.unit("palette.leafHue") * 0.16
        self.palette = dict(
            petalBase=(petal_hue, petal_saturation, petal_brightness * 0.82),
            petalTip=(wrapped_unit(petal_hue + hue_shift),
                      clamp(petal_saturation * source.value("palette.tipSaturation", 0.45, 1.15), 0, 1),
                      min(1.0, petal_brightness * source.value("palette.tipBrightness", 0.95, 1.35))),
            leaf=(leaf_hue,
                  source.value("palette.leafSaturation", 0.34, 0.82),
                  source.value("palette.leafBrightness", 0.34, 0.72)),
            stem=(wrapped_unit(leaf_hue + source.signed("palette.stemShift") * 0.05),
                  source.value("palette.stemSaturation", 0.2, 0.7),
                  source.value("palette.stemBrightness", 0.24, 0.54)),
            centre=(source.unit("palette.centreHue"),
                    source.value("palette.centreSaturation", 0.3, 1.0),
                    source.value("palette.centreBrightness", 0.6, 1.0)),
        )
        self.glow = source.bell("palette.glow", 0, 1)
        self.sheen = source.value("palette.sheen", 0.05, 0.65)

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
                heightScale=max(0.02, height), leafUnfurl=leaf_unfurl,
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


def blade_profile(s, sharpness, serration, ripples):
    base = math.sin(math.pi * (clamp(s, 0, 1) ** 0.7))
    shaped = max(0.0, base) ** max(0.3, sharpness)
    if serration <= 0 or ripples <= 0:
        return shaped
    return shaped * (1 + serration * 0.1 * math.sin(s * math.pi * ripples))


def build_mesh(genome, growth):
    """Mirror of SeedCore/Morphology/PlantBuilder.swift."""
    builder = MeshBuilder()
    skeleton = build_skeleton(genome, growth["heightScale"])
    builder.add_tube("stem", skeleton["stem"], genome.sides)

    husk = clamp((0.25 - growth["heightScale"]) / 0.23, 0, 1)
    if husk > 0.01:
        builder.add_dome("stem", np.array([0.0, genome.baseRadius * 0.4, 0.0]),
                         np.array([0.0, 1.0, 0.0]), np.array([1.0, 0.0, 0.0]),
                         genome.baseRadius * 2.4 * husk, flatten=0.8, rows=8, columns=12)

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
            profile = blade_profile(v, genome.leafTipSharpness, genome.serration, 9)
            across = (u - 0.5) * 2 * half_width * profile
            sag = -genome.leafDroop * length * v * v * 0.8
            crease = genome.leafFold * half_width * profile * (abs(u - 0.5) * 2) ** 2
            return origin + forward * (v * length) + up * (sag + crease) + side * across

        builder.add_surface("leaf", 11, 7, point)


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
        return origin + forward * (v * length) + local_side * across + local_up * bend

    builder.add_surface("petal", 9, 7, point)


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

def ramp_colour(role, t, palette):
    def interpolate(a, b, t):
        delta = b[0] - a[0]
        if delta > 0.5:
            delta -= 1
        if delta < -0.5:
            delta += 1
        return (wrapped_unit(a[0] + delta * t),
                a[1] + (b[1] - a[1]) * t,
                a[2] + (b[2] - a[2]) * t)

    t = clamp(t, 0, 1)
    if role == "petal":
        return interpolate(palette["petalBase"], palette["petalTip"], t)
    if role == "leaf":
        leaf = palette["leaf"]
        return interpolate(leaf, (leaf[0], leaf[1], min(1, leaf[2] * 1.18)), t)
    if role == "stem":
        stem = palette["stem"]
        return interpolate(stem, (stem[0], stem[1], min(1, stem[2] * 1.25)), t)
    if role == "centre":
        centre = palette["centre"]
        return interpolate(centre, (centre[0], centre[1], max(0, centre[2] * 0.7)), t)
    return interpolate(palette["centre"], palette["petalTip"], t)
