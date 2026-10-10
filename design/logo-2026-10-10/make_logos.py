#!/usr/bin/env python3
"""
Logo directions for Peace Garden, 10 October 2026. Design exploration only:
nothing here touches a live asset.

  python3 design/logo-2026-10-10/make_logos.py

Writes every direction's SVG masters into its own folder beside this file.
`make_sheets.py` renders them.

The drawing is the loading fiddlehead's (`App/PeaceGarden/Views/Loading/
Fiddlehead.swift`, branch `worktree-agent-a944b9f3f00872bf1`), ported line for
line in `frond()`, so a mark taken from here and the launch moment are the same
figure. No direction draws a ground: a plant grows from a free round end or
from the edge of its tile.

Suite rules kept (`interfulgent-hub/docs/2026-10-09-site-and-hub-design.md`
§3.7; `docs/BRAND.md`): ground `#0D0D1F`, monoline of even weight with round
ends, one gradient running bottom-left to top-right, Peace Garden's 140° → 60°
hue segment, isoluminant stops solved rather than chosen, a separate `-small`
drawing below 24 px, and a `-light-ground` drawing that darkens the stops and
turns the white element to ink.

  pip install numpy
"""

import colorsys
import math
from pathlib import Path

HERE = Path(__file__).resolve().parent

GROUND = "#0D0D1F"          # the suite's dark ground, and the launch ground
LIGHT_GROUND = "#F6F6F6"    # the website's light ground (`site.css`)
INK = "#121212"             # the website's light ink (`site.css`)
# The leaf. Not #FFFFFF: the suite already has a warm off-white in UnCubed's
# exponent, and a mark this fine glares in pure white beside the app's muted
# plants. Using the suite's existing one adds no third white.
LEAF = "#F4F3EF"

# The calmer ramp: the same three hues as today (forest green, lime, yellow,
# 140° → 60°), still isoluminant, but at 0.36 saturation and 9.5:1 instead of
# 0.95 and 13:1. Sage, moss and straw rather than neon.
HUES = (140.0, 100.0, 60.0)
SATURATION = 0.36
DARK_CONTRAST = 9.5
LIGHT_CONTRAST = 4.5

WORDMARK_FONT = ("-apple-system, 'SF Pro Text', BlinkMacSystemFont, Inter, "
                 "'Helvetica Neue', sans-serif")


# ------------------------------------------------------------------ colour

def _lum(rgb):
    ch = [v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4 for v in rgb]
    return 0.2126 * ch[0] + 0.7152 * ch[1] + 0.0722 * ch[2]


def _rgb(value):
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) / 255 for i in (0, 2, 4))


def _hex(rgb):
    return "#" + "".join(f"{round(c * 255):02X}" for c in rgb)


def _solve(hue, target):
    low, high = 0.0, 1.0
    for _ in range(60):
        mid = (low + high) / 2
        if _lum(colorsys.hls_to_rgb(hue / 360, mid, SATURATION)) < target:
            low = mid
        else:
            high = mid
    return _hex(colorsys.hls_to_rgb(hue / 360, (low + high) / 2, SATURATION))


def contrast(a, b):
    la, lb = _lum(_rgb(a)), _lum(_rgb(b))
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)


def ramp(light=False):
    if light:
        target = (_lum(_rgb(LIGHT_GROUND)) + 0.05) / LIGHT_CONTRAST - 0.05
    else:
        target = DARK_CONTRAST * (_lum(_rgb(GROUND)) + 0.05) - 0.05
    return [_solve(h, target) for h in HUES]


# ---------------------------------------------------------------- geometry

def frond(open_=0.9, rise=1.0, length=0.82, taper=3.0, turn_open=0.7,
          turn_furled=2.7, hand=-1, bract=0.24, sway=0.2, root=(68, 130),
          bract_width=0.30, steps=130, lean=0.0):
    """`Fiddlehead.figure(open:rise:)`, ported. Frame 100 × 130, y down."""
    held = min(max(open_, 0), 1)
    grown = 0.16 + 0.84 * min(max(rise, 0), 1)
    turn = math.pi * (turn_open + (turn_furled - turn_open) * (1 - held))
    run = 130 * length * grown
    step = run / steps
    x, y = root
    stem = [(x, y)]
    base = -math.pi / 2 + lean
    heading = base
    for i in range(1, steps + 1):
        s = i / steps
        heading = base + hand * turn * s ** taper + sway * math.sin(math.pi * s)
        x += math.cos(heading) * step
        y += math.sin(heading) * step
        stem.append((x, y))
    leaf = spathe((x, y), heading, 130 * bract * grown, hand, bract_width,
                  bud=_beat(held, 0.2, 1.0))
    return stem, leaf


