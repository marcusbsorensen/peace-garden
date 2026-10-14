#!/usr/bin/env python3
"""Before and after, from the mass test's own stress results, one row a size.

    python3 tools/perf/perf_table.py --before DIR [DIR ...] --after DIR [DIR ...]

Every number comes from `stress-<size>.json` (`MassTestStressTests`):

- **Longest block opening**: the longest the main thread went without a frame
  while the garden opened — the first frame itself, or the longest
  display-link interval until the plot held still, whichever is longer.
- **Filled in**: from the window's making until every plant had its pictures
  and the plot held still (before 14 October the first frame itself held
  every picture, so that is the first frame and the settling after it).
- **Redraw**: a frame with the clock moved a second and nothing new to make,
  the main thread's own CPU, mean (and median where recorded).
- **Turn**: a quarter-turn, the longest block and until it was filled in
  again; **a month**: the clock wound on a month, the same.
- **Peak**: the process footprint, sampled in-app every quarter second while
  the garden opened, turned and grew; **after closing**: three seconds after
  the window went, with the footprint before it opened in brackets.
"""
import argparse
import glob
import json
import os


def load(folders):
    rows = {}
    for folder in folders:
        for path in glob.glob(os.path.join(folder, "stress-*.json")):
            d = json.load(open(path))
            rows[d["plants"]] = d
    return rows


def opening_block(d):
    return max(d.get("firstFrameMs", 0), d.get("open", {}).get("worstMs", 0))


def peak(d):
    phases = [d.get("open", {})] + d.get("turns", []) + d.get("months", [])
    return max([d.get("footprintPeakMB", 0)] + [p.get("peakDuringMB", 0) for p in phases])


def cell(d):
    if d is None:
        return None
    o = d.get("open", {})
    r = d.get("redraw", {})
    turn = (d.get("turns") or [{}])[0]
    month = (d.get("months") or [{}])[0]
    median = r.get("cpuMsP50")
    return {
        "block": f"{opening_block(d) / 1000:.2f} s" if opening_block(d) >= 1000 else f"{opening_block(d):.0f} ms",
        # From the window's making: the first frame, then the settling after it
        # (before 14 October the first frame held every picture).
        "filled": f"{d.get('firstFrameMs', 0) / 1000 + o.get('seconds', 0):.1f} s",
        "redraw": f"{r.get('cpuMsPerFrame', 0):.1f}" + (f" ({median:.1f})" if median is not None else "") + " ms",
        "turn": f"{turn.get('worstMs', 0):.0f} ms / {turn.get('seconds', 0):.1f} s",
        "month": f"{month.get('worstMs', 0):.0f} ms / {month.get('seconds', 0):.1f} s",
        "peak": f"{peak(d):.0f} MB",
        "after": f"{d.get('footprintAfterCloseMB', 0):.0f} MB (from {d.get('footprintBeforeMB', 0):.0f})",
    }


parser = argparse.ArgumentParser()
parser.add_argument("--before", nargs="*", default=[])
parser.add_argument("--after", nargs="*", default=[])
args = parser.parse_args()
before, after = load(args.before), load(args.after)
keys = ["block", "filled", "redraw", "turn", "month", "peak", "after"]
names = ["Longest block opening", "Filled in", "Redraw, main CPU mean (median)",
         "Turn: longest block / filled", "A month on: longest block / filled", "Footprint peak",
         "After closing"]
print("| Plants | | " + " | ".join(names) + " |")
print("|---:|---|" + "---:|" * len(names))
for n in sorted(set(before) | set(after)):
    for label, rows in (("before", before), ("after", after)):
        c = cell(rows.get(n))
        if c is None:
            continue
        print(f"| {n} | {label} | " + " | ".join(c[k] for k in keys) + " |")
