#!/usr/bin/env python3
"""
Builds every picture in this folder from the frames
`LoadingTests.testWriteTheLoadingFrames` writes. Nothing here draws the
animation: every picture is a crop of a frame the shipped SwiftUI view drew.

    TEST_RUNNER_PG_RENDER_LOADING=/some/new xcodebuild test ... \\
        -only-testing:PeaceGardenTests/LoadingTests/testWriteTheLoadingFrames
    python3 design/loading-2026-10-11/make-assets.py /some/new /some/before

`/some/before` holds the same harness's frames from the 10 October drawing
(commit a605bae, the merge before this round), for `before-after.png`. Without
it, that one sheet is skipped.

Needs Pillow, and ffmpeg for the MP4s.
"""

import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

NEW = Path(sys.argv[1])
BEFORE = Path(sys.argv[2]) if len(sys.argv) > 2 else None
OUT = Path(__file__).resolve().parent
FPS = 30
MOMENT = 60     # frames in the 2.0 s moment, 0 to 60 inclusive
DISSOLVE = 5    # frames of the 180 ms hand-over after it
TOTAL = MOMENT + 1 + DISSOLVE
LABELLED = [3, 9, 15, 21, 27, 33, 39, 45, 51, 57, 60, 62]   # twelve of the 66
BREATH = 12
FONT = ImageFont.load_default(size=13)
BIG = ImageFont.load_default(size=17)
GAP = (60, 60, 70)
INK = (150, 150, 168)
SHEET = (28, 28, 36)

# The recommended dress: the stem tapered, the leaf outlined (Fiddlehead.Style.standard).
STANDARD = "tapered-outline"


def load(name, folder=NEW):
    return Image.open(folder / name).convert("RGB")


def label(im, text, fill=INK, font=FONT):
    ImageDraw.Draw(im).text((6, 5), text, fill=fill, font=font)
    return im


def scaled(im, k):
    return im.resize((int(im.width * k), int(im.height * k)), Image.LANCZOS)


def grid(rows, gap=4, background=GAP):
    """Rows of equal-sized cells, pasted with a gap."""
    w = max(sum(c.width for c in row) + gap * (len(row) - 1) for row in rows)
    h = sum(max(c.height for c in row) for row in rows) + gap * (len(rows) - 1)
    sheet = Image.new("RGB", (w, h), background)
    y = 0
    for row in rows:
        x = 0
        for cell in row:
            sheet.paste(cell, (x, y))
            x += cell.width + gap
        y += max(c.height for c in row) + gap
    return sheet


def titled(sheet, title, notes=()):
    """A sheet with a title above it and a line or two of notes."""
    head = 34 + 18 * len(notes)
    out = Image.new("RGB", (sheet.width, sheet.height + head), SHEET)
    d = ImageDraw.Draw(out)
    d.text((10, 8), title, fill=(220, 220, 228), font=BIG)
    for i, line in enumerate(notes):
        d.text((10, 32 + 18 * i), line, fill=INK, font=FONT)
    out.paste(sheet, (0, head))
    return out


def save_png(im, name):
    path = OUT / name
    im.save(path, optimize=True)
    if path.stat().st_size > 450 * 1024:
        # Still too big: a 256-colour palette, which these flat drawings lose nothing to.
        im.quantize(colors=256, method=Image.MEDIANCUT, dither=Image.Dither.NONE).save(path, optimize=True)
    return name


# MARK: - The launch moment


def launch_strip():
    """Twelve frames of the launch moment and its hand-over, whole screens: the dark
    stage above and the light stage below. The moment is on the dark ground in both
    appearances, so the rows differ only at the hand-over."""
    rows = []
    for mode in ("dark", "light"):
        rows.append([label(scaled(load(f"launch-{mode}-{i:03d}.png"), 0.25), f"{i / FPS:.2f} s")
                     for i in LABELLED])
    return grid(rows)


def launch_frames():
    out = []
    for index in range(TOTAL):
        pair = [scaled(load(f"launch-{mode}-{index:03d}.png"), 0.2) for mode in ("dark", "light")]
        out.append(grid([pair]))
    # The blank launch screen the moment begins on, and the stage it hands over to.
    return [out[0]] * 6 + out + [out[-1]] * 12


def mark_crop(im):
    """The launch frame's middle, where the mark is: the 55 % wide frame and a little."""
    w, h = im.size
    return im.crop((int(w * 0.17), int(h * 0.27), int(w * 0.83), int(h * 0.73)))


# MARK: - The waiting mark


def waiting_crop(im):
    w, h = im.size
    return im.crop((int(w * 0.25), int(h * 0.1), int(w * 0.75), int(h * 0.98)))


def waiting_strip(folder=NEW):
    rows = []
    for mode in ("light", "dark"):
        rows.append([scaled(waiting_crop(load(f"busy-{mode}-{i:02d}.png", folder)), 0.42) for i in range(BREATH)])
    return grid(rows, gap=2)


def waiting_frames(loops=3):
    cells = []
    for index in range(BREATH):
        row = [scaled(waiting_crop(load(f"busy-{mode}-{index:02d}.png")), 0.42) for mode in ("light", "dark")]
        cells.append(grid([row]))
    return cells * loops


