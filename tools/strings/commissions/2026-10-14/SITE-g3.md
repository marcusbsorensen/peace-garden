# Site strings, group 3: it, ja, ko, lt, lv, mk, mt, nb, nl, pl, 14 October 2026

Marcus's choice of 14 October (19A): translate now, and mark everything for a
native reader. **Nothing here has been read by anybody who speaks the
language.** Every string added below wants that reading, and the lines under
*Unsure* are where it would earn most.

Branch `claude/translate-site-g3-2026-10-14`, from `main` at `84194c8`.
`check.py`: 42 clean. `export.py --check`: in step.

## What was added, in all ten

**45 keys per language, 450 in all**: the 44 that were in no language
(`gardenBody downloadBody walkTitle walkThisArea walkBody walkAbout walkGrowing
walkEmpty walkAway walkTurnAnti walkTurnClock moveUp moveDown moveLeft moveRight
zoomIn zoomOut moveHome plantKey plantAmbassador plantPostcard plantPostcardText
plantCopied plantCopyThis plantClose quietAbout quietAway crossAbout crossAway
orchardAbout orchardAway knotAbout knotAway seedbedAbout seedbedAway frameAbout
frameAway glasshouseAbout glasshouseAway coppiceAbout coppiceAway groundAbout
groundAway goOn`), checked against `strings.js` and each catalogue, and
`privacy10`. Every catalogue now has all 146 keys.

**Where they sit in the file.** Existing keys keep their order and values. New
keys go in by `strings.js` order: `gardenBody` after `gardenTitle`,
`downloadBody` after `downloadTitle`, the walk/pad/panel/area block after
`downloadBody`, `goOn` after `notYet`, `privacy10` after `privacy9` (where the
Danish has it). Same format as before: one-space indent, characters unescaped.

**Decisions that hold across the ten:**

- **`walkTitle` is each language's `areaTravel`, word for word.** Both say *The
  Long Walk* in English and name one place.
- **The failure lines name the area as the catalogue does**, in whatever case
  the sentence needs (genitive in lt and pl; nominative with an agreeing
  predicate in lv, mk, mt; as written elsewhere). *The walk* in `walkAway` is
  the head noun of `areaTravel` (*il viale*, *alėja*, *laan*…), or the whole name
  in ja and ko.
- **`{area}` is the area's name with its article, in the nominative**, set in
  by `plantpanel.js` as the catalogue writes it. Where a language would have to
  inflect it, the placeholder sits in quotation marks after the language's
  established word for an area, which stays nominative: it *dell'area «{area}»*,
  lt *srities „{area}“*, lv *apvidus „{area}“*, mk *подрачјето „{area}“*, mt
  *taż-żona “{area}”*, pl *obszaru „{area}”*. ja, ko, nb and nl need no frame (nb
  takes the s-genitive on the whole name: *Såbedets*, *Den stille hagens*).
- **The paging clause's *Go on* agrees with `goOn`** where the language allows
  (*Prosegui*, *Verder/Loop verder*, *Gå videre*, *Kompli*, *Продолжи*). It stays
  an imperative where the catalogue's own *Drag to walk it* is one, and a
  *can* form in ja and ko, as theirs is.
- **The knot's unit is the language's pattern word, not a knot**, where the
  area is not named for a knot: *intreccio* (it), 模様 (ja), 무늬 (ko), *raštas*
  (lt), *raksts* (lv), *шара* (mk), *disinn* (mt), *mønster* (nb), *wzór* (pl). nl
  says *het volgende parterre*, which is its area's own name.
- **Numbers in the area paragraphs stay words**, as the English writes them:
  *five trees in a quincunx*, *three raised beds* are descriptions, not counts
  read off a table.
- **`plantClose`** is now the ✕ button's accessible name, read aloud. Each is
  the language's ordinary button verb, and in it, nb and nl the app's own:
  *Chiudi*, 閉じる, 닫기, *Uždaryti*, *Aizvērt*, *Затвори*, *Agħlaq*, *Lukk*,
  *Sluiten*, *Zamknij*.
- **`gardenTitle`** also names `/g`'s hidden heading. All ten still read right
  as a heading and as the bar's way back (*Il giardino*, 庭, 정원, *Sodas*,
  *Dārzs*, *Градината*, *Il-ġnien*, *Hagen*, *De tuin*, *Ogród*); none changed.
