# Peace Garden: Wild Fields, slab, sky and shadows — handover 2 October 2026 (03:00)

The previous handover is at `git show 06a8b9e:.claude/HANDOVER.md` (30 September).

## Goal
Tonight's batch live and in build 6: the Wild Fields with water, worn paths and pasture ground; the website's plots as the app's floating slab; the app's new day sky, slab, plant screen and shadows; the 1 October translations corrected.

## State
- **On main and pushed (`b104cf3`)**:
  - the website slab, with stones only when zoomed in;
  - the Wild Fields joined: ponds B, pasture ground, worn paths and privacy9;
  - the curate tool;
  - the app's shadows (Marcus's tweaks) and the warmer plot light;
  - the reviewed translation fixes for the site and the app (REVIEW.md and APPLIED-app.md).
  - String, reference and wear/curate checks pass.
- **Live**: `b104cf3` deployed 2 October, with wear on (`'wear' => true` in the live config.php). All 42 header checks and 17 pages are clean, and the wear POSTs return 200. Screenshots are in `out/deploy-2026-10-02b/`. Before this, `d7c5d48` was live; a rollback copy is in the session scratchpad at `live-d7c5d48`.
- **Build 6 uploaded** (1.0 (6), delivery `b56c27e2-…`). Its 170 tests: 163 passed, 0 failed, 7 skipped (the opt-in renders); SeedCore 422 passed. The archive is `build/PeaceGarden-1.0-6.xcarchive` and the ipa is in `build/export-6/`. `project.yml` is at 6.
- **Running**:
  - garden-layout research (worktree branch; output in `design/garden-layouts-2026-10-02/`);
- **Then**:
  - Marcus tries /wild on his phone;
  - install build 6 from TestFlight on a real phone;
  - delete the remote `worktree-agent-*` and `claude/*` branches (all merged; the local worktrees are already gone);
  - close PR #8.

## Decisions made, 2 October 2026 (Marcus)
- Lotus B: the hollows hold water. Night ponds show star reflections and ripples. The ground is pasture. Deploy, then he tries it on his phone.
- Worn paths: privacy9 goes after privacy8, the path width stays, and **wear is switched on with this deploy**. That means `'wear' => true` in the server's `.api/config.php`, which lives only on the server and is excluded from rsync.
- Day sky B+C+D. Plot light warmed as built; the winter sun is not lowered; pre-dawn plants match the moonlit ground.
- Website plots hang the slab. Stones show only when zoomed in (1.3× plus 8 px), on both platforms.
- Shadows: noon lighter, evening sharper, the hare, fox and snail shadows kept.
- Translation review (`tools/strings/commissions/2026-10-01/REVIEW.md`, branch `claude/strings-review-2026-10-01`, PR #8):
  - Apply all 40 findings.
  - Polish *Dzikie Łąki*; Ukrainian, Russian and Belarusian *луги*/*лугі*; Greek *Τα Άγρια λιβάδια*.
  - **Keep** Vildmarken / Villmarka / Vildmarken, with Danish (and Norwegian) *på → i*.
  - The English app line becomes "Left as it is, no name is shown."

## Next steps
1. Merge the integration branch into main, then the site strings branch (based on privacy9, so it should merge cleanly).
2. Deploy: rebuild the wasm, `tools/deploy.sh --dry-run`, deploy, then set `'wear' => true` in the live config.php. Then run `--check` and confirm every page is console-clean. Tell Marcus to try /wild on his phone, and roll back if it stutters.
3. Merge shadows. Warm the plot light (`design/app-sky-2026-10-02/README.md`). Merge the app strings branch.
4. Build 6: set `CURRENT_PROJECT_VERSION` to 6, run the full suite on the iPhone Air, then archive, export and upload.
5. Clean up merged worktrees and remote `worktree-agent-*` branches. Close PR #8 once REVIEW.md lands on main through the site strings branch.

## Traps
- **The config backup won't survive a deploy:** `deploy.sh` protects only `.api/config.php`, so the next upload deletes `config.php.bak-2026-10-02`. To roll back, restore the config first, then redeploy.
- **Cloud routines:** use RemoteTrigger. Agent `isolation: "remote"` runs locally. Strip connectors after every create (`clear_mcp_connections`). Routines don't notify; check with `list_runs` and `get_run_log`.
- **Every agent brief says commit and push after each step** (Marcus, 2 October).
- **Token-guard hook** blocks:
  - unbounded `git diff`/`git show` (run git from Python);
  - "curl";
  - plain `cat`;
  - a bare `grep` without `| head`, plus `\|` in grep and `grep -r`;
  - images over ~500 KB.
- **xcstrings:** write with the Xcode dump (`indent=2`, `" : "`, three-line `{}`), and assert the round-trip first.
- **The wasm is untracked:** rebuild it with `tools/wasm/build.sh` after any SeedCore change, and copy it into any worktree you deploy from.
- **Never install onto the iPhone 17 Pro** (Marcus's garden). The iPhone Air is scratch.
- Agents share the scratchpad; give each its own subfolder.
