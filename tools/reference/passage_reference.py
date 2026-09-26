#!/usr/bin/env python3
"""A second implementation of the passage draw, and the invariants it must hold.

`Quotes` lives in `App/`, which has no test target and needs Xcode on a Mac, so
none of the 53 Swift tests reach it. This stands in for them the way
`derivation_reference.py` stands in for the derivation: the same rules written
again from the specification, run on every push.

It does not hard-code the theme positions or the bank. Both are read out of
`Quotes.swift`, so the reference cannot quietly drift from the app — if the two
disagree the parse fails or an invariant does, rather than this file agreeing
with a version of the app that no longer exists. The three tables a theme is
now read *through* — the twelve families, the two genus roots each is named
from, and which theme claims which root — are read out of SeedCore for the same
reason.
"""
import collections
import hashlib
import json
import os
import re
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
QUOTES = ROOT / "App" / "PeaceGarden" / "Views" / "Quotes.swift"
AMBASSADORS = Path(__file__).resolve().parent / "ambassador_vectors.json"
CORE = ROOT / "Packages" / "SeedCore" / "Sources" / "SeedCore"
ARCHETYPES_SWIFT = CORE / "Genome" / "Archetype.swift"
PLANT_NAME_SWIFT = CORE / "Genome" / "PlantName.swift"
AREAS_SWIFT = CORE / "WebGardens" / "Areas.swift"

M64 = (1 << 64) - 1
INHERIT_FIRST = 0.36   # GeneSource.inheritFirstParent
INHERIT_SECOND = 0.72  # GeneSource.inheritSecondParent
DIMENSIONS = 4

failures = []


def check(condition, message):
    if condition:
        print(f"  ok    {message}")
    else:
        print(f"  FAIL  {message}")
        failures.append(message)


# --- the app's own numbers, read rather than copied -------------------------

def load_quotes():
    source = QUOTES.read_text()

    # Declaration order is what `Theme.allCases` gives Swift, and `pick` indexes
    # straight into it, so the order here has to be the order there.
    try:
        region = source[source.index("enum Theme"):source.index("var position")]
    except ValueError:
        sys.exit("could not find the Theme cases in Quotes.swift")
    themes = []
    for line in re.findall(r"^\s*case ([a-z]+(?:\s*,\s*[a-z]+)*)\s*$", region, re.M):
        themes.extend(name.strip() for name in line.split(","))
    if not themes:
        sys.exit("found the Theme enum but no cases in it")

    # **Bounded to `var position`'s own body**, and the bound is the whole fix.
    #
    # This read `case .x: return [...]` across the entire file, which was true of
    # exactly one property when it was written. `heads` was added afterwards, in
    # the same shape and four lines below — `case .beginnings: return ["Thal",
    # "Lir", "Ver"]` — and the tool then tried to read a genus syllable as a
    # coordinate and died on it. CI has been red since, saying only that "Thal"
    # is not a float.
    #
    # Requiring numbers as well as bounding the region, because a second
    # numeric property under `Theme` would otherwise reintroduce this quietly.
    try:
        body = source[source.index("var position"):]
        body = body[:body.index("\n        }") + 1]
    except ValueError:
        sys.exit("could not find the body of `var position` in Quotes.swift")

    positions = {}
    for name, values in re.findall(
        r"case \.(\w+):\s*return \[([\d.,\s]+)\]", body
    ):
        positions[name] = [float(v) for v in values.split(",")]
    if not positions:
        sys.exit("found `var position` and no coordinates in it")

    # `subtheme: .theFirstAct` ends in `theme: .theFirstAct`, so without the
    # lookbehind every passage is counted twice — once under its theme and once
    # under a subtheme name that is not a theme at all. It reported 738 passages
    # for a bank of 369 and failed *every passage's theme is a real theme*,
    # which is the one line in this output that sounds like a content problem
    # and was a regex.
    bank = collections.Counter(re.findall(r"(?<!sub)theme: \.(\w+)", source))
    return themes, positions, bank


