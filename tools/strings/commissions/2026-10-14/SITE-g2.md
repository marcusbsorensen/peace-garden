# Site strings, group 2, 14 October 2026

Estonian, Basque, Finnish, French, Irish, Galician, Hebrew, Croatian, Hungarian
and Icelandic. Marcus chose on 14 October (19A) to translate now and mark
everything for a native reader's review, so **every string below is a draft
that nobody who speaks the language has read yet.**

Each of the ten catalogues gained the same 45 keys: the 44 that were in no
language (`gardenBody downloadBody walkTitle walkThisArea walkBody walkAbout
walkGrowing walkEmpty walkAway walkTurnAnti walkTurnClock moveUp moveDown
moveLeft moveRight zoomIn zoomOut moveHome plantKey plantAmbassador
plantPostcard plantPostcardText plantCopied plantCopyThis plantClose quietAbout
quietAway crossAbout crossAway orchardAbout orchardAway knotAbout knotAway
seedbedAbout seedbedAway frameAbout frameAway glasshouseAbout glasshouseAway
coppiceAbout coppiceAway groundAbout groundAway goOn`), checked against
`strings.js` and each catalogue before writing, and `privacy10`. Each has 146
keys now, the whole of `strings.js`. `check.py`: all ten clean, and 42 of 42
clean across the tree. `export.py --check`: in step.

## What holds in all ten

- **Placement.** Each key went in straight after the key before it in
  `strings.js` that the catalogue already had: `gardenBody` after `gardenTitle`,
  the walk and area keys after `wildPostcardText`, `goOn` after `notYet`,
  `privacy10` after `privacy9`. Nothing that was there moved.
- **Each language's own words.** The area names, *the Wild Fields*, *seed*,
  *gardener*, *garden* and *area* are the ones the catalogue already uses. The
  word for *area* is the one in `privacy6`. `walkTitle` is the same as
  `areaTravel`, since both say The Long Walk in English. Each failure line has
  the shape of that language's `wildAway`, with the area named as the
  catalogue names it.
- **`{area}` is put in as written**, with its article and no case ending
  (`areaIn` in `plantpanel.js`). So in the seven languages where a preposition
  would inflect it, or join onto its article, it stands where it needs neither.
  It goes first, before a colon, in `plantAmbassador`, and after a label such
  as *Area:* in `plantPostcardText`. Where the grammar has a slot that leaves a
  name whole, the string uses it: French *dans {area}*, Croatian *u području
  {area}*, Hungarian *{area} nagykövete*, Hebrew *שגריר {area}* and *באזור
  {area}*.
- **Instructions take the form the catalogue already uses** in `frontTurn` and
  at the end of `wildBody`. That is the infinitive in French and Hebrew and the
  imperative in the other eight. Key names on the pad are short. They are
  nouns or infinitives where that language names a button that way: Hungarian
  *Bezárás*, Hebrew *סגירה*, Icelandic *Loka*, Galician *Pechar*.
- **Numbers.** The about paragraphs keep their counts as words, as the English
  does: *five trees*, *six drills*, *the next four*, *ten areas*. They describe
  how a place is laid out rather than report a figure. A reader who wants the
  numeral rule applied to them should say so for all 42 at once.
- **`plantClose`** is now only the name of the ✕ button, read aloud. All ten
  are the word that language uses for a close button: *Fermer*, *Pechar*,
  *Zatvori*, *Bezárás*, *Sulje*, *Sulge*, *Loka*, *סגירה*, *Itxi*, *Dún*.
  French matches the app's *Fermer*. **`gardenTitle`** was checked as the
  hidden heading over `/g`'s map: all ten read right as a page's heading.
- **`privacy10`** carries the five claims in order. The question goes to the
  App Store of the reader's own country and to Apple alone. It carries only
  the country and the app's id, and the internet address is said to reach
  Apple as any request does. There is an arrow when there is a newer version,
  no question when the phone has no store country, and neither the name nor
  the question under Reduce Motion. *App Store* and *Peace Garden* stay as they
  are. **Reduce Motion** has iOS's own name in the five languages iOS is
  written in (French, Finnish, Hungarian, Croatian, Hebrew). **The other five
  have no iOS of their own**, so a reader's phone runs in English, or in
  Spanish or French. Estonian, Basque, Galician, Irish and Icelandic therefore
  describe the setting in their own words with *(Reduce Motion)* after it.
  That is the one deliberate departure from the claim *as the phone's
  Accessibility settings write it*, and a reader may prefer the English
  setting name alone.

