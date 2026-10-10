#!/usr/bin/env python3
"""
Builds the filmstrips, the GIFs and the MP4s in this folder from the frames
`LoadingTests.testWriteTheLoadingFrames` writes. Nothing here draws the
animation: every picture is a crop of a frame the shipped SwiftUI views drew.

    TEST_RUNNER_PG_RENDER_LOADING=/some/folder xcodebuild test ... \\
        -only-testing:PeaceGardenTests/LoadingTests/testWriteTheLoadingFrames
    python3 design/loading-2026-10-10/make-assets.py /some/folder

Needs Pillow, and ffmpeg for the MP4s.
"""

import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

FRAMES = Path(sys.argv[1])
OUT = Path(__file__).resolve().parent
FPS = 30
MOMENT = 36     # frames in the 1.2 s moment, from 0 to 36 inclusive
DISSOLVE = 5    # frames of the 180 ms hand-over after it
TOTAL = MOMENT + 1 + DISSOLVE
LABELLED = [1, 5, 9, 13, 17, 21, 25, 29, 33, 36, 38, 41]   # twelve frames of the 42
BREATH = 12
FONT = ImageFont.load_default(size=13)


def load(name):
    return Image.open(FRAMES / name).convert("RGB")


def central(im, share=0.5):
    """The middle of a phone-shaped frame: where the mark is, and the plant."""
    w, h = im.size
    top = int(h * (0.5 - share / 2))
    return im.crop((0, top, w, top + int(h * share)))


def label(im, text, ground):
    d = ImageDraw.Draw(im)
    d.text((8, 6), text, fill=(150, 150, 170) if sum(ground) < 300 else (90, 90, 90), font=FONT)
    return im


def launch_strip(variant):
    """Twelve frames of the launch moment and its hand-over, dark above, light below."""
    thumbs = {}
    for mode in ("dark", "light"):
        row = []
        for index in LABELLED:
            im = central(load(f"{variant}-{mode}-{index:03d}.png"))
            im = im.resize((int(im.width * 0.3), int(im.height * 0.3)), Image.LANCZOS)
            ground = im.getpixel((2, 2))
            label(im, f"{index / FPS:.2f} s", ground)
            row.append(im)
        thumbs[mode] = row
    w, h = thumbs["dark"][0].size
    sheet = Image.new("RGB", (w * len(LABELLED) + 4 * (len(LABELLED) - 1), h * 2 + 4), (60, 60, 70))
    for r, mode in enumerate(("dark", "light")):
        for c, im in enumerate(thumbs[mode]):
            sheet.paste(im, (c * (w + 4), r * (h + 4)))
    return sheet


