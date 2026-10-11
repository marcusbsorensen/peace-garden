"""The turn marks' heads, measured before and after the 11 October change.

    python3 design/garden-controls-2026-10-11/measure-arrowheads.py

Replays `TurnGlyph` (App/PeaceGarden/Views/Glyphs.swift) at the tray's size,
a 20 pt mark whose circle has a radius of 8 pt, and prints for each barb: its
length, its angle to the arc's tangent at the tip, and how far its free end
stands from the circle. That distance is the radial one, |distance from the
centre - radius|, which is the nearest point of the circle; for both barbs the
nearest point lies on the drawn arc, not in the gap. Then the clear space
between the head and the plot's diamond, stroke widths (1.2 pt) taken off.
"""
import math

RADIUS = 8.0         # points, in the tray's 20 pt mark
STROKE = 1.2         # Chrome.monoline
END = math.pi * 3.30  # where the stroke ends: the tip, screen angles clockwise

BEFORE = dict(back=0.55, spread=0.42, lean=0.0, plot=0.62)


def lean_for(back, spread):
    """sin(lean) = b (1 - sqrt(1 - s^2)) / s^2: the turn in, towards the
    centre, that puts both free ends the same distance from the circle while
    keeping the barbs one length. Derived in TurnGlyph.lean's comment."""
    return math.asin(back * (1 - math.sqrt(1 - spread ** 2)) / spread ** 2)


AFTER = dict(back=0.50, spread=0.34, lean=lean_for(0.50, 0.34), plot=0.54)


def head(back, spread, lean, **_):
    tip = (RADIUS * math.cos(END), RADIUS * math.sin(END))
    along = (-math.sin(END), math.cos(END))
    out = (math.cos(END), math.sin(END))
    s, c = math.sin(lean), math.cos(lean)
    backwards = (-along[0] * c - out[0] * s, -along[1] * c - out[1] * s)
    outwards = (out[0] * c - along[0] * s, out[1] * c - along[1] * s)
    ends = {}
    for name, side in (("outer", 1), ("inner", -1)):
        ends[name] = (tip[0] + (backwards[0] * back + outwards[0] * spread * side) * RADIUS,
                      tip[1] + (backwards[1] * back + outwards[1] * spread * side) * RADIUS)
    return tip, ends, along


def point_to_segment(p, a, b):
    dx, dy = b[0] - a[0], b[1] - a[1]
    t = max(0.0, min(1.0, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / (dx * dx + dy * dy)))
    return math.hypot(p[0] - a[0] - t * dx, p[1] - a[1] - t * dy)


def segment_gap(a, b, c, d, n=400):
    pts = lambda p, q: [(p[0] + (q[0] - p[0]) * i / n, p[1] + (q[1] - p[1]) * i / n) for i in range(n + 1)]
    return min(min(point_to_segment(p, c, d) for p in pts(a, b)),
               min(point_to_segment(p, a, b) for p in pts(c, d)))


def report(title, geometry):
    tip, ends, along = head(**geometry)
    print(f"{title}: reach {geometry['back']:.2f} r back, {geometry['spread']:.2f} r out, "
          f"turned in {math.degrees(geometry['lean']):.2f} deg")
    gaps = {}
    for name, (x, y) in ends.items():
        dx, dy = x - tip[0], y - tip[1]
        length = math.hypot(dx, dy)
        # The tangent at the tip, pointing back the way the stroke came.
        cosine = -(dx * along[0] + dy * along[1]) / length
        angle = math.degrees(math.acos(cosine))
        gaps[name] = abs(math.hypot(x, y) - RADIUS)
        print(f"  {name} barb: {length:.2f} pt long, {angle:4.1f} deg to the tangent at the tip, "
              f"free end {gaps[name]:.2f} pt from the circle")
    print(f"  outer gap / inner gap: {gaps['outer'] / gaps['inner']:.2f}")
    w = RADIUS * geometry["plot"]
    h = w * 0.58
    corners = [(0, -h), (w, 0), (0, h), (-w, 0)]
    clear = min(segment_gap(tip, e, corners[i], corners[(i + 1) % 4])
                for e in ends.values() for i in range(4)) - STROKE
    print(f"  plot diamond {geometry['plot']:.2f} r wide each way; clear space to the head {clear:.2f} pt")


if __name__ == "__main__":
    report("Before", BEFORE)
    report("After", AFTER)
