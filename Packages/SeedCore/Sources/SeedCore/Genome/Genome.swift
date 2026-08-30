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
        public var symmetry: Int
        public var vigour: Double
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
        public var atNodes: Bool
        public var present: Bool
    }

    public struct Palette: Equatable, Sendable {
        public var petalBase: HSB
        public var petalTip: HSB
        public var leaf: HSB
        public var stem: HSB
        public var centre: HSB
        public var glow: Double
        public var sheen: Double
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

        form = Form(
            archetype: archetype,
            symmetry: source.integer("form.symmetry", 3...9),
            vigour: source.bell("form.vigour", 0.82...1.22)
        )

        let height = source.value("stem.height", 0.55...1.25) * profile.heightScale * form.vigour
        let baseRadius = source.value("stem.baseRadius", 0.008...0.019) * profile.stemThickness
        stem = Stem(
            height: height,
            baseRadius: baseRadius,
            taper: source.value("stem.taper", 0.28...0.72),
            lean: source.signed("stem.lean") * 0.55,
            sway: source.bell("stem.sway", 0...1) * profile.swayScale,
            twist: source.signed("stem.twist") * 0.7,
            nodeCount: max(1, Int((Double(source.integer("stem.nodeCount", 2...7)) * profile.nodeScale).rounded())),
            sides: source.integer("stem.sides", 6...9)
        )

        foliage = Foliage(
            leavesPerNode: source.integer("foliage.leavesPerNode", 1...3),
            length: source.value("foliage.length", 0.09...0.26) * profile.leafLengthScale * form.vigour,
            widthRatio: source.value("foliage.widthRatio", 0.22...0.78) * profile.leafWidthScale,
            droop: source.bell("foliage.droop", 0...1) * profile.leafDroop,
            fold: source.value("foliage.fold", 0.05...0.55),
            pitch: source.value("foliage.pitch", 0.35...1.25),
            // Phyllotaxis: the golden angle, jittered a little per plant.
            divergence: 2.399963 + source.signed("foliage.divergence") * 0.22,
            serration: source.bell("foliage.serration", 0...1),
            tipSharpness: source.value("foliage.tipSharpness", 0.7...2.1)
        )

        let petalBase = source.integer("bloom.petalCount", 3...13)
        let petalCount = max(3, Int((Double(petalBase) * profile.petalCountScale).rounded()))
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
            atNodes: profile.bloomsAtNodes,
            present: source.unit("bloom.present") < profile.bloomPresence
        )

        // Petal colour is drawn as a base plus a *shift* to the tip, so hybrids
        // that inherit one parent's base and the other's shift still land on a
        // coherent gradient rather than two unrelated colours.
        let petalHue = source.unit("palette.petalHue")
        let hueShift = source.signed("palette.petalTipShift") * 0.09
        let petalSaturation = source.value("palette.petalSaturation", 0.15...0.95)
        let petalBrightness = source.value("palette.petalBrightness", 0.55...1.0)
        let leafHue = 0.22 + source.unit("palette.leafHue") * 0.16
        palette = Palette(
            petalBase: HSB(
                hue: petalHue,
                saturation: petalSaturation,
                brightness: petalBrightness * 0.82
            ),
            petalTip: HSB(
                hue: (petalHue + hueShift).wrappedUnit,
                saturation: (petalSaturation * source.value("palette.tipSaturation", 0.45...1.15)).clamped(to: 0...1),
                brightness: min(1.0, petalBrightness * source.value("palette.tipBrightness", 0.95...1.35))
            ),
            leaf: HSB(
                hue: leafHue,
                saturation: source.value("palette.leafSaturation", 0.34...0.82),
                brightness: source.value("palette.leafBrightness", 0.34...0.72)
            ),
            stem: HSB(
                hue: (leafHue + source.signed("palette.stemShift") * 0.05).wrappedUnit,
                saturation: source.value("palette.stemSaturation", 0.2...0.7),
                brightness: source.value("palette.stemBrightness", 0.24...0.54)
            ),
            centre: HSB(
                hue: source.unit("palette.centreHue"),
                saturation: source.value("palette.centreSaturation", 0.3...1.0),
                brightness: source.value("palette.centreBrightness", 0.6...1.0)
            ),
            glow: source.bell("palette.glow", 0...1),
            sheen: source.value("palette.sheen", 0.05...0.65)
        )

        tempo = Tempo(
            germinationHours: source.value("tempo.germinationHours", 3...20),
            seedlingDays: source.value("tempo.seedlingDays", 0.6...2.4),
            vegetativeDays: source.value("tempo.vegetativeDays", 2.0...7.0),
            buddingDays: source.value("tempo.buddingDays", 1.0...4.0),
            bloomDays: source.value("tempo.bloomDays", 3.0...12.0),
            opensByDay: source.chance("tempo.opensByDay", 0.7)
        )

        name = PlantName(source: source)
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
