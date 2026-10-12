# Peace Garden: build 8 assembled — handover 12 October 2026

Previous note: `git show a553669:.claude/HANDOVER.md`, about build 7 and the new logo. This session ran on Marcus's work account (hello@uncubed.app). Memory lives in the personal account's folder, `~/.claude/projects/-Users-marcus-Projects-peace-garden/memory/`.

## Goal
Ship build 8 to TestFlight with the requests Marcus made on 12 October, and deploy the privacy page that describes the new update check.

## What's in build 8 (all on local `main`, 23 commits ahead of origin)
- **Launch moment.** It shows "Peace Garden" and the version, and checks for an update once per launch.
  - The check asks the App Store in the person's own storefront only. There is no US fallback (memory `no-us-default`), and Kosovo's `XKS` maps to `xk`.
  - Limits: a 2 s timeout, silent on failure, no cookies, Low Data Mode respected.
  - When an update exists, the version label gains `arrow.up.circle`.
- **Recycling glyph** redrawn to match the new logo (`CycleGlyph`, Frond A).
- **Garden screen.**
  - The (+) sits bottom left and the turns bottom right, at all times. The arrowheads are now square to the circle.
  - The tray has **one panel per row**, darkened 20% over a thin blur. There are no plates per item (memory `one-panel-not-many`).
  - Plot types: the seven not chosen are at 0.85, and the chosen one sits in a soft pool of light.
  - The control is called **"Reset view"** (Danish "Nulstil visning"). The six other drafts are `needs_review`.
  - The garden screen draws its controls and status bar as in Dark, whichever appearance is chosen (3A, then 1A). The plant's screen, opened from the garden, still follows the chosen appearance (`inTheAppearance()` in `Chrome.swift`).
  - Pictures: `design/tray-panels-2026-10-12/` (`panels-ABC`, `grounds`, `panels-light-AB`, `answers-final`, `status-bar`).
- **Developer controls in TestFlight.** Open Settings with the cog, then hold the "Settings" heading for 2 s. A Testing section opens with:
  - the imaginary meeting;
  - the clock wind (+6h/+1d/+1w/+1m);
  - tile grid or plot;
  - old sky.

  How the gate works: `Developer.isAvailable` is true in Debug, and true in Release only when `AppTransaction` reports `.sandbox` (TestFlight). App Store copies never show it. In TestFlight, the clock moves only what's shown and never a saved date.
- **Imaginary plants go public when released** (Marcus's choice, 1C; memory `imaginary-plants-public`). Don't add a guard. Removing one takes `curate.php hide` over ssh.

## State
- `project.yml` is at **8**.
- Tests:
  - the full suite passed on `f8424f0` and on `977990c`;
  - the final run on `d54c662` (status bar merged) passed 240 tests, with 0 failures and 11 skipped. xcodebuild still exited 133: its simulator-diagnostics collection timed out after the tests had finished, which is harmless but stops a chained `&&`;
  - SeedCore passed, and `Packages/` hasn't changed since.
- The archive goes to `build/PeaceGarden-1.0-8.xcarchive`, and the ipa to `build/export-8/`.
- **Site:** deployed 12 October with the update-check paragraph, `privacy10`.

## Next steps (Marcus runs these; the classifier blocks Claude from all three)
1. ~~`git push origin main`~~ done, `6b88f54`.
2. ~~Upload build 8~~ done 12 October, through the Organizer's Distribute App (the script failed first, see Traps). The usual visionOS/accelerometer warning appeared.
3. ~~Deploy~~ done 12 October: 3 files (the privacy page, `strings.js`, `da.json`), and every check in `deploy.sh --check` was ok.
4. On the phone, from TestFlight, check:
   - the version label on the launch moment;
   - holding the Settings heading opens Testing (this is the first real check of the StoreKit gate);
   - an imaginary meeting;
   - the tray panels in both appearances.

## Open, not urgent
- **Right to left:** `ContinuingRow`'s edge fade may hide the start of the tray rows (seen before the tray rewrite; recheck).
- **String catalogue is behind main.** `tools/strings/sync.sh` would bring in about 20 keys from the web garden and Wild Fields work. "Reset view" was added by hand.
- **Dead answer sheet, for build 9.** The garden's own answer sheet has had nothing to open it since 20 September (`d2a2930`), when the notice was changed to open the plant first. Its removal is on `claude/remove-dead-answer-sheet-2026-10-12` (`146d8d3`). It compiles, and GardenControlsTests and PlotTests pass (56 of 56). Merged into main after build 8 was uploaded (Marcus: 1A 2A 3A). `ShowInGardenView` itself is live: a plant's screen opens it from its Answer mark.
- The two wasm prototype pages still use `icon.svg`.
- FreqShift's icon isn't in its repo.
- Leftover `claude/*` branches on origin, here and in uncubed, can be deleted.

## Traps
- **Token guard:**
  - It blocks any shell command containing c-u-r-l (file and branch names included), bare `cat`, and unbounded `git show`/`git diff` (put `| head -n N` straight after).
  - It blocks `grep` without `| head`. **It also misreads `\|` or a quoted `|` in a grep pattern as a pipe, so use separate `-e` flags.**
  - Images over about 100 KB must be downscaled with `sips`.
- **Upload "Failed to Use Accounts"** (`IDEDistributionUploadAccountStep`: no account with App Store Connect access for R94VDZ56RY): Xcode's Apple sign-in has lapsed. Marcus signs in again in Xcode → Settings → Accounts, or distributes from the Organizer (`open build/PeaceGarden-1.0-N.xcarchive`), which asks on the way.
- **Xcode export "Copy failed":** Homebrew rsync 3.5 is on PATH. Export with `env PATH=/usr/bin:/bin:/usr/sbin:/sbin:/Applications/Xcode.app/Contents/Developer/usr/bin` (memory `xcode-export-rsync`).
- **The Xcode project is gitignored.** Run `xcodegen generate` after every merge that adds Swift files.
- **Cloud routines on this account** use `env_01XEuhfALG2Bm8UZiSSGr96Q`. Strip the connectors, and watch with `git ls-remote` (memory `work-account-routines-github`).
- **Questions to Marcus:** numbered, with A/B/C options and the recommendation first. Visual choices go on screen with matching letters.
- **Simulators:** never the iPhone 17 Pro. Use scratch iPhone Airs, and delete them afterwards.
- **Disk:** about 38 GB free after cleanup. Delete derived data and scratch clones when done.
