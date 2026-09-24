#!/usr/bin/env python3
"""
The commission of 24 September 2026: the front page, and what the names mean.

    python3 tools/strings/commissions/2026-09-24/sheets.py            # write the sheets
    python3 tools/strings/commissions/2026-09-24/sheets.py --check    # check what came back
    python3 tools/strings/commissions/2026-09-24/sheets.py --leave-out front-rest,meaning-lines

**It sends nothing anywhere.** Like `commission.py`, it reads the repository and
writes text: one sheet per language in `sheets/`, and `missing.json`, the
inventory of every key a language still lacks. Nothing here calls a service.

**Why a script and not only the sheets.** `commission.py` reads the English out
of `strings.js` rather than repeating it, because a second copy is wrong by the
afternoon; this does the same, and reads the app's English out of
`Localizable.xcstrings`. If the English moves before the sheets are handed over,
run it again. What it owns is what exists nowhere else in a form a translator
can be handed: what each string has to say.

**Why not a fourth mode of `commission.py`.** `check.py` imports that file's
groups and runs in CI, so a group added there is a standing rule for every
catalogue rather than one round's paperwork. Whether these keys become
standing groups is Marcus's call, and the README puts it to him; until then
`--check` below does their share of the mechanical checking.
"""

import json
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[3]
sys.path.insert(0, str(ROOT / "tools/strings"))
from commission import AREAS, CLAIMS, PRIVACY, english  # noqa: E402

CATALOGUES = ROOT / "Server/strings"
XCSTRINGS = ROOT / "App/PeaceGarden/Resources/Localizable.xcstrings"
TERMS = json.loads((ROOT / "tools/strings/terms.json").read_text())["seed"]

# Kalaallisut is left out, by its own `awaiting` note: the machine pass was not
# good enough there to ship, and nobody on this side can read it. A null draws
# the English, correctly marked, which is the honest state.
LEFT_OUT = {"kl"}

THEMES = ["waiting", "ground", "beginnings", "renewal", "travel",
          "peace", "kinship", "pattern", "light", "meeting"]

FRONT = ["frontLead", "frontTurn", "frontMeet", "frontMeetBody",
         "frontCross", "frontCrossBody", "frontGrow", "frontGrowBody"]
# The three other keys the new front page draws. Without them its two buttons
# and the word on a closed card stay English on a page otherwise translated.
FRONT_REST = ["downloadTitle", "gardenTitle", "notYet"]
MEANING = [f"meaning{t.capitalize()}" for t in THEMES]
MEANINGS = ["meaningsTitle", "meaningsAbout", "meaningsSecond", "meaningsArea",
            "meaningsMeaning", "meaningsNames", "meaningsWord", "meaningsSays"]

# The app's plain keys: their English is the key.
APP_PLAIN = ["Area", "What the name means"]

