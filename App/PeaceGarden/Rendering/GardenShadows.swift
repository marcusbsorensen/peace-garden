import CoreGraphics
import Foundation
import SceneKit
import SeedCore
import simd
import SwiftUI

/// Shadows on the plot, worked out from the shapes that cast them: every plant
/// and every figure standing on the ground, in the sun or under the moon.
///
/// **The website's way, and for the website's reason.** `Server/assets/js/
/// shadow.js` and `docs/WEB-GARDENS.md` §*Shadows: under every plant* record a
/// first pass of ovals that Marcus saw through at once: a spindly plant with a
/// few wide branches got a broad pool it had nothing to cast, and a dense
/// rosette a small one. The app's first shadow was its own sprite blackened and
/// sheared, which kept the shape but read every pixel as standing straight up
/// from the foot — a leaf held out to the side cast as though it were stem,
/// nothing was clipped to the plot, and a long evening shadow ran off over the
/// sky. So here, as on the web, a shadow is **where the thing is, seen from the
/// light**: what it puts between the light and the ground, slid down along the
/// light onto the ground and counted in layers.
///
/// **From the geometry, not from the picture.** The sprites are already taken
/// when a shadow is wanted, and a silhouette is the obvious thing to reuse —
/// but a picture has lost the one fact a shadow needs, which is how high each
/// part of it is. A leaf at the top of a stem and a leaf at its foot are the
/// same pixel apart in the sprite whatever the sun is doing, and a metre apart
/// in the shadow at five in the afternoon. The triangles still know. So the
/// meshes that are rendered into the sprites — a plant's `PlantMesh`, a
/// figure's SceneKit nodes — are each boiled down once to a **caster**: a cloud
/// of centimetre pieces saying where surface is and which way it faces. One
/// implementation then serves both: plants and figures alike are a caster, a
/// turn and a size.
///
/// **Kept per step, like the sprites, but at forty-eight steps a day rather
/// than eight.** The sun's bearing moves forty-five degrees between two sprite
/// steps, and two shadows forty-five degrees apart crossfaded is two shadows.
/// Half an hour apart they cross-fade as one that turns. A shadow costs a
/// few milliseconds from its caster, off the main thread, so the finer steps
/// cost little; it is the caster, made once per plant, that holds the work.
final class GardenShadows: @unchecked Sendable {
    static let shared = GardenShadows()

    private let lock = NSLock()
    /// Held by what they weigh: a plant's caster is a few thousand pieces and
    /// a sheet a few tens of kilobytes, and a plot of forty things at two
    /// steps each, with a turn's worth besides, fits in these.
    private var casters = Store<CasterKey, ShadowCaster>(limit: 12 << 20)
    private var sheets = Store<SheetKey, ShadowSheet?>(limit: 16 << 20)
    private var building: [CasterKey: Task<ShadowCaster, Never>] = [:]
    /// The figures' casters, never let go: there are six, a few hundred
    /// kilobytes between them, and they are modelled on the main actor, where
    /// making one again after the store had let it go was a visible pause.
    private var figures: [CasterKey: ShadowCaster] = [:]

    private init() {}

    // MARK: Round the clock in forty-eight

    /// Points round the clock a shadow is worked out at.
    static let steps = 48

    static func light(step: Int) -> GardenGround.Light {
        GardenGround.Light.at(hour: Double((step % steps + steps) % steps) / Double(steps) * 24)
    }

    /// The two steps an hour falls between, and how far between them it is.
    static func steps(at hour: Double) -> (before: Int, after: Int, blend: Double) {
        let clock = ((hour.truncatingRemainder(dividingBy: 24)) + 24).truncatingRemainder(dividingBy: 24)
        let raw = clock / 24 * Double(steps)
        let before = Int(raw.rounded(.down)) % steps
        return (before, (before + 1) % steps, raw - raw.rounded(.down))
    }

    /// How much of a shadow there is at all, by how high its light is.
    ///
    /// **Nothing at the moment the sun hands over to the moon.** They hand over
    /// on opposite horizons — the sun sets at one corner as the moon rises at
    /// the opposite one — so a shadow that kept any strength through the
    /// handover would swing straight round. Both are on the horizon there, and
    /// a body on the horizon lights the ground edge-on, so a shadow fades out
    /// as its light goes down and the next one fades in as its light comes up.
    static func presence(of light: GardenGround.Light) -> Double {
        smooth(0.02, 0.3, light.up)
    }

    /// How dark full shade is on ground facing `normal`, as what the ground's
    /// light is multiplied by: **the same arithmetic the ground is lit with**,
    /// asked twice, once in the open and once with the direct light taken away.
    ///
    /// So a shadow on the plot is the shade the ground's own hills cast, not a
    /// grey laid over it: by day the sky still lights it and it goes cool, under
    /// the moon there is far less direct light to take and it is faint, and on
    /// a slope turned from the light there is nothing to take at all.
    ///
    /// **More than half again a hill's shade.** Under a plant the sky is partly
    /// shut out as well as the sun — a hill's shade is open to the whole sky,
    /// a pool under a leafy plant is not — and at the ground's own depth of
    /// shade the shadows were there and could not be seen: by day the sky
    /// lights this ground nearly as much as the sun does.
    ///
    /// The moon's is cooler again. Its light and the sky's are both blue at
    /// night, so the arithmetic alone takes them in near enough equal parts and
    /// the shade came out grey; a moonlit shadow reads as night by keeping more
    /// of the blue than of the red.
    static func fullShade(under light: GardenGround.Light,
                          normal: SIMD3<Double> = SIMD3(0, 1, 0)) -> SIMD3<Double> {
        let grey = SIMD3<Double>(repeating: 0.5)
        let open = GardenGround.shaded(base: grey, normal: normal, shadow: 1, light: light)
        let shut = GardenGround.shaded(base: grey, normal: normal, shadow: 0, light: light)
        var kept = SIMD3<Double>(repeating: 1)
        for channel in 0..<3 where open[channel] > 0.001 {
            kept[channel] = min(1, shut[channel] / open[channel])
        }
        let one = SIMD3<Double>(repeating: 1)
        var taken = (one - kept) * underCover
        if light.isDay {
            // A low sun still throws a shadow that can be seen. The ground
            // takes most of its light from the sky by then, and the arithmetic
            // alone left a five o'clock shadow as a smudge.
            taken = simd_max(taken, one * 0.5)
        } else {
            taken *= SIMD3(1.12, 1.0, 0.72)
        }
        return one - simd_min(one * 0.8, taken)
    }

    /// How much more a shadow takes than the open shade of a hill.
    static let underCover = 1.6

    // MARK: Kept

    func caster(_ key: CasterKey) -> ShadowCaster? {
        lock.withLock { figures[key] ?? casters.get(key) }
    }

