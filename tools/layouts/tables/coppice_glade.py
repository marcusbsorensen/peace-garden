"""The Coppice as coupes round a glade: three rides meet at a small sunny glade and curve out to the edge.

Marcus's choice of 2 October 2026 (`design/garden-layouts-2026-10-02/RESEARCH.md`
§*The Coppice*, option A). The rule is unchanged: three coupes of eleven, five
stools and a floor of six in each, ferns on the stools and stars on the floor,
one coupe cut each winter. Only where the places stand has changed.

- **Three rides meet at the glade** and bend out to the rim, and divide the
  plot into three coupes of unequal size. The glade, the rides' angles and
  the coupes' shares come from the feature variant.
- **The stools stand scattered in their coupe**, as blue noise clear of the
  glade, the rides and the floor, and fill from the coupe's middle outward —
  the old `2, 1, 3, 0, 4` kept in spirit: a coupe of three stools is a clump.
- **The stars stand in clumps of three along the ride edges**, where the light
  is: one clump by each of the coupe's two rides. The front row is the ride's
  edge, for the shorter stars, and the back row stands behind it, away from
  the ride, for the taller. The first clump holds two of the front row and
  one of the back, the second one of the front and two of the back, and each
  row fills its first clump first, so a coupe's first stars stand together.
- **The spring basin** stands beside the outer end of one ride.

Tags: `coupe` (0 to 2, round the glade the way a turn runs), `place` (0 a
stool, 1 the back row, 2 the front, as `Coppice.Place`) and `index` (the place
along its row as the rule numbers it: a row's k-th place to fill carries
`Coppice.stoolOrder[k]` or `Coppice.floorOrder[k]`). Curves: `glade`,
`ride0` to `ride2` (centre lines, from the glade out past the rim), `coupe0`
to `coupe2` (each coupe's ground, out past the rim) and `spring` (one point).
"""
import math

from places import Layout, shapes, sample, order
from places.numbers import Rng, cos_sin

FIELDS = ('coupe', 'place', 'index')
NUDGES = 3
MIN_SPACING = 0.40
BOUND = 2.3

STOOL, BACK, FRONT = 0, 1, 2
STOOL_ORDER = [2, 1, 3, 0, 4]     # Coppice.stoolOrder
FLOOR_ORDER = [1, 0, 2]           # Coppice.floorOrder

GLADE = (0.62, 0.52)    # the glade's radii
RIDE_HALF = 0.27        # half a ride at its widest (0.48 m, give or take 12%)
FRONT_FROM = 0.48       # the front row's distance from its ride's centre line
BACK_FROM = 0.90        # the back row's
STOOL_CLEAR = 0.55      # a stool from any ride's centre line
OUT = 3.6               # how far a ride and a coupe's ground run, past the rim
STOOL_SPACING = 0.55    # the least two stools of a coupe stand apart
STOOL_FLOOR = 0.45      # the least a stool stands from a star's place
STOOL_GLADE = 0.85      # and from the glade's middle
HEART = 1.55            # how far from the glade a coupe's stand of stools gathers
FIRST_CLUMP = (1.05, 1.25)    # how far along its ride from the glade's middle each clump stands
SECOND_CLUMP = (1.25, 1.50)


def _d(a, b):
    dx, dz = a[0] - b[0], a[1] - b[1]
    return math.sqrt(dx * dx + dz * dz)


def _on_plot(p, half=2.12, corner=0.40):
    """Inside a rounded square the plot's wandering edge never comes in past
    (2.38 m on a side, corners round 0.35), less room for a nudge."""
    x, z = abs(p[0]), abs(p[1])
    if x > half or z > half:
        return False
    c = half - corner
    if x > c and z > c:
        return _d((x, z), (c, c)) <= corner
    return True


def _ride(glade, turn, bend, rng):
    """A ride's centre line: from the glade's middle out past the rim, bending
    by `bend` of a turn by its far end, with a little of its own wander."""
    control = []
    for k, r in enumerate([0.0, 0.7, 1.4, 2.1, 2.8, OUT]):
        f = r / OUT
        wiggle = 0.0 if k == 0 else rng.uniform(-0.004, 0.004)
        c, s = cos_sin(turn + bend * f * f + wiggle)
        control.append((glade[0] + r * c, glade[1] + r * s))
    return shapes.spline(control, closed=False, per=10)


