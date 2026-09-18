import SceneKit
import SeedCore
import SwiftUI
import UIKit

/// What is built in a garden rather than grown: for now, the Long Walk's
/// hedges and its mown path. `docs/WEB-GARDENS.md` §*Structures need drawing
/// properly*.
///
/// **A hedge cut by hand is a loaf, not a box**: soft-shouldered, bulging where
/// it has grown, its top an undulating line and its ends rounded. The shape is
/// SeedCore's `Organic.hedge`, so the website's hedge is the same hedge; the
/// grain of the leaves on it and the garden's own light across it are here, and
/// it is rendered like a figure — by the plants' camera, under the plants'
/// light, at eight hours and four turns.
@MainActor
final class GardenStructures {
    static let shared = GardenStructures()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 160
    }

    // MARK: Hedges

    /// A hedge is drawn as a run of short pieces, each sorted into the garden
    /// by its own depth like a plant. A hedge the length of the plot is in front
    /// of some plants and behind others, and one picture cannot be both.
    nonisolated static let pieceLength = 0.4

    /// Through the hedge, across the walk.
    nonisolated static let thickness = 0.36

    /// A 2 m yew backdrop behind the far border, and a 0.7 m hedge in front of
    /// the near one, swapped as the plot turns. Settled by Marcus, 18 September:
    /// looking down from one side, a tall hedge on the near side hides the whole
    /// border behind it.
    static let tall = 2.0
    static let low = 0.7

    /// The picture a hedge piece is taken in, and where its foot is in it.
    static func figure(height: Double) -> GardenCreatures.Figure {
        let metres = height + 0.6
        return GardenCreatures.Figure(metres: metres, lift: 0.3 / metres, glow: .zero)
    }

    private var lines: [String: HedgeLine] = [:]

    /// One hedge, on side `-1` or `+1` of the path, built once for a plot and
    /// a ground and kept.
    func line(side: Int, height: Double, plotSide: Double, world: Int) -> HedgeLine {
        let key = "\(side)-\(Int(height * 100))-\(Int(plotSide * 100))-\(world)"
        if let held = lines[key] { return held }
        let built = HedgeLine(side: side, height: height, plotSide: plotSide, key: key) { x, z in
            GardenWorlds.shared.height(world: world, x: x, z: z, plotSide: plotSide)
        }
        if lines.count > 16 { lines.removeAll() }
        lines[key] = built
        return built
    }

    static func key(line: HedgeLine, piece: Int, step: Int, turn: Int) -> String {
        "hedge-\(line.key)-\(piece)-\(step)-\(((turn % 4) + 4) % 4)"
    }

    /// One piece of a hedge, photographed standing on its own ground.
    ///
    /// **Cut from the one mesh, not built on its own.** Each piece is a run of
    /// the hedge's rings, and neighbours share the ring they meet at — and one
    /// more either side, so a piece overlaps the next by a ring and the joint
    /// is the same surface drawn twice rather than two edges meeting. The
    /// square-ended boxes this replaces were square-ended because pieces with
    /// rounded ends each drew a dark seam at every joint; a piece of a
    /// continuous mesh has no end of its own to draw.
    func hedge(_ line: HedgeLine, piece index: Int, step: Int, turn: Int) -> UIImage? {
        let quarter = ((turn % 4) + 4) % 4
        let key = Self.key(line: line, piece: index, step: step, turn: quarter) as NSString
        if let held = cache.object(forKey: key) { return held }
        guard line.pieces.indices.contains(index) else { return nil }

        let figure = Self.figure(height: line.height)
        let side = CGFloat(figure.metres) * GardenCreatures.renderedPointsPerMetre / 2
        let view = SCNView(frame: CGRect(x: 0, y: 0, width: side, height: side))
        view.scene = GardenSprites.makeScene(lit: GardenGround.Light.at(step: step).turned(quarters: quarter))
        view.backgroundColor = .clear
        view.isOpaque = false
        view.antialiasingMode = .multisampling4X

        let node = SCNNode(geometry: line.geometry(piece: line.pieces[index]))
        node.geometry?.materials = [Self.yew]

        let pivot = SCNNode()
        pivot.eulerAngles.y = Float(quarter) * .pi / 2
        pivot.addChildNode(node)
        view.scene?.rootNode.addChildNode(pivot)
        view.pointOfView = GardenCreatures.camera(for: figure)

        let snapshot = view.snapshot()
        guard snapshot.size.width > 0 else { return nil }
        cache.setObject(snapshot, forKey: key)
        return snapshot
    }

    /// Clipped yew: dark, matte, and grained with the small leaves a clipped
    /// face is made of — a speckle of lighter and darker greens.
    ///
    /// **Picked half again brighter than yew looks on its own**, the rule the
    /// bank of earth under the plot already follows: a hedge's face is vertical,
    /// so it is lit by the sky and by little of the sun, and at yew's own
    /// darkness the face towards the path was black at midday.
    private static let yew: SCNMaterial = {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = leafGrain
        material.diffuse.wrapS = .repeat
        material.diffuse.wrapT = .repeat
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(2, 2, 1)
        material.roughness.contents = NSNumber(value: 0.92)
        material.metalness.contents = NSNumber(value: 0.0)
        return material
    }()

    private static let leafGrain: UIImage = {
        let side = 128
        var random = SplitMix64(seed: 0x7EE5)
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { context in
            UIColor(red: 0.27, green: 0.39, blue: 0.27, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 0, width: side, height: side))
            for _ in 0..<900 {
                let x = Double(random.next() % UInt64(side)), y = Double(random.next() % UInt64(side))
                let r = 1 + Double(random.next() % 3)
                let lift = Double(random.next() % 100) / 100 * 0.16 - 0.07
                UIColor(red: 0.27 + lift * 0.7, green: 0.40 + lift, blue: 0.27 + lift * 0.7, alpha: 1).setFill()
                context.cgContext.fillEllipse(in: CGRect(x: x, y: y, width: r, height: r * 0.7))
            }
        }
    }()
}