## Per language

### fr — French
- Terms: *espace* for area, *parcelle* for plot, *châssis* for the frames,
  *rayons* for drills, *tablettes* for the staging, *souches* for stools.
  *Zoom avant* / *Zoom arrière*, *Vers le haut* and the rest for the pad, and
  NBSP before colons and inside guillemets, as the newer strings write them.
- `plantAmbassador`: *{area} : son ambassadrice…*, which is feminine to agree
  with *plante*. `plantPostcardText` keeps *dans {area}*, so the article
  arrives capitalised mid-sentence: *dans Le verger*.
- For a reader: the capital *Le* in the postcard; *Impossible d'atteindre la
  dormance*, which reads a little like "reach dormancy"; and whether *Vers le
  haut* or *Déplacer vers le haut* is better for the pad.

### gl — Galician
- Terms: *zona* for area, *parcela* for plot, *arriates* for the borders,
  *sucos* for drills, *caixóns* with a glass lid for the frames, *tocos* for
  stools, and *a App Store* (feminine).
- The postcard is *{name} medra aquí: {area}, en Peace Garden.*, because *en*
  would have to join onto the name's article (*no pomar*).
- For a reader: *ao tresbolillo* for the quincunx (taken from Spanish); *gremio*
  for a plant guild; and whether to keep *Reducir movemento (Reduce Motion)* or
  use the Spanish iOS name *Reducir movimiento*, which is what a Galician phone
  most likely shows.

### hr — Croatian
- Terms: *područje* for area, *parcela* for plot, *gredice* for the borders and
  beds, *klijališta* for the frames, *panjevi* for stools, and *poveznica* for
  link, as `appNote` has it.
- `plantPostcardText`: *u području {area}*, keeping the name in the nominative
  after a generic noun.
- For a reader: whether *Smanji kretanje* is really iOS's Croatian name for
  Reduce Motion; the two turns (*Okreni suprotno od kazaljke na satu*), which
  are the longest pad names in the group; and *ambasadorica* for a plant.

### hu — Hungarian
- Terms: *terület* for area, *parcella* for plot, *évelőágy* for the borders,
  *hidegágy* for the frames (unheated, unlike *melegágy*), *tő* for stools, and
  *hivatkozás* for link, as `appNote` has it.
- *Verzió* in `privacy10`, as the App Store says it, while `newerVersion` says
  *változat*. A reader may want the two to match.
- For a reader: *{area} nagykövete* with no article at the head of the line;
  the noun forms of the turns (*Forgatás az óramutatóval ellentétesen*), which
  are long; and *Mozgás csökkentése* for Reduce Motion.

### fi — Finnish
- Terms: *alue* for area, *palsta* for plot, *perennapenkki* for the borders,
  and *lasikantinen laatikko* for the frames, because *lava* is already the
  Seedbed's word (*Taimilava*). *Vastapäivään* / *myötäpäivään*, *Lähennä* /
  *Loitonna*. Long compounds avoided where a phrase wraps (*kaksi
  perennapenkkiä* rather than *kaksoisperennapenkki*).
- The postcard is *{name} kasvaa Peace Gardenissa. Alue: {area}.* The failure
  lines inflect each area's name (*Hiljaiseen puutarhaan*, *Kantovesoille*).
- For a reader: the case chosen for *Horrospenkkiin* and *Kantovesoille*;
  `coppiceAbout`, which is two sentences where the English has one; and *Vähennä
  liikettä* for Reduce Motion.

### et — Estonian
- Terms: *ala* for area, *maalapp* for plot, *püsikupeenar* for the borders,
  and *klaaskaanega kast* for the frames, because *kasvulava* is a forcing
  frame. *Vastupäeva* / *päripäeva*, *Suumi sisse* / *välja*, and *saadik* for
  ambassador.
