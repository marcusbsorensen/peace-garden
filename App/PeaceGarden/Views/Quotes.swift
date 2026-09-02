import Foundation
import SeedCore

/// A short passage, where it came from, and the theme it belongs to.
///
/// The provenance is deliberately terse — a name, a language, a species. It is
/// there so the passage can be trusted and looked up, not so it can be cited.
struct Passage: Equatable, Sendable {
    let text: String     // the passage itself
    let source: String   // brief provenance, shown beneath it
    let theme: Quotes.Theme
    let subtheme: Quotes.Subtheme
}

/// The bank of passages, and the draw that picks from it.
///
/// A passage is shown at the moment two people cross their plants. Which one
/// they get is settled in two stages, and the split is the whole design:
///
/// - **The theme belongs to the pair.** Each person's seed carries a theme of
///   its own — read off the head of its plant's genus, so the name says it. When
///   two people meet, the pair inherits one: usually one of theirs, sometimes a
///   third that lies between them. It is rolled from `pairID`, so it is settled
///   the first time they meet and never moves again.
/// - **The subtheme belongs to the child.** Each theme divides three ways, and
///   which third a meeting draws from is read off the ending of the child's own
///   genus. A plant says which corner of its theme it came out of.
/// - **The line belongs to the meeting.** Within that third, the passage is
///   drawn from the child seed, which carries a fresh nonce from each phone. So
///   it is a different line every single time, and both phones agree on it.
///
/// Together: the same character with the same person always, never the same
/// words twice. Drawing the theme from the child instead would let it wobble
/// between meetings, which is the coherence undone; drawing the line from the
/// pair would freeze it forever, which was the first attempt and too rigid.
///
/// Neither stage consults a clock, a server, or a device identifier, so two
/// phones in different time zones reach the same answer and a plant kept in the
/// garden reads the same in ten years.
///
/// The intent is divinatory rather than instructive. A passage is offered as
/// something that might happen to fit this meeting, which is why the bank mixes
/// quotation, definition, etymology and fact — the pleasure is partly in not
/// knowing which kind is about to appear. Those four kinds cut *across* the
/// themes rather than sorting into them, and that is on purpose: a theme should
/// be recognisable in what a line is about, not in what form it takes.
///
/// Everything here is safe to ship in a binary. Quotations come from authors
/// long dead and from traditional sayings; translations are either
/// public-domain ones, credited to the translator, or rendered plainly here.
/// Facts are not copyrightable, but the wording of a reference book is, so
/// every definition, etymology and fact below is written from scratch rather
/// than lifted. Nothing goes in that could not be established. Every named
/// author died long enough ago to be out of copyright everywhere the app will
/// ship. Where a saying could not be pinned to a person it is credited as
/// traditional, which is the honest attribution rather than a weaker one.
enum Quotes {

    /// The ten themes a passage can belong to.
    ///
    /// Themes are not a list and not a ring. Each one sits at a point in a
    /// four-dimensional space, and how close two themes are depends on which
    /// dimension you are asking about — which is the point, because Waiting is
    /// near Ground in one direction and near Beginnings in quite another. A
    /// single ordering cannot hold both, and a ring forces every theme to have
    /// exactly two neighbours whether it deserves them or not.
    enum Theme: String, CaseIterable, Sendable {
        case beginnings, waiting, renewal, light, pattern
        case ground, travel, meeting, kinship, peace

        /// Where this theme sits, one score per `Dimension`, in that order.
        var position: [Double] {
            switch self {
            case .beginnings: return [0.30, 0.45, 0.60, 0.35]
            case .waiting:    return [0.15, 0.10, 1.00, 0.40]
            case .renewal:    return [0.25, 0.70, 0.70, 0.35]
            case .light:      return [0.30, 0.60, 0.35, 0.50]
            case .pattern:    return [0.40, 0.25, 0.50, 0.70]
            case .ground:     return [0.25, 0.05, 0.85, 0.45]
            case .travel:     return [0.35, 1.00, 0.45, 0.75]
            case .meeting:    return [0.90, 0.70, 0.10, 0.55]
            case .kinship:    return [1.00, 0.30, 0.90, 0.30]
            case .peace:      return [0.55, 0.00, 0.75, 0.20]
            }
        }

        /// The genus syllables that mean this theme.
        ///
        /// Every one of `PlantName.genusHeads` appears exactly once across the
        /// ten themes, which is what makes `init(genusHead:)` total. The list
        /// is frozen — see `PlantName.genusHeads` for why a twenty-fifth
        /// syllable cannot simply be added — so the themes were fitted to the
        /// syllables rather than the syllables chosen for the themes. Four
        /// themes take three heads and six take two, which leaves a plant
        /// half again as likely to be born to Beginnings as to Peace.
        /// Documented rather than corrected: correcting it means either
        /// renaming every plant that exists or weighting the draw, and a
        /// weighted draw would break the one thing this design is for, which
        /// is that the name and the theme are the same fact said twice.
        var genusHeads: [String] {
            switch self {
            case .beginnings: return ["Thal", "Lir", "Ver"]   // a shoot, a lily, the spring
            case .waiting:    return ["Nyx", "Umbr"]          // night, shade
            case .renewal:    return ["Dros", "Ros"]          // dew, and dew again
            case .light:      return ["El", "Aur", "Sel"]     // sun, dawn, moon
            case .pattern:    return ["Cal", "Quin"]          // the shapely, the five
            case .ground:     return ["Cer", "Fen", "Pell"]   // grain, fen, the earth's skin
            case .travel:     return ["Zeph", "Ael", "Hal"]   // west wind, gust, salt sea
            case .meeting:    return ["Mel", "Ith"]           // honey, Ithaca
            case .kinship:    return ["Wyn", "Cyn"]           // joy, the dog at the door
            case .peace:      return ["Ol", "Bel"]            // the olive, a clear sky
            }
        }

        /// The theme a plant's name says it belongs to.
        ///
        /// Total by construction, and defended by `ThemeMappingTests`: every
        /// head is claimed once, and none twice.
        init(genusHead: String) {
            self = Theme.allCases.first { $0.genusHeads.contains(genusHead) } ?? .beginnings
        }

        /// This theme's three subthemes, in the order the genus tails read
        /// them. Taken from `Subtheme.theme` rather than listed again, so
        /// there is one place a subtheme's theme is written down.
        var subthemes: [Subtheme] {
            Subtheme.allCases.filter { $0.theme == self }
        }
    }

    /// The thirty subthemes: three under each theme.
    ///
    /// They were not invented and then filled. Every theme's passages were laid
    /// out and read, and these are the three heaps they fell into —
    /// which is why the three are uneven, and why the shape differs from theme
    /// to theme. Most themes turn out to divide into *the mechanism*, *the
    /// instances*, and *the words and sayings*, but not all of them do, and
    /// forcing the odd ones into that frame would have been drawing the map
    /// before walking the ground.
    ///
    /// The order of the cases within a theme is the order the genus tails read
    /// them in, so `Theme.subthemes` is `[first, second, third]` and nothing
    /// else needs to know which is which.
    enum Subtheme: String, CaseIterable, Sendable {
        // beginnings
        case theFirstAct, smallToLarge, whatAStartSettles
        // waiting
        case heldBack, theLongCount, standingAndWatching
        // renewal
        case cutAndComeAgain, theTurningYear, madeWhole
        // light
        case theEdgesOfTheDay, readingTheLight, lightItself
        // pattern
        case counted, fittedTogether, orderNamed
        // ground
        case theSoilItself, aPlaceYouAreFrom, aKeptPlace
        // travel
        case howASeedGoes, theRoad, farOff
        // meeting
        case theMoment, twoThatNeedEachOther, theMannersOfIt
        // kinship
        case grownTogether, theWordsForIt, twoPeople
        // peace
        case quietAsASound, theWordsForStopping, atEase

        var theme: Theme {
            switch self {
            case .theFirstAct, .smallToLarge, .whatAStartSettles: return .beginnings
            case .heldBack, .theLongCount, .standingAndWatching: return .waiting
            case .cutAndComeAgain, .theTurningYear, .madeWhole: return .renewal
            case .theEdgesOfTheDay, .readingTheLight, .lightItself: return .light
            case .counted, .fittedTogether, .orderNamed: return .pattern
            case .theSoilItself, .aPlaceYouAreFrom, .aKeptPlace: return .ground
            case .howASeedGoes, .theRoad, .farOff: return .travel
            case .theMoment, .twoThatNeedEachOther, .theMannersOfIt: return .meeting
            case .grownTogether, .theWordsForIt, .twoPeople: return .kinship
            case .quietAsASound, .theWordsForStopping, .atEase: return .peace
            }
        }
    }

    /// The four ways two themes can be near one another.
    ///
    /// A pair settles on one of these as the thing that defines them, and their
    /// shared theme is then matched along that dimension alone. Matching on all
    /// four at once averages everything toward the middle of the space and hands
    /// the same central theme to most pairs; choosing one keeps the answers
    /// spread and gives each pairing a reason.
    enum Dimension: Int, CaseIterable, Sendable {
        /// Solitary at 0, shared at 1. One thing, or two.
        case company
        /// Still at 0, moving at 1.
        case motion
        /// A moment at 0, a long span at 1.
        case duration
        /// Classic at 0, quirky at 1. Not what a line is about but how it
        /// sounds: Marcus Aurelius at one end, burdock burs and Velcro at the
        /// other.
        case register
    }

