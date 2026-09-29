#!/usr/bin/env python3
"""The Coppice's fill, simulated before any rule exists.

    python3 tools/coppice/simulate.py            # the report docs/WEB-GARDENS.md quotes
    python3 tools/coppice/simulate.py --sweep    # every template size tried, one line each

Reads the arrivals `coppice-sample` grew (`sample.json`, which the cuts are
measured on, and `fresh.json`, which they are not) and plants them by the rule
`docs/WEB-GARDENS.md` §*The Coppice, chosen* proposes, and by the rules it was
chosen over. Nothing here is SeedCore: it is a Python sketch of a rule that
has not been written, so the numbers are a design's, and the build measures its
own. To draw new samples:

    swift run -c release --package-path tools/coppice coppice-sample 2000 coppice-arrival > tools/coppice/sample.json
    swift run -c release --package-path tools/coppice coppice-sample 2000 coppice-fresh > tools/coppice/fresh.json

**Every plant in the Coppice is a fern or a star.** Its genus heads are `Dros`
and `Ros`, and `PlantName.roots` gives those to many-merous ferns and
many-merous stars and to nothing else, so the area's own plants are exactly two
habits — about 48 ferns to 52 stars. The rule proposed reads that: a fern
stands on a stool and is cut with its coupe; a star stands in the light between
and is never cut.
"""
import argparse, json, os, random, statistics
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))

# MARK: The plot

COUPES = 3          # three bands across the plot, cut one a year in turn
STOOLS = 5          # a coupe's stools, one row down its middle
FLOOR_ROW = 3       # places in the light either side of the stools, a row each

# Where the places stand, in metres from the middle of the plot. Proposed, not
# built: `geometry()` checks they clear the rim and the rides with the nudge.
PLOT_SIDE = 5.2
RIM_WANDER = 0.16             # Organic's outline goes up to this far inward
COUPE_Z = (-1.80, 0.0, 1.80)  # coupe 0 is z-, the far band before a turn
RIDE_Z = 0.90                 # the two rides' centrelines, either side of the middle band
RIDE_HALF = 0.24              # half a ride's width
RIDE_BOW = 0.08               # how far a ride's centreline wanders off its line
ROW_FROM = 0.40               # each floor row from its coupe's stool row
STOOL_X = (-1.8, -0.9, 0.0, 0.9, 1.8)
FLOOR_X = (-1.35, 0.0, 1.35)
NUDGE = 0.06                  # from the seed, either way


def load(name):
    with open(os.path.join(HERE, name)) as f:
        data = json.load(f)
    cols = data["columns"]
    rows = [dict(zip(cols, r)) for r in data["arrivals"]]
    return data, rows


def centile(values, p):
    """The value below which a share `p` of `values` falls, interpolated."""
    s = sorted(values)
    k = (len(s) - 1) * p
    lo, hi = int(k), min(int(k) + 1, len(s) - 1)
    return s[lo] + (s[hi] - s[lo]) * (k - lo)


# MARK: The rule proposed

