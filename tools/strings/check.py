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
from commission import AREAS, CLAIMS, english  # noqa: E402

# How much longer than the English a string may be before the layout is at risk.
#
# Not a style rule. The band under the plant, the invitation block and the about
# column are all sized for prose of roughly this length, and German and Finnish
# will legitimately run long — 1.9 is chosen to sit above them and below the
# runaway paraphrase that is the actual failure. Measured in characters, which
# is crude and is the same crudeness for every language.
LENGTH_FACTOR = 1.9

# The word each language settled on for `seed`, kept in `terms.json` and read
# off the commissioned strings by `terms.py`. See that file for why it is a
# committed table rather than something worked out on every run.
TERMS = json.loads((pathlib.Path(__file__).resolve().parent / "terms.json")
                   .read_text())["seed"]

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


def problems_for(code, catalogue, source):
    found = []
    strings = catalogue.get("strings", {})
    written = {k: v for k, v in strings.items()
               if k in CLAIMS and isinstance(v, str) and v.strip()}
    if not written:
        return []                       # still awaiting, and that is allowed

    missing = [k for k in CLAIMS if k not in written]
    if missing:
        found.append(f"half-commissioned: {', '.join(missing)} still null. "
                     "Six arrive together or the page is two languages at once")

    if not missing and catalogue.get("awaiting"):
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
        if ratio > LENGTH_FACTOR:
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
        # Matched on the head of the word rather than the whole of it. Every
        # language here inflects the ending and none of them inflects the head:
        # Estonian's genitive is `seemne` against a nominative `seeme`, and a
        # whole-word match calls that a missing word. Four characters, or the
        # whole term where it is shorter — Danish `frø`, Japanese `種`.
        head = term.lower()[:4]
        for key, value in written.items():
            if "seed" in source[key].lower() and head not in value.lower():
                found.append(
                    f"{key}: nothing here starts like {term!r}, which is this "
                    "language's own word for a seed in the thirteen already "
                    "shipping. Either the paragraph avoids saying seed, or it "
                    "says it with a different word")
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
    return found


def main():
    source = english()
    codes = sys.argv[1:] or sorted(p.stem for p in CATALOGUES.glob("*.json"))
    total, written, named, clean = 0, 0, 0, 0
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
        found = (problems_for(code, catalogue, source)
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
          f"{named} have all ten area names. {clean} clean.")
    return 0 if clean == total else 1


if __name__ == "__main__":
    sys.exit(main())
