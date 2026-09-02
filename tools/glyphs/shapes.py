"""The four stage-row marks, transcribed from Swift into SVG path data.

`SeedGlyph`, `GardenGlyph` and `CogShape` live in `App/PeaceGarden/Views/Chrome.swift`;
`MeetGlyph` is in `Views/Glyphs.swift`. **Swift is authoritative.** This is a
mirror, kept so the marks can be rendered and looked at without a simulator —
the same bargain `tools/preview` makes for the plant, and it will drift the same
way.

Everything is emitted in a 15 x 15 box, because fifteen points is the size the
row actually draws them at, and every failure so far has been a failure at that
size rather than at any other.
"""

import math

SIDE = 15.0
STROKE = 1.2


def _inset(side, d=0.6):
    return d, d, side - 2 * d, side - 2 * d


def seed(side=SIDE, tilt=20.0):
    """Round at the foot, drawn to a point at the crown, and leaning."""
    # width = min(rect.width, rect.height / 1.5)
    width = min(side, side / 1.5)
    x, y, w, h = side / 2 - width / 2, 0.0, width, side
    x, y, w, h = x + 0.6, y + 0.6, w - 1.2, h - 1.2
    mid_x, min_y, max_y = x + w / 2, y, y + h
    d = (
        f"M {mid_x} {max_y} "
        f"C {x + w} {max_y - h * 0.10}, {mid_x + w * 0.16} {min_y + h * 0.34}, {mid_x} {min_y} "
        f"C {mid_x - w * 0.16} {min_y + h * 0.34}, {x} {max_y - h * 0.10}, {mid_x} {max_y} Z"
    )
    return [(d, f"rotate({tilt} {side / 2} {side / 2})")]


def meet(side=SIDE):
    """Two unequal stems crossing low, each ending in a curl."""
    x, y, w, h = _inset(side)

    def at(u, v):
        return x + w * u, y + h * v

    p = []
    p.append("M %g %g C %g %g, %g %g, %g %g Q %g %g, %g %g" % (
        *at(0.34, 1.0), *at(0.40, 0.70), *at(0.84, 0.50), *at(0.76, 0.22),
        *at(0.74, 0.05), *at(0.56, 0.13)))
    p.append("M %g %g C %g %g, %g %g, %g %g Q %g %g, %g %g" % (
        *at(0.66, 1.0), *at(0.60, 0.78), *at(0.15, 0.64), *at(0.22, 0.40),
        *at(0.26, 0.23), *at(0.42, 0.32)))
    return [(" ".join(p), None)]


def garden(side=SIDE):
    """Three different plants on a short bed line."""
    x, y, w, h = _inset(side)

    def at(u, v):
        return x + w * u, y + h * v

    p = []
    # Left, shortest: a round head, leaning out of the bed.
    p.append("M %g %g Q %g %g, %g %g" % (*at(0.18, 1.0), *at(0.18, 0.74), *at(0.08, 0.50)))
    r = w * 0.17 / 2
    cx, cy = x + r, y + h * 0.26 + r
    p.append(f"M {cx - r} {cy} a {r} {r} 0 1 0 {2 * r} 0 a {r} {r} 0 1 0 {-2 * r} 0")
    # Middle, tallest: a spire, its flowers as ticks up the stem.
    p.append("M %g %g Q %g %g, %g %g" % (*at(0.48, 1.0), *at(0.45, 0.55), *at(0.50, 0.10)))
    for ty, flank in [(0.42, 1.0), (0.31, -1.0), (0.21, 1.0)]:
        p.append("M %g %g L %g %g" % (*at(0.49, ty), *at(0.49 + 0.09 * flank, ty - 0.05)))
    # Right: a bell, nodding.
    p.append("M %g %g C %g %g, %g %g, %g %g" % (
        *at(0.84, 1.0), *at(0.92, 0.76), *at(0.94, 0.46), *at(0.82, 0.36)))
    p.append("M %g %g Q %g %g, %g %g" % (*at(0.74, 0.37), *at(0.82, 0.66), *at(0.90, 0.37)))
    # The bed: under their feet, not the width of the frame.
    p.append("M %g %g L %g %g" % (*at(0.06, 1.0), *at(0.94, 1.0)))
    return [(" ".join(p), None)]


def cog(side=SIDE, teeth=8):
    """A large ring with short teeth: a graduated dial rather than machinery."""
    c = side / 2
    half = side / 2
    ring, tip = half * 0.70, half * 0.94
    p = [f"M {c - ring} {c} a {ring} {ring} 0 1 0 {2 * ring} 0 a {ring} {ring} 0 1 0 {-2 * ring} 0"]
    for i in range(teeth):
        b = i * 2 * math.pi / teeth - math.pi / 2
        p.append("M %g %g L %g %g" % (c + ring * math.cos(b), c + ring * math.sin(b),
                                      c + tip * math.cos(b), c + tip * math.sin(b)))
    return [(" ".join(p), None)]


MARKS = [("Seed", seed), ("Meet", meet), ("Garden", garden), ("Settings", cog)]
