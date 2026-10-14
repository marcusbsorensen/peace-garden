# Site strings, group 4, 14 October 2026

Marcus chose 19A on 14 October: translate now, and mark everything for a native
reader's review. This is group 4 of the website part: **pt, ro, ru, sk, sl, sq,
sr, sv, tr, uk, zh**. Each catalogue had the same 45 strings missing, and each
now has all 146:

- the 44 keys that were in no language (`gardenBody downloadBody walkTitle
  walkThisArea walkBody walkAbout walkGrowing walkEmpty walkAway walkTurnAnti
  walkTurnClock moveUp moveDown moveLeft moveRight zoomIn zoomOut moveHome
  plantKey plantAmbassador plantPostcard plantPostcardText plantCopied
  plantCopyThis plantClose quietAbout quietAway crossAbout crossAway
  orchardAbout orchardAway knotAbout knotAway seedbedAbout seedbedAway
  frameAbout frameAway glasshouseAbout glasshouseAway coppiceAbout coppiceAway
  groundAbout groundAway goOn`), checked against `strings.js` and each
  catalogue before writing;
- `privacy10`, the launch moment's update check, written against `UPDATE` in
  `commission.py`.

Each language was written in one pass against its own catalogue's words. New
keys go in `strings.js` order: `gardenBody` after `gardenTitle`,
`downloadBody` and the walk, pad, panel and area keys after `downloadTitle`,
`goOn` after `notYet`, `privacy10` after `privacy9`. `check.py`: 42 of 42
clean. **Nobody who speaks any of these eleven has read a word of this round.**
Every string here is for a native reader, through `docs/REVIEWING-A-LANGUAGE.md`.

## What holds across the eleven

- **The word for an area is the one `meaningsAbout` and `privacy6` already use**:
  zona, zona, участок, oblasť, območje, zonë, подручје, område, alan, ділянка,
  区域.
- **`{area}` arrives as the area's name, in the form the catalogue writes it**,
  which is the nominative. So in `plantAmbassador` and `plantPostcardText` the
  inflecting languages set it in quotes after their word for an area (*na zona
  «A estufa»*, *на участке «Тихий сад»*, *v oblasti „Skleník“*), the one
  construction where a name may stay in the nominative. Swedish needs no quotes:
  its names are definite and take *-s* and *i* (*Kallbänkens ambassadör*, *i
  Kallbänken*). Turkish writes *{area} alanı*, so no suffix has to agree with a
  name it cannot see. Chinese needs neither. The postcard follows each
  language's `wildPostcardText`, its sister string.
- **The ten failure lines name their area by hand**, in whatever case the sentence
  needs (*До Тихого сада…*, *Kışlağa…*, *Butucii nu pot fi accesați…*), on the
  pattern of that language's `wildAway`.
- **`walkTitle` is the language's `areaTravel`**, word for word. `/walk` heads
  itself with `areaTravel` and the two say *The Long Walk* in English.
- **`plantClose` is a verb that works as a button's name read aloud**: Fechar,
  Închide, Закрыть, Zavrieť, Zapri, Mbyll, Затвори, Stäng (the app's own), Kapat,
  Закрити, 关闭. **`gardenTitle` was not changed**, and in all eleven it reads as
  the heading of the map at `/g`.
- **The counts in the layout descriptions stay words**: *ten areas*, *six
  drills*, *four low frames*, *three bands*. They describe a scene rather than
  report a quantity, as the English writes them and as every catalogue already
  writes `meaningsAbout`'s *three parts*. If Marcus reads *Ten areas* in
  `gardenBody` as a count, it becomes a numeral in every language.
- **`downloadBody`'s *drawn*** uses the verb each language's `privacy4` uses for
  when a seed was made (*tirada*, *extrasă*, *появляется*, *dras*, *çekilir*,
  *抽出*…).
- **A plot** is `privacy6`'s word where it has one. The kitchen garden's *next
  plot* takes a different word wherever *beds* had already taken that one.
- **The next knot** goes to the language's own area name: a parterre (ru, sk,
  sl, sr, sv), a girih (tr), a pattern (pt, ro, sq), 回纹 (zh).
