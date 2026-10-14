# UI follow-ups, 14 October 2026

Drawn on an iPhone Air, by the app's own code, for Marcus to choose from.

| File | What it shows |
|------|---------------|
| `about.png` | The i beside Location description, About at the foot of Settings, and the About sheet. |
| `stage-share.png` | The Share mark top right on the stage, and its five rows. |
| `meet-not-this-time.png` | The X while Meet looks; the words over a plant just made (an imaginary meeting). |
| `backgrounds-hours.png` | The sky of the phone's hour as first built (A) beside the time-lapse's sky (B), at 09:00, 18:10, 18:30 and 23:00. |
| `backgrounds-hours-C.png` | **21C, built**: 06:00, 09:00, 18:10, 18:40, 19:30 and 23:00, on the lock screen, as the shared picture, and as the last frame of the shared time-lapse. |

## The sky of the phone's hour

A shared picture, video or wallpaper stands under the sky of the hour on the
phone's clock (`ShareGround.byTheHour`), read from the clock and nothing else:
no location, no season, and the same fixed star field at every hour.

**As first built (`backgrounds-hours.png`, row A)** it was the garden's own
sky: day from 06:00 to 18:00, the garden's dusk while the sun was less than
24° under, and the garden's starry night. The garden's dusk is brief and
faint, so 18:10 and 18:30 already read as night. Row B, not built, was the
time-lapse's sky for the same hours: rose and mauve, with no horizon band.

### Marcus's choice: 21C

> Use the time-lapse's rose and mauve sky for the dusk and dawn hours only;
> keep the garden's starry night at night and the garden's day by day.

What is built (`ShareSky`, `ShareBackdrop`):

- **Day**: the garden's day sky, its sun on the left in the morning and the
  right in the afternoon, below the lock screen's clock.
- **Dusk and dawn**: the time-lapse's sky (`TimeLapseSky`), from its own colour
  definitions for the sun's height, drawn as the time-lapse draws it over a
  dark stage. 06:00, with the sun on the horizon, is dawn.
- **Night**: the garden's starry night, as before.
- **Handed over, not switched.** The garden's day comes in over the dusk
  across the first 6° of the sun's climb (where the time-lapse's colours
  become the day's), and the dusk thins into the garden's night between 12°
  under (where its colours have become the night's) and 24° under. The fixed
  stars come out as the time-lapse's own do, between 4° and 16° under. On the
  orbit's sun that is 17:38 to 18:00 into dusk, 18:15 to 19:00 for the stars,
  and 18:45 to 19:31 into the night; dawn is the same in reverse.
  `PlantShareTests.testTheSkyByTheHourHasNoJump` measures the ground every
  five minutes from 17:30 to 21:00, and from 03:00 to 06:30, and holds every
  step in mean luminance under 2.5% of the full range (the first build
  jumped 5.9% at 18:00 and 5.6% at 06:00; the garden's own day dims by up to
  1.7% in five minutes late in the afternoon).
- **18:40 is nearly night.** The time-lapse's rose is strongest about 3°
  under (18:10) and its colours are the night's by 12° under (18:45), so
  18:30 is a dim mauve and 18:40 reads as night with the stars coming out.
  That is the time-lapse's own dusk, as row B showed it; a longer dusk would
  mean stretching it for the share.
- **No stars by day.** The first build let the garden's stars show over the
  day as the sun got low. With the time-lapse's dusk after sunset they would
  have gone out at 18:00 and come back at 18:15, so the stars now follow the
  time-lapse's rule at every hour.
- **The shared time-lapse ends under the same sky.** While the plant rests at
  the end of the film, the time-lapse's sky hands over to the shared
  picture's ground for the same hour, in place of leaving to the bare stage
  (`TimeLapseFilm.Options.endsUnderTheHour`). At dusk the two are the same
  colours, so the handover only brings in the fixed stars and the plant's
  pool of light. The film is still held to the time-lapse's flash rules
  (`TimeLapseLuminanceTests`).

To draw the sheet again:

```
xcodebuild test … -only-testing:PeaceGardenTests/PlantShareRenderTests/testDrawTheSkyByTheHour \
  TEST_RUNNER_PG_RENDERS=<folder>
python3 design/ui-followups-2026-10-14/compose-hours.py <folder>
```
