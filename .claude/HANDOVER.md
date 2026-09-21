# Peace Garden: the third area — handover 21 September 2026

Two things this session: **the bench has a back**, and **the Crossing is open**.
Three of ten areas are planted now. The previous handover, whose traps still
apply, is at `git show 9bed47c:.claude/HANDOVER.md`.

**If you are the session picking this up: the fourth area is decided and not
started.** Read *The fourth area is the Orchard* below, then the Traps, and
build. Nothing else here is outstanding.

## State
- **Done, tested, pushed, deployed.** `9a483c7` on `origin/main`. SeedCore 207,
  app 129 (1 skipped, run by hand in the simulator), `check_crossing` 1959
  checks over 500 placements, `check_quiet_garden` 1850, `check_ambassador` 279,
  `check_areas` 47, `check_long_walk` 600, `check_offers`, `check_limits`,
  `check_backup` 25, `check_sky` 9729, `export.py --check` and `check_port.py`
  in step.
- Live: `/api/garden` says `travel`, `meeting` and `peace` are open,
  `/api/cross` answers one plot, and `https://peacegarden.app/cross` draws it —
  looked at, in the live browser, grass quarters and all, with *Melyrina
  latifolia* on the first quarter's diagonal.
- **The host's SSH IP allowlist stopped a deploy mid-session.** rsync answers
  `Connection reset by 45.8.225.251`, not a permission denial, because the
  allowlist gates SSH before authentication. It is My20i -> peacegarden.app ->
  Security -> SSH Access, and it needs whatever this Mac's public IP is that
  day (api.ipify.org gives it). Only Marcus can set it.

## The bench has a back (`2d4c541`)

Decision 2 from the last handover, and it was real: seen down its own length the
seat was one upright panel 0.42 m across and very nearly square — a slab — and
two of the room's four quarter turns put it that way, so half of every view of
the Quiet Garden had one. A post standing on each end carries two rails, which
puts a shoulder in the end-on silhouette. Two rails and not one board: a back in
one piece is the same panel the ends already are.

The back is on the bench's `+x`, which the room turns to point into its corner,
so a sitter faces the lawn with the hedges behind them. `pg_bench` keeps its
signature and no placement rule is involved.

## The Crossing (`c4da1b0`)

`SeedCore/WebGardens/Crossing.swift`, `Server/.api/Crossing.php`,
`CrossStore.php`, `Server/assets/js/crossing.js`, `crosspage.js`, `/cross`,
`/dev/cross`, `tools/reference/check_crossing.php`.

Marcus chose all three of the recommendations put to him: 24 a plot in four
quarters of six; the quarter with the fewest; a round paving at the centre with
no plant on it.

- **Twenty-four a plot**, between the walk's 48 and the room's 10. Six is three
  along the path edges, two behind them, one at the outer corner.
- **The rule is *wherever there is least*** — the emptiest quarter of the oldest
  plot that has a slot the plant fits, ties to the lowest-numbered quarter.
  **`<` and not `<=` on that count** is the only thing a port could get wrong
  while agreeing about every number, which is why the check replays all 500.
- **Cuts at 0.97 m and 1.43 m**, measured at the 50th and 83rd centiles for a
  bed of 3:2:1. Not the walk's 0.93/1.28, not the room's 1.13. *(I first wrote
  25th and 50th in the question put to Marcus; that was wrong and the code has
  the right ones.)*
- **The three at the path rank share an arc**, which is what frees them from
  having to be in order with each other. Only ranks are compared, never
  distances.
- **At 500: 21 plots, 20 full**, the growing one holding 21 with quarters at
  6, 5, 5, 5. 484 of 501 got a slot of their own rank. **The rule held first
  time**, as the room's did, because it borrowed a shape already argued about.
- **Slot spots are written out as literals**, not computed from an angle: a sine
  from a host's own library is not the same number on every host and a placement
  has to match in Swift and PHP for ever. Same reason `Organic.quarter` exists.
