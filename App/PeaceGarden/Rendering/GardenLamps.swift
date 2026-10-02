import SceneKit
import SeedCore
import simd
import SwiftUI

/// The lights somebody puts out in the garden: what each one looks like, how far
/// its light reaches, and what it does to the plants standing in it.
///
/// **A pool on the ground and a lift on the plants, not a light in their
/// renders.** Settled 18 September. Lighting a plant's leaves from the lantern's
/// side would mean re-rendering every plant near a lantern at eight hours and four
/// turns every time the lantern moved. Instead the ground under a light gets a
/// warm pool, and a plant standing in it is drawn again over itself, tinted by
/// the light and added — which brightens it in proportion to its own colour, the
/// way light does, so a white petal comes up more than a dark leaf. It is the
/// vocabulary the garden already has: `GardenVisits` announces a plant with a
/// pool of light, and `StageBackdrop` has stood a plant in one since August.
enum GardenLamps {

    // MARK: How much they show

    /// How strongly the lights glow, from how dark it is.
    ///
    /// The same curve the galaxy follows, so the lamps come up exactly as the
    /// garden goes down. Never nothing: a lantern in daylight is still a lantern,
    /// and a light that vanished at noon would be a light nobody could find to
    /// move.
    static func glow(in light: GardenGround.Light) -> Double {
        0.14 + 0.86 * min(1, max(0, 1 - light.strength / 0.5))
    }

    // MARK: Each kind

    /// The colour a light casts. Lights are allowed to be saturated — they are
    /// not chrome, and a lantern's warmth is what it is for.
    static func colour(of kind: LampKind) -> SIMD3<Double> {
        switch kind {
        case .lantern: return SIMD3(1.00, 0.74, 0.40)
        case .paperLamp: return SIMD3(1.00, 0.55, 0.32)
        case .fireflies: return SIMD3(0.80, 1.00, 0.48)
        case .hare, .fox, .moth, .snail:
            return GardenCreatures.figure(of: kind)?.glow ?? SIMD3(repeating: 1)
        }
    }

    /// How far a light's light goes, in metres, before it is nothing.
    static func reach(of kind: LampKind) -> Double {
        switch kind {
        case .lantern: return 1.5
        case .paperLamp: return 1.35
        case .fireflies: return 0.95
        case .hare, .fox: return 0.7
        case .moth: return 0.6
        case .snail: return 0.45
        }
    }

    /// How much of a pool a light casts on the ground, against a lantern's.
    ///
    /// A drift of fireflies is a handful of very small lights: close by a
    /// flower they are enough to see it by, and they do not paint the ground the
    /// way a lamp does. At a lantern's strength they came out as a green
    /// spotlight on the grass.
    static func pool(of kind: LampKind) -> Double {
        switch kind {
        case .lantern: return 1.0
        case .paperLamp: return 0.85
        case .fireflies: return 0.28
        // Paint that has held the day's light gives back very little of it: a
        // figure is enough to see a flower beside it by, and no more.
        case .hare, .fox: return 0.3
        case .moth: return 0.24
        case .snail: return 0.18
        }
    }

    /// Where the light itself is, in metres above the ground it stands on.
    static func height(of kind: LampKind) -> Double {
        switch kind {
        case .lantern: return 0.25
        case .paperLamp: return 0.86
        case .fireflies: return 0.45
        case .hare: return 0.22
        case .fox: return 0.09
        case .moth: return 0.32
        case .snail: return 0.07
        }
    }

    /// How far to the right of its foot the light hangs, in metres: the paper
    /// lamp, from the end of its cane. The rest are over their foot.
    static func hangs(of kind: LampKind) -> Double {
        kind == .paperLamp ? 0.165 : 0
    }

    /// The halo in the air round the light itself: its radius in metres, and
    /// how bright its middle is.
    ///
    /// A figure's is small and faint. Glow-in-the-dark paint lights the air
    /// round it hardly at all, and a lantern's metre-wide halo round a snail
    /// read as a snail with a lantern in it.
    static func halo(of kind: LampKind) -> (radius: Double, strength: Double) {
        switch kind {
        case .lantern, .paperLamp, .fireflies: return (0.42, 0.55)
        case .hare, .fox, .moth: return (0.22, 0.22)
        case .snail: return (0.12, 0.22)
        }
    }