# ---------------------------------------------------------------------------
# What each string has to say.
#
# Same shape as `commission.py`'s CLAIMS. **`must not` appears only where there
# is a known trap**: the fluent, obvious rendering that says the wrong thing.
# ---------------------------------------------------------------------------
NOTES = {
    "frontLead": {
        "seen": "The front page, `/`, directly under the heading (`tagline`). "
                "It is the whole of the page for a reader who goes no further "
                "than the first screen.",
        "must": [
            "Two phones touch, and each hands the other a seed.",
            "What grows is one plant that took both of them: neither person "
            "could have grown this plant alone.",
            "It opens over real days.",
        ],
        "must not": [
            "Read as *neither can grow anything alone*. The claim is about this "
            "plant needing both seeds, and a reader with a plant of their own "
            "already knows the other reading is false.",
        ],
        "note": "Two of its three claims are already in your `about1`: *two "
                "phones hand each other a seed* and *it opens over real days*. "
                "Use the same words for them here.",
    },
    "frontTurn": {
        "seen": "A small hint under the plant on the front page, which turns "
                "when somebody drags it with a finger or a mouse. Visual only: "
                "a screen reader skips it.",
        "must": [
            "Dragging the plant turns it.",
        ],
        "note": "The one instruction in this commission, and it is a hint on a "
                "control rather than a sentence. Use the form your language's "
                "interfaces use for such a hint — an infinitive or a short "
                "phrase is usual — and a verb for *drag* that covers a finger "
                "as well as a mouse.",
    },
    "frontMeet": {
        "seen": "The first of three steps on the front page, each a heading of "
                "one word under a glyph, read left to right as a sequence: "
                "*Meet*, *Cross*, *Grow*.",
        "must": ["Two people meet, in person."],
        "note": "The three are one form between them — three verbs, or three "
                "verbal nouns, whichever your language uses for the steps of a "
                "process. One word each where your language allows.",
    },
    "frontMeetBody": {
        "seen": "Under *Meet*.",
        "must": [
            "Two people touch their phones together.",
            "They are in the same place, physically together.",
        ],
        "note": "*In the same room* stands for being there together; your "
                "language's everyday way of saying *face to face* or *in the "
                "same place* is right if a room is too literal.",
    },
    "frontCross": {
        "seen": "The second step, under its glyph.",
        "must": ["The two seeds are crossed, as a gardener crosses two plants."],
        "must not": [
            "Be a word that means only crossing a road, or a cross as a shape. "
            "A word that holds the gardener's sense as well — *krydse*, "
            "*croiser* — is exactly right.",
        ],
        "note": "Your `growBody` already has the verb: *Peace Garden crosses "
                "this seed with one of your own*. Use it. Where your "
                "`areaMeeting` is the plant-cross word, the two will visibly "
                "belong together, which is right.",
    },
    "frontCrossBody": {
        "seen": "Under *Cross*.",
        "must": [
            "The exchange goes both ways: each person hands the other a seed.",
            "Then the two seeds are crossed.",
        ],
        "note": "*Hand each other a seed* is the phrase your `about1` already "
                "has. Agree with it.",
    },
    "frontGrow": {
        "seen": "The third step, under its glyph.",
        "must": ["A plant grows."],
    },
    "frontGrowBody": {
        "seen": "Under *Grow*.",
        "must": [
            "The plant is one neither of the two could have grown alone.",
            "It opens over real days.",
        ],
        "note": "It repeats the second sentence of `frontLead`, a screen "
                "further down. Word the two alike.",
    },
    "gardenTitle": {
        "seen": "The front page's second button and the heading over the ten "
                "cards. Also the name of the garden's glyph in the bar on every "
                "page, read aloud and shown on hover, and the heading of the "
                "small map at the foot of each area page.",
        "must": ["The garden: the place of ten areas that a reader can walk."],
        "note": "A name for the place, with the article your language gives a "
                "place it means as *the one*. The word for *garden* your "
                "catalogue already uses.",
    },
    "downloadTitle": {
        "seen": "The front page's first button, which opens `/download`, and "
                "that page's heading.",
        "must": ["The app — Peace Garden on the phone — as a thing, by name."],
        "must not": [
            "Be a command such as *Download* or *Get the app*. It is a heading.",
        ],
    },
    "notYet": {
        "seen": "On the card of each area that is still being built, on the "
                "front page, and beside the same areas in the table at "
                "`/meanings`.",
        "must": ["This area opens later."],
        "note": "A plain statement of where things stand, matter-of-fact "
                "rather than apologetic. Keep the full stop.",
    },
    "meaningsTitle": {
        "seen": "The heading of `/meanings`, and the words of every link to it: "
                "the book glyph in the bar on every page (read aloud and shown "
                "on hover) and the headword on each area page.",
        "must": ["What the names of the plants mean."],
        "note": "A heading, so no full stop. In the app's languages the app's "
                "own button says *What the name means*, of one plant; the two "
                "should read as the same phrase in the singular and the plural.",
    },
    "meaningsAbout": {
        "seen": "The first paragraph of `/meanings`, above a worked example "
                "that takes one name apart piece by piece.",
        "must": [
            "A plant's name says where the plant belongs.",
            "The beginning of the name's first word chooses the area it "
            "stands in.",
            "The ending of that same first word chooses which of the area's "
            "three parts the words shown under the plant come from.",
        ],
        "must not": [
            "Suggest anybody chooses or gives the name. It is drawn from the "
            "seed.",
        ],
        "note": "*The words under it* are the quotation shown under a plant. "
                "*First word* is said plainly on purpose; the term *genus* "
                "arrives in the next paragraph.",
    },
    "meaningsSecond": {
        "seen": "The second paragraph of `/meanings`, after the worked example.",
        "must": [
            "The second word of the name names the one way this plant most "
            "differs from the rest of its genus.",
            "After a first word ending in -ynth, the second word takes its "
            "masculine form: rubra becomes ruber.",
        ],
        "note": "`-ynth`, `rubra` and `ruber` are Latin and copied exactly, "
                "letter for letter. *Genus* and *masculine form* are the "
                "ordinary botanical and grammatical terms in your language.",
    },
    "meaningsArea": {
        "seen": "A column heading in the table at `/meanings`, over the ten "
                "area names.",
        "must": ["An area of the garden."],
        "note": "One word. In the app's languages the app's name sheet has the "
                "same word as a row label (`Area`); they are one word in two "
                "places.",
    },
    "meaningsMeaning": {
        "seen": "A column heading in the table at `/meanings`, over the ten "
                "definitions; on a phone it becomes a small label above each "
                "one.",
        "must": ["What the theme holds: what it gathers in and is about."],
    },
    "meaningsNames": {
        "seen": "A column heading in the table at `/meanings`, over the "
                "syllables that begin plant names in each area — *Nyx-*, "
                "*Fen-*. On a phone it becomes a label directly before the "
                "syllables.",
        "must": ["Names that begin with the syllables that follow."],
        "note": "It has to lead straight into a list of name-beginnings, so "
                "choose the grammar that runs into one.",
    },
    "meaningsWord": {
        "seen": "A column heading in the second table at `/meanings`, over "
                "Latin second words such as *ruber*.",
        "must": ["The second word of a plant's name."],
    },
    "meaningsSays": {
        "seen": "The column heading beside `meaningsWord`, over what each "
                "second word says about its plant.",
        "must": ["What that word says about the plant."],
    },
}

