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
SITE = ROOT / "Server"

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

# **The bract is white, and the coil's colour runs on into it and dies away.**
#
# It was the other way round until 4 September: the bract took the sweep and a
# flat white spadix stood inside it, which is the suite's own habit — Pfish
# carries two white bubble rings beside a fish that graduates, at the fish's own
# weight and in flat #FFFFFF. Marcus asked for the inversion, and it says more
# about the app than the arrangement it replaces: the white is what has opened,
# and the colour is the unfolding still travelling through it.
#
# §3.2 is untouched. The bract is still an outline at the main weight, and the
# taper is a fill rather than a stroke only because a stroke cannot narrow, and
# this one has to reach nothing at its point.
BRACT = "#FFFFFF"

# The taper leaves the coil at exactly the stroke's half-width, so there is no
# seam at the mouth of the bract, and it reaches nothing well short of the
# bract's own tip — colour running the whole length would read as a filled leaf
# rather than as something arriving in an open one.
TAPER_TO = 0.58        # along the bract's spine
TAPER_POWER = 1.7      # above 1: full at the mouth, thin early, long in the point
TAPER_SEAM = 0.20      # below this the taper and the outline share ink, on purpose
TAPER_CLEARANCE = 8.0  # construction units, each side, past the seam
TAPER_TURNS_AT = 0.38  # how far along the taper the yellow has fully arrived

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
    blade, room, axis = taper(spine)
    return line, spathe(spine), blade, room, axis


def spathe_half_width(s, length):
    """The bract's half-width at `s` along its spine. Zero at both ends."""
    return np.sin(np.pi * s ** 0.62) ** 0.85 * SPATHE_WIDTH * length


def taper_half_width(s):
    """The taper's half-width at `s` along the bract's spine, reaching nothing."""
    return np.clip(1 - s / TAPER_TO, 0, 1) ** TAPER_POWER * STROKE / 2


def taper(spine):
    """
    The coil's colour carried into the bract, as an outline to be filled.

    Built the same way the bract is — out along one edge and back along the
    other — so the two shapes are the same construction and cannot drift apart.

    Returns the outline and the tightest room it leaves inside the bract, which
    `main` reports beside the other clearances rather than leaving to be
    squinted at.
    """
    length = float(np.sum(np.linalg.norm(np.diff(spine, axis=0), axis=1)))
    s = np.linspace(0, 1, len(spine))
    keep = s <= TAPER_TO
    spine, s = spine[keep], s[keep]

    tangents = np.gradient(spine, axis=0)
    tangents /= np.maximum(np.linalg.norm(tangents, axis=1, keepdims=True), 1e-9)
    normals = np.stack([-tangents[:, 1], tangents[:, 0]], axis=1)
    width = taper_half_width(s)[:, None]

    # **Past the seam the taper has to sit inside the bract's hollow. At the
    # mouth the two share ink deliberately** — that shared ink is the whole of
    # what makes the colour read as running on, rather than as a second mark
    # that happens to be standing nearby.
    past = s > TAPER_SEAM
    room = float((spathe_half_width(s[past], length) - STROKE / 2
                  - taper_half_width(s[past])).min())
    assert room >= TAPER_CLEARANCE, (
        f"the taper leaves {room:.1f} units of clearance, wanted {TAPER_CLEARANCE}"
    )
    return (np.concatenate([spine + normals * width,
                            (spine - normals * width)[::-1]]),
            room, np.array([spine[0], spine[-1]]))


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
    coil, bract, spike, room, axis = spiral()
    # The taper sits inside the bract, so it cannot extend the bounds — but it is
    # measured with everything else rather than assumed not to.
    min_x, min_y, max_x, max_y = ink_bounds(
        list(coil) + list(bract) + list(spike), STROKE)
    available = TILE - 2 * MARGIN
    scale = available / max(max_x - min_x, max_y - min_y)

    # Centred on the drawn bounds. Unlike `un³` there is no open side wanting an
    # optical bias: the mark's ink is distributed about its own centre.
    width, height = (max_x - min_x) * scale, (max_y - min_y) * scale
    offset_x = (TILE - width) / 2 - min_x * scale
    offset_y = (TILE - height) / 2 - min_y * scale

    def place(run):
        return [(x * scale + offset_x, y * scale + offset_y) for x, y in run]

    return (place(coil), place(bract), place(spike), place(axis),
            room * scale, STROKE * scale)


# ------------------------------------------------------------------- output