// MARK: - A hedge

/// One of the Long Walk's hedges: a single `Organic.hedge` mesh set down on the
/// plot, and the pieces it is drawn in.
///
/// **Its line is the walk's, and it may spill over the rim.** The hedge's
/// middle is where the website puts it, `LongWalk.hedgeFrom` plus half a
/// thickness out, all along its length (Marcus, 18 September): pulled in to
/// keep its outer foot on the worn ground, it stood in the back row of the
/// border, so its outer foot overhangs the edge of the clod instead, as a hedge
/// grown out over it would. It runs as far each way as its inner foot has
/// ground under it, and each end is the mesh's own rounded shoulder. Each ring
/// stands on the ground under the middle of it, so the hedge rides the
/// ground's rises in one piece.
struct HedgeLine {
    struct Piece {
        let index: Int
        /// The rings it is cut from, one more either side of its own.
        let rings: ClosedRange<Int>
        /// Where it stands, for the depth sort and the picture's foot.
        let spot: Spot
        /// The ground's height there, which its picture is taken relative to.
        let ground: Double
    }

    let side: Int
    let height: Double
    let key: String
    let rings: Int
    /// On the plot: `x` and `z` where each vertex stands, `y` its height above
    /// the plot's `y = 0`, ground included.
    let positions: [SIMD3<Float>]
    let normals: [SIMD3<Float>]
    /// Whether SeedCore's triangles are wound the way SceneKit takes as the
    /// back, which culls every face seen from outside.
    let flipped: Bool
    /// The first quad's six indices as SeedCore wrote them, so a piece is
    /// wound exactly as the whole mesh is, whichever way that is.
    private let quad: [UInt32]
    let pieces: [Piece]
    /// Each ring's two feet on the ground, and how far its top stands above it,
    /// for the shadow.
    let feet: [(outer: Spot, inner: Spot, tall: Double)]

    static let around = 20

