#!/usr/bin/env python3
"""
The mechanical half of reviewing a commission.

    python3 tools/strings/check.py [code ...]

**None of this reads the language.** It cannot tell you whether a sentence is
good, or even whether it says the right thing — that is what the claims in
`commission.py` are for, and what a native speaker standing at `/t` is for. What
it catches is the class of fault that is invisible to a reviewer reading a list
of strings and obvious once it is on a page: a lost placeholder, English left
behind, a paragraph that will not fit, a word that disagrees with the same word
three lines up.

Exits 1 on anything found, so it can go in CI beside the other four checks.
"""

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
CATALOGUES = ROOT / "Server/strings"
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from commission import (AREAS, CLAIMS, FRONT, MEANINGS, PRIVACY,  # noqa: E402
                        english)

# How much longer than the English a string may be before the layout is at risk.
#
# Not a style rule. The band under the plant, the invitation block and the about
# column are all sized for prose of roughly this length, and German and Finnish
# will legitimately run long — 1.9 is chosen to sit above them and below the
# runaway paraphrase that is the actual failure. Measured in characters, which
# is crude and is the same crudeness for every language.
LENGTH_FACTOR = 1.9

# **Below this many characters of English the ratio says nothing**, and is
# not asked. *Meet* is four letters and *Begegnen* eight: twice the English and
# exactly right. The front page's steps and the `/meanings` column heads are
# words, not prose, and a word is as long as the language makes it. Every
# string the ratio was written for is well past this.
SHORT = 20

# The word each language settled on for `seed`, kept in `terms.json` and read
# off the commissioned strings by `terms.py`. See that file for why it is a
# committed table rather than something worked out on every run.
_TERMBASE = json.loads((pathlib.Path(__file__).resolve().parent / "terms.json")
                       .read_text())
TERMS = _TERMBASE["seed"]

# And, for the languages that need them, the forms of that word — written by
# hand in `BY_HAND` in `terms.py`, where each entry says why. A language with no
# entry falls back to the head of its word, below.
FORMS = _TERMBASE.get("forms", {})

# How long an area name may be before the map wobbles.
#
# A cell is about 8.5rem wide with its name set at 0.86rem, which is two
# comfortable lines at this length. Past it a name takes a third line and makes
# its whole row of the map taller — a wobble rather than a break, and the only
# layout constraint the ten have.
#
# Measured in characters, which is the same crudeness `LENGTH_FACTOR` above
# admits to and is wrong in the same direction: a Chinese or Japanese name is
# three or four characters and can never trip this, so the cap does nothing for
# those two. It is a guard against a *description* arriving where a name was
# asked for, and descriptions arrive in alphabets.
NAME_LIMIT = 34

# How near two of the ten may be to each other before a reader glancing at
# the map cannot tell which cell is which. Characters, not proportion —
# see `area_problems_for`.
NAME_DISTANCE = 3


