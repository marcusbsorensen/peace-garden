# Languages

Written 2 September 2026 as a scope document, and **built the same day**. What
follows is the record of what the app now does, so the numbers below are
measured rather than estimated and the copy quoted is the copy in the
catalogue. The question was whether the app can follow the language the phone is
already set to, on the grounds that a peace garden that presumes English is not
one.

**The interface, yes, and it now does.** Eight languages: English as the source,
and Dutch, Danish, French, Spanish, Norwegian Bokmål, Swedish and Italian
translated from it. The passages are still English, and the reason is set out
further down; nothing about that has changed.

## What the app is made of, by language

| | Strings | Where they are |
| --- | --- | --- |
| Interface — buttons, labels, headings, explanations | **191** | `App/PeaceGarden/Resources/Localizable.xcstrings` |
| The three system permission prompts | **3** | `App/PeaceGarden/Resources/InfoPlist.xcstrings` |
| The 300 passages and their provenance | 300 | `Views/Quotes.swift`, **English, untranslated** |
| Plant names | 0 | already language-neutral |
| Growth stages, plant forms, figurative places | 58 | inside the 191 above |
| Dates, times, intervals, numbers | 0 | already localised by the system |

Of the 191: 40 figurative places, 12 plant forms, 6 growth stages and 4 plurals.
The remaining 129 are the sentences, labels, buttons, prompts and values on the
screens.

## What extraction gave, and what it missed

**The first build extracted 67 of the 191**, and seven of those 67 were things
that should never have been in a translator's file at all: an empty key from
`TextField("", …)`, two `#Preview` captions, and four developer controls.
So sixty real strings out of a hundred and ninety-one. **The other hundred and
thirty-one were invisible to extraction, and every one of them was on screen.**

The reason is one distinction, and it is the whole of the work:

> `Text(someString)` is drawn exactly as handed over. `Text(someKey)` is looked
> up in the catalogue first. They are spelled the same at the call site.

Every helper in the app took a `String`. `QuietButton(title: "Close")`,
`ChromeIconLabel(title: "Garden")`, `HoldToConfirm(title:consequence:)`,
`ExchangeView.waiting(title:detail:)`, `field(label:prompt:)` — each of them
accepted a literal, and each of them quietly turned it into text nobody could
translate. They now take `LocalizedStringKey` or `LocalizedStringResource`, and
the literals at every call site are extracted.

`LocalizedStringResource` where a `String` is needed as well as a `Text` —
`HoldToConfirm` speaks its consequence through `AccessibilityNotification`, and
`PollenExchangeService` builds its failures before any view sees them.
`LocalizedStringKey` everywhere else, because it is the smaller thing.

### The four strings that hid a plural

Marked up as plural variations, with `one` and `other` in all eight languages.
French counts nought as `one`, so each singular has to read at nought as well as
at one; the other seven use `one` for one alone.

| Key | Where | Wrong in English at |
| --- | --- | --- |
| `%lld grown from meetings` | the garden's heading | 1 |
| `%lld left` | characters left in a note | — |
| `It will open like this in %lld days` | under a new plant | 1 |
| `When %lld days old` | the seed screen's first bloom | 1 |

`%lld left` is the odd one: no English word in it inflects, so it looks like it
does not need the markup. It does — the translations now read *nog 1 teken* and
*nog 12 tekens*, *queda 1 carácter* and *quedan 12 caracteres*, which is a
better line than the English and would have been impossible without it.

### The strings that were built rather than written

Each is now a format string whose arguments a translator can reorder.

| Was | Is | Note |
| --- | --- | --- |
| `"\(stage) · \(name)"` | `tile.caption` | a stage and a person |
| `growth.summary()` | `stage.caption` | a stage and an interval |
| `"When \(days) days old"` | a plural | |
| `"Seen as \(name)"` | `Seen as %@` | |
| `"From \(peer)'s \(plant)"` | `From %1$@’s %2$@` | two names, reordered in five of the seven |
| `"\(petals) across \(layers)"` | `%1$lld across %2$lld` | |
| `"\(label(reset))?"` | one question per row | |

