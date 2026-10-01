# Batch B — Swedish (sv) and Dutch (nl), 1 October 2026

Job 1: the 8 site strings (`wildTitle` … `privacy8`) added to
`Server/strings/sv.json` and `nl.json`, after `privacy5`, so the diff is
additions only. Job 2: 79 app strings each, in `app/sv.json` and `app/nl.json`
(the 2 stale keys skipped). `check.py sv nl` and `app_check.py` (on a merged copy
I threw away afterwards) both exit 0. Every fragment key exists in the
xcstrings, none is stale, and each value has the same format specifiers as its
key.

## The decision to look at first

**Both languages already had a name for the Wild Fields before this batch.**
The commission of 25 September translated `Release to the Wild Fields`,
`Release to the Wild Fields?` and the release consequence (`It leaves your
garden for the Wild Fields…`). Those are shipping, and the batch is told to
change no existing string and to keep one name per language. So I kept the
names already there rather than giving the website a second one. In Swedish
that conflicts with the `wildTitle` spec. See below.

## Swedish (sv)

**The Wild Fields: *Vildmarken*** (with *på*: *på Vildmarken*), as the app
already says it.
- What works: it is a place name, it is ground nobody tends, it is not a garden
  or a park, and it is not one of the ten.
- What does not: *vildmark* is wilderness, which suggests forest and fell more
  than open fields. It is also singular, and the spec asks for "open,
  unarranged ground, more than one field".
- **If Marcus or a Swedish reader wants the spec met exactly, the name is
  *Vilda fälten*.** It follows the areas' own pattern (*Långa allén*, *Tysta
  trädgården*). Switching means changing the 3 shipped app strings above along
  with everything in this batch: 7 site strings and 8 app strings. A
  search-and-replace of *Vildmarken* → *Vilda fälten* covers it, but *på
  Vildmarken* should become *på Vilda fälten*, and in two places
  (`Anyone walking the field…`, `wildBody`'s *marken fortsätter*) the word
  *mark* would need to become *fälten*.
- I considered *Utmarken*, the old unfenced outlying land beyond the infields.
  The idea fits well, but it reads as forest grazing and few readers would know
  it.

**Release: *släppa ut*.** The button `Release` is *Släpp ut*, matching the
shipped *Släpp ut den* / *Släpp ut den på Vildmarken*. *Let go* is *släppa ut*
wherever it means the release, as with an animal let out into the wild, never
*publicera*. `Let go into the Wild Fields` (the Settings heading) is *Utsläppta
på Vildmarken*.

Other choices:
- People who grew a plant are *odlade* (`wildByOne`: *Odlad av {name}*).
- *Take it back* is *Ta tillbaka den*, as in `privacy6`.
- The scrambled form is *förvanskad form*, as in `privacy5`/`privacy6`.
- The web garden is *trädgården på webben*. The older *peace garden* keys use
  the shipped *fredsträdgården*.

Unsure:
- `Light` serves both the appearance option (beside `Dark`) and the label over
  the day/night control. *Ljus* has to do both, so `Dark` is *Mörk* to pair with
  it. iOS itself says *Ljust/Mörkt*, but *Ljust* would be wrong as the section
  label.
- `Gardener username` is shortened to *Användarnamn*. *Trädgårdsmästarens
  användarnamn* is too long for a Settings label.
- `wildByOne`/`wildByTwo`: *Odlad* is common gender, agreeing with *växt*.
- `Hold for three seconds.` is written *Håll inne i 3 sekunder.*, because three
  seconds is a quantity and takes a numeral. The same applies to *5 decimaler*
  in the coordinates note.
- `privacy8`: "and of the place and month each chose until both have" is
  *och likaså den plats och den månad var och en av er har valt, tills båda har
  valt dem*. This is faithful but heavy, so it is worth a reader's eye.

## Dutch (nl)

**The Wild Fields: *de Wilde Velden*** (*De Wilde Velden* as the title), as the
app already says it.
- It meets the spec: open fields, plural, untended, not a garden, not an area.
- Capitalised as a proper place name, the way the shipped app strings have it.
  The ten area names are sentence case (*De lange laan*), so the difference is
  visible on the front page's link under the area cards. A reader may prefer
  one style for both.
- Considered: *de Woeste Gronden*, the Dutch landscape term for land never
  reclaimed. It is a good native word, but it reads as wasteland.

**Release: *loslaten*.** The button `Release` is *Loslaten*, matching the
shipped *Loslaten* / *Loslaten in de Wilde Velden*.
- *Vrijlaten* is the more exact word for releasing an animal into the wild, and
  I would have chosen it fresh. *Loslaten* was already settled and also carries
  "let go", so I kept it. *Publiceren* is not used anywhere.

Gender of *plant*:
- On the site a plant is *ze/haar*, as in `privacy6` and `meaningsAbout`.
- In the app it is *hij/hem*, as in the shipped app strings.
- I followed each surface's own convention. Both are correct Dutch, but a
  reader may want them unified.

Other choices:
- *Gekweekt door {name}* (as *kweken* in `frontLead`).
- *gehusselde vorm*, *de tuin op het web* and *terughalen*, as in
  `privacy5`–`privacy7`.
- *vredestuin* for the older *peace garden* keys.

Unsure:
- `You let this plant go into the Wild Fields. %@ keeps theirs.` is *De plant
  van %@ blijft.* Dutch has no neutral "theirs" for one person, so this follows
  the shipped release consequence (*De plant van de persoon … blijft*).
- `Ask %@` is *Vraag het %@*, a button label.
- `When you met` is *Wanneer jullie elkaar ontmoetten*. It is long for a switch
  chip, but it matches the shipped `Where you met`.
- `Light`/`Dark` are *Licht*/*Donker*. *Licht* also works as the day/night
  section label.
- `Display` is *Scherm* and `Appearance` is *Weergave*, following iOS.
- `privacy8`: "either of you can withdraw what you chose" is *ieder van jullie
  kan wat je gekozen hebt op elk moment weer intrekken*. Mixing *ieder van
  jullie* with *je* is normal in speech but a careful reader may object.