    /// A sheet if it has been worked out: `.some(nil)` when it has, and there
    /// was nothing to cast — the light too low, or the thing too small.
    func sheet(_ key: SheetKey) -> ShadowSheet?? {
        lock.withLock { sheets.get(key) }
    }

    /// A caster, made once however many ask for it at the same time: the plot
    /// asks for a plant's while the sprite is still being taken from the same
    /// mesh, and the sprite hands its mesh over rather than have it built twice.
    func caster(_ key: CasterKey, build: @escaping @Sendable () -> ShadowCaster) async -> ShadowCaster {
        if let held = caster(key) { return held }
        let task: Task<ShadowCaster, Never> = lock.withLock {
            if let running = building[key] { return running }
            let running = Task.detached(priority: .userInitiated) { build() }
            building[key] = running
            return running
        }
        let made = await task.value
        lock.withLock {
            casters.set(key, made, cost: made.points.count * 24)
            building[key] = nil
        }
        return made
    }

    /// Hands a plant's mesh over while it is at hand, so its caster is made
    /// without building the plant a second time.
    func keep(_ mesh: PlantMesh, as key: CasterKey) {
        guard caster(key) == nil else { return }
        Task { _ = await caster(key) { ShadowCaster(mesh: mesh) } }
    }

    func keep(figure caster: ShadowCaster, as key: CasterKey) {
        lock.withLock { figures[key] = caster }
    }

    func keep(_ sheet: ShadowSheet?, as key: SheetKey) {
        let weight = sheet.map { $0.image.width * $0.image.height * 4 } ?? 64
        lock.withLock { sheets.set(key, sheet, cost: weight) }
    }

    // MARK: Keys

    /// Which caster: a plant's by its seed and how grown it is, bucketed as
    /// its sprite is, or a figure's by its kind. Values rather than strings,
    /// because they are asked for every frame the plot is drawn.
    struct CasterKey: Hashable, Sendable {
        let seed: SeedID?
        let bucket: Int
        let figure: LampKind?

        static func plant(_ seed: SeedID, growth: GrowthModel.State) -> CasterKey {
            CasterKey(seed: seed, bucket: Int(growth.overall * 24) * 10 + Int(growth.bloomOpen * 6),
                      figure: nil)
        }

        static func figure(_ kind: LampKind) -> CasterKey {
            CasterKey(seed: nil, bucket: 0, figure: kind)
        }
    }

    /// Which sheet: a caster, the turn and size it stands at, and the step.
    struct SheetKey: Hashable, Sendable {
        let caster: CasterKey
        let turn: Int
        let scale: Int
        let step: Int
    }

    static func smooth(_ a: Double, _ b: Double, _ v: Double) -> Double {
        let t = min(1, max(0, (v - a) / (b - a)))
        return t * t * (3 - 2 * t)
    }
}

/// What is kept, by what it weighs, letting go of what was looked at longest
/// ago when it is over its limit. Not thread-safe; `GardenShadows` holds its
/// lock round it.
private struct Store<Key: Hashable, Value> {
    let limit: Int
    private var items: [Key: (value: Value, cost: Int, used: UInt64)] = [:]
    private var total = 0
    private var clock: UInt64 = 0

    init(limit: Int) { self.limit = limit }

    mutating func get(_ key: Key) -> Value? {
        guard var item = items[key] else { return nil }
        clock += 1
        item.used = clock
        items[key] = item
        return item.value
    }

    mutating func set(_ key: Key, _ value: Value, cost: Int) {
        clock += 1
        if let old = items[key] { total -= old.cost }
        items[key] = (value, cost, clock)
        total += cost
        guard total > limit else { return }
        // Down to three quarters, oldest first, so this is not done again on
        // the very next arrival.
        for (key, item) in items.sorted(by: { $0.value.used < $1.value.used }) {
            guard total > limit * 3 / 4 else { break }
            items[key] = nil
            total -= item.cost
        }
    }
}

// MARK: - The caster

/// What a thing puts between a light and the ground, from any direction: its
/// surface, boiled down to centimetre pieces.
///
/// **Each piece keeps how much of its surface faces along each axis**, rather
/// than one area or one normal. One area would cast a leaf held flat as much
/// under a low sun as under a high one; one normal, summed over a piece, has
/// the two sides of a stem cancel to nothing — a stem is a tube, and in a
/// centimetre its far wall faces exactly away from its near one. What faces
/// each axis, added up without sign, cannot cancel, and the area a piece shows
/// a light from any direction is near enough the light's own components
/// weighed against it. A closed body is counted front and back, as two layers,
/// which is what the web counts too.
struct ShadowCaster: Sendable {
    /// Where each piece is, in metres from the thing's foot, in its own axes.
    var points: [SIMD3<Float>] = []
    /// How much of each piece's surface faces along `x`, `y` and `z`, in
    /// square metres.
    var faces: [SIMD3<Float>] = []

    /// How large a piece is, in metres.
    static let piece: Float = 0.01

    var isEmpty: Bool { points.isEmpty }

    init(points: [SIMD3<Float>], faces: [SIMD3<Float>]) {
        self.points = points
        self.faces = faces
    }

    /// A plant, from the mesh its sprite is rendered from.
    init(mesh: PlantMesh) {
        var pieces = Pieces()
        for part in mesh.parts {
            let p = part.positions, index = part.indices
            var n = 0
            while n + 2 < index.count {
                let a = Int(index[n]), b = Int(index[n + 1]), c = Int(index[n + 2])
                if a < p.count, b < p.count, c < p.count { pieces.add(p[a], p[b], p[c]) }
                n += 3
            }
        }
        self = pieces.caster()
    }

    /// A figure, from the SceneKit nodes it is modelled in, in the root's own
    /// axes.
    init(node root: SCNNode) {
        var pieces = Pieces()
        func walk(_ node: SCNNode, _ parent: simd_float4x4) {
            let transform = node === root ? parent : parent * node.simdTransform
            if let geometry = node.geometry, !node.isHidden {
                Self.triangles(of: geometry, transform: transform) { pieces.add($0, $1, $2) }
            }
            for child in node.childNodes { walk(child, transform) }
        }
        walk(root, matrix_identity_float4x4)
        self = pieces.caster()
    }