**The two captions have symbolic keys, and that is deliberate.** Both would have
been written `%1$@ · %2$@`, they mean different things, and two entries that
read the same cannot share a key. They are the only two symbolic keys in the
catalogue; everything else is keyed on its English.

**`%lld across %lld` has no plural**, and the comment says why: no noun is
written in English or in any of the seven, so nothing agrees with either number.
A language that cannot say it without the noun should ask for a plural variation
rather than guess.

### What moved out of SeedCore

`GrowthModel.State.summary()` is gone. It assembled the caption under a plant
out of `stage.displayName.lowercased()` and a `DateComponentsFormatter`, and it
could not stay: a stage name is a word somebody reads, and lowercasing an
English identifier is not how any other language forms the same caption. The
caption is now `GrowthModel.State.caption()` in `Views/Localised.swift`, which
also holds the app's words for the six growth stages and the twelve plant forms.
`displayName` in SeedCore is what it always was — an identifier, for a log and
for the developer panel.

`Places.all` is now `[LocalizedStringResource]` rather than `[String]`, which is
what makes the compiler extract all forty. A resource carries its English phrase
as its `key`, and **the key is what goes into `UserDefaults`** — so a standing
choice of place made in one language is still the same place after the phone is
switched to another.

### What is deliberately not in the catalogue

- **The developer controls.** Everything in `DeveloperControls.swift` is
  `Text(verbatim:)`. Not because developers read English, but because the file
  is inside `#if DEBUG`: a catalogue synced from a Release build would mark
  those strings stale and a Debug build would bring them back. Verbatim makes
  the builds agree, and that is checked rather than assumed: a Debug simulator
  build, a Debug device build and a Release device build were each synced into
  the catalogue in turn and **none of the three changed a byte of it**.
- **The simulator's stand-in for the knock**, for the same reason.
- **`#Preview` captions**, for the same reason.
- **The abort reason on the wire** — `"same seed"`, `"checksum mismatch"`. It
  is a diagnostic for whoever reads a bug report, not a sentence.
- **The passages.** See below.

## The catalogue itself

`Localizable.xcstrings`, 191 entries, and **every one carries a comment**. That
is the part most often skipped and it is the part that decides whether a
translation is right, because a translator cannot run the app. The comments say
where a string appears and what it is doing:

> **Opens** — Row label on the seed screen, beside 'By day' or 'By night'. A
> verb: when the flower opens. Not an opening, and not the imperative.
>
> **Seed** — The mark at the foot of the main screen that opens your own seed,
> and the label on the row showing it. A noun: the seed itself.
>
> **Meet** — The act of two people meeting, not an appointment. It is also the
> screen's name and is said inside other sentences, so it has to read as a name.
>
> **Log places** — Log as in write down, not as in a wooden log. It sits beside
> 'Not now' on one line inside 40pt margins, which leaves about 250 points for
> the pair — so the verb on its own is better here than the verb with its
> object.
>
> **Crossing** — Title for the second or two while the two seeds are being
> crossed. A verb — this is what is happening now.
>
> **Nothing took** — 'Took' as a cutting takes: the plant did not root.

The scope guessed a translator would get about a fifth of them wrong unaided,
and writing the seven languages against them, that looks about right. The ones
that would have gone worst are the terse ones: `Opens`, `Met`, `Where`,
`Created`, `Leave it`, `Let it go`, `None`, `Crossing`, and the twelve plant
forms, where *Plume* is a panicle and *Spire* is a flower spike and neither is
what a dictionary offers first.

Comments live in the catalogue rather than in the Swift, except where a
`String(localized:)` call already takes one. The catalogue is the file a
translator opens, and `xcstringstool sync` keeps what is there.

### Keeping it in step

`xcodebuild` writes the `.stringsdata` files and stops. Only Xcode itself merges
them into the catalogue, which on a machine that builds from the command line
means the catalogue quietly stops matching the source. **`tools/strings/sync.sh`
is that missing step**, run after a build:

```
xcodebuild … -derivedDataPath build
tools/strings/sync.sh build
```

New literals arrive untranslated; a literal that has gone is marked `stale`
rather than deleted, so a translation is never lost to a refactor.

## Voice

The British-English original is plain, unhurried, never exclamatory, and says
what a thing *is* rather than what it is not. Each language was written to that
rather than translated word for word.

**Informal address everywhere, and it was a decision.** Dutch *je*, Danish and
Norwegian and Swedish *du*, French *tu*, Spanish *tú*, Italian *tu*. The app
speaks to one person about their own plant; the formal register would make it
institutional, and it is the wrong voice for a screen that says *your garden
keeps every plant you have grown with somebody*.

Three consequences worth writing down:

- **Spanish avoids the second-person plural entirely.** *Vosotros* is
  Peninsular and *ustedes* is not, and several of these sentences are about two
  people at once. Rather than pick a hemisphere, they are rephrased around it —
  *los dos teléfonos*, *las dos personas*, *el lugar del encuentro*. French,
  Italian, Dutch and the Scandinavian three use their ordinary plural.
- **"Gardener" is translated, and the word travels.** It is the name somebody is
  called before they have given one, and it is sent to the other phone. So two
  people meeting across a language boundary may see different fallbacks —
  *Tuinier* on one screen and *Gardener* on the other. The alternative was to
  send an empty name and let each phone render its own, which is a change to
  what is on the wire and belongs in its own commit.
- **Its gender is the masculine default in French, Spanish and Italian.**
  *Jardinier*, *Jardinero*, *Giardiniere*. Dutch *Tuinier*, Danish and
  Norwegian *Gartner* and Swedish *Trädgårdsmästare* are gender-neutral as they
  stand. This is the one place in the app where a person is named by a word the
  app chose, and it is worth a native reviewer's opinion.

**"Peace Garden" title-cased is the product and stays as it is**; *peace garden*
lower-cased is the thing, and is translated — *vredestuin*, *fredshave*, *jardin
de paix*, *jardín de paz*, *fredshage*, *fredsträdgård*, *giardino di pace*.

The four screen names have to agree with themselves: *Meet* is a mark at the
foot of the stage and a word inside three sentences, so *Ontmoeten* / *Møde* /
*Rencontre* / *Encuentro* / *Møte* / *Möte* / *Incontro* appears in all four
places or in none.

## Type

The chrome is 11pt, light, tracked out by 2.4 and uppercased, which is a great
deal wider per letter than the size suggests. **`tools/type/measure.swift`
measures every localised label in every language against a 402-point phone**,
reading the catalogue rather than a list typed into it, so a language added
later is measured without touching the tool:

```
swift tools/type/measure.swift        # an iPhone 17 Pro, 402pt
swift tools/type/measure.swift 375    # an iPhone SE, which iOS 17 still admits
```

It is calibrated against the one measurement taken off a real phone: the four
mark labels unrolled at once came to about 440 points, and the model says 449.

### What it found

**The mark row was the whole risk, and one word at a time is what saves it.**
The abandoned arrangement — all four unrolled together — measures 449 points in
English and 533 in Italian, against a screen of 402. A third over, with no size
of phone that would have taken it:

| | en | da | nb | sv | nl | es | fr | it |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| four at once | 449 | 460 | 461 | 505 | 508 | 509 | 516 | 533 |
| one at a time, worst | 269 | 309 | 309 | 314 | 303 | 286 | 286 | 302 |

One at a time leaves 207 points for a word. The widest of the thirty-two is
Swedish INSTÄLLNINGAR at 119. **Nothing in the mark row is close.**

**One row overflowed, and it was the tightest thing in the app.** *Not now* and
*Log places* sit side by side inside 40-point margins, which leaves about 250
points for a pair of tracked-out capsules. Spanish *Registrar lugares* went over
by two points and Dutch cleared it by five, which is not clearance. Two changes:

