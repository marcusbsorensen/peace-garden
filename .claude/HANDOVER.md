# Peace Garden: the re-roll's three answers are built and rehearsed — handover 29 September 2026

The previous handover is at `git show b158188:.claude/HANDOVER.md`.

## Goal
Promote the reed and the cushion to archetypes, flip the spire, re-roll and replant the garden once (approved 28 September), with Marcus's three answers of 29 September built in.

## State
- **Branch `shape/reroll`, on `main`'s `bc4fe4d`. Not merged, not pushed, not deployed, not replanted.**
  - `cd2f07f`, `d7b7cb9`, `485bd85` — the re-roll itself (see the previous handover).
  - `75f6778` Danish: *Rør* for Reed (was *Siv*), *Pude* for Cushion. Norwegian *Siv* left.
  - `883951a` **Cold Frame: a bigger tank.** Front row of frames retired (raw 2, 3 kept for decoding), tank takes its ground: 39 places, six staggered rows of 7/6, 0.62 m along, 0.57 m between rows, 4.4 × 3.16 m at `tankZ` 0.6; `frameZ` 1.65. At 500: 9 plots (was 17), frames in all 9, glass 73% held (was 19%). `sinkPool` has an optional `bank`. Cut 0.50 → 0.49.
  - `af79044` **Every cut measured again** on three thousand crossings (list in `docs/WEB-GARDENS.md` §*Every cut measured again, 29 September 2026*): Long Walk 0.75/1.18, Quiet 1.08, Crossing 0.85/1.34, Orchard + Knot 0.48/1.18, Glasshouse 1.16, Coppice 0.99, Home Ground spire 1.261 / rosette 0.266 / umbel 0.930. Coppice samples regrown.
- **Green:** SeedCore 405 (399 inside WebAssembly), app 131 (iPhone Air, 1 skipped), every `tools/reference/check_*.php` (bar `check_restore`), `passage_reference.py`, `check_port.py`, `check_sky.mjs`, strings checks, `tools/replant/rehearse.sh main`.
- **Wasm rebuilt** into `Server/.pages/` (untracked) from this tree.
- **Renders** in the session scratchpad `reroll/` (`reroll-answers.jpg`): Cold Frame before/after at plots 1, middle, last; Knot and Coppice plot 1 before/after.

## Open questions for Marcus
- Look at the renders: the Cold Frame is now a pond with two frames behind it. In a young garden a third colour opens a new plot (two frames a plot), so the rehearsal's small garden went from 2 plots to 4, the later ones mostly empty water.
- **Go-ahead to back up, deploy and replant** (outward-facing).

## Next step
When Marcus says go: `tools/replant/README.md` §the order — `sh tools/backup.sh`, `--restore-test`, plan from that copy and read its notes, deploy (`tools/deploy.sh`), run `replant.php` with `--dry-run` then for real, `--verify`. Then merge `shape/reroll` to `main` and push.

## Traps
- **Hidden browser pane pauses the page.** Capture headless: Playwright `browser_run_code_unsafe` → `page.screenshot`, `/dev/<area>?plot=N` on port 8803 (`php -S localhost:8803 -t Server tools/wasm/dev-router.php`).
- **The token-guard hook** blocks unbounded `git diff`/`git show` (use a small Python script running git), any command containing the word "curl", plain `cat`, `\|` in grep patterns, and images over ~500 KB.
- **Don't edit SeedCore while a tool builds it** (`tools/homeground`, `tools/coppice`, the wasm): SwiftPM fails with "modified during the build".
- **The Home Ground tool's sample cache** is stamped with the ground ambassador's height; clear `tools/homeground/.build/samples` when heights move without that plant changing.
- **Simulators.** The iPhone 17 Pro holds Marcus's garden: do not reinstall onto it. The iPhone Air is scratch.
- **The reed is the heaviest plant** (~40k vertices), and a Cold Frame tank now holds up to 39 of the area's water plants.
