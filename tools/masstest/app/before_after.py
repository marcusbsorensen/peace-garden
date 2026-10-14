"""A before/after table from two `analyze_screens.py` outputs.

    python3 tools/masstest/app/before_after.py <before analysis dir> <after analysis dir> [--skip about,about-end]

Counts only the screens both sweeps photographed (a screen new in the after
sweep is left out with `--skip`, and given its own lines at the end). Prints a
Markdown table per device and for all three together:

- the accessibility audit by type, *Dynamic Type* split into *unsupported*
  (the text does not scale at all) and *partially unsupported* (it scales,
  and is capped or reflows somewhere along the way);
- clipped texts: the audit's *text clipped* and the analyser's words past an
  edge of the window outside a scroll view;
- texts that grew from Large to XXXL, AX3 or AX5, of those compared;
- overlaps and labels that stayed put under right to left.
"""
import argparse, json, os, re
from collections import Counter

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
_catalogue = json.load(open(os.path.join(REPO, "App/PeaceGarden/Resources/Localizable.xcstrings")))["strings"]
# The plot's own elements (14 October): a plant's name, or a light's in any
# language. They stand where the plants stand, so they overlap one another and
# do not mirror, both by design, and are left out of those two counts.
LIGHTS = set()
for key in ["Lantern", "Paper lamp", "Fireflies", "Hare", "Fox", "Moth", "Snail"]:
    LIGHTS.add(key)
    LIGHTS.add(f"{key} {key}")
    for unit in _catalogue.get(key, {}).get("localizations", {}).values():
        LIGHTS.add(unit["stringUnit"]["value"])
BINOMIAL = re.compile(r"^[A-Z][a-z]+ [a-z]+$")


def on_the_plot(label):
    label = (label or "").strip()
    return label in LIGHTS or bool(BINOMIAL.match(label))

p = argparse.ArgumentParser()
p.add_argument("before")
p.add_argument("after")
p.add_argument("--skip", default="about,about-end")
a = p.parse_args()
skip = set(a.skip.split(",")) if a.skip else set()
DEVICES = ["SE", "Air", "ProMax"]


def load(folder, device):
    path = os.path.join(folder, f"{device}.json")
    return json.load(open(path)) if os.path.exists(path) else {}


def count(findings, keep):
    c = Counter()
    for issue in findings.get("audit", []):
        if not keep(issue["screen"]):
            continue
        kind = issue["type"]
        if kind == "dynamicType":
            kind = "dynamicType partial" if "partially" in issue["description"] else "dynamicType none"
        c[kind] += 1
    c["clipped: audit"] = c["textClipped"]
    c["clipped: past an edge"] = sum(1 for r in findings.get("offscreen", []) if keep(r["screen"]))
    grew = [r for r in findings.get("dynamicType", []) if keep(r["screen"])]
    c["texts that grew"] = sum(r["textsThatGrew"] for r in grew)
    c["texts compared"] = sum(r["textsThatGrew"] + r["textsThatDidNot"] for r in grew)
    c["overlaps"] = sum(1 for r in findings.get("overlap", []) if keep(r["screen"])
                        and not (r["screen"] == "garden" and on_the_plot(r["a"]) and on_the_plot(r["b"])))
    c["not mirrored"] = sum(1 for r in findings.get("notMirrored", []) if keep(r["screen"])
                            and not (r["screen"] == "garden" and on_the_plot(r["label"])))
    return c


ROWS = [("sufficientElementDescription", "Audit: element with no description"),
        ("contrast", "Audit: contrast"),
        ("dynamicType none", "Audit: Dynamic Type unsupported"),
        ("dynamicType partial", "Audit: Dynamic Type partially unsupported (capped or reflowing)"),
        ("textClipped", "Audit: text clipped"),
        ("hitRegion", "Audit: hit region"),
        ("trait", "Audit: trait"),
        ("elementDetection", "Audit: element detection"),
        ("auditError", "Audit could not run"),
        ("clipped: past an edge", "Words past an edge of the window"),
        ("overlaps", "Overlapping words (see note)"),
        ("not mirrored", "Labels unmoved under right to left"),
        ("texts that grew", "Texts that grew, L to XXXL/AX3/AX5")]

totals = {"before": Counter(), "after": Counter()}
for device in DEVICES:
    before = count(load(a.before, device), lambda s: s not in skip)
    after = count(load(a.after, device), lambda s: s not in skip)
    totals["before"].update(before)
    totals["after"].update(after)
    print(f"\n#### {device}\n\n| | before | after |\n|---|---:|---:|")
    for key, name in ROWS:
        if before[key] or after[key]:
            extra = ""
            if key == "texts that grew":
                extra = f" of {before['texts compared']}", f" of {after['texts compared']}"
                print(f"| {name} | {before[key]}{extra[0]} | {after[key]}{extra[1]} |")
            else:
                print(f"| {name} | {before[key]} | {after[key]} |")

b, f = totals["before"], totals["after"]
print("\n#### All three phones\n\n| | before | after |\n|---|---:|---:|")
for key, name in ROWS:
    if b[key] or f[key]:
        if key == "texts that grew":
            print(f"| {name} | {b[key]} of {b['texts compared']} | {f[key]} of {f['texts compared']} |")
        else:
            print(f"| {name} | {b[key]} | {f[key]} |")
audited = lambda c: sum(c[k] for k, _ in ROWS[:9])
print(f"| **Audit issues in all** | **{audited(b)}** | **{audited(f)}** |")

if skip:
    print("\n#### Screens only in the after sweep: " + ", ".join(sorted(skip)) + "\n")
    print("| | after |\n|---|---:|")
    only = Counter()
    for device in DEVICES:
        only.update(count(load(a.after, device), lambda s: s in skip))
    for key, name in ROWS:
        if only[key]:
            print(f"| {name} | {only[key]} |")
