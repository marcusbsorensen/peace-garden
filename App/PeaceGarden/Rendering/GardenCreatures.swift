import SceneKit
import simd
import SeedCore
import SwiftUI
import UIKit

/// The glow-in-the-dark animals: a hare, a fox, a moth and a snail, as figures
/// painted with the pale paint that holds the day's light and gives it back
/// after dark.
///
/// **Modelled and rendered, not drawn.** Settled 18 September. They stand beside
/// plants grown from a genome and rendered in the garden's own light, and a hare
/// drawn in SwiftUI shapes would be clip art beside them. So each is a SceneKit
/// figure, rendered by the same camera and under the same light as a plant, at
/// the same eight points round the clock and four turns of the plot. They are
/// figures rather than animals, which is what lets a moth be a moth you can find
/// on a plot five metres across: a real one would be four points wide.
///
/// **Two pictures, not one.** The figure as the garden lights it, and the glow
/// alone, taken with nothing lighting it but itself. The glow is laid over the
/// lit figure *added*, by as much as it is dark — so the one render of the glow
/// serves every hour, and the paint comes up exactly as the lanterns do.
@MainActor
final class GardenCreatures {
    static let shared = GardenCreatures()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 160
    }

    /// Rendered finer than a plant. A figure is a fifth of a metre and is looked
    /// at closely; at a plant's hundred points a metre a snail is twenty points
    /// across before anybody zooms.
    nonisolated static let renderedPointsPerMetre: CGFloat = 260

    nonisolated static func isCreature(_ kind: LampKind) -> Bool {
        figure(of: kind) != nil
    }

    // MARK: The frame each is taken in

    /// How much garden a figure's picture covers, and where its foot is in it.
    ///
    /// **A figure's foot is not on the bottom edge.** A plant is a stem with
    /// everything above it, so its foot can be. An animal lies along the ground,
    /// and the half of it nearer the camera is drawn *below* where it stands —
    /// a fox with its foot on the bottom edge loses its nose. So the frame
    /// reaches below the foot by `lift` of itself.
    struct Figure {
        /// The picture's side, in metres of standing height.
        let metres: Double
        /// How far up the picture the foot is, as a fraction of it.
        let lift: Double
        /// The glow's colour, which is also the colour of the little light it
        /// casts.
        let glow: SIMD3<Double>
    }

    nonisolated static func figure(of kind: LampKind) -> Figure? {
        switch kind {
        case .hare: return Figure(metres: 0.80, lift: 0.20, glow: SIMD3(0.55, 1.00, 0.62))
        case .fox: return Figure(metres: 0.66, lift: 0.33, glow: SIMD3(0.45, 0.95, 0.88))
        case .moth: return Figure(metres: 0.60, lift: 0.20, glow: SIMD3(0.64, 0.86, 1.00))
        case .snail: return Figure(metres: 0.44, lift: 0.26, glow: SIMD3(0.80, 1.00, 0.46))
        case .lantern, .paperLamp, .fireflies: return nil
        }
    }

    /// Which way a figure faces, in eighths of a turn, from its light's own id —
    /// so two hares are not a pair of bookends, and a figure keeps facing the
    /// way it did when it is looked at again.
    nonisolated static func facing(seed: Int) -> Int {
        ((seed % 8) + 8) % 8
    }

    nonisolated static func key(_ kind: LampKind, step: Int?, turn: Int, facing: Int) -> String {
        let quarter = ((turn % 4) + 4) % 4
        return "\(kind.rawValue)-\(step.map(String.init) ?? "glow")-\(quarter)-\(facing)"
    }

    // MARK: Rendering

    /// The figure under the garden's light at one of the eight points round the
    /// clock, or — with `step` nil — its glow alone.
    func picture(_ kind: LampKind, step: Int?, turn: Int, facing: Int) -> UIImage? {
        guard let figure = Self.figure(of: kind) else { return nil }
        let quarter = ((turn % 4) + 4) % 4
        let key = Self.key(kind, step: step, turn: quarter, facing: facing) as NSString
        if let held = cache.object(forKey: key) { return held }

        let glowing = step == nil
        let side = CGFloat(figure.metres) * Self.renderedPointsPerMetre
        let view = SCNView(frame: CGRect(x: 0, y: 0, width: side, height: side))
        view.scene = step.map {
            GardenSprites.makeScene(lit: GardenGround.Light.at(step: $0).turned(quarters: quarter))
        } ?? Self.glowScene()
        view.backgroundColor = .clear
        view.isOpaque = false
        view.antialiasingMode = .multisampling4X

        let paint = Paint(glowing: glowing, glow: figure.glow)
        let body: SCNNode
        switch kind {
        case .hare: body = Self.hare(paint)
        case .fox: body = Self.fox(paint)
        case .moth: body = Self.moth(paint)
        case .snail: body = Self.snail(paint)
        case .lantern, .paperLamp, .fireflies: return nil
        }

        // Turned with the plot, as a plant is, so its near side stays its near
        // side and the sun stays where the sun is.
        let pivot = SCNNode()
        pivot.eulerAngles.y = Float(facing) * .pi / 4 + Float(quarter) * .pi / 2
        pivot.addChildNode(body)
        view.scene?.rootNode.addChildNode(pivot)
        view.pointOfView = Self.camera(for: figure)

        let snapshot = view.snapshot()
        guard snapshot.size.width > 0 else { return nil }
        cache.setObject(snapshot, forKey: key)
        return snapshot
    }

    /// The camera a plant is taken with, reaching below the foot.
    ///
    /// `GardenSprites.makeCameraNode` aims at half the frame's height straight
    /// above the foot. Here it aims along the camera's own up axis instead, by
    /// how far the foot should sit above the bottom edge — which is the one
    /// number that says it, where an aim point in the world would have to be
    /// worked back through the elevation.
    static func camera(for figure: Figure) -> SCNNode {
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        let half = figure.metres * GardenSprites.elevationCosine / 2
        camera.orthographicScale = half
        camera.zNear = 0.01
        camera.zFar = 100
        camera.wantsHDR = false

        let node = SCNNode()
        node.camera = camera

        // The camera's up, in the world: straight up, less the part of it along
        // the line of sight.
        let up = SIMD3<Float>(-1, 2, -1) / Float(6.0.squareRoot())
        let above = Float(half - figure.lift * figure.metres * GardenSprites.elevationCosine)
        let target = up * above
        let eye = target + GardenSprites.cameraDirection * 20
        node.simdPosition = eye
        node.look(at: SCNVector3(target.x, target.y, target.z),
                  up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 0, -1))
        return node
    }

    /// What the glow is photographed under: nothing but a little light from
    /// the viewer's side, so the paint has a shape rather than being a flat
    /// cut-out. Phosphorescence is in fact about that flat, and would read as a
    /// sticker.
    private static func glowScene() -> SCNScene {
        let scene = SCNScene()
        let front = SCNNode()
        front.light = SCNLight()
        front.light?.type = .directional
        front.light?.intensity = 1000
        let from = GardenSprites.cameraDirection + SIMD3(0, 0.6, 0)
        front.simdPosition = from * 10
        front.look(at: SCNVector3Zero, up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 0, -1))
        scene.rootNode.addChildNode(front)
        return scene
    }

    // MARK: The paint

    /// The materials a figure is made of, for one of the two pictures.
    struct Paint {
        let glowing: Bool
        let glow: SIMD3<Double>

        /// The luminous paint. By day it is the pale, faintly green white that
        /// glow-in-the-dark paint is; in the glow picture, it is the glow.
        var luminous: SCNMaterial {
            let material = SCNMaterial()
            if glowing {
                material.lightingModel = .lambert
                material.diffuse.contents = Self.colour(glow * 0.35)
                material.emission.contents = Self.colour(glow * 0.62)
            } else {
                material.lightingModel = .physicallyBased
                material.diffuse.contents = Self.colour(SIMD3(0.83, 0.87, 0.74))
                material.roughness.contents = NSNumber(value: 0.55)
                material.metalness.contents = NSNumber(value: 0.0)
            }
            return material
        }

        /// Anything painted over the luminous paint, or not painted with it: an
        /// eye, a nose, a moth's eyespots, the stake it stands on. Black in the
        /// glow picture, so it hides the glow behind it the way it would.
        func unlit(_ colour: SIMD3<Double>, roughness: Double = 0.5) -> SCNMaterial {
            let material = SCNMaterial()
            if glowing {
                material.lightingModel = .constant
                material.diffuse.contents = UIColor.black
            } else {
                material.lightingModel = .physicallyBased
                material.diffuse.contents = Self.colour(colour)
                material.roughness.contents = NSNumber(value: roughness)
                material.metalness.contents = NSNumber(value: 0.0)
            }
            return material
        }

        var eye: SCNMaterial { unlit(SIMD3(0.07, 0.07, 0.08), roughness: 0.25) }

        static func colour(_ rgb: SIMD3<Double>) -> UIColor {
            UIColor(red: rgb.x, green: rgb.y, blue: rgb.z, alpha: 1)
        }
    }

    // MARK: Modelling

    /// An ellipsoid: a sphere, scaled. Most of any animal is one.
    private static func blob(_ centre: SIMD3<Float>, _ radii: SIMD3<Float>, _ material: SCNMaterial,
                             pitch: Float = 0, yaw: Float = 0, roll: Float = 0) -> SCNNode {
        let sphere = SCNSphere(radius: 1)
        sphere.segmentCount = 40
        sphere.materials = [material]
        let node = SCNNode(geometry: sphere)
        node.simdPosition = centre
        node.simdScale = radii
        node.eulerAngles = SCNVector3(pitch, yaw, roll)
        return node
    }

    /// An ellipsoid laid from one point to another: a leg, an ear, a feeler.
    /// `width` is across it and `depth` through it, which for an ear is its
    /// thinness.
    private static func limb(from a: SIMD3<Float>, to b: SIMD3<Float>,
                             width: Float, depth: Float, _ material: SCNMaterial) -> SCNNode {
        let along = b - a
        let node = blob((a + b) / 2, SIMD3(width, simd_length(along) / 2, depth), material)
        node.eulerAngles = SCNVector3Zero
        node.simdOrientation = simd_quatf(from: SIMD3(0, 1, 0), to: simd_normalize(along))
        return node
    }

    /// A cone from its base to its tip.
    private static func cone(from base: SIMD3<Float>, to tip: SIMD3<Float>,
                             radius: Float, tip tipRadius: Float = 0.002,
                             _ material: SCNMaterial) -> SCNNode {
        let along = tip - base
        let geometry = SCNCone(topRadius: CGFloat(tipRadius), bottomRadius: CGFloat(radius),
                               height: CGFloat(simd_length(along)))
        geometry.radialSegmentCount = 32
        geometry.materials = [material]
        let node = SCNNode(geometry: geometry)
        node.simdPosition = (base + tip) / 2
        node.simdOrientation = simd_quatf(from: SIMD3(0, 1, 0), to: simd_normalize(along))
        return node
    }

    /// The hare, sitting up, ears raised and laid a little back. Faces +z.
    /// Half a metre to the tips of its ears, which is a hare.
    static func hare(_ paint: Paint) -> SCNNode {
        let root = SCNNode()
        let coat = paint.luminous

        // The haunch it sits on, and the chest rising out of it.
        root.addChildNode(blob(SIMD3(0, 0.105, -0.03), SIMD3(0.095, 0.10, 0.12), coat))
        root.addChildNode(blob(SIMD3(0, 0.185, 0.03), SIMD3(0.068, 0.105, 0.072), coat, pitch: 0.25))

        // The head, nose down a little, and the muzzle.
        root.addChildNode(blob(SIMD3(0, 0.29, 0.075), SIMD3(0.05, 0.052, 0.072), coat, pitch: 0.3))
        root.addChildNode(blob(SIMD3(0, 0.272, 0.132), SIMD3(0.026, 0.024, 0.026), coat))

        for side: Float in [-1, 1] {
            // The ears: long, thin, and set back.
            root.addChildNode(limb(from: SIMD3(side * 0.022, 0.325, 0.055),
                                   to: SIMD3(side * 0.062, 0.49, -0.025),
                                   width: 0.024, depth: 0.009, coat))
            // The forelegs, straight down to the paws.
            root.addChildNode(limb(from: SIMD3(side * 0.03, 0.16, 0.075),
                                   to: SIMD3(side * 0.032, 0.014, 0.1),
                                   width: 0.016, depth: 0.016, coat))
            root.addChildNode(blob(SIMD3(side * 0.032, 0.012, 0.115), SIMD3(0.018, 0.012, 0.028), coat))
            // The long hind feet it sits on.
            root.addChildNode(blob(SIMD3(side * 0.066, 0.018, 0.02), SIMD3(0.028, 0.018, 0.085), coat))
            // The eyes, high on the side of the head, as a hare's are.
            root.addChildNode(blob(SIMD3(side * 0.043, 0.302, 0.098), SIMD3(repeating: 0.009), paint.eye))
        }

        root.addChildNode(blob(SIMD3(0, 0.062, -0.148), SIMD3(repeating: 0.032), coat))
        root.addChildNode(blob(SIMD3(0, 0.268, 0.156), SIMD3(0.008, 0.006, 0.005), paint.eye))
        return root
    }

    /// The fox, curled asleep: its brush wrapped round the front of it and its
    /// nose laid along it.
    static func fox(_ paint: Paint) -> SCNNode {
        let root = SCNNode()
        let coat = paint.luminous

        // Low, so the head can be seen above it: at a body's full height the
        // head sank into the coil and the fox was a dome.
        root.addChildNode(blob(SIMD3(0, 0.065, 0), SIMD3(0.19, 0.065, 0.13), coat))
        root.addChildNode(blob(SIMD3(-0.07, 0.085, -0.02), SIMD3(0.1, 0.075, 0.1), coat))

        // The brush: a run of beads round an ellipse from the rump to under the
        // chin, fullest past its middle. Close enough together that they read as
        // one soft length rather than as beads.
        let beads = 26
        for bead in 0..<beads {
            let t = Float(bead) / Float(beads - 1)
            let angle = Float.pi * (0.97 - 0.82 * t)
            let x = 0.215 * cos(angle)
            let z = 0.155 * sin(angle)
            let radius = 0.03 + 0.032 * sin(Float.pi * pow(t, 0.75))
            root.addChildNode(blob(SIMD3(x, 0.035 + radius * 0.7, z), SIMD3(repeating: radius), coat))
        }

        // The head resting on the brush at the front, and the muzzle laid along
        // it, back towards the rump.
        let head = SIMD3<Float>(0.14, 0.14, 0.09)
        root.addChildNode(blob(head, SIMD3(0.062, 0.052, 0.058), coat))
        let nose = SIMD3<Float>(0.06, 0.112, 0.172)
        root.addChildNode(cone(from: head + SIMD3(-0.02, -0.005, 0.02), to: nose,
                               radius: 0.034, tip: 0.01, coat))
        root.addChildNode(blob(nose, SIMD3(repeating: 0.01), paint.eye))

        // The ears, pricked even asleep, with the black backs a fox's have
        // painted on their tips.
        for (base, tip) in [(SIMD3<Float>(0.165, 0.172, 0.055), SIMD3<Float>(0.21, 0.25, 0.037)),
                            (SIMD3<Float>(0.152, 0.172, 0.122), SIMD3<Float>(0.19, 0.247, 0.15))] {
            root.addChildNode(cone(from: base, to: tip, radius: 0.028, coat))
            let from = base + (tip - base) * 0.62
            root.addChildNode(cone(from: from, to: tip + (tip - base) * 0.02,
                                   radius: 0.028 * 0.4 + 0.002, paint.eye))
        }

        // Its eyes, shut: two short dark strokes on the face, across the line
        // of the muzzle. A white fox with no face was a cushion.
        let muzzle = simd_normalize(nose - head)
        let across = simd_normalize(simd_cross(SIMD3<Float>(0, 1, 0), muzzle))
        for side: Float in [-1, 1] {
            let eye = head + muzzle * 0.05 + SIMD3(0, 0.026, 0) + across * side * 0.03
            root.addChildNode(limb(from: eye - across * 0.009 - muzzle * 0.003,
                                   to: eye + across * 0.009 + muzzle * 0.003,
                                   width: 0.0035, depth: 0.0035, paint.eye))
        }
        return root
    }

    /// A moth at rest with its wings held open, on the top of a thin stake — a
    /// moth set down on the ground is a moth nobody finds.
    static func moth(_ paint: Paint) -> SCNNode {
        let root = SCNNode()
        let coat = paint.luminous
        let top: Float = 0.31

        let stake = SCNCylinder(radius: 0.005, height: CGFloat(top))
        stake.materials = [paint.unlit(SIMD3(0.36, 0.30, 0.18), roughness: 0.8)]
        let post = SCNNode(geometry: stake)
        post.simdPosition = SIMD3(0, top / 2, -0.01)
        root.addChildNode(post)

        // Thorax, abdomen and head, nose to +z.
        root.addChildNode(blob(SIMD3(0, top + 0.012, 0.008), SIMD3(0.02, 0.018, 0.028), coat))
        root.addChildNode(blob(SIMD3(0, top + 0.006, -0.05), SIMD3(0.014, 0.013, 0.046), coat))
        root.addChildNode(blob(SIMD3(0, top + 0.014, 0.043), SIMD3(repeating: 0.014), coat))

        for side: Float in [-1, 1] {
            // Feathered feelers, flat and swept forward.
            root.addChildNode(limb(from: SIMD3(side * 0.008, top + 0.022, 0.05),
                                   to: SIMD3(side * 0.038, top + 0.045, 0.1),
                                   width: 0.009, depth: 0.0025, coat))
            root.addChildNode(blob(SIMD3(side * 0.012, top + 0.016, 0.053), SIMD3(repeating: 0.005), paint.eye))

            // The wings, raised a little from the body.
            let hinge = SCNNode()
            hinge.simdPosition = SIMD3(side * 0.014, top + 0.016, 0.0)
            hinge.eulerAngles.z = side * 0.2
            for wing in [forewing(side: side), hindwing(side: side)] {
                let shape = SCNShape(path: wing, extrusionDepth: 0.003)
                shape.chamferRadius = 0
                // Seen from underneath as often as from above, and one side's
                // path is the other's mirrored, so it winds the other way.
                let membrane = paint.luminous
                membrane.isDoubleSided = true
                shape.materials = [membrane]
                let node = SCNNode(geometry: shape)
                // A path is drawn in its own x and y and extruded along z; the
                // quarter-turn about x lays it flat, its y becoming the body's
                // forward.
                node.eulerAngles.x = .pi / 2
                hinge.addChildNode(node)
            }
            // An eyespot on each hindwing, painted on its upper face, which
            // after the quarter-turn is half the extrusion above the hinge.
            let spot = SCNCylinder(radius: 0.013, height: 0.001)
            spot.materials = [paint.unlit(SIMD3(0.36, 0.42, 0.44), roughness: 0.4)]
            let eyespot = SCNNode(geometry: spot)
            eyespot.simdPosition = SIMD3(side * 0.058, 0.0022, -0.045)
            hinge.addChildNode(eyespot)

            root.addChildNode(hinge)
        }
        return root
    }

    /// A forewing, from the root out: a long leading edge to a squared tip.
    private static func forewing(side: Float) -> UIBezierPath {
        let s = CGFloat(side)
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0.016))
        path.addCurve(to: CGPoint(x: s * 0.14, y: 0.036),
                      controlPoint1: CGPoint(x: s * 0.05, y: 0.04),
                      controlPoint2: CGPoint(x: s * 0.11, y: 0.046))
        path.addCurve(to: CGPoint(x: s * 0.105, y: -0.03),
                      controlPoint1: CGPoint(x: s * 0.152, y: 0.012),
                      controlPoint2: CGPoint(x: s * 0.13, y: -0.02))
        path.addCurve(to: CGPoint(x: 0, y: -0.012),
                      controlPoint1: CGPoint(x: s * 0.07, y: -0.04),
                      controlPoint2: CGPoint(x: s * 0.02, y: -0.02))
        path.close()
        path.flatness = 0.001
        return path
    }

    /// A hindwing: rounder, and trailing.
    private static func hindwing(side: Float) -> UIBezierPath {
        let s = CGFloat(side)
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: -0.004))
        path.addCurve(to: CGPoint(x: s * 0.095, y: -0.032),
                      controlPoint1: CGPoint(x: s * 0.04, y: -0.006),
                      controlPoint2: CGPoint(x: s * 0.09, y: -0.012))
        path.addCurve(to: CGPoint(x: s * 0.03, y: -0.085),
                      controlPoint1: CGPoint(x: s * 0.1, y: -0.06),
                      controlPoint2: CGPoint(x: s * 0.06, y: -0.088))
        path.addCurve(to: CGPoint(x: 0, y: -0.035),
                      controlPoint1: CGPoint(x: s * 0.008, y: -0.08),
                      controlPoint2: CGPoint(x: 0, y: -0.06))
        path.close()
        path.flatness = 0.001
        return path
    }

    /// The snail, feelers up, its shell coiled over its back. Faces +z.
    static func snail(_ paint: Paint) -> SCNNode {
        let root = SCNNode()
        let coat = paint.luminous

        // The foot, and the head raised off the front of it.
        root.addChildNode(blob(SIMD3(0, 0.018, 0.005), SIMD3(0.034, 0.02, 0.105), coat))
        root.addChildNode(limb(from: SIMD3(0, 0.022, 0.06), to: SIMD3(0, 0.055, 0.118),
                               width: 0.024, depth: 0.022, coat))

        for side: Float in [-1, 1] {
            let tip = SIMD3<Float>(side * 0.03, 0.125, 0.152)
            root.addChildNode(limb(from: SIMD3(side * 0.01, 0.066, 0.122), to: tip,
                                   width: 0.0055, depth: 0.0055, coat))
            root.addChildNode(blob(tip, SIMD3(repeating: 0.0085), paint.eye))
            root.addChildNode(limb(from: SIMD3(side * 0.012, 0.047, 0.132),
                                   to: SIMD3(side * 0.02, 0.036, 0.162),
                                   width: 0.0045, depth: 0.0045, coat))
        }

        // The shell: a tube coiled in on itself about a line across the back,
        // shrinking as it goes in and drifting to one side, the way a shell's
        // whorls stack. Its mouth is the largest bead, down on the foot.
        let centre = SIMD3<Float>(0, 0.085, -0.03)
        let beads = 90
        for bead in 0..<beads {
            let turn = Float(bead) / Float(beads - 1) * 4 * .pi
            let shrink = exp(-0.2 * turn)
            let radius: Float = 0.054 * shrink
            let point = SIMD3<Float>(
                0.022 * (1 - shrink),
                centre.y - radius * cos(turn),
                centre.z - radius * sin(turn)
            )
            root.addChildNode(blob(point, SIMD3(repeating: 0.034 * shrink + 0.002), coat))
        }
        return root
    }
}

