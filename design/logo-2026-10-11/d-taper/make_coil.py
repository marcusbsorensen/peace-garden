#!/usr/bin/env python3
"""
Peace Garden logo, round two and three-quarters, 11 October 2026: T2 with
more curl. Design exploration only; nothing here touches a live asset.

  python3 design/logo-2026-10-11/d-taper/make_coil.py

Marcus chose T2 (τ 0.58: the coil's tip at 0.42 of the base stroke, the
stem's neck at 0.75, the leaf at 0.72). He then asked for "a little bit more
of an inward spiralling curl so it's got a tiny more similarity to the
original app logo", today's spiral icon (`tools/icon/make_icon.py`: a
logarithmic spiral of 2 turns, its radius growing 2.55 times a turn).

Only the crozier's head changes. Round two's `meeting()` draws it with
`curl(b[-1], hb, 24, 16, 0.85, +1)`: a logarithmic spiral whose radius of
curvature falls from 24 to 16 units over 0.85 turns, about 1.61 times a turn.
Here `meeting()` runs unchanged with that one call's dials replaced, so the
stalk, the fork, the stem, the leaf, the taper, the ramp, the placement and
the file set are all T2's. The taper still runs from the fork to the tip, so
the tip is still the thinnest point.

Why the coil has to grow. Wound on at T2's own rate, a quarter turn more
brings the tip within 0.4 px of the stalk at 60 px, and the turns merge. So
each extra amount winds faster (2.1 to 2.3 times a turn, nearer today's
2.55), with the inner radius held at 10 units (0.83 strokes) so the eye is
the same in all three; the outer radius then grows so the first turn keeps
its room. C1 stays T2's size; C2 and C3 grow.

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
from PIL import Image                 # noqa: E402

import make_taper as T                # noqa: E402

ML, MS = T.ML, T.MS
ROUND_TWO_HEAD = ML.curl              # round two's crozier head, before any patch

# ------------------------------------------------------------------ dials

TAPER = dict((f, t) for f, _, _, t in T.STRENGTHS)["t2"]   # Marcus's choice
T2_COIL = (0.85, 24.0, 16.0)          # (turns, outer radius, inner radius), round two's
ROUND_TWO_SMALL = (0.62, 26.0, 20.0)  # the small drawing's, round two's
COILS = [
    # (folder, label, amount, (turns, outer radius, inner radius))
    ("c1", "C1", "a quarter turn more", (1.10, 25.0, 10.0)),
    ("c2", "C2", "half a turn more", (1.35, 29.0, 10.0)),
    ("c3", "C3", "three-quarters of a turn more", (1.60, 34.0, 10.0)),
]
# The small drawing with a little of the extra curl, tried at 16 and 32 px.
SMALL_TRIED = (0.77, 33.0, 20.0)
SMALL_COIL = None                     # None keeps round two's small drawing
RECOMMENDED = "c2"


def coiled(dials, small_dials=None):
    """A stand-in for round two's `meeting()`, with the crozier's head wound
    to `dials` (and the small drawing's to `small_dials`, or round two's).
    The arguments the head was grown from are kept on `draw.head`, for the
    eye's centre."""
    def draw(small=False):
        turns, r_out, r_in = (small_dials or ROUND_TWO_SMALL) if small else dials

        def head(root, heading, _r_out, _r_in, _turns, hand, n=180):
            draw.head = dict(root=root, heading=heading, turns=turns, r_out=r_out, r_in=r_in, hand=hand)
            return ROUND_TWO_HEAD(root, heading, r_out, r_in, turns, hand,
                                  n=round(180 * max(1.0, turns / 0.85)))

        with T.patched(ML, curl=head):
            return ML.meeting(small)
    draw.head = None
    return draw


# ---------------------------------------------------------------- the eye

ICON_BOX = ((1024 - ML.INK_HEIGHT * 1024) / 2,) * 2 + (ML.INK_HEIGHT * 1024,) * 2
FAVICON_BOX = (17, 13, 74, 74)


