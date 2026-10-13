# Peace Garden app: mass test, 13 October 2026

The app stressed with gardens of 14 to 2,000 plants, SeedCore crossed 100,000
times, and the main screens swept across every catalogue language, a
pseudo-long locale, forced right-to-left, four Dynamic Type sizes, both
appearances and three phone sizes. Harness in `tools/masstest/app/`; the
garden stress test is `App/PeaceGardenTests/MassTestStressTests.swift`, the
fuzz `Packages/SeedCore/Tests/SeedCoreTests/MassTestFuzzTests.swift`. Both are
skipped unless `PG_MASSTEST` is set, so the everyday suite is unchanged.
**No product code was changed and no test seam was added**: the stress test
hosts the real `PlotView` over a `GardenModel` built from a temporary file,
and the UI tests write `garden.json` into the app's container from the test
runner.

## The findings in one line each

1. **Big gardens freeze and then die.** Opening, turning or winding the garden re-photographs every plant in one main-thread block: 0.6 s at 14 plants, 3.2 s at 100, 18 s at 500; memory peaks at about 8 MB a plant while it does, so 200 plants reach 2.5 GB, the app itself passed 5 to 6 GB on a two-finger gesture at 300, and 1,000 and 2,000 passed 5 GB within seconds of opening and had to be stopped.
2. **Every frame of a pan, pinch or carried plant redraws every plant**: 19 ms at 14 plants, 110 ms at 100 (about 9 frames a second), 590 ms at 500.
3. **The garden is invisible to VoiceOver**: no plant has a label or an action, and the tray's 7 figures and 8 grounds are unlabelled buttons.
4. **Dynamic Type does nothing**: 0 of 1,499 texts grew from Large to the larger sizes; only the launch nameplate scales.
5. **Settings shows its privacy paragraph in English in all seven languages**: the source says "when that seed was *drawn*", the catalogue key (since 26 September) says "*made*", so the lookup misses.
6. **Right to left, the tray's fade and » sit over the first item** instead of at the edge where the row overflows; the garden's foot is half mirrored.
7. **First light truncates on the iPhone SE** in French (and pseudo-long): a line that should wrap is squeezed to one line with an ellipsis.
8. **The small label voice fails the contrast audit in both appearances**; in Light, `Chrome.faint` is 3.7:1 by arithmetic, under WCAG AA's 4.5:1.
9. **With Settings open, VoiceOver can still reach the stage underneath** (its four marks and the plant's name are in the same accessibility tree).
10. **Some buttons are read twice**: "Reset everything, Reset everything", "Empty the garden, Empty the garden", "Release, Release".
11. **Memory is not handed back**: closing a 500-plant garden leaves 1.4 GB behind, and the footprint climbs about 20 MB with each month the clock moves.
12. Smaller: the seed sheet's last rows sit below the fold on the SE; the Testing section cannot be folded by launch argument; seven or eight asking-flow strings per language still await translation (known).

SeedCore came through clean: 100,000 random crosses, lineages up to 2,715
crosses deep, no crash, no trait out of range, no NaN, deterministic across
two runs, and a second implementation in Python re-derived 500 sampled
crosses exactly.

## What ran

| | |
|---|---|
| Xcode / runtime | Xcode 26.6 (17F113), iOS 26.5 simulator runtime |
| Build | **Debug**, because every `-pg` launch argument and the developer clock are Debug-only. Timed twice: as built (`-Onone`), and with the optimiser on (`SWIFT_OPTIMIZATION_LEVEL=-O`, still Debug), which is the nearer guide to a shipped build: an unoptimised SeedCore makes each plant's mesh about ten times slower |
| Simulators (scratch, deleted after) | `pg-mt-app-SE` iPhone SE (3rd generation), 375 × 667 pt, the smallest phone iOS 26 runs on · `pg-mt-app-Air` iPhone Air, 420 × 912 · `pg-mt-app-ProMax` iPhone 17 Pro Max, 440 × 956 · `pg-mt-app-Stress` iPhone Air, for the stress and performance runs. No iPhone 17 Pro simulator was touched |
| The Mac | Shared with two other agents (Docker, a headless browser) and a fourth simulator not mine. Load average reached about 600 and swap 40 GB; at one point the disk filled (see *Conditions*). So the times that matter are given as **main-thread CPU time**, which a busy machine distorts far less than the wall clock |
| Duration | Runs from 22:13 to 23:45, up to four simulators at once (about 1 h 30 min of wall time; 100 minutes of screen sweeping alone) |

**Screen matrix (sampled, not the full product).** Every language on every
phone; every Dynamic Type size on at least one phone; both appearances on
every phone. Screens: first light (fresh install), the stage, the seed sheet,
Meet, Settings (top and scrolled to the end), the garden with the tray open, a
plant's screen; plus the launch moment, photographed by timing. Light runs
show the garden by day (`-garden.daylight.v1 always`), dark ones by night.

| Phone | Configurations | Count |
|---|---|---:|
| SE | 10 locales × Large × Dark; 10 locales × AX5 × Light | 20 |
| Air | 10 locales × Large × Light; {en, it, pseudo, rtl} × {XXXL, AX3} × Dark | 18 |
| Pro Max | 10 locales × AX5 × Dark; en × Large × Light | 11 |

Locales: `da es fr it nb nl sv en` (the catalogue), `pseudo`
(`-NSDoubleLocalizedStrings YES`: every looked-up string doubled, which also
exposes any string that never goes through the catalogue) and `rtl`
(`-AppleTextDirection YES -NSForceRightToLeftWritingDirection YES`).
`performAccessibilityAudit(for: .all)` ran on every screen for en, fr, it,
pseudo and rtl. In all: 392 screens photographed and read back as element
trees across 49 configurations, 232 of them audited (29 configurations, 4,045
issues), and the launch moment in 30 configurations. `analyze_screens.py`
then compared every screen with its English counterpart (untranslated text,
strings that never reach the catalogue, mirroring, Dynamic Type growth) and
checked every frame against the window (off-screen, overlapping);
`evidence/screen-analysis.txt` is its output, `evidence/analysis/` the detail.

Contact sheets (downscaled) are in [`sheets/`](sheets/); evidence crops in
[`evidence/`](evidence/).

## Performance by garden size

A garden of genuine crosses (`Pollination.cross`, as at a knock), born across
the last 240 days so every stage is present, with a figure or light for every
50 plants (6 at least, 40 at most). Hosted in a window the size of an iPhone
Air. Optimised Debug build unless marked.

| Plants | Plot side | Garden file / read | **Opening: main thread blocked** (CPU) | Then settling | **One redraw** (main-thread CPU) — a pan, a pinch, a carried plant | ≈ frames a second while moving | Quarter-turn freeze (CPU) | Clock a month on | **Memory peak during a turn** | Left after closing | Unoptimised build: opening / redraw / turn |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 14 | 5.2 m | 11 KB / 1 ms | 0.6 s | 1.0 s | 19 ms | ~50 | 0.6 s | 0.8 s | 0.3 GB | 0.37 GB | 5.9 s / 66 ms / 2.2 s |
| 100 | 13.9 m | 71 KB / 3 ms | 3.2 s | 0.9 s | 110 ms | ~9 | 2.5 s | 4.1 s | 1.0 GB | 0.61 GB | 31.7 s / 442 ms / 12.9 s |
| 200 | 19.7 m | 142 KB / 5 ms | 7.4 s | 6.3 s | 212 ms | ~5 | 5.8 s | 6.9 s | 2.5 GB | 0.81 GB | – |
| 300 | 24.1 m | 212 KB / 9 ms | 7.3 s † | 3.7 s | 325 ms | ~3 | 10.0 s | 20 s | 3.7 GB | 1.08 GB | – |
| 500 | 31.1 m | 352 KB / 14 ms | 17.7 s | 22.6 s | 592 ms | ~1.7 | 26.8 s | 31 s | 5.9 GB | 1.46 GB | 150 s / 2,259 ms / 61.8 s |
| 1,000 | 44 m | 571 KB | **stopped**: passed 5 GB before its first frame had finished | | | | | | > 5 GB | | |
| 2,000 | 62 m | 1.1 MB | **stopped**: passed 5.5 GB about 25 s into opening | | | | | | > 5.5 GB | | |

† 300 ran in the same process straight after 200 and reused the first 200
plants' work (they are the same seeds), so its opening is flattered.
"Memory peak during a turn" is the process footprint sampled in-app just after
each quarter-turn; the stops at 1,000 and 2,000 are the footprint read from
outside by `watchdog.sh` (`top`), which killed the app at a 5 GB ceiling to
keep the Mac's swap from filling the disk again. A simulator has no jetsam; a
phone does.

**Through real fingers** (XCUITest on the same Air, optimised build,
`MassTestPerformanceUITests`):

| Plants | Launch to responsive (`XCTApplicationLaunchMetric`) | Launch memory peak | Garden open, launched straight into it | Pan at 2.4× zoom: app CPU | Two-finger quarter-turn: until it answers | Turn: app CPU | Turn: memory peak (`XCTMemoryMetric`) |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 14 | 1.07 s | 54 MB | 5.0 s | 67% of a core | 0.9 s | 0.4 s | 0.18 GB |
| 100 | 1.33 s | 60 MB | 10.7 s | (22%, see below) | 7.1 s | 5.3 s | 1.55 GB |
| 300 | 1.30 s | 62 MB | 22.3 s | **killed**: passed 6.0 GB during the pinch and pan | **killed**: passed 5.2 GB during the turn | | |

Launch is flat (the stage shows only the person's own plant), and the garden
file reads in milliseconds at any size: everything above is the garden
screen. `XCTHitchMetric` was asked for and reported nothing on the
simulator, so the pan is judged by the app's CPU. The 100-plant pan probably
was not panning (the pinch that zooms in first can land while the app is
busy, and at the fitted size a drag does nothing by design); read the
in-process redraw column above for how moving scales.

**Where it degrades**: already at 14 plants a redraw costs more than a 60 Hz
frame (19 ms against 16.7 ms; a ProMotion phone has 8.3 ms). From about 50
plants a pan is visibly slow, from 100 it is a slide show, and every turn or
stage change is a freeze of seconds. **Where it fails**: the footprint while
turning or opening grows about 8 MB a plant on top of about 1.3 MB a plant
held. An iPhone ends an app at very roughly half its memory, so expect the
garden to be killed on turning or opening at somewhere around 150 to 200
plants on a 4 GB phone (the SE, the 13 mini) and 250 to 300 on a 6 GB one. Those
device limits are estimates; the slope is measured.

## Findings, most severe first

### 1. Opening, turning or winding a big garden freezes it, then kills it

**What happens.** Every plant on the plot is drawn from a SceneKit snapshot
(`GardenSprites.sprite`), two per plant (the steps either side of the hour).
Each is made inside a `.task` on the plant's view, on the main actor, with no
suspension point, so all of them run back to back before the next frame:
`PlotView` blocks the main thread for the whole garden. At 100 plants the
first frame takes 3.2 s of main-thread CPU (31.7 s unoptimised), a
quarter-turn 2.5 s, and every month the clock moves 4 s, because a plant's
growth bucket, the turn and the season are all in the sprite's key. The
autoreleased `SCNView`s and pictures pile up until the block ends, so memory
peaks with the garden's size: about 8 MB a plant, 2.5 GB at 200, 5.9 GB at
500. The cache that should make a turn back free holds 120 sprites
(`countLimit = 120`), which is one side of 60 plants.

**Repro.**

    python3 tools/masstest/app/make_garden.py 300 garden.json
    cp garden.json "$(xcrun simctl get_app_container <udid> app.peacegarden data)/Library/Application Support/PeaceGarden/garden.json"
    xcrun simctl launch <udid> app.peacegarden -loading.style.v1 off -pgOpen garden

then turn the plot with two fingers or the turn buttons. For numbers:
`MT_OPT=1 zsh tools/masstest/app/build.sh` and
`MT_DD=build/DD-MassTestUnitO zsh tools/masstest/app/run_tests.sh stress <udid> build/mt/stress build/mt/stress.clock PG_MASSTEST_SIZES=14,100,500`.

**Evidence.** The tables above; `evidence/stress/stress-O*/stress-*.json`
(every phase, frame intervals and footprints; `stress-Onone` unoptimised);
`evidence/stress/watchdog-optimised-footprint.log` (the stops at 300 in the
app, 1,000 and 2,000). At 100 plants `XCTMemoryMetric` puts a two-finger
turn's physical peak at 1.55 GB against 0.18 GB at 14 (`evidence/perf/`).

**Fixes.**

- **A (recommended).** Make sprites off the main thread and one at a time:
  `SCNRenderer` renders offscreen without a view; wrap each in
  `autoreleasepool`, yield between plants, and show the plant's thumbnail (or
  nothing) until its sprite arrives. The freeze goes, and the memory peak
  becomes one sprite's instead of the garden's.
- **B.** Photograph at the size drawn. At the fitted zoom a 500-plant plot
  draws a plant about 15 points tall from a 480-pixel sprite; a small sprite
  for the fitted view, and full ones only for what is on screen when zoomed in,
  cuts the memory per plant by an order of magnitude. Best combined with A.
- **C.** Hold the cache by cost (`totalCostLimit` in bytes) sized to one side of
  the garden being shown, so a turn and back costs one side, not two.

### 2. Every frame of a gesture redraws every plant

**What happens.** A pan or pinch changes `@GestureState` in `PlotView`, which
re-evaluates the whole body: the standings (a growth state per plant), the
shadow casts, the near-to-far sort and a SwiftUI view per plant. Measured by
moving the clock a second a frame, which re-evaluates the same body with
nothing new to make: 19 ms of main-thread CPU a frame at 14 plants, 110 ms at
100, 212 at 200, 592 at 500 (unoptimised: 66, 442, 2,259). Through real
fingers at 14 plants a pan keeps two thirds of a core busy.

**Repro.** Any garden of 50 or more, `-pgOpen garden`, pinch in and drag.

**Evidence.** The redraw column; `evidence/stress/*/stress-*.json` → `redraw`.

**Fixes.**

- **A (recommended).** Keep pan and zoom out of the body: apply the gesture's
  transform to a container whose content does not read the gesture state
  (a `UIViewRepresentable` scroll view, or `.geometryGroup()` with the offset
  held outside the observed state), so moving the plot moves pixels.
- **B.** Memoise what a gesture cannot change (standings, casts, sort order),
  keyed on the growth buckets, the turn and the hour step.
- **C.** Draw the plants in one `Canvas` from the sprites, with hit-testing in a
  thin layer of leaf paths: one draw instead of N views.

### 3. The garden cannot be used with VoiceOver

**What happens.** On every garden screen audited (29 of 29) the audit
reports 47 or 48 elements with no description: every plant sprite
(unlabelled images), the 7 figures in the tray and the grounds (buttons with
no label; a ground carries only *selected*), and the sky behind them. A plant has no action, so
VoiceOver cannot open a plant's screen from the garden at all. (The turn
buttons, which say a system symbol's name, passed.) Synthesised taps on the
plants never opened one in this run either, while the same taps opened the
grid's tiles and revealed a plant screen's details.

**Repro.** VoiceOver on, `-pgOpen garden -pgTray YES`, swipe through.

**Evidence.** `evidence/garden-foot-unlabelled.jpg` (the controls with no
label: every figure and ground in it); 1,369 *sufficientElementDescription*
issues, every one of them on the garden screen.

**Fixes.**

- **A (recommended).** One accessibility element per plant, near to far:
  label the plant's name and stage, button trait, activation opens its
  screen; label the figures and grounds with a system symbol's name where one
  fits (the tray's existing rule) and words where none does.
- **B.** Hide the plot itself from VoiceOver and give the plants as a list
  reached from the garden's heading.
- **C.** Label the tray's controls only, and leave the plants as pictures.

### 4. Dynamic Type has no effect

**What happens.** Nearly every text is `.font(.system(size:))`, which does not
scale. Between Large and the larger sizes, 0 of 1,499 texts compared (SE at
AX5, Air at XXXL and AX3) changed height; the audit reports *Dynamic Type
font sizes are unsupported* on every screen, 1,912 times. Only the launch
nameplate scales (`@ScaledMetric`, capped), and one glyph in Settings. The
audit's 193 *text clipped* issues say "may be clipped at larger Dynamic Type
sizes": predictions for when type does scale, not clipping today (the one
real truncation is finding 7).

**Repro.** `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL -pgOpen settings`.

**Evidence.** `evidence/dynamic-type-L-vs-AX5.jpg`; `sheets/Air-dynamic-type.jpg`.

**Fixes.**

- **A (recommended).** Scale inside the helpers everything already goes
  through (`chromeLabel`, `chromeHeading`, `plantName`, and a body-text helper
  for the 15 to 17 point paragraphs) with `@ScaledMetric`/`UIFontMetrics`, and
  cap each screen at the size its layout can hold
  (`.dynamicTypeSize(...accessibility2)`), as the nameplate already does.
- **B.** Scale the paragraphs only (Settings explanations, first light, Meet,
  the plant's meeting), leaving the tracked capitals fixed.
- **C.** Keep fixed sizes as a design decision, and say so in the App Store
  accessibility answers.

### 5. Settings' privacy paragraph is English in every language

**What happens.** `SettingsView.swift:464` says "…its seed, when that seed was
**drawn**, its plant's name…". Commit `620893f` (26 September, *The privacy
page says when a seed was made, not when it was drawn*) changed the catalogue
key to "made", with translations into all seven languages, but not the
source. The lookup misses and the paragraph is English everywhere.
`pseudo` agrees: it is the one paragraph in Settings that is not doubled.

**Repro.** `-AppleLanguages "(da)" -pgOpen settings`, scroll to the end.

**Evidence.** `evidence/settings-privacy-english-in-danish.jpg`; found in all
30 translated-language configurations, on both Settings screenshots. It is
the only untranslated text the sweep found on the screens it reached.

**Fixes.**

- **A (recommended).** Change "drawn" to "made" in `SettingsView.swift:464`,
  which is what the catalogue, the web page and `commission.py` say.
- **B.** Rename the catalogue key back to "drawn" and re-check the seven
  translations' verb.
- **C.** Either way, add a test that resolves each catalogue key in `da` and
  fails on an English result, which would also have caught this.

### 6. Right to left: the tray's fade and » on the wrong edge

**What happens.** Under a right-to-left layout the tray's two rows mirror (the
first figure and the chosen ground start at the right), but the edge fade and
the » that says *more this way* stay on the right, on top of the first items,
while the row's overflow runs off the left edge with no fade at all. The foot
below is half mirrored: *Reset view* and the daylight choice swap sides, the
tray's minus and the two turn buttons do not. (The plot itself does not
mirror, by design.)