def _beat(v, a, b):
    t = min(max((v - a) / (b - a), 0), 1)
    return t * t * (3 - 2 * t)


def spathe(mouth, heading, length, hand=-1, width=0.30, bud=1.0, ribs=24):
    """The bract as `Fiddlehead` draws it: leaves on the stem's own tangent and
    keeps turning the same way, profile `sin(π s^0.85)`."""
    sweep = 0.34 * hand
    spine = [mouth]
    tx, ty = mouth
    for i in range(1, ribs + 1):
        a = heading + sweep * i / ribs
        tx += math.cos(a) * length / ribs
        ty += math.sin(a) * length / ribs
        spine.append((tx, ty))
    near, far = [], []
    for i in range(ribs + 1):
        s = i / ribs
        half = width * length * math.sin(math.pi * s ** 0.85)
        j = min(i, ribs - 1)
        a = math.atan2(spine[j + 1][1] - spine[j][1], spine[j + 1][0] - spine[j][0])
        near.append((spine[i][0] - math.sin(a) * half, spine[i][1] + math.cos(a) * half))
        far.append((spine[i][0] + math.sin(a) * half, spine[i][1] - math.cos(a) * half))
    mx, my = mouth
    return [(mx + (px - mx) * bud, my + (py - my) * bud) for px, py in near + far[::-1]]


def log_spiral(turns=1.45, r0=10.0, growth=2.9, bearing=58.0, steps=220):
    """The current mark's coil, loosened: logarithmic, centre outwards,
    anticlockwise, its outer end pointing at `bearing` (degrees from east)."""
    k = math.log(growth) / (2 * math.pi)
    total = 2 * math.pi * turns
    pts = []
    for i in range(steps + 1):
        t = total * i / steps
        r = r0 * math.exp(k * t)
        pts.append((r * math.cos(t), -r * math.sin(t)))
    # Tangent at the end, then rotate the whole so it points at `bearing`.
    (ax, ay), (bx, by) = pts[-2], pts[-1]
    now = math.atan2(-(by - ay), bx - ax)
    rot = math.radians(bearing) - now
    c, s = math.cos(rot), math.sin(rot)
    pts = [(x * c + y * s, -x * s + y * c) for x, y in pts]
    (ax, ay), (bx, by) = pts[-2], pts[-1]
    return pts, math.atan2(by - ay, bx - ax)


# ----------------------------------------------------------- the directions
#
# Each returns a list of strokes: (points, role, closed). Role "stem" takes the
# gradient; "leaf" takes the leaf colour. `edge` means the stem runs off the
# bottom of its tile rather than ending on a free round end.

def fiddlehead(small=False):
    if small:
        stem, leaf = frond(open_=0.85, length=0.62, bract=0.36, bract_width=0.34, sway=0.15)
        return [(stem, "stem", False), (leaf, "leaf", True)]
    stem, leaf = frond(open_=0.8, bract=0.28)
    return [(stem, "stem", False), (leaf, "leaf", True)]


def edge(small=False):
    # Taller, still half furled: a bud held in the curl, the stem coming up
    # from below the frame, so the tile's own edge is where it grows from.
    if small:
        stem, leaf = frond(open_=0.72, length=1.05, bract=0.34, bract_width=0.34,
                           root=(66, 175), sway=0.12)
    else:
        stem, leaf = frond(open_=0.72, length=1.15, bract=0.25, root=(66, 185), sway=0.16)
    return [(stem, "stem", False), (leaf, "leaf", True)]


def spiral(small=False):
    # Today's mark, calmed: fewer turns, opened out, a hairline, and the white
    # leaf on its end in place of the filled taper and the spadix.
    if small:
        coil, heading = log_spiral(turns=1.05, r0=14, growth=3.2)
        leaf = spathe(coil[-1], heading, 46, hand=-1, width=0.34)
    else:
        coil, heading = log_spiral()
        leaf = spathe(coil[-1], heading, 52, hand=-1, width=0.30)
    return [(coil, "stem", False), (leaf, "leaf", True)]


