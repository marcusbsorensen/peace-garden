# The front page, and what the names mean

Fifty-five short strings for the website, in forty-one languages; for the
app's seven languages, fifty-two for the sheet that explains a plant's name,
all but two of them the website's own words split or repeated. Each language has its own sheet in `sheets/<code>.md`, which is this
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
  glyph as three steps; the thirty part labels are a short list. If
  your language needs two words, use two, and no more.
- **Sentence case.** The tracked-out capitals on the page are set by the
  stylesheet, and some languages are excluded from them — that is handled for
  you.

## The ten `meaning*` lines, and the one colon

Each is one line in the form **Headword: definition.**

> Waiting: what is held back until its time, however long that is, and whoever keeps watch.

The site cuts the line at its **first colon** and sets what comes before it as
a dictionary headword — on each area page, on each of the ten cards on the
front page, and as that area's entry at `/meanings`. The colon itself is used up by
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
   `/meanings` for the entries, and `/frame` for one area's entry under its
   paragraph. In the app, the book beside a plant's name on the seed screen.

**Then somebody who reads the language has to look**, which is
`docs/REVIEWING-A-LANGUAGE.md`.

==============================================================================

# Czech — Čeština  (cs)

**55 strings for the site.** Your language is not one of the app's, so there is no app half.

Write into `Server/strings/cs.json`.

## The words this language has already chosen

Commissioned and shipping. **What you write has to agree with them.**

- *seed*: **semínko** (`tools/strings/terms.json`)
- `tagline`
    en  A plant grown from a meeting.
    cs  Rostlina vyrostlá ze setkání.
- `about1`
    en  Peace Garden makes a plant out of two people meeting. Two phones hand each other a seed. What grows from the two seeds is a plant that combines their features, like a handshake or a joint garden that has some of each person. It opens over real days, in its own time.
    cs  Peace Garden dělá ze setkání dvou lidí rostlinu. Dva telefony si podají semínko. To, co ze dvou semínek vyroste, je rostlina s rysy obou — jako podání ruky nebo společná zahrada, ve které je něco od každého. Otevírá se v průběhu skutečných dnů, svým vlastním tempem.
- `about2`
    en  A seed travels in a link as well as by touch, so it reaches a phone that has never heard of any of this.
    cs  Semínko cestuje v odkazu stejně jako dotykem, a dostane se tak do telefonu, který o ničem z toho nikdy neslyšel.
- `about3`
    en  A seed reaches you from someone you meet in person. Peace Garden is on iPhone and iPad.
    cs  Semínko k tobě přichází od někoho, koho potkáš osobně. Peace Garden je na iPhonu a iPadu.
- `seedTitle`
    en  A seed has arrived
    cs  Přišlo semínko
- `replyTitle`
    en  A seed has come back
    cs  Semínko se vrátilo
- `sentBy`
    en  Sent by {name}
    cs  Od {name}
- `gardener`
    en  a gardener
    cs  zahradník
- `planted`
    en  Planted
    cs  Zasazeno
- `growTitle`
    en  Growing it
    cs  Pěstování
- `growBody`
    en  Peace Garden crosses this seed with one of your own, and the plant that comes of the pair is yours to keep. This meeting grows one plant, you both have it, and it stays the same for as long as you do.
    cs  Peace Garden zkříží tohle semínko s jedním tvým a rostlina, která z páru vzejde, zůstane tobě. Z tohohle setkání vyroste jedna rostlina, máte ji oba a zůstává stejná, dokud ji máte.
- `appNote`
    en  Peace Garden is on iPhone and iPad. This link keeps, so there is no hurry.
    cs  Peace Garden je na iPhonu a iPadu. Odkaz zůstává, takže není kam spěchat.
- `inEnglish`
    en  in English
    cs  anglicky
- `language`
    en  Language
    cs  Jazyk
- `keys`
    en  Keys
    cs  Klávesy
- `random`
    en  Somewhere at random
    cs  Někam náhodně
- `damaged`
    en  This link arrived damaged, so the seed could not be read.
    cs  Tento odkaz přišel poškozený, semínko se nepodařilo přečíst.
- `notASeed`
    en  That link does not carry a seed.
    cs  Tento odkaz žádné semínko nenese.
