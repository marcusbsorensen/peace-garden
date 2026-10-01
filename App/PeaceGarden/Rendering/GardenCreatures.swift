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
///
/// The lantern and the paper lamp are taken here too, by the same camera and
/// cache, with a flame where the figures have paint: see `GardenLamps.swift`.
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

    /// The animals, painted. The lantern and the paper lamp are modelled and
    /// taken the same way, but they are lights with a flame in them rather than
    /// paint, and are shown at full strength in the row.
    nonisolated static func isCreature(_ kind: LampKind) -> Bool {
        switch kind {
        case .hare, .fox, .moth, .snail: return true
        case .lantern, .paperLamp, .fireflies: return false
        }
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
        /// Whether its own light is paint or a flame. Paint comes up by the
        /// square of the lamps' glow, a flame by the glow itself.
        var flame = false
        /// Whether it is drawn with a shadow sheared from its own picture.
        ///
        /// **Only what stands up off a foot, the way a plant does.** The shear
        /// reads every pixel as height above the foot. For a stem, a stake or a
        /// post that is true. For a figure lying along the ground most of the
        /// picture is ground it covers, and the shear threw that forward as a
        /// dark copy of the body under it — the shadow under the hare that
        /// should not have been there. The hare's long feet and haunch, the
        /// fox and the snail are all footprint; the moth's stake and the
        /// lights' posts are not.
        var shadow = false
    }

    nonisolated static func figure(of kind: LampKind) -> Figure? {
        switch kind {
        case .hare: return Figure(metres: 0.80, lift: 0.20, glow: SIMD3(0.55, 1.00, 0.62))
        case .fox: return Figure(metres: 0.66, lift: 0.33, glow: SIMD3(0.45, 0.95, 0.88))
        case .moth: return Figure(metres: 0.60, lift: 0.20, glow: SIMD3(0.64, 0.86, 1.00), shadow: true)
        case .snail: return Figure(metres: 0.44, lift: 0.26, glow: SIMD3(0.80, 1.00, 0.46))
        case .lantern:
            return Figure(metres: 0.50, lift: 0.08, glow: GardenLamps.colour(of: kind),
                          flame: true, shadow: true)
        case .paperLamp:
            return Figure(metres: 1.10, lift: 0.04, glow: GardenLamps.colour(of: kind),
                          flame: true, shadow: true)
        case .fireflies: return nil
        }
    }

    /// How far round a figure is turned on the plot, in radians.
    ///
    /// Turned with the plot, as a plant is, so its near side stays its near
    /// side and the sun stays where the sun is. Except the paper lamp, which
    /// always hangs to the right of its cane: its halo is drawn in the plot,
    /// round where the paper is, and has to know where that is without asking
    /// the picture.
    nonisolated static func turn(of kind: LampKind, facing: Int, quarter: Int) -> Float {
        switch kind {
        // Its arm is along +x, and +x a quarter of the way round from the
        // camera's right is the screen's right.
        case .paperLamp: return .pi / 4
        default: return Float(facing) * .pi / 4 + Float(quarter) * .pi / 2
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

    /// A picture already taken, without taking it: what a figure starts from
    /// when it is drawn again, so a plot redrawn does not flash its figures
    /// empty for a frame while the same pictures are fetched.
    func held(_ kind: LampKind, step: Int?, turn: Int, facing: Int) -> UIImage? {
        cache.object(forKey: Self.key(kind, step: step, turn: turn, facing: facing) as NSString)
    }

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
        } ?? (figure.flame ? SCNScene() : Self.glowScene())
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
        case .lantern: body = Self.lantern(paint)
        case .paperLamp: body = Self.paperLamp(paint)
        case .fireflies: return nil
        }

        let pivot = SCNNode()
        pivot.eulerAngles.y = Self.turn(of: kind, facing: facing, quarter: quarter)
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
        var luminous: SCNMaterial { luminous(SIMD3(0.83, 0.87, 0.74)) }

        /// Luminous paint tinted by day, and giving back `strength` of the
        /// glow. A pigment that colours the paint also holds less light, so the
        /// fox's russet glows dimmer than its white — which is what keeps its
        /// face and the tip of its brush apart from the rest of it after dark.
        func luminous(_ day: SIMD3<Double>, strength: Double = 1) -> SCNMaterial {
            let material = SCNMaterial()
            if glowing {
                material.lightingModel = .lambert
                material.diffuse.contents = Self.colour(glow * 0.35 * strength)
                material.emission.contents = Self.colour(glow * 0.62 * strength)
            } else {
                material.lightingModel = .physicallyBased
                material.diffuse.contents = Self.colour(day)
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

    /// The fox, curled asleep: its back to the world, its brush wrapped round
    /// the front of it and its chin laid on the brush, the white tip of the
    /// brush by its nose.
    ///
    /// **Two paints, and smooth.** It was one pale paint and a brush of
    /// twenty-six beads, and by day it was a caterpillar; at night it was one
    /// cyan cushion. A fox is told by three things before anything else — its
    /// ears, its muzzle and the white end of its brush — so those are what
    /// is modelled with care, and the paint is two: a russet-pale coat, and a
    /// whiter paint on the cheeks, the chin and the brush's tip, which also
    /// holds more of the light. The ear backs, the nose and the shut eyes are
    /// dark, and dark in the glow too. The body and the brush are each one
    /// swept surface (`FigureGeometry`), so each takes the light as one thing.
    static func fox(_ paint: Paint) -> SCNNode {
        let root = SCNNode()
        let coat = paint.luminous(SIMD3(0.90, 0.69, 0.50), strength: 0.66)
        let brushCoat = paint.luminous(SIMD3(0.86, 0.62, 0.43), strength: 0.52)
        let white = paint.luminous(SIMD3(0.93, 0.92, 0.86), strength: 1.05)
        let dark = paint.unlit(SIMD3(0.13, 0.10, 0.09), roughness: 0.45)

        func surface(_ geometry: SCNGeometry, _ material: SCNMaterial) -> SCNNode {
            geometry.materials = [material]
            return SCNNode(geometry: geometry)
        }

        // The body: one curve from the rump round the back to the shoulders,
        // lying low so the head can be seen resting above it. Thickest at the
        // haunch, closed in a dome at the rump, and narrowing at the far end
        // into a neck that runs up inside the head.
        let spine: [SIMD3<Float>] = [
            SIMD3(-0.06, 0.07, 0.07), SIMD3(-0.11, 0.074, 0.0),
            SIMD3(-0.07, 0.078, -0.07), SIMD3(0.02, 0.078, -0.085),
            SIMD3(0.08, 0.082, -0.035), SIMD3(0.075, 0.1, 0.035),
        ]
        root.addChildNode(surface(FigureGeometry.sweep(through: spine) { t in
            let run = min(1, t / 0.16, (1 - t) / 0.08)
            let dome = sqrt(max(0, run * (2 - run)))
            let girth: Float = 1 - 0.45 * t * t
            return SIMD2(0.09 * girth, 0.075 * girth) * dome
        }, coat))

        // The hind legs, folded up in the hollow of the coil under the head.
        root.addChildNode(blob(SIMD3(-0.015, 0.055, 0.045), SIMD3(0.075, 0.05, 0.06), coat, yaw: 0.5))

        // The brush, from under the rump round the front to lie across the
        // paws, full past its middle and closing to a soft point. The last
        // fifth of it is the white tip.
        let brush: [SIMD3<Float>] = [
            SIMD3(-0.085, 0.055, 0.035), SIMD3(-0.14, 0.052, 0.085),
            SIMD3(-0.085, 0.054, 0.15), SIMD3(0.0, 0.052, 0.165),
            SIMD3(0.085, 0.048, 0.135), SIMD3(0.13, 0.042, 0.07),
        ]
        let brushSize: (Float) -> SIMD2<Float> = { t in
            let full = 0.03 + 0.032 * sin(Float.pi * min(1, pow(t, 0.8) * 1.08))
            let end = sqrt(max(0, 1 - pow(max(0, t - 0.82) / 0.18, 2)))
            let radius = max(0.012, full) * end
            return SIMD2(radius, radius * 0.86)
        }
        root.addChildNode(surface(FigureGeometry.sweep(through: brush, to: 0.8, rows: 48,
                                                       size: brushSize), brushCoat))
        root.addChildNode(surface(FigureGeometry.sweep(through: brush, from: 0.8, rows: 16,
                                                       size: brushSize), white))

        // The head, laid on the brush in the hollow of the coil with its muzzle
        // running along the brush towards the tip.
        let head = SIMD3<Float>(0.06, 0.128, 0.07)
        let muzzle = simd_normalize(SIMD3<Float>(0.62, -0.34, 0.72))
        let across = simd_normalize(simd_cross(SIMD3<Float>(0, 1, 0), muzzle))
        let up = simd_normalize(simd_cross(muzzle, across))
        let along = simd_quatf(from: SIMD3(0, 0, 1), to: muzzle)
        let skull = blob(head, SIMD3(0.056, 0.048, 0.06), coat)
        skull.simdOrientation = along
        root.addChildNode(skull)

        // The muzzle: long, fine, and tapering to the nose — the line that most
        // says fox rather than cat or dog.
        let nose = head + muzzle * 0.105 - up * 0.012
        root.addChildNode(surface(FigureGeometry.sweep(
            through: [head + muzzle * 0.01 + up * 0.006, head + muzzle * 0.06 - up * 0.004, nose],
            rows: 20, around: 24, reference: up
        ) { t in
            let radius = 0.034 - 0.024 * t
            return SIMD2(radius, radius * 0.8)
        }, coat))
        // White under it, from the cheeks to the chin.
        for side: Float in [-1, 1] {
            let cheek = blob(head + muzzle * 0.03 - up * 0.02 + across * side * 0.028,
                             SIMD3(0.024, 0.02, 0.036), white)
            cheek.simdOrientation = along
            root.addChildNode(cheek)
        }
        let chin = blob(head + muzzle * 0.06 - up * 0.024, SIMD3(0.02, 0.012, 0.04), white)
        chin.simdOrientation = along
        root.addChildNode(chin)
        root.addChildNode(blob(nose + muzzle * 0.004, SIMD3(0.011, 0.009, 0.01), paint.eye))

        // The ears: big, pointed and upright even asleep, laid back a little
        // and turned out, each a blade swept from base to point. Turned out so
        // that from any side one of them shows its face: side-on, an ear seen
        // edge-on was a black spike. Behind each is the
        // top of the same blade again in dark, a hair further back, for the
        // black backs a fox's ears have — pale from the front, dark from
        // behind.
        for side: Float in [-1, 1] {
            let base = head - muzzle * 0.02 + up * 0.03 + across * side * 0.03
            let tip = base + up * 0.075 - muzzle * 0.03 + across * side * 0.018
            let middle = (base + tip) / 2 + muzzle * 0.006
            let ear: (Float, Float) -> SCNGeometry = { scale, from in
                FigureGeometry.sweep(through: [base, middle, tip], from: from, rows: 16, around: 20,
                                     reference: simd_normalize(muzzle - across * side * 0.6)) { t in
                    let width = 0.033 * scale * (1 - t) * (0.8 + 0.2 * (1 - t))
                    return SIMD2(width, 0.009 * scale * (1 - t * 0.7))
                }
            }
            root.addChildNode(surface(ear(1, 0), coat))
            let back = surface(ear(1.03, 0.3), dark)
            back.simdPosition = -muzzle * 0.004
            root.addChildNode(back)
        }

        // Its eyes, shut: two short dark strokes slanting up the face, as a
        // fox's eyes slant.
        for side: Float in [-1, 1] {
            let eye = head + muzzle * 0.045 + up * 0.022 + across * side * 0.026
            let slant = simd_normalize(across * side * 0.8 - muzzle * 0.45 + up * 0.25)
            root.addChildNode(limb(from: eye - slant * 0.011, to: eye + slant * 0.011,
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

/// A modelled figure or light standing on the plot: lit by the garden at its
/// hour, crossfaded the way a plant is, with its own light added over it by how
/// dark it is.
struct ModelledFigure: View {
    let kind: LampKind
    let glow: Double
    let pointsPerMetre: Double
    let hour: Double
    let turn: Int
    let seed: Int

    @State private var before: UIImage?
    @State private var after: UIImage?
    @State private var shine: UIImage?

    init(kind: LampKind, glow: Double, pointsPerMetre: Double, hour: Double, turn: Int, seed: Int) {
        self.kind = kind
        self.glow = glow
        self.pointsPerMetre = pointsPerMetre
        self.hour = hour
        self.turn = turn
        self.seed = seed
        let facing = GardenCreatures.facing(seed: seed)
        let between = GardenGround.Light.steps(at: hour)
        let held = GardenCreatures.shared
        _before = State(initialValue: held.held(kind, step: between.before, turn: turn, facing: facing))
        _after = State(initialValue: held.held(kind, step: between.after, turn: turn, facing: facing))
        _shine = State(initialValue: held.held(kind, step: nil, turn: turn, facing: facing))
    }

    private var between: (before: Int, after: Int, blend: Double) {
        GardenGround.Light.steps(at: hour)
    }

    var body: some View {
        if let figure = GardenCreatures.figure(of: kind) {
            let side = figure.metres * pointsPerMetre
            let facing = GardenCreatures.facing(seed: seed)
            let colour = GardenLamps.swiftUIColour(figure.glow)
            // Squared for paint, so that by day — when a lamp's glow is still
            // a seventh — the paint is pale paint and not a light. At the
            // lamps' own curve the hare shone at ten in the morning. A flame
            // is a lamp, and comes up on the lamps' curve.
            let shown = figure.flame ? glow : glow * glow

            ZStack {
                if figure.shadow, let before {
                    FootShadow(image: before, side: side, lift: figure.lift, hour: hour, turn: turn)
                }
                if let before { Image(uiImage: before).resizable() }
                if let after { Image(uiImage: after).resizable().opacity(between.blend) }
                if let shine {
                    // Its own light, and a little of it spilling into the air
                    // round it — glow-in-the-dark paint is never quite
                    // contained by its edge, and nor is a lit pane.
                    Image(uiImage: shine).resizable()
                        .blur(radius: max(1, 0.03 * pointsPerMetre))
                        .opacity(0.8 * shown)
                        .blendMode(.plusLighter)
                    Image(uiImage: shine).resizable()
                        .opacity(shown)
                        .blendMode(.plusLighter)
                }
            }
            .frame(width: side, height: side)
            // Down so the foot, which is `lift` up the picture, is on the
            // bottom edge of whatever holds it.
            .offset(y: figure.lift * side)
            .background(alignment: .bottom) {
                // A little of its own light on the ground under it. A lamp has
                // its pool laid by the plot already.
                if !figure.flame {
                    Ellipse()
                        .fill(EllipticalGradient(colors: [colour.opacity(0.3 * shown), colour.opacity(0)],
                                                 center: .center, startRadiusFraction: 0,
                                                 endRadiusFraction: 0.5))
                        .frame(width: 0.5 * pointsPerMetre, height: 0.29 * pointsPerMetre)
                        .offset(y: 0.145 * pointsPerMetre)
                        .blendMode(.plusLighter)
                }
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