    init(side: Int, height: Double, plotSide: Double, key: String,
         ground: (Double, Double) -> Double) {
        self.side = side
        self.height = height
        self.key = key
        let outline = PlotOutline.of(plotSide: plotSide)
        let thickness = GardenStructures.thickness
        let nominal = LongWalk.hedgeFrom + thickness / 2
        let half = plotSide / 2

        // Its length: as far each way as its inner foot has ground under it,
        // five centimetres on, the shorter of the two, so each rounded end
        // comes round on the clod rather than out over the corner. The same
        // length both ways, centred on the plot's middle.
        func reach(_ direction: Double) -> Double {
            var z = half
            while z > 0.3 {
                let x = Double(side) * (nominal - thickness / 2)
                if outline.contains(x: x, z: direction * (z + 0.05)) { return z }
                z -= 0.02
            }
            return 0.3
        }
        let length = 2 * min(reach(1), reach(-1))

        let mesh = Organic.hedge(length: length, height: height, thickness: thickness,
                                 seed: PlotOutline.hedgeSeed(side: side))
        let stride = Self.around + 1
        rings = mesh.positions.count / stride - 1

        var positions = mesh.positions
        var centres: [Spot] = []
        var grounds: [Double] = []
        for r in 0...rings {
            let z = Double(mesh.positions[r * stride].z)
            let x = Double(side) * nominal
            let under = ground(x, z)
            centres.append(Spot(x: x, z: z))
            grounds.append(under)
            for a in 0..<stride {
                let n = r * stride + a
                positions[n].x += Float(x)
                positions[n].y += Float(under)
            }
        }
        self.positions = positions

        // Normals worked out here, on the hedge as it stands, and turned
        // outward whichever way the triangles are wound: the top of the middle
        // ring has to face the sky.
        var normals = Self.normals(positions, mesh.indices)
        let top = (rings / 2) * stride + Self.around / 2
        flipped = normals[top].y < 0
        if flipped { normals = normals.map { -$0 } }
        let first = Array(mesh.indices.prefix(6))
        quad = flipped ? [first[0], first[2], first[1], first[3], first[5], first[4]] : first
        self.normals = normals

        feet = (0...rings).map { r in
            let a = positions[r * stride], b = positions[r * stride + Self.around]
            let ring = positions[(r * stride)..<(r * stride + stride)]
            let highest = Double(ring.map(\.y).max() ?? 0)
            let (outer, inner) = Double(a.x) * Double(side) > Double(b.x) * Double(side) ? (a, b) : (b, a)
            return (Spot(x: Double(outer.x), z: Double(outer.z)),
                    Spot(x: Double(inner.x), z: Double(inner.z)),
                    max(0, highest - grounds[r]))
        }

        let pieceCount = max(1, Int((length / GardenStructures.pieceLength).rounded()))
        let rings = self.rings
        pieces = (0..<pieceCount).map { p in
            let from = p * rings / pieceCount, to = (p + 1) * rings / pieceCount
            let middle = (from + to) / 2
            return Piece(index: p, rings: max(0, from - 1)...min(rings, to + 1),
                         spot: centres[middle], ground: grounds[middle])
        }
    }

    /// A piece as SceneKit geometry, standing on its own foot: the plot's
    /// coordinates less the piece's spot and ground.
    func geometry(piece: Piece) -> SCNGeometry {
        let stride = Self.around + 1
        let first = piece.rings.lowerBound * stride
        let last = (piece.rings.upperBound + 1) * stride
        let origin = SIMD3<Float>(Float(piece.spot.x), Float(piece.ground), Float(piece.spot.z))
        let local = positions[first..<last].map { p -> SCNVector3 in
            let q = p - origin
            return SCNVector3(q.x, q.y, q.z)
        }
        let turned = normals[first..<last].map { SCNVector3($0.x, $0.y, $0.z) }

        // The leaf grain runs on in metres along the hedge and round it, so it
        // carries across a joint, at the density the boxes had it.
        let section = Float(2 * height + GardenStructures.thickness)
        var grain: [CGPoint] = []
        for n in first..<last {
            let a = n % stride
            grain.append(CGPoint(x: CGFloat(positions[n].z / 0.4),
                                 y: CGFloat(Float(a) / Float(Self.around) * section / 0.4)))
        }

        var indices: [UInt32] = []
        let spans = piece.rings.count - 1
        for r in 0..<spans {
            for a in 0..<Self.around {
                let offset = UInt32(r * stride + a)
                indices += quad.map { $0 + offset }
            }
        }
        return SCNGeometry(
            sources: [SCNGeometrySource(vertices: local), SCNGeometrySource(normals: turned),
                      SCNGeometrySource(textureCoordinates: grain)],
            elements: [SCNGeometryElement(indices: indices, primitiveType: .triangles)]
        )
    }

    /// Smooth normals, each the sum of the faces round the vertex.
    private static func normals(_ positions: [SIMD3<Float>], _ indices: [UInt32]) -> [SIMD3<Float>] {
        var sums = [SIMD3<Float>](repeating: .zero, count: positions.count)
        var t = 0
        while t + 2 < indices.count {
            let a = Int(indices[t]), b = Int(indices[t + 1]), c = Int(indices[t + 2])
            let n = simd_cross(positions[b] - positions[a], positions[c] - positions[a])
            sums[a] += n; sums[b] += n; sums[c] += n
            t += 3
        }
        return sums.map { simd_length($0) > 0 ? simd_normalize($0) : SIMD3(0, 1, 0) }
    }
}

// MARK: - Drawing them

