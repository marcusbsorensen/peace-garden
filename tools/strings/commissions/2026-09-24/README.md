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
| Site: `/meanings` (`meaningsTitle`, `meaningsAbout`, `meaningsSecond`, `meaningsNames`) | 4 | 41 | 164 |
| Site: the thirty part labels (`subtheme*`) | 30 | 41 | 1,230 |
| App: the name sheet (10 headwords, 10 definitions, 30 parts, `Area`, `What the name means`) | 52 | 7 | 364 |
| **Total** | | | **2,619** |

In the app's seven languages all but two of the app's fifty-two are the
site's own words: the ten entries split at the colon, and the thirty parts
repeated. Each is written once, so the distinct writing is 2,339. The ten
`area.*` keys are already in all seven and are not in it.

**Two changes since the sheets were first written, both 24 September.** Main
made `/meanings` a dictionary and dropped the four headings its tables had
(`meaningsArea`, `meaningsMeaning`, `meaningsWord`, `meaningsSays`); they are
gone from the commission and from Danish. And Marcus moved the thirty part
labels into the site's catalogue, as `subtheme<Case>` beside the app's
`subtheme.<case>`, so they are in the commission for all forty-one.

The 41 are every site language except Kalaallisut, which is left out by its own
`awaiting` note: the machine pass was not good enough there to ship, and it
wants a speaker.

## Decided, 24 September

Marcus answered all five the same day.

1. **The ten meaning lines are commissioned**, reversing *English only* in
   `strings.js` and `meanings.js`. Both comments were changed in the commit
   that landed Danish.
2. **`downloadTitle`, `gardenTitle` and `notYet` are included.**
3. **Danish first, for Marcus to read, then the other forty in batches**,
   later.
4. **The privacy page is in this round, but not yet.** Its English is being
   corrected — `privacy1`–`privacy5` are out of date about what the server
   stores — so nothing on it is translated until the new English is in
   `strings.js`. `privacyTitle` waits with them: the page arrives as one group.
   When it lands, `commission.py --privacy <code>` prints its sheet from the
   corrected English; check its `PRIVACY` claims against the new wording first,
   because those are the specification the translator writes to.
5. **`FRONT` and `MEANINGS` are standing groups** in `commission.py`, checked
   by `check.py` in every catalogue — the colon, the Latin, and the site's line
   against the app's two halves. A group with nothing written is allowed, so
   the forty languages still to come pass as they are.

## Where it stands

- **Danish is written and read.** Marcus corrected it on 24 September:
  people are *folk* or *personer*, never *mennesker*, and `meaningTravel` is
  his own line. The rule is in `tools/strings/BRIEF.md` and in `REGISTER` in
  `commission.py`, which every Danish sheet now prints. Three older Danish
  strings outside this commission still say *mennesker* — `about1` on the
  site, and two in the app about leaving the garden — and wait on his word.
  The `read` note in `Server/strings/da.json` still covers only the area
  names.
- **The other forty are next, a batch at a time**, each grouped by the problem
  it shares:

  | Batch | Languages | What they share |
  | --- | --- | --- |
  | 2 | es fr it nb nl sv | the app's other six, both halves |
  | 3 | ja ko zh ar he | the full-width colon, and headwords in scripts where a colon sits differently |
  | 4 | de pt ro ca gl is fi hu eu et | the rest of western and northern Europe |
  | 5 | ru uk be pl cs sk sl hr sr bg mk | Slavic |
  | 6 | lt lv cy ga el tr sq mt | the rest |

  There is no send step to run: every earlier round was a sheet handed to a
  translator, and for the site languages that was a Claude session writing the
  catalogues directly. Hand each batch its `sheets/<code>.md`. Regenerate
  first if the English has moved:

      python3 tools/strings/commissions/2026-09-24/sheets.py

- **After each batch:**

      python3 tools/strings/commissions/2026-09-24/sheets.py --check
      python3 tools/strings/check.py
      python3 tools/strings/app_check.py
      python3 tools/site/export.py --check

- Then a reader for each language, as `docs/REVIEWING-A-LANGUAGE.md` asks.

## What each language still lacks, and why

`missing.json` has it per language. Every site language but Kalaallisut lacks
the same 89 keys:

| Group | Keys |
| --- | --- |
| **This commission: the front page** (11) | `frontLead` `frontTurn` `frontMeet` `frontMeetBody` `frontCross` `frontCrossBody` `frontGrow` `frontGrowBody` `downloadTitle` `gardenTitle` `notYet` |
| **This commission: the meaning lines** (10) | `meaningWaiting` `meaningGround` `meaningBeginnings` `meaningRenewal` `meaningTravel` `meaningPeace` `meaningKinship` `meaningPattern` `meaningLight` `meaningMeeting` |
| **This commission: `/meanings`** (4) | `meaningsTitle` `meaningsAbout` `meaningsSecond` `meaningsNames` |
| **This commission: the part labels** (30) | `subthemeHeldBack` … `subthemeTheMannersOfIt`, three to a theme in map order |
| The privacy page, its own sheet (6) | `privacyTitle` `privacy1`–`privacy5` — present as `null` |
| The area paragraphs, English only by `strings.js` (7) | `walkAbout` `quietAbout` `crossAbout` `orchardAbout` `knotAbout` `seedbedAbout` `frameAbout` |
| Live, uncommissioned, not in this round (17) | `walkTitle` `wildTitle` `wildBody` `downloadBody` `walkGrowing` `walkEmpty` `walkBack` `walkOn` `walkTurnAnti` `walkTurnClock` `walkAway` `quietAway` `crossAway` `orchardAway` `knotAway` `seedbedAway` `frameAway` |
| Said nowhere on the site, kept until you decide whether they go (4) | `gardenBody` `walkBody` `goOn` — per `strings.js` — and `walkThisArea`, which no page or script uses either |

**Kalaallisut** lacks those 89 and sixteen more — the six paragraphs and the
ten area names — all deliberately, by its `awaiting` note.

**The app's seven** each lack the 52 of this commission and **64 older strings
that are live and untranslated in all seven** — the display settings, releasing
a plant to the garden, the location setting and more. They are outside this
round and are listed under `app` in `missing.json`; worth a round of their
own.

## Kept out on purpose

- **The area paragraphs**, English only by `strings.js`.
- **The instances and the epithet glosses on the site.** English data in
  `meanings.js`, the project's own record of what it attributed to what. The
  part labels above them are keys since 24 September.
- **The area names, the plant names and the name-beginnings.** The names are
  written; the Latin travels as it is.
- **The four keys said nowhere**, until you decide their fate.
