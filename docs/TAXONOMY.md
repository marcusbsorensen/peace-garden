# Making the name a description

**The aim, in one line: a botanist or a keen gardener should be able to key one of
these plants out, and be right.**

That is a higher bar than the names currently clear, and it is the right bar,
because the app has borrowed the whole apparatus of botanical naming — genus,
epithet, italics, a synthesised Latinate binomial — and an expert reading it will
apply an expert's expectations within about four seconds.

This is a design. None of it is built.

---

## What is wrong now

Six draws, in two files, none of which consult the plant:

```swift
// Genome.swift
let archetype = source.pick("form.archetype", from: Archetype.allCases)

// PlantName.swift
let head   = source.pick("name.genusHead",   from: Self.genusHeads)
let middle = source.pick("name.genusMiddle", from: Self.genusMiddles)
let tail   = source.pick("name.genusTail",   from: Self.genusTails)
let epithetHead = source.pick("name.epithetHead", from: Self.epithetHeads)
let epithetTail = source.pick("name.epithetTail", from: Self.epithetTails)
```

Every one is a separate draw from the same seed. The name and the plant are
independent, and measurably so: **over four thousand seeds the theme explains
0.3% of the variance in stem height, 0.3% in petal count, 0.5% in leaf count and
0.2% in hue**, and the archetype mix inside every theme is flat at 9–12%.

So three things are true at once:

- **The genus classifies nothing.** *Melissa* and *Melandra* share a genus and
  need have no character in common. A genus that groups by nothing is not a
  genus; it is a prefix.
- **The epithet may be false.** *stellifolia* means *star-leaved*. Nothing makes
  the leaves star-shaped. *tacitantha* means *silent-flowered* and says nothing
  about the flower.
- **Some epithets are not Latin.** Heads and tails combine freely, so
  `pall` + `icola` gives *pallicola*, "pale-dwelling" — a category error, because
  `-icola` takes a habitat and `pall-` is a colour. `mont` + `escens` gives
  *montescens*, "becoming mountain".

The vocabulary itself is good and worth keeping. *nocticola*, *stellifolia*,
*tacitantha*, *pluvialis* are well-formed and evocative. What is missing is that
they be **true**, and that they be **assembled by grammar**.

## The three rules

### 1. A genus is its flower

This is the actual convention. Genera are separated on floral characters —
inflorescence, symmetry, perianth, stamen number. Vegetative characters (leaf
shape, habit, height) and colour vary freely *within* a genus, which is why two
plants of one genus can look very different at a glance and still key out the
same.

So: **the genus head is derived from the floral plan, not drawn beside it.**
Twenty-four heads, twelve archetypes, and a second floral character to split each
archetype in two. Same head ⇒ same flower.

That inverts the current dependency, and inverts it the right way round. **You
name what you observe.** `PlantName` should be handed the floral traits and read
the genus off them, rather than picking a syllable in parallel.

Everything else in the name — the middle, the tail — stays individual variation,
as it is now.

### 2. An epithet is a true statement about this specimen

Not a decoration. The epithet names **the character in which this plant most
departs from its genus** — which is what an epithet is for, and what makes a key
possible.

Mechanically: score the plant's vegetative and chromatic traits against the genus
average, take the most extreme, and name that. A plant whose leaves are far more
divided than its genus's is *-ifolia* with a dissection head; one that droops is
*pendula*; one unusually pale is *pallida*; one that opens at dusk is
*noctiflora*.

The reward is that the name becomes checkable. Somebody who reads *pendula* and
looks at the plant is not disappointed, and somebody who reads a hundred names
starts to be able to predict.

### 3. It has to be Latin

Two constraints the current generator has no notion of:

- **Heads and tails must be compatible.** `-icola` (dwelling) and `-ensis` (of a
  place) take habitats. `-ifolia` (leaved) and `-antha` / `-iflora` (flowered)
  take anatomy. `-escens` (becoming) takes a colour or a state. Each tail needs a
  declared set of heads it can govern.
