#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// The paving where the Crossing's four paths meet. One of `Organic`'s
/// structures; the noise it wanders with is in `Organic`.
extension Organic {

    /// The paving where the Crossing's four paths meet: a low disc standing
    /// proud of the ground, cambered a little so it catches the light.
    ///
    /// **The first structure in the garden that is neither hedge nor bench**,
    /// and the first that is round. It is laid rather than grown, so like the
    /// bench its wander is small and lives in the edge — 0.035 m on a metre of
    /// radius, which is a rim of stones set by hand rather than a poured circle.
    /// A perfect circle is not a straight line, but it is the same fault:
    /// nothing in this garden was made by a machine.
    ///
    /// It has a rim down to the ground rather than sitting flat on it, because
    /// paving that meets grass at no height at all reads as a texture painted on
    /// the lawn from the isometric view every plot is seen at.
    ///
    /// **Unnamed**, as the hedges, the lights and the bench are.
    public static func roundel(radius: Double = 0.85, lift: Double = 0.05,
                               seed: UInt64) -> StructureMesh {
        let segments = 96
        let rings = 6
        let camber = 0.008
        let perimeter = 2 * Double.pi * radius
        var mesh = StructureMesh()

        // The edge, worked out once, so the top and the rim below it share it
        // exactly and no seam opens between them.
        var edge: [Double] = []
        for a in 0...segments {
            let p = Double(a) / Double(segments) * perimeter
            edge.append(radius + 0.035 * seamless(p, perimeter: perimeter,
                                                  wavelength: 1.1, seed: seed))
        }

        for r in 0...rings {
            let t = Double(r) / Double(rings)
            for a in 0...segments {
                let (cx, cz) = circle(Double(a) / Double(segments))
                let out = t * edge[a]
                // **Uneven, or it is a lid.** A disc with smooth normals and a
                // gentle camber takes one broad highlight and reads as a
                // painted cover rather than as stones somebody laid. Seven
                // millimetres of unevenness is under the eye's notice as a
                // height and is the whole difference in how it is lit.
                let uneven = 0.007 * wobble(out * 1.9, Double(a) / Double(segments) * 2.4,
                                            wavelength: 0.5, seed: seed)
                mesh.positions.append(SIMD3<Float>(
                    Float(out * cx),
                    Float(lift + camber * (1 - t * t) + uneven),
                    Float(out * cz)
                ))
            }
        }
        let stride = segments + 1
        for r in 0..<rings {
            for a in 0..<segments {
                let i = UInt32(r * stride + a), j = UInt32((r + 1) * stride + a)
                mesh.indices.append(contentsOf: [i, i + 1, j, i + 1, j + 1, j])
            }
        }

        // The rim, straight down to the grass.
        let top = UInt32(rings * stride)
        let foot = UInt32(mesh.positions.count)
        for a in 0...segments {
            let (cx, cz) = circle(Double(a) / Double(segments))
            mesh.positions.append(SIMD3<Float>(Float(edge[a] * cx), 0, Float(edge[a] * cz)))
        }
        for a in 0..<segments {
            let i = top + UInt32(a), j = foot + UInt32(a)
            mesh.indices.append(contentsOf: [i, i + 1, j, i + 1, j + 1, j])
        }
        mesh.computeNormals()
        return mesh
    }
}
