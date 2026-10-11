"""
The launch label's pictures, from the loading harness's own frames.

    python3 design/launch-label-2026-10-11/make-choice.py <renders>

`<renders>` is the folder `LaunchLabelTests.testWriteTheLaunchLabelFrames`
writes to (`TEST_RUNNER_PG_RENDER_LOADING`): the end of the launch moment on a
390 x 844 pt phone at 3x, the launch ground, a 34 pt home indicator left under
the foot.

- `choice.png`: A, B and C, each as the whole screen, its lower part at 2x, and
  its foot at the phone's own 3x pixels with the update arrow showing.
- `update-glyph.png`: the recommendation's foot at 3x, without and with the
  arrow, under right to left, at the largest text size and in the light
  appearance.
"""
import pathlib
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = pathlib.Path(__file__).resolve().parent
RENDERS = pathlib.Path(sys.argv[1])
S = 3  # the renders' scale
BACK, INK, SOFT, GOLD = (34, 34, 38), (230, 230, 235), (160, 160, 168), (255, 214, 102)

COLUMNS = [
    ("A", "stacked", "Name over version, centred, low (recommended)",
     "Name 13 pt, version 11 pt, 28 pt above the home indicator"),
    ("B", "line", "One line at the foot, the quietest",
     "Name and version side by side, both 11 pt"),
    ("C", "underPlant", "The name under the plant, a caption",
     "Name 17 pt under the plant, version 11 pt at the foot"),
]


def font(size):
    return ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", size)


def frame(name):
    return Image.open(RENDERS / f"{name}.png").convert("RGB")


def crop_pt(image, left, top, width, height):
    return image.crop((int(left * S), int(top * S), int((left + width) * S), int((top + height) * S)))


def save(img, name):
    out = HERE / name
    img.quantize(colors=256, method=Image.Quantize.MEDIANCUT).save(out, optimize=True)
    print(out.name, img.size, out.stat().st_size // 1024, "KB")


def choice():
    cw, pad, gap = 620, 30, 16
    whole_w = 420
    whole_h = round(844 * whole_w / 390)
    lower = (55, 470, 280, 350)     # points: the plant's foot down to the screen's
    lower_w = cw - 20
    lower_h = round(lower[3] * lower_w / lower[2])
    foot = (100, 735, 200, 80)      # points: the foot, at the phone's 3x
    rows = [150, whole_h, lower_h, foot[3] * S, 10]
    img = Image.new("RGB", (pad * 2 + cw * 3, pad + sum(rows) + gap * len(rows)), BACK)
    d = ImageDraw.Draw(img)
    for i, (letter, key, caption, sizes) in enumerate(COLUMNS):
        x = pad + i * cw
        d.text((x, pad - 6), letter, fill=GOLD, font=font(64))
        d.text((x + 70, pad + 8), caption, fill=INK, font=font(20))
        d.text((x + 70, pad + 40), sizes, fill=SOFT, font=font(16))
        y = pad + rows[0] + gap
        plain = frame(f"label-{key}")
        img.paste(plain.resize((whole_w, whole_h), Image.LANCZOS), (x, y))
        y += rows[1] + gap
        img.paste(crop_pt(plain, *lower).resize((lower_w, lower_h), Image.LANCZOS), (x, y))
        y += rows[2] + gap
        img.paste(crop_pt(frame(f"label-{key}-glyph"), *foot), (x, y))
        y += rows[3] + gap
    d.text((pad, pad + 104),
           "Down each column: the whole screen at the end of the moment, 390 pt wide; its lower part "
           "at 2x; the foot at the phone's own 3x pixels, with the update arrow showing.",
           fill=SOFT, font=font(16))
    save(img, "choice.png")


def update_glyph():
    pad, gap = 30, 16
    foot = (95, 725, 200, 95)
    states = [
        ("label-stacked", "Until the store has a newer version: the version alone"),
        ("label-stacked-glyph", "A newer version in the store: the arrow beside it"),
        ("label-stacked-glyph-rtl", "Right to left (Arabic): the arrow on the version's trailing side"),
        ("label-stacked-glyph-largest", "The largest text size asked for: it stops at xxxLarge"),
        ("label-stacked-glyph-light", "The light appearance: the launch ground is dark in both"),
    ]
    tile_w, tile_h = foot[2] * S, foot[3] * S
    img = Image.new("RGB", (pad * 2 + tile_w + 520, pad * 2 + len(states) * (tile_h + gap)), BACK)
    d = ImageDraw.Draw(img)
    y = pad
    for name, caption in states:
        img.paste(crop_pt(frame(name), *foot), (pad, y))
        d.text((pad + tile_w + 24, y + tile_h // 2 - 12), caption, fill=INK, font=font(19))
        y += tile_h + gap
    save(img, "update-glyph.png")


if __name__ == "__main__":
    choice()
    update_glyph()
