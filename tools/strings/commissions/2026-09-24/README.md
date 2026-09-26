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
   because those are the specification the translator writes to. **Landed
   later on 24 September**: the new English is in `strings.js`, with two new
   paragraphs, `privacy6` and `privacy7`, and the `PRIVACY` claims were
   rewritten to it the same day. Every catalogue carries the eight as `null`,
   Danish included, for the round to translate next.
5. **`FRONT` and `MEANINGS` are standing groups** in `commission.py`, checked
   by `check.py` in every catalogue — the colon, the Latin, and the site's line
   against the app's two halves. A group with nothing written is allowed, so
   the forty languages still to come pass as they are.

## Where it stands

- **Danish is written and read.** Marcus corrected it on 24 September:
  people are *folk* or *personer*, never *mennesker*, and `meaningTravel` is
  his own line. The rule is in `tools/strings/BRIEF.md` and in `REGISTER` in
  `commission.py`, which every Danish sheet now prints, and `check.py` flags
  *menneske* anywhere in Danish, site or app. The three older strings that
  said it — `about1`, and two in the app about leaving the garden — say
  *personer* and *folk* now. The `read` note in `Server/strings/da.json`
  records what he read and when.
- **All six batches are written** (below). **Every site language but Kalaallisut
  now has the front page, the ten meaning lines, `/meanings` and the thirty
  parts.** Each batch was grouped by the problem it shares:

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

## Batch 2, written 24 September

**es fr it nb nl sv, both halves**: 55 site strings and 52 app strings each,
written from their sheets by a Claude session per language, as every earlier
site round was. Every check above passes. **Nobody who speaks any of the six
has read them yet**; these are the choices each translator asked a reader to
look at first.

| | For the reader |
| --- | --- |
| es | `Area` is *Zona* (*área* reads as a measurement). Pattern is *Orden*, not *Patrón* (a template, or a boss). |
| fr | `Area` is *Espace*; a reader might prefer *Coin*. A no-break space before each colon. Straight apostrophes, as `fr.json` has; the app's older French uses curly ones. `downloadTitle` *L'application*, where the app says *l'app*. |
| it | Kinship is *Parentela*, which leans to blood; *Affinità* is the alternative. Pattern is *Disegno*. |
| nb | People are *personer* for a pair and *folk* in general, never *mennesker* — the Danish rule, applied by judgement; `about1` still says *to mennesker*. `A kept place` is *Et hegnet sted*. |
| nl | `Area` is *Gebied*. The plant is *ze*, as `about1` has it; `growBody` says *hij*. Four part labels to check: *De eerste daad*, *Het jaar dat keert*, *De omgangsvormen*, *Een verzorgde plek*. |
| sv | People are *människor*, as `about1` has them. Peace is *Frid* (inward), not *fred* (no war). Kinship is *Frändskap*, which takes in kin by choice. |

## Batch 3, written 25 September

**ja ko zh ar he, the site only** (none is an app language): 55 strings each,
written from their sheets as batch 2 was. Every check passes. Unread by any
speaker; these are what each translator asked a reader to look at first.

| | For the reader |
| --- | --- |
| ja | です・ます and あなた, as `ja.json`. `notYet` is 準備中です. Headwords 絆 (Kinship), 模様 (Pattern), 安らぎ (Peace), 土 (Ground). *Area* as 区画 needs agreeing. Full-width `：`, no spaces. |
| ko | Plain `:` (the sheet keeps `：` for zh and ja). 평온 (Peace), 재생 (Renewal — also "playback"), 유대 (Kinship), 무늬 (Pattern). Genus written 속(屬). |
| zh | Simplified, as `zh.json`. Full-width `：`. 规律 for Pattern (纹理 the alternative); 彼此应尽的本分 for what each owes the other; `notYet` 尚未开放. *Area* is 区域, first use. |
| ar | Plain `:`. One U+200E before `-ynth` in `meaningsSecond`, so the hyphen stays on its left; `rubra`/`ruber` need none. قسم for *area*, جزء for *part*. قرابة leans to blood kin. |
| he | Plain `:`. No marks: the Latin follows `he.json`'s `ל-iPhone`, so `ב-ynth` shows its hyphen as a Hebrew prefix's. Addressed to one man, as the catalogue is; the forms here read the same for either. תבנית (Pattern) can mean a template. |

## Batch 4, written 25 September

**de pt ro ca gl is fi hu eu et, the site only**: 55 strings each, written from
their sheets as batches 2 and 3 were. Every check passes. Unread by any
speaker; these are what each translator asked a reader to look at first.

