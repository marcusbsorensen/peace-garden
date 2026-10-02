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
    static let stagingSlats = 4
    static let stagingSlat = 0.085
    static let stagingSlatThick = 0.025
    static let stagingLeg = 0.05

    /// **The staging, as a ring round the inside of the round house**: slats
    /// curved along the table's `staging` line (`PlaceTable.glasshouseWheel`), on
    /// bearers across it, each bearer carried on a pair of legs. It stands on
    /// `y = 0` where the table lays it, its top at `Glasshouse.stagingTop`,
    /// `Glasshouse.stagingDepth` across, and its two ends either side of the
    /// door.
    ///
    /// **The slats follow the line's wander**, a centimetre either way, so the
    /// ring is laid by hand rather than turned; the pots stand on that line,
    /// so every pot is on the staging. Twelve frames of legs round 10 m, a
    /// little under a metre apart, which is what a run of slats a couple of
    /// centimetres thick will span loaded with wet pots without sagging.
    public static func ringStaging(seed: UInt64) -> StructureMesh {
        var mesh = StructureMesh()
        let depth = Glasshouse.stagingDepth, height = Glasshouse.stagingTop
        let slats = stagingSlats, slat = stagingSlat, thick = stagingSlatThick, leg = stagingLeg
        let gap = (depth - Double(slats) * slat) / Double(slats - 1)
        var n: UInt64 = 40
        let next = { () -> UInt64 in n += 1; return mix64(seed &+ n) }
        let line = Glasshouse.table.curve("staging", on: .plain).points.map { SIMD2($0.x, $0.z) }
        // Outward from the middle of the house at each point of the line: the
        // line runs round the middle, so across it is away from the middle.
        let out = line.map { $0 / length($0) }

        // The slats, running round the ring.
        for k in 0..<slats {
            let off = -depth / 2 + slat / 2 + Double(k) * (slat + gap)
            let path = line.indices.map { i -> SIMD3<Double> in
                let p = line[i] + out[i] * off
                return SIMD3(p.x, height - thick / 2, p.y)
            }
            append(rod(path, hint: { _ in SIMD3(0, 1, 0) }, width: slat, deep: thick), to: &mesh,
                   turned: false, at: .zero)
        }

        // The frames: a bearer across under the slats, on two legs, at even
        // steps along the line from a little in from either end.
        var run = [0.0]
        for i in 1..<line.count { run.append(run[i - 1] + length(line[i] - line[i - 1])) }
        let frames = 12
        let bearer = 0.06
        for f in 0..<frames {
            let want = 0.12 + (run[line.count - 1] - 0.24) * Double(f) / Double(frames - 1)
            var i = 1
            while i < line.count - 1 && run[i] < want { i += 1 }
            let t = (want - run[i - 1]) / max(1e-12, run[i] - run[i - 1])
            let at = line[i - 1] + (line[i] - line[i - 1]) * t
            let o = at / length(at)
            let across = { (by: Double) -> SIMD2<Double> in at + o * by }
            let under = height - thick - bearer / 2
            let a = across(-(depth / 2 - 0.01)), b = across(depth / 2 - 0.01)
            append(bar(from: SIMD3(a.x, under, a.y), to: SIMD3(b.x, under, b.y), width: leg, deep: bearer,
                       seed: next()), to: &mesh, turned: false, at: .zero)
            for side in [-1.0, 1.0] {
                let p = across(side * (depth / 2 - leg / 2 - 0.02))
                append(bar(from: SIMD3(p.x, 0, p.y), to: SIMD3(p.x, height - thick - bearer, p.y),
                           width: leg, deep: leg, seed: next()), to: &mesh, turned: false, at: .zero)
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