- `newerVersion`
    en  This seed came from a newer version of Peace Garden.
    cs  Toto semínko pochází z novější verze Peace Garden.

**The ten areas**, which the front page sets under your ten meaning lines, card by card:

- `areaWaiting`  The Cold Frame  →  **Zimoviště**
- `areaGround`  The Home Ground  →  **Rodná země**
- `areaBeginnings`  The Seedbed  →  **Semeniště**
- `areaRenewal`  The Coppice  →  **Výmladky**
- `areaTravel`  The Long Walk  →  **Dlouhá alej**
- `areaPeace`  The Quiet Garden  →  **Tichá zahrada**
- `areaKinship`  The Orchard  →  **Sad**
- `areaPattern`  The Knot Garden  →  **Barokní zahrada**
- `areaLight`  The Glasshouse  →  **Skleník**
- `areaMeeting`  The Crossing  →  **Křižovatka**

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

*Where it is seen.* On the card of each area that is still being built, on the front page, and beside the same areas' names in their entries at `/meanings`.

*It must say:*
  - This area opens later.

*Note.* A plain statement of where things stand, matter-of-fact rather than apologetic. Keep the full stop.

## The ten entries: what each theme means

Each one is **Headword: definition.** — one colon, straight after the headword, and no other (the brief says why). The headword is the theme; the area name printed under each is yours already, and is there so the two read well together on a card.

### `meaningWaiting`

> Waiting: what is held back until its time, however long that is, and whoever keeps watch.

*The card it sits on.* Above **Zimoviště**. Also under that area's drawing on its own page, and as its entry at `/meanings`.

*The headword.* Waiting as a noun, the act of it. The word for waiting rather than for hope or expectation.

*The definition must say:*
  - What is held back until its time comes, however long that is.
  - And whoever keeps watch over it — a person standing by.

*What the theme holds, in three* (context, not text to translate):
  - Held back — dormancy, stratification, marcescence
  - The long count — Masada dates, Beal's bottles, bamboo mast years
  - Standing and watching — patiens, abide, the gardener's shadow

### `meaningGround`

> Ground: the earth a plant stands in, and the earth that is yours.

*The card it sits on.* Above **Rodná země**. Also under that area's drawing on its own page, and as its entry at `/meanings`.

*The headword.* Ground as earth. Where your language's word for it also means *reason* or *floor*, pick the one a gardener means.

*The definition must say:*
  - The earth a plant stands in.
  - And the earth that is yours — home ground, belonging.

*What the theme holds, in three* (context, not text to translate):
  - The soil itself — rhizosphere, a teaspoon of earth, Darwin's worms
  - A place you are from — querencia, Heimat, petrichor
  - A kept place — pairidaeza, colere, garden as enclosure

*Note.* *Yours* addresses the reader, informally. If your language has one word that is both soil and home, as Latin *colere* is both to till and to dwell, it is the headword.

### `meaningBeginnings`

> Beginnings: the first thing a seed does, and how much comes of it.

*The card it sits on.* Above **Semeniště**. Also under that area's drawing on its own page, and as its entry at `/meanings`.

*The headword.* Beginnings, in whichever number your language speaks of beginnings as a subject.

*The definition must say:*
  - The first thing a seed does — germination.
  - And how much comes of it — small becoming large.

*What the theme holds, in three* (context, not text to translate):
  - The first act — germination, imbibition, radicle, meristem
  - Small to large — the acorn, the coco de mer against orchid dust
  - What a start settles — the Bramley pip, prime and primrose

### `meaningRenewal`

> Renewal: what is cut back and comes again, and what is mended.

*The card it sits on.* Above **Výmladky**. Also under that area's drawing on its own page, and as its entry at `/meanings`.

*The headword.* Renewal: coming again, being made new.

*The definition must say:*
  - What is cut back and grows again, in the gardener's sense.
  - And what is mended — made whole after breaking.

*What the theme holds, in three* (context, not text to translate):
  - Cut and come again — coppicing, epicormic buds, the Hiroshima ginkgos
  - The turning year — If Winter comes, spring as water
  - Made whole — kintsugi, resurgam, anastasis, convalesce