def analyse(draw, small=False, taper=TAPER):
    """The coil measured in the frame it is drawn in: the 1024 icon, or the
    100-unit favicon for the small drawing. Lengths come back in that frame's
    pixels; `per_px` converts them to any size."""
    if small:
        box, frac, frame = FAVICON_BOX, ML.TILE_STROKE["suite"] / ML.INK_HEIGHT * 1.35, 100
    else:
        box, frac, frame = ICON_BOX, ML.TILE_STROKE["suite"] / ML.INK_HEIGHT, 1024
    raw = draw(small)
    head = draw.head
    placed, stroke = ML.place(raw, box, frac)
    rc, cro = np.asarray(raw[0][0]), np.asarray(placed[0][0])
    stem, leaf = np.asarray(placed[1][0]), np.asarray(placed[2][0])
    k = np.hypot(*(cro[-1] - cro[0])) / np.hypot(*(rc[-1] - rc[0]))
    off = cro[0] - k * rc[0]
    sc, ss = T._arclength(cro), T._arclength(stem)
    if taper is not None and not small:
        coil_w, stem_w, _ = T.profiles(placed, stroke, taper)
        wc, ws = coil_w(sc / sc[-1]), stem_w(ss / ss[-1])
        wl = np.full(len(leaf), stroke * taper.leaf)
    else:
        wc, ws = np.full(len(cro), stroke), np.full(len(stem), stroke)
        wl = np.full(len(leaf), stroke * ML.LEAF_WEIGHT)
    n_b = 121                                   # the stalk's points; the head follows
    # The eye's centre is the spiral's pole: the head wound on for eight more turns.
    ext = head["turns"] + 8
    pole_raw, _ = ROUND_TWO_HEAD(head["root"], head["heading"], head["r_out"],
                                 head["r_out"] * (head["r_in"] / head["r_out"]) ** (ext / head["turns"]),
                                 ext, head["hand"], n=6000)
    pole = off + k * np.asarray(pole_raw[-1])

    def clear(p, wp, q, wq):
        return np.hypot(*(p[:, None, :] - q[None, :, :]).transpose(2, 0, 1)) - (wp[:, None] + wq[None, :]) / 2

    pairs = clear(cro, wc, cro, wc)
    pairs[np.abs(sc[:, None] - sc[None, :]) < 2 * stroke] = np.inf
    coil = slice(n_b - 1, None)
    allp, allw = np.vstack([cro, stem, leaf]), np.concatenate([wc, ws, wl])
    lowest = (cro[coil, 1] + wc[coil] / 2).max()
    x0, y0, x1, y1 = (cro[coil] - wc[coil, None] / 2).min(axis=0).tolist() + \
                     (cro[coil] + wc[coil, None] / 2).max(axis=0).tolist()
    return {
        "frame": frame, "stroke": stroke,
        "turns": head["turns"], "r_out_units": head["r_out"], "r_in_units": head["r_in"],
        "r_in_strokes": head["r_in"] * k / stroke,
        "growth_per_turn": (head["r_out"] / head["r_in"]) ** (1 / head["turns"]),
        "tip": wc[-1],
        "mouth": float(pairs[-1].min()) if not np.isinf(pairs[-1].min()) else None,
        "tightest": float(pairs.min()),
        "eye": float((np.hypot(*(allp - pole).T) - allw / 2).min()),
        "to_stem": float(clear(cro[coil], wc[coil], stem, ws).min()),
        "to_leaf": float(clear(cro[coil], wc[coil], leaf, wl).min()),
        "above_fork": float(cro[0, 1] - lowest),
        "coil_box": (x1 - x0, y1 - y0),
        "coil_centre": ((x0 + x1) / 2, (y0 + y1) / 2),
    }


def at(m, key, size):
    """A length from `analyse()` in pixels at `size`."""
    return m[key] * size / m["frame"]


# ------------------------------------------------------------------ files