- **The epithet must agree in gender with the genus.** *Aurelia nocturna*, not
  *Aurelia nocturnum*. Genus endings in `-ia`, `-a`, `-ea`, `-ina`, `-ora`,
  `-ula`, `-era` are feminine; `-is` and `-ynth` need deciding. This is the single
  most visible tell to anybody who has read a flora, and getting it right is
  cheap.

## The ambassador is a type specimen

Botany already has the word for what §*The ambassador plants* in `WEBSITE.md`
describes, and it is better than "ambassador": the **type**. A type specimen is
the one individual that anchors a name — not the average, not the ideal, but the
particular plant the description was written from.

Naming them that way is itself part of the delight, and it makes the garden's
structure legible to anybody who knows the term: an area holds the types of its
genera, and every other plant in it is referred to them.

## What this costs

**Every existing plant changes its name, and many change their theme**, because
the head is now read off the form and the theme is read off the head. A pair who
met before this lands would find their passage moved.

**That cost is close to zero today and will never be lower.** Nothing has
shipped; there is no App Store listing; the plants that exist are on Marcus's
simulator. `theme(of:)`'s doc comment already records what moved the last time
this mapping changed, and this is a bigger version of the same move made at the
last moment it is free.

`ThemeMappingTests` and the whole passage machinery are untouched: head → theme
stays exactly as it is. Only the head's *source* changes.

## The rank that was missing

*Added 3 September, answering "what is the most botanically correct way to do
this". It changes the structure above rather than contradicting it, and it is
the reason the epithet's gender agreement had nowhere to attach.*

Rule 1 says the head is the genus and the middle and tail stay individual
variation. But **the tail carries the subtheme** — `NAMES-AND-THEMES.md` is
built on it — so it cannot be fixed per genus. That leaves *Aurelia* and
*Aurynth* as one genus with two spellings, and a botanist reading two spellings
sees two genera. Gender then has nothing to agree with: gender is a property of
a name, and there would be two names for one genus.

The resolution is one rank deeper, and it is not an invention. **Genera in a
family share a root and differ in their endings** — *Helianthus*,
*Helianthemum*, *Heliopsis*; *Campanula*, *Campanulastrum*. The head is that
shared root. So:

| Rank | What it is | How many | What fixes it |
| --- | --- | --- | --- |
| **Family** | The gross floral plan and inflorescence | 12 | The archetype |
| **Root** | The head. Family plus merosity | 24 | The flower |
| **Genus** | head + middle + tail, as written | 240 | The root, plus free variation |
| **Species** | The epithet | — | This specimen's departure |

Everything the design already wanted falls out of it. Same head still means
same flower, so rule 1 holds unchanged and `theme(of:)` is untouched. Gender
attaches to the written genus, where it belongs, so *Aurelia nocturna* and
*Aurynth nocturnus* are both correct and visibly different — which is the
cheapest possible proof to a reader that the grammar is real. And the family is
a rank the garden can use: an area holds the types of its genera, which is
what §*The ambassador is a type specimen* was reaching for.

### What the archetype profiles constrain, which is currently the wrong half

This is the change that buys botanical correctness and diversity with one move,
and it is the answer to *leave room for the joy of diversity*.

`ArchetypeProfile` biases floral and vegetative traits about equally:
`heightScale`, `leafLengthScale`, `leafDroop` and `swayScale` alongside
`petalCountScale`, `petalCurlBias` and `centreScale`. Botanically that is
backwards. **A family is constant in its flower and wildly various in
everything else** — that is precisely why two plants of one family can look
nothing alike and still key the same, and why a flora keys on the flower.

So: harden the floral half, and widen the vegetative half. Height, leaf shape,
habit, droop, sway and colour get *more* range than they have now, not less;
the floral plan gets almost none. A garden reads as more varied, and every
plant in it is still keyable.

### Merosity becomes a character rather than a cut

