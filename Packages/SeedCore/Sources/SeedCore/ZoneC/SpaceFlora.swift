#if os(WASI)
import FoundationEssentials
import WASILibc
#else
import Foundation
#endif

// Space flora: the plants a Zone C seed grows.
//
// **`peacegarden.space.v1` is a derivation of its own, pinned.** A space seed is
// 16 random bytes, `r`, that Autonaut drew; Peace Garden finds it as `r ‖ mark`.
// Everything about the plant — its kind and every trait — is drawn from `r` alone
// through `seedDigest`, so a draw from `r ‖ mark` is a draw from `r`, and a second
// implementation needs nothing but SHA-256 (no key, no CryptoKit, nothing the
// Linux and WebAssembly builds lack). `tools/reference/space_flora_reference.py`
// is that second implementation, and `tools/reference/space_flora_vectors.json`
// is what both of them, and Autonaut, are held to.
//
// **The plants are grown through Peace Garden's own morphology.** Each kind is
// built from one of its forms — the umbel, the reed, the vine, the succulent, the
// cushion — as a `Genome`, so `PlantBuilder` grows it with the refined 3D look the
// garden has, and both apps draw it with the same geometry.
//
// Draws are by name, as `GeneSource`'s are: every label starts `space.`, so
// nothing here can move an earthly plant, and a trait added later moves nothing
// already drawn.

public extension SeedDomain {
    /// Space flora. Versioned like every other tag: a change to the derivation is
    /// a `.v2`, never an edit to this one.
    static let space = "peacegarden.space.v1"
}

// MARK: - The kinds

/// A space plant's kind. The order is frozen: `space.kind` is sliced by
/// position, so a sixth kind added anywhere but the end would re-roll every
/// space plant's kind, as appending an archetype did to the garden's.
public enum SpaceKind: String, CaseIterable, Codable, Sendable {
    case cluster   // A  Star Cluster
    case comet     // B  Comet Reed
    case orbit     // C  Orbit Vine
    case crystal   // D  Crystal Rosette
    case nebula    // E  Nebula Moss

    /// The letter Marcus chose them by, 17 October 2026.
    public var letter: String {
        switch self {
        case .cluster: return "A"
        case .comet: return "B"
        case .orbit: return "C"
        case .crystal: return "D"
        case .nebula: return "E"
        }
    }

    /// The name in English. Two plain nouns, a thing in space and a kind of
    /// plant, so each translates word for word.
    public var displayName: String {
        switch self {
        case .cluster: return "Star Cluster"
        case .comet: return "Comet Reed"
        case .orbit: return "Orbit Vine"
        case .crystal: return "Crystal Rosette"
        case .nebula: return "Nebula Moss"
        }
    }

    /// The Peace Garden form this kind is grown from.
    public var form: Archetype {
        switch self {
        case .cluster: return .umbel
        case .comet: return .reed
        case .orbit: return .vine
        case .crystal: return .succulent
        case .nebula: return .cushion
        }
    }

    /// The kind's own line, in English, and in English in every language.
    public var quotation: String {
        switch self {
        case .cluster:
            return "A mass of innumerable stars planted together in clusters."
        case .comet:
            return "I'll tell you how the sun rose, \u{2014} / A ribbon at a time."
        case .orbit:
            return "Zero-g and I feel fine."
        case .crystal:
            return "It has a stark beauty all its own."
        case .nebula:
            return "they look like little stars. A whole shower of them coming by."
        }
    }

    /// Whose line it is and where it is from.
    public var source: String {
        switch self {
        case .cluster:
            return "Galileo Galilei, Sidereus Nuncius (1610), tr. Edward Stafford Carlos, "
                + "The Sidereal Messenger (1880)"
        case .comet:
            return "Emily Dickinson, \"A Day\", Poems (First Series, 1890)"
        case .orbit:
            return "John Glenn, Friendship 7, 20 February 1962"
        case .crystal:
            return "Neil Armstrong, Apollo 11, 20 July 1969"
        case .nebula:
            return "John Glenn, Friendship 7, 20 February 1962"
        }
    }

    /// Read from a space seed's 16 bytes: the same slice of one named draw in
    /// every host.
    static func drawn(from unit: Double) -> SpaceKind {
        let all = allCases
        return all[min(all.count - 1, Int(unit * Double(all.count)))]
    }
}

// MARK: - What each kind is allowed to be

/// Ranges rather than multipliers: the derivation is new and versioned, so each
/// kind says its own bounds outright. Lengths in metres, angles in radians, hues
/// in `0...1`, the same units as `Genome`.
///
/// Where a trait scales with the plant, the range is the draw and `vigour` is
/// the plant: height and leaf length are the drawn value times it, as a
/// garden plant's are.
public struct SpaceFloraProfile: Sendable {
    // form
    /// The two counts the kind's flower is built in, low and high. One plant in
    /// five takes the variant, a petal fewer or more.
    public var petals: (few: Int, many: Int)
    /// Bell-drawn; scales height and leaf.
    public var vigour: ClosedRange<Double>

