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

Tree clean, `main` at `849f537`, **unpushed**. 63 SeedCore tests pass; the app
builds at Swift 6 with complete concurrency.

**Verified by looking, on an iPhone 17 Pro Max simulator:** plants across six
genomes and five ages. Leaves have pinnate venation, relief and a proper
base-to-tip ramp; surfaces carry normal and roughness maps off one bake; a
bounce light stops away-facing leaves crushing to black; spikes taper and
flower in a gradient; petals can break their colour (flamed / marbled /
brushed); every part wears its own age. The settings screen, including the
reset alert and its cancel.

**The Exchange screens have now been driven**, on a pair of simulators (17 Pro
Max and 17 Pro), and a whole meeting has been watched. On the way in:

- The naming step. The button rewrites itself from MEET AS GARDENER to
  THAT'S ME the moment a name lands.
- `UnfurlingBackdrop(.pair)` over the exchange screen's own content, at last.
  It works and the pair reads as a pair.
- The place offer, and the system location prompt behind it.
- The search, and the timeout — *Nothing took*.
- Two simulators finding each other over Multipeer: *Ada is here*.
- The knock stand-in, and the peer being told: *Waiting for Ada. Felt that.
  They need to tap theirs too.*

**And the meeting has been watched end to end.** Both phones knocked, the
crossing, the child, the passage — *Cosmos is Greek kosmos, order and ornament
in one word* — its provenance line, and its seven days to bloom. Both phones
showed the same passage and the same child, computed separately with no server
between them, which is the claim the whole design rests on. Then the note: the
place suggested and already filled in, the coordinates kept because both had
asked for them, and the child landing in the garden attributed to Ada.

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
- `App/PeaceGarden/Views/PlantStageView.swift` — why the controls row is held
  open on a simulator.
- `App/PeaceGarden/Rendering/PlantThumbnail.swift` — `ThumbnailRenderer`, and
  the framing bug below.
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

## What it took to drive it

Two simulator-only affordances, both compiled out of any build that runs on a
phone. Neither changes what the app does; they only make it reachable.

- **The three-second window.** `ExchangeProtocol.touchWindow` is 3.0 seconds
  and a tool round trip is two to four, so the second stand-in tap always
  landed late. `touchesCountAsOneKnock` relaxes this side's acceptance on a
  simulator. The constant is untouched — it is protocol vocabulary and it
  compiles on Linux. One consequence: a simulator paired with a real phone
  will disagree about a slow pair of taps. Cross two of a kind.
- **The controls row.** It is revealed by a `UITapGestureRecognizer` on the
  SceneKit view, and injected taps do not reach that recogniser at all —
  SpringBoard takes them, SwiftUI buttons take them, that one does not. So the
  row was unreachable and Exchange with it. **This is the real root of the
  "taps open nothing" story**, which has now been diagnosed twice and wrongly
  once: the sheet does present, but the row that opens it could not be
  summoned. On a simulator the row is shown from the start and never hides.

## The garden grid, found by looking

`ThumbnailRenderer` framed each tile on the mesh in front of it, so a tile
zoomed all the way in on whatever was there and a newborn hybrid filled its
square as a wide dome on a stub — the mushroom again, made by the camera rather
than by the geometry. The stage has framed against
`PlantSceneBuilder.matureBounds(for:)` since the first mushroom was chased out;
that decision had never travelled to the grid.

Framing strictly on the mature bounds swaps one failure for its opposite: a
stage is nine hundred points tall and a tile is a hundred and fifty, so the
proportion that makes a seedling small and hopeful full-screen makes it a speck
low in an empty square. Both cases land on the plant you just grew with
somebody. So `referenceBounds` draws the mature box in toward the plant while
the plant would fill less than `smallestShareOfATile` (0.28) of its tile, and
leaves it alone above that. Scaling about the origin brings the camera's aim
down too, which is what stops a seedling sitting on the floor of its frame.

Checked across six plants aged 0, 1, 3, 7, 15 and 40 days: the newborn reads as
a shoot with room above it, and every older tile is unchanged.

## Next step

An App Clip, which the long-form handover calls the cheapest real improvement,
because it changes how the app spreads rather than what it does: a seed scanned
by somebody who has never installed anything, growing on their phone seconds
later. The AASA groundwork is done and verified, and Apple's CDN already holds
the file.

## Traps

- **A screenshot straight after a tap catches the screen before the sheet.**
  Wait about a second, or print from the action to be sure. This was blamed for
  the "taps open nothing" blocker and was only half of it — the other half, and
  the part that actually stopped three sessions, is that the controls row could
  not be summoned at all. See *What it took to drive it*.
- **To look at a garden across a whole life**, clone the record in `plants`
  with fresh `seed` values and `birth` backdated by 0, 1, 3, 7, 15 and 40 days.
  That is what caught the tile framing, and no single-plant garden would have.
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
