#!/usr/bin/env python3
"""Plan sketches for the ten areas' layout proposals, 2 October 2026.

    python3 plans.py <out_dir>

Writes <area>-<a|b>-10.png and <area>-<a|b>-full.png for each proposal, and
stats.json with what each proposal's rule does with a thousand arrivals.

Every plant here is invented: a stream of arrivals per area with the habits the
area's genus roots give it (PlantName.roots and Areas.genusHeads), heights and
spreads near the medians WEB-GARDENS.md records, and colour families drawn as
unevenly as the garden draws them. The numbers are indicative, not measured:
a proposal that is chosen is simulated again on SeedCore's own plants.

Plants are blobs coloured by habit, with a dot of their flower's colour family.
Shadows fall away from the page's light, which comes from (-x, +z). North (z-)
is up. Nothing is drawn with a straight line.
"""
import json
import math
import os
import random
import subprocess
import sys

SIDE = 5.2
HALF = SIDE / 2
GOLDEN = math.radians(137.50776)

# --------------------------------------------------------------------------
# Determinism


def key(*parts):
    h = 1469598103934665603
    for part in parts:
        for ch in str(part).encode():
            h ^= ch
            h = (h * 1099511628211) & 0xFFFFFFFFFFFFFFFF
    return h


def rng(*parts):
    return random.Random(key(*parts))


class Wave:
    """Smooth, seeded wander: a few sines with seeded phases, in -1..1."""

    def __init__(self, seed, terms=((1, 1.0), (2, 0.55), (3, 0.35), (5, 0.2), (7, 0.12))):
        r = rng('wave', seed)
        self.terms = [(f, a, r.uniform(0, 2 * math.pi)) for f, a in terms]
        self.norm = sum(a for _, a, _ in self.terms)

    def __call__(self, t):
        return sum(a * math.sin(f * t + p) for f, a, p in self.terms) / self.norm


# --------------------------------------------------------------------------
# Geometry


def dist(a, b):
    return math.hypot(a[0] - b[0], a[1] - b[1])


def rot(p, angle, about=(0.0, 0.0)):
    c, s = math.cos(angle), math.sin(angle)
    x, z = p[0] - about[0], p[1] - about[1]
    return (about[0] + x * c - z * s, about[1] + x * s + z * c)


def loop(cx, cz, rx, rz, seed, amp=0.03, exp=2.0, n=96, turn=0.0, bite=None):
    """A closed wandering outline: a superellipse whose radius wanders."""
    w = Wave(('loop', seed), ((2, 1), (3, .6), (4, .4), (5, .35), (7, .2), (11, .1)))
    pts = []
    for i in range(n):
        t = 2 * math.pi * i / n
        c, s = math.cos(t), math.sin(t)
        x = rx * math.copysign(abs(c) ** (2 / exp), c)
        z = rz * math.copysign(abs(s) ** (2 / exp), s)
        k = 1 + amp * w(t)
        if bite:
            at, depth, width = bite
            d = math.atan2(math.sin(t - at), math.cos(t - at))
            k -= depth * math.exp(-(d / width) ** 2)
        pts.append(rot((cx + x * k, cz + z * k), turn, (cx, cz)))
    return pts


def spline(pts, per=10, closed=False):
    """Dense points along a Catmull-Rom curve through pts."""
    out = []
    n = len(pts)
    rng_i = range(n) if closed else range(n - 1)
    for i in rng_i:
        p0 = pts[(i - 1) % n] if closed else pts[max(i - 1, 0)]
        p1 = pts[i]
        p2 = pts[(i + 1) % n]
        p3 = pts[(i + 2) % n] if closed else pts[min(i + 2, n - 1)]
        for j in range(per):
            t = j / per
            t2, t3 = t * t, t * t * t
            out.append(tuple(0.5 * ((2 * p1[k]) + (-p0[k] + p2[k]) * t
                                    + (2 * p0[k] - 5 * p1[k] + 4 * p2[k] - p3[k]) * t2
                                    + (-p0[k] + 3 * p1[k] - 3 * p2[k] + p3[k]) * t3)
                       for k in range(2)))
    if not closed:
        out.append(pts[-1])
    return out


def resample(pts, step):
    out = [pts[0]]
    acc = 0.0
    for a, b in zip(pts, pts[1:]):
        seg = dist(a, b)
        while acc + seg >= step:
            t = (step - acc) / seg
            a = (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
            out.append(a)
            seg = dist(a, b)
            acc = 0.0
        acc += seg
    if dist(out[-1], pts[-1]) > step * 0.3:
        out.append(pts[-1])
    return out


def length(pts):
    return sum(dist(a, b) for a, b in zip(pts, pts[1:]))


def along(pts, s):
    """Point and unit tangent at arc length s along a polyline."""
    acc = 0.0
    for a, b in zip(pts, pts[1:]):
        seg = dist(a, b)
        if acc + seg >= s or b is pts[-1]:
            t = 0 if seg == 0 else min(1.0, max(0.0, (s - acc) / seg))
            tx, tz = (b[0] - a[0]) / (seg or 1), (b[1] - a[1]) / (seg or 1)
            return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t), (tx, tz)
        acc += seg
    return pts[-1], (1.0, 0.0)


def band(centre, half, seed, amp=0.14, caps=True, bulge=1.0):
    """A closed outline round a wandering centreline: hedges, paths, rills."""
    wl, wr = Wave(('bandL', seed)), Wave(('bandR', seed))
    left, right = [], []
    s = 0.0
    n = len(centre)
    for i, p in enumerate(centre):
        a, b = centre[max(i - 1, 0)], centre[min(i + 1, n - 1)]
        tx, tz = b[0] - a[0], b[1] - a[1]
        m = math.hypot(tx, tz) or 1
        nx, nz = -tz / m, tx / m
        if i:
            s += dist(centre[i - 1], p)
        h = half(i / max(n - 1, 1)) if callable(half) else half
        hl = h * (1 + amp * wl(s * 2.1))
        hr = h * (1 + amp * wr(s * 2.1))
        left.append((p[0] + nx * hl, p[1] + nz * hl))
        right.append((p[0] - nx * hr, p[1] - nz * hr))
    pts = left[:]
    if caps:
        pts += cap(centre[-1], centre[-2], left[-1], right[-1], bulge)
    pts += right[::-1]
    if caps:
        pts += cap(centre[0], centre[1], right[0], left[0], bulge)
    return pts


def cap(end, before, frm, to, bulge=1.0):
    """Points round a domed end from frm to to; bulge < 1 flattens the dome."""
    cx, cz = (frm[0] + to[0]) / 2, (frm[1] + to[1]) / 2
    r = dist(frm, to) / 2
    tx, tz = end[0] - before[0], end[1] - before[1]
    m = math.hypot(tx, tz) or 1
    tx, tz = tx / m, tz / m
    ux, uz = (frm[0] - cx) / (r or 1), (frm[1] - cz) / (r or 1)
    pts = []
    for k in range(1, 8):
        a = math.pi * k / 8
        pts.append((cx + r * math.cos(a) * ux + r * bulge * math.sin(a) * tx,
                    cz + r * math.cos(a) * uz + r * bulge * math.sin(a) * tz))
    return pts


def inside(p, poly):
    x, z = p
    hit = False
    n = len(poly)
    for i in range(n):
        x1, z1 = poly[i]
        x2, z2 = poly[(i + 1) % n]
        if (z1 > z) != (z2 > z):
            if x < x1 + (z - z1) * (x2 - x1) / (z2 - z1):
                hit = not hit
    return hit


def near_line(p, pts):
    return min(seg_dist(p, a, b) for a, b in zip(pts, pts[1:]))


def seg_dist(p, a, b):
    ax, az = b[0] - a[0], b[1] - a[1]
    m = ax * ax + az * az
    t = 0 if m == 0 else max(0, min(1, ((p[0] - a[0]) * ax + (p[1] - a[1]) * az) / m))
    return math.hypot(p[0] - a[0] - ax * t, p[1] - a[1] - az * t)


def poisson(ok, box, r, seed, k=30):
    """Bridson's blue noise inside a region, seeded."""
    R = rng('poisson', seed)
    x0, z0, x1, z1 = box
    cell = r / math.sqrt(2)
    grid = {}
    pts, active = [], []

    def free(p):
        if not (x0 <= p[0] <= x1 and z0 <= p[1] <= z1) or not ok(p):
            return False
        gi, gj = int((p[0] - x0) / cell), int((p[1] - z0) / cell)
        for i in range(gi - 2, gi + 3):
            for j in range(gj - 2, gj + 3):
                q = grid.get((i, j))
                if q and (q[0] - p[0]) ** 2 + (q[1] - p[1]) ** 2 < r * r:
                    return False
        return True

    def add(p):
        pts.append(p)
        active.append(p)
        grid[(int((p[0] - x0) / cell), int((p[1] - z0) / cell))] = p

    for _ in range(2000):
        p = (R.uniform(x0, x1), R.uniform(z0, z1))
        if free(p):
            add(p)
            break
    while active:
        i = R.randrange(len(active))
        a = active[i]
        for _ in range(k):
            ang = R.uniform(0, 2 * math.pi)
            d = R.uniform(r, 2 * r)
            p = (a[0] + d * math.cos(ang), a[1] + d * math.sin(ang))
            if free(p):
                add(p)
                break
        else:
            active.pop(i)
    return pts


def poisson_count(ok, box, count, seed, r0=0.5):
    """Blue noise with exactly `count` points, trimmed farthest-first."""
    r = r0
    for _ in range(30):
        pts = poisson(ok, box, r, seed)
        if len(pts) >= count:
            break
        r *= 0.95
    order = far_order(pts, min(range(len(pts)), key=lambda i: (pts[i][1], pts[i][0])))
    return [pts[i] for i in order[:count]]


def far_order(pts, first):
    """Each prefix as evenly spread as it can be: farthest point next."""
    order = [first]
    left = set(range(len(pts))) - {first}
    dmin = {i: dist(pts[i], pts[first]) for i in left}
    while left:
        j = max(left, key=lambda i: (round(dmin[i], 6), -i))
        order.append(j)
        left.remove(j)
        for i in left:
            dmin[i] = min(dmin[i], dist(pts[i], pts[j]))
    return order


def vogel(centre, c, count, turn=0.0):
    """A sunflower: every prefix evenly spread round the middle."""
    return [(centre[0] + c * math.sqrt(k + 0.5) * math.cos(k * GOLDEN + turn),
             centre[1] + c * math.sqrt(k + 0.5) * math.sin(k * GOLDEN + turn)) for k in range(count)]


# --------------------------------------------------------------------------
# Plants

HABIT_COLOUR = {
    'plume': '#cdb878', 'vine': '#7cab62', 'thistle': '#9d88cc', 'cushion': '#dd9db3',
    'poppy': '#e3805c', 'orchid': '#c78ad6', 'bell': '#7e9ade', 'umbel': '#ece5cc',
    'spire': '#d9788f', 'succulent': '#95cbb0', 'fern': '#5f9f58', 'star': '#efc866',
    'lotus': '#4fa58a', 'reed': '#bcae6c',
}
# lobes, depth, sharpness (>1 spiky, <1 rounded)
SHAPE = {
    'plume': (11, .26, 2.2), 'vine': (5, .22, .8), 'thistle': (9, .34, 3.0), 'cushion': (7, .07, .5),
    'poppy': (4, .2, .6), 'orchid': (3, .28, .7), 'bell': (5, .16, .5), 'umbel': (12, .06, .5),
    'spire': (6, .14, .7), 'succulent': (8, .22, 1.3), 'fern': (7, .38, 1.7), 'star': (5, .40, 2.3),
    'lotus': (1, 0, 1), 'reed': (6, .62, 4.0),
}
FAMILY_COLOUR = ['#e5643f', '#e7cf43', '#4fc08f', '#4aa7e0', '#8a74e6', '#de5aa3', '#f5f0e4']
FAMILY_WEIGHT = [0.21, 0.10, 0.07, 0.22, 0.17, 0.19, 0.04]

AREA_HABITS = {
    'walk': [('plume', .27), ('vine', .25), ('thistle', .26), ('cushion', .22)],
    'quiet': [('plume', .5), ('poppy', .5)],
    'cross': [('orchid', .34), ('bell', .33), ('cushion', .33)],
    'orchard': [('vine', .5), ('thistle', .5)],
    'knot': [('umbel', .5), ('bell', .5)],
    'seedbed': [('succulent', .22), ('lotus', .34), ('spire', .22), ('reed', .22)],
    'frame': [('lotus', .40), ('reed', .28), ('fern', .32)],
    'glasshouse': [('star', .34), ('poppy', .33), ('orchid', .33)],
    'coppice': [('fern', .48), ('star', .52)],
    'ground': [('spire', .32), ('umbel', .35), ('succulent', .33)],
}
HEIGHT = {  # median, spread of the log
    'plume': (1.05, .32), 'vine': (0.85, .38), 'thistle': (1.0, .35), 'cushion': (0.3, .35),
    'poppy': (0.8, .35), 'orchid': (0.75, .35), 'bell': (0.8, .35), 'umbel': (0.93, .28),
    'spire': (1.3, .3), 'succulent': (0.28, .3), 'fern': (0.49, .32), 'star': (1.0, .3),
    'lotus': (0.34, .15), 'reed': (1.0, .3),
}
SPREAD = {
    'plume': .62, 'vine': .7, 'thistle': .6, 'cushion': .55, 'poppy': .5, 'orchid': .5,
    'bell': .55, 'umbel': .67, 'spire': .47, 'succulent': .38, 'fern': .67, 'star': .79,
    'lotus': 1.0, 'reed': .5,
}
AMBASSADOR = {  # habit and height of each area's ambassador, from WEB-GARDENS.md
    'walk': ('thistle', 1.04), 'quiet': ('poppy', 0.55), 'cross': ('cushion', 0.46),
    'orchard': ('thistle', 1.34), 'knot': ('bell', 1.085), 'seedbed': ('succulent', 0.3),
    'frame': ('lotus', 0.34), 'glasshouse': ('star', 0.9), 'coppice': ('star', 0.906),
    'ground': ('umbel', 1.10),
}


def pick(R, weighted):
    u = R.random() * sum(w for _, w in weighted)
    for item, w in weighted:
        u -= w
        if u <= 0:
            return item
    return weighted[-1][0]


def stream(area, n):
    R = rng('stream', area)
    kinds = [(f'k{i:02d}', 1 / (i + 1) ** 0.8) for i in range(46)]
    out = []
    for i in range(n):
        habit = pick(R, AREA_HABITS[area])
        med, sd = HEIGHT[habit]
        if area == 'glasshouse':
            med, sd = 1.0, .2
        h = max(0.12, min(2.4, med * math.exp(R.gauss(0, sd))))
        fam = pick(R, list(enumerate(FAMILY_WEIGHT)))
        if area == 'glasshouse' and fam == 2:
            fam = pick(R, [(3, .5), (1, .5)])
        hue = None if fam == 6 else (fam + R.random()) * 60.0
        if area == 'glasshouse' and hue is not None and 100 <= hue <= 140:
            hue = 141 + R.random() * 30
        spread = SPREAD[habit] * math.exp(R.gauss(0, .2))
        plant = dict(i=i, habit=habit, h=h, fam=fam, hue=hue, kind=pick(R, kinds), spread=spread)
        if i == 0:
            plant['habit'], plant['h'] = AMBASSADOR[area]
            plant['spread'] = SPREAD[plant['habit']]
        out.append(plant)
    return out


# --------------------------------------------------------------------------
# Drawing


