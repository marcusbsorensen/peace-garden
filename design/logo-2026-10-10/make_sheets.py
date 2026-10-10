#!/usr/bin/env python3
"""
Renders the contact sheet (`sheet.png`) and the congruence sheet
(`in-context.png`) for each direction, and `overview.png` for all of them.

  python3 design/logo-2026-10-10/make_sheets.py

Rendered with cairosvg (pip install cairosvg pillow). The wordmark is set in
the system sans on Apple devices; here it falls back to Inter, the nearest
installed face. Every PNG is held under 450 KB.
"""

import io
from pathlib import Path

import cairosvg
from PIL import Image, ImageDraw, ImageFont

from make_logos import DIRECTIONS, GROUND, LIGHT_GROUND

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
HUB = ROOT.parent / "interfulgent-hub"
CURRENT = ROOT / "Server/assets/icon.svg"
LIMIT = 450 * 1024

SHEET_BG = "#26262C"
LABEL = (200, 200, 205)
FONT = "/usr/share/fonts/opentype/inter/Inter-Regular.otf"


def font(size):
    try:
        return ImageFont.truetype(FONT, size)
    except OSError:
        return ImageFont.load_default()


def render(path, w, h=None, bg=None):
    png = cairosvg.svg2png(url=str(path), output_width=w, output_height=h or w,
                           background_color=bg)
    return Image.open(io.BytesIO(png)).convert("RGBA")


def squircle_mask(size):
    """iOS's mask, near enough for judging: a rounded square, radius 22.37 %."""
    k = 4
    m = Image.new("L", (size * k, size * k), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, size * k - 1, size * k - 1),
                                        radius=size * k * 0.2237, fill=255)
    return m.resize((size, size), Image.LANCZOS)


def icon(path, size):
    im = render(path, size)
    im.putalpha(squircle_mask(size))
    return im


def label(draw, xy, text, size=18):
    draw.text(xy, text, fill=LABEL, font=font(size))


def save(im, path):
    im = im.convert("RGB")
    im.save(path, optimize=True)
    if path.stat().st_size > LIMIT:
        # Octree keeps the marks' few flat colours exact; the photographic
        # renders take the dither.
        im.quantize(colors=256, method=Image.Quantize.FASTOCTREE,
                    dither=Image.Dither.FLOYDSTEINBERG).save(path, optimize=True)
    if path.stat().st_size > LIMIT:
        raise SystemExit(f"{path} is {path.stat().st_size} bytes")
    return path.stat().st_size


def current_lockup(ink, ground, w=840, h=200):
    """Today's masthead: the icon on its tile beside the wordmark."""
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 420 100" width="420" height="100">'
           f'<rect width="420" height="100" fill="{ground}"/>'
           f'<clipPath id="c"><rect x="20" y="20" width="60" height="60" rx="13.2"/></clipPath>'
           f'<image href="{CURRENT.as_uri()}" x="20" y="20" width="60" height="60" clip-path="url(#c)"/>'
           f'<text x="96" y="59.5" font-family="Inter" font-size="30" letter-spacing="5.4" fill="{ink}">'
           f'Peace Garden</text></svg>')
    png = cairosvg.svg2png(bytestring=svg.encode(), output_width=w, output_height=h, unsafe=True)
    return Image.open(io.BytesIO(png)).convert("RGBA")