class Coppice:
    """A coupe holds `stools` stools in one row and a floor of two rows, back
    and front, of `floor_row` places each.

    - **A fern takes a stool**: the coupe of the oldest plot with a free stool
      that holds fewest ferns on stools. Stools are one row and are not graded:
      a stool is drawn at its coupe's stage, so its height is the year's before
      it is the plant's.
    - **A fern that finds every stool taken, in every open plot, may stand on
      the floor**, by the floor's rule, **one to a coupe** (`overflow`), and
      is not cut, as a fern on a woodland floor is not. Without it the floor
      falls behind for good (a stool share of 45% against ferns' 48%); with no
      limit a long run of ferns takes the floor from the stars and leaves the
      plots they open with stools no fern will come to.
    - **A star takes the floor**: its own row (back at or above `floor_cut`),
      oldest plot first, in the coupe with fewest on its floor; else the other
      row if nothing would stand out of order; else a new plot. The Crossing's
      loops, with coupes for quarters.
    - **A new plot is opened in its first coupe**: a fern on its middle stool,
      a star in its own row.
    - `carpet=True` is the variant considered: the first star on a coupe's
      floor claims it for its colour family, as the Cold Frame's frames are
      claimed, and only stars of that family join it.
    """

    def __init__(self, floor_cut, stools=STOOLS, floor_row=FLOOR_ROW, coupes=COUPES,
                 carpet=False, stool_kind=lambda p: p["archetype"] == "fern", overflow=1):
        self.floor_cut = floor_cut
        self.overflow = overflow
        self.stools, self.floor_row, self.coupes = stools, floor_row, coupes
        self.carpet = carpet
        self.on_stool = stool_kind
        self.plots = []   # per plot: per coupe: {"stool": [...], "back": [...], "front": [...]}
        self.log = []     # (arrival index, plot, coupe, where)

    # -- the places --------------------------------------------------------

    def open_plot(self):
        self.plots.append([{"stool": [], "back": [], "front": []} for _ in range(self.coupes)])
        return len(self.plots) - 1

    def floor(self, coupe):
        return coupe["back"] + coupe["front"]

    def row_of(self, height):
        return "back" if height >= self.floor_cut else "front"

    def in_order(self, height, row, coupe):
        """Nothing in the front row taller than anything in the back, among the
        plants drawn grown — the floor. The Cold Frame's `inOrder`."""
        for other in coupe["back" if row == "front" else "front"]:
            if row == "back" and height < other["height"]:
                return False
            if row == "front" and height > other["height"]:
                return False
        return True

    def family_of(self, coupe):
        stars = [p for p in self.floor(coupe) if not self.on_stool(p)]
        return stars[0]["family"] if stars else None

    # -- the rule ----------------------------------------------------------

    def place_on_stool(self, plant):
        for pi, plot in enumerate(self.plots):
            best, fewest = None, None
            for ci, coupe in enumerate(plot):
                if len(coupe["stool"]) < self.stools and (fewest is None or len(coupe["stool"]) < fewest):
                    best, fewest = ci, len(coupe["stool"])
            if best is not None:
                return pi, best, "stool"
        return None

    def place_on_floor(self, plant, claim):
        own = self.row_of(plant["height"])
        other = "front" if own == "back" else "back"
        for row in (own, other):
            for pi, plot in enumerate(self.plots):
                best, fewest = None, None
                for ci, coupe in enumerate(plot):
                    if claim is not None and not claim(coupe):
                        continue
                    n = len(self.floor(coupe))
                    if len(coupe[row]) < self.floor_row and self.in_order(plant["height"], row, coupe) \
                            and (fewest is None or n < fewest):
                        best, fewest = ci, n
                if best is not None:
                    return pi, best, row
        return None

    def place(self, plant):
        if self.on_stool(plant):
            spot = self.place_on_stool(plant)
            if spot:
                return spot
            if self.overflow:
                room = lambda c: sum(1 for p in self.floor(c) if self.on_stool(p)) < self.overflow
                spot = self.place_on_floor(plant, room)
                if spot:
                    return spot
            return self.open_plot(), 0, "stool"
        if self.carpet:
            fam = plant["family"]
            spot = self.place_on_floor(plant, lambda c: self.family_of(c) == fam)
            if spot:
                return spot
            spot = self.place_on_floor(plant, lambda c: self.family_of(c) is None)
            if spot:
                return spot
        else:
            spot = self.place_on_floor(plant, None)
            if spot:
                return spot
        return self.open_plot(), 0, self.row_of(plant["height"])

    def plant(self, plant, index):
        pi, ci, where = self.place(plant)
        self.plots[pi][ci][where].append(plant)
        self.log.append((index, pi, ci, where))
        return pi, ci, where

    # -- what it made ------------------------------------------------------

    @property
    def per_plot(self):
        return self.coupes * (self.stools + 2 * self.floor_row)

    def count(self, plot):
        return sum(len(c["stool"]) + len(c["back"]) + len(c["front"]) for c in plot)


def stage(plot, coupe, year):
    """0 cut this winter, 1 regrowing, 2 grown. The coupes are cut in sequence
    along the wood, so the stage runs on unbroken from one plot into the next."""
    return (year - (COUPES * plot + coupe)) % COUPES


# MARK: Measuring a fill

