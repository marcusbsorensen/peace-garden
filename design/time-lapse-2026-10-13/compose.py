#!/usr/bin/env python3
"""
Lays out the time-lapse pictures from the frames the tests draw.

    TEST_RUNNER_PG_RENDER_TIMELAPSE=<folder> xcodebuild … test \
        -only-testing:PeaceGardenTests/TimeLapseRenderTests \
        -only-testing:PeaceGardenTests/TimeLapseLuminanceTests
    python3 design/time-lapse-2026-10-13/compose.py <folder>

Every plant and sky in these pictures is a frame of `TimeLapseFilm`, the same
score and renderer the share export uses, drawn on an iPhone Air simulator.
Only the labels, the layout and the charts are drawn here.
"""

import csv
import pathlib
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = pathlib.Path(__file__).resolve().parent
SOURCE = pathlib.Path(sys.argv[1])

GROUND = (13, 13, 31)
INK = (236, 236, 240)
MUTED = (160, 162, 176)
FAINT = (96, 98, 116)
LIMIT = (217, 168, 140)  # Chrome.pinkGold
SERIES = [(156, 194, 158), (169, 194, 99), (120, 150, 220), (217, 168, 140)]

GROWTH_START, GROWTH_END, DURATION = 1.2, 10.4, 12.0


def font(size, bold=False):
    for path in ["/System/Library/Fonts/HelveticaNeue.ttc", "/System/Library/Fonts/Helvetica.ttc"]:
        try:
            return ImageFont.truetype(path, size, index=1 if bold else 0)
        except OSError:
            continue
    return ImageFont.load_default()


def rows(name):
    with open(SOURCE / name) as handle:
        return list(csv.DictReader(handle))


