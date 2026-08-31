# Peace Garden — handover 31 August 2026

Longer than it should be, because the session covered four unrelated things: a
typography finding, the passage architecture, 204 passages, and the whole
location feature. The reasoning lives in the two design documents rather than
here.

## Goal

Phase 1 of an iPhone/iPad app: a plant grown from a seed drawn once, and two
people crossing seeds by touching phones. `docs/HANDOVER.md` is the long-form
handover and still current for everything this session did not touch.

## State

Tree clean, `main` at `f2316a4`, **four commits unpushed**.

Verified by tooling: **63 SeedCore tests**, the app builds at Swift 6 with
complete concurrency, `tools/reference/passage_reference.py` passes and now runs
in CI, full build is 14 seconds.

Built and **never seen running**: all of it. The passage bank, the themed draw,
the figurative places, and the whole location feature. Also still unseen from
last session: the name field's underline and three serif headings.

- **Passage bank complete at 300**, thirty per theme. A pair's theme is fixed
  forever; the line within it is new every meeting.
- **Location feature complete.** Standing switch in Seed, one-time offer on Meet,
  consent flag on the card, coordinates shown as numbers and tappable to a map,
  and "Tell it differently" for editing a kept plant afterwards.
- **`docs/TYPE.md`** holds the second-serif-voice finding, parked until it can be
  checked against the brand guidelines below.

## Reference

**The design document**, from Claude Design:
https://claude.ai/design/p/c162a8a5-fb14-40ae-8234-bdc2a12f9512?via=share

Open it in a browser; it returns 403 to a plain fetch, so a session cannot read
it without Marcus. It is the counterpart to `docs/BRAND.md` (the mark and its
construction) and `design/*.dc.html` (the visual language canvas). `docs/TYPE.md`
ends with five explicit questions, and the first job with this document is to see
which of them it already answers.

## Files

- `App/PeaceGarden/Views/Quotes.swift` — the 300 passages, the ten themes and
  their four-dimensional positions, and the two-stage draw.
- `App/PeaceGarden/Views/Places.swift` — forty figurative places. `Draw.swift` —
  the shared fold both use.
- `App/PeaceGarden/Exchange/PlaceKeeping.swift` — the location switch, permission
  and single reading. `PollenExchangeService.swift:89` starts it, `:285` is the
  one gate that discards a reading the other person did not agree to.
- `Packages/SeedCore/Sources/SeedCore/Genome/Pollination.swift` — `pairID` and
  `pairUnit`, the counterpart to `encounterID`.
- `tools/reference/passage_reference.py` — the test target `App/` does not have.
- `docs/PLACE.md`, `docs/TYPE.md` — the reasoning, written down.

## Decisions made

- **Told versus inherited.** A seed is never stamped. Location and display name
  are things the parents chose to say, so they live on `EncounterNote` and are
  editable forever; the seed, lineage and birthday are not reachable from any
  editing screen. Do not move either onto the genome.
- **A coordinate never crosses the air.** Only a consent flag does. Each phone
  stamps its own reading. Both-or-neither is a privacy rule, not a simplification:
  two people at one meeting stand in the same place, so recording mine records
  yours. An earlier build sent it on `confirm` and was replaced.
- **Themes are not a list or a ring.** Ten points in four dimensions, and each
  pair settles which single dimension defines them. Matching on all four at once
  was tried and gave 150 of 400 pairings the same central theme.
- **Thirty per theme, flat, not weighted by popularity.** A pair's repeat odds
  depend only on their own theme's size.
- **The bank stays in Swift.** The compile-time argument for a JSON resource was
  measured and is wrong.
- **No reverse geocoding**, because the app makes no network request at all.

## Next step

Push the four commits, then reach Exchange **by hand on a device** and watch a
real crossing: the passage, its provenance line, the suggested place, and the
place offer. Everything else is blocked behind that.

## Traps

- **Injected taps on the `SEED · MEET · GARDEN` row open nothing**, though they
  register as gesture actions. Coordinates are right; do not re-derive them.
- **New files need `xcodegen generate`** before they build. The `.xcodeproj` is
  gitignored and generated.
- **Screenshot round trips take seconds**, so a settled screen after a tap does
  not mean an animation was skipped. `recordVideo` timelines are not real time.
  `timeout` is not installed here.
