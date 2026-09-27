# Peace Garden: water, plant surfaces, pedicels — handover 27 September 2026

This session covered too much ground: water in two areas, a rebuild of the web plant shading, and a morphology fix. The decisions are in `docs/WEB-GARDENS.md` and `docs/PLANT-FORMS.md`. The previous handover is at `git show e286c67:.claude/HANDOVER.md`.

## Goal
Water where water lilies go, web plants that look grown rather than moulded, and no flower threaded on its own stem.

## State
Everything below is committed, pushed and deployed. SeedCore has 398 tests passing, the app 131 (1 skipped), and both PHP cross-checks are green.
- **Cold Frame tank**: 7×3 lilies, 0.62 m apart, frames pushed out to `frameZ` 1.55, cut moved 0.38→0.50 (median of the dry plants only).
- **Seedbed flooded drills**: a drill is claimed by kind *and* element; the channel is 0.54 m wide; the plot API returns `water`.
- **Web plant shading**: per-leaf maturity tint, relief and roughness bake (buffer `PGP3`), gamma-correct shared `shade()` with re-tuned `LIGHT`, specular gated on relief slope.
- **Pedicels**: node blooms on spire, vine and bell now stand on stalks. Ported to the Python preview. The app is rebuilt with it.
- **Phone build**: `xcodebuild` for `generic/platform=iOS` succeeded with Marcus's signing, but it is **not installed**. He runs it from Xcode.
- **Unverified in the app**: the pedicels have not been *seen* there. The simulator is a fresh install whose only plant is a 20-hour *Calora gracilis* seedling, and there is no debug way to age a plant.

## Files
- `Packages/SeedCore/Sources/SeedCore/WebGardens/ColdFrame.swift`: the tank, `backFrom`
- `Packages/SeedCore/Sources/SeedCore/WebGardens/Seedbed.swift`: `isWater`, claim by kind + element
- `Packages/SeedCore/Sources/SeedCore/Morphology/PlantSkeleton.swift`: `pedicels`, keyed by node offset
- `Packages/SeedCore/Sources/SeedCore/Morphology/PlantBuilder.swift`: node bloom on its pedicel; the stalk is drawn in `addBlooms`
- `tools/wasm/Sources/PlantWasm/Exports.swift`: the PGP3 buffer (maturity + `bakeRelief`)
- `Server/assets/js/longwalk.js`: `LIGHT`, `SHADE` (gamma), `PLANT_FRAGMENT`
- `Server/assets/js/plant.js`: decoder, `YOUNG` table, single-plant shader
- `Server/assets/js/seedbed.js`: `CHANNEL`, dug drills, rim-ring backing
- `Server/.api/{ColdFrame,Seedbed,SeedbedStore}.php`, `router.php`: ports and `water`
- `tools/reference/check_{cold_frame,seedbed}.php`, `taking_back.php`: the cross-checks
- `tools/preview/plant_model.py`: `build_pedicels`

## Decisions made
- **Only the Cold Frame and the Seedbed ever get lilies.** An area comes from the genus head, which is the archetype's root: `Nyx` and `Lir`. So the Quiet Garden's pool rule can never fire live.
- **The Seedbed floods drills instead of a pool.** A grown lily's pads need about 1 m, and a pool would mean shortening the six-of-eight drills Marcus chose. That costs 2 plots (21, up from 19); accepted.
- **Two-place lotus rule**: unreachable under glass now, but kept because stored rows still have `span` 2.
- **`SeedbedStore` keeps the habit on take-back.** A blank habit reads a flooded drill as dry. Rows taken back before 27 Sep read dry until the replant.
- **Relief strengths and roughness swings are the app's, unchanged.** They were already tuned down once, from "corrugated iron".
- **Gamma**: it changes the light curve, not the light's direction. `sun` is unchanged and still shared by plants, ground and shadows.
- **Pedicels are kept separate from `branches`.** Tests assert that racemes have no branches.

## Next step
Add a debug-only launch argument that ages the current plant to flowering, so a spire's pedicels can be seen in the simulator. Marcus was offered this as the recommended option and has not yet answered.

## Traps
- **token-guard hook**: blocks plain `grep`, unbounded `cat` and `cat >` heredocs. Use `grep -l`/`-c`, `awk`, `sed -n`, `python3`, or Write.
- **Backticks inside a GLSL template literal end the JS string.** This broke `plant.js` twice. Check with `node --check` on a `.mjs` copy.
- **Hidden browser pane**: screenshots time out and `toBlob` returns blank. `preview_start {url}` forces the pane open. `/dev/plant` draws only once, so capture it with a screenshot.
- **Sunk water needs the floor under it to give way.** Otherwise it draws inside a closed box: the Quiet Garden pool, then the Seedbed backing fan.
- **XCTest results**: read the "Executed N tests, with M failures" line, not the tail of the output.
- **`/dev/*` workbenches invent a general population**, so their plot counts differ from the tests' own-area samples.
- **Stale SourceKit errors in the editor**: trust `swift build`.
- **`tools/deploy.sh`**: uploads the working tree. SSH sometimes resets at key exchange; retry once and don't hammer it.

## Also pending (not next)
- Water as scenery in the 8 lily-free areas (grading approved)
- Plan-view glyphs and slab relief
- Reed and alpine archetypes, plus the re-roll and 4 root syllables × 41 languages
