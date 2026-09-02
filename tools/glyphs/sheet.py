"""Render the stage-row marks, large and at the size they are actually drawn.

    python3 tools/glyphs/sheet.py --out out/marks.png

Two halves, because the app now has two grounds and a mark has to survive both:
black with the stroke at white 72%, and the light ground (white 0.965) with it
at near-black 70%. Each mark appears large enough to criticise and at fifteen
points, which is the only size that has ever caught anything.

`--paths` takes a directory of SVG files instead of the built-in shapes, so a
traced candidate can be put through the same sheet as what it would replace.
"""

import argparse
import io
import os
import sys

import cairosvg
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import shapes  # noqa: E402

SCALE = 3            # device pixels per point, as a phone draws it
LARGE = 132.0        # points, for looking at
TRUE = shapes.SIDE   # points, as the row draws it

GROUNDS = [
    ("On black", (0, 0, 0), (255, 255, 255), 0.72),
    ("On the light ground", (246, 246, 246), (18, 18, 18), 0.70),
]


def render(subpaths, side, stroke, ink, alpha, px):
    """One mark, as a transparent RGBA image `px` pixels square."""
    body = "".join(
        '<path d="%s" %s fill="none" stroke="rgb(%d,%d,%d)" stroke-opacity="%g" '
        'stroke-width="%g" stroke-linecap="round" stroke-linejoin="round"/>'
        % (d, f'transform="{t}"' if t else "", *ink, alpha, stroke)
        for d, t in subpaths
    )
    svg = (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {side} {side}" '
        f'width="{side}" height="{side}">{body}</svg>'
    )
    png = cairosvg.svg2png(bytestring=svg.encode(), output_width=px, output_height=px)
    return Image.open(io.BytesIO(png)).convert("RGBA")


def _font(size):
    for name in ("/System/Library/Fonts/SFNSMono.ttf",
                 "/System/Library/Fonts/Supplemental/Andale Mono.ttf",
                 "/Library/Fonts/Arial.ttf"):
        if os.path.exists(name):
            return ImageFont.truetype(name, size)
    return ImageFont.load_default()


def sheet(marks, out):
    cols = len(marks)
    cell = int(LARGE * SCALE) + 60
    pad = 44
    head = 40
    strip = 120                      # the true-size row under each ground
    half = head + cell + strip
    width = pad * 2 + cell * cols
    canvas = Image.new("RGB", (width, pad * 2 + half * len(GROUNDS)), (28, 28, 32))
    draw = ImageDraw.Draw(canvas)
    label = _font(19)
    small = _font(15)

    for row, (title, ground, ink, alpha) in enumerate(GROUNDS):
        top = pad + row * half
        draw.rectangle([pad, top, width - pad, top + half - 20], fill=ground)
        draw.text((pad + 18, top + 12), title, font=label,
                  fill=tuple(int(c * 0.45 + 128 * 0.55) for c in ink))

        for col, (name, fn) in enumerate(marks):
            x = pad + col * cell
            big = render(fn(LARGE), LARGE, shapes.STROKE * (LARGE / TRUE),
                         ink, alpha, int(LARGE * SCALE))
            canvas.paste(big, (x + 30, top + head + 20), big)
            draw.text((x + 30, top + head + cell - 34), name, font=small, fill=ink)

            # And at fifteen points, three times over, which is how it is met.
            true = render(fn(TRUE), TRUE, shapes.STROKE, ink, alpha, int(TRUE * SCALE))
            ty = top + head + cell + 30
            for k in range(3):
                canvas.paste(true, (x + 30 + k * int(TRUE * SCALE) + k * 14, ty), true)
            draw.text((x + 30, ty + 62), "15 pt", font=small, fill=ink)

    os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
    canvas.save(out)
    print(f"{out}  {canvas.width}x{canvas.height}")


def from_directory(path):
    """Each `*.svg` in `path` becomes a mark, named from its file."""
    import re
    marks = []
    for name in sorted(os.listdir(path)):
        if not name.endswith(".svg"):
            continue
        text = open(os.path.join(path, name)).read()
        box = re.search(r'viewBox="0 0 ([\d.]+) ([\d.]+)"', text)
        source = float(box.group(1)) if box else 100.0
        ds = re.findall(r'\sd="([^"]+)"', text)
        if not ds:
            print(f"  no path in {name}, skipped")
            continue

        def fn(side, ds=ds, source=source):
            k = side / source
            return [(d, f"scale({k})") for d in ds]

        marks.append((os.path.splitext(name)[0], fn))
    return marks


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="out/marks.png")
    ap.add_argument("--paths", help="a directory of SVGs to render instead")
    args = ap.parse_args()
    sheet(from_directory(args.paths) if args.paths else shapes.MARKS, args.out)
