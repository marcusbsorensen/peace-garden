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

## What is Marcus's to decide

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
