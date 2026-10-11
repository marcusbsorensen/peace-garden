#!/usr/bin/env python3
"""
Draws the app icon, to the Interfulgent suite brand system.

The governing document is `uncubed-integration/docs/design/suite-brand.md`. What it
owns, and what is therefore not a choice made here:

  §3.1  One ground: #0D0D1F, flat. No gradient, no texture.
  §3.2  Monoline strokes, never arbitrary filled shapes. Free ends round.
        No gradient on the ground, no shadow, no bevel, no drawn squircle.
  §3.2a Deliberate stroke modulation, under conditions, with a small variant
        that dials it back below about 24 px.
  §3.3  One continuous gradient along the stroke, bottom-left to top-right.
        A mark of one continuous stroke takes an even sweep.
  §3.4  Each app owns a segment of a shared hue arc.
  §3.6  A white secondary accent.

Peace Garden's own construction — the glyph and its geometry — is §4's "what each
app owns", and is recorded in `docs/BRAND.md` beside the measured numbers.

  python3 tools/icon/make_icon.py

**The mark is the fiddlehead Marcus chose on 11 October 2026**: round two's
D-suite (`design/logo-2026-10-11/`), a stem and a crozier from one root, the stem
opening into a warm white leaf, with T2's taper, C2's extra half turn in the coil,
and variant A's lower fork and earlier taper (`d-taper/coil2-a/`). This file is
now the single source of truth for it and imports nothing from `design/`; the
design scripts are the record of how it was reached, not a dependency. The port
is checked against their files by `check_port.py`.

Writes `icon.svg` next to this file as the canonical drawing, and the 1024 PNG the
asset catalogue needs. Both come off the same paths — the SVG writes them as
curves and the PNG flattens the same curves finely — so the two cannot drift.

It also writes the website's files: the tiled icon and its touch icon, the
favicon, and the bare mark the site's bar carries, once for a dark ground and once
for a light one. See `main` for which is which.

**The drawing and its painting are separate halves.** Everything above
`# --- colour` is dials; `plant()` and `fitted()` turn them into placed paths on
the 1024 grid; everything under `# --- output` paints whatever those return, on a
tile or bare, on dark or on light. A new drawing replaces the dials and the
geometry and leaves the painting alone.

  pip install numpy pillow
"""

import colorsys
import json
import math
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
CATALOGUE = ROOT / "App/PeaceGarden/Resources/Assets.xcassets/AppIcon.appiconset"
SITE = ROOT / "Server"

TILE = 1024

# §3.1. Cool, not warm: red minus blue is −18.
GROUND = "#0D0D1F"

# §3.4. Peace Garden's segment, amended by the owner on 11 October 2026 within
# its own band: sage through moss to green-gold, calm rather than the neon forest
# green, lime and yellow of 30 August. One hue and one saturation per stop, bottom-
# left to top-right. The top stops at 76° rather than 60° to clear FlagFans'
# #F0C24E (ΔE2000 19.5), and the bottom starts at 124°, 26° under Pfish's 150°.
HUES = (124.0, 98.0, 76.0)
SATURATION = (0.24, 0.34, 0.44)

# Every stop is held to one luminance, because §3.4's load-bearing property is
# isoluminance and not the hues: an unequal triad becomes a value staircase in
# greyscale, which reads as a printing fault.
#
# 9.7:1, down from the neon ramp's 13:1. That number was set to keep yellow at
# full chroma, which a calm ramp no longer wants. Solved, the stops are #9CC29E,
# #9DC386 and #A9C263.
TARGET_CONTRAST = 9.7

# **The site's light ground, for the bare mark.** The tile carries its own ground
# and so has no light and dark pair; the bare mark on the site's bar has no ground
# of its own and stands on the page's, which follows the reader. So it is drawn
# twice. On dark it is the tile's drawing exactly. On light the ramp is solved
# again, per stop, to `LIGHT_CONTRAST` against `LIGHT_GROUND`, with saturation
# lifted so the darker stops keep their hue, and the leaf is drawn in `LIGHT_INK`.
# Solved, the stops are #397E3D, #467D25 and #60781E.
#
# 4.6:1 rather than the tile's 9.7:1, because on a near-white ground 9.7:1 is
# nearly black: the stops would lose their hue to reach it. 4.6 clears WCAG's 4.5
# for text with a little to spare.
LIGHT_GROUND = "#F6F6F6"         # `site.css`, the light `--ground`
LIGHT_INK = "#121212"            # `site.css`, the light `--ink`; the leaf on light
LIGHT_CONTRAST = 4.6
LIGHT_SATURATION = (0.38, 0.54, 0.60)

# The leaf: the suite's warm white (UnCubed's exponent), a stroked outline and
# never a fill, at less than the stem's weight. The suite's accents run 0.40
# (Animal Rescue Centre) to 0.82 (UnCubed).
LEAF = "#F4F3EF"
LEAF_WEIGHT = 0.72               # the leaf's stroke against the stem's at its root

# The stroke at the root, as a share of the tile: the suite's median when it was
# measured on 11 October (Pfish 0.052 to Animal Rescue Centre 0.079). The ink
# stands this share of the tile high, centred: the suite's median fill.
STROKE = 0.0654
INK_HEIGHT = 0.70