    static let all: [Passage] = [

        // MARK: Beginnings

        Passage(
            text: "The beginning is the most important part of the work.",
            source: "Plato, Republic, tr. Benjamin Jowett",
            theme: .beginnings,
            subtheme: .whatAStartSettles
        ),
        Passage(
            text: "The child is father of the man.",
            source: "William Wordsworth, 1802",
            theme: .beginnings,
            subtheme: .whatAStartSettles
        ),
        Passage(
            text: "Well begun is half done.",
            source: "Proverb",
            theme: .beginnings,
            subtheme: .whatAStartSettles
        ),
        Passage(
            text: "The beginning is half of the whole.",
            source: "Greek proverb",
            theme: .beginnings,
            subtheme: .whatAStartSettles
        ),
        Passage(
            text: "Fortune favours the bold.",
            source: "Virgil, Aeneid, rendered plainly",
            theme: .beginnings,
            subtheme: .whatAStartSettles
        ),
        Passage(
            text: "Germination: the moment a seed stops being a store and starts being a plant. It cannot be undone.",
            source: "Botany",
            theme: .beginnings,
            subtheme: .theFirstAct
        ),
        Passage(
            text: "Imbibition: the first act of a germinating seed, which is simply to drink. Nothing grows until water has got in.",
            source: "Botany",
            theme: .beginnings,
            subtheme: .theFirstAct
        ),
        Passage(
            text: "Radicle: the first root, and the first part to leave the seed. Something goes down before anything goes up.",
            source: "Botany",
            theme: .beginnings,
            subtheme: .theFirstAct
        ),
        Passage(
            text: "Cotyledon: the seed leaf, packed away before there was any light to need, and often nothing like the leaves that follow it.",
            source: "Botany",
            theme: .beginnings,
            subtheme: .theFirstAct
        ),
        Passage(
            text: "Meristem: the small region where a plant's cells are still dividing. Everything it will ever be comes out of a few of these.",
            source: "Botany",
            theme: .beginnings,
            subtheme: .theFirstAct
        ),
        Passage(
            text: "Origin is Latin oriri, to rise. The same word gives orient, named for the direction the sun comes up from.",
            source: "Latin",
            theme: .beginnings,
            subtheme: .whatAStartSettles
        ),
        Passage(
            text: "Seminal, seminar and disseminate all descend from Latin semen, a seed. A seminar was a seed bed.",
            source: "Latin",
            theme: .beginnings,
            subtheme: .whatAStartSettles
        ),
        Passage(
            text: "Inaugurate comes from the augur, who read the flight of birds. Nothing began until the omens had been taken.",
            source: "Latin",
            theme: .beginnings,
            subtheme: .whatAStartSettles
        ),
        Passage(
            text: "Nature is Latin natura, from nasci, to be born. The word for everything is built on the word for beginning.",
            source: "Latin",
            theme: .beginnings,
            subtheme: .whatAStartSettles
        ),
        Passage(
            text: "Prime and primrose share Latin primus, first. A primrose is named for when it arrives rather than for what it is.",
            source: "Latin",
            theme: .beginnings,
            subtheme: .whatAStartSettles
        ),
        Passage(
            text: "An acorn buried by a jay is likelier to become an oak than one that simply falls, because the jay carries it away from the parent tree and then forgets a good number of them.",
            source: "Garrulus glandarius",
            theme: .beginnings,
            subtheme: .smallToLarge
        ),
        Passage(
            text: "The heaviest seed is the coco de mer, at up to twenty-five kilograms. The lightest are orchid seeds, of which a million weigh about a gram.",
            source: "Extremes of seed size",
            theme: .beginnings,
            subtheme: .smallToLarge
        ),
        Passage(
            text: "Wheat found in Egyptian tombs has never once grown. The stories are old, the tests are many, and every one of them has failed.",
            source: "Mummy wheat",
            theme: .beginnings,
            subtheme: .whatAStartSettles
        ),
        Passage(
            text: "A bamboo shoot can put on the better part of a metre in a day, using cells laid down before it ever broke the ground.",
            source: "Phyllostachys",
            theme: .beginnings,
            subtheme: .smallToLarge
        ),
        Passage(
            text: "A seedling settles which way is up and which way is down before it has met the surface, one part following the light and the other following gravity.",
            source: "Tropisms",
            theme: .beginnings,
            subtheme: .theFirstAct
        ),
        Passage(
            text: "The tree which fills the arms grew from the tiniest sprout.",
            source: "Laozi, tr. James Legge",
            theme: .beginnings,
            subtheme: .smallToLarge
        ),
        Passage(
            text: "To see a World in a Grain of Sand, and a Heaven in a Wild Flower.",
            source: "William Blake (1757–1827)",
            theme: .beginnings,
            subtheme: .smallToLarge
        ),
        Passage(
            text: "Convince me that you have a seed there, and I am prepared to expect wonders.",
            source: "Henry David Thoreau, 1860",
            theme: .beginnings,
            subtheme: .smallToLarge
        ),
        Passage(
            text: "The creation of a thousand forests is in one acorn.",
            source: "Ralph Waldo Emerson, History, 1841",
            theme: .beginnings,
            subtheme: .smallToLarge
        ),
        Passage(
            text: "To make a prairie it takes a clover and one bee — one clover, and a bee, and revery.",
            source: "Emily Dickinson (1830–1886)",
            theme: .beginnings,
            subtheme: .smallToLarge
        ),
        Passage(
            text: "Great oaks from little acorns grow.",
            source: "English proverb",
            theme: .beginnings,
            subtheme: .smallToLarge
        ),
        Passage(
            text: "Every Bramley apple is a cutting from one tree, grown from a pip that Mary Ann Brailsford planted in a pot in 1809.",
            source: "Southwell, Nottinghamshire",
            theme: .beginnings,
            subtheme: .whatAStartSettles
        ),
        Passage(
            text: "Sow a pip from any apple and what comes up is a wholly new variety, which is why named apples travel as grafts.",
            source: "Malus domestica",
            theme: .beginnings,
            subtheme: .whatAStartSettles
        ),
        Passage(
            text: "Orchid seed is as fine as dust and carries almost nothing to live on. Each grain waits for a fungus to feed it into life.",
            source: "Orchidaceae",
            theme: .beginnings,
            subtheme: .smallToLarge
        ),
        Passage(
            text: "A giant sequoia seed weighs about five milligrams, roughly a flake of oatmeal, and the tree that comes of it is among the largest living things on earth.",
            source: "Sequoiadendron giganteum",
            theme: .beginnings,
            subtheme: .smallToLarge
        ),
        Passage(
            text: "Large streams from little fountains flow.",
            source: "David Everett, 1791",
            theme: .beginnings,
            subtheme: .smallToLarge
        ),
        Passage(
            text: "A flowering plant is fertilised twice at once: one sperm makes the embryo, the other makes the store of food packed around it.",
            source: "Double fertilisation",
            theme: .beginnings,
            subtheme: .theFirstAct
        ),
        Passage(
            text: "Plumule: the shoot already inside the seed, its first leaves folded and waiting while the root goes down ahead of it.",
            source: "Botany",
            theme: .beginnings,
            subtheme: .theFirstAct
        ),
        Passage(
            text: "Hypocotyl: the stem between root and seed leaves. In many seedlings it comes up bent double, so the soil is pushed aside by a shoulder and the growing tip arrives unscratched.",
            source: "Botany",
            theme: .beginnings,
            subtheme: .theFirstAct
        ),
        Passage(
            text: "Initial and initiate come from Latin initium, an entrance, from in-ire, to go in. A beginning is a going in.",
            source: "Latin",
            theme: .beginnings,
            subtheme: .theFirstAct
        ),
        Passage(
            text: "Debut is French débuter, to play the first stroke in a game, from but, the mark being aimed at. The word starts at the target rather than at the player.",
            source: "French",
            theme: .beginnings,
            subtheme: .theFirstAct
        ),
        Passage(
            text: "A mistletoe seedling grows away from the light rather than towards it, because the thing it needs is the shaded side of the branch it has landed on.",
            source: "Viscum album",
            theme: .beginnings,
            subtheme: .theFirstAct
        ),

        // MARK: Waiting

        Passage(
            text: "They also serve who only stand and wait.",
            source: "John Milton, 1673",
            theme: .waiting,
            subtheme: .standingAndWatching
        ),
        Passage(
            text: "The two most powerful warriors are patience and time.",
            source: "Leo Tolstoy, War and Peace, 1869",
            theme: .waiting,
            subtheme: .standingAndWatching
        ),
        Passage(
            text: "How poor are they that have not patience.",
            source: "William Shakespeare, Othello",
            theme: .waiting,
            subtheme: .standingAndWatching
        ),
        Passage(
            text: "Everything comes to him who waits.",
            source: "English proverb",
            theme: .waiting,
            subtheme: .standingAndWatching
        ),
        Passage(
            text: "However long the night, the dawn will break.",
            source: "African proverb",
            theme: .waiting,
            subtheme: .standingAndWatching
        ),
        Passage(
            text: "Dormancy: a seed refusing to grow although the conditions are right, held back from the inside until something changes.",
            source: "Botany",
            theme: .waiting,
            subtheme: .heldBack
        ),
        Passage(
            text: "Quiescence: a seed entirely ready to grow and simply waiting on the world. Not the same thing as dormancy, and often mistaken for it.",
            source: "Botany",
            theme: .waiting,
            subtheme: .heldBack
        ),
        Passage(
            text: "Stratification: the weeks of cold a seed must pass through before it will start, which gardeners counterfeit with a fridge.",
            source: "Botany",
            theme: .waiting,
            subtheme: .heldBack
        ),
        Passage(
            text: "Scarification: wearing through a seed coat so that water can get in, done in the wild by a gut, a fire, or a winter of grit.",
            source: "Botany",
            theme: .waiting,
            subtheme: .heldBack
        ),
        Passage(
            text: "Marcescence: dead leaves a tree holds onto all winter and lets go only when the new buds push them off.",
            source: "Botany",
            theme: .waiting,
            subtheme: .heldBack
        ),
        Passage(
            text: "Patient is Latin patiens, bearing. A patient in a hospital and patience in a queue are the same word doing the same work.",
            source: "Latin",
            theme: .waiting,
            subtheme: .standingAndWatching
        ),
        Passage(
            text: "Abide and abode are one word. Where you waited became where you lived.",
            source: "Old English",
            theme: .waiting,
            subtheme: .standingAndWatching
        ),
        Passage(
            text: "Wait reaches English from a Germanic root meaning to watch. It was a kind of looking before it was a kind of staying.",
            source: "Old French",
            theme: .waiting,
            subtheme: .standingAndWatching
        ),
        Passage(
            text: "Harvest is the old English name for the season itself, haerfest. Autumn was named for the work, and the word for the work outlived it.",
            source: "Old English",
            theme: .waiting,
            subtheme: .standingAndWatching
        ),
        Passage(
            text: "Expect is Latin exspectare, to look out for. To expect a thing is to be watching the road.",
            source: "Latin",
            theme: .waiting,
            subtheme: .standingAndWatching
        ),
        Passage(
            text: "A titan arum may store for seven years or more before it flowers, and the flower is over in about two days.",
            source: "Amorphophallus titanum",
            theme: .waiting,
            subtheme: .theLongCount
        ),
        Passage(
            text: "The century plant is misnamed but not by much: it grows for decades, flowers once on a stalk taller than a house, and dies.",
            source: "Agave americana",
            theme: .waiting,
            subtheme: .theLongCount
        ),
        Passage(
            text: "Periodical cicadas spend thirteen or seventeen years underground and come up all together. Both numbers are prime, which makes them very hard to keep time with.",
            source: "Magicicada",
            theme: .waiting,
            subtheme: .theLongCount
        ),
        Passage(
            text: "Some desert seeds carry a chemical on the coat that has to be washed off by a certain depth of rain, so that a light shower cannot trick them into starting.",
            source: "Germination inhibitors",
            theme: .waiting,
            subtheme: .heldBack
        ),
        Passage(
            text: "Let it first blossom, then bear fruit, then ripen.",
            source: "Epictetus, tr. George Long",
            theme: .waiting,
            subtheme: .standingAndWatching
        ),
        Passage(
            text: "A garden is a grand teacher. It teaches patience and careful watchfulness.",
            source: "Gertrude Jekyll, 1899",
            theme: .waiting,
            subtheme: .standingAndWatching
        ),
        Passage(
            text: "The best fertiliser is the gardener's shadow.",
            source: "Gardener's proverb",
            theme: .waiting,
            subtheme: .standingAndWatching
        ),
        Passage(
            text: "One generation plants the trees; another gets the shade.",
            source: "Chinese proverb",
            theme: .waiting,
            subtheme: .standingAndWatching
        ),
        Passage(
            text: "Vernalisation: the long cold a seed or a bud passes through, after which spring is able to move it.",
            source: "Botany",
            theme: .waiting,
            subtheme: .heldBack
        ),
        Passage(
            text: "After-ripening: the weeks of dry keeping some seeds need before the embryo inside them is finished. A seed can look complete and not yet be.",
            source: "Botany",
            theme: .waiting,
            subtheme: .heldBack
        ),
        Passage(
            text: "Seed bank: the seeds already lying in the soil of any field or wood, a good many of them older than the plants standing over them, waiting for the ground to be opened.",
            source: "Ecology",
            theme: .waiting,
            subtheme: .heldBack
        ),
        Passage(
            text: "Latent is Latin latere, to lie hidden. A latent thing is not absent, only unnoticed.",
            source: "Latin",
            theme: .waiting,
            subtheme: .heldBack
        ),
        Passage(
            text: "Some Australian seeds will not start for heat alone. What wakes them is a chemical from the smoke of burnt plants, carried into the ground by the first rain after a fire.",
            source: "Karrikins",
            theme: .waiting,
            subtheme: .heldBack
        ),
        Passage(
            text: "Diapause: a pause an insect's development takes on purpose, entered before the hard season arrives rather than in answer to it.",
            source: "Entomology",
            theme: .waiting,
            subtheme: .heldBack
        ),
        Passage(
            text: "A season is a sowing. The word descends from Latin satio, the time at which seed goes into the ground.",
            source: "Latin",
            theme: .waiting,
            subtheme: .standingAndWatching
        ),
        Passage(
            text: "A date seed from Masada, dated to roughly two thousand years old, was sown in 2005 and grew. The tree is called Methuselah.",
            source: "Phoenix dactylifera, Israel",
            theme: .waiting,
            subtheme: .theLongCount
        ),
        Passage(
            text: "Ground squirrels buried fruits in Siberia some thirty-two thousand years ago. In 2012 the tissue inside them was grown on into whole flowering plants.",
            source: "Silene stenophylla, PNAS 2012",
            theme: .waiting,
            subtheme: .theLongCount
        ),
        Passage(
            text: "A sacred lotus seed lifted from an old lake bed in Liaoning germinated after about thirteen hundred years, and the plant is growing still.",
            source: "Nelumbo nucifera",
            theme: .waiting,
            subtheme: .theLongCount
        ),
        Passage(
            text: "Seeds were sealed into bottles and buried in 1879. A bottle opened in 2021 still held mullein seeds that woke and grew.",
            source: "Beal's seed experiment, Michigan",
            theme: .waiting,
            subtheme: .theLongCount
        ),
        Passage(
            text: "Some bamboos flower once, all together, all over the world, after more than a century. Plants from one stock keep the same clock.",
            source: "Phyllostachys bambusoides",
            theme: .waiting,
            subtheme: .theLongCount
        ),
        Passage(
            text: "Century is Latin centuria, a hundred of anything: it counted men in a legion long before it counted years.",
            source: "Latin",
            theme: .waiting,
            subtheme: .theLongCount
        ),
        Passage(
            text: "A bristlecone pine in the White Mountains of California has been alive for more than four and a half thousand years, and is still making cones.",
            source: "Pinus longaeva",
            theme: .waiting,
            subtheme: .theLongCount
        ),
        Passage(
            text: "An ocean quahog dredged off Iceland was found to carry five hundred and seven growth lines in its shell, one laid down for every year it had been alive.",
            source: "Arctica islandica",
            theme: .waiting,
            subtheme: .theLongCount
        ),
        Passage(
            text: "With time and patience the mulberry leaf becomes a silk gown.",
            source: "Chinese proverb",
            theme: .waiting,
            subtheme: .theLongCount
        ),

        // MARK: Renewal

        Passage(
            text: "If Winter comes, can Spring be far behind?",
            source: "Percy Bysshe Shelley, 1820",
            theme: .renewal,
            subtheme: .theTurningYear
        ),
        Passage(
            text: "There lives the dearest freshness deep down things.",
            source: "Gerard Manley Hopkins, 1877",
            theme: .renewal,
            subtheme: .madeWhole
        ),
        Passage(
            text: "To every thing there is a season, and a time to every purpose under the heaven.",
            source: "Ecclesiastes, King James Bible, 1611",
            theme: .renewal,
            subtheme: .theTurningYear
        ),
        Passage(
            text: "Into each life some rain must fall.",
            source: "Henry Wadsworth Longfellow, 1842",
            theme: .renewal,
            subtheme: .madeWhole
        ),
        Passage(
            text: "Fall down seven times, stand up eight.",
            source: "Japanese proverb",
            theme: .renewal,
            subtheme: .madeWhole
        ),
        Passage(
            text: "The nature of the Universe loves nothing so much as to change the things which are, and to make new things like them.",
            source: "Marcus Aurelius, tr. George Long",
            theme: .renewal,
            subtheme: .theTurningYear
        ),
        Passage(
            text: "The year's at the spring, and day's at the morn.",
            source: "Robert Browning, 1841",
            theme: .renewal,
            subtheme: .theTurningYear
        ),
        Passage(
            text: "Kintsugi: mending broken pottery with gold, so that the repair becomes the most visible thing about the bowl.",
            source: "Japanese",
            theme: .renewal,
            subtheme: .madeWhole
        ),
        Passage(
            text: "Coppicing: cutting a tree to the ground on a cycle, which does not end it but starts it again. A stool can be kept alive for centuries this way.",
            source: "Forestry",
            theme: .renewal,
            subtheme: .cutAndComeAgain
        ),
        Passage(
            text: "Serotiny: seed held inside a cone sealed with resin, which opens only in the heat of a fire.",
            source: "Botany",
            theme: .renewal,
            subtheme: .cutAndComeAgain
        ),
        Passage(
            text: "Epicormic: growth from buds that have waited years under the bark, and wake when the crown above them is lost.",
            source: "Botany",
            theme: .renewal,
            subtheme: .cutAndComeAgain
        ),
        Passage(
            text: "Resurgam: I shall rise again. Common on gravestones, where it is written as a statement rather than a hope.",
            source: "Latin",
            theme: .renewal,
            subtheme: .madeWhole
        ),
        Passage(
            text: "Anastasis: a standing up again. Biologists borrowed it for cells that begin to die and then recover.",
            source: "Greek",
            theme: .renewal,
            subtheme: .madeWhole
        ),
        Passage(
            text: "Recover is Latin recuperare, to get back. It was about retrieving a thing long before it was about health.",
            source: "Latin",
            theme: .renewal,
            subtheme: .madeWhole
        ),
        Passage(
            text: "Spring names the season for what water does. It is the same word as a spring in the ground, from Old English springan, to leap up.",
            source: "Old English",
            theme: .renewal,
            subtheme: .theTurningYear
        ),
        Passage(
            text: "Revive is Latin revivere, to live again. Vivid, survive and victuals grow from that root: to live, to outlive, and what you live on.",
            source: "Latin",
            theme: .renewal,
            subtheme: .madeWhole
        ),
        Passage(
            text: "Phoenix reaches English through Latin from Greek phoinix, which also named the date palm and the colour crimson.",
            source: "Greek",
            theme: .renewal,
            subtheme: .madeWhole
        ),
        Passage(
            text: "Renaissance is Latin renasci, to be born again. The name of the age was borrowed from what happens to a plant.",
            source: "Latin",
            theme: .renewal,
            subtheme: .madeWhole
        ),
        Passage(
            text: "Convalesce is Latin convalescere, to grow strong. The con is there for emphasis rather than company, though mending together is not a bad thing to hear in it.",
            source: "Latin",
            theme: .renewal,
            subtheme: .madeWhole
        ),
        Passage(
            text: "A coppiced lime stool in an English wood can be older than the church beside it. The tree is cut back every fifteen years or so, and the roots have never once stopped.",
            source: "Coppice woodland",
            theme: .renewal,
            subtheme: .cutAndComeAgain
        ),
        Passage(
            text: "Deciduous trees withdraw the nitrogen and phosphorus from their leaves before letting them go, so autumn colour is what is left once the valuable part has been taken back.",
            source: "Leaf senescence",
            theme: .renewal,
            subtheme: .theTurningYear
        ),
        Passage(
            text: "After Mount St Helens erupted in 1980, the first plants back were not colonists arriving but survivors that had been underground or under snow when it happened.",
            source: "Mount St Helens, 1980",
            theme: .renewal,
            subtheme: .cutAndComeAgain
        ),
        Passage(
            text: "Grasses grow from the base rather than the tip, which is why mowing does not kill a lawn and does kill most of what tries to share it.",
            source: "Poaceae",
            theme: .renewal,
            subtheme: .cutAndComeAgain
        ),
        Passage(
            text: "The flowers appear on the earth; the time of the singing of birds is come.",
            source: "Song of Solomon, King James Bible, 1611",
            theme: .renewal,
            subtheme: .theTurningYear
        ),
        Passage(
            text: "Who would have thought my shrivelled heart could have recovered greenness?",
            source: "George Herbert (1593–1633)",
            theme: .renewal,
            subtheme: .madeWhole
        ),
        Passage(
            text: "Earth laughs in flowers.",
            source: "Ralph Waldo Emerson, Hamatreya",
            theme: .renewal,
            subtheme: .theTurningYear
        ),
        Passage(
            text: "To plant seeds, and watch their renewal of life — this is the commonest delight of the race.",
            source: "Charles Dudley Warner, 1870",
            theme: .renewal,
            subtheme: .theTurningYear
        ),
        Passage(
            text: "Thrive comes from Old Norse thrifask, to grasp for oneself. Thriving was once a matter of taking hold.",
            source: "Old Norse",
            theme: .renewal,
            subtheme: .madeWhole
        ),
        Passage(
            text: "Green, grow and grass come from one Germanic root. The colour is named for what growing things do.",
            source: "Old English",
            theme: .renewal,
            subtheme: .theTurningYear
        ),
        Passage(
            text: "The equinox is not quite the day of equal light. Air bends the sun's image upward, so it seems to rise a little before it is up and to set a little after it has gone.",
            source: "Equinox and equilux",
            theme: .renewal,
            subtheme: .theTurningYear
        ),
        Passage(
            text: "Phenology: the keeping of dates for when things happen — first frog, first swift, first blackthorn. People kept the record for centuries before it was given a name.",
            source: "Phenology",
            theme: .renewal,
            subtheme: .theTurningYear
        ),
        Passage(
            text: "Six ginkgos standing within two kilometres of the Hiroshima blast came through it, put out leaves again, and are alive today.",
            source: "Hibakujumoku, Hiroshima",
            theme: .renewal,
            subtheme: .cutAndComeAgain
        ),
        Passage(
            text: "Pollarding: cutting a tree back above the height a cow or a deer can reach, so that the crop comes again and the ground beneath it can still be grazed.",
            source: "Forestry",
            theme: .renewal,
            subtheme: .cutAndComeAgain
        ),
        Passage(
            text: "Cut-and-come-again: a sowing picked by the leaf rather than by the plant, so that one short row can be gone over for months.",
            source: "Gardener's term",
            theme: .renewal,
            subtheme: .cutAndComeAgain
        ),
        Passage(
            text: "Rosebay willowherb is called fireweed for what it does after a burn: often the first colour back on cleared ground, and its spike opens from the bottom upward.",
            source: "Chamaenerion angustifolium",
            theme: .renewal,
            subtheme: .cutAndComeAgain
        ),
        Passage(
            text: "Regenerate is Latin regenerare, to bring forth again, from generare — the same root as genus and generous, all of it about stock and increase.",
            source: "Latin",
            theme: .renewal,
            subtheme: .cutAndComeAgain
        ),
        Passage(
            text: "A willow cutting pushed into wet ground roots from the bare stick. Gardeners soaked willow twigs to make a water for starting other cuttings long before anyone knew what was in it.",
            source: "Salix",
            theme: .renewal,
            subtheme: .cutAndComeAgain
        ),

        // MARK: Light

        Passage(
            text: "Let there be light.",
            source: "Genesis, King James Bible, 1611",
            theme: .light,
            subtheme: .lightItself
        ),
        Passage(
            text: "The sun is but a morning star.",
            source: "Henry David Thoreau, Walden, 1854",
            theme: .light,
            subtheme: .lightItself
        ),
        Passage(
            text: "Trailing clouds of glory do we come.",
            source: "William Wordsworth, 1807",
            theme: .light,
            subtheme: .lightItself
        ),
        Passage(
            text: "The darkest hour is just before the dawn.",
            source: "English proverb",
            theme: .light,
            subtheme: .theEdgesOfTheDay
        ),
        Passage(
            text: "More light.",
            source: "Reported as Goethe's last words, 1832",
            theme: .light,
            subtheme: .lightItself
        ),
        Passage(
            text: "Crepuscular: at home in the light of dusk and dawn, which belongs to neither day nor night.",
            source: "Latin",
            theme: .light,
            subtheme: .theEdgesOfTheDay
        ),
        Passage(
            text: "Gloaming: the last of the light, when things can still be seen but their colours cannot.",
            source: "Scots",
            theme: .light,
            subtheme: .theEdgesOfTheDay
        ),
        Passage(
            text: "Alpenglow: the red left on a mountain after the sun has gone from everything below it.",
            source: "German",
            theme: .light,
            subtheme: .theEdgesOfTheDay
        ),
        Passage(
            text: "Photoperiodism: a plant deciding when to flower by measuring the length of the night. It counts the dark rather than the light.",
            source: "Botany",
            theme: .light,
            subtheme: .readingTheLight
        ),
        Passage(
            text: "Etiolation: the pale, stretched growth of a plant kept in the dark, reaching for a light that is not there.",
            source: "Botany",
            theme: .light,
            subtheme: .readingTheLight
        ),
        Passage(
            text: "Penumbra: the ring around a shadow where the light is only partly blocked, which is why an edge is soft.",
            source: "Latin",
            theme: .light,
            subtheme: .theEdgesOfTheDay
        ),
        Passage(
            text: "Window is Old Norse vindauga, wind eye. It was a hole for the weather before it was a hole for the light.",
            source: "Old Norse",
            theme: .light,
            subtheme: .lightItself
        ),
        Passage(
            text: "Lucid, elucidate and Lucifer share Latin lux. To make a thing clear is to bring light to it.",
            source: "Latin",
            theme: .light,
            subtheme: .lightItself
        ),
        Passage(
            text: "Solstice is Latin sol and sistere, the sun standing still: for a few days at midsummer it rises in nearly the same place.",
            source: "Latin",
            theme: .light,
            subtheme: .lightItself
        ),
        Passage(
            text: "Phosphorus is Greek for light-bearer. It named the morning star long before it named the element that glows in the dark.",
            source: "Greek",
            theme: .light,
            subtheme: .lightItself
        ),
        Passage(
            text: "Twilight is usually read as two-light, the Old English prefix meaning two: the light belonging to neither side of the day.",
            source: "Old English",
            theme: .light,
            subtheme: .theEdgesOfTheDay
        ),
        Passage(
            text: "Leaves are green because chlorophyll uses the red and blue of daylight and reflects the green it cannot use. A plant is the colour of the light it has no use for.",
            source: "Chlorophyll",
            theme: .light,
            subtheme: .readingTheLight
        ),
        Passage(
            text: "Some flowers carry ultraviolet markings that run to the middle like a landing strip. A bee can see them and we cannot.",
            source: "Nectar guides",
            theme: .light,
            subtheme: .readingTheLight
        ),
        Passage(
            text: "A full moon is roughly four hundred thousand times fainter than the sun, and the eye adjusts so completely that it does not feel like it.",
            source: "Lunar illumination",
            theme: .light,
            subtheme: .lightItself
        ),
        Passage(
            text: "Only a few per cent of the light falling on a wood reaches its floor, which is why so much woodland flowering is finished before the trees come into leaf.",
            source: "Woodland canopy",
            theme: .light,
            subtheme: .readingTheLight
        ),
        Passage(
            text: "Light crosses from the sun to a leaf in about eight minutes, having spent tens of thousands of years getting from the sun's core to its surface.",
            source: "Solar physics",
            theme: .light,
            subtheme: .lightItself
        ),
        Passage(
            text: "I saw Eternity the other night, like a great ring of pure and endless light.",
            source: "Henry Vaughan (1621–1695)",
            theme: .light,
            subtheme: .lightItself
        ),
        Passage(
            text: "The sky is blue because air scatters the short waves of daylight in every direction at once. Seen through far more air at the end of the day, the same scattering leaves red.",
            source: "Rayleigh scattering",
            theme: .light,
            subtheme: .lightItself
        ),
        Passage(
            text: "Now I see the secret of the making of the best persons: it is to grow in the open air.",
            source: "Walt Whitman, 1856",
            theme: .light,
            subtheme: .readingTheLight
        ),
        Passage(
            text: "Apricity: the warmth of the sun as it is felt on a winter's day.",
            source: "English, first recorded 1623",
            theme: .light,
            subtheme: .theEdgesOfTheDay
        ),
        Passage(
            text: "Heliotropism: the turning of a plant through the day so that it keeps its face to the sun.",
            source: "Botany",
            theme: .light,
            subtheme: .readingTheLight
        ),
        Passage(
            text: "Nyctinasty: the folding of leaves and petals at dusk, and their opening again with the light.",
            source: "Botany",
            theme: .light,
            subtheme: .readingTheLight
        ),
        Passage(
            text: "Anthesis: the span of a flower's life during which it stands open.",
            source: "Botany",
            theme: .light,
            subtheme: .readingTheLight
        ),
        Passage(
            text: "Gökotta: rising at first light to go outside and listen to the earliest birds.",
            source: "Swedish",
            theme: .light,
            subtheme: .theEdgesOfTheDay
        ),
        Passage(
            text: "Dusk is measured in three depths: civil, while you can still read outdoors; nautical, while the horizon can still be told from the sea; and astronomical, after which the sky gets no darker.",
            source: "Twilight, by degrees",
            theme: .light,
            subtheme: .theEdgesOfTheDay
        ),
        Passage(
            text: "The green flash: on a clear horizon the last speck of the setting sun can turn green for a second, because the air bends each colour by a slightly different amount.",
            source: "Atmospheric refraction",
            theme: .light,
            subtheme: .theEdgesOfTheDay
        ),
        Passage(
            text: "Dayspring: an old name for daybreak, built on spring in its first sense, which is a rising — the way water rises in a spring.",
            source: "English",
            theme: .light,
            subtheme: .theEdgesOfTheDay
        ),
        Passage(
            text: "Evening is Old English æfnung, from a verb meaning to draw on towards night. Eve, even and evensong are the same word underneath.",
            source: "Old English",
            theme: .light,
            subtheme: .theEdgesOfTheDay
        ),
        Passage(
            text: "Daisy is the day's eye, named for a flower that opens with the light and closes again at dusk.",
            source: "Old English",
            theme: .light,
            subtheme: .readingTheLight
        ),
        Passage(
            text: "Young sunflowers follow the sun west and swing back east overnight. Grown ones settle facing east, where morning warmth brings the bees earlier.",
            source: "Science, 2016",
            theme: .light,
            subtheme: .readingTheLight
        ),
        Passage(
            text: "Phytochrome: the pigment a plant reads light with, switched one way by red and back again by far-red, which is how a seed can tell it is lying in somebody else's shade.",
            source: "Botany",
            theme: .light,
            subtheme: .readingTheLight
        ),

        // MARK: Pattern

        Passage(
            text: "The universe is written in the language of mathematics, and its characters are triangles, circles and other figures.",
            source: "Galileo, Il Saggiatore, 1623",
            theme: .pattern,
            subtheme: .orderNamed
        ),
        Passage(
            text: "The form of an object is a diagram of forces.",
            source: "D'Arcy Thompson, On Growth and Form, 1917",
            theme: .pattern,
            subtheme: .orderNamed
        ),
        Passage(
            text: "What immortal hand or eye could frame thy fearful symmetry?",
            source: "William Blake, 1794",
            theme: .pattern,
            subtheme: .orderNamed
        ),
        Passage(
            text: "The universe is represented in every one of its particles.",
            source: "Ralph Waldo Emerson, Compensation, 1841",
            theme: .pattern,
            subtheme: .orderNamed
        ),
        Passage(
            text: "God ever geometrises.",
            source: "Attributed to Plato by Plutarch",
            theme: .pattern,
            subtheme: .orderNamed
        ),
        Passage(
            text: "As above, so below.",
            source: "Hermetic maxim",
            theme: .pattern,
            subtheme: .orderNamed
        ),
        Passage(
            text: "Quincunx: five set as on a die, four at the corners and one in the middle. Orchards are still planted this way because it fits the most trees into the ground.",
            source: "Latin",
            theme: .pattern,
            subtheme: .counted
        ),
        Passage(
            text: "Tessellation: shapes meeting edge to edge with nothing left over, which is what a honeycomb is.",
            source: "Geometry",
            theme: .pattern,
            subtheme: .fittedTogether
        ),
        Passage(
            text: "Fractal: a shape that keeps its character at every scale, so that a piece of a fern frond looks like the fern.",
            source: "Geometry",
            theme: .pattern,
            subtheme: .fittedTogether
        ),
        Passage(
            text: "Decussate: leaves in pairs, each pair turned a right angle from the pair below, so that no leaf sits directly over another.",
            source: "Botany",
            theme: .pattern,
            subtheme: .fittedTogether
        ),
        Passage(
            text: "Radial and bilateral: a daisy faces every direction at once, an orchid faces you. Almost every flower is one or the other.",
            source: "Floral symmetry",
            theme: .pattern,
            subtheme: .fittedTogether
        ),
        Passage(
            text: "Umbel: a flower head where every stalk springs from one point and rises to the same height, as cow parsley does.",
            source: "Botany",
            theme: .pattern,
            subtheme: .fittedTogether
        ),
        Passage(
            text: "Pattern and patron are one word, from Latin patronus. A pattern was the model a thing was made to, as a patron was the model to follow.",
            source: "Latin",
            theme: .pattern,
            subtheme: .orderNamed
        ),
        Passage(
            text: "Symmetry is Greek for measured together: syn, with, and metron, a measure.",
            source: "Greek",
            theme: .pattern,
            subtheme: .counted
        ),
        Passage(
            text: "Rhythm comes from Greek rhein, to flow. A rhythm is a flowing, measured out.",
            source: "Greek",
            theme: .pattern,
            subtheme: .orderNamed
        ),
        Passage(
            text: "Cosmos is Greek kosmos, order and ornament in one word. The same root gives cosmetic: to call the universe a cosmos was to call it well arranged.",
            source: "Greek",
            theme: .pattern,
            subtheme: .orderNamed
        ),
        Passage(
            text: "Calculate is Latin calculus, a pebble. Counting was done with stones long before it was done with signs.",
            source: "Latin",
            theme: .pattern,
            subtheme: .counted
        ),
        Passage(
            text: "Order is Latin ordo, thought to begin with the row of threads on a loom. The word for arrangement started at the weaver's frame.",
            source: "Latin",
            theme: .pattern,
            subtheme: .orderNamed
        ),
        Passage(
            text: "Every bird in a murmuration watches only its six or seven nearest neighbours, whatever the distance between them. Nothing more is needed to make the shape of the flock.",
            source: "Flocking, 2008",
            theme: .pattern,
            subtheme: .counted
        ),
        Passage(
            text: "Honeybee cells begin round and settle into hexagons as the wax warms. A hexagon holds the most floor for the least wall.",
            source: "Apis mellifera",
            theme: .pattern,
            subtheme: .fittedTogether
        ),
        Passage(
            text: "A snowflake's six arms match because they grew in the same air at the same instant, not because any arm can see another.",
            source: "Crystal growth",
            theme: .pattern,
            subtheme: .fittedTogether
        ),
        Passage(
            text: "Zebra stripes, leopard spots and the markings on a fish can all come from two chemicals spreading and reacting at different rates, a mechanism Alan Turing set out in 1952.",
            source: "Turing patterns",
            theme: .pattern,
            subtheme: .fittedTogether
        ),
        Passage(
            text: "Pine cones, pineapples and daisy heads count their spirals in Fibonacci numbers because each new part is set in the largest gap the ones before it left.",
            source: "Phyllotaxis",
            theme: .pattern,
            subtheme: .counted
        ),
        Passage(
            text: "It is interesting to contemplate an entangled bank, clothed with many plants of many kinds.",
            source: "Charles Darwin, 1859",
            theme: .pattern,
            subtheme: .orderNamed
        ),
        Passage(
            text: "Rose is a rose is a rose is a rose.",
            source: "Gertrude Stein, 1913",
            theme: .pattern,
            subtheme: .orderNamed
        ),
        Passage(
            text: "An anthology is a gathering of flowers: Greek anthos, flower, and legein, to gather up.",
            source: "Greek",
            theme: .pattern,
            subtheme: .orderNamed
        ),
        Passage(
            text: "New leaves are set about 137.5 degrees around from the last, the one angle at which every leaf keeps a share of the light.",
            source: "Phyllotaxis, the golden angle",
            theme: .pattern,
            subtheme: .counted
        ),
        Passage(
            text: "Count the spirals in a sunflower head each way and you will nearly always land on two neighbouring Fibonacci numbers, such as 34 and 55.",
            source: "Helianthus annuus",
            theme: .pattern,
            subtheme: .counted
        ),
        Passage(
            text: "Pollen wears a sculpted coat of sporopollenin, tough enough that grains keep their pattern in peat for thousands of years and can still be named.",
            source: "Palynology",
            theme: .pattern,
            subtheme: .fittedTogether
        ),
        Passage(
            text: "A daisy is a crowd rather than a flower. The yellow middle is hundreds of small blooms packed together, and every white ray around the edge is one more.",
            source: "Asteraceae",
            theme: .pattern,
            subtheme: .fittedTogether
        ),
        Passage(
            text: "Aestivation: the way petals are folded against one another inside the bud — overlapped like roof tiles, or twisted like a furled umbrella. Each family folds its own way.",
            source: "Botany",
            theme: .pattern,
            subtheme: .fittedTogether
        ),
        Passage(
            text: "Cooling basalt cracks into columns and drying mud cracks into plates for one reason: where three cracks meet, the work is shared most evenly at a hundred and twenty degrees.",
            source: "Columnar jointing",
            theme: .pattern,
            subtheme: .fittedTogether
        ),
        Passage(
            text: "A returning honeybee dances the angle of the flowers against the sun, and the length of her waggle tells the others how far to fly.",
            source: "Karl von Frisch",
            theme: .pattern,
            subtheme: .counted
        ),
        Passage(
            text: "Tally is Latin talea, a rod or a cutting: a stick notched across and then split, so that two people each went away holding half of one count.",
            source: "Latin",
            theme: .pattern,
            subtheme: .counted
        ),
        Passage(
            text: "Clover comes in threes so reliably that a fourth leaf is worth the looking: roughly one stem in five thousand carries one.",
            source: "Trifolium repens",
            theme: .pattern,
            subtheme: .counted
        ),
        Passage(
            text: "Whorl: leaves or petals set three or more to a ring at one height on the stem, so that the count is read around rather than along.",
            source: "Botany",
            theme: .pattern,
            subtheme: .counted
        ),
        Passage(
            text: "God made the whole numbers; all the rest is the work of man.",
            source: "Leopold Kronecker (1823–1891), as reported",
            theme: .pattern,
            subtheme: .counted
        ),

        // MARK: Ground

        Passage(
            text: "There is nothing like staying at home for real comfort.",
            source: "Jane Austen, Emma, 1815",
            theme: .ground,
            subtheme: .aPlaceYouAreFrom
        ),
        Passage(
            text: "We must cultivate our garden.",
            source: "Voltaire, Candide, 1759, rendered plainly",
            theme: .ground,
            subtheme: .aKeptPlace
        ),
        Passage(
            text: "God made the country, and man made the town.",
            source: "William Cowper, 1785",
            theme: .ground,
            subtheme: .aKeptPlace
        ),
        Passage(
            text: "How fortunate the farmers are, if only they knew it.",
            source: "Virgil, Georgics, rendered plainly",
            theme: .ground,
            subtheme: .aKeptPlace
        ),
        Passage(
            text: "East, west, home's best.",
            source: "English proverb",
            theme: .ground,
            subtheme: .aPlaceYouAreFrom
        ),
        Passage(
            text: "Terroir: everything about a place that gets into what grows there, and none of which can be moved along with the plant.",
            source: "French",
            theme: .ground,
            subtheme: .theSoilItself
        ),
        Passage(
            text: "Rhizosphere: the few millimetres of soil around a root, unlike any other soil on earth because the root has been at work on it.",
            source: "Botany",
            theme: .ground,
            subtheme: .theSoilItself
        ),
        Passage(
            text: "Topophilia: love of one particular place, which is a different feeling from a love of places.",
            source: "Greek",
            theme: .ground,
            subtheme: .aPlaceYouAreFrom
        ),
        Passage(
            text: "Heimat: the place you are from, carrying rather more than the English word home can hold.",
            source: "German",
            theme: .ground,
            subtheme: .aPlaceYouAreFrom
        ),
        Passage(
            text: "An acre was the ground a yoke of oxen could plough in a day, which is why it is such an odd number of square yards.",
            source: "Old English",
            theme: .ground,
            subtheme: .aKeptPlace
        ),
        Passage(
            text: "Country is Latin contra, opposite: the land lying over against you when you stand and look out.",
            source: "Latin",
            theme: .ground,
            subtheme: .aPlaceYouAreFrom
        ),
        Passage(
            text: "Territory is Latin terra, earth, though Roman writers liked to tie it to terrere, to frighten. Land held by keeping others off it.",
            source: "Latin",
            theme: .ground,
            subtheme: .aPlaceYouAreFrom
        ),
        Passage(
            text: "Meadow and mow come from one root. A meadow is a place that gets cut.",
            source: "Old English",
            theme: .ground,
            subtheme: .aKeptPlace
        ),
        Passage(
            text: "A teaspoon of healthy soil holds more living organisms than there are people on earth.",
            source: "Soil biology",
            theme: .ground,
            subtheme: .theSoilItself
        ),
        Passage(
            text: "It can take several hundred years to build a centimetre of topsoil, and one storm on bare ground to take it away.",
            source: "Soil formation",
            theme: .ground,
            subtheme: .theSoilItself
        ),
        Passage(
            text: "Chalk downland can carry forty species of plant in a single square metre, precisely because the soil is too poor for any one of them to take over.",
            source: "Chalk grassland",
            theme: .ground,
            subtheme: .theSoilItself
        ),
        Passage(
            text: "Earthworms pass the whole topsoil of a field through their bodies every few years. Darwin spent forty years working this out and made it his last book.",
            source: "Darwin on worms, 1881",
            theme: .ground,
            subtheme: .theSoilItself
        ),
        Passage(
            text: "If you have a garden in your library, nothing will be wanting.",
            source: "Cicero, letter to Varro, 46 BC",
            theme: .ground,
            subtheme: .aKeptPlace
        ),
        Passage(
            text: "God Almighty first planted a garden; and indeed it is the purest of human pleasures.",
            source: "Francis Bacon, 1625",
            theme: .ground,
            subtheme: .aKeptPlace
        ),
        Passage(
            text: "I found the poems in the fields, and only wrote them down.",
            source: "John Clare (1793–1864)",
            theme: .ground,
            subtheme: .aKeptPlace
        ),
        Passage(
            text: "Long live the weeds and the wilderness yet.",
            source: "Gerard Manley Hopkins (1844–1889)",
            theme: .ground,
            subtheme: .aKeptPlace
        ),
        Passage(
            text: "Petrichor: the smell that lifts off dry ground when rain first reaches it.",
            source: "English, coined 1964",
            theme: .ground,
            subtheme: .theSoilItself
        ),
        Passage(
            text: "Querencia: the place a creature keeps returning to, where it is most itself and draws its strength.",
            source: "Spanish",
            theme: .ground,
            subtheme: .aPlaceYouAreFrom
        ),
        Passage(
            text: "Smultronställe: a wild-strawberry place, a small treasured spot you go back to on your own.",
            source: "Swedish",
            theme: .ground,
            subtheme: .aPlaceYouAreFrom
        ),
        Passage(
            text: "Paradise began as a walled garden: Old Persian pairidaeza, an enclosure planted for pleasure.",
            source: "Old Persian",
            theme: .ground,
            subtheme: .aKeptPlace
        ),
        Passage(
            text: "Garden, yard and girdle share one root meaning an enclosure. A garden is first of all a kept place.",
            source: "Proto-Germanic",
            theme: .ground,
            subtheme: .aKeptPlace
        ),
        Passage(
            text: "A neighbour is a near-dweller: Old English neah, near, and gebur, one who lives here.",
            source: "Old English",
            theme: .ground,
            subtheme: .aPlaceYouAreFrom
        ),
        Passage(
            text: "Hiraeth: a Welsh longing for a place, which can be felt as readily for somewhere you are standing in as for somewhere you have left.",
            source: "Welsh",
            theme: .ground,
            subtheme: .aPlaceYouAreFrom
        ),
        Passage(
            text: "Home is Old English ham, which meant a village as readily as a house. It is still on the map in every place name ending in -ham.",
            source: "Old English",
            theme: .ground,
            subtheme: .aPlaceYouAreFrom
        ),
        Passage(
            text: "A salmon finds the river it hatched in by its smell, having learned that water as a young fish and carried it for years at sea.",
            source: "Salmo salar",
            theme: .ground,
            subtheme: .aPlaceYouAreFrom
        ),
        Passage(
            text: "Human, humble and humus grow from a single Latin root: the ground itself.",
            source: "Latin",
            theme: .ground,
            subtheme: .theSoilItself
        ),
        Passage(
            text: "Culture and cultivate come from Latin colere: to till the ground, to tend it, and to hold it in honour.",
            source: "Latin",
            theme: .ground,
            subtheme: .aKeptPlace
        ),
        Passage(
            text: "One seagrass in the Mediterranean has spread sideways for perhaps a hundred thousand years, and the whole meadow counts as a single plant.",
            source: "Posidonia oceanica",
            theme: .ground,
            subtheme: .theSoilItself
        ),
        Passage(
            text: "Loam: sand, silt and clay in something near equal measure, which is what lets a soil take up water and let go of it in the same afternoon.",
            source: "Soil science",
            theme: .ground,
            subtheme: .theSoilItself
        ),
        Passage(
            text: "Chernozem, podzol and gley came into English from Russian, where soils were first described and mapped as things in their own right. The names travelled with the science.",
            source: "Russian",
            theme: .ground,
            subtheme: .theSoilItself
        ),
        Passage(
            text: "Most of the weight of a tree came out of the air. The carbon in the wood was carbon dioxide, and the ground supplied the water and the smaller part of the rest.",
            source: "Photosynthesis",
            theme: .ground,
            subtheme: .theSoilItself
        ),

        // MARK: Travel

        Passage(
            text: "The journey of a thousand li commenced with a single step.",
            source: "Laozi, tr. James Legge",
            theme: .travel,
            subtheme: .theRoad
        ),
        Passage(
            text: "He travels the fastest who travels alone.",
            source: "Rudyard Kipling, 1890",
            theme: .travel,
            subtheme: .theRoad
        ),
        Passage(
            text: "Afoot and light-hearted I take to the open road.",
            source: "Walt Whitman, 1856",
            theme: .travel,
            subtheme: .theRoad
        ),
        Passage(
            text: "There is no frigate like a book to take us lands away.",
            source: "Emily Dickinson (1830–1886)",
            theme: .travel,
            subtheme: .farOff
        ),
        Passage(
            text: "All roads lead to Rome.",
            source: "Medieval proverb",
            theme: .travel,
            subtheme: .theRoad
        ),
        Passage(
            text: "Myrmecochory: travel by ant. The seed carries an oil body the ants want, so they take the whole thing home, eat that part and leave the rest on the refuse heap.",
            source: "Botany",
            theme: .travel,
            subtheme: .howASeedGoes
        ),
        Passage(
            text: "Ballochory: seeds thrown by the plant itself, which spends the dry weeks building tension and then lets go.",
            source: "Botany",
            theme: .travel,
            subtheme: .howASeedGoes
        ),
        Passage(
            text: "Zoochory: travel by animal, where a seed makes its whole journey inside or attached to something that walks.",
            source: "Botany",
            theme: .travel,
            subtheme: .howASeedGoes
        ),
        Passage(
            text: "Fernweh: an ache for far-off places, and the exact opposite number to homesickness.",
            source: "German",
            theme: .travel,
            subtheme: .farOff
        ),
        Passage(
            text: "Vagary: a wandering. It meant a stray journey long before it meant a stray notion.",
            source: "Latin",
            theme: .travel,
            subtheme: .farOff
        ),
        Passage(
            text: "Tramontane: from beyond the mountains. Said of a wind, and of a stranger.",
            source: "Italian",
            theme: .travel,
            subtheme: .farOff
        ),
        Passage(
            text: "Travel and travail are one word, descended from the name of an instrument of torture. To travel was to suffer, and the road saw to the rest.",
            source: "Old French",
            theme: .travel,
            subtheme: .theRoad
        ),
        Passage(
            text: "Arrive is Latin ad ripam, to the shore. Every arrival was a landing before it was anything else.",
            source: "Latin",
            theme: .travel,
            subtheme: .theRoad
        ),
        Passage(
            text: "A journey is a day: Old French journee, the ground a person could cover between one dawn and the next.",
            source: "Old French",
            theme: .travel,
            subtheme: .theRoad
        ),
        Passage(
            text: "Pilgrim is Latin peregrinus, one from beyond the fields, which is to say a foreigner. The holy part came later.",
            source: "Latin",
            theme: .travel,
            subtheme: .farOff
        ),
        Passage(
            text: "Nomad is Greek nomas, one who moves for pasture, from nemein, to graze. The word is about grass before it is about restlessness.",
            source: "Greek",
            theme: .travel,
            subtheme: .farOff
        ),
        Passage(
            text: "A sandbox tree pod dries until it bursts with a crack, throwing its seeds at something like two hundred and fifty kilometres an hour.",
            source: "Hura crepitans",
            theme: .travel,
            subtheme: .howASeedGoes
        ),
        Passage(
            text: "Mistletoe arrives glued to a branch because a bird cannot easily let the seed go, and wipes its beak clean on the bark.",
            source: "Viscum album",
            theme: .travel,
            subtheme: .howASeedGoes
        ),
        Passage(
            text: "Sea beans from the Caribbean wash up on Scottish beaches, carried by the Gulf Stream, and were once kept as charms by people who had no idea where they came from.",
            source: "Entada gigas",
            theme: .travel,
            subtheme: .farOff
        ),
        Passage(
            text: "Krakatoa was sterilised in 1883. Seeds arrived by sea and by bird, and a forest stood there again within fifty years.",
            source: "Krakatoa, after 1883",
            theme: .travel,
            subtheme: .howASeedGoes
        ),
        Passage(
            text: "Swallows were once believed to spend the winter in the mud at the bottom of ponds, because nobody could credit that they went as far as they do.",
            source: "Pre-Victorian natural history",
            theme: .travel,
            subtheme: .farOff
        ),
        Passage(
            text: "Good company in a journey makes the way to seem the shorter.",
            source: "Izaak Walton, after an Italian saying, 1653",
            theme: .travel,
            subtheme: .theRoad
        ),
        Passage(
            text: "To travel hopefully is a better thing than to arrive.",
            source: "Robert Louis Stevenson, 1881",
            theme: .travel,
            subtheme: .theRoad
        ),
        Passage(
            text: "May the road rise up to meet you.",
            source: "Traditional Irish blessing",
            theme: .travel,
            subtheme: .theRoad
        ),
        Passage(
            text: "A road is a riding: Old English rad, from ridan, to ride. The word named the going before it named the ground gone over.",
            source: "Old English",
            theme: .travel,
            subtheme: .theRoad
        ),
        Passage(
            text: "The Ridgeway keeps to the chalk because the high ground stayed passable in the months when the clay below it did not. People have walked that line for some five thousand years.",
            source: "The Ridgeway",
            theme: .travel,
            subtheme: .theRoad
        ),
        Passage(
            text: "Anemochory: travel by wind, where a seed makes its entire journey on moving air.",
            source: "Botany",
            theme: .travel,
            subtheme: .howASeedGoes
        ),
        Passage(
            text: "Volunteer: a plant that arrives of its own accord and grows in ground that somebody else left bare.",
            source: "Gardener's term",
            theme: .travel,
            subtheme: .howASeedGoes
        ),
        Passage(
            text: "Horace Walpole coined serendipity in 1754 from Serendip, an old name for Sri Lanka, after a tale of three lucky princes.",
            source: "English, 1754",
            theme: .travel,
            subtheme: .farOff
        ),
        Passage(
            text: "The Arctic tern keeps to summer at both ends of the earth, and over a long life will fly something like the distance to the moon and back three times.",
            source: "Sterna paradisaea",
            theme: .travel,
            subtheme: .farOff
        ),
        Passage(
            text: "Ultramarine is blue from over the sea: Latin ultra marinus. The stone it was ground from came by ship from a single valley in Afghanistan.",
            source: "Latin, and lapis lazuli",
            theme: .travel,
            subtheme: .farOff
        ),
        Passage(
            text: "Come, my friends, 'tis not too late to seek a newer world.",
            source: "Alfred Tennyson, Ulysses, 1842",
            theme: .travel,
            subtheme: .farOff
        ),
        Passage(
            text: "A dandelion's parachute holds a ring of circling air just above itself, and that steady vortex is what carries a seed a mile from home.",
            source: "Nature, 2018",
            theme: .travel,
            subtheme: .howASeedGoes
        ),
        Passage(
            text: "Burdock burs caught on a Swiss engineer's dog in 1941. He put the hooks under a microscope, and the result was Velcro.",
            source: "Arctium, and George de Mestral",
            theme: .travel,
            subtheme: .howASeedGoes
        ),
        Passage(
            text: "A coconut can float for months across open ocean and root where it comes ashore. Whole island floras arrived that way.",
            source: "Cocos nucifera",
            theme: .travel,
            subtheme: .howASeedGoes
        ),
        Passage(
            text: "Hydrochory: travel by water, where a seed is built to float — an air pocket, a corky coat — and goes wherever the current is already going.",
            source: "Botany",
            theme: .travel,
            subtheme: .howASeedGoes
        ),

        // MARK: Meeting

        Passage(
            text: "Journeys end in lovers meeting.",
            source: "William Shakespeare, Twelfth Night",
            theme: .meeting,
            subtheme: .theMoment
        ),
        Passage(
            text: "Ships that pass in the night, and speak each other in passing.",
            source: "Henry Wadsworth Longfellow, 1863",
            theme: .meeting,
            subtheme: .theMoment
        ),
        Passage(
            text: "Chance favours only the prepared mind.",
            source: "Louis Pasteur, 1854, rendered plainly",
            theme: .meeting,
            subtheme: .theMoment
        ),
        Passage(
            text: "No one ever steps into the same river twice.",
            source: "Attributed to Heraclitus",
            theme: .meeting,
            subtheme: .theMoment
        ),
        Passage(
            text: "Anagnorisis: the turn in a story where one person recognises who another has been all along.",
            source: "Greek",
            theme: .meeting,
            subtheme: .theMoment
        ),
        Passage(
            text: "Xenia: the old Greek obligation between a host and a stranger, binding on both of them, and enforced by Zeus.",
            source: "Greek",
            theme: .meeting,
            subtheme: .theMannersOfIt
        ),
        Passage(
            text: "Rendezvous: a French imperative meaning present yourselves. The word was an instruction before it was a place.",
            source: "French",
            theme: .meeting,
            subtheme: .theMannersOfIt
        ),
        Passage(
            text: "Liminal: on the threshold. From Latin limen, the stone laid under a door.",
            source: "Latin",
            theme: .meeting,
            subtheme: .theMannersOfIt
        ),
        Passage(
            text: "Protandry: a flower shedding its pollen before its own stigma is ready, so that it cannot meet itself.",
            source: "Botany",
            theme: .meeting,
            subtheme: .twoThatNeedEachOther
        ),
        Passage(
            text: "Flower constancy: a bee that has found one kind of bloom keeps returning to that kind, which is the whole reason it is any use to the flower.",
            source: "Pollination",
            theme: .meeting,
            subtheme: .twoThatNeedEachOther
        ),
        Passage(
            text: "Introduce is Latin introducere, to lead inside. An introduction is a door being held open.",
            source: "Latin",
            theme: .meeting,
            subtheme: .theMannersOfIt
        ),
        Passage(
            text: "Coincide is Latin co and incidere, to fall together. It is the same falling as in chance.",
            source: "Latin",
            theme: .meeting,
            subtheme: .theMoment
        ),
        Passage(
            text: "Acquaint comes through Old French from Latin accognoscere, to come to know. The word describes a beginning rather than a state.",
            source: "Latin",
            theme: .meeting,
            subtheme: .theMannersOfIt
        ),
        Passage(
            text: "Random is Old French randon, a headlong rush. It meant speed for centuries before it meant chance.",
            source: "Old French",
            theme: .meeting,
            subtheme: .theMoment
        ),
        Passage(
            text: "Threshold is Old English therscwold, from threshing: the board at the door that kept the beaten grain inside.",
            source: "Old English",
            theme: .meeting,
            subtheme: .theMannersOfIt
        ),
        Passage(
            text: "Nearly every fig has its own species of wasp, and neither can reproduce without the other. The wasp enters through a hole so tight that it loses its wings getting in.",
            source: "Ficus and Agaonidae",
            theme: .meeting,
            subtheme: .twoThatNeedEachOther
        ),
        Passage(
            text: "Vanilla is pollinated by hand nearly everywhere it is grown, because the bee that does the job lives only in Mexico.",
            source: "Vanilla planifolia",
            theme: .meeting,
            subtheme: .twoThatNeedEachOther
        ),
        Passage(
            text: "Some orchids look and smell enough like a female wasp that the males try to mate with them, and carry the pollen away without ever meeting a wasp.",
            source: "Ophrys",
            theme: .meeting,
            subtheme: .twoThatNeedEachOther
        ),
        Passage(
            text: "A yucca moth packs pollen into the flower deliberately and lays its eggs in the ovary. A plant given too many eggs drops the whole flower, which keeps the bargain honest.",
            source: "Yucca and Tegeticula",
            theme: .meeting,
            subtheme: .twoThatNeedEachOther
        ),
        Passage(
            text: "Interfulgence: a shining between things rather than upon them. Johnson listed the word in 1755, and the Oxford English Dictionary has found three uses of it in all.",
            source: "English, rare",
            theme: .meeting,
            subtheme: .theMannersOfIt
        ),
        Passage(
            text: "The world puts off its mask of vastness to its lover. It becomes small as one song, as one kiss of the eternal.",
            source: "Rabindranath Tagore, Stray Birds, 1916",
            theme: .meeting,
            subtheme: .theMannersOfIt
        ),
        Passage(
            text: "Ichigo ichie: one meeting, one chance. This gathering is the only one of its kind, so meet it whole.",
            source: "Japanese, from the way of tea",
            theme: .meeting,
            subtheme: .theMoment
        ),
        Passage(
            text: "Thigmotropism: growth steered by touch, as a tendril winds around whatever it happens to meet.",
            source: "Botany",
            theme: .meeting,
            subtheme: .twoThatNeedEachOther
        ),
        Passage(
            text: "Kairos: the opening in time when a thing can be done. The right moment, as distinct from the hour on the clock.",
            source: "Ancient Greek",
            theme: .meeting,
            subtheme: .theMoment
        ),
        Passage(
            text: "Clinamen: the faint swerve by which falling atoms come to meet one another, and so make a world.",
            source: "Lucretius, first century BC",
            theme: .meeting,
            subtheme: .theMoment
        ),
        Passage(
            text: "To meet is to come to the moot: Old English metan, from gemot, the gathering where matters were settled.",
            source: "Old English",
            theme: .meeting,
            subtheme: .theMannersOfIt
        ),
        Passage(
            text: "Encounter reaches English from Latin in contra, to come face to face with whatever stands opposite.",
            source: "Old French",
            theme: .meeting,
            subtheme: .theMannersOfIt
        ),
        Passage(
            text: "Salute and salutary both come from Latin salus, health. A greeting was a wish for someone's soundness before it was a word.",
            source: "Latin",
            theme: .meeting,
            subtheme: .theMannersOfIt
        ),
        Passage(
            text: "Hongi: the Māori greeting in which two people press nose and forehead together, and one breath is shared between them.",
            source: "Māori",
            theme: .meeting,
            subtheme: .theMannersOfIt
        ),
        Passage(
            text: "Chance descends from Latin cadere, to fall. A chance is simply the way things happened to fall out.",
            source: "Latin",
            theme: .meeting,
            subtheme: .theMoment
        ),
        Passage(
            text: "Happy and happen are one word: Old Norse happ, chance or luck. To be happy was first of all to be well befallen.",
            source: "Old Norse",
            theme: .meeting,
            subtheme: .theMoment
        ),
        Passage(
            text: "Many flowers read the pollen that lands on them and open a path for a stranger's grain, so that the next generation comes from two.",
            source: "Self-incompatibility in plants",
            theme: .meeting,
            subtheme: .twoThatNeedEachOther
        ),
        Passage(
            text: "Flowers carry a faint electric charge. A bumblebee can feel it, and read from it which blooms another bee has lately emptied.",
            source: "Science, 2013",
            theme: .meeting,
            subtheme: .twoThatNeedEachOther
        ),
        Passage(
            text: "A Brazil nut tree needs a bee strong enough to force its flowers open and an agouti willing to gnaw the pod, and fruits well only where both live. The crop is still gathered wild.",
            source: "Bertholletia excelsa",
            theme: .meeting,
            subtheme: .twoThatNeedEachOther
        ),
        Passage(
            text: "Obligate: said of a partnership neither side can leave. From Latin obligare, to bind, which is the same binding as in obliged.",
            source: "Latin",
            theme: .meeting,
            subtheme: .twoThatNeedEachOther
        ),
        Passage(
            text: "Cleaner wrasse keep a station on the reef, and much larger fish queue at it and hold still with their mouths open to be gone over.",
            source: "Labroides dimidiatus",
            theme: .meeting,
            subtheme: .twoThatNeedEachOther
        ),

        // MARK: Kinship

        Passage(
            text: "No man is an island, entire of itself.",
            source: "John Donne, 1624",
            theme: .kinship,
            subtheme: .twoPeople
        ),
        Passage(
            text: "Two are better than one; because they have a good reward for their labour.",
            source: "Ecclesiastes, King James Bible, 1611",
            theme: .kinship,
            subtheme: .twoPeople
        ),
        Passage(
            text: "The children of Adam are limbs of one body.",
            source: "Sa'di, Gulistan, 1258",
            theme: .kinship,
            subtheme: .twoPeople
        ),
        Passage(
            text: "Friendship makes prosperity brighter, and lightens adversity by dividing it.",
            source: "Cicero, On Friendship, rendered plainly",
            theme: .kinship,
            subtheme: .twoPeople
        ),
        Passage(
            text: "A friend in need is a friend indeed.",
            source: "English proverb",
            theme: .kinship,
            subtheme: .twoPeople
        ),
        Passage(
            text: "Anastomosis: two separate channels joining into one. Said of rivers, of blood vessels, and of the veins in a leaf.",
            source: "Greek",
            theme: .kinship,
            subtheme: .grownTogether
        ),
        Passage(
            text: "Mutualism: both partners better off, and neither able to leave without paying for it.",
            source: "Ecology",
            theme: .kinship,
            subtheme: .grownTogether
        ),
        Passage(
            text: "Commensalism: one partner gains and the other is untroubled either way. A quieter arrangement than symbiosis, and far more common.",
            source: "Ecology",
            theme: .kinship,
            subtheme: .grownTogether
        ),
        Passage(
            text: "Holobiont: an organism counted together with everything living in and on it, on the grounds that none of them manage alone.",
            source: "Biology",
            theme: .kinship,
            subtheme: .grownTogether
        ),
        Passage(
            text: "Sibling is Old English sibb, a word meaning peace and kinship at once. To be at peace with someone and to be related to them were the same thing.",
            source: "Old English",
            theme: .kinship,
            subtheme: .theWordsForIt
        ),
        Passage(
            text: "Gossip is God-sib, a godparent. The word for a spiritual relative became the word for what relatives do.",
            source: "Old English",
            theme: .kinship,
            subtheme: .theWordsForIt
        ),
        Passage(
            text: "Cousin is Latin consobrinus, the child of your mother's sister. English kept widening it until it meant very nearly any relative at all.",
            source: "Latin",
            theme: .kinship,
            subtheme: .theWordsForIt
        ),
        Passage(
            text: "A stand of aspen can be one organism sharing a single root system. The largest known covers more than forty hectares and is counted as one tree.",
            source: "Populus tremuloides",
            theme: .kinship,
            subtheme: .grownTogether
        ),
        Passage(
            text: "A lichen is a fungus farming an alga, and the partnership is so complete that it was described as a single species for a century before anyone noticed it was two.",
            source: "Lichenology",
            theme: .kinship,
            subtheme: .grownTogether
        ),
        Passage(
            text: "A graft joins two plants so completely that they share sap for life, while each keeps its own genes. One trunk can carry five varieties of apple.",
            source: "Grafting",
            theme: .kinship,
            subtheme: .grownTogether
        ),
        Passage(
            text: "Men exist for the sake of one another.",
            source: "Marcus Aurelius, tr. George Long",
            theme: .kinship,
            subtheme: .twoPeople
        ),
        Passage(
            text: "A friend is one soul dwelling in two bodies.",
            source: "Aristotle, as reported by Diogenes Laertius",
            theme: .kinship,
            subtheme: .twoPeople
        ),
        Passage(
            text: "Because it was he, because it was I.",
            source: "Montaigne on friendship, tr. Charles Cotton",
            theme: .kinship,
            subtheme: .twoPeople
        ),
        Passage(
            text: "Your friend is your needs answered. He is your field, which you sow with love and reap with thanksgiving.",
            source: "Kahlil Gibran, 1923",
            theme: .kinship,
            subtheme: .twoPeople
        ),
        Passage(
            text: "I thought myself rich when I found another: a person is a person's delight.",
            source: "Hávamál, Old Norse",
            theme: .kinship,
            subtheme: .twoPeople
        ),
        Passage(
            text: "Ubuntu: a person is made a person by other people, and our humanity shows itself in what passes between us.",
            source: "Nguni Bantu",
            theme: .kinship,
            subtheme: .twoPeople
        ),
        Passage(
            text: "And we'll tak a cup o' kindness yet, for auld lang syne.",
            source: "Robert Burns, 1788",
            theme: .kinship,
            subtheme: .twoPeople
        ),
        Passage(
            text: "Inosculation: two trees that grow against one another long enough to fuse, and afterwards share bark and sap.",
            source: "Botany",
            theme: .kinship,
            subtheme: .grownTogether
        ),
        Passage(
            text: "A companion is one you break bread with: Latin com, together, and panis, bread.",
            source: "Latin",
            theme: .kinship,
            subtheme: .theWordsForIt
        ),
        Passage(
            text: "Kind and kin are one word. To be kind was first to treat someone as though they were family.",
            source: "Old English",
            theme: .kinship,
            subtheme: .theWordsForIt
        ),
        Passage(
            text: "Friend is an old present participle of a verb meaning to love. A friend is, quite literally, one loving.",
            source: "Proto-Germanic",
            theme: .kinship,
            subtheme: .theWordsForIt
        ),
        Passage(
            text: "Rivals were once people who shared a stream: Latin rivalis, from rivus, a brook.",
            source: "Latin",
            theme: .kinship,
            subtheme: .theWordsForIt
        ),
        Passage(
            text: "Symbiosis is Greek for living together. It was coined in the 1870s for lichens, which are a fungus and an alga as one.",
            source: "Greek",
            theme: .kinship,
            subtheme: .theWordsForIt
        ),
        Passage(
            text: "Old English kept the mother's brother and the father's brother apart, eam and fædera, and did the same for aunts. French uncle and aunt came in and quietly did away with the distinction.",
            source: "Old English and Old French",
            theme: .kinship,
            subtheme: .theWordsForIt
        ),
        Passage(
            text: "Nephew and nepotism are one word: Latin nepos, a nephew or a grandson, and the popes who found positions for theirs.",
            source: "Latin",
            theme: .kinship,
            subtheme: .theWordsForIt
        ),
        Passage(
            text: "Brother has barely moved in five thousand years: bhrata in Sanskrit, phrater in Greek, frater in Latin, brothor in Old English, all of them the one word.",
            source: "Indo-European",
            theme: .kinship,
            subtheme: .theWordsForIt
        ),
        Passage(
            text: "Milk kinship: in several traditions a child fed at the same breast counts as family ever after, with the same closeness and the same bar on marrying.",
            source: "Milk kinship",
            theme: .kinship,
            subtheme: .theWordsForIt
        ),
        Passage(
            text: "Every green leaf runs on a bacterium that another cell took in more than a billion years ago. The two have been one ever since.",
            source: "Endosymbiosis",
            theme: .kinship,
            subtheme: .grownTogether
        ),
        Passage(
            text: "Most land plants trade sugar for phosphorus with fungi threaded through the soil. The arrangement is around four hundred million years old.",
            source: "Mycorrhizal symbiosis",
            theme: .kinship,
            subtheme: .grownTogether
        ),
        Passage(
            text: "In most flowering plants the chloroplasts descend through the seed parent alone, so a part of one parent travels on unmixed.",
            source: "Plastid inheritance",
            theme: .kinship,
            subtheme: .grownTogether
        ),
        Passage(
            text: "Trees of one kind often graft their roots together underground, which is how a cut stump with no leaves of its own can be kept alive for years by the ones standing around it.",
            source: "Root grafting",
            theme: .kinship,
            subtheme: .grownTogether
        ),

        // MARK: Peace
        //
        // Five strands, so that a theme's passages are not versions of one
        // thought: quiet held inwardly, the day letting go, shelter, peace made
        // between two parties, and the particular hush of green places.

        Passage(
            text: "Annihilating all that's made to a green thought in a green shade.",
            source: "Andrew Marvell (1621–1678)",
            theme: .peace,
            subtheme: .atEase
        ),
        Passage(
            text: "Time is but the stream I go a-fishing in.",
            source: "Henry David Thoreau, Walden, 1854",
            theme: .peace,
            subtheme: .atEase
        ),
        Passage(
            text: "And I shall have some peace there, for peace comes dropping slow.",
            source: "W. B. Yeats, 1890",
            theme: .peace,
            subtheme: .atEase
        ),
        Passage(
            text: "Psithurism: the sound of wind moving through leaves.",
            source: "English, from Greek",
            theme: .peace,
            subtheme: .quietAsASound
        ),
        Passage(
            text: "Peace is Latin pax, kin to pangere, to fasten. A peace was something two sides made fast between them.",
            source: "Latin",
            theme: .peace,
            subtheme: .theWordsForStopping
        ),
        Passage(
            text: "For nowhere either with more quiet or more freedom from trouble does a man retire than into his own soul.",
            source: "Marcus Aurelius, tr. George Long",
            theme: .peace,
            subtheme: .atEase
        ),
        Passage(
            text: "Tranquillity is nothing else than the good ordering of the mind.",
            source: "Marcus Aurelius, tr. George Long",
            theme: .peace,
            subtheme: .atEase
        ),
        Passage(
            text: "Climb the mountains and get their good tidings. Nature's peace will flow into you as sunshine flows into trees.",
            source: "John Muir, Our National Parks, 1901",
            theme: .peace,
            subtheme: .atEase
        ),
        Passage(
            text: "Study to be quiet.",
            source: "Izaak Walton's closing words, 1653",
            theme: .peace,
            subtheme: .quietAsASound
        ),
        Passage(
            text: "All shall be well, and all shall be well, and all manner of thing shall be well.",
            source: "Julian of Norwich, c. 1395",
            theme: .peace,
            subtheme: .atEase
        ),
        Passage(
            text: "He leadeth me beside the still waters.",
            source: "Psalm 23, King James Bible, 1611",
            theme: .peace,
            subtheme: .atEase
        ),
        Passage(
            text: "I loafe and invite my soul.",
            source: "Walt Whitman, 1855",
            theme: .peace,
            subtheme: .atEase
        ),
        Passage(
            text: "Calm of mind, all passion spent.",
            source: "John Milton, Samson Agonistes, 1671",
            theme: .peace,
            subtheme: .atEase
        ),
        Passage(
            text: "That inward eye which is the bliss of solitude.",
            source: "William Wordsworth, 1807",
            theme: .peace,
            subtheme: .atEase
        ),
        Passage(
            text: "Hygge: warmth and ease in company, put together on purpose out of small and ordinary things.",
            source: "Danish",
            theme: .peace,
            subtheme: .atEase
        ),
        Passage(
            text: "Niksen: doing nothing, and doing it deliberately rather than by accident.",
            source: "Dutch",
            theme: .peace,
            subtheme: .theWordsForStopping
        ),
        Passage(
            text: "Sobremesa: the time still spent at the table after the meal has ended, because nobody wants to be the one who gets up.",
            source: "Spanish",
            theme: .peace,
            subtheme: .atEase
        ),
        Passage(
            text: "Meriggiare: to pass the midday hours resting in the shade.",
            source: "Italian",
            theme: .peace,
            subtheme: .atEase
        ),
        Passage(
            text: "Lagom: just the right amount, neither too little nor too much, and no need to say which.",
            source: "Swedish",
            theme: .peace,
            subtheme: .theWordsForStopping
        ),
        Passage(
            text: "Shinrin-yoku: forest bathing, which asks nothing of you but to be among trees with your senses open.",
            source: "Japanese, coined 1982",
            theme: .peace,
            subtheme: .atEase
        ),
        Passage(
            text: "Crown shyness: the gap neighbouring trees leave between their canopies, so that a forest roof is a mosaic with daylight in the seams.",
            source: "Botany",
            theme: .peace,
            subtheme: .quietAsASound
        ),
        Passage(
            text: "Serene is Latin serenus, said first of weather: a clear sky with no wind in it.",
            source: "Latin",
            theme: .peace,
            subtheme: .theWordsForStopping
        ),
        Passage(
            text: "Calm reaches English from Greek kauma, the heat of the day: the hour when it is too hot to work and everything stops.",
            source: "Greek",
            theme: .peace,
            subtheme: .theWordsForStopping
        ),
        Passage(
            text: "Quiet and quit are one word: Latin quietus, at rest, which later became the receipt for a debt discharged.",
            source: "Latin",
            theme: .peace,
            subtheme: .theWordsForStopping
        ),
        Passage(
            text: "Rest is Old English ræst, whose Germanic kin also meant a stage of a journey: the distance between one stopping place and the next.",
            source: "Old English",
            theme: .peace,
            subtheme: .theWordsForStopping
        ),
        Passage(
            text: "A truce is a plural: Middle English trewes, pledges, kin to true. It was a promise before it was a pause.",
            source: "Middle English",
            theme: .peace,
            subtheme: .theWordsForStopping
        ),
        Passage(
            text: "Sabbath comes from Hebrew shabbath, to cease. The word names the stopping rather than the day.",
            source: "Hebrew",
            theme: .peace,
            subtheme: .theWordsForStopping
        ),
        Passage(
            text: "Fresh snow is full of air and absorbs the high notes out of any sound, which is why a snowed-in landscape is not merely quiet but muffled.",
            source: "Acoustics of snow",
            theme: .peace,
            subtheme: .quietAsASound
        ),
        Passage(
            text: "In an anechoic chamber there is nothing left to hear but yourself, and people who sit in one report the sound of their own blood.",
            source: "Anechoic chambers",
            theme: .peace,
            subtheme: .quietAsASound
        ),
        Passage(
            text: "An owl flies without a sound because the front edge of its wing is combed into a fringe that breaks the air up before it can whistle, and the rest of the feather is soft enough to swallow what is left.",
            source: "Strigiformes",
            theme: .peace,
            subtheme: .quietAsASound
        ),
        Passage(
            text: "Danish keeps two words where English has one: stilhed is no sound at all, and tavshed is nobody speaking. English says silence and leaves you to work out which.",
            source: "Danish",
            theme: .peace,
            subtheme: .quietAsASound
        ),
        Passage(
            text: "The quietest sound a person can hear moves the eardrum by less than the width of an atom.",
            source: "Threshold of hearing",
            theme: .peace,
            subtheme: .quietAsASound
        ),
        Passage(
            text: "A small red stone was laid on a log in the Hoh rain forest to mark one square inch of ground, chosen because a person can sit there a long while and hear nothing that people made.",
            source: "One Square Inch, Olympic National Park",
            theme: .peace,
            subtheme: .quietAsASound
        ),
        Passage(
            text: "England has been mapped for its quiet as well as for its roads. The survey scored every square kilometre by what could be seen and heard from it, and printed tranquillity as a colour.",
            source: "CPRE tranquillity mapping, 2006",
            theme: .peace,
            subtheme: .quietAsASound
        ),
        Passage(
            text: "Susurrus: taken whole from Latin, where it was the word for a whispering, a rustle, the murmur of a crowd and the hum of bees.",
            source: "Latin",
            theme: .peace,
            subtheme: .quietAsASound
        ),
        Passage(
            text: "Whist was an interjection meaning hush before it was a card game, and the game is said to be named for the silence it was played in.",
            source: "English",
            theme: .peace,
            subtheme: .quietAsASound
        ),
        Passage(
            text: "Horas non numero nisi serenas, cut on old sundials: I count only the serene hours. Serenus meant cloudless, so a dial that needs sun to count at all is only describing itself.",
            source: "Sundial motto, Latin",
            theme: .peace,
            subtheme: .theWordsForStopping
        ),
        Passage(
            text: "Armistice is Latin arma and sistere, the arms standing still. It is the same sistere as in solstice, where it is the sun that stands still.",
            source: "Latin",
            theme: .peace,
            subtheme: .theWordsForStopping
        ),
        Passage(
            text: "Respite is Latin respectus, a looking back, and the same word as respect. A respite is time given by somebody who has looked at you again.",
            source: "Latin",
            theme: .peace,
            subtheme: .theWordsForStopping
        ),
    ]

