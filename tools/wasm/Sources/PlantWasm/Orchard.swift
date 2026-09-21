#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif
import SeedCore

// An Orchard for the page: the same shape as `Walk.swift`, `Quiet.swift` and
// `Cross.swift`, and for the same reason — a template has to be judged at five
// hundred plants before it is live, and the browser is where it can be looked
// at.
//
//   pg_orchard_plan()        the plot's own numbers as JSON: its side, how far
//                            out the trees stand, how far a guild sits from its
//                            trunk, and what a plot holds — so the page keeps no
//                            copy of them
//   pg_orchard_arrive()      plants the next arrival; returns its plot
//   pg_orchard_count(plot)   plantings in a plot so far
//   pg_orchard_grow(plot, i) grows the i-th planting of a plot into the result:
//                            spot x, spot z (f32 each), then a plant buffer
//   pg_orchard_plots()       plots opened so far
//   pg_orchard_describe(p)   a plot's plantings as JSON: place and traits, for
//                            judging whether the guilds really do fill one at a
//                            time
//
// Opened rather than empty: it starts with Cyninora contorta under the middle
// tree, the way the real one does.

nonisolated(unsafe) private var orchardWays = Orchard.Ways.opened()
nonisolated(unsafe) private var grownInOrchard: [String: Genome] = {
    let one = Ambassadors.of(.kinship)
    return [one.seed.hex: one.genome]
}()

/// The n-th arrival: two parents who meet once, and the plant they make.
private func orchardVisitor(_ n: Int) -> (child: SeedID, genome: Genome) {
    let parentA = SeedMint.mint(fromEntropy: Data("orchard-parent-\(n)-a".utf8))
    let parentB = SeedMint.mint(fromEntropy: Data("orchard-parent-\(n)-b".utf8))
    let meeting = Pollination.encounterID(
        seedA: parentA, seedB: parentB, nonceA: Data("a".utf8), nonceB: Data("b".utf8)
    )
    let child = Pollination.cross(seedA: parentA, seedB: parentB, encounterID: meeting)
    return (child, Genome(seed: child,
                          lineage: .crossed(parentA: parentA, parentB: parentB, encounterID: meeting)))
}

@_expose(wasm, "pg_orchard_plan")
@_cdecl("pg_orchard_plan")
public func pgOrchardPlan() -> Int32 {
    let json = """
        {"plotSide":\(Orchard.plotSide),"treeFrom":\(Orchard.treeFrom),\
        "guildRadius":\(Orchard.guildRadius),"slots":\(Orchard.slots.count),\
        "guilds":\(Orchard.Guild.allCases.count)}
        """
    setResult(Array(json.utf8))
    return Int32(json.utf8.count)
}

@_expose(wasm, "pg_orchard_arrive")
@_cdecl("pg_orchard_arrive")
public func pgOrchardArrive() -> Int32 {
    // Counted from the arrivals, not the plantings: the ambassador is standing
    // there and is not an arrival.
    let (child, genome) = orchardVisitor(orchardWays.plantings.count - 1)
    let planting = orchardWays.plant(seed: child, traits: LongWalk.traits(of: genome))
    grownInOrchard[planting.seed] = genome
    return Int32(planting.plot)
}

@_expose(wasm, "pg_orchard_count")
@_cdecl("pg_orchard_count")
public func pgOrchardCount(_ plot: Int32) -> Int32 {
    Int32(orchardWays.plot(Int(plot)).count)
}

@_expose(wasm, "pg_orchard_grow")
@_cdecl("pg_orchard_grow")
public func pgOrchardGrow(_ plot: Int32, _ index: Int32) -> Int32 {
    let here = orchardWays.plot(Int(plot))
    guard here.indices.contains(Int(index)),
          let genome = grownInOrchard[here[Int(index)].seed] else { return 0 }
    let spot = here[Int(index)].spot
    var out: [UInt8] = []
    for value in [Float(spot.x), Float(spot.z)] {
        withUnsafeBytes(of: value.bitPattern.littleEndian) { out.append(contentsOf: $0) }
    }
    out.append(contentsOf: PlantBuffer.encode(genome))
    setResult(out)
    return Int32(out.count)
}

@_expose(wasm, "pg_orchard_plots")
@_cdecl("pg_orchard_plots")
public func pgOrchardPlots() -> Int32 {
    Int32(orchardWays.plots)
}

@_expose(wasm, "pg_orchard_describe")
@_cdecl("pg_orchard_describe")
public func pgOrchardDescribe(_ plot: Int32) -> Int32 {
    guard let json = try? JSONEncoder().encode(orchardWays.plot(Int(plot))) else { return 0 }
    setResult(Array(json))
    return Int32(json.count)
}

/// Where the five trunks stand in a plot, as JSON — so the page draws the
/// quincunx from the rule rather than from a copy of it.
@_expose(wasm, "pg_orchard_trees")
@_cdecl("pg_orchard_trees")
public func pgOrchardTrees() -> Int32 {
    let trees = Orchard.Guild.allCases.map { "[\($0.trunk.x),\($0.trunk.z)]" }
    let json = "[" + trees.joined(separator: ",") + "]"
    setResult(Array(json.utf8))
    return Int32(json.utf8.count)
}
