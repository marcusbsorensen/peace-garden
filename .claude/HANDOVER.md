# Peace Garden — handover 5 September 2026 (late)

*The naming settled, the machinery for it is built, and 420 names are now
orderable and unordered. Most of what is open is commissioning rather than
building.*

## Goal

Get the app and site launch-ready. The writing settled and translated, the mark
final, and the work off this machine.

## State

`main` at `af7b0ec`, **pushed**. **peacegarden.app is live** — and does not yet
carry this commit; `tools/deploy.sh` has not been run since it landed.

**Verified** — 97 SeedCore tests, 28 app tests, five Python checks; the ten
areas walked in the browser in English, Danish and Arabic, including the
fallback marking and the language switch.

**Unverified** — the release hold (needs a thumb); every translation; Italian,
Norwegian, Dutch and Swedish throughout; **the ten area names in 41 of the 42
languages**. Danish has them; nothing else does.

## Next step

**Order the next language, and pick one where the cold frame will bite again.**
Danish is done and it earned its keep: it found a defect in the brief on the
first pass, which is exactly what piloting one before ordering forty-two was
for. German is the obvious second — *Frühbeet* is the same forcing trap, so it
tests whether the corrected note actually works on somebody who is not Marcus.

```sh
python3 tools/strings/commission.py --areas de
```

Then a language outside the northern-European garden tradition, where three of
the four hard ones have no local answer at all: Japanese or Arabic. `areaRenewal`
and `areaMeeting` are the ones to watch there.

**A full Danish read is still owed.** Three of the ten were settled with Marcus
directly — *Hjemstavnen* and *Barokhaven* confirmed, *Dvalebedet* chosen once
the cold frame came apart. The other seven were drafted and went unchallenged on
a read-through rather than being separately confirmed.

## What landed, and the two decisions inside it

**The ten area names are catalogue keys in every language.** Marcus reversed the
English-only rule on 5 September; this is the machinery, and the reasoning is in
`docs/WEBSITE.md` §*Walking it*, which now carries the reversal rather than the
argument it overturned.

| | |
| --- | --- |
| `Server/assets/js/strings.js` | ten keys, plus `AREA_KEYS` mapping theme → key |
| `Server/strings/*.json` | 420 nulls. Absent falls back to English **per name**, so a language ships its map in pieces |
| `tools/strings/NAMING.md` | the second brief — **new file, and the substantial one** |
| `tools/strings/commission.py` | `--areas <code>`, and the `AREAS` table it prints from |
| `tools/strings/check.py` | five checks on the ten, and its old rule kept on its surviving half |
| `Server/assets/js/walk.js` | `areaName()`, and the `drawMap` fix below |
| `docs/REVIEWING-A-LANGUAGE.md` | §3 gains the ten; §4's *areas are English* bullet reverses |

Two English names were settled at the same time, because 420 names get written
against them:

- **The Root Ground became The Home Ground.** The `ground` theme is soil (9), *a
  place you are from* (9), *a kept place* (12) — two thirds belonging, and the
  old name carried only the soil.
- **The Orchard was questioned and kept.** It names `kinship` three times: every
  tree is a graft (two plants made one — the first subtheme by meaning), every
  tree was *chosen* rather than happened upon, and it bears over years. Marcus's
  reading, now in the brief. `WEBSITE.md` had said nearly this since the names
  were chosen and it had never reached a translator.

## Also landed

- **`Wyn` became `Vin` on 6 September.** Marcus asked what W and Y were doing
  in names called Latin. Y is right — Latin took it from Greek to spell exactly
  these loanwords. W is not, and `Wyn` was the only head rooted in neither Greek
  nor Latin. Now L *vinculum*, a bond, at the same index; Wynaceae is Vinaceae.
  It renamed the vine family's 4-merous plants and moved no geometry.

## The numeral rule

**A quantity is a numeral from 2 up; one stays a word.** In `BRIEF.md`. Prose is
not a quantity: *two people meeting* stays words, and so do the forty figurative
places like *Where two paths cross*.

