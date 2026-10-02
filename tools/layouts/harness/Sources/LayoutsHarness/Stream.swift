import Foundation
import SeedCore

/// One arrival, as a placement rule sees it: the seed, and the five traits
/// the phone sends with it.
struct Arrival: Codable {
    var seed: String
    var height: Double
    var family: Int
    var kind: String
    var hue: Double?
    var habit: String

    var traits: PlantTraits {
        PlantTraits(height: height, family: family, kind: kind, hue: hue, habit: habit)
    }

    var seedID: SeedID { SeedID(hex: seed)! }
}

/// **The stream: strangers meeting, each crossing filed where its name says.**
///
/// Crossing after crossing of two seeds nobody has seen before, each child
/// grown by SeedCore and sent to the area its genus head names — the way the
/// live garden fills, and the way every area since the Cold Frame has drawn
/// its own sample. One pass serves all ten: area by area, the stream is the
/// crossings that landed there, in the order they were made. An area with
/// two heads of twenty-eight receives one crossing in fourteen, the Seedbed
/// and the Long Walk one in seven, so their streams are as uneven in habit as
/// the garden's.
///
/// Every area's stream is drawn from the same crossings, so a layout change
/// to one area is measured on exactly the plants it was measured on before.
enum Stream {
    static let label = "layouts-stranger"

    static func make(_ count: Int, for areas: [Area]) -> [Area: [Arrival]] {
        var found: [Area: [Arrival]] = [:]
        var n = 0
        let wanted = Set(areas)
        while wanted.contains(where: { (found[$0]?.count ?? 0) < count }) {
            let a = SeedMint.mint(fromEntropy: Data("\(label)-\(n)-a".utf8))
            let b = SeedMint.mint(fromEntropy: Data("\(label)-\(n)-b".utf8))
            n += 1
            let meeting = Pollination.encounterID(seedA: a, seedB: b,
                                                  nonceA: Data("a".utf8), nonceB: Data("b".utf8))
            let child = Pollination.cross(seedA: a, seedB: b, encounterID: meeting)
            let genome = Genome(seed: child, lineage: .crossed(parentA: a, parentB: b, encounterID: meeting))
            let area = Area(genome: genome)
            guard wanted.contains(area), (found[area]?.count ?? 0) < count else { continue }
            let t = LongWalk.traits(of: genome)
            found[area, default: []].append(Arrival(seed: child.hex, height: t.height, family: t.family,
                                                    kind: t.kind, hue: t.hue, habit: t.habit))
        }
        return found
    }
}

/// Growing a plant builds its mesh, so a stream is kept between runs in the
/// package's own build directory, which git ignores.
///
/// **Named by what the plants grow into**, as `tools/homeground` names its
/// samples: the stamp is the travel ambassador's grown height to the bit, so a
/// SeedCore that grows plants differently draws a fresh stream rather than
/// answering with the old heights.
enum Cache {
    static let stamp: String = {
        let bounds = Maturity.bounds(for: Ambassadors.of(.travel).genome)
        return String((bounds.max.y - bounds.min.y).bitPattern, radix: 16)
    }()

    static func stream(_ count: Int, for areas: [Area]) -> [Area: [Arrival]] {
        let dir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent(".build/streams")
        var kept: [Area: [Arrival]] = [:]
        var missing: [Area] = []
        for area in areas {
            let file = dir.appendingPathComponent("\(area.rawValue)-\(count)-\(stamp).json")
            if let data = try? Data(contentsOf: file),
               let arrivals = try? JSONDecoder().decode([Arrival].self, from: data), arrivals.count == count {
                kept[area] = arrivals
            } else {
                missing.append(area)
            }
        }
        guard !missing.isEmpty else { return kept }
        FileHandle.standardError.write(Data("Growing \(count) arrivals for \(missing.map(\.rawValue).joined(separator: ", "))…\n".utf8))
        let made = Stream.make(count, for: missing)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        for (area, arrivals) in made {
            kept[area] = arrivals
            let file = dir.appendingPathComponent("\(area.rawValue)-\(count)-\(stamp).json")
            try? JSONEncoder().encode(arrivals).write(to: file)
        }
        return kept
    }
}
