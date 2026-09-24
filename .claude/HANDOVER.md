# Peace Garden: build the Coppice — handover 24 September 2026

This session did too much for one note: eight streams, all merged and deployed. Older notes: `git show b5e82ca:.claude/HANDOVER.md`, `git show 61223ee:.claude/HANDOVER.md`.

## Goal
Open all ten garden areas before the app is announced. Eight are open; the Coppice and the Home Ground are designed and decided, not built.

## State
- **Deployed and checked live** (main `7a7498a`, pushed):
  - Front page B.
  - A glyph bar on every page: Garden mark, a book for `/meanings`, a globe and the language chooser.
  - Area pages as two outlined panels: the area's name and its meaning as a dictionary entry; the pad over the minimap.
  - The `/meanings` glyph dictionary.
  - `/garden` sends an open area straight to its page and no longer asks `/api/count`.
  - The Cold Frame's glass propped at 0.16.
  - Asset stamping and an import map in `Server/index.php`.
  - The security fix in `Offers.php`.
  - Privacy retention: withdrawn, declined and 30-day offers are erased to keyed hashes; 55-minute rate windows; the new seven-paragraph privacy page.
  - The Glasshouse, the eighth area; the Home Ground glyph; the Danish round.
  - The live migration ran: `offer_key` and the Glasshouse tables exist, and the one declined offer is hashed.
- **Merged but not released:** the app's name-meaning sheet (book beside the name on the Seed screen) and the Glasshouse `hue` sent by the phone. Both need an app build. Until then, Glasshouse plants take the first free pot from the door.
- **Marcus has not yet** added the cron line in 20i Scheduled Tasks. Until he does, the privacy page's "up to an hour" is not guaranteed:
  `*/5 * * * * /usr/bin/php $HOME/public_html/.api/sweep.php >> $HOME/backups/sweep.log 2>&1`
- **Mac backups** now live in `~/Library/Application Support/Peace Garden backups`. The launchd prune runs daily at 09:41 and has run once, exit 0.

## Files
- `docs/WEB-GARDENS.md`: the Coppice and the Home Ground, each "chosen", "fill, simulated" and "Decided, 24 September 2026"; also the Glasshouse as built.
- `tools/coppice/`, `tools/homeground/`: their simulations.
- `Packages/SeedCore/Sources/SeedCore/WebGardens/Glasshouse.swift`, `Server/.api/GlasshouseStore.php`, `Server/.pages/glasshouse`: the latest area built end to end. Copy its shape for the next.
- `Server/.api/TakenBack.php`: what each store keeps after a take-back. A new store needs its `TAKEN_BACK` entry and a `tools/reference/taking_back.php` run.
- `Server/assets/js/meanings.js`: the one table for the dictionary, the area entries and the glyphs; `splitEntry` splits a meaning line at its colon.
- `tools/strings/commissions/2026-09-24/`: sheets for the other 40 languages. Danish is done and read. The privacy keys are ready to translate.
- `design/at-scale/2026-09-24-sheet.jpg`: all eight areas at their share of 10,000 shared plants.

## Decisions made
- **Coppice:**
  - 33 a plot, in three coupes. Ferns on the stools, cut with their coupe; stars on the floor, never cut.
  - The rotation turns at the winter solstice (21 December UTC). Stars mixed as they arrive.
  - It needs the plant's archetype as a new trait.
- **Home Ground:**
  - Three raised beds a plot, one crop a bed (spire, umbel or succulent), each crop at its own spacing (14, 27 or 52 a bed).
  - Tall plants fill from the north end, short ones from the south.
  - Trodden-soil paths; mounded beds with no boards.
- **Glyphs over words:** the chrome is glyphs. No flags for languages: a flag is a country.
- **Dictionary headwords:** the `meaning*` lines are always "Word: definition", with exactly one colon; the site splits at it.
- **Danish:** people are "folk" or "personer", never "mennesker"; `check.py` enforces it. Danish goes first in any round, for Marcus to read.
- **Privacy wording:** approved as live. Remaining gaps, accepted: a reply link carries a little more than an offer link; "nearby" includes the same Wi-Fi network.

## Next step
Build the Coppice from `docs/WEB-GARDENS.md` §"The Coppice, chosen", in the Glasshouse's shape. That means:
- the rule and the archetype trait in SeedCore;
- the store and its `TAKEN_BACK` entry;
- the `plantInto` case and a block in `check_offers.php`;
- the page, with today's bar and panels;
- `gates.js` `BUILT`;
- the `deploy.sh` checks.

After that, the Home Ground. Then act on the at-scale sheet:
- open each area on its newest plot;
- give each area an overview;
- make the colour rules visible;
- the Quiet Garden's 84 near-empty rooms;
- Seedbed rows left part-empty in the middle of a run;
- the crowded Glasshouse staging.

## Traps
- **Playwright MCP:** it misbehaves when several agents share it; one agent's `browser_close` shut another's tab. Drive renders from a playwright-core script of your own instead.
- **"Cloud" agents:** they fall back to local worktrees here. Merge each branch, then `git worktree remove --force` and delete the branch.
- **Seeing a new deploy:** a browser that visited earlier keeps old JS unless the page is served through `index.php` with stamps. Check with a fresh profile.
- **Toolchains:** the WebAssembly suite needs `~/Library/Developer/Toolchains/swift-6.3.3-RELEASE.xctoolchain/usr/bin/swift`. Rebuild the module (`sh tools/wasm/build.sh`) before any deploy that touches Swift.
- **Before deploying a migration:** run `sh tools/backup.sh` first. Deploying migrates the live MariaDB on the first request.
- **Loose ends, left alone:**
  - PDO rounds stored decimals to 14 digits (heights are unaffected in practice).
  - `.htaccess` routes only `s|g|t`.
  - The `g` key on `/g` is labelled by the wordmark, which now leads home.
  - Unused keys: `gardenBody`, `walkBody`, `goOn`, `walkThisArea`.