    /// Every triangle of a SceneKit geometry, read back out of its buffers.
    ///
    /// **A primitive's buffers are not the primitive.** A sphere hands back a
    /// sphere half a unit across and a cylinder one a unit tall, whatever
    /// radius and height they were made with, and SceneKit scales them on the
    /// way to the screen; read as they stand, the moth's stake cast a shadow a
    /// metre across. So what is read is fitted to the box the geometry says it
    /// fills, axis by axis — which leaves a mesh built from its own vertices,
    /// whose buffer is its box, exactly as it was.
    private static func triangles(of geometry: SCNGeometry, transform: simd_float4x4,
                                  _ visit: (SIMD3<Float>, SIMD3<Float>, SIMD3<Float>) -> Void) {
        guard let source = geometry.sources(for: .vertex).first, source.usesFloatComponents,
              source.componentsPerVector >= 3, source.vectorCount > 0 else {
            // An extruded path has no buffers until it is first drawn, so it
            // is laid from its path instead.
            if let shape = geometry as? SCNShape { extruded(shape, transform: transform, visit) }
            return
        }
        let count = source.vectorCount, stride = source.dataStride, offset = source.dataOffset
        let wide = source.bytesPerComponent == 8
        var read = [SIMD3<Float>]()
        read.reserveCapacity(count)
        source.data.withUnsafeBytes { raw in
            for i in 0..<count {
                let at = offset + i * stride
                guard at + 3 * source.bytesPerComponent <= raw.count else { break }
                if wide {
                    read.append(SIMD3(Float(raw.loadUnaligned(fromByteOffset: at, as: Double.self)),
                                      Float(raw.loadUnaligned(fromByteOffset: at + 8, as: Double.self)),
                                      Float(raw.loadUnaligned(fromByteOffset: at + 16, as: Double.self))))
                } else {
                    read.append(SIMD3(raw.loadUnaligned(fromByteOffset: at, as: Float.self),
                                      raw.loadUnaligned(fromByteOffset: at + 4, as: Float.self),
                                      raw.loadUnaligned(fromByteOffset: at + 8, as: Float.self)))
                }
            }
        }
        guard let first = read.first else { return }
        var low = first, high = first
        for p in read { low = simd_min(low, p); high = simd_max(high, p) }
        let (boxLow, boxHigh) = geometry.boundingBox
        let wantLow = SIMD3<Float>(boxLow.x, boxLow.y, boxLow.z)
        let wantHigh = SIMD3<Float>(boxHigh.x, boxHigh.y, boxHigh.z)
        var fit = SIMD3<Float>(repeating: 1), shift = SIMD3<Float>(repeating: 0)
        for axis in 0..<3 where high[axis] - low[axis] > 1e-7 && wantHigh[axis] >= wantLow[axis] {
            fit[axis] = (wantHigh[axis] - wantLow[axis]) / (high[axis] - low[axis])
            shift[axis] = wantLow[axis] - low[axis] * fit[axis]
        }
        let positions = read.map { p -> SIMD3<Float> in
            let moved = transform * SIMD4(p * fit + shift, 1)
            return SIMD3(moved.x, moved.y, moved.z)
        }
        func at(_ i: Int) -> SIMD3<Float>? { i >= 0 && i < positions.count ? positions[i] : nil }

        for element in geometry.elements {
            let width = element.bytesPerIndex
            let primitives = element.primitiveCount
            element.data.withUnsafeBytes { raw in
                let total = raw.count / max(1, width)
                func index(_ k: Int) -> Int {
                    guard k < total else { return -1 }
                    switch width {
                    case 1: return Int(raw[k])
                    case 2: return Int(raw.loadUnaligned(fromByteOffset: k * 2, as: UInt16.self))
                    default: return Int(raw.loadUnaligned(fromByteOffset: k * 4, as: UInt32.self))
                    }
                }
                func triangle(_ a: Int, _ b: Int, _ c: Int) {
                    if let pa = at(a), let pb = at(b), let pc = at(c) { visit(pa, pb, pc) }
                }
                switch element.primitiveType {
                case .triangles:
                    for t in 0..<primitives { triangle(index(3 * t), index(3 * t + 1), index(3 * t + 2)) }
                case .triangleStrip:
                    for t in 0..<primitives { triangle(index(t), index(t + 1), index(t + 2)) }
                case .polygon:
                    // The corner counts come first, one per polygon, then the
                    // corners themselves; each polygon is laid as a fan.
                    var next = primitives
                    for polygon in 0..<primitives {
                        let corners = index(polygon)
                        guard corners >= 3 else { next += max(0, corners); continue }
                        for k in 1..<(corners - 1) {
                            triangle(index(next), index(next + k), index(next + k + 1))
                        }
                        next += corners
                    }
                default:
                    break
                }
            }
        }
    }

    /// An extruded path — a moth's wing — laid as its two faces: the path's
    /// inside, sampled every few millimetres, at the front and the back of the
    /// extrusion. Its thin sides throw nothing worth counting.
    private static func extruded(_ shape: SCNShape, transform: simd_float4x4,
                                 _ visit: (SIMD3<Float>, SIMD3<Float>, SIMD3<Float>) -> Void) {
        guard let path = shape.path?.cgPath else { return }
        var outline: [CGPoint] = []
        var last = CGPoint.zero
        path.applyWithBlock { element in
            let e = element.pointee
            switch e.type {
            case .moveToPoint, .addLineToPoint:
                last = e.points[0]
                outline.append(last)
            case .addQuadCurveToPoint:
                let (c, end) = (e.points[0], e.points[1])
                for k in 1...10 {
                    let t = CGFloat(k) / 10, u = 1 - t
                    outline.append(CGPoint(x: u * u * last.x + 2 * u * t * c.x + t * t * end.x,
                                           y: u * u * last.y + 2 * u * t * c.y + t * t * end.y))
                }
                last = end
            case .addCurveToPoint:
                let (c1, c2, end) = (e.points[0], e.points[1], e.points[2])
                for k in 1...12 {
                    let t = CGFloat(k) / 12, u = 1 - t
                    let a = u * u * u, b = 3 * u * u * t, c = 3 * u * t * t, d = t * t * t
                    outline.append(CGPoint(x: a * last.x + b * c1.x + c * c2.x + d * end.x,
                                           y: a * last.y + b * c1.y + c * c2.y + d * end.y))
                }
                last = end
            case .closeSubpath:
                break
            @unknown default:
                break
            }
        }
        guard outline.count > 2 else { return }
        let box = path.boundingBoxOfPath
        let spacing = max(0.002, Double(min(box.width, box.height)) / 40)
        let half = Float(shape.extrusionDepth / 2)
        func inside(_ x: Double, _ y: Double) -> Bool {
            var crossings = false
            var j = outline.count - 1
            for i in 0..<outline.count {
                let a = outline[i], b = outline[j]
                if (a.y > y) != (b.y > y), x < (b.x - a.x) * (y - a.y) / (b.y - a.y) + a.x { crossings.toggle() }
                j = i
            }
            return crossings
        }
        func point(_ x: Double, _ y: Double, _ z: Float) -> SIMD3<Float> {
            let moved = transform * SIMD4(Float(x), Float(y), z, 1)
            return SIMD3(moved.x, moved.y, moved.z)
        }
        var y = Double(box.minY) + spacing / 2
        while y < Double(box.maxY) {
            var x = Double(box.minX) + spacing / 2
            while x < Double(box.maxX) {
                if inside(x, y) {
                    let s = spacing / 2
                    for z in [-half, half] {
                        let a = point(x - s, y - s, z), b = point(x + s, y - s, z)
                        let c = point(x + s, y + s, z), d = point(x - s, y + s, z)
                        visit(a, b, c)
                        visit(a, c, d)
                    }
                }
                x += spacing
            }
            y += spacing
        }
    }

