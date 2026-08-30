#!/usr/bin/env python3
"""
Executable reference for the Peace Garden seed-derivation spec (v1).

The Swift implementation in Packages/SeedCore must agree with this file
byte-for-byte. Two phones that never talk to a server have to arrive at the
*same* hybrid plant from the same encounter, so every derivation here is:

  * deterministic  - no clocks, no locale, no floating point in the hash path
  * commutative    - sorting the two parents removes "who initiated"
  * domain-separated and length-prefixed - no input can impersonate another

Run this file to print the test vectors that are pasted into
Tests/SeedCoreTests/DerivationVectorTests.swift.
"""

import hashlib

MASK64 = (1 << 64) - 1

# ---------------------------------------------------------------- primitives

def digest(domain: str, *parts: bytes) -> bytes:
    """SHA-256 over a domain tag and length-prefixed parts. Returns 32 bytes."""
    h = hashlib.sha256()
    h.update(domain.encode("utf-8"))
    h.update(b"\x00")
    for p in parts:
        h.update(len(p).to_bytes(4, "big"))
        h.update(p)
    return h.digest()


def mix64(x: int) -> int:
    """SplitMix64 finaliser - the only place we do wrapping arithmetic."""
    x &= MASK64
    x ^= x >> 30
    x = (x * 0xBF58476D1CE4E5B9) & MASK64
    x ^= x >> 27
    x = (x * 0x94D049BB133111EB) & MASK64
    x ^= x >> 31
    return x


# ------------------------------------------------------------------- domains

DOMAIN_SEED = "peacegarden.seed.v1"
DOMAIN_ENCOUNTER = "peacegarden.encounter.v1"
DOMAIN_CROSS = "peacegarden.cross.v1"
DOMAIN_TRAIT = "peacegarden.trait.v1"
DOMAIN_CHECK = "peacegarden.checksum.v1"


def mint_seed(entropy: bytes) -> bytes:
    """A person's own seed: 32 bytes, minted once, never regenerated."""
    return digest(DOMAIN_SEED, entropy)


def encounter_id(seed_a: bytes, seed_b: bytes, nonce_a: bytes, nonce_b: bytes) -> bytes:
    """Identifies one meeting. Both phones compute the same value."""
    lo, hi = sorted([seed_a, seed_b])
    n_lo, n_hi = sorted([nonce_a, nonce_b])
    return digest(DOMAIN_ENCOUNTER, lo, hi, n_lo, n_hi)


def cross(seed_a: bytes, seed_b: bytes, enc_id: bytes) -> bytes:
    """The offspring seed produced by one encounter between two seeds."""
    lo, hi = sorted([seed_a, seed_b])
    return digest(DOMAIN_CROSS, lo, hi, enc_id)


def checksum(seed: bytes) -> bytes:
    """Short value the two phones compare to prove they grew the same plant."""
    return digest(DOMAIN_CHECK, seed)[:8]


# ------------------------------------------------------------- gene sampling

def gene_u64(seed: bytes, label: str) -> int:
    """Every trait is drawn by *name*, so adding traits never shifts old ones."""
    d = digest(DOMAIN_TRAIT, seed, label.encode("utf-8"))
    return mix64(int.from_bytes(d[:8], "big"))


def gene_unit(seed: bytes, label: str) -> float:
    """Uniform in [0, 1) - 53 significant bits, identical to Swift's."""
    return (gene_u64(seed, label) >> 11) * (2.0 ** -53)


# -------------------------------------------------------------- inheritance

# Thresholds are cumulative over [0,1): parent0, parent1, blend, mutation.
INHERIT_P0 = 0.36
INHERIT_P1 = 0.72
INHERIT_BLEND = 0.94


def inherit_unit(child: bytes, p0: bytes, p1: bytes, label: str) -> float:
    """
    A hybrid trait is mostly one parent's, sometimes a blend, rarely novel.
    p0/p1 must already be sorted so both phones agree which parent is which.
    """
    r = gene_unit(child, "inherit:" + label)
    if r < INHERIT_P0:
        return gene_unit(p0, label)
    if r < INHERIT_P1:
        return gene_unit(p1, label)
    if r < INHERIT_BLEND:
        a = gene_unit(p0, label)
        b = gene_unit(p1, label)
        return a + (b - a) * gene_unit(child, "blend:" + label)
    return gene_unit(child, "mutate:" + label)


