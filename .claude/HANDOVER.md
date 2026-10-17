# Peace Garden: build 10 uploaded, Zone C designed — handover 16 October 2026

## Build 10 (16 October)
- **Build 9 is on TestFlight.** Marcus uploaded it from the Organizer.
- **Build 10 is assembled (16 October, evening), from `ca25b43`:**
  - 309 tests, 0 failures, 20 skipped (`build/test-10.log`, `build/test-10.rc`);
  - the archive is at `build/PeaceGarden-1.0-10.xcarchive`, and the .ipa is at `build/export-10/`, with CFBundleVersion 10;
  - the scratch simulator `PG-build10-Air` has been deleted.

  **Uploaded on 16 October at 18:09** with `sh tools/upload-build.sh 10` (Marcus 1A). The script worked, with no Organizer needed. App Store Connect was processing it. The log is at `build/upload-10.log`.
- **Logo:** round two is done and ported (`2cb2fd5`, BRAND.md). There is nothing left to do.
- **Space seeds, from the Interfulgent Hub session (16 October). Marcus said 2A: design them in a fresh session.**
  - Read `~/Projects/interfulgent-hub/docs/suite-crossovers.md` first.
  - Peace Garden becomes where the suite meets: each app can give a seed that opens a special area or plant here.
  - Decided so far:
    - an area only for people who have Autonaut (`~/Projects/autonaut`, brief §7);
    - space seeds carry no custom content;
    - seeds pass between a person's own apps through a suite App Group (team R94VDZ56RY), and never through iCloud or a server;
    - web apps pass seeds as a signed link or code;
    - between devices, a seed QR or code is shown only in Peace Garden or a neutral pouch.
  - **The exception, and the hard part:** another Autonaut user can find one person's space seed through the server. Autonaut never contacts the server. The space seed reaches Peace Garden through the App Group and travels in Peace Garden's ordinary seed exchange, looking like its own traffic. The reason is that 20i keeps IP logs for 12 weeks, and Autonaut use is health data. That only holds if the size, timing and endpoint match ordinary exchanges.
  - Coordinate directly with the Autonaut session. Neither session edits the other's repo.
  - **Zone C** is Marcus's code name, adopted on 16 October, for the space-garden area in Peace Garden and the space-seed exchange that feeds it (Autonaut brief §7).
  - The Autonaut session's facts:
    - the only trigger is "Send as a seed" on a finished creation;
    - the seed is a kind only;
    - Autonaut reads back seeds found for the person through the same App Group;
    - Autonaut hides both "Send as a seed" and the space garden when Peace Garden is absent, and checks presence through the App Group;
    - Autonaut has zero network code and no Xcode project yet;
    - if Autonaut is deleted, what has grown in Zone C stays.
  - **Design decided (16 October):** `design/space-seeds-2026-10-16/DESIGN.md` on branch `claude/space-seeds-design` (`93c52d6`, now `c7c7602`), not merged; building began 17 October.
    - Marcus answered: 1–5A, 6B, 7 (cross with the finder's own seed), 8A, 9B (kept after he was told the iCloud consequence), 10B, 11A, 12A, 13A, 14A, 15A.
    - In short:
      - space seeds and returns ride in two fixed slots of `POST /api/walk/pending`, sent by every phone at every start, into two SQLite pools on the server;
      - the finder crosses the found seed with their own Zone C seed, using the knock's `Pollination` derivation drawn as space flora;
      - an HPKE-sealed return brings the sender the same plant in Peace Garden's Zone C;
      - Autonaut's side is unchanged.
    - The Hub accepted the App Group layout: `group.com.interfulgent.suite`; `Seeds/v1/out|in|exchange`; `Presence/v1/<app>`, written only when missing; fixed file dates on every file.
    - Autonaut's A1–A7 are settled.
    - **Build plan (17 October):** `design/space-seeds-2026-10-16/BUILD-PLAN.md` on `claude/space-seeds-design` (`c7c7602`): 22 packages, gates G1–G8. Marcus chose 1A (build 11 carries the padded request, switch and privacy text with Zone C dormant; flora and the Zone C view in build 12), 2A (store the last find's day), 3A (small population run first), and to start building: server and words as cloud routines, app packages locally, two at a time.
    - **Agreed with Autonaut (17 October):** staged writes via `Seeds/v1/tmp/<app>-<random>` then rename; malformed files deleted on sight; directory dates fixed too; Peace Garden is iOS only, so Zone C stays shut on a Mac. Flora kinds are with Marcus via the Autonaut session.
    - **Progress (17 October, about 01:00 UTC).** Integration branch `claude/zonec` (`48705ae`) = design + S1 pools (tests pass locally) + W1 English (Marcus approved G2a: privacy7 and About as written; privacy11 "The garden's nightly backup leaves the pools out."; switch *News from the garden*; Zone C row "Seeds can pass between this app and Autonaut.") + A0 App Group (24 tests) + A1 store (30 tests) + A2 crypto (23 tests; 1,024 openings 90 ms of a 100 ms bound). Running: A3 launch request (local, `.claude/worktrees/zonec-a3`); cloud S2+S5 (`trig_01VBvyXULLGpYVnnai5DXWHW`, branches `claude/zonec-s2`, `-s5`); Opus review of A2 (`trig_017rZ19aLt1sEJY5xMcZx6PP`, `claude/zonec-a2-review`, `REVIEW-A2.md`); W2 site translations as two cloud routines: Danish `trig_01V5GPepHXQAxzMQdecYV97T` (`claude/translate-zonec-site-da`, record with "For Marcus to decide") and the other 40 `trig_01FKTLVEG3n1tRUC5gjRVUd3` (`claude/translate-zonec-site-rest`, committed per batch of 10). Subagents cannot reach RemoteTrigger; create routines from the coordinator. Scratch simulator `D5BC11B1-4A87-49EF-8F90-966720999885`; delete after the app waves.
    - **Decided 17 October:** Zone C gets its own consent switch, off by default, shown only while Autonaut is installed (DESIGN §7 item 16; Hub lawful basis 122A consent); UserDefaults key `zonec.enabled.v1`. `st_ctime` cannot be fixed (Hub risk 7). Autonaut's space flora proposal: `~/Projects/autonaut/design/space-flora-2026-10-17/` (`6d8a53a`, five kinds, four new fields); Marcus choosing which kinds via the Autonaut session, then C1.
    - **Later (17 October, about 02:30 UTC).** `claude/zonec` now `7e45632`: + A3 launch request (all classes pass), + S2 pending route (`check_aloft.php` passes locally), + S5 lock-test script (`tools/zonec/locktest.sh`; running it on 20i is gate G4). Opus review of A2 (`REVIEW-A2.md` on `claude/zonec-a2-review`): nothing serious; findings 1, 3–6 go to the A5 agent, finding 2 (Debug builds send padding only to production) to A4. Running locally: A4 engine (`.claude/worktrees/zonec-a4`, also: open returns off the main actor; delete an `out` file only when the answer carries an `aloft` bundle) and A5 switches/About/reset plus the review fixes (`.claude/worktrees/zonec-a5`). Cloud: W2 translations. `tools/reference/check_sweep.php` fails on main as well (not Zone C's); `check_restore.php` needs arguments.
    - **Later still (17 October, about 03:30 UTC).** `claude/zonec` now `8ba0f9b`: + A5 (switches *News from the garden* and *Zone C*, About, reset, A2 review fixes 1, 3–6; 139 tests), + A4 engine (201 tests incl. end-to-end; Debug sends padding only; `out` deleted only when the answer carries `aloft`; engine wired live behind the Zone C switch), + W2 site translations in 41 languages (check.py clean). Marcus read the Danish (G2b): privacy11 as written; privacy7 quotes »Nyt fra haven«, so T1's Danish app label must be **Nyt fra haven**.
    - **Space flora decided (Marcus via Autonaut, 92ade7a):** all five kinds A Star Cluster, B Comet Reed, C Orbit Vine, D Crystal Rosette, E Nebula Moss, quotations in English everywhere (Galileo, Dickinson, Glenn, Armstrong, Glenn); grown through Peace Garden's own generator and morphology; both apps render with Peace Garden's renderer. Agreed with Autonaut: SceneKit plant layer (`App/PeaceGarden/Rendering/PlantSceneBuilder`, `PlantSceneView`, `PlantThumbnail` and what they need) moves into a new Apple-only package `Packages/PlantRender` depending on SeedCore; Autonaut links products `SeedCore` and `PlantRender` from this public repo at a pinned commit (milestone 15). Send Autonaut that commit when PlantRender works, and the A–E sheet drawn by it for Marcus (G1).
    - **C1 merged (17 October, about 13:10 UTC).** `claude/zonec` now `a9688ff`: space flora `peacegarden.space.v1` in SeedCore (five kinds, four morphology traits defaulting to today, hybrid draw, `tools/reference/space_flora_vectors.json`). SeedCore 496 tests on macOS, 489 in WebAssembly, Python reference agrees; 4,750 existing meshes hashed identical before and after. C1 judgement calls for G1: kind inheritance 47/47/6; sage-to-moss leaves for all kinds; Star Cluster and Orbit Vine flowers come out small (judge on the sheet). WebAssembly on this Mac: put `~/Library/Developer/Toolchains/swift-6.3.3-RELEASE.xctoolchain/usr/bin` first on PATH and use `/usr/local/bin/node` (Homebrew node is broken).
    - **S3 and X1 merged (about 15:30 UTC).** `claude/zonec` now `0ab6acf`: deploy.sh pending check, `check_backup.php`, Server README Zone C pools; CI steps for the pools, `space_flora_reference.py` and all three key guards (the third, `check_make_key.sh`, added by the coordinator; it now asks GNU stat first). All pass locally.
    - **R1 written, not built:** `claude/zonec-r1` `1991df1` (worktree `.claude/worktrees/zonec-r1`). `Packages/PlantRender`, iOS 17 only (UIKit), moves PlantSceneBuilder, PlantSceneView, PlantThumbnail, GradientTexture, SeedHusk, StageBackdrop, StagePlantStyle cases; app-only hooks are `@_spi(PeaceGarden)`; `FloraSheetTests` writes the A–E PNGs when `TEST_RUNNER_PG_SHEET_DIR` is set. The agent stopped before the first build: disk 6.7 GB free, swap 20.4 of 21.5 GB (UnCubed SwiftPM jobs, an unlocked Autonaut xcodebuild). Resume (Sonnet agent, same worktree) when swap < 14 GB, disk > 10 GB and no other xcodebuild: xcodegen, PlantRender tests, app suite, sheet run; expect a round of compile fixes. UnCubed and Autonaut asked to use the shared xcode lock. Finished worktrees a0–a5 and c1 removed.
    - **Next:** R1 PlantRender extraction (new package; touches the app's Rendering folder), then the A–E sheet; S3 (cloud), S4 population test (local Docker, small run first), A6/A7 after G1, A8, T1 (Danish label Nyt fra haven; also the five flora names and quotations, translated fresh into the 7 app languages, never copied from published translations, with the original source kept in English — Marcus via Autonaut, 17 October), X1 (incl. the three CI key guards from A5's report), B1. **Follow-up for A1/A4:** a sent-seed record that ends after 60 launches with no plant lets its sender later find her own seed; keep the expired seeds' marks (or `r`) in a small set the finder skips.
    - **Waiting on Marcus:** send the 20i ticket (snapshots, excluding `~/peacegarden-data/`, NFS and `fcntl` locks; 8A, G5).

## Paused here (14 October, late evening)
Marcus paused development because the work account's (hello@uncubed.app) credit is running out. He'll carry on from his personal account. Nothing is running, and there are no worktrees or agent branches left except main.
- **Local main is at the HANDOVER commit after `7dd470f`** and is ahead of GitHub (last pushed `84194c8`). The unpushed commits are 29B/30A, build 9, 32B and these notes. **Marcus pushes main first.** A cloud routine can't see anything unpushed.
- **Build 9:** the upload script failed with "Failed to Use Accounts", so the Organizer was opened on `build/PeaceGarden-1.0-9.xcarchive`. ~~Ask Marcus whether the upload went through.~~ **Answered: Marcus confirmed build 9 went up to App Store Connect from the Organizer.**
- **The disk was almost full** (424 MB free and falling) while an UnCubed session archived outside the shared lock. Check `df -h /System/Volumes/Data` before any Xcode work. The large consumers belong to other projects: CoreSimulator devices (21 GB) and `/private/tmp/claude-501/*-rubiks-solving` (3.9 GB).
- **The next session starts here:** build 10 = build 32B (`CountLineShadow.shipping = .B` in `PlotView.swift`, not yet compiled on main). Bump to 10, run the full suite through the lock, archive, export.
- The lock script is in the repo: `sh tools/xcode-lock.sh xcodebuild … -jobs 4 …`. Its lock is the shared `/private/tmp/claude-501/xcode.lock`, which other projects' sessions use too.

Previous notes: `git show c83bc6e:.claude/HANDOVER.md` covers build 8 (12 October), and `a553669` covers build 7 and the logo. This session ran on Marcus's work account (hello@uncubed.app). Memory lives in the personal account's folder, `~/.claude/projects/-Users-marcus-Projects-peace-garden/memory/`.

**Credit (13–14 October):** Marcus has said to go for broke in this credit window. **The machine is the limit, not credit:** only one Xcode build or test may run at a time (memory `one-xcode-build`). Use the shared `mkdir` lock at `/private/tmp/claude-501/xcode.lock`, pass `-jobs 4`, and keep one simulator booted. On 13 October parallel builds stalled the 48 GB Mac.

## State
- **Build 8** is on TestFlight, uploaded 12 October from the Organizer, after the upload script failed with "Failed to Use Accounts" (see Traps). Marcus hasn't reported trying it on his phone yet.
- **Server and website were deployed on 14 October** from `b8ffe1f`+:
  - plot-service fixes: one yes, retried deadlocks, a schema version, one place per plant, crowd-aware limits, no self-cross, utf8mb4;
  - site fixes: the module cached a year at its stamped address, security headers (HSTS, CSP, Referrer-Policy, nosniff), no front-page jump, contrast, the map at tablet width, still fireflies under Reduce Motion, fresh copy, and a fuller `deploy.sh --check`.

  `migrate.php` reports version 1, all tables utf8mb4, and nothing in two places. A backup was taken first. The live console is clean on `/` and `/wild`.
- **Host PHP:** the site runs PHP 8.3, but the command line's `php` is 8.0. Cron now runs `/usr/bin/php83` for backup.php and sweep.php (`tools/backup.sh --install-cron` replaced the old lines on 14 October). Always run `php83` over ssh.
- **Main is on GitHub at `84194c8`.** Merged on 13–14 October:
  - the three mass tests' harnesses and reports (`design/mass-test-2026-10-13/{population,app,site}/`);
  - Settings clarity (sage switches, a coloured sun and moon, a cog by the heading, plain location labels with one line per choice);
  - title glyphs and Meet's circled X ("Not this time" kept in words over a plant just made);
  - the plant-drawing toggle on the Seed screen (three marks, one setting);
  - the time-lapse (play glyph top left, 12 s, flash-tested);
  - Share (picture, turning video, wallpaper, moving wallpaper, time-lapse; on the plant's screen and the stage; the sky follows the phone's hour, rose at dusk);
  - the About sheet with Privacy;
  - the server and site fixes;
  - accessibility (VoiceOver in the garden and tray, Dynamic Type, Settings hiding the stage, contrast, right to left);
  - garden performance (500 plants open in 89 ms of main-thread time, 0.43 GB; 2,000 plants open).

  The full suite was last run at the integration (280 tests); the performance branch ran 307 after its merge.

## State at the end of 14 October
- **App polish is merged** (`1712e2c`):
  - 24A, the foot row stays left to right;
  - 27A, the seed sheet opens half way and scrolls;
  - 28C, the VoiceOver layer is always built, 12 plants a frame after fill-in, 3–6 ms a slice.

  **Waiting on Marcus (26A):** `design/app-polish-2026-10-14/small-caps-AB.png`.
  - A, medium weight: barely moves the contrast.
  - B, `muted` for those lines: about 6.9:1 in Light against 4.9 now.
  - Separately, the garden's count line by day is 3.5:1 under every option; it needs white text or a shade.

  **Marcus answered on 14 October: 29B, `muted` for those small-capital lines; 30A, the count line in white by day.** Neither is built yet. The A/B switch commit `bae237a` on the old polish branch shows where each line is drawn.
- **The translation round (19A) is done, merged and deployed** (site, 14 October evening):
  - the app has all seven languages for every sentence in use (Danish final; "Landskab %lld");
  - the site has 146 of 146 keys in all 40 offered languages, privacy10 included;
  - Greenlandic is out of the chooser (`offered: false`) but reachable with `?l=kl`;
  - Dutch says "hij" except `meaningLight`, which must change together with the app's `theme.light.definition`.

  Records are in `tools/strings/commissions/2026-10-14/`. Marcus has `DANISH-app.md` and `DANISH-site.md` to read.
- **English copy questions found by the translators:**
  - `walkBody` says the Long Walk is "the one area with real plants", which is stale and isn't shown;
  - `downloadBody` says the plant "is nobody else's", while `growBody` says "you both have it". Marcus hasn't answered this yet.

## Next steps
1. ~~Build 29B and 30A~~ merged 14 October (`design/small-caps-2026-10-14/`). The small capitals are 6.5–6.9:1 in Light. The count line in white by day is 4.9:1 at an October noon but 3.7–4.1 in the first morning hours and through a June midday. **Marcus answered 31A** (build 9 ships as it is) **and 32B:** the count line by day draws the medium soft haze (`CountLineShadow.shipping = .B`, merged, `design/count-line-shadow-2026-10-14/`), 4.6–5.2:1 at the weak hours. Not yet built or tested on main; it goes into build 10. He is to check on a phone whether the haze looks needless at noon under plain blue sky.
2. **Build 9 is assembled** (`8681ea4`): 309 tests with 0 failures, archive at `build/PeaceGarden-1.0-9.xcarchive`, .ipa at `build/export-9/` with CFBundleVersion 9. Marcus uploads with `sh tools/upload-build.sh 9`, or from the Organizer if the Xcode sign-in has lapsed, then pushes main.
3. ~~Site deploy for the translations~~ done 14 October evening, with every check ok.
4. Marcus checks on a real phone:
   - the moving wallpaper: does iOS let a Live Photo made by the app move?
   - time-lapse and Share speed;
   - the garden with many plants;
   - the TestFlight Testing section (the StoreKit gate).

## Open, not urgent
- **Server finding 7:** responses grow with the garden (`/api/wild` count, tiles). Fine at today's size.
- **When a yes and a withdrawal arrive at the same moment, the withdrawal can lose** (2 of 30). The state stays consistent.
- **`/meanings` CLS** is 0.16–0.21, the same cause as the front page had. Area pages opened on a plant shift 0.03–0.05; that's older than this work.
- **2,000 plants with fireflies** don't hold 60 fps. Some single frames still grow with garden size.
- **A dusk longer than the time-lapse's** in shared pictures would be a new choice for Marcus. He was offered it and hasn't asked.
- The wasm prototype pages still use `icon.svg`. FreqShift's icon isn't in its repo. The leftover `claude/suite-brand-*` branches in uncubed can go.
- **Remote `claude/*` branches from 13–14 October** are all merged and can be deleted. Marcus runs the delete.

## Traps
- **Token guard:**
  - It blocks c-u-r-l anywhere in a command, bare `cat` (including heredocs into files, so use Write), and `grep` without `| head`.
  - It reads `\|` or a quoted `|` in a grep pattern as a pipe; use separate `-e` flags.
  - It blocks `git show`/`git diff` without `| head -n N`. To save a file, use `git show X:f | head -n 3000 > out`.
  - Images over about 100 KB need a `sips` downscale first.
- **Upload "Failed to Use Accounts":** Xcode's Apple sign-in has lapsed. Sign in again under Xcode → Settings → Accounts, or use the Organizer (`open build/PeaceGarden-1.0-N.xcarchive`).
- **Xcode export "Copy failed":** Homebrew rsync is on PATH. Export with `env PATH=/usr/bin:/bin:/usr/sbin:/sbin:/Applications/Xcode.app/Contents/Developer/usr/bin`.
- **xcodebuild exit 133** after "** TEST SUCCEEDED **" means a simulator-diagnostics timeout; read the log. Don't chain archives on `&&` after a test run.
- **The Xcode project is gitignored.** Run `xcodegen generate` after every merge.
- **Docker is OrbStack.** It stops if the disk fills; restart with `open -a OrbStack`.
- **Marcus's choices that look like bugs:** imaginary plants release publicly (`imaginary-plants-public`); wear is on at the live site (18A).
- **Questions to Marcus:** numbered, with A/B/C options, the recommendation first, and pictures for anything visual.
- **Simulators:** never the iPhone 17 Pro. Use scratch simulators and delete them.