# The ten entries. `must` is what the definition has to carry, half by half;
# `headword` is the trap in the theme's own word. The three parts each theme
# holds come from `commission.py`'s AREAS, printed under each.
ENTRIES = {
    "waiting": {
        "headword": "Waiting as a noun, the act of it. The word for waiting "
                    "rather than for hope or expectation.",
        "must": [
            "What is held back until its time comes, however long that is.",
            "And whoever keeps watch over it — a person standing by.",
        ],
    },
    "ground": {
        "headword": "Ground as earth. Where your language's word for it also "
                    "means *reason* or *floor*, pick the one a gardener means.",
        "must": [
            "The earth a plant stands in.",
            "And the earth that is yours — home ground, belonging.",
        ],
        "note": "*Yours* addresses the reader, informally. If your language "
                "has one word that is both soil and home, as Latin *colere* "
                "is both to till and to dwell, it is the headword.",
    },
    "beginnings": {
        "headword": "Beginnings, in whichever number your language speaks of "
                    "beginnings as a subject.",
        "must": [
            "The first thing a seed does — germination.",
            "And how much comes of it — small becoming large.",
        ],
    },
    "renewal": {
        "headword": "Renewal: coming again, being made new.",
        "must": [
            "What is cut back and grows again, in the gardener's sense.",
            "And what is mended — made whole after breaking.",
        ],
    },
    "travel": {
        "headword": "Travel as a noun: going, the journey.",
        "must": [
            "The ways a seed goes and the ways a person goes, both.",
            "And the pull of somewhere else — longing for a far place.",
        ],
        "must not": [
            "Make *pull* a physical pulling. It is the tug of elsewhere.",
        ],
    },
    "peace": {
        "headword": "Peace in the quiet, inward sense.",
        "must": [
            "The quiet a garden exists for.",
            "And the ease that comes with that quiet.",
        ],
    },
    "kinship": {
        "headword": "Kinship: belonging together as kin, by blood or by "
                    "choice.",
        "must": [
            "What grows together — grafts, roots and fungi joined.",
            "And the people kept rather than happened upon: chosen and held "
            "on to, set against chance.",
        ],
        "note": "*Kept rather than happened upon* is Marcus's reading of the "
                "Orchard. The contrast between keeping and chance is the point "
                "of the half; keep both sides of it.",
    },
    "pattern": {
        "headword": "Pattern as order in living things.",
        "must": [
            "The order in living things — spirals, tiling.",
            "And the names given to order — the words people have for it.",
        ],
        "must not": [
            "Be a sewing pattern, a template or a model to copy.",
        ],
    },
    "light": {
        "headword": "Light as a noun, as in sunlight.",
        "must": [
            "What a plant turns towards.",
            "And the day it keeps time by — a plant measures the length of "
            "the day.",
        ],
        "must not": [
            "Be *light* as in weight, or the light appearance in the app's "
            "settings.",
        ],
    },
    "meeting": {
        "headword": "Meeting: two coming together, the word your `tagline` "
                    "already uses for *a meeting*.",
        "must": [
            "Two coming together at the right moment.",
            "And what each owes the other — the obligations of host and guest, "
            "of flower and pollinator.",
        ],
        "must not": [
            "Be an appointment or a conference.",
        ],
    },
}


