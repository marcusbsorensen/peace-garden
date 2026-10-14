"""29B and 30A, before and after: the thin small capitals in four places, and
the garden's count line by day at several hours and seasons and by night.

    python3 design/small-caps-2026-10-14/compose.py <renders> <out folder>

`<renders>` holds one folder per sweep of the mass test's screen harness
(`tools/masstest/app/run_tests.sh screens`) on an iPhone Air: `before/` and
`after/` with en-L-dark and en-L-light (stage, seed, garden, plant), and one
garden-only sweep for each hour of the day, named `<oct|jun|dec>-<hhmm>`
(`-t<n>` with the plot turned n quarters, which moves the sun on the screen;
`-ax` at AX3, the garden's words stopping at AX1). See README.md.

Measured as 26A was (`design/app-polish-2026-10-14/small-caps-AB.png`): off
the screenshot, against the median of the text's own box. Strokes: the mean of
its most inked 4% of pixels. Peak: its brightest (on dark) or darkest (on
light) half-percent. The count line is also worked out by arithmetic over the
sky behind it (the box's median colour): white, and `muted` (white at 0.72),
which is what it was before.
"""
import json, sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont

SCALE = 3          # the Air's screenshots are 3x points
SHOW = 2.0         # shown at 2 px a point
SEED_LABELS = {"Seed", "Created", "Petals", "Leaves", "Opens", "First bloom"}
MUTED = 0.72       # Chrome.muted under Dark: white at this alpha

# title, screen, which texts, crop in points (x, y, w, h)
PLACES = [
    ("A plant's place and date", "plant", lambda l: l == "the long field" or " at " in l and any(c.isdigit() for c in l),
     (80, 690, 260, 80)),
    ("The stage caption", "stage", lambda l: l == "Mature", (90, 736, 240, 56)),
    ("The seed screen's labels", "seed", lambda l: l in SEED_LABELS or l == "Plume", (30, 546, 360, 314)),
    ("The garden's count line", "garden", lambda l: "grown from meetings" in l, (20, 104, 250, 60)),
]

HOURS = [
    ("oct-0615", "15 Oct, 06:15"), ("oct-0700", "15 Oct, 07:00"), ("oct-0730", "15 Oct, 07:30"),
    ("oct-0800", "15 Oct, 08:00"), ("oct-0900", "15 Oct, 09:00"),
    ("after", "14 Oct, 12:00 (Always day)"), ("oct-1500", "15 Oct, 15:00"),
    ("oct-1700", "15 Oct, 17:00"), ("oct-1745", "15 Oct, 17:45"),
    ("oct-1700-t2", "15 Oct, 17:00, turned twice"), ("oct-1745-t2", "15 Oct, 17:45, turned twice"),
    ("dec-1200", "15 Dec, 12:00"),
    ("jun-0615", "15 June, 06:15"), ("jun-0700", "15 June, 07:00"), ("jun-0730", "15 June, 07:30"),
    ("jun-0800", "15 June, 08:00"), ("jun-0900", "15 June, 09:00"),
    ("jun-1200", "15 June, 12:00"), ("jun-1500", "15 June, 15:00"), ("jun-1700", "15 June, 17:00"),
    ("jun-1200-t1", "15 June, 12:00, turned once"), ("jun-1200-t2", "15 June, 12:00, turned twice"),
    ("jun-1200-t3", "15 June, 12:00, turned 3 times"),
    ("jun-1200-ax", "15 June, 12:00, AX3"),
]


