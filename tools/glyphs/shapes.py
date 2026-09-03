"""The four stage-row marks, transcribed from Swift into SVG path data.

`SeedGlyph`, `GardenGlyph` and `CogShape` live in `App/PeaceGarden/Views/Chrome.swift`;
`MeetGlyph` is in `Views/Glyphs.swift`. **Swift is authoritative.** This is a
mirror, kept so the marks can be rendered and looked at without a simulator —
the same bargain `tools/preview` makes for the plant, and it will drift the same
way.

Everything is emitted in a 15 x 15 box, because fifteen points is the size the
row actually draws them at, and every failure any of them has had has been a
failure at that size rather than at any other. The four are **not** one size
within that box: `SCALE` mirrors `markBox` in `Chrome.swift`.

    python3 tools/glyphs/sheet.py --out out/marks.png
"""

import math

SIDE = 15.0
STROKE = 1.2


def _box(side, d=0.9):
    return d, d, side - 2 * d, side - 2 * d


def _poly(points, move=True):
    head = "M" if move else "L"
    return f"{head} {points[0][0]:.3f} {points[0][1]:.3f} " + " ".join(
        f"L {x:.3f} {y:.3f}" for x, y in points[1:]
    )


# --- Seed -------------------------------------------------------------------

def seed(side=SIDE, tilt=20.0):
    """Nearly an oval: one end a little drawn, the other a little fuller.

    **The taper was the whole fault.** Run the point over most of the height and
    the mark is a water drop, or a flame, or a leaf — everything except a seed.
    A real seed is barely pointed. So the crown's controls sit only a third of
    the way down and close to the axis, which turns the tip without drawing it
    out, and the foot's sit wide and low, which keeps it round.
    """
    w = min(side, side / 1.30)
    x = side / 2 - w / 2 + 0.9
    y, h = 0.9, side - 1.8
    w -= 1.8
    mid, top, bot = x + w / 2, y, y + h
    def outline(t):
        """The left flank, crown to foot, as the outline actually draws it."""
        p0, c1 = (mid, top), (mid - w * 0.34, y + h * 0.17)
        c2, p1 = (x - w * 0.16, bot), (mid, bot)
        u = 1 - t
        return tuple(
            u ** 3 * p0[i] + 3 * u * u * t * c1[i] + 3 * u * t * t * c2[i] + t ** 3 * p1[i]
            for i in (0, 1)
        )

    # **The shading is an offset of the curve beside it, computed rather than
    # eyeballed.** Drawn by hand it was a chord across the corner: near the
    # outline at one end, far from it at the other, which reads as a crack
    # rather than as a near side. Sampling the flank and stepping in along its
    # own normal keeps the gap constant, which is the whole of what makes it
    # look like a surface turning away.
    shade, inset = [], w * 0.135
    for k in range(9):
        t = 0.54 + 0.22 * k / 8
        px, py = outline(t)
        qx, qy = outline(t + 0.006)
        dx, dy = qx - px, qy - py
        length = math.hypot(dx, dy) or 1.0
        nx, ny = -dy / length, dx / length
        # Of the two normals, take whichever ends up nearer the inside of the
        # shape. Guessing the sign from which flank this is fails at the foot,
        # where the curve turns through the vertical and the flanks swap.
        heart = (mid, y + h * 0.55)
        a = (px + nx * inset, py + ny * inset)
        b = (px - nx * inset, py - ny * inset)
        shade.append(a if math.dist(a, heart) < math.dist(b, heart) else b)

    d = (
        f"M {mid} {bot} "
        f"C {x + w * 1.16} {bot}, {mid + w * 0.34} {y + h * 0.17}, {mid} {top} "
        f"C {mid - w * 0.34} {y + h * 0.17}, {x - w * 0.16} {bot}, {mid} {bot} Z "
        + _poly(shade)
    )
    return [(d, f"rotate({tilt} {side / 2} {side / 2})")]


# --- Meet -------------------------------------------------------------------

