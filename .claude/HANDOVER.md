# The Garden screen — handover 18 September 2026

## Goal

Turn the app's Garden screen from a grid of tiles into a place: a floating
square plot in isometric that the person arranges their own plants on, with a
choice of ground and a sun and moon going round it.

## State

**Done and verified, and looked at on a simulator.** The Garden screen is the
plot: a floating square plot in isometric, standing on one of eight worlds, with
the plants at their real relative sizes standing on the terrain, a pool of light
under anything that has changed since it was last opened, and a row of little
worlds to choose the ground from, and the sun and moon going round it on the
real clock. Thematic no longer stands one plant inside another. 56 app tests,
from 35; SeedCore at 106. Four commits on `main`, not pushed.

**Done, not built into the app.** The gestures. The
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
| `App/PeaceGarden/Rendering/GardenGround.swift` | The cut, the light, the saturation ceiling, and the flat plot that is the fallback. |
| `App/PeaceGarden/Rendering/GardenWorlds.swift` | The eight grounds, as height and colour per cell. |
| `App/PeaceGarden/Rendering/GardenTerrain.swift` | The plot drawn as a mesh, off the main actor and kept. |
| `App/PeaceGarden/Rendering/GardenLight.swift` | The orbit, and tonight's moon. Read by everything. |
| `App/PeaceGarden/Rendering/GardenSky.swift` | Space, the stars, and whichever body is up. |
| `App/PeaceGarden/Resources/Worlds/` | The two textures, 276 KB, straight from the mockup. |
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

## Terrain: done

Eight worlds, from the mockup's own two textures — 128 by 128 cells each, height
packed sixteen-bit into the red and green bytes, albedo as plain RGB. A world
ships as what it is rather than as a picture of itself, so the light is applied
where the ground is drawn; that is what lets the orbit move without eight times
twenty-four renders.

The ground is **chosen**, and the choice is `Bed.world` — optional, so nothing
migrates. Growing it from the gardener's seed was the alternative and was
rejected on ARRANGING.md's own opening line. A world is a number because a world
has no name, which makes the atlas's row order part of the file format: add at
the end, never reorder.

Two faults, both found by looking:

1. **The ravine came out as a lattice of black diamonds.** A world's colour is
   stippled — that is what gives strata and scree their grain — and a mesh
   coarser than the atlas reads one cell per quad, so each quad took a dot or a
   gap. The plot is drawn at the atlas's own resolution now, and anything
   coarser averages over the patch its quad covers. **The meadow, having no
   stipple, hid this completely.**
2. **The middle of a quad is not the average of two opposite corners.** Where the
   ground is steep that point sits off the surface, so the march for shade
   started underground. Flat ground agrees, so the meadow hid this too.

Drawing sixteen thousand quads is about half a second, which inside `body` is
half a second of frozen phone. `GardenTerrain` is an actor: the screen appears at
once and the ground arrives a beat later.

## The orbit: done

One light, because exactly one body is above the horizon at any hour: the sun up
from 06:00 to 18:00, the moon the other twelve, each rising at one corner of the
plot and setting at the opposite one. `GardenGround.Light.at(hour:)` is the whole
model, and the ground, the plants, the shadows and the sky all read it — which is
what stops a plant being lit from a different hour than the ground it stands on.

- **The ground** is re-shaded at the hour, cached on the light as well as the
  size. The terrain shadows itself along the light direction.
- **The plants** are rendered at eight points round the clock and crossfaded
  between the two the hour falls between. **They were studio-lit until now** —
  `PlantSceneBuilder.makeScene` is one hard key, a cold rim and a near-black
  ambient, which is right for a plant photographed for a box and is why the
  plants looked pasted onto the ground. They take the garden's own light now.
- **The shadows** are a shear of the sprite, blackened: a point `v` points up the
  picture is `v / pointsPerMetre` metres up the plant, and its shadow lands that
  height over the light's slope away across the ground. One affine transform, no
  second drawing.
- **The sky** darkens with the hour, the stars come out and are fixed rather than
  drifting, and the moon carries its real phase for the date.
- **Night falls by the clock, with an override** — `GardenDaylight` in Seed. It
  changes the light and nothing else, so a night-opening flower is still open at
  two in the morning under a noon sun.

Two things worth knowing. **The shadow goes flat twice a day**: at noon and
midnight the body is at the azimuth where a shadow runs along the screen's
horizontal, and a shadow with no screen height is a line. It is what an
isometric view of that moment is, not a bug. And **`Light.noon` is spelled out
rather than computed**, because it is a default argument in `GardenGround.swift`
while the orbit is an extension in `GardenLight.swift`, and the compiler will not
reach across for it in that position; a test holds the two to each other.

## Next step

The gestures, which is the last part of `docs/ARRANGING.md` that is designed and
not built: pinch to zoom, two-finger rotate in ninety-degree steps, and **long
press to lift a plant, then drag**. The design is in §*Turning it* and §*One
finger cannot do two things*, and the reasoning is settled — every plant is a
meeting, so an accidental nudge is a worse failure than waiting a beat.

What is not settled and has to be before rotation is built: **how the plants are
drawn when the plot is turned**. Four renders each at ninety-degree steps, or
billboards that always face the viewer. It now costs four times eight, because a
sprite is already rendered at eight hours.

`Isometric.ground(at:)` is the inverse the dragging needs, and it is exact on
flat ground. Over terrain it has to run twice — once at ground zero, once with
that place's own height subtracted — which `docs/ARRANGING.md` §*A plant stands
on the ground* sets out and which nothing has needed yet.

## Traps

- **A world's colour is stippled, so never point-sample it at a coarse mesh.**
  The grain is the texture; one cell per quad is either the grain or a lattice of
  holes, depending on whether the mesh matches the atlas.
- **The meadow hides terrain faults.** It has almost no relief and no stipple, so
  it draws correctly under arithmetic that is wrong. Check a new world drawing
  against the ravine or the alpine, never against the meadow.
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
