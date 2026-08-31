# Peace Garden — brand record

Written 30 August 2026, when the app joined the Interfulgent suite.

The system is not Peace Garden's to define. It is
`uncubed-integration/docs/design/suite-brand.md`, and §3 of that document owns the
ground, the stroke treatment, the gradient and the hue allocation. **Read it before
changing anything here.** What follows is only what §4 leaves to each app — the
glyph, its geometry, and the numbers this app measured.

## The mark

**An unwinding spiral carrying a peace lily's spathe, with its spadix inside.** One
continuous monoline stroke — a logarithmic coil, tight at its centre, opening as it
turns, and leaving on its own tangent into the bract it holds at the top — plus one
short white stroke that does not take the gradient.

The spathe is not parked on the end of the line. It **leaves on the tangent the
spiral actually ends on** and keeps turning the same way, so the whole mark is one
gesture rather than two shapes introduced to each other.

### The white element, and the suite's habit of having one

Measured off the shipped artefacts rather than recalled:

| App | White element | How it relates to the gradient |
|---|---|---|
| **Pfish** | two bubble rings, **`#FFFFFF`**, at the fish's own stroke weight | separate elements, outside the sweep |
| **UnCubed** | the exponent finishing on **`#F4F3EF`** | not a separate element — the sweep's last stop |
| **Peace Garden** | the spadix, **`#FFFFFF`**, at **48%** of the stroke | separate element, outside the sweep |

**These are two different devices and the suite has not said which it prefers.**
Pfish sets flat white beside a mark that graduates; UnCubed resolves the graduation
onto a warm off-white. Peace Garden follows Pfish, because a spadix is a distinct
organ and not the end of the bract. Worth noting that **the suite therefore has two
whites in it** — `#FFFFFF` and `#F4F3EF` — and nothing yet says that is deliberate.

The spadix runs **lighter than the stroke it sits inside**. At full weight it fills
the bract's hollow and the spathe stops reading as an enclosed form. `un³` has the
precedent for a secondary element at a reduced weight: its exponent runs at 82% of
the letters, and §10.4 calls the choice deliberate for the same reason — a
superscript at full weight closes its counters into a blot.

### Where this stands against §3.5, which is the question anyone will ask

§3.5 says a mark may not depict what the app is *about*; it may depict what the app
*gives you*. **Which side of that line this mark falls on depends on how the app is
framed, and the framing moved while it was being drawn. Recorded, because the
argument matters more than the conclusion.**

- **Read as "the app is about a seed and what grows from it"**, every plant form is
  the forbidden case — a leaf, a shoot, a flower and a seed all become "a flag is a
  flag", and a spathe with them. This was the first reading taken here, and it is
  why the mark began as a bare spiral with no botany in it at all.
- **Read as "the app is about an encounter and the passage of time, and the plant is
  what it hands you in exchange"**, the spathe sits exactly where Pfish's fish sits:
  the reward, not the subject. §3.5's own table admits Pfish on precisely that
  reasoning.

**The mark as drawn depends on the second reading.** That reading is defensible and
is the owner's, but it is not the one §3.5's table records, and the two are not
interchangeable — so a reader who assumes the first will think this mark is a
breach. If the second reading is right, it belongs in §3.5's table beside Pfish's
row rather than being inferred from this document.

The spiral carries the argument either way: it depicts the *medium* the app works
in, which is unfolding over real time, in the way FreqShift draws a waveform rather
than a voice.

> **What was drawn first, and rejected.** A luminous flower on a pool of light:
> filled shapes with shading, a glow, a radial gradient ground, no stroke anywhere.
> It was drawn before this document had been read and it broke §3.1, §3.2, §3.3 and
> §3.5 at once. Recorded because it looked good, and looking good is exactly how a
> mark that is not in the system gets kept.

## Construction — 1024 × 1024, ground `#0D0D1F`

| Dial | Value |
|---|---|
| Turns | **2.0** |
| Start radius | **48** (construction units) |
| Growth per turn | **× 2.3** — logarithmic, not Archimedean |
| Stroke | **67.65** rendered |
| End bearing | **45°**, up and to the right |
| Spathe length | **0.92** of the spiral's final radius |
| Spathe turn | **0.30 rad**, continuing the spiral's sense |
| Spathe half-width | **0.28** of its own length, widest at ⅓ along |
| Spadix weight | **48%** of the stroke |
| Spadix run | **0.26 → 0.55** along the spathe's spine |
| Spadix clearance | **≥ 8** units each side, asserted |
| Margin | **190** |

