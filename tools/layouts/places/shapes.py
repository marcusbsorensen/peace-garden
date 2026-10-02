"""Curves on the ground: outlines, arcs, splines, and what can be asked of them.

A curve is a list of (x, z) points in metres from the middle of the plot,
north (z-) up the page. A closed curve does not repeat its first point at the
end. Nothing here is a straight line once it is drawn (Marcus's rule): an
outline is a smooth curve through its points, made fine enough that its
segments are shorter than anything planted beside them.

Every function is deterministic and uses `numbers` for its turning, so the
generator's output is the same on every machine (`numbers.py` says why).
"""
import math

from .numbers import cos_sin, wobble, key


# --------------------------------------------------------------------------
# Making curves

def ellipse(centre, radii, n=96, turn=0.0):
    """A closed ellipse, `radii` (along x, along z) before it is turned by
    `turn` (a fraction of a turn). Points run from x+ toward z+."""
    cx, cz = centre
    rx, rz = radii
    tc, ts = cos_sin(turn)
    out = []
    for i in range(n):
        c, s = cos_sin(i / n)
        x, z = rx * c, rz * s
        out.append((cx + x * tc - z * ts, cz + x * ts + z * tc))
    return out


def circle(centre, radius, n=96):
    return ellipse(centre, (radius, radius), n)


def arc(centre, radius, start, end, spacing=0.04):
    """An open arc of a circle from `start` to `end`, in turns (0 is x+, a
    quarter z+); `end` below `start` runs the other way."""
    span = end - start
    length = abs(span) * 2 * math.pi * radius
    n = max(2, int(math.ceil(length / spacing)) + 1)
    cx, cz = centre
    out = []
    for i in range(n):
        c, s = cos_sin(start + span * i / (n - 1))
        out.append((cx + radius * c, cz + radius * s))
    return out


def spline(points, closed=True, per=12):
    """A Catmull-Rom curve through `points`, `per` points to each span: the
    smooth way through a few control points an outline is drawn from."""
    n = len(points)
    if n < 2:
        return list(points)
    spans = range(n) if closed else range(n - 1)
    out = []
    for i in spans:
        p0 = points[(i - 1) % n] if closed else points[max(i - 1, 0)]
        p1 = points[i]
        p2 = points[(i + 1) % n]
        p3 = points[(i + 2) % n] if closed else points[min(i + 2, n - 1)]
        for j in range(per):
            t = j / per
            t2, t3 = t * t, t * t * t
            out.append(tuple(0.5 * (2 * p1[k] + (p2[k] - p0[k]) * t
                                    + (2 * p0[k] - 5 * p1[k] + 4 * p2[k] - p3[k]) * t2
                                    + (3 * p1[k] - p0[k] - 3 * p2[k] + p3[k]) * t3)
                             for k in range(2)))
    if not closed:
        out.append(tuple(points[-1]))
    return out


def wander(curve, amount, seed, wavelength=0.9, closed=True):
    """Each point pushed along the curve's normal by up to `amount` metres
    either way, by smooth noise along its length: a hand-cut edge. On a
    closed curve the wander meets itself without a seam."""
    total = length(curve, closed)
    s = 0.0
    out = []
    n = len(curve)
    salt = key('wander', seed)
    for i, p in enumerate(curve):
        if i:
            s += _dist(curve[i - 1], p)
        nx, nz = normal(curve, i, closed)
        w = wobble(s, wavelength, salt, period=total if closed else None)
        out.append((p[0] + nx * amount * w, p[1] + nz * amount * w))
    return out


def blob(centre, radii, seed, wander_by=0.05, wavelength=0.9, n=120, turn=0.0):
    """An organic outline: an ellipse whose edge wanders by up to `wander_by`.
    For anything less regular, give `spline` control points and `wander` it."""
    return wander(ellipse(centre, radii, n, turn), wander_by, seed, wavelength)


def offset(curve, by, closed=False):
    """The curve moved sideways by `by` metres, to its left as it runs (the
    side x+ turns to z+): a verge beside a ride, a row beside a hedge."""
    out = []
    for i, p in enumerate(curve):
        nx, nz = normal(curve, i, closed)
        out.append((p[0] - nx * by, p[1] - nz * by))
    return out


def scale(curve, k, about=(0.0, 0.0)):
    ax, az = about
    return [(ax + (x - ax) * k, az + (z - az) * k) for x, z in curve]


def move(curve, dx, dz):
    return [(x + dx, z + dz) for x, z in curve]