    // branching
    public var inflorescence: Inflorescence
    public var branchCount: ClosedRange<Int> = 0...0
    public var branchSpread: ClosedRange<Double> = 0...0
    public var branchAngle: ClosedRange<Double> = 0...0
    public var bloomScale: Double

    // stem
    public var height: ClosedRange<Double>
    public var baseRadius: ClosedRange<Double>
    public var taper: ClosedRange<Double>
    /// Magnitude; `space.stem.leanSide` picks the side.
    public var lean: ClosedRange<Double>
    /// Bell-drawn.
    public var sway: ClosedRange<Double>
    /// Magnitude; `space.stem.twistSide` picks the hand.
    public var twist: ClosedRange<Double>
    public var nodeCount: ClosedRange<Int>
    /// Where the nodes sit, as fractions of the stem. Placed, not drawn.
    public var nodeZone: ClosedRange<Double>

    // foliage
    public var leavesPerNode: ClosedRange<Int>
    public var leafLength: ClosedRange<Double>
    public var leafWidthRatio: ClosedRange<Double>
    /// Bell-drawn.
    public var droop: ClosedRange<Double>
    public var fold: ClosedRange<Double>
    public var pitch: ClosedRange<Double>
    public var veinCount: ClosedRange<Int>
    public var leafTip: ClosedRange<Double>
    /// How far a stem leaf's size follows the stem's height.
    public var leafReach: Double = 0.55

    // habit
    public var rosette: Bool = false
    public var crownLeaves: ClosedRange<Int> = 0...0
    public var crownPitch: ClosedRange<Double> = 0...0
    public var crownRise: Double = 0.55
    public var crownTaper: Double = 0.5
    public var crownLengthScale: Double = 1
    public var fleshiness: Double = 0
    public var strap: Bool = false
    public var cushion: Bool = false
    /// Nebula Moss: the dome's width across, in metres.
    public var cushionWidth: ClosedRange<Double> = 0...0
    /// Comet Reed: the share of each crown leaf's bearing pulled round to the
    /// side the culm leans toward.
    public var sweep: ClosedRange<Double> = 0...0
    /// Orbit Vine: the turns the stem makes round its own axis.
    public var orbit: ClosedRange<Double> = 0...0

    // bloom
    /// A flower at every node above a third of the way up, the lowest largest
    /// and first to open.
    public var bloomsAtNodes: Bool = false
    public var layers: ClosedRange<Int>
    public var petalLength: ClosedRange<Double>
    public var petalWidthRatio: ClosedRange<Double>
    /// Negative cups, positive reflexes.
    public var curl: ClosedRange<Double>
    public var petalTwist: ClosedRange<Double>
    public var headPitch: ClosedRange<Double>
    public var centreRadius: ClosedRange<Double>
    public var stamens: ClosedRange<Int>
    public var sepals: Sepals
    public var calyx: Calyx
    public var outline: PetalOutline
    public var bloomPresence: Double
    /// Nebula Moss: the share of its rosettes that flower.
    public var flowerShare: ClosedRange<Double> = 0...0

    // palette
    /// Calm schemes only: never complementary, split or bicolour.
    public var schemes: [ColourScheme]
    public var petalHue: ClosedRange<Double>
    public var petalSaturation: ClosedRange<Double>
    public var petalBrightness: ClosedRange<Double>
    /// 97 to 119 degrees, low saturation: Peace Garden's own sage to moss, for
    /// every kind.
    public var leafHue: ClosedRange<Double> = 0.27...0.33
    public var leafSaturation: ClosedRange<Double> = 0.10...0.22
    public var leafBrightness: ClosedRange<Double> = 0.70...0.86
    /// Bell-drawn.
    public var glow: ClosedRange<Double>
}

