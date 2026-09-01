# Names and themes

Written 1 September 2026 and **built the same day**, so this is both the spec
and the record. Where the building changed the specification, the section says
so.

The idea in one line: **a plant's name says which passage it can be given.**
The head of the genus carries the theme, the ending of the genus carries the
subtheme, and both were already in every seed ever minted.

## What was wrong

The passage bank has ten themes and three hundred lines, thirty to a theme, and
a seed carried a theme of its own drawn as `passage.theme.v1` — a trait like any
other, and independent of every other trait. So a plant's name and a plant's
theme were two unrelated facts about the same seed. *Nyxia lumurna* was as
likely to be a Travel plant as a Waiting one, and nothing anybody could see
would say otherwise.

Meanwhile the twenty-four syllables the genus is built from already carry
meaning, and always did:

> `Ael`, `Aur`, `Bel`, `Cal`, `Cer`, `Cyn`, `Dros`, `El`, `Fen`, `Hal`, `Ith`,
> `Lir`, `Mel`, `Nyx`, `Ol`, `Pell`, `Quin`, `Ros`, `Sel`, `Thal`, `Umbr`,
> `Ver`, `Wyn`, `Zeph`

Night, dew, the west wind, the olive. The vocabulary was in the code. Only the
connection was missing.

## The one constraint that shaped everything

**The list of heads is frozen.** `GeneSource.pick` indexes by
`unit(label) * options.count`, so the boundaries between the twenty-four
syllables are a function of there being twenty-four. Add a twenty-fifth and
every plant on every phone is renamed.

This killed the obvious design, which was to write a head list per theme and
add whatever syllables the themes needed — eight new ones, as first sketched.
It cannot be done. **The themes had to be fitted to the syllables**, not the
syllables chosen for the themes.

It also settles the direction of the map. Deriving the head *from* the theme
renames plants; deriving the theme *from* the head does not, because a theme is
never stored — only derived, at the moment a passage is shown.

## The map

Four themes take three heads and six take two. That is the only division of
twenty-four that keeps every theme populated, and it means a plant is half again
as likely to be born to Beginnings as to Peace — 12.5% against 8.3%.

**Recorded rather than corrected.** The two fixes both cost more than the
problem: renaming every plant, or weighting the draw, and a weighted draw would
break the one thing the design is for, which is that the name and the theme are
the same fact said twice.

| Theme | Genus heads | Sense |
| --- | --- | --- |
| **beginnings** | `Thal` · `Lir` · `Ver` | Gk *thallos*, a young shoot · Gk *leirion*, lily · L *ver*, the spring |
| **waiting** | `Nyx` · `Umbr` | Gk *Nyx*, night · L *umbra*, shade |
| **renewal** | `Dros` · `Ros` | Gk *drosos*, dew · L *ros*, dew again |
| **light** | `El` · `Aur` · `Sel` | Gk *hēlios*, sun · L *aurora*, dawn · Gk *Selēnē*, moon |
| **pattern** | `Cal` · `Quin` | Gk *kalos*, the shapely · L *quinque*, five |
| **ground** | `Cer` · `Fen` · `Pell` | L *Ceres*, the grain · fen, low wet ground · L *pellis*, the earth's skin |
| **travel** | `Zeph` · `Ael` · `Hal` | Gk *Zephyros*, west wind · Gk *aellē*, a gust · Gk *hals*, the salt sea |
| **meeting** | `Mel` · `Ith` | Gk *meli*, honey · Ithaca, the place arrived at |
| **kinship** | `Wyn` · `Cyn` | OE *wynn*, joy · Gk *kyōn*, the dog that waits at the door |
| **peace** | `Ol` · `Bel` | L *oliva*, the olive · L *bellus*, said of weather: a clear sky |

Two of these bent to fit, and are worth naming because a later reader will
wonder. **`Ith`** could as easily be Gk *ithys*, straight; Ithaca was chosen
because Meeting needed a second head and an arrival is what a meeting is.
**`Bel`** has four defensible roots; *bellus* said of weather was taken because
Peace needed one and *serenus*, a clear sky with no wind in it, is literally in
the Peace bank.

## The subthemes

Each theme's thirty passages were laid out and read, and the three heaps below
are the ones they fell into. They were not invented and then filled — which is
why the thirds are uneven and why the shape differs from theme to theme.

Most themes divide into **the mechanism**, **the instances**, and **the words
and sayings**. Not all of them do, and forcing the odd ones into that frame
would have been drawing the map before walking the ground.

