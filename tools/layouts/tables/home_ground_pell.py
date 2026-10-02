"""The Home Ground's places for a bed sown with rosettes (`Pell`), in each of its three beds.

The earth's skin: rosettes, three across at 0.38 m and ten rows 0.40 m
apart, thirty a bed. The rows follow the bed's line, which sways in a lazy S
(`_home_ground.py` says how), and run square to it. Bed by bed, west to east
as the table draws it, and in each bed in `HomeGround.Slot`'s order: from the
north end, row by row, west to east along each row. A bed fills from both
ends, so this is the rule's order, not a fill order.
"""
from places import Layout

from tables._home_ground import rows

FIELDS = ('bed', 'index')
NUDGES = 1
MIN_SPACING = 0.32


def build(nudge):
    layout = Layout()
    for bed in range(3):
        for index, p in enumerate(rows(bed, 'pell')):
            layout.add([p], bed=bed, index=index)
    return layout
