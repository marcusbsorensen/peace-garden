#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif
import SeedCore

// A Crossing for the page: the same shape as `Walk.swift` and `Quiet.swift`, and
// for the same reason — a template has to be judged at five hundred plants
// before it is live, and the browser is where it can be looked at.
//
//   pg_cross_plan()        the plot's own numbers as JSON: its side, how wide a
//                          path is at the plot's edge and at the round, how big
//                          the paving is, and what a plot holds — so the page
//                          keeps no copy of them. The paths' lines and the
//                          places are the table's (`tables/crossing_ways.js`),
//                          and a plot's variant is `pg_plot_variant`'s
//   pg_cross_arrive()      plants the next arrival; returns its plot
//   pg_cross_count(plot)   plantings in a plot so far
//   pg_cross_grow(plot, i) grows the i-th planting of a plot into the result:
//                          spot x, spot z (f32 each), then a plant buffer
//   pg_cross_plots()       plots opened so far
//   pg_cross_describe(p)   a plot's plantings as JSON: slot and traits, for
//                          judging how the rule fills the quarters
//
// Opened rather than empty: it starts with its ambassador (Ithula obscura
// since 28 September 2026, in the first quarter's middle rank) the way the
// real one does.
//
// **Only this area's own plants arrive**, since 2 October 2026, as the Cold
// Frame's workbench and `tools/layouts/harness` draw them: the crossings whose
// names put them at the Crossing, orchids, bells and cushions. Before then
// every crossing came here, lilies and reeds among them, which the live garden
// never sends.

nonisolated(unsafe) private var ways = Crossing.Ways.opened()
nonisolated(unsafe) private var grownAtCrossing: [String: Genome] = {
    let one = Ambassadors.of(.meeting)
    return [one.seed.hex: one.genome]
}()

nonisolated(unsafe) private var crossCrossings = 0

/// The next arrival: the next crossing whose name puts it at the Crossing.
private func crossVisitor() -> (child: SeedID, genome: Genome) {
    while true {
        let n = crossCrossings
        crossCrossings += 1
        let parentA = SeedMint.mint(fromEntropy: Data("crossing-parent-\(n)-a".utf8))
        let parentB = SeedMint.mint(fromEntropy: Data("crossing-parent-\(n)-b".utf8))
        let meeting = Pollination.encounterID(
            seedA: parentA, seedB: parentB, nonceA: Data("a".utf8), nonceB: Data("b".utf8)
        )
        let child = Pollination.cross(seedA: parentA, seedB: parentB, encounterID: meeting)
        let genome = Genome(seed: child,
                            lineage: .crossed(parentA: parentA, parentB: parentB, encounterID: meeting))
        if Area(genome: genome) == .meeting { return (child, genome) }
    }
}

@_expose(wasm, "pg_cross_plan")
@_cdecl("pg_cross_plan")
public func pgCrossPlan() -> Int32 {
    let json = """
        {"plotSide":\(Crossing.plotSide),"pathHalfWidth":\(Crossing.pathHalfWidth),\
        "pathHalfWidthAtRound":\(Crossing.pathHalfWidthAtRound),\
        "roundelRadius":\(Crossing.roundelRadius),"slots":\(Crossing.slots.count)}
        """
    setResult(Array(json.utf8))
    return Int32(json.utf8.count)
}

@_expose(wasm, "pg_cross_arrive")
@_cdecl("pg_cross_arrive")
public func pgCrossArrive() -> Int32 {
    let (child, genome) = crossVisitor()
    let planting = ways.plant(seed: child, traits: LongWalk.traits(of: genome))
    grownAtCrossing[planting.seed] = genome
    return Int32(planting.plot)
}

@_expose(wasm, "pg_cross_count")
@_cdecl("pg_cross_count")
public func pgCrossCount(_ plot: Int32) -> Int32 {
    Int32(ways.plot(Int(plot)).count)
}

@_expose(wasm, "pg_cross_grow")
@_cdecl("pg_cross_grow")
public func pgCrossGrow(_ plot: Int32, _ index: Int32) -> Int32 {
    let here = ways.plot(Int(plot))
    guard here.indices.contains(Int(index)),
          let genome = grownAtCrossing[here[Int(index)].seed] else { return 0 }
    let spot = here[Int(index)].spot
    var out: [UInt8] = []
    for value in [Float(spot.x), Float(spot.z)] {
        withUnsafeBytes(of: value.bitPattern.littleEndian) { out.append(contentsOf: $0) }
    }
    out.append(contentsOf: PlantBuffer.encode(genome))
    setResult(out)
    return Int32(out.count)
}

@_expose(wasm, "pg_cross_plots")
@_cdecl("pg_cross_plots")
public func pgCrossPlots() -> Int32 {
    Int32(ways.plots)
}

@_expose(wasm, "pg_cross_describe")
@_cdecl("pg_cross_describe")
public func pgCrossDescribe(_ plot: Int32) -> Int32 {
    guard let json = try? JSONEncoder().encode(ways.plot(Int(plot))) else { return 0 }
    setResult(Array(json))
    return Int32(json.count)
}