**Repro.** `-AppleTextDirection YES -NSForceRightToLeftWritingDirection YES -pgOpen garden -pgTray YES`.

**Evidence.** `evidence/rtl-tray-fade.jpg` (SE, left to right and right to
left side by side).

**Fixes.**

- **A (recommended).** Put the fade and the » on the trailing edge by layout
  direction (leading/trailing alignment, or flip the mask with
  `layoutDirection`), and decide the foot as one row: mirrored except the turn
  arrows, which belong to the plot.
- **B.** Pin the tray rows left to right like the plot, since they are
  pictures in the garden's own order, not a reading line.
- **C.** Leave it until a right-to-left language is in the catalogue.

### 7. First light truncates on the iPhone SE

**What happens.** On the 667-point SE the first-light column does not fit
vertically, and SwiftUI gives up a line of height rather than overflowing: in
French "Les empreintes qui tourbillonnent ensemble :" becomes "…ense…", at
Large and at AX5. Pseudo-long truncates two lines the same way; the audit
also flags the Italian heading on the Air and the Pro Max.

**Repro.** Fresh install (no `garden.json`), `-AppleLanguages "(fr)"`, on an
iPhone SE (3rd generation); the lines arrive over about six seconds.

**Evidence.** `evidence/firstlight-fr-se-truncated.jpg`, and
`evidence/firstlight-se-every-language.jpg` (the same column in all ten
locales on the SE: only French and pseudo truncate). Danish, Spanish and
Italian fit, but leave one word alone on the heading's third line (FORM.,
TI., TE.), which is a typographic call rather than a fault.

