#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif
import SeedCore

// A Glasshouse for the page: the same shape as `Frame.swift` and `Seedbed.swift`,
// and for the same reason — a template has to be judged at five hundred plants
// before it is live, and the browser is where it can be looked at.
//
//   pg_glasshouse_plan()          the area's own numbers as JSON: its side, the
//                                 house's length, width, eaves and ridge, the
//                                 staging's middle, depth and top, how far a
//                                 potted plant stands off the floor, the border's
//                                 line, and what a plot holds — so the page
//                                 keeps no copy of them
//   pg_glasshouse_arrive()        plants the next arrival; returns its plot
//   pg_glasshouse_count(plot)     plantings in a plot so far
//   pg_glasshouse_grow(plot, i)   grows the i-th planting of a plot into the
//                                 result: spot x, spot z and lift (f32 each),
//                                 then a plant buffer
//   pg_glasshouse_plots()         plots opened so far
//   pg_glasshouse_describe(p)     a plot's plantings as JSON: place and traits
//   pg_glasshouse_frame(seed)     the house's bars and its open door,
//   pg_glasshouse_glass(seed)     its glass,
//   pg_glasshouse_staging(seed)   the staging,
//   pg_glasshouse_pot(seed)       one clay pot,
//   pg_glasshouse_soil(seed)      and the soil in it — each in the shape
//                                 `pg_hedge` returns: vertex count, index count
//                                 (u32), positions, normals (3 × f32), indices
//                                 (u32)
//
// **The plants are grown at their best**, as everywhere but the Cold Frame, by
// `pg_grow` and `pg_grow_hybrid` for the page drawing what the service holds.
// What is new is where they stand: three in four of them in a pot on the
// staging, 0.83 m off the floor, which is why a planting here carries a lift.
//
// Opened rather than empty: it starts with the light ambassador potted at its
// own band, the way the real one does.

nonisolated(unsafe) private var glasshouseWays = Glasshouse.Ways.opened()
nonisolated(unsafe) private var grownInGlasshouse: [String: Genome] = {
    let one = Ambassadors.of(.light)
    return [one.seed.hex: one.genome]
}()
nonisolated(unsafe) private var glasshouseCrossings = 0

/// The next arrival: the next crossing whose name puts it in the Glasshouse.
///
/// **Only this area's plants, as `GlasshouseTests` draws them**, because the
/// border's cut and the staging's bands were measured over those. A workbench of
/// any crossing would fill the staging's bands unevenly and show a spectrum
/// nobody will see.
private func glasshouseVisitor() -> (child: SeedID, genome: Genome) {
    while true {
        let n = glasshouseCrossings
        glasshouseCrossings += 1
        let parentA = SeedMint.mint(fromEntropy: Data("glasshouse-parent-\(n)-a".utf8))
        let parentB = SeedMint.mint(fromEntropy: Data("glasshouse-parent-\(n)-b".utf8))
        let meeting = Pollination.encounterID(
            seedA: parentA, seedB: parentB, nonceA: Data("a".utf8), nonceB: Data("b".utf8)
        )
        let child = Pollination.cross(seedA: parentA, seedB: parentB, encounterID: meeting)
        let genome = Genome(seed: child,
                            lineage: .crossed(parentA: parentA, parentB: parentB, encounterID: meeting))
        if Area(genome: genome) == .light { return (child, genome) }
    }
}

@_expose(wasm, "pg_glasshouse_plan")
@_cdecl("pg_glasshouse_plan")
public func pgGlasshousePlan() -> Int32 {
    let json = """
        {"plotSide":\(Glasshouse.plotSide),"length":\(Glasshouse.houseLength),\
        "width":\(Glasshouse.houseWidth),"eaves":\(Glasshouse.eaves),"ridge":\(Glasshouse.ridge),\
        "stagingZ":\(Glasshouse.stagingZ),"stagingDepth":\(Glasshouse.stagingDepth),\
        "stagingTop":\(Glasshouse.stagingTop),"lift":\(Glasshouse.stagingTop + Glasshouse.potSoil),\
        "borderZ":\(Glasshouse.borderZ),"borderGap":\(Glasshouse.borderGap),\
        "borderPlaces":\(Glasshouse.borderPlaces),"positions":\(Glasshouse.positions),\
        "borderFrom":\(Glasshouse.borderFrom),"slots":\(Glasshouse.slots.count)}
        """
    setResult(Array(json.utf8))
    return Int32(json.utf8.count)
}

