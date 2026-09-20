# Peace Garden: the ambassador stands — handover 20 September 2026

One thing this session: **the Long Walk stopped being empty.** *Halula
crassicaulis* is in plot 0, and two of the three decisions the last handover
left for Marcus are closed. The previous handover, whose traps still apply, is
at `git show 75e2c8a:.claude/HANDOVER.md`.

## State
- **Done, tested, pushed, deployed.** `8462dce` on `origin/main`. SeedCore 181,
  `check_ambassador` 272 checks, `check_areas` 47, `check_long_walk` 600
  placements, `check_offers`, `check_limits`, `check_backup` 22, `check_sky`
  9729, `export.py --check` and `check_port.py` in step.
- Live: `https://peacegarden.app/api/walk` answers `{"plots":1}`, `/api/walk/plot/0`
  serves the ambassador, and `/walk` draws it — looked at, in the live browser,
  standing alone in a double border with the path and the hedges.

## What is built (`8462dce`)

### The walk's ambassador stands at its head, and is not a row
- `LongWalk.ambassador` and `LongWalk.Walk.opened()` in SeedCore;
  `Server/.api/Ambassadors.php` in the service;
  `tools/reference/check_ambassador.php` holds them together in CI.
- **There is no specimen slot, and that is the answer rather than a gap.**
  WEB-GARDENS.md asked which slot of a template an ambassador stands in. A
  double border's feature belongs at the end of its vista and **this walk has no
  end** — its plots open end to end for as long as people meet — so what it has
  is a head, and the ambassador is simply the first plant the rule ever placed.
- **It could not have been the tall one at the back.** *Halula* is 1.02 m, the
  middle of a border, and only *Cyninora contorta* (kinship, 1.33 m) is a
  back-tier plant at all. A specimen fixed at the back would stand a short plant
  behind taller ones in nine areas of ten. **A specimen slot has to be one the
  area's own ambassador can stand in** — a constraint on every template still to
  be written.
- **Not a row, and that was not one of the two options on the table.** A slot and
  a nudge are pure functions of the pinned seed, so the placement is derived on
  each side rather than stored on either. Nothing for a withdrawal, a report or a
  backup to reach, and `WalkStore::plant` throws on an ambassador's seed so that
  stays true the day somebody adds a route that plants a minted one. The service
  hands it to the rule **ahead of** the stored arrivals, so everything shared
  since is graded against a border with its oldest plant in it.
- **A planting with no parents grows from its seed.** The service sends an empty
  `parents` and no meeting; `longwalk.js` reaches for `pg_grow` instead of
  `pg_grow_hybrid`. `pg_grow` already existed — no new wasm export was needed,
  though the module was rebuilt so `/dev/walk` opens with the ambassador too.
- **Flipped while the walk was empty**, the same argument as the area flip: the
  walk is append-only, so the ambassador could be its first planting only until
  somebody else's plant arrived. It had none, measured before touching anything.
- `check_offers.php` now counts the plants **gardeners** put there, because the
  walk is never empty again.

## The decisions waiting for Marcus

1. **The second area.** The only one of the three left. The Quiet Garden is
   cheapest — its hedge already exists in `GardenStructures.swift` — and its rule
   is the most distinctive ("the fewest plants per plot of any area, by rule").
   **Not started, on purpose:** the Long Walk's own notes record that *without
   the path and the hedges, a plot is a scatter of plants on grass — the rule is
   right and invisible.* Designing a second rule without being able to look at it
   rendered repeats exactly that. It wants a session with eyes on it.
2. **Whether an area's template must give its ambassador a slot it fits.** Found
   this session and not yet a rule anywhere: nine of the ten ambassadors are edge
   or middle plants. The Quiet Garden's *Olyne paniculata* is 0.75 m, so whatever
   "the one tree" of an enclosure turns out to mean, it is not that plant.

## Traps
- **The browser pane caches `/plant.wasm` hard.** A rebuilt module was still the
  old one in the page, and a cache-busted 7.9 MB fetch times out the JS tool.
  Probe a rebuilt wasm under node with `node:wasi` instead — it takes a second
  and it is unambiguous. This cost a wrong reading of `pg_walk_plots` once.
- **The browser pane throttles `requestAnimationFrame` to 1 Hz** regardless of
  `document.hidden` or fronting the tab. Anything timed in it is wrong by an
  order of magnitude.
- **The language banks nest under a `strings` key.**
- **The Long Walk *is* the travel area.** Renaming either on the assumption they
  are two things is a wrong turn already taken and reverted.
- **20i's CDN normalises `Accept-Encoding`.** Brotli never arrives. Measured 20
  September; do not measure it again.
- **`/.api/` and `/.pages/` are refused by nginx's dot-directory rule**, so only
  `index.php` can serve from them.
- **`Server/.api/config.php` is gitignored and points wherever it was last left**
   — this session found it aimed at a previous session's scratchpad SQLite, with
  120 arrivals in it placed before the ambassador existed. A local walk that
  looks wrong may just be stale: delete the file it names and re-send arrivals.
- Adding or removing an app file needs `xcodegen generate`. Nothing this session
  added one.

## Still open from before
- **A plant's own page** (capability URL). WEBSITE.md says it is built first and
  it is what makes a plot worth having.
- **Sign in with Apple**, deliberately behind the plant page.
- The **Milky Way** is absent from the sky though the Wild Fields are described
  as lit by it.
- The **Wild Fields** need release-to-a-place; the **curator's tool** is unbuilt.
- Two dotted threads from plants standing near each other run almost on top of
  one another below the plot.
- The app's `-pgArea longWalk` preview draws **the gardener's own plants** into a
  Long Walk-shaped plot, so it has no ambassador and deliberately was not given
  one: it is a preview of the structures, not of the walk.
