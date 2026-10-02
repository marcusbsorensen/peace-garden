#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// A round glasshouse: the house the Glasshouse is since 2 October 2026, its
/// wall a ring of glass, its roof a dome of glass on curved ribs, a sliding
/// door slid open round the outside of the wall. One of `Organic`'s
/// structures; the noise it wanders with is in `Organic`, and its bars are the
/// bench's boards, swept along a curve.
///
/// **Laid by hand, not turned on a lathe.** The wall follows the table's
/// `house` curve (`PlaceTable.glasshouseWheel`), whose radius wanders outward
/// by up to 4 cm, so the sill, the eaves and every ring up the dome wander
/// with it; each post leans a few millimetres off true; and every rib and ring
/// is swept along a curve (Marcus, 18 September: no straight lines). It was a
/// span house of straight bars until then, `Organic.spanHouse`, now gone.
///
/// **In two pieces, because it is two materials**, as the cold frame's lights
/// are: the painted bars, lit as the bench is, and the glass, which the page
/// draws last and sees through.
///
/// Both stand on `y = 0`, centred on the origin, with the doorway at
/// `Glasshouse.doorTurn` — in the gap between the staging's two ends.
/// **Glazed to the ground**, with no brick base under the wall glass: a dwarf
/// wall would hide the pots from every quarter turn.
///
/// **Unnamed**, as every structure is. A named structure is forty-two
/// translations.
extension Organic {

    /// How thick a glasshouse's bars are, across and deep; and its sill.
    static let houseBar = 0.045
    static let houseBarDeep = 0.06
    static let houseSill = 0.10

    /// The doorway, and how high its head is: the width of a barrow and the
    /// height of a gardener.
    public static let doorHalf = 0.40
    public static let doorHead = 1.95

    /// **How many bays the wall is glazed in**, the doorway besides: fourteen
    /// round 13 m of wall puts a post about every 0.9 m, the span a glazing
    /// bar is made for, and a rib rises from every post.
    static let houseBays = 14

    /// The ring at the top of the dome the ribs end on, the cap over it, and
    /// the ring partway up, as a fraction of the way out to the wall, that
    /// carries the glass between them.
    static let crownRing = 0.22
    static let purlinAt = 0.58

    // MARK: The wall, as the table lays it

    /// The house's wall, walked by length: the table's `house` curve, point
    /// `i` at turn `i / n`, closed.
    struct Wall {
        let points: [SIMD2<Double>]
        let run: [Double]

        init() {
            let curve = Glasshouse.table.curve("house", on: .plain)
            points = curve.points.map { SIMD2($0.x, $0.z) }
            var run = [0.0]
            for i in 1...points.count {
                run.append(run[i - 1] + Organic.length(points[i % points.count] - points[i - 1]))
            }
            self.run = run
        }

        var total: Double { run[points.count] }

        /// How far round the wall the middle of the doorway is: the point at
        /// `Glasshouse.doorTurn`, which the table puts on a point of its own.
        var door: Double {
            run[Int((Double(points.count) * Glasshouse.doorTurn).rounded())]
        }

        /// The point `s` metres round the wall from point 0, either way round.
        func at(_ s: Double) -> SIMD2<Double> {
            let want = s - (s / total).rounded(.down) * total
            var i = 1
            while i < points.count && run[i] < want { i += 1 }
            let t = (want - run[i - 1]) / max(1e-12, run[i] - run[i - 1])
            let a = points[i - 1], b = points[i % points.count]
            return a + (b - a) * t
        }

        /// Points from `from` to `to` metres round, both ends included, about
        /// `step` apart.
        func along(from: Double, to: Double, step: Double = 0.08) -> [SIMD2<Double>] {
            let n = max(1, Int(((to - from) / step).rounded(.up)))
            return (0...n).map { at(from + (to - from) * Double($0) / Double(n)) }
        }

        /// Where the posts stand, in metres round: the doorway's two, then
        /// `houseBays` equal bays round from one to the other.
        var posts: [Double] {
            let start = door + Organic.doorHalf, glazed = total - 2 * Organic.doorHalf
            return (0...Organic.houseBays).map { start + glazed * Double($0) / Double(Organic.houseBays) }
        }
    }

