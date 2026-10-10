# A loading animation for Peace Garden — 10 October 2026

Two variants, drawn and wired, for Marcus to choose between from the pictures in
this folder. **Variant A is recommended.** Nothing is merged to `main`.

| | A — the mark unwinds (recommended) | B — the fiddlehead |
| --- | --- | --- |
| What it is | The app's own mark, furled, lets go of its coil; the white bract opens like a bud; one band of light crosses it once; it rests on the exact icon drawing | The garden's own gesture, alone: a gold hairline stem lets go of its curl and a leaf opens at the tip |
| Ground | `#0D0D1F`, the suite's, in both appearances | The app's own ground, following light and dark |
| Colour | The mark's own: forest green, lime, yellow, white bract | Gold hairline (the backdrop's gold in the dark, the app's ink in the light) |
| Launch moment | 1.2 s, then the suite's 120 ms / 180 ms hand-over | 1.2 s, then the same hand-over |
| Waiting mark | The coil breathing, in the app's ink, 2.4 s | The frond breathing, in the app's ink, 2.4 s |
| Needs | A launch screen of `#0D0D1F` to be seamless (see question 3) | Nothing |
| Code | `App/PeaceGarden/Views/Loading/UnwindingMark*.swift` | `App/PeaceGarden/Views/Loading/Fiddlehead.swift` |

PLACEHOLDER-PICTURES

## 1. What the suite does (read from the three apps, nothing in them changed)

**The pattern, in five lines.**

1. **A brand mark at rest on `#0D0D1F`, and one band of light (or one ripple) crossing it once**, then it hands over. It is the app's own icon artwork, drawn in code (SwiftUI `Canvas` in UnCubed and Pfish, a web canvas in FlagFans) — no Lottie, no video, no frame sequence.
2. **Its phase is a function of the clock and nothing else**, so it cannot report progress it does not have; the work behind it is started, never awaited past a ceiling, and any touch ends it.
3. **Short and once per launch:** UnCubed 0.6 s (ceiling 0.9 s), Pfish 0.6 s, FlagFans 2.0 s. Easing is ease in and out (UnCubed's `m-turn`, `cubic-bezier(0.35, 0, 0.15, 1)`; FlagFans smoothstep; Pfish linear, from its lightning flash).
4. **The hand-over is the same in two apps:** the mark fades over 120 ms and the ground over 180 ms, started together, so the mark never floats half transparent over the screen it is handing to. UnCubed and FlagFans match the system launch screen's colour to the ground so there is no seam; Pfish keeps its white launch screen on purpose, because Reduce Motion users get no curtain.
5. **Reduce Motion gets no moment at all**, not a shorter one (UnCubed: duration 0; Pfish and FlagFans: not built). UnCubed alone has a counterpart for *user-started* waits: `BusyMark`/`CheckingRing`, four arcs "built and rebuilt", 20 pt, 2 pt stroke, 1.1 s a revolution, shown only after a 400 ms threshold, held still at phase 0 under Reduce Motion.

**Shared and each app's own.**

| Shared by all three | UnCubed's own | Pfish's own | FlagFans's own |
| --- | --- | --- | --- |
| Ground `#0D0D1F`, flat, both appearances · mark from the icon artwork · light crossing once · clock-only phase · any touch skips · launch work never gates · Reduce Motion = nothing | `un³` and the arc's wash · the awaited launch work (restoring purchases, 300 ms budget) · the busy ring · a design-system table of motion tokens | A fish, two bubbles rising and a shimmer · a CloudKit check and a what's-new card behind it, after it | A longer 2.0 s with two beats (sheen, then a gust in the crossbar) · a wordmark, a `Checking for news…` line, an `INTERFULGENT` footer, `Tap to skip` |

**Where to read it.**

- UnCubed — `uncubed-integration/App/LaunchSplash.swift`, `LaunchSplashView.swift` (the splash and the root's three phases), `LaunchWork.swift` (what runs behind, the 900 ms ceiling), `BrandMarkArc.swift` (`LaunchCurtain`: the 600 ms sweep), `BusyMark.swift`, `CheckingRing.swift`, `CheckingRingGeometry.swift`; `docs/design/ui-design-system.md` §6 (motion tokens, §6.4 Reduce Motion, §6.5 *no shimmer or skeleton loading*); `docs/2026-10-05-busy-and-arrows-1005.md`.
- Pfish — `pfish-ios/App/LaunchCurtainView.swift`, `Sources/TankKit/LaunchCurtain.swift` (the rules, 14 tests), `docs/launch-and-home-design.md` §2.
- FlagFans — `flagfans/src/components/LaunchSplash.tsx`, `docs/design/launch-screen/ff-launch-mockup-approved-2026-10-09.html` and its frames, `capacitor.config.ts` (the native launch image is the same ground).
- Brand — `uncubed-integration/docs/design/suite-brand.md` §3 (one ground, one stroke, one gradient, the hue allocation; Peace Garden's 140° → 60° segment) says nothing about loading. `interfulgent-hub` has no loading or motion rule. The two frames folders (`uncubed-entry-animation-frames`, `uncubed-arrowfit-frames`) are review stills for the cube entry and the arrow fit, not loading assets; they show the working method this folder follows, which is deciding from renders.

## 2. Where Peace Garden waits

| Wait | What is there today | Wired? |
| --- | --- | --- |
| **Launch.** `GardenModel()` reads the garden file, then `PlantStageView` builds its SceneKit view | The system's blank launch screen (the plist's `UIColorName` is empty), then the stage | **Yes**, as the launch moment: an overlay, the app built underneath it |
| **A request to the web garden** (`ShowInGardenView` ask and answer, `WildBesideView`), timeouts 8 s and 20 s | The two buttons dim to 40 % and stop answering, with nothing to say why — UnCubed's *"I could not tell whether my tap had registered"* | **Yes**, the waiting mark after 400 ms, on both screens |
| **The first draw of the garden.** `GardenSprites.sprite(…)` renders every plant through an `SCNView` snapshot on the main actor, twice per plant, and caches 120 | Plants appear as each render finishes | No. A mark per plant is the wrong shape, and `PlotView` is 1,639 lines. Candidate: hold the plot's own ground behind one launch-style mark until the first row is in |
| **Growing a plant's 3D scene** (`PlantSceneView`) | Black until the first frame | No. Covered by the launch moment only at launch |
| **An exchange between two phones** | `BreathingDot` and a sentence, while searching and while waiting for the other phone's knock | No. It already has a waiting mark, and the sentence is the news. Candidate for the same view |
| **First light** | `BreathingDot`, four fading lines, `SproutingRule` | No. It is staged and paced to be read, not a wait |

I did not measure these on a device. The simulator's GPU is not the phone's, so
any figure from it would mislead.

## 3. Decisions for Marcus

PLACEHOLDER-QUESTIONS