**Fixes.**

- **A (recommended).** `.fixedSize(horizontal: false, vertical: true)` on the
  heading and the four lines, so each takes the lines it needs, with the
  column in a scroll view that only scrolls when it must
  (`.scrollBounceBehavior(.basedOnSize)`).
- **B.** Tighten the 26- and 78-point gaps on compact heights.
- **C.** Shorten the French line.

### 8. The small label voice fails the contrast audit

**What happens.** The audit fails the tracked capitals and the faint lines on
every screen that has them, in both appearances: the stage's stage caption
(MATURE), the seed sheet's row labels, Settings' section headings, the
garden's "14 GROWN FROM MEETINGS", Meet's NOT NOW and CANCEL, a plant's place
and date. By arithmetic, `Chrome.faint` in Light (7% black at 52% on the 96.5%
ground) is **3.7:1**, under WCAG AA's 4.5:1; in Dark it is 6.5:1 on black, and
the audit's failures there are most likely the 10- and 11-point light weight,
whose strokes never reach their colour.

**Repro.** `-stage.appearance.v1 light -pgOpen seed`.

**Evidence.** `evidence/contrast-label-voice.jpg`.

**Fixes.**

- **A (recommended).** `Chrome.faint` in Light at 0.60 instead of 0.52
  (about 4.6:1), and the label voice at `.regular` below 12 points.
