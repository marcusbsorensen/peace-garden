#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif
import SeedCore

// A Home Ground for the page: the same shape as `Seedbed.swift` and
// `Coppice.swift`, and for the same reason — a template has to be judged at
// five hundred plants before it is live, and the browser is where it can be
// looked at.
//
//   pg_ground_plan()          the area's own numbers as JSON: its side, the
//                             straight lines the three beds sway about and how
//                             wide and long they are, and each crop's spacing
//                             and cut — so the page keeps no copy of them. The
//                             line each bed really runs along is the table's,
//                             which the page imports as it is
//                             (`tables/home_ground_beds.js`), and which way
//                             round a plot is laid is `pg_plot_variant`'s
//   pg_ground_arrive()        plants the next arrival; returns its plot
//   pg_ground_count(plot)     plantings in a plot so far
//   pg_ground_grow(plot, i)   grows the i-th planting of a plot into the result:
//                             spot x, spot z (f32 each), then a plant buffer
//   pg_ground_plots()         plots opened so far
//   pg_ground_describe(p)     a plot's plantings as JSON: place and traits —
//                             including the crop each bed is sown with
//   pg_ground_lineage(n)      the n-th of the workbench's arrivals as a phone
//                             would send it to the plot service, as JSON:
//                             seed, parents, encounter, height, family, habit
//
// Opened rather than empty: it starts with the ground ambassador at the north
// end of the west bed, the way the real one does — so that bed is sown with
// umbels before a single arrival, exactly as the service has it.

nonisolated(unsafe) private var groundWays = HomeGround.Ways.opened()
nonisolated(unsafe) private var grownInGround: [String: Genome] = {
    let one = Ambassadors.of(.ground)
    return [one.seed.hex: one.genome]
}()

/// The workbench's crossings that land in the Home Ground, found as they are
/// asked for and kept, so `pg_ground_lineage` and `pg_ground_arrive` name the
/// same n-th plant without starting the search again.
nonisolated(unsafe) private var groundFound: [(child: SeedID, parentA: SeedID, parentB: SeedID,
                                                encounter: Data, genome: Genome)] = []
nonisolated(unsafe) private var groundCrossings = 0

/// The n-th crossing whose name puts it in the Home Ground.
///
/// **Only this area's plants, as `HomeGroundTests` draws them**, because the
/// three cuts are the medians of this area's own crops. A workbench of any
/// crossing would bring a spire, an umbel or a rosette in one plant of eight.
private func groundVisitor(_ n: Int) -> (child: SeedID, parentA: SeedID, parentB: SeedID,
                                         encounter: Data, genome: Genome) {
    while groundFound.count <= n {
        let k = groundCrossings
        groundCrossings += 1
        let parentA = SeedMint.mint(fromEntropy: Data("ground-parent-\(k)-a".utf8))
        let parentB = SeedMint.mint(fromEntropy: Data("ground-parent-\(k)-b".utf8))
        let meeting = Pollination.encounterID(
            seedA: parentA, seedB: parentB, nonceA: Data("a".utf8), nonceB: Data("b".utf8)
        )
        let child = Pollination.cross(seedA: parentA, seedB: parentB, encounterID: meeting)
        let genome = Genome(seed: child,
                            lineage: .crossed(parentA: parentA, parentB: parentB, encounterID: meeting))
        if Area(genome: genome) == .ground { groundFound.append((child, parentA, parentB, meeting, genome)) }
    }
    return groundFound[n]
}

@_expose(wasm, "pg_ground_plan")
@_cdecl("pg_ground_plan")
public func pgGroundPlan() -> Int32 {
    let list = { (values: [Double]) in values.map { "\($0)" }.joined(separator: ",") }
    // Each crop's spacing, asked of the rule. Where its places are is the
    // crop's table, which the service reads; the page is sent each spot.
    let crops = HomeGround.Crop.allCases.map { crop -> String in
        let s = crop.sown
        return """
            "\(crop.rawValue)":{"across":\(s.across),"gap":\(s.gap),"rows":\(s.rows),\
            "rowGap":\(s.rowGap),"cut":\(crop.cut),"capacity":\(crop.capacity)}
            """
    }.joined(separator: ",")
    let json = """
        {"plotSide":\(HomeGround.plotSide),"beds":\(HomeGround.beds),\
        "bedX":[\(list(HomeGround.bedX))],"bedWidth":\(HomeGround.bedWidth),\
        "bedLength":\(HomeGround.bedLength),"crops":{\(crops)}}
        """
    setResult(Array(json.utf8))
    return Int32(json.utf8.count)
}

@_expose(wasm, "pg_ground_arrive")
@_cdecl("pg_ground_arrive")
public func pgGroundArrive() -> Int32 {
    // The ambassador is the first planting and not an arrival, so the n-th
    // arrival is the n-th crossing whatever else has been asked of the list.
    let arrival = groundVisitor(groundWays.plantings.count - 1)
    let planting = groundWays.plant(seed: arrival.child, traits: LongWalk.traits(of: arrival.genome))
    grownInGround[planting.seed] = arrival.genome
    return Int32(planting.plot)
}

@_expose(wasm, "pg_ground_count")
@_cdecl("pg_ground_count")
public func pgGroundCount(_ plot: Int32) -> Int32 {
    Int32(groundWays.plot(Int(plot)).count)
}

@_expose(wasm, "pg_ground_grow")
@_cdecl("pg_ground_grow")
public func pgGroundGrow(_ plot: Int32, _ index: Int32) -> Int32 {
    let here = groundWays.plot(Int(plot))
    guard here.indices.contains(Int(index)),
          let genome = grownInGround[here[Int(index)].seed] else { return 0 }
    let spot = here[Int(index)].spot
    var out: [UInt8] = []
    for value in [Float(spot.x), Float(spot.z)] {
        withUnsafeBytes(of: value.bitPattern.littleEndian) { out.append(contentsOf: $0) }
    }
    out.append(contentsOf: PlantBuffer.encode(genome))
    setResult(out)
    return Int32(out.count)
}

@_expose(wasm, "pg_ground_plots")
@_cdecl("pg_ground_plots")
public func pgGroundPlots() -> Int32 {
    Int32(groundWays.plots)
}

@_expose(wasm, "pg_ground_describe")
@_cdecl("pg_ground_describe")
public func pgGroundDescribe(_ plot: Int32) -> Int32 {
    guard let json = try? JSONEncoder().encode(groundWays.plot(Int(plot))) else { return 0 }
    setResult(Array(json))
    return Int32(json.count)
}

@_expose(wasm, "pg_ground_lineage")
@_cdecl("pg_ground_lineage")
public func pgGroundLineage(_ n: Int32) -> Int32 {
    let a = groundVisitor(Int(n))
    let traits = LongWalk.traits(of: a.genome)
    let json = """
        {"seed":"\(a.child.hex)","parents":["\(a.parentA.hex)","\(a.parentB.hex)"],\
        "encounter":"\(SeedID(bytes: a.encounter)?.hex ?? "")",\
        "height":\(traits.height),"family":\(traits.family),"habit":"\(traits.habit)"}
        """
    setResult(Array(json.utf8))
    return Int32(json.utf8.count)
}
