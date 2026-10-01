#!/usr/bin/env python3
"""Redraws worlds in the app's ground atlas, in place.

    python3 tools/worlds/worlds.py            # redraw, write, measure
    python3 tools/worlds/worlds.py --check    # say whether the atlas is what this draws

The atlas is two PNGs, 128 wide by 128 x N tall, one 128-square block per
world (`App/PeaceGarden/Resources/Worlds/`). Height is sixteen bits in the red
and green bytes, -2..+2 m, drawn for a 5.2 m plot. Albedo is plain RGB.

**The order of the blocks is the file format.** A bed stores its world's index,
so a world may be redrawn where it stands or a new one added at the end, but
nothing is ever moved or removed. `docs/ARRANGING.md` §*The ground is chosen*.

**The mockup that drew the first eight was never committed**, so this does not
regenerate the atlas: it reads it, redraws the blocks named in `REDRAWN`, and
leaves every other block's height and colour exactly as they were.

It also writes the **kind** of every cell — grass, earth, gravel, rock and so on
— into the height image's blue byte, which nothing used before. The app reads
it to decide how a cell's crumb is drawn: how widely its tone spreads, how much
it is roughened, whether it is toned per corner like a surface or per face like
a heap of stones. For the worlds drawn here the kind is known; for the mockup's
it is read back off the colour, which is good enough because the materials were
chosen to be told apart.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ATLAS = ROOT / "App/PeaceGarden/Resources/Worlds"
INDEX = ROOT / "design/worlds.json"

CELLS = 128
SIDE = 5.2
LOW, HIGH = -2.0, 2.0
STEP = SIDE / (CELLS - 1)

# Row j of a block is z, column i is x — the order `GardenWorlds.place` reads.
_axis = -SIDE / 2 + np.arange(CELLS) * STEP
X, Z = np.meshgrid(_axis, _axis)

# MARK: Kinds — must match `GardenGround.Kind` in the app.
GRASS, EARTH, GRAVEL, ROCK, SCREE, SNOW, WATER, BOX, TARMAC, SAND = range(10)

# MARK: Materials, as albedo before any light. Dark on purpose: the app's
# hemispheric light lifts a face that looks up by about a fifth.
M = {
    "grass": (0.235, 0.282, 0.188),
    "grass_dry": (0.282, 0.280, 0.190),
    "grass_wet": (0.180, 0.232, 0.180),
    "moss": (0.200, 0.250, 0.150),
    "turf": (0.300, 0.300, 0.205),
    "heather": (0.255, 0.225, 0.205),
    "bracken": (0.320, 0.262, 0.180),
    "rock_light": (0.440, 0.430, 0.400),
    "rock": (0.335, 0.330, 0.315),
    "rock_dark": (0.225, 0.225, 0.232),
    "scree": (0.385, 0.375, 0.352),
    "snow": (0.610, 0.632, 0.660),
    "earth": (0.215, 0.160, 0.118),
    "earth_dark": (0.160, 0.122, 0.094),
    "gravel": (0.415, 0.395, 0.345),
    "box": (0.140, 0.205, 0.135),
    "box_light": (0.180, 0.250, 0.160),
    "water": (0.170, 0.215, 0.235),
    "stone": (0.500, 0.480, 0.445),
    "ochre": (0.345, 0.290, 0.232),
    "grey": (0.305, 0.305, 0.312),
    "red": (0.330, 0.250, 0.205),
    "dark": (0.205, 0.205, 0.215),
    "shingle": (0.330, 0.320, 0.300),
    "shingle_wet": (0.200, 0.212, 0.200),
}
M = {k: np.array(v) for k, v in M.items()}

SATURATION_CEILING = 0.28  # `GardenGround.saturationCeiling`


def ceilinged(rgb: np.ndarray) -> np.ndarray:
    """`GardenGround.ceilinged`, over a whole block."""
    high = rgb.max(axis=-1, keepdims=True)
    low = rgb.min(axis=-1, keepdims=True)
    sat = np.where(high > 0, (high - low) / np.maximum(high, 1e-9), 0)
    keep = np.where(sat > SATURATION_CEILING, SATURATION_CEILING / np.maximum(sat, 1e-9), 1)
    grey = high * (1 - keep)
    return rgb * keep + grey


# MARK: Noise. Value noise on a seeded lattice: deterministic, so a world is
# the same world every time this runs.

def _lattice(seed: int, n: int = 256) -> np.ndarray:
    return np.random.default_rng(seed).random((n, n)) * 2 - 1


def noise(x, z, scale: float, seed: int) -> np.ndarray:
    g = _lattice(seed)
    n = g.shape[0]
    u = np.asarray(x, dtype=float) / scale + 37.0
    v = np.asarray(z, dtype=float) / scale + 53.0
    i0 = np.floor(u).astype(int)
    j0 = np.floor(v).astype(int)
    fu, fv = u - i0, v - j0
    su, sv = fu * fu * (3 - 2 * fu), fv * fv * (3 - 2 * fv)
    a = g[j0 % n, i0 % n]
    b = g[j0 % n, (i0 + 1) % n]
    c = g[(j0 + 1) % n, i0 % n]
    d = g[(j0 + 1) % n, (i0 + 1) % n]
    return (a * (1 - su) + b * su) * (1 - sv) + (c * (1 - su) + d * su) * sv


def fbm(x, z, scale: float, seed: int, octaves: int = 4, gain: float = 0.5) -> np.ndarray:
    total, weight, norm = 0.0, 1.0, 0.0
    for k in range(octaves):
        total = total + weight * noise(x, z, scale / 2 ** k, seed + 101 * k)
        norm += weight
        weight *= gain
    return total / norm


def along(t, scale: float, seed: int) -> np.ndarray:
    """Noise along one axis — a wandering line."""
    t = np.asarray(t, dtype=float)
    return fbm(t, np.full_like(t, 0.37), scale, seed, octaves=3)


def smooth(a: float, b: float, v) -> np.ndarray:
    t = np.clip((np.asarray(v, dtype=float) - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def speckle(seed: int) -> np.ndarray:
    """A number in 0..1 per cell — the stipple."""
    return np.random.default_rng(seed).random((CELLS, CELLS))


def slope_of(h: np.ndarray) -> np.ndarray:
    gz, gx = np.gradient(h, STEP)
    return np.hypot(gx, gz)


def laplacian(h: np.ndarray) -> np.ndarray:
    p = np.pad(h, 1, mode="edge")
    return (p[:-2, 1:-1] + p[2:, 1:-1] + p[1:-1, :-2] + p[1:-1, 2:] - 4 * h) / STEP ** 2


def mix(a, b, t):
    t = np.asarray(t, dtype=float)[..., None]
    return a * (1 - t) + b * t


def paint(colour: np.ndarray, where, material: np.ndarray, amount=1.0):
    w = (np.asarray(where, dtype=float) * amount)[..., None]
    return colour * (1 - w) + material * w


def boulders(seed: int, count: int, inside, radius=(0.07, 0.18), tall=0.62):
    """Rounded stones: a field of heights to add and a mask of where they are."""
    rng = np.random.default_rng(seed)
    lift = np.zeros((CELLS, CELLS))
    placed = 0
    tries = 0
    while placed < count and tries < count * 40:
        tries += 1
        x, z = rng.uniform(-2.45, 2.45, 2)
        if not inside(x, z):
            continue
        r = rng.uniform(*radius)
        # Squashed and turned, so no two are the same circle.
        angle = rng.uniform(0, np.pi)
        squash = rng.uniform(0.65, 1.0)
        dx, dz = X - x, Z - z
        a = (dx * np.cos(angle) + dz * np.sin(angle)) / r
        b = (-dx * np.sin(angle) + dz * np.cos(angle)) / (r * squash)
        d = np.hypot(a, b)
        bump = r * tall * np.sqrt(np.clip(1 - d ** 2, 0, 1)) ** 0.8
        lift = np.maximum(lift, bump)
        placed += 1
    return lift, lift > 0.008


# MARK: The worlds drawn here


def alpine():
    """Foothills climbing to a modest ridge along the far edge.

    The first alpine world was a massif in the middle of the plot, 0.97 m high,
    and a lantern stood as tall as the mountains — which read as a giant's
    lantern rather than as a small mountain. Peaking at a little over half a
    metre at the far corner, with the near half of the plot gently plantable,
    it reads as the ground climbing into rock, at the plot's own scale.
    """
    seed = 2600
    # The crest wanders along the far (-z) edge, and the rise runs in from it a
    # wandering distance, so the foot of the slope is never a ruled line.
    crest = -2.30 + 0.16 * along(X, 1.3, seed)
    reach = 2.85 + 0.45 * along(X, 1.6, seed + 1)
    t = np.clip(1 - (Z - crest) / reach, 0, 1)
    behind = np.clip((crest - Z) / 0.55, 0, 1)
    # Higher toward the far corner, lower toward the right-hand one.
    peak = 0.56 * (0.70 + 0.30 * np.clip((0.6 - X) / 3.2, 0, 1)) * (1 + 0.16 * along(X, 0.9, seed + 2))
    rise = t ** 1.9 * (1.35 - 0.35 * t)
    h = peak * rise * (1 - 0.35 * behind ** 2)

    # Foothills: broad swells that grow with the slope.
    h += 0.035 * fbm(X, Z, 1.3, seed + 3) * (0.5 + t)
    h += 0.012 * fbm(X, Z, 0.35, seed + 4)

    # Rock comes through as outcrops in bands — ledges a hand or two high, which
    # is the size a rock is in a garden, and what makes the climb read as rock.
    crags = smooth(0.05, 0.35, fbm(X, Z, 0.75, seed + 5)) * smooth(0.30, 0.62, t)
    band = 0.065
    k = (h + 0.012 * fbm(X, Z, 0.4, seed + 6)) / band
    stair = (np.floor(k) + smooth(0.55, 0.92, k - np.floor(k))) * band
    h = h + crags * (stair - h) * 0.95 + crags * 0.025

    lift, stones = boulders(seed + 7, 9, lambda x, z: z > -0.2, radius=(0.05, 0.11))
    lift2, stones2 = boulders(seed + 8, 16, lambda x, z: z < -0.6, radius=(0.07, 0.16))
    h = h + np.maximum(lift, lift2)
    stones = stones | stones2

    s = slope_of(h)
    lap = laplacian(h)
    pick = speckle(seed + 9)
    patch = fbm(X, Z, 0.9, seed + 10)
    fine = fbm(X, Z, 0.25, seed + 11)

    # Grass: lusher in the hollows and low down, a paler short turf as it
    # climbs and on anything convex.
    wet = smooth(-0.4, 1.2, lap * 0.06 + 0.3 * patch)
    colour = mix(M["grass"], M["grass_wet"], wet * (1 - t))
    colour = mix(colour, M["turf"], smooth(0.2, 0.75, t + 0.25 * fine))
    colour = paint(colour, smooth(0.15, 0.45, patch) * (fine > 0.15), M["grass_dry"], 0.6)
    colour = paint(colour, (fine < -0.30) & (t > 0.35), M["moss"], 0.8)

    # Snow lies on the high ground **and** only where it is gentle enough to
    # hold, which is what stops a snowcap looking painted on.
    # Only in patches, and dimmer than the hand would choose: it is the
    # brightest thing on the plot, and at noon a field of it outshone the plants.
    snowline = 0.45 + 0.06 * fbm(X, Z, 0.5, seed + 12) + 0.04 * X
    snow = (h > snowline) & (s < 0.40) & (patch + 0.5 * fine > 0.08)

    rock = (s > 0.85) | (crags * smooth(0.45, 0.7, s) > 0.5) | stones
    # Scree below the crags: the rock mask carried a few cells downhill (+z).
    below = np.zeros_like(rock)
    for shift in range(1, 7):
        below[shift:, :] |= rock[:-shift, :]
    scree = ~rock & (below | ((s > 0.42) & (t > 0.35))) & (fine + 0.4 * pick > 0.05) & (t > 0.15)

    strata = np.floor((h + 0.03 * X) / 0.05).astype(int) % 3
    rock_colour = np.where((strata == 0)[..., None], M["rock"],
                           np.where((strata == 1)[..., None], M["rock_light"], M["rock_dark"]))
    rock_colour = rock_colour * (0.88 + 0.24 * pick)[..., None]
    colour = np.where(scree[..., None], M["scree"] * (0.82 + 0.36 * pick)[..., None], colour)
    colour = np.where(rock[..., None], rock_colour, colour)
    colour = np.where(snow[..., None], M["snow"] * (0.96 + 0.06 * pick)[..., None], colour)

    kind = np.full((CELLS, CELLS), GRASS, dtype=np.uint8)
    kind[scree] = SCREE
    kind[rock] = ROCK
    kind[snow] = SNOW
    return h, colour, kind


def ravine():
    """A gorge that starts as a crack and opens as it runs.

    It begins nearly closed at the middle of the far-right edge and widens as
    it comes toward the viewer, to leave through the near-left edge, so the cut
    under the plot shows its notch. Its walls wander in and out independently,
    step in ledges of strata, and leave most of the plot as ground either side.
    """
    seed = 4400
    s = np.clip((Z + SIDE / 2) / SIDE, 0, 1)  # 0 at the closed end, 1 where it opens
    # fbm along a line rarely leaves ±0.4, so these amplitudes are about
    # double what they wander by.
    centre = 0.80 * along(Z, 1.7, seed) + 0.22 * along(Z, 0.55, seed + 1)
    open_ = s ** 1.15
    top = 0.06 + 1.18 * open_  # half-width at the lip
    left = top * (1 + 0.65 * along(Z, 0.85, seed + 2)) + (0.08 + 0.22 * s) * along(Z, 0.28, seed + 3)
    right = top * (1 + 0.65 * along(Z, 0.85, seed + 4)) + (0.08 + 0.22 * s) * along(Z, 0.28, seed + 5)
    left = np.maximum(left, 0.035)
    right = np.maximum(right, 0.035)
    depth = 0.10 + 0.56 * smooth(0.0, 0.62, s)
    floor = 0.10 + 0.32 * s

    dx = X - centre
    half = np.where(dx < 0, left, right)
    q = np.abs(dx) / half

    # The ground either side: gently rolling, falling a little toward the lip.
    ground = 0.045 * fbm(X, Z, 1.2, seed + 6) + 0.015 * fbm(X, Z, 0.4, seed + 7)
    ground += 0.06 * smooth(1.0, 3.5, q) - 0.03

    g = np.clip((q - floor) / (1 - floor), 0, 1)
    rise = 1 - (1 - g) ** 1.6
    rise = np.clip(rise + 0.05 * fbm(X, Z, 0.25, seed + 8) * (g > 0) * (g < 1), 0, 1)
    h = ground - depth * (1 - rise)

    # Strata: the wall steps in ledges at the same heights all along the gorge,
    # with a slight dip, which is what makes it read as bedded rock.
    wall = (g > 0) & (g < 1)
    band = 0.085
    tilt = 0.035 * X + 0.02 * Z
    k = (h - tilt) / band
    stair = (np.floor(k) + smooth(0.45, 0.95, k - np.floor(k))) * band + tilt
    h = np.where(wall, h + (stair - h) * 0.85, h)

    # The floor: shingle, a damp runnel down its lowest line, and stones.
    run = np.abs(dx - 0.06 * along(Z, 0.5, seed + 9)) < (0.035 + 0.05 * s)
    runnel = run & (q < floor) & (s > 0.18)
    h = np.where(runnel, h - 0.015, h)
    lift, stones = boulders(seed + 10, 30, lambda x, z: True, radius=(0.05, 0.13))
    on_floor = q < floor * 1.4
    h = h + np.where(on_floor, lift, 0)
    stones = stones & on_floor
    lift2, stones2 = boulders(seed + 11, 10, lambda x, z: True, radius=(0.07, 0.15))
    away = q > 1.25
    h = h + np.where(away, lift2, 0)
    stones2 = stones2 & away

    sl = slope_of(h)
    lap = laplacian(h)
    pick = speckle(seed + 12)
    patch = fbm(X, Z, 0.9, seed + 13)
    fine = fbm(X, Z, 0.25, seed + 14)

    wet = smooth(-0.5, 1.5, lap * 0.05 + 0.3 * patch)
    colour = mix(M["grass"], M["grass_wet"], wet)
    colour = paint(colour, smooth(0.10, 0.45, patch) * (fine > 0.0), M["grass_dry"], 0.6)
    # Heather and bracken on the dry shoulders by the lip.
    shoulder = (q > 1.0) & (q < 1.45 + 0.4 * fine)
    colour = paint(colour, shoulder & (fine > 0.05), M["heather"], 0.85)
    colour = paint(colour, shoulder & (fine <= 0.05) & (patch > -0.1), M["bracken"], 0.6)

    # The walls in strata by height, each band a different stone, stippled.
    rocky = wall & (sl > 0.75)
    # Bands a little thicker than a cell is tall on the wall, or the stipple
    # swallows them; and **lighter than they look right in the hand**, as the
    # cut's are, because a wall is lit by the sky and hardly by the sun.
    layer = np.floor((h - tilt) / 0.075 + 0.3 * fbm(X, Z, 0.6, seed + 15)).astype(int)
    order = [M["ochre"], M["grey"], M["red"], M["ochre"], M["dark"], M["grey"], M["red"]]
    strata = np.zeros((CELLS, CELLS, 3))
    for n, material in enumerate(order):
        strata[(layer % len(order)) == n] = material * 1.3
    strata = strata * (0.92 + 0.16 * pick)[..., None]
    colour = np.where(rocky[..., None], strata, colour)
    # Ledges hold soil, so they are green: moss and fern on every shelf.
    ledge = wall & ~rocky
    colour = np.where(ledge[..., None], mix(M["moss"], M["grass_wet"], pick), colour)

    floor_cells = (q <= floor) | (on_floor & ~wall)
    shingle = M["shingle"] * (0.80 + 0.40 * pick)[..., None]
    colour = np.where(floor_cells[..., None], mix(shingle, M["moss"], (patch > 0.25) * 0.7), colour)
    colour = np.where(runnel[..., None], M["shingle_wet"] * (0.85 + 0.3 * pick)[..., None], colour)
    rock_stone = M["rock"] * (0.85 + 0.35 * pick)[..., None]
    colour = np.where((stones | stones2)[..., None], rock_stone, colour)

    kind = np.full((CELLS, CELLS), GRASS, dtype=np.uint8)
    kind[floor_cells & ~(patch > 0.25)] = SCREE
    kind[runnel] = SCREE
    kind[rocky] = ROCK
    kind[stones | stones2] = ROCK
    return h, colour, kind


def parterre():
    """A formal garden drawn large enough to read at the plot's scale.

    The first parterre was twenty-five domed compartments ten centimetres high,
    which at a plot five metres across drew as the scales of a lizard. This one
    is four: a gravel cross and a gravel round, a basin in the middle with a
    stone kerb, four box balls on the round, and each compartment edged in box
    a hand and a half high and filled with dug earth for planting. Regular,
    because cultivation may be — but every edge wanders by a centimetre or two,
    because no edge in the garden is ruled.
    """
    seed = 7700
    wob = lambda scale, n, amount: amount * fbm(X, Z, scale, seed + n)  # noqa: E731
    ax, az = np.abs(X), np.abs(Z)
    r = np.hypot(X, Z)

    # Signed distance to each compartment: a rounded square in its quarter,
    # with its inner corner taken out by the gravel round.
    lo, hi, corner = 0.31, 2.02, 0.16
    c = (lo + hi) / 2
    e = (hi - lo) / 2 - corner
    qx, qz = np.abs(ax - c) - e, np.abs(az - c) - e
    rect = np.hypot(np.maximum(qx, 0), np.maximum(qz, 0)) + np.minimum(np.maximum(qx, qz), 0) - corner
    round_ = 1.06 + wob(0.4, 1, 0.012)
    sd = np.maximum(rect, round_ - r) + wob(0.22, 2, 0.013)

    hedge_width = 0.23
    hedge = (sd < 0) & (sd > -hedge_width)
    bed = sd <= -hedge_width
    outside = sd >= 0

    kerb_in, kerb_out = 0.56, 0.68
    basin = r < kerb_in + wob(0.3, 3, 0.006)
    kerb = ~basin & (r < kerb_out + wob(0.3, 4, 0.006))

    edge_path = np.maximum(ax, az) > 2.40 + wob(0.5, 5, 0.03)

    pick = speckle(seed + 6)
    fine = fbm(X, Z, 0.3, seed + 7)

    h = np.zeros((CELLS, CELLS))
    # Gravel, raked: a few millimetres of wander.
    h += 0.004 * fbm(X, Z, 0.2, seed + 8)
    # The beds are dug and mounded a little toward their middles.
    h = np.where(bed, 0.025 + 0.035 * smooth(-hedge_width, -0.55, sd) + 0.008 * fine, h)
    # Box: a rounded clipped top over steep sides, its height wandering.
    u = np.clip((sd + hedge_width / 2) / (hedge_width / 2), -1, 1)
    tall = 0.20 * (1 + 0.10 * fbm(X, Z, 0.35, seed + 9)) + 0.012 * fbm(X, Z, 0.08, seed + 10)
    h = np.where(hedge, tall * np.sqrt(np.clip(1 - u ** 4, 0, 1)), h)
    # The kerb stands a little proud; the water sits just under the gravel.
    h = np.where(kerb, 0.075 + 0.004 * pick, h)
    h = np.where(basin, -0.035, h)
    # Four box balls on the round, on the diagonals.
    for angle in (np.pi / 4, 3 * np.pi / 4, 5 * np.pi / 4, 7 * np.pi / 4):
        bx, bz = 0.875 * np.cos(angle), 0.875 * np.sin(angle)
        d = np.hypot(X - bx, Z - bz) / (0.165 + wob(0.12, 11, 0.012))
        ball = d < 1
        h = np.where(ball, np.maximum(h, 0.34 * np.sqrt(np.clip(1 - d ** 2, 0, 1)) ** 0.9), h)
        hedge = hedge | ball
        bed = bed & ~ball
    # A lawn margin outside the gravel walk, at the rim.
    h = np.where(edge_path & outside, 0.012 + 0.008 * fine, h)

    gravel = M["gravel"] * (0.86 + 0.28 * pick)[..., None]
    colour = np.broadcast_to(gravel, (CELLS, CELLS, 3)).copy()
    lawn = mix(M["grass"], M["grass_dry"], smooth(-0.2, 0.5, fine))
    colour = np.where((edge_path & outside)[..., None], lawn, colour)
    earth = mix(M["earth"], M["earth_dark"], smooth(-0.3, 0.6, fine + 0.6 * (pick - 0.5)))
    colour = np.where(bed[..., None], earth, colour)
    # Box: darker toward its foot, lighter where the new growth is on top.
    top = smooth(0.08, 0.20, h)
    box = mix(M["box"], M["box_light"], top * (0.6 + 0.4 * pick))
    colour = np.where(hedge[..., None], box, colour)
    colour = np.where(kerb[..., None], M["stone"] * (0.92 + 0.12 * pick)[..., None], colour)
    colour = np.where(basin[..., None], M["water"] * (0.97 + 0.04 * pick)[..., None], colour)

    kind = np.full((CELLS, CELLS), GRAVEL, dtype=np.uint8)
    kind[edge_path & outside] = GRASS
    kind[bed] = EARTH
    kind[hedge] = BOX
    kind[kerb] = ROCK
    kind[basin] = WATER
    return h, colour, kind


REDRAWN = {2: alpine, 4: ravine, 7: parterre}


# MARK: Kinds for the mockup's worlds, read back off their colour.

def classify(world: int, h: np.ndarray, rgb: np.ndarray) -> np.ndarray:
    r, g, b = (rgb[..., n].astype(int) for n in range(3))
    high = np.maximum(np.maximum(r, g), b)
    low = np.minimum(np.minimum(r, g), b)
    total = r + g + b
    s = slope_of(h)

    kind = np.full(h.shape, GRASS, dtype=np.uint8)
    neutral = (high - low) < 16
    brown = (r > g + 6) & (r - b > 14)
    kind[brown] = EARTH
    kind[neutral & (s > 0.6)] = ROCK
    kind[neutral & (total > 215) & (s <= 0.6)] = GRAVEL
    if world == 3:  # the lake: water lies at the lake's own level
        kind[h <= h.min() + 0.0015] = WATER
    if world == 5:  # the verge: a strip of road
        kind[neutral & (total < 140)] = TARMAC
    return kind


# MARK: The file


def read_atlas():
    hp = np.array(Image.open(ATLAS / "worlds-height.png").convert("RGB")).astype(np.int64)
    ap = np.array(Image.open(ATLAS / "worlds-albedo.png").convert("RGB")).astype(np.uint8)
    return hp, ap


def decode(hp: np.ndarray) -> np.ndarray:
    return LOW + ((hp[..., 0] << 8) | hp[..., 1]) / 65535 * (HIGH - LOW)


def draw(hp: np.ndarray, ap: np.ndarray):
    hp, ap = hp.copy(), ap.copy()
    worlds = hp.shape[0] // CELLS
    measured = {}
    for w in range(worlds):
        rows = slice(w * CELLS, (w + 1) * CELLS)
        if w in REDRAWN:
            h, colour, kind = REDRAWN[w]()
            packed = np.clip(np.round((h - LOW) / (HIGH - LOW) * 65535), 0, 65535).astype(np.int64)
            hp[rows, :, 0] = packed >> 8
            hp[rows, :, 1] = packed & 0xFF
            ap[rows] = np.clip(np.round(ceilinged(np.clip(colour, 0, 1)) * 255), 0, 255).astype(np.uint8)
        else:
            kind = classify(w, decode(hp[rows]), ap[rows])
        hp[rows, :, 2] = kind
        block = decode(hp[rows])
        measured[w] = (float(block.min()), float(block.max()))
    return hp, ap, measured


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--out", type=Path, help="write the atlas here instead, to look at first")
    args = parser.parse_args()

    hp, ap = read_atlas()
    new_h, new_a, measured = draw(hp, ap)

    if args.check:
        same = np.array_equal(new_h, hp) and np.array_equal(new_a, ap)
        print("the atlas is what this draws" if same else "the atlas differs from what this draws")
        raise SystemExit(0 if same else 1)

    out = args.out or ATLAS
    out.mkdir(parents=True, exist_ok=True)
    Image.fromarray(new_h.astype(np.uint8), "RGB").save(out / "worlds-height.png", optimize=True)
    Image.fromarray(new_a, "RGB").save(out / "worlds-albedo.png", optimize=True)
    for w, (low, high) in measured.items():
        print(f"world {w}: {low:+.4f} .. {high:+.4f}")
    if args.out:
        return

    index = json.loads(INDEX.read_text())
    for world in index["worlds"]:
        low, high = measured[world["row"]]
        world["min"], world["max"] = round(low, 3), round(high, 3)
    INDEX.write_text(json.dumps(index, indent=2) + "\n")


if __name__ == "__main__":
    main()
