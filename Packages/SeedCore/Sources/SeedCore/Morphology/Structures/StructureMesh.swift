#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// Geometry for a structure in the garden, not a plant: positions, normals and
/// triangles, ready for SceneKit or WebGL.
public struct StructureMesh: Sendable {
    public var positions: [SIMD3<Float>] = []
    public var normals: [SIMD3<Float>] = []
    public var indices: [UInt32] = []

    public init() {}

    /// Smooth normals, each the sum of the faces around the vertex.
    mutating func computeNormals() {
        var sums = [SIMD3<Float>](repeating: .zero, count: positions.count)
        var t = 0
        while t + 2 < indices.count {
            let a = Int(indices[t]), b = Int(indices[t + 1]), c = Int(indices[t + 2])
            let e1 = positions[b] - positions[a], e2 = positions[c] - positions[a]
            let n = SIMD3<Float>(e1.y * e2.z - e1.z * e2.y, e1.z * e2.x - e1.x * e2.z, e1.x * e2.y - e1.y * e2.x)
            sums[a] += n; sums[b] += n; sums[c] += n
            t += 3
        }
        normals = sums.map { n in
            let length = (n.x * n.x + n.y * n.y + n.z * n.z).squareRoot()
            return length > 0 ? n / length : SIMD3<Float>(0, 1, 0)
        }
    }
}
