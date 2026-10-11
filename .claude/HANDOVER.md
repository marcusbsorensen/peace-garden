# Peace Garden: logo redesign, then build 7 — handover 11 October 2026

This session covered too much: layouts, gateways, the loading animation and the logo. The previous, longer note is at `git show 94e658a:.claude/HANDOVER.md`.

## Goal
Make the app's logo and loading animation fit the app's own calm, finely drawn look and the Interfulgent app suite. Then ship them in build 7.

## State
- **Live and verified**
  - The site serves `fd4e995`'s `Server/` (deployed 11 October). This includes:
    - the new layouts for all ten areas;
    - neighbour gateways with miniatures of each neighbour's real layout;
    - Wild Fields worn paths switched on (`'wear' => true` in the server's `.api/config.php`).
  - The replant ran by the runbook. The live garden holds only the ambassadors, so nothing moved.
- **App: build 6** is uploaded to App Store Connect as 1.0 (6). `project.yml` `CURRENT_PROJECT_VERSION` is 6.
- **On main, not yet in any build:** the loading animation in `App/PeaceGarden/Views/Loading/`. A fiddlehead grows from a fixed point over 2.0 s, on a dark `#0D0D1F` launch ground. `LoadingTests` pass. The full app suite has not been run since it went in.
- **Logo round 2: running in the cloud, unchecked.**
  - Routine `trig_01H2KVZLsUTPw7ZSgFf7brd6`, due at 01:20Z on 11 October.
  - It pushes branch `claude/logo-2026-10-11` (D and E at two weights, `suite-row.png`, `hue-map.png`).
  - The old routine `trig_01694nUqyCRsYyQCqVT8WNc5` is disabled. It compared against the wrong suite.

## Files
- `design/logo-2026-10-10/README.md`: logo round 1, with the generator `make_sheets.py`.
- `design/loading-2026-10-10/README.md`: the loading animation's decisions, with its renders.
- `design/gateways-2026-10-10/README.md`: the gateways and miniatures, and Marcus's answers on them.
- `docs/WEB-GARDENS.md`: every area's rules and dated decisions, plus the new layouts.
- `tools/layouts/README.md`: plot variants, place tables and the fill harness (`BASELINE.md`).
- `tools/replant/README.md`: the runbook for a live replant.
- `tools/icon/make_icon.py` and `icon.svg`: how today's app icon is made.
- Suite brand guide: `docs/design/suite-brand.md` on UnCubed's main branch (`~/Projects/uncubed-integration`).

## Decisions made
- **Logo direction.** D (two fronds) or E (upward flower head). A was rejected because a downward flower looks sad.
- **Logo line weight** must match the suite's app icons: Pfish, UnCubed, Animal Rescue Centre, FlagFans and FreqShift. It is not matched to the Institute marks, because the suite brand guide keeps the Institute out of the apps.
- **Logo colours.**
  - Peace Garden's existing suite-guide entry reserves lime green for it. It moves to calmer sage and moss within that band.
  - Keep clear of Pfish (light green to turquoise to light blue) and FlagFans (light brown to ochre).
  - The leaf is warm white `#F4F3EF`.
  - On the website, a bare mark without a tile.
- **Loading animation.**
  - Grows from a fixed point. No drawn soil, ever (see memory `no-drawn-soil`).
  - Lasts 2.0 s, on a dark launch ground in both appearances.
  - With Reduce Motion: no launch moment, but a still waiting mark.
  - The exchange screen keeps its `BreathingDot`.
  - Still to do: take the chosen logo's colours, and lift the leaf upward at the end.
- **Layouts.** All ten areas use option A, with Marcus's answers recorded in `docs/WEB-GARDENS.md`. In the Cold Frame pond a lotus takes one place.
- **Gateways.** Neighbours show as miniatures at half light. The minimap keeps its symbolic glyphs. Maps read left to right in Arabic and Hebrew too.
- **First garden draw.** Only add a waiting mark after measuring the real delay on a device.

## Next step
Check the logo routine (`RemoteTrigger list_runs`, `git ls-remote origin claude/logo-2026-10-11`). Then:
1. Merge its branch into main.
2. Send Marcus `suite-row.png`, `hue-map.png` and the two best `in-context.png` files.
3. Ask him to choose between D and E, and between the suite weight and the light weight.

Once he has chosen, give one agent the whole job:
- apply the logo to the app icon set, `make_icon.py`, and the website favicon and wordmark;
- recolour the fiddlehead and lift its leaf;
- set `CURRENT_PROJECT_VERSION` to 7, then run the full suite once;
- archive and upload build 7;
- deploy the website.

## Traps
- **Usage rules** (`~/.claude/CLAUDE.md`):
  - at most 2 local agents at a time;
  - Sonnet for routine work, Opus only for hard design, and set the model on every dispatch;
  - exploratory design goes to cloud routines;
  - strip connectors after every routine create;
  - routines don't notify, so check them yourself.
- **Token guard** blocks:
  - a bare `grep` without `| head`;
  - plain or heredoc `cat`;
  - "curl";
  - unbounded `git diff` or `git show`;
  - images over about 500 KB.
- **Wasm build:** use the swift.org toolchain. If new place tables are missed, delete `tools/wasm/.build/release.yaml` and `description.json`.
- **Simulators:** never use the iPhone 17 Pro (Marcus's garden). Make scratch iPhone Air simulators and delete them afterwards.
- **Worktrees:** worktrees locked by this session need `git worktree remove --force --force`. Don't remove an agent's worktree while you might still resume it.
- **Working directory:** don't `cd` into a worktree in Bash; it moves the session's working directory.
- **`deploy.sh`** protects only `.api/config.php`. Python Playwright isn't installed; the Node `playwright-core` in the npx cache works.
- **SourceKit "No such module" diagnostics** are noise.
