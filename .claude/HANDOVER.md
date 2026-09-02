# Peace Garden — handover 2 September 2026 (second session)

## Goal
Three things, all started from the previous handover's open list: the plant
forms in `docs/PLANT-FORMS.md`, the suite-brand item, and the localisation
scoped in `docs/LANGUAGES.md`. All three are done or in flight; the language
work grew from "one language, passages left in English" to eight banks and a
plan for twenty-five more.

## State
`main` clean. **72 SeedCore tests and 22 app tests pass** (was 63 and 12).
Device build clean for `generic/platform=iOS`.

- **Plant forms are live and were looked at on a simulator**: a raceme
  unchanged, a solitary orchid, a flat-topped corymb and a plume, all
  unmistakably different plants. Then the corymb again with the chrome in Dutch,
  which is the two halves of this session in one screen.
- **The interface speaks eight languages** — 191 strings, every one with a
  translator's comment.
- **Seven passage banks**, 349 to 380 passages each, every subtheme at ten or
  more. The English bank was filled from 300 to 369 to meet the same floor.
- **Spanish is the one that is not there.** Its interface is localised; its bank
  failed three times and was still being written. A Spanish phone therefore
  reads English lines and is told so, which is the `isBorrowed` path and is
  worth keeping working — every round-two language arrives that way.

### To add Spanish when it lands
The two halves are being written to
`…/scratchpad/spanish-a.swift` and `spanish-b.swift` as bare `Passage(...)`
lines. Wrap them in the same `extension Quotes { static let spanish: [Passage] = [ … ] }`
shape the other six use, then: a `case spanish = "es"` in `QuoteBank`, a line in
`passages`, move `"es-ES"` from `testALanguageWithNoBankBorrowsAndSaysSo` back
to `testFlemishReadsTheDutchBankAndNynorskTheNorwegianOne`, `xcodegen generate`,
and build. The tests will tell you the rest.

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
  happened is overlap with the English bank. All seven landed at **zero**.
- **Flemish reads the Dutch bank**, matched on language alone. It is a variety of
  Dutch, not a peer. Nynorsk reads the Norwegian bank for the same reason.
- **Informal address in all seven interfaces**, and Spanish avoids the
  second-person plural entirely rather than picking a hemisphere.
- **Sami and Frisian are out of round two; Greenlandic is in.** See
  `docs/LANGUAGES.md`, "Round two", for all three reasons.

## What this session found that nobody was looking for
- **The English bank was the thinnest of the eight**, with thirteen subthemes
  under the floor of ten its own scope set and `quietAsASound` at five. Filled to
  369, twelve everywhere. One of the new entries is the argument for having done
  all eight at once: *Danish keeps two words where English has one — stilhed is
  no sound at all, and tavshed is nobody speaking.* The Danish bank found that
  writing its own subtheme; English gained a passage about what it lacks.
- **The subtheme draw is 30/30/40 and was never written down.** Ten genus tails
  band 3/3/4, so a theme's third subtheme comes up 40% of the time. How often a
  reader meets a line twice is the draw probability over the number of lines, so
  a third subtheme wants about a third more passages than a first. Peace's
  `quietAsASound` was the worst case — five lines *and* a 30% draw — and its
  lines came round more than twice as often as anywhere else in the bank. It is
  a doc comment on `subtheme(of:in:)` now.
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
- **The Spanish bank failed three times, and the cause was reading, not
  writing.** Twice on an API output content filter, once on a 600-second stall,
  and every one of them died partway through `Quotes.swift` — which is 2,000+
  lines and grows with every bank. The fix is
  `tools/quotes/brief.py`-style extraction: pull the struct, the rules doc
  comment, the two enums and one sample passage per subtheme into a 228-line
  brief, tell the agent to read only that, and split the bank in half by theme
  so each agent writes 180 entries rather than 360. **Do this for all
  twenty-five round-two banks from the start** rather than discovering it
  again.
- **`tools/preview` has drifted further.** Its branch code is a faithful mirror,
  but its stems still lack `apexPoint`, the bloom lag and the foot dome.
  `SeedCore` is authoritative; the preview is for judging shape.
