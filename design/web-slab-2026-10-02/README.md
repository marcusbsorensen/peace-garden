# The website's plots as the app's solid slab, before and after (2 October 2026)

Marcus approved the app's slab (`design/app-slab-2026-10-02/`) and asked for
the website's plots to match it, so that both read as the same object. These
are the website's own drawings, before and after, from a local dev server,
captured in headless Chrome at twice the size shown and scaled to 1000 px.
The two close views are reduced to 256 colours to keep them under 500 KB.

| Files | What they show |
|---|---|
| `before-walk`, `after-walk` | `/dev/walk?plot=0`, 1280×800: the Long Walk, three plots end to end. |
| `before-knot`, `after-knot` | `/dev/knot?plot=0`, 1280×800: the Knot Garden. |
| `before-quiet`, `after-quiet` | `/dev/quiet?plot=0`, 1280×800: the Quiet Garden, hedged on four sides. |
| `before-orchard-gateways`, `after-orchard-gateways` | `/orchard`, 1280×800: the Orchard's page with its three neighbours out past it, whose sides are the same slab at half the size. |
| `before-knot-side`, `after-knot-side` | The Knot Garden 2.5 times closer, 1000×1000, on the near corner: both near sides and the lower edge. |
| `before-knot-phone`, `after-knot-phone` | The Knot Garden on a 390×844 phone screen. |
| `app-after-stones-17-wide`, `app-after-stones-17-side` | The app's Meadow at 17:00 from `WorldRenderTests.testDrawTheSlab`, whole and three times closer, on the sky colour of `design/app-slab-2026-10-02/` at that hour: no stones on the whole plot, and the stones there close up. |

## What changed

- **One mass, lit as planes.** Each stretch of side is lit by the way the rim
  faces there, smoothed over 18 cm, so the face toward the noon sun is light
  all over and the face away from it dark all over. The old bank took a normal
  every 8 cm and showed it in vertical stripes (`before-knot-side`).
- **Leaning in to one lower edge.** The side draws in 20 cm on the way down to
  an edge that undulates gently all the way round. The old bank was upright
  to a floor that wandered nearly twice as far, with a seam where it began.
- **Strata as bands.** Humus a hand deep under the turf, then earth, then rock,
  with boundaries that wander along the side, faint layers in each, and a few
  angular stones in the rock.
- **The near side still shows 0.95 m**, as before and as in the app.
- **Stones only when zoomed in** (Marcus, 2 October 2026, on both platforms):
  `after-knot` and the other whole views have none; `after-knot-side`, 2.5
  times closer, has them. The website draws none until the look is 1.3 times
  closer than the whole plot, and then none under eight CSS pixels across.

`docs/WEB-GARDENS.md` §*The plot's side as a solid slab* has what is the app's,
what is different here and why, and the frame times.

## Drawing them again

Serve the site (`php -S localhost:<port> -t Server tools/wasm/dev-router.php`,
with the module built into `Server/.pages/`), then capture each page in a
headless Chromium at the sizes above with a device scale of 2 (3 for the
phone). The close view is the stage's own `toward([2.0, 0.3, 2.0], 2.5)` held
with `lookAt`.
