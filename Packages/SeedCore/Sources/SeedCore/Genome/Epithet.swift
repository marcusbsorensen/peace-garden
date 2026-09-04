import Foundation

/// The second half of a binomial: one true statement about this specimen.
///
/// **An epithet is not a decoration.** `docs/TAXONOMY.md` §2: it names the
/// character in which this plant most departs from its genus, which is what an
/// epithet is for and what makes a key possible. Before this, the epithet was
/// two syllables drawn from the seed and glued together — *stellifolia* on a
/// plant whose leaves are not star-shaped, *tacitantha* saying nothing about
/// the flower, and *pallicola* meaning "pale-dwelling", which is not a thing a
/// plant can be.
///
/// So the rule is: **say only what is so.** Every epithet below is checked
/// against the plant before it is given, and a plant with nothing remarkable
/// about it is *vulgaris* rather than flattered.
///
/// ## How a departure is measured
///
/// Every continuous trait is drawn as a position in its own range —
/// `GeneSource.value` is `lower + unit(label) * width` — so `unit(label)` *is*
/// this plant's rank among the plants of its genus. Every plant of a genus
/// draws the same labels through the same `ArchetypeProfile`, so a position of
/// 0.94 in `foliage.length` means the leaves are longer than 94% of the genus,
/// exactly and without having to work out what the genus's average is.
///
/// That is why the source is asked again here rather than the finished traits
/// being measured back. It is the same number, it costs a hash, and it cannot
/// drift out of step with the arithmetic in `Genome.init` the way a
/// reconstructed mean would.
///
/// Traits drawn with `bell` are read the same way, by averaging the three units
/// it sums. A centre-weighted trait reaching 0.9 is rarer than a uniform one
/// doing the same, which is right: a plant whose leaves droop that far really
/// is unusual, and *pendula* should be rare.
///
/// ## Colour is measured differently, and deliberately
///
/// Colour is absolute, not relative to the genus, because `Palette` does not
/// consult the archetype — a genus constrains no colour at all, so there is no
/// genus average to depart from. And *aurea* means golden however golden its
/// neighbours are. A hue band is the honest test.
public struct Epithet: Equatable, Sendable {

    /// Which gender the epithet has to agree in.
    ///
    /// A property of the written genus, and the single most visible tell to
    /// anybody who has read a flora: *Aurelia nocturna*, never *Aurelia
    /// nocturnum*.
    ///
    /// **Only `-ynth` is masculine.** It is the Greek `-ynthos` — *Hyacinthus*,
    /// *Absinthium* — and Latinises to a masculine second-declension noun. The
    /// nine other endings are `-a`, `-ia`, `-ea`, `-ina`, `-ora`, `-ula`,
    /// `-era`, `-yne` and `-is`: the seven in `-a` are first-declension
    /// feminines, `-yne` is the Greek feminine `-ynē`, and `-is` is a
    /// third-declension feminine on the model of *Arabis* and *Berberis*.
    /// `docs/TAXONOMY.md` §3 left these two to be decided; this is the
    /// decision, and it makes one genus in ten masculine, which is enough for
    /// the agreement to be visible rather than theoretical.
    public enum Gender: Sendable {
        case feminine
        case masculine

        static func of(genusTail: String) -> Gender {
            genusTail == "ynth" ? .masculine : .feminine
        }
    }

    /// The two forms of one epithet.
    ///
    /// Written as a pair rather than derived by a rule, because the rule has
    /// exceptions and they are the ones a reader notices: *ruber* is masculine
    /// to *rubra*, not *rubrus*, and third-declension adjectives like
    /// *vulgaris* and *crassicaulis* do not change at all.
    struct Form: Sendable {
        let feminine: String
        let masculine: String

        init(_ feminine: String, _ masculine: String) {
            self.feminine = feminine
            self.masculine = masculine
        }

        /// For the regular pattern, `-a` against `-us`.
        init(_ stem: String) {
            self.feminine = stem + "a"
            self.masculine = stem + "us"
        }

        /// For third-declension adjectives, which do not decline for gender.
        static func invariant(_ word: String) -> Form { Form(word, word) }

        func written(_ gender: Gender) -> String {
            gender == .feminine ? feminine : masculine
        }
    }

    /// A candidate: what would be said, and how rare it is to be able to say it.
    ///
    /// **Notability is rarity, and that is the whole selection rule**: of the
    /// true things, say the one fewest of this plant's relatives could have
    /// said. It is what a botanist naming a specimen does, and it is the only
    /// scale on which a marking and a measurement can be compared at all.
    ///
    /// Getting this wrong is neither subtle nor visible. The first version
    /// scored the two kinds of character on unrelated scales, so *variegata* —
    /// true of **37%** of plants — outranked every measurement and took a third
    /// of the garden. The names still looked like names.
    /// `testEveryEpithetIsReachableAndNoneDominates` is what said otherwise.
    struct Candidate {
        let form: Form
        /// The share of plants this could be said of. Lower is worth more.
        let rate: Double
        /// How far past the floor, for choosing between two characters of equal
        /// rarity. A tie-break only: it cannot promote a common character over
        /// a rare one.
        var extremity: Double = 0