def d_closed(pts):
    n = len(pts)
    out = [f'M{pts[0][0]:.3f},{pts[0][1]:.3f}']
    for i in range(n):
        p0, p1, p2, p3 = pts[i - 1], pts[i], pts[(i + 1) % n], pts[(i + 2) % n]
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        out.append(f'C{c1[0]:.3f},{c1[1]:.3f} {c2[0]:.3f},{c2[1]:.3f} {p2[0]:.3f},{p2[1]:.3f}')
    return ''.join(out) + 'Z'


def d_open(pts):
    n = len(pts)
    out = [f'M{pts[0][0]:.3f},{pts[0][1]:.3f}']
    for i in range(n - 1):
        p0, p1, p2, p3 = pts[max(i - 1, 0)], pts[i], pts[i + 1], pts[min(i + 2, n - 1)]
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        out.append(f'C{c1[0]:.3f},{c1[1]:.3f} {c2[0]:.3f},{c2[1]:.3f} {p2[0]:.3f},{p2[1]:.3f}')
    return ''.join(out)


class Svg:
    def __init__(self):
        self.parts = []
        self.defs = []
        self.clip = None
        self.rim_open = False

    def shape(self, pts, fill='none', stroke='none', sw=0.0, op=1.0, closed=True, extra=''):
        d = d_closed(pts) if closed else d_open(pts)
        o = f' opacity="{op:.2f}"' if op < 1 else ''
        s = f' stroke="{stroke}" stroke-width="{sw:.3f}" stroke-linejoin="round" stroke-linecap="round"' \
            if stroke != 'none' else ''
        self.parts.append(f'<path d="{d}" fill="{fill}"{s}{o}{extra}/>')

    def line(self, pts, stroke, sw, op=1.0, dash=None):
        extra = f' stroke-dasharray="{dash}"' if dash else ''
        self.shape(pts, 'none', stroke, sw, op, closed=False, extra=extra)

    def raw(self, s):
        self.parts.append(s)

    def begin_clip(self, pts, name):
        self.defs.append(f'<clipPath id="{name}"><path d="{d_closed(pts)}"/></clipPath>')
        self.parts.append(f'<g clip-path="url(#{name})">')

    def end_clip(self):
        self.parts.append('</g>')

    def render(self, path, px=820, pad=0.32):
        lo = -HALF - pad
        size = SIDE + 2 * pad
        R = rng('stars', path)
        stars = ''.join(
            f'<circle cx="{R.uniform(lo, -lo):.3f}" cy="{R.uniform(lo, -lo):.3f}" '
            f'r="{R.uniform(.006, .016):.3f}" fill="#fff" opacity="{R.uniform(.25, .8):.2f}"/>'
            for _ in range(70))
        svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{px}" height="{px}" '
               f'viewBox="{lo:.3f} {lo:.3f} {size:.3f} {size:.3f}">'
               f'<defs><filter id="soft" x="-50%" y="-50%" width="200%" height="200%">'
               f'<feGaussianBlur stdDeviation="0.025"/></filter>'
               f'<filter id="softer" x="-50%" y="-50%" width="200%" height="200%">'
               f'<feGaussianBlur stdDeviation="0.07"/></filter>{"".join(self.defs)}</defs>'
               f'<rect x="{lo}" y="{lo}" width="{size}" height="{size}" fill="#0c1120"/>{stars}'
               + ''.join(self.parts) + '</svg>')
        with open(path, 'w') as f:
            f.write(svg)


GROUND = {
    'lawn': '#4d7543', 'meadow': '#58753f', 'rough': '#557a42', 'gravel': '#b3a385',
    'soil': '#5a4232', 'tilth': '#6c5240', 'litter': '#6b5236', 'tiles': '#9c5c40',
    'bed': '#4a3a2b', 'path': '#7d6a55',
}


def slab(svg, seed, ground):
    """The floating plot: its wandering rim, a hint of its side, its ground."""
    rim = loop(0, 0, HALF - 0.07, HALF - 0.07, ('rim', seed), amp=0.012, exp=7.5, n=140)
    svg.shape([(x + 0.05, z + 0.30) for x, z in rim], '#000', op=0.5, extra=' filter="url(#softer)"')
    svg.shape([(x, z + 0.20) for x, z in rim], '#3a291e')
    svg.shape([(x, z + 0.09) for x, z in rim], '#5b4130')
    svg.shape(rim, GROUND[ground] if ground in GROUND else ground)
    svg.begin_clip(rim, f'rim{key(seed) % 1000000}')
    svg.rim_open = True
    return rim


def texture(svg, rim, seed, tones, count=420, size=(0.015, 0.05), op=(0.15, 0.4), clipname=None):
    """Speckle a ground: grass tufts, gravel, crumbs."""
    R = rng('tex', seed)
    name = clipname or f'c{key(seed) % 100000}'
    svg.begin_clip(rim, name)
    for _ in range(count):
        x, z = R.uniform(-HALF, HALF), R.uniform(-HALF, HALF)
        r = R.uniform(*size)
        svg.raw(f'<ellipse cx="{x:.3f}" cy="{z:.3f}" rx="{r:.3f}" ry="{r * R.uniform(.5, 1):.3f}" '
                f'fill="{R.choice(tones)}" opacity="{R.uniform(*op):.2f}"/>')
    svg.end_clip()


def stripes(svg, region, seed, along_x=False, width=0.42, tone='#ffffff', op=0.07):
    """Mown stripes inside a region, gently wandering."""
    name = f's{key(seed) % 1000000}'
    svg.begin_clip(region, name)
    w = Wave(('stripe', seed))
    k = 0
    v = -HALF - 0.4
    while v < HALF + 0.4:
        if k % 2 == 0:
            line = [(t, v + 0.03 * w(t * 1.3 + k)) if along_x else (v + 0.03 * w(t * 1.3 + k), t)
                    for t in [i * 0.2 - HALF - 0.4 for i in range(32)]]
            pts = band(line, width / 2, ('st', seed, k), amp=0.05, caps=False)
            svg.shape(pts, tone, op=op)
        v += width
        k += 1
    svg.end_clip()


def hedge(svg, centre, half, seed, tall=False):
    pts = band(centre, half, ('hedge', seed), amp=0.18)
    off = 0.20 if tall else 0.10
    svg.shape([(x + off, z - off * 0.7) for x, z in pts], '#000', op=0.35, extra=' filter="url(#soft)"')
    svg.shape(pts, '#2c5631')
    inner = band(centre, half * 0.55, ('hedgetop', seed), amp=0.25)
    svg.shape([(x - 0.02, z + 0.02) for x, z in inner], '#3b6f40', op=0.85)


def water(svg, outline, seed, kerb=None):
    if kerb:
        svg.shape(kerb, '#9a907e')
    svg.shape(outline, '#1f4560')
    inner = [(x * 0.97, z * 0.97) for x, z in outline]
    cx = sum(p[0] for p in outline) / len(outline)
    cz = sum(p[1] for p in outline) / len(outline)
    inner = [(cx + (x - cx) * 0.82, cz + (z - cz) * 0.82) for x, z in outline]
    svg.shape(inner, '#2d6585', op=0.65)
    svg.shape(outline, 'none', '#86b3c8', 0.025, op=0.55)


def plant_pts(x, z, r, habit, seed, n=44):
    lobes, depth, sharp = SHAPE[habit]
    phase = rng('ph', seed).uniform(0, math.pi)
    w = Wave(('pl', seed), ((2, 1), (3, .5)))
    pts = []
    for i in range(n):
        t = 2 * math.pi * i / n
        c = abs(math.cos(lobes * t / 2 + phase))
        f = 1 - depth + depth * c ** sharp
        f *= 1 + 0.06 * w(t)
        pts.append((x + r * f * math.cos(t), z + r * f * math.sin(t)))
    return pts


def lotus_pts(x, z, r, seed):
    """A pad with its notch."""
    R = rng('pad', seed)
    notch = R.uniform(0, 2 * math.pi)
    pts = [(x, z)]
    for i in range(37):
        t = notch + 0.3 + (2 * math.pi - 0.6) * i / 36
        pts.append((x + r * math.cos(t), z + r * math.sin(t)))
    return pts


def draw_plants(svg, items, scale=0.7, bloom=1.0):
    """items: (x, z, plant, size) where size scales the drawing (young, cut)."""
    if svg.rim_open:
        svg.end_clip()
        svg.rim_open = False
    for x, z, p, size in items:
        r = p['spread'] / 2 * scale * size
        h = p['h'] * size
        dx, dz = 0.22 * h, -0.16 * h
        if p['habit'] == 'lotus':
            for k, (ox, oz, f) in enumerate(pad_layout(p, r)):
                svg.shape(lotus_pts(x + ox + 0.04, z + oz - 0.03, f, (p['i'], k)), '#000', op=0.25)
        else:
            svg.shape(plant_pts(x + dx, z + dz, r * 0.95, p['habit'], p['i']), '#000', op=0.28,
                      extra=' filter="url(#soft)"')
    for x, z, p, size in sorted(items, key=lambda t: (t[2]['h'] * t[3], t[1])):
        r = p['spread'] / 2 * scale * size
        col = HABIT_COLOUR[p['habit']]
        if p['habit'] == 'lotus':
            for k, (ox, oz, f) in enumerate(pad_layout(p, r)):
                svg.shape(lotus_pts(x + ox, z + oz, f, (p['i'], k)), col, '#1e4d3c', 0.012)
            svg.raw(f'<circle cx="{x:.3f}" cy="{z:.3f}" r="{(0.075 * size + 0.02) * bloom:.3f}" '
                    f'fill="{FAMILY_COLOUR[p["fam"]]}" stroke="#fff" stroke-width="0.01" opacity="0.95"/>')
            continue
        svg.shape(plant_pts(x, z, r, p['habit'], p['i']), col, shade(col, 0.6), 0.014)
        svg.shape(plant_pts(x - r * 0.12, z + r * 0.12, r * 0.55, p['habit'], (p['i'], 'hi')),
                  shade(col, 1.18), op=0.55)
        if p['habit'] != 'fern' and size > 0.45:
            fr = (0.05 + 0.04 * min(1.0, p['spread'])) * bloom
            svg.raw(f'<circle cx="{x:.3f}" cy="{z:.3f}" r="{fr * size:.3f}" fill="{FAMILY_COLOUR[p["fam"]]}" '
                    f'stroke="{shade(FAMILY_COLOUR[p["fam"]], 0.55)}" stroke-width="0.008"/>')


def pad_layout(p, r):
    R = rng('pads', p['i'])
    out = [(0.0, 0.0, r * 0.55)]
    for k in range(2):
        a = R.uniform(0, 2 * math.pi)
        out.append((math.cos(a) * r * 0.45, math.sin(a) * r * 0.45, r * R.uniform(0.38, 0.5)))
    return out


def shade(hex_colour, f):
    h = hex_colour.lstrip('#')
    rgb = [int(h[i:i + 2], 16) for i in (0, 2, 4)]
    rgb = [max(0, min(255, int(c * f + (255 - c) * max(0, f - 1) * 0.5))) for c in rgb]
    return '#' + ''.join(f'{c:02x}' for c in rgb)


def soft_patch(svg, pts, colour, op=0.22):
    svg.shape(pts, colour, op=op, extra=' filter="url(#soft)"')


# --------------------------------------------------------------------------
# The proposals


class Proposal:
    area = ''
    name = ''
    cuts = ()

    def __init__(self):
        self.plots = []
        self._tpl = {}

    def tpl(self, p):
        if p not in self._tpl:
            self._tpl[p] = self.template(p)
        return self._tpl[p]

    def places(self, p):
        return self.tpl(p)['places']

    def open(self):
        self.plots.append({})
        return len(self.plots) - 1

    def rank(self, h):
        return sum(1 for c in self.cuts if h >= c)

    def capacity(self, p):
        return len(self.places(p))

    def items(self, p):
        out = []
        for i, plant in self.plots[p].items():
            if plant is None:
                continue
            pl = self.places(p)[i]
            x, z = self.spot(p, i, plant)
            out.append((x, z, plant, self.size(p, i, plant)))
        return out

    def spot(self, p, i, plant):
        pl = self.places(p)[i]
        R = rng('nudge', self.area, plant['i'])
        n = getattr(self, 'nudge', 0.05)
        return pl['x'] + R.uniform(-n, n), pl['z'] + R.uniform(-n, n)

    def size(self, p, i, plant):
        return 1.0

    def stats(self):
        n = len(self.plots)
        settled = range(max(0, n - 2))
        cap = sum(self.capacity(p) for p in settled)
        held = sum(len(self.plots[p]) for p in settled)
        return dict(plots=n, held=round(100 * held / cap, 1) if cap else None)


def border_in_order(prop, p, i, plant, depth_of, reach=0.9):
    """Nothing stands in front of something shorter, among near neighbours."""
    pl = prop.places(p)
    me = pl[i]
    d = depth_of(me)
    for j, other in prop.plots[p].items():
        if other is None:
            continue
        o = pl[j]
        if o.get('side') != me.get('side') or dist((o['x'], o['z']), (me['x'], me['z'])) > reach:
            continue
        do = depth_of(o)
        if d > do + 0.05 and plant['h'] < other['h']:
            return False
        if d < do - 0.05 and plant['h'] > other['h']:
            return False
    return True


# ---- The Long Walk ---------------------------------------------------------

def walk_hedges(svg, seed):
    for side in (-1, 1):
        centre = spline([(side * 2.36, -2.62), (side * 2.34, -1.2), (side * 2.37, 0.3), (side * 2.35, 2.62)], 12)
        hedge(svg, centre, 0.16, (seed, side), tall=(side == 1))


def walk_rill(svg, centre, seed):
    w = Wave(('rill', seed))
    line = [(x + 0.18 * w(z * 1.7), z) for x, z in centre]
    line = line[3:-3]
    svg.shape(band(line, 0.07, ('rillk', seed), amp=0.1), '#8e8576')
    svg.shape(band(line, 0.045, ('rillw', seed), amp=0.1), '#3f7fa0')


