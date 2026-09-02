# Languages

Written 2 September 2026. **Scope only — nothing here is built.** The question
was whether the app can follow the language the phone is already set to, on the
grounds that a peace garden that presumes English is not one.

The short answer: the interface, yes, and cheaply. The passages, no, and the
reason is worth understanding before anybody promises otherwise.

## What the app is made of, by language

| | Roughly | Translatable? |
| --- | --- | --- |
| Interface strings — buttons, labels, headings, explanations | ~180 | Yes, ordinarily |
| The 300 passages and their provenance | 300 | **See below.** Mostly not |
| Plant names | 0 | Already language-neutral |
| Growth stages, archetypes, figurative places | ~30 | Yes |
| Dates, times, numbers | 0 | Already localised by the system |

## The interface: a fortnight, not a rewrite

**String Catalogs.** Xcode extracts every `Text("…")` literal in the app into a
single `.xcstrings` file, and SwiftUI looks each one up at runtime against the
phone's language. Nothing in the source has to change to *start*: the literals
already in place become the keys.

The work is:

1. Add `Localizable.xcstrings` to `App/PeaceGarden/Resources`, and to
   `project.yml` as a resource. Turn on string extraction for the target.
2. Build once. Every literal appears in the catalogue as an English source
   string awaiting translations.
3. Go through what extraction gets wrong. Two kinds:
   - **Interpolations that hide grammar.** `"\(count) grown from meetings"` is
     wrong in every language with a plural rule other than English's, and wrong
     in English at one. A catalogue holds plural variations; each such string
     has to be marked up as one.
   - **Strings built rather than written.** `"\(stage) · \(name)"` on a garden
     tile, `"When \(days) days old"`, `"Seen as \(name)"`. Each needs a format
     string with named arguments so a translator can reorder them.
4. Add a comment to every entry that needs one. `Opens` is a verb here and a
   noun in most dictionaries; `Seed` is the button that shows your own seed, not
   an instruction to sow one. A translator without those notes will guess, and
   about a fifth of the time guess wrong.
5. Right-to-left. The layout is built on leading/trailing rather than
   left/right, so it should mirror on its own — but three things need looking
   at rather than assuming: the `SproutingRule`'s tendrils (mirrored already,
   but the pair is asymmetric under `curlingDown`), the garden tile grid, and
   the QR code, which must **not** mirror.
6. Type. The chrome is set at 11pt with 2.4 tracking and uppercased. German
   compounds will overflow the mark labels; `textCase(.uppercase)` is wrong for
   Turkish dotted i and for Greek accents, and should be a per-language
   decision rather than a global modifier.

None of that is hard. All of it is the ordinary work, and it is roughly a
fortnight for one language plus a few days each thereafter.

## The passages: this is the real question

The bank is not 300 strings. It is 300 **quotations, definitions, etymologies
and facts, each carrying its provenance**, and they do not survive translation
as a class. Four kinds, four different problems:

- **Quotations.** Translating Marvell's "a green thought in a green shade" into
  Dutch produces a Dutch sentence that Marvell did not write, still credited to
  Marvell. Where a published translation exists and is out of copyright it can
  be used and must be credited to its translator — which is another line of
  provenance per passage per language. Where one does not, the honest options
  are to leave the passage in English or to drop it.
- **Etymologies of English words.** "Quiet and quit are one word." "Kind and kin
  are one word." "Daisy is the day's eye." These are facts *about English* and
  are simply false in Dutch. About sixty passages are of this kind. They cannot
  be translated; they would have to be **replaced** with the equivalent fact in
  the target language, which is original editorial work by somebody who knows
  that language's word histories.
- **Etymologies of Latin and Greek.** These travel — *pax* is *pax* whoever is
  reading — but the English gloss around them needs rewriting rather than
  translating.
- **Facts.** Snow absorbing high notes, the fig and its wasp, the golden angle.
  These translate cleanly. Perhaps a hundred passages.

So a full localisation of the bank is not a translation job at all. It is a
**commission**: roughly 200 passages per language written from scratch by
somebody with the languages and the reading, against the rules already set out
at the top of `Quotes.swift` — long-dead authors, public-domain translations
credited, nothing lifted from a reference book's wording.

### The three honest options

1. **Interface localised, passages in English.** Cheap, shippable, and the
   passage screen is the one moment the app speaks at length — so it is also the
   moment the English is most conspicuous. Defensible if the passage carries a
   line saying which language it is in.
2. **Interface localised, passages hidden where there is no bank.** The meeting
   still works; it simply says less. Consistent with the app's own instincts,
   and it makes the passage a thing some languages have rather than a thing
   English speakers get and others get badly.
3. **A bank per language, commissioned.** The right answer, and the expensive
   one. It also scales badly: ten themes × three subthemes × ten lines is the
   floor for a language, and the subtheme structure means a thin bank shows.

**The recommendation is 1 now and 3 for the two or three languages that earn
it.** Option 2 is the fallback if a language gets an interface and no bank.

## What the map already gives away for free

Worth saying, because it is a real piece of luck. `docs/NAMES-AND-THEMES.md`
made a plant's name carry its theme, and **plant names are already
language-neutral** — synthesised Latinate binomials, which is the international
convention for plants and reads the same in Amsterdam as in Margate. A hybrid
called *Zephanis stellula* needs no translation anywhere, and the theme it
belongs to is legible from the name to anybody who reads any Latin at all.

The same is true of the marks. Every glyph drawn in `Glyphs.swift` and
`Chrome.swift` says its thing without a word, which is why the mark row at the
foot of the stage is a better foundation for this than the three words it
replaced — and why **turning the plant's name off leaves a screen that is
already in every language**. That switch is in Settings today. It is worth
knowing that it is not only a preference about clutter.

## Order of work

1. Extract to a String Catalog and fix the interpolations and plurals. One day.
2. Comments for translators, and the uppercase and tracking review. Two days.
3. One language end to end — Dutch is the obvious first, given who asked — with
   the passages left in English and labelled. A week.
4. Right-to-left check with a pseudolanguage before committing to Arabic or
   Hebrew.
5. Decide about banks, per language, on the evidence of whether anybody there
   is using it.
