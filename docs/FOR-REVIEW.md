# For review

Written overnight, 3 September. Everything here is English that has not been
commissioned in sixteen languages, because it is the site's own writing rather
than the app's and you asked to read it first. Nothing below is live: the six
prose strings are `null` in every `Server/strings/*.json`, which draws the
English silently, and the area names are not written anywhere yet.

Delete this file once it is settled.

---

## How to look at the garden while you read this

    python3 -m http.server 8791 --directory Server

Then `http://localhost:8791/g`. Every plant in it is invented and the page says
so. `?` lists every key. Arrows or hjkl walk, `r` goes somewhere at random, `g`
returns to the map, `c` opens the language chooser.

**The thing worth doing first**: open a plant, then change the language. The
passage changes and it is not a translation of what it said before — the plant
carries a theme and a subtheme, both derived from its name, and your bank
supplies the words. That argument has been in `WEBSITE.md` since it was written
and this is the first time it has been possible to see it.

---

## 1. The six prose strings

These are already in `Server/assets/js/strings.js` and already on the page in
English — this is the copy as it stands, gathered so it can be read as a piece
rather than as six entries in a catalogue. **Approve, edit, or replace.**

### `tagline` — the line under the mark

> A plant grown from a meeting.

### `about1` — what this is

> Peace Garden makes a plant out of two people meeting. Two phones hand each
> other a seed, and what grows from the pair is a plant that is the two of them
> together, opening over real days in its own time.

### `about2` — why a link exists

> A seed travels in a link as well as by touch, so it reaches a phone that has
> never heard of any of this.

### `about3` — what the page is doing

> The seed in a link rides after the # in its address, and that part stays in
> your browser. This page is a file, and it draws what your own link already
> holds.

### `growBody` — under *Growing it*

> Peace Garden crosses this seed with one of your own, and the plant that comes
> of the pair is yours to keep. The same two seeds always make the same plant,
> on any phone, for as long as both of you have it.

### `appNote` — the honest one

> The app is being made for iPhone. This link keeps until it arrives.

**One note on `about3`.** It is the only string that explains a mechanism, and
it is doing privacy work: it is where a reader learns the seed never reached the
server. Worth deciding whether that is the right register for it, or whether the
sentence should say plainly what it protects rather than describing what it does.

---

## 2. The ten area names

The garden is ten areas, one per theme, laid out from `Quotes.Theme.position` —
see `Server/assets/js/garden.js`. The layout is settled and derived. **The names
are not, and they are a decision rather than a derivation.**

Every one below is a real place in a garden, which is the system: not ten
abstractions dressed up, but ten things a gardener could point at.

| Theme | Area | Why |
| --- | --- | --- |
| `waiting` | **The Cold Frame** | Where a plant is held back until it can go out. `waiting`'s three subthemes are `heldBack`, `theLongCount` and `standingAndWatching`, and a cold frame is all three. |
| `ground` | **The Root Ground** | Still, long-span, solitary — the part of a garden that is under it. |
| `beginnings` | **The Seedbed** | Where a thing starts, and the one name on this list nobody has to be told. |
| `renewal` | **The Coppice** | Coppicing is cutting so that it grows back. `renewal`'s first subtheme is literally `cutAndComeAgain`. |
| `travel` | **The Long Walk** | The gravel run through a large garden, and the only area whose name is a journey. |
| `peace` | **The Quiet Garden** | Plain, and it carries `quietAsASound` without explaining it. |
| `kinship` | **The Orchard** | An orchard is a family: grafted, propagated, related on purpose. |
| `pattern` | **The Knot Garden** | A knot garden is a garden whose whole subject is pattern. |
| `light` | **The Glasshouse** | The one structure in a garden built for light rather than for shelter. |
| `meeting` | **The Crossing** | Where paths meet — and where two seeds cross. |

Laid out, walking right goes from the still and long-span toward the moving and
momentary, walking down from solitary toward shared:

|  |  |  |  |  |
| --- | --- | --- | --- | --- |
| The Cold Frame | The Root Ground | The Seedbed | The Coppice | The Long Walk |
| The Quiet Garden | The Orchard | The Knot Garden | The Glasshouse | The Crossing |

### What this costs, which is the part worth your decision

**Ten names is ten strings, and ten strings is a hundred and seventy
commissions** — seventeen languages now, twenty-five after round two lands,
thirty-three after the alphabets round. `WEBSITE.md` calls that multiplier "the
number to quote at whoever wants to add a paragraph", so it is quoted here.

Three ways to go, and the second is the recommendation:

1. **Commission all ten.** The garden is named in the reader's language. Most
   expensive, and the names are idiomatically English — *cold frame* and *knot
   garden* have no clean equivalent in several of the sixteen and would come
   back as descriptions rather than names.
2. **Name the areas once, in English, and leave them.** A garden's areas are
   proper nouns, the way a plant's binomial already is. The app has spent a
   whole document arguing that a synthesised Latinate name reads the same in
   Amsterdam as in Margate; an area name can hold the same line. **Zero new
   strings**, and it is consistent with what the plant names already do.
3. **Do not name them at all** — the areas are drawn on a map and pointed at,
   and a reader picks one by looking. Cheapest, and it loses the thing you asked
   for, which was names related to the themes.

Option 2 is what the app's own naming argument supports, and it is the only one
of the three that costs nothing and still answers the request.
