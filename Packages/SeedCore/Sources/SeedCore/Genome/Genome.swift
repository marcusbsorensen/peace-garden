import Foundation

/// Where a plant came from.
public enum Lineage: Equatable, Codable, Sendable {
    case minted
    case crossed(parentA: SeedID, parentB: SeedID, encounterID: Data)

    public var parents: (SeedID, SeedID)? {
        if case let .crossed(a, b, _) = self { return (a, b) }
        return nil
    }

    public var isHybrid: Bool { parents != nil }
}

/// A hue/saturation/brightness triple in `0...1`.
public struct HSB: Equatable, Codable, Sendable {
    public var hue: Double
    public var saturation: Double
    public var brightness: Double

    public init(hue: Double, saturation: Double, brightness: Double) {
        self.hue = hue
        self.saturation = saturation
        self.brightness = brightness
    }
}

/// The full expressed trait set of one plant.
///
/// A genome is *derived*, never stored: everything below is a pure function of
/// the seed (plus, for hybrids, the two parent seeds). Persistence only keeps
/// the seed and lineage, so a saved garden is a few hundred bytes per plant and
/// can never drift out of sync with the plant it draws.
public struct Genome: Equatable, Sendable {
    public struct Form: Equatable, Sendable {
        public var archetype: Archetype
        /// How many parts the flower is built in, as a class. The count itself
        /// is `bloom.petalCount`.
        ///
        /// **This replaced `symmetry`**, which was drawn into every genome
        /// from the first commit and read by nothing — not by the geometry, not
        /// by the name, not by a test. A trait nothing consumes cannot be
        /// keyed, and a plant that cannot be keyed is what `docs/TAXONOMY.md`
        /// was written about. Removing it is free: a `Genome` is derived from a
        /// seed every time and never stored, so no garden on any phone holds a
        /// field that has gone.
        public var merosity: Merosity
        public var vigour: Double
    }

    /// How this plant carries its flowers, and the stalks that follow from it.
    ///
    /// Derived from the archetype, which is itself drawn from the seed — so a
    /// hybrid's form comes free with the archetype its own seed picks, and
    /// nothing new has to cross. Two phones reach the same head from the same
    /// seed without sending anything, which is the guarantee the whole exchange
    /// rests on.
    public struct Branching: Equatable, Sendable {
        public var inflorescence: Inflorescence
        /// Stalks given off the upper stem. `.head` only.
        public var count: Int
        /// Flat-topped at 0, an open spray at 1. `.head` only.
        public var spread: Double
        /// How far off the stem's own line a stalk leaves it, in radians.
        public var angle: Double
        /// How large every bloom is drawn, against a raceme's.
        public var bloomScale: Double
    }

    public struct Stem: Equatable, Sendable {
        public var height: Double
        public var baseRadius: Double
        public var taper: Double
        public var lean: Double
        public var sway: Double
        public var twist: Double
        public var nodeCount: Int
        public var sides: Int
    }

    public struct Foliage: Equatable, Sendable {
        public var leavesPerNode: Int
        public var length: Double
        public var widthRatio: Double
        public var droop: Double
        public var fold: Double
        public var pitch: Double
        public var divergence: Double
        public var serration: Double
        /// How many teeth the margin is cut into.
        public var teeth: Int
        /// Ribs running from the midrib out to the margin.
        public var veinCount: Int
        public var veinDepth: Double
        public var tipSharpness: Double
    }

    public struct Bloom: Equatable, Sendable {
        public var petalCount: Int
        public var layers: Int
        public var length: Double
        public var widthRatio: Double
        public var curl: Double
        public var twist: Double
        public var tipSharpness: Double
        public var headPitch: Double
        public var centreRadius: Double
        public var stamenCount: Int
        /// A cleft in the tip of each petal, as a pink or a campion has.
        public var notch: Double
        /// The green collar beneath the flower.
        public var sepalCount: Int
        public var hasPistil: Bool
        public var atNodes: Bool
        public var present: Bool
    }

