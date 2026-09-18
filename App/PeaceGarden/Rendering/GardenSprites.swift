import SceneKit
import simd
import SeedCore
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

    /// The resolution a sprite is rendered at, independent of what the plot is
    /// zoomed to. Rendering at the screen's own scale would rebuild every plant
    /// on every pinch; this renders once and the drawing scales the image.
    nonisolated static let renderedPointsPerMetre: CGFloat = 100

    /// True isometric: the camera sits along `(1, 1, 1)`, which is the same
    /// direction `Isometric` projects from. A sprite rendered from anywhere else
    /// would be a plant photographed from one angle and stood on ground drawn
    /// from another, which is the fault nobody can name when they see it.
    nonisolated static let cameraDirection = SIMD3<Float>(1, 1, 1) / Float(3.0.squareRoot())

    /// `cos` of the camera's elevation, `atan(1/√2)`. A vertical metre takes up
    /// this much of the camera's own up axis, which is what sets the
    /// orthographic scale that puts the foot exactly on the bottom edge.
    nonisolated static let elevationCosine = 0.816_496_580_927_726

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 120
    }

    /// Bucketed the way a thumbnail is: a sprite does not need to follow growth
    /// any more closely than the eye can see at this size.
    nonisolated static func key(genome: Genome, growth: GrowthModel.State,
                                step: Int, turn: Int = 0) -> String {
        let bucket = Int(growth.overall * 24) * 10 + Int(growth.bloomOpen * 6)
        return "\(genome.seed.hex)-\(bucket)-\(step)-\(((turn % 4) + 4) % 4)"
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
    }

    /// `matureBounds` builds a whole second mesh and gives the same answer for
    /// the whole life of a seed, so it is held — the same reason
    /// `ThumbnailRenderer` holds it.
    private var frameBySeed: [String: Double] = [:]

    /// How much garden this plant's frame has to cover: its mature height, or
    /// its mature spread if it is wider than it is tall, rounded up to a step.
    ///
    /// Measured against what it will grow into rather than what it is today, so
    /// a plant does not jump between frames as it grows — the same rule the
    /// stage and the tiles both follow, for the same reason.
    func frameMetres(for genome: Genome) -> Double {
        if let held = frameBySeed[genome.seed.hex] { return held }

        let steps = max(1, Int((Self.needed(of: genome) / Self.frameStep).rounded(.up)))
        let framed = Double(steps) * Self.frameStep

        frameBySeed[genome.seed.hex] = framed
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
    static func needed(of genome: Genome) -> Double {
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
    func sprite(genome: Genome, growth: GrowthModel.State,
                step: Int, turn: Int = 0) -> Sprite? {
        let quarter = ((turn % Self.turns) + Self.turns) % Self.turns
        let metres = frameMetres(for: genome)
        let key = Self.key(genome: genome, growth: growth, step: step, turn: quarter) as NSString
        if let held = cache.object(forKey: key) { return Sprite(image: held, metres: metres) }

        let side = CGFloat(metres) * Self.renderedPointsPerMetre
        let view = SCNView(frame: CGRect(x: 0, y: 0, width: side, height: side))
        view.scene = Self.makeScene(lit: GardenGround.Light.at(step: step)
            .turned(quarters: quarter))
        // Snapshotted with transparency so the ground shows through. If a plant
        // ever comes back as a black square, this is the pair of lines that did
        // it — the same trap `ThumbnailRenderer` records.
        view.backgroundColor = .clear
        view.isOpaque = false
        view.antialiasingMode = .multisampling4X

        let mesh = PlantBuilder(genome: genome).mesh(growth: growth)
        let plant = PlantSceneBuilder.node(for: mesh, palette: genome.palette)

        // A plant's origin is its foot, so it stands at the middle of the frame
        // without being moved. Turned about its own stem by an amount drawn
        // from its seed: a rank of plants all facing the same way reads as a
        // catalogue page, and the turn has to come from the seed rather than
        // from a position, or every plant in the garden spins when one is added.
        let pivot = SCNNode()
        pivot.eulerAngles.y = Self.turn(for: genome.seed)
            + Float(quarter) * .pi / 2
        pivot.addChildNode(plant)
        view.scene?.rootNode.addChildNode(pivot)

        view.pointOfView = Self.makeCameraNode(frameMetres: metres)

        let snapshot = view.snapshot()
        guard snapshot.size.width > 0 else { return nil }
        cache.setObject(snapshot, forKey: key)
        return Sprite(image: snapshot, metres: metres)
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
    static func makeScene(lit light: GardenGround.Light) -> SCNScene {
        let scene = SCNScene()

        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        sun.light?.color = UIColor(red: light.colour.x, green: light.colour.y,
                                   blue: light.colour.z, alpha: 1)
        sun.light?.intensity = 1400 * light.strength
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
    static func makeCameraNode(frameMetres: Double) -> SCNNode {
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