Splitting a family on "petal count above or below the middle" is a cut through
a continuum, and a continuum is not diagnostic — a key cannot use it. In a real
flora merosity is discrete and near-fixed: *petals 5, rarely 4 or 6*.

So the draw becomes the *class*, and the count follows from it, with the rare
variant a real plant has. That is what makes `-merous` worth naming, and it is
what "tighten the flower only" means in practice.

## The twelve families

**The merosity numbers are proposed, not settled**, and they are exactly the
kind of thing this repository has learned only rendering catches — the mushroom,
the boulder seed, the locket husk. They want a pass through `tools/preview`
before they are fixed.

Each family takes two roots, from **different themes**, so no area of the garden
is a single repeated shape. The theme each root carries is unchanged.

| Family | Low-merous root | High-merous root | The resemblance |
| --- | --- | --- | --- |
| **Veraceae** · spire | `Ver` 4 · beginnings | `Cer` 6 · ground | *ver*, the spring, and *Ceres*, the grain: a foxglove spike and a wheat ear |
| **Quinaceae** · umbel | `Quin` 5 · pattern | `Fen` 8 · ground | *quinque*, five — an umbel is five-merous — and the fen that cow parsley stands in |
| **Umbraceae** · fern | `Umbr` 3 · waiting | `Dros` 5 · renewal | *umbra*, shade, and *drosos*, dew: where a frond lives and what it holds |
| **Melaceae** · orchid | `Mel` 3 · meeting | `Sel` 6 · light | Orchids *are* 3-merous. *meli*, the honey that pays the pollinator; *Selēnē*, the moon orchid |
| **Liraceae** · lotus | `Lir` 8 · beginnings | `Nyx` 14 · waiting | *leirion*, lily — a lotus is a water lily — and *Nyx*, night, for the ones that open in it |
| **Cynaceae** · thistle | `Cyn` 13 · kinship | `Hal` 21 · travel | *Cynara* is the artichoke, a thistle. *hals*, the salt sea, is sea holly |
| **Wynaceae** · vine | `Wyn` 4 · kinship | `Ael` 6 · travel | *wynn*, joy, for the honeysuckle; *aellē*, a gust, for a lax stem in wind |
| **Calaceae** · bell | `Cal` 5 · pattern | `Ith` 10 · meeting | *kalos*, the shapely — Campanula is 5-merous — and Ithaca, the bell rung on arrival |
| **Elaceae** · star | `El` 5 · light | `Ros` 8 · renewal | *hēlios*, the sun as a flat radial bloom; *ros*, the dew, on a dog rose's five |
| **Belaceae** · poppy | `Bel` 4 · peace | `Aur` 6 · light | *bellus*, a clear sky, for remembrance; *aurora* for the poppy that opens at dawn |
| **Pellaceae** · succulent | `Pell` 8 · ground | `Thal` 12 · beginnings | *pellis*, the earth's skin, for a houseleek; *thallos*, a body with no organs told apart |
| **Olaceae** · plume | `Ol` 5 · peace | `Zeph` 10 · travel | *oliva* — the olive's flowers are a small panicle and its leaves are narrow — and *Zephyros*, the west wind |

Every one of the twenty-four heads is used once. No family has both roots in one
theme, so every area holds two or three distinct kinds of plant.

**One family name lands on a real one by the same root that named it**, which
was not arranged: **Olaceae** beside Oleaceae, both from *olea*, the olive.
**Cynaceae** beside Cynareae is likely rather than certain — `Cyn` was taken for
Gk *kyōn*, the dog, and *Cynara*'s own descent from it is disputed.

**Calaceae was claimed as a third and is not one.** *Campanula* is a diminutive
of *campana*, a bell; it has nothing to do with *kalos*. The two words share two
letters and no root. Recorded rather than quietly deleted, because that false
echo was offered as a reason to keep `Cal` on the bell — and it was the only
reason.

