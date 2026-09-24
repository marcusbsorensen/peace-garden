# The front page, and what the names mean

About thirty short strings for the website, in forty-one languages; for the
app's seven languages, fifty-two more for the sheet that explains a plant's
name. Each language has its own sheet in `sheets/<code>.md`, which is this
brief with that language's own material filled in and the exact count at its
head: read that rather than this file alone, because half of what matters is
the vocabulary your language has already settled on.

**This is a translation.** It takes the instruction `tools/strings/BRIEF.md`
gives the six paragraphs, not the one `NAMING.md` gives the ten areas: every
language says the same things, and the plainest way your language says each one
is the answer. The ten area names are already written in your catalogue, and
none of the strings here is an area name — the cards on the front page set your
area name *beside* the line you write, and it is printed on your sheet so the
two sit well together.

## What is already decided, and is not yours to reopen

- **Informal address, everywhere.** Dutch *je*, Danish *du*, German *du*,
  French *tu*. Only two strings here address the reader at all — `frontTurn`,
  and *the earth that is yours* in `meaningGround`.
- **The vocabulary.** Your language has already chosen its words for *seed*,
  *garden*, *meeting*, *cross* and the ten areas. Your sheet prints them.
  **Use those words.** Three strings here repeat phrases your language has
  already written — `frontLead` says two things `about1` says, and
  `frontCross` is the verb `growBody` already uses for crossing — and where
  they repeat, they agree.
- **A quantity is a numeral from 2 up; prose is not a quantity.** Nothing in
  this commission reports a quantity. *Two people*, *the two seeds*, *that
  area's three parts* are sentences about a pair or about the shape of a table,
  and stay words, as they are in the English.
- **The plant names stay Latin.** `meaningsSecond` quotes three pieces of one —
  `-ynth`, `rubra`, `ruber` — and they are copied exactly.

## The register

The site's own: quiet, plain, addressed to one stranger who was handed a link
by somebody they met.

- **No marketing and no exclamation marks.** Nothing is being sold.
- **Say what a thing is and does.** *It stays on your phone* rather than *it
  never leaves*. A negative reads as a warning even when it was meant kindly.
- **Headings and labels are short, and short on purpose.** `frontMeet`,
  `frontCross` and `frontGrow` are one word each in English and sit under a
  glyph as three steps; the `meanings*` labels head the columns of a table. If
  your language needs two words, use two, and no more.
- **Sentence case.** The tracked-out capitals on the page are set by the
  stylesheet, and some languages are excluded from them — that is handled for
  you.

## The ten `meaning*` lines, and the one colon

Each is one line in the form **Headword: definition.**

> Waiting: what is held back until its time, however long that is, and whoever keeps watch.

The site cuts the line at its **first colon** and sets what comes before it as
a dictionary headword — on each area page, on each of the ten cards on the
front page, and in the table at `/meanings`. The colon itself is used up by
that cut and does not appear on the page.

- **One colon, straight after the headword, and none anywhere else in the
  line.** A second colon would print in the middle of the definition.
- **Chinese and Japanese may use the full-width colon `：`**, which the site
  reads exactly as it reads `:`. French may keep its usual space before the
  colon; the site trims it.
- **The headword is the theme, not the area.** *Waiting*, not *The Cold
  Frame* — the area's name is printed under the line on the card, and a card
  that says the same thing twice has lost its headword. One word where your
  language allows, a noun, in the form a dictionary would list it.
- **The definition is a phrase, not a sentence**, the way a dictionary gives
  one: it runs on from the colon, starts as your language continues after a
  colon (lower case, in most), and ends with a full stop. Each has two halves
  joined by *and*, one for each of the things the theme holds; keep both.

**In the app's seven languages** — Danish, Spanish, French, Italian, Norwegian
Bokmål, Dutch and Swedish — the app's name sheet sets the same ten entries
from two keys each, `theme.<name>` for the headword and
`theme.<name>.definition` for the rest, with no colon between them. Write the
headword and the definition once: the site's line is those two joined by your
language's colon, and the app's two keys are the same two pieces apart. The
check at the foot of this brief compares them.

## The rule that matters most

