#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif
import SeedCore

// A Seedbed for the page: the same shape as `Walk.swift`, `Quiet.swift`,
// `Cross.swift`, `Orchard.swift` and `Knot.swift`, and for the same reason — a
// template has to be judged at five hundred plants before it is live, and the
// browser is where it can be looked at.
//
//   pg_seedbed_plan()        the bed's own numbers as JSON: its side, where
//                            each of the six drills runs in x, where each of
//                            the eight places sits in z, the gaps those come
//                            from, where a label stands, and what a plot holds
//                            — so the page keeps no copy of them
//   pg_seedbed_arrive()      plants the next arrival; returns its plot
//   pg_seedbed_count(plot)   plantings in a plot so far
//   pg_seedbed_grow(plot, i) grows the i-th planting of a plot into the result:
//                            spot x, spot z (f32 each), then a plant buffer
//   pg_seedbed_plots()       plots opened so far
//   pg_seedbed_describe(p)   a plot's plantings as JSON: place and traits —
//                            including `kind`, the epithet a drill is claimed
//                            by, which is what the page prints at its head
//   pg_seedbed_label(h, w, seed)
//                            a row label into the result, in the shape
//                            `pg_hedge` and `pg_tree` already return: vertex
//                            count, index count (u32), positions, normals
//                            (3 × f32), indices (u32)
//
// Opened rather than empty: it starts with the beginnings ambassador at the
// head of the first drill, the way the real one does — so drill 0 is claimed by
// that plant's epithet before a single arrival, exactly as the service has it.
//
// `pg_seedbed_plan` carries drill and place positions where the Knot's carries
// its weave, because that is the arithmetic the page would otherwise repeat.
// The drill a plant stands in is claimed, never reserved, so there is nothing
// to report before the plants arrive; the claim is read back off `describe`,
// as the Knot's colour claim is.

nonisolated(unsafe) private var seedbedWays = Seedbed.Ways.opened()
nonisolated(unsafe) private var grownInSeedbed: [String: Genome] = {
    let one = Ambassadors.of(.beginnings)
    return [one.seed.hex: one.genome]
}()

/// The n-th arrival: two parents who meet once, and the plant they make.
private func seedbedVisitor(_ n: Int) -> (child: SeedID, genome: Genome) {
    let parentA = SeedMint.mint(fromEntropy: Data("seedbed-parent-\(n)-a".utf8))
    let parentB = SeedMint.mint(fromEntropy: Data("seedbed-parent-\(n)-b".utf8))
    let meeting = Pollination.encounterID(
        seedA: parentA, seedB: parentB, nonceA: Data("a".utf8), nonceB: Data("b".utf8)
    )
    let child = Pollination.cross(seedA: parentA, seedB: parentB, encounterID: meeting)
    return (child, Genome(seed: child,
                          lineage: .crossed(parentA: parentA, parentB: parentB, encounterID: meeting)))
}

@_expose(wasm, "pg_seedbed_plan")
@_cdecl("pg_seedbed_plan")
public func pgSeedbedPlan() -> Int32 {
    // Asked of the rule, place by place, rather than worked out again here:
    // where a drill runs and where a place sits along it are `Slot.spot`'s
    // business, and two copies of that sum drift.
    let drillX = (0..<Seedbed.drills)
        .map { "\(Seedbed.Slot(drill: $0, index: 0).spot.x)" }
        .joined(separator: ",")
    let placeZ = (0..<Seedbed.places)
        .map { "\(Seedbed.Slot(drill: 0, index: $0).spot.z)" }
        .joined(separator: ",")
    let json = """
        {"plotSide":\(Seedbed.plotSide),"drills":\(Seedbed.drills),\
        "places":\(Seedbed.places),"drillGap":\(Seedbed.drillGap),\
        "alongGap":\(Seedbed.alongGap),"labelAt":\(Seedbed.labelAt),\
        "drillX":[\(drillX)],"placeZ":[\(placeZ)],\
        "slots":\(Seedbed.slots.count)}
        """
    setResult(Array(json.utf8))
    return Int32(json.utf8.count)
}

