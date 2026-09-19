"""A garden with one plant in each standing, for looking at the asking.

    python3 tools/fixture/garden.py "$(xcrun simctl get_app_container booted \
        app.peacegarden data)/Library/Application Support/PeaceGarden/garden.json"

Then launch with `-pgOpen garden -pgPlots http://localhost:8803` to point the
app at a local plot service. Two things the app will not tell you if you get
them wrong: dates must be ISO 8601, and a token is hex — `Data` decodes from
base64 by default, so a hex token written as base64 arrives half as long again
as it should be and the service answers 400.

It writes six plants: one offerable, one asked, one invited, one shown, one
declined, and one hybrid from before meetings left tokens behind, which can
never be asked about.
"""
import base64, hashlib, json, struct, sys, uuid, datetime

CROSS = "peacegarden.cross.v1"
SEED = "peacegarden.seed.v1"


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


def when(days_ago):
    t = datetime.datetime(2026, 9, 19, 12, 0, tzinfo=datetime.timezone.utc) - datetime.timedelta(days=days_ago)
    return t.strftime("%Y-%m-%dT%H:%M:%SZ")


mine = seed("marcus-fixture")
plants = []

# name, peer, standing state, days ago, tokens?
rows = [
    ("here", "Ada", None, 40),
    ("asked", "Bo", "asked", 32),
    ("invited", "Cai", "invited", 25),
    ("shown", "Devi", "shown", 18),
    ("declined", "Esme", "declined", 12),
    ("untokened", "Fen", None, 60),
]

for label, peer, state, days in rows:
    theirs = seed(f"peer-{label}")
    encounter = digest("peacegarden.encounter.v1", mine, theirs, label.encode())
    child = cross(mine, theirs, encounter)
    low, high = (mine, theirs) if mine < theirs else (theirs, mine)
    record = {
        "id": str(uuid.uuid4()).upper(),
        "seed": child.hex(),
        # **Base64, not hex.** `SeedID` writes itself as hex and so does
        # `MeetingTokens`, but `Lineage.encounterID` is a plain `Data` with a
        # synthesised `Codable`, and a plain `Data` is base64. Written as hex it
        # decodes to 48 bytes of nonsense, the app is perfectly happy, and the
        # plot service answers 400 on an encounter 96 characters wide.
        "lineage": {"crossed": {"parentA": low.hex(), "parentB": high.hex(),
                                "encounterID": base64.b64encode(encounter).decode()}},
        "birth": when(days),
        "savedAt": when(days),
        "encounter": {"peerDisplayName": peer, "happenedAt": when(days), "showsDateTime": True,
                      "place": "the long field"},
    }
    if label != "untokened":
        record["tokens"] = {
            # Hex, because `MeetingTokens` writes itself as hex. The two
            # spellings live side by side in one file; see above.
            "ours": digest("token.ours", label.encode())[:16].hex(),
            "theirs": digest("token.theirs", label.encode())[:16].hex(),
        }
    if state:
        record["standing"] = {"state": state, "changedAt": when(days - 1)}
    plants.append(record)

garden = {
    "schemaVersion": 1,
    "identity": {"seed": mine.hex(), "birth": when(90), "displayName": "Marcus"},
    "plants": plants,
}

path = sys.argv[1]
with open(path, "w") as out:
    json.dump(garden, out, indent=2)
print(f"wrote {len(plants)} plants to {path}")
for label, peer, state, days in rows:
    print(f"  {label:10} {peer:6} {state or 'here'}")