**Each of these strings says something true about how the app works or what a
name means, and a fluent translation can quietly say something else.** Under
every string your sheet prints *what it must say* and, where there is a known
trap, *what it must not*. Those are the specification. If the natural sentence
in your language cannot carry the claim, write a less natural one and say so
in your notes.

## When you are done

**On the site.** Add the keys to `Server/strings/<code>.json`, under
`strings`, in the order `Server/assets/js/strings.js` lists them. They are
absent from the file today rather than `null`, so this is an addition, not a
replacement.

**In the app** (the seven only). In
`App/PeaceGarden/Resources/Localizable.xcstrings`, give each key a
`localizations.<code>` entry of the shape the ten `area.*` keys already have:
`{"stringUnit": {"state": "translated", "value": "…"}}`.

Then:

1. `python3 tools/strings/commissions/2026-09-24/sheets.py --check` — this
   commission's own mechanical check: the colon, the halves agreeing between
   site and app, English left behind, the Latin kept, the front page arriving
   whole.
2. `python3 tools/strings/check.py`, `python3 tools/strings/app_check.py` and
   `python3 tools/site/export.py --check`.
3. **Look at it.** `python3 tools/site/serve.py`, then
   `http://localhost:8801/t`, the word at the door is `peace`, and pick your
   language's gardener. Then `/` for the front page and its ten cards,
   `/meanings` for the table, and `/frame` for one area's entry under its
   paragraph. In the app, the book beside a plant's name on the seed screen.

**Then somebody who reads the language has to look**, which is
`docs/REVIEWING-A-LANGUAGE.md`.

==============================================================================

# Swedish — Svenska  (sv)

**29 strings for the site and 52 for the app.** The ten site entries and twenty of the app's are the same ten headwords and definitions, written once.

Write into `Server/strings/sv.json` and `App/PeaceGarden/Resources/Localizable.xcstrings`.

## The words this language has already chosen

Commissioned and shipping. **What you write has to agree with them.**

- *seed*: **frö** (`tools/strings/terms.json`)
- `tagline`
    en  A plant grown from a meeting.
    sv  En växt vuxen ur ett möte.
- `about1`
    en  Peace Garden makes a plant out of two people meeting. Two phones hand each other a seed. What grows from the two seeds is a plant that combines their features, like a handshake or a joint garden that has some of each person. It opens over real days, in its own time.
    sv  Peace Garden gör en växt av två människor som möts. Två telefoner räcker varandra ett frö. Det som växer ur de två fröna är en växt med drag från båda, som ett handslag eller en delad trädgård där det står något av var och en. Den öppnar sig över riktiga dagar, i sin egen takt.
- `about2`
    en  A seed travels in a link as well as by touch, so it reaches a phone that has never heard of any of this.
    sv  Ett frö reser i en länk lika väl som genom beröring, och når så en telefon som aldrig hört talas om något av detta.
- `about3`
    en  A seed reaches you from someone you meet in person. Peace Garden is on iPhone and iPad.
    sv  Ett frö kommer till dig från någon du möter ansikte mot ansikte. Peace Garden finns till iPhone och iPad.
- `seedTitle`
    en  A seed has arrived
    sv  Ett frö har kommit
- `replyTitle`
    en  A seed has come back
    sv  Ett frö har kommit tillbaka
- `sentBy`
    en  Sent by {name}
    sv  Skickat av {name}
- `gardener`
    en  a gardener
    sv  en trädgårdsmästare
- `planted`
    en  Planted
    sv  Planterat
- `growTitle`
    en  Growing it
    sv  Att få det att växa
- `growBody`
    en  Peace Garden crosses this seed with one of your own, and the plant that comes of the pair is yours to keep. This meeting grows one plant, you both have it, and it stays the same for as long as you do.
    sv  Peace Garden korsar detta frö med ett eget, och växten som kommer av paret är din att behålla. Det här mötet ger en enda växt, ni har den båda två, och den förblir densamma så länge ni har den.
- `appNote`
    en  Peace Garden is on iPhone and iPad. This link keeps, so there is no hurry.
    sv  Peace Garden finns till iPhone och iPad. Länken består, så det är ingen brådska.
