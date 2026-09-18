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
- **A plant in a browser (afternoon):** SeedCore builds for WebAssembly and `tools/wasm/web/` draws one plant with WebGL2. The module is **2.1 MB brotli** (2.8 MB gzip, 7.9 MB raw) after `wasm-opt -Oz`; the rest is the Swift standard library and FoundationEssentials, not SeedCore (0.3 MB). The whole SeedCore suite passes inside wasm, apart from `GardenStoreTests`. All 15 pinned port seeds grow the same buffers as on the Mac: identical shape, indices, UVs and texels, with positions within 3.2 µm and normals within 3 × 10⁻⁴ (libm rounding). SeedCore 124 tests and the app's 74 pass. Written up in `WEBSITE.md` §*What renders the plant*.
- **Drawn only with diffuse texture and a plain sun.** Relief and roughness maps, the app's lighting, and a plant's name are still to come.
- **A Long Walk plot in the browser (evening):** `tools/wasm/web/walk.html` (`?plot=N` for others). The module plants real crossings of two parents by `LongWalk.Walk.plant`, then grows each planting from its lineage. The page draws the app's plot: true isometric, the 0.95 m slab with strata, the three-stripe mown path, a 2.0 m yew on the far side and a 0.7 m hedge on the near, swapped as it turns in quarter turns, lit by the app's midday light and shading formula. Plot 1 is 24 plants from 29 arrivals, planted and grown in 0.4 s. Checked by eye at all four turns and at phone width.
- **The Long Walk judged at 500 plants (late evening):** `walk.html?arrivals=500&from=0&span=3` plants 500 and shows plots end to end with each plot's fill. The rule held; the look was too sparse (1.4 plants a m², drifts unreadable). **Marcus chose to double it**: two staggered rows a tier, 48 a plot. Drifts are kept to five by refusing a slot that would join drifts past five (a latent bug the density exposed). Every plot but the newest four is full at 600 arrivals. A partly filled plot is shown as it is. SeedCore 124/124, app 74 pass.
- **The walk is a fixed demonstration sequence** (`tools/wasm/Sources/PlantWasm/Walk.swift`), the same on every reload. The plot service will supply real plantings and their lineage instead.
- **Differences from the app:** no hedge or plant shadows, no albedo atlas on the turf, a flat slab rather than the bulged one, and no night.
- **The plot service (night):** `Server/.api/`. The Long Walk rule ported to PHP (`LongWalk.php`), held to 600 pinned Swift placements by `tools/reference/check_long_walk.php` in CI (three deliberate breakages each caught); the cross check (`Seeds.php`, matches the pinned child); an append-only store (`WalkStore.php`, SQLite or MySQL through PDO, arrivals serialised by a lock row); `/api/walk`, `/api/walk/plot/{n}`, and `POST /api/walk/plant`, which answers 403 unless a local config opens it. End to end locally: `tools/wasm/send-arrivals.mjs` sends 120 real crossings, the service places all 120 where the Swift rule does (worst 1.1e-7 m, float32 in the module), and `walk.html?source=service` draws them. `Server/README.md` § The plot service.
- **Not started:** deploying the service, sign-in, consent, the phone's upload, the curator tool and the Wild Fields.

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

- **WebAssembly is the renderer.** Marcus asked for a trim before building on it; it went from 2.5 to 2.1 MB brotli with wasm-opt. Embedded Swift is the next big cut, and a rewrite, so it waits.
- **On WASI, SeedCore imports `FoundationEssentials` and hashes with `PortableSHA256`.** The full Foundation (through swift-crypto) is 37 MB of ICU data. Use nothing from outside `FoundationEssentials` in SeedCore: `String(format:)` and `replacingOccurrences` were rewritten for this.
- **SeedCore arithmetic that must wrap uses `Int64`/`UInt64`, never `Int`.** `Int` is 32 bits in wasm; `speckle` was the one case.

- **Plot service decisions (Marcus, 18 September):** a shared plant's record carries the child seed, **both parents' seeds** and the meeting ID, with both gardeners' consent (WEBSITE.md amended). The placement rule runs in **PHP, as a port checked in CI** against placements pinned from the Swift; the phone sends height and colour family, which only a grown plant can give.

## Next step
The plot service is built and runs locally end to end; it is not deployed. Before it can take a real plant it needs:
1. **The 20i database** (Marcus creates it in the control panel), its DSN in `Server/.api/config.php` on the server, then a deploy and the dot-rule check in `Server/README.md`.
2. **Sign-in** (Sign in with Apple for a gardener's plot, WEBSITE.md) and **both gardeners' consent** on the phone, with copy saying the other gardener's plant becomes visible.
3. **The phone's side**: Release (today it only deletes, `PlantDetailView.release()`) sends seed, parents, meeting, height and family to `POST /api/walk/plant`.
Ask Marcus which first; (1) is his to do.

## Traps
- **WebAssembly needs the swift.org toolchain, not Xcode's.** Installed: `~/Library/Developer/Toolchains/swift-6.3.3-RELEASE.xctoolchain` and the SDK `swift-6.3.3-RELEASE_wasm`. Use that toolchain's `swift` explicitly. To run the tests in wasm: `swift build --build-tests --swift-sdk swift-6.3.3-RELEASE_wasm`, then `node tools/wasm/run-wasi.mjs <scratch>/debug/SeedCorePackageTests.xctest`, optionally followed by test class names such as `SeedCoreTests.PortableSHA256Tests`. The whole suite takes about 7 minutes.
- **Two wasm builds at once in one package race and report nonsense errors.**
- **`build.sh` wants `wasm-opt`** (`brew install binaryen`). Without it the module is 2.5 MB brotli rather than 2.1.
- **zsh does not word-split `$VAR`.** Pass lists of seeds as an array.
- **Simulator `garden.json` is currently Long Walk plot 3, placed by the one-row rule**, so it no longer matches the two-row layout; rebuild it before judging the app's preview. The earlier fixture backups were in the session scratchpad and may be gone.
- **Rebuilding a plot fixture:** a throwaway SwiftPM tool that depends on `Packages/SeedCore` by path, plants 300 crossings with `LongWalk.Walk`, and writes `{plants, placed}`. Dates **must** be encoded `.iso8601`. Otherwise the app fails to read the garden, falls to the first-run screen, and may overwrite the file; terminate it at once.
- **Preview command:** `xcrun simctl launch booted app.peacegarden -pgOpen garden -pgPlotSide 5.2 -pgArea longWalk`. For night, add `-developer.clockShift 43200`.
- **A figure's foot is `lift` up its picture, not on the bottom edge.** Anything that places, shadows or hit-tests a figure or hedge piece must allow for it.
- **Sheared sprite shadows collapse to hairlines near noon.** Anything long, like a hedge, needs a ground-polygon shadow instead.
- **A vertical face is lit by the sky, not the sun.** Pick its material brighter than it looks on its own, then grey it.
- **A token-guard hook blocks plain `cat` and `grep`, and blocks heredocs containing the word "curl".** Use Read, `rg`, or write scripts to the scratchpad.
- **SeedCore tests take about 100 s.** Use `--filter`. For the app: `xcodegen generate`, then `xcodebuild test -scheme PeaceGarden -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`.
