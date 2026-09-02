# Peace Garden — handover 2 September 2026 (third session)

## Goal
Started as three items from the last handover — plant forms, the suite-brand
note, the localisation scoped in `docs/LANGUAGES.md` — and grew. It ended with
twelve passage banks, a round of UI feedback from Marcus, a website
specification, and two fields added to the exchange payload that could not have
been added later.

## State
`main` at `7dd2589`, clean. **72 SeedCore tests and 23 app tests pass.** Device
build clean for `generic/platform=iOS`.

- **Plant forms are live** — `docs/PLANT-FORMS.md` is the record now. Twelve
  archetypes are twelve things, verified on a simulator.
- **The interface speaks eight languages**; **twelve banks are wired**: English,
  Dutch, Danish, French, Spanish, Norwegian, Swedish, Italian, German,
  Portuguese, Turkish, Polish. Zero lines shared with English, across all of them.
- **`docs/WEBSITE.md`** is the phase 2 specification. Read it before touching
  anything about peacegarden.app.
- **`PollenCard` carries a contact token and an arrival**, and the settings
  paragraph was rewritten in the same commit because the token made it untrue.

## What needs doing next

### 1. The four glyphs — Marcus's own note
**All four marks in the stage row need more work.** They were redrawn this
session and are better than they were; they are not good enough. The plan Marcus
set: **send them to Manus for versions to trace** rather than iterating blind in
Swift path maths. The `work-with-manus` skill is how, and NanoBanana 2 is the
image generator.

| Mark | What it is now | What went wrong on the way |
| --- | --- | --- |
| Seed | A leaning teardrop, round at the foot, drawn to a point | Upright it looked *placed* rather than grown; the tilt is 20° clockwise |
| Meet | Two unequal stems crossing, tips curled | Drawn as a mirrored pair it was an hourglass — a symmetrical X reads as a letter first |
| Garden | Three different plants on a short bed line | Upright stems on a full-width line are a colonnade; a bowl at one end and a ball at the other close it into a basket |
| Settings | `CogShape`, untouched this session | A small disc with long rays is the *brightness* glyph, which is why the cog avoids that proportion |

Constraints for whoever briefs Manus: monoline, round free ends, even weight
(BRAND.md §3.2), legible at **15 points** on black *and* on the new light
ground, and no rectangles — a rectangle is the one shape this app has none of.
They sit in a row of four, so they have to differ from each other at a glance
and from `SunGlyph`, `BloomGlyph`, `PetalGlyph`, `LeafGlyph`, `MoonGlyph` and
`ClockGlyph`, which share the seed panel.

### 2. Wave two of the banks
Thirteen of the twenty-five remain — the list, the waves and what wave one
learned are in `docs/LANGUAGES.md` § "Round two". Wave one was German,
Portuguese, Polish and Turkish.

**Use the tools.** `tools/quotes/brief.py --out brief.swift` cuts `Quotes.swift`
to 238 lines; `tools/quotes/assemble.py <Language> <a> <b>` joins two halves and
refuses a bank that would fail the tests. Two agents per language, five themes
each. Every failure this session came from an agent holding too much before
writing, or reading the whole 2,600-line bank.

### 3. What `docs/WEBSITE.md` asks of the app
The payload half is done; the rest is not.

- **"Alert me when a joint seed is shared"** must mean *no request at all* when
  off, so the service is never told the phone exists.
- **"Plants grown under this name will keep it"** is now a promise the phase 2
  design contradicts — the shared page reads the name live.
- New: a **Peace garden** section (who you are signed in as), **Delete my peace
  garden account** as a fourth held row, **Show in the peace garden** per plant
  in Garden rather than Settings, and a line about the plot in *Reset
  everything*.
- **A gap in `docs/PHASES.md`**: it specifies the see-your-note-as-it-will-appear
  screen for the invited person only. Whoever publishes first wrote their note
  privately too and needs the same screen.

## Decisions made this session
- **`Inflorescence`, not `Form`** — `Genome.Form` was taken, and these are
  inflorescence types in the botany the file already borrows from.
- **A solitary bloom is 1.7×, not the spec's 2.2.** Three archetypes were
  already inflating `petalLengthScale`; compounded, a poppy was a satellite dish.
- **Two phones no longer agree on the passage, and should not.** The theme and
  the subtheme still agree — both derived, both language-neutral. A pair holds
  the character of the passage in common rather than its words. `QuoteBank`'s
  doc comment is the argument.
- **The stage is composed for the bare screen**, not for what the chrome band
  leaves, because the band is hidden most of the time.
- **The contact token is per meeting, not per person.** A stable identifier is a
  directory however it is spelled.
- **No guest book** is what `docs/WEBSITE.md` recommends, along with unlisted
  capability URLs for shared plants. **Not yet confirmed by Marcus.**

## What this session found that nobody was looking for
- **The English bank was the thinnest of the eight**, with thirteen subthemes
  under the floor its own scope set. Filled to 369. One new entry is the
  argument for doing them in parallel: *Danish keeps two words where English has
  one — stilhed is no sound at all, and tavshed is nobody speaking.*
- **The subtheme draw is 30/30/40.** Ten genus tails band 3/3/4, so how often a
  reader meets a line twice is the draw probability over the line count, not the
  count. Now a doc comment on `subtheme(of:in:)`.
- **131 of 191 interface strings were never extractable** — every chrome helper
  took a `String`, so a literal handed to `QuietButton(title:)` was drawn as
  written and looked up nowhere.
- **Three separate things blocked a light appearance**, and the third was a bug:
  `StageBackdrop`'s pool of light faded to *opaque black* rather than to
  nothing, which is the same picture on black and a black disc covering the
  screen on anything else.
- **Turkish carries no named literary quotation at all.** It had the richest
  poetry available to it and dropped every line, because classical wording and
  its diacritics could not be verified. That is the rule working and it is a
  real gap in that bank.

## Traps
Everything in `docs/HANDOVER.md` still applies. Added or confirmed this session:

- **New files need `xcodegen generate`.** Still the commonest way to lose an
  hour: `Localised.swift` compiled fine and the app could not see it.
- **A bank file mid-write does not parse, and `xcodegen` will add it to the
  target anyway.** `swiftc -parse` every `Quotes+*.swift` before regenerating.
- **`simctl install` wants the `.app` path**, not `-showBuildSettings` output
  pasted together, which gives you a path ending in `YES`.
- **To see a chosen archetype or language, write the state rather than
  reinstalling.** Put a hex seed into `Library/Application Support/PeaceGarden/
  garden.json` in the app's data container; `xcrun simctl spawn <sim> defaults
  write app.peacegarden <key> <value>` sets any `@AppStorage` key. Set `birth`
  to a real past date rather than winding `developer.clockShift` — the app
  re-saves the birth using the shifted clock and the shift then stops biting.
- **A long single-shot generation trips an API output filter with no useful
  error**, and a long read stalls an agent outright. Both killed the Spanish
  bank, three times between them.
- **`tools/preview` has drifted further.** Its branch code is a faithful mirror;
  its stems still lack `apexPoint`, the bloom lag and the foot dome. `SeedCore`
  is authoritative.
