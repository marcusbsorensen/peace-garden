"""Where places can go: blue noise in an outline, a sunflower, points along a curve.

Each returns a list of (x, z). **None of these orders is a fill order**; give
the list to `order` for that. The one exception is `sunflower`, whose points
come centre first, which is already the order a spiral should fill in.
"""
import math

from .numbers import Rng, cos_sin, GOLDEN
from . import shapes


def _allowed(region, margin, keep):
    def ok(p):
        if region is not None:
            if not shapes.inside(p, region):
                return False
            if margin > 0 and shapes.distance_to(p, region, closed=True) < margin:
                return False
        return keep is None or keep(p)
    return ok


def blue_noise(region, spacing, seed, count=None, margin=0.0, keep=None, start=None,
               tries=30, shrink=0.97):
    """**Bridson's Poisson-disc sampling inside a closed outline**: points no
    closer than `spacing` to each other, spread evenly with no lattice
    (Bridson 2007; RESEARCH.md §*Blue noise*).

    - `margin`: how far every point stays inside the outline's edge.
    - `keep(p)`: anything else a point must satisfy (clear of a ride, of a
      tree's trunk), True to keep it.
    - `start`: where the first point goes; the outline's centroid if it is
      allowed there, else the first allowed point of a fine scan.
    - `count`: exactly this many. The spacing shrinks by `shrink` until at
      least that many fit, and the surplus is trimmed farthest-first from the
      point nearest the middle, so what is left is still evenly spread. The
      spacing it settled on is in the result's `spacing` attribute.

    Returns a list of (x, z) with a `spacing` attribute.
    """
    ok = _allowed(region, margin, keep)
    r = spacing
    for _ in range(80):
        pts = _bridson(region, ok, r, seed, start, tries)
        if count is None or len(pts) >= count:
            break
        r *= shrink
    else:
        raise ValueError(f'{count} places do not fit in that outline at any spacing above {r:.3f} m')
    if count is not None and len(pts) > count:
        from .order import farthest_first, nearest
        middle = shapes.centroid(region) if region is not None else (0.0, 0.0)
        pts = farthest_first(pts, first=nearest(pts, middle))[:count]
    out = _Points(pts)
    out.spacing = r
    return out


class _Points(list):
    spacing = None


def _bridson(region, ok, r, seed, start, tries):
    rng = Rng('blue-noise', seed)
    if region is not None:
        xs = [p[0] for p in region]
        zs = [p[1] for p in region]
        x0, x1, z0, z1 = min(xs), max(xs), min(zs), max(zs)
    else:
        x0, x1, z0, z1 = -2.6, 2.6, -2.6, 2.6
    cell = r / math.sqrt(2.0)
    grid = {}
    pts = []
    active = []

    def at(p):
        return (math.floor((p[0] - x0) / cell), math.floor((p[1] - z0) / cell))

    def free(p):
        if not (x0 <= p[0] <= x1 and z0 <= p[1] <= z1) or not ok(p):
            return False
        gi, gj = at(p)
        for i in range(gi - 2, gi + 3):
            for j in range(gj - 2, gj + 3):
                q = grid.get((i, j))
                if q is not None:
                    dx, dz = q[0] - p[0], q[1] - p[1]
                    if dx * dx + dz * dz < r * r:
                        return False
        return True

    def add(p):
        pts.append(p)
        active.append(p)
        grid[at(p)] = p

    first = start
    if first is None and region is not None:
        c = shapes.centroid(region)
        first = c if free(c) else None
    if first is None or not free(first):
        steps = 60
        first = None
        for j in range(steps + 1):
            for i in range(steps + 1):
                p = (x0 + (x1 - x0) * i / steps, z0 + (z1 - z0) * j / steps)
                if free(p):
                    first = p
                    break
            if first is not None:
                break
        if first is None:
            return []
    add(first)
    while active:
        i = rng.below(len(active))
        a = active[i]
        for _ in range(tries):
            d = r * (1 + rng.unit())
            c, s = cos_sin(rng.unit())
            p = (a[0] + d * c, a[1] + d * s)
            if free(p):
                add(p)
                break
        else:
            active.pop(i)
    return pts


def sunflower(centre, c, count, turn=0.0, region=None, margin=0.0, keep=None, limit=20000):
    """**Vogel's sunflower**: point k at radius c * sqrt(k + 1/2) and k golden
    angles round (Vogel 1979). Every prefix is evenly spread and centred, and
    adding a point never moves one: the garden's own rule that a plant never
    moves. Neighbours stand about 1.8 c apart.

    Points outside `region` (less `margin`) or refused by `keep` are skipped,
    so the spiral can fill a pond of any shape from its deepest point. Returns
    the first `count` kept, **centre first**, which is their fill order.
    """
    ok = _allowed(region, margin, keep)
    cx, cz = centre
    out = []
    for k in range(limit):
        rad = c * math.sqrt(k + 0.5)
        cc, ss = cos_sin(turn + k * GOLDEN)
        p = (cx + rad * cc, cz + rad * ss)
        if ok(p):
            out.append(p)
            if len(out) == count:
                return out
    raise ValueError(f'only {len(out)} of {count} sunflower points fit')


def along(curve, count, closed=False, start=0.0, end=None, offset=0.0, ends=False):
    """`count` points evenly spaced along a curve by length, from `start` to
    `end` metres along it (the whole curve by default), each moved `offset`
    metres to the curve's left (`shapes.offset`). On an open stretch the points
    sit in the middles of `count` equal spans, unless `ends` puts the first and
    last on its ends; on a whole closed curve they go all the way round."""
    total = shapes.length(curve, closed)
    end = total if end is None else end
    span = end - start
    out = []
    for i in range(count):
        if closed and start == 0.0 and end == total:
            s = span * i / count
        elif ends and count > 1:
            s = start + span * i / (count - 1)
        else:
            s = start + span * (i + 0.5) / count
        (x, z), (tx, tz) = shapes.point_at(curve, s, closed)
        out.append((x - tz * offset, z + tx * offset))
    return out


def ring(centre, radius, count, start=0.0, end=None):
    """`count` points on a circle, exactly: from `start` (turns) all the way
    round, or to `end` with a point on each end."""
    cx, cz = centre
    out = []
    for i in range(count):
        t = start + (i / count if end is None else (end - start) * i / max(1, count - 1))
        c, s = cos_sin(t)
        out.append((cx + radius * c, cz + radius * s))
    return out