// MARK: - Drawing one

/// A figure standing on the plot: lit by the garden at its hour, crossfaded the
/// way a plant is, with its glow added over it by how dark it is.
struct CreatureFigure: View {
    let kind: LampKind
    let glow: Double
    let pointsPerMetre: Double
    let hour: Double
    let turn: Int
    let seed: Int

    @State private var before: UIImage?
    @State private var after: UIImage?
    @State private var shine: UIImage?

    private var between: (before: Int, after: Int, blend: Double) {
        GardenGround.Light.steps(at: hour)
    }

    var body: some View {
        if let figure = GardenCreatures.figure(of: kind) {
            let side = figure.metres * pointsPerMetre
            let facing = GardenCreatures.facing(seed: seed)
            let colour = GardenLamps.swiftUIColour(figure.glow)

            ZStack {
                if let before {
                    FootShadow(image: before, side: side, lift: figure.lift, hour: hour, turn: turn)
                }
                if let before { Image(uiImage: before).resizable() }
                if let after { Image(uiImage: after).resizable().opacity(between.blend) }
                if let shine {
                    // The paint's own light, and a little of it spilling into
                    // the air round it — glow-in-the-dark paint is never quite
                    // contained by its edge.
                    //
                    // Squared, so that by day — when a lamp's glow is still a
                    // seventh — the paint is pale paint and not a light. At the
                    // lamps' own curve the hare shone at ten in the morning.
                    Image(uiImage: shine).resizable()
                        .blur(radius: max(1, 0.03 * pointsPerMetre))
                        .opacity(0.8 * glow * glow)
                        .blendMode(.plusLighter)
                    Image(uiImage: shine).resizable()
                        .opacity(glow * glow)
                        .blendMode(.plusLighter)
                }
            }
            .frame(width: side, height: side)
            // Down so the foot, which is `lift` up the picture, is on the
            // bottom edge of whatever holds it.
            .offset(y: figure.lift * side)
            .background(alignment: .bottom) {
                // A little of its own light on the ground under it.
                Ellipse()
                    .fill(EllipticalGradient(colors: [colour.opacity(0.3 * glow * glow), colour.opacity(0)],
                                             center: .center, startRadiusFraction: 0,
                                             endRadiusFraction: 0.5))
                    .frame(width: 0.5 * pointsPerMetre, height: 0.29 * pointsPerMetre)
                    .offset(y: 0.145 * pointsPerMetre)
                    .blendMode(.plusLighter)
            }
            .task(id: GardenCreatures.key(kind, step: between.before, turn: turn, facing: facing)) {
                before = GardenCreatures.shared.picture(kind, step: between.before, turn: turn, facing: facing)
            }
            .task(id: GardenCreatures.key(kind, step: between.after, turn: turn, facing: facing)) {
                after = GardenCreatures.shared.picture(kind, step: between.after, turn: turn, facing: facing)
            }
            .task(id: GardenCreatures.key(kind, step: nil, turn: turn, facing: facing)) {
                shine = GardenCreatures.shared.picture(kind, step: nil, turn: turn, facing: facing)
            }
        }
    }
}
