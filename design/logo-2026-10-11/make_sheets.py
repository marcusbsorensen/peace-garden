#!/usr/bin/env python3
"""
Renders round two's sheets:

  suite-row.png            the four candidates beside the five suite apps' real
                           icons, at 180 and 60 px, on the iOS home screen's dark
                           and light grounds, with today's Peace Garden icon
  hue-map.png              the suite apps' hue bands, measured from their icons,
                           with Peace Garden's current lime and the new ramp
  <candidate>/sheet.png    the contact sheet, as round one's
  <candidate>/in-context.png  beside the app's renders and the suite's icons

  python3 design/logo-2026-10-11/make_sheets.py

Round one's renderer is reused (`render`, the iOS mask, `save` with its
450 KB ceiling, today's masthead). Run `make_logos.py` and `measure.py` first.

  pip install cairosvg pillow numpy scipy
"""

import importlib.util
import io
import json
import sys
from pathlib import Path

import cairosvg
from PIL import Image, ImageDraw

import make_logos as ML
from colour import de2000, hsl

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
CURRENT = ROOT / "Server/assets/icon.svg"
ICONS = HERE / "suite-icons"

# Round one's sheet module imports a module called `make_logos`, which is
# also this round's name; hand it round one's for the length of the import.
_ours = sys.modules["make_logos"]
sys.modules["make_logos"] = ML.round_one
_spec = importlib.util.spec_from_file_location(
    "round_one_sheets", HERE.parent / "logo-2026-10-10" / "make_sheets.py")
R1 = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(R1)
sys.modules["make_logos"] = _ours

render, icon, squircle_mask, save, label, font = (R1.render, R1.icon, R1.squircle_mask,
                                                   R1.save, R1.label, R1.font)
SHEET_BG = R1.SHEET_BG
GROUND, LIGHT_GROUND = ML.GROUND, ML.LIGHT_GROUND

# iOS home-screen grounds, without a wallpaper: the system's grouped
# backgrounds, dark and light.
HOME_DARK = "#1C1C1E"
HOME_LIGHT = "#F2F2F7"

SUITE = [
    ("Pfish", "pfish-1024.png"),
    ("UnCubed", "uncubed-1024.png"),
    ("Animal Rescue Centre", "animal-rescue-centre-1024.png"),
    ("FlagFans", "flagfans-1024.png"),
    ("FreqShift", "freqshift-162.png"),
]
CANDS = [c[0] for c in ML.CANDIDATES]
NAMES = {"d-suite": "D-suite", "d-light": "D-light", "e-suite": "E-suite", "e-light": "E-light"}


def raster_icon(path, size):
    """A suite app's real icon at `size`, under the iOS mask. FreqShift's only
    artefact is a 162 px web logo drawn as its own tile, so it is cropped to
    that tile first; at 180 it is upscaled, and looks it."""
    im = Image.open(path).convert("RGB")
    a = im.load()
    page = a[1, 1]
    if im.width < 1024:  # the web logo; every app icon set holds a full 1024
        px = [(x, y) for y in range(im.height) for x in range(im.width)
              if sum(abs(p - q) for p, q in zip(a[x, y], page)) > 25]
        xs, ys = [p[0] for p in px], [p[1] for p in px]
        im = im.crop((min(xs), min(ys), max(xs) + 1, max(ys) + 1))
    im = im.resize((size, size), Image.LANCZOS).convert("RGBA")
    im.putalpha(squircle_mask(size))
    return im


def any_icon(kind, ref, size):
    if kind == "svg":
        return icon(ref, size)
    return raster_icon(ref, size)


def columns():
    cols = [("Peace Garden today", "svg", CURRENT)]
    cols += [(NAMES[c], "svg", HERE / c / "icon-1024.svg") for c in CANDS]
    cols += [(n, "png", ICONS / f) for n, f in SUITE]
    return cols