def sorted_parents(seed_a: bytes, seed_b: bytes):
    return tuple(sorted([seed_a, seed_b]))


# ---------------------------------------------------------------- seed links

DOMAIN_LINK = "peacegarden.link.v1"


def b64url(raw: bytes) -> str:
    import base64
    return base64.urlsafe_b64encode(raw).decode().rstrip("=")


def link_body(kind, seed, nonce, birth_seconds, display_name, plant_name,
              echo=None, check=None) -> str:
    return ".".join([
        "1",
        kind,
        b64url(seed),
        b64url(nonce),
        str(birth_seconds),
        b64url(display_name.encode("utf-8")),
        b64url(plant_name.encode("utf-8")),
        b64url(echo) if echo else "",
        b64url(check) if check else "",
    ])


def link_checksum(body: str) -> str:
    """Catches a link a messaging app has mangled. Not a signature."""
    return b64url(digest(DOMAIN_LINK, body.encode("utf-8"))[:6])


def link_fragment(kind, seed, nonce, birth_seconds, display_name, plant_name,
                  echo=None, check=None) -> str:
    body = link_body(kind, seed, nonce, birth_seconds, display_name, plant_name, echo, check)
    return body + "." + link_checksum(body)


# ------------------------------------------------------------------ vectors

def hexs(b: bytes) -> str:
    return b.hex()


def main() -> None:
    seed_a = mint_seed(b"peace-garden-reference-entropy-A")
    seed_b = mint_seed(b"peace-garden-reference-entropy-B")
    nonce_a = bytes(range(16))
    nonce_b = bytes(range(100, 116))

    enc = encounter_id(seed_a, seed_b, nonce_a, nonce_b)
    enc_swapped = encounter_id(seed_b, seed_a, nonce_b, nonce_a)
    child = cross(seed_a, seed_b, enc)
    child_swapped = cross(seed_b, seed_a, enc_swapped)

    assert enc == enc_swapped, "encounter id must be commutative"
    assert child == child_swapped, "cross must be commutative"

    p0, p1 = sorted_parents(seed_a, seed_b)

    print("// Generated by tools/reference/derivation_reference.py - do not hand-edit.")
    print(f'seedA          = {hexs(seed_a)}')
    print(f'seedB          = {hexs(seed_b)}')
    print(f'nonceA         = {hexs(nonce_a)}')
    print(f'nonceB         = {hexs(nonce_b)}')
    print(f'encounterID    = {hexs(enc)}')
    print(f'childSeed      = {hexs(child)}')
    print(f'checksum(child)= {hexs(checksum(child))}')
    print()
    for label in ("stem.height", "bloom.petalCount", "palette.petalHue", "form.archetype"):
        print(f'geneU64  {label:24s} A = {gene_u64(seed_a, label)}')
        print(f'geneUnit {label:24s} A = {gene_unit(seed_a, label):.17g}')
        print(f'inherit  {label:24s}   = {inherit_unit(child, p0, p1, label):.17g}')
    print()

    # Distribution sanity: named draws must not correlate across labels.
    import statistics
    vals = [gene_unit(mint_seed(str(i).encode()), "stem.height") for i in range(20000)]
    print(f'mean   = {statistics.mean(vals):.4f}  (expect ~0.5)')
    print(f'stdev  = {statistics.pstdev(vals):.4f}  (expect ~0.2887)')
    buckets = [0] * 10
    for v in vals:
        buckets[int(v * 10)] += 1
    print(f'deciles= {buckets}')

    # Every distinct encounter between the same pair must give a distinct child.
    kids = {cross(seed_a, seed_b, encounter_id(seed_a, seed_b, bytes([i] * 16), nonce_b))
            for i in range(256)}
    print(f'distinct children from 256 encounters = {len(kids)}')

    fragment = link_fragment("o", seed_a, nonce_a, 1_700_000_000, "Marcus", "Aurelia nocturna")
    print(f'link fragment = {fragment}')
    print()

    # Inheritance mix over many labels, to confirm the thresholds behave.
    from collections import Counter
    tally = Counter()
    for i in range(20000):
        label = f"trait.{i}"
        r = gene_unit(child, "inherit:" + label)
        tally["p0" if r < INHERIT_P0 else "p1" if r < INHERIT_P1
              else "blend" if r < INHERIT_BLEND else "mutate"] += 1
    print(f'inheritance mix = {dict(tally)}')


if __name__ == "__main__":
    main()