    /// The part of a light that answers a finger, in metres: across it, and up
    /// from its foot.
    static func grip(of kind: LampKind) -> (width: Double, height: Double) {
        switch kind {
        case .lantern, .paperLamp, .fireflies: return (0.32, height(of: kind) + 0.14)
        case .hare: return (0.3, 0.5)
        case .fox: return (0.42, 0.24)
        case .moth: return (0.3, 0.4)
        case .snail: return (0.24, 0.18)
        }
    }

    // MARK: What it does to a plant

    /// How much a plant standing at `spot` is lifted by the lights, and in what
    /// colour.
    ///
    /// Falls off with the square of the distance through the reach, so a plant
    /// at a lantern's foot is lit and one at the edge of its reach is barely
    /// touched — a linear fall-off lit a whole bed evenly, which reads as the
    /// garden being brighter rather than as a lantern standing in it.
    ///
    /// **A larger light reaches further and lifts a little more.** Its reach
    /// grows with its size, as its pool on the ground does, so the plants it
    /// lifts are the ones standing in the pool somebody can see. Its strength
    /// grows only with the square root of its size: a lantern made half as large
    /// again is a larger lantern, not a brighter flame, and a light at its
    /// largest lifting a quarter more is enough to see the difference by. A
    /// light at its own size has no scale stored and draws exactly as before.
    static func lift(at spot: Spot, from lamps: [Lamp]) -> (amount: Double, colour: SIMD3<Double>) {
        var amount = 0.0
        var colour = SIMD3<Double>(repeating: 0)

        for lamp in lamps {
            guard let kind = lamp.known else { continue }
            let size = lamp.drawnScale
            let apart = hypot(spot.x - lamp.spot.x, spot.z - lamp.spot.z)
            let near = max(0, 1 - apart / (reach(of: kind) * size))
            let weight = near * near * size.squareRoot()
            amount += weight
            colour += self.colour(of: kind) * weight
        }

        guard amount > 0 else { return (0, SIMD3(repeating: 1)) }
        return (min(amount, 1), colour / amount)
    }

    static func swiftUIColour(_ rgb: SIMD3<Double>) -> Color {
        Color(red: rgb.x, green: rgb.y, blue: rgb.z)
    }
}

// MARK: - Drawing them

/// One light, drawn standing at its foot, with its own halo.
///
/// Drawn in metres like everything else on the plot, so a lantern is the size of
/// a lantern beside a plant that is the size it grew to.
struct LampFigure: View {
    let kind: LampKind
    let glow: Double
    let pointsPerMetre: Double
    /// A seed for anything that should differ between two lights of one kind —
    /// the fireflies, so two drifts do not move in step, and the figures, so two
    /// hares do not face the same way.
    let seed: Int
    /// The hour and the plot's turn, which everything modelled needs: the
    /// figures, the lantern and the paper lamp are lit by the garden as well as
    /// by themselves. Fireflies are only their own light.
    var hour: Double = 12
    var turn: Int = 0
    /// The season, which colours the garden's light on what is modelled.
    var season: Season = .orbit

    var body: some View {
        let colour = GardenLamps.swiftUIColour(GardenLamps.colour(of: kind))
        let metre = pointsPerMetre
        let lightAt = GardenLamps.height(of: kind) * metre

        let halo = GardenLamps.halo(of: kind)

        ZStack(alignment: .bottom) {
            // The halo round the light itself, added rather than laid over, so
            // it brightens what is behind it instead of fogging it.
            Circle()
                .fill(RadialGradient(
                    colors: [colour.opacity(halo.strength * glow), colour.opacity(0)],
                    center: .center, startRadius: 0, endRadius: halo.radius * metre
                ))
                .frame(width: 2 * halo.radius * metre, height: 2 * halo.radius * metre)
                .offset(x: GardenLamps.hangs(of: kind) * metre, y: -lightAt + halo.radius * metre)
                .blendMode(.plusLighter)

            switch kind {
            case .fireflies: Fireflies(colour: colour, glow: glow, metre: metre, seed: seed)
            case .lantern, .paperLamp, .hare, .fox, .moth, .snail:
                ModelledFigure(kind: kind, glow: glow, pointsPerMetre: metre,
                               hour: hour, turn: turn, seed: seed, season: season)
            }
        }
        .frame(width: 1.0 * metre, height: 1.2 * metre, alignment: .bottom)
    }
}