def suite_row():
    cols = columns()
    cw = 214
    W = 40 + cw * len(cols) + 20
    H = 120 + 2 * 420
    sheet = Image.new("RGBA", (W, H), SHEET_BG)
    dr = ImageDraw.Draw(sheet)
    label(dr, (40, 24), "Peace Garden round two beside the suite: today's icon, the four candidates, "
                        "then the five suite apps' real icons", 30)
    label(dr, (40, 66), "180 px and 60 px, on the iOS home screen's dark (#1C1C1E) and light (#F2F2F7) "
                        "grounds. FreqShift's only icon in its repository is a 162 px web logo, upscaled here.", 17)
    for band, (bg, ink) in enumerate(((HOME_DARK, (235, 235, 240)), (HOME_LIGHT, (40, 40, 45)))):
        y0 = 110 + band * 420
        sheet.alpha_composite(Image.new("RGBA", (W - 60, 400), bg), (30, y0))
        d = ImageDraw.Draw(sheet)
        for i, (name, kind, ref) in enumerate(cols):
            x = 40 + i * cw + (cw - 180) // 2
            if i == 5:  # a hairline between Peace Garden and the suite
                d.line((40 + i * cw - 4, y0 + 20, 40 + i * cw - 4, y0 + 380), fill=(128, 128, 136), width=1)
            sheet.alpha_composite(any_icon(kind, ref, 180), (x, y0 + 24))
            d.text((x + 90, y0 + 214), name, fill=ink, font=font(17), anchor="ma")
            sheet.alpha_composite(any_icon(kind, ref, 60), (x + 60, y0 + 262))
            short = {"Peace Garden today": "Today", "Animal Rescue Centre": "A.R.C."}.get(name, name)
            d.text((x + 90, y0 + 330), short, fill=ink,
                   font=font(12), anchor="ma")
    return save(sheet, HERE / "suite-row.png")


# ------------------------------------------------------------------ hue map

def hue_map():
    m = json.loads((HERE / "measurements.json").read_text())
    # (name, measured key or None, source stops, span recorded in suite-brand.md)
    rows = [
        ("Peace Garden, new ramp", None, ML.ramp(), None),
        ("Peace Garden, today", "peace-garden-today", ["#06F556", "#55F306", "#DCDC06"], (60, 140)),
        ("Pfish", "pfish", ["#11CD6F", "#10CAA8", "#12C4DF"], (150, 188)),
        ("FreqShift", "freqshift", [], (190, 268)),
        ("UnCubed", "uncubed", ["#98B1F7", "#C2A4F8", "#F68BF6"], (224, 300)),
        ("Animal Rescue Centre", "arc", ["#C90021", "#FF5343", "#FCC190"], None),
        ("FlagFans", "flagfans", ["#B98A62", "#D4A458", "#F0C24E"], (28, 45)),
    ]
    W, H = 2240, 1180
    left, right = 360, W - 60
    lo, hi = -40.0, 320.0   # so ARC's 350° → 28° reads as one band, on the left

    def X(h):
        h = h if h <= hi else h - 360
        h = h if h >= lo else h + 360
        return left + (h - lo) / (hi - lo) * (right - left)

    sheet = Image.new("RGBA", (W, H), GROUND)
    dr = ImageDraw.Draw(sheet)
    ink, muted = (226, 226, 232), (150, 150, 160)
    dr.text((40, 26), "The suite's hue bands, measured from the real icons, with Peace Garden's lime "
                      "and the new sage-to-green-gold ramp", fill=ink, font=font(30))
    dr.text((40, 70), "HSL hue. Bar: measured from the icon's own pixels (5th–95th percentile of the gradient's ink). "
                      "Dots: the gradient's stops, from source. Outline: the span suite-brand.md records.",
            fill=muted, font=font(17))
    # The reference strip, at the suite's own kind of chroma.
    import colorsys
    sy = 120
    for x in range(left, right):
        h = (lo + (x - left) / (right - left) * (hi - lo)) % 360
        r, g, b = colorsys.hls_to_rgb(h / 360, 0.62, 0.75)
        dr.line((x, sy, x, sy + 26), fill=(round(r * 255), round(g * 255), round(b * 255)))
    for t in range(-30, 330, 30):
        x = X(t % 360)
        dr.line((x, sy + 30, x, sy + 38), fill=muted)
        dr.text((x, sy + 42), f"{t % 360}°", fill=muted, font=font(14), anchor="ma")
    for t in range(-30, 330, 30):
        x = X(t % 360)
        dr.line((x, sy + 70, x, sy + 70 + 7 * 118), fill=(40, 40, 60))

    def grad_bar(x0, x1, y, h, stops):
        x0, x1 = sorted((x0, x1))
        if not stops:
            dr.rectangle((x0, y, x1, y + h), fill=(150, 160, 230))
            return
        cs = sorted(stops, key=lambda c: X(hsl(c)[0]))
        pts = [(X(hsl(c)[0]), ML.round_one._rgb(c)) for c in cs]
        for x in range(round(x0), round(x1) + 1):
            if x <= pts[0][0]:
                c = pts[0][1]
            elif x >= pts[-1][0]:
                c = pts[-1][1]
            else:
                for (xa, ca), (xb, cb) in zip(pts, pts[1:]):
                    if xa <= x <= xb:
                        t = (x - xa) / max(1e-6, xb - xa)
                        c = tuple(a + (b - a) * t for a, b in zip(ca, cb))
                        break
            dr.line((x, y, x, y + h), fill=tuple(round(v * 255) for v in c))

    for i, (name, key, stops, recorded) in enumerate(rows):
        y = sy + 92 + i * 118
        dr.text((40, y + 6), name, fill=ink, font=font(20))
        if key:
            mm = m[key]
            dr.text((40, y + 34), f"measured {mm['hue_lo']:.0f}°–{mm['hue_hi']:.0f}°", fill=muted, font=font(15))
            grad_bar(X(mm["hue_lo"]), X(mm["hue_hi"]), y + 14, 22, stops)
        else:
            hs = [hsl(c)[0] for c in stops]
            dr.text((40, y + 34), f"stops {max(hs):.0f}° → {min(hs):.0f}°, 9.7:1", fill=muted, font=font(15))
            grad_bar(X(min(hs)), X(max(hs)), y + 14, 22, stops)
        if recorded:
            dr.rectangle((X(recorded[0]), y + 6, X(recorded[1]), y + 44), outline=(200, 200, 210), width=2)
        last, drop = -1e9, 0
        for c in sorted(stops, key=lambda c: X(hsl(c)[0])):
            x = X(hsl(c)[0])
            dr.ellipse((x - 9, y + 58, x + 9, y + 76), fill=c, outline=(13, 13, 31), width=2)
            drop = 16 if x - last < 70 and not drop else 0   # stagger labels that would touch
            dr.text((x, y + 80 + drop), c, fill=muted, font=font(13), anchor="ma")
            last = x

    # The two distances that matter, said in numbers.
    new = ML.ramp()
    pf = ["#11CD6F", "#10CAA8", "#12C4DF"]
    ff = ["#B98A62", "#D4A458", "#F0C24E"]
    old_straw = "#BBBB6E"
    y = sy + 92 + len(rows) * 118 + 4
    dr.text((40, y), (f"Nearest neighbours, CIEDE2000: new sage {new[0]} to Pfish's nearest stop "
                      f"ΔE {min(de2000(new[0], p) for p in pf):.1f}; new green-gold {new[2]} to FlagFans' nearest "
                      f"ΔE {min(de2000(new[2], f) for f in ff):.1f}. Round one's straw {old_straw} was "
                      f"ΔE {min(de2000(old_straw, f) for f in ff):.1f} from FlagFans, so the ramp now ends at 76°, not 60°."),
            fill=ink, font=font(17))
    dr.text((40, y + 30), "Animal Rescue Centre has no row in suite-brand.md §3.4; its span (355° → 25°) is "
                          "recorded only in its own SVG. FreqShift has no source stops in its repository.",
            fill=muted, font=font(15))
    return save(sheet, HERE / "hue-map.png")


