#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// Irregular edges for everything the garden sets around its plants.
///
/// **No straight line anywhere in the garden** (Marcus, 18 September): a ruled
/// edge beside a petal is jarring, so the ground's outline, its sides, the
/// path's verges and the hedges all wander. The shapes are here, in SeedCore,
/// so the app and the website draw the same outline for the same plot rather
/// than each inventing its own.
///
/// **Deterministic, and the same on every host.** The noise is hashed lattice
/// values blended with a smoothstep: additions and multiplications only, no
/// `sin`, so the browser's build and the phone agree to the bit, and a hedge
/// has the same bumps every time it is drawn.
public enum Organic {

    // MARK: Noise

    /// Smooth noise along a line, in -1...1. `t` in lattice cells.
    public static func noise(_ t: Double, seed: UInt64) -> Double {
        let cell = t.rounded(.down)
        let f = t - cell
        let i = Int64(cell)
        let a = lattice(i, seed), b = lattice(i &+ 1, seed)
        return a + (b - a) * smooth(f)
    }

    /// Smooth noise over a surface, in -1...1. `u`, `v` in lattice cells.
    public static func noise(_ u: Double, _ v: Double, seed: UInt64) -> Double {
        let cu = u.rounded(.down), cv = v.rounded(.down)
        let fu = smooth(u - cu), fv = smooth(v - cv)
        let i = Int64(cu), j = Int64(cv)
        let row = { (j: Int64) -> UInt64 in seed ^ (UInt64(bitPattern: j) &* 0x9E37_79B9_7F4A_7C15) }
        let a = lattice(i, row(j)), b = lattice(i &+ 1, row(j))
        let c = lattice(i, row(j &+ 1)), d = lattice(i &+ 1, row(j &+ 1))
        let top = a + (b - a) * fu, bottom = c + (d - c) * fu
        return top + (bottom - top) * fv
    }

    /// Three octaves of `noise`, for an edge that wanders at a walking scale
    /// and is rough close to. `wavelength` in metres; the result is in -1...1.
    public static func wobble(_ x: Double, wavelength: Double, seed: UInt64) -> Double {
        let t = x / wavelength
        let sum = noise(t, seed: seed)
            + 0.5 * noise(t * 2.13, seed: mix64(seed &+ 1))
            + 0.25 * noise(t * 4.37, seed: mix64(seed &+ 2))
        return sum / 1.75
    }

    /// The same over a surface.
    public static func wobble(_ u: Double, _ v: Double, wavelength: Double, seed: UInt64) -> Double {
        let su = u / wavelength, sv = v / wavelength
        let sum = noise(su, sv, seed: seed)
            + 0.5 * noise(su * 2.13, sv * 2.13, seed: mix64(seed &+ 1))
            + 0.25 * noise(su * 4.37, sv * 4.37, seed: mix64(seed &+ 2))
        return sum / 1.75
    }

    // MARK: The ground's outline