- the accept verb lost its object in six languages — *Vastleggen*, *Registrér*,
  *Enregistrer*, *Registrar*, *Registrer*, *Registrera*, *Registra* — which the
  paragraph above the buttons already explains;
- and the pair is now a `ViewThatFits`, side by side while the words fit and
  stacked when they do not. **A row whose only defence is a short translation is
  a row that clips the first time somebody writes a long one.**

**One label wrapped**: French *Ton nom d'utilisateur dans Peace Garden* ran past
the 342-point column. It wraps rather than clips, so it was a choice rather than
a bug; it is *Ton nom dans Peace Garden* now and fits on one line.

Everything else clears. At 375 points — an iPhone SE, which the iOS 17
deployment target still admits and which nothing has ever been checked against —
two Spanish section labels wrap to a second line and nothing clips.

### Uppercasing, per language

`textCase(.uppercase)` was a global modifier on both `chromeLabel` and
`chromeHeading`. It is now `Chrome.letterCase(in:)`, read through a
`ChromeLetterCase` modifier that looks at the environment's locale, with a named
list of the languages that keep their written case:

```swift
static let keepsWrittenCase: Set<String> = ["tr", "az", "el", "ga"]
```

Turkish and Azerbaijani have two letter i's; Greek drops the accent on an
uppercased vowel except the disjunctive ή; Irish keeps its lowercase prefix,
*nAthair* rather than *NATHAIR*. **None of the seven shipping languages is on
that list, and none needs to be.** Dutch *ij* is two letters and uppercases to
*IJ* correctly; French keeps its accents under Swift's locale-aware
`uppercased()`; the Scandinavian three, Spanish and Italian have nothing at
stake. The list is the mechanism rather than a finding — adding a language to it
is a one-line decision instead of a rewrite of the two voices.

### Seen running

An iPhone 17 Pro simulator, Dutch and French end to end, and Swedish and Italian
for the long words — German is not a shipping language, so the worst case was
taken from the longest strings there actually are. First light, the stage, the
garden, Settings, the naming step, the place offer, the searching screen and *a
seed on the wind*. Everything fits; the Dutch imprint lines each hold one line,
the Italian *CONTINUA COME GIARDINIERE* sits inside its capsule with room, and
*NON ORA* and *REGISTRA* sit side by side with a third of the row to spare.

**Getting to those screens took a new developer control.** The marks at the foot
of the stage answer a tap gesture rather than a button, and an injected tap does
not reach a gesture recogniser — the same reason the row is drawn from the start
on a simulator instead of waiting to be revealed. So the seed, the garden and
the settings are behind a control that nothing but a thumb can press, which is
fine until somebody has to take the same four screenshots in eight languages.
`Developer.openOnLaunch` reads a screen name off the command line, in Debug
builds only:

```
xcrun simctl launch <device> app.peacegarden -AppleLanguages '(nl)' -pgOpen settings
```

## Right to left

Out of scope for the seven — all are Latin-alphabet and left to right — but run
as a pseudolanguage pass before anybody commits to Arabic or Hebrew, and
recorded rather than fixed:

```
xcrun simctl launch <device> app.peacegarden -AppleTextDirection YES \
    -NSForceRightToLeftWritingDirection YES
```

**The three named suspects, and what they actually did:**

1. **`SproutingRule`'s tendrils are fine, including under `curlingDown`.** The
   suspicion was that the pair is asymmetric when it is turned over. It is not:
   the rule is an `HStack` of a mirrored tendril, a hairline and an unmirrored
   one, and RTL reverses the stack while SwiftUI mirrors each `Shape` — two
   flips that cancel. The rule renders pixel-for-pixel identically in both
   directions, which was checked by cropping the same band out of both
   screenshots and overlaying them. **Nothing to do.**
2. **The garden tile grid mirrors, correctly.** Tiles fill right to left and the
   odd fifth one lands in the right-hand column, which is what an RTL reader
   expects. The captions are `%1$@ · %2$@`; the middle dot is a neutral
   character and takes the paragraph direction, so the bidi algorithm handles it.