class WalkA(Proposal):
    """Interlocking drifts: the border's places in long thin lenses."""
    area, name = 'walk', 'a'
    cuts = (0.75, 1.18)
    nudge = 0.04

    WARM = {0, 1, 5}

    def template(self, p):
        R = rng('walkA', p)
        places, lenses = [], []
        for side in (-1, 1):
            counts = [5, 3, 5, 3, 5, 3] if side == -1 else [3, 5, 3, 5, 3, 5]
            for k, cnt in enumerate(counts):
                zc = -1.72 + 0.69 * k + R.uniform(-0.04, 0.04)
                back = (side * 1.98, zc - 0.74)
                front = (side * 0.86, zc + 0.74)
                ax, az = front[0] - back[0], front[1] - back[1]
                m = math.hypot(ax, az)
                nx, nz = -az / m, ax / m
                ts = [.1, .3, .5, .7, .9] if cnt == 5 else [.17, .5, .83]
                lens = len(lenses)
                for j, t in enumerate(ts):
                    off = (0.10 if cnt == 5 else 0.06) * (1 if j % 2 else -1)
                    x = back[0] + ax * t + nx * off
                    z = back[1] + az * t + nz * off
                    depth = abs(x)
                    tier = 2 if depth >= 1.72 else (1 if depth >= 1.30 else 0)
                    places.append(dict(x=x, z=z, group=lens, rank=tier, side=side, t=t))
                lenses.append(dict(side=side, k=k, back=back, front=front, cnt=cnt, zc=zc))
        # Jekyll's grading: a warm colour claims the free lens nearest the
        # plot's middle, a cool one the free lens nearest its ends, sides in turn.
        middle_first = sorted(range(len(lenses)), key=lambda i: (abs(lenses[i]['zc']), lenses[i]['side']))
        ends_first = sorted(range(len(lenses)), key=lambda i: (-abs(lenses[i]['zc']), -lenses[i]['side']))
        return dict(places=places, lenses=lenses, order=middle_first, warm=middle_first, cool=ends_first)

    def claim(self, p, lens):
        for i, plant in self.plots[p].items():
            if self.places(p)[i]['group'] == lens:
                return plant['fam']
        return None

    def try_lens(self, p, lens, plant, ranks):
        pl = self.places(p)
        for want in ranks:
            cands = [i for i, x in enumerate(pl) if x['group'] == lens and x['rank'] == want and i not in self.plots[p]]
            cands.sort(key=lambda i: abs(pl[i]['t'] - 0.5))
            for i in cands:
                if border_in_order(self, p, i, plant, lambda q: abs(q['x'])):
                    self.plots[p][i] = plant
                    return True
        return False

    def place(self, plant):
        tier = self.rank(plant['h'])
        near = [tier] + [t for t in (tier - 1, tier + 1) if 0 <= t <= 2]
        tones = {plant['fam'], (plant['fam'] + 1) % 6, (plant['fam'] - 1) % 6} if plant['fam'] < 6 else {6}
        grade = 'warm' if plant['fam'] in self.WARM else 'cool'
        for p in range(len(self.plots)):
            for lens in self.tpl(p)['order']:
                if self.claim(p, lens) == plant['fam'] and self.try_lens(p, lens, plant, [tier]):
                    return
            for lens in self.tpl(p)[grade]:
                if self.claim(p, lens) is None and self.try_lens(p, lens, plant, [tier]):
                    return
            for lens in self.tpl(p)['order']:
                if self.claim(p, lens) == plant['fam'] and self.try_lens(p, lens, plant, near[1:]):
                    return
            for lens in self.tpl(p)['order']:
                c = self.claim(p, lens)
                if c is not None and c in tones and self.try_lens(p, lens, plant, near):
                    return
        p = self.open()
        for lens in self.tpl(p)[grade]:
            if self.try_lens(p, lens, plant, near):
                return

    def draw(self, svg, p):
        rim = slab(svg, ('walk', p), 'lawn')
        stripes(svg, rim, ('walkA', p), along_x=False, width=0.4)
        for side in (-1, 1):
            w = Wave(('verge', p, side))
            front = [(side * (0.62 + 0.06 * w(z * 1.6)), z) for z in [i * 0.2 - 2.6 for i in range(27)]]
            back = [(side * 2.3, z) for z in [2.6 - i * 0.2 for i in range(27)]]
            svg.shape(front + back, '#43663a')
        texture(svg, rim, ('walkAt', p), ['#2f4a2a', '#6b8f55', '#3e5d34'], count=260)
        tpl = self.tpl(p)
        for lens_i, lens in enumerate(tpl['lenses']):
            fam = self.claim(p, lens_i)
            if fam is None:
                continue
            (bx, bz), (fx, fz) = lens['back'], lens['front']
            cx, cz = (bx + fx) / 2, (bz + fz) / 2
            ang = math.atan2(fz - bz, fx - bx)
            pts = loop(cx, cz, dist(lens['back'], lens['front']) / 2 + 0.18, 0.26 if lens['cnt'] == 5 else 0.2,
                       ('lens', p, lens_i), amp=0.08, turn=ang)
            soft_patch(svg, pts, FAMILY_COLOUR[fam], 0.34)
        walk_rill(svg, [(0, z) for z in [i * 0.1 - 2.6 for i in range(53)]], ('walk', p))
        walk_hedges(svg, ('walk', p))
        draw_plants(svg, self.items(p), bloom=1.6)
        for lens_i, lens in enumerate(tpl['lenses']):
            fam = self.claim(p, lens_i)
            if fam is None:
                continue
            (bx, bz), (fx, fz) = lens['back'], lens['front']
            ang = math.atan2(fz - bz, fx - bx)
            pts = loop((bx + fx) / 2, (bz + fz) / 2, dist(lens['back'], lens['front']) / 2 + 0.22,
                       0.3 if lens['cnt'] == 5 else 0.24, ('lensl', p, lens_i), amp=0.06, turn=ang)
            svg.shape(pts, 'none', FAMILY_COLOUR[fam], 0.022, op=0.75, extra=' stroke-dasharray="0.07 0.05"')


class WalkB(Proposal):
    """The walk that bends: an S through each plot, deep bays inside the bends."""
    area, name = 'walk', 'b'
    cuts = (0.75, 1.18)
    nudge = 0.04

    def path_x(self, p, z):
        sign = 1 if p % 2 == 0 else -1
        return sign * 0.62 * math.sin(math.pi * z / HALF)

    def template(self, p):
        places = []
        for side in (-1, 1):
            def ok(q, side=side):
                xc = self.path_x(p, q[1])
                d = (q[0] - xc) * side
                return 0.78 <= d and abs(q[0]) <= 2.08 and abs(q[1]) <= 2.38
            pts = poisson_count(ok, (-2.1, -2.4, 2.1, 2.4), 24, ('walkB', p, side), r0=0.56)
            for x, z in pts:
                d = (x - self.path_x(p, z)) * side - 0.6
                tier = 2 if d >= 1.0 else (1 if d >= 0.5 else 0)
                places.append(dict(x=x, z=z, rank=tier, side=side, depth=d))
        mid = (0.0, 0.0)
        order = far_order([(q['x'], q['z']) for q in places],
                          min(range(len(places)), key=lambda i: dist((places[i]['x'], places[i]['z']), mid)))
        return dict(places=places, order=order)

    def drift(self, p, i, fam):
        """Size of the same-colour drift a plant at i would join."""
        pl = self.places(p)
        seen, todo = {i}, [i]
        while todo:
            a = todo.pop()
            for j, other in self.plots[p].items():
                if j in seen or other['fam'] != fam or pl[j]['side'] != pl[i]['side']:
                    continue
                if dist((pl[a]['x'], pl[a]['z']), (pl[j]['x'], pl[j]['z'])) <= 0.75:
                    seen.add(j)
                    todo.append(j)
        return len(seen)

    def place(self, plant):
        tier = self.rank(plant['h'])
        for want in [tier] + [t for t in (tier - 1, tier + 1) if 0 <= t <= 2]:
            for p in range(len(self.plots)):
                pl = self.places(p)
                cands = [i for i in self.tpl(p)['order'] if pl[i]['rank'] == want and i not in self.plots[p]]
                good = [i for i in cands if border_in_order(self, p, i, plant, lambda q: q['depth'])
                        and self.drift(p, i, plant['fam']) <= 5]
                if good:
                    joined = [i for i in good if self.drift(p, i, plant['fam']) > 1]
                    self.plots[p][(joined or good)[0]] = plant
                    return
        p = self.open()
        pl = self.places(p)
        i = next((i for i in self.tpl(p)['order'] if pl[i]['rank'] == tier), self.tpl(p)['order'][0])
        self.plots[p][i] = plant

    def draw(self, svg, p):
        rim = slab(svg, ('walk', p), '#43663a')
        texture(svg, rim, ('walkBt', p), ['#2f4a2a', '#6b8f55', '#3e5d34'], count=260)
        centre = [(self.path_x(p, z), z) for z in [i * 0.1 - 2.75 for i in range(56)]]
        path = band(centre, 0.6, ('wpath', p), amp=0.08, caps=False)
        svg.shape(path, GROUND['lawn'])
        stripes(svg, path, ('walkBs', p), along_x=False, width=0.36)
        walk_rill(svg, centre, ('walkB', p))
        walk_hedges(svg, ('walk', p))
        draw_plants(svg, self.items(p), bloom=1.6)


# ---- The Quiet Garden -------------------------------------------------------

def quiet_frame(svg, p, ground='lawn'):
    rim = slab(svg, ('quiet', p), ground)
    stripes(svg, rim, ('quiet', p), along_x=(p % 2 == 1), width=0.45)
    texture(svg, rim, ('quiett', p), ['#3a5c33', '#6c9256'], count=200)
    ring = loop(0, 0, 2.43, 2.43, ('qh', p), amp=0.006, exp=9, n=160)
    ring.append(ring[0])
    for k, seg in enumerate([ring[0:41], ring[40:81], ring[80:121], ring[120:161]]):
        hedge(svg, seg, 0.14, ('qhedge', p, k), tall=(k in (2, 3)))
    return rim


def bench(svg, at, angle, seed):
    plank = loop(at[0], at[1], 0.62, 0.2, ('bench', seed), amp=0.01, exp=6, turn=angle)
    svg.shape([(x + 0.12, z - 0.08) for x, z in plank], '#000', op=0.35, extra=' filter="url(#soft)"')
    svg.shape(plank, '#8a6a4a', '#4a3524', 0.02)
    back = loop(*rot((at[0], at[1] - 0.17), angle, at), 0.6, 0.05, ('benchb', seed), amp=0.01, exp=6, turn=angle)
    svg.shape(back, '#6e5238')


