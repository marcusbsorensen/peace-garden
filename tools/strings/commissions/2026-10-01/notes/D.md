# Batch D, 1 October 2026: French, Portuguese, Catalan, Galician, Basque

Job 1 (the 8 Wild Fields strings on the site) in all five, in
`Server/strings/<code>.json`, inserted after `privacy7` so the diff only adds
lines. Job 2 (the app's 79 non-stale new strings) in French, in
`app/fr.json`. Nobody who speaks any of these languages has read any of it yet.

## French (fr)

- **The Wild Fields: *les Champs Sauvages*.** The app already says this in
  three shipping strings (*Relâcher dans les Champs Sauvages*, and the release
  sentence), and the job asks for one name in each language, so the name was
  already chosen. It also fits NAMING.md: *champs* is open, untended ground
  and it is plural, and *sauvage* is the ordinary word for what nobody looks
  after. I kept the app's capitals (*Champs Sauvages*) in `wildTitle` and in
  every mention, even though the ten area names use sentence case
  (*Le croisement*). It is a proper place name, and if `wildTitle` were
  written differently from the app the two would read as two places.
- **Releasing: *relâcher*.** This is the app's own button word (*Relâcher*),
  and it is what French says for letting an animal go back into the wild.
  `wildBody` says *quand on la relâche*. In the app the button `Release` is
  *Relâcher*, and the Settings heading `Let go into the Wild Fields` is
  *Relâchées dans les Champs Sauvages* (the plants that were let go).
- **Not sure about these:**
  - `wildByOne` / `wildByTwo`: *Cultivée par {name}*. It agrees with
    *plante* (feminine), the way `sentBy` *Envoyée par* agrees with *graine*.
    The settled verb is *faire pousser*, but *Que {name} a fait pousser* is
    clumsy as a label, so I used *cultivée*.
  - **App key `Light` has two jobs.** It is the appearance option next to
    *Dark* (Chrome.swift `StageAppearance`), and it is also the section
    heading over the day/night toggle (SettingsView.swift:328). French needs
    two words: *Clair* for the option, *Lumière* for the heading. One key can
    only hold one, so I wrote *Clair* to match *Sombre* and the note that
    quotes it (« Clair » y renonce…). As a heading over *Toujours le jour /
    Suit l'heure / Toujours la nuit* it reads oddly. **The app should split
    this key.** Other languages will hit the same problem.
  - **Numerals.** `Hold for three seconds.` and *to five decimal places* spell
    the number out in the English. The BRIEF rule (a quantity from 2 up is a
    numeral) still applies, so the French says *Maintiens pendant 3
    secondes.* (the same as the older `Hold for 3 seconds.`) and *à 5
    décimales*.
  - **5 keys that no code uses.** These are not marked stale, but `git grep`
    finds them nowhere under App/ or Packages/: `%@ would like this plant to
    stand in the peace garden.`, `In the peace garden`, `Show this plant in
    the peace garden.`, `Somebody has asked about a plant here`, `Hold for
    three seconds.`. The code now says *public website garden*, and those
    keys are not in the catalogue yet. I translated the 5 as asked, using
    the app's *jardin de paix* for "peace garden". When the catalogue next
    syncs they are likely to turn stale, and the *public website garden*
    keys will need French.
  - `Let it stand there` (the yes button when somebody asks you to show a
    plant in the web garden): *La laisser y pousser*. *Se tenir* sounded
    stiff on a button, and the plant there really does grow at its real age.
  - Where English uses "they" for the other person, the French avoids
    gendering a name it cannot see: *l'autre personne* (as the catalogue
    already does), and *choisis par %@*. The one exception is `the other
    gardener` → *l'autre jardinier*, which matches the settled *Jardinier*.
  - `Menu bar` options: *Masquée / Marques seules / Marques et mots*. They
    agree with *barre* (feminine). *Marques* is the existing word for the
    marks.

## Portuguese (pt), *tu* throughout

- **The Wild Fields: *os Campos Silvestres*.** *Silvestre* is the ordinary
  word for a plant that grows without anyone tending it (*flor silvestre*),
  and that is exactly what this place is. *Selvagem* leans towards animals
  and fierceness. Plural *campos*, for open ground. The Spanish app's choice
  is the same (*Campos Silvestres*), which helps a reader who moves between
  the Iberian languages. Capitalised as a place name, as in the
  French/Spanish/Italian app.
