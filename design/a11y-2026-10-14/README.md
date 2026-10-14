# Accessibility, 14 October 2026

The accessibility findings and the small layout faults of the app's mass test
(`design/mass-test-2026-10-13/app/README.md`, findings 3, 4, 6, 7, 8, 9, 10 and
12), fixed on `claude/a11y-2026-10-14` — Marcus, 14 October: **15A**, all the
accessibility findings; **16A**, the small layout faults. Then the same screen
matrix and accessibility audit run again, before and after.

## What changed

| Finding | What was wrong | What it does now | Where |
|---|---|---|---|
| **3** VoiceOver in the garden | Every plant an unlabelled picture with no action; the tray's 7 figures and 8 grounds unlabelled buttons; the sky and ground more pictures in the way | One element per plant on the plot: its **name**, then what it is doing and who it was grown with (*Mature, with Ines*, the words of its own screen); activating it **opens the plant's screen**, as a tap on its leaves does; a plant somebody has asked to show says so as its hint. Each **light** on the plot is said by name and opens its panel (turn, smaller, larger), which the escape gesture shuts. Carrying is still the long press, passed through with a held double tap; each element's activation point is low on the plant. The tray's figures say what they are, the grounds *Ground 1* to *Ground 8*, the chosen one *selected*. The sky and the plot's pictures are hidden from VoiceOver | `Views/PlotVoiceOver.swift` (new): a layer of its own, computed from the standings and lights the plot is drawn from, moved by the plot's own zoom, pan and lean, equatable so a pan does not rebuild it. `PlotView.swift`: two `accessibilityHidden`, the layer's one call, the tray labels, the panel's escape, and `voiceOver(...)` in an extension at the end of the file. Nothing in the drawing code |
| **4** Dynamic Type | 0 of 1,770 texts grew from Large to the larger sizes | Every text a person reads follows the size setting: `scaledFont(size:)`, and the label, heading and name voices through it, each designed size growing at the rate of the text style nearest it (caption 1 for the small labels, which moves at every step; caption 2 does not move below Large). At Large every screen is exactly what it was. Columns that outgrow the screen **scroll** (`scrollsWhenTooTall()`), and the denser chrome is **capped** — see below. A control's edge is a capsule round one line and a rounded rectangle round more, so a wrapped label is not cut by its own ends. The seed screen's rows put the value under its label once the two no longer fit side by side | `Views/Chrome.swift` (`ScaledSystemFont`, `scrollsWhenTooTall`, `ControlEdge`, the caps), and one line per text in every view that sets its own type |
| **4** (and the follow-ups' note) Capitals read aloud | VoiceOver was handed *LOCATION DESCRIPTION* and read it as capitals, letter by letter for some words; an explicit `Text` label beside it was capitalised too | The capitals are drawn, not read: the shared letter-case style gives VoiceOver the same words in the case they were written in, so every tracked heading and label in the app is read as words | `ChromeLetterCase` in `Views/Chrome.swift`: one `accessibilityRepresentation` |
| **6** Right to left | The tray's fade and » stood over the first figure; the row ran off the other edge unfaded; the foot was half mirrored | Each tray row fades and points on the side of the glass it actually runs on past. The foot mirrors as one row: the plus and the turns trade corners with *Reset view* and the light, and the turn pair keeps its own order and its arrows, because a turn is the plot's direction. The plot itself still does not mirror | `Views/PlotTray.swift` (`ContinuingRow`), `PlotView.controls`, `GardenControlsTests`, `docs/ARRANGING.md` |
| **7** First light on the SE | French and pseudo-long squeezed a line to *…ense…* | Each line takes the height it needs and the column scrolls only when it must | `Views/FirstLightView.swift` |
| **8** The small label voice's contrast | `Chrome.faint` in Light 3.7 : 1 | `faint` in Light at 0.60: **4.8 : 1** (Dark 6.5 : 1, unchanged). The label voice is regular rather than light below 12 points, so its strokes reach their grey. The garden's count line, which stands on the sky, is `muted` | `Chrome.faint`, `chromeLabel`, `PlotView.header` |
| **9** VoiceOver behind Settings | Settings is a layer over the stage, and the stage's marks, plant name and caption were in reach beneath it | The stage's words, marks, first-meeting panel and Share mark are hidden from VoiceOver while Settings is open. (A modal trait on the layer was tried and taken out: it collapsed the whole tree under Settings to its Close.) | `Views/PlantStageView.swift` |
| **10** Read twice | *Reset everything, Reset everything*, *Empty the garden…*, *Release, Release* | The copy of the label the fill wipes across is hidden; every held row is read once | `HoldToConfirm` in `Views/Chrome.swift` |
| **12** The seed sheet on the SE | Half way up, its last rows sat below the fold | It opens the whole way on a phone the height of an SE and at any type size above the default, half way everywhere else; either way it drags to the other | `PlantStageView.openSeed()` |
| **12** `-developer.showsSection NO` | Arrived as the string "NO", read by `as? Bool`, so it did nothing | Read with `bool(forKey:)` when anything is stored, as `-pgTray` is | `Developer` in `Views/DeveloperControls.swift`; the harness's comment |

After the follow-ups were merged (About, *Not this time* on Meet, Share on the
stage, the time-lapse share): the stage's Share mark is hidden behind Settings
too, the About sheet's type scales (its header capped at AX1, as Settings'),
and the sweep photographs and audits the About sheet (`about`, `about-end`).

