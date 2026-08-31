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
}

/// The bank of passages, and the draw that picks from it.
///
/// A passage is shown at the moment two people cross their plants. Which one
/// they get is settled in two stages, and the split is the whole design:
///
/// - **The theme belongs to the pair.** Each person's seed carries a theme of
///   its own, drawn as a trait like any other. When two people meet, the pair
///   inherits one — usually one of theirs, sometimes a third that lies between
///   them. It is rolled from `pairID`, so it is settled the first time they meet
///   and never moves again.
/// - **The line belongs to the meeting.** Within that theme, the passage is
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

        // MARK: Beginnings — 10 today

        Passage(
            text: "The tree which fills the arms grew from the tiniest sprout.",
            source: "Laozi, tr. James Legge",
            theme: .beginnings
        ),
        Passage(
            text: "To see a World in a Grain of Sand, and a Heaven in a Wild Flower.",
            source: "William Blake (1757–1827)",
            theme: .beginnings
        ),
        Passage(
            text: "Convince me that you have a seed there, and I am prepared to expect wonders.",
            source: "Henry David Thoreau, 1860",
            theme: .beginnings
        ),
        Passage(
            text: "The creation of a thousand forests is in one acorn.",
            source: "Ralph Waldo Emerson, History, 1841",
            theme: .beginnings
        ),
        Passage(
            text: "To make a prairie it takes a clover and one bee — one clover, and a bee, and revery.",
            source: "Emily Dickinson (1830–1886)",
            theme: .beginnings
        ),
        Passage(
            text: "Great oaks from little acorns grow.",
            source: "English proverb",
            theme: .beginnings
        ),
        Passage(
            text: "Every Bramley apple is a cutting from one tree, grown from a pip that Mary Ann Brailsford planted in a pot in 1809.",
            source: "Southwell, Nottinghamshire",
            theme: .beginnings
        ),
        Passage(
            text: "Sow a pip from any apple and what comes up is a wholly new variety, which is why named apples travel as grafts.",
            source: "Malus domestica",
            theme: .beginnings
        ),
        Passage(
            text: "Orchid seed is as fine as dust and carries almost nothing to live on. Each grain waits for a fungus to feed it into life.",
            source: "Orchidaceae",
            theme: .beginnings
        ),
        Passage(
            text: "A flowering plant is fertilised twice at once: one sperm makes the embryo, the other makes the store of food packed around it.",
            source: "Double fertilisation",
            theme: .beginnings
        ),

        // MARK: Waiting — 11 today

        Passage(
            text: "Let it first blossom, then bear fruit, then ripen.",
            source: "Epictetus, tr. George Long",
            theme: .waiting
        ),
        Passage(
            text: "A garden is a grand teacher. It teaches patience and careful watchfulness.",
            source: "Gertrude Jekyll, 1899",
            theme: .waiting
        ),
        Passage(
            text: "The best fertiliser is the gardener's shadow.",
            source: "Gardener's proverb",
            theme: .waiting
        ),
        Passage(
            text: "One generation plants the trees; another gets the shade.",
            source: "Chinese proverb",
            theme: .waiting
        ),
        Passage(
            text: "Vernalisation: the long cold a seed or a bud passes through, after which spring is able to move it.",
            source: "Botany",
            theme: .waiting
        ),
        Passage(
            text: "A season is a sowing. The word descends from Latin satio, the time at which seed goes into the ground.",
            source: "Latin",
            theme: .waiting
        ),
        Passage(
            text: "A date seed from Masada, dated to roughly two thousand years old, was sown in 2005 and grew. The tree is called Methuselah.",
            source: "Phoenix dactylifera, Israel",
            theme: .waiting
        ),
        Passage(
            text: "Ground squirrels buried fruits in Siberia some thirty-two thousand years ago. In 2012 the tissue inside them was grown on into whole flowering plants.",
            source: "Silene stenophylla, PNAS 2012",
            theme: .waiting
        ),
        Passage(
            text: "A sacred lotus seed lifted from an old lake bed in Liaoning germinated after about thirteen hundred years, and the plant is growing still.",
            source: "Nelumbo nucifera",
            theme: .waiting
        ),
        Passage(
            text: "Seeds were sealed into bottles and buried in 1879. A bottle opened in 2021 still held mullein seeds that woke and grew.",
            source: "Beal's seed experiment, Michigan",
            theme: .waiting
        ),
        Passage(
            text: "Some bamboos flower once, all together, all over the world, after more than a century. Plants from one stock keep the same clock.",
            source: "Phyllostachys bambusoides",
            theme: .waiting
        ),

        // MARK: Renewal — 7 today

        Passage(
            text: "The flowers appear on the earth; the time of the singing of birds is come.",
            source: "Song of Solomon, King James Bible, 1611",
            theme: .renewal
        ),
        Passage(
            text: "Who would have thought my shrivelled heart could have recovered greenness?",
            source: "George Herbert (1593–1633)",
            theme: .renewal
        ),
        Passage(
            text: "Earth laughs in flowers.",
            source: "Ralph Waldo Emerson, Hamatreya",
            theme: .renewal
        ),
        Passage(
            text: "To plant seeds, and watch their renewal of life — this is the commonest delight of the race.",
            source: "Charles Dudley Warner, 1870",
            theme: .renewal
        ),
        Passage(
            text: "Thrive comes from Old Norse thrifask, to grasp for oneself. Thriving was once a matter of taking hold.",
            source: "Old Norse",
            theme: .renewal
        ),
        Passage(
            text: "Green, grow and grass come from one Germanic root. The colour is named for what growing things do.",
            source: "Old English",
            theme: .renewal
        ),
        Passage(
            text: "Six ginkgos standing within two kilometres of the Hiroshima blast came through it, put out leaves again, and are alive today.",
            source: "Hibakujumoku, Hiroshima",
            theme: .renewal
        ),

        // MARK: Light — 9 today

        Passage(
            text: "I saw Eternity the other night, like a great ring of pure and endless light.",
            source: "Henry Vaughan (1621–1695)",
            theme: .light
        ),
        Passage(
            text: "Now I see the secret of the making of the best persons: it is to grow in the open air.",
            source: "Walt Whitman, 1856",
            theme: .light
        ),
        Passage(
            text: "Apricity: the warmth of the sun as it is felt on a winter's day.",
            source: "English, first recorded 1623",
            theme: .light
        ),
        Passage(
            text: "Heliotropism: the turning of a plant through the day so that it keeps its face to the sun.",
            source: "Botany",
            theme: .light
        ),
        Passage(
            text: "Nyctinasty: the folding of leaves and petals at dusk, and their opening again with the light.",
            source: "Botany",
            theme: .light
        ),
        Passage(
            text: "Anthesis: the span of a flower's life during which it stands open.",
            source: "Botany",
            theme: .light
        ),
        Passage(
            text: "Gökotta: rising at first light to go outside and listen to the earliest birds.",
            source: "Swedish",
            theme: .light
        ),
        Passage(
            text: "Daisy is the day's eye, named for a flower that opens with the light and closes again at dusk.",
            source: "Old English",
            theme: .light
        ),
        Passage(
            text: "Young sunflowers follow the sun west and swing back east overnight. Grown ones settle facing east, where morning warmth brings the bees earlier.",
            source: "Science, 2016",
            theme: .light
        ),

        // MARK: Pattern — 7 today

        Passage(
            text: "It is interesting to contemplate an entangled bank, clothed with many plants of many kinds.",
            source: "Charles Darwin, 1859",
            theme: .pattern
        ),
        Passage(
            text: "Rose is a rose is a rose is a rose.",
            source: "Gertrude Stein, 1913",
            theme: .pattern
        ),
        Passage(
            text: "An anthology is a gathering of flowers: Greek anthos, flower, and legein, to gather up.",
            source: "Greek",
            theme: .pattern
        ),
        Passage(
            text: "New leaves are set about 137.5 degrees around from the last, the one angle at which every leaf keeps a share of the light.",
            source: "Phyllotaxis, the golden angle",
            theme: .pattern
        ),
        Passage(
            text: "Count the spirals in a sunflower head each way and you will nearly always land on two neighbouring Fibonacci numbers, such as 34 and 55.",
            source: "Helianthus annuus",
            theme: .pattern
        ),
        Passage(
            text: "Pollen wears a sculpted coat of sporopollenin, tough enough that grains keep their pattern in peat for thousands of years and can still be named.",
            source: "Palynology",
            theme: .pattern
        ),
        Passage(
            text: "A returning honeybee dances the angle of the flowers against the sun, and the length of her waggle tells the others how far to fly.",
            source: "Karl von Frisch",
            theme: .pattern
        ),

        // MARK: Ground — 13 today

        Passage(
            text: "If you have a garden in your library, nothing will be wanting.",
            source: "Cicero, letter to Varro, 46 BC",
            theme: .ground
        ),
        Passage(
            text: "God Almighty first planted a garden; and indeed it is the purest of human pleasures.",
            source: "Francis Bacon, 1625",
            theme: .ground
        ),
        Passage(
            text: "I found the poems in the fields, and only wrote them down.",
            source: "John Clare (1793–1864)",
            theme: .ground
        ),
        Passage(
            text: "Long live the weeds and the wilderness yet.",
            source: "Gerard Manley Hopkins (1844–1889)",
            theme: .ground
        ),
        Passage(
            text: "Petrichor: the smell that lifts off dry ground when rain first reaches it.",
            source: "English, coined 1964",
            theme: .ground
        ),
        Passage(
            text: "Querencia: the place a creature keeps returning to, where it is most itself and draws its strength.",
            source: "Spanish",
            theme: .ground
        ),
        Passage(
            text: "Smultronställe: a wild-strawberry place — a small, treasured spot you go back to on your own.",
            source: "Swedish",
            theme: .ground
        ),
        Passage(
            text: "Paradise began as a walled garden — Old Persian pairidaeza, an enclosure planted for pleasure.",
            source: "Old Persian",
            theme: .ground
        ),
        Passage(
            text: "Garden, yard and girdle share one root meaning an enclosure. A garden is first of all a kept place.",
            source: "Proto-Germanic",
            theme: .ground
        ),
        Passage(
            text: "A neighbour is a near-dweller: Old English neah, near, and gebur, one who lives here.",
            source: "Old English",
            theme: .ground
        ),
        Passage(
            text: "Human, humble and humus grow from a single Latin root: the ground itself.",
            source: "Latin",
            theme: .ground
        ),
        Passage(
            text: "Culture and cultivate come from Latin colere: to till the ground, to tend it, and to hold it in honour.",
            source: "Latin",
            theme: .ground
        ),
        Passage(
            text: "One seagrass in the Mediterranean has spread sideways for perhaps a hundred thousand years, and the whole meadow counts as a single plant.",
            source: "Posidonia oceanica",
            theme: .ground
        ),

        // MARK: Travel — 9 today

        Passage(
            text: "Good company in a journey makes the way to seem the shorter.",
            source: "Izaak Walton, after an Italian saying, 1653",
            theme: .travel
        ),
        Passage(
            text: "To travel hopefully is a better thing than to arrive.",
            source: "Robert Louis Stevenson, 1881",
            theme: .travel
        ),
        Passage(
            text: "May the road rise up to meet you.",
            source: "Traditional Irish blessing",
            theme: .travel
        ),
        Passage(
            text: "Anemochory: travel by wind, where a seed makes its entire journey on moving air.",
            source: "Botany",
            theme: .travel
        ),
        Passage(
            text: "Volunteer: a plant that arrives of its own accord and grows in ground that somebody else left bare.",
            source: "Gardener's term",
            theme: .travel
        ),
        Passage(
            text: "Horace Walpole coined serendipity in 1754 from Serendip, an old name for Sri Lanka, after a tale of three lucky princes.",
            source: "English, 1754",
            theme: .travel
        ),
        Passage(
            text: "A dandelion's parachute holds a ring of circling air just above itself, and that steady vortex is what carries a seed a mile from home.",
            source: "Nature, 2018",
            theme: .travel
        ),
        Passage(
            text: "Burdock burs caught on a Swiss engineer's dog in 1941. He put the hooks under a microscope, and the result was Velcro.",
            source: "Arctium, and George de Mestral",
            theme: .travel
        ),
        Passage(
            text: "A coconut can float for months across open ocean and root where it comes ashore. Whole island floras arrived that way.",
            source: "Cocos nucifera",
            theme: .travel
        ),

        // MARK: Meeting — 10 today

        Passage(
            text: "The world puts off its mask of vastness to its lover. It becomes small as one song, as one kiss of the eternal.",
            source: "Rabindranath Tagore, Stray Birds, 1916",
            theme: .meeting
        ),
        Passage(
            text: "Ichigo ichie: one meeting, one chance. This gathering is the only one of its kind, so meet it whole.",
            source: "Japanese, from the way of tea",
            theme: .meeting
        ),
        Passage(
            text: "Thigmotropism: growth steered by touch, as a tendril winds around whatever it happens to meet.",
            source: "Botany",
            theme: .meeting
        ),
        Passage(
            text: "Kairos: the opening in time when a thing can be done — the right moment, as distinct from the hour on the clock.",
            source: "Ancient Greek",
            theme: .meeting
        ),
        Passage(
            text: "Clinamen: the faint swerve by which falling atoms come to meet one another, and so make a world.",
            source: "Lucretius, first century BC",
            theme: .meeting
        ),
        Passage(
            text: "To meet is to come to the moot: Old English metan, from gemot, the gathering where matters were settled.",
            source: "Old English",
            theme: .meeting
        ),
        Passage(
            text: "Encounter reaches English from Latin in contra — to come face to face with whatever stands opposite.",
            source: "Old French",
            theme: .meeting
        ),
        Passage(
            text: "Chance descends from Latin cadere, to fall. A chance is simply the way things happened to fall out.",
            source: "Latin",
            theme: .meeting
        ),
        Passage(
            text: "Many flowers read the pollen that lands on them and open a path for a stranger's grain, so that the next generation comes from two.",
            source: "Self-incompatibility in plants",
            theme: .meeting
        ),
        Passage(
            text: "Flowers carry a faint electric charge. A bumblebee can feel it, and read from it which blooms another bee has lately emptied.",
            source: "Science, 2013",
            theme: .meeting
        ),

        // MARK: Kinship — 15 today

        Passage(
            text: "Men exist for the sake of one another.",
            source: "Marcus Aurelius, tr. George Long",
            theme: .kinship
        ),
        Passage(
            text: "A friend is one soul dwelling in two bodies.",
            source: "Aristotle, as reported by Diogenes Laertius",
            theme: .kinship
        ),
        Passage(
            text: "Because it was he, because it was I.",
            source: "Montaigne on friendship, tr. Charles Cotton",
            theme: .kinship
        ),
        Passage(
            text: "Your friend is your needs answered. He is your field, which you sow with love and reap with thanksgiving.",
            source: "Kahlil Gibran, 1923",
            theme: .kinship
        ),
        Passage(
            text: "I thought myself rich when I found another: a person is a person's delight.",
            source: "Hávamál, Old Norse",
            theme: .kinship
        ),
        Passage(
            text: "Ubuntu: a person is made a person by other people, and our humanity shows itself in what passes between us.",
            source: "Nguni Bantu",
            theme: .kinship
        ),
        Passage(
            text: "Inosculation: two trees that grow against one another long enough to fuse, and afterwards share bark and sap.",
            source: "Botany",
            theme: .kinship
        ),
        Passage(
            text: "A companion is one you break bread with: Latin com, together, and panis, bread.",
            source: "Latin",
            theme: .kinship
        ),
        Passage(
            text: "Kind and kin are one word. To be kind was first to treat someone as though they were family.",
            source: "Old English",
            theme: .kinship
        ),
        Passage(
            text: "Friend is an old present participle of a verb meaning to love. A friend is, quite literally, one loving.",
            source: "Proto-Germanic",
            theme: .kinship
        ),
        Passage(
            text: "Rivals were once people who shared a stream: Latin rivalis, from rivus, a brook.",
            source: "Latin",
            theme: .kinship
        ),
        Passage(
            text: "Symbiosis is Greek for living together. It was coined in the 1870s for lichens, which are a fungus and an alga as one.",
            source: "Greek",
            theme: .kinship
        ),
        Passage(
            text: "Every green leaf runs on a bacterium that another cell took in more than a billion years ago. The two have been one ever since.",
            source: "Endosymbiosis",
            theme: .kinship
        ),
        Passage(
            text: "Most land plants trade sugar for phosphorus with fungi threaded through the soil. The arrangement is around four hundred million years old.",
            source: "Mycorrhizal symbiosis",
            theme: .kinship
        ),
        Passage(
            text: "In most flowering plants the chloroplasts descend through the seed parent alone, so a part of one parent travels on unmixed.",
            source: "Plastid inheritance",
            theme: .kinship
        ),

        // MARK: Peace
        //
        // Five strands, so that thirty passages are not thirty versions of one
        // thought: quiet held inwardly, the day letting go, shelter, peace made
        // between two parties, and the particular hush of green places.

        Passage(
            text: "Annihilating all that's made to a green thought in a green shade.",
            source: "Andrew Marvell (1621–1678)",
            theme: .peace
        ),
        Passage(
            text: "Time is but the stream I go a-fishing in.",
            source: "Henry David Thoreau, Walden, 1854",
            theme: .peace
        ),
        Passage(
            text: "And I shall have some peace there, for peace comes dropping slow.",
            source: "W. B. Yeats, 1890",
            theme: .peace
        ),
        Passage(
            text: "Psithurism: the sound of wind moving through leaves.",
            source: "English, from Greek",
            theme: .peace
        ),
        Passage(
            text: "Peace is Latin pax, kin to pangere, to fasten. A peace was something two sides made fast between them.",
            source: "Latin",
            theme: .peace
        ),
        Passage(
            text: "For nowhere either with more quiet or more freedom from trouble does a man retire than into his own soul.",
            source: "Marcus Aurelius, tr. George Long",
            theme: .peace
        ),
        Passage(
            text: "Tranquillity is nothing else than the good ordering of the mind.",
            source: "Marcus Aurelius, tr. George Long",
            theme: .peace
        ),
        Passage(
            text: "Climb the mountains and get their good tidings. Nature's peace will flow into you as sunshine flows into trees.",
            source: "John Muir, Our National Parks, 1901",
            theme: .peace
        ),
        Passage(
            text: "Study to be quiet.",
            source: "Izaak Walton's closing words, 1653",
            theme: .peace
        ),
        Passage(
            text: "All shall be well, and all shall be well, and all manner of thing shall be well.",
            source: "Julian of Norwich, c. 1395",
            theme: .peace
        ),
        Passage(
            text: "He leadeth me beside the still waters.",
            source: "Psalm 23, King James Bible, 1611",
            theme: .peace
        ),
        Passage(
            text: "I loafe and invite my soul.",
            source: "Walt Whitman, 1855",
            theme: .peace
        ),
        Passage(
            text: "Calm of mind, all passion spent.",
            source: "John Milton, Samson Agonistes, 1671",
            theme: .peace
        ),
        Passage(
            text: "That inward eye which is the bliss of solitude.",
            source: "William Wordsworth, 1807",
            theme: .peace
        ),
        Passage(
            text: "Hygge: warmth and ease in company, put together on purpose out of small and ordinary things.",
            source: "Danish",
            theme: .peace
        ),
        Passage(
            text: "Niksen: doing nothing, and doing it deliberately rather than by accident.",
            source: "Dutch",
            theme: .peace
        ),
        Passage(
            text: "Sobremesa: the time still spent at the table after the meal has ended, because nobody wants to be the one who gets up.",
            source: "Spanish",
            theme: .peace
        ),
        Passage(
            text: "Meriggiare: to pass the midday hours resting in the shade.",
            source: "Italian",
            theme: .peace
        ),
        Passage(
            text: "Lagom: just the right amount — not too little and not too much, and no need to say which.",
            source: "Swedish",
            theme: .peace
        ),
        Passage(
            text: "Shinrin-yoku: forest bathing, which asks nothing of you but to be among trees with your senses open.",
            source: "Japanese, coined 1982",
            theme: .peace
        ),
        Passage(
            text: "Crown shyness: the gap neighbouring trees leave between their canopies, so that a forest roof is a mosaic with daylight in the seams.",
            source: "Botany",
            theme: .peace
        ),
        Passage(
            text: "Serene is Latin serenus, said first of weather: a clear sky with no wind in it.",
            source: "Latin",
            theme: .peace
        ),
        Passage(
            text: "Calm reaches English from Greek kauma, the heat of the day — the hour when it is too hot to work and everything stops.",
            source: "Greek",
            theme: .peace
        ),
        Passage(
            text: "Quiet and quit are one word: Latin quietus, at rest, which later became the receipt for a debt discharged.",
            source: "Latin",
            theme: .peace
        ),
        Passage(
            text: "Rest is Old English ræst, whose Germanic kin also meant a stage of a journey — the distance between one stopping place and the next.",
            source: "Old English",
            theme: .peace
        ),
        Passage(
            text: "A truce is a plural: Middle English trewes, pledges, kin to true. It was a promise before it was a pause.",
            source: "Middle English",
            theme: .peace
        ),
        Passage(
            text: "Sabbath comes from Hebrew shabbath, to cease. The word names the stopping rather than the day.",
            source: "Hebrew",
            theme: .peace
        ),
        Passage(
            text: "Fresh snow is full of air and absorbs the high notes out of any sound, which is why a snowed-in landscape is not merely quiet but muffled.",
            source: "Acoustics of snow",
            theme: .peace
        ),
        Passage(
            text: "In an anechoic chamber there is nothing left to hear but yourself, and people who sit in one report the sound of their own blood.",
            source: "Anechoic chambers",
            theme: .peace
        ),
        Passage(
            text: "Horas non numero nisi serenas — I count only the serene hours. A sundial can say it honestly, having no choice.",
            source: "Sundial motto, Latin",
            theme: .peace
        ),
    ]

    /// The passages of one theme, grouped once rather than filtered per draw.
    private static let byTheme: [Theme: [Passage]] = Dictionary(grouping: all, by: \.theme)

    // MARK: - The draw

    /// The theme a seed carries on its own.
    ///
    /// A trait like any other, drawn by name, so it was already true of every
    /// seed ever minted — including the ones growing on phones before this
    /// existed. Nobody's plant changes because the themes arrived.
    static func theme(of seed: SeedID) -> Theme {
        GeneSource.primary(seed).pick("passage.theme.v1", from: Theme.allCases)
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
    /// The theme comes from the pair and holds; the line comes from the child
    /// seed and does not.
    static func passage(for result: CrossPollinationResult) -> Passage {
        passage(
            theme: sharedTheme(parentA: result.parentA, parentB: result.parentB),
            childSeed: result.childSeed
        )
    }

    /// The passage a theme gives to one particular meeting.
    ///
    /// A pure function of the theme and those 32 bytes and of nothing else, by
    /// way of `deterministicFold`, which is where the reasons live.
    static func passage(theme: Theme, childSeed: SeedID) -> Passage {
        guard let pool = byTheme[theme], !pool.isEmpty else {
            preconditionFailure("every theme must carry at least one passage: \(theme)")
        }
        return pool[Int(deterministicFold(childSeed.bytes) % UInt64(pool.count))]
    }
}
