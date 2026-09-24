# The commission of 24 September 2026

The front page that went live on 24 September, the ten one-line meanings its
cards carry, the page at `/meanings`, and the app's new name sheet. Prepared
and not sent: **nothing in this folder, or anywhere in `tools/`, calls a
translation service or any other API.** `sheets.py` reads the repository and
writes text, as `commission.py` does.

| File | What it is |
| --- | --- |
| `BRIEF.md` | The brief, in the register of `tools/strings/BRIEF.md`, with the colon rule for the ten meaning lines |
| `sheets/<code>.md` | One per language, 41 of them: the brief, that language's settled words, and every string with where it is seen and what it has to say. The seven app languages carry the app half as well |
| `sheets.py` | Writes the sheets from `strings.js` and `Localizable.xcstrings` as they stand; `--check` checks what comes back |
| `missing.json` | Every key each language lacks, site and app, sorted by why |

## How big it is

| | Keys | Languages | Strings |
| --- | ---: | ---: | ---: |
| Site: the front page (`front*` 8, plus `downloadTitle`, `gardenTitle`, `notYet`) | 11 | 41 | 451 |
| Site: the ten meaning lines (`meaning*`) | 10 | 41 | 410 |
| Site: `/meanings` (`meanings*`) | 8 | 41 | 328 |
| App: the name sheet (10 headwords, 10 definitions, 30 parts, `Area`, `What the name means`) | 52 | 7 | 364 |
| **Total** | | | **1,553** |

In the seven app languages the site's ten meaning lines and the app's twenty
`theme.*` keys are the same ten entries, written once and joined or split at
the colon, so the distinct writing is 1,483. The ten `area.*` keys are already
in all seven and are not in it.

The 41 are every site language except Kalaallisut, which is left out by its own
`awaiting` note: the machine pass was not good enough there to ship, and it
wants a speaker.

## Decisions first

1. **The ten meaning lines.** `strings.js` marks them *English only*, and
   `meanings.js` *English-only for now*. Commission them?
   - **Yes (recommended).** The new front page sets one on every card, beside
     an area name already in the reader's language, and the app is
     commissioning the same ten entries for its name sheet. Left in English, a
     Greek front page shows ten Greek names under ten English definitions.
   - No. `sheets.py --leave-out meaning-lines`: 1,143 strings, and the app still
     gets its twenty.
2. **The front page's other three keys**, `downloadTitle`, `gardenTitle` and
   `notYet`, uncommissioned in every language.
   - **Include (recommended).** They are the front's two buttons and the word
     on a closed card; without them a translated front page has three English
     labels on its first screen. 123 strings.
   - Leave out. `sheets.py --leave-out front-rest`: 1,430 strings.
3. **Order.**
   - **Danish alone first, read by you, then the other forty in five batches
     (recommended).** The headword-and-colon form is new, and the last
     Danish-first round corrected the brief twice before the rest were ordered.
   - All forty-one at once.
4. **The privacy page**: six keys, `null` in all forty-two, its sheet already
   written (`commission.py --privacy <code>`), and linked from the foot of the
   new front page.
   - **Same round (recommended).** 246 more strings, and it is the page a wary
     reader opens.
   - Later.
5. **A standing check for these keys.** `check.py` has no group for them, so a
   half-translated front page passes it clean; `sheets.py --check` covers this
   round only.
   - **Add `FRONT` and `MEANINGS` as groups of their own in `commission.py`,
     checked by `check.py` (recommended),** as a separate change before the
     returns come in. A group with nothing written is allowed, so no catalogue
     starts failing; the colon rule and the site–app agreement move across
     from `--check`.
   - Keep the dated check only.

## What you run or send next

1. Answer the five above. If 1 or 2 is a no, regenerate with the
   `--leave-out` shown. Regenerate anyway if the English in `strings.js` or the
   app's catalogue has moved since 24 September:

       python3 tools/strings/commissions/2026-09-24/sheets.py

