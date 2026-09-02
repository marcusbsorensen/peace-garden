"""Cut `Quotes.swift` down to something an agent can read.

Commissioning a passage bank means handing somebody the rules, the two enums and
enough of the existing bank to hear the register. It does not mean handing them
`Quotes.swift`, which is past two thousand lines and grows with every bank added
to it.

That distinction is not academic. The Spanish bank failed three times — twice on
an API output content filter, once on a ten-minute stall — and every one of them
died partway through reading the whole file. What worked was a two-hundred-line
brief and two agents splitting the ten themes between them.

    python3 tools/quotes/brief.py                    # writes brief to stdout
    python3 tools/quotes/brief.py --out brief.swift
    python3 tools/quotes/brief.py --counts           # what each subtheme holds

The brief carries the `Passage` struct, the shipping rules in the doc comment
above `enum Quotes`, the `Theme` and `Subtheme` enums with their notes, and one
sample passage per subtheme. It stays the same size however many banks exist,
which is the point.
"""

import argparse
import collections
import pathlib
import re
import sys

QUOTES = pathlib.Path(__file__).resolve().parents[2] / "App/PeaceGarden/Views/Quotes.swift"
ENTRY = re.compile(
    r'Passage\(\s*text:\s*"((?:[^"\\]|\\.)*)"\s*,\s*source:\s*"((?:[^"\\]|\\.)*)"'
    r'\s*,\s*theme:\s*\.(\w+)\s*,\s*subtheme:\s*\.(\w+)\s*\)',
    re.S,
)


def source(path=QUOTES):
    if not path.exists():
        sys.exit(f"no {path}")
    return path.read_text()


def entries(text):
    """Every passage as (text, source, theme, subtheme)."""
    return ENTRY.findall(text)


def counts(text):
    """How many passages each subtheme carries, in the enum's own order."""
    tally = collections.Counter(sub for _, _, _, sub in entries(text))
    block = re.search(r"enum Subtheme.*?\n\n", text, re.S)
    order, theme = [], None
    for line in (block.group(0) if block else "").splitlines():
        heading = re.match(r"\s*// (\w+)", line)
        if heading:
            theme = heading.group(1)
        cases = re.match(r"\s*case ([a-zA-Z, ]+)$", line)
        if cases:
            order += [(theme, name.strip()) for name in cases.group(1).split(",")]
    return [(theme, sub, tally[sub]) for theme, sub in order]


def brief(text):
    """The rules, the enums, and one passage per subtheme."""
    head = text[: text.index("    static let all: [Passage] = [")]
    seen = {}
    for match in ENTRY.finditer(text):
        seen.setdefault(match.group(4), " ".join(match.group(0).split()))
    sample = ",\n".join(f"        {entry}" for entry in seen.values())
    return (
        head
        + "\n// ---- one passage from each subtheme, for register ----\n"
        + "//\n"
        + "// This is an extract. The bank itself is not here on purpose: it is\n"
        + "// long enough to derail the agent reading it, and a new bank should\n"
        + "// not be written by looking at the English one anyway.\n\n"
        + sample
        + "\n"
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=pathlib.Path)
    parser.add_argument("--counts", action="store_true")
    parser.add_argument("--floor", type=int, default=12)
    parser.add_argument("--bank", type=pathlib.Path, help="a Quotes+X.swift to count instead")
    args = parser.parse_args()

    text = source(args.bank) if args.bank else source()

    if args.counts:
        rows = counts(source()) if args.bank else counts(text)
        tally = collections.Counter(sub for _, _, _, sub in entries(text))
        total = short = 0
        print(f"{'theme':<12} {'subtheme':<24} {'has':>4} {'short':>6}")
        for theme, sub, _ in rows:
            has = tally[sub]
            gap = max(0, args.floor - has)
            total += has
            short += gap
            print(f"{theme:<12} {sub:<24} {has:>4} {gap or '':>6}")
        print(f"\n{total} passages; {short} short of {args.floor} in every subtheme")
        return

    out = brief(text)
    if args.out:
        args.out.write_text(out)
        print(f"wrote {args.out}, {len(out.splitlines())} lines "
              f"(from {len(text.splitlines())})")
    else:
        sys.stdout.write(out)


if __name__ == "__main__":
    main()
