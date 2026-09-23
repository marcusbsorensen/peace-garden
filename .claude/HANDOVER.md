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
