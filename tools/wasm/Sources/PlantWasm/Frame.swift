#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif
import SeedCore

// A Cold Frame for the page: the same shape as `Seedbed.swift` and `Knot.swift`,
// and for the same reason — a template has to be judged at five hundred plants
// before it is live, and the browser is where it can be looked at.
//
//   pg_frame_plan()          the area's own numbers as JSON: its side, the
//                            frames' middles, a frame's length, depth and walls,
//                            how far its lights are propped, where the ranks
//                            and places stand, and what a plot holds — so the
//                            page keeps no copy of them
//   pg_frame_arrive()        plants the next arrival; returns its plot
//   pg_frame_count(plot)     plantings in a plot so far
//   pg_frame_grow(plot, i)   grows the i-th planting of a plot, **young**, into
//                            the result: spot x, spot z (f32 each) — a lotus's
//                            the middle of its two places — then a plant buffer
//   pg_frame_plots()         plots opened so far
//   pg_frame_describe(p)     a plot's plantings as JSON: place, span (two for
//                            a lotus, since 25 September 2026) and traits
//   pg_frame_box(seed)       a frame's box of boards,
//   pg_frame_lights(seed)    its lights' bars and the blocks they are propped on,
//   pg_frame_glass(seed)     and the glass in them — each in the shape `pg_hedge`
//                            returns: vertex count, index count (u32),
//                            positions, normals (3 × f32), indices (u32)
//   pg_grow_young(t, n)      `pg_grow` and `pg_grow_hybrid` at `ColdFrame.drawn`,
//   pg_grow_hybrid_young(t, n)
//                            for the page drawing what the service holds
//
// **Every plant here is drawn young.** That is the whole of what the area adds
// to the module: the same plant buffer as everywhere else, built at
// `ColdFrame.drawn` instead of at the plant's best. Where it stands was decided
// by the height it will grow to; what the page shows is the height it is now.
//
// Opened rather than empty: it starts with the waiting ambassador, a lotus, at
// the pond's deepest point, the way the real one does.

nonisolated(unsafe) private var frameWays = ColdFrame.Ways.opened()
nonisolated(unsafe) private var grownInFrame: [String: Genome] = {
    let one = Ambassadors.of(.waiting)
    return [one.seed.hex: one.genome]
}()
nonisolated(unsafe) private var frameCrossings = 0

/// The next arrival: the next crossing whose name puts it in the Cold Frame.
///
/// **Only this area's plants, as `ColdFrameTests` draws them**, because the
/// cut is the median of those. A workbench of any crossing would stand two
/// thirds of its plants at the back and show a rule nobody will see run.
private func frameVisitor() -> (child: SeedID, genome: Genome) {
    while true {
        let n = frameCrossings
        frameCrossings += 1
        let parentA = SeedMint.mint(fromEntropy: Data("frame-parent-\(n)-a".utf8))
        let parentB = SeedMint.mint(fromEntropy: Data("frame-parent-\(n)-b".utf8))
        let meeting = Pollination.encounterID(
            seedA: parentA, seedB: parentB, nonceA: Data("a".utf8), nonceB: Data("b".utf8)
        )
        let child = Pollination.cross(seedA: parentA, seedB: parentB, encounterID: meeting)
        let genome = Genome(seed: child,
                            lineage: .crossed(parentA: parentA, parentB: parentB, encounterID: meeting))
        if Area(genome: genome) == .waiting { return (child, genome) }
    }
}

@_expose(wasm, "pg_frame_plan")
@_cdecl("pg_frame_plan")
public func pgFramePlan() -> Int32 {
    // Asked of the rule rather than worked out again here: where a frame
    // stands and where a place sits in it are `Frame.centre` and `Slot.spot`.
    // The frames in use only: the back row since 29 September 2026. The pond
    // is not a frame and is not sent: its outline and places are the table's
    // (`tables/cold_frame_pond.js`), and a plot's mirror is `pg_plot_variant`'s.
    // A retired front frame is not sent at all.
    let frames = ColdFrame.frames
        .map { "[\($0.centre.x),\($0.centre.z)]" }
        .joined(separator: ",")
    let placeX = (0..<ColdFrame.places)
        .map { "\(ColdFrame.Slot(frame: .backWest, rank: .front, index: $0).spot.x - ColdFrame.Frame.backWest.centre.x)" }
        .joined(separator: ",")
    let json = """
        {"plotSide":\(ColdFrame.plotSide),"frames":[\(frames)],\
        "length":\(ColdFrame.frameLength),"depth":\(ColdFrame.frameDepth),\
        "backWall":\(ColdFrame.backWall),"frontWall":\(ColdFrame.frontWall),\
        "propped":\(ColdFrame.propped),"places":\(ColdFrame.places),\
        "rankFrom":\(ColdFrame.rankFrom),"placeX":[\(placeX)],\
        "backFrom":\(ColdFrame.backFrom),"slots":\(ColdFrame.slots.count)}
        """
    setResult(Array(json.utf8))
    return Int32(json.utf8.count)
}

