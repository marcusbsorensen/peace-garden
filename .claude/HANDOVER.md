# Peace Garden — handover 6 September 2026 (evening)

*Forty-one of the forty-two maps are named and live. One of the forty-one is
confirmed by somebody who reads the language. **That ratio is now the whole of
the remaining problem** — the naming is done and the reading has barely
started.*

## Goal

Get the app and site launch-ready. The writing settled and translated, the mark
final, and the work off this machine.

## State

`main` at `HEAD`, **pushed**. **peacegarden.app is live and carries all of
it** — redeployed twice on 6 September, thirteen paths checked at the far end
each time, and **all forty-one named maps read back off the origin and compared
key by key against the local catalogues: no mismatches**. The Arabic map was
walked live: `dir="rtl"`, the row starting at the right, one row height.

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
Norwegian, Dutch and Swedish throughout; and **410 of the 420 area names**,
which are drawn, walked, live, and unread by anybody who speaks the language
they are in. Danish is the only one a reader has looked at.

## Next step

**Getting the maps read.** The naming is finished and it is the half that could
be done alone; forty of the forty-one have never been seen by somebody who reads
the language, and they are all live.

`docs/REVIEWING-A-LANGUAGE.md` is the job and `out/review/INDEX.md` has 43
sendable packets — **and they predate the map**, so screen 6 is now a screen to
judge rather than one to skip. The packets need that section rewritten before
any of them goes out.

**On paying for it.** Marcus's idea, 6 September. MTurk is the wrong market for
this specific job: it pays per task, which rewards speed over judgement, and
text work there is widely routed through machine translation or an LLM — which
would be paying to have machine translation checked by machine translation, on a
brief whose first line is *you are the part that cannot be automated*. Its pool
is also thin to absent for Danish, Welsh, Basque, Icelandic, Maltese and
Kalaallisut. **Prolific** costs about the same, prescreens on language fluency
rather than self-report, pays hourly, and is built for free-text research
answers. For the small languages, one ProZ translator for a 15-minute read is
likely cheaper than the MTurk batches that fail.

**Then the ten Kalaallisut names**, from somebody who has the language. See
below.

## The forty-one that are named, and the one that is not

**Danish is done, and all ten are confirmed by a native reader.** Four were
settled with Marcus directly — *Hjemstavnen* and *Barokhaven* confirmed,
*Dvalebedet* chosen once the cold frame came apart, and *Stubhaven* given for
`areaRenewal`, a *stub* being the coppice stool itself where I had reached for
the forestry word. The remaining six he confirmed on 6 September.

So **Danish is the worked example**, and it is worth handing to a reviewer
alongside the brief: it is the only language where the whole loop has run.

**German, Japanese and Arabic were the pilots**, ordered one at a time to break
the brief, and they did — five corrections between them and Danish. All three
are written up in `NAMING.md` as worked examples with *unread* said plainly, and
the reasoning is in their three commit messages.

**The other thirty-seven went in five batches**, grouped by the problem they
share. Two things came out of that which the brief still does not say:

- **Three of the four languages told to choose a half of `areaMeeting` did not
  have to.** Hungarian *kereszteződés*, Greek *διασταύρωση* and Latvian
  *krustojums* each hold the junction and the plant cross in one word. The
  note's list of eight is longer than the problem is, and only Korean, Chinese,
  Hebrew, Finnish and Basque actually had to compound or choose.
- **`areaWaiting` splits the languages in two.** Dutch *koude bak*, Swedish
  *kallbänk* and Hungarian *hidegágy* are explicitly the cold member of a
  cold/warm pair — the thing English is only by accident and Danish and German
  are not at all. Dutch and Swedish took the object; Hungarian could not,
  because its seedbed is an *-ágy* too.

**Kalaallisut is deliberately unnamed**, and it is the one thing asked for on
6 September that was not done. Greenlandic is polysynthetic, and it has no
orchard, no glasshouse and no knot garden; every name would be a compound built
from affixes that cannot be checked, and ten invented words would be obvious to
every one of its readers. The map falls back to English per name, which is what
that fallback is for.

## The check that came out of it

`check.py` gained the rule the Arabic commission found, and it is the one part
of today's naming that will still be working in a year.

**Two names can be different words for unrelated things and still be a letter
apart** — المشتى beside المشتل — and nothing on this site could see it. It is
measured as **edit distance rather than similarity**, because what matters is
how much is left to tell two names apart: Bulgarian's *Тихата градина* and
*Овощната градина* are three quarters identical by ratio and nine characters
distinguish them.

It also has to be **held against the length**, or it is nonsense in Chinese: a
name there is two or three characters, so 温室 and 交汇处 — which share nothing —
are three edits apart and fired on the first draft of the check. At most three
characters, and at most a third of the shorter name.

It found two faults on its first real run: Hebrew התרדמה beside האדמה, and
Basque *Negutegia* beside *Berotegia*. Maltese *Il-mixtla* beside *Il-mixja
twila* was caught by hand and sits under the threshold, which is why `NAMING.md`
still asks for the ten to be read down a page and looked at.

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

- **The ten Kalaallisut names**, and 410 of the 420 unread. See *Next step*.
- **Six names to put in front of a reader before the others**, all live. German
  `Heimaterde`, which carries the soil and the belonging and also sits near a
  register some German readers will hear — Marcus chose to ship it and ask.
  Japanese `冬囲い` and Turkish `Kütük sürgünleri`, where *sürgün* is also the
  word for exile. Arabic `الخِلْفة`, which needs its diacritics or it reads as
  offspring. Maltese `Il-friegħi ġodda` and Irish `Na buinneáin`, both for
  `areaRenewal` and both the shakiest of their language's ten.
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