    static func length(_ v: SIMD2<Double>) -> Double { (v.x * v.x + v.y * v.y).squareRoot() }
    static func length(_ v: SIMD3<Double>) -> Double { (v.x * v.x + v.y * v.y + v.z * v.z).squareRoot() }
    static func cross(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> SIMD3<Double> {
        SIMD3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
    }

    /// **The dome**: how high it stands at a fraction `f` of the way out from
    /// the middle to the wall under it — the eaves at the wall and the crown
    /// in the middle, as `1 − f²`. Over a wall at `houseRadius` it is
    /// `Glasshouse.roof`; over one further out it is higher.
    static func dome(_ f: Double) -> Double {
        Glasshouse.eaves + (Glasshouse.crown - Glasshouse.eaves) * (1 - f * f)
    }

    /// A point on the dome over wall point `w`, a fraction `f` of the way out,
    /// lifted `over` off it; and which way is up off the dome there.
    static func onDome(_ w: SIMD2<Double>, _ f: Double, over: Double = 0) -> SIMD3<Double> {
        SIMD3(w.x * f, dome(f) + over, w.y * f)
    }

    static func domeNormal(_ w: SIMD2<Double>, _ f: Double) -> SIMD3<Double> {
        let r2 = w.x * w.x + w.y * w.y
        let k = 2 * (Glasshouse.crown - Glasshouse.eaves) * f / r2
        return SIMD3(w.x * k, 1, w.y * k)
    }

    // MARK: Bars along a curve

    /// **A bar swept along a curve**: the bench's board section, a rectangle
    /// with its corners rounded, carried along `path` with its depth toward
    /// `hint` at each point and its width across. A ring when `closed`; a bar
    /// with its two ends shut otherwise.
    static func rod(_ path: [SIMD3<Double>], hint: (Int) -> SIMD3<Double>, width: Double, deep: Double,
                    closed: Bool = false) -> StructureMesh {
        let n = path.count
        let around = 12
        let radius = min(0.012, min(width, deep) * 0.35)
        var mesh = StructureMesh()
        for j in 0..<n {
            let before = closed ? path[(j + n - 1) % n] : path[max(0, j - 1)]
            let after = closed ? path[(j + 1) % n] : path[min(n - 1, j + 1)]
            let d = after - before
            let along = d / max(1e-12, length(d))
            let side = cross(hint(j), along)
            let across = side / max(1e-12, length(side))
            let up = cross(along, across)
            for a in 0...around {
                let (x, y, _, _) = boardSection(Double(a) / Double(around), halfWidth: width / 2,
                                                halfThick: deep / 2, radius: radius)
                let p = path[j] + across * x + up * y
                mesh.positions.append(SIMD3<Float>(Float(p.x), Float(p.y), Float(p.z)))
            }
        }
        let stride = around + 1
        let spans = closed ? n : n - 1
        for r in 0..<spans {
            let next = (r + 1) % n
            for a in 0..<around {
                let i = UInt32(r * stride + a), j = UInt32(next * stride + a)
                mesh.indices.append(contentsOf: [i, i + 1, j, i + 1, j + 1, j])
            }
        }
        if !closed {
            for (ring, flip) in [(0, false), (n - 1, true)] {
                let centre = UInt32(mesh.positions.count)
                let c = path[ring]
                mesh.positions.append(SIMD3<Float>(Float(c.x), Float(c.y), Float(c.z)))
                for a in 0..<around {
                    let i = UInt32(ring * stride + a)
                    mesh.indices.append(contentsOf: flip ? [centre, i, i + 1] : [centre, i + 1, i])
                }
            }
        }
        return mesh
    }

    /// One straight bar between two points: the bench's plank, turned to run
    /// from `a` to `b`, `width` across and `deep` in the direction nearest to
    /// up. For what is short and hidden — the staging's legs and bearers.
    static func bar(from a: SIMD3<Double>, to b: SIMD3<Double>, width: Double, deep: Double,
                    seed: UInt64) -> StructureMesh {
        let d = b - a
        let size = length(d)
        let along = d / size
        // Across: level, at right angles to the bar. A bar that is itself
        // upright is given `x` for across.
        let level = SIMD3<Double>(along.z, 0, -along.x)
        let levelLength = (level.x * level.x + level.z * level.z).squareRoot()
        let across = levelLength > 1e-6 ? level / levelLength : SIMD3<Double>(1, 0, 0)
        let up = cross(across, along)
        var piece = plank(length: size, width: width, thickness: deep, lift: -deep / 2, seed: seed)
        let middle = (a + b) / 2
        for v in piece.positions.indices {
            let p = SIMD3<Double>(Double(piece.positions[v].x), Double(piece.positions[v].y),
                                  Double(piece.positions[v].z))
            let q = middle + across * p.x + up * p.y + along * p.z
            piece.positions[v] = SIMD3<Float>(Float(q.x), Float(q.y), Float(q.z))
        }
        return piece
    }

    // MARK: The frame

    /// The house's frame, as its bars: a sill round the foot, broken at the
    /// doorway; a post at every bay, each leaning a few millimetres off true;
    /// the eaves plate round the top of the wall; a rib curving up the dome
    /// from every post to the ring at the crown, a second ring partway up,
    /// and a cap over the crown; the doorway's head — and the door, slid open
    /// round the outside of the wall.
    ///
    /// **The door is open**, for the reason the cold frame's lights are
    /// propped: the garden is lit at midday, and by day a glasshouse door
    /// stands open to let the heat out.
    public static func roundHouse(seed: UInt64) -> StructureMesh {
        var mesh = StructureMesh()
        let wall = Wall()
        let w = houseBar, deep = houseBarDeep
        let level = { (_: Int) in SIMD3<Double>(0, 1, 0) }
        let put = { (piece: StructureMesh, mesh: inout StructureMesh) in
            append(piece, to: &mesh, turned: false, at: .zero)
        }
        let posts = wall.posts

        // The sill: a board round the foot of the glass, from one side of the
        // doorway all the way round to the other.
        let sill = wall.along(from: posts[0], to: posts[houseBays]).map { SIMD3($0.x, houseSill / 2, $0.y) }
        put(rod(sill, hint: level, width: 0.07, deep: houseSill), &mesh)

        // The eaves plate, all the way round, over the doorway too.
        let ring = wall.points.map { SIMD3($0.x, Glasshouse.eaves, $0.y) }
        put(rod(ring, hint: level, width: w, deep: deep, closed: true), &mesh)

        // The posts, each from the sill (the doorway's from the floor) to the
        // eaves, bowed off true by a few millimetres from the seed: a post set
        // by hand is plumb to the eye and not to a level.
        for (k, s) in posts.enumerated() {
            let foot = wall.at(s)
            let out = foot / length(foot)
            let tangent = SIMD2(-out.y, out.x)
            let from = k == 0 || k == houseBays ? 0.0 : houseSill
            let lean = 0.006 * wobble(Double(k) * 1.7, wavelength: 1, seed: mix64(seed &+ 71))
            let path = (0...6).map { (i: Int) -> SIMD3<Double> in
                let t = Double(i) / 6
                let bow = lean * 4 * t * (1 - t)
                return SIMD3(foot.x + tangent.x * bow, from + (Glasshouse.eaves - from) * t,
                             foot.y + tangent.y * bow)
            }
            put(rod(path, hint: { _ in SIMD3(out.x, 0, out.y) }, width: w, deep: deep), &mesh)
        }

        // The ribs: up the dome from every post to the crown ring, deep
        // across the dome rather than across the plot, so each reads as a
        // curved bar from any side.
        for s in posts {
            let foot = wall.at(s)
            let top = crownRing / length(foot)
            let fs = (0...16).map { 1 - (1 - top) * Double($0) / 16 }
            let path = fs.map { onDome(foot, $0) }
            put(rod(path, hint: { domeNormal(foot, fs[$0]) }, width: w, deep: deep), &mesh)
        }

        // The ring partway up the dome, and the ring at the crown.
        let purlin = wall.points.map { onDome($0, purlinAt) }
        put(rod(purlin, hint: { domeNormal(wall.points[$0], purlinAt) }, width: w, deep: deep * 0.8,
                closed: true), &mesh)
        let crownPoints = stride(from: 0, to: wall.points.count, by: 4).map { wall.points[$0] }
        let crown = crownPoints.map { onDome($0, crownRing / length($0)) }
        put(rod(crown, hint: { domeNormal(crownPoints[$0], crownRing / length(crownPoints[$0])) },
                width: w, deep: deep, closed: true), &mesh)
        put(cap(seed: seed), &mesh)

        // The doorway's head, between its two posts.
        let head = wall.along(from: posts[houseBays] - wall.total, to: posts[0])
            .map { SIMD3($0.x, Organic.doorHead, $0.y) }
        put(rod(head, hint: level, width: w, deep: deep), &mesh)

        // The door: two stiles and three rails, curved to the wall and a
        // hand's breadth outside it, slid round past the doorway.
        let leaf = doorLeaf(wall)
        for s in [leaf.from, leaf.to] {
            let p = outside(wall, s)
            let out = p / length(p)
            put(rod([SIMD3(p.x, 0.02, p.y), SIMD3(p.x, doorHead - 0.03, p.y)],
                    hint: { _ in SIMD3(out.x, 0, out.y) }, width: w, deep: 0.04), &mesh)
        }
        for y in [0.05, 0.85, doorHead - 0.06] {
            let rail = stride(from: 0, through: 8, by: 1).map { (i: Int) -> SIMD3<Double> in
                let p = outside(wall, leaf.from + (leaf.to - leaf.from) * Double(i) / 8)
                return SIMD3(p.x, y, p.y)
            }
            put(rod(rail, hint: level, width: 0.04, deep: w), &mesh)
        }
        mesh.computeNormals()
        return mesh
    }

    /// Where the open door stands: from the doorway's edge on band 11's side,
    /// round the wall by its own width, in metres round — slid toward `x+`,
    /// so from the page's first view it stands across the wall in front of
    /// the staging's yellow end rather than edge on at the house's side.
    static func doorLeaf(_ wall: Wall) -> (from: Double, to: Double) {
        (wall.door - 3 * doorHalf + 0.02, wall.door - doorHalf + 0.02)
    }

    /// A point `s` metres round the wall, a hand's breadth outside it.
    static func outside(_ wall: Wall, _ s: Double) -> SIMD2<Double> {
        let p = wall.at(s)
        return p * (1 + 0.05 / length(p))
    }

    /// The cap over the crown: a squat turned boss, painted as the bars are,
    /// that the ribs and the glass end under.
    static func cap(seed: UInt64) -> StructureMesh {
        let base = dome(0) - 0.01
        let profile: [(Double, Double)] = [
            (crownRing + 0.035, base), (crownRing + 0.03, base + 0.035), (crownRing * 0.75, base + 0.075),
            (crownRing * 0.4, base + 0.1), (0.04, base + 0.115), (0.03, base + 0.17), (0.0, base + 0.19),
        ]
        let around = 24
        var mesh = StructureMesh()
        for (radius, y) in profile {
            for a in 0...around {
                let (c, s) = turn(Double(a) / Double(around))
                let r = radius + 0.002 * wobble(1.5 * c, 1.5 * s, wavelength: 0.5, seed: seed)
                mesh.positions.append(SIMD3<Float>(Float(r * c), Float(y), Float(r * s)))
            }
        }
        let stride = UInt32(around + 1)
        for r in 0..<UInt32(profile.count - 1) {
            for a in 0..<UInt32(around) {
                let i = r * stride + a, j = i + stride
                mesh.indices.append(contentsOf: [i, j, i + 1, i + 1, j, j + 1])
            }
        }
        return mesh
    }

    // MARK: The glass

    /// The house's glass: the wall a curved sheet a bay, sill to eaves, the
    /// doorway left open under its head; the dome a sheet a bay between two
    /// ribs, lapped in four from the crown down, each pane a glass's
    /// thickness under the one above it; and the door's own pane.
    ///
    /// **Each sheet with a ripple in it**, a couple of millimetres deep, as
    /// the cold frame's panes are and for their reason: clear glass is seen by
    /// what it reflects, and a ripple turns the light across a pane and
    /// catches it as a glint. On a dome every pane faces its own way, so the
    /// glints come round the house as it turns.
    public static func roundHouseGlass(seed: UInt64) -> StructureMesh {
        var mesh = StructureMesh()
        let wall = Wall()
        let posts = wall.posts
        var sheetSeed: UInt64 = 200

        /// One sheet: `at(u, v)` places a point for `u`, `v` in 0...1, `off(p)`
        /// is the way the ripple pushes it.
        func sheet(columns: Int, rows: Int, at: (Double, Double) -> SIMD3<Double>,
                   off: (SIMD3<Double>) -> SIMD3<Double>) {
            sheetSeed += 1
            let s = mix64(seed &+ sheetSeed)
            let base = UInt32(mesh.positions.count)
            for r in 0...rows {
                for c in 0...columns {
                    let p = at(Double(c) / Double(columns), Double(r) / Double(rows))
                    let ripple = 0.0018 * wobble(p.x + p.z, p.y + p.z * 0.5, wavelength: 0.25, seed: s)
                    let q = p + off(p) * ripple
                    mesh.positions.append(SIMD3<Float>(Float(q.x), Float(q.y), Float(q.z)))
                }
            }
            let stride = UInt32(columns + 1)
            for r in 0..<UInt32(rows) {
                for c in 0..<UInt32(columns) {
                    let i = base + r * stride + c, j = i + stride
                    mesh.indices.append(contentsOf: [i, j, i + 1, i + 1, j, j + 1])
                }
            }
        }
        let outward = { (p: SIMD3<Double>) -> SIMD3<Double> in
            let r = (p.x * p.x + p.z * p.z).squareRoot()
            return SIMD3(p.x / r, 0, p.z / r)
        }

        // The wall: a sheet a bay, sill to eaves, following the wall's wander.
        for b in 0..<houseBays {
            let s0 = posts[b], s1 = posts[b + 1]
            sheet(columns: 6, rows: 4, at: { u, v in
                let p = wall.at(s0 + (s1 - s0) * u)
                return SIMD3(p.x, houseSill + (Glasshouse.eaves - houseSill) * v, p.y)
            }, off: outward)
        }
        // Over the doorway, from its head to the eaves.
        let doorFrom = posts[houseBays] - wall.total, doorTo = posts[0]
        sheet(columns: 4, rows: 1, at: { u, v in
            let p = wall.at(doorFrom + (doorTo - doorFrom) * u)
            return SIMD3(p.x, doorHead + (Glasshouse.eaves - doorHead) * v, p.y)
        }, off: outward)

        // The dome, a bay between two ribs, over the doorway too, in four
        // panes lapped from the crown down.
        let bays = zip(posts, posts.dropFirst()).map { ($0, $1) } + [(doorFrom, doorTo)]
        let laps: [(Double, Double)] = [(1.0, 0.78), (0.79, purlinAt), (purlinAt + 0.01, 0.38), (0.39, 0.0)]
        for (s0, s1) in bays {
            for (k, lap) in laps.enumerated() {
                let over = houseBarDeep / 2 + 0.004 * Double(k + 1)
                sheet(columns: 6, rows: 3, at: { u, v in
                    let w = wall.at(s0 + (s1 - s0) * u)
                    let to = max(crownRing / length(w), lap.1)
                    return onDome(w, lap.0 + (to - lap.0) * v, over: over)
                }, off: { _ in SIMD3(0, 1, 0) })
            }
        }

        // The door's pane, standing where the door has been slid to.
        let leaf = doorLeaf(wall)
        sheet(columns: 6, rows: 6, at: { u, v in
            let p = outside(wall, leaf.from + (leaf.to - leaf.from) * u)
            return SIMD3(p.x, 0.05 + (doorHead - 0.1) * v, p.y)
        }, off: outward)

        mesh.computeNormals()
        return mesh
    }
}