Open, and deliberately left rather than half-done:

- **The singular case.** `%lld grown from meetings` prints *1 grown from a
  meeting* where the rule asks for *One*. Not a find-and-replace: CLDR's `one`
  category covers 0 and 1 in French and 1, 21, 31 in Russian, so a hard-coded
  word is wrong in some of the forty-three.
- **Nothing enforces it.** `check.py` is the place, and it needs each language's
  number words — the same list a sweep would need.

## Still open

- **410 area names.** Danish is in; 41 languages to go. See *Next step*.
- **Four app strings want native readers** — the release row, its alert, its
  confirm and its consequence, all `needs_review` in it/nb/nl/sv. Marcus wrote
  the Danish and read the French and Spanish.
- **The language review is 2 screens of 6.** Screens 3 (no name), 4 (come back),
  5 (broken) and 6 (the garden) are unwalked in every language.
  `out/review/INDEX.md` has 43 sendable packets — **and screen 6 is now a
  different job**, since the map is a thing to judge rather than a thing to
  skip. The packets predate that.
- **`tools/deploy.sh` has not run since `66b2271`.** The live site still has the
  English-only map.
- **The passage banks are not all "its own writers"** — Danish drew Marcus
  Aurelius, Spanish drew a Catalan tradition, where §4 promises otherwise.
- **Request logging on `/s`** is a 20i control-panel setting, not done.
- **The Wild Fields is phase 2**, reachable from the menu as a named place.
  `docs/PHASES.md` carries it as a requirement on the plot service.
- The iPhone SE layout, and the passage's own direction in the app for an RTL
  reader with no bank — both in `docs/LANGUAGES.md`, both unlooked at.
- **App Store screenshots.** `-pgOpen` was built for it and has never been used.
- **`appNote` shares its first sentence with `about3`.**
- `#area-name` holds stale text on a plant page. It is inside a `hidden`
  section so nobody sees or hears it; pre-existing, noted while working nearby.

## Traps

- **`AREA_KEYS` must stay below `export const KEYS` in `strings.js`.**
  `commission.py` reads the English by slicing between `export const EN` and
  `export const KEYS` and matching `key: "value"`, so an object of ten string
  values above that line is parsed as ten more catalogue entries whose English
  is the word `areaWaiting`. There is a note on the declaration saying so.
- **A held control cannot be driven by injection.** `HoldToConfirm` reads a press
  through `PressReporting`, and an injected press arrives and is released in the
  same instant. `Chrome.swift` says so. Test it with a thumb.
- **Never `pkill -f CoreSimulator`.** It wedges the whole simulator subsystem and
  every boot then times out at 60s. Recovery is
  `killall -9 com.apple.CoreSimulator.CoreSimulatorService`, which launchd
  restarts.
- **`.htaccess` does nothing on peacegarden.app.** A `RewriteRule` that never
  fires looks exactly like a file being served.
- **A 200 with the wrong `Content-Type` is this site's whole failure mode.** Run
  `tools/deploy.sh --check` rather than trusting an upload.
- **`/api/count` 404s locally** and the garden says every plant in it is
  invented. That is the plot service being absent, not a fault.
- **A plant created under a developer clock shift is born at the shifted now**,
  so wind on again afterwards to age it. `xcrun simctl spawn <udid> defaults
  write app.peacegarden developer.clockShift -float <seconds>`.
- **The marks at the foot of the stage do not answer injected taps.** Use
  `xcrun simctl launch <udid> app.peacegarden -pgOpen settings`.
- **`cd` persists between Bash calls.** Always pass absolute `--package-path`.
- **Render a night-opening plant at its own peak hour**, or every flower is a
  shut bud. `tools/preview/plant_model.py` has the tempo.
- **A term match must be on the head of a word, not the whole of it.**
- **Catalogue keys are nested under `strings`**, not at the top level.
