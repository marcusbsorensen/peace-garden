# Sharing a plant — 13 October 2026

Marcus, 13 October:

> can we add a function for the user to save their plant as their wallpaper
> somehow? Maybe an option for an animated slowly turning version also? I think
> we need a "Share button" top right on the plant's screen that gives some
> options like that, including sending the plant as a photo to the Photo album,
> via email, whatsapp, etc. Not the seed, but the current state of the growing
> plant

Built on `claude/share-plant-2026-10-13`. Everything new is in
`App/PeaceGarden/Views/Share/`; `PlantDetailView` gained one overlay.

## What it does

**A Share mark top right on a plant's screen, beside Close** — the system's
`square.and.arrow.up` in the same hairline ring as the X, read by VoiceOver as
*Share*. It opens the system menu with four rows:

| Row | What it makes | Where it goes |
| --- | --- | --- |
| **Share picture** | A still of the plant as it is now, 1440 × 1800 (4:5) JPEG | The share sheet: Save Image, Mail, Messages, WhatsApp, AirDrop… whatever the phone has, none named by the app |
| **Share turning video** | Once round on its stem in 8 s, 1080 × 1350 H.264 MP4, 30 fps | The share sheet |
| **Save as wallpaper** | A still at this phone's own screen pixels, the plant below the lock screen's clock | Photos, then a line: *Saved to Photos. Open it there, tap ⬆, then Use as Wallpaper.* (the glyph is drawn in the line) |
| **Save as moving wallpaper** | A Live Photo: the wallpaper still, and a 3 s turn (three-eighths of a turn) that comes to rest on it | Photos, as one Live Photo asset, then the same line |

While a picture or a movie is being drawn the glyph dims and a hairline runs
round its ring as the frames are made (information, not motion, so Reduce
Motion keeps it). The plant is drawn offscreen with SceneKit's `SCNRenderer`,
off the main thread, with the stage's own scene, lights and camera
(`PlantSceneBuilder`), at the growth it has now (`model.now`).

**Nothing about the plant goes with it but its picture.** No seed, no name, no
other gardener, no meeting place or date: not in the pixels, not in the
metadata, not in the file name (every file is *Peace Garden.jpg/.mp4/.heic/.mov*).
The night sky is the real sky for one fixed moment over the equator at
Greenwich rather than the person's own, which would say roughly where and when
the picture was made. `PlantShareTests` reads every byte of every file for the
seed and the name.

**Photos is add-only** (`PHPhotoLibrary.requestAuthorization(for: .addOnly)`):
the app can put a picture in and cannot see what is there. Purpose string,
in `Resources/Info.plist` (the brief said `project.yml`, but this project's
plist is a file and `INFOPLIST_KEY_*` settings are inert here, as the
export-compliance comment in the plist explains):

> Peace Garden adds a picture or a video of your plant to Photos when you ask
> it to, so you can keep it or use it as your wallpaper.

Translated in `InfoPlist.xcstrings` (Danish translated, the rest needs_review).
`PrivacyInfo.xcprivacy` is unchanged: nothing here uses a required-reason API.

**The website's privacy page** describes what the app and the site *send*. The
app sends nothing new: a picture leaves the phone only when the person hands it
to another app through the system share sheet. So no line is needed for the
page to stay true; question 8 below offers one anyway.

## The pictures

| File | What |
| --- | --- |
| `backgrounds-ABC.png` | The three grounds, each as an iPhone Air wallpaper on a mock lock screen |
| `wallpaper-lockscreen-A.png` | The recommended ground larger, on the mock lock screen |
| `mark-AB.png` | The shared picture with no mark, and with the site's mark small in a corner |
| `sample-picture.jpg` | The shared picture as sent, downscaled to 1080 wide |
| `turning-strip.png` | Six frames of the turning video, 0 to 8 s; the last is the first |
| `moving-strip.png` | The moving wallpaper's frames, 0 to 3 s, and the still it ends on |
| `button-light-dark.png`, `menu-light-dark.png` | The mark and its menu on a real plant's screen, simulator, Light and Dark |
| `flow-dark.png` | The share sheet, the Photos prompt and the line after saving, simulator, Dark |

The lock screen is a mock — the system's clock face and weight vary with the
phone's own settings — but its places and sizes are the system's. The MP4 and
the MOV are not committed; the strips are. `compose.py` lays the sheets out from
what `PlantShareRenderTests` draws (`PG_RENDERS`).

## Decisions for Marcus

Recommendation first in each.

