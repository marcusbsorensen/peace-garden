# Peace Garden: web gardens and the Long Walk — handover 18 September 2026

This session covered four areas: glow-in-the-dark figures, zoom, the web gardens design, and the Long Walk. The app's Garden-screen handover it replaces is at `git show 7d5845d:.claude/HANDOVER.md`. Its traps still apply.

## Goal
The website's shared garden should look and work like the app's Garden screen: floating isometric plots, curated **by rule**, one layout per area. The Wild Fields stay uncurated. The design is `docs/WEB-GARDENS.md`, with a shared copy at https://claude.ai/code/artifact/b662a38c-3948-4a53-9e41-084bdea8ee7b

## State
- **Done, tested, pushed** (`6898c8b` is on `origin/main`). SeedCore has 120 tests and the app has 74; all pass.
- **Glow-in-the-dark figures:** hare, fox, moth and snail, each a new `LampKind`. `CreatureTests` checks that none is clipped by its frame.
- **Zoom:**
  - Taps land on a plant's leaves, not the box round them.
  - Carrying something to the screen edge pans the plot.
  - Double tap zooms in on a plant among its neighbours.
  - The ground on screen is redrawn at the zoomed resolution.
  - **The double tap is unverified.** Injected taps come too far apart to register; it needs a real thumb.
- **Long Walk rule** in SeedCore: tiers cut from measured heights, drifts of one colour capped at five, append-only, nothing in front of something shorter. `LongWalkTests`.
- **Long Walk structures** in the app, developer preview only: a mown path, a tall yew behind the far border, a low hedge in front of the near one, and hedge shadows. Checked by eye at midday and at one quarter-turn. **Not checked at night.**
- **Not started:** the browser cannot draw a plant, and there is no plot service, curator tool or Wild Fields.

## Files
- `docs/WEB-GARDENS.md`: the design: ten areas, plots, dressing, the curator tool, the Wild Fields, worn paths, build order. Current.
- `Packages/SeedCore/Sources/SeedCore/WebGardens/LongWalk.swift`: the rule. The tier cut-offs are measured values (see its doc comment).
- `Packages/SeedCore/Sources/SeedCore/Growth/Maturity.swift`: a plant's grown size. It moved here from `PlantSceneBuilder`, which now forwards to it.
- `App/PeaceGarden/Rendering/GardenStructures.swift`: hedges, `MownPath`, `HedgeShadow`, and `FootShadow` (shared with the figures).
- `App/PeaceGarden/Rendering/GardenCreatures.swift`: the figures. Its `camera(for:)` is reused by the hedges.
- `App/PeaceGarden/Views/PlotView.swift`: `hedges`/`hedgeLines`, `comeIn`, `nudge`, and `GardenGroundView`'s close redraw.
- `App/PeaceGarden/Views/DeveloperControls.swift`: the `-pgPlotSide` and `-pgArea` launch settings.
- `docs/ARRANGING.md`: *The glow-in-the-dark figures* and *What zoom is for*.

## Decisions made
- **Curate by rule.** We design each area's layout; plants take their place by the rule; only showcase plants are placed by hand. An area is many 5.2 m plots. The Wild Fields are uncurated, and a plant's place there comes from its seed.
- **Placement is assigned once on arrival and stored.** A plant never moves. This supersedes the seed-derived grid in `WEBSITE.md` (marked there).
- **The rule is "nothing stands in front of something shorter", not rows.** Filling row by row left 11 of the first 15 plots half empty.
- **Measure tiers on 300 different parent pairs.** A sample crossed with one parent skews tall and is half bells.
- **Hedges:** tall behind the far border, low in front of the near one, swapped as the plot turns. Clipped boxes, square-ended, cut to one top line.
- **Worn paths in the Wild Fields are accepted,** as counts per ground cell only: no cookie, no identifier, no address. The privacy page must say so before they go live.
- **Zoom stays capped at 3×.** Its uses are arranging, showing a plant among its neighbours, and tapping the right plant.
- **Figures are 3D models, not paintings.** Their glow is a second render added over the figure by the square of the lamps' glow.

## Next step
Compile SeedCore to WebAssembly and draw one plant in a browser. Measure the wasm size, which is the open question in `WEBSITE.md` §*What renders the plant*. Every web garden depends on this.

## Traps
- **Simulator `garden.json` is currently Long Walk plot 3.** The earlier fixture backups were in the session scratchpad and may be gone.
- **Rebuilding a plot fixture:** a throwaway SwiftPM tool that depends on `Packages/SeedCore` by path, plants 300 crossings with `LongWalk.Walk`, and writes `{plants, placed}`. Dates **must** be encoded `.iso8601`. Otherwise the app fails to read the garden, falls to the first-run screen, and may overwrite the file; terminate it at once.
- **Preview command:** `xcrun simctl launch booted app.peacegarden -pgOpen garden -pgPlotSide 5.2 -pgArea longWalk`. For night, add `-developer.clockShift 43200`.
- **A figure's foot is `lift` up its picture, not on the bottom edge.** Anything that places, shadows or hit-tests a figure or hedge piece must allow for it.
- **Sheared sprite shadows collapse to hairlines near noon.** Anything long, like a hedge, needs a ground-polygon shadow instead.
- **A vertical face is lit by the sky, not the sun.** Pick its material brighter than it looks on its own, then grey it.
- **A token-guard hook blocks plain `cat` and `grep`, and blocks heredocs containing the word "curl".** Use Read, `rg`, or write scripts to the scratchpad.
- **SeedCore tests take about 100 s.** Use `--filter`. For the app: `xcodegen generate`, then `xcodebuild test -scheme PeaceGarden -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`.
