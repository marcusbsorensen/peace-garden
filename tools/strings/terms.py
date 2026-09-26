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

**And, where one form of the word is not enough, the others.** `check.py` looks
for the word inside a sentence by asking for the first four characters of it,
which is enough for a language that only adds an ending and decides the
grammatical number for one that changes the head — Italian's plural is *semi*,
Maltese's *żrieragħ*. `BY_HAND` carries those forms, `terms.json` carries them
as `forms` beside `seed`, and any one of them satisfies the check.

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
# **A list of forms rather than one word, since 26 September 2026.** The first is
# the word as the termbase names it, and `terms.json`'s `seed` is read off it —
# that is the whole of what this table did before. The rest are the other forms
# the same word takes, and they are here for `check.py`, which looks for the word
# inside a sentence by asking for the first four characters of it. Four
# characters is enough for a language that only adds an ending, and it decides
# the grammatical number for a language that changes the head: the privacy round
# of 26 September had six languages write a singular, or a periphrasis, because
# the plural they would have reached for first had nothing of those four
# characters left in it. **A form listed here is matched as it is written**, and
# any one of them satisfies the rule.
#
# It is still a termbase and not a grammar. What belongs here is another form of
# the word this language settled on; another *word* for a seed does not, and the
# rule exists to catch exactly that.
#
# `ko`: the four share `습니다`, which is how a Korean sentence politely ends. It
#       is three characters against 씨앗's two, so length loses. The only entry
#       here that corrects the extraction rather than adding a form.
# `ar`: `بذرة` is the word; `بذر` is what its endings leave, in `بذرتها` and the
#       dual `بذرتَي`; and the plural `بذور` breaks the pattern outright.
# `cy`: the plural of `hedyn` is `hadau`, which shares nothing with it. Neither
#       `hed` nor `had` will do as a stem instead — `rhedeg` and `chadw` are
#       both in `cy.json` already, and either would pass a page that never says
#       seed at all.
# `ga`: not a plural but lenition, which puts an `h` after the first letter, so
#       `do shíolta` is the natural *your seeds* and has no `síol` in it. The
#       genitive singular `síl` is left out on purpose: `síl` is also the verb
#       *think*, and a check that accepts `sílim` has stopped checking.
# `it`: the plural is `semi`.
# `mk`: the plural is `семиња` and its definite `семињата`, so the form here is
#       the `семињ` both of them start with.
# `mt`: the broken plural of `żerriegħa` is `żrieragħ`.
# `ro`: the plural is `semințe` and its definite `semințele`, so the form here is
#       `seminț`. `sămânț` does the same for the singular and its `sămânța`.
BY_HAND = {
    "ko": ["씨앗"],
    "ar": ["بذرة", "بذر", "بذور"],
    "cy": ["hedyn", "hadau"],
    "ga": ["síol", "shíol"],
    "it": ["seme", "semi"],
    "mk": ["семе", "семињ"],
    "mt": ["żerriegħa", "żrieragħ"],
    "ro": ["sămânț", "seminț"],
}


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
    table = {code: BY_HAND[code][0] if code in BY_HAND else term
             for code, term in found.items()}
    forms = {code: BY_HAND[code] for code in found if code in BY_HAND}
    if "--write" in sys.argv:
        TERMS.write_text(json.dumps(
            {"note": "The word for `seed`, read off the commissioned strings by "
                     "tools/strings/terms.py, and under `forms` the other forms "
                     "of it a language uses, where the first four characters of "
                     "the word are not enough for check.py to find it. "
                     "Regenerate with --write; correct by hand in BY_HAND "
                     "there, not here.",
             "seed": dict(sorted(table.items())),
             "forms": dict(sorted(forms.items()))},
            ensure_ascii=False, indent=1) + "\n")
        print(f"wrote {TERMS.relative_to(ROOT)} — {len(table)} languages, "
              f"{len(forms)} of them with their forms by hand")
        return 0
    for code, term in sorted(table.items()):
        mark = (f"  (by hand: {', '.join(forms[code])})" if code in forms
                else "")
        print(f"{code:>3}  {term}{mark}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
