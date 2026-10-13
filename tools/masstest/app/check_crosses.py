"""Re-derives the fuzz run's sampled crosses with Python's own SHA-256.

    python3 tools/masstest/app/check_crosses.py fuzz-crosses.json

The encounter and the child are recomputed from the two seeds and the two
nonces exactly as `Pollination` describes them, by a second implementation
of the hashing, so a drift between Swift and the web garden's derivation
would show here rather than as two phones growing different plants.
"""
import hashlib, json, struct, sys

ENCOUNTER = "peacegarden.encounter.v1"
CROSS = "peacegarden.cross.v1"


def digest(domain, *parts):
    message = domain.encode() + b"\0"
    for part in parts:
        message += struct.pack(">I", len(part)) + part
    return hashlib.sha256(message).digest()


def main(path):
    rows = json.load(open(path))
    bad = 0
    for row in rows:
        a, b = bytes.fromhex(row["a"]), bytes.fromhex(row["b"])
        na, nb = bytes.fromhex(row["nonceA"]), bytes.fromhex(row["nonceB"])
        # The seeds in byte order, and the nonces in byte order on their own:
        # neither phone's nonce is tied to its seed.
        low, high = sorted([a, b])
        nlow, nhigh = sorted([na, nb])
        encounter = digest(ENCOUNTER, low, high, nlow, nhigh)
        child = digest(CROSS, low, high, encounter)
        if encounter.hex() != row["encounter"] or child.hex() != row["child"]:
            bad += 1
            if bad <= 5:
                print("mismatch", row["child"][:12], "encounter ok" if encounter.hex() == row["encounter"] else "encounter differs")
    print(f"{len(rows)} crosses re-derived, {bad} differ")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
