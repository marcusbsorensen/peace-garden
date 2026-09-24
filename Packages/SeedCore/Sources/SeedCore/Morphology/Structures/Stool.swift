#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// A coppice stool: the low boss of old wood a fern on a stool grows from.
/// One of `Organic`'s structures; the noise it wanders with is in `Organic`.
///
/// **Grown wood that was cut**, so its outline wanders more than a sawn
/// bench's and less than a hedge's: a few lobes round it, where the stems it
/// once carried stood, and bark that is ridged rather than planed. The cut
/// face on top is sloped a little, as a coppice cut is made, so the rain runs
/// off it rather than standing in it and rotting the stool.
///
/// **In two pieces, because it is two materials**, as a pot and its compost
/// are: the bark, and the cut face, which the page colours by the year — pale
/// in the winter it was cut, weathering grey over the two after. The face is
/// the one surface in the garden that shows the date.
///
/// Both stand centred on the origin, the ground at `y = 0` and the middle of
/// the face at `Coppice.stoolHeight`, where a fern's foot stands. The bark goes
/// a little below the ground, so a stool set on a slope of the woodland floor
/// is sunk into the litter on its low side rather than standing off it.
///
/// **It belongs to a planting, not to the plot.** Its width, its lobes and the
/// slope of its cut all come from the seed of the fern on it, so an empty
/// stool place is woodland floor and a stool is drawn only with its fern.
///
/// **Unnamed**, as every structure is. A named structure is forty-two
/// translations.
extension Organic {

    /// How many points round a stool's outline: one every three centimetres
    /// at the widest, which is finer than a lobe and coarser than the page can
    /// see.
    static let stoolAround = 40

    /// **How far a stool's outline wanders in from its width**, and only in:
    /// three centimetres. A sawn board's wander is four millimetres and a
    /// hedge's three and a half centimetres on half its thickness, so a stool
    /// sits between them, and because it only ever wanders inward no stool is
    /// wider than the width the rule measured its clearance at.
    static let stoolWander = 0.03

    /// How far the bark goes below the ground.
    static let stoolSunk = 0.03

    /// How far the cut falls across the face, edge to edge.
    static let stoolSlope = 0.024

    /// How far out the cut face reaches, as a share of the outline: the rest is
    /// the bark rolling over to meet it.
    static let stoolFace = 0.86

    /// **How wide a stool is, from its seed**: somewhere in
    /// `Coppice.stoolAcross`, evenly.
    public static func stoolAcross(seed: UInt64) -> Double {
        let unit = Double(mix64(seed &+ 5) >> 11) * 0x1.0p-53
        let range = Coppice.stoolAcross
        return range.lowerBound + (range.upperBound - range.lowerBound) * unit
    }

    /// How far the outline stands from the middle a fraction `t` of the way
    /// round, from `x+` towards `z+`: half the width, less up to
    /// `stoolWander`.
    ///
    /// Sampled round a circle of the surface noise rather than along a line,
    /// as a pot's wall is, so the last step round meets the first with no seam.
    /// A circle a little under one lattice cell across, so the first octave
    /// makes five or six lobes and the finer two roughen them. The noise
    /// seldom reaches the ends of its range, so it is doubled and held to them:
    /// otherwise one stool in thirty came out as round as a turned one.
    static func stoolRadius(_ t: Double, across: Double, seed: UInt64) -> Double {
        let (c, s) = turn(t)
        let lobe = 2 * wobble(0.8 * c, 0.8 * s, wavelength: 1.0, seed: mix64(seed &+ 11))
        return across / 2 - stoolWander * 0.5 * (1 + min(1, max(-1, lobe)))
    }

    /// The height of the cut at a point on it: `Coppice.stoolHeight` at the
    /// middle, falling across the face in a direction from the seed, and a
    /// millimetre or so uneven away from the middle, as a saw leaves it.
    static func stoolCut(x: Double, z: Double, across: Double, seed: UInt64) -> Double {
        let unit = Double(mix64(seed &+ 7) >> 11) * 0x1.0p-53
        let (dc, ds) = turn(unit)
        let half = across / 2
        let out = (x * x + z * z).squareRoot() / half
        let rough = 0.0015 * out * wobble(x, z, wavelength: 0.07, seed: mix64(seed &+ 13))
        return Coppice.stoolHeight + stoolSlope / 2 * (x * dc + z * ds) / half + rough
    }

