# The Seedbed, built: drills on the contour

Option A of `RESEARCH.md` §*The Seedbed*, as Marcus chose it on 2 October 2026.
Built on the layouts foundation (`tools/layouts/`).

## What was built

**These stand as they were:**

- six drills of eight, 0.74 m between drills and 0.52 m between places along one;
- a drill claimed by kind and by element, read off its first plant;
- a lotus taking two places and standing centred across them;
- a drill's last odd place waiting for a plant of one place.

**What changed:**

- **The table**, `tools/layouts/tables/seedbed_drills.py`, written to
  `PlaceTable.seedbedDrills` (Swift), `SeedbedDrillsTable` (PHP) and
  `tables/seedbed_drills.js`. One feature variant, 48 places.
  - The bed falls toward z+, so each drill is a contour: an arc about a point
    7.4 m below the plot's middle, wandering 2.5 cm.
  - The drills now run across the bed in x and are stacked down it in z, where
    the straight ones ran in z.
  - Drill 0 is the top, on the high side; drill 5 is the foot.
  - Tags: `drill`, `index` (how far along the drill, 0 nearest the label, as
    before) and `pair` (the order a flooded drill's pairs are sown in). The
    table also carries each drill's line, `drill0` to `drill5`. Each line's
    first point is where its label stands.

  | Drill | Radius | Bow over its length | First place, x | Label |
  |---|---|---|---|---|
  | 0 (top) | 9.40 m | 0.17 m | −1.81 | (−2.14, −1.75) |
  | 1 | 8.66 m | 0.20 m | −1.72 | (−2.05, −0.99) |
  | 2 | 7.92 m | 0.25 m | −1.68 | (−2.01, −0.25) |
  | 3 | 7.18 m | 0.26 m | −1.68 | (−2.01, 0.50) |
  | 4 | 6.44 m | 0.28 m | −1.70 | (−2.03, 1.28) |
  | 5 (foot) | 5.70 m | 0.30 m | −1.79 | (−2.11, 2.11) |

  The middle drills begin a little further in than the outer ones, so the
  labels stand on a curve rather than in a ruled column. The nearest two places
  are 0.52 m apart along a drill and 0.72 m across. Every place is within
  ±2.0 m of the middle, inside the bed the check allows (±2.1 m with the
  nudge).
- **The water lies low.** A dry kind claims the highest drill nobody has sown,
  and a lily or a reed claims the lowest. The flooded drills gather at the foot
  of the bed and the dry ones at its head.
- **A drill is sown from its middle.** Marcus answered "from the labelled end" on 23
  September; this is changed on purpose, by his yes to *every count looks
  finished*.
  - A dry drill takes the place nearest its middle first, then farthest-first.
    One plant stands in the middle; three stand at the middle and both ends.
  - A flooded drill is sown in pairs, in the same way, because a lily takes two
    places. A reed takes the first free place in that order, so two reeds share
    a pair before a third opens another.
- **Plots alternate**, mirrored one to the next (`Seedbed.variants`, now read).
  The labels stand at the west end of even plots and the east end of odd ones,
  and the water stays low in both.
- **The nudge** is still 0.06 m along a drill and 0.035 m across it. It now
  runs along x and across z, because the drills turned.
- **The stored shape is the same**: `drill`, `slot_index` (where along the
  drill, from the label) and `slot_span`. The service works out the spot when
  it serves a planting: `Seedbed::spot($plot, …)` takes the middle of the
  places, adds the nudge and mirrors odd plots.
- **Vectors and checks.**
  - Each row of `seedbed_vectors.json` gains its plot's `variant` and its
    `spot`, compared exactly by `check_seedbed.php`.
  - The check's *filled from the label with no gap* becomes three checks: a
    dry drill is a prefix of its order; a flooded drill's pairs are a prefix of
    its pair order; and each drill claimed was the first on its own side of the
    bed when it was claimed.
  - `SeedbedTests` proves that sowing in pairs lets in and turns away exactly
    the plants that sowing from the label did, for every mix of reeds and lilies
    up to nine.
- **The drawing** (`seedbed.js`):
  - Each furrow follows its drill's line. The rake is dark in the bottom of a
    drill, pale on the crest and flat again past either end.
  - A flooded drill's trough is dug along its arc and closes in a rounded pool
    at each end.
  - Each label stands on its line's first point, turned to face out along the
    drill.
  - Each plot's variant comes from the module, so a mirrored plot is dug
    mirrored.
  - `pg_seedbed_plan` no longer carries positions: they are the table's.
- **The page** (`seedbedpage.js`) reads each planting's drill and kind from the
  wire, which has carried both since the kind went on it. It falls back to the
  nearest drill line only for a service that sends neither.
- **One fix on the workbench**: a drill claimed by a reed is drawn flooded, as
  the service draws it. It was drawn dry, because the workbench only flooded a
  drill for a lotus.

## The fill, against the baseline

`layouts-harness --area seedbed --against tools/layouts/baseline.json`:

| Arrivals | Plots | Places held | Held | Settled plots | Held in settled | Empty in settled |
|---|---|---|---|---|---|---|
| 10 | 2 | 11 of 96 | 11.5% | 0 | — | — |
| 100 | 8 | 131 of 384 | 34.1% | 6 | 38.5% | 177 |
| 1,000 | 36 | 1275 of 1728 | 73.8% | 34 | 77.3% | 370 |

**Every figure is the baseline's, to the place.**

- **The plots do not change.** Claiming by side changes which drill a kind
  claims, never whether there is one free in a plot, so every plant goes to the
  plot it went to before.
- **The orders do not change the counts.** Sown from the label, a flooded drill
  takes a lily while (8 − reeds) / 2 lilies fit. Sown in pairs, it takes one
  while a whole pair is free, which is the same number. `SeedbedTests` checks
  this.

**Why option A cannot honestly reduce the 370 empty places.**

- They are drills claimed by kinds that come rarely: a kind that arrives once
  claims eight places and holds one.
- Which drills are claimed, and how full each gets, depends only on the arrivals
  and the claim rule. It does not depend on where the drills lie or which plot
  they are in. So no arrangement of drills changes it.
- Only a different claim rule or shorter drills would.
  - The same arrivals with **eight drills of six** leave **239** empty, in 33
    plots rather than 36. But eight drills at 0.74 m do not fit the bed.
  - Letting kinds share a drill is the rule Marcus chose against.

Neither was built.

Measured on the 500 arrivals of `SeedbedTests`:

- three stems stand inside a lotus's pads, where one did. Two are reeds sown
  in the place beside a lily's pair, each nudged toward the lily, 0.69 m from
  its stem. That is the lotus rule's 0.78 m less two nudges, and the widest
  tenth of pads reach it. The straight bed's sample happened not to put a reed
  there.
- The test's bar is 1% (five); three is under it.

## Renders

From `/dev/seedbed` on a local server, headless, cropped to the plot. These are
the same plants before and after:

- `seedbed-before-10.jpg`, `seedbed-after-10.jpg`: plot 0 after 45 arrivals,
  ten places held (new kinds open new plots, so plot 0 grows slowly).
  - Before, every plant stands at the labelled north end and the flooded drills
    are interleaved with the dry.
  - After, the water lies together at the foot of the bed, and each drill's
    plants stand from its middle.
- `seedbed-before-full.jpg`, `seedbed-after-full.jpg`: plot 3 of 500, a
  settled plot, mirrored after.
- `seedbed-before-three.jpg`, `seedbed-after-three.jpg`: plots 3, 4 and 5 side
  by side. A bed is shown one plot at a time; after, they alternate,
  mirrored, plain, mirrored.

## What a replant needs

**A deploy re-lays every existing Seedbed plot by itself, but only a replant
gives the old plots the new order.**

- The service works out each plant's spot when it serves it, and a stored
  `slot_index` still means how far along its drill from the label.
- So on the day the code goes live, every old planting moves onto its place on
  the curved drill, odd plots mirrored. No two collide, and none moves to
  another drill.
- The old plots keep their old claims and their old sowing: flooded drills
  wherever they were first claimed, and drills sown from the label.
- New arrivals into an old plot are placed correctly, because the rule finds
  the next free place in the new order whatever is already held.

`tools/replant` replays every arrival through `Seedbed.Ways` and writes the same
columns (`drill`, `slot_index`, `slot_span`, the nudge), with no schema change.

- Capacities are unchanged, and **so is plot assignment**: the replay puts
  every planting in the plot it is in.
- Only the drill and the place within the plot change.

## Left open

- **The drills curve gently**, bowing 0.17–0.30 m over 3.6 m. Six drills 0.74
  m apart fill 3.7 m of the bed's depth, which leaves room for no more bow
  inside the bed. Seen from the page's eye the flooded drills read as arcs;
  the dry drills read nearly straight. A stronger curve needs a narrower gap
  between drills, which is Marcus's number. **Answered the same day:**
  *Curved more*, below.
- **A drill of two looks lopsided**: the middle and one end, which is what
  focal-first, then farthest-first, gives on a row. From three up it is
  balanced. A lily's second pair can stand by the label for the same reason.
- **The map glyph** needs no change. The glyphs stay symbolic (Marcus, 28
  September).
- `docs/WEB-GARDENS.md` §*The Seedbed, built* describes the straight drills,
  *filling from the labelled end* and the label at the north end, and needs
  folding in.
