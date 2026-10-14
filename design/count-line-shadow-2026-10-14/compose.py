"""31A: the garden's count line by day with no shadow and with shadows A, B
and C, at the worst moments of the day and some for reference.

    python3 design/count-line-shadow-2026-10-14/compose.py <renders> <out folder>

`<renders>` holds one folder per sweep of the mass test's screen harness
(`tools/masstest/app/run_tests.sh screens`, with `PG_MT_PNG=1`) on an iPhone
Air, named `<moment>-<none|A|B|C>`, each with `en-L-light/garden.png` (or
`en-AX5-light` for the largest type). See README.md.

**Measured against the sky as it is after the shadow.** The previous sheets
(`design/small-caps-2026-10-14/compose.py`) set the text against the median of
its whole box, which is mostly open sky and so says nothing about a shadow
that lies only round the letters. Here:

- The letters are found in the moment's render without a shadow: every pixel
  lighter than the sky around it by more than a few percent of the way to
  white, anti-aliased edge included. The same letters stand in the same place
  in all four renders.
- **The text** is as before: the mean of its box's most inked 4% of pixels.
- **The ground** is the pixels immediately round the letters, inside the
  shadow: more than one pixel and at most two points (6 px) from a letter.
  Each of those pixels belongs to the letter nearest it.
- **The figure is the lowest letter**: the text against the median of each
  letter's own ground, the least of the line's letters. The sky behind the
  line is uneven (the sun's halo in the morning, a cloud's edge), and by the
  line's median the unshadowed line already reads 4.5 : 1 at an October 07:30
  while the letters in the halo are at 3.2. The line's median (`lineMedian`),
  every letter (`letterContrasts`) and the previous sheet's figure
  (`againstBoxMedian`) are kept in `measurements.json`.
- The screenshots are read as PNG. The harness's JPEG rings right next to a
  white stroke, which is exactly where this ground is.
"""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

SCALE = 3                       # the Air's screenshots are 3x points
RING = (1, 2 * SCALE)           # ground: more than 1 px, at most 2 pt from a letter
OPTIONS = [
    ("none", "None (build 9)"),
    ("A", "A: 50% at 2 pt"),
    ("B", "B: 75% at 2.5 pt, twice"),
    ("C", "C: 100% at 1 pt + 85% at 3.5 pt"),
]
MOMENTS = [
    ("oct-0700", "15 Oct, 07:00", "en-L-light"),
    ("oct-0730", "15 Oct, 07:30", "en-L-light"),
    ("jun-0700", "15 June, 07:00", "en-L-light"),
    ("jun-1200", "15 June, 12:00", "en-L-light"),
    ("jun-0700-ax5", "15 June, 07:00, AX5", "en-AX5-light"),
    ("oct-1200", "15 Oct, 12:00 (reference)", "en-L-light"),
    ("oct-1700", "15 Oct, 17:00 (reference)", "en-L-light"),
]


