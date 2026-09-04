#!/usr/bin/env python3
"""
The brief for one language, with that language's own material filled in.

    python3 tools/strings/commission.py da

Prints everything needed to write the six strings for Danish and nothing else:
the rules, the claims each sentence has to carry, the English, and — the part
that cannot be got from anywhere else — the vocabulary Danish has already
settled on in the thirteen strings it has.

**The English is read from `strings.js` rather than repeated here.** It has
changed four times in one day; a second copy would be wrong by the afternoon.
The claims below are the one thing this file owns, because they exist nowhere
else in a form a translator can be handed.
"""

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
SOURCE = ROOT / "Server/assets/js/strings.js"
CATALOGUES = ROOT / "Server/strings"
BRIEF = pathlib.Path(__file__).resolve().parent / "BRIEF.md"

# The six, and what each one has to be true about.
#
# **`must not` is the useful half.** Every line in it is the fluent, obvious
# sentence that says the wrong thing — which is how the English got one wrong for
# weeks. A translator who reads only the source will write exactly these.
CLAIMS = {
    "tagline": {
        "seen": "Under the mark, on the page somebody reaches with no seed.",
        "must": [
            "A plant comes out of a meeting between two people.",
        ],
        "must not": [
            "Be a slogan or a call to action. It is a name for the thing, not a "
            "sentence about it — closer to a book's subtitle than to an advert.",
        ],
    },
    "about1": {
        "seen": "First paragraph, on the page with no seed.",
        "must": [
            "The app makes a plant out of two people meeting.",
            "Two phones hand each other a seed.",
            "What grows carries features of both seeds.",
            "It opens over real days, at its own pace.",
        ],
        "must not": [
            "Say the plant is an average or a blend of two plants. Traits come "
            "from one parent or the other, and a few belong to neither.",
            "Lose the last sentence. A reader who expects a finished picture "
            "reads a seedling as a failure, and this is the only place the site "
            "says a plant takes weeks.",
        ],
        "note": "The two similes — a handshake, a shared garden — are Marcus's, "
                "and the point of them is that they are things a reader has "
                "already done. If a handshake carries something else where you "
                "are, find the nearest ordinary thing two people do together on "
                "meeting, and say so in your notes.",
    },
    "about2": {
        "seen": "Second paragraph, on the page with no seed.",
        "must": [
            "A seed can travel in a link as well as by phones touching.",
            "That is what lets it reach a phone that has never had the app.",
        ],
        "must not": [
            "Suggest the receiver has to sign up, install anything first, or "
            "have heard of Peace Garden.",
        ],
    },
    "about3": {
        "seen": "Third paragraph, on the page with no seed — and read only by "
                "somebody who has none. The seed block and this block are "
                "mutually exclusive, so this reader typed the address or "
                "followed a link that lost its seed on the way.",
        "must": [
            "A seed reaches you from a person you meet, face to face.",
            "Peace Garden exists, on iPhone and iPad.",
        ],
        "must not": [
            "Imply a seed can be got from the website, downloaded, or asked "
            "for. It cannot. That is the whole point of the sentence.",
            "Say the app is coming or being made. It is out.",
        ],
    },
    "growBody": {
        "seen": "Under *Growing it*, on the page that does have a seed in it.",
        "must": [
            "The app crosses this seed with one of the reader's own.",
            "The plant that comes of the pair is theirs to keep.",
            "This meeting grows one plant, and both people have that one.",
            "It stays the same plant for as long as they have it.",
        ],
        "must not": [
            "Say, or imply, that the same two seeds always make the same "
            "plant. **This is the one that was wrong in English for weeks.** "
            "Both sides contribute a random nonce, so meeting the same person "
            "again grows a different plant, and neither of them can steer it.",
            "Imply the link can be opened twice to get the same plant back. A "
            "fresh nonce each time means it cannot.",
        ],
    },
    "appNote": {
        "seen": "The quiet line under growBody, on the page with a seed.",
        "must": [
            "Peace Garden is on iPhone and iPad.",
            "The link keeps, so there is no hurry.",
        ],
        "must not": [
            "Give the link an expiry, or suggest acting quickly.",
            "Say the app is coming. It is out.",
        ],
        "note": "Its first sentence is the same claim as about3's second. The "
                "two are never on screen together, so they may be worded alike "
                "or differently as your language prefers.",
    },
}


def english():
    """The six, and the thirteen, as `strings.js` has them today."""
    source = SOURCE.read_text()
    body = source[source.index("export const EN"):source.index("export const KEYS")]
    found = {}
    for match in re.finditer(r'^  (\w+):\s*\n?\s*"((?:[^"\\]|\\.)*)",', body, re.M):
        found[match.group(1)] = match.group(2).encode().decode("unicode_escape")
    return found


def main():
    if len(sys.argv) != 2:
        sys.exit(f"usage: {sys.argv[0]} <language code>")
    code = sys.argv[1]
    path = CATALOGUES / f"{code}.json"
    if not path.exists():
        sys.exit(f"no catalogue at {path.relative_to(ROOT)}")

    catalogue = json.loads(path.read_text())
    theirs = catalogue.get("strings", {})
    source = english()

    print(BRIEF.read_text())
    print("=" * 78)
    print(f"\n# {catalogue['language']} — {catalogue['endonym']}  ({code})\n")
    print(f"Write into `Server/strings/{code}.json`.\n")

    # The vocabulary first, because it constrains everything after it.
    settled = {k: v for k, v in theirs.items() if isinstance(v, str) and v.strip()}
    print("## The words this language has already chosen\n")
    print("These thirteen are commissioned and shipping. **The six you are about")
    print("to write have to agree with them.**\n")
    for key, value in settled.items():
        print(f"- `{key}`\n    en  {source.get(key, '?')}\n    {code}  {value}")

    print("\n## The six\n")
    for key, claim in CLAIMS.items():
        print(f"### `{key}`\n")
        print(f"> {source[key]}\n")
        print(f"*Where it is seen.* {claim['seen']}\n")
        print("*It must say:*")
        for line in claim["must"]:
            print(f"  - {line}")
        print("\n*It must not:*")
        for line in claim["must not"]:
            print(f"  - {line}")
        if "note" in claim:
            print(f"\n*Note.* {claim['note']}")
        print()


if __name__ == "__main__":
    main()
