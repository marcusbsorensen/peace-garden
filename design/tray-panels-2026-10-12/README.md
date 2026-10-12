# The tray's panels — 12 October 2026

Marcus's answers to the 11 October pictures (`../garden-controls-2026-10-11/`), built, and one
fix to the update check. Branch `claude/tray-panels-2026-10-12`; nothing is merged.

Every picture is the real app on an iPhone Air simulator with a full garden (fourteen plants,
six figures), at night (*Always night*) and by day (*Always day*).

## What changed

**1. One panel behind each row, not a plate behind each figure.** One slightly opaque panel
behind the whole row of figures, and one behind the whole row of plot types. Each is a single
rounded rectangle inside the screen's margins, the same for everything in the row and wherever
the row has been scrolled to. The sky behind it is blurred, which takes the stars and clouds
out from behind the row, and darkened a little by the screen's own ground. The row scrolls
inside its panel and fades at the panel's ends, and the double chevron stands just inside the
panel's edge. The plates, their three options and `-pgPlate` are gone; `PlotTray.swift` is
105 lines shorter (349 to 244).

**2. The plot types: your B, with C's pool of light.** The ones not chosen stand at 0.75
(0.42 before 11 October, full strength since); the chosen one is at full strength in a soft
pool of light. VoiceOver still reads *selected* on it. The bar, the other options and
`-pgGrounds` are gone; one constant, `GroundMark.others`, holds the 0.75.

![](grounds.png)

**3. *Reset view*.** VoiceOver now says *Reset view* for the mark in the tray, instead of a
system symbol's name, and every comment, test and doc that said *put the view back* says
*Reset view*. It was not a string before, so it is one new key in `Localizable.xcstrings`:

| Language | Text | State |
| --- | --- | --- |
| Danish | **Nulstil visning** | translated |
| Spanish | Restablecer vista | needs review |
| French | Réinitialiser la vue | needs review |
| Italian | Reimposta vista | needs review |
| Norwegian | Nullstill visning | needs review |
| Dutch | Weergave herstellen | needs review |
| Swedish | Återställ vyn | needs review |

The Danish follows the catalogue's own words: *Nulstil* as in *Nulstil alt*, *Visning* as in
*Display*. The others are drafts on the same pattern, flagged for the next translation round.

**4. Kosovo in the update check.** Apple's storefront code for Kosovo, `XKS`, is not ISO's, so
the conversion refused it and phones in Kosovo skipped the check. One alias, `XKS` to `xk`, is
read before Foundation is asked. Still never the US store.

## Decision for Marcus

**How strong should the panels be?**

![](panels-ABC.png)

- **A** — the screen's ground at 0.35 over a light blur. *Recommended, built.*
- **B** — lighter, 0.2.
- **C** — darker, 0.55.

The last row, unlettered, is 11 October's plate behind each figure, for reference.

To change it, change `ContinuingRow.shade` in `App/PeaceGarden/Views/PlotTray.swift`.

## Not asked, worth knowing

- **The blur is cheap here.** Two of the system's thinnest blur, where 11 October had seven
  plates each with its own. The night sky behind them is still, and the day sky's clouds
  redraw at most twelve times a second.
- **Under Settings' *Light* appearance the panels are pale, not dark.** They are shaded with the
  screen's own ground, which is near-white in that appearance, so the ink on them still has
  something to stand against. Not photographed; the pictures are the default, *Dark*.
- **The app's string catalogue is behind its source on `main`.** Syncing it after a build
  (`tools/strings/sync.sh`) would also bring in about twenty keys from other work (the public
  website garden's wording, the Wild Fields messages) and mark several stale. Only *Reset
  view* was added here, by hand, in Xcode's own layout; the rest is for whoever owns that work.
- **Debug flags.** `-pgTray YES` still opens the tray on launch. `-pgPlate` and `-pgGrounds`
  went with the options they chose between.

## Tests

- `GardenControlsTests` now also reads what VoiceOver says for the tray's reset mark and
  expects *Reset view*.
- `GardenControlsRenderTests` draws the plot-type row as built, at night and by day, for
  `grounds.png` (skipped unless `PG_RENDERS` is set).
- `UpdateCheckTests.testKosovosStorefrontAsksKosovosStore`: `XKS` and `xks` give `xk`, and the
  check asks in `country=xk`. `XKX`, which is not Apple's code, is still refused.

`panels-ABC.png` is three builds of the app differing only in `ContinuingRow.shade`, each
photographed on the simulator; the reference row is 11 October's photographs of the plates.