    /// The pieces being gathered: every triangle cut down to centimetres and
    /// dropped into the piece it falls in.
    private struct Pieces {
        private var index: [Int64: Int] = [:]
        private var weighted: [SIMD3<Float>] = []
        private var areas: [Float] = []
        private var faces: [SIMD3<Float>] = []

        mutating func add(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ c: SIMD3<Float>) {
            let cross = simd_cross(b - a, c - a)
            let twice = simd_length(cross)
            guard twice > 1e-12, twice.isFinite else { return }
            let area = twice / 2
            let facing = simd_abs(cross) / twice * area
            let longest = max(simd_distance(a, b), simd_distance(b, c), simd_distance(c, a))
            let cuts = min(200, max(1, Int((longest / ShadowCaster.piece).rounded(.up))))
            guard cuts > 1 else {
                put((a + b + c) / 3, area, facing)
                return
            }
            // Cut into `cuts²` like triangles, each laid at its own middle, so
            // a long blade's area lies along it rather than at its centre.
            let share = 1 / Float(cuts * cuts)
            let u = (b - a) / Float(cuts), v = (c - a) / Float(cuts)
            for i in 0..<cuts {
                for j in 0..<(cuts - i) {
                    put(a + u * (Float(i) + 1.0 / 3) + v * (Float(j) + 1.0 / 3), area * share, facing * share)
                    if i + j < cuts - 1 {
                        put(a + u * (Float(i) + 2.0 / 3) + v * (Float(j) + 2.0 / 3), area * share, facing * share)
                    }
                }
            }
        }

        private mutating func put(_ p: SIMD3<Float>, _ area: Float, _ facing: SIMD3<Float>) {
            let cell = (p / ShadowCaster.piece).rounded(.down)
            guard cell.x.isFinite, cell.y.isFinite, cell.z.isFinite else { return }
            let key = (Int64(cell.x) + (1 << 20)) << 42 | (Int64(cell.y) + (1 << 20)) << 21
                | (Int64(cell.z) + (1 << 20))
            if let at = index[key] {
                weighted[at] += p * area
                areas[at] += area
                faces[at] += facing
            } else {
                index[key] = weighted.count
                weighted.append(p * area)
                areas.append(area)
                faces.append(facing)
            }
        }

        func caster() -> ShadowCaster {
            var points = [SIMD3<Float>]()
            points.reserveCapacity(weighted.count)
            for n in 0..<weighted.count { points.append(weighted[n] / max(areas[n], 1e-12)) }
            return ShadowCaster(points: points, faces: faces)
        }
    }
}

// MARK: - The shadow

/// How a shadow is worked out: the website's numbers, kept together, and
/// changed only where the app's ground asked for it.
struct ShadowLook: Sendable {
    /// The grid's cell, in metres, at least; a long shadow gets coarser cells
    /// rather than more of them, up to `most` a side.
    var cell = 0.015
    var most = 120
    /// How far what is low and what is high are blurred, in metres. Near the
    /// ground a shadow is sharp — a contact shadow, which is what the eye reads
    /// as standing on the ground — and higher up it softens.
    var near = 0.018
    var far = 0.07
    /// How far out — its height, or under a low sun how far along the ground
    /// it lands — a part has gone over to the soft layer, and how much it
    /// counts there beside a low one.
    var high = 0.40
    var faint = 0.55
    /// And a third layer, for what lands a long way out under a low sun: by
    /// `further` along the ground a part is blurred `farthest` and counts
    /// `fainter`. Two layers left the tip of a metre-long evening shadow as
    /// sharp as its middle; a real one's edge softens all the way out.
    var farthest = 0.12
    var further = 1.4
    var fainter = 0.6
    /// How quickly layers darken towards `darkest`, which a pile of leaves
    /// approaches and does not pass: ten leaves are not ten times one.
    ///
    /// **Not the web's `0.42 × (1 − e^(−1.1 × layers))`.** There the 0.42 is
    /// the whole of how dark a shadow gets; here how dark full shade is comes
    /// from the light (`GardenShadows.fullShade`), and this says how much of
    /// it the layers reach. One leaf reaches most of it, because on this
    /// ground, which is darker than the web's and lit more by its sky, the
    /// web's single leaf could not be seen.
    var layers = 1.8
    var darkest = 0.95
    /// How much the slide of anything above the ground wanders by where it
    /// is, as a share, and over how long a wave. A stake's shadow is otherwise
    /// a ruled line, and nothing in the garden is.
    var wander = 0.06
    var wave = 1.0
    /// How much of the shade light through the leaves breaks up.
    var dapple = 0.0
    /// The lowest the light is taken to be, as the longest slide it gives: a
    /// metre up casts at most this many metres along the ground.
    var longest = 4.0

    static let plant = ShadowLook(wander: 0.05, dapple: 0.28)
    static let figure = ShadowLook(darkest: 0.92, wander: 0.08, wave: 3)
}

/// A shadow worked out: how much of the ground's light is taken, cell by cell,
/// as the alpha of a picture, with where the grid lies about the foot.
struct ShadowSheet: @unchecked Sendable {
    let image: CGImage
    /// The near corner of the first cell, in metres from the foot along the
    /// plot's own `x` and `z`.
    let x0: Double
    let z0: Double
    let cell: Double
    /// Which way the light the shadow was worked out for came from, in the
    /// plot's axes — after the lowest light was raised to `longest`. Laying it
    /// on a slope needs it.
    let light: SIMD3<Double>
}

extension ShadowCaster {

