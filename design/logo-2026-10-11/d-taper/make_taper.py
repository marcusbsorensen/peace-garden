#!/usr/bin/env python3
"""
Peace Garden logo, round two and a half, 11 October 2026: D-suite with
tapers. Design exploration only; nothing here touches a live asset.

  python3 design/logo-2026-10-11/d-taper/make_taper.py

Marcus chose D-suite (round two's D, Meeting, at the suite's median stroke of
0.0654 of the tile, the sage → moss → green-gold ramp, the leaf a warm white
outline). He then asked for two tapers:

  coil  the crozier keeps the full stroke where it leaves the fork and thins
        as it winds inward, ending in a thinner round end at the coil's eye
  stem  the tall stem thins slightly towards the leaf, so the leaf reads
        chunkier than the stem just below it

The root stays at the full 0.0654, every end stays round, every line is still
integrated from a heading by round two's `meeting()`, and there is no ground
line. Nothing in round two is copied: the geometry, placement, colour, file
set and sheets all come from `make_logos.py` and `make_sheets.py`. This file
adds only the width profile and the outline that carries it.

How a tapered line is drawn. A stroke-width cannot vary, so each tapered line
is a filled outline: the centreline is resampled evenly, offset by half the
local width on both sides (on the envelope of the circles, so the sides stay
tangent to the round ends), closed by exact circular arcs at the local width,
and filled with round two's one even gradient sweep, its vector computed by
round two's own `bounds()`. The colour at every point is therefore unchanged.
The leaf stays a stroke.

The width profile is a smoothstep (3u² − 2u³), zero slope at both ends, so
the thinning starts without a kink at the fork and arrives at the tip without
a pointed wedge. One strength parameter, `tau`, sets both tapers, as
`suite-brand.md` §3.2a(3) asks: the coil's tip thins to 1 − tau of the base
stroke and the stem's neck to 1 − STEM_SHARE × tau.

  pip install cairosvg pillow numpy scipy
"""

import io
import json
import math
import sys
import tempfile
from contextlib import contextmanager
from dataclasses import dataclass
from pathlib import Path

HERE = Path(__file__).resolve().parent
R2 = HERE.parent
sys.path.insert(0, str(R2))

import cairosvg                       # noqa: E402
import numpy as np                    # noqa: E402
from PIL import Image, ImageDraw      # noqa: E402

import make_logos as ML               # noqa: E402
import make_sheets as MS              # noqa: E402
import measure as ME                  # noqa: E402