# --------------------------------------------------------------- the plant
#
# Construction units: 100 wide, y down, the root at (50, 130). Every line is
# integrated from a heading that varies smoothly along it, so every line is a
# curve by construction; there is no straight segment and no ground line.

ROOT_POINT = (50.0, 130.0)
STEM_LENGTH = 86.0


def stem_heading(s):
    """The tall stem: up, leaning left as it rises, with a slight swell."""
    return -math.pi / 2 - 0.08 - 0.36 * s ** 1.5 + 0.12 * math.sin(math.pi * s)


# The tendril leaves the stem `FORK` of its 120 steps up — 14, lowered from round
# two's 22 because Marcus asked for it to split further down. A lower fork alone
# barely moves the visible split, since the stalk leaves almost parallel to the
# stem, so it also leaves a little wider and bends a little less: heading
# −90° + 0.24 + 0.32 s over 52 units.
FORK = 14
STALK = (0.24, 0.32, 52.0)       # (heading offset, bend, length)

# The crozier's head: a logarithmic spiral, entered on the stalk's own heading,
# its radius falling from 27 to 10 units over 1.35 turns. C2's half turn more
# than round two's 0.85, wound faster (2.1 times a turn) so the turns do not
# merge, and two units smaller than C2's 29 because the thinner turns need less
# room. The inner radius holds the eye open at about two tip widths.
COIL = (1.35, 27.0, 10.0)        # (turns, outer radius, inner radius)

# The leaf, as the loading fiddlehead draws it: it leaves on the stem's own
# tangent and keeps turning the same way, its half-width `sin(π s^0.85)` of its
# length times `LEAF_WIDTH`.
LEAF_LENGTH = 40.0
LEAF_WIDTH = 0.32
LEAF_SWEEP = 0.34                # radians, turning against the stem's lean
LEAF_RIBS = 24

# **The taper**, §3.2a under the growth clause proposed in round two and a half:
# each line is thickest where it grows from and thins towards its free end, and
# neither thickens again. One strength, `TAU`: the crozier's tip is 1 − τ of the
# root's stroke (0.42), the stem's neck at the leaf 1 − 0.43 τ (0.75).
TAU = 0.58
STEM_SHARE = 0.43
# The crozier thins along an ease-out from the fork, 1 − (1 − u)^2.5, which
# front-loads the thinning: by the top of its rise it is 0.69 of the root, lighter
# than the stem beside it. The stem stays full to where round two's fork was,
# 22 of its 120 steps, and then eases to its neck along a smoothstep.
TENDRIL_EASE = 2.5
STEM_TAPER_FROM = 22 / 120
# The outline is sampled every this share of the root's stroke along each line.
STEP = 0.2

# **The small drawing**, for 16, 32 and 48 px, is round two's and is not tapered:
# §3.2a(5) requires the small variant, because below about 24 px the thin end
# nears a device pixel and the line reads as broken. It is heavier by
# `SMALL_WEIGHT`, with a fatter leaf so its eye stays open and less coil, and it
# forks where round two forked. A lower fork was tried in it; the hook then sits
# level with its own fork, which is not better.
SMALL_WEIGHT = 1.35
SMALL_FORK = 22
SMALL_STALK = (0.16, 0.42, 50.0)
SMALL_COIL = (0.62, 26.0, 20.0)
SMALL_LEAF = (42.0, 0.38)        # (length, width)

# The favicon is the small drawing on the rounded ground tile, as the suite's
# are, on a 100-unit frame: the ink in this box, the tile's corners this round.
FAVICON_BOX = (17.0, 13.0, 74.0, 74.0)
FAVICON_RADIUS = 22.0
FAVICON_SIZES = (16, 32, 48)

# The bare mark's box. No tile, no ground and no margin for one: the drawing is
# cropped to its own ink, squared about its centre, with this much of the box left
# clear on each side so a round cap is never shaved by the edge. Round two's
# website marks leave 4 of 100.
BARE_INSET = 0.04
BARE_SIZE = 100                  # the SVG's nominal size; it scales to its box


# ------------------------------------------------------------------- colour

def relative_luminance(rgb):
    """WCAG relative luminance, for the contrast and isoluminance checks."""
    channels = []
    for value in rgb:
        channels.append(value / 12.92 if value <= 0.03928
                        else ((value + 0.055) / 1.055) ** 2.4)
    return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]


def contrast(rgb, other):
    a, b = relative_luminance(rgb), relative_luminance(other)
    lighter, darker = max(a, b), min(a, b)
    return (lighter + 0.05) / (darker + 0.05)


def from_hex(value):
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


def to_hex(rgb):
    return "#" + "".join(f"{round(min(max(c, 0), 1) * 255):02X}" for c in rgb)


def stop_at(hue, target_luminance, saturation):
    """
    The colour at `hue` and `saturation` whose luminance is `target_luminance`.

    Lightness is solved rather than chosen, which is what holds the triad
    isoluminant across hues of very different natural brightness.
    """
    low, high = 0.0, 1.0
    for _ in range(60):
        middle = (low + high) / 2
        rgb = colorsys.hls_to_rgb(hue / 360.0, middle, saturation)
        if relative_luminance(rgb) < target_luminance:
            low = middle
        else:
            high = middle
    return colorsys.hls_to_rgb(hue / 360.0, (low + high) / 2, saturation)


