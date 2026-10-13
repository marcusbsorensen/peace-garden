"""The UI performance run as a Markdown table, one row per garden size.

    python3 tools/masstest/app/perf_table.py build/mt/perf

Reads `metrics-<size>.json` (`xcrun xcresulttool get test-results metrics
--path <bundle>`) and the hand-timed `perf-<size>-<test>.json` beside it.
Medians throughout; XCTest's first `measure` iteration is its own and is
kept, as it reports it.
"""
import glob, json, os, re, statistics, sys

folder = sys.argv[1]


def median(values):
    values = [v for v in values if v is not None]
    return statistics.median(values) if values else None


def metric(metrics, test, name):
    for t in metrics:
        if t["testIdentifier"].endswith(test + "()"):
            for run in t["testRuns"]:
                for m in run["metrics"]:
                    if re.search(name, m["displayName"]):
                        return median(m["measurements"]), m["unitOfMeasurement"]
    return None, None


def hand(size, test):
    path = os.path.join(folder, f"perf-{size}-{test}.json")
    return json.load(open(path)) if os.path.exists(path) else {}


def f(v, fmt="{:.1f}"):
    return "–" if v is None else fmt.format(v)


sizes = sorted(int(re.search(r"metrics-(\d+)", p).group(1)) for p in glob.glob(os.path.join(folder, "metrics-*.json")))
# XCTHitchMetric was asked for and reported nothing on the simulator, so the
# pan is judged by how much of a core the app burns per second of gesture.
print("| Plants | Launch to responsive | Launch memory peak | Garden open, launched into it | Pan: app CPU per second of gesture | Pan: memory peak | Two-finger turn: until it answers | Turn: app CPU | Turn: memory peak |")
print("|---:|---:|---:|---:|---:|---:|---:|---:|---:|")
for size in sizes:
    try:
        metrics = json.load(open(os.path.join(folder, f"metrics-{size}.json")))
    except ValueError:
        metrics = []
    launch, _ = metric(metrics, "testLaunchToInteractive", r"ApplicationFirstFramePresentationResponsive")
    launch_mem, _ = metric(metrics, "testLaunchToInteractive", r"Memory Peak Physical")
    pan_cpu, _ = metric(metrics, "testPan", r"^CPU Time")
    pan_clock, _ = metric(metrics, "testPan", r"Clock Monotonic Time")
    pan_mem, _ = metric(metrics, "testPan", r"Memory Peak Physical")
    turn_cpu, _ = metric(metrics, "testRotate", r"^CPU Time")
    turn_mem, _ = metric(metrics, "testRotate", r"Memory Peak Physical")
    opened = median([r.get("responsiveSeconds") for r in hand(size, "open").get("runs", [])])
    turned = median([r.get("seconds") for r in hand(size, "rotate").get("turns", [])])
    share = pan_cpu / pan_clock if pan_cpu and pan_clock else None
    print("| {} | {} s | {} MB | {} s | {} | {} MB | {} s | {} s | {} MB |".format(
        size, f(launch, "{:.2f}"), f(launch_mem / 1024 if launch_mem else None, "{:.0f}"),
        f(opened), f(share * 100 if share else None, "{:.0f}% of a core"),
        f(pan_mem / 1024 if pan_mem else None, "{:.0f}"), f(turned), f(turn_cpu),
        f(turn_mem / 1024 if turn_mem else None, "{:.0f}")))
