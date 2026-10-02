"""An example no area uses: a bed, a pool and an arc, to show the generator working.

The bed's outline wanders; nine places stand in it as blue noise, the one
nearest its middle first and then farthest-first. Seven stand in a round
pool on a sunflower from its middle. Five stand along an arc round the pool,
the arc's middle first. Two feature variants, the pool moved between them.
"""
from places import Layout, shapes, sample, order

FIELDS = ('kind',)
NUDGES = 2
JS = True
MIN_SPACING = 0.30

BED, POOL, EDGE = 0, 1, 2


def build(nudge):
    pool_at = [(1.05, -0.95), (0.80, -1.20)][nudge]

    bed = shapes.blob((-0.80, 0.50), (1.40, 1.15), seed=('example-bed', nudge), wander_by=0.08, turn=0.06)
    pool = shapes.blob(pool_at, (0.75, 0.70), seed=('example-pool', nudge), wander_by=0.04)
    edge = shapes.arc(pool_at, 1.20, 0.02, 0.23)

    in_bed = sample.blue_noise(bed, 0.60, seed=('example-bed', nudge), count=9, margin=0.15)
    in_pool = sample.sunflower(pool_at, 0.20, 7, region=pool, margin=0.10)
    on_edge = sample.along(edge, 5, ends=True)

    return (Layout()
            .add(order.focal_first(in_bed, shapes.centroid(bed)), kind=BED)
            .add(in_pool, kind=POOL)
            .add(order.focal_first(on_edge, shapes.point_at(edge, shapes.length(edge) / 2)[0]), kind=EDGE)
            .curve('bed', bed)
            .curve('pool', pool)
            .curve('edge', edge, closed=False))