    /// The passages of one subtheme, grouped once rather than filtered per
    /// draw. Keyed by the subtheme alone, since a subtheme names its theme.
    ///
    /// Grouped for the bank this phone reads rather than for the English one.
    /// Only that bank's array is ever built: the other seven are `static let`s
    /// nothing touches, so a Danish phone pays for the Danish bank and nothing
    /// else. See `QuoteBank` for what two phones on different banks still agree
    /// on, which is the theme and the subtheme and deliberately not the line.
    private static let bySubtheme: [Subtheme: [Passage]] =
        Dictionary(grouping: QuoteBank.current.passages, by: \.subtheme)

    // MARK: - The draw

    /// The theme a seed carries on its own, read off its plant's name.
    ///
    /// This used to be its own draw, `passage.theme.v1`, independent of
    /// everything else the seed decided. It is now the sense of the syllable
    /// the genus already begins with, which is the whole point: a plant called
    /// *Nyxia* is a waiting plant and says so, and nobody has to be told.
    ///
    /// **The change is safe in the way that matters and visible in one way
    /// that does not.** No name, body, birthday or garden moves — a theme is
    /// never stored, only derived, and this reads a draw that every seed ever
    /// minted already made. What does move is which passage a given pair is
    /// shown: two people who met before this landed will find their shared
    /// theme has shifted once. A passage is a thing said at a meeting rather
    /// than a property of the plant it made, and the note that plant carries
    /// never held it.
    static func theme(of seed: SeedID) -> Theme {
        Theme(genusHead: Genome(seed: seed, lineage: .minted).name.genusHead)
    }

