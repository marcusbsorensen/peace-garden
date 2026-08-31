# Peace Garden — handover 31 August 2026

Two sessions in this file. The first covered the plant rendering, a settings
screen and the phase-2 sharing design. The second went and drove the Exchange
screens on two simulators, which is what the first one said to do next. The
reasoning lives in the commits and in `docs/`, not here.

## Goal

Phase 1: a plant grown from a seed drawn once, and two people crossing seeds by
touching phones. `docs/HANDOVER.md` is the long-form handover, still current for
everything this session did not touch.

## State

Tree clean, `main` at `5466873`, **unpushed**. 63 SeedCore tests pass; the app
builds at Swift 6 with complete concurrency.

**Verified by looking, on an iPhone 17 Pro Max simulator:** plants across six
genomes and five ages. Leaves have pinnate venation, relief and a proper
base-to-tip ramp; surfaces carry normal and roughness maps off one bake; a
bounce light stops away-facing leaves crushing to black; spikes taper and
flower in a gradient; petals can break their colour (flamed / marbled /
brushed); every part wears its own age. The settings screen, including the
reset alert and its cancel.

**The Exchange screens have now been driven**, on a pair of simulators (17 Pro
Max and 17 Pro), and most of the meeting has been watched:

- The naming step. The button rewrites itself from MEET AS GARDENER to
  THAT'S ME the moment a name lands.
- `UnfurlingBackdrop(.pair)` over the exchange screen's own content, at last.
  It works and the pair reads as a pair.
- The place offer, and the system location prompt behind it.
- The search, and the timeout — *Nothing took*.
- Two simulators finding each other over Multipeer: *Ada is here*.
- The knock stand-in, and the peer being told: *Waiting for Ada. Felt that.
  They need to tap theirs too.*

**Still unwatched:** the last three seconds. Both phones touched, the crossing,
`PlantRevealView`, the passage with its provenance line, and the encounter
note. Nothing is wrong with it — see *The three-second window* below.

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
- `App/PeaceGarden/Exchange/PollenExchangeService.swift` — `canFeelTouch` and
  `standInForTouch()`, the simulator's substitute for the knock.
- `App/PeaceGarden/Views/ExchangeView.swift` — `awaitingTouch(peerName:)` picks
  between the stand-in and the real thing.
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
- **The simulator gets a stand-in for the knock, and the device never does.**
  `standInForTouch()` lives inside `#if targetEnvironment(simulator)`, so the
  shipping app keeps the line that the tap is a gesture rather than a button.
  A device always has an accelerometer, so `canFeelTouch` is true there and the
  screen is unchanged.

## The three-second window

`ExchangeProtocol.touchWindow` is 3.0 seconds, and both phones must be tapped
inside it. Two people touching phones together clear that easily. Driving two
simulators through a tool does not: a round trip is two to four seconds, so
the second stand-in tap regularly lands late and the crossing never advances.

That is what stopped the last three seconds being watched, rather than
anything wrong with the exchange. Worth deciding, next time: either widen the
window under `#if targetEnvironment(simulator)`, or arm the stand-in so a tap
counts from the moment the peer appears rather than from the tap itself.

## Next step

Watch the last three seconds: both phones touched, the crossing,
`PlantRevealView`, the passage with its provenance line, and the encounter
note. Decide the window question above first, or it will not be reachable.

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
- **The simulator's input connection drops**, and does it within a minute or
  two of steady driving. Relaunching the app with `simctl launch` fixed it
  several times and was quicker than anything else; re-`attach` and a full
  `shutdown`/`boot` both failed to bring one device back. Two simulators at
  once makes it worse. Expect to relaunch between steps rather than at the end.
- **The SEED / MEET / GARDEN row hides itself after six seconds**
  (`Chrome.controlsIdleTimeout`), and a tool round trip is two to four. So the
  usual sequence — tap the plant to reveal, screenshot to check, tap MEET —
  reliably misses, because the row has gone by the third step and the tap lands
  on the scene and reveals it again. Tap the plant and then MEET as two
  consecutive calls with nothing in between, and screenshot afterwards. The row
  sits at about y=870 in points on a 17 Pro Max; y=884 catches its bottom edge
  and works only sometimes.
- **New files need `xcodegen generate`.** The `.xcodeproj` is gitignored.
- **`UnfurlingBackdrop(.pair)` crosses the words while it unfurls.** The left
  crozier's spiral passes through *WHAT THEY WILL SEE* and the line under it on
  the naming screen, and it is worse on the smaller 17 Pro than on the Pro Max.
  It is clear of the text by the time the unfurl settles, so this is a few
  seconds rather than a permanent collision — but the naming screen is the one
  a person is stopped on longest. Left alone deliberately, 31 August.