- **B.** Weight only, colours unchanged.
- **C.** Accept it as the design's quietness, for labels that are never the
  only carrier of meaning.

### 9. With Settings open, VoiceOver reaches the stage underneath

**What happens.** Settings is a layer over the stage, not a presentation, and
the stage's four marks and the plant's name stay in the accessibility tree
beneath it: in every Settings screenshot's element tree, *Seed*, *Meet*,
*Garden*, *Settings* and the plant name sit under Settings' own controls. A
VoiceOver user swiping past the last Settings row lands on controls they
cannot see. (Read from the tree; VoiceOver itself was not driven.)

**Repro.** VoiceOver on, `-pgOpen settings`, swipe right to the end.

**Evidence.** `evidence/screen-analysis.txt`: 84 to 189 "overlaps" per phone,
nearly all of them Settings' rows lying over the stage's marks.

**Fixes.**

- **A (recommended).** `.accessibilityHidden(showingSettings)` on the stage's
  content in `PlantStageView`.
- **B.** `.accessibilityAddTraits(.isModal)` on the Settings layer.

### 10. Buttons read twice

**What happens.** The element tree labels Settings' reset rows "Reset
everything, Reset everything" and "Empty the garden, Empty the garden", and a
plant screen's release mark "Release, Release": a label given both by the
button's text and by an added accessibility label, combined.

