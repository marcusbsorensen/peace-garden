# Peace Garden — handover 1 September 2026

## Goal

Phase 1: a plant grown from a seed drawn once, and two people crossing seeds by
touching phones. Phase 1 is built and has been watched working. Three
workstreams are now specified and none is started.

## State

Tree clean, `main` at `66c9e81`, everything pushed. 63 SeedCore tests pass; the
app builds at Swift 6 with complete concurrency.

**Watched working, end to end, on two simulators:** a whole meeting — discovery,
the knock, the crossing, both phones deriving the same child and the same
passage with no server between them, the note with the place suggested and the
coordinates logged because both asked, and the child landing in the garden
attributed to the other gardener. Also the garden grid across six ages.

**Running on Marcus's own iPhone 17 Pro**, device build of `e18e28f`, signed
Apple Development. Dev provisioning expires after seven days, then reinstall.

**Specified, not started:** all three workstreams below. The specs carry the
shipping copy and the reasoning, and are meant to be built from directly.

## Files

- `docs/CHROME-AND-SETTINGS.md` — build spec, with copy. **Start here.**
- `docs/SEEDS-ON-THE-WIND.md` — design above the rule, build spec below it.
- `docs/BOTANICAL-GARDEN.md` — phase 2, scope only.
- `App/PeaceGarden/Views/SettingsView.swift` — the screen being rewritten.
- `App/PeaceGarden/Views/PlantStageView.swift` — controls row; the cog goes here.
- `App/PeaceGarden/Views/SeedView.swift` — loses Settings, gains the wind door.
- `App/PeaceGarden/Views/Chrome.swift` — `chromeLabel`, `SproutingRule`, `QuietButton`.
- `App/PeaceGarden/Views/SeedOfferView.swift`, `IncomingSeedView.swift` — the wind
  round trip, QR and share, already working and only needing a door.
- `App/PeaceGarden/Exchange/PollenExchangeService.swift` — `canFeelTouch`,
  `standInForTouch()`, `touchesCountAsOneKnock`.

## Decisions made

- **The simulator gets affordances the phone never does** — the knock stand-in,
  the relaxed touch window, the held-open controls row. All
  `#if targetEnvironment(simulator)`, so the shipping app keeps the line that
  the tap is a gesture rather than a button.
- **One offer on the wind at a time, no daily cap.** A display rule and never a
  cryptographic one: a reply arriving three weeks later must still work, which
  is the guarantee the whole link design was built around.
- **Keep becomes log.** *Keep* can mean keep away, and this is the one control
  where a wrong guess is not undoable.
- **Settings explains once.** The reset rows lose their detail lines, because
  the confirmation alert says the same thing at the moment somebody decides.
- **The garden map is derived, not invented.** `Quotes.Theme` already places ten
  themes in a four-dimensional space; project it rather than drawing by feel.
- **A published note never carries the coordinate.**

## Next step

Implement `docs/CHROME-AND-SETTINGS.md`. It is self-contained.

## Traps

- **Simulator input dies within a minute or two** of steady driving. `simctl
  launch` to relaunch the app cures it; re-attach and a full reboot did not.
  Two simulators at once makes it worse.
- **Injected taps never reach the SceneKit tap recogniser** that reveals the
  controls row — SpringBoard and SwiftUI buttons take them, that one does not.
  This is the real root of the old "taps open nothing" story, wrongly closed
  twice. The row is held open on simulators now, so it no longer bites.
- **A garden of one plant shows nothing.** Clone `plants` in `garden.json` with
  fresh seeds and births backdated 0/1/3/7/15/40 days. That is what caught the
  tile framing.
- **New files need `xcodegen generate`.** The `.xcodeproj` is gitignored.
- **`tools/preview/` is a port that drifts**, `SeedCore` is authoritative. Do
  not add a third hand-maintained copy of the geometry for the web renderer
  without CI comparing them, the way `tools/reference/` already is.
