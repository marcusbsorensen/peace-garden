# The site's privacy7 and privacy11, Zone C W2, 17 October 2026

`privacy7` (rewritten) and `privacy11` (new) in forty languages, on
`claude/translate-zonec-site-rest`, in four batches of ten. The English is
Marcus's, approved 17 October 2026, and is unchanged
(`design/space-seeds-2026-10-16/WORDING-en.md`, sections 1 and 2). **Nobody who
speaks any of these forty languages has read these translations yet.** They
follow each language's `commission.py --privacy` brief and its settled
vocabulary; they are for review.

**The same choices in every language:**

- **"News from the garden".** The app has no label for the renamed switch in
  any language yet (`Localizable.xcstrings` still holds the old *Alert me when a
  joint seed is shared* label, in da, es, fr, it, nb, nl, sv only; the new label
  is A5's and T1's). So in every language the switch is rendered plainly as
  *news from the garden*, with the garden word the catalogue already uses.
  Where the app is translated (es, fr, it, nb, nl, sv), this should be
  matched to T1's label once it exists.
- **"Two pools".** Read as a pair named straight away by *one … and one …*, in
  the same way as the catalogue's *two random numbers* and *two parents*: prose,
  not a count to put in a table. So it stays a word in every language. 64 and
  104 are sizes and keep numerals (the language's own digits), with its word for
  byte.
- **Pool.** Rendered as a place where values are kept together (store, tank,
  depot), never as water, as the brief's note asks.
- **Reply.** The reply to a seed is the catalogue's word for an answer; the
  answer to a request is worded as the response to the request where the
  language allows, so the two stay apart.
- **Autonaut, Peace Garden** are untranslated. Informal address wherever the
  sentence addresses the reader.

## ar - Arabic

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- ar: ومع تشغيل أخبار الحديقة، يسأل التطبيق حديقة الويب عن نبتاتك المشتركة في كلّ مرّة يبدأ فيها، وذلك بإرسال الأرقام العشوائية من لقاءاتك. ويسأل سواء التقيت بأحد أم لا. ويرسل كلّ طلب أيضًا قيمة واحدة تبدو عشوائية وردًّا واحدًا يبدو عشوائيًا، ويعيد الجواب عددًا قليلًا من كلٍّ منهما.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- ar: تحتفظ حديقة الويب بالقيم التي تتلقّاها وتبدو عشوائية في مجمَّعين، أحدهما لقيم من ٦٤ بايت والآخر لقيم من ١٠٤ بايت. تُحفظ كلّ قيمة وحدها، بلا وقت ولا عنوان ولا ترتيب. وتبقى القيمة إلى أن تدفعها قيم أحدث. وتترك النسخة الاحتياطية الليلية للحديقة المجمَّعين خارجها. ولا يُفتح الردّ إلا على الهاتف الذي أرسل بذرته. وتنتقل بذور Autonaut بهذه الطريقة أيضًا. وبالنسبة إلى حديقة الويب، كلّ قيمة أرقام عشوائية.

- **Terms.** seed بذرة, plant نبتة, web garden حديقة الويب, meeting لقاء, random numbers أرقام عشوائية; pool مجمَّع (dual مجمَّعين); byte بايت; switch أخبار الحديقة; Eastern Arabic digits ٦٤ and ١٠٤.
- **Unsure.** The dual of مجمَّع and the vowelling of the plural/dual forms; *a few* for *a handful* (عددًا قليلًا); whether أخبار الحديقة reads as a switch label.

## be - Belarusian

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- be: Калі навіны з саду ўключаныя, праграма пры кожным запуску запытвае сад на сайце пра твае агульныя расліны, адсылаючы выпадковыя лікі з тваіх сустрэч. Яна запытвае незалежна ад таго, ці была ў цябе хоць адна сустрэча. Кожны запыт адсылае таксама адно значэнне, якое выглядае выпадковым, і адзін адказ, які выглядае выпадковым, а ў адказ на запыт вяртаецца некалькі таго і другога.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- be: Сад на сайце захоўвае атрыманыя значэнні, якія выглядаюць выпадковымі, у двух сховішчах: у адным значэнні па 64 байты, у другім — па 104 байты. Кожнае значэнне захоўваецца асобна, без часу, адраса і парадку. Значэнне застаецца, пакуль яго не выштурхнуць больш новыя. Начная рэзервовая копія саду пакідае сховішчы па-за сабой. Адказ адчыняецца толькі на тэлефоне, які даслаў сваю насенінку. Насенінкі з Autonaut ходзяць гэтым жа шляхам. Для саду на сайце кожнае значэнне — выпадковыя лікі.

- **Terms.** насенінка, расліна, сад на сайце, сустрэча, выпадковыя лікі; pool сховішча; байт; switch навіны з саду.
- **Unsure.** The two-value construction after *64/104* (*па 64 байты*) and the plural *насенінкі*; *некалькі* for *a handful*.

## bg - Bulgarian

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- bg: Когато новините от градината са включени, при всяко стартиране приложението пита уеб градината за твоите споделени растения, като изпраща случайните числа от твоите срещи. Пита независимо дали е имало среща с някого. Всяка заявка изпраща още една стойност, която изглежда случайна, и един отговор, който изглежда случаен, а в отговор на заявката се връща по няколко от двете.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- bg: Уеб градината пази получените стойности, които изглеждат случайни, в две хранилища, едното за стойности от 64 байта, другото за стойности от 104 байта. Всяка стойност се пази сама, без време, адрес или ред. Стойността стои, докато по-нови не я изместят. Нощното резервно копие на градината оставя хранилищата извън себе си. Отговорът се отваря само на телефона, който е изпратил своето семе. Семена от Autonaut пътуват по същия начин. За уеб градината всяка стойност е случайни числа.

- **Terms.** семе, растение, уеб градина, среща, случайни числа; pool хранилище; байт; switch новини от градината.
- **Unsure.** *Дали е имало среща с някого* is used to keep the sentence gender-neutral.

## ca - Catalan

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- ca: Amb les novetats del jardí activades, cada vegada que l'aplicació s'engega, pregunta al jardí del web per les teves plantes compartides, enviant-hi els números aleatoris de les teves trobades. Ho pregunta tant si has tingut alguna trobada com si no. Cada petició també envia un valor que sembla aleatori i una resposta que sembla aleatòria, i la resposta a la petició en torna uns quants de cada.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- ca: El jardí del web guarda en dos dipòsits els valors que rep i que semblen aleatoris, un de valors de 64 bytes i un de valors de 104 bytes. Cada valor es guarda sol, sense hora, adreça ni ordre. Un valor es queda fins que d'altres de més nous el desplacen. La còpia de seguretat nocturna del jardí deixa fora els dipòsits. Una resposta només s'obre al telèfon que va enviar la seva llavor. Les llavors d'Autonaut viatgen també d'aquesta manera. Per al jardí del web, cada valor són números aleatoris.

- **Terms.** llavor, planta, jardí del web, trobada, números aleatoris; pool dipòsit; byte (plural bytes); switch novetats del jardí.
- **Unsure.** *Uns quants de cada* for *a handful*; *en torna* for the answer bringing back.

## cs - Czech

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- cs: Když jsou zapnuté zprávy ze zahrady, aplikace se při každém spuštění ptá zahrady na webu na tvé sdílené rostliny, a to tím, že posílá náhodná čísla z tvých setkání. Ptá se, ať už nějaké setkání bylo, nebo ne. Každý dotaz posílá také jednu hodnotu, která vypadá náhodně, a jednu odpověď, která vypadá náhodně, a odpověď na dotaz přináší od každé z nich několik.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- cs: Zahrada na webu uchovává přijaté hodnoty, které vypadají náhodně, ve dvou zásobnících, jednom pro hodnoty o 64 bajtech a jednom pro hodnoty o 104 bajtech. Každá hodnota se uchovává samostatně, bez času, adresy a pořadí. Hodnota zůstává, dokud ji nevytlačí novější. Noční záloha zahrady zásobníky vynechává. Odpověď se otevře jen na telefonu, který poslal své semínko. Semínka z aplikace Autonaut putují také takto. Pro zahradu na webu je každá hodnota náhodná čísla.

- **Terms.** semínko, rostlina, zahrada na webu, setkání, náhodná čísla; pool zásobník; bajt; switch zprávy ze zahrady.
- **Unsure.** *Autonaut* is introduced as *aplikace Autonaut* so it need not decline. *Hrstka* was avoided for *a handful*; *několik* used.

## cy - Welsh

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- cy: Gyda newyddion o'r ardd ymlaen, bob tro y bydd yr ap yn cychwyn mae'n gofyn i'r ardd ar y we am dy blanhigion a rennir, drwy anfon y rhifau ar hap o'th gyfarfodydd. Mae'n gofyn pa un a wyt ti wedi cwrdd â rhywun ai peidio. Mae pob cais hefyd yn anfon un gwerth sy'n edrych fel petai ar hap ac un ateb sy'n edrych fel petai ar hap, ac mae'r ymateb i'r cais yn dod â llond llaw o'r naill a'r llall yn ôl.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- cy: Mae'r ardd ar y we yn cadw'r gwerthoedd sy'n edrych fel petaent ar hap y mae'n eu derbyn mewn dwy gronfa, un o werthoedd 64 beit ac un o werthoedd 104 beit. Cedwir pob gwerth ar ei ben ei hun, heb amser, cyfeiriad na threfn. Mae gwerth yn aros nes bod rhai mwy newydd yn ei wthio allan. Mae copi wrth gefn nosol yr ardd yn gadael y cronfeydd allan. Dim ond ar y ffôn a anfonodd ei hedyn y mae ateb yn agor. Mae hadau o Autonaut yn teithio fel hyn hefyd. I'r ardd ar y we, rhifau ar hap yw pob gwerth.

- **Terms.** hedyn, planhigyn, gardd ar y we, cyfarfod, rhifau ar hap, beit; pool cronfa; switch newyddion o'r ardd.
- **Unsure.** Mutations (*dwy gronfa*, *na threfn*) and *llond llaw*; I am least sure of this language of the ten.

## de - German

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- de: Wenn Neuigkeiten aus dem Garten eingeschaltet sind, fragt die App bei jedem Start den Webgarten nach deinen geteilten Pflanzen und schickt dazu die Zufallszahlen aus deinen Begegnungen. Sie fragt, ob du jemandem begegnet bist oder nicht. Jede Anfrage schickt außerdem einen zufällig aussehenden Wert und eine zufällig aussehende Antwort hoch, und die Antwort auf die Anfrage bringt von beidem eine Handvoll zurück.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- de: Der Webgarten bewahrt die zufällig aussehenden Werte, die er erhält, in zwei Speichern auf, einem für Werte zu 64 Byte und einem für Werte zu 104 Byte. Jeder Wert wird einzeln aufbewahrt, ohne Zeit, Adresse oder Reihenfolge. Ein Wert bleibt, bis neuere ihn verdrängen. Die nächtliche Sicherung des Gartens lässt die Speicher aus. Eine Antwort öffnet sich nur auf dem Telefon, das ihren Samen geschickt hat. Samen von Autonaut reisen ebenso auf diesem Weg. Für den Webgarten ist jeder Wert Zufallszahlen.

- **Terms.** Samen, Pflanze, Webgarten, Begegnung, Zufallszahlen, Byte; pool Speicher; switch Neuigkeiten aus dem Garten.
- **Unsure.** *Speicher* for pool (*Lostopf* was considered); *Werte zu 64 Byte*.

## el - Greek

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- el: Με τα νέα από τον κήπο ανοιχτά, κάθε φορά που ξεκινά η εφαρμογή ρωτά τον κήπο στο διαδίκτυο για τα φυτά που έχεις μοιραστεί, στέλνοντας τους τυχαίους αριθμούς από τις συναντήσεις σου. Ρωτά είτε έχεις συναντήσει κάποιον είτε όχι. Κάθε αίτημα στέλνει επίσης μία τιμή που μοιάζει τυχαία και μία απάντηση που μοιάζει τυχαία, και η απάντηση στο αίτημα φέρνει πίσω μια χούφτα από καθεμία.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- el: Ο κήπος στο διαδίκτυο κρατά τις τιμές που λαμβάνει και μοιάζουν τυχαίες σε δύο δεξαμενές, μία με τιμές των 64 μπάιτ και μία με τιμές των 104 μπάιτ. Κάθε τιμή κρατιέται μόνη της, χωρίς ώρα, διεύθυνση ή σειρά. Μια τιμή μένει μέχρι να τη σπρώξουν έξω νεότερες. Το νυχτερινό αντίγραφο ασφαλείας του κήπου αφήνει έξω τις δεξαμενές. Μια απάντηση ανοίγει μόνο στο τηλέφωνο που έστειλε τον σπόρο της. Οι σπόροι από το Autonaut ταξιδεύουν κι αυτοί με τον ίδιο τρόπο. Για τον κήπο στο διαδίκτυο, κάθε τιμή είναι τυχαίοι αριθμοί.

- **Terms.** σπόρος, φυτό, κήπος στο διαδίκτυο, συνάντηση, τυχαίοι αριθμοί; pool δεξαμενή; μπάιτ; switch νέα από τον κήπο.
- **Unsure.** *Χούφτα* for *a handful*; *μπάιτ* over the formal *ψηφιολέξη*.

## es - Spanish

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- es: Cuando las noticias del jardín están activadas, la app pregunta al jardín de la web por tus plantas compartidas cada vez que se abre, enviando los números al azar de tus encuentros. Pregunta tanto si te has encontrado con alguien como si no. Cada petición envía además un valor que parece al azar y una respuesta que parece al azar, y la respuesta a la petición trae de vuelta un puñado de cada uno.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- es: El jardín de la web guarda los valores que recibe y que parecen al azar en dos depósitos, uno de valores de 64 bytes y otro de valores de 104 bytes. Cada valor se guarda solo, sin hora, dirección ni orden. Un valor permanece hasta que otros más nuevos lo desplazan. La copia de seguridad nocturna del jardín deja fuera los depósitos. Una respuesta solo se abre en el teléfono que envió su semilla. Las semillas de Autonaut viajan también así. Para el jardín de la web, cada valor son números al azar.

- **Terms.** semilla, planta, jardín de la web, encuentro, números al azar, byte; pool depósito; switch noticias del jardín.
- **Unsure.** The app is translated into Spanish but has no label yet for the switch, so *noticias del jardín* is plain wording to be matched to T1's label.

## et - Estonian

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- et: Kui uudised aiast on sisse lülitatud, küsib rakendus igal käivitumisel veebiaialt sinu jagatud taimede kohta ja saadab selleks sinu kohtumiste juhuslikud arvud. Ta küsib sõltumata sellest, kas oled kedagi kohanud. Iga päring saadab ka ühe juhuslikuna paistva väärtuse ja ühe juhuslikuna paistva vastuse ning päringu vastus toob kummastki tagasi peotäie.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- et: Veebiaed hoiab saadud juhuslikuna paistvaid väärtusi kahes hoidlas, ühes 64-baidiste väärtuste ja teises 104-baidiste väärtuste jaoks. Iga väärtust hoitakse eraldi, ilma aja, aadressi ja järjekorrata. Väärtus jääb alles, kuni uuemad selle välja tõrjuvad. Aia öine varukoopia jätab hoidlad välja. Vastus avaneb ainult telefonis, mis saatis selle seemne. Autonaut-rakenduse seemned liiguvad samamoodi. Veebiaiale on iga väärtus juhuslikud arvud.

- **Terms.** seeme, taim, veebiaed, kohtumine, juhuslikud arvud, bait; pool hoidla; switch uudised aiast.
- **Unsure.** *Autonaut-rakenduse seemned* to avoid declining the name; *peotäis* for *a handful*.

## eu - Basque

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- eu: Lorategiko berriak aktibatuta daudenean, aplikazioak abiatzen den bakoitzean sareko lorategiari galdetzen dio zure landare partekatuei buruz, eta horretarako zure topaketetako ausazko zenbakiak bidaltzen ditu. Galdetzen du, inor topatu duzun ala ez. Eskaera bakoitzak ausazkoa dirudien balio bat eta ausazkoa dirudien erantzun bat ere bidaltzen ditu, eta eskaeraren erantzunak bakoitzetik eskukada bat itzultzen du.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- eu: Sareko lorategiak jasotzen dituen balio ausazkoak diruditenak bi biltegitan gordetzen ditu, bata 64 byteko balioena eta bestea 104 byteko balioena. Balio bakoitza bere aldetik gordetzen da, ordurik, helbiderik eta ordenarik gabe. Balio batek bertan jarraitzen du, berriagoek kanporatu arte. Lorategiaren gaueko babeskopiak biltegiak kanpoan uzten ditu. Erantzun bat bere hazia bidali zuen telefonoan bakarrik irekitzen da. Autonaut-en haziak ere horrela bidaiatzen dute. Sareko lorategiarentzat, balio bakoitza ausazko zenbakiak da.

- **Terms.** hazi, landare, sareko lorategi, topaketa, ausazko zenbakiak, byte; pool biltegi; switch lorategiko berriak.
- **Unsure.** Case endings on *Autonaut-en*; *eskukada* for a handful; the verb agreement of *balio bakoitza ausazko zenbakiak da*. The catalogue's *zu* address is kept.

## fi - Finnish

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- fi: Kun uutiset puutarhasta ovat käytössä, sovellus kysyy verkkopuutarhalta jaetuista kasveistasi joka kerta käynnistyessään ja lähettää sitä varten kohtaamistesi satunnaisluvut. Se kysyy riippumatta siitä, oletko tavannut ketään. Jokainen pyyntö lähettää lisäksi yhden satunnaiselta näyttävän arvon ja yhden satunnaiselta näyttävän vastauksen, ja pyynnön vastaus tuo takaisin kummastakin kourallisen.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- fi: Verkkopuutarha säilyttää vastaanottamansa satunnaiselta näyttävät arvot kahdessa varastossa, joista toisessa on 64 tavun arvot ja toisessa 104 tavun arvot. Kutakin arvoa säilytetään yksin, ilman aikaa, osoitetta tai järjestystä. Arvo pysyy, kunnes uudemmat työntävät sen ulos. Puutarhan yöllinen varmuuskopio jättää varastot pois. Vastaus aukeaa vain puhelimessa, joka lähetti siemenensä. Autonaut-sovelluksen siemenet kulkevat samoin. Verkkopuutarhalle jokainen arvo on satunnaislukuja.

- **Terms.** siemen, kasvi, verkkopuutarha, kohtaaminen, satunnaisluvut, tavu; pool varasto; switch uutiset puutarhasta.
- **Unsure.** *Autonaut-sovelluksen* avoids declining the name; *kourallinen* for a handful.

## fr - French

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- fr: Quand les nouvelles du jardin sont activées, l'application interroge le jardin en ligne sur tes plantes partagées à chaque démarrage, en envoyant les nombres tirés au hasard de tes rencontres. Elle pose la question, que tu aies rencontré quelqu'un ou non. Chaque requête envoie aussi une valeur d'apparence aléatoire et une réponse d'apparence aléatoire, et la réponse à la requête en rapporte une poignée de chaque.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- fr: Le jardin en ligne garde les valeurs d'apparence aléatoire qu'il reçoit dans deux réserves, l'une de valeurs de 64 octets et l'autre de valeurs de 104 octets. Chaque valeur est gardée seule, sans heure, adresse ni ordre. Une valeur reste jusqu'à ce que de plus récentes la repoussent. La sauvegarde de nuit du jardin laisse les réserves de côté. Une réponse ne s'ouvre que sur le téléphone qui a envoyé sa graine. Les graines d'Autonaut voyagent aussi de cette façon. Pour le jardin en ligne, chaque valeur, ce sont des nombres tirés au hasard.

- **Terms.** graine, plante, jardin en ligne, rencontre, nombres tirés au hasard, octet; pool réserve; switch nouvelles du jardin.
- **Unsure.** *Octet* is France's word for byte; *une poignée* for a handful. The app is translated into French but has no label yet for the switch.

## ga - Irish

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- ga: Le nuacht ón ngairdín ar siúl, gach uair a thosaíonn an aip fiafraíonn sí de ghairdín an ghréasáin faoi na plandaí atá roinnte agat, trí na huimhreacha randamacha ó do chastaí a sheoladh. Fiafraíonn sí cibé ar casadh duine ort nó nár casadh. Seolann gach iarratas luach amháin a bhfuil cuma randamach air agus freagra amháin a bhfuil cuma randamach air freisin, agus tugann an freagra ar an iarratas dornán díobh araon ar ais.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- ga: Coinníonn gairdín an ghréasáin na luachanna a bhfuil cuma randamach orthu a fhaigheann sé i dhá linn, ceann de luachanna 64 beart agus ceann de luachanna 104 beart. Coinnítear gach luach ina aonar, gan am, seoladh ná ord. Fanann luach go dtí go ndéanann cinn níos nuaí é a bhrú amach. Fágann cúltaca oíche an ghairdín na linnte ar lár. Ní osclaíonn freagra ach ar an nguthán a sheol a shíol. Taistealaíonn síolta ó Autonaut ar an mbealach seo freisin. Do ghairdín an ghréasáin, is uimhreacha randamacha gach luach.

- **Terms.** síol, planda, gairdín an ghréasáin, casadh, uimhreacha randamacha, beart; pool linn (plural linnte); switch nuacht ón ngairdín.
- **Unsure.** Mutations after *ar an* and *i dhá*, the plural *linnte*, and *beart* for byte. I am not confident of this one.

## gl - Galician

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- gl: Coas novas do xardín activadas, cada vez que a aplicación arranca, pregunta ao xardín da web polas túas plantas compartidas, enviándolle os números aleatorios dos teus encontros. Pregunta tanto se te atopaches con alguén como se non. Cada petición envía ademais un valor de aspecto aleatorio e unha resposta de aspecto aleatorio, e a resposta á petición trae de volta un puñado de cada.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- gl: O xardín da web garda os valores que recibe e que parecen aleatorios en dous depósitos, un de valores de 64 bytes e outro de valores de 104 bytes. Cada valor gárdase só, sen hora, enderezo nin orde. Un valor queda ata que outros máis novos o desprazan. A copia de seguranza nocturna do xardín deixa fóra os depósitos. Unha resposta só se abre no teléfono que enviou a súa semente. As sementes de Autonaut viaxan tamén así. Para o xardín da web, cada valor son números aleatorios.

- **Terms.** semente, planta, xardín da web, encontro, números aleatorios, byte; pool depósito; switch novas do xardín.
- **Unsure.** *Un puñado* for a handful. The catalogue's old *pregúntalle* with an enclitic was replaced by *pregunta ao xardín*.

## he - Hebrew

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- he: כשחדשות מהגן דלוקות, בכל פעם שהאפליקציה עולה היא שואלת את גן הרשת על הצמחים שאתה חולק, בכך שהיא שולחת את המספרים המקריים מהמפגשים שלך. היא שואלת בין שפגשת מישהו ובין שלא. כל בקשה שולחת גם ערך אחד שנראה מקרי ותשובה אחת שנראית מקרית, והתשובה לבקשה מחזירה חופן מכל אחד מהם.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- he: גן הרשת שומר את הערכים שנראים מקריים שהוא מקבל בשני מאגרים, אחד של ערכים בני 64 בייט ואחד של ערכים בני 104 בייט. כל ערך נשמר לבדו, בלי זמן, כתובת או סדר. ערך נשאר עד שחדשים יותר דוחקים אותו החוצה. הגיבוי הלילי של הגן משאיר את המאגרים בחוץ. תשובה נפתחת רק בטלפון ששלח את הזרע שלה. זרעים מ-Autonaut עוברים גם הם בדרך הזאת. מבחינת גן הרשת, כל ערך הוא מספרים מקריים.

- **Terms.** זרע, צמח, גן הרשת, מפגש, מספרים מקריים, בייט; pool מאגר; switch חדשות מהגן.
- **Unsure.** Masculine address kept as in the catalogue (*שאתה חולק*); *חופן* for a handful; the Latin *Autonaut* after the prefix *מ-*; right-to-left mixing should be seen in a browser.

## hr - Croatian

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- hr: Ako su vijesti iz vrta uključene, aplikacija pri svakom pokretanju pita mrežni vrt o tvojim dijeljenim biljkama, tako da pošalje slučajne brojeve iz tvojih susreta. Pita bez obzira na to je li bilo ikakvog susreta. Svaki zahtjev šalje i jednu vrijednost koja izgleda slučajno i jedan odgovor koji izgleda slučajno, a odgovor na zahtjev vraća šaku jednih i drugih.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- hr: Mrežni vrt čuva vrijednosti koje primi i koje izgledaju slučajno u dva spremnika, jednom za vrijednosti od 64 bajta i jednom za vrijednosti od 104 bajta. Svaka se vrijednost čuva sama, bez vremena, adrese i redoslijeda. Vrijednost ostaje dok je ne istisnu novije. Noćna sigurnosna kopija vrta izostavlja spremnike. Odgovor se otvara samo na telefonu koji je poslao svoje sjeme. Sjemena iz aplikacije Autonaut putuju na isti način. Za mrežni vrt svaka je vrijednost slučajni brojevi.

- **Terms.** sjeme, biljka, mrežni vrt, susret, slučajni brojevi, bajt; pool spremnik; switch vijesti iz vrta.
- **Unsure.** *Je li bilo ikakvog susreta* keeps the sentence gender-neutral. *Šaka jednih i drugih* for a handful.

## hu - Hungarian

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- hu: Ha a hírek a kertből be vannak kapcsolva, az alkalmazás minden induláskor megkérdezi a webes kertet a megosztott növényeidről, és ehhez elküldi a találkozásaid véletlen számait. Megkérdezi akkor is, ha találkoztál valakivel, és akkor is, ha nem. Minden kérés elküld egy véletlennek tűnő értéket és egy véletlennek tűnő választ is, és a kérésre adott válasz mindkettőből egy maréknyit hoz vissza.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- hu: A webes kert a kapott, véletlennek tűnő értékeket két tárolóban őrzi, az egyikben 64 bájtos, a másikban 104 bájtos értékek vannak. Mindegyik érték külön van tárolva, idő, cím és sorrend nélkül. Egy érték addig marad, amíg újabbak ki nem szorítják. A kert éjszakai mentése kihagyja a tárolókat. Egy válasz csak azon a telefonon nyílik meg, amelyik elküldte a hozzá tartozó magot. Az Autonaut magjai is így utaznak. A webes kertnek minden érték véletlen számok.

- **Terms.** mag, növény, webes kert, találkozás, véletlen számok, bájt; pool tároló; switch hírek a kertből.
- **Unsure.** *Akkor is … és akkor is, ha nem* for *whether or not*; *maréknyi* for a handful.

## is - Icelandic

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- is: Þegar fréttir úr garðinum eru á, spyr appið vefgarðinn um plönturnar sem þú deilir í hvert skipti sem appið er opnað, með því að senda tölurnar af handahófi frá fundunum þínum. Það spyr hvort sem þú hefur hitt einhvern eða ekki. Hver beiðni sendir einnig eitt gildi sem lítur út fyrir að vera af handahófi og eitt svar sem lítur út fyrir að vera af handahófi, og svarið við beiðninni kemur með handfylli af hvoru til baka.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- is: Vefgarðurinn geymir gildin sem hann fær og líta út fyrir að vera af handahófi í tveimur geymslum, einni með 64 bæta gildum og einni með 104 bæta gildum. Hvert gildi er geymt eitt og sér, án tíma, heimilisfangs eða raðar. Gildi helst þar til nýrri ýta því út. Næturafrit garðsins skilur geymslurnar útundan. Svar opnast aðeins í símanum sem sendi fræið sitt. Fræ frá Autonaut ferðast líka þannig. Fyrir vefgarðinum er hvert gildi tölur af handahófi.

- **Terms.** fræ, planta, vefgarður, fundur, tölur af handahófi, bæti (gen. pl. bæta); pool geymsla; switch fréttir úr garðinum.
- **Unsure.** Case and number agreement throughout, *hvort sem … eða ekki*, and *handfylli*. I am not confident of this one.

## it - Italian

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- it: Quando le novità dal giardino sono attive, l'app chiede al giardino sul web delle tue piante condivise ogni volta che parte, inviando i numeri casuali dei tuoi incontri. Lo chiede che tu abbia incontrato qualcuno o no. Ogni richiesta invia anche un valore dall'aspetto casuale e una risposta dall'aspetto casuale, e la risposta alla richiesta ne riporta una manciata di ciascuno.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- it: Il giardino sul web conserva i valori dall'aspetto casuale che riceve in due depositi, uno di valori da 64 byte e uno di valori da 104 byte. Ogni valore è conservato da solo, senza ora, indirizzo né ordine. Un valore resta finché altri più recenti non lo spingono fuori. Il backup notturno del giardino lascia fuori i depositi. Una risposta si apre solo sul telefono che ha inviato il suo seme. I semi di Autonaut viaggiano anch'essi così. Per il giardino sul web, ogni valore è numeri casuali.

- **Terms.** seme, pianta, giardino sul web, incontro, numeri casuali, byte; pool deposito; switch novità dal giardino.
- **Unsure.** *Una manciata* for a handful. The app is translated into Italian but has no label yet for the switch.

## ja - Japanese

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- ja: 庭からの便りをオンにしていると、アプリは起動するたびに、分かち合っている植物についてウェブの庭に問い合わせます。問い合わせるときは、あなたの出会いの乱数を送ります。出会いがあったかどうかにかかわらず、問い合わせます。リクエストのたびに、無作為に見える値と無作為に見える返信を一つずつ送り、その応答にはどちらもひとつかみずつ含まれて戻ってきます。

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- ja: ウェブの庭は、受け取った無作為に見える値を二つの置き場に保管します。一つは64バイトの値の置き場、もう一つは104バイトの値の置き場です。それぞれの値は単独で保管され、時刻もアドレスも順序もありません。値は、新しい値に押し出されるまで残ります。庭の夜間バックアップは、二つの置き場を含みません。返信は、その種を送った電話でだけ開きます。Autonautからの種も、同じように届きます。ウェブの庭にとっては、どの値も乱数です。

- **Terms.** 種, 植物, ウェブの庭, 出会い, 乱数, バイト; pool 置き場 (プール reads as water); switch 庭からの便り; the catalogue's polite です/ます register with あなた.
- **Unsure.** *ひとつかみ* for a handful; *リクエスト* and *返信* are kept apart as request and reply; the written 二つ for *two pools*. I have not rendered a plural for the reply.

## ko - Korean

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- ko: 정원 소식을 켜 두면, 앱은 시작할 때마다 함께 나눈 식물에 대해 웹 정원에 물어봅니다. 물어볼 때는 당신의 만남들에서 나온 무작위 숫자를 보냅니다. 만난 사람이 있든 없든 물어봅니다. 요청마다 무작위처럼 보이는 값 하나와 무작위처럼 보이는 답 하나도 함께 보내고, 요청에 대한 응답은 그 각각을 한 줌씩 가져옵니다.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- ko: 웹 정원은 받은, 무작위처럼 보이는 값을 두 저장소에 보관합니다. 하나는 64바이트 값의 저장소이고, 다른 하나는 104바이트 값의 저장소입니다. 각 값은 시각, 주소, 순서 없이 따로 보관됩니다. 값은 더 새로운 값이 밀어낼 때까지 남아 있습니다. 정원의 야간 백업은 저장소를 제외합니다. 답은 그 씨앗을 보낸 전화에서만 열립니다. Autonaut에서 온 씨앗도 이렇게 전해집니다. 웹 정원에게 모든 값은 무작위 숫자입니다.

- **Terms.** 씨앗, 식물, 웹 정원, 만남, 무작위 숫자, 바이트; pool 저장소; switch 정원 소식.
- **Unsure.** *한 줌* for a handful; the catalogue's 당신 and polite register kept.

## lt - Lithuanian

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- lt: Kai naujienos iš sodo įjungtos, programėlė kiekvieno paleidimo metu paklausia interneto sodo apie augalus, kuriais pasidalijai, ir tam nusiunčia tavo susitikimų atsitiktinius skaičius. Ji klausia nesvarbu, ar buvo bent vienas susitikimas. Kiekviena užklausa nusiunčia ir vieną atsitiktinai atrodančią reikšmę, ir vieną atsitiktinai atrodantį atsakymą, o užklausos atsakymas grąžina saują kiekvieno.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- lt: Interneto sodas laiko gaunamas atsitiktinai atrodančias reikšmes dviejose saugyklose: vienoje 64 baitų reikšmės, kitoje 104 baitų reikšmės. Kiekviena reikšmė laikoma atskirai, be laiko, adreso ir eilės tvarkos. Reikšmė išlieka, kol ją išstumia naujesnės. Sodo naktinė atsarginė kopija saugyklų neapima. Atsakymas atsidaro tik telefone, kuris išsiuntė savo sėklą. Sėklos iš Autonaut keliauja taip pat. Interneto sodui kiekviena reikšmė yra atsitiktiniai skaičiai.

- **Terms.** sėkla, augalas, interneto sodas, susitikimas, atsitiktiniai skaičiai, baitas; pool saugykla; switch naujienos iš sodo.
- **Unsure.** *Neapima* (does not cover) for *leaves out*; *saują* for a handful. The gender-neutral *ar buvo bent vienas susitikimas*.

## lv - Latvian

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- lv: Ja ziņas no dārza ir ieslēgtas, lietotne katrā palaišanas reizē pajautā tīmekļa dārzam par augiem, ar kuriem esat dalījušies, un tam nosūta tavu satikšanos nejaušos skaitļus. Tā jautā neatkarīgi no tā, vai ir bijusi kāda satikšanās. Katrs pieprasījums nosūta arī vienu nejauši izskatāmu vērtību un vienu nejauši izskatāmu atbildi, un pieprasījuma atbilde atnes atpakaļ pa saujai no katra.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- lv: Tīmekļa dārzs saņemtās nejauši izskatāmās vērtības glabā divās krātuvēs, vienā ir 64 baitu vērtības, otrā 104 baitu vērtības. Katra vērtība tiek glabāta atsevišķi, bez laika, adreses un secības. Vērtība paliek, līdz to izspiež jaunākās. Dārza nakts rezerves kopija krātuves atstāj ārpus sevis. Atbilde atveras tikai tālrunī, kas nosūtīja savu sēklu. Sēklas no Autonaut ceļo tāpat. Tīmekļa dārzam katra vērtība ir nejauši skaitļi.

- **Terms.** sēkla, augs, tīmekļa dārzs, satikšanās, nejaušie skaitļi, baits; pool krātuve; switch ziņas no dārza.
- **Unsure.** The catalogue's own *augiem, ar kuriem esat dalījušies* is kept, though it mixes plural and singular address as the old string did. *Pa saujai* for a handful.

## mk - Macedonian

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- mk: Ако вестите од градината се вклучени, при секое стартување апликацијата ја прашува веб градината за твоите поделени растенија, притоа испраќајќи ги случајните броеви од твоите средби. Прашува без разлика дали имало каква било средба. Секое барање испраќа и една вредност што изгледа случајно и еден одговор што изгледа случајно, а одговорот на барањето враќа шака од секое.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- mk: Веб градината ги чува добиените вредности што изгледаат случајно во две складишта, едното за вредности од 64 бајти, другото за вредности од 104 бајти. Секоја вредност се чува сама, без време, адреса и редослед. Вредноста останува додека не ја истиснат понови. Ноќниот бекап на градината ги остава складиштата надвор. Одговорот се отвора само на телефонот што го испрати своето семе. Семиња од Autonaut патуваат на истиот начин. За веб градината секоја вредност е случајни броеви.

- **Terms.** семе, растение, веб градина, средба, случајни броеви, бајт; pool складиште; switch вести од градината.
- **Unsure.** *Шака* for a handful; *бекап* for backup, as an ordinary loan.

## mt - Maltese

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- mt: Bl-aħbarijiet mill-ġnien mixgħula, kull darba li l-app tinfetaħ, tistaqsi lill-ġnien tal-web dwar il-pjanti li qsamt, billi tibgħat in-numri bl-addoċċ mill-laqgħat tiegħek. Tistaqsi kemm jekk kien hemm laqgħa kif ukoll jekk le. Kull talba tibgħat ukoll valur wieħed li jidher bl-addoċċ u tweġiba waħda li tidher bl-addoċċ, u r-risposta għat-talba terġa' ġġib qabda minn kull waħda.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- mt: Il-ġnien tal-web iżomm il-valuri li jidhru bl-addoċċ li jirċievi f'żewġ ġabriet, waħda ta' valuri ta' 64 byte u oħra ta' valuri ta' 104 byte. Kull valur jinżamm waħdu, mingħajr ħin, indirizz jew ordni. Valur jibqa' sakemm jagħfsuh 'il barra valuri aktar ġodda. Il-backup ta' kull lejl tal-ġnien iħalli l-ġabriet barra. Tweġiba tinfetaħ biss fuq it-telefon li bagħat iż-żerriegħa tagħha. Iż-żrieragħ minn Autonaut jivvjaġġaw b'dan il-mod ukoll. Għall-ġnien tal-web, kull valur huwa numri bl-addoċċ.

- **Terms.** żerriegħa (pl. żrieragħ), pjanta, ġnien tal-web, laqgħa, numri bl-addoċċ, byte; pool ġabra; switch aħbarijiet mill-ġnien.
- **Unsure.** *Qabda* for a handful; *jagħfsuh 'il barra* for pushing out; *backup* kept as a loan. I am not confident of this one.

## nb - Norwegian Bokmål

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- nb: Når nytt fra hagen er slått på, spør appen hagen på nettet om de delte plantene dine hver gang den starter, ved å sende de tilfeldige tallene fra møtene dine. Den spør enten du har møtt noen eller ikke. Hver forespørsel sender også én verdi som ser tilfeldig ut og ett svar som ser tilfeldig ut, og svaret på forespørselen bringer med seg en håndfull av hver.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- nb: Hagen på nettet beholder verdiene som ser tilfeldige ut og som den mottar, i to lagre, ett med verdier på 64 byte og ett med verdier på 104 byte. Hver verdi lagres alene, uten tid, adresse eller rekkefølge. En verdi blir liggende til nyere verdier skyver den ut. Hagens nattlige sikkerhetskopi holder lagrene utenfor. Et svar åpnes bare på telefonen som sendte frøet sitt. Frø fra Autonaut reiser på samme måte. For hagen på nettet er hver verdi tilfeldige tall.

- **Terms.** frø, plante, hagen på nettet, møte, tilfeldige tall, byte; pool lager; switch nytt fra hagen.
- **Unsure.** The app is translated into Bokmål but has no label yet for the switch.

## nl - Dutch

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- nl: Als nieuws uit de tuin aan staat, vraagt de app bij iedere start aan de tuin op het web naar je gedeelde planten, door de willekeurige getallen van je ontmoetingen te versturen. Ze vraagt het of je nu iemand hebt ontmoet of niet. Elk verzoek stuurt ook één willekeurig ogende waarde en één willekeurig ogend antwoord mee, en het antwoord op het verzoek brengt van elk een handvol terug.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- nl: De tuin op het web bewaart de willekeurig ogende waarden die hij ontvangt in twee bakken, één met waarden van 64 byte en één met waarden van 104 byte. Elke waarde wordt los bewaard, zonder tijd, adres of volgorde. Een waarde blijft staan tot nieuwere haar wegduwen. De nachtelijke back-up van de tuin laat de bakken buiten beschouwing. Een antwoord opent alleen op de telefoon die zijn zaadje heeft gestuurd. Zaadjes van Autonaut reizen ook zo. Voor de tuin op het web is elke waarde willekeurige getallen.

- **Terms.** zaadje, plant, tuin op het web, ontmoeting, willekeurige getallen, byte; pool bak; switch nieuws uit de tuin.
- **Unsure.** *Bak* for a pool; *een handvol*. The app is translated into Dutch but has no label yet for the switch.

## pl - Polish

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- pl: Gdy wieści z ogrodu są włączone, aplikacja przy każdym uruchomieniu pyta ogród na stronie o twoje wspólne rośliny, wysyłając liczby losowe z twoich spotkań. Pyta niezależnie od tego, czy było jakiekolwiek spotkanie. Każde zapytanie wysyła też jedną wartość, która wygląda na losową, i jedną odpowiedź, która wygląda na losową, a odpowiedź na zapytanie przynosi garść każdej z nich.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- pl: Ogród na stronie przechowuje otrzymane wartości, które wyglądają na losowe, w dwóch zbiornikach, jednym na wartości 64-bajtowe i jednym na wartości 104-bajtowe. Każda wartość jest przechowywana osobno, bez czasu, adresu i kolejności. Wartość zostaje, aż wypchną ją nowsze. Nocna kopia zapasowa ogrodu pomija zbiorniki. Odpowiedź otwiera się tylko na telefonie, który wysłał swoje nasionko. Nasiona z aplikacji Autonaut podróżują w ten sam sposób. Dla ogrodu na stronie każda wartość to liczby losowe.

- **Terms.** nasionko / nasiona, roślina, ogród na stronie, spotkanie, liczby losowe, bajt; pool zbiornik; switch wieści z ogrodu.
- **Unsure.** *Aplikacja Autonaut* avoids declining the name; *64-bajtowe* as an adjective; *garść* for a handful.

## pt - Portuguese

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- pt: Com as novidades do jardim ligadas, cada vez que a aplicação arranca pergunta ao jardim da web pelas tuas plantas partilhadas, enviando os números aleatórios dos teus encontros. Pergunta tanto se encontraste alguém como se não. Cada pedido envia também um valor de aspeto aleatório e uma resposta de aspeto aleatório, e a resposta ao pedido traz de volta um punhado de cada.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- pt: O jardim da web guarda os valores de aspeto aleatório que recebe em dois depósitos, um de valores de 64 bytes e outro de valores de 104 bytes. Cada valor é guardado sozinho, sem hora, endereço nem ordem. Um valor fica até outros mais recentes o empurrarem para fora. A cópia de segurança noturna do jardim deixa os depósitos de fora. Uma resposta só abre no telefone que enviou a sua semente. As sementes do Autonaut viajam também assim. Para o jardim da web, cada valor são números aleatórios.

- **Terms.** semente, planta, jardim da web, encontro, números aleatórios, byte; pool depósito; switch novidades do jardim.
- **Unsure.** European Portuguese (*aspeto*, *partilhadas*) as the catalogue has it; *um punhado* for a handful.

## ro - Romanian

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- ro: Cu veștile din grădină pornite, aplicația întreabă grădina web, la fiecare pornire, despre plantele pe care le ai în comun, trimițând numerele aleatoare din întâlnirile tale. Întreabă fie că ai întâlnit pe cineva, fie că nu. Fiecare cerere trimite și o valoare cu aspect aleator și un răspuns cu aspect aleator, iar răspunsul la cerere aduce înapoi o mână din fiecare.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- ro: Grădina web păstrează valorile cu aspect aleator pe care le primește în două depozite, unul cu valori de 64 de octeți și unul cu valori de 104 octeți. Fiecare valoare e păstrată singură, fără oră, adresă sau ordine. O valoare rămâne până când valori mai noi o împing afară. Copia de siguranță de noapte a grădinii lasă depozitele deoparte. Un răspuns se deschide doar pe telefonul care și-a trimis sămânța. Semințele de la Autonaut călătoresc și ele așa. Pentru grădina web, fiecare valoare e numere aleatoare.

- **Terms.** sămânță (pl. semințe), plantă, grădină web, întâlnire, numere aleatoare, octet; pool depozit; switch veștile din grădină.
- **Unsure.** *64 de octeți* and *104 octeți* by the numeral rule; *o mână* for a handful.

## ru - Russian

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- ru: Если новости из сада включены, приложение при каждом запуске спрашивает у сада на сайте о твоих общих растениях, отправляя случайные числа из твоих встреч. Оно спрашивает независимо от того, была ли хоть одна встреча. Каждый запрос отправляет также одно значение, которое выглядит случайным, и один ответ, который выглядит случайным, а ответ на запрос приносит обратно горсть тех и других.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- ru: Сад на сайте хранит получаемые значения, которые выглядят случайными, в двух хранилищах: в одном значения по 64 байта, в другом по 104 байта. Каждое значение хранится отдельно, без времени, адреса и порядка. Значение остаётся, пока его не вытеснят более новые. Ночная резервная копия сада оставляет хранилища за своими пределами. Ответ открывается только на телефоне, который отправил своё семя. Семена из Autonaut путешествуют так же. Для сада на сайте каждое значение — случайные числа.

- **Terms.** семя, растение, сад на сайте, встреча, случайные числа, байт; pool хранилище; switch новости из сада.
- **Unsure.** *Горсть* for a handful; *оставляет хранилища за своими пределами* for *leaves out*.

## sk - Slovak

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- sk: Keď sú správy zo záhrady zapnuté, aplikácia sa pri každom spustení spýta záhrady na webe na tvoje spoločné rastliny, a to tak, že pošle náhodné čísla z tvojich stretnutí. Pýta sa bez ohľadu na to, či nejaké stretnutie bolo. Každá žiadosť posiela aj jednu hodnotu, ktorá vyzerá náhodne, a jednu odpoveď, ktorá vyzerá náhodne, a odpoveď na žiadosť prináša späť hrsť z každej.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- sk: Záhrada na webe uchováva prijaté hodnoty, ktoré vyzerajú náhodne, v dvoch zásobníkoch, jednom na hodnoty s veľkosťou 64 bajtov a jednom na hodnoty s veľkosťou 104 bajtov. Každá hodnota sa uchováva samostatne, bez času, adresy a poradia. Hodnota zostáva, kým ju nevytlačia novšie. Nočná záloha záhrady zásobníky vynecháva. Odpoveď sa otvorí len na telefóne, ktorý poslal svoje semienko. Semienka z aplikácie Autonaut putujú rovnako. Pre záhradu na webe je každá hodnota náhodné čísla.

- **Terms.** semienko, rastlina, záhrada na webe, stretnutie, náhodné čísla, bajt; pool zásobník; switch správy zo záhrady.
- **Unsure.** *Hodnoty s veľkosťou 64 bajtov* for the sizes; *hrsť* for a handful; *aplikácia Autonaut* to avoid declining the name.

## sl - Slovenian

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- sl: Če so novice iz vrta vklopljene, aplikacija ob vsakem zagonu vpraša spletni vrt o tvojih deljenih rastlinah, tako da pošlje naključna števila iz tvojih srečanj. Vpraša ne glede na to, ali je bilo kakšno srečanje. Vsaka zahteva pošlje tudi eno vrednost, ki je videti naključna, in en odgovor, ki je videti naključen, odgovor na zahtevo pa prinese nazaj peščico obojega.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- sl: Spletni vrt hrani prejete vrednosti, ki so videti naključne, v dveh shrambah, v eni so vrednosti po 64 bajtov, v drugi vrednosti po 104 bajtov. Vsaka vrednost se hrani sama, brez časa, naslova in vrstnega reda. Vrednost ostane, dokler je ne izpodrinejo novejše. Nočna varnostna kopija vrta obe shrambi izpusti. Odgovor se odpre samo na telefonu, ki je poslal svoje seme. Semena iz aplikacije Autonaut potujejo enako. Za spletni vrt je vsaka vrednost naključna števila.

- **Terms.** seme, rastlina, spletni vrt, srečanje, naključna števila, bajt; pool shramba (dual shrambi); switch novice iz vrta.
- **Unsure.** The dual (*obe shrambi izpusti*); *po 64 bajtov* for the sizes; *peščica* for a handful.

## sq - Albanian

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- sq: Me lajmet nga kopshti aktive, sa herë që aplikacioni niset, ai pyet kopshtin në web për bimët e tua të ndara, duke dërguar numrat e rastit nga takimet e tua. Ai pyet qoftë se ke takuar dikë, qoftë se jo. Çdo kërkesë dërgon edhe një vlerë që duket e rastit dhe një përgjigje që duket e rastit, dhe përgjigjja ndaj kërkesës sjell mbrapsht një grusht nga secila.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- sq: Kopshti në web i mban vlerat që duken të rastit dhe që merr në dy depo, njërën me vlera 64-bajtëshe dhe tjetrën me vlera 104-bajtëshe. Çdo vlerë mbahet më vete, pa kohë, adresë ose renditje. Një vlerë qëndron derisa ta shtyjnë jashtë të tjera më të reja. Kopja rezervë e natës e kopshtit i lë depot jashtë. Një përgjigje hapet vetëm në telefonin që dërgoi farën e vet. Farat nga Autonaut udhëtojnë po kështu. Për kopshtin në web, çdo vlerë është numra të rastit.

- **Terms.** farë, bimë, kopsht në web, takim, numra të rastit, bajt; pool depo; switch lajme nga kopshti.
- **Unsure.** *64-bajtëshe* as an adjective; *grusht* for a handful. I am not confident of this one.

## sr - Serbian

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- sr: Ако су вести из баште укључене, апликација при сваком покретању пита веб-башту о твојим дељеним биљкама, тако што пошаље случајне бројеве из твојих сусрета. Пита без обзира на то да ли је било икаквог сусрета. Сваки захтев шаље и једну вредност која изгледа случајно и један одговор који изгледа случајно, а одговор на захтев враћа шаку једних и других.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- sr: Веб-башта чува примљене вредности које изгледају случајно у два спремника, једном за вредности од 64 бајта и једном за вредности од 104 бајта. Свака вредност се чува сама, без времена, адресе и редоследа. Вредност остаје док је не истисну новије. Ноћна резервна копија баште изоставља спремнике. Одговор се отвара само на телефону који је послао своје семе. Семена из апликације Autonaut путују на исти начин. За веб-башту свака вредност су случајни бројеви.

- **Terms.** Cyrillic as the catalogue has it: семе, биљка, веб-башта, сусрет, случајни бројеви, бајт; pool спремник; switch вести из баште.
- **Unsure.** *Шака* for a handful; the catalogue's ekavian forms.

## sv - Swedish

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- sv: När nytt från trädgården är på, frågar appen trädgården på webben om dina delade växter varje gång den startar, genom att skicka slumptalen från dina möten. Den frågar oavsett om du har mött någon eller inte. Varje förfrågan skickar också ett värde som ser slumpmässigt ut och ett svar som ser slumpmässigt ut, och svaret på förfrågan för med sig en handfull av vardera tillbaka.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- sv: Trädgården på webben behåller de värden som ser slumpmässiga ut och som den tar emot i två förråd, ett med värden på 64 byte och ett med värden på 104 byte. Varje värde sparas för sig, utan tid, adress eller ordning. Ett värde blir kvar tills nyare värden trycker ut det. Trädgårdens nattliga säkerhetskopia lämnar förråden utanför. Ett svar öppnas bara på telefonen som skickade sitt frö. Frön från Autonaut reser på samma sätt. För trädgården på webben är varje värde slumptal.

- **Terms.** frö (pl. frön), växt, trädgården på webben, möte, slumptal, byte; pool förråd; switch nytt från trädgården.
- **Unsure.** *En handfull*. The app is translated into Swedish but has no label yet for the switch.

## tr - Turkish

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- tr: Bahçeden haberler açıkken, uygulama her başladığında paylaştığın bitkileri web bahçesine sorar; bunu karşılaşmalarından gelen rastgele sayıları göndererek yapar. Biriyle karşılaşmış olsan da olmasan da sorar. Her istek ayrıca rastgele görünen bir değer ve rastgele görünen bir yanıt gönderir, isteğin yanıtı ise her birinden bir avuç geri getirir.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- tr: Web bahçesi aldığı rastgele görünen değerleri iki depoda tutar: birinde 64 baytlık değerler, ötekinde 104 baytlık değerler vardır. Her değer zaman, adres ve sıra olmadan tek başına tutulur. Bir değer, daha yeniler onu dışarı itene kadar durur. Bahçenin gecelik yedeği depoları dışarıda bırakır. Bir yanıt yalnızca tohumunu gönderen telefonda açılır. Autonaut'tan gelen tohumlar da böyle yolculuk eder. Web bahçesi için her değer rastgele sayılardır.

- **Terms.** tohum, bitki, web bahçesi, karşılaşma, rastgele sayılar, bayt; pool depo; switch bahçeden haberler.
- **Unsure.** *Bir avuç* for a handful; *Autonaut'tan* with the apostrophe suffix.

## uk - Ukrainian

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- uk: Якщо новини з саду увімкнені, застосунок при кожному запуску запитує сад на сайті про твої спільні рослини, надсилаючи випадкові числа з твоїх зустрічей. Він запитує незалежно від того, чи була хоч одна зустріч. Кожен запит надсилає також одне значення, що виглядає випадковим, і одну відповідь, що виглядає випадковою, а відповідь на запит приносить назад жменю кожного.

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- uk: Сад на сайті зберігає отримані значення, що виглядають випадковими, у двох сховищах: в одному значення по 64 байти, в іншому по 104 байти. Кожне значення зберігається окремо, без часу, адреси й порядку. Значення лишається, доки його не витіснять новіші. Нічна резервна копія саду сховища залишає поза собою. Відповідь відкривається лише на телефоні, який надіслав свою насінину. Насінини з Autonaut подорожують так само. Для саду на сайті кожне значення — випадкові числа.

- **Terms.** насінина, рослина, сад на сайті, зустріч, випадкові числа, байт; pool сховище; switch новини з саду.
- **Unsure.** *Жменя* for a handful.

## zh - Chinese (Simplified)

**privacy7**

- en: With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.
- zh: 打开花园消息后，应用每次启动时都会向网上花园询问你分享的那些植物，询问的办法是把你各次相遇的随机数发过去。无论你有没有遇见过谁，它都会询问。每次请求还会发出一个看起来随机的值和一个看起来随机的回复，请求的答复会带回两者各一小把。

**privacy11**

- en: The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.
- zh: 网上花园把收到的看起来随机的值存放在两个存储池里，一个存放64字节的值，一个存放104字节的值。每个值单独保存，没有时间、地址和顺序。值会一直留着，直到更新的值把它挤出去。花园的夜间备份不包含这两个存储池。回复只能在发出该种子的那部手机上打开。来自 Autonaut 的种子也走这条路。对网上花园来说，每个值都是随机数。

- **Terms.** 种子, 植物, 网上花园, 相遇, 随机数, 字节; pool 存储池; switch 花园消息.
- **Unsure.** *一小把* for a handful; the catalogue's 提醒 is replaced by 花园消息. I used the numerals 64 and 104 and left no space before 字节, as Chinese does.
