import SceneKit
import simd

/// The smooth surfaces the figures and the lights are modelled from: a tube
/// swept along a curve, and a shape turned on a lathe.
///
/// **One surface, not a chain of beads.** The fox's brush was twenty-six
/// spheres strung along an arc, and by day it read as a caterpillar: each bead
/// caught the sun on its own crown and left a groove of shade between it and
/// the next, which is exactly what a segmented body looks like. A tube swept
/// along the same curve, its section swelling and narrowing as it goes, takes
/// the light the way one tail does. The lantern's cap and post, and the paper
/// lamp, are turned for the same reason: an iron cap is one casting, and it has
/// to shade as one.
///
/// Both come out of the same grid of rings, with normals averaged across it so
/// nothing is faceted, and every triangle wound to face out — some of a lathe's
/// profiles turn back on themselves, an eave's lip for one, and a triangle that
/// faced in would be culled and leave a hole.
enum FigureGeometry {

    /// A tube through `points`, its section an ellipse `size(t)` across and
    /// through, `t` running from 0 at the first point to 1 at the last by
    /// distance along the curve rather than by point, so a tail's swell is where
    /// it is said to be however the points are spaced.
    ///
    /// `from` and `to` take a stretch of the curve, so one tube can be painted
    /// in two colours — a brush and its white tip — and meet itself exactly.
    /// "Across" is square to `reference`: for a body lying on the ground that
    /// is straight up, so across is level; for an ear standing up out of a head
    /// it is the way the head faces, so across is from one side of the head to
    /// the other.
    ///
    /// An end whose size falls to zero closes to a point. Let it fall the way
    /// a circle does, as the square root of the distance from the end, and it
    /// closes as a dome.
    static func sweep(through points: [SIMD3<Float>],
                      from: Float = 0, to: Float = 1,
                      rows: Int = 40, around: Int = 28,
                      reference: SIMD3<Float> = SIMD3(0, 1, 0),
                      tint: ((Float) -> Float)? = nil,
                      size: (Float) -> SIMD2<Float>) -> SCNGeometry {
        let curve = Curve(points)
        var rings: [[SIMD3<Float>]] = []
        var centres: [SIMD3<Float>] = []
        var tangents: [SIMD3<Float>] = []
        var shades: [Float] = []

        for row in 0...rows {
            let t = from + (to - from) * Float(row) / Float(rows)
            let (centre, tangent) = curve.at(t)
            var side = simd_cross(reference, tangent)
            if simd_length(side) < 1e-4 { side = simd_cross(SIMD3(1, 0, 0), tangent) }
            side = simd_normalize(side)
            let up = simd_normalize(simd_cross(tangent, side))
            let radii = size(t)
            rings.append((0...around).map { column in
                let angle = Float(column) / Float(around) * 2 * .pi
                return centre + side * (radii.x * cos(angle)) + up * (radii.y * sin(angle))
            })
            centres.append(centre)
            tangents.append(tangent)
            shades.append(tint?(t) ?? 1)
        }
        // Out is away from the curve; at a closed end, along it.
        let outward = rings.indices.map { row in
            rings[row].map { point -> SIMD3<Float> in
                let out = point - centres[row]
                if simd_length(out) > 1e-6 { return simd_normalize(out) }
                return row < rows / 2 ? -tangents[row] : tangents[row]
            }
        }
        return grid(rings, outward: outward, shades: tint == nil ? nil : shades)
    }

    /// A shape turned about the vertical through its foot, from a profile of
    /// (radius, height) points, smoothed through them. The profile starts on
    /// the axis at the bottom, goes out and up the outside, and comes back in
    /// to the axis at the top, so it can tell which way is out where it turns
    /// back under itself.
    ///
    /// `section` bends the circle: given the angle round, it says how far out
    /// the edge is at that angle as a fraction of the radius. A rounded square
    /// is how a four-paned lantern is turned. `tint` is given the height, for
    /// a light that is brighter in its middle than at its rims.
    static func lathe(_ profile: [SIMD2<Float>], rows: Int = 36, around: Int = 48,
                      section: ((Float) -> Float)? = nil,
                      tint: ((Float) -> Float)? = nil) -> SCNGeometry {
        let curve = Curve(profile.map { SIMD3($0.x, $0.y, 0) })
        var rings: [[SIMD3<Float>]] = []
        var outward: [[SIMD3<Float>]] = []
        var shades: [Float] = []

        for row in 0...rows {
            let t = Float(row) / Float(rows)
            let (point, tangent) = curve.at(t)
            let radius = max(0, point.x)
            // The profile runs up from the foot and back in to the axis at the
            // top, so the solid is always on its left: out is the way along
            // it turned a quarter clockwise.
            let out = SIMD2<Float>(tangent.y, -tangent.x)
            var ring: [SIMD3<Float>] = []
            var outs: [SIMD3<Float>] = []
            for column in 0...around {
                let angle = Float(column) / Float(around) * 2 * .pi
                let reach = radius * (section?(angle) ?? 1)
                ring.append(SIMD3(reach * sin(angle), point.y, reach * cos(angle)))
                outs.append(simd_normalize(SIMD3(out.x * sin(angle), out.y, out.x * cos(angle))))
            }
            rings.append(ring)
            outward.append(outs)
            shades.append(tint?(point.y) ?? 1)
        }
        return grid(rings, outward: outward, shades: tint == nil ? nil : shades)
    }

