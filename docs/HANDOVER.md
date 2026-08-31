# Handover

Written 30 August 2026, at the end of the session that built this. For whoever
picks it up next — including me, having forgotten all of it.

## What exists

An iPhone and iPad app. A plant grows from a seed drawn once for one person;
two people who meet can cross their seeds by touching phones, and grow a plant
neither could have grown alone. Phase 1 is local plus the exchange. The shared
peace garden is phase 2 and is not started — see [PHASES.md](PHASES.md).

Ten commits on `main`. Read [ARCHITECTURE.md](ARCHITECTURE.md) first; it is
short and it explains the one idea everything else follows from.

## What has actually been verified, and how

This matters more than usual here, because the project was built somewhere that
could not run it.

| | |
| --- | --- |
| **SeedCore** | Compiles and passes its 53 tests on **both** platforms, at Swift 6 language mode: macOS/arm64 against CryptoKit and Apple's `simd`, and Linux against swift-crypto and the compatibility layer. The two agree, which is what proves the compatibility layer is equivalent rather than merely plausible. |
| **The derivation** | Independently implemented in Python (`tools/reference/`) and executed. Its outputs are pinned into `DerivationVectorTests`. Both implementations agree. |
| **The geometry** | Ported to Python (`tools/preview/`) and run over 120 genomes at seven ages, then *rendered and looked at*. That caught six real defects that no test would have. |
| **Camera framing** | Checked across six viewport shapes, iPhone portrait to a 320pt Split View column. |
| **Everything in `App/`** | Builds, installs and runs, on a device and in the simulator, at Swift 6 with complete concurrency checking. |
| **The arrival** | Recorded off the simulator and stepped through frame by frame, five times. That is what shaped it; see below. |

One function in SeedCore is also uncompiled: `GrowthModel.State.summary()`, which
uses `DateComponentsFormatter` — absent from swift-corelibs-foundation, fine on
iOS.

## Where the second 31 August session left off

Two commits, both driven and watched on an iPhone 17 Pro Max simulator.

- **The seed is seen opening, once.** Six seconds on the day a seed is sown:
  the case splits along a horizontal seam, the lid tips and rides up on the
  shoot and goes, the cup stays and fades, and the camera draws back from the
  seed to the plant's own framing. `GerminationView` drives it, `SeedHusk`
  draws it, and `RootView` runs it between first light and the stage. It says
  nothing, it can be tapped past, and Reduce Motion skips it.
- **The pool of light follows the plant.** `StageBackdrop` takes a `presence`
  — `heightScale`, which is already exactly that number — and sizes its glow
  from it. A seedling stands in a small close pool and grows into a wide one.
  A mature plant is unchanged.
- **The name is asked for at the first meeting**, on the way into Exchange,
  where there is at last somebody for it to be for. First light asks for
  nothing. `GardenModel.shownName` falls back to Gardener until then.
- **Swift 6 and `SWIFT_STRICT_CONCURRENCY: complete`**, app and core. 53 tests
  still pass.

### What the renders caught, and what they cost

The husk went through five passes on the simulator before it read as
germination. Worth knowing which, because each one is a thing a test would
have called correct:

1. SeedCore's own husk cannot do this. It is measured against the shoot — the
   mushroom fix — so it shrinks with the shoot and there is never a seed
   sitting there. Rendering the range in `tools/preview` settled that in one
   look. `SeedHusk` is a seed with a size of its own.
2. A pale seed at that size is a boulder. The coat is held to absolute values,
   tinted by the plant rather than scaled off it.
3. Two halves opening equally is a locket. The lid does nearly all the moving.
4. The lid wants both sides lit and the cup wants one. Culled, a tipped lid is
   a wire crescent; double-sided, the cup shows its far wall as stripes.
5. `SkeletonBuilder` floors a stem at a centimetre however far the arrival
   winds it back, and a genome may be tall and thin — those had a spike out of
   the top of a closed seed. The plant is kept hidden until the seam opens,
   which is one rule instead of arithmetic against two unrelated traits.

### Not verified, and why

**The exchange screen was never reached.** Injected taps on the Seed / Meet /
Garden row register as gesture actions in the log and cancel the controls'
hide task — so the buttons *are* being pressed — but the `fullScreenCover`
does not present. That wiring is untouched since `1fda816`, so it is not a
regression from this work, but it does mean three things went unlooked-at:
the naming step, `UnfurlingBackdrop(.pair)` over the exchange screen's own
content, and the first-meeting passage. Worth reproducing by hand on a device
before assuming it is only the harness.