**So `Cal` and `Quin` were swapped, 3 September.** With the false echo gone, two
arguments pointed the other way. An umbel is an *arrangement*, which is what
Pattern's subthemes are about — the golden angle, the quincunx, tessellation —
where a bell is a silhouette. And *quinque* is worth saying where five can be
counted: five lobes on one bell, not five petals on each of forty florets.

The cost is real and is recorded rather than argued away. **Apiaceae is *the*
five-merous family in a flora**, so `Quin` on the umbel was the most precisely
true thing on this table, and that resonance is spent. It is exactly the kind of
thing an expert notices in the four seconds this document opens by invoking.

Both roots sit in Pattern and both families are 5-merous at the low root, so the
swap moved no number and broke no constraint — only which syllable sits on which
family, and the two family names trading places with it.

## Built, and what looking at it changed

*3 September. `RootTableTests`, eight of them, and the whole thing rendered.*

The structure above is built and both suites are green — 80 in SeedCore, 23 in
the app, `ThemeMappingTests` among them, which is the evidence that head → theme
did not move.

**The bell's pairing was wrong, and only the render said so.** It was written as
5 against 6 and flagged in this file as the tightest pair on the table, on the
argument that six lobes is countable even if it is not obvious. Four plants of
each, drawn side by side, settled it: the two genera were *not tellable apart*.
A nodding tube is small and one extra lobe at that size is nothing at all.

It is 5 against 10 now — *Campanula* single, and Campanula 'Flore Pleno'
doubled. **Twice the parts is the one number that is both legible and true**,
because doubling is what a garden does to a bell anyway. Drawn again, the
10-merous plants read as visibly fuller. It is better rather than solved: the
bell remains the least legible couplet on the table, and a bell may simply be
the wrong shape to key on a count.

Against it, the orchid's 3 against 6 reads immediately, which is the pair with
the most botany behind it. That is the shape of the result: where the number is
real, it shows.

Two things the render also confirmed, both of which were arguments until now:

- **The twelve silhouettes stay distinct**, which is the acceptance test
  `tools/preview/archetypes.py` exists for.
- **Plants of one genus vary widely in everything but the flower** — colour,
  height, leaf, habit — while the bloom holds. That is the whole design in one
  picture, and it is what the vegetative widening below has still to push
  further.

`tools/preview/plant_model.py` was ported alongside, or the sheet would have
drawn the old flowers and told us nothing. It is not covered by CI — only
`tools/reference/` is — so it is a port that has to be kept by hand, and this is
the second time that has mattered.

## The epithet, built

*3 September. `Epithet.swift`, and nine tests.*

Rules 2 and 3 are built. The epithet is no longer two syllables glued together
from separate draws; it is a claim about the plant, checked before it is made.

**How a departure is measured, which turned out to be free.** Every continuous
trait is drawn as a position in its own range — `GeneSource.value` is
`lower + unit(label) * width` — so `unit(label)` *is* this plant's rank among
the plants of its genus. Every plant of a genus draws the same labels through
the same profile, so a position of 0.94 in `foliage.length` means the leaves are
longer than 94% of the genus, exactly, without anyone working out the genus's
average. The source is asked again rather than the finished traits measured
back: same number, one hash, and it cannot drift out of step with `Genome.init`.

**Colour is measured absolutely and deliberately.** `Palette` never consults the
archetype, so a genus constrains no colour and there is no genus average to
depart from — and *aurea* means golden however golden its neighbours are.

**The gender question §3 left open is answered.** `-ynth` is masculine, the
Greek `-ynthos` of *Hyacinthus*; the other nine endings are feminine, `-is` on
the model of *Arabis*. That makes one genus in ten masculine, which is enough
for the agreement to be visible in a garden rather than only in a test:
*Ithora rubra* beside *Verynth ruber*, *Olea paniculata* beside
*Olynth paniculatus*.

### Two mistakes worth keeping in the record

