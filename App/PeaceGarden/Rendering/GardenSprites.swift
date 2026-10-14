import SceneKit
import simd
import SeedCore
import SwiftUI
import UIKit

/// A plant as a still, drawn at the garden's own scale.
///
/// **This is not `ThumbnailRenderer` with a different size.** A thumbnail frames
/// every plant against its own mature bounds, so each one fills its tile — which
/// is right for a grid and is the one thing a garden must not do. Here a plant
/// that grows to half a metre has to be half the height of one that grows to a
/// metre, because that difference is a real fact about the two plants and the
/// grid was the only reason it was ever hidden.
///
/// So the camera is orthographic and fixed: every sprite covers the same
/// `frameMetres` of vertical plant, and where a plant's top lands in its frame
/// *is* its height. One metre is `renderedPointsPerMetre` points in every
/// sprite, which is exactly the property the isometric plot needs.
@MainActor
final class GardenSprites {
    static let shared = GardenSprites()

    /// A sprite frame is **a whole number of steps of this**, chosen per plant to
    /// hold it, with the foot on the bottom edge.
    ///
    /// It was a single fixed number until the frame was measured. The mockup's
    /// fourteen crossings run 0.46 m to 1.38 m, and `ARRANGING.md` records that
    /// range as the real one; across a hundred and twenty crossings the tallest
    /// is **2.36 m**. A fixed 1.6 m frame drew that plant with its head cut off,
    /// and the cut would have looked like a tall plant rather than like a fault.
    ///
    /// Stepped rather than exact so that two plants of much the same size share a
    /// frame, and a plant's frame does not change by a hair as it grows.
    nonisolated static let frameStep: Double = 0.4

    /// The headroom the plot reserves above its far corner, in metres.
    ///
    /// Not a limit on anything — a plant taller than this is still drawn whole,
    /// in its own frame. It is what the camera leaves room for, and a plant above
    /// it merely stands closer to the top of the screen than the design intends.
    /// `PlotTests` holds it against the measured range.
    nonisolated static let tallestExpected: Double = 2.6

    /// The finest a sprite is ever rendered, in points to the metre: at the
    /// screen's own scale, 300 pixels a metre on a 3x phone. Rendering at the
    /// screen's own scale *on every pinch* would rebuild every plant on every
    /// pinch; this is the ceiling, and `pixelsPerMetre(drawnAt:scale:)` picks
    /// the step under it that the plot actually needs.
    nonisolated static let renderedPointsPerMetre: CGFloat = 100

    /// The ceiling on a 3x screen, which is what a sprite was always rendered
    /// at before 14 October, and what a picture asked for without a size is.
    nonisolated static let fullPixelsPerMetre = 300

    /// The coarsest step a sprite is rendered at.
    nonisolated static let coarsestPixelsPerMetre = 32

    /// **A sprite is rendered at twice the size it is drawn, rounded up to a
    /// power of two** (14 October 2026), never above the ceiling.
    ///
    /// Every plant used to be photographed at 300 pixels a metre whatever the
    /// plot was zoomed to: a 1.6 m frame was 480 pixels square, a megabyte,
    /// for a plant that a garden of five hundred draws fifteen points tall.
    /// Two of those a plant is what put a big garden past five gigabytes.
    ///
    /// **Twice, because the picture was always scaled down.** Drawn at the
    /// size it is taken, a plant keeps every jagged edge SceneKit's own
    /// smoothing leaves; taken at two to four times the size and scaled down,
    /// as it always was, its edges and its finest veins come out as they did.
    /// A garden small enough to be drawn at more than half the ceiling is
    /// still taken at the ceiling, exactly as before; zooming in asks for the
    /// next step, for the plants on screen.
    nonisolated static let oversampling = 2.0

    nonisolated static func pixelsPerMetre(drawnAt pointsPerMetre: Double, scale: Double) -> Int {
        let ceiling = Double(renderedPointsPerMetre) * max(1, scale)
        let wanted = pointsPerMetre * scale * oversampling
        var step = Double(coarsestPixelsPerMetre)
        while step < wanted, step < ceiling { step *= 2 }
        return Int(min(step, ceiling).rounded())
    }

