# For review

Written overnight, 3 September. Everything here is English that has not been
commissioned in sixteen languages, because it is the site's own writing rather
than the app's and you asked to read it first. The six prose strings are `null`
in every `Server/strings/*.json`, which draws the English silently.

**The ten area names were settled on 4 September** and §2 has gone with them:
named once, in English, kept as a table in `assets/js/walk.js` rather than as
ten catalogue keys. The reasoning now lives in `WEBSITE.md`, under *Walking it*,
which is where a decision belongs once it stops being a question.

**One decision is left — §1, the six prose strings.** Marcus is editing them.
Delete this file once they are settled; §3 is a record rather than a question
and its home is `WEBSITE.md` if it outlives the file.

---

## How to look at the garden while you read this

    python3 tools/site/serve.py

Then `http://localhost:8801/g`. Every plant in it is invented and the page says
so. `?` lists every key. Arrows or hjkl walk, `r` goes somewhere at random, `g`
returns to the map, `c` opens the language chooser.

**The command used to be `python3 -m http.server --directory Server`, and that
one never worked.** The site's three pages carry no extension — `/s` is what
every seed link already minted points at — and `http.server` types a file by its
extension, so all three arrived as `application/octet-stream` and the browser
downloaded them instead of drawing them. It returned 200 and logged nothing
wrong, which is why it stood in this file unchallenged. `tools/site/serve.py`
serves them as HTML, the way a host does.

### Standing in one of the languages

    http://localhost:8801/t

Forty-three test gardeners, one per language, `Test-DA-Gartner` through
`Test-ZH-Yuanding`. The word at the door is `peace`. Picking one draws the whole
site as a reader of that language gets it — labels, passage bank, reading
direction, whether the label voice may be uppercased or letter-spaced — with a
bar across the top saying which one you are in and a way out. While you are
standing in one, the language chooser moves between testers, because there is
exactly one per language.

There are no accounts and nothing to log in to: `Server/` is static files, and a
tester is a name and a language kept in that browser. The word is a latch rather
than a lock and `assets/js/testers.js` says so at the top. **It earned itself
within two minutes** — see §3.

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

## 3. What the testers found, which is not for review but is worth knowing

Two bugs in the first ten minutes of standing in Arabic and Hebrew, both fixed
in the same pass. Recorded because they are the same bug, and because the shape
of it will come back.

**English text inside a right-to-left page is reordered at its punctuation.**
The bidi algorithm puts the full stop of an English sentence at the head of the
line when the paragraph direction is right to left, so *A plant grown from a
meeting.* was drawn as *.A plant grown from a meeting*. It hit two places:

- `/g`'s invented-garden notice, which is hardcoded English in the markup.
- **Every one of the six prose strings in §1, on both `/s` and `/g`.** They are
  `null` in all forty-two catalogues on purpose, they fall back to English
  silently, and that fallback is most of the words on the page. So for the two
  right-to-left languages the whole of the site's own writing was scrambled.

The fix is to say what language a run of text is in: `lang="en" dir="ltr"` on
the notice, and `strings.dress()` doing the same for any key that fell back.
The attributes are cleared again when a key stops falling back, because a stale
`lang="en"` on a commissioned Hebrew string is the same bug facing the other
way.

**Neither would have been found by reading the code**, and neither shows in any
of the four CI checks. They needed somebody to stand in Arabic and look, which
until now took editing local storage by hand. That is the whole argument for
the roster.

It also means §1 has a second cost attached to it that it did not have when it
was written: while those six strings stay `null`, Arabic and Hebrew readers get
English prose — correctly set now, but English. Commissioning them fixes a
reading as well as a gap.
