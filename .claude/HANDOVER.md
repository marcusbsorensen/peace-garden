# Peace Garden — handover 16 September 2026

## Goal

Get the app and site launch-ready. Forty-one of the forty-two language maps are
named and live; the naming is finished and **the reading has barely started**.
That ratio is the whole of the remaining language problem.

## State

`main` at `6971358`, pushed. peacegarden.app carries all of it, last deployed
6 September: thirteen paths checked at the far end and all forty-one named maps
read back off the origin key by key, no mismatches.

**The working tree is not clean**, and holds three separate pieces of work, all
verified and none committed:

1. **The marks at the foot of the stage are bigger.** See below.
2. **Two Danish corrections from a native reader.** `growTitle` and `growBody`
   in `Server/strings/da.json`, and the seed-on-the-wind share text in
   `Localizable.xcstrings`. `growBody` had drifted: the English says the plant
   *stays the same for as long as you do*, a claim about time, and the Danish
   had become *identisk for begge parter*, a claim about the two of you. The
   reader's version restores it. *Fredshave* was left standing in all three app
   keys — the site never translates the name, the app does, and that is a
   separate decision nobody has taken.
3. **The receptacle.** The join between a flower and the tip it grows from was
   never closed; `docs/PLANT-FORMS.md` §"The one join that was never closed"
   has the whole of it.

**The latest build is on MBS iPhone**, installed 16 September from `6971358`.

**Verified** — 97 SeedCore tests, 28 app tests, six Python checks (`app_check.py`
is new and is the sixth), all re-run against the bigger marks. The numeral rule
driven on the simulator at all three numbers: *One grown from a meeting*, *2
grown from meetings*, *One character left* at 239 of 240, *0 characters left* at
240. One packet link driven end to end on the origin.

**The receptacle** — 97 SeedCore tests after raising the three pinned vertex
counts in `testAFixedSeedAlwaysDrawsTheSameMesh`, whose widths and heights did
not move; all six Python checks; and the join looked at through
`tools/preview/preview.py`, which carries the same change so it cannot drift.

**The bigger marks, verified on an iPhone 17 Pro simulator** — collapsed,
unrolled, and in *Marks and words*; English and Swedish, the widest language;
Garden opened on the second tap, so the unroll-then-open path still works at the
new geometry. `measure.swift` carries the row's real furniture and reports 0
over at 402 points and at an SE's 375.

**Unverified** — 410 of the 420 area names, and every translation. Danish is the
only language anybody has read; `check.py` prints the count on every run.

## Files

| | |
| --- | --- |
| `App/PeaceGarden/Views/PlantStageView.swift` | the stage. `mark()` at :293 builds one foot mark and passes its insets at :316; the row is :224–233; the name/stage block above it ends `.padding(.bottom, 16)` at :220; the band's own `.padding(.bottom, 30)` at :255 |
| `App/PeaceGarden/Views/Chrome.swift` | `ChromeIconLabel.glyphSize` default **28** at :1013, applied at :1047. `pressable()` at :525 makes the circle — `.padding(.horizontal, h)` and `.padding(.vertical, v)` under a `Capsule()`, both passed in |
| `tools/type/measure.swift` | the row's furniture, per language, against 402 points or any width passed in |
| `docs/COMMISSIONING-THE-READS.md` | how the forty-one get read, and why not MTurk |
| `tools/strings/app_check.py` | the numeral rule, sixth CI check |
| `tools/strings/NAMING.md` | the brief, now with five corrections its own commissions found |
| `out/review/` | 43 sendable packets, minted 6 September against the live site |

## Decisions made

- **Kalaallisut is deliberately unnamed.** Ten compounds built from affixes that
  cannot be checked would be obvious to every one of its readers. It falls back
  to English per name, which is what that fallback is for.
- **MTurk is the wrong market** for the reads — pays per task, text work widely
  routed through MT, pool absent for a third of the list. Prolific for the bulk,
  one translator each for the nine small languages.
- **`appNote` sharing a sentence with `about3` is not a fault.** They sit in
  mutually exclusive sections of `/s`; no reader sees both.
- **Enforcement of the numeral rule is not in `check.py`.** The site's forty-two
  catalogues carry no numerals at all — the whole exposure is the app.

