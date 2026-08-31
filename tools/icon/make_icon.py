#!/usr/bin/env python3
"""
Draws the app icon, to the Interfulgent suite brand system.

The governing document is `uncubed-integration/docs/design/suite-brand.md`. What it
owns, and what is therefore not a choice made here:

  §3.1  One ground: #0D0D1F, flat. No gradient, no texture.
  §3.2  Monoline strokes, never arbitrary filled shapes. Free ends round.
        No gradient on the ground, no shadow, no bevel, no drawn squircle.
  §3.3  One continuous gradient along the stroke, bottom-left to top-right.
        A mark of one continuous stroke takes an even sweep.
  §3.4  Each app owns a segment of a shared hue arc.
  §3.5  Marks are symbolic, never pictorial: a mark may not depict what the
        app is *about*.

Peace Garden's own construction — the glyph and its geometry — is §4's "what each
app owns", and is recorded in `docs/BRAND.md` beside the measured numbers.

  python3 tools/icon/make_icon.py

Writes `icon.svg` next to this file as the canonical drawing, and the 1024 PNG the
asset catalogue needs. Both come off the same flattened polyline, so the two cannot
drift — the same reason UnCubed's generator flattens rather than rasterises.

  pip install numpy pillow
"""

import colorsys
import json
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
CATALOGUE = ROOT / "App/PeaceGarden/Resources/Assets.xcassets/AppIcon.appiconset"

TILE = 1024
SUPERSAMPLE = 3

# §3.1. Cool, not warm: red minus blue is −18.
GROUND = "#0D0D1F"

# §3.4. Peace Garden's segment, allocated 2026-08-30 — yellow through lime to
# forest green. It sits *below* the 150°–340° arc the suite document calls usable,
# so it extends the arc rather than taking an allocation within it, and that was
# the owner's decision rather than this script's. 10° of clearance under Pfish's
# 150°, and no overlap with anything.
HUE_FROM = 140.0  # forest green, at the bottom-left of the sweep
HUE_TO = 60.0     # yellow, at the top-right
SATURATION = 0.95  # neon

# Every stop is held to one luminance, because §3.4's load-bearing property is
# isoluminance and not the hues: an unequal triad becomes a value staircase in
# greyscale, which reads as a printing fault.
#
# 13:1 rather than Pfish's ~9.1:1, and the number is chosen rather than inherited.
# Holding a triad isoluminant costs the naturally-bright hues their chroma —
# yellow is the extreme case, and at 9.1:1 it lands on #B9B905, an olive. 13:1 is
# the highest target at which the green end still sits at full chroma; above it
# the greens climb past it and wash out to pastel. So it is the most saturated
# isoluminant triad this span can carry, which is what "neon" asks for.
TARGET_CONTRAST = 13.0
STOP_COUNT = 3

# The stroke. One weight — the mark is monoline, so §3.2a's modulation terms and
# the recorded contrast ratio they require do not apply and must not be reached for.
STROKE = 48.0

# The spiral is logarithmic, so it is genuinely tighter at the centre and opens as
# it turns. An Archimedean one holds the same gap the whole way out and reads as
# evenly wound rather than as growing. `GROWTH_PER_TURN` is the factor each turn
# multiplies the radius by.
#
# Two constraints, asserted in `spiral()` rather than left as lore, because both
# were found by drawing them wrong: the start radius must clear half the stroke or
# the innermost turn paints over its own centre, and the innermost turn's radial
# gain must clear a whole stroke or consecutive turns merge — and they merge first
# at the smallest size, which is the one that matters most.
TURNS = 2.0
START_RADIUS = 48.0
GROWTH_PER_TURN = 2.55
# Where the outer end points, measured anticlockwise from east. 45° puts it up and
# to the right, so the mark's own reading order runs the same way as the gradient —
# the argument §10.4 makes for `un³`.
END_BEARING = 45.0