    /// The shadow this caster throws on level ground, turned `turn` radians
    /// about its foot and scaled by `scale`, from a light in `light` (towards
    /// the light, in the plot's own axes).
    ///
    /// The website's `castShadow`, worked from pieces instead of triangles:
    /// every piece is slid along the light onto the ground and laid into a grid
    /// with the area it shows the light — into a sharp layer if it lands near
    /// the foot, a soft one further out, and a softer one further still; the
    /// layers are blurred, counted into light lost,
    /// and faded to nothing at the grid's own border so the sheet it is drawn
    /// on never shows. A piece is a centimetre tall, and under a low sun a
    /// centimetre of stem lies along several centimetres of ground, so a piece
    /// is laid along its own slide rather than at one point of it — a stem's
    /// shadow at five o'clock is a line and not a row of dots.
    func cast(toward light: SIMD3<Double>, turn: Double, scale: Double, look: ShadowLook,
              salt: Double) -> ShadowSheet? {
        guard !points.isEmpty, light.y > 0.001 else { return nil }

        // The light, raised if it is lower than `longest` allows.
        var towards = simd_normalize(light)
        let level = (towards.x * towards.x + towards.z * towards.z).squareRoot()
        if level > towards.y * look.longest {
            let along = level > 1e-9 ? SIMD2(towards.x, towards.z) / level : SIMD2(0, 0)
            towards = simd_normalize(SIMD3(along.x * look.longest, 1, along.y * look.longest))
        }
        let slide = SIMD2(-towards.x / towards.y, -towards.z / towards.y)
        let slideLength = simd_length(slide)

        // The light in the caster's own axes, for how much of each piece it
        // sees; positions are turned into the plot's.
        let c = cos(turn), s = sin(turn)
        let own = SIMD3(towards.x * c - towards.z * s, towards.y, towards.x * s + towards.z * c)
        let seen = SIMD3(Float(abs(own.x)), Float(abs(own.y)), Float(abs(own.z)))
        let groundPerSeen = Float(scale * scale / towards.y)
        let piece = Double(ShadowCaster.piece) * scale

        func wander(_ x: Double, _ z: Double) -> Double {
            guard look.wander > 0 else { return 1 }
            let u = x * look.wave + salt, v = z * look.wave - salt
            return 1 + look.wander * (0.45 * sin(u * 4.1 + v * 2.3 + 1.7) + 0.3 * sin(u * -2.9 + v * 6.7 + 4.2)
                + 0.15 * sin(u * 11.3 + v * 9.1 + 0.3) + 0.2 * (Self.grain(u * 53.1 + v * 97.3) - 0.5))
        }

        // Where everything lands, and how much of it.
        let count = points.count
        var landed = [SIMD2<Double>](repeating: .zero, count: count)
        var heights = [Double](repeating: 0, count: count)
        var weights = [Double](repeating: 0, count: count)
        var x0 = 0.0, z0 = 0.0, x1 = 0.0, z1 = 0.0, reaching = 0.0
        for n in 0..<count {
            let p = points[n]
            let lx = Double(p.x) * scale, lz = Double(p.z) * scale
            let x = lx * c + lz * s, z = -lx * s + lz * c
            let y = max(0, Double(p.y) * scale)
            let reach = y * wander(lx, lz)
            let at = SIMD2(x + slide.x * reach, z + slide.y * reach)
            landed[n] = at
            heights[n] = y
            reaching = max(reaching, y * max(1, slideLength))
            weights[n] = Double(simd_dot(faces[n], seen) * groundPerSeen)
            x0 = min(x0, at.x); x1 = max(x1, at.x)
            z0 = min(z0, at.y); z1 = max(z1, at.y)
        }

        let far = look.far, near = look.near, farthest = look.farthest
        // Room round it for the widest blur anything in it gets.
        let room = 3 * (reaching > look.high * 1.5 ? max(far, farthest) : far) + 4 * look.cell
        x0 -= room; z0 -= room; x1 += room; z1 += room
        let cell = max(look.cell, max(x1 - x0, z1 - z0) / Double(look.most))
        let w = max(4, Int(((x1 - x0) / cell).rounded(.up)))
        let h = max(4, Int(((z1 - z0) / cell).rounded(.up)))
        var sharp = [Float](repeating: 0, count: w * h)
        var soft = [Float](repeating: 0, count: w * h)
        var softest = [Float](repeating: 0, count: w * h)
        let perCell = 1 / (cell * cell)

        // How many points a piece is laid at along its own slide.
        let spread = piece * slideLength
        let parts = max(1, min(12, Int((spread / cell).rounded(.up))))
        let dx = slide.x * piece, dz = slide.y * piece

        for n in 0..<count {
            let layers = weights[n] * perCell / Double(parts)
            guard layers > 0 else { continue }
            // Sharp near the foot and soft further out: by how far along the
            // ground a piece lands, which under a high sun is about its height
            // and under a low one several times it. A stem's shadow at five in
            // the afternoon is a metre long and blurs out along it, rather
            // than running across the plot as a ruled line.
            let out = heights[n] * max(1, slideLength)
            let t = GardenShadows.smooth(0, look.high, out)
            let u2 = GardenShadows.smooth(look.high * 1.5, look.further, out)
            let low = Float(layers * (1 - t)), high = Float(layers * t * (1 - u2) * look.faint)
            let highest = Float(layers * t * u2 * look.fainter)
            for k in 0..<parts {
                // Spread over the piece's own height, and not below the ground.
                let along = parts == 1 ? 0 : (Double(k) + 0.5) / Double(parts) - 0.5
                let lift = heights[n] + along * piece < 0 ? 0 : along
                let u = (landed[n].x + dx * lift - x0) / cell - 0.5
                let v = (landed[n].y + dz * lift - z0) / cell - 0.5
                let i = Int(u.rounded(.down)), j = Int(v.rounded(.down))
                let fu = Float(u - Double(i)), fv = Float(v - Double(j))
                guard i >= 0, j >= 0, i + 1 < w, j + 1 < h else { continue }
                let a = j * w + i
                let shares = ((1 - fu) * (1 - fv), fu * (1 - fv), (1 - fu) * fv, fu * fv)
                sharp[a] += low * shares.0; soft[a] += high * shares.0
                sharp[a + 1] += low * shares.1; soft[a + 1] += high * shares.1
                sharp[a + w] += low * shares.2; soft[a + w] += high * shares.2
                sharp[a + w + 1] += low * shares.3; soft[a + w + 1] += high * shares.3
                if highest > 0 {
                    softest[a] += highest * shares.0; softest[a + 1] += highest * shares.1
                    softest[a + w] += highest * shares.2; softest[a + w + 1] += highest * shares.3
                }
            }
        }

        Self.blur(&sharp, w, h, max(1, Int((near / cell).rounded())))
        Self.blur(&soft, w, h, max(1, Int((far / cell).rounded())))
        Self.blur(&softest, w, h, max(1, Int((farthest / cell).rounded())))

        // Layers to light lost, faded to nothing over the last cells.
        var bytes = [UInt8](repeating: 0, count: w * h * 4)
        let edge = 3.0
        var any = false
        for j in 0..<h {
            let fj = GardenShadows.smooth(0, edge, Double(min(j, h - 1 - j)))
            let z = z0 + (Double(j) + 0.5) * cell
            for i in 0..<w {
                let fade = fj * GardenShadows.smooth(0, edge, Double(min(i, w - 1 - i)))
                guard fade > 0 else { continue }
                let layers = Double(sharp[j * w + i] + soft[j * w + i] + softest[j * w + i])
                var lost = fade * look.darkest * (1 - exp(-look.layers * layers))
                if look.dapple > 0, lost > 0.004 {
                    let x = x0 + (Double(i) + 0.5) * cell
                    let a = x + salt, b = z - salt
                    let light = 0.6 * Self.noise(a * 4.3 + b * 2.1, b * 4.3 - a * 2.1)
                        + 0.4 * Self.noise(a * 9.7 - b * 5.3 + 31, b * 9.7 + a * 5.3 + 17)
                    lost *= 1 - look.dapple * GardenShadows.smooth(0.4, 0.75, light)
                }
                let value = UInt8(max(0, min(255, (lost * 255).rounded())))
                guard value > 0 else { continue }
                any = true
                let at = (j * w + i) * 4
                bytes[at] = value; bytes[at + 1] = value; bytes[at + 2] = value; bytes[at + 3] = value
            }
        }
        guard any, let image = Self.image(bytes, width: w, height: h) else { return nil }
        return ShadowSheet(image: image, x0: x0, z0: z0, cell: cell, light: towards)
    }

