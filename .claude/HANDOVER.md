# The Garden screen — handover 17 September 2026

## Goal

Turn the app's Garden screen from a grid of tiles into a place: a floating
square plot in isometric that the person arranges their own plants on, with a
choice of ground and a sun and moon going round it.

## State

**Done and verified, and looked at on a simulator.** The Garden screen is the
plot. Flat ground, noon light held still, plants standing on it at their real
relative sizes, and a pool of light under anything that has changed since it was
last opened. Thematic no longer stands one plant inside another. 49 app tests,
from 35; SeedCore untouched at 106. Two commits on `main`, not pushed.

**Done, not built into the app.** Terrain, the orbit, and the gestures. The
interactive Design canvas remains the reference:
https://claude.ai/artifact/JtRewHDMGQJJTPnKvS5Tru — eight worlds, drag a plant,
hour slider, orbiting sun and moon with cast shadows, real moon phase. Its
numbers are now written down; see *What the mockup actually says* below.

**Unchanged and still outstanding** — the language work. 41 named maps to place.
`Server/strings/da.json`'s `read` block is **not** missing, contrary to the
previous handover: it is filled, by Marcus, 6 September, covering the ten area
names. What Danish still needs is its *prose*. See
`docs/COMMISSIONING-THE-READS.md`, which is current.

## Files

| | |
| --- | --- |
| `docs/ARRANGING.md` | The whole design, updated with what was settled and measured today. |
| `App/PeaceGarden/Arranging/Isometric.swift` | The projection, its inverse, and the fit to a viewport. |
| `App/PeaceGarden/Rendering/GardenGround.swift` | The plot, the cut, the light, and the saturation ceiling. |
| `App/PeaceGarden/Rendering/GardenSprites.swift` | Plants as stills at one shared scale. **Not `ThumbnailRenderer`** — see below. |
| `App/PeaceGarden/Views/PlotView.swift` | The screen. |
| `App/PeaceGarden/Views/GardenVisits.swift` | What has changed since a plant was last opened. |
| `App/PeaceGarden/Views/GardenView.swift` | One line: the plot, or the grid behind the developer switch. |
| `App/PeaceGarden/Views/GardenGridView.swift` | The old grid, kept as the control. |
| `App/PeaceGardenTests/PlotTests.swift` | 12 tests. Three of them found real faults on the first run. |

## What the tests found, which no render would have

All three looked like a plausible garden.

1. **The tallest plant is 2.36 m, not 1.36 m.** `ARRANGING.md` records the range
   as 0.46–1.36 m and calls it real, which it is — of the mockup's fourteen
   crossings. Across a hundred and twenty it goes three quarters of a metre
   higher. A fixed sprite frame cut that plant's head off, and a plant with its
   head cut off looks like a tall plant. Frames are per plant now.
2. **The viewport fit took the plot's vertical span as half what it is.** On a
   phone the width binds and the height is never asked, so it was invisible; on a
   landscape iPad the far corner's plant sat 125 points off the top of the screen.
3. **`.position` makes a view fill its parent**, so a tap attached outside it
   answers anywhere. The last plant drawn swallowed every tap in the garden,
   including the ones meant for the plants under it.

## What looking found, which no test would have

1. **A first-opened garden lit every plant.** With nothing remembered, every
   plant has changed, and a garden where everything is lit says nothing about any
   of it. `GardenVisits.firstSight` takes the whole garden as seen the first time
   it is opened, which is also true: nothing has changed since a visit that never
   happened.
2. **The pool wanted setting twice.** At 0.26 it was brighter than the plant
   standing in it; at 0.15 a single announcing plant in a garden of fourteen
   could be missed entirely, which is the whole job. It is 0.22.

## Decisions made today

- **What announces a plant that has changed: the light finds it.** The last of
  `ARRANGING.md`'s open questions about replacing the grid. Two things it turns
  on: *opened*, not merely on screen; and growth only, **never** the bloom —
  `diurnalFactor` would otherwise light two thirds of the garden every evening.
- **The saturation ceiling is 0.28.** A decision, not a measurement: the
  generator that held the original number was never committed. Every ground
  colour passes through one function, so a material written too bright later
  cannot quietly take `Chrome`'s rule away.
- **The grid is kept and reachable from the developer section**, not deleted. It
  is the only thing there is to judge the plot against, and the judgement has to
  be made on a real garden. It stays compiled in Release on purpose: `#if DEBUG`
  would take `tile.caption` out of the catalogue, and a catalogue entry here is
  forty-two translations.