def meet(side=SIDE):
    """Two stems crossing twice, and each ends as a different growing thing.

    **Twice is what makes it a meeting rather than a junction.** One crossing is
    an X, and an X is a letter. Two is two things that grew near one another,
    leant through, and came back.

    The lens between the crossings is given room deliberately. Drawn tight the
    two strokes read as one thick line with a nick in it at fifteen points; open,
    the eye sees two stems and the space they make between them.

    Both ends coil inward, the way the app mark and `Tendril` coil. An arch
    over into a hanging leaf was a wilt: the eye takes the direction of a tip
    before it takes anything else.
    """
    x, y, w, h = _box(side)

    def at(u, v):
        return x + w * u, y + h * v

    p = []

    # The left stem: bows right through both crossings, then curls inward at
    # the top. **A stem that arches over and hangs a leaf downward is wilted**,
    # whatever else it is doing — the eye reads the direction of the tip before
    # it reads anything else. Coiled inward it is a stem that is still going.
    coil_l = []
    for step in range(21):
        along = step / 20
        r = (w * 0.105 / 3.4) * (3.4 ** along)
        a = 1.15 + 3.5 * along
        coil_l.append((at(0.315, 0.150)[0] + r * math.cos(a),
                       at(0.315, 0.150)[1] + r * math.sin(a)))
    coil_l.reverse()
    p.append("M %.3f %.3f C %.3f %.3f, %.3f %.3f, %.3f %.3f" % (
        *at(0.24, 1.00), *at(0.72, 0.78), *at(0.74, 0.40), *at(0.50, 0.20)))
    p.append("C %.3f %.3f, %.3f %.3f, %.3f %.3f" % (
        *at(0.44, 0.14), coil_l[0][0] + w * 0.03, coil_l[0][1] + h * 0.03,
        *coil_l[0]))
    p.append(_poly(coil_l[1:], move=False))

    # The right stem: bows left through both crossings, then runs on and coils.
    p.append("M %.3f %.3f C %.3f %.3f, %.3f %.3f, %.3f %.3f" % (
        *at(0.76, 1.00), *at(0.28, 0.78), *at(0.26, 0.42), *at(0.56, 0.24)))
    cx, cy = at(0.640, 0.150)
    coil = []
    for step in range(21):
        along = step / 20
        r = (w * 0.125 / 3.6) * (3.6 ** along)
        a = 2.1 + 3.6 * along
        coil.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    p.append(_poly(list(reversed(coil)), move=False))
    return [(" ".join(p), None)]


# --- Garden -----------------------------------------------------------------

# The three blades, as start, two handles and end, in fractions of the box. The
# middle one stands; the outer two lean away from it and stop shorter, so the
# tuft has a silhouette rather than a top edge.
GRASS = [
    ((0.70, 1.00), (0.665, 0.76), (0.625, 0.58), (0.585, 0.40)),
    ((0.70, 1.00), (0.715, 0.72), (0.725, 0.46), (0.715, 0.20)),
    ((0.70, 1.00), (0.750, 0.76), (0.815, 0.60), (0.865, 0.46)),
]


def garden(side=SIDE):
    """Two plants: a five-petal flower, and a tuft of grass beside it.

    Three stems with different things stuck on their ends was three squiggles.
    **Two plants that a reader can name is worth more than three that read as
    marks**, and at fifteen points two is what there is room for anyway.

    The flower is drawn as an outline rather than as petals radiating from a
    centre, because radiating strokes at this size are a sun however few of them
    there are.

    **The grass is three blades, because a seed head cannot be drawn at this
    size.** It was a thirteen-turn zigzag, and the arithmetic was never going to
    work: thirteen turns across the box is 0.55pt a turn, under a stroke 1.2pt
    wide. A stroke twice the size of the feature it is drawing fills the gaps in,
    so what came out was a threaded rod — a screw, or a comb, and the one mark in
    the set whose subject could not be recovered without its word. Five larger
    turns were tried and read as a lightning bolt; a leaf on a stem merged into a
    mitten; a closed bud read well but rhymed with the seed mark two places along
    the row.

    Blades carry no feature smaller than the stroke, which is the whole point.
    Three rather than two: two splay from one foot and the near one parallels the
    flower's stem, which puts three uprights side by side and is the colonnade
    this mark was drawn to get away from.

    It costs ink — 30.6% of the frame against the zigzag's 27.6%, measured at
    fifteen points, which makes this the heaviest mark in the row ahead of the
    cog's 28.7%. Separated strokes read lighter than that number suggests, where
    the zigzag merged into a solid bar and read heavier than its own.
    """
    x, y, w, h = _box(side)

    def at(u, v):
        return x + w * u, y + h * v

    p = []

    # The flower: five lobes on one closed outline, and a stem under it.
    cx, cy = at(0.33, 0.30)
    tip, valley = w * 0.20, w * 0.075
    for k in range(5):
        a0 = -math.pi / 2 + k * 2 * math.pi / 5
        a1 = a0 + 2 * math.pi / 5
        vs = a0 - math.pi / 5
        ve = a1 - math.pi / 5
        start = (cx + valley * math.cos(vs), cy + valley * math.sin(vs))
        end = (cx + valley * math.cos(ve), cy + valley * math.sin(ve))
        lift = tip * 1.42
        c1 = (cx + lift * math.cos(a0 - 0.40), cy + lift * math.sin(a0 - 0.40))
        c2 = (cx + lift * math.cos(a0 + 0.40), cy + lift * math.sin(a0 + 0.40))
        if k == 0:
            p.append("M %.3f %.3f" % start)
        p.append("C %.3f %.3f, %.3f %.3f, %.3f %.3f" % (*c1, *c2, *end))
    p.append("Z")
    p.append("M %.3f %.3f C %.3f %.3f, %.3f %.3f, %.3f %.3f" % (
        *at(0.37, 1.00), *at(0.36, 0.76), *at(0.32, 0.66), *at(0.33, 0.50)))

    # The grass: three blades out of one foot, each a single curve.
    for a, b, c, d in GRASS:
        p.append("M %.3f %.3f C %.3f %.3f, %.3f %.3f, %.3f %.3f"
                 % (*at(*a), *at(*b), *at(*c), *at(*d)))

    # The bed, under their feet only.
    p.append("M %.3f %.3f L %.3f %.3f" % (*at(0.25, 1.00), *at(0.79, 1.00)))
    return [(" ".join(p), None)]


