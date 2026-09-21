# Peace Garden: the second area — handover 21 September 2026

One thing this session: **the garden has two areas open instead of one.** The
Quiet Garden is built, live and drawn. The previous handover, whose traps still
apply, is at `git show 6a6518b:.claude/HANDOVER.md`.

## State
- **Done, tested, pushed, deployed.** `fd8c5ee` on `origin/main`. SeedCore 194,
  `check_quiet_garden` 1850 checks over 500 placements, `check_ambassador` 279,
  `check_areas` 47, `check_long_walk` 600, `check_offers`, `check_limits`,
  `check_backup` 22, `check_sky` 9729, `export.py --check` and `check_port.py`
  in step.
- Live: `/api/garden` says `travel` and `peace` are open, `/api/quiet` answers
  one plot, and `https://peacegarden.app/quiet` draws it — looked at, in the
  live browser, with *Olyne paniculata* sitting beside its bench.

## What is built (`cbbe0c8`)

### The Quiet Garden: ten plants where the walk holds forty-eight
`SeedCore/WebGardens/QuietGarden.swift`, `Server/.api/QuietGarden.php`,
`RoomStore.php`, `Server/assets/js/quietgarden.js`, `/quiet`, `/dev/quiet`.

- **The room:** a 5.2 m square, hedge round all four sides at 2.3 m, a bench
  lying across one corner with one plant beside it, and a group of three at the
  foot of the hedge in each of the other three corners. The middle and the
  middles of all four sides stay grass.
- **No tree.** Marcus dropped it: nothing grown here is one (0.24–2.04 m), and a
  drawn tree among plants grown from a genome is clip art. **The specimen is the
  plant by the bench**, which is always the plot's first arrival — so the
  ambassador gets it in plot 0 without a reserved slot, the same answer the walk
  reached yesterday by a different route. It is also what lets a 0.75 m
  ambassador be a specimen at all.
- **A group is one colour or a tone of it.** Own colour, else an unplanted
  corner, else a colour near its own — the two arcs either side, or pale. **The
  near-colour fallback is load-bearing**: measured over 300 crossings the seven
  families are badly uneven (two take 43%, pale takes 3.7%), so own-colour alone
  would strand pale groups and open plots for want of a match.
- **Back-from-arm cut at 1.13 m**, the 67th centile, because a group is one back
  and two arms. Deliberately not the walk's 1.28 m.
- **At 500 arrivals: 51 plots, 49 full**, the growing end holding six and five.
  The walk takes 11 for the same 500. Joiners: 185 own colour, 112 a tone.
- **The rule held first time**, which the walk's did not, because it borrowed the
  walk's shape rather than inventing one.
- **`quiet_garden` is a table of its own.** The two areas share no column after
  `encounter`, which is the point at which *a table for each area* stopped being
  a prediction. An offer now carries its area and is planted there.

### What looking found, all of it in the drawing
- Four hedges round an enclosure left **a notch at every corner** — a domed end
  falls to the ground over half the hedge's height, a metre on the tall ones.
  `Organic.hedge` gained a `domed` flag; the enclosure's four runs are square-
  ended and overlap by a hedge's thickness.
- The **bench lay along its corner's diagonal** instead of across it and read as
  a headstone. `atan2(z, x)`, not `atan2(-z, x)`.
- The room was **framed so tight the page's prose landed on the lawn**; `/quiet`
  frames 1.25 plot-sides.

### The app asks the garden which areas are open
`PlotService.garden()`, `GardenModel.openAreas()`, `ShowInGardenView`,
six tests in `AskingTests`.

- **It read its own compiled list until now**, so a phone learned that an area
  had opened at its next update rather than on the day — and `GET /api/garden`
  had no caller but the website, which is the thing it was built to prevent.
- **Prompted, not polled**: one GET when the share screen opens, and never
  otherwise, which is what keeps it clear of the *Alert me* switch. It carries
  no token, no body and nothing about the phone. Asked once a session.
- **What this build believes stands in** when the service cannot be reached, and
  errs toward *not yet*.
- An area this build has never heard of is **dropped, not read as travel** —
  `Area.init(from:)`'s lenient fallback is right for a stored record and wrong
  here.
