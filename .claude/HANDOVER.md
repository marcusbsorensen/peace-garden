# Peace Garden: the fifth area, curved — handover 23 September 2026

**The Knot Garden is open and its bands curve.** Five of ten areas are planted.
The handover before this one, whose traps mostly still apply, is at
`git show 41169df:.claude/HANDOVER.md`.

## State
- **Done, tested, pushed, deployed.** *The knot's bands curve, because a weave
  drawn with a ruler is a grid* on `origin/main`. SeedCore 251 tests on macOS
  and 245 on WebAssembly, app 129 (1 skipped, run by hand in the simulator),
  `check_knot` 1770
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
- Looked at live after the curve went up, and looked at locally with forty
  arrivals sent by `tools/wasm/send-arrivals.mjs` so the compartments had blocks
  in them — which is the only way to see whether the bands crowd the planting.

## The libm divergence, found and answered

**CI had been red since 20 September and nobody had recorded it.** Twelve runs,
through the Crossing, the Orchard and the Knot Garden. Fixed on 22 September in
*A vector file is compared as numbers, because two C libraries do not agree* —
named rather than numbered, because a commit cannot carry its own hash. What
follows is what it actually was, because the shape of the answer matters more
than the patch.

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
that holds no plant. **It read as a woven grid rather than as a curving knot
for one day, which the bands' bow answered.**

- The alternative considered first was the classic octagram — a square and a
  diamond interlaced. Its compartments are the star's eight points, and a
  regular octagram's points are about 0.45 m² each at any scale that fits a
  5.2 m plot, which will not hold four plants at a spacing anybody would call a
  block. Four interlaced circles and a diagonal weave were both worked through
  and both give badly unequal compartments. The orthogonal weave is the one that
  gives **eight compartments of one size**, which is what a mirror pair needs in
  order to read as a mirror.
- **What made it curve was `Organic`, not the rule.** Done on 23 September —
  see *The curve* below. The sentence that stood here was right about where the
  change belonged and wrong about the shape: what a weave needs is not an arc
  but a line that is flat where it meets a crossing.

## The curve, 23 September

Marcus answered the first decision: curve it. `197e6fd`.

- **`Organic.hedge` gained `bow`** — how far the middle of a run stands off the
  straight line between its two ends. Sixth thing the file knows how to do, and
  it turned out to be a parameter rather than a structure.
- **The line is flat at both ends**, `(1 - f²)²` rather than a circle's arc, and
  that is the whole design. The first shape tried was a plain parabola, which
  arrives at its ends still turning. Drawn, it showed everything a weave has at
  a crossing: the inner stretch and the arm met at a visible corner, the
  under-run's square cut end came out oblique and poked through the band
  crossing over it, and the swelling sat on the axis while the band had curved
  away from it. **Flat ends make a crossing the one place on a run where nothing
  is happening**, which is exactly where a weave puts its joints and its cuts,
  and all three faults went at once.
- **A run that does not bow is the run it always was, to the bit.** The call is
  shared with the Long Walk, the Quiet Garden and the app.
  `testAHedgeThatDoesNotBowIsTheHedgeItWas` compares the positions and the
  normals with no tolerance at all, which is right here because both sides are
  the same arithmetic on the same host — unlike a vector file, which is two
  hosts and wants `VectorFile.same`.
- **`KnotGarden.weave` is where the four runs are laid out now**, and `knot.js`
  draws what it is given. The layout was in the page; it moved for the reason
  `bandHalfThickness` was in the rule already — a compartment's edges are where
  the bands' faces are, so the shape of a band is something the rule has to be
  able to answer, and two copies of it can drift without either looking wrong.
- **The numbers came out of measuring, not out of taste.** `knotBow` 0.30 is
  free: it bows into the middle, nothing is planted there, and the nearest plant
  to any band is exactly as near as it was when every band was straight.
  `armBow` 0.05 is paid for: the nearest place to an arm stood 0.18 m from the
  band's face, `Planting.nudge` already spends 0.09 of that, and 0.05 of bow
  leaves 0.048 m. **Half the margin the straight weave had**, spent knowingly.
  `KnotGarden.clearance(x:z:)` is the measure and
  `testNoPlaceStandsInABandHoweverItIsNudged` is the guard.
- **The bug worth knowing about.** Each run was first cut between `under` and
  `over` in the order those two are named, which is right for the two runs at
  `+bandFrom` and wrong for the two at `-bandFrom`: there the crossings lie the
  other way round, so one stretch spanned the whole plot and one had its ends
  swapped and came out with a negative length. **It drew something that looked
  nearly right** — plausible enough that two rounds of looking at screenshots
  went past it, and it was the plan JSON printed as a table that showed it.
  `testEachRunIsThreeStretchesEndToEndWithOneGap` is the assertion now.
- **What is still true from the day before**: the pattern is an orthogonal
  weave, not an octagram, and the reasons above still hold. What has changed is
  only that it no longer reads as a grid.

## The decisions waiting for Marcus

**None.** Both are answered.

- **Whether the Knot Garden's weave should curve** — yes, and it does. See *The
  curve* above.
- **Whether the share screen should hold its question back while it asks
  `/api/garden`** — it does not need to. Carried from four handovers ago and
  closed on 23 September by a decision about the garden rather than about the
  code: **all ten areas will be open before the app is announced.**
  `ShowInGardenView` draws what the build believes and corrects itself when the
  service answers, which can only be a correction when an area opened after that
  build shipped. If every area is open before the first public build is cut, the
  two lists agree for every build that reaches anybody, the flicker is
  unreachable, and so is the whole *this plant's area comes later* form of the
  screen. Nothing to change, and nothing left to watch on a device.
  - **What the request is still for.** `GET /api/garden` was built so a phone
    need not learn about an opening from a version of itself, and that job ends
    at announcement. It is kept because it is one request per app launch,
    carries nothing about the phone, and is the only way the app can be told an
    area has *gone* — a withdrawn area, or a plot service that cannot take a
    plant, stops being offered instead of being promised. Taking it out would
    buy one fewer request and lose that.

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
- **The wasm test build needs the swift.org toolchain named**, not the `swift`
  on the PATH, which is Xcode's and has no WebAssembly backend — it dies with
  *No available targets are compatible with triple "wasm32-unknown-wasip1"* and
  a compiler crash dump, which reads like a bug in the code and is not.
  `tools/wasm/build.sh` finds the right one for itself; a test build has to be
  told:
  `~/Library/Developer/Toolchains/swift-6.3.3-RELEASE.xctoolchain/usr/bin/swift build --package-path Packages/SeedCore --build-tests --swift-sdk swift-6.3.3-RELEASE_wasm --scratch-path .build-wasm`
- **To look closely at a plot in the browser pane**, scale the stage canvas with
  CSS — `document.getElementById('stage').style.transform = 'scale(2.4)'` with
  `transformOrigin` on the plot — and hide the page's text. The canvas backs
  900 CSS px with 1800, so 2× is pixel-for-pixel. `zoom` does not crop, and
  `drawImage` off that canvas comes back blank, because the WebGL context does
  not preserve its drawing buffer.
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
- **`Organic` is 727 lines and holds five structures** (hedge, bench, roundel,
  tree, plus the ground's outline and verges). The curve turned out to be a
  parameter on the hedge rather than a sixth structure, so the `Structures/`
  split did not become due after all — but the file is longer again and nothing
  else is coming that would make it shorter. **It is a mechanical move with no
  behaviour in it**, which makes it a good commit to do on its own and a bad one
  to fold into anything else. `private` members would have to become `internal`,
  since Swift's `private` is file-scoped.
