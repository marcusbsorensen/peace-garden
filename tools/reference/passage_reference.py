#!/usr/bin/env python3
"""A second implementation of the passage draw, and the invariants it must hold.

`Quotes` lives in `App/`, which has no test target and needs Xcode on a Mac, so
none of the 53 Swift tests reach it. This stands in for them the way
`derivation_reference.py` stands in for the derivation: the same rules written
again from the specification, run on every push.

It does not hard-code the theme positions or the bank. Both are read out of
`Quotes.swift`, so the reference cannot quietly drift from the app — if the two
disagree the parse fails or an invariant does, rather than this file agreeing
with a version of the app that no longer exists.
"""
import collections
import hashlib
import os
import re
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
QUOTES = ROOT / "App" / "PeaceGarden" / "Views" / "Quotes.swift"

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

    positions = {}
    for name, values in re.findall(
        r"case \.(\w+):\s*return \[([^\]]+)\]", source
    ):
        positions[name] = [float(v) for v in values.split(",")]

    bank = collections.Counter(re.findall(r"theme: \.(\w+)", source))
    return themes, positions, bank


THEMES, POSITION, BANK = load_quotes()


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


def theme_of(seed):
    value = unit(seed_digest("peacegarden.trait.v1", seed, b"passage.theme.v1"))
    return THEMES[min(len(THEMES) - 1, int(value * len(THEMES)))]


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

print("\nThe bank")
check(set(BANK) == set(THEMES), "every passage's theme is a real theme")
empty = [t for t in THEMES if not BANK[t]]
check(not empty, f"no theme is empty{'' if not empty else f' (empty: {empty})'}")
for theme in THEMES:
    marker = "" if BANK[theme] >= 30 else f"  <- wants {30 - BANK[theme]} more"
    print(f"        {theme:<11} {BANK[theme]:>3}{marker}")

print("\nThe draw")
people = [os.urandom(32) for _ in range(3000)]
own = collections.Counter(theme_of(p) for p in people)
check(len(own) == len(THEMES), "every theme is reachable as a person's own")
check(max(own.values()) < 2 * min(own.values()),
      f"a person's theme is roughly even ({min(own.values())}-{max(own.values())} of {len(people)})")

pairs = [(os.urandom(32), os.urandom(32)) for _ in range(6000)]
shared = collections.Counter(shared_theme(a, b) for a, b in pairs)
check(len(shared) == len(THEMES), "every theme is reachable as a shared theme")
check(max(shared.values()) < 2 * min(shared.values()),
      f"no theme swallows the space ({min(shared.values())}-{max(shared.values())} of {len(pairs)})")

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