    /// Which third of a theme a plant draws from, read off the genus ending.
    ///
    /// Ten tails over three subthemes, so the split is 3/3/4 rather than even.
    /// That suits the bank: the third heap under most themes is the words and
    /// the sayings, and it is reliably the largest of the three.
    /// The three subthemes are not drawn equally, and a bank should know it.
    ///
    /// There are ten genus tails and they band 3/3/4, so a theme's **third**
    /// subtheme comes up about 40% of the time and the first two about 30%
    /// each. How often a reader meets a line twice is therefore the draw
    /// probability over the number of lines, not the number of lines alone —
    /// so a third subtheme wants about a third more passages than a first to
    /// feel equally fresh.
    ///
    /// This bit once. Peace's `quietAsASound` sat at five passages against
    /// `atEase`'s fifteen, and being the *first* subtheme it was drawn 30% of
    /// the time — so its lines came round more than twice as often as any other
    /// corner of the bank. Filling English to twelve everywhere closed it: the
    /// worst ratio across the eight banks is now about 1.3.
    static func subtheme(of genome: Genome, in theme: Theme) -> Subtheme {
        let tails = PlantName.genusTails
        let band: Int
        switch tails.firstIndex(of: genome.name.genusTail) ?? 0 {
        case 0...2: band = 0
        case 3...5: band = 1
        default: band = 2
        }
        let subthemes = theme.subthemes
        return subthemes[min(band, subthemes.count - 1)]
    }

