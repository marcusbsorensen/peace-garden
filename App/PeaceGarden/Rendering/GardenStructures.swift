import SceneKit
import SeedCore
import SwiftUI
import UIKit

/// What is built in a garden rather than grown: for now, the Long Walk's
/// hedges and its mown path. `docs/WEB-GARDENS.md` §*Structures need drawing
/// properly*.
///
/// **A clipped hedge is a geometric form**, which is why it can be modelled as
/// one: a yew hedge is a box with rounded shoulders, in real life as here. What
/// stops it being a green rectangle is the grain of the leaves on it and the
/// garden's own light across it, so it is rendered like a figure — by the
/// plants' camera, under the plants' light, at eight hours and four turns.
@MainActor
final class GardenStructures {
    static let shared = GardenStructures()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 96
    }

    // MARK: Hedges

    /// A hedge is drawn as a run of short pieces, each sorted into the garden
    /// by its own depth like a plant. A hedge the length of the plot is in front
    /// of some plants and behind others, and one picture cannot be both.
    static let pieceLength = 0.4

    /// Through the hedge, across the walk.
    static let thickness = 0.36

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

    static func key(height: Double, step: Int, turn: Int) -> String {
        "hedge-\(Int(height * 100))-\(step)-\(((turn % 4) + 4) % 4)"
    }

    func hedge(height: Double, step: Int, turn: Int) -> UIImage? {
        let quarter = ((turn % 4) + 4) % 4
        let key = Self.key(height: height, step: step, turn: quarter) as NSString
        if let held = cache.object(forKey: key) { return held }

        let figure = Self.figure(height: height)
        let side = CGFloat(figure.metres) * GardenCreatures.renderedPointsPerMetre / 2
        let view = SCNView(frame: CGRect(x: 0, y: 0, width: side, height: side))
        view.scene = GardenSprites.makeScene(lit: GardenGround.Light.at(step: step).turned(quarters: quarter))
        view.backgroundColor = .clear
        view.isOpaque = false
        view.antialiasingMode = .multisampling4X

        // A little longer than a piece, so neighbours overlap and no light
        // shows between them. **Square-ended**: with rounded shoulders every
        // piece's rounded ends drew a dark seam at each joint, and the hedge
        // came out as a row of posts.
        let box = SCNBox(width: Self.thickness, height: height,
                         length: Self.pieceLength + 0.03, chamferRadius: 0)
        box.materials = [Self.yew]
        let node = SCNNode(geometry: box)
        node.position = SCNVector3(0, Float(height / 2), 0)

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

    /// Clipped yew: very dark, matte, and grained with the small leaves a
    /// clipped face is made of — a speckle of lighter and darker greens.
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
            UIColor(red: 0.14, green: 0.25, blue: 0.12, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 0, width: side, height: side))
            for _ in 0..<900 {
                let x = Double(random.next() % UInt64(side)), y = Double(random.next() % UInt64(side))
                let r = 1 + Double(random.next() % 3)
                let lift = Double(random.next() % 100) / 100 * 0.16 - 0.07
                UIColor(red: 0.14 + lift * 0.6, green: 0.26 + lift, blue: 0.12 + lift * 0.5, alpha: 1).setFill()
                context.cgContext.fillEllipse(in: CGRect(x: x, y: y, width: r, height: r * 0.7))
            }
        }
    }()
}

// MARK: - Drawing them

/// One piece of hedge standing on the plot, crossfaded round the clock the way
/// a plant is. Its shadow is `HedgeShadow`'s, for the whole hedge at once.
struct HedgePiece: View {
    let height: Double
    let pointsPerMetre: Double
    let hour: Double
    let turn: Int

    @State private var before: UIImage?
    @State private var after: UIImage?

    private var between: (before: Int, after: Int, blend: Double) {
        GardenGround.Light.steps(at: hour)
    }

    var body: some View {
        let figure = GardenStructures.figure(height: height)
        let side = figure.metres * pointsPerMetre

        ZStack {
            if let before { Image(uiImage: before).resizable() }
            if let after { Image(uiImage: after).resizable().opacity(between.blend) }
        }
        .frame(width: side, height: side)
        .offset(y: figure.lift * side)
        .task(id: GardenStructures.key(height: height, step: between.before, turn: turn)) {
            before = GardenStructures.shared.hedge(height: height, step: between.before, turn: turn)
        }
        .task(id: GardenStructures.key(height: height, step: between.after, turn: turn)) {
            after = GardenStructures.shared.hedge(height: height, step: between.after, turn: turn)
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
struct MownPath: View {
    let view: Isometric
    let light: GardenGround.Light
    let plotSide: Double
    let height: (Spot) -> Double

    /// Lighter and flatter than the turf beside it: mown short, and walked.
    static let grass = SIMD3<Double>(0.285, 0.320, 0.225)

    var body: some View {
        Canvas { context, _ in
            let half = plotSide / 2
            let width = LongWalk.pathHalfWidth
            let bands = 3
            let across = 2 * width / Double(bands)
            for band in 0..<bands {
                let x0 = -width + Double(band) * across
                let x1 = x0 + across
                // Walked down its length in short steps, so the path follows
                // the ground's rises instead of cutting straight through them.
                var edge: [Spot] = []
                for step in 0...26 { edge.append(Spot(x: x0, z: -half + Double(step) / 26 * plotSide)) }
                for step in (0...26).reversed() { edge.append(Spot(x: x1, z: -half + Double(step) / 26 * plotSide)) }
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
struct HedgeShadow: View {
    let view: Isometric
    let light: GardenGround.Light
    let plotSide: Double
    /// Each hedge: how far out from the path its middle stands, and how tall.
    let hedges: [(x: Double, height: Double)]
    let height: (Spot) -> Double

    var body: some View {
        Canvas { context, _ in
            let rise = max(0.12, light.direction.y)
            let half = plotSide / 2
            let thick = GardenStructures.thickness / 2
            var shadow = Path()
            for hedge in hedges {
                let away = Spot(x: -light.direction.x / rise * hedge.height,
                                z: -light.direction.z / rise * hedge.height)
                let foot = [Spot(x: hedge.x - thick, z: -half), Spot(x: hedge.x + thick, z: -half),
                            Spot(x: hedge.x + thick, z: half), Spot(x: hedge.x - thick, z: half)]
                let cast = foot.map { Spot(x: $0.x + away.x, z: $0.z + away.z) }
                // The footprint and its cast, and the band each edge sweeps
                // between them: their union is the shadow, whichever way the
                // light falls.
                var quads: [[Spot]] = [foot, cast]
                for i in 0..<4 {
                    let next = (i + 1) % 4
                    quads.append([foot[i], foot[next], cast[next], cast[i]])
                }
                for quad in quads {
                    var piece = Path()
                    for (n, corner) in quad.enumerated() {
                        let clamped = Spot(x: min(max(corner.x, -half), half),
                                           z: min(max(corner.z, -half), half))
                        let point = view.point(corner, y: height(clamped))
                        if n == 0 { piece.move(to: point) } else { piece.addLine(to: point) }
                    }
                    piece.closeSubpath()
                    shadow.addPath(piece)
                }
            }
            // Only on the plot: a shadow off the edge would fall on the sky.
            context.clip(to: GardenGround.topFace(plotSide: plotSide, in: view))
            context.fill(shadow, with: .color(.black.opacity(max(0.10, 0.42 * light.strength / 0.76))))
        }
        .allowsHitTesting(false)
    }
}
