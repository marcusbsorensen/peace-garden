#!/usr/bin/env python3
"""
Renders plants from `plant_model.py` to a PNG.

A rough stand-in for the SceneKit renderer — painter's algorithm, one key light,
one rim — so the shapes and the palettes can be judged without a Mac.

  python3 preview.py --seeds 12 --out sheet.png          # a contact sheet
  python3 preview.py --seed hello --stages --out row.png # one plant over time
  python3 preview.py --seeds 6 --feet --out feet.png     # the foot, close, both ways up

Back faces are culled for the roles the app culls them for, so a hole in the
mesh comes out as a hole here. It did not always: this drew every triangle
whichever way it faced, which closes every gap it should have been reporting.
"""

import argparse
import colorsys
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "reference"))

from derivation_reference import cross, encounter_id, mint_seed  # noqa: E402
from plant_model import (  # noqa: E402
    Genome,
    build_mesh,
    growth_state,
    normalize,
    ramp_colour,
)

KEY_LIGHT = normalize(np.array([0.55, 0.75, 0.75]))
RIM_LIGHT = normalize(np.array([-0.6, 0.15, -0.8]))
RIM_COLOUR = np.array([0.62, 0.72, 1.0])
AMBIENT = np.array([0.16, 0.18, 0.24]) * 0.55


def shade(role, colour_hsb, normal, glow):
    base = np.array(colorsys.hsv_to_rgb(*colour_hsb))
    key = max(0.0, float(np.dot(normal, KEY_LIGHT)))
    rim = max(0.0, float(np.dot(normal, RIM_LIGHT))) ** 2
    lit = base * (AMBIENT + key * 0.95) + RIM_COLOUR * base * rim * 0.5
    if role in ("centre", "stamen"):
        lit = lit + base * (0.12 + glow * 0.3)
    if role == "petal":
        lit = lit + base * glow * 0.12
    return np.clip(lit, 0, 1)


# The stage: a black ground with a soft, cool pool of light behind the plant,
# falling off to pure black at the edges. Mirrors StageBackdrop.swift.
BACKDROP_BASE_HUE = 0.60
BACKDROP_TINT = 0.12
BACKDROP_SATURATION = 0.30
BACKDROP_BRIGHTNESS = 0.26
BACKDROP_CENTRE = (0.5, 0.46)
BACKDROP_RADIUS = 0.85
BACKDROP_FALLOFF = 2.0


def backdrop_hue(palette):
    """Cool slate, nudged toward the plant's own colour so each stage is its own."""
    base, petal = BACKDROP_BASE_HUE, palette["petalBase"][0]
    delta = petal - base
    if delta > 0.5:
        delta -= 1
    if delta < -0.5:
        delta += 1
    return (base + delta * BACKDROP_TINT) % 1.0


def draw_backdrop(image, palette):
    width, height = image.size
    glow = np.array(colorsys.hsv_to_rgb(backdrop_hue(palette),
                                        BACKDROP_SATURATION, BACKDROP_BRIGHTNESS))
    radius = max(width, height) * BACKDROP_RADIUS
    cx, cy = width * BACKDROP_CENTRE[0], height * BACKDROP_CENTRE[1]

    ys, xs = np.mgrid[0:height, 0:width]
    distance = np.sqrt((xs - cx) ** 2 + (ys - cy) ** 2) / radius
    falloff = np.clip(1.0 - distance, 0.0, 1.0) ** BACKDROP_FALLOFF
    pixels = (falloff[:, :, None] * glow[None, None, :] * 255).astype(np.uint8)
    image.paste(Image.fromarray(pixels, "RGB"), (0, 0))


# Which materials the app lights from both faces, from `PlantSceneBuilder`'s
# `material(for:)`. Everything absent from this set is back-face culled there,
# and has to be culled here too.
#
# **This tool drew every triangle for a year, whichever way it faced.** That is
# a renderer with no hidden surfaces at all, and it cannot show a hole: an open
# end, a lid facing away, a surface wound inside out all come out looking solid.
# It is the reason the hole in the foot of every stem lived here undetected —
# `preview` was rendering the mesh, faithfully, and quietly closing it.
DOUBLE_SIDED = {"stem", "leaf", "petal"}