    /// Light lost as white at that much alpha, premultiplied, to be coloured
    /// where it is laid by the shade of the ground it falls on. A mask of
    /// alpha alone would be a quarter of the size, and is not drawn at all.
    private static func image(_ bytes: [UInt8], width: Int, height: Int) -> CGImage? {
        guard let provider = CGDataProvider(data: Data(bytes) as CFData) else { return nil }
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                       bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    }

    /// Three box blurs each way, which is near enough a Gaussian and costs the
    /// same whatever the radius. Nothing outside the grid is counted.
    private static func blur(_ grid: inout [Float], _ w: Int, _ h: Int, _ r: Int) {
        var line = [Float](repeating: 0, count: max(w, h))
        let scale = 1 / Float(2 * r + 1)
        for pass in 0..<2 {
            let count = pass == 0 ? h : w, length = pass == 0 ? w : h
            for k in 0..<count {
                func at(_ i: Int) -> Int { pass == 0 ? k * w + i : i * w + k }
                for _ in 0..<3 {
                    for i in 0..<length { line[i] = grid[at(i)] }
                    var sum: Float = 0
                    for i in 0..<min(r, length) { sum += line[i] }
                    for i in 0..<length {
                        if i + r < length { sum += line[i + r] }
                        if i - r - 1 >= 0 { sum -= line[i - r - 1] }
                        grid[at(i)] = sum * scale
                    }
                }
            }
        }
    }

    /// Smooth noise between 0 and 1: a lattice of random heights, eased
    /// between, turned and stretched where it is read so no row of it lines up
    /// with anything — a sum of waves drew a trellis in the shade on the web.
    private static func noise(_ x: Double, _ z: Double) -> Double {
        let i = x.rounded(.down), j = z.rounded(.down), fx = x - i, fz = z - j
        func at(_ a: Double, _ b: Double) -> Double { grain(a * 157.31 + b * 311.7) }
        let sx = fx * fx * (3 - 2 * fx), sz = fz * fz * (3 - 2 * fz)
        let top = at(i, j) + (at(i + 1, j) - at(i, j)) * sx
        let bottom = at(i, j + 1) + (at(i + 1, j + 1) - at(i, j + 1)) * sx
        return top + (bottom - top) * sz
    }

    private static func grain(_ n: Double) -> Double {
        let x = sin(n * 12.9898) * 43_758.5453
        return x - x.rounded(.down)
    }
}

// MARK: - Where a shadow may fall

extension GardenShadows {

    /// The plot's top surface as it lands on screen: the one place a shadow is
    /// allowed to be.
    ///
    /// **Not the rim's outline.** On a world with a hill the surface rises
    /// above the far rim on screen, and a shadow on the hill's far side would
    /// be cut off at a line the hill stands in front of. A heightmap seen from
    /// above at thirty-five degrees covers, in every column of the screen, one
    /// unbroken run from its highest point to its lowest — the near rim — so
    /// the surface is worked out column by column from the same warped grid
    /// the ground is drawn from. Below the near rim is the cut, and beyond the
    /// rest is sky; neither is in it.
    @MainActor
    static func surface(world: Int, plotSide: Double, view: Isometric) -> Path {
        let key = "\(world)-\(Int(plotSide * 1000))-\(Int(view.pointsPerMetre * 100))"
            + "-\(Int(view.centre.x * 10)),\(Int(view.centre.y * 10))-\(((view.turn % 4) + 4) % 4)"
        if let held = surfaces[key] { return held }

        let worlds = GardenWorlds.shared
        let outline = PlotOutline.of(plotSide: plotSide)
        let mesh = 96
        let half = plotSide / 2, step = plotSide / Double(mesh)
        var screen = [CGPoint]()
        screen.reserveCapacity((mesh + 1) * (mesh + 1))
        for j in 0...mesh {
            for i in 0...mesh {
                let at = outline.warp(x: -half + Double(i) * step, z: -half + Double(j) * step)
                let y = worlds.height(world: world, x: at.x, z: at.z, plotSide: plotSide)
                screen.append(view.point(x: at.x, y: y, z: at.z))
            }
        }
        let left = screen.map(\.x).min() ?? 0, right = screen.map(\.x).max() ?? 0
        let width = 1.0
        let columns = max(2, Int(((right - left) / width).rounded(.up)) + 1)
        var top = [Double](repeating: .infinity, count: columns)
        var bottom = [Double](repeating: -.infinity, count: columns)
        // Along every edge of the grid, not only at its corners: a column a
        // corner happened to miss took its run from the corners inside the
        // rim, and the rim came out notched — pale teeth of unshaded ground
        // standing up out of a shadow that reached the edge.
        func take(_ a: CGPoint, _ b: CGPoint) {
            let steps = max(1, Int((abs(b.x - a.x) / (width / 2)).rounded(.up)))
            for k in 0...steps {
                let t = Double(k) / Double(steps)
                let x = a.x + (b.x - a.x) * t, y = a.y + (b.y - a.y) * t
                let c = min(columns - 1, max(0, Int(((x - left) / width).rounded())))
                top[c] = min(top[c], y)
                bottom[c] = max(bottom[c], y)
            }
        }
        let row = mesh + 1
        for j in 0...mesh {
            for i in 0...mesh {
                let here = screen[j * row + i]
                if i < mesh { take(here, screen[j * row + i + 1]) }
                if j < mesh { take(here, screen[(j + 1) * row + i]) }
            }
        }
        // A column no point fell in takes its neighbours' run.
        for c in 0..<columns where !top[c].isFinite {
            var a = c - 1, b = c + 1
            while a >= 0, !top[a].isFinite { a -= 1 }
            while b < columns, !top[b].isFinite { b += 1 }
            let pick = [a, b].filter { $0 >= 0 && $0 < columns }
            guard !pick.isEmpty else { continue }
            top[c] = pick.map { top[$0] }.reduce(0, +) / Double(pick.count)
            bottom[c] = pick.map { bottom[$0] }.reduce(0, +) / Double(pick.count)
        }

        var path = Path()
        for c in 0..<columns where top[c].isFinite {
            let point = CGPoint(x: left + Double(c) * width, y: top[c])
            if path.isEmpty { path.move(to: point) } else { path.addLine(to: point) }
        }
        for c in stride(from: columns - 1, through: 0, by: -1) where bottom[c].isFinite {
            path.addLine(to: CGPoint(x: left + Double(c) * width, y: bottom[c]))
        }
        path.closeSubpath()
        if surfaces.count > 12 { surfaces.removeAll() }
        surfaces[key] = path
        return path
    }

