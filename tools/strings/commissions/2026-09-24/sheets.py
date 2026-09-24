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

**What each string has to say lives in `commission.py`**, as `FRONT` and
`MEANINGS`, which Marcus made standing groups on 24 September, so `check.py`
holds every catalogue to them. This file prints them into the sheets, and
`--check` adds what only this round needs: the app's name sheet, and the
whole of it arriving at once.
"""

import json
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[3]
sys.path.insert(0, str(ROOT / "tools/strings"))
from commission import AREAS, CLAIMS, PARTS, PRIVACY, REGISTER, english  # noqa: E402
from commission import FRONT as FRONT_CLAIMS  # noqa: E402
from commission import MEANINGS as MEANING_CLAIMS  # noqa: E402

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
# The four headings the page's two tables had went with the tables, when
# `/meanings` became a dictionary on 24 September.
MEANINGS = ["meaningsTitle", "meaningsAbout", "meaningsSecond", "meaningsNames"]
# The thirty part labels, on the site since Marcus moved them into the
# catalogue on 24 September: `subtheme<Case>`, the app's `subtheme.<case>`.
PART_KEYS = {f"subtheme{key[0].upper()}{key[1:]}": f"subtheme.{key}"
             for parts in PARTS.values() for key, _ in parts}

# The app's plain keys: their English is the key.
APP_PLAIN = ["Area", "What the name means"]

# What each string has to say lives in `commission.py`, as `FRONT` and
# `MEANINGS`, since Marcus made them standing groups on 24 September.
NOTES = {**FRONT_CLAIMS, **{k: v for k, v in MEANING_CLAIMS.items()
                           if k.startswith("meanings")}}
ENTRIES = {k.removeprefix("meaning").lower(): v
           for k, v in MEANING_CLAIMS.items()
           if k.startswith("meaning") and not k.startswith("meanings")}


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
    return keys + MEANINGS + list(PART_KEYS)


# Every key a catalogue can lack, sorted by why. `missing.json` is written
# against this, and a key that fits none of them stops the script.
WHY = {
    "this commission: the front page": FRONT + FRONT_REST,
    "this commission: the ten meaning lines": MEANING,
    "this commission: /meanings": MEANINGS,
    "this commission: the thirty part labels": list(PART_KEYS),
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
                   f"app**, and all but two of the app's are the site's own: "
                   "the ten entries split at the colon, and the thirty parts "
                   "word for word. Write each once.\n")
    else:
        out.append(f"**{site_count} strings for the site.** Your language is "
                   "not one of the app's, so there is no app half.\n")
    out.append(f"Write into `Server/strings/{code}.json`"
               + (" and `App/PeaceGarden/Resources/Localizable.xcstrings`."
                  if in_app else "."))
    out.append("")

    # What a reader has corrected, then the vocabulary: both constrain
    # everything after them.
    if REGISTER.get(code):
        out.append("## What a reader of this language has already corrected\n")
        out.append("Rules, not examples.\n")
        out += [f"- {line}" for line in REGISTER[code]]
        out.append("")
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
                       "that area's drawing on its own page, and as its entry "
                       "at `/meanings`.\n")
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

    out.append(f"## The thirty parts ({len(PART_KEYS)})\n")
    out.append("Each theme's three parts, as the numbered senses of its entry: "
               "under the definition on an area's page, and at `/meanings` "
               "with the endings that choose each one. Labels in a short list, "
               "one line each on a phone: sentence case, no full stop. What "
               "the examples have in common is what a label has to cover; the "
               "examples stay in English on the page.\n")
    if in_app:
        out.append("**Your language is one of the app's**, whose name sheet "
                   "lists the same thirty under the same names — "
                   "`subtheme.<case>` there, `subtheme<Case>` here. One label, "
                   "written once, in both.\n")
    for theme in THEMES:
        out.append(f"**{source[f'meaning{theme.capitalize()}'].split(':')[0]}**\n")
        for key in [k for k in PART_KEYS
                    if MEANING_CLAIMS[k]["seen"].endswith(
                        f"`{PART_KEYS[k]}`.")
                    and f"entry for {theme.capitalize()}:" in MEANING_CLAIMS[k]["seen"]]:
            claim = MEANING_CLAIMS[key]
            also = f"  ·  app: `{PART_KEYS[key]}`" if in_app else ""
            out.append(f"- `{key}`{also}  **{source[key]}**  \n"
                       f"  {claim['must'][0]}  \n"
                       f"  *{claim['note'].split(' — ', 1)[1].split('. Those stay')[0]}*")
        out.append("")

    if in_app:
        out.append("## The app's two of its own\n")
        out.append("A book beside a plant's name on the seed screen opens a "
                   "sheet: the theme's headword and definition, the area it "
                   "puts the plant in, and the three parts — all written "
                   "above. **The ten `area.*` keys are already in your "
                   "language.** Two labels are the app's alone:\n")
        for key in APP_PLAIN:
            out.append(f"- `{key}`  \n  *{app[key].get('comment', '')}*")
        out.append("\n  `Area` is the word for one of the garden's ten areas, "
                   "as the site's pages speak of them. `What the name means` "
                   "is the site's `meaningsTitle` said of one plant.\n")
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
    word for word. `check.py` covers the site's groups for good; this adds the
    app's half of the name sheet, which only this round is writing.
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
    # The site's thirty parts and the app's are one list.
    for key, app_key in PART_KEYS.items():
        ours, theirs = written.get(key), app_value(app, app_key, code)
        if ours and filled(theirs) and ours.strip() != theirs.strip():
            problems.append(f"{key}: the site says {ours!r}, the app {theirs!r}")
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