def sweep_at(point, box, stops):
    """The colour the sweep has reached at `point`, so the taper can join it."""
    start = np.array([box[0], box[3]])
    axis = np.array([box[2], box[1]]) - start
    t = float(np.clip((np.array(point) - start) @ axis / (axis @ axis), 0, 1))
    position = t * (len(stops) - 1)
    lower = int(min(max(math.floor(position), 0), len(stops) - 2))
    blend = position - lower
    return tuple(stops[lower][1][i] * (1 - blend) + stops[lower + 1][1][i] * blend
                 for i in range(3))


def path_data(points):
    return "M " + " L ".join(f"{x:.2f} {y:.2f}" for x, y in points)


def svg(coil, bract, spike, axis, stroke, stops):
    # **The sweep spans the ink that takes it, which is the coil and the taper —
    # not the bract.** With the bract white, measuring across it spends the top
    # of the ramp on ink that is not drawn in it: the yellow landed inside the
    # leaf's white outline, and the coil was left showing only the green half of
    # its own gradient. Measured across the coloured run, the spiral goes green
    # to yellow along its own length and the taper is the yellow end of it.
    box = ink_bounds(list(coil) + list(spike), stroke)
    # Bottom-left to top-right, across the drawn ink. In SVG's coordinates the
    # bottom is the larger y.
    x1, y1, x2, y2 = box[0], box[3], box[2], box[1]
    marks = "".join(
        f'<stop offset="{index / (len(stops) - 1):.4f}" stop-color="{to_hex(rgb)}"/>'
        for index, (_, rgb) in enumerate(stops)
    )
    # The bract first, then the coil, then the taper. The order is what puts the
    # colour over the white where they share ink at the mouth, which is the
    # junction reading as one stroke running on rather than as two meeting.
    # **The taper takes the ramp's last stop, and blends to it only at the
    # mouth.** The sweep is spatial — bottom-left to top-right, per §3.3 — and
    # the taper sits at the top *middle* of the mark rather than in that corner,
    # so left on the sweep it comes out mid-ramp green however the box is drawn.
    # It carries the yellow instead, joining the coil in the colour the coil has
    # arrived at, so the run still reads as one.
    (ax, ay), (bx, by) = axis[0], axis[1]
    hot = (f'<stop offset="0" stop-color="{to_hex(sweep_at(axis[0], box, stops))}"/>'
           f'<stop offset="{TAPER_TURNS_AT}" stop-color="{to_hex(stops[-1][1])}"/>'
           f'<stop offset="1" stop-color="{to_hex(stops[-1][1])}"/>')
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{TILE}" height="{TILE}" \
viewBox="0 0 {TILE} {TILE}">
<defs><linearGradient id="sweep" gradientUnits="userSpaceOnUse" \
x1="{x1:.2f}" y1="{y1:.2f}" x2="{x2:.2f}" y2="{y2:.2f}">{marks}</linearGradient>
<linearGradient id="point" gradientUnits="userSpaceOnUse" \
x1="{ax:.2f}" y1="{ay:.2f}" x2="{bx:.2f}" y2="{by:.2f}">{hot}</linearGradient></defs>
<rect width="{TILE}" height="{TILE}" fill="{GROUND}"/>
<path d="{path_data(bract)}" fill="none" stroke="{BRACT}" \
stroke-width="{stroke:.2f}" stroke-linecap="round" stroke-linejoin="round"/>
<path d="{path_data(coil)}" fill="none" stroke="url(#sweep)" \
stroke-width="{stroke:.2f}" stroke-linecap="round" stroke-linejoin="round"/>
<path d="{path_data(spike)} Z" fill="url(#point)" stroke="none"/>
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


def fill_mask(points):
    """A filled polygon, as a coverage mask. The taper's, and only the taper's."""
    canvas = TILE * SUPERSAMPLE
    mask = Image.new("L", (canvas, canvas), 0)
    ImageDraw.Draw(mask).polygon(
        [(x * SUPERSAMPLE, y * SUPERSAMPLE) for x, y in points], fill=255)
    return (np.asarray(mask, dtype=np.float32) / 255.0)[..., None]


