import Foundation

/// How a plant's two petal colours relate to each other.
///
/// Drawing both hues at random gives variety but not beauty — most pairs of
/// random hues fight. Picking a relationship first and deriving the second hue
/// from the first gives the same range of colour with a reason behind it, the
/// way a real flower's throat and margin belong to each other.
public enum ColourScheme: String, CaseIterable, Codable, Sendable {
    /// One hue, moving in saturation and brightness only.
    case monochrome
    /// Neighbours on the wheel: coral into rose, butter into apricot.
    case analogous
    /// Opposites, held apart: violet petals, a yellow throat.
    case complementary
    /// Opposite-ish, softer than the full complement.
    case split
    /// Two clearly separate colours, as a bicolour tulip has.
    case bicolour
    /// The base hue draining toward white or deepening toward black.
    case ombre

    public var displayName: String {
        switch self {
        case .monochrome: return "Monochrome"
        case .analogous: return "Analogous"
        case .complementary: return "Complementary"
        case .split: return "Split"
        case .bicolour: return "Bicolour"
        case .ombre: return "Ombré"
        }
    }
}

/// The colour a plant's leaves take.
///
/// Most plants are green. The rest are why anyone collects them.
public enum FoliageTone: String, CaseIterable, Codable, Sendable {
    case green
    case olive
    case burgundy
    case plum
    case silver
    case bronze

    public var displayName: String {
        rawValue.capitalized
    }

    /// Hue, saturation and brightness ranges for this tone.
    var hueRange: ClosedRange<Double> {
        switch self {
        case .green: return 0.25...0.36
        case .olive: return 0.16...0.24
        case .burgundy: return 0.96...1.0
        case .plum: return 0.76...0.86
        case .silver: return 0.40...0.52
        case .bronze: return 0.06...0.11
        }
    }

    var saturationRange: ClosedRange<Double> {
        switch self {
        case .green: return 0.42...0.82
        case .olive: return 0.38...0.66
        case .burgundy: return 0.45...0.75
        case .plum: return 0.30...0.58
        case .silver: return 0.08...0.22
        case .bronze: return 0.35...0.60
        }
    }

    var brightnessRange: ClosedRange<Double> {
        switch self {
        case .green: return 0.34...0.72
        case .olive: return 0.36...0.66
        case .burgundy: return 0.30...0.55
        case .plum: return 0.32...0.56
        case .silver: return 0.52...0.80
        case .bronze: return 0.34...0.58
        }
    }

    /// Weighted so green is ordinary and the rest are a find. Repeats stand in
    /// for weights so the draw stays a single named gene.
    static let weighted: [FoliageTone] = [
        .green, .green, .green, .green, .green, .green, .green,
        .olive, .olive, .olive,
        .burgundy, .burgundy,
        .plum,
        .silver,
        .bronze
    ]
}

/// How a leaf's second colour is laid over its first.
public enum Variegation: String, CaseIterable, Codable, Sendable {
    case none
    /// A pale rim around the whole blade.
    case margin
    /// A stripe down the centre, either side of the midrib.
    case midrib
    /// Scattered patches, as a spotted begonia has.
    case speckled

    public var displayName: String {
        switch self {
        case .none: return "Plain"
        case .margin: return "Margined"
        case .midrib: return "Striped"
        case .speckled: return "Speckled"
        }
    }

    static let weighted: [Variegation] = [
        .none, .none, .none, .none, .none, .none, .none,
        .margin, .margin,
        .midrib,
        .speckled
    ]
}

/// Moves a uniform draw off the band of green that leaves occupy.
///
/// A flower the same green as the foliage around it reads as another leaf. Real
/// green flowers exist — a hellebore, a green rose — but they are a curiosity,
/// so the draw skips the band unless a rare gene says otherwise. The map is
/// monotone, which keeps inheritance sensible: a child that lands between its
/// parents' hues still lands between their colours.
func flowerHue(_ unit: Double, allowGreen: Bool) -> Double {
    guard !allowGreen else { return unit }
    let bandStart = 0.26
    let bandWidth = 0.14
    let scaled = unit * (1 - bandWidth)
    return scaled < bandStart ? scaled : scaled + bandWidth
}

