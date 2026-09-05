#!/usr/bin/env python3
"""
The brief for one language, with that language's own material filled in.

    python3 tools/strings/commission.py da            # the six paragraphs
    python3 tools/strings/commission.py --areas da    # the ten area names

Prints everything needed to write one commission for Danish and nothing else:
the rules, what each string has to carry, the English, and — the part that
cannot be got from anywhere else — the vocabulary Danish has already settled on
in the strings it has.

**Two commissions, and they take opposite instructions.** The six paragraphs are
a translation: every language says the same things about how the app works, and
a fluent sentence that says something else is the failure. The ten area names
are not a translation at all — they are naming, and the right answer is often
whatever that language's own gardening already calls the place. Handing a
namer the paragraph brief produces *le jardin de nœuds* where the answer is
*parterre de broderie*. Hence two briefs, two modes, and this note in both.

**The English is read from `strings.js` rather than repeated here.** It has
changed four times in one day; a second copy would be wrong by the afternoon.
The claims and the area material below are the one thing this file owns,
because they exist nowhere else in a form a translator can be handed.
"""

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
SOURCE = ROOT / "Server/assets/js/strings.js"
CATALOGUES = ROOT / "Server/strings"
BRIEF = pathlib.Path(__file__).resolve().parent / "BRIEF.md"
NAMING = pathlib.Path(__file__).resolve().parent / "NAMING.md"

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