# --------------------------------------------------------- per candidate

def contact_sheet(folder):
    d = HERE / folder
    W, H = 2240, 1640
    sheet = Image.new("RGBA", (W, H), SHEET_BG)
    dr = ImageDraw.Draw(sheet)
    title = dict((c[0], c[1]) for c in ML.CANDIDATES)[folder]
    label(dr, (40, 24), f"Peace Garden logo, round two, {NAMES[folder]}: {title}", 30)
    label(dr, (40, 64), "App icon at 1024, under the iOS mask")
    sheet.alpha_composite(icon(d / "icon-1024.svg", 1024), (40, 96))

    x0 = 1110
    sizes = (180, 120, 60, 29)
    for row, (name, path) in enumerate((("New", d / "icon-1024.svg"), ("Today's", CURRENT))):
        y = 96 + row * 270
        label(dr, (x0, y), f"{name} icon at 180, 120, 60 and 29 px")
        x = x0
        for s in sizes:
            sheet.alpha_composite(icon(path, s), (x, y + 32 + (180 - s)))
            x += s + 36

    y = 650
    label(dr, (x0, y), "Favicon at 32 and 16 px, each also shown ×4 · new, then today's")
    x = x0
    for path in (d / f"{folder}-favicon.svg", CURRENT):
        for s in (32, 16):
            im = render(path, s)
            if path == CURRENT:
                im.putalpha(squircle_mask(s))
            sheet.alpha_composite(im, (x, y + 40))
            sheet.alpha_composite(im.resize((s * 4, s * 4), Image.NEAREST), (x, y + 84))
            x += s * 4 + 30
        x += 40

    y = 900
    label(dr, (x0, y), "Small drawing at 32 and 16, the website mark, and one colour, on dark and light")
    x = x0
    for name, bg, s in ((f"{folder}-small.svg", GROUND, 32), (f"{folder}-small-light-ground.svg", LIGHT_GROUND, 32),
                        (f"{folder}-small.svg", GROUND, 16), (f"{folder}-small-light-ground.svg", LIGHT_GROUND, 16),
                        (f"{folder}.svg", GROUND, 120), (f"{folder}-light-ground.svg", LIGHT_GROUND, 120),
                        (f"{folder}-one-colour.svg", LIGHT_GROUND, 120)):
        sheet.alpha_composite(render(d / name, s, bg=bg), (x, y + 40 + (120 - s)))
        x += s + 24

    y = 1150
    label(dr, (40, y), "Wordmark lockup, the bare mark beside the wordmark, on dark and on light · today's masthead beneath")
    sheet.alpha_composite(render(d / f"{folder}-lockup.svg", 840, 200), (40, y + 36))
    sheet.alpha_composite(render(d / f"{folder}-lockup-light-ground.svg", 840, 200), (900, y + 36))
    sheet.alpha_composite(R1.current_lockup("#FFFFFF", GROUND, 840, 200).resize((420, 100)), (40, y + 260))
    sheet.alpha_composite(R1.current_lockup("#121212", LIGHT_GROUND, 840, 200).resize((420, 100)), (900, y + 260))
    label(dr, (1780, y + 40), "The site's wordmark as\nset today (system sans,\n400, tracked 0.18 em).\n"
                              "Inter stands in here.", 18)
    return save(sheet, d / "sheet.png")