/// Deterministic patch noise for speckled leaves.
///
/// A hash of the cell rather than a gradient noise: the patches want hard
/// edges, like the markings on a leaf, not a soft cloud.
func speckle(u: Double, v: Double, seed: UInt64, frequency: Double) -> Double {
    let cellU = Int((u * frequency).rounded(.down))
    let cellV = Int((v * frequency * 2).rounded(.down))
    var hash = seed
    hash = mix64(hash ^ UInt64(bitPattern: Int64(cellU &* 0x9E37_79B9)))
    hash = mix64(hash ^ UInt64(bitPattern: Int64(cellV &* 0x85EB_CA6B)))
    return Double(hash >> 11) * 0x1.0p-53
}

public extension Genome.Palette {
    /// Builds a plant's whole colour scheme from its genes.
    ///
    /// The order matters: a relationship is chosen first, then the second petal
    /// colour is derived from the first through it. Everything else — throat,
    /// veins, rim, centre — is pinned to those two, so a flower reads as one
    /// thing rather than a pile of independent random colours.
    static func derive(from source: GeneSource, seed: SeedID) -> Genome.Palette {
        let scheme = source.pick("palette.scheme", from: ColourScheme.allCases)

        let baseHue = flowerHue(
            source.unit("palette.petalHue"),
            allowGreen: source.chance("palette.greenFlower", 0.08)
        )
        let baseSaturation = source.value("palette.petalSaturation", 0.18...0.95)
        let baseBrightness = source.value("palette.petalBrightness", 0.55...1.0)
        let direction: Double = source.chance("palette.hueDirection", 0.5) ? 1 : -1

        var tipHue = baseHue
        var tipSaturation = baseSaturation
        var tipBrightness = baseBrightness

        switch scheme {
        case .monochrome:
            tipSaturation = baseSaturation * source.value("palette.tipSaturation", 0.45...1.1)
            tipBrightness = baseBrightness * source.value("palette.tipBrightness", 1.0...1.35)
        case .analogous:
            tipHue = baseHue + direction * source.value("palette.tipShift", 0.04...0.11)
            tipSaturation = baseSaturation * source.value("palette.tipSaturation", 0.7...1.1)
            tipBrightness = baseBrightness * source.value("palette.tipBrightness", 0.95...1.25)
        case .complementary:
            tipHue = baseHue + 0.5
            // Held back hard: a full-strength complement at the tip of every
            // petal is a traffic light, not a flower.
            tipSaturation = baseSaturation * source.value("palette.tipSaturation", 0.35...0.7)
            tipBrightness = baseBrightness * source.value("palette.tipBrightness", 1.0...1.3)
        case .split:
            tipHue = baseHue + 0.5 + direction * source.value("palette.tipShift", 0.06...0.16)
            tipSaturation = baseSaturation * source.value("palette.tipSaturation", 0.4...0.8)
            tipBrightness = baseBrightness * source.value("palette.tipBrightness", 1.0...1.3)
        case .bicolour:
            tipHue = baseHue + direction * source.value("palette.tipShift", 0.22...0.42)
            tipSaturation = baseSaturation * source.value("palette.tipSaturation", 0.75...1.15)
            tipBrightness = baseBrightness * source.value("palette.tipBrightness", 0.9...1.25)
        case .ombre:
            tipSaturation = baseSaturation * source.value("palette.tipSaturation", 0.08...0.35)
            tipBrightness = min(1.0, baseBrightness * source.value("palette.tipBrightness", 1.15...1.5))
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

        // The throat is the flower's own colour taken deeper and warmer, or the
        // complement when the scheme has already committed to contrast.
        let throatTowardComplement = scheme == .complementary || scheme == .split
        let throatHue = throatTowardComplement
            ? (baseHue + 0.5 + source.signed("palette.throatShift") * 0.06)
            : (baseHue + source.signed("palette.throatShift") * 0.08)
        let petalThroat = HSB(
            hue: throatHue.wrappedUnit,
            saturation: min(1, baseSaturation * source.value("palette.throatSaturation", 0.9...1.5) + 0.1),
            brightness: (baseBrightness * source.value("palette.throatBrightness", 0.5...0.95)).clamped(to: 0...1)
        )

        let petalVein = HSB(
            hue: (baseHue + source.signed("palette.veinShift") * 0.05).wrappedUnit,
            saturation: min(1, baseSaturation * 1.25 + 0.08),
            brightness: (baseBrightness * source.value("palette.veinBrightness", 0.35...0.7)).clamped(to: 0...1)
        )
        let veining = source.chance("palette.hasVeins", 0.45)
            ? source.bell("palette.veining", 0.15...0.75)
            : 0

        let picotee: HSB? = source.chance("palette.hasPicotee", 0.18)
            ? HSB(
                hue: (baseHue + 0.5 + source.signed("palette.picoteeShift") * 0.1).wrappedUnit,
                saturation: source.value("palette.picoteeSaturation", 0.5...1.0),
                brightness: source.value("palette.picoteeBrightness", 0.35...0.9)
              )
            : nil

        let tone = source.pick("palette.foliageTone", from: FoliageTone.weighted)
        let leaf = HSB(
            hue: source.value("palette.leafHue", tone.hueRange),
            saturation: source.value("palette.leafSaturation", tone.saturationRange),
            brightness: source.value("palette.leafBrightness", tone.brightnessRange)
        )

        let variegation = source.pick("palette.variegation", from: Variegation.weighted)
        let leafAccent = HSB(
            hue: (leaf.hue + source.signed("palette.accentShift") * 0.12).wrappedUnit,
            saturation: leaf.saturation * source.value("palette.accentSaturation", 0.1...0.6),
            brightness: min(1, leaf.brightness * source.value("palette.accentBrightness", 1.3...2.1))
        )

        // Veins are the leaf's own colour taken darker and a little deeper,
        // never a separate hue: a leaf whose veins disagree with its blade
        // reads as printed on rather than grown.
        let leafVein = HSB(
            hue: (leaf.hue + source.signed("palette.leafVeinShift") * 0.04).wrappedUnit,
            saturation: min(1, leaf.saturation * source.value("palette.leafVeinSaturation", 1.05...1.45)),
            brightness: (leaf.brightness * source.value("palette.leafVeinBrightness", 0.52...0.86)).clamped(to: 0...1)
        )
        // Nearly every leaf shows some venation, because nearly every real leaf
        // does. The gene decides how much, not whether.
        let leafVeining = source.chance("palette.hasLeafVeins", 0.88)
            ? source.bell("palette.leafVeining", 0.25...0.9)
            : 0

        let stem = HSB(
            hue: (leaf.hue + source.signed("palette.stemShift") * 0.06).wrappedUnit,
            saturation: (leaf.saturation * source.value("palette.stemSaturation", 0.6...1.1)).clamped(to: 0...1),
            brightness: (leaf.brightness * source.value("palette.stemBrightness", 0.62...1.0)).clamped(to: 0...1)
        )

        let centre = HSB(
            hue: source.unit("palette.centreHue"),
            saturation: source.value("palette.centreSaturation", 0.3...1.0),
            brightness: source.value("palette.centreBrightness", 0.6...1.0)
        )

        return Genome.Palette(
            scheme: scheme,
            petalBase: petalBase,
            petalTip: petalTip,
            petalThroat: petalThroat,
            petalVein: petalVein,
            picotee: picotee,
            veining: veining,
            foliageTone: tone,
            leaf: leaf,
            variegation: variegation,
            leafAccent: leafAccent,
            leafVein: leafVein,
            leafVeining: leafVeining,
            leafQuilting: source.bell("palette.leafQuilting", 0.1...0.85),
            stem: stem,
            centre: centre,
            glow: source.bell("palette.glow", 0...1),
            sheen: source.value("palette.sheen", 0.05...0.65),
            speckleSeed: GeneSource.rawUInt64(seed, "palette.speckleSeed")
        )
    }
}