def lum(rgb):
    c = rgb / 255.0
    c = np.where(c <= 0.03928, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    return 0.2126 * c[..., 0] + 0.7152 * c[..., 1] + 0.0722 * c[..., 2]


def ratio(a, b):
    hi, lo = max(a, b), min(a, b)
    return (hi + 0.05) / (lo + 0.05)


def count_line(folder):
    els = json.load(open(folder / "garden.json"))["elements"]
    return [e for e in els if e.get("type") == "text" and "grown from meetings" in e.get("label", "")][0]


def window(e, margin):
    """The line's box grown by `margin` pixels, in pixels."""
    return (int(e["x"] * SCALE) - margin, int(e["y"] * SCALE) - margin,
            int((e["x"] + e["w"]) * SCALE) + margin, int((e["y"] + e["h"]) * SCALE) + margin)


def letters(img, e):
    """The letters' pixels in the window, from a render without a shadow."""
    x0, y0, x1, y1 = window(e, RING[1])
    L = lum(np.asarray(img.crop((x0, y0, x1, y1)), dtype=np.float64))
    # The sky behind: what is left when anything as thin as a stroke is taken out.
    sky = ndimage.median_filter(L, size=25)
    cover = (L - sky) / np.maximum(1 - sky, 1e-6)
    return cover > 0.06


def measure(img, e, mask):
    x0, y0, x1, y1 = window(e, RING[1])
    L = lum(np.asarray(img.crop((x0, y0, x1, y1)), dtype=np.float64))
    m = RING[1]
    inner = L[m:-m, m:-m].ravel()
    n = max(1, int(0.04 * inner.size))
    text = float(np.sort(inner)[-n:].mean())
    dist, (iy, ix) = ndimage.distance_transform_edt(~mask, return_indices=True)
    ring = (dist > RING[0]) & (dist <= RING[1])
    ground = L[ring]
    # Letter by letter: each pixel of the ground belongs to the letter nearest
    # it. The sky behind the line is not even (the sun's halo lies behind its
    # first half in the morning), so a letter in the halo can be well under
    # the line's median.
    letters_, count = ndimage.label(mask, structure=np.ones((3, 3)))
    owner = letters_[iy, ix]
    per = []
    for k in range(1, count + 1):
        sel = ring & (owner == k)
        if (letters_ == k).sum() < 40 or sel.sum() < 40:   # a stray pixel, not a letter
            continue
        per.append(ratio(text, float(np.median(L[sel]))))
    return {
        "text": round(text, 4),
        "groundMedian": round(float(np.median(ground)), 4),
        "contrast": round(min(per), 2),
        "letters": len(per),
        "letterMedian": round(float(np.median(per)), 2),
        "letterContrasts": [round(p, 2) for p in per],
        "lineMedian": round(ratio(text, float(np.median(ground))), 2),
        "againstBoxMedian": round(ratio(text, float(np.median(inner))), 2),
    }


def font(size, bold=False):
    try:
        return ImageFont.truetype("/System/Library/Fonts/HelveticaNeue.ttc", size, index=1 if bold else 0)
    except OSError:
        return ImageFont.load_default()


def save(sheet, path):
    sheet.quantize(colors=256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).save(path, optimize=True)


def main():
    renders, out = Path(sys.argv[1]), Path(sys.argv[2])
    results, cells = {}, {}
    for tag, title, config in MOMENTS:
        base = renders / f"{tag}-none" / config
        if not (base / "garden.png").exists():
            continue
        e = count_line(base)
        mask = letters(Image.open(base / "garden.png").convert("RGB"), e)
        for key, _ in OPTIONS:
            folder = renders / f"{tag}-{key}" / config
            img = Image.open(folder / "garden.png").convert("RGB")
            assert count_line(folder)["y"] == e["y"], f"{tag}-{key}: the line moved"
            r = measure(img, e, mask)
            r["frame"] = [e["x"], e["y"], e["w"], e["h"]]
            results[f"{tag}/{key}"] = r
            # The crop: the line and some sky round it, at the screenshot's own pixels.
            top = e["y"] - 9
            cells[(tag, key)] = img.crop((int(20 * SCALE), int(top * SCALE),
                                          int(max(250, e["x"] + e["w"] + 14) * SCALE),
                                          int((e["y"] + e["h"] + 9) * SCALE)))

    rows = [m for m in MOMENTS if (m[0], "none") in cells]
    pad, label_w, head_h, note_h = 20, 300, 56, 34
    col_w = max(c.width for c in cells.values())
    width = label_w + len(OPTIONS) * (col_w + pad) + pad
    foot = [
        "iPhone Air, English, the garden byTheClock with the developer clock wound to the moment (London, the garden's own season).",
        "Shown at the screenshot's own pixels (3 px a point). The number: the lowest of the line's 19 letters, each the line's strokes (its most",
        "inked 4% of pixels) against the median of the pixels immediately round that letter (1 px to 2 pt away), with the shadow. Green: 4.5 : 1 and over.",
        "AX5: the label voice stops growing at AX3, so the line is drawn at AX3 there.",
    ]
    height = 80 + head_h + sum(cells[(t, "none")].height + note_h + pad for t, _, _ in rows) + 28 * len(foot) + 30
    sheet = Image.new("RGB", (width, height), (232, 230, 226))
    d = ImageDraw.Draw(sheet)
    d.text((pad, 22), "31A: a soft dark shadow under the garden's count line by day", fill=(20, 20, 20), font=font(30, True))
    y = 80
    for i, (_, name) in enumerate(OPTIONS):
        d.text((label_w + pad + i * (col_w + pad), y + 14), name, fill=(20, 20, 20), font=font(24, True))
    y += head_h
    for tag, title, _ in rows:
        h = cells[(tag, "none")].height
        d.text((pad, y + h // 2 - 14), title, fill=(30, 30, 30), font=font(23))
        for i, (key, _) in enumerate(OPTIONS):
            x0 = label_w + pad + i * (col_w + pad)
            sheet.paste(cells[(tag, key)], (x0, y))
            r = results[f"{tag}/{key}"]
            d.text((x0, y + h + 4), f"{r['contrast']:.2f} : 1",
                   fill=(30, 110, 50) if r["contrast"] >= 4.5 else (170, 30, 30), font=font(24, True))
        y += h + note_h + pad
    for k, line in enumerate(foot):
        d.text((pad, y + 6 + 28 * k), line, fill=(40, 40, 40), font=font(20))
    save(sheet, out / "shadow-ABC.png")

    # By night the line is `muted` and has no shadow, whatever is asked for:
    # midnight with none and with B, measured on the same letters.
    night = renders / "night-none" / "en-L-dark"
    if (night / "garden.png").exists():
        e = count_line(night)
        img = Image.open(night / "garden.png").convert("RGB")
        mask = letters(img, e)
        for key in ["none", "B"]:
            other = Image.open(renders / f"night-{key}" / "en-L-dark" / "garden.png").convert("RGB")
            r = measure(other, e, mask)
            x0, y0, x1, y1 = window(e, RING[1])
            a = np.asarray(img.crop((x0, y0, x1, y1)), dtype=np.int16)
            b = np.asarray(other.crop((x0, y0, x1, y1)), dtype=np.int16)
            r["meanDifferenceFromNone"] = round(float(np.abs(a - b).mean()), 3)
            results[f"night/{key}"] = r
    json.dump(results, open(out / "measurements.json", "w"), indent=1)

    print("moment".ljust(16) + "".join(k.rjust(16) for k, _ in OPTIONS))
    for tag, _, _ in rows:
        print(tag.ljust(16) + "".join(
            f"{results[f'{tag}/{k}']['contrast']:>7.2f} ({results[f'{tag}/{k}']['lineMedian']:.2f})".rjust(16)
            for k, _ in OPTIONS))
    for k, v in results.items():
        if k.startswith("night/"):
            print(k, v["contrast"], v["lineMedian"], "mean difference from none", v["meanDifferenceFromNone"])


if __name__ == "__main__":
    main()
