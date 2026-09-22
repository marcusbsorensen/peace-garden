# Peace Garden: the fifth area — handover 22 September 2026

**The Knot Garden is open.** Five of ten areas are planted. The handover before
this one, whose traps mostly still apply, is at
`git show 41169df:.claude/HANDOVER.md`.

## State
- **Done, tested, pushed, deployed.** `2bc18d5` on `origin/main`. SeedCore 241
  tests, app 129 (1 skipped, run by hand in the simulator), `check_knot` 1770
  checks over 500 placements, `check_orchard` 1651, `check_crossing` 1959,
  `check_quiet_garden` 1850, `check_ambassador` 279, `check_areas` 47,
  `check_long_walk` 600, `check_backup` 28, `check_sky` 9729, `check_offers`,
  `check_limits`, `tools/site/export.py --check` and
  `tools/preview/check_port.py` all in step. **And in step on WebAssembly too**,
  which had not been true since 20 September — see *The libm divergence* below.
- Live: `/api/garden` says `pattern`, `travel`, `meeting`, `kinship` and `peace`
  are open, `/api/knot` answers one plot, and `https://peacegarden.app/knot`
  draws it — looked at in the live browser, with *Quina caerulea* standing alone
  in the north compartment. `knot.js`, `knotpage.js`, `longwalk.js` and `walk.js`
  were fetched back off the host and diffed against local: all four match.
- **The Knot Garden reads as one plant in an empty pattern until it fills**, the
  way the Crossing and the Orchard did on their first day. Left alone.

## The libm divergence, found and answered

**CI had been red since 20 September and nobody had recorded it.** Twelve runs,
through the Crossing, the Orchard and the Knot Garden. Fixed on 22 September in
`104e4a5`; what follows is what it actually was, because the shape of the answer
matters more than the patch.

**Reproduced on this Mac rather than by pushing.** The wasm SDK is already
installed, so the suite can be built and run for another host locally:

```sh
swift build --package-path Packages/SeedCore --build-tests \
  --swift-sdk swift-6.3.3-RELEASE_wasm --scratch-path .build-wasm
node tools/wasm/run-wasi.mjs .build-wasm/debug/SeedCorePackageTests.xctest
```

Ten minutes, and it is the only way to see what another host sees. It is in
`.gitignore` and noted in the workflow.

**What differs, measured rather than guessed.** Of five hundred arrivals to the
Knot Garden, **194 have a grown height that differs between macOS and
WebAssembly, by at most 3.6 × 10⁻⁷ m** — three of a `Float`'s last bits, a third
of a micron. **Nothing else differs at all**: not a plot, not a slot, not a
nudge, not a colour family, in any of the five areas. The rules were already
platform-independent; only the last bits of the numbers fed to them were not.

**It is not fixable and it never was.** A plant's mesh is built out of `sin`,
`cos`, `pow` and `exp`. Apple's libm and wasi-libc are each correct to within
about an ulp of the true value without being correct to the same bit as one
another. `tools/reference/check_sky.mjs` had already reached exactly this
conclusion for the JavaScript port and written it down — *demanding equality of
those is demanding that two C libraries agree, which is not a property of this
code and not one anybody can fix* — and allowed a named tolerance per quantity.
The Swift side was still comparing rendered JSON as **strings**.

**So the six suites now compare values, not bytes**, through
`Tests/SeedCoreTests/VectorFile.swift`: a grown height is allowed a hundredth of
a millimetre and everything else is allowed nothing. A nudge is seed bytes
divided and multiplied, so it is exact; a plot and a slot are integers, so they
are exact. The sky reuses `check_sky.mjs`'s own `ANGLE`, `PIXEL` and `POW`, with
the same names on purpose.

**And the tolerance is proved safe rather than asserted to be.** Each area's
vector test now also runs `VectorFile.placementCannotTurn(on:cuts:groupedBy:)`,
which says every recorded height clears that area's cuts by more than the
tolerance and every pair the rule compares is further apart than twice it —
which is the whole of what a rule asks about a height. The tightest margin in
the garden is **1.6 × 10⁻⁴ m**, sixteen times the tolerance and four hundred
times the disagreement. The day a plant lands near a cut, that test fails and
says which plant and which cut.

**Where the tolerance is now blind**, and it is worth knowing: a change to the
geometry that moved every height by less than ten microns would no longer be
caught by these files. A change that moves a plant still is, exactly, because a
placement is integers.

`LongWalk.middleFrom` and `LongWalk.backFrom` were added on the way: its cuts
were literals inside `tier(height:)` where the other four areas name theirs, and
the margin test needed to read the rule rather than copy it.

**Green on both hosts**: 246 tests on macOS, 240 under WebAssembly, no failures.

## The Knot Garden, built

