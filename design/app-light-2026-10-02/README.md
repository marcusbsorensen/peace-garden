# The plot's light, warmed to the sky — 2 October 2026

Marcus chose on 2 October that once the shadows had landed, the light on the
plot should warm to match the new day sky, the low gold sun of morning and
evening most of all. Until now the sky went gold as the sun got low, and the
ground and the plants under it stayed noon-white.

## The pictures

The same scene and framing as `design/app-shadows-2026-10-02/final-*-close.png`:
fourteen grown plants, the six figures and lights, the first ground, London.

| Files | When |
|---|---|
| `before-summer-08.png`, `after-summer-08.png` | 21 June 2026, 08:00 |
| `before-summer-12.png`, `after-summer-12.png` | 21 June, noon |
| `before-summer-17.png`, `after-summer-17.png` | 21 June, 17:00 |
| `before-winter-12.png`, `after-winter-12.png` | 21 December, noon |
| `before-summer-00.png`, `after-summer-00.png` | midnight, 21–22 June |
| `stronger-summer-17.png`, `stronger-winter-12.png` | the warmth turned all the way up, for comparison. Not what is built. |

What to look for:

- **17:00** is the biggest change. The plants now stand in the evening sun:
  gold where they face it, and the hare cream rather than mint. The ground
  is a little warmer and no darker.
- **Winter noon** is warm all over, under the pale low sky of December.
- **Summer noon** is the noon it was. **Summer 08:00** has barely moved: in
  June the sun is already 31° up at eight, and the sky at that hour is blue.
  The gold is from about 06:00 to 07:30 and 16:30 to 18:00.
- **Midnight** differs nowhere by more than 6 levels in 255.

## What changed

- **The sun's colour comes from the sky.** It is the colour the day sky paints
  round the sun's disc, taken in by how low the drawn sun stands. Above 30° that
  is nothing. At five on a summer evening, 16° up, it is a pale gold. On the
  horizon it is the orange of the disc. A December noon in London stands 15°
  up and is lit like a summer evening. The sun keeps its brightness as it
  turns gold, so the plot is warmer, not darker.
- **The sky's light on the ground takes the drawn sky's colour**, at the same
  brightness as before at every hour. It takes 60% of the colour change.
  Shade is lit by the sky alone, so this keeps it a little cooler than the
  sunlit ground beside it, and a long evening shadow still reads as shade.
  The `stronger-` pictures take all of it. There the ground goes brown rather
  than gold.
- **One sun.** The season now travels on the light. The sky paints its
  colours from the light's season, and the ground, plants, figures, hedges and
  the shade under the shadows are all lit by that same light. The season is
  rounded to a degree of noon and a twentieth of haze, and is part of every
  cache key the light is in. A new season means new pictures, every few days.
- **Plants and ground are lit by the same body at every hour.** The plants are
  photographed at eight hours and crossfaded between them. The picture at
  18:00 was moonlit, so from 15:00 every afternoon a plant faded towards a
  moonlit picture of itself, and by 17:00 it was two thirds moonlit while the
  ground beside it was still in the sun. The same thing happened before dawn
  the other way round. Each hand-over at six is now two pictures, one from
  each side, and the afternoon reaches towards the sun going down. A plant
  now changes at six together with the ground, as the ground always has.

## Where this departs from the sky's notes

`design/app-sky-2026-10-02/README.md` suggested the season should also
**move** the sun: a 15° noon in December, with longer shadows and a dimmer plot.
That has not been done. The season colours the light, and the direction and
strength stay the orbit's. This keeps the rule the sky already follows
(`Season`: "it leans the colours; it does not move the sun"). It also keeps
the shadows as Marcus set them this morning. On level ground a 15° sun gives
about a third of the light a 62° one does, so a moved winter sun would mean a
dark plot all winter.

## The one change at night

Moonlight, the ground and the shadows are unchanged. Between 03:00 and 06:00
the plants are now crossfaded towards the moon setting rather than the sun
rising, so before dawn they are as dark as the ground they stand on. Until now
they brightened towards sunrise from three in the morning.

## Questions for Marcus

1. **How warm?** As built (`after-`) or all the way (`stronger-`)?
   *Recommended: as built.* Stronger turns the ground brown.
2. **Should the winter sun stand lower as well**, with longer shadows and a
   darker plot all winter? *Recommended: no.*
3. **Before dawn**, should the plants match the moonlit ground, as now, or
   brighten towards sunrise from three o'clock, as before?
   *Recommended: match the ground.*

## Running it again

```
TEST_RUNNER_PG_RENDERS=/some/folder TEST_RUNNER_PG_RENDERS_PREFIX=after-summer \
TEST_RUNNER_PG_RENDERS_DATE=2026-06-21 TEST_RUNNER_PG_RENDERS_HOURS=8,12,17,0 \
xcodebuild test -project PeaceGarden.xcodeproj -scheme PeaceGarden \
  -destination 'platform=iOS Simulator,id=<your own simulator>' \
  -only-testing:PeaceGardenTests/PlotRenderTests
```

`PG_RENDERS_DATE` is new: the day to draw, with any hour before six taken as
the morning after it. The `-close` pictures are the ones kept here, put
through `pngquant`. The warmth is two numbers in `GardenLight.swift`:
`sunWarming` (0.85) and `skyWarming` (0.6). The stronger pictures set both
to 1.