def problems_for(code, catalogue, source, claims=CLAIMS, group="prose"):
    """One group of commissioned prose.

    **`claims` is a parameter because there are two groups now and they arrive
    separately.** The six paragraphs and the eight on `/privacy` are different
    commissions; a language may have either without the other, and folding them
    into one table made 41 of 42 catalogues fail as half-commissioned the
    moment the privacy keys existed. Same rule as the ten area names.
    """
    found = []
    strings = catalogue.get("strings", {})
    written = {k: v for k, v in strings.items()
               if k in claims and isinstance(v, str) and v.strip()}
    if not written:
        return []                       # still awaiting, and that is allowed

    missing = [k for k in claims if k not in written]
    if missing:
        found.append(f"half-commissioned {group}: {', '.join(missing)} still "
                     "null. They arrive together or the page is two languages "
                     "at once")

    if claims is CLAIMS and not missing and catalogue.get("awaiting"):
        found.append("the `awaiting` note is still there, and it says the prose "
                     "is English on purpose. It is not any more — delete it")

    for key, value in written.items():
        # Placeholders. None of the six carry one today; a translator who
        # invents one, or a future string that gains one, is what this is for.
        theirs = set(re.findall(r"\{(\w+)\}", value))
        ours = set(re.findall(r"\{(\w+)\}", source[key]))
        if theirs != ours:
            found.append(f"{key}: placeholders {sorted(theirs)} against "
                         f"{sorted(ours)} in the English")

        if value.strip() == source[key].strip():
            found.append(f"{key}: identical to the English. If that is genuinely "
                         "right for this language, it still has to be a decision "
                         "somebody made rather than a paste")

        if "!" in value:
            found.append(f"{key}: an exclamation mark. The register does not have "
                         "them — see BRIEF.md")

        ratio = len(value) / max(1, len(source[key]))
        if len(source[key]) >= SHORT and ratio > LENGTH_FACTOR:
            found.append(f"{key}: {ratio:.1f}× the English. The layout is sized "
                         f"for prose, not for a paraphrase of it")

        # An English area name inside one of the six paragraphs.
        #
        # **The reason for this rule inverted on 5 September and the rule did
        # not.** It used to say the areas are proper nouns that stay English, so
        # a translated one is a translated map. The areas are now named in every
        # language, and the check survives on its other half: none of the six
        # paragraphs mentions an area at all, so an English area name appearing
        # in one is either a paste or English left behind.
        #
        # It stays on the English names only. Checking for *this language's* ten
        # would fire on ordinary prose the moment a language named an area with
        # a common word — Danish `Såbedet` against a paragraph about sowing —
        # and the ten are checked properly below in their own right.
        for area in (english_name.removeprefix("The ")
                     for english_name in (source[k] for k in AREAS)):
            if area.lower() in value.lower():
                found.append(f"{key}: carries the area name {area!r}, in "
                             "English. No paragraph here mentions an area, so "
                             "this is a paste or a line left untranslated")

    # Vocabulary. Every one of the six says *seed* in English, and the word for
    # it was settled by the thirteen. A page that calls a seed two things is
    # worse than a page in English.
    term = TERMS.get(code)
    if term:
        # **What counts as saying it is the language's own business, and is
        # written down per language.** `terms.json` carries the forms of the word
        # for the languages that need them, and any one of them does.
        #
        # Where a language has none, the head of the word: four characters, or
        # the whole of it where it is shorter — Danish `frø`, Japanese `種`.
        # Most languages here inflect the ending and not the head, so the head
        # finds every form of the word — Estonian's genitive `seemne` against a
        # nominative `seeme`, which a whole-word match would call a missing word.
        #
        # **The head alone was deciding the grammatical number**, which is not
        # this check's business and was never meant to be: a plural that changes
        # the head has nothing of those four characters left in it, so Italian
        # wrote *Ogni seme* where it wanted *I tuoi semi*, and five other
        # languages bent a sentence the same way in the privacy round of 26
        # September. Those six, and Irish, are `BY_HAND` in `terms.py` now.
        forms = [f.lower() for f in FORMS.get(code, [])] or [term.lower()[:4]]
        for key, value in written.items():
            if "seed" in source[key].lower() and not any(
                    form in value.lower() for form in forms):
                found.append(
                    f"{key}: nothing here is a form of {term!r}, which is this "
                    "language's own word for a seed in the thirteen already "
                    "shipping. Either the paragraph avoids saying seed, or it "
                    "says it with a different word — and if it is a form of the "
                    "right word that the termbase has not got, add it to "
                    "`BY_HAND` in `terms.py` and regenerate")
    return found


# The one colon. `splitEntry` in `meanings.js` cuts a meaning line at the first
# of either, and sets what is before it as the headword.
COLON = re.compile(r"[:：]")

# The Latin `meaningsSecond` quotes, which travel exactly as they are.
LATIN = ["-ynth", "rubra", "ruber"]

# The app's catalogue, for the one place the site and the app say the same
# thing in two halves.
APP = ROOT / "App/PeaceGarden/Resources/Localizable.xcstrings"


# Words a native reader has ruled out, by language: the part of `REGISTER` in
# `commission.py` a machine can see. **Checked in every string the language
# has, site and app, and not only in a commission's own**, because the rule is
# the reader's and it is general: Marcus's *folk* or *personer* for people in
# Danish found three older strings saying *mennesker* the day it was made.
AVOID = {
    "da": [("menneske", "people are folk or personer in Danish, never "
                        "mennesker (Marcus, 24 September 2026)")],
}


def avoid_problems_for(code, catalogue, app):
    """Any word this language's reader has ruled out, anywhere it is said."""
    found = []
    rules = AVOID.get(code, [])
    if not rules:
        return found
    said = {f"{key}": value for key, value in catalogue.get("strings", {}).items()
            if isinstance(value, str)}
    for key in app:
        value = app_value(app, key, code)
        if value:
            said[f"app {key[:48]!r}"] = value
    for where, value in said.items():
        for word, why in rules:
            if word in value.casefold():
                found.append(f"{where}: says {word!r}. {why}")
    return found


def app_value(app, key, code):
    """One language's words for one app key, or None."""
    return (app.get(key, {}).get("localizations", {}).get(code, {})
               .get("stringUnit", {}).get("value"))


