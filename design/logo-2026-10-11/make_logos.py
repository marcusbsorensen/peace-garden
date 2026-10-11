#!/usr/bin/env python3
"""
Peace Garden logo, round two, 11 October 2026. Design exploration only:
nothing here touches a live asset.

  python3 design/logo-2026-10-11/make_logos.py

Refines round one's D (Meeting) and E (Leaf and curl) against the suite apps'
measured icons (`measure.py`, `measurements.json`), each at two weights:

  suite  the suite's median stroke, 0.0654 of the tile (UnCubed's; the five
         apps run 0.052–0.079)
  light  a step lighter, 0.0524 of the tile: Pfish's, the lightest stroke in
         the suite, so the bridge towards the app's fine drawing never leaves
         the suite's own range

Reuses round one's spline writer (`path_d`) and the bract (`spathe`), which
is the loading fiddlehead's, so the leaf is the same leaf.

Suite rules kept (`uncubed/docs/design/suite-brand.md` on `integration`):
ground #0D0D1F (§3.1); strokes, never filled shapes, round free ends (§3.2);
one gradient bottom-left to top-right (§3.3), an even sweep, since each mark's
gradient element is one continuous stem; Peace Garden's green band (§3.4);
the warm white leaf as a secondary accent (§3.6). Marcus's rules kept: every
line a curve, no ground line, the plant grows from a free round end.

  pip install numpy
"""

import importlib.util
import math
from pathlib import Path

from colour import GROUND, contrast, on_dark, on_light

HERE = Path(__file__).resolve().parent

# Round one's module has this file's name, so it is loaded under another.
_spec = importlib.util.spec_from_file_location(
    "round_one", HERE.parent / "logo-2026-10-10" / "make_logos.py")
round_one = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(round_one)
path_d, spathe, thin = round_one.path_d, round_one.spathe, round_one.thin

LIGHT_GROUND = "#F6F6F6"    # the website's light ground (`site.css`)
INK = "#121212"             # the website's light ink (`site.css`)
LEAF = "#F4F3EF"            # the suite's warm white (UnCubed's exponent)

# The calmer ramp: sage → moss → green-gold, isoluminant at 9.7:1 on the
# ground. Hues 124° → 98° → 76°, inside Peace Garden's band and clear of both
# neighbours: the sage end starts below Pfish's 150° at low saturation (ΔE2000
# ≥ 13 from every Pfish stop) and the gold end stops at 76°, not round one's
# 60° straw, which sat ΔE 14 from FlagFans' #F0C24E (now ≥ 19.5).
HUES = (124.0, 98.0, 76.0)
SATS = (0.24, 0.34, 0.44)
DARK_CONTRAST = 9.7
LIGHT_CONTRAST = 4.6
LIGHT_SATS = (0.38, 0.54, 0.60)

TILE_STROKE = {"suite": 0.0654, "light": 0.0524}   # of the tile, measured
LEAF_WEIGHT = 0.72   # the leaf's stroke against the stem's; the suite's accents run
                     # 0.40 (ARC) to 0.82 (UnCubed), FlagFans' crossbar 0.69
INK_HEIGHT = 0.70    # the ink's height as a share of the tile: the suite's median 0.71

WORDMARK_FONT = ("-apple-system, 'SF Pro Text', BlinkMacSystemFont, Inter, "
                 "'Helvetica Neue', sans-serif")


def ramp(light=False):
    if light:
        return [on_light(h, s, LIGHT_CONTRAST, LIGHT_GROUND) for h, s in zip(HUES, LIGHT_SATS)]
    return [on_dark(h, s, DARK_CONTRAST) for h, s in zip(HUES, SATS)]


# ---------------------------------------------------------------- geometry
#
# Frame: 100 wide, y down, the root near y 130. A stroke is integrated from a
# heading function, so every line is a curve by construction.

def grow(root, length, heading, n=120):
    x, y = root
    pts = [(x, y)]
    for i in range(1, n + 1):
        s = i / n
        h = heading(s)
        x += math.cos(h) * length / n
        y += math.sin(h) * length / n
        pts.append((x, y))
    return pts, heading(1.0)


def curl(root, start_heading, r_out, r_in, turns, hand, n=180):
    """A crozier head: a logarithmic spiral entered on `start_heading`, its
    radius falling from `r_out` to `r_in` over `turns` turns. `r_in` is held
    at about 1.3 strokes so a heavy stroke never fills the coil's eye — the
    fault that closed round one's curls into dots at the suite's weight."""
    total = 2 * math.pi * turns
    x, y = root
    pts = [(x, y)]
    h = start_heading
    for i in range(1, n + 1):
        t = total * (i - 0.5) / n
        r = r_out * (r_in / r_out) ** (t / total)
        ds = r * total / n
        h = start_heading + hand * t
        x += math.cos(h) * ds
        y += math.sin(h) * ds
        pts.append((x, y))
    return pts, h