    /// The outline of a slab of ground `width` across (x) and `length` long (z),
    /// centred on the origin: a rectangle with its corners worn round and every
    /// side wandering in and out by up to `reach`, as a clod of earth does.
    ///
    /// The wander only ever goes inward from the rectangle, so the outline sits
    /// inside `width` × `length` and anything drawn to that square can be cut
    /// to it. Points run anticlockwise seen from above (x+ face first, going
    /// z- to z+), about `spacing` apart, and the loop closes without a seam.
    public static func outline(width: Double, length: Double, seed: UInt64,
                               reach: Double = 0.22, spacing: Double = 0.08) -> [Spot] {
        let r = min(0.35, min(width, length) * 0.12)
        let hx = width / 2 - reach, hz = length / 2 - reach
        let w = hx - r, l = hz - r
        // Four straight sides, each followed by the corner at its end.
        let sides: [(x0: Double, z0: Double, dx: Double, dz: Double, length: Double, cx: Double, cz: Double)] = [
            (hx, -l, 0, 1, 2 * l, w, l),
            (w, hz, -1, 0, 2 * w, -w, l),
            (-hx, l, 0, -1, 2 * l, -w, -l),
            (-w, -hz, 1, 0, 2 * w, w, -l),
        ]
        let arc = Double.pi / 2 * r
        let perimeter = sides.reduce(0) { $0 + $1.length } + 4 * arc
        let count = max(16, Int((perimeter / spacing).rounded()))

        var points: [Spot] = []
        points.reserveCapacity(count)
        for k in 0..<count {
            var p = Double(k) / Double(count) * perimeter
            var base = (x: 0.0, z: 0.0, nx: 0.0, nz: 0.0)
            for s in sides {
                // The outward normal is the direction of travel turned a quarter clockwise.
                let nx = s.dz, nz = -s.dx
                if p <= s.length {
                    base = (s.x0 + s.dx * p, s.z0 + s.dz * p, nx, nz)
                    break
                }
                p -= s.length
                if p <= arc {
                    // Round the corner: the normal turns anticlockwise from this side's to the next's.
                    let (c, sn) = quarter(p / r)
                    let ox = nx * c + s.dx * sn, oz = nz * c + s.dz * sn
                    base = (s.cx + r * ox, s.cz + r * oz, ox, oz)
                    break
                }
                p -= arc
            }
            let inward = reach * 0.5 * (1 + seamless(Double(k) / Double(count) * perimeter,
                                                     perimeter: perimeter, wavelength: 0.95, seed: seed))
            points.append(Spot(x: base.x - base.nx * inward + base.nx * reach,
                               z: base.z - base.nz * inward + base.nz * reach))
        }
        return points
    }

    /// Whether a point on the ground is inside an outline.
    public static func contains(_ outline: [Spot], x: Double, z: Double) -> Bool {
        var inside = false
        var j = outline.count - 1
        for i in 0..<outline.count {
            let a = outline[i], b = outline[j]
            if (a.z > z) != (b.z > z), x < (b.x - a.x) * (z - a.z) / (b.z - a.z) + a.x {
                inside.toggle()
            }
            j = i
        }
        return inside
    }

    // MARK: A path's verges

    /// How far a path's verge stands out from its straight line at `along`
    /// metres down it, for one side. A mown path is cut by eye, so it wanders
    /// up to a hand's width either way over a few paces.
    public static func verge(_ along: Double, side: Int, seed: UInt64) -> Double {
        0.14 * wobble(along, wavelength: 1.2, seed: mix64(seed &+ UInt64(bitPattern: Int64(side)) &+ 11))
    }

    // MARK: A hedge

    /// A length of hedge as a mesh: soft-shouldered, bulging a little where
    /// it has grown and dipping where it has not, its top an undulating line
    /// and its ends rounded, as a hedge is after years of being cut by hand.
    ///
    /// Stands on `y = 0`, runs along `z`, centred on the origin.
    public static func hedge(length: Double, height: Double, thickness: Double,
                             seed: UInt64) -> StructureMesh {
        let rings = max(4, Int((length / 0.06).rounded()))
        let around = 20
        // The ends: narrowing over about a hedge's thickness, and the top
        // rounding down over half its height, so an end is a long shoulder
        // falling to the ground rather than a cut face with a rounded corner.
        let endWide = min(thickness * 0.8, length / 2)
        let endHigh = min(max(thickness, height * 0.5), length / 2)
        var mesh = StructureMesh()

        for r in 0...rings {
            let along = -length / 2 + Double(r) / Double(rings) * length
            let fromEnd = min(along + length / 2, length / 2 - along)
            let wide = fromEnd >= endWide ? 1.0 : squareRoot(max(0, 1 - pow2(1 - fromEnd / endWide)))
            let high = fromEnd >= endHigh ? 1.0 : squareRoot(max(0, 1 - pow2(1 - fromEnd / endHigh)))
            let top = height * (1 + 0.08 * wobble(along, wavelength: 0.7, seed: mix64(seed &+ 3)))
            for a in 0...around {
                let angle = Double(a) / Double(around)          // 0 at the ground on one face, round over the top, to 1 at the ground on the other
                let (sx, sy, nx, ny) = section(angle, halfWidth: thickness / 2, height: top)
                let bump = 0.035 * wobble(along, angle * 3.2, wavelength: 0.35, seed: seed)
                let x = (sx + nx * bump) * wide
                let y = sy == 0 ? 0 : (sy + ny * bump) * high
                mesh.positions.append(SIMD3<Float>(Float(x), Float(y), Float(along)))
            }
        }
        let stride = around + 1
        for r in 0..<rings {
            for a in 0..<around {
                let i = UInt32(r * stride + a)
                let j = UInt32((r + 1) * stride + a)
                // Wound so the faces, and the normals made from them, point outward.
                mesh.indices.append(contentsOf: [i, i + 1, j, i + 1, j + 1, j])
            }
        }
        mesh.computeNormals()
        return mesh
    }

