import Foundation
import SeedCore

/// One Home Ground plant, as a placement rule would see it, and a little more:
/// the footprint, which decides the spacing, and the form, which is the fact
/// the recommended rule reads.
struct Plant: Codable {
    var seed: String
    var height: Double
    /// Across the grown plant on the two ground axes, in metres.
    var wide: Double
    var family: Int
    /// `Cer`, `Fen` or `Pell` — and in this area, one form each.
    var head: String
    var archetype: String
    var kind: String
    /// Which gardeners' seeds it was crossed from, for the stream that has
    /// gardeners in it. Empty for a stream of strangers.
    var parents: [Int] = []

    init(seed: SeedID, genome: Genome, parents: [Int] = []) {
        let bounds = Maturity.bounds(for: genome)
        let traits = LongWalk.traits(of: genome)
        self.seed = seed.hex
        height = traits.height
        wide = Double(max(bounds.max.x - bounds.min.x, bounds.max.z - bounds.min.z))
        family = traits.family
        head = genome.name.genusHead
        archetype = genome.form.archetype.rawValue
        kind = traits.kind
        self.parents = parents
    }
}

/// A stream of arrivals.
enum Stream {

    /// **Strangers**: every plant a crossing of two seeds nobody has seen
    /// before, kept only if its name puts it in the Home Ground. The way every
    /// area since the Cold Frame has drawn its sample, and it is the right
    /// sample for measuring a cut: it has no gardener in it to lean the heights.
    static func strangers(_ count: Int, label: String) -> (plants: [Plant], crossings: Int) {
        var found: [Plant] = []
        var n = 0
        while found.count < count {
            let a = SeedMint.mint(fromEntropy: Data("homeground-\(label)-\(n)-a".utf8))
            let b = SeedMint.mint(fromEntropy: Data("homeground-\(label)-\(n)-b".utf8))
            n += 1
            if let plant = cross(a, b, nonce: "\(n)") { found.append(plant) }
        }
        return (found, n)
    }

    /// **Gardeners**: a village of them, meeting unevenly. A few meet often
    /// and most rarely — weights falling as one over rank, which is how
    /// footfall is distributed nearly everywhere it has been counted — and
    /// every meeting is a new crossing of the two gardeners' own seeds.
    ///
    /// This is the stream the Long Walk warned about: *crossings of one person
    /// with forty others ran taller and were half bells, so a sample from one
    /// gardener is the wrong sample*. Wrong for measuring a cut; right for
    /// asking whether the rule holds when arrivals come in runs.
    static func gardeners(_ count: Int, village: Int, label: String) -> (plants: [Plant], crossings: Int) {
        let seeds = (0..<village).map { SeedMint.mint(fromEntropy: Data("homeground-\(label)-gardener-\($0)".utf8)) }
        let weights = (0..<village).map { 1.0 / Double($0 + 1) }
        let total = weights.reduce(0, +)
        var rng = SplitMix(seed: 0x486F6D65)
        func pick() -> Int {
            var r = rng.unit() * total
            for (i, w) in weights.enumerated() { r -= w; if r < 0 { return i } }
            return village - 1
        }
        var found: [Plant] = []
        var n = 0
        while found.count < count {
            let i = pick()
            var j = pick()
            while j == i { j = pick() }
            n += 1
            if let plant = cross(seeds[i], seeds[j], nonce: "\(label)-\(n)", parents: [i, j]) {
                found.append(plant)
            }
        }
        return (found, n)
    }

    private static func cross(_ a: SeedID, _ b: SeedID, nonce: String, parents: [Int] = []) -> Plant? {
        let meeting = Pollination.encounterID(seedA: a, seedB: b,
                                              nonceA: Data("a\(nonce)".utf8), nonceB: Data("b\(nonce)".utf8))
        let child = Pollination.cross(seedA: a, seedB: b, encounterID: meeting)
        let genome = Genome(seed: child, lineage: .crossed(parentA: a, parentB: b, encounterID: meeting))
        guard Area(genome: genome) == .ground else { return nil }
        return Plant(seed: child, genome: genome, parents: parents)
    }

    /// The ambassador, as the first arrival every stream is placed after.
    static var ambassador: Plant {
        let one = Ambassadors.of(.ground)
        return Plant(seed: one.seed, genome: one.genome)
    }
}

/// A small fixed generator, so the village meets in the same order every run.
struct SplitMix {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
    mutating func unit() -> Double { Double(next() >> 11) / Double(1 << 53) }
}

/// Samples are slow to grow — every plant builds its mesh — so they are kept
/// between runs in the package's own build directory, which git ignores.
enum Cache {
    static func load(_ name: String, make: () -> (plants: [Plant], crossings: Int)) -> (plants: [Plant], crossings: Int) {
        let dir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent(".build/samples")
        let file = dir.appendingPathComponent("\(name).json")
        struct Stored: Codable { var plants: [Plant]; var crossings: Int }
        if let data = try? Data(contentsOf: file), let stored = try? JSONDecoder().decode(Stored.self, from: data) {
            return (stored.plants, stored.crossings)
        }
        let made = make()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? JSONEncoder().encode(Stored(plants: made.plants, crossings: made.crossings)).write(to: file)
        return made
    }
}
