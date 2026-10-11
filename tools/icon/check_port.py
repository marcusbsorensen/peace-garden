#!/usr/bin/env python3
"""
Checks that `make_icon.py`'s outputs are the mark Marcus chose on 11 October 2026,
by comparing pixels with the design files it was ported from
(`design/logo-2026-10-11/d-taper/coil2-a/`).

  python3 tools/icon/check_port.py

Each pair is rasterised at the same size — the SVGs by CairoSVG, the PNG and the
.ico as they were written — composited on the ground each is seen on, and
compared channel by channel. It prints the mean and the maximum absolute
difference per channel, in 8-bit levels, and fails if either is past what
antialiasing alone explains: a mean of 1 level, or more than 0.5 % of pixels off
by over 24 levels. A shape that has moved or a colour that has changed fails both
by a wide margin; two renderers disagreeing about an edge fails neither.

Two things the design files carry that the port deliberately does not, and that
show here as a handful of pixels rather than as a failure:

- **The round ends.** The design files close each tapered line with one SVG arc
  across a diameter, which rounding can flatten by up to a pixel at 512; the port
  draws each end as two quarter arcs, so it stays round (see `outline` in
  `make_icon.py`). It is the maximum, not the mean, on the bare marks.
- **The favicon's corners.** CairoSVG draws a `<rect rx>` with uneven corners,
  two rounder than the other two. The reference is rasterised here with its
  rounded rect written out as the same shape in arcs, which CairoSVG draws evenly.

Run it after `make_icon.py`. It reads the design files and writes nothing.

  pip install cairosvg pillow numpy
"""

import io
import re
import sys
from pathlib import Path

import cairosvg
import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
DESIGN = ROOT / "design/logo-2026-10-11/d-taper/coil2-a"
SITE = ROOT / "Server"
APP_ICON = ROOT / "App/PeaceGarden/Resources/Assets.xcassets/AppIcon.appiconset/icon.png"

DARK = "#0D0D1F"      # the suite's ground, which the dark marks were solved on
LIGHT = "#F6F6F6"     # the site's light ground, which the light mark was solved on

MEAN_LIMIT = 1.0      # levels, per channel
FAR = 24              # levels: a pixel off by more than this is "far"
FAR_SHARE = 0.005     # of the pixels


def even_corners(text):
    """Each `<rect width height rx>` written out as a path of arcs."""
    def path(match):
        w, h, r = (float(match.group(i)) for i in (1, 2, 3))
        return (f'<path d="M{r:g} 0L{w - r:g} 0A{r:g} {r:g} 0 0 1 {w:g} {r:g}L{w:g} {h - r:g}'
                f'A{r:g} {r:g} 0 0 1 {w - r:g} {h:g}L{r:g} {h:g}A{r:g} {r:g} 0 0 1 0 {h - r:g}'
                f'L0 {r:g}A{r:g} {r:g} 0 0 1 {r:g} 0Z"')
    return re.sub(r'<rect width="([\d.]+)" height="([\d.]+)" rx="([\d.]+)"', path, text)


def raster_svg(path, size):
    png = cairosvg.svg2png(bytestring=even_corners(path.read_text()).encode(),
                           output_width=size, output_height=size)
    return Image.open(io.BytesIO(png)).convert("RGBA")


def raster_file(path, size):
    with Image.open(path) as image:
        if path.suffix == ".ico":
            image.size = (size, size)
        image.load()
        image = image.convert("RGBA")
    assert image.size == (size, size), f"{path} is {image.size}, not {size}"
    return image


def on(image, ground):
    """`image` flattened onto `ground`, as RGB levels."""
    under = Image.new("RGBA", image.size, ground)
    under.alpha_composite(image)
    return np.asarray(under.convert("RGB"), dtype=np.int16)


def compare(name, ours, reference, size, ground):
    a = on(ours, ground)
    b = on(reference, ground)
    diff = np.abs(a - b)
    mean = diff.reshape(-1, 3).mean(axis=0)
    peak = diff.reshape(-1, 3).max(axis=0)
    far = float((diff.max(axis=2) > FAR).mean())
    ok = bool(mean.max() <= MEAN_LIMIT and far <= FAR_SHARE)
    print(f"{'ok  ' if ok else 'FAIL'} {name:<44} {size:>4} px on {ground}   "
          f"mean R {mean[0]:4.2f} G {mean[1]:4.2f} B {mean[2]:4.2f}   "
          f"max R {peak[0]:3d} G {peak[1]:3d} B {peak[2]:3d}   "
          f"far {far * 100:5.2f} %")
    return ok


def main():
    checks = [
        # (name, ours at size, the design's file, size, ground)
        ("app icon, icon.png", lambda s: raster_file(APP_ICON, s),
         DESIGN / "icon-1024.svg", 1024, DARK),
        ("app icon, tools/icon/icon.svg", lambda s: raster_svg(HERE / "icon.svg", s),
         DESIGN / "icon-1024.svg", 1024, DARK),
        ("site icon, assets/icon.svg", lambda s: raster_svg(SITE / "assets/icon.svg", s),
         DESIGN / "icon-1024.svg", 1024, DARK),
        ("touch icon, assets/icon-180.png",
         lambda s: raster_file(SITE / "assets/icon-180.png", s),
         DESIGN / "icon-1024.svg", 180, DARK),
        ("bare mark, assets/mark-dark.svg",
         lambda s: raster_svg(SITE / "assets/mark-dark.svg", s),
         DESIGN / "d-taper-coil2-a.svg", 512, DARK),
        ("bare mark, assets/mark-light.svg",
         lambda s: raster_svg(SITE / "assets/mark-light.svg", s),
         DESIGN / "d-taper-coil2-a-light-ground.svg", 512, LIGHT),
    ]
    for size in (16, 32, 48):
        for ground in (DARK, LIGHT):
            checks.append((f"favicon, favicon.ico", lambda s: raster_file(SITE / "favicon.ico", s),
                           DESIGN / "d-taper-coil2-a-favicon.svg", size, ground))
    results = [compare(name, ours(size), raster_svg(reference, size), size, ground)
               for name, ours, reference, size, ground in checks]
    failed = results.count(False)
    print(f"{len(results) - failed} of {len(results)} match")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