**Notability had to become rarity.** The first version scored measurements by
how far into a tail they reached and markings by a number written next to each
one — two unrelated scales. So *variegata*, which is true of **37%** of plants,
outranked every measurement and took a third of the garden. The rule now is one
scale and one sentence: **of the true things, say the one fewest of this plant's
relatives could have said.** That is what a botanist naming a specimen does, and
it is the only basis on which a marking and a measurement can be compared at
all. Extremity survives as a tie-break between characters of equal rarity.

**Three words were dead.** *pallida*, *obscura* and *venosa* asked for petal
brightness and veining outside the ranges those traits are drawn in — brightness
never leaves `0.45...0.82` and veining never passes `0.65` — so they could not
be said of any plant that will ever exist. The thresholds had been guessed.
They are measured percentiles now, and `Epithet.Rate` is a table of measurements
with a test that re-measures it, because a rate that goes stale silently
restores the bug it was written to fix.

Both were caught by tests written before the numbers were tuned, and neither
would have been visible in a name. That is the point: an epithet that has come
unhooked from its trait still reads as a perfectly good name.

### Where it landed

Fifty-seven distinct epithets over twenty thousand seeds, the commonest at 6%.
About one plant in fifty is *vulgaris* — lower than it sounds like it should be,
and right: twenty-four characters cover a lot of ground, so a plant with nothing
in any tail and no marking at all is genuinely rare. The floor still does its
work one character at a time, which is the part that matters — every claim made
is true of the top eighth.

`serratifolia`, `integrifolia` and `pendula` are rare, at well under a percent
each, because serration and droop are drawn with `bell` and a centre-weighted
trait reaches its tails seldom. That is correct rather than a defect: a plant
whose leaves droop that far really is unusual, and the name should be.

## The vegetative half, widened

*3 September. The other half of §"What the archetype profiles constrain", and
the last of the design. The flower is held to a count per genus; this is the
room given back.*

Seventeen ranges, all of them vegetative, none of them floral. What went where:

| Trait | Was | Is | Spread |
| --- | --- | --- | --- |
| `foliage.length` | `0.09...0.26` | `0.055...0.28` | ×2.9 → ×5.1 |
| `stem.height` | `0.55...1.25` | `0.44...1.42` | ×2.3 → ×3.2 |
| `stem.baseRadius` | `0.008...0.019` | `0.006...0.022` | ×2.4 → ×3.7 |
| `foliage.widthRatio` | `0.22...0.78` | `0.13...0.88` | ×3.5 → ×6.8 |
| `stem.taper` | `0.28...0.72` | `0.16...0.86` | ×2.6 → ×5.4 |
| `foliage.pitch` | `0.35...1.25` | `0.24...1.45` | 0.90 → 1.21 rad |
| `stem.nodeCount` | `2...7` | `2...9` | 6 → 8 counts |
| `foliage.fold` | `0.05...0.55` | `0.02...0.62` | ×11 → ×31 |
| `foliage.tipSharpness` | `0.7...2.1` | `0.5...2.4` | ×3.0 → ×4.8 |
| `form.vigour` | `0.82...1.22` | `0.74...1.30` | ×1.5 → ×1.8 |
| `stem.lean` | `±0.55` | `±0.75` | 28° → 39° of bend |
| `stem.twist` | `±0.7` | `±0.95` | +36% |
| `stem.sway`, `foliage.serration` | `0...1` | `0...1.25`, `0...1.3` | +25%, +30% |
| `foliage.droop` | `0...1` | `0...1.15` | +15% |
| `foliage.teeth` | `5...17` | `3...17` | downward only |
| `foliage.veinCount` | `3...9` | `2...9` | downward only |

**The ranges widened and the multipliers did not, and that distinction is the
whole of it.** A multiplier moves where a family's centre sits — it is what
makes a succulent squat and a vine lax — and pushing one further from 1 makes
the twelve kinds more unlike each other without making any two plants of one
kind less alike. A range is the other thing: how far one plant may stand from
its own relatives. Only one multiplier moved, and only downward; see below.

