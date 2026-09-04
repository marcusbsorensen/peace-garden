# Peace Garden — handover 4 September 2026

*This session ran four strands: the stage framing, the site's own writing, the
app icon, and the translation commission. They were sequential rather than
tangled, but a fresh session should pick one.*

## Goal

Get the app and site launch-ready. The writing settled and translated, the mark
final, and the work off this machine.

## State

`main` at `393227f`, **pushed**, CI green on both jobs — the first passing run
since 2 September, and it now runs five Python checks rather than four.

**Verified.** 97 SeedCore tests, 23 app tests, five Python checks. Framing seen on
an iPhone 17 Pro and an iPad mini, across mature, five-day seedling and
name-turned-off; the icon on a home screen; Arabic and Hebrew in a browser.

- **The plant stands above its name**, 14pt clear, framed into the space above
  the measured band and anchored on its base, so a seedling stands where a
  mature plant stands. Other screens pass no band and are unchanged.
- **The flush reads** — open star to shut bud across one cycle, four times the
  petal pixels at peak against trough. The old worry about 45% is closed.
- **All six prose strings settled**, two corrected against the code rather than
  reworded, and `docs/FOR-REVIEW.md` retired with nothing lost.
- **41 of 42 languages commissioned**, Greenlandic held deliberately.
- **The icon is inverted**: white bract, the colour running in and going yellow
  as it tapers. The favicon comes off the same drawing.

**Unverified.** iPad landscape framing — the arithmetic is safe (a fixed ~180pt
band against 744pt) but the rotation would not drive from here. The translations
are machine-made and have had no native eyes.

## Files

- `App/PeaceGarden/Rendering/PlantSceneView.swift:115` — `settle`, `clearance`,
  `standingLine`, and the aim that anchors the base.
- `App/PeaceGarden/Views/PlantStageView.swift:135` — `BandTopKey`.
- `Server/assets/js/strings.js` — the six, each with its reasoning above it.
- `tools/strings/{BRIEF.md,commission.py,terms.py,check.py}` — the commission
  pipeline; `check.py` is in CI.
- `tools/icon/make_icon.py:103` — the bract and taper constants.
- `Server/strings/kl.json` — why Greenlandic is held.

## Decisions made

- **The band is measured, not counted from type sizes** — two of the four things
  in it can be turned off, and the safe area differs per device.
- **Area names stay English**, once: ten strings would have been 420
  commissions, and *cold frame* has no clean equivalent in several languages.
- **`growBody` may never say the same two seeds make the same plant.**
  `Pollination.encounterID` hashes both seeds *and* both nonces. Marcus caught
  it; it had stood for weeks.
- **`about3` is read only by somebody with no seed** (`page.js:136`), so it says
  how a seed reaches you rather than how the fragment works.
- **Greenlandic ships English rather than a confident wrong sentence.**
- **Spanish, Portuguese and Galician are region-neutral**, `growBody` being the
  first string to need a second-person plural.

## Next step

Get native speakers to `/t` (word: `peace`), starting with Greenlandic, which
cannot ship until somebody reads it. `python3 tools/site/serve.py`, then
`http://localhost:8801/t`.

## Traps

- **`cd` persists between Bash calls.** Always pass absolute `--package-path`.
- **Render a night-opening plant at its own peak hour.** At 13:00 the diurnal
  factor damps it to a third and every flower is a shut bud — indistinguishable
  from a broken feature. Get the tempo from `tools/preview/plant_model.py`.
- **The developer clock is a `UserDefaults` double**, so `xcrun simctl spawn
  <udid> defaults write app.peacegarden developer.clockShift -float <seconds>`
  before launch beats tapping +1w, and takes negative values.
- **The marks at the foot of the stage do not answer injected taps.** Use
  `xcrun simctl launch <udid> app.peacegarden -pgOpen settings`.
- **A term match must be on the head of a word, not the whole of it.** Estonian's
  genitive `seemne` against a nominative `seeme` broke this once.
- **Catalogue keys are nested under `strings`**, not at the top level. Counting
  them at the top level says every language is untranslated.
