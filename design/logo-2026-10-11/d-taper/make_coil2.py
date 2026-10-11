#!/usr/bin/env python3
"""
Peace Garden logo, round two and seven-eighths, 11 October 2026: C2 with an
earlier taper and a lower fork. Design exploration only; nothing here touches
a live asset.

  python3 design/logo-2026-10-11/d-taper/make_coil2.py

Marcus chose C2 (T2's taper, half a turn more in the coil), then asked to
"introduce the taper faster so that we don't have the very thick line all the
way through to the top of that tendril", because it "looks too heavy in
comparison to the relatively small flower head on the left", and to "move
that tendril a bit down so it splits from the main stem further down".

Two changes, both to the tendril alone:

  taper  an ease-out, 1 − (1 − u)^p over the tendril's length, so it starts
         thinning at the fork and is already well under the stem's weight by
         the top of its rise, then settles into the same tip (0.42 of the
         base) without a wedge; round two and a half's smoothstep left most
         of the thinning to the coil
  fork   the tendril leaves the stem lower down. Round two takes the fork 22
         of the stem's 120 steps up; here it is a dial. A lower fork alone
         barely lowers the visible split, because the stalk leaves nearly
         parallel to the stem, so the lower forks also leave a little wider
         and bend a little less, entering the coil on much the same heading.
         The coil sits lower, and smaller than C2's (outer radius 27, not 29),
         since the thinner turns need less room

The stem (its taper starting where round two's fork was, neck 0.75) and the
leaf are C2's, point for point. The small drawing and favicon stay round
two's. The stem, leaf and the stalk's rise come from round two's `meeting()`
and `grow()`, the head from its `curl()`, the taper and every file from
`make_taper.py`, the measures from `make_coil.py`.

  pip install cairosvg pillow numpy scipy
"""

import json
import math
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent))

import numpy as np                    # noqa: E402
from PIL import Image, ImageDraw      # noqa: E402

import make_coil as C                 # noqa: E402

T, ML, MS = C.T, C.ML, C.MS

# ------------------------------------------------------------------ dials

ROUND_TWO_FORK = 22                   # of the stem's 120 steps, round two's
STALK = (0.14, 0.40, 52.0)            # round two's rise: heading −90° + 0.14 + 0.40 s, over 52 units
# Marcus's choice, as drawn: the fork, the rise, the head and the profile
# (0 is round two and a half's smoothstep).
C2 = dict(fork=ROUND_TWO_FORK, stalk=STALK, coil=(1.35, 29.0, 10.0), ease=0.0)
EASE = 2.5                            # the earlier taper: 1 − (1 − u)^2.5 from the fork
COIL = (1.35, 27.0, 10.0)             # C2's half turn more, two units smaller

VARIANTS = [
    # (folder, letter, caption, dials)
    ("coil2-a", "A", "Lower fork, earlier taper",
     dict(fork=14, stalk=(0.24, 0.32, 52.0), coil=COIL, ease=EASE)),
    ("coil2-b", "B", "Lowest fork, earlier taper",
     dict(fork=10, stalk=(0.30, 0.30, 48.0), coil=COIL, ease=EASE)),
    ("coil2-c", "C", "Fork as now, earlier taper",
     dict(fork=ROUND_TWO_FORK, stalk=STALK, coil=COIL, ease=EASE)),
]
RECOMMENDED = "coil2-a"


def taper_for(dials):
    """T2's taper (τ 0.58), its stem held as C2 has it, the tendril's profile
    as `dials` ask."""
    return T.Taper(0.58, coil_ease_out=dials["ease"], stem_taper_from=ROUND_TWO_FORK / 120)


def lowered(dials):
    """C2's drawing with the tendril leaving the stem `dials['fork']` steps
    up it, and its head wound to `dials['coil']`. The small drawing is round
    two's."""
    small_draw = C.coiled(C.T2_COIL)

    def draw(small=False):
        if small:
            out = small_draw(True)
            draw.head = small_draw.head
            return out
        _, stem, leaf = ML.meeting(False)
        h0, dh, length = dials.get("stalk", STALK)
        b, hb = ML.grow(stem[0][dials["fork"]], length, lambda s: -math.pi / 2 + h0 + dh * s)
        turns, r_out, r_in = dials["coil"]
        c, _ = C.ROUND_TWO_HEAD(b[-1], hb, r_out, r_in, turns, +1, n=round(180 * max(1.0, turns / 0.85)))
        draw.head = dict(root=b[-1], heading=hb, turns=turns, r_out=r_out, r_in=r_in, hand=+1)
        return [(b + c[1:], "stem", False), stem, leaf]
    draw.head = None
    return draw


