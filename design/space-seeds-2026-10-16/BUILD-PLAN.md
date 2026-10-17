# Zone C: build plan

16 October 2026. **Planning only: this branch writes no app, server or site code.** Built from `DESIGN.md` (decisions final, §7 and §8), `.claude/HANDOVER.md` and a read of the code. Package IDs: **S** server, **F/C** the look and SeedCore, **A** app, **W/T** site and app words, **X/H/B** CI and docs, messages, the build. "Needs" lists what must be merged first. Sizes: S one commit, M a few hours of agent time, L several commits.

## 1. How it runs

- **Spending.** Sonnet for every package. Opus once, to read A2's diff (crypto fails silently, so a second reader earns its cost). At most 2 local agents at a time.
- **Cloud.** S1–S3, S5, W1, W2, T1's language routines and X1 need only PHP, Python or Node, so they can run as cloud routines (`~/.claude/CLAUDE.md`, "Running work in the cloud": push first, one routine per job, strip the connectors, set the model to Sonnet because the cloud default is Opus). Xcode work is local.
- **No polling.** An agent starts a long job with a log and a clock file (`rc=`, `DONE`) and ends its turn.
- **One branch per package**, `claude/zonec-<id>`, committed and pushed after every step. The coordinator merges. No agent pushes to main or deploys. Peace Garden never edits the Hub's or Autonaut's repos.
- **Step 0:** no merge to main is needed. Every package branches from `origin/claude/space-seeds-design`, which cloud routines check out after cloning.
- **Traps for agents.** The token guard blocks bare `grep`, `cat`, `curl` and unbounded `git show`. The Xcode project is gitignored: `xcodegen generate` after every merge. Check `df -h /System/Volumes/Data` before Xcode work (34 GB free at 97% on 16 October). Live PHP is `php83` over ssh. Questions to Marcus are numbered, lettered, recommendation first, with pictures for anything visual.
- **Single owners.** No two packages that can run together touch a file:
  - `Localizable.xcstrings`: T1 (everyone else writes English literals). `GardenModel.swift`: A3, then A5. `PlantStageView.swift`: A6.
  - `router.php`: S2. `Server/README.md` and `tools/deploy.sh`: S3. `tests.yml` and `docs/*`: X1. `project.yml` and `Info.plist`: B1. `.gitignore`: A2.
  - `tools/strings/commission.py` and `check.py`: W1. `Server/strings/*.json`: W2, each routine its own files.
- **Waves** say when a package may start; its "needs" still bind. 1: S1, A0, A1, A2 (two at a time), W1, H1. 2: S2, S5, A3, F0. 3: S3, S4, A4, A5, W2, C1. 4: A6, then A7; A8, T1, X1. 5: the live gates, then B1.
- **Critical paths.** Server: S1, S2, S4, G4, G3. App: A0/A1/A2, A3, A4, A6, B1. Look: F0, G1, C1, A6. The gates can be answered during waves 1–3; only C1 (G1), W2 and T1 (G2a) wait on them.

## 2. Work packages

### Server (no Xcode)

**S1. Aloft pools** · M · Sonnet · needs: nothing
- Goal: the two pools as one class over `../peacegarden-data/aloft.sqlite` (directory 0700, file 0600, made on first use as `store()` does, `router.php:137–140`).
  - `aloft(row BLOB PRIMARY KEY)` for 64-byte rows and `back(row BLOB PRIMARY KEY)` for 104, both `WITHOUT ROWID`, `secure_delete=ON`, `journal_mode=DELETE`. Constants P = Q = 2048, B = R = 128.
  - `put()` is `INSERT OR IGNORE`, then one random removal when over the cap. `draw(n)` returns exactly n distinct rows, topped up with padding while the pool holds fewer: `sodium_crypto_scalarmult_base(random_bytes(32))` for the public key, random bytes for the rest.
  - A 1 s lock timeout. A lock failure answers with padding and drops the insert; never a 5xx.
- Files: new `Server/.api/Aloft.php`, `tools/reference/check_aloft_store.php`; changed `Server/.api/settings.php` (an `aloft` path, default beside `public_html`, so tests can aim it at a volume).
- Tests: one column and no rowid per table; never over the cap after 10,000 puts; eviction is not first-in-first-out; `draw(128)` is 128 distinct rows of the right length at any fill; real rows are offered evenly (each within 25% of the mean over 20,000 draws at P = 2,048); a removed marker leaves no bytes in the file; a repeated row is stored once; modes 0700 and 0600.
- Note: DESIGN.md:228 says random probes into the key. They are uneven (R3), so draw with `ORDER BY random() LIMIT n`, a scan of at most 2,048 rows, and keep probes only if the scan is slow on 20i. Not hard enough for Opus.

