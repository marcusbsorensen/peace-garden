# Batch A — Danish (da) and Norwegian Bokmål (nb), 1 October 2026

Job 1: the 8 site strings (`wildTitle`, `wildBody`, `wildEmpty`, `wildAway`,
`wildByOne`, `wildByTwo`, `wildPostcardText`, `privacy8`) added to
`Server/strings/da.json` and `nb.json`, inserted after `privacy7` so the diff
is additions only. Job 2: 79 app strings per language in `app/da.json` and
`app/nb.json` (the 81 untranslated keys less the 2 marked stale).

## Danish

**The Wild Fields: *Vildmarken*.** Not chosen fresh. The app already calls the
place *Vildmarken* in three translated keys (*Release to the Wild Fields* →
*Løssæt den på Vildmarken*, its question form, and the release consequence
*… tager ud på Vildmarken*), and the rule is one name per language, so the site
and every new string use it. It does meet the spec: open, untended ground,
not a garden or a park, not one of the ten areas, and nothing like any of
them on the map.

What it does not carry is *fields*, plural. *Vildmarken* is "the wilderness".
The closer name would be ***De Vilde Marker***: open farmland gone wild, more
than one field, and a better fit for a page that says "the field runs on in
every direction". **Marcus's call.** If he prefers it, the three existing app
keys above have to change too, or the app and the site will disagree.

**Preposition.** The new strings say *i Vildmarken* / *ud i Vildmarken*, which
is how Danish talks about the wilderness. The existing *på Vildmarken* reads
like a translation. I'd suggest changing those two to *Sæt den fri i
Vildmarken* / *Løssæt den i Vildmarken* when they're next touched. I left them
alone, since this job doesn't edit the xcstrings.

**Release: *Løssæt*** (button), as the existing *Release it* = *Løssæt den*.
It's the word for releasing animals into the wild. In prose, *let go* is
***slippe fri* / *slippe ud i Vildmarken***, which matches the existing *Let it
go* = *Slip den*: *%@ har sluppet den plante, I groede frem sammen, ud i
Vildmarken*. Neither word means publishing.

**People:** *folk* / *personer* only. No *mennesker* anywhere (checked).

Unsure:
- `wildByOne` / `wildByTwo` — ***Dyrket af {name}***. I used *dyrket* rather
  than the catalogue's *groet frem*, because *groet frem af {name}* reads as
  "sprouted out of {name}".
- `Gardener username` → *Brugernavn som gartner*. Clumsy but exact. A shorter
  *Gartnernavn* would lose "username", the word `privacy8` and *Your Peace
  Garden username* use.
- `It grew from your seed and %@'s…` → *dit frø og frøet fra %@*, to avoid the
  genitive. The catalogue's *%@’s* isn't Danish, and *%@s* breaks on names
  ending in *s*. The second variant starts *De bliver spurgt…*. *De* at the
  start of a sentence can be misread as the formal *you*, but the catalogue
  already uses it this way (*De har ikke appen*).
- `The garden was black…` — *Lys giver afkald på det, så telefonen kan læses i
  sollys*. This spells out "for a phone in sunlight" as "so the phone can be
  read in sunlight", which is the intended meaning.
- `Which one` → *Hvilket sted*. The English is elliptical, and the chooser
  picks a place.
- `Hold for three seconds.` → *Hold nede i 3 sekunder.* A numeral, per the
  quantity rule, and identical to the existing *Hold for 3 seconds.*
- `five decimal places` → *5 decimaler*. A quantity, so a numeral.
- Five keys aren't referenced in code today (*In the peace garden*, *Show this
  plant in the peace garden.*, *%@ would like this plant to stand in the peace
  garden.*, *Somebody has asked about a plant here* and *Hold for three
  seconds.*). They're translated anyway, using *fredshaven* as the existing
  *Plant i fredshaven* does.

## Norwegian Bokmål

**The Wild Fields: *Villmarka*.** The same reasoning: the app already has
*Slipp den ut på Villmarka* and *… drar ut på Villmarka*. The *-a* definite
form is kept as the app has it (*Villmarken* is the conservative alternative).
The same note on the plural applies: ***De ville markene*** would carry
*fields*, and changing it means changing the existing app keys too.
The new strings use *i Villmarka* / *ut i Villmarka*. I'd suggest the same
*på → i* change for the existing two.

**Release: *Slipp ut*** (button), matching *Release it* = *Slipp den ut*. In
prose, *let go* is *slippe fri* / *slippe ut i Villmarka*.

Unsure:
- `wildByOne` / `wildByTwo` — *Dyrket av {name}*, for the same reason as the
  Danish.
- `Follows the hour` → *Følger klokken*, matching the catalogue's *stiller
  klokken etter* rather than *klokka*.
- `Let the plant turn` → *La planten dreie*, matching the site's *Dra for å
  dreie*.
- The nb catalogue already uses *mennesker* (*Menneskene du har møtt…*). That's
  fine in Norwegian, and the Danish correction doesn't carry over. The new
  strings don't need the word.

## Checks

- `python3 tools/strings/check.py da nb` — exit 0.
- `python3 tools/strings/app_check.py` on a throwaway merge of both fragments
  into the xcstrings — exit 0. The merge was then discarded.
- Script: all 79 keys per language exist in the xcstrings, none is stale, none
  already has that language, each value has the same multiset of format
  specifiers as its key, and the key set equals the untranslated non-stale set.