**The spiral is logarithmic on purpose.** An Archimedean one holds the same gap the
whole way out, which reads as evenly wound rather than as growing, and it cannot be
tight at the centre and open at the rim at the same time.

Two constraints are asserted in the generator rather than left as lore, because
both were discovered by drawing them wrong:

- **The start radius must clear half the stroke.** Below that the innermost turn
  paints over its own centre and the mark is a blob with a tail.
- **The innermost turn's radial gain must clear a whole stroke.** Below that
  consecutive turns merge, and they merge first at the smallest size.
- **The spadix must leave clearance inside the bract's hollow.** The hollow is the
  spathe's half-width less half the outline's own stroke, and it is checked at the
  narrow end of the spadix's run, which is where it runs out of room first.

The fit is computed from the drawn bounds — the flattened polyline plus half a
stroke, which is exact for round caps — and not typed. Centred, with no optical
bias: the mark has no open side wanting one, and the render measures **286 px** clear
to left and right and **189 px** clear top and bottom, ink at 44% × 63% of the tile.

## Colour

§3.4's segment for this app is **yellow → lime → forest green**, allocated by the
owner on 2026-08-30. Three stops, bottom-left to top-right:

| Hue | | Contrast on ground | Luminance |
|---|---|---|---|
| **140°** forest green | `#06F556` | 13.00 : 1 | 0.6614 |
| **100°** lime | `#55F306` | 13.00 : 1 | 0.6614 |
| **60°** yellow | `#DCDC06` | 13.00 : 1 | 0.6614 |

**Isoluminance spread: 0.000%.** Lightness is solved per hue against a luminance
target rather than chosen, which is what holds a triad level across hues of very
different natural brightness. Yellow is the extreme case and the reason it has to
be solved: eyeballing it is how the sweep becomes a value staircase in greyscale.

**13:1 rather than Pfish's ~9.1:1, and the number is chosen rather than inherited.**
Holding a triad isoluminant costs the naturally-bright hues their chroma. At 9.1:1
this span's yellow lands on `#B9B905`, an olive. 13:1 is the highest target at which
the green end still sits at full chroma — above it the greens climb past it and wash
out to pastel — so it is the most saturated isoluminant triad this span can carry,
which is what *neon* asks for.

An even sweep, because the mark is one continuous stroke: §3.3's rule about putting
the transitions in the gaps applies to marks made of separate elements, and this is
not one.

## Sizes

One drawing covers every app-icon size down to 40 px, where the spiral still reads
as a spiral. The ground travels with the mark, so there is no light and dark pair
and no tinted variant — matching `ui-design-system.md` §10.4.

## Reproducing it

`tools/icon/make_icon.py`, with no arguments. It writes `tools/icon/icon.svg` as the
canonical drawing and the 1024 PNG in the asset catalogue, both off the same
flattened polyline so the two cannot drift. **Change the dials; do not hand-edit
either output, and do not trace the SVG.**

> **Two rasteriser traps, both found by drawing them.** PIL's jointed thick line
> leaves a serrated fringe along a finely-sampled curve. Offsetting the whole
> centreline into a single outline polygon fixes that, and then ties itself in a
> knot at the spathe's tip, where the path reverses through 180°: the offset
> self-intersects and an even-odd fill punches a hole in the point. The PNG builds
> the stroke as the union of one quad per segment and one disc per vertex, which
> has neither problem because every piece is convex. An SVG renderer shares neither
> artefact, so in both cases the two outputs would have disagreed about the same
> polyline — the failure `ui-design-system.md` §10.4 describes as looking wrong only
> in the render.

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
   The spathe is permitted under the reading that the plant is what the app *gives*
   you, and forbidden under the reading that it is what the app is *about* — see
   the section above. The table is where that gets settled; leaving it unwritten
   leaves the mark resting on an argument nobody has ratified.

4. **The hue span extends the arc rather than dividing it.** §3.4 puts the usable
   arc at roughly 150°–340°; 60°–140° sits below it. That is a widening of the
   system — reasonable, and the owner's call — but §3.4's text still says 150°, and
   the two now disagree.
