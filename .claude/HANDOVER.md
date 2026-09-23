# Peace Garden: build the Cold Frame — handover 23 September 2026

This session did five things (Organic split, the Seedbed, site navigation, glyph pad + minimap, the Cold Frame's design), so this note is compressed. Fuller notes: `git show 780ecf2:.claude/HANDOVER.md`; older traps, all still valid: `git show ff3f8e5:.claude/HANDOVER.md`.

## Goal
Open all ten garden areas before the app is announced. Six are open; build the seventh, the Cold Frame (`waiting`), whose design Marcus has settled.

## State
- Done, verified, pushed, deployed (`cd15a74`, CI green on Linux, WebAssembly and Python): the Seedbed (`beginnings`) live on peacegarden.app. The site now has a bar, text below the plot, a glyph pad and a 5×2 minimap. SeedCore 271 tests on macOS and 265 on WebAssembly; app 129 run, 1 skipped; every `tools/reference/check_*.php` passes.
- Cold Frame: decided, no code written.

## Files
- `Packages/SeedCore/Sources/SeedCore/WebGardens/Seedbed.swift`, `KnotGarden.swift`: the two rules to model on. The Knot has the colour claim the Cold Frame needs.
- `Packages/SeedCore/Sources/SeedCore/Morphology/Structures/`: where the glazed frame goes (next to Hedge, Bench, Roundel, Tree, RowLabel).
- `Packages/SeedCore/Sources/SeedCore/Morphology/PlantBuilder.swift:25`: `mesh(growth:)`, which builds a plant at any growth stage.
- `Server/.api/Seedbed.php`, `SeedbedStore.php`, `tools/reference/check_seedbed.php`, `tools/wasm/Sources/PlantWasm/Seedbed.swift`: the full shape of an area, one file per layer.
- `Server/.pages/seedbed`, `Server/assets/js/seedbed.js`, `seedbedpage.js`: copy these for the new page, not an older page.
- `docs/WEB-GARDENS.md` §*The Seedbed, built*: write the Cold Frame's section beside it.

## Decisions made
- **Every plant is drawn young; nobody is turned away.** Measured over 2000 crossings: `waiting` plants grow to 0.40–1.52 m (median 0.82), and a frame holds about 0.4 m, so a height limit would refuse over 90% of the area's own plants.
- **Four frames of twelve, 48 a plot**: two rows of two frames, each about 2 m × 1 m, two ranks of six inside.
- **Colour claims a frame; mature height orders its ranks** (tallest-to-be at the back). The claim is read off the plants, never stored, as in the Knot Garden.
- **Placement uses the mature height** stored with the planting. The drawn young stage is only a matter of drawing.
- An area's `kind` means its epithet (`PlantTraits.kind`). Only the Seedbed reads it.

## Next step
Simulate the fill in a scratch test before writing the rule: seven colour families over four frames a plot, 500 arrivals, and a rank cut measured from those arrivals. Then write `ColdFrame.swift` with tests and vectors, including `VectorFile.placementCannotTurn`, since this area has a height cut. Then the PHP port, the store, the check, the CI step and the wasm exports; the page last, using agents as the Seedbed did.

## Traps
- **Measure before designing.** The Seedbed's "kind" and the Cold Frame's "small" were both wrong on paper and right once measured.
- **A vector file must be one JSON document.** On the recording host it matches byte for byte and is never parsed, so a file of JSON lines passes on the Mac and fails under WebAssembly.
- **Run the WebAssembly suite locally before pushing.** It takes 7–20 minutes (`git show ff3f8e5:.claude/HANDOVER.md` has the command). Filter the output with `rg "error|Executed"`, not just `Executed`, or a failure is hidden.
- **The open list lives in eight places:**
  - `Areas.swift`, `Areas.php`
  - `backup.php` `KEPT`
  - `gates.js` `BUILT`
  - `.pages/g`'s comment
  - `AreaVectorTests`, whose name must be edited too
  - `area_vectors.json`, re-recorded
  - the app's `ThemeMappingTests`, run by hand in Xcode
- **A new area's kind or trait must travel both arrival paths**: `POST /api/walk/plant` and the offer path (`walk_offers`).
- **Glyph-only controls take their name from `data-s-label`**, never from hardcoded English.
- **Deploying migrates the live database.** Ask Marcus first, then run `sh tools/deploy.sh`.
- **Agents writing to the same files overwrite each other.** Keep their file sets apart, and run page work one at a time.
