# Commissioning the site's own prose

Six strings, in forty-two languages. `tools/strings/commission.py <code>` prints
this brief with one language's own material filled in; read that rather than
this file alone, because half of what matters is the vocabulary your language
has already settled on.

**This is a translation, and the passage banks are not.** `tools/quotes/BRIEF.md`
governs those and opens by saying a bank must never be a translation — it is
written out of what that language has of its own. This job is the opposite:
these six sentences say specific things about how the app works, and every
language has to say the same things. Do not go looking for a better idea than
the English. Go looking for the plainest way your language says this one.

## What is already decided, and is not yours to reopen

- **Informal address, everywhere.** Dutch *je*, Danish *du*, German *du*, French
  *tu*. It was decided once for the whole app and the thirteen strings already in
  your catalogue are written that way. See `docs/LANGUAGES.md`.
- **The vocabulary.** Your language has already chosen its words for *seed*,
  *gardener*, *planted*, *garden* and the rest, in the thirteen commissioned
  strings. `commission.py` prints them. **Use those words.** A page that calls a
  seed two different things in four paragraphs is worse than a page in English.
- **Numbers are numerals, from 2 up.** *2 phones*, *3 seconds*, *10 days* —
  never *two*, *three*, *ten*. **One is the exception** and stays a word in every
  language. Use whatever digits your language writes with: Eastern Arabic
  numerals in Arabic, Western ones elsewhere. Decided by Marcus on 5 September
  2026, and it inverts the usual advice to spell out small numbers.

  Two things follow, and they are the reason the rule is worth having. A digit is
  the one token on the page that a reader of any of the forty-three languages
  recognises without it being translated for them — and a digit is read at a
  glance where a word has to be read. This is a site somebody opens once, on a
  phone, from a message.

  Where the number is grammar rather than a count, the grammar wins: a dual form,
  an agreement, or an idiom that happens to contain *two* is not a place to put a
  digit. If your language cannot take a numeral in a particular sentence, say so
  rather than forcing it.

- **The area names stay English.** *The Cold Frame*, *The Seedbed*, *The
  Crossing*. They are proper nouns, like the plants' binomials. If one appears in
  your draft, you have gone wrong.

## The register

Quiet, plain, and addressed to one stranger. The whole site is written for
somebody who has been handed a link by a person they met, and who may be
wondering whether it is a scam.

- **No imperatives and no marketing.** Nothing is being sold and nobody is being
  told to do anything. Not *Download now*, not *Discover*, not *Get started*.
- **No exclamation marks.**
- **Say what a thing is and does**, rather than what it is not. *It stays in your
  browser* rather than *it never leaves*. A negative reads as a warning even when
  it was meant as a reassurance, and this page has a reader who is already
  slightly on guard.
- Sentence case. The tracked-out capitals on the page are a separate voice, set
  by the stylesheet, and some languages are excluded from it — that is handled
  for you.

## The rule that matters most

**Each of these sentences makes a claim about how the app actually works, and a
fluent translation can quietly make a different one.**

This is not hypothetical. On 4 September `growBody` was found to have said, in
English, that the same two seeds always make the same plant. It is fluent, it is
the obvious sentence, and it is false: the derivation mixes both seeds *and* a
random nonce from each side, precisely so that meeting somebody again grows a
different plant. It had stood for weeks.

So `commission.py` prints, under every string, **what it must say and what it
must not**. Those are the specification. If the natural sentence in your language
cannot carry the claim, write a less natural one and say so in your notes — do
not write the fluent sentence that says something else.

## When you are done

Write your six values into `Server/strings/<code>.json`, under `strings`,
replacing the `null`s. Then:

1. **Remove the `awaiting` note** at the top of that file. It says the prose is
   still English on purpose, and once you have written it that is no longer true.
   `check.py` will fail while it is still there.
2. Run `python3 tools/strings/check.py`, which is mechanical and fast: it checks
   the placeholders, that no English has been left behind, that the lengths are
   sane for the layout, and that you used the vocabulary your catalogue had
   already settled.
3. Run `python3 tools/site/export.py --check`.
4. **Look at it.** `python3 tools/site/serve.py`, then `http://localhost:8801/t`,
   the word at the door is `peace`, and pick your language's gardener. Open `/s`
   with no seed for the four about strings, and a seed link for the other two.
   Two bugs were found in the first ten minutes of somebody doing this in Arabic
   and Hebrew, and neither was visible in the code.

**Then somebody who reads the language has to look**, which is a different job
and is written up for them in `docs/REVIEWING-A-LANGUAGE.md`.
`python3 tools/site/mintlink.py --review <code>` prints the links that go with
it — two of the six strings live only on a page that has a seed in it, so
without a minted link a third of the commission cannot be seen at all.
