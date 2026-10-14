"""What VoiceOver finds on a screen, drawn over its photograph: every button's
frame from the screen's element tree, outlined, with its label (and value).

    python3 tools/masstest/app/draw_elements.py <screen.jpg> <screen.json> <out.jpg> [--width 700] [--min-y 0]

Frames are in points and the photograph in pixels; the scale is the picture's
width over the window's.
"""
import argparse, json
from PIL import Image, ImageDraw, ImageFont

p = argparse.ArgumentParser()
p.add_argument("shot")
p.add_argument("tree")
p.add_argument("out")
p.add_argument("--width", type=int, default=700)
p.add_argument("--labels", default="plants", help="plants (buttons with a value), buttons, or all")
a = p.parse_args()

im = Image.open(a.shot).convert("RGB")
tree = json.load(open(a.tree))
s = im.width / tree["window"]["w"]
draw = ImageDraw.Draw(im)
try:
    font = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", int(9 * s))
except OSError:
    font = ImageFont.load_default()
for e in tree["elements"]:
    if e["type"] != "button" or not e["label"]:
        continue
    if a.labels == "plants" and not e.get("value"):
        continue
    x, y, w, h = e["x"] * s, e["y"] * s, e["w"] * s, e["h"] * s
    colour = (255, 64, 160) if e.get("value") else (80, 200, 255)
    draw.rectangle([x, y, x + w, y + h], outline=colour, width=max(2, int(s)))
    text = e["label"] + (f" — {e['value']}" if e.get("value") else "")
    draw.text((x + w + 2, y), text, fill=colour, font=font)
if im.width > a.width:
    im = im.resize((a.width, int(im.height * a.width / im.width)), Image.LANCZOS)
im.save(a.out, "JPEG", quality=80, optimize=True)
print(a.out, im.size)
