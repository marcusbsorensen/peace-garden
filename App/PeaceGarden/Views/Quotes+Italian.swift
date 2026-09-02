import Foundation

/// The Italian bank: three hundred passages written for Italian rather than
/// carried across from `Quotes.all`.
///
/// The English bank leans hard on facts about English — that *quiet* and *quit*
/// are one word, that a daisy is the day's eye — and those are not true in
/// Italian, so they are gone, and Italian's own word histories stand where they
/// were. *Pace* beside *pagare* and *patto*; *margherita* named for the pearl;
/// *negozio* as the plain absence of *otium*; *letame* built on the Latin word
/// for glad. Italian has an advantage here that few languages have, which is
/// that Latin is not foreign to it: an etymology can be laid out without ever
/// leaving the language, and half of it is already on the page.
///
/// The quotations are Italian wherever they can be, in the original — Dante,
/// Petrarca, Boccaccio, Ariosto, Leopardi, Manzoni, Pascoli, Carducci, the
/// *Cantico* of Francis, Leonardo's notebooks — along with the proverbs, which
/// belong to nobody and are credited that way. Where a line comes from
/// elsewhere it is either a public-domain Italian translation with its
/// translator named, or it is rendered plainly here and the source says so:
/// *resa in forma piana*.
///
/// The binding rules from `Quotes.swift` hold without change. Every named author
/// is long out of copyright; every definition, etymology and fact is written
/// from scratch rather than lifted; nothing is here that could not be
/// established. So is the register: a line or two, a terse source, offered
/// rather than taught, and the informal *tu* throughout, because the app is
/// speaking to one person about one plant.
extension Quotes {
    static let italian: [Passage] = [

        // MARK: Beginnings

        Passage(
            text: "Germinazione: il momento in cui un seme smette di essere una riserva e comincia a essere una pianta. Non si torna indietro.",
            source: "Botanica",
            theme: .beginnings,
            subtheme: .theFirstAct
        ),
        Passage(
            text: "Imbibizione: il primo atto di un seme che germina, che è semplicemente bere. Finché l'acqua non è entrata non cresce niente.",
            source: "Botanica",
            theme: .beginnings,
            subtheme: .theFirstAct
        ),
        Passage(
            text: "Radichetta: la prima radice, e la prima cosa a uscire dal seme. Qualcosa scende prima che qualcosa salga.",
            source: "Botanica",
            theme: .beginnings,
            subtheme: .theFirstAct
        ),
        Passage(
            text: "Cotiledone: la foglia del seme, preparata quando non c'era ancora luce da cercare, e spesso per niente somigliante alle foglie che vengono dopo.",
            source: "Botanica",
            theme: .beginnings,
            subtheme: .theFirstAct
        ),
        Passage(
            text: "Meristema: la piccola zona dove le cellule di una pianta si stanno ancora dividendo. Tutto quello che sarà esce da poche di queste.",
            source: "Botanica",
            theme: .beginnings,
            subtheme: .theFirstAct
        ),
        Passage(
            text: "Una plantula stabilisce dov'è l'alto e dov'è il basso prima ancora di aver toccato la superficie: una parte segue la luce, l'altra segue il peso.",
            source: "Tropismi",
            theme: .beginnings,
            subtheme: .theFirstAct
        ),
        Passage(
            text: "Germe e germano vengono dalla stessa parola latina. Il seme che spunta e il fratello di padre e madre si chiamano allo stesso modo.",
            source: "Latino",
            theme: .beginnings,
            subtheme: .theFirstAct
        ),
        Passage(
            text: "Sbocciare viene da boccia, il bocciolo. In italiano fiorire è uscire da una piccola scatola chiusa.",
            source: "Italiano",
            theme: .beginnings,
            subtheme: .theFirstAct
        ),
        Passage(
            text: "Nelle piante a fiore la fecondazione avviene due volte insieme: da una parte nasce l'embrione, dall'altra la dispensa di cibo che gli sta intorno.",
            source: "Doppia fecondazione",
            theme: .beginnings,
            subtheme: .theFirstAct
        ),
        Passage(
            text: "Un granello di polline arrivato sullo stimma fa crescere un tubo che può essere lungo molti centimetri, e tutto questo solo per raggiungere l'ovulo.",
            source: "Tubo pollinico",
            theme: .beginnings,
            subtheme: .theFirstAct
        ),

        Passage(
            text: "Poca favilla gran fiamma seconda.",
            source: "Dante, Paradiso I",
            theme: .beginnings,
            subtheme: .smallToLarge
        ),
        Passage(
            text: "Una ghianda sepolta da una ghiandaia ha più probabilità di diventare quercia di una che semplicemente cade: l'uccello la porta lontano dalla pianta madre, e poi ne dimentica parecchie.",
            source: "Garrulus glandarius",
            theme: .beginnings,
            subtheme: .smallToLarge
        ),
        Passage(
            text: "Il seme più pesante è quello del coco de mer, fino a venticinque chili. I più leggeri sono quelli delle orchidee: ne serve un milione per fare un grammo.",
            source: "Estremi della misura di un seme",
            theme: .beginnings,
            subtheme: .smallToLarge
        ),
        Passage(
            text: "Il seme di orchidea è fine come polvere e non porta con sé quasi niente da mangiare. Ogni granello aspetta un fungo che lo nutra fino alla vita.",
            source: "Orchidaceae",
            theme: .beginnings,
            subtheme: .smallToLarge
        ),
        Passage(
            text: "Un germoglio di bambù può crescere quasi un metro in un giorno, adoperando cellule già pronte prima ancora di aver bucato la terra.",
            source: "Phyllostachys",
            theme: .beginnings,
            subtheme: .smallToLarge
        ),
        Passage(
            text: "L'albero che riempie le braccia è cresciuto da un germoglio sottilissimo.",
            source: "Laozi, resa in forma piana",
            theme: .beginnings,
            subtheme: .smallToLarge
        ),
        Passage(
            text: "Vedere un mondo in un granello di sabbia, e un cielo in un fiore di campo.",
            source: "William Blake (1757–1827), resa in forma piana",
            theme: .beginnings,
            subtheme: .smallToLarge
        ),
        Passage(
            text: "La pigna del pino domestico impiega tre anni a maturare: si forma in una primavera e lascia andare i pinoli nella terza.",
            source: "Pinus pinea",
            theme: .beginnings,
            subtheme: .smallToLarge
        ),
        Passage(
            text: "In un grammo di semi di papavero ce ne sono diverse migliaia, e ciascuno porta dentro di sé una pianta alta un metro.",
            source: "Papaver",
            theme: .beginnings,
            subtheme: .smallToLarge
        ),
        Passage(
            text: "Da cosa nasce cosa.",
            source: "Proverbio",
            theme: .beginnings,
            subtheme: .smallToLarge
        ),

        Passage(
            text: "Considerate la vostra semenza: fatti non foste a viver come bruti.",
            source: "Dante, Inferno XXVI",
            theme: .beginnings,
            subtheme: .whatAStartSettles
        ),
        Passage(
            text: "Chi ben comincia è a metà dell'opera.",
            source: "Proverbio",
            theme: .beginnings,
            subtheme: .whatAStartSettles
        ),
        Passage(
            text: "Il buon giorno si vede dal mattino.",
            source: "Proverbio",
            theme: .beginnings,
            subtheme: .whatAStartSettles
        ),
        Passage(
            text: "Il principio è la parte più importante di tutto il lavoro.",
            source: "Platone, Repubblica, resa in forma piana",
            theme: .beginnings,
            subtheme: .whatAStartSettles
        ),
        Passage(
            text: "Seme, semenza, seminario e disseminare scendono tutti dal latino semen. Un seminario era un semenzaio.",
            source: "Latino",
            theme: .beginnings,
            subtheme: .whatAStartSettles
        ),
        Passage(
            text: "Origine viene dal latino oriri, sorgere. La stessa parola dà oriente, chiamato così per la direzione da cui il sole si alza.",
            source: "Latino",
            theme: .beginnings,
            subtheme: .whatAStartSettles
        ),
        Passage(
            text: "Natura viene da nasci, nascere. La parola per tutto quanto è costruita sulla parola per cominciare.",
            source: "Latino",
            theme: .beginnings,
            subtheme: .whatAStartSettles
        ),
        Passage(
            text: "Auguri viene da augurium, la lettura del volo degli uccelli. Ogni volta che fai gli auguri a qualcuno stai prendendo un presagio per lui.",
            source: "Latino",
            theme: .beginnings,
            subtheme: .whatAStartSettles
        ),
        Passage(
            text: "Semina il seme di una mela qualsiasi e quello che nasce è una varietà nuova di zecca. Per questo le mele che hanno un nome viaggiano come innesti.",
            source: "Malus domestica",
            theme: .beginnings,
            subtheme: .whatAStartSettles
        ),
        Passage(
            text: "Il grano trovato nelle tombe egizie non è germogliato nemmeno una volta. Le storie sono antiche, le prove sono state molte, e sono fallite tutte.",
            source: "Il grano delle mummie",
            theme: .beginnings,
            subtheme: .whatAStartSettles
        ),
        Passage(
            text: "Chi non risica non rosica.",
            source: "Proverbio",
            theme: .beginnings,
            subtheme: .whatAStartSettles
        ),
        Passage(
            text: "La fortuna aiuta gli audaci.",
            source: "Virgilio, Eneide, resa in forma piana",
            theme: .beginnings,
            subtheme: .whatAStartSettles
        ),

        // MARK: Waiting

        Passage(
            text: "Dormienza: un seme che si rifiuta di crescere anche se le condizioni ci sono, trattenuto dall'interno finché qualcosa non cambia.",
            source: "Botanica",
            theme: .waiting,
            subtheme: .heldBack
        ),
        Passage(
            text: "Quiescenza: un seme pronto in tutto e per tutto, che aspetta soltanto il mondo. Non è la stessa cosa della dormienza, e viene scambiata per quella di continuo.",
            source: "Botanica",
            theme: .waiting,
            subtheme: .heldBack
        ),
        Passage(
            text: "Stratificazione: le settimane di freddo che un seme deve attraversare prima di partire, e che il giardiniere contraffà con il frigorifero.",
            source: "Botanica",
            theme: .waiting,
            subtheme: .heldBack
        ),
        Passage(
            text: "Scarificazione: consumare il tegumento di un seme perché l'acqua possa entrare. In natura lo fanno un intestino, un incendio, o un inverno di ghiaia.",
            source: "Botanica",
            theme: .waiting,
            subtheme: .heldBack
        ),
        Passage(
            text: "Vernalizzazione: il lungo freddo che un seme o una gemma attraversa, dopo il quale la primavera è finalmente in grado di muoverli.",
            source: "Botanica",
            theme: .waiting,
            subtheme: .heldBack
        ),
        Passage(
            text: "Marcescenza: le foglie morte che un albero si tiene addosso tutto l'inverno e lascia andare solo quando le gemme nuove le spingono via.",
            source: "Botanica",
            theme: .waiting,
            subtheme: .heldBack
        ),
        Passage(
            text: "Certi semi del deserto portano sul tegumento una sostanza che la pioggia deve lavare via fino a una certa profondità, così che un acquazzone leggero non possa ingannarli.",
            source: "Inibitori della germinazione",
            theme: .waiting,
            subtheme: .heldBack
        ),
        Passage(
            text: "Nella macchia mediterranea molti semi restano duri e chiusi finché non passa il fuoco. Il calore è la chiave, e a volte è l'unica.",
            source: "Macchia mediterranea",
            theme: .waiting,
            subtheme: .heldBack
        ),
        Passage(
            text: "Aspettare è il latino ad spectare, guardare verso. Prima di essere una forma di pazienza era una forma di sguardo.",
            source: "Latino",
            theme: .waiting,
            subtheme: .heldBack
        ),
        Passage(
            text: "Attendere è ad tendere, tendere verso. Chi attende non sta fermo: sta teso in una direzione.",
            source: "Latino",
            theme: .waiting,
            subtheme: .heldBack
        ),
        Passage(
            text: "Dietro indugiare c'è il latino dubitare, esitare fra due. Un indugio è una cosa che sta ancora fra due possibilità.",
            source: "Latino",
            theme: .waiting,
            subtheme: .heldBack
        ),

        Passage(
            text: "Il titano fa provviste per sette anni e più prima di fiorire, e il fiore dura circa due giorni.",
            source: "Amorphophallus titanum",
            theme: .waiting,
            subtheme: .theLongCount
        ),
        Passage(
            text: "L'agave si chiama pianta del secolo per esagerazione, ma non per molta: cresce per decenni, fiorisce una volta sola su uno stelo più alto di una casa, e muore.",
            source: "Agave americana",
            theme: .waiting,
            subtheme: .theLongCount
        ),
        Passage(
            text: "Le cicale periodiche stanno sottoterra tredici o diciassette anni e salgono tutte insieme. Sono due numeri primi, e questo le rende difficilissime da aspettare al varco.",
            source: "Magicicada",
            theme: .waiting,
            subtheme: .theLongCount
        ),
        Passage(
            text: "Un seme di dattero trovato a Masada, vecchio di circa duemila anni, è stato seminato nel 2005 ed è cresciuto. L'albero si chiama Matusalemme.",
            source: "Phoenix dactylifera, Israele",
            theme: .waiting,
            subtheme: .theLongCount
        ),
        Passage(
            text: "In Siberia certi scoiattoli avevano interrato dei frutti trentaduemila anni fa. Nel 2012, dal tessuto rimasto dentro, sono state fatte crescere piante intere, che hanno fiorito.",
            source: "Silene stenophylla, PNAS 2012",
            theme: .waiting,
            subtheme: .theLongCount
        ),
        Passage(
            text: "Un seme di loto sacro raccolto da un antico fondo di lago nel Liaoning è germogliato dopo circa milletrecento anni, e la pianta è viva ancora.",
            source: "Nelumbo nucifera",
            theme: .waiting,
            subtheme: .theLongCount
        ),
        Passage(
            text: "Nel 1879 certi semi furono chiusi in bottiglie e sepolti. Una bottiglia aperta nel 2021 conteneva semi di verbasco che si sono svegliati e sono cresciuti.",
            source: "Esperimento di Beal, Michigan",
            theme: .waiting,
            subtheme: .theLongCount
        ),
        Passage(
            text: "Certi bambù fioriscono una volta sola, tutti insieme, in tutto il mondo, dopo più di un secolo. Piante venute da uno stesso ceppo tengono lo stesso orologio.",
            source: "Phyllostachys bambusoides",
            theme: .waiting,
            subtheme: .theLongCount
        ),
        Passage(
            text: "Un olivo comincia a dare frutto verso il quinto anno, e in Puglia e in Sardegna ce ne sono che ne danno ancora dopo un migliaio.",
            source: "Olea europaea",
            theme: .waiting,
            subtheme: .theLongCount
        ),
        Passage(
            text: "Il Castagno dei Cento Cavalli, sull'Etna, prende il nome da una regina che vi si sarebbe riparata con cento cavalieri durante un temporale. L'albero c'è ancora.",
            source: "Castanea sativa, Sant'Alfio",
            theme: .waiting,
            subtheme: .theLongCount
        ),
        Passage(
            text: "Le palafitte su cui sta Venezia sono di legno e reggono da secoli proprio perché stanno sott'acqua, dove l'aria non arriva a farle marcire.",
            source: "Fondazioni lagunari",
            theme: .waiting,
            subtheme: .theLongCount
        ),

        Passage(
            text: "Se son rose, fioriranno.",
            source: "Proverbio",
            theme: .waiting,
            subtheme: .standingAndWatching
        ),
        Passage(
            text: "Ogni frutto vuole la sua stagione.",
            source: "Proverbio",
            theme: .waiting,
            subtheme: .standingAndWatching
        ),
        Passage(
            text: "La notte porta consiglio.",
            source: "Proverbio",
            theme: .waiting,
            subtheme: .standingAndWatching
        ),
        Passage(
            text: "Roma non fu fatta in un giorno.",
            source: "Proverbio",
            theme: .waiting,
            subtheme: .standingAndWatching
        ),
        Passage(
            text: "Chi ha tempo non aspetti tempo.",
            source: "Proverbio",
            theme: .waiting,
            subtheme: .standingAndWatching
        ),
        Passage(
            text: "Questo di sette è il più gradito giorno, pien di speme e di gioia.",
            source: "Giacomo Leopardi, Il sabato del villaggio",
            theme: .waiting,
            subtheme: .standingAndWatching
        ),
        Passage(
            text: "Nel campo mezzo grigio e mezzo nero resta un aratro senza buoi, che pare dimenticato.",
            source: "Giovanni Pascoli, Lavandare",
            theme: .waiting,
            subtheme: .standingAndWatching
        ),
        Passage(
            text: "La nebbia a gl'irti colli piovigginando sale.",
            source: "Giosuè Carducci, San Martino",
            theme: .waiting,
            subtheme: .standingAndWatching
        ),
        Passage(
            text: "Io son da l'aspettar omai sì stanca.",
            source: "Gaspara Stampa (1523–1554), Rime",
            theme: .waiting,
            subtheme: .standingAndWatching
        ),
        Passage(
            text: "La vita fugge, et non s'arresta una hora.",
            source: "Petrarca, Canzoniere 272",
            theme: .waiting,
            subtheme: .standingAndWatching
        ),
        Passage(
            text: "Paziente viene dal latino patiens, che sopporta. Il paziente in ospedale e la pazienza in fila sono la stessa parola che fa lo stesso lavoro.",
            source: "Latino",
            theme: .waiting,
            subtheme: .standingAndWatching
        ),
        Passage(
            text: "Il concime migliore è l'ombra del contadino.",
            source: "Proverbio contadino",
            theme: .waiting,
            subtheme: .standingAndWatching
        ),
        Passage(
            text: "Magari viene dal greco makários, beato. La parola con cui l'italiano dice sarebbe bello era, all'origine, l'augurio di essere felice.",
            source: "Greco",
            theme: .waiting,
            subtheme: .standingAndWatching
        ),
        Passage(
            text: "Una generazione pianta gli alberi, un'altra si siede all'ombra.",
            source: "Proverbio cinese, resa in forma piana",
            theme: .waiting,
            subtheme: .standingAndWatching
        ),

        // MARK: Renewal

        Passage(
            text: "Ceduo: un bosco tagliato a turno, che per questo non finisce ma ricomincia. Una ceppaia può essere tenuta viva per secoli.",
            source: "Selvicoltura",
            theme: .renewal,
            subtheme: .cutAndComeAgain
        ),
        Passage(
            text: "Talea: un pezzo di ramo messo nella terra, che si convince di essere una pianta intera e si rifà le radici da capo.",
            source: "Giardinaggio",
            theme: .renewal,
            subtheme: .cutAndComeAgain
        ),
        Passage(
            text: "Propaggine: un tralcio piegato dentro la terra che mette radici mentre è ancora attaccato alla madre. Da qui viene propagare.",
            source: "Viticoltura",
            theme: .renewal,
            subtheme: .cutAndComeAgain
        ),
        Passage(
            text: "Pollone: il germoglio che parte dal piede di una pianta tagliata. L'albero non ricomincia dall'alto ma dal basso.",
            source: "Botanica",
            theme: .renewal,
            subtheme: .cutAndComeAgain
        ),
        Passage(
            text: "Serotinia: il seme tenuto dentro un cono sigillato di resina, che si apre soltanto nel calore di un incendio.",
            source: "Botanica",
            theme: .renewal,
            subtheme: .cutAndComeAgain
        ),
        Passage(
            text: "Epicormico: la crescita da gemme che hanno aspettato anni sotto la corteccia e si svegliano quando la chioma sopra di loro va perduta.",
            source: "Botanica",
            theme: .renewal,
            subtheme: .cutAndComeAgain
        ),
        Passage(
            text: "Le graminacee crescono dalla base e non dalla punta: per questo falciare non uccide un prato, e uccide quasi tutto quello che prova a dividerselo.",
            source: "Poaceae",
            theme: .renewal,
            subtheme: .cutAndComeAgain
        ),
        Passage(
            text: "Sei ginkgo rimasti in piedi a due chilometri dallo scoppio di Hiroshima hanno rimesso le foglie l'anno dopo, e sono vivi oggi.",
            source: "Hibakujumoku, Hiroshima",
            theme: .renewal,
            subtheme: .cutAndComeAgain
        ),
        Passage(
            text: "Dopo l'eruzione del Monte Sant'Elena, nel 1980, le prime piante a tornare non furono coloni in arrivo ma sopravvissuti che al momento dello scoppio stavano sottoterra o sotto la neve.",
            source: "Monte Sant'Elena, 1980",
            theme: .renewal,
            subtheme: .cutAndComeAgain
        ),
        Passage(
            text: "Potare viene dal latino putare, che voleva dire mondare una pianta e anche fare i conti. Di lì escono computare, reputare e disputare: pensare, per i romani, era una specie di potatura.",
            source: "Latino",
            theme: .renewal,
            subtheme: .cutAndComeAgain
        ),
        Passage(
            text: "L'olivo si innesta sull'oleastro, il suo parente selvatico. Sotto quasi ogni olivo coltivato c'è un piede che nessuno ha mai addomesticato.",
            source: "Olea europaea",
            theme: .renewal,
            subtheme: .cutAndComeAgain
        ),
        Passage(
            text: "Un gelso capitozzato resta nudo come un pugno chiuso e in una stagione rimette una chioma intera. Intere campagne lombarde sono state disegnate da questa abitudine.",
            source: "Morus alba",
            theme: .renewal,
            subtheme: .cutAndComeAgain
        ),

        Passage(
            text: "Zephiro torna, e 'l bel tempo rimena.",
            source: "Petrarca, Canzoniere 310",
            theme: .renewal,
            subtheme: .theTurningYear
        ),
        Passage(
            text: "Ben venga maggio e 'l gonfalon selvaggio!",
            source: "Angelo Poliziano (1454–1494)",
            theme: .renewal,
            subtheme: .theTurningYear
        ),
        Passage(
            text: "Passata è la tempesta: odo augelli far festa.",
            source: "Giacomo Leopardi, La quiete dopo la tempesta",
            theme: .renewal,
            subtheme: .theTurningYear
        ),
        Passage(
            text: "Gemmea l'aria, il sole così chiaro che tu ricerchi gli albicocchi in fiore.",
            source: "Giovanni Pascoli, Novembre",
            theme: .renewal,
            subtheme: .theTurningYear
        ),
        Passage(
            text: "D'aprile vi dono la gentil campagna, tutta fiorita di bell'erba fresca.",
            source: "Folgóre da San Gimignano, Sonetti dei mesi",
            theme: .renewal,
            subtheme: .theTurningYear
        ),
        Passage(
            text: "Ogni cosa ha la sua stagione, ed ogni azione sotto il cielo ha il suo tempo.",
            source: "Ecclesiaste, tr. Giovanni Diodati, 1607",
            theme: .renewal,
            subtheme: .theTurningYear
        ),
        Passage(
            text: "Una rondine non fa primavera.",
            source: "Proverbio",
            theme: .renewal,
            subtheme: .theTurningYear
        ),
        Passage(
            text: "Marzo pazzerello: guarda il sole e prendi l'ombrello.",
            source: "Proverbio",
            theme: .renewal,
            subtheme: .theTurningYear
        ),
        Passage(
            text: "Primavera viene da prima vera, il principio del ver latino, che era il nome della stagione. La parola dice che è un inizio, non una cosa in sé.",
            source: "Latino",
            theme: .renewal,
            subtheme: .theTurningYear
        ),
        Passage(
            text: "Vendemmia è vinum più demere, togliere via. La parola descrive il gesto di levare il grappolo, non quello di fare il vino.",
            source: "Latino",
            theme: .renewal,
            subtheme: .theTurningYear
        ),
        Passage(
            text: "Gli alberi a foglia caduca si riprendono l'azoto e il fosforo dalle foglie prima di lasciarle andare. Il colore d'autunno è quello che resta dopo che la parte di valore è stata ritirata.",
            source: "Senescenza fogliare",
            theme: .renewal,
            subtheme: .theTurningYear
        ),
        Passage(
            text: "Per San Benedetto, la rondine è sotto il tetto.",
            source: "Proverbio",
            theme: .renewal,
            subtheme: .theTurningYear
        ),

        Passage(
            text: "Bocca baciata non perde ventura, anzi rinnova come fa la luna.",
            source: "Boccaccio, Decameron II",
            theme: .renewal,
            subtheme: .madeWhole
        ),
        Passage(
            text: "Il giorno fu pieno di lampi; ma ora verranno le stelle.",
            source: "Giovanni Pascoli, La mia sera",
            theme: .renewal,
            subtheme: .madeWhole
        ),
        Passage(
            text: "Ristorare e restaurare sono la stessa parola latina entrata due volte in italiano: una per bocca, una per libro. Un ristorante è un posto che ti rimette a posto.",
            source: "Latino",
            theme: .renewal,
            subtheme: .madeWhole
        ),
        Passage(
            text: "Guarire non è latino ma germanico, e dietro c'è un verbo che voleva dire difendere. In italiano si guarisce come ci si ripara.",
            source: "Germanico",
            theme: .renewal,
            subtheme: .madeWhole
        ),
        Passage(
            text: "Rinascimento è il latino renasci, nascere di nuovo. Il nome dell'epoca è stato preso in prestito da quello che fa una pianta.",
            source: "Latino",
            theme: .renewal,
            subtheme: .madeWhole
        ),
        Passage(
            text: "Risorgimento vuol dire, alla lettera, un alzarsi di nuovo. La parola era della resurrezione molto prima di essere della politica.",
            source: "Italiano",
            theme: .renewal,
            subtheme: .madeWhole
        ),
        Passage(
            text: "Kintsugi: riparare la ceramica rotta con l'oro, così che l'aggiustatura diventi la cosa più visibile della ciotola.",
            source: "Giapponese",
            theme: .renewal,
            subtheme: .madeWhole
        ),
        Passage(
            text: "Rimedio viene da mederi, prendersi cura. La stessa radice dà medico: il rimedio è l'attenzione prima di essere la medicina.",
            source: "Latino",
            theme: .renewal,
            subtheme: .madeWhole
        ),
        Passage(
            text: "Convalescenza è con più valescere, farsi forte. Il con è lì per insistenza più che per compagnia, anche se rimettersi in due non è una cosa brutta da sentirci dentro.",
            source: "Latino",
            theme: .renewal,
            subtheme: .madeWhole
        ),
        Passage(
            text: "Anastasi: un rialzarsi in piedi. I biologi l'hanno presa in prestito dal greco per le cellule che cominciano a morire e poi si riprendono.",
            source: "Greco",
            theme: .renewal,
            subtheme: .madeWhole
        ),
        Passage(
            text: "Cadere sette volte, rialzarsi otto.",
            source: "Proverbio giapponese, resa in forma piana",
            theme: .renewal,
            subtheme: .madeWhole
        ),
        Passage(
            text: "Il tempo è galantuomo.",
            source: "Proverbio",
            theme: .renewal,
            subtheme: .madeWhole
        ),

        // MARK: Light

        Passage(
            text: "Era già l'ora che volge il disio ai naviganti e 'ntenerisce il core.",
            source: "Dante, Purgatorio VIII",
            theme: .light,
            subtheme: .theEdgesOfTheDay
        ),
        Passage(
            text: "Dolce e chiara è la notte e senza vento.",
            source: "Giacomo Leopardi, La sera del dì di festa",
            theme: .light,
            subtheme: .theEdgesOfTheDay
        ),
        Passage(
            text: "E s'aprono i fiori notturni, nell'ora che penso a' miei cari.",
            source: "Giovanni Pascoli, Il gelsomino notturno",
            theme: .light,
            subtheme: .theEdgesOfTheDay
        ),
        Passage(
            text: "Forse perché della fatal quïete tu sei l'immago, a me sì cara vieni, o Sera!",
            source: "Ugo Foscolo, Alla sera",
            theme: .light,
            subtheme: .theEdgesOfTheDay
        ),
        Passage(
            text: "Dolce color d'orïental zaffiro.",
            source: "Dante, Purgatorio I",
            theme: .light,
            subtheme: .theEdgesOfTheDay
        ),
        Passage(
            text: "Crepuscolo viene dal latino creper, incerto. È l'ora che porta il nome del non vedere bene.",
            source: "Latino",
            theme: .light,
            subtheme: .theEdgesOfTheDay
        ),
        Passage(
            text: "Alba viene da albus, bianco. Il primo momento del giorno prende il nome dal suo colore, prima ancora di avere una luce.",
            source: "Latino",
            theme: .light,
            subtheme: .theEdgesOfTheDay
        ),
        Passage(
            text: "Tramonto è trans montem, al di là del monte. Il sole non cala: passa dietro qualcosa.",
            source: "Latino",
            theme: .light,
            subtheme: .theEdgesOfTheDay
        ),
        Passage(
            text: "Imbrunire: il verbo per quello che fa la sera. Non è la luce che se ne va, è tutto il resto che diventa scuro.",
            source: "Italiano",
            theme: .light,
            subtheme: .theEdgesOfTheDay
        ),
        Passage(
            text: "Vespro viene da vesper, la stella della sera, che è poi lo stesso pianeta della stella del mattino. La preghiera dell'imbrunire porta il nome di Venere.",
            source: "Latino",
            theme: .light,
            subtheme: .theEdgesOfTheDay
        ),
        Passage(
            text: "Penombra è paene umbra, quasi ombra: l'anello intorno a un'ombra dove la luce è fermata solo in parte, ed è per questo che i bordi sono morbidi.",
            source: "Latino",
            theme: .light,
            subtheme: .theEdgesOfTheDay
        ),
        Passage(
            text: "Per Santa Lucia il giorno più corto che ci sia. Il proverbio era esatto prima della riforma del calendario, e da allora è in anticipo di una decina di giorni.",
            source: "Proverbio",
            theme: .light,
            subtheme: .theEdgesOfTheDay
        ),
        Passage(
            text: "Controluce: guardare una cosa avendo la luce dietro di essa. Si perde il colore e si guadagna la forma.",
            source: "Italiano",
            theme: .light,
            subtheme: .theEdgesOfTheDay
        ),

        Passage(
            text: "Fotoperiodismo: una pianta decide quando fiorire misurando la lunghezza della notte. Conta il buio, non la luce.",
            source: "Botanica",
            theme: .light,
            subtheme: .readingTheLight
        ),
        Passage(
            text: "Eziolamento: la crescita pallida e allungata di una pianta tenuta al buio, protesa verso una luce che non c'è.",
            source: "Botanica",
            theme: .light,
            subtheme: .readingTheLight
        ),
        Passage(
            text: "Le foglie sono verdi perché la clorofilla adopera il rosso e il blu del giorno e rimanda indietro il verde. Una pianta ha il colore della luce di cui non sa che farsi.",
            source: "Clorofilla",
            theme: .light,
            subtheme: .readingTheLight
        ),
        Passage(
            text: "Eliotropismo: il girare di una pianta lungo il giorno per tenere la faccia rivolta al sole.",
            source: "Botanica",
            theme: .light,
            subtheme: .readingTheLight
        ),
        Passage(
            text: "Nictinastia: il chiudersi delle foglie e dei petali all'imbrunire, e il loro riaprirsi con la luce.",
            source: "Botanica",
            theme: .light,
            subtheme: .readingTheLight
        ),
        Passage(
            text: "Antesi: il tempo della vita di un fiore in cui sta aperto.",
            source: "Botanica",
            theme: .light,
            subtheme: .readingTheLight
        ),
        Passage(
            text: "I girasoli giovani seguono il sole verso ponente e tornano a levante durante la notte. Da grandi si fermano guardando a levante, dove il caldo del mattino fa arrivare le api prima.",
            source: "Science, 2016",
            theme: .light,
            subtheme: .readingTheLight
        ),
        Passage(
            text: "Girasole è una parola italiana che ha fatto il giro del mondo storpiata: gli inglesi la sentirono, non la capirono, e chiamarono il topinambur carciofo di Gerusalemme.",
            source: "Helianthus tuberosus",
            theme: .light,
            subtheme: .readingTheLight
        ),
        Passage(
            text: "Molti fiori portano segni ultravioletti che corrono verso il centro come una pista d'atterraggio. Un'ape li vede e noi no.",
            source: "Guide del nettare",
            theme: .light,
            subtheme: .readingTheLight
        ),
        Passage(
            text: "Sul fondo di un bosco arriva solo qualche punto per cento della luce che cade sulle chiome. Per questo tanta fioritura del sottobosco è già finita quando gli alberi mettono le foglie.",
            source: "Chioma forestale",
            theme: .light,
            subtheme: .readingTheLight
        ),
        Passage(
            text: "Il tornasole prende il nome dal girarsi verso il sole, e la carta che cambia colore prende il nome dalla pianta.",
            source: "Italiano",
            theme: .light,
            subtheme: .readingTheLight
        ),
        Passage(
            text: "Nella lucciola quasi tutta l'energia spesa diventa luce invece che calore, e questo è precisamente quello che nessuna lampada da noi costruita sa ancora fare.",
            source: "Lampyridae",
            theme: .light,
            subtheme: .readingTheLight
        ),
        Passage(
            text: "Margherita viene dal greco margarites, perla. Il fiore prende il nome da una pietra e non dalla luce, anche se della luce fa il suo mestiere: si apre col giorno e si chiude all'imbrunire.",
            source: "Greco",
            theme: .light,
            subtheme: .readingTheLight
        ),

        Passage(
            text: "E quindi uscimmo a riveder le stelle.",
            source: "Dante, Inferno XXXIV",
            theme: .light,
            subtheme: .lightItself
        ),
        Passage(
            text: "Laudato si', mi' Signore, cum tucte le tue creature, spetialmente messor lo frate Sole.",
            source: "Francesco d'Assisi, Cantico delle creature",
            theme: .light,
            subtheme: .lightItself
        ),
        Passage(
            text: "Lume non è, se non vien dal sereno che non si turba mai.",
            source: "Dante, Paradiso XIX",
            theme: .light,
            subtheme: .lightItself
        ),
        Passage(
            text: "Il sole non vide mai nessuna ombra.",
            source: "Leonardo da Vinci (1452–1519)",
            theme: .light,
            subtheme: .lightItself
        ),
        Passage(
            text: "Che fai tu, luna, in ciel? dimmi, che fai, silenziosa luna?",
            source: "Giacomo Leopardi, Canto notturno",
            theme: .light,
            subtheme: .lightItself
        ),
        Passage(
            text: "Sia la luce. E la luce fu.",
            source: "Genesi, tr. Giovanni Diodati, 1607",
            theme: .light,
            subtheme: .lightItself
        ),
        Passage(
            text: "Lucciola vuol dire piccola luce. Prendere lucciole per lanterne è il modo di dire italiano per l'inganno che ti prendi da solo.",
            source: "Italiano",
            theme: .light,
            subtheme: .lightItself
        ),
        Passage(
            text: "Solstizio è sol più sistere, il sole che sta fermo: per qualche giorno, a mezza estate, sorge quasi nello stesso punto.",
            source: "Latino",
            theme: .light,
            subtheme: .lightItself
        ),
        Passage(
            text: "Chiaroscuro e sfumato sono parole italiane che il resto del mondo ha preso così com'erano. La seconda è di Leonardo, e vuol dire senza contorni, come il fumo.",
            source: "Italiano",
            theme: .light,
            subtheme: .lightItself
        ),
        Passage(
            text: "La luce arriva dal sole a una foglia in circa otto minuti, dopo aver messo decine di migliaia di anni per uscire dal centro del sole e raggiungerne la superficie.",
            source: "Fisica solare",
            theme: .light,
            subtheme: .lightItself
        ),
        Passage(
            text: "La luna piena è circa quattrocentomila volte più debole del sole, e l'occhio si adatta talmente bene che non te ne accorgi affatto.",
            source: "Illuminazione lunare",
            theme: .light,
            subtheme: .lightItself
        ),
        Passage(
            text: "Considerare è cum sidere, con le stelle; desiderare è de sidere, dalle stelle. Pensarci bene è consultarle, desiderare è sentirne la mancanza.",
            source: "Latino",
            theme: .light,
            subtheme: .lightItself
        ),

        // MARK: Pattern

        Passage(
            text: "Leonardo Fibonacci, pisano, portò in Europa le cifre indo-arabe nel 1202, e per spiegare la sua successione si mise a contare conigli.",
            source: "Liber abaci, 1202",
            theme: .pattern,
            subtheme: .counted
        ),
        Passage(
            text: "Zero e cifra sono la stessa parola araba, sifr, il vuoto, entrata in italiano due volte per due strade diverse.",
            source: "Arabo",
            theme: .pattern,
            subtheme: .counted
        ),
        Passage(
            text: "Le pigne, gli ananas e i capolini delle margherite contano le loro spirali con i numeri di Fibonacci, perché ogni parte nuova si mette nel vuoto più largo lasciato da quelle di prima.",
            source: "Fillotassi",
            theme: .pattern,
            subtheme: .counted
        ),
        Passage(
            text: "Le foglie nuove si dispongono a circa centotrentasette gradi e mezzo dalla precedente: è l'unico angolo con cui ogni foglia conserva una sua parte di luce.",
            source: "Fillotassi, l'angolo aureo",
            theme: .pattern,
            subtheme: .counted
        ),
        Passage(
            text: "Conta le spirali di un capolino di girasole nei due versi e quasi sempre trovi due numeri di Fibonacci vicini, per esempio trentaquattro e cinquantacinque.",
            source: "Helianthus annuus",
            theme: .pattern,
            subtheme: .counted
        ),
        Passage(
            text: "Calcolo viene da calculus, un sassolino. L'italiano ha tenuto tutti e due i sensi: il conto che fai e la pietra che ti porti dentro.",
            source: "Latino",
            theme: .pattern,
            subtheme: .counted
        ),
        Passage(
            text: "Quinconce: cinque come sul dado, quattro agli angoli e uno in mezzo. I frutteti si piantano ancora così perché è il modo di far stare più alberi nella stessa terra.",
            source: "Latino",
            theme: .pattern,
            subtheme: .counted
        ),
        Passage(
            text: "Simmetria è greco per misurato insieme: syn, con, e metron, misura.",
            source: "Greco",
            theme: .pattern,
            subtheme: .counted
        ),
        Passage(
            text: "Ogni storno in uno stormo guarda soltanto i sei o sette vicini più prossimi, qualunque sia la distanza. Non serve altro per fare la forma di tutto il branco.",
            source: "Volo collettivo, 2008",
            theme: .pattern,
            subtheme: .counted
        ),
        Passage(
            text: "D'inverno gli stormi di storni sopra Roma contano centinaia di migliaia di individui, e la sera disegnano figure che nessuno di loro ha in mente.",
            source: "Sturnus vulgaris, Roma",
            theme: .pattern,
            subtheme: .counted
        ),
        Passage(
            text: "Un'ape che torna balla l'angolo dei fiori rispetto al sole, e la lunghezza della sua danza dice alle altre quanto lontano volare.",
            source: "Karl von Frisch",
            theme: .pattern,
            subtheme: .counted
        ),

        Passage(
            text: "Non ha l'ottimo artista alcun concetto ch'un marmo solo in sé non circonscriva.",
            source: "Michelangelo Buonarroti, Rime",
            theme: .pattern,
            subtheme: .fittedTogether
        ),
        Passage(
            text: "Tassellatura: forme che si toccano lato contro lato senza che avanzi niente, che è poi quello che fa un favo.",
            source: "Geometria",
            theme: .pattern,
            subtheme: .fittedTogether
        ),
        Passage(
            text: "Frattale: una forma che tiene lo stesso carattere a ogni scala, così che un pezzo di felce somigli alla felce.",
            source: "Geometria",
            theme: .pattern,
            subtheme: .fittedTogether
        ),
        Passage(
            text: "Decussato: foglie a coppie, ogni coppia girata di un angolo retto rispetto a quella sotto, così che nessuna foglia stia esattamente sopra un'altra.",
            source: "Botanica",
            theme: .pattern,
            subtheme: .fittedTogether
        ),
        Passage(
            text: "Ombrella: un capolino dove ogni peduncolo parte da un solo punto e arriva alla stessa altezza, come fa il finocchio selvatico.",
            source: "Botanica",
            theme: .pattern,
            subtheme: .fittedTogether
        ),
        Passage(
            text: "Le celle delle api cominciano tonde e si assestano in esagoni man mano che la cera si scalda. Un esagono tiene più pavimento con meno muro.",
            source: "Apis mellifera",
            theme: .pattern,
            subtheme: .fittedTogether
        ),
        Passage(
            text: "I sei bracci di un fiocco di neve si somigliano perché sono cresciuti nella stessa aria nello stesso istante, non perché un braccio possa vedere gli altri.",
            source: "Crescita dei cristalli",
            theme: .pattern,
            subtheme: .fittedTogether
        ),
        Passage(
            text: "Combaciare viene da bacio: due cose che si incastrano alla perfezione, in italiano, si stanno baciando.",
            source: "Italiano",
            theme: .pattern,
            subtheme: .fittedTogether
        ),
        Passage(
            text: "Mosaico: un pavimento fatto di tessere, dove nessuna tessera sa che cosa raffigura e tutte insieme lo raffigurano.",
            source: "Italiano",
            theme: .pattern,
            subtheme: .fittedTogether
        ),
        Passage(
            text: "La terza rima è un'invenzione di Dante: ogni terzina lascia in mezzo una rima che apre la terzina dopo, così che il poema non si possa interrompere senza che si senta.",
            source: "Metrica italiana",
            theme: .pattern,
            subtheme: .fittedTogether
        ),
        Passage(
            text: "Le strisce della zebra, le macchie del leopardo e i disegni di un pesce possono nascere tutti da due sostanze che si spargono e reagiscono a velocità diverse, un meccanismo descritto da Alan Turing nel 1952.",
            source: "Modelli di Turing",
            theme: .pattern,
            subtheme: .fittedTogether
        ),
        Passage(
            text: "Il polline porta un guscio scolpito di sporopollenina, tanto duro che nella torba i granelli tengono il loro disegno per migliaia di anni e si possono ancora riconoscere a uno a uno.",
            source: "Palinologia",
            theme: .pattern,
            subtheme: .fittedTogether
        ),
        Passage(
            text: "Radiale e bilaterale: una margherita guarda in tutte le direzioni insieme, un'orchidea guarda te. Quasi ogni fiore è o l'una o l'altra cosa.",
            source: "Simmetria fiorale",
            theme: .pattern,
            subtheme: .fittedTogether
        ),

        Passage(
            text: "La filosofia è scritta in questo grandissimo libro che continuamente ci sta aperto innanzi a gli occhi, ed è scritto in lingua matematica.",
            source: "Galileo Galilei, Il Saggiatore, 1623",
            theme: .pattern,
            subtheme: .orderNamed
        ),
        Passage(
            text: "La sapienza è figliola della sperienzia.",
            source: "Leonardo da Vinci (1452–1519)",
            theme: .pattern,
            subtheme: .orderNamed
        ),
        Passage(
            text: "Il buon senso c'era; ma se ne stava nascosto, per paura del senso comune.",
            source: "Alessandro Manzoni, I promessi sposi",
            theme: .pattern,
            subtheme: .orderNamed
        ),
        Passage(
            text: "Il mondo è bello perché è vario.",
            source: "Proverbio",
            theme: .pattern,
            subtheme: .orderNamed
        ),
        Passage(
            text: "Le note si chiamano do re mi perché Guido d'Arezzo prese le prime sillabe dei versi di un inno a san Giovanni, che salivano di un grado ciascuno.",
            source: "Guido d'Arezzo, XI secolo",
            theme: .pattern,
            subtheme: .orderNamed
        ),
        Passage(
            text: "Il sonetto nasce alla corte siciliana di Federico II e si attribuisce a Giacomo da Lentini. Quattordici versi sono un'invenzione con una data.",
            source: "Scuola siciliana, XIII secolo",
            theme: .pattern,
            subtheme: .orderNamed
        ),
        Passage(
            text: "Ordine viene da ordo, che si pensa cominciasse come la fila dei fili sul telaio. Anche ordire, mettere l'ordito, è la stessa parola: l'ordine parte dal lavoro del tessitore.",
            source: "Latino",
            theme: .pattern,
            subtheme: .orderNamed
        ),
        Passage(
            text: "Trama in italiano è insieme il filo che attraversa l'ordito e l'intreccio di una storia. La stessa parola tiene la stoffa e il racconto.",
            source: "Italiano",
            theme: .pattern,
            subtheme: .orderNamed
        ),
        Passage(
            text: "Testo viene da textus, tessuto. Un testo, un tessuto e un contesto sono tutte cose intrecciate.",
            source: "Latino",
            theme: .pattern,
            subtheme: .orderNamed
        ),
        Passage(
            text: "Pagina viene da pangere, fissare, e indicava all'origine una fila di viti legate al filare. Dalla stessa radice viene pace.",
            source: "Latino",
            theme: .pattern,
            subtheme: .orderNamed
        ),
        Passage(
            text: "Cosmo è il greco kosmos, che vuol dire insieme ordine e ornamento. Dalla stessa parola viene cosmetico: chiamare cosmo l'universo era dirlo ben messo.",
            source: "Greco",
            theme: .pattern,
            subtheme: .orderNamed
        ),
        Passage(
            text: "Il giardino all'italiana è fatto di sempreverdi e di geometria perché la sua pianta si legga uguale in ogni stagione. È un giardino che non vuole cambiare.",
            source: "Giardino all'italiana",
            theme: .pattern,
            subtheme: .orderNamed
        ),
        Passage(
            text: "Luca Pacioli chiamò divina la proporzione aurea nel 1509, e a disegnargli i solidi del libro fu Leonardo.",
            source: "De divina proportione, 1509",
            theme: .pattern,
            subtheme: .orderNamed
        ),

        // MARK: Ground

        Passage(
            text: "Laudato si', mi' Signore, per sora nostra matre Terra, la quale ne sustenta et governa.",
            source: "Francesco d'Assisi, Cantico delle creature",
            theme: .ground,
            subtheme: .theSoilItself
        ),
        Passage(
            text: "L'aiuola che ci fa tanto feroci.",
            source: "Dante, Paradiso XXII",
            theme: .ground,
            subtheme: .theSoilItself
        ),
        Passage(
            text: "Rizosfera: i pochi millimetri di terra intorno a una radice, diversi da ogni altra terra al mondo perché la radice ci ha lavorato.",
            source: "Botanica",
            theme: .ground,
            subtheme: .theSoilItself
        ),
        Passage(
            text: "In un cucchiaino di terra sana ci sono più organismi viventi che persone sulla Terra.",
            source: "Biologia del suolo",
            theme: .ground,
            subtheme: .theSoilItself
        ),
        Passage(
            text: "Possono volerci alcune centinaia d'anni per fare un centimetro di terra buona, e un solo temporale su un campo nudo per portarlo via.",
            source: "Formazione del suolo",
            theme: .ground,
            subtheme: .theSoilItself
        ),
        Passage(
            text: "Uomo, umile e humus escono da una sola radice latina: il terreno.",
            source: "Latino",
            theme: .ground,
            subtheme: .theSoilItself
        ),
        Passage(
            text: "Letame viene da laetamen, e dietro c'è laetus, lieto. In latino un campo grasso era un campo allegro, e il concime porta ancora quel nome.",
            source: "Latino",
            theme: .ground,
            subtheme: .theSoilItself
        ),
        Passage(
            text: "Gleba era la zolla, e i servi della gleba erano legati non a un padrone ma a un pezzo di terra.",
            source: "Latino",
            theme: .ground,
            subtheme: .theSoilItself
        ),
        Passage(
            text: "Petricore: l'odore che si alza dalla terra asciutta quando la pioggia la raggiunge per la prima volta.",
            source: "Coniato nel 1964",
            theme: .ground,
            subtheme: .theSoilItself
        ),
        Passage(
            text: "I lombrichi fanno passare tutta la terra fertile di un campo attraverso il proprio corpo ogni pochi anni. Darwin ci mise quarant'anni a capirlo e ne fece il suo ultimo libro.",
            source: "Darwin sui lombrichi, 1881",
            theme: .ground,
            subtheme: .theSoilItself
        ),
        Passage(
            text: "Una prateria di posidonia nel Mediterraneo può essersi allargata di lato per centomila anni, e tutta quanta conta come una sola pianta.",
            source: "Posidonia oceanica",
            theme: .ground,
            subtheme: .theSoilItself
        ),
        Passage(
            text: "Sotto la neve, pane; sotto la pioggia, fame.",
            source: "Proverbio",
            theme: .ground,
            subtheme: .theSoilItself
        ),
        Passage(
            text: "Anno di neve, anno di bene.",
            source: "Proverbio",
            theme: .ground,
            subtheme: .theSoilItself
        ),

        Passage(
            text: "Sempre caro mi fu quest'ermo colle.",
            source: "Giacomo Leopardi, L'infinito",
            theme: .ground,
            subtheme: .aPlaceYouAreFrom
        ),
        Passage(
            text: "Quel ramo del lago di Como, che volge a mezzogiorno.",
            source: "Alessandro Manzoni, I promessi sposi",
            theme: .ground,
            subtheme: .aPlaceYouAreFrom
        ),
        Passage(
            text: "I cipressi che a Bólgheri alti e schietti van da San Guido in duplice filar.",
            source: "Giosuè Carducci, Davanti San Guido",
            theme: .ground,
            subtheme: .aPlaceYouAreFrom
        ),
        Passage(
            text: "Né più mai toccherò le sacre sponde ove il mio corpo fanciulletto giacque.",
            source: "Ugo Foscolo, A Zacinto",
            theme: .ground,
            subtheme: .aPlaceYouAreFrom
        ),
        Passage(
            text: "Casa mia, casa mia, per piccina che tu sia, tu mi sembri una badia.",
            source: "Proverbio",
            theme: .ground,
            subtheme: .aPlaceYouAreFrom
        ),
        Passage(
            text: "A ogni uccello il suo nido è bello.",
            source: "Proverbio",
            theme: .ground,
            subtheme: .aPlaceYouAreFrom
        ),
        Passage(
            text: "Campanilismo: l'affetto per un posto grande quanto arriva il suono della propria campana, e la diffidenza per tutto quello che sta oltre.",
            source: "Italiano",
            theme: .ground,
            subtheme: .aPlaceYouAreFrom
        ),
        Passage(
            text: "Paese viene da pagus, il distretto di campagna. Dalla stessa parola viene pagano, che voleva dire semplicemente uno di fuori città.",
            source: "Latino",
            theme: .ground,
            subtheme: .aPlaceYouAreFrom
        ),
        Passage(
            text: "Villano viene da villa, la casa di campagna. Chi ci abitava ha finito per dare il nome alla scortesia, e questo dice più di chi lo diceva che di lui.",
            source: "Latino",
            theme: .ground,
            subtheme: .aPlaceYouAreFrom
        ),
        Passage(
            text: "Vicino viene da vicus, il borgo o il quartiere. Un vicino non è chi ti sta accanto ma chi appartiene allo stesso pezzo di paese.",
            source: "Latino",
            theme: .ground,
            subtheme: .aPlaceYouAreFrom
        ),
        Passage(
            text: "Nostalgia è una parola costruita a tavolino nel 1688 con due parole greche, il ritorno e il dolore, per dare un nome a una malattia dei soldati lontani da casa.",
            source: "Greco, coniata nel 1688",
            theme: .ground,
            subtheme: .aPlaceYouAreFrom
        ),
        Passage(
            text: "Contrada viene da contra: la terra che ti sta di fronte quando ti fermi e guardi fuori.",
            source: "Latino",
            theme: .ground,
            subtheme: .aPlaceYouAreFrom
        ),

        Passage(
            text: "Coltivare viene da colere, che voleva dire lavorare la terra, abitarla e anche onorarla. Dalla stessa parola vengono cultura e culto.",
            source: "Latino",
            theme: .ground,
            subtheme: .aKeptPlace
        ),
        Passage(
            text: "Giardino non è latino: è arrivato dal nord, da una parola germanica per recinto, mentre l'orto ha tenuto il latino hortus. La lingua distingue il posto che dà da mangiare da quello che dà piacere.",
            source: "Germanico e latino",
            theme: .ground,
            subtheme: .aKeptPlace
        ),
        Passage(
            text: "Paradiso comincia come un giardino murato: dall'antico persiano pairidaeza, un recinto piantato per il piacere.",
            source: "Antico persiano",
            theme: .ground,
            subtheme: .aKeptPlace
        ),
        Passage(
            text: "Aia e area sono la stessa parola latina entrata due volte, e all'origine voleva dire lo spiazzo battuto dove si trebbia. Il posto viene prima della misura.",
            source: "Latino",
            theme: .ground,
            subtheme: .aKeptPlace
        ),
        Passage(
            text: "Maggese: il campo lasciato riposare e arato a maggio. Il nome della terra ferma è il nome di un mese.",
            source: "Italiano",
            theme: .ground,
            subtheme: .aKeptPlace
        ),
        Passage(
            text: "Selva è latina, bosco è germanica, foresta viene dal latino foris, fuori: era il bosco che stava oltre il recinto. Tre parole e tre modi diversi di guardare gli alberi.",
            source: "Etimologia",
            theme: .ground,
            subtheme: .aKeptPlace
        ),
        Passage(
            text: "A Pompei le radici delle piante hanno lasciato dei vuoti nella cenere. Colando gesso in quei vuoti si è potuto dire quali alberi ci fossero in ogni giardino la mattina dell'eruzione.",
            source: "Orti di Pompei",
            theme: .ground,
            subtheme: .aKeptPlace
        ),
        Passage(
            text: "L'orto botanico di Padova, del 1545, sta ancora nel posto e nel disegno di allora. La palma che vi cresce dal 1585 la chiamano la palma di Goethe, perché lui la andò a vedere.",
            source: "Padova, 1545",
            theme: .ground,
            subtheme: .aKeptPlace
        ),
        Passage(
            text: "Se hai un giardino nella tua biblioteca, non ti mancherà niente.",
            source: "Cicerone, lettera a Varrone, resa in forma piana",
            theme: .ground,
            subtheme: .aKeptPlace
        ),
        Passage(
            text: "T'amo, o pio bove; e mite un sentimento di vigore e di pace al cor m'infondi.",
            source: "Giosuè Carducci, Il bove",
            theme: .ground,
            subtheme: .aKeptPlace
        ),
        Passage(
            text: "Solo et pensoso i più deserti campi vo mesurando a passi tardi et lenti.",
            source: "Petrarca, Canzoniere 35",
            theme: .ground,
            subtheme: .aKeptPlace
        ),
        Passage(
            text: "Ritocchino e girapoggio sono i due modi di piantare i filari su una collina: uno va dritto su per la pendenza, l'altro le gira intorno. La scelta decide dove finirà la terra quando piove.",
            source: "Agronomia toscana",
            theme: .ground,
            subtheme: .aKeptPlace
        ),

        // MARK: Travel

        Passage(
            text: "Mirmecoria: viaggiare in formica. Il seme porta un corpicino oleoso che le formiche vogliono, così se lo trascinano in casa, mangiano quella parte e buttano il resto sul mucchio dei rifiuti.",
            source: "Botanica",
            theme: .travel,
            subtheme: .howASeedGoes
        ),
        Passage(
            text: "Autocoria: semi lanciati dalla pianta stessa, che passa le settimane asciutte a caricare una tensione e poi lascia andare.",
            source: "Botanica",
            theme: .travel,
            subtheme: .howASeedGoes
        ),
        Passage(
            text: "Zoocoria: viaggiare in animale, dove un seme fa tutto il suo viaggio dentro o attaccato a qualcosa che cammina.",
            source: "Botanica",
            theme: .travel,
            subtheme: .howASeedGoes
        ),
        Passage(
            text: "Anemocoria: viaggiare in vento, dove un seme fa tutto il suo viaggio sull'aria che si muove.",
            source: "Botanica",
            theme: .travel,
            subtheme: .howASeedGoes
        ),
        Passage(
            text: "Il seme dell'erodio si avvita da solo nel terreno: la resta si arrotola quando è asciutta e si distende con l'umido, e a forza di girare entra.",
            source: "Erodium",
            theme: .travel,
            subtheme: .howASeedGoes
        ),
        Passage(
            text: "Il ciclamino, quando ha finito di fiorire, arrotola il peduncolo come una molla e posa la capsula per terra, dove le formiche la trovano.",
            source: "Cyclamen",
            theme: .travel,
            subtheme: .howASeedGoes
        ),
        Passage(
            text: "Il vischio arriva incollato a un ramo perché l'uccello non riesce a staccarsi il seme di dosso e si pulisce il becco sulla corteccia. Da vischio viene invischiare.",
            source: "Viscum album",
            theme: .travel,
            subtheme: .howASeedGoes
        ),
        Passage(
            text: "Il paracadute del soffione si tiene sopra un anello d'aria che gira su se stesso, e quel vortice fermo è quello che porta un seme lontano un miglio da casa.",
            source: "Nature, 2018",
            theme: .travel,
            subtheme: .howASeedGoes
        ),
        Passage(
            text: "Una noce di cocco può galleggiare per mesi in mare aperto e mettere radici dove tocca terra. Intere flore di isole sono arrivate così.",
            source: "Cocos nucifera",
            theme: .travel,
            subtheme: .howASeedGoes
        ),
        Passage(
            text: "Krakatoa fu sterilizzata nel 1883. I semi arrivarono per mare e per uccello, e in cinquant'anni là c'era di nuovo una foresta.",
            source: "Krakatoa, dopo il 1883",
            theme: .travel,
            subtheme: .howASeedGoes
        ),
        Passage(
            text: "I ricci di bardana si attaccarono al cane di un ingegnere svizzero nel 1941. Lui mise gli uncini sotto il microscopio, e ne è venuto fuori il velcro.",
            source: "Arctium, e George de Mestral",
            theme: .travel,
            subtheme: .howASeedGoes
        ),
        Passage(
            text: "Spontanea: la pianta che arriva da sé e cresce in una terra che qualcun altro ha lasciato nuda.",
            source: "Termine da giardinieri",
            theme: .travel,
            subtheme: .howASeedGoes
        ),

        Passage(
            text: "Nel mezzo del cammin di nostra vita mi ritrovai per una selva oscura.",
            source: "Dante, Inferno I",
            theme: .travel,
            subtheme: .theRoad
        ),
        Passage(
            text: "Vien dietro a me, e lascia dir le genti.",
            source: "Dante, Purgatorio V",
            theme: .travel,
            subtheme: .theRoad
        ),
        Passage(
            text: "Chi va piano va sano e va lontano.",
            source: "Proverbio",
            theme: .travel,
            subtheme: .theRoad
        ),
        Passage(
            text: "Tutte le strade portano a Roma, e per un po' fu esatto: nel Foro c'era un cippo dorato da cui si contavano le miglia di ogni via dell'impero.",
            source: "Milliarium aureum",
            theme: .travel,
            subtheme: .theRoad
        ),
        Passage(
            text: "Miglio viene da mille passus, mille passi, e un passo romano ne contava due dei nostri. La misura della strada è il corpo che la percorre.",
            source: "Latino",
            theme: .travel,
            subtheme: .theRoad
        ),
        Passage(
            text: "Viaggio viene da viaticum, che in latino era la provvista da portarsi dietro. La parola era quello che ti metti in tasca prima di essere il cammino.",
            source: "Latino",
            theme: .travel,
            subtheme: .theRoad
        ),
        Passage(
            text: "Strada e strato sono la stessa parola latina: la via strata era la via distesa, cioè lastricata uno strato sopra l'altro.",
            source: "Latino",
            theme: .travel,
            subtheme: .theRoad
        ),
        Passage(
            text: "Cammino non è latino ma celtico, entrato in italiano dalla Gallia. La parola più nostra per la strada viene da fuori.",
            source: "Celtico",
            theme: .travel,
            subtheme: .theRoad
        ),
        Passage(
            text: "La via Francigena fu descritta tappa per tappa nel 990 dall'arcivescovo Sigerico, che tornava a Canterbury da Roma e si annotò dove aveva dormito.",
            source: "Sigerico, 990",
            theme: .travel,
            subtheme: .theRoad
        ),
        Passage(
            text: "Posta viene da statio posita, la stazione messa lungo la strada dove si cambiavano i cavalli. La lettera prende il nome dal punto in cui il viaggio si spezzava.",
            source: "Latino",
            theme: .travel,
            subtheme: .theRoad
        ),
        Passage(
            text: "Movesi il vecchierel canuto et biancho.",
            source: "Petrarca, Canzoniere 16",
            theme: .travel,
            subtheme: .theRoad
        ),
        Passage(
            text: "Il moto è causa d'ogni vita.",
            source: "Leonardo da Vinci (1452–1519)",
            theme: .travel,
            subtheme: .theRoad
        ),

        Passage(
            text: "Tu proverai sì come sa di sale lo pane altrui.",
            source: "Dante, Paradiso XVII",
            theme: .travel,
            subtheme: .farOff
        ),
        Passage(
            text: "Addio, monti sorgenti dall'acque, ed elevati al cielo.",
            source: "Alessandro Manzoni, I promessi sposi",
            theme: .travel,
            subtheme: .farOff
        ),
        Passage(
            text: "Le donne, i cavallier, l'arme, gli amori, le cortesie, l'audaci imprese io canto.",
            source: "Ludovico Ariosto, Orlando furioso, 1516",
            theme: .travel,
            subtheme: .farOff
        ),
        Passage(
            text: "Non ho raccontato la metà di quello che ho visto.",
            source: "Attribuito a Marco Polo",
            theme: .travel,
            subtheme: .farOff
        ),
        Passage(
            text: "Vaghe stelle dell'Orsa, io non credea tornare ancor per uso a contemplarvi.",
            source: "Giacomo Leopardi, Le ricordanze",
            theme: .travel,
            subtheme: .farOff
        ),
        Passage(
            text: "Tramontana è il vento che viene da oltre i monti, ed è anche la stella polare. Perdere la tramontana vuol dire perdere insieme il vento e il nord.",
            source: "Italiano",
            theme: .travel,
            subtheme: .farOff
        ),
        Passage(
            text: "La rosa dei venti chiama ogni vento per il posto da cui arriva e non per quello verso cui va: levante è il vento del sole che si alza, ponente quello del sole che cala.",
            source: "Rosa dei venti",
            theme: .travel,
            subtheme: .farOff
        ),
        Passage(
            text: "Settentrione vuol dire i sette buoi da lavoro: sono le sette stelle dell'Orsa Maggiore, che nel cielo del nord girano come un carro intorno all'aia.",
            source: "Latino",
            theme: .travel,
            subtheme: .farOff
        ),
        Passage(
            text: "Mezzogiorno in italiano è l'ora e insieme il sud. È il punto dove sta il sole quando è più alto, e il nome è rimasto attaccato a metà del paese.",
            source: "Italiano",
            theme: .travel,
            subtheme: .farOff
        ),
        Passage(
            text: "Pellegrino viene da peregrinus, per agros: uno che sta fuori dai campi, cioè un forestiero. La parte santa è arrivata dopo.",
            source: "Latino",
            theme: .travel,
            subtheme: .farOff
        ),
        Passage(
            text: "Dante distingue i palmieri, che tornano dalla Terrasanta con una palma, i romei, che vanno a Roma, e i peregrini, che vanno in Galizia. Tre parole per tre strade.",
            source: "Dante, Vita nuova",
            theme: .travel,
            subtheme: .farOff
        ),
        Passage(
            text: "Straniero, estraneo e strano sono la stessa parola latina, extraneus, entrata più volte. Chi viene da fuori e chi ti sorprende hanno un solo nome.",
            source: "Latino",
            theme: .travel,
            subtheme: .farOff
        ),
        Passage(
            text: "Certi semi caraibici arrivano sulle spiagge del nord Europa portati dalla corrente, e per secoli sono stati tenuti come amuleti da gente che non aveva idea di dove venissero.",
            source: "Entada gigas",
            theme: .travel,
            subtheme: .farOff
        ),

        // MARK: Meeting

        Passage(
            text: "Benedetto sia 'l giorno e 'l mese e l'anno.",
            source: "Petrarca, Canzoniere 61",
            theme: .meeting,
            subtheme: .theMoment
        ),
        Passage(
            text: "L'acqua che tocchi de' fiumi è l'ultima di quelle che andò e la prima di quella che viene.",
            source: "Leonardo da Vinci (1452–1519)",
            theme: .meeting,
            subtheme: .theMoment
        ),
        Passage(
            text: "Quant'è bella giovinezza, che si fugge tuttavia! Chi vuol esser lieto, sia: di doman non c'è certezza.",
            source: "Lorenzo de' Medici (1449–1492)",
            theme: .meeting,
            subtheme: .theMoment
        ),
        Passage(
            text: "Chi è questa che vèn, ch'ogn'om la mira, che fa tremar di chiaritate l'âre.",
            source: "Guido Cavalcanti (c. 1258–1300)",
            theme: .meeting,
            subtheme: .theMoment
        ),
        Passage(
            text: "Attimo viene da atomo: il pezzo di tempo così piccolo che non si può tagliare più.",
            source: "Greco",
            theme: .meeting,
            subtheme: .theMoment
        ),
        Passage(
            text: "Momento viene da momentum, che era il movimento minimo del piatto della bilancia, quello che basta a farla pendere da una parte.",
            source: "Latino",
            theme: .meeting,
            subtheme: .theMoment
        ),
        Passage(
            text: "Caso viene da cadere. Un caso è semplicemente il modo in cui le cose sono venute giù.",
            source: "Latino",
            theme: .meeting,
            subtheme: .theMoment
        ),
        Passage(
            text: "Occasione viene da ob cadere, cadere davanti a qualcuno. L'occasione non arriva: ti si posa sulla strada.",
            source: "Latino",
            theme: .meeting,
            subtheme: .theMoment
        ),
        Passage(
            text: "Coincidere è cum incidere, cadere insieme. È la stessa caduta che sta dentro la parola caso.",
            source: "Latino",
            theme: .meeting,
            subtheme: .theMoment
        ),
        Passage(
            text: "Colpo di fulmine: in italiano l'innamorarsi a prima vista prende il nome da un fenomeno del cielo, e la cosa notevole è che nessuno lo trova strano.",
            source: "Italiano",
            theme: .meeting,
            subtheme: .theMoment
        ),
        Passage(
            text: "Ichigo ichie: un incontro, una volta sola. Questa riunione è l'unica del suo genere, quindi vale la pena starci per intero.",
            source: "Giapponese, dalla via del tè",
            theme: .meeting,
            subtheme: .theMoment
        ),
        Passage(
            text: "Kairòs: l'apertura nel tempo in cui una cosa si può fare. Il momento giusto, che è un'altra cosa dall'ora sull'orologio.",
            source: "Greco antico",
            theme: .meeting,
            subtheme: .theMoment
        ),
        Passage(
            text: "Clinamen: la deviazione minima con cui gli atomi che cadono arrivano a incontrarsi, e così fanno un mondo.",
            source: "Lucrezio, I secolo a.C.",
            theme: .meeting,
            subtheme: .theMoment
        ),

        Passage(
            text: "Quasi ogni fico ha la sua specie di vespa, e nessuno dei due si riproduce senza l'altro. La vespa entra da un foro tanto stretto che nel passarci perde le ali.",
            source: "Ficus e Agaonidae",
            theme: .meeting,
            subtheme: .twoThatNeedEachOther
        ),
        Passage(
            text: "La caprificazione è antica quanto la coltivazione del fico: si appendono rami di fico selvatico fra quelli coltivati perché le vespe facciano il loro passaggio.",
            source: "Ficus carica",
            theme: .meeting,
            subtheme: .twoThatNeedEachOther
        ),
        Passage(
            text: "Protandria: un fiore che lascia andare il polline prima che il proprio stimma sia pronto, così da non potersi incontrare da solo.",
            source: "Botanica",
            theme: .meeting,
            subtheme: .twoThatNeedEachOther
        ),
        Passage(
            text: "Costanza fiorale: un'ape che ha trovato un tipo di fiore torna a quello e basta, ed è precisamente questo a renderla utile al fiore.",
            source: "Impollinazione",
            theme: .meeting,
            subtheme: .twoThatNeedEachOther
        ),
        Passage(
            text: "La vaniglia si impollina a mano quasi ovunque venga coltivata, perché l'ape che fa quel lavoro vive soltanto in Messico.",
            source: "Vanilla planifolia",
            theme: .meeting,
            subtheme: .twoThatNeedEachOther
        ),
        Passage(
            text: "Certe orchidee somigliano e odorano abbastanza a una vespa femmina che i maschi ci provano, e portano via il polline senza aver mai incontrato una vespa.",
            source: "Ophrys",
            theme: .meeting,
            subtheme: .twoThatNeedEachOther
        ),
        Passage(
            text: "La farfallina dello yucca infila il polline nel fiore apposta e poi ci depone le uova. Una pianta che ne riceve troppe lascia cadere tutto il fiore, e così il patto resta onesto.",
            source: "Yucca e Tegeticula",
            theme: .meeting,
            subtheme: .twoThatNeedEachOther
        ),
        Passage(
            text: "Tigmotropismo: la crescita guidata dal tatto, come fa un viticcio che si avvolge intorno a quello che gli capita di toccare.",
            source: "Botanica",
            theme: .meeting,
            subtheme: .twoThatNeedEachOther
        ),
        Passage(
            text: "Molti fiori leggono il polline che ci arriva sopra e aprono la strada al granello di uno sconosciuto, così che la generazione dopo venga da due.",
            source: "Autoincompatibilità",
            theme: .meeting,
            subtheme: .twoThatNeedEachOther
        ),
        Passage(
            text: "I fiori portano una carica elettrica leggerissima. Un bombo la sente, e da quella capisce quali fiori un'altra ape ha appena svuotato.",
            source: "Science, 2013",
            theme: .meeting,
            subtheme: .twoThatNeedEachOther
        ),
        Passage(
            text: "Il tartufo non è una pianta e non vive senza un albero: si attacca alle radici di una quercia o di un nocciolo, e i due si scambiano quello che l'altro non sa fare.",
            source: "Tuber",
            theme: .meeting,
            subtheme: .twoThatNeedEachOther
        ),
        Passage(
            text: "La vite maritata si fa in Campania da prima dei Romani: la vite viene fatta salire su un pioppo o su un olmo vivo, e l'albero si chiama il marito.",
            source: "Alberata",
            theme: .meeting,
            subtheme: .twoThatNeedEachOther
        ),

        Passage(
            text: "Oh gran bontà de' cavallieri antiqui!",
            source: "Ludovico Ariosto, Orlando furioso",
            theme: .meeting,
            subtheme: .theMannersOfIt
        ),
        Passage(
            text: "A tavola non si invecchia.",
            source: "Proverbio",
            theme: .meeting,
            subtheme: .theMannersOfIt
        ),
        Passage(
            text: "Patti chiari, amicizia lunga.",
            source: "Proverbio",
            theme: .meeting,
            subtheme: .theMannersOfIt
        ),
        Passage(
            text: "Paese che vai, usanza che trovi.",
            source: "Proverbio",
            theme: .meeting,
            subtheme: .theMannersOfIt
        ),
        Passage(
            text: "In latino hospes voleva dire tutti e due: chi riceve e chi è ricevuto. L'italiano ha tenuto il doppio senso in ospite e non ha mai deciso.",
            source: "Latino",
            theme: .meeting,
            subtheme: .theMannersOfIt
        ),
        Passage(
            text: "Ciao viene dal veneziano s-ciào, cioè schiavo: era un modo di dire mi metto a disposizione. Il saluto più leggero d'Italia comincia da una sottomissione.",
            source: "Veneziano",
            theme: .meeting,
            subtheme: .theMannersOfIt
        ),
        Passage(
            text: "Salutare è augurare salute. Un saluto è, alla lettera, il desiderio che l'altro stia bene.",
            source: "Latino",
            theme: .meeting,
            subtheme: .theMannersOfIt
        ),
        Passage(
            text: "Convivio è cum vivere, vivere insieme. Il banchetto prende il nome dalla cosa più grossa che si possa fare a tavola.",
            source: "Latino",
            theme: .meeting,
            subtheme: .theMannersOfIt
        ),
        Passage(
            text: "Commensale è chi divide la mensa, compagno è chi divide il pane. L'italiano ha due parole per la stessa gentilezza e se le tiene tutte e due.",
            source: "Latino",
            theme: .meeting,
            subtheme: .theMannersOfIt
        ),
        Passage(
            text: "Brindisi viene da una frase tedesca che voleva dire te lo porto. Il gesto italiano più conosciuto al mondo ha un nome preso in prestito.",
            source: "Tedesco",
            theme: .meeting,
            subtheme: .theMannersOfIt
        ),
        Passage(
            text: "Eliminare è ex limine, mettere fuori dalla soglia. È la stessa pietra della porta che dà liminale e preliminare.",
            source: "Latino",
            theme: .meeting,
            subtheme: .theMannersOfIt
        ),
        Passage(
            text: "Tessera hospitalis: una tesserina spezzata in due, e ciascuno dei due ospiti ne teneva metà. Generazioni dopo, i discendenti si riconoscevano rimettendo insieme i pezzi.",
            source: "Roma antica",
            theme: .meeting,
            subtheme: .theMannersOfIt
        ),
        Passage(
            text: "Passeggiata: la camminata della sera lungo il corso, il cui scopo dichiarato è camminare e il cui scopo vero è vedersi.",
            source: "Italiano",
            theme: .meeting,
            subtheme: .theMannersOfIt
        ),
        Passage(
            text: "Sprezzatura: nascondere del tutto la fatica, così che quello che fai sembri venuto da sé. La parola la conia Castiglione, e non se ne è mai trovata un'altra.",
            source: "Baldassarre Castiglione, Il Cortegiano, 1528",
            theme: .meeting,
            subtheme: .theMannersOfIt
        ),

        // MARK: Kinship

        Passage(
            text: "Ogni parte ha inclinazione di ricongiungersi col suo tutto.",
            source: "Leonardo da Vinci (1452–1519)",
            theme: .kinship,
            subtheme: .grownTogether
        ),
        Passage(
            text: "Anastomosi: due canali separati che diventano uno. Si dice dei fiumi, dei vasi sanguigni e delle nervature di una foglia.",
            source: "Greco",
            theme: .kinship,
            subtheme: .grownTogether
        ),
        Passage(
            text: "Mutualismo: tutti e due i soci ci guadagnano, e nessuno dei due se ne può andare senza pagare qualcosa.",
            source: "Ecologia",
            theme: .kinship,
            subtheme: .grownTogether
        ),
        Passage(
            text: "Commensalismo: uno dei due ci guadagna e all'altro non cambia niente. È un accordo più tranquillo della simbiosi, e molto più comune.",
            source: "Ecologia",
            theme: .kinship,
            subtheme: .grownTogether
        ),
        Passage(
            text: "Un innesto unisce due piante così a fondo che si dividono la linfa per tutta la vita, e ciascuna tiene i propri geni. Un tronco solo può portare cinque varietà di mela.",
            source: "Innesto",
            theme: .kinship,
            subtheme: .grownTogether
        ),
        Passage(
            text: "Inosculazione: due alberi che crescono l'uno contro l'altro abbastanza a lungo da fondersi, e da lì in poi si dividono corteccia e linfa.",
            source: "Botanica",
            theme: .kinship,
            subtheme: .grownTogether
        ),
        Passage(
            text: "Un lichene è un fungo che coltiva un'alga, e la società è talmente riuscita che per un secolo è stata descritta come una specie sola, prima che qualcuno si accorgesse che erano due.",
            source: "Lichenologia",
            theme: .kinship,
            subtheme: .grownTogether
        ),
        Passage(
            text: "Ogni foglia verde funziona grazie a un batterio che una cellula si prese in casa più di un miliardo di anni fa. Da allora sono una cosa sola.",
            source: "Endosimbiosi",
            theme: .kinship,
            subtheme: .grownTogether
        ),
        Passage(
            text: "La maggior parte delle piante di terra scambia zucchero contro fosforo con funghi infilati nel suolo. L'accordo ha circa quattrocento milioni di anni.",
            source: "Micorrize",
            theme: .kinship,
            subtheme: .grownTogether
        ),
        Passage(
            text: "Un bosco di pioppo tremulo può essere un solo organismo con un solo apparato radicale. Il più grande conosciuto copre più di quaranta ettari e conta come un albero solo.",
            source: "Populus tremuloides",
            theme: .kinship,
            subtheme: .grownTogether
        ),
        Passage(
            text: "Nella maggior parte delle piante a fiore i cloroplasti scendono soltanto dal genitore che ha fatto il seme, e così una parte di uno dei due viaggia senza mescolarsi.",
            source: "Eredità plastidiale",
            theme: .kinship,
            subtheme: .grownTogether
        ),
        Passage(
            text: "Confine è cum finis, il termine che due tengono in comune. Un confine, in italiano, appartiene a tutti e due i lati.",
            source: "Latino",
            theme: .kinship,
            subtheme: .grownTogether
        ),

        Passage(
            text: "Fratello e sorella sono due diminutivi: in italiano si dice, alla lettera, fratellino e sorellina, e la parola grande da cui venivano non c'è più.",
            source: "Latino",
            theme: .kinship,
            subtheme: .theWordsForIt
        ),
        Passage(
            text: "Zio non è latino ma greco. Il latino aveva avunculus e patruus, uno per parte, e l'italiano li ha lasciati cadere tutti e due per una parola presa in prestito.",
            source: "Greco",
            theme: .kinship,
            subtheme: .theWordsForIt
        ),
        Passage(
            text: "Nipote fa da sola il lavoro di due parole: il figlio di tuo figlio e il figlio di tuo fratello si chiamano allo stesso modo, come già in latino.",
            source: "Latino",
            theme: .kinship,
            subtheme: .theWordsForIt
        ),
        Passage(
            text: "Parente viene da parens, chi genera, e in italiano è passato a voler dire chiunque della famiglia. Per il padre e la madre è servita un'altra parola, genitore.",
            source: "Latino",
            theme: .kinship,
            subtheme: .theWordsForIt
        ),
        Passage(
            text: "Compagno è cum panis, chi divide il pane con te.",
            source: "Latino",
            theme: .kinship,
            subtheme: .theWordsForIt
        ),
        Passage(
            text: "Famiglia viene da familia, che indicava tutta la casa, e dietro c'è famulus, il servo. La parola più calda che abbiamo comincia da lì.",
            source: "Latino",
            theme: .kinship,
            subtheme: .theWordsForIt
        ),
        Passage(
            text: "Sposo viene da spondere, promettere solennemente. Dalla stessa parola viene rispondere: chi risponde sta ripromettendo qualcosa.",
            source: "Latino",
            theme: .kinship,
            subtheme: .theWordsForIt
        ),
        Passage(
            text: "Cognato è cognatus, nato insieme. Il parente acquisito porta il nome di una nascita in comune che non c'è mai stata.",
            source: "Latino",
            theme: .kinship,
            subtheme: .theWordsForIt
        ),
        Passage(
            text: "Affine e confine tengono la stessa idea: due cose affini hanno un limite in comune.",
            source: "Latino",
            theme: .kinship,
            subtheme: .theWordsForIt
        ),
        Passage(
            text: "Simbiosi è greco per vivere insieme. Fu coniata negli anni Settanta dell'Ottocento per i licheni, che sono un fungo e un'alga in uno.",
            source: "Greco",
            theme: .kinship,
            subtheme: .theWordsForIt
        ),
        Passage(
            text: "Compare e comare erano il padrino e la madrina, e nel sud sono diventati il modo di chiamare chi ti sta vicino. Il legame del battesimo ha prestato la parola all'amicizia.",
            source: "Italiano",
            theme: .kinship,
            subtheme: .theWordsForIt
        ),
        Passage(
            text: "Prossimo è il superlativo di prope, vicino: il più vicino di tutti. Amare il prossimo vuol dire, alla lettera, amare chi ti sta più addosso.",
            source: "Latino",
            theme: .kinship,
            subtheme: .theWordsForIt
        ),

        Passage(
            text: "Al cor gentil rempaira sempre amore, come l'ausello in selva a la verdura.",
            source: "Guido Guinizzelli (c. 1235–1276)",
            theme: .kinship,
            subtheme: .twoPeople
        ),
        Passage(
            text: "Chi trova un amico trova un tesoro.",
            source: "Proverbio",
            theme: .kinship,
            subtheme: .twoPeople
        ),
        Passage(
            text: "L'unione fa la forza.",
            source: "Proverbio",
            theme: .kinship,
            subtheme: .twoPeople
        ),
        Passage(
            text: "Una mano lava l'altra, e tutte e due lavano il viso.",
            source: "Proverbio",
            theme: .kinship,
            subtheme: .twoPeople
        ),
        Passage(
            text: "Un albero non fa foresta.",
            source: "Proverbio",
            theme: .kinship,
            subtheme: .twoPeople
        ),
        Passage(
            text: "Dimmi con chi vai e ti dirò chi sei.",
            source: "Proverbio",
            theme: .kinship,
            subtheme: .twoPeople
        ),
        Passage(
            text: "Due valgono meglio che un solo.",
            source: "Ecclesiaste, tr. Giovanni Diodati, 1607",
            theme: .kinship,
            subtheme: .twoPeople
        ),
        Passage(
            text: "L'amico è un'anima sola che abita in due corpi.",
            source: "Aristotele, riferito da Diogene Laerzio, resa in forma piana",
            theme: .kinship,
            subtheme: .twoPeople
        ),
        Passage(
            text: "Gli uomini sono fatti gli uni per gli altri.",
            source: "Marco Aurelio, resa in forma piana",
            theme: .kinship,
            subtheme: .twoPeople
        ),
        Passage(
            text: "Perché era lui, perché ero io.",
            source: "Montaigne sull'amicizia, resa in forma piana",
            theme: .kinship,
            subtheme: .twoPeople
        ),
        Passage(
            text: "L'amor che move il sole e l'altre stelle.",
            source: "Dante, Paradiso XXXIII",
            theme: .kinship,
            subtheme: .twoPeople
        ),
        Passage(
            text: "I figli di Adamo sono membra di un solo corpo.",
            source: "Saadi, Gulistan, 1258, resa in forma piana",
            theme: .kinship,
            subtheme: .twoPeople
        ),
        Passage(
            text: "Ubuntu: una persona è fatta persona dalle altre persone, e la nostra umanità si vede in quello che passa fra noi.",
            source: "Bantu nguni",
            theme: .kinship,
            subtheme: .twoPeople
        ),

        // MARK: Peace

        Passage(
            text: "Psiturismo: il suono del vento che passa fra le foglie.",
            source: "Dal greco",
            theme: .peace,
            subtheme: .quietAsASound
        ),
        Passage(
            text: "Timidezza delle chiome: lo spazio che alberi vicini lasciano fra una chioma e l'altra, così che il tetto di un bosco sia un mosaico con la luce nelle cuciture.",
            source: "Botanica",
            theme: .peace,
            subtheme: .quietAsASound
        ),
        Passage(
            text: "La neve fresca è piena d'aria e si mangia le note alte di qualunque suono: per questo un paesaggio innevato non è soltanto silenzioso, è ovattato.",
            source: "Acustica della neve",
            theme: .peace,
            subtheme: .quietAsASound
        ),
        Passage(
            text: "In una camera anecoica non resta niente da sentire tranne te stesso, e chi ci si siede racconta di aver sentito il proprio sangue.",
            source: "Camere anecoiche",
            theme: .peace,
            subtheme: .quietAsASound
        ),
        Passage(
            text: "Il latino diceva silere delle cose e tacere delle persone. L'italiano tiene ancora la differenza, e ha una parola per ciascuno dei due silenzi.",
            source: "Latino",
            theme: .peace,
            subtheme: .quietAsASound
        ),
        Passage(
            text: "Fermata è insieme la sosta dell'autobus e il segno che tiene una nota oltre la sua durata. In italiano fermarsi e prolungarsi si dicono con la stessa parola.",
            source: "Italiano",
            theme: .peace,
            subtheme: .quietAsASound
        ),
        Passage(
            text: "Il segno della fermata in italiano si chiama corona: una piccola corona posata sopra la nota, che le dà il permesso di durare.",
            source: "Notazione musicale",
            theme: .peace,
            subtheme: .quietAsASound
        ),
        Passage(
            text: "La parola è d'argento, il silenzio è d'oro.",
            source: "Proverbio",
            theme: .peace,
            subtheme: .quietAsASound
        ),
        Passage(
            text: "Un grillo canta strofinando un'ala contro l'altra, e più fa caldo più canta in fretta. Contando i trilli si può stimare la temperatura dell'aria.",
            source: "Gryllidae",
            theme: .peace,
            subtheme: .quietAsASound
        ),
        Passage(
            text: "Il canto di una cicala può passare i cento decibel a un metro di distanza, e sono animali lunghi pochi centimetri.",
            source: "Cicadidae",
            theme: .peace,
            subtheme: .quietAsASound
        ),
        Passage(
            text: "Il vento in una pineta e il vento in un querceto non fanno lo stesso rumore: gli aghi fischiano, le foglie larghe frusciano.",
            source: "Acustica del bosco",
            theme: .peace,
            subtheme: .quietAsASound
        ),
        Passage(
            text: "Sottovoce, sordina e smorzando sono parole italiane con cui la musica di tutto il mondo dice di farsi piccola.",
            source: "Italiano",
            theme: .peace,
            subtheme: .quietAsASound
        ),

        Passage(
            text: "Pace viene da pax, imparentata con pangere, fissare. Una pace era una cosa che due parti fissavano fra loro, come un paletto piantato nella terra.",
            source: "Latino",
            theme: .peace,
            subtheme: .theWordsForStopping
        ),
        Passage(
            text: "Pagare viene da pacare, pacificare. Saldare un debito era, alla lettera, metterlo in pace.",
            source: "Latino",
            theme: .peace,
            subtheme: .theWordsForStopping
        ),
        Passage(
            text: "Patto e pace hanno la stessa radice. Chi fa un patto e chi fa la pace stanno facendo lo stesso gesto.",
            source: "Latino",
            theme: .peace,
            subtheme: .theWordsForStopping
        ),
        Passage(
            text: "Quieto e cheto sono la stessa parola latina entrata due volte: una per la scuola, una per la bocca. L'acqua cheta è la stessa acqua quieta.",
            source: "Latino",
            theme: .peace,
            subtheme: .theWordsForStopping
        ),
        Passage(
            text: "Tregua non è latina ma gotica, da una parola che voleva dire patto. In italiano la pausa della guerra porta un nome venuto da fuori.",
            source: "Gotico",
            theme: .peace,
            subtheme: .theWordsForStopping
        ),
        Passage(
            text: "Sereno viene da serenus, che si diceva prima di tutto del tempo: un cielo pulito e senza vento. Rasserenarsi è tornare a fare bel tempo.",
            source: "Latino",
            theme: .peace,
            subtheme: .theWordsForStopping
        ),
        Passage(
            text: "Calma arriva dal greco kauma, il caldo del giorno: l'ora in cui fa troppo caldo per lavorare e tutto si ferma.",
            source: "Greco",
            theme: .peace,
            subtheme: .theWordsForStopping
        ),
        Passage(
            text: "Ozio era otium, il tempo che ti appartiene. Il suo contrario si diceva negotium, non-ozio, e da lì viene negozio: gli affari prendono il nome dalla mancanza di riposo.",
            source: "Latino",
            theme: .peace,
            subtheme: .theWordsForStopping
        ),
        Passage(
            text: "Piacere e placido sono la stessa parola latina entrata due volte. Quello che ti piace e quello che è calmo si chiamavano allo stesso modo.",
            source: "Latino",
            theme: .peace,
            subtheme: .theWordsForStopping
        ),
        Passage(
            text: "Riposo è re pausare, fare pausa un'altra volta, e pausa viene dal greco pausis, il finire di una cosa. Riposarsi è finire qualcosa più volte.",
            source: "Latino e greco",
            theme: .peace,
            subtheme: .theWordsForStopping
        ),
        Passage(
            text: "Horas non numero nisi serenas, inciso sulle meridiane: conto solo le ore serene. Serenus voleva dire senza nuvole, quindi un quadrante che ha bisogno del sole per contare sta soltanto descrivendo se stesso.",
            source: "Motto da meridiana, latino",
            theme: .peace,
            subtheme: .theWordsForStopping
        ),
        Passage(
            text: "Requie viene da requies, riposo, ed è rimasta in italiano quasi soltanto nella frase senza requie, cioè in quello che non si ferma mai.",
            source: "Latino",
            theme: .peace,
            subtheme: .theWordsForStopping
        ),

        Passage(
            text: "E il naufragar m'è dolce in questo mare.",
            source: "Giacomo Leopardi, L'infinito",
            theme: .peace,
            subtheme: .atEase
        ),
        Passage(
            text: "Chiare, fresche et dolci acque.",
            source: "Petrarca, Canzoniere 126",
            theme: .peace,
            subtheme: .atEase
        ),
        Passage(
            text: "Pace non trovo, et non ò da far guerra.",
            source: "Petrarca, Canzoniere 134",
            theme: .peace,
            subtheme: .atEase
        ),
        Passage(
            text: "E 'n la sua volontade è nostra pace.",
            source: "Dante, Paradiso III",
            theme: .peace,
            subtheme: .atEase
        ),
        Passage(
            text: "Beati quelli ke 'l sosterrano in pace.",
            source: "Francesco d'Assisi, Cantico delle creature",
            theme: .peace,
            subtheme: .atEase
        ),
        Passage(
            text: "Egli mi fa giacere in paschi erbosi, e mi guida lungo le acque chete.",
            source: "Salmo 23, tr. Giovanni Diodati, 1607",
            theme: .peace,
            subtheme: .atEase
        ),
        Passage(
            text: "S'ei piace, ei lice.",
            source: "Torquato Tasso, Aminta, 1573",
            theme: .peace,
            subtheme: .atEase
        ),
        Passage(
            text: "Meriggiare: passare le ore del mezzogiorno all'ombra. Meriggio viene da medius dies, la metà del giorno: il verbo dice l'ora insieme al gesto.",
            source: "Italiano",
            theme: .peace,
            subtheme: .atEase
        ),
        Passage(
            text: "Controra: nel sud, le ore dopo pranzo in cui il caldo ferma tutto e per strada non c'è nessuno. È un pezzo di giornata che ha un nome proprio.",
            source: "Italiano meridionale",
            theme: .peace,
            subtheme: .atEase
        ),
        Passage(
            text: "Abbiocco: il sonno che ti prende dopo aver mangiato bene, contro il quale non c'è niente da fare e non c'è motivo di fare niente.",
            source: "Romanesco",
            theme: .peace,
            subtheme: .atEase
        ),
        Passage(
            text: "Dolce far niente: la frase che l'italiano ha regalato a tutte le lingue, e che nessuna di loro ha tradotto.",
            source: "Italiano",
            theme: .peace,
            subtheme: .atEase
        ),
        Passage(
            text: "Adagio è ad agio, con comodo. Tutta la musica del mondo si segna con parole italiane, e quella per andare piano dice semplicemente di stare comodi.",
            source: "Italiano",
            theme: .peace,
            subtheme: .atEase
        ),
        Passage(
            text: "Val più un'ora di allegria che cento di malinconia.",
            source: "Proverbio",
            theme: .peace,
            subtheme: .atEase
        ),
        Passage(
            text: "Shinrin-yoku: il bagno di foresta, che non ti chiede niente se non di stare fra gli alberi con i sensi aperti.",
            source: "Giapponese, coniato nel 1982",
            theme: .peace,
            subtheme: .atEase
        ),
    ]
}
