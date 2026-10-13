"""How much a screen sweep covered: screens, configurations, audits and what
the audits said, for the report's numbers.

    python3 tools/masstest/app/sweep_counts.py build/mt/screens
"""
import collections, glob, json, os, sys

root = sys.argv[1]
shots = [p for p in glob.glob(os.path.join(root, "*", "*", "*.json")) if not p.endswith("-audit.json")]
audits = glob.glob(os.path.join(root, "*", "*", "*-audit.json"))
configs = {tuple(p.split(os.sep)[-3:-1]) for p in shots}
audited = {tuple(p.split(os.sep)[-3:-1]) for p in audits}
print(f"screens {len(shots)}, configurations {len(configs)}, audited screens {len(audits)}, audited configurations {len(audited)}")
by_type = collections.Counter()
for p in audits:
    for issue in json.load(open(p)):
        by_type[issue["type"]] += 1
print(f"audit issues {sum(by_type.values())}: {dict(by_type)}")
garden = [p for p in audits if p.endswith("garden-audit.json")]
counts = sorted(sum(1 for i in json.load(open(p)) if i["type"] == "sufficientElementDescription") for p in garden)
if counts:
    print(f"garden screens audited {len(counts)}; no-description issues per screen min {counts[0]}, median {counts[len(counts) // 2]}, max {counts[-1]}")
