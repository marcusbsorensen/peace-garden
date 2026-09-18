# Peace Garden: web gardens, the Long Walk and a plant in a browser — handover 18 September 2026

This session covered five areas: glow-in-the-dark figures, zoom, the web gardens design, the Long Walk, and SeedCore in WebAssembly (the afternoon). The app's Garden-screen handover it replaces is at `git show 7d5845d:.claude/HANDOVER.md`. Its traps still apply.

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
- **A plant in a browser (afternoon):** SeedCore builds for WebAssembly and `tools/wasm/web/` draws one plant with WebGL2. The module is **2.5 MB brotli** (3.7 MB gzip, 12.8 MB raw). The whole SeedCore suite passes inside wasm, apart from `GardenStoreTests`. All 15 pinned port seeds grow the same buffers as on the Mac: identical shape, indices, UVs and texels, with positions within 3.2 µm and normals within 3 × 10⁻⁴ (libm rounding). SeedCore 124 tests and the app's 74 pass. Written up in `WEBSITE.md` §*What renders the plant*.
- **Drawn only with diffuse texture and a plain sun.** Relief and roughness maps, the app's lighting, and a plant's name are still to come.
- **Not started:** plots in the browser, the plot service, the curator tool and the Wild Fields.

## Files
- `docs/WEB-GARDENS.md`: the design: ten areas, plots, dressing, the curator tool, the Wild Fields, worn paths, build order. Current.
- `Packages/SeedCore/Sources/SeedCore/WebGardens/LongWalk.swift`: the rule. The tier cut-offs are measured values (see its doc comment).
- `Packages/SeedCore/Sources/SeedCore/Growth/Maturity.swift`: a plant's grown size. It moved here from `PlantSceneBuilder`, which now forwards to it.
- `App/PeaceGarden/Rendering/GardenStructures.swift`: hedges, `MownPath`, `HedgeShadow`, and `FootShadow` (shared with the figures).
- `App/PeaceGarden/Rendering/GardenCreatures.swift`: the figures. Its `camera(for:)` is reused by the hedges.
- `App/PeaceGarden/Views/PlotView.swift`: `hedges`/`hedgeLines`, `comeIn`, `nudge`, and `GardenGroundView`'s close redraw.
- `App/PeaceGarden/Views/DeveloperControls.swift`: the `-pgPlotSide` and `-pgArea` launch settings.
- `docs/ARRANGING.md`: *The glow-in-the-dark figures* and *What zoom is for*.

- `tools/wasm/`: the browser module (`Sources/PlantWasm/Exports.swift`, the buffer layout is in its header comment), `build.sh`, and `web/` (the page and `plant.js`). Preview it with the `plant-wasm` launch configuration.
- `Packages/SeedCore/Sources/SeedCore/Determinism/PortableSHA256.swift` and `Genome/RGB.swift` (HSB to RGB, moved out of the app's `GradientTexture`).

## Decisions made
- **Curate by rule.** We design each area's layout; plants take their place by the rule; only showcase plants are placed by hand. An area is many 5.2 m plots. The Wild Fields are uncurated, and a plant's place there comes from its seed.
- **Placement is assigned once on arrival and stored.** A plant never moves. This supersedes the seed-derived grid in `WEBSITE.md` (marked there).
- **The rule is "nothing stands in front of something shorter", not rows.** Filling row by row left 11 of the first 15 plots half empty.
- **Measure tiers on 300 different parent pairs.** A sample crossed with one parent skews tall and is half bells.
- **Hedges:** tall behind the far border, low in front of the near one, swapped as the plot turns. Clipped boxes, square-ended, cut to one top line.
- **Worn paths in the Wild Fields are accepted,** as counts per ground cell only: no cookie, no identifier, no address. The privacy page must say so before they go live.
- **Zoom stays capped at 3×.** Its uses are arranging, showing a plant among its neighbours, and tapping the right plant.
- **Figures are 3D models, not paintings.** Their glow is a second render added over the figure by the square of the lamps' glow.

- **WebAssembly is the renderer.** At 2.5 MB brotli, and matching the phone, the CI-gated JavaScript port stays the fallback only. Marcus has yet to confirm that 2.5 MB is acceptable for a first visit on mobile data.
- **On WASI, SeedCore imports `FoundationEssentials` and hashes with `PortableSHA256`.** The full Foundation (through swift-crypto) is 37 MB of ICU data. Use nothing from outside `FoundationEssentials` in SeedCore: `String(format:)` and `replacingOccurrences` were rewritten for this.
- **SeedCore arithmetic that must wrap uses `Int64`/`UInt64`, never `Int`.** `Int` is 32 bits in wasm; `speckle` was the one case.

## Next step
Draw one Long Walk plot in the browser: its placed plants, from `LongWalk`, on the app's floating ground. Before that, add a CI job that builds SeedCore for wasm and runs its tests under Node, so a Foundation-only API or an `Int` wrap cannot creep back.

## Traps
- **WebAssembly needs the swift.org toolchain, not Xcode's.** Installed: `~/Library/Developer/Toolchains/swift-6.3.3-RELEASE.xctoolchain` and the SDK `swift-6.3.3-RELEASE_wasm`. Use that toolchain's `swift` explicitly. To run the tests in wasm: `swift build --build-tests --swift-sdk swift-6.3.3-RELEASE_wasm`, then run `SeedCorePackageTests.xctest` with Node's `node:wasi` and a `/` preopen. That takes about 7 minutes.
- **Two wasm builds at once in one package race and report nonsense errors.**
- **zsh does not word-split `$VAR`.** Pass lists of seeds as an array.
- **Simulator `garden.json` is currently Long Walk plot 3.** The earlier fixture backups were in the session scratchpad and may be gone.
- **Rebuilding a plot fixture:** a throwaway SwiftPM tool that depends on `Packages/SeedCore` by path, plants 300 crossings with `LongWalk.Walk`, and writes `{plants, placed}`. Dates **must** be encoded `.iso8601`. Otherwise the app fails to read the garden, falls to the first-run screen, and may overwrite the file; terminate it at once.
- **Preview command:** `xcrun simctl launch booted app.peacegarden -pgOpen garden -pgPlotSide 5.2 -pgArea longWalk`. For night, add `-developer.clockShift 43200`.
- **A figure's foot is `lift` up its picture, not on the bottom edge.** Anything that places, shadows or hit-tests a figure or hedge piece must allow for it.
- **Sheared sprite shadows collapse to hairlines near noon.** Anything long, like a hedge, needs a ground-polygon shadow instead.
- **A vertical face is lit by the sky, not the sun.** Pick its material brighter than it looks on its own, then grey it.
- **A token-guard hook blocks plain `cat` and `grep`, and blocks heredocs containing the word "curl".** Use Read, `rg`, or write scripts to the scratchpad.
- **SeedCore tests take about 100 s.** Use `--filter`. For the app: `xcodegen generate`, then `xcodebuild test -scheme PeaceGarden -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`.
