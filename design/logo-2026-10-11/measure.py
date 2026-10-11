#!/usr/bin/env python3
"""
Measures the suite apps' real icons, 11 October 2026: stroke weight, how much
of the tile the mark fills, the ground, and the hue band each gradient spans.

  python3 design/logo-2026-10-11/measure.py

Reads the copies in `suite-icons/` (taken from each repository's own app icon
set; see the README for the commits) and writes `measurements.json`.

Stroke width is measured from the raster with a distance transform: every ink
pixel's distance to the nearest ground pixel, sampled on the ridge (local
maxima), so twice the ridge value is the local stroke width. Taken separately
for the gradient ink and for the white/cream accent, since the suite lets the
accent carry a different weight. Where the SVG or the generator gives the
number exactly, the README quotes that beside this.

  pip install numpy scipy pillow
"""

import colorsys
import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

HERE = Path(__file__).resolve().parent
ICONS = HERE / "suite-icons"

APPS = [
    # (key, display name, file)
    ("pfish", "Pfish", "pfish-1024.png"),
    ("uncubed", "UnCubed", "uncubed-1024.png"),
    ("arc", "Animal Rescue Centre", "animal-rescue-centre-1024.png"),
    ("flagfans", "FlagFans", "flagfans-1024.png"),
    ("freqshift", "FreqShift", "freqshift-162.png"),
    ("peace-garden-today", "Peace Garden (today)", "peace-garden-today-1024.png"),
]


def ground_of(rgb):
    """The ground: the commonest colour along the tile's inner border band."""
    h, w, _ = rgb.shape
    band = np.concatenate([rgb[h // 8, w // 8: -w // 8], rgb[-h // 8, w // 8: -w // 8],
                           rgb[h // 8: -h // 8, w // 8], rgb[h // 8: -h // 8, -w // 8]])
    return np.median(band, axis=0)


def widths(mask):
    if mask.sum() < 20:
        return None
    dt = ndimage.distance_transform_edt(mask)
    ridge = (dt == ndimage.maximum_filter(dt, size=3)) & (dt >= 1.5)
    vals = dt[ridge]
    if len(vals) < 10:
        return None
    # Twice the ridge distance, less the half-pixel the transform adds at the
    # anti-aliased edge.
    return float(np.median(vals) * 2 - 1), float(np.percentile(vals, 90) * 2 - 1)


def measure(path):
    im = Image.open(path).convert("RGB")
    rgb = np.asarray(im).astype(float)
    # FreqShift's only artefact in its repository is a 162 px web logo: its own
    # rounded tile on a darker page. Normalise to the tile, not the image.
    page = rgb[1, 1]
    tile = np.abs(rgb - page).sum(axis=2) > 25
    if np.abs(ground_of(rgb) - page).sum() > 25:
        ys, xs = np.nonzero(tile)
        rgb = rgb[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    size = (rgb.shape[0] + rgb.shape[1]) / 2
    ground = ground_of(rgb)
    diff = np.abs(rgb - ground).sum(axis=2)
    ink = diff > 90
    hsv = np.array([colorsys.rgb_to_hsv(*(p / 255)) for p in rgb[ink]])
    sat = np.zeros(ink.shape)
    val = np.zeros(ink.shape)
    hue = np.zeros(ink.shape)
    sat[ink], val[ink], hue[ink] = hsv[:, 1], hsv[:, 2], hsv[:, 0] * 360
    accent = ink & (sat < 0.18) & (val > 0.8)
    colour = ink & ~accent & (sat >= 0.18)
    ys, xs = np.nonzero(ink)
    x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
    # Hue band of the gradient ink, measured in HSL as suite-brand.md §3.4 is.
    hues = []
    for p in rgb[colour][:: max(1, colour.sum() // 4000)]:
        h_, l_, s_ = colorsys.rgb_to_hls(*(p / 255))
        if s_ > 0.2:
            hues.append(h_ * 360)
    hues = np.array(hues)
    # Unwrap around red so a band crossing 0° (ARC's 355° → 25°) reads as one.
    if len(hues) and (hues > 300).any() and (hues < 60).any():
        hues = np.where(hues > 180, hues - 360, hues)
    cw = widths(colour)
    aw = widths(accent)
    bright = rgb[colour]
    return {
        "size": round(size),
        "ground": "#" + "".join(f"{round(c):02X}" for c in ground),
        "ink_box_w": round((x1 - x0 + 1) / size, 3),
        "ink_box_h": round((y1 - y0 + 1) / size, 3),
        "ink_area": round(float(ink.sum()) / size ** 2, 3),
        "stroke_colour": round(cw[0] / size, 4) if cw else None,
        "stroke_colour_p90": round(cw[1] / size, 4) if cw else None,
        "stroke_accent": round(aw[0] / size, 4) if aw else None,
        "accent_share": round(float(accent.sum()) / max(1, ink.sum()), 3),
        "hue_lo": round(float(np.percentile(hues, 5)) % 360, 1) if len(hues) else None,
        "hue_hi": round(float(np.percentile(hues, 95)) % 360, 1) if len(hues) else None,
        "hue_mid": round(float(np.median(hues)) % 360, 1) if len(hues) else None,
        "mean_sat": round(float(np.mean([colorsys.rgb_to_hls(*(p / 255))[2] for p in bright[::max(1, len(bright) // 2000)]])), 3) if len(bright) else None,
    }


CANDIDATES = ["d-suite", "d-light", "e-suite", "e-light"]


def rendered(folder):
    """A candidate's icon, rendered to a PNG beside the suite copies' measure."""
    import io
    import cairosvg
    png = cairosvg.svg2png(url=str(HERE / folder / "icon-1024.svg"), output_width=1024)
    return io.BytesIO(png)


def main():
    out = {}
    rows = [(k, n, ICONS / f) for k, n, f in APPS]
    rows += [(c, f"Candidate {c}", rendered(c)) for c in CANDIDATES if (HERE / c).exists()]
    for key, name, f in rows:
        m = measure(f)
        m["name"] = name
        out[key] = m
        print(f"{name:22s} stroke {m['stroke_colour']}  accent {m['stroke_accent']}  "
              f"box {m['ink_box_w']}×{m['ink_box_h']}  area {m['ink_area']}  "
              f"ground {m['ground']}  hue {m['hue_lo']}→{m['hue_hi']} (mid {m['hue_mid']})  "
              f"sat {m['mean_sat']}  accent share {m['accent_share']}")
    (HERE / "measurements.json").write_text(json.dumps(out, indent=2) + "\n")


if __name__ == "__main__":
    main()
