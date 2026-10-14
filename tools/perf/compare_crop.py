#!/usr/bin/env python3
"""Before, after and their difference side by side, cropped and scaled.

    python3 tools/perf/compare_crop.py before.png after.png out.jpg x,y,w,h [--width 900] [--gain 8]

The crop is in points at the photographs' scale of 3. The third panel is the
largest channel difference, multiplied by `gain`.
"""
import argparse

import numpy as np
from PIL import Image

parser = argparse.ArgumentParser()
parser.add_argument("before")
parser.add_argument("after")
parser.add_argument("out")
parser.add_argument("crop")
parser.add_argument("--width", type=int, default=900)
parser.add_argument("--gain", type=float, default=8)
parser.add_argument("--scale", type=float, default=3)
args = parser.parse_args()

x, y, w, h = (int(float(v) * args.scale) for v in args.crop.split(","))
a = Image.open(args.before).convert("RGB").crop((x, y, x + w, y + h))
b = Image.open(args.after).convert("RGB").crop((x, y, x + w, y + h))
d = np.abs(np.asarray(a, dtype=np.int16) - np.asarray(b, dtype=np.int16)).max(axis=2)
heat = Image.fromarray(np.clip(d * args.gain, 0, 255).astype(np.uint8)).convert("RGB")
gap = 6
sheet = Image.new("RGB", (w * 3 + gap * 2, h), (255, 255, 255))
for i, panel in enumerate((a, b, heat)):
    sheet.paste(panel, (i * (w + gap), 0))
ratio = args.width / sheet.width
sheet = sheet.resize((args.width, max(1, int(sheet.height * ratio))), Image.LANCZOS)
sheet.save(args.out, quality=85)