    /// The theme two people share, settled the first time they meet.
    ///
    /// The odds match `GeneSource`'s inheritance, so a theme descends the way a
    /// genus and an epithet already do: mostly one parent or the other, and
    /// otherwise something that lies between them. `GeneSource` keeps a further
    /// 6% for a wholly novel value; here that case is folded into the blend,
    /// because a theme drawn from between two people is already a theme neither
    /// of them brought.
    static func sharedTheme(parentA: SeedID, parentB: SeedID) -> Theme {
        let mine = theme(of: parentA)
        let theirs = theme(of: parentB)
        let roll = Pollination.pairUnit(seedA: parentA, seedB: parentB, label: "passage.theme.inherit.v1")
        if roll < GeneSource.inheritFirstParent { return mine }
        if roll < GeneSource.inheritSecondParent { return theirs }

        let axisRoll = Pollination.pairUnit(seedA: parentA, seedB: parentB, label: "passage.theme.axis.v1")
        let axis = Dimension.allCases[
            min(Dimension.allCases.count - 1, Int(axisRoll * Double(Dimension.allCases.count)))
        ]
        return between(mine, theirs, on: axis)
    }

    /// The theme nearest to two others along one dimension.
    ///
    /// Both parents are excluded: taking a parent's theme is what the two
    /// branches above already do, so leaving them in the running would only make
    /// the blend a fourth way of saying the same thing.
    static func between(_ one: Theme, _ other: Theme, on axis: Dimension) -> Theme {
        let index = axis.rawValue
        let midpoint = (one.position[index] + other.position[index]) / 2
        let centre = (0..<Dimension.allCases.count).map {
            (one.position[$0] + other.position[$0]) / 2
        }

        /// How far a theme is from the midpoint on the governing axis, then over
        /// all four. The second only decides ties on the first.
        func distance(_ theme: Theme) -> (Double, Double) {
            let overall = zip(theme.position, centre)
                .reduce(0.0) { $0 + ($1.0 - $1.1) * ($1.0 - $1.1) }
            return (abs(theme.position[index] - midpoint), overall)
        }

        let candidates = Theme.allCases.filter { $0 != one && $0 != other }
        return candidates.min { distance($0) < distance($1) } ?? one
    }