/// One piece of hedge standing on the plot, crossfaded round the clock the way
/// a plant is. Its shadow is `HedgeShadow`'s, for the whole hedge at once.
struct HedgePiece: View {
    let line: HedgeLine
    let index: Int
    let pointsPerMetre: Double
    let hour: Double
    let turn: Int

    @State private var before: UIImage?
    @State private var after: UIImage?

    private var between: (before: Int, after: Int, blend: Double) {
        GardenGround.Light.steps(at: hour)
    }

    var body: some View {
        let figure = GardenStructures.figure(height: line.height)
        let side = figure.metres * pointsPerMetre

        ZStack {
            if let before { Image(uiImage: before).resizable() }
            if let after { Image(uiImage: after).resizable().opacity(between.blend) }
        }
        .frame(width: side, height: side)
        .offset(y: figure.lift * side)
        .task(id: GardenStructures.key(line: line, piece: index, step: between.before, turn: turn)) {
            before = GardenStructures.shared.hedge(line, piece: index, step: between.before, turn: turn)
        }
        .task(id: GardenStructures.key(line: line, piece: index, step: between.after, turn: turn)) {
            after = GardenStructures.shared.hedge(line, piece: index, step: between.after, turn: turn)
        }
    }
}

/// The shadow something casts, sheared about its foot.
///
/// The shear is `GardenPlantSprite`'s, with the foot line moved up to where the
/// foot is in a picture that reaches below it. What lies nearer than the foot
/// shears the wrong way by a little, which on something lying on the ground is
/// under it anyway. Shared by the figures and the hedges: by day a thing with no
/// shadow stood on the grass like a sticker, beside plants that each had theirs.
struct FootShadow: View {
    let image: UIImage
    let side: Double
    let lift: Double
    let hour: Double
    let turn: Int

    var body: some View {
        let light = GardenGround.Light.at(hour: hour)
        let seen = light.turned(quarters: turn).direction
        let rise = max(0.12, seen.y)
        let across = -(seen.x - seen.z) * Isometric.cosThirty / rise
        let down = -(seen.x + seen.z) * Isometric.sinThirty / rise
        let foot = side * (1 - lift)

        Image(uiImage: image)
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(.black)
            .blur(radius: 0.30 + 0.34 * (1 - light.up))
            .opacity(max(0.10, 0.42 * light.strength / 0.76))
            .transformEffect(CGAffineTransform(
                a: 1, b: 0,
                c: -across, d: -down,
                tx: across * foot, ty: foot * (1 + down)
            ))
    }
}

/// The Long Walk's mown path, in stripes the way a mower leaves a lawn: each
/// pass lays the grass one way and the next lays it back, so the light catches
/// alternate bands. **Along the path, not across it**: a mower goes up and down
/// a path's length, and stripes across it read as paving slabs.
///
/// **Cut by eye.** Its verges wander a hand's width either way over a few paces
/// (`Organic.verge`), the lines between the passes wander a third as much, and
/// it runs out where the ground does, so its ends are the plot's own edge.
struct MownPath: View {
    let view: Isometric
    let light: GardenGround.Light
    let plotSide: Double
    let height: (Spot) -> Double

    /// Lighter and flatter than the turf beside it: mown short, and walked.
    static let grass = SIMD3<Double>(0.285, 0.320, 0.225)

    /// Where the line between two passes stands at `z`, for boundary `0...bands`
    /// counted from the `-x` verge. The seeds are `PlotOutline`'s.
    static func boundary(_ n: Int, of bands: Int, at z: Double) -> Double {
        let width = LongWalk.pathHalfWidth
        let straight = -width + Double(n) * 2 * width / Double(bands)
        if n == 0 { return straight - Organic.verge(z, side: -1, seed: PlotOutline.pathSeed) }
        if n == bands { return straight + Organic.verge(z, side: 1, seed: PlotOutline.pathSeed) }
        return straight + 0.03 * Organic.wobble(z, wavelength: 1.3,
                                                seed: mix64(PlotOutline.pathSeed &+ UInt64(n)))
    }

