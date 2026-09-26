# Peace Garden: the Home Ground live, all ten areas open — handover 24 September 2026 (late)

Older notes: `git show 447d066:.claude/HANDOVER.md`.

## Goal
All ten areas open before the app is announced, on the new plant shapes.

## State
- **Live and checked** (main `0dbc578`, pushed, deployed; backup taken before): the Home Ground, the tenth area. Rule, port, store, routes, page, workbench, replant, docs.
  - Rule: `Packages/SeedCore/Sources/SeedCore/WebGardens/HomeGround.swift`. Three beds; the crop (the genus root) claims a bed; from the crop's cut up a plant takes the first free place from the north end, below it the first from the south.
  - **The crop is read off `PlantTraits.habit`**, which names the root exactly in this area (Cer is only ever a spire, Fen an umbel, Pell a succulent). No new trait and no offers migration. A habit never sent is sown as an umbel.
  - Marcus's two answers on the new shapes: rosettes 3 across at 0.38 m, 30 a bed; umbel cut 0.930 m (spire 1.346, rosette 0.275).
  - Fresh 500: 9 plots, 7 full, 26 beds sown, 23 full, 90% held. Exactly what the simulation gives (`tools/homeground`, now running the decided design).
  - Service: `Server/.api/HomeGround.php`, `HomeGroundStore.php` (table `home_ground`, crop a column), `/api/ground`, `/api/ground/plot/{n}`. `Area.isOpen` and `Areas::OPEN` carry `ground`: ten of ten.
  - Page: `/ground` (`Server/assets/js/ground.js`, `groundpage.js`), workbench `/dev/ground`. Mounded soil beds, no boards, trodden paths, sown beds raked and unsown beds dug.
  - Replant: `home_ground` in `tools/replant` and `Server/.api/replant.php`; the crop is derived from the habit the plan carries.
- **Tests**: SeedCore 378/0 on macOS, 372/0 under WebAssembly; every PHP check passes, including the new `check_home_ground.php`, offers and backup; replant rehearsal passes across ten areas; strings check clean.
- **Live**: `/api/garden` lists ten open; `/ground` serves and draws; `deploy.sh` checks pass. The live Home Ground holds only its ambassador.