3. **The QR code does not mirror.** It is an `Image`, and SwiftUI leaves images
   alone unless asked. Its three finder patterns stay top-left, top-right and
   bottom-left in both directions. **Nothing to do**, and worth knowing that
   adding `.flipsForRightToLeftLayoutDirection(true)` to it would be the bug.

**Two things the scope did not name:**

4. **`UnfurlingBackdrop` mirrors.** SwiftUI mirrors `Shape` paths under RTL, and
   the two fronds are shapes: the composition comes out reflected. It is a
   backdrop and it reads perfectly well either way, but `Frond.Plan.late` is
   documented as *deliberately not a mirror pair*, and reflecting the whole
   composition is a change nobody specified. Decide before shipping RTL.
5. **The mark row reverses, so the prominent Meet mark moves** from
   second-from-left to second-from-right. Correct, and worth expecting.

The four glyphs in that row are near enough symmetric that mirroring them is
invisible. `PencilShape` and `LeafGlyph` are not symmetric and do mirror, which
is right. Nothing was found that needs fixing before a right-to-left language
could be added.

## The passages: still the real question

Nothing below has changed, and building the interface has not made it easier.

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

### What was done instead: option 3, eight times over

The scope recommended option 1 now and option 3 — a bank per language — for the
two or three languages that earned it. **Eight banks were commissioned in one
round**: English, which was then filled out to match, plus Dutch, Danish,
French, Spanish, Norwegian Bokmål, Swedish and Italian, each written from
scratch against the rules at the top of `Quotes.swift` by somebody working only
in that language.

They are not translations of each other and they share almost nothing. Measured
across the seven that landed: **zero lines in common with the English bank**,
none of them. That is `testNoBankIsTheEnglishOneTranslated`, and it is the one
number that says the commission was a commission rather than a translation job
with a better brief.

**Spanish is the one that is not wired.** It was commissioned with the rest and
failed three times — twice on an API output content filter, once on a stall —
and its second half is written while its first is not. `QuoteBank` therefore has
no `.spanish` case, and a Spanish phone reads English lines and is told so under
the passage. That is not a workaround: it is the state every one of round two's
twenty-five languages will pass through, since an interface is a fortnight and a
bank is a commission. Keeping it live and visible is worth more than hiding it.
Adding the bank is a case in `QuoteBank`, a line in `passages`, and moving
`"es-ES"` between two tests.

What each one found is in its own file's doc comment. The pattern across them is
worth recording, because it is an argument about the subthemes rather than about
any language:

- **Four of the seven independently named `quietAsASound` as their hardest.**
  Dutch has no coinage like *psithurism* and leans on *ruisen* and the legally
  designated *stiltegebieden*; French spends *bruissement* on silk, paper and
  crowds; Swedish and Norwegian both find their quiet-words are weather and
  water words rather than sound words — *havblikk*, *blikkstille*, *stiltje*.
  All seven reached ten anyway.
- **Several subthemes are richer outside English.** Danish separates *stilhed*
  from *tavshed* where English collapses both into silence. Italian owns the
  vocabulary the world uses for musical rest — *fermata*, *sordina*,
  *smorzando*. Norwegian's `theEdgesOfTheDay` is an embarrassment of material in
  a country where the edges of the day last months.
- **Some subthemes carve differently and were let to.** French has no word for a
  sibling at all — *frère ou sœur*, and *fratrie* names only the set — so its
  `theWordsForIt` is built on chosen closeness rather than blood. Norwegian's
  *fred* names protection laid over a place (*fredlyse*, a listed building that
  is literally *fredet*) rather than a cessation. Italian's `aPlaceYouAreFrom`
  resolves at the bell tower rather than the hearth, and *campanilismo* carries
  a note of parochialism that "home" does not.

### What two phones agree on now

They cannot agree on the line any more, and should not. A shared line would
require the banks to be parallel translations, which is the one thing they must
not be.

