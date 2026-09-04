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

**Verified.** 97 SeedCore tests, 23 app tests, five Python checks. Framing looked
at on an iPhone 17 Pro and an iPad mini across mature, five-day seedling, and
name-turned-off. Icon seen on a home screen. Arabic and Hebrew opened in a
browser to confirm the fallback marking clears once a key stops being null.

- **The plant stands above its name**, on a line 14pt clear of the type, framed
  into the space above the measured chrome band. Base-anchored, so a seedling
  stands where a mature plant stands. Every other screen passes no band and is
  unchanged.
- **The flush reads.** A mature spire across one cycle goes from open star to
  shut bud — four times the petal pixels at peak against trough. The previous
  handover's worry about 45% being too subtle is closed.
- **All six prose strings settled**, two of them corrected against the code
  rather than reworded. `docs/FOR-REVIEW.md` is retired; nothing was lost.
- **41 of 42 languages commissioned.** Greenlandic held deliberately.
- **The icon is inverted**: white bract, the coil's colour running into it and
  going yellow as it tapers. The favicon now comes off the same drawing.

**Unverified.** iPad landscape framing — the arithmetic is safe (the band is a
fixed ~180pt against 744pt of height) but the rotation would not drive from here.
The 42 translations are machine-made and have had no native eyes.

## Files

- `App/PeaceGarden/Rendering/PlantSceneView.swift:115` — `settle`, `clearance`,
  `standingLine`, and the aim that anchors the base.
- `App/PeaceGarden/Views/PlantStageView.swift:135` — `BandTopKey`, measured
  whether or not the band is on screen.
- `Server/assets/js/strings.js` — the six, each with its reasoning above it.
- `tools/strings/BRIEF.md`, `commission.py`, `terms.py`, `check.py` — the
  commission pipeline. `check.py` is in CI.
- `tools/icon/make_icon.py:103` — the bract and taper constants, and why they
  swapped.
- `Server/strings/kl.json` — its `awaiting` note says why Greenlandic is held.

## Decisions made

- **The band is measured, not counted up from type sizes.** Two of the four
  things in it can be turned off in Settings and the safe area differs per device.
- **Area names stay English**, once. Ten strings would have been 420 commissions,
  and *cold frame* has no clean equivalent in several of the sixteen.
- **`growBody` may never say the same two seeds make the same plant.**
  `Pollination.encounterID` hashes both seeds *and* both nonces. Marcus caught
  this; it had stood for weeks.
- **`about3` is read only by somebody with no seed** — `page.js:136` makes the
  blocks mutually exclusive. It now says how a seed reaches you, not how the
  fragment works.
- **Greenlandic ships English rather than a confident wrong sentence.**
- **Spanish, Portuguese and Galician are region-neutral**, because `growBody` is
  the first string needing a second-person plural.

## Next step

Get native speakers to `/t` (word: `peace`), starting with Greenlandic, which
cannot ship until somebody reads it. `python3 tools/site/serve.py`, then
`http://localhost:8801/t`.

## Traps

- **`cd` persists between Bash calls.** Always pass absolute `--package-path`.
- **Render a night-opening plant at its own peak hour.** At 13:00 the diurnal
  factor damps it to a third and every flower is a shut bud, which looks exactly
  like a broken feature. Compute the seed's tempo with
  `tools/preview/plant_model.py` rather than sampling blind.
- **The developer clock is a `UserDefaults` double.** `xcrun simctl spawn <udid>
  defaults write app.peacegarden developer.clockShift -float <seconds>` before
  launch beats tapping +1w five times, and takes negative values.
- **The marks at the foot of the stage do not answer injected taps.** Use
  `xcrun simctl launch <udid> app.peacegarden -pgOpen settings`.
- **A term match must be on the head of a word, not the whole of it.** Estonian's
  genitive `seemne` against a nominative `seeme` broke this once.
- **Catalogue keys are nested under `strings`**, not at the top level. Counting
  them at the top level says every language is untranslated.