- `inEnglish`
    en  in English
    sv  på engelska
- `language`
    en  Language
    sv  Språk
- `keys`
    en  Keys
    sv  Tangenter
- `random`
    en  Somewhere at random
    sv  Någonstans på måfå
- `damaged`
    en  This link arrived damaged, so the seed could not be read.
    sv  Den här länken kom fram skadad, så fröet kunde inte läsas.
- `notASeed`
    en  That link does not carry a seed.
    sv  Den länken bär inget frö.
- `newerVersion`
    en  This seed came from a newer version of Peace Garden.
    sv  Det här fröet kom från en nyare version av Peace Garden.

**The ten areas**, which the front page sets under your ten meaning lines, card by card:

- `areaWaiting`  The Cold Frame  →  **Kallbänken**
- `areaGround`  The Home Ground  →  **Hembygden**
- `areaBeginnings`  The Seedbed  →  **Såbädden**
- `areaRenewal`  The Coppice  →  **Stubbskotten**
- `areaTravel`  The Long Walk  →  **Långa allén**
- `areaPeace`  The Quiet Garden  →  **Tysta trädgården**
- `areaKinship`  The Orchard  →  **Fruktträdgården**
- `areaPattern`  The Knot Garden  →  **Barockparterren**
- `areaLight`  The Glasshouse  →  **Växthuset**
- `areaMeeting`  The Crossing  →  **Korsningen**

**In the app**, the rows the new `Area` label sits among on the seed screen:

- `Seed`  →  **Frö**
- `Created`  →  **Skapat**

## The front page (11)

### `frontLead`

> Two phones touch and hand each other a seed. What grows is a plant neither could have grown alone, opening over real days.

*Where it is seen.* The front page, `/`, directly under the heading (`tagline`). It is the whole of the page for a reader who goes no further than the first screen.

*It must say:*
  - Two phones touch, and each hands the other a seed.
  - What grows is one plant that took both of them: neither person could have grown this plant alone.
  - It opens over real days.

*It must not:*
  - Read as *neither can grow anything alone*. The claim is about this plant needing both seeds, and a reader with a plant of their own already knows the other reading is false.

*Note.* Two of its three claims are already in your `about1`: *two phones hand each other a seed* and *it opens over real days*. Use the same words for them here.

### `frontTurn`

> Drag to turn

*Where it is seen.* A small hint under the plant on the front page, which turns when somebody drags it with a finger or a mouse. Visual only: a screen reader skips it.

*It must say:*
  - Dragging the plant turns it.

*Note.* The one instruction in this commission, and it is a hint on a control rather than a sentence. Use the form your language's interfaces use for such a hint — an infinitive or a short phrase is usual — and a verb for *drag* that covers a finger as well as a mouse.

### `frontMeet`

> Meet

*Where it is seen.* The first of three steps on the front page, each a heading of one word under a glyph, read left to right as a sequence: *Meet*, *Cross*, *Grow*.

*It must say:*
  - Two people meet, in person.

*Note.* The three are one form between them — three verbs, or three verbal nouns, whichever your language uses for the steps of a process. One word each where your language allows.

### `frontMeetBody`

> Two people touch phones, in the same room.

*Where it is seen.* Under *Meet*.

*It must say:*
  - Two people touch their phones together.
  - They are in the same place, physically together.

*Note.* *In the same room* stands for being there together; your language's everyday way of saying *face to face* or *in the same place* is right if a room is too literal.

### `frontCross`

> Cross

*Where it is seen.* The second step, under its glyph.

*It must say:*
  - The two seeds are crossed, as a gardener crosses two plants.

*It must not:*
  - Be a word that means only crossing a road, or a cross as a shape. A word that holds the gardener's sense as well — *krydse*, *croiser* — is exactly right.

*Note.* Your `growBody` already has the verb: *Peace Garden crosses this seed with one of your own*. Use it. Where your `areaMeeting` is the plant-cross word, the two will visibly belong together, which is right.

### `frontCrossBody`

> Each hands the other a seed, and the two seeds cross.

*Where it is seen.* Under *Cross*.