def strip(name, title, subtitle, lines):
    """One or more rows of nine frames, each labelled with its growth."""
    width, height = 196, 426
    gap, left, top = 10, 150, 96
    canvas = Image.new("RGB", (left + 9 * (width + gap) + 20, top + len(lines) * (height + 64) + 10), GROUND)
    draw = ImageDraw.Draw(canvas)
    draw.text((24, 22), title, font=font(30, True), fill=INK)
    draw.text((24, 60), subtitle, font=font(17), fill=MUTED)
    for row, (label, prefix) in enumerate(lines):
        notes = {int(r["slot"]): r for r in rows(f"strip-{prefix}.csv")}
        y = top + row * (height + 64)
        draw.text((24, y + height // 2 - 12), label, font=font(19, True), fill=INK)
        for slot in range(9):
            frame = Image.open(SOURCE / f"strip-{prefix}-{slot}.png").convert("RGB").resize((width, height), Image.LANCZOS)
            x = left + slot * (width + gap)
            canvas.paste(frame, (x, y))
            note = notes[slot]
            growth = round(float(note["progress"]) * 100)
            text = f"growth {growth}%"
            box = draw.textbbox((0, 0), text, font=font(18, True))
            draw.text((x + (width - box[2]) // 2, y + height + 8), text, font=font(18, True), fill=INK)
            under = f"{float(note['time']):.1f} s · height {round(float(note['height']) * 100)}%"
            box = draw.textbbox((0, 0), under, font=font(14))
            draw.text((x + (width - box[2]) // 2, y + height + 32), under, font=font(14), fill=MUTED)
    canvas.save(HERE / name, optimize=True)


def chart(draw, box, series, y_max, y_label, limit=None, steps=False):
    """A plain line chart: time across, luminance (or its step) up."""
    x0, y0, x1, y1 = box
    for start, end in [(0, GROWTH_START), (GROWTH_END, DURATION)]:
        draw.rectangle((x0 + (x1 - x0) * start / DURATION, y0, x0 + (x1 - x0) * end / DURATION, y1), fill=(22, 22, 44))
    draw.line((x0, y1, x1, y1), fill=FAINT, width=1)
    draw.line((x0, y0, x0, y1), fill=FAINT, width=1)
    for second in range(0, 13, 2):
        x = x0 + (x1 - x0) * second / DURATION
        draw.line((x, y1, x, y1 + 5), fill=FAINT)
        draw.text((x - 6, y1 + 8), f"{second}", font=font(13), fill=MUTED)
    for tick in [0, y_max / 2, y_max]:
        y = y1 - (y1 - y0) * tick / y_max
        draw.line((x0 - 5, y, x0, y), fill=FAINT)
        label = f"{tick * 100:.1f}%" if steps else f"{tick:.2f}"
        draw.text((x0 - 60, y - 8), label, font=font(13), fill=MUTED)
    draw.text((x0, y0 - 24), y_label, font=font(14), fill=MUTED)
    if limit is not None:
        y = y1 - (y1 - y0) * limit / y_max
        for x in range(int(x0), int(x1), 12):
            draw.line((x, y, min(x + 6, x1), y), fill=LIMIT, width=2)
    for colour, points in series:
        xy = [(x0 + (x1 - x0) * t / DURATION, y1 - (y1 - y0) * min(v, y_max) / y_max) for t, v in points]
        draw.line(xy, fill=colour, width=2, joint="curve")


def luminance_chart():
    runs = [
        ("Young plant, two days, Dark, 10:00", "luminance-young-dark-10h.csv"),
        ("Old plant, five months, Dark, 10:00", "luminance-old-dark-10h.csv"),
        ("Old plant, five months, Dark, 22:00", "luminance-old-dark-22h.csv"),
        ("Old plant, five months, Light, 10:00", "luminance-old-light-10h.csv"),
    ]
    width, height = 1500, 1080
    canvas = Image.new("RGB", (width, height), GROUND)
    draw = ImageDraw.Draw(canvas)
    draw.text((40, 26), "The time-lapse's brightness, every frame at 60 fps", font=font(30, True), fill=INK)
    draw.text((40, 66), "Mean relative luminance of the whole frame (stage, sky A and the plant, as the screen plays it), "
              "measured by TimeLapseLuminanceTests.", font=font(17), fill=MUTED)
    draw.text((40, 90), "Shaded: arriving (0–1.2 s) and resting (10.4–12 s). One drift between. "
              "The dashed line is the test's limit: no step of 1% of the range from one frame to the next.",
              font=font(17), fill=MUTED)
    level, step = [], []
    worst = []
    for index, (label, name) in enumerate(runs):
        data = [(float(r["time"]), float(r["luminance"])) for r in rows(name)]
        level.append((SERIES[index], data))
        deltas = [(data[i][0], abs(data[i][1] - data[i - 1][1])) for i in range(1, len(data))]
        step.append((SERIES[index], deltas))
        biggest = max(deltas, key=lambda d: d[1])
        worst.append((label, biggest[1], biggest[0], min(v for _, v in data), max(v for _, v in data)))
    chart(draw, (120, 160, 1040, 560), level, 0.8, "mean luminance (0 = black, 1 = white)")
    chart(draw, (120, 640, 1040, 960), step, 0.012, "change from the frame before", limit=0.01, steps=True)
    y = 170
    for index, (label, biggest, at, low, high) in enumerate(worst):
        draw.rectangle((1080, y + 6, 1100, y + 18), fill=SERIES[index])
        draw.text((1110, y), label, font=font(16, True), fill=INK)
        draw.text((1110, y + 22), f"largest step {biggest * 100:.2f}% at {at:.1f} s", font=font(15), fill=MUTED)
        draw.text((1110, y + 42), f"range {low:.3f} to {high:.3f}", font=font(15), fill=MUTED)
        y += 84
    draw.text((1080, 640), "WCAG 2.3.1 counts a flash as a pair of", font=font(15), fill=MUTED)
    draw.text((1080, 660), "opposing changes of 10% or more, the", font=font(15), fill=MUTED)
    draw.text((1080, 680), "darker under 0.8, and allows three", font=font(15), fill=MUTED)
    draw.text((1080, 700), "a second. Here: none in any second,", font=font(15), fill=MUTED)
    draw.text((1080, 720), "and the brightness turns round once.", font=font(15), fill=MUTED)
    canvas.save(HERE / "sky-luminance.png", optimize=True)


def skies():
    rows_ = [
        ("A", "First light to now, at 15:00", "Recommended. Twilight brightening into the afternoon.", "A-15"),
        ("A", "First light to now, at 22:00", "The same choice at night: twilight settling into the dark.", "A-22"),
        ("B", "Night into day", "Deep night to full day, whatever the hour.", "B-15"),
        ("C", "Still", "The sky as it is now, held. Also what Reduce Motion gets.", "C-15"),
        ("A", "A in the Light appearance", "The same hours in a paler key, over the light ground.", "A-15-light"),
    ]
    times = [0.6, 2.4, 4.4, 6.4, 8.4, 10.4]
    width, height, gap = 140, 304, 8
    left, top, row_height = 300, 110, height + 46
    total_width = left + 6 * (width + gap) + 330
    canvas = Image.new("RGB", (total_width, top + len(rows_) * row_height + 20), GROUND)
    draw = ImageDraw.Draw(canvas)
    draw.text((30, 24), "Which way the sky drifts", font=font(30, True), fill=INK)
    draw.text((30, 64), "The old plant (five months), six moments of each run. One drift per run; "
              "at most one turn from dark to light. Right: that row's luminance over the run.",
              font=font(17), fill=MUTED)
    for row, (letter, title, line, name) in enumerate(rows_):
        y = top + row * row_height
        draw.text((30, y + 4), letter, font=font(64, True), fill=INK)
        draw.text((30, y + 86), title, font=font(18, True), fill=INK)
        words, text = line.split(" "), ""
        line_y = y + 114
        for word in words:
            trial = (text + " " + word).strip()
            if draw.textbbox((0, 0), trial, font=font(15))[2] > 250:
                draw.text((30, line_y), text, font=font(15), fill=MUTED)
                line_y += 20
                text = word
            else:
                text = trial
        draw.text((30, line_y), text, font=font(15), fill=MUTED)
        for slot, t in enumerate(times):
            frame = Image.open(SOURCE / f"sky-{name}-{slot}.png").convert("RGB").resize((width, height), Image.LANCZOS)
            x = left + slot * (width + gap)
            canvas.paste(frame, (x, y))
            draw.text((x + width // 2 - 16, y + height + 8), f"{t:.1f} s", font=font(14), fill=MUTED)
        data = [(float(r["time"]), float(r["luminance"])) for r in rows(f"sky-{name}.csv")]
        x0 = left + 6 * (width + gap) + 70
        top_value = 0.8 if name.endswith("light") else 0.3
        chart(draw, (x0, y + 30, x0 + 230, y + height - 30), [(SERIES[row % len(SERIES)], data)], top_value, "luminance")
    canvas.save(HERE / "sky-ABC.png", optimize=True)


def plant_screen():
    """The real screen with the glyph, and the run playing on it."""
    if not (SOURCE / "screen-still.png").exists():
        return
    width, height = 420, 912
    canvas = Image.new("RGB", (2 * width + 3 * 30, height + 170), GROUND)
    draw = ImageDraw.Draw(canvas)
    draw.text((30, 24), "The play glyph on the plant's screen", font=font(28, True), fill=INK)
    draw.text((30, 62), "iPhone Air simulator, Dark. Top left, opposite Close; Share joins Close at the top right.",
              font=font(16), fill=MUTED)
    for index, (name, label) in enumerate([("screen-still.png", "Before: the play glyph, top left"),
                                           ("screen-playing.png", "2.6 s in: the glyph is a stop square")]):
        shot = Image.open(SOURCE / name).convert("RGB").resize((width, height), Image.LANCZOS)
        x = 30 + index * (width + 30)
        canvas.paste(shot, (x, 100))
        draw.text((x, 100 + height + 14), label, font=font(17, True), fill=INK)
    canvas.save(HERE / "plant-screen.png", optimize=True)


plant_screen()
strip("strip-young.png", "A young plant, two days old",
      "Nine moments of its time-lapse, an eighth of its growing apart: the film the share export makes, "
      "Dark, sky A at 15:00.", [("As played", "young")])
strip("strip-old.png", "An old plant, five months old",
      "The same nine moments. Above, as played; below, under Reduce Motion: five stills dissolving "
      "into each other, and the sky held still.", [("As played", "old"), ("Reduce Motion", "old-reduce-motion")])
luminance_chart()
skies()
print("written to", HERE)
