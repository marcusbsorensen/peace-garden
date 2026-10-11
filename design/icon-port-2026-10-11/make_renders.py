#!/usr/bin/env python3
"""
Renders for the owner's last look at the icon port, 11 October 2026.

  python3 design/icon-port-2026-10-11/make_renders.py

  icon-before-after.png   today's icon (main) beside the new one under the iOS
                          mask at 512, 180, 120, 87, 60 and 40 px, on the home
                          screen's dark and light grounds, 60 and 40 also 3×
  favicon.png             the old and new favicon at 16, 32 and 48 px, true size
                          and 4×, on a light and a dark browser tab strip
  suite-row-final.png     the new icon beside the five suite icons, 180 and 60 px
  masthead-*.png          the site's bar after the change, served by
                          `tools/site/serve.py` and captured with Playwright

Today's files are read from `origin/main` with git, so this can be rerun on the
branch. Round two's sheet helpers (`make_sheets.py`: the iOS mask, labels, the
450 KB ceiling) are reused, not copied. Run `tools/icon/make_icon.py` first.

  pip install cairosvg pillow numpy scipy playwright
"""

import io
import subprocess
import sys
import tempfile
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
R2 = ROOT / "design/logo-2026-10-11"
sys.path.insert(0, str(R2))

from PIL import Image, ImageDraw     # noqa: E402

import make_sheets as MS              # noqa: E402

R1 = MS.R1
for _f in (R1.FONT, "/usr/share/fonts/opentype/inter/Inter-Regular.otf",
           "/System/Library/Fonts/SFNS.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"):
    if Path(_f).exists():
        R1.FONT = _f
        break

NEW_ICON = ROOT / "tools/icon/icon.svg"
NEW_FAVICON = ROOT / "Server/favicon.ico"
SIZES = (512, 180, 120, 87, 60, 40)
ENLARGED = (60, 40)
PORT = 8817


def from_main(path, into):
    """`path` as it is on origin/main, written into the folder `into`."""
    out = into / Path(path).name
    out.write_bytes(subprocess.run(["git", "-C", str(ROOT), "show", f"origin/main:{path}"],
                                   check=True, capture_output=True).stdout)
    return out


def ico_frame(path, size):
    with Image.open(path) as im:
        im.size = (size, size)
        im.load()
        return im.convert("RGBA")


