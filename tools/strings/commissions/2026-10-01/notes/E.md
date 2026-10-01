# Batch E — the Wild Fields, site strings, 30 languages

Eight keys per language (`wildTitle`, `wildBody`, `wildEmpty`, `wildAway`,
`wildByOne`, `wildByTwo`, `wildPostcardText`, `privacy8`), added to
`Server/strings/<code>.json` beside the privacy keys; no existing string
changed. `check.py` on all 30 exits 0. None of this has been read by a
speaker of the language yet.

**Common decisions.**

- *Release* is everywhere the word for setting a living thing free into the
  wild (an animal released, a bird let loose), never publish, post or share.
- The Wild Fields name is one place-name per language, used in every one of
  the eight strings that mention it, inflected where the grammar requires. It
  is not one of the ten areas and does not look like any of them; none uses
  the language's word for garden or park.
- `privacy8` reuses each catalogue's own words from `privacy2`–`privacy7`:
  the web garden, random numbers, the meeting, the parents' seeds, and the
  *scrambled form* of `privacy5`. All eight claims are present, in order, and
  nothing is called anonymous.
- `wildByOne`/`wildByTwo`: where the language has case, the name sits where it
  stays in the nominative or where a foreign name is left uninflected: after
  a verb (*Izaudzēja {name}*), as a label (*Kasvattaja {name}*,
  *Yetiştiren: {name}*), or after a preposition that takes names as written.
  No language's `wildByOne` mentions a second person.
- There are no quantities in these eight strings. *Two* is prose throughout
  (the two who grew it, the two seeds), so no numerals were written, and none
  in Arabic.
- In `wildBody`, *Drag to walk it* follows the form each catalogue's
  `frontTurn` already uses.

## Per language

**de — *Wilde Felder*** (in sentences *die Wilden Felder*). No article in the
heading, as with the German area names (*Stiller Garten*). *Brache* was
considered and dropped because it reads as wasteland. Release: *freilassen*.
Uncertain: *Zum Durchstreifen ziehen* for "drag to walk it".

**cy — *Y Meysydd Gwyllt*.** *Maes/meysydd* is open field. Release: *rhyddhau*.
Uncertain: `wildByTwo` *{a} a {b}*. Before a vowel Welsh wants *ac*, and the
name is not known in advance.

**ga — *Na Machairí Fiáine*.** *Machaire* is open plain, unlike *gort*
(a tilled field) or *páirc*, which is also a park. Release: *scaoil saor*.
Uncertain: whether the adjective should be lenited after *machairí*. It was
left unlenited because the plural ends in a vowel.

**is — *Villtu vellirnir*.** Release: *sleppa*, as for an animal. The by-lines
are labels (*Ræktandi: {name}*, *Ræktendur: {a} og {b}*) because *af {name}*
would need a dative that a name typed as written cannot carry.

**fi — *Villit niityt*.** *Pelto* is cultivated land, so meadows were used
instead. Release: *päästää vapaaksi*. The by-lines follow `sentBy`
(*Kasvattaja {name}*). Uncertain: *Peace Gardenissa* in the postcard, since the
catalogue never inflects the name elsewhere.

**et — *Metsikud väljad*.** Release: *vabaks laskma*. The by-lines follow
`sentBy` (*Kasvataja: {name}*). The postcard uses *Peace Gardenis*, and the
catalogue already inflects the name (*Peace Gardeni*).

**lv — *Savvaļas lauki*.** Release: *palaist savvaļā*, literally into the wild,
so the name and the verb share a root. Postcard: *lietotnē Peace Garden*,
which keeps the name uninflected.

**lt — *Laukiniai laukai*.** *Laukinis* (wild) comes from *laukas* (field).
Release: *paleisti į laisvę*. Postcard: *programėlėje Peace Garden*.

**pl — *Dzikie Pola*.** This is also the historical name of the steppe
borderland, an open and untended expanse, which fits. A reader may still want
to rule on it. Release: *wypuścić na wolność*. The by-lines are passive
(*Wyhodowana przez {name}*) to avoid a gendered past tense.

**cs — *Divoká pole*.** Release: *vypustit na svobodu*. Uncertain:
`wildByOne` *Vypěstoval(a) {name}*. Czech has no ungendered past tense and the
gardener's gender is unknown. `wildByTwo` uses the default plural
*vypěstovali*. In `privacy8` the gendered "you chose" was rephrased as
*podle tvé volby*.

