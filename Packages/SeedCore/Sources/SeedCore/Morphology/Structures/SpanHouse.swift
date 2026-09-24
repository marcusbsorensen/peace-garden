#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// A span house: the glasshouse the Glasshouse is, a ridge down its length and
/// two equal slopes of glass either side, glazed to the ground, with a sliding
/// door at one gable. One of `Organic`'s structures; the noise it wanders with
/// is in `Organic`, and its bars are the bench's boards.
///
/// **Named for what a glasshouse maker calls it**, and not `Glasshouse`, which
/// is the rule's name — a structure file cannot share a name with a rule file
/// in one module.
///
/// **In two pieces, because it is two materials**, as the cold frame's lights
/// are: the painted bars, lit as the bench is, and the glass, which the page
/// draws last and sees through.
///
/// Both stand on `y = 0`, centred on the origin, the ridge along `x` and the
/// door in the `x−` gable — the end the staging's spectrum and the border both
/// count from. **Glazed to the ground**, with no brick base under the side
/// glass: a dwarf wall would hide the pots from half the page's quarter turns.
///
/// **Unnamed**, as every structure is. A named structure is forty-two
/// translations.
extension Organic {

    /// How thick a glasshouse's bars are, across and deep; and its sill.
    static let houseBar = 0.045
    static let houseBarDeep = 0.06
    static let houseSill = 0.10

    /// The doorway in the `x−` gable, and how high its head is: the width of a
    /// barrow and the height of a gardener.
    public static let doorHalf = 0.40
    public static let doorHead = 1.95

    /// Where the bays of the side walls and the roof are divided: every
    /// quarter of the house's length, which puts a rafter and a stud about
    /// every 1.1 m — the span a glazing bar is made for.
    static func houseBays(length: Double) -> [Double] {
        (0...4).map { -length / 2 + Double($0) * length / 4 }
    }

    /// One bar between two points: the bench's plank, turned to run from `a`
    /// to `b`, `width` across and `deep` in the direction nearest to up.
    static func bar(from a: SIMD3<Double>, to b: SIMD3<Double>, width: Double, deep: Double,
                    seed: UInt64) -> StructureMesh {
        let d = b - a
        let length = (d.x * d.x + d.y * d.y + d.z * d.z).squareRoot()
        let along = d / length
        // Across: level, at right angles to the bar. A bar that is itself
        // upright is given `x` for across.
        let level = SIMD3<Double>(along.z, 0, -along.x)
        let levelLength = (level.x * level.x + level.z * level.z).squareRoot()
        let across = levelLength > 1e-6 ? level / levelLength : SIMD3<Double>(1, 0, 0)
        let up = SIMD3<Double>(across.y * along.z - across.z * along.y,
                               across.z * along.x - across.x * along.z,
                               across.x * along.y - across.y * along.x)
        var piece = plank(length: length, width: width, thickness: deep, lift: -deep / 2, seed: seed)
        let middle = (a + b) / 2
        for v in piece.positions.indices {
            let p = SIMD3<Double>(Double(piece.positions[v].x), Double(piece.positions[v].y),
                                  Double(piece.positions[v].z))
            let q = middle + across * p.x + up * p.y + along * p.z
            piece.positions[v] = SIMD3<Float>(Float(q.x), Float(q.y), Float(q.z))
        }
        return piece
    }