- The postcard is *{name} kasvab Peace Gardenis. Ala: {area}.* The failure
  lines inflect each area's name (*Vaiksesse aeda*, *Kännuvõsudele*).
- For a reader: *maalapp* for plot; *Kännuvõsudele* and *Ristumisele* as the
  case for those two names; and the description of Reduce Motion (*liikumise
  vähendamine*).

### is — Icelandic
- Terms: *svæði* for area, *skiki* for plot, and *glerkassar* for the frames,
  because *vermireitur* is a forcing bed. *Rangsælis* / *réttsælis*, *Auka* /
  *Minnka aðdrátt*, and *sendiherra* for ambassador. The failure lines decline
  each area's name (*Kyrrláta garðinn*, *Heimahagana*, *Áttablaðarósina*).
- The postcard is *{name} vex í Peace Garden. Svæði: {area}.*, since each name
  carries its own article.
- For a reader: *skiki* for plot (`privacy9` already uses *reitir* for squares
  of ground); *sáðraðir* for drills; and *„Minnka hreyfingu“ (Reduce Motion)*.

### he — Hebrew
- Terms: *אזור* for area, *חלקה* for plot, *ערוגות* for the borders, *תיבות
  גידול* for the frames, and *גדמים* for stools. Masculine address, as in
  `privacy8`. Latin names after a hyphen (*ה-App Store*, *ו-Apple*), as
  `appNote` writes *ל-iPhone*, and a maqaf in *כחול־ירוק*. No direction marks
  were added, since the catalogue has none.
- `plantPostcardText` opens in Hebrew, as `wildPostcardText` does since the
  last review: *צומח באזור {area} של Peace Garden: {name}.* `{area}` always
  stands second in a construct, never under a prefix that would swallow its
  article.
- For a reader: *השגריר* for a plant; *להמשיך במורד השדרה*; and *הפחתת תנועה*,
  which should be iOS's own Hebrew.

### eu — Basque
- Terms: *eremu* for area, *lursail* for plot, *lore-ertz* for the borders,
  *motzondo* for stools (as the area name has it), and *enbaxadore* for
  ambassador. *Zu*, as the catalogue is written. The failure lines inflect
  each area's name (*Lorategi isilera*, *Motzondoetara*). The postcard is *{name},
  Peace Gardenen hazten. Eremua: {area}.*
- For a reader: *ohe* for a garden bed; *gremio* for a plant guild; *App
  Storeri* written without a hyphen, as the catalogue writes *Peace Gardenek*;
  and *Mugimendua murriztu (Reduce Motion)*.
- **`wildTitle`, *Landa Basatiak*: kept, as a judgement for a Basque reader to
  confirm.** The last review asked whether *basati* leans too far towards
  *savage*. It is the ordinary word for wild nature and untamed land (*natura
  basatia*, *lurralde basatiak*, *animalia basatiak*), and its savage sense
  belongs mostly to people and conduct. The proposed *basa-* compound
  (*Basalandak*) is not an established word, and *basa* on its own also means
  mud. If a reader still wants it changed, the name is in `wildBody`,
  `wildAway`, `wildPostcardText`, `privacy8` and `privacy9` as well.

### ga — Irish
- Terms: *limistéar* for area, *ceapach* for plot and bed (as `privacy6` has
  it), *imeall bláthanna* for the borders, *seanbhunanna* for stools, and
  *casadh* for a meeting, as the catalogue says it. *Tuathal* / *deiseal* for
  the turns. In the failure lines each area's name is the object, with its
  article in lower case (*an t-úllord*, *ceapach na síolta*).
- The postcard is *{name}, ag fás in Peace Garden. Limistéar: {area}.*, since a
  preposition before `{area}` would want a mutation that the placeholder cannot
  take.
- For a reader: *an snaidhm* follows the catalogue's area name, but *snaidhm* is
  usually feminine (*an tsnaidhm*), and the area name may want the same
  correction. Also *Laghdú Gluaisne (Reduce Motion)*, and *imfhálú* for an
  enclosure.
