# Peace Garden — handover 3 September 2026

*A long overnight session that ran four strands at once: passage banks, the
website, non-Latin typography, and then a taxonomy redesign. They were
independent and it worked, but a fresh session should pick one — and the one to
pick is under **Next step**.*

## Goal

Finish round two of the passage banks, support the other alphabets, build the
website stages already specified, and add the situational navigation Marcus asked
for. All done. What came out of it is a fifth strand — making the plant names an
actual classification — which is designed and not built.

## State

`main` at `0fda1bb`. **`round-two` is branched from it, green, and not merged.**

- **43 passage banks**, up from 17. Every language on both round-two lists landed
  except **Faroese and Luxembourgish**, which never got an agent slot and are not
  written. The brief for them is `tools/quotes/BRIEF.md`.
- **The website**: `/g` walks the garden — derived map, nav pad, random, a key for
  every action — and its plant view draws a passage that changes with the reader's
  language without being a translation of the last one. Site labels in 16
  languages; the six prose strings deliberately left in English.
- **Non-Latin**: case and tracking split into separate rules. Verified on a
  simulator that Arabic draws right-to-left with its joins intact.

**Verified.** 72 SeedCore tests, 23 app tests, all four CI checks, `refresh.py`
quiet, export writing 44 files.

**Unverified.** Greenlandic's *sentences* are composed rather than quoted — its
lexical claims are sourced to a grammar, its syntax is not. It needs a Kalaallisut
reader before shipping, and its own agent said so unprompted.

## Files

- `docs/TAXONOMY.md` — the next real work. Read it first.
- `docs/FOR-REVIEW.md` — two decisions waiting on Marcus: the site's six prose
  strings, and whether ten area names get commissioned in 43 languages.
- `docs/WORDS.md` — what 43 languages said about peace, and why the convergences
  are the finding. Feeds the garden's type-specimen sections.
- `tools/quotes/land.py`, `refresh.py`, `BRIEF.md` — commission, land and verify
  a bank. `refresh.py` is not optional; see Traps.
- `Server/g`, `Server/assets/js/{garden,keys,walk,plots}.js` — the garden walk.

## Decisions made

- **The garden's map is derived from `Theme.position` and must not move.**
  Retuning a theme's position is now a change to the map.
- **A plant's cell inside an area comes from its seed and never moves.**
- **Drawn marks never mirror under RTL; layout does.** `View.drawnHand()`.
- **Arabic is never letter-spaced** — a joined script. `Chrome.neverTracked`.
- **The keyboard sheet costs one string**, because every row is labelled by the
  control it operates. Adding a shortcut must not add a commission.
- **The type-specimen plants live only in the shared garden** and never touch a
  person's own seed or their exchanges.

## Next step

`docs/TAXONOMY.md`, once Marcus answers the three questions at its foot — the
first, which archetype belongs to which genus, is the blocker. The concrete first
move is deriving the genus head from the floral plan instead of drawing it
alongside: `Genome.swift:210` and `PlantName.swift:66`. It renames every plant,
and nothing has shipped, so today is the cheapest this will ever be.

## Traps

- **`cd` persists between Bash calls.** An `xcodebuild` ran from
  `Packages/SeedCore` and silently tested nothing. Cost time twice.
- **A file reaching 360 lines is not a finished bank.** Agents keep revising.
  Run `python3 tools/quotes/refresh.py <banks dir>` *until it says nothing
  moved* — it caught Galician on three separate passes.
- **Twenty concurrent subagents is the ceiling**, and finishing agents do not
  free slots promptly.
- **Forcing RTL needs both** `-AppleTextDirection YES` and
  `-NSForceRightToLeftWritingDirection YES`. The first alone does nothing.
- **A browser caches ES modules by URL.** A changed module looks missing; move
  the dev server to a new port to be sure.
- **`GardenStoreTests` fails when the Mac's screen locks** — the protection class
  follows it, and CI never sees it because SeedCore runs on Linux there.
