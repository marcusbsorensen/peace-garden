# The name and version on the launch moment, and the update check — 11 October 2026

Marcus: *"the launch moment is lovely - I think we just need to write PeaceGarden and the
version number somewhere on it, so it can check for updates if it has a network
connection."* Then, for the update check, option A: ask the App Store quietly, and show a
small up-arrow beside the version when there is something newer, asked of the person's own
country's App Store. Branch `claude/launch-glyph-2026-10-11`; nothing is merged.

**Decided — Marcus, 11 October 2026: A, the name over the version, low; no version in
Settings; and the person's own App Store, never the US one.** The answers are recorded under
each question at the end.

![](choice.png)

**[`choice.png`](choice.png)**, which Marcus decided from. Each column is the end of the launch moment as
the loading harness draws it (`LaunchMoment.mark` at t = 1, the launch ground, a 390 pt
phone at 3×, a 34 pt home indicator left under the foot): the whole screen, its lower part
at 2×, and the foot at the phone's own pixels with the update arrow showing.
[`update-glyph.png`](update-glyph.png) shows the recommendation's foot without the arrow,
with it, under right to left, at the largest text size and in the light appearance.

## What it says, and how

- **The name, *Peace Garden*,** is a proper noun and is written the same in every language,
  as the site's wordmark is: no key, no translation. It is set as the wordmark is set, light
  and letter-spaced by 0.18 of its size (`site.css` `.wordmark`), smaller and quieter,
  because here the plant is the picture and the name its caption.
- **The version, `1.0 (7)`,** is the bundle's: `CFBundleShortVersionString` and
  `CFBundleVersion` (`AppVersion`). Under right to left it is held in a left-to-right isolate,
  or the bidirectional algorithm would lay it out as `(7) 1.0`.
- **Colour.** The moment is on the launch ground in both appearances, so the colours are
  fixed, not the app's adaptive greys: the logo's warm white `#F4F3EF` at the chrome's two
  text levels, 0.72 for the name (9.1:1 on `#0D0D1F`) and 0.56 for the version (5.9:1). Both
  clear WCAG AA for small text, and both are quieter than the plant's leaf (17.3:1).
- **Dynamic Type** scales both, and stops at xxxLarge, where A is 1.3 times its size. A test
  draws every placement at the largest accessibility size on a 375 × 667 phone, a 390 × 844
  one and an iPad, and holds its ink below the frame the plant is drawn in and inside the
  screen.
- **VoiceOver hears one label, once**: *Peace Garden 1.0 (7)*, carried by the version; the
  name is hidden from it, and the drawing still says nothing. The update arrow, when it is
  there, is a button of its own.
- **Touch.** Any touch still ends the moment: the words take none and it falls through to
  the ground. Only the arrow keeps its own, through a 44 pt target round a glyph the size of
  a numeral; it opens the App Store and ends the moment.
- **It fades in** over the first 180 ms (`LoadingTiming.busyFade`, the app's figure for a
  thing coming in over a ground that is already there), and leaves with the plant, over
  120 ms, so it never floats over the screen being handed over to.

## Reduce Motion: no name and no version

Reduce Motion has no launch moment, only the still waiting mark, and the name and version do
not go on the still mark. The waiting mark is not a launch: it appears inside the app's own
screens whenever a request takes longer than 400 ms, so a name and version on it would be
repeated at every wait, over the screen somebody is using. A still nameplate at launch
instead would be a curtain, and Reduce Motion's rule, the suite's, is no curtain, not a
shorter one. So with Reduce Motion on there is no name, no version and no question to the App
Store, and the privacy page says so. If the version should be reachable with Reduce Motion
on, the place for it is the foot of Settings, not the waiting mark: question 2 below.

## The update check (option A, as Marcus chose)

`UpdateCheck` in `Views/Loading/UpdateCheck.swift`.

- **When.** Once a launch, started as the launch moment starts, and never waited for. The
  request may take up to 2 s, the length of the moment, because an answer after that has
  nowhere to be shown; offline, slow, refused or unreadable all end in silence. The answer is
  kept for the session.