    var body: some View {
        Canvas { context, _ in
            let half = plotSide / 2
            let bands = 3
            // Walked down its length in five-centimetre steps, so the verges
            // wander at the scale they were cut at and the path follows the
            // ground's rises instead of cutting straight through them.
            let steps = max(26, Int((plotSide / 0.05).rounded()))
            context.clip(to: PlotOutline.of(plotSide: plotSide).path(in: view, height: height))
            for band in 0..<bands {
                var edge: [Spot] = []
                for step in 0...steps {
                    let z = -half + Double(step) / Double(steps) * plotSide
                    edge.append(Spot(x: Self.boundary(band, of: bands, at: z), z: z))
                }
                for step in (0...steps).reversed() {
                    let z = -half + Double(step) / Double(steps) * plotSide
                    edge.append(Spot(x: Self.boundary(band + 1, of: bands, at: z), z: z))
                }
                var path = Path()
                for (n, corner) in edge.enumerated() {
                    let point = view.point(corner, y: height(corner) + 0.005)
                    if n == 0 { path.move(to: point) } else { path.addLine(to: point) }
                }
                path.closeSubpath()
                let base = Self.grass * (band % 2 == 0 ? 1.07 : 0.95)
                let lit = GardenGround.shaded(base: base, normal: SIMD3(0, 1, 0), light: light)
                context.fill(path, with: .color(Color(red: lit.x, green: lit.y, blue: lit.z)))
            }
        }
        .allowsHitTesting(false)
    }
}

/// The shadow a whole hedge casts, laid on the ground as one shape.
///
/// A hedge is a wall, and a wall's shadow is plain geometry: its footprint,
/// and the same footprint moved away from the light by its height over the
/// light's slope, and everything between. Sheared per piece like a plant's,
/// each of twenty-odd pieces cast its own line, and near noon — when a sheared
/// shadow has no height on screen — the garden was ruled with hairlines.
///
/// **From the hedge's own feet**, ring by ring: each short stretch of hedge
/// casts the hull of its two rings' feet and those feet moved away by the
/// height of its top there, so the shadow's edges wander with the hedge's
/// footing and rise and fall with its top.
struct HedgeShadow: View {
    let view: Isometric
    let light: GardenGround.Light
    let plotSide: Double
    let hedges: [HedgeLine]
    let height: (Spot) -> Double

    var body: some View {
        Canvas { context, _ in
            let rise = max(0.12, light.direction.y)
            let outline = PlotOutline.of(plotSide: plotSide)
            var shadow = Path()
            for hedge in hedges {
                let feet = hedge.feet
                // Every other ring is plenty: six centimetres of hedge is a
                // point or two on screen.
                for r in Swift.stride(from: 0, to: feet.count - 1, by: 2) {
                    let next = min(feet.count - 1, r + 2)
                    var corners: [Spot] = []
                    for ring in [feet[r], feet[next]] {
                        let away = Spot(x: -light.direction.x / rise * ring.tall,
                                        z: -light.direction.z / rise * ring.tall)
                        for foot in [ring.outer, ring.inner] {
                            corners.append(foot)
                            corners.append(Spot(x: foot.x + away.x, z: foot.z + away.z))
                        }
                    }
                    let hull = Self.hull(corners)
                    guard hull.count > 2 else { continue }
                    var piece = Path()
                    for (n, corner) in hull.enumerated() {
                        // The ground's heights are clamped to the square, so
                        // a corner cast off the plot reads the rim's.
                        let point = view.point(corner, y: height(corner))
                        if n == 0 { piece.move(to: point) } else { piece.addLine(to: point) }
                    }
                    piece.closeSubpath()
                    shadow.addPath(piece)
                }
            }
            // Only on the plot: a shadow off the edge would fall on the sky.
            context.clip(to: outline.path(in: view, height: height))
            context.fill(shadow, with: .color(.black.opacity(max(0.10, 0.42 * light.strength / 0.76))))
        }
        .allowsHitTesting(false)
    }

    /// The convex hull of a handful of places, anticlockwise.
    static func hull(_ spots: [Spot]) -> [Spot] {
        let sorted = spots.sorted { $0.x == $1.x ? $0.z < $1.z : $0.x < $1.x }
        guard sorted.count > 2 else { return sorted }
        func turn(_ o: Spot, _ a: Spot, _ b: Spot) -> Double {
            (a.x - o.x) * (b.z - o.z) - (a.z - o.z) * (b.x - o.x)
        }
        var lower: [Spot] = [], upper: [Spot] = []
        for p in sorted {
            while lower.count >= 2, turn(lower[lower.count - 2], lower[lower.count - 1], p) <= 0 { lower.removeLast() }
            lower.append(p)
        }
        for p in sorted.reversed() {
            while upper.count >= 2, turn(upper[upper.count - 2], upper[upper.count - 1], p) <= 0 { upper.removeLast() }
            upper.append(p)
        }
        return Array(lower.dropLast() + upper.dropLast())
    }
}