def contact_sheet(folder, title):
    d = HERE / folder
    W, H = 2240, 1640
    sheet = Image.new("RGBA", (W, H), SHEET_BG)
    dr = ImageDraw.Draw(sheet)
    label(dr, (40, 24), f"Peace Garden logo, direction {folder[0].upper()}: {title}", 30)
    label(dr, (40, 64), "App icon at 1024, under the iOS mask")
    sheet.alpha_composite(icon(d / "icon-1024.svg", 1024), (40, 96))

    x0 = 1110
    sizes = (180, 120, 60, 29)
    for row, (name, path) in enumerate((("New", d / "icon-1024.svg"), ("Current", CURRENT))):
        y = 96 + row * 270
        label(dr, (x0, y), f"{name} icon at 180, 120, 60 and 29 px")
        x = x0
        for s in sizes:
            sheet.alpha_composite(icon(path, s), (x, y + 32 + (180 - s)))
            x += s + 36

    y = 650
    label(dr, (x0, y), "Favicon at 32 and 16 px, each also shown ×4 · new, then current")
    x = x0
    for path in (d / f"{folder}-favicon.svg", CURRENT):
        for s in (32, 16):
            im = render(path, s)
            if path == CURRENT:
                im.putalpha(squircle_mask(s))
            sheet.alpha_composite(im, (x, y + 40))
            big = im.resize((s * 4, s * 4), Image.NEAREST)
            sheet.alpha_composite(big, (x, y + 84))
            x += s * 4 + 30
        x += 40

    y = 900
    label(dr, (x0, y), "Small drawing and one-colour version, light and dark grounds")
    x = x0
    for name, bg, s in ((f"{folder}-small.svg", GROUND, 32), (f"{folder}-small-light-ground.svg", LIGHT_GROUND, 32),
                        (f"{folder}-small.svg", GROUND, 16), (f"{folder}-small-light-ground.svg", LIGHT_GROUND, 16),
                        (f"{folder}.svg", GROUND, 120), (f"{folder}-light-ground.svg", LIGHT_GROUND, 120),
                        (f"{folder}-one-colour.svg", LIGHT_GROUND, 120)):
        im = render(d / name, s, bg=bg)
        sheet.alpha_composite(im, (x, y + 40 + (120 - s)))
        x += s + 24

    y = 1150
    label(dr, (40, y), "Wordmark lockup on dark and on light · today's masthead beneath, for comparison")
    sheet.alpha_composite(render(d / f"{folder}-lockup.svg", 840, 200), (40, y + 36))
    sheet.alpha_composite(render(d / f"{folder}-lockup-light-ground.svg", 840, 200), (900, y + 36))
    sheet.alpha_composite(current_lockup("#FFFFFF", GROUND, 840, 200).resize((420, 100)), (40, y + 260))
    sheet.alpha_composite(current_lockup("#121212", LIGHT_GROUND, 840, 200).resize((420, 100)), (900, y + 260))
    label(dr, (1780, y + 40), "Lockup: the mark without\na tile, then the site's\nwordmark as set today\n(system sans, 400,\ntracked 0.18 em).\nInter stands in here.", 18)
    return save(sheet, d / "sheet.png")


def fit_h(im, h):
    return im.resize((round(im.width * h / im.height), h), Image.LANCZOS)