- **`crossing` is a third table.** The columns after `encounter` now mean a tier
  of a border, a place in a group of three, and a place in a bed of six. Three
  areas is where *a table for each* stopped being a prediction.

### The quarters are grass
Marcus looked at a plot with one plant in it and called the bare soil: four
brown quarters read as ground waiting to be dug rather than as a garden. The
slab's top is grass now, with the two paths mown through it and the quarters
left rough — a mottle carried on the corners of a 0.26 m grid, so neighbours
share their corners and no cell edge shows anywhere. The rough grass is the
turf colour at 0.9, which is what buys the mown runs their contrast.

**It also deleted a problem rather than solving one:** a quarter is no longer a
shape with an edge, so there are no four L-shaped beds to draw and no boundary
in the plot except the path's own wandering edge.

### What looking found, all of it the paving
`Organic.roundel` is the first structure that is neither hedge nor bench. It
arrived as a bright dish two metres across and took four passes:
- **Too big.** 1.0 m radius against a 1.2 m path; now 0.85, a quarter of a metre
  wider than the path on each side.
- **Too bright and too blue.** A near-neutral albedo under a blue sky ambient is
  a blue lid. The stone is warmer and darker now.
- **Its own mesh showing.** Taking the tone from the vertex's distance from the
  middle drew the rings as spokes.
- **Too smooth**, which was the real one. Smooth normals over a cambered disc
  take one broad highlight and read as a polished cover. **It is the one thing
  on the page shaded flat** — one normal and one tone a triangle, from where the
  triangle is — which is what makes it faces rather than a surface.

## The fourth area is the Orchard, and it is decided

Marcus chose it on 21 September and answered the three questions it raises. **No
code is written yet** — this section is the brief, so the session that builds it
does not have to re-decide anything.

The Orchard is `kinship`. Genus heads `Vin` (a bond) and `Cyn` (the dog at the
door); table `orchard`; heading `areaMeeting`'s neighbour `areaKinship`, "The
Orchard", already in `strings.js` and already translated in all 42 catalogues,
so — as with the last three — it costs two English strings, `orchardAbout` and
`orchardAway`.

1. **The garden plants the trees, not the gardeners.** Five trees in a quincunx
   are *structures*, like the hedges, the bench and the roundel: drawn by a new
   `Organic.tree`, standing in every plot from the day it opens, a row nowhere.
   Every arriving plant joins a guild underneath one.

   This is the roundel's move again and it was chosen for the same reason. The
   alternative — the tallest arrivals become the trees — leaves a new plot with
   five empty tree slots and guild slots that mean nothing until a tall plant
   happens along, and hands the first gardener to the Orchard a tree while the
   second gets shade. **What it costs:** the Orchard is the first area where a
   gardener's plant can never take the most prominent thing in the plot. The
   Quiet Garden's bench is the precedent that says this is allowed.

2. **Twenty a plot** — four guild places at the compass points of each of five
   trees. Between the Crossing's 24 and the Quiet Garden's 10, in the same
   5.2 m square. Four round a trunk is the spacing a guild wants; six reads as
   a ring.

3. **Fill one guild, then the next** — *not* the Crossing's "wherever there is
   least". A tree is either dressed or bare, never all five half-done, which is
   what a young orchard actually looks like. **This is the whole reason to build
   a fourth area rather than a second Crossing**: it is the opposite rule, so it
   tests whether the template survives a placement that is deliberately uneven.

### What decision 3 leaves for the build to settle
Two sub-choices follow from it and are the builder's call, not Marcus's — but
name them in the commit rather than letting them be accidents:
- **Which guild fills first.** The centre of the quincunx, then the four corners
  in quarter order, is the reading that matches how the other three areas number
  themselves.
- **Which of a guild's four places a plant takes.** Height, as everywhere else:
  the tallest behind the trunk, the lowest at the front. Note that this makes a
  guild's four ranks *fixed*, which is nearer the Quiet Garden's ten than the
  Crossing's quarters, and means the order check compares ranks and never
  distances — the trap the Crossing already taught.

