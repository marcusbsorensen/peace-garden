# Peace Garden — brand record

Written 30 August 2026, when the app joined the Interfulgent suite.

The system is not Peace Garden's to define. It is
`uncubed-integration/docs/design/suite-brand.md`, and §3 of that document owns the
ground, the stroke treatment, the gradient and the hue allocation. **Read it before
changing anything here.** What follows is only what §4 leaves to each app — the
glyph, its geometry, and the numbers this app measured.

## The mark

**A fiddlehead: two fronds from one root, the tall one opening into a warm white
leaf, the other still a crozier, its coil carried above the fork and rolling
outward.** Chosen by Marcus on 11 October 2026, after two rounds of drawing
recorded in `design/logo-2026-10-11/README.md`: round two's D, *Meeting*, at the
suite's weight, with a growth taper (T2), half a turn more in the coil (C2), and
then a lower fork and an earlier taper on the crozier (variant A of "round two and
seven-eighths"). It replaced the unwinding spiral with a peace lily's spathe that
the app carried from 30 August.

Every line is a curve, integrated from a heading that varies smoothly along it.
There is no straight segment and no ground line, and the plant grows from a free
round end. Nothing in the crozier drops below the point it grew from.

The two fronds are drawn in the one gradient. The leaf is an outline in the
suite's warm white, `#F4F3EF`, at 0.72 of the stem's weight; it does not take the
gradient. **The taper follows growth**: each frond is thickest where it grows from
and thins towards its free end, and neither thickens again. The stem keeps its
full weight to just above the fork and eases to three-quarters of it where it
meets the leaf, so the leaf reads as the chunkiest thing in the mark. The crozier
starts thinning at the fork and is already lighter than the stem beside it by the
top of its rise, then winds into its coil and ends at 0.42 of the root.

### The white element, and the suite's habit of having one

Measured off the shipped artefacts rather than recalled:

| App | White element | How it relates to the gradient |
|---|---|---|
| **Pfish** | two bubble rings, **`#FFFFFF`**, at the fish's own stroke weight | separate elements, outside the sweep |
| **UnCubed** | the exponent finishing on **`#F4F3EF`** | not a separate element — the sweep's last stop |
| **Peace Garden** | the leaf, **`#F4F3EF`**, an outline at **0.72** of the stem's root | separate element, outside the sweep |

Peace Garden follows Pfish in setting the white apart from the gradient, because
the leaf is a distinct organ and not the end of the stem, and takes UnCubed's warm
white rather than `#FFFFFF`. Until 11 October its white was `#FFFFFF`, so the
suite had two whites in it; it now uses the warmer one, as UnCubed does.

The leaf runs **lighter than the stroke at the root**, and it is about 27.5 % of
the ink, above the suite's measured 17–24 %. That is the measurable form of what
Marcus asked for, a leaf that reads chunkier than the thinner line just below it.
At full weight the leaf's eye closes to a one-pixel slit at 60 px and the leaf
reads as a solid white shape; 0.85 and 1.0 were drawn and rejected for that.

### Where this stands against §3.5, which is the question anyone will ask

§3.5 says a mark may not depict what the app is *about*; it may depict what the app
*gives you*. **Which side of that line this mark falls on depends on how the app is
framed, and the framing moved while it was being drawn. Recorded, because the
argument matters more than the conclusion.**

- **Read as "the app is about a seed and what grows from it"**, every plant form is
  the forbidden case — a leaf, a shoot, a flower and a seed all become "a flag is a
  flag". This was the first reading taken here, and it is why the mark began on
  30 August as a bare spiral with no botany in it at all.
- **Read as "the app is about an encounter and the passage of time, and the plant is
  what it hands you in exchange"**, the plant sits exactly where Pfish's fish sits:
  the reward, not the subject. §3.5's own table admits Pfish on precisely that
  reasoning.

**The mark as drawn depends on the second reading**, more plainly than the spiral
did: a fiddlehead with a leaf is a plant. That reading is defensible and is the
owner's, but it is not the one §3.5's table records, and the two are not
interchangeable — so a reader who assumes the first will think this mark is a
breach. If the second reading is right, it belongs in §3.5's table beside Pfish's
row rather than being inferred from this document.

The crozier still carries something of the old argument: a frond uncurling is
unfolding over real time, which is the medium the app works in.

> **What was drawn first, and rejected.** A luminous flower on a pool of light:
> filled shapes with shading, a glow, a radial gradient ground, no stroke anywhere.
> It was drawn before this document had been read and it broke §3.1, §3.2, §3.3 and
> §3.5 at once. Recorded because it looked good, and looking good is exactly how a
> mark that is not in the system gets kept.

## Construction — 1024 × 1024, ground `#0D0D1F`

The drawing is built in construction units, 100 wide with y down and the root at
(50, 130), then placed so its ink stands **0.70** of the tile high, centred, the
suite's median fill. The ink measures **0.58 × 0.69** of the tile, about 210 px
clear to left and right and 155 px top and bottom.

| Dial | Value |
|---|---|
| Stroke at the root | **0.0654** of the tile, **66.97** rendered: the suite's median (Pfish 0.052 to Animal Rescue Centre 0.079) |
| Stem | **86** units, heading −90° − 0.08 − 0.36 s^1.5 + 0.12 sin(π s) |
| Fork | **14** of the stem's 120 steps up, lowered from round two's 22 |
| Crozier's rise | **52** units, heading −90° + 0.24 + 0.32 s |
| Crozier's coil | logarithmic, **1.35** turns, radius **27 → 10** units, entered on the rise's own heading |
| Leaf | **40** units long, half-width **0.32** of its length, profile sin(π s^0.85), turning **0.34** rad against the stem's lean |
| Leaf's stroke | **0.72** of the root, `#F4F3EF`, an outline, never a fill |
| Taper strength | **τ 0.58**: the crozier's tip at 1 − τ (**0.42**), the stem's neck at 1 − 0.43 τ (**0.75**) |
| Crozier's profile | ease-out from the fork, 1 − (1 − u)^**2.5** over its length |
| Stem's profile | full to **22/120** of its length, then smoothstep to its neck |

**How a taper is drawn.** A stroke-width cannot vary along a path, so each frond
is a filled outline: the centreline is resampled every 0.2 of the root's stroke,
offset by half the local width on both sides, on the envelope of the circles of
that width, and closed at each end by a circular arc, so each round end is tangent
to both sides. The sides are Catmull–Rom curves and the ends arcs, so nothing is
straight. The crozier's fill starts inside the stem's at the fork and both carry
the same gradient in the same coordinates, so the overlap cannot show.

### Widths and gaps, which are the thing that fails first

The generator measures and prints these; they are not eyeballed off a downsample.
The app ships one 1024 image and iOS scales it down, so 40 px (a notification on a
2× iPhone) is the smallest it is drawn.

| | On the tile | At 180 px | At 60 px | At 40 px |
|---|---|---|---|---|
| Stroke at the root | 67.0 u | 11.8 px | 3.9 px | 2.6 px |
| Stem's neck | 50.3 u | 8.8 px | 2.9 px | 2.0 px |
| Leaf's stroke | 48.2 u | 8.5 px | 2.8 px | 1.9 px |
| Crozier's tip | 28.1 u | 4.9 px | 1.6 px | 1.1 px |
| Coil's mouth, the tightest gap | 28.3 u | 5.0 px | 1.7 px | 1.1 px |

**The tightest gap is the coil's mouth**, from the tip's round end to the turn
outside it. **The tip stays at 0.42 of the root** because a thinner one falls under
a pixel at 40 px. At 40 px the inner turn and the one outside it blur into one
band in places; that was known and accepted when the coil was chosen.

**On weight against the rest of the suite.** The root holds the suite's median, so
the mark matches the suite where it is heaviest. The median stroke across the whole
drawing is about 0.034 of the tile, under the suite's measured 0.052–0.079,
because most of the crozier is thin; that is the lighter tendril Marcus asked for.
The ink area, 0.090 of the tile, is inside the suite's 0.09–0.14.

The fit is computed from the drawn bounds — the centrelines plus half the root's
stroke — and not typed. Changing a dial cannot silently break a relationship
somebody set on purpose.

## Colour

§3.4's segment for this app was allocated by the owner on 2026-08-30 and amended
within its own band on 2026-10-11: **sage → moss → green-gold**, calm where the
first ramp was neon. Three stops, bottom-left to top-right:

| Hue | Saturation | On `#0D0D1F` | Contrast | On `#F6F6F6` (the site's light ground) | Contrast |
|---|---|---|---|---|---|
| **124°** sage | 0.24 · 0.38 | `#9CC29E` | 9.71 : 1 | `#397E3D` | 4.60 : 1 |
| **98°** moss | 0.34 · 0.54 | `#9DC386` | 9.67 : 1 | `#467D25` | 4.60 : 1 |
| **76°** green-gold | 0.44 · 0.60 | `#A9C263` | 9.67 : 1 | `#60781E` | 4.62 : 1 |

The first saturation is the dark ramp's and the second the light one's. The leaf
is `#F4F3EF` on dark, 17.3 : 1, and the site's ink `#121212` on light, 17.3 : 1.

**Isoluminant at 9.7 : 1 on the ground**, to within the rounding of an 8-bit colour.
Lightness is solved per stop against a luminance target rather than chosen, which
is what holds the triad level across hues of very different natural brightness;
eyeballing it is how a sweep becomes a value staircase in greyscale. The 13 : 1 of
the first ramp was set to keep yellow at full chroma, which a calm ramp no longer
wants.

**Both ends were moved to clear a neighbour, and measured.** The top stops at 76°,
not 60°: a 60° straw at this saturation was ΔE2000 14.2 from FlagFans' `#F0C24E`,
and 76° is 19.5. The bottom starts at 124°, not 140°, which widens the clearance
under Pfish's 150° from 10° to 26°. Peace Garden is now the least saturated mark in
the suite.

**On light, 4.6 : 1 rather than 9.7 : 1**, because on a near-white ground 9.7 : 1 is
nearly black and the stops would lose their hue to reach it. 4.6 clears WCAG's 4.5
for text with a little to spare. Saturation is lifted on light so the darker stops
keep their hue. Only the site's bare mark is drawn on light; the icon carries its
own ground.

An even sweep, because the fronds are one continuous run of colour: §3.3's rule
about putting the transitions in the gaps applies to marks made of separate
elements. The sweep spans the whole drawing's ink box as round two measured it, so
the colour does not move with the taper; the measured hue band on the icon is
86°–110°.

## Sizes

One drawing covers every app-icon size down to 40 px. The ground travels with the
mark, so there is no light and dark pair and no tinted variant — matching
`ui-design-system.md` §10.4 — and the asset catalogue has one 1024 entry.

**Below 48 px the mark is a second drawing, untapered**, as §3.2a(5) requires of
modulated marks: below about 24 px the thin end nears a device pixel and the line
reads as broken. Carried down, the crozier's tip would be 0.63 px on a 16 px
favicon. The small drawing is round two's: the same figure, 1.35 times heavier,
with a fatter leaf and less coil, forking where round two forked. Its stroke is
1.5 px at 16, 3.0 at 32 and 4.5 at 48. A lower fork and more curl were both tried
in it and are not better at 16 and 32 px. **The favicon is the small drawing on the
rounded ground tile**, drawn at each of its three sizes rather than scaled.

## Reproducing it

`tools/icon/make_icon.py`, with no arguments. It writes `tools/icon/icon.svg` as the
canonical drawing, the 1024 PNG in the asset catalogue, and the website's icon,
touch icon, favicon and bare marks. The SVG writes each path as curves and the PNG
flattens the same curves, so the two cannot drift. **Change the dials; do not
hand-edit any output, and do not trace the SVG.** The generator imports nothing
from `design/`; the design scripts are the record of how the drawing was reached.

`tools/icon/check_port.py` rasterises each output beside the design file it was
ported from (`design/logo-2026-10-11/d-taper/coil2-a/`) and compares pixels. Run it
after the generator. They match apart from antialiasing, and two deliberate
differences the script describes: the port draws each round end of a taper as two
quarter arcs, because one arc across a diameter is flattened by rounding in the
design files, and the check draws the favicon's rounded tile as arcs, because
CairoSVG draws a rounded `<rect>` with uneven corners.

> **Two rasteriser traps, both found by drawing them.** PIL's jointed thick line
> leaves a serrated fringe along a finely sampled curve, and offsetting a whole
> centreline into one outline polygon ties itself in a knot wherever the path turns
> back on itself. The PNG builds each stroke — the leaf, and the small drawing's
> fronds — as the union of one quad per segment and one disc per vertex, which has
> neither problem because every piece is convex. The tapered fronds are outlines
> by construction, and are filled as they are.

## Four things the suite document has to decide, and this app cannot

Peace Garden was written into `suite-brand.md` on 2026-08-31 — §1's app table, §2's
examined table, §3.4's hue allocation and §3.5's verdict table. **Being written down
is not the same as being settled**, and each of these was recorded as an open
question rather than closed by the act of adding a row.

1. ~~**Peace Garden is in neither table in `suite-brand.md`.**~~ Added.

2. **§1's coherence claim does not obviously cover this app.** What makes the suite
   honest — and what made class 41 credible in the trade mark filing — is that every
   app teaches *a skill acquired by drilled repetition with immediate feedback*.
   Peace Garden teaches nothing and is not trying to. It is a contemplative object.
   That is the same question §2 asked about Pfish at length and answered by finding
   the skill it taught; there may be no equivalent answer here. **If Peace Garden
   joins the suite as a peer rather than only wearing its system, §1's argument gets
   weaker, and §1 says that argument is load-bearing.** Worth settling deliberately
   rather than discovering it in a trade mark examination.

3. **§3.5's table needs a Peace Garden row, and the mark depends on what it says.**
   The plant is permitted under the reading that it is what the app *gives*
   you, and forbidden under the reading that it is what the app is *about* — see
   the section above. The table is where that gets settled; leaving it unwritten
   leaves the mark resting on an argument nobody has ratified.

4. **The hue span extends the arc rather than dividing it.** §3.4 puts the usable
   arc at roughly 150°–340°; 60°–140° sat below it, and since 11 October 76°–124°
   still does. That is a widening of the
   system — reasonable, and the owner's call — but §3.4's text still says 150°, and
   the two now disagree.
