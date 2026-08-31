import Foundation

/// A short passage and where it came from.
///
/// The provenance is deliberately terse — a name, a language, a species. It is
/// there so the passage can be trusted and looked up, not so it can be cited.
struct Passage: Equatable, Sendable {
    let text: String     // the passage itself
    let source: String   // brief provenance, shown beneath it
}

/// The bank of passages, and the one function that picks from it.
///
/// A passage is shown at the moment two people cross their plants, and it is
/// chosen from `pairID` — the two parent seeds, with no nonce. So it is the
/// same passage every time those two meet, and a fresh draw for every new
/// person. Both phones compute it, neither sends it, and it will be the same
/// passage if either of them looks again in ten years.
///
/// Drawing from the *child* seed would have given the opposite behaviour, and
/// did until this was changed: a child carries a per-encounter nonce so that
/// meeting the same person twice grows two different plants. That is right for
/// the plant and wrong for the passage. The line belongs to the two people; the
/// plants they grow are new each time.
///
/// Two different pairs can still draw the same passage, and no bank size fixes
/// that — with a stateless shared draw, collisions are the price of both phones
/// agreeing without sending anything. Treated as a coincidence rather than a
/// fault, which is the register the bank is written in anyway.
///
/// The intent is divinatory rather than instructive. A passage is offered as
/// something that might happen to fit this meeting, which is why the bank mixes
/// quotation, definition, etymology and fact — the pleasure is partly in not
/// knowing which kind is about to appear.
///
/// Everything here is safe to ship in a binary. Quotations come from authors
/// long dead and from traditional sayings; translations are either
/// public-domain ones, credited to the translator, or rendered plainly here.
/// Facts are not copyrightable, but the wording of a reference book is, so
/// every definition, etymology and fact below is written from scratch rather
/// than lifted. Nothing goes in that could not be established.
enum Quotes {
    static let all: [Passage] = [

        // MARK: - Quotations
        //
        // Every named author died long enough ago to be out of copyright
        // everywhere the app will ship, and each line has been checked against
        // the work it comes from rather than against a quotation site. Where a
        // saying could not be pinned to a person it is credited as traditional,
        // which is the honest attribution rather than a weaker one.

        Passage(
            text: "Men exist for the sake of one another.",
            source: "Marcus Aurelius, tr. George Long"
        ),
        Passage(
            text: "Let it first blossom, then bear fruit, then ripen.",
            source: "Epictetus, tr. George Long"
        ),
        Passage(
            text: "The tree which fills the arms grew from the tiniest sprout.",
            source: "Laozi, tr. James Legge"
        ),
        Passage(
            text: "A friend is one soul dwelling in two bodies.",
            source: "Aristotle, as reported by Diogenes Laertius"
        ),
        Passage(
            text: "Because it was he, because it was I.",
            source: "Montaigne on friendship, tr. Charles Cotton"
        ),
        Passage(
            text: "If you have a garden in your library, nothing will be wanting.",
            source: "Cicero, letter to Varro, 46 BC"
        ),
        Passage(
            text: "The flowers appear on the earth; the time of the singing of birds is come.",
            source: "Song of Solomon, King James Bible, 1611"
        ),
        Passage(
            text: "God Almighty first planted a garden; and indeed it is the purest of human pleasures.",
            source: "Francis Bacon, 1625"
        ),
        Passage(
            text: "Good company in a journey makes the way to seem the shorter.",
            source: "Izaak Walton, after an Italian saying, 1653"
        ),
        Passage(
            text: "Annihilating all that's made to a green thought in a green shade.",
            source: "Andrew Marvell (1621–1678)"
        ),
        Passage(
            text: "Who would have thought my shrivelled heart could have recovered greenness?",
            source: "George Herbert (1593–1633)"
        ),
        Passage(
            text: "I saw Eternity the other night, like a great ring of pure and endless light.",
            source: "Henry Vaughan (1621–1695)"
        ),
        Passage(
            text: "To see a World in a Grain of Sand, and a Heaven in a Wild Flower.",
            source: "William Blake (1757–1827)"
        ),
        Passage(
            text: "I found the poems in the fields, and only wrote them down.",
            source: "John Clare (1793–1864)"
        ),
        Passage(
            text: "Time is but the stream I go a-fishing in.",
            source: "Henry David Thoreau, Walden, 1854"
        ),
        Passage(
            text: "Convince me that you have a seed there, and I am prepared to expect wonders.",
            source: "Henry David Thoreau, 1860"
        ),
        Passage(
            text: "Earth laughs in flowers.",
            source: "Ralph Waldo Emerson, Hamatreya"
        ),
        Passage(
            text: "The creation of a thousand forests is in one acorn.",
            source: "Ralph Waldo Emerson, History, 1841"
        ),
        Passage(
            text: "It is interesting to contemplate an entangled bank, clothed with many plants of many kinds.",
            source: "Charles Darwin, 1859"
        ),
        Passage(
            text: "Now I see the secret of the making of the best persons: it is to grow in the open air.",
            source: "Walt Whitman, 1856"
        ),
        Passage(
            text: "To make a prairie it takes a clover and one bee — one clover, and a bee, and revery.",
            source: "Emily Dickinson (1830–1886)"
        ),
        Passage(
            text: "To plant seeds, and watch their renewal of life — this is the commonest delight of the race.",
            source: "Charles Dudley Warner, 1870"
        ),
        Passage(
            text: "To travel hopefully is a better thing than to arrive.",
            source: "Robert Louis Stevenson, 1881"
        ),
        Passage(
            text: "Long live the weeds and the wilderness yet.",
            source: "Gerard Manley Hopkins (1844–1889)"
        ),
        Passage(
            text: "And I shall have some peace there, for peace comes dropping slow.",
            source: "W. B. Yeats, 1890"
        ),
        Passage(
            text: "A garden is a grand teacher. It teaches patience and careful watchfulness.",
            source: "Gertrude Jekyll, 1899"
        ),
        Passage(
            text: "The world puts off its mask of vastness to its lover. It becomes small as one song, as one kiss of the eternal.",
            source: "Rabindranath Tagore, Stray Birds, 1916"
        ),
        Passage(
            text: "Rose is a rose is a rose is a rose.",
            source: "Gertrude Stein, 1913"
        ),
        Passage(
            text: "Your friend is your needs answered. He is your field, which you sow with love and reap with thanksgiving.",
            source: "Kahlil Gibran, 1923"
        ),
        Passage(
            text: "I thought myself rich when I found another: a person is a person's delight.",
            source: "Hávamál, Old Norse"
        ),
        Passage(
            text: "May the road rise up to meet you.",
            source: "Traditional Irish blessing"
        ),
        Passage(
            text: "Great oaks from little acorns grow.",
            source: "English proverb"
        ),
        Passage(
            text: "The best fertiliser is the gardener's shadow.",
            source: "Gardener's proverb"
        ),
        Passage(
            text: "One generation plants the trees; another gets the shade.",
            source: "Chinese proverb"
        ),

        // MARK: - Definitions
        //
        // Each sense is written here from an understanding of the word, so the
        // wording belongs to this file and no lexicographer's phrasing is being
        // carried along with it. Words are chosen for how well they suit two
        // people meeting by chance, which is why so many of them are about
        // turning, touching and waiting.

        Passage(
            text: "Ichigo ichie: one meeting, one chance. This gathering is the only one of its kind, so meet it whole.",
            source: "Japanese, from the way of tea"
        ),
        Passage(
            text: "Ubuntu: a person is made a person by other people, and our humanity shows itself in what passes between us.",
            source: "Nguni Bantu"
        ),
        Passage(
            text: "Petrichor: the smell that lifts off dry ground when rain first reaches it.",
            source: "English, coined 1964"
        ),
        Passage(
            text: "Apricity: the warmth of the sun as it is felt on a winter's day.",
            source: "English, first recorded 1623"
        ),
        Passage(
            text: "Inosculation: two trees that grow against one another long enough to fuse, and afterwards share bark and sap.",
            source: "Botany"
        ),
        Passage(
            text: "Thigmotropism: growth steered by touch, as a tendril winds around whatever it happens to meet.",
            source: "Botany"
        ),
        Passage(
            text: "Heliotropism: the turning of a plant through the day so that it keeps its face to the sun.",
            source: "Botany"
        ),
        Passage(
            text: "Nyctinasty: the folding of leaves and petals at dusk, and their opening again with the light.",
            source: "Botany"
        ),
        Passage(
            text: "Anthesis: the span of a flower's life during which it stands open.",
            source: "Botany"
        ),
        Passage(
            text: "Anemochory: travel by wind, where a seed makes its entire journey on moving air.",
            source: "Botany"
        ),
        Passage(
            text: "Vernalisation: the long cold a seed or a bud passes through, after which spring is able to move it.",
            source: "Botany"
        ),
        Passage(
            text: "Kairos: the opening in time when a thing can be done — the right moment, as distinct from the hour on the clock.",
            source: "Ancient Greek"
        ),
        Passage(
            text: "Clinamen: the faint swerve by which falling atoms come to meet one another, and so make a world.",
            source: "Lucretius, first century BC"
        ),
        Passage(
            text: "Querencia: the place a creature keeps returning to, where it is most itself and draws its strength.",
            source: "Spanish"
        ),
        Passage(
            text: "Gökotta: rising at first light to go outside and listen to the earliest birds.",
            source: "Swedish"
        ),
        Passage(
            text: "Smultronställe: a wild-strawberry place — a small, treasured spot you go back to on your own.",
            source: "Swedish"
        ),
        Passage(
            text: "Psithurism: the sound of wind moving through leaves.",
            source: "English, from Greek"
        ),
        Passage(
            text: "Volunteer: a plant that arrives of its own accord and grows in ground that somebody else left bare.",
            source: "Gardener's term"
        ),

        // MARK: - Etymologies
        //
        // Word origins are facts and belong to nobody, but the way a dictionary
        // tells them is that dictionary's own. These are told here in whole
        // sentences, and the spellings of old forms are transliterated so they
        // set cleanly in any font the app might use.

        Passage(
            text: "A companion is one you break bread with: Latin com, together, and panis, bread.",
            source: "Latin"
        ),
        Passage(
            text: "Paradise began as a walled garden — Old Persian pairidaeza, an enclosure planted for pleasure.",
            source: "Old Persian"
        ),
        Passage(
            text: "Garden, yard and girdle share one root meaning an enclosure. A garden is first of all a kept place.",
            source: "Proto-Germanic"
        ),
        Passage(
            text: "A season is a sowing. The word descends from Latin satio, the time at which seed goes into the ground.",
            source: "Latin"
        ),
        Passage(
            text: "Peace is Latin pax, kin to pangere, to fasten. A peace was something two sides made fast between them.",
            source: "Latin"
        ),
        Passage(
            text: "A neighbour is a near-dweller: Old English neah, near, and gebur, one who lives here.",
            source: "Old English"
        ),
        Passage(
            text: "To meet is to come to the moot: Old English metan, from gemot, the gathering where matters were settled.",
            source: "Old English"
        ),
        Passage(
            text: "Encounter reaches English from Latin in contra — to come face to face with whatever stands opposite.",
            source: "Old French"
        ),
        Passage(
            text: "Chance descends from Latin cadere, to fall. A chance is simply the way things happened to fall out.",
            source: "Latin"
        ),
        Passage(
            text: "Horace Walpole coined serendipity in 1754 from Serendip, an old name for Sri Lanka, after a tale of three lucky princes.",
            source: "English, 1754"
        ),
        Passage(
            text: "Thrive comes from Old Norse thrifask, to grasp for oneself. Thriving was once a matter of taking hold.",
            source: "Old Norse"
        ),
        Passage(
            text: "Kind and kin are one word. To be kind was first to treat someone as though they were family.",
            source: "Old English"
        ),
        Passage(
            text: "Friend is an old present participle of a verb meaning to love. A friend is, quite literally, one loving.",
            source: "Proto-Germanic"
        ),
        Passage(
            text: "Human, humble and humus grow from a single Latin root: the ground itself.",
            source: "Latin"
        ),
        Passage(
            text: "An anthology is a gathering of flowers: Greek anthos, flower, and legein, to gather up.",
            source: "Greek"
        ),
        Passage(
            text: "Rivals were once people who shared a stream: Latin rivalis, from rivus, a brook.",
            source: "Latin"
        ),
        Passage(
            text: "Symbiosis is Greek for living together. It was coined in the 1870s for lichens, which are a fungus and an alga as one.",
            source: "Greek"
        ),
        Passage(
            text: "Daisy is the day's eye, named for a flower that opens with the light and closes again at dusk.",
            source: "Old English"
        ),
        Passage(
            text: "Green, grow and grass come from one Germanic root. The colour is named for what growing things do.",
            source: "Old English"
        ),
        Passage(
            text: "Culture and cultivate come from Latin colere: to till the ground, to tend it, and to hold it in honour.",
            source: "Latin"
        ),

        // MARK: - Facts
        //
        // Each of these is stated from the underlying finding rather than
        // paraphrased from an article about it, and each carries enough of a
        // reference for a curious person to go and check. Figures are given
        // roughly on purpose: several are estimates with real error bars, and a
        // round number is the more honest way to show that.

        Passage(
            text: "New leaves are set about 137.5 degrees around from the last, the one angle at which every leaf keeps a share of the light.",
            source: "Phyllotaxis, the golden angle"
        ),
        Passage(
            text: "Count the spirals in a sunflower head each way and you will nearly always land on two neighbouring Fibonacci numbers, such as 34 and 55.",
            source: "Helianthus annuus"
        ),
        Passage(
            text: "Young sunflowers follow the sun west and swing back east overnight. Grown ones settle facing east, where morning warmth brings the bees earlier.",
            source: "Science, 2016"
        ),
        Passage(
            text: "A dandelion's parachute holds a ring of circling air just above itself, and that steady vortex is what carries a seed a mile from home.",
            source: "Nature, 2018"
        ),
        Passage(
            text: "A date seed from Masada, dated to roughly two thousand years old, was sown in 2005 and grew. The tree is called Methuselah.",
            source: "Phoenix dactylifera, Israel"
        ),
        Passage(
            text: "Ground squirrels buried fruits in Siberia some thirty-two thousand years ago. In 2012 the tissue inside them was grown on into whole flowering plants.",
            source: "Silene stenophylla, PNAS 2012"
        ),
        Passage(
            text: "A sacred lotus seed lifted from an old lake bed in Liaoning germinated after about thirteen hundred years, and the plant is growing still.",
            source: "Nelumbo nucifera"
        ),
        Passage(
            text: "Seeds were sealed into bottles and buried in 1879. A bottle opened in 2021 still held mullein seeds that woke and grew.",
            source: "Beal's seed experiment, Michigan"
        ),
        Passage(
            text: "Six ginkgos standing within two kilometres of the Hiroshima blast came through it, put out leaves again, and are alive today.",
            source: "Hibakujumoku, Hiroshima"
        ),
        Passage(
            text: "Every Bramley apple is a cutting from one tree, grown from a pip that Mary Ann Brailsford planted in a pot in 1809.",
            source: "Southwell, Nottinghamshire"
        ),
        Passage(
            text: "Sow a pip from any apple and what comes up is a wholly new variety, which is why named apples travel as grafts.",
            source: "Malus domestica"
        ),
        Passage(
            text: "Every green leaf runs on a bacterium that another cell took in more than a billion years ago. The two have been one ever since.",
            source: "Endosymbiosis"
        ),
        Passage(
            text: "Most land plants trade sugar for phosphorus with fungi threaded through the soil. The arrangement is around four hundred million years old.",
            source: "Mycorrhizal symbiosis"
        ),
        Passage(
            text: "Orchid seed is as fine as dust and carries almost nothing to live on. Each grain waits for a fungus to feed it into life.",
            source: "Orchidaceae"
        ),
        Passage(
            text: "Pollen wears a sculpted coat of sporopollenin, tough enough that grains keep their pattern in peat for thousands of years and can still be named.",
            source: "Palynology"
        ),
        Passage(
            text: "Many flowers read the pollen that lands on them and open a path for a stranger's grain, so that the next generation comes from two.",
            source: "Self-incompatibility in plants"
        ),
        Passage(
            text: "A flowering plant is fertilised twice at once: one sperm makes the embryo, the other makes the store of food packed around it.",
            source: "Double fertilisation"
        ),
        Passage(
            text: "In most flowering plants the chloroplasts descend through the seed parent alone, so a part of one parent travels on unmixed.",
            source: "Plastid inheritance"
        ),
        Passage(
            text: "Flowers carry a faint electric charge. A bumblebee can feel it, and read from it which blooms another bee has lately emptied.",
            source: "Science, 2013"
        ),
        Passage(
            text: "A returning honeybee dances the angle of the flowers against the sun, and the length of her waggle tells the others how far to fly.",
            source: "Karl von Frisch"
        ),
        Passage(
            text: "Burdock burs caught on a Swiss engineer's dog in 1941. He put the hooks under a microscope, and the result was Velcro.",
            source: "Arctium, and George de Mestral"
        ),
        Passage(
            text: "Some bamboos flower once, all together, all over the world, after more than a century. Plants from one stock keep the same clock.",
            source: "Phyllostachys bambusoides"
        ),
        Passage(
            text: "A coconut can float for months across open ocean and root where it comes ashore. Whole island floras arrived that way.",
            source: "Cocos nucifera"
        ),
        Passage(
            text: "One seagrass in the Mediterranean has spread sideways for perhaps a hundred thousand years, and the whole meadow counts as a single plant.",
            source: "Posidonia oceanica"
        )
    ]

    /// The passage that belongs to two people.
    ///
    /// Takes a `pairID` — `Pollination.pairID`, a digest of the two parent
    /// seeds. This has to be a pure function of those bytes and of nothing else:
    /// both phones compute it independently, and the same pair must give the
    /// same passage on a different device, on a later OS, and years from now.
    /// That rules out `Hasher`, whose seed is randomised per process, so the
    /// fold below is spelled out here instead.
    static func passage(for pairID: Data) -> Passage {
        precondition(!all.isEmpty, "the passage bank must never be empty")
        let index = Int(fold(pairID) % UInt64(all.count))
        return all[index]
    }

    /// FNV-1a over the whole digest.
    ///
    /// Every byte is folded rather than a prefix taken, so a passage depends on
    /// the whole of what it is given. Wrapping arithmetic is the point of the
    /// algorithm rather than an accident, which is why it is written with `&*`.
    private static func fold(_ bytes: Data) -> UInt64 {
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325
        for byte in bytes {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01B3
        }
        return hash
    }
}
