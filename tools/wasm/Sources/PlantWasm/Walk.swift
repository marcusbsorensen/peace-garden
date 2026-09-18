#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif
import SeedCore

// A Long Walk for the page, until the plot service exists to supply one.
//
// Every arrival is a real crossing of two parents that meet once, so the walk
// holds the mix a real one would: hybrids, not minted seeds, of all heights and
// colours. They are planted by `LongWalk.Walk.plant`, the rule the plot service
// will run, and each is grown here from its own lineage.
//
//   pg_walk_arrive()      plants the next arrival; returns its plot
//   pg_walk_count(plot)   plantings in a plot so far
//   pg_walk_grow(plot, i) grows the i-th planting of a plot into the result:
//                         spot x, spot z (f32 each), then a plant buffer
//   pg_walk_plots()       plots opened so far
//   pg_walk_describe(p)   a plot's plantings as JSON into the result: slot and
//                         traits, for judging how the rule fills a border
//   pg_lineage(n)         the n-th arrival as a phone would send it to the plot
//                         service, as JSON: seed, parents, encounter, height, family
//   pg_grow_hybrid(t, n)  grows a plant from "seed parentA parentB encounter"
//                         (hex, space-separated), as the page does from the service
//
// The same sequence of arrivals every time, so a plot looks the same on every
// reload, the way a real one would.

nonisolated(unsafe) private var walk = LongWalk.Walk()
nonisolated(unsafe) private var genomes: [String: Genome] = [:]

/// The n-th arrival of the demonstration: two parents who meet once, and their child.
private func arrival(_ n: Int) -> (child: SeedID, parentA: SeedID, parentB: SeedID, encounter: Data, genome: Genome) {
    let parentA = SeedMint.mint(fromEntropy: Data("long-walk-parent-\(n)-a".utf8))
    let parentB = SeedMint.mint(fromEntropy: Data("long-walk-parent-\(n)-b".utf8))
    let encounter = Pollination.encounterID(
        seedA: parentA, seedB: parentB, nonceA: Data("a".utf8), nonceB: Data("b".utf8)
    )
    let child = Pollination.cross(seedA: parentA, seedB: parentB, encounterID: encounter)
    let genome = Genome(seed: child, lineage: .crossed(parentA: parentA, parentB: parentB, encounterID: encounter))
    return (child, parentA, parentB, encounter, genome)
}

@_expose(wasm, "pg_walk_arrive")
@_cdecl("pg_walk_arrive")
public func pgWalkArrive() -> Int32 {
    let (child, _, _, _, genome) = arrival(walk.plantings.count)
    let planting = walk.plant(seed: child, traits: LongWalk.traits(of: genome))
    genomes[planting.seed] = genome
    return Int32(planting.plot)
}

@_expose(wasm, "pg_walk_count")
@_cdecl("pg_walk_count")
public func pgWalkCount(_ plot: Int32) -> Int32 {
    Int32(walk.plot(Int(plot)).count)
}

@_expose(wasm, "pg_walk_grow")
@_cdecl("pg_walk_grow")
public func pgWalkGrow(_ plot: Int32, _ index: Int32) -> Int32 {
    let here = walk.plot(Int(plot))
    guard here.indices.contains(Int(index)), let genome = genomes[here[Int(index)].seed] else { return 0 }
    let spot = here[Int(index)].spot
    var out: [UInt8] = []
    for value in [Float(spot.x), Float(spot.z)] {
        withUnsafeBytes(of: value.bitPattern.littleEndian) { out.append(contentsOf: $0) }
    }
    out.append(contentsOf: PlantBuffer.encode(genome))
    setResult(out)
    return Int32(out.count)
}

@_expose(wasm, "pg_walk_plots")
@_cdecl("pg_walk_plots")
public func pgWalkPlots() -> Int32 {
    Int32(walk.plots)
}

@_expose(wasm, "pg_walk_describe")
@_cdecl("pg_walk_describe")
public func pgWalkDescribe(_ plot: Int32) -> Int32 {
    guard let json = try? JSONEncoder().encode(walk.plot(Int(plot))) else { return 0 }
    setResult(Array(json))
    return Int32(json.count)
}

@_expose(wasm, "pg_lineage")
@_cdecl("pg_lineage")
public func pgLineage(_ n: Int32) -> Int32 {
    let a = arrival(Int(n))
    let traits = LongWalk.traits(of: a.genome)
    let json = """
        {"seed":"\(a.child.hex)","parents":["\(a.parentA.hex)","\(a.parentB.hex)"],\
        "encounter":"\(SeedID(bytes: a.encounter)?.hex ?? "")",\
        "height":\(traits.height),"family":\(traits.family)}
        """
    setResult(Array(json.utf8))
    return Int32(json.utf8.count)
}

@_expose(wasm, "pg_grow_hybrid")
@_cdecl("pg_grow_hybrid")
public func pgGrowHybrid(_ text: UnsafePointer<UInt8>, _ length: Int32) -> Int32 {
    let words = String(decoding: UnsafeBufferPointer(start: text, count: Int(length)), as: UTF8.self)
        .split(separator: " ").map(String.init)
    guard words.count == 4,
          let child = SeedID(hex: words[0]), let parentA = SeedID(hex: words[1]),
          let parentB = SeedID(hex: words[2]), let encounter = SeedID(hex: words[3])?.bytes else { return 0 }
    let genome = Genome(seed: child, lineage: .crossed(parentA: parentA, parentB: parentB, encounterID: encounter))
    let out = PlantBuffer.encode(genome)
    setResult(out)
    return Int32(out.count)
}
