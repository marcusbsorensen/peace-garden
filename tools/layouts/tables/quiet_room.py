"""The Quiet Garden's asymmetric room: one, five, three and one, the pool off the middle toward the bench.

Marcus, 2 October 2026 (RESEARCH.md, *The Quiet Garden*, option A). The ten
dry places of a room stand as:

- the specimen beside the bench (group 0), where it has stood since 21 September;
- a group of five in the far corner, across the water: what the bench looks at (group 1);
- a group of three along the side to the bench's left, a third of the way down it (group 2);
- one plant alone across the lawn from the five, which repeats its colour: the echo (group 3).

The pool lies off the middle toward the bench, longer across the bench's view
than along it, with a bay on the bench's side that three stepping stones lead
into from the seat (`stones`). Its two places (group 4) are the pool's own and
lie along its length; the live garden never sends this area a lily, so they
stay empty.

Within a group the places are listed nearest the corner first, then
farthest-first, and `stand` says which are the back of the group (1) and which
its arms (0): the five has two at the back, the three one. A rule that takes
the first free place of the stand it wants leaves every count of a group
looking like a clump rather than a row begun at one end. The room is turned
and mirrored by its plot's number, eight ways, so no two rooms side by side
are laid alike.
"""
import math

from places import Layout, shapes, sample, order
from places.numbers import cos_sin, bump, turn_of

FIELDS = ('group', 'stand')
NUDGES = 1
JS = True

SPECIMEN, FIVE, THREE, ECHO, POOL = 0, 1, 2, 3, 4
ARM, BACK = 0, 1

# The hedge's inner face, `QuietGarden.hedgeFrom`, and how far in from it the
# plants at its foot stand: `atTheHedge`, 1.95.
HEDGE = 2.30
AT_THE_HEDGE = 1.95
# Where the bench stands, `QuietGarden.benchSpot`, on its corner's diagonal.
BENCH = (-1.72, -1.72)
# The specimen, where it has stood since 21 September: at the foot of the
# hedge on the bench's own side, nearer the corner than a group's arm.
SPECIMEN_AT = (-1.95, -0.95)

# The pool: its middle, how long and how wide, and the bay on the bench's
# side. Long across the line from the bench, so the bench looks across it.
POOL_AT = (-0.30, -0.26)
POOL_RADII = (1.06, 0.66)
POOL_TURN = -0.125
BAY = 0.30
IN_THE_WATER = 0.45


def pool():
    """The pool's outline: an ellipse whose edge wanders, pressed in on the
    bench's side into a bay."""
    toward_bench = turn_of(BENCH[0] - POOL_AT[0], BENCH[1] - POOL_AT[1])
    ring = shapes.ellipse(POOL_AT, POOL_RADII, n=144, turn=POOL_TURN)
    out = []
    for x, z in ring:
        dx, dz = x - POOL_AT[0], z - POOL_AT[1]
        t = turn_of(dx, dz)
        d = abs(t - toward_bench)
        d = min(d, 1 - d)
        k = 1 - BAY * bump(d, 0.17)
        out.append((POOL_AT[0] + dx * k, POOL_AT[1] + dz * k))
    return shapes.wander(out, 0.04, seed=('quiet-pool',), wavelength=0.8)


def stones(rim):
    """Three stepping stones from the seat to the water's edge, a stride
    apart and a little off the straight line, as stones set by hand are."""
    toward = (POOL_AT[0] - BENCH[0], POOL_AT[1] - BENCH[1])
    length = math.sqrt(toward[0] * toward[0] + toward[1] * toward[1])
    ux, uz = toward[0] / length, toward[1] / length
    # Where the line from the bench meets the water.
    s = 0.0
    while shapes.distance_to((BENCH[0] + ux * s, BENCH[1] + uz * s), rim, closed=True) > 0.02 \
            and not shapes.inside((BENCH[0] + ux * s, BENCH[1] + uz * s), rim):
        s += 0.01
    out = []
    for k, (along, aside) in enumerate(((0.40, 0.05), (0.40 + (s - 0.58) / 2, -0.06), (s - 0.18, 0.04))):
        out.append((BENCH[0] + ux * along - uz * aside, BENCH[1] + uz * along + ux * aside))
    return out


def clump(centre, radii, turn, count, spacing, seed, corner, backs):
    """A group of `count` in a blob at the hedge's foot: blue noise, the
    place nearest the corner first, then farthest-first; the `backs` nearest
    the corner are its back."""
    region = shapes.blob(centre, radii, seed=seed, wander_by=0.05, turn=turn)
    pts = sample.blue_noise(region, spacing, seed=seed, count=count, margin=0.04,
                            keep=lambda p: max(abs(p[0]), abs(p[1])) <= AT_THE_HEDGE)
    ordered = order.focal_first(pts, corner)
    by_corner = sorted(ordered, key=lambda p: (p[0] - corner[0]) * (p[0] - corner[0])
                       + (p[1] - corner[1]) * (p[1] - corner[1]))
    back = set(by_corner[:backs])
    return [(p, BACK if p in back else ARM) for p in ordered]


def build(nudge):
    rim = pool()
    # The two groups' ground: wide enough that no two of a group stand closer
    # than 0.6 m before their nudge, the room a clump's plants need not to
    # stand in one another.
    five = clump((1.35, 1.35), (1.10, 0.72), -0.125, 5, 0.70, ('quiet-five',), (HEDGE, HEDGE), 2)
    three = clump((1.45, -0.95), (0.62, 0.66), 0.0, 3, 0.72, ('quiet-three', 2), (HEDGE, -0.98), 1)
    echo = [(-1.70, 1.36)]
    c, s = cos_sin(POOL_TURN)
    water = [(POOL_AT[0] + c * IN_THE_WATER, POOL_AT[1] + s * IN_THE_WATER),
             (POOL_AT[0] - c * IN_THE_WATER, POOL_AT[1] - s * IN_THE_WATER)]
    dry = [SPECIMEN_AT] + [p for p, _ in five] + [p for p, _ in three] + echo
    for p in dry:
        if shapes.distance_to(p, rim, closed=True) < 0.6 or shapes.inside(p, rim):
            raise SystemExit(f'quiet_room: {p} is within 0.6 m of the water')
        if max(abs(p[0]), abs(p[1])) > AT_THE_HEDGE + 0.02:
            raise SystemExit(f'quiet_room: {p} is in the hedge')
    for p in water:
        if not shapes.inside(p, rim) or shapes.distance_to(p, rim, closed=True) < 0.3:
            raise SystemExit(f'quiet_room: {p} is not well in the water')
    layout = Layout()
    layout.add([SPECIMEN_AT], group=SPECIMEN, stand=ARM)
    for p, stand in five:
        layout.add([p], group=FIVE, stand=stand)
    for p, stand in three:
        layout.add([p], group=THREE, stand=stand)
    layout.add(echo, group=ECHO, stand=ARM)
    layout.add(water, group=POOL, stand=ARM)
    layout.curve('pool', rim)
    layout.curve('stones', stones(rim), closed=False)
    return layout
