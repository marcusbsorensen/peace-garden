"""The Home Ground's three beds: where each one's middle is, and the line it runs along.

Lazy beds that follow the land (Marcus, 2 October 2026; RESEARCH.md, option
A): three beds 1.2 m wide, their middles 1.60 m apart with paths of 0.40 m
between, from z = -2.1 (north) to 2.1, swaying together in a lazy S 0.15 m
either way, each straying a little off it as a spade leaves a ridge. The curves `bed0`, `bed1` and `bed2` are each bed's
middle, west to east as the table draws it, north end first; the page raises
a bed 0.6 m either side of its line. One place to a bed, its middle, for the
bed's number. A plot is drawn as it stands or mirrored, by its number
(`HomeGround.variants`), which sways the beds the other way.
"""
from places import Layout, shapes

from tables._home_ground import line

FIELDS = ('bed',)
NUDGES = 1
JS = True


def build(nudge):
    layout = Layout()
    for bed in range(3):
        middle = line(bed)
        (x, z), _ = shapes.point_at(middle, shapes.length(middle) / 2)
        layout.add([(x, z)], bed=bed)
        layout.curve(f'bed{bed}', middle, closed=False)
    return layout