**Strings.** Eight new ones, all spoken by VoiceOver and never drawn: the seven
lights (*Lantern, Paper lamp, Fireflies, Hare, Fox, Moth, Snail*) and *Ground
%lld*. Danish translated (*Lanterne, Papirlampe, Ildfluer, Hare, Ræv,
Natsværmer, Snegl, Terræn %lld*), the other six `needs_review`; comments say
what each is. `tools/strings/check.py` and `tools/strings/app_check.py` clean.

## Where Dynamic Type stops, and why

Everything not listed grows to AX5. Each cap is a `dynamicTypeSize(...)` with
the reason beside it in the code.

| What | Grows to | Why |
|---|---|---|
| The label voice (tracked capitals, 10–12 pt) | AX3 | The widest type in the app; past AX3 a long Danish or Dutch word no longer fits an SE's column and breaks mid-word |
| The heading voice, and the mark beside a title | AX2 | The same at a larger size: at AX5 *ONTMOETEN* and *PRENDENDO* broke mid-word; at AX2 a heading is already twice its Large size |
| The word beside a mark (the stage's row, a plant's row) | XL, then shrinks to 80 % | One word at a time leaves about 140 points beside three other marks on an SE; *INSTÄLLNINGAR* takes 119 at Large |
| Word buttons in a capsule (*Not now*, *They don't have the app*, *Not this time*) | AX1 | Past AX1 the longest takes three lines in its capsule |
| The held rows (Settings' three resets, *Release*) | AX2 | The fill wipes across a pill; at AX2 the longest label is still one line on an SE |
| Settings' and About's pinned header | AX1, and the title shrinks to fit one line | The band stays over the scroll, so every point it grows is a point less of Settings; *INDSTILLINGER* was cut letter by letter |
| The garden screen's words (heading, count, asking line, the empty-garden note, the tray's light control) | AX1 | The plot is framed in the sky between the heading and the foot; past AX1 the heading alone came down over the plot |
| A plant's screen (name, meeting, standing, the release sentence) | AX2 | The words stand above and below a plant that cannot move out of their way; with the release sentence out, an SE's foot is full at AX2 |
| The first-meeting panel on the stage | AX2 | A panel over the plant, not a page; at AX2 it already covers most of an SE |
| The words under a new plant after a meeting | AX1 | The plant is the point of the moment and stands in what the words leave. **Not photographed**: it needs a real meeting |

Not scaled at all, on purpose: glyph-only controls (the X, Share, play, the
tray's marks, the drawing marks — their labels are read, and their rings are
the targets), and the Testing section (English, developers only). The launch
nameplate already scaled.

## Before and after

The mass test's own matrix, on scratch simulators (`pg-a11y-SE` iPhone SE 3rd
generation, `pg-a11y-Air`, `pg-a11y-ProMax` iPhone 17 Pro Max; no iPhone 17
Pro), Debug build, iOS 26.5: **SE** 10 locales at Large Dark and at AX5 Light,
and en, fr, pseudo-long, right to left at AX3 Dark; **Air** 10 locales at Large
Light, and en, it, pseudo-long, right to left at XXXL and AX3 Dark; **Pro Max**
10 locales at AX5 Dark and English at Large Light. Screens: first light, the
stage, the seed sheet, Meet, Settings (top and end), the garden with the tray
open, a plant's screen; after, the About sheet as well (top and scrolled).
`performAccessibilityAudit(for: .all)` on every screen in en, fr, it,
pseudo-long and right to left. 53 configurations, 424 screens before, 530
after.

