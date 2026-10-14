"""The stress results as a Markdown table, one row per garden size.

    python3 tools/masstest/app/stress_table.py build/mt/stress-O build/mt/stress-O2 ...

Every number is from `stress-<size>.json` (`MassTestStressTests`). Times
marked CPU are the main thread's own CPU time, which a shared machine
distorts much less than the wall clock.
"""
import glob, json, os, sys

rows = {}
for folder in sys.argv[1:]:
    for path in glob.glob(os.path.join(folder, "stress-*.json")):
        d = json.load(open(path))
        rows[d["plants"]] = d


def f(v, fmt="{:.0f}"):
    return "–" if v is None else fmt.format(v)


print("| Plants | Plot side | File | Load | First frame (wall / main CPU) | Settled after | Redraw a frame (main CPU / p95 interval) | Quarter-turn (wall / main CPU) | A month on (wall) | Footprint peak sampled | Left after closing |")
print("|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|")
for n in sorted(rows):
    d = rows[n]
    turn = d["turns"][0] if d.get("turns") else {}
    month = d["months"][0] if d.get("months") else {}
    redraw = d.get("redraw", {})
    print("| {} | {} m | {} KB | {} ms | {} s / {} s | {} s | {} ms / {} ms | {} s / {} s | {} s | {} MB | {} MB |".format(
        n, f(d.get("plotSideM"), "{:.1f}"), d.get("fileKB"), f(d.get("loadMs")),
        f(d.get("firstFrameMs", 0) / 1000, "{:.1f}"),
        f(d.get("firstFrameCPUms", 0) / 1000 if d.get("firstFrameCPUms") else None, "{:.1f}"),
        f(d["open"].get("seconds"), "{:.1f}"),
        f(redraw.get("cpuMsPerFrame")), f(redraw.get("p95Ms")),
        f(turn.get("seconds"), "{:.1f}"), f(turn.get("mainThreadCPUSeconds"), "{:.1f}"),
        f(month.get("seconds"), "{:.1f}"),
        f(d.get("footprintPeakMB")), f(d.get("footprintAfterCloseMB"))))
