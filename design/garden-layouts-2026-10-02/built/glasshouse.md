# The Glasshouse, built: the colour wheel

Option A of `RESEARCH.md`, as Marcus approved it on 2 October 2026. The plot
does not vary: a colour wheel has one way round (`Glasshouse.variants` is
`.fixed`, and is now read, so a plot's spot is found the way every other
area's is).

## What was built

**The house is round.** A wall of glass 2.2 m in radius, laid by hand: its
radius wanders outward by up to 4 cm, never inward, so nothing stands under a
roof lower than `Glasshouse.roof`. Fourteen bays and a doorway, a post at each,
and a rib curving up a parabolic dome from every post to a ring at the crown,
with a second ring partway up and a turned cap over the crown. Eaves 2.2 m,
crown 3.5 m. Every bar is the bench's board section swept along a curve, and
each post leans a few millimetres off true.

- **The door is in the green gap**, at `z+`, between the staging's two ends.
  It is slid open round the outside of the wall toward `x+`, so from the
  page's first view it stands across the wall in front of the staging's yellow
  end. A threshold stone lies across the doorway, half in and half out.
- **The staging is a ring** of four curved slats on twelve frames of legs,
  0.40 m deep, its middle 1.8 m out. 24 pots stand on it 0.43 m apart, two to
  each of the twelve hue bands. Band 0 (blue-green) is just past the door
  going round toward `x−`; band 11 (yellow) is just before it. From the
  page's first view the warm half is nearest and the cool half behind the bed.
- **The border is a round bed of eight in the middle**, under the crown,
  filled from its middle and then farthest-first. The ambassador, *Elora
  elata*, now stands in the middle of it.
- **The floor** is the same quarry tiles. Outside the wall they keep the
  jittered lattice. Inside they are laid in five rings from the bed to the
  wall, each following the bed's wander on its inside and the wall's on its
  outside.
- **The trough** stays under the staging, bent to the ring under its `x+`
  side. It is 0.24 m across, to stand between the legs. `water.js`'s troughs
  are fanned from a middle and cannot bend, so `glasshouse.js` walks this one
  along the staging's line. `water.js` is unchanged.

**The rule is unchanged where it was settled.** The height cut stays at 1.16 m.
The band edges and their hue rule are as pinned. A pot still tries its own
band in every plot, then one band off on the side its hue leans to, never
across the cut, then opens a new plot. Thirty-two places a plot, 24 + 8.

**One placement changed, as the first move asks**: the order free places are
offered in.
- A pale plant, or one whose hue was never sent, takes the first free pot in
  the table's order: the pot opposite the door, then farthest-first. It took
  the first free pot from the door, so every pale pot stood in band 0 or 1
  first.
- The bed fills from its middle out. Its index is still "the next place", so
  only where that place is moved.

**Places are a table made offline**:
- the spec is `tools/layouts/tables/glasshouse_wheel.py`;
- it generates `PlaceTable.glasshouseWheel`, `GlasshouseWheelTable.php` and
  `tables/glasshouse_wheel.js`;
- the table also carries the three outlines the drawing follows: the wall
  (`house`, indexed by turn), the staging's line (`staging`) and the bed
  (`bed`).

The table is named `glasshouse_wheel`, not `glasshouse`, because a generated
`Glasshouse.swift` cannot sit in the same module as the rule's file.

| Piece | Where |
|---|---|
| Rule | `SeedCore/WebGardens/Glasshouse.swift` (spots from the table, `paleOrder`, `roof(atRadius:)`) |
| House | `SeedCore/Morphology/Structures/RoundHouse.swift` (new; `SpanHouse.swift` removed) |
| Staging | `Structures/Staging.swift`: `ringStaging` replaces `staging`; the pot is unchanged |
| Port | `Server/.api/Glasshouse.php` (`spot` from the table, `standing`, `paleOrder`), `GlasshouseStore.php` |
| Checks | `GlasshouseTests`, `RoundHouseTests` (new; `SpanHouseTests` removed), `GlasshouseVectorTests` |
| Vectors | `tools/reference/glasshouse_vectors.json` and `check_glasshouse.php`, re-recorded: each row carries `variant` and `spot`, compared exactly |
| Module | `tools/wasm/Sources/PlantWasm/Glasshouse.swift`: the plan JSON now gives radius, eaves, crown, door, the ring and the bed |
| Drawing | `Server/assets/js/glasshouse.js`; comments in `glasshousepage.js` and the workbench |

**The app does not draw the Glasshouse.** Its structures live in SeedCore's
`Morphology/Structures/`, but only the plant module (wasm) calls them. The app
uses `Organic` only for the Long Walk's hedges, verges and the plot outline.
No app code changed, and none of the removed API is referenced from `App/`,
so no simulator run was needed.

**Night and day.** The web has one sky, the real star sky. The light colour
scheme draws the same black sky behind the plot (checked headless in both
schemes), and no lamp exists today. Against it the painted bars read as pale
lines, and the glass shows as faint glints off the dome's laps and ripples, as
the span house's did.

## The fill, on SeedCore's own plants

`swift run -c release --package-path tools/layouts/harness layouts-harness --area glasshouse --against tools/layouts/baseline.json`.
Moved figures are shown as new (old).

| Arrivals | Plots | Places held | Held | Settled plots | Held in settled | Empty in settled |
|---|---|---|---|---|---|---|
| 10 | 1 | 11 of 32 | 34.4% | 0 | — | — |
| 100 | 4 | 101 of 128 | 78.9% | 2 | 98.4% (96.9%) | 1 (2) |
| 1000 | 33 | 1001 of 1056 | 94.8% | 31 | 98.7% | 13 |

**At 1,000 it is the baseline exactly**: 33 plots, 94.8% held, 98.7% in
settled plots. That follows from the rule, since only where a pale pot goes
changed. At 100 the settled plots are a little fuller. On the tests' own 500:
17 plots, 92% held, 331 of 361 hued pots in their own band, and the nearest
plant 0.63 m under the dome.

## What a replant needs

**Nothing it must have.**
- Capacities are unchanged.
- Every slot an existing planting holds (bed, band or bed place, row) is a
  slot of the new house.
- An old plot drawn today stands every plant in the round house at its slot's
  new spot.
- Hued pots and the bed are placed by the same rule as before.

**What a replant would change** is the pale and unsent pots only, and what
they push:
- Re-recording the vectors moved 161 of 500 placements, and 72 changed plot.
  Each is a pale pot taking a different pot, or a hued pot taking the row or
  plot the pale one left.
- Without a replant, the live garden's pale pots stay where the old rule put
  them, near the door in bands 0 and 1. Those places are still valid in the
  round house.
- `slot_row` changes meaning, harmlessly. It was 0 by the glass and 1 by the
  path; it is now the band's first and second pot in the table's order. Both
  are 0 or 1.

## Shared files touched

All minimal, and only this area's lines:
- **`Server/assets/js/gates.js`**: the Glasshouse's glyph, from a pitched roof
  end-on to a round house with a dome, ribs and a door.
- **`Server/assets/js/strings.js`**: `glasshouseAbout`, the English, which no
  catalogue has been commissioned for (0 of 42 carry it).
- **`tools/reference/check_offers.php`**: the two Glasshouse expectations. An
  unhued offer takes the first pot the table offers; the bed's next place
  follows the ambassador.
- **`tools/reference/check_curate.php`**: it copies `Server/.api/*.php` into a
  scratch site and now copies `.api/tables/*.php` too. **Every area whose port
  reads a table needs this**, or the copy cannot load the router. The other
  area agents may make the same change.

## Renders

In `built/`, each from `/dev/glasshouse` on this worktree's server, cropped
to the plot. *10* is `?arrivals=10&plot=0`; *full* is `?arrivals=500&plot=3`.

| Before | After |
|---|---|
| `glasshouse-before-10.jpg` | `glasshouse-after-10.jpg` |
| `glasshouse-before-full.jpg` | `glasshouse-after-full.jpg` |
| `glasshouse-before-three.jpg` (plots 3–5) | `glasshouse-after-three.jpg` |

Also:
- `glasshouse-after-close.jpg`: `span=0.6`, the staging and pots close to;
- `glasshouse-after-full-turned.jpg`: a half turn, the cool half of the wheel
  nearest;
- `glasshouse-after-page.jpg`: the real `/glasshouse` page, from 120 of the
  vector file's arrivals sown into the local service, with the neighbouring
  slabs.

## Left open

1. **Whether the wheel reads.** Colour shows only through flowers, which are
   small beside the leaves. In the renders the hues sort round the ring (warm
   nearest from the first view, cool nearest after a half turn), but a reader
   has to look for it. The research's sketch drew a painted hue band
   along the staging's edge as a key. That is not built, because colour
   belongs to the plants; it is the obvious next step if the wheel does not
   read.
2. **The dome's height** was set for the eye, not the plants. The plants need
   about 2.4 m over the staging. A dome that rises less than about 1.3 m over
   its eaves hides inside the ellipse its own eaves make, and reads as a drum
   with a lid. Crown 3.5 m, eaves 2.2 m.
3. **The door's side.** It faces `z+`, as the research drew it, and slides
   toward `x+`. The other way puts it edge on at the house's side from the
   first view.
4. **The glyph.** It is a new drawing at 20 px, and wants a look beside the
   other nine.