    /// True isometric: the camera sits along `(1, 1, 1)`, which is the same
    /// direction `Isometric` projects from. A sprite rendered from anywhere else
    /// would be a plant photographed from one angle and stood on ground drawn
    /// from another, which is the fault nobody can name when they see it.
    nonisolated static let cameraDirection = SIMD3<Float>(1, 1, 1) / Float(3.0.squareRoot())

    /// `cos` of the camera's elevation, `atan(1/√2)`. A vertical metre takes up
    /// this much of the camera's own up axis, which is what sets the
    /// orthographic scale that puts the foot exactly on the bottom edge.
    nonisolated static let elevationCosine = 0.816_496_580_927_726

    /// **Held by weight, not by count** (14 October 2026). It held 120
    /// pictures, which was one side of sixty plants, so a garden of a hundred
    /// photographed every plant again on every turn back. Every plant on the
    /// plot holds its own two pictures while it is shown; this is what lets a
    /// turn back, a garden opened again or a step of the clock come back
    /// without being taken again, and it is emptied when the garden closes
    /// (`opened()`, `closed()`) and when the phone is short of memory.
    private let cache = NSCache<NSString, Rendered>()
    nonisolated static let cacheBytes = 96 << 20

    private init() {
        cache.totalCostLimit = Self.cacheBytes
        workers = (0..<Self.workerCount).map { SpriteWorker(label: "app.peacegarden.sprites.\($0)") }
        idle = workers
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: .main
        ) { _ in
            MainActor.assumeIsolated { GardenSprites.shared.forget() }
        }
    }

    /// Bucketed the way a thumbnail is: a sprite does not need to follow growth
    /// any more closely than the eye can see at this size. The season is in it
    /// because it colours the light the plant is photographed in, and the
    /// resolution because two sizes of one picture are two pictures.
    nonisolated static func key(genome: Genome, growth: GrowthModel.State,
                                step: Int, turn: Int = 0, season: Season = .orbit,
                                pixelsPerMetre: Int = fullPixelsPerMetre) -> String {
        "\(genome.seed.hex)-\(bucket(of: growth))-\(step)-\(((turn % 4) + 4) % 4)-\(season.key)-\(pixelsPerMetre)"
    }

    nonisolated static func bucket(of growth: GrowthModel.State) -> Int {
        Int(growth.overall * 24) * 10 + Int(growth.bloomOpen * 6)
    }

    /// Everything a picture's mesh and camera depend on, without the step of
    /// the clock: the pictures of one plant at two steps are taken from one
    /// mesh in one sitting.
    nonisolated static func sitting(genome: Genome, growth: GrowthModel.State, quarter: Int,
                                    season: Season, pixelsPerMetre: Int) -> String {
        "\(genome.seed.hex)-\(bucket(of: growth))-\(quarter)-\(season.key)-\(pixelsPerMetre)"
    }

    /// How many ways round a plant is drawn.
    ///
    /// **Four renders each, settled 18 September.** Rotation is free for the
    /// ground, which is computed, and expensive for the plants, which are
    /// sprites taken from one camera — so a turned plot either turns them too or
    /// lets them stay billboards facing the viewer. Billboards are the usual
    /// answer and are a real compromise for a plant with a front and a back, and
    /// every plant here is a meeting with somebody. Four it is.
    ///
    /// It costs four times eight, because a sprite is already drawn at eight
    /// points round the clock. The cache is sized for one plot's worth of them,
    /// not for the whole garden at every angle.
    nonisolated static let turns = 4

    /// The size a sprite draws at on a plot at this scale, foot at the bottom
    /// centre of it.
    nonisolated static func drawnSize(metres: Double, pointsPerMetre: Double) -> CGSize {
        let side = metres * pointsPerMetre
        return CGSize(width: side, height: side)
    }

    /// A plant's still, and how many metres of garden it covers. The two travel
    /// together because one without the other is a picture at an unknown scale.
    struct Sprite {
        let image: UIImage
        let metres: Double
        /// Where the plant actually is inside its frame, as fractions of it.
        ///
        /// **A frame is mostly air.** It is square and sized for the plant's
        /// mature height or spread, whichever is more, so a slim plant fills a
        /// strip of it and a seedling a corner. Answering a finger across the
        /// whole frame meant a plant standing in front of a lantern took every
        /// touch meant for the lantern — the lantern could be seen and not
        /// picked up. So a plant answers only where it has leaves.
        let opaque: CGRect
        /// Where the leaves are, cell by cell, in a unit square: what a finger
        /// actually has to land on.
        ///
        /// **A box is not enough where plants overlap.** The box round a plant
        /// is still mostly air, and where a near plant's box lies over a far
        /// plant's leaves the near plant took the tap — the wrong sheet opened.
        /// Zoom is partly *for* being sure of the plant tapped, and zooming in
        /// could not help while the air answered.
        let leaves: Path

        /// The leaves at a drawn size.
        func leaves(in size: CGSize) -> Path {
            leaves.applying(CGAffineTransform(scaleX: size.width, y: size.height))
        }
    }

    /// What the cache holds: the picture and where the plant is in it, measured
    /// once when it is rendered rather than every time it is drawn.
    final class Rendered: Sendable {
        let image: UIImage
        let metres: Double
        let opaque: CGRect
        let leaves: Path
        init(image: UIImage, metres: Double, opaque: CGRect, leaves: Path) {
            self.image = image
            self.metres = metres
            self.opaque = opaque
            self.leaves = leaves
        }

        var sprite: Sprite { Sprite(image: image, metres: metres, opaque: opaque, leaves: leaves) }

        /// What it weighs in memory, for the cache.
        var bytes: Int {
            image.cgImage.map { $0.bytesPerRow * $0.height } ?? 4 << 10
        }
    }

    /// How finely the leaves are mapped: cells across a sprite's frame.
    nonisolated static let leafCells = 48

    /// Every cell of a picture with something opaque in it, grown by a cell
    /// all round, as a path in a unit square.
    ///
    /// Grown because a stem one point wide is a leaf a finger cannot hit; a cell
    /// either side is a little tolerance at the fitted size, and at 3x the same
    /// cell is a third of that — which is what zooming in to be sure is for.
    /// Rows are merged into runs, so a plant is tens of rectangles, not
    /// thousands. A small picture is read at every pixel rather than every
    /// other one, so no cell is skipped where pixels are fewer than cells.
    nonisolated static func leafPath(of image: UIImage) -> Path {
        guard let cg = image.cgImage else { return Path(CGRect(x: 0, y: 0, width: 1, height: 1)) }
        let width = cg.width, height = cg.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(
            data: &pixels, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return Path(CGRect(x: 0, y: 0, width: 1, height: 1)) }
        context.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))

        let n = leafCells
        let every = min(width, height) >= 2 * n ? 2 : 1
        var solid = [Bool](repeating: false, count: n * n)
        for y in stride(from: 0, to: height, by: every) {
            for x in stride(from: 0, to: width, by: every) where pixels[(y * width + x) * 4 + 3] > 24 {
                solid[(y * n / height) * n + x * n / width] = true
            }
        }

        var grown = solid
        for row in 0..<n {
            for column in 0..<n where solid[row * n + column] {
                for dy in -1...1 {
                    for dx in -1...1 {
                        let r = row + dy, c = column + dx
                        if (0..<n).contains(r), (0..<n).contains(c) { grown[r * n + c] = true }
                    }
                }
            }
        }

        var path = Path()
        let cell = 1 / Double(n)
        for row in 0..<n {
            var column = 0
            while column < n {
                guard grown[row * n + column] else { column += 1; continue }
                let start = column
                while column < n, grown[row * n + column] { column += 1 }
                path.addRect(CGRect(x: Double(start) * cell, y: Double(row) * cell,
                                    width: Double(column - start) * cell, height: cell))
            }
        }
        return path
    }

    /// The box round everything in a picture that is not transparent, as
    /// fractions of the picture. Padded a little, because a leaf a finger's
    /// width from where it was aimed is still the leaf that was meant.
    private nonisolated static func opaqueBounds(of image: UIImage) -> CGRect {
        guard let cg = image.cgImage else { return CGRect(x: 0, y: 0, width: 1, height: 1) }
        let width = cg.width, height = cg.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(
            data: &pixels, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return CGRect(x: 0, y: 0, width: 1, height: 1) }
        context.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))

        let every = min(width, height) >= 2 * leafCells ? 2 : 1
        var minX = width, minY = height, maxX = -1, maxY = -1
        for y in stride(from: 0, to: height, by: every) {
            for x in stride(from: 0, to: width, by: every) where pixels[(y * width + x) * 4 + 3] > 24 {
                minX = min(minX, x); maxX = max(maxX, x)
                minY = min(minY, y); maxY = max(maxY, y)
            }
        }
        guard maxX >= minX, maxY >= minY else { return .zero }

        let pad = 0.03
        let x0 = max(0, Double(minX) / Double(width) - pad)
        let y0 = max(0, Double(minY) / Double(height) - pad)
        let x1 = min(1, Double(maxX + 1) / Double(width) + pad)
        let y1 = min(1, Double(maxY + 1) / Double(height) + pad)
        return CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
    }

    /// `matureBounds` builds a whole second mesh and gives the same answer for
    /// the whole life of a seed, so it is held — the same reason
    /// `ThumbnailRenderer` holds it. Behind a lock, because the pictures are
    /// taken off the main thread and each one needs its frame.
    private nonisolated static let frames = Frames()

    private final class Frames: @unchecked Sendable {
        private let lock = NSLock()
        private var bySeed: [String: Double] = [:]
        func get(_ seed: String) -> Double? { lock.withLock { bySeed[seed] } }
        func set(_ seed: String, _ metres: Double) { lock.withLock { bySeed[seed] = metres } }
    }

    /// How much garden this plant's frame has to cover: its mature height, or
    /// its mature spread if it is wider than it is tall, rounded up to a step.
    ///
    /// Measured against what it will grow into rather than what it is today, so
    /// a plant does not jump between frames as it grows — the same rule the
    /// stage and the tiles both follow, for the same reason.
    nonisolated func frameMetres(for genome: Genome) -> Double {
        Self.frameMetres(for: genome)
    }

    nonisolated static func frameMetres(for genome: Genome) -> Double {
        let seed = genome.seed.hex
        if let held = frames.get(seed) { return held }

        let steps = max(1, Int((needed(of: genome) / frameStep).rounded(.up)))
        let framed = Double(steps) * frameStep

        frames.set(seed, framed)
        return framed
    }

    /// How much frame a plant actually needs, before it is rounded up to a step.
    ///
    /// **A frame is square in metres of height and not in metres of ground.** The
    /// camera looks down, so a metre laid flat takes up less of the picture than
    /// a metre standing up — `elevationCosine / cosThirty` of it, about
    /// nineteen twentieths. A plant as wide as its frame is tall would lose its
    /// outermost leaves, which is the sort of clipping that reads as a narrow
    /// plant rather than as a fault.
    nonisolated static func needed(of genome: Genome) -> Double {
        let bounds = PlantSceneBuilder.matureBounds(for: genome)
        let height = Double(bounds.max.y - bounds.min.y)
        let spread = Double(
            hypot(bounds.max.x - bounds.min.x, bounds.max.z - bounds.min.z)
        )
        return max(height, spread / (elevationCosine / Isometric.cosThirty))
    }

    /// A plant at one of the eight points round the clock.
    ///
    /// **The hour does two different things to a plant at once, and both are
    /// real.** It moves the light on its leaves, which is this; and it opens or
    /// closes its flower through `GrowthModel.diurnalFactor`, which is already
    /// in `growth` before this is called. A garden visited at night is genuinely
    /// a different garden, and was before anybody drew a bed.
    /// - Parameter turn: quarter-turns of the **plot's own axes**, not of the
    ///   camera. The plant and the light are both rotated by it, which is what
    ///   the ground will do when the plot is turned, so a plant's near side stays
    ///   its near side and its light stays where the sun is.
    /// - Parameter season: what colours the light, as it colours the ground's
    ///   and the sky's (`GardenGround.Light.at(hour:season:)`).
    ///
    /// **Taken where it is asked for, at the full size.** What the tests and
    /// the mass test's own timing call. The plot asks for its pictures with
    /// `sprite(…, pixelsPerMetre:) async`, which takes them off the main thread.
    func sprite(genome: Genome, growth: GrowthModel.State,
                step: Int, turn: Int = 0, season: Season = .orbit) -> Sprite? {
        let quarter = ((turn % Self.turns) + Self.turns) % Self.turns
        let pixels = Self.fullPixelsPerMetre
        let key = Self.key(genome: genome, growth: growth, step: step, turn: quarter,
                           season: season, pixelsPerMetre: pixels) as NSString
        if let held = cache.object(forKey: key) { return held.sprite }

        if here == nil { here = SCNRenderer(device: MTLCreateSystemDefaultDevice(), options: nil) }
        guard let renderer = here else { return nil }
        let sitting = Sitting(genome: genome, growth: growth, quarter: quarter, season: season,
                              pixelsPerMetre: pixels, steps: [step])
        guard let made = autoreleasepool(invoking: { Self.take(sitting, with: renderer) }).first
        else { return nil }
        cache.setObject(made.rendered, forKey: key, cost: made.rendered.bytes)
        return made.rendered.sprite
    }

    /// A picture already taken, without taking it: what a plant starts from
    /// when it is drawn again, so a garden opened again, or a plant redrawn,
    /// does not stand empty for a frame while the same picture is fetched.
    func held(genome: Genome, growth: GrowthModel.State, step: Int, turn: Int = 0,
              season: Season = .orbit, pixelsPerMetre: Int) -> Sprite? {
        cache.object(forKey: Self.key(genome: genome, growth: growth, step: step, turn: turn,
                                      season: season, pixelsPerMetre: pixelsPerMetre) as NSString)?.sprite
    }

    /// **The plot's way in: taken off the main thread, and waited for**
    /// (14 October 2026).
    ///
    /// Every picture used to be taken inside its plant's `.task`, on the main
    /// actor, with nothing to suspend on, so a garden opening photographed
    /// every plant back to back before its first frame: 3.2 s of frozen phone
    /// at a hundred plants, 18 s at five hundred, and every turn of the plot
    /// and every step of the clock the same again. Now the plant asks and
    /// waits; the picture is taken on one of two workers, each with its own
    /// renderer; and the garden fills in plant by plant while it can still be
    /// turned and pinched. The two steps either side of the hour are taken
    /// from one mesh in one sitting, and a plant that stops waiting — the plot
    /// turned again, the garden closed — is struck off before it is begun.
    func sprite(genome: Genome, growth: GrowthModel.State, step: Int, turn: Int = 0,
                season: Season = .orbit, pixelsPerMetre: Int) async -> Sprite? {
        let quarter = ((turn % Self.turns) + Self.turns) % Self.turns
        let key = Self.key(genome: genome, growth: growth, step: step, turn: quarter,
                           season: season, pixelsPerMetre: pixelsPerMetre)
        if let held = cache.object(forKey: key as NSString) { return held.sprite }
        guard !Task.isCancelled else { return nil }

        let sitting = Sitting(genome: genome, growth: growth, quarter: quarter, season: season,
                              pixelsPerMetre: pixelsPerMetre, steps: [step])
        tickets += 1
        let ticket = tickets
        let rendered: Rendered? = await withTaskCancellationHandler {
            await withCheckedContinuation { (continuation: CheckedContinuation<Rendered?, Never>) in
                waiting[key, default: []].append(Waiter(ticket: ticket, continuation: continuation))
                want(step, of: sitting, key: key)
            }
        } onCancel: {
            let id = sitting.id
            Task { @MainActor in GardenSprites.shared.giveUp(ticket, on: key, step: step, of: id) }
        }
        return rendered?.sprite
    }

    /// The garden is on screen. Counted, so the pictures are let go of only
    /// when the last one closes.
    func opened() { gardensOpen += 1 }

    /// The garden has gone, and its pictures go with it: every plant held its
    /// own, and this lets go of what was kept besides — the figures' pictures,
    /// the shadows and the ground's drawings too, which the garden alone uses.
    /// 1.46 GB stayed behind after a garden of 500 had closed (mass test,
    /// 13 October, finding 11).
    func closed() {
        gardensOpen = max(0, gardensOpen - 1)
        guard gardensOpen == 0 else { return }
        forget()
        GardenCreatures.shared.forget()
        GardenShadows.shared.forget()
        Task { await GardenTerrain.shared.forget() }
    }

    /// Lets go of every picture kept.
    func forget() {
        cache.removeAllObjects()
    }

    /// How many pictures are being waited for: none once the garden on screen
    /// has every plant it asked for. What the mass test waits on.
    var outstanding: Int {
        waiting.values.reduce(0) { $0 + $1.count }
    }

    // MARK: Taking them off the main thread

    /// Everything one sitting needs, and the steps of the clock it is taken at.
    struct Sitting: Sendable {
        let genome: Genome
        let growth: GrowthModel.State
        let quarter: Int
        let season: Season
        let pixelsPerMetre: Int
        var steps: [Int]
        let id: String

        init(genome: Genome, growth: GrowthModel.State, quarter: Int, season: Season,
             pixelsPerMetre: Int, steps: [Int]) {
            self.genome = genome
            self.growth = growth
            self.quarter = quarter
            self.season = season
            self.pixelsPerMetre = pixelsPerMetre
            self.steps = steps
            id = GardenSprites.sitting(genome: genome, growth: growth, quarter: quarter,
                                       season: season, pixelsPerMetre: pixelsPerMetre)
        }

        func key(step: Int) -> String {
            GardenSprites.key(genome: genome, growth: growth, step: step, turn: quarter,
                              season: season, pixelsPerMetre: pixelsPerMetre)
        }
    }

    /// One picture from a sitting.
    struct Made: Sendable {
        let step: Int
        let rendered: Rendered
    }

    private struct Waiter {
        let ticket: Int
        let continuation: CheckedContinuation<Rendered?, Never>
    }

    /// How many pictures are taken at once. Two: a garden fills in at about
    /// twice the pace of one, and no more than two scenes' worth of memory is
    /// ever in hand.
    nonisolated static let workerCount = 2

    private var workers: [SpriteWorker] = []
    private var idle: [SpriteWorker] = []
    /// The renderer for pictures asked for on the main thread itself.
    private var here: SCNRenderer?

    /// Who is waiting for which picture.
    private var waiting: [String: [Waiter]] = [:]
    /// Sittings asked for and not yet begun, by `Sitting.id`, and the order
    /// they were asked in. Taken first come, first served: the plot asks far
    /// to near, so the garden fills in from the back.
    private var pending: [String: Sitting] = [:]
    private var order: [String] = []
    private var next = 0
    /// Pictures being taken now.
    private var started: Set<String> = []
    private var pumpQueued = false
    private var tickets = 0
    private var gardensOpen = 0

    private func want(_ step: Int, of sitting: Sitting, key: String) {
        guard !started.contains(key) else { return }
        if var already = pending[sitting.id] {
            if !already.steps.contains(step) {
                already.steps.append(step)
                pending[sitting.id] = already
            }
            return
        }
        pending[sitting.id] = sitting
        order.append(sitting.id)
        queuePump()
    }

    /// Begun a beat later rather than at once, so the second step a plant asks
    /// for in the same pass joins the first one's sitting.
    private func queuePump() {
        guard !pumpQueued else { return }
        pumpQueued = true
        Task { @MainActor in GardenSprites.shared.pump() }
    }

    private func pump() {
        pumpQueued = false
        while !idle.isEmpty, let sitting = nextSitting() {
            let worker = idle.removeLast()
            for step in sitting.steps { started.insert(sitting.key(step: step)) }
            worker.queue.async {
                let made = worker.take(sitting)
                Task { @MainActor in GardenSprites.shared.finished(sitting, made: made, by: worker) }
            }
        }
    }

    private func nextSitting() -> Sitting? {
        while next < order.count {
            let id = order[next]
            next += 1
            if let sitting = pending.removeValue(forKey: id) { return sitting }
        }
        order.removeAll(keepingCapacity: true)
        next = 0
        return nil
    }

    private func finished(_ sitting: Sitting, made: [Made], by worker: SpriteWorker) {
        idle.append(worker)
        for step in sitting.steps {
            let key = sitting.key(step: step)
            started.remove(key)
            let rendered = made.first { $0.step == step }?.rendered
            let waiters = waiting.removeValue(forKey: key) ?? []
            // Kept only while a garden is open to want it again.
            if let rendered, gardensOpen > 0 || !waiters.isEmpty {
                cache.setObject(rendered, forKey: key as NSString, cost: rendered.bytes)
            }
            for waiter in waiters { waiter.continuation.resume(returning: rendered) }
        }
        pump()
    }

    private func giveUp(_ ticket: Int, on key: String, step: Int, of sitting: String) {
        guard var waiters = waiting[key], let index = waiters.firstIndex(where: { $0.ticket == ticket })
        else { return }
        let waiter = waiters.remove(at: index)
        waiting[key] = waiters.isEmpty ? nil : waiters
        waiter.continuation.resume(returning: nil)
        guard waiters.isEmpty, var still = pending[sitting] else { return }
        still.steps.removeAll { $0 == step }
        pending[sitting] = still.steps.isEmpty ? nil : still
    }

    /// One sitting: the plant's mesh built once and photographed at each step
    /// asked for. Runs on whichever thread calls it, with a renderer that
    /// thread owns, and touches nothing shared but the frames and the
    /// shadows' store, which both hold their own locks.
    nonisolated static func take(_ sitting: Sitting, with renderer: SCNRenderer) -> [Made] {
        let genome = sitting.genome
        let metres = frameMetres(for: genome)
        let mesh = PlantBuilder(genome: genome).mesh(growth: sitting.growth)
        // The shadow is worked out from this same mesh, so it is handed over
        // while it is here rather than built again for it.
        GardenShadows.shared.keep(mesh, as: .plant(genome.seed, growth: sitting.growth))
        let plant = PlantSceneBuilder.node(for: mesh, palette: genome.palette)

        // A plant's origin is its foot, so it stands at the middle of the frame
        // without being moved. Turned about its own stem by an amount drawn
        // from its seed: a rank of plants all facing the same way reads as a
        // catalogue page, and the turn has to come from the seed rather than
        // from a position, or every plant in the garden spins when one is added.
        let pivot = SCNNode()
        pivot.eulerAngles.y = turn(for: genome.seed) + Float(sitting.quarter) * .pi / 2
        pivot.addChildNode(plant)
        let camera = makeCameraNode(frameMetres: metres)
        let side = max(1, (metres * Double(sitting.pixelsPerMetre)).rounded())

        var made: [Made] = []
        var shape: (opaque: CGRect, leaves: Path)?
        for step in sitting.steps {
            let scene = makeScene(lit: GardenGround.Light.at(step: step, season: sitting.season)
                .turned(quarters: sitting.quarter))
            // Taken with transparency so the ground shows through. If a plant
            // ever comes back as a black square, this is the line that did it —
            // the same trap `ThumbnailRenderer` records.
            scene.background.contents = UIColor.clear
            pivot.removeFromParentNode()
            scene.rootNode.addChildNode(pivot)
            renderer.scene = scene
            renderer.pointOfView = camera
            // Off the main thread there is no run loop to commit SceneKit's
            // implicit transaction, so it is committed before the picture.
            SCNTransaction.flush()
            let image = renderer.snapshot(atTime: 0, with: CGSize(width: side, height: side),
                                          antialiasingMode: .multisampling4X)
            guard image.size.width > 0 else { continue }
            // The light moves the colours and not the outline, so where the
            // plant is in its frame is measured once a sitting.
            let measured = shape ?? (opaqueBounds(of: image), leafPath(of: image))
            shape = measured
            made.append(Made(step: step, rendered: Rendered(image: image, metres: metres,
                                                            opaque: measured.opaque,
                                                            leaves: measured.leaves)))
        }
        renderer.scene = nil
        return made
    }

    /// A plant standing outdoors, under the same light as the ground it stands on.
    ///
    /// **`PlantSceneBuilder.makeScene` is a studio and is exactly wrong here.**
    /// One hard key, a cold rim and an ambient of about 0.09, so an unlit face
    /// falls to near-black: right for a botanical model kit photographed for its
    /// box, and wrong for a plant standing in a garden at four in the afternoon.
    /// The garden light is hemispheric — sky from above, bounce from the ground
    /// below — so a shadowed leaf is lit by the sky rather than by nothing. No
    /// amount of filtering the studio render gets there, because the information
    /// is not in the rendered pixels to recover.
    ///
    /// The numbers are the same ones the ground is shaded with, read from the
    /// same function, so the plant and the ground can never be lit from
    /// different hours.
    nonisolated static func makeScene(lit light: GardenGround.Light) -> SCNScene {
        let scene = SCNScene()

        // A low gold sun keeps its brightness, so its red is a little over
        // one (`GardenGround.Light.sunlight`). A light's colour is a colour,
        // so the excess goes into its intensity instead.
        let over = max(1, light.colour.x, light.colour.y, light.colour.z)
        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        sun.light?.color = UIColor(red: light.colour.x / over, green: light.colour.y / over,
                                   blue: light.colour.z / over, alpha: 1)
        sun.light?.intensity = 1400 * light.strength * over
        sun.light?.castsShadow = false
        // A directional light shines down its own negative z, so the node stands
        // off along the direction the light comes *from* and looks back at the
        // plant.
        sun.position = SCNVector3(Float(light.direction.x) * 10,
                                  Float(light.direction.y) * 10,
                                  Float(light.direction.z) * 10)
        sun.look(at: SCNVector3Zero, up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 0, -1))
        scene.rootNode.addChildNode(sun)

        let sky = SCNNode()
        sky.light = SCNLight()
        sky.light?.type = .ambient
        sky.light?.color = UIColor(red: light.sky.x, green: light.sky.y,
                                   blue: light.sky.z, alpha: 1)
        sky.light?.intensity = 700
        scene.rootNode.addChildNode(sky)

        // The galaxy, from straight overhead. Directional rather than ambient,
        // so it lights the tops of leaves and leaves their undersides to the
        // bounce — the same weighting the ground gives it.
        if simd_length(light.galaxy) > 0.001 {
            let galaxy = SCNNode()
            galaxy.light = SCNLight()
            galaxy.light?.type = .directional
            galaxy.light?.color = UIColor(red: light.galaxy.x, green: light.galaxy.y,
                                          blue: light.galaxy.z, alpha: 1)
            galaxy.light?.intensity = 1300
            galaxy.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
            scene.rootNode.addChildNode(galaxy)
        }

        // The light a plant gets back off the ground it is standing on. Without
        // it a leaf facing away from the sun falls to the ambient alone and
        // reads as a hole cut in the plant rather than as a leaf in shade.
        let bounce = SCNNode()
        bounce.light = SCNLight()
        bounce.light?.type = .directional
        bounce.light?.color = UIColor(red: light.bounce.x, green: light.bounce.y,
                                      blue: light.bounce.z, alpha: 1)
        bounce.light?.intensity = 500
        bounce.eulerAngles = SCNVector3(0.9, -0.4, 0)
        scene.rootNode.addChildNode(bounce)

        return scene
    }

    /// Which way a plant faces, in radians, from two bytes of its own seed.
    nonisolated static func turn(for seed: SeedID) -> Float {
        let bytes = [UInt8](seed.bytes)
        guard bytes.count >= 2 else { return 0 }
        let whole = (Int(bytes[0]) << 8) | Int(bytes[1])
        return Float(Double(whole) / 65_535 * 2 * .pi)
    }

    /// The camera every sprite is taken with.
    ///
    /// Orthographic, so there is no perspective to make a plant at the edge of
    /// its frame lean. `orthographicScale` is half the frame's height in world
    /// units; setting it to half the covered height *along the camera's own up
    /// axis* is what lands the plant's foot exactly on the bottom edge, which is
    /// the anchor the plot places against.
    nonisolated static func makeCameraNode(frameMetres: Double) -> SCNNode {
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = frameMetres * elevationCosine / 2
        camera.zNear = 0.01
        camera.zFar = 100
        camera.wantsHDR = false

        let node = SCNNode()
        node.camera = camera

        let target = SCNVector3(0, Float(frameMetres / 2), 0)
        node.position = SCNVector3(
            target.x + cameraDirection.x * 20,
            target.y + cameraDirection.y * 20,
            target.z + cameraDirection.z * 20
        )

        // Aimed with `look(at:)` rather than by Euler angles, which are applied
        // in an order it is easy to be wrong about and hard to see you were
        // wrong about — the plot would simply be the wrong shape.
        node.look(at: target, up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 0, -1))
        return node
    }
}

/// One renderer, kept on one queue. SceneKit's renderer belongs to the thread
/// that uses it, so each worker has its own and only ever uses it there.
final class SpriteWorker: @unchecked Sendable {
    let queue: DispatchQueue
    private var renderer: SCNRenderer?

    init(label: String) {
        queue = DispatchQueue(label: label, qos: .userInitiated)
    }

    /// On `queue` only: `work` with this worker's renderer, in a pool of its
    /// own, so whatever SceneKit autoreleases goes with the picture.
    func withRenderer<T>(_ work: (SCNRenderer) -> T?) -> T? {
        dispatchPrecondition(condition: .onQueue(queue))
        if renderer == nil { renderer = SCNRenderer(device: MTLCreateSystemDefaultDevice(), options: nil) }
        guard let renderer else { return nil }
        return autoreleasepool { work(renderer) }
    }

    /// On `queue` only.
    func take(_ sitting: GardenSprites.Sitting) -> [GardenSprites.Made] {
        withRenderer { GardenSprites.take(sitting, with: $0) } ?? []
    }
}