**The theme and the subtheme still agree**, and they are the part that was
always doing the work: the theme is drawn from the pair, the subtheme from the
child's own genus, and both are language-neutral because a plant's name is a
synthesised Latinate binomial. Two people meeting across languages draw from the
same corner of the same theme and each reads it in their own. What a pair holds
in common is the character of the passage rather than its words.

`QuoteBank` is where that is written down, and
`testTwoPhonesOnDifferentBanksAgreeOnTheCornerIfNotTheWords` is what holds it.

### The line saying which language

Built. `QuoteBank.isBorrowed` is true when the phone's language has an interface
and no bank, and `PlantRevealView` then reads *source · in English*. It is
dormant for all eight, and it exists before the languages that need it because
round two will need it on the day its interfaces land and its banks have not.

### What this found in the English bank

Nobody expected to learn anything about English by commissioning seven other
languages. **The English bank does not meet the floor its own scope set.**

`docs/LANGUAGES.md` said ten themes × three subthemes × ten lines was the floor
for a language. English has 300 passages, **thirteen of its thirty subthemes
under ten, and `quietAsASound` at five**. Every commissioned bank came in
between 349 and 380 with a floor of eleven.

It is held in `QuoteBankTests` at its own measured floor rather than at the real
one — enough that it cannot quietly get thinner, visible enough that somebody
fills it. Roughly ninety passages would bring it level with the languages that
were written to describe it.

## What the map gives away for free

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
already in every language**. That switch is in Settings today, and the line
under it now says so plainly:

> Off, the stage is the plant and the marks along the foot, in no language at
> all.

## What it cost, and what the next language costs

The scope said a fortnight for one language and a few days each thereafter. It
was a day for the extraction and the interpolations, a day for the comments and
the type review, and the seven languages came together rather than one at a time
— which is cheaper than doing one and then six, because the comment that makes
Dutch right is the comment that makes Italian right.

**The next language is: add its translations to two `.xcstrings` files, run
`tools/type/measure.swift`, and look at four screens.** Nothing in the source has
to change for it. That is what the fortnight bought.

## Round two

Twenty-five languages, agreed 2 September, held until round one had landed so
that the brief could carry what round one learned.

**Latin alphabet, which is the fence for now.** Catalan, Polish, Hungarian,
Romanian, Slovene, Croatian, Slovak, Czech, Welsh, Basque, Turkish, Finnish,
Irish, Portuguese, German, Lithuanian, Latvian, Estonian, Albanian, Icelandic,
Galician, Luxembourgish, Faroese, Maltese, Greenlandic.

Three that were asked for and are not on it, each for a different reason:

- **Flemish** is the Belgian variety of Dutch, `nl-BE`, not a peer language.
  `QuoteBank.bank(for:)` matches on the language alone, so a Flemish phone reads
  the Dutch bank — which was briefed to carry Gezelle and *Vlaams spreekwoord*
  for exactly this reason. A `nl-BE` variant bank remains possible later.
- **Ukrainian** is Cyrillic, so it goes with Greek, Russian, Bulgarian, Serbian,
  Macedonian and Belarusian in the other-alphabets round.
- **Sami and Frisian** are out. Both needed disambiguating before they could be
  briefed at all — "Sami" is a family of about nine languages of which only
  Northern has much in print, and "Frisian" means West Frisian — and neither is
  an iOS display language. The effort goes to the larger banks.

**"Gaelic" resolved to Irish.** Irish and Scottish Gaelic are separate
languages; Irish is an official EU language with far more out-of-copyright
literature to quote.

**Greenlandic is the interesting one.** Kalaallisut has its own ISO code, its
own Latin orthography since the 1973 reform, and has been the sole official
language of Greenland since 2009. The hedge is that the Inuit languages form a
dialect continuum from Alaska to Greenland, so where you cut it into languages
is conventional rather than sharp — a Kalaallisut and an Iñupiaq speaker cannot
understand each other, but every adjacent pair can. It is not related to Danish.
It is polysynthetic, which is the argument *for* it: a language that builds
whole sentences into single words is an unusually good seam for the definition
and etymology kinds. Its constraint is quotation — Rink (1866–71) and Rasmussen
are clear, but *Sinnattugaq*, the first Greenlandic novel, does not clear until
2027 — so its bank leans on oral tradition and word-building, and its brief has
to say so.