def meaning_problems_for(code, catalogue, app):
    """The ten meaning lines, as a headword and a definition.

    **The colon is structure, not punctuation.** The site cuts each line at its
    first colon and never prints it: the headword becomes a `<dfn>`, the rest
    runs on after it. A line with no colon is all definition and no headword; a
    line with two prints the second in the middle of the definition.

    **And in the app's languages the line is two app keys joined.** The name
    sheet sets `theme.<name>` as the headword and `theme.<name>.definition`
    under it, so the site's line and the app's pair have to be the same words,
    or a reader sees two definitions of one theme.

    The thirty part labels are held to the app's `subtheme.<case>` the same
    way, and to being labels: no full stop.
    """
    found = []
    strings = catalogue.get("strings", {})
    for key in MEANINGS:
        value = strings.get(key)
        if not (isinstance(value, str) and value.strip()):
            continue
        if key.startswith("subtheme"):
            # A part label: a label, and in the app's languages the app's own
            # `subtheme.<case>` in the same words.
            if value.rstrip().endswith("."):
                found.append(f"{key}: a full stop. It is a label, not a sentence")
            case = key.removeprefix("subtheme")
            theirs = app_value(app, f"subtheme.{case[0].lower()}{case[1:]}", code)
            if theirs and theirs.strip() != value.strip():
                found.append(f"{key}: the site says {value!r} and the app "
                             f"{theirs!r}. One label, one wording")
            continue
        if key.startswith("meanings"):
            if key == "meaningsSecond":
                for latin in LATIN:
                    if latin not in value:
                        found.append(f"meaningsSecond: {latin!r} is gone. It is "
                                     "Latin, and is copied exactly")
            continue
        colons = COLON.findall(value)
        parts = COLON.split(value, 1)
        head = parts[0].strip()
        if len(colons) != 1 or not head:
            found.append(f"{key}: {len(colons)} colons. One, straight after the "
                         "headword — the site cuts the line there")
            continue
        if len(head.split()) > 3:
            found.append(f"{key}: the headword {head!r} is a phrase. It is the "
                         "theme's name, as a dictionary lists it")
        theme = key.removeprefix("meaning").lower()
        app_head = app_value(app, f"theme.{theme}", code)
        app_body = app_value(app, f"theme.{theme}.definition", code)
        if app_head and app_body and (head, parts[1].strip()) != (
                app_head.strip(), app_body.strip()):
            found.append(f"{key}: the site says {value!r} and the app "
                         f"{app_head!r} / {app_body!r}. One entry, one wording")
    return found


def area_problems_for(catalogue, source):
    """The ten area names, which are a different commission and a different job.

    **None of this reads the language either.** Whether a name is the one a
    gardener would use is what `NAMING.md` and a native reader are for. What is
    here is the class of fault that survives a careful namer: a description
    where a name was asked for, two areas that ended up sharing a word, a map
    half in one language.
    """
    found = []
    strings = catalogue.get("strings", {})
    written = {k: v for k, v in strings.items()
               if k in AREAS and isinstance(v, str) and v.strip()}
    if not written:
        return []                       # still awaiting, and that is allowed

    missing = [k for k in AREAS if k not in written]
    if missing:
        found.append(f"the map is part-named: {', '.join(missing)} still null. "
                     "A name falls back to English on its own, so this ships — "
                     "but it ships a map labelled in two languages")

    for key, value in written.items():
        if value.strip() == source[key].strip():
            found.append(f"{key}: identical to the English. A name is the one "
                         "string here that is allowed to be, but it has to be a "
                         "decision somebody made rather than a paste — say so "
                         "in your notes")

        if value.rstrip().endswith(".") or "!" in value:
            found.append(f"{key}: ends a sentence. These are names — no full "
                         "stop, and the register has no exclamation marks")

        if len(value) > NAME_LIMIT:
            found.append(f"{key}: {len(value)} characters against a cell sized "
                         f"for about {NAME_LIMIT}. That is usually a "
                         "description arriving where a name was asked for")

    # Ten different names. **The one fault a reader cannot work around**, and
    # the reason this check exists at all: the map is how somebody knows where
    # they are standing, and two cells reading alike takes that away. Easy to
    # arrive at honestly — `beginnings` and `ground` both want the word for a
    # bed of earth in several languages, and `peace` and `ground` both want the
    # word for a quiet enclosure.
    seen = {}
    for key, value in written.items():
        seen.setdefault(value.strip().casefold(), []).append(key)
    for name, keys in seen.items():
        if len(keys) > 1:
            found.append(f"{', '.join(keys)}: all called {name!r}. Two areas "
                         "with one name is two cells a reader cannot tell "
                         "apart, and the map is how they know where they are")

    # Two names that are not the same and are not *different enough*. Arabic
    # drafted المشتى for `areaWaiting` beside المشتل for `areaBeginnings`: two
    # words meaning quite unrelated things, one letter apart, in cells read at a
    # glance.
    #
    # **Edit distance rather than similarity**, because the thing that matters
    # is how much is left to tell them apart, not what fraction is shared.
    # Bulgarian's *Тихата градина* and *Овощната градина* share the word for a
    # garden and are three quarters identical by ratio; nine characters
    # distinguish them and nobody will confuse the two. Three characters is the
    # line, and past it this cannot decide — which is why `NAMING.md` asks for
    # the ten to be read down a page and looked at.
    #
    # **Held against the length as well, or it is nonsense in Chinese.** A name
    # there is two or three characters, so 温室 and 交汇处 — which share nothing
    # at all — are three edits apart and would fire on a bare threshold. The
    # distance has to be small *against what is there*: at most a third of the
    # shorter name. In an alphabet that changes nothing, and in a logography it
    # is the whole of the rule.
    ordered = list(written.items())
    for i, (key, value) in enumerate(ordered):
        for other, second in ordered[i + 1:]:
            apart = distance(value.strip(), second.strip())
            shorter = min(len(value.strip()), len(second.strip()))
            if apart <= NAME_DISTANCE and shorter >= apart * 3:
                found.append(
                    f"{key}, {other}: {value!r} and {second!r} are "
                    "near-identical to look at. The map is read at a glance in "
                    "a small cell, so two names this close are two cells a "
                    "reader cannot tell apart even where they mean different "
                    "things")
    return found