def render(genome, growth, size=(420, 620), yaw=0.55, pitch=0.08, supersample=2,
           look=0.5, spread=1.5, on_axis=False):
    """One plant.

    `look` is where the camera aims, as a fraction of the plant's own height: 0.5
    is the middle of it and 0 is the foot. `spread` is how much room it is given
    — 1.5 frames the whole plant, and below 1 it closes in on whatever `look`
    picked out. Together they are what `--feet` uses to get near the ground,
    which is the one part of a plant this tool never used to show.

    `on_axis` aims sideways at the plant's own stem at that height rather than at
    the middle of its bounding box. The two agree on an upright plant and part
    company on a leaning one, whose box is centred on air a long way from the
    stem — far enough that a close frame misses the plant altogether.
    """
    parts = build_mesh(genome, growth)
    if not parts:
        return Image.new("RGB", size, (0, 0, 0))

    every = [p for part in parts.values() for p in part["positions"]]
    points = np.array(every)
    low, high = points.min(axis=0), points.max(axis=0)
    centre = (low + high) * 0.5
    centre[1] = low[1] + (high[1] - low[1]) * look
    if on_axis:
        near = points[abs(points[:, 1] - centre[1]) < max(high[1] - low[1], 1e-6) * 0.05]
        if len(near):
            centre[0], centre[2] = float(near[:, 0].mean()), float(near[:, 2].mean())
    extent = high - low
    radius = max(0.06, float(max(extent)) * 0.5)
    distance = radius / math.tan(math.radians(36) / 2) * spread

    cos_yaw, sin_yaw = math.cos(yaw), math.sin(yaw)
    cos_pitch, sin_pitch = math.cos(pitch), math.sin(pitch)

    def to_camera(point):
        p = point - centre
        x = p[0] * cos_yaw + p[2] * sin_yaw
        z = -p[0] * sin_yaw + p[2] * cos_yaw
        y = p[1] * cos_pitch - z * sin_pitch
        z = p[1] * sin_pitch + z * cos_pitch
        return np.array([x, y, z - distance])

    def rotate_normal(normal):
        x = normal[0] * cos_yaw + normal[2] * sin_yaw
        z = -normal[0] * sin_yaw + normal[2] * cos_yaw
        y = normal[1] * cos_pitch - z * sin_pitch
        z = normal[1] * sin_pitch + z * cos_pitch
        return np.array([x, y, z])

    width, height = size[0] * supersample, size[1] * supersample
    focal = (height * 0.5) / math.tan(math.radians(36) / 2)

    triangles = []
    for role, part in parts.items():
        positions = part["positions"]
        normals = part["normals"]
        uvs = part["uvs"]
        for a, b, c in part["indices"]:
            camera_points = [to_camera(positions[i]) for i in (a, b, c)]
            if any(p[2] > -0.01 for p in camera_points):
                continue
            # Back-face culling, on the same terms the app culls. The camera
            # looks down -Z, so the way back to it is +Z: a triangle faces us
            # when its winding normal has a positive z.
            if role not in DOUBLE_SIDED:
                edge_a = camera_points[1] - camera_points[0]
                edge_b = camera_points[2] - camera_points[0]
                if np.cross(edge_a, edge_b)[2] <= 0:
                    continue
            screen = []
            for p in camera_points:
                screen.append((width * 0.5 + p[0] * focal / -p[2],
                               height * 0.5 - p[1] * focal / -p[2]))
            depth = sum(p[2] for p in camera_points) / 3.0
            normal = rotate_normal(normalize(sum(np.array(normals[i]) for i in (a, b, c)) / 3.0))
            u = sum(uvs[i][0] for i in (a, b, c)) / 3.0
            v = sum(uvs[i][1] for i in (a, b, c)) / 3.0
            triangles.append((depth, role, screen, normal, u, v))

    triangles.sort(key=lambda item: item[0])

    image = Image.new("RGB", (width, height), (0, 0, 0))
    draw_backdrop(image, genome.palette)
    draw = ImageDraw.Draw(image)
    for _, role, screen, normal, u, v in triangles:
        colour = shade(role, ramp_colour(role, u, v, genome.palette), normal, genome.glow)
        draw.polygon(screen, fill=tuple(int(c * 255) for c in colour))

    return image.resize(size, Image.LANCZOS)


