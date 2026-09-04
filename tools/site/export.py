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

    # Round two. Listed ahead of their banks on purpose: this table is the one
    # thing between a finished bank and a site that will not build, and a name
    # is a five-second decision that should not be made at the end of a
    # commission. A code here with no bank costs nothing — the manifest is
    # built from the banks that exist, not from this list.
    "sl": ("Slovene", "Slovenščina"),
    "hr": ("Croatian", "Hrvatski"),
    "sk": ("Slovak", "Slovenčina"),
    "cy": ("Welsh", "Cymraeg"),
    "eu": ("Basque", "Euskara"),
    "ga": ("Irish", "Gaeilge"),
    "lt": ("Lithuanian", "Lietuvių"),
    "lv": ("Latvian", "Latviešu"),
    "et": ("Estonian", "Eesti"),
    "sq": ("Albanian", "Shqip"),
    "is": ("Icelandic", "Íslenska"),
    "gl": ("Galician", "Galego"),
    "lb": ("Luxembourgish", "Lëtzebuergesch"),
    "fo": ("Faroese", "Føroyskt"),
    "mt": ("Maltese", "Malti"),
    "kl": ("Greenlandic", "Kalaallisut"),

    # The other alphabets.
    "el": ("Greek", "Ελληνικά"),
    "ru": ("Russian", "Русский"),
    "uk": ("Ukrainian", "Українська"),
    "bg": ("Bulgarian", "Български"),
    "sr": ("Serbian", "Српски"),
    "mk": ("Macedonian", "Македонски"),
    "be": ("Belarusian", "Беларуская"),
    "ar": ("Arabic", "العربية"),
    "he": ("Hebrew", "עברית"),
    "ja": ("Japanese", "日本語"),
    "zh": ("Chinese", "中文"),
    "ko": ("Korean", "한국어"),
}

# The word for *gardener*, for the test roster. See `testers()`.
#
# **ASCII only, and that is the whole specification.** The roster exists to be
# typed and read by somebody at a GB keyboard who is checking what a page looks
# like in a language he does not speak, so `Gärtner` is written `Gaertner` and
# `garðyrkjumaður` is written `Gardyrkjumadur`. That is a transliteration for a
# keyboard, not an endonym: the endonym is two columns to the left in `NAMES`
# and is the one the chooser shows.
#
# Diacritics are stripped from Latin scripts for the same reason they are
# transliterated out of Cyrillic — `í` and `ç` are no easier to type on this
# keyboard than `и` is. German takes the `ae` convention because German has one;
# everything else simply loses the mark.
#
# Three of these words repeat — Gradinar for Bulgarian, Macedonian and Romanian,
# Zahradnik for Czech and Slovak, Gartner for Danish and Norwegian — and they are
# left repeating. They are the same word, and pretending otherwise to make a
# tidier list would be the only false thing on it. The code in front of each
# keeps the identity unique, which is all the roster needs.
GARDENERS = {
    "en": "Gardener",
    "nl": "Tuinier",
    "da": "Gartner",
    "fr": "Jardinier",
    "es": "Jardinero",
    "nb": "Gartner",
    "sv": "Tradgardsmastare",     # trädgårdsmästare
    "it": "Giardiniere",
    "de": "Gaertner",             # Gärtner
    "pt": "Jardineiro",
    "tr": "Bahcivan",             # bahçıvan
    "pl": "Ogrodnik",
    "cs": "Zahradnik",            # zahradník
    "hu": "Kertesz",              # kertész
    "ro": "Gradinar",             # grădinar
    "ca": "Jardiner",
    "fi": "Puutarhuri",

    # Round two.
    "sl": "Vrtnar",
    "hr": "Vrtlar",
    "sk": "Zahradnik",            # záhradník
    "cy": "Garddwr",
    "eu": "Lorezain",             # flower-keeper, which is the Basque for it
    "ga": "Garraiodoir",          # garraíodóir
    "lt": "Sodininkas",
    "lv": "Darznieks",            # dārznieks
    "et": "Aednik",
    "sq": "Kopshtar",
    "is": "Gardyrkjumadur",       # garðyrkjumaður
    "gl": "Xardineiro",
    "lb": "Gaertner",             # Gäertner
    "fo": "Urtagardsmadur",       # urtagarðsmaður
    "mt": "Gardinar",             # ġardinar
    # **Unverified, and the only one on this list that is.** Kalaallisut builds
    # this out of `naatsiivik`, a garden, and a suffix for one who works at a
    # thing. That is a construction rather than a word anybody has confirmed,
    # which is exactly the objection the Greenlandic bank's own agent raised
    # about its sentences — see .claude/HANDOVER.md. It needs the same reader.
    "kl": "Naatsiivilerisoq",

    # The other alphabets, transliterated by sound.
    "el": "Kipouros",             # κηπουρός
    "ru": "Sadovnik",             # садовник
    "uk": "Sadivnyk",             # садівник
    "bg": "Gradinar",             # градинар
    "sr": "Bastovan",             # баштован
    "mk": "Gradinar",             # градинар
    "be": "Sadounik",             # садоўнік
    "ar": "Bustani",              # بستاني
    "he": "Ganan",                # גנן
    "ja": "Niwashi",              # 庭師
    "zh": "Yuanding",             # 园丁
    "ko": "Jeongwonsa",           # 정원사
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


def testers(rows):
    """One test gardener per language the site knows.

    A roster rather than an account list, because the site has no accounts and
    no server to keep them on. What a tester *is* is a name and a language, and
    the language is the whole of the perspective: which labels are drawn, which
    bank supplies the passage, which way the page runs, and whether the label
    voice may be uppercased or letter-spaced. Standing in one of these is
    standing where a reader of that language stands.

    Generated here, off the same manifest rows the chooser is built from, so
    the roster cannot fall behind the languages. A language with no gardener
    stops the build exactly as a language with no endonym does — which is the
    point of putting it in this tool rather than writing the file by hand.

    The code in the identity is the **language** code, not the country: `DA`
    for Danish where a country code would say `DK`. The site is keyed on
    language codes throughout, so this way the roster and the chooser agree
    with no table between them — and several of these languages have no country
    to name. Basque, Catalan, Galician, Welsh and Arabic are the obvious ones,
    and inventing a flag for each is a decision this app should not be making.
    """
    roster = []
    for row in rows:
        code = row["code"]
        if code not in GARDENERS:
            sys.exit(f"{code} has no word for gardener in GARDENERS — add it before it ships")
        gardener = GARDENERS[code]
        roster.append({
            "code": code,
            "id": f"Test-{code.upper()}-{gardener}",
            "gardener": gardener,
            "name": row["name"],
            "endonym": row["endonym"],
        })
    return {
        "note": "Generated by tools/site/export.py. The app is the source; do not edit.",
        "testers": roster,
    }


def rendered():
    """Everything this tool would write, as `relative path -> text`."""
    available = banks()
    files = {
        f"passages/{code}.json": json.dumps(bank, ensure_ascii=False, indent=1) + "\n"
        for code, bank in available.items()
    }
    catalogue = manifest(available, interfaces())
    files["languages.json"] = json.dumps(catalogue, ensure_ascii=False, indent=1) + "\n"
    files["testers.json"] = (
        json.dumps(testers(catalogue["languages"]), ensure_ascii=False, indent=1) + "\n"
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