- One test builds `GET /api/garden`'s reply out of
  `tools/reference/area_vectors.json` rather than by hand, so the app's decoder
  is held to the shape the service actually sends. It pins the shape, not the
  agreement: the two lists are meant to be able to differ.
- **The app names no area in any language**, and the one sentence that did
  (*"The Long Walk is the one area planted so far"*) had gone false. It now says
  the areas are planted one at a time and counts none. Giving the app ten area
  names would be 420 commissions to say what the website already says.

### A new module is a new address (`fd8c5ee`)
`/plant.wasm` is 8 MB at a path that never changes. A browser or CDN holding
yesterday's copy cannot know a new one exists, so a returning visitor was told
`/quiet` could not be reached. `index.php` now stamps the module's mtime-and-size
into each page as `data-module`, and the drivers read it. `Cache-Control` is
`no-cache` as well; a dev copy says `no-store`.

## The decisions waiting for Marcus

1. **The third area.** The Crossing is the obvious next (quadripartite, four
   paths to a centre, plants facing in) and would be the first with a structure
   that is neither hedge nor bench. The Orchard would be the first to need a
   plant to be *under* another.
2. **Whether a bench should have a back.** Seen end-on it reads as a slab, which
   is true of benches and may still be worth fixing, since two of the four
   quarter turns put it that way.
3. **Whether the share screen should hold its question back while it asks.**
   `ShowInGardenView` shows what this build believes and corrects itself when
   `/api/garden` answers, so an area opened since the build flips from *not yet*
   to *you can* within a second of the screen appearing. Decided that way
   because the two agree in every other case and a blank or a spinner would
   cost the common screen to spare the rare one — but it has not been watched on
   a device, and it is a second of bad news before good.

## Traps
- **`/plant.wasm` caching, now three ways.** Fixed for the live pages by the
  stamp above. If a page ever loads the module by the bare path again, a
  returning visitor runs the old one. `/dev/*` busts its own address every load.
  **Probe a rebuilt module under node with `node:wasi`** rather than in the
  browser pane — it takes a second and it is unambiguous. This cost three wrong
  readings across two sessions.
- **The browser pane throttles `requestAnimationFrame` to 1 Hz.** Anything timed
  in it is wrong by an order of magnitude.
- **The language banks nest under a `strings` key.** The `walk*` and `quiet*`
  strings are **not** in the per-language catalogues — they live in
  `strings.js`, English, until commissioned. Only `areaPeace` and the other nine
  area names are translated, which is why a second area cost two strings.
- **The Long Walk *is* the travel area.** Renaming either is a wrong turn already
  taken and reverted.
- **20i's CDN normalises `Accept-Encoding`** and holds a response for its full
  max-age; it is not ours to purge. Brotli never arrives. Do not measure again.
- **`/.api/` and `/.pages/` are refused by nginx's dot-directory rule.**
- **`Server/.api/config.php` is gitignored and points wherever it was last left.**
- **`swift build --package-path tools/wasm` fails on macOS** (deployment target);
  it only builds for wasm. Use `sh tools/wasm/build.sh`.
- **CI does not run `App/PeaceGardenTests`** — they need Xcode on a Mac. Opening
  the Quiet Garden left `ThemeMappingTests` asserting travel was the only open
  area, through a commit and a deploy, and nothing said so. Run them by hand
  when an area opens:
  `xcodebuild test -project PeaceGarden.xcodeproj -scheme PeaceGarden -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
- Adding or removing an app file needs `xcodegen generate`. Nothing this session
  added one.

## Still open from before
- **A plant's own page** (capability URL), then **Sign in with Apple**.
- The **Milky Way** is absent from the sky though the Wild Fields are described
  as lit by it.
- The **Wild Fields** need release-to-a-place; the **curator's tool** is unbuilt.
- Two dotted threads from plants standing near each other run almost on top of
  one another below the plot.
- **`WalkStore` has outgrown its name** — it holds the connection for a garden
  with two areas now. Renaming touches every caller and the reference checks, so
  it is a commit of its own.
- The plumbing in `longwalk.js` (GL, camera, quarter turns, the plant program) is
  shared with `quietgarden.js` by importing from it. **A third area is when that
  wants a module of its own.**