| | For the reader |
| --- | --- |
| de | *Begegnen / Kreuzen / Wachsen*. *ziehen* is "raise a plant" in the grow lines and "drag" in `frontTurn`. *Worte* where a purist might want *Wörter*. |
| pt | European, as the catalogue is. **Address settled: *tu* throughout** (Marcus, 25 September). `growBody`'s *sua* became *tua*; it was the only string addressing the reader as *você*. |
| ro | `frontGrowBody` at 1.88× the English. `meaningGround` *Pământ* over *Pământul natal*; *Glie* if it reads twice. *Rânduială* for Pattern. *Roata anului*, *Buna-cuviință*. |
| ca | *Creuar*, as `growBody`. *Ordre* for Pattern, as Spanish chose *Orden*. `meaningBeginnings` carries small-to-large less sharply than the English. |
| gl | *Atoparse / Cruzar / Medrar*. *Orde* for Pattern. *zona* for *area*, following Spanish; no settled word. |
| is | *Fundur* is the tagline's word, but also a business meeting. *Appið* (*Smáforritið* the purist's). *Í dvala* repeats *Dvalabeðið*. |
| fi | The Latin stays in the base form, no case endings. *Kuvio* for Pattern. Three labels doubtful: *Pitkä odotus* (loses the counting), `CutAndComeAgain`, `TheWordsForIt`. |
| hu | The Latin takes no suffixes; the case goes on the words round it. *Mintázat* for Pattern; *nappal* for day. The generic "we" in `meaningKinship`. |
| eu | *zu*, as the catalogue. *Antolaera* (phyllotaxis's word) for Pattern needs confirming. Steps as verbal nouns, since *Hazi* alone reads as "seed". *-ynth-ez*. |
| et | *Ristamine* (breeding) for Cross, beside the area *Ristumine*. *Maa* for Ground. `frontMeetBody` the weakest line. |

## Batch 5, written 25 September

**ru uk be pl cs sk sl hr sr bg mk, the site only**: 55 strings each. Every
check passes. Unread by any speaker. The Latin pieces stay in Latin letters and
uninflected throughout; the case goes on the words round them. Where *genus* and
grammatical gender share a word (*род*, *rod*, *rodzaj*), the masculine is
written *мужской род* / *mužský tvar* / *forma męska* and so on — check each.

| | For the reader |
| --- | --- |
| ru | ты, gender-neutral as the catalogue. *Встреча / Скрещивание / Рост*. *род* twice in `meaningsSecond`. `meaningsNames` *Названия на* (fuller: *Названия, начинающиеся на*). |
| uk | ти, gender-neutral (*поодинці*). *Мандри* matches `about2`. Curly ’ in *зобов’язаний*. `meaningsNames` *Назви на*. |
| be | ты. *Лад* for Pattern (not *Узор*), *Спакой* for Peace. *куток* for *area*. Check "could not" in the neither-alone line doesn't read "would not bother". |
| bg | ти. *Закономерност* for Pattern is long for a card. *кът* for *area*. The Kinship line's rhythm. |
| mk | Nouns for the steps (*Средба / Вкрстување / Растење*). *Шара* for Pattern (*Поредок* the fallback). New words: *подрачје*, *дел*, *род*. |
| pl | *żadna z dwóch osób … sama* (feminine *osoba*, no gender chosen). *Wzór* for Pattern (*Ład* the alternative). *Ziemia* over *Ziemia rodzinna*. *Obszar* for *area*. |
| cs | *Řád* for Pattern, *Putování* for Travel. *Země* over *Rodná země* (*Půda* the fallback). *jména* for plant names wants a botanist. |
| sk | *Pôda* for Ground, so the card doesn't say *Rodná zem* twice. *Vzorec* for Pattern leans to "formula". |
| sl | The dual for every pair. *Zemlja* over *Rodna zemlja*. *Vzorec* also "sample". |
| hr | *Susret / Križanje / Rast*. *Uzorak* for Pattern also "sample". *Rez i novi izboj* for cut-and-come-again. |
| sr | Cyrillic, ekavian, *башта*. As Croatian, in its own words. *подручје* for *area*. |

## Batch 6, written 26 September

**lt lv cy ga el tr sq mt, the site only**: 55 strings each, the last of the
forty-one. Every check passes. Unread by any speaker.

Two general notes. **Pattern is the hard headword in all eight**: every one of
these languages uses its everyday word for *pattern* to mean a sewing pattern
or a template, which the brief forbids, so each reaches for its word for
*regularity* instead and each of those is longer than the English. And
**`notYet` follows Danish, German and Czech in saying *opens later*** rather
than *not open yet*: ten area names across three genders in most of these
languages, and a negated participle would have to agree with all of them.

| | For the reader |
| --- | --- |
| lt | *Dėsningumas* for Pattern (*Raštas* reads as ornament). *sritis* for *area*, which nothing had settled. `frontTurn` is informal singular, *Vilk, kad pasuktum*, where Lithuanian interfaces often go impersonal. |
| lv | *Likumsakarība* for Pattern is long for a card, and *Raksts* was rejected as the sewing one. *apvidus* for *area* reads geographic; *nogabals* is the garden word if a reader prefers it. |
| cy | *Patrwm* for Pattern is also a sewing pattern and Welsh has no cleaner word, so the definition carries the sense. *Carennydd* for Kinship over *Perthynas*. *Tangnefedd* for Peace, the inward one, not *heddwch*. *ardal* for *area*. |
| ga | `meaningMeeting`'s headword is three words, *Casadh le chéile*, because *Casadh* alone is turning. *Patrún* has the template sense, as Welsh's does. *Suaimhneas* for Peace, not *Síocháin*. *limistéar* for *area*. |
| el | *Κανονικότητα* for Pattern is long for a card; *Μοτίβο* is the alternative and *πατρόν* the sewing one. *Γαλήνη* for Peace, not *ειρήνη*. *λαχτάρα* for the pull of elsewhere, where *νοσταλγία* leans homeward. *περιοχή* for *area*. |
| tr | *Örüntü* for Pattern is the scientific word; *desen* is fabric and *kalıp* a template. *Yakınlık* for Kinship can read as proximity, and *Akrabalık* leans to blood. `meaningsNames` is *Şöyle başlayan adlar*, because Turkish puts the beginning before the noun and the label has to run into a list. |
| sq | *Afëria* for Kinship (*Farefisnia* leans to blood). *Paqja* for Peace, with *qetësia* the quiet and *prehja* the ease, so the line does not say one thing three times. *gjini* is both genus and grammatical gender, so `meaningsSecond` says *formën e mashkullit*. *zonë* for *area*. |
| mt | **Two for Marcus, not only for a reader.** The area is *L-istennija* and the theme is *Stennija*, so that one card says waiting twice: either the area name or the headword has to move. And `frontCross` is *Inkroċjar*, the horticultural word, where `growBody` says *jaqsam* — agreeing with `growBody`, as the brief asks, would have printed *Qsim* under the glyph, which reads as dividing. Nothing written was changed, so the two disagree until one is chosen. Also *Xejra* for Pattern, *Rabta* for Kinship, *Sliem* for Peace. |

## What each language still lacks, and why

**Regenerated late on 24 September**, after the Glasshouse, the Coppice and
the Home Ground opened and the pad replaced the chevrons: thirteen new keys,
all English only by `strings.js` and outside this round, and `walkBack` and
`walkOn` gone. Then again the same night for the plant panel's seven, English
only by `strings.js` and outside this round like the pad's. The sheets
themselves did not change.

**Regenerated again on 26 September, with batch 6 in.** This commission's
fifty-five are now written in all forty-one, so its four rows have left the
table for every language but Kalaallisut.

`missing.json` has it per language. Every site language but Kalaallisut lacks
the same 54 keys, and none of them is this commission's:

| Group | Keys |
| --- | --- |
| The privacy page, its own sheet (8) | `privacyTitle` `privacy1`–`privacy7` — present as `null` |
| The area paragraphs, English only by `strings.js` (10) | `walkAbout` `quietAbout` `crossAbout` `orchardAbout` `knotAbout` `seedbedAbout` `frameAbout` `glasshouseAbout` `coppiceAbout` `groundAbout` |
| Live, uncommissioned, not in this round (32) | `walkTitle` `wildTitle` `wildBody` `downloadBody` `walkGrowing` `walkEmpty` `walkTurnAnti` `walkTurnClock` `walkAway` `quietAway` `crossAway` `orchardAway` `knotAway` `seedbedAway` `frameAway` `glasshouseAway` `coppiceAway` `groundAway`, and the pad's seven: `moveUp` `moveDown` `moveLeft` `moveRight` `zoomIn` `zoomOut` `moveHome`, and the plant panel's seven: `plantKey` `plantAmbassador` `plantPostcard` `plantPostcardText` `plantCopied` `plantCopyThis` `plantClose` |
| Said nowhere on the site, kept until you decide whether they go (4) | `gardenBody` `walkBody` `goOn` — per `strings.js` — and `walkThisArea`, which no page or script uses either |

**The privacy page is the round that is now next**, at eight keys in
forty-two: it is the only one of the four rows above that is commissioned and
waiting rather than deliberately English.

**Kalaallisut** lacks those 54, this commission's 55, and sixteen more — the
six paragraphs and the ten area names — 125 in all, deliberately, by its
`awaiting` note.

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
