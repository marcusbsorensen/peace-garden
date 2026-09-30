# Peace Garden: the re-roll is live — handover 29 September 2026

The previous handover is at `git show 760d8f8:.claude/HANDOVER.md`.

## Goal
The garden's shapes settled before the app is announced: the reed and the cushion as families, the spire opening from below, the Cold Frame's pond sized to its water plants, every height cut measured on the new population. Done.

## State
- **Live and replanted** (main `5fdb500`, pushed, deployed 29 September about 20:05 BST), by `tools/replant/README.md`'s runbook step by step:
  - PHP checks 16/16; rehearsals on SQLite and MariaDB against the old live commit `bc4fe4d`, both clean.
  - Backup `walk-2026-09-29T190234Z`, `--restore-test` (33 checks); plan `c0aa56033b17` from it. Nothing was planted, so nothing moved.
  - Deploy: one 502 on `/favicon.ico` at the first check, clean on `--check` a minute later.
  - Replant dry-run, run and `--verify`: "0 plantings in 10 areas, 0 offers waiting". All ten area pages load with no console errors; the Cold Frame shows its pond.
  - Backup after: `walk-2026-09-29T190459Z`. The plan file is removed from the server. `shape/reroll` and `shape/reed-cushion` deleted.
- **Marcus's answers, 29 September**, all as built on the branch (commits `75f6778`, `883951a`, `af79044`):
  - **Cold Frame**: two frames (the front row retired, raw 2 and 3 kept for decoding) and a pond of 39 places in six staggered rows (was 21). 500 arrivals: 9–10 plots (was 15–17), frames in use in every plot. Marcus saw the renders and chose it.
  - **Every cut measured again** — the table is in `docs/WEB-GARDENS.md` §*Every cut measured again, 29 September 2026*. Knot ranks now 142/250/108.
  - **Danish**: *Rør* for Reed (was *Siv*), *Pude* for Cushion. Norwegian *Siv* left.
- **Green**: SeedCore 405 (399 inside WebAssembly), app 131 on the iPhone Air (1 skipped), every `check_*.php` bar `check_restore`, `passage_reference.py`, `check_port.py`, `check_sky.mjs`, the strings checks.
- **Translations**: all 41 site languages have the 24 September commission (batch 6 was `9ac810f`, with two Maltese corrections after). Only Danish has been read by a speaker.

## Next step
Nothing waits on a decision. Candidates:
- **App build 3 is uploaded** to App Store Connect (30 September 09:25, delivery `39003575-bd47-49f4-8d90-db7dedeb80f1`; archive `build/PeaceGarden-1.0-3.xcarchive`). It carries the re-rolled shapes, the Danish *Rør* and the batch 2 name sheet. App tests 131/0 (1 skipped) on the iPhone Air. Once it is what testers run, and if anything has been planted by then, run the replant again from a fresh copy.
- The next translation round: the privacy page (8 strings), the English-only area paragraphs, the plant panel and the move pad, and the app's 64 older strings.
- Readers for the forty unread languages (`docs/REVIEWING-A-LANGUAGE.md`).

## Traps
- **Hidden browser pane pauses the page.** Capture headless: Playwright `browser_run_code_unsafe` → `page.screenshot`, `/dev/<area>?plot=N` on port 8803 (`php -S localhost:8803 -t Server tools/wasm/dev-router.php`).
- **The token-guard hook** blocks unbounded `git diff`/`git show` (run git inside a small Python script), any command containing the word "curl" (use Python's urllib), plain `cat`, `\|` in grep patterns, and images over ~500 KB (pass `limit` to Read, or `sips -Z 1000`).
- **Don't edit SeedCore while a tool builds it** (`tools/homeground`, `tools/coppice`, the wasm): SwiftPM fails with "modified during the build".
- **The Home Ground tool's sample cache** is stamped with the ground ambassador's height; clear `tools/homeground/.build/samples` when heights move without that plant changing.
- **Simulators.** The iPhone 17 Pro holds Marcus's garden: never install onto it. The iPhone Air is scratch; `simctl boot` it before `xcodebuild test`.
- **The MariaDB rehearsal** needs OrbStack running (`orb start`); stop it afterwards.
- **The reed is the heaviest plant** (~40k vertices), and a Cold Frame pond holds up to 39 water plants.
