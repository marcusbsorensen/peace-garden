"""Fill orders: the order a table offers its free places in.

**Fill so every count looks finished** (Marcus, 2 October 2026; RESEARCH.md
§*Three moves for every area*, 1): the focal place first, then the place
farthest from those already taken, or the next point of a sunflower. A rule
takes the first free place in table order that it may stand in, so a plot of
three plants is three spread round its focal place, never three in a row from
one end. The order is worked out here, once, and written into the table:
nothing about it is computed at run time.

Every function takes points as (x, z) tuples, or anything whose [0] and [1]
are x and z (a `Place`), and returns the same objects reordered.
"""


def _d2(a, b):
    dx, dz = a[0] - b[0], a[1] - b[1]
    return dx * dx + dz * dz


def nearest(points, to):
    """The index of the point nearest `to`; the lowest index on a tie."""
    best, at = None, 0
    for i, p in enumerate(points):
        d = _d2(p, to)
        if best is None or d < best:
            best, at = d, i
    return at


def farthest_first(points, first=0, quantum=1e-9):
    """**Farthest-first**: `points[first]`, then each time the point whose
    nearest already-taken point is farthest away. Every prefix is then as
    evenly spread over the table's places as a prefix can be.

    Distances are compared in steps of `quantum` square metres, so two places
    an equal distance away by design (a symmetric arc) go in the order they
    were given, rather than by whichever the last bit of a float favours.
    """
    n = len(points)
    if n == 0:
        return []
    order = [first]
    left = [i for i in range(n) if i != first]
    near = {i: _d2(points[i], points[first]) for i in left}
    while left:
        best = max(left, key=lambda i: (round(near[i] / quantum), -i))
        order.append(best)
        left.remove(best)
        for i in left:
            d = _d2(points[i], points[best])
            if d < near[i]:
                near[i] = d
    return [points[i] for i in order]


def focal_first(points, focal, quantum=1e-9):
    """The place nearest `focal` first, then farthest-first: the move Marcus
    chose, in one call."""
    return farthest_first(points, nearest(points, focal), quantum)


def centre_first(points, centre=(0.0, 0.0)):
    """Nearest `centre` first, outward; a tie keeps the given order. For a
    sunflower that is its own order, which is the fill order a spiral wants,
    and it stays so after the points are turned or thinned."""
    return [p for _, _, p in sorted((_d2(p, centre), i, p) for i, p in enumerate(points))]


def within(points, group, then):
    """Reorder each group's places by `then` (a function of a list, such as
    `lambda g: focal_first(g, focal)`), keeping the groups where they first
    appear. For a rule that picks a group first — a guild, a coupe, a drill —
    and then the first free place in it, only each group's own order counts."""
    groups = {}
    for p in points:
        groups.setdefault(group(p), []).append(p)
    out = []
    for members in groups.values():
        out.extend(then(members))
    return out


def interleave(*lists):
    """One from each list in turn, for a table whose rule fills several groups
    level with each other, as the Crossing's quarters fill."""
    out = []
    for i in range(max((len(l) for l in lists), default=0)):
        for l in lists:
            if i < len(l):
                out.append(l[i])
    return out
