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

Tree clean. Pushed through `d9de83e`; six commits since then are local — the
rendering work, the settings screen and the shared-garden mock-ups.

Verified by tooling: **63 SeedCore tests**, the app builds at Swift 6 with
complete concurrency, `tools/reference/passage_reference.py` passes and now runs
in CI, full build is 14 seconds.

The plants no longer look like placeholder geometry. Leaves have venation and
relief, surfaces carry normal and roughness maps, a spike tapers and flowers in
a gradient, petals can break their colour, and everything wears its own age.
Every one of those was tuned against renders on a simulator rather than against
judgement, and each one had at least one confident guess proved wrong by
looking. See the commits from `478f453` onward.

`design/garden/` holds five mock-ups for the phase-2 shared garden, published
as a canvas.

Built and **never seen running**: the exchange screens. The passage bank, the themed draw,
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

Reach Exchange and watch a real crossing: the passage, its provenance line, the
suggested place, and the place offer. This is reachable from the harness — see
Traps — so it no longer needs a second physical device to make progress on the
screen itself, only on the tap-to-meet handshake.

Two open questions worth answering before more is built on them:

- A public plant page belongs to two people. Does it name both gardeners, or
  only the one who chose to share it? `PHASES.md` says the encounter note is
  each person's own, which points at the latter.
- Self-shadowing does not work while every blade is a single double-sided
  surface with no thickness. Worth revisiting only alongside giving blades a
  thickness — see the comment in `PlantSceneBuilder.makeScene`.

## Traps

- **The `SEED · MEET · GARDEN` row works. It always did.** Two sessions recorded
  it as a blocker and it was screenshot timing: the sheet animates in and a
  screenshot taken straight after the tap catches the screen before it. Proved
  by printing from the button action and from the sheet's content builder —
  both fire, and a screenshot a moment later shows the sheet. Nothing about
  reaching Exchange is blocked. **Wait about a second after any tap that
  presents something before believing a screenshot.**
- **New files need `xcodegen generate`** before they build. The `.xcodeproj` is
  gitignored and generated.
- **Screenshot round trips take seconds**, so a settled screen after a tap does
  not mean an animation was skipped. `recordVideo` timelines are not real time.
  `timeout` is not installed here.