@_expose(wasm, "pg_frame_arrive")
@_cdecl("pg_frame_arrive")
public func pgFrameArrive() -> Int32 {
    let (child, genome) = frameVisitor()
    let planting = frameWays.plant(seed: child, traits: LongWalk.traits(of: genome))
    grownInFrame[planting.seed] = genome
    return Int32(planting.plot)
}

@_expose(wasm, "pg_frame_count")
@_cdecl("pg_frame_count")
public func pgFrameCount(_ plot: Int32) -> Int32 {
    Int32(frameWays.plot(Int(plot)).count)
}

@_expose(wasm, "pg_frame_grow")
@_cdecl("pg_frame_grow")
public func pgFrameGrow(_ plot: Int32, _ index: Int32) -> Int32 {
    let here = frameWays.plot(Int(plot))
    guard here.indices.contains(Int(index)),
          let genome = grownInFrame[here[Int(index)].seed] else { return 0 }
    let spot = here[Int(index)].spot
    var out: [UInt8] = []
    putFrame(Float(spot.x), &out)
    putFrame(Float(spot.z), &out)
    out.append(contentsOf: PlantBuffer.encode(genome, growth: ColdFrame.drawn))
    setResult(out)
    return Int32(out.count)
}

@_expose(wasm, "pg_frame_plots")
@_cdecl("pg_frame_plots")
public func pgFramePlots() -> Int32 {
    Int32(frameWays.plots)
}

@_expose(wasm, "pg_frame_describe")
@_cdecl("pg_frame_describe")
public func pgFrameDescribe(_ plot: Int32) -> Int32 {
    guard let json = try? JSONEncoder().encode(frameWays.plot(Int(plot))) else { return 0 }
    setResult(Array(json))
    return Int32(json.count)
}

@_expose(wasm, "pg_frame_box")
@_cdecl("pg_frame_box")
public func pgFrameBox(_ seed: UInt32) -> Int32 {
    let out = frameStructure(Organic.coldFrame(seed: UInt64(seed)))
    setResult(out)
    return Int32(out.count)
}

@_expose(wasm, "pg_frame_lights")
@_cdecl("pg_frame_lights")
public func pgFrameLights(_ seed: UInt32) -> Int32 {
    let out = frameStructure(Organic.frameLights(seed: UInt64(seed)))
    setResult(out)
    return Int32(out.count)
}

@_expose(wasm, "pg_frame_glass")
@_cdecl("pg_frame_glass")
public func pgFrameGlass(_ seed: UInt32) -> Int32 {
    let out = frameStructure(Organic.frameGlass(seed: UInt64(seed)))
    setResult(out)
    return Int32(out.count)
}

/// `pg_grow`, young: a minted plant — the ambassador — at `ColdFrame.drawn`.
@_expose(wasm, "pg_grow_young")
@_cdecl("pg_grow_young")
public func pgGrowYoung(_ text: UnsafePointer<UInt8>, _ length: Int32) -> Int32 {
    let hex = String(decoding: UnsafeBufferPointer(start: text, count: Int(length)), as: UTF8.self)
    guard let seed = SeedID(hex: hex) else { return 0 }
    let out = PlantBuffer.encode(Genome(seed: seed), growth: ColdFrame.drawn)
    setResult(out)
    return Int32(out.count)
}

/// `pg_grow_hybrid`, young: a crossed plant from "seed parentA parentB
/// encounter", as the page reads it off the service, at `ColdFrame.drawn`.
@_expose(wasm, "pg_grow_hybrid_young")
@_cdecl("pg_grow_hybrid_young")
public func pgGrowHybridYoung(_ text: UnsafePointer<UInt8>, _ length: Int32) -> Int32 {
    let words = String(decoding: UnsafeBufferPointer(start: text, count: Int(length)), as: UTF8.self)
        .split(separator: " ").map(String.init)
    guard words.count == 4,
          let child = SeedID(hex: words[0]), let parentA = SeedID(hex: words[1]),
          let parentB = SeedID(hex: words[2]), let encounter = SeedID(hex: words[3])?.bytes else { return 0 }
    let genome = Genome(seed: child, lineage: .crossed(parentA: parentA, parentB: parentB, encounterID: encounter))
    let out = PlantBuffer.encode(genome, growth: ColdFrame.drawn)
    setResult(out)
    return Int32(out.count)
}

/// A structure's mesh, in the shape `readStructure` in the page already reads.
private func frameStructure(_ mesh: StructureMesh) -> [UInt8] {
    var out: [UInt8] = []
    putFrame(UInt32(mesh.positions.count), &out)
    putFrame(UInt32(mesh.indices.count), &out)
    for p in mesh.positions { putFrame(p.x, &out); putFrame(p.y, &out); putFrame(p.z, &out) }
    for n in mesh.normals { putFrame(n.x, &out); putFrame(n.y, &out); putFrame(n.z, &out) }
    for i in mesh.indices { putFrame(i, &out) }
    return out
}

private func putFrame(_ value: UInt32, _ out: inout [UInt8]) {
    withUnsafeBytes(of: value.littleEndian) { out.append(contentsOf: $0) }
}

private func putFrame(_ value: Float, _ out: inout [UInt8]) {
    putFrame(value.bitPattern, &out)
}