**S2. The `pending` route** · M · Sonnet · needs: S1
- Goal: `POST /api/walk/pending` takes optional `aloft` (128 lowercase hex) and `back` (208), stores each after the bundles are drawn, and always answers `aloft` (B × 128 hex) and `back` (R × 208 hex) beside `offers` and `wild`.
  - Builds 1–10 (TestFlight only) send neither, still get both bundles, and store nothing.
  - A malformed slot is a 400, as a malformed token is. Slot bytes are never logged. A pool lock failure never changes status or length.
- Files: changed `Server/.api/router.php` (the route at 503–532 only), `Server/.api/Seeds.php` (a length-checked hex helper beside `isHex16`); new `tools/reference/check_aloft.php` (serves `Server/` with `php -S` and a throwaway config).
- Tests: answer length identical with no slots, padding, real-looking slots, and with empty, half-full and full pools; malformed slots (uppercase, 127 or 129 characters, array, null) give the token 400 and store nothing; a well-formed slot is stored once and never returned to its own request; `tokens: []` with slots is 200; 129 tokens is still 400; the error log holds no slot bytes; the 8,192-byte body cap (`router.php:145`) still takes 128 tokens plus both slots (about 4.9 KB).

**S3. Deploy check, backup guard, server docs** · S · Sonnet · needs: S2
- Goal: the pieces around the route: a live check, proof the pools stay out of the nightly copy, and the server's own README.
- Files: `tools/deploy.sh` (a pending check after the `/api/*` checks: an empty bag with padding slots answers 200 with both bundles at the fixed lengths); `tools/reference/check_backup.php` (`KEPT`, `backup.php:77–86`, names no pool table and a dump holds none); `Server/README.md` (the `pending` entries at 498–500, 546 and 628–631, and a "Zone C pools" section: where the file lives, a restore starts it empty, `deploy.sh --delete` never reaches `../peacegarden-data`). `backup.php` itself is not changed.
- Tests: `PG_BASE=http://127.0.0.1:8822 sh tools/deploy.sh --check` against a local copy; `php tools/reference/check_backup.php`.

**S4. Population test for the pools** · L · Sonnet · needs: S2 · local (Docker on OrbStack)
- Goal: `tools/masstest/population/` checks the pools and the fixed sizes, with the SQLite file on a Docker volume as well as tmpfs. What it asserts is in section 4.
- Files: changed `driver.mjs` (`pending()` at 200–207 sends padding slots, and about 1 phone in 6 a real-looking one), `lib.mjs`, `adversary.mjs` (slot cases beside 194–197), `check.php`, `load.mjs`, `stack.sh`, `conf/php.Dockerfile` (it installs only `pdo_mysql opcache`, line 7; confirm `pdo_sqlite` and `sodium` are present), `conf/config.php` (the `aloft` path); new `aloft.mjs`; results in new `design/space-seeds-2026-10-16/population/`.
- The coordinator asks Marcus before the full run (Q3).

**S5. Live lock-test script** · S · Sonnet · needs: S1
- Goal: the SQLite file-locking test DESIGN.md:388 asks for, as one command. New `tools/zonec/locktest.php`, `tools/zonec/locktest.sh`.
- It reports `php83 -m` for `pdo_sqlite` and `sodium`, free disk and fsync time; makes a scratch pool outside `public_html`; runs 64 CLI processes and 64 concurrent web requests of put, evict and draw for 5 minutes; reports busy errors, longest wait, `PRAGMA integrity_check` and rows lost; deletes what it made.
- Tested locally against `php -S`. Writing it is free; running it is G4.

### The look and SeedCore

**F0. Space flora renders** · M · Sonnet · needs: Autonaut's flora proposal (M2)
- Goal: pictures for G1, never prose. One lettered sheet (A, B, C) of the same cross in three treatments: the sender's seed grown, the finder's own seed, their child, at three growth stages, on the suite ground `#0D0D1F`, with a low-stimulation version beside anything that glows.
- Rules on the sheet: plants grow from a point or a screen edge, with no drawn soil; no straight lines; if anything moves it is one slow drift, no flashing, Reduce Motion holds.
- Files: new `tools/zonec/flora_preview.py`, `design/space-seeds-2026-10-16/flora/` (README, `compose.py`, `flora-ABC.png`). A Python render, as `tools/preview/` is, so it costs no Xcode time.
- If Autonaut cannot send kinds in time, F0 draws 3 to 5 provisional kinds for Autonaut to ratify (DESIGN.md §8, A3).