## What the mockup actually says

Recovered from the canvas and now matched exactly, so a spot placed there lands
in the same place here.

| | |
| --- | --- |
| Projection | `sx = (x - z)·cos30·PPM`, `sy = ((x + z)·sin30 - y)·PPM`. Depth order `x + z`. |
| Scale | 42 px/m on a 390-wide canvas; the app fits instead, and comes to 41.5. |
| Plot | 5.2 m, diamond 378 × 218 px. |
| The cut | `0.40 + 1.70·(1 - r^1.7)^0.85` on the Chebyshev radius. **At the rim that is 0.40 everywhere**, so the visible skirt is a constant 0.40 m and the bulge underneath is never drawn. |
| Cut soil | `[0.215, 0.185, 0.160]`, shaded with a fixed shadow term of 0.55. |
| Light | Noon `[-0.332, 0.883, 0.332]`, strength 0.76, sky `[0.40, 0.48, 0.60]`, bounce `[0.27, 0.25, 0.20]`, `pow(key, 0.9)`, `0.18 + 0.82·shadow`. |

## Next step

**The terrain, then the orbit** — in that order, because the orbit is what stops
the ground being a picture and there has to be a ground first. `GardenGround` is
written against a height at a place rather than against zero, so a heightmap
drops in without the drawing changing shape; `nearFaces` already samples along
the rim for exactly that reason.

## Thematic crowding: done

Settled and built, 18 September. An area is 0.92 m wide and a plant is up to a
metre across, so scattering plants inside an area stood them inside one another —
7.5 cm apart on the first garden drawn. Spreading cannot fix it: over forty
gardens of fourteen, independent scatter leaves 82 pairs under 20 cm and a cloud
2.9 m across still leaves 37, because two seeds know nothing about each other.

An area's members are now ranked by seed hex and laid down its depth. Closest
pair 0.217 m, pairs under 20 cm none. It costs the one thing: a plant joining an
area re-spaces that area — about three plants in fourteen, by at most 0.43 m.
Nothing outside the area moves, and no spot anywhere depends on arrival order,
which is the trap the old rule was actually guarding.

`testAddingAPlantDoesNotMoveTheOnesAlreadyThere` now exempts Thematic alongside
Meetings, and two tests hold what replaced it:
`testAPlantJoiningAnAreaDisturbsOnlyThatArea` and
`testThematicNeverStandsOnePlantInsideAnother`, the second over forty gardens
because one garden is what let the fault through the first time.

## Traps

- **`ThumbnailRenderer` is the wrong renderer for a garden.** It frames every
  plant against its own mature bounds so each fills its tile, which is right for
  a grid and is the one thing a garden must not do. `GardenSprites` is
  orthographic and fixed. Do not "simplify" one into the other.
- **`Arrangement.spots` is keyed by `UUID`; `Bed.placed` is keyed by
  `uuidString`.** Opposite on purpose — `JSONEncoder` writes a non-String-keyed
  dictionary as a flat array.
- **`Garden.arrangements` mints a fresh `UUID` on every access** when `beds` is
  nil, so it must not be used as SwiftUI identity.
- **`UserDefaults` written by the app is lost if the simulator process is
  killed within a few seconds.** Two hours went on a pool of light that was
  working the whole time. Wind the state in with
  `xcrun simctl spawn booted defaults write app.peacegarden …` rather than
  reading back what the app wrote.
- **`Quotes.theme(of:)` is wrong for arranging.** Use `Arrangement.theme(of:)`.
- **Anything derived from a plant's index reshuffles the garden** when a plant is
  added. Derive from the seed. `Meetings` is the one exemption.
- **`swift test --package-path Packages/SeedCore` takes ~150 s.** App tests:
  `xcodegen generate` then `xcodebuild test -scheme PeaceGarden -destination
  'platform=iOS Simulator,name=iPhone 17 Pro'`.
- Older traps — simulator, deploy, `AREA_KEYS`, the mesh pin — are in
  `docs/HANDOVER.md` and still apply.

## Looking at it yourself

There is a garden fixture — fourteen real crossings against four peers, births
spread over four months — built by a throwaway SwiftPM tool in the session
scratchpad. It is **not in the repo**; rebuilding it is twenty minutes, and the
one thing worth keeping from it is that `GardenStore.defaultStore()` reads
`$(xcrun simctl get_app_container booted app.peacegarden data)/Library/Application
Support/PeaceGarden/garden.json`. The garden screen opens directly with
`xcrun simctl launch booted app.peacegarden -pgOpen garden`.