/// A drift of fireflies: a light that moves.
///
/// Each one wanders on its own slow loop about the drift's middle and blinks on
/// its own clock, from phases dealt once from the seed so the same drift moves
/// the same way every time it is looked at. They blink more than they glow —
/// a steady firefly is a lamp with no body.
private struct Fireflies: View {
    let colour: Color
    let glow: Double
    let metre: Double
    let seed: Int

    private static let count = 8

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let middle = CGPoint(x: size.width / 2,
                                     y: size.height - GardenLamps.height(of: .fireflies) * metre)
                for index in 0..<Self.count {
                    let phase = GardenGround.grain(seed, index, 3) * 2 * .pi
                    let speed = 0.25 + GardenGround.grain(seed, index, 4) * 0.35
                    let wander = 0.10 + GardenGround.grain(seed, index, 5) * 0.22

                    let x = middle.x + cos(time * speed + phase) * wander * metre
                    let y = middle.y + sin(time * speed * 1.3 + phase * 0.7) * wander * 0.7 * metre
                    let blink = max(0, sin(time * (1.1 + speed) + phase * 3))
                    let alpha = (0.25 + 0.75 * blink) * (0.3 + 0.7 * glow)

                    let halo = 5.0 * blink + 2
                    context.fill(
                        Path(ellipseIn: CGRect(x: x - halo, y: y - halo, width: halo * 2, height: halo * 2)),
                        with: .radialGradient(
                            Gradient(colors: [colour.opacity(alpha * 0.5), colour.opacity(0)]),
                            center: CGPoint(x: x, y: y), startRadius: 0, endRadius: halo
                        )
                    )
                    context.fill(
                        Path(ellipseIn: CGRect(x: x - 1.1, y: y - 1.1, width: 2.2, height: 2.2)),
                        with: .color(colour.opacity(alpha))
                    )
                }
            }
        }
        .frame(width: 1.0 * metre, height: 1.2 * metre)
    }
}

// MARK: - Modelling them

/// The lantern and the paper lamp, modelled and taken the way the figures are.
///
/// **They were drawn, and beside everything else they were clip art.** A
/// triangle for a cap, a rounded rectangle filled with the light and ruled
/// round in near-black, a stroked curve for a cane: flat shapes with outlines,
/// in a garden where every plant, hedge and hare is a solid lit by the hour. So
/// they are solids too, turned and swept (`FigureGeometry`) and photographed by
/// the plants' own camera under the plants' own light, at the same eight
/// points round the clock and four turns of the plot.
///
/// **Their own light is the second picture.** The figures' glow picture is
/// paint shining; a lamp's is the flame: the glass or the paper lit from
/// inside, and — for the lantern — the iron round it catching that light on its
/// inner edges and the underside of its cap. Added over the garden's picture,
/// on the lamps' own curve, it is the same light the pool on the ground and
/// the lift on the plants are.
extension GardenCreatures {

    /// Iron, painted dark and weathered, not black: by day it has to show its
    /// shape, and a black lantern was a hole in the garden with a light in it.
    /// In the flame's picture all that lights it is the flame, and it is matte
    /// there: a physically based surface a few centimetres from a point light
    /// burnt the lantern's tray to a white ring at any strength of flame.
    static func iron(_ paint: Paint) -> SCNMaterial {
        let material = SCNMaterial()
        if paint.glowing {
            material.lightingModel = .lambert
            material.diffuse.contents = UIColor(white: 0.3, alpha: 1)
        } else {
            material.lightingModel = .physicallyBased
            material.diffuse.contents = UIColor(red: 0.27, green: 0.27, blue: 0.28, alpha: 1)
            material.roughness.contents = NSNumber(value: 0.4)
            material.metalness.contents = NSNumber(value: 0.3)
        }
        return material
    }

