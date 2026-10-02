# The day sky — 2 October 2026

Marcus said the daytime sky was "nowhere near as pleasing to look at as the night sky", "that slightly petrol blue". Four proposals were drawn behind a plot as the garden frames it, on 2 October in London at 07, 10, 13, 17 and 19, and **he chose B, C and D together**, on A as their ground. That is now the sky by day, for everyone. The night is the one he liked, unchanged apart from the last of the light after sunset and one planet.

## What was chosen

- **A, the real colour of the hour**, under everything: a deep blue overhead, a pale luminous band at the horizon behind the plot, a halo round the sun, gold and rose as it gets low.
- **B, the day's clouds**: soft heaps or high wisps, the same for everyone on a given day, some days none, each taking about a quarter of an hour to cross.
- **C, the real moon by day and the season**: the moon where it really is when it is really up, the sky's colours as high as today's real sun would make them, and the brightest planet at dusk.
- **D, now and again, the season's birds**, very high: geese in autumn and late winter, swifts in summer, a small flock otherwise, about one crossing an hour.

`final-07.png`, `final-13.png` and `final-17.png` are the chosen sky as built. The rest of this folder is what it was chosen from: `sheet-07.png` to `sheet-19.png` put the old sky (`now`), A, B, C, D and BCD side by side for each hour, with the single renders beside them and a few extras (`b-13-high`, `b-13-mixed`, `d-13-july`, `now-18-20`, `a-18-20`).

The old day stays behind the developer switch for comparison: Settings → Testing → *Sky*, or `-pgOldSky YES`.

## What it costs

CoreGraphics on the simulator at 3x, so for comparison rather than a promise about a phone. `notes.txt` has the run.

| | ms |
|---|---|
| Still canvas, the old day | 12.0 |
| Still canvas, chosen, **before**: gradients painted full size every redraw | 27.8 |
| Still canvas, chosen, **after**: the day's light kept as a small picture | 15.4 |
| …the redraw in which the picture is painted again (once a minute) | 15.5 |
| Moving canvas, clouds, every frame at 12 fps | 2.3 |
| Moving canvas, birds, every frame at 30 fps during a crossing | 0.1 |

The still canvas is redrawn when the garden's clock ticks, every 20 s. The day's gradients are painted at half a pixel a point (210 × 456 on this screen) and kept until the minute, the season, the size or the sun's place on screen changes; the kept picture and the full-size painting are indistinguishable in the renders. On a clear day the moving canvas sleeps until the next crossing.

## Warming the plot to match — for after the shadow work merges

The light on the plot is untouched, on purpose. Marcus wants the plot warmed to match a low gold sun once the shadow work has merged. Where it would start:

1. **The low-sun tint.** `GardenLight.swift`, `at(hour:)`: the day's `colour` is a constant `(1.00, 0.96, 0.88)`. Make it the sky's own: `mix((1.00, 0.96, 0.88), SkyPalette.at(elevation:).glow, 0.7 * palette.low)`. At 07 and 17 on the orbit (16° up, `low` ≈ 0.45, `glow` ≈ `(1.00, 0.82, 0.60)`) that is about `(1.00, 0.91, 0.79)`; at noon it is unchanged. The sun's disc in the sky already warms by `SkyPalette.disc`.
2. **`skyByDay`.** The plot's light from above is a constant `(0.40, 0.48, 0.60)`, blended from `skyByNight` by `0.35 + 0.65 * up`. Take it from the drawn sky instead: the middle of `zenith` and `horizon` from the same `SkyPalette`, scaled so its luminance matches today's value at each hour. Bluer than now at noon, warmer at 07 and 17, and no brighter overall. `bounceByDay` can stay.
3. **The season's sun height reaching the light.** The sky already uses `Season(date:place:).noon` as the peak (`SunPath.elevation(atHour:peak:)`); the light still climbs to the orbit's fixed `GardenGround.Light.peak` of 62°. To agree, `at(hour:)` would take the date and place and use `Season.noon` as the peak, and `SunPath.direction(atHour:)` would take the same peak so the sun's disc stays where the light comes from. In London that is 15° at a midwinter noon against 62° at midsummer: longer shadows and a dimmer plot all winter.

What has to move with those, or the plot goes stale:

- **Plant sprites** are cached by `GardenSprites.key(genome:growth:step:turn:)`, which knows the step but not the date. If the light comes to depend on the season, add a season bucket to the key (the declination to the nearest few degrees is plenty).
- **Terrain** is cached in `GardenTerrain.image` on the light's strength and direction only, and `GardenGroundView.baseKey` likewise. A colour or sky-light change that leaves strength alone needs adding to both keys.
- `PlotTests` pins the light curve by its values (`GardenLight.at(hour:)`'s comment says why), so those numbers will need restating, and `GardenGround.Light.noon` is written out by hand and must follow.

## Small things noticed

- The sun stands where the orbit's projection puts it: half off the left edge at 13:00 and in the bottom-left corner at 17:00, so the afternoon halo rises from below. Unchanged.
- The empty garden's help text is now one of the frames the sky keeps clear of, so clouds thin out under it as they do under the heading.