### The shape of the work, from the Crossing's pattern
`SeedCore/WebGardens/Orchard.swift`, `Server/.api/Orchard.php`,
`OrchardStore.php`, `Server/assets/js/orchard.js`, `orchardpage.js`,
`Server/.pages/orchard`, `/orchard` in `index.php` and `router.php`,
`/dev/orchard`, `tools/reference/check_orchard.php`, `Organic.tree` +
`pg_tree` in `tools/wasm/Sources/PlantWasm/Dressing.swift`, a `Cross.swift`
equivalent for the plot calls, `Areas.swift`/`Areas.php` to open `kinship` and
name the table, `Ambassadors.php`, `WalkStore.php`, `backup.php`'s KEPT list,
`check_backup.php`, `check_ambassador.php`, `walk.js`'s `built` map, and
`docs/WEB-GARDENS.md`. **Re-record `area_vectors.json`** — opening an area
breaks `AreaVectorTests` by design, and rename the test to say four.

**No libm in the quincunx.** Tree spots and the four compass places are literals,
for the reason `Organic.quarter` exists: a sine from a host's own library is not
the same number on every host, and a placement has to match in Swift and PHP for
ever.

## Still waiting for Marcus

1. **Whether the share screen should hold its question back while it asks
   `/api/garden`.** Carried from the handover before last. Unchanged, and still
   not watched on a device.

## Traps
- **Run the app's tests by hand when an area opens.** CI cannot: they need Xcode
  on a Mac. This is the trap that bit last time; it did not this time.
  `xcodebuild test -project PeaceGarden.xcodeproj -scheme PeaceGarden -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
- **`/plant.wasm` caching.** Fixed for the live pages by the `data-module` stamp
  in `index.php`. **Probe a rebuilt module under node with `node:wasi`** rather
  than in the browser pane — a second, and unambiguous.
- **The browser pane throttles `requestAnimationFrame` to 1 Hz.**
- **The language banks nest under a `strings` key.** `walk*`, `quiet*` and now
  `cross*` are **not** in the per-language catalogues — they live in
  `strings.js`, English, until commissioned. Only the ten area names are
  translated, which is why a third area cost two strings again.
- **The Long Walk *is* the travel area**, and the Crossing *is* `meeting`.
- **20i's CDN normalises `Accept-Encoding`** and holds a response for its full
  max-age. Brotli never arrives. Do not measure again.
- **`/.api/` and `/.pages/` are refused by nginx's dot-directory rule.**
- **`Server/.api/config.php` is gitignored and points wherever it was last left.**
- **`swift build --package-path tools/wasm` fails on macOS** (deployment target).
  Use `sh tools/wasm/build.sh`.
- Adding or removing an app file needs `xcodegen generate`. Nothing this session
  added one.
- **The Mac's disk was at 98% (18 GiB of 926) during this session** and macOS
  was reporting memory failures because swap could not grow. Another session was
  sorting it. The big ones: `~/Library` 263G, `~/ComfyUI` 125G, `~/omlx-models`
  63G; reclaimable caches CoreSimulator 20G, `~/Library/Application Support/Claude`
  25G, DerivedData 13G, `~/.cache` 15G.

## Still open from before
- **A plant's own page** (capability URL), then **Sign in with Apple**.
- The **Milky Way** is absent from the sky though the Wild Fields are described
  as lit by it.
- The **Wild Fields** need release-to-a-place; the **curator's tool** is unbuilt.
- Two dotted threads from plants standing near each other run almost on top of
  one another below the plot.
- **`WalkStore` has outgrown its name** — it holds the connection for a garden
  with three areas now, and says so in its own doc comment. Renaming touches
  every caller and the reference checks, so it is a commit of its own.
- **The plumbing in `longwalk.js` is now imported by two other areas**
  (`quietgarden.js` and `crossing.js`) for GL, the camera, the quarter turns,
  the plant program, `COLOUR`, `SIDE`, `RIM_DEPTH`, `readOutline` and
  `readStructure`. The last handover said a third area is when that wants a
  module of its own. **It is now that.** Nothing is broken by leaving it; it is
  simply the wrong name on the door.
