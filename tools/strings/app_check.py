#!/usr/bin/env python3
"""
The numeral rule, on the app's catalogue.

    python3 tools/strings/app_check.py

**A quantity is a numeral from 2 up; one stays a word.** `BRIEF.md` has said so
since 6 September and nothing enforced it, which is how *1 grown from a meeting*
shipped in eight languages.

The handover expected this to live in `check.py` and to need a table of every
language's number words. It needs neither. `check.py` reads `Server/strings`,
and the site's forty-two catalogues contain **no numerals at all** — the site's
prose never states a quantity. The whole of the rule's exposure is the app, and
there the fault has a shape a machine can see without knowing any language:

    a plural `one` variation that still carries the count specifier

`one` is the case that fires at a count of one, and a string that prints the
count there prints a numeral where the rule asks for a word. What that word is
in Norwegian is not this file's business.

## Where `one` is not exactly one

The trap, and the reason two keys below are exceptions rather than fixes.
CLDR's `one` is a category, not the number 1. In French it covers **0 and 1**;
in Russian it covers 1, 21, 31 and so on. So writing the word into `one` is
right only where the string can never be shown at any other number in that
category — and for the note counter, which reaches nought every time somebody
fills the note, it is not. That one chooses its singular in Swift instead, which
is why `One character left` exists as a key with no number in it.
"""

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
CATALOGUE = ROOT / "App/PeaceGarden/Resources/Localizable.xcstrings"

# Anything that prints the count.
SPECIFIER = re.compile(r"%(?:\d+\$)?(?:lld|ld|d|u|@)")

# Keys whose `one` case never fires **at one**, with the reason. **Not a list of
# things to get round to** — a `one` that cannot arrive at one may keep its
# specifier, and putting a word there would be dead text nobody can check. Note
# the distinction: the case may still fire, at a number that is not one, and
# then a numeral is exactly what the rule asks for.
NOT_AT_ONE = {
    # The two day counts cannot reach one at all. The shortest tempo any genome
    # can draw is 3/24 + 0.6 + 2.0 + 1.0 days — 3.7, which rounds to 4. See
    # `Genome.Tempo` for the ranges; if they ever come down, this file starts
    # failing, which is the right thing for it to do.
    "It will open like this in %lld days": "the shortest tempo is 3.7 days",
    "When %lld days old": "the shortest tempo is 3.7 days",
    # This one is reachable at one and is taken before the catalogue sees it:
    # `EncounterNoteView` chooses `One character left` itself. What is left for
    # `one` to serve is nought, which only French's category includes — and
    # nought is a numeral by the rule, so `%lld` is right here.
    "%lld left": "one is chosen in Swift; `one` serves nought in French",
}


def main():
    catalogue = json.loads(CATALOGUE.read_text())
    found = []
    checked = 0

    for key, entry in sorted(catalogue.get("strings", {}).items()):
        for language, unit in sorted(entry.get("localizations", {}).items()):
            one = (unit.get("variations", {}).get("plural", {})
                       .get("one", {}).get("stringUnit", {}).get("value"))
            if one is None:
                continue
            checked += 1
            if not SPECIFIER.search(one):
                continue
            if key in NOT_AT_ONE:
                continue
            found.append(
                f"{key!r} [{language}]: the `one` case is {one!r}, which prints "
                "a numeral where one is a word. Either write the word — safe "
                "only where this string can never be shown at another number "
                "in this language's `one` category — or choose the singular in "
                "Swift, as `One character left` does")

    for problem in found:
        print(f"  • {problem}")
    print(f"\n{checked} plural `one` cases across the app's languages. "
          f"{len(found)} print a numeral. "
          f"{len(NOT_AT_ONE)} keys excepted because `one` cannot fire at one.")
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main())
