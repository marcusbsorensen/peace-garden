"""Take a commissioned bank all the way in.

`assemble.py` writes the file, `register.py` tells `QuoteBank` about it, xcodegen
puts it in the target and `export.py` gives the site its copy. Four steps, in
that order, every time — and at sixteen banks in a night the fourth is the one
that gets forgotten, because the app builds fine without it and only the site
notices.

    python3 tools/quotes/land.py Estonian et path/to/Estonian.swift
    python3 tools/quotes/land.py Estonian et path/to/Estonian.swift --dry-run

It stops at the first failure and says which step, because a bank that is half
landed is worse than one that is not landed at all: the app compiles, the tests
pass, and the site quietly serves eighteen languages while the app has nineteen.

**It does not write the site's strings file.** That is thirteen labels in a
language somebody has to actually know, and a tool that filled it with English
would be a tool that hides the gap. The absence is reported at the end instead;
until the file exists the site draws that language's chrome in English, silently
and per key, which is the behaviour `loadStrings` was built for.
"""

import argparse
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]


def run(label, command, dry_run):
    print(f"  {label} … ", end="", flush=True)
    if dry_run:
        print("(dry run)")
        return True
    result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
    tail = (result.stdout + result.stderr).strip().splitlines()
    if result.returncode != 0:
        print("failed")
        for line in tail[-6:]:
            print(f"      {line}")
        return False
    print(tail[-1] if tail else "done")
    return True


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("language", help="Estonian, Welsh, … — names the file and the property")
    parser.add_argument("code", help="the two-letter language code")
    parser.add_argument("halves", nargs="+", type=pathlib.Path,
                        help="the commissioned file, or its halves")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    steps = [
        ("assemble", [sys.executable, "tools/quotes/assemble.py", args.language,
                      *[str(h) for h in args.halves]]),
        ("register", [sys.executable, "tools/quotes/register.py", args.language, args.code]),
        ("xcodegen", ["xcodegen", "generate"]),
        ("export", [sys.executable, "tools/site/export.py"]),
    ]

    print(f"{args.language} ({args.code})")
    for label, command in steps:
        if not run(label, command, args.dry_run):
            sys.exit(f"\nstopped at {label}. Nothing after it has run.")

    strings = ROOT / f"Server/strings/{args.code}.json"
    print()
    if strings.exists():
        print(f"landed. {strings.relative_to(ROOT)} is already there.")
    else:
        print(f"landed — but {strings.relative_to(ROOT)} does not exist, so the site "
              f"will draw {args.language}'s chrome in English until somebody writes "
              f"the thirteen labels.")


if __name__ == "__main__":
    main()