def turned(curve, turn, about=(0.0, 0.0)):
    """The curve turned by `turn` (a fraction of a turn) about `about`."""
    c, s = cos_sin(turn)
    ax, az = about
    return [(ax + (x - ax) * c - (z - az) * s, az + (x - ax) * s + (z - az) * c) for x, z in curve]


# --------------------------------------------------------------------------
# Asking things of curves

def _dist(a, b):
    dx, dz = b[0] - a[0], b[1] - a[1]
    return math.sqrt(dx * dx + dz * dz)


def _total(values):
    """Added left to right. Not `sum()`, which from Python 3.12 compensates
    for rounding and so gives a different last bit from earlier Pythons."""
    out = 0.0
    for v in values:
        out += v
    return out


def length(curve, closed=False):
    total = _total(_dist(a, b) for a, b in zip(curve, curve[1:]))
    if closed and len(curve) > 1:
        total += _dist(curve[-1], curve[0])
    return total


def tangent(curve, i, closed=False):
    """The unit direction the curve runs at its i-th point."""
    n = len(curve)
    a = curve[(i - 1) % n] if closed else curve[max(i - 1, 0)]
    b = curve[(i + 1) % n] if closed else curve[min(i + 1, n - 1)]
    tx, tz = b[0] - a[0], b[1] - a[1]
    m = math.sqrt(tx * tx + tz * tz) or 1.0
    return tx / m, tz / m


def normal(curve, i, closed=False):
    """The unit normal at the i-th point: the tangent turned a quarter back,
    so for a closed curve that runs from x+ toward z+ it points outward."""
    tx, tz = tangent(curve, i, closed)
    return tz, -tx


def point_at(curve, s, closed=False):
    """The point `s` metres along the curve, and the unit direction there."""
    pts = list(curve) + ([curve[0]] if closed else [])
    acc = 0.0
    last = len(pts) - 2
    for i in range(last + 1):
        a, b = pts[i], pts[i + 1]
        seg = _dist(a, b)
        if acc + seg >= s or i == last:
            t = 0.0 if seg == 0 else min(1.0, max(0.0, (s - acc) / seg))
            m = seg or 1.0
            return ((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t),
                    ((b[0] - a[0]) / m, (b[1] - a[1]) / m))
        acc += seg
    return tuple(pts[-1]), (1.0, 0.0)


def resample(curve, spacing, closed=False):
    """Points every `spacing` metres along the curve (the last span of an open
    curve may be shorter)."""
    total = length(curve, closed)
    n = max(2, int(round(total / spacing)))
    if closed:
        return [point_at(curve, total * i / n, True)[0] for i in range(n)]
    return [point_at(curve, total * i / n)[0] for i in range(n)] + [tuple(curve[-1])]


def inside(p, loop):
    """Whether a point is inside a closed curve: the even-odd rule, as
    `Organic.contains` asks it."""
    x, z = p
    hit = False
    j = len(loop) - 1
    for i in range(len(loop)):
        ax, az = loop[i]
        bx, bz = loop[j]
        if (az > z) != (bz > z) and x < (bx - ax) * (z - az) / (bz - az) + ax:
            hit = not hit
        j = i
    return hit


def distance_to(p, curve, closed=False):
    """How far a point is from the nearest part of a curve."""
    pts = list(curve) + ([curve[0]] if closed else [])
    best = float('inf')
    px, pz = p
    for a, b in zip(pts, pts[1:]):
        ax, az = b[0] - a[0], b[1] - a[1]
        m = ax * ax + az * az
        t = 0.0 if m == 0 else max(0.0, min(1.0, ((px - a[0]) * ax + (pz - a[1]) * az) / m))
        dx, dz = px - a[0] - ax * t, pz - a[1] - az * t
        best = min(best, dx * dx + dz * dz)
    return math.sqrt(best)


def centroid(loop):
    """The middle of the area a closed curve holds."""
    area2 = cx = cz = 0.0
    n = len(loop)
    for i in range(n):
        x0, z0 = loop[i]
        x1, z1 = loop[(i + 1) % n]
        cross = x0 * z1 - x1 * z0
        area2 += cross
        cx += (x0 + x1) * cross
        cz += (z0 + z1) * cross
    if area2 == 0:
        return (_total(p[0] for p in loop) / n, _total(p[1] for p in loop) / n)
    return (cx / (3 * area2), cz / (3 * area2))


def area(loop):
    """The area a closed curve holds, in square metres."""
    n = len(loop)
    return abs(_total(loop[i][0] * loop[(i + 1) % n][1] - loop[(i + 1) % n][0] * loop[i][1]
                   for i in range(n))) / 2
