# Shadows in the app's garden, 2 October 2026

Every plant and every figure on the plot (hare, fox, snail, moth, lantern, paper
lamp) now throws a shadow on the ground. The shadow follows the sun or the moon
at the hour. Before this, a plant's shadow was its own picture, blackened and
sheared. Branch `worktree-agent-a6817e95101b680b7`, not merged.

## The pictures

The same plot, before and after, at 08:00, noon, 17:00 and midnight:

| File | What it shows |
|------|---------------|
| `before-HH.png`, `after-HH.png` | The whole plot, at twice the screen's points |
| `before-HH-close.png`, `after-HH-close.png` | The middle of the plot, at the phone's own resolution |
| `after-hill-turned-09.png`, `-16.png` (and `-close`) | The third ground, which has a hill, with the plot turned a quarter |
| `sheets.png` | The shadows on their own, seen from above, for three plants at three hours and each figure at 09:00 |

The scene has 14 grown plants from fixed seeds, plus the six figures and lights,
each beside a plant. It stands on the first ground. The date is 26 September
2026, when the moon is full, so the midnight shadows are as strong as moon
shadows get. The test that draws the scene is `PlotRenderTests` (see "Running
it again").

## What changed

- **A shadow's shape comes from the thing itself**, as on the website. The mesh
  that is rendered into each sprite (`PlantMesh` for a plant, the SceneKit model
  for a figure) is reduced to centimetre pieces. Each piece is slid along the
  light onto the ground and counted in layers. A tall thin stem therefore casts
  a long thin shadow, and a cushion a short broad one. Where leaves overlap,
  the shadow is darker. The plant shadows are gently dappled.
- **Sharp at the foot, softer further out**, according to how far along the
  ground each part lands. A five o'clock shadow is long and blurs out along its
  length.
- **Multiplied into the ground and cut to its top surface.** All the shadows are
  one layer, drawn after the ground and before anything that stands on it. They
  stop at the rim, so nothing falls down the cut or over the sky. A lamp's pool
  of light is drawn after the shadows, so it lightens them. On a slope, a
  shadow is laid on the slope itself. A plant standing in a hill's shade throws
  no shadow of its own.
- **Moon shadows are fainter and cooler, and depend on the phase.** At new moon,
  a fifth of the full-moon shadow remains, because the ground is still lit from
  where the moon is.
- **The sun hands over to the moon without a jump.** A shadow fades to nothing
  as its light reaches the horizon at 06:00 and 18:00. The next one fades in as
  the other light rises.
- **Shadows are worked out at 48 points a day**, every half hour. They are
  kept, and cross-faded between steps. The sprites stay at 8 points a day: two
  shadows 45° apart, cross-faded, would read as two shadows.
- The hare, the fox and the snail had no shadow before. Their sheared one threw
  the body forward as a dark copy (`docs/ARRANGING.md`). The shadow is now
  worked out from their models. The code is in
  `App/PeaceGarden/Rendering/GardenShadows.swift`.

## Frame times

These were measured on the iPhone Air simulator (iOS 26.5), in a Debug build of
the same scene. The machine was shared with other agents' builds, with a load
average between 40 and 390. That load moved the numbers between runs by more
than the shadows cost, so the most reliable figure is the one taken within a
single run.

| | With shadows | Without |
|---|---|---|
| Within one run: 40 frames with, 40 without, six times each (main-thread CPU per frame, median of six) | 71.2 ms | 70.4 ms |
| The same again, a second run | 74.8 ms | 81.4 ms |

**Drawing the shadows costs about 1 ms of main thread per frame**, which is
inside the noise. To get this, the plot is redrawn every frame (as in a drag or
a pan) with nothing new to make. The shadows are switched off with a debug-only
switch, `Developer.hidesShadows`.

The before and after builds were also timed, one run after the other. Each run
went through three phases:

- the plot redrawn every frame;
- the clock run from 07:00 to 17:00 in 4 s, which remakes the ground, the
  sprites and the shadows;
- the same clock run again, with everything already made.

| | Before (5 runs) | After (4 runs) |
|---|---|---|
| Plot redrawn every frame: main-thread CPU per frame | 62–73 ms (median 67) | 67–87 ms (median 73) |
| Clock run, first time: mean frame | 94–163 ms (median 106) | 100–123 ms (median 118) |
| Clock run, second time: mean frame | 92–98 ms (median 96) | 92–93 ms (median 92) |

The first clock run is about 10 ms a frame slower with shadows. The shadows for
each new half hour are being worked out in the background then, alongside the
sprites. Once they are made, as in the second run, there is no difference.

Before the shadows, the plot already cost 60–70 ms per frame in Debug. That is
the app's own cost, not the shadows', and worth a separate look.

The shadows are worked out off the main thread, in Debug:

- each plant, once: 41–71 ms;
- each half-hour step from then on: 30–52 ms per plant.

So a step change across fourteen plants is about a second of background work in
Debug. The six figures are modelled on the main thread, once per session:
40–150 ms each in Debug. A Release build on a phone was not measured; it
should be several times faster.

## What still looks wrong

- **Noon pools merge.** Under the cluster of large flowers, several shadows
  overlap into one heavy dark patch. That is physically right, but heavy.
- **Five o'clock shadows read as shade more than as shapes.** They are long,
  broad and soft, and on this dark ground the stems' lines mostly dissolve.
- **A shadow lands only on the ground**, never on a plant or a figure beside it.
  The website does the same.
- **On a slope, a shadow lies on the plane of the ground at the foot.** Across a
  ridge or into a hollow it does not bend.
- **A plant dragged into a hill's shade loses its shadow at once.** The check is
  made at the foot only.
- **Zoom was not rendered.** The test cannot set it. The shadows are soft, so
  scaling them up should not show, but nobody has looked.
- **The Long Walk preview hedges keep their old shadow.** This only affects the
  developer preview.

## Questions for Marcus

1. Noon shadows take up to three quarters of the ground's light where they are
   densest.
   **Keep** (recommended), or lighter?
2. At new moon, a fifth of the full-moon shadow remains. **Keep** (recommended),
   or none?
3. The hare, fox and snail now have shadows, though they had none since build 3.
   **Keep** (recommended), or take them away again?

## Running it again

```
TEST_RUNNER_PG_RENDERS=/some/folder TEST_RUNNER_PG_RENDERS_PREFIX=after \
xcodebuild test -project PeaceGarden.xcodeproj -scheme PeaceGarden \
  -destination 'platform=iOS Simulator,id=<your own simulator>' \
  -only-testing:PeaceGardenTests/PlotRenderTests
```

Further variables:

- `TEST_RUNNER_PG_RENDERS_HOURS`: the hours to draw, e.g. `9,16`;
- `TEST_RUNNER_PG_RENDERS_WORLD`: the ground;
- `TEST_RUNNER_PG_RENDERS_TURN`: the plot's quarter turns;
- `TEST_RUNNER_PG_FRAMES=1`: also time frames.

The PNGs here were fitted inside 1000 px and passed through `pngquant` where
they would otherwise have been over 480 KB.