def busy_strip(variant):
    rows = []
    for mode in ("dark", "light"):
        row = []
        for index in range(BREATH):
            im = load(f"{variant}-busy-{mode}-{index:02d}.png")
            w, h = im.size
            im = im.crop((int(w * 0.2), int(h * 0.12), int(w * 0.8), int(h * 0.88)))
            row.append(im.resize((im.width // 2, im.height // 2), Image.LANCZOS))
        rows.append(row)
    w, h = rows[0][0].size
    sheet = Image.new("RGB", (w * BREATH + 2 * (BREATH - 1), h * 2 + 2), (60, 60, 70))
    for r, row in enumerate(rows):
        for c, im in enumerate(row):
            sheet.paste(im, (c * (w + 2), r * (h + 2)))
    return sheet


def side_by_side(variant, share=0.5, scale=0.5):
    """Frames of the whole launch, dark beside light, for the video and the GIF."""
    out = []
    for index in range(TOTAL):
        pair = []
        for mode in ("dark", "light"):
            im = central(load(f"{variant}-{mode}-{index:03d}.png"), share)
            pair.append(im.resize((int(im.width * scale), int(im.height * scale)), Image.LANCZOS))
        w, h = pair[0].size
        both = Image.new("RGB", (w * 2 + 4, h), (60, 60, 70))
        both.paste(pair[0], (0, 0))
        both.paste(pair[1], (w + 4, 0))
        out.append(both)
    # A held frame at each end: the blank launch screen the moment begins on, and
    # the stage it hands over to.
    return [out[0]] * 6 + out + [out[-1]] * 12


def busy_frames(variant, loops=3):
    cells = []
    for index in range(BREATH):
        row = []
        for mode in ("dark", "light"):
            im = load(f"{variant}-busy-{mode}-{index:02d}.png")
            w, h = im.size
            row.append(im.crop((int(w * 0.2), int(h * 0.12), int(w * 0.8), int(h * 0.88))))
        w, h = row[0].size
        both = Image.new("RGB", (w * 2 + 4, h), (60, 60, 70))
        both.paste(row[0], (0, 0))
        both.paste(row[1], (w + 4, 0))
        cells.append(both.resize((both.width // 2, both.height // 2), Image.LANCZOS))
    return cells * loops


def save_gif(frames, path, fps):
    # One palette for the whole animation, taken from a mosaic of frames across
    # it. Taken from the first frame alone it is the blank ground and nothing
    # else, and every colour that arrives later is thrown away.
    sample = frames[:: max(1, len(frames) // 12)][:12]
    w, h = sample[0].size
    mosaic = Image.new("RGB", (w * len(sample), h))
    for i, f in enumerate(sample):
        mosaic.paste(f, (i * w, 0))
    palette = mosaic.quantize(colors=200, method=Image.MEDIANCUT)
    quantised = [f.quantize(palette=palette, dither=Image.Dither.NONE) for f in frames]
    quantised[0].save(path, save_all=True, append_images=quantised[1:], duration=int(1000 / fps),
                      loop=0, optimize=True, disposal=1)


def save_mp4(frames, path, fps, workdir):
    folder = workdir / path.stem
    folder.mkdir(parents=True, exist_ok=True)
    for i, f in enumerate(frames):
        f.save(folder / f"{i:04d}.png")
    # Even dimensions for yuv420p.
    w, h = frames[0].size
    vf = f"scale={w // 2 * 2}:{h // 2 * 2},format=yuv420p"
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", str(fps),
                    "-i", str(folder / "%04d.png"), "-vf", vf, "-c:v", "libx264",
                    "-crf", "20", "-movflags", "+faststart", str(path)], check=True)


def main():
    work = FRAMES / "_video"
    work.mkdir(exist_ok=True)
    for variant in ("a", "b"):
        launch_strip(variant).save(OUT / f"{variant}-launch-filmstrip.png", optimize=True)
        busy_strip(variant).save(OUT / f"{variant}-waiting-filmstrip.png", optimize=True)
        frames = side_by_side(variant)
        save_gif(frames, OUT / f"{variant}-launch.gif", FPS)
        save_mp4(frames, OUT / f"{variant}-launch.mp4", FPS, work)
        loops = busy_frames(variant)
        save_gif(loops, OUT / f"{variant}-waiting.gif", FPS / 2)
        save_mp4(loops, OUT / f"{variant}-waiting.mp4", FPS / 2, work)
    # The two resting still frames of the moment side by side: the last frame of
    # each, before the hand-over, which is what is on screen at the end.
    pair = []
    for variant in ("a", "b"):
        for mode in ("dark", "light"):
            im = central(load(f"{variant}-{mode}-{MOMENT:03d}.png"), 0.6)
            pair.append(im.resize((int(im.width * 0.5), int(im.height * 0.5)), Image.LANCZOS))
    w, h = pair[0].size
    sheet = Image.new("RGB", (w * 4 + 12, h), (60, 60, 70))
    for i, im in enumerate(pair):
        sheet.paste(im, (i * (w + 4), 0))
    sheet.save(OUT / "compare-resting-frames.png", optimize=True)
    for name in ("a", "b"):
        for kind in ("launch", "waiting"):
            for ext in ("gif", "mp4"):
                p = OUT / f"{name}-{kind}.{ext}"
                print(p.name, f"{p.stat().st_size / 1024:.0f} KB")


main()
