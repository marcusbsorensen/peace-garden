# Peace Garden: the fourth area — handover 21 September 2026

**The Orchard is open.** Four of ten areas are planted. Earlier the same day:
the bench got a back and the Crossing opened, both recorded below. The handover
before that, whose traps still apply, is at `git show 9bed47c:.claude/HANDOVER.md`.

## State
- **Done, tested, pushed, deployed.** `fd22549` on `origin/main`. SeedCore 223,
  app 129 (1 skipped, run by hand in the simulator), `check_orchard` 1651 checks
  over 500 placements, `check_crossing` 1959, `check_quiet_garden` 1850,
  `check_ambassador` 279, `check_areas` 47, `check_long_walk` 600,
  `check_backup` 25, `check_sky` 9729, `check_offers`, `check_limits`,
  `tools/site/export.py --check` and `tools/preview/check_port.py` all in step.
- Live: `/api/garden` says `travel`, `meeting`, `kinship` and `peace` are open,
  `/api/orchard` answers one plot, and `https://peacegarden.app/orchard` draws
  it — looked at in the live browser, quincunx and mown discs and all, with
  *Cyninora contorta* under the middle tree. `orchard.js` and `longwalk.js` were
  fetched back off the host and diffed against local: both match.
- **The Orchard reads as five trees and no planting until it fills.** A
  middle-guild place stands 0.75 m from its trunk, so at two of the four turns
  the middle trunk is between the ambassador and the viewer, and at the default
  turn the page's prose sits over it. The Crossing looked much the same on its
  first day. **Left alone deliberately**; the cheap fix would be opening a plot
  at an outer guild, which costs the thing that made the middle guild rankless.
- **The host's SSH IP allowlist stopped a deploy earlier today.** rsync answers
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

## The Orchard, built

`SeedCore/WebGardens/Orchard.swift`, `Server/.api/Orchard.php`,
`OrchardStore.php`, `Server/assets/js/orchard.js`, `orchardpage.js`, `/orchard`,
`/dev/orchard`, `tools/reference/check_orchard.php`, `Organic.tree`,
`pg_tree`, `pg_orchard_*`. The long version is in `docs/WEB-GARDENS.md`
§*The Orchard, built*; what follows is only what a next session needs.

Marcus chose the area and answered its three questions before any code existed:
the garden plants the trees, twenty a plot, and a guild is finished before the
next is begun.

- **The rule is the Crossing's two loops turned inside out** — guild outside,
  rank inside. That nesting *is* the area. A port with them swapped agrees about
  the first four plants of every plot, about every plot's total and about most
  placements after that, which is why the check replays all five hundred.
- **The middle guild has no ranks**, because its four places are all the same
  distance from the plot's centre and the middle tree is the one you walk all
  the way round. This is not an accommodation: it is the Crossing's *three
  sharing an arc* applied to a whole guild, and it is what lets a plot open with
  any plant at all — including the 1.33 m kinship ambassador, the tallest of
  the ten.
- **Cuts at 0.75 and 1.30**, the 25th and 75th centiles of 300 crossings for a
  guild of 1:2:1.
- **Three plants in four get their own rank, against the Crossing's 96.6%**, and
  that is the rule's price rather than a fault — `inOrder` still guarantees the
  picture for every plant. Recorded in `OrchardTests` so a change that wrecks it
  shows up.
- **At 500: 26 plots, 25 exactly full.** One older plot sits at 19 because its
  last free place wants a plant of 0.77 m or less; it is not abandoned, and the
  test says so in the way it checks.
- **The counts do not fall from guild to guild, and asserting they did was this
  session's one real bug.** 4 4 4 3 4 is correct: a guild's last place holds the
  tightest constraint in the plot and can wait a long time for a plant tall
  enough for its crown. Both the PHP check and the Swift test asserted
  monotonicity, both passed on the `orchard-arrival-` five hundred, and
  `/dev/orchard` — which uses `orchard-parent-` seeds — showed 4 4 4 3 4 on
  screen. **Two samples caught what one could not**, and the workbench earned
  its keep as something other than a picture. The checks now assert the two
  things that really are guaranteed, and are stronger for it.