def meeting(small=False):
    # Two fronds: one opened into its leaf, and a second crozier, still curled,
    # leaving the first a quarter of the way up and turning the other way. The
    # app is about two people meeting and what that grows.
    root = (55, 130)
    if small:
        a, la = frond(open_=0.85, length=0.70, bract=0.32, bract_width=0.34, root=root, sway=0.30)
        fork = a[len(a) // 6]
        b, _ = frond(open_=0.25, length=0.40, hand=1, root=fork, sway=0.0, taper=2.2, lean=0.5)
        return [(b, "stem", False), (a, "stem", False), (la, "leaf", True)]
    a, la = frond(open_=0.8, length=0.82, root=root, sway=0.28)
    fork = a[len(a) // 6]
    b, _ = frond(open_=0.30, length=0.44, hand=1, root=fork, sway=0.0, taper=2.2, lean=0.5)
    return [(b, "stem", False), (a, "stem", False), (la, "leaf", True)]


def leaf_and_curl(small=False):
    # The leaf held up, not hanging: a short stem leaning up and to the right,
    # the way the gradient runs, carrying an upright spathe, and one tendril
    # still coiled off the stem below it. The strongest at sixteen pixels.
    root = (40, 128)
    stem = []
    x, y = root
    n = 90
    run = 64 if small else 80
    for i in range(n + 1):
        s = i / n
        h = -math.pi / 2 + 0.55 * s ** 1.6 - 0.22 * math.sin(math.pi * s)
        if i:
            x += math.cos(h) * run / n
            y += math.sin(h) * run / n
        stem.append((x, y))
    leaf = spathe(stem[-1], h, 58 if small else 52, hand=1, width=0.32 if small else 0.27)
    strokes = [(stem, "stem", False), (leaf, "leaf", True)]
    # The tendril leaves from a third of the way up and curls to the left.
    j = n // 3 if not small else n // 4
    tx, ty = stem[j]
    t = []
    tlen = 30 if small else 34
    for i in range(61):
        s = i / 60
        h = -math.pi / 2 - 0.55 - 3.4 * s ** 2.6
        if i:
            tx += math.cos(h) * tlen / 60
            ty += math.sin(h) * tlen / 60
        t.append((tx, ty))
    strokes.insert(0, (t, "stem", False))
    return strokes


DIRECTIONS = [
    # (folder, title, drawing, edge, icon stroke /1024, mark stroke /100,
    #  small stroke /100)
    ("a-fiddlehead", "Fiddlehead", fiddlehead, False, 20, 3.2, 8.5),
    ("b-from-the-edge", "From the edge", edge, True, 20, 3.2, 8.5),
    ("c-spiral-unwound", "Spiral, unwound", spiral, False, 22, 3.4, 9.0),
    ("d-meeting", "Meeting", meeting, False, 19, 3.0, 8.0),
    ("e-leaf-and-curl", "Leaf and curl", leaf_and_curl, False, 22, 3.4, 9.0),
]


# ---------------------------------------------------------------- writing

def _bounds(strokes, pad=0.0):
    xs = [p[0] for s in strokes for p in s[0]]
    ys = [p[1] for s in strokes for p in s[0]]
    return min(xs) - pad, min(ys) - pad, max(xs) + pad, max(ys) + pad


def fit(strokes, box, stroke, edge=False, bottom=None):
    """Scale and place the drawing so its ink, half a stroke included, sits
    centred in `box` (x, y, w, h). For an edge drawing only the part above
    `bottom` (in output units) is fitted; the rest runs out of the frame."""
    bx, by, bw, bh = box
    if edge:
        # Fit the drawing's top and sides; the stem's lower end is pushed
        # past `bottom` so it leaves the frame.
        x0, y0, x1, y1 = _bounds([s for s in strokes if s[1] == "leaf"] +
                                 [(s[0][len(s[0]) // 3:], s[1], s[2]) for s in strokes if s[1] == "stem"])
        k = min(bw / (x1 - x0), bh / (y1 - y0))
        x0b, _, x1b, _ = _bounds(strokes)
        ox = bx + (bw - (x1b - x0b) * k) / 2 - x0b * k
        oy = by + stroke / 2 - y0 * k
    else:
        x0, y0, x1, y1 = _bounds(strokes)
        k = min((bw - stroke) / (x1 - x0), (bh - stroke) / (y1 - y0))
        ox = bx + (bw - (x1 - x0) * k) / 2 - x0 * k
        oy = by + (bh - (y1 - y0) * k) / 2 - y0 * k
    return [([(ox + x * k, oy + y * k) for x, y in pts], role, closed)
            for pts, role, closed in strokes]


def path_d(pts, closed):
    """Catmull–Rom through the points as cubic Béziers: every segment curved."""
    p = []
    for q in pts:  # coincident points (the bract's mouth and tip) kink a spline
        if not p or math.hypot(q[0] - p[-1][0], q[1] - p[-1][1]) > 1e-3:
            p.append(q)
    if closed:
        p = p[:-1] if p[0] == p[-1] else p
        n = len(p)
        get = lambda i: p[i % n]
        rng = range(n)
    else:
        n = len(p)
        get = lambda i: p[min(max(i, 0), n - 1)]
        rng = range(n - 1)
    d = [f"M{p[0][0]:.2f} {p[0][1]:.2f}"]
    for i in rng:
        p0, p1, p2, p3 = get(i - 1), get(i), get(i + 1), get(i + 2)
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        d.append(f"C{c1[0]:.2f} {c1[1]:.2f} {c2[0]:.2f} {c2[1]:.2f} {p2[0]:.2f} {p2[1]:.2f}")
    if closed:
        d.append("Z")
    return "".join(d)


def thin(pts, every):
    out = pts[::every]
    if out[-1] != pts[-1]:
        out.append(pts[-1])
    return out


def body(strokes, stroke, stops, leaf, gid, fade=None, one=None):
    """The drawing as SVG elements. `fade` (y0, y1) fades the stem to nothing
    towards the bottom, for an edge mark without its tile."""
    x0, y0, x1, y1 = _bounds(strokes)
    defs = []
    if one is None:
        st = "".join(f'<stop offset="{i / (len(stops) - 1):g}" stop-color="{c}"/>'
                     for i, c in enumerate(stops))
        defs.append(f'<linearGradient id="{gid}" gradientUnits="userSpaceOnUse" '
                    f'x1="{x0:.2f}" y1="{y1:.2f}" x2="{x1:.2f}" y2="{y0:.2f}">{st}</linearGradient>')
    mask = ""
    if fade:
        defs.append(f'<linearGradient id="{gid}f" gradientUnits="userSpaceOnUse" x1="0" y1="{fade[0]:.2f}" '
                    f'x2="0" y2="{fade[1]:.2f}"><stop offset="0" stop-color="#fff"/>'
                    f'<stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>'
                    f'<mask id="{gid}m" maskUnits="userSpaceOnUse" x="-1000" y="-1000" width="3000" height="3000">'
                    f'<rect x="-1000" y="-1000" width="3000" height="3000" fill="url(#{gid}f)"/></mask>')
        mask = f' mask="url(#{gid}m)"'
    out = []
    for pts, role, closed in strokes:
        colour = one or (f"url(#{gid})" if role == "stem" else leaf)
        out.append(f'<path d="{path_d(thin(pts, 3 if closed else 4), closed)}" stroke="{colour}"/>')
    g = (f'<g fill="none" stroke-width="{stroke:g}" stroke-linecap="round" '
         f'stroke-linejoin="round"{mask}>' + "".join(out) + "</g>")
    return ("<defs>" + "".join(defs) + "</defs>" if defs else ""), g


def svg(w, h, title, inner, extra_attrs=""):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w:g} {h:g}" '
            f'width="{w:g}" height="{h:g}"{extra_attrs}><title>{title}</title>{inner}</svg>\n')


def write_direction(folder, title, draw, is_edge, s_icon, s_mark, s_small):
    out = HERE / folder
    out.mkdir(exist_ok=True)
    dark, light = ramp(False), ramp(True)
    name = f"Peace Garden, {title}"
    files = {}

    # App icon, 1024, full bleed: iOS applies the mask. The ink stays inside
    # a centred circle of radius 400 (the mask's corners begin well outside it).
    big = draw(False)
    if is_edge:
        placed = fit(big, (262, 150, 500, 640), s_icon, edge=True)
    else:
        placed = fit(big, (232, 172, 560, 680), s_icon)
    defs, g = body(placed, s_icon, dark, LEAF, "g")
    files["icon-1024.svg"] = svg(1024, 1024, f"{name}, app icon",
                                 defs + f'<rect width="1024" height="1024" fill="{GROUND}"/>' + g)

    def mark(strokes, stroke, stops, leaf, small, tile=None, one=None):
        if is_edge:
            if tile:
                box = (24, 12, 52, 66) if not small else (20, 8, 60, 70)
                p = fit(strokes, box, stroke, edge=True)
                d, gg = body(p, stroke, stops, leaf, "g", one=one)
                return d + (f'<clipPath id="t"><rect width="100" height="100" rx="22"/></clipPath>'
                            f'<rect width="100" height="100" rx="22" fill="{tile}"/>'
                            f'<g clip-path="url(#t)">{gg}</g>')
            box = (24, 6, 52, 62) if not small else (18, 4, 64, 66)
            p = fit(strokes, box, stroke, edge=True)
            d, gg = body(p, stroke, stops, leaf, "g", fade=(62, 98), one=one)
            return d + gg
        if tile:
            box = (16, 12, 68, 76) if small else (20, 14, 60, 72)
        else:
            box = (8, 4, 84, 92) if small else (10, 4, 80, 92)
        p = fit(strokes, box, stroke)
        d, gg = body(p, stroke, stops, leaf, "g", one=one)
        return d + ((f'<rect width="100" height="100" rx="22" fill="{tile}"/>' if tile else "") + gg)

    small = draw(True)
    files[f"{folder}.svg"] = svg(100, 100, f"{name}, website mark for dark grounds",
                                 mark(big, s_mark, dark, LEAF, False))
    files[f"{folder}-light-ground.svg"] = svg(100, 100, f"{name}, website mark for light grounds",
                                              mark(big, s_mark, light, INK, False))
    files[f"{folder}-small.svg"] = svg(100, 100, f"{name}, small-size drawing below 24 px",
                                       mark(small, s_small, dark, LEAF, True))
    files[f"{folder}-small-light-ground.svg"] = svg(
        100, 100, f"{name}, small-size drawing below 24 px, for light grounds",
        mark(small, s_small, light, INK, True))
    files[f"{folder}-one-colour.svg"] = svg(
        100, 100, f"{name}, one colour (currentColor)",
        mark(big, s_mark, None, None, False, one="currentColor"), ' color="#121212"')
    files[f"{folder}-favicon.svg"] = svg(100, 100, f"{name}, favicon",
                                         mark(small, s_small, dark, LEAF, True, tile=GROUND))
    files[f"{folder}-tile.svg"] = svg(100, 100, f"{name}, website mark on its tile",
                                      mark(big, s_mark * 1.15, dark, LEAF, False, tile=GROUND))

    # Lockups: the bare mark beside the site's wordmark as it is set today —
    # the system sans at 400, tracked 0.18 em, mixed case (`site.css` .wordmark).
    for suffix, ground, stops, leaf, ink in (("", GROUND, dark, LEAF, "#FFFFFF"),
                                             ("-light-ground", LIGHT_GROUND, light, INK, INK)):
        inner = mark(big, s_mark, stops, leaf, False)
        lock = (f'<rect width="420" height="100" fill="{ground}"/>'
                f'<svg x="14" y="10" width="80" height="80" viewBox="0 0 100 100">{inner}</svg>'
                f'<text x="104" y="59.5" font-family="{WORDMARK_FONT}" font-size="30" '
                f'font-weight="400" letter-spacing="5.4" fill="{ink}">Peace Garden</text>')
        files[f"{folder}-lockup{suffix}.svg"] = svg(420, 100, f"{name}, wordmark lockup", lock)

    for fname, text in files.items():
        (out / fname).write_text(text)
    return dark, light


def main():
    for d in DIRECTIONS:
        write_direction(*d)
    dark, light = ramp(False), ramp(True)
    print("dark ramp ", dark, [f"{contrast(c, GROUND):.2f}" for c in dark])
    print("light ramp", light, [f"{contrast(c, LIGHT_GROUND):.2f}" for c in light])
    print("leaf on ground", f"{contrast(LEAF, GROUND):.2f}")


if __name__ == "__main__":
    main()
