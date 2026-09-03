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
theme, so every area holds two or three distinct kinds of plant. Three of the
family names land on real ones by the same etymology that named them:
**Cynaceae** beside Cynareae, the thistle tribe; **Olaceae** beside Oleaceae,
the olives; **Calaceae** beside Campanulaceae.

**One is still worth arguing about.** `Cal` is given to the bell for
*Campanula*, but *kalos* is the shapely in general and Pattern could as fairly
claim the umbel's geometry — `Cal` and `Quin` could swap families.

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