### What the renders showed

Two sheets, before and after, on the same seeds — `tools/preview/archetypes.py`
for the twelve silhouettes, and six plants of one genus side by side for the
thing this change is actually about.

**The twelve silhouettes stay distinct**, which is the standing acceptance test
and the reason not to widen further.

**Within a genus, the gain is real and it is mostly in proportion rather than in
size.** Both the app and the preview frame a plant to fill the view — nobody
ever sees one next to a ruler — so what reads is a plant against its own
thickness, its own leaves and its own node spacing. Six spires went from 5–11
nodes to 5–14, and from a leaf spread of ×1.8 to ×2.3: the sparse one now reads
as a sparse plant rather than the same plant with fewer parts. Six stars went
from ×3.1 to ×5.5 in leaf length, which is the difference between a leafy
rosette and a near-leafless scape carrying the same five-merous flower. Six
bells now include one with two nodes and a bare stem beside one with eight and a
column of leaves. In every row the petal count holds: spire 3–4, fern 3–4, bell
4–5, star 5–6, orchid 3, lotus 8–9, thistle 12–13. That is the design in a
picture — the flower constant, everything else various.

**Three ugly plants in the after sheet were in the before sheet too**: a dark
succulent that reads as a log rather than a plant, a vine so bare it is a wire,
and a pale succulent whose leaves are wider than they are long. All three are
pre-existing and none is worse for this change. They are recorded here because
the next person to widen anything will find them and wonder.

### The one thing that had to come down

**A fern's droop could not follow the rest, and only a render said so.** Drawn
at a ladder of values, a fern stops reading as a plant somewhere past a droop of
about 1.3 on a leaf held near-upright and long against its own plant: it
collapses into a starburst mat with the stem lost inside it.

