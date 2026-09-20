# Peace Garden: the asking — handover 19–20 September 2026

One thing this session: **a plant can now be put in the shared garden, and it takes both gardeners.** The previous handover, whose traps still apply, is at `git show 8a7e904:.claude/HANDOVER.md`.

## The problem it solves
A plant made at a meeting is grown from its child seed, **both parents' seeds** and the meeting's ID — a browser cannot draw it from less. So showing one of your plants publishes the other gardener's seed too. It was never one person's to publish, and there was no way to ask them: no accounts, no directory, nothing that identifies a person, all by design.

The one thing that existed was the contact token — sixteen bytes each phone mints in its `PollenCard` at a meeting — and it was **minted and thrown away**. It cannot be added to a meeting that has already happened, which is why `WEBSITE.md` called keeping it the most urgent item in phase 2.

## State
- **Done, tested, pushed.** `bf46213` on `origin/main`. SeedCore 145, app 98 (1 skipped), `check_offers.php` 31 checks and `check_long_walk.php` 600 placements, both in CI.
- **Watched end to end on an iPhone 17 Pro** against a local copy of the service: an invitation appeared on the garden screen, was answered, and the plant stood in plot 0 of the walk. The service agreed.

### What is built
- **The tokens are kept.** `MeetingTokens` on `PlantRecord`: `ours`, which this phone is addressed at, and `theirs`, where it addresses the other gardener. **Two rather than one**, so an invitation has a direction that cannot be set the wrong way round. Written as hex, the way a seed is.
- **`Standing`** says where a plant stands: here, asked, invited, shown, declined, withdrawn. Absent means here, so no garden migrates; an unknown word from a newer version decodes rather than throwing the garden away.
- **The asking, in PHP** (`Server/.api/Offers.php`): `POST /api/walk/offer`, `/pending`, `/answer`, `/withdraw`. An offer is addressed to the token its recipient minted, only that phone can answer it, there is **one offer per plant** — which is what makes a decline final and is why the app needs no block list — and either gardener can take it back at any time without the other.
- **`/api/walk/plant` stays shut.** It is the one route that plants with nobody asked, and it exists for the reference check.
- **The phone's side**: `PlotService` (four calls, a transport it can be handed), `GardenModel.offer/answer/withdraw/catchUpOnTheAsking`, and `ShowInGardenView` — **one screen for both gardeners**, because they are told the same facts and only the question differs; two screens drift into a large question and a small one.
- **Off means no request.** `Sharing.wantsInvitations` is read in one place and the question stops there. `AskingTests` pins it.
- **`-pgPlots http://localhost:8803`** points a debug build at a local service. `Server/README.md` has the command.

## Decisions made
- **The token is the address; consent is what it carries.** The service holds a bag of offers keyed by opaque bytes and no directory of people.
- **A token does not carry authenticity.** A service cannot tell two tokens minted at a real meeting from two minted by one person on one machine, so it cannot tell a real pair of gardeners from somebody planting invented crossings. What it prevents is anybody planting *somebody else's* plant or answering for them. **Spam is abuse control and is not built** — rate limiting belongs in front of the service, and the walk is append-only, so spam is expensive to undo.
- **This supersedes *a plant is published by a plot, proved by a key*** for the Long Walk only. That argument (`WEBSITE.md` §*Who can put a plant there*) is about a page carrying a name, and its premise is that a seed is public. A token is not. A plant's own page still needs the plot and the sign-in.
- **A Long Walk plant carries no name, no note and no date.** So this consent is about one thing: the plant standing where anyone walking the garden can come across it. The name-and-note flow is a plant's own page and is a second consent with its own screen — folding it in here would publish prose on a yes given to a different question, which `PHASES.md` forbids.
- **A withdrawn planting is hidden, not deleted.** The walk stays append-only, the slot stays taken, and the border keeps the gap.
- **The invitation line sits above the row of figures, not under the heading** (Marcus, 19 September): between the title and the garden there is sky, and sky holds the sun, the moon and the stars and nothing else.

## What cannot be shared, and why
- **Every plant grown before today.** No tokens, so no invitation is possible, ever. The app says nothing rather than offering a row that cannot work.
- **Anything grown from a link.** An offer link is forwardable, so a secret in one is held by everybody it reached. Whether the *reply* link should carry a token — letting the offerer be reached but not the replier — is open, and is a change to the link format.

## Also done, 19 September, after the first write-up
- **Rate limiting** (`Server/.api/Limits.php`): 20 offers, 60 answers, 30 withdrawals and 240 askings an hour per address, answered `429` with `Retry-After`. In PHP because 20i's vhost is not ours, so it caps what is **written** rather than what arrives — the half that matters on an append-only walk. What is stored is a salted digest and a count, dropped once the window passes; the salt is random per install and lives in the database, so the table cannot be read back into addresses. `REMOTE_ADDR` only: a forwarded header with no known proxy is written by the caller. `tools/reference/check_limits.php`, 11 checks, in CI — the one worth having is that the allowance **comes back**, since a limit that counted for ever would lock somebody out of their own garden by the second week.
- **The service is deployed.** `/api/walk/offer`, `/pending`, `/answer` and `/withdraw` answer on peacegarden.app; `/plant` still answers 403; `tools/deploy.sh` checked every path. The rate-limit tables migrated on the live MySQL, which could only be proved there.
- **The plant detail screen**: `StageVeil` takes the light off the plant while the details are up, because a tall plant fills the glass and every word was drawn on its stem. One gradient, so no edge: strong at the top for the name, a clear window through the middle, nearly solid at the foot where the meeting and the three controls are. Checked dark and light.