        func beats(_ other: Candidate) -> Bool {
            rate == other.rate ? extremity > other.extremity : rate < other.rate
        }
    }

    /// How far into a tail a continuous trait must reach to be worth naming.
    ///
    /// **This is the "floor" of `docs/TAXONOMY.md` §3's third question**, and
    /// the reason the answer was *the notable* rather than *the extreme*. The
    /// extreme is always available, so every plant would be named for something
    /// however ordinary it was, and the name would stop meaning anything —
    /// *longifolia* on a plant with middling leaves that happened to be its
    /// least middling trait.
    ///
    /// At 0.12 a trait has to be in the top or bottom eighth of its genus.
    /// Across the continuous characters that leaves about a tenth of plants
    /// with nothing to say, which is what `vulgaris` is for.
    static let floor = 0.12

    /// How often each categorical character is true, **measured** over twenty
    /// thousand seeds rather than assumed.
    ///
    /// These are what put a marking and a measurement on one scale, so they are
    /// load-bearing rather than documentation. `testTheDeclaredRatesAreTheRealOnes`
    /// re-measures them, because a rate that goes stale silently restores the
    /// exact bug they were written to fix — and a palette is the kind of thing
    /// that gets retuned.
    ///
    /// Three of these were unreachable when first written, because the
    /// thresholds were guessed rather than measured: petal brightness never
    /// leaves `0.45...0.82` and veining never passes `0.65`, so *pallida*,
    /// *obscura* and *venosa* could not be said of any plant in the garden. A
    /// vocabulary with dead words in it is a vocabulary nobody has checked.
    ///
    /// **`leafy` moved on 3 September 2026**, from 0.240, and it is the proof
    /// that the guard was worth writing. Widening the vegetative half took
    /// `stem.nodeCount` from `2...7` to `2...9`; a third of the garden now
    /// carries fifteen leaves where a quarter did, so *foliosa* went from a
    /// character worth naming to one about as ordinary as *variegata*. Nothing
    /// about that is visible in a name — every plant still reads perfectly
    /// well — and it is the same silent failure the rest of this table exists
    /// to catch. The seven colour rates are untouched, because no colour range
    /// moved.
    enum Rate {
        static let variegation = 0.367
        static let marbling = 0.315
        static let leafy = 0.330
        static let night = 0.297
        static let picotee = 0.182
        static let blue = 0.147
        static let vivid = 0.091
        static let dark = 0.089
        static let panicle = 0.086
        static let veined = 0.083
        static let gold = 0.064
        static let red = 0.057
        static let pale = 0.020
    }

    /// The plant with nothing remarkable about it.
    ///
    /// A real flora reaches for *vulgaris* constantly and for exactly this
    /// reason. It is third-declension, so it is the same in both genders, and
    /// it is the honest answer: this is an ordinary member of its genus. A
    /// plant named *vulgaris* is the closest thing the garden has to the type.
    static let ordinary = Form.invariant("vulgaris")

    public let written: String
    public let gender: Gender
}

extension Epithet {