def region(path, opening, closing, what):
    """The text from `opening` to the first `closing` after it.

    Bounded for the reason `var position` above is bounded: a pattern let loose
    on a whole Swift file reads whatever else happens to be written in the same
    shape, and a table of syllables is written in the shape of a table of
    coordinates.
    """
    source = path.read_text()
    try:
        start = source.index(opening)
    except ValueError:
        sys.exit(f"could not find {what} in {path.name}")
    rest = source[start:]
    try:
        return rest[:rest.index(closing) + len(closing)]
    except ValueError:
        sys.exit(f"could not find the end of {what} in {path.name}")


def load_names():
    """The tables a plant's theme is read through, out of SeedCore.

    A theme is not a draw of its own any more. It is the sense of the syllable
    the genus begins with, and the genus is read off the flower — so this needs
    what `PlantName` needs: the twelve families in `allCases` order, the two
    roots each of them is named from, and which theme claims which root.

    Read rather than written out again, for the reason the positions and the
    bank are read. Three copies here would agree with the app until the day one
    of them was tuned, and this file exists to notice that day.
    """
    # Declaration order is `Archetype.allCases`, which `pick` indexes straight
    # into. Bounded to the cases because `displayName` further down is a second
    # switch in almost the same shape — `case .spire: return "Spire"`.
    cases = region(ARCHETYPES_SWIFT, "enum Archetype", "public var familyName",
                   "the Archetype cases")
    archetypes = re.findall(r"^\s*case (\w+)[ \t]*(?://.*)?$", cases, re.M)
    if not archetypes:
        sys.exit("found the Archetype enum but no cases in it")

    # `PlantName.roots`: each family's two roots, the low merosity first.
    table = region(PLANT_NAME_SWIFT, "static let roots", "\n    ]",
                   "`PlantName.roots`")
    roots = {
        family: {"few": few, "many": many}
        for family, few, many in re.findall(
            r'\.(\w+):\s*\(few: "(\w+)",\s*many: "(\w+)"\)', table
        )
    }
    if not roots:
        sys.exit("found `PlantName.roots` and no roots in it")

    # The frozen twenty-four. Named here only so the two tables below can be
    # held to it: `GeneSource.pick` indexes by `unit * count`, so a syllable
    # added to this list renames every plant on every phone.
    listed = region(PLANT_NAME_SWIFT, "public static let genusHeads", "\n    ]",
                    "`PlantName.genusHeads`")
    frozen = re.findall(r'"(\w+)"', listed)
    if not frozen:
        sys.exit("found `PlantName.genusHeads` and no syllables in it")

    # **`Area.genusHeads`, not `Quotes.Theme.genusHeads`**, which is this table
    # read through `Theme.init(area:)` — a switch over both tens, so the area a
    # syllable names is the theme it names. The app's own copy moved to the core
    # on 20 September because the website has to file a plant into an area and
    # the website is SeedCore compiled to wasm rather than the app.
    claims = region(AREAS_SWIFT, "public var genusHeads", "\n        }",
                    "`Area.genusHeads`")
    theme_of_head = {}
    for theme, heads in re.findall(r"case \.(\w+):\s*return \[([^\]]*)\]", claims):
        for head in re.findall(r'"(\w+)"', heads):
            # First claim wins, as `Area.allCases.first { ... }` has it.
            theme_of_head.setdefault(head, theme)
    if not theme_of_head:
        sys.exit("found `Area.genusHeads` and no syllables in it")

    return archetypes, roots, frozen, theme_of_head


THEMES, POSITION, BANK = load_quotes()
ARCHETYPES, ROOTS, FROZEN_HEADS, THEME_OF_HEAD = load_names()


# --- the derivation ---------------------------------------------------------

def seed_digest(domain, *parts):
    hasher = hashlib.sha256()
    hasher.update(domain.encode())
    hasher.update(b"\x00")
    for part in parts:
        hasher.update(struct.pack(">I", len(part)))
        hasher.update(part)
    return hasher.digest()


def mix64(value):
    value &= M64
    value ^= value >> 30
    value = (value * 0xBF58476D1CE4E5B9) & M64
    value ^= value >> 27
    value = (value * 0x94D049BB133111EB) & M64
    value ^= value >> 31
    return value