`SeedCore/WebGardens/KnotGarden.swift`, `Server/.api/KnotGarden.php`,
`KnotStore.php`, `Server/assets/js/knot.js`, `knotpage.js`, `/knot`,
`/dev/knot`, `tools/reference/check_knot.php`. The long version is in
`docs/WEB-GARDENS.md` §*The Knot Garden, built*; what follows is only what a
next session needs.

Marcus chose the area and answered its three questions before any code existed:
thirty-two a plot in eight compartments, the eight as four mirror pairs sharing
a colour, and colour picking the pair while height picks the place.

- **The first rule that reads a plant's colour.** `PlantTraits` has carried
  `family` since the Long Walk and four areas graded by height alone. Both
  fields are used now, and the height grammar is kept rather than replaced.
- **A pair is claimed, never reserved.** The first plant to stand in a pair
  gives it its colour; only that colour may join it afterwards. Read off the
  plants rather than stored in a column, so a claim cannot go stale or be
  restored wrong.
- **The fill is the best of the five areas**, and it was the number that could
  have sent the design back: 17 plots at five hundred, 66 pairs claimed, 56
  exactly full, 92% of every place holding a plant. The rarest colour (pale, 19
  of 501) claimed three pairs in the whole garden, not one per plot — because a
  pair is claimed only when a plant needs one.
- **The cuts are the Orchard's, and are named as the Orchard's.** First time two
  areas share cuts. `KnotGarden.sideFrom = Orchard.flankFrom` in Swift and
  `KnotGarden::SIDE_FROM = Orchard::FLANK_FROM` in PHP, so there is one number
  rather than two that agree today.
- **The pairing arithmetic falls out of the declaration order**, which is
  therefore load-bearing: `Compartment` declares the four sides then the four
  corners, so `rawValue % 4` is the quarter turn, `rawValue ^ 2` is the mirror,
  and `rawValue % 2 + (atCorner ? 2 : 0)` is the pair. `KnotGardenTests`
  checks all three rather than trusting them.
- **`testAPairsTwoCompartmentsFillTogether` had to be replayed, not read off the
  finished plot.** *Which of the two was emptier* is a fact about the moment.
  The naive assertion — never differ by more than one — is false, and was this
  suite's first failure: a compartment whose remaining places are the wrong rank
  is passed over however empty it is. Exactly one pair of sixty-six ends uneven.
  This is the Orchard's 4 4 4 3 4 lesson arriving again in a new shape.

### What looking found, and it took three passes
- **The bands were walls.** 0.22 m through and 0.32 m tall drew nine boxes and
  no crossing read as a crossing. Thinning alone was not enough: **what reads as
  a wall is a run taller than it is broad.** Knot hedging is a ribbon laid on
  the ground, so it is 0.18 m through and 0.17 m tall, and at that the weave
  reads from every turn. Worth remembering for the Home Ground's bed edging and
  the Cold Frame's frames, which are both low things too.
- **The gravel was a tiled floor.** A square grid of flat-toned cells split on a
  common diagonal draws a checkerboard however fine it is, because the grid is
  the only thing in the picture that repeats exactly. Jittering the lattice by a
  third of a cell and turning each cell's diagonal with the same noise fixed it.
  **It was the regularity, not the size.**
- **Per-face tone, not per-corner.** Grass carries its tone on a grid's corners
  and interpolates; gravel cannot, and the same arithmetic drew wet sand. The
  roundel's finding at a twentieth of the size.

### What the pattern is, and what it is not
Two bands each way, crossing four times, inside a square edging: four
compartments at the sides, four at the corners, the weave closing round a middle
that holds no plant. **It reads as a woven grid rather than as a curving knot,
and that is a real limit rather than an oversight.**

- The alternative considered first was the classic octagram — a square and a
  diamond interlaced. Its compartments are the star's eight points, and a
  regular octagram's points are about 0.45 m² each at any scale that fits a
  5.2 m plot, which will not hold four plants at a spacing anybody would call a
  block. Four interlaced circles and a diagonal weave were both worked through
  and both give badly unequal compartments. The orthogonal weave is the one that
  gives **eight compartments of one size**, which is what a mirror pair needs in
  order to read as a mirror.
- **What would make it curve is `Organic`, not the rule.** A run of hedging that
  follows an arc is the missing piece; `Organic.hedge` draws straight runs only.
  That is a change to a shared structure with five areas' worth of callers, and
  it is a session of its own — but it is the single thing that would make this
  area look like its name rather than merely be laid out like it.

## The decisions waiting for Marcus

1. **Whether the Knot Garden's weave should curve**, which is the `Organic.hedge`
   arc above, and is the difference between a parterre and a knot.
2. **Whether the share screen should hold its question back while it asks
   `/api/garden`.** Carried from three handovers ago. Unchanged, and still not
   watched on a device.