# ---------------------------------------------------------------- measures

def split(dials):
    """Where the tendril leaves the stem, in the 1024 icon: the fork (the
    centrelines' junction) and the visible split (the first point up the
    tendril whose edge clears the stem's), each as a height above the root's
    round end, in tiles; and the tendril's width at the top of its rise, as
    a share of the base and against the stem's at the same height."""
    placed, stroke = T.icon_frame(draw=lowered(dials))
    tp = taper_for(dials)
    cro, stem = np.asarray(placed[0][0]), np.asarray(placed[1][0])
    coil_w, stem_w, _ = T.profiles(placed, stroke, tp)
    sc, ss = T._arclength(cro), T._arclength(stem)
    wc, ws = coil_w(sc / sc[-1]), stem_w(ss / ss[-1])
    gap = (np.hypot(*(cro[:, None, :] - stem[None, :, :]).transpose(2, 0, 1))
           - (wc[:, None] + ws[None, :]) / 2).min(axis=1)
    first = int(np.argmax(gap > 0))
    base = stem[0][1] + stroke / 2
    top = 120                                   # the stalk's last point
    j = int(np.argmin(np.abs(stem[:, 1] - cro[top, 1])))
    split.points = (cro[0], cro[first])
    return {
        "fork_steps": dials["fork"], "fork_share_of_stem": round(dials["fork"] / 120, 3),
        "fork_above_root_end": round((base - cro[0, 1]) / 1024, 3),
        "split_above_root_end": round((base - cro[first, 1]) / 1024, 3),
        "rise_top_width": round(wc[top] / stroke, 2),
        "stem_width_there": round(ws[j] / stroke, 2),
    }


def report(dials):
    m = C.analyse(lowered(dials), taper=taper_for(dials))
    r = {
        "turns": m["turns"], "r_out_units": m["r_out_units"], "r_in_units": m["r_in_units"],
        "taper_profile": (f"ease-out, 1 − (1 − u)^{dials['ease']:g}, from the fork" if dials["ease"]
                          else "smoothstep from the fork (round two and a half's)"),
        "tip_of_base": round(m["tip"] / m["stroke"], 2),
        "tip_px_60": round(C.at(m, "tip", 60), 2), "tip_px_40": round(C.at(m, "tip", 40), 2),
        "mouth_px_180": round(C.at(m, "mouth", 180), 2), "mouth_px_60": round(C.at(m, "mouth", 60), 2),
        "mouth_px_40": round(C.at(m, "mouth", 40), 2),
        "tightest_px_60": round(C.at(m, "tightest", 60), 2),
        "eye_px_180": round(C.at(m, "eye", 180), 2), "eye_px_60": round(C.at(m, "eye", 60), 2),
        "to_stem_px_60": round(C.at(m, "to_stem", 60), 2), "to_leaf_px_60": round(C.at(m, "to_leaf", 60), 2),
        "above_fork_of_tile": round(m["above_fork"] / 1024, 3),
        "coil_box_of_tile": [round(v / 1024, 3) for v in m["coil_box"]],
    }
    r.update(split(dials))
    return r


# ------------------------------------------------------------------ files

def write_variant(folder, letter, caption, dials):
    return T.write_strength(folder, letter, caption, taper_for(dials), draw=lowered(dials),
                            prefix=f"d-taper-{folder}",
                            title=f"D-suite T2, half a turn more, {letter}: {caption.lower()}")


# ----------------------------------------------------------------- sheets

D_ICON = HERE / "c2" / "icon-1024.svg"     # C2 as now
TODAY = MS.ICONS / "peace-garden-today-1024.png"
YELLOW = (255, 214, 102)


def columns():
    cols = [(letter, caption + (" (recommended)" if folder == RECOMMENDED else ""),
             HERE / folder / "icon-1024.svg") for folder, letter, caption, _ in VARIANTS]
    return cols + [("D", "C2 as now", D_ICON), ("", "Today's icon, for reference", TODAY)]


def any_icon(path, px):
    return MS.icon(path, px) if path.suffix == ".svg" else MS.raster_icon(path, px)