def unit(digest):
    return (mix64(int.from_bytes(digest[:8], "big")) >> 11) * (2.0 ** -53)


def pair_id(one, other):
    low, high = sorted((one, other))
    return seed_digest("peacegarden.pair.v1", low, high)


def pair_unit(one, other, label):
    return unit(seed_digest("peacegarden.pair.v1", pair_id(one, other), label.encode()))


def trait_unit(seed, label):
    """One named draw off a minted seed: `GeneSource.primary(_:).unit(_:)`.

    Minted, so there is no inheritance ladder here. `Quotes.theme(of:)` builds
    its genome with `lineage: .minted` whichever seed it is handed, and the only
    seeds it is ever handed are people's own.
    """
    return unit(seed_digest("peacegarden.trait.v1", seed, label.encode()))


def genus_head(seed):
    """The syllable the plant this seed mints is named from.

    **The head is read off the flower rather than drawn**, which is why there is
    no label for it: `PlantName.genusHead(for:_:)` takes the family and the
    merosity — the two floral facts a genus is separated on — and looks the root
    up. Both of those were already in every seed ever minted, as
    `form.archetype` and `bloom.merosity`.

    A family missing from the root table raises, as it does there: a fallback
    would rename a twelfth of every garden in silence.
    """
    index = int(trait_unit(seed, "form.archetype") * len(ARCHETYPES))
    archetype = ARCHETYPES[min(len(ARCHETYPES) - 1, index)]
    # `chance(_:0.5)`, and true is the high merosity.
    merosity = "many" if trait_unit(seed, "bloom.merosity") < 0.5 else "few"
    return ROOTS[archetype][merosity]


def theme_of(seed):
    """The theme a seed carries on its own, read off its plant's genus head.

    **This was its own draw until 1 September 2026** — `passage.theme.v1`, a
    trait beside the plant rather than a reading of it, so *Nyxia* was as likely
    to be a Travel plant as a Waiting one and nothing anybody could see would
    say otherwise. It is now the sense of the syllable the genus already begins
    with, which is the whole point of the change: the name and the theme are one
    fact said twice.

    No tag moved to do it. `form.archetype` and `bloom.merosity` are draws every
    seed already made, and `passage.theme.v1` is simply never asked again —
    which is what makes the change safe, since a theme is never stored, only
    derived. See docs/NAMES-AND-THEMES.md.

    An unclaimed syllable falls back to the first theme, as `Area(genusHead:)`
    falls back to `.beginnings`. It cannot happen while *every frozen syllable is
    claimed by one theme* holds below, and that check is the guard — this is here
    so a broken table reads as one failure rather than as a traceback.
    """
    return THEME_OF_HEAD.get(genus_head(seed), THEMES[0])


def between(one, other, axis):
    midpoint = (POSITION[one][axis] + POSITION[other][axis]) / 2
    centre = [(POSITION[one][i] + POSITION[other][i]) / 2 for i in range(DIMENSIONS)]
    pool = [t for t in THEMES if t not in (one, other)]
    return min(pool, key=lambda t: (
        abs(POSITION[t][axis] - midpoint),
        sum((POSITION[t][i] - centre[i]) ** 2 for i in range(DIMENSIONS)),
    ))


def shared_theme(one, other):
    mine, theirs = theme_of(one), theme_of(other)
    roll = pair_unit(one, other, "passage.theme.inherit.v1")
    if roll < INHERIT_FIRST:
        return mine
    if roll < INHERIT_SECOND:
        return theirs
    axis_roll = pair_unit(one, other, "passage.theme.axis.v1")
    return between(mine, theirs, min(DIMENSIONS - 1, int(axis_roll * DIMENSIONS)))


def fold(data):
    hashed = 0xCBF29CE484222325
    for byte in data:
        hashed ^= byte
        hashed = (hashed * 0x00000100000001B3) & M64
    return hashed


