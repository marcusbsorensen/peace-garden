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
//   pg_hedge(l, h, t, seed)        a hedge into the result: vertex count, index
//                                  count (u32), positions, normals (3 × f32),
//                                  indices (u32)

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
public func pgHedge(_ length: Double, _ height: Double, _ thickness: Double, _ seed: UInt32) -> Int32 {
    let mesh = Organic.hedge(length: length, height: height, thickness: thickness, seed: UInt64(seed))
    var out: [UInt8] = []
    put(UInt32(mesh.positions.count), &out)
    put(UInt32(mesh.indices.count), &out)
    for p in mesh.positions { put(p.x, &out); put(p.y, &out); put(p.z, &out) }
    for n in mesh.normals { put(n.x, &out); put(n.y, &out); put(n.z, &out) }
    for i in mesh.indices { put(i, &out) }
    setResult(out)
    return Int32(out.count)
}

private func put(_ value: UInt32, _ out: inout [UInt8]) {
    withUnsafeBytes(of: value.littleEndian) { out.append(contentsOf: $0) }
}

private func put(_ value: Float, _ out: inout [UInt8]) {
    put(value.bitPattern, &out)
}