# ---------------------------------------------------------------------------
# Reading the repository
# ---------------------------------------------------------------------------

def app_catalogue():
    return json.loads(XCSTRINGS.read_text())["strings"]


def app_english(app, key):
    unit = app[key].get("localizations", {}).get("en", {}).get("stringUnit")
    return unit["value"] if unit else key


def app_languages(app):
    found = set()
    for entry in app.values():
        found |= set(entry.get("localizations", {}))
    return sorted(found - {"en"})


def app_value(app, key, code):
    """A language's value for one app key, or None.

    A plural key keeps its words under `variations` rather than `stringUnit`;
    it is written if its `other` case is.
    """
    local = app.get(key, {}).get("localizations", {}).get(code, {})
    unit = (local.get("stringUnit")
            or local.get("variations", {}).get("plural", {})
                    .get("other", {}).get("stringUnit"))
    return unit.get("value") if unit else None


def subtheme_keys(app):
    """The three `subtheme.*` keys of each theme, found by their English.

    The labels are the part of each line of `commission.py`'s `thirds` before
    the dash, so the grouping is read rather than written down twice.
    """
    by_label = {app_english(app, k): k for k in app if k.startswith("subtheme.")}
    grouped = {}
    for theme in THEMES:
        thirds = AREAS[f"area{theme.capitalize()}"]["thirds"]
        grouped[theme] = []
        for line in thirds:
            label = line.split(" — ")[0]
            if label not in by_label:
                sys.exit(f"no subtheme key has the English {label!r}")
            grouped[theme].append((by_label[label], line))
    assert sum(len(v) for v in grouped.values()) == len(by_label) == 30
    return grouped


def app_keys(app):
    keys = []
    for theme in THEMES:
        keys += [f"theme.{theme}", f"theme.{theme}.definition"]
    for theme, parts in subtheme_keys(app).items():
        keys += [k for k, _ in parts]
    return keys + APP_PLAIN


def filled(value):
    return isinstance(value, str) and value.strip() != ""


def site_keys(leave_out):
    keys = list(FRONT)
    if "front-rest" not in leave_out:
        keys += FRONT_REST
    if "meaning-lines" not in leave_out:
        keys += MEANING
    return keys + MEANINGS


# Every key a catalogue can lack, sorted by why. `missing.json` is written
# against this, and a key that fits none of them stops the script.
WHY = {
    "this commission: the front page": FRONT + FRONT_REST,
    "this commission: the ten meaning lines": MEANING,
    "this commission: /meanings": MEANINGS,
    "the privacy page, its own sheet (commission.py --privacy)": list(PRIVACY),
    "the area paragraphs, English only by strings.js": ["walkAbout", "quietAbout", "crossAbout", "orchardAbout",
                   "knotAbout", "seedbedAbout", "frameAbout"],
    "live, uncommissioned, and not in this round": [
        "walkTitle", "wildTitle", "wildBody", "downloadBody",
        "walkGrowing", "walkEmpty", "walkBack", "walkOn", "walkTurnAnti",
        "walkTurnClock", "walkAway", "quietAway", "crossAway", "orchardAway",
        "knotAway", "seedbedAway", "frameAway"],
    "said nowhere on the site, kept until Marcus decides whether they go": [
        "gardenBody", "walkBody", "goOn", "walkThisArea"],
    "the six paragraphs, awaiting by decision": list(CLAIMS),
    "the ten area names, awaiting by decision": [k for k in AREAS],
}


# ---------------------------------------------------------------------------
# Writing the sheets
# ---------------------------------------------------------------------------

def quote(text):
    return "\n".join(f"> {line}" for line in text.splitlines())


def claim_block(out, note):
    out.append(f"*Where it is seen.* {note['seen']}\n")
    out.append("*It must say:*")
    out += [f"  - {line}" for line in note["must"]]
    if note.get("must not"):
        out.append("\n*It must not:*")
        out += [f"  - {line}" for line in note["must not"]]
    if note.get("note"):
        out.append(f"\n*Note.* {note['note']}")
    out.append("")


