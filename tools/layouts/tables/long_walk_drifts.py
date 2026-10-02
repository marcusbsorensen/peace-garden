"""The Long Walk's borders as interlocking drifts: twelve slanting lenses a plot.

Each border's twenty-four places stand in six long, thin lenses of five,
three, five, three, five and three places, slanting from the hedge (the
lens's back, up the walk) to the path's edge (its tip, down the walk) and
overlapping the next like slates. The two borders interlock: a lens of five
on one side faces a lens of three on the other. Marcus chose this on
2 October 2026 (`design/garden-layouts-2026-10-02/RESEARCH.md`, the Long Walk,
option A), with each plot graded cool at its ends and hot in its middle.

`side` is -1 for the border at x- and 1 for the one at x+. `lens` is the
lens's rank from the plot's middle: lens 0 is the one a warm colour claims
first, lens 11 the one a cool colour claims first, so the places are listed
middle lens first. `tier` is 0 at the front of a border, 1 in the middle and
2 at the back, read off how far the place stands from the path: a lens's back
is back tier and its tip front tier, so nothing stands in front of something
shorter by depth. Within a lens its places run from its middle outward,
farthest-first. The curves are each lens's outline, `lens0` to `lens11` by
rank, and each border's front edge, which follows the lenses' tips.
"""
import math

from places import Layout, shapes, order
from places.numbers import Rng

FIELDS = ('side', 'lens', 'tier')
JS = True
MIN_SPACING = 0.33
BOUND = 2.45

# Lens sizes from the head of the plot (z-) to its foot, side by side.
COUNTS = {-1: (5, 3, 5, 3, 5, 3), 1: (3, 5, 3, 5, 3, 5)}
# Which tier each place of a lens is, from its back to its tip.
TIERS = {5: (2, 1, 1, 0, 0), 3: (2, 1, 0)}

BACK = 2.02      # how far out a lens's back stands from the middle of the path
TIP = 0.84       # and its tip
REACH = 0.66     # half a lens's length along the walk
FIRST = -1.74    # the middle of the lens at the head of the plot, in z
STEP = 0.696     # from one lens's middle to the next


def lens_axis(side, k):
    """A lens's spine, back to tip, bowed a little so no lens is a ruled line."""
    rng = Rng('long-walk-lens', side, k)
    zc = FIRST + STEP * k + rng.uniform(-0.03, 0.03)
    back = (side * (BACK + rng.uniform(-0.03, 0.03)), zc - REACH)
    tip = (side * (TIP + rng.uniform(-0.02, 0.02)), zc + REACH)
    mid = ((back[0] + tip[0]) / 2, (back[1] + tip[1]) / 2)
    # Bowed toward the head of the walk by a few centimetres, across the spine.
    dx, dz = tip[0] - back[0], tip[1] - back[1]
    bow = 0.05 + rng.uniform(-0.015, 0.015)
    length = math.sqrt(dx * dx + dz * dz)
    nx, nz = dz / length, -dx / length
    if nz > 0:
        nx, nz = -nx, -nz
    mid = (mid[0] + nx * bow, mid[1] + nz * bow)
    return zc, shapes.spline([back, mid, tip], closed=False, per=16)


def lens_places(side, k, count, spine):
    """Places along a lens's spine, back to tip, a little either side of it."""
    rng = Rng('long-walk-place', side, k)
    total = shapes.length(spine)
    ts = (0.10, 0.30, 0.50, 0.70, 0.90) if count == 5 else (0.15, 0.50, 0.85)
    out = []
    for j, t in enumerate(ts):
        (x, z), (tx, tz) = shapes.point_at(spine, total * t)
        off = (0.05 if count == 5 else 0.03) * (1 if j % 2 else -1) + rng.uniform(-0.015, 0.015)
        out.append((x - tz * off, z + tx * off))
    return out


def lens_outline(side, k, spine, count):
    """A lens's outline: its spine fattened in the middle, tapering to points
    at both ends, its edge wandering a little."""
    total = shapes.length(spine)
    half = 0.21 if count == 5 else 0.17
    pts = shapes.resample(spine, 0.05)
    n = len(pts)
    left, right = [], []
    for i, p in enumerate(pts):
        u = i / (n - 1)
        w = half * math.sqrt(4 * u * (1 - u)) + 0.02
        nx, nz = shapes.normal(pts, i)
        left.append((p[0] + nx * w, p[1] + nz * w))
        right.append((p[0] - nx * w, p[1] - nz * w))
    loop = left + list(reversed(right))
    # Rounded past each end of the spine, so a lens does not end on a point.
    return shapes.wander(shapes.spline(shapes.resample(loop, 0.12), per=4), 0.02, ('lens', side, k),
                         wavelength=0.5)


def build(nudge):
    lenses = []
    for side in (-1, 1):
        for k, count in enumerate(COUNTS[side]):
            zc, spine = lens_axis(side, k)
            places = lens_places(side, k, count, spine)
            tiers = TIERS[count]
            lenses.append(dict(side=side, k=k, zc=zc, count=count, spine=spine,
                               places=list(zip(places, tiers))))
    # Middle first: by how far the lens's middle is from the plot's, the
    # border at x- taking the first of each pair and the other the second, so
    # a warm colour's first two lenses face each other across the path.
    def rank(lens):
        far = round(abs(lens['zc']) / STEP)
        return (far, lens['side'] * (1 if lens['zc'] < 0 else -1))
    lenses.sort(key=rank)

    layout = Layout()
    for rank_, lens in enumerate(lenses):
        middle = shapes.point_at(lens['spine'], shapes.length(lens['spine']) / 2)[0]
        points = [p for p, _ in lens['places']]
        tier_of = {p: t for p, t in lens['places']}
        for p in order.focal_first(points, middle):
            layout.add([p], side=lens['side'], lens=rank_, tier=tier_of[p])
        layout.curve(f'lens{rank_}', lens_outline(lens['side'], lens['k'], lens['spine'], lens['count']))
    return layout