**sk — *Divoké polia*.** As Czech: *vypustiť na slobodu*, and *Vypestoval(a)*
has the same uncertainty.

**hu — *Vadmezők*.** A compound with no article in the heading, like the
area names. Release: *szabadon enged*. The by-lines follow `sentBy`
(*Nevelte: {name}*). The postcard uses *a Peace Gardenben*.

**mt — *L-Għelieqi Selvaġġi*.** *Għalqa/għelieqi* are fields. It is capitalised as
a proper place-name (the area names are lower-case after the article).
Release: *teħles / tinħeles*, to set free. Uncertain: the capitalisation, and
*tinħeles* compared with *terħi*.

**ro — *Câmpurile sălbatice*.** Definite, like *Grădina liniștită*. *Pe*
câmpuri for location. Release: *a elibera*. By-lines: *Crescută de {name}*,
like *Trimisă de*.

**sl — *Divja polja*.** Release: *izpustiti*. The by-lines use the catalogue's
own inclusive form: *Vzgojil_a {name}*, as in *Poslal_a*. Two gardeners take
the dual, *Vzgojila {a} in {b}* (two women would be *vzgojili*). Uncertain:
that dual.

**hr — *Divlja polja*.** Release: *pustiti na slobodu*. Uncertain:
*Uzgojio/la {name}*, because the catalogue's present-tense trick (*Šalje*)
does not work for something already grown.

**sr — *Дивља поља*.** Cyrillic, as in sr.json. As Croatian, with
*Узгојио/ла*. Postcard: *у апликацији Peace Garden*, so the Latin name is not
inflected.

**mk — *Дивите полиња*.** Definite, like the area names. Release: *пушти на
слобода*. By-lines: *Одгледано од {name}* (neuter, agreeing with
*растение*), with no gender problem.

**bg — *Дивите полета*.** Release: *пусна на свобода*. By-lines: *Отгледано
от {name}*. In `privacy8` the gendered *си избрал* was rephrased as *по твой
избор*.

**sq — *Fushat e egra*.** Release: *lëshoj të lirë*. By-lines: *Rritur nga
{name}*, like *Dërguar nga*.

**el — *Οι Άγριοι αγροί*.** *Αγρός* is field, and the heading takes an
article like the area names. Release: *αφήνω ελεύθερο*. By-lines:
*Καλλιεργήθηκε από {name}*.

**ru — *Дикие поля*.** This echoes the historical *Дикое поле* (singular). The
plural keeps "more than one field". Release: *отпустить на волю*. Uncertain:
*Вырастил(а) {name}*, a gendered past tense with the bracket convention.

**uk — *Дикі поля*.** As Russian, with the same historical echo. Release:
*відпустити на волю*. Seed is *насінина/насінини*, per the termbase.
Uncertain: *Виростив(-ла)*.

**be — *Дзікія палі*.** Release: *адпусціць на волю*. Seed is *насенінка*.
Uncertain: *Вырасціў(-ла)*.

**tr — *Yaban kırları*.** *Kır* is open country. *Tarla* is tilled land and was
not used. Release: *serbest bırakmak*. By-lines are labels, like `sentBy`
(*Yetiştiren: {name}*, *Yetiştirenler: {a} ve {b}*).

**he — *השדות הפראיים*.** Release: *לשחרר*. The postcard avoids a prefix on the
Latin name (*של Peace Garden*). Uncertain: `wildByTwo` *ו{b}*, with the
conjunction attached directly to a name that may be in Latin script.

**ar — *البراري*.** The wild open lands, plural. It is a place-name rather than
*الحقول البرية*, and it shares nothing visually with the ten areas. Release:
*أطلق*, used for setting an animal free. By-lines follow `sentBy`
(*أنبتها {name}*). There are no numerals.

**ja — *原野*.** Uncultivated open land. Release: *放つ*, as in *野に放つ*. The
register is the catalogue's です／ます with あなた. *Drag to walk* is a
statement (*ドラッグで歩けます。*). Uncertain: *原野* has no plural, which
leaves "more than one field" to the sense of extent.

**ko — *들판*.** Release: *놓아주다*. The register is the catalogue's 합니다
with 당신. By-lines follow `sentBy` (*{name} 님이 기름*). Uncertain: *들판* compared
with *벌판*, and whether *기름* reads naturally as "grown by".

**zh — *旷野*.** Simplified, as in zh.json. Release: *放归* (as in 放归野外).
*放生* was rejected because of its religious sense. By-lines: *由 {name} 培育*,
like *由 {name} 发送*.
