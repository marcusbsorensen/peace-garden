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
    /// **`domed` is about what happens at the two ends.** A hedge that stops
    /// has a long shoulder falling to the ground, which is what a hedge looks
    /// like where somebody stopped planting, and it is how the Long Walk's two
    /// runs end. A hedge that goes round an enclosure never stops: each of the
    /// four runs carries on into the next, so its ends are cut square and
    /// buried inside its neighbour. Domed ends there leave a notch at every
    /// corner you can see the sky through, because the shoulder falls away over
    /// half the hedge's height — a metre on a two-metre hedge, which no sane
    /// overlap covers.
    ///
    /// **`bow` is how far the middle of the run stands off the straight line
    /// between its two ends**, in metres, toward `x+`. A run that follows a
    /// curve is the difference between a knot and a trellis: the eye follows a
    /// ribbon through a crossing, and a ribbon drawn with a ruler is a grid
    /// however it is woven. The two ends stay where a straight run's ends are,
    /// so a caller bows a run without moving it, and the crossings of a weave
    /// stay where they were put.
    ///
    /// **The line leaves both ends flat**, along the straight line between
    /// them, and does its standing off in the middle. That is what makes a
    /// bowed run join on to its neighbours: a weave is built out of stretches
    /// that meet at the crossings, and a stretch that arrived at a crossing
    /// still turning would meet the next one at a corner, cut its end at a
    /// slant, and leave the two faces of a joint showing. Flat ends mean a
    /// crossing is the one place on the whole run where nothing is happening,
    /// which is where a weave wants its joints and its cuts.
    ///
    /// So the line is `(1 - f²)²` across `f` in -1...1 rather than a circle's
    /// arc — a polynomial, for the reason `quarter` is one: every host has to
    /// get the same bits. It is also the shape a run of clipped box actually
    /// takes between two fixed points, which a circle's arc is not.
    public static func hedge(length: Double, height: Double, thickness: Double,
                             seed: UInt64, domed: Bool = true,
                             bow: Double = 0) -> StructureMesh {
        let rings = max(4, Int((length / 0.06).rounded()))
        let around = 20
        // The ends: narrowing over about a hedge's thickness, and the top
        // rounding down over half its height, so an end is a long shoulder
        // falling to the ground rather than a cut face with a rounded corner.
        let endWide = domed ? min(thickness * 0.8, length / 2) : 0
        let endHigh = domed ? min(max(thickness, height * 0.5), length / 2) : 0
        var mesh = StructureMesh()

        for r in 0...rings {
            let along = -length / 2 + Double(r) / Double(rings) * length
            let fromEnd = min(along + length / 2, length / 2 - along)
            let wide = fromEnd >= endWide ? 1.0 : squareRoot(max(0, 1 - pow2(1 - fromEnd / endWide)))
            let high = fromEnd >= endHigh ? 1.0 : squareRoot(max(0, 1 - pow2(1 - fromEnd / endHigh)))
            let top = height * (1 + 0.08 * wobble(along, wavelength: 0.7, seed: mix64(seed &+ 3)))
            // Where the bowed line is at this ring, how steeply it leans, and
            // the length of (lean, 1) — which turns the section with the line,
            // so the run keeps its thickness the whole way round the bow
            // instead of thinning where it leans hardest.
            let fraction = 2 * along / length               // -1 at one end, +1 at the other
            let hump = 1 - fraction * fraction
            let stands = bow * hump * hump
            let lean = -8 * bow * fraction * hump / length
            let spread = squareRoot(1 + lean * lean)
            for a in 0...around {
                let angle = Double(a) / Double(around)          // 0 at the ground on one face, round over the top, to 1 at the ground on the other
                let (sx, sy, nx, ny) = section(angle, halfWidth: thickness / 2, height: top)
                let bump = 0.035 * wobble(along, angle * 3.2, wavelength: 0.35, seed: seed)
                let side = (sx + nx * bump) * wide
                let y = sy == 0 ? 0 : (sy + ny * bump) * high
                // A run that does not bow is the line it has always been, to
                // the bit: four areas' hedges are drawn by this call and none
                // of them should move because a fifth one curves.
                let (x, z) = bow == 0
                    ? (side, along)
                    : (stands + side / spread, along - side * lean / spread)
                mesh.positions.append(SIMD3<Float>(Float(x), Float(y), Float(z)))
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

    // MARK: A bench

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

    // MARK: A roundel

    /// The paving where the Crossing's four paths meet: a low disc standing
    /// proud of the ground, cambered a little so it catches the light.
    ///
    /// **The first structure in the garden that is neither hedge nor bench**,
    /// and the first that is round. It is laid rather than grown, so like the
    /// bench its wander is small and lives in the edge — 0.035 m on a metre of
    /// radius, which is a rim of stones set by hand rather than a poured circle.
    /// A perfect circle is not a straight line, but it is the same fault:
    /// nothing in this garden was made by a machine.
    ///
    /// It has a rim down to the ground rather than sitting flat on it, because
    /// paving that meets grass at no height at all reads as a texture painted on
    /// the lawn from the isometric view every plot is seen at.
    ///
    /// **Unnamed**, as the hedges, the lights and the bench are.
    public static func roundel(radius: Double = 0.85, lift: Double = 0.05,
                               seed: UInt64) -> StructureMesh {
        let segments = 96
        let rings = 6
        let camber = 0.008
        let perimeter = 2 * Double.pi * radius
        var mesh = StructureMesh()

        // The edge, worked out once, so the top and the rim below it share it
        // exactly and no seam opens between them.
        var edge: [Double] = []
        for a in 0...segments {
            let p = Double(a) / Double(segments) * perimeter
            edge.append(radius + 0.035 * seamless(p, perimeter: perimeter,
                                                  wavelength: 1.1, seed: seed))
        }

        for r in 0...rings {
            let t = Double(r) / Double(rings)
            for a in 0...segments {
                let (cx, cz) = circle(Double(a) / Double(segments))
                let out = t * edge[a]
                // **Uneven, or it is a lid.** A disc with smooth normals and a
                // gentle camber takes one broad highlight and reads as a
                // painted cover rather than as stones somebody laid. Seven
                // millimetres of unevenness is under the eye's notice as a
                // height and is the whole difference in how it is lit.
                let uneven = 0.007 * wobble(out * 1.9, Double(a) / Double(segments) * 2.4,
                                            wavelength: 0.5, seed: seed)
                mesh.positions.append(SIMD3<Float>(
                    Float(out * cx),
                    Float(lift + camber * (1 - t * t) + uneven),
                    Float(out * cz)
                ))
            }
        }
        let stride = segments + 1
        for r in 0..<rings {
            for a in 0..<segments {
                let i = UInt32(r * stride + a), j = UInt32((r + 1) * stride + a)
                mesh.indices.append(contentsOf: [i, i + 1, j, i + 1, j + 1, j])
            }
        }

        // The rim, straight down to the grass.
        let top = UInt32(rings * stride)
        let foot = UInt32(mesh.positions.count)
        for a in 0...segments {
            let (cx, cz) = circle(Double(a) / Double(segments))
            mesh.positions.append(SIMD3<Float>(Float(edge[a] * cx), 0, Float(edge[a] * cz)))
        }
        for a in 0..<segments {
            let i = top + UInt32(a), j = foot + UInt32(a)
            mesh.indices.append(contentsOf: [i, i + 1, j, i + 1, j + 1, j])
        }
        mesh.computeNormals()
        return mesh
    }

    // MARK: A tree

    /// An orchard tree: a trunk that leans and a canopy that is not a ball. It
    /// stands on `y = 0`, centred on the origin, and is the tallest thing in the
    /// Orchard by a clear margin over anything a gardener can grow.
    ///
    /// **Grown rather than sawn**, which puts it on the hedge's side of the line
    /// the bench is on the other side of. The trunk wanders as it rises and the
    /// canopy is lumpy at two scales, because a tree drawn as a cylinder under a
    /// sphere is the clip art `docs/WEB-GARDENS.md` warns about, and no amount
    /// of good colour rescues it.
    ///
    /// **The canopy's roughness is sampled in space, not in angle.** Perturbing
    /// a ring by its angle leaves a seam where the angle wraps from one to zero;
    /// perturbing it by where the vertex actually is cannot, because the ring
    /// closes in space and so does the noise. The same trick does the trunk. It
    /// is why there is no `seamless` call here although the roundel beside it
    /// needs one — the roundel's noise runs *along* its edge, and this runs
    /// across a surface the edge lies on.
    ///
    /// **The canopy's underside clears the planting beneath it, completely.**
    /// A guild stands `Orchard.guildRadius` from the trunk, which is exactly the
    /// canopy's widest radius, so a guild plant stands at the drip line with the
    /// whole canopy above it — its lower surface there is 2.5 m up and the
    /// tallest plant this garden grows is 2.2 m.
    ///
    /// **It was not so at the first size tried.** A 1.7 m spread on a 1.55 m
    /// crown put the canopies so low and so close that they covered the planting
    /// from every angle, which fails the one thing this area is for: an orchard
    /// where you cannot see the guild is five trees. Lifting the crown and
    /// drawing it narrower leaves a clear 0.9 m between neighbouring canopies
    /// and every plant in open view.
    ///
    /// **The crown sits at 2.10 m rather than the 1.95 m that looked enough.**
    /// At 1.95 the lumpiness pulled the canopy's underside down to 2.24 m over
    /// the guild — clear of a 2.2 m plant by four centimetres, and *not* clear
    /// of the 2.35 m one the Crossing's three hundred threw up. The clearance is
    /// checked in `OrganicTests` against that 2.35 rather than against the
    /// tallest plant anybody has happened to grow.
    public static func tree(height: Double = 3.25, spread: Double = 1.5,
                            crownBase: Double = 2.10, seed: UInt64) -> StructureMesh {
        let around = 14
        let trunkRings = 12
        // **Coarse on purpose.** The first canopy was drawn at thirty segments
        // and twenty rings, and at that fineness it took one smooth highlight
        // and read as a green balloon on a stick — the roundel's mistake in
        // leaf. A canopy is clumps of foliage, so its faces have to be big
        // enough to be clumps: eighteen by twelve gives facets a few
        // centimetres across, which is the size a bunch of leaves is.
        let segments = 24
        let rings = 16
        let halfSpread = spread / 2
        let crownTop = max(crownBase + 0.4, height)
        let canopy = crownTop - crownBase
        var mesh = StructureMesh()

        /// How far the trunk's axis has wandered off plumb by this height. It is
        /// held to zero at the ground, so the tree is planted rather than
        /// floating, and the canopy rides the same wander so that no join shows.
        func lean(_ y: Double) -> (x: Double, z: Double) {
            let ramp = min(1, y / max(0.25, crownBase * 0.7))
            let reach = 0.07 * ramp * ramp
            return (reach * wobble(y, wavelength: 1.9, seed: mix64(seed &+ 5)),
                    reach * wobble(y, wavelength: 1.9, seed: mix64(seed &+ 6)))
        }

        /// Two scales of lumpiness, read from where a vertex is rather than from
        /// how far round it is.
        ///
        /// **The first octave is nearly as broad as the tree**, which is what
        /// makes a canopy lopsided rather than merely bumpy. The second is a
        /// third of that, for the lobes inside it. Drawn the other way round —
        /// both octaves short — the canopy stayed a sphere with a texture on it,
        /// and a sphere with a texture on it is still a sphere.
        func rough(_ x: Double, _ y: Double, _ z: Double) -> Double {
            0.66 * wobble(x, z, wavelength: 1.35, seed: seed)
                + 0.34 * wobble(z * 1.25, y * 1.7, wavelength: 0.48, seed: mix64(seed &+ 7))
        }

        // The trunk, from the ground to a little way into the canopy so that
        // nothing can open between the two.
        let trunkTop = crownBase + canopy * 0.22
        for r in 0...trunkRings {
            let t = Double(r) / Double(trunkRings)
            let y = t * trunkTop
            let axis = lean(y)
            // Thick at the foot, where a tree flares into its roots, and evenly
            // slimmer above it.
            let flare = t < 0.12 ? 1 + 0.9 * pow2(1 - t / 0.12) : 1
            let radius = (0.125 - 0.052 * t) * flare
            for a in 0...around {
                let (cx, cz) = circle(Double(a) / Double(around))
                let px = axis.x + radius * cx, pz = axis.z + radius * cz
                let bark = 1 + 0.11 * rough(px * 2.4, y * 2.4, pz * 2.4)
                mesh.positions.append(SIMD3<Float>(
                    Float(axis.x + radius * cx * bark),
                    Float(y),
                    Float(axis.z + radius * cz * bark)
                ))
            }
        }
        let trunkStride = around + 1
        for r in 0..<trunkRings {
            for a in 0..<around {
                let i = UInt32(r * trunkStride + a), j = UInt32((r + 1) * trunkStride + a)
                // Wound the opposite way round from the roundel's, because this
                // surface stands up where that one lies flat: the same order
                // that points a disc's faces at the sky points a cylinder's into
                // its own middle.
                mesh.indices.append(contentsOf: [i, j, i + 1, i + 1, j, j + 1])
            }
        }

        // The canopy: an ellipsoid on the trunk's own axis, pulled about.
        let base = UInt32(mesh.positions.count)
        for r in 0...rings {
            let t = Double(r) / Double(rings)
            let y = crownBase + t * canopy
            let axis = lean(y)
            let profile = squareRoot(max(0, 1 - pow2(2 * t - 1)))
            for a in 0...segments {
                let (cx, cz) = circle(Double(a) / Double(segments))
                let ideal = halfSpread * profile
                let px = axis.x + ideal * cx, pz = axis.z + ideal * cz
                // The lumpiness fades out at the two poles with the profile
                // itself, or a radius of nothing would be pulled into a spike.
                // **0.55, not the 0.20 the first pass used.** `wobble` is in
                // -1...1 but value noise only touches its ends: a typical
                // reading is about a third of the range, so a coefficient set
                // by the range gives a third of the lumpiness it looks like it
                // asks for. 0.20 drew a ball. This is a canopy a third of its
                // own radius out of true, which is about what a fruit tree is.
                let out = ideal + 0.55 * profile * rough(px, y, pz)
                mesh.positions.append(SIMD3<Float>(
                    Float(axis.x + out * cx),
                    Float(y),
                    Float(axis.z + out * cz)
                ))
            }
        }
        let stride = segments + 1
        for r in 0..<rings {
            for a in 0..<segments {
                let i = base + UInt32(r * stride + a), j = base + UInt32((r + 1) * stride + a)
                mesh.indices.append(contentsOf: [i, j, i + 1, i + 1, j, j + 1])
            }
        }

        mesh.computeNormals()

        // **The two poles are one point held by `segments + 1` vertices**, and
        // `computeNormals` gives each of them only the faces it happens to
        // touch — which draws a star of slightly different greens at the top of
        // every tree, the canopy's own mesh showing through exactly as the
        // roundel's rings once did. One averaged normal for the ring puts it
        // right, and it is the only place in this mesh where a vertex's normal
        // is not simply what its faces say.
        for ring in [0, rings] {
            let start = Int(base) + ring * stride
            guard mesh.normals.count >= start + stride else { continue }
            var sum = SIMD3<Float>(0, 0, 0)
            for a in 0...segments { sum += mesh.normals[start + a] }
            let length = (sum.x * sum.x + sum.y * sum.y + sum.z * sum.z).squareRoot()
            guard length > 0 else { continue }
            let unit = sum / length
            for a in 0...segments { mesh.normals[start + a] = unit }
        }
        return mesh
    }

    /// cos and sin of a whole turn, `turn` running 0 to 1, built out of
    /// `quarter` so that no host's libm is involved and every host gets the same
    /// bits — the same reason `quarter` itself is a polynomial.
    static func circle(_ turn: Double) -> (x: Double, z: Double) {
        let wrapped = turn - (turn / 1).rounded(.down)
        let q = wrapped * 4
        let leg = min(3, Int(q))
        let (c, s) = quarter((q - Double(leg)) * Double.pi / 2)
        switch leg {
        case 0:  return (c, s)
        case 1:  return (-s, c)
        case 2:  return (-c, -s)
        default: return (s, -c)
        }
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
