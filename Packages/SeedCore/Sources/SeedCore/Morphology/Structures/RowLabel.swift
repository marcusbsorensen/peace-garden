#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// The label at the head of a drill. One of `Organic`'s structures; the noise
/// it wanders with is in `Organic`.
extension Organic {

    /// A wooden row label: a tongue on a short stake, leaning back a little so
    /// it can be read from the path.
    ///
    /// Stands on `y = 0`, its face toward `z-`, centred on the origin, which is
    /// where the drill it names begins.
    ///
    /// **It leans because a label that stands upright is invisible.** Seen from
    /// the garden's fixed isometric eye, a plate edge-on is a line a couple of
    /// pixels wide; tilted back it catches the sky and reads as a pale shape at
    /// the head of the drill, which is the whole of its job. The lean is 22°,
    /// far enough to be read and near enough that it does not look pushed over.
    ///
    /// **Nothing is written on it.** At this scale a word would be four pixels
    /// tall and would fight the plants for attention. The drill's kind is named
    /// in the page's text instead, where it can be read and translated.
    ///
    /// The stake tapers and the tongue's corners round, both by a hand's
    /// worth rather than a machine's, and the two wander with the same seed as
    /// everything else the garden sets around its plants.
    public static func rowLabel(height: Double = 0.30, width: Double = 0.15,
                                seed: UInt64) -> StructureMesh {
        var mesh = StructureMesh()
        let lean = 0.38                      // tangent of about 22°, as a slope rather than an angle
        let stakeTop = height * 0.55
        let tongueHigh = height - stakeTop

        // The stake: a squared post swept up y, tapering as it goes.
        let stakeRings = 7, around = 24
        for r in 0...stakeRings {
            let t = Double(r) / Double(stakeRings)
            let y = t * stakeTop
            let taper = 1 - 0.18 * t
            let halfWidth = 0.012 * taper
            let halfThick = 0.009 * taper
            for a in 0...around {
                let angle = Double(a) / Double(around)
                let (sx, sz, nx, nz) = boardSection(angle, halfWidth: halfWidth,
                                                    halfThick: halfThick, radius: 0.004)
                let bend = 0.02 * wobble(y * 3.1, angle * 2.0, wavelength: 0.6, seed: seed)
                mesh.positions.append(SIMD3<Float>(Float(sx + bend * 0.4),
                                                   Float(y),
                                                   Float(sz + y * lean)))
                mesh.normals.append(SIMD3<Float>(Float(nx), 0, Float(nz)))
            }
        }
        weld(&mesh, from: 0, rings: stakeRings, around: around)

        // The tongue: a thin plate swept across x, leaning back over the stake.
        let base = UInt32(mesh.positions.count)
        let plateRings = 9
        let halfWidth = width / 2
        for r in 0...plateRings {
            let t = Double(r) / Double(plateRings)
            let across = (t - 0.5) * width
            // Shoulders: the plate narrows to its top corners rather than
            // arriving square, the way a label cut with a knife does.
            let shoulder = 1 - 0.14 * pow2(max(0, abs(across) / halfWidth - 0.55) / 0.45)
            let high = tongueHigh * shoulder
            for a in 0...around {
                let angle = Double(a) / Double(around)
                let (py, pz, ny, nz) = boardSection(angle, halfWidth: high / 2,
                                                    halfThick: 0.006, radius: 0.005)
                let ripple = 0.004 * wobble(across * 4.0, angle * 2.0, wavelength: 0.5,
                                            seed: mix64(seed &+ 1))
                let y = stakeTop + tongueHigh / 2 + py
                mesh.positions.append(SIMD3<Float>(Float(across),
                                                   Float(y),
                                                   Float(pz + ripple + y * lean)))
                mesh.normals.append(SIMD3<Float>(0, Float(ny), Float(nz)))
            }
        }
        weld(&mesh, from: base, rings: plateRings, around: around)

        mesh.computeNormals()
        return mesh
    }

    /// Sews one swept run of rings into triangles, wound so the outside faces
    /// out. Both of a label's pieces are swept the same way.
    private static func weld(_ mesh: inout StructureMesh, from base: UInt32,
                             rings: Int, around: Int) {
        let stride = around + 1
        for r in 0..<rings {
            for a in 0..<around {
                let i = base + UInt32(r * stride + a)
                let j = base + UInt32((r + 1) * stride + a)
                mesh.indices.append(contentsOf: [i, i + 1, j, i + 1, j + 1, j])
            }
        }
    }
}