    /// Reads the plant and says the one truest thing about it.
    static func describing(
        source: GeneSource,
        genusTail: String,
        stem: Genome.Stem,
        foliage: Genome.Foliage,
        branching: Genome.Branching,
        palette: Genome.Palette,
        tempo: Genome.Tempo,
        leafCount: Int
    ) -> Epithet {
        let gender = Gender.of(genusTail: genusTail)
        var candidates: [Candidate] = []

        // MARK: Foliage
        //
        // Every `-folia` epithet below is a real one and means what it says.
        // The suffix governs a shape or a size, never a colour and never a
        // habitat — which is the grammar rule §3 asks for, kept by never
        // building an epithet out of parts in the first place.
        consider(&candidates, source.position("foliage.length"),
                 low: Form("brevifoli"), high: Form("longifoli"))
        consider(&candidates, source.position("foliage.widthRatio"),
                 low: Form("angustifoli"), high: Form("latifoli"))
        consider(&candidates, source.bellPosition("foliage.serration"),
                 low: Form("integrifoli"), high: Form("serratifoli"))
        consider(&candidates, source.bellPosition("foliage.droop"),
                 low: Form("erect"), high: Form("pendul"))
        consider(&candidates, source.position("foliage.pitch"),
                 low: nil, high: Form("patentifoli"))

        // MARK: Habit

        consider(&candidates, source.position("stem.height"),
                 low: Form("nan"), high: Form("elat"))
        consider(&candidates, source.position("stem.baseRadius"),
                 low: Form.invariant("gracilis"), high: Form.invariant("crassicaulis"))
        consider(&candidates, source.magnitude("stem.lean"),
                 low: nil, high: Form("declinat"))
        consider(&candidates, source.magnitude("stem.twist"),
                 low: nil, high: Form("contort"))
        consider(&candidates, source.bellPosition("stem.sway"),
                 low: nil, high: Form("flexuos"))

        // Leaves are counted rather than drawn, so this one is a real count
        // against the genus's own range rather than a position in a draw.
        // Nodes and leaves-per-node both feed it, which is why it is worth
        // saying separately from `longifolia`.
        if leafCount >= 15 { candidates.append(Candidate(form: Form("folios"), rate: Rate.leafy)) }

        // A spray wide enough to be worth naming. `.head` families only — the
        // other two have nothing to spread.
        if branching.inflorescence == .head, branching.spread > 0.82 {
            candidates.append(Candidate(form: Form("paniculat"), rate: Rate.panicle))
        }

        // MARK: Colour, which is absolute. See the note at the top.
        //
        // Every threshold here is a measured percentile of the palette rather
        // than a guess at one. The first set was guessed and three of them
        // could never fire: petal brightness lives in `0.45...0.82` and never
        // reaches the `0.86` *pallida* was asking for.

        let petal = palette.petalBase
        if petal.brightness > 0.75, petal.saturation < 0.30 {
            candidates.append(Candidate(form: Form("pallid"), rate: Rate.pale))
        }
        if petal.brightness < 0.479 {
            candidates.append(Candidate(form: Form("obscur"), rate: Rate.dark))
        }
        if petal.saturation > 0.888 {
            candidates.append(Candidate(form: Form("vivid"), rate: Rate.vivid))
        }
        if (0.10...0.18).contains(petal.hue), petal.saturation > 0.45 {
            candidates.append(Candidate(form: Form("aure"), rate: Rate.gold))
        }
        if (0.58...0.78).contains(petal.hue), petal.saturation > 0.45 {
            candidates.append(Candidate(form: Form("caerule"), rate: Rate.blue))
        }
        // *ruber, rubra, rubrum* — the irregular one, and the reason `Form`
        // holds two words rather than a stem. `caeruleus` is regular and was
        // wrongly written invariant first time; the gender test caught it.
        if petal.hue > 0.95 || petal.hue < 0.035, petal.saturation > 0.5 {
            candidates.append(Candidate(form: Form("rubra", "ruber"), rate: Rate.red))
        }

        // MARK: Markings, which are either there or not

        if palette.picotee != nil {
            candidates.append(Candidate(form: Form("marginat"), rate: Rate.picotee))
        }
        if palette.variegation != .none {
            candidates.append(Candidate(form: Form("variegat"), rate: Rate.variegation))
        }
        if palette.marbling != .none {
            candidates.append(Candidate(form: Form("marmorat"), rate: Rate.marbling))
        }
        if palette.veining > 0.546 {
            candidates.append(Candidate(form: Form("venos"), rate: Rate.veined))
        }

        // MARK: When it opens
        //
        // *noctiflora* is the one epithet here that was already in the old
        // vocabulary and already true — it just was not checked. Now it is only
        // said of a plant that actually opens at night.
        if !tempo.opensByDay {
            candidates.append(Candidate(form: Form("noctiflor"), rate: Rate.night))
        }

        // The rarest true thing, with extremity only breaking ties between
        // characters of equal rarity.
        let chosen = candidates.reduce(nil as Candidate?) { best, next in
            guard let best else { return next }
            return next.beats(best) ? next : best
        }?.form ?? ordinary
        return Epithet(written: chosen.written(gender), gender: gender)
    }

    /// Adds the low or the high reading of one trait, if either clears the floor.
    ///
    /// A trait with nothing to say at one end passes `nil` for it — nothing
    /// about a stem leaning less than usual is worth a name, because not
    /// leaning is what stems do.
    private static func consider(
        _ candidates: inout [Candidate],
        _ position: Double,
        low: Form?,
        high: Form?
    ) {
        // Both readings are sayable of a twelfth of the genus, so both carry
        // `floor` as their rate. Which end this plant is at decides the word;
        // how far into the tail it reaches only breaks ties.
        if position <= floor, let low {
            candidates.append(Candidate(form: low, rate: floor, extremity: floor - position))
        } else if position >= 1 - floor, let high {
            candidates.append(Candidate(form: high, rate: floor, extremity: position - (1 - floor)))
        }
    }
}

extension GeneSource {
    /// Where this plant sits among the plants of its genus, in `0...1`.
    ///
    /// The same number `value(_:_:)` used to place the trait in its range, so
    /// it is a rank and not an estimate of one.
    func position(_ label: String) -> Double { unit(label) }

    /// The same, for a trait drawn with `bell(_:_:)`, which sums three units.
    func bellPosition(_ label: String) -> Double {
        (unit(label + ".a") + unit(label + ".b") + unit(label + ".c")) / 3.0
    }

    /// How far a `signed(_:)` trait is from centred, in `0...1`.
    ///
    /// Lean and twist have no meaningful low end — a plant that leans slightly
    /// left is not the opposite of one that leans slightly right, it is the
    /// same plant. What is worth naming is leaning *at all*, either way.
    func magnitude(_ label: String) -> Double { abs(signed(label)) }
}