    /// The house's frame, as its bars: a sill round the foot, a post at each
    /// corner and a stud at each bay, a plate along each eave, a ridge, a
    /// rafter at every bay from eave to ridge, the gables' own studs, the
    /// doorway's posts and head — and the door, slid open along the outside of
    /// the gable.
    ///
    /// **The door is open**, for the reason the cold frame's lights are
    /// propped: the garden is lit at midday, and by day a glasshouse door
    /// stands open to let the heat out.
    public static func spanHouse(length: Double = Glasshouse.houseLength, width: Double = Glasshouse.houseWidth,
                                 eaves: Double = Glasshouse.eaves, ridge: Double = Glasshouse.ridge,
                                 seed: UInt64) -> StructureMesh {
        var mesh = StructureMesh()
        let w = houseBar, deep = houseBarDeep
        let hx = length / 2, hz = width / 2
        var n: UInt64 = 60
        let next = { () -> UInt64 in n += 1; return mix64(seed &+ n) }
        let put = { (a: SIMD3<Double>, b: SIMD3<Double>, mesh: inout StructureMesh) in
            append(bar(from: a, to: b, width: w, deep: deep, seed: next()), to: &mesh, turned: false,
                   at: .zero)
        }
        let roof = { (z: Double) in ridge - (ridge - eaves) * min(1, abs(z) / hz) }
        let sillTop = houseSill

        // The sill: a board round the foot of the glass, broken at the doorway.
        let sill = { (a: SIMD3<Double>, b: SIMD3<Double>, mesh: inout StructureMesh) in
            append(bar(from: a, to: b, width: 0.07, deep: sillTop, seed: next()), to: &mesh, turned: false,
                   at: .zero)
        }
        for z in [-hz, hz] {
            sill(SIMD3(-hx, sillTop / 2, z), SIMD3(hx, sillTop / 2, z), &mesh)
        }
        sill(SIMD3(hx, sillTop / 2, -hz), SIMD3(hx, sillTop / 2, hz), &mesh)
        sill(SIMD3(-hx, sillTop / 2, -hz), SIMD3(-hx, sillTop / 2, -doorHalf), &mesh)
        sill(SIMD3(-hx, sillTop / 2, doorHalf), SIMD3(-hx, sillTop / 2, hz), &mesh)

        // The side walls: a post or a stud at every bay, and the eave plate.
        for z in [-hz, hz] {
            for x in houseBays(length: length) {
                put(SIMD3(x, sillTop, z), SIMD3(x, eaves, z), &mesh)
            }
            put(SIMD3(-hx, eaves, z), SIMD3(hx, eaves, z), &mesh)
        }

        // The roof: the ridge, and a rafter at every bay down both slopes.
        put(SIMD3(-hx, ridge, 0), SIMD3(hx, ridge, 0), &mesh)
        for x in houseBays(length: length) {
            for z in [-hz, hz] {
                put(SIMD3(x, eaves, z), SIMD3(x, ridge, 0), &mesh)
            }
        }

        // The far gable: a stud up the middle to the ridge, and one either side
        // of it up to the roof.
        for z in [-hz / 2, 0, hz / 2] {
            put(SIMD3(hx, sillTop, z), SIMD3(hx, roof(z), z), &mesh)
        }
        // The door's gable: the same studs either side, the doorway's two posts
        // and its head, and the middle stud from the head to the ridge.
        for z in [-hz / 2, hz / 2] {
            put(SIMD3(-hx, sillTop, z), SIMD3(-hx, roof(z), z), &mesh)
        }
        for z in [-doorHalf, doorHalf] {
            put(SIMD3(-hx, 0, z), SIMD3(-hx, doorHead, z), &mesh)
        }
        put(SIMD3(-hx, doorHead, -doorHalf), SIMD3(-hx, doorHead, doorHalf), &mesh)
        put(SIMD3(-hx, doorHead, 0), SIMD3(-hx, ridge, 0), &mesh)

        // The door, slid open along the outside of the gable toward `z+`: its
        // two stiles and three rails, a hand's breadth proud of the gable.
        let door = doorLeaf(outside: -hx)
        for z in [door.from, door.to] {
            put(SIMD3(door.x, 0.02, z), SIMD3(door.x, doorHead - 0.03, z), &mesh)
        }
        for y in [0.05, 0.85, doorHead - 0.06] {
            put(SIMD3(door.x, y, door.from), SIMD3(door.x, y, door.to), &mesh)
        }
        mesh.computeNormals()
        return mesh
    }

    /// Where the open door stands: its plane, just outside the gable at `x`,
    /// and the span of `z` it covers, slid along past the doorway.
    static func doorLeaf(outside x: Double) -> (x: Double, from: Double, to: Double) {
        (x - 0.05, doorHalf - 0.02, 3 * doorHalf - 0.02)
    }