def _at(ride, s):
    """The point `s` metres along a ride, its unit tangent and its left normal."""
    (x, z), (tx, tz) = shapes.point_at(ride, s)
    return (x, z), (tx, tz), (-tz, tx)


def _clump(ride, s, into, fronts):
    """A clump of three by a ride, `s` metres along it, on the side `into` of
    it (+1 its left, -1 its right): two in front and one behind, or one in
    front and two behind. Returns (front places, back places), each nearest
    the glade first."""
    (x, z), (tx, tz), (nx, nz) = _at(ride, s)
    nx, nz = nx * into, nz * into
    def at(off, along):
        return (x + nx * off + tx * along, z + nz * off + tz * along)
    if fronts == 2:
        return [at(FRONT_FROM, -0.33), at(FRONT_FROM, 0.33)], [at(BACK_FROM, 0.03)]
    return [at(FRONT_FROM, 0.0)], [at(BACK_FROM, -0.34), at(BACK_FROM, 0.34)]


def _thin(points, middle):
    """Whether a stand of stools is strung out in a line: the spread across
    its long axis under 0.35 of the spread along it."""
    sxx = szz = sxz = 0.0
    for x, z in points:
        dx, dz = x - middle[0], z - middle[1]
        sxx += dx * dx
        szz += dz * dz
        sxz += dx * dz
    half = (sxx + szz) / 2
    root = math.sqrt(((sxx - szz) / 2) * ((sxx - szz) / 2) + sxz * sxz)
    major, minor = half + root, half - root
    return minor < 0.35 * 0.35 * major


def _shares(rng):
    """Three unequal shares of the turn round the glade, none under 0.27."""
    while True:
        a = rng.uniform(0.27, 0.40)
        b = rng.uniform(0.27, 0.40)
        c = 1.0 - a - b
        if 0.27 <= c <= 0.42 and max(abs(a - b), abs(b - c), abs(a - c)) >= 0.04:
            return [a, b, c]


class _Miss(Exception):
    """An attempt at a layout that does not fit, and why."""


