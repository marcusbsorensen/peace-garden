"""The Seedbed's six drills on the contour: concentric arcs, the way rows follow a slope.

The bed falls toward z+, so each drill is a contour: an arc about a point
below the plot, the top drill the longest radius. Drill 0 is the top, on the
high side, where the dry kinds claim from; drill 5 the bottom, on the low
side, where the water kinds claim from, so the flooded drills lie together
like paddies. Marcus chose this on 2 October 2026
(`design/garden-layouts-2026-10-02/RESEARCH.md`, the Seedbed, option A).

Eight places a drill, 0.52 m apart along it, and 0.74 m between drills, as
the straight bed had. `index` is how far along its drill a place stands,
0 nearest the label at the drill's west end. Each drill's places are listed in
the order a dry drill is sown: the place nearest its middle first, then
farthest-first, so a drill of one plant, three or five looks sown rather than
started. `pair` is the order a flooded drill is sown in: a lily takes two
places side by side, so a flooded drill is sown in pairs (0 and 1, 2 and 3,
and so on), the pair nearest its middle first and then farthest-first, and a
reed takes the first free place in that order. Both orders change which
places are taken, never how many: a drill holds the same plants either way.

The curves are each drill's line, `drill0` to `drill5`, from its label to a
little past its last place: the first point is where the label stands, and
the line is what the rake draws and the water fills.
"""
import math

from places import Layout, shapes, order
from places.numbers import Rng, cos_sin, turn_of

FIELDS = ('drill', 'index', 'pair')
JS = True
MIN_SPACING = 0.48
BOUND = 2.06

DRILLS = 6
PLACES = 8
ALONG = 0.52       # between places along a drill
ACROSS = 0.74      # between drills
CENTRE = (0.02, 7.4)   # the contours' middle, below the plot
TOP = -2.0         # where the top drill crosses x = CENTRE's
LABEL = 0.34       # how far before its first place a drill's label stands
TAIL = 0.26        # how far the drill runs on past its last place


def drill_line(d):
    """Drill d's line: an arc about CENTRE, wandering a few centimetres."""
    cx, cz = CENTRE
    r = cz - TOP - ACROSS * d
    rng = Rng('seedbed-drill', d)
    # Where the drill's first place stands across the bed: the labels stand
    # on a gentle curve rather than a ruled column, the middle drills
    # beginning a little further in than the outer ones.
    u = (d - (DRILLS - 1) / 2) / ((DRILLS - 1) / 2)
    first_x = -1.80 + 0.13 * (1 - u * u) + rng.uniform(-0.02, 0.02)
    length = ALONG * (PLACES - 1)
    # Turns about CENTRE of the label, the first place and the far end.
    def turn_at_x(x):
        dz = -math.sqrt(r * r - (x - cx) * (x - cx))
        return turn_of(x - cx, dz)
    t_first = turn_at_x(first_x)
    per_metre = 1 / (2 * math.pi * r)
    t_start = t_first - LABEL * per_metre
    t_end = t_first + (length + TAIL) * per_metre
    n = int(math.ceil((t_end - t_start) / per_metre / 0.05))
    arc = []
    for i in range(n + 1):
        c, s = cos_sin(t_start + (t_end - t_start) * i / n)
        arc.append((cx + r * c, cz + r * s))
    line = shapes.wander(arc, 0.025, ('seedbed-furrow', d), wavelength=1.1, closed=False)
    return line, LABEL


def build(nudge):
    layout = Layout()
    for d in range(DRILLS):
        line, label = drill_line(d)
        # The eight places, 0.52 m apart along the line from the first.
        spots = [shapes.point_at(line, label + ALONG * i)[0] for i in range(PLACES)]
        middle = shapes.point_at(line, label + ALONG * (PLACES - 1) / 2)[0]
        index_of = {p: i for i, p in enumerate(spots)}
        # The flooded order: the pairs, by their middles, nearest the drill's
        # middle first and then farthest-first.
        pairs = [((spots[2 * k][0] + spots[2 * k + 1][0]) / 2, (spots[2 * k][1] + spots[2 * k + 1][1]) / 2, k)
                 for k in range(PLACES // 2)]
        pair_rank = {}
        for rank, p in enumerate(order.focal_first(pairs, middle)):
            pair_rank[p[2]] = rank
        for p in order.focal_first(spots, middle):
            i = index_of[p]
            layout.add([p], drill=d, index=i, pair=pair_rank[i // 2])
        layout.curve(f'drill{d}', line, closed=False)
    return layout
