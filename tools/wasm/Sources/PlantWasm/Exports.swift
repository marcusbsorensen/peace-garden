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
//   magic "PGP3", part count, then the grown plant's bounds as six f32
//   per part:    role (u32), vertex count (u32), index count (u32),
//                positions (3 × f32 each), normals (3 × f32), uvs (2 × f32),
//                maturity (f32 each), indices (u32)
//   then, per role in `MeshRole.allCases` order:
//                side (u32), side × side RGBA diffuse texels, row 0 at v = 1,
//                then side × side RGBA relief texels, the same way round
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
// **The relief since 27 September 2026**, which is why the magic is PGP3 and
// the end of the note that stood here since the first plant went on a page.
//
// A leaf lit by one colour and one flat normal has a single uniform sheen,
// and no amount of colour detail recovers from that — it is the whole of why
// a web plant read as moulded rather than grown. `PaletteRamp.relief` has
// described the surface all along: veins standing proud, the blade quilting
// between them, ribbing on a stem, bumps on a floret. The app has baked it
// into a normal map and a roughness map since it was written
// (`GradientTexture.renderNormal`, `renderRoughness`).
//
// **One texture rather than the app's two.** The tangent-space normal of a
// height field always points out of the surface, so `z` can be recovered on
// the page from `x` and `y`; that frees the blue channel for the roughness,
// which is read off the same height field anyway. So the wire carries
// `(nx + 1) / 2`, `(ny + 1) / 2`, roughness, 255 — the ridge the light
// catches and the gloss on it, in one place, from one sampling of the
// relief.

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
        out.append(contentsOf: Array("PGP3".utf8))
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
            bakeRelief(role, palette: genome.palette, into: &out)
        }
        return out
    }

    /// How wide a role's textures are, diffuse and relief alike: the app's
    /// `GradientTexture.resolution`. Written once because the two bakes have
    /// to agree, and the page reads one side for the pair.
    private static func side(of role: MeshRole) -> Int {
        switch role {
        case .leaf: return 256
        case .petal: return 192
        case .centre: return 96
        case .stem, .stamen, .calyx: return 64
        }
    }

    /// **What stops a leaf reading as a painted panel**: the app's normal and
    /// roughness bakes, packed into one texture
    /// (`GradientTexture.renderNormal`, `renderRoughness`).
    ///
    /// The height field is sampled once and both come off it, so the ridge
    /// the light catches and the gloss on it are the same ridge. Raised
    /// ground is smoother, which is the way a vein actually catches light
    /// against the tissue either side of it.
    ///
    /// `nz` is left off the wire: a height field's tangent-space normal
    /// always points out of the surface, so the page recovers it and the
    /// blue channel carries the roughness instead.
    private static func bakeRelief(_ role: MeshRole, palette: Genome.Palette, into out: inout [UInt8]) {
        let side = self.side(of: role)
        // How much apparent depth the relief stands for. **Every one of these
        // came down after the app's first render**: relief that reads as
        // convincing in the abstract reads as corrugated iron on a blade the
        // size of a thumb. Kept identical to the app's so a plant has one
        // surface wherever it is drawn.
        let strength: Double
        switch role {
        case .leaf: strength = 14
        case .petal: strength = 10
        case .stem: strength = 9
        case .centre: strength = 8
        case .stamen: strength = 0
        case .calyx: strength = 6
        }
        // **The swings are deliberately small.** Taking roughness far down on
        // the raised ground gave every ridge a hot specular in the app, and
        // the detail that was meant to appear was the detail that burnt out.
        let base: Double, swing: Double
        switch role {
        case .stem: (base, swing) = (0.75, 0.12)
        case .leaf: (base, swing) = (0.62 - palette.sheen * 0.3, 0.16)
        case .petal: (base, swing) = (0.45 - palette.sheen * 0.3, 0.10)
        case .centre: (base, swing) = (0.55, 0.12)
        case .stamen: (base, swing) = (0.4, 0)
        case .calyx: (base, swing) = (0.62, 0.1)
        }

        var heights = [Double](repeating: 0, count: side * side)
        for y in 0..<side {
            let v = 1 - Double(y) / Double(side - 1)
            for x in 0..<side {
                heights[y * side + x] = PaletteRamp.relief(
                    for: role, u: Double(x) / Double(side - 1), v: v, palette: palette)
            }
        }
        func height(_ x: Int, _ y: Int) -> Double {
            heights[min(side - 1, max(0, y)) * side + min(side - 1, max(0, x))]
        }
        func byte(_ value: Double) -> UInt8 {
            UInt8(max(0, min(255, (value * 255).rounded())))
        }

        out.reserveCapacity(out.count + side * side * 4)
        for y in 0..<side {
            for x in 0..<side {
                let dx = (height(x + 1, y) - height(x - 1, y)) * strength
                let dy = (height(x, y + 1) - height(x, y - 1)) * strength
                var nx = -dx, ny = dy, nz = 1.0
                let length = (nx * nx + ny * ny + nz * nz).squareRoot()
                nx /= length; ny /= length; nz /= length
                _ = nz
                let rough = max(0.05, min(1, base - (heights[y * side + x] - 0.5) * swing))
                out.append(byte((nx + 1) * 0.5))
                out.append(byte((ny + 1) * 0.5))
                out.append(byte(rough))
                out.append(255)
            }
        }
    }

    /// The app's diffuse bake: the same sizes, texel centres and conversion
    /// as `GradientTexture`.
    private static func bake(_ role: MeshRole, palette: Genome.Palette, into out: inout [UInt8]) {
        let side = self.side(of: role)
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
