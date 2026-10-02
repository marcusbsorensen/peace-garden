# Second read of the 1 October 2026 translations

Read on 2 October 2026, against `main` at `24c45e5`. This review covers the eight Wild Fields
site strings in 41 catalogues (every `Server/strings/<code>.json` except `kl`), the 79 new app
strings in da, es, fr, it, nb, nl and sv, and the translators' notes A–E. Each string was judged
against `WILD` in `commission.py`, `BRIEF.md`, the area names, and the app's layout code. **40
findings: 2 wrong, 12 awkward and 26 minor.** Both **wrong** findings are about the name of the
place, not what the strings claim. Polish *Dzikie Pola* and Ukrainian *Дикі поля* name a real
historical region, and a native reader will take the name as a reference to it. Every one of the
41 `privacy8` strings carries all eight claims in order. None makes the plant sound anonymous,
and none treats showing a name as expected. No `wildByOne` hints at a second person, and no
`wildByTwo` suggests who released the plant. In every language *release* is the word for setting
a living thing free, never *publish*. Every language uses one name for the Wild Fields, the site
and the app agree in all seven app languages, and no name collides with an area name. Informal
address holds everywhere, Danish never uses *mennesker*, and every `%@` in the app strings is
intact. Seventeen languages read well as they stand. The main thing left to decide is the name
itself. In Danish, Norwegian and Swedish it is singular *wilderness*, which the spec says should
be *fields*, and changing it means changing app strings that have already shipped.

`check.py` exits 0 on the current tree. No catalogue or xcstrings was changed by this review.

## Wrong

| Lang | Key | Current | Problem | Proposed |
|---|---|---|---|---|
| pl | `wildTitle` (and the 5 strings that name it) | Dzikie Pola | Capitalised, this is exactly the proper name of the historical steppe borderland, the Cossack and Tatar frontier of Sienkiewicz's *Ogniem i mieczem*, now in Ukraine. A Polish reader takes it as an allusion to that region rather than as a description of open ground. On a site called Peace Garden it points at a land of border wars. The translator flagged it. | **Dzikie Łąki** (meadows: open, untended and plural, with no echo). For the other strings, see the Polish section. |
| uk | `wildTitle` (and the 5 strings that name it) | Дикі поля | *Дике поле* is the textbook name of the southern steppe of Cossack history, and the 2018 film *Дике поле* is set in the Donbas. In 2026 the southern steppe is the front line. The plural softens the echo but does not remove it. | **Дикі луги** (*луги*, meadows; *луки* would also read as "bows"). For the other strings, see the Ukrainian section. |

## Across languages

These findings are about code or the English source, not any one translation. Only the first is counted.