### `meaningTravel`

> Travel: the ways a seed and a person go, and the pull of somewhere else.

*The card it sits on.* Above **Dlouhá alej**. Also under that area's drawing on its own page, and as its entry at `/meanings`.

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

### `meaningPeace`

> Peace: the quiet a garden is for, and the ease that comes with it.

*The card it sits on.* Above **Tichá zahrada**. Also under that area's drawing on its own page, and as its entry at `/meanings`.

*The headword.* Peace in the quiet, inward sense.

*The definition must say:*
  - The quiet a garden exists for.
  - And the ease that comes with that quiet.

*What the theme holds, in three* (context, not text to translate):
  - Quiet as a sound — psithurism, snow, the anechoic chamber
  - The words for stopping — pax, serenus, quietus, sabbath
  - At ease — hygge, sobremesa, shinrin-yoku

### `meaningKinship`

> Kinship: what grows together, and the people kept rather than happened upon.

*The card it sits on.* Above **Sad**. Also under that area's drawing on its own page, and as its entry at `/meanings`.

*The headword.* Kinship: belonging together as kin, by blood or by choice.

*The definition must say:*
  - What grows together — grafts, roots and fungi joined.
  - And the people kept rather than happened upon: chosen and held on to, set against chance.

*What the theme holds, in three* (context, not text to translate):
  - Grown together — inosculation, grafting, lichen, mycorrhiza
  - The words for it — sibb, God-sib, companion, kind and kin
  - Two people — Donne, Montaigne, Hávamál, ubuntu

*Note.* *Kept rather than happened upon* is Marcus's reading of the Orchard. The contrast between keeping and chance is the point of the half; keep both sides of it.

### `meaningPattern`

> Pattern: the order in living things, and the names given to order.

*The card it sits on.* Above **Barokní zahrada**. Also under that area's drawing on its own page, and as its entry at `/meanings`.

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

### `meaningLight`

> Light: what a plant turns towards, and the day it keeps time by.

*The card it sits on.* Above **Skleník**. Also under that area's drawing on its own page, and as its entry at `/meanings`.

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

### `meaningMeeting`

> Meeting: two coming together at the right moment, and what each owes the other.

*The card it sits on.* Above **Křižovatka**. Also under that area's drawing on its own page, and as its entry at `/meanings`.

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

## The page at /meanings (4)

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

*Where it is seen.* The paragraph after the ten entries at `/meanings`, above the glossary of second words it introduces.

*It must say:*
  - The second word of the name names the one way this plant most differs from the rest of its genus.
  - After a first word ending in -ynth, the second word takes its masculine form: rubra becomes ruber.

*Note.* `-ynth`, `rubra` and `ruber` are Latin and copied exactly, letter for letter. *Genus* and *masculine form* are the ordinary botanical and grammatical terms in your language.

### `meaningsNames`

> Names beginning

*Where it is seen.* A small label in each entry at `/meanings`, where a dictionary gives a word's etymology, leading straight into the name-starts that bring a plant to that area — *Nyx-*, *Fen-*, each with a drawing and its root.

*It must say:*
  - Names that begin with the syllables that follow.

*Note.* It has to lead straight into a list of name-beginnings, so choose the grammar that runs into one.

## The thirty parts (30)

Each theme's three parts, as the numbered senses of its entry: under the definition on an area's page, and at `/meanings` with the endings that choose each one. Labels in a short list, one line each on a phone: sentence case, no full stop. What the examples have in common is what a label has to cover; the examples stay in English on the page.

**Waiting**

- `subthemeHeldBack`  **Held back**  
  Dormancy: a seed or a bud held until its season.  
  *dormancy, stratification, marcescence*
- `subthemeTheLongCount`  **The long count**  
  Very long waits: seeds that germinated after centuries.  
  *Masada dates, Beal's bottles, bamboo mast years*
- `subthemeStandingAndWatching`  **Standing and watching**  
  Patience: keeping watch while it happens.  
  *patiens, abide, the gardener's shadow*

**Ground**

- `subthemeTheSoilItself`  **The soil itself**  
  The soil, and what lives in it.  
  *rhizosphere, a teaspoon of earth, Darwin's worms*
