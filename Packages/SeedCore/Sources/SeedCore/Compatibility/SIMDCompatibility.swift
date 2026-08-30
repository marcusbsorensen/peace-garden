#if !canImport(simd)
import Foundation

// Apple's `simd` module does not exist outside Apple's platforms, but
// `SIMD3<Float>` itself is in the Swift standard library and so is its
// arithmetic. These are the handful of functions the morphology code asks
// `simd` for, and nothing more.
//
// They exist so the package — and its tests — build on Linux, which is what
// lets continuous integration run the whole suite on every push. The plant this
// produces on Linux is the same plant it produces on a phone: the maths below
// is the definition, not an approximation of something faster.

@inlinable
func dot(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float {
    a.x * b.x + a.y * b.y + a.z * b.z
}

@inlinable
func cross(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> SIMD3<Float> {
    SIMD3<Float>(
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x
    )
}

@inlinable
func simd_length_squared(_ v: SIMD3<Float>) -> Float { dot(v, v) }

@inlinable
func simd_length(_ v: SIMD3<Float>) -> Float { simd_length_squared(v).squareRoot() }

@inlinable
func simd_normalize(_ v: SIMD3<Float>) -> SIMD3<Float> {
    let length = simd_length(v)
    return length > 0 ? v / length : v
}

@inlinable
func simd_min(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> SIMD3<Float> {
    SIMD3<Float>(Swift.min(a.x, b.x), Swift.min(a.y, b.y), Swift.min(a.z, b.z))
}

@inlinable
func simd_max(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> SIMD3<Float> {
    SIMD3<Float>(Swift.max(a.x, b.x), Swift.max(a.y, b.y), Swift.max(a.z, b.z))
}

/// Rotation about an axis, which is the only thing SeedCore asks a quaternion
/// to do. Rodrigues' formula gives the same result as the quaternion sandwich
/// product for a unit axis.
struct simd_quatf {
    var angle: Float
    var axis: SIMD3<Float>

    init(angle: Float, axis: SIMD3<Float>) {
        self.angle = angle
        self.axis = simd_normalize(axis)
    }

    func act(_ v: SIMD3<Float>) -> SIMD3<Float> {
        let cosine = cos(angle)
        let sine = sin(angle)
        return v * cosine + cross(axis, v) * sine + axis * (dot(axis, v) * (1 - cosine))
    }
}
#endif