def sheet(code, catalogue, source, app, keys, leave_out):
    theirs = catalogue.get("strings", {})
    in_app = code in app_languages(app)
    out = [(HERE / "BRIEF.md").read_text(), "=" * 78, ""]
    out.append(f"# {catalogue['language']} — {catalogue['endonym']}  ({code})\n")
    site_count = len(keys)
    if in_app:
        app_count = len(app_keys(app))
        out.append(f"**{site_count} strings for the site and {app_count} for the "
                   f"app.** The ten site entries and twenty of the app's are "
                   "the same ten headwords and definitions, written once.\n")
    else:
        out.append(f"**{site_count} strings for the site.** Your language is "
                   "not one of the app's, so there is no app half.\n")
    out.append(f"Write into `Server/strings/{code}.json`"
               + (" and `App/PeaceGarden/Resources/Localizable.xcstrings`."
                  if in_app else "."))
    out.append("")

    # The vocabulary first, because it constrains everything after it.
    out.append("## The words this language has already chosen\n")
    out.append("Commissioned and shipping. **What you write has to agree with "
               "them.**\n")
    if code in TERMS:
        out.append(f"- *seed*: **{TERMS[code]}** (`tools/strings/terms.json`)")
    for key, value in theirs.items():
        if key in keys or key in AREAS or not filled(value):
            continue
        out.append(f"- `{key}`\n    en  {source.get(key, '?')}\n    {code}  {value}")
    out.append("\n**The ten areas**, which the front page sets under your ten "
               "meaning lines, card by card:\n")
    for key in AREAS:
        out.append(f"- `{key}`  {source[key]}  →  **{theirs.get(key) or '(none)'}**")
    if in_app:
        out.append("\n**In the app**, the rows the new `Area` label sits "
                   "among on the seed screen:\n")
        for key in ["Seed", "Created"]:
            out.append(f"- `{key}`  →  **{app_value(app, key, code)}**")
    out.append("")

    front = [k for k in FRONT + FRONT_REST if k in keys]
    out.append(f"## The front page ({len(front)})\n")
    for key in front:
        out.append(f"### `{key}`\n")
        out.append(quote(source[key]) + "\n")
        claim_block(out, NOTES[key])

    site_lines = "meaning-lines" not in leave_out
    if site_lines or in_app:
        out.append("## The ten entries: what each theme means\n")
        out.append("Each one is **Headword: definition.** — one colon, straight "
                   "after the headword, and no other (the brief says why). The "
                   "headword is the theme; the area name printed under each is "
                   "yours already, and is there so the two read well together "
                   "on a card.\n")
        if not site_lines:
            out.append("**This round, the site keeps these ten in English**, "
                       "and only the app's two keys for each are written: the "
                       "headword, and the definition that follows it.\n")
        elif in_app:
            out.append("**Your language is one of the app's.** Write each "
                       "headword and definition once. The site's key is the two "
                       "joined by your colon; the app's two keys are the same "
                       "two pieces, the headword without the colon and the "
                       "definition as it follows it.\n")
        for theme in THEMES:
            key = f"meaning{theme.capitalize()}"
            area = AREAS[f"area{theme.capitalize()}"]
            entry = ENTRIES[theme]
            also = (f"  ·  app: `theme.{theme}`, `theme.{theme}.definition`"
                    if in_app else "")
            out.append(f"### `{key}`{also}\n")
            out.append(quote(source[key]) + "\n")
            name = theirs.get(f"area{theme.capitalize()}")
            out.append(f"*The card it sits on.* Above **{name}**. Also under "
                       "that area's paragraph on its own page, and in the "
                       "`/meanings` table.\n")
            out.append(f"*The headword.* {entry['headword']}\n")
            out.append("*The definition must say:*")
            out += [f"  - {line}" for line in entry["must"]]
            if entry.get("must not"):
                out.append("\n*It must not:*")
                out += [f"  - {line}" for line in entry["must not"]]
            out.append("\n*What the theme holds, in three* (context, not text "
                       "to translate):")
            out += [f"  - {line}" for line in area["thirds"]]
            if entry.get("note"):
                out.append(f"\n*Note.* {entry['note']}")
            out.append("")

    out.append(f"## The page at /meanings ({len(MEANINGS)})\n")
    for key in MEANINGS:
        out.append(f"### `{key}`\n")
        out.append(quote(source[key]) + "\n")
        claim_block(out, NOTES[key])

    if in_app:
        grouped = subtheme_keys(app)
        out.append("## The app's name sheet (32 more)\n")
        out.append("A book beside a plant's name on the seed screen opens a "
                   "sheet: the theme as a headword with its definition (the "
                   "twenty keys above), the area it puts the plant in, and the "
                   "theme's three parts, with the one the name's ending chose "
                   "set in full ink and the other two faint. **The ten "
                   "`area.*` keys are already written in your language** and "
                   "are left alone.\n")
        out.append("### The thirty parts\n")
        out.append("Labels in a short list, one line each on a phone: "
                   "sentence case, no full stop. Each is the name of one third "
                   "of a theme, so what the examples after the dash have in "
                   "common is what the label has to cover. The examples are "
                   "context and are not translated.\n")
        for theme in THEMES:
            out.append(f"**{source[f'meaning{theme.capitalize()}'].split(':')[0]}**\n")
            for key, line in grouped[theme]:
                comment = app[key].get("comment", "")
                out.append(f"- `{key}`  **{app_english(app, key)}**  \n"
                           f"  {line.split(' — ', 1)[1]}.  \n"
                           f"  *{comment}*")
            out.append("")
        out.append("### Two more\n")
        for key in APP_PLAIN:
            out.append(f"- `{key}`  \n  *{app[key].get('comment', '')}*")
        out.append("\n  `Area` is the same word as the site's `meaningsArea`. "
                   "`What the name means` is the site's `meaningsTitle` said of "
                   "one plant.\n")
    return "\n".join(out).rstrip() + "\n"