| Theme | First third | Second third | Last third |
| --- | --- | --- | --- |
| **beginnings** | The first act — *germination, imbibition, radicle, meristem* (7) | Small to large — *the acorn, the coco de mer against orchid dust* (10) | What a start settles — *the Bramley pip, prime and primrose* (13) |
| **waiting** | Held back — *dormancy, stratification, marcescence* (7) | The long count — *Masada dates, Beal's bottles, bamboo mast years* (8) | Standing and watching — *patiens, abide, the gardener's shadow* (15) |
| **renewal** | Cut and come again — *coppicing, epicormic buds, the Hiroshima ginkgos* (7) | The turning year — *If Winter comes, spring as water* (10) | Made whole — *kintsugi, resurgam, anastasis, convalesce* (13) |
| **light** | The edges of the day — *gloaming, alpenglow, apricity, gökotta* (8) | Reading the light — *photoperiodism, heliotropism, the day's eye* (11) | Light itself — *lux, solstice, phosphorus, the eight minutes* (11) |
| **pattern** | Counted — *the golden angle, Fibonacci spirals, quincunx* (8) | Fitted together — *tessellation, decussate leaves, Turing patterns* (9) | Order named — *cosmos, rhythm, ordo, the anthology* (13) |
| **ground** | The soil itself — *rhizosphere, a teaspoon of earth, Darwin's worms* (9) | A place you are from — *querencia, Heimat, petrichor* (9) | A kept place — *pairidaeza, colere, garden as enclosure* (12) |
| **travel** | How a seed goes — *anemochory, sea beans, the dandelion's vortex* (11) | The road — *ad ripam, peregrinus, travel and travail* (10) | Far off — *Fernweh, tramontane, serendipity* (9) |
| **meeting** | The moment — *kairos, clinamen, ichigo ichie* (11) | Two that need each other — *fig and wasp, yucca moth, Ophrys* (9) | The manners of it — *xenia, limen, interfulgence* (10) |
| **kinship** | Grown together — *inosculation, grafting, lichen, mycorrhiza* (11) | The words for it — *sibb, God-sib, companion, kind and kin* (8) | Two people — *Donne, Montaigne, Hávamál, ubuntu* (11) |
| **peace** | Quiet as a sound — *psithurism, snow, the anechoic chamber* (5) | The words for stopping — *pax, serenus, quietus, sabbath* (10) | At ease — *hygge, sobremesa, shinrin-yoku* (15) |

**Which third comes from the genus ending.** Ten endings over three subthemes,
split `-ia -is -a` / `-ea -ina -ora` / `-yne -era -ula -ynth`, so 30% / 30% /
40%. That suits the bank rather than fighting it: the last third is the words
and the sayings, and it is reliably the largest of the three.

The smallest pool is Peace's *quiet as a sound*, at five. Thin, and left thin
rather than padded out with lines that belong elsewhere.

## What a meeting settles, and where

Three settlements from three different places, which extends the two the design
already had:

| | Comes from | Holds? |
| --- | --- | --- |
| **Theme** | The pair, inherited from the two parents' own themes | Settled the first time two people meet, and never moves |
| **Subtheme** | The child's own genus ending | New at every meeting, because the child seed is |
| **The line** | The child seed, by `deterministicFold` | Never the same twice |

So two people keep one theme forever and roam its thirty passages by way of
whichever third their new plant happens to belong to. A plant says which corner
of its theme it came out of.

## What this changes for somebody using it

**Nothing about any plant.** No name, body, palette, birthday or garden moves.
The theme is read off a draw — `name.genusHead` — that every seed ever minted
already made, and a theme has never been stored.

**One thing about a passage.** Two people who met before this landed will find
their shared theme has shifted once, because it used to come from a different
draw. A passage is something said at a meeting rather than a property of the
plant it made, and the note that plant carries never held it.

That is the whole cost, and it is paid once.

## What was built

- `PlantName` keeps the head and the ending it was built from rather than
  leaving them to be recovered from the spelling. Both lists are now `public`
  and both carry the note about being frozen.
- `PlantName.init(genus:epithet:)` — the hand-written one — reads them back off
  the spelling, searching for the ending **in what is left after the head**.
  Searching the whole word puts `Cer`, `Quin` and `Ver` in the wrong third
  whenever they take the shortest ending: *Cera*'s longest matching ending is
  `era`, and the answer is `a`. See below.
- `Quotes.Subtheme` — thirty cases, each naming its theme.
- `Quotes.Theme.genusHeads`, and `Theme(genusHead:)`.
- `Quotes.subtheme(of:in:)`, reading the ending.
- `Quotes.theme(of:)` stops drawing `passage.theme.v1` and reads the name.
- Passages are pooled by subtheme rather than by theme.
- **`App/PeaceGardenTests`, the app target's first tests.** Twelve of them.

## The tests, and why the app needed some at last

SeedCore has carried all the testing until now, which was right while everything
worth proving lived there. This does not: it is a hand-written table over two
frozen lists, and that is the kind of thing that goes wrong in silence. A head
dropped from the table costs nobody a compile error and quietly sends a
twenty-fourth of all plants to Beginnings. A subtheme with no passages behind it
is a crash at the one moment the app exists for.

The twelve cover: every head claimed by exactly one theme; no theme claiming a
head that does not exist; the two frozen lists still 24 and 10 long; three
subthemes per theme; every subtheme carrying passages; every passage agreeing
with its own subtheme's theme; the bank still 30 to a theme; a subtheme drawn
for a theme always belonging to it; all three thirds reachable; every theme
reachable; a plant's theme always claiming its own genus head; and a hand-made
name recovering its own syllables.

**The last one earned its place immediately.** It failed on `Cera`, `Quina` and
`Vera` the first time it ran, which is the `era`/`a` ambiguity above — three of
the twenty-four heads landing in the wrong third of their own theme whenever
they took the shortest ending. Nothing on screen would ever have said so.

## What to watch

- **The Beginnings tilt.** 12.5% against Peace's 8.3%. If it reads as a bias in
  use rather than as a number in a document, the answer is more passages, not a
  weighted draw.
- **Ten passages a meeting, not thirty.** A pair now draws from one third of
  their theme at a time. Across meetings they still roam all thirty, because the
  child's ending moves — but any single meeting has a tenth the bank behind it
  that it used to.
- **`Cerera` is honestly ambiguous** — `Cer` + `er` + `a`, or `Cer` + `era` —
  and the hand-written init has to guess. A drawn name never asks, because it
  keeps both syllables from the start. Only ever a display concern.