    @MainActor private static var surfaces: [String: Path] = [:]

    /// Whether the ground's own relief keeps the light off a place: the same
    /// march the ground's hills are shaded by. A plant standing in a hill's
    /// shadow has no shadow of its own to throw.
    static func inRelief(world: Int, at spot: Spot, plotSide: Double,
                         light: GardenGround.Light) -> Bool {
        let worlds = GardenWorlds.shared
        let along = SIMD2(light.direction.x, light.direction.z)
        let rise = light.direction.y
        guard worlds.isLoaded, rise > 0.001, simd_length(along) > 0.001 else { return false }
        let step = plotSide / Double(GardenWorlds.cells)
        let travel = simd_normalize(along) * step
        let climb = rise / simd_length(along) * step
        let outline = PlotOutline.of(plotSide: plotSide)
        var x = spot.x, z = spot.z
        var y = worlds.height(world: world, x: x, z: z, plotSide: plotSide) + max(0.012, step)
        for _ in 0..<46 {
            x += travel.x; z += travel.y; y += climb
            if !outline.reaches(x: x, z: z) { return false }
            if worlds.height(world: world, x: x, z: z, plotSide: plotSide) > y { return true }
        }
        return false
    }
}

// MARK: - On the plot

/// One thing standing on the plot, as far as its shadow is concerned.
///
/// Made afresh every frame the plot is drawn, so it carries what is cheap to
/// carry and works out its keys once: a plant's genome is only built when its
/// caster has to be.
struct ShadowCast: Identifiable {
    enum Thing {
        case plant(PlantRecord, GrowthModel.State)
        case figure(LampKind)
    }

    let id: UUID
    let thing: Thing
    /// Where it stands, for the lie of the ground under it.
    let spot: Spot
    /// Where its foot is drawn, in the plot's own unzoomed points. In hand,
    /// that is where it is held: the thing rises and its shadow stays down.
    let foot: CGPoint
    /// How far round it stands, in radians about the upright, in the plot's
    /// own axes — the same turn its sprite is taken at, less the plot's.
    let turn: Double
    /// How large it is drawn against the size it was made at.
    let scale: Double
    let casterKey: GardenShadows.CasterKey

    init(id: UUID, thing: Thing, spot: Spot, foot: CGPoint, turn: Double, scale: Double) {
        self.id = id
        self.thing = thing
        self.spot = spot
        self.foot = foot
        self.turn = turn
        self.scale = scale
        switch thing {
        case .plant(let record, let growth): casterKey = .plant(record.seed, growth: growth)
        case .figure(let kind): casterKey = .figure(kind)
        }
    }

    func sheetKey(step: Int) -> GardenShadows.SheetKey {
        GardenShadows.SheetKey(caster: casterKey, turn: Int((turn * 1000).rounded()),
                               scale: Int((scale * 100).rounded()), step: step)
    }

    var look: ShadowLook {
        switch thing {
        case .plant: return .plant
        case .figure: return .figure
        }
    }

    /// Where the wander and the dapple are read from, so two plants' shadows
    /// do not break up alike.
    var salt: Double { turn * 3.7 + scale }
}

/// Every shadow on the plot, laid on the ground and multiplied into it.
///
/// **One layer, under everything that stands.** Drawn after the ground and
/// before the lights' pools and the plants, as the web draws its shadows after
/// the ground and before the plants: a shadow darkens the ground and never a
/// plant beside it, and a lamp's pool lights a shadow up rather than being
/// darkened by it. The sheets are laid together and then **multiplied** into
/// the ground — never laid over it as grey — and the whole layer is cut to the
/// plot's top surface, so a long evening shadow stops at the rim instead of
/// running down the cut or out over the sky.
///
/// Each sheet is worked out on level ground and laid on the slope under its
/// foot by one affine map, which is exact for a plane: a shadow thrown down a
/// slope away from the light lengthens and one thrown up it shortens, as they
/// do. A plant in the shadow of a hill throws none of its own.
struct GroundShadows: View {
    let casts: [ShadowCast]
    let view: Isometric
    let world: Int
    let plotSide: Double
    let hour: Double
    let date: Date
    let size: CGSize

    /// Bumped when worked-out shadows arrive, so they are drawn.
    @State private var arrived = 0

    private struct Laid: Identifiable {
        let id: SheetID
        let image: CGImage
        let transform: CGAffineTransform
        let tint: Color
        let opacity: Double
    }

