import Foundation

/// Draws trait values out of a seed.
///
/// Every trait is sampled *by name* rather than by position in a stream. That
/// means adding a trait in a later version does not shift the values of the
/// traits already growing on people's phones — a plant you minted on day one
/// looks the same on day four hundred.
public struct GeneSource: Sendable {
    /// The seed the traits are drawn from.
    public let seed: SeedID

    /// Present for hybrids: the two parents, already sorted so that both phones
    /// label them the same way round.
    public let parents: (SeedID, SeedID)?

    public static func primary(_ seed: SeedID) -> GeneSource {
        GeneSource(seed: seed, parents: nil)
    }

    /// - Parameters are accepted in either order; they are sorted internally.
    public static func hybrid(child: SeedID, parentA: SeedID, parentB: SeedID) -> GeneSource {
        let sorted = parentA < parentB ? (parentA, parentB) : (parentB, parentA)
        return GeneSource(seed: child, parents: sorted)
    }

    private init(seed: SeedID, parents: (SeedID, SeedID)?) {
        self.seed = seed
        self.parents = parents
    }

    /// Cumulative thresholds over `[0, 1)`: first parent, second parent, blend
    /// of the two, then a rare novel value. Tuned so a hybrid reads as clearly
    /// descended from both plants while still holding a surprise.
    static let inheritFirstParent = 0.36
    static let inheritSecondParent = 0.72
    static let inheritBlend = 0.94

    /// Uniform in `[0, 1)` for the named trait.
    public func unit(_ label: String) -> Double {
        guard let parents else {
            return Self.rawUnit(seed, label)
        }
        let roll = Self.rawUnit(seed, "inherit:" + label)
        if roll < Self.inheritFirstParent {
            return Self.rawUnit(parents.0, label)
        }
        if roll < Self.inheritSecondParent {
            return Self.rawUnit(parents.1, label)
        }
        if roll < Self.inheritBlend {
            let first = Self.rawUnit(parents.0, label)
            let second = Self.rawUnit(parents.1, label)
            return first + (second - first) * Self.rawUnit(seed, "blend:" + label)
        }
        return Self.rawUnit(seed, "mutate:" + label)
    }

    static func rawUnit(_ seed: SeedID, _ label: String) -> Double {
        Double(rawUInt64(seed, label) >> 11) * 0x1.0p-53
    }

    static func rawUInt64(_ seed: SeedID, _ label: String) -> UInt64 {
        mix64(seedDigest(SeedDomain.trait, seed.bytes, Data(label.utf8)).leadingUInt64)
    }
}

public extension GeneSource {
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
        precondition(!options.isEmpty, "cannot pick from an empty set of options")
        let index = min(options.count - 1, Int(unit(label) * Double(options.count)))
        return options[index]
    }

    /// Centre-weighted variant of `value(_:_:)`, for traits where the extremes
    /// should be uncommon rather than as likely as the middle.
    func bell(_ label: String, _ range: ClosedRange<Double>) -> Double {
        let sum = unit(label + ".a") + unit(label + ".b") + unit(label + ".c")
        return range.lowerBound + (sum / 3.0) * (range.upperBound - range.lowerBound)
    }

    /// Uniform in `[-1, 1]`.
    func signed(_ label: String) -> Double {
        unit(label) * 2.0 - 1.0
    }
}