    /// A rounded square, as a `section`: 1 on the flats, and out to the
    /// corners by `sharpness`, where 2 is a circle and the larger it is the
    /// squarer the corners.
    static func roundedSquare(_ sharpness: Float) -> (Float) -> Float {
        { angle in
            1 / pow(pow(abs(cos(angle)), sharpness) + pow(abs(sin(angle)), sharpness), 1 / sharpness)
        }
    }

    // MARK: The grid

    private static func grid(_ rings: [[SIMD3<Float>]], outward: [[SIMD3<Float>]],
                             shades: [Float]?) -> SCNGeometry {
        let rows = rings.count - 1
        let around = rings[0].count - 1
        let width = around + 1
        let positions = rings.flatMap { $0 }
        let outs = outward.flatMap { $0 }
        var normals = [SIMD3<Float>](repeating: .zero, count: positions.count)
        var indices: [UInt32] = []

        func index(_ row: Int, _ column: Int) -> Int { row * width + column }

        for row in 0..<rows {
            for column in 0..<around {
                let quad = [index(row, column), index(row, column + 1),
                            index(row + 1, column), index(row + 1, column + 1)]
                for var triangle in [[quad[0], quad[1], quad[2]], [quad[2], quad[1], quad[3]]] {
                    let a = positions[triangle[0]], b = positions[triangle[1]], c = positions[triangle[2]]
                    var face = simd_cross(b - a, c - a)
                    if simd_dot(face, outs[triangle[0]] + outs[triangle[1]] + outs[triangle[2]]) < 0 {
                        triangle.swapAt(1, 2)
                        face = -face
                    }
                    indices += triangle.map(UInt32.init)
                    for corner in triangle { normals[corner] += face }
                }
            }
        }

        for row in 0...rows {
            // A ring closed to a point faces the way out is there, or the
            // point is a pinch of normals each pointing a different way.
            let closed = simd_length(rings[row][0] - rings[row][around / 2]) < 1e-6
            // The seam is one edge, drawn twice: give both copies the same
            // normal, or it shows as a crease down the back.
            let joined = normals[index(row, 0)] + normals[index(row, around)]
            normals[index(row, 0)] = joined
            normals[index(row, around)] = joined
            for column in 0...around {
                let at = index(row, column)
                if closed || simd_length(normals[at]) < 1e-12 {
                    normals[at] = outs[at]
                } else {
                    normals[at] = simd_normalize(normals[at])
                }
            }
        }

        var coordinates: [CGPoint] = []
        for row in 0...rows {
            for column in 0...around {
                coordinates.append(CGPoint(x: Double(column) / Double(around), y: Double(row) / Double(rows)))
            }
        }

        var sources = [
            SCNGeometrySource(vertices: positions.map { SCNVector3($0.x, $0.y, $0.z) }),
            SCNGeometrySource(normals: normals.map { SCNVector3($0.x, $0.y, $0.z) }),
            SCNGeometrySource(textureCoordinates: coordinates),
        ]
        if let shades {
            var colours: [Float] = []
            for row in 0...rows {
                for _ in 0...around { colours += [shades[row], shades[row], shades[row], 1] }
            }
            let data = colours.withUnsafeBufferPointer { Data(buffer: $0) }
            sources.append(SCNGeometrySource(
                data: data, semantic: .color, vectorCount: positions.count,
                usesFloatComponents: true, componentsPerVector: 4,
                bytesPerComponent: MemoryLayout<Float>.size, dataOffset: 0,
                dataStride: MemoryLayout<Float>.size * 4
            ))
        }
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        return SCNGeometry(sources: sources, elements: [element])
    }

    // MARK: The curve

    /// A Catmull-Rom curve through its points, measured along its length.
    private struct Curve {
        private var samples: [SIMD3<Float>] = []
        private var lengths: [Float] = []

        init(_ points: [SIMD3<Float>]) {
            let first: SIMD3<Float> = points[0] * 2 - points[1]
            let last: SIMD3<Float> = points[points.count - 1] * 2 - points[points.count - 2]
            let padded = [first] + points + [last]
            for segment in 0..<(points.count - 1) {
                let p0 = padded[segment], p1 = padded[segment + 1]
                let p2 = padded[segment + 2], p3 = padded[segment + 3]
                let steps = 40
                for step in 0..<steps {
                    let s = Float(step) / Float(steps)
                    let s2 = s * s, s3 = s2 * s
                    let a: SIMD3<Float> = p1 * 2
                    let b: SIMD3<Float> = (p2 - p0) * s
                    var c: SIMD3<Float> = p0 * 2 - p1 * 5
                    c += p2 * 4 - p3
                    var d: SIMD3<Float> = p1 * 3 - p0
                    d += p3 - p2 * 3
                    samples.append((a + b + c * s2 + d * s3) * 0.5)
                }
            }
            samples.append(points[points.count - 1])
            var run: Float = 0
            lengths = [0]
            for at in 1..<samples.count {
                run += simd_length(samples[at] - samples[at - 1])
                lengths.append(run)
            }
        }

        /// The point `t` of the way along, and the way the curve runs there.
        func at(_ t: Float) -> (SIMD3<Float>, SIMD3<Float>) {
            let total = lengths[lengths.count - 1]
            let wanted = min(max(t, 0), 1) * total
            var low = 0, high = lengths.count - 1
            while high - low > 1 {
                let mid = (low + high) / 2
                if lengths[mid] < wanted { low = mid } else { high = mid }
            }
            let span = max(lengths[high] - lengths[low], 1e-9)
            let point = simd_mix(samples[low], samples[high], SIMD3(repeating: (wanted - lengths[low]) / span))
            let before = samples[max(0, low - 1)], after = samples[min(samples.count - 1, high + 1)]
            return (point, simd_normalize(after - before))
        }
    }
}
