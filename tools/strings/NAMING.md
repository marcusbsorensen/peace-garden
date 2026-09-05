# Naming the ten areas of the garden

Ten names, in forty-two languages. `tools/strings/commission.py --areas <code>`
prints this brief with one language's own material filled in — the ten areas,
what each one is a place for, and the words your language has already settled
on. Read that rather than this file alone.

## This is naming, and it is neither of the other two jobs

Three kinds of writing go into this site and they take opposite instructions.
Being handed the wrong one is the main way this commission goes wrong.

| | The job | The instruction |
| --- | --- | --- |
| **The passage banks** | 30 lines a theme, from your language's own writers | Never a translation. `tools/quotes/BRIEF.md` |
| **The six paragraphs** | How the app works | A translation, and the claims are the specification. `BRIEF.md` |
| **The ten area names** | Ten places in a garden | **Naming.** This file |

The middle one says *do not go looking for a better idea than the English; go
looking for the plainest way your language says this one*. **That instruction is
wrong here**, and reading it across is the failure this brief exists to prevent.

An area is a real place in a garden. A cold frame, a glasshouse, a seedbed are
objects your language's gardeners have handled for centuries and already have
words for. You are not translating the English name of the thing. **You are
naming the thing.** Where the two come out the same, good — most of them will.
Where they do not, the name your own gardening already uses wins, every time,
and it is not a compromise when it does.

The clearest case is `areaPattern`. The English is *The Knot Garden*, a Tudor
form of low interlaced hedging. A French translator working from the English
writes *le jardin de nœuds*, which is fluent, faithful, and names nothing that
exists. The right answer is *parterre de broderie* — France's own tradition of
the same idea, under its own name, which is not a translation of anything.

## What is already decided, and is not yours to reopen

- **The ten areas and where they sit.** The map is a projection of the ten
  themes' own positions and it does not move. You are naming ten fixed places,
  not choosing them or their order.
- **Which theme each area is for.** Printed under every name, with the three
  thirds that theme divides into and examples from each. **Read those before you
  name anything** — the name has to cover the whole theme, and two of the ten
  were changed in English precisely because they covered only part of it.
- **Informal address, everywhere**, and **the vocabulary your language has
  already chosen** for *seed*, *garden*, *gardener*, *planted*. Both as in
  `BRIEF.md`. `commission.py` prints your catalogue.
- **The plant names stay Latin.** Those are invented and belong to no language.
  An area name is the opposite case, which is why this commission exists.

## What a name is

- **A name, not a sentence and not a description.** *The Seedbed*, not *the
  place where seeds are sown*. If the only thing your language can offer is a
  description, say so in your notes and give the shortest one that could be
  written on a sign.
- **No full stop.** Nothing here ends a sentence.
- **The article is your language's business.** English puts *The* on all ten
  because they are places on a map. Do whatever your language does when it names
  a place: Danish suffixes it, Russian has no article at all, Greek declines it.
  Do not carry the English *The* across as a word.
- **Sentence case**, as everywhere else on the site. The tracked-out capitals on
  the page are set by the stylesheet, and some languages are excluded from that —
  it is handled for you.
- **It has to fit a cell.** The map draws each name in a box about 8.5rem wide,
  two comfortable lines. `check.py` warns past 34 characters. A name that runs
  long makes its whole row of the map taller, which is a wobble rather than a
  break — but it is the one layout constraint here, and a name that needs three
  lines is usually a description.
- **The ten have to be ten different names.** Two areas called the same thing is
  the one fault a reader cannot work around: the map is how you know where you
  are. `check.py` fails on it.

## Three of the ten cannot be translated, only renamed

Each of these names something that exists in English and may not exist where you
are. **Do not invent a calque.** Reach for your own tradition; where there is
none, name what happens in the place.

- **`areaPattern` — The Knot Garden.** A Tudor form. Use your own tradition's
  name for a garden laid out as a deliberate pattern — *parterre de broderie*,
  *giardino all'italiana*, *chahar bagh*. Where there is none, name the pattern
  rather than the hedge.
- **`areaRenewal` — The Coppice.** An English woodland practice: cutting a tree
  to the stool so that it grows back stronger. *Taillis*, *Niederwald*,
  *stævningsskov* are forestry words rather than garden ones, and outside
  northern Europe the practice is largely absent. Name the place for what happens
  there — cut, and it comes again. **A description is acceptable here** where it
  is not elsewhere.
- **`areaMeeting` — The Crossing.** Two senses in one English word: where paths
  cross, and crossing two plants to make a third. *Croisement*, *cruce*,
  *incrocio*, *krydsning* hold both. **Japanese, Korean, Chinese, Arabic,
  Hebrew, Finnish, Hungarian and Basque have to choose one.** Keep the meeting.
  A word that means only the horticultural cross is the wrong half — this is the
  area the whole app is named for, and what happens there is two people.

## When you are done

Write your ten values into `Server/strings/<code>.json`, under `strings`,
replacing the `null`s on the ten `area*` keys. Then:

1. Run `python3 tools/strings/check.py`, which checks the ten are all there, all
   different, none left in English, none a sentence, and all short enough for the
   cell.
2. **Look at the map.** `python3 tools/site/serve.py`, then
   `http://localhost:8801/t`, the word at the door is `peace`, and pick your
   language's gardener. `/g` is the garden; the ten are the map you land on.
   Walk into two or three of them with the arrow keys.

A missing name falls back to English silently and per name, so a half-finished
commission shows a mixed map rather than an empty one. That is deliberate — it
is how a language ships in pieces — and it is also why `check.py` asks for the
ten together before it calls a language done.

**Then somebody who reads the language has to look**, which is a different job:
`docs/REVIEWING-A-LANGUAGE.md`.