The cause is worth writing down because it is not what it looks like.
`PlantBuilder.addLeaf` builds the blade's frame from `forward = radial·sin(pitch)
+ axis·cos(pitch)` and then sags it along **that frame's own up-vector**. For a
leaf held out horizontally that vector points at the ground and droop reads as
droop. For a leaf held close to the stem it points sideways, so droop kinks the
blade out and back over itself instead of bending it down. Droop is therefore
only droop for a flat leaf, and the failure needs three things at once: a high
droop, a low `pitch`, and a leaf long against its plant. Widening all three at
once is exactly what this change was doing.

Two consequences. `foliage.pitch`'s floor was set at 0.24 rather than the 0.18
first tried, because a leaf pressed flat against the stem is where the kink
lives and is not a look worth much. And the fern's `leafDroop` came down from
1.5 to 1.3 — the only multiplier on the table to move. 1.15 × 1.3 is 1.495, so
**a fern's droop ceiling is where it already was** and its worst individual is
the same worst individual the garden already had, while the other eleven
families gain 15%. Nothing was lost to buy that.

Over 30,000 seeds the fern is the only family that can reach the kink at all.
The first attempt — `0...1.3` droop, pitch floor 0.18, leaf to 0.30, height from
0.40 — reached it five times, about one fern in five hundred. Before the change
and after it, none. **Every test passed at all three.**

The first metric tried was wrong and is worth recording, because it was
plausible and it would have cost the widening. Reasoning from the formula,
`sag = droop × length × 0.8`, said the failure was the leaf out-sagging its own
plant — and by that measure the first attempt took ferns from 0.3% to 6%, which
looked like a change that could not ship. Drawn as a ladder, plants at a
sag of 1.4 times their own height turned out to read perfectly well: as an
agave, a bromeliad, a spreading rosette. The ratio was not the failure. It only
correlated with it, because both rise with droop.

### What was tried and rejected

- **Raising `foliage.teeth` and `foliage.veinCount`.** Both are sampled along
  the nineteen rows `addSurface` gives a blade, and at their existing ceilings of
  17 and 9 they are already at or past what nineteen rows can resolve. Raising
  either draws a *coarser* leaf, not a finer one. Both were widened downward
  instead, which costs nothing and gives a three-lobed margin and a two-ribbed
  blade — neither of which the garden had.
- **Widening the vegetative multipliers.** See above: wrong rank. They set
  between-family difference, and this change is about within-genus variation.
- **Colour, deliberately left alone.** The coupling is real and the payoff is
  not: `Epithet`'s three petal thresholds and its thirteen `Rate` measurements
  were taken against the current palette, so any widening means re-measuring all
  sixteen to hold each character at its present share. Against that, colour is
  already the most various thing in a genus — the six-plant sheets have red,
  blue, green and yellow spires side by side — so it is the one place where
  more range buys the least. It stays as it is.
- **Fixing the sag.** A drooping leaf should *arch*: the tip curves down while
  the blade keeps its own length. The model displaces a straight blade instead,
  so a drooping leaf silently grows — at a droop of 1.7 its arc is nearly twice
  its nominal length. Arc-length-preserving droop is the right answer and it is
  a change to every leaf in the garden, which is a bigger move than widening a
  range and wants its own pass.

### What it cost

**`Epithet.Rate.leafy` moved, from 0.240 to 0.330, and that was not foreseen.**
The warning written for this work was about colour; `leafy` is a *count* rate —
`leafCount >= 15` — and taking `stem.nodeCount` from `2...7` to `2...9` moved it.
*foliosa* went from a character worth naming to one about as ordinary as
*variegata*. Nothing about that is visible in a name, which is the whole reason
`testTheDeclaredRatesAreTheRealOnes` exists, and it earned its keep on the first
change after it was written.

`EpithetTests` carries the same coupling in two literals: a *longifolia* had to
have leaves over 0.21 m and a *brevifolia* under 0.13 m, both measured against
the old `foliage.length`. They are 0.185 and 0.11 now, set just inside what the
range permits rather than at the tightest value a sample happens to show, so
they survive somebody changing the seed count. *brevifolia*'s is the tighter
claim it used to be: a short leaf is now genuinely shorter.

The three meshes `PlantFormTests` pins moved for the second time, and the note
under that test says so. Every trait widened here feeds the mesh, so all three
plants changed shape.

Two hard bounds were respected by construction rather than by luck, both of them
`GenomeTests`': height cannot exceed 1.42 × 1.45 (the vine) × 1.30 = 2.68 m
against a declared ceiling of 3, and node count cannot exceed 9 × 2.1 (the
succulent) = 19 against a declared ceiling of 20. Those two multipliers are what
set the tops of those two ranges.

`tools/preview/plant_model.py` was ported alongside, as it has to be — it is not
covered by CI, and the third time that has mattered. The port was checked line
by line against the Swift afterwards, all 27 ranges and 84 multipliers, and it
reproduces the failing `EpithetTests` figure to five decimal places, which is
the evidence that the renders above are of the plants the app will draw.

## What is Marcus's to decide

*Marcus settled these on 3 September: the pairings are trusted as proposed, the
flower is tightened and the vegetative half widened, and the epithet names the
notable with a floor. What follows is kept because the reasoning is worth having
rather than because it is still open.*

1. **Which archetypes pair into which genus, and which genera into which theme.**
   The heads carry meanings that were chosen deliberately — *Ol* and *Bel* for
   peace are the olive and a clear sky; *Zeph*, *Ael*, *Hal* for travel are the
   west wind, a gust and the salt sea. Those meanings should survive the change,
   which means the archetype assigned to *Ol* ought to look like an olive. This
   is a judgement about resemblance and it is not one to make by algorithm.
2. **How much variation to leave inside a genus.** Enough that a garden is not
   twelve repeated shapes; little enough that the genus reads. There is a knob
   and it wants an eye on it, not a default.
3. **Whether the epithet names the extreme or the notable.** The extreme is
   mechanical and always available. The notable is more like what a botanist
   would actually have done, and needs a rule for what counts.
