"""The Knot Garden's interlaced rings: a ring round the middle and four rings woven through it, inside a softened square.

Option A of the layouts Marcus approved on 2 October 2026
(`design/garden-layouts-2026-10-02/RESEARCH.md`). The four small rings stand
on the plot's diagonals, each crossing the middle ring twice, so the knot has
eight compartments: the four lenses where a small ring overlaps the middle
one, and the four crescents of the small rings outside it. Opposite lenses
are a pair and opposite crescents are a pair, so the colour rule is the one
the knot always had.

Places are listed compartment by compartment, in `KnotGarden.Compartment`'s
order (the lenses north-east, south-east, south-west and north-west, then the
crescents the same way round), four to each: the heart nearest the middle of
the plot, the two sides, the point farthest out. A compartment is the
north-east one turned by whole quarters, so a pair's places are exactly
opposite across the middle.

The curves are the bands' lines, hand-laid: `middle` and `ring0` to `ring3`
(the small rings in compartment order), and `edging`. `crossings` is not a
band: it is the eight points where the middle ring crosses a small one, in
order round the middle ring from the north-east ring's first, and the middle
ring rides over at the even ones and dives under at the odd.
"""
import math

from places import Layout, shapes
from places.numbers import cos_sin, turn_of

FIELDS = ('compartment', 'index')
NUDGES = 1
JS = True
MIN_SPACING = 0.40

# What the rule says, written again here only to check the table against it.
BAND = 0.09            # KnotGarden.bandHalfThickness
NUDGE = 0.09           # how far a plant stands off its place, either way on each axis
CLEAR = 0.03           # what a plant pushed as hard as the seed can push it keeps from the box
SWELL = (0.0275, 0.29)  # how much thicker each side a band is where it rides over, and how far along
BASIN = 0.30           # the basin's radius, in the empty middle

# The knot. Measured, not chosen: on the axes, as the research's sketch drew it,
# the small rings can be no bigger than 0.74 m before they meet each other or the
# edging, and a lens then holds its four 0.22 m apart. On the diagonals they
# reach into the square's corners and the lens holds them 0.42 m apart.
MIDDLE = 1.480         # the middle ring's radius
RING_AT = 1.480        # how far out along its diagonal each small ring's middle is
RING = 0.936           # each small ring's radius
EDGING = 2.25          # the edging's half side on the axes: a squircle, |x|^4 + |z|^4 = 2.25^4
WANDER = 0.010         # how far a hand-laid line strays off its true line, either way
STEP = 0.05            # the spacing of a curve's points

# A compartment's four places in its own frame: out along its diagonal, then
# across it. The north-east one is this turned to the north-east.
LENS = [(0.805, 0.0), (1.050, -0.525), (1.050, 0.525), (1.220, 0.0)]
CRESCENT = [(1.740, 0.0), (1.655, -0.650), (1.655, 0.650), (2.155, 0.0)]


def _mm(v):
    """A length rounded to the millimetre the table holds, so that turning it
    a quarter is a sign and a swap and a pair stays exactly opposite."""
    return int(round(v * 1000)) / 1000


def _quarters(p, k):
    """Turned k quarters, x+ to z+, as `PlotVariant` turns."""
    x, z = p
    for _ in range(k % 4):
        x, z = 0.0 - z, x
    return (x, z)


NORTH_EAST = -1 / 8     # the north-east diagonal as a fraction of a turn: x+, z-


def _to_north_east(a, t):
    c, s = cos_sin(NORTH_EAST)
    return (_mm(a * c - t * s), _mm(a * s + t * c))


def _ring_middle(k):
    c, s = cos_sin(NORTH_EAST + k / 4)
    return (RING_AT * c, RING_AT * s)


def _laid(curve, seed):
    """A line as a hand lays it: off its true line by up to WANDER, and
    resampled every STEP metres."""
    return shapes.resample(shapes.wander(curve, WANDER, seed, wavelength=0.9), STEP, closed=True)


def _squircle(a, n=1440):
    out = []
    for i in range(n):
        c, s = cos_sin(i / n)
        r = a / math.sqrt(math.sqrt(c * c * c * c + s * s * s * s))
        out.append((r * c, r * s))
    return out


def _crossings(a, b):
    """Where two closed polylines cross."""
    out = []
    for i in range(len(a)):
        p, q = a[i], a[(i + 1) % len(a)]
        for j in range(len(b)):
            u, v = b[j], b[(j + 1) % len(b)]
            d = (q[0] - p[0]) * (v[1] - u[1]) - (q[1] - p[1]) * (v[0] - u[0])
            if d == 0:
                continue
            t = ((u[0] - p[0]) * (v[1] - u[1]) - (u[1] - p[1]) * (v[0] - u[0])) / d
            w = ((u[0] - p[0]) * (q[1] - p[1]) - (u[1] - p[1]) * (q[0] - p[0])) / d
            if 0 <= t < 1 and 0 <= w < 1:
                out.append((p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t))
    return out


