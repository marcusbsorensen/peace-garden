"""A garden of any size, for the mass test: N crossed plants and some figures.

    python3 tools/masstest/app/make_garden.py 500 out/garden-500.json
    python3 tools/masstest/app/make_garden.py 14 out/garden-14.json --lamps 6

Built on `tools/fixture/garden.py`'s encoding (hex seeds, base64 encounter IDs)
and its derivation: every plant is a real cross of two seeds, `cross(a, b,
encounter)` exactly as `Pollination.cross` does it, so the app grows each one
from SeedCore as it would a plant met at a knock. Nothing here decides what a
plant looks like; the seed does.

Births are spread over the last `--span` days (default 240) before today, so a
garden of any size holds every stage from seedling to a plant long in flower.
No plant carries tokens or a standing, so nothing in the garden asks the plot
service anything. Deterministic for a given N and day.
"""
import argparse, base64, datetime, hashlib, json, math, struct, uuid

CROSS = "peacegarden.cross.v1"
SEED = "peacegarden.seed.v1"
PEERS = ["Ada", "Bo", "Cai", "Devi", "Esme", "Fen", "Ines", "Jo", "Kit", "Lin",
         "Mo", "Nell", "Oz", "Pia", "Rafi", "Suki", "Tomas", "Hilde", "Owen", "Marta"]
KINDS = ["lantern", "paperLamp", "fireflies", "hare", "fox", "moth", "snail"]


def digest(domain, *parts):
    message = domain.encode() + b"\0"
    for part in parts:
        message += struct.pack(">I", len(part)) + part
    return hashlib.sha256(message).digest()


def seed(of):
    return digest(SEED, of.encode())


def cross(a, b, encounter):
    low, high = (a, b) if a < b else (b, a)
    return digest(CROSS, low, high, encounter)


def stable_uuid(label):
    return str(uuid.UUID(bytes=hashlib.sha256(label.encode()).digest()[:16])).upper()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("count", type=int)
    parser.add_argument("out")
    parser.add_argument("--lamps", type=int, default=None,
                        help="figures and lights on the plot (default 6 + count/50, at most 40)")
    parser.add_argument("--span", type=float, default=240, help="days the births are spread over")
    parser.add_argument("--name", default="Wren")
    args = parser.parse_args()

    today = datetime.datetime.now(datetime.timezone.utc).replace(hour=12, minute=0, second=0, microsecond=0)

    def when(days_ago):
        return (today - datetime.timedelta(days=days_ago)).strftime("%Y-%m-%dT%H:%M:%SZ")

    mine = seed("masstest-me")
    plants = []
    for n in range(args.count):
        theirs = seed(f"masstest-peer-{n}")
        encounter = digest("peacegarden.encounter.v1", mine, theirs, f"masstest-{n}".encode())
        child = cross(mine, theirs, encounter)
        low, high = (mine, theirs) if mine < theirs else (theirs, mine)
        days = 1 + (args.span - 1) * (1 - n / max(1, args.count - 1)) if args.count > 1 else 30
        plants.append({
            "id": stable_uuid(f"masstest-plant-{n}"),
            "seed": child.hex(),
            "lineage": {"crossed": {"parentA": low.hex(), "parentB": high.hex(),
                                    "encounterID": base64.b64encode(encounter).decode()}},
            "birth": when(days),
            "savedAt": when(days),
            "encounter": {"peerDisplayName": PEERS[n % len(PEERS)], "happenedAt": when(days),
                          "showsDateTime": True, "place": "the long field"},
        })

    count = args.lamps if args.lamps is not None else min(40, 6 + args.count // 50)
    # Spread on a loose spiral inside the smallest plot, so every figure is on
    # the ground whatever size the plot has grown to.
    lamps = []
    for k in range(count):
        angle = k * 2.399963
        radius = 0.25 + 0.85 * ((k + 1) / max(1, count)) ** 0.5
        lamps.append({"id": stable_uuid(f"masstest-lamp-{k}"), "kind": KINDS[k % len(KINDS)],
                      "spot": {"x": round(radius * math.cos(angle), 3),
                               "z": round(radius * math.sin(angle), 3)}})

    garden = {
        "schemaVersion": 1,
        "identity": {"seed": mine.hex(), "birth": when(300), "displayName": args.name},
        "plants": plants,
        "beds": [{"id": stable_uuid("masstest-bed"), "name": "", "template": "thematic",
                  "placed": {}, "world": 0, "lamps": lamps}],
    }
    with open(args.out, "w") as out:
        json.dump(garden, out)
    print(f"wrote {len(plants)} plants and {len(lamps)} figures to {args.out}")


if __name__ == "__main__":
    main()