# The ten areas, in map order, and what each is a place for.
#
# **`thirds` is the load-bearing part.** An area name has to cover a whole
# theme, and the three subthemes are what that theme actually contains — the
# heaps its thirty passages fell into when they were read, in
# `docs/NAMES-AND-THEMES.md`. Two of the ten were renamed in English on
# 5 September precisely because the name carried one third and left two.
#
# `why` says what the English name is doing, so that a namer can tell whether
# their own language's word does the same work. It is not a gloss to translate.
AREAS = {
    "areaWaiting": {
        "theme": "waiting",
        "sense": "Being held back until the time is right — and standing and "
                 "watching while it is not.",
        "thirds": [
            "Held back — dormancy, stratification, marcescence",
            "The long count — Masada dates, Beal's bottles, bamboo mast years",
            "Standing and watching — patiens, abide, the gardener's shadow",
        ],
        "why": "A cold frame is where a plant is kept until it can go out. It "
               "is all three thirds at once: held back, for a long time, under "
               "somebody's eye.",
        "note": "Several languages have no single word — Frühbeet, koudebak, "
                "drivbænk are each a compound. If yours has none, name the "
                "place a gardener would point at rather than describing the "
                "frame's construction.",
    },
    "areaGround": {
        "theme": "ground",
        "sense": "The soil itself, the place you are from, and a place "
                 "somebody keeps.",
        "thirds": [
            "The soil itself — rhizosphere, a teaspoon of earth, Darwin's worms",
            "A place you are from — querencia, Heimat, petrichor",
            "A kept place — pairidaeza, colere, garden as enclosure",
        ],
        "why": "**Renamed 5 September 2026.** It was *The Root Ground*, which "
               "carried the soil and left out the belonging — two of the three "
               "thirds. *Home ground* carries both: the earth, and the earth "
               "that is yours.",
        "note": "Most languages already have this phrase and it is what to "
                "reach for — terre natale, hjemstavn, tierra natal, родная "
                "земля. Latin *colere* means both to till and to dwell, which "
                "is the hinge the whole theme turns on; if your language has a "
                "word that does both jobs, it is the right one.",
    },
    "areaBeginnings": {
        "theme": "beginnings",
        "sense": "The first act, the small becoming large, and what a start "
                 "settles.",
        "thirds": [
            "The first act — germination, imbibition, radicle, meristem",
            "Small to large — the acorn, the coco de mer against orchid dust",
            "What a start settles — the Bramley pip, prime and primrose",
        ],
        "why": "The bed a seed is sown in. The plainest of the ten, and every "
               "gardening language has the thing.",
    },
    "areaRenewal": {
        "theme": "renewal",
        "sense": "Cutting so that it grows back, the turning year, and being "
                 "made whole.",
        "thirds": [
            "Cut and come again — coppicing, epicormic buds, the Hiroshima ginkgos",
            "The turning year — If Winter comes, spring as water",
            "Made whole — kintsugi, resurgam, anastasis, convalesce",
        ],
        "why": "Coppicing is cutting a tree to the stool so that it grows back "
               "stronger. That is the first third exactly, and the rest of the "
               "theme by extension.",
        "note": "**Cannot be translated, only renamed.** An English woodland "
                "practice; taillis, Niederwald and stævningsskov are forestry "
                "words rather than garden ones, and outside northern Europe the "
                "practice is largely absent. Name the place for what happens "
                "there — cut, and it comes again. A description is acceptable "
                "here where it is not elsewhere.",
    },
    "areaTravel": {
        "theme": "travel",
        "sense": "How a seed goes, the road, and the far off.",
        "thirds": [
            "How a seed goes — anemochory, sea beans, the dandelion's vortex",
            "The road — ad ripam, peregrinus, travel and travail",
            "Far off — Fernweh, tramontane, serendipity",
        ],
        "why": "A long walk is a real garden feature: the formal avenue you can "
               "see the end of and still have to walk. The one at Windsor is "
               "three miles.",
        "note": "Not a hike or a ramble. It is the garden's own avenue — grande "
                "allée, Lindenallee, paseo.",
    },
    "areaPeace": {
        "theme": "peace",
        "sense": "Quiet as a sound, the words for stopping, and being at ease.",
        "thirds": [
            "Quiet as a sound — psithurism, snow, the anechoic chamber",
            "The words for stopping — pax, serenus, quietus, sabbath",
            "At ease — hygge, sobremesa, shinrin-yoku",
        ],
        "why": "Plain on purpose. It is also the half of the app's own name "
               "that is not *garden*, so whatever your language uses for peace "
               "in that sense is likely to be right here too.",
    },
    "areaKinship": {
        "theme": "kinship",
        "sense": "Things grown together, the words for kin, and two people.",
        "thirds": [
            "Grown together — inosculation, grafting, lichen, mycorrhiza",
            "The words for it — sibb, God-sib, companion, kind and kin",
            "Two people — Donne, Montaigne, Hávamál, ubuntu",
        ],
        "why": "**An orchard is a family, and it names the theme three times "
               "over.** Every tree in it is a graft — two plants made one, "
               "which is the first third by meaning rather than by "
               "association. Every tree in it was *chosen* and put there, as "
               "kin and friends are kept rather than happened upon. And it "
               "bears, over years, which is what the keeping is for. Marcus's "
               "reading, 5 September 2026, and it is why the name was kept "
               "when it was questioned.",
        "note": "An orchard is not a wood. If your language distinguishes "
                "planted fruit trees from trees in general, that distinction is "
                "the whole point of the name.",
    },
    "areaPattern": {
        "theme": "pattern",
        "sense": "The counted, the fitted-together, and order named.",
        "thirds": [
            "Counted — the golden angle, Fibonacci spirals, quincunx",
            "Fitted together — tessellation, decussate leaves, Turing patterns",
            "Order named — cosmos, rhythm, ordo, the anthology",
        ],
        "why": "A knot garden is low hedging laid out in an interlaced "
               "pattern: the theme drawn in box.",
        "note": "**Cannot be translated, only renamed.** A Tudor form. French "
                "reaches for *parterre de broderie*, which is its own tradition "
                "under its own name and is the right answer rather than a "
                "compromise. Use yours — giardino all'italiana, jardín de "
                "arrayanes, chahar bagh. Where there is none, name the pattern "
                "rather than the hedge.",
    },
    "areaLight": {
        "theme": "light",
        "sense": "The edges of the day, reading the light, and light itself.",
        "thirds": [
            "The edges of the day — gloaming, alpenglow, apricity, gökotta",
            "Reading the light — photoperiodism, heliotropism, the day's eye",
            "Light itself — lux, solstice, phosphorus, the eight minutes",
        ],
        "why": "The one building in a garden that is made of light. Serre, "
               "Gewächshaus, drivhus — every gardening language has it.",
        "note": "The horticultural building, not a conservatory attached to a "
                "house.",
    },
    "areaMeeting": {
        "theme": "meeting",
        "sense": "The moment, two that need each other, and the manners of it.",
        "thirds": [
            "The moment — kairos, clinamen, ichigo ichie",
            "Two that need each other — fig and wasp, yucca moth, Ophrys",
            "The manners of it — xenia, limen, interfulgence",
        ],
        "why": "Two senses in one word: where paths cross, and crossing two "
               "plants to make a third. It is what the app does, and this is "
               "the area the whole thing is named for.",
        "note": "**Cannot be translated, only renamed.** Croisement, cruce, "
                "incrocio and krydsning hold both senses. Japanese, Korean, "
                "Chinese, Arabic, Hebrew, Finnish, Hungarian and Basque have to "
                "choose one — **keep the meeting.** A word that means only the "
                "horticultural cross is the wrong half; what happens here is "
                "two people.",
    },
}