*It must say:*
  - The exchange goes both ways: each person hands the other a seed.
  - Then the two seeds are crossed.

*Note.* *Hand each other a seed* is the phrase your `about1` already has. Agree with it.

### `frontGrow`

> Grow

*Where it is seen.* The third step, under its glyph.

*It must say:*
  - A plant grows.

### `frontGrowBody`

> A plant neither could have grown alone opens over real days.

*Where it is seen.* Under *Grow*.

*It must say:*
  - The plant is one neither of the two could have grown alone.
  - It opens over real days.

*Note.* It repeats the second sentence of `frontLead`, a screen further down. Word the two alike.

### `downloadTitle`

> The app

*Where it is seen.* The front page's first button, which opens `/download`, and that page's heading.

*It must say:*
  - The app — Peace Garden on the phone — as a thing, by name.

*It must not:*
  - Be a command such as *Download* or *Get the app*. It is a heading.

### `gardenTitle`

> The garden

*Where it is seen.* The front page's second button and the heading over the ten cards. Also the name of the garden's glyph in the bar on every page, read aloud and shown on hover, and the heading of the small map at the foot of each area page.

*It must say:*
  - The garden: the place of ten areas that a reader can walk.

*Note.* A name for the place, with the article your language gives a place it means as *the one*. The word for *garden* your catalogue already uses.

### `notYet`

> Not open yet.

*Where it is seen.* On the card of each area that is still being built, on the front page, and beside the same areas in the table at `/meanings`.

*It must say:*
  - This area opens later.

*Note.* A plain statement of where things stand, matter-of-fact rather than apologetic. Keep the full stop.

## The ten entries: what each theme means

Each one is **Headword: definition.** — one colon, straight after the headword, and no other (the brief says why). The headword is the theme; the area name printed under each is yours already, and is there so the two read well together on a card.

**Your language is one of the app's.** Write each headword and definition once. The site's key is the two joined by your colon; the app's two keys are the same two pieces, the headword without the colon and the definition as it follows it.

### `meaningWaiting`  ·  app: `theme.waiting`, `theme.waiting.definition`

> Waiting: what is held back until its time, however long that is, and whoever keeps watch.

*The card it sits on.* Above **Kallbänken**. Also under that area's paragraph on its own page, and in the `/meanings` table.

*The headword.* Waiting as a noun, the act of it. The word for waiting rather than for hope or expectation.

*The definition must say:*
  - What is held back until its time comes, however long that is.
  - And whoever keeps watch over it — a person standing by.

*What the theme holds, in three* (context, not text to translate):
  - Held back — dormancy, stratification, marcescence
  - The long count — Masada dates, Beal's bottles, bamboo mast years
  - Standing and watching — patiens, abide, the gardener's shadow

### `meaningGround`  ·  app: `theme.ground`, `theme.ground.definition`

> Ground: the earth a plant stands in, and the earth that is yours.

*The card it sits on.* Above **Hembygden**. Also under that area's paragraph on its own page, and in the `/meanings` table.

*The headword.* Ground as earth. Where your language's word for it also means *reason* or *floor*, pick the one a gardener means.

*The definition must say:*
  - The earth a plant stands in.
  - And the earth that is yours — home ground, belonging.

*What the theme holds, in three* (context, not text to translate):
  - The soil itself — rhizosphere, a teaspoon of earth, Darwin's worms
  - A place you are from — querencia, Heimat, petrichor
  - A kept place — pairidaeza, colere, garden as enclosure

*Note.* *Yours* addresses the reader, informally. If your language has one word that is both soil and home, as Latin *colere* is both to till and to dwell, it is the headword.

### `meaningBeginnings`  ·  app: `theme.beginnings`, `theme.beginnings.definition`

> Beginnings: the first thing a seed does, and how much comes of it.

*The card it sits on.* Above **Såbädden**. Also under that area's paragraph on its own page, and in the `/meanings` table.

*The headword.* Beginnings, in whichever number your language speaks of beginnings as a subject.

*The definition must say:*
  - The first thing a seed does — germination.
  - And how much comes of it — small becoming large.