**C1. Space flora in SeedCore** · M · Sonnet · needs: G1, M2
- Goal: the pinned derivation `peacegarden.space.v1`: kind and traits from the 16 bytes `r` alone (Autonaut calls it too), and the hybrid draw for crosses on the same 36/36/22/6 ladder as `GeneSource`, parents sorted so both phones draw the same plant.
- Files: new `Packages/SeedCore/Sources/SeedCore/ZoneC/SpaceFlora.swift`, `SpaceFloraHybrid.swift`, `Packages/SeedCore/Tests/SeedCoreTests/SpaceFloraTests.swift`, `SpaceFloraVectorTests.swift`, `tools/reference/space_flora_reference.py`, `tools/reference/space_flora_vectors.json` (the file Autonaut tests against).
- New files keep the `#if os(WASI)` import header the others use and call `seedDigest` only: no HMAC or HPKE, because the Linux and WASM builds have no CryptoKit.
- Tests: vectors equal in Swift, Python and WASM (with the tolerance `VectorFile` already names); every kind reachable; hybrid commutative; the Zone C `CrossPollinationResult` gives the same child, encounter and checksum on both sides; a draw from `r‖mark` equals a draw from `r`.
- Merge to main as soon as green: Autonaut builds against it.

### App (local, Xcode)

**A0. App Group and transit folder** · M · Sonnet · needs: nothing (G6 only for a signed device build)
- Changed: `App/PeaceGarden/Resources/PeaceGarden.entitlements` (`group.com.interfulgent.suite`), `App/PeaceGarden/Resources/PrivacyInfo.xcprivacy` (file-timestamp category, reason C617.1, beside the UserDefaults entry at 57–70; R5).
- New: `App/PeaceGarden/ZoneC/SuiteGroup.swift` (the container behind a protocol so tests inject a temp directory; `NSFileCoordinator`; atomic writes staged as `Seeds/v1/tmp/peacegarden-<random>`, dated and flagged there, then renamed into `in/` (DESIGN §3, agreed with Autonaut 17 October), own `peacegarden-*` leftovers cleared at launch, `tmp/` never read; dates set to 1 January 2001 on files and on `Presence/v1`, `out`, `in` and `tmp` after each write, and read back; `isExcludedFromBackup` on `Seeds/v1`), `SuiteTransit.swift`, `App/PeaceGardenTests/SuiteTransitTests.swift`.
- `SuiteTransit` takes `out/<random>` only if it is exactly `{"v":1,"r":"<32 lowercase hex>"}` (else deletes it unread); writes `in/<random>` as `{"v":1,"seed":"<64 hex>"}` only while fewer than 3 wait; keeps the `exchange` marker; writes `Presence/v1/peacegarden` only when missing; reads `Presence/v1/autonaut`.
- Tests: strict parse (extra key, uppercase, short, wrong version all deleted); cap of 3; a second launch leaves the presence file's dates alone; every file and directory reads back 1 January 2001, and the test records what `st_ctime` shows (R6); backup flag set; the code writes only its own files and reads only `out/`, `Presence/v1/autonaut` and its own.

**A1. Zone C store** · M · Sonnet · needs: nothing
- Goal: Zone C's own data, in the backup (9B). New `App/PeaceGarden/ZoneC/ZoneCStore.swift` (`zonec.json` beside `garden.json`, written with `GardenStore.guarded`, with a schema version), `ZoneCModels.swift`, `App/PeaceGardenTests/ZoneCStoreTests.swift`.
- It holds:
  - Zone C's own seed: 32 bytes from `SecRandomCopyBytes`, minted once when first needed.
  - Sent-seed records: `r`, the seed key's private half, launches left (60), plants grown (at most 3); at most 8, the oldest pushed out.
  - Owed returns: the 56 payload bytes, sends left (8); at most 3.
  - Zone C plants: child seed, both parents, encounter, which side grew it; a birth only if G1 says the flora ages. And the day of the last find (Q2).
- Tests: round trip; own seed minted once and stable; a ninth record pushes out the oldest; a record ends at 60 launches or 3 plants; `isExcludedFromBackup` is false on the store; no record carries a date; erase removes the file.

