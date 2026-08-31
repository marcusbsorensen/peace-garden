import Foundation
#if canImport(simd)
import simd
#endif

/// Which material a run of triangles belongs to.
public enum MeshRole: String, CaseIterable, Sendable {
    case stem
    case leaf
    case petal
    case centre
    case stamen
}

/// Renderer-agnostic geometry for one plant.
///
/// The core produces plain vertex buffers rather than SceneKit or RealityKit
/// objects, so the renderer is a thin, replaceable layer and the geometry
/// itself stays testable without a GPU.
public struct PlantMesh: Sendable {
    public struct Part: Sendable {
        public var role: MeshRole
        public var positions: [SIMD3<Float>]
        public var normals: [SIMD3<Float>]
        public var uvs: [SIMD2<Float>]
        /// How far along its own development this vertex's surface is, 0 to 1.
        ///
        /// Per vertex rather than per part, because every leaf on a plant is one
        /// part and they are not the same age: a leaf at the frontier is days
        /// old and the one at the base has been there for weeks. A texture is
        /// shared by the whole part and so cannot say this; the renderer reads
        /// it as a vertex attribute and tints from it.
        ///
        /// Blooms carry their own openness here, so a spike can hold a flower
        /// and a bud and colour them differently.
        public var maturity: [Float]
        public var indices: [UInt32]

        public var triangleCount: Int { indices.count / 3 }
    }

    public var parts: [Part]
    public var minBounds: SIMD3<Float>
    public var maxBounds: SIMD3<Float>

    public var height: Float { maxBounds.y - minBounds.y }
    public var centre: SIMD3<Float> { (minBounds + maxBounds) * 0.5 }
    public var vertexCount: Int { parts.reduce(0) { $0 + $1.positions.count } }
    public var triangleCount: Int { parts.reduce(0) { $0 + $1.triangleCount } }
}