    /// The passage for one crossing.
    ///
    /// Three settlements from three different places: the theme from the pair,
    /// which holds; the subtheme from the child's own name; and the line from
    /// the child seed, which carries a fresh nonce and so does not hold.
    static func passage(for result: CrossPollinationResult) -> Passage {
        let theme = sharedTheme(parentA: result.parentA, parentB: result.parentB)
        let child = Genome(seed: result.childSeed, lineage: result.lineage)
        return passage(
            subtheme: subtheme(of: child, in: theme),
            childSeed: result.childSeed
        )
    }

    /// The passage a subtheme gives to one particular meeting.
    ///
    /// A pure function of the subtheme and those 32 bytes and of nothing else,
    /// by way of `deterministicFold`, which is where the reasons live.
    static func passage(subtheme: Subtheme, childSeed: SeedID) -> Passage {
        passage(subtheme: subtheme, childSeed: childSeed, from: bySubtheme)
    }

    /// The same draw against a bank given explicitly, which is how the tests
    /// reach the seven banks a given phone is not reading.
    static func passage(
        subtheme: Subtheme,
        childSeed: SeedID,
        from index: [Subtheme: [Passage]]
    ) -> Passage {
        guard let pool = index[subtheme], !pool.isEmpty else {
            preconditionFailure("every subtheme must carry at least one passage: \(subtheme)")
        }
        return pool[Int(deterministicFold(childSeed.bytes) % UInt64(pool.count))]
    }
}
