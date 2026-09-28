# Peace Garden: the reed, the cushion and the re-roll — handover 28 September 2026

The previous handover is at `git show be881db:.claude/HANDOVER.md`.

## Goal
Promote the reed and the cushion to real archetypes, flip the spire, and re-roll and replant the garden once. Marcus approved all of it on 28 September.

## State
- **Live on peacegarden.app**: water in all ten areas (`water/scenery` merged, `6b8a56d`, deployed, `deploy.sh` check green).
- **On `main`, app only**:
  - `-pgStage` and `-pgMint` debug launch args.
  - The stage frames a turning plant by its reach from the stem (`Maturity.extent`, `framing(reach:)`).
  - SeedCore 400 tests pass, app 131.
- **`shape/reed-cushion` (`15955dd`): approved, not merged.** The reed and the cushion as `ArchetypeProfile.Prototype` behind `@_spi(Prototype)`. `-pgPrototype` shows them on the stage, and on this branch `-pgMint` mints at launch.
- `glyphs/plan-views`: **abandoned**. The symbolic glyphs stay.

## Files
- `Packages/SeedCore/Sources/SeedCore/Genome/Archetype.swift`: `Prototype` profiles to move into `profile(for:)` as `case reed, cushion`
- `Packages/SeedCore/Sources/SeedCore/Genome/PlantName.swift:122`: `roots`; `WebGardens/Areas.swift:146`: `genusHeads` per theme
- `Packages/SeedCore/Sources/SeedCore/Morphology/PlantBuilder.swift`:
  - `strapProfile`, `addCushion`, `addCushionFlower` (branch)
  - the spire's node-bloom order at about `:660`
- `docs/PLANT-FORMS.md` (last section on the branch): what is left, and why

## Decisions made
- **Shapes approved as rendered.** Merge `shape/reed-cushion` first, then append the two cases to `Archetype`. Appending re-slices the draw, which is the re-roll Marcus chose.
- **Roots.** The few-merous root names the family (few + "aceae").

  | Family | Few (petals) | Many (petals) | Themes |
  |---|---|---|---|
  | Reed | *Don* (3) | *Syr* (6) | waiting, beginnings |
  | Cushion | *Tyl* (5) | *Or* (8) | travel, meeting |

  - Reed themes put reeds with the lilies by water. Default: *Syr* to waiting, *Don* to beginnings.
  - Cushion themes put cushions at the head of the slope. Default: *Or* to travel, *Tyl* to meeting.
  - Glosses: syrinx, the reed pipe; donax, the reed; tylē, a cushion; oros, a mountain.
- **Spires open bottom-up** (4a), in the same re-roll, since it moves bloom sizes and so heights.
- **Roots travel untranslated.** The labels *Reed* and *Cushion* need the app's 7 languages.

## Next step
On a branch from `main`, merge `shape/reed-cushion`, then add `case reed, cushion` with the roots and themes above. Then work through every list the survey found:
- `wantsWater`, and the PHP `WANTS_WATER`
- `passages.js`, `meanings.js`, `Localised.swift`
- `plant_model.py` (the port needs the strap and the cushion)
- the counts in `RootTableTests`, `GenomeTests` and `ThemeMappingTests`

After that:
- Flip the spire.
- Cut the cushion's cost; it is 7× an ordinary plant.
- Re-record every area vector, the ambassadors and `vectors.json`.
- Rebuild the wasm.
- Render for Marcus, then back up and replant.

This is a whole session. Do not deploy before the replant rehearsal passes.

## Traps
- **Hidden browser pane pauses the page**, so `toBlob` and even `setTimeout` never settle. Capture headless with Playwright `browser_run_code_unsafe` → `page.screenshot`.
- **The token-guard hook** blocks `innerHTML` (the security plugin), unbounded `git show`, and `cat >`. Use Write, and `| head -n`.
- **Simulators.** The iPhone 17 Pro holds Marcus's garden: do not reinstall onto it. The iPhone Air is scratch; `scratchpad/shoot.sh` pattern: uninstall, install, launch with `-pgMint`.
- **`pedicel-N` seed words** give known archetypes. Search with a scratch SwiftPM package depending on SeedCore by path.
