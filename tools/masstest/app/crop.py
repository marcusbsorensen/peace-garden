"""A piece of a screenshot, by a frame in points, for a report.

    python3 tools/masstest/app/crop.py shot.jpg <window width pt> x y w h out.jpg [--pad 20] [--box x,y,w,h] [--width 600]

The screenshot is in pixels and the frames XCUITest gives are in points; the
scale is the picture's width over the window's. `--box` draws a rectangle
(points) on the crop, round the thing being pointed at. Written as a JPEG no
wider than `--width`.
"""
import argparse
from PIL import Image, ImageDraw

p = argparse.ArgumentParser()
p.add_argument("shot")
p.add_argument("window", type=float)
p.add_argument("x", type=float)
p.add_argument("y", type=float)
p.add_argument("w", type=float)
p.add_argument("h", type=float)
p.add_argument("out")
p.add_argument("--pad", type=float, default=20)
p.add_argument("--box", default="")
p.add_argument("--width", type=int, default=600)
a = p.parse_args()

im = Image.open(a.shot).convert("RGB")
s = im.width / a.window
left, top = max(0, (a.x - a.pad) * s), max(0, (a.y - a.pad) * s)
right, bottom = min(im.width, (a.x + a.w + a.pad) * s), min(im.height, (a.y + a.h + a.pad) * s)
if a.box:
    bx, by, bw, bh = (float(v) for v in a.box.split(","))
    ImageDraw.Draw(im).rectangle([bx * s, by * s, (bx + bw) * s, (by + bh) * s], outline=(255, 64, 160), width=max(2, int(s)))
crop = im.crop((int(left), int(top), int(right), int(bottom)))
if crop.width > a.width:
    crop = crop.resize((a.width, int(crop.height * a.width / crop.width)), Image.LANCZOS)
crop.save(a.out, "JPEG", quality=78, optimize=True)
print(a.out, crop.size)