@_expose(wasm, "pg_seedbed_arrive")
@_cdecl("pg_seedbed_arrive")
public func pgSeedbedArrive() -> Int32 {
    // Counted from the arrivals, not the plantings: the ambassador is standing
    // there and is not an arrival.
    let (child, genome) = seedbedVisitor(seedbedWays.plantings.count - 1)
    let planting = seedbedWays.plant(seed: child, traits: LongWalk.traits(of: genome))
    grownInSeedbed[planting.seed] = genome
    return Int32(planting.plot)
}

@_expose(wasm, "pg_seedbed_count")
@_cdecl("pg_seedbed_count")
public func pgSeedbedCount(_ plot: Int32) -> Int32 {
    Int32(seedbedWays.plot(Int(plot)).count)
}

@_expose(wasm, "pg_seedbed_grow")
@_cdecl("pg_seedbed_grow")
public func pgSeedbedGrow(_ plot: Int32, _ index: Int32) -> Int32 {
    let here = seedbedWays.plot(Int(plot))
    guard here.indices.contains(Int(index)),
          let genome = grownInSeedbed[here[Int(index)].seed] else { return 0 }
    let spot = here[Int(index)].spot
    var out: [UInt8] = []
    for value in [Float(spot.x), Float(spot.z)] {
        withUnsafeBytes(of: value.bitPattern.littleEndian) { out.append(contentsOf: $0) }
    }
    out.append(contentsOf: PlantBuffer.encode(genome))
    setResult(out)
    return Int32(out.count)
}

@_expose(wasm, "pg_seedbed_plots")
@_cdecl("pg_seedbed_plots")
public func pgSeedbedPlots() -> Int32 {
    Int32(seedbedWays.plots)
}

@_expose(wasm, "pg_seedbed_describe")
@_cdecl("pg_seedbed_describe")
public func pgSeedbedDescribe(_ plot: Int32) -> Int32 {
    guard let json = try? JSONEncoder().encode(seedbedWays.plot(Int(plot))) else { return 0 }
    setResult(Array(json))
    return Int32(json.count)
}

/// The label that stands at the head of a drill, from `Organic.rowLabel` — so
/// the browser's label is the shape the app draws. Stands on `y = 0` at the
/// origin, face toward `z-`: the page sets it at `drillX[d]`, `labelAt`.
@_expose(wasm, "pg_seedbed_label")
@_cdecl("pg_seedbed_label")
public func pgSeedbedLabel(_ height: Double, _ width: Double, _ seed: UInt32) -> Int32 {
    let out = seedbedStructure(Organic.rowLabel(height: height, width: width, seed: UInt64(seed)))
    setResult(out)
    return Int32(out.count)
}

/// A structure's mesh, in the shape `readHedge` in the page already reads.
private func seedbedStructure(_ mesh: StructureMesh) -> [UInt8] {
    var out: [UInt8] = []
    putSeedbed(UInt32(mesh.positions.count), &out)
    putSeedbed(UInt32(mesh.indices.count), &out)
    for p in mesh.positions { putSeedbed(p.x, &out); putSeedbed(p.y, &out); putSeedbed(p.z, &out) }
    for n in mesh.normals { putSeedbed(n.x, &out); putSeedbed(n.y, &out); putSeedbed(n.z, &out) }
    for i in mesh.indices { putSeedbed(i, &out) }
    return out
}

private func putSeedbed(_ value: UInt32, _ out: inout [UInt8]) {
    withUnsafeBytes(of: value.littleEndian) { out.append(contentsOf: $0) }
}

private func putSeedbed(_ value: Float, _ out: inout [UInt8]) {
    putSeedbed(value.bitPattern, &out)
}