**Repro.** `-pgOpen settings`, scroll to *Starting again*, VoiceOver.

**Fixes.** **A (recommended).** One element per control:
`.accessibilityElement(children: .ignore)` with a single label, as
`ChromeMark` already does. **B.** Drop the added label where the text says it.

### 11. Memory kept after closing, and creeping with the clock

**What happens.** In one process, closing the garden left the footprint at
0.37 GB after 14 plants, 0.61 GB after 100 and 1.46 GB after 500 (it started
at 0.16 GB). And while open, each month the clock moved added about 20 MB at
every size, six months running, without levelling off. The bounded stores
(`GardenShadows`: 12 + 16 MB; the sprite cache: 120 pictures) do not account
for either; malloc holding on to the multi-gigabyte peak of finding 1, and
per-season ground or SceneKit caches, are the likely causes. Not confirmed
without Instruments.

**Evidence.** `evidence/stress/*/stress-*.json`: `footprintAfterCloseMB`,
`months[].footprintMB`.

**Fixes.** **A (recommended).** Fix 1A first (it removes the peak malloc keeps),
then one Instruments *Allocations* run over open, turn, a year of months,
close. **B.** Clear `GardenSprites`' cache when the garden closes and on a
memory warning.

### 12. Smaller things

- **Seed sheet on the SE.** At the medium detent the last rows (*First bloom*)
  sit below the screen in every language; they are reached by dragging the
  sheet up. Fix: **A** start the sheet at `.large` on compact heights, or
  **B** leave it.
