"""Pictures side by side, labelled, for a before/after or an A/B in a report.

    python3 tools/masstest/app/side_by_side.py out.jpg "English" a.jpg "Right to left" b.jpg [--height 360]
"""
import sys
from PIL import Image, ImageDraw, ImageFont

args = sys.argv[1:]
height = 360
if "--height" in args:
    i = args.index("--height")
    height = int(args[i + 1])
    del args[i:i + 2]
out, pairs = args[0], list(zip(args[1::2], args[2::2]))
ims = []
for label, path in pairs:
    im = Image.open(path).convert("RGB")
    ims.append((label, im.resize((int(im.width * height / im.height), height), Image.LANCZOS)))
try:
    font = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", 13)
except OSError:
    font = ImageFont.load_default()
sheet = Image.new("RGB", (sum(im.width for _, im in ims) + 8 * (len(ims) + 1), height + 30), (245, 245, 245))
draw = ImageDraw.Draw(sheet)
x = 8
for label, im in ims:
    draw.text((x, 6), label, fill=(30, 30, 30), font=font)
    sheet.paste(im, (x, 24))
    x += im.width + 8
sheet.save(out, "JPEG", quality=78, optimize=True)
print(out, sheet.size)
