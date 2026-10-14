#!/usr/bin/env python3
"""Compares two photographs of the garden pixel by pixel.

    python3 tools/perf/pixel_diff.py before.png after.png [--region x,y,w,h] [--heat out.png]

Prints, over the whole picture and over the plot's region (in points, at the
picture's own scale of 3), the mean absolute difference per channel (0-255),
the 99th percentile and the largest, and the share of pixels differing by
more than 8, 16 and 32 levels in any channel. `--heat` writes the difference,
amplified eight times, as a picture, for looking at where it is.

The garden has things in it that move with the wall clock — the clouds, the
sky's birds — so two photographs of the *same* build differ too; run it on two
of those for the floor before reading anything into a difference.
"""
import argparse

import numpy as np
from PIL import Image

parser = argparse.ArgumentParser()
parser.add_argument("before")
parser.add_argument("after")
parser.add_argument("--region", help="x,y,w,h in points (scale 3)")
parser.add_argument("--heat")
parser.add_argument("--scale", type=float, default=3)
args = parser.parse_args()

a = np.asarray(Image.open(args.before).convert("RGB"), dtype=np.int16)
b = np.asarray(Image.open(args.after).convert("RGB"), dtype=np.int16)
assert a.shape == b.shape, (a.shape, b.shape)
d = np.abs(a - b)


def report(name, part):
    worst = part.max(axis=2)
    total = worst.size
    print(f"{name}: {part.shape[1]}x{part.shape[0]} px, mean {part.mean():.2f}, "
          f"p99 {np.percentile(worst, 99):.0f}, max {worst.max()}, "
          f">8 {100 * (worst > 8).sum() / total:.2f}%, "
          f">16 {100 * (worst > 16).sum() / total:.2f}%, "
          f">32 {100 * (worst > 32).sum() / total:.2f}%")


report("whole", d)
if args.region:
    x, y, w, h = (float(v) * args.scale for v in args.region.split(","))
    report("region", d[int(y):int(y + h), int(x):int(x + w)])
if args.heat:
    heat = np.clip(d.max(axis=2) * 8, 0, 255).astype(np.uint8)
    Image.fromarray(heat).save(args.heat)