### The tree took four passes, which is the roundel's number
`Organic.tree` is the second structure that is neither hedge nor bench, and
every one of its faults was one the roundel had already taught:
- **Too big and too low** — it covered the planting, and an orchard where you
  cannot see the guild is five trees.
- **A green balloon.** `wobble` is in -1...1 but value noise only *touches* its
  ends; a typical reading is a third of the range. A coefficient chosen from the
  range gives a third of the lumpiness it looks like it asks for. **This is the
  trap to remember: 0.20 drew a ball, 0.55 drew a canopy.**
- **Faceted.** Flat shading was tried on the roundel's precedent and made a
  polyhedron. The roundel is flat because paving *is* faces; a canopy is grown
  and belongs with the hedges, which are smooth.
- **A star at every treetop, twice.** The canopy's poles are one point held by
  25 vertices and `computeNormals` gave each only its own faces; and a per-face
  colour hash gave tiny touching triangles wildly different greens. Both are
  *the mesh showing through its own shading*, which is the roundel's third pass
  again.

## The decisions waiting for Marcus

1. **Whether the share screen should hold its question back while it asks
   `/api/garden`.** Carried from two handovers ago. Unchanged, and still not
   watched on a device.

## The fifth area is the Knot Garden, and it is decided

Marcus chose it on 21 September and answered the three questions it raises.
**No code is written yet** — this section is the brief, so the session that
builds it does not have to re-decide anything.

The Knot Garden is `pattern`. Genus heads `Cal` (the shapely) and `Quin` (the
five); table `knot_garden`; heading `areaPattern`, "The Knot Garden", already in
`strings.js` and already translated in all 42 catalogues, so — as with the last
four — it costs two English strings, `knotAbout` and `knotAway`.

**It is the first area whose rule reads a plant's colour.** `PlantTraits` has
carried `family` since the Long Walk and no rule has ever looked at it; four
areas have graded by height alone. Seven families: six arcs of the hue circle
plus pale, from `LongWalk.family(hue:saturation:)`.

1. **Thirty-two a plot: eight compartments of four.** Between the walk's 48 and
   the crossing's 24. Four plants is enough to read as a block of one colour,
   which three is not.
2. **The eight are four mirror pairs, and a pair shares a colour family.** That
   is what *a slot has a mirror* turns out to mean — the knot is symmetric in
   colour, which is what a knot garden looks like from above. So a plot carries
   four of the seven families, eight places each.

   **Nothing is ever reserved.** The literal reading — taking a place holds the
   opposite place for a matching plant — was rejected, and for a reason already
   written into four areas' comments: nothing in this garden reserves a slot,
   not even for an ambassador. The Orchard also showed that a constrained place
   can wait hundreds of arrivals, and a *reserved* one would wait on a plant
   nobody has grown.
3. **Colour picks the compartment pair, height picks the place within it.** Both
   fields of `PlantTraits` used for the first time, and the height grammar every
   other area shares is kept rather than thrown away.

### What the build has to settle, and should name in the commit
- **The pattern.** Eight compartments in the 5.2 m square: four at the corners
  and four at the sides, with the knot's crossing at the centre. **The centre
  holds no plant**, as the Crossing's paving does and for the same reason — an
  area's opening place has to be one its own ambassador can stand in, and a
  centrepiece is not it. Mirror pairs are then opposite corners (two pairs) and
  opposite sides (two pairs).
- **The interlace is the hard part and will take the passes.** A knot's bands
  cross *over and under* each other. `Organic.hedge` exists and is the right
  tool, but an over-crossing means lifting one run at the crossing, and a knot
  drawn without the over-and-under is four hedges in a pattern rather than a
  knot. Budget the roundel's four passes and the tree's four again.
- **Gravel, not grass** — the first ground in the garden that is neither lawn
  nor meadow. Probably the roundel's per-face tone at a much finer grain; the
  trap is that gravel drawn too coarse is shingle and too fine is sand.
- **What an arrival does when no pair in any plot holds its family and no pair
  is unclaimed.** The analogue of `ranks(beside:)`. Start with: try every plot
  oldest-first for its own family, then every plot for an unclaimed pair, then
  open a new plot. **Check the fill at 500** — with seven families and four
  pairs a plot, early plots will reject a lot, and whether that settles down is
  the one number that could send the design back.
