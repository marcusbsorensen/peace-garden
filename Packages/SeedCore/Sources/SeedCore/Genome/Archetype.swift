import Foundation

/// The broad shape a plant grows into.
///
/// Archetypes exist so that variation reads as *different kinds of plant*
/// rather than one plant with the sliders moved. Each one biases the trait
/// ranges through `ArchetypeProfile`; the seed still decides everything within
/// those bounds.
public enum Archetype: String, CaseIterable, Codable, Sendable {
    case spire      // tall, dense vertical raceme
    case umbel      // flat-topped cluster on fine stalks
    case fern       // no bloom to speak of; deep pinnate foliage
    case orchid     // few, large, asymmetric blooms
    case lotus      // broad cupped petals, heavy centre
    case thistle    // spiny bracts, tight globe head
    case vine       // long lax stem, small paired leaves
    case bell       // nodding tubular flowers
    case star       // flat radial bloom, sharp petals
    case poppy      // single crumpled bloom on a bare stem
    case succulent  // thick short stem, fleshy rosette
    case plume      // feathery many-branched inflorescence

    public var displayName: String {
        switch self {
        case .spire: return "Spire"
        case .umbel: return "Umbel"
        case .fern: return "Fern"
        case .orchid: return "Orchid"
        case .lotus: return "Lotus"
        case .thistle: return "Thistle"
        case .vine: return "Vine"
        case .bell: return "Bell"
        case .star: return "Star"
        case .poppy: return "Poppy"
        case .succulent: return "Succulent"
        case .plume: return "Plume"
        }
    }
}

/// How a plant carries its flowers, and therefore what shape it is.
///
/// Until this existed every archetype was one unbranched stem at different
/// proportions, which is why three plants side by side read as the same plant
/// three times — and why they all read as too tall. A tower spends its whole
/// budget on height because there is nowhere else to spend it.
///
/// Named `Inflorescence` rather than `Form`, which is what the build spec
/// called it, for two reasons. `Genome.Form` already exists and a bare `Form`
/// inside `Genome` would resolve to that one. And these three cases *are*
/// inflorescence types in the botany the rest of this file borrows its
/// vocabulary from, so the precise word costs nothing and says more.
public enum Inflorescence: String, CaseIterable, Sendable {
    /// Blooms on the axis: a single stem, flowers at the tip or up the nodes.
    ///
    /// What every plant was before the other two existed, unchanged, and still
    /// the commonest. It is named so that the other two read as choices rather
    /// than as exceptions.
    case raceme
    /// Stalks off the upper stem, a bloom on each.
    ///
    /// `branchSpread` carries the whole range between a flat-topped cluster and
    /// a feathery spray, which is worth having as a number rather than as two
    /// more cases — the two ends are the same construction differently tuned.
    case head
    /// A bare stem and one much larger bloom.
    ///
    /// Fewer blooms is what buys the size. A spire carries a dozen small
    /// flowers and cannot afford a large one; a poppy carries one and can
    /// afford nothing else. The plants should look like they cost the same.
    case solitary
}

/// Multipliers and overrides an archetype applies to the seed's raw draws.
public struct ArchetypeProfile: Sendable {
    public var heightScale: Double = 1
    public var stemThickness: Double = 1
    public var nodeScale: Double = 1
    public var leafLengthScale: Double = 1
    public var leafWidthScale: Double = 1
    public var leafDroop: Double = 1
    public var petalCountScale: Double = 1
    public var petalLengthScale: Double = 1
    public var petalWidthScale: Double = 1
    /// Negative curls cup the petals inward, positive reflex them back.
    public var petalCurlBias: Double = 0
    public var headPitchBias: Double = 0
    public var centreScale: Double = 1
    /// Flowers open at every node rather than only at the tip.
    ///
    /// Meaningful for `.raceme` alone. The other two forms decide where their
    /// flowers go from the form itself, and their profiles leave this be.
    public var bloomsAtNodes: Bool = false
    /// Fraction of blooms present at all — a fern gets almost none.
    public var bloomPresence: Double = 1
    public var swayScale: Double = 1

    public var inflorescence: Inflorescence = .raceme
    /// How large every bloom is drawn, against a raceme's.
    public var bloomScale: Double = 1
    /// Flat-topped at 0, an open spray at 1. `.head` only.
    public var branchSpread: Double = 0
    /// Before the seed's own draw scales it. `.head` only.
    public var branchCount: Int = 5

