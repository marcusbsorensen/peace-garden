"""Lays out the Share mark's renders as the lettered sheets in this folder.

    python3 design/share-plant-2026-10-13/compose.py <renders> [<screenshots>]

`<renders>` is the folder `PlantShareRenderTests` wrote (PG_RENDERS): the
three wallpapers bare and on a lock screen, the shared picture, the turning
video and the Live Photo. `<screenshots>` holds the simulator's screenshots
of the mark and its menu, if they are to be laid out too. Nothing here draws a
plant; it arranges what the app drew. The video and the movie stay out of
git: a strip of frames from each is what is kept.
"""
import pathlib
import subprocess
import sys
import tempfile

import cairosvg
from PIL import Image, ImageDraw, ImageFont

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
MARK = ROOT / "Server/assets/mark-dark.svg"
SHEET = (24, 24, 28)
INK = (236, 234, 228)
FAINT = (160, 158, 152)


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


def lettered(panels, labels, notes=None, gap=36, pad=40, label_room=96):
    """Panels side by side, each with a letter and a line under it."""
    width = sum(p.width for p in panels) + gap * (len(panels) - 1) + pad * 2
    height = max(p.height for p in panels) + pad * 2 + label_room
    sheet = Image.new("RGB", (width, height), SHEET)
    draw = ImageDraw.Draw(sheet)
    x = pad
    for index, panel in enumerate(panels):
        sheet.paste(panel, (x, pad))
        y = pad + panel.height + 18
        draw.text((x, y), labels[index], font=font(30), fill=INK)
        if notes and notes[index]:
            draw.text((x, y + 40), notes[index], font=font(20), fill=FAINT)
        x += panel.width + gap
    return sheet


def with_mark(picture):
    """The picture with the site's bare mark small in its lower right corner."""
    side = round(picture.width * 0.075)
    with tempfile.TemporaryDirectory() as scratch:
        png = pathlib.Path(scratch) / "mark.png"
        cairosvg.svg2png(url=str(MARK), write_to=str(png), output_width=side, output_height=side)
        mark = Image.open(png).convert("RGBA")
    alpha = mark.getchannel("A").point(lambda a: round(a * 0.8))
    mark.putalpha(alpha)
    marked = picture.convert("RGBA")
    margin = round(picture.width * 0.045)
    marked.alpha_composite(mark, (picture.width - side - margin, picture.height - side - margin))
    return marked.convert("RGB")


def frames(movie, times, width):
    """Frames from a movie at the given seconds, each `width` wide."""
    out = []
    with tempfile.TemporaryDirectory() as scratch:
        for n, t in enumerate(times):
            png = pathlib.Path(scratch) / f"f{n}.png"
            subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-ss", f"{t:.4f}", "-i", str(movie),
                            "-frames:v", "1", str(png)], check=True)
            out.append(fit(Image.open(png).convert("RGB"), width))
    return out


def save_jpeg(image, path, quality=86):
    image.save(path, "JPEG", quality=quality, optimize=True, progressive=True)


def main():
    renders = pathlib.Path(sys.argv[1])
    shots = pathlib.Path(sys.argv[2]) if len(sys.argv) > 2 else None

    # 1. The three grounds, each on a lock screen.
    locks = [fit(Image.open(renders / f"lock-{l}.png").convert("RGB"), 380) for l in "ABC"]
    lettered(locks,
             ["A  Night sky", "B  Day sky", "C  The plant's own stage"],
             ["recommended: the garden's night, the plant's light",
              "the garden's mid-morning, no pool of light",
              "black and the pool of light, as on a dark phone"]
             ).save(HERE / "backgrounds-ABC.png", optimize=True)

    # 2. The default on its own lock screen, larger.
    fit(Image.open(renders / "lock-A.png").convert("RGB"), 630).save(
        HERE / "wallpaper-lockscreen-A.png", optimize=True)

    # 3. A mark in the corner, or none, on the shared picture.
    picture = Image.open(renders / "picture.jpg").convert("RGB")
    plain, marked = fit(picture, 540), fit(with_mark(picture), 540)
    lettered([plain, marked], ["A  No mark", "B  A small mark"],
             ["recommended: the picture is the plant's", "the site's mark, 7.5% of the width, 80%"]
             ).save(HERE / "mark-AB.png", optimize=True)

    # 4. The shared picture itself, smaller than it is sent, under 1 MB.
    save_jpeg(fit(picture, 1080), HERE / "sample-picture.jpg")

    # 5. The turning video, six frames across its eight seconds; the last is
    #    the first again.
    strip = frames(renders / "turning.mp4", [0, 1.6, 3.2, 4.8, 6.4, 7.967], 240)
    lettered(strip, ["0 s", "1.6 s", "3.2 s", "4.8 s", "6.4 s", "8 s (= 0 s)"], gap=12, label_room=64
             ).save(HERE / "turning-strip.png", optimize=True)

    # 6. The moving wallpaper: the movie's frames, then the still it ends on.
    still_path = next(renders.glob("moving.hei*"), None) or renders / "moving.jpg"
    moving = frames(renders / "moving.mov", [0, 1.0, 2.0, 2.967], 200)
    with tempfile.TemporaryDirectory() as scratch:
        png = pathlib.Path(scratch) / "still.png"
        subprocess.run(["sips", "-s", "format", "png", str(still_path), "--out", str(png)],
                       check=True, capture_output=True)
        moving.append(fit(Image.open(png).convert("RGB"), 200))
    lettered(moving, ["0 s", "1 s", "2 s", "3 s", "the still"], gap=12, label_room=64
             ).save(HERE / "moving-strip.png", optimize=True)

    # 7. The mark and its menu, Light and Dark, from the simulator.
    if shots:
        for name in ("button", "menu"):
            pair = [shots / f"{name}-light.png", shots / f"{name}-dark.png"]
            if all(p.exists() for p in pair):
                panels = [fit(Image.open(p).convert("RGB"), 420) for p in pair]
                lettered(panels, ["Light", "Dark"]).save(HERE / f"{name}-light-dark.png", optimize=True)

    for path in sorted(HERE.glob("*.png")) + sorted(HERE.glob("*.jpg")):
        print(f"{path.name:32} {path.stat().st_size / 1024:8.0f} KB")


if __name__ == "__main__":
    main()
