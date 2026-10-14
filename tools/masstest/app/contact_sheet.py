"""Contact sheets from a screen sweep: one row per configuration, one column
per screen, every thumbnail the same width, labelled.

    python3 tools/masstest/app/contact_sheet.py <device folder> <out.jpg> \
        --configs en-L-dark,fr-L-dark --screens stage,seed,settings --width 150

Configurations and screens default to every folder and every picture found.
A missing picture is left as a grey cell with its name, so a gap in the sweep
shows as a gap. Written as a JPEG at quality 70.
"""
import argparse, os
from PIL import Image, ImageDraw, ImageFont

ORDER = ["launch", "firstlight", "stage", "seed", "meet", "settings", "settings-end", "about", "about-end", "garden", "plant"]


def main():
    p = argparse.ArgumentParser()
    p.add_argument("folder")
    p.add_argument("out")
    p.add_argument("--configs", default="")
    p.add_argument("--screens", default="")
    p.add_argument("--width", type=int, default=150)
    p.add_argument("--title", default="")
    a = p.parse_args()

    configs = a.configs.split(",") if a.configs else sorted(
        d for d in os.listdir(a.folder) if os.path.isdir(os.path.join(a.folder, d)))
    found = {f[:-4] for c in configs for f in os.listdir(os.path.join(a.folder, c))
             if f.endswith(".jpg")} if not a.screens else set()
    screens = a.screens.split(",") if a.screens else sorted(found, key=lambda s: (ORDER.index(s) if s in ORDER else 99, s))

    # Cell height from the first picture's aspect.
    aspect = 2.17
    for c in configs:
        for s in screens:
            path = os.path.join(a.folder, c, s + ".jpg")
            if os.path.exists(path):
                with Image.open(path) as im:
                    aspect = im.height / im.width
                break
        else:
            continue
        break

    w = a.width
    h = int(w * aspect)
    label_w, head_h, pad = 120, 34 if a.title else 18, 4
    sheet = Image.new("RGB", (label_w + len(screens) * (w + pad) + pad, head_h + len(configs) * (h + pad) + pad), (24, 24, 28))
    draw = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", 12)
    except OSError:
        font = ImageFont.load_default()
    if a.title:
        draw.text((pad, 2), a.title, fill=(235, 235, 235), font=font)
    for j, s in enumerate(screens):
        draw.text((label_w + j * (w + pad) + pad, head_h - 15), s, fill=(200, 200, 200), font=font)
    for i, c in enumerate(configs):
        y = head_h + i * (h + pad) + pad
        draw.text((pad, y + h // 2 - 6), c, fill=(200, 200, 200), font=font)
        for j, s in enumerate(screens):
            x = label_w + j * (w + pad) + pad
            path = os.path.join(a.folder, c, s + ".jpg")
            if os.path.exists(path):
                with Image.open(path) as im:
                    sheet.paste(im.convert("RGB").resize((w, h), Image.LANCZOS), (x, y))
            else:
                draw.rectangle([x, y, x + w, y + h], fill=(60, 60, 64))
                draw.text((x + 6, y + 6), "missing", fill=(160, 160, 160), font=font)
    sheet.save(a.out, "JPEG", quality=70, optimize=True)
    print(f"{a.out}: {len(configs)} x {len(screens)}, {sheet.width}x{sheet.height}, {os.path.getsize(a.out) // 1024} KB")


if __name__ == "__main__":
    main()
