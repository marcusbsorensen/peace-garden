"""Labels read twice in a screen sweep: an element whose label is one phrase
said twice over, *Reset everything, Reset everything* (mass test finding 10).

    python3 tools/masstest/app/read_twice.py <sweep folder>

The pseudo-long locale doubles every string on purpose and is left out.
"""
import glob, json, os, re, sys
from collections import Counter

twice = re.compile(r"^(.+?)[,\s]+\1$", re.DOTALL)
found = Counter()
for path in glob.glob(os.path.join(sys.argv[1], "*", "*", "*.json")):
    if path.endswith("-audit.json") or "/pseudo-" in path or path.endswith("timings.json"):
        continue
    screen = os.path.basename(path)[:-5]
    for e in json.load(open(path)).get("elements", []):
        label = e.get("label", "").strip()
        if label and twice.match(label):
            found[(screen, label[:70])] += 1
for (screen, label), n in found.most_common():
    print(f"{n:4}x {screen:13} {label!r}")
print("total", sum(found.values()))
