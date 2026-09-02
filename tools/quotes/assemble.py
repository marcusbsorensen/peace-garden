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
    return {w for w in re.split(r"[^0-9A-Za-zÀ-ÿ]+", text.lower()) if len(w) >= 4}


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

    body = "\n".join(h.read_text().rstrip() for h in args.halves)
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
