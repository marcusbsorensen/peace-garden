"""What a table's `build(nudge)` returns: places in fill order, and curves."""
from collections import namedtuple

# Places are written to the millimetre: finer than any nudge, and a decimal
# every host reads to the same double.
MM = 1000


class Place(namedtuple('Place', 'x z tags')):
    """One place: x and z in metres from the middle of the plot, and its tags,
    a dict of small integers naming what it is (which coupe, which rank).
    `[0]` and `[1]` are x and z, so `order` takes it as it takes a tuple."""

    def tag(self, name):
        return self.tags[name]


def quantise(v):
    """A length in whole millimetres, as an integer: what the table holds."""
    return int(round(v * MM))


class Layout:
    """The places of one feature variant, in fill order, and the curves its
    drawing needs (an outline, a ride's centreline).

        layout = Layout()
        layout.add(points, coupe=0, kind=1)   # in the order they fill
        layout.curve('glade', outline)        # closed unless told otherwise
    """

    def __init__(self):
        self.places = []
        self.curves = {}

    def add(self, points, **tags):
        """Add points, in the order given, each with these tags (and any a
        `Place` already carries)."""
        for p in points:
            own = dict(p.tags) if isinstance(p, Place) else {}
            own.update(tags)
            self.places.append(Place(p[0], p[1], own))
        return self

    def reorder(self, fn):
        """Put every place in a new order: `fn` takes the list and returns it
        reordered, as `order.farthest_first` and its kin do."""
        before = len(self.places)
        self.places = list(fn(self.places))
        if len(self.places) != before or not all(isinstance(p, Place) for p in self.places):
            raise ValueError('a reorder has to return the same places')
        return self

    def curve(self, name, points, closed=True):
        """A curve the drawing needs, by name: the same name in every feature
        variant."""
        self.curves[name] = (list(points), closed)
        return self