*What the theme holds, in three* (context, not text to translate):
  - The first act — germination, imbibition, radicle, meristem
  - Small to large — the acorn, the coco de mer against orchid dust
  - What a start settles — the Bramley pip, prime and primrose

### `meaningRenewal`  ·  app: `theme.renewal`, `theme.renewal.definition`

> Renewal: what is cut back and comes again, and what is mended.

*The card it sits on.* Above **Stubbskotten**. Also under that area's paragraph on its own page, and in the `/meanings` table.

*The headword.* Renewal: coming again, being made new.

*The definition must say:*
  - What is cut back and grows again, in the gardener's sense.
  - And what is mended — made whole after breaking.

*What the theme holds, in three* (context, not text to translate):
  - Cut and come again — coppicing, epicormic buds, the Hiroshima ginkgos
  - The turning year — If Winter comes, spring as water
  - Made whole — kintsugi, resurgam, anastasis, convalesce

### `meaningTravel`  ·  app: `theme.travel`, `theme.travel.definition`

> Travel: the ways a seed and a person go, and the pull of somewhere else.

*The card it sits on.* Above **Långa allén**. Also under that area's paragraph on its own page, and in the `/meanings` table.

*The headword.* Travel as a noun: going, the journey.

*The definition must say:*
  - The ways a seed goes and the ways a person goes, both.
  - And the pull of somewhere else — longing for a far place.

*It must not:*
  - Make *pull* a physical pulling. It is the tug of elsewhere.

*What the theme holds, in three* (context, not text to translate):
  - How a seed goes — anemochory, sea beans, the dandelion's vortex
  - The road — ad ripam, peregrinus, travel and travail
  - Far off — Fernweh, tramontane, serendipity

### `meaningPeace`  ·  app: `theme.peace`, `theme.peace.definition`

> Peace: the quiet a garden is for, and the ease that comes with it.

*The card it sits on.* Above **Tysta trädgården**. Also under that area's paragraph on its own page, and in the `/meanings` table.

*The headword.* Peace in the quiet, inward sense.

*The definition must say:*
  - The quiet a garden exists for.
  - And the ease that comes with that quiet.

*What the theme holds, in three* (context, not text to translate):
  - Quiet as a sound — psithurism, snow, the anechoic chamber
  - The words for stopping — pax, serenus, quietus, sabbath
  - At ease — hygge, sobremesa, shinrin-yoku

### `meaningKinship`  ·  app: `theme.kinship`, `theme.kinship.definition`

> Kinship: what grows together, and the people kept rather than happened upon.

*The card it sits on.* Above **Fruktträdgården**. Also under that area's paragraph on its own page, and in the `/meanings` table.

*The headword.* Kinship: belonging together as kin, by blood or by choice.

*The definition must say:*
  - What grows together — grafts, roots and fungi joined.
  - And the people kept rather than happened upon: chosen and held on to, set against chance.

*What the theme holds, in three* (context, not text to translate):
  - Grown together — inosculation, grafting, lichen, mycorrhiza
  - The words for it — sibb, God-sib, companion, kind and kin
  - Two people — Donne, Montaigne, Hávamál, ubuntu

*Note.* *Kept rather than happened upon* is Marcus's reading of the Orchard. The contrast between keeping and chance is the point of the half; keep both sides of it.

### `meaningPattern`  ·  app: `theme.pattern`, `theme.pattern.definition`

> Pattern: the order in living things, and the names given to order.

*The card it sits on.* Above **Barockparterren**. Also under that area's paragraph on its own page, and in the `/meanings` table.

*The headword.* Pattern as order in living things.

*The definition must say:*
  - The order in living things — spirals, tiling.
  - And the names given to order — the words people have for it.

*It must not:*
  - Be a sewing pattern, a template or a model to copy.

*What the theme holds, in three* (context, not text to translate):
  - Counted — the golden angle, Fibonacci spirals, quincunx
  - Fitted together — tessellation, decussate leaves, Turing patterns
  - Order named — cosmos, rhythm, ordo, the anthology

### `meaningLight`  ·  app: `theme.light`, `theme.light.definition`

> Light: what a plant turns towards, and the day it keeps time by.

*The card it sits on.* Above **Växthuset**. Also under that area's paragraph on its own page, and in the `/meanings` table.

