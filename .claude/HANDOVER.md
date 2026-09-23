# Peace Garden: build the Glasshouse — handover 23 September 2026

This session built and deployed the Cold Frame, then chose and simulated the Glasshouse. Fuller notes: `git show 64d4253:.claude/HANDOVER.md` (the Cold Frame); older traps: `git show ff3f8e5:.claude/HANDOVER.md`.

## Goal
Open all ten garden areas before the app is announced. Seven are open. Build the eighth, the Glasshouse (`light`), whose design Marcus has settled.

## State
- **The Cold Frame (`waiting`) is done, verified, pushed and deployed** (`a1e6b0b`). CI is green on all three jobs, and `/frame` draws live.
  - SeedCore: 298 tests on macOS and 292 under WebAssembly.
  - The app: 129 run, 1 skipped.
  - Every `check_*.php` passes.
- **The Glasshouse is designed and simulated, and has no code** (`195a05b`). Its full design is in `docs/WEB-GARDENS.md` §*The Glasshouse, chosen* and §*The fill, simulated*.

## Files
- `Packages/SeedCore/Sources/SeedCore/WebGardens/ColdFrame.swift`: the newest rule to model on. It has a measured cut and draws plants at a chosen growth stage.
- `Packages/SeedCore/Sources/SeedCore/WebGardens/Seedbed.swift`, `PlantTraits.swift`: how a new trait (`kind`) was added. The Glasshouse's hue goes in the same way.
- `Packages/SeedCore/Sources/SeedCore/Morphology/Structures/`: where the staging goes, beside `GlazedFrame.swift`.
- `Packages/SeedCore/Sources/SeedCore/Genome/Colouring.swift:240`: `flowerHue`, where a plant's hue is derived.
- `Packages/SeedCore/Tests/SeedCoreTests/ColdFrameTests.swift`: draws only one area's plants. Copy this for `light`.
- `Server/.api/ColdFrame.php`, `ColdFrameStore.php`, `WalkStore.php` (`plantInto`), `tools/reference/check_cold_frame.php`, `check_offers.php`: the service side, one file per layer.
- `Server/assets/js/frame.js`, `framepage.js`, `Server/.pages/frame`, `tools/wasm/Sources/PlantWasm/Frame.swift`, `tools/wasm/web/frame.html`: copy these for the page.
- `Server/assets/js/longwalk.js` `makePlotStage`: a ground builder may return `glass`, which is drawn blended after the plants. The Glasshouse's roof uses it.

## Decisions made
- **Staging and a border.** Short plants stand in pots on the staging; the tallest stand in a soil border along the back, where they cannot shade the pots.
- **32 a plot:** 12 positions along the staging with 2 pots at each, plus a border of 8.
- **The border cut is the Orchard's 1.30**, borrowed and named as `Orchard.crownFrom`. The measured 75th centile is 1.294.
- **The staging is a spectrum of colour.**
  - The hue circle is cut at about 114°, in the empty green arc.
  - 12 bands of equal *share*, not equal width. Equal width filled only 68–82%.
  - A pot looks for its own band in every open plot, oldest first, then one band off, then opens a new plot.
  - Pale plants (saturation under 0.22) take any free place.
  - On a fresh sample: 87% of places held, 86% of pots in their own band, none more than one off.
- **The border fills in arrival order from the door end** (Marcus). The spectrum belongs to the staging alone.
- **Hue is exact on every host**, because it is arithmetic from seed bytes with no `sin` or `pow`. Band edges therefore need no tolerance and no margin test. The border cut does need `placementCannotTurn`.
- **Hue becomes a fourth trait, `PlantTraits.hue`.** The phone sends it and the store keeps it in a column, arriving by both paths as `kind` does. That includes a `walk_offers` migration, done the way the Seedbed's was.

## Next step
Write `Glasshouse.swift` with tests and a vector file.
- Set the 12 band edges from a larger `light` sample than 500 (2,000 or more), and write them in as literal constants.
- Then, in order: the PHP port, the store, `check_glasshouse.php`, the CI step, the wasm exports, the staging structure, and the page last.

## Traps
- **The WebAssembly suite must be built with the swift.org toolchain:** `~/Library/Developer/Toolchains/swift-6.3.3-RELEASE.xctoolchain/usr/bin/swift build --package-path Packages/SeedCore --build-tests --swift-sdk swift-6.3.3-RELEASE_wasm --scratch-path .build-wasm`
  - Plain `swift` is Xcode's here and crashes.
  - If the build fails, `run-wasi.mjs` still runs the old test bundle and reports green. Check that the build succeeded first.
- **`WalkStore::plantInto` sends any unknown area to the Long Walk, and says nothing.** Add the `light` case there, and a block in `check_offers.php`.
- **A structure file cannot share a name with a rule file** in one Swift module.
- **The open list is in eight places:**
  - `Areas.swift`, `Areas.php`
  - `backup.php` `KEPT`
  - `gates.js` `BUILT`
  - `.pages/g`'s comment
  - `AreaVectorTests`, whose name changes too
  - `area_vectors.json`
  - the app's `ThemeMappingTests`, run by hand
- A page's route is also needed in `Server/index.php`, `tools/site/serve.py` and `tools/wasm/dev-router.php`.
- **Measure over the area's own plants.** Bands fitted to one sample flatter it: 98% on the sample they were fitted to, 87% on a fresh one.
- **Deploying migrates the live database.** Ask Marcus, rebuild the module with `sh tools/wasm/build.sh`, then run `sh tools/deploy.sh`.
- The dev service on port 8803 may already be running. `/dev/<area>?arrivals=200` is the workbench.