def english():
    """The six, the thirteen and the ten, as `strings.js` has them today."""
    source = SOURCE.read_text()
    body = source[source.index("export const EN"):source.index("export const KEYS")]
    found = {}
    for match in re.finditer(r'^  (\w+):\s*\n?\s*"((?:[^"\\]|\\.)*)",', body, re.M):
        found[match.group(1)] = match.group(2).encode().decode("unicode_escape")
    return found


def settled_words(theirs, source, code, wanted):
    """What this language has already said, printed so the next job agrees.

    Both commissions open with this, because both are constrained by it and
    neither can work it out from the English. `wanted` excludes whichever set is
    being written now — printing a translator their own blank keys as
    *already chosen* would be a lie, and printing them filled in would be
    telling them the answer.
    """
    have = {k: v for k, v in theirs.items()
            if k in wanted and isinstance(v, str) and v.strip()}
    if not have:
        return
    for key, value in have.items():
        print(f"- `{key}`\n    en  {source.get(key, '?')}\n    {code}  {value}")


def prose(catalogue, code, source):
    """The six paragraphs."""
    theirs = catalogue.get("strings", {})
    print(BRIEF.read_text())
    print("=" * 78)
    print(f"\n# {catalogue['language']} — {catalogue['endonym']}  ({code})\n")
    print(f"Write into `Server/strings/{code}.json`.\n")

    # The vocabulary first, because it constrains everything after it.
    print("## The words this language has already chosen\n")
    print("Commissioned and shipping. **The six you are about to write have to")
    print("agree with them.**\n")
    settled_words(theirs, source, code,
                  [k for k in source if k not in CLAIMS and k not in AREAS])

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


def areas(catalogue, code, source):
    """The ten area names."""
    theirs = catalogue.get("strings", {})
    print(NAMING.read_text())
    print("=" * 78)
    print(f"\n# {catalogue['language']} — {catalogue['endonym']}  ({code})\n")
    print(f"Write into `Server/strings/{code}.json`.\n")

    print("## The words this language has already chosen\n")
    print("The site's own prose, commissioned and shipping. The ten names have")
    print("to sit beside these — chiefly whatever this language calls a *seed*")
    print("and a *garden*.\n")
    settled_words(theirs, source, code, [k for k in source if k not in AREAS])

    print("\n## The ten\n")
    print("In the order they are walked: the top row of the map left to right,")
    print("then the bottom row. Nothing about the map moves.\n")
    for key, area in AREAS.items():
        print(f"### `{key}`\n")
        print(f"> {source[key]}\n")
        print(f"*The place.* {area['sense']}\n")
        print("*What the theme holds, in three:*")
        for line in area["thirds"]:
            print(f"  - {line}")
        print(f"\n*What the English name is doing.* {area['why']}")
        if "note" in area:
            print(f"\n*Note.* {area['note']}")
        print()


def main():
    argv = sys.argv[1:]
    wants_areas = "--areas" in argv
    rest = [a for a in argv if a != "--areas"]
    if len(rest) != 1:
        sys.exit(f"usage: {sys.argv[0]} [--areas] <language code>")
    code = rest[0]
    path = CATALOGUES / f"{code}.json"
    if not path.exists():
        sys.exit(f"no catalogue at {path.relative_to(ROOT)}")

    catalogue = json.loads(path.read_text())
    source = english()
    (areas if wants_areas else prose)(catalogue, code, source)


if __name__ == "__main__":
    main()
