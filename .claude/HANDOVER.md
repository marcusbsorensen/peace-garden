# Peace Garden — handover 31 August 2026

This session covered three unrelated things: the plant rendering, a settings
screen, and the phase-2 sharing design. The reasoning lives in the commits and
in `docs/`, not here.

## Goal

Phase 1: a plant grown from a seed drawn once, and two people crossing seeds by
touching phones. `docs/HANDOVER.md` is the long-form handover, still current for
everything this session did not touch.

## State

Tree clean, `main` at `cebc66f`, **everything pushed**. 63 SeedCore tests pass;
the app builds at Swift 6 with complete concurrency.

**Verified by looking, on an iPhone 17 Pro Max simulator:** plants across six
genomes and five ages. Leaves have pinnate venation, relief and a proper
base-to-tip ramp; surfaces carry normal and roughness maps off one bake; a
bounce light stops away-facing leaves crushing to black; spikes taper and
flower in a gradient; petals can break their colour (flamed / marbled /
brushed); every part wears its own age. The settings screen, including the
reset alert and its cancel.

**Built and never seen running:** the Exchange screens. Same three things as
last session — the naming step, `UnfurlingBackdrop(.pair)` in place, and the
first-meeting passage. No longer blocked; nobody has just done it.

## Files

- `Packages/SeedCore/Sources/SeedCore/Morphology/Palette.swift` — `venation`,
  `relief`, `breaking`. Colour and relief sampled at the same `(u, v)`.
- `App/PeaceGarden/Rendering/GradientTexture.swift` — bakes diffuse, normal and
  roughness per role. Resolution is per role; the HSB conversion is arithmetic
  on purpose.
- `App/PeaceGarden/Rendering/PlantSceneBuilder.swift` — materials, the aging
  shader modifier, and why self-shadowing was abandoned.
- `Packages/SeedCore/Sources/SeedCore/Morphology/PlantBuilder.swift` — leaf
  taper, per-flower scale, and the two `ceiling` values that make the age
  gradients permanent.
- `App/PeaceGarden/Views/SettingsView.swift`, `Views/Sharing.swift` — the panel
  and the invitation preference.
- `docs/PHASES.md`, `docs/PLACE.md` — the sharing decisions below.
- `design/garden/` — five shared-garden mock-ups; the seeded `.html` is
  generated and gitignored.

## Decisions made

- **A shared page names the gardener who shared it, and nobody else.** The
  other is invited; the page says nothing about them, not even a placeholder,
  until they accept. Both notes then show, attributed — two accounts of one
  meeting may disagree, and that is the record.
- **A published note never carries the coordinate.** The consent that put it
  there was about two phones making no network request.
- **The exchange payload needs an opaque contact token**, agreed at the
  meeting. One field, and impossible to add to meetings already made.
- **Age gradients must be positional, not only temporal.** Unfurling is spent
  within days, so a plant that grows up loses the gradient entirely.
- **Self-shadowing is off**, and stays off until blades have thickness. Two
  shadow modes and a correct frustum produced nothing: every blade is a single
  double-sided surface with no back to cast from.

## Next step

Reach Exchange in the simulator and watch a real crossing: the passage, its
provenance line, the suggested place, and the place offer.

## Traps

- **A screenshot straight after a tap catches the screen before the sheet.**
  This cost two sessions, recorded as a phantom "taps open nothing" blocker.
  Wait about a second, or print from the action to be sure.
- **To look at a mature plant**, edit `garden.json` in the app container
  (`xcrun simctl get_app_container <udid> app.peacegarden data`, then
  `Library/Application Support/PeaceGarden/`): backdate `birth` and swap `seed`
  (any sha256 hex). The container path rotates on every reinstall, so re-resolve
  it each time. Fifteen days clears `daysToBloom` for any genome.
- **The `.color` geometry semantic is not a free channel.** SceneKit multiplies
  vertex colour into the diffuse before any shader modifier runs. Use a second
  texcoord set.
- **Shader modifier varyings** want a `#pragma varyings` block and `out.`/`in.`,
  not `#pragma varying <type> <name>`. Failures render magenta; the real error
  is in `xcrun simctl spawn <udid> log show`.
- **The simulator's input connection drops.** Re-`attach`, and re-boot if that
  fails; taps then work again.
- **New files need `xcodegen generate`.** The `.xcodeproj` is gitignored.
