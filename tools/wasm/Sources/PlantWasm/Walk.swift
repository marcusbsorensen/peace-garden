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
//
// The same sequence of arrivals every time, so a plot looks the same on every
// reload, the way a real one would.

nonisolated(unsafe) private var walk = LongWalk.Walk()
nonisolated(unsafe) private var genomes: [String: Genome] = [:]

@_expose(wasm, "pg_walk_arrive")
@_cdecl("pg_walk_arrive")
public func pgWalkArrive() -> Int32 {
    let n = walk.plantings.count
    let parentA = SeedMint.mint(fromEntropy: Data("long-walk-parent-\(n)-a".utf8))
    let parentB = SeedMint.mint(fromEntropy: Data("long-walk-parent-\(n)-b".utf8))
    let encounter = Pollination.encounterID(
        seedA: parentA, seedB: parentB, nonceA: Data("a".utf8), nonceB: Data("b".utf8)
    )
    let child = Pollination.cross(seedA: parentA, seedB: parentB, encounterID: encounter)
    let genome = Genome(seed: child, lineage: .crossed(parentA: parentA, parentB: parentB, encounterID: encounter))
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