def measure(c, stream, checkpoints):
    """Plant `stream` and report at each checkpoint."""
    out = []
    marks = set(checkpoints)
    opened_at, full_at = {}, {}
    for i, p in enumerate(stream):
        before = len(c.plots)
        c.plant(p, i)
        if len(c.plots) > before:
            opened_at[len(c.plots) - 1] = i
        for pi, plot in enumerate(c.plots):
            if pi not in full_at and c.count(plot) == c.per_plot:
                full_at[pi] = i
        if i + 1 in marks:
            out.append(snapshot(c, i + 1, opened_at, full_at))
    return out


def snapshot(c, n, opened_at, full_at):
    plots = len(c.plots)
    places = plots * c.per_plot
    planted = sum(c.count(p) for p in c.plots)
    empty_stools = sum(c.stools - len(k["stool"]) for p in c.plots for k in p)
    empty_floor = sum(2 * c.floor_row - len(c.floor(k)) for p in c.plots for k in p)
    full = sum(1 for p in c.plots if c.count(p) == c.per_plot)
    # Empty places in plots that are not among the newest two: the ones a
    # visitor would find in the settled part of the wood.
    settled_empty = sum(c.per_plot - c.count(p) for p in c.plots[:-2])
    floor_plants = [p for pl in c.plots for k in pl for p in c.floor(k)]
    floor_ferns = sum(1 for p in floor_plants if c.on_stool(p))
    own_row, displaced = 0, 0
    order_broken = 0
    for pl in c.plots:
        for k in pl:
            for row in ("back", "front"):
                for p in k[row]:
                    if c.row_of(p["height"]) == row:
                        own_row += 1
                    else:
                        displaced += 1
            if k["back"] and k["front"] and max(p["height"] for p in k["front"]) > min(p["height"] for p in k["back"]):
                order_broken += 1
    # How evenly a plot's three coupes fill, kind by kind: the largest
    # difference between two coupes of one plot, over the settled plots.
    spread = Counter()
    for pl in c.plots[:-2]:
        s = [len(k["stool"]) for k in pl]
        f = [len(c.floor(k)) for k in pl]
        spread[(max(s) - min(s), max(f) - min(f))] += 1
    # The longest any plot stayed unfinished, in arrivals, and which.
    waits = [(full_at.get(pi, n) - opened_at.get(pi, 0), pi) for pi in range(plots)]
    unfinished = [pi for pi in range(plots) if pi not in full_at]
    return dict(n=n, plots=plots, places=places, planted=planted, fill=planted / places,
                full=full, empty_stools=empty_stools, empty_floor=empty_floor,
                settled_empty=settled_empty, floor_ferns=floor_ferns, floor=len(floor_plants),
                own_row=own_row, displaced=displaced, order_broken=order_broken,
                spread=spread, longest_wait=max(waits), unfinished=unfinished)


def line(s):
    return (f"{s['n']:>5}  {s['plots']:>4} plots  {s['fill']*100:5.1f}% held  "
            f"{s['full']:>4} full  empty: {s['empty_stools']:>3} stools {s['empty_floor']:>3} floor  "
            f"settled-empty {s['settled_empty']:>3}  floor ferns {s['floor_ferns']:>3}/{s['floor']:<4} "
            f"own row {s['own_row']}/{s['own_row']+s['displaced']}  out of order {s['order_broken']}")


# MARK: The streams

