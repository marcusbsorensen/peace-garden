"""The Glasshouse as a colour wheel: a round house, its staging a ring of 24 pots, a round bed in the middle.

Option A of the layouts Marcus approved on 2 October 2026. The staging runs
round the inside of the house as one ring of pots 0.43 m apart, two to each of
the twelve hue bands, band 0 just past the door going round toward `x-` and
band 11 just before it. The door is in the gap between the two ends, at `z+`,
which is the green these plants avoid. The border is a round bed of eight in
the middle, under the dome's crown.

Places are the staging's pots in the order a pale plant is offered them (the
pot opposite the door, then farthest-first), then the border's in the order it
fills (the middle of the bed, then farthest-first). A band's earlier pot is its
row 0. Every outline wanders by hand: the house's wall outward only, by up to
4 cm, so nothing stands under a roof lower than `Glasshouse.roof`; the staging
by a centimetre either way, so a pot is still on it; the bed by 4 cm.
"""
from places import Layout, order, sample, shapes
from places.numbers import cos_sin, wobble, key

FIELDS = ('bed', 'index', 'row')
NUDGES = 1
JS = True
MIN_SPACING = 0.40

# The numbers SeedCore's `Glasshouse` holds, which `GlasshouseTests` checks
# this table against: where the door is, how big the house is, where the ring
# of pots runs and how far apart they stand.
DOOR = 0.25            # a turn from x+ toward z+: the door faces z+
HOUSE = 2.20           # the wall's radius, at its innermost
STAGING = 1.80         # the ring of pots
POT_GAP = 0.43         # from one pot to the next, along the ring
END = 0.12             # from the last pot to the end of the staging
POTS = 24
BED = 0.85             # the round bed in the middle
BORDER = 8

STAGING_BED, BORDER_BED = 0, 1


def round_loop(radius, reach, seed, wavelength, n, outward_only=False):
    """A circle laid by hand: point i at turn i/n, its radius wandering by up
    to `reach` (outward only, if asked) with no seam where it meets itself.
    Indexed by turn, so whatever reads it knows how far round each point is."""
    circumference = 2 * 3.141592653589793 * radius
    salt = key('glasshouse', seed)
    out = []
    for i in range(n):
        w = wobble(circumference * i / n, wavelength, salt, period=circumference)
        r = radius + (reach * (1 + w) / 2 if outward_only else reach * w)
        c, s = cos_sin(i / n)
        out.append((r * c, r * s))
    return out


def staging_line():
    """The staging's middle line, from the end by band 0 round to the end by
    band 11: long enough for 24 pots at `POT_GAP` and `END` beyond the last at
    each end, centred on the turn opposite the door, its radius wandering a
    centimetre either way."""
    length = (POTS - 1) * POT_GAP + 2 * END
    span = length / (2 * 3.141592653589793 * STAGING)
    start = DOOR + 0.5 - span / 2
    n = 160
    salt = key('glasshouse', 'staging')
    out = []
    for i in range(n + 1):
        t = start + span * i / n
        w = wobble(length * i / n, 1.4, salt)
        r = STAGING + 0.010 * w
        c, s = cos_sin(t)
        out.append((r * c, r * s))
    return out


def build(nudge):
    house = round_loop(HOUSE, 0.04, 'house', 1.5, 192, outward_only=True)
    bed = round_loop(BED, 0.04, 'bed', 0.9, 96)
    line = staging_line()
    length = shapes.length(line)

    # The 24 pots along the line by length, the first and last `END` from its
    # ends, so the gap between pots comes out at `POT_GAP` give or take the
    # line's wander. Band b is pots 2b and 2b + 1, counted from band 0's end.
    pots = sample.along(line, POTS, start=END, end=length - END, ends=True)
    band = {pots[i]: i // 2 for i in range(POTS)}
    opposite = shapes.point_at(line, length / 2)[0]
    offered = order.focal_first(pots, opposite)
    seen = {}
    staging = []
    for p in offered:
        b = band[p]
        row = seen.get(b, 0)
        seen[b] = row + 1
        staging.append((p, b, row))

    # The bed: eight places as blue noise in the round bed, the one nearest
    # its middle first, then farthest-first.
    places = sample.blue_noise(bed, 0.52, seed=('glasshouse', 'border'), count=BORDER, margin=0.16,
                               start=(0.0, 0.0))
    border = order.focal_first(places, (0.0, 0.0))

    layout = Layout()
    for p, b, row in staging:
        layout.add([p], bed=STAGING_BED, index=b, row=row)
    for k, p in enumerate(border):
        layout.add([p], bed=BORDER_BED, index=k, row=0)
    return (layout
            .curve('house', house)
            .curve('staging', line, closed=False)
            .curve('bed', bed))
