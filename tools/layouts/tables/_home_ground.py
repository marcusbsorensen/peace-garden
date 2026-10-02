"""The Home Ground's lazy beds, which its four tables share. Not a table itself
(a name that starts with an underscore is not a spec).

Three beds 1.2 m wide, their middles 1.65 m apart across the plot, run its
length from z = -2.1 (north) to z = 2.1, as they always have; since 2 October
2026 they sway together in a lazy S, as hand-dug ridges follow the ground
(RESEARCH.md, option A). Rows run across the curve, square to it, so a crop's
rows still read as rows. Each crop's places are its own table, because two
crops' places can fall on one point of a bed, and a table holds a point once.
"""
import math

from places import shapes
from places.numbers import Rng

# What the rule says, written again here to lay the beds out.
BED_X = (-1.65, 0.0, 1.65)
LENGTH = 4.2
WIDTH = 1.2
# Across a row, the gap between, rows down the bed, the gap between: a crop's
# own spacing (`HomeGround.Crop.sown`).
SOWN = {'cer': (3, 0.40, 9, 0.45), 'fen': (2, 0.60, 7, 0.60), 'pell': (3, 0.38, 10, 0.40)}

# **How far the beds sway**: 0.10 m either way, a little short of a third of
# the way down from each end, and straight again at the ends and the middle.
# Measured, not chosen: the beds and paths are as wide as they were, so the
# outer beds have only the 0.13 m between their edges and the slab's to move
# in, and at 0.10 the outer edge, wandering as the page draws it, stays inside
# 2.38 m, the nearest any slab's edge can come. It is (1 - u^2)^2 shaped, as
# `Organic.hedge`'s bow is, so the beds leave each end square to the
# headland: the trough at the foot of a path stands in a path that runs
# straight there.
SWAY = 0.10
# Each bed's own stray off the S, as a spade leaves it.
STRAY = 0.010
STEP = 0.05

# u (1 - u^2)^2 is largest at u = 1 / sqrt 5, where it is 16 / (25 sqrt 5).
_PEAK = 16 / (25 * math.sqrt(5))


def sway(z):
    """How far the beds stand east of their straight line at `z` (the plain
    plot; a mirrored plot sways the other way)."""
    u = z / (LENGTH / 2)
    if abs(u) >= 1:
        return 0.0
    return SWAY / _PEAK * u * (1 - u * u) * (1 - u * u)


def line(bed):
    """A bed's middle, north end first, a point every STEP metres along it.

    The middle bed sways; the other two are its line moved 1.65 m sideways,
    square to it all the way, so the paths between them stay 0.45 m where the
    beds lean as well as where they run straight. Then each strays on its own."""
    n = 840
    middle = [(BED_X[1] + sway(-LENGTH / 2 + LENGTH * i / n), -LENGTH / 2 + LENGTH * i / n)
              for i in range(n + 1)]
    beside = shapes.offset(middle, BED_X[1] - BED_X[bed]) if bed != 1 else middle
    strayed = _stray(beside, ('home-ground-bed', bed))
    return shapes.resample(strayed, STEP)


def _stray(points, seed):
    """Each point moved across the bed by smooth noise, nothing at the two ends,
    so a bed is as long as it was and starts and ends where it did."""
    rng = Rng(*seed)
    knots = [rng.uniform(-1, 1) for _ in range(8)]
    out = []
    n = len(points) - 1
    for i, (x, z) in enumerate(points):
        t = i / n * (len(knots) - 1)
        k = min(int(t), len(knots) - 2)
        f = t - k
        f = f * f * (3 - 2 * f)
        w = knots[k] + (knots[k + 1] - knots[k]) * f
        ends = 4 * (i / n) * (1 - i / n)
        out.append((x + STRAY * w * ends, z))
    return out


def rows(bed, crop):
    """A bed sown with `crop`: its places in reading order from the north end,
    row by row, west to east along each row, as `HomeGround.Slot` numbers them.

    The rows stand `rowGap` apart along the bed's line, centred on its middle,
    so every crop's rows span the same 3.6 m of it; each row runs square to
    the line there, its places `gap` apart."""
    across, gap, count, row_gap = SOWN[crop]
    middle = line(bed)
    half = shapes.length(middle) / 2
    out = []
    for r in range(count):
        s = half + (r - (count - 1) / 2) * row_gap
        (x, z), (tx, tz) = shapes.point_at(middle, s)
        # East, square to the line: the line's direction turned a quarter back.
        ex, ez = tz, -tx
        for c in range(across):
            o = (c - (across - 1) / 2) * gap
            out.append((x + ex * o, z + ez * o))
    return out
