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

- **Danish is written**, site and app, and waiting for Marcus to read it:
  `/`, `/meanings` and `/frame` through `/t`, and the book beside a plant's
  name in the app. Its `read` note in `Server/strings/da.json` still covers
  only the area names, and changes when the reading is done.
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
