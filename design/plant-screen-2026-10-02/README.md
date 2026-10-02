# The plant 56 points higher on its own screen

2 October 2026. The plant on the app's main screen now stands 56 points higher
than it did, and is the same size. The name, the stage caption and the marks
have not moved. `PlantSceneView.Coordinator.rise` holds the number and the
reasons; nothing else changed.

Each picture is before on the left, after on the right.

| File | What it shows |
|------|---------------|
| `01`–`04` | iPhone Air: tall plant upright, tall turned and tilted, broad upright, broad turned and tilted |
| `05`–`08` | iPhone SE (3rd generation), the same four |
| `09`, `10` | The words hidden (Settings: *Hidden*), Air and SE, tall and broad |

## Why 56 points

The plant used to stand 14 points above its name. Measured over a thousand
minted plants, each turned all the way round and tilted to the limit of the
drag:

| | Before | After |
|---|---|---|
| Plants reaching the name's line, upright (Air / SE) | 244 / 203 | 0 / 0 |
| Plants reaching the name's line, tilted (Air / SE) | 362 / 388 | 2 / 38 |
| Plants reaching the letters themselves, tilted (Air / SE) | 321 / 355 | 0 / 9 |
| Closest a tilted plant comes to the top safe area (Air / SE) | 92 / 74 pt | 40 / 32 pt |

The broad plants are the ones that collide: the near side of a lotus's pads
or a cushion's rosettes sits lower on the screen than its stem, and lower still
when tilted. Spires, reeds and vines are narrow at the foot and never reached it.

## One position, not an ease

With the words hidden the plant sits higher too, and still looks settled: the
middle plant's centre moves from 60% down the screen to 53% on the Air, closer
to the pool of light behind it (46%). The tallest plants on an SE are the
highest it gets, centred about 39% down with nearly a third of the screen
clear below (picture `10`). Easing the plant up as the words appear would move
it every time the screen is touched and again six seconds later, on the one
screen built to hold still, so it stays put.

## Checked, and not a reason against

- **Top of the screen.** This screen has no controls up there. The tallest
  plant, tilted, stays 40 points clear of the Dynamic Island's safe area on an
  Air and 32 clear of the clock on an SE.
- **Small screens.** The nine plants that still reach the letters are on the
  SE, and only at the very limit of the tilt. On a short iPad window the rise
  is capped so it cannot push an upright grown plant off the top.
- **Release hold.** It is on the garden plant's screen, which has no band
  under the plant and is unchanged.
- **First-run hint.** The plant used to stand behind the panel about meeting
  others; it now stands clear of it on the Air and nearly so on the SE.
- **Sideways.** At the full tilt the widest plant can now reach about two
  points past the side edge of an SE, where before it stopped two points short.

## How the pictures were taken

Two simulators made for this and deleted afterwards. Tall plant minted from
`-pgMint stage-fit-88` (*Ceranina latifolia*, a spire), broad from
`stage-fit-152` (*Nyxisis contorta*, a lotus), both `-pgStage blooming`, with
the turntable off. Tilted is the drag's limit looking down into the plant,
turned to the angle where it reaches lowest; a temporary debug hook set the
pose and is not in the commit. On a simulator the row is always showing.
