#if os(WASI)
import FoundationEssentials
import WASILibc
#else
import Foundation
#endif
import SeedCore

// The page's side of the module.
//
// The page writes a seed's 64 hex characters into memory it got from
// `pg_alloc`, calls `pg_grow`, and reads the plant back from `pg_result`. The
// plant is a flat little-endian buffer, laid out for WebGL to take whole:
//
//   magic "PGP2", part count, then the grown plant's bounds as six f32
//   per part:    role (u32), vertex count (u32), index count (u32),
//                positions (3 × f32 each), normals (3 × f32), uvs (2 × f32),
//                maturity (f32 each), indices (u32)
//   then, per role in `MeshRole.allCases` order:
//                side (u32), then side × side RGBA texels, row 0 at v = 1
//
// **`maturity` since 27 September 2026**, which is why the magic is PGP2.
// It is one value for a whole surface — a leaf unfurls as a leaf — carried
// per vertex because that is the only channel that survives every leaf on a
// plant sharing one material (`MeshBuilder.addSurface`). The app has read it
// since it was written and tints a young leaf toward the carotenoids under
// its chlorophyll; without it every leaf on a web plant is the same colour
// to the pixel, which is a good part of why they read as plastic.
//
// The magic is checked on the page, so a wasm and a page that disagree say
// so rather than drawing nonsense. Nothing stores this buffer, so there is
// no old version to keep reading.
//
// Only the diffuse texture for now. The app also bakes relief and roughness;
// they follow once one plant is on a page.

nonisolated(unsafe) private var result: [UInt8] = []

func setResult(_ bytes: [UInt8]) {
    result = bytes
}

@_expose(wasm, "pg_alloc")
@_cdecl("pg_alloc")
public func pgAlloc(_ count: Int32) -> UnsafeMutableRawPointer? {
    malloc(Int(count))
}

@_expose(wasm, "pg_free")
@_cdecl("pg_free")
public func pgFree(_ pointer: UnsafeMutableRawPointer?) {
    free(pointer)
}

/// Grows the minted plant for a seed. Returns the result's length in bytes,
/// or 0 if the text is not a seed.
@_expose(wasm, "pg_grow")
@_cdecl("pg_grow")
public func pgGrow(_ text: UnsafePointer<UInt8>, _ length: Int32) -> Int32 {
    let hex = String(decoding: UnsafeBufferPointer(start: text, count: Int(length)), as: UTF8.self)
    guard let seed = SeedID(hex: hex) else { return 0 }
    result = PlantBuffer.encode(Genome(seed: seed))
    return Int32(result.count)
}

@_expose(wasm, "pg_result")
@_cdecl("pg_result")
public func pgResult() -> UnsafeRawPointer? {
    result.withUnsafeBytes { UnsafeRawPointer($0.baseAddress) }
}

enum PlantBuffer {
    /// At its best unless told otherwise. The Cold Frame is the one area that
    /// says otherwise: it draws every plant young (`ColdFrame.drawn`).
    static func encode(_ genome: Genome, growth: GrowthModel.State? = nil) -> [UInt8] {
        let mesh = PlantBuilder(genome: genome).mesh(growth: growth ?? Maturity.bloomPreview(for: genome))
        var out: [UInt8] = []
        out.append(contentsOf: Array("PGP2".utf8))
        put(UInt32(mesh.parts.count), &out)
        for value in [mesh.minBounds, mesh.maxBounds] {
            put(value.x, &out); put(value.y, &out); put(value.z, &out)
        }
        for part in mesh.parts {
            put(UInt32(MeshRole.allCases.firstIndex(of: part.role) ?? 0), &out)
            put(UInt32(part.positions.count), &out)
            put(UInt32(part.indices.count), &out)
            for p in part.positions { put(p.x, &out); put(p.y, &out); put(p.z, &out) }
            for n in part.normals { put(n.x, &out); put(n.y, &out); put(n.z, &out) }
            for t in part.uvs { put(t.x, &out); put(t.y, &out) }
            for m in part.maturity { put(m, &out) }
            for i in part.indices { put(i, &out) }
        }
        for role in MeshRole.allCases {
            bake(role, palette: genome.palette, into: &out)
        }
        return out
    }

    /// The app's diffuse bake: the same sizes, texel centres and conversion
    /// as `GradientTexture`.
    private static func bake(_ role: MeshRole, palette: Genome.Palette, into out: inout [UInt8]) {
        let side: Int
        switch role {
        case .leaf: side = 256
        case .petal: side = 192
        case .centre: side = 96
        case .stem, .stamen, .calyx: side = 64
        }
        put(UInt32(side), &out)
        out.reserveCapacity(out.count + side * side * 4)
        for y in 0..<side {
            let v = 1 - Double(y) / Double(side - 1)
            for x in 0..<side {
                let u = Double(x) / Double(side - 1)
                let colour = PaletteRamp.colour(for: role, u: u, v: v, palette: palette).rgb8
                out.append(colour.red); out.append(colour.green); out.append(colour.blue); out.append(255)
            }
        }
    }

    private static func put(_ value: UInt32, _ out: inout [UInt8]) {
        withUnsafeBytes(of: value.littleEndian) { out.append(contentsOf: $0) }
    }

    private static func put(_ value: Float, _ out: inout [UInt8]) {
        put(value.bitPattern, &out)
    }
}
