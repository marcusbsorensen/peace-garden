# Peace Garden — handover 2 September 2026 (second session)

## Goal
Three things, all started from the previous handover's open list: the plant
forms in `docs/PLANT-FORMS.md`, the suite-brand item, and the localisation
scoped in `docs/LANGUAGES.md`. All three are done or in flight; the language
work grew from "one language, passages left in English" to eight banks and a
plan for twenty-five more.

## State
`main` at `c905c04`, plus uncommitted wiring — see **In flight** below.

- **72 SeedCore tests** (was 63) and **12 app tests** pass. Device build clean
  for `generic/platform=iOS`.
- **Plant forms are live and were looked at on a simulator**: a raceme
  unchanged, a solitary orchid, a flat-topped corymb and a plume, all
  unmistakably different plants.
- **The interface localisation is merged** — eight languages, 191 strings, every
  one with a translator's comment.
- **Six passage banks are committed**; the seventh and the English fill-out were
  still running when this was written.

### In flight when this was written
Two background agents, and the tree does not build until the first lands:

1. **Spanish bank** → `App/PeaceGarden/Views/Quotes+Spanish.swift`.
   `QuoteBanks.swift` already refers to `Quotes.spanish`, so the app target does
   not compile until that file exists. Spanish failed twice on an API output
   content filter before being told to append a theme at a time.
2. **English bank fill-out** → editing `Quotes.swift` in place, adding 69
   passages to bring every subtheme to twelve.

Uncommitted and finished: `QuoteBanks.swift`, `QuoteBankTests.swift`, the
`bySubtheme` change and `passage(subtheme:childSeed:from:)` in `Quotes.swift`,
the borrowed-language line in `PlantRevealView.swift`, and the round-two section
of `docs/LANGUAGES.md`.

**To finish**: wait for both, `xcodegen generate`, build for the simulator *and*
`generic/platform=iOS`, run both test suites, then commit. `QuoteBankTests`
holds English at a floor of 5 as a recorded exception — **remove that exception
once the fill-out lands** and give English the same floor as everything else.

## Files
- `docs/PLANT-FORMS.md` — now the record rather than the spec, including three
  places the build departed from it and why.
- `docs/LANGUAGES.md` — rewritten by the localisation agent, then extended with
  what the banks found and the round-two list. It is long and it is the map.
- `App/PeaceGarden/Views/QuoteBanks.swift` — which bank a phone reads, and what
  two phones on different banks still agree on.
- `App/PeaceGarden/Views/Localised.swift` — what moved out of SeedCore, plus the
  stage, archetype and growth captions.
- `tools/preview/archetypes.py` — twelve archetypes side by side. The acceptance
  test for the forms work.
- `tools/type/measure.swift`, `tools/strings/sync.sh` — the type review, and the
  step `xcodebuild` leaves out.

## Decisions made
- **The enum is `Inflorescence`, not `Form`.** `Genome.Form` was taken, and
  these three cases are inflorescence types in the botany the file borrows from.
- **A solitary bloom is 1.7×, not the spec's 2.2.** Three archetypes were
  already inflating `petalLengthScale` to get a big flower; at 2.2 on top a
  poppy came out a satellite dish. Those three are 1.0 now and the form carries
  the size. Thistle is 2.4 because its petals are bracts.
- **Two phones no longer agree on the passage, and should not.** A shared line
  would force the banks to be parallel translations, which is the one thing they
  must not be. **The theme and the subtheme still agree** — both derived, both
  language-neutral — so a pair holds the character of the passage in common
  rather than its words. `QuoteBank`'s doc comment is the argument.
- **A bank is a commission, not a translation**, and the measure of whether that
  happened is overlap with the English bank. All six landed at **zero**.
- **Flemish reads the Dutch bank**, matched on language alone. It is a variety of
  Dutch, not a peer. Nynorsk reads the Norwegian bank for the same reason.
- **Informal address in all seven interfaces**, and Spanish avoids the
  second-person plural entirely rather than picking a hemisphere.
- **Sami and Frisian are out of round two; Greenlandic is in.** See
  `docs/LANGUAGES.md`, "Round two", for all three reasons.

## What this session found that nobody was looking for
- **The English bank is the thinnest of the eight.** It has 300 passages,
  thirteen subthemes under the floor of ten that its own scope set, and
  `quietAsASound` at five. Every commissioned bank came in at 349–380 with a
  floor of eleven. Marcus asked for it to be filled next, and that is the agent
  running now.
- **131 of the 191 interface strings were never extractable.** Every chrome
  helper took a `String`, so a literal handed to `QuietButton(title:)` was drawn
  as written and looked up nowhere. `xcodebuild` writes `.stringsdata` and stops
  — only Xcode merges them, which is what `tools/strings/sync.sh` is.
- **Four of seven banks independently named `quietAsASound` as their hardest.**
  That is evidence about the subtheme rather than about any language.

## Next step
Finish the wiring above, then round two: twenty-five languages, briefed with
what `docs/LANGUAGES.md` § "What round one learned" records. After that, the
previous handover's next step still stands — an App Clip, because it changes how
the app spreads rather than what it does.

## Traps
Everything in the previous handover still applies. Added this session:

- **A bank file mid-write does not parse, and `xcodegen` will happily add it to
  the target.** Check `swiftc -parse` on every `Quotes+*.swift` before
  regenerating, or the build fails somewhere confusing.
- **`simctl install` wants the `.app` path, not `-showBuildSettings` output.**
  `BUILT_PRODUCTS_DIR` and `FULL_PRODUCT_NAME` pasted together gives you a path
  ending in `YES`.
- **To see a chosen archetype, write the seed rather than reinstalling.** Put a
  hex seed into `Library/Application Support/PeaceGarden/garden.json` in the
  app's data container and relaunch; `xcrun simctl spawn <sim> defaults write
  app.peacegarden developer.clockShift -float 3456000` winds it to maturity.
  Reinstalling until the draw obliges takes twenty times as long.
- **A long single-shot generation can trip an API output content filter.** It
  killed Spanish twice with no useful error. Appending in pieces fixed it.
- **`tools/preview` has drifted further.** Its branch code is a faithful mirror,
  but its stems still lack `apexPoint`, the bloom lag and the foot dome.
  `SeedCore` is authoritative; the preview is for judging shape.