def distance(a, b):
    """Levenshtein, on the two names as they are drawn."""
    if a == b:
        return 0
    previous = list(range(len(b) + 1))
    for i, one in enumerate(a, 1):
        row = [i]
        for j, two in enumerate(b, 1):
            row.append(min(previous[j] + 1,          # a character dropped
                           row[j - 1] + 1,           # a character added
                           previous[j - 1] + (one != two)))
        previous = row
    return previous[-1]


def main():
    source = english()
    app = json.loads(APP.read_text())["strings"]
    codes = sys.argv[1:] or sorted(p.stem for p in CATALOGUES.glob("*.json"))
    total, written, named, private, clean, been_read = 0, 0, 0, 0, 0, 0
    fronted, meant = 0, 0
    for code in codes:
        path = CATALOGUES / f"{code}.json"
        if not path.exists():
            sys.exit(f"no catalogue at {path.relative_to(ROOT)}")
        catalogue = json.loads(path.read_text())
        strings = catalogue.get("strings", {})
        total += 1
        if any(isinstance(strings.get(k), str) and strings[k].strip()
               for k in CLAIMS):
            written += 1
        if all(isinstance(strings.get(k), str) and strings[k].strip()
               for k in AREAS):
            named += 1
        if all(isinstance(strings.get(k), str) and strings[k].strip()
               for k in PRIVACY):
            private += 1
        if all(isinstance(strings.get(k), str) and strings[k].strip()
               for k in FRONT):
            fronted += 1
        if all(isinstance(strings.get(k), str) and strings[k].strip()
               for k in MEANINGS):
            meant += 1
        if catalogue.get("read"):
            been_read += 1
        found = (problems_for(code, catalogue, source)
                 + problems_for(code, catalogue, source, PRIVACY, "privacy page")
                 + problems_for(code, catalogue, source, FRONT, "front page")
                 + problems_for(code, catalogue, source, MEANINGS,
                                "meanings")
                 + meaning_problems_for(code, catalogue, app)
                 + avoid_problems_for(code, catalogue, app)
                 + area_problems_for(catalogue, source))
        if found:
            print(f"{code}:")
            for problem in found:
                print(f"  • {problem}")
        else:
            clean += 1
    awaiting = total - written
    print(f"\n{written} of {total} catalogues have the prose"
          f"{f', {awaiting} still awaiting it' if awaiting else ''}. "
          f"{named} have all ten area names. {private} have the privacy "
          f"page. {fronted} have the front page, {meant} what the names "
          f"mean. {clean} clean.")
    # **The count that matters and had nowhere to live.** Everything above is
    # what a machine can see. This is the one number that says whether anybody
    # who speaks the language has looked, and until `read` existed the only way
    # to know was to remember. A catalogue carries `read` with who, when and
    # what — the same shape as `awaiting`, which is the other note here that is
    # about the state of a commission rather than about a string.
    print(f"{been_read} of {total} have been read by somebody who speaks the "
          f"language.")
    return 0 if clean == total else 1


if __name__ == "__main__":
    sys.exit(main())
