# Arranging the Garden screen — handover 17 September 2026

## Goal

Turn the app's Garden screen from a grid of tiles into a place: a floating
square plot in isometric that the person arranges their own plants on, with a
choice of ground and a sun and moon going round it.

## State

**Done and verified.** `Spot`, `Template`, `Bed`, `Garden.beds` in SeedCore —
106 tests, from 97. The five templates in the app — 35 app tests, from 28. Both
suites green locally; CI green on `eed4ae6`. `main` is pushed and clean.

**Done, not built into the app.** The whole visual design, as an interactive
Design canvas: https://claude.ai/artifact/JtRewHDMGQJJTPnKvS5Tru — eight worlds,
drag a plant, hour slider, orbiting sun and moon with cast shadows, real moon
phase. Everything drawn there is real: actual crossings, geometry from
`tools/preview`, names and `opensByDay` from SeedCore. The render scripts are in
the session scratchpad and are **not in the repo**; rebuilding them is a few
hours if they are wanted.

**Not started.** The Garden screen itself. Nothing in `App/PeaceGarden/Views/`
has changed.

**Unchanged and still outstanding** — the language work from the previous
handover: 41 named maps, one language read. `Server/strings/da.json`'s `read`
block still needs the Danish reader's name and date. See
`docs/COMMISSIONING-THE-READS.md`.

## Files

| | |
| --- | --- |
| `docs/ARRANGING.md` | The whole design. Read this first; everything below is in it. |
| `Packages/SeedCore/Sources/SeedCore/Persistence/Arranging.swift` | `Spot`, `Template`, `Bed`, and `Garden.plotSide`. |
| `Packages/SeedCore/Sources/SeedCore/Persistence/GardenModels.swift:141` | `beds`, optional so nothing migrates. |
| `App/PeaceGarden/Arranging/Arrangement.swift` | The five templates. `theme(of:)` at :76 is the one that bites. |
| `App/PeaceGardenTests/ArrangementTests.swift` | Holds every template to placing from the seed, not from a list. |
| `App/PeaceGarden/Views/GardenView.swift` | The grid being replaced. Its comment at :100 is the open question. |

## Decisions made

- **An arrangement is *told*, not inherited** (`docs/PLACE.md`'s words). Local,
  never in `ExchangePayload`, cannot reach a seed. So layouts never sync.
- **A floating square plot in isometric.** A sphere was built and dropped: no
  edge is the cleanest answer, but it hid half the garden and made every
  cultivated world fight its surface.
- **A `Spot` is metres from the centre.** The plot grows as √(hybrid count), so
  a fraction would spread the garden apart at every new meeting.
- **`placed` is keyed by `uuidString`** — `JSONEncoder` writes a non-String-keyed
  dictionary as a flat array, which is unreadable outside Swift.
- **The worlds are chosen by looking and are never named.** A named world is 42
  translations; the ten area names already cost 420.
- **Night and day reads `tempo.opensByDay`, never the genus head.**
- **The plot pinches to zoom and two-finger rotates**, in ninety-degree steps.
  Rotation is free for the ground (it is computed) and expensive for the plants
  (they are sprites from one camera) — that asymmetry is the whole question.
- **Long press to lift a plant, then drag.** One finger cannot both move a plant
  and pan the plot; every plant is a meeting, so an accidental nudge is a worse
  failure than waiting a beat. Haptic on the lift.

## Next step

Build the Garden screen against `Arrangement.spots(for:template:plotSide:mine:)`,
starting with the plot and the plants at the right scale — no terrain, no orbit.
`docs/ARRANGING.md` §*How it is drawn* has the two options; take the sprite one.
Gestures come after that, not with it — §*Turning it* has the design.

## Traps

- **`Quotes.theme(of:)` is wrong for arranging.** It builds the genome `.minted`;
  a hybrid's traits come from its parents. All 14 test crossings get a different
  genus head. Use `Arrangement.theme(of:)`.
- **Anything derived from a plant's index reshuffles the garden** when a plant is
  added. Derive from the seed. `Meetings` is the one exemption.
- **`swift test --package-path Packages/SeedCore` takes ~150 s.** App tests:
  `xcodegen generate` then `xcodebuild test -scheme PeaceGarden -destination
  'platform=iOS Simulator,name=iPhone 17 Pro'`.
- Older traps — simulator, deploy, `AREA_KEYS`, the mesh pin — are in
  `docs/HANDOVER.md` and still apply.
