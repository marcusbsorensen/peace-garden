import Foundation
#if canImport(simd)
import simd
#endif

/// One station along a swept path: where it is, which way it points, and how
/// thick the plant is there.
public struct PathSample: Sendable {
    public var position: SIMD3<Float>
    public var tangent: SIMD3<Float>
    public var normal: SIMD3<Float>
    public var binormal: SIMD3<Float>
    public var radius: Float
    /// Position along the path, `0` at the base and `1` at the tip.
    public var t: Float
}

/// The stem, its leaf nodes, and its tip.
public struct PlantSkeleton: Sendable {
    public var stem: [PathSample]
    public var nodes: [PathSample]
    public var apex: PathSample
}

public enum SkeletonBuilder {
    /// Grows the stem for a genome at a given height fraction.
    ///
    /// The curve is integrated step by step rather than evaluated from a
    /// formula, because lean, sway and twist compound along the stem — the same
    /// way a real one accumulates its shape as it grows.
    public static func stem(genome: Genome, heightScale: Float, segments: Int = 28) -> PlantSkeleton {
        let length = max(0.01, Float(genome.stem.height) * heightScale)
        let step = length / Float(segments)
        let leanPerStep = Float(genome.stem.lean) * 0.9 / Float(segments)
        let swayAmplitude = Float(genome.stem.sway) * 0.8
        // A young stem is thin as well as short. Holding the radius at its
        // final value makes a seedling look like a cut-off post.
        let baseRadius = Float(genome.stem.baseRadius) * (0.4 + 0.6 * heightScale)
        let taper = Float(genome.stem.taper)

        var positions: [SIMD3<Float>] = [.zero]
        var radii: [Float] = [baseRadius]
        var direction = SIMD3<Float>(0, 1, 0)
        var position = SIMD3<Float>.zero

        for index in 1...segments {
            let t = Float(index) / Float(segments)
            // Lean tips the whole stem one way; sway waves it back and forth.
            let lean = leanPerStep * (0.6 + 0.8 * t)
            let sway = swayAmplitude * cos(t * .pi * 2.2) / Float(segments)
            direction = rotate(direction, axis: SIMD3<Float>(0, 0, 1), angle: lean)
            direction = rotate(direction, axis: SIMD3<Float>(1, 0, 0), angle: sway)
            direction = simd_normalize(direction)
            position += direction * step
            positions.append(position)
            radii.append(baseRadius * (1 - (1 - taper) * t))
        }

        let samples = transportFrames(
            positions: positions,
            radii: radii,
            twist: Float(genome.stem.twist)
        )

        let nodeCount = genome.stem.nodeCount
        var nodes: [PathSample] = []
        nodes.reserveCapacity(nodeCount)
        for index in 0..<nodeCount {
            let fraction: Float = nodeCount == 1
                ? 0.55
                : 0.16 + 0.74 * Float(index) / Float(nodeCount - 1)
            let sampleIndex = min(samples.count - 1, Int((fraction * Float(samples.count - 1)).rounded()))
            nodes.append(samples[sampleIndex])
        }

        return PlantSkeleton(stem: samples, nodes: nodes, apex: samples[samples.count - 1])
    }

    /// Rotation-minimising frames.
    ///
    /// A naive up-vector frame flips when the stem passes vertical and makes
    /// leaves jump round the stem; carrying the previous frame forward through
    /// the tangent's rotation avoids that.
    static func transportFrames(
        positions: [SIMD3<Float>],
        radii: [Float],
        twist: Float
    ) -> [PathSample] {
        guard positions.count >= 2 else { return [] }

        var tangents: [SIMD3<Float>] = []
        tangents.reserveCapacity(positions.count)
        for index in positions.indices {
            let previous = positions[max(0, index - 1)]
            let next = positions[min(positions.count - 1, index + 1)]
            let delta = next - previous
            tangents.append(simd_length_squared(delta) < 1e-12 ? SIMD3<Float>(0, 1, 0) : simd_normalize(delta))
        }

        var normal = arbitraryPerpendicular(to: tangents[0])
        var samples: [PathSample] = []
        samples.reserveCapacity(positions.count)

        for index in positions.indices {
            if index > 0 {
                normal = rotate(normal, from: tangents[index - 1], to: tangents[index])
                // Re-orthogonalise: floating point drift accumulates over a
                // couple of dozen segments and shows up as a twisted stem.
                normal = normal - tangents[index] * dot(normal, tangents[index])
                let lengthSquared = simd_length_squared(normal)
                normal = lengthSquared < 1e-12
                    ? arbitraryPerpendicular(to: tangents[index])
                    : simd_normalize(normal)
            }

            let t = Float(index) / Float(positions.count - 1)
            let twisted = rotate(normal, axis: tangents[index], angle: twist * t)
            samples.append(
                PathSample(
                    position: positions[index],
                    tangent: tangents[index],
                    normal: twisted,
                    binormal: simd_normalize(cross(tangents[index], twisted)),
                    radius: radii[min(radii.count - 1, index)],
                    t: t
                )
            )
        }
        return samples
    }

    static func arbitraryPerpendicular(to vector: SIMD3<Float>) -> SIMD3<Float> {
        let reference = abs(vector.y) > 0.9 ? SIMD3<Float>(1, 0, 0) : SIMD3<Float>(0, 1, 0)
        return simd_normalize(cross(vector, reference))
    }

    static func rotate(_ vector: SIMD3<Float>, axis: SIMD3<Float>, angle: Float) -> SIMD3<Float> {
        guard abs(angle) > 1e-7 else { return vector }
        return simd_quatf(angle: angle, axis: simd_normalize(axis)).act(vector)
    }

    static func rotate(_ vector: SIMD3<Float>, from: SIMD3<Float>, to: SIMD3<Float>) -> SIMD3<Float> {
        let axis = cross(from, to)
        let sine = simd_length(axis)
        guard sine > 1e-7 else { return vector }
        let angle = atan2(sine, dot(from, to))
        return simd_quatf(angle: angle, axis: axis / sine).act(vector)
    }
}
