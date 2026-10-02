"""The Home Ground's places for a bed sown with spires (`Cer`), in each of its three beds.

The grain: spires in a stand, three across at 0.40 m and nine rows 0.45 m
apart, twenty-seven a bed. The rows follow the bed's line, which sways in a
lazy S (`_home_ground.py` says how), and run square to it. Bed by bed, west
to east as the table draws it, and in each bed in `HomeGround.Slot`'s order:
from the north end, row by row, west to east along each row. A bed fills from
both ends, so this is the rule's order, not a fill order.
"""
from places import Layout

from tables._home_ground import rows

FIELDS = ('bed', 'index')
NUDGES = 1
# On the inside of a bend a row's outer places draw closer to the next row's:
# 0.348 m at the closest since the sway became 0.15 m (0.387 at 0.10; 0.45
# down a straight bed).
MIN_SPACING = 0.34


def build(nudge):
    layout = Layout()
    for bed in range(3):
        for index, p in enumerate(rows(bed, 'cer')):
            layout.add([p], bed=bed, index=index)
    return layout
