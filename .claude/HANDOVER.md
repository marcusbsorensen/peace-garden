# Peace Garden — handover 5 September 2026

*The site went up, the host turned out not to be the host the design assumed,
and the language review started. A fresh session should pick up the review.*

## Goal

Get the app and site launch-ready. The writing settled and translated, the mark
final, and the work off this machine.

## State

`main` at `18a2e9f`, **pushed**. **peacegarden.app is live** — `/s`, `/g`, `/t`
and the association file all answer with the types they are.

**Verified** — 97 SeedCore tests, 28 app tests (five of them new), five Python
checks; eleven paths checked at the far end by `tools/deploy.sh`; `/s` drawing
its seed in English, French, Danish and Arabic; the garden falling back to
invented plants and saying so; the release row in place on an iPhone 17 Pro.

- **The host does not read `.htaccess`.** 20i serves this site from nginx
  straight to PHP-FPM with no Apache in the chain, so the whole content-type
  design was inert and `/s` arrived as a download. `Server/index.php` serves the
  four extensionless paths now; they live in `Server/.pages/`.
- **`tools/deploy.sh`** uploads and then reads the headers back, which is the
  half that matters. `--check` alone checks what is live.
- **`force-cache` was hiding every correction.** All four generated files were
  fetched that way, so a reader who had seen a language once kept it for good.
  Now `no-cache`.
- **One drawing.** `assets/mark.svg` was a stale copy of the icon and the pages
  carried the old mark in the header beside the new one in the tab. Deleted; the
  pages point at `assets/icon.svg`.
- **Three corrections live** — the Danish tagline and `growBody`, the French
  `about2`.
- **Release to the wild fields**, held for three seconds, with the departure
  drawn in `ReleaseFlight`.

**Unverified** — the release hold itself, which needs a thumb (see Traps); every
translation, which is machine-made; iPad landscape framing.

## Files

- `Server/index.php` — the four paths, and why the host leaves no other way.
- `tools/deploy.sh` — upload and check. `Server/README.md` is the long version.
- `Server/assets/js/strings.js:200` — the caching note the other three point at.
- `App/PeaceGarden/Views/PlantDetailView.swift` — the release row, the alert on
  the assisted path, and `release()`.
- `App/PeaceGarden/Rendering/ReleaseFlight.swift` — the departure.
- `App/PeaceGardenTests/ReleaseFlightTests.swift` — how a 1.7s animation is
  checked at all. `PG_FLIGHT_FRAMES` writes the frames out to look at.
- `tools/site/mintlink.py --packets out/review` — 43 sendable review packets.

## Decisions made

- **`.pages/` rather than the served paths**, because a file at `/s` wins at
  nginx's `try_files` and `index.php` never sees the request. The leading dot
  gets nginx's own dot-directory deny, so each page has one address.
- **The association file goes through PHP too.** Apple's CDN was parsing it
  happily while the origin said `application/octet-stream`, which is Apple being
  lenient about a rule Apple documents.
- **`HoldToConfirm`, not a new control.** This pass wrote one from scratch
  before finding the app already had a better one. Deleted.
- **The wild fields are a place in phase 2** — `docs/PHASES.md`. A released
  plant stands unattributed; releasing is one person's; the other's copy stays.
- **The release copy says what survives**, not what cannot be undone.

## Next step

**The language review, screens 3 to 6.** Screens 1 and 2 were walked in English,
French, Danish and Spanish and produced three corrections. Screens 3 (no name),
4 (come back), 5 (broken) and 6 (the garden) have not been looked at in any
language. `out/review/INDEX.md` has the packets; `tools/site/mintlink.py
--review <code> --base https://peacegarden.app` prints one language's six.

Then the thirty-seven others, and Greenlandic, which cannot ship until a speaker
reads it.

## Still open

- **Four app strings need seven languages each** — the release row, its alert
  and its consequence. `Localizable.xcstrings`; da/es/fr/it/nb/nl/sv fall back to
  English in silence until then.
- **The passage banks are not all "its own writers"** — Danish drew Marcus
  Aurelius, Spanish drew a Catalan tradition. `docs/REVIEWING-A-LANGUAGE.md` §4
  promises otherwise. Different job from the strings.
- **Request logging on `/s`** is a 20i control-panel setting and is not done.
- The two nobody has looked at, both in `docs/LANGUAGES.md`: the iPhone SE
  layout, and the passage's own direction in the app for an RTL reader with no
  bank.
- **App Store screenshots.** `-pgOpen` was built for it and has never been used.
- **`appNote` shares its first sentence with `about3`.**

## Traps

- **A held control cannot be driven by injection.** `HoldToConfirm` reads a
  press through `PressReporting`, and an injected press arrives and is released
  in the same instant — the hold begins and is abandoned before a frame is
  drawn. `Chrome.swift` says so. Test it with a thumb.
- **`.htaccess` does nothing on peacegarden.app.** A `RewriteRule` that never
  fires looks exactly like a file being served.
- **A 200 with the wrong `Content-Type` is this site's whole failure mode.** Run
  `tools/deploy.sh --check` rather than trusting an upload.
- **`cd` persists between Bash calls.** Always pass absolute `--package-path`.
- **Render a night-opening plant at its own peak hour.** At 13:00 every flower
  is a shut bud. Get the tempo from `tools/preview/plant_model.py`.
- **The developer clock is a `UserDefaults` double**, so `xcrun simctl spawn
  <udid> defaults write app.peacegarden developer.clockShift -float <seconds>`
  before launch beats tapping +1w. A plant created under a shift is born at the
  shifted now, so wind on again afterwards to age it.
- **The marks at the foot of the stage do not answer injected taps.** Use
  `xcrun simctl launch <udid> app.peacegarden -pgOpen settings`.
- **A term match must be on the head of a word, not the whole of it.**
- **Catalogue keys are nested under `strings`**, not at the top level.
