# Handover

Written 30 August 2026, at the end of the session that built this. For whoever
picks it up next — including me, having forgotten all of it.

## What exists

An iPhone and iPad app. A plant grows from a seed drawn once for one person;
two people who meet can cross their seeds by touching phones, and grow a plant
neither could have grown alone. Phase 1 is local plus the exchange. The shared
peace garden is phase 2 and is not started — see [PHASES.md](PHASES.md).

Seven commits on `main`. Read [ARCHITECTURE.md](ARCHITECTURE.md) first; it is
short and it explains the one idea everything else follows from.

## What has actually been verified, and how

This matters more than usual here, because the project was built somewhere that
could not run it.

| | |
| --- | --- |
| **SeedCore** | Compiles and passes its 52 tests on **both** platforms: macOS/arm64 against CryptoKit and Apple's `simd`, and Linux against swift-crypto and the compatibility layer. The two agree, which is what proves the compatibility layer is equivalent rather than merely plausible. |
| **The derivation** | Independently implemented in Python (`tools/reference/`) and executed. Its outputs are pinned into `DerivationVectorTests`. Both implementations agree. |
| **The geometry** | Ported to Python (`tools/preview/`) and run over 120 genomes at seven ages, then *rendered and looked at*. That caught six real defects that no test would have. |
| **Camera framing** | Checked across six viewport shapes, iPhone portrait to a 320pt Split View column. |
| **Everything in `App/`** | Builds, installs and runs, on a device and in the simulator. It needed no source changes to compile — the `@MainActor` and `nonisolated` guesses below were both wrong. |

One function in SeedCore is also uncompiled: `GrowthModel.State.summary()`, which
uses `DateComponentsFormatter` — absent from swift-corelibs-foundation, fine on
iOS.

## Open, in the order I would do it

1. ~~**Build `App/` in Xcode.**~~ Done. It compiled unchanged and ran first
   time — and what it drew was a mushroom. See *The mushroom* below.
2. **Activate the free SSL on peacegarden.app.** My20i → Manage Hosting →
   Options ▸ Manage → Security → SSL/TLS → Activate Free SSL. Up to 30 minutes.
   The domain is registered, DNS is correct and the site answers on port 80;
   only the certificate is missing. Nothing about seed links works until it is
   there, and `.app` is HSTS-preloaded so browsers will not fall back to HTTP.
3. **Upload `Server/.well-known/apple-app-site-association`.** It is written and
   filled in. `Server/README.md` has the command and the rules that quietly
   break associated domains.
4. **GitHub Actions will not allocate a runner.** Both runs died in three
   seconds with `runner_id: 0` and no logs; a re-run did the same. That is
   billing or Actions being disabled, not the workflow — the tests pass locally
   on the same toolchain the workflow uses. Check Settings → Actions → General
   and the account's billing. Public repositories get unlimited minutes.
5. **Delete `claude/plant-seed-exchange-app-8gagec` on `marcusbsorensen/cc-queue`.**
   Superseded; its content is all here. The session that made it could not
   delete it — its git relay refuses a zero-object push.
6. ~~**There is no app icon.**~~ Done, and to the Interfulgent suite system —
   the app is a sixth alongside FreqShift, UnCubed, Pfish, DashLit Diner and
   FlagFans. `tools/icon/make_icon.py` draws it; the outputs are generated, so
   change the script and never touch them. [BRAND.md](BRAND.md) records the
   construction, the measured colour, and **three things the suite document has
   to decide that this app cannot** — chiefly whether Peace Garden is a peer of
   the other five or only wears their system, which bears on the trade mark
   filing. Checked on a home screen beside Pfish, down to 40 points.
7. **Raise the bar to Swift 6 and `SWIFT_STRICT_CONCURRENCY: complete`**, which
   is the house standard in UnCubed. Deliberately *after* the first green build,
   not before: turning both up on never-compiled code buries real errors under
   concurrency diagnostics.

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
swift test --package-path Packages/SeedCore     # 52 tests, macOS or Linux
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