# The spathe — a peace lily's bract, carried on the end of the line. It leaves on
# the spiral's own tangent and keeps turning the same way, so it follows the
# trajectory rather than being parked at the end of it.
#
# The turn is a dial and not the spiral's own continuation, which was tried first:
# over the length a bract needs, the spiral turns through nearly 50° and the blade
# curls back across the coil, closing a loop and reading as a bean. A spathe is a
# long sail with a gentle bend and a drawn-out point.
SPATHE_LENGTH = 0.92  # against the spiral's final radius
SPATHE_TURN = 0.30    # radians, continuing the spiral's sense
SPATHE_WIDTH = 0.28   # half-width, against the spathe's own length

# The spadix: the cream spike a peace lily stands inside its bract. It is the one
# element that does not take the gradient, which is the suite's own habit — Pfish
# carries two white bubble rings beside a fish that graduates, at the fish's own
# weight and in flat #FFFFFF. (UnCubed's white is a different device: its off-white
# is the gradient's last stop, not a separate element.)
#
# Lighter than the stroke it sits inside, because at full weight it fills the
# spathe's hollow and the bract stops reading as one. `un³` has the precedent for
# a secondary element at a reduced weight — its exponent runs at 82% of the
# letters. The clearance this leaves is asserted, not eyeballed.
SPADIX = "#FFFFFF"
SPADIX_WEIGHT = 0.48   # of the main stroke
SPADIX_FROM = 0.26     # along the spathe's spine
SPADIX_TO = 0.55
SPADIX_CLEARANCE = 8.0  # construction units, each side

MARGIN = 190.0


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
    return "#" + "".join(f"{round(c * 255):02X}" for c in rgb)


def stop_at(hue, target_luminance):
    """
    The colour at `hue` whose luminance is `target_luminance`.

    Lightness is solved rather than chosen, which is what holds the triad
    isoluminant across hues of very different natural brightness — yellow and
    forest green are the extreme case, and eyeballing them is how a sweep becomes
    a staircase.
    """
    low, high = 0.0, 1.0
    for _ in range(60):
        middle = (low + high) / 2
        rgb = colorsys.hls_to_rgb(hue / 360.0, middle, SATURATION)
        if relative_luminance(rgb) < target_luminance:
            low = middle
        else:
            high = middle
    return colorsys.hls_to_rgb(hue / 360.0, (low + high) / 2, SATURATION)


def ramp():
    """The gradient's stops, bottom-left to top-right."""
    ground = from_hex(GROUND)
    # The luminance that puts a stop at TARGET_CONTRAST against the ground.
    target = TARGET_CONTRAST * (relative_luminance(ground) + 0.05) - 0.05
    hues = [HUE_FROM + (HUE_TO - HUE_FROM) * i / (STOP_COUNT - 1)
            for i in range(STOP_COUNT)]
    return [(hue, stop_at(hue, target)) for hue in hues]


# ----------------------------------------------------------------- geometry

def spiral():
    """
    One continuous stroke, unwinding.

    §3.5 is the reason this is not a plant. A mark may not depict what the app is
    about, and the app is about a seed and what grows from it — so a leaf, a
    shoot, a flower and a seed are all the forbidden case, in the way that "a flag
    is a flag" is for FlagFans. What is drawn instead is the medium the app works
    in, which is unfolding over time: the same move FreqShift makes by drawing a
    waveform rather than a voice.
    """
    assert START_RADIUS > STROKE / 2, "the innermost turn would fill its own centre"
    assert START_RADIUS * (GROWTH_PER_TURN - 1) > STROKE, "consecutive turns would merge"

    sweep = TURNS * 2 * math.pi
    # Solve the phase so the outer end lands on END_BEARING.
    phase = math.radians(END_BEARING) - sweep

    def at(theta):
        radius = START_RADIUS * GROWTH_PER_TURN ** (theta / (2 * math.pi))
        angle = theta + phase
        # Screen space: y grows downward, so the sine is negated.
        return np.array([radius * math.cos(angle), -radius * math.sin(angle)])

    line = np.array([at(sweep * i / 512) for i in range(513)])

    # Leave on the tangent the spiral actually ends on, taken from the drawn
    # points rather than differentiated by hand.
    heading = line[-1] - line[-2]
    heading /= np.linalg.norm(heading)
    length = SPATHE_LENGTH * START_RADIUS * GROWTH_PER_TURN ** TURNS

    steps = 160
    spine = [line[-1]]
    for index in range(1, steps + 1):
        # The turn accumulates along the blade, so the bend is gentle at the base
        # and the tip is the part that has swung.
        angle = SPATHE_TURN * index / steps
        direction = np.array([
            heading[0] * math.cos(angle) - heading[1] * math.sin(angle),
            heading[0] * math.sin(angle) + heading[1] * math.cos(angle),
        ])
        spine.append(spine[-1] + direction * (length / steps))
    spine = np.array(spine)
    return np.concatenate([line, spathe(spine)]), spadix(spine)