- **Releasing: *libertar*.** This is the verb for letting a living thing go
  back into the wild. *Soltar* is also possible but sounds more like
  dropping something. `wildBody`: *quando é libertada*. `privacy8`: *Se
  libertares uma planta*.
- **Not sure about these:** *Cultivada por {name}* (same reason as the
  French). *a crescer* is European Portuguese, matching the catalogue
  (*telefone*, *partilhar*, *registo*). *Arrastar para o percorrer* follows
  `frontTurn` (*Arrastar para rodar*), which is an infinitive, not an
  imperative.

## Catalan (ca)

- **The Wild Fields: *els Camps Silvestres*.** Same reasoning as Portuguese:
  *silvestre* is Catalan's ordinary word for wild-growing plants. *Salvatge*
  was the other candidate. It is fine for plants too, but it leans towards
  animals and roughness.
- **Releasing: *deixar anar*.** This translates the English *let go* exactly,
  and it is plain. *Alliberar* would also work, but it sounds more like
  freeing a captive. `wildEmpty`: *Aquí encara no s'ha deixat anar res.*
- **Not sure about these:** the last sentence of `privacy8` is rewritten
  (*Tothom pot veure una planta que s'ha deixat anar*) because *una planta
  deixada anar* is awkward. `wildPostcardText` uses *que creix* rather than
  the gerund *creixent*, which reads as a calque. *Arrossega per
  recórrer-lo* follows `frontTurn`.

## Galician (gl)

- **The Wild Fields: *os Campos Silvestres*.** *Silvestre* is standard
  Galician for wild plants. *Bravo* (*terra brava*, ground nobody farms)
  is the most Galician word for "untended", and in some ways the better fit.
  But *Campos Bravos* can also read as "fierce fields", so I left it out.
  **A native reader might prefer *Campos Bravos*.**
- **Releasing: *ceibar*.** Galician's own word for setting something free
  (*ceibar os animais*). It fits better than *soltar*. `wildBody`: *cando se
  ceiba*. `privacy8`: *Se ceibas unha planta*, *unha planta ceibada*.
- **Not sure about these:** *Cultivada por {name}*. "Nothing is shown unless
  it is chosen" is written positively (*Só se amosa o que se escolleu*),
  following the BRIEF's rule to say what a thing does. Catalan and Basque do
  the same.

## Basque (eu)

- **The Wild Fields: *Landa Basatiak*.** *Landa* means field or open country
  (not *soro*, which is a cultivated plot). *Basati* means wild, as in
  *landare basatiak* and *animalia basatiak*. In the plural definite it
  covers more than one field. The inflected forms used are *Landa
  Basatietara* (to), *Landa Basatietan* (in) and *Landa Basatiek*
  (ergative). **This is the least certain name in the batch.** A compound
  with *basa-* (as in *basalore*, wild flower) would be more idiomatic, but
  I could not find one that names a place without inventing a word.
- **Releasing: *askatu*** (to set free). `wildEmpty`: *Oraindik ez da ezer
  askatu hemen.*
- **Not sure about these:**
  - `wildByOne` / `wildByTwo` are *Hazlea: {name}* / *Hazleak: {a} eta
    {b}* ("Grower: …"). In a natural Basque sentence the ergative ending
    would go on the name (*Wren-ek*, *Anak*), and its form depends on the
    name's last letter, which a placeholder cannot know. The label form
    avoids that. A reader should check that *hazle* sounds right here.
  - In *hazi* the verb "grow" and the noun "seed" are the same word. That is
    already true of the shipping strings, so nothing new.
  - `wildPostcardText` says *Peace Gardenen*, the same inflection as
    `about1`'s *Peace Gardenek*.

## Checks

- `python3 tools/strings/check.py fr pt ca gl eu`: exit 0, 5 clean.
- `python3 tools/strings/app_check.py` on a throwaway merge of `app/fr.json`
  into the xcstrings: exit 0. The merge was thrown away and the catalogue is
  unchanged.
- Key script: the 79 keys are exactly the untranslated, non-stale keys. All
  exist, none are stale, every `%@` matches, and every key that names the
  Wild Fields says *Champs Sauvages*. Every key except the 5 listed above
  was found in the code with `git grep -F`.
