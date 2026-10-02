# Layouts: place tables, plot variants and the fill harness

The shared parts for the ten areas' new layouts (Marcus, 2 October 2026:
`design/garden-layouts-2026-10-02/RESEARCH.md`, every area option A). An area
agent builds its layout on these:

| Part | Where |
|---|---|
| Place tables, made offline | `generate.py`, `places/`, specs in `tables/` |
| A table in SeedCore | `PlaceTable` (`WebGardens/PlaceTable.swift`), tables in `WebGardens/Tables/` |
| A table in the service and the page | `Server/.api/tables/<Name>Table.php`, `Server/assets/js/tables/<name>.js` |
| A plot's variant | `PlotVariant` (`WebGardens/PlotVariant.swift`), `Server/.api/PlotVariant.php`, `Server/assets/js/variant.js`, `pg_plot_variant` in the module |
| The fill harness | `harness/`; today's figures in `BASELINE.md` and `baseline.json` |

Places are metres from the plot's middle, north (`z−`) up the page. A quarter
turn takes `x+` to `z+`, as `Organic.outline` runs.

## 1. Write a table

One spec per table, `tables/<name>.py` (lower case and underscores; an area's
own tables start with its name, `coppice_glade`). `tables/example.py` is one.

```python
"""What the table is for: the first line and the paragraph become its doc comment."""
from places import Layout, shapes, sample, order

FIELDS = ('coupe', 'kind')   # the integer tags every place carries, in order
NUDGES = 3                   # feature variants: the area's `nudges`
JS = True                    # also write Server/assets/js/tables/<name>.js
MIN_SPACING = 0.40           # optional: fail if two places are closer
# BOUND = 2.6                # places stay within ±BOUND in x and z
# SAME_COUNT = True          # every variant the same number of places

def build(nudge):
    glade = shapes.blob((0.2, -0.1), (0.6, 0.5), seed=('glade', nudge), wander_by=0.06)
    ...
    return (Layout()
            .add(order.focal_first(stools, focal), coupe=0, kind=0)
            .curve('glade', glade))
```

What `places` offers:

- **Outlines** (`shapes`): `blob` (an ellipse whose edge wanders), `spline`
  through control points, `wander` any closed curve, `ellipse`, `circle`,
  `arc`, `offset`, `turned`, `scale`, `move`; and `inside`, `distance_to`,
  `centroid`, `area`, `length`, `point_at`, `resample`.
- **Places** (`sample`): `blue_noise(region, spacing, seed, count=…, margin=…,
  keep=…)` is Bridson inside an outline, exactly `count` if asked;
  `sunflower(centre, c, count, region=…)` is Vogel's spiral, neighbours about
  1.8 c apart, centre first; `along(curve, count, offset=…)` and `ring(…)` put
  places along a curve.
- **Fill order** (`order`): `focal_first(points, focal)` is the move Marcus
  chose: the place nearest the focal point, then farthest-first.
  `centre_first` for a spiral; `within(points, group, then)` when the rule
  picks a group (a guild, a coupe) before a place; `interleave` for groups
  filled level. **A rule takes the first free place in table order it may
  stand in**, so the order is the table's.
- **Numbers** (`numbers`): `cos_sin(turn)`, `turn_of(x, z)`, `bump`, `smooth`,
  `Rng(*seed)`. Use these, never `math.sin`, `math.atan2`, `math.exp`,
  `math.hypot`, `**` with a float, `random`, or `sum()` over floats (Python
  3.12 changed its rounding): those are the C library's or the interpreter's,
  and `--check` has to get the same bytes on Linux and in any Python.

## 2. Make it, look at it, commit it

    python3 tools/layouts/generate.py                 # write every table
    python3 tools/layouts/generate.py --draw DIR      # and an SVG of each variant
    python3 tools/layouts/generate.py --list
    python3 tools/layouts/generate.py --check         # what CI runs

