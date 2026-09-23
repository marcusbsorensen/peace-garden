#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// A garden seat, and the board it is built out of. One of `Organic`'s
/// structures; the noise it wanders with is in `Organic`.
extension Organic {

    /// A garden seat: a plank across two plank ends, with a back of two rails on
    /// short posts. It stands on `y = 0`, runs along `z`, is centred on the
    /// origin, and its back is on the `+x` side.
    ///
    /// **Sawn rather than grown.** The hedge beside it is a loaf that has bulged
    /// where it grew; this is boards that have weathered, so its wander is a
    /// fraction of the hedge's and it lives in the softness of the edges rather
    /// than in the line of the thing. A bench drawn with ruled edges among
    /// plants grown from a genome is the clip art `docs/WEB-GARDENS.md` warns
    /// about, and a bench that undulated like a hedge would be a different
    /// mistake: it would not read as made.
    ///
    /// **The back is what makes it a seat when you look down its length.**
    /// Backless, end-on it was one upright panel four tenths of a metre across
    /// and very nearly square — a slab — and two of the room's four quarter
    /// turns put it that way, so half of all the views of the Quiet Garden had
    /// it. A post above each end and two rails across them put a shoulder into
    /// that silhouette, which is the shape a seat is known by.
    ///
    /// **The back stands on `+x`, the side away from the lawn.** The room turns
    /// the bench so `+x` points into its own corner, so a sitter faces the
    /// middle of the room with the hedges behind them, which is the only way
    /// round a seat goes into the angle of two hedges.
    ///
    /// **Unnamed**, as the hedges and the lights are. A named structure is
    /// forty-two translations.
    public static func bench(length: Double = 1.5, height: Double = 0.45,
                             depth: Double = 0.42, seed: UInt64) -> StructureMesh {
        var mesh = StructureMesh()
        let board = 0.065
        // How far the back rises above the seat, and how far back it sits: over
        // the ends rather than overhanging them, so the seat stays the widest
        // thing in the silhouette and the back reads as carried by it.
        let rise = 0.33
        let backAt = Float(depth / 2 - board / 2)
        let endAt = { (end: Double) in Float(end * (length / 2 - 0.19)) }

        // The seat, swept along the bench's own length.
        append(plank(length: length, width: depth, thickness: board,
                     lift: height - board, seed: mix64(seed &+ 1)),
               to: &mesh, turned: false, at: SIMD3<Float>(0, 0, 0))

        for end in [-1.0, 1.0] {
            // Two ends, the same plank turned a quarter and stood on the ground.
            // Inset from the seat's ends, so the seat overhangs them the way a
            // bench's does and the whole thing does not read as a box.
            append(plank(length: depth, width: board, thickness: height - board,
                         lift: 0, seed: mix64(seed &+ UInt64(bitPattern: Int64(end)) &+ 7)),
                   to: &mesh, turned: true,
                   at: SIMD3<Float>(0, 0, endAt(end)))

            // A post standing on each end, square in plan, carrying the rails.
            append(plank(length: board, width: board, thickness: rise,
                         lift: height, seed: mix64(seed &+ UInt64(bitPattern: Int64(end)) &+ 11)),
                   to: &mesh, turned: false,
                   at: SIMD3<Float>(backAt, 0, endAt(end)))
        }

        // Two rails, with daylight between them, because a back in one piece is
        // the same panel the ends already are and would undo what it is for.
        for (i, rail) in [(lift: 0.06, deep: 0.10), (lift: 0.22, deep: 0.11)].enumerated() {
            append(plank(length: length, width: board, thickness: rail.deep,
                         lift: height + rail.lift, seed: mix64(seed &+ UInt64(i) &+ 13)),
                   to: &mesh, turned: false, at: SIMD3<Float>(backAt, 0, 0))
        }
        mesh.computeNormals()
        return mesh
    }