- **The frames** are described as low boxes with glass lids, not as hotbeds,
  because most of these languages' word for a frame is a forcing frame
  (`NAMING.md`). Swedish keeps *kallbänk*, which is its area's own word and
  names the unheated kind.
- **Reduce Motion is the phone's own name for the setting** in the eight that
  are iOS languages: Reduzir movimento, Reducere mișcare, Уменьшение движения,
  Obmedziť pohyb, Minska rörelse, Hareketi Azalt, Зменшення руху, 减弱动态效果.
  **Slovenian, Albanian and Serbian are not iOS display languages as far as I
  know**, so each gives its own rendering with *(Reduce Motion)* beside it:
  that is the name the reader's phone most likely shows. Serbian's *Смањи
  кретање* is Croatian iOS's *Smanji kretanje* in Cyrillic. All eleven names
  are from memory and want a reader with a phone.

### Two English claims worth a look (not changed)

- **`walkBody`** says the Walk is *the one area of the garden with real plants
  in it*. That stopped being true when all ten areas opened, and the comment in
  `strings.js` says the string is said nowhere now. Translated as written.
- **`downloadBody`** says the plant that grows from a seed *is nobody else's*.
  `growBody` says *this meeting grows one plant, you both have it*. The
  translations say what the English says.

## Per language

All eleven: **45 keys added** (the 44 and `privacy10`).

### pt — Portuguese
European, with *tu*. Area *zona*. Plot *canteiro* (`privacy6`); the kitchen
garden's plot *talhão*, because its raised beds are *canteiros*. *Tirada* for
drawn. Turns *Rodar no sentido anti-horário / horário* (`frontTurn`'s
*rodar*), zoom *Ampliar / Reduzir*. The failure lines contract with the name in
lower case, as the catalogue writes it (*à estufa*, *ao pomar*).
**Unsure:** the about paragraphs use *tu* imperatives (*Segue…, ou dá a
volta*) where `wildBody` used the infinitive (*Arrastar para o percorrer*).
*Não é possível chegar à dormência* reads as the state as much as the place.
*Guilda* for guild. Whether Portuguese (Portugal) iOS capitalises *Reduzir
Movimento*.

### ro — Romanian
*Tu*. Area *zona*, with „…”. Plot *strat* (`privacy6`); the kitchen garden's
plot *parcelă*. *Extrasă* for drawn. Turns use *rotește* (`frontTurn`'s *a
roti*). The failure lines agree with each name (*Sera nu poate fi accesată*,
*Pământul natal … accesat*, *Butucii nu pot fi accesați*).
**Unsure:** *patru plante însoțitoare* for a guild of four plants, which is
plainer and drops the permaculture term. *Rotește-te* for turning to see a
plot from another side. *Plantele cresc…* (the plants are growing) for
`walkGrowing`, where the English means the page is growing them.

### ru — Russian
*Ты*. Area *участок*, with «…». Plot *грядка* (`privacy6`); the kitchen
garden's plot *делянка*. `moveHome` is *Показать всё целиком*, which avoids
calling a glasshouse or an orchard a *грядка*. *Появляется* for drawn.
*Миксбордер* for the border, *посадка конвертом* for the quincunx, *партер*
for the knot. The failure lines follow `wildAway`: *До … сейчас не добраться*.
**Unsure:** *Посол* for ambassador. The pad uses bare directions (*Вверх*)
beside verbs (*Приблизить*). *Гильдия*.

### sk — Slovak
*Ty*. Area *oblasť*, with „…“. Plot *záhon* (`privacy6`); the kitchen garden's
plot *parcela*. *Objaví sa* for drawn. The about paragraphs say *otoč sa a
uvidíš* so that no participle is gendered. The quincunx is *päť bodiek na
hracej kocke*, the knot *parter*. The failure lines agree by gender (*Výmladky
teraz nie sú dostupné*).
**Unsure:** *Veľvyslankyňa*, which is feminine after *rastlina*.
*Spoločenstvo* for guild.

