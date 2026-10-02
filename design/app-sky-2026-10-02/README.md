# The day sky, four ways — 2 October 2026

Marcus: the daytime sky is "nowhere near as pleasing to look at as the night sky", "that slightly petrol blue". These are four proposals, drawn behind a plot as the garden frames it, on 2 October in London at 07, 10, 13, 17 and 19. None is the default.

- **now** — the sky as it ships: one radial of greyed teal, the same at every height.
- **A** — the real colour of the hour: a deep blue overhead, a pale luminous band at the horizon behind the plot, a halo round the sun, gold and rose as it gets low.
- **B** — A with the day's clouds: soft heaps or high wisps, the same for everyone that day, some days none, crossing in about a quarter of an hour.
- **C** — A with the real moon by day when it is really up, the sun's height leaning with the season and the latitude, and the brightest planet at dusk.
- **D** — A with, now and again, a few birds crossing very high: geese now, swifts in summer, about one crossing an hour.
- **BCD** — all of them together.

`sheet-07.png` to `sheet-19.png` put every option side by side for one hour. `b-13-high.png` and `b-13-mixed.png` are other days' weather, `d-13-july.png` is the swifts, and `now-18-20.png` / `a-18-20.png` show the last of the light after sunset, which A adds. The night itself is unchanged in every option.

## What each costs

CoreGraphics on the simulator at 3x, so for comparison rather than a promise about a phone (`notes.txt`):

| | still canvas, redrawn every 20 s | moving canvas, every frame |
|---|---|---|
| now | 11.9 ms | none |
| A | 27.8 ms | none |
| B | 27.8 ms | 2.4 ms at 12 fps |
| C | 27.8 ms | none |
| D | 27.8 ms | 0.1 ms at 30 fps, only during a crossing (about 1.5% of the time) |
| BCD | 27.8 ms | 2.6 ms |

If A is kept, its gradients could be painted once a minute into a small picture and scaled up, which should bring the still canvas close to what now costs.

## What the options imply but do not do

The light on the plot is untouched, so the shadow work stays valid. Three things follow from the new sky and are left for a decision:

- **The plot's light could warm when the sun is low.** The sky goes gold at 07 and 17 while the plot is still lit a neutral white (`GardenLight` colour 1.00, 0.96, 0.88). The sun's disc is warmed in the sky drawing only.
- **The plot's sky light could follow the sky.** The ground and plants take a constant blue-grey from above (`skyByDay`), which now reads dull against a brighter, bluer day and a warm dusk.
- **C's season moves the sky, not the sun.** A London December keeps a low, golden sky all day while the orbit still lights the plot as at midsummer.

## Small things noticed

- The sun stands where the orbit's projection puts it: half off the left edge at 13 and in the bottom-left corner at 17, so the afternoon halo rises from below. Unchanged.
- In an empty garden, B's clouds can pass under the line of help text below the heading, which is not one of the frames the sky keeps clear of. Adding it would be one line in `PlotView`.
- To try one on a phone: Settings → Testing → *Sky*, or `-pgSky clouds` (`now`, `hour`, `clouds`, `season`, `life`, `all`).
