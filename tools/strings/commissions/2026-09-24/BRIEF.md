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
