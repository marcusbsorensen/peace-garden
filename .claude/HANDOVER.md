# Peace Garden — handover 31 August 2026

## Goal

Phase 1 of an iPhone/iPad app: a plant grown from a seed drawn once, and two
people crossing seeds by touching phones. Working the open list in
`docs/HANDOVER.md` — the project's long-form handover, current, and worth
reading for depth. This is the session layer on top of it.

## State

Eight commits, all pushed, tree clean, `main` at `168d709`.

Verified: **the seed opening** (six seconds on the day a seed is sown, recorded
and stepped through frame by frame); **the pool of light following the plant**;
**the name moved to the first meeting**, with first light's button brought up to
its rule; **Swift 6 + complete concurrency**, app and core, 53 tests; **CI green**
for the first time, which the repo going public fixed; **AASA live** — direct
200, `application/json`, no redirect hops, matching `project.yml`, and already
on Apple's CDN.

Unverified: the whole exchange screen — the naming step,
`UnfurlingBackdrop(.pair)` over real content, and the first-meeting passage.

## Files

- `App/PeaceGarden/Rendering/SeedHusk.swift` — the seed that opens. New.
- `App/PeaceGarden/Views/GerminationView.swift` — drives the six seconds. New.
- `App/PeaceGarden/Rendering/PlantSceneView.swift:11` — `Arrival`, plus the
  camera override in `applyFraming()`.
- `App/PeaceGarden/Rendering/StageBackdrop.swift` — `presence` sizes the glow.
- `App/PeaceGarden/Views/ExchangeView.swift` — `nameYourself`, gated on
  `model.hasChosenName`.

## Decisions made

- **The arrival's husk is app-side, not in SeedCore.** The core's husk is
  measured against the shoot — the mushroom fix — so it shrinks with it and
  never reads as a seed. Do not "fix" the core to suit the arrival.
- **The camera interpolates in ratio, not metres.** A straight lerp lurches.
- **`heightScale` is the plant's presence.** Nothing needs measuring.
- **The repository is public.** That is what gives CI its runner.

## Next step

Settle whether the exchange screen is reachable. Simulator
`45D11C4E-AA8C-42EE-BF2C-6021A76FDAD0` is in exactly the right state — identity
planted, `displayName` empty, no plants kept. Tap the plant, then `MEET`. A
naming screen means the app is fine and it was tap injection; nothing happening
means a real bug in `PlantStageView`'s `fullScreenCover`. Naming yourself
destroys that state; delete and reinstall to get it back.

## Traps

- **Injected taps on the `SEED · MEET · GARDEN` row open nothing**, though they
  register as gesture actions. The coordinates are right; do not re-derive.
- **Screenshot round trips take seconds**, so a settled screen straight after a
  tap does not mean an animation was skipped — I "fixed" a non-existent bug on
  that basis. Record and profile instead.
- **`recordVideo` timelines are not real time** and outlast the wait; profile
  to find the moment. **Controls toggle**, so a reveal tap on an
  already-visible row turns it off. `timeout` is not installed here.
