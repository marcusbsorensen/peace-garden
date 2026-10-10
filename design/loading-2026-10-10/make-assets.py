#!/usr/bin/env python3
"""
Builds the final filmstrips, GIFs and MP4s in this folder from the frames
`LoadingTests.testWriteTheLoadingFrames` writes. Nothing here draws the
animation: every picture is a crop of a frame the shipped SwiftUI view drew.

    TEST_RUNNER_PG_RENDER_LOADING=/some/folder xcodebuild test ... \\
        -only-testing:PeaceGardenTests/LoadingTests/testWriteTheLoadingFrames
    python3 design/loading-2026-10-10/make-assets.py /some/folder

Needs Pillow, and ffmpeg for the MP4s. The first round's pictures (`a-*`, `b-*`,
`compare-resting-frames.png`, `real-launch-*`) were made by
`make-assets-first-round.py` from code that has since been removed.
"""

import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

FRAMES = Path(sys.argv[1])
OUT = Path(__file__).resolve().parent
FPS = 30
MOMENT = 60     # frames in the 2.0 s moment, 0 to 60 inclusive
DISSOLVE = 5    # frames of the 180 ms hand-over after it
TOTAL = MOMENT + 1 + DISSOLVE
LABELLED = [3, 9, 15, 21, 27, 33, 39, 45, 51, 57, 60, 62]   # twelve of the 66
BREATH = 12
FONT = ImageFont.load_default(size=13)
GAP = (60, 60, 70)


def load(name):
    return Image.open(FRAMES / name).convert("RGB")


def central(im, share):
    """The middle of a phone-shaped frame: where the drawing is, and the plant."""
    w, h = im.size
    top = int(h * (0.5 - share / 2))
    return im.crop((0, top, w, top + int(h * share)))


def label(im, text):
    d = ImageDraw.Draw(im)
    d.text((8, 6), text, fill=(140, 140, 160), font=FONT)
    return im


def scaled(im, k):
    return im.resize((int(im.width * k), int(im.height * k)), Image.LANCZOS)


def launch_strip():
    """Twelve frames of the launch moment and its hand-over: dark stage above, light below."""
    rows = []
    for mode in ("dark", "light"):
        row = []
        for index in LABELLED:
            im = scaled(central(load(f"{mode}-{index:03d}.png"), 0.36), 0.3)
            row.append(label(im, f"{index / FPS:.2f} s"))
        rows.append(row)
    w, h = rows[0][0].size
    sheet = Image.new("RGB", (w * len(LABELLED) + 4 * (len(LABELLED) - 1), h * 2 + 4), GAP)
    for r, row in enumerate(rows):
        for c, im in enumerate(row):
            sheet.paste(im, (c * (w + 4), r * (h + 4)))
    return sheet


def waiting_crop(im):
    w, h = im.size
    return im.crop((int(w * 0.2), int(h * 0.12), int(w * 0.8), int(h * 0.95)))


def waiting_strip():
    """One breath, twelve frames: the light appearance above and the dark below."""
    rows = []
    for mode in ("light", "dark"):
        row = [scaled(waiting_crop(load(f"busy-{mode}-{i:02d}.png")), 0.34) for i in range(BREATH)]
        rows.append(row)
    w, h = rows[0][0].size
    sheet = Image.new("RGB", (w * BREATH + 2 * (BREATH - 1), h * 2 + 2), GAP)
    for r, row in enumerate(rows):
        for c, im in enumerate(row):
            sheet.paste(im, (c * (w + 2), r * (h + 2)))
    return sheet


def launch_frames():
    """The whole launch, dark stage beside light stage, with a held frame at each end."""
    out = []
    for index in range(TOTAL):
        pair = [scaled(central(load(f"{mode}-{index:03d}.png"), 0.36), 0.36) for mode in ("dark", "light")]
        w, h = pair[0].size
        both = Image.new("RGB", (w * 2 + 4, h), GAP)
        both.paste(pair[0], (0, 0))
        both.paste(pair[1], (w + 4, 0))
        out.append(both)
    # The blank launch screen the moment begins on, and the stage it hands over to.
    return [out[0]] * 6 + out + [out[-1]] * 12


def waiting_frames(loops=3):
    cells = []
    for index in range(BREATH):
        row = [scaled(waiting_crop(load(f"busy-{mode}-{index:02d}.png")), 0.4) for mode in ("light", "dark")]
        w, h = row[0].size
        both = Image.new("RGB", (w * 2 + 4, h), GAP)
        both.paste(row[0], (0, 0))
        both.paste(row[1], (w + 4, 0))
        cells.append(both)
    return cells * loops


def save_gif(frames, path, fps, colours=160):
    # One palette for the whole animation, taken from a mosaic of frames across it.
    # Taken from the first frame alone it is the blank ground and nothing else, and
    # every colour that arrives later is thrown away.
    sample = frames[:: max(1, len(frames) // 12)][:12]
    w, h = sample[0].size
    mosaic = Image.new("RGB", (w * len(sample), h))
    for i, f in enumerate(sample):
        mosaic.paste(f, (i * w, 0))
    palette = mosaic.quantize(colors=colours, method=Image.MEDIANCUT)
    quantised = [f.quantize(palette=palette, dither=Image.Dither.NONE) for f in frames]
    quantised[0].save(path, save_all=True, append_images=quantised[1:], duration=int(1000 / fps),
                      loop=0, optimize=True, disposal=1)


def save_mp4(frames, path, fps, workdir):
    folder = workdir / path.stem
    folder.mkdir(parents=True, exist_ok=True)
    for i, f in enumerate(frames):
        f.save(folder / f"{i:04d}.png")
    w, h = frames[0].size
    vf = f"scale={w // 2 * 2}:{h // 2 * 2},format=yuv420p"
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", str(fps),
                    "-i", str(folder / "%04d.png"), "-vf", vf, "-c:v", "libx264",
                    "-crf", "20", "-movflags", "+faststart", str(path)], check=True)


def main():
    work = FRAMES / "_video"
    work.mkdir(exist_ok=True)
    launch_strip().save(OUT / "final-launch-filmstrip.png", optimize=True)
    waiting_strip().save(OUT / "final-waiting-filmstrip.png", optimize=True)
    frames = launch_frames()
    save_gif(frames, OUT / "final-launch.gif", FPS)
    save_mp4(frames, OUT / "final-launch.mp4", FPS, work)
    loops = waiting_frames()
    save_gif(loops, OUT / "final-waiting.gif", FPS / 2)
    save_mp4(loops, OUT / "final-waiting.mp4", FPS / 2, work)
    # The two still frames Reduce Motion gets, side by side, light then dark.
    pair = [scaled(waiting_crop(load(f"busy-still-{mode}.png")), 0.5) for mode in ("light", "dark")]
    w, h = pair[0].size
    sheet = Image.new("RGB", (w * 2 + 4, h), GAP)
    sheet.paste(pair[0], (0, 0))
    sheet.paste(pair[1], (w + 4, 0))
    sheet.save(OUT / "final-waiting-reduce-motion.png", optimize=True)
    for name in ("final-launch-filmstrip.png", "final-waiting-filmstrip.png", "final-waiting-reduce-motion.png",
                 "final-launch.gif", "final-launch.mp4", "final-waiting.gif", "final-waiting.mp4"):
        print(name, f"{(OUT / name).stat().st_size / 1024:.0f} KB")


main()