def choice():
    """The one picture Marcus decides from: each option under its letter, on
    the home screen's dark and light grounds, at 240 px under the iOS mask
    and at 60 px, true size and enlarged 3× (the coordinator's lettered
    layout)."""
    cols = columns()
    cw, pad, band, head = 300, 24, 480, 92
    grounds = ((MS.HOME_DARK, (235, 235, 245)), (MS.HOME_LIGHT, (30, 30, 30)))
    img = Image.new("RGBA", (pad * 2 + cw * len(cols), head + 2 * (band + 10)), (40, 40, 44))
    d = ImageDraw.Draw(img)
    for i, (letter, caption, _) in enumerate(cols):
        x = pad + i * cw
        d.text((x + 10, 10), letter, fill=YELLOW, font=MS.font(44))
        first, *rest = caption.split(" (")
        for k, line in enumerate([first] + [f"({r}" for r in rest]):
            d.text((x + (60 if letter else 10), 24 + k * 22), line, fill=(220, 220, 225), font=MS.font(17))
    y = head
    for ground, ink in grounds:
        d.rectangle([0, y, img.width, y + band], fill=ground)
        for i, (_, _, path) in enumerate(cols):
            x = pad + i * cw
            img.alpha_composite(any_icon(path, 240), (x + 30, y + 10))
            small = any_icon(path, 60)
            img.alpha_composite(small, (x + 30, y + 270))
            img.alpha_composite(small.resize((180, 180), Image.NEAREST), (x + 105, y + 270))
        d.text((pad, y + 455), "60 px at true size, and the same 60 px enlarged 3× to show the pixels",
               fill=ink, font=MS.font(14))
        y += band + 10
    return MS.save(img, HERE / "coil2-choice.png")


def compare():
    all_dials = [d for *_, d in VARIANTS] + [C2]
    cols = [(f"{letter}  {caption}", path) for letter, caption, path in columns()[:4]]
    coils, forks = [], []
    for dials in all_dials:
        coils.append(C.analyse(lowered(dials), taper=taper_for(dials))["coil_centre"])
        split(dials)
        fork, first = split.points
        forks.append((fork + first) / 2)
    return T.compare(cols, [("Each coil at 1024 px, 1:1", coils),
                            ("Each fork at 1024 px, 1:1, centred between the fork and the visible split", forks)],
                     HERE / "coil2-compare.png",
                     "Earlier taper, lower fork: A, B and C beside D, C2 as it is now")


# ------------------------------------------------------------------- main

def main():
    for v in VARIANTS:
        write_variant(*v)
    out = {}
    for folder, letter, caption, dials in VARIANTS + [("c2", "D", "C2 as now", C2)]:
        r = report(dials)
        r.update(T.measure_icon(HERE / folder / "icon-1024.svg", lowered(dials)))
        r.update(letter=letter, caption=caption, stalk=list(dials["stalk"]))
        out[letter] = r
        print(f"{letter}  fork {r['fork_steps']} ({r['fork_above_root_end']} above the root's end), "
              f"split {r['split_above_root_end']}, {r['taper_profile']}, rise top {r['rise_top_width']} "
              f"(stem {r['stem_width_there']}), tip {r['tip_of_base']} = {r['tip_px_60']}/{r['tip_px_40']} px, "
              f"mouth {r['mouth_px_180']}/{r['mouth_px_60']}/{r['mouth_px_40']}, "
              f"eye {r['eye_px_180']}/{r['eye_px_60']}, stem {r['to_stem_px_60']} leaf {r['to_leaf_px_60']} "
              f"above fork {r['above_fork_of_tile']}, coil {r['coil_box_of_tile']}, root {r['stroke_root']} "
              f"median {r['stroke_colour']} box {r['ink_box_w']}x{r['ink_box_h']} area {r['ink_area']} "
              f"leaf share {r['accent_share']}")
    (HERE / "coil2-measurements.json").write_text(json.dumps(out, indent=2, default=float) + "\n")
    print("choice", choice())
    print("compare", compare())
    folder, letter, caption, _ = next(v for v in VARIANTS if v[0] == RECOMMENDED)
    print(folder, "in context", T.in_context(folder, letter, caption,
                                           name=f"D-suite T2, half a turn more, {letter}: {caption.lower()}"))


if __name__ == "__main__":
    main()