- **Whose store.** The phone's own App Store country, from StoreKit's `Storefront.current`,
  Marcus's answer of 11 October 2026: *"we do NOT want to be US dependent or force people
  from non-US-friendly countries to have to check with a US app store in case their web
  traffic is tracked."* StoreKit gives three letters (`DNK`) and the lookup takes two (`dk`);
  Foundation converts them through the region aliases every locale carries (`und_DNK` reads
  as the region `DK`), so there is no hand-written table, and the result is accepted only if
  it is two letters and an ISO region (`StoreCountry`). **With no storefront there is no
  question**: signed out, unavailable, or a code that does not convert, the check is skipped
  silently, and it never falls back to the US store, which is what the lookup answers from
  when no country is given. Kosovo's storefront is the one known case: Apple's `XKS` is not
  an ISO code, so a phone in Kosovo's store skips the check.
- **What it sends.** One GET to Apple's public lookup,
  `https://itunes.apple.com/lookup?bundleId=app.peacegarden&country=dk`: the app's id and the
  store's country, nothing else. The session is ephemeral, with no cookies and no cache; the
  two headers a phone adds on its own are replaced, the user agent (which names the system's
  version) by `PeaceGarden` and the preferred languages by `en`, since only two numbers are
  read from the answer. It honours Low Data Mode by not asking on a constrained network. An
  answer that arrives after the 2 s, the storefront's time included, is not shown.
- **What it shows.** If the store's version is newer than the bundle's, compared as dotted
  numbers (1.10 is newer than 1.9, and 1 and 1.0 are the same), an `arrow.up.circle` SF
  Symbol appears beside the version, fading in. It opens the app's page,
  `https://apps.apple.com/app/id<the store's id>`, built from the store's numeric id rather
  than taken from the answer as a link. No results, which is what the lookup returns until
  the app is publicly released (TestFlight builds are not in it), means no arrow. Anything
  that is not dotted whole numbers is never newer.
- **No new words but one.** The arrow's VoiceOver label is one new key, *Newer version in
  the App Store*, Danish *Nyere version i App Store*; the other 41 languages are for the next
  translation round.
- **Tests and the network.** The launch moment plays in the test host too, so a test run
  asks nothing (`UpdateCheck.isHostingTests`); `UpdateCheckTests` hands the check a session
  with a stand-in for the network.
- **To see the arrow** in a debug build: `xcrun simctl launch <device> app.peacegarden
  -pgUpdateGlyph YES`. It shows the arrow without asking.

### On the privacy page

`/privacy` gains a tenth paragraph, `privacy10`, after the one on the asking, since both
happen as the app opens (`Server/.pages/privacy`, `Server/assets/js/strings.js`,
`Server/strings/da.json`). The other languages read it in English until the next
commission; `tools/strings/commission.py` and `check.py` carry it as a group of its own, as
the ninth is, so no catalogue becomes half-commissioned.

The final wording, with the store's country (11 October 2026):

> **English.** When the app opens, it shows its name and version for a moment and asks the
> App Store of your own country whether there is a newer version of Peace Garden. The
> question carries only that country and the app's id, and Apple receives it from your
> internet address, as it does any request. If there is a newer version, a small arrow
> appears beside the version number, and touching it opens the App Store. When the phone
> cannot say which country's App Store it uses, the app skips the question. With Reduce
> Motion on, the app opens straight into your garden, without the name or the question.

> **Dansk.** Når appen åbner, viser den et øjeblik sit navn og sin version og spørger App
> Store i dit eget land, om der findes en nyere version af Peace Garden. Spørgsmålet
> indeholder kun landet og appens id, og Apple modtager det fra din internetadresse, som ved
> enhver forespørgsel. Findes der en nyere version, kommer der en lille pil ved siden af
> versionsnummeret, og rører du ved den, åbner App Store. Kan telefonen ikke oplyse, hvilket
> lands App Store den bruger, springer appen spørgsmålet over. Med Reducer bevægelse slået
> til åbner appen direkte i din have, uden navnet og uden spørgsmålet.

*Cannot say which country's App Store it uses* is said that way rather than *signed out*,
because whether StoreKit gives a storefront to a phone signed out of the App Store is
Apple's to decide and has not been tested here; what the app does is the same either way.

**The privacy manifest** (`PrivacyInfo.xcprivacy`) gains a comment and no entry: the request
carries the App Store's own country to the App Store and reaches only Apple, so it is not
collected data and not tracking. App Store Connect's answer stays *Data Not Collected*.

## The three placements, as drawn for the choice

| | Where | Name | Version | Foot above the home indicator |
| --- | --- | --- | --- | --- |
| **A**, recommended | stacked, centred, low | 13 pt | 11 pt, under it | 28 pt |
| **B** | one line at the foot | 11 pt | 11 pt, beside it | 14 pt |
| **C** | the name under the plant, the version at the foot | 17 pt | 11 pt | 14 pt |

