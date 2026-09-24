# Peace Garden: nine areas, new shapes, the move pad — handover 24 September 2026 (night)

This session did too much for one note: the Coppice, new plant shapes everywhere, and new page navigation. All three are merged, deployed and live. Older notes: `git show 16b42c2:.claude/HANDOVER.md`.

## Goal
Open the tenth area, the Home Ground, before the app is announced, on the new plant shapes.

## State
- **Live and checked** (main `f8e4591`, pushed, deployed; backups taken before and after):
  - **Coppice**, the ninth area: `/coppice`, rule `Packages/SeedCore/Sources/SeedCore/WebGardens/Coppice.swift`, `PlantTraits.habit`, a year that turns on 21 December UTC.
  - **New plant shapes**: a habit per archetype (crown leaves; rosettes for succulent, fern, orchid and lotus; lotus pads), a closed calyx under every bloom in place of the ring, and round petals (star and thistle stay pointed). Median height÷spread 1.29, against 2.15 before; 30% of plants are wider than tall.
  - **Every area's cuts re-measured**, and every vector file re-recorded. The Glasshouse border has its own cut again (1.14). The Cold Frame cut is now 0.38.
  - **Replant**: run live and verified. It moved nothing, because the live garden holds no plantings.
  - **Move pad** on all nine area pages (`Server/assets/js/movepad.js`): directions follow the screen; zoom and turns in the corners; the centre key, a dot in a square, glides home. Nine live pages load clean in a fresh browser.
  - **Sweep cron** runs on the server every five minutes.
  - **Tests**: SeedCore 357/0, WebAssembly 351/0, app 131 pass, every PHP check passes.
- **Waiting on an app build**: the phone does not yet send `habit` or `hue`, and still sends old-shape heights. Once that build ships, run the replant again from a fresh copy (`tools/replant/README.md` §runbook).
- **Unverified**: the Coppice's years 1 and 2 on the live service, which stays in year 0 until 21 December.

## Files
- `tools/replant/README.md` — how to replant the live garden; the runbook's steps are in order.
- `docs/WEB-GARDENS.md` — every area's design and measured numbers, re-measured 24 September; §"The Home Ground, chosen" is next.
- `docs/PLANT-FORMS.md` §"Habit" — the new shapes.
- `Packages/SeedCore/Sources/SeedCore/Genome/Archetype.swift` `profile(for:)`, and `Morphology/PlantBuilder.swift` (`addCalyx`, crown leaves, pads, petal outline): the shape levers.
- `tools/homeground/` — the Home Ground's simulation; its samples are now keyed to SeedCore's shapes.

## Decisions made
- **Shapes changed everywhere (option c)**, and the live garden replanted, rather than versioning the shape rules.
- **A closed green calyx under the petals**, with its colour drawn from the leaf. `MeshRole.calyx` is placed last so older role indices hold.
- **Move pad**: plots are treated as a line, because the service sends only a count. Home keeps the turn.
- **Coppice**: no stage words on the page.
- **Standing rules**: no straight lines in the garden; glyphs over words; Danish says "folk"/"personer", never "mennesker", and goes first in any round.
- **Marcus's idea for later**: gateways that show glimpses of neighbouring areas. It hooks in at an area's first and last plot edges in `movepad.js` `neighbour()`. It needs a design first: which area lies past which end.

## Next step
Build the Home Ground. First put Marcus the two design points found under the new shapes: its rosettes are 0.38 m wide on a 0.28 m spacing, and its umbel cut, 0.932, sits 0.009 mm from an arrival. With those answered, the Glasshouse and Coppice builds are the template: rule, port and store, then page, then the `gates.js` BUILT entry, then the deploy checks.

## Open, set aside by Marcus
- Young water-lily pads reach through the Cold Frame's walls in 55% of end places. The recommended fix is to draw young flat leaves smaller.
- The Glasshouse staging is crowded: 99% of its plants are wider than the 0.30 m gap. Recommended: leave it for the at-scale work.
- `coppiceAbout`, `coppiceAway`, `moveUp`…`zoomOut` and `moveHome` are English only. Regenerate `tools/strings/commissions/2026-09-24/` with `sheets.py` before sending; `walkBack` and `walkOn` are gone.

## Traps
- **Token-guard hook**: blocks unbounded `cat`, `grep`, `git show`, heredoc `cat >` and large images. Use `rg`, `head`, Read with offset/limit, and the Write tool; downscale screenshots with `sips -Z 1000` first.
- **Renders**: don't use the Playwright MCP. Drive playwright-core scripts of your own with a fresh profile; the local server is `php -S localhost:8847 -t Server tools/wasm/dev-router.php`.
- **MariaDB**: the restore test and `rehearse.sh --mariadb` need OrbStack (`open -a OrbStack`). Quit it afterwards.
- **Before any deploy that touches Swift**: run `sh tools/wasm/build.sh`; the module is built, not committed.
- **The `shape/broader` worktree** (`.claude/worktrees/agent-af70adf3868978ef3`) is merged but locked by a finished agent. Remove it with `git worktree remove -f -f`, then delete `shape/broader` and `worktree-agent-af70adf3868978ef3`.
