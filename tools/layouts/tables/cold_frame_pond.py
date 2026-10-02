"""The Cold Frame's pond, planted as a pond: reeds in clumps of three at the margin, lilies from the deepest water out.

Marcus, 2 October 2026 (RESEARCH.md, *The Cold Frame*, option A). The tank of
29 September becomes a pond with a wandering, kidney outline, its bay toward
the frames, and keeps its thirty-nine places:

- **the margin** (kind 0): five clumps of three on the shallow shelf a hand
  in from the edge, where a reed stands. The clumps are listed the west one
  first and then farthest-first round the pond, and a clump's three together,
  so reeds arrive as clumps rather than as a fringe;
- **the open water** (kind 1): twenty-four on a sunflower from the deepest
  point (Vogel's spiral, centre first), where a lily lies. A pond of three
  lilies is three in the middle, never three in a row.

The rule sends a reed to the margin and a lily to the open water, each falling
back to the other, so neither strands a plot: a reed that finds the margin
full takes the open water from its outer edge in, and a lily that finds the
open water full takes the margin in the clumps' order. The plot is mirrored
by its number, so the bay leans east and west in turn; the frames stay at the
back.
"""
import math

from places import Layout, shapes, sample, order
from places.numbers import cos_sin

FIELDS = ('kind', 'clump')
NUDGES = 1
JS = True

MARGIN, OPEN = 0, 1

# The pond, as control points round it from the east end toward the front
# (z+), then back along the frames' side with its bay. Inside the yard the
# tank had: 2.2 m either side of the middle, from 0.85 m in front of the plot's
# middle line (the frames' fronts stand at 1.10) to 2.15 m toward the front.
OUTLINE = [
    (2.28, 0.60), (2.12, 1.62), (1.28, 2.18), (0.10, 2.22), (-1.12, 2.15),
    (-2.02, 1.76), (-2.30, 0.80), (-2.10, -0.36), (-1.25, -0.90), (-0.42, -0.86),
    (0.20, -0.62), (0.82, -0.80), (1.66, -0.92), (2.18, -0.34),
]
# How far in from the water's edge a reed's clump stands, and how far its
# three stand from the clump's middle. The pond itself is a little larger than
# the tank was, 12.8 m² against 13.9 m² of the tank's squared outline less its
# corners, and stops 0.2 m short of the frames' fronts.
SHELF = 0.26
CLUMP = 0.15
# The open water: no lily within this of the edge, nor of a reed's place, nor
# of another lily (`ColdFrame.pondGap`). Half a metre between lilies, as the
# research proposed: a little closer than the tank's 0.62, so a young lily's
# pads (0.31 m from its stem at the median) lie against its neighbour's.
EDGE_ROOM = 0.24
REED_ROOM = 0.36
LILY_GAP = 0.50


def pond():
    return shapes.wander(shapes.spline(OUTLINE, closed=True, per=12), 0.035,
                         seed=('cold-frame-pond',), wavelength=0.9)


def inward(rim, s):
    """The point `s` metres round the rim and the way into the water there."""
    (x, z), (tx, tz) = shapes.point_at(rim, s, closed=True)
    # The rim runs from x+ toward z+, so the water is to its left.
    return (x, z), (-tz, tx)


def clumps(rim):
    total = shapes.length(rim, closed=True)
    centres = []
    for k in range(5):
        # Five round the pond, a little unevenly, none in the bay.
        s = total * (0.03 + k * 0.205 + (0.02 if k % 2 else -0.015))
        (x, z), (nx, nz) = inward(rim, s)
        if z < -0.3 and abs(x) < 0.9:
            raise SystemExit(f'cold_frame_pond: clump {k} is in the bay')
        centres.append(((x + nx * SHELF, z + nz * SHELF), (nx, nz)))
    west = min(range(5), key=lambda k: centres[k][0][0])
    ordered = order.focal_first([c for c, _ in centres], centres[west][0])
    out = []
    for c in ordered:
        k = [cc for cc, _ in centres].index(c)
        _, (nx, nz) = centres[k]
        members = []
        for j in range(3):
            # A small scalene triangle, its first reed on the water side.
            turn = (j / 3.0) + 0.07 * k + (0.04 if j == 2 else 0.0)
            cc, ss = cos_sin(turn)
            # Lay the triangle in the shore's frame: along it and into the water.
            along, into = cc * CLUMP * (1.0 + 0.15 * j), ss * CLUMP
            members.append((c[0] + nx * into - nz * along, c[1] + nz * into + nx * along))
        out.append(members)
    return out


def open_water(rim, reeds):
    # The deepest water: the middle of the pond, a little toward the front,
    # away from the bay.
    deep = shapes.centroid(rim)
    deep = (deep[0], deep[1] + 0.10)

    def keep(p):
        if shapes.distance_to(p, rim, closed=True) < EDGE_ROOM:
            return False
        return all(math.sqrt((p[0] - r[0]) * (p[0] - r[0]) + (p[1] - r[1]) * (p[1] - r[1])) >= REED_ROOM
                   for r in reeds)
    # The widest spiral that holds twenty-four with half a metre between any
    # two, turned whichever of twenty ways leaves the most between them.
    c = 0.36
    while c > 0.25:
        best = None
        for k in range(20):
            try:
                pts = sample.sunflower(deep, c, 24, turn=k / 20, region=rim, keep=keep, limit=800)
            except ValueError:
                continue
            least = min(math.sqrt((a[0] - b[0]) * (a[0] - b[0]) + (a[1] - b[1]) * (a[1] - b[1]))
                        for i, a in enumerate(pts) for b in pts[i + 1:])
            if best is None or least > best[0] + 1e-9:
                best = (least, pts)
        if best is not None and best[0] >= LILY_GAP:
            return best[1]
        c -= 0.005
    raise SystemExit('cold_frame_pond: twenty-four lilies do not fit')


def build(nudge):
    rim = pond()
    groups = clumps(rim)
    reeds = [p for g in groups for p in g]
    lilies = open_water(rim, reeds)
    layout = Layout()
    for k, members in enumerate(groups):
        layout.add(members, kind=MARGIN, clump=k)
    layout.add(lilies, kind=OPEN, clump=0)
    layout.curve('pond', rim)
    layout.curve('shelf', shapes.offset(rim, 0.42, closed=True))
    return layout
