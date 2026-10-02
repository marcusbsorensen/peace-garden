#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif
import SeedCore

// A Coppice for the page: the same shape as `Glasshouse.swift` and `Frame.swift`,
// and for the same reason — a template has to be judged at five hundred plants
// before it is live, and the browser is where it can be looked at.
//
//   pg_coppice_plan()             the area's own numbers as JSON: its side, the
//                                 rides' width and wander, how high and wide a
//                                 stool is, the floor's cut, and what a plot
//                                 holds — so the page keeps no copy of them
//   pg_coppice_layout(p)          plot p as it is laid, as JSON: its variant, the
//                                 glade's outline, the three rides' centre lines,
//                                 each coupe's ground and the spring, all turned
//                                 for the plot
//   pg_coppice_arrive()           plants the next arrival; returns its plot
//   pg_coppice_count(plot)        plantings in a plot so far
//   pg_coppice_grow(plot, i, y)   grows the i-th planting of a plot as it stands
//                                 in year `y` into the result: spot x, spot z and
//                                 stage (f32 each, the stage −1 for a planting
//                                 drawn at its best), its stool's seed (u32),
//                                 then a plant buffer
//   pg_coppice_stage(p, c, y)     the stage of coupe `c` of plot `p` in year `y`
//   pg_coppice_plots()            plots opened so far
//   pg_coppice_describe(p)        a plot's plantings as JSON: place and traits
//   pg_coppice_lineage(n)         the n-th of the workbench's arrivals as a phone
//                                 would send it to the plot service, as JSON:
//                                 seed, parents, encounter, height, family, habit
//   pg_coppice_relief(x, z, seed) the woodland floor's rise and fall there, in
//                                 −1...1, for the page to scale
//   pg_coppice_stool(seed)        a stool's bark,
//   pg_coppice_face(seed)         and its cut face — each in the shape
//                                 `pg_hedge` returns: vertex count, index count
//                                 (u32), positions, normals (3 × f32), indices
//                                 (u32)
//   pg_coppice_footprint(seed)    where that stool meets the ground: point count
//                                 (u32), then x, z (f32) per point, as
//                                 `pg_outline` answers
//   pg_grow_coppiced(t, n, s)     `pg_grow` and `pg_grow_hybrid` at a stage of
//   pg_grow_hybrid_coppiced(t, n, s)
//                                 the rotation — 0 cut, 1 regrowing, anything
//                                 else at its best — for the page drawing what
//                                 the service holds
//
// **Only a fern on a stool is drawn young**, and how young is its coupe's
// stage: `Coppice.cutDrawn`, `Coppice.regrowingDrawn`, or at its best. The
// service sends the stage beside the spot, so the page asks the module for the
// plant at that stage and never works one out from a date.
//
// Opened rather than empty: it starts with the renewal ambassador on the first
// coupe's middle stool (a fern since 28 September 2026), the way the real one
// does.

nonisolated(unsafe) private var coppiceWays = Coppice.Ways.opened()
nonisolated(unsafe) private var grownInCoppice: [String: Genome] = {
    let one = Ambassadors.of(.renewal)
    return [one.seed.hex: one.genome]
}()

/// The workbench's crossings that land in the Coppice, found as they are asked
/// for and kept, so `pg_coppice_lineage` and `pg_coppice_arrive` name the same
/// n-th plant without starting the search again.
nonisolated(unsafe) private var coppiceFound: [(child: SeedID, parentA: SeedID, parentB: SeedID,
                                                 encounter: Data, genome: Genome)] = []
nonisolated(unsafe) private var coppiceCrossings = 0

/// The n-th crossing whose name puts it in the Coppice.
///
/// **Only this area's plants, as `CoppiceTests` draws them**, because the
/// back row's cut is the median of this area's stars and the stools wait for
/// its ferns. A workbench of any crossing would put a fern in half the Long
/// Walk's plants and none of the rest.
private func coppiceVisitor(_ n: Int) -> (child: SeedID, parentA: SeedID, parentB: SeedID,
                                          encounter: Data, genome: Genome) {
    while coppiceFound.count <= n {
        let k = coppiceCrossings
        coppiceCrossings += 1
        let parentA = SeedMint.mint(fromEntropy: Data("coppice-parent-\(k)-a".utf8))
        let parentB = SeedMint.mint(fromEntropy: Data("coppice-parent-\(k)-b".utf8))
        let meeting = Pollination.encounterID(
            seedA: parentA, seedB: parentB, nonceA: Data("a".utf8), nonceB: Data("b".utf8)
        )
        let child = Pollination.cross(seedA: parentA, seedB: parentB, encounterID: meeting)
        let genome = Genome(seed: child,
                            lineage: .crossed(parentA: parentA, parentB: parentB, encounterID: meeting))
        if Area(genome: genome) == .renewal { coppiceFound.append((child, parentA, parentB, meeting, genome)) }
    }
    return coppiceFound[n]
}