def png(coil, bract, spike, spine_axis, stroke, stops):
    canvas = TILE * SUPERSAMPLE

    box = ink_bounds(list(coil) + list(spike), stroke)   # see `svg`
    start = np.array([box[0], box[3]])          # bottom-left
    axis = np.array([box[2], box[1]]) - start   # to top-right
    ys, xs = np.mgrid[0:canvas, 0:canvas].astype(np.float32) / SUPERSAMPLE
    t = np.clip(((xs - start[0]) * axis[0] + (ys - start[1]) * axis[1])
                / float(axis @ axis), 0, 1)

    # An even sweep: the coil and the taper are one continuous run of colour, so
    # §3.3's rule about putting the transitions in the gaps does not apply.
    colours = np.array([rgb for _, rgb in stops], dtype=np.float32)
    position = t * (len(stops) - 1)
    lower = np.clip(np.floor(position), 0, len(stops) - 2).astype(np.int32)
    blend = (position - lower)[..., None]
    gradient = colours[lower] * (1 - blend) + colours[lower + 1] * blend

    image = np.array(from_hex(GROUND), dtype=np.float32) * np.ones_like(gradient)

    # Bract, coil, taper — the same order the SVG draws them in, for the same
    # reason. The two have to agree: they come off one flattened polyline and a
    # difference between them would be a difference nobody is looking for.
    white = np.array(from_hex(BRACT), dtype=np.float32)
    bract_coverage = stroke_mask(bract, stroke)
    image = image * (1 - bract_coverage) + white * bract_coverage

    coil_coverage = stroke_mask(coil, stroke)
    image = image * (1 - coil_coverage) + gradient * coil_coverage

    # The taper carries the ramp's last stop. See the note in `svg`; the two
    # renderings have to agree.
    base = np.array(sweep_at(spine_axis[0], box, stops), dtype=np.float32)
    tip = np.array(stops[-1][1], dtype=np.float32)
    run = np.array(spine_axis[1]) - np.array(spine_axis[0])
    u = np.clip(((xs - spine_axis[0][0]) * run[0]
                 + (ys - spine_axis[0][1]) * run[1])
                / float(run @ run), 0, 1)
    u = np.clip(u / TAPER_TURNS_AT, 0, 1)[..., None]
    hot = base * (1 - u) + tip * u

    spike_coverage = fill_mask(spike)
    image = image * (1 - spike_coverage) + hot * spike_coverage

    out = Image.fromarray((np.clip(image, 0, 1) * 255).astype(np.uint8), "RGB")
    return out.resize((TILE, TILE), Image.LANCZOS)


CONTENTS = {
    "images": [
        {"filename": "icon.png", "idiom": "universal",
         "platform": "ios", "size": "1024x1024"}
    ],
    "info": {"author": "xcode", "version": 1},
}


def clearances(coil, bract, room, stroke):
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
    # clearance. The bract's outline starts and ends at that junction, being one
    # run out and back, so both of its ends are trimmed.
    body = np.array(coil[:400])
    edge = np.array(bract[47:-47])
    gaps = np.linalg.norm(edge[:, None, :] - body[None, :, :], axis=2)
    bract_to_coil = float(gaps.min()) - stroke

    # The taper inside the bract, measured where `taper` measured it: past the
    # seam, since at the mouth the two share ink on purpose.
    return {"between turns": turns, "bract to coil": bract_to_coil,
            "taper in bract": room}


def main():
    stops = ramp()
    coil, bract, spike, axis, room, stroke = fitted()

    CATALOGUE.mkdir(parents=True, exist_ok=True)
    (HERE / "icon.svg").write_text(svg(coil, bract, spike, axis, stroke, stops))
    # An app icon may not carry an alpha channel. The ground travels with the
    # mark — §10.4's "no light and dark pair" — so one drawing covers every
    # appearance and every size.
    png(coil, bract, spike, axis, stroke, stops).save(CATALOGUE / "icon.png")
    (CATALOGUE / "Contents.json").write_text(json.dumps(CONTENTS, indent=2) + "\n")

    # **The site's favicon is this drawing, not a second one.** It used to be
    # `mark.svg`, the wordmark, which is a different job: a favicon is seen at
    # sixteen pixels beside a title, where letterforms are a smudge and a mark is
    # a mark. Written from here so the two cannot drift — the same bargain the
    # SVG and the PNG already strike with each other.
    #
    # Three files, because a favicon is three questions. The SVG is what a
    # current browser takes and the only one that stays sharp. The 180 is what
    # iOS puts on a home screen, and this is a site people open on a phone. The
    # .ico is at the root because a browser asks for /favicon.ico whether or not
    # it has been told to, and a 404 in everybody's console is a thing somebody
    # will one day spend an afternoon on.
    tile = png(coil, bract, spike, axis, stroke, stops)
    (SITE / "assets/icon.svg").write_text(svg(coil, bract, spike, axis, stroke, stops))
    tile.resize((180, 180), Image.LANCZOS).save(SITE / "assets/icon-180.png")
    tile.resize((64, 64), Image.LANCZOS).save(
        SITE / "favicon.ico", sizes=[(16, 16), (32, 32), (48, 48)])

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
    for name, gap in clearances(coil, bract, room, stroke).items():
        print(f"  {name:>16}  {gap:6.1f} u   "
              f"{gap * 120 / TILE:4.2f} px @40pt·3x   {gap * 40 / TILE:4.2f} px @40px")


if __name__ == "__main__":
    main()