def ramp(light=False):
    """
    The gradient's stops, bottom-left to top-right, as (hue, rgb), each rounded to
    the 8-bit colour it is written as, so the SVG and the PNG paint the same one.

    On the tile's ground by default; with `light`, on the site's light ground,
    where a stop has to be darker than the ground rather than lighter.
    """
    if light:
        ground = from_hex(LIGHT_GROUND)
        # The luminance that puts a stop at LIGHT_CONTRAST *below* the ground.
        target = (relative_luminance(ground) + 0.05) / LIGHT_CONTRAST - 0.05
        saturations = LIGHT_SATURATION
    else:
        ground = from_hex(GROUND)
        # The luminance that puts a stop at TARGET_CONTRAST against the ground.
        target = TARGET_CONTRAST * (relative_luminance(ground) + 0.05) - 0.05
        saturations = SATURATION
    return [(hue, from_hex(to_hex(stop_at(hue, target, saturation))))
            for hue, saturation in zip(HUES, saturations)]


# ----------------------------------------------------------------- geometry

def grow(root, length, heading, n=120):
    """A line integrated from `heading(s)`, s from 0 to 1, in `n` equal steps."""
    x, y = root
    points = [(x, y)]
    for i in range(1, n + 1):
        h = heading(i / n)
        x += math.cos(h) * length / n
        y += math.sin(h) * length / n
        points.append((x, y))
    return points, heading(1.0)


def curl(root, start_heading, r_out, r_in, turns, hand, n):
    """
    A crozier's head: a logarithmic spiral entered on `start_heading`, its radius
    falling from `r_out` to `r_in` over `turns` turns.
    """
    total = 2 * math.pi * turns
    x, y = root
    points = [(x, y)]
    for i in range(1, n + 1):
        t = total * (i - 0.5) / n
        r = r_out * (r_in / r_out) ** (t / total)
        h = start_heading + hand * t
        x += math.cos(h) * r * total / n
        y += math.sin(h) * r * total / n
        points.append((x, y))
    return points


def leaf(mouth, heading, length, width):
    """
    The leaf's outline: out along one edge from the mouth and back along the
    other. Its width is nothing at the mouth, so it leaves the stem exactly as
    wide as the stem, and nothing at the tip, because it is drawn to a point.
    """
    spine = [mouth]
    x, y = mouth
    for i in range(1, LEAF_RIBS + 1):
        a = heading - LEAF_SWEEP * i / LEAF_RIBS
        x += math.cos(a) * length / LEAF_RIBS
        y += math.sin(a) * length / LEAF_RIBS
        spine.append((x, y))
    near, far = [], []
    for i in range(LEAF_RIBS + 1):
        half = width * length * math.sin(math.pi * (i / LEAF_RIBS) ** 0.85)
        j = min(i, LEAF_RIBS - 1)
        a = math.atan2(spine[j + 1][1] - spine[j][1], spine[j + 1][0] - spine[j][0])
        near.append((spine[i][0] - math.sin(a) * half, spine[i][1] + math.cos(a) * half))
        far.append((spine[i][0] + math.sin(a) * half, spine[i][1] - math.cos(a) * half))
    return near + far[::-1]


def plant(small=False):
    """
    The fiddlehead in construction units: (tendril, stem, leaf) as polylines.

    Two fronds from one root. The tall one opens into the leaf, held up and to
    the left; the second leaves it low down and is still a crozier, its coil
    carried above the fork and rolling outward to the right. No part of the
    crozier drops below the point it grew from.
    """
    stem, top = grow(ROOT_POINT, STEM_LENGTH, stem_heading)
    fork, (h0, bend, length), (turns, r_out, r_in) = (
        (SMALL_FORK, SMALL_STALK, SMALL_COIL) if small else (FORK, STALK, COIL))
    blade = leaf(stem[-1], top, *(SMALL_LEAF if small else (LEAF_LENGTH, LEAF_WIDTH)))
    rise, heading = grow(stem[fork], length, lambda s: -math.pi / 2 + h0 + bend * s)
    head = curl(rise[-1], heading, r_out, r_in, turns, +1,
                n=round(180 * max(1.0, turns / 0.85)))
    return rise + head[1:], stem, blade


def bounds(lines, halves):
    """The box around `lines`, each widened by its own half-width."""
    xs0, ys0, xs1, ys1 = [], [], [], []
    for line, half in zip(lines, halves):
        xs, ys = [p[0] for p in line], [p[1] for p in line]
        xs0.append(min(xs) - half)
        ys0.append(min(ys) - half)
        xs1.append(max(xs) + half)
        ys1.append(max(ys) + half)
    return min(xs0), min(ys0), max(xs1), max(ys1)


def place(lines, box, stroke):
    """
    Scales the drawing so its ink, half a stroke included on every side, fits
    `box` (x, y, w, h), centred. Computed from the drawn bounds rather than typed,
    so changing a dial cannot silently break a relationship somebody set.
    """
    bx, by, bw, bh = box
    x0, y0, x1, y1 = bounds(lines, [0] * len(lines))
    k = min((bw - stroke) / (x1 - x0), (bh - stroke) / (y1 - y0))
    ox = bx + (bw - (x1 - x0) * k) / 2 - x0 * k
    oy = by + (bh - (y1 - y0) * k) / 2 - y0 * k
    return [[(ox + x * k, oy + y * k) for x, y in line] for line in lines]


