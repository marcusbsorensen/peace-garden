# The privacy page: paths that visitors wear

**Settled by Marcus, 2 October 2026.** Drafted the same day in English; he
rewrote it, and his wording is `privacy9` in `Server/assets/js/strings.js`,
straight after `privacy8`. It is on the page only while wear is on
(`Server/index.php`), and is commissioned on its own (`WEAR` in
`tools/strings/commission.py`). The record is `docs/WEB-GARDENS.md`
§*Paths that visitors wear*, *Built on /dev*. Nothing here is still open.

## The paragraph, as settled

> When you walk through the Wild Fields on this site, by dragging the field or
> pressing its arrows, the page notes which squares of ground the middle of
> your view crosses, each half a metre across. Every half minute or so, and
> when you leave the page, it sends the Wild Fields that list of squares
> alone, sorted. The Wild Fields keep one number for each square, for how worn
> it is, and draw the numbers as paths for everyone to see. Each square counts
> a few crossings a day at most, and every number halves each month, so a path
> stays only while people keep walking it. The numbers are all that is kept: a
> count for each square of ground, the same whoever walked it and whenever.
> Only walking counts; looking around, coming closer and opening a plant leave
> the ground as it was.

## What each sentence rests on

- *Dragging the field or pressing its arrows*, *the middle of your view*,
  *only walking counts*: `walkOn` in `Server/assets/js/wear.js`, which counts
  a drag and the pad's four directions, and nothing else.
- *Every half minute or so, and when you leave the page*, *that list of
  squares alone, sorted*: `EVERY`, the flush on `pagehide`, the sorted batch
  and `sendCells` (no credentials, no referrer) in the same file.
- *One number for each square*, *a few crossings a day*, *halves each month*:
  `Server/.api/WildWear.php`. `wild_wear` is the cell, its wear and today's
  count, `CAP` is six, and `HALF_LIFE` is thirty days. The field's one date
  is the day it was last faded, which is about the field, not any visit.
- *A count for each square of ground, the same whoever walked it and
  whenever*: no row per visitor or per batch, no time of any visit, and
  `WITHOUT ROWID` on SQLite. The address meets only the rate limit, which
  `privacy5` already describes.

## The two choices, answered

1. **Key and place:** `privacy9`, straight after `privacy8`, and shown only
   while wear is on.
2. **Half a metre:** kept.

And the width of a path, judged on the renders: about a metre is right as it
is.
