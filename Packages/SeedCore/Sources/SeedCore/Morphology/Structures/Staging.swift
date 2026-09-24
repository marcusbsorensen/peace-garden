#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// Glasshouse staging, and the pots that stand on it. One of `Organic`'s
/// structures; the noise it wanders with is in `Organic`, and the boards are
/// the bench's.
///
/// **Slatted, because staging is.** A solid shelf holds water and rots; staging
/// is laid in slats with a finger's width of air between them, so the pots
/// drain and the air moves round them. The slats are also what make it read as
/// staging rather than as a table at this distance: a line of light between
/// each board.
///
/// **Unnamed**, as every structure is. A named structure is forty-two
/// translations.
extension Organic {

    /// How many slats a staging is laid in, how wide each is and how thick.
    static let stagingSlats = 5
    static let stagingSlat = 0.105
    static let stagingSlatThick = 0.025
    static let stagingLeg = 0.05

    /// The staging: slats along `x` on bearers across it, each bearer carried
    /// on a pair of legs. It stands on `y = 0`, centred on the origin, its top
    /// at `height`, `length` along `x` and `depth` across `z`.
    ///
    /// Five frames of legs over four metres, a metre apart, which is what a
    /// run of slats a couple of centimetres thick will span loaded with wet
    /// pots without sagging.
    public static func staging(length: Double = Glasshouse.houseLength - 0.4,
                               depth: Double = Glasshouse.stagingDepth,
                               height: Double = Glasshouse.stagingTop, seed: UInt64) -> StructureMesh {
        var mesh = StructureMesh()
        let slats = stagingSlats, slat = stagingSlat, thick = stagingSlatThick, leg = stagingLeg
        let gap = (depth - Double(slats) * slat) / Double(slats - 1)
        var n: UInt64 = 40
        let next = { () -> UInt64 in n += 1; return mix64(seed &+ n) }

        // The slats, running the staging's length.
        for s in 0..<slats {
            let z = -depth / 2 + slat / 2 + Double(s) * (slat + gap)
            append(plank(length: length, width: slat, thickness: thick, lift: height - thick, seed: next()),
                   to: &mesh, turned: true, at: SIMD3<Float>(0, 0, Float(z)))
        }

        // The frames: a bearer across under the slats, on two legs.
        let frames = 5
        let bearer = 0.06
        for f in 0..<frames {
            let x = -length / 2 + 0.12 + Double(f) * (length - 0.24) / Double(frames - 1)
            append(plank(length: depth - 0.02, width: leg, thickness: bearer,
                         lift: height - thick - bearer, seed: next()),
                   to: &mesh, turned: false, at: SIMD3<Float>(Float(x), 0, 0))
            for side in [-1.0, 1.0] {
                append(plank(length: leg, width: leg, thickness: height - thick - bearer, lift: 0,
                             seed: next()),
                       to: &mesh, turned: false,
                       at: SIMD3<Float>(Float(x), 0, Float(side * (depth / 2 - leg / 2 - 0.02))))
            }
        }
        mesh.computeNormals()
        return mesh
    }

    /// A clay pot: a tapered wall, a rolled rim a little proud of it, and the
    /// inside of the wall down to the soil. Stands on `y = 0`, centred on the
    /// origin, its soil at `Glasshouse.potSoil`.
    ///
    /// **Turned, and then left to wander a little**, as a hand-thrown pot does:
    /// a lathe profile swept round, each ring pushed in and out by a couple of
    /// millimetres from the seed, so a staging of twenty-four pots is not
    /// twenty-four copies of one.
    public static func pot(seed: UInt64) -> StructureMesh {
        // The profile, from the middle of the base out and up the outside, over
        // the rim and down the inside to the soil: (radius, height).
        let soil = Glasshouse.potSoil
        let profile: [(Double, Double)] = [
            (0.0, 0.0), (0.056, 0.0), (0.060, 0.006),
            (0.076, 0.112), (0.088, 0.116), (0.090, 0.124),
            (0.090, 0.146), (0.086, 0.150), (0.078, 0.150),
            (0.075, 0.140), (0.074, soil),
        ]
        let around = 20
        var mesh = StructureMesh()
        for (r, (radius, y)) in profile.enumerated() {
            for a in 0...around {
                let angle = Double(a) / Double(around)
                let (c, s) = turn(angle)
                // Sampled round a circle of the surface noise rather than along
                // a line, so the last step round meets the first with no seam.
                let wander = radius > 0
                    ? 0.0025 * wobble(1.5 * c + Double(r) * 0.3, 1.5 * s, wavelength: 0.5, seed: seed) : 0
                mesh.positions.append(SIMD3<Float>(Float((radius + wander) * c), Float(y),
                                                   Float((radius + wander) * s)))
            }
        }
        let stride = UInt32(around + 1)
        for r in 0..<UInt32(profile.count - 1) {
            for a in 0..<UInt32(around) {
                let i = r * stride + a, j = i + stride
                mesh.indices.append(contentsOf: [i, j, i + 1, i + 1, j, j + 1])
            }
        }
        mesh.computeNormals()
        return mesh
    }

    /// The soil in a pot: a disc just inside the rim, a little domed, the way
    /// compost settles after watering. Its own mesh because it is its own
    /// colour.
    public static func potSoil(seed: UInt64) -> StructureMesh {
        let around = 20
        let radius = 0.075
        var mesh = StructureMesh()
        mesh.positions.append(SIMD3<Float>(0, Float(Glasshouse.potSoil + 0.006), 0))
        for a in 0...around {
            let angle = Double(a) / Double(around)
            let (c, s) = turn(angle)
            let r = radius + 0.002 * wobble(1.5 * c, 1.5 * s, wavelength: 0.4, seed: seed)
            mesh.positions.append(SIMD3<Float>(Float(r * c), Float(Glasshouse.potSoil), Float(r * s)))
        }
        for a in 1...UInt32(around) {
            mesh.indices.append(contentsOf: [0, a + 1, a])
        }
        mesh.computeNormals()
        return mesh
    }

    /// A point on the unit circle a fraction `t` of the way round, without
    /// `sin` or `cos`: the series the board's rounded corners are drawn with
    /// (`quarter`), good over a quarter turn and turned four times, so a pot is
    /// the same shape on every host.
    static func turn(_ t: Double) -> (Double, Double) {
        let whole = t - t.rounded(.down)
        let quarterIndex = min(3, Int(whole * 4))
        let within = whole * 4 - Double(quarterIndex)
        let (c, s) = quarter(within * Double.pi / 2)
        switch quarterIndex {
        case 0: return (c, s)
        case 1: return (-s, c)
        case 2: return (-c, -s)
        default: return (s, -c)
        }
    }
}