- `subthemeAPlaceYouAreFrom`  **A place you are from**  
  Home ground: belonging to a place.  
  *querencia, Heimat, petrichor*
- `subthemeAKeptPlace`  **A kept place**  
  A garden as a place enclosed and tended.  
  *pairidaeza, colere, garden as enclosure*

**Beginnings**

- `subthemeTheFirstAct`  **The first act**  
  Germination: the first root a seed puts out.  
  *germination, imbibition, radicle, meristem*
- `subthemeSmallToLarge`  **Small to large**  
  The acorn and the oak: how much grows from how little.  
  *the acorn, the coco de mer against orchid dust*
- `subthemeWhatAStartSettles`  **What a start settles**  
  What a beginning decides about everything after it.  
  *the Bramley pip, prime and primrose*

**Renewal**

- `subthemeCutAndComeAgain`  **Cut and come again**  
  A plant cut back that grows again — a gardener's phrase in English.  
  *coppicing, epicormic buds, the Hiroshima ginkgos*
- `subthemeTheTurningYear`  **The turning year**  
  The seasons coming round.  
  *If Winter comes, spring as water*
- `subthemeMadeWhole`  **Made whole**  
  Mending and healing: what was broken, made whole.  
  *kintsugi, resurgam, anastasis, convalesce*

**Travel**

- `subthemeHowASeedGoes`  **How a seed goes**  
  How seeds are carried, by wind and by water.  
  *anemochory, sea beans, the dandelion's vortex*
- `subthemeTheRoad`  **The road**  
  Journeys, and the people who make them.  
  *ad ripam, peregrinus, travel and travail*
- `subthemeFarOff`  **Far off**  
  Distance, and the longing for somewhere else.  
  *Fernweh, tramontane, serendipity*

**Peace**

- `subthemeQuietAsASound`  **Quiet as a sound**  
  Quiet as something heard: wind in trees, snow falling.  
  *psithurism, snow, the anechoic chamber*
- `subthemeTheWordsForStopping`  **The words for stopping**  
  The words people have for rest and ceasing.  
  *pax, serenus, quietus, sabbath*
- `subthemeAtEase`  **At ease**  
  Comfort: being at ease, with others and alone.  
  *hygge, sobremesa, shinrin-yoku*

**Kinship**

- `subthemeGrownTogether`  **Grown together**  
  Grafts, lichen, roots and fungi joined into one.  
  *inosculation, grafting, lichen, mycorrhiza*
- `subthemeTheWordsForIt`  **The words for it**  
  The words people have for kin and companions.  
  *sibb, God-sib, companion, kind and kin*
- `subthemeTwoPeople`  **Two people**  
  Friendship between two people.  
  *Donne, Montaigne, Hávamál, ubuntu*

**Pattern**

- `subthemeCounted`  **Counted**  
  Patterns that are numbers: spirals, the golden angle.  
  *the golden angle, Fibonacci spirals, quincunx*
- `subthemeFittedTogether`  **Fitted together**  
  Shapes that tile and interlock.  
  *tessellation, decussate leaves, Turing patterns*
- `subthemeOrderNamed`  **Order named**  
  The words people have for order.  
  *cosmos, rhythm, ordo, the anthology*

**Light**

- `subthemeTheEdgesOfTheDay`  **The edges of the day**  
  Dawn and dusk.  
  *gloaming, alpenglow, apricity, gökotta*
- `subthemeReadingTheLight`  **Reading the light**  
  How a plant senses light and turns to it.  
  *photoperiodism, heliotropism, the day's eye*
- `subthemeLightItself`  **Light itself**  
  Sunlight as a thing in itself.  
  *lux, solstice, phosphorus, the eight minutes*

**Meeting**

- `subthemeTheMoment`  **The moment**  
  The right moment: a meeting that happens when it should.  
  *kairos, clinamen, ichigo ichie*
- `subthemeTwoThatNeedEachOther`  **Two that need each other**  
  A flower and its pollinator: two that live by each other.  
  *fig and wasp, yucca moth, Ophrys*
- `subthemeTheMannersOfIt`  **The manners of it**  
  Hospitality: how a guest is received.  
  *xenia, limen, interfulgence*