def icon_before_after(old_icon):
    gap = 28
    row_w = sum(SIZES) + gap * (len(SIZES) - 1) + 60 + sum(s * 3 for s in ENLARGED) + gap
    W = 40 + 150 + row_w + 40
    row_h = 512 + 60
    H = 130 + 2 * (2 * row_h + 40)
    sheet = Image.new("RGBA", (W, H), MS.SHEET_BG)
    dr = ImageDraw.Draw(sheet)
    MS.label(dr, (40, 24), "The app icon: today's (main) beside the new one", 30)
    MS.label(dr, (40, 66), "Under the iOS mask at 512, 180, 120, 87, 60 and 40 px, on the home screen's dark "
                           "(#1C1C1E) and light (#F2F2F7) grounds; then 60 and 40 px enlarged 3×, nearest "
                           "neighbour, as a phone lights them", 17)
    for band, (bg, ink) in enumerate(((MS.HOME_DARK, (235, 235, 240)), (MS.HOME_LIGHT, (40, 40, 45)))):
        y0 = 120 + band * (2 * row_h + 40)
        sheet.alpha_composite(Image.new("RGBA", (W - 60, 2 * row_h + 20), bg), (30, y0))
        d = ImageDraw.Draw(sheet)
        for r, (name, path) in enumerate((("Today", old_icon), ("New", NEW_ICON))):
            y = y0 + 20 + r * row_h
            d.text((50, y + 240), name, fill=ink, font=MS.font(24))
            x = 190
            for s in SIZES:
                sheet.alpha_composite(MS.icon(path, s), (x, y + 512 - s))
                d.text((x + s // 2, y + 520), f"{s}", fill=ink, font=MS.font(14), anchor="ma")
                x += s + gap
            x += 60 - gap
            for s in ENLARGED:
                tile = Image.new("RGBA", (s, s), bg)
                tile.alpha_composite(MS.icon(path, s))
                big = tile.resize((s * 3, s * 3), Image.NEAREST)
                sheet.alpha_composite(big, (x, y + 512 - s * 3))
                d.text((x + s * 3 // 2, y + 520), f"{s} ×3", fill=ink, font=MS.font(14), anchor="ma")
                x += s * 3 + gap
    return MS.save(sheet, HERE / "icon-before-after.png")


def tab(sheet, xy, favicon, strip, active, ink):
    """A browser tab with `favicon` at its true size, beside the site's name."""
    x, y = xy
    w, h = 240, 40
    d = ImageDraw.Draw(sheet)
    d.rounded_rectangle((x, y, x + w, y + h + 10), radius=10, fill=active)
    s = favicon.width
    sheet.alpha_composite(favicon, (x + 14 + (16 - min(s, 16)) // 2, y + (h - s) // 2 + 2))
    d.text((x + 24 + min(s, 48) + 4, y + h // 2 + 2), "Peace Garden", fill=ink, font=MS.font(14), anchor="lm")


def favicon_sheet(old_ico):
    sizes = (16, 32, 48)
    strips = (("Light tab strip", "#DEE1E6", "#FFFFFF", (32, 33, 36)),
              ("Dark tab strip", "#202124", "#35363A", (232, 234, 237)))
    col = 4 * sum(sizes) + 3 * 24 + 40
    W = 40 + 120 + 2 * col + 40
    band_h = 420
    H = 120 + len(strips) * band_h + 20
    sheet = Image.new("RGBA", (W, H), MS.SHEET_BG)
    dr = ImageDraw.Draw(sheet)
    MS.label(dr, (40, 24), "The favicon: today's (main) beside the new one", 30)
    MS.label(dr, (40, 66), "favicon.ico at 16, 32 and 48 px: 4× (nearest neighbour), true size beneath, "
                           "then the 16 px in a tab", 17)
    for band, (title, strip, active, ink) in enumerate(strips):
        y0 = 112 + band * band_h
        sheet.alpha_composite(Image.new("RGBA", (W - 60, band_h - 20), strip), (30, y0))
        d = ImageDraw.Draw(sheet)
        d.text((50, y0 + 12), title, fill=ink, font=MS.font(16))
        for c, (name, path) in enumerate((("Today", old_ico), ("New", NEW_FAVICON))):
            x = 170 + c * col
            d.text((x, y0 + 40), name, fill=ink, font=MS.font(18))
            for s in sizes:
                frame = ico_frame(path, s)
                bg = Image.new("RGBA", (s, s), strip)
                bg.alpha_composite(frame)
                sheet.alpha_composite(bg.resize((s * 4, s * 4), Image.NEAREST), (x, y0 + 70 + 192 - s * 4))
                sheet.alpha_composite(frame, (x + (s * 4 - s) // 2, y0 + 274))
                x += s * 4 + 24
            tab(sheet, (170 + c * col, y0 + 346), ico_frame(path, 16), strip, active, ink)
    return MS.save(sheet, HERE / "favicon.png")


def suite_row():
    cols = [("Peace Garden", "svg", NEW_ICON)] + [(n, "png", MS.ICONS / f) for n, f in MS.SUITE]
    cw = 214
    W = 40 + cw * len(cols) + 60
    H = 120 + 2 * 420
    sheet = Image.new("RGBA", (W, H), MS.SHEET_BG)
    dr = ImageDraw.Draw(sheet)
    MS.label(dr, (40, 24), "The new icon beside the suite", 30)
    MS.label(dr, (40, 66), "180 and 60 px, home-screen dark (#1C1C1E) and light (#F2F2F7) grounds. "
                           "FreqShift's only icon is a 162 px web logo, upscaled.", 17)
    short = {"Animal Rescue Centre": "A.R.C."}
    for band, (bg, ink) in enumerate(((MS.HOME_DARK, (235, 235, 240)), (MS.HOME_LIGHT, (40, 40, 45)))):
        y0 = 110 + band * 420
        sheet.alpha_composite(Image.new("RGBA", (W - 60, 400), bg), (30, y0))
        d = ImageDraw.Draw(sheet)
        for i, (name, kind, ref) in enumerate(cols):
            x = 40 + i * cw + (cw - 180) // 2
            if i == 1:
                d.line((40 + i * cw - 4, y0 + 20, 40 + i * cw - 4, y0 + 380), fill=(128, 128, 136), width=1)
            sheet.alpha_composite(MS.any_icon(kind, ref, 180), (x, y0 + 24))
            d.text((x + 90, y0 + 214), short.get(name, name), fill=ink, font=MS.font(17), anchor="ma")
            sheet.alpha_composite(MS.any_icon(kind, ref, 60), (x + 60, y0 + 262))
            d.text((x + 90, y0 + 330), short.get(name, name), fill=ink, font=MS.font(12), anchor="ma")
    return MS.save(sheet, HERE / "suite-row-final.png")


SHOTS = [
    # (name, path, scheme, width, locale)
    ("front-dark-1280", "/", "dark", 1280, "en-GB"),
    ("front-dark-375", "/", "dark", 375, "en-GB"),
    ("front-light-1280", "/", "light", 1280, "en-GB"),
    ("front-light-375", "/", "light", 375, "en-GB"),
    ("walk-dark-1280", "/walk", "dark", 1280, "en-GB"),
    ("walk-light-375", "/walk", "light", 375, "en-GB"),
    ("front-ar-rtl-dark-1280", "/", "dark", 1280, "ar"),
    ("front-ar-rtl-light-375", "/", "light", 375, "ar"),
]


def mastheads():
    """The bar after the change: `header.masthead` at 2×, 12 px around it."""
    from playwright.sync_api import sync_playwright
    server = subprocess.Popen([sys.executable, str(ROOT / "tools/site/serve.py"), "--port", str(PORT)],
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    out = []
    try:
        time.sleep(1.5)
        with sync_playwright() as p:
            try:
                browser = p.chromium.launch()
            except Exception:
                # A Playwright newer than the machine's browsers: use the one
                # that is installed rather than downloading another.
                browser = p.chromium.launch(executable_path="/opt/pw-browsers/chromium")
            for name, path, scheme, width, locale in SHOTS:
                page = browser.new_page(viewport={"width": width, "height": 900}, device_scale_factor=2,
                                        color_scheme=scheme, locale=locale)
                page.goto(f"http://localhost:{PORT}{path}", wait_until="load", timeout=60000)
                page.wait_for_function("() => { const m = document.querySelector('header.masthead img.mark');"
                                       " return m && m.complete && m.naturalWidth > 0; }", timeout=30000)
                page.wait_for_timeout(1200)
                head = page.locator("header.masthead").first
                box = head.bounding_box()
                mark = page.locator("header.masthead img.mark").first.evaluate(
                    "m => [m.currentSrc.split('/').pop(), m.getBoundingClientRect().width, "
                    "m.getBoundingClientRect().height, document.dir || document.documentElement.dir]")
                pad = 12
                clip = {"x": max(box["x"] - pad, 0), "y": max(box["y"] - pad, 0),
                        "width": min(box["width"] + 2 * pad, width), "height": box["height"] + 2 * pad}
                png = page.screenshot(clip=clip)
                target = HERE / f"masthead-{name}.png"
                MS.save(Image.open(io.BytesIO(png)), target)
                out.append((target.name, mark))
                page.close()
            browser.close()
    finally:
        server.terminate()
    return out


def main():
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        old_icon = from_main("tools/icon/icon.svg", tmp)
        old_ico = from_main("Server/favicon.ico", tmp)
        icon_before_after(old_icon)
        favicon_sheet(old_ico)
        suite_row()
    for name, mark in mastheads():
        print(name, mark)
    for f in sorted(HERE.glob("*.png")):
        print(f"{f.name:40s} {f.stat().st_size / 1024:6.1f} KB")


if __name__ == "__main__":
    main()
