# Peace Garden — handover 1 September 2026

> Twelve lines over length, after two passes at trimming. The session ran three
> ways at once — a device install, a round of UI feedback, and scoping two new
> features — and the traps below are what it cost to learn. Cutting them would
> spend somebody else's afternoon to save a paragraph.

## Goal

Phase 1 — a plant grown from a seed drawn once, and two people crossing seeds by
touching phones — is built and has been watched working. Three workstreams are
specified and none is started.

## State

Tree clean, `main` at `5b0076a`, pushed. 63 SeedCore tests pass; builds at
Swift 6 with complete concurrency.

**Watched end to end on two simulators:** a whole meeting — discovery, the
knock, the crossing, both phones deriving the same child and the same passage
with no server, the note with the place suggested and coordinates logged
because both asked, and the child landing in the garden attributed to the other
gardener. Also the garden grid across six ages.

**Running on Marcus's iPhone 17 Pro**, device build of `e18e28f`. Dev
provisioning expires after seven days, then reinstall.

**Specified, not started:** the three workstreams below.

## Files

- `docs/CHROME-AND-SETTINGS.md` — build spec, with copy. **Start here.**
- `docs/SEEDS-ON-THE-WIND.md` — design above the rule, build spec below it.
- `docs/BOTANICAL-GARDEN.md` — phase 2, scope only.
- `Views/SettingsView.swift` rewritten; `Views/PlantStageView.swift` takes the
  cog; `Views/SeedView.swift` loses Settings and gains the wind door;
  `Views/Chrome.swift` holds `chromeLabel` and `SproutingRule`.
- `Views/SeedOfferView.swift`, `Views/IncomingSeedView.swift` — the wind round
  trip. Already working; only needs a door.

## Decisions made

- **The simulator gets affordances the phone never does** — knock stand-in,
  relaxed touch window, held-open controls row, all
  `#if targetEnvironment(simulator)`, so the shipping app keeps the line that
  the tap is a gesture rather than a button.
- **One offer on the wind at a time, no daily cap.** A display rule and never a
  cryptographic one: a reply arriving three weeks later must still work, which
  is the guarantee the whole link design was built around.
- **Keep becomes log.** *Keep* can mean keep away, and this is the one control
  where a wrong guess is not undoable.
- **Settings explains once.** The reset rows are held for three seconds rather
  than tapped, the alert goes, and each consequence appears only while its
  button is filling — about as long as the sentence takes to read. A hold
  cannot be done by reflex and can be abandoned by letting go.
- **Colour enters the chrome only where something is lost** — crimson, ochre
  and pink-gold on the three resets. It stays rare so it keeps meaning.
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
  controls row; SpringBoard and SwiftUI buttons take them. This is the real
  root of the old "taps open nothing" story, wrongly closed twice. The row is
  held open on simulators now, so it no longer bites.
- **A garden of one plant shows nothing.** Clone `plants` in `garden.json` with
  fresh seeds and births backdated 0/1/3/7/15/40 days. That is what caught the
  tile framing.
- **New files need `xcodegen generate`.** The `.xcodeproj` is gitignored.
- **`tools/preview/` is a port that drifts**, `SeedCore` is authoritative. The
  web renderer must not become a third hand-maintained copy of the geometry
  without CI comparing them, the way `tools/reference/` already is.