# The paths. A path is a list of segments in absolute coordinates: ("M", p),
# ("L", p), ("C", c1, c2, p), ("A", r, large, sweep, p) or ("Z",). The SVG writes them as they are;
# the PNG flattens the same segments, so the two draw the same curve.

def thin(points, every):
    out = points[::every]
    if out[-1] != points[-1]:
        out.append(points[-1])
    return out


def spline(points, closed):
    """Catmull–Rom through `points` as cubic Béziers: every segment curved."""
    p = []
    for q in points:   # coincident points (the leaf's mouth and tip) kink a spline
        q = (float(q[0]), float(q[1]))
        if not p or math.hypot(q[0] - p[-1][0], q[1] - p[-1][1]) > 1e-3:
            p.append(q)
    if closed:
        p = p[:-1] if p[0] == p[-1] else p
        n = len(p)
        get = lambda i: p[i % n]         # noqa: E731
        span = range(n)
    else:
        n = len(p)
        get = lambda i: p[min(max(i, 0), n - 1)]   # noqa: E731
        span = range(n - 1)
    path = [("M", p[0])]
    for i in span:
        p0, p1, p2, p3 = get(i - 1), get(i), get(i + 1), get(i + 2)
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        path.append(("C", c1, c2, p2))
    if closed:
        path.append(("Z",))
    return path


def smoothstep(u):
    u = np.clip(u, 0.0, 1.0)
    return u * u * (3 - 2 * u)


def arclength(p):
    return np.concatenate([[0.0], np.cumsum(np.hypot(*np.diff(p, axis=0).T))])


def outline(points, width_at, step):
    """
    A tapered line as a closed outline, to be filled. `width_at(u)` gives the full
    width at the fraction `u` of the line's length.

    A stroke-width cannot vary along a path, so this is how a taper is drawn. The
    centreline is resampled every `step`, and each side is offset by half the
    local width on the envelope of the circles of that width, so each round end is
    a true circle tangent to both sides. The sides are splines and the ends arcs,
    so nothing is straight.
    """
    p = np.asarray(points, float)
    s = arclength(p)
    n = max(3, int(math.ceil(s[-1] / step)) + 1)
    t = np.linspace(0.0, s[-1], n)
    p = np.column_stack([np.interp(t, s, p[:, 0]), np.interp(t, s, p[:, 1])])
    s = t
    r = width_at(s / s[-1]) / 2
    tangent = np.gradient(p, axis=0)
    tangent /= np.hypot(tangent[:, 0], tangent[:, 1])[:, None]
    normal = np.column_stack([-tangent[:, 1], tangent[:, 0]])
    dr = np.gradient(r, s)
    q = np.sqrt(np.clip(1 - dr ** 2, 0, 1))
    a = p + r[:, None] * (-dr[:, None] * tangent + q[:, None] * normal)
    b = p + r[:, None] * (-dr[:, None] * tangent - q[:, None] * normal)
    # **Each round end is two quarter arcs, through the point straight ahead of
    # the line's end, not one half arc.** Where the width is not changing — the
    # root, and the tip, where both profiles arrive flat — the end is an exact
    # semicircle, and one SVG arc across a diameter is ill-posed: which of the
    # two arcs is drawn hangs on a flag decided by rounding, and a radius
    # written to two places a hair longer than half the chord flattens the end
    # by up to a pixel. The design files carry that flattening; split, the end
    # is round whatever the rounding.
    tip = tuple(p[-1] + r[-1] * tangent[-1])
    root = tuple(p[0] - r[0] * tangent[0])
    side_a = spline([tuple(v) for v in a], False)
    side_b = spline([tuple(v) for v in b[::-1]], False)
    return (side_a + [("A", r[-1], False, False, tip), ("A", r[-1], False, False, tuple(b[-1]))]
            + side_b[1:]
            + [("A", r[0], False, False, root), ("A", r[0], False, False, tuple(a[0])), ("Z",)])


def profiles(tendril, stem, stroke):
    """
    The width along each line, as functions of the fraction of its length. The
    stem is full from the root to `STEM_TAPER_FROM`, then eases to its neck; the
    crozier is full at the fork and eases out to its tip.
    """
    stem_end = 1 - STEM_SHARE * TAU
    tip = 1 - TAU

    def stem_width(u):
        return stroke * (1 - (1 - stem_end) * smoothstep(
            (u - STEM_TAPER_FROM) / (1 - STEM_TAPER_FROM)))

    def tendril_width(u):
        ease = 1 - (1 - np.clip(u, 0.0, 1.0)) ** TENDRIL_EASE
        return stroke * (1 - (1 - tip) * ease)

    return tendril_width, stem_width


@dataclass
class Part:
    """One thing painted: a path, filled or stroked, in the sweep or the leaf's ink."""
    path: list
    paint: str              # "sweep" or "leaf"
    width: float = 0.0      # 0 fills the path; otherwise a round-capped stroke


@dataclass
class Mark:
    """A drawing placed on its frame, ready to paint."""
    parts: list
    sweep: tuple            # the ink box the gradient spans, (x0, y0, x1, y1)
    stroke: float           # the stroke at the root, in the frame's units
    lines: tuple            # the placed centrelines, for the measures


