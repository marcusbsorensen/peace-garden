# Peace Garden: build the Glasshouse — handover 24 September 2026

This session did too much for one note. It built the Cold Frame, chose and simulated the Glasshouse, and redid the site chrome. The Glasshouse's full note is `git show 61223ee:.claude/HANDOVER.md`. Older traps are in `git show ff3f8e5:.claude/HANDOVER.md`.

## Goal
Open all ten garden areas before the app is announced, with a front page that shows the garden rather than describing it. Seven areas are open.

## State
- **Done, pushed and deployed** (`afcb978`, CI green). Live, and checked: `/meanings`, `/frame` and `/knot` answer 200; `gates.js`, `meanings.js` and `site.css` match byte for byte; no console errors.
  - Each minimap cell shows its area's ground colour and a glyph.
  - One footer row on every page: the privacy link and the language choice.
  - Hairlines above and below each area page's pad and map.
  - A block on each open area page saying what its plants mean.
  - A new page, `/meanings`, with the lookup table.
- **The Cold Frame is live** (`a1e6b0b`).
- **The Glasshouse is designed and simulated, with no code.** It is written up in `docs/WEB-GARDENS.md` §*The Glasshouse, chosen* and §*The fill, simulated*.
- **Front page B is live** (`5b18834`, deployed 24 September; `/` checked live at 1280px: plant drawn, ten cards, seven links, no console errors). Markup in `Server/.pages/index`, script `Server/assets/js/frontpage.js`, styles at the end of `site.css` (§The front), eight `front*` keys in `strings.js`, English only for now. Built on the site's own bar, foot and colour tokens rather than the prototype's; cards use the `meaning*` lines and `notYet`.
- **Unused keys kept:** `gardenBody`, `walkBody`, `goOn` are said nowhere now. Marcus chose to keep them for now.

## Files
- `tools/wasm/web/front-b.html`: the chosen prototype, at `/dev/front-b`, with inline styles and script.
- `tools/wasm/web/front-a.html`: the rejected night design, kept for reference.
- `tools/wasm/Sources/PlantWasm/Front.swift`: `pg_front_meeting(n)`, a demonstration meeting grown by `pg_grow_hybrid`.
- `Server/.pages/index` and `Server/assets/js/page.js`: the live front page, which B replaces.
- `Server/assets/js/gates.js` `LOOK`: each area's ground colour and glyph path. The minimap and both prototypes read it.
- `Server/assets/js/meanings.js`: the one table of theme meanings, heads, roots and subthemes. `showGathers(theme, strings)` draws an area page's block.
- `Server/assets/site.css`: `.bar-foot` (the footer), `.walk-page > .walk-ways` (the hairlines), `.minimap*`, and the meanings section at the end of the file.

## Decisions made
- **Front page B, "the stage by day":**
  - One large plant you can drag to turn: the child of a demonstration meeting.
  - A line on meet, cross, grow, each with a 56px glyph.
  - Ten cards, each showing its ground colour, glyph, meaning and name. Open areas come first; closed ones are greyed.
  - It follows the reader's light or dark setting.
- **The block on each area page is meaning plus the subtheme row plus a link.** Marcus dropped the name-starts line to keep the pad above the fold. The name-starts are on `/meanings`.
- **The ten one-line meanings are new wording** (`strings.js` `meaning*` keys), approved by Marcus. `commission.py`'s `sense` lines were not used, because they only list the subthemes.
- **Subtheme labels and second-word glosses stay English data** in `meanings.js`. They are not catalogue keys, which avoids about 60 commissions.
- **The Glasshouse design:**
  - Staging plus a border, 32 a plot: 24 pots and 8 in the border.
  - The border cut is `Orchard.crownFrom` (1.30).
  - The staging is a hue spectrum: 12 bands of equal share, the circle cut at 114°, then the pot's own band, then one band off, then a new plot.
  - Pale plants take any gap.
  - The border fills in arrival order from the door.
  - Hue becomes a fourth trait, `PlantTraits.hue`, and needs no tolerance.

## Next step
Build the Glasshouse, from `git show 61223ee:.claude/HANDOVER.md` and `docs/WEB-GARDENS.md` §*The Glasshouse, chosen* and §*The fill, simulated*. Commission the eight `front*` keys when the next string round goes out.

## Traps
- **The Write hook opens local files as `file://` tabs** in the browser pane. They take focus, and screenshots of the real tab then come back blank. Close those tabs and select the working tab again.
- **Screenshots miss content scrolled into view by a script.** To see a whole page, make the window tall (`resize_window` 1280×2200) and reload, then set the viewport back to `desktop`.
- **The WebAssembly suite needs the swift.org toolchain**: `~/Library/Developer/Toolchains/swift-6.3.3-RELEASE.xctoolchain/usr/bin/swift`. Plain `swift` crashes. If the build fails, `run-wasi.mjs` runs the stale test bundle and reports green.
- **`WalkStore::plantInto` sends an unknown area to the Long Walk and says nothing.** A new area needs its case there and a block in `check_offers.php`.
- **Deploying migrates the live database.** Rebuild the module with `sh tools/wasm/build.sh`, then run `sh tools/deploy.sh`, and ask Marcus first. `deploy.sh` checks `/meanings` and `frontpage.js` now.
- **`docs/TAXONOMY.md:203,209` has Cal and Quin swapped**; `PlantName.swift` is right. Not yet fixed.