    /// One board: a rounded rectangle swept along `z`, `width` across `x` and
    /// `thickness` up `y`, its underside at `lift`.
    private static func plank(length: Double, width: Double, thickness: Double,
                              lift: Double, seed: UInt64) -> StructureMesh {
        let rings = max(3, Int((length / 0.09).rounded()))
        let around = 28
        let radius = min(0.018, min(width, thickness) * 0.35)
        var mesh = StructureMesh()
        for r in 0...rings {
            let along = -length / 2 + Double(r) / Double(rings) * length
            for a in 0...around {
                let angle = Double(a) / Double(around)
                let (x, y, nx, ny) = boardSection(angle, halfWidth: width / 2,
                                                  halfThick: thickness / 2, radius: radius)
                // A sawn board's wander: a twentieth of a hedge's, so an edge
                // is soft rather than wavy.
                let grain = 0.004 * wobble(along, angle * 2.1, wavelength: 0.5, seed: seed)
                mesh.positions.append(SIMD3<Float>(
                    Float(x + nx * grain),
                    Float(lift + thickness / 2 + y + ny * grain),
                    Float(along)
                ))
            }
        }
        let stride = around + 1
        for r in 0..<rings {
            for a in 0..<around {
                let i = UInt32(r * stride + a), j = UInt32((r + 1) * stride + a)
                mesh.indices.append(contentsOf: [i, i + 1, j, i + 1, j + 1, j])
            }
        }
        // The two ends, so a board is a solid and not a tube: a fan to the
        // middle of each ring.
        for (ring, flip) in [(0, false), (rings, true)] {
            let centre = UInt32(mesh.positions.count)
            mesh.positions.append(SIMD3<Float>(0, Float(lift + thickness / 2),
                                               Float(-length / 2 + Double(ring) / Double(rings) * length)))
            for a in 0..<around {
                let i = UInt32(ring * stride + a)
                mesh.indices.append(contentsOf: flip ? [centre, i, i + 1] : [centre, i + 1, i])
            }
        }
        return mesh
    }

    /// A board's cross-section: a rectangle with its four corners rounded, from
    /// `angle` 0 at the middle of the right-hand edge, anticlockwise round.
    static func boardSection(_ angle: Double, halfWidth: Double, halfThick: Double,
                             radius: Double) -> (x: Double, y: Double, nx: Double, ny: Double) {
        let w = max(0, halfWidth - radius), t = max(0, halfThick - radius)
        let arc = Double.pi / 2 * radius
        let runs = [t, arc, 2 * w, arc, 2 * t, arc, 2 * w, arc, t]
        // The corner each arc turns about, and the direction the straight before
        // it runs in: right edge up, top-right, top leftwards, and so on round.
        var p = angle * runs.reduce(0, +)
        var leg = 0
        while leg < runs.count - 1, p > runs[leg] { p -= runs[leg]; leg += 1 }
        let quarterTurn = { (t: Double) -> (Double, Double) in quarter(t / max(radius, 1e-9)) }
        switch leg {
        case 0:  return (halfWidth, p, 1, 0)
        case 1:  let (c, s) = quarterTurn(p); return (w + radius * c, t + radius * s, c, s)
        case 2:  return (w - p, halfThick, 0, 1)
        case 3:  let (c, s) = quarterTurn(p); return (-w - radius * s, t + radius * c, -s, c)
        case 4:  return (-halfWidth, t - p, -1, 0)
        case 5:  let (c, s) = quarterTurn(p); return (-w - radius * c, -t - radius * s, -c, -s)
        case 6:  return (-w + p, -halfThick, 0, -1)
        case 7:  let (c, s) = quarterTurn(p); return (w + radius * s, -t - radius * c, s, -c)
        default: return (halfWidth, -t + p, 1, 0)
        }
    }

    /// Copies one piece into another, optionally turned a quarter about `y`, so
    /// a bench's ends can be the same board as its seat.
    private static func append(_ piece: StructureMesh, to mesh: inout StructureMesh,
                               turned: Bool, at offset: SIMD3<Float>) {
        let base = UInt32(mesh.positions.count)
        for position in piece.positions {
            let turnedPosition = turned
                ? SIMD3<Float>(position.z, position.y, position.x)
                : position
            mesh.positions.append(turnedPosition + offset)
        }
        mesh.indices.append(contentsOf: piece.indices.map { $0 + base })
    }
}
