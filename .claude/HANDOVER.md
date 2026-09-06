# Peace Garden — handover 6 September 2026 (evening)

*Four of the forty-two maps are named, one of the four is confirmed, and all
four are live. The brief has now been corrected five times by the commissions it
produced, which is what piloting them one at a time was for. The pilots are
spent: what is left is bulk.*

## Goal

Get the app and site launch-ready. The writing settled and translated, the mark
final, and the work off this machine.

## State

`main` at `HEAD`, **pushed**. **peacegarden.app is live and carries all of
it** — redeployed 6 September in the evening, forty-six files, thirteen paths
checked at the far end, and the German, Japanese and Arabic maps read back off
the origin. The Arabic map was walked live: `dir="rtl"`, the row starting at the
right, one row height.

**The privacy page went live in that deploy**, for the first time and in English
for every reader. It is unlinked — nothing on `/g` or `/s` points at it — and it
exists because a privacy URL is a mandatory App Store listing field. `/privacy`
answers 200 `text/html`.

**Verified** — 97 SeedCore tests, 28 app tests, five Python checks; the ten
areas walked in the browser in English, Danish and Arabic, including the
fallback marking and the language switch; **the live map, on the origin**;
**the release hold, driven end to end on a simulator** — 1 second leaves the
plant, 4 seconds releases it and the garden falls back to *nothing has been
crossed yet*.

**Unverified** — every translation; Italian,
Norwegian, Dutch and Swedish throughout; **the ten area names in 38 of the 42
languages**, and the German, Japanese and Arabic thirty, which are drawn,
walked, live, and unread by anybody who speaks any of the three.

## Next step

**The remaining thirty-eight, in batches.** The pilots are done and they were
worth doing — five corrections to the brief, four of them from the three
languages named today — but the yield has stopped: Arabic produced one
correction where German and Japanese produced three between them, and it was the
visual half of a rule that already existed.

```sh
python3 tools/strings/commission.py --areas <code>
python3 tools/strings/check.py
```

**Take a batch that shares a problem rather than an alphabet.** The eight
languages the `areaMeeting` note names — ko, zh, he, fi, hu, eu, and the two
done — are one batch, and Japanese has already shown them the way out of it.
The Romance and Germanic runs are another, and they will mostly write
themselves. `check.py` runs over all forty-two at once, so there is no reason to
go singly any more.

**What has not started at all is getting any of the four read.**
`docs/REVIEWING-A-LANGUAGE.md` is the job, `out/review/INDEX.md` has 43 sendable
packets, and they predate the map being a thing to judge — screen 6 is now a
different screen. Danish is the only language where a reader has looked.

## The four that are named, and what each one is for

**Danish is done, and all ten are confirmed by a native reader.** Four were
settled with Marcus directly — *Hjemstavnen* and *Barokhaven* confirmed,
*Dvalebedet* chosen once the cold frame came apart, and *Stubhaven* given for
`areaRenewal`, a *stub* being the coppice stool itself where I had reached for
the forestry word. The remaining six he confirmed on 6 September.

So **Danish is the worked example**, and it is worth handing to the next namer
alongside the brief: it is the only language where the whole loop has run, and
it produced two of the brief's five corrections rather than merely passing.

**German, Japanese and Arabic are drafted and unread.** All three are in
`NAMING.md` now as worked examples with that said plainly, and the whole of the
reasoning is in the three commit messages rather than in any file. What each
was for:

- **German tested the corrected cold frame note on a namer who is not Marcus,
  and it held.** The note names *Frühbeet* as a forcing device and *Frühbeet*
  was not reached for. The name went to *Wartebeet*, the holding.
- **Japanese tested whether the hard four survive outside the northern-European
  garden**, and they do. It has no knot garden and it has 枯山水, which is the
  same move French makes with *parterre de broderie*. It was also on the list of
  eight languages the brief tells to choose a half of `areaMeeting`, and it did
  not have to: 出会いの辻 carries both.
- **Arabic tested the case the brief believed it had already solved**, and the
  brief was wrong twice over. It offered Arabic *chahar bagh*, which is Persian.
  And المشتى, the first draft for `areaWaiting`, had to go because
  `areaBeginnings` is المشتل and the two differ in one final letter.

Between them they corrected the brief four times — the tradition next door, a
language that compounds rather than choosing, ten different *things*, and ten
names that do not *look* alike — all written into `NAMING.md` and
`commission.py`, because they are corrections to *method* rather than claims
about a language, and a native reader is not the thing that would confirm them.

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

## The Winds, and the counterparty

Two ideas from Marcus on 6 September, one written up and one deliberately not
started.

**The Winds is written up in `docs/PHASES.md`** and nothing is built. A third
kind of meeting: a seed cast to a place where it meets another cast seed, for
somebody who cannot easily meet a person. It rests on his sentence — **the
seeds have met, not the people** — which keeps `tagline` true and makes
`about1` false, and which produces the taxonomy the app was missing: the tap,
the link, The Winds. Read that section before touching any of it; the note
names what it costs in words, in servers, and in the privacy page committed
the same day.

