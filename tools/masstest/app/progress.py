"""Where every running sweep has got to.

    python3 tools/masstest/app/progress.py build/mt
"""
import glob, json, os, sys

root = sys.argv[1] if len(sys.argv) > 1 else "build/mt"
for timings in sorted(glob.glob(os.path.join(root, "screens", "*", "timings.json"))):
    device = os.path.basename(os.path.dirname(timings))
    try:
        rows = json.load(open(timings))
    except ValueError:
        continue
    errors = [r for r in rows if "error" in r]
    last = rows[-1] if rows else {}
    print(f"{device:7} {len(rows):3} screens, last {last.get('config')} {last.get('screen')}, "
          f"{sum(r.get('seconds', 0) for r in rows) / 60:.0f} min, {len(errors)} errors")
    for r in errors[-3:]:
        print("         ", r["config"], r["screen"], r["error"][:90])
for log in sorted(glob.glob(os.path.join(root, "stress*", "stress-log.txt"))):
    print(os.path.dirname(log))
    for line in open(log).read().splitlines()[-6:]:
        print("   ", line[:200])
for clock in sorted(glob.glob(os.path.join(root, "*.clock"))):
    lines = open(clock).read().splitlines()
    print(f"{os.path.basename(clock):24} {' | '.join(lines[1:])[:150]}")
