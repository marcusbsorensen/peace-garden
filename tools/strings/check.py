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
from commission import CLAIMS, english  # noqa: E402

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

        # An area name in a translated string means somebody translated the map.
        for area in ("Cold Frame", "Root Ground", "Seedbed", "Coppice",
                     "Long Walk", "Quiet Garden", "Orchard", "Knot Garden",
                     "Glasshouse", "Crossing"):
            if area.lower() in value.lower():
                found.append(f"{key}: carries the area name {area!r}. The areas "
                             "are proper nouns and stay English, but they do not "
                             "belong in this paragraph at all")

    # Vocabulary. Every one of the six says *seed* in English, and the word for
    # it was settled by the thirteen. A page that calls a seed two things is
    # worse than a page in English.
    term = TERMS.get(code)
    if term:
        for key, value in written.items():
            if "seed" in source[key].lower() and term.lower() not in value.lower():
                found.append(
                    f"{key}: says {term!r} nowhere, which is this language's own "
                    "word for a seed in the thirteen already shipping. It may be "
                    "inflected past recognition — worth an eye rather than a fix")
    return found


def main():
    source = english()
    codes = sys.argv[1:] or sorted(p.stem for p in CATALOGUES.glob("*.json"))
    total, written, clean = 0, 0, 0
    for code in codes:
        path = CATALOGUES / f"{code}.json"
        if not path.exists():
            sys.exit(f"no catalogue at {path.relative_to(ROOT)}")
        catalogue = json.loads(path.read_text())
        total += 1
        if any(isinstance(catalogue.get("strings", {}).get(k), str)
               and catalogue["strings"][k].strip() for k in CLAIMS):
            written += 1
        found = problems_for(code, catalogue, source)
        if found:
            print(f"{code}:")
            for problem in found:
                print(f"  • {problem}")
        else:
            clean += 1
    awaiting = total - written
    print(f"\n{written} of {total} catalogues have the prose"
          f"{f', {awaiting} still awaiting it' if awaiting else ''}. "
          f"{clean} clean.")
    return 0 if clean == total else 1


if __name__ == "__main__":
    sys.exit(main())
