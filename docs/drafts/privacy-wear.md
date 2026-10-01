# The privacy page: paths that visitors wear

Draft, 2 October 2026, English only. Not in `strings.js`: Marcus reads it
first, then it is translated, and wear stays off on the live site until it has
been (`docs/WEB-GARDENS.md` §*Paths that visitors wear*).

## The paragraph

> When you walk through the Wild Fields on this site, by dragging the field or
> pressing its arrows, the page notes which squares of ground the middle of
> your view crosses, each half a metre across. Every half minute or so, and
> when you leave the page, it sends that list of squares to the Wild Fields, in
> no particular order, and nothing with it. The Wild Fields keep one number for
> each square, for how worn it is, and draw the numbers for everyone to see as
> paths. Each square counts a few crossings a day at most, and every number
> halves each month, so a path stays only while people keep walking it. The
> numbers are all that is kept: they hold nothing about anyone, not who walked,
> when, or where any one person went. Only walking counts: looking around,
> coming closer and opening a plant send nothing.

## What each sentence rests on

- *Dragging the field or pressing its arrows*, *the middle of your view*,
  *only walking counts*: `walkOn` in `Server/assets/js/wear.js`, which counts
  a drag and the pad's four directions, and nothing else.
- *Every half minute or so, and when you leave*, *in no particular order*,
  *nothing with it*: `EVERY`, the flush on `pagehide`, the sorted batch and
  `sendCells` (no credentials, no referrer) in the same file.
- *One number for each square*, *a few crossings a day*, *halves each month*:
  `Server/.api/WildWear.php` — `wild_wear` is the cell, its wear and today's
  count; `CAP` is six; `HALF_LIFE` is thirty days. The field's one date is
  the day it was last faded, which is about the field, not any visit.
- *Holds nothing about anyone*: no row per visitor or per batch, no time of
  any visit, `WITHOUT ROWID` on SQLite. The address meets only the rate limit,
  which `privacy5` already describes (a scrambled form, for up to an hour).

## Two choices for Marcus

1. **Key and place.** Recommended: `privacy9`, read straight after `privacy8`,
   so the two Wild Fields paragraphs sit together. Or: fold it into
   `privacy8`, which is already the longest paragraph on the page.
2. **Half a metre.** Recommended: keep it, because it tells a reader how
   coarse the squares are, which is most of why they say nothing about a
   person. Or: drop it, for a shorter first sentence.