- **The cuts will be the Orchard's 0.75 and 1.30**, because a compartment of
  four graded outward is the same 1:2:1 the Orchard's guild is. **Say so** — this
  would be the first area to share cuts with another, and the honest thing is to
  name the reuse rather than re-measure and present the same numbers as
  independent.
- **The ambassador is *Quina caerulea*, 1.0064 m, family 4.** An empty plot has
  no claimed pairs, so it claims one for family 4 and stands in it. No
  awkwardness, unlike the Orchard's — worth confirming rather than assuming.

### The shape of the work, from the Orchard's pattern
`SeedCore/WebGardens/KnotGarden.swift`, `Server/.api/KnotGarden.php`,
`KnotStore.php`, `Server/assets/js/knot.js`, `knotpage.js`,
`Server/.pages/knot`, `/knot` in `index.php` and `router.php`, `/dev/knot`,
`tools/reference/check_knot.php`, the hedging in `Organic`, a `Knot.swift` in
`tools/wasm/Sources/PlantWasm/`, `Areas.swift`/`Areas.php` to open `pattern`,
`Ambassadors.php`, `WalkStore.php`, `backup.php`'s KEPT list,
`check_backup.php`, `check_ambassador.php`, `walk.js`'s `built` map,
**`tools/site/serve.py`'s `PAGES`**, and `docs/WEB-GARDENS.md`. **Re-record
`area_vectors.json`**, and expect `ThemeMappingTests` and `AreaVectorTests` to
fail by design — and nothing else, per the trap below.

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
- **The Long Walk *is* the travel area**, the Crossing *is* `meeting`, and the
  Orchard *is* `kinship` — not `renewal`, which is the Coppice, and not
  `ground`, which is the Home Ground.
- **`wobble` is in -1...1 but value noise only touches its ends.** A typical
  reading is about a third of the range, so a coefficient picked from the range
  gives a third of the effect it looks like it asks for. This is what drew the
  first canopy as a ball, and it applies to every use of `wobble` and `noise`
  in `Organic`.
- **`PeaceGarden.xcodeproj` is at the repository root**, not under `App/`.
- **Opening an area breaks the *previous* area's test suite.**
  `CrossingTests.testTheCrossingIsTheMeetingArea` asserted the whole list of
  open areas, so opening the Orchard failed a test that tells nobody anything
  about the Crossing. Fixed by taking the list out of it. The list is now
  written down in exactly two places on purpose — `AreaVectorTests` for
  SeedCore and `ThemeMappingTests` for the app — and **an area that opens should
  fail those two and nothing else**. If a third place turns up, take it out
  rather than updating it.
- **A new page needs adding to `tools/site/serve.py`'s `PAGES` as well as to
  `Server/index.php`.** `python3 tools/site/export.py --check` is what catches
  it. **`/cross` was missing from it** — the Crossing shipped that way and the
  last handover recorded this check as in step when it was not. Fixed here for
  both pages. It is dev-only tooling, so nothing live was broken; what was
  broken is that `/cross` did not work in the static site preview.
- The two python checks are **`tools/site/export.py`** and
  **`tools/preview/check_port.py`**, not under `tools/reference/`.
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
- **The plumbing in `longwalk.js` is now imported by three other areas**
  (`quietgarden.js`, `crossing.js`, `orchard.js`) for GL, the camera, the
  quarter turns, the plant program, `COLOUR`, `SIDE`, `RIM_DEPTH`, `readOutline`
  and `readStructure`. Two handovers ago said a third area is when that wants a
  module of its own; it is now four, and `COLOUR` has grown `leaf` and `bark`
  for an area that is not the Long Walk. **This is the oldest unpaid debt in the
  web garden.** Nothing is broken by leaving it — it is simply the wrong name on
  the door, and the file's own comment at `makePlotStage` says so.
- **`Organic` is now 660 lines and holds five structures** (hedge, bench,
  roundel, tree, plus the ground's outline and verges). It has not become hard
  to read yet, but the tree is the first one big enough that a `Structures/`
  split would be worth considering at the sixth.