## The marks, done

The four marks at the foot of the stage were a 15-point glyph in a capsule 41 by
39 — a target under the 44 a target is meant to be, and a drawing under half of
its own circle, which is why the seed and the cog read as specks. Now **28 in a
48-point circle**, which was two faults and so was raised as two numbers:

- `ChromeIconLabel.glyphSize` 15 → 28 (`Chrome.swift:1013`). It is used in one
  place, the stage row, so the default is the row's size.
- `pressable()` gained a `vertical:` (`Chrome.swift:525`), defaulting to the 12
  it always had. The other nine callers are buttons inside panels and were left
  where they were; growing every button in the app was not what the row needed.
- The stage passes **10 all round** collapsed, and 18 horizontal once a word
  unrolls (`PlantStageView.swift:316`). Ten and ten is what makes 28 into a
  round 48; eighteen is because a 48-point capsule's cap curves through 24, so a
  word set at ten would start inside its own end.
- `measure.swift`'s furniture follows the real geometry, and `docs/LANGUAGES.md`
  §Type carries the new per-language worst cases.

**The gap above the row did not need raising.** `.padding(.bottom, 16)` at
`PlantStageView.swift:220` is untouched: the capsule grows downward from a fixed
top edge, so the clearance from the plant name never closed. The band is 9 points
taller, which the plant gives up — looked at, and the framing holds.

## Next step

**The reading.** The first prose read of any language has now happened — Danish,
by a native speaker, two corrections above. `Server/strings/da.json`'s `read`
block still credits only the ten area names to me on 6 September, so
`check.py` still says *1 of 42*. **It needs her name and today's date**; I have
not invented either.

Forty-one named maps, one read. That ratio is still the whole of the remaining
language problem and nothing above changes it.
`docs/COMMISSIONING-THE-READS.md` is the plan: Prolific for the bulk, one
translator each for the nine small languages, and `out/review/` already holds 43
sendable packets minted against the live site on 6 September. 410 of the 420
area names are still unverified.

## Traps

- **The marks do not answer injected taps** — SceneKit's gesture recogniser, not
  injection generally. Use `xcrun simctl launch <udid> app.peacegarden -pgOpen
  settings|garden|seed|meet`.
- **To get a plant on the simulator**: settings → scroll to the foot → *Meet an
  imaginary gardener* → *Meet as gardener* → tap for the knock → *Plant in peace
  garden*. That is a real crossing and leaves a real plant.
- **A plant page opens with its chrome hidden** when Menu bar is *Hidden*, the
  default. One tap on the background reveals it.
- **`xcodebuild` to the phone fails over Wi-Fi** — the developer disk image will
  not mount. Build `generic/platform=iOS` and install with `xcrun devicectl
  device install app --device <id> <path>.app`. That works.
- **Never `pkill -f CoreSimulator`.** Recovery is `killall -9
  com.apple.CoreSimulator.CoreSimulatorService`.
- **`mintlink.py --packets` now refuses a localhost base.** It used to obey one
  and write forty-three unsendable files that looked perfect.
- **A 200 with the wrong `Content-Type` is this site's whole failure mode.** Run
  `tools/deploy.sh --check` rather than trusting an upload.
- **`/api/count` 404s locally** — the plot service being absent, not a fault.
- **`AREA_KEYS` must stay below `export const KEYS` in `strings.js`**, or
  `commission.py` parses it as ten catalogue entries.
- **`cd` persists between Bash calls.** Pass absolute `--package-path`.
- **The mesh *is* pinned**, and not where you would look for it:
  `PlantFormTests.testAFixedSeedAlwaysDrawsTheSameMesh`, not `PlantMeshTests`.
  Any change to the geometry moves three vertex counts. Its own note says it is
  a change-detector rather than a contract, so raising them is the right answer.
- **`tools/preview/plant_model.py` is a hand port of SeedCore and has drifted
  three times.** Change geometry in one and change it in the other in the same
  breath; its README is emphatic about why.
- **The shell here is zsh, which does not split an unquoted `$var`.** A loop over
  `"tools/site/export.py --check"` hands python one filename with a space in it
  and reports a failing check that passes when it is run on its own.