public extension SpaceFloraProfile {
    static func profile(for kind: SpaceKind) -> SpaceFloraProfile {
        switch kind {
        case .cluster:   // A: from the umbel and the plume
            return SpaceFloraProfile(
                petals: (6, 9), vigour: 0.8...1.2,
                inflorescence: .head, branchCount: 5...9, branchSpread: 0.25...0.75,
                branchAngle: 0.9...1.3, bloomScale: 0.7,
                height: 0.45...0.95, baseRadius: 0.005...0.012, taper: 0.3...0.7, lean: 0...0.35,
                sway: 0.2...0.9, twist: 0...0.4,
                nodeCount: 2...5, nodeZone: 0.12...0.6,
                leavesPerNode: 1...2, leafLength: 0.06...0.16, leafWidthRatio: 0.12...0.3,
                droop: 0.3...0.9, fold: 0.1...0.4, pitch: 0.6...1.1, veinCount: 0...2, leafTip: 1.2...2.0,
                crownLeaves: 2...4, crownPitch: 0.45...0.8, crownRise: 0.4, crownTaper: 0.5,
                crownLengthScale: 1.4,
                layers: 1...1, petalLength: 0.025...0.05, petalWidthRatio: 0.2...0.4, curl: 0.1...0.4,
                petalTwist: -0.2...0.2, headPitch: 0...0.3, centreRadius: 0.15...0.3, stamens: 3...6,
                sepals: .none, calyx: .lid, outline: .pointed, bloomPresence: 1,
                schemes: [.monochrome, .ombre], petalHue: 0.155...0.183,
                petalSaturation: 0.25...0.55, petalBrightness: 0.88...1.0,
                glow: 0.5...0.9)
        case .comet:     // B: from the reed
            return SpaceFloraProfile(
                petals: (6, 12), vigour: 0.85...1.25,
                inflorescence: .solitary, bloomScale: 1.3,
                height: 0.6...1.2, baseRadius: 0.004...0.009, taper: 0.5...0.85, lean: 0.45...0.75,
                sway: 0.4...1.0, twist: 0...0.2,
                nodeCount: 1...2, nodeZone: 0.1...0.3,
                leavesPerNode: 1...1, leafLength: 0.3...0.6, leafWidthRatio: 0.03...0.07,
                droop: 0.6...1.1, fold: 0.05...0.3, pitch: 0.2...0.5, veinCount: 0...0, leafTip: 1.6...2.4,
                rosette: true, crownLeaves: 7...12, crownPitch: 0.15...0.55, crownRise: 0.5,
                crownTaper: 0.35, crownLengthScale: 1.5, strap: true, sweep: 0.55...0.85,
                layers: 2...3, petalLength: 0.03...0.06, petalWidthRatio: 0.5...0.8, curl: -0.7...(-0.4),
                petalTwist: -0.3...0.3, headPitch: 0.6...1.1, centreRadius: 0.25...0.4, stamens: 0...0,
                sepals: .none, calyx: .swelling, outline: .rounded, bloomPresence: 1,
                schemes: [.ombre, .monochrome], petalHue: 0.545...0.576,
                petalSaturation: 0.2...0.45, petalBrightness: 0.92...1.0,
                glow: 0.6...1.0)
        case .orbit:     // C: from the vine
            return SpaceFloraProfile(
                petals: (6, 8), vigour: 0.85...1.3,
                inflorescence: .raceme, bloomScale: 0.8,
                height: 0.9...1.6, baseRadius: 0.003...0.007, taper: 0.2...0.6, lean: 0...0.3,
                sway: 0.9...1.6, twist: 0.55...0.95,
                nodeCount: 6...12, nodeZone: 0.2...0.95,
                leavesPerNode: 1...1, leafLength: 0.06...0.12, leafWidthRatio: 0.7...0.95,
                droop: 0.2...0.6, fold: 0.1...0.3, pitch: 0.9...1.3, veinCount: 2...4, leafTip: 0.5...0.9,
                crownLeaves: 0...2, crownPitch: 0.9...1.2, crownLengthScale: 1.3, orbit: 1.5...3.0,
                bloomsAtNodes: true,
                layers: 1...1, petalLength: 0.02...0.04, petalWidthRatio: 0.6...0.85, curl: -0.6...(-0.3),
                petalTwist: -0.2...0.2, headPitch: 0.2...0.6, centreRadius: 0.2...0.35, stamens: 0...3,
                sepals: .appressed, calyx: .cup, outline: .rounded, bloomPresence: 1,
                schemes: [.analogous, .monochrome], petalHue: 0.74...0.80,
                petalSaturation: 0.3...0.55, petalBrightness: 0.85...1.0,
                glow: 0.4...0.8)
        case .crystal:   // D: from the succulent
            return SpaceFloraProfile(
                petals: (6, 12), vigour: 0.8...1.2,
                inflorescence: .raceme, bloomScale: 1.0,
                height: 0.12...0.3, baseRadius: 0.006...0.012, taper: 0.3...0.7, lean: 0...0.2,
                sway: 0.1...0.4, twist: 0...0.3,
                nodeCount: 7...13, nodeZone: 0...0,
                leavesPerNode: 1...1, leafLength: 0.1...0.2, leafWidthRatio: 0.3...0.5,
                droop: 0...0.15, fold: 0.3...0.6, pitch: 0.3...0.75, veinCount: 1...1, leafTip: 1.8...2.4,
                rosette: true, crownLeaves: 2...4, crownPitch: 0.3...0.75, crownRise: 0.5,
                crownTaper: 0.45, crownLengthScale: 1, fleshiness: 1,
                layers: 1...2, petalLength: 0.03...0.06, petalWidthRatio: 0.25...0.45, curl: 0...0.3,
                petalTwist: -0.2...0.2, headPitch: 0...0.4, centreRadius: 0.12...0.22, stamens: 0...4,
                sepals: .none, calyx: .cup, outline: .pointed, bloomPresence: 0.6,
                schemes: [.analogous, .monochrome], petalHue: 0.62...0.68,
                petalSaturation: 0.3...0.55, petalBrightness: 0.88...1.0,
                leafSaturation: 0.06...0.16, leafBrightness: 0.78...0.92,
                glow: 0.4...0.8)
        case .nebula:    // E: from the cushion
            return SpaceFloraProfile(
                petals: (6, 9), vigour: 0.8...1.25,
                inflorescence: .raceme, bloomScale: 0.5,
                height: 0.08...0.16, baseRadius: 0.004...0.008, taper: 0...0, lean: 0...0.15,
                sway: 0...0.2, twist: 0...0,
                nodeCount: 18...34, nodeZone: 0...0,
                leavesPerNode: 5...7, leafLength: 0.012...0.025, leafWidthRatio: 0.3...0.6,
                droop: 0...0.3, fold: 0...0.2, pitch: 0.3...0.7, veinCount: 0...0, leafTip: 0.8...1.4,
                rosette: true, fleshiness: 0.6, cushion: true, cushionWidth: 0.2...0.38,
                layers: 1...1, petalLength: 0.008...0.016, petalWidthRatio: 0.4...0.7, curl: 0...0.3,
                petalTwist: -0.2...0.2, headPitch: 0...0.3, centreRadius: 0.25...0.4, stamens: 0...0,
                sepals: .none, calyx: .lid, outline: .rounded, bloomPresence: 1,
                flowerShare: 0.25...0.45,
                schemes: [.ombre, .analogous], petalHue: 0.845...0.90,
                petalSaturation: 0.28...0.5, petalBrightness: 0.88...1.0,
                glow: 0.6...1.0)
        }
    }
}

