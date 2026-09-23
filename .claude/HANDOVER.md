# Peace Garden: the Cold Frame is built — handover 23 September 2026 (night)

Fuller notes on earlier work: `git show 780ecf2:.claude/HANDOVER.md` (the Seedbed, the walkable site) and `git show ff3f8e5:.claude/HANDOVER.md` (the libm divergence and older traps, all still valid). The long version of this one is `docs/WEB-GARDENS.md` §*The Cold Frame, built*.

## Goal
Open all ten garden areas before the app is announced. **Seven are built**; three to go: the Coppice (`renewal`), the Glasshouse (`light`), the Home Ground (`ground`). Each still needs its three questions answered by Marcus.

## State
- **The Cold Frame (`waiting`) is built, verified, pushed and deployed** (`a1e6b0b`, CI green on all three jobs). Live: `/api/garden` lists `waiting` open, `/api/frame/plot/0` serves the ambassador, `/frame` draws with no console errors, and the Knot Garden still draws after the stage's glass pass. SeedCore 292 tests under WebAssembly, 0 failures (was 265).
  - SeedCore: 298 tests on macOS, 0 failures (was 271).
  - The app: 129 run, 1 skipped, 0 failures, run by hand with `xcodebuild test … iPhone 17 Pro`.
  - PHP: every `tools/reference/check_*.php` in CI passes. `check_cold_frame` runs 3,105 checks over 500 placements.
  - Also passing: `check_sky.mjs`, `export.py --check`, `check_port.py`, and `tools/strings/check.py` and `app_check.py`.
- Looked at in `/dev/frame?arrivals=200` from all four turns, and on `/frame` against the dev service, where the ambassador, *Nyxisora crassicaulis*, stands young in the back-west frame.

## What was decided while building (not Marcus's decisions)
- **The cut is 0.85 m, the median of `waiting` plants only**: 500 of them, found in 5,805 crossings. It is the first cut measured over one area's own plants. `ColdFrameTests`, the vectors and the workbench all draw this area's plants only.
- **At 500 arrivals:** 12 plots, 87% of places held, and 485 of 501 plants in their own rank. The nearest plant to the cut is 0.4 mm away, 40 times the tolerance.
- **Drawn young means `ColdFrame.drawn`**, a composed state: `heightScale` 0.30, leaves 0.7, buds 0.2, nothing open.
  - It is not a moment on the plant's own timeline, because a plant young enough to fit under glass has never shown colour, and colour is what claims a frame.
  - Below 0.25 the seed's husk is drawn.
  - The plants come out 0.10–0.45 m tall, every one under its glass. `ColdFrameTests` holds this.
- **Glass is a new pass in `makePlotStage`** (`longwalk.js`). A ground builder may return a `glass` mesh, and it is drawn blended after the plants.
  - Opacity 0.14. At 0.3 the plants under it were a milky smudge.
  - The panes are lapped and rippled so the glass itself can be seen.
- **The lights are always propped open**, because every plot is lit at midday. Shutting them at night would need a page that knows its own hour.
- **Routes are `/frame`, `/api/frame`, `/api/frame/plot/{n}` and `/dev/frame`.**
- **Two new strings, `frameAbout` and `frameAway`**, in English only, as every area's are.

## Next step
The eighth area. Its three questions were put to Marcus on 23 September, after measuring the three unbuilt areas' plants (4,000 crossings):

| Area | Share | Mature height | Median | Under 1.0 m |
| --- | --- | --- | --- | --- |
| Glasshouse (`light`) | 12.6% | 0.44–1.88 m | 1.03 m | 47% |
| Home Ground (`ground`) | 11.7% | 0.21–2.33 m | 0.81 m | 63% |
| Coppice (`renewal`) | 8.4% | 0.32–1.91 m | 0.89 m | 62% |

Record his answers here and in `docs/WEB-GARDENS.md`, then simulate the fill before writing the rule, as the Cold Frame was.

## Traps, new today
- **The WebAssembly suite needs the swift.org toolchain, not Xcode's.** The command in `ff3f8e5`'s handover calls plain `swift`, which is Xcode's here, and it crashes with *No available targets are compatible with triple "wasm32-unknown-wasip1"*. Use:
  `~/Library/Developer/Toolchains/swift-6.3.3-RELEASE.xctoolchain/usr/bin/swift build --package-path Packages/SeedCore --build-tests --swift-sdk swift-6.3.3-RELEASE_wasm --scratch-path .build-wasm`
  If the build fails, `run-wasi.mjs` will still run the old test bundle and report green. Check that the build succeeded first.
- **`WalkStore::plantInto` sends any unknown area to the Long Walk, and says nothing.** A new area that is not added there loses its plants to the walk. `check_offers.php` now catches this for the Cold Frame. Add a block for each new area.
- **The rank is stored as `slot_rank`**, because RANK is reserved in MySQL 8.
- **A structure file cannot share a name with a rule file** in one Swift module, which is why the frame is `Structures/GlazedFrame.swift`.
- **The open list is in eight places**, all updated for `waiting`:
  - `Areas.swift`, `Areas.php`
  - `backup.php` `KEPT`
  - `gates.js` `BUILT`
  - `.pages/g`'s comment
  - `AreaVectorTests`, whose name changes too
  - `area_vectors.json`
  - `ThemeMappingTests`
- A page also needs its route in `Server/index.php`, `tools/site/serve.py` and `tools/wasm/dev-router.php`.
- The dev service on port 8803 may already be running from an earlier session. It serves new files without a restart.
