# Commissioning a passage bank

The brief handed to every agent that wrote one of the round-two banks, kept
because **round three exists** — the alphabets not yet covered, and whatever
comes after them — and because everything in it was learned by a bank failing.

`<scratch>` below is wherever the working files live; give the agent a real
directory. `tools/quotes/brief.py` writes `brief.swift`; `NON-LATIN.md` beside
this file is the addendum for a bank in another alphabet.

You are writing **one** bank, for one language, alone. Nobody else is writing it.

## What to produce

A single file at `<scratch>/banks/<Language>.swift` holding nothing but
`Passage(...)` lines under `// MARK: -` headings, one heading per theme. No
wrapper, no `enum`, no `extension` — `tools/quotes/assemble.py` puts those on.

**360 passages: ten themes, three subthemes each, twelve per subtheme.** Twelve
is the floor and it is enforced. Round-one banks landed between 349 and 380.

## Write to disk as you go

A theme at a time, into your own directory, rather than holding all 360 passages
until the end. **Croatian stalled after ten minutes and produced nothing at
all**, and Spanish failed three times the same way when round one was written.
An agent that has written six themes to disk and then stalls has lost four
themes; one that has written nothing has lost everything, and the next attempt
starts from an empty file.

## Working files go in your own directory

If you split the work into parts, put them in `<scratch>/banks/<language>/`, not
in `<scratch>/banks/` itself. **Twenty of these are running at once and several
have already reached for `part1.swift`** — one agent overwrote another's working
file that way and had to rewrite half a bank. The finished file still goes at
`<scratch>/banks/<Language>.swift`; only the scraps need a room of their own.

## What to read first, and all you need to read

1. `<scratch>/brief.swift` — 238 lines. The `Passage` struct, the shipping
   rules, the `Theme` and `Subtheme` enums with their notes, and one sample
   passage per subtheme so you can hear the register.
2. This file.

**Do not read `App/PeaceGarden/Views/Quotes.swift`.** It is 2,596 lines and
growing. The Spanish bank failed three times and every failure died partway
through reading it. The brief exists so you do not have to.

You may read one existing bank if you want a second example of the file shape —
`Quotes+Turkish.swift` is the shortest at 394 lines. One is enough.

## The rules that matter most

- **A bank is not a translation.** The other banks are not a source text. Draw
  on what *this* language has: its own writers, its own proverbs, its own words.
  Two banks agreeing on a line means one of them was translated, and that is the
  one thing a bank must not be.
- **Register is a rule, not a preference.** These passages are read by two people
  who have just met and crossed a seed. Four round-one banks had to drop
  verified, out-of-copyright, famous lines because they read as a rebuke or as
  an elegy. A line can be true, beautiful, correctly attributed and still wrong
  here. Warmth, plainness, and the register of something said rather than
  declaimed.
- **Attribution is a claim about a real person.** Every quotation must be
  out of copyright and correctly attributed. If you are not certain a line is
  really by whom you think, cut it. A misattribution ships as a false claim
  about a dead writer. Proverbs take the form the other banks use for proverbs.
  **Never invent an attribution, and never attach a real name to a line you
  composed.**
- **Go to the raw source, not to a summary of it.** The Estonian bank found this
  the hard way: one summarised fetch of a proverb collection came back visibly
  invented. Fetching the raw wikitext of the same page gave two thousand
  attested proverbs, and comparing the two caught a fabrication that would
  otherwise have shipped as a claim about a language. It also caught two
  wordings that were subtly wrong. **A search result that paraphrases a source
  is not a source.** Where a proverb collection or a text exists in raw form,
  read that; where it does not, corroborate a line against a second independent
  place before using it.

- **`quietAsASound` is the hard one.** Every round-one bank struggled and every
  one got there. What worked: acoustic fact, quiet as it is marked in law or
  custom, and the oblique words a language has for it — not more synonyms for
  silence.

## What is already taken

Nine round-two banks are written: Catalan, Czech, Finnish, German, Hungarian,
Polish, Portuguese, Romanian, Turkish. Round one: Danish, Dutch, English,
French, Italian, Norwegian, Spanish, Swedish. Do not lean on a neighbour's
material — a Slovak bank made of Czech lines is a translation with extra steps.

## Your language

<LANGUAGE NOTE>

## When you are done

Run, from the repository root:

    python3 tools/quotes/assemble.py <Language> <scratch>/banks/<Language>.swift --check-only

Fix whatever it reports and run it again until it passes. It refuses anything
that would fail `QuoteBankTests`, so a pass here means the bank is sound.

Then report back: the passage count, the check result, anything you had to
decide, and — this matters — **any word in this language for peace, quiet or
meeting that says something the subthemes do not.** Round one found Turkish
*barış*, built on *barışmak*, to make peace *with one another*; and Polish
*pokój*, one word for peace and for a room. Those change how a subtheme is
understood. Say if you found one.

Do not edit any file in the repository. Do not touch `Quotes.swift`,
`QuoteBanks.swift` or any `.xcstrings`. Write your one file and stop.