// MARK: - The draw

/// Draws trait values out of a space seed's 16 bytes, by name.
///
/// `GeneSource`'s twin: the same calls (`value`, `bell`, `integer`, `chance`,
/// `pick`, `signed`) over a different key and a different domain. A hybrid
/// carries its two parents, already sorted, and draws every named trait on the
/// 36/36/22/6 ladder `GeneSource` does.
struct SpaceGenes: Sendable {
    /// A space seed is read by its first 16 bytes, whatever follows them: for a
    /// found seed that is `r`, and the mark after it is never read.
    static let keyLength = 16

    /// The 16 bytes the child, or the plant itself, is drawn from.
    let key: Data
    /// Present for hybrids: each parent's 16 bytes, sorted so that both phones
    /// label them the same way round.
    let parents: (Data, Data)?

    static func primary(key: Data) -> SpaceGenes {
        SpaceGenes(key: Self.leading(key), parents: nil)
    }

    /// The parents arrive already sorted, by the caller, on their whole seeds.
    static func hybrid(child: Data, first: Data, second: Data) -> SpaceGenes {
        SpaceGenes(key: Self.leading(child), parents: (Self.leading(first), Self.leading(second)))
    }

    static func leading(_ bytes: Data) -> Data {
        Data(bytes.prefix(keyLength))
    }

    /// Uniform in `[0, 1)` for the named trait.
    func unit(_ label: String) -> Double {
        guard let parents else {
            return Self.rawUnit(key, label)
        }
        let roll = Self.rawUnit(key, "inherit:" + label)
        if roll < GeneSource.inheritFirstParent {
            return Self.rawUnit(parents.0, label)
        }
        if roll < GeneSource.inheritSecondParent {
            return Self.rawUnit(parents.1, label)
        }
        if roll < GeneSource.inheritBlend {
            let first = Self.rawUnit(parents.0, label)
            let second = Self.rawUnit(parents.1, label)
            return first + (second - first) * Self.rawUnit(key, "blend:" + label)
        }
        return Self.rawUnit(key, "mutate:" + label)
    }

    static func rawUInt64(_ key: Data, _ label: String) -> UInt64 {
        mix64(seedDigest(SeedDomain.space, key, Data(label.utf8)).leadingUInt64)
    }

    static func rawUnit(_ key: Data, _ label: String) -> Double {
        Double(rawUInt64(key, label) >> 11) * 0x1.0p-53
    }

