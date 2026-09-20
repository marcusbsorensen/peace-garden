# Peace Garden: the ten areas — handover 20 September 2026

One thing this session: **the garden stopped being one long border and became ten areas, nine of them shut.** The previous handover, whose traps still apply, is at `git show ea4cf86~5:.claude/HANDOVER.md`.

## State
- **Done, tested, pushed, deployed.** `ea4cf86` on `origin/main`. SeedCore 178, app all passing, `check_areas` 47 checks, `check_long_walk` 600 placements, `check_offers`, `check_limits`, `check_backup` 22, `check_sky` 9729, `export.py --check` in step.
- Live: `https://peacegarden.app/api/garden` answers the ten with `travel` open; `/walk` grows the Long Walk; `/g`'s notice no longer calls it invented.

## What is built

### The service knows there are ten areas (`2f1fee2`, `c0fc8f9`, `cb96142`)
- `SeedCore/WebGardens/Areas.swift` — `Area`, `isOpen`, `open`, `table`, a lenient `init(from:)` that falls back to travel. `Server/.api/Areas.php` is the port; `tools/reference/check_areas.php` holds them together in CI, and it was watched failing.
- `GET /api/garden` lists the ten and which are open. An offer carries `area`; a name that is not one of the ten is **400**, an area that is not planted yet is **409** — the request is well formed and would be right on another day, and that difference is what the gardener gets told.
- **A table for each area, not one table with an area column.** `plot`, `side`, `tier` and `slot_index` mean a double border on a travel row and would mean a compartment and a quarter on a knot-garden row. And `long_walk` is live and append-only: a new area is a new table beside it rather than a migration against real plantings.
- **The area is taken on trust**, like `height` and `family` already were. A service cannot grow a plant. What it *can* check is that the seed is the cross of those parents at that meeting, which is what stops one person planting in another's name.

### A plant goes to the area its own name belongs to (`edebfe6`)
- `GardenModel.offer` sends `Arrangement.area(of: record)` — the plant's **own** genus head, never the one its seed would mint afresh. Over fourteen crossings drawn for the mockup all fourteen genus heads differed, so minting would have filed every plant under an area with nothing to do with its name and looked sensible doing it.
- **Flipped while the walk was empty**, on Marcus's call, because the walk is append-only: every plant shared before the flip would have gone permanently into travel whatever it was.
- Nine plants in ten are now refused. `ShowInGardenView` says so **before** it asks: a plant whose area is still to be planted gets two sentences and no question. The 409 keeps its own sentence underneath for an app older than the service's list — the general refusal sentence says *try again in a little while*, which would be false.

### The syllables moved into the core (`c3a3e73`)
- `Quotes.Theme.genusHeads` was the app's, and the one place that most needs it is not the app: **the website files plants into areas and the website is SeedCore compiled to wasm.** So the table is `Area.genusHeads`, with `Area(genusHead:)` and `Area(genome:)`, and the app's theme reads it.
- `Arrangement.area(of:)` is the core's reading; `theme(of:)` follows from it. The area is the fact, the theme is the app's name for it.

### The ten ambassadors (`3437edf`)
- `SeedCore/WebGardens/Ambassadors.swift`, `AmbassadorTests`, `tools/reference/ambassador_vectors.json`.
- **Found, not chosen**: minted in order from `peace-garden.ambassador.v1/<n>`, keeping the first seed to land on each area — ten inside 82 tries. The test runs the search again and checks it arrives at the same ten, so the hexes cannot quietly become hand-picked and a change to `Genome`'s naming fails loudly rather than replanting every area.
- *Halula crassicaulis* for the Long Walk, *Olyne paniculata* for the Quiet Garden, *Melyrina latifolia* for the Crossing.
- All ten sown on one pinned day, a month before the garden opened, because the slowest takes 21.4 days to mature. Held to it by test rather than assumed.

## The decisions waiting for Marcus

1. **How an ambassador stands in a plot.** It is not a shared plant — nobody put it there, nobody can withdraw it — so it should not be a row in an area's table. But the placement rule runs in the **plot service**, so either the service plants it as a row anyway, or every drawer of a plot knows to put it in before the arrivals. `LongWalk.Walk` could grow an `opened()` that plants the travel ambassador first, which needs no new rule and no reserved slot, but it has to be the same on both sides of the port. **Not built, deliberately.**
2. **Which slot is an area's specimen.** WEB-GARDENS.md says the ambassador stands in it. No template names one, including the Long Walk's.
3. **The second area.** The Quiet Garden is cheapest — its hedge already exists in `GardenStructures.swift` — and its rule is the most distinctive ("the fewest plants per plot of any area, by rule"). **Not started, on purpose:** the Long Walk's own notes record that *without the path and the hedges, a plot is a scatter of plants on grass — the rule is right and invisible.* Designing a second rule without being able to look at it rendered repeats exactly that. It wants a session with eyes on it.

## Traps
- **The browser pane throttles `requestAnimationFrame` to 1 Hz** regardless of `document.hidden` or fronting the tab. Anything timed in it is wrong by an order of magnitude. This cost a false "30–60 seconds to grow three plots" once.
- **The language banks nest under a `strings` key.** Looking at the top level and concluding a key is missing is a mistake already made once, on the area names — 41 of 42 had named all ten.
- **The Long Walk *is* the travel area.** It is both the name of an area of the shared garden and the thing `/walk` shows. Renaming either on the assumption they are two things is a wrong turn already taken and reverted.
- **20i's CDN normalises `Accept-Encoding`.** `br, gzip` reaches PHP as `gzip`; `br` alone reaches it with nothing. Brotli never arrives. Measured 20 September; do not measure it again.
- **`/.api/` and `/.pages/` are refused by nginx's dot-directory rule**, so only `index.php` can serve from them. That is what `/plant.wasm` is doing in `Server/index.php`.
- Adding or removing an app file needs `xcodegen generate`. Nothing this session added one.

## Still open from before
- **A plant's own page** (capability URL). WEBSITE.md says it is built first and it is what makes a plot worth having.
- **Sign in with Apple**, deliberately behind the plant page.
- The **Milky Way** is absent from the sky though the Wild Fields are described as lit by it.
- The **Wild Fields** need release-to-a-place; the **curator's tool** is unbuilt.
- Two dotted threads from plants standing near each other run almost on top of one another below the plot.
