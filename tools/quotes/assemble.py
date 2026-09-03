"""Join the halves of a commissioned bank into one `Quotes+Language.swift`.

A bank is written by two agents, five themes each, because one agent writing all
three hundred and sixty is what kept failing — twice on an API output content
filter and once on a stall. Each half is a bare list of `Passage(...)` lines with
`// MARK:` headings and no wrapper. This puts the wrapper on and checks the
result before it goes anywhere near the project.

    python3 tools/quotes/assemble.py Spanish spanish-a.swift spanish-b.swift
    python3 tools/quotes/assemble.py Spanish a.swift b.swift --check-only

It refuses to write a file that would fail `QuoteBankTests`, because finding out
at `xcodebuild` time means the broken bank is already in the target and the
build error points at Swift rather than at the passage.
"""

import argparse
import collections
import itertools
import pathlib
import re
import sys
import unicodedata

ROOT = pathlib.Path(__file__).resolve().parents[2]
VIEWS = ROOT / "App/PeaceGarden/Views"
ENTRY = re.compile(
    r'Passage\(\s*text:\s*"((?:[^"\\]|\\.)*)"\s*,\s*source:\s*"((?:[^"\\]|\\.)*)"'
    r'\s*,\s*theme:\s*\.(\w+)\s*,\s*subtheme:\s*\.(\w+)\s*\)',
    re.S,
)
FLOOR = 10
MAX_TEXT, MAX_SOURCE, MAX_OVERLAP = 240, 90, 0.5


def words(text):
    """The interesting words in a passage, as `QuoteBankTests` counts them.

    **Letters in any script, and no digits**, which is what Swift's
    `CharacterSet.letters.inverted` gives `testNoSubthemeSaysTheSameThingTwice`.
    This used to split on `[^0-9A-Za-zÀ-ÿ]+`, and both halves of that were
    wrong once the banks stopped being Latin:

    - **Cyrillic, Greek, Arabic, Hebrew and CJK all split away to nothing**, so
      every non-Latin passage produced an empty word set and the duplicate check
      quietly skipped it. A file could pass here and fail at `xcodebuild`, which
      is the one thing this module exists to prevent.
    - **Four-digit years survived**, so in a subtheme where the only surviving
      tokens were years, two passages mentioning 1861 scored a perfect overlap.

    Found by the agent writing the Ukrainian bank, which checked its own years
    by hand rather than trusting this.

    A script with no spaces gives one token per run, so for CJK this degrades to
    catching exact repeats rather than near ones. Swift does the same thing, and
    matching it is the point: this is a pre-flight check, and a pre-flight check
    that is stricter or looser than the real one is worse than none.
    """
    # A letter is `[^\W\d_]`, so anything else — the split — is `[\W\d_]`.
    return {w for w in re.split(r"[\W\d_]+", text.lower(), flags=re.UNICODE) if len(w) >= 4}


def normalise(body):
    """Give every `Passage(...)` line the trailing comma an array literal needs.

    **A missing comma is a compile error this module used to pass straight
    through.** It promises to refuse anything that would fail `QuoteBankTests`,
    and it was checking the passages while ignoring the Swift around them — so a
    bank could be declared clean here and then fail at `xcodebuild` on a syntax
    error, which is the one outcome this module exists to prevent.

    The Greenlandic bank arrived with ten of them, one at the end of each theme,
    which is exactly where a writer stops and starts a new section. Adding the
    comma is safer than reporting it: there is no case where a `Passage(...)`
    line in one of these files should *not* have one.
    """
    out = []
    for line in body.splitlines():
        stripped = line.rstrip()
        if re.match(r"^\s*Passage\(.*\)$", stripped):
            stripped += ","
        out.append(stripped)
    return "\n".join(out)