def spathe_half_width(s, length):
    """The bract's half-width at `s` along its spine. Zero at both ends."""
    return np.sin(np.pi * s ** 0.62) ** 0.85 * SPATHE_WIDTH * length


def spadix(spine):
    """The spike inside the bract, and the check that it fits inside it."""
    length = float(np.sum(np.linalg.norm(np.diff(spine, axis=0), axis=1)))
    lo = int(SPADIX_FROM * (len(spine) - 1))
    hi = int(SPADIX_TO * (len(spine) - 1))

    # The hollow the spadix has to sit in is the bract's half-width less half the
    # outline's own stroke. Checked at the narrow end of the spadix's run, which
    # is where it runs out of room first.
    s = np.linspace(0, 1, len(spine))[lo:hi + 1]
    hollow = spathe_half_width(s, length).min() - STROKE / 2
    room = hollow - STROKE * SPADIX_WEIGHT / 2
    assert room >= SPADIX_CLEARANCE, (
        f"the spadix leaves {room:.1f} units of clearance, wanted {SPADIX_CLEARANCE}"
    )
    return spine[lo:hi + 1]


def spathe(spine):
    """
    The bract, as an outline around a spine.

    Its width closes to nothing at both ends: at the base so the outline leaves the
    stroke exactly as wide as the stroke, with no seam, and at the tip because a
    peace lily's spathe is drawn to a point. Widest at about a third along, which
    is what makes it a spathe rather than a leaf.
    """
    tangents = np.gradient(spine, axis=0)
    tangents /= np.maximum(np.linalg.norm(tangents, axis=1, keepdims=True), 1e-9)
    normals = np.stack([-tangents[:, 1], tangents[:, 0]], axis=1)

    length = float(np.sum(np.linalg.norm(np.diff(spine, axis=0), axis=1)))
    s = np.linspace(0, 1, len(spine))
    width = spathe_half_width(s, length)[:, None]

    # Out along one edge and back along the other, so the whole mark stays one path.
    return np.concatenate([spine + normals * width, (spine - normals * width)[::-1]])


def ink_bounds(points, stroke):
    """
    The smallest box containing the drawn ink.

    Taken from the flattened points plus half a stroke, which is exact rather than
    conservative for round caps and joins — they extend exactly half the weight
    beyond the centreline in every direction. `BrandMark.swift` computes it the
    same way, deliberately.
    """
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    half = stroke / 2
    return min(xs) - half, min(ys) - half, max(xs) + half, max(ys) + half


def fitted():
    """
    The polyline placed on the 1024 grid, and the stroke weight it is drawn at.

    The fit is computed from the drawn bounds rather than typed, so changing a
    dial above cannot silently break a relationship somebody set on purpose.
    """
    points, spike = spiral()
    # The spadix sits inside the bract, so it cannot extend the bounds — but it is
    # measured with everything else rather than assumed not to.
    min_x, min_y, max_x, max_y = ink_bounds(
        list(points) + list(spike), STROKE)
    available = TILE - 2 * MARGIN
    scale = available / max(max_x - min_x, max_y - min_y)

    # Centred on the drawn bounds. Unlike `un³` there is no open side wanting an
    # optical bias: the mark's ink is distributed about its own centre.
    width, height = (max_x - min_x) * scale, (max_y - min_y) * scale
    offset_x = (TILE - width) / 2 - min_x * scale
    offset_y = (TILE - height) / 2 - min_y * scale

    def place(run):
        return [(x * scale + offset_x, y * scale + offset_y) for x, y in run]

    return place(points), place(spike), STROKE * scale