    /// **Where a stool meets the ground**, anticlockwise from `x+` seen from
    /// above. The page lays its shadow from this: the footprint moved away from
    /// the light, as a hedge's shadow is.
    public static func stoolFootprint(seed: UInt64) -> [Spot] {
        let across = stoolAcross(seed: seed)
        return (0..<stoolAround).map { a in
            let t = Double(a) / Double(stoolAround)
            let (c, s) = turn(t)
            let r = stoolRadius(t, across: across, seed: seed)
            return Spot(x: r * c, z: r * s)
        }
    }

    /// The bark: rings from the foot, sunk below the ground, up the side of
    /// the boss and over its shoulder to the edge of the cut face.
    ///
    /// **The widest ring is the one at the ground**, and every ring above it
    /// is drawn in toward the face, ridged a little as old bark is — never out
    /// past the footprint, so the footprint is the stool's whole extent.
    public static func stool(seed: UInt64) -> StructureMesh {
        let across = stoolAcross(seed: seed)
        // Each ring as (share of the outline, share of the cut's height). The
        // first is the foot below the ground, whose height is its own.
        let rings: [(Double, Double)] = [
            (1.0, 0), (1.0, 0), (0.985, 0.35), (0.955, 0.65), (0.92, 0.88), (0.89, 0.97),
            (stoolFace, 1.0),
        ]
        var mesh = StructureMesh()
        for (r, (share, rise)) in rings.enumerated() {
            for a in 0...stoolAround {
                let t = Double(a) / Double(stoolAround)
                let (c, s) = turn(t)
                let outline = stoolRadius(t, across: across, seed: seed)
                // Ridged between the ground and the face, and not at either,
                // so the foot is the footprint and the top meets the face.
                let between = r > 1 && r < rings.count - 1
                let ridge = between
                    ? 0.015 * wobble(1.6 * c, 1.6 * s + rise, wavelength: 0.5, seed: mix64(seed &+ 17)) : 0
                let radius = outline * share * (1 + ridge)
                let x = radius * c, z = radius * s
                let y = r == 0 ? -stoolSunk : rise * stoolCut(x: x, z: z, across: across, seed: seed)
                mesh.positions.append(SIMD3<Float>(Float(x), Float(y), Float(z)))
            }
        }
        let stride = UInt32(stoolAround + 1)
        for r in 0..<UInt32(rings.count - 1) {
            for a in 0..<UInt32(stoolAround) {
                let i = r * stride + a, j = i + stride
                mesh.indices.append(contentsOf: [i, j, i + 1, i + 1, j, j + 1])
            }
        }
        mesh.computeNormals()
        return mesh
    }

    /// The cut face: a disc from the middle out to the bark's top ring,
    /// following the slope of the cut. Its middle is at
    /// `Coppice.stoolHeight` exactly, where the fern stands.
    public static func stoolFace(seed: UInt64) -> StructureMesh {
        let across = stoolAcross(seed: seed)
        let shares = [0.3, 0.6, 0.85, 1.0]
        var mesh = StructureMesh()
        mesh.positions.append(SIMD3<Float>(0, Float(Coppice.stoolHeight), 0))
        for share in shares {
            for a in 0...stoolAround {
                let t = Double(a) / Double(stoolAround)
                let (c, s) = turn(t)
                let radius = stoolRadius(t, across: across, seed: seed) * stoolFace * share
                let x = radius * c, z = radius * s
                mesh.positions.append(SIMD3<Float>(Float(x), Float(stoolCut(x: x, z: z, across: across, seed: seed)),
                                                   Float(z)))
            }
        }
        let stride = UInt32(stoolAround + 1)
        for a in 0..<UInt32(stoolAround) {
            mesh.indices.append(contentsOf: [0, a + 2, a + 1])
        }
        for r in 0..<UInt32(shares.count - 1) {
            for a in 0..<UInt32(stoolAround) {
                let i = 1 + r * stride + a, j = i + stride
                mesh.indices.append(contentsOf: [i, i + 1, j, i + 1, j + 1, j])
            }
        }
        mesh.computeNormals()
        return mesh
    }
}

extension Coppice.Planting {
    /// **The number a planting's stool is grown from**: the first four bytes
    /// of its seed. Four, not eight, because the page reads a seed as hex and
    /// hands the module a 32-bit number, and a stool drawn on the page has to
    /// be the one drawn anywhere else.
    public var stoolSeed: UInt64 { Coppice.stoolSeed(seed) }
}

extension Coppice {
    /// The stool seed for a seed written as hex. `Planting.stoolSeed`.
    public static func stoolSeed(_ hex: String) -> UInt64 {
        UInt64(hex.prefix(8), radix: 16) ?? 0
    }
}