2. **Hand over `sheets/da.md`.** There is no send step to run: every earlier
   round was a sheet handed to a translator, and for the site languages that
   was a Claude session writing the catalogues directly, batched by shared
   problem (the area names went in five batches in `b8ccd43`). So either open
   a session on this branch and give it the sheet, or send the file to a
   person. The sheet says where to write and what to run.
3. Read the Danish yourself — `/`, `/meanings`, `/frame` through `/t`, and the
   book beside a plant's name in the app.
4. The other forty, a batch at a time, each grouped by the problem it shares:

   | Batch | Languages | What they share |
   | --- | --- | --- |
   | 2 | es fr it nb nl sv | the app's other six, both halves |
   | 3 | ja ko zh ar he | the full-width colon, and headwords in scripts where a colon sits differently |
   | 4 | de pt ro ca gl is fi hu eu et | the rest of western and northern Europe |
   | 5 | ru uk be pl cs sk sl hr sr bg mk | Slavic |
   | 6 | lt lv cy ga el tr sq mt | the rest |

5. After each batch:

       python3 tools/strings/commissions/2026-09-24/sheets.py --check
       python3 tools/strings/check.py
       python3 tools/strings/app_check.py
       python3 tools/site/export.py --check

6. **When the meaning lines land, two comments stop being true**: *English
   only, like the area paragraphs* above `meaningWaiting` in
   `Server/assets/js/strings.js`, and *English-only for now* in
   `Server/assets/js/meanings.js`. Change them in the commit that lands the
   first language.
7. Then a reader for each language, as `docs/REVIEWING-A-LANGUAGE.md` asks.

## What each language still lacks, and why

`missing.json` has it per language. Every site language but Kalaallisut lacks
the same 63 keys:

| Group | Keys |
| --- | --- |
| **This commission: the front page** (11) | `frontLead` `frontTurn` `frontMeet` `frontMeetBody` `frontCross` `frontCrossBody` `frontGrow` `frontGrowBody` `downloadTitle` `gardenTitle` `notYet` |
| **This commission: the meaning lines** (10) | `meaningWaiting` `meaningGround` `meaningBeginnings` `meaningRenewal` `meaningTravel` `meaningPeace` `meaningKinship` `meaningPattern` `meaningLight` `meaningMeeting` |
| **This commission: `/meanings`** (8) | `meaningsTitle` `meaningsAbout` `meaningsSecond` `meaningsArea` `meaningsMeaning` `meaningsNames` `meaningsWord` `meaningsSays` |
| The privacy page, its own sheet (6) | `privacyTitle` `privacy1`–`privacy5` — present as `null` |
| The area paragraphs, English only by `strings.js` (7) | `walkAbout` `quietAbout` `crossAbout` `orchardAbout` `knotAbout` `seedbedAbout` `frameAbout` |
| Live, uncommissioned, not in this round (17) | `walkTitle` `wildTitle` `wildBody` `downloadBody` `walkGrowing` `walkEmpty` `walkBack` `walkOn` `walkTurnAnti` `walkTurnClock` `walkAway` `quietAway` `crossAway` `orchardAway` `knotAway` `seedbedAway` `frameAway` |
| Said nowhere on the site, kept until you decide whether they go (4) | `gardenBody` `walkBody` `goOn` — per `strings.js` — and `walkThisArea`, which no page or script uses either |

**Kalaallisut** lacks those 63 and sixteen more — the six paragraphs and the
ten area names — all deliberately, by its `awaiting` note.

**The app's seven** each lack the 52 of this commission and **64 older strings
that are live and untranslated in all seven** — the display settings, releasing
a plant to the garden, the location setting and more. They are outside this
round and are listed under `app` in `missing.json`; worth a round of their
own.

## Kept out on purpose

- **The area paragraphs**, English only by `strings.js`.
- **The part labels, instances and epithet glosses on the site.** They are
  English data in `meanings.js`, not catalogue keys, by that file's own
  account. The app commissions its thirty parts here; if the site ever wants
  them, `meanings.js` says moving them into the catalogue is mechanical, and
  the seven would already have them.
- **The area names, the plant names and the name-beginnings.** The names are
  written; the Latin travels as it is.
- **The four keys said nowhere**, until you decide their fate.