def write_coil(folder, label, amount, dials):
    title = f"D-suite T2 with more curl, {label} ({amount})"
    return T.write_strength(folder, label, amount, TAPER, draw=coiled(dials, SMALL_COIL),
                            prefix=f"d-taper-{folder}", title=title)


# ----------------------------------------------------------------- sheets

T2_ICON = HERE / "t2" / "icon-1024.svg"
NAMES = {"t2": "T2, as chosen", "c1": "C1, +¼ turn", "c2": "C2, +½ turn", "c3": "C3, +¾ turn"}


def today_centre():
    """The centre of today's spiral at 1024: the centroid of its green ink,
    which the coil's turns outweigh the tail running up to the bract."""
    rgb = np.asarray(T.R1.render(MS.CURRENT, 1024).convert("RGB")).astype(int)
    green = (rgb[..., 1] > 120) & (rgb[..., 1] - rgb[..., 2] > 80)
    ys, xs = np.nonzero(green)
    return (float(xs.mean()), float(ys.mean()))


def coil_compare():
    cols = [(NAMES["t2"], T2_ICON)] + [(NAMES[f], HERE / f / "icon-1024.svg") for f, *_ in COILS]
    cols += [("Today's icon", MS.CURRENT)]
    centres = [analyse(coiled(T2_COIL))["coil_centre"]]
    centres += [analyse(coiled(d))["coil_centre"] for *_, d in COILS]
    centres += [today_centre()]
    return T.compare(cols, [("Each coil at 1024 px, 1:1 (today's spiral for reference)", centres)],
                     HERE / "curl-compare.png",
                     "T2 with more curl: T2 as chosen, then C1, C2 and C3, with today's spiral icon")


def coil_suite_row():
    pg = [(NAMES["t2"], T2_ICON)] + [(NAMES[f], HERE / f / "icon-1024.svg") for f, *_ in COILS]
    return T.suite_row(pg, HERE / "curl-suite-row.png",
                       "T2 with more curl beside the suite: T2, C1, C2 and C3, the five suite apps' "
                       "real icons, then today's Peace Garden icon")


def coil_small_sizes():
    tried = coiled(T2_COIL, SMALL_TRIED)
    base = analyse(coiled(T2_COIL), small=True, taper=None)["coil_box"][0]
    rows = []
    for caption, meeting, dials in (("Round two's small drawing", None, ROUND_TWO_SMALL),
                                    ("With a little more curl", tried, SMALL_TRIED)):
        m = analyse(coiled(T2_COIL, dials), small=True, taper=None)
        chosen = (SMALL_COIL or ROUND_TWO_SMALL) == dials
        note = (f"{'Chosen' if chosen else 'Not chosen'}: {caption.lower()}, {dials[0]:.2f} turns, "
                f"coil ×{m['coil_box'][0] / base:.2f} wide. "
                f"Mouth gap on the favicon {at(m, 'mouth', 16):.2f} px at 16, {at(m, 'mouth', 32):.2f} at 32; "
                f"eye {at(m, 'eye', 16):.2f} and {at(m, 'eye', 32):.2f} px")

        def src(kind, meeting=meeting):
            return T.small_svg(None, kind, meeting)
        rows.append((note, src))
    return T.small_sheet(
        rows, HERE / "curl-small-sizes.png",
        "Small sizes with more curl: the favicon and the small drawing at 16, 32 and 48 px, "
        "enlarged 4× (nearest neighbour) with the true size beneath",
        "Round two's untapered small drawing, then the same with a little of the extra curl. "
        "The small drawing is the same for C1, C2 and C3.")


# ------------------------------------------------------------------- main