    /// What a flame shines through — glass, or paper. By day it is the
    /// material, lit by the garden; in the flame's picture it is the light
    /// coming through it, in the lamp's colour, shaded by the `tint` its
    /// geometry carries.
    static func lit(_ paint: Paint, day: SIMD3<Double>, roughness: Double) -> SCNMaterial {
        let material = SCNMaterial()
        if paint.glowing {
            material.lightingModel = .constant
            material.diffuse.contents = Paint.colour(paint.glow * 0.72)
        } else {
            material.lightingModel = .physicallyBased
            material.diffuse.contents = Paint.colour(day)
            material.roughness.contents = NSNumber(value: roughness)
            material.metalness.contents = NSNumber(value: 0)
        }
        return material
    }

    private static func solid(_ geometry: SCNGeometry, _ material: SCNMaterial) -> SCNNode {
        geometry.materials = [material]
        return SCNNode(geometry: geometry)
    }

    /// A small iron lantern on a short post: four panes of frosted glass in a
    /// rounded frame, under a cap with a flared eave and a finial. Its glass
    /// is where `GardenLamps.height` says the light is.
    static func lantern(_ paint: Paint) -> SCNNode {
        let root = SCNNode()
        let iron = iron(paint)
        let square = FigureGeometry.roundedSquare(4.5)

        // The post, swelling to a foot and a collar.
        root.addChildNode(solid(FigureGeometry.lathe([
            SIMD2(0, 0), SIMD2(0.03, 0.001), SIMD2(0.029, 0.008), SIMD2(0.017, 0.022),
            SIMD2(0.0125, 0.05), SIMD2(0.0115, 0.12), SIMD2(0.013, 0.162),
            SIMD2(0.02, 0.172), SIMD2(0.012, 0.18), SIMD2(0, 0.181),
        ], rows: 48, around: 28), iron))

        // The tray the glass stands in.
        root.addChildNode(solid(FigureGeometry.lathe([
            SIMD2(0, 0.172), SIMD2(0.035, 0.173), SIMD2(0.055, 0.178), SIMD2(0.058, 0.186),
            SIMD2(0.05, 0.192), SIMD2(0, 0.193),
        ], rows: 20, section: square), iron))

        // The glass, barrelled a little, brightest at the flame's height.
        let flame: Float = 0.245
        let glass = lit(paint, day: SIMD3(0.80, 0.68, 0.48), roughness: 0.2)
        root.addChildNode(solid(FigureGeometry.lathe([
            SIMD2(0, 0.188), SIMD2(0.041, 0.19), SIMD2(0.0445, 0.245), SIMD2(0.041, 0.302),
            SIMD2(0, 0.304),
        ], rows: 30, section: square, tint: paint.glowing ? { height in
            let off = abs(height - flame) / 0.06
            return 0.55 + 0.45 * max(0, 1 - off * off)
        } : nil), glass))

        // The frame: a bar up each corner, bowed out with the glass.
        for corner in 0..<4 {
            let angle = Float.pi / 4 + Float(corner) * .pi / 2
            let out = SIMD3<Float>(sin(angle), 0, cos(angle)) * square(angle)
            root.addChildNode(solid(FigureGeometry.sweep(
                through: [out * 0.043 + SIMD3(0, 0.186, 0), out * 0.0475 + SIMD3(0, 0.245, 0),
                          out * 0.043 + SIMD3(0, 0.306, 0)],
                rows: 16, around: 12
            ) { _ in SIMD2(repeating: 0.0042) }, iron))
        }

        // The cap: a band over the glass, then a flared eave sweeping up to the
        // finial, with a lip turned down at its edge.
        root.addChildNode(solid(FigureGeometry.lathe([
            SIMD2(0, 0.298), SIMD2(0.05, 0.3), SIMD2(0.055, 0.304), SIMD2(0.068, 0.305),
            SIMD2(0.074, 0.309), SIMD2(0.068, 0.314), SIMD2(0.05, 0.322), SIMD2(0.032, 0.334),
            SIMD2(0.017, 0.348), SIMD2(0.011, 0.36), SIMD2(0.012, 0.366), SIMD2(0.005, 0.369),
            SIMD2(0, 0.37),
        ], rows: 64, section: FigureGeometry.roundedSquare(3.2)), iron))
        root.addChildNode(solid(FigureGeometry.lathe([
            SIMD2(0, 0.366), SIMD2(0.008, 0.369), SIMD2(0.0095, 0.375), SIMD2(0.006, 0.382),
            SIMD2(0.002, 0.388), SIMD2(0, 0.39),
        ], rows: 20, around: 24), iron))

        // The flame, which lights nothing but the lantern itself, and only in
        // its own picture.
        if paint.glowing {
            let light = SCNNode()
            light.light = SCNLight()
            light.light?.type = .omni
            light.light?.color = Paint.colour(paint.glow)
            light.light?.intensity = 1600
            light.light?.attenuationStartDistance = 0.02
            light.light?.attenuationEndDistance = 0.1
            light.simdPosition = SIMD3(0, flame, 0)
            root.addChildNode(light)
        }
        return root
    }