def build(nudge):
    middle = _laid(shapes.circle((0.0, 0.0), MIDDLE, 720), ('knot-middle',))
    rings = [_laid(shapes.circle(_ring_middle(k), RING, 720), ('knot-ring', k)) for k in range(4)]
    edging = _laid(_squircle(EDGING), ('knot-edging',))

    # The eight crossings, round the middle ring: each ring's first (the one
    # before its own diagonal, going x+ to z+), then its second.
    crossings = []
    for k, ring in enumerate(rings):
        two = _crossings(middle, ring)
        if len(two) != 2:
            raise SystemExit(f'knot_garden_rings: ring {k} crosses the middle ring {len(two)} times, not twice')
        diagonal = NORTH_EAST + k / 4
        two.sort(key=lambda p: (turn_of(*p) - diagonal + 0.5) % 1.0)
        crossings += two

    lens = [_to_north_east(a, t) for a, t in LENS]
    crescent = [_to_north_east(a, t) for a, t in CRESCENT]
    layout = Layout()
    for first, shape in ((0, lens), (4, crescent)):
        for k in range(4):
            for i, p in enumerate(shape):
                layout.add([_quarters(p, k)], compartment=first + k, index=i)

    _check(layout, middle, rings, edging, crossings)

    layout.curve('middle', middle)
    for k, ring in enumerate(rings):
        layout.curve(f'ring{k}', ring)
    layout.curve('edging', edging)
    layout.curve('crossings', crossings, closed=False)
    return layout


def _check(layout, middle, rings, edging, crossings):
    """The table refuses to be written if a plant could stand in the box, a
    place is outside its compartment, two bands touch, or the basin does not
    fit."""
    problems = []
    bands = [middle] + rings + [edging]
    # Where a band rides over, it swells: the stretch of it within SWELL[1] of
    # the crossing is that much thicker.
    swells = []
    for i, c in enumerate(crossings):
        line = middle if i % 2 == 0 else rings[i // 2]
        swells.append([q for q in line if math.sqrt((q[0] - c[0]) * (q[0] - c[0]) + (q[1] - c[1]) * (q[1] - c[1]))
                       <= SWELL[1]])

    def clearance(p):
        least = min(shapes.distance_to(p, line, closed=True) for line in bands) - BAND
        swollen = min(shapes.distance_to(p, s) for s in swells) - BAND - SWELL[0]
        return min(least, swollen)

    for place in layout.places:
        k, i = place.tags['compartment'], place.tags['index']
        worst = min(clearance((place.x + dx, place.z + dz))
                    for dx in (-NUDGE, 0, NUDGE) for dz in (-NUDGE, 0, NUDGE))
        if worst < CLEAR:
            problems.append(f'compartment {k} place {i} can stand {worst:.3f} m from a band')
        p = (place.x, place.z)
        in_middle = shapes.inside(p, middle)
        in_ring = shapes.inside(p, rings[k % 4])
        if not in_ring or in_middle != (k < 4):
            problems.append(f'compartment {k} place {i} is not in its {"lens" if k < 4 else "crescent"}')

    # Every band clear of every other but where the middle ring crosses a small one.
    def gap(a, b):
        return min(shapes.distance_to(p, b, closed=True) for p in a) - 2 * BAND
    for k in range(4):
        g = gap(rings[k], rings[(k + 1) % 4])
        if g < 0.03:
            problems.append(f'rings {k} and {(k + 1) % 4} are {g:.3f} m apart')
        g = gap(rings[k], edging)
        if g < 0.03:
            problems.append(f'ring {k} is {g:.3f} m from the edging')
    g = gap(middle, edging)
    if g < 0.03:
        problems.append(f'the middle ring is {g:.3f} m from the edging')
    room = min(math.sqrt(x * x + z * z) for ring in rings for x, z in ring) - BAND - BASIN
    if room < 0.05:
        problems.append(f'the basin has {room:.3f} m round it')

    # Graded outward: in every compartment the heart is nearest the middle of
    # the plot, the point farthest, and the two sides between.
    def out(p):
        return math.sqrt(p.x * p.x + p.z * p.z)
    for k in range(8):
        block = [p for p in layout.places if p.tags['compartment'] == k]
        if not out(block[0]) < out(block[1]) == out(block[2]) < out(block[3]):
            problems.append(f'compartment {k} is not graded outward')
    if problems:
        raise SystemExit('knot_garden_rings:\n  ' + '\n  '.join(problems))