def report(name, draw):
    m = analyse(draw)
    row = {
        "turns": m["turns"], "r_out_units": m["r_out_units"], "r_in_units": m["r_in_units"],
        "r_in_strokes": round(m["r_in_strokes"], 2), "growth_per_turn": round(m["growth_per_turn"], 2),
        "coil_box_vs_t2": None,
        "tip_px_60": round(at(m, "tip", 60), 2), "tip_px_40": round(at(m, "tip", 40), 2),
        "mouth_px_180": round(at(m, "mouth", 180), 2), "mouth_px_60": round(at(m, "mouth", 60), 2),
        "mouth_px_40": round(at(m, "mouth", 40), 2),
        "tightest_px_60": round(at(m, "tightest", 60), 2), "tightest_px_40": round(at(m, "tightest", 40), 2),
        "eye_px_180": round(at(m, "eye", 180), 2), "eye_px_60": round(at(m, "eye", 60), 2),
        "eye_px_40": round(at(m, "eye", 40), 2),
        "to_stem_px_60": round(at(m, "to_stem", 60), 2), "to_leaf_px_60": round(at(m, "to_leaf", 60), 2),
        "above_fork_of_tile": round(m["above_fork"] / 1024, 3),
        "coil_box_of_tile": [round(v / 1024, 3) for v in m["coil_box"]],
    }
    return row


def main():
    for folder, label, amount, dials in COILS:
        write_coil(folder, label, amount, dials)
    out = {"t2": report("t2", coiled(T2_COIL))}
    out["t2"].update(T.measure_icon(T2_ICON))
    base = max(out["t2"]["coil_box_of_tile"])
    for folder, label, amount, dials in COILS:
        out[folder] = report(folder, coiled(dials))
        out[folder].update(T.measure_icon(HERE / folder / "icon-1024.svg", coiled(dials)))
    for k, r in out.items():
        r["coil_box_vs_t2"] = round(max(r["coil_box_of_tile"]) / base, 2)
        print(f"{k:3s} turns {r['turns']:.2f}  r {r['r_out_units']:.0f}→{r['r_in_units']:.0f} "
              f"({r['r_in_strokes']} strokes, ×{r['growth_per_turn']}/turn)  coil ×{r['coil_box_vs_t2']}  "
              f"tip {r['tip_px_60']}/{r['tip_px_40']}  mouth {r['mouth_px_180']}/{r['mouth_px_60']}/{r['mouth_px_40']}  "
              f"tightest {r['tightest_px_60']}/{r['tightest_px_40']}  eye {r['eye_px_180']}/{r['eye_px_60']}/{r['eye_px_40']}  "
              f"stem {r['to_stem_px_60']} leaf {r['to_leaf_px_60']} above fork {r['above_fork_of_tile']}  "
              f"median {r['stroke_colour']} box {r['ink_box_w']}×{r['ink_box_h']} area {r['ink_area']} "
              f"leaf share {r['accent_share']}")
    small_base = analyse(coiled(T2_COIL), small=True, taper=None)["coil_box"][0]
    for name, dials in (("small, round two", ROUND_TWO_SMALL), ("small, tried", SMALL_TRIED)):
        m = analyse(coiled(T2_COIL, dials), small=True, taper=None)
        out[name] = {s: {"mouth_px": round(at(m, "mouth", s), 2), "tightest_px": round(at(m, "tightest", s), 2),
                         "eye_px": round(at(m, "eye", s), 2), "stroke_px": round(at(m, "stroke", s), 2),
                         "above_fork_px": round(at(m, "above_fork", s), 2)}
                     for s in (16, 32, 48)}
        out[name]["dials"] = dials
        out[name]["coil_width_vs_round_two"] = round(m["coil_box"][0] / small_base, 2)
        print(name, out[name])
    (HERE / "coil-measurements.json").write_text(json.dumps(out, indent=2, default=float) + "\n")
    print("compare", coil_compare())
    print("suite row", coil_suite_row())
    f, label, amount, _ = next(c for c in COILS if c[0] == RECOMMENDED)
    print(f, "in context", T.in_context(f, label, amount, name=f"D-suite T2 with more curl, {NAMES[f]}"))
    print("small sizes", coil_small_sizes())


if __name__ == "__main__":
    main()