    /// The house's glass: the two slopes of the roof, the two side walls, the
    /// two gables — the door's with its doorway left open — and the door's
    /// own pane.
    ///
    /// **Each bay a sheet with a ripple in it**, a couple of millimetres deep,
    /// as the cold frame's panes are and for their reason: clear glass is seen
    /// by what it reflects, and a ripple turns the light across a pane and
    /// catches it as a glint. The roof is lapped, as a roof is glazed, in four
    /// panes down each slope; the walls are not, because vertical glass is set
    /// in one sheet a bay.
    public static func spanHouseGlass(length: Double = Glasshouse.houseLength,
                                      width: Double = Glasshouse.houseWidth,
                                      eaves: Double = Glasshouse.eaves, ridge: Double = Glasshouse.ridge,
                                      seed: UInt64) -> StructureMesh {
        var mesh = StructureMesh()
        let hx = length / 2, hz = width / 2
        let bays = houseBays(length: length)
        let roof = { (z: Double) in ridge - (ridge - eaves) * min(1, abs(z) / hz) }
        var sheetSeed: UInt64 = 200

        /// One sheet: `at(u, v)` places a point for `u`, `v` in 0...1, `off`
        /// is how the ripple pushes it, and `keep` may leave out a cell.
        func sheet(columns: Int, rows: Int, at: (Double, Double) -> SIMD3<Double>,
                   off: SIMD3<Double>, keep: (SIMD3<Double>) -> Bool = { _ in true }) {
            sheetSeed += 1
            let s = mix64(seed &+ sheetSeed)
            let base = UInt32(mesh.positions.count)
            for r in 0...rows {
                for c in 0...columns {
                    let u = Double(c) / Double(columns), v = Double(r) / Double(rows)
                    let p = at(u, v)
                    let ripple = 0.0018 * wobble(p.x + p.z, p.y + p.z * 0.5, wavelength: 0.25, seed: s)
                    let q = p + off * ripple
                    mesh.positions.append(SIMD3<Float>(Float(q.x), Float(q.y), Float(q.z)))
                }
            }
            let stride = UInt32(columns + 1)
            for r in 0..<UInt32(rows) {
                for c in 0..<UInt32(columns) {
                    let i = base + r * stride + c, j = i + stride
                    let middle = (at((Double(c) + 0.5) / Double(columns), (Double(r) + 0.5) / Double(rows)))
                    guard keep(middle) else { continue }
                    mesh.indices.append(contentsOf: [i, j, i + 1, i + 1, j, j + 1])
                }
            }
        }

        // The roof, each slope in four panes lapped from the ridge down, each
        // pane a glass's thickness under the one above it.
        let panes = 4, lap = 0.03
        for side in [-1.0, 1.0] {
            let slope = hz
            let paneRun = (slope + Double(panes - 1) * lap) / Double(panes)
            for b in 0..<(bays.count - 1) {
                for p in 0..<panes {
                    let z0 = side * (Double(p) * (paneRun - lap)), z1 = side * (Double(p) * (paneRun - lap) + paneRun)
                    let over = 0.004 * Double(panes - p)
                    sheet(columns: 5, rows: 3, at: { u, v in
                        let x = bays[b] + (bays[b + 1] - bays[b]) * u
                        let z = z0 + (z1 - z0) * v
                        return SIMD3(x, roof(min(abs(z), hz)) + Self.houseBarDeep / 2 + over, z)
                    }, off: SIMD3(0, 1, 0))
                }
            }
        }

        // The side walls, a sheet a bay, from the sill to the eave.
        for z in [-hz, hz] {
            for b in 0..<(bays.count - 1) {
                sheet(columns: 4, rows: 4, at: { u, v in
                    SIMD3(bays[b] + (bays[b + 1] - bays[b]) * u, houseSill + (eaves - houseSill) * v, z)
                }, off: SIMD3(0, 0, 1))
            }
        }

        // The gables, from the sill up to the roof line; the door's leaves its
        // doorway open.
        for x in [-hx, hx] {
            sheet(columns: 12, rows: 10, at: { u, v in
                let z = -hz + width * u
                return SIMD3(x, houseSill + (roof(z) - houseSill) * v, z)
            }, off: SIMD3(1, 0, 0), keep: { p in
                !(x < 0 && abs(p.z) < doorHalf && p.y < doorHead)
            })
        }

        // The door's pane, standing where the door has been slid to.
        let door = doorLeaf(outside: -hx)
        sheet(columns: 3, rows: 6, at: { u, v in
            SIMD3(door.x, 0.05 + (doorHead - 0.1) * v, door.from + (door.to - door.from) * u)
        }, off: SIMD3(1, 0, 0))

        mesh.computeNormals()
        return mesh
    }
}
