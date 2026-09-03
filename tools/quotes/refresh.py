"""Re-assemble every landed bank from its commissioned file, and say what moved.

**A file reaching 360 lines is not a finished bank.** Banks were landed overnight
by watching their length rather than by waiting for the agent that wrote them to
report, and two of them were mid-revision when they were taken. Welsh differed in
seventy-one passages and the early draft carried real errors — a proverb about a
tight barn with the wrong spelling, a non-word, hydrology backwards, slack water
called monthly when it is twice daily. Basque was mid-revision too.

    python3 tools/quotes/refresh.py <directory of Language.swift files>

Run it after every commissioning report has come in, and again before merging.
Anything it reports as changed was landed early; anything it reports as missing
was never commissioned or its file is gone.

It rewrites in place rather than reporting and stopping, because `assemble.py`
refuses anything that would fail the tests — so a rewrite is either a no-op or a
correction, and there is no third outcome worth pausing for. Run the tests and
the export afterwards.

It only touches banks that are already registered, so it cannot land something
new by accident — that is `land.py`'s job and it involves decisions this does not
make.
"""

import argparse
import hashlib
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
VIEWS = ROOT / "App/PeaceGarden/Views"
BANKS = ROOT / "App/PeaceGarden/Views/QuoteBanks.swift"


def registered():
    """`Slovene` -> `sl`, for every bank the app knows about."""
    text = BANKS.read_text()
    out = {}
    for name, code in re.findall(r'^\s*case (\w+) = "(\w{2})"$', text, re.M):
        out[name[0].upper() + name[1:]] = code
    return out


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("directory", type=pathlib.Path,
                        help="where the commissioned <Language>.swift files are")
    args = parser.parse_args()

    moved, missing, same = [], [], []
    for language, code in sorted(registered().items()):
        if language == "English":
            continue
        source = args.directory / f"{language}.swift"
        landed = VIEWS / f"Quotes+{language}.swift"
        if not source.exists():
            missing.append(language)
            continue
        before = digest(landed)
        result = subprocess.run(
            [sys.executable, "tools/quotes/assemble.py", language, str(source)],
            cwd=ROOT, capture_output=True, text=True)
        if result.returncode != 0:
            moved.append(f"{language} FAILED: {(result.stdout + result.stderr).strip().splitlines()[-1]}")
            continue
        after = digest(landed)
        if before != after:
            moved.append(language)
        else:
            same.append(language)

    print(f"{len(same)} unchanged")
    if missing:
        print(f"{len(missing)} with no commissioned file here: {', '.join(missing)}")
    if moved:
        print(f"\n{len(moved)} CHANGED — these were landed before their agent finished:")
        for language in moved:
            print(f"  {language}")
        print("\nRun the tests and the export, then commit.")
    else:
        print("\nNothing moved. Every landed bank matches its commissioned file.")


if __name__ == "__main__":
    main()
