# Peace Garden — handover 3 September 2026

*An overnight session, run with Marcus asleep and told to decide, document and
keep going. Every decision it made alone is either in `docs/FOR-REVIEW.md` or
named under **Decisions made**, so all of it can be overturned.*

## Goal

Three fixes on `main`, finishing the previous handover's next step. Then a
branch, `round-two`, for the night: wave two of the passage banks, support for
the other alphabets, the site's settled words in sixteen languages, and the
website stages already specified. Situational navigation — a random plant, named
areas, a pad for stepping to neighbours, and a key for every action — was asked
for partway through and is built.

## State

`main` at `0fda1bb`: the glyph sheet's broken entry point, the hole in the foot
of every stem, and the garden mark's unreadable grass. **`round-two` is branched
from it and not merged.**

**Forty passage banks in the app**, up from seventeen. Landed overnight:
Estonian, Lithuanian, Slovene, Latvian, Ukrainian, Slovak, Welsh, Basque,
Galician, Serbian, Japanese, Chinese, Icelandic, Irish, Albanian, Korean,
Hebrew, Bulgarian, Croatian, Russian, Arabic, Greenlandic, Greek. Still being
written when this was filed: Macedonian, Belarusian, Maltese, Greenlandic, Arabic. **Those agents belong
to that session — clearing it loses them and the scratchpad both.** Two never got a slot,
Faroese and Luxembourgish — their notes are in the session scratchpad's
`QUEUE.md`, and the brief they need is now `tools/quotes/BRIEF.md`.

**Verified.** 72 SeedCore tests and 23 app tests after every landing. All four CI
checks. Every bank checked by `assemble.py` and independently for overlap against
every bank before it; the Cyrillic ones checked for actually being Cyrillic. The
stage driven on a simulator in both directions and at five ages. The site driven
in a browser: the map, an area, the walk, the sheet, the pad at the map's edge,
`/s` with a real seed link, and Ukrainian, Japanese and **Arabic** passages drawn
by the app, reached through *Meet an imaginary gardener*. The Arabic one is the
one that mattered: right-to-left layout, and the source line العربية with its
joins intact and no letter-spacing. Had `Chrome.neverTracked` or the bank-locale
fix been wrong it would have come out as a row of disconnected forms.

Forcing RTL needs both `-AppleTextDirection YES` and
`-NSForceRightToLeftWritingDirection YES`; the first alone does nothing.

**Unverified.** Any bank whose agent had not reported when it was landed — run
`python3 tools/quotes/refresh.py <banks dir>` and it will say. It reported
nothing moved at the time of writing, but four commissions were still running.

**Greenlandic needs a Kalaallisut reader before it ships.** Its lexical and
morphological claims are sourced to a grammar its agent read in full, but the
sentences are composed rather than quoted — original prose built from attested
stems and affixes. That is a different risk from every other bank and its agent
said so plainly.

The right-to-left work has never been *read* by
somebody who reads Arabic or Hebrew — the layout is right in the sense that
nothing is upside down; whether it is good is not a question this repository can
answer about itself. Neither has a bank or an interface yet.

## Files

- `tools/quotes/BRIEF.md`, `NON-LATIN.md` — the brief every agent was handed.
  Kept because round three exists, and because everything in it was learned by a
  bank failing.
- `tools/quotes/land.py` — assemble, register, xcodegen, export, in that order.
  Use it for every remaining bank; then the thirteen site labels.
- `Server/assets/js/garden.js`, `keys.js`, `walk.js`, `plots.js`, `Server/g` —
  the map, the keyboard registry, the walk, and a stand-in for the plot service
  that says on screen that it is one.
- `docs/FOR-REVIEW.md` — **read this first.** The site's six prose strings and
  ten area names, with the argument and its alternatives, and one command to
  look at the garden while deciding. Nothing in it is live.
- `docs/WEBSITE.md` §*Walking it*, §*Every action on a key*;
  `docs/LANGUAGES.md` §*The other alphabets*.

## Decisions made

- **The garden's map is derived, and must not move.** Ten areas laid out from
  `Theme.position`'s first two principal components. Retuning a theme's position
  is now a change to the map.
- **A plant's cell comes from its seed and never moves.** Two may share a cell.
- **Drawn marks never mirror; layout does.** `View.drawnHand()`.
- **Arabic is never letter-spaced** — a joined script, and tracking severs the
  joins. `Chrome.neverTracked`.
- **The keyboard sheet costs one string**, because every row is labelled by the
  control it operates. Adding a shortcut must not add a commission.
- **Area names are English proper nouns, provisionally** — the argument the app
  already makes about plant binomials. First item in `FOR-REVIEW.md` and the one
  most likely to be overturned.

## Next step

Land the banks that finished after this was filed. For each:
`python3 tools/quotes/land.py <Language> <code> <file>`, then its thirteen site
labels, then `xcodebuild … test`, then one commit per bank. **Then run
`python3 tools/quotes/refresh.py <banks dir>` until it says nothing moved** —
not once. Agents keep revising after they first reach the count, and it caught
Galician on three separate passes. Finished files are in the
session scratchpad under `banks/`; if that is gone, the banks are gone and are
re-commissioned from `tools/quotes/BRIEF.md`.

## Traps

- **Twenty concurrent subagents is the ceiling**, and finishing agents do not
  free slots promptly. Commission in waves and keep a queue.
- **`cd` persists between Bash calls.** It bit again: an `xcodebuild` ran from
  `Packages/SeedCore` and silently tested nothing.
- **`GardenStoreTests` fails when the Mac's screen locks** — the protection
  class follows it, and CI never sees it because SeedCore runs on Linux there.
  Fixed by injecting the write options; the shape will recur.
- **A browser caches ES modules by URL.** A changed module can look missing;
  moving the dev server to a new port is the quickest way to be sure.
- **`assemble.py`'s floor is 10 and the brief asks for 12.** Passing the checker
  is not meeting the brief.
- **A file reaching 360 lines is not a finished bank.** Agents keep revising
  after they first hit the count. Welsh differed in seventy-one passages from
  the copy landed off its length, and carried real errors — a proverb spelled
  into nonsense, a non-word, hydrology backwards. `refresh.py` exists for this.
- **An agent that holds all 360 passages until the end loses all of them.**
  Croatian stalled at ten minutes with nothing written. The brief now says to
  write a theme at a time, into a directory of the agent's own — several reached
  for `part1.swift` and one overwrote another's.
