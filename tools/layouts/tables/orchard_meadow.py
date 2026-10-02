"""The Orchard as a meadow orchard: five trees on a quincunx, a crescent of four under each outer tree turned toward the middle one, and one mown way.

Marcus's choice of 2 October 2026 (`design/garden-layouts-2026-10-02/RESEARCH.md`
§*The Orchard*, option A). The rule is unchanged: five guilds of four, one
finished before the next is begun, and a guild's places graded outward from
the middle of the plot. Only where the places stand has changed.

- **The trees stay on the quincunx, each outer one nudged a little**, because
  old orchards are never true. Each feature variant nudges them differently.
- **An outer guild is a crescent at its tree's drip line, turned toward the
  middle tree**: the understorey on the line to the middle, the two flanks
  either side of it at one distance from the middle, and the crown at the
  crescent's far horn. The crowns horn toward the pockets on the plot's z axis,
  so two tall crowns frame each of those, and the x axis pockets stay open for
  the way.
- **The middle tree keeps its ring of four**, on the diagonals, each facing a
  crescent. The ring has no ranks, so its order is the fill order: the place
  facing the first crescent, then the one opposite, then the other two.
- **The guilds fill farthest-first**: the far crescent (facing the eye before
  a turn), the near one, then the two at the sides.
- **One mown way** wanders in from the x− edge through the open pocket, passes
  the middle tree inside its mown disc, and leaves by the x+ pocket.
- **The dipping pond** lies in one of the z axis pockets, between two crowns.

Tags: `guild` (0 the middle, then 1 to 4 in the order they fill) and `index`
(0 to 3: in an outer guild 0 is the understorey, 1 and 2 the flanks, 3 the
crown, as `Orchard.Slot` reads them). Curves: `trunks` (the five, middle
first, then by guild), `way` (the mown way's centre line), `pond` (its middle,
one point) and `crescent1` to `crescent4` (each crescent's mown arc).
"""
import math

from places import Layout, shapes
from places.numbers import Rng, cos_sin, turn_of

FIELDS = ('guild', 'index')
NUDGES = 3
MIN_SPACING = 0.55
BOUND = 2.3

TREE_FROM = 1.74        # how far out the outer trunks stand on each axis, before the nudge
TREE_NUDGE = 0.08       # how far a trunk may be nudged on each axis
CRESCENT = 0.90         # how far a crescent's places stand from their trunk: the drip line
MIDDLE = 0.75           # how far the middle tree's four stand from it: under its canopy's edge,
                        # where the underside is 2.35 m up and over the tallest plant grown
FLANK = 36 / 360        # the flanks' turn either side of the line to the middle
CROWN = 72 / 360        # the crown's turn, toward the pocket it frames
PLANT_NUDGE = 0.13      # Orchard's nudge from the seed, each axis

# The outer trees in the order their guilds fill: far, near, then the sides.
CORNERS = [(-1, -1), (1, 1), (1, -1), (-1, 1)]


def _d(a, b):
    dx, dz = a[0] - b[0], a[1] - b[1]
    return math.sqrt(dx * dx + dz * dz)


def _on_plot(p, half=2.20, corner=0.40):
    """Inside a rounded square the plot's wandering edge never comes in past,
    less a margin for the plant's nudge: `Organic.outline` comes in to 2.38 m
    on a side and rounds its corners by 0.35 m."""
    x, z = abs(p[0]), abs(p[1])
    if x > half or z > half:
        return False
    c = half - corner
    if x > c and z > c:
        return _d((x, z), (c, c)) <= corner
    return True


def _wrap(t):
    while t > 0.5:
        t -= 1.0
    while t <= -0.5:
        t += 1.0
    return t