## Traps
- **Run the app's tests by hand when an area opens.** CI cannot: they need Xcode
  on a Mac. Done this time.
  `xcodebuild test -project PeaceGarden.xcodeproj -scheme PeaceGarden -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
- **A new area is six places that record the open list, not two.** The last
  handover said two — `AreaVectorTests` and `ThemeMappingTests` — and that is
  true of the *assertions*. The others are `Areas.swift`, `Areas.php`,
  `backup.php`'s `KEPT`, `walk.js`'s `built` map and `.pages/g`'s own comment.
  `check_areas.php` catches the first two of those; nothing catches the rest.
- **A new page needs `tools/site/serve.py`'s `PAGES` as well as
  `Server/index.php`.** `python3 tools/site/export.py --check` is what catches
  it. Also `tools/wasm/dev-router.php` for the workbench, which nothing checks.
- **A new reference check needs a step in `.github/workflows/tests.yml`.**
  Nothing derives the list.
- **A vector file records what one host computes, and hosts differ in the last
  bits.** Compare through `VectorFile.same`, never as strings, and name the
  tolerance for the fields that need one. A new area's vector test also wants
  `VectorFile.placementCannotTurn(on:cuts:groupedBy:)`, or the tolerance is
  merely convenient. See *The libm divergence* above.
- **Run the suite for another host before believing CI is green.** `swift test`
  on the Mac says nothing about Linux or WebAssembly, and it said nothing for
  two days.
- **`check_backup.php` was not asserting the Orchard's table.** Fixed here,
  along with the Knot Garden's. It had been carrying the Orchard on trust since
  21 September, which is exactly the silent data loss the check exists for.
- **`/plant.wasm` caching.** Fixed for the live pages by the `data-module` stamp
  in `index.php`. **Probe a rebuilt module under node with `node:wasi`** rather
  than in the browser pane — a second, and unambiguous.
- **The browser pane throttles `requestAnimationFrame` to 1 Hz**, and its
  `zoom` action does not crop. To look closely at a plot, set the viewport
  square (`resize_window` 900×900) — the isometric fit makes the plot largest at
  1:1 — rather than trying to magnify a region.
- **The language banks nest under a `strings` key.** `walk*`, `quiet*`, `cross*`,
  `orchard*` and now `knot*` are **not** in the per-language catalogues — they
  live in `strings.js`, English, until commissioned. Only the ten area names are
  translated, which is why a fifth area cost two strings again. Five areas, ten
  strings.
- **The Knot Garden *is* the `pattern` area**, the Long Walk `travel`, the
  Crossing `meeting`, the Orchard `kinship`, the Quiet Garden `peace`. Not
  `light`, which is the Glasshouse.
- **`wobble` is in -1...1 but value noise only touches its ends.** A typical
  reading is about a third of the range.
- **`PeaceGarden.xcodeproj` is at the repository root**, not under `App/`.
- **The two python checks are `tools/site/export.py` and
  `tools/preview/check_port.py`**, not under `tools/reference/`.
- **20i's CDN normalises `Accept-Encoding`.** Do not measure again.
- **`/.api/` and `/.pages/` are refused by nginx's dot-directory rule.**
- **`Server/.api/config.php` is gitignored and points wherever it was last left.**
- **`swift build --package-path tools/wasm` fails on macOS** (deployment target).
  Use `sh tools/wasm/build.sh`.
- **The host's SSH IP allowlist** can stop a deploy: rsync answers
  `Connection reset`, not a permission denial. My20i -> peacegarden.app ->
  Security -> SSH Access, and it needs this Mac's public IP that day. It was
  fine today.
- Adding or removing an app file needs `xcodegen generate`. Nothing this session
  added one.

## Still open from before
- **A plant's own page** (capability URL), then **Sign in with Apple**.
- The **Milky Way** is absent from the sky though the Wild Fields are described
  as lit by it.
- The **Wild Fields** need release-to-a-place; the **curator's tool** is unbuilt.
- Two dotted threads from plants standing near each other run almost on top of
  one another below the plot.
- **`WalkStore` has outgrown its name** — it now holds the connection for five
  areas and says so in its own doc comment. Renaming touches every caller and
  the reference checks, so it is a commit of its own.
- **The plumbing in `longwalk.js` is imported by four other areas**
  (`quietgarden.js`, `crossing.js`, `orchard.js`, `knot.js`) for GL, the camera,
  the quarter turns, the plant program, `COLOUR`, `SIDE`, `RIM_DEPTH`, `hash`,
  `readOutline` and `readStructure`. `COLOUR` has now grown `leaf`, `bark`,
  `gravel` and `box` for areas that are not the Long Walk, and `hash` had to be
  exported for a fifth. **This is the oldest unpaid debt in the web garden** and
  it grew again today. Nothing is broken by leaving it — it is the wrong name on
  the door — and the file's own comment at `makePlotStage` says so.
- **`Organic` is 709 lines and holds five structures** (hedge, bench, roundel,
  tree, plus the ground's outline and verges). The Knot Garden needed no sixth,
  so the `Structures/` split is still only worth considering rather than due —
  but the arc-following hedge above would be the sixth thing, and that is when
  to do it.