    public static func profile(for archetype: Archetype) -> ArchetypeProfile {
        var profile = ArchetypeProfile()
        switch archetype {
        case .spire:
            profile.heightScale = 1.35
            profile.nodeScale = 1.6
            profile.petalLengthScale = 0.55
            profile.petalCountScale = 0.7
            profile.bloomsAtNodes = true
            profile.leafLengthScale = 0.8
        case .umbel:
            profile.inflorescence = .head
            profile.branchSpread = 0
            profile.branchCount = 5
            profile.bloomScale = 0.8
            profile.heightScale = 0.9
            profile.petalLengthScale = 0.45
            profile.petalCountScale = 1.4
            profile.centreScale = 0.6
            profile.leafDroop = 1.2
        case .fern:
            profile.heightScale = 0.8
            profile.nodeScale = 1.9
            profile.leafLengthScale = 1.5
            profile.leafWidthScale = 0.7
            profile.leafDroop = 1.5
            profile.bloomPresence = 0.05
            profile.swayScale = 1.3
        case .orchid:
            profile.inflorescence = .solitary
            profile.bloomScale = 1.7
            profile.heightScale = 0.85
            profile.stemThickness = 0.8
            profile.nodeScale = 0.6
            profile.petalCountScale = 0.35
            profile.petalLengthScale = 1.0
            profile.petalWidthScale = 1.3
            profile.petalCurlBias = 0.25
            profile.headPitchBias = 0.5
            profile.leafLengthScale = 1.2
        case .lotus:
            profile.inflorescence = .solitary
            profile.bloomScale = 1.7
            profile.heightScale = 0.7
            profile.stemThickness = 1.4
            profile.petalLengthScale = 1.0
            profile.petalWidthScale = 1.5
            profile.petalCurlBias = -0.55
            profile.centreScale = 1.7
            profile.nodeScale = 0.5
        case .thistle:
            profile.inflorescence = .solitary
            profile.bloomScale = 2.4
            profile.heightScale = 0.9
            profile.nodeScale = 0.55
            profile.stemThickness = 1.2
            profile.petalCountScale = 2.2
            profile.petalLengthScale = 0.4
            profile.petalWidthScale = 0.3
            profile.petalCurlBias = -0.3
            profile.centreScale = 1.3
        case .vine:
            profile.heightScale = 1.45
            profile.stemThickness = 0.6
            profile.nodeScale = 1.7
            profile.leafLengthScale = 0.65
            profile.leafWidthScale = 1.1
            profile.swayScale = 1.8
            profile.bloomsAtNodes = true
            profile.petalLengthScale = 0.5
        case .bell:
            profile.petalCurlBias = -0.75
            profile.petalLengthScale = 1.1
            profile.headPitchBias = 1.0
            profile.petalCountScale = 0.55
            profile.bloomsAtNodes = true
        case .star:
            profile.petalCurlBias = 0.35
            profile.petalWidthScale = 0.6
            profile.centreScale = 0.7
            profile.petalCountScale = 0.9
        case .poppy:
            profile.inflorescence = .solitary
            profile.bloomScale = 1.7
            profile.heightScale = 0.75
            profile.nodeScale = 0.35
            profile.leafLengthScale = 0.7
            profile.petalCountScale = 0.3
            profile.petalLengthScale = 1.0
            profile.petalWidthScale = 1.6
            profile.petalCurlBias = -0.35
            profile.headPitchBias = 0.35
            profile.swayScale = 1.4
        case .succulent:
            profile.heightScale = 0.45
            profile.stemThickness = 1.9
            profile.nodeScale = 2.1
            profile.leafLengthScale = 0.55
            profile.leafWidthScale = 1.6
            profile.leafDroop = 0.3
            profile.petalLengthScale = 0.5
            profile.bloomPresence = 0.6
        case .plume:
            profile.inflorescence = .head
            profile.branchSpread = 1
            profile.branchCount = 7
            profile.bloomScale = 0.8
            profile.heightScale = 1.05
            profile.nodeScale = 1.8
            profile.petalCountScale = 1.8
            profile.petalLengthScale = 0.35
            profile.petalWidthScale = 0.35
            profile.leafLengthScale = 0.6
            profile.leafWidthScale = 0.4
        }
        return profile
    }
}