    func value(_ label: String, _ range: ClosedRange<Double>) -> Double {
        range.lowerBound + unit(label) * (range.upperBound - range.lowerBound)
    }

    func integer(_ label: String, _ range: ClosedRange<Int>) -> Int {
        let span = range.upperBound - range.lowerBound + 1
        let offset = min(span - 1, Int(unit(label) * Double(span)))
        return range.lowerBound + offset
    }

    func chance(_ label: String, _ probability: Double) -> Bool {
        unit(label) < probability
    }

    func pick<Element>(_ label: String, from options: [Element]) -> Element {
        options[min(options.count - 1, Int(unit(label) * Double(options.count)))]
    }

    func bell(_ label: String, _ range: ClosedRange<Double>) -> Double {
        let sum = unit(label + ".a") + unit(label + ".b") + unit(label + ".c")
        return range.lowerBound + (sum / 3.0) * (range.upperBound - range.lowerBound)
    }

    func signed(_ label: String) -> Double {
        unit(label) * 2.0 - 1.0
    }
}

// MARK: - The plant

/// A space plant: its kind, and the genome `PlantBuilder` grows it from.
public struct SpaceFlora: Equatable, Sendable {
    public let kind: SpaceKind
    /// The 16 bytes it was drawn from. For a found seed, `r`.
    public let key: Data
    /// For a cross of two kinds, the other one: the colour of the small point in
    /// every flower's centre. `nil` when the child is of every parent's kind.
    public let centreKind: SpaceKind?
    /// What `PlantBuilder` and `GrowthModel` take.
    public let genome: Genome

    /// The kind's name, in English.
    public var name: String { kind.displayName }

    /// The plant `r` grows. `r` is exactly 16 bytes; any other length is not a
    /// space seed and returns `nil`.
    public static func draw(r: Data) -> SpaceFlora? {
        guard r.count == SpaceGenes.keyLength else { return nil }
        return SpaceFlora(genes: .primary(key: r), lineage: .minted)
    }

    /// The plant a seed grows, read by its first 16 bytes: `r ‖ mark` grows what
    /// `r` does.
    public static func draw(seed: SeedID) -> SpaceFlora {
        SpaceFlora(genes: .primary(key: seed.bytes), lineage: .minted)
    }

    /// Builds the plant from a draw source. A hybrid's kind is inherited from
    /// its parents' on the same ladder as every trait (`SpaceFloraHybrid`); a
    /// plant that is nobody's child draws its own.
    init(genes: SpaceGenes, lineage: Lineage) {
        let kind: SpaceKind
        var centreKind: SpaceKind?
        if let parents = genes.parents {
            let kinds = (Self.kind(of: parents.0), Self.kind(of: parents.1))
            kind = Self.inheritedKind(genes: genes, parentKinds: kinds)
            // One small point of the other parent in every flower.
            centreKind = kinds.0 != kind ? kinds.0 : (kinds.1 != kind ? kinds.1 : nil)
        } else {
            kind = Self.kind(of: genes.key)
        }
        self.kind = kind
        self.key = genes.key
        self.centreKind = centreKind
        self.genome = Genome(space: kind, genes: genes, lineage: lineage, centreKind: centreKind)
    }

    /// The kind the 16 bytes `key` draw, as a plant that is nobody's child.
    static func kind(of key: Data) -> SpaceKind {
        SpaceKind.drawn(from: SpaceGenes.rawUnit(key, "space.kind"))
    }
}

// MARK: - Into a genome