def meeting(small=False):
    """D, Meeting, lifted. Two fronds from one root: the tall one opens into
    the leaf, held up and outward; the second leaves it low down and is still
    a crozier, its open coil carried above the fork and rolling outward.
    Round one hung the leaf from a hooked stem and let the crozier fall away
    off the stem's side; here every head points up or out, and no part of the
    crozier drops below the point it grew from."""
    root = (50, 130)
    a, ha = grow(root, 86, lambda s: -math.pi / 2 - 0.08 - 0.36 * s ** 1.5 + 0.12 * math.sin(math.pi * s))
    fork = a[22 * len(a) // 120]
    if small:
        # Below 32 px: a fatter leaf so its eye stays open, and less coil.
        leaf = spathe(a[-1], ha, 42, hand=-1, width=0.38)
        b, hb = grow(fork, 50, lambda s: -math.pi / 2 + 0.16 + 0.42 * s)
        c, _ = curl(b[-1], hb, 26, 20, 0.62, +1)
    else:
        leaf = spathe(a[-1], ha, 40, hand=-1, width=0.32)
        b, hb = grow(fork, 52, lambda s: -math.pi / 2 + 0.14 + 0.40 * s)
        c, _ = curl(b[-1], hb, 24, 16, 0.85, +1)
    crozier = b + c[1:]
    return [(crozier, "stem", False), (a, "stem", False), (leaf, "leaf", True)]


def leaf_and_curl(small=False):
    """E, Leaf and curl. Round one's figure kept: a stem leaning up and to the
    right, the way the gradient runs, carrying the leaf upright, and one
    tendril leaving low on the stem. The tendril now lifts — it leaves to the
    left and sweeps up, an arm raised, its tip pointing up and away — where
    round one's rose and then rolled down below its own start. It turns less
    than a third of a turn, so at the suite's weight it never closes back on
    the stem."""
    root = (52, 130)
    stem, h = grow(root, 104, lambda s: -math.pi / 2 + 0.46 * s ** 1.6 - 0.20 * math.sin(math.pi * s))
    j = len(stem) // 4
    if small:
        leaf = spathe(stem[-1], h, 42, hand=1, width=0.38)
        t0, th = grow(stem[j], 30, lambda s: -math.pi + 0.40 + 0.50 * s)
        tc, _ = curl(t0[-1], th, 22, 18, 0.20, +1)
    else:
        leaf = spathe(stem[-1], h, 31, hand=1, width=0.36)
        t0, th = grow(stem[j], 32, lambda s: -math.pi + 0.35 + 0.50 * s)
        tc, _ = curl(t0[-1], th, 20, 14, 0.25, +1)
    tendril = [stem[j]] + t0[1:] + tc[1:]
    return [(tendril, "stem", False), (stem, "stem", False), (leaf, "leaf", True)]


CANDIDATES = [
    # (folder, title, drawing, weight)
    ("d-suite", "D, Meeting, at the suite's weight", meeting, "suite"),
    ("d-light", "D, Meeting, a step lighter", meeting, "light"),
    ("e-suite", "E, Leaf and curl, at the suite's weight", leaf_and_curl, "suite"),
    ("e-light", "E, Leaf and curl, a step lighter", leaf_and_curl, "light"),
]


# ---------------------------------------------------------------- writing

def bounds(strokes, stroke, leaf_w):
    """The ink box, half a stroke included."""
    xs0, ys0, xs1, ys1 = [], [], [], []
    for pts, role, _ in strokes:
        half = (leaf_w if role == "leaf" else stroke) / 2
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        xs0.append(min(xs) - half)
        xs1.append(max(xs) + half)
        ys0.append(min(ys) - half)
        ys1.append(max(ys) + half)
    return min(xs0), min(ys0), max(xs1), max(ys1)


def place(strokes, box, stroke_frac):
    """Scale the drawing so its ink, strokes included, fits `box` (x, y, w, h)
    centred, with the stroke held at `stroke_frac` of the box's height. Half a
    stroke is reserved on every side, since the stroke is part of the ink."""
    bx, by, bw, bh = box
    stroke = stroke_frac * bh
    x0, y0, x1, y1 = bounds(strokes, 0, 0)
    k = min((bw - stroke) / (x1 - x0), (bh - stroke) / (y1 - y0))
    ox = bx + (bw - (x1 - x0) * k) / 2 - x0 * k
    oy = by + (bh - (y1 - y0) * k) / 2 - y0 * k
    placed = [([(ox + x * k, oy + y * k) for x, y in pts], role, closed)
              for pts, role, closed in strokes]
    return placed, stroke


def body(strokes, stroke, stops, leaf, gid, one=None):
    x0, y0, x1, y1 = bounds(strokes, stroke, stroke * LEAF_WEIGHT)
    defs = ""
    if one is None:
        st = "".join(f'<stop offset="{i / (len(stops) - 1):g}" stop-color="{c}"/>'
                     for i, c in enumerate(stops))
        defs = (f'<defs><linearGradient id="{gid}" gradientUnits="userSpaceOnUse" '
                f'x1="{x0:.2f}" y1="{y1:.2f}" x2="{x1:.2f}" y2="{y0:.2f}">{st}</linearGradient></defs>')
    out = []
    for pts, role, closed in strokes:
        colour = one or (f"url(#{gid})" if role == "stem" else leaf)
        w = stroke if role == "stem" else stroke * LEAF_WEIGHT
        out.append(f'<path d="{path_d(thin(pts, 3 if closed else 4), closed)}" '
                   f'stroke="{colour}" stroke-width="{w:.2f}"/>')
    return defs, ('<g fill="none" stroke-linecap="round" stroke-linejoin="round">'
                  + "".join(out) + "</g>")


def svg(w, h, title, inner, extra=""):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w:g} {h:g}" '
            f'width="{w:g}" height="{h:g}"{extra}><title>{title}</title>{inner}</svg>\n')