*The headword.* Light as a noun, as in sunlight.

*The definition must say:*
  - What a plant turns towards.
  - And the day it keeps time by — a plant measures the length of the day.

*It must not:*
  - Be *light* as in weight, or the light appearance in the app's settings.

*What the theme holds, in three* (context, not text to translate):
  - The edges of the day — gloaming, alpenglow, apricity, gökotta
  - Reading the light — photoperiodism, heliotropism, the day's eye
  - Light itself — lux, solstice, phosphorus, the eight minutes

### `meaningMeeting`  ·  app: `theme.meeting`, `theme.meeting.definition`

> Meeting: two coming together at the right moment, and what each owes the other.

*The card it sits on.* Above **Korsningen**. Also under that area's paragraph on its own page, and in the `/meanings` table.

*The headword.* Meeting: two coming together, the word your `tagline` already uses for *a meeting*.

*The definition must say:*
  - Two coming together at the right moment.
  - And what each owes the other — the obligations of host and guest, of flower and pollinator.

*It must not:*
  - Be an appointment or a conference.

*What the theme holds, in three* (context, not text to translate):
  - The moment — kairos, clinamen, ichigo ichie
  - Two that need each other — fig and wasp, yucca moth, Ophrys
  - The manners of it — xenia, limen, interfulgence

## The page at /meanings (8)

### `meaningsTitle`

> What the names mean

*Where it is seen.* The heading of `/meanings`, and the words of every link to it: the book glyph in the bar on every page (read aloud and shown on hover) and the headword on each area page.

*It must say:*
  - What the names of the plants mean.

*Note.* A heading, so no full stop. In the app's languages the app's own button says *What the name means*, of one plant; the two should read as the same phrase in the singular and the plural.

### `meaningsAbout`

> A plant's name says where it belongs. The start of its first word chooses the area it stands in, and the ending chooses which of that area's three parts the words under it come from.

*Where it is seen.* The first paragraph of `/meanings`, above a worked example that takes one name apart piece by piece.

*It must say:*
  - A plant's name says where the plant belongs.
  - The beginning of the name's first word chooses the area it stands in.
  - The ending of that same first word chooses which of the area's three parts the words shown under the plant come from.

*It must not:*
  - Suggest anybody chooses or gives the name. It is drawn from the seed.

*Note.* *The words under it* are the quotation shown under a plant. *First word* is said plainly on purpose; the term *genus* arrives in the next paragraph.

### `meaningsSecond`

> The second word names the one way a plant most differs from the rest of its genus. After a first word ending in -ynth it takes its masculine form, so rubra becomes ruber.

*Where it is seen.* The second paragraph of `/meanings`, after the worked example.

*It must say:*
  - The second word of the name names the one way this plant most differs from the rest of its genus.
  - After a first word ending in -ynth, the second word takes its masculine form: rubra becomes ruber.

*Note.* `-ynth`, `rubra` and `ruber` are Latin and copied exactly, letter for letter. *Genus* and *masculine form* are the ordinary botanical and grammatical terms in your language.

### `meaningsArea`

> Area

*Where it is seen.* A column heading in the table at `/meanings`, over the ten area names.

*It must say:*
  - An area of the garden.

*Note.* One word. In the app's languages the app's name sheet has the same word as a row label (`Area`); they are one word in two places.

### `meaningsMeaning`

> What it holds

*Where it is seen.* A column heading in the table at `/meanings`, over the ten definitions; on a phone it becomes a small label above each one.

*It must say:*
  - What the theme holds: what it gathers in and is about.

### `meaningsNames`

> Names beginning

*Where it is seen.* A column heading in the table at `/meanings`, over the syllables that begin plant names in each area — *Nyx-*, *Fen-*. On a phone it becomes a label directly before the syllables.

*It must say:*
  - Names that begin with the syllables that follow.

*Note.* It has to lead straight into a list of name-beginnings, so choose the grammar that runs into one.

### `meaningsWord`

> Second word

*Where it is seen.* A column heading in the second table at `/meanings`, over Latin second words such as *ruber*.

*It must say:*
  - The second word of a plant's name.