def homoglyphs(text):
    """Latin letters hiding inside a word written in another script.

    **Invisible on screen and wrong in the string.** The Macedonian bank arrived
    with thirteen of them — ten instances of `сè` typed with Latin `è` (U+00E8)
    instead of Cyrillic `ѐ` (U+0450), plus a Latin `o` and `e` inside a Cyrillic
    word that came straight out of the source wikitext as an encoding artefact.
    Nothing renders differently; the text sorts, searches and compares wrong.

    Its own agent wrote a scanner to find them, which is the sign a check belongs
    in the tool rather than in each commission. Only mixed *words* are reported:
    a Latin binomial or a product name standing alone in a Cyrillic sentence is
    ordinary and deliberate.
    """
    suspect = []
    for word in re.findall(r"[^\W\d_]+", text, flags=re.UNICODE):
        scripts = set()
        for character in word:
            name = unicodedata.name(character, "")
            for script in ("LATIN", "CYRILLIC", "GREEK", "ARABIC", "HEBREW"):
                if name.startswith(script):
                    scripts.add(script)
        if len(scripts) > 1:
            suspect.append(word)
    return suspect


def check(entries, english):
    """Everything `QuoteBankTests` will ask, asked here first."""
    problems = []
    by_subtheme = collections.defaultdict(list)
    for text, source, theme, subtheme in entries:
        by_subtheme[subtheme].append((text, source))
        if len(text) >= MAX_TEXT:
            problems.append(f"a paragraph rather than a passage: {text[:70]}…")
        if len(source) >= MAX_SOURCE:
            problems.append(f"the source is a citation: {source[:70]}…")
        if not source.strip():
            problems.append(f"no provenance: {text[:70]}…")
        for field in (text, source):
            for word in homoglyphs(field):
                problems.append(
                    f"two scripts in one word — {word!r} in: {field[:60]}…")

    seen = collections.Counter(text for text, _, _, _ in entries)
    problems += [f"carried twice: {t[:70]}…" for t, n in seen.items() if n > 1]

    for subtheme, group in by_subtheme.items():
        if len(group) < FLOOR:
            problems.append(f"{subtheme} has {len(group)}, floor is {FLOOR}")
        for (one, _), (other, _) in itertools.combinations(group, 2):
            a, b = words(one), words(other)
            if a and b and len(a & b) / len(a | b) >= MAX_OVERLAP:
                problems.append(
                    f"{subtheme} says the same thing twice:\n    {one[:70]}…\n    {other[:70]}…"
                )

    shared = seen.keys() & english
    if shared:
        problems.append(f"{len(shared)} lines shared with the English bank")
    return problems, by_subtheme


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("language", help="Dutch, Spanish, … — names the file and the property")
    parser.add_argument("halves", nargs="+", type=pathlib.Path)
    parser.add_argument("--check-only", action="store_true")
    parser.add_argument("--note", default="", help="a line for the doc comment")
    args = parser.parse_args()

    missing = [h for h in args.halves if not h.exists()]
    if missing:
        sys.exit("not written yet: " + ", ".join(str(m) for m in missing))

    body = normalise("\n".join(h.read_text().rstrip() for h in args.halves))
    entries = ENTRY.findall(body)
    if not entries:
        sys.exit("no passages found — are these the right files?")

    english = {t for t, _, _, _ in ENTRY.findall((VIEWS / "Quotes.swift").read_text())}
    problems, by_subtheme = check(entries, english)

    print(f"{len(entries)} passages across {len(by_subtheme)} subthemes, "
          f"thinnest {min(len(g) for g in by_subtheme.values())}")
    if problems:
        print(f"\n{len(problems)} problem(s):")
        for problem in problems:
            print("  •", problem)
        sys.exit(1)
    print("clean against everything QuoteBankTests will ask")

    if args.check_only:
        return

    out = VIEWS / f"Quotes+{args.language}.swift"
    note = f"\n///\n/// {args.note}" if args.note else ""
    out.write_text(
        "import Foundation\n\n"
        f"/// The {args.language} passages.\n"
        "///\n"
        "/// Written rather than translated: about sixty of the English passages\n"
        "/// are etymologies of English words and are simply false in any other\n"
        "/// language, so this bank comes from its own word histories, its own\n"
        f"/// literature and its own proverbs.{note}\n"
        "extension Quotes {\n"
        f"    static let {args.language.lower()}: [Passage] = [\n"
        f"{body}\n"
        "    ]\n"
        "}\n"
    )
    print(f"wrote {out.relative_to(ROOT)} — now run xcodegen generate")


if __name__ == "__main__":
    main()
