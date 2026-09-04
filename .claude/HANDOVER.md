# Peace Garden — handover 3 September 2026

*This session ran two unrelated strands: a site test roster, then the whole
taxonomy build. They did not interfere, but a fresh session should pick one.*

## Goal

Make the plant names a real classification a botanist could key out
(`docs/TAXONOMY.md`), and give a mature plant something to do. Both done.

## State

`round-two` at `5d3a235`, green, **still not merged into `main`** — the branch
has diverged a long way and merging is an outstanding decision Marcus has agreed
to but which has not happened.

**Verified.** 96 SeedCore tests, 23 app tests, all three Python CI checks. Built
and driven on an iPhone 17 Pro Max simulator: first light → planting → a mature
*Wynula latifolia*. Renders looked at for the merosity couplets, the vegetative
spread, and one full flush cycle.

- **The genus is read off the flower.** 12 families × 2 merosity classes → the
  24 frozen heads. Same root ⇒ same floral plan and petal count. Head → theme is
  untouched, so no passage anyone has seen has moved.
- **The epithet is a checked claim**, with Latin grammar and gender agreement.
  57 distinct epithets, commonest at 6%, ~1 in 50 *vulgaris*.
- **Vegetative ranges widened**, floral held tight — 17 ranges, no floral range
  touched.
- **Flushes**: a wave of open flowers travelling up the stem over 1–4 weeks.
- **43 test gardeners** at `/t` on the site, word `peace`.
- **The preview port is under CI**, and names nothing: its naming was three
  months stale and nothing rendered it, so it was deleted rather than ported.

**Known gap, not closed.** The port computes in `double` where Swift computes
several values in `Float`. The rounding rule now matches; the precision does
not. It does not bite on the current 15 vectors, but it is a second way those
lines could disagree.

**Unverified.** The flush has not been seen *in the app* — only in the Python
port. Its amplitude (a trough at 45%) is visible on the crown but subtle on
small-flowered plants; whether to deepen it wants looking at on a simulator.

## Files

- `Packages/SeedCore/Sources/SeedCore/Genome/PlantName.swift:60` — the root
  table. The pairings, and why `Cal`/`Quin` swapped.
- `Packages/SeedCore/Sources/SeedCore/Genome/Epithet.swift` — the vocabulary,
  the rarity rule, and `Rate`, a table of **measured** base rates.
- `Packages/SeedCore/Sources/SeedCore/Growth/GrowthModel.swift` — `flush`,
  `flushDepth`.
- `Packages/SeedCore/Sources/SeedCore/Morphology/PlantBuilder.swift` —
  `flushFactor`, the travelling wave.
- `docs/TAXONOMY.md` — the design and everything the renders changed.
- `docs/FOR-REVIEW.md` — **two decisions still waiting on Marcus**: the six
  prose strings and the ten area names.
- `Server/assets/js/testers.js`, `Server/t` — the roster. No accounts exist.

## Decisions made

- **The archetype is a family, not a genus.** Genera in a family share a root
  and differ in their endings (*Helianthus*, *Helianthemum*). This is what let
  gender attach to the written genus.
- **Notability is rarity**: of the true things, say the one fewest relatives
  could have said. Scoring markings and measurements on separate scales gave
  *variegata* a third of the garden.
- **A flush never closes completely.** A bare plant would read as a meeting
  having faded. The trough is a bud at 45%. This is about meaning, not botany.
- **`-ynth` is masculine, the other nine endings feminine.**
- **`Cal` and `Quin` swapped**: *Calaceae* is the umbel, *Quinaceae* the bell.
  The Campanulaceae echo that justified the old arrangement was false —
  *Campanula* is from *campana*, not *kalos*.
- **Language codes, not country codes**, in tester names (`Test-DA-Gartner`).

## Next step

Run the app on a simulator and watch a mature plant across a flush cycle — wind
the garden on from Settings → Testing. Decide whether the 45% trough is enough
to read as change. Then merge `round-two` into `main`.

## Traps

- **`cd` persists between Bash calls.** Always pass absolute `--package-path`.
- **`tools/preview/plant_model.py` is in CI now** — `check_port.py` against a
  committed `tools/preview/vectors.json`, which a Swift recorder writes. If
  SeedCore changes on purpose, re-record with
  `PEACE_GARDEN_RECORD_VECTORS=1 swift test --package-path … --filter PortVectorTests`,
  then bring the port along. Older notes in `docs/TAXONOMY.md` still say it is
  not in CI; they are dated journal entries and were left alone.
- **Render a night-opening plant at its own peak hour.** At 13:00 the diurnal
  factor damps it to a third and every flower is a shut bud — which looks
  exactly like a feature that is not working.
- **Simulator taps need real coordinates.** Screenshots come back scaled; take a
  raw `xcrun simctl io … screenshot` and divide by 3.
- **Thresholds against a drawn trait must be measured, not guessed.** Three
  epithets were unreachable because petal brightness never leaves 0.45–0.82.
- **Swift `.rounded()` is half-away-from-zero; Python `round()` is half-to-even.**
  They disagreed on `stem.nodeCount` for about one plant in 27. Fixed in five
  places in the port, with three vectors chosen specifically to cover it.
