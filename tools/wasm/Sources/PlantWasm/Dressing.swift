#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif
import SeedCore

// The garden's irregular edges for the page, from SeedCore's `Organic`, so the
// browser's ground, verges and hedges are the shapes the app draws.
//
//   pg_outline(w, l, seed)         the ground's outline into the result: point
//                                  count (u32), then x, z (f32) per point
//   pg_verge(along, side, seed)    how far a path's verge wanders there (f64)
//   pg_hedge(l, h, t, seed, domed, bow)
//                                  a hedge into the result: vertex count, index
//                                  count (u32), positions, normals (3 × f32),
//                                  indices (u32). `domed` 0 cuts its ends
//                                  square, for a run that carries on into the
//                                  next one round an enclosure; `bow` stands
//                                  its middle off the line between its ends,
//                                  which is what draws a knot rather than a
//                                  grid
//   pg_bench(l, h, d, seed)        the Quiet Garden's seat, the same shape
//   pg_roundel(r, lift, seed)      the Crossing's paving, the same shape
//   pg_tree(h, spread, base, seed) the Orchard's trees, the same shape

@_expose(wasm, "pg_outline")
@_cdecl("pg_outline")
public func pgOutline(_ width: Double, _ length: Double, _ seed: UInt32) -> Int32 {
    let points = Organic.outline(width: width, length: length, seed: UInt64(seed))
    var out: [UInt8] = []
    put(UInt32(points.count), &out)
    for p in points { put(Float(p.x), &out); put(Float(p.z), &out) }
    setResult(out)
    return Int32(out.count)
}

@_expose(wasm, "pg_verge")
@_cdecl("pg_verge")
public func pgVerge(_ along: Double, _ side: Int32, _ seed: UInt32) -> Double {
    Organic.verge(along, side: Int(side), seed: UInt64(seed))
}

@_expose(wasm, "pg_hedge")
@_cdecl("pg_hedge")
public func pgHedge(_ length: Double, _ height: Double, _ thickness: Double,
                    _ seed: UInt32, _ domed: Int32, _ bow: Double) -> Int32 {
    let out = structure(Organic.hedge(length: length, height: height, thickness: thickness,
                                      seed: UInt64(seed), domed: domed != 0, bow: bow))
    setResult(out)
    return Int32(out.count)
}

@_expose(wasm, "pg_bench")
@_cdecl("pg_bench")
public func pgBench(_ length: Double, _ height: Double, _ depth: Double, _ seed: UInt32) -> Int32 {
    let out = structure(Organic.bench(length: length, height: height, depth: depth,
                                      seed: UInt64(seed)))
    setResult(out)
    return Int32(out.count)
}

@_expose(wasm, "pg_roundel")
@_cdecl("pg_roundel")
public func pgRoundel(_ radius: Double, _ lift: Double, _ seed: UInt32) -> Int32 {
    let out = structure(Organic.roundel(radius: radius, lift: lift, seed: UInt64(seed)))
    setResult(out)
    return Int32(out.count)
}

@_expose(wasm, "pg_tree")
@_cdecl("pg_tree")
public func pgTree(_ height: Double, _ spread: Double, _ crownBase: Double, _ seed: UInt32) -> Int32 {
    let out = structure(Organic.tree(height: height, spread: spread,
                                     crownBase: crownBase, seed: UInt64(seed)))
    setResult(out)
    return Int32(out.count)
}

/// A structure's mesh, in the shape `readHedge` in the page already reads.
private func structure(_ mesh: StructureMesh) -> [UInt8] {
    var out: [UInt8] = []
    put(UInt32(mesh.positions.count), &out)
    put(UInt32(mesh.indices.count), &out)
    for p in mesh.positions { put(p.x, &out); put(p.y, &out); put(p.z, &out) }
    for n in mesh.normals { put(n.x, &out); put(n.y, &out); put(n.z, &out) }
    for i in mesh.indices { put(i, &out) }
    return out
}

private func put(_ value: UInt32, _ out: inout [UInt8]) {
    withUnsafeBytes(of: value.littleEndian) { out.append(contentsOf: $0) }
}

private func put(_ value: Float, _ out: inout [UInt8]) {
    put(value.bitPattern, &out)
}