def drawn(small, box, stroke):
    """
    The plant placed in `box` at `stroke`, and its paint order: the crozier, then
    the stem, then the leaf. The crozier's fill starts inside the stem's at the
    fork, and both carry the one gradient in the same coordinates, so the overlap
    cannot show.
    """
    tendril, stem, blade = place(plant(small), box, stroke)
    # §3.3: one even sweep, bottom-left to top-right, across the ink box of the
    # whole drawing as round two measured it — the stems at their root weight and
    # the leaf at its own — so the colour does not move with the taper.
    sweep = bounds([tendril, stem, blade], [stroke / 2, stroke / 2, stroke * LEAF_WEIGHT / 2])
    leaf_part = Part(spline(thin(blade, 3), True), "leaf", stroke * LEAF_WEIGHT)
    if small:
        parts = [Part(spline(thin(tendril, 4), False), "sweep", stroke),
                 Part(spline(thin(stem, 4), False), "sweep", stroke), leaf_part]
    else:
        tendril_width, stem_width = profiles(tendril, stem, stroke)
        parts = [Part(outline(tendril, tendril_width, STEP * stroke), "sweep"),
                 Part(outline(stem, stem_width, STEP * stroke), "sweep"), leaf_part]
    return Mark(parts, sweep, stroke, (tendril, stem, blade))


def fitted():
    """
    The mark placed on the 1024 grid: its paths, the box its sweep spans, and the
    stroke at the root, 0.0654 of the tile.

    The ink stands `INK_HEIGHT` of the tile high, centred. Full bleed: iOS applies
    the mask.
    """
    h = INK_HEIGHT * TILE
    return drawn(False, ((TILE - h) / 2, (TILE - h) / 2, h, h), STROKE * TILE)


def small_fitted():
    """
    The small drawing on the favicon's 100-unit frame, at `SMALL_WEIGHT` times the
    stroke, held as a share of the ink's height as the icon's is.
    """
    box = FAVICON_BOX
    return drawn(True, box, STROKE / INK_HEIGHT * SMALL_WEIGHT * box[3])


def bare_view(mark):
    """
    The bare mark's viewBox: the drawn ink, squared about its centre, with
    `BARE_INSET` of the box clear on each side.

    The ink is the centrelines plus half the root's stroke, which is exact for
    round ends and conservative where a line has thinned. Cropped from the tile's
    own coordinates rather than fitted again, so the bare mark and the tile are the
    same paths and cannot differ by a rounding.
    """
    min_x, min_y, max_x, max_y = bounds(mark.lines, [mark.stroke / 2] * len(mark.lines))
    side = max(max_x - min_x, max_y - min_y) / (1 - 2 * BARE_INSET)
    return ((min_x + max_x - side) / 2, (min_y + max_y - side) / 2, side)


# ------------------------------------------------------------------- output

def number(value):
    """A coordinate to two places, without trailing zeros."""
    return f"{value:.2f}".rstrip("0").rstrip(".")


def path_data(path):
    out = []
    for segment in path:
        kind = segment[0]
        if kind == "M":
            out.append(f"M{segment[1][0]:.2f} {segment[1][1]:.2f}")
        elif kind == "L":
            out.append(f"L{segment[1][0]:.2f} {segment[1][1]:.2f}")
        elif kind == "C":
            (a, b), (c, d), (x, y) = segment[1:]
            out.append(f"C{a:.2f} {b:.2f} {c:.2f} {d:.2f} {x:.2f} {y:.2f}")
        elif kind == "A":
            r, large, sweep, (x, y) = segment[1:]
            out.append(f"A{r:.2f} {r:.2f} 0 {int(large)} {int(sweep)} {x:.2f} {y:.2f}")
        else:
            out.append("Z")
    return "".join(out)


def svg(mark, stops, ground=GROUND, leaf_ink=LEAF, frame=(0.0, 0.0, TILE),
        size=TILE, radius=None, title="Peace Garden"):
    """
    The drawing as SVG: on its ground by default, or bare — `ground` None — for the
    site's bar. `frame` is the square of the mark's own coordinates to show,
    (x, y, side), and `radius` rounds the ground's corners, for the favicon.
    """
    x0, y0, x1, y1 = mark.sweep
    marks = "".join(
        f'<stop offset="{index / (len(stops) - 1):g}" stop-color="{to_hex(rgb)}"/>'
        for index, (_, rgb) in enumerate(stops))
    vx, vy, side = frame
    view = " ".join(number(v) for v in (vx, vy, side, side))
    tile = ""
    if ground is not None and radius is None:
        tile = (f'<rect x="{number(vx)}" y="{number(vy)}" width="{number(side)}" '
                f'height="{number(side)}" fill="{ground}"/>\n')
    elif ground is not None:
        # A rounded ground is written as the path `render` fills, not as a
        # `<rect rx>`, which some renderers round unevenly: the SVG and the .ico
        # then have the same corners.
        tile = f'<path d="{path_data(tile_path(frame, radius))}" fill="{ground}"/>\n'
    body = []
    for part in mark.parts:
        paint = "url(#sweep)" if part.paint == "sweep" else leaf_ink
        if part.width:
            body.append(f'<path d="{path_data(part.path)}" fill="none" stroke="{paint}" '
                        f'stroke-width="{part.width:.2f}" stroke-linecap="round" '
                        f'stroke-linejoin="round"/>')
        else:
            body.append(f'<path d="{path_data(part.path)}" fill="{paint}"/>')
    # Bottom-left to top-right, across the ink box. In SVG's coordinates the
    # bottom is the larger y.
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" '
            f'viewBox="{view}">\n<title>{title}</title>\n'
            f'<defs><linearGradient id="sweep" gradientUnits="userSpaceOnUse" '
            f'x1="{x0:.2f}" y1="{y1:.2f}" x2="{x1:.2f}" y2="{y0:.2f}">{marks}</linearGradient></defs>\n'
            + tile + "\n".join(body) + "\n</svg>\n")