def inventory(source, app):
    """Every key each language lacks, sorted by why."""
    everything = [k for keys in WHY.values() for k in keys]
    report = {"site": {}, "app": {}}
    for path in sorted(CATALOGUES.glob("*.json")):
        strings = json.loads(path.read_text()).get("strings", {})
        lacking = [k for k in source if not filled(strings.get(k))]
        stray = [k for k in lacking if k not in everything]
        if stray:
            sys.exit(f"{path.stem}: {stray} lack a translation and fit no "
                     "group in WHY. Say why, then run this again.")
        report["site"][path.stem] = {
            why: [k for k in keys if k in lacking]
            for why, keys in WHY.items() if any(k in lacking for k in keys)}
    ours = set(app_keys(app))
    for code in app_languages(app):
        report["app"][code] = {
            "this commission: the name sheet":
                [k for k in app_keys(app) if not filled(app_value(app, k, code))],
            "older strings, untranslated and not in this round":
                sorted(k for k, e in app.items()
                       if k not in ours and not k.startswith("area.")
                       and e.get("shouldTranslate") is not False
                       and e.get("extractionState") != "stale"
                       and not filled(app_value(app, k, code))),
        }
    return report


def write(leave_out):
    source = english()
    app = app_catalogue()
    keys = site_keys(leave_out)
    target = HERE / "sheets"
    target.mkdir(exist_ok=True)
    for old in target.glob("*.md"):
        old.unlink()
    codes = []
    for path in sorted(CATALOGUES.glob("*.json")):
        if path.stem in LEFT_OUT:
            continue
        catalogue = json.loads(path.read_text())
        (target / f"{path.stem}.md").write_text(
            sheet(path.stem, catalogue, source, app, keys, leave_out))
        codes.append(path.stem)
    (HERE / "missing.json").write_text(
        json.dumps(inventory(source, app), ensure_ascii=False, indent=1) + "\n")
    languages = app_languages(app)
    print(f"{len(codes)} sheets: {len(keys)} site strings × {len(codes)} = "
          f"{len(keys) * len(codes)}; {len(app_keys(app))} app strings × "
          f"{len(languages)} = {len(app_keys(app)) * len(languages)}. "
          f"Left out: {', '.join(sorted(LEFT_OUT))}.")


# ---------------------------------------------------------------------------
# Checking what comes back
# ---------------------------------------------------------------------------

COLON = re.compile(r"[:：]")