**Before** is local `main` at `19c0c1a`, swept this morning. **After** is this
branch with the follow-ups merged: the Large and XXXL runs from the build of
10:45, their stage screens and the Air's XXXL seed screens again from the final
build, and every AX3 and AX5 run from the final build (the capitals' caps
change those sizes only). The counts compare only the screens both sweeps
photographed; the About sheet has lines of its own at the end.

#### SE

| | before | after |
|---|---:|---:|
| Audit: element with no description | 658 | 0 |
| Audit: contrast | 286 | 111 |
| Audit: Dynamic Type unsupported | 787 | 0 |
| Audit: Dynamic Type partially unsupported (capped or reflowing) | 0 | 290 |
| Audit: text clipped | 49 | 10 |
| Overlapping words on Settings (the stage beneath it; see note) | 222 | 226 |
| Overlapping words anywhere else | 0 | 3 |
| Labels unmoved under right to left | 3 | 0 |
| Texts that grew, L to XXXL/AX3/AX5 | 0 of 1182 | 1166 of 1216 |

#### Air

| | before | after |
|---|---:|---:|
| Audit: element with no description | 611 | 0 |
| Audit: contrast | 203 | 90 |
| Audit: Dynamic Type unsupported | 884 | 0 |
| Audit: Dynamic Type partially unsupported (capped or reflowing) | 0 | 278 |
| Audit: text clipped | 98 | 20 |
| Overlapping words on Settings (the stage beneath it; see note) | 134 | 126 |
| Labels unmoved under right to left | 3 | 0 |
| Texts that grew, L to XXXL/AX3/AX5 | 0 of 588 | 576 of 604 |

#### ProMax

| | before | after |
|---|---:|---:|
| Audit: element with no description | 288 | 0 |
| Audit: contrast | 103 | 42 |
| Audit: Dynamic Type unsupported | 421 | 0 |
| Audit: Dynamic Type partially unsupported (capped or reflowing) | 0 | 144 |
| Audit: text clipped | 40 | 4 |
| Overlapping words on Settings (the stage beneath it; see note) | 82 | 142 |
| Labels unmoved under right to left | 1 | 0 |

#### All three phones

| | before | after |
|---|---:|---:|
| Audit: element with no description | 1557 | 0 |
| Audit: contrast | 592 | 243 |
| Audit: Dynamic Type unsupported | 2092 | 0 |
| Audit: Dynamic Type partially unsupported (capped or reflowing) | 0 | 712 |
| Audit: text clipped | 187 | 34 |
| Overlapping words on Settings (the stage beneath it; see note) | 438 | 494 |
| Overlapping words anywhere else | 0 | 3 |
| Labels unmoved under right to left | 7 | 0 |
| Texts that grew, L to XXXL/AX3/AX5 | 0 of 1770 | 1742 of 1820 |
| **Audit issues in all** | **4428** | **989** |

#### Screens only in the after sweep: about, about-end

| | after |
|---|---:|
| Audit: contrast | 11 |
| Audit: text clipped | 27 |
| Texts that grew, L to XXXL/AX3/AX5 | 180 |

Labels read twice (`read_twice.py`, pseudo-long left out): **322 before, 0
after**. The 78 texts that did not grow are all the held rows' labels, which
the analyser compares with the row's own element of the same name; the label
itself goes from 18 to 32 points high at AX3 on the SE. *Words past an edge of
the window* is 0 in both: the analyser now counts words below a scroll view's
fold as scrollable rather than off screen, which is what the seed sheet's
rows on the SE were before (finding 12 is in `seed-sheet-SE.jpg` instead).
The three overlaps *anywhere else* are a far plant's VoiceOver box reaching up
under the garden's count line at AX5 (Dutch and pseudo-long), not words on
words; the plot's own elements overlapping one another, and not mirroring,
are by design and left out.


## Contact sheets