def lum(rgb):
    c = rgb / 255.0
    c = np.where(c <= 0.03928, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    return 0.2126 * c[..., 0] + 0.7152 * c[..., 1] + 0.0722 * c[..., 2]


def ratio(a, b):
    hi, lo = max(a, b), min(a, b)
    return (hi + 0.05) / (lo + 0.05)


def box_of(img, e):
    return img.crop((int(e["x"] * SCALE), int(e["y"] * SCALE),
                     int((e["x"] + e["w"]) * SCALE), int((e["y"] + e["h"]) * SCALE)))


def measure(img, e, dark):
    px = np.asarray(box_of(img, e).convert("RGB"), dtype=np.float64)
    L = lum(px).ravel()
    bg = float(np.median(L))
    stroke = float(np.percentile(L, 99.5 if dark else 0.5))
    ordered = np.sort(L)
    n = max(1, int(0.04 * L.size))
    mean = float(ordered[-n:].mean() if dark else ordered[:n].mean())
    return ratio(stroke, bg), ratio(mean, bg)


def over_sky(img, e):
    """White, and white at `MUTED`, laid over the median colour of the box."""
    px = np.asarray(box_of(img, e).convert("RGB"), dtype=np.float64).reshape(-1, 3)
    sky = np.median(px, axis=0)
    under = float(lum(sky))
    muted = MUTED * 255 + (1 - MUTED) * sky
    return ratio(1.0, under), ratio(float(lum(muted)), under), [int(v) for v in sky]


def elements(folder, screen):
    return json.load(open(folder / f"{screen}.json"))["elements"]


def texts(folder, screen, wanted):
    return [e for e in elements(folder, screen) if e.get("type") == "text" and wanted(e.get("label", ""))]


def audit_hits(folder, screen, els):
    path = folder / f"{screen}-audit.json"
    if not path.exists():
        return None
    issues = [i for i in json.load(open(path)) if i.get("type") == "contrast" and "frame" in i]

    def overlaps(e, f):
        fx, fy, fw, fh = f
        return not (fx + fw <= e["x"] or e["x"] + e["w"] <= fx or fy + fh <= e["y"] or e["y"] + e["h"] <= fy)
    return [f'{i.get("label")}: {i["description"]}' for i in issues if any(overlaps(e, i["frame"]) for e in els)]


def font(size, bold=False):
    try:
        return ImageFont.truetype("/System/Library/Fonts/HelveticaNeue.ttc", size, index=1 if bold else 0)
    except OSError:
        return ImageFont.load_default()


def crop_points(img, x, y, w, h):
    c = img.crop((int(x * SCALE), int(y * SCALE), int((x + w) * SCALE), int((y + h) * SCALE)))
    return c.resize((int(w * SHOW), int(h * SHOW)), Image.LANCZOS)


def save(sheet, path):
    sheet.quantize(colors=256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).save(path, optimize=True)


def places_sheet(renders, out, results):
    keys, names = ["before", "after"], ["Before", "After (29B, 30A)"]
    crops = {}
    for appearance in ["dark", "light"]:
        for title, screen, wanted, crop in PLACES:
            for key in keys:
                folder = renders / key / f"en-L-{appearance}"
                els = texts(folder, screen, wanted)
                img = Image.open(folder / f"{screen}.jpg").convert("RGB")
                # The garden's chrome is drawn as in Dark whatever the appearance.
                ms = [measure(img, e, appearance == "dark" or screen == "garden") for e in els]
                hits = audit_hits(folder, screen, els)
                results[f"{appearance}/{screen}/{key}"] = {
                    "elements": [e["label"] for e in els],
                    "peak": [round(m[0], 2) for m in ms],
                    "strokes": [round(m[1], 2) for m in ms],
                    "lowestPeak": round(min(m[0] for m in ms), 2) if ms else None,
                    "lowestStrokes": round(min(m[1] for m in ms), 2) if ms else None,
                    "auditContrast": hits,
                }
                crops[(appearance, screen, key)] = crop_points(img, *crop)

    pad, label_w, head_h, note_h = 16, 260, 44, 30
    col_w = max(int(p[3][2] * SHOW) for p in PLACES)
    width = label_w + 2 * (col_w + pad) + pad
    rows_h = sum(int(p[3][3] * SHOW) + note_h + pad for p in PLACES)
    foot = [
        "Measured off the screenshot against the median of each text's own box. Strokes: the mean of its",
        "most inked 4% of pixels; peak: its brightest (on dark) or darkest (on light) half-percent. The lowest",
        "of the place's texts. Audit: performAccessibilityAudit's contrast issues on those texts, one run.",
        "The garden is drawn as in Dark in both appearances: Light shows it by day (noon), Dark by night.",
    ]
    height = 2 * (head_h + rows_h) + 70 + 26 * len(foot) + 30
    sheet = Image.new("RGB", (width, height), (232, 230, 226))
    d = ImageDraw.Draw(sheet)
    d.text((pad, 18), "29B and 30A: iPhone Air, English, Large — before and after", fill=(20, 20, 20), font=font(26, True))
    y = 70
    for appearance in ["dark", "light"]:
        d.text((pad, y + 8), appearance.capitalize(), fill=(20, 20, 20), font=font(24, True))
        for i, n in enumerate(names):
            d.text((label_w + pad + i * (col_w + pad), y + 10), n, fill=(20, 20, 20), font=font(22, True))
        y += head_h
        for title, screen, _, crop in PLACES:
            h = int(crop[3] * SHOW)
            label = title + ((" (night)" if appearance == "dark" else " (day)") if screen == "garden" else "")
            d.text((pad, y + 6), label, fill=(30, 30, 30), font=font(19))
            for i, key in enumerate(keys):
                x0 = label_w + pad + i * (col_w + pad)
                sheet.paste(crops[(appearance, screen, key)], (x0, y))
                r = results[f"{appearance}/{screen}/{key}"]
                hits = r["auditContrast"]
                note = f"strokes {r['lowestStrokes']}:1, peak {r['lowestPeak']}:1   audit {len(hits) if hits is not None else '-'}"
                d.text((x0, y + h + 4), note, fill=(160, 30, 30) if r["lowestStrokes"] < 4.5 else (30, 90, 40),
                       font=font(19))
            y += h + note_h + pad
    for k, line in enumerate(foot):
        d.text((pad, y + 10 + 26 * k), line, fill=(40, 40, 40), font=font(18))
    save(sheet, out / "small-caps-before-after.png")


def count_sheet(renders, out, results):
    rows = []
    wanted = PLACES[3][2]
    for tag, title in HOURS + [("before-night", "Midnight (Always night), before"), ("after-night", "Midnight (Always night), after")]:
        if tag.endswith("-night"):
            folder = renders / tag.split("-")[0] / "en-L-dark"
        else:
            name = "en-AX3-light" if tag.endswith("-ax") else "en-L-light"
            folder = renders / tag / name
        if not (folder / "garden.json").exists():
            continue
        els = texts(folder, "garden", wanted)
        heads = [e for e in elements(folder, "garden") if e.get("type") == "text" and e.get("label") == "Peace garden"]
        img = Image.open(folder / "garden.jpg").convert("RGB")
        e = els[0]
        peak, strokes = measure(img, e, True)
        white, muted, sky = over_sky(img, e)
        top = min([e["y"]] + [h["y"] for h in heads]) - 8
        right = max([e["x"] + e["w"]] + [h["x"] + h["w"] for h in heads]) + 8
        crop = crop_points(img, 20, top, max(260, right - 20), e["y"] + e["h"] + 8 - top)
        key = f"count/{tag}"
        results[key] = {"title": title, "frame": [e["x"], e["y"], e["w"], e["h"]],
                        "peak": round(peak, 2), "strokes": round(strokes, 2), "sky": sky,
                        "whiteOverSky": round(white, 2), "mutedOverSky": round(muted, 2)}
        rows.append((title, crop, results[key], tag.endswith("-night")))

    pad, label_w, note_w = 16, 330, 560
    col_w = max(c.width for _, c, _, _ in rows)
    width = label_w + col_w + note_w + 3 * pad
    height = 70 + sum(max(c.height, 52) + pad for _, c, _, _ in rows) + 4 * 26 + 30
    sheet = Image.new("RGB", (width, height), (232, 230, 226))
    d = ImageDraw.Draw(sheet)
    d.text((pad, 18), "30A: the garden's count line in white by day, iPhone Air, English", fill=(20, 20, 20), font=font(26, True))
    y = 70
    for title, crop, r, night in rows:
        d.text((pad, y + 6), title, fill=(30, 30, 30), font=font(19))
        sheet.paste(crop, (label_w + pad, y))
        x0 = label_w + col_w + 2 * pad
        drawn = "muted" if night else "white"
        d.text((x0, y + 2), f"{drawn} as drawn: strokes {r['strokes']}:1, peak {r['peak']}:1",
               fill=(160, 30, 30) if r["strokes"] < 4.5 else (30, 90, 40), font=font(19))
        d.text((x0, y + 26), f"over this sky: white {r['whiteOverSky']}:1, muted {r['mutedOverSky']}:1",
               fill=(60, 60, 60), font=font(17))
        y += max(crop.height, 52) + pad
    foot = [
        "The days are byTheClock with the developer clock wound to the hour, London, the garden's own season for the date.",
        "As drawn: off the screenshot, as on the other sheet. Over this sky: white, and white at 0.72 (muted, the line",
        "before 30A), laid by arithmetic over the median colour of the line's box; the night is muted before and after.",
    ]
    for k, line in enumerate(foot):
        d.text((pad, y + 10 + 26 * k), line, fill=(40, 40, 40), font=font(18))
    save(sheet, out / "count-line-by-hour.png")


def main():
    renders, out = Path(sys.argv[1]), Path(sys.argv[2])
    results = {}
    places_sheet(renders, out, results)
    count_sheet(renders, out, results)
    json.dump(results, open(out / "measurements.json", "w"), indent=1)
    for k, v in results.items():
        if k.startswith("count/"):
            print(k, v["strokes"], v["peak"], "white", v["whiteOverSky"], "muted", v["mutedOverSky"], v["sky"])
        else:
            print(k, v["lowestStrokes"], v["lowestPeak"], v["auditContrast"])


if __name__ == "__main__":
    main()