- **App key `Light` does two jobs** (minor, counted once). It is the appearance option beside
  *Dark* and also the heading over the day/night control (`SettingsView.swift:328`). French,
  Spanish and Italian need two different words (*Clair*/*Lumière*, *Claro*/*Luz*,
  *Chiaro*/*Luce*), and each translator could write only one. The fix is to split the key in
  code: keep `Light` for the option and add a key such as `Light and dark` for the heading.
- *Not counted.* `wildByTwo` in Spanish (*y* becomes *e* before an *i*-sound) and Welsh (*a*
  becomes *ac* before a vowel) depends on the name, which the string cannot know. The forms used
  are the right default.
- *Not counted.* In `wildpage.js`, the by-line is set to `dir="auto"` and the names are inserted
  without isolation. In ja, ko and zh the by-line begins with `{name}`, so a name in Arabic or
  Hebrew script flips the whole line to right-to-left and the Japanese, Korean or Chinese words
  end up on the wrong side of it. Wrapping each name in U+2068…U+2069 (FSI…PDI), and setting the
  line's direction from the page language, would fix it in every language at once.
- *Not counted, English source.* The app key *Beside it stands only what each of you chooses.
  Left as it is, you stay anonymous.* is accurate about names. Next to `privacy8`'s point that
  anyone who knows one of the parent seeds can recognise the plant, though, *anonymous* claims a
  little more than is true. Marcus may want *Left as it is, no name is shown*. All seven
  translations follow the English faithfully.

## Per language

### ar — Arabic
- **`wildPostcardText`** — `{name}، تنمو في البراري، في Peace Garden.`
  Problem: this text is shared into other apps, which set a paragraph's direction from its first
  strong character. Here that is the Latin plant name, so the line is laid out left to right and
  the final *في* lands on the far side of the Arabic run from *Peace Garden*.
  Proposed: `تنمو {name} في البراري، في Peace Garden.`
  Severity: **awkward**

### be — Belarusian
- **`wildTitle`** — Дзікія палі
  Problem: the *Дикое поле* echo is much weaker in Belarusian, so the name reads naturally. If
  Russian and Ukrainian change, though, Belarusian would be the one East Slavic catalogue still
  using it.
  Proposed: *Дзікія лугі* (in `wildAway`: *Да Дзікіх лугоў*; in the postcard: *у Дзікіх лугах*),
  or keep it as it is.
  Severity: **minor**

### bg — Bulgarian
Reads well.

### ca — Catalan
Reads well.

### cs — Czech
Reads well. *Vypěstoval(a) {name}* is the usual Czech way to leave gender open, and it does not suggest a second person.

### cy — Welsh
Reads well.

### da — Danish (Marcus reads this one; these points are for him)
- **`wildTitle`** (site and app) — Vildmarken
  Problem: the name is singular *wilderness*. The spec asks for "more than one field", and
  `wildBody` describes a field. Translator A flagged it, and the name already ships in three app
  strings.
  Proposed: *De Vilde Marker*. This means changing the three shipped app strings and the eight
  new ones together, or else keeping *Vildmarken* as a deliberate choice.
  Severity: **awkward**
- **App, shipped keys `Release to the Wild Fields` / `…?` / `It leaves your garden…`** —
  *på Vildmarken*
  Problem: the new strings say *i/ud i Vildmarken*, so the app now uses both prepositions.
  Proposed: *Løssæt den i Vildmarken* / *Løssætte den i Vildmarken?* / *…tager ud i Vildmarken*.
  Severity: **minor**
- **App `Gardener username`** — Brugernavn som gartner
  Problem: it reads as "username as a gardener".
  Proposed: *Dit brugernavn*
  Severity: **minor**

### de — German
- **`wildBody`** — …*was die beiden, die sie gezogen haben, zu zeigen gewählt haben.*
  Problem: *zu zeigen gewählt haben* is an anglicism.
  Proposed: *…wofür sich die beiden, die sie gezogen haben, entschieden haben.*
  Severity: **minor**

### el — Greek
- **`wildTitle`** (and every string that names it) — Οι Άγριοι αγροί
  Problem: *αγρός* is cultivated farmland, which works against "untended". *Άγριοι αγροί* also
  sounds like a play on words.
  Proposed: *Τα Άγρια λιβάδια* (*στα Άγρια λιβάδια*, *τα Άγρια λιβάδια κρατούν*). The
  neuter plural needs the articles adjusting in `wildBody`, `wildAway`, `wildPostcardText` and
  `privacy8`, and *ο αγρός συνεχίζεται* becomes *το λιβάδι συνεχίζεται*.
  Severity: **awkward**
- **`privacy8`** — *πρώτα παίρνεται πίσω από εκεί*
  Problem: the passive *παίρνεται πίσω* is stiff.
  Proposed: *πρώτα αποσύρεται από εκεί*
  Severity: **minor**

### es — Spanish
Site strings read well.
- **App `How the place is said`** — Cómo se dice el lugar
  Problem: *decir un lugar* is unidiomatic.
  Proposed: *Cómo se indica el lugar*
  Severity: **minor**

### et — Estonian
Reads well.

### eu — Basque
- **`wildTitle`** — Landa Basatiak
  Problem: *basati* leans towards *savage* (of animals and people). Batch D flagged this as the
  least certain name in its batch. A native reader may prefer a *basa-* form.
  Proposed: ask a Basque reader to choose between *Landa Basatiak* and a *basa-* compound
  such as *Basalandak*. I am not confident enough to replace it.
  Severity: **minor**

### fi — Finnish
Reads well.

### fr — French
- **`wildAway`** — Les Champs Sauvages ne peuvent pas être atteints pour l'instant.
  Problem: the passive is stiff, and the app says the same thing differently (*Impossible
  d'atteindre les Champs Sauvages pour l'instant.*).
  Proposed: *Impossible d'atteindre les Champs Sauvages pour l'instant.*
  Severity: **minor**
- **App `How the place is said`** — Comment le lieu est dit
  Problem: unidiomatic.
  Proposed: *Comment le lieu est indiqué*
  Severity: **minor**

### ga — Irish
Reads well. The unlenited *Fiáine* after *Machairí* is correct.

### gl — Galician
Reads well.

### he — Hebrew
- **`wildPostcardText`** — `{name}, צומח בשדות הפראיים של Peace Garden.`
  Problem: the same direction problem as in Arabic. Opening with the Latin name makes the shared
  line left to right, and *של* separates from *Peace Garden*.
  Proposed: `צומח בשדות הפראיים של Peace Garden: {name}.`
  Severity: **awkward**
- **`wildByTwo`** — `גודל על ידי {a} ו{b}`
  Problem: Hebrew writes a maqaf when *ו* attaches to a word in Latin script or to digits.
  Proposed: `גודל על ידי {a} ו־{b}`
  Severity: **minor**

### hr — Croatian
- **`wildBody`** — *Povuci za hodanje.*
  Problem: *hodanje* is the act of walking, which is odd as an invitation.
  Proposed: *Povuci za šetnju.*
  Severity: **minor**

### hu — Hungarian
- **`wildByTwo`** — Nevelte: {a} és {b}
  Problem: with two names, a label reads more naturally in the plural.
  Proposed: *Nevelték: {a} és {b}*
  Severity: **minor**
- **`privacy8`** — *amit a két ember közül, aki felnevelte, mindegyik választott*
  Problem: the clause order is clumsy.
  Proposed: *amit a növényt felnevelő két ember közül mindegyik maga választott*
  Severity: **minor**

### is — Icelandic
Reads well.

### it — Italian
Site strings read well.
- **App `the other gardener`** — l'altra persona
  Problem: this is a fallback inserted into `%@`, so *Chiedi a %@* and *In attesa di %@* come out
  as *a l'altra persona* / *di l'altra persona*. Italian requires *all'* and *dell'*. Translator C
  flagged it. No single word fixes it.
  Proposed: in code, give the two templates fallback variants (*Chiedi all'altra persona*, *In
  attesa dell'altra persona*). Keep this string for the other uses.
  Severity: **awkward**
- **App `How the place is said`** — Come si dice il luogo
  Problem: unidiomatic.
  Proposed: *Come viene indicato il luogo*
  Severity: **minor**

### ja — Japanese
- **`wildBody`** — …*それ自身の種が置いた場所に立ち*…
  Problem: *それ自身の* reads as a translation.
  Proposed: *…自分の種が置いた場所に立ち…*
  Severity: **minor**

The register (です/ます) is right, and so is *原野* for an open, untended expanse.

### ko — Korean
- **`wildByOne`, `wildByTwo`** — `{name} 님이 기름` / `{a} 님과 {b} 님이 기름`
  Problem: written alone, the nominalised *기름* is also the everyday noun for *oil*, so the
  label can read as "{name} is oil". The translator flagged it.
  Proposed: `{name} 님이 기른 식물` / `{a} 님과 {b} 님이 기른 식물`
  Severity: **awkward**

### lt — Lithuanian
- **`wildEmpty`** — Čia dar niekas nepaleista į laisvę.
  Problem: an impersonal neuter passive takes the genitive of negation, so *niekas* should be
  *nieko*.
  Proposed: *Čia dar nieko nepaleista į laisvę.*
  Severity: **minor**
- **`privacy8`** — *Niekas nerodoma, jei nepasirinkta*
  Problem: the same agreement problem.
  Proposed: *Nieko nerodoma, jei nepasirinkta*
  Severity: **minor**

### lv — Latvian
Reads well.

### mk — Macedonian
Reads well.

### mt — Maltese
Reads well.

### nb — Norwegian Bokmål
- **`wildTitle`** (site and app) — Villmarka
  Problem: the same as in Danish. It is singular *wilderness*, and the spec asks for fields.
  Proposed: *De ville markene*, changed together with the three shipped app strings. Otherwise
  keep *Villmarka* as a deliberate choice.
  Severity: **awkward**
- **App, shipped keys** — *Slipp den ut på Villmarka* / *drar ut på Villmarka*
  Problem: the new strings say *i Villmarka*.
  Proposed: *Slipp den ut i Villmarka* / *drar ut i Villmarka*
  Severity: **minor**
- **App `What it says`** — Hva det skal stå
  Problem: ungrammatical. The subject needs *som*.
  Proposed: *Hva som skal stå*
  Severity: **minor**
- **App `Gardener username`** — Brukernavn som gartner
  Problem: it reads as "username as a gardener".
  Proposed: *Brukernavnet ditt*
  Severity: **minor**

### nl — Dutch
- **Site and app** — the plant is *ze/haar* on the site and *hij/hem* in the app.
  Problem: both are correct Dutch, but somebody who uses both will notice. Translator B flagged it.
  Proposed: choose one. *Hij* matches the app's shipped strings, which are the larger set.
  Severity: **minor**

### pl — Polish
- **`wildTitle`** and the strings that name it — see *Wrong*. The full replacement:
  - `wildTitle`: *Dzikie Łąki*
  - `wildBody`: *Tu trafia roślina, gdy wypuszcza się ją na wolność. Nikt nie układa Dzikich Łąk: każda roślina stoi tam, gdzie postawiło ją jej własne nasiono, a łąka ciągnie się w każdą stronę. Przy roślinie stoi tylko to, co dwoje ludzi, którzy ją wyhodowali, postanowiło pokazać. Przeciągnij, aby po niej chodzić.*
  - `wildAway`: *Nie można teraz dotrzeć do Dzikich Łąk.*
  - `wildPostcardText`: *{name} rośnie na Dzikich Łąkach, w Peace Garden.*
  - `privacy8`: *Dzikie Pola* → *Dzikie Łąki* in all three places (*wysyła ją na Dzikie Łąki*, *Dzikie Łąki przechowują* twice).
  Severity: **wrong**

### pt — Portuguese
Reads well. *Tu* is used throughout.

### ro — Romanian
Reads well.

### ru — Russian
- **`wildTitle`** (and every string that names it) — Дикие поля
  Problem: it echoes *Дикое поле*, the historical name of the same steppe. That is weaker in the
  plural and in Russian than in Ukrainian, but it is the same reference on a site that both
  readers use.
  Proposed: *Дикие луга* (*Дикие луга никто не обустраивает… а луг тянется во все стороны*; *До
  Диких лугов сейчас не добраться*; *растёт в Диких лугах*; *в Дикие луга*, *Дикие луга хранят* in
  `privacy8`).
  Severity: **awkward**

### sk — Slovak
Reads well.

### sl — Slovenian
- **`wildBody`, `wildEmpty`, `privacy8`** — *ko je izpuščena* / *Tu še ni bilo nič izpuščeno.* /
  *Če rastlino izpustiš* / *izpuščeno rastlino*
  Problem: with nothing after it, *izpustiti* reads first as "leave out, omit". *Tu še ni bilo nič
  izpuščeno* comes out as "nothing has been omitted here yet". The other Slavic catalogues all add
  *na svobodo/slobodu*.
  Proposed: *ko je izpuščena na prostost* / *Tu še ni bilo nič izpuščeno na prostost.* / *Če
  rastlino izpustiš na prostost* / *na prostost izpuščeno rastlino*.
  Severity: **awkward**

### sq — Albanian
Reads well.

### sr — Serbian
Reads well.

### sv — Swedish
- **`wildTitle`** (site and app) — Vildmarken
  Problem: *vildmark* means forest and fell more than open fields, and it is singular. Translator B
  flagged it as conflicting with the spec.
  Proposed: *Vilda fälten* (*på Vilda fälten*), changed together with the three shipped app
  strings. In `wildBody`, *marken fortsätter* becomes *fälten fortsätter*.
  Severity: **awkward**
- **App `%@ has let the plant you grew together go into the Wild Fields. Yours stays here.`** —
  %@ har släppt ut växten ni odlade tillsammans på Vildmarken. Din stannar här.
  Problem: *på Vildmarken* attaches to *odlade*, so the sentence first reads as "the plant you grew
  together on the Wild Fields".
  Proposed: *%@ har släppt ut växten ni odlade tillsammans. Nu står den på Vildmarken, och din
  stannar här.*
  Severity: **awkward**
- **App `In the middle, the sun and moon go round…`** — *På vardera sidan stannar den i dag eller
  natt, vad klockan än är.*
  Problem: *i dag* means *today*, so the sentence reads "stays today or night".
  Proposed: *På vardera sidan står den still på dag eller natt, vad klockan än är.*
  Severity: **awkward**
- **App `What it says`** — Vad det står
  Problem: *som* is needed as the subject.
  Proposed: *Vad som står*
  Severity: **minor**
- **App `Waiting for you to allow location.`** — Väntar på att du tillåter plats.
  Problem: *tillåta plats* is not idiomatic.
  Proposed: *Väntar på att du ger tillgång till din plats.*
  Severity: **minor**

### tr — Turkish
- **`privacy8`** — *ikinizden biri seçtiğini istediği zaman geri çekebilir*
  Problem: *ikinizden biri* is "one of you", which can read as only one of the two being able to
  withdraw.
  Proposed: *ikinizden her biri seçtiğini istediği zaman geri çekebilir*
  Severity: **minor**

### uk — Ukrainian
- **`wildTitle`** and the strings that name it — see *Wrong*. The full replacement:
  - `wildTitle`: *Дикі луги*
  - `wildBody`: *Дикі луги ніхто не впорядковує: … а луг тягнеться в усі боки.*
  - `wildAway`: *До Диких лугів зараз не дістатися.*
  - `wildPostcardText`: *{name} росте в Диких лугах, у Peace Garden.*
  - `privacy8`: *надсилає її в Дикі луги*; *Дикі луги зберігають* (twice).
  Severity: **wrong**

### zh — Chinese
- **`wildBody`** — 旷野没有人安排
  Problem: topicalising the place sounds translated.
  Proposed: 没有人安排旷野
  Severity: **minor**

## App: layout and placeholders

- Every one of the 79 values in all seven languages is identical in the fragments and in
  `Localizable.xcstrings`, and every `%@` is present.
- No Settings label is too long for a phone. Switch rows use 15 pt text that wraps, and chooser
  labels and section headings sit on their own lines. The longest is *Mostrar la etapa de
  crecimiento* / *Afficher le stade de croissance* (31 characters), which fits beside a toggle at
  375 pt.
- The three release chips (`Your name`, `Where you met`, `When you met`) are wrapped in
  `ViewThatFits` and fall back to a column. That means French *Quand vous vous êtes rencontrés*
  and Dutch *Wanneer jullie elkaar ontmoetten* are long but do not overflow, and both match their
  shipped *Where you met*.