### sl — Slovenian
*Ti*. Area *območje* (*na območju*), with „…“. Plot *greda* (`privacy6`); the
kitchen garden's plot *parcela*. *Nastane* for drawn. The knot is *parter*.
Reduce Motion is *Zmanjšaj gibanje (Reduce Motion)*. The failure lines agree by
gender (*Križišče … ni dosegljivo*).
**Unsure:** whether Slovenian is an iOS language. *Trajnična greda* for the
border uses the same word as the plot. *Skupnost* for guild. *Ambasadorka*.

### sq — Albanian
*Ti*. Area *zonë*, with «…». Plot *parcelë*, where `privacy6` says *brazdë* (a
furrow), which reads wrong for a whole plot: a reader should look at both.
Beds are *lehe*. *Krijohet* for drawn (`privacy4` says *u krijua*). The knot
is *modeli*, because I am not sure *parter* is a garden word in Albanian.
Reduce Motion is *Zvogëlo lëvizjen (Reduce Motion)*.
**Unsure:** Albanian is not an iOS language. *Ambasadorja*. *Grup* for guild.

### sr — Serbian
Cyrillic, as the catalogue, with *ti*. Area *подручје* (*на подручју*), with
„…“. Plot *леја* (`privacy6`); the kitchen garden's plot *парцела*. *Настаје*
for drawn. The postcard says *у апликацији Peace Garden*, as
`wildPostcardText` does. The knot is *партер*. Reduce Motion is *Смањи кретање
(Reduce Motion)*. Checked: no Latin letter outside the product and platform
names.
**Unsure:** Serbian is not an iOS language. *Заједница* for guild. *до следећа
четири*.

### sv — Swedish
*Du*. Area *område*. The ambassador is *{area}s ambassadör*, and the genitive
works because every area name ends in *-n* or *-t*: a renamed area ending in
*-s* would need this string looked at again. The postcard says *i {area}*.
*Stäng* and *länk* are the app's own words; *dras* for drawn (`privacy4`).
Turns are *Vrid moturs / medurs* (`frontTurn`'s *vrida*). *Minska rörelse* is
in the ”…” that `privacy7` uses for a setting. *Kvinkunx*, *växtgille*,
*kallbänkar*, *parterr*. The kitchen garden's plot is *täppa*, `moveHome`'s
plot *planteringen*. The Wild Fields stay *Vildmarken*, though none of these
strings names them.
**Unsure:** *Växterna växer fram…* for `walkGrowing`. *Planteringen* for the
plot.

### tr — Turkish
*Sen*. Area *alan*, written *{area} alanı*. Plot *tarh* (`privacy6`); the
kitchen garden's plot *parsel*. *Çekilir* for drawn. Each failure line puts the
dative on its name (*Kışlağa*, *Seraya*, *Uzun yola*). The quincunx is *zarın
beşi*, the guild *lonca*, the knot *girih*, as the area is named.
**Unsure:** *uygulamanın kimliği* for the app's id. *Uzun yola* for the walk.

### uk — Ukrainian
*Ти*, with the typographic apostrophe the catalogue uses. Area *ділянка*, with
«…». Plot *грядка* (`privacy6`). The kitchen garden's next plot is *город*,
because *ділянка* is already the area. *З’являється* for drawn. The quincunx
is *п’ять крапок на гральному кубику*, since *конвертом* is Russian usage. The
knot is *партер*. The failure lines follow `wildAway`: *До … зараз не
дістатися*.
**Unsure:** *Посол* for ambassador.

### zh — Chinese
Simplified, as the catalogue, with full-width punctuation and a space either
side of a Latin run. Area *区域*. Plot *园地*; the kitchen garden's plot
*菜地*. *抽出* for drawn. The quincunx is *梅花形*, the guild *共生组合*, the
knot *回纹*. The ellipsis is *……*, as Chinese writes it. Reduce Motion is
“减弱动态效果”. *国家或地区* for country, as Apple's Chinese writes it, and
*轻点* for touch.
**Unsure:** *大使* for ambassador. *从老桩旁* for ferns coming back from the old
stools.