    var body: some View {
        let _ = arrived
        let between = GardenShadows.steps(at: hour)
        // The moon's light by its phase. Not all the way to nothing at the new
        // moon: the ground and the plants are still lit from where the moon is,
        // and a garden lit from one side with nothing casting would be wrong in
        // a way nobody could name.
        let moon = 0.2 + 0.8 * MoonPhase.lit(on: date)
        let laid = casts.flatMap { cast in
            [lay(cast, step: between.before, weight: 1 - between.blend, moon: moon),
             lay(cast, step: between.after, weight: between.blend, moon: moon)].compactMap { $0 }
        }

        ZStack(alignment: .topLeading) {
            ForEach(laid) { sheet in
                Image(decorative: sheet.image, scale: 1)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: CGFloat(sheet.image.width), height: CGFloat(sheet.image.height))
                    .colorMultiply(sheet.tint)
                    .opacity(sheet.opacity)
                    .transformEffect(sheet.transform)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .compositingGroup()
        .clipShape(GardenShadows.surface(world: world, plotSide: plotSide, view: view))
        .blendMode(.multiply)
        .allowsHitTesting(false)
        // Keyed by everything wanted rather than by what is missing, so a
        // shadow arriving does not cancel the work on the next.
        .task(id: wanted(between)) {
            await workOut(missing(between))
        }
    }

    // MARK: Laying one

    private func lay(_ cast: ShadowCast, step: Int, weight: Double, moon: Double) -> Laid? {
        guard weight > 0.002 else { return nil }
        let light = GardenShadows.light(step: step)
        let presence = GardenShadows.presence(of: light) * (light.isDay ? 1 : moon)
        guard presence > 0.002,
              let worked = GardenShadows.shared.sheet(cast.sheetKey(step: step)),
              let sheet = worked else { return nil }
        let ground = Self.ground(world: world, at: cast.spot, plotSide: plotSide, step: step, light: light)
        guard !ground.inRelief else { return nil }
        let gx = ground.slope.x, gz = ground.slope.y

        // Level ground's shadow, moved onto the slope along the light: a point
        // that lands at `p` on the level lands at `p + L (g · p) / D` on the
        // plane, `D` being how much the light still rises over the slope.
        let towards = sheet.light
        let d = max(0.3 * towards.y, towards.y - (gx * towards.x + gz * towards.z))
        let s11 = 1 + towards.x * gx / d, s12 = towards.x * gz / d
        let s21 = towards.z * gx / d, s22 = 1 + towards.z * gz / d

        // And the plane onto the screen.
        let origin = view.point(x: 0, y: 0, z: 0)
        let alongX = view.point(x: 1, y: gx, z: 0), alongZ = view.point(x: 0, y: gz, z: 1)
        let ex = CGPoint(x: alongX.x - origin.x, y: alongX.y - origin.y)
        let ez = CGPoint(x: alongZ.x - origin.x, y: alongZ.y - origin.y)
        let m11 = ex.x * s11 + ez.x * s21, m12 = ex.x * s12 + ez.x * s22
        let m21 = ex.y * s11 + ez.y * s21, m22 = ex.y * s12 + ez.y * s22
        let cell = sheet.cell
        let transform = CGAffineTransform(
            a: m11 * cell, b: m21 * cell, c: m12 * cell, d: m22 * cell,
            tx: cast.foot.x + m11 * sheet.x0 + m12 * sheet.z0,
            ty: cast.foot.y + m21 * sheet.x0 + m22 * sheet.z0
        )

        return Laid(id: SheetID(cast: cast.id, step: step), image: sheet.image, transform: transform,
                    tint: ground.shade, opacity: weight * presence)
    }

    /// The lie of the ground under a foot, as a plane, whether a hill keeps
    /// the light off it, and how dark full shade is there: asked of the
    /// heightmap and the light once for each place and step and kept, because
    /// the plot is drawn every frame of a drag.
    private struct Place: Hashable {
        let world: Int, x: Int, z: Int, side: Int, step: Int
    }

    private typealias Ground = (slope: SIMD2<Double>, inRelief: Bool, shade: Color)

    @MainActor private static var places: [Place: Ground] = [:]

    @MainActor
    private static func ground(world: Int, at spot: Spot, plotSide: Double, step: Int,
                               light: GardenGround.Light) -> Ground {
        let place = Place(world: world, x: Int((spot.x * 1000).rounded()), z: Int((spot.z * 1000).rounded()),
                          side: Int((plotSide * 1000).rounded()), step: step)
        if let held = places[place] { return held }
        let worlds = GardenWorlds.shared
        let reach = 0.15
        func height(_ x: Double, _ z: Double) -> Double {
            worlds.height(world: world, x: x, z: z, plotSide: plotSide)
        }
        let slope = SIMD2((height(spot.x + reach, spot.z) - height(spot.x - reach, spot.z)) / (2 * reach),
                          (height(spot.x, spot.z + reach) - height(spot.x, spot.z - reach)) / (2 * reach))
        let shade = GardenShadows.fullShade(under: light, normal: simd_normalize(SIMD3(-slope.x, 1, -slope.y)))
        let found = (slope: slope,
                     inRelief: GardenShadows.inRelief(world: world, at: spot, plotSide: plotSide, light: light),
                     shade: Color(red: shade.x, green: shade.y, blue: shade.z))
        if places.count > 4_000 { places.removeAll() }
        places[place] = found
        return found
    }

    // MARK: Working them out

    private struct SheetID: Hashable {
        let cast: UUID
        let step: Int
    }

    private struct Wanted {
        let key: GardenShadows.SheetKey
        let cast: ShadowCast
        let step: Int
    }

    private func wanted(_ between: (before: Int, after: Int, blend: Double)) -> Int {
        var hasher = Hasher()
        for cast in casts {
            hasher.combine(cast.sheetKey(step: between.before))
            hasher.combine(cast.sheetKey(step: between.after))
        }
        return hasher.finalize()
    }

    private func missing(_ between: (before: Int, after: Int, blend: Double)) -> [Wanted] {
        var wanted: [Wanted] = []
        for cast in casts {
            for step in Set([between.before, between.after]) {
                guard GardenShadows.presence(of: GardenShadows.light(step: step)) > 0.002 else { continue }
                let key = cast.sheetKey(step: step)
                if GardenShadows.shared.sheet(key) == nil {
                    wanted.append(Wanted(key: key, cast: cast, step: step))
                }
            }
        }
        return wanted
    }

    private func workOut(_ wanted: [Wanted]) async {
        let shadows = GardenShadows.shared
        for item in wanted {
            if Task.isCancelled { return }
            guard shadows.sheet(item.key) == nil else { continue }
            let caster: ShadowCaster
            switch item.cast.thing {
            case .plant(let record, let growth):
                caster = await shadows.caster(item.cast.casterKey) {
                    ShadowCaster(mesh: PlantBuilder(genome: record.genome).mesh(growth: growth))
                }
            case .figure(let kind):
                if let held = shadows.caster(item.cast.casterKey) {
                    caster = held
                } else {
                    guard let model = GardenCreatures.model(of: kind) else { continue }
                    caster = ShadowCaster(node: model)
                    shadows.keep(figure: caster, as: item.cast.casterKey)
                }
            }
            let light = GardenShadows.light(step: item.step).direction
            let look = item.cast.look
            let turn = item.cast.turn, scale = item.cast.scale, salt = item.cast.salt
            let night = !GardenShadows.light(step: item.step).isDay
            let sheet = await Task.detached(priority: .userInitiated) {
                var softer = look
                if night {
                    // The moon's shadows are softer: by night the sky's light
                    // is most of what there is, and the edge of a shade is
                    // less of an edge.
                    softer.near *= 1.6
                    softer.far *= 1.4
                }
                return caster.cast(toward: light, turn: turn, scale: scale, look: softer, salt: salt)
            }.value
            shadows.keep(sheet, as: item.key)
            arrived += 1
        }
    }
}
