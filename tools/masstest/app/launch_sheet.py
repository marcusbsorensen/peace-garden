"""One sheet of launch moments: a row per phone, a picture per configuration.

    python3 tools/masstest/app/launch_sheet.py build/mt/launch out.jpg --width 100

Reads `<phone>/launch-<locale>-<size>.jpg` from `launch.sh`.
"""
import argparse, os
from PIL import Image, ImageDraw, ImageFont

p = argparse.ArgumentParser()
p.add_argument("folder")
p.add_argument("out")
p.add_argument("--width", type=int, default=100)
a = p.parse_args()

phones = sorted(d for d in os.listdir(a.folder) if os.path.isdir(os.path.join(a.folder, d)))
rows = []
for phone in phones:
    names = sorted(f for f in os.listdir(os.path.join(a.folder, phone)) if f.endswith(".jpg"))
    rows.append((phone, names))
width = a.width
height = int(width * 2.2)
columns = max(len(n) for _, n in rows)
try:
    font = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", 11)
except OSError:
    font = ImageFont.load_default()
sheet = Image.new("RGB", (70 + columns * (width + 4) + 4, len(rows) * (height + 22) + 6), (24, 24, 28))
draw = ImageDraw.Draw(sheet)
for r, (phone, names) in enumerate(rows):
    y = 4 + r * (height + 22)
    draw.text((4, y + height // 2), phone, fill=(220, 220, 220), font=font)
    for c, name in enumerate(names):
        x = 70 + c * (width + 4)
        with Image.open(os.path.join(a.folder, phone, name)) as im:
            h = int(width * im.height / im.width)
            sheet.paste(im.convert("RGB").resize((width, h), Image.LANCZOS), (x, y + 16))
        draw.text((x, y + 2), name[len("launch-"):-4], fill=(200, 200, 200), font=font)
sheet.save(a.out, "JPEG", quality=72, optimize=True)
print(a.out, sheet.size, os.path.getsize(a.out) // 1024, "KB")