### `meaningsSays`

> What it says of the plant

*Where it is seen.* The column heading beside `meaningsWord`, over what each second word says about its plant.

*It must say:*
  - What that word says about the plant.

## The app's name sheet (32 more)

A book beside a plant's name on the seed screen opens a sheet: the theme as a headword with its definition (the twenty keys above), the area it puts the plant in, and the theme's three parts, with the one the name's ending chose set in full ink and the other two faint. **The ten `area.*` keys are already written in your language** and are left alone.

### The thirty parts

Labels in a short list, one line each on a phone: sentence case, no full stop. Each is the name of one third of a theme, so what the examples after the dash have in common is what the label has to cover. The examples are context and are not translated.

**Waiting**

- `subtheme.heldBack`  **Held back**  
  dormancy, stratification, marcescence.  
  *One of the three parts of the theme Waiting: dormancy, a seed that will not germinate yet. Listed on the screen that explains a plant's name.*
- `subtheme.theLongCount`  **The long count**  
  Masada dates, Beal's bottles, bamboo mast years.  
  *One of the three parts of the theme Waiting: very long waits, seeds that germinated after centuries. Listed on the screen that explains a plant's name.*
- `subtheme.standingAndWatching`  **Standing and watching**  
  patiens, abide, the gardener's shadow.  
  *One of the three parts of the theme Waiting: patience, keeping watch. Listed on the screen that explains a plant's name.*

**Ground**

- `subtheme.theSoilItself`  **The soil itself**  
  rhizosphere, a teaspoon of earth, Darwin's worms.  
  *One of the three parts of the theme Ground: soil, and what lives in it. Listed on the screen that explains a plant's name.*
- `subtheme.aPlaceYouAreFrom`  **A place you are from**  
  querencia, Heimat, petrichor.  
  *One of the three parts of the theme Ground: home ground, belonging to a place. Listed on the screen that explains a plant's name.*
- `subtheme.aKeptPlace`  **A kept place**  
  pairidaeza, colere, garden as enclosure.  
  *One of the three parts of the theme Ground: a garden as a place enclosed and tended. Listed on the screen that explains a plant's name.*

**Beginnings**

- `subtheme.theFirstAct`  **The first act**  
  germination, imbibition, radicle, meristem.  
  *One of the three parts of the theme Beginnings: germination, the first root. Listed on the screen that explains a plant's name.*
- `subtheme.smallToLarge`  **Small to large**  
  the acorn, the coco de mer against orchid dust.  
  *One of the three parts of the theme Beginnings: the acorn and the oak. Listed on the screen that explains a plant's name.*
- `subtheme.whatAStartSettles`  **What a start settles**  
  the Bramley pip, prime and primrose.  
  *One of the three parts of the theme Beginnings: what a beginning decides about everything after it. Listed on the screen that explains a plant's name.*

**Renewal**

- `subtheme.cutAndComeAgain`  **Cut and come again**  
  coppicing, epicormic buds, the Hiroshima ginkgos.  
  *One of the three parts of the theme Renewal: a plant cut back that grows again. A gardener's phrase. Listed on the screen that explains a plant's name.*
- `subtheme.theTurningYear`  **The turning year**  
  If Winter comes, spring as water.  
  *One of the three parts of the theme Renewal: the seasons coming round. Listed on the screen that explains a plant's name.*
- `subtheme.madeWhole`  **Made whole**  
  kintsugi, resurgam, anastasis, convalesce.  
  *One of the three parts of the theme Renewal: mending and healing, what was broken made whole. Listed on the screen that explains a plant's name.*

**Travel**

- `subtheme.howASeedGoes`  **How a seed goes**  
  anemochory, sea beans, the dandelion's vortex.  
  *One of the three parts of the theme Travel: how seeds are carried by wind and water. Listed on the screen that explains a plant's name.*
- `subtheme.theRoad`  **The road**  
  ad ripam, peregrinus, travel and travail.  
  *One of the three parts of the theme Travel: journeys and pilgrims. Listed on the screen that explains a plant's name.*
- `subtheme.farOff`  **Far off**  
  Fernweh, tramontane, serendipity.  
  *One of the three parts of the theme Travel: distance, and the longing for somewhere else. Listed on the screen that explains a plant's name.*