# ------------------------------------------------------------------- output

def path_data(points):
    return "M " + " L ".join(f"{x:.2f} {y:.2f}" for x, y in points)


def svg(points, spike, stroke, stops):
    box = ink_bounds(points, stroke)
    # Bottom-left to top-right, across the drawn ink. In SVG's coordinates the
    # bottom is the larger y.
    x1, y1, x2, y2 = box[0], box[3], box[2], box[1]
    marks = "".join(
        f'<stop offset="{index / (len(stops) - 1):.4f}" stop-color="{to_hex(rgb)}"/>'
        for index, (_, rgb) in enumerate(stops)
    )
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{TILE}" height="{TILE}" \
viewBox="0 0 {TILE} {TILE}">
<defs><linearGradient id="sweep" gradientUnits="userSpaceOnUse" \
x1="{x1:.2f}" y1="{y1:.2f}" x2="{x2:.2f}" y2="{y2:.2f}">{marks}</linearGradient></defs>
<rect width="{TILE}" height="{TILE}" fill="{GROUND}"/>
<path d="{path_data(points)}" fill="none" stroke="url(#sweep)" \
stroke-width="{stroke:.2f}" stroke-linecap="round" stroke-linejoin="round"/>
<path d="{path_data(spike)}" fill="none" stroke="{SPADIX}" \
stroke-width="{stroke * SPADIX_WEIGHT:.2f}" stroke-linecap="round" \
stroke-linejoin="round"/>
</svg>
"""


def stroke_mask(points, stroke):
    """A round-capped, round-joined stroke, as a coverage mask."""
    canvas = TILE * SUPERSAMPLE
    mask = Image.new("L", (canvas, canvas), 0)
    draw = ImageDraw.Draw(mask)
    scaled = np.array([(x * SUPERSAMPLE, y * SUPERSAMPLE) for x, y in points])
    half = stroke * SUPERSAMPLE / 2

    # The stroke as the union of one quad per segment and one disc per vertex.
    #
    # Two rejected alternatives, both of which were drawn. PIL's own jointed thick
    # line leaves a serrated fringe along a curve this finely sampled. Offsetting
    # the whole centreline into a single outline polygon is clean on the spiral but
    # ties itself in a knot at the spathe's tip, where the path reverses through
    # 180° — the offset self-intersects and an even-odd fill punches a hole in the
    # point. Per-primitive union has neither problem: each piece is convex, and
    # overdrawing is the union.
    for a, b in zip(scaled, scaled[1:]):
        direction = b - a
        length = float(np.linalg.norm(direction))
        if length < 1e-9:
            continue
        offset = np.array([-direction[1], direction[0]]) / length * half
        draw.polygon([tuple(a + offset), tuple(b + offset),
                      tuple(b - offset), tuple(a - offset)], fill=255)
    for point in scaled:
        draw.ellipse([point[0] - half, point[1] - half,
                      point[0] + half, point[1] + half], fill=255)
    return (np.asarray(mask, dtype=np.float32) / 255.0)[..., None]


def png(points, spike, stroke, stops):
    canvas = TILE * SUPERSAMPLE
    coverage = stroke_mask(points, stroke)

    box = ink_bounds(points, stroke)
    start = np.array([box[0], box[3]])          # bottom-left
    axis = np.array([box[2], box[1]]) - start   # to top-right
    ys, xs = np.mgrid[0:canvas, 0:canvas].astype(np.float32) / SUPERSAMPLE
    t = np.clip(((xs - start[0]) * axis[0] + (ys - start[1]) * axis[1])
                / float(axis @ axis), 0, 1)

    # An even sweep: the mark is one continuous stroke, so §3.3's rule about
    # putting the transitions in the gaps between elements does not apply.
    colours = np.array([rgb for _, rgb in stops], dtype=np.float32)
    position = t * (len(stops) - 1)
    lower = np.clip(np.floor(position), 0, len(stops) - 2).astype(np.int32)
    blend = (position - lower)[..., None]
    gradient = colours[lower] * (1 - blend) + colours[lower + 1] * blend

    image = np.array(from_hex(GROUND), dtype=np.float32) * np.ones_like(gradient)
    image = image * (1 - coverage) + gradient * coverage

    # The spadix last, and flat: it is the one element outside the sweep.
    spike_coverage = stroke_mask(spike, stroke * SPADIX_WEIGHT)
    image = image * (1 - spike_coverage) + np.array(from_hex(SPADIX),
                                                    dtype=np.float32) * spike_coverage

    out = Image.fromarray((np.clip(image, 0, 1) * 255).astype(np.uint8), "RGB")
    return out.resize((TILE, TILE), Image.LANCZOS)


CONTENTS = {
    "images": [
        {"filename": "icon.png", "idiom": "universal",
         "platform": "ios", "size": "1024x1024"}
    ],
    "info": {"author": "xcode", "version": 1},
}


def clearances(points, spike, stroke):
    """
    The tightest gaps in the mark, in tile units.

    A mark that merges at small sizes does it at one specific place, and it is
    cheaper to measure that place than to squint at a downsample. Reported at the
    sizes the icon is actually seen at rather than on the 1024 grid, because a
    gap is legible or not in device pixels.
    """
    scale = stroke / STROKE

    # Consecutive turns. The innermost pair is always the tightest: the radial
    # gain per turn grows with the radius, and the stroke does not.
    turns = (START_RADIUS * (GROWTH_PER_TURN - 1) - STROKE) * scale

    # The bract against the coil it rises from. The junction is skipped at both
    # ends — they meet there on purpose, and a measurement across a join is not a
    # clearance.
    coil = np.array(points[:400])
    bract = np.array(points[560:])
    gaps = np.linalg.norm(bract[:, None, :] - coil[None, :, :], axis=2)
    bract_to_coil = float(gaps.min()) - stroke

    # The spike inside the bract.
    spine = np.array(spike)
    edge = np.array(points[513:])
    inner = np.linalg.norm(spine[:, None, :] - edge[None, :, :], axis=2)
    spadix = float(inner.min()) - stroke / 2 - stroke * SPADIX_WEIGHT / 2

    return {"between turns": turns, "bract to coil": bract_to_coil,
            "spadix in bract": spadix}


def main():
    stops = ramp()
    points, spike, stroke = fitted()

    CATALOGUE.mkdir(parents=True, exist_ok=True)
    (HERE / "icon.svg").write_text(svg(points, spike, stroke, stops))
    # An app icon may not carry an alpha channel. The ground travels with the
    # mark — §10.4's "no light and dark pair" — so one drawing covers every
    # appearance and every size.
    png(points, spike, stroke, stops).save(CATALOGUE / "icon.png")
    (CATALOGUE / "Contents.json").write_text(json.dumps(CONTENTS, indent=2) + "\n")

    ground = from_hex(GROUND)
    print(f"ground {GROUND}   stroke {stroke:.2f}   span {HUE_FROM:.0f}°→{HUE_TO:.0f}°")
    luminances = []
    for hue, rgb in stops:
        luminances.append(relative_luminance(rgb))
        print(f"  {hue:5.1f}°  {to_hex(rgb)}  "
              f"contrast {contrast(rgb, ground):.2f}:1  luminance {luminances[-1]:.4f}")
    spread = (max(luminances) - min(luminances)) / max(luminances) * 100
    print(f"  isoluminance spread {spread:.3f}%")

    print("clearances, as drawn on the tile and as rendered:")
    for name, gap in clearances(points, spike, stroke).items():
        print(f"  {name:>16}  {gap:6.1f} u   "
              f"{gap * 120 / TILE:4.2f} px @40pt·3x   {gap * 40 / TILE:4.2f} px @40px")


if __name__ == "__main__":
    main()
