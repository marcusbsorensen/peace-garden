"""The Crossing's four ways turning in, and the six places of each quarter on three arcs round the basin.

Marcus, 2 October 2026 (RESEARCH.md, *The Crossing*, option A). Four mown
paths come in from the middle of each side and all turn the same way, 56
degrees between the plot's edge and the paved round, so the four meet it
turning in rather than crossing. Between each two the quarter is a comma of
rough grass wrapped round the centre. Each quarter's six stand on three arcs
round the basin: three on the inner arc, two behind them, one at the outer
corner, all facing in. The rule is the one built on 21 September: the
emptiest quarter first, so ten plants make a ring round the basin.

Each path is laid by hand: its centre line wanders a few centimetres of its
own, so the four are not one path turned four ways, and a plot turned a
quarter is not the plot it was. The places are worked out from the paths as
laid: on each arc, the stretch clear of both paths by a plant's room, the
middle of it first. Quarter 0 is the south-east one, between the ways in from
the east and the south, as `Crossing.Quarter.first` lies.
"""
import math

from places import Layout, shapes
from places.numbers import cos_sin, smooth

FIELDS = ('quarter', 'rank')
NUDGES = 1
JS = True
MIN_SPACING = 0.50

# A path's half width at the plot's edge and where it reaches the round:
# `Crossing.pathHalfWidth` and `pathHalfWidthAtRound`. Narrower than the
# straight paths' 0.6, and narrowing as it turns in. A path that turns crosses
# each arc at a slant and covers more of it than one running straight across,
# and at 0.6 the inner arc had no room for three: the research's drawing stood
# them on the mown grass. These stand clear of it.
HALF_EDGE = 0.45
HALF_ROUND = 0.35
EDGE = 2.60
ROUND = 0.85
# How far a path turns, evenly, from `BEGUN` metres out to the round: 0.19
# of a turn, of which 0.155 (56 degrees) is on the plot. Every stretch of it
# is turning, and the arcs the plants stand on still have room for them.
WHIRL = 0.19
BEGUN = 3.00
# The three arcs, and how many stand on each: the path rank, the middle, the
# corner. Nothing on an arc is in front of anything else on it.
ARCS = ((1.95, 3), (2.45, 2), (2.80, 1))
# How far a place stands from a path's edge: a plant's own room and its nudge.
CLEAR = 0.23
WANDER = 0.035


def half_width(r):
    """A path's half width at `r` metres from the middle (`Crossing.halfWidth`)."""
    u = smooth((r - ROUND) / (EDGE - ROUND))
    return HALF_ROUND + (HALF_EDGE - HALF_ROUND) * u


def way_turn(q, r):
    """Which way path `q` lies from the middle at `r` metres out, in turns:
    straight in at the middle of its side where it crosses the plot's edge,
    and turning evenly all the way in, a little under a sixth of a turn by
    the round. The turn is laid out from `BEGUN` metres out, past the plot,
    so the path is already turning where it comes onto it."""
    return q * 0.25 + WHIRL * ((BEGUN - r) - (BEGUN - EDGE)) / (BEGUN - ROUND)


def way(q):
    """Path `q`'s centre line, from outside the plot to under the round."""
    pts = []
    steps = 140
    for i in range(steps + 1):
        r = 3.1 - (3.1 - 0.62) * i / steps
        c, s = cos_sin(way_turn(q, r))
        pts.append((r * c, r * s))
    return shapes.wander(pts, WANDER, seed=('crossing-way', q), wavelength=1.1, closed=False)


def room(p, ways):
    """How far a point is from the nearer path's edge."""
    best = None
    for w in ways:
        for x, z in w:
            dx, dz = p[0] - x, p[1] - z
            r = math.sqrt(x * x + z * z)
            gap = math.sqrt(dx * dx + dz * dz) - half_width(r)
            if best is None or gap < best:
                best = gap
    return best


def stretch(q, r, ways):
    """The turns between which the arc of radius `r` in quarter `q` is clear of
    both its paths by a plant's room."""
    lo_turn = way_turn(q, r)
    hi_turn = way_turn(q + 1, r)
    steps = 900
    clear = []
    for i in range(steps + 1):
        t = lo_turn + (hi_turn - lo_turn) * i / steps
        c, s = cos_sin(t)
        if room((r * c, r * s), ways) >= CLEAR:
            clear.append(t)
    if not clear:
        raise SystemExit(f'crossing_ways: no room on the {r} m arc of quarter {q}')
    return clear[0], clear[-1]


def at(r, t):
    c, s = cos_sin(t)
    return (r * c, r * s)


def gap(a, b):
    return math.sqrt((a[0] - b[0]) * (a[0] - b[0]) + (a[1] - b[1]) * (a[1] - b[1]))


def quarter_places(q, ways):
    """The six places of quarter `q`, rank by rank, each rank its middle
    first. The three of the path rank span the inner arc's clear stretch; the
    corner stands in the middle of the outer one; and the two between stand
    where they are furthest from all four and from each other."""
    (r0, _), (r1, _), (r2, _) = ARCS
    lo, hi = stretch(q, r0, ways)
    inner = [at(r0, (lo + hi) / 2), at(r0, lo), at(r0, hi)]
    lo, hi = stretch(q, r2, ways)
    corner = [at(r2, (lo + hi) / 2)]
    lo, hi = stretch(q, r1, ways)
    steps = 60
    best = None
    for i in range(steps + 1):
        a = at(r1, lo + (hi - lo) * i / steps)
        for j in range(i + 1, steps + 1):
            b = at(r1, lo + (hi - lo) * j / steps)
            least = gap(a, b)
            for p in inner + corner:
                least = min(least, gap(a, p), gap(b, p))
            if best is None or least > best[0] + 1e-9:
                best = (least, a, b)
    return inner, [best[1], best[2]], corner


def build(nudge):
    ways = [way(q) for q in range(4)]
    layout = Layout()
    for q in range(4):
        # The quarter between the way in from `q` and the next one round.
        near = [ways[q], ways[(q + 1) % 4]]
        for rank, places in enumerate(quarter_places(q, near)):
            layout.add(places, quarter=q, rank=rank)
    for q in range(4):
        layout.curve(f'way{q}', ways[q], closed=False)
    return layout