def worst_cases(rows, seed=7):
    """Arrival orders chosen to hurt. The realistic stream is the sample as it
    was drawn; these are the same plants in orders no real garden would see.

    An order can hurt this rule in two separate ways, and sorting by height
    alone does both at once — ferns are the shorter habit, so a stream sorted
    by height is mostly a run of ferns followed by a run of stars. So they are
    taken apart: **runs of one habit**, which test whether a stool can wait for
    a fern; and **heights sorted within each habit, the habits arriving in the
    order they were drawn**, which test the floor's two rows."""
    ferns = [r for r in rows if r["archetype"] == "fern"]
    stars = [r for r in rows if r["archetype"] == "star"]

    def runs(length):
        """The drawn stream cut into windows of twice `length`, each window's
        stars moved ahead of its ferns: runs of about `length` of one habit,
        with the two habits in the proportion they arrive in."""
        out = []
        for i in range(0, len(rows), 2 * length):
            window = rows[i:i + 2 * length]
            out += [r for r in window if r["archetype"] == "star"]
            out += [r for r in window if r["archetype"] == "fern"]
        return out

    def sorted_within(key, window=None):
        """Heights sorted within each habit — across the whole stream, or
        within each window of `window` arrivals — and the habits arriving in
        the order they were drawn."""
        out = []
        for i in range(0, len(rows), window or len(rows)):
            part = rows[i:i + (window or len(rows))]
            f = iter(sorted((r for r in part if r["archetype"] == "fern"), key=key))
            s = iter(sorted((r for r in part if r["archetype"] == "star"), key=key))
            out += [next(f) if r["archetype"] == "fern" else next(s) for r in part]
        return out

    rng = random.Random(seed)
    return {
        "runs of twenty, stars then ferns": runs(20),
        "runs of sixty, stars then ferns": runs(60),
        "every star first, then every fern": stars + ferns,
        "every fern first, then every star": ferns + stars,
        "shortest first, within each habit, in windows of a hundred": sorted_within(lambda r: r["height"], 100),
        "tallest first, within each habit, in windows of a hundred": sorted_within(lambda r: -r["height"], 100),
        "shortest first, within each habit, the whole stream": sorted_within(lambda r: r["height"]),
        "tallest first, within each habit, the whole stream": sorted_within(lambda r: -r["height"]),
        "one colour at a time": sorted(rows, key=lambda r: r["family"]),
        "shuffled": rng.sample(rows, len(rows)),
    }


def longest_run(rows):
    best, run, last = 0, 0, None
    for r in rows:
        run = run + 1 if r["archetype"] == last else 1
        last = r["archetype"]
        best = max(best, run)
    return best


# MARK: The report

