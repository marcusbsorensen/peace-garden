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