extension Genome {
    /// A space plant as the garden's own morphology grows it.
    ///
    /// Its `seed` is derived from the plant's 16 bytes under the space domain,
    /// so the incidental jitter inside the mesh — a leaf's azimuth, a petal's
    /// phase — is a function of `r` and nothing else, and a draw from `r ‖ mark`
    /// grows the same mesh vertex for vertex.
    init(space kind: SpaceKind, genes g: SpaceGenes, lineage: Lineage, centreKind: SpaceKind?) {
        let p = SpaceFloraProfile.profile(for: kind)
        let seed = SeedID(digest: seedDigest(SeedDomain.space, g.key, Data("space.seed".utf8)))

        // The floral facts first, as `Genome` reads them. Whether the plant
        // flowers and how long its leaves are decide how tall a rosette stands,
        // so they are read ahead of the stem; a name gives the same value
        // however often it is read.
        let merosity: Merosity = g.chance("space.bloom.merosity", 0.5) ? .many : .few
        let vigour = g.bell("space.form.vigour", p.vigour)
        let flowers = g.chance("space.bloom.present", p.bloomPresence)

        let leafLength = g.value("space.foliage.length", p.leafLength) * vigour
        let typicalLength = (p.leafLength.lowerBound + p.leafLength.upperBound) * 0.5 * vigour
        let rosetteLength = p.crownLengthScale * (leafLength * 0.6 + typicalLength * 0.4)
        let drawnHeight = g.value("space.stem.height", p.height) * vigour
        // A rosette that does not flower sends up no stalk: only the crown the
        // leaves come from, and a few centimetres of stub.
        let height = p.rosette && !flowers ? 0.08 + drawnHeight * 0.25 : drawnHeight

        let form = Form(archetype: kind.form, merosity: merosity, vigour: vigour)

        let branching = Branching(
            inflorescence: p.inflorescence,
            count: g.integer("space.branch.count", p.branchCount),
            spread: g.value("space.branch.spread", p.branchSpread).clamped(to: 0...1),
            angle: g.value("space.branch.angle", p.branchAngle),
            bloomScale: p.bloomScale
        )

        let leanMagnitude = g.value("space.stem.lean", p.lean)
        let twistMagnitude = g.value("space.stem.twist", p.twist)
        let stem = Stem(
            height: height,
            baseRadius: g.value("space.stem.baseRadius", p.baseRadius),
            taper: g.value("space.stem.taper", p.taper),
            lean: g.chance("space.stem.leanSide", 0.5) ? leanMagnitude : -leanMagnitude,
            sway: g.bell("space.stem.sway", p.sway),
            twist: g.chance("space.stem.twistSide", 0.5) ? twistMagnitude : -twistMagnitude,
            nodeCount: g.integer("space.stem.nodeCount", p.nodeCount),
            sides: g.integer("space.stem.sides", 6...9)
        )

        let veinCount = g.integer("space.foliage.veinCount", p.veinCount)
        let foliage = Foliage(
            leavesPerNode: g.integer("space.foliage.leavesPerNode", p.leavesPerNode),
            length: leafLength,
            widthRatio: g.value("space.foliage.widthRatio", p.leafWidthRatio),
            droop: g.bell("space.foliage.droop", p.droop),
            fold: g.value("space.foliage.fold", p.fold),
            pitch: g.value("space.foliage.pitch", p.pitch),
            // Phyllotaxis: the golden angle, jittered a little per plant.
            divergence: 2.399963 + g.signed("space.foliage.divergence") * 0.22,
            // No space flora is toothed.
            serration: 0,
            teeth: 0,
            veinCount: veinCount,
            veinDepth: veinCount > 0 ? g.bell("space.foliage.veinDepth", 0.25...0.9) : 0,
            tipSharpness: g.value("space.foliage.tipSharpness", p.leafTip)
        )

        let reach = p.leafReach
        let stemLeafScale = (1 - reach) + reach * min(1.5, max(0.4, height / 0.9))
        let crownCount = (p.rosette ? stem.nodeCount * foliage.leavesPerNode : 0)
            + g.integer("space.habit.crownLeaves", p.crownLeaves)
        let habit = Habit(
            rosette: p.rosette,
            crownCount: crownCount,
            crownLength: p.rosette
                ? rosetteLength
                : min(0.6, p.crownLengthScale * foliage.length * stemLeafScale),
            crownPitch: g.value("space.habit.crownPitch", p.crownPitch),
            crownTaper: p.crownTaper,
            crownRise: p.crownRise,
            pads: false,
            fleshiness: p.fleshiness,
            pinnae: 0,
            stemLeafScale: stemLeafScale,
            nodeZone: p.nodeZone,
            strap: p.strap,
            cushion: p.cushion,
            sweep: g.value("space.habit.sweep", p.sweep),
            orbit: g.value("space.habit.orbit", p.orbit),
            cushionWidth: p.cushion ? g.value("space.habit.cushionWidth", p.cushionWidth) : nil,
            flowerShare: p.cushion ? g.value("space.bloom.flowerShare", p.flowerShare) : 0.45
        )

        // **The kind has a petal count; the plant does not draw one.** One plant
        // in five carries the variant, a petal fewer or more, as `Genome` has it.
        // Every plan is six or more, so the variant never makes a four-petalled
        // flower, which drawn in a monoline reads as a cross.
        let plan = merosity == .few ? p.petals.few : p.petals.many
        let variance = g.unit("space.bloom.petalVariant")
        let petalCount = max(3, plan + (variance < 0.1 ? -1 : variance > 0.9 ? 1 : 0))
        let stamenCount = g.integer("space.bloom.stamenCount", p.stamens)
        let bloom = Bloom(
            petalCount: petalCount,
            layers: g.integer("space.bloom.layers", p.layers),
            length: g.value("space.bloom.length", p.petalLength),
            widthRatio: g.value("space.bloom.widthRatio", p.petalWidthRatio),
            curl: g.value("space.bloom.curl", p.curl),
            twist: g.value("space.bloom.twist", p.petalTwist),
            tipSharpness: g.value("space.bloom.tipSharpness", 0.6...2.4),
            headPitch: g.value("space.bloom.headPitch", p.headPitch),
            centreRadius: g.value("space.bloom.centreRadius", p.centreRadius),
            stamenCount: stamenCount,
            notch: 0,
            sepalCount: p.sepals == .none ? 0 : g.integer("space.bloom.sepalCount", 4...6),
            hasPistil: stamenCount > 0 && g.chance("space.bloom.hasPistil", 0.6),
            atNodes: p.bloomsAtNodes,
            opensFromBelow: p.bloomsAtNodes,
            present: flowers,
            calyx: p.calyx,
            sepals: p.sepals,
            outline: p.outline,
            crumple: 0
        )

        let palette = SpacePalette.derive(from: g, profile: p, seed: seed, centreKind: centreKind)

        let tempo = Tempo(
            germinationHours: g.value("space.tempo.germinationHours", 6...24),
            seedlingDays: g.value("space.tempo.seedlingDays", 1...3),
            vegetativeDays: g.value("space.tempo.vegetativeDays", 3...8),
            buddingDays: g.value("space.tempo.buddingDays", 2...5),
            bloomDays: g.value("space.tempo.bloomDays", 10...30),
            // Deep space has no day.
            opensByDay: false
        )

        // The kind's name is the plant's: two plain nouns.
        let words = kind.displayName.split(separator: " ").map(String.init)
        let name = PlantName(genus: words[0], epithet: words.count > 1 ? words[1] : "")

        self.init(
            seed: seed, lineage: lineage, form: form, branching: branching, stem: stem,
            foliage: foliage, habit: habit, bloom: bloom, palette: palette, tempo: tempo,
            name: name
        )
    }

