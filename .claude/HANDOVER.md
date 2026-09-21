# Peace Garden: the fourth area — handover 21 September 2026

**The Orchard is open.** Four of ten areas are planted. Earlier the same day:
the bench got a back and the Crossing opened, both recorded below. The handover
before that, whose traps still apply, is at `git show 9bed47c:.claude/HANDOVER.md`.

## State
- **Built, tested, committed. NOT deployed** — Marcus asked for the Orchard to
  be built and has not asked for a deploy. `sh tools/deploy.sh` is the command,
  and the SSH IP allowlist below will very likely need his attention first.
- SeedCore tests, app tests (by hand, in the simulator), and every reference
  check pass. `check_orchard` agrees with the Swift on all 500 arrivals across
  26 plots at 1629 checks, and it agreed **first time**.
- Live still shows three areas. `/api/garden` will say `kinship` is open as
  soon as the deploy goes.
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

1. **Whether to deploy the Orchard.** It is built and tested and not live. The
   SSH IP allowlist under *State* is the thing that will stop it.
2. **The fifth area.** The Knot Garden is the first where a slot has a *mirror*,
   which is the one structural first left that none of the four has met; the
   Seedbed is the plainest; the Glasshouse is the first with a roof, and so the
   first where the sky is occluded. Six left.
3. **Whether the share screen should hold its question back while it asks
   `/api/garden`.** Carried from two handovers ago. Unchanged, and still not
   watched on a device.

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
