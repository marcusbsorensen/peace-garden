# Peace Garden: broader plant shapes — handover 24 September 2026 (evening)

The Coppice is open and live. The session's second half turned to the plants themselves: every one is narrow and tall, and Marcus chose to change their shape everywhere. Older notes: `git show 8922297:.claude/HANDOVER.md` (the morning's: eight areas, the Coppice next).

## Goal
Real variety among the species, low and broad plants among them, before the app is announced. Then the Home Ground, the tenth area.

## State
- **Deployed and checked live** (main `735b659`, pushed):
  - **The Coppice, the ninth area.** Rule in `SeedCore/WebGardens/Coppice.swift`, port `Server/.api/Coppice.php`, store `CoppiceStore.php`, page `/coppice`, stool `Morphology/Structures/Stool.swift`. On the design's fresh 500 it holds the simulation's numbers exactly: 16 plots, 14 full, 94.9%.
  - `PlantTraits.habit` (the archetype's name) on the wire and in `walk_offers`; empty means never sent, read as a star.
  - `/api/coppice/plot/{n}` sends the year of the rotation (turns 21 December UTC), each coupe's stage, and each stool fern's stage. The service is in year 0 until 21 December 2026; years 1 and 2 were checked only on `/dev/coppice`.
  - Backup taken before the migration; `coppice` and `coppice_lock` are in `backup.php`'s KEPT.
- **The sweep cron runs.** Installed with `tools/backup.sh --install-cron`; `~/backups/sweep.log` shows a run at 12:55 UTC. The privacy page's "up to an hour" holds.
- **Needs an app build:** the phone does not yet send `habit`, so every fern offered from the app lands on the Coppice floor as a star, and the stools stay empty until the build ships. The Glasshouse `hue` and the name-meaning sheet are waiting on the same build.
- **The new shapes, approved**, on branch `shape/broader` in the worktree `.claude/worktrees/agent-af70adf3868978ef3` (not merged, not pushed):
  - `461c600` v1 and `4d1c96e` v2: a *habit* per archetype (`Archetype.swift` `profile(for:)`, `Genome.Habit`): crown leaves from the stem's foot; rosettes for succulent, fern, orchid and lotus; round pads for lotus; cut fronds for fern; stem leaves that grow with stem height. New genes are named draws (`habit.crownLeaves`, `habit.crownPitch`, `habit.pinnae`, `leaf.crown.N`), so nothing else shifts; names are untouched. `docs/PLANT-FORMS.md` §"Habit".
  - v2 on 6,000 plants: median height÷spread **1.28** (2.15 on main), **31%** wider than tall (6%), **22%** under 0.5 m (6%). Lotus 0.34 × 0.87 m; succulents open rosettes; poppy, bell and star ratio about 1.36.
  - Young stages held: crown leaves grow with height in proportion to how upright they are. Cold Frame tallest seedling 0.34 m (0.45 on main); Coppice's closest star over a cut fern 0.16 m clear.
  - SeedCore on v2: 357 tests, 39 failures in 22 — the recorded vectors, area fill and cut numbers, and one new floor: a young lotus is 0.058 m, under `ColdFrameTests.swift:275`'s 0.08 m.
- **In flight: the cup fix**, the same agent on the same branch:
  - **The ring under blooms is the centre dome** (`PlantBuilder.swift` `addBloom`, `addDome(role: .centre, …)`): oversized, centred on the point every petal springs from so the petals pierce it, open underneath (the web lights back faces, so the hollow shows), any hue. Nothing green sits under the petals; `addSepals` gives reflexed blades to 70% of seeds whatever their archetype.
  - **Fix, version C:** petals attach on a ring at 0.9 of the centre's radius and shorten by half of it; the centre capped at 0.34 of a petal; a closed cup from the stem tip to the petal bases, a bulbous involucre on the thistle; no reflexed sepals on poppy, umbel, orchid, thistle, fern. Its own leaf-green **calyx colour role** through `Palette`/`Colouring`, the app's `GradientTexture` and `PlantSceneBuilder`, the wasm texture bake and `plant.js` `ROLES`.
  - Also toning down the poppy's basal leaves, which read as a flat green star.

## The measurement (6,000 plants, read-only)
- Median height 1.00 m, spread 0.45 m, height÷spread 2.15; 6% wider than tall, nearly all plume.
- **Why:** stem height is a gene (`Genome.swift:282`); spread comes from leaf length (`:312`), drawn independently of height, so spread plateaus near 0.47 m and tall plants read as sticks (ratio 3.7 over 1.6 m). Nodes sit 16–90% up the stem, never at the base (`PlantSkeleton.swift:96-102`).
- **Succulent** is a small leafy column (0.45 × 0.20 m) and nothing builds a rosette; **lotus** and **poppy** are a big bloom on a 0.7 m stem.
- Numbers, renders and tools are in the session scratchpad (`/private/tmp/claude-501/-Users-marcus-Projects-peace-garden/70b0cbab-03c1-4376-a9c0-5e0072493992/scratchpad/`): `plant_shapes*.csv`, `archetype_summary*.csv` (main, `_v1`, `_after`), `area_spacing.csv`, `shape/` (measuring package), `draw_grid.py`, the render grids, and `ring/` (the ring investigation: `ring_compare.png`, `prototype_C.diff`, `render_closeup.py`, `probe/`). **Session-only**: copy what is wanted into `tools/` before the session is cleared.
- **Nothing spaces plants by spread.** Room for wider plants (nearest places): Orchard 0.90, Quiet Garden 0.85, Crossing and Knot Garden about 0.55, Seedbed 0.52, Coppice 0.40, Glasshouse staging and Cold Frame 0.30.

## Decisions made
- **Change shape everywhere now (option c)**, heights included, rather than add breadth only or version the rules. Marcus, 24 September.
- **Replant the live web garden** when the shapes go live: re-grow each stored seed with the new shapes on the Mac and replay every area's arrivals in their original order, after a backup. Places may change once.
- **Shapes approved at v2**, then the cup fix and the poppy change, **then straight to stage 2** without another look. Marcus, 24 September.
- **A closed green cup under the petals** rather than the ring, with its own green; botany per archetype as above.
- **Coppice:** no stage words on the page (a turn would make "the far band" wrong); the floor is lighter in the cut band. Stools cast shadows, the only web page that draws any.
- Earlier decisions stand: glyphs over words, no flags, dictionary headwords with one colon, Danish says "folk"/"personer", never "mennesker", Danish first in any round.

## Next step
1. When the cup fix reports: check `ring_branch_after.png` and the shape renders, and that the app and web both draw the calyx role.
2. Then stage 2, on the branch:
   - re-measure every area's cuts on the new heights: Long Walk 0.93/1.28, Quiet Garden 1.13, Crossing 0.97/1.43, Orchard 0.75/1.30 (the Knot Garden and the Glasshouse border borrow it), Cold Frame 0.85, Coppice 1.10, the Glasshouse band edges if hue moved (it should not);
   - re-record every `tools/reference/*_vectors.json`, and the ambassador heights in `Server/.api/Ambassadors.php`;
   - the structure tests: Glasshouse roof, Cold Frame glass at the young stage, Coppice's "shortest star over every cut fern";
   - `PlantFormTests` width pins, the Python port `tools/preview/plant_model.py` with `PortVectorTests`, the app's sprite headroom (`GardenSprites.swift:43`), the committed samples in `tools/coppice` and `tools/homeground`;
   - check spacing: the Glasshouse staging and Cold Frame ranks are 0.3 m apart, the tightest; the Orchard and Quiet Garden have the most room;
   - the young lotus's 0.058 m against the Cold Frame's 0.08 m seedling floor;
   - write the replant tool, rehearse it on a copy;
   - **ask Marcus before** the backup, deploy and replant: they change the live database. Then merge, remove the worktree and its `worktree-agent-*` branches.
3. Then the Home Ground, from `docs/WEB-GARDENS.md` §"The Home Ground, chosen" (its fill was simulated on the old shapes and needs re-simulating).
4. Strings: `coppiceAbout` and `coppiceAway` are English only; commission them with the next round, Danish first.

## Traps
- **Playwright MCP:** misbehaves when agents share it. Drive renders from a playwright-core script of your own, with a fresh profile.
- **Agents in worktrees:** merge the branch, then `git worktree remove --force` and delete the branch.
- **Seeing a new deploy:** a browser that visited earlier keeps old JS unless the page is served through `index.php` with stamps.
- **Toolchains:** the WebAssembly suite needs `~/Library/Developer/Toolchains/swift-6.3.3-RELEASE.xctoolchain/usr/bin/swift`. Run `sh tools/wasm/build.sh` before any deploy that touches Swift; the module is built, not committed.
- **Before deploying a migration:** `sh tools/backup.sh` first. Deploying migrates the live MariaDB on the first request.
- **The token-guard hook** blocks unbounded `cat`, `grep`, `git show` and large images; pipe through `head`, use `rg`, downscale screenshots with `sips` before reading.
- **Heights are exact only to 0.01 mm across hosts** (`VectorFile.height`); habit and hue are exact. Any new cut needs `placementCannotTurn` in its vector test.
- **Loose ends, left alone:** PDO rounds stored decimals to 14 digits; `.htaccess` routes only `s|g|t`; the `g` key on `/g` is labelled by the wordmark; unused keys `gardenBody`, `walkBody`, `goOn`, `walkThisArea`; the local branch `area/coppice` is merged and can be deleted.
