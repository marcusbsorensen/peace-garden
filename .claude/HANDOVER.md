# Peace Garden: broader plant shapes — handover 24 September 2026 (afternoon)

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
- **In flight: the shape prototype**, a background agent in a worktree on branch `shape/broader`. It changes morphology in SeedCore only and comes back with `archetype_grid_after.png`, `mixed_after.png`, `same_seeds_before_after.png` and `archetype_summary_after.csv` in the session scratchpad. Nothing else moves until Marcus approves the shapes.

## The measurement (6,000 plants, read-only)
- Median height 1.00 m, spread 0.45 m, height÷spread 2.15; 6% wider than tall, nearly all plume.
- **Why:** stem height is a gene (`Genome.swift:282`); spread comes from leaf length (`:312`), drawn independently of height, so spread plateaus near 0.47 m and tall plants read as sticks (ratio 3.7 over 1.6 m). Nodes sit 16–90% up the stem, never at the base (`PlantSkeleton.swift:96-102`).
- **Succulent** is a small leafy column (0.45 × 0.20 m) and nothing builds a rosette; **lotus** and **poppy** are a big bloom on a 0.7 m stem.
- Numbers and the measuring package are in the session scratchpad: `plant_shapes.csv`, `archetype_summary.csv`, `area_spacing.csv`, `shape/`, `draw_grid.py`, `archetype_grid.png`. The scratchpad is session-only; copy them into `tools/` if they are wanted later.

## Decisions made
- **Change shape everywhere now (option c)**, heights included, rather than add breadth only or version the rules. Marcus, 24 September.
- **Replant the live web garden** when the shapes go live: re-grow each stored seed with the new shapes on the Mac and replay every area's arrivals in their original order, after a backup. Places may change once.
- **Coppice:** no stage words on the page (a turn would make "the far band" wrong); the floor is lighter in the cut band. Stools cast shadows, the only web page that draws any.
- Earlier decisions stand: glyphs over words, no flags, dictionary headwords with one colon, Danish says "folk"/"personer", never "mennesker", Danish first in any round.

## Next step
1. Show Marcus the prototype's renders and before/after table. Iterate on the shapes until he approves.
2. Then stage 2, on the branch:
   - re-measure every area's cuts on the new heights: Long Walk 0.93/1.28, Quiet Garden 1.13, Crossing 0.97/1.43, Orchard 0.75/1.30 (the Knot Garden and the Glasshouse border borrow it), Cold Frame 0.85, Coppice 1.10, the Glasshouse band edges if hue moved (it should not);
   - re-record every `tools/reference/*_vectors.json`, and the ambassador heights in `Server/.api/Ambassadors.php`;
   - the structure tests: Glasshouse roof, Cold Frame glass at the young stage, Coppice's "shortest star over every cut fern";
   - `PlantFormTests` width pins, the Python port `tools/preview/plant_model.py` with `PortVectorTests`, the app's sprite headroom (`GardenSprites.swift:43`), the committed samples in `tools/coppice` and `tools/homeground`;
   - check spacing: the Glasshouse staging and Cold Frame ranks are 0.3 m apart, the tightest; the Orchard and Quiet Garden have the most room;
   - write the replant tool, rehearse it on a copy, then back up, deploy and replant.
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
