# Peace Garden: the Home Ground live, all ten areas open — handover 24 September 2026 (late)

Older notes: `git show 447d066:.claude/HANDOVER.md`.

## Goal
All ten areas open before the app is announced, on the new plant shapes.

## State
- **Live and checked** (main `0dbc578`, pushed, deployed; backup taken before): the Home Ground, the tenth area. Rule, port, store, routes, page, workbench, replant, docs.
  - Rule: `Packages/SeedCore/Sources/SeedCore/WebGardens/HomeGround.swift`. Three beds; the crop (the genus root) claims a bed; from the crop's cut up a plant takes the first free place from the north end, below it the first from the south.
  - **The crop is read off `PlantTraits.habit`**, which names the root exactly in this area (Cer is only ever a spire, Fen an umbel, Pell a succulent). No new trait and no offers migration. A habit never sent is sown as an umbel.
  - Marcus's two answers on the new shapes: rosettes 3 across at 0.38 m, 30 a bed; umbel cut 0.930 m (spire 1.346, rosette 0.275).
  - Fresh 500: 9 plots, 7 full, 26 beds sown, 23 full, 90% held. Exactly what the simulation gives (`tools/homeground`, now running the decided design).
  - Service: `Server/.api/HomeGround.php`, `HomeGroundStore.php` (table `home_ground`, crop a column), `/api/ground`, `/api/ground/plot/{n}`. `Area.isOpen` and `Areas::OPEN` carry `ground`: ten of ten.
  - Page: `/ground` (`Server/assets/js/ground.js`, `groundpage.js`), workbench `/dev/ground`. Mounded soil beds, no boards, trodden paths, sown beds raked and unsown beds dug.
  - Replant: `home_ground` in `tools/replant` and `Server/.api/replant.php`; the crop is derived from the habit the plan carries.
- **Tests**: SeedCore 378/0 on macOS, 372/0 under WebAssembly; every PHP check passes, including the new `check_home_ground.php`, offers and backup; replant rehearsal passes across ten areas; strings check clean.
- **Live**: `/api/garden` lists ten open; `/ground` serves and draws; `deploy.sh` checks pass. The live Home Ground holds only its ambassador.

## Files
- `docs/WEB-GARDENS.md` §"The Home Ground, chosen" → §"Decided" (items 6–7 are tonight's) → §"The Home Ground, built".
- `tools/homeground/` — the simulation, now the decided design.

## Decisions made
- Crop read off the habit rather than sent as a new trait (implementation choice, recorded in the doc).
- Unknown habit → umbel: widest spacing, commonest crop.
- Taking back keeps bed, crop and place; blanks height, family and habit.
- No words for the crops on the page.

## Next step
**Build 2 (1.0) is uploaded to App Store Connect**, 24 September 20:55 (delivery `93b033f3-8c12-4ec7-80ab-c86f6133e119`; archive `build/PeaceGarden-1.0-2.xcarchive`, `.ipa` in `build/export-1.0-2/`). It sends `habit`, `hue` and the new-shape heights — the source had since the Glasshouse and the Coppice; build 1 of 16 September predated both. `AskingTests` now checks the offer carries them. App suite 131/0 (1 skipped).
Once it is through processing and on testers' phones: the replant from a fresh copy (`tools/replant/README.md` §runbook), across all ten areas. After that, the at-scale work, or the gateways design pass.
One upload warning, harmless unless visionOS is wanted: `UIRequiredDeviceCapabilities` lists `accelerometer`, which visionOS lacks (90984).

## Open, set aside
- **Until build 2 is what people run, every Home Ground arrival is sown as an umbel.** The replant after that build (`tools/replant/README.md` §runbook) puts each in its own crop's bed. Same build is needed for the Coppice's ferns and the Glasshouse's hues.
- The commission (`tools/strings/commissions/2026-09-24/`) is regenerated: the thirteen English-only keys of the three new areas and the pad are grouped in `sheets.py`'s `WHY` and counted in its README (102 lacking per language, was 91). The sheets did not change. **Batch 2 (es fr it nb nl sv) is written and live on the site** (`4a3dba4`, deployed 24 September), unread by any speaker; the commission README tables what each wants a reader to check. Its app half ships in build 3. Batch 3 (ja ko zh ar he) is next.
- From before: young water-lily pads through the Cold Frame's walls; the Glasshouse staging crowded. Both set aside by Marcus.
- Marcus's gateways idea (glimpses of neighbouring areas) needs a design pass; hooks in `movepad.js` `neighbour()`.

## Traps
- **Token-guard hook**: blocks unbounded `cat`, `grep`, `git show`/`git diff`, heredoc `cat >`. Pipe `git show` through `head -N > file` to read a diff.
- **Dev server**: an old `php -S localhost:8803 -t Server tools/wasm/dev-router.php` may already be running from an earlier session; it serves from disk, so reuse it (`/dev/ground`, `/ground`).
- **Workbench sowing is slow**: 500 arrivals take ~20 s in the browser before anything is drawn.
- **`VectorFile.placementCannotTurn` checks every cut against every height**; the Home Ground's vector test checks each height against its own crop's cut instead.