def geometry():
    edge = PLOT_SIDE / 2 - RIM_WANDER
    rows = []
    for z in COUPE_Z:
        rows += [("stool", x, z) for x in STOOL_X]
        rows += [("back", x, z - ROW_FROM) for x in FLOOR_X]
        rows += [("front", x, z + ROW_FROM) for x in FLOOR_X]
    rim = min(edge - (max(abs(x), abs(z)) + NUDGE) for _, x, z in rows)
    ride = float("inf")
    for _, x, z in rows:
        for rz in (-RIDE_Z, RIDE_Z):
            ride = min(ride, abs(z - rz) - NUDGE - RIDE_HALF - RIDE_BOW)
    near = min(((a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2) ** 0.5
               for i, a in enumerate(rows) for b in rows[i + 1:])
    print(f"The places: {len(rows)} a plot; the nearest two {near:.2f} m apart before the nudge; "
          f"{rim:.2f} m clear of the rim and {ride:.2f} m clear of a ride at the worst nudge and wander")


def report():
    fit_data, fit = load("sample.json")
    fresh_data, fresh = load("fresh.json")
    amb = fit_data["ambassador"]

    print("# The Coppice's arrivals\n")
    for name, data, rows in (("fitted", fit_data, fit), ("fresh", fresh_data, fresh)):
        kinds = Counter(r["archetype"] for r in rows)
        print(f"{name}: {len(rows)} plants from {data['crossings']} crossings; "
              f"{kinds['fern']} ferns, {kinds['star']} stars ({kinds['fern']/len(rows)*100:.1f}% ferns)")
    for kind in ("fern", "star"):
        h = [r["height"] for r in fit if r["archetype"] == kind]
        cut = [r["cutHeight"] for r in fit if r["archetype"] == kind]
        reg = [r["regrowingHeight"] for r in fit if r["archetype"] == kind]
        sp = [r["spread"] for r in fit if r["archetype"] == kind]
        print(f"  {kind}s grown {min(h):.2f}-{max(h):.2f} m, median {statistics.median(h):.3f}, "
              f"quartiles {centile(h, .25):.3f}/{centile(h, .75):.3f}; spread median {statistics.median(sp):.2f} m")
        print(f"  {kind}s drawn cut {min(cut):.2f}-{max(cut):.2f} m (median {statistics.median(cut):.2f}), "
              f"regrowing {min(reg):.2f}-{max(reg):.2f} m (median {statistics.median(reg):.2f})")
    fam = Counter(r["family"] for r in fit if r["archetype"] == "star")
    print("  stars by colour family:", ", ".join(f"{k}: {fam[k]}" for k in sorted(fam)))
    print(f"  ambassador: {amb['name']}, a {amb['archetype']}, {amb['height']:.3f} m, family {amb['family']}")

    star_cut = round(statistics.median(r["height"] for r in fit if r["archetype"] == "star"), 2)
    print(f"\nThe floor's cut, the median of the fitted sample's stars: {star_cut:.2f} m")
    fresh_back = sum(1 for r in fresh if r["archetype"] == "star" and r["height"] >= star_cut)
    print(f"  on the fresh sample it puts {fresh_back / sum(1 for r in fresh if r['archetype']=='star')*100:.1f}% of stars at the back")

    stars_all = [r["height"] for r in fit + fresh if r["archetype"] == "star"]
    nearest = min(stars_all, key=lambda h: abs(h - star_cut))
    print(f"  the nearest star to it, of {len(stars_all)}, is {abs(nearest - star_cut)*1000:.2f} mm away")
    geometry()

    ambassador = {"height": amb["height"], "family": amb["family"], "archetype": amb["archetype"]}
    checkpoints = [100, 250, 500, 1000, 2000]

    print(f"\n# The rule proposed: a fern to a stool, a star to the floor "
          f"({COUPES} coupes of {STOOLS} stools and {2*FLOOR_ROW} on the floor, "
          f"{COUPES*(STOOLS+2*FLOOR_ROW)} a plot)\n")
    for name, rows in (("fresh sample", fresh), ("fitted sample", fit)):
        c = Coppice(star_cut)
        where = c.plant(ambassador, -1)
        snaps = measure(c, rows, checkpoints)
        print(f"{name} (the ambassador opens it: plot {where[0]}, coupe {where[1]}, {where[2]} row)")
        for s in snaps:
            print("  " + line(s))
        last = snaps[-1]
        print(f"  coupe evenness over settled plots (stool diff, floor diff): {dict(last['spread'])}")
        print(f"  longest a plot stayed unfinished: {last['longest_wait'][0]} arrivals (plot {last['longest_wait'][1]}); "
              f"unfinished at {last['n']}: plots {last['unfinished']}")
        per = Counter(c.count(p) for p in c.plots)
        print(f"  plants per plot at {last['n']}: " + ", ".join(f"{k}: {per[k]}" for k in sorted(per, reverse=True)))

    # 4,000: both samples end to end, which is the longest stream there is to hand.
    c = Coppice(star_cut)
    c.plant(ambassador, -1)
    snaps = measure(c, fit + fresh, [4000])
    print(f"\nboth samples end to end, 4,000 arrivals\n  " + line(snaps[0]))
    print(f"  unfinished: plots {snaps[0]['unfinished']}")

    # The year: what is drawn cut, regrowing and grown, in each of the three.
    c = Coppice(star_cut)
    c.plant(ambassador, -1)
    measure(c, fresh[:500], [500])
    print("\nThe rotation at 500 (fresh sample): ferns on stools by stage, for three years running")
    for year in range(3):
        stages = Counter()
        for pi, plot in enumerate(c.plots):
            for ci, coupe in enumerate(plot):
                stages[stage(pi, ci, year)] += len(coupe["stool"])
        total = sum(stages.values())
        print(f"  year {year}: cut {stages[0]}, regrowing {stages[1]}, grown {stages[2]} of {total} "
              f"— every star, and every fern on the floor, grown and in flower")
    # A cut coupe against the stars in it, and a grown one.
    over_cut, over_front, over_back, stools = 0, 0, 0, 0
    lowest_margin = float("inf")
    for plot in c.plots:
        for coupe in plot:
            stars = [p for p in c.floor(coupe) if p["archetype"] == "star"]
            front = [p["height"] for p in coupe["front"]]
            back = [p["height"] for p in coupe["back"]]
            for fern in coupe["stool"]:
                stools += 1
                # The ambassador is a fern on a stool since the re-roll of 28
                # September 2026, and the sample does not record its young
                # heights, so it is left out of the cut year's measure.
                if stars and "cutHeight" in fern:
                    lowest_margin = min(lowest_margin, min(p["height"] for p in stars) - fern["cutHeight"])
                    if fern["cutHeight"] > min(p["height"] for p in stars):
                        over_cut += 1
                if front and fern["height"] > max(front):
                    over_front += 1
                if back and fern["height"] > min(back):
                    over_back += 1
    print(f"  cut: no fern on a stool stands taller than any star in its coupe "
          f"({over_cut} of {stools} do; the least clearance is {lowest_margin:.2f} m)")
    print(f"  grown: {over_front} of {stools} ferns on stools stand over every star in the front row of their coupe, "
          f"{over_back} over the shortest star behind them")

    print("\n# Worst cases: the fresh sample's plants in orders chosen to hurt\n")
    print(f"(the longest run of one habit in the realistic streams: {longest_run(fresh)} in the fresh sample, "
          f"{longest_run(fit)} in the fitted one)")
    for name, stream in worst_cases(fresh).items():
        mid = Coppice(star_cut); mid.plant(ambassador, -1)
        end = Coppice(star_cut); end.plant(ambassador, -1)
        m = measure(mid, stream[:1000], [1000])[0]
        e = measure(end, stream, [len(stream)])[0]
        print(f"{name}:\n  " + line(m) + "\n  " + line(e))
    c = Coppice(star_cut, carpet=True); c.plant(ambassador, -1)
    e = measure(c, worst_cases(fresh)["one colour at a time"], [2000])[0]
    print("one colour at a time, with carpets:\n  " + line(e))
    c = Coppice(star_cut, overflow=99); c.plant(ambassador, -1)
    e = measure(c, worst_cases(fresh)["every fern first, then every star"], [2000])[0]
    print("every fern first, with any number of ferns on the floor:\n  " + line(e))

    print("\n# The rules it was chosen over, on the fresh sample at 2,000\n")
    variants = {
        "proposed: fern to a stool, star to the floor": Coppice(star_cut),
        "carpets: a coupe's floor claimed by the colour of its first star": Coppice(star_cut, carpet=True),
        "no fern on the floor at all": Coppice(star_cut, overflow=0),
        "any number of ferns on the floor": Coppice(star_cut, overflow=99),
    }
    # By height: the tallest share of plants on the stools, whatever their habit,
    # with the floor's cut at the median of the rest.
    share = STOOLS / (STOOLS + 2 * FLOOR_ROW)
    tall_cut = centile([r["height"] for r in fit], 1 - share)
    rest_cut = statistics.median(r["height"] for r in fit if r["height"] < tall_cut)
    variants[f"by height: the tallest {share*100:.0f}% on stools (cut {tall_cut:.2f} m)"] = Coppice(
        rest_cut, stool_kind=lambda p, t=tall_cut: p["height"] >= t)
    # The stars cut and the ferns the floor: the heights' own order.
    fern_cut = statistics.median(r["height"] for r in fit if r["archetype"] == "fern")
    variants["stars on the stools, ferns the floor"] = Coppice(
        fern_cut, stool_kind=lambda p: p["archetype"] == "star")
    for name, c in variants.items():
        c.plant(ambassador, -1)
        s = measure(c, fresh, [2000])[0]
        stars_cut = sum(1 for pl in c.plots for k in pl for p in k["stool"] if p["archetype"] == "star")
        stars = sum(1 for r in fresh if r["archetype"] == "star")
        print(f"{name}\n  " + line(s) +
              f"\n  stars on stools, so out of flower two years in three: {stars_cut} of {stars} ({stars_cut/stars*100:.0f}%)")


def sweep():
    """Every template size near the one proposed, on the fresh sample."""
    _, fit = load("sample.json")
    _, fresh = load("fresh.json")
    star_cut = round(statistics.median(r["height"] for r in fit if r["archetype"] == "star"), 2)
    print("stools  floor/row  a plot  stool share   at 500 / 2000")
    for stools in (3, 4, 5, 6, 7):
        for floor_row in (2, 3, 4):
            out = []
            for n in (500, 2000):
                c = Coppice(star_cut, stools=stools, floor_row=floor_row)
                s = measure(c, fresh[:n], [n])[0]
                out.append(f"{s['plots']:>3} plots {s['fill']*100:5.1f}% settled-empty {s['settled_empty']:>3} "
                           f"floor ferns {s['floor_ferns']:>3}")
            per = COUPES * (stools + 2 * floor_row)
            print(f"{stools:>6}  {floor_row:>9}  {per:>6}  {stools/(stools+2*floor_row)*100:>10.0f}%   " + " | ".join(out))


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--sweep", action="store_true", help="try every template size near the one proposed")
    args = ap.parse_args()
    sweep() if args.sweep else report()
