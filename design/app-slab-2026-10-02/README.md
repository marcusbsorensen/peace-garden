# The plot as a solid slab, before and after (2 October 2026)

Marcus asked for the plot to look *less like it is melting away with the soil
below, and more like a solid slab of earth with organic contours that is
floating*. These are the app's own drawings of the Meadow on a 5.2 m plot,
before and after, from `WorldRenderTests.testDrawTheSlab` on an iPhone Air
simulator. Each one is put on the app's sky gradient for its hour, without
stars, sun, moon or plants.

| Files | What they show |
|---|---|
| `before-10-wide`, `after-10-wide` | The garden screen's framing at 10:00. The sun is behind the plot on the left, so both near sides are in shade. |
| `before-10-side`, `after-10-side` | Three times closer, on the near side to the right of the near corner, with the lower edge in view. |
| `before-17-…`, `after-17-…` | 17:00. The low sun is on the left-hand side. |
| `before-night-…`, `after-night-…` | Midnight, which is what *Always night* draws. |
| `after-turns-10`, `after-turns-night` | All four quarter-turns, at 10:00 and at midnight. |

## What changed

- **One mass, lit as planes.** Each stretch of side is lit by the way the rim
  faces there, so a side turned toward the sun or moon is bright all over and
  one turned away is dark all over. The old side was lit cell by cell, which
  read as noise.
- **A lower edge that is one line.** The side leans in by 20 cm on the way
  down and ends in a smooth edge that undulates over a pace and a half. The
  old floor was ragged a column at a time, which read as drips.
- **Strata as bands.** Humus under the turf, then earth, then rock, with
  boundaries that wander along the side and a few stones in the rock.
- **The near side still shows 0.95 m.** The side is now 1.05 m deep, because
  leaning it in lifts its lower edge on the screen by 0.10 m. At 0.95 m it
  looked a fifth thinner than before.

The reasons, and what was measured, are in `docs/ARRANGING.md` under *A keel
that tapers to nothing*.

## Drawing them again

```
TEST_RUNNER_PG_RENDER_SLAB=/some/folder TEST_RUNNER_PG_RENDER_TURNS=0,1,2,3 \
  xcodebuild test -project PeaceGarden.xcodeproj -scheme PeaceGarden \
  -destination 'platform=iOS Simulator,name=<your simulator>' \
  -only-testing:PeaceGardenTests/WorldRenderTests/testDrawTheSlab
```

`TEST_RUNNER_PG_RENDER_HOURS` (default `10,17,0`) and
`TEST_RUNNER_PG_RENDER_WORLD_LIST` (default `0`) choose the hours and worlds.
The test writes transparent PNGs and its timings, and also `slab-flat.png`, the
flat plot that is drawn when there is no world atlas.