def flatten(path, per_curve=16):
    """
    The path as polylines, one per subpath, with each Bézier cut into `per_curve`
    pieces and each arc into pieces of at most 3°: well under a pixel from the
    curve at every size this draws.
    """
    runs, run, here = [], [], None
    for segment in path:
        kind = segment[0]
        if kind == "M":
            if run:
                runs.append(run)
            here = np.array(segment[1])
            run = [here]
        elif kind == "L":
            here = np.array(segment[1])
            run.append(here)
        elif kind == "C":
            p0, p1, p2, p3 = here, *(np.array(v) for v in segment[1:])
            t = np.linspace(0, 1, per_curve + 1)[1:, None]
            run.extend(((1 - t) ** 3) * p0 + 3 * ((1 - t) ** 2) * t * p1
                       + 3 * (1 - t) * t ** 2 * p2 + t ** 3 * p3)
            here = p3
        elif kind == "A":
            r, large, sweep, end = segment[1:]
            end = np.array(end)
            run.extend(arc_points(here, end, r, large, sweep))
            here = end
    if run:
        runs.append(run)
    return [np.array(r) for r in runs]


def arc_points(start, end, r, large, sweep):
    """A circular SVG arc as points after `start`, by the SVG spec's centre form."""
    half = (start - end) / 2
    d2 = float(half @ half)
    r = max(r, math.sqrt(d2))          # the spec scales a short radius up
    factor = math.sqrt(max(r * r - d2, 0.0) / d2) if d2 else 0.0
    if large == sweep:
        factor = -factor
    centre = (start + end) / 2 + factor * np.array([half[1], -half[0]])
    a0 = math.atan2(*(start - centre)[::-1])
    a1 = math.atan2(*(end - centre)[::-1])
    delta = a1 - a0
    if sweep and delta < 0:
        delta += 2 * math.pi
    elif not sweep and delta > 0:
        delta -= 2 * math.pi
    steps = max(2, int(math.ceil(abs(math.degrees(delta)) / 3)))
    angles = a0 + delta * np.linspace(0, 1, steps + 1)[1:]
    return list(centre + r * np.column_stack([np.cos(angles), np.sin(angles)]))


def tile_path(frame, radius):
    """The ground's square, its corners rounded by `radius`, as a path, clockwise."""
    x, y, side = frame
    right, bottom, c = x + side, y + side, radius
    path = [("M", (x + c, y)),
            ("L", (right - c, y)), ("A", c, False, True, (right, y + c)),
            ("L", (right, bottom - c)), ("A", c, False, True, (right - c, bottom)),
            ("L", (x + c, bottom)), ("A", c, False, True, (x, bottom - c)),
            ("L", (x, y + c)), ("A", c, False, True, (x + c, y)), ("Z",)]
    return [segment for segment in path if segment[0] != "A" or c]


def coverage(part, to_canvas, canvas, scale):
    """
    A part's coverage, drawn at `canvas` pixels square. A fill is one polygon per
    subpath; a stroke is the union of one quad per segment and one disc per vertex,
    which gives round caps and joins and, every piece being convex, never ties
    itself in a knot where a path turns back on itself.
    """
    mask = Image.new("L", (canvas, canvas), 0)
    draw = ImageDraw.Draw(mask)
    for run in flatten(part.path):
        points = to_canvas(run)
        if not part.width:
            draw.polygon([tuple(p) for p in points], fill=255)
            continue
        half = part.width * scale / 2
        for a, b in zip(points, points[1:]):
            direction = b - a
            length = float(np.linalg.norm(direction))
            if length < 1e-9:
                continue
            offset = np.array([-direction[1], direction[0]]) / length * half
            draw.polygon([tuple(a + offset), tuple(b + offset),
                          tuple(b - offset), tuple(a - offset)], fill=255)
        for p in points:
            draw.ellipse([p[0] - half, p[1] - half, p[0] + half, p[1] + half], fill=255)
    return mask


