# The Coppice, built: coupes round a glade

Option A of `RESEARCH.md` §*The Coppice*, as Marcus chose it on 2 October 2026.
Built on the layouts foundation (`tools/layouts/`).

## What was built

**The rule did not change.** These all stand as they were:

- thirty-three a plot, three coupes of eleven: five stools and a floor of six;
- ferns to stools in the coupe with fewest, stars to their own row, and one
  fern at most on a coupe's floor;
- the Crossing's loops;
- the rotation, cut one coupe a winter.

Re-recorded, the 500 vector rows keep every plot, slot and nudge they had; each
row only gains its plot's variant and its spot. What changed is where a slot
stands.

- **The table**, `tools/layouts/tables/coppice_glade.py`, written to
  `PlaceTable.coppiceGlade` (Swift) and `CoppiceGladeTable` (PHP). Three
  feature variants, 33 places each.
- **Three rides meet at a small sunny glade** and bend out past the rim. The
  rides bend by up to 18° by their far end. They divide the plot into **three
  coupes of unequal size**: each coupe takes 27–42% of the turn round the
  glade, and the three are never alike. On the plot the coupes hold:

  | Variant | Glade's middle | Coupes' shares of the plot |
  |---|---|---|
  | 0 | (0.21, −0.05) | 30%, 32%, 37% |
  | 1 | (0.05, −0.16) | 34%, 29%, 38% |
  | 2 | (0.03, −0.17) | 27%, 35%, 38% |

- **The stools stand scattered, as a stand.** Blue noise over the whole coupe,
  then the five nearest the coupe's heart are kept: its middle line, 1.55 m out
  from the glade. A stand strung out in a line is refused. They stay at least:
  - 0.55 m from each other;
  - 0.55 m from a ride's line;
  - 0.45 m from a star's place;
  - 0.85 m from the glade's middle.

  The stand fills from its middle outward. **The old order 2, 1, 3, 0, 4 is
  kept as the index a stool is numbered by**: the stool numbered 2 is the
  stand's middle, 1 the next out, and so on. A coupe of three stools is still
  a clump, and every stored planting still means the place it meant.
- **The stars stand in clumps of three along the ride edges, where the light
  is**, one clump by each of the coupe's two rides.
  - The **front row is now the ride's edge**, 0.48 m from its line, for the
    shorter stars. The **back row stands behind it**, 0.90 m from the line, for
    the taller. Seen from the ride, short stands in front of tall. (The back
    row was `z−` of the stools before.)
  - The first clump, 1.05–1.25 m along its ride from the glade, holds two of
    the front row and one of the back. The second, 1.25–1.50 m along the other
    ride, holds one of the front and two of the back.
  - Each row's first place is in the first clump, so a coupe's first two stars
    stand together whatever rows they take. `floorOrder` (1, 0, 2) is kept as
    the indices, as the stools' is.
- **Plots vary by number**: four turns, mirrored, and three feature variants,
  24 in all (`Coppice.variants`, `Coppice::VARIANTS`). Each feature variant
  moves the glade, the rides' angles and the coupes' shares. Plot 0 is the
  table as drawn.
- **The service sends the turned spot** (`Coppice::spot($plot, …)` in
  `CoppiceStore`), and `check_coppice.php` compares each row's variant and
  spot with the Swift's exactly.
- **The page** (`coppice.js`) draws each plot from `pg_coppice_layout(plot)`:
  - the three rides, trodden 0.48 m wide (±12%) with edges wandering 4 cm, off
    the table's lines;
  - the glade, lighter, sunlit and greening, with no drawn edge;
  - each coupe lit by its stage, blending across a ride, with the glade open
    in every year;
  - the spring basin beside the outer end of a ride.

  What the litter reads (the rides, the glade, the coupe's light) is worked
  out at each lattice corner and averaged over a leaf, rather than once a
  leaf.

Spacings and clearances, measured on the table:

| | Variant 0 | Variant 1 | Variant 2 |
|---|---|---|---|
| Nearest two places | 0.460 m | 0.462 m | 0.475 m |
| Stool to stool | 0.58 m | 0.56 m | 0.56 m |
| Stool to star | 0.46 m | 0.46 m | 0.48 m |
| Star to star, in a clump | 0.52 m | 0.52 m | 0.52 m |
| A star's place to its ride's line | 0.45 m | 0.45 m | 0.47 m |
| Least clearance of the worst rim, before the 0.06 m nudge | 0.28 m | 0.31 m | 0.28 m |

Where these stand against the bands:

- The nearest two places were 0.40 m apart in the bands. They are 0.46 m now.
- The widest stool still leaves every floor place more than 0.05 m clear at
  the worst nudge of both, as `CoppiceTests` checks.
- At the worst nudge and the widest ride, a star stands 0.09 m clear of a
  ride's trodden edge, where the bands' straight rides left 0.12 m. A star is
  meant to stand at the ride's edge, in the light, and these rides bend.

## The fill, against the baseline

`layouts-harness --area coppice --against tools/layouts/baseline.json`:

| Arrivals | Plots | Places held | Held | Settled plots | Held in settled | Empty in settled |
|---|---|---|---|---|---|---|
| 10 | 1 | 11 of 33 | 33.3% | 0 | — | — |
| 100 | 4 | 101 of 132 | 76.5% | 2 | 100.0% | 0 |
| 1,000 | 31 | 1001 of 1023 | 97.8% | 29 | 100.0% | 0 |

**Every figure is the baseline's, unchanged**: the rule is the same, so the same
plants land in the same slots.

## Renders

From `/dev/coppice` on a local server, headless, in year 0, cropped to the plot:

- `coppice-before-10.jpg`, `coppice-after-10.jpg`: plot 0 with ten plants;
- `coppice-before-full.jpg`, `coppice-after-full.jpg`: plot 3 of 500, full;
- `coppice-before-three.jpg`, `coppice-after-three.jpg`: plots 4, 5 and 6,
  three identical sets of bands before and three different glades after.

## What a replant needs

**Nothing for this area beyond deploying.** Capacities are unchanged (33 a
plot), and so is plot assignment: replaying the rule gives every stored planting
the plot, coupe, place, index and nudge it already has. The service works out
where a planting stands when it serves it, from its stored slot and its plot's
variant. So **the deploy re-lays every existing Coppice plot at once, with no
row changed**, and `tools/replant` would write the same rows it reads. A
coupe's stage is unchanged, so the cut band of each plot is the same coupe; it
lies round the glade rather than across the plot. Every plant moves on the page
once, on the day the code goes live.

## Left open

- **The ride edges are 3 cm nearer a star than the bands' were** (0.09 m clear
  at the worst, against 0.12 m), because a clump stands at the ride's edge on
  purpose. If a render shows a star's leaves on a ride, the front row can move
  out to 0.52 m.
- **The spring stands beside a ride's outer end** chosen by the table, so it is
  not always the near one before a turn. The old *near ride* had no meaning
  once plots turn.
- `docs/WEB-GARDENS.md` §*The plot* and §*How it reads from the page's eye*
  describe the bands, and need folding in.
