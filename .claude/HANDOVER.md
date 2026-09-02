# Peace Garden — handover 2 September 2026

*This session ran four threads at once — marks, banks, website, a CI fix. They
were independent, and it worked, but a fresh session should pick one.*

## Goal
Finish the three items the previous handover left open: the four stage-row
marks, wave two of the passage banks, and what `docs/WEBSITE.md` asks of the
app. All three are done. The website itself was started on top of that.

## State
`main` at `f80f48b`, clean.

**Verified.** 72 SeedCore tests, 23 app tests, all three CI jobs green — CI was
red at `e806de4` when this session opened and is fixed. Device and simulator
builds clean. Seventeen banks, 6,166 passages, every one through `assemble.py`.
`/s` was driven in a browser by the agent that built it.

**Unverified.** *Nobody has seen the four marks on a screen.* Their geometry was
judged at fifteen points in `tools/glyphs` and the Swift is a line-for-line
transcription, but the stage row has not been looked at. See *Next step*.

## Files
- `App/PeaceGarden/Views/Chrome.swift` — `markBox`, `SeedGlyph`, `GardenGlyph`,
  `CogShape`. Every rejected drawing is in the doc comments.
- `App/PeaceGarden/Views/Glyphs.swift` — `MeetGlyph`.
- `tools/glyphs/` — `shapes.py` mirrors the Swift, `sheet.py` renders any set of
  marks large and at fifteen points on both grounds. The real product of the
  mark work; use it before changing any glyph.
- `tools/site/export.py` — writes `Server/passages/*.json` and
  `Server/languages.json` from the app. CI runs `--check`.
- `Server/` — the site. `s`, `assets/js/*.js`, `strings/*.json` (16 files, every
  value `null`, awaiting commission).
- `docs/WEBSITE.md` — phase 2 spec. Read before touching peacegarden.app.
- `docs/LANGUAGES.md` § *Round two* — the eight banks still to write.

## Decisions made
- **The garden is walkable; guests from anywhere can visit.** Taken while
  nothing is published, so no page is relisted and nobody re-asked. `noindex`
  stays — walkable and indexed are different properties. The garden shows
  plants, not people; a grid of names is a directory.
- **The passage is drawn in the reader's language, everywhere.** So the garden is
  read one language at a time, not partitioned by language. Partitioning would
  publish the sharer's language — the first fact this app stated about somebody
  that they never chose to state, and hardest on small-language speakers.
- **The plot record must carry the derived theme.** A page reads a theme off a
  genus head, but a *pair's* theme needs both parent seeds, and giving a page
  those publishes the other gardener's seed. `WEBSITE.md` said this was free.
- **20i with a database on it** for the plot service; **seventeen languages** of
  site chrome; **the cog is an ordinary cog**, because recognition wins on the
  one mark whose job is to be found without being read.

## Next step
Look at the stage row on a simulator. First light blocks it and **injected taps
do not reach the `PLANT IT NOW` button** — `tap` and `touch_path` both, at
coordinates checked against the screenshot. Go round it the documented way:
write `Library/Application Support/PeaceGarden/garden.json` in the app's data
container with a `birth` some weeks past, so the app opens on the stage.

## Traps
- **A screenshot right after `simctl launch` catches the zoom animation.** Wait
  four seconds. Third instance of this shape in this repo, after sheets and taps.
- **`cd` persists between Bash calls**, and a later `xcodebuild` then fails with
  *`PeaceGarden.xcodeproj` does not exist*.
- **`Localizable.xcstrings` is not `json.dumps` round-trippable** — Xcode writes
  `"key" : {`. Rewriting it reformats all 6,181 lines. Edit textually.
- **Two agents writing one bank will duplicate three or four lines**, always a
  proverb or a famous poem. `assemble.py` catches them; each sits in a different
  subtheme in each half, so the call is which home is better, not which to drop.
- **A generative image model cannot hold a monoline.** Three rounds went bulbous,
  then brightness-glyph, then cat. Use it for composition, draw the line here.