def drawing(draw, small, box, stroke_frac, stops, leaf, one=None, gid="g"):
    placed, stroke = place(draw(small), box, stroke_frac)
    return body(placed, stroke, stops, leaf, gid, one)


def write_candidate(folder, title, draw, weight):
    out = HERE / folder
    out.mkdir(exist_ok=True)
    dark, light = ramp(False), ramp(True)
    name = f"Peace Garden, {title}"
    files = {}
    # The stroke as a share of the ink's height, which is what carries the
    # weight from the icon to every other surface unchanged.
    of_ink = TILE_STROKE[weight] / INK_HEIGHT

    # App icon, 1024, full bleed: iOS applies the mask. Ink 0.70 of the tile
    # high, centred, the suite's median fill.
    h = INK_HEIGHT * 1024
    d, g = drawing(draw, False, ((1024 - h) / 2, (1024 - h) / 2, h, h), of_ink, dark, LEAF)
    files["icon-1024.svg"] = svg(1024, 1024, f"{name}, app icon",
                                 d + f'<rect width="1024" height="1024" fill="{GROUND}"/>' + g)

    # The website mark, bare, for dark and for light grounds.
    full = (4, 4, 92, 92)
    for suffix, stops, leaf, t in (("", dark, LEAF, "for dark grounds"),
                                   ("-light-ground", light, INK, "for light grounds")):
        d, g = drawing(draw, False, full, of_ink, stops, leaf)
        files[f"{folder}{suffix}.svg"] = svg(100, 100, f"{name}, website mark {t}", d + g)
        # The small drawing: below 32 px, heavier by a third and simpler, as
        # the suite's small files are; legible at 16.
        d, g = drawing(draw, True, full, of_ink * 1.35, stops, leaf)
        files[f"{folder}-small{suffix}.svg"] = svg(
            100, 100, f"{name}, small drawing for 16 and 32 px, {t}", d + g)

    d, g = drawing(draw, False, full, of_ink, None, None, one="currentColor")
    files[f"{folder}-one-colour.svg"] = svg(100, 100, f"{name}, one colour (currentColor)",
                                            d + g, ' color="#121212"')
    # Favicon: the small drawing on the rounded ground tile, as the suite's.
    d, g = drawing(draw, True, (17, 13, 74, 74), of_ink * 1.35, dark, LEAF)
    files[f"{folder}-favicon.svg"] = svg(
        100, 100, f"{name}, favicon",
        d + f'<rect width="100" height="100" rx="22" fill="{GROUND}"/>' + g)

    # Lockups: the bare mark beside the site's wordmark as set today (system
    # sans, 400, tracked 0.18 em, mixed case; `site.css` .wordmark).
    for suffix, ground, stops, leaf, ink in (("", GROUND, dark, LEAF, "#FFFFFF"),
                                             ("-light-ground", LIGHT_GROUND, light, INK, INK)):
        d, g = drawing(draw, False, (14, 12, 76, 76), of_ink, stops, leaf)
        lock = (d + f'<rect width="420" height="100" fill="{ground}"/>' + g +
                f'<text x="104" y="59.5" font-family="{WORDMARK_FONT}" font-size="30" '
                f'font-weight="400" letter-spacing="5.4" fill="{ink}">Peace Garden</text>')
        files[f"{folder}-lockup{suffix}.svg"] = svg(420, 100, f"{name}, wordmark lockup", lock)

    for fname, text in files.items():
        (out / fname).write_text(text)


def main():
    for c in CANDIDATES:
        write_candidate(*c)
    dark, light = ramp(False), ramp(True)
    print("dark ramp ", dark, [f"{contrast(c, GROUND):.2f}" for c in dark])
    print("light ramp", light, [f"{contrast(c, LIGHT_GROUND):.2f}" for c in light])
    print("leaf on ground", f"{contrast(LEAF, GROUND):.2f}")


if __name__ == "__main__":
    main()
