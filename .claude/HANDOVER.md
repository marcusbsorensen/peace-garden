# Peace Garden — handover 31 August 2026

## Goal

Phase 1 of an iPhone/iPad app: a plant grown from a seed drawn once, and two
people crossing seeds by touching phones. Working the open list in
`docs/HANDOVER.md` — the long-form handover, current, worth reading for depth.

## State

Eleven commits, all pushed, tree clean, `main` at `69708e8`.

Seen and right: the **seed opening** (six seconds on the day a seed is sown),
the **pool of light following the plant**, **first light** with its name field
gone, the **button edges**. Marcus confirmed the **exchange screen and its
fronds** himself. Checked by tooling: **Swift 6 + complete concurrency**, 53
tests, **CI green**, and the **AASA file live** — direct 200,
`application/json`, no redirect hops, already on Apple's CDN.

Built but **never seen**: the name field's new **underline**, and the three
**serif headings** just changed (`IncomingSeedView`, `GardenView`,
`EncounterNoteView`). They compile; nobody has looked at them.

## Files

- `App/PeaceGarden/Views/Chrome.swift` — `pressable()` (the button edge),
  `underlining()` (the rule as a field's underline), `SproutingRule.height`.
- `App/PeaceGarden/Rendering/SeedHusk.swift` — the seed that opens, and
  `App/PeaceGarden/Views/GerminationView.swift`, which drives it. Both new.
- `App/PeaceGarden/Rendering/PlantSceneView.swift:11` — `Arrival`, and the
  camera override in `applyFraming()`. `StageBackdrop.swift` — `presence`
  sizes the glow.

## Decisions made

- **The arrival's husk is app-side, not in SeedCore.** The core's husk is
  measured against the shoot — the mushroom fix — so it shrinks with it and
  never reads as a seed. Do not "fix" the core to suit the arrival.
- **The camera interpolates in ratio, not metres.** A straight lerp lurches.
- **`heightScale` is the plant's presence.** Nothing needs measuring.
- **`plantName` is for `genome.name.full` alone.** Four views wear it; grep
  before adding a fifth. **The repository is public**, which gives CI a runner.

## Next step

Marcus has Claude Design pulling the brand guidelines together from
`docs/BRAND.md`, `design/*.dc.html` and `Chrome.swift`. Hand it this finding: a
**second serif voice nobody has written down** — serif *non-italic*, inline
rather than a named style, on screen headings (`ExchangeView.swift:175,200`)
and every field typed into (`EncounterNoteView.swift:53,90`,
`SeedView.swift:54`), plus `PlantDetailView.swift:68`. Settle those, then apply.

## Traps

- **Injected taps on the `SEED · MEET · GARDEN` row open nothing**, though they
  register as gesture actions. The app is fine — Marcus reached that screen by
  hand — and the coordinates are right, so do not re-derive them. Anything
  behind that row has to be checked by asking him.
- **Screenshot round trips take seconds**, so a settled screen straight after a
  tap does not mean an animation was skipped — I "fixed" a non-existent bug on
  that basis. Record and profile instead.
- **`recordVideo` timelines are not real time** and outlast the wait; profile
  to find the moment. **Controls toggle**, so a reveal tap on a visible row
  turns it off. `timeout` is not installed here.