def _try(rng):
    glade = (rng.uniform(-0.25, 0.25), rng.uniform(-0.25, 0.25))
    shares = _shares(rng)
    base = rng.unit()
    turns = [base, base + shares[0], base + shares[0] + shares[1]]
    rides = [_ride(glade, t, rng.uniform(-0.05, 0.05), rng) for t in turns]
    outline = shapes.blob(glade, GLADE, seed=('coppice-glade', rng.next()), wander_by=0.05,
                          turn=rng.unit())

    coupes = []
    for c in range(3):
        a0, a1 = turns[c], turns[(c + 1) % 3] + (1.0 if c == 2 else 0.0)
        steps = 24
        rim = []
        for k in range(1, steps):
            cc, ss = cos_sin(a0 + (a1 - a0) * k / steps)
            rim.append((glade[0] + OUT * cc, glade[1] + OUT * ss))
        coupes.append([glade] + rides[c][1:] + rim + list(reversed(rides[(c + 1) % 3][1:])))

    def near_ride(p, least):
        return any(shapes.distance_to(p, r) < least for r in rides)

    floors = []
    for c in range(3):
        first, second = rides[c], rides[(c + 1) % 3]
        # Which side of each ride is this coupe's: the one its ground is on.
        def side(ride):
            p, _, n = _at(ride, 1.2)
            probe = (p[0] + n[0] * 0.6, p[1] + n[1] * 0.6)
            return 1.0 if shapes.inside(probe, coupes[c]) else -1.0
        fa, ba = _clump(first, rng.uniform(*FIRST_CLUMP), side(first), 2)
        fb, bb = _clump(second, rng.uniform(*SECOND_CLUMP), side(second), 1)
        floors.append((fa, ba, fb, bb))
    places = [p for f in floors for group in f for p in group]
    if not all(_on_plot(p) for p in places):
        raise _Miss('a star off the plot')
    for c, (fa, ba, fb, bb) in enumerate(floors):
        for p, own in [(q, 0) for q in fa + ba] + [(q, 1) for q in fb + bb]:
            mine = rides[c] if own == 0 else rides[(c + 1) % 3]
            others = [r for r in rides if r is not mine]
            if any(shapes.distance_to(p, r) < 0.55 for r in others):
                raise _Miss('a star near another ride')
            if shapes.distance_to(p, mine) < FRONT_FROM - 0.04:
                raise _Miss('a star in its own ride')
            if _d(p, glade) < 0.78:
                raise _Miss('a star in the glade')
    if any(_d(a, b) < 0.50 for i, a in enumerate(places) for b in places[i + 1:]):
        raise _Miss('two stars too close')

    spring = None
    for _ in range(60):
        r = rides[int(rng.below(3))]
        s = rng.uniform(1.9, 2.6)
        p, _, n = _at(r, s)
        into = 1.0 if rng.unit() < 0.5 else -1.0
        at = (p[0] + n[0] * 0.58 * into, p[1] + n[1] * 0.58 * into)
        if (_on_plot(at, half=2.0, corner=0.45) and all(_d(at, q) >= 0.62 for q in places)
                and not near_ride(at, 0.55)):
            spring = at
            break
    if spring is None:
        raise _Miss('no room for the spring')

    stools = []
    for c in range(3):
        keep = (lambda p: _on_plot(p) and not near_ride(p, STOOL_CLEAR) and _d(p, glade) >= STOOL_GLADE
                and all(_d(p, q) >= STOOL_FLOOR for q in places) and _d(p, spring) >= 0.62)
        # A stand of five round the coupe's heart: blue noise over the whole
        # coupe, and the five nearest the heart kept, so a coupe's stools
        # stand together in its middle rather than strung along the rim.
        found = sample.blue_noise(coupes[c], STOOL_SPACING, seed=('coppice-stools', rng.next()), keep=keep)
        if len(found) < 5:
            raise _Miss('no room for five stools')
        a0, a1 = turns[c], turns[(c + 1) % 3] + (1.0 if c == 2 else 0.0)
        hx, hz = cos_sin((a0 + a1) / 2)
        heart = (glade[0] + HEART * hx, glade[1] + HEART * hz)
        stand = order.centre_first(found, heart)[:5]
        mx = mz = 0.0
        for p in stand:      # added left to right, never with sum()
            mx += p[0]
            mz += p[1]
        if _thin(stand, (mx / 5, mz / 5)):
            raise _Miss('a stand strung in a line')
        stools.append(order.centre_first(stand, (mx / 5, mz / 5)))
    every = places + [p for s in stools for p in s]
    if any(_d(a, b) < min(0.50, STOOL_FLOOR) for i, a in enumerate(every) for b in every[i + 1:]):
        raise _Miss('places too close')

    return glade, outline, rides, coupes, floors, stools, spring


def build(nudge):
    rng = Rng('coppice-glade', nudge)
    for _ in range(2000):
        try:
            made = _try(rng)
            break
        except _Miss:
            continue
    else:
        raise ValueError(f'no coppice fits for variant {nudge}')
    glade, outline, rides, coupes, floors, stools, spring = made

    layout = Layout()
    for c in range(3):
        fa, ba, fb, bb = floors[c]
        for k, p in enumerate(stools[c]):
            layout.add([p], coupe=c, place=STOOL, index=STOOL_ORDER[k])
        for k, p in enumerate([ba[0], bb[0], bb[1]]):
            layout.add([p], coupe=c, place=BACK, index=FLOOR_ORDER[k])
        for k, p in enumerate([fa[0], fb[0], fa[1]]):
            layout.add([p], coupe=c, place=FRONT, index=FLOOR_ORDER[k])
    layout.curve('glade', outline)
    for r, ride in enumerate(rides):
        layout.curve(f'ride{r}', ride, closed=False)
    for c, ground in enumerate(coupes):
        layout.curve(f'coupe{c}', ground)
    layout.curve('spring', [spring], closed=False)
    return layout
