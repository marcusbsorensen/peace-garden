# The Home Ground, built: lazy beds that follow the land

Option A of `RESEARCH.md` §*The Home Ground*, as Marcus chose it on 2 October
2026. Built on the layouts foundation (`tools/layouts/`). Plots vary by their
number, mirrored only, as decided.

## What was built

**The rule did not change.** The crop claims the bed, tall plants come from
the north end and short from the south, a crop's own spacing, 27 spires, 14
umbels or 30 rosettes to a bed. Re-recorded, the 500 vector rows keep every
plot, bed, crop, index and nudge they had; each row only gains its plot's
variant and its spot.

- **The beds sway together in a lazy S**: 0.10 m west in the north half and
  0.10 m east in the south, straight at the two ends and the middle, shaped
  `u (1 − u²)²` so they leave each headland square to it. The middle bed sways;
  the other two are its line moved 1.65 m sideways, square to it all the way,
  so the paths stay 0.45 m (0.44 to 0.46) where the beds lean as well as where
  they run straight. Each bed then strays up to 1 cm off the S on its own, as a
  spade leaves a ridge. They lean at most 8.5°.
- **0.10 m is as far as they can sway with the beds and paths as wide as they
  were.** The research's sketch swayed them 0.34 m, which carried the outer
  bed off the slab. Here the outer edge reaches 2.35 m out, plus the drawing's
  wander, inside the 2.38 m the slab's edge can come to.
- **Rows run square to the curve**, `rowGap` apart along the bed's line,
  centred on it, so every crop's rows still span 3.6 m of it and three beds of
  three crops end level. On the inside of a bend a row's outer places draw a
  little closer: closest spires 0.39 m (0.40 straight), umbels 0.53 m (0.60),
  rosettes 0.33 m (0.38). The rows near an end lean too, so a row's end place
  comes to 0.22 m from the bed's end (0.275 before).
- **The tables**: one per crop, `tools/layouts/tables/home_ground_{cer,fen,pell}.py`,
  because two crops' places can fall on one point and a table holds a point
  once; and `home_ground_beds.py`, each bed's middle and its line, which the
  page reads. The geometry is shared in `_home_ground.py`, which the generator
  does not take for a spec.
- **Plots alternate, mirrored and not** (`HomeGround.variants`, a space of
  two, as the foundation deals it): one plot sways one way and the next the
  other, and the trough at the foot of a path changes side with it. North
  stays north, so every bed's tall end does.
- **The nudge is added before the mirror**, in the table's frame, so the
  narrower nudge down the bed turns with its row: `spot = variant.apply(place +
  nudge)`, in the Swift, the port (`HomeGround::spotOf`) and the store.
- **The page** (`ground.js`) raises each bed along its line, its width square
  to it, laid as the plot's variant (`pg_plot_variant`) before the plants are
  grown; sown beds are read off the spots as before, by the nearest line. **A
  bed's side wanders 2.5 cm now, not 4.5**: the S is the bold curve and this is
  the fine wander on it (RESEARCH.md §*A bold curve, finely wandering*), and
  the outer beds need the room.
- `check_home_ground.php` compares each row's variant and spot exactly, and
  checks every crop's rows span 3.6 m of every bed's line with each row's
  middle on it.

## Measured on real plants

`swift run -c release --package-path tools/layouts/harness layouts-harness
--area ground --against tools/layouts/baseline.json`: **no figure moved.**

| Arrivals | Plots | Held | Settled plots | Held in settled | Empty in settled |
|---|---|---|---|---|---|
| 10 | 1 | 11 of 71, 15.5% | 0 | — | — |
| 100 | 2 | 101 of 129, 78.3% | 0 | — | — |
| 1000 | 16 | 1001 of 1039, 96.3% | 14 | 100.0% | 0 |

The same as the baseline at every count: the rule, the capacities and the
slots are unchanged.

## What a replant needs

**Nothing.** Capacities and plot assignment are unchanged, and the service
works out each planting's spot when it serves it, from the plot, bed, crop,
slot and nudge it stores (`HomeGroundStore::planting`), so a deploy re-lays
every existing plot by itself, mirrored plots included.

## Left open

- **How bold a sway.** 0.10 m reads as a gentle S in the renders. For more,
  something has to give: paths of 0.40 m would allow about 0.15 m, beds of
  1.1 m more. Both are numbers Marcus settled on 24 September.
- **The trough stands square to the plot**, not to the path: the path runs
  straight where it stands, so it fits, but `raiseTrough` has no turn if the
  sway is ever made bolder.
- **The map's glyph** for `ground` (`gates.js`) still draws three straight
  beds. Not touched: it is shared.
- `docs/WEB-GARDENS.md` §*The plot* says the outermost bed is 0.35 m inside
  the plot and a bed's side wanders 4.5 cm; these notes are for folding in.

Renders: `ground-before-10.jpg`, `ground-after-10.jpg` (plot 0, ten plants),
`ground-before-full.jpg`, `ground-after-full.jpg` (plot 3 of the workbench's
500, mirrored), and `ground-before-three.jpg`, `ground-after-three.jpg` (plots
3, 4 and 5: mirrored, plain, mirrored).
