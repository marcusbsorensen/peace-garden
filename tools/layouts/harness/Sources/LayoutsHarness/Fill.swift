import Foundation
import SeedCore

/// **What the harness asks of an area's rule**: open it with its ambassador,
/// plant arrivals one by one, and say for each plot how many places its
/// plants hold and how many it has for this area's plants.
///
/// Each area answers in its own file in `Areas/`, so an area agent who changes
/// a rule's types changes only that file. A place a lotus takes two of counts
/// twice; a place no plant of this area can take (the Quiet Garden's pool,
/// which the live garden never sends a lily) does not count at all.
protocol Rule {
    static func opened() -> Self
    mutating func arrive(_ arrival: Arrival)
    var plots: Int { get }
    /// Places held in a plot: plants, a lotus counted for the places it takes.
    func held(in plot: Int) -> Int
    /// Places a plot has for this area's plants.
    func capacity(of plot: Int) -> Int
    /// Anything about the settled plots the counts do not say.
    func note(settled: Range<Int>) -> String?
}

extension Rule {
    func note(settled: Range<Int>) -> String? { nil }
}

/// What the area looks like after so many arrivals.
struct Measure: Codable, Equatable {
    var arrivals: Int
    var plots: Int
    /// Every plant standing, the ambassador among them.
    var plants: Int
    var held: Int
    var places: Int
    /// **Settled** is every plot but the newest two, which are where a
    /// visitor would find an empty place in the old part of an area: the
    /// measure the Coppice's and the research's simulations used.
    var settledPlots: Int
    var settledHeld: Int
    var settledPlaces: Int
    var note: String?

    var heldShare: Double { places == 0 ? 0 : Double(held) / Double(places) }
    var settledShare: Double? { settledPlaces == 0 ? nil : Double(settledHeld) / Double(settledPlaces) }
    var settledEmpty: Int { settledPlaces - settledHeld }
}

enum Fill {
    /// Plants `arrivals` into the area as it opened, and measures it after
    /// each of `checkpoints` arrivals.
    static func run<R: Rule>(_ rule: R.Type, _ arrivals: [Arrival], at checkpoints: [Int]) -> [Measure] {
        var ways = R.opened()
        var out: [Measure] = []
        let marks = Set(checkpoints)
        for (n, arrival) in arrivals.enumerated() {
            ways.arrive(arrival)
            if marks.contains(n + 1) { out.append(measure(ways, arrivals: n + 1)) }
        }
        return out
    }

    static func measure<R: Rule>(_ ways: R, arrivals: Int) -> Measure {
        let plots = ways.plots
        let held = (0..<plots).map { ways.held(in: $0) }
        let places = (0..<plots).map { ways.capacity(of: $0) }
        let settled = 0..<max(0, plots - 2)
        return Measure(arrivals: arrivals, plots: plots, plants: arrivals + 1,
                       held: held.reduce(0, +), places: places.reduce(0, +),
                       settledPlots: settled.count,
                       settledHeld: settled.map { held[$0] }.reduce(0, +),
                       settledPlaces: settled.map { places[$0] }.reduce(0, +),
                       note: ways.note(settled: settled))
    }

    /// The area's rule, by area.
    static func run(_ area: Area, _ arrivals: [Arrival], at checkpoints: [Int]) -> [Measure] {
        switch area {
        case .travel: return run(LongWalk.Walk.self, arrivals, at: checkpoints)
        case .peace: return run(QuietGarden.Room.self, arrivals, at: checkpoints)
        case .meeting: return run(Crossing.Ways.self, arrivals, at: checkpoints)
        case .kinship: return run(Orchard.Ways.self, arrivals, at: checkpoints)
        case .pattern: return run(KnotGarden.Ways.self, arrivals, at: checkpoints)
        case .beginnings: return run(Seedbed.Ways.self, arrivals, at: checkpoints)
        case .waiting: return run(ColdFrame.Ways.self, arrivals, at: checkpoints)
        case .light: return run(Glasshouse.Ways.self, arrivals, at: checkpoints)
        case .renewal: return run(Coppice.Ways.self, arrivals, at: checkpoints)
        case .ground: return run(HomeGround.Ways.self, arrivals, at: checkpoints)
        }
    }
}