    /// A paper lamp hung from the tip of a bent bamboo cane. The cane rises
    /// from the foot and bows over at the top, and the lamp hangs from it to
    /// the right, its middle where `GardenLamps.height` says the light is and
    /// as far out as `GardenLamps.hangs` says.
    static func paperLamp(_ paint: Paint) -> SCNNode {
        let root = SCNNode()
        let out = Float(GardenLamps.hangs(of: .paperLamp))
        let middle = Float(GardenLamps.height(of: .paperLamp))
        let cane = paint.unlit(SIMD3(0.50, 0.42, 0.25), roughness: 0.55)

        // The cane, a little thicker at the foot, with the knuckles bamboo has
        // every so often along it, and a rounded end.
        root.addChildNode(solid(FigureGeometry.sweep(
            through: [SIMD3(0, -0.01, 0), SIMD3(-0.01, 0.34, 0.004), SIMD3(-0.004, 0.68, -0.004),
                      SIMD3(0.035, 0.92, 0), SIMD3(0.1, 0.99, 0), SIMD3(out - 0.008, 0.993, 0),
                      SIMD3(out + 0.006, 0.982, 0)],
            rows: 120, around: 14
        ) { t in
            let knuckle = pow(max(0, cos(t * 7 * 2 * .pi)), 40)
            let end = sqrt(max(0, 1 - pow(max(0, t - 0.985) / 0.015, 2)))
            return SIMD2(repeating: (0.0075 - 0.0025 * t) * (1 + 0.22 * knuckle) * end)
        }, cane))

        // The cord it hangs by.
        let top = middle + 0.095
        root.addChildNode(solid(FigureGeometry.sweep(
            through: [SIMD3(out, 0.99, 0), SIMD3(out, top, 0)], rows: 4, around: 8
        ) { _ in SIMD2(repeating: 0.0016) }, paint.eye))

        // The lamp: a round paper lamp on hoops, pinched in a little at each
        // hoop, so the paper bellies between them.
        let hoops: Float = 9
        var profile: [SIMD2<Float>] = [SIMD2(0, middle - 0.095)]
        for step in 1..<72 {
            let y = Float(step) / 72 * 2 - 1
            let round = pow(max(0, 1 - y * y), 0.62)
            let hoop = pow(abs(cos((y + 1) / 2 * hoops * .pi)), 10)
            profile.append(SIMD2(0.08 * round * (1 - 0.035 * hoop) + 0.012 * (1 - round),
                                 middle + 0.095 * y))
        }
        profile.append(SIMD2(0, middle + 0.095))
        let paper = lit(paint, day: SIMD3(0.96, 0.9, 0.78), roughness: 0.85)
        let lamp = solid(FigureGeometry.lathe(profile, rows: 96, around: 40,
                                              tint: paint.glowing ? { height in
            let y = (height - middle) / 0.095
            let hoop = pow(abs(cos((y + 1) / 2 * hoops * .pi)), 10)
            return (0.5 + 0.5 * pow(max(0, 1 - y * y), 0.7)) * (1 - 0.3 * hoop)
        } : nil), paper)
        lamp.simdPosition = SIMD3(out, 0, 0)
        root.addChildNode(lamp)

        // The rims top and bottom, which the paper is gathered on.
        for (y, radius) in [(middle + 0.092, Float(0.03)), (middle - 0.092, Float(0.036))] {
            let rim = solid(FigureGeometry.lathe([
                SIMD2(0, y - 0.006), SIMD2(radius, y - 0.005), SIMD2(radius + 0.003, y),
                SIMD2(radius, y + 0.005), SIMD2(0, y + 0.006),
            ], rows: 12, around: 32), cane)
            rim.simdPosition = SIMD3(out, 0, 0)
            root.addChildNode(rim)
        }
        return root
    }
}