## Where the first 31 August session left off

The app builds, runs and has been driven on an iPhone 17 Pro Max simulator
throughout. `main` carries eight commits from that session. What is live:

- **The mushroom is gone** — the husk was sized from the mature stem's radius
  while the shoot is drawn at a fraction of it. See *The mushroom* below.
- **The app icon** is drawn to the Interfulgent suite system. [BRAND.md](BRAND.md).
- **A three-beat walk-through** — a seed taking form, a plant that can meet
  others, two plants making a seed — each retiring itself once its function has
  been used, off `model.hybrids.isEmpty` rather than a stored flag.
- **The first screen unfolds a line at a time**, each waiting on the one before
  it to be read; `readingBeat` sets the gap from the word count.
- **The plant is framed against what it will grow into**, and aimed at its own
  middle, so a seedling is small and centred and opens outward for weeks.
- **A gold frond unfurls** behind first light, and a pair behind the exchange.
- **96 passages** with provenance, chosen from the child seed.
- A [visual language canvas](https://claude.ai/code/artifact/cae29da5-67e8-49a9-b275-b28df64fb54f)
  covering direction, palette, type, voice, motion and marks.

### Open, and worth doing next

1. ~~**The seed sprouting out of its husk, with a focus-in.**~~ Done.
2. ~~**The pool of light and the plant have come apart.**~~ Done: the light
   follows the plant.
3. **`UnfurlingBackdrop(.pair)` has not been seen over the exchange screen's own
   content.** It was measured thoroughly in isolation; nobody has looked at it
   in place. Blocked on reaching that screen — see *Not verified* above.
4. **`suite-brand.md` is edited and uncommitted in `uncubed-integration`**, which
   sits on `drawings-by-identity` with unrelated work in flight. It adds Peace
   Garden to §1, §2, §3.4 and §3.5.
5. ~~**The name field is still on the first screen.**~~ Done: it is asked for
   at the first meeting.
6. **The passages are placed but the screen is not tuned** — the first-meeting
   reveal has not been seen with a real exchange behind it. Same blocker as 3.
7. ~~**First light has a large gap under the sprouting rule.**~~ Done: the
   words, the rule and the button are one column between two spacers.

## Open, in the order I would do it

1. ~~**Build `App/` in Xcode.**~~ Done. It compiled unchanged and ran first
   time — and what it drew was a mushroom. See *The mushroom* below.
2. ~~**Activate the free SSL on peacegarden.app.**~~ Done, and verified:
   `https://peacegarden.app/` presents a certificate that validates. The site
   answers 403 to a bare GET, which is the host's default for a directory with
   nothing in it and not a TLS problem.
3. **Upload `Server/.well-known/apple-app-site-association`.** Still 404, and
   now the only thing between here and working seed links. It is written and
   filled in. `Server/README.md` has the command and the rules that quietly
   break associated domains.
4. **GitHub Actions would not allocate a runner** — and it was not the
   setting. `/actions/permissions` read `enabled: true, allowed_actions: all`
   while every job came back `runner_id: 0` with an empty `steps` array, which
   is what a private repository out of included minutes looks like. **The
   repository is public now**, which is unlimited. Nothing has been pushed
   since, so the next push is the test of it — if a runner still refuses to
   start, it is not billing after all.
5. ~~**Delete `claude/plant-seed-exchange-app-8gagec` on
   `marcusbsorensen/cc-queue`.**~~ Done, via the API rather than a push.
6. ~~**There is no app icon.**~~ Done, and to the Interfulgent suite system —
   the app is a sixth alongside FreqShift, UnCubed, Pfish, DashLit Diner and
   FlagFans. `tools/icon/make_icon.py` draws it; the outputs are generated, so
   change the script and never touch them. [BRAND.md](BRAND.md) records the
   construction, the measured colour, and **three things the suite document has
   to decide that this app cannot** — chiefly whether Peace Garden is a peer of
   the other five or only wears their system, which bears on the trade mark
   filing. Checked on a home screen beside Pfish, down to 40 points.
7. ~~**Raise the bar to Swift 6 and `SWIFT_STRICT_CONCURRENCY: complete`.**~~
   Done, app and core. Three diagnostics, all the same one: `NSCache` and
   Multipeer's types are documented thread-safe and simply predate `Sendable`.
   They are marked `nonisolated(unsafe)` with a note saying why, which leaves
   the next reader looking at the real question — whether the hop to the main
   actor is deliberate. It is, in each case.

## Decisions that are settled

Not because they cannot change, but because they were argued once and the
reasoning is written down. Don't redo them by accident.

- **A plant is a seed plus a birthday. Everything else is derived.** No
  appearance is ever stored, sent or synced. This is why two phones agree with
  no server, why a garden is kilobytes, and why a saved plant cannot drift.
- **Traits are drawn by name, not by position in a stream.** Adding a trait in a
  later version must not shift the ones already growing on someone's phone.
- **The tap is a gesture, not a transport.** iOS gives no NFC peer-to-peer
  between iPhones. Accelerometers recognise the knock; Multipeer carries the
  seeds. [EXCHANGE-PROTOCOL.md](EXCHANGE-PROTOCOL.md).
- **A reply link echoes the offer's nonce back.** That is what makes replies
  self-contained, so the sender need not have kept a record of an offer made
  weeks ago. [SEEDS-ON-THE-WIND.md](SEEDS-ON-THE-WIND.md).
- **The link payload rides in the URL fragment**, which never reaches a server.
- **Bundle identifier `app.peacegarden`.** Reverse-DNS of the domain, matching
  the house pattern. Permanent once App Store Connect sees a build.
- **SceneKit, not RealityKit.** The core emits plain vertex buffers, so moving
  is a rewrite of `PlantSceneBuilder.swift` and nothing else.

## The mushroom

The first plant ever drawn on a phone came out as a wide brown dome sitting on a
stub. Three things, none of them the port:

- **The husk was sized from the mature stem.** `PlantBuilder.addStem` took
  `genome.stem.baseRadius * 2.4`, but `SkeletonBuilder` draws a young stem at
  `0.4 + 0.6 * heightScale` of that radius. On the day a seed is sown those
  differ five-fold, so the seed case came out three times wider than the whole
  plant was tall and swallowed it. It is now measured against the shoot as it
  is, and capped against the shoot's length so it can never be the tallest thing
  on the plant.
- **`heightScale` had a floor of 0.02.** The ramp under it is measured in days,
  so across the germination *hours* it barely moves: whatever the floor is, that
  is the plant its owner meets. Now 0.055.
- **`PlantSceneBuilder.framing` floored the plant's *extent* at 3cm.** Meant as a
  guard against a degenerate mesh, it silently asserted every plant is at least
  a handspan across — true of a mature one, false of every seedling, which was
  then pushed away and drawn as a speck. The guard is on the distance now.

**How it survived.** `tools/preview` renders the whole life and was looked at,
but its stage row started at day 0.2, by which point the shoot has grown out of
the husk. The one frame nobody had ever rendered was the one every person sees
first. The row now starts at day 0, and
`testAFreshlySownSeedLooksLikeAShootAndNotAMushroom` covers the first six hours
across 120 genomes. Worth remembering that the gap was in *which* moments were
checked, not in how carefully any of them were.

## Traps

- **The trait label strings are the file format.** Renaming `"stem.height"` is a
  breaking change to every plant that exists. Same for the domain tags in
  `SeedDomain` — add a `.v2`, never edit a `.v1`.
- **`tools/preview/` will drift.** It is a Python port of the genome and the
  geometry, kept because it renders plants anywhere. `SeedCore` is
  authoritative. `tools/reference/` is different: it is a second implementation
  of the derivation *on purpose*, and CI runs it so the two cannot disagree
  silently.
- **If a petal's tip colour appears at its base**, flip the row order in
  `GradientTexture.image(for:palette:)`. The comment is on the line.
- **The AASA file has no extension, must be served as `application/json`, and
  must not redirect** — not even http to https. Apple's CDN caches it for up to
  a day, so get it right before testing rather than iterating against it.

## How to check things

```sh
swift test --package-path Packages/SeedCore     # 53 tests, macOS or Linux
python3 tools/reference/derivation_reference.py # the derivation, independently

cd tools/preview && pip install numpy pillow
python3 preview.py --seeds 12 --out sheet.png          # twelve plants
python3 preview.py --seed hello --stages --out row.png # one plant over its life
python3 preview.py --cross ada marcus --out cross.png  # two parents and a child
```

## What I would do next, after the list above

Phase 2 is the shared garden, and [PHASES.md](PHASES.md) sets out the questions
it has to answer before any of it is built — chiefly what identity a shared
garden needs when phase 1 deliberately has none, and the moderation surface that
guest books bring with them. Neither is a coding problem.

Before that, the cheapest real improvement is an App Clip, because it changes
how the app spreads rather than what it does: a seed scanned by someone who has
never installed anything, growing on their phone seconds later.