**A2. Crypto, marks, slots, returns** · M · Sonnet, then one Opus read of the diff · needs: nothing
- Goal: all cryptography in the app target (CryptoKit). New in `App/PeaceGarden/ZoneC/`:
  - `ZoneCMark.swift`: first 16 bytes of HMAC-SHA256(K, `peacegarden.zonec.mark.v1` ‖ r).
  - `ZoneCKey.swift` and a generated, gitignored `ZoneCProductionKey.swift` made by `tools/zonec/make_key.sh` (R1). Debug and tests use a fixed test K; a Release build does not compile without the generated file, because the symbol exists only there.
  - `ZoneCSlots.swift`: the 64- and 104-byte slots, padding from real X25519 keys, hex.
  - `ZoneCReturn.swift`: HPKE base mode, `Curve25519_SHA256_ChachaPoly`, info `peacegarden.zonec.back.v1` ‖ space seed, 56 bytes in, 104 out.
  - `App/PeaceGardenTests/ZoneCCryptoTests.swift`; changed `.gitignore`.
- Tests: the mark accepts its own and rejects a flipped bit, and no random 32 bytes pass in 100,000 tries; slots are exactly 128 and 208 hex characters, real and padding alike, each public half derived from a private key (generator injected); a return opens only with the right private key and the right space seed; two seals of one payload differ; the RFC 9180 appendix A.2 ciphertext opens with this suite; 1,024 openings (8 records × 128 rows) take under 100 ms on the scratch simulator.

**A3. The launch request** · M · Sonnet · needs: A0, A1, A2
- Goal: every launch sends the padded request and reads both bundles.
- Changed: `WebGarden/PlotService.swift` (`pending`, 96–107, loses the empty-bag return; `Asking`, `Reply` and `Pending` gain the two fields, tolerated when absent); `GardenModel.swift` (`catchUpOnTheAsking`, 559–578: drop the guard at 565, run the exchange once per process); `App/PeaceGardenTests/AskingTests.swift` (the test at 322–326 asserts the opposite and flips).
- New: `ZoneC/ZoneCExchange.swift` (takes the oldest `out` seed, writes its record and key before sending, builds the slots, deletes the file only after a 2xx, counts a launch against records and owed returns only on a 2xx) and `ZoneCBundles.swift` (the sink A4 implements; a no-op until then).
- Tests (the existing `Stub` transport): an empty garden asks; `aloft` is 128 and `back` 208 hex in every case, and the request's byte length is the same with a real seed as with padding; a garden of 129 meetings sends two requests, real slots in the first and padding in the second; an answer with no slots (older server) or wrong-length rows is tolerated; switch off sends nothing; a timeout or 429 leaves the `out` file and reuses the same key (R2).

**A4. The engine: find, cross, return** · L · Sonnet · needs: A1, A2, A3
- Files: new `ZoneC/ZoneCEngine.swift`, `ZoneCFinder.swift`, `ZoneCReturns.swift`, `App/PeaceGardenTests/ZoneCEngineTests.swift`, `ZoneCEndToEndTests.swift`.
- Finding (DESIGN §5): check marks with K; skip a seed it holds a record for, and a space seed already a parent of a Zone C plant; one find a day (Q2); only while Autonaut is present, fewer than 3 files wait in `in/` and fewer than 3 returns are owed. Cross with Zone C's own seed as `CrossPollinationResult(localSeed: own, remoteSeed: found, localNonce: n, remoteNonce: r)`; plant in Zone C; write `in/`; queue the return for 8 launches.
- Returns: on each answer, try every live record's key on every return row; open, compare the checksum, skip a plant already grown, grow the twin; a record ends at 3 plants.
- Tests: both sides reach the same child, encounter and checksum, equal to what a knock gives; an in-memory pool stands in for the server and two engines (Ana, Ben) run launches until the twin appears, inside the delivery band §5.3 gives; several finders grow several plants, up to 3; a return for another sender, a wrong checksum and a flipped bit grow nothing; each limit above; a find writes only `in/`, a return writes nothing to the group.

