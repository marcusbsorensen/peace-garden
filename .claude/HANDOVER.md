# Peace Garden: pedicels seen, water everywhere, reed and cushion — handover 28 September 2026

An unattended run of four pieces of work. Three are visual and sit on branches waiting for Marcus's eye; nothing visual was deployed. The previous handover is at `git show be881db:.claude/HANDOVER.md`.

## Goal
Clear the handover queue: see the pedicels, water in the lily-free areas, the reed and alpine archetypes, and plan-view glyphs. The model changes land before the one replant.

## State
- **`main`, pushed, not deployed (app-only):**
  - `87e63c9`: debug launch args. `-pgStage <stage>` winds the clock to mid-stage at the plant's peak hour. `-pgMint <words>` mints the seed on a fresh install.
  - Pedicels seen in the simulator on a spire (`pedicel-9`), a vine (`pedicel-3`) and a bell (`pedicel-2`).
  - `62da45d`: lopsided plants no longer turn off the stage edge. `Maturity.extent` gives the reach, and `framing(reach:)` uses it. 76 of 600 seeds used to leave an iPhone screen; only the 163 that were at or over the edge are framed smaller.
  - SeedCore 400 tests pass, app 131 (1 skipped).
- **`water/scenery` (`b7e2123`), JS only, not deployed.** One piece of water in each of the seven dry areas, to the grading (dug at 0–1.2 m, stone above). Renders sent. The table is in `docs/WEB-GARDENS.md` §"Water as scenery in the other eight". No console errors on any page.
- **`shape/reed-cushion` (`15955dd`), not deployed.** The reed and the cushion as `ArchetypeProfile.Prototype`, behind `@_spi(Prototype)`. The enum is untouched, so no plant moved. Renders sent.
  - The `-pgPrototype reed|cushion` debug arg shows them on the stage.
  - On this branch only, `-pgMint` mints at launch.
  - `docs/PLANT-FORMS.md` last section.
- **`glyphs/plan-views`, drafts only.** `tools/glyphs/plan-views/glyphs.html`. Good: Cold Frame, Coppice, Knot, Glasshouse. Collapsing into UI icons: Seedbed, Long Walk, Quiet Garden.

## Files
- `App/PeaceGarden/Views/DeveloperControls.swift`: `stageOnLaunch`, `mintWords`, `wind(to:)`; `prototype` on the branch
- `App/PeaceGarden/Rendering/PlantSceneBuilder.swift`: `framing(reach:)`
- `Packages/SeedCore/Sources/SeedCore/Growth/Maturity.swift`: `extent`, `reach(of:)`
- `Server/assets/js/water.js`: `raiseTrough`, `raiseRill`, `footing`, `floorAround` (branch)
- `Packages/SeedCore/Sources/SeedCore/Morphology/PlantBuilder.swift`: `strapProfile`, `addCushion`, `addCushionFlower` (branch)
- `Packages/SeedCore/Sources/SeedCore/Genome/Archetype.swift`: `ArchetypeProfile.Prototype` (branch)

## Decisions made
- Nothing visual is deployed or merged before Marcus sees it.
- The prototypes are profiles, not enum cases. Adding a case is the re-roll, and it happens once, after the shapes are settled.
- **The roots are not a 41-language commission.** Heads and roots are untranslated proper nouns. The thirty parts are the subtheme labels. A new root needs a theme, a gloss and a glyph; the new archetype labels need the app's 7 languages. Memory corrected.
- **A root's theme is its area.** Lilies reach water only through Nyx (Cold Frame) and Lir (Seedbed). A reed's roots go in those themes if it is to stand by water.
- The web's single-plant view orbits a bounding sphere, so it never had the app's off-screen fault.

## Next step
Put Marcus's verdicts on the three branches into effect. Water: merge and deploy, or revise. Reed and cushion: tune, or promote to cases with roots and then re-roll. Glyphs: a third pass on the three that fail.

## Open questions for Marcus
- Root candidates. Reed: *Syr* (syrinx, the reed pipe) and *Don* (donax, the reed), in waiting and beginnings. Cushion: *Tyl* (tylē, a cushion) and *Or* (oros, a mountain), in travel and meeting, the head of the slope.
- A spire opens top-down (`PlantBuilder.swift:660`). Real racemes open bottom-up. Keep it or flip it?
- A cushion is 79k vertices, 7× an ordinary plant. Optimise before it becomes an archetype.

## Traps
- **Hidden browser pane pauses the page**, so `toBlob` and even `setTimeout` never settle. Capture headless with Playwright `browser_run_code_unsafe` → `page.screenshot`.
- **The token-guard hook** blocks `innerHTML` (the security plugin), unbounded `git show`, and `cat >`. Use Write, and `| head -n`.
- **Simulators.** The iPhone 17 Pro holds Marcus's garden: do not reinstall onto it. The iPhone Air is scratch; `scratchpad/shoot.sh` pattern: uninstall, install, launch with `-pgMint`.
- **`pedicel-N` seed words** give known archetypes. Search with a scratch SwiftPM package depending on SeedCore by path.