def mark_only(im):
    """The waiting mark alone at a phone's own 3x pixels: 40 x 60 pt and a margin."""
    w, h = im.size
    cx, cy = w // 2, h // 2
    return im.crop((cx - 84, cy - 110, cx + 84, cy + 110))


# MARK: - Moving pictures


def save_gif(frames, path, fps, colours=128):
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


# MARK: - The sheets


def final_frame():
    """The plant the moment ends on, in the recommended dress, at 3x."""
    return load(f"final-{STANDARD}.png")


def reduce_motion():
    pair = [scaled(waiting_crop(load(f"busy-still-{mode}.png")), 0.6) for mode in ("light", "dark")]
    return grid([pair])


def before_after():
    """10 October above, 11 October below: the launch moment at seven points, then the
    waiting mark at the top of its breath in light and dark, and the Reduce Motion still."""
    times = [9, 21, 30, 39, 45, 51, 60]
    rows = []
    for folder, name in ((BEFORE, "10 October"), (NEW, "11 October")):
        row = [label(scaled(mark_crop(load(f"launch-dark-{i:03d}.png", folder)), 0.42),
                     f"{name} · {i / FPS:.1f} s") for i in times]
        for mode in ("light", "dark"):
            row.append(label(scaled(mark_only(load(f"busy-{mode}-06.png", folder)), 1.0), f"waiting, {mode}",
                             fill=(120, 120, 130)))
        row.append(label(mark_only(load("busy-still-dark.png", folder)), "still", fill=(120, 120, 130)))
        rows.append(row)
    return titled(grid(rows), "Before and after: 10 October (above) and 11 October (below)",
                  ["Launch moment on #0D0D1F, then the waiting mark at the top of its breath and the Reduce Motion still, "
                   "at a phone's own 3x pixels."])


def halo_sheet():
    cells = []
    for value, words in (("007", "halo 0.07, as on 10 October"), ("004", "halo 0.04, chosen"), ("000", "no halo")):
        im = load(f"final-halo-{value}.png")
        w, h = im.size
        # The upper half of the plant at 1:1, where the halo shows against the leaf and the stem.
        crop = im.crop((int(w * 0.12), int(h * 0.02), int(w * 0.88), int(h * 0.52)))
        cells.append(label(crop, words, fill=(200, 200, 210)))
    return titled(grid([cells]), "The halo under the hairline, on the plant the moment ends on",
                  ["1:1 crops of the 3x render (the upper half of the plant). The halo is the stem's middle colour at "
                   "this opacity, 10 pt wide."])


def choice_sheet(names, words, title, notes):
    """One row per dress: five points of the launch moment, the plant it ends on at 1:1,
    and the waiting mark at the top of its breath, dark and light, at 3x."""
    rows = []
    for name, caption in zip(names, words):
        row = []
        for index, seconds in enumerate([0.5, 0.9, 1.2, 1.5, 2.0]):
            row.append(label(scaled(load(f"choice-moment-{name}-{index}.png"), 0.5), f"{caption} · {seconds:.1f} s"))
        final = load(f"final-{name}.png")
        w, h = final.size
        row.append(label(final.crop((int(w * 0.2), int(h * 0.02), int(w * 0.8), int(h * 0.35))), "the end, 1:1"))
        for mode in ("dark", "light"):
            row.append(label(mark_only(load(f"choice-busy-{name}-{mode}-2.png")), f"40 pt, {mode}",
                             fill=(120, 120, 130)))
        row.append(label(mark_only(load(f"choice-busy-{name}-dark-still.png")), "still", fill=(120, 120, 130)))
        rows.append(row)
    return titled(grid(rows), title, notes)


def main():
    work = NEW / "_video"
    work.mkdir(exist_ok=True)
    made = []
    made.append(save_png(launch_strip(), "launch-filmstrip.png"))
    frames = launch_frames()
    save_gif(frames, OUT / "launch.gif", FPS)
    save_mp4(frames, OUT / "launch.mp4", FPS, work)
    made += ["launch.gif", "launch.mp4"]
    made.append(save_png(waiting_strip(), "waiting-filmstrip.png"))
    loops = waiting_frames()
    save_gif(loops, OUT / "waiting.gif", FPS / 2)
    save_mp4(loops, OUT / "waiting.mp4", FPS / 2, work)
    made += ["waiting.gif", "waiting.mp4"]
    made.append(save_png(reduce_motion(), "reduce-motion.png"))
    made.append(save_png(final_frame(), "final-frame.png"))
    if BEFORE:
        made.append(save_png(before_after(), "before-after.png"))
    made.append(save_png(halo_sheet(), "option-halo.png"))
    made.append(save_png(choice_sheet(
        ["even-outline", "tapered-outline"], ["even", "tapered"],
        "The stem: an even hairline (10 October) above, tapered to 0.6 at the tip below",
        ["Both with the outlined leaf. The taper runs root to tip, so the coil thins as it turns in "
         "and the stem thins towards the leaf."]), "option-stem.png"))
    made.append(save_png(choice_sheet(
        ["tapered-outline", "tapered-filled"], ["outline", "filled"],
        "The leaf: a stroked outline, as the logo's, above; filled below",
        ["Both with the tapered stem. The waiting mark's leaf never opens past its bud, so at 40 pt "
         "it is a few points across."]), "option-leaf.png"))
    for name in made:
        print(name, f"{(OUT / name).stat().st_size / 1024:.0f} KB")


main()
