#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif
import SeedCore

// A Quiet Garden for the page: the same shape as `Walk.swift` and for the same
// reason — a template has to be judged at five hundred plants before it is live,
// and the browser is where it can be looked at.
//
//   pg_room_plan()        the room's own numbers as JSON: the plot's side, where
//                         the hedge stands, where the bench stands, and what a
//                         plot holds — so the page keeps no copy of them
//   pg_room_arrive()      plants the next arrival; returns its plot
//   pg_room_count(plot)   plantings in a plot so far
//   pg_room_grow(plot, i) grows the i-th planting of a plot into the result:
//                         spot x, spot z (f32 each), then a plant buffer
//   pg_room_plots()       plots opened so far
//   pg_room_describe(p)   a plot's plantings as JSON: slot and traits, for
//                         judging how the rule fills a room
//
// Opened rather than empty: the room starts with its ambassador (Bela caerulea
// since 28 September 2026) beside the bench, the way the real one does.
//
// **Only this area's own plants arrive**, since 2 October 2026, as the Cold
// Frame's workbench and `tools/layouts/harness` draw them: the crossings whose
// names put them in the Quiet Garden, plumes and poppies. Before then every
// crossing came here, and the pool held the lilies the live garden never
// sends this area. The room's places, its pool and its stones are the table's
// (`tables/quiet_room.js`), and a room's variant is `pg_plot_variant`'s.

nonisolated(unsafe) private var room = QuietGarden.Room.opened()
nonisolated(unsafe) private var grown: [String: Genome] = {
    let one = Ambassadors.of(.peace)
    return [one.seed.hex: one.genome]
}()

nonisolated(unsafe) private var roomCrossings = 0

/// The next arrival: the next crossing whose name puts it in the Quiet Garden.
private func visitor() -> (child: SeedID, genome: Genome) {
    while true {
        let n = roomCrossings
        roomCrossings += 1
        let parentA = SeedMint.mint(fromEntropy: Data("quiet-garden-parent-\(n)-a".utf8))
        let parentB = SeedMint.mint(fromEntropy: Data("quiet-garden-parent-\(n)-b".utf8))
        let meeting = Pollination.encounterID(
            seedA: parentA, seedB: parentB, nonceA: Data("a".utf8), nonceB: Data("b".utf8)
        )
        let child = Pollination.cross(seedA: parentA, seedB: parentB, encounterID: meeting)
        let genome = Genome(seed: child,
                            lineage: .crossed(parentA: parentA, parentB: parentB, encounterID: meeting))
        if Area(genome: genome) == .peace { return (child, genome) }
    }
}

@_expose(wasm, "pg_room_plan")
@_cdecl("pg_room_plan")
public func pgRoomPlan() -> Int32 {
    let bench = QuietGarden.benchSpot
    let json = """
        {"plotSide":\(QuietGarden.plotSide),"hedgeFrom":\(QuietGarden.hedgeFrom),\
        "bench":[\(bench.x),\(bench.z)],"slots":\(QuietGarden.slots.count)}
        """
    setResult(Array(json.utf8))
    return Int32(json.utf8.count)
}

@_expose(wasm, "pg_room_arrive")
@_cdecl("pg_room_arrive")
public func pgRoomArrive() -> Int32 {
    let (child, genome) = visitor()
    let planting = room.plant(seed: child, traits: LongWalk.traits(of: genome))
    grown[planting.seed] = genome
    return Int32(planting.plot)
}

@_expose(wasm, "pg_room_count")
@_cdecl("pg_room_count")
public func pgRoomCount(_ plot: Int32) -> Int32 {
    Int32(room.plot(Int(plot)).count)
}

@_expose(wasm, "pg_room_grow")
@_cdecl("pg_room_grow")
public func pgRoomGrow(_ plot: Int32, _ index: Int32) -> Int32 {
    let here = room.plot(Int(plot))
    guard here.indices.contains(Int(index)), let genome = grown[here[Int(index)].seed] else { return 0 }
    let spot = here[Int(index)].spot
    var out: [UInt8] = []
    for value in [Float(spot.x), Float(spot.z)] {
        withUnsafeBytes(of: value.bitPattern.littleEndian) { out.append(contentsOf: $0) }
    }
    out.append(contentsOf: PlantBuffer.encode(genome))
    setResult(out)
    return Int32(out.count)
}

@_expose(wasm, "pg_room_plots")
@_cdecl("pg_room_plots")
public func pgRoomPlots() -> Int32 {
    Int32(room.plots)
}

@_expose(wasm, "pg_room_describe")
@_cdecl("pg_room_describe")
public func pgRoomDescribe(_ plot: Int32) -> Int32 {
    guard let json = try? JSONEncoder().encode(room.plot(Int(plot))) else { return 0 }
    setResult(Array(json))
    return Int32(json.count)
}