| Sheet | What it shows |
|---|---|
| `dynamic-type-SE-before-after.jpg` | iPhone SE, every screen: English at Large and French at AX5, before and after. At Large nothing moved; at AX5 everything grew, and the columns scroll |
| `SE-AX5-every-language-after.jpg` | iPhone SE at AX5, Light, all ten locales, every screen including About: no clipped or overlapping words |
| `SE-AX3-after.jpg` | iPhone SE at AX3, Dark: English, French, pseudo-long, right to left |
| `Air-XXXL-AX3-after.jpg` | iPhone Air at XXXL and AX3, Dark: English, Italian, pseudo-long, right to left |
| `ProMax-AX5-every-language-after.jpg` | iPhone 17 Pro Max at AX5, Dark, all ten locales |
| `voiceover-garden.jpg` | What VoiceOver finds in the garden, each element's frame drawn over the photograph: the plants (pink, name and value) and every control (blue). Air by day, SE by night |
| `first-light-SE.jpg` | Finding 7: French and pseudo-long on the SE, before (*…ense…*) and after |
| `rtl-garden-foot-SE.jpg` | Finding 6: the garden's foot left to right, and right to left before and after |
| `seed-sheet-SE.jpg` | Finding 12: the seed sheet on the SE at Large and in Danish at AX5, before (half way, rows under the fold) and after |
| `contrast-faint-light.jpg` | Finding 8: the seed sheet's labels in Light, `faint` at 0.52 and light, then at 0.60 and regular |
| `about-sheet-after.jpg` | The About sheet (new today) at Large, AX3 and AX5, left to right and right to left |


## What a sweep cannot see

- **The test's element tree is not VoiceOver's.** XCUITest's snapshot still
  lists elements hidden from VoiceOver — the stage under Settings, the plot's
  pictures — so the analyser's *overlapping words on Settings* is the stage
  beneath it in both columns. `AccessibilityTests.testTheStageIsHiddenBehindSettings`
  walks the tree VoiceOver walks and finds none of it. The audit itself
  skipped the hidden pictures (no undescribed element is left).
- ***Dynamic Type partially unsupported*** is the audit's word for a text that
  grows and then stops — every cap above — or that reflows on the way (the
  seed screen's rows going from side by side to stacked). Before, nothing
  grew, so there was no *partially*.
- ***Text clipped*** is a prediction, as the mass test said: every one after
  reads *may be clipped at larger Dynamic Type sizes*, nearly all of them on
  the Large and XXXL runs. At the sizes photographed, AX3 and AX5 on the SE,
  the contact sheets show no clipped or overlapping words.
- **Contrast.** By arithmetic `faint` is now 4.8 : 1 in Light and 6.5 : 1 in
  Dark. The audit samples pixels, and still fails the small light-weight
  capitals in places — a plant's place and date over its veil, the stage's
  caption, the seed screen's labels, the garden's count over the sky, and the
  first light's last line while it is still fading in. Tried and put back:
  `faint` at 0.64 in Dark and 0.66 in Light changed none of those results, so
  what fails them is the thin, tracked type and what is behind it, not the
  grey. See *For Marcus*.

## For Marcus

1. **The foot now mirrors** under right to left (finding 6's fix A), which
   undoes the 11 October pinning of the plus and the turns. The turn pair keeps
   its order. One line in `PlotView.controls` puts the pinning back.
2. **Eight new spoken strings**, where `LampKind` said a light is never named
   because a named light is forty-two translations: no system symbol names a
   paper lamp, a fox or a snail, and unlabelled buttons were the finding. The
   grounds are counted, not named. Worth a glance at the Danish, *Natsværmer*
   and *Terræn*.
3. **Contrast past the arithmetic**: the remaining audit failures are the
   label voice's thin capitals. Regular weight from 12 points up, or `muted`
   for the place and date on a plant's screen, would clear most of them, at
   some cost to the quiet.
4. **The seed sheet opens whole** on an SE and above the default type size,
   so the plant its drawing marks change is behind it until the sheet is
   dragged down.
5. **Performance**: `PlotVoiceOver` adds one list of the plot's plants and
   lights to each evaluation of the garden's body (no genome is derived for
   it; the names are read only when the layer redraws). The other agent's
   rendering work may want to build it only when an assistive technology is
   running.

## Reusing

    zsh tools/masstest/app/build.sh                    # MT_LOCK="sh <lock>.sh" on a shared Mac
    zsh tools/masstest/app/run_tests.sh screens <udid> <out> <clock> PG_MT_CONFIGS='fr/AX5/light' \
        PG_MT_SCREENS=stage,seed,meet,settings,about,garden,plant,firstlight PG_MT_FIXTURES=<dir> PG_MT_AUDIT=all
    python3 tools/masstest/app/analyze_screens.py <sweep> <analysis>
    python3 tools/masstest/app/before_after.py <analysis before> <analysis after>
    python3 tools/masstest/app/read_twice.py <sweep>
    python3 tools/masstest/app/draw_elements.py <screen.jpg> <screen.json> <out.jpg> --labels buttons