Places are written to the millimetre. Never edit a generated file: `--check`
fails CI on any byte that is not what its spec makes, on a file whose spec
has gone, and on PHP or JavaScript that does not parse. Look at the drawing
before asking Marcus anything, and show him a render, not a table.

## 3. Read it in the rule, the service and the page

- **Swift:** `PlaceTable.coppiceGlade.places(nudge:)` in fill order;
  `table.tag("coupe", of: place)`; `table.spot(i, on: variant)` is place `i`
  turned for the plot; `table.curve("glade", on: variant)`.
- **PHP:** `require_once __DIR__ . '/tables/CoppiceGladeTable.php'`;
  `CoppiceGladeTable::PLACES[$nudge][$i]` is `[x, z, coupe, kind]`;
  `CoppiceGladeTable::CURVES['glade'][$nudge]` is `[closed, [[x, z], …]]`.
- **JavaScript:** `import { coppiceGlade } from './tables/coppice_glade.js'`,
  the same shape as the PHP. Only for what the drawing needs; the service
  already sends each planting's spot.

A table of one variant answers every nudge, so a table that does not change
with the plot sits beside ones that do.

## 4. Vary the plot

Each area declares how its plots vary in its own file, and nothing reads it
yet: `Coppice.variants` in Swift, `Coppice::VARIANTS` in PHP. Today's, as
proposed (change them as the layout needs, in both, in the same commit):

| Space | Areas |
|---|---|
| fixed | Knot Garden, Glasshouse (Marcus's decision) |
| turned 4 ways and mirrored | Quiet Garden, Crossing, Orchard, Coppice |
| half turn and mirrored | Long Walk (the path stays where it runs) |
| mirrored only, so alternating | Seedbed, Cold Frame, Home Ground |

`nudges` is 1 everywhere until an area's tables have feature variants; set it
to the spec's `NUDGES`.

- **Swift:** `PlotVariant.of(plot:area:)` → `turn` (0…3), `mirror`, `nudge`.
  `variant.apply(spot)` turns a place, exactly; `undo` turns it back.
- **PHP:** `PlotVariant::of($plot, 'renewal', self::VARIANTS)`,
  `PlotVariant::apply($variant, $x, $z)`.
- **JavaScript:** `variantFromModule(engine, 'renewal', plot)` asks the plant
  module, so the page keeps no copy of a space; `plotVariant(plot, area,
  space)` if the service sends the space; `applyVariant`,
  `applyVariantToCurve`. Mirroring reverses which way a closed curve runs.

What the deal promises: plot 0 is plain (the plan as drawn); no plot is laid
as the plot before it; every block of `count` plots holds every variant; a
space of two alternates. Add the seed's nudge in the table's frame and turn
the sum, so a nudge that is narrower one way (the Home Ground's) turns with
its row: `variant.apply(place + nudge)`.

## 5. Pin it

- The tables pin themselves: `generate.py --check` in CI.
- The variant function is pinned by `PlotVariantVectorTests`,
  `check_plot_variant.php` and `check_plot_variant.mjs`, over every space.
  **Your area's own plots are not**: when the rule or its port reads the
  variant or a table, add `"variant":[turn,mirror,nudge]` and the spot to each
  row of the area's vector file, compare them in `check_<area>.php`, and
  re-record (`PEACE_GARDEN_RECORD_VECTORS=1 swift test --filter <Area>VectorTests`).
- A spot from a table and a variant is exact on every host, so the vectors
  compare it with no tolerance. Only a height needs one.

## 6. Measure the fill

    swift run -c release --package-path tools/layouts/harness layouts-harness \
      --area coppice --against tools/layouts/baseline.json

prints plots, places held and the settled plots' fill at 10, 100 and 1,000
arrivals, each moved figure as `new (old)`. The first run grows the stream
(about half a minute for all ten); later runs read it back. `--at 10,100,2000`
measures elsewhere, `--save FILE` keeps the figures. It links this checkout's
SeedCore, so it measures whatever the rule now is. If the rule's types change,
its adapter is `harness/Sources/LayoutsHarness/Areas/<Area>.swift`.
