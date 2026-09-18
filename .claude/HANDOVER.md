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
real clock, the Milky Way overhead, lights to put out, and the gestures to
arrange all of it, and glow-in-the-dark figures. 73 app tests, from 35; SeedCore 110, from 106. Pushed to
`origin/main` at `7417653`; one commit after it.

**Done, not built into the app.** Nothing from the mockup is left. The
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
| `App/PeaceGarden/Rendering/GardenLamps.swift` | The lights people put out: how each looks, reaches, and lifts a plant. |
| `App/PeaceGarden/Rendering/GardenCreatures.swift` | The glow-in-the-dark figures: modelled, lit, and their glow. |
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

## What 18 September also settled

- **A turned plot turns its plants: four renders each at ninety degrees**, not
  billboards. `GardenSprites.sprite(genome:growth:step:turn:)` takes it, and the
  turn is of the **plot's own axes** — the plant and the light rotate together,
  because the sun goes round the plot rather than round the screen. Nothing calls
  it with a turn yet; the gesture is what will.
- **The cut is a bank of earth, 0.95 m deep**, drawn in coarse cells: humus,
  earth, rock, stones, and a floor ragged by a few centimetres.
- **The sky is blue by day and a deep blue by night**, rather than the mockup's
  near-black at every hour.

## Also done 18 September

- **The Milky Way**: a cool light from straight overhead at every hour, fading
  with the sun and noticed only after dark. The moon's curve is unchanged and
  still pinned; the garden is now visible at 18:00, the darkest hour.
- **The gestures**, driven on a simulator with injected touches: long press to
  lift a plant (a third of a second, a tap of feedback), quarter-turns with two
  fingers, pinch to 3×, pan once zoomed. The inverse under a finger is a march
  down the sight line, not the two passes `ARRANGING.md` said were enough — on a
  steep peak two ground places sit under one screen point, and a fixed-point
  search found the hidden one.
- **Lights**: lanterns, paper lamps and fireflies, put out from the row at the
  bottom, carried by a long press, taken away by being carried off the edge.
  Pools on the ground, a lift on nearby plants. On `Bed.lamps`, with the kind
  stored as a string so a garden from a later build still opens.

## Next step

**Glow-in-the-dark animals: done.** A hare, a fox asleep, a moth on a stake and
a snail, modelled in SceneKit and rendered like the plants — `GardenCreatures`,
and `ARRANGING.md` §*The glow-in-the-dark figures*. Four new `LampKind`s, added
at the end. Pale figures by day; the paint glows as the garden goes dark. Looked
at on a simulator by day and by night. `CreatureTests` checks that no figure is
clipped by its frame at any facing. It found the snail's feelers going off the
side at two facings.

**Put it back is done**: carry a hand-placed plant off the edge of the plot and
it goes home to where its arrangement puts it — the same gesture that takes a
light away, so off the edge always means *give this up*.

**Still open:**

- **What zoom is for** is still unanswered; 3× is the cap until it is, and at 3×
  the ground's cells begin to show. The figures are rendered at 260 points a
  metre, so they hold up at 3× better than the plants do.
- **The figures' light on the plants is the lamps' lift**, which is a tint added
  over the plant. It is faint, set by `pool` and `reach`. Nobody has yet judged
  whether a hare beside a white flower should show on the flower at all.

## Traps

- **A plant's frame is mostly air.** Anything that answers a touch across the
  whole frame steals touches from whatever stands behind it. `Sprite.opaque` is
  the box the leaves actually occupy; use it.
- **A circular gradient in a flattened ellipse is a hard-edged disc.** Anything
  lying on the ground fades with `EllipticalGradient`.
- **A cut face is vertical, so it is lit by the sky and by almost none of the
  sun.** Materials for it have to be picked at about half again the brightness
  they look right at on their own, or the bank comes out black.
- **A world's colour is stippled, so never point-sample it at a coarse mesh.**
  The grain is the texture; one cell per quad is either the grain or a lattice of
  holes, depending on whether the mesh matches the atlas.
- **The meadow hides terrain faults.** It has almost no relief and no stipple, so
  it draws correctly under arithmetic that is wrong. Check a new world drawing
  against the ravine or the alpine, never against the meadow.
- **A figure's foot is `lift` up its picture, not on the bottom edge.** Anything
  that places, shadows or hit-tests a figure has to use it. The frames are sized
  by `CreatureTests`, which fails with the edge that is cut; change a model, run it.
- **Launch at night with** `xcrun simctl launch booted app.peacegarden -pgOpen
  garden -developer.clockShift 43200` — the developer clock, twelve hours on.
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