@_expose(wasm, "pg_glasshouse_arrive")
@_cdecl("pg_glasshouse_arrive")
public func pgGlasshouseArrive() -> Int32 {
    let (child, genome) = glasshouseVisitor()
    let planting = glasshouseWays.plant(seed: child, traits: LongWalk.traits(of: genome))
    grownInGlasshouse[planting.seed] = genome
    return Int32(planting.plot)
}

@_expose(wasm, "pg_glasshouse_count")
@_cdecl("pg_glasshouse_count")
public func pgGlasshouseCount(_ plot: Int32) -> Int32 {
    Int32(glasshouseWays.plot(Int(plot)).count)
}

@_expose(wasm, "pg_glasshouse_grow")
@_cdecl("pg_glasshouse_grow")
public func pgGlasshouseGrow(_ plot: Int32, _ index: Int32) -> Int32 {
    let here = glasshouseWays.plot(Int(plot))
    guard here.indices.contains(Int(index)),
          let genome = grownInGlasshouse[here[Int(index)].seed] else { return 0 }
    let planting = here[Int(index)]
    var out: [UInt8] = []
    putGlasshouse(Float(planting.spot.x), &out)
    putGlasshouse(Float(planting.spot.z), &out)
    putGlasshouse(Float(planting.slot.lift), &out)
    out.append(contentsOf: PlantBuffer.encode(genome))
    setResult(out)
    return Int32(out.count)
}

@_expose(wasm, "pg_glasshouse_plots")
@_cdecl("pg_glasshouse_plots")
public func pgGlasshousePlots() -> Int32 {
    Int32(glasshouseWays.plots)
}

@_expose(wasm, "pg_glasshouse_describe")
@_cdecl("pg_glasshouse_describe")
public func pgGlasshouseDescribe(_ plot: Int32) -> Int32 {
    guard let json = try? JSONEncoder().encode(glasshouseWays.plot(Int(plot))) else { return 0 }
    setResult(Array(json))
    return Int32(json.count)
}

@_expose(wasm, "pg_glasshouse_frame")
@_cdecl("pg_glasshouse_frame")
public func pgGlasshouseFrame(_ seed: UInt32) -> Int32 {
    let out = glasshouseStructure(Organic.spanHouse(seed: UInt64(seed)))
    setResult(out)
    return Int32(out.count)
}

@_expose(wasm, "pg_glasshouse_glass")
@_cdecl("pg_glasshouse_glass")
public func pgGlasshouseGlass(_ seed: UInt32) -> Int32 {
    let out = glasshouseStructure(Organic.spanHouseGlass(seed: UInt64(seed)))
    setResult(out)
    return Int32(out.count)
}

@_expose(wasm, "pg_glasshouse_staging")
@_cdecl("pg_glasshouse_staging")
public func pgGlasshouseStaging(_ seed: UInt32) -> Int32 {
    let out = glasshouseStructure(Organic.staging(seed: UInt64(seed)))
    setResult(out)
    return Int32(out.count)
}

@_expose(wasm, "pg_glasshouse_pot")
@_cdecl("pg_glasshouse_pot")
public func pgGlasshousePot(_ seed: UInt32) -> Int32 {
    let out = glasshouseStructure(Organic.pot(seed: UInt64(seed)))
    setResult(out)
    return Int32(out.count)
}

@_expose(wasm, "pg_glasshouse_soil")
@_cdecl("pg_glasshouse_soil")
public func pgGlasshouseSoil(_ seed: UInt32) -> Int32 {
    let out = glasshouseStructure(Organic.potSoil(seed: UInt64(seed)))
    setResult(out)
    return Int32(out.count)
}

/// A structure's mesh, in the shape `readStructure` in the page already reads.
private func glasshouseStructure(_ mesh: StructureMesh) -> [UInt8] {
    var out: [UInt8] = []
    putGlasshouse(UInt32(mesh.positions.count), &out)
    putGlasshouse(UInt32(mesh.indices.count), &out)
    for p in mesh.positions { putGlasshouse(p.x, &out); putGlasshouse(p.y, &out); putGlasshouse(p.z, &out) }
    for n in mesh.normals { putGlasshouse(n.x, &out); putGlasshouse(n.y, &out); putGlasshouse(n.z, &out) }
    for i in mesh.indices { putGlasshouse(i, &out) }
    return out
}

private func putGlasshouse(_ value: UInt32, _ out: inout [UInt8]) {
    withUnsafeBytes(of: value.littleEndian) { out.append(contentsOf: $0) }
}

private func putGlasshouse(_ value: Float, _ out: inout [UInt8]) {
    putGlasshouse(value.bitPattern, &out)
}