- **`privacy10`, Reduce Motion.** Its rule is the setting's own name as the
  phone writes it. it, ja, ko, nb, nl and pl use iOS's: *Riduci movimento*,
  視差効果を減らす, 동작 줄이기, *Reduser bevegelse*, *Verminder beweging*,
  *Ogranicz ruch*. **iOS has no Lithuanian, Latvian, Macedonian or Maltese**, so
  a reader of those has a phone in another language, most likely English, and
  the page names the setting as their phone shows it: *„Reduce Motion“* (lt,
  lv, mk), *“Reduce Motion”* (mt), introduced by the word for a setting. If iOS
  has added any of the four, the name should become that.
- **`privacy10`'s claims**, checked in each: the name and version for a moment;
  the question goes to the App Store of the reader's own country (the store's
  country, not where they stand: ko says *당신 나라의*, not *당신이 있는
  나라의*); only that country and the app's id; Apple receives it from the
  internet address, as with any request, in the catalogue's own word for a
  request (`privacy5`'s); the arrow beside the version number opens the App
  Store; no store country means no question; Reduce Motion means neither name
  nor question. *App Store* and *Peace Garden* stay as names.

## Per language

### it — Italian
- Terms: *area* (as `privacy6`, `meaningsAbout`), *riquadro* for a plot (general
  enough for a glasshouse and a wood), *aiuola* for a bed, *cassoni* for the
  cold frames, *ceppaie* for the stools (the area is *La ceppaia*), *bancali*
  for staging, *bordura* for a border, *Prosegui* for *Go on*, imperatives *tu*.
- **Elision.** No *altra persona* appears anywhere on the site, before or after
  this round, so the app's *all'altra persona* / *dell'altra persona* has
  nothing to match here. Searched for unelided *a l'*, *di l'*, *da l'*, *su l'*:
  none.
- Unsure: *Leggi della pianta al centro* for `plantKey`; *gilda* for a guild;
  *la dormienza* as a place to be reached in `frameAway` (it is the area's name);
  `plantAmbassador` as *Ambasciatrice* (feminine, agreeing with *pianta*).

### ja — Japanese
- Terms: 区画 for an area, as before, so a plot is never 区画: `moveHome` is
  全体を表示, and the paragraphs say 植え込み, 畑, 仕切り. フレーム for a cold
  frame, ギルド for a guild, サイコロの五の目 for the quincunx, 辻 for the next
  crossing (the area is 出会いの辻).
- Unsure: the knot paragraph describes clipped hedging under an area named
  枯山水, which is the name's business and not this round's; *いまは…につながりません*
  copies `wildAway` and may read oddly for a place (つながる is a connection).

### ko — Korean
- Terms: 구역 for an area, so the crossing's quarters and the knot's
  compartments are 칸; `moveHome` 전체 보기; 냉상 for a cold frame, 길드 for a
  guild, 유리온실 as the area has it, 그루터기 for the stools (the area's own
  name).
- Unsure: *다음 무늬로* for the next knot under an area named 화계; the
  `plantAmbassador` 대사 (an ambassador, but also *a line of dialogue*).

### lt — Lithuanian
- Terms: *sritis* for an area, *lysvė* for a plot (as `privacy6`), *inspektai*
  for cold frames, *oranžerija* in the glasshouse paragraph to match the area's
  name, *kelmai* for stools, *gėlynas* for a border; buttons in the infinitive
  (*Uždaryti*, *Perkelti aukštyn*), the paging clause in the *tu* imperative as
  `wildBody`'s *Vilk*.
- Unsure: the genitive forms of the names (*Tyliojo sodo*, *Gimtosios žemės*,
  *Atžalų*); *gildija*; *penkios akutės ant lošimo kauliuko* for the quincunx;
  *Eik prie kito daržo* for the next plot of the kitchen garden.

### lv — Latvian
- Terms: *apvidus* for an area, *dobe* for a plot (as `privacy6`), *aukstās
  lecektis* for cold frames, *oranžērija* as the area has it, *puķu apmale* for a
  border, *celmi* for stools; failure lines in the nominative (*Klusais dārzs
  pašlaik nav sasniedzams*), copying `wildAway`.
- Unsure: *ģilde*; *Izstaigāt šo apvidu* for `walkThisArea`; the agreement in
  `coppiceAway` (*Atvases … sasniedzamas*).

### mk — Macedonian
- Terms: *подрачје* for an area, *леја* for a plot (as `privacy6`), *пенушки*
  for stools, *заедница* rather than a loan for a guild, *шара* for the next knot,
  *настанува* for a seed being drawn (as `privacy2` and `privacy4` say it);
  imperatives as `wildBody`'s *Повлечи*.
- Unsure: area names without an article as subjects (*Крстосница моментално не
  е достапна*), kept as names; *земја* for a country in `privacy10`, where the
  same word is soil in `privacy9` and in *Родна земја*. No long single words
  were needed in these strings, which are prose and wrap at spaces.

### mt — Maltese
- Terms: *żona* for an area, *ħawt* for a plot (as `privacy6`), *selħiet* for
  drills, *link* feminine (as `damaged` and `privacy4`; `appNote` has it
  masculine), *Kompli* for *Go on*.
- Unsure, and Maltese wants a speaker most: *sies* for a hedge; *biċċa ħaxix*
  for a lawn; *ċangar* for paving; *L-ambaxxatriċi* for the ambassador; whether
  *Il-friegħi ġodda ma jistgħux jintlaħqu* reads as a place.

### nb — Norwegian Bokmål
- Terms: *område* for an area, *parsell* for a plot, *rabatt* for a border,
  *kaldbenker* for cold frames (not *drivbenk*, which forces), *stubbene* for the
  stools beside *Stubbehagen*, *Lukk* as the app; a-forms as the catalogue
  (*klokka*, *døra*); *Gå videre* for *Go on*.
- Unsure: *et laug av fire planter* for a guild; *femmeren på en terning* for
  the quincunx; *{area}s ambassadør: den første planten som fikk plass her*. No
  long single words here; the map's long names are not in this round.

### nl — Dutch
- Terms: *gebied* for an area, *perk* for a plot, *koude bakken* and *de kas*
  and *het parterre* carried from the area names into their paragraphs,
  *stoven* for stools, *Sluiten* as the app, infinitives on the buttons
  (*Inzoomen*, *Tegen de klok in draaien*), *Verder* for *Go on*.
- **The plant is *hij/hem/zijn* across the whole of nl.json, as the app says
  it.** 30 pronouns in 7 keys, each an exact phrase:
  - `about1`: *Ze opent zich … in haar eigen tempo* → *Hij … zijn* (2)
  - `meaningsAbout`: *waar ze thuishoort*, *in welk gebied ze staat* → *hij* (2)
  - `meaningsSecond`: *van haar geslacht* → *zijn* (1)
  - `frontLead`: *en ze opent zich* → *hij* (1)
  - `privacy6`: *haar zaadje*, *haar twee ouders*, *om haar een plek te geven*,
    *haar hoogte, haar kleur, haar gebied*, *van haar naam*, *wanneer ze is
    aangeboden*, *kan haar … zien staan*, *kan haar terughalen*, *waar ze
    stond*, *zodat ze niet* → *zijn/hem/hij* (12)
  - `wildBody`: *als ze wordt losgelaten*, *haar eigen zaadje haar neerzet*,
    *die haar lieten groeien* → *hij*, *zijn … hem*, *hem* (4)
  - `privacy8`: *stuurt de app haar*, *haar zaadje*, *haar twee ouders*, *als ze
    die heeft*, *van haar ouders* (twice), *die haar lieten groeien*, *wordt ze
    daar eerst teruggehaald* → *hem/zijn/hij* (8)
  - Left as they are, because they are not the plant: the phones, the two
    people and the backups (*ze*, plural), the page in `privacy9` (*stuurt ze*),
    the ground (*zoals hij was*).
  - **Not changed: `meaningLight`**, *de dag waaraan ze de tijd afmeet*.
    `check.py` holds it to the app's `theme.light.definition`, which says *ze*
    too, so changing the site alone fails the check. **The two want changing
    together** to *waaraan hij de tijd afmeet*, in the app's round.
- Unsure: `{area}` mid-sentence keeps the name's capital (*Ambassadeur van De
  kas*, *die groeit in Het zaaibed*); *gilde* for a guild; *Over de plant in het
  midden lezen* for `plantKey`.

### pl — Polish
- Terms: *obszar* for an area, *grządka* for a plot (as `privacy6`), *działka*
  for the kitchen garden's next plot, *inspekty* for cold frames, *rabata* for a
  border, *pniaki* for stools; *losowane* for a seed being drawn; *Dalej* for
  *Go on*; *„Ogranicz ruch”*.
- Unsure: the genitive names in the failure lines (*do Cichego ogrodu*, *do
  Odrośli*); *grządka* for the plots of the Long Walk and the Glasshouse, kept
  for agreement with `privacy6` where *kwatera* would be more general; *gildia*.