1. **What the plant stands on** (`backgrounds-ABC.png`)
   - **A. The garden's night sky**, with the plant's own pool of light behind
     it (built). The clock reads white over it, and it is the sky the garden
     already has.
   - B. The garden's day sky, mid-morning.
   - C. The plant's own stage as a dark phone shows it: black and the pool.
2. **A Peace Garden mark in a corner** (`mark-AB.png`)
   - **A. None** (built). The picture is the plant's; a mark on somebody's
     wallpaper is an advert on their phone.
   - B. The site's mark, small, lower right, on the shared picture only.
3. **The person's own plant (the stage) has no Share yet.** Its chrome is all at
   the foot, and a fifth mark there does not fit Swedish on an SE.
   - **A. The same mark top right on the stage, shown and hidden with the row**
     (`controlsVisible`), so both plant screens share from the same corner.
   - B. A fifth mark in the foot row.
   - C. Leave the stage without it.
4. **The shape of the shared picture and video**
   - **A. 4:5 portrait** (built): whole in Messages, Mail and a feed, and a
     plant is taller than it is wide.
   - B. Square.
   - C. The phone's own screen shape.
5. **How the moving wallpaper moves**
   - **A. 3 seconds, three-eighths of a turn, ending on the still** (built):
     the length of a Live Photo the camera takes, at the video's own pace.
   - B. The whole 8-second turn. iOS may trim or refuse a Live Photo that long
     as a wallpaper.
6. **How fast the video turns**
   - **A. Once round in 8 seconds** (built).
   - B. 12 seconds, slower and calmer, a larger file.
   - C. 6 seconds.
7. **A young plant in a picture**
   - **A. The frame comes in so a plant fills at least 45% of its band**
     (built), as the garden's tiles do. A seedling in a shared picture is
     something, not a speck.
   - B. As on the stage: small in a large space, sized against what it will grow
     into.
8. **The website's privacy page**
   - **A. No change**: it says what the app sends, and the app sends nothing
     new.
   - B. One sentence after the storage paragraph: *A picture or a video of your
     plant leaves your phone only when you share or save it yourself, and it
     carries the plant and nothing else.* (A new key in 42 languages.)
9. **The picture under Light appearance**
   - **A. The chosen ground whatever the appearance** (built): a wallpaper is
     not the app's screen.
   - B. Light appearance shares the light stage instead.
10. **The menu**
    - **A. The system's menu** (built): four rows, a glyph each, read by
      VoiceOver, and a fifth (the time-lapse) is one more case.
    - B. A sheet of our own, in the app's type.

## What was verified, and what was not

**Unit tests** (`PlantShareTests`, 7): the picture is 1440 × 1800; a wallpaper
is the screen's own pixels (iPhone Air 1260 × 2736, a 1179-wide phone, an SE),
its movie the nearest even size; the plant is drawn over the ground, not in a
box; the turn is 240 frames and 8.0 s and its last frame is its first; the
Live Photo's still and movie carry one identifier and the still-image-time is
the last frame, which is the still; and no file carries the seed, the name, a
location or a date, and the shared video carries no metadata at all.

**On a scratch iPhone Air simulator**, through the real mark on a real plant's
screen (a fixture garden, driven by a throwaway UI test): all four rows. The
picture and the video reached the share sheet and were saved from it with
*Save Image* and *Save Video*; Photos asked once, with the purpose string; the
wallpaper and the moving wallpaper were saved and the line came up after each,
which VoiceOver reads with *Share* where the glyph is. Read back through
PhotoKit from a process allowed to read the library: the moving wallpaper is
`mediaSubtypes` `.photoLive` (8) with a photo and a paired-video resource, all
the saved stills are 1260 × 2736 or 1440 × 1800, the video 1080 × 1350 and
8.0 s, and none has a location.

**Not verifiable on a simulator:** whether iOS accepts the Live Photo as a
*moving* wallpaper on the lock screen. The simulator has no wallpaper picker,
and which Live Photos may move there is not published (developers report
"Motion not available" for some made in code). It needs trying on a phone:
save a moving wallpaper, then Photos → Share → Use as Wallpaper. If it says
"Motion not available", question 5's B is no help; the next things to try are
HEVC instead of H.264 and the still-image-time in the middle of the clip, as
the camera writes it.

## For the time-lapse

`MovieWriter.write(…, draw:)` turns any run of drawn frames into an H.264 movie,
and `PlantPictureRenderer.show(growth:)` puts the same plant at another age in
the same frame. A *Share time-lapse* row is one more case in `PlantShareAction`
and one more branch in `PlantShareWork.start`.