# --- Settings ---------------------------------------------------------------

def cog(side=SIDE, teeth=7, steps=15):
    """A cog, and recognisably the ordinary one.

    Six teeth rather than eight, because at fifteen points the gap between teeth
    is what fails first and six buys a third more of it. The tooth profile is a
    flattened cosine — `tanh` of it — which gives square-ish tops and roots with
    quick flanks and no corners anywhere, so it reads as a gear without putting
    a right angle in an app that has none.

    An odd number of teeth, so no tooth sits opposite another and the mark has
    no mirror line through it.
    """
    c = side / 2
    half = side / 2 - 0.9
    tip, root = half, half * 0.70
    mid, amp = (tip + root) / 2, (tip - root) / 2

    # **Phased so a tooth stands at the top.** The profile is measured from
    # twelve o'clock rather than from the x axis, which put the top of the mark
    # halfway up a flank — arbitrary, and it looked it. With an odd number of
    # teeth a peak at the top forces a trough exactly at the bottom, so the mark
    # has one spoke straight up and the notch between the two lowest directly
    # under it, and no mirror line anywhere.
    ring = []
    for step in range(teeth * steps + 1):
        phase = 2 * math.pi * step / (teeth * steps)
        a = phase - math.pi / 2
        r = mid + amp * math.tanh(2.6 * math.cos(teeth * phase))
        ring.append((c + r * math.cos(a), c + r * math.sin(a)))
    bore = root * 0.52
    return [(
        _poly(ring) + " Z "
        + f"M {c - bore:.3f} {c:.3f} a {bore:.3f} {bore:.3f} 0 1 0 {2 * bore:.3f} 0 "
          f"a {bore:.3f} {bore:.3f} 0 1 0 {-2 * bore:.3f} 0",
        None,
    )]


def _sized(fn, k):
    """Draw a mark into a centred sub-box of its frame.

    **The four are not one size.** A cog fills its square corner to corner and a
    seed is a small closed shape, so at equal frames the cog swamps everything
    beside it. Sized by what each one has to say instead: the garden is two
    plants and carries the most, the meeting and the cog sit between, and the
    seed is the smallest thing in the app and looks it.

    The stroke does not scale — it is applied by the renderer at one width — so
    a smaller mark is a lighter mark as well as a shorter one, which is the
    second half of why this works.
    """
    def sized(side=SIDE, **kw):
        inner = side * k
        shift = (side - inner) / 2
        out = []
        for path, transform in fn(inner, **kw):
            move = f"translate({shift:.3f} {shift:.3f})"
            out.append((path, f"{move} {transform}" if transform else move))
        return out
    return sized


SCALE = {"Seed": 0.70, "Meet": 0.88, "Garden": 1.00, "Settings": 0.84}

CANDIDATES = [
    ("Seed", _sized(seed, SCALE["Seed"])),
    ("Meet", _sized(meet, SCALE["Meet"])),
    ("Garden", _sized(garden, SCALE["Garden"])),
    ("Settings", _sized(cog, SCALE["Settings"])),
]


if __name__ == "__main__":
    import os
    import sys
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import sheet
    sheet.sheet(CANDIDATES, sys.argv[1] if len(sys.argv) > 1 else "out/candidates.png")