Measured in the renders, on the 390 × 844 pt phone with a 34 pt home indicator; the
plant's lowest ink, its root, is at 571 pt.

| | Ink, wide × tall | Under the plant's root | Above the screen's foot | With the arrow |
| --- | --- | --- | --- | --- |
| **A** | 107 × 31 pt | 179 pt | 63 pt | the arrow hangs beside the version; nothing moves |
| **B** | 141 × 10 pt | 214 pt | 49 pt | the line grows to 162 pt |
| **C** | name 137 pt wide; version alone | 28 pt (the name) | 49 pt | beside the version, at the foot |

- **A** reads as a caption, apart from the plant and clear of the edge: the name, and the
  version under it a step quieter. At the largest text size it grows to 139 × 45 pt and stays
  153 pt under the plant's frame.
- **B** is the quietest, one line close to the home indicator. The cost: at 11 pt and
  letter-spaced the name reads as small print, and the line sits where the system's own
  furniture is.
- **C** makes a lockup, the name under the plant as the logo's lockup has it under the mark.
  It is the most present of the three and the nearest to competing with the fiddlehead, and
  the version is left alone at the foot.

**A is now the only placement in the code.** B and C, and the switch between them, were
removed once Marcus chose; their sizes are in the table above, and `choice.png` was drawn by
the harness at commit `6342216`, when all three were there. The loading harness
(`LoadingTests.testWriteTheLoadingFrames`) now draws the label too, fading in over the first
180 ms, and `design/loading-2026-10-11/`'s launch filmstrip, GIF and MP4 were rebuilt from
it. Its `final-frame.png` is the plant's own frame, which the label stands below, so it is
unchanged.

## Decisions for Marcus

All answered by Marcus on 11 October 2026.

1. **Where and how big?** A, name over version, low and small (recommended) · B, one line
   at the foot · C, the name under the plant as a caption.
   **Decided, 11 October 2026: A.**
2. **The version with Reduce Motion on?** Nowhere, as built: no moment, no name, no question
   (recommended) · also at the foot of Settings, as `Peace Garden 1.0 (7)` with the arrow,
   which asks the App Store whenever Settings opens.
   **Decided, 11 October 2026: nowhere.** Settings is unchanged.
3. **Which App Store does the check ask?** The US store, the lookup's default · B, the
   phone's own storefront, and no check without one.
   **Decided, 11 October 2026: B**, the person's own, never the US one by default.

## Tests

All on the branch rebased onto `origin/main`, on a scratch iPhone Air simulator:

- `LaunchLabelTests`, 4 tests and the picture writer: the colours' contrast on the launch
  ground (9.1:1 and 5.9:1, both under the leaf's); small, as chosen, at the wordmark's
  spacing; below the plant and inside the screen at the default and the largest
  accessibility text size, on three screens, with the arrow showing; and the arrow beside
  the version without moving it, on its trailing side in both directions.
- `UpdateCheckTests`, 13 tests, none touching the network: dotted versions compared as
  numbers; odd versions never newer; `1.0 (7)` from the bundle and held left to right, and
  the one spoken label; the request names this app and the store's country alone, with no
  cookies, no cache, Low Data Mode honoured and a 2 s limit; it asks in the storefront's own
  country; with no storefront, or one that does not convert, no request is made at all; a
  sample of thirty storefront codes from across the world converts, and nine malformed ones
  are refused; no results, no glyph; a newer version opens the store page built from its id;
  the same or an older version shows nothing; failure is silent; once a launch with the
  answer kept; and a test run asks nothing.
- `LoadingTests`, passing; its picture writer now draws the label.
- `tools/strings/check.py`: 42 catalogues clean, with `privacy10` its own group.

## Making the pictures again

```
TEST_RUNNER_PG_RENDER_LOADING=/some/renders xcodebuild test -project PeaceGarden.xcodeproj \
  -scheme PeaceGarden -destination 'platform=iOS Simulator,id=<a scratch simulator>' \
  -only-testing:PeaceGardenTests/LaunchLabelTests/testWriteTheLaunchLabelFrames
python3 design/launch-label-2026-10-11/make-choice.py /some/renders   # update-glyph.png
```

`choice.png` comes from the same two commands run at commit `6342216`, when the harness still
drew B and C.

Rendered on a scratch iPhone Air simulator, since deleted; nothing was measured on a
device.
