# Extra rules for a bank in another alphabet

Read `ROUND-TWO.md` first. Everything in it applies. This adds what changes when
the script is not Latin.

## The text is the text

Write the passages in the language's own script, unromanised, as ordinary Swift
string literals. No transliteration, no escaping, no parenthetical Latin gloss.
`assemble.py` handles any character that is not a quote or a backslash, and the
app has drawn non-Latin text since it was built.

**Do not add a translation.** A passage is read by somebody who reads that
language; an English gloss beside it is for somebody else, and it is the one
thing that would make the bank a parallel text rather than a bank.

## The source line

`source` is the attribution, and it is read under the passage. Write it in the
same script as the passage — a Greek reader gets a Greek poet's name in Greek.
Where a work has a title, give it in the original. The site and the app both set
`lang` on the passage block, so the two are announced correctly.

## Register, again, because the corpora are older

Round one found that four banks had to drop verified, out-of-copyright, famous
lines because they read as a rebuke or as an elegy. **That risk is higher here.**
The out-of-copyright material in these languages skews toward the epic, the
national and the devotional, and all three reach for a register that is wrong for
two people who have just met and crossed a seed.

Two specific traps:

- **The national poet.** Every language on this list has one, and their most
  quoted lines are usually about the nation rather than about a person. A line
  about a homeland is not a line about a meeting.
- **The philosophical chestnut.** The English bank already carries Plato and
  Marcus Aurelius. A Greek bank assembled from the same shelf is the English
  bank in Greek, which is precisely what a bank must not be.

## Copyright, which bites harder in these languages

Most of these are life-plus-seventy, and the twentieth-century writers who are
most quoted are frequently *not* clear. Check a death date before you use a name,
and cut what you cannot verify. **Never invent an attribution, and never attach a
real name to a line you composed.** Folk material — proverbs, songs, sayings —
is attributed the way the other banks attribute proverbs, to what it is rather
than to a person, and it is usually the richest and safest seam here.