**Peace**

- `subtheme.quietAsASound`  **Quiet as a sound**  
  psithurism, snow, the anechoic chamber.  
  *One of the three parts of the theme Peace: quiet as something heard, wind in trees, snow. Listed on the screen that explains a plant's name.*
- `subtheme.theWordsForStopping`  **The words for stopping**  
  pax, serenus, quietus, sabbath.  
  *One of the three parts of the theme Peace: the words for rest and ceasing. Listed on the screen that explains a plant's name.*
- `subtheme.atEase`  **At ease**  
  hygge, sobremesa, shinrin-yoku.  
  *One of the three parts of the theme Peace: comfort, being at ease with others. Listed on the screen that explains a plant's name.*

**Kinship**

- `subtheme.grownTogether`  **Grown together**  
  inosculation, grafting, lichen, mycorrhiza.  
  *One of the three parts of the theme Kinship: grafts, lichen, roots and fungi joined. Listed on the screen that explains a plant's name.*
- `subtheme.theWordsForIt`  **The words for it**  
  sibb, God-sib, companion, kind and kin.  
  *One of the three parts of the theme Kinship: the words people have for kin and companions. Listed on the screen that explains a plant's name.*
- `subtheme.twoPeople`  **Two people**  
  Donne, Montaigne, Hávamál, ubuntu.  
  *One of the three parts of the theme Kinship: friendship between two people. Listed on the screen that explains a plant's name.*

**Pattern**

- `subtheme.counted`  **Counted**  
  the golden angle, Fibonacci spirals, quincunx.  
  *One of the three parts of the theme Pattern: patterns that are numbers, spirals and the golden angle. Listed on the screen that explains a plant's name.*
- `subtheme.fittedTogether`  **Fitted together**  
  tessellation, decussate leaves, Turing patterns.  
  *One of the three parts of the theme Pattern: shapes that tile and interlock. Listed on the screen that explains a plant's name.*
- `subtheme.orderNamed`  **Order named**  
  cosmos, rhythm, ordo, the anthology.  
  *One of the three parts of the theme Pattern: the words people have for order. Listed on the screen that explains a plant's name.*

**Light**

- `subtheme.theEdgesOfTheDay`  **The edges of the day**  
  gloaming, alpenglow, apricity, gökotta.  
  *One of the three parts of the theme Light: dawn and dusk. Listed on the screen that explains a plant's name.*
- `subtheme.readingTheLight`  **Reading the light**  
  photoperiodism, heliotropism, the day's eye.  
  *One of the three parts of the theme Light: how a plant senses light and turns to it. Listed on the screen that explains a plant's name.*
- `subtheme.lightItself`  **Light itself**  
  lux, solstice, phosphorus, the eight minutes.  
  *One of the three parts of the theme Light: sunlight as a thing in itself. Listed on the screen that explains a plant's name.*

**Meeting**

- `subtheme.theMoment`  **The moment**  
  kairos, clinamen, ichigo ichie.  
  *One of the three parts of the theme Meeting: the right moment, a chance meeting. Listed on the screen that explains a plant's name.*
- `subtheme.twoThatNeedEachOther`  **Two that need each other**  
  fig and wasp, yucca moth, Ophrys.  
  *One of the three parts of the theme Meeting: a flower and its pollinator. Listed on the screen that explains a plant's name.*
- `subtheme.theMannersOfIt`  **The manners of it**  
  xenia, limen, interfulgence.  
  *One of the three parts of the theme Meeting: hospitality, how a guest is received. Listed on the screen that explains a plant's name.*

### Two more

- `Area`  
  *Row label on the screen that explains a plant's name, beside the place in the shared garden the plant belongs to, such as 'The Cold Frame'. A part of a garden, not a measurement. The website heads its table with the same word (key meaningsArea).*
- `What the name means`  
  *The book mark beside a plant's name on the seed screen, read aloud. It opens a page explaining what the plant's name says about it.*

  `Area` is the same word as the site's `meaningsArea`. `What the name means` is the site's `meaningsTitle` said of one plant.
