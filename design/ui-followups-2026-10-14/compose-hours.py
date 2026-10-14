"""Lays out the sky of the phone's hour as backgrounds-hours-C.png.

    python3 design/ui-followups-2026-10-14/compose-hours.py <renders>

`<renders>` is the folder `PlantShareRenderTests.testDrawTheSkyByTheHour`
wrote (PG_RENDERS): for each hour, the wallpaper on a lock screen
(`lock-hour-HHMM.png`), the shared picture (`picture-hour-HHMM.png`) and the
last frame of the shared time-lapse (`film-hour-HHMM.png`). Nothing here draws
a plant or a sky; it arranges what the app drew.
"""
import pathlib
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = pathlib.Path(__file__).resolve().parent
SHEET = (24, 24, 28)
INK = (236, 234, 228)
FAINT = (160, 158, 152)

HOURS = [("0600", "06:00", "dawn"), ("0900", "09:00", "day"), ("1810", "18:10", "dusk"),
         ("1840", "18:40", "last of the dusk"), ("1930", "19:30", "into the night"),
         ("2300", "23:00", "night")]
ROWS = [("lock-hour", "On the lock screen"), ("picture-hour", "As the shared picture"),
        ("film-hour", "The shared time-lapse's last frame")]


def font(size):
    for path in ("/System/Library/Fonts/Helvetica.ttc", "/System/Library/Fonts/SFNS.ttf"):
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


def fit(image, width):
    height = round(image.height * width / image.width)
    return image.resize((width, height), Image.LANCZOS)


def main():
    renders = pathlib.Path(sys.argv[1])
    cell, gap, pad, label, heading, title = 250, 18, 36, 34, 40, 64
    rows = []
    for stem, name in ROWS:
        panels = [renders / f"{stem}-{key}.png" for key, _, _ in HOURS]
        if all(p.exists() for p in panels):
            rows.append((name, [fit(Image.open(p).convert("RGB"), cell) for p in panels]))
    width = pad * 2 + cell * len(HOURS) + gap * (len(HOURS) - 1)
    height = pad + title + sum(heading + label + max(p.height for p in panels) + pad for _, panels in rows)
    sheet = Image.new("RGB", (width, height), SHEET)
    draw = ImageDraw.Draw(sheet)
    draw.text((pad, pad - 8), "21C, built: the garden's day, the time-lapse's dusk and dawn, "
              "the garden's starry night.", font=font(28), fill=INK)
    draw.text((pad, pad + 30), "The phone's clock only. Each sky hands over to the next as the sun moves.",
              font=font(20), fill=FAINT)
    y = pad + title
    for name, panels in rows:
        draw.text((pad, y + 6), name, font=font(24), fill=INK)
        y += heading
        for index, panel in enumerate(panels):
            x = pad + index * (cell + gap)
            _, clock, sky = HOURS[index]
            draw.text((x, y), clock, font=font(22), fill=INK)
            draw.text((x + 70, y + 3), sky, font=font(18), fill=FAINT)
            sheet.paste(panel, (x, y + label))
        y += label + max(p.height for p in panels) + pad
    out = HERE / "backgrounds-hours-C.png"
    sheet.save(out, optimize=True)
    print(f"{out.name} {sheet.width}x{sheet.height} {out.stat().st_size / 1024:.0f} KB")


if __name__ == "__main__":
    main()