### The waves

Twenty-five banks is fifty agents, so they go out in waves rather than at once —
enough to read a wave and correct the brief before the next commits to it.

**Wave one: German, Portuguese, Polish, Turkish.** Chosen to stress the brief in
four directions rather than by size: Germanic, Romance, Slavic, Turkic. Polish is
the first Slavic bank, so its etymologies are new territory rather than
variations on the six that came before. **Turkish is the first bank outside
Indo-European**, which makes it the real test of whether the thirty subthemes are
about the world or about the languages that named them.

Two words worth watching for in what comes back, because either could change how
a subtheme is understood:

- **Turkish *barış*** is built on *barışmak*, to make peace *with one another*.
  Turkish names peace as a reciprocal act between two people rather than a state
  or an absence — which is what this app is about, arrived at from outside the
  family that named the subtheme.
- **Polish *pokój*** is one word for peace and for a room: the state, and the
  space you are standing in.

Later waves, roughly by size and by how much material each has to draw on:
Czech, Hungarian, Romanian, Catalan, Finnish; then Croatian, Slovak, Slovene,
Lithuanian, Latvian, Estonian; then Welsh, Irish, Basque, Galician, Albanian,
Icelandic; then the thin-corpus four — Faroese, Luxembourgish, Maltese,
Greenlandic — which need a brief of their own saying so.

### What round one learned, for the round-two brief

- **Cut the reading down, then split the writing.** Spanish failed three times
  — twice on an API output content filter, once on a ten-minute stall — and
  every one died partway through reading `Quotes.swift`, which is now 2,000+
  lines and grows with each bank added to it. What worked: a 228-line brief
  holding the struct, the rules, the two enums and one sample passage per
  subtheme, and two agents splitting the ten themes five and five. Half the
  reading, half the writing, and the brief stays the same size however many
  banks exist. Every round-two brief should start there.
- **Name the thin-corpus languages as thin.** Faroese, Luxembourgish and
  Greenlandic will not reach 300 passages from quotation. Say so, or an agent
  pads — or worse, invents an attribution.
- **Tell them what the last round found hard.** Every bank struggled with
  `quietAsASound` and every bank got there. Naming the kinds of material that
  worked — acoustic fact, quiet marked in law, the words a language has for it
  obliquely — saves each one rediscovering it.
- **Register is a rule, not a preference.** Four banks dropped verified,
  out-of-copyright, famous lines because they read as a rebuke or an elegy to
  two people who have just met. That instruction earns its place in the brief.
- **Say what is already taken.** German is the type-review worst case and its
  bank doubles as the overflow test. Maltese is Semitic in Latin script, its
  etymology seam Arabic under a Sicilian-Italian overlay. Basque is an isolate
  with no cognates to lean on.

## What is still open

1. **The English bank is ninety passages short of its own floor.** Thirteen
   subthemes under ten, `quietAsASound` at five. It is the thinnest of the
   eight, and it is the one every other bank was written against.
2. **A native reviewer for each of the seven interfaces, and now for each of
   the seven banks.** A bank is harder to review than an interface and matters
   more: a misattributed quotation ships as a claim about a dead writer.
3. **A native reviewer for each of the seven.** These translations are careful
   and they are not a native speaker's. The places, the plant forms and the
   fallback name are where an outside eye would earn most.
3. **The fallback name travels.** A person who never gives a name is called by
   their own phone's word for it, and that word is what the other phone shows.
   Sending an empty name and letting each phone render its own would be better
   and is a change to the exchange payload.
4. **`UnfurlingBackdrop` mirrors under RTL.** Decide whether the reflected
   composition is acceptable before a right-to-left language is added.
5. **The iPhone SE has never been looked at.** The deployment target admits it,
   the measurements say two Spanish labels wrap there, and nobody has run the
   app on one.