    public struct Palette: Equatable, Sendable {
        /// How the two petal colours relate. Kept on the palette because it is
        /// worth telling someone what their flower is doing.
        public var scheme: ColourScheme
        /// The colour at the base of a petal, nearest the flower's centre.
        public var petalBase: HSB
        /// The colour at the petal's tip.
        public var petalTip: HSB
        /// The mark in the flower's throat, where the petals meet.
        public var petalThroat: HSB
        public var petalVein: HSB
        /// A contrasting rim, as a picotee carnation has. Usually absent.
        public var picotee: HSB?
        public var veining: Double
        /// How the petal's pigment breaks up. Usually it does not.
        public var marbling: Marbling
        /// The colour showing through where the pigment has broken.
        public var marble: HSB
        /// The scale of the pattern: low is a few broad flames, high is a fine
        /// feathering.
        public var marbleScale: Double
        /// Seeds the pattern, so two flowers marbled the same way are still
        /// marbled differently.
        public var marbleSeed: UInt64

        public var foliageTone: FoliageTone
        public var leaf: HSB
        public var variegation: Variegation
        /// The second leaf colour, used according to `variegation`.
        public var leafAccent: HSB
        /// The colour of a leaf's midrib and the veins branching off it.
        ///
        /// Petals have had veins from the start and leaves have not, which is
        /// backwards: venation is most of what tells the eye a green shape is a
        /// leaf rather than a painted panel.
        public var leafVein: HSB
        /// How strongly the venation shows, 0 for a leaf that hides it.
        public var leafVeining: Double
        /// How far the blade is quilted between its veins, 0 for a flat leaf.
        ///
        /// Read as relief rather than as colour: it is what the normal map is
        /// built from, so a high value catches the light in ridges without
        /// changing the leaf's colour at all.
        public var leafQuilting: Double

        public var stem: HSB
        public var centre: HSB
        public var glow: Double
        public var sheen: Double
        /// Seeds the patch pattern on speckled leaves.
        public var speckleSeed: UInt64
    }

    /// How the plant unfolds in real time. Days are real days: the plant a
    /// person carries is meant to be watched over weeks, not scrubbed.
    public struct Tempo: Equatable, Sendable {
        public var germinationHours: Double
        public var seedlingDays: Double
        public var vegetativeDays: Double
        public var buddingDays: Double
        public var bloomDays: Double
        public var opensByDay: Bool

        public var daysToBloom: Double {
            germinationHours / 24.0 + seedlingDays + vegetativeDays + buddingDays
        }
    }

    public let seed: SeedID
    public let lineage: Lineage
    public let form: Form
    public let branching: Branching
    public let stem: Stem
    public let foliage: Foliage
    public let bloom: Bloom
    public let palette: Palette
    public let tempo: Tempo
    public let name: PlantName

    public var isHybrid: Bool { lineage.isHybrid }

    /// Total leaves once fully grown.
    public var leafCount: Int { stem.nodeCount * foliage.leavesPerNode }

    // MARK: - Derivation

    public init(seed: SeedID, lineage: Lineage = .minted) {
        let source: GeneSource
        switch lineage {
        case .minted:
            source = .primary(seed)
        case let .crossed(parentA, parentB, _):
            source = .hybrid(child: seed, parentA: parentA, parentB: parentB)
        }
        self.init(seed: seed, lineage: lineage, source: source)
    }