def render(mark, stops, size, ground=GROUND, leaf_ink=LEAF, frame=(0.0, 0.0, TILE),
           radius=None):
    """
    The drawing as pixels, `size` square: the SVG's own painting, part by part.

    Each part's coverage is drawn supersampled and averaged down, then laid over
    what is already there in its paint, as an SVG renderer composites one path at a
    time. With a ground the image is opaque RGB, as an app icon must be; bare, or
    on a rounded tile, it carries alpha.
    """
    vx, vy, side = frame
    supersample = max(6, round(2048 / size))
    canvas = size * supersample
    scale = canvas / side

    def to_canvas(points):
        return (np.asarray(points) - np.array([vx, vy])) * scale

    # The sweep at each pixel's centre, padded beyond the ends, as an SVG
    # linearGradient is. An even sweep: the mark is one continuous run of colour,
    # so §3.3's rule about putting the transitions in the gaps does not apply.
    x0, y0, x1, y1 = mark.sweep
    start = np.array([x0, y1])                     # bottom-left
    axis = np.array([x1, y0]) - start              # to top-right
    centres = (np.arange(size) + 0.5) * side / size
    ys, xs = np.meshgrid(vy + centres, vx + centres, indexing="ij")
    t = np.clip(((xs - start[0]) * axis[0] + (ys - start[1]) * axis[1])
                / float(axis @ axis), 0, 1)
    colours = np.array([rgb for _, rgb in stops], dtype=np.float64)
    position = t * (len(stops) - 1)
    lower = np.clip(np.floor(position), 0, len(stops) - 2).astype(np.int32)
    blend = (position - lower)[..., None]
    gradient = colours[lower] * (1 - blend) + colours[lower + 1] * blend

    # Premultiplied colour and alpha.
    colour = np.zeros((size, size, 3))
    alpha = np.zeros((size, size, 1))
    if ground is not None:
        # The tile is a path like any other, so its corners are drawn by the
        # same rasteriser as the mark.
        tile = Part(tile_path(frame, radius or 0.0), "ground")
        mask = coverage(tile, to_canvas, canvas, scale).reduce(supersample)
        cover = np.asarray(mask, dtype=np.float64)[..., None] / 255
        colour = np.array(from_hex(ground)) * cover
        alpha = cover
    ink = np.array(from_hex(leaf_ink))
    for part in mark.parts:
        mask = coverage(part, to_canvas, canvas, scale).reduce(supersample)
        cover = np.asarray(mask, dtype=np.float64)[..., None] / 255
        paint = gradient if part.paint == "sweep" else ink
        colour = colour * (1 - cover) + paint * cover
        alpha = alpha * (1 - cover) + cover

    if ground is not None and radius is None:
        return Image.fromarray(np.round(np.clip(colour, 0, 1) * 255).astype(np.uint8), "RGB")
    straight = np.where(alpha > 0, colour / np.maximum(alpha, 1e-9), 0)
    rgba = np.concatenate([straight, alpha], axis=2)
    return Image.fromarray(np.round(np.clip(rgba, 0, 1) * 255).astype(np.uint8), "RGBA")


def save_raster(image, path, **options):
    """
    Saves `image` to `path`, unless the file there already decodes to the same
    pixels.

    The same pixels do not always encode to the same bytes: Pillow's PNG and ICO
    writers have changed between versions, and a run on another machine rewrote
    all three rasters with not one pixel different. A diff of three binaries
    that changed nothing is noise somebody has to rule out by hand, and it hides
    the run that did change one.

    An .ico takes one drawing per size through `append_images`, and each size is
    compared against the one this run would write.
    """
    provided = [image] + list(options.get("append_images", []))

    def wanted_at(size):
        for candidate in provided:
            if candidate.size == size:
                return candidate
        return image.resize(size, Image.LANCZOS)

    if path.exists():
        with Image.open(path) as existing:
            # An .ico carries several sizes and opens on the largest; each is
            # compared, at the sizes this run would write.
            sizes = options.get("sizes") or [existing.size]
            same = True
            for size in sizes:
                if path.suffix == ".ico":
                    if size not in existing.info.get("sizes", {size}):
                        same = False
                        break
                    existing.size = size
                    wanted = wanted_at(size)
                else:
                    wanted = image
                if (existing.size != wanted.size or existing.mode != wanted.mode
                        or existing.tobytes() != wanted.tobytes()):
                    same = False
                    break
        if same:
            return
    image.save(path, **options)


CONTENTS = {
    "images": [
        {"filename": "icon.png", "idiom": "universal",
         "platform": "ios", "size": "1024x1024"}
    ],
    "info": {"author": "xcode", "version": 1},
}


def measures(mark):
    """
    The widths and the tightest gap that decide whether the mark holds at small
    sizes, in tile units.

    The coil's mouth is the gap from the tip's round end to the nearest other ink
    — the turn outside it — leaving out the tip's own last two strokes of length,
    which it cannot touch. It is the tightest gap in the coil, and it is legible
    or not in device pixels, so `main` reports it at the sizes the icon is seen at.
    """
    tendril, stem, blade = (np.asarray(line) for line in mark.lines)
    tendril_width, stem_width = profiles(tendril, stem, mark.stroke)
    st, ss = arclength(tendril), arclength(stem)
    wt, ws = tendril_width(st / st[-1]), stem_width(ss / ss[-1])
    far = st < st[-1] - 2.0 * mark.stroke
    points = np.vstack([tendril[far], stem, blade])
    widths = np.concatenate([wt[far], ws, np.full(len(blade), mark.stroke * LEAF_WEIGHT)])
    tip = tendril[-1]
    mouth = float(np.min(np.hypot(*(points - tip).T) - widths / 2) - wt[-1] / 2)
    return {"root": mark.stroke, "crozier tip": float(wt[-1]),
            "stem neck": float(ws[-1]), "leaf": mark.stroke * LEAF_WEIGHT,
            "coil mouth": mouth}


