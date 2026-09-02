# Peace Garden — handover 2 September 2026

## Goal
Phase 1 — a plant grown from a seed created once, and two people crossing seeds
by touching phones — is built and watched working. This session was a round of
UI feedback from Marcus's own phone, plus tying the passage bank to plant names.

## State
Tree clean, `main` at `660ee7d`, pushed. **63 SeedCore tests and 12 app tests
pass** (`App/PeaceGardenTests` is new — the app target had none before).
Debug build of `660ee7d` installed on **MBS iPhone**; dev provisioning lasts
seven days, then reinstall.

Verified on a simulator: the whole stage redesign, the seed and wind screens,
the imaginary meeting end to end, the garden grid, Settings.

**Not verified, needs a thumb:**
- The long press on the stage marks. Injected presses are not sustained on a
  simulator — the same limit that makes `HoldToConfirm` untestable there.
- Whether Messages/Mail/WhatsApp now list in the share sheet. This simulator has
  exactly one share extension (Reminders), so it could never show them.

## Files
- `docs/NAMES-AND-THEMES.md` — genus head ⇄ theme, genus ending ⇄ subtheme. Built.
- `docs/LANGUAGES.md` — localisation scope. **Nothing built.**
- `docs/PLANT-FORMS.md` — three plant forms. Build spec, **nothing started.**
- `docs/CHROME-AND-SETTINGS.md` — built; now the record rather than the spec.
- `App/PeaceGarden/Views/PlantStageView.swift` — all chrome at the foot now.
- `App/PeaceGarden/Views/Glyphs.swift` — the seven new marks.
- `App/PeaceGarden/Views/DeveloperControls.swift` — `#if DEBUG` clock + imaginary gardener.

## Decisions made
- **`PlantName.genusHeads` and `genusTails` are frozen.** `GeneSource.pick`
  indexes by `unit(label) * count`, so a twenty-fifth syllable renames every
  plant on every phone. Themes were fitted to the 24, not the other way round.
- **Theme is derived from the name, never the reverse.** A name is stored; a
  theme is not.
- Four themes take three heads and six take two, so Beginnings is 12.5% against
  Peace's 8.3%. Recorded, not corrected — a weighted draw would break the point.
- **The chrome is one band at the foot**: name, stage, four marks. Only the mark
  you touched unrolls (four words at once overflow a 402pt phone by ~40).
- **A short URL is impossible and should be.** The payload rides in the fragment
  so it never reaches a server; shortening needs one.
- On screen it is *create*, in the code it is *draw*. Both deliberate.
- Contrast: `muted` 0.72, `faint` 0.56, `sectionLabel` 0.80, `hairline` 0.24.

## Next step
Implement `docs/PLANT-FORMS.md` — every plant is still one unbranched stem, and
four of the twelve archetype names are not true. It is self-contained.

## Traps
- **New files need `xcodegen generate`.** The `.xcodeproj` is gitignored.
- **`simctl install` over a running app does not reload it.** Terminate first,
  or you will screenshot the old binary and redraw a glyph that was already fine.
- **Injected taps never reach the SceneKit tap recogniser.** `PlantDetailView`'s
  details are therefore unreachable on a simulator; the stage row is held open.
- **Build for `generic/platform=iOS` before claiming a device install works.**
  A simulator-only `#if` compiled fine and failed on the phone, and the install
  silently deposited the previous binary.
- Screenshot→point scale on the iPhone 17 Pro panel is **0.4365**, not 402/921
  on the height axis. Wrong y sent three taps into empty space.