/// A stage as the page sends it: 0 cut, 1 regrowing, and anything else — the
/// service's `null`, sent as −1 — at its best.
private func coppiceDrawn(_ stage: Int32) -> GrowthModel.State? {
    switch stage {
    case 0: return Coppice.cutDrawn
    case 1: return Coppice.regrowingDrawn
    default: return nil
    }
}

@_expose(wasm, "pg_coppice_plan")
@_cdecl("pg_coppice_plan")
public func pgCoppicePlan() -> Int32 {
    let json = """
        {"plotSide":\(Coppice.plotSide),"coupes":\(Coppice.coupes),\
        "rideWidth":\(Coppice.rideWidth),"rideWander":\(Coppice.rideWander),\
        "stoolHeight":\(Coppice.stoolHeight),\
        "stoolAcross":[\(Coppice.stoolAcross.lowerBound),\(Coppice.stoolAcross.upperBound)],\
        "backFrom":\(Coppice.backFrom),"slots":\(Coppice.slots.count)}
        """
    setResult(Array(json.utf8))
    return Int32(json.utf8.count)
}

/// **Plot `plot` as it is laid**, as JSON, so the page draws the wood from the
/// rule's own table rather than from a copy of it: the plot's variant
/// (`[turn, mirror, nudge]`), the glade's outline, the three rides' centre
/// lines (each from the glade's middle out past the rim), each coupe's ground
/// and the spring's middle — every point already turned for the plot, as the
/// service turns the plants'. A pure function of the plot's number.
@_expose(wasm, "pg_coppice_layout")
@_cdecl("pg_coppice_layout")
public func pgCoppiceLayout(_ plot: Int32) -> Int32 {
    let variant = Coppice.variant(ofPlot: Int(plot))
    func point(_ s: Spot) -> String { "[\(s.x),\(s.z)]" }
    func line(_ points: [Spot]) -> String { "[" + points.map(point).joined(separator: ",") + "]" }
    let json = """
        {"variant":[\(variant.turn),\(variant.mirror ? 1 : 0),\(variant.nudge)],\
        "glade":\(line(Coppice.glade(on: variant))),\
        "rides":[\(Coppice.rides(on: variant).map(line).joined(separator: ","))],\
        "grounds":[\(Coppice.grounds(on: variant).map(line).joined(separator: ","))],\
        "spring":\(point(Coppice.spring(on: variant)))}
        """
    setResult(Array(json.utf8))
    return Int32(json.utf8.count)
}

@_expose(wasm, "pg_coppice_arrive")
@_cdecl("pg_coppice_arrive")
public func pgCoppiceArrive() -> Int32 {
    // The ambassador is the first planting and not an arrival, so the n-th
    // arrival is the n-th crossing whatever else has been asked of the list.
    let arrival = coppiceVisitor(coppiceWays.plantings.count - 1)
    let planting = coppiceWays.plant(seed: arrival.child, traits: LongWalk.traits(of: arrival.genome))
    grownInCoppice[planting.seed] = arrival.genome
    return Int32(planting.plot)
}

@_expose(wasm, "pg_coppice_count")
@_cdecl("pg_coppice_count")
public func pgCoppiceCount(_ plot: Int32) -> Int32 {
    Int32(coppiceWays.plot(Int(plot)).count)
}

@_expose(wasm, "pg_coppice_grow")
@_cdecl("pg_coppice_grow")
public func pgCoppiceGrow(_ plot: Int32, _ index: Int32, _ year: Int32) -> Int32 {
    let here = coppiceWays.plot(Int(plot))
    guard here.indices.contains(Int(index)),
          let genome = grownInCoppice[here[Int(index)].seed] else { return 0 }
    let planting = here[Int(index)]
    let stage = planting.slot.place == .stool
        ? Float(Coppice.stage(plot: planting.plot, coupe: planting.slot.coupe, year: Int(year)).rawValue)
        : -1
    var out: [UInt8] = []
    putCoppice(Float(planting.spot.x), &out)
    putCoppice(Float(planting.spot.z), &out)
    putCoppice(stage, &out)
    putCoppice(UInt32(truncatingIfNeeded: planting.stoolSeed), &out)
    out.append(contentsOf: PlantBuffer.encode(genome, growth: Coppice.drawn(planting, year: Int(year))))
    setResult(out)
    return Int32(out.count)
}

@_expose(wasm, "pg_coppice_stage")
@_cdecl("pg_coppice_stage")
public func pgCoppiceStage(_ plot: Int32, _ coupe: Int32, _ year: Int32) -> Int32 {
    Int32(Coppice.stage(plot: Int(plot), coupe: Int(coupe), year: Int(year)).rawValue)
}

@_expose(wasm, "pg_coppice_plots")
@_cdecl("pg_coppice_plots")
public func pgCoppicePlots() -> Int32 {
    Int32(coppiceWays.plots)
}

@_expose(wasm, "pg_coppice_describe")
@_cdecl("pg_coppice_describe")
public func pgCoppiceDescribe(_ plot: Int32) -> Int32 {
    guard let json = try? JSONEncoder().encode(coppiceWays.plot(Int(plot))) else { return 0 }
    setResult(Array(json))
    return Int32(json.count)
}