- **The Testing section cannot be folded from the command line.**
  `Developer` reads `developer.showsSection` through
  `object(forKey:) as? Bool`, and `-developer.showsSection NO` arrives as the
  string "NO", so the argument silently does nothing and, being in the
  argument domain, hides a stored value too. The harness folds it with
  `simctl spawn … defaults write`. Fix: **A** read it with `bool(forKey:)`
  when the object is there, as `-pgTray` already is, or **B** leave it; it
  only matters to screenshots.
- **Known untranslated strings.** Seven keys in `da`, eight in the other six
  languages (the asking flow, and *Newer version in the App Store*) have no
  translation yet; none is on a screen this sweep reached. Already queued for
  the next round in `HANDOVER`.
- **Names fit.** The longest of 100,000 names (*Umbressynth angustifolius*,
  25 characters) sets at 309 of 315 points in the seed screen's 28-point title
  on an SE: six points to spare. Every other size has 40 or more.
- **Tallest plant.** The tallest of 1,000 meshes was 2.57 m against
  `GardenSprites.tallestExpected` of 2.6 m: three centimetres of headroom. A
  taller plant is still drawn whole, only closer to the top.

## SeedCore fuzz

`MassTestFuzzTests` (macOS, `swift test`): a population of 128 minted seeds
meeting at random, each child replacing a random member, so lineages ran up
to 2,715 crosses deep.

