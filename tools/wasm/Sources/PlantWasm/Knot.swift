#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif
import SeedCore

// A Knot Garden for the page: the same shape as `Walk.swift`, `Quiet.swift`,
// `Cross.swift` and `Orchard.swift`, and for the same reason — a template has
// to be judged at five hundred plants before it is live, and the browser is
// where it can be looked at.
//
//   pg_knot_plan()        the plot's own numbers as JSON: its side, how thick
//                         and how high a band is, how a band swells where it
//                         rides over and how far an under-band's end tucks
//                         into it, and what a plot holds — so the page keeps
//                         no copy of them. The lines of the rings are the
//                         table's, which the page imports as it is
//                         (`tables/knot_garden_rings.js`)
//   pg_knot_arrive()      plants the next arrival; returns its plot
//   pg_knot_count(plot)   plantings in a plot so far
//   pg_knot_grow(plot, i) grows the i-th planting of a plot into the result:
//                         spot x, spot z (f32 each), then a plant buffer
//   pg_knot_plots()       plots opened so far
//   pg_knot_describe(p)   a plot's plantings as JSON: place and traits, for
//                         judging whether a pair really does hold one colour
//                         and fill as a mirror
//
// Opened rather than empty: it starts with its ambassador (Quinyria obscura
// since 28 September 2026) in the north-east lens, the way the real one does — which means the first pair is
// already claimed for family 4 before a single arrival, exactly as the service
// has it.

nonisolated(unsafe) private var knotWays = KnotGarden.Ways.opened()
nonisolated(unsafe) private var grownInKnot: [String: Genome] = {
    let one = Ambassadors.of(.pattern)
    return [one.seed.hex: one.genome]
}()

/// The n-th arrival: two parents who meet once, and the plant they make.
private func knotVisitor(_ n: Int) -> (child: SeedID, genome: Genome) {
    let parentA = SeedMint.mint(fromEntropy: Data("knot-parent-\(n)-a".utf8))
    let parentB = SeedMint.mint(fromEntropy: Data("knot-parent-\(n)-b".utf8))
    let meeting = Pollination.encounterID(
        seedA: parentA, seedB: parentB, nonceA: Data("a".utf8), nonceB: Data("b".utf8)
    )
    let child = Pollination.cross(seedA: parentA, seedB: parentB, encounterID: meeting)
    return (child, Genome(seed: child,
                          lineage: .crossed(parentA: parentA, parentB: parentB, encounterID: meeting)))
}

@_expose(wasm, "pg_knot_plan")
@_cdecl("pg_knot_plan")
public func pgKnotPlan() -> Int32 {
    let json = """
        {"plotSide":\(KnotGarden.plotSide),\
        "bandHalfThickness":\(KnotGarden.bandHalfThickness),\
        "bandHeight":\(KnotGarden.bandHeight),\
        "swellThicker":\(KnotGarden.swellThicker),"swellTaller":\(KnotGarden.swellTaller),\
        "swellReach":\(KnotGarden.swellReach),"tuck":\(KnotGarden.tuck),\
        "slots":\(KnotGarden.slots.count),\
        "compartments":\(KnotGarden.Compartment.allCases.count)}
        """
    setResult(Array(json.utf8))
    return Int32(json.utf8.count)
}

@_expose(wasm, "pg_knot_arrive")
@_cdecl("pg_knot_arrive")
public func pgKnotArrive() -> Int32 {
    // Counted from the arrivals, not the plantings: the ambassador is standing
    // there and is not an arrival.
    let (child, genome) = knotVisitor(knotWays.plantings.count - 1)
    let planting = knotWays.plant(seed: child, traits: LongWalk.traits(of: genome))
    grownInKnot[planting.seed] = genome
    return Int32(planting.plot)
}

@_expose(wasm, "pg_knot_count")
@_cdecl("pg_knot_count")
public func pgKnotCount(_ plot: Int32) -> Int32 {
    Int32(knotWays.plot(Int(plot)).count)
}

@_expose(wasm, "pg_knot_grow")
@_cdecl("pg_knot_grow")
public func pgKnotGrow(_ plot: Int32, _ index: Int32) -> Int32 {
    let here = knotWays.plot(Int(plot))
    guard here.indices.contains(Int(index)),
          let genome = grownInKnot[here[Int(index)].seed] else { return 0 }
    let spot = here[Int(index)].spot
    var out: [UInt8] = []
    for value in [Float(spot.x), Float(spot.z)] {
        withUnsafeBytes(of: value.bitPattern.littleEndian) { out.append(contentsOf: $0) }
    }
    out.append(contentsOf: PlantBuffer.encode(genome))
    setResult(out)
    return Int32(out.count)
}

@_expose(wasm, "pg_knot_plots")
@_cdecl("pg_knot_plots")
public func pgKnotPlots() -> Int32 {
    Int32(knotWays.plots)
}

@_expose(wasm, "pg_knot_describe")
@_cdecl("pg_knot_describe")
public func pgKnotDescribe(_ plot: Int32) -> Int32 {
    guard let json = try? JSONEncoder().encode(knotWays.plot(Int(plot))) else { return 0 }
    setResult(Array(json))
    return Int32(json.count)
}
