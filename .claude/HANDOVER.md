# Peace Garden — handover 3 September 2026

*An overnight session, run with Marcus asleep and told to decide, document and
keep going. Everything it decided alone is in `docs/FOR-REVIEW.md` or named under
**Decisions made** below, so it can all be overturned in the morning.*

## Goal

Three things on `main`, finishing the previous handover's next step; then a
branch, `round-two`, for the night: wave two of the passage banks, support for
the other alphabets, the site's settled words in sixteen languages, and the
website stages that were already specified. Situational navigation — a random
plant, named areas, a pad for stepping to neighbours, and a key for every action
— was asked for partway through and is built.

## State

`main` at `0fda1bb`. `round-two` branched from it, **not merged**.

**Verified.** 72 SeedCore tests, 23 app tests, all four CI checks run locally.
The stage driven on a simulator in both directions and at five ages; the site
driven in a browser — the map, an area, the walk under arrows and hjkl, the
sheet, the pad disabling a direction at the map's edge. Every landed bank checked
by `assemble.py` and independently for overlap against every bank before it.

**Unverified.** *No non-Latin passage has been drawn on a screen.* The route is
`PlantRevealView`, which needs a completed exchange — reach it with
`Developer.shared.wantsImaginaryMeeting`, or write a garden with a crossed plant
in it, which `tools/`-adjacent scratch already does. The scripts were checked
through `assemble.py` and in CSS; the app has not been asked to draw one.

## Files

- `Server/assets/js/garden.js` — the map, derived from `Quotes.Theme.position`;
  cells derived from seeds. `selfTest()` needs no browser.
- `Server/assets/js/keys.js` — one registry, one listener. **The sheet is the
  registry**, so a shortcut it does not list cannot exist.
- `Server/assets/js/walk.js`, `plots.js`, `Server/g` — the walk, and a stand-in
  for the plot service that says on screen that it is one.
- `tools/quotes/land.py` — assemble, register, xcodegen, export, in that order.
  Use it for every remaining bank.
- `docs/FOR-REVIEW.md` — **read this first.** The site's six prose strings and
  ten area names, with the argument and its alternatives. Nothing in it is live.
- `docs/WEBSITE.md` §*Walking it* and §*Every action on a key*;
  `docs/LANGUAGES.md` §*The other alphabets*.

## Decisions made

- **The garden's map is derived, and must not move.** Ten areas laid out from
  `Theme.position`'s first two principal components — 85% of its variance, the
  first axis motion against duration, the second company. Retuning a theme's
  position is now a change to the map.
- **A plant's cell comes from its seed and never moves.** Two plants may share a
  cell, and that is drawn.
- **Drawn marks never mirror; layout does.** A seed, a flower and a gear have a
  shape rather than a handedness. `View.drawnHand()`.
- **Arabic is never letter-spaced.** It is a joined script and tracking severs
  the joins. `Chrome.neverTracked`, mirrored in the site's CSS.
- **The shortcut sheet costs one string**, because each row is labelled by the
  control it operates. Adding a shortcut must not add a commission.
- **Area names are English proper nouns, provisionally** — the same argument the
  app already makes about plant binomials. This is the first thing in
  `FOR-REVIEW.md` and the one most likely to be overturned.

## Next step

Land the banks that finished after this was written. For each:
`python3 tools/quotes/land.py <Language> <code> <file>`, then the thirteen site
labels in `Server/strings/<code>.json`, then commit one bank per commit. The
files are in the session scratchpad under `banks/`; `QUEUE.md` beside them holds
the six that never got a slot.

## Traps

- **Twenty concurrent subagents is the ceiling**, and it is not raised by agents
  finishing quickly. Commission in waves and keep a queue file.
- **`cd` persists between Bash calls.** It bit again: an `xcodebuild` ran from
  `Packages/SeedCore` and silently tested nothing.
- **`GardenStoreTests` fails when the Mac's screen locks.** `GardenStore.guarded`
  ties readability to the lock, so the suite passes all day and fails overnight;
  CI never sees it because SeedCore runs on Linux there. Fixed by injecting the
  write options, but the shape will recur anywhere else protection is used.
- **A browser caches ES modules by URL.** A changed module can appear missing;
  moving the dev server to a new port is the quickest way to be sure.
- **`assemble.py`'s floor is 10 and the brief asks for 12.** Passing the checker
  is not the same as meeting the brief.