**The website as a counterparty is NOT link plumbing**, and this was got wrong
once in conversation before being checked. A reply's ninth field is
`result.checksum`, and `PollenLink` verifies it — `if let check, check !=
result.checksum { return nil }` — so the site cannot hand back a reply without
actually performing the cross. `mintlink.py` fills that field with random bytes
and gets away with it because its links only need to *parse*.

It is still smaller than the port `docs/WEBSITE.md` rules out: three
domain-separated SHA-256 digests — `encounterID`, `cross`, `checksum` — and no
genome, no traits, no geometry. `tools/reference/derivation_reference.py` is an
independent implementation of exactly those and CI already gates it, so a JS
port has a reference and a vector.

**The order to build it in**, agreed rather than assumed:

1. The three digests in JS, held against the Python reference and a pinned
   vector **in CI**, before anything depends on them. This also closes the SEAM
   `link.js` names in its own header — *nothing gates this yet*.
2. The encoder, gated by round-tripping `PINNED` through parse-then-re-encode.
3. The page, which is the easy part and the only part needing 43 languages.

The link format is the one thing here that is permanent once a link has been
sent to anybody, which is why step 1 comes first and why this was not started
at the end of a long session.

## Still open

- **390 area names.** Danish, German, Japanese and Arabic are in; 38 languages
  to go, and only Danish has been read. See *Next step*.
- **Three names want a native reader before anything else does**, and all three
  are live. `Heimaterde` for German `areaGround` — it carries the soil and the
  belonging, which is more of the theme than any alternative manages, and it
  also sits near a register some German readers will hear; Marcus chose to ship
  it and ask rather than reach for *Muttererde* and lose the belonging.
  Japanese `冬囲い`, which names a practice where the other nine name places.
  And Arabic `الخِلْفة`, the least certain of the forty: it is the growth that
  follows a cutting, it is not a common word in that sense, and it needs its
  diacritics or it reads as offspring.
- **The privacy page is live in English and null in all 42.** It is a third
  commission, `commission.py --privacy <code>`, and none of it has been ordered.
- **Four app strings want native readers** — the release row, its alert, its
  confirm and its consequence, all `needs_review` in it/nb/nl/sv. Marcus wrote
  the Danish and read the French and Spanish.
- **The language review is 2 screens of 6.** Screens 3 (no name), 4 (come back),
  5 (broken) and 6 (the garden) are unwalked in every language.
  `out/review/INDEX.md` has 43 sendable packets — **and screen 6 is now a
  different job**, since the map is a thing to judge rather than a thing to
  skip. The packets predate that.
- **The passage banks are not all "its own writers"** — Danish drew Marcus
  Aurelius, Spanish drew a Catalan tradition, where §4 promises otherwise.
- **Request logging on `/s`** is a 20i control-panel setting, not done.
- **The Wild Fields is phase 2**, reachable from the menu as a named place.
  `docs/PHASES.md` carries it as a requirement on the plot service.
- The iPhone SE layout, and the passage's own direction in the app for an RTL
  reader with no bank — both in `docs/LANGUAGES.md`, both unlooked at.
- **App Store screenshots.** `-pgOpen` was built for it and has never been used.
- **`appNote` shares its first sentence with `about3`.**
- **The singular case is visible in the app**, not just in theory: the garden
  header reads *1 grown from a meeting* where the numeral rule asks for *One*.
  Seen on the simulator, 6 September.
- `#area-name` holds stale text on a plant page. It is inside a `hidden`
  section so nobody sees or hears it; pre-existing, noted while working nearby.

## Traps

- **`AREA_KEYS` must stay below `export const KEYS` in `strings.js`.**
  `commission.py` reads the English by slicing between `export const EN` and
  `export const KEYS` and matching `key: "value"`, so an object of ten string
  values above that line is parsed as ten more catalogue entries whose English
  is the word `areaWaiting`. There is a note on the declaration saying so.
- **A held control *can* be driven, and the old trap here was wrong.** It said
  an injected press arrives and is released in the same instant. True of a
  `simctl` tap; false of a touch path with per-sample delays, which holds a
  contact down as long as it is told to —
  `mcp__Claude_Code_iOS_Simulator__control` `touch_path`, dt_ms up to 1000 a
  sample. Proved on the release row, 6 September. **A thumb is still owed for
  the judgement**: whether 3 seconds is right rather than long, and whether a
  drifting thumb hands the touch to the scroll view. A synthesised path holds
  perfectly still, which is the case a hand does not test.
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
- **The marks at the foot of the stage do not answer injected taps** — that
  one still holds, and it is the SceneKit gesture recogniser rather than
  anything about injection generally: SwiftUI buttons, rows and scroll views on
  the same screen all answer fine. Use `xcrun simctl launch <udid>
  app.peacegarden -pgOpen settings|garden|seed|meet`.
- **A plant page opens with its chrome hidden** when Menu bar is *Hidden*,
  which is the default. One tap on the background reveals the name, the
  encounter and the release row; without it the screen is a plant and a Close.
- **`cd` persists between Bash calls.** Always pass absolute `--package-path`.
- **Render a night-opening plant at its own peak hour**, or every flower is a
  shut bud. `tools/preview/plant_model.py` has the tempo.
- **A term match must be on the head of a word, not the whole of it.**
- **Catalogue keys are nested under `strings`**, not at the top level.