- **The plant panel is live** (merge `0863179`, deployed 24 September late, backup taken first). Tap a plant on any area page, or press `p`: its name, what the name means, one passage (the app's own rule for a crossed plant), and *Send as a postcard*, a link `/<area>?plot=N#p=<12 hex>` that opens the plant with its panel up. Shared module `Server/assets/js/plantpanel.js`; name from the new `pg_name` export. `docs/WEB-GARDENS.md` records the decision and the as-built. Seven new strings, English only. Distinct from the phase-2 *plant's own page* in `WEBSITE.md`, which carries the gardener and needs a second consent.
- **`tools/reference/passage_reference.py` `theme_of` is fixed** (26 September). It was still drawing `passage.theme.v1`, a trait the app stopped asking for on 1 September; the app reads the theme off the genus head, which is looked up from two draws the seed already makes (`form.archetype` and `bloom.merosity`). So the two agreed about one seed in ten by luck, and the distribution was flat 10% where the app's is 12.5/8.33 on the twenty-four syllables split 3/2. No domain tag was renamed or invented. Two invariants had to be rewritten as well: "roughly even" was true of the flat draw and false of the app, and left alone would have gone red in CI on 0.6% and 1.8% of runs. The new ones catch a reversion to a flat draw 2000 times out of 2000, and the file is now pinned to `ambassador_vectors.json` — all ten ambassadors agree on archetype, head and area. **That missing pin is what let it drift**: every other invariant was a property of the draw's shape, and the wrong draw had the same shape.

- **Live, 24 September late** (merge `b675bda`, and `1e70130` before it):
  - **Shadows** (`Server/assets/js/shadow.js`): each plant's from its own triangles projected along the sun and blurred, so a dense rosette sits in a pool and a spindly plant barely marks the ground; the Knot's box, the Cold Frame's boxes, the Seedbed's labels; the Long Walk's yew and low hedge and the Quiet Garden's hedge and bench, far edges wandering; the Orchard's crowns a dappled pool. Left out by choice: Glasshouse staging and bars, Cold Frame lid bars (straight stripes). A turn now costs 14–50 ms (structure shadows recomputed).
  - **Cold Frame lights open**: a tap on a shut frame's glass swings both lights to 60° on the back edge (no panel); taps then pick plants; one open at a time; `p` and postcards open the frame first. Closing a panel leaves the frame open (decided for Marcus).
  - **The name larger** (mark 60 px, wordmark 22 px regular, full ink) and **no hairline above the foot** on any page. Marcus.

- **Live, 25 September early**:
  - **Batch 3** of the commission (ja ko zh ar he, site only), `79f78f1`. Twelve of forty-one languages now have the front page and the meanings. Batch 4 (de pt ro ca gl is fi hu eu et) is next.
  - **Every area's floor ends on the plot's edge** (`025bb02`): the Orchard's mown discs and meadow, the Crossing's grass and paths, and the Knot, Cold Frame, Glasshouse, Seedbed and Quiet Garden floors hung past it. **Hedges on the plot** (`81b8271`): the Long Walk's and Quiet Garden's outer faces drawn in to the edge; the rule's inner faces and every place unmoved.
  - **A lotus takes two places** in the Cold Frame and the Seedbed (`6cc8b90`, Marcus's choice after measuring: a young lotus's pads reached 0.31 m, the Cold Frame's spacing, and a quarter of its plants stood inside one). Stems inside pads 1 in 500 in each. Fresh 500: Cold Frame 18 plots (was 12), Seedbed 19 (was 15). New columns `slot_span` and `habit` on both tables. The Cold Frame's ambassador, a lotus, now holds the first two places of its rank. Old stored plantings read as one place until the replant. SeedCore 390/0 macOS, 384/0 wasm; 16 PHP checks; replant rehearsal passes across ten areas.

- **The commission is finished** (26 September). Batch 6 — lt lv cy ga el tr sq mt — went in last, 55 site strings each, and **all forty-one site languages now have the front page, the ten meaning lines, `/meanings` and the thirty parts.** Kalaallisut is out by its own `awaiting` note. Every check passes: `sheets.py --check` 41 of 41 clean, `check.py` 42 clean, `app_check.py`, `export.py --check` in step. Looked at in the browser in Welsh, Greek and Maltese. **Nobody who speaks any of the forty has read a word of it**; the commission README tables what each translator asked a reader to look at.
  - **Two Maltese collisions, both settled by Marcus the same day**, and the only strings the whole commission changed rather than added. `areaWaiting` was *L-istennija*, which translated the theme and so made the Waiting card print *Stennija* over *L-istennija*; it is now **Ir-raqda**, the sleep, naming the area by what it does as Irish's *An suan* and Greek's *Ο λήθαργος* do. And `growBody` said *jaqsam*, which would have made `frontCross` read *Qsim*, dividing rather than crossing; it now says **jinkroċja**, so the step is *Inkroċjar* and the two agree.
  - Pattern was the hard headword in all eight: every one of these languages uses its everyday word for *pattern* to mean a sewing pattern, so each took its word for *regularity* instead, and each is longer than the English. `Κανονικότητα` and `Likumsakarība` are the longest and still fit a card.
  - **The privacy page is the round that is now next**: eight keys in forty-two, the only commissioned group still waiting. `commission.py --privacy <code>` prints its sheet.

## Files
- `docs/WEB-GARDENS.md` §"The Home Ground, chosen" → §"Decided" (items 6–7 are tonight's) → §"The Home Ground, built".
- `tools/homeground/` — the simulation, now the decided design.

## Decisions made
- Crop read off the habit rather than sent as a new trait (implementation choice, recorded in the doc).
- Unknown habit → umbel: widest spacing, commonest crop.
- Taking back keeps bed, crop and place; blanks height, family and habit.
- No words for the crops on the page.

## Next step
**Build 2 (1.0) is uploaded to App Store Connect**, 24 September 20:55 (delivery `93b033f3-8c12-4ec7-80ab-c86f6133e119`; archive `build/PeaceGarden-1.0-2.xcarchive`, `.ipa` in `build/export-1.0-2/`). It sends `habit`, `hue` and the new-shape heights — the source had since the Glasshouse and the Coppice; build 1 of 16 September predated both. `AskingTests` now checks the offer carries them. App suite 131/0 (1 skipped).
Once it is through processing and on testers' phones: the replant from a fresh copy (`tools/replant/README.md` §runbook), across all ten areas. After that, the at-scale work, or the gateways design pass.
One upload warning, harmless unless visionOS is wanted: `UIRequiredDeviceCapabilities` lists `accelerometer`, which visionOS lacks (90984).

## Open, set aside
- **Until build 2 is what people run, every Home Ground arrival is sown as an umbel.** The replant after that build (`tools/replant/README.md` §runbook) puts each in its own crop's bed. Same build is needed for the Coppice's ferns and the Glasshouse's hues.
- The commission (`tools/strings/commissions/2026-09-24/`) is regenerated: the thirteen English-only keys of the three new areas and the pad are grouped in `sheets.py`'s `WHY` and counted in its README (102 lacking per language, was 91). The sheets did not change. **Batch 2 (es fr it nb nl sv) is written and live on the site** (`4a3dba4`, deployed 24 September), unread by any speaker; the commission README tables what each wants a reader to check. Its app half ships in build 3. All six batches are written now; see above.
- From before: young water-lily pads through the Cold Frame's walls; the Glasshouse staging crowded. Both set aside by Marcus.
- Marcus's gateways idea (glimpses of neighbouring areas) needs a design pass; hooks in `movepad.js` `neighbour()`.

## Traps
- **Token-guard hook**: blocks unbounded `cat`, `grep`, `git show`/`git diff`, heredoc `cat >`. Pipe `git show` through `head -N > file` to read a diff.
- **Dev server**: an old `php -S localhost:8803 -t Server tools/wasm/dev-router.php` may already be running from an earlier session; it serves from disk, so reuse it (`/dev/ground`, `/ground`).
- **Workbench sowing is slow**: 500 arrivals take ~20 s in the browser before anything is drawn.
- **`VectorFile.placementCannotTurn` checks every cut against every height**; the Home Ground's vector test checks each height against its own crop's cut instead.
