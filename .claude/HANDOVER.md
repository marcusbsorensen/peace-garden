# Peace Garden: the asking — handover 19 September 2026

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

## Next, in the order I would do it
1. **Deploy the service.** The four new routes are in the repo and not on peacegarden.app. `tools/deploy.sh`; the server's `config.php` is never touched. Until then the app's asking answers 404 against the live host.
2. **Rate limiting in front of `/api/walk/offer` and `/answer`**, before anybody knows the addresses. The walk is append-only.
3. **Backups and a tested restore**, still owed, and cheapest while the database is nearly empty.
4. **Sign in with Apple**, for a gardener's own plot and a plant's own page — the part the tokens deliberately do not cover.
5. **Settings' copy is now out of date** in three places `WEBSITE.md` §*What this asks of the app* names: the username's line, *Reset everything* saying nothing about a plot, and a **Peace garden** section that appears once something has been shared.

## What I would look at again on screen
- `ShowInGardenView` has a **large gap** between the facts and the buttons; first light's fix — one column between two spacers — is the pattern.
- Its footnote is **small caps across three ragged lines** and reads as a warning label.
- The screen is **all words, no plant**, which no other screen in this app is.
- The invitation capsule is assertive beside the figures.

## Traps, added to the previous list
- **`Data` encodes as base64.** A token written base64 on disk and sent as hex is two spellings of one secret; `MeetingTokens` has a hand-written `Codable` for this reason and `SeedID` beside it is hex.
- **`Server/.api/config.php` is local, gitignored, and was pointing at a dead session scratchpad.** It now points at this session's; set it to somewhere that survives before relying on a local walk. The previous 120-arrival local database is untouched at its old path.
- **A simulator fixture's tokens must be hex**, and dates `.iso8601` (as before). `tools/fixture/garden.py` writes a garden with one plant in each standing, and its header has the command.
- **Injected taps reach SwiftUI buttons** and still do not reach the SceneKit recogniser. Both screens here are SwiftUI, so the whole flow can be driven from the command line.