def _crescent(trunk, sx, sz):
    """A guild's four places round its trunk, index order, and its mown arc."""
    toward = turn_of(-trunk[0], -trunk[1])
    pocket = turn_of(-sx, 0.0)
    horn = 1.0 if _wrap(pocket - toward) > 0 else -1.0
    offsets = [0.0, -horn * FLANK, horn * FLANK, horn * CROWN]
    places = []
    for off in offsets:
        c, s = cos_sin(toward + off)
        places.append((trunk[0] + CRESCENT * c, trunk[1] + CRESCENT * s))
    lo, hi = min(offsets) - 0.05, max(offsets) + 0.05
    arc = shapes.arc(trunk, CRESCENT, toward + lo, toward + hi, spacing=0.08)
    return places, arc


def _middle():
    """The middle tree's four, on the diagonals, in fill order: facing the
    first crescent, the one opposite, then the other two as the guilds go."""
    out = []
    for sx, sz in CORNERS:
        c, s = cos_sin(turn_of(sx, sz))
        out.append((MIDDLE * c, MIDDLE * s))
    return out


def _way(rng):
    """The mown way's centre line: in from x−, past the middle tree on one
    side inside its disc, out at x+. Beyond the rim at both ends, so the
    drawing cuts it where the plot's own edge is."""
    side = 1.0 if rng.unit() < 0.5 else -1.0
    j = lambda reach: rng.uniform(-reach, reach)
    control = [(-2.80, j(0.30)), (-1.75, j(0.16)), (-0.95, side * 0.18 + j(0.10)),
               (0.0, side * 0.40), (0.95, side * 0.18 + j(0.10)), (1.75, j(0.16)), (2.80, j(0.30))]
    return shapes.spline(control, closed=False, per=10)


def _pond(rng, places, way):
    """The dipping pond: in a z axis pocket, between two crowns, clear of every
    place by 0.80 m and of the way by 0.90 m."""
    for side in ([1.0, -1.0] if rng.unit() < 0.5 else [-1.0, 1.0]):
        for _ in range(60):
            at = (rng.uniform(-0.12, 0.12), side * rng.uniform(1.62, 1.76))
            if all(_d(at, p) >= 0.80 for p in places) and shapes.distance_to(at, way) >= 0.90:
                return at
    raise ValueError('no room for the pond')


def build(nudge):
    rng = Rng('orchard-meadow', nudge)
    middle = _middle()
    for attempt in range(400):
        trunks = [(0.0, 0.0)]
        guilds = []
        arcs = []
        for sx, sz in CORNERS:
            trunk = (sx * TREE_FROM + rng.uniform(-TREE_NUDGE, TREE_NUDGE),
                     sz * TREE_FROM + rng.uniform(-TREE_NUDGE, TREE_NUDGE))
            places, arc = _crescent(trunk, sx, sz)
            trunks.append(trunk)
            guilds.append(places)
            arcs.append(arc)
        every = middle + [p for g in guilds for p in g]
        ok = all(_on_plot(p) for p in every)
        ok = ok and all(_d(a, b) >= MIN_SPACING + 0.002 for i, a in enumerate(every) for b in every[i + 1:])
        ok = ok and all(_d(p, t) >= 0.55 for p in every for t in trunks)
        # The middle tree's four and the near end of each crescent lean toward
        # each other: no two guilds' places closer than 0.80 m.
        groups = [middle] + guilds
        ok = ok and all(_d(a, b) >= 0.80 for i, g in enumerate(groups) for h in groups[i + 1:]
                        for a in g for b in h)
        if not ok:
            continue
        way = _way(rng)
        outer = [p for g in guilds for p in g]
        if any(shapes.distance_to(p, way) < 0.55 for p in outer):
            continue
        if any(shapes.distance_to(t, way) < 0.90 for t in trunks[1:]):
            continue
        try:
            pond = _pond(rng, every, way)
        except ValueError:
            continue
        break
    else:
        raise ValueError(f'no orchard fits for variant {nudge}')

    layout = Layout()
    for g, places in enumerate([middle] + guilds):
        for i, p in enumerate(places):
            layout.add([p], guild=g, index=i)
    layout.curve('trunks', trunks, closed=False)
    layout.curve('way', way, closed=False)
    layout.curve('pond', [pond], closed=False)
    for g, arc in enumerate(arcs, start=1):
        layout.curve(f'crescent{g}', arc, closed=False)
    return layout