def in_context(folder):
    d = HERE / folder
    W, H = 2240, 1440
    sheet = Image.new("RGBA", (W, H), SHEET_BG)
    dr = ImageDraw.Draw(sheet)
    label(dr, (40, 24), f"{NAMES[folder]} beside the app as it is drawn, and beside the suite's icons", 30)
    renders = [
        ("Plant screen", ROOT / "design/plant-screen-2026-10-02/01-air-tall-upright.png", (434, 130, 868, 1000)),
        ("Garden at dusk", ROOT / "design/app-sky-2026-10-02/a-17.png", None),
        ("Garden by day", ROOT / "design/app-light-2026-10-02/after-summer-12.png", None),
    ]
    x, y, h = 40, 80, 720
    sheet.alpha_composite(icon(d / "icon-1024.svg", 360), (x, y + 40))
    label(dr, (x, y + 410), "New icon, 360")
    sheet.alpha_composite(icon(CURRENT, 180), (x + 90, y + 470))
    label(dr, (x + 90, y + 660), "Today's, 180")
    x += 400
    for name, path, crop in renders:
        im = Image.open(path).convert("RGBA")
        if crop:
            im = im.crop(crop)
        im = R1.fit_h(im, h)
        if x + im.width > W - 40:
            im = im.crop((0, 0, W - 40 - x, h))
        sheet.alpha_composite(im, (x, y))
        sheet.alpha_composite(icon(d / "icon-1024.svg", 120), (x + 16, y + h - 136))
        label(dr, (x, y + h + 8), name)
        x += im.width + 24

    y = 880
    label(dr, (40, y), "In a row with the suite at 150 px, on the iOS home screen's dark and light grounds")
    row = [(NAMES[folder], "svg", d / "icon-1024.svg")] + [(n, "png", ICONS / f) for n, f in SUITE] + \
          [("Peace Garden today", "svg", CURRENT)]
    for band, bg in enumerate((HOME_DARK, HOME_LIGHT)):
        sheet.alpha_composite(Image.new("RGBA", (W - 80, 210), bg), (40, y + 36 + band * 230))
        xx = 90
        for name, kind, ref in row:
            sheet.alpha_composite(any_icon(kind, ref, 150), (xx, y + 66 + band * 230))
            xx += 300
    xx = 90
    for name, *_ in row:
        label(dr, (xx, y + 500), name, 16)
        xx += 300
    return save(sheet, d / "in-context.png")


def main():
    print("suite-row", suite_row())
    print("hue-map", hue_map())
    for c in CANDS:
        print(c, contact_sheet(c), in_context(c))


if __name__ == "__main__":
    main()