def child_seed(one, other):
    low_seed, high_seed = sorted((one, other))
    low_nonce, high_nonce = sorted((os.urandom(16), os.urandom(16)))
    encounter = seed_digest(
        "peacegarden.encounter.v1", low_seed, high_seed, low_nonce, high_nonce
    )
    return seed_digest("peacegarden.cross.v1", low_seed, high_seed, encounter)


# --- what must be true ------------------------------------------------------

print(f"Read {len(THEMES)} themes and {sum(BANK.values())} passages from Quotes.swift\n")

print("The map")
check(len(THEMES) == len(POSITION), f"every theme has a position ({len(POSITION)}/{len(THEMES)})")
check(all(len(p) == DIMENSIONS for p in POSITION.values()),
      f"every position has {DIMENSIONS} dimensions")
check(all(0.0 <= v <= 1.0 for p in POSITION.values() for v in p),
      "every score is within 0...1")
check(len(set(map(tuple, POSITION.values()))) == len(POSITION),
      "no two themes sit at the same point")

# The website keeps a copy of the positions, for the plant panel on an area
# page, which draws a crossed plant's passage from its parents' shared theme as
# the app does at the meeting. Read out of `passages.js` the way the app's are
# read out of `Quotes.swift`, and held to them, order included: a tie in
# `between` goes to the first theme in `allCases` order.
PAGE = ROOT / "Server" / "assets" / "js" / "passages.js"
page_source = PAGE.read_text()
try:
    region = page_source[page_source.index("const POSITIONS"):]
    region = region[:region.index("});")]
except ValueError:
    sys.exit("could not find `POSITIONS` in passages.js")
page_positions = {
    name: [float(v) for v in values.split(",")]
    for name, values in re.findall(r"^\s*(\w+): \[([\d.,\s]+)\]", region, re.M)
}
check(list(page_positions) == THEMES and all(page_positions[t] == POSITION[t] for t in THEMES),
      "passages.js has the app's positions, in the app's order")
check(f"INHERIT_FIRST = {INHERIT_FIRST};" in page_source and f"INHERIT_SECOND = {INHERIT_SECOND};" in page_source,
      "passages.js has GeneSource's two inheritance odds")

# The syllables, which is what a theme is now read from. `theme_of` is total
# only while these hold: every root the draw can reach has to be claimed, and
# claimed once, or a plant would have a name and no theme.
print("\nThe names")
check(sorted(THEME_OF_HEAD) == sorted(FROZEN_HEADS),
      f"every frozen syllable is claimed by one theme ({len(THEME_OF_HEAD)}/{len(FROZEN_HEADS)})")
check(set(THEME_OF_HEAD.values()) == set(THEMES),
      "every theme is named by at least one syllable")
rooted = sorted(pair[merosity] for pair in ROOTS.values() for merosity in ("few", "many"))
check(rooted == sorted(FROZEN_HEADS),
      f"the {len(ARCHETYPES)} families' roots are the frozen syllables, once each")

# **Ten plants SeedCore actually grew**, and the one check here that holds this
# file to the app's own answer rather than to a second reading of the app's
# tables. `ambassador_vectors.json` is recorded by `AmbassadorTests` and pinned
# by it, and what that test says about tolerance is why this works: a grown
# height is allowed a hundredth of a millimetre and *the seeds, the names and the
# genus heads are exact*.
#
# It is here because its absence is what let `theme_of` drift. Every invariant
# below is a property of the *shape* of the draw rather than of the draw itself,
# and `passage.theme.v1` had that shape too — reachable, never empty, steady
# across a pair's meetings. So nothing went red from 1 September, when the app
# stopped asking for that tag, until this was noticed.
vectors = json.loads(AMBASSADORS.read_text())["ambassadors"]
wrong = {
    row["area"]: f'{genus_head(bytes.fromhex(row["seed"]))} for {row["genusHead"]}'
    for row in vectors
    if genus_head(bytes.fromhex(row["seed"])) != row["genusHead"]
}
check(not wrong,
      f"the {len(vectors)} ambassadors mint the syllables SeedCore recorded"
      f"{'' if not wrong else f' (off: {wrong})'}")
