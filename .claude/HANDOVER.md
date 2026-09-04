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

**Verified** — 97 SeedCore tests, 23 app tests, five Python checks; the framing on
an iPhone 17 Pro and iPad mini across mature, seedling and name-off; the icon on
a home screen; Arabic and Hebrew in a browser.

- **The plant stands above its name**, 14pt clear, anchored on its base so a
  seedling stands where a mature plant does. Other screens are unchanged.
- **The flush reads** — open star to shut bud across a cycle, four times the
  petal pixels at peak against trough. The old worry about 45% is closed.
- **The six prose strings are settled**, two corrected against the code rather
  than reworded, and `docs/FOR-REVIEW.md` retired with nothing lost.
- **41 of 42 languages commissioned**, Greenlandic held deliberately.
- **The icon is inverted**: white bract, the colour running in and going yellow
  as it tapers. The favicon comes off the same drawing.

**Unverified** — iPad landscape framing (the arithmetic is safe: a fixed ~180pt
band against 744pt) and every translation, which is machine-made.

## Files

- `App/PeaceGarden/Rendering/PlantSceneView.swift:115` — `settle`, `clearance`,
  `standingLine`, and the aim that anchors the base.
- `App/PeaceGarden/Views/PlantStageView.swift:135` — `BandTopKey`.
- `Server/assets/js/strings.js` — the six, each with its reasoning above it.
- `tools/strings/{BRIEF.md,commission.py,terms.py,check.py}` — the commission
  pipeline; `check.py` is in CI.
- `tools/icon/make_icon.py:103` — the bract and taper constants.
- `tools/site/mintlink.py` — mints a seed link, which is the only way to reach
  `growBody` and `appNote` at all.
- `Server/strings/kl.json` — why Greenlandic is held.

## Decisions made

- **The band is measured, not counted from type sizes** — two of the four things
  in it can be turned off, and the safe area differs per device.
- **Area names stay English**, once: ten strings would have been 420
  commissions.
- **`growBody` may never say the same two seeds make the same plant.**
  `Pollination.encounterID` hashes both seeds *and* both nonces. Marcus caught
  it; it had stood for weeks.
- **`about3` is read only by somebody with no seed** (`page.js:136`), so it says
  how a seed reaches you rather than how the fragment works.
- **Greenlandic ships English rather than a confident wrong sentence**, and
  Spanish, Portuguese and Galician are region-neutral — `growBody` is the first
  string to need a second-person plural.

## Next step

**The site is not deployed.** `peacegarden.app/s` and `/strings/*.json` both
answer 404, so nobody can review anything remotely yet. `Server/README.md` says
what to upload. That is the blocker in front of everything below.

Then the review: `docs/REVIEWING-A-LANGUAGE.md` is written for a bilingual
friend rather than a developer, and `python3 tools/site/mintlink.py --review
<code> --base https://peacegarden.app` prints the six links that go with it.
Marcus reads English, French, Danish and Spanish and wants to be walked through
those four in Claude in Chrome, on his own screen. Greenlandic cannot ship until
a speaker reads it; the other thirty-seven want the same packet.

## Still open

- **The two nobody has looked at**, both in `docs/LANGUAGES.md`: the iPhone SE
  layout, and the passage's own direction in the app for an RTL reader with no
  bank. The web solved the second; the app has the same case untouched.
- **The English passage bank is ninety passages short of its own floor** —
  thirteen subthemes under ten, `quietAsASound` at five. It is the one every
  other bank was written against.
- **App Store screenshots.** `-pgOpen` was built for taking four screens in
  eight languages and has never been used for it.
- **Spanish and Portuguese regionality**, if neutral is not wanted.
- **`appNote` shares its first sentence with `about3`** — a duplicated
  commission in 42 languages, never seen together on screen.

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