def main():
    stops, light = ramp(), ramp(light=True)
    mark = fitted()
    small = small_fitted()

    CATALOGUE.mkdir(parents=True, exist_ok=True)
    icon = svg(mark, stops, title="Peace Garden")
    (HERE / "icon.svg").write_text(icon)
    # An app icon may not carry an alpha channel. The ground travels with the
    # mark — §10.4's "no light and dark pair" — so one drawing covers every
    # appearance and every size, and the catalogue has one entry, with no dark
    # or tinted variant.
    tile = render(mark, stops, TILE)
    save_raster(tile, CATALOGUE / "icon.png")
    (CATALOGUE / "Contents.json").write_text(json.dumps(CONTENTS, indent=2) + "\n")

    # **The site's tab and home-screen icons are this drawing, not a second one**
    # — and neither is the mark at the head of each page. Both used to point at
    # `mark.svg`, which was described as a copy of this drawing and kept in step
    # by hand. It was not: this file inverted the bract on 4 September and the
    # copy stayed as it was, so `/s`, `/g` and `/t` each showed the old mark in the
    # header and the new one in the tab, at the same time, and nothing failed. The
    # copy is gone and the pages point here, which is the only version of "cannot
    # drift" that does not depend on somebody remembering.
    #
    # Three files, because a favicon is three questions. The SVG is what a
    # current browser takes and the only one that stays sharp; for the tab it is
    # `favicon.svg`, below, and `icon.svg` stays for where the tile is wanted. The 180 is what
    # iOS puts on a home screen, and this is a site people open on a phone. The
    # .ico is at the root because a browser asks for /favicon.ico whether or not
    # it has been told to; it carries the small drawing on its rounded tile, drawn
    # at each of its sizes rather than scaled from one.
    (SITE / "assets/icon.svg").write_text(icon)
    save_raster(render(mark, stops, 180), SITE / "assets/icon-180.png")
    frame = (0.0, 0.0, 100.0)
    favicons = [render(small, stops, size, frame=frame, radius=FAVICON_RADIUS)
                for size in FAVICON_SIZES]
    save_raster(favicons[-1], SITE / "favicon.ico",
                sizes=[(s, s) for s in FAVICON_SIZES], append_images=favicons[:-1])
    # **The tab takes `favicon.svg`**, Marcus's choice of 11 October: the .ico's
    # drawing as curves. `icon.svg` in a tab is the tapered mark at 16 px, its
    # crozier's tip about 0.6 px, which §3.2a(5) is there to prevent.
    (SITE / "assets/favicon.svg").write_text(
        svg(small, stops, frame=frame, size=100, radius=FAVICON_RADIUS))

    # **The bar carries the bare mark, not the tile**, since 11 October: the
    # drawing beside the wordmark with no dark square behind it. Without its
    # ground it has to be drawn for the ground it lands on, so there are two:
    # `mark-dark.svg` is this drawing exactly, and `mark-light.svg` is the same
    # paths with the ramp solved for the site's light ground and the leaf in
    # ink. Pages that follow the reader switch between them with `<picture>`;
    # the areas, which are always night, carry only the dark one.
    view = bare_view(mark)
    (SITE / "assets/mark-dark.svg").write_text(
        svg(mark, stops, ground=None, frame=view, size=BARE_SIZE,
            title="Peace Garden, for dark grounds"))
    (SITE / "assets/mark-light.svg").write_text(
        svg(mark, light, ground=None, leaf_ink=LIGHT_INK, frame=view, size=BARE_SIZE,
            title="Peace Garden, for light grounds"))

    ground = from_hex(GROUND)
    print(f"ground {GROUND}   root stroke {mark.stroke:.2f}   "
          f"hues {' → '.join(f'{h:g}°' for h in HUES)}")
    luminances = []
    for (hue, rgb), saturation in zip(stops, SATURATION):
        luminances.append(relative_luminance(rgb))
        print(f"  {hue:5.1f}°  s {saturation:.2f}  {to_hex(rgb)}  "
              f"contrast {contrast(rgb, ground):.2f}:1  luminance {luminances[-1]:.4f}")
    spread = (max(luminances) - min(luminances)) / max(luminances) * 100
    print(f"  isoluminance spread {spread:.2f}% (8-bit rounding)")
    print(f"  leaf {LEAF}  contrast {contrast(from_hex(LEAF), ground):.2f}:1")

    lit = from_hex(LIGHT_GROUND)
    print(f"bare mark on the light ground {LIGHT_GROUND}, leaf in {LIGHT_INK} "
          f"({contrast(from_hex(LIGHT_INK), lit):.2f}:1)")
    for (hue, rgb), saturation in zip(light, LIGHT_SATURATION):
        print(f"  {hue:5.1f}°  s {saturation:.2f}  {to_hex(rgb)}  "
              f"contrast {contrast(rgb, lit):.2f}:1")

    print("widths and the coil's mouth, on the tile and as rendered:")
    for name, value in measures(mark).items():
        print(f"  {name:>12}  {value:6.1f} u  {value / mark.stroke:4.2f} of the root   "
              + "   ".join(f"{value * px / TILE:5.2f} px @{px}" for px in (180, 60, 40)))
    print("the small drawing's stroke on the favicon (untapered, §3.2a(5)):  "
          + "   ".join(f"{small.stroke * px / 100:4.2f} px @{px}" for px in FAVICON_SIZES))


if __name__ == "__main__":
    main()