check(all(theme_of(bytes.fromhex(row["seed"])) == row["area"] for row in vectors),
      "and each one's theme is the area SeedCore stands it in")
check(all(row["name"].startswith(row["genusHead"]) for row in vectors),
      "and each one's written genus begins with it")

print("\nThe bank")
check(set(BANK) == set(THEMES), "every passage's theme is a real theme")
empty = [t for t in THEMES if not BANK[t]]
check(not empty, f"no theme is empty{'' if not empty else f' (empty: {empty})'}")
for theme in THEMES:
    marker = "" if BANK[theme] >= 30 else f"  <- wants {30 - BANK[theme]} more"
    print(f"        {theme:<11} {BANK[theme]:>3}{marker}")

print("\nThe draw")
people = [os.urandom(32) for _ in range(24000)]
own = collections.Counter(theme_of(p) for p in people)
check(len(own) == len(THEMES), "every theme is reachable as a person's own")

# **Not even, and not meant to be.** This line read *a person's theme is roughly
# even* while the theme was a draw of its own, and that claim died with the
# draw: four themes take three of the twenty-four syllables and six take two, so
# a person is half again as likely to be born to Beginnings as to Peace — 12.5%
# against 8.3%. docs/NAMES-AND-THEMES.md records the unevenness rather than
# correcting it, because both corrections cost more than it does: renaming every
# plant that exists, or weighting the draw, and a weighted draw would break the
# one thing the design is for.
#
# So the invariant is the ratio the syllables give rather than evenness, which
# is also the check that would have caught this file's drift — a theme drawn
# flat comes out 20% under on a three-syllable theme, and the tolerance is 15%.
# It wants the larger sample to earn that: 24000 puts the tightest theme seven
# standard deviations inside the bound, where 3000 put it two and a half.
HEADS_PER_THEME = collections.Counter(THEME_OF_HEAD.values())
TOLERANCE = 0.15
skewed = {}
for theme in THEMES:
    expected = len(people) * HEADS_PER_THEME[theme] / len(FROZEN_HEADS)
    if abs(own[theme] / expected - 1) > TOLERANCE:
        skewed[theme] = f"{own[theme]} for {expected:.0f}"
check(not skewed,
      "a person's theme follows the syllable counts, within "
      f"{TOLERANCE:.0%}{'' if not skewed else f' (off: {skewed})'}")

pairs = [(os.urandom(32), os.urandom(32)) for _ in range(6000)]
shared = collections.Counter(shared_theme(a, b) for a, b in pairs)
check(len(shared) == len(THEMES), "every theme is reachable as a shared theme")
# Held against an even share rather than against each other, for the reason
# above and one more: a shared theme's own share is the syllable counts put
# through `between`, so there is no closed form to hold it to. Half an even
# share to double one is what *swallows the space* means, and the widest the
# blend actually runs is 0.077 to 0.135.
even = len(pairs) / len(THEMES)
check(all(0.5 * even <= shared[t] <= 2 * even for t in THEMES),
      f"no theme swallows the space ({min(shared.values())}-{max(shared.values())} of {len(pairs)}, "
      f"an even share being {even:.0f})")

one, other = os.urandom(32), os.urandom(32)
check(len({shared_theme(one, other) for _ in range(200)}) == 1,
      "a pair's theme does not move across 200 meetings")
check(len({child_seed(one, other) for _ in range(200)}) == 200,
      "every meeting of that pair has its own child seed")

reached = collections.defaultdict(set)
for _ in range(20000):
    a, b = os.urandom(32), os.urandom(32)
    theme = shared_theme(a, b)
    reached[theme].add(fold(child_seed(a, b)) % BANK[theme])
unreachable = {t: BANK[t] - len(reached[t]) for t in THEMES if len(reached[t]) < BANK[t]}
check(not unreachable, f"every passage can be drawn{'' if not unreachable else f' (missed: {unreachable})'}")

print()
if failures:
    print(f"{len(failures)} invariant(s) failed")
    sys.exit(1)
print("All invariants hold.")