| | |
|---|---|
| Crosses | 100,000, twice (400 s and 863 s on the shared Mac) |
| Problems | **0**: encounter and cross symmetric in who knocked first; genome a pure function of seed and parents; every declared range held (petals, nodes, sides, height, layers, curl, head pitch, leaves, teeth, veins, stamens, sepals, branches, tempo, every colour); every `Double` in the genome finite (reflection over one in four); every growth state finite and in range at ages from 0 to 560 days; names non-empty, well spaced, genus capitalised, epithet lower case |
| Determinism | fingerprint over every child's seed, name and height identical across the two runs (`42bd04bc…`) |
| Second implementation | 500 sampled crosses re-derived with Python's `hashlib` (`check_crosses.py`): 0 differ |
| Meshes | 1,000 grown (one in a hundred): none empty, no non-finite vertex, no index out of range; mean 15,446 vertices; tallest 2.57 m |
| Names | 31,905 distinct in 100,000; characters A–Z a–z and space only |

Names repeat by design (they are read from the plant), so a garden of 500
holds a handful of same-named pairs.

## Conditions, and what to trust

- The screen findings are deterministic and do not depend on the machine.
- The performance numbers are a simulator on a shared, heavily loaded Mac.
  Main-thread CPU times are the reliable ones; walls are given where only a
  wall means anything (settling, a turn as felt). Device numbers will differ;
  the shapes (linear in plants, one block, memory per plant) will not.
- The first unoptimised stress run pushed the Mac's swap to 40 GB and filled
  the disk at about 23:00 (the transient of finding 1, multiplied by a
  simulator that never says no). Two screenshots and some result bundles were
  lost and re-taken; from then on `watchdog.sh` held the app to a 5 GB
  footprint.
- XCUITest synthesised taps reached the scene's own recogniser on a plant's
  screen but never opened a plant on the plot, so the plant's screen was
  reached through the developer tile grid (`-developer.showsTileGrid YES`),
  which opens the same `PlantDetailView`.

## Reusing the harness

    zsh tools/masstest/app/build.sh                  # app, unit and UI tests, once
    MT_OPT=1 zsh tools/masstest/app/build.sh         # the same, optimised
    python3 tools/masstest/app/make_garden.py 500 build/mt/fixtures/garden-500.json
    zsh tools/masstest/app/run_tests.sh stress  <udid> build/mt/stress  build/mt/stress.clock  PG_MASSTEST_SIZES=14,100,500
    zsh tools/masstest/app/run_tests.sh screens <udid> build/mt/screens build/mt/screens.clock PG_MT_CONFIGS='en/L/dark;fr/AX5/light' PG_MT_FIXTURES=$PWD/build/mt/fixtures
    zsh tools/masstest/app/run_tests.sh perf    <udid> build/mt/perf    build/mt/perf.clock    PG_MT_SIZES=14,100 PG_MT_FIXTURES=$PWD/build/mt/fixtures
    zsh tools/masstest/app/launch.sh <udid> build/mt/launch build/mt/launch.clock "en/L fr/AX5 rtl/L"
    zsh tools/masstest/app/fuzz.sh build/mt/fuzz build/mt/fuzz.clock
    python3 tools/masstest/app/analyze_screens.py build/mt/screens build/mt/analysis
    python3 tools/masstest/app/contact_sheet.py build/mt/screens/SE sheet.jpg --width 110
    zsh tools/masstest/app/watchdog.sh <udid> watchdog.log 5000 stop-file   # alongside any big garden

Reading results back: `stress_table.py` and `perf_table.py` (the two tables
above; `perf_table.py` wants `xcrun xcresulttool get test-results metrics`
saved beside the hand timings as `metrics-<size>.json`), `sweep_counts.py`,
`progress.py` (where running sweeps have got to), `wait_for.sh` (blocks on
clock files), `launch_sheet.py`, `crop.py` and `side_by_side.py` (evidence),
`collect_evidence.sh` (copies the small results into a report folder),
`check_crosses.py` and `name_widths.swift` (the fuzz's second implementation
and the name widths).

`run_tests.sh` installs over whatever is on the simulator and writes a garden
into it: point it at scratch simulators only. The UI-test target lives in a
project of its own (`tools/masstest/app/masstest.yml`, which includes
`project.yml`), generated as `PeaceGardenMassTest.xcodeproj` at the root and
gitignored like the app's.
