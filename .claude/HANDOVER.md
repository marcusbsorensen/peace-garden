# Peace Garden — handover 5 September 2026 (evening)

*The site went up, a plant can be let go, and the writing rules changed twice.
Most of what is open now is naming rather than building.*

## Goal

Get the app and site launch-ready. The writing settled and translated, the mark
final, and the work off this machine.

## State

`main` at `fa3c0ac`, **pushed**. **peacegarden.app is live.**

**Verified** — 97 SeedCore tests, 28 app tests, five Python checks; eleven paths
checked at the far end by `tools/deploy.sh`; `/s` drawing in English, French,
Danish and Arabic; the release row and *Løssæt den på Vildmarken* on an
iPhone 17 Pro.

- **The host does not read `.htaccess`.** 20i is nginx straight to PHP-FPM with
  no Apache, so the content-type design was inert and `/s` arrived as a
  download. `Server/index.php` serves the four extensionless paths; they live in
  `Server/.pages/`.
- **`force-cache` was hiding every correction** on all four generated files. Now
  `no-cache`.
- **One drawing.** `mark.svg` was a stale copy of the icon; deleted.
- **Release to the Wild Fields**, held for 3 seconds, with `ReleaseFlight` for
  the departure and four tests that render it rather than watch it.
- **Two gender faults fixed** — `%@ est sorti` and `%@ si è allontanato` guessed
  masculine for somebody's name.

**Unverified** — the release hold itself (needs a thumb); every translation;
Italian, Norwegian, Dutch and Swedish throughout.

## Next step

**The Root Ground needs more thought.** Marcus's note, and it is the first thing
to settle because 42 languages will be commissioned against these names.

It is the weakest of the ten in English: not a real garden term the way *The
Seedbed* and *The Glasshouse* are, and not a coinage that earns itself the way
*The Crossing* does. It names the `ground` theme — *the rhizosphere, a teaspoon
of earth, querencia, Heimat, a kept place, pairidaeza, garden as enclosure*. The
theme is about **soil, and about a place you belong to**, and the name currently
carries only the first half.

*The Orchard* is worth a second look at the same time: it names `kinship`
(*inosculation, grafting, lichen, sibb, ubuntu*) by association rather than by
meaning, and it is the other one a translator will struggle to justify.

## The ten, and the decision behind them

**Marcus reversed the English-only rule on 5 September**: the ten area names are
to be named in every language. Nothing is built. What that means:

| | |
| --- | --- |
| `Server/assets/js/walk.js` | `AREA_NAMES` is a table; becomes catalogue keys |
| `Server/assets/js/strings.js` | ten keys into `EN` — nineteen becomes twenty-nine, against a module whose first line defends the low tens |
| `Server/strings/*.json` | 42 × 10 = **420 names**. Absent falls back to English silently, so they can arrive language by language |
| `tools/strings/commission.py` | a second brief. Naming a place is not the job the six paragraphs are |
| `tools/strings/check.py` | its area rule **fails CI** if a translated string contains an area name. That inverts |
| `docs/REVIEWING-A-LANGUAGE.md` §4 | tells every reviewer the areas stay English. Reverses |
| `tools/strings/BRIEF.md` | carries an interim note saying the change is coming and not to act on it yet |

Three of the ten cannot be translated, only renamed, and the brief has to say so:

- **The Knot Garden** is a Tudor form. French would reach for *parterre de
  broderie* — its own tradition, which is the right answer and not a translation.
- **The Coppice** is an English woodland practice. A forestry term at best
  elsewhere, and absent outside northern Europe.
- **The Crossing** carries two senses at once — where paths cross, and crossing
  two plants. *croisement*, *cruce*, *incrocio*, *krydsning* all keep both.
  Japanese, Korean, Chinese, Arabic, Hebrew, Finnish, Hungarian and Basque must
  choose, and the brief should tell them to keep the meeting.

## The numeral rule

**A quantity is a numeral from 2 up; one stays a word.** In `BRIEF.md`. It is
for numbers the reader is being told — plants in a garden, seconds to hold,
days until a flower opens. **Prose is not a quantity**: *two people meeting*
stays words, and so do the forty figurative places like *Where two paths cross*.

Open, and deliberately left rather than half-done:

- **The singular case.** `%lld grown from meetings` prints *1 grown from a
  meeting* where the rule asks for *One*. Not a find-and-replace: CLDR's `one`
  category covers 0 and 1 in French and 1, 21, 31 in Russian, so a hard-coded
  word is wrong in some of the forty-three.
- **Nothing enforces it.** `check.py` is the place, and it needs each language's
  number words — the same list a sweep would need.

## Still open

- **Four app strings want native readers** — the release row, its alert, its
  confirm and its consequence, all `needs_review` in it/nb/nl/sv. Marcus wrote
  the Danish and read the French and Spanish.
- **The language review is 2 screens of 6.** Screens 3 (no name), 4 (come back),
  5 (broken) and 6 (the garden) are unwalked in every language.
  `out/review/INDEX.md` has 43 sendable packets.
- **The passage banks are not all "its own writers"** — Danish drew Marcus
  Aurelius, Spanish drew a Catalan tradition, where §4 promises otherwise.
- **Request logging on `/s`** is a 20i control-panel setting, not done.
- **The Wild Fields is phase 2**, reachable from the menu as a named place.
  `docs/PHASES.md` carries it as a requirement on the plot service.
- The iPhone SE layout, and the passage's own direction in the app for an RTL
  reader with no bank — both in `docs/LANGUAGES.md`, both unlooked at.
- **App Store screenshots.** `-pgOpen` was built for it and has never been used.
- **`appNote` shares its first sentence with `about3`.**

## Traps

- **A held control cannot be driven by injection.** `HoldToConfirm` reads a press
  through `PressReporting`, and an injected press arrives and is released in the
  same instant. `Chrome.swift` says so. Test it with a thumb.
- **Never `pkill -f CoreSimulator`.** It wedges the whole simulator subsystem and
  every boot then times out at 60s. Recovery is
  `killall -9 com.apple.CoreSimulator.CoreSimulatorService`, which launchd
  restarts. Learned the hard way this afternoon.
- **`.htaccess` does nothing on peacegarden.app.** A `RewriteRule` that never
  fires looks exactly like a file being served.
- **A 200 with the wrong `Content-Type` is this site's whole failure mode.** Run
  `tools/deploy.sh --check` rather than trusting an upload.
- **A plant created under a developer clock shift is born at the shifted now**,
  so wind on again afterwards to age it. `xcrun simctl spawn <udid> defaults
  write app.peacegarden developer.clockShift -float <seconds>`.
- **The marks at the foot of the stage do not answer injected taps.** Use
  `xcrun simctl launch <udid> app.peacegarden -pgOpen settings`.
- **`cd` persists between Bash calls.** Always pass absolute `--package-path`.
- **Render a night-opening plant at its own peak hour**, or every flower is a
  shut bud. `tools/preview/plant_model.py` has the tempo.
- **A term match must be on the head of a word, not the whole of it.**
- **Catalogue keys are nested under `strings`**, not at the top level.