## Also done, 20 September
- **The walk is copied every night, and the copy is proved to come back.** `Server/.api/backup.php` runs from cron at 03:17, copies `long_walk`, `long_walk_lock` and `walk_offers` — not the rate limiter's arithmetic, which would hand back spent allowance — and **reads each copy back before filing it**, because a dump cut short is a valid gzip of a valid beginning and restores most of the walk in silence. `tools/backup.sh` pulls them to `~/Documents/Peace Garden backups`, which is the copy that survives losing the account. `--restore-test` loads one into an empty MariaDB (Docker) and then **replays** every arrival into a second one by the same rule: a row count cannot see a lost ordering, because each restored row is individually plausible and the walk is wrong. `--rehearse` sows a walk of its own, since the real one is empty, and then deletes an arrival from the middle and requires the check to fail. `tools/reference/check_backup.php` holds the nightly half in CI.
- **The consent screen has the plant on it.** `ShowInGardenView` is now the plant, `StageVeil(cut: .reading)`, and the words over it. The veil is cut to the words rather than to the plant — a narrow window low down where the stem is — and that window is what closed the gap between the facts and the buttons. The footnote is prose instead of tracked capitals, and the plant's name clears Close.
- **Starting again takes the plants down first.** The contact tokens live in the phone's garden and nowhere else, so *Reset everything* and *Empty the garden* were permanent in a second way: wiping them while a plant stood in the peace garden left it standing for good. Both rows now run `GardenModel.takeEverythingBack()` first, one plant at a time (the service counts withdrawals per hour), and **if the garden cannot be reached, nothing is reset at all**. The consequence gains a clause only while something is standing.
- **The browser is under the same sky as the phone.** The field's own decisions — `faintest`, `fieldOfView`, radius, alpha, tint, and the x/y mapping — moved from `StarField` into `Sky`, so both renderers are ports of one thing. `tools/wasm/web/sky.js` draws it on a 2-D canvas behind the walk; `SkyVectorTests` records what the Swift sees and `tools/reference/check_sky.mjs` holds the JavaScript to it, including a sample of the real catalogue placed from four latitudes. Exact for arithmetic, a billionth of a degree for anything through libm.

## Next, in the order I would do it
1. **Sign in with Apple**, for a gardener's own plot and a plant's own page — the part the tokens deliberately do not cover, and the thing blocking the **Peace garden** section `WEBSITE.md` asks for in Settings.
2. **Turn the sky with the plot.** The plot turns in quarter turns and the sky does not follow. Nearly free — the field of view is already 220° of a full circle — and it would mean turning the garden turns your view of the sky.
3. **The Long Walk has no public page.** `tools/wasm/web/walk.html` is a local preview; `/garden` on the site is the 2-D area walk. The sky is ready for the page before the page exists.
4. **Watch the asking against the live service** with a fresh fixture. Note that a plain launch now talks to peacegarden.app, so the fixture's Ada plant comes back **declined** from the live test earlier — launch with `-pgPlots http://127.0.0.1:9` to see the local standings.

## What I would look at again on screen
- The invitation capsule is assertive beside the figures.
- On the detail screen the age caption still sits **on the flower head** of a tall plant. The veil is strong enough there to read it and no stronger, because the alternative is dimming the one part of a spire worth seeing.
- The **Milky Way is not in the sky** and the Wild Fields are described as lit by it. It is unresolved starlight rather than catalogue stars, so it needs its own treatment.

## Traps, added to the previous list
- **`Data` encodes as base64.** A token written base64 on disk and sent as hex is two spellings of one secret; `MeetingTokens` has a hand-written `Codable` for this reason and `SeedID` beside it is hex.
- **`Server/.api/config.php` is local, gitignored, and was pointing at a dead session scratchpad.** It now points at this session's; set it to somewhere that survives before relying on a local walk. The previous 120-arrival local database is untouched at its old path.
- **A simulator fixture's tokens must be hex**, and dates `.iso8601` (as before). `tools/fixture/garden.py` writes a garden with one plant in each standing, and its header has the command.
- **Injected taps reach SwiftUI buttons** and still do not reach the SceneKit recogniser. Both screens here are SwiftUI, so the whole flow can be driven from the command line.
- **Backticks inside a double-quoted remote `ssh` script run on the Mac.** A comment in `install_cron` containing `` `crontab -l` `` executed it locally, and `set -eu` in the same script silently installed an **empty** crontab because `crontab -l` exits 1 with no crontab and killed the subshell before the new line was echoed. Both caught by checking what the far end actually holds.
- **There is no MySQL client on the Mac**, so `--rehearse` takes its copy with the database's own dumper inside the container — but asks `backup.php --tables` and `--preamble` for the shape, so there is one idea of what a copy holds rather than two.
- **Trig will not match bit for bit across languages.** Darwin's libm and V8's are each correct to about an ulp and not to the same bit. Pin arithmetic exactly and give library calls a tolerance stated in the units of the thing measured.