def check(leave_out):
    """The mechanical half, for this commission's keys only.

    None of this reads the language; `check.py`'s opening paragraph applies
    word for word. It is here because `check.py` has no group for these keys
    yet, so a half-translated front page passes it clean.
    """
    source = english()
    app = app_catalogue()
    keys = site_keys(leave_out)
    areas_en = [source[k].removeprefix("The ").lower() for k in AREAS]
    found, started = [], 0
    for path in sorted(CATALOGUES.glob("*.json")):
        code = path.stem
        if code in LEFT_OUT:
            continue
        strings = json.loads(path.read_text()).get("strings", {})
        written = {k: strings[k] for k in keys if filled(strings.get(k))}
        app_started = code in app_languages(app) and any(
            filled(app_value(app, k, code)) for k in app_keys(app))
        if not written and not app_started:
            continue
        started += 1
        problems = []
        front = [k for k in FRONT if k in written]
        if front and len(front) != len(FRONT):
            problems.append("half a front page: "
                            + ", ".join(k for k in FRONT if k not in written))
        for key, value in written.items():
            english_value = source[key]
            if value.strip() == english_value.strip():
                problems.append(f"{key}: identical to the English — a decision "
                                "or a paste?")
            if "!" in value:
                problems.append(f"{key}: an exclamation mark")
            if re.findall(r"\{(\w+)\}", value):
                problems.append(f"{key}: a placeholder the English has not got")
            if len(english_value) >= 20 and len(value) > 1.9 * len(english_value):
                problems.append(f"{key}: {len(value) / len(english_value):.1f}× "
                                "the English")
            for area in areas_en:
                if area in value.lower():
                    problems.append(f"{key}: the English area name {area!r}")
            term = TERMS.get(code)
            if (term and "seed" in english_value.lower()
                    and term.lower()[:4] not in value.lower()):
                problems.append(f"{key}: nothing starts like {term!r}, this "
                                "language's word for a seed")
        for key in MEANING:
            if key not in written:
                continue
            colons = COLON.findall(written[key])
            head = COLON.split(written[key], 1)[0].strip()
            if len(colons) != 1 or not head:
                problems.append(f"{key}: {len(colons)} colons. One, straight "
                                "after the headword")
            elif len(head.split()) > 3:
                problems.append(f"{key}: the headword {head!r} is a phrase")
        if "meaningsSecond" in written:
            for latin in ["-ynth", "rubra", "ruber"]:
                if latin not in written["meaningsSecond"]:
                    problems.append(f"meaningsSecond: {latin!r} is missing")
        if code in app_languages(app):
            problems += app_problems(code, app, written)
        if problems:
            found.append((code, problems))
    for code, problems in found:
        print(f"{code}:")
        for problem in problems:
            print(f"  • {problem}")
    print(f"\n{started} of {len(list(CATALOGUES.glob('*.json'))) - len(LEFT_OUT)} "
          f"languages have started. {started - len(found)} clean.")
    return 1 if found else 0


def app_problems(code, app, written):
    problems = []
    lacking = [k for k in app_keys(app) if not filled(app_value(app, k, code))]
    if lacking and len(lacking) != len(app_keys(app)):
        problems.append(f"app: {len(lacking)} of the name sheet's "
                        f"{len(app_keys(app))} still English")
    for key in app_keys(app):
        value = app_value(app, key, code)
        if not filled(value):
            continue
        if "!" in value:
            problems.append(f"app {key}: an exclamation mark")
        if key.startswith("subtheme.") and value.rstrip().endswith("."):
            problems.append(f"app {key}: a label with a full stop")
    # The site's line and the app's two halves are one entry.
    for theme in THEMES:
        line = written.get(f"meaning{theme.capitalize()}")
        head = app_value(app, f"theme.{theme}", code)
        body = app_value(app, f"theme.{theme}.definition", code)
        if not (line and filled(head) and filled(body)):
            continue
        parts = COLON.split(line, 1)
        if len(parts) != 2 or (parts[0].strip(), parts[1].strip()) != (
                head.strip(), body.strip()):
            problems.append(f"meaning{theme.capitalize()}: the site says "
                            f"{line!r}, the app {head!r} / {body!r}")
    return problems


def main():
    argv = sys.argv[1:]
    leave_out = set()
    if "--leave-out" in argv:
        leave_out = set(argv[argv.index("--leave-out") + 1].split(","))
        unknown = leave_out - {"front-rest", "meaning-lines"}
        if unknown:
            sys.exit(f"--leave-out takes front-rest and meaning-lines, not {unknown}")
    if "--check" in argv:
        return check(leave_out)
    write(leave_out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