    /// A genome from its parts, for the plants that are not drawn by
    /// `Genome.init(seed:lineage:)`. Whoever calls it owns the guarantee that
    /// the parts are one plant's.
    init(
        seed: SeedID, lineage: Lineage, form: Form, branching: Branching, stem: Stem,
        foliage: Foliage, habit: Habit, bloom: Bloom, palette: Palette, tempo: Tempo,
        name: PlantName
    ) {
        self.seed = seed
        self.lineage = lineage
        self.form = form
        self.branching = branching
        self.stem = stem
        self.foliage = foliage
        self.habit = habit
        self.bloom = bloom
        self.palette = palette
        self.tempo = tempo
        self.name = name
    }

    /// The same plant with another habit. For the tests of the four traits a
    /// space plant adds, which hold a plant up against itself with the trait
    /// taken away.
    func replacing(habit: Habit) -> Genome {
        Genome(
            seed: seed, lineage: lineage, form: form, branching: branching, stem: stem,
            foliage: foliage, habit: habit, bloom: bloom, palette: palette, tempo: tempo,
            name: name
        )
    }
}

// MARK: - Colour

/// A space plant's colours: `Palette.derive`'s rules, cut down to the calm
/// schemes the kind lists and held to its own bands.
///
/// **The petals are the kind's colour and the leaves are the garden's.** Every
/// kind's leaves and stems (and the veins in them) sit in Peace Garden's sage to
/// moss, held there by a clamp on the hue, so a space plant beside an earthly one
/// reads as a relative; the flower carries the kind's own hue. Marbling, picotee and variegation are off for every kind, so nothing
/// loud enters.
enum SpacePalette {
    static func derive(
        from g: SpaceGenes,
        profile p: SpaceFloraProfile,
        seed: SeedID,
        centreKind: SpaceKind?
    ) -> Genome.Palette {
        let scheme = g.pick("space.palette.scheme", from: p.schemes)

        let baseHue = g.value("space.palette.petalHue", p.petalHue)
        let baseSaturation = g.value("space.palette.petalSaturation", p.petalSaturation)
        let baseBrightness = g.value("space.palette.petalBrightness", p.petalBrightness)
        let direction: Double = g.chance("space.palette.hueDirection", 0.5) ? 1 : -1

        var tipHue = baseHue
        var tipSaturation = baseSaturation
        var tipBrightness = baseBrightness

        switch scheme {
        case .analogous:
            // A narrower shift than the garden's 0.04 to 0.11: the tip stays in
            // the kind's own colour.
            tipHue = baseHue + direction * g.value("space.palette.tipShift", 0.02...0.06)
            tipSaturation = baseSaturation * g.value("space.palette.tipSaturation", 0.7...1.1)
            tipBrightness = baseBrightness * g.value("space.palette.tipBrightness", 0.95...1.25)
        case .ombre:
            tipSaturation = baseSaturation * g.value("space.palette.tipSaturation", 0.08...0.35)
            tipBrightness = min(1.0, baseBrightness * g.value("space.palette.tipBrightness", 1.15...1.5))
        default:
            // Monochrome, the only other scheme a kind lists.
            tipSaturation = baseSaturation * g.value("space.palette.tipSaturation", 0.45...1.1)
            tipBrightness = baseBrightness * g.value("space.palette.tipBrightness", 1.0...1.35)
        }

        let petalBase = HSB(
            hue: baseHue.wrappedUnit,
            saturation: baseSaturation.clamped(to: 0...1),
            brightness: (baseBrightness * 0.82).clamped(to: 0...1)
        )
        let petalTip = HSB(
            hue: tipHue.wrappedUnit,
            saturation: tipSaturation.clamped(to: 0...1),
            brightness: tipBrightness.clamped(to: 0...1)
        )

        // Deeper and a touch warmer than the petal, never a different colour.
        let petalThroat = HSB(
            hue: (baseHue + g.signed("space.palette.throatShift") * 0.03).wrappedUnit,
            saturation: min(1, baseSaturation * g.value("space.palette.throatSaturation", 0.9...1.5) + 0.1),
            brightness: (baseBrightness * g.value("space.palette.throatBrightness", 0.5...0.95)).clamped(to: 0...1)
        )
        let petalVein = HSB(
            hue: (baseHue + g.signed("space.palette.veinShift") * 0.02).wrappedUnit,
            saturation: min(1, baseSaturation * 1.25 + 0.08),
            brightness: (baseBrightness * g.value("space.palette.veinBrightness", 0.35...0.7)).clamped(to: 0...1)
        )
        let veining = g.chance("space.palette.hasVeins", 0.45)
            ? g.bell("space.palette.veining", 0.15...0.75)
            : 0

        let leaf = HSB(
            hue: g.value("space.palette.leafHue", p.leafHue),
            saturation: g.value("space.palette.leafSaturation", p.leafSaturation),
            brightness: g.value("space.palette.leafBrightness", p.leafBrightness)
        )
        // Only read where a leaf is variegated, and none is; kept as a plain
        // lighter tint of the leaf so the field is never a stranger.
        let leafAccent = HSB(
            hue: leaf.hue,
            saturation: leaf.saturation * 0.3,
            brightness: min(1, leaf.brightness * 1.5)
        )
        let leafVein = HSB(
            hue: (leaf.hue + g.signed("space.palette.leafVeinShift") * 0.02).clamped(to: p.leafHue),
            saturation: min(1, leaf.saturation * g.value("space.palette.leafVeinSaturation", 1.05...1.45)),
            brightness: (leaf.brightness * g.value("space.palette.leafVeinBrightness", 0.52...0.86)).clamped(to: 0...1)
        )
        let leafVeining = g.chance("space.palette.hasLeafVeins", 0.88)
            ? g.bell("space.palette.leafVeining", 0.25...0.9)
            : 0
        let stem = HSB(
            hue: (leaf.hue + g.signed("space.palette.stemShift") * 0.03).clamped(to: p.leafHue),
            saturation: (leaf.saturation * g.value("space.palette.stemSaturation", 0.6...1.1)).clamped(to: 0...1),
            brightness: (leaf.brightness * g.value("space.palette.stemBrightness", 0.62...1.0)).clamped(to: 0...1)
        )

        // **One small point of the other parent in every flower.** The heart of
        // a flower takes its hue from the kind's own band, or, in a cross of two
        // kinds, from the other kind's.
        let centreBand = (centreKind.map { SpaceFloraProfile.profile(for: $0) } ?? p).petalHue
        let centre = HSB(
            hue: g.value("space.palette.centreHue", centreBand),
            saturation: g.value("space.palette.centreSaturation", 0.35...0.7),
            brightness: g.value("space.palette.centreBrightness", 0.85...1.0)
        )

        return Genome.Palette(
            scheme: scheme,
            petalBase: petalBase,
            petalTip: petalTip,
            petalThroat: petalThroat,
            petalVein: petalVein,
            picotee: nil,
            veining: veining,
            marbling: .none,
            marble: petalBase,
            marbleScale: 3,
            marbleSeed: SpaceGenes.rawUInt64(g.key, "space.palette.marbleSeed"),
            foliageTone: .green,
            leaf: leaf,
            variegation: .none,
            leafAccent: leafAccent,
            leafVein: leafVein,
            leafVeining: leafVeining,
            leafQuilting: g.bell("space.palette.leafQuilting", 0.05...0.5),
            stem: stem,
            centre: centre,
            glow: g.bell("space.palette.glow", p.glow),
            sheen: g.value("space.palette.sheen", 0.05...0.65),
            speckleSeed: SpaceGenes.rawUInt64(g.key, "space.palette.speckleSeed")
        )
    }
}