    // MARK: Parts

    /// A hedge's cross-section, a loaf: straight-ish sides that round over into
    /// a top, from `angle` 0 (the ground, x+) to 1 (the ground, x-). Returns the
    /// point and its outward direction.
    static func section(_ angle: Double, halfWidth: Double, height: Double)
        -> (x: Double, y: Double, nx: Double, ny: Double) {
        // Perimeter: up one side, round the shoulder, across, down the other.
        let shoulder = min(halfWidth * 0.8, height * 0.4)
        let side = height - shoulder
        let across = 2 * (halfWidth - shoulder)
        let arc = Double.pi / 2 * shoulder
        let total = 2 * side + 2 * arc + across
        var p = angle * total
        if p <= side { return (halfWidth, p, 1, 0) }
        p -= side
        if p <= arc {
            let t = p / shoulder
            let (c, s) = quarter(t)
            return (halfWidth - shoulder + shoulder * c, side + shoulder * s, c, s)
        }
        p -= arc
        if p <= across { return (halfWidth - shoulder - p, height, 0, 1) }
        p -= across
        if p <= arc {
            let t = p / shoulder
            let (c, s) = quarter(t)
            return (-(halfWidth - shoulder) - shoulder * s, side + shoulder * c, -s, c)
        }
        p -= arc
        return (-halfWidth, max(0, side - p), -1, 0)
    }

    /// cos and sin of `t` radians for 0...π/2, as polynomials, so no host's
    /// libm is involved and every host gets the same bits.
    static func quarter(_ t: Double) -> (Double, Double) {
        let t2 = t * t
        let c = 1 - t2 / 2 + t2 * t2 / 24 - t2 * t2 * t2 / 720 + t2 * t2 * t2 * t2 / 40320
        let s = t * (1 - t2 / 6 + t2 * t2 / 120 - t2 * t2 * t2 / 5040 + t2 * t2 * t2 * t2 / 362_880)
        return (c, s)
    }

    /// Wander along a closed loop, with no seam where it meets itself: over the
    /// last stretch it eases toward the value the loop started with.
    private static func seamless(_ p: Double, perimeter: Double, wavelength: Double, seed: UInt64) -> Double {
        let here = wobble(p, wavelength: wavelength, seed: seed)
        let blend = 1.0
        guard p > perimeter - blend else { return here }
        let start = wobble(p - perimeter, wavelength: wavelength, seed: seed)
        let t = smooth((p - (perimeter - blend)) / blend)
        return here + (start - here) * t
    }

    private static func lattice(_ i: Int64, _ seed: UInt64) -> Double {
        Double(mix64(seed ^ UInt64(bitPattern: i) &* 0xD6E8_FEB8_6659_FD93) >> 11) * 0x1.0p-52 - 1
    }

    private static func smooth(_ f: Double) -> Double { f * f * (3 - 2 * f) }
    private static func pow2(_ x: Double) -> Double { x * x }

    /// Newton's method from a fixed start, for the same reason as `quarter`.
    static func squareRoot(_ x: Double) -> Double {
        guard x > 0 else { return 0 }
        var y = x > 1 ? x : 1
        for _ in 0..<30 { y = 0.5 * (y + x / y) }
        return y
    }
}

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