**A5. Switch, About text, reset** · S · Sonnet · needs: A0, A3
- Changed: `Views/SettingsView.swift` (the row at 579–582 relabelled "Ask the garden for news when it opens" with one short line under it; the stored key `sharing.invitations.v1` stays, so no one's choice moves); `Views/AboutView.swift` (a Privacy paragraph: the request at each start carries two random-looking values and returns a handful of each; Zone C is in the phone's backup with the garden); `Views/Sharing.swift` (the comment on what off stops); `GardenModel.swift` (`resetEverything`, 648–654, also erases Zone C's store; R8); additions to `SettingsClarityTests` and `AboutSheetTests`.
- **Zone C switch (DESIGN §7 item 16, Marcus 17 October):** a second row, "Zone C" with one short line, off by default, shown only while `Presence/v1/autonaut` exists; its own stored key. Turning it on is the consent. Off: the padded request still goes, A3 takes nothing from `out/` and A4 finds nothing and queues no return.
- Behaviour: `Seeds/v1/exchange` exists only while both switches are on; otherwise deleted; reconciled at each launch. The presence marker is A0's and does not follow the switch.
- Tests: Zone C row hidden without the presence file and off by default with it; Zone C off keeps the padded request but sends padding only and removes `exchange`; label and note present; launch switch off sends no request and removes the `exchange` marker; on restores it; reset removes `zonec.json` (own seed, records, plants) and any seed waiting in `out/` or `in/`, and leaves the switch as it was.

**A6. Zone C view, door, space flora drawn** · L · Sonnet · needs: A4, C1, G1
- Changed: `Views/PlantStageView.swift` (one mark in the foot row, shown while `Presence/v1/autonaut` exists or Zone C holds a plant: a known glyph, not a word).
- New: `ZoneC/ZoneCView.swift`, `ZoneCModel.swift`, `SpaceFloraDrawing.swift`, `ZoneCGlyph.swift`, `App/PeaceGardenTests/ZoneCViewTests.swift`, `SpaceFloraRenderTests.swift` (writes PNGs when `PG_RENDER_SPACEFLORA` is set, as `WorldRenderTests` does).
- Rules: Marcus's (organic edges, no straight lines, no drawn soil, no flashing, Reduce Motion holds); its own door and no glimpse from the ordinary garden; a sent seed appears only when a return arrives (13A); a glyph says whether a plant grew because the person found a seed or because theirs was found; Dynamic Type, VoiceOver, right to left.
- Tests: door hidden without the presence file and shown with it; the view lists the store's plants and nothing else; accessibility labels; the render equals the sheet chosen at G1, shown to Marcus as a picture before merge.

**A7. Share picture** · S · Sonnet · needs: A6
- New `ZoneC/ZoneCPicture.swift` and a test. `Views/Share/*` is not touched, because a Zone C plant is not a `PlantRecord`. The picture is made only when the person asks (10B) and carries the plant and nothing about it (as `PlantPicture.swift:8–12`).
- Test by type: no conversion from a Zone C plant to anything an offer, release, tap or link takes.

**A8. One real round trip** · S · Sonnet · needs: S2, A4
- New `App/PeaceGardenTests/ZoneCLocalServerTests.swift`, skipped unless `PG_ZONEC_SERVER` names a local server (`php -S` or the S4 stack). Ana's seed goes up, Ben's engine finds it in the real bundle, his return comes back in the real `back` bundle, Ana's grows the twin, and the answer lengths are the fixed ones.

### Words, site and the rest

**W1. English privacy text and claims** · S · Sonnet · needs: nothing (G2a before W2)
- `Server/assets/js/strings.js`:
  - rewrite `privacy7`: the app asks each time it starts, with or without meetings, sends one random-looking value up and one reply, and receives a handful of each;
  - new `privacy11`: what the pools keep (random-looking 64- and 104-byte values, no time, address or order), until when (until newer ones push them out), that they are in no backup, that a reply opens only on the phone that sent its seed. It may name Autonaut.
- Also: `Server/.pages/privacy` (a `privacy11` paragraph after `privacy7`); `tools/strings/commission.py` (the `PRIVACY` claims for `privacy7` at line 256, a `ZONEC` dict like `WEAR` and `UPDATE`, and `--privacy` prints it); `tools/strings/check.py` (reads the new key). No Zone C on the web.
- Tests: `python3 tools/strings/check.py`; `python3 tools/site/export.py --check`.

**W2. Site translations** · M · Sonnet, cloud · needs: W1, G2a
- Strings: `privacy7` and `privacy11` (`privacy3` already says "in your phone's backups"). Languages: every commissioned catalogue except English and Greenlandic (which awaits a speaker): 41. `Server/strings/` holds 42 files and `languages.json` offers 42 including English, where DESIGN.md and the handover say 40. Recount with `check.py` when commissioning.
- How: `python3 tools/strings/commission.py --privacy <code>` prints each language's brief. One routine for Danish (the site, plus the app strings from T1) so Marcus can read it first; four routines for the other 40 in batches of 10, as `SITE-g1` to `g4` ran on 14 October. Each routine owns only its files and one branch, `claude/translate-zonec-site-gN`.
- Rules: informal address; Danish *folk* or *personer*, never *mennesker*; say what a thing is, not what it is not; numerals from 2 up. Records in `tools/strings/commissions/<date>/SITE-zc-gN.md`.
- Tests: `python3 tools/strings/check.py` clean for all 42; the crawl in `tools/masstest/site` (layout shift and overflow) for the longest languages (de, fi, hu) at phone width.

**T1. App translations** · M · Sonnet, cloud · needs: A5, A6, A7 text final; G2a
- Strings: the relabelled switch and its note; the About paragraph; the Zone C door's accessibility label, empty state and share caption; whatever A5–A7 add. A known glyph before a new word, to spare 7 translations each time. Languages: da, es, fr, it, nb, nl, sv.
- How: `tools/strings/sync.sh` after a build lists the new keys; one routine per language writes `tools/strings/commissions/<date>/app/<code>.json` (as on 1 October), then one apply step puts all seven into `Localizable.xcstrings`. Danish first, for G2b.
- Tests: `python3 tools/strings/app_check.py`; the app's catalogue tests; the language sweep in `tools/masstest/app`, once.

**X1. CI and docs** · S · Sonnet · needs: S3, C1, A5
- Goal: CI and the docs say what now exists. Files: `.github/workflows/tests.yml` (steps for `check_aloft_store.php`, `check_aloft.php`, `space_flora_reference.py`); `docs/WEBSITE.md` (the switch row at 1053); `docs/CHROME-AND-SETTINGS.md` (163, 178); `docs/EXCHANGE-PROTOCOL.md` (a Zone C section pointing to `DESIGN.md`); a short new `docs/ZONE-C.md` saying where each piece lives.

**H1. Messages and the DPIA row** · S · Sonnet or the coordinator · needs: G5 for the final wording; the draft can go now
- The coordinator sends two messages with `send_message`; nothing is edited in other repos.
- M1 to the Hub session: the Appendix row.
- M2 to the Autonaut session: please send the space-flora kinds, names and look (A3); the pinned vectors will be `tools/reference/space_flora_vectors.json`; set directory dates as well as file dates (R6); nothing else changes for Autonaut.

**B1. Build 11 (and 12, per Q1)** · M · Sonnet · needs: everything in the build, G3, G6, G7
- Goal: an archive Marcus can upload. Changed: `project.yml` (`CURRENT_PROJECT_VERSION`, and the encryption comment at 78–88), `Info.plist` (the export-compliance key, per G7).
- Steps: `xcodegen generate`; the full suite once through the lock; archive; export with `/usr/bin` first on PATH (the rsync trap); Marcus runs `sh tools/upload-build.sh` (G8).

## 3. Gates that need Marcus

| Gate | What Marcus does | Blocks | Carries on without it |
|---|---|---|---|
| **G1** Space flora renders | Chooses from the lettered sheet F0 makes (a picture, never prose) | C1, A6, A7, the Zone C strings in T1, B1 if the view ships | All of S, W, A0–A5, T1's switch and About strings, H1 |
| **G2a** English wording | Reads the English of `privacy7`, `privacy11`, the switch label and note, the About paragraph | W2, T1 | W1 drafts, all code |
| **G2b** Danish reads | Reads `DANISH-site` and `DANISH-app` in the commission records | Merging Danish, G3, B1 | The other 40 languages' routines, all code |
| **G3** Live deploy (one deploy carries server and site, after `tools/backup.sh`) | Says go; runs `tools/deploy.sh`, then `--check` | B1's distribution | Everything before it |
| **G4** SQLite locking on the live 20i host | Allows S5 to run once on the host (a temporary upload and removal) and reads the report | G3: the route cannot go live untested. A failure sends §4.4 back to Marcus (a flat file under `flock`, or another host) | All code and local tests |
| **G5** 20i snapshot answer (8A) | Asks 20i how often the web space, including files outside `public_html`, is snapshotted, for how long, and whether customers can read the snapshots | H1's final wording, G3 | All code |
| **G6** (extra) App Group | Registers `group.com.interfulgent.suite` and adds it to `app.peacegarden` on the developer portal | B1's signed archive, any device test | Simulator tests with an injected directory |
| **G7** (extra) Export compliance | Decides the `ITSAppUsesNonExemptEncryption` answer now that HPKE encrypts (R4) | B1 | All code; A2 leaves the value alone |
| **G8** (extra) TestFlight | Runs `sh tools/upload-build.sh N`, or uses the Organizer if the Xcode sign-in has lapsed | Testers receiving it | |

## 4. Test strategy

- **Unit tests per package** are listed above. Each package runs its own tests before its branch is pushed.
- **PHP checks** (`tools/reference/check_*.php`) run in CI on Linux over throwaway SQLite, as the others do. SeedCore's `swift test` and the WASM job pick up the new tests; X1 adds the Python reference to `tests.yml`.
- **Population test, adapted (S4).** It asserts:
  - every 200 `pending` answer carries `aloft` of exactly 16,384 and `back` of exactly 26,624 hex characters in every phase (empty, filling, full; with and without slots); `offers` and `wild` are the only things allowed to vary;
  - each pool is at or under its cap, with one column and no rowid, and rises by one per well-formed request until full; neither pool is in `backup.php --tables` or a dump;
  - offered counts are even over 20,000 requests (max to min ratio and chi-square); a removed marker's bytes are not in the file;
  - the adversary's slot cases give the token 400 and store nothing; one address is 429 after 1,100; a flood from many addresses (`X-Sim-Addr`) shows how many real rows survive 2,048 fake ones;
  - 10, 50 and 200 clients of `pending` with slots, on a volume and on tmpfs: zero 5xx, no surfaced lock error, a clean `integrity_check`, p50 and p99 beside today's `pending`;
  - a festival day (one shared address) shows the empty-bag count by address alone (`Limits.php:151`).
  - It cannot show 20i's disk and locking (G4) or its logs (G5).
- **Xcode runs go one at a time through the shared lock, with `-jobs 4`, on a scratch simulator** the agent creates (an iPhone Air, as build 10 did) and deletes afterwards. Never the iPhone 17 Pro; one simulator booted at a time (`one-xcode-build`: parallel builds froze the Mac on 13 October). Shape: `sh tools/xcode-lock.sh xcodebuild test -project PeaceGarden.xcodeproj -scheme PeaceGarden -destination 'id=<scratch UDID>' -jobs 4 -only-testing:PeaceGardenTests/<Class>`. `swift test --package-path Packages/SeedCore` goes through the lock too. An exit 133 after "TEST SUCCEEDED" is the simulator-diagnostics timeout: read the log.
- **The full suite** (309 tests plus the new ones) runs once, in B1, after the coordinator asks Marcus.
- **End to end.** A4's in-memory pool with two engines; A8 once against a real local server; the first live round trip is a TestFlight build on two phones, once Autonaut can write a seed.

## 5. Open risks DESIGN.md did not foresee

1. **K sits in a public repo.** `gh repo view` says `marcusbsorensen/peace-garden` is public, and DESIGN.md:135 compiles K into the app. If K is committed, 20i or anyone can pick the space seeds out of the pool, and §4's central claim (the server cannot tell) becomes "unless it reads our repo". A2 keeps K in a gitignored generated file; the binary still holds K, as DESIGN.md accepts.
2. **A lost answer duplicates a seed.** DESIGN.md:366 writes the record only after a 2xx; the request can time out (`PlotService.swift:254`) and the caller swallows it (`GardenModel.swift:566`). The next launch would draw a new key: two pool rows for one seed, one openable by the sender, and a finder who meets both grows two plants. A3 writes the record first, reuses the key, and counts the eight return sends on 2xx only.
3. **Probe sampling is uneven** (DESIGN.md:228). A probe lands on the first key at or after a random point, so a row's chance follows the gap before it (the largest of 2,048 gaps is about 7 times the mean), and 128 probes repeat a row about 4 times. §5.3's delivery figures assume even draws. S1 scans with `ORDER BY random()` and tests evenness.
4. **Export compliance.** `Info.plist:98` declares no non-exempt encryption because the only cryptography was SHA-256 (`Info.plist:86–97`, `project.yml:78–88`). HPKE with ChaCha20-Poly1305 is encryption. G7.
5. **Privacy manifest.** `PrivacyInfo.xcprivacy:57–70` declares only UserDefaults; setting and reading file dates in the group needs the file-timestamp category. A0 adds it.
6. **Fixed dates may not cover everything** (DESIGN.md:102). A directory's modified date changes when a file in it is added or removed, and Peace Garden deletes an `out` file at its own launch; the change time (`st_ctime`) belongs to the file system and may not be settable. A0 resets directory dates and records what it can read back. If change time cannot be reset, §3.2 narrows to "modified and created", and the Hub and Autonaut are told.
7. **"One find a day" needs a stored day**, and §5.3 says records hold no date (DESIGN.md:269, 317). The day of the last find would sit in the backed-up store. Q2.
8. **Reset everything does not know Zone C** (`GardenModel.swift:648–654`). Without A5, Zone C's own seed, records and plants, and any seed waiting in `out/` or `in/`, survive a reset and stay in backups.
9. **"A start" is a cold start.** The request runs from `.task` on the root view (`PeaceGardenApp.swift:42`), which does not run again when the app comes back from suspension. Phones that rarely cold-start send fewer than the 2 a day that §5.3's table and the 60-launch record life assume (DESIGN.md:317). Check on a real phone in TestFlight; 15A already schedules a revisit.

## 6. Decisions for Marcus (recommendation first)

**Decided 17 October: 1A, 2A, 3A.** Building starts now: server and words as cloud routines, app packages locally, two at a time.

1. **Ship order.**
   - A (recommended): build 11 carries the padded request, the relabelled switch and the privacy text, with Zone C dormant (no door without Autonaut's presence file); the flora and the Zone C view follow in build 12. The crowd exists before the first space seed, and G1 leaves the critical path.
   - B: everything in one build, after G1.
2. **The day for "one find a day".**
   - A (recommended): keep the number of the last day a find happened, in Zone C's store. In a backup without Advanced Data Protection Apple could read that one date.
   - B: allow a find only every third launch. No date, but not the rule you chose in 5A.
3. **First population run.**
   - A (recommended): a reduced run (1,000 gardeners, 30 days) to check the pools, then the full 5,000 over 155 days once before G3.
   - B: the full run first.

## Appendix: DPIA row for the Hub session (M1)

Format follows `~/Projects/interfulgent-hub/docs/dpia-flagfans-hub-rows.md`. **Section 2.2, "Built: tables holding personal data", add:**

| Peace Garden launch request and space-seed pools (`peacegarden.app`, Marcus's 20i package): `POST /api/walk/pending` and `../peacegarden-data/aloft.sqlite` | Each request carries two fixed-size random-looking values (64 and 104 bytes): padding, or a space seed with a one-time public key, or a sealed return; the meeting tokens the route already took ride beside them. The pools hold only those values: one column each, no time, address, token, counter or order. The answer carries 128 random rows from each pool. 20i's own logs keep each request's address, time, route, status and size for 12 weeks (CDN logs 7 days). On the phone, Zone C's store: its own random seed, up to 8 sent-seed records (a seed and a private key, no date), the plants grown, and [if Q2 A] the day of the latest find | Every Peace Garden user who leaves "Ask the garden for news when it opens" on, which is the default, whether or not they use Autonaut | Pool rows leave by random eviction once a pool holds 2,048 (about two days at 1,000 starts a day). In no nightly copy; a restore starts the pools empty. 20i snapshots of the web space: [20i's answer, 8A]. On the phone: until the person resets or removes the app; Zone C is in the device backup with the garden (9B) |

**Section 2.6, 20i row, add:** the pool file sits in the package's storage outside `public_html`; its secure-delete setting overwrites removed rows; snapshot policy [8A].

**Residual risks.** 1 to 3 are the Hub's three (Autonaut's privacy page carries them too); 4 to 6 are new:
1. A server altered to act as well as log could swap in its own seed key, open returns, and learn which addresses found seeds. Only a relay (Oblivious HTTP, iCloud Private Relay) closes it.
2. If a sender and a finder both post a share picture of their shared plant, anyone who sees both can link them.
3. An iCloud backup without Advanced Data Protection shows Apple that the person has space flora, which implies Autonaut; two backups show that two people share a plant. Accepted by Marcus (9B).
4. With the mark key, a copy of the pool narrows a space seed to the addresses that opened Peace Garden between two 20i snapshots [8A].
5. Every Peace Garden phone with the switch on now contacts the server at each start, so 20i's logs list all of them for 12 weeks, not only those with meetings.
6. Two behaviours cannot be hidden: opening Peace Garden more often to look in Zone C, and turning the switch on to use it.

**Lawful basis (for Marcus and the Hub to settle):** Autonaut takes consent at the first "Send as a seed" (its `docs/DATA.md`); Peace Garden's request is already described at `privacy7`, which W1 rewrites.
