"""Write the site's passage banks and language manifest out of the app.

    python3 tools/site/export.py            # write Server/passages/ and Server/languages.json
    python3 tools/site/export.py --check    # fail if what is on disk is not what this would write

**The site adds no language of its own and commissions no bank of its own.**
`docs/WEBSITE.md` settles that, and this tool is what makes it true rather than
remembered: the banks are a build product of `QuoteBanks.swift` and the
`Quotes+*.swift` files, so a bank added to the app is a bank the site has, in the
same commit, or CI goes red.

That matters more than it sounds. Commissioning a bank twice would produce two
different Dutch banks — the passage version of exactly the drift `tools/preview/`
has, which is why `tools/reference/` exists and CI runs it. This repository has
already chosen once between generating a thing and remembering to update it. The
string catalogue that turned out to be 131 strings short is what remembering
looks like.

## What it writes

- `Server/passages/<code>.json` — one bank. Every passage carries its theme and
  its subtheme, because those are what a page has: the theme falls out of the
  lineage and the subtheme out of the plant's own genus ending, both derived and
  both language-neutral. **The reader's own bank supplies the line**, which is
  the app's rule — two people on different banks deliberately see different
  words and hold the character of the passage in common.
- `Server/languages.json` — every code the app knows, whether it has an
  interface, whether it has a bank, and what to call it in a chooser. A language
  with an interface and no bank is the normal state, not the exception: an
  interface is a fortnight and a bank is a commission. The site reads this to
  decide what to offer and, where a bank is missing, to say under the passage
  that the language was borrowed.
"""

import argparse
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
VIEWS = ROOT / "App/PeaceGarden/Views"
CATALOGUE = ROOT / "App/PeaceGarden/Resources/Localizable.xcstrings"
SERVER = ROOT / "Server"

ENTRY = re.compile(
    r'Passage\(\s*text:\s*"((?:[^"\\]|\\.)*)"\s*,\s*source:\s*"((?:[^"\\]|\\.)*)"'
    r'\s*,\s*theme:\s*\.(\w+)\s*,\s*subtheme:\s*\.(\w+)\s*\)',
    re.S,
)
CASE = re.compile(r'^\s*case (\w+) = "([\w-]+)"', re.M)
BINDING = re.compile(r"^\s*case \.(\w+): return Quotes\.(\w+)", re.M)

# What to call a language in a chooser. The endonym is what the chooser shows —
# somebody looking for their own language is looking for their own word for it —
# and the English name is for anything that has to be read by a person working
# on the site. Kept here rather than fetched, because the site is a static page
# and a chooser that needs a network call to name its options is worse than a
# table of thirty-three rows.
NAMES = {
    "en": ("English", "English"),
    "nl": ("Dutch", "Nederlands"),
    "da": ("Danish", "Dansk"),
    "fr": ("French", "Français"),
    "es": ("Spanish", "Español"),
    "nb": ("Norwegian Bokmål", "Norsk bokmål"),
    "sv": ("Swedish", "Svenska"),
    "it": ("Italian", "Italiano"),
    "de": ("German", "Deutsch"),
    "pt": ("Portuguese", "Português"),
    "tr": ("Turkish", "Türkçe"),
    "pl": ("Polish", "Polski"),
    "cs": ("Czech", "Čeština"),
    "hu": ("Hungarian", "Magyar"),
    "ro": ("Romanian", "Română"),
    "ca": ("Catalan", "Català"),
    "fi": ("Finnish", "Suomi"),
}


def unescape(text):
    """Swift's string escapes, which are the ones JSON has plus none of its own."""
    return (text.replace('\\"', '"').replace("\\\\", "\\")
                .replace("\\n", "\n").replace("\\t", "\t"))


def banks():
    """Every wired bank, as `code -> [passage]`, read out of `QuoteBanks.swift`."""
    source = (VIEWS / "QuoteBanks.swift").read_text()
    codes = dict(CASE.findall(source))              # caseName -> "nl"
    properties = dict(BINDING.findall(source))      # caseName -> "dutch"
    missing = set(codes) - set(properties)
    if missing:
        sys.exit(f"{', '.join(sorted(missing))} has a case but no bank in `passages`")

    files = {"all": VIEWS / "Quotes.swift"}
    for path in sorted(VIEWS.glob("Quotes+*.swift")):
        files[path.stem.split("+", 1)[1].lower()] = path

    out = {}
    for case, code in codes.items():
        path = files.get(properties[case])
        if path is None:
            sys.exit(f"{code} names Quotes.{properties[case]}, and no file defines it")
        out[code] = [
            {
                "text": unescape(text),
                "source": unescape(provenance),
                "theme": theme,
                "subtheme": subtheme,
            }
            for text, provenance, theme, subtheme in ENTRY.findall(path.read_text())
        ]
        if not out[code]:
            sys.exit(f"{code}: no passages found in {path.name}")
    return out


def interfaces():
    """The languages the interface itself speaks, from the string catalogue."""
    catalogue = json.loads(CATALOGUE.read_text())
    speaks = {catalogue.get("sourceLanguage", "en")}
    for entry in catalogue["strings"].values():
        speaks |= set(entry.get("localizations", {}))
    return speaks


def manifest(available, speaks):
    rows = []
    for code in sorted(set(available) | speaks):
        if code not in NAMES:
            sys.exit(f"{code} has no name in NAMES — add it before it ships")
        name, endonym = NAMES[code]
        rows.append({
            "code": code,
            "name": name,
            "endonym": endonym,
            "interface": code in speaks,
            "bank": code in available,
            "passages": len(available.get(code, [])),
        })
    return {
        "note": "Generated by tools/site/export.py. The app is the source; do not edit.",
        "languages": rows,
    }


def rendered():
    """Everything this tool would write, as `relative path -> text`."""
    available = banks()
    files = {
        f"passages/{code}.json": json.dumps(bank, ensure_ascii=False, indent=1) + "\n"
        for code, bank in available.items()
    }
    files["languages.json"] = (
        json.dumps(manifest(available, interfaces()), ensure_ascii=False, indent=1) + "\n"
    )
    return files


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true",
                        help="say what differs and exit 1, writing nothing")
    args = parser.parse_args()

    files = rendered()
    stale = [p for p in SERVER.glob("passages/*.json") if p.name not in
             {pathlib.PurePath(k).name for k in files}]

    if args.check:
        problems = [f"{path} was never generated" for path in stale]
        for relative, text in sorted(files.items()):
            path = SERVER / relative
            if not path.exists():
                problems.append(f"{relative} is missing")
            elif path.read_text() != text:
                problems.append(f"{relative} is not what the app says")
        if problems:
            print("The site and the app have come apart:")
            for problem in problems:
                print("  •", problem)
            print("\nRun `python3 tools/site/export.py` and commit what it writes.")
            sys.exit(1)
        counts = ", ".join(
            f"{pathlib.PurePath(k).stem} {json.loads(v) and len(json.loads(v))}"
            for k, v in sorted(files.items()) if k.startswith("passages/")
        )
        print(f"in step — {counts}")
        return

    for path in stale:
        path.unlink()
        print(f"removed {path.relative_to(ROOT)}, which no longer has a bank")
    for relative, text in sorted(files.items()):
        path = SERVER / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
    print(f"wrote {len(files)} files under {SERVER.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