    private init(seed: SeedID, lineage: Lineage, source: GeneSource) {
        self.seed = seed
        self.lineage = lineage

        let archetype = source.pick("form.archetype", from: Archetype.allCases)
        let profile = ArchetypeProfile.profile(for: archetype)

        // The two floral facts the name is read from. Everything below is the
        // plant; these two are also its classification.
        let merosity: Merosity = source.chance("bloom.merosity", 0.5) ? .many : .few

        // **The vegetative half is drawn wide on purpose.** Every range from
        // here to the end of `foliage` is wider than it was before 3 September
        // 2026, and docs/TAXONOMY.md §"What the archetype profiles constrain"
        // is why: a family is constant in its flower and various in everything
        // else, which is precisely how two plants of one family can look
        // nothing alike and still key the same. The flower above is held to a
        // count per genus; the stem and the leaves are given room.
        //
        // The ranges widened rather than the `ArchetypeProfile` multipliers,
        // and that distinction is the whole of it. A multiplier moves where a
        // family's centre sits, which is between-family difference; a range
        // decides how far one plant may stand from its own relatives, which is
        // what a genus is allowed to vary in. Only the fern's `leafDroop` moved,
        // and only downward — see `ArchetypeProfile`.
        //
        // Vigour scales height and leaf alike, so it is the one knob that
        // changes a plant's size without changing its proportions. It is worth
        // widening anyway, because `baseRadius` and `nodeCount` are drawn
        // independently of it: a vigorous plant comes out taller on the same
        // stem thickness with the same number of nodes, which reads as drawn
        // out rather than merely larger.
        form = Form(
            archetype: archetype,
            merosity: merosity,
            vigour: source.bell("form.vigour", 0.74...1.30)
        )

        // New keys only, and every existing one left exactly as it was.
        // `GeneSource` draws by name rather than by position in a stream, so
        // adding these cannot shift a trait already growing on somebody's
        // phone — which is the only property here that could not be fixed
        // later.
        branching = Branching(
            inflorescence: profile.inflorescence,
            count: max(3, min(7, Int(
                (Double(profile.branchCount) * source.value("stem.branch.count", 0.72...1.34)).rounded()
            ))),
            spread: (profile.branchSpread + source.signed("stem.branch.spread") * 0.14)
                .clamped(to: 0...1),
            angle: source.value("stem.branch.angle", 1.0...1.35),
            bloomScale: profile.bloomScale
        )

        // Height and radius are drawn independently, so widening both widens
        // the *ratio* between them — which is what actually reads, because both
        // the app and `tools/preview` frame a plant to fill the view. Nobody
        // ever sees a plant next to a ruler; they see it next to its own
        // thickness and its own leaves. `nodeCount`'s ceiling is set by the
        // succulent, whose `nodeScale` of 2.1 takes 9 to 19 and no further:
        // `GenomeTests` declares 20 the limit.
        let height = source.value("stem.height", 0.44...1.42) * profile.heightScale * form.vigour
        let baseRadius = source.value("stem.baseRadius", 0.006...0.022) * profile.stemThickness
        stem = Stem(
            height: height,
            baseRadius: baseRadius,
            taper: source.value("stem.taper", 0.16...0.86),
            lean: source.signed("stem.lean") * 0.75,
            sway: source.bell("stem.sway", 0...1.25) * profile.swayScale,
            twist: source.signed("stem.twist") * 0.95,
            nodeCount: max(1, Int((Double(source.integer("stem.nodeCount", 2...9)) * profile.nodeScale).rounded())),
            sides: source.integer("stem.sides", 6...9)
        )

        // **Leaf length is the widest of these, and the one that pays most.**
        // Nearly fivefold, against twofold and a bit before. A leaf is only
        // ever seen against the plant carrying it, so decoupling its size from
        // the stem's is what turns one genus into a leafy individual and a bare
        // one — and the bare end is the more legible of the two, which is why
        // most of the new range is below the old floor rather than above its
        // ceiling.
        //
        // Two of these widened downward only, and for the same reason.
        // `addSurface` gives a blade nineteen rows, and both `teeth` and
        // `veinCount` are sampled along those rows — at their old ceilings of
        // 17 and 9 they are already at or past what nineteen rows can resolve,
        // so raising either would draw a coarser leaf rather than a finer one.
        // Widening them the other way costs nothing and gives a three-lobed
        // margin and a two-ribbed blade, neither of which the garden had.
        foliage = Foliage(
            leavesPerNode: source.integer("foliage.leavesPerNode", 1...3),
            length: source.value("foliage.length", 0.055...0.28) * profile.leafLengthScale * form.vigour,
            widthRatio: source.value("foliage.widthRatio", 0.13...0.88) * profile.leafWidthScale,
            // Held to 1.15 rather than the 1.3 the rest of these took, because
            // droop is the one vegetative trait with a drawing limit rather
            // than a botanical one. `PlantBuilder.addLeaf` sags the blade along
            // its own frame's up-vector, and for a leaf held close to the stem
            // that vector points sideways — so a high droop on an upright leaf
            // kinks the blade out and back instead of bending it down. Drawn at
            // a ladder of values, a fern stops reading as a plant somewhere
            // past a droop of about 1.3 on a near-upright leaf that is long
            // against its own plant — all three at once — and the fern is the
            // only family whose multiplier could reach it.
            droop: source.bell("foliage.droop", 0...1.15) * profile.leafDroop,
            fold: source.value("foliage.fold", 0.02...0.62),
            pitch: source.value("foliage.pitch", 0.24...1.45),
            // Phyllotaxis: the golden angle, jittered a little per plant.
            divergence: 2.399963 + source.signed("foliage.divergence") * 0.22,
            serration: source.bell("foliage.serration", 0...1.3),
            teeth: source.integer("foliage.teeth", 3...17),
            veinCount: source.integer("foliage.veinCount", 2...9),
            veinDepth: source.chance("foliage.hasVeins", 0.72)
                ? source.bell("foliage.veinDepth", 0.2...1.0)
                : 0,
            tipSharpness: source.value("foliage.tipSharpness", 0.5...2.4)
        )

        // **The genus has a petal count; the plant does not draw one.** It used
        // to be `integer("bloom.petalCount", 3...13)` scaled per archetype,
        // which is a smear rather than a character — two plants of a genus were
        // as likely to differ as to agree, so no key could name it.
        //
        // A flora reads *petals 5, rarely 4 or 6*, and that is what this is: the
        // count belongs to the genus, and one plant in five carries the
        // variant. Without the variant a bed of one genus reads as printed
        // rather than grown; with more of it the count stops being diagnostic.
        let plan = merosity == .few ? profile.petals.few : profile.petals.many
        let variance = source.unit("bloom.petalVariant")
        let petalCount = max(3, plan + (variance < 0.1 ? -1 : variance > 0.9 ? 1 : 0))
        // Sized against the plant it sits on. A bloom that does not scale with
        // the stem reads as a speck on a tall plant rather than a small flower,
        // and the flower is the thing people are looking at.
        let bloomScale = 0.75 + 0.45 * min(1.6, height)
        let petalLength = source.value("bloom.length", 0.09...0.24) * profile.petalLengthScale * bloomScale
        bloom = Bloom(
            petalCount: petalCount,
            layers: source.integer("bloom.layers", 1...3),
            length: petalLength,
            widthRatio: source.value("bloom.widthRatio", 0.25...0.85) * profile.petalWidthScale,
            curl: (source.signed("bloom.curl") * 0.6 + profile.petalCurlBias).clamped(to: -1...1),
            twist: source.signed("bloom.twist") * 0.5,
            tipSharpness: source.value("bloom.tipSharpness", 0.6...2.4),
            headPitch: (source.bell("bloom.headPitch", 0...0.9) + profile.headPitchBias).clamped(to: 0...1.9),
            centreRadius: source.value("bloom.centreRadius", 0.1...0.32) * profile.centreScale,
            stamenCount: source.integer("bloom.stamenCount", 0...9),
            notch: source.chance("bloom.hasNotch", 0.3)
                ? source.value("bloom.notch", 0.35...1.0)
                : 0,
            sepalCount: source.chance("bloom.hasSepals", 0.7)
                ? source.integer("bloom.sepalCount", 3...6)
                : 0,
            hasPistil: source.chance("bloom.hasPistil", 0.75),
            atNodes: profile.bloomsAtNodes,
            present: source.unit("bloom.present") < profile.bloomPresence
        )

        palette = Palette.derive(from: source, seed: seed)

        tempo = Tempo(
            germinationHours: source.value("tempo.germinationHours", 3...20),
            seedlingDays: source.value("tempo.seedlingDays", 0.6...2.4),
            vegetativeDays: source.value("tempo.vegetativeDays", 2.0...7.0),
            buddingDays: source.value("tempo.buddingDays", 1.0...4.0),
            bloomDays: source.value("tempo.bloomDays", 3.0...12.0),
            opensByDay: source.chance("tempo.opensByDay", 0.7)
        )

        // Last, and reading what is above it rather than drawing alongside it.
        // docs/TAXONOMY.md §1: you name what you observe.
        name = PlantName(
            source: source,
            archetype: archetype,
            merosity: merosity,
            stem: stem,
            foliage: foliage,
            branching: branching,
            palette: palette,
            tempo: tempo,
            leafCount: stem.nodeCount * foliage.leavesPerNode
        )
    }
}

extension Genome {
    /// Convenience for a plant grown from an encounter.
    public static func hybrid(child: SeedID, parentA: SeedID, parentB: SeedID, encounterID: Data) -> Genome {
        let sorted = parentA < parentB ? (parentA, parentB) : (parentB, parentA)
        return Genome(
            seed: child,
            lineage: .crossed(parentA: sorted.0, parentB: sorted.1, encounterID: encounterID)
        )
    }
}

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }

    /// Wraps into `0..<1`, for hues that walk off either end of the wheel.
    var wrappedUnit: Double {
        let value = truncatingRemainder(dividingBy: 1.0)
        return value < 0 ? value + 1.0 : value
    }
}
