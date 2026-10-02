# How the ten areas fill today, 2 October 2026

The figures every area's new layout is compared with: **today's rules, before
any area's layout changed**, run by `tools/layouts/harness` over SeedCore's own
plants. The same figures, as the harness saves them, are `baseline.json`
beside this file, so

    swift run -c release --package-path tools/layouts/harness layouts-harness --against tools/layouts/baseline.json

prints each figure that has moved as `new (old)`.

Measured at `c274aa3`, whose rules are those of `dec6a5c` (main, 2 October):
the variant spaces and the place tables added since are not read by any rule
yet.

## The stream

Strangers' crossings, `layouts-stranger-<n>-a` × `-b`, each child grown by
SeedCore and filed in the area its genus head names, as the live garden files
it. Each area receives the first thousand that land in it, after its
ambassador. All ten streams come from the same crossings, so an area measured
again after its layout changes is measured on the same plants.

| Area | Habits in its thousand | Median height |
|---|---|---|
| Long Walk | vine 284, thistle 271, plume 257, cushion 188 | 0.94 m |
| Quiet Garden | poppy 511, plume 489 | 0.92 m |
| Crossing | bell 370, orchid 346, cushion 284 | 0.77 m |
| Orchard | thistle 504, vine 496 | 1.20 m |
| Knot Garden | bell 513, umbel 487 | 1.01 m |
| Seedbed | succulent 274, lotus 274, spire 196, reed 256 | 0.44 m |
| Cold Frame | lotus 359, fern 329, reed 312 | 0.47 m |
| Glasshouse | poppy 342, star 340, orchid 318 | 0.93 m |
| Coppice | star 534, fern 466 | 0.67 m |
| Home Ground | succulent 399, umbel 310, spire 291 | 0.71 m |

## The figures

- **Places held** counts places, not plants: a lotus in the Seedbed or the Cold
  Frame takes two.
- **Places** are those a plant of the area's own can take. The Quiet Garden's
  pool is left out, because the live garden never sends that area a lily; the
  Home Ground's are its claimed beds', 27, 14 or 30 by crop, and a bed nobody
  has sown counts for nothing.
- **Settled** is every plot but the newest two, which are where a visitor
  would find an empty place in the old part of an area: the measure the
  Coppice's design and the research used.

| Area | Arrivals | Plots | Places held | Held | Settled plots | Held in settled | Empty in settled |
|---|---|---|---|---|---|---|---|
| Long Walk | 10 | 1 | 11 of 48 | 22.9% | 0 | — | — |
| Long Walk | 100 | 3 | 101 of 144 | 70.1% | 1 | 100.0% | 0 |
| Long Walk | 1000 | 24 | 1001 of 1152 | 86.9% | 22 | 92.2% | 82 |
| Quiet Garden | 10 | 2 | 11 of 20 | 55.0% | 0 | — | — |
| Quiet Garden | 100 | 11 | 101 of 110 | 91.8% | 9 | 97.8% | 2 |
| Quiet Garden | 1000 | 101 | 1001 of 1010 | 99.1% | 99 | 99.7% | 3 |
| Crossing | 10 | 1 | 11 of 24 | 45.8% | 0 | — | — |
| Crossing | 100 | 6 | 101 of 144 | 70.1% | 4 | 87.5% | 12 |
| Crossing | 1000 | 46 | 1001 of 1104 | 90.7% | 44 | 92.6% | 78 |
| Orchard | 10 | 1 | 11 of 20 | 55.0% | 0 | — | — |
| Orchard | 100 | 6 | 101 of 120 | 84.2% | 4 | 98.8% | 1 |
| Orchard | 1000 | 51 | 1001 of 1020 | 98.1% | 49 | 99.9% | 1 |
| Knot Garden | 10 | 1 | 11 of 32 | 34.4% | 0 | — | — |
| Knot Garden | 100 | 5 | 101 of 160 | 63.1% | 3 | 83.3% | 16 |
| Knot Garden | 1000 | 33 | 1001 of 1056 | 94.8% | 31 | 99.1% | 9 |
| Seedbed | 10 | 2 | 11 of 96 | 11.5% | 0 | — | — |
| Seedbed | 100 | 8 | 131 of 384 | 34.1% | 6 | 38.5% | 177 |
| Seedbed | 1000 | 36 | 1275 of 1728 | 73.8% | 34 | 77.3% | 370 |
| Cold Frame | 10 | 2 | 11 of 126 | 8.7% | 0 | — | — |
| Cold Frame | 100 | 4 | 101 of 252 | 40.1% | 2 | 69.0% | 39 |
| Cold Frame | 1000 | 18 | 1001 of 1134 | 88.3% | 16 | 94.4% | 56 |
| Glasshouse | 10 | 1 | 11 of 32 | 34.4% | 0 | — | — |
| Glasshouse | 100 | 4 | 101 of 128 | 78.9% | 2 | 96.9% | 2 |
| Glasshouse | 1000 | 33 | 1001 of 1056 | 94.8% | 31 | 98.7% | 13 |
| Coppice | 10 | 1 | 11 of 33 | 33.3% | 0 | — | — |
| Coppice | 100 | 4 | 101 of 132 | 76.5% | 2 | 100.0% | 0 |
| Coppice | 1000 | 31 | 1001 of 1023 | 97.8% | 29 | 100.0% | 0 |
| Home Ground | 10 | 1 | 11 of 71 | 15.5% | 0 | — | — |
| Home Ground | 100 | 2 | 101 of 129 | 78.3% | 0 | — | — |
| Home Ground | 1000 | 16 | 1001 of 1039 | 96.3% | 14 | 100.0% | 0 |

## Against the research's invented plants

The research (`design/garden-layouts-2026-10-02/RESEARCH.md`) simulated each
proposal on invented plants and said its numbers were indicative. On the real
stream, today's rules at a thousand:

- **The same count of plots** in the Quiet Garden (101), the Orchard (51), the
  Knot Garden (33) and the Seedbed (36).
- **Close** in the Crossing (46 here, 47 there) and the Coppice (31, 32).
- **Apart** where the invented heights or habits were furthest from the
  garden's: the Long Walk (24 plots and 92% of settled places held here, 22
  and 99% there), the Glasshouse (33 here against option A's 37), the Cold
  Frame (18, against A's 19) and the Home Ground (16, against A's 19).

So a layout's fill is to be judged against this file, not against the
research's numbers.

## Where today's rules leave settled places empty

Worth knowing before an area changes, so the change is not blamed for it. At
a thousand, the Seedbed leaves 370 settled places empty, the Long Walk 82, the
Crossing 78 and the Cold Frame 56; the other six leave 13 or fewer.

The Seedbed's is by design (`docs/WEB-GARDENS.md` §*The fill, and why it is the
loosest in the garden*): a drill is claimed by its first plant's kind and
holds only that kind, so most drills wait for a kind that comes rarely. The
other three were not looked into here.
