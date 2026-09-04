#!/usr/bin/env python3
"""
The word each language settled on for *seed*, so the six can use it too.

    python3 tools/strings/terms.py            # report
    python3 tools/strings/terms.py --write    # regenerate terms.json

**Read off the commissioned strings rather than asked for.** Four of the
thirteen say *seed* in English — `seedTitle`, `notASeed`, `newerVersion` and
`damaged` — so whatever all four of a language's translations have in common is
that language's word for it, inflections trimmed off at both ends by the
matching itself. It finds `frø` in Danish, `hedyn` in Welsh, `بذرة` in Arabic
and `种子` in Chinese without being told anything about any of them.

**Where it is wrong it is wrong loudly, which is why the answer is committed.**
Korean's four strings share `습니다`, a polite verb ending, and it is longer than
the word for seed; a heuristic that scores by length cannot help but prefer it.
So the extraction seeds `terms.json` and a person fixes what it got wrong, once.
A termbase is a thing you keep, not a thing you infer on every run.

Only *seed* is done this way. *Link* was tried and dropped: two strings is not
enough for the demonstrative to wash out, so it extracted `Dieser Link` and
`Ez a hivatkozás` — phrases, which are no use for matching against a sentence
that inflects them.
"""

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
CATALOGUES = ROOT / "Server/strings"
TERMS = pathlib.Path(__file__).resolve().parent / "terms.json"

AUTHORITY = ["seedTitle", "notASeed", "newerVersion", "damaged"]

# What the extraction could not get, and what a reader of the four strings can.
#
# `ko`: the four share `습니다`, which is how a Korean sentence politely ends. It
# is three characters against 씨앗's two, so length loses.
BY_HAND = {"ko": "씨앗"}


def common(strings):
    """The longest substring in all of them. Case-folded: Greenlandic's four
    are `Naammat`, `naammammik`, `Naammat`, `naammat`, and the capital at the
    head of a sentence is not part of the word."""
    if not strings:
        return ""
    folded = [s.lower() for s in strings]
    shortest = min(folded, key=len)
    best = ""
    for i in range(len(shortest)):
        for j in range(len(shortest), i + len(best), -1):
            piece = shortest[i:j]
            if all(piece in s for s in folded):
                best = piece
                break
    best = best.strip()
    # Spanish, Galician and Portuguese come back as `a semilla`, `a semente`:
    # the article is common to all four strings too. The word is the long half.
    return max(best.split(), key=len) if " " in best else best


def extracted():
    found = {}
    for path in sorted(CATALOGUES.glob("*.json")):
        strings = json.loads(path.read_text()).get("strings", {})
        values = [strings[k] for k in AUTHORITY
                  if isinstance(strings.get(k), str) and strings[k].strip()]
        if len(values) == len(AUTHORITY):
            found[path.stem] = common(values)
    return found


def main():
    found = extracted()
    table = {code: BY_HAND.get(code, term) for code, term in found.items()}
    if "--write" in sys.argv:
        TERMS.write_text(json.dumps(
            {"note": "The word for `seed`, read off the commissioned strings by "
                     "tools/strings/terms.py. Regenerate with --write; correct "
                     "by hand in BY_HAND there, not here.",
             "seed": dict(sorted(table.items()))},
            ensure_ascii=False, indent=1) + "\n")
        print(f"wrote {TERMS.relative_to(ROOT)} — {len(table)} languages")
        return 0
    for code, term in sorted(table.items()):
        mark = "  (by hand)" if code in BY_HAND else ""
        print(f"{code:>3}  {term}{mark}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