class QuietBase(Proposal):
    area = 'quiet'
    cuts = (1.08,)
    nudge = 0.06

    def orient(self, p, pts):
        """The room's composition turned and mirrored by its number."""
        turn = (p % 4) * math.pi / 2
        mirror = (p // 4) % 2 == 1
        out = []
        for x, z in pts:
            if mirror:
                x, z = z, x
            out.append(rot((x, z), turn))
        return out

    def group_claim(self, p, g):
        for i, plant in self.plots[p].items():
            if self.places(p)[i]['group'] == g:
                return plant['fam']
        return None

    def ok_order(self, p, i, plant):
        pl = self.places(p)
        g = pl[i]['group']
        for j, other in self.plots[p].items():
            if pl[j]['group'] != g:
                continue
            if pl[i]['rank'] > pl[j]['rank'] and plant['h'] < other['h']:
                return False
            if pl[i]['rank'] < pl[j]['rank'] and plant['h'] > other['h']:
                return False
        return True

    def take(self, p, g, plant, ranks):
        pl = self.places(p)
        if g == 'echo':
            if 9 not in self.plots[p]:
                self.plots[p][9] = plant
                return True
            return False
        for want in ranks:
            for i in self.tpl(p)['order']:
                if pl[i]['group'] == g and pl[i]['rank'] == want and i not in self.plots[p] \
                        and self.ok_order(p, i, plant):
                    self.plots[p][i] = plant
                    return True
        return False

    def place(self, plant):
        r = self.rank(plant['h'])
        ranks = [r, 1 - r]
        fam = plant['fam']
        tones = {fam, (fam + 1) % 6, (fam - 1) % 6, 6} if fam < 6 else set(range(7))
        groups = self.tpl(0)['groups']
        for p in range(len(self.plots)):
            for g in groups:
                if self.group_claim(p, g) == fam and self.take(p, g, plant, ranks):
                    return
        for p in range(len(self.plots)):
            for g in groups:
                if self.group_claim(p, g) is None and self.take(p, g, plant, ranks):
                    return
            echo = self.tpl(p).get('echo')
            if echo is not None:
                main = self.group_claim(p, groups[0])
                if main is not None and fam in ({main, (main + 1) % 6, (main - 1) % 6, 6} if main < 6 else {6}) \
                        and self.take(p, echo, plant, [0, 1]):
                    return
            for g in groups:
                c = self.group_claim(p, g)
                if c is not None and c in tones and self.take(p, g, plant, ranks):
                    return
        p = self.open()
        self.plots[p][self.tpl(p)['specimen']] = plant


class QuietA(QuietBase):
    """An asymmetric room: one, five, three and one, the lawn as the pause."""
    name = 'a'

    def template(self, p):
        spec = [(-1.02, -1.92)]
        g5 = [(1.82, 1.62, 1), (1.88, 0.98, 1), (1.30, 1.90, 0), (1.06, 1.42, 0), (1.47, 1.20, 0)]
        g3 = [(1.90, -1.02, 1), (1.47, -1.36, 0), (1.55, -0.58, 0)]
        echo = [(-1.72, 1.42, 0)]
        raw = [(x, z) for x, z in spec] + [(x, z) for x, z, _ in g5] + [(x, z) for x, z, _ in g3] + [(echo[0][0], echo[0][1])]
        pts = self.orient(p, raw)
        meta = [('spec', 0)] + [('g5', r) for _, _, r in g5] + [('g3', r) for _, _, r in g3] + [('echo', 0)]
        places = [dict(x=x, z=z, group=g, rank=r) for (x, z), (g, r) in zip(pts, meta)]
        order = [0, 1, 6, 2, 3, 7, 4, 5, 8, 9]
        return dict(places=places, order=order, groups=['g5', 'g3'], echo='echo', specimen=0)

    def draw(self, svg, p):
        quiet_frame(svg, p)
        bx, bz = self.orient(p, [(-1.78, -1.78)])[0]
        pool_c = self.orient(p, [(-0.32, -0.22)])[0]
        turn = (p % 4) * math.pi / 2 + (0.6 if (p // 4) % 2 == 0 else -0.6) + math.pi / 4
        pool = loop(pool_c[0], pool_c[1], 0.95, 0.64, ('qpool', p), amp=0.06, exp=2.2, turn=turn,
                    bite=(math.pi * 0.5, 0.18, 0.5))
        svg.shape([(x + 0.03, z + 0.03) for x, z in pool], '#2e4a2a')
        water(svg, pool, ('qp', p))
        stones = self.orient(p, [(-1.32, -1.32), (-1.02, -1.08), (-0.86, -0.78)])
        for k, (sx, sz) in enumerate(stones):
            st = loop(sx, sz, 0.16, 0.12, ('stone', p, k), amp=0.12, turn=k)
            svg.shape([(x + 0.03, z - 0.02) for x, z in st], '#000', op=0.3)
            svg.shape(st, '#a59c8c', '#6f675b', 0.01)
        bench(svg, (bx, bz), math.atan2(-bz, -bx) - math.pi / 2, p)
        draw_plants(svg, self.items(p), bloom=1.5)


class QuietB(QuietBase):
    """Clumps on a lawn: a belt of hedge, two clumps, a lake to look across."""
    name = 'b'

    def template(self, p):
        spec = [(-1.02, -1.92)]
        c5c = (0.62, -0.78)
        c5 = [(c5c[0], c5c[1], 1)] + [(c5c[0] + 0.44 * math.cos(a), c5c[1] + 0.40 * math.sin(a), r)
                                      for a, r in [(0.3, 1), (1.8, 0), (3.3, 0), (4.6, 0)]]
        c3c = (-1.12, 0.42)
        c3 = [(c3c[0], c3c[1], 1), (c3c[0] + 0.42, c3c[1] + 0.22, 0), (c3c[0] - 0.12, c3c[1] + 0.46, 0)]
        echo = [(1.6, 1.62)]
        raw = spec + [(x, z) for x, z, _ in c5] + [(x, z) for x, z, _ in c3] + echo
        pts = self.orient(p, raw)
        meta = [('spec', 0)] + [('g5', r) for _, _, r in c5] + [('g3', r) for _, _, r in c3] + [('echo', 0)]
        places = [dict(x=x, z=z, group=g, rank=r) for (x, z), (g, r) in zip(pts, meta)]
        return dict(places=places, order=[0, 1, 6, 2, 3, 7, 4, 5, 8, 9], groups=['g5', 'g3'], echo='echo', specimen=0)

    def draw(self, svg, p):
        quiet_frame(svg, p)
        line = self.orient(p, [(-2.0, 1.55), (-1.1, 1.25), (-0.2, 1.62), (0.75, 1.42), (1.35, 0.85),
                               (1.95, 0.45), (2.05, -0.2)])
        centre = spline(line, 10)
        lake = band(centre, lambda t: 0.28 + 0.22 * math.sin(math.pi * t) + 0.08 * math.sin(7 * t),
                    ('qlake', p), amp=0.1)
        svg.shape([(x + 0.03, z + 0.03) for x, z in lake], '#2e4a2a')
        water(svg, lake, ('ql', p))
        bx, bz = self.orient(p, [(-1.78, -1.78)])[0]
        bench(svg, (bx, bz), math.atan2(-bz, -bx) - math.pi / 2, p)
        draw_plants(svg, self.items(p), bloom=1.5)


# ---- The Crossing ------------------------------------------------------------

def roundel(svg, seed, basin=0.33):
    disc = loop(0, 0, 0.85, 0.85, ('roundel', seed), amp=0.03)
    svg.shape([(x + 0.06, z - 0.04) for x, z in disc], '#000', op=0.3, extra=' filter="url(#soft)"')
    svg.shape(disc, '#8f877a', '#6a6358', 0.02)
    R = rng('flags', seed)
    for k in range(9):
        a = k * 2 * math.pi / 9 + R.uniform(-.1, .1)
        svg.line([(0.42 * math.cos(a), 0.42 * math.sin(a)), (0.84 * math.cos(a + .05), 0.84 * math.sin(a + .05))],
                 '#756e62', 0.012, op=0.8)
    ring = loop(0, 0, basin + 0.09, basin + 0.09, ('basinrim', seed), amp=0.02)
    svg.shape(ring, '#a89f90', '#6a6358', 0.015)
    water(svg, loop(0, 0, basin, basin, ('basin', seed), amp=0.02), ('b', seed))


class CrossBase(Proposal):
    area = 'cross'
    cuts = (0.85, 1.34)
    nudge = 0.05

    def place(self, plant):
        r = self.rank(plant['h'])
        for want in [r] + [t for t in (r - 1, r + 1) if 0 <= t <= 2]:
            for p in range(len(self.plots)):
                pl = self.places(p)
                counts = [sum(1 for i in self.plots[p] if pl[i]['group'] == q) for q in range(4)]
                for q in sorted(range(4), key=lambda q: (counts[q], q)):
                    for i, x in enumerate(pl):
                        if x['group'] == q and x['rank'] == want and i not in self.plots[p]:
                            self.plots[p][i] = plant
                            return
        p = self.open()
        pl = self.places(p)
        self.plots[p][next(i for i, x in enumerate(pl) if x['rank'] == r)] = plant


class CrossA(CrossBase):
    """Four ways turning in: paths that curve to meet the middle, beds like commas."""
    name = 'a'

    def path_angle(self, i, r):
        t = max(0.0, min(1.0, (2.75 - r) / 1.9))
        return -math.pi / 2 + i * math.pi / 2 + math.radians(78) * t ** 1.6

    def template(self, p):
        places = []
        for q in range(4):
            for r, n, rank in [(1.32, 3, 0), (1.86, 2, 1), (2.38, 1, 2)]:
                a0 = self.path_angle(q, r)
                a1 = self.path_angle(q + 1, r)
                margin = (0.48 + 0.26) / r
                lo, hi = a0 + margin, a1 - margin
                for k in range(n):
                    a = (lo + hi) / 2 if n == 1 else lo + (hi - lo) * k / (n - 1)
                    rr = r + (0.08 if n == 1 else 0)
                    places.append(dict(x=rr * math.cos(a), z=rr * math.sin(a), group=q, rank=rank))
        return dict(places=places)

    def draw(self, svg, p):
        rim = slab(svg, ('cross', p), 'rough')
        texture(svg, rim, ('crosst', p), ['#3c5e33', '#78a05f', '#2f4d2a'], count=520)
        for i in range(4):
            centre = [(r * math.cos(self.path_angle(i, r)), r * math.sin(self.path_angle(i, r)))
                      for r in [2.8 - k * 0.1 for k in range(21)]]
            path = band(centre, 0.47, ('cpath', p, i), amp=0.08, caps=False)
            svg.shape(path, '#6a9356')
            stripes(svg, path, ('cps', p, i), width=0.3, op=0.06)
        roundel(svg, ('cross', p))
        draw_plants(svg, self.items(p))


class CrossB(CrossBase):
    """The chahar bagh: rills out from the basin, sunk quarters, plants on arcs."""
    name = 'b'

    def template(self, p):
        places = []
        for q in range(4):
            base = math.pi / 4 + q * math.pi / 2 - math.pi / 2
            for r, angs, rank in [(1.48, (-17, 0, 17), 0), (2.02, (-11, 11), 1), (2.62, (0,), 2)]:
                for a in angs:
                    t = base + math.radians(a)
                    places.append(dict(x=r * math.cos(t), z=r * math.sin(t), group=q, rank=rank))
        return dict(places=places)

    def draw(self, svg, p):
        rim = slab(svg, ('cross', p), '#6a9356')
        stripes(svg, rim, ('crossBs', p), width=0.32, op=0.05)
        for q in range(4):
            sx = 1 if q in (0, 3) else -1
            sz = 1 if q in (0, 1) else -1
            v, r0 = 0.66, 1.14
            a0, a1 = math.asin(v / r0), math.pi / 2 - math.asin(v / r0)
            arc = [(r0 * math.cos(a1 - (a1 - a0) * t / 8), r0 * math.sin(a1 - (a1 - a0) * t / 8)) for t in range(9)]
            raw = arc[::-1] + [(v, 2.0), (v, 2.8), (2.8, 2.8), (2.8, v), (2.0, v)]
            raw = [(sx * x, sz * z) for x, z in raw]
            if sx * sz < 0:
                raw = raw[::-1]
            w = Wave(('sunkw', p, q))
            bed = [(x + 0.03 * w(i * 0.7), z + 0.03 * w(i * 0.7 + 2)) for i, (x, z) in
                   enumerate(spline(raw, 6, closed=True))]
            svg.shape(bed, '#7fa468')
            svg.shape([(x * 0.985 + 0.03 * sx, z * 0.985 + 0.03 * sz) for x, z in bed], '#3f6436')
            texture(svg, bed, ('sunkt', p, q), ['#3c5e33', '#78a05f', '#2f4d2a'], count=170)
        for i, (dx, dz) in enumerate([(0, -1), (1, 0), (0, 1), (-1, 0)]):
            w = Wave(('rillc', p, i))
            centre = [(dx * r + dz * 0.03 * w(r * 2), dz * r + dx * 0.03 * w(r * 2)) for r in
                      [0.7 + k * 0.1 for k in range(20)]]
            svg.shape(band(centre, 0.12, ('rk', p, i), amp=0.08), '#958c7c')
            svg.shape(band(centre, 0.07, ('rw', p, i), amp=0.08), '#3f7fa0')
        roundel(svg, ('cross', p), basin=0.38)
        draw_plants(svg, self.items(p))


# ---- The Orchard --------------------------------------------------------------

def tree(svg, at, seed, r=0.66):
    can = loop(at[0], at[1], r, r, ('canopy', seed), amp=0.16, n=80)
    svg.shape([(x + 0.55, z - 0.4) for x, z in can], '#000', op=0.22, extra=' filter="url(#softer)"')
    svg.shape(can, '#3f6b38', '#2a4a26', 0.02, op=0.38)
    inner = loop(at[0] - 0.12, at[1] + 0.1, r * 0.62, r * 0.6, ('canopy2', seed), amp=0.2, n=60)
    svg.shape(inner, '#5b8a4c', op=0.35)
    svg.raw(f'<circle cx="{at[0]:.3f}" cy="{at[1]:.3f}" r="0.09" fill="#4a3727"/>')


class OrchardBase(Proposal):
    area = 'orchard'
    cuts = (0.48, 1.18)
    nudge = 0.05

    def place(self, plant):
        r = self.rank(plant['h'])
        for p in range(len(self.plots)):
            pl = self.places(p)
            for g in self.tpl(p)['guilds']:
                spots = [i for i, x in enumerate(pl) if x['group'] == g]
                if all(i in self.plots[p] for i in spots):
                    continue
                for want in [r] + [t for t in (r - 1, r + 1) if 0 <= t <= 2]:
                    for i in spots:
                        if i in self.plots[p]:
                            continue
                        if pl[i]['rank'] is None or pl[i]['rank'] == want:
                            if self.guild_ok(p, i, plant):
                                self.plots[p][i] = plant
                                return
        p = self.open()
        self.plots[p][self.tpl(p)['first']] = plant

    def guild_ok(self, p, i, plant):
        pl = self.places(p)
        me = pl[i]
        if me['rank'] is None:
            return True
        for j, other in self.plots[p].items():
            o = pl[j]
            if o['group'] != me['group'] or o['rank'] is None:
                continue
            if me['rank'] > o['rank'] and plant['h'] < other['h']:
                return False
            if me['rank'] < o['rank'] and plant['h'] > other['h']:
                return False
        return True


class OrchardA(OrchardBase):
    """A meadow orchard: crescents turned to the middle, one mown way through."""
    name = 'a'

    def trees(self, p):
        R = rng('trees', p)
        return [(0.0, 0.0)] + [(sx * 1.7 + R.uniform(-.12, .12), sz * 1.7 + R.uniform(-.12, .12))
                               for sx, sz in [(-1, -1), (1, -1), (1, 1), (-1, 1)]]

    def template(self, p):
        places = []
        trees = self.trees(p)
        for k, a in enumerate([math.pi / 4, 3 * math.pi / 4, 5 * math.pi / 4, 7 * math.pi / 4]):
            places.append(dict(x=0.86 * math.cos(a), z=0.86 * math.sin(a), group=0, rank=None))
        for g, (tx, tz) in enumerate(trees[1:], start=1):
            toward = math.atan2(-tz, -tx)
            for off, rank in [(-62, 2), (-21, 0), (21, 1), (62, 1)]:
                a = toward + math.radians(off)
                places.append(dict(x=tx + 0.9 * math.cos(a), z=tz + 0.9 * math.sin(a), group=g, rank=rank))
        return dict(places=places, guilds=[0, 1, 2, 3, 4], first=0, trees=trees)

    def draw(self, svg, p):
        rim = slab(svg, ('orchard', p), 'meadow')
        texture(svg, rim, ('orcht', p), ['#3a5530', '#7d9a59', '#90a866', '#2e4628'], count=700,
                size=(0.012, 0.04))
        trees = self.tpl(p)['trees']
        way = spline([(-2.7, 0.7), (-1.5, 0.95), (-0.75, 0.55), (0.0, 0.95), (0.85, 0.2), (1.35, -0.55),
                      (2.0, -0.85), (2.7, -0.6)], 10)
        mown = band(way, 0.32, ('way', p), amp=0.12, caps=False)
        svg.shape(mown, '#6d9a57')
        for g, (tx, tz) in enumerate(trees):
            if g == 0:
                patch = loop(tx, tz, 1.05, 1.05, ('mow', p, g), amp=0.07)
            else:
                toward = math.atan2(-tz, -tx)
                arc = [(tx + 0.9 * math.cos(toward + math.radians(a)), tz + 0.9 * math.sin(toward + math.radians(a)))
                       for a in range(-80, 81, 10)]
                patch = band(arc, 0.36, ('mowc', p, g), amp=0.1)
            svg.shape(patch, '#6d9a57')
        stripes(svg, rim, ('orchs', p), width=0.3, op=0.04)
        draw_plants(svg, self.items(p))
        for g, t in enumerate(trees):
            tree(svg, t, ('tree', p, g))


class OrchardB(OrchardBase):
    """Clumps of kin: three trees and two, the meadow sweeping between."""
    name = 'b'

    def trees(self, p):
        raw = [(-1.55, -1.25), (-0.4, -1.55), (-0.95, -0.25), (1.05, 1.15), (1.75, 0.15)]
        turn = (p % 4) * math.pi / 2
        return [rot(t, turn) for t in raw]

    def template(self, p):
        trees = self.trees(p)
        clumps = [trees[:3], trees[3:]]
        places = []
        for g, t in enumerate(trees):
            mates = clumps[0] if g < 3 else clumps[1]
            cx = sum(q[0] for q in mates) / len(mates)
            cz = sum(q[1] for q in mates) / len(mates)
            away = math.atan2(t[1] - cz, t[0] - cx)
            for off, rank in [(-70, 0), (-24, 1), (24, 2), (70, 1)]:
                a = away + math.radians(off)
                x, z = t[0] + 0.88 * math.cos(a), t[1] + 0.88 * math.sin(a)
                places.append(dict(x=max(-2.25, min(2.25, x)), z=max(-2.25, min(2.25, z)), group=g, rank=rank))
        return dict(places=places, guilds=[2, 0, 1, 3, 4], first=8, trees=trees)

    def draw(self, svg, p):
        rim = slab(svg, ('orchard', p), 'meadow')
        texture(svg, rim, ('orcht', p), ['#3a5530', '#7d9a59', '#90a866', '#2e4628'], count=700,
                size=(0.012, 0.04))
        trees = self.tpl(p)['trees']
        for k, mates in enumerate([trees[:3], trees[3:]]):
            cx = sum(q[0] for q in mates) / len(mates)
            cz = sum(q[1] for q in mates) / len(mates)
            patch = loop(cx, cz, 1.45 if k == 0 else 1.2, 1.25 if k == 0 else 0.95, ('mowB', p, k),
                         amp=0.08, turn=math.atan2(mates[0][1] - cz, mates[0][0] - cx))
            svg.shape(patch, '#6d9a57')
        turn = (p % 4) * math.pi / 2
        way = spline([rot(q, turn) for q in [(-2.7, 1.9), (-1.5, 1.75), (-0.6, 0.75), (0.45, 0.55), (0.75, -0.6), (1.7, -1.1), (2.2, -2.7)]], 10)
        svg.shape(band(way, 0.3, ('wayB', p), amp=0.12, caps=False), '#6d9a57')
        draw_plants(svg, self.items(p))
        for g, t in enumerate(trees):
            tree(svg, t, ('treeB', p, g))


# ---- The Knot Garden ----------------------------------------------------------

class KnotBase(Proposal):
    area = 'knot'
    cuts = (0.48, 1.18)
    nudge = 0.035

    def pair_of(self, c):
        return c % 4

    def claim(self, p, pair):
        pl = self.places(p)
        for i, plant in self.plots[p].items():
            if self.pair_of(pl[i]['group']) == pair:
                return plant['fam']
        return None

    def fill(self, p, pair, plant, ranks):
        pl = self.places(p)
        comps = [pair, pair + 4]
        counts = {c: sum(1 for i in self.plots[p] if pl[i]['group'] == c) for c in comps}
        for want in ranks:
            for c in sorted(comps, key=lambda c: (counts[c], c)):
                for i, x in enumerate(pl):
                    if x['group'] == c and x['rank'] == want and i not in self.plots[p]:
                        if self.in_order(p, i, plant):
                            self.plots[p][i] = plant
                            return True
        return False

    def in_order(self, p, i, plant):
        pl = self.places(p)
        for j, other in self.plots[p].items():
            if pl[j]['group'] != pl[i]['group']:
                continue
            if pl[i]['rank'] > pl[j]['rank'] and plant['h'] < other['h']:
                return False
            if pl[i]['rank'] < pl[j]['rank'] and plant['h'] > other['h']:
                return False
        return True

    def place(self, plant):
        r = self.rank(plant['h'])
        near = [r] + [t for t in (r - 1, r + 1) if 0 <= t <= 2]
        for p in range(len(self.plots)):
            for pair in range(4):
                if self.claim(p, pair) == plant['fam'] and self.fill(p, pair, plant, near):
                    return
        for p in range(len(self.plots)):
            for pair in range(4):
                if self.claim(p, pair) is None and self.fill(p, pair, plant, near):
                    return
        p = self.open()
        self.fill(p, 0, plant, near)

    def tint(self, svg, p, regions):
        for c, pts in regions.items():
            fam = self.claim(p, self.pair_of(c))
            if fam is not None:
                soft_patch(svg, pts, FAMILY_COLOUR[fam], 0.16)


def ring_band(svg, cx, cz, r, seed, half=0.09, n=120):
    pts = loop(cx, cz, r, r, ('ringc', seed), amp=0.008, n=n)
    pts.append(pts[0])
    pts = pts + [pts[1]]
    outer = [(cx + (x - cx) * (r + half) / r, cz + (z - cz) * (r + half) / r) for x, z in pts[:-1]]
    inner = [(cx + (x - cx) * (r - half) / r, cz + (z - cz) * (r - half) / r) for x, z in pts[:-1]]
    return outer, inner


class KnotA(KnotBase):
    """Interlaced rings: a round knot drawn with a hand-laid line."""
    name = 'a'
    RC, RS, D = 1.15, 0.86, 1.34

    def centres(self):
        return [(0, -self.D), (self.D, 0), (0, self.D), (-self.D, 0)]

    def template(self, p):
        places = []
        a_lens = (self.D - self.RS + self.RC) / 2
        for k in range(4):
            ax = -math.pi / 2 + k * math.pi / 2
            # lens k: a ribbon along the arc, clockwise low → tall
            for s, rank in [(-0.5, 0), (-0.17, 1), (0.17, 1), (0.5, 2)]:
                a = ax + s / a_lens
                places.append(dict(x=a_lens * math.cos(a), z=a_lens * math.sin(a), group=k, rank=rank))
            cx, cz = self.centres()[k]
            for off, rank in [(-95, 0), (-35, 1), (35, 2), (95, 1)]:
                a = ax + math.radians(off)
                places.append(dict(x=cx + 0.52 * math.cos(a), z=cz + 0.52 * math.sin(a), group=k + 4, rank=rank))
        # pairs: lens N-S, lens E-W, lune N-S, lune E-W
        for x in places:
            g = x['group']
            x['group'] = {0: 0, 2: 4, 1: 1, 3: 5, 4: 2, 6: 6, 5: 3, 7: 7}[g]
        return dict(places=places)

    def draw(self, svg, p):
        rim = slab(svg, ('knot', p), 'gravel')
        texture(svg, rim, ('knott', p), ['#8d7f66', '#cbbd9d', '#a1937a', '#776a55'], count=1500,
                size=(0.012, 0.03), op=(0.3, 0.7))
        edging = loop(0, 0, 2.4, 2.4, ('edge', p), amp=0.008, exp=3.6, n=160)
        regions = {}
        for k, (cx, cz) in enumerate(self.centres()):
            lune = loop(cx, cz, self.RS - 0.1, self.RS - 0.1, ('lune', k), amp=0.02)
            lune = [q for q in lune if math.hypot(*q) > self.RC + 0.1]
            regions[{0: 2, 1: 3, 2: 6, 3: 7}[k]] = lune if len(lune) > 4 else []
            ax = -math.pi / 2 + k * math.pi / 2
            a_lens = (self.D - self.RS + self.RC) / 2
            lens = loop(a_lens * math.cos(ax), a_lens * math.sin(ax), 0.24, 0.62, ('lens', k), amp=0.03,
                        turn=ax)
            regions[{0: 0, 1: 1, 2: 4, 3: 5}[k]] = lens
        self.tint(svg, p, {c: pts for c, pts in regions.items() if pts})
        rings = [(0, 0, self.RC)] + [(cx, cz, self.RS) for cx, cz in self.centres()]
        bands = []
        for k, (cx, cz, r) in enumerate(rings):
            outer, inner = ring_band(svg, cx, cz, r, (p, k))
            bands.append((outer, inner))
        e_out, e_in = ring_band(svg, 0, 0, 1, ('e', p))
        edge_outer = [(x * 1.03, z * 1.03) for x, z in edging]
        edge_inner = [(x * 0.965, z * 0.965) for x, z in edging]
        self.knot_band(svg, edge_outer, edge_inner)
        for outer, inner in bands:
            self.knot_band(svg, outer, inner)
        # over at alternate crossings: redraw the central ring's arcs over the small rings there
        for k in range(4):
            ax = -math.pi / 2 + k * math.pi / 2
            half = math.acos((self.D ** 2 + self.RC ** 2 - self.RS ** 2) / (2 * self.D * self.RC))
            for sgn, over_central in [(-1, k % 2 == 0), (1, k % 2 == 1)]:
                a = ax + sgn * half
                if over_central:
                    self.over(svg, 0, 0, self.RC, a, (p, 'c', k, sgn))
                else:
                    cx, cz = self.centres()[k]
                    px, pz = self.RC * math.cos(a), self.RC * math.sin(a)
                    self.over(svg, cx, cz, self.RS, math.atan2(pz - cz, px - cx), (p, 's', k, sgn))
        basin = loop(0, 0, 0.3, 0.3, ('kb', p), amp=0.03)
        svg.shape(loop(0, 0, 0.38, 0.38, ('kbr', p), amp=0.03), '#a89f90', '#6a6358', 0.015)
        water(svg, basin, ('kbw', p))
        draw_plants(svg, self.items(p), scale=0.66, bloom=1.5)

    def knot_band(self, svg, outer, inner):
        ring = outer + [outer[0]] + [inner[0]] + inner[::-1]
        svg.raw(f'<path d="{d_closed(outer)} {d_closed(inner[::-1])}" fill="#000" opacity="0.3" '
                f'transform="translate(0.05,-0.035)" fill-rule="evenodd" filter="url(#soft)"/>')
        svg.raw(f'<path d="{d_closed(outer)} {d_closed(inner[::-1])}" fill="#2f5b34" fill-rule="evenodd"/>')

    def over(self, svg, cx, cz, r, a, seed):
        span = 0.3 / r
        ts = [a - span + 2 * span * i / 12 for i in range(13)]
        outer = [(cx + (r + 0.095) * math.cos(t), cz + (r + 0.095) * math.sin(t)) for t in ts]
        inner = [(cx + (r - 0.095) * math.cos(t), cz + (r - 0.095) * math.sin(t)) for t in ts]
        piece = outer + inner[::-1]
        svg.shape([(x + 0.04, z - 0.03) for x, z in piece], '#000', op=0.3, closed=True,
                  extra=' filter="url(#soft)"')
        svg.raw(f'<path d="M{outer[0][0]:.3f},{outer[0][1]:.3f} ' + ' '.join(f'L{x:.3f},{z:.3f}' for x, z in outer[1:])
                + ' ' + ' '.join(f'L{x:.3f},{z:.3f}' for x, z in inner[::-1]) + 'Z" fill="#33613a"/>')
        svg.line(outer, '#173019', 0.016, op=0.9)
        svg.line(inner, '#173019', 0.016, op=0.9)


class KnotB(KnotBase):
    """The weave kept; each compartment a golden-angle cluster mirrored across the knot."""
    name = 'b'

    def template(self, p):
        places = []
        side = [(0.0, -1.52), (1.52, 0.0), (0.0, 1.52), (-1.52, 0.0)]
        corner = [(1.52, -1.52), (1.52, 1.52), (-1.52, 1.52), (-1.52, -1.52)]
        for k in range(4):
            for c, centre in [(k, side[k]), (k + 4, corner[k])]:
                pts = vogel((0, 0), 0.26, 4, turn=0.4)
                pts = [rot(q, k * math.pi / 2) for q in pts]
                pts = [(centre[0] + x, centre[1] + z) for x, z in pts]
                by_r = sorted(range(4), key=lambda i: math.hypot(*pts[i]))
                ranks = {by_r[0]: 0, by_r[1]: 1, by_r[2]: 1, by_r[3]: 2}
                for i, (x, z) in enumerate(pts):
                    places.append(dict(x=x, z=z, group=c, rank=ranks[i]))
        for x in places:
            g = x['group']
            x['group'] = {0: 0, 2: 4, 1: 1, 3: 5, 4: 2, 6: 6, 5: 3, 7: 7}[g]
        return dict(places=places)

    def draw(self, svg, p):
        rim = slab(svg, ('knot', p), 'gravel')
        texture(svg, rim, ('knott', p), ['#8d7f66', '#cbbd9d', '#a1937a', '#776a55'], count=1500,
                size=(0.012, 0.03), op=(0.3, 0.7))
        regions = {}
        side = [(0.0, -1.52), (1.52, 0.0), (0.0, 1.52), (-1.52, 0.0)]
        corner = [(1.52, -1.52), (1.52, 1.52), (-1.52, 1.52), (-1.52, -1.52)]
        mapping = {0: 0, 2: 4, 1: 1, 3: 5, 4: 2, 6: 6, 5: 3, 7: 7}
        for k in range(4):
            regions[mapping[k]] = loop(*side[k], 0.55, 0.55, ('sr', k), amp=0.04, exp=3)
            regions[mapping[k + 4]] = loop(*corner[k], 0.55, 0.55, ('cr', k), amp=0.04, exp=3)
        self.tint(svg, p, regions)
        edge = loop(0, 0, 2.27, 2.27, ('edgeB', p), amp=0.006, exp=9, n=160)
        edge.append(edge[0])
        hedge(svg, edge, 0.09, ('kedge', p))
        for axis in ('x', 'z'):
            for s in (-1, 1):
                pts = []
                for t in [i * 0.1 - 2.25 for i in range(46)]:
                    if abs(t) <= 0.76:
                        bow = 0.30 * math.cos(math.pi * t / 1.52)
                    else:
                        u = (abs(t) - 0.76) / 1.49
                        bow = -0.05 * math.sin(math.pi * u)
                    v = s * (0.76 - bow)
                    pts.append((t, v) if axis == 'x' else (v, t))
                hedge(svg, pts, 0.09, ('kb', axis, s, p))
        svg.shape(loop(0, 0, 0.38, 0.38, ('kbr', p), amp=0.03), '#a89f90', '#6a6358', 0.015)
        water(svg, loop(0, 0, 0.3, 0.3, ('kb', p), amp=0.03), ('kbw', p))
        draw_plants(svg, self.items(p), scale=0.66, bloom=1.5)


# ---- The Seedbed ---------------------------------------------------------------

class SeedbedBase(Proposal):
    area = 'seedbed'
    nudge = 0.02

    def wet(self, plant):
        return plant['habit'] in ('lotus', 'reed')

    def claim(self, p, d):
        pl = self.places(p)
        for i, plant in self.plots[p].items():
            if plant is not None and pl[i]['group'] == d:
                return (plant['kind'], self.wet(plant))
        return None

    def sow(self, p, d, plant):
        pl = self.places(p)
        spots = [i for i, x in enumerate(pl) if x['group'] == d]
        spots.sort(key=lambda i: pl[i]['k'])
        free = [i for i in spots if i not in self.plots[p]]
        if not free:
            return False
        if plant['habit'] == 'lotus':
            first = free[0]
            k = pl[first]['k']
            nxt = [i for i in free if pl[i]['k'] == k + 1]
            if not nxt:
                return False
            self.plots[p][first] = plant
            self.plots[p][nxt[0]] = None
            return True
        self.plots[p][free[0]] = plant
        return True

    def place(self, plant):
        me = (plant['kind'], self.wet(plant))
        for p in range(len(self.plots)):
            for d in self.tpl(p)['drills']:
                if self.claim(p, d) == me and self.sow(p, d, plant):
                    return
        for p in range(len(self.plots)):
            for d in self.drill_order(p, me[1]):
                if self.claim(p, d) is None and self.sow(p, d, plant):
                    return
        p = self.open()
        for d in self.drill_order(p, me[1]):
            if self.sow(p, d, plant):
                return

    def spot(self, p, i, plant):
        pl = self.places(p)
        x, z = pl[i]['x'], pl[i]['z']
        if plant['habit'] == 'lotus':
            nxt = [j for j, q in enumerate(pl) if q['group'] == pl[i]['group'] and q['k'] == pl[i]['k'] + 1]
            if nxt:
                x, z = (x + pl[nxt[0]]['x']) / 2, (z + pl[nxt[0]]['z']) / 2
        R = rng('nudge', 'seedbed', plant['i'])
        return x + R.uniform(-.03, .03), z + R.uniform(-.03, .03)

    def capacity(self, p):
        return len(self.places(p))

    def stats(self):
        n = len(self.plots)
        settled = range(max(0, n - 2))
        cap = sum(self.capacity(p) for p in settled)
        held = sum(len(self.plots[p]) for p in settled)
        return dict(plots=n, held=round(100 * held / cap, 1) if cap else None)

    def label(self, svg, at, angle, seed):
        st = loop(at[0], at[1], 0.11, 0.05, ('lab', seed), amp=0.05, exp=4, turn=angle)
        svg.shape([(x + 0.05, z - 0.04) for x, z in st], '#000', op=0.35)
        svg.shape(st, '#e8dcc0', '#8a7b60', 0.01)


class SeedbedA(SeedbedBase):
    """Drills on the contour: six curving drills, the water ones lowest."""
    name = 'a'
    C = (0.3, 5.6)

    def template(self, p):
        places = []
        drills = []
        R = rng('sbA', p)
        for d in range(6):
            zk = -1.98 + 0.75 * d
            r = self.C[1] - zk
            start = -1.8 + 0.12 * math.sin(d * 1.7 + p) + R.uniform(-.04, .04)
            a0 = math.atan2(-(r ** 2 - (start - self.C[0]) ** 2) ** 0.5, start - self.C[0])
            for k in range(8):
                a = a0 + k * 0.5 / r
                places.append(dict(x=self.C[0] + r * math.cos(a), z=self.C[1] + r * math.sin(a), group=d, k=k))
            drills.append(d)
        return dict(places=places, drills=drills)

    def drill_order(self, p, wet):
        return [5, 4, 3, 2, 1, 0] if wet else [0, 1, 2, 3, 4, 5]

    def draw(self, svg, p):
        rim = slab(svg, ('seedbed', p), 'tilth')
        texture(svg, rim, ('sbt', p), ['#4f3a2c', '#86684f', '#5e4635'], count=1300, size=(0.01, 0.03),
                op=(0.3, 0.7))
        pl = self.places(p)
        for d in range(6):
            pts = sorted([(q['k'], q['x'], q['z']) for q in pl if q['group'] == d])
            first, last = pts[0], pts[-1]
            r = math.hypot(first[1] - self.C[0], first[2] - self.C[1])
            a0 = math.atan2(first[2] - self.C[1], first[1] - self.C[0]) - 0.25 / r
            a1 = math.atan2(last[2] - self.C[1], last[1] - self.C[0]) + 0.3 / r
            arc = [(self.C[0] + r * math.cos(a0 + (a1 - a0) * t / 30), self.C[1] + r * math.sin(a0 + (a1 - a0) * t / 30))
                   for t in range(31)]
            claim = self.claim(p, d)
            if claim and claim[1]:
                svg.shape(band(arc, 0.36, ('bank', p, d), amp=0.06), '#3e3024')
                water(svg, band(arc, 0.28, ('flood', p, d), amp=0.08), ('fl', p, d))
            else:
                svg.shape(band(arc, 0.06, ('drill', p, d), amp=0.2), '#3b2c21', op=0.8)
            self.label(svg, (first[1] - 0.3, first[2] - 0.02), -0.3, (p, d))
        draw_plants(svg, self.items(p), scale=0.85)


class SeedbedB(SeedbedBase):
    """The crozier: six drills that spiral out from a pool, like a shoot unrolling."""
    name = 'b'

    def arm(self, p, j):
        base = j * math.pi / 3 + 0.25 * (p % 3)
        pts = []
        for k in range(107):
            u = k * 0.016
            r = 0.58 + u
            a = base + 1.2 * u
            pts.append((r * math.cos(a), r * math.sin(a)))
        return pts

    def template(self, p):
        places = []
        for j in range(6):
            line = self.arm(p, j)
            for k in range(8):
                (x, z), _ = along(line, 0.18 + k * 0.42)
                places.append(dict(x=x, z=z, group=j, k=k))
        return dict(places=places, drills=list(range(6)))

    def drill_order(self, p, wet):
        return [0, 3, 1, 4, 2, 5] if not wet else [5, 2, 4, 1, 3, 0]

    def draw(self, svg, p):
        rim = slab(svg, ('seedbed', p), 'tilth')
        texture(svg, rim, ('sbt', p), ['#4f3a2c', '#86684f', '#5e4635'], count=1300, size=(0.01, 0.03),
                op=(0.3, 0.7))
        for j in range(6):
            line = self.arm(p, j)
            line = resample(line, 0.08)
            claim = self.claim(p, j)
            end = int(len(line) * 0.98)
            if claim and claim[1]:
                svg.shape(band(line[:end], lambda t: 0.16 + 0.14 * t, ('sbank', p, j), amp=0.06), '#3e3024')
                water(svg, band(line[:end], lambda t: 0.12 + 0.11 * t, ('sflood', p, j), amp=0.08), ('sf', p, j))
            else:
                svg.shape(band(line[:end], 0.05, ('sdrill', p, j), amp=0.2), '#3b2c21', op=0.8)
        pool = loop(0, 0, 0.42, 0.42, ('spool', p), amp=0.05)
        svg.shape(loop(0, 0, 0.5, 0.5, ('spoolb', p), amp=0.05), '#3e3024')
        water(svg, pool, ('spw', p))
        for j in range(6):
            (x, z), _ = along(self.arm(p, j), 0.02)
            self.label(svg, (x, z), j * math.pi / 3, (p, j))
        draw_plants(svg, self.items(p), scale=0.85)


# ---- The Cold Frame ----------------------------------------------------------------

class FrameBase(Proposal):
    area = 'frame'
    cuts = (0.49,)
    nudge = 0.03

    def frames_places(self, centres, angles=(0, 0)):
        places = []
        for f, ((cx, cz), ang) in enumerate(zip(centres, angles)):
            for rank, dz in [(1, -0.2), (0, 0.2)]:
                for k in range(6):
                    q = rot((cx - 0.8 + 0.32 * k, cz + dz), ang, (cx, cz))
                    places.append(dict(x=q[0], z=q[1], group=f'f{f}', rank=rank, k=k, kind='frame'))
        return places

    def frame_claim(self, p, f):
        for i, plant in self.plots[p].items():
            if self.places(p)[i]['group'] == f:
                return plant['fam']
        return None

    def put_frame(self, p, f, plant):
        r = self.rank(plant['h'])
        pl = self.places(p)
        for want in (r, 1 - r):
            for i, x in enumerate(pl):
                if x['group'] == f and x['rank'] == want and i not in self.plots[p]:
                    ok = all(not (pl[j]['group'] == f and ((x['rank'] > pl[j]['rank'] and plant['h'] < o['h']) or
                                                          (x['rank'] < pl[j]['rank'] and plant['h'] > o['h'])))
                             for j, o in self.plots[p].items())
                    if ok:
                        self.plots[p][i] = plant
                        return True
        return False

    def place(self, plant):
        if plant['habit'] in ('lotus', 'reed'):
            for p in range(len(self.plots)):
                if self.put_water(p, plant):
                    return
            p = self.open()
            self.put_water(p, plant)
            return
        frames = self.tpl(0)['frames']
        for p in range(len(self.plots)):
            for f in frames:
                if self.frame_claim(p, f) == plant['fam'] and self.put_frame(p, f, plant):
                    return
        for p in range(len(self.plots)):
            for f in frames:
                if self.frame_claim(p, f) is None and self.put_frame(p, f, plant):
                    return
        p = self.open()
        self.put_frame(p, frames[0], plant)

    def size(self, p, i, plant):
        return 0.42 if self.places(p)[i]['kind'] == 'frame' else 1.0

    def draw_frames(self, svg, p, centres, angles=(0, 0)):
        for f, ((cx, cz), ang) in enumerate(zip(centres, angles)):
            box = loop(cx, cz, 1.05, 0.48, ('fbox', p, f), amp=0.008, exp=7, turn=ang)
            svg.shape([(x + 0.12, z - 0.09) for x, z in box], '#000', op=0.35, extra=' filter="url(#soft)"')
            svg.shape(box, '#7a5c40', '#4a3524', 0.02)
            svg.shape(loop(cx, cz, 0.97, 0.4, ('fsoil', p, f), amp=0.01, exp=7, turn=ang), '#4a3828')

    def draw_glass(self, svg, p, centres, angles=(0, 0)):
        for f, ((cx, cz), ang) in enumerate(zip(centres, angles)):
            svg.shape(loop(cx, cz, 0.99, 0.42, ('fglass', p, f), amp=0.006, exp=7, turn=ang), '#cfe3ee',
                      '#e8f2f6', 0.012, op=0.16)
            for k in (-1, 0, 1):
                a = rot((cx + k * 0.33, cz - 0.42), ang, (cx, cz))
                b = rot((cx + k * 0.33 + 0.01, cz + 0.42), ang, (cx, cz))
                svg.line([a, b], '#8a6a4a', 0.025, op=0.8)


class FrameA(FrameBase):
    """A pond planted as a pond: reeds in clumps at the margin, lilies from the middle out."""
    name = 'a'
    FRAMES = [(-1.12, -1.78), (1.16, -1.62)]
    ANGLES = (0.03, -0.05)
    CV, SX, SZ, AVOID = 0.32, 0.92, 0.88, 0.46

    def pond(self, p):
        return loop(0.05, 0.8, 2.28, 1.5, ('pond', p), amp=0.04, exp=3.2, bite=(-math.pi / 2 + 0.4, 0.12, 0.45))

    def template(self, p):
        places = self.frames_places(self.FRAMES, self.ANGLES)
        pond = self.pond(p)
        n = len(pond)
        clumps = []
        for c, t in enumerate([0.04, 0.24, 0.45, 0.63, 0.84]):
            px, pz = pond[int(t * n) % n]
            cx, cz = 0.05 + (px - 0.05) * 0.84, 0.8 + (pz - 0.8) * 0.8
            for k, (ox, oz) in enumerate([(0, 0), (0.27, 0.12), (0.08, 0.28)]):
                q = rot((cx + ox, cz + oz), c * 1.3, (cx, cz))
                places.append(dict(x=q[0], z=q[1], group=f'c{c}', rank=0, kind='margin', k=k))
            clumps.append((cx, cz))
        open_water = []
        for q in vogel((0.2, 0.85), self.CV, 160, turn=0.3):
            shrunk_ok = inside(q, [(0.05 + (x - 0.05) * self.SX, 0.8 + (z - 0.8) * self.SZ) for x, z in pond])
            if shrunk_ok and all(dist(q, c) > self.AVOID for c in clumps):
                open_water.append(q)
            if len(open_water) == 24:
                break
        for k, (x, z) in enumerate(open_water):
            places.append(dict(x=x, z=z, group='open', rank=0, kind='open', k=k))
        return dict(places=places, frames=['f0', 'f1'], pond=pond)

    def put_water(self, p, plant):
        pl = self.places(p)
        first = 'open' if plant['habit'] == 'lotus' else 'margin'
        for kind in (first, 'margin' if first == 'open' else 'open'):
            if kind == 'margin':
                for c in range(5):
                    for i, x in enumerate(pl):
                        if x['group'] == f'c{c}' and i not in self.plots[p]:
                            self.plots[p][i] = plant
                            return True
            else:
                for i, x in enumerate(pl):
                    if x['kind'] == 'open' and i not in self.plots[p]:
                        self.plots[p][i] = plant
                        return True
        return False

    def draw(self, svg, p):
        rim = slab(svg, ('frame', p), 'gravel')
        texture(svg, rim, ('frt', p), ['#8d7f66', '#cbbd9d', '#a1937a', '#776a55'], count=1300,
                size=(0.012, 0.03), op=(0.3, 0.7))
        pond = self.tpl(p)['pond']
        svg.shape([(0.05 + (x - 0.05) * 1.04, 0.8 + (z - 0.8) * 1.05) for x, z in pond], '#6f7a4c')
        water(svg, pond, ('fpond', p))
        shelf = [(0.05 + (x - 0.05) * 0.88, 0.8 + (z - 0.8) * 0.84) for x, z in pond]
        svg.shape(shelf, 'none', '#7fa8bc', 0.02, op=0.25)
        self.draw_frames(svg, p, self.FRAMES, self.ANGLES)
        draw_plants(svg, self.items(p))
        self.draw_glass(svg, p, self.FRAMES, self.ANGLES)


class FrameB(FrameBase):
    """Three pools and a stepping-stone path to the frames: the waiting garden."""
    name = 'b'
    FRAMES = [(-1.05, -1.82), (1.18, -1.66)]
    ANGLES = (0.08, -0.1)
    POOLS = [((-1.05, 0.85), 1.32, 1.18, 0.25), ((1.5, 0.15), 0.88, 0.75, -0.4), ((1.2, 1.8), 0.62, 0.5, 0.2)]

    def template(self, p):
        places = self.frames_places(self.FRAMES, self.ANGLES)
        caps = [17, 7, 3]
        reeds = [[(0.1, 2), (0.6, 1)], [(0.35, 1)], [(0.75, 1)]]
        pools = []
        for k, ((cx, cz), rx, rz, turn) in enumerate(self.POOLS):
            outline = loop(cx, cz, rx, rz, ('pool', p, k), amp=0.06, exp=2.3, turn=turn)
            pools.append(outline)
            n = len(outline)
            clumps = []
            for t, _ in reeds[k]:
                px, pz = outline[int(t * n) % n]
                cx2, cz2 = cx + (px - cx) * 0.8, cz + (pz - cz) * 0.8
                for j, (ox, oz) in enumerate([(0, 0), (0.24, 0.1), (0.06, 0.25)]):
                    places.append(dict(x=cx2 + ox, z=cz2 + oz, group=f'r{k}{len(clumps)}', rank=0, kind='margin', k=j))
                clumps.append((cx2, cz2))
            got = 0
            for q in vogel((cx, cz), 0.32, 90, turn=k):
                shrunk = [(cx + (x - cx) * 0.88, cz + (z - cz) * 0.84) for x, z in outline]
                if inside(q, shrunk) and all(dist(q, c) > 0.45 for c in clumps):
                    places.append(dict(x=q[0], z=q[1], group=f'p{k}', rank=0, kind='open', k=got))
                    got += 1
                if got == caps[k]:
                    break
        return dict(places=places, frames=['f0', 'f1'], pools=pools)

    def put_water(self, p, plant):
        pl = self.places(p)
        kinds = ['open', 'margin'] if plant['habit'] == 'lotus' else ['margin', 'open']
        for kind in kinds:
            for k in range(3):
                for i, x in enumerate(pl):
                    if x['kind'] == kind and x['group'][1] == str(k) and i not in self.plots[p]:
                        self.plots[p][i] = plant
                        return True
        return False

    def draw(self, svg, p):
        rim = slab(svg, ('frame', p), 'gravel')
        texture(svg, rim, ('frt', p), ['#8d7f66', '#cbbd9d', '#a1937a', '#776a55'], count=1300,
                size=(0.012, 0.03), op=(0.3, 0.7))
        for k, outline in enumerate(self.tpl(p)['pools']):
            (cx, cz) = self.POOLS[k][0]
            svg.shape([(cx + (x - cx) * 1.08, cz + (z - cz) * 1.1) for x, z in outline], '#6f7a4c')
            water(svg, outline, ('fp', p, k))
        stepping = spline([(0.42, 2.5), (0.36, 1.85), (0.5, 1.15), (0.42, 0.45), (0.38, -0.25),
                           (0.12, -0.85), (0.06, -1.3)], 12)
        for k, (x, z) in enumerate(resample(stepping, 0.36)):
            st = loop(x + 0.06 * math.sin(k * 2.1), z, 0.15, 0.12, ('step', p, k), amp=0.14, turn=k * 0.7)
            svg.shape([(sx + 0.03, sz - 0.02) for sx, sz in st], '#000', op=0.3)
            svg.shape(st, '#a39a8a', '#6c6457', 0.01)
        self.draw_frames(svg, p, self.FRAMES, self.ANGLES)
        draw_plants(svg, self.items(p))
        self.draw_glass(svg, p, self.FRAMES, self.ANGLES)


# ---- The Glasshouse ---------------------------------------------------------------

def band_of(hue):
    edges = [166.6, 190.8, 215.9, 239.8, 265.8, 291.0, 315.7, 345.4, 15.7 + 360, 40.3 + 360, 69.6 + 360]
    t = hue if hue >= 114 else hue + 360
    return sum(1 for e in edges if t >= e)


class GlassBase(Proposal):
    area = 'glasshouse'
    cuts = (1.16,)
    nudge = 0.025

    def place(self, plant):
        pl_new = None
        if plant['h'] >= self.cuts[0]:
            for p in range(len(self.plots)):
                pl = self.places(p)
                for i in self.tpl(p)['border_order']:
                    if i not in self.plots[p]:
                        self.plots[p][i] = plant
                        return
            p = self.open()
            self.plots[p][self.tpl(p)['border_order'][0]] = plant
            return
        if plant['hue'] is None:
            for p in range(len(self.plots)):
                for i in self.tpl(p)['pot_order']:
                    if i not in self.plots[p]:
                        self.plots[p][i] = plant
                        return
            p = self.open()
            self.plots[p][self.tpl(p)['pot_order'][0]] = plant
            return
        b = plant.get('_band', band_of(plant['hue']))
        for want in [b] + [x for x in (b - 1, b + 1) if 0 <= x < self.bands]:
            for p in range(len(self.plots)):
                pl = self.places(p)
                for i, x in enumerate(pl):
                    if x['kind'] == 'pot' and x['band'] == want and i not in self.plots[p]:
                        self.plots[p][i] = plant
                        return
        p = self.open()
        pl = self.places(p)
        self.plots[p][next(i for i, x in enumerate(pl) if x['kind'] == 'pot' and x['band'] == min(b, self.bands - 1))] = plant

    def draw_pots(self, svg, p):
        for i, plant in self.plots[p].items():
            pl = self.places(p)[i]
            if pl['kind'] != 'pot':
                continue
            x, z = self.spot(p, i, plant)
            svg.raw(f'<circle cx="{x + 0.03:.3f}" cy="{z - 0.02:.3f}" r="0.13" fill="#000" opacity="0.35"/>')
            svg.raw(f'<circle cx="{x:.3f}" cy="{z:.3f}" r="0.12" fill="#b4673f" stroke="#7a4128" stroke-width="0.015"/>')


class GlassA(GlassBase):
    """The colour wheel: a round house, the spectrum round its staging, the door at green."""
    name = 'a'
    bands = 12

    def template(self, p):
        places = []
        door = math.pi / 2
        span = math.radians(320)
        start = door + math.radians(20)
        for b in range(12):
            for k in range(2):
                a = start + (b * 2 + k + 0.5) * span / 24
                places.append(dict(x=1.9 * math.cos(a), z=1.9 * math.sin(a), kind='pot', band=b, k=k))
        border = [(0.0, 0.0)] + [(0.6 * math.cos(door + math.pi + k * 2 * math.pi / 7),
                                  0.6 * math.sin(door + math.pi + k * 2 * math.pi / 7)) for k in range(7)]
        for k, (x, z) in enumerate(border):
            places.append(dict(x=x, z=z, kind='border', band=None, k=k))
        pot_order = [i for i, x in enumerate(places) if x['kind'] == 'pot']
        border_order = [i for i, x in enumerate(places) if x['kind'] == 'border']
        return dict(places=places, pot_order=pot_order, border_order=border_order)

    def draw(self, svg, p):
        rim = slab(svg, ('glass', p), 'gravel')
        texture(svg, rim, ('glt', p), ['#8d7f66', '#cbbd9d', '#a1937a'], count=900, size=(0.012, 0.03),
                op=(0.3, 0.6))
        house = loop(0, 0, 2.36, 2.36, ('house', p), amp=0.006)
        svg.shape([(x + 0.25, z - 0.18) for x, z in house], '#000', op=0.3, extra=' filter="url(#softer)"')
        svg.shape(house, GROUND['tiles'])
        R = rng('tiles', p)
        for ring in range(6):
            r = 0.95 + ring * 0.24
            svg.shape(loop(0, 0, r, r, ('tr', p, ring), amp=0.006), 'none', '#7d4630', 0.012, op=0.5)
        door = math.pi / 2
        for k in range(24):
            a = door + math.radians(20) + k * math.radians(320) / 24
            svg.line([(0.96 * math.cos(a), 0.96 * math.sin(a)), (2.3 * math.cos(a + .01), 2.3 * math.sin(a + .01))],
                     '#7d4630', 0.01, op=0.4)
        staging = band([(1.9 * math.cos(door + math.radians(a)), 1.9 * math.sin(door + math.radians(a)))
                        for a in range(22, 339, 4)], 0.2, ('stage', p), amp=0.03)
        svg.shape([(x + 0.06, z - 0.04) for x, z in staging], '#000', op=0.35, extra=' filter="url(#soft)"')
        svg.shape(staging, '#8c6a4a', '#5a4130', 0.015)
        edges = [114, 166.6, 190.8, 215.9, 239.8, 265.8, 291.0, 315.7, 345.4, 375.7, 400.3, 429.6, 474]
        for b in range(12):
            a0 = door + math.radians(20) + b * math.radians(320) / 12
            a1 = a0 + math.radians(320) / 12
            hue = ((edges[b] + edges[b + 1]) / 2) % 360
            arc = [(2.16 * math.cos(a0 + (a1 - a0) * t / 6), 2.16 * math.sin(a0 + (a1 - a0) * t / 6)) for t in range(7)]
            svg.shape(band(arc, 0.035, ('hue', b), amp=0.05, caps=False), hsl(hue), op=0.85)
        bed = loop(0, 0, 0.95, 0.95, ('gbed', p), amp=0.04)
        svg.shape(bed, '#4a3828', '#6a5038', 0.02)
        self.draw_pots(svg, p)
        draw_plants(svg, self.items(p), scale=0.66, bloom=1.4)
        for k in range(16):
            a = k * 2 * math.pi / 16
            svg.line([(0.15 * math.cos(a), 0.15 * math.sin(a)), (2.36 * math.cos(a), 2.36 * math.sin(a))],
                     '#e6f0f4', 0.016, op=0.22)
        for r in (0.8, 1.6):
            svg.shape(loop(0, 0, r, r, ('rib', r), amp=0.0), 'none', '#e6f0f4', 0.012, op=0.18)
        wall = band([(2.36 * math.cos(door + math.radians(a)), 2.36 * math.sin(door + math.radians(a)))
                     for a in range(16, 345, 3)], 0.05, ('gw', p), amp=0.03)
        svg.shape(wall, '#d8e8ef', op=0.55)


def hsl(h, s=0.62, l=0.58):
    import colorsys
    r, g, b = colorsys.hls_to_rgb(h / 360, l, s)
    return '#%02x%02x%02x' % (int(r * 255), int(g * 255), int(b * 255))


class GlassB(GlassBase):
    """A crescent theatre: curved, stepped staging; the border tallest at its middle."""
    name = 'b'
    bands = 10
    C = (0.0, -3.4)

    def template(self, p):
        places = []
        for b in range(10):
            for k, rr in enumerate((4.55, 4.97)):
                a = -math.pi / 2 + math.radians(-22 + (b + 0.5) * 44 / 10) + (0.012 if k else 0)
                a = math.pi / 2 + math.radians(25 - (b + 0.5) * 50 / 10)
                places.append(dict(x=self.C[0] + rr * math.cos(a), z=self.C[1] + rr * math.sin(a), kind='pot',
                                   band=b, k=k))
        border = []
        for k in range(8):
            t = -1.6 + k * 3.2 / 7
            border.append((t, -1.05 + 0.12 * (t / 1.6) ** 2))
        for k, (x, z) in enumerate(border):
            places.append(dict(x=x, z=z, kind='border', band=None, k=k))
        base = len(places) - 8
        border_order = [base + k for k in (3, 4, 2, 5, 1, 6, 0, 7)]
        pot_order = [i for i, x in enumerate(places) if x['kind'] == 'pot']
        return dict(places=places, pot_order=pot_order, border_order=border_order)

    def place(self, plant):
        if plant['hue'] is not None:
            plant = dict(plant)
            plant['_band'] = min(9, int(band_of(plant['hue']) * 10 / 12))
        return GlassBase.place(self, plant)

    def draw(self, svg, p):
        rim = slab(svg, ('glass', p), 'gravel')
        texture(svg, rim, ('glt', p), ['#8d7f66', '#cbbd9d', '#a1937a'], count=900, size=(0.012, 0.03),
                op=(0.3, 0.6))
        house = loop(0, 0, 2.2, 1.7, ('houseB', p), amp=0.005, exp=7)
        svg.shape([(x + 0.25, z - 0.18) for x, z in house], '#000', op=0.3, extra=' filter="url(#softer)"')
        svg.shape(house, GROUND['tiles'])
        for k in range(14):
            x = -2.0 + k * 0.3
            svg.line(spline([(x, -1.6), (x + 0.02, 0), (x - 0.01, 1.6)], 6), '#7d4630', 0.01, op=0.4)
        arc_lo = [(self.C[0] + 4.55 * math.cos(math.pi / 2 + math.radians(a)), self.C[1] + 4.55 * math.sin(math.pi / 2 + math.radians(a)))
                  for a in range(-27, 28, 2)]
        arc_hi = [(self.C[0] + 4.97 * math.cos(math.pi / 2 + math.radians(a)), self.C[1] + 4.97 * math.sin(math.pi / 2 + math.radians(a)))
                  for a in range(-27, 28, 2)]
        svg.shape(band(arc_lo, 0.2, ('lo', p), amp=0.03), '#7c5c3f', '#5a4130', 0.015)
        svg.shape(band(arc_hi, 0.2, ('hi', p), amp=0.03), '#9a7652', '#5a4130', 0.015)
        bed = band([(t, -1.05 + 0.12 * (t / 1.6) ** 2) for t in [i * 0.2 - 1.85 for i in range(19)]], 0.32,
                   ('gbB', p), amp=0.06)
        svg.shape(bed, '#4a3828', '#6a5038', 0.02)
        self.draw_pots(svg, p)
        draw_plants(svg, self.items(p), scale=0.66, bloom=1.4)
        for k in range(15):
            x = -2.1 + k * 0.3
            svg.line(spline([(x, -1.7), (x + 0.01, 0), (x, 1.7)], 6), '#e6f0f4', 0.016, op=0.2)
        svg.line(spline([(-2.2, 0.0), (0, 0.02), (2.2, 0.0)], 8), '#e6f0f4', 0.03, op=0.3)
        svg.shape(house, 'none', '#d8e8ef', 0.06, op=0.5)


# ---- The Coppice ------------------------------------------------------------------

class CoppiceBase(Proposal):
    area = 'coppice'
    cuts = (0.99,)
    nudge = 0.04

    def stage(self, p, c, year=0):
        return (year - (3 * p + c)) % 3

    def size(self, p, i, plant):
        pl = self.places(p)[i]
        if pl['kind'] == 'stool':
            return {0: 0.38, 1: 0.68, 2: 1.0}[self.stage(p, pl['coupe'])]
        return 1.0

    def place(self, plant):
        fern = plant['habit'] == 'fern'
        if fern:
            for p in range(len(self.plots)):
                pl = self.places(p)
                counts = {c: sum(1 for i in self.plots[p] if pl[i]['coupe'] == c and pl[i]['kind'] == 'stool')
                          for c in range(3)}
                for c in sorted(range(3), key=lambda c: (counts[c], c)):
                    for i in self.tpl(p)['order']:
                        if pl[i]['coupe'] == c and pl[i]['kind'] == 'stool' and i not in self.plots[p]:
                            self.plots[p][i] = plant
                            return
        r = self.rank(plant['h'])
        for want in (r, 1 - r):
            for p in range(len(self.plots)):
                pl = self.places(p)
                counts = {c: sum(1 for i in self.plots[p] if pl[i]['coupe'] == c and pl[i]['kind'] == 'floor')
                          for c in range(3)}
                for c in sorted(range(3), key=lambda c: (counts[c], c)):
                    if fern and any(self.plots[p][i]['habit'] == 'fern' for i in self.plots[p]
                                    if pl[i]['coupe'] == c and pl[i]['kind'] == 'floor'):
                        continue
                    for i in self.tpl(p)['order']:
                        x = pl[i]
                        if x['coupe'] == c and x['kind'] == 'floor' and x['rank'] == want and i not in self.plots[p]:
                            if self.in_order(p, i, plant):
                                self.plots[p][i] = plant
                                return
        p = self.open()
        pl = self.places(p)
        kind = 'stool' if fern else 'floor'
        i = next(i for i in self.tpl(p)['order'] if pl[i]['kind'] == kind and pl[i]['coupe'] == 0
                 and (fern or pl[i]['rank'] == r))
        self.plots[p][i] = plant

    def in_order(self, p, i, plant):
        pl = self.places(p)
        for j, o in self.plots[p].items():
            if pl[j]['coupe'] != pl[i]['coupe'] or pl[j]['kind'] != 'floor':
                continue
            if pl[i]['rank'] > pl[j]['rank'] and plant['h'] < o['h']:
                return False
            if pl[i]['rank'] < pl[j]['rank'] and plant['h'] > o['h']:
                return False
        return True

    def stools(self, svg, p):
        pl = self.places(p)
        for i, x in enumerate(pl):
            if x['kind'] != 'stool' or i not in self.plots[p]:
                continue
            st = self.stage(p, x['coupe'])
            s = loop(x['x'], x['z'], 0.2, 0.2, ('stool', p, i), amp=0.08)
            svg.shape([(a + 0.05, b - 0.035) for a, b in s], '#000', op=0.35, extra=' filter="url(#soft)"')
            svg.shape(s, '#5d4330', '#3a291c', 0.012)
            face = {0: '#e9dcc0', 1: '#bba98d', 2: '#8e8576'}[st]
            svg.shape(loop(x['x'], x['z'], 0.13, 0.13, ('face', p, i), amp=0.06), face)

    def litter(self, svg, p):
        rim = slab(svg, ('coppice', p), 'litter')
        texture(svg, rim, ('copt', p), ['#4f3c27', '#87694a', '#5d7a3e', '#3f5a32'], count=1100,
                size=(0.012, 0.04), op=(0.25, 0.6))
        return rim


class CoppiceA(CoppiceBase):
    """Coupes as patches round a glade: three cants of unequal size, rides that meet."""
    name = 'a'

    def geometry(self, p):
        R = rng('copA', p)
        glade = (0.22 + R.uniform(-.25, .25), -0.12 + R.uniform(-.25, .25))
        base = R.uniform(0, 2 * math.pi)
        angles = [base, base + math.radians(115 + R.uniform(-10, 10)), base + math.radians(245 + R.uniform(-10, 10))]
        rides = []
        for k, a in enumerate(angles):
            pts = []
            for j in range(26):
                r = 0.5 + j * 0.12
                bend = 0.35 * math.sin(r * 0.9 + k)
                pts.append((glade[0] + r * math.cos(a + bend * 0.3), glade[1] + r * math.sin(a + bend * 0.3)))
            rides.append(pts)
        return glade, angles, rides

    def template(self, p):
        glade, angles, rides = self.geometry(p)
        rim = loop(0, 0, HALF - 0.07, HALF - 0.07, ('rim', ('coppice', p)), amp=0.012, exp=7.5, n=140)
        inner = [(x * 0.88, z * 0.88) for x, z in rim]
        places = []
        order = []
        for c in range(3):
            a0, a1 = angles[c], angles[(c + 1) % 3] + (2 * math.pi if c == 2 else 0)

            def ok(q, c=c, a0=a0, a1=a1):
                a = math.atan2(q[1] - glade[1], q[0] - glade[0])
                while a < a0:
                    a += 2 * math.pi
                return a < a1 and inside(q, inner) and dist(q, glade) > 0.95 and \
                    all(near_line(q, rd) > 0.62 for rd in rides)
            stools = poisson_count(ok, (-2.4, -2.4, 2.4, 2.4), 5, ('copstool', p, c), r0=0.78)
            for x, z in stools:
                places.append(dict(x=x, z=z, kind='stool', coupe=c, rank=0))
            for ride, rank_near in [(rides[c], 0), (rides[(c + 1) % 3], 0)]:
                mid = 7 if ride is rides[c] else 11
                while mid > 2 and not inside(ride[mid], [(x * 0.8, z * 0.8) for x, z in rim]):
                    mid -= 1
                (rx, rz) = ride[mid]
                tx, tz = ride[mid + 1][0] - rx, ride[mid + 1][1] - rz
                m = math.hypot(tx, tz)
                nx, nz = -tz / m, tx / m
                probe = (rx + nx * 0.6, rz + nz * 0.6)
                if not ok(probe):
                    nx, nz = -nx, -nz
                front_n = 2 if ride is rides[c] else 1
                pts = [(rx + nx * 0.44 - tx / m * 0.34, rz + nz * 0.44 - tz / m * 0.34, 0),
                       (rx + nx * 0.44 + tx / m * 0.38, rz + nz * 0.44 + tz / m * 0.38, 0),
                       (rx + nx * 0.92 + tx / m * 0.04, rz + nz * 0.92 + tz / m * 0.04, 1)]
                if front_n == 1:
                    pts = [pts[0], (rx + nx * 0.92 - tx / m * 0.42, rz + nz * 0.92 - tz / m * 0.42, 1),
                           (rx + nx * 0.92 + tx / m * 0.42, rz + nz * 0.92 + tz / m * 0.42, 1)]
                for x, z, rank in pts:
                    places.append(dict(x=x, z=z, kind='floor', coupe=c, rank=rank))
        g = [(q['x'], q['z']) for q in places]
        order = far_order(g, min(range(len(g)), key=lambda i: dist(g[i], glade)))
        return dict(places=places, order=order, glade=glade, rides=rides)

    def draw(self, svg, p):
        rim = self.litter(svg, p)
        glade, angles, rides = self.geometry(p)
        for c in range(3):
            st = self.stage(p, c)
            a0, a1 = angles[c], angles[(c + 1) % 3] + (2 * math.pi if c == 2 else 0)
            wedge = [glade] + [(glade[0] + 4 * math.cos(a0 + (a1 - a0) * t / 20), glade[1] + 4 * math.sin(a0 + (a1 - a0) * t / 20))
                               for t in range(21)]
            tone = {0: '#c9b48a', 1: '#3f5a32', 2: '#26361f'}[st]
            svg.begin_clip(rim, f'cw{p}{c}')
            svg.shape(wedge, tone, op={0: 0.22, 1: 0.18, 2: 0.32}[st])
            svg.end_clip()
        for k, ride in enumerate(rides):
            svg.begin_clip(rim, f'cr{p}{k}')
            svg.shape(band(ride, 0.24, ('ride', p, k), amp=0.12), '#8a7458', op=0.85)
            svg.end_clip()
        svg.shape(loop(glade[0], glade[1], 0.62, 0.55, ('glade', p), amp=0.1), '#8a7458', op=0.9)
        svg.shape(loop(glade[0], glade[1], 0.45, 0.4, ('glade2', p), amp=0.12), '#6f8a45', op=0.6)
        self.stools(svg, p)
        draw_plants(svg, self.items(p))


class CoppiceB(CoppiceBase):
    """Sinuous bands: the three cants kept, curving, stools in a loose zigzag."""
    name = 'b'

    def centre_z(self, p, k, x):
        return -1.62 + 1.62 * k + 0.24 * math.sin(1.15 * x + 0.9 * k + 0.7 * (p % 3))

    def template(self, p):
        places = []
        R = rng('copB', p)
        for k in range(3):
            for j, x in enumerate([-1.8, -0.9, 0.0, 0.9, 1.8]):
                x += R.uniform(-.08, .08)
                z = self.centre_z(p, k, x) + (0.17 if j % 2 else -0.17)
                places.append(dict(x=x, z=z, kind='stool', coupe=k, rank=0))
            for j, x in enumerate([-1.38, -0.05, 1.32]):
                for rank, off in [(1, -0.47), (0, 0.47)]:
                    xx = x + (0.22 if rank else -0.18) + R.uniform(-.06, .06)
                    places.append(dict(x=xx, z=self.centre_z(p, k, xx) + off, kind='floor', coupe=k, rank=rank))
        g = [(q['x'], q['z']) for q in places]
        order = far_order(g, min(range(len(g)), key=lambda i: dist(g[i], (0, 0))))
        return dict(places=places, order=order)

    def draw(self, svg, p):
        rim = self.litter(svg, p)
        for k in range(3):
            st = self.stage(p, k)
            tone = {0: '#c9b48a', 1: '#3f5a32', 2: '#26361f'}[st]
            line = [(x, self.centre_z(p, k, x)) for x in [i * 0.15 - 2.8 for i in range(38)]]
            svg.begin_clip(rim, f'cb{p}{k}')
            svg.shape(band(line, 0.62, ('cband', p, k), amp=0.08, caps=False), tone, op={0: 0.22, 1: 0.18, 2: 0.32}[st])
            svg.end_clip()
        for k in range(2):
            line = [(x, (self.centre_z(p, k, x) + self.centre_z(p, k + 1, x)) / 2) for x in
                    [i * 0.15 - 2.8 for i in range(38)]]
            svg.begin_clip(rim, f'crb{p}{k}')
            svg.shape(band(line, 0.24, ('crideB', p, k), amp=0.12, caps=False), '#8a7458', op=0.85)
            svg.end_clip()
        self.stools(svg, p)
        draw_plants(svg, self.items(p))


# ---- The Home Ground --------------------------------------------------------------

CROP = {'spire': ((-0.4, 0.0, 0.4), 0.45, 1.261), 'umbel': ((-0.3, 0.3), 0.6, 0.93),
        'succulent': ((-0.38, 0.0, 0.38), 0.40, 0.266)}


class GroundBase(Proposal):
    area = 'ground'
    nudge = 0.02

    def claim(self, p, b):
        return self.tpl(p)['claims'].get(b) if p in self._tpl else None

    def place(self, plant):
        crop = plant['habit']
        for p in range(len(self.plots)):
            for b in range(3):
                if self.tpl(p)['claims'].get(b) == crop and self.sow(p, b, plant):
                    return
        for p in range(len(self.plots)):
            for b in range(3):
                if b not in self.tpl(p)['claims']:
                    self.tpl(p)['claims'][b] = crop
                    self.lay(p, b, crop)
                    if self.sow(p, b, plant):
                        return
        p = self.open()
        self.tpl(p)['claims'][0] = crop
        self.lay(p, 0, crop)
        self.sow(p, 0, plant)

    def sow(self, p, b, plant):
        t = self.tpl(p)
        rows = t['beds'][b]
        tall = plant['h'] >= CROP[plant['habit']][2]
        seq = [i for row in rows for i in row]
        if not seq:
            return False
        free = [i for i in seq if i not in self.plots[p]]
        if not free:
            return False
        i = free[0] if tall else free[-1]
        self.plots[p][i] = plant
        return True

    def capacity(self, p):
        return sum(len(r) for b in self.tpl(p)['beds'].values() for r in b)


class GroundA(GroundBase):
    """Lazy beds that follow the land: three curving beds, rows across them."""
    name = 'a'

    def centre(self, p, b, z):
        sign = 1 if p % 2 == 0 else -1
        return -1.65 + 1.65 * b + sign * 0.34 * (1 - (z / 2.15) ** 2) + 0.05 * math.sin(2.2 * z + b)

    def template(self, p):
        return dict(places=[], beds={}, claims={})

    def lay(self, p, b, crop):
        t = self.tpl(p)
        across, step, _ = CROP[crop]
        line = [(self.centre(p, b, z), z) for z in [i * 0.05 - 2.08 for i in range(84)]]
        L = length(line)
        rows = []
        s = step / 2 + 0.05
        while s <= L - step / 2:
            (x, z), (tx, tz) = along(line, s)
            nx, nz = -tz, tx
            row = []
            for o in across:
                t['places'].append(dict(x=x + nx * o, z=z + nz * o, group=b))
                row.append(len(t['places']) - 1)
            rows.append(row)
            s += step
        t['beds'][b] = rows

    def draw(self, svg, p):
        rim = slab(svg, ('ground', p), 'path')
        texture(svg, rim, ('grt', p), ['#5e4c3b', '#9a8670', '#6b5844'], count=1000, size=(0.012, 0.035),
                op=(0.3, 0.6))
        for b in range(3):
            line = [(self.centre(p, b, z), z) for z in [i * 0.1 - 1.95 for i in range(40)]]
            bed = band(line, 0.62, ('gbedA', p, b), amp=0.06, bulge=0.32)
            svg.shape([(x + 0.06, z - 0.04) for x, z in bed], '#000', op=0.3, extra=' filter="url(#soft)"')
            svg.shape(bed, '#4a3829')
            texture(svg, bed, ('gbt', p, b), ['#3a2b1f', '#6a5240', '#2e2218'], count=280, size=(0.01, 0.03),
                    op=(0.4, 0.8))
        tx = (self.centre(p, 0, 2.1) + self.centre(p, 1, 2.1)) / 2
        trough = loop(tx, 2.32, 0.4, 0.17, ('trough', p), amp=0.02, exp=5)
        svg.shape(trough, '#9a917f', '#6c6457', 0.015)
        water(svg, loop(tx, 2.32, 0.31, 0.1, ('troughw', p), amp=0.02, exp=5), ('tw', p))
        draw_plants(svg, self.items(p), scale=0.85)


class GroundB(GroundBase):
    """Three keyhole beds round a trough: crops in arcs, tall at the back of each ring."""
    name = 'b'
    BEDS = [(-1.28, -1.12), (1.28, -1.12), (0.0, 1.2)]

    def template(self, p):
        return dict(places=[], beds={}, claims={})

    def lay(self, p, b, crop):
        t = self.tpl(p)
        cx, cz = self.BEDS[b]
        hearth = (0.0, -0.18)
        notch = math.atan2(hearth[1] - cz, hearth[0] - cx)
        across, step, _ = CROP[crop]
        radii = {'spire': (0.48, 0.82), 'umbel': (0.55, 0.9), 'succulent': (0.45, 0.72, 0.98)}[crop]
        row = []
        for r in radii:
            span = 2 * math.pi - 2 * (0.32 / r + 0.2)
            n = max(1, int(span * r / step))
            back = notch + math.pi
            for k in range(n):
                off = (k + 0.5) / n * span - span / 2
                row.append((abs(off), len(t['places'])))
                t['places'].append(dict(x=cx + r * math.cos(back + off), z=cz + r * math.sin(back + off), group=b))
        row.sort()
        t['beds'][b] = [[i for _, i in row]]

    def draw(self, svg, p):
        rim = slab(svg, ('ground', p), 'path')
        texture(svg, rim, ('grt', p), ['#5e4c3b', '#9a8670', '#6b5844'], count=1000, size=(0.012, 0.035),
                op=(0.3, 0.6))
        hearth = (0.0, -0.18)
        for b, (cx, cz) in enumerate(self.BEDS):
            notch = math.atan2(hearth[1] - cz, hearth[0] - cx)
            outer = loop(cx, cz, 1.13, 1.13, ('kh', p, b), amp=0.03)
            svg.shape([(x + 0.06, z - 0.04) for x, z in outer], '#000', op=0.3, extra=' filter="url(#soft)"')
            svg.shape(outer, '#4a3829')
            texture(svg, outer, ('kht', p, b), ['#3a2b1f', '#6a5240', '#2e2218'], count=220, size=(0.01, 0.03),
                    op=(0.4, 0.8))
            notch_line = [(cx + r * math.cos(notch), cz + r * math.sin(notch)) for r in [0.0, 0.4, 0.8, 1.25]]
            svg.shape(band(notch_line, 0.2, ('notch', p, b), amp=0.08), GROUND['path'])
            svg.shape(loop(cx, cz, 0.27, 0.27, ('khc', p, b), amp=0.06), GROUND['path'])
        trough = loop(*hearth, 0.32, 0.32, ('troughB', p), amp=0.03)
        svg.shape(trough, '#9a917f', '#6c6457', 0.015)
        water(svg, loop(*hearth, 0.23, 0.23, ('troughBw', p), amp=0.03), ('twB', p))
        draw_plants(svg, self.items(p), scale=0.85)


# --------------------------------------------------------------------------
# Running

class WalkNow(WalkB):
    """The built walk, for comparison: three tiers of staggered rows each side."""
    name = 'now'

    def template(self, p):
        places = []
        for side in (-1, 1):
            for tier, depth, per in [(0, 0.95, 5), (1, 1.45, 4), (2, 1.95, 3)]:
                spacing = 4.8 / per
                for index in range(2 * per):
                    row, step = index % 2, index // 2
                    d = depth + (-0.13 if row == 0 else 0.13)
                    places.append(dict(x=side * d, z=-2.4 + (step + 0.25 + 0.5 * row) * spacing, rank=tier,
                                       side=side, depth=d - 0.6))
        order = sorted(range(len(places)), key=lambda i: (places[i]['z'], places[i]['side']))
        return dict(places=places, order=order)


class QuietNow(QuietBase):
    """The built room, for comparison: a specimen by the bench, three corner groups of three."""
    name = 'now'

    def template(self, p):
        raw = [(-1.02, -1.92, 'spec', 0)]
        for g, (cx, cz) in enumerate([(1.85, -1.85), (1.85, 1.85), (-1.85, 1.85)]):
            raw += [(cx, cz, f'g{g}', 1), (cx - 0.45 * (1 if cx > 0 else -1), cz, f'g{g}', 0),
                    (cx, cz - 0.45 * (1 if cz > 0 else -1), f'g{g}', 0)]
        places = [dict(x=x, z=z, group=g, rank=r) for x, z, g, r in raw]
        return dict(places=places, order=list(range(10)), groups=['g0', 'g1', 'g2'], echo=None, specimen=0)


PROPOSALS = [WalkA, WalkB, QuietA, QuietB, CrossA, CrossB, OrchardA, OrchardB, KnotA, KnotB,
             SeedbedA, SeedbedB, FrameA, FrameB, GlassA, GlassB, CoppiceA, CoppiceB, GroundA, GroundB]
BASELINES = [WalkNow, QuietNow]


def run(cls, n):
    prop = cls()
    for plant in stream(cls.area, n):
        if cls.area == 'glasshouse' and cls.name == 'b' and plant.get('hue') is not None:
            pass
        prop.place(plant)
    return prop


def settled_plot(prop):
    n = len(prop.plots)
    return min(3, max(0, n - 3))


def render(prop, p, path):
    svg = Svg()
    prop.draw(svg, p)
    svg.render(path)


def strip(cls, plots, path, turn=False, px=560):
    """Several plots of one area at a thousand arrivals, side by side."""
    from PIL import Image
    big = run(cls, 1000)
    tiles = []
    for p in plots:
        svgp = f'{path}.{p}.svg'
        render(big, p, svgp)
        png = svgp[:-4] + '.png'
        subprocess.run(['rsvg-convert', '-w', str(px), '-h', str(px), svgp, '-o', png], check=True)
        im = Image.open(png).convert('RGB')
        if turn:
            # the walk runs left to right, its head (z-) at the left
            im = im.rotate(90, expand=True)
        tiles.append(im)
        os.remove(svgp)
        os.remove(png)
    if turn:
        tiles = [t.crop((int(px * 0.03), 0, int(px * 0.97), px)) for t in tiles]
    w = sum(t.width for t in tiles)
    sheet = Image.new('RGB', (w, px), '#0c1120')
    x = 0
    for t in tiles:
        sheet.paste(t, (x, 0))
        x += t.width
    sheet.save(path, optimize=True)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else '.'
    only = sys.argv[2:]
    os.makedirs(out, exist_ok=True)
    stats = {}
    stats_path = os.path.join(out, 'stats.json')
    if only and os.path.exists(stats_path):
        stats = json.load(open(stats_path))
    for cls in PROPOSALS:
        tag = f'{cls.area}-{cls.name}'
        if only and tag not in only:
            continue
        small = run(cls, 10)
        big = run(cls, 1000)
        p = settled_plot(big)
        for prop, plot, label in [(small, 0, '10'), (big, p, 'full')]:
            svgp = os.path.join(out, f'{tag}-{label}.svg')
            render(prop, plot, svgp)
            png = svgp[:-4] + '.png'
            subprocess.run(['rsvg-convert', '-w', '820', '-h', '820', svgp, '-o', png], check=True)
            os.remove(svgp)
        s = big.stats()
        s['plot_shown'] = p
        s['in_plot_shown'] = len(big.plots[p])
        s['capacity_shown'] = big.capacity(p)
        s['first_plot_at_10'] = len(small.plots[0])
        s['plots_at_10'] = len(small.plots)
        stats[tag] = s
        print(tag, s)
    if not only or 'strips' in only:
        strip(WalkA, [2, 3, 4], os.path.join(out, 'walk-a-three.png'), turn=True)
        strip(QuietA, [0, 1, 2, 3], os.path.join(out, 'quiet-a-rooms.png'))
    if not only:
        for cls in BASELINES:
            s = run(cls, 1000).stats()
            s['first_plot_at_10'] = len(run(cls, 10).plots[0])
            stats[f'{cls.area}-now'] = s
            print(f'{cls.area}-now', s)
    with open(stats_path, 'w') as f:
        json.dump(stats, f, indent=1)


if __name__ == '__main__':
    main()
