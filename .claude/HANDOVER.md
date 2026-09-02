# Peace Garden — handover 2 September 2026 (fourth session)

## Goal
Picked up the previous handover's three open items and finished all three: the
four stage-row marks, wave two of the banks, and what `docs/WEBSITE.md` asks of
the app. The website itself was started along the way, at Marcus's instruction.

## State
`main` at `356d9ee`, clean. **72 SeedCore tests and 23 app tests pass**; device
and simulator builds clean; all three CI jobs green — which they were not when
this session started.

- **Seventeen passage banks**, 6,166 passages. Wave two — Czech, Hungarian,
  Romanian, Finnish, Catalan — is complete. Eight of the twenty-five remain.
- **The four marks are redrawn** and in `Chrome.swift` / `Glyphs.swift`, at four
  different sizes.
- **`Server/` has a website in it.** `/s` answers, in seventeen languages.
- **`tools/site/export.py`** generates the site's banks and manifest from the
  app, gated by CI.

## What needs doing next

### 1. Look at the marks on a device
**The one thing this session could not verify.** The geometry was rendered and
judged at fifteen points in `tools/glyphs`, and the Swift is a line-for-line
transcription of it, but nobody has seen the row on a screen.

Getting there needs first light passed, and **injected taps did not reach the
`PLANT IT NOW` button** — `tap` and `touch_path` both, at coordinates checked
against the screenshot, with the screen fully settled. That is the same class of
failure `docs/HANDOVER.md` records for the stage row's `UITapGestureRecognizer`,
except this is a plain SwiftUI button, which that note says *should* take an
injected tap. Either the note is incomplete or something is over the button.

The cheap way round it is the trap already written down: write
`Library/Application Support/PeaceGarden/garden.json` in the app's data
container with a past `birth`, so the app opens on the stage and first light
never runs.

### 2. Wave three of the banks
Eight left: Croatian, Slovak, Slovene, Lithuanian, Latvian, Estonian, Welsh,
Irish, Basque, Galician, Albanian, Icelandic, and the thin-corpus four —
Faroese, Luxembourgish, Maltese, Greenlandic — which need a brief of their own
saying so. `docs/LANGUAGES.md` § *Round two* has the waves.

The two-agents-per-language split held perfectly: ten agents, no stall, no
output filter, nothing lost. **What it costs is duplicate lines** — Czech three,
Romanian two, Finnish two, Catalan one, Hungarian none — always a proverb or a
famous poem, always the material both agents would obviously reach for.
`assemble.py` catches every one. Budget for the judgement call, because each
duplicate sat in a *different subtheme* in each half, so the question is never
"drop which" but "which home is better".

### 3. The shared plant page
Marcus's answer to what comes after `/s`. `/p/` plus twenty-odd random
characters, `noindex`, unlisted. `Server/assets/js/languages.js`, `strings.js`
and `passages.js` carry nothing about `/s` and are meant to be reused as-is.

**It needs the theme in the plot record** — see below.

### 4. Commission the site's sixteen string files
`Server/strings/*.json` carry every key with a `null` value. Seventeen strings
each. The English they are written from is in `assets/js/strings.js`.

## Decisions made this session
- **The garden is walkable, and guests from anywhere can visit it.** Marcus, and
  it closed the first item under *Still open*. Taken while nothing is published,
  so nothing is relisted and nobody is re-asked — the consent taken at share
  time is simply the right consent the first time. `noindex` stays: walkable and
  indexed are different properties and only one was asked for. **The garden shows
  plants, not people** — a grid of names is a directory.
- **The passage is drawn in the reader's language, in the garden as on a page.**
  So *parts of the garden in each language* is one garden read one language at a
  time, not a garden partitioned by language. Partitioning would publish the
  sharer's language, which is the first fact this app would have stated about
  somebody that they never chose to state, and hardest on speakers of small
  languages.
- **20i, with a database on it**, for the plot service. Same-origin with the
  pages.
- **Seventeen languages of site chrome**, not English alone.
- **The cog is an ordinary cog.** Recognition wins on the one mark whose whole
  job is to be found without being read.

## What this session found that nobody was looking for
- **CI was red before this session started**, at `e806de4`, and had been for two
  commits. Two regexes in `passage_reference.py`, both correct when written and
  both outgrown: `var position` was read across the whole file, so `heads` —
  added later in the same shape — made it parse the genus syllable `"Thal"` as a
  coordinate. Under that, `subtheme: .theFirstAct` ends in `theme: .theFirstAct`,
  so every passage had been counted twice since subthemes arrived. It reported
  738 passages for a bank of 369.
- **The theme does not fall out of the lineage**, which `docs/WEBSITE.md` said
  twice. A theme reads off a genus head; a *pair's* theme comes from both parent
  seeds, which a page cannot be given. The plot record has to carry the derived
  theme. Corrected in the spec.
- **`QuoteBankTests` named the languages it expected to have no bank**, and they
  graduated. It now takes whichever planned language has not arrived yet and
  tests the mechanism separately against `zxx`.
- **Turkish reads English labels in mixed case on the site**, because the
  written-case rule follows the interface language and the words are not
  commissioned yet. Correct mechanism, odd output, resolves itself.
- **`/s*` in the association file claims more than `/s`.** A top-level
  `style.css` or `share` would be caught as a universal link.

## Traps
Everything in `docs/HANDOVER.md` and the previous `.claude/HANDOVER.md` still
applies. Added this session:

- **Injected taps do not reach first light's button either.** See item 1.
- **A screenshot taken right after `simctl launch` catches the zoom animation**,
  not the app. Four seconds is enough. This is the same trap the repository has
  recorded twice for sheets, in a third place.
- **`cd` in a Bash call persists**, and an `xcodebuild` run afterwards fails with
  *`PeaceGarden.xcodeproj` does not exist* rather than anything about paths.
- **A generative image model cannot hold a monoline.** Three rounds: bulbous,
  then the brightness glyph, then a cat. Each round fixed the named fault and
  introduced a new one, because it generates from a description rather than
  constructing geometry. What it is good for is composition. `tools/glyphs`
  exists because of that, and is the thing worth keeping.
- **`Localizable.xcstrings` is not `json.dumps`-able round-trip.** Xcode writes
  `"key" : {` with a space before the colon; rewriting the file with `json.dumps`
  reformats all 6,181 lines. Edit it textually.
