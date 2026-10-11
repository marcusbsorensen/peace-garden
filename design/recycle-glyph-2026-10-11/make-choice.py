"""
The recycling glyph's choice, as one lettered picture: A, B, C and the glyph
before 11 October, each in place on the Settings row (the app, on a simulator),
in the plant's row of marks (drawn by `ChromeMark`), at its true sizes in both
appearances, and enlarged.

    python3 design/recycle-glyph-2026-10-11/make-choice.py <renders> <screenshots>

`<renders>` is `CycleGlyphTests.testWriteTheCycleGlyphs`' folder
(`TEST_RUNNER_PG_RENDER_CYCLE`). `<screenshots>` holds `settings-<x>-<mode>.png`,
simulator screenshots of Settings scrolled to *Starting again*, x in a, b, c,
old, mode in dark, light: the app launched with `-pgOpen settings
-pgCycleFrond <x> -stage.appearance.v1 <mode>`, and `old` from the build
before the change.
"""
import pathlib
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = pathlib.Path(__file__).resolve().parent
RENDERS = pathlib.Path(sys.argv[1])
SHOTS = pathlib.Path(sys.argv[2])

COLUMNS = [
    ("A", "a", "A turn of coil, a start twice the stroke (recommended)"),
    ("B", "b", "More coil, a heavier start: nearest the logo"),
    ("C", "c", "A hook, the logo's small drawing; a gentle taper"),
    ("", "old", "Before: three spirals opening outward"),
]
CW, PAD, GAP = 600, 30, 34
BACK, INK, SOFT, GOLD = (34, 34, 38), (230, 230, 235), (160, 160, 168), (255, 214, 102)


def font(size):
    return ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", size)


def settings_row(path):
    """The *Reset everything* row: found by its crimson glyph, cropped 1:1."""
    shot = Image.open(path).convert("RGB")
    w, h = shot.size
    px = shot.load()
    xs, ys = [], []
    for y in range(0, h, 2):
        for x in range(0, w // 2, 2):
            r, g, b = px[x, y]
            if 95 < r < 210 and g < 80 and b < 90 and r - g > 50:   # crimson, not the seed's pink-gold
                xs.append(x)
                ys.append(y)
    cx, cy = (min(xs) + max(xs)) // 2, (min(ys) + max(ys)) // 2
    return shot.crop((cx - 90, cy - 80, cx - 90 + 540, cy + 80))


def mark_crop(path):
    """The middle mark of the plant's row, its word unrolled."""
    row = Image.open(path).convert("RGB")
    w, h = row.size
    return row.crop((int(w * 0.20), 0, int(w * 0.80), h))


def main():
    rows_h = [110, 175, 175, 170, 260, 410]
    height = PAD + sum(rows_h) + GAP * len(rows_h) + 40
    img = Image.new("RGB", (PAD * 2 + CW * len(COLUMNS), height), BACK)
    d = ImageDraw.Draw(img)
    labels = ["On the Settings row, 15 pt, dark (the app)",
              "On the Settings row, 15 pt, light (the app)",
              "On a plant's row of marks, 28 pt (ChromeMark)",
              "True size at 3x: 15 pt crimson and 28 pt grey, dark and light; 15 pt enlarged 4x",
              "The 28 pt drawing enlarged 12x"]
    for i, (letter, key, caption) in enumerate(COLUMNS):
        x = PAD + i * CW
        if letter:
            d.text((x, PAD - 6), letter, fill=GOLD, font=font(64))
        d.text((x + (70 if letter else 0), PAD + 18), caption, fill=INK, font=font(19))
        y = PAD + rows_h[0] + GAP

        for mode in ("dark", "light"):
            crop = settings_row(SHOTS / f"settings-{key}-{mode}.png")
            img.paste(crop, (x, y))
            y += rows_h[1] + GAP

        mark = mark_crop(RENDERS / f"row-{key}-dark.png")
        fit = min((CW - 20) / mark.width, rows_h[3] / mark.height, 1)
        if fit < 1:
            mark = mark.resize((int(mark.width * fit), int(mark.height * fit)), Image.LANCZOS)
        img.paste(mark, (x, y))
        y += rows_h[3] + GAP

        tx = x
        for size, ink in ((15, "crimson"), (28, "muted")):
            for mode in ("dark", "light"):
                tile = Image.open(RENDERS / f"glyph-{key}-{size}-{ink}-{mode}.png").convert("RGB")
                img.paste(tile, (tx, y + (96 - tile.height) // 2))
                tx += tile.width + 14
        zoom = Image.open(RENDERS / f"glyph-{key}-15-crimson-dark.png").convert("RGB")
        zoom = zoom.resize((zoom.width * 4, zoom.height * 4), Image.NEAREST)
        img.paste(zoom, (tx + 10, y))
        y += rows_h[4] + GAP

        big = Image.open(RENDERS / f"glyph-{key}-enlarged-dark.png").convert("RGB")
        img.paste(big, (x, y))

    # What each band is, small, under it.
    y = PAD + rows_h[0] + GAP
    for index, h in enumerate(rows_h[1:]):
        if labels[index]:
            d.text((PAD, y + h + 8), labels[index], fill=SOFT, font=font(16))
        y += h + GAP
    out = HERE / "choice.png"
    img.quantize(colors=256, method=Image.Quantize.MEDIANCUT).save(out, optimize=True)
    print(out, img.size, out.stat().st_size // 1024, "KB")


if __name__ == "__main__":
    main()
