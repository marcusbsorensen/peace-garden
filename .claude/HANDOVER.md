# Peace Garden: new logo live, build 7 uploaded — handover 11 October 2026 (evening)

Previous note: `git show 7a067c8:.claude/HANDOVER.md`. This session ran on Marcus's work account (hello@uncubed.app). Memory lives in the personal account's folder, `~/.claude/projects/-Users-marcus-Projects-peace-garden/memory/`.

## Goal
Ship the new logo and the recoloured loading animation in build 7, and deploy the website with the new marks.

## State
- **Final mark chosen and ported.** D (Meeting) with T2's taper, C2's extra half turn, and variant A's lower fork and earlier taper. The record is in `design/logo-2026-10-11/README.md` §8 and its subsections.
  - `tools/icon/make_icon.py` is now the single source. It writes the app icon, `tools/icon/icon.svg`, `Server/assets/icon.svg`, `icon-180.png`, `favicon.ico`, `mark-dark.svg`, `mark-light.svg` and `favicon.svg`.
  - `tools/icon/check_port.py` compares every output with the design files; 18 of 18 match.
- **Website (main, not deployed).**
  - The bar shows the bare mark, with no tile: the light version on light pages, the dark version on dark pages, and the dark one always on the areas.
  - Tabs use `assets/favicon.svg`, the untapered small drawing.
  - **Deployed 11 October, about 20:20 BST**, from `4c85d1c`: 25 files, no deletions. `deploy.sh --check` was all ok, and the live header was checked in a browser.
- **Fiddlehead (main).** The logo's colours, the leaf lifting to 36°, a tapered stem, an outlined leaf, a 0.04 halo, and Reduce Motion's still lifted. All six of Marcus's answers are in `design/loading-2026-10-11/README.md`.
- **Build 7.**
  - `project.yml` is at 7.
  - The full suite passed: 197 tests, 0 failed, 8 skipped. SeedCore passed too.
  - It is archived at `build/PeaceGarden-1.0-7.xcarchive`, and the ipa is `build/export-7/PeaceGarden.ipa`.
  - **Uploaded 11 October with `tools/upload-build.sh 7`**, run by Marcus. The upload goes through Xcode's signed-in account and reads no key file.
  - App Store Connect warned that `UIRequiredDeviceCapabilities` includes `accelerometer`, so the app won't be offered on visionOS. This is informational.
- **uncubed `suite-brand.md`:** done on both branches, `main` at `7d23ed82` and `integration` at `9e2ba859`, with identical copies. The leftover `claude/suite-brand-*` branches there can be deleted.

## Next steps
1. Install build 7 from TestFlight on a real phone once it has processed. Check the icon on the home screen, the launch moment (the leaf lifting) and Reduce Motion's still.
2. **Open, not urgent:**
   - the recycling glyph in `Chrome.swift` still echoes the old spiral (see `design/icon-port-2026-10-11/README.md`);
   - the two wasm prototype pages still use `icon.svg`;
   - FreqShift's real icon isn't in its repo (logo round two README, question 7).
3. **Uploads and deploys.** The auto-mode classifier blocks Claude from both, and from editing its own permissions. Marcus runs `sh tools/upload-build.sh N` and `tools/deploy.sh` himself, or adds `Bash(sh tools/upload-build.sh:*)` and `Bash(tools/deploy.sh:*)` to `.claude/settings.local.json`. Run the deploy in a real terminal with `; echo "exit=$?"`: through the session's shell input, the dry run once stopped after its first line.

## Traps
- **Token guard:**
  - it blocks any shell command containing the word c-u-r-l, file names included (for example `curl-compare.png`), so use globs or the Read tool;
  - it also blocks bare `cat`, `grep` without `| head`, unbounded `git show`/`git diff` (put `| head -n N` straight after), and images over about 100 KB, so downscale with `sips` first.
- **Xcode export fails with "Copy failed"** when Homebrew's rsync 3.5 comes first on PATH. Run it with `env PATH=/usr/bin:/bin:/usr/sbin:/sbin:/Applications/Xcode.app/Contents/Developer/usr/bin` (memory: `xcode-export-rsync`).
- **The Xcode project is gitignored.** After pulling new Swift files, run `xcodegen generate`, or the build can't find types such as `busyMark`.
- **Cloud routines on this account:**
  - use environment `env_01XEuhfALG2Bm8UZiSSGr96Q`, not the personal one;
  - strip the connectors after creating each routine;
  - routines don't notify, so watch with a background `git ls-remote` loop (memory: `work-account-routines-github`).
- **Questions to Marcus:** number them, letter the options A/B/C with the recommendation first, and put visual choices on screen with matching letters (memory: `numbered-lettered-questions`).
- **The disk is about full** (around 9 GB free). Don't keep derived data or scratch clones.
- **Simulators:** never use the iPhone 17 Pro. Make scratch iPhone Air simulators and delete them afterwards (this session's is deleted).