def in_context(folder, title):
    d = HERE / folder
    W, H = 2240, 1400
    sheet = Image.new("RGBA", (W, H), SHEET_BG)
    dr = ImageDraw.Draw(sheet)
    label(dr, (40, 24), f"Direction {folder[0].upper()}: {title} — beside the app as it is drawn, and beside the suite", 30)

    renders = [
        ("Plant screen", ROOT / "design/plant-screen-2026-10-02/01-air-tall-upright.png", (434, 130, 868, 1000)),
        ("Garden at dusk", ROOT / "design/app-sky-2026-10-02/a-17.png", None),
        ("Garden by day", ROOT / "design/app-light-2026-10-02/after-summer-12.png", None),
    ]
    x, y, h = 40, 80, 720
    # The new icon first, large, as it would sit on the home screen.
    big = icon(d / "icon-1024.svg", 360)
    sheet.alpha_composite(big, (x, y + 40))
    label(dr, (x, y + 410), "New icon, 360")
    sheet.alpha_composite(icon(CURRENT, 180), (x + 90, y + 470))
    label(dr, (x + 90, y + 660), "Current, 180")
    x += 400
    for name, path, crop in renders:
        im = Image.open(path).convert("RGBA")
        if crop:
            im = im.crop(crop)
        im = fit_h(im, h)
        if x + im.width > W - 40:
            im = im.crop((0, 0, W - 40 - x, h))
        sheet.alpha_composite(im, (x, y))
        # The icon at home-screen size in the corner of each render.
        sheet.alpha_composite(icon(d / "icon-1024.svg", 120), (x + 16, y + h - 136))
        label(dr, (x, y + h + 8), name)
        x += im.width + 24

    y = 880
    label(dr, (40, y), "Beside the Interfulgent marks (interfulgent-hub/design/logo), on the suite ground #0D0D1F, and on light")
    hub = HUB / "design/logo"
    row = [
        ("Peace Garden, new", d / f"{folder}.svg", d / f"{folder}-light-ground.svg"),
        ("Peace Garden, current", CURRENT, CURRENT),
        ("Interfulgent A3 (chosen)", hub / "interfulgent-a-a3-burnt-orange-to-pale-yellow-warm.svg",
         hub / "interfulgent-a-a3-burnt-orange-to-pale-yellow-small-light-ground-warm.svg"),
        ("Interfulgent A1", hub / "interfulgent-a-a1-gold-to-yellow-warm.svg",
         hub / "interfulgent-a-a1-gold-to-yellow-small-light-ground-warm.svg"),
        ("Interfulgent B, lens", hub / "interfulgent-b-lens.svg", None),
        ("Interfulgent C, ring", hub / "interfulgent-c-diamond-ring.svg", None),
    ]
    band = Image.new("RGBA", (W - 80, 200), GROUND)
    light = Image.new("RGBA", (W - 80, 200), LIGHT_GROUND)
    sheet.alpha_composite(band, (40, y + 36))
    sheet.alpha_composite(light, (40, y + 256))
    x = 80
    for name, dark_path, light_path in row:
        if dark_path.exists():
            im = icon(dark_path, 150) if dark_path == CURRENT else render(dark_path, 150)
            sheet.alpha_composite(im, (x, y + 61))
        if light_path and light_path.exists():
            im = icon(light_path, 150) if light_path == CURRENT else render(light_path, 150)
            sheet.alpha_composite(im, (x, y + 281))
        label(dr, (x, y + 466), name, 16)
        x += 340
    return save(sheet, d / "in-context.png")


def overview():
    W, H = 2240, 980
    sheet = Image.new("RGBA", (W, H), SHEET_BG)
    dr = ImageDraw.Draw(sheet)
    label(dr, (40, 24), "Peace Garden logo directions, 10 October 2026 — current first", 30)
    cols = [("Current", CURRENT, None)] + [(f"{f[0].upper()}: {t}", HERE / f / "icon-1024.svg", f)
                                           for f, t, *_ in DIRECTIONS]
    x = 40
    for name, path, folder in cols:
        sheet.alpha_composite(icon(path, 300), (x, 90))
        label(dr, (x, 400), name)
        for i, s in enumerate((60, 29)):
            sheet.alpha_composite(icon(path, s), (x + i * 90, 450 + (60 - s)))
        if folder:
            fav = HERE / folder / f"{folder}-favicon.svg"
            sheet.alpha_composite(render(fav, 16), (x + 180, 494))
            lk = render(HERE / folder / f"{folder}-lockup.svg", 300, 72)
            sheet.alpha_composite(lk, (x, 560))
            lk = render(HERE / folder / f"{folder}-lockup-light-ground.svg", 300, 72)
            sheet.alpha_composite(lk, (x, 650))
            sheet.alpha_composite(render(HERE / folder / f"{folder}-light-ground.svg", 140, bg=LIGHT_GROUND), (x, 750))
            sheet.alpha_composite(render(HERE / folder / f"{folder}.svg", 140, bg=GROUND), (x + 160, 750))
        else:
            sheet.alpha_composite(render(path, 16), (x + 180, 494))
            sheet.alpha_composite(current_lockup("#FFFFFF", GROUND, 300, 72), (x, 560))
            sheet.alpha_composite(current_lockup("#121212", LIGHT_GROUND, 300, 72), (x, 650))
        x += 362
    return save(sheet, HERE / "overview.png")


def main():
    for folder, title, *_ in DIRECTIONS:
        print(folder, contact_sheet(folder, title), in_context(folder, title))
    print("overview", overview())


if __name__ == "__main__":
    main()