R1 = MS.R1
# Round one's sheets ask for Inter, which the cloud machine had; fall back to
# the system's sans so the labels are not drawn in Pillow's 10 px default.
for _f in (R1.FONT, "/System/Library/Fonts/SFNS.ttf",
           "/System/Library/Fonts/Helvetica.ttc", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"):
    if Path(_f).exists():
        R1.FONT = _f
        break

# ------------------------------------------------------------------ dials

# The brief's starting pairs (stem neck, coil tip) were 0.85/0.55, 0.75/0.42
# and 0.65/0.30. Fitted to one parameter through T2's pair, T1's neck lands at
# 0.81 and T3's at 0.70; the coil tips are as briefed.
STEM_SHARE = 0.43    # the stem's neck thins by this share of the coil's taper
SMALL = None         # the small drawing (16, 32 and 48 px): untapered, §3.2a(5)


@dataclass(frozen=True)
class Taper:
    tau: float                      # the one strength parameter
    leaf: float = ML.LEAF_WEIGHT    # the leaf's stroke against the stem's base
    stem_share: float = STEM_SHARE

    @property
    def coil_end(self):
        return 1 - self.tau

    @property
    def stem_end(self):
        return 1 - self.stem_share * self.tau

    @property
    def contrast(self):
        """§3.2a(2): thickest ÷ thinnest."""
        return 1 / self.coil_end


STRENGTHS = [
    # (folder, label, word, taper)
    ("t1", "T1", "gentle", Taper(0.45)),
    ("t2", "T2", "medium", Taper(0.58)),
    ("t3", "T3", "strong", Taper(0.70)),
]
ROUND_TWO = R2 / "d-suite" / "icon-1024.svg"
STEP = 0.2           # outline sample spacing, as a share of the base stroke


def smoothstep(u):
    u = np.clip(u, 0.0, 1.0)
    return u * u * (3 - 2 * u)


# ---------------------------------------------------------------- outline

def _arclength(p):
    return np.concatenate([[0.0], np.cumsum(np.hypot(*np.diff(p, axis=0).T))])


def _resample(p, step):
    s = _arclength(p)
    n = max(3, int(math.ceil(s[-1] / step)) + 1)
    t = np.linspace(0.0, s[-1], n)
    return np.column_stack([np.interp(t, s, p[:, 0]), np.interp(t, s, p[:, 1])]), t


def _arc(p0, p1, r, large, sweep):
    return (f"A{r:.2f} {r:.2f} 0 {int(large)} {int(sweep)} "
            f"{p1[0]:.2f} {p1[1]:.2f}")


def outline(pts, width_at, step):
    """A tapered line as a closed outline. `width_at(u)` gives the full width
    at the fraction `u` of the line's length. The sides lie on the envelope of
    the circles of that width along the centreline, so each round end is a
    true circle tangent to both sides; the sides are Catmull–Rom curves
    (round one's `path_d`) and the ends SVG arcs."""
    p, s = _resample(np.asarray(pts, float), step)
    r = width_at(s / s[-1]) / 2
    t = np.gradient(p, axis=0)
    t /= np.hypot(t[:, 0], t[:, 1])[:, None]
    n = np.column_stack([-t[:, 1], t[:, 0]])
    dr = np.gradient(r, s)
    q = np.sqrt(np.clip(1 - dr ** 2, 0, 1))
    a = p + r[:, None] * (-dr[:, None] * t + q[:, None] * n)
    b = p + r[:, None] * (-dr[:, None] * t - q[:, None] * n)
    span_end = 2 * math.atan2(q[-1], -dr[-1])            # the tip's cap
    span_start = 2 * math.pi - 2 * math.atan2(q[0], -dr[0])  # the root's cap
    side_a = ML.path_d([tuple(v) for v in a], False)
    side_b = ML.path_d([tuple(v) for v in b[::-1]], False)
    return (side_a + _arc(a[-1], b[-1], r[-1], span_end > math.pi, 0)
            + side_b[side_b.index("C"):] + _arc(b[0], a[0], r[0], span_start > math.pi, 0) + "Z")


def profiles(strokes, stroke, taper):
    """Width along each line, as functions of the fraction of its length.
    The stem is full from the root to the fork, then eases to its neck; the
    crozier is full at the fork and eases to its tip."""
    crozier, stem = np.asarray(strokes[0][0]), np.asarray(strokes[1][0])
    fork = int(np.argmin(np.hypot(*(stem - crozier[0]).T)))
    s = _arclength(stem)
    u_fork = s[fork] / s[-1]

    def stem_w(u):
        return stroke * (1 - (1 - taper.stem_end) * smoothstep((u - u_fork) / (1 - u_fork)))

    def coil_w(u):
        return stroke * (1 - (1 - taper.coil_end) * smoothstep(u))

    return coil_w, stem_w, u_fork


def tapered_body(strokes, stroke, stops, leaf, gid, one, taper):
    """Round two's `body()`, with the two stems as tapered fills. The gradient
    vector is round two's, from its own `bounds()`, so the colour does not
    move."""
    x0, y0, x1, y1 = ML.bounds(strokes, stroke, stroke * ML.LEAF_WEIGHT)
    defs = ""
    if one is None:
        st = "".join(f'<stop offset="{i / (len(stops) - 1):g}" stop-color="{c}"/>'
                     for i, c in enumerate(stops))
        defs = (f'<defs><linearGradient id="{gid}" gradientUnits="userSpaceOnUse" '
                f'x1="{x0:.2f}" y1="{y1:.2f}" x2="{x1:.2f}" y2="{y0:.2f}">{st}</linearGradient></defs>')
    paint = one or f"url(#{gid})"
    coil_w, stem_w, _ = profiles(strokes, stroke, taper)
    out = []
    for (pts, role, closed), width_at in zip(strokes, (coil_w, stem_w, None)):
        if role == "stem":
            out.append(f'<path d="{outline(pts, width_at, STEP * stroke)}" fill="{paint}"/>')
        else:
            out.append(f'<path d="{ML.path_d(ML.thin(pts, 3), closed)}" fill="none" '
                       f'stroke="{one or leaf}" stroke-width="{stroke * taper.leaf:.2f}" '
                       f'stroke-linecap="round" stroke-linejoin="round"/>')
    return defs, "<g>" + "".join(out) + "</g>"


def taper_drawing(taper, small_taper=SMALL):
    """A stand-in for round two's `drawing()`: the same placement, with the
    tapered body. `small_taper` None draws round two's small drawing as it
    was, untapered."""
    def drawing(draw, small, box, stroke_frac, stops, leaf, one=None, gid="g"):
        placed, stroke = ML.place(draw(small), box, stroke_frac)
        t = small_taper if small else taper
        if t is None:
            return ML.body(placed, stroke, stops, leaf, gid, one)
        return tapered_body(placed, stroke, stops, leaf, gid, one, t)
    return drawing


@contextmanager
def patched(module, **attrs):
    old = {k: getattr(module, k) for k in attrs}
    for k, v in attrs.items():
        setattr(module, k, v)
    try:
        yield
    finally:
        for k, v in old.items():
            setattr(module, k, v)


def write_strength(folder, label, word, taper, draw=None, prefix=None, title=None):
    """Round two's `write_candidate()`, unchanged, with the tapered drawing
    patched in. It writes into a scratch folder named for the prefix, and the
    files move into `d-taper/<folder>/`. `draw` stands in for round two's
    `meeting()` (`make_coil.py` passes one with more curl)."""
    prefix = prefix or f"d-taper-{folder}"
    title = title or f"D-suite with taper {label} ({word})"
    out = HERE / folder
    out.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        with patched(ML, HERE=Path(tmp), drawing=taper_drawing(taper)):
            ML.write_candidate(prefix, title, draw or ML.meeting, "suite")
        for f in sorted((Path(tmp) / prefix).iterdir()):
            (out / f.name).write_text(f.read_text())
    return out


# ------------------------------------------------------------ the 1024 frame

def icon_frame(small=False, draw=None):
    """The drawing placed as `write_candidate()` places the app icon."""
    h = ML.INK_HEIGHT * 1024
    box = ((1024 - h) / 2, (1024 - h) / 2, h, h)
    return ML.place((draw or ML.meeting)(small), box, ML.TILE_STROKE["suite"] / ML.INK_HEIGHT)


def eye(taper, size):
    """The coil's eye at `size` px. Returns (clear radius, mouth gap) in px:
    the clear radius is from the coil's centre of curvature at its tip to the
    nearest ink; the mouth gap is from the tip's round end to the nearest
    other ink, leaving out the tip's own last two strokes of length. Both
    must stay above about a pixel at 60."""
    placed, stroke = icon_frame()
    k = size / 1024
    crozier = np.asarray(placed[0][0]) * k
    stem = np.asarray(placed[1][0]) * k
    leaf = np.asarray(placed[2][0]) * k
    stroke *= k
    tp = taper or Taper(0.0)
    coil_w, stem_w, _ = profiles([(crozier, "", 0), (stem, "", 0)], stroke, tp)
    wc = coil_w(_arclength(crozier) / _arclength(crozier)[-1])
    ws = stem_w(_arclength(stem) / _arclength(stem)[-1])
    # The coil's centre of curvature at its tip: round two's `curl` ends at
    # radius r_in (16 of its units), turning clockwise on screen, so the
    # centre lies to the right of the direction of travel.
    tip, prev = crozier[-1], crozier[-6]
    tdir = (tip - prev) / np.hypot(*(tip - prev))
    scale = _arclength(crozier)[-1] / _arclength(np.asarray(ML.meeting(False)[0][0]))[-1]
    centre = tip + 16 * scale * np.array([-tdir[1], tdir[0]])
    s = _arclength(crozier)
    far = s < s[-1] - 2.0 * stroke   # leave out the tip's own last stretch
    pts = np.vstack([crozier, stem, leaf])
    ws_all = np.concatenate([wc, ws, np.full(len(leaf), stroke * tp.leaf)])
    clear = float(np.min(np.hypot(*(pts - centre).T) - ws_all / 2))
    other = np.concatenate([far, np.ones(len(stem) + len(leaf), bool)])
    gap = float(np.min(np.hypot(*(pts[other] - tip).T) - ws_all[other] / 2) - wc[-1] / 2)
    return clear, gap


# ------------------------------------------------------------- measurement

def render_svg(svg_text, size, bg=None):
    png = cairosvg.svg2png(bytestring=svg_text.encode(), output_width=size, output_height=size,
                           background_color=bg)
    return Image.open(io.BytesIO(png)).convert("RGBA")


def measure_icon(path, draw=None):
    """Round two's `measure()` on the rendered icon, plus the stroke at the
    root: round two's `widths()` on the ink between the root and the fork."""
    png = cairosvg.svg2png(url=str(path), output_width=1024)
    m = ME.measure(io.BytesIO(png))
    rgb = np.asarray(Image.open(io.BytesIO(png)).convert("RGB")).astype(float)
    ink = np.abs(rgb - ME.ground_of(rgb)).sum(axis=2) > 90
    # Below the fork only the stem is drawn (the crozier's round start sits
    # inside it), so this band is the root's stroke and nothing else.
    placed, _ = icon_frame(draw=draw)
    fork_y = float(np.asarray(placed[0][0])[0][1])
    band = np.zeros_like(ink)
    band[int(math.ceil(fork_y)):] = True
    w = ME.widths(ink & band)
    m["stroke_root"] = round(w[0] / 1024, 4)
    return m


# -------------------------------------------------------------------- sheets

def crop_boxes():
    """Where to look at 1024: the coil, the stem meeting the leaf, the fork."""
    placed, stroke = icon_frame()
    crozier, stem = np.asarray(placed[0][0]), np.asarray(placed[1][0])
    coil = crozier[-180:]
    cc = (coil.min(axis=0) + coil.max(axis=0)) / 2
    neck = stem[-1] + np.array([-30.0, 30.0])
    fork = crozier[0] + np.array([15.0, -90.0])
    return {"coil": cc, "neck": neck, "fork": fork}


def crop(path, centre, size=400):
    im = R1.render(path, 1024)
    x, y = (int(round(v - size / 2)) for v in centre)
    x = min(max(x, 0), 1024 - size)
    y = min(max(y, 0), 1024 - size)
    return im.crop((x, y, x + size, y + size))


def columns():
    cols = [("D-suite, round two", ROUND_TWO)]
    cols += [(f"{lab} {word}", HERE / f / "icon-1024.svg") for f, lab, word, _ in STRENGTHS]
    return cols


def compare(cols=None, crops=None, out=None,
            title="D-suite with tapers: round two's untapered D-suite beside T1, T2 and T3"):
    """`cols` is [(name, icon path)]; `crops` is [(caption, [centre per column])]."""
    cols = cols or columns()
    cw = 420
    W = 40 + cw * len(cols) + 20
    band_h = 600
    if crops is None:
        boxes = crop_boxes()
        crops = [(text, [boxes[key]] * len(cols)) for key, text in (
            ("coil", "The coil at 1024 px, 1:1"), ("neck", "The stem meeting the leaf at 1024 px, 1:1"),
            ("fork", "The fork at 1024 px, 1:1: the crozier's fill over the stem's, one gradient"))]
    H = 130 + 2 * band_h + 330 + len(crops) * 440
    sheet = Image.new("RGBA", (W, H), MS.SHEET_BG)
    dr = ImageDraw.Draw(sheet)
    MS.label(dr, (40, 24), title, 30)
    MS.label(dr, (40, 66), "360, 180 and 60 px under the iOS mask, on the home screen's dark (#1C1C1E) and "
                           "light (#F2F2F7) grounds; then 60 px enlarged 4×, nearest neighbour; then 1:1 crops "
                           "of the 1024 px icon", 17)
    for i, (name, path) in enumerate(cols):
        dr.text((40 + i * cw + 190, 104), name, fill=R1.LABEL, font=MS.font(20), anchor="ma")
    for band, (bg, ink) in enumerate(((MS.HOME_DARK, (235, 235, 240)), (MS.HOME_LIGHT, (40, 40, 45)))):
        y0 = 136 + band * band_h
        sheet.alpha_composite(Image.new("RGBA", (W - 60, band_h - 20), bg), (30, y0))
        for i, (name, path) in enumerate(cols):
            x = 40 + i * cw + 10
            sheet.alpha_composite(MS.icon(path, 360), (x, y0 + 16))
            sheet.alpha_composite(MS.icon(path, 180), (x, y0 + 392))
            sheet.alpha_composite(MS.icon(path, 60), (x + 230, y0 + 512))
    y0 = 136 + 2 * band_h
    MS.label(dr, (40, y0), "60 px, enlarged 4× (nearest neighbour): what a phone actually lights")
    for i, (name, path) in enumerate(cols):
        im = MS.icon(path, 60)
        bg = Image.new("RGBA", (60, 60), MS.HOME_DARK)
        bg.alpha_composite(im)
        sheet.alpha_composite(bg.resize((240, 240), Image.NEAREST), (40 + i * cw + 10, y0 + 36))
        sheet.alpha_composite(bg, (40 + i * cw + 270, y0 + 216))
    for row, (text, centres) in enumerate(crops):
        y = 136 + 2 * band_h + 330 + row * 440
        MS.label(dr, (40, y), text)
        for i, (name, path) in enumerate(cols):
            sheet.alpha_composite(crop(path, centres[i]), (40 + i * cw + 10, y + 34))
    return MS.save(sheet, out or HERE / "compare.png")


def suite_row(pg=None, out=None, title="D-suite with tapers beside the suite: round two's D-suite, T1, T2 "
                                        "and T3, the five suite apps' real icons, then today's Peace Garden icon"):
    pg = pg or columns()
    cols = [(n, "svg", p) for n, p in pg]
    cols += [(n, "png", MS.ICONS / f) for n, f in MS.SUITE]
    cols += [("Peace Garden today", "svg", MS.CURRENT)]
    cw = 214
    W = 40 + cw * len(cols) + 20
    H = 120 + 2 * 420
    sheet = Image.new("RGBA", (W, H), MS.SHEET_BG)
    dr = ImageDraw.Draw(sheet)
    MS.label(dr, (40, 24), title, 30)
    MS.label(dr, (40, 66), "180 px and 60 px, on the iOS home screen's dark (#1C1C1E) and light (#F2F2F7) "
                           "grounds. FreqShift's only icon in its repository is a 162 px web logo, upscaled here.", 17)
    short = {"D-suite, round two": "D-suite", "Animal Rescue Centre": "A.R.C.", "Peace Garden today": "Today"}
    for band, (bg, ink) in enumerate(((MS.HOME_DARK, (235, 235, 240)), (MS.HOME_LIGHT, (40, 40, 45)))):
        y0 = 110 + band * 420
        sheet.alpha_composite(Image.new("RGBA", (W - 60, 400), bg), (30, y0))
        d = ImageDraw.Draw(sheet)
        for i, (name, kind, ref) in enumerate(cols):
            x = 40 + i * cw + (cw - 180) // 2
            if i in (len(pg), len(pg) + 5):  # hairlines around the suite
                d.line((40 + i * cw - 4, y0 + 20, 40 + i * cw - 4, y0 + 380), fill=(128, 128, 136), width=1)
            sheet.alpha_composite(MS.any_icon(kind, ref, 180), (x, y0 + 24))
            d.text((x + 90, y0 + 214), short.get(name, name), fill=ink, font=MS.font(17), anchor="ma")
            sheet.alpha_composite(MS.any_icon(kind, ref, 60), (x + 60, y0 + 262))
            d.text((x + 90, y0 + 330), short.get(name, name), fill=ink, font=MS.font(12), anchor="ma")
    return MS.save(sheet, out or HERE / "suite-row.png")


def in_context(folder, label, word, name=None):
    key = f"d-taper/{folder}"
    with patched(MS, NAMES={**MS.NAMES, key: name or f"D-suite, taper {label} ({word})"}):
        return MS.in_context(key)


def small_svg(taper, ground, meeting=None):
    """The favicon or the small drawing, with `taper` carried into it, as an
    SVG string (for the rejected rows of small-sizes.png). `meeting` stands
    in for round two's drawing."""
    stops, leaf = (ML.ramp(False), ML.LEAF) if ground != "light" else (ML.ramp(True), ML.INK)
    draw = taper_drawing(taper, small_taper=taper)
    meeting = meeting or ML.meeting
    if ground == "favicon":
        d, g = draw(meeting, True, (17, 13, 74, 74), ML.TILE_STROKE["suite"] / ML.INK_HEIGHT * 1.35,
                    stops, leaf)
        return ML.svg(100, 100, "favicon", d + f'<rect width="100" height="100" rx="22" fill="{ML.GROUND}"/>' + g)
    d, g = draw(meeting, True, (4, 4, 92, 92), ML.TILE_STROKE["suite"] / ML.INK_HEIGHT * 1.35, stops, leaf)
    return ML.svg(100, 100, "small", d + g)


def thinnest_px(taper, size, favicon=True):
    """The thinnest stem section of the small drawing at `size` px."""
    box = (17, 13, 74, 74) if favicon else (4, 4, 92, 92)
    _, stroke = ML.place(ML.meeting(True), box, ML.TILE_STROKE["suite"] / ML.INK_HEIGHT * 1.35)
    return stroke * size / 100 * (taper.coil_end if taper else 1.0)


SMALL_SIZES = (16, 32, 48)
SMALL_FILES = {"favicon": "-favicon", "dark": "-small", "light": "-small-light-ground"}


def small_sizes():
    rows = [("Chosen for T1, T2 and T3: untapered, round two's small drawing (§3.2a(5))", None)]
    rows += [(f"Not chosen: {lab}'s taper carried into the small drawing", t) for f, lab, _, t in STRENGTHS]
    sheet_rows = []
    for text, taper in rows:
        px = ", ".join(f"{s} px {thinnest_px(taper, s):.2f}" for s in SMALL_SIZES)
        if taper is None:
            def src(kind):
                return (HERE / "t2" / f"d-taper-t2{SMALL_FILES[kind]}.svg").read_text()
        else:
            def src(kind, taper=taper):
                return small_svg(taper, kind)
        sheet_rows.append((f"{text}.  Thinnest stroke on the favicon: {px} px", src))
    return small_sheet(
        sheet_rows, HERE / "small-sizes.png",
        "Small sizes: the favicon and the small drawing at 16, 32 and 48 px, "
        "enlarged 4× (nearest neighbour) with the true size beneath",
        "The small drawing is round two's, untapered, for every strength. The rows beneath "
        "show what each strength's taper would do if it were carried down.")


def small_sheet(rows, out, title, subtitle):
    """`rows` is [(caption, src(kind) → SVG text)], kind one of favicon, dark, light."""
    sizes = SMALL_SIZES
    groups = (("favicon", MS.HOME_DARK, "Favicon on a dark tab bar"),
              ("favicon", MS.HOME_LIGHT, "Favicon on a light tab bar"),
              ("dark", ML.GROUND, "Small drawing on #0D0D1F"),
              ("light", ML.LIGHT_GROUND, "Small drawing on #F6F6F6"))
    gw = 4 * sum(sizes) + 3 * 16 + 30
    W = 40 + gw * len(groups) + 10
    rh = 330
    H = 120 + rh * len(rows)
    sheet = Image.new("RGBA", (W, H), MS.SHEET_BG)
    dr = ImageDraw.Draw(sheet)
    MS.label(dr, (40, 24), title, 30)
    MS.label(dr, (40, 66), subtitle, 17)
    for r, (text, src_of) in enumerate(rows):
        y = 110 + r * rh
        MS.label(dr, (40, y), text, 18)
        for g, (kind, bg, gname) in enumerate(groups):
            x = 40 + g * gw
            MS.label(dr, (x, y + 30), gname, 15)
            src = src_of(kind)
            xx = x
            for s in sizes:
                im = render_svg(src, s)
                tile = Image.new("RGBA", (s, s), bg)
                tile.alpha_composite(im)
                sheet.alpha_composite(tile.resize((s * 4, s * 4), Image.NEAREST), (xx, y + 58 + (192 - s * 4)))
                sheet.alpha_composite(tile, (xx, y + 264))
                xx += s * 4 + 16
    return MS.save(sheet, out)


# ---------------------------------------------------------------------- main

def main():
    for folder, label, word, taper in STRENGTHS:
        write_strength(folder, label, word, taper)
    print(f"{'':10s} {'coil tip':>8s} {'stem neck':>9s} {'leaf':>5s} {'contrast':>8s}"
          f"  eye at 180: clear, gap px   eye at 60: clear, gap px")
    for name, taper in [("round two", None)] + [(lab, t) for _, lab, _, t in STRENGTHS]:
        tp = taper or Taper(0.0)
        c180, g180 = eye(taper, 180)
        c60, g60 = eye(taper, 60)
        print(f"{name:10s} {tp.coil_end:8.3f} {tp.stem_end:9.3f} {tp.leaf:5.2f} {tp.contrast:8.2f}"
              f"  {c180:6.2f} {g180:6.2f}               {c60:6.2f} {g60:6.2f}")
    meas = {"d-suite": measure_icon(ROUND_TWO)}
    for folder, label, word, taper in STRENGTHS:
        meas[folder] = measure_icon(HERE / folder / "icon-1024.svg")
        c60, g60 = eye(taper, 60)
        c180, g180 = eye(taper, 180)
        meas[folder].update(tau=taper.tau, coil_end=round(taper.coil_end, 3),
                            stem_end=round(taper.stem_end, 3), leaf=taper.leaf,
                            contrast=round(taper.contrast, 2),
                            eye_clear_px_180=round(c180, 2), eye_gap_px_180=round(g180, 2),
                            eye_clear_px_60=round(c60, 2), eye_gap_px_60=round(g60, 2))
    c60, g60 = eye(None, 60)
    c180, g180 = eye(None, 180)
    meas["d-suite"].update(eye_clear_px_180=round(c180, 2), eye_gap_px_180=round(g180, 2),
                           eye_clear_px_60=round(c60, 2), eye_gap_px_60=round(g60, 2))
    for k, m in meas.items():
        print(f"{k:8s} root {m['stroke_root']}  median {m['stroke_colour']}  "
              f"box {m['ink_box_w']}×{m['ink_box_h']}  area {m['ink_area']}  leaf share {m['accent_share']}")
    (HERE / "measurements.json").write_text(json.dumps(meas, indent=2) + "\n")
    print("compare", compare())
    print("suite-row", suite_row())
    for folder, label, word, _ in STRENGTHS:
        print(folder, "in-context", in_context(folder, label, word))
    print("small-sizes", small_sizes())


if __name__ == "__main__":
    main()
