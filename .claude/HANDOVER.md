# Peace Garden: the sixth area, and a garden you can walk — handover 23 September 2026 (evening)

**The Seedbed is built, and the website can be walked from area to area.** Six
of ten areas are planted. The handover before this one — whose *Traps* all still
apply and are not repeated here — is at `git show ff3f8e5:.claude/HANDOVER.md`.

## State
- **Done, tested, pushed, deployed** (`02c58c7`, CI green on all three hosts).
  Live: `/api/garden` lists six areas open, `/api/seedbed/plot/0` answers the
  ambassador (*angustifolia*, drill 0), and `/seedbed` draws with no console
  errors. The live database took the `seedbed` table and the `walk_offers.kind`
  column.
- SeedCore 271 tests on macOS, **265 under WebAssembly, green**; app 129 (1
  skipped), run by hand. Every `tools/reference/check_*.php` passes (bar
  `check_restore`, which needs a live MariaDB and is not in CI), `check_sky.mjs`,
  `export.py --check` and `check_port.py`.
- `Organic.swift` was split into `Morphology/Structures/` (`12aab64`, pushed): a
  hedge, a bench, a roundel, a tree, and now a row label, each in its own file.

## The Seedbed, `beginnings`
Marcus's three answers: six drills of eight; a drill is claimed by the kind of
its first plant; places are taken in arrival order from the labelled end. The
long version is `docs/WEB-GARDENS.md` §*The Seedbed, built*.

- **A kind is the epithet.** Measured before building: over 500 crossings the
  binomial is unique 490 times and the genus nearly so; the epithet repeats (46
  of them, *rubra* 30 times). `PlantTraits.kind` is a third trait, sent by the
  phone, stored in a column, compared as a string. The service knows no botany.
- **No height and no colour decide anything here**, so the libm divergence
  cannot reach this area and its vector test needs no `placementCannotTurn`.
- **The fill is 65% at 500 arrivals**, the loosest of the six, and a new plot
  looks sparse: six kinds claim its six drills and the seventh opens another.
  The page names each drill's kind (in the serif) and draws how many of eight
  are sown, rather than implying a full bed.
- **The kind reaches the store by both paths** — `POST /api/walk/plant` and the
  offer path (`walk_offers.kind`, migrated with an `ALTER` the way `area` was).
  Validated as `[a-z]{0,64}`. `check_backup.php` reads the kind back out of a
  restored copy.
- **`Organic.rowLabel`**: a tongue on a stake leaning back 22°, because an
  upright plate at the isometric eye is a line. Nothing written on it. The page
  paints it a paler wood than `COLOUR.timber`, which went nearly black at that
  angle.

## The website, walked
`docs/WEBSITE.md` §*Moving through the garden*. A bar on every page (mark, hub
link to `/garden#<theme>`); the words below the plot as in the app; a glyph pad
(chevrons page between plots, rings turn the garden); a minimap of the 5×2 map
read from `garden.js`. The worded gates came and went in the same afternoon.
**No new strings**: the area names were already commissioned in 42 languages.

## Next: the Cold Frame, `waiting` — decided, not started

Marcus answered its three questions on 23 September, after a measurement that
changed the first one. **Build it next.**

**What was measured** (2000 crossings, `LongWalk.traits`): plants whose name puts
them in `waiting` are about 9% of arrivals and run **0.40–1.52 m at maturity**,
median 0.82 m (p10 0.54, p25 0.65, p75 1.02, p90 1.17). A low glazed frame holds
about 0.4 m. So "small plants only" as a height limit would have refused over
90% of the Cold Frame's own plants — a 0.5 m cut admits under a tenth of them.
Across all arrivals: 6% are under 0.5 m, 25% under 0.75 m.

**The three answers:**
1. **Every plant, drawn young.** Nobody is turned away. Each plant stands in its
   frame at an early growth stage, whatever it will grow into — the layout's own
   words, *the young stages of what grows elsewhere*. SeedCore already builds a
   plant at any stage: `PlantBuilder.mesh(growth: GrowthModel.State)`, which the
   app uses to grow plants over days. The web's grow export currently draws a
   mature plant; the Cold Frame needs a young stage passed through.
   **Choose the stage by measuring**, not by taste: the tallest seedling (from a
   1.5 m plant) has to stand under the glass, and the shortest has to still read
   as a plant at the isometric eye.
2. **Four frames of twelve, 48 a plot**: two rows of two frames, each about
   2 m × 1 m with a path between, two ranks of six inside each.
3. **Colour claims a frame; height orders the ranks inside it.** The Knot
   Garden's claim-not-reserve: the first plant in a frame gives it its colour
   family, only that family joins it, read off the plants rather than stored.
   Inside, the mature height decides front or back rank — the ones that will
   grow tallest stand at the back, so a frame is graded by what its seedlings
   will become. **The height used is the mature one**, not the drawn young one:
   it is a fact about the plant, stored with it, like every area's.

**Things to settle while building, not decisions for Marcus:**
- The rank cut. Measure it, or name whose it borrows (the Knot borrowed the
  Orchard's). A cut means the libm margin applies again: this area's vector test
  needs `VectorFile.placementCannotTurn`, unlike the Seedbed's.
- Simulate the fill before building, as the Seedbed was: seven colour families
  over four frames a plot.
- The structure: a low glazed frame with its lid propped by day — the second of
  the four structures still owed, in `Morphology/Structures/`. Glass is new: it
  has to read as glass at the isometric eye without hiding the seedlings, and
  its edges are organic like everything else.
- It is **`waiting`**, and the `waiting` genus heads and map cell (top-left of
  the 5×2 map, above the Quiet Garden) already exist. Eight places record the
  open list — see *Traps, new today*.

## Waiting for Marcus
- **The Seedbed's furrows** come out as fairly even bands at page size. They
  read as a raked bed rather than as ruled lines, but it is the one place the
  no-straight-lines rule deserves his eye.

## Traps, new today
- **A vector file must be one JSON document, not one object per line.**
  `VectorFile.same` returns early when the committed file and the render are
  byte-equal, which on the recording host is always, so a file of JSON lines
  passes on the Mac and fails on every other host the moment a height differs
  in its last bits. It did, under WebAssembly. `SeedbedVectorTests` now parses
  its file on purpose; the other areas' files are already arrays.
- **A new area is now eight places that record the open list**: the six from the
  last handover, plus the app's `ThemeMappingTests` and the `BUILT` map in
  `Server/assets/js/gates.js` (which replaced `walk.js`'s `built`).
- **A new area page must be built in the new layout**: bar, plot band, heading
  and two sentences below, then `.walk-ways` (the pad and the minimap). Copy
  `Server/.pages/seedbed`, not an older page from history.
- **`data-s-label`** (in `plain.js`) sets `aria-label` and `title` from the
  catalogue. Use it for any glyph-only control; never hardcode an English label.
- **The hub `/g` still hardcodes English `aria-label`s** on its own pad. Known,
  left alone.
- **`/api/count` 404s on `/g` under the dev router** — a stand-in asks for an
  endpoint nothing serves. Harmless, pre-existing.
- **`check_restore.php` replays only the Long Walk** after a restore, and has
  never covered the other five areas. Not in CI.

## Still open
- The four areas left: the Cold Frame, the Coppice, the Glasshouse, the Home
  Ground — each still needs its three questions answered. Three structures to
  come: a glazed frame, staging, bed edging.
- Everything under *Still open from before* in the previous handover.