def contact_sheet(seeds, columns=4, cell=(300, 430), age_days=None):
    rows = math.ceil(len(seeds) / columns)
    sheet = Image.new("RGB", (columns * cell[0], rows * cell[1]), (0, 0, 0))
    for index, label in enumerate(seeds):
        genome = Genome(mint_seed(label.encode()))
        days = age_days if age_days is not None else genome.daysToBloom + genome.bloomDays * 0.45
        state = growth_state(genome, days * 86400)
        tile = render(genome, state, size=cell)
        sheet.paste(tile, ((index % columns) * cell[0], (index // columns) * cell[1]))
        # No binomial in the caption, and see `plant_model.Genome.__init__` for
        # why: the port grows geometry and names nothing. The name it used to
        # print here was three months behind SeedCore's, which is to say it was
        # a name no plant in the garden has ever had.
        print(f"{label:>10}  {genome.archetype:<10} "
              f"petals {genome.petalCount:>3}  leaves {genome.leafCount:>3}  "
              f"{state['stage']} open={state['bloomOpen']:.2f}")
    return sheet


def stage_row(label, cell=(300, 430)):
    genome = Genome(mint_seed(label.encode()))
    # Day zero first, and not by accident: the row used to start at 0.2, and the
    # plant a person actually meets — the one drawn seconds ago — was the single
    # frame nobody had ever looked at. It was a mushroom for months.
    marks = [0.0, 0.2, 1.0, genome.daysToBloom * 0.5, genome.daysToBloom * 0.85,
             genome.daysToBloom + 0.4, genome.daysToBloom + genome.bloomDays * 0.5]
    sheet = Image.new("RGB", (len(marks) * cell[0], cell[1]), (0, 0, 0))
    for index, days in enumerate(marks):
        state = growth_state(genome, days * 86400)
        sheet.paste(render(genome, state, size=cell), (index * cell[0], 0))
        print(f"day {days:6.2f}  {state['stage']:<12} height={state['heightScale']:.2f} "
              f"leaves={state['leafUnfurl']:.2f} bloom={state['bloomOpen']:.2f}")
    return sheet


def foot_row(labels, cell=(300, 430)):
    """The foot of each plant, from the angle the app actually looks at it.

    **The one angle this tool never took.** Every other mode centres on the
    plant's bounding box and stands far enough back to hold all of it, which
    puts the foot small, low in the frame and seen from above. The app does not
    stand there: `PlantSceneView.applyFraming` raises its aim above the plant's
    middle and comes in close, so the foot is large and near the bottom of the
    screen, a few points under the mark row. That is where a person meets it.

    Two rows. The top one is the app's own angle, slightly down onto the foot,
    which is where the hole in the stem was visible for a year. The bottom one
    is from below, because a lid that faces the ground can only be checked by
    something standing under it — and it is the view that says whether a foot is
    closed or merely appears closed from above.
    """
    sheet = Image.new("RGB", (len(labels) * cell[0], cell[1] * 2), (0, 0, 0))
    for index, label in enumerate(labels):
        genome = Genome(mint_seed(label.encode()))
        days = genome.daysToBloom + genome.bloomDays * 0.45
        state = growth_state(genome, days * 86400)

        # Framed against the stem's own width, not the plant's. `render` puts
        # exactly `radius * spread` of world into half the frame, and a foot is
        # two orders of magnitude narrower than a plant is tall — sized off the
        # plant, every one of these lands either inside the stem or nowhere near
        # it, depending on how tall that plant happened to grow.
        parts = build_mesh(genome, state)
        points = np.array([p for part in parts.values() for p in part["positions"]])
        low, high = points.min(axis=0), points.max(axis=0)
        radius = max(0.06, float(max(high - low)) * 0.5)
        near_foot = points[points[:, 1] < low[1] + (high[1] - low[1]) * 0.02]
        width = float(np.hypot(near_foot[:, 0], near_foot[:, 2]).max())
        spread = max(width, 1e-4) * 7 / radius

        for row, pitch in enumerate((0.22, -0.40)):
            tile = render(genome, state, size=cell, pitch=pitch,
                          look=0.012, spread=spread, on_axis=True)
            sheet.paste(tile, (index * cell[0], row * cell[1]))
        print(f"{label:>10}  {genome.archetype:<10} "
              f"foot {width * 1000:5.1f}mm  {state['stage']}")
    return sheet


def cross_row(label_a, label_b, cell=(300, 430)):
    """Two parents and the plant their meeting made, side by side."""
    seed_a = mint_seed(label_a.encode())
    seed_b = mint_seed(label_b.encode())
    enc = encounter_id(seed_a, seed_b, b"\x01" * 16, b"\x02" * 16)
    child_seed = cross(seed_a, seed_b, enc)

    plants = [Genome(seed_a), Genome(seed_b), Genome(child_seed, parents=(seed_a, seed_b))]
    sheet = Image.new("RGB", (len(plants) * cell[0], cell[1]), (0, 0, 0))
    for index, genome in enumerate(plants):
        days = genome.daysToBloom + genome.bloomDays * 0.45
        state = growth_state(genome, days * 86400)
        sheet.paste(render(genome, state, size=cell), (index * cell[0], 0))
        role = ("parent", "parent", "child")[index]
        # A cross used to be read off the name — one parent's genus with the
        # other's epithet. It cannot be read here any more, and it should not
        # be: descent in the name is SeedCore's to show, in the app, where the
        # name is right. What this row shows is the body, which is the thing a
        # render can actually be checked against.
        print(f"{role:>7}  {genome.archetype:<10} "
              f"petals {genome.petalCount:>3}  leaves {genome.leafCount:>3}  "
              f"hue {genome.palette['petalBase'][0]:.2f}")
    return sheet


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--seeds", type=int, default=12)
    parser.add_argument("--seed", type=str)
    parser.add_argument("--prefix", type=str, default="plant")
    parser.add_argument("--stages", action="store_true")
    parser.add_argument("--feet", action="store_true",
                        help="the foot of each plant, from above and from below")
    parser.add_argument("--cross", nargs=2, metavar=("A", "B"))
    parser.add_argument("--age-days", type=float)
    parser.add_argument("--out", type=str, default="preview.png")
    args = parser.parse_args()

    if args.cross:
        image = cross_row(*args.cross)
    elif args.feet:
        image = foot_row([args.seed] if args.seed
                         else [f"{args.prefix}-{i}" for i in range(min(args.seeds, 6))])
    elif args.stages:
        image = stage_row(args.seed or f"{args.prefix}-0")
    else:
        labels = [args.seed] if args.seed else [f"{args.prefix}-{i}" for i in range(args.seeds)]
        image = contact_sheet(labels, age_days=args.age_days)

    image.save(args.out)
    print(f"wrote {args.out}")


if __name__ == "__main__":
    main()
