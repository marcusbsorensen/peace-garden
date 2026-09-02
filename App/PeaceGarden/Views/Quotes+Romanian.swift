import Foundation

/// The Romanian passages.
///
/// Written rather than translated: about sixty of the English passages
/// are etymologies of English words and are simply false in any other
/// language, so this bank comes from its own word histories, its own
/// literature and its own proverbs.
///
/// A Latin core with Slavic, Turkish, Hungarian and Greek laid over it, and the seam is where the bank lives: suta is Slavic beside mie from Latin, da from one side and nu from the other. liniste is built on lin, from lenis, so Romanian names quiet after gentleness rather than after absence.
extension Quotes {
    static let romanian: [Passage] = [
        // MARK: - Beginnings

        // MARK: The first act
        Passage( text: "Cine se scoală de dimineață, departe ajunge.", source: "proverb românesc", theme: .beginnings, subtheme: .theFirstAct ),
        Passage( text: "Scrieți, băieți, numai scrieți.", source: "Ion Heliade Rădulescu", theme: .beginnings, subtheme: .theFirstAct ),
        Passage( text: "A fost odată ca-n povești, / A fost ca niciodată.", source: "Mihai Eminescu, Luceafărul", theme: .beginnings, subtheme: .theFirstAct ),
        Passage( text: "A începe vine din latinescul incipere, adică in și capere, a lua: începutul este, la propriu, un lucru luat în mână.", source: "latină", theme: .beginnings, subtheme: .theFirstAct ),
        Passage( text: "Grâul care iese din bob se cheamă colț, iar verbul e a încolți: sămânța nu răsare mai devreme, ci face un dinte.", source: "limba română", theme: .beginnings, subtheme: .theFirstAct ),
        Passage( text: "De Anul Nou, copiii umblă cu plugușorul și trag o brazdă închipuită prin curte. Lucrul câmpului începe prin a fi jucat.", source: "obicei românesc", theme: .beginnings, subtheme: .theFirstAct ),
        Passage( text: "Ghiocelul nu topește zăpada, o străpunge: vârful frunzelor lui e îngroșat anume, ca să împingă prin pământ înghețat.", source: "Galanthus nivalis", theme: .beginnings, subtheme: .theFirstAct ),
        Passage( text: "Românește nu începi o treabă, te apuci de ea. Cine se apucă pune mâna pe lucru înainte să-l facă.", source: "limba română", theme: .beginnings, subtheme: .theFirstAct ),
        Passage( text: "Mugurul de pe viță se numește ochi, iar tăierea de primăvară se socotește în ochi: via pornește anul cu câți ochi i-au fost lăsați.", source: "viticultură", theme: .beginnings, subtheme: .theFirstAct ),
        Passage( text: "Puiul de barză își sparge oul cu un dinte crescut anume pe cioc, care cade la câteva zile după ce nu mai are ce face cu el.", source: "Ciconia ciconia", theme: .beginnings, subtheme: .theFirstAct ),
        Passage( text: "Prin decembrie se pune grâu la încolțit într-o farfurie, la căldură. Cât de des răsare, atât de bun se așteaptă să fie anul.", source: "obicei românesc", theme: .beginnings, subtheme: .theFirstAct ),
        Passage( text: "Primele cărți tipărite în limba română au ieșit de sub teascul diaconului Coresi, la Brașov, în a doua jumătate a veacului al XVI-lea.", source: "tipografia lui Coresi", theme: .beginnings, subtheme: .theFirstAct ),

        // MARK: Small to large
        Passage( text: "Buturuga mică răstoarnă carul mare.", source: "proverb românesc", theme: .beginnings, subtheme: .smallToLarge ),
        Passage( text: "Dramul a fost o măsură adevărată, cam trei grame. A rămas doar în ce se cere cel mai des: un dram de noroc.", source: "măsuri vechi românești", theme: .beginnings, subtheme: .smallToLarge ),
        Passage( text: "Româna micșorează de două ori la rând: codru, codruț, codruțule. Nimic nu e atât de mic încât să nu mai poată fi micșorat.", source: "limba română", theme: .beginnings, subtheme: .smallToLarge ),
        Passage( text: "Pentru puțin, aici se spune oleacă, nițel, un pic, un strop și o țâră. Cinci cuvinte pentru aceeași cantitate neînsemnată.", source: "limba română", theme: .beginnings, subtheme: .smallToLarge ),
        Passage( text: "Delta Dunării înaintează în mare cu câțiva zeci de metri pe an, din mâlul adus de la mii de kilometri. E cel mai tânăr pământ din țară.", source: "geografie", theme: .beginnings, subtheme: .smallToLarge ),
        Passage( text: "Un pumn de mălai umflă un ceaun întreg de mămăligă. Boabele măcinate sug apa până cresc de vreo trei ori.", source: "bucătărie țărănească", theme: .beginnings, subtheme: .smallToLarge ),
        Passage( text: "Maiaua e o lingură de aluat vechi pusă deoparte, care dospește toată covata următoare. Pâinea de azi ține minte pâinea de acum o săptămână.", source: "brutărie", theme: .beginnings, subtheme: .smallToLarge ),
        Passage( text: "Un pui de somn nu e somnul vreunui pui: românește, pui înseamnă și cea mai mică porție din orice lucru.", source: "limba română", theme: .beginnings, subtheme: .smallToLarge ),
        Passage( text: "O singură căpățână de mac poartă vreo trei mii de semințe, fiecare cât un fir de praf, și le scutură singură prin niște ferestruici de sus.", source: "Papaver rhoeas", theme: .beginnings, subtheme: .smallToLarge ),
        Passage( text: "Cuibul de barză de pe stâlp se drege în fiecare primăvară cu câteva crengi noi. După douăzeci de ani ajunge să cântărească peste o sută de kilograme.", source: "Ciconia ciconia", theme: .beginnings, subtheme: .smallToLarge ),
        Passage( text: "Muntele de sare de la Slănic este o mare veche, uscată bob cu bob acum câteva milioane de ani și îngropată de atunci.", source: "geologie", theme: .beginnings, subtheme: .smallToLarge ),
        Passage( text: "Pentru un kilogram de miere, albinele umblă la câteva milioane de flori. România e printre cele mai mari stupine ale Europei.", source: "apicultură", theme: .beginnings, subtheme: .smallToLarge ),

        // MARK: What a start settles
        Passage( text: "Ziua bună se cunoaște de dimineață.", source: "proverb românesc", theme: .beginnings, subtheme: .whatAStartSettles ),
        Passage( text: "Cum îți așterni, așa dormi.", source: "proverb românesc", theme: .beginnings, subtheme: .whatAStartSettles ),
        Passage( text: "Așchia nu sare departe de trunchi.", source: "proverb românesc", theme: .beginnings, subtheme: .whatAStartSettles ),
        Passage( text: "Ursitoarele sunt trei și vin în a treia noapte de la naștere. Li se lasă pe masă pâine, sare și apă, fiindcă ele hotărăsc și pleacă.", source: "credință populară românească", theme: .beginnings, subtheme: .whatAStartSettles ),
        Passage( text: "Noroc, soartă și ursită înseamnă cam același lucru, dar au venit din trei limbi deosebite. Ce ți-e dat a fost numit de mai multe ori.", source: "limba română", theme: .beginnings, subtheme: .whatAStartSettles ),
        Passage( text: "Soarta vine din latinescul sortem, bățul tras la întâmplare dintr-un vas. La început a fost un obiect, nu o poveste.", source: "latină", theme: .beginnings, subtheme: .whatAStartSettles ),
        Passage( text: "Grâul semănat toamna trebuie să treacă prin ger, altfel nu face spic niciodată. Frigul de la început îi îngăduie vara.", source: "agronomie", theme: .beginnings, subtheme: .whatAStartSettles ),
        Passage( text: "Într-o grindă de biserică de lemn din Maramureș, inelele scrise în primii ani ai bradului spun și acum în care iarnă a fost doborât.", source: "dendrocronologie", theme: .beginnings, subtheme: .whatAStartSettles ),
        Passage( text: "Un fag crescut singur pe islaz se ramifică de jos și rămâne scund. Același fag într-o pădure deasă urcă douăzeci de metri fără nicio creangă.", source: "silvicultură", theme: .beginnings, subtheme: .whatAStartSettles ),
        Passage( text: "La broasca țestoasă dobrogeană, căldura cuibului hotărăște dacă puii vor fi masculi sau femele. Adâncimea gropii ține loc de zestre.", source: "Testudo hermanni", theme: .beginnings, subtheme: .whatAStartSettles ),
        Passage( text: "De la bun început, se zice românește. Începutul primește un adjectiv care nu descrie nimic, doar întărește: era chiar acela, cel bun.", source: "limba română", theme: .beginnings, subtheme: .whatAStartSettles ),
        Passage( text: "Orice larvă de albină ar fi putut ajunge matcă. Ce le desparte este numai hrana primită în cele dintâi zile.", source: "Apis mellifera", theme: .beginnings, subtheme: .whatAStartSettles ),

        // MARK: - Waiting

        // MARK: Held back
        Passage( text: "Graba strică treaba.", source: "proverb românesc", theme: .waiting, subtheme: .heldBack ),
        Passage( text: "Cu răbdare și cu tăcere se face agurida miere.", source: "proverb românesc", theme: .waiting, subtheme: .heldBack ),
        Passage( text: "Brândușa de toamnă înflorește pe câmpul gol, fără nicio frunză. Frunzele și sămânța îi vin abia în primăvara următoare.", source: "Colchicum autumnale", theme: .waiting, subtheme: .heldBack ),
        Passage( text: "A zăbovi e cuvânt slav, iar zăbava e o întârziere pe care ți-o iei singur. Cine face ceva fără zăbavă nu s-a oprit deloc pe drum.", source: "limba română", theme: .waiting, subtheme: .heldBack ),
        Passage( text: "Multe semințe de pomi nu încolțesc dacă nu au trecut printr-o iarnă. Pepinierele le îngroapă în nisip umed și le lasă acolo până în martie.", source: "pepinieristică", theme: .waiting, subtheme: .heldBack ),
        Passage( text: "Mugurul de măr este gata făcut încă din iulie, cu floarea strânsă înăuntru. Stă închis șapte luni, deși nimic nu-i mai lipsește.", source: "Malus domestica", theme: .waiting, subtheme: .heldBack ),
        Passage( text: "Ursul din Carpați nu doarme adânc iarna: se trezește dacă e nevoie. Puii se nasc în bârlog, în mijlocul gerului, și ies afară abia primăvara.", source: "Ursus arctos", theme: .waiting, subtheme: .heldBack ),
        Passage( text: "Cloșca stă pe ouă douăzeci și una de zile și nu mai face niciun ou cât timp clocește. Coboară de pe cuib doar cât să bea apă.", source: "gospodărie", theme: .waiting, subtheme: .heldBack ),
        Passage( text: "A amâna este făcut din mâine: cine amână împinge lucrul, la propriu, în ziua următoare.", source: "limba română", theme: .waiting, subtheme: .heldBack ),
        Passage( text: "Firea, felul cuiva de a fi, este chiar infinitivul vechi al verbului a fi. Cine își ține firea își ține ființa pe loc.", source: "limba română", theme: .waiting, subtheme: .heldBack ),
        Passage( text: "Iazul morii adună apa pârâului până se strânge destulă cât să întoarcă roata. Până atunci, morarul are vreme să stea de vorbă.", source: "mori de apă", theme: .waiting, subtheme: .heldBack ),
        Passage( text: "Borșul se pune la copt: tărâțe, apă călduță, un ștergar deasupra și trei zile în care nu se face nimic cu el.", source: "bucătărie românească", theme: .waiting, subtheme: .heldBack ),

        // MARK: The long count
        Passage( text: "Ce mi-e vremea, când de veacuri / Stele-mi scânteie pe lacuri?", source: "Mihai Eminescu, Revedere", theme: .waiting, subtheme: .theLongCount ),
        Passage( text: "Nu aduce anul ce aduce ceasul.", source: "proverb românesc", theme: .waiting, subtheme: .theLongCount ),
        Passage( text: "Încetul cu încetul se face oțetul.", source: "proverb românesc", theme: .waiting, subtheme: .theLongCount ),
        Passage( text: "Dorul coboară din latinescul dolus, durere. În română nu se simte, se are: ai un dor, duci dorul cuiva, îți este dor de undeva.", source: "limba română", theme: .waiting, subtheme: .theLongCount ),
        Passage( text: "Vremea e cuvânt slav, timpul e latinesc, și româna le-a păstrat pe amândouă. Vremea a rămas totodată numele stării cerului.", source: "limba română", theme: .waiting, subtheme: .theLongCount ),
        Passage( text: "Morunul, cel mai mare pește al Dunării, nu lasă icre înainte de vreo cincisprezece ani, și nici atunci în fiecare primăvară.", source: "Huso huso", theme: .waiting, subtheme: .theLongCount ),
        Passage( text: "Tisa crește atât de încet încât un trunchi de un stat de om poate avea sute de ani. La noi e ocrotită prin lege oriunde se găsește.", source: "Taxus baccata", theme: .waiting, subtheme: .theLongCount ),
        Passage( text: "Gheața din peștera Scărișoara stă în foi așezate una peste alta, ca inelele unui copac. Cele de la fund s-au format acum vreo trei mii de ani.", source: "Munții Apuseni", theme: .waiting, subtheme: .theLongCount ),
        Passage( text: "Chihlimbarul de la Colți, pe Valea Buzăului, e rășină scursă dintr-un copac acum zeci de milioane de ani și întărită de atunci încoace.", source: "geologie", theme: .waiting, subtheme: .theLongCount ),
        Passage( text: "De când lumea și pământul, se spune aici pentru ceva ce nu are început de ținut minte. Nu e o măsură, e o renunțare la măsurat.", source: "expresie românească", theme: .waiting, subtheme: .theLongCount ),
        Passage( text: "Bătrân se trage din latinescul veteranus, ostașul lăsat acasă după multă slujbă. Vârsta a fost la început o socoteală a anilor lucrați.", source: "latină", theme: .waiting, subtheme: .theLongCount ),
        Passage( text: "Caietele rămase de la Eminescu au stat la Academie mai bine de un secol până să apară tipărite întregi, filă cu filă, în facsimil.", source: "manuscrisele eminesciene", theme: .waiting, subtheme: .theLongCount ),

        // MARK: Standing and watching
        Passage( text: "Iar noi locului ne ținem, / Cum am fost așa rămânem.", source: "Mihai Eminescu, Revedere", theme: .waiting, subtheme: .standingAndWatching ),
        Passage( text: "Priveam fără de țintă-n sus — / Într-o sălbatică splendoare / Vedeam Ceahlăul la apus.", source: "George Coșbuc, Vara", theme: .waiting, subtheme: .standingAndWatching ),
        Passage( text: "În fund, pe cer albastru, în zarea depărtată, / La răsărit, sub soare, un negru punct s-arată.", source: "Vasile Alecsandri, Oaspeții primăverii", theme: .waiting, subtheme: .standingAndWatching ),
        Passage( text: "Cu răbdarea treci marea.", source: "proverb românesc", theme: .waiting, subtheme: .standingAndWatching ),
        Passage( text: "A aștepta coboară din latinescul adspectare, a privi înspre ceva. Așteptarea a fost mai întâi o direcție a ochilor.", source: "latină", theme: .waiting, subtheme: .standingAndWatching ),
        Passage( text: "A uita înseamnă a pierde din minte; a se uita înseamnă a privi. Același verb, cu un pronume în plus, face două lucruri fără legătură.", source: "limba română", theme: .waiting, subtheme: .standingAndWatching ),
        Passage( text: "Privighetoarea își trage numele de la a priveghea, a sta treaz. Pasărea e botezată după ceasul la care cântă, nu după cântec.", source: "Luscinia megarhynchos", theme: .waiting, subtheme: .standingAndWatching ),
        Passage( text: "Foișorul de Foc din București s-a ridicat anume ca de sus să se zărească fumul. Orașul a crescut în jurul lui și turnul a rămas fără priveliște.", source: "București", theme: .waiting, subtheme: .standingAndWatching ),
        Passage( text: "Prin Deltă trece Via Pontica, drumul de toamnă al păsărilor. Oamenii se așază în stuf, cu ochelarul la ochi, și le socotesc cu sutele de mii.", source: "Delta Dunării", theme: .waiting, subtheme: .standingAndWatching ),
        Passage( text: "La Vârful Omu, peste două mii cinci sute de metri, aparatele se citesc la aceleași ore în fiecare zi, și iarna, și când nu se întâmplă nimic.", source: "stația meteorologică Omu", theme: .waiting, subtheme: .standingAndWatching ),
        Passage( text: "Noaptea, la stână, ciobanul doarme. Câinii sunt cei care veghează, iar treaba lor se face stând pe loc, cu urechile ridicate.", source: "păstorit", theme: .waiting, subtheme: .standingAndWatching ),
        Passage( text: "Cotele Dunării se iau de pe niște rigle bătute în mal, la aceeași oră a dimineții. Cineva scrie un număr; din numerele acelea se află viitura.", source: "hidrologie", theme: .waiting, subtheme: .standingAndWatching ),

        // MARK: - Renewal

        // MARK: Cut and come again
        Passage( text: "Otava este iarba crescută după ce fânul a fost strâns: al doilea rând de pe aceeași pajiște, în aceeași vară.", source: "limba română", theme: .renewal, subtheme: .cutAndComeAgain ),
        Passage( text: "Vița tăiată primăvara plânge: prin tăietură curge sevă zile în șir, semn că rădăcina lucra deja de sub pământ.", source: "viticultură", theme: .renewal, subtheme: .cutAndComeAgain ),
        Passage( text: "Stuful se recoltează iarna, pe gheață, și se ridică la loc până în august. Stufărișul Deltei e cel mai întins de pe pământ.", source: "Delta Dunării", theme: .renewal, subtheme: .cutAndComeAgain ),
        Passage( text: "Răchita de pe malul apei se retează în fiecare an până la trunchi. Nuielele pentru coșuri sunt tocmai lăstarii crescuți de atunci.", source: "împletituri", theme: .renewal, subtheme: .cutAndComeAgain ),
        Passage( text: "Crângul e un fel de a ține pădurea: arborii se doboară la pământ, iar cioata scoate mlădițe noi. Așa poate fi lucrată sute de ani.", source: "silvicultură", theme: .renewal, subtheme: .cutAndComeAgain ),
        Passage( text: "Cerbul carpatin își leapădă coarnele în fiecare primăvară și crește altele, de obicei mai mari. Câteva luni umblă cu capul gol.", source: "Cervus elaphus", theme: .renewal, subtheme: .cutAndComeAgain ),
        Passage( text: "Românește nu o iei de la început, ci de la capăt. Reînceperea se face de la marginea unde lucrul rămăsese.", source: "limba română", theme: .renewal, subtheme: .cutAndComeAgain ),
        Passage( text: "Tunsul oilor se face la intrarea verii, într-o singură zi și cu tot satul de față. Lâna e la loc până vin gerurile.", source: "păstorit", theme: .renewal, subtheme: .cutAndComeAgain ),
        Passage( text: "Fânețele de munte din Transilvania se cosesc de mână, târziu, după ce florile au lăsat sămânță. De aceea au rămas cele mai bogate din Europa.", source: "pajiști carpatine", theme: .renewal, subtheme: .cutAndComeAgain ),
        Passage( text: "Pomii se curăță la sfârșitul iernii. Ramurile scoase acum fac loc luminii, iar mărul leagă mai mult rod decât dacă l-ai fi lăsat în pace.", source: "pomicultură", theme: .renewal, subtheme: .cutAndComeAgain ),
        Passage( text: "Șopârla își lasă coada în urmă când e prinsă și îi crește alta. A doua oară înăuntru nu mai e os, ci zgârci, și se cunoaște după culoare.", source: "Lacerta agilis", theme: .renewal, subtheme: .cutAndComeAgain ),
        Passage( text: "Nisipurile din sudul Olteniei au fost oprite din mers cu salcâmi. Tăiați pe la douăzeci de ani, pornesc singuri din rădăcină, fără să fie sădiți iar.", source: "Robinia pseudoacacia", theme: .renewal, subtheme: .cutAndComeAgain ),

        // MARK: The turning year
        Passage( text: "S-a dus zăpada albă de pe întinsul țării, / S-au dus zilele Babei și nopțile vegherii.", source: "Vasile Alecsandri, Sfârșitul iernei", theme: .renewal, subtheme: .theTurningYear ),
        Passage( text: "Vreme trece, vreme vine, / Toate-s vechi și nouă toate.", source: "Mihai Eminescu, Glossă", theme: .renewal, subtheme: .theTurningYear ),
        Passage( text: "A-nceput de ieri să cadă / Câte-un fulg, acum a stat.", source: "George Coșbuc, Iarna pe uliță", theme: .renewal, subtheme: .theTurningYear ),
        Passage( text: "Cu o floare nu se face primăvară.", source: "proverb românesc", theme: .renewal, subtheme: .theTurningYear ),
        Passage( text: "La întâi martie se dă un mărțișor: un fir alb răsucit cu unul roșu. Se poartă până înfloresc pomii, apoi se leagă de o creangă.", source: "obicei românesc", theme: .renewal, subtheme: .theTurningYear ),
        Passage( text: "Babele sunt cele nouă zile de la începutul lui martie. Îți alegi una fără să vezi cerul; cum iese vremea atunci, așa ți se spune că va fi anul.", source: "credință populară românească", theme: .renewal, subtheme: .theTurningYear ),
        Passage( text: "Primăvară înseamnă, cuvânt cu cuvânt, prima vară. Latinescul ver a rămas în vară, iar anotimpul de dinaintea ei s-a numit după ea.", source: "latină", theme: .renewal, subtheme: .theTurningYear ),
        Passage( text: "Lunile purtau nume de treburi și de vreme: gerar, florar, cireșar, cuptor, gustar, brumar. Calendarul spunea ce se întâmplă afară.", source: "calendar popular", theme: .renewal, subtheme: .theTurningYear ),
        Passage( text: "Bruma se așază pe pământ, chiciura se prinde de crengi, promoroaca se face din ceață. Trei nume după locul unde îngheață apa.", source: "limba română", theme: .renewal, subtheme: .theTurningYear ),
        Passage( text: "Anul păstorului are două hotare: la Sângeorz turmele urcă la munte, la Sâmedru coboară. Între ele e vara, tot restul se cheamă iarnă.", source: "calendar pastoral", theme: .renewal, subtheme: .theTurningYear ),
        Passage( text: "Berzele se duc pe la sfârșitul lui august. Câteva zile stau cu zecile pe miriște, fără să facă nimic, iar într-o dimineață locul e gol.", source: "Ciconia ciconia", theme: .renewal, subtheme: .theTurningYear ),
        Passage( text: "De Sânziene, în noaptea cea mai scurtă, se împletesc cununi din florile galbene de câmp și se aruncă pe acoperiș. De atunci ziua începe să scadă.", source: "obicei de miezul verii", theme: .renewal, subtheme: .theTurningYear ),

        // MARK: Made whole
        Passage( text: "A vindeca vine din latinescul vindicare, a scoate pe cineva de sub o stăpânire străină. Tămăduirea a fost, la obârșie, o eliberare.", source: "latină", theme: .renewal, subtheme: .madeWhole ),
        Passage( text: "Bolnavul, românește, nu se însănătoșește numai: se face bine. Ieșirea din suferință e pusă pe seama verbului a face.", source: "limba română", theme: .renewal, subtheme: .madeWhole ),
        Passage( text: "Cine leșină și se trezește își revine: se întoarce la sine, ca dintr-un drum. Aceeași vorbă se spune și după o spaimă mare.", source: "expresie românească", theme: .renewal, subtheme: .madeWhole ),
        Passage( text: "Zimbrul lipsise din Carpați vreo două veacuri. A fost adus înapoi în munții Țarcului, iar acum fată singur, prin pădure, fără ajutor.", source: "Bison bonasus", theme: .renewal, subtheme: .madeWhole ),
        Passage( text: "Castorul se stinsese de pe toate apele țării. După ce a fost pus iar pe Olt, a coborât de la sine pe alte văi și și-a făcut baraje acolo.", source: "Castor fiber", theme: .renewal, subtheme: .madeWhole ),
        Passage( text: "Marmotele de pe crestele noastre se trag din câteva zeci aduse din Alpi și slobozite în golul alpin. Fluieratul de deasupra pietrei e adus de departe.", source: "Marmota marmota", theme: .renewal, subtheme: .madeWhole ),
        Passage( text: "Insula Babina din Deltă fusese îndiguită și arată. I s-au tăiat digurile, apa a intrat înapoi și stuful cu peștele s-au așezat singure la loc.", source: "Delta Dunării", theme: .renewal, subtheme: .madeWhole ),
        Passage( text: "Prinsul sturionilor în Dunăre e oprit de ani buni. În fiecare primăvară li se dă drumul în fluviu puieților crescuți anume pentru asta.", source: "Dunăre", theme: .renewal, subtheme: .madeWhole ),
        Passage( text: "Pelicanul creț scăzuse la câteva zeci de perechi. Ținut sub pază, s-a înmulțit iar, iar colonia lui din stuf e printre cele mai mari ale Europei.", source: "Pelecanus crispus", theme: .renewal, subtheme: .madeWhole ),
        Passage( text: "Un copac nu-și drege rana, ci o îmbracă: lemnul proaspăt crește peste ea an după an, iar semnul rămâne pentru totdeauna înăuntru.", source: "fiziologia arborilor", theme: .renewal, subtheme: .madeWhole ),
        Passage( text: "A drege înseamnă și a repara ceva stricat, și a potrivi mâncarea cu ce-i lipsește. Un singur verb pentru amândouă felurile de îndreptat.", source: "limba română", theme: .renewal, subtheme: .madeWhole ),
        Passage( text: "Nămolul din lacul Techirghiol e o depunere veche de plante și de sare. Se scoate cu lopata, se usucă pe pielea omului și se spală înapoi în lac.", source: "Techirghiol", theme: .renewal, subtheme: .madeWhole ),

        // MARK: - Light

        // MARK: The edges of the day
        Passage( text: "Somnoroase păsărele / Pe la cuiburi se adună, / Se ascund în rămurele — / Noapte bună!", source: "Mihai Eminescu, Somnoroase păsărele", theme: .light, subtheme: .theEdgesOfTheDay ),
        Passage( text: "Aburii ușori ai nopții ca fantasme se ridică / Și, plutind deasupra luncii, printre ramuri se despică.", source: "Vasile Alecsandri, Malul Siretului", theme: .light, subtheme: .theEdgesOfTheDay ),
        Passage( text: "Se crapă de ziuă, se spune. Lumina nu sosește, ci plesnește ceva: cerul se sparge la margine, ca o coajă subțire.", source: "expresie românească", theme: .light, subtheme: .theEdgesOfTheDay ),
        Passage( text: "Cea dintâi dungă de dimineață se cheamă geană. În geană de ziuă înseamnă atât cât ai desface o pleoapă.", source: "limba română", theme: .light, subtheme: .theEdgesOfTheDay ),
        Passage( text: "Zorile nu se ivesc, se revarsă. Revărsatul zorilor spune că roșeața curge peste marginea pământului, ca dintr-un vas prea plin.", source: "expresie românească", theme: .light, subtheme: .theEdgesOfTheDay ),
        Passage( text: "Zori nu are număr singular. Nimeni nu apucă un zor: lumina de la început de zi e socotită dintru început mai multe lucruri deodată.", source: "gramatica limbii române", theme: .light, subtheme: .theEdgesOfTheDay ),
        Passage( text: "Amurgul își ia numele de la murg, culoarea unui cal negru-roșcat. Seara poartă, la noi, numele unei blăni de armăsar.", source: "limba română", theme: .light, subtheme: .theEdgesOfTheDay ),
        Passage( text: "Se înserează, se înnoptează, se face ziuă: aceste verbe nu au pe nimeni care să le săvârșească. Trecerea se petrece fără subiect.", source: "gramatica limbii române", theme: .light, subtheme: .theEdgesOfTheDay ),
        Passage( text: "La Sulina, cel mai răsăritean pământ al țării, soarele se arată mai devreme decât oriunde altundeva. Ziua intră în țară pe la capătul Deltei.", source: "geografie", theme: .light, subtheme: .theEdgesOfTheDay ),
        Passage( text: "Soarele răsare și apune. Într-un verb stă a sări, în celălalt stă a pune: dimineața sare afară, seara e așezat deoparte.", source: "latină", theme: .light, subtheme: .theEdgesOfTheDay ),
        Passage( text: "După ce lumina e mai scurtă ca oricând, se zice că ea crește pe zi ce trece cu un pas de cocoș. Măsura e mică fiindcă atât se vede la început.", source: "vorbă de calendar", theme: .light, subtheme: .theEdgesOfTheDay ),

        // MARK: Reading the light
        Passage( text: "Punctele cardinale sunt aici ceasuri: miazăzi e sudul, miazănoapte e nordul, iar estul și vestul se cheamă răsărit și apus.", source: "limba română", theme: .light, subtheme: .readingTheLight ),
        Passage( text: "Soare cu dinți i se spune luminii de ianuarie care taie ochii și nu încălzește nimic. Se vede de departe că mușcă.", source: "expresie românească", theme: .light, subtheme: .readingTheLight ),
        Passage( text: "Floarea-soarelui tânără urmărește soarele toată ziua, iar noaptea se răsucește înapoi. După ce se coace, rămâne întoarsă spre răsărit pentru totdeauna.", source: "Helianthus annuus", theme: .light, subtheme: .readingTheLight ),
        Passage( text: "Ciobanul află ceasul măsurându-și umbra cu propriul picior, talpă după talpă. La amiază îi ajung câțiva pași, seara nu-i mai ajunge nimic.", source: "măsurători păstorești", theme: .light, subtheme: .readingTheLight ),
        Passage( text: "Pe la începutul lui august, în zori, Ceahlăul își aruncă peste munți o umbră în chip de piramidă, deși vârful nu are forma aceea.", source: "umbra Ceahlăului", theme: .light, subtheme: .readingTheLight ),
        Passage( text: "Curcubeul, spune credința veche, soarbe apă din râuri și o urcă în nori. Ce se vede pe cer e socotit un lucru care lucrează, nu un semn.", source: "credință populară românească", theme: .light, subtheme: .readingTheLight ),
        Passage( text: "Zarea e strălucirea de la marginea cerului, iar din ea s-a făcut verbul a zări. Ca să vezi ceva, trebuie întâi puțină lumină pe hotarul lumii.", source: "limba română", theme: .light, subtheme: .readingTheLight ),
        Passage( text: "Icoanele pe sticlă se lucrează de-a-ndoaselea: culoarea de deasupra se pune cea dintâi. Lumina trece prin sticlă, atinge vopseaua și se întoarce la privitor.", source: "icoane pe sticlă", theme: .light, subtheme: .readingTheLight ),
        Passage( text: "Când luna nouă stă cu coarnele în sus, ca o luntre, se zice că ține ploaia în ea. Când se pleacă într-o rână, o varsă.", source: "credință populară românească", theme: .light, subtheme: .readingTheLight ),
        Passage( text: "Canicula poartă numele stelei Câine, care în iulie se ridică o dată cu soarele. Cea mai fierbinte parte a verii a fost socotită după un astru.", source: "latină", theme: .light, subtheme: .readingTheLight ),
        Passage( text: "Zorelele sunt numite după zori: se desfac o dată cu lumina și se strâng până la prânz. Floarea e un ceas care merge o singură dată pe zi.", source: "Ipomoea purpurea", theme: .light, subtheme: .readingTheLight ),
        Passage( text: "Mușchiul se face mai gros pe fața dinspre miazănoapte a trunchiului, acolo unde soarele nu bate. Cine s-a rătăcit pipăie coaja copacului.", source: "orientare în pădure", theme: .light, subtheme: .readingTheLight ),

        // MARK: Light itself
        Passage( text: "La steaua care-a răsărit / E-o cale-atât de lungă, / Că mii de ani i-au trebuit / Luminii să ne-ajungă.", source: "Mihai Eminescu, La steaua", theme: .light, subtheme: .lightItself ),
        Passage( text: "Lumina vine din latinescul lumen, iar poiana din mijlocul pădurii se cheamă luminiș. Golul e numit după ce cade în el, nu după ce-i lipsește.", source: "latină", theme: .light, subtheme: .lightItself ),
        Passage( text: "Luceafărul de dimineață și luceafărul de seară sunt aceeași planetă, văzută de două ori. Numele lui înseamnă, în latinește, purtător de lumină.", source: "astronomie", theme: .light, subtheme: .lightItself ),
        Passage( text: "Licuriciul lucește fără să se încălzească: aproape toată puterea cheltuită iese ca lumină. Numele îi vine de la verbul a licări.", source: "Lampyris noctiluca", theme: .light, subtheme: .lightItself ),
        Passage( text: "Albastrul de la Voroneț stă de peste cinci sute de ani pe peretele de afară, în ploaie și în ger, și nu s-a șters. Cum era făcut nu se știe nici azi.", source: "Voroneț", theme: .light, subtheme: .lightItself ),
        Passage( text: "Opaițul e un blid de lut cu un capăt de fitil pus în seu. A ținut casele luminate mii de ani, cu o flacără cât o boabă de fasole.", source: "arheologie", theme: .light, subtheme: .lightItself ),
        Passage( text: "Focul se scotea cu amnarul și cremenea: oțelul lovește piatra și sar scântei în iască. De acolo a rămas a scăpăra, spus și despre fulger, și despre priviri.", source: "limba română", theme: .light, subtheme: .lightItself ),
        Passage( text: "Soarele de andezit de la Sarmizegetusa e un disc de piatră împărțit în zece raze. Ce se citea pe el nu mai știe astăzi nimeni.", source: "Sarmizegetusa Regia", theme: .light, subtheme: .lightItself ),
        Passage( text: "La Lopătari, în munții Buzăului, gazul iese din pământ și arde singur, zi și noapte. I se spune focul viu, fiindcă nu-l aprinde nimeni.", source: "Focul Viu, Lopătari", theme: .light, subtheme: .lightItself ),
        Passage( text: "În unele veri, Marea Neagră se aprinde noaptea la fiecare val. Sunt alge mărunte care fac lumină de îndată ce apa le clatină.", source: "Noctiluca scintillans", theme: .light, subtheme: .lightItself ),
        Passage( text: "Româna are străluciri de toate mărimile: a luci, a sclipi, a scânteia, a licări, a fulgera. Fiecare verb spune cât de tare și cât de scurt.", source: "limba română", theme: .light, subtheme: .lightItself ),
        Passage( text: "Timișoara a fost cel dintâi oraș din Europa cu străzile luminate electric. Lămpile s-au aprins acolo înaintea celor din marile capitale.", source: "Timișoara", theme: .light, subtheme: .lightItself ),

        // MARK: - Pattern

        // MARK: Counted
        Passage( text: "Toamna se numără bobocii.", source: "proverb românesc", theme: .pattern, subtheme: .counted ),
        Passage( text: "Socoteala de acasă nu se potrivește cu cea din târg.", source: "proverb românesc", theme: .pattern, subtheme: .counted ),
        Passage( text: "Câte bordeie, atâtea obiceie.", source: "proverb românesc", theme: .pattern, subtheme: .counted ),
        Passage( text: "Româna ține un gen pe care surorile ei latine l-au pierdut: un scaun se poartă ca masculin, două scaune ca feminin. Numărătoarea îl mută dintr-o parte în alta.", source: "gramatica limbii române", theme: .pattern, subtheme: .counted ),
        Passage( text: "Unsprezece vrea să spună unu spre zece, unul pus peste zece, și e un fel slav de a socoti. De la douăzeci încolo se revine la tiparul latinesc.", source: "limba română", theme: .pattern, subtheme: .counted ),
        Passage( text: "Suta e cuvânt slav, mia e cuvânt latinesc. Cine numără cu glas tare trece dintr-o limbă în alta fără să bage de seamă.", source: "limba română", theme: .pattern, subtheme: .counted ),
        Passage( text: "În jurul Mesei Tăcerii de la Târgu Jiu stau douăsprezece scaune de piatră, făcute ca niște clepsidre. Masa fiind rotundă, nu are capul ei.", source: "Masa Tăcerii, Târgu Jiu", theme: .pattern, subtheme: .counted ),
        Passage( text: "Coloana de la Târgu Jiu e alcătuită dintr-o singură mărgea romboidală, pusă de cincisprezece ori întreagă și de două ori pe jumătate, jos și sus.", source: "Coloana fără sfârșit", theme: .pattern, subtheme: .counted ),
        Passage( text: "Pleiadelor li se spune aici Cloșca cu pui. Cu ochiul liber se zăresc șase sau șapte, deși stelele acelui pâlc sunt cu mult mai multe.", source: "astronomie populară", theme: .pattern, subtheme: .counted ),
        Passage( text: "A da în bobi se face cu patruzeci și una de boabe de fasole, împărțite în grămăjoare. Ghicitul e, înainte de orice, o aritmetică.", source: "practică populară românească", theme: .pattern, subtheme: .counted ),
        Passage( text: "În noaptea dintre ani se pun deoparte douăsprezece foi de ceapă, cu sare în fiecare, câte una de lună. Dimineața, cele umede arată lunile ploioase.", source: "calendarul de ceapă", theme: .pattern, subtheme: .counted ),
        Passage( text: "Măsurile vechi erau luate de pe trup: degetul, palma, cotul, pasul, stânjenul. Ogorul se socotea în pogoane, iar pogonul era cât ara cineva într-o zi.", source: "măsuri vechi românești", theme: .pattern, subtheme: .counted ),

        // MARK: Fitted together
        Passage( text: "Articolul se lipește la coada cuvântului: lup, lupul. Nicio altă limbă latină nu face așa, în schimb albaneza și bulgara fac la fel.", source: "gramatica limbii române", theme: .pattern, subtheme: .fittedTogether ),
        Passage( text: "Româna și-a lăsat aproape de tot infinitivul: nu zice vreau a merge, ci vreau să merg. Deprinderea e luată de la vecinii din Balcani, nu de la Roma.", source: "gramatica limbii române", theme: .pattern, subtheme: .fittedTogether ),
        Passage( text: "Da e slav, nu e latinesc. Încuviințarea a venit dintr-o parte, împotrivirea din cealaltă, și de atunci stau alături în aceeași gură.", source: "limba română", theme: .pattern, subtheme: .fittedTogether ),
        Passage( text: "A citi vine din slavă, a scrie vine din latină. Cele două jumătăți ale aceleiași îndeletniciri au sosit aici pe drumuri deosebite.", source: "limba română", theme: .pattern, subtheme: .fittedTogether ),
        Passage( text: "Altoiul face din doi pomi unul singur: rădăcina unuia, rodul celuilalt. De la filoxeră încoace, mai toată vița de vie de la noi stă pe rădăcină străină.", source: "pomicultură", theme: .pattern, subtheme: .fittedTogether ),
        Passage( text: "În horă nu conduce nimeni. Cercul se închide, palmele se țin, iar cel care vine mai târziu se prinde între doi oameni care se dau la o parte.", source: "joc popular românesc", theme: .pattern, subtheme: .fittedTogether ),
        Passage( text: "Pe porțile maramureșene e cioplită funia răsucită, care trece de pe un stâlp pe celălalt. Lemnul e tăiat anume ca să pară legat cu frânghie.", source: "poarta maramureșeană", theme: .pattern, subtheme: .fittedTogether ),
        Passage( text: "Colacul de sărbătoare se împletește din trei fâșii de aluat. După coacere nu se mai văd trei, însă fără una dintre ele s-ar desface tot.", source: "bucătărie românească", theme: .pattern, subtheme: .fittedTogether ),
        Passage( text: "Bisericile de lemn din Maramureș s-au ridicat fără cuie: bârnele sunt crestate la capete și se încalecă una peste alta, cunună după cunună.", source: "arhitectură de lemn", theme: .pattern, subtheme: .fittedTogether ),
        Passage( text: "Foile iei se prind între ele printr-o cheiță, o cusătură ajurată. Ceea ce ține bucățile laolaltă este tocmai partea cea mai împodobită a cămășii.", source: "ia românească", theme: .pattern, subtheme: .fittedTogether ),
        Passage( text: "Hribul nu crește oriunde, ci lângă anumiți arbori. Ciuperca și rădăcina sunt împletite sub pământ și își dau una alteia ce nu-și pot face singure.", source: "Boletus edulis", theme: .pattern, subtheme: .fittedTogether ),
        Passage( text: "La Dej, Someșul Mic și Someșul Mare se adună într-un singur Someș. Niciunul nu rămâne cu numele lui, deși apa este a amândurora.", source: "geografie", theme: .pattern, subtheme: .fittedTogether ),

        // MARK: Order named
        Passage( text: "De la lume adunate și iarăși la lume date.", source: "Anton Pann, Povestea vorbii", theme: .pattern, subtheme: .orderNamed ),
        Passage( text: "Cuvânt vine din latinescul conventum, o înțelegere între oameni. Vorba a fost mai întâi ceva asupra căruia se căzuse de acord.", source: "latină", theme: .pattern, subtheme: .orderNamed ),
        Passage( text: "Pentru zăpadă sunt patru nume: nea și ninsoare, venite din latină, omăt și zăpadă, venite din slavă. Ninge la fel, se spune în două feluri.", source: "limba română", theme: .pattern, subtheme: .orderNamed ),
        Passage( text: "Vânturile sunt botezate după locul din care bat: crivățul de la miazănoapte, austrul dinspre miazăzi, băltărețul dinspre bălțile Dunării.", source: "meteorologie populară", theme: .pattern, subtheme: .orderNamed ),
        Passage( text: "Brad, barză, mal, vatră, copil: vorbe mai vechi decât latina de aici, rămase de la oamenii care locuiau locul dinainte. Lucrurile erau deja pe teren.", source: "substratul limbii române", theme: .pattern, subtheme: .orderNamed ),
        Passage( text: "Din 1993, același sunet se scrie î la marginea cuvântului și â înăuntru: început, dar cuvânt. Litera arată unde stă, nu cum se rostește.", source: "ortografia limbii române", theme: .pattern, subtheme: .orderNamed ),
        Passage( text: "S-a ținut un caz gramatical numai pentru chemat: codrule, soro, Ioane. Cine strigă pe cineva îi schimbă terminația numelui.", source: "gramatica limbii române", theme: .pattern, subtheme: .orderNamed ),
        Passage( text: "Cantemir a scris Descriptio Moldaviae latinește și cu hartă: cea dintâi carte care ia țara la rând, munte cu munte și obicei cu obicei, pentru străini.", source: "Dimitrie Cantemir, Descriptio Moldaviae", theme: .pattern, subtheme: .orderNamed ),
        Passage( text: "Leul poartă numele unui taler olandez cu un leu bătut pe el, care umbla pe aceste locuri acum vreo trei sute de ani. Banul se cheamă după o dregătorie.", source: "numismatică", theme: .pattern, subtheme: .orderNamed ),
        Passage( text: "Doina se cântă slobod, fără măsură dinainte hotărâtă. Cine o zice o lungește cât are nevoie; cine o pune pe note e nevoit să aleagă în locul ei.", source: "muzică populară românească", theme: .pattern, subtheme: .orderNamed ),
        Passage( text: "Cerul a primit nume de gospodărie: Carul Mare pentru cele șapte stele, Calea Robilor pentru brâul alb care taie bolta în două.", source: "astronomie populară", theme: .pattern, subtheme: .orderNamed ),
        Passage( text: "Pe mâneca iei, șirurile cusute pieziș se numesc râuri, iar peticul brodat de pe umăr, altiță. După felul cum sunt așezate se știe din ce sat e cămașa.", source: "ia românească", theme: .pattern, subtheme: .orderNamed ),
        // MARK: - Ground

        // MARK: The soil itself
        Passage(text: "Pământ vine din latinescul pavimentum, podea bătătorită. Celelalte limbi romanice au ținut terra; româna și-a numit solul după felul în care este călcat.", source: "Latină", theme: .ground, subtheme: .theSoilItself),
        Passage(text: "Latinescul terra nu s-a păstrat în română ca nume al solului. A dat țara și țărâna: din același cuvânt, o patrie și un pumn de praf.", source: "Etimologie", theme: .ground, subtheme: .theSoilItself),
        Passage(text: "A ara este latinesc, din arare. Plugul și brazda sunt slave. Fapta poartă nume roman, unealta care o face vine din altă limbă.", source: "Etimologie", theme: .ground, subtheme: .theSoilItself),
        Passage(text: "Cernoziomul din Câmpia Română are un strat negru adânc de peste un metru, adunat din ierburi de stepă putrezite mii de ani la rând.", source: "Pedologie", theme: .ground, subtheme: .theSoilItself),
        Passage(text: "Loessul pe care stă Dobrogea este praf purtat de vânt și așezat fir cu fir, pe vremea când câmpia era rece și golașă.", source: "Geologie", theme: .ground, subtheme: .theSoilItself),
        Passage(text: "Lutul își ține numele latinesc, lutum. Din el ies cărămida nearsă, oala de pământ și tencuiala întinsă peste nuiele.", source: "Latină", theme: .ground, subtheme: .theSoilItself),
        Passage(text: "Humă se cheamă argila albă cu care se văruiau vatra și pereții. Satul lui Creangă, Humulești, își trage numele de la ea.", source: "Lexic", theme: .ground, subtheme: .theSoilItself),
        Passage(text: "Ogorul este pământul arat și lăsat un an fără sămânță. Nu stă nelucrat: odihna lui este o lucrare.", source: "Agricultură", theme: .ground, subtheme: .theSoilItself),
        Passage(text: "Glia este solul cu iarbă cu tot, tăiat într-o singură bucată, și totodată locul unde te-ai născut. Un cuvânt care e deopotrivă material și obârșie.", source: "Definiție", theme: .ground, subtheme: .theSoilItself),
        Passage(text: "Apa trece, pietrele rămân.", source: "proverb românesc", theme: .ground, subtheme: .theSoilItself),
        Passage(text: "Râma își ia numele de la verbul a râma, a răscoli cu botul. Cum se cheamă spune ce face, nu cum arată.", source: "Lumbricus terrestris", theme: .ground, subtheme: .theSoilItself),
        Passage(text: "Țelină înseamnă două lucruri fără legătură între ele: leguma din supă și ținutul nearat vreodată. A desțeleni este a-l sparge întâia oară.", source: "Omonimie", theme: .ground, subtheme: .theSoilItself),

        // MARK: A place you are from
        Passage(text: "Nu știu alții cum sunt, dar eu, când mă gândesc la locul nașterii mele, la casa părintească din Humulești...", source: "Ion Creangă, Amintiri din copilărie", theme: .ground, subtheme: .aPlaceYouAreFrom),
        Passage(text: "Satul vine din latinescul fossatum, șanț săpat de jur împrejur. Orașul vine din maghiarul város. Cel mic poartă nume roman, cel mare unguresc.", source: "Etimologie", theme: .ground, subtheme: .aPlaceYouAreFrom),
        Passage(text: "Vatra este locul focului și, totodată, partea din sat unde stau casele. Cuvântul nu vine din latină; româna îl împarte cu albaneza.", source: "Lexic", theme: .ground, subtheme: .aPlaceYouAreFrom),
        Passage(text: "Obârșia unui om și obârșia unui râu se spun la fel. Amândouă înseamnă capătul de sus, de unde pornește.", source: "Definiție", theme: .ground, subtheme: .aPlaceYouAreFrom),
        Passage(text: "Mal, brad, barză, viezure, mânz, copil: vreo sută de cuvinte pe care româna nu le-a luat nici din latină, nici din slavă. Sunt tot ce se mai aude din vorbirea de dinaintea Romei.", source: "Substrat", theme: .ground, subtheme: .aPlaceYouAreFrom),
        Passage(text: "Terminația -ești dintr-un nume de sat a fost întâi numele unei familii. Popeștii erau ai lui Popa, iar așezarea a primit numele lor.", source: "Toponimie", theme: .ground, subtheme: .aPlaceYouAreFrom),
        Passage(text: "Moșia își trage numele de la moș, bătrânul de la care a venit. Ținutul se cheamă după cel dinaintea ta, nu după tine.", source: "Etimologie", theme: .ground, subtheme: .aPlaceYouAreFrom),
        Passage(text: "Acasă nu este o clădire. Poți fi acasă în curte, în sat sau în țară; cuvântul arată apartenența, nu zidurile.", source: "Definiție", theme: .ground, subtheme: .aPlaceYouAreFrom),
        Passage(text: "Omul sfințește locul.", source: "proverb românesc", theme: .ground, subtheme: .aPlaceYouAreFrom),
        Passage(text: "În Ardeal, o țară poate fi o vale: Țara Oașului, Țara Hațegului, Țara Bârsei. Vorba care astăzi înseamnă stat a însemnat mai întâi atât cât străbați într-o zi.", source: "Geografie", theme: .ground, subtheme: .aPlaceYouAreFrom),
        Passage(text: "Baștină este ce ai prin naștere, nu prin cumpărare. Se spune la fel despre un om, despre un soi de măr și despre un cuvânt.", source: "Definiție", theme: .ground, subtheme: .aPlaceYouAreFrom),
        Passage(text: "Plaiul este coasta de munte pe care se poate păși și paște, dar și drumul care o urmează. Același cuvânt ține deodată un loc și o cale.", source: "Definiție", theme: .ground, subtheme: .aPlaceYouAreFrom),

        // MARK: A kept place
        Passage(text: "Gardul este cuvânt de dinaintea latinei, împărțit cu albaneza; grădina este slavă. Ceea ce înconjoară locul are nume mai vechi decât locul.", source: "Etimologie", theme: .ground, subtheme: .aKeptPlace),
        Passage(text: "Curtea vine din latinescul cohortem, împrejmuirea din spatele casei. Din același cuvânt au ieșit și cohorta de soldați, și curtea domnească.", source: "Latină", theme: .ground, subtheme: .aKeptPlace),
        Passage(text: "Ograda este slavă, a îngrădi este făcut din gard. Două limbi au dat două cuvinte pentru același gest.", source: "Etimologie", theme: .ground, subtheme: .aKeptPlace),
        Passage(text: "Prispa este fâșia de pământ bătut, ridicată de-a lungul casei și adăpostită de streașină. Nu este nici odaie, nici ogradă.", source: "Definiție", theme: .ground, subtheme: .aKeptPlace),
        Passage(text: "În Maramureș, poarta de lemn se face mai înaltă decât gardul și se cioplește cu funia răsucită și cu roata soarelui.", source: "Etnografie", theme: .ground, subtheme: .aKeptPlace),
        Passage(text: "Fântâna își ia numele din latinescul fontana, izvor. Cumpăna care scoate găleata este o pârghie cu contragreutate, veche de mii de ani.", source: "Latină", theme: .ground, subtheme: .aKeptPlace),
        Passage(text: "Livada a venit, prin slavă, dintr-un cuvânt grecesc care însemna pajiște. Româna a mutat înțelesul de la iarbă la pomi.", source: "Etimologie", theme: .ground, subtheme: .aKeptPlace),
        Passage(text: "Vie înseamnă deopotrivă podgorie și femininul lui viu. Vinea și viva, două vorbe latinești deosebite, au ajuns la aceeași rostire.", source: "Omonimie", theme: .ground, subtheme: .aKeptPlace),
        Passage(text: "Prisaca este locul unde stau stupii, ales nu după ce se află pe el, ci după ce înflorește de jur împrejur.", source: "Apicultură", theme: .ground, subtheme: .aKeptPlace),
        Passage(text: "Răzorul este fâșia îngustă lăsată nearată între două ogoare. Nu aparține nimănui și ține minte hotarul.", source: "Definiție", theme: .ground, subtheme: .aKeptPlace),
        Passage(text: "Ochiul stăpânului îngrașă vita.", source: "proverb românesc", theme: .ground, subtheme: .aKeptPlace),
        Passage(text: "Căpița se ridică pe loc și rămâne mică; claia se clădește în jurul unui par bătut în pământ și ține fânul uscat până în primăvară.", source: "Etnografie", theme: .ground, subtheme: .aKeptPlace),

        // MARK: - Travel

        // MARK: How a seed goes
        Passage(text: "Păpădia își trimite semințele cu o umbreluță de peri. Deasupra ei aerul se învârte într-un inel, iar inelul o ține sus mai mult decât ar ține o pânză plină.", source: "Taraxacum officinale", theme: .travel, subtheme: .howASeedGoes),
        Passage(text: "Scaiul se agață de lână cu cârlige mărunte, care se îndoaie fără să se rupă. De acolo vine și zicerea că cineva se ține scai de tine.", source: "Arctium lappa", theme: .travel, subtheme: .howASeedGoes),
        Passage(text: "În iunie, plopii albi umplu orașele cu puf. Fiecare fulg poartă un bob care trebuie să cadă pe umed în câteva zile, altfel nu mai are ce da.", source: "Populus alba", theme: .travel, subtheme: .howASeedGoes),
        Passage(text: "Samara frasinului cade rotindu-se în jurul unui singur capăt. Învârtirea o ține în aer destul cât vântul să o mute de sub coroana părintelui.", source: "Fraxinus excelsior", theme: .travel, subtheme: .howASeedGoes),
        Passage(text: "Ciulinul uscat se rupe toamna de la rădăcină și se rostogolește peste Bărăgan, scuturând pe tot drumul ce a strâns peste vară.", source: "Botanică", theme: .travel, subtheme: .howASeedGoes),
        Passage(text: "Vâscul face boabe cleioase. Pasărea le mănâncă, apoi își șterge ciocul de o creangă, și acolo rămâne lipit ce a mai trecut prin ea.", source: "Viscum album", theme: .travel, subtheme: .howASeedGoes),
        Passage(text: "Alunarul ascunde toamna semințe de zâmbru prin mușchi, câte una, în mii de ascunzători. Din cele uitate cresc pădurile de pe creste.", source: "Nucifraga caryocatactes", theme: .travel, subtheme: .howASeedGoes),
        Passage(text: "Plaurul este o insulă plutitoare de stuf, groasă cât un om întins, care se mișcă odată cu vântul și duce cu sine tot ce a prins rădăcină deasupra.", source: "Delta Dunării", theme: .travel, subtheme: .howASeedGoes),
        Passage(text: "Turița se lipește de haină cu perișori întorși la vârf. Nu alege unde ajunge, ci pe cine trece pe lângă ea.", source: "Galium aparine", theme: .travel, subtheme: .howASeedGoes),
        Passage(text: "Oile poartă semințe prinse în lână pe drumurile de munte, iar la tuns le lasă în cu totul altă parte a țării decât cea unde le-au luat.", source: "Transhumanță", theme: .travel, subtheme: .howASeedGoes),
        Passage(text: "Măceșele stau pe tufă peste iarnă, când păsărilor nu le-a mai rămas altceva. Sâmburele iese întreg și cade departe de locul unde a crescut.", source: "Rosa canina", theme: .travel, subtheme: .howASeedGoes),
        Passage(text: "Slăbănogul își încordează păstaia ca pe un arc. La cea mai ușoară atingere ea se răsucește dintr-o dată și azvârle boabele la câțiva pași.", source: "Impatiens noli-tangere", theme: .travel, subtheme: .howASeedGoes),

        // MARK: The road
        Passage(text: "Drum este cuvânt grecesc venit prin slavă; cale este latinesc și însemna întâi poteca bătută de vite. Româna le păstrează pe amândouă.", source: "Etimologie", theme: .travel, subtheme: .theRoad),
        Passage(text: "Cărare vine din latinescul carraria, calea carelor. Astăzi se cheamă la fel poteca prin iarbă și dunga pieptănată în păr.", source: "Latină", theme: .travel, subtheme: .theRoad),
        Passage(text: "Ciobanii coborau turmele din Carpați până în bălțile Dunării și le urcau înapoi, de două ori pe an, pe poteci cu nume știute din tată în fiu.", source: "Păstorit", theme: .travel, subtheme: .theRoad),
        Passage(text: "Vad este locul pe unde se trece apa pe jos. A-ți face vad înseamnă a-ți aduna mușterii: o singură vorbă pentru trecere și pentru trecători.", source: "Definiție", theme: .travel, subtheme: .theRoad),
        Passage(text: "Pod înseamnă și puntea peste apă, și încăperea de sub acoperiș. Amândouă sunt podele așezate deasupra unui gol.", source: "Omonimie", theme: .travel, subtheme: .theRoad),
        Passage(text: "Podul ridicat de Apolodor la Drobeta a avut peste o mie de metri și a fost, vreme de un mileniu, cea mai lungă lucrare de acest fel.", source: "Inginerie romană", theme: .travel, subtheme: .theRoad),
        Passage(text: "Ulița este slavă și duce prin sat; strada a fost împrumutată târziu, din italiană, și duce prin oraș. Numele nou a sosit odată cu caldarâmul.", source: "Etimologie", theme: .travel, subtheme: .theRoad),
        Passage(text: "Poșta a fost deopotrivă locul unde se schimbau caii și distanța dintre două asemenea locuri, cam douăzeci de kilometri. Depărtarea se socotea în opriri.", source: "Măsuri vechi", theme: .travel, subtheme: .theRoad),
        Passage(text: "Conac vine din turcescul konak și a însemnat întâi popasul de o noapte al unui drumeț. Casa boierească a primit numele mult mai târziu.", source: "Turcă", theme: .travel, subtheme: .theRoad),
        Passage(text: "Calea Laptelui poartă în românește și alte nume: Calea Robilor, Calea Paielor, Drumul lui Troian. Fiecare sat a văzut acolo altceva.", source: "nume populare", theme: .travel, subtheme: .theRoad),
        Passage(text: "Cine merge încet, departe ajunge.", source: "proverb românesc", theme: .travel, subtheme: .theRoad),
        Passage(text: "Răscrucea își ia numele de la cruce, vorbă latinească; răspântia a intrat din slavă. Un singur loc, botezat de două ori.", source: "Etimologie", theme: .travel, subtheme: .theRoad),

        // MARK: Far off
        Passage(text: "Dorul se are, nu se simte. Româna spune mi-e dor așa cum spune mi-e foame, iar cuvântul vine din latinescul dolus, durere.", source: "Etimologie", theme: .travel, subtheme: .farOff),
        Passage(text: "Zare înseamnă și marginea unde cerul se așază pe pământ, și lumina slabă care vine de acolo. Depărtarea și licărul poartă un singur nume.", source: "Definiție", theme: .travel, subtheme: .farOff),
        Passage(text: "În basme, depărtarea are măsura ei: peste mări și țări, peste nouă mări și nouă țări. Numărul rămâne mereu același.", source: "formulă de basm", theme: .travel, subtheme: .farOff),
        Passage(text: "Româna deosebește drumețul, care se află pe drum, de călătorul care merge undeva anume, și de pribeagul care umblă fără să se oprească.", source: "Distincție", theme: .travel, subtheme: .farOff),
        Passage(text: "Hăt nu spune nimic de unul singur. Așezat înaintea lui departe, îl împinge și mai încolo: hăt departe, hăt în fundul văii.", source: "Lexic", theme: .travel, subtheme: .farOff),
        Passage(text: "Aiurea a însemnat întâi în altă parte, din latinescul alibi, și abia pe urmă vorbă fără noimă. Depărtarea a ajuns să însemne și rătăcire.", source: "Latină", theme: .travel, subtheme: .farOff),
        Passage(text: "Barza poartă unul dintre numele rămase de dinaintea latinei, iar pasărea face în fiecare toamnă vreo zece mii de kilometri, până în sudul Africii.", source: "Ciconia ciconia", theme: .travel, subtheme: .farOff),
        Passage(text: "Cât vezi cu ochii este o măsură care se schimbă după loc: pe câmpie ține o zi de mers, în pădure ține douăzeci de pași.", source: "expresie românească", theme: .travel, subtheme: .farOff),
        Passage(text: "În poveștile românești lumea are două tărâmuri, iar spre celălalt se coboară printr-o gură deschisă în pământ. Ce e departe poate fi și dedesubt.", source: "Folclor", theme: .travel, subtheme: .farOff),
        Passage(text: "Străin vine din latinescul extraneus, cel de afară. Româna îl pune deopotrivă pe omul necunoscut, pe altă țară și pe lucrul care nu e al tău.", source: "Latină", theme: .travel, subtheme: .farOff),
        Passage(text: "Dunărea sosește de la aproape trei mii de kilometri, strânge apele a zece țări și abia la capăt își desface brațele în mare.", source: "Geografie", theme: .travel, subtheme: .farOff),

        // MARK: - Meeting

        // MARK: The moment
        Passage(text: "Noroc este deopotrivă salut la sosire, urare la plecare și vorba spusă când se ciocnesc paharele. Vine din slavă și înseamnă, la obârșie, ceea ce ți-a fost sorocit.", source: "Etimologie", theme: .meeting, subtheme: .theMoment),
        Passage(text: "La bine ai venit nu se răspunde cu mulțumesc, ci cu bine te-am găsit. Cel care sosește spune, la rândul lui, că a găsit gazda în stare bună.", source: "Formulă de salut", theme: .meeting, subtheme: .theMoment),
        Passage(text: "Codrule, codruțule, / Ce mai faci, drăguțule?", source: "Mihai Eminescu, Revedere", theme: .meeting, subtheme: .theMoment),
        Passage(text: "A da ochii cu cineva înseamnă a ajunge atât de aproape de el încât nu mai poți trece pe alături, chiar dacă nu asta căutai.", source: "Definiție", theme: .meeting, subtheme: .theMoment),
        Passage(text: "Sărut mâna este o mutare în românește a formulei vieneze küss die Hand, rămasă în gură mult după ce a plecat din Viena.", source: "Împrumut", theme: .meeting, subtheme: .theMoment),
        Passage(text: "Hai și haide au venit din turcă. Cuvântul cel mai obișnuit prin care doi oameni pornesc împreună nu e nici latinesc, nici slav.", source: "Turcă", theme: .meeting, subtheme: .theMoment),
        Passage(text: "A ieși în întâmpinarea cuiva înseamnă a porni de acasă către cel care vine, ca bucata de drum rămasă să nu o facă singur.", source: "Definiție", theme: .meeting, subtheme: .theMoment),
        Passage(text: "Numai munte cu munte nu se întâlnește.", source: "proverb românesc", theme: .meeting, subtheme: .theMoment),
        Passage(text: "La gura Dunării, apa dulce plutește deasupra celei sărate și se zărește de sus ca o pată deschisă la culoare, înaintând în larg.", source: "Oceanografie", theme: .meeting, subtheme: .theMoment),
        Passage(text: "Româna nu zice ne-am mai văzut o dată, ci ne cunoaștem. O singură stare față în față ajunge cât o cunoștință.", source: "Distincție", theme: .meeting, subtheme: .theMoment),
        Passage(text: "Someșul Mic și Someșul Mare curg fiecare cu numele lui până la Dej, unde se împreună și de acolo încolo rămâne doar unul.", source: "Geografie", theme: .meeting, subtheme: .theMoment),
        Passage(text: "A se nimeri este a ajunge în același loc în aceeași clipă fără ca vreunul să fi urmărit asta. Limba are un verb anume pentru potriveala aceasta.", source: "Lexic", theme: .meeting, subtheme: .theMoment),

        // MARK: Two that need each other
        Passage(text: "Soț vine din latinescul socius, tovarăș de drum. De aceea un număr cu soț este par: are pereche. Unul fără soț a rămas nepereche.", source: "Latină", theme: .meeting, subtheme: .twoThatNeedEachOther),
        Passage(text: "Aproape toată vița de vie din România crește pe rădăcină americană. După filoxeră, soiurile de aici au fost altoite pe portaltoi aduși de peste ocean.", source: "Viticultură", theme: .meeting, subtheme: .twoThatNeedEachOther),
        Passage(text: "Lichenul nu este o plantă, ci doi locatari: ciuperca ridică adăpostul, alga face hrana. Despărțiți, niciunul nu ține stânca pe care o țin amândoi.", source: "Biologie", theme: .meeting, subtheme: .twoThatNeedEachOther),
        Passage(text: "Hribii nu răsar oriunde. Firele lor se împletesc cu rădăcinile fagului sau ale bradului, iar schimbul dintre ei hrănește și copacul, și ciuperca.", source: "Micoriză", theme: .meeting, subtheme: .twoThatNeedEachOther),
        Passage(text: "Salcâmul înflorește vreo zece zile. Stupii se urcă în camion și pleacă după floare, dinspre miazăzi spre miazănoapte, ca să prindă tot răstimpul.", source: "Stupărit pastoral", theme: .meeting, subtheme: .twoThatNeedEachOther),
        Passage(text: "Claca este lucrul făcut în ceată la casa unuia, plătit cu masă și cu joc, cu învoiala că el va merge la rândul său la casa fiecăruia.", source: "Etnografie", theme: .meeting, subtheme: .twoThatNeedEachOther),
        Passage(text: "Șezătoarea strângea femeile în serile de iarnă într-o singură odaie. Torcea fiecare al ei, dar la lumina și la căldura aceluiași foc.", source: "Obicei", theme: .meeting, subtheme: .twoThatNeedEachOther),
        Passage(text: "Doi boi înjugați trag mai mult decât amândoi pe rând, însă numai dacă pasul lor se potrivește. De aceea se aleg din vreme și se deprind împreună.", source: "Agricultură", theme: .meeting, subtheme: .twoThatNeedEachOther),
        Passage(text: "În grădină, fasolea urcătoare se seamănă printre rândurile de porumb. Una capătă arac, cealaltă capătă azotul lăsat în sol de rădăcini.", source: "Grădinărit", theme: .meeting, subtheme: .twoThatNeedEachOther),
        Passage(text: "Văcarul scotea dimineața vitele întregului sat pe o singură uliță și le aducea înapoi pe înserat, fiecare vacă știind ea singură la ce poartă să intre.", source: "Obicei sătesc", theme: .meeting, subtheme: .twoThatNeedEachOther),
        Passage(text: "Nucul își scutură praful din mâțișori înainte ca florile lui femeiești să fie coapte, ori tocmai pe urma lor. Aproape niciodată nu se leagă din el însuși.", source: "Juglans regia", theme: .meeting, subtheme: .twoThatNeedEachOther),
        Passage(text: "Într-o livadă de meri se lasă din loc în loc câte un pom de alt fel. Fără el, floarea celorlalți leagă puține mere.", source: "Pomicultură", theme: .meeting, subtheme: .twoThatNeedEachOther),

        // MARK: The manners of it
        Passage(text: "Oaspete vine din latinescul hospitem, care numea deodată gazda și străinul primit în casă. Un singur cuvânt pentru amândouă părțile.", source: "Latină", theme: .meeting, subtheme: .theMannersOfIt),
        Passage(text: "A omeni pe cineva înseamnă a-l primi și a-l ospăta cum se cade. Verbul e făcut de-a dreptul din om: purtarea bună poartă numele speciei.", source: "Etimologie", theme: .meeting, subtheme: .theMannersOfIt),
        Passage(text: "Celui venit i se aduce întâi o linguriță de dulceață și un pahar cu apă rece. Se ia o dată, se mulțumește, și abia pe urmă se stă de vorbă.", source: "Obicei", theme: .meeting, subtheme: .theMannersOfIt),
        Passage(text: "Cine intră întâia oară într-o casă este primit cu pâine și cu sare, cele două lucruri care nu lipsesc niciodată din cămară.", source: "Etnografie", theme: .meeting, subtheme: .theMannersOfIt),
        Passage(text: "Poftim ține locul a patru vorbe: intră, ia, mai spune o dată și iartă-mă. Tonul hotărăște de fiecare dată despre care este vorba.", source: "Lexic", theme: .meeting, subtheme: .theMannersOfIt),
        Passage(text: "A da binețe este a saluta pe drum un necunoscut. La țară se socotea nepotrivit să treci pe lângă cineva fără să o faci.", source: "Definiție", theme: .meeting, subtheme: .theMannersOfIt),
        Passage(text: "Mulțumesc a ieșit din urarea mulți ani. A mulțumi cuiva a însemnat la început a-i dori ani mulți, nu a-i întoarce fapta.", source: "Etimologie", theme: .meeting, subtheme: .theMannersOfIt),
        Passage(text: "Româna are trepte: tu, dumneata, dumneavoastră. Cele înalte vin din domnia ta și domnia voastră, așa încât politețea începe prin a face pe celălalt domn.", source: "Gramatică", theme: .meeting, subtheme: .theMannersOfIt),
        Passage(text: "În sate, omul mai vârstnic este strigat cu nume de rudenie: nea, bade, lele, tanti. Numele familiei se împrumută celor din afara ei.", source: "Adresare", theme: .meeting, subtheme: .theMannersOfIt),
        Passage(text: "Vorba dulce mult aduce.", source: "proverb românesc", theme: .meeting, subtheme: .theMannersOfIt),
        Passage(text: "Capul mesei se dă celui venit de departe ori celui mai bătrân, iar gazda se așază lângă ușă, ca să poată ieși după ce mai trebuie.", source: "Obicei", theme: .meeting, subtheme: .theMannersOfIt),
        Passage(text: "Înainte de mâncare se spune poftă bună, iar la sfârșit gazda spune să-ți fie de bine. Masa are formulă și la intrare, și la ieșire.", source: "Formulă", theme: .meeting, subtheme: .theMannersOfIt),

        // MARK: - Kinship

        // MARK: Grown together
        Passage(text: "Când un fir de grâu scoate din același bob mai multe tulpini, agronomii spun că înfrățește. Numele tehnic al lucrului este chiar numele rudeniei.", source: "Agronomie", theme: .kinship, subtheme: .grownTogether),
        Passage(text: "Doi copaci crescuți lipiți se freacă până își rup scoarța, iar rana se închide peste amândoi. Lemnul ajunge unul singur și seva trece dintr-o parte în alta.", source: "Silvicultură", theme: .kinship, subtheme: .grownTogether),
        Passage(text: "O pădurice de plop tremurător poate fi un singur individ: puieții ies toți din aceeași rădăcină și îngălbenesc toți în aceeași săptămână.", source: "Populus tremula", theme: .kinship, subtheme: .grownTogether),
        Passage(text: "Rugul de mure își apleacă vârfurile până ating solul, și acolo prind rădăcini noi. Un desiș întreg poate fi un lanț pornit dintr-o tufă.", source: "Rubus", theme: .kinship, subtheme: .grownTogether),
        Passage(text: "Iedera nu suge din copac. Se prinde de el cu rădăcini scurte care nu intră în lemn și urcă pe altul doar ca să ajungă la lumină.", source: "Hedera helix", theme: .kinship, subtheme: .grownTogether),
        Passage(text: "Un pom nu își vindecă tăietura, ci o îngroapă: marginile scoarței cresc una spre alta până se ating și o acoperă cu totul.", source: "Botanică", theme: .kinship, subtheme: .grownTogether),
        Passage(text: "Frate de cruce se cheamă legătura dintre doi oameni care nu sunt rude și care își jură frăție de față cu martori. Se ținea la fel de tare ca rudenia de sânge.", source: "Obicei", theme: .kinship, subtheme: .grownTogether),
        Passage(text: "Rădăcinile fagilor de pe același povârniș se împreunează una cu alta. Se găsesc cioate fără nicio frunză, ținute în viață ani la rând de vecinii lor.", source: "Silvicultură", theme: .kinship, subtheme: .grownTogether),
        Passage(text: "O nuia de salcie înfiptă în mal prinde rădăcină de la sine. Șirurile de sălcii de pe hotare au fost, aproape toate, puse în felul acesta.", source: "Salix alba", theme: .kinship, subtheme: .grownTogether),
        Passage(text: "Hameiul se răsucește întotdeauna într-un sens, volbura întotdeauna în celălalt. Niciuna nu învață de la cealaltă și niciuna nu se încurcă.", source: "Botanică", theme: .kinship, subtheme: .grownTogether),
        Passage(text: "Codru-i frate cu românul.", source: "zicală românească", theme: .kinship, subtheme: .grownTogether),
        Passage(text: "Roiul plecat din stup se atârnă de o creangă ca un ciorchine, fiecare albină ținându-se de picioarele alteia, până când se hotărăsc încotro merg.", source: "Apis mellifera", theme: .kinship, subtheme: .grownTogether),

        // MARK: The words for it
        Passage(text: "Neam este cuvânt maghiar și acoperă trei lucruri deodată: ruda ta, felul unui lucru și un popor întreg.", source: "Maghiară", theme: .kinship, subtheme: .theWordsForIt),
        Passage(text: "Rudă înseamnă și om din familia ta, și prăjină lungă de lemn. Două vorbe fără nicio legătură, ajunse la aceeași rostire.", source: "Omonimie", theme: .kinship, subtheme: .theWordsForIt),
        Passage(text: "Cumnat vine din latinescul cognatus, care la Roma numea ruda de sânge. Româna l-a mutat cu totul la rudele căpătate prin căsătorie.", source: "Latină", theme: .kinship, subtheme: .theWordsForIt),
        Passage(text: "Nepot ține locul a două rude pe care alte limbi le despart: copilul copilului tău și copilul fratelui tău. Româna nu simte nevoia să aleagă.", source: "Distincție", theme: .kinship, subtheme: .theWordsForIt),
        Passage(text: "Vărul primar se cheamă așa după latinescul verus, adevărat. El este vărul adevărat, față de cei de-al doilea și de-al treilea, veniți mai de departe.", source: "Etimologie", theme: .kinship, subtheme: .theWordsForIt),
        Passage(text: "Nașul și finul sunt rude fără sânge. Legătura se cheamă cumetrie și era socotită destul de tare cât să oprească o nuntă între cele două case.", source: "Obicei", theme: .kinship, subtheme: .theWordsForIt),
        Passage(text: "Socru, soacră, ginere, noră, cumnată: toate numele rudelor prin căsătorie au rămas latinești. Româna nu a împrumutat niciunul din altă limbă.", source: "Lexic", theme: .kinship, subtheme: .theWordsForIt),
        Passage(text: "Moașa care aduce copilul pe lume își trage numele de la moașă, femeia bătrână. Meseria a fost botezată după vârsta celei care o făcea.", source: "Etimologie", theme: .kinship, subtheme: .theWordsForIt),
        Passage(text: "Fiu și fiică sunt latinești, dar copil nu este. E o vorbă de dinaintea Romei, pe care româna o împarte cu albaneza.", source: "Substrat", theme: .kinship, subtheme: .theWordsForIt),
        Passage(text: "Stră- se poate pune de mai multe ori la rând: bunic, străbunic, străstrăbunic. Fiecare adăugire urcă o treaptă și nimeni nu a hotărât unde se oprește.", source: "Gramatică", theme: .kinship, subtheme: .theWordsForIt),
        Passage(text: "Familie a intrat târziu, din franceză. Înainte se spunea casă ori neam: locul unde stăteau împreună sau sângele din care veneau.", source: "Împrumut", theme: .kinship, subtheme: .theWordsForIt),
        Passage(text: "Frate se spune și celui care nu îți este frate. În vorbirea de toate zilele ține loc de virgulă, de mirare și de rugăminte.", source: "Adresare", theme: .kinship, subtheme: .theWordsForIt),

        // MARK: Two people
        Passage(text: "Prieten este cuvânt slav, deși aproape tot ce ține de casă a rămas latinesc. Numele celui de-al doilea om a fost luat din altă parte.", source: "Etimologie", theme: .kinship, subtheme: .twoPeople),
        Passage(text: "Dragoste și iubire sunt amândouă slave; amor a sosit târziu, prin cărți. Româna are trei nume pentru același lucru și niciunul moștenit din latină.", source: "Lexic", theme: .kinship, subtheme: .twoPeople),
        Passage(text: "În horă se ține de mână și cercul se închide; în brâu, jucătorii se apucă unul de brâul celuilalt, iar șirul rămâne deschis la capete.", source: "Joc popular", theme: .kinship, subtheme: .twoPeople),
        Passage(text: "În mijlocul jocului, cineva aruncă o strigătură: două sau patru versuri rimate, spuse tare, prin care perechile află ce urmează.", source: "Folclor", theme: .kinship, subtheme: .twoPeople),
        Passage(text: "Unde-s doi, puterea crește.", source: "Vasile Alecsandri, Hora Unirii", theme: .kinship, subtheme: .twoPeople),
        Passage(text: "Prietenul la nevoie se cunoaște.", source: "proverb românesc", theme: .kinship, subtheme: .twoPeople),
        Passage(text: "Două fete care se prind surate schimbă între ele flori de sânziene, iar de atunci înainte își spun soro, măcar că nu le leagă niciun sânge.", source: "Obicei", theme: .kinship, subtheme: .twoPeople),
        Passage(text: "Vino-n codru la izvorul / Care tremură pe prund.", source: "Mihai Eminescu, Dorința", theme: .kinship, subtheme: .twoPeople),
        Passage(text: "Fierăstrăul cu două mânere se trage, nu se împinge. Fiecare om trage când îi vine rândul, iar dacă unul se grăbește, pânza se îndoaie și stă.", source: "Meșteșug", theme: .kinship, subtheme: .twoPeople),
        Passage(text: "Pereche vine din latinescul paricula, lucruri deopotrivă. De aceea despre doi potriviți se spune că fac pereche, nu că sunt doi.", source: "Latină", theme: .kinship, subtheme: .twoPeople),
        Passage(text: "Logodna era o învoială între două case, întărită cu un inel și cu martori, și se ținea aproape cât nunta însăși.", source: "Obicei", theme: .kinship, subtheme: .twoPeople),
        Passage(text: "Rândunelele se întorc la cuibul de anul trecut și îl dreg amândouă, cărând tină în cioc, drum după drum, până se închide crăpătura.", source: "Hirundo rustica", theme: .kinship, subtheme: .twoPeople),

        // MARK: - Peace

        // MARK: Quiet as a sound
        Passage(text: "Liniște este făcut din lin, care vine din latinescul lenis, blând. Româna nu numește starea după lipsa zgomotului, ci după blândețea lui.", source: "Etimologie", theme: .peace, subtheme: .quietAsASound),
        Passage(text: "Mâlc nu se aude nicăieri singur. Trăiește numai în a tăcea mâlc, unde nu face altceva decât să apese tăcerea.", source: "Lexic", theme: .peace, subtheme: .quietAsASound),
        Passage(text: "Freamăt se spune despre pădure, susur despre apă, foșnet despre frunza uscată. Trei zgomote mărunte, fiecare cu locul lui.", source: "Distincție", theme: .peace, subtheme: .quietAsASound),
        Passage(text: "În blocuri, orele de liniște stau scrise la intrare: noaptea până dimineața și, pe alocuri, un ceas după prânz. Sunt singurele ore pe care legea le apără.", source: "Uz și lege", theme: .peace, subtheme: .quietAsASound),
        Passage(text: "Zăpada proaspătă înghite sunetul: aerul prins între fulgi ia din el mai ales ce este ascuțit. De aceea întâia noapte de iarnă pare mai tăcută decât e.", source: "Acustică", theme: .peace, subtheme: .quietAsASound),
        Passage(text: "Peste vârfuri trece lună, / Codru-și bate frunza lin.", source: "Mihai Eminescu, Peste vârfuri", theme: .peace, subtheme: .quietAsASound),
        Passage(text: "Buciumul se aude peste văi la câțiva kilometri, însă numai pe vreme așezată. La vânt nu trece nici dealul dintâi.", source: "Instrument pastoral", theme: .peace, subtheme: .quietAsASound),
        Passage(text: "Ciocănitoarea își alege pentru tobă creanga cea mai uscată și mai goală din tot copacul. Într-o pădure fără vânt, bătaia ei se duce peste un kilometru.", source: "Dendrocopos major", theme: .peace, subtheme: .quietAsASound),
        Passage(text: "Șoapta se face fără glas: coardele nu se clatină deloc, printre ele trece doar suflarea. De aceea o șoaptă nu poate fi cântată.", source: "Fonetică", theme: .peace, subtheme: .quietAsASound),
        Passage(text: "În surdină înseamnă cântat cu surdina așezată pe punte. Sunetul rămâne întreg acolo unde era; i se ia numai tăria.", source: "Muzică", theme: .peace, subtheme: .quietAsASound),
        Passage(text: "Ciobanul nu ascultă talăngile, le aude fără voia lui. Bagă de seamă abia atunci când ele tac.", source: "Păstorit", theme: .peace, subtheme: .quietAsASound),
        Passage(text: "Înainte de furtună, păsările se opresc cu un sfert de ceas mai devreme decât cade prima picătură. Tăcerea sosește înaintea ploii.", source: "Observație", theme: .peace, subtheme: .quietAsASound),

        // MARK: The words for stopping
        Passage(text: "A se împăca este făcut din pace, dar se spune deopotrivă despre doi care se înțeleg bine și despre unul care se obișnuiește cu un gând.", source: "Lexic", theme: .peace, subtheme: .theWordsForStopping),
        Passage(text: "Lasă-mă în pace nu cere împăcare, ci singurătate. Aceeași vorbă slujește și la încheierea unei certe, și la a nu fi deranjat.", source: "Distincție", theme: .peace, subtheme: .theWordsForStopping),
        Passage(text: "Târgul se încheie cu bătutul palmei: cei doi își lovesc o dată palmele, și de atunci înțelegerea nu se mai întoarce.", source: "Obicei", theme: .peace, subtheme: .theWordsForStopping),
        Passage(text: "Răgazul este vremea pe care ți-o dă altul; odihna este ceea ce faci tu cu ea. Unul se cere, cealaltă se ia.", source: "Distincție", theme: .peace, subtheme: .theWordsForStopping),
        Passage(text: "Tihna nu înseamnă odihnă. Este felul așezat în care lucrezi atunci când nu te zorește nimeni.", source: "Definiție", theme: .peace, subtheme: .theWordsForStopping),
        Passage(text: "Astâmpăr se aude mai des cu ne- în față: neastâmpăr. Starea are nume, însă se cheamă mai ales după lipsa ei.", source: "Lexic", theme: .peace, subtheme: .theWordsForStopping),
        Passage(text: "A înceta vine din latinescul cessare, a lăsa din mână. Româna i-a pus un în- înainte, ca și cum oprirea ar fi tot o intrare.", source: "Latină", theme: .peace, subtheme: .theWordsForStopping),
        Passage(text: "A se potoli se zice la fel despre vânt, despre foc și despre un om supărat. Toate trei se sting cam în același ritm.", source: "Lexic", theme: .peace, subtheme: .theWordsForStopping),
        Passage(text: "A ierta vine din latinescul libertare, a face liber. Iertarea a fost întâi o eliberare și abia pe urmă o purtare.", source: "Latină", theme: .peace, subtheme: .theWordsForStopping),
        Passage(text: "Sărbătoare vine din latinescul servatoria, lucruri de păzit. O zi de sărbătoare este una pe care o ții, nu una pe care o petreci.", source: "Latină", theme: .peace, subtheme: .theWordsForStopping),
        Passage(text: "Când ploaia stă și vântul cade, se spune că s-a așezat vremea. Nu că s-ar fi făcut frumos, ci că a contenit să se schimbe.", source: "Expresie", theme: .peace, subtheme: .theWordsForStopping),
        Passage(text: "A împăca și capra și varza înseamnă a mulțumi două tabere care se bat cap în cap. Idiomul acesta nu se spune la fel nicăieri altundeva.", source: "Idiom românesc", theme: .peace, subtheme: .theWordsForStopping),

        // MARK: At ease
        Passage(text: "Somnoroase păsărele / Pe la cuiburi se adună.", source: "Mihai Eminescu, Somnoroase păsărele", theme: .peace, subtheme: .atEase),
        Passage(text: "Lacul codrilor albastru / Nuferi galbeni îl încarcă.", source: "Mihai Eminescu, Lacul", theme: .peace, subtheme: .atEase),
        Passage(text: "Chef vine din turcescul keyf, care numește starea bună a omului. Româna a ținut și starea, și petrecerea făcută pentru ea.", source: "Turcă", theme: .peace, subtheme: .atEase),
        Passage(text: "Taifasul este vorba fără treabă. Se stă la taifas: nu se face, nu se duce la capăt și nu se ține minte.", source: "Definiție", theme: .peace, subtheme: .atEase),
        Passage(text: "Agale se spune doar despre un mers care nu are unde ajunge. Nimeni nu aleargă agale.", source: "Lexic", theme: .peace, subtheme: .atEase),
        Passage(text: "A se lăfăi este a lua mai mult loc decât îți trebuie, într-un fel pe care nimeni nu îl ia în nume de rău.", source: "Definiție", theme: .peace, subtheme: .atEase),
        Passage(text: "La țară se spune să nu dormi sub nuc. Frunza lui lasă în sol o substanță care oprește alte plante să crească dedesubt.", source: "Juglans regia", theme: .peace, subtheme: .atEase),
        Passage(text: "Odihna scurtă de după prânz se cheamă un pui de somn: nu o bucată dintr-un somn întreg, ci un exemplar mic al lui.", source: "Expresie", theme: .peace, subtheme: .atEase),
        Passage(text: "Cerdac vine din turcescul çardak. Este încăperea fără pereți din fața casei, locul unde se stă atunci când nu se face nimic.", source: "Arhitectură", theme: .peace, subtheme: .atEase),
        Passage(text: "Vreme înseamnă deopotrivă timpul care trece și starea cerului. Cine zice am vreme și cine zice e vreme bună folosesc același cuvânt slav.", source: "Omonimie", theme: .peace, subtheme: .atEase),
        Passage(text: "Senin vine din latinescul serenus și se pune numai pe două lucruri: pe cerul fără nor și pe fruntea unui om.", source: "Latină", theme: .peace, subtheme: .atEase),
        Passage(text: "La amiază, oile se strâng cap la cap și rămân nemișcate, fiecare la umbra celeilalte, până când soarele coboară.", source: "Păstorit", theme: .peace, subtheme: .atEase),
    ]
}