@_expose(wasm, "pg_coppice_lineage")
@_cdecl("pg_coppice_lineage")
public func pgCoppiceLineage(_ n: Int32) -> Int32 {
    let a = coppiceVisitor(Int(n))
    let traits = LongWalk.traits(of: a.genome)
    let json = """
        {"seed":"\(a.child.hex)","parents":["\(a.parentA.hex)","\(a.parentB.hex)"],\
        "encounter":"\(SeedID(bytes: a.encounter)?.hex ?? "")",\
        "height":\(traits.height),"family":\(traits.family),"habit":"\(traits.habit)"}
        """
    setResult(Array(json.utf8))
    return Int32(json.utf8.count)
}

/// The floor's rise and fall: `Organic`'s surface noise at a metre and a half,
/// so a stool's width is on one slope and a coupe's length has two or three.
@_expose(wasm, "pg_coppice_relief")
@_cdecl("pg_coppice_relief")
public func pgCoppiceRelief(_ x: Double, _ z: Double, _ seed: UInt32) -> Double {
    Organic.wobble(x, z, wavelength: 1.5, seed: UInt64(seed))
}

@_expose(wasm, "pg_coppice_stool")
@_cdecl("pg_coppice_stool")
public func pgCoppiceStool(_ seed: UInt32) -> Int32 {
    let out = coppiceStructure(Organic.stool(seed: UInt64(seed)))
    setResult(out)
    return Int32(out.count)
}

@_expose(wasm, "pg_coppice_face")
@_cdecl("pg_coppice_face")
public func pgCoppiceFace(_ seed: UInt32) -> Int32 {
    let out = coppiceStructure(Organic.stoolFace(seed: UInt64(seed)))
    setResult(out)
    return Int32(out.count)
}

@_expose(wasm, "pg_coppice_footprint")
@_cdecl("pg_coppice_footprint")
public func pgCoppiceFootprint(_ seed: UInt32) -> Int32 {
    let points = Organic.stoolFootprint(seed: UInt64(seed))
    var out: [UInt8] = []
    putCoppice(UInt32(points.count), &out)
    for p in points { putCoppice(Float(p.x), &out); putCoppice(Float(p.z), &out) }
    setResult(out)
    return Int32(out.count)
}

/// `pg_grow` at a stage: a minted plant — the ambassador, a fern on a stool
/// since 28 September 2026 and so drawn at its coupe's stage — for the page
/// drawing what the service holds.
@_expose(wasm, "pg_grow_coppiced")
@_cdecl("pg_grow_coppiced")
public func pgGrowCoppiced(_ text: UnsafePointer<UInt8>, _ length: Int32, _ stage: Int32) -> Int32 {
    let hex = String(decoding: UnsafeBufferPointer(start: text, count: Int(length)), as: UTF8.self)
    guard let seed = SeedID(hex: hex) else { return 0 }
    let out = PlantBuffer.encode(Genome(seed: seed), growth: coppiceDrawn(stage))
    setResult(out)
    return Int32(out.count)
}

/// `pg_grow_hybrid` at a stage: a crossed plant from "seed parentA parentB
/// encounter", as the page reads it off the service.
@_expose(wasm, "pg_grow_hybrid_coppiced")
@_cdecl("pg_grow_hybrid_coppiced")
public func pgGrowHybridCoppiced(_ text: UnsafePointer<UInt8>, _ length: Int32, _ stage: Int32) -> Int32 {
    let words = String(decoding: UnsafeBufferPointer(start: text, count: Int(length)), as: UTF8.self)
        .split(separator: " ").map(String.init)
    guard words.count == 4,
          let child = SeedID(hex: words[0]), let parentA = SeedID(hex: words[1]),
          let parentB = SeedID(hex: words[2]), let encounter = SeedID(hex: words[3])?.bytes else { return 0 }
    let genome = Genome(seed: child, lineage: .crossed(parentA: parentA, parentB: parentB, encounterID: encounter))
    let out = PlantBuffer.encode(genome, growth: coppiceDrawn(stage))
    setResult(out)
    return Int32(out.count)
}

/// A structure's mesh, in the shape `readStructure` in the page already reads.
private func coppiceStructure(_ mesh: StructureMesh) -> [UInt8] {
    var out: [UInt8] = []
    putCoppice(UInt32(mesh.positions.count), &out)
    putCoppice(UInt32(mesh.indices.count), &out)
    for p in mesh.positions { putCoppice(p.x, &out); putCoppice(p.y, &out); putCoppice(p.z, &out) }
    for n in mesh.normals { putCoppice(n.x, &out); putCoppice(n.y, &out); putCoppice(n.z, &out) }
    for i in mesh.indices { putCoppice(i, &out) }
    return out
}

private func putCoppice(_ value: UInt32, _ out: inout [UInt8]) {
    withUnsafeBytes(of: value.littleEndian) { out.append(contentsOf: $0) }
}

private func putCoppice(_ value: Float, _ out: inout [UInt8]) {
    putCoppice(value.bitPattern, &out)
}
