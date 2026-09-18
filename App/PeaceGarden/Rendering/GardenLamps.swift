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
        }
    }

    /// How far a light's light goes, in metres, before it is nothing.
    static func reach(of kind: LampKind) -> Double {
        switch kind {
        case .lantern: return 1.5
        case .paperLamp: return 1.35
        case .fireflies: return 0.95
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
        }
    }

    /// Where the light itself is, in metres above the ground it stands on.
    static func height(of kind: LampKind) -> Double {
        switch kind {
        case .lantern: return 0.30
        case .paperLamp: return 0.86
        case .fireflies: return 0.45
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
    static func lift(at spot: Spot, from lamps: [Lamp]) -> (amount: Double, colour: SIMD3<Double>) {
        var amount = 0.0
        var colour = SIMD3<Double>(repeating: 0)

        for lamp in lamps {
            guard let kind = lamp.known else { continue }
            let apart = hypot(spot.x - lamp.spot.x, spot.z - lamp.spot.z)
            let near = max(0, 1 - apart / reach(of: kind))
            let weight = near * near
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
    /// only the fireflies use it, so two drifts do not move in step.
    let seed: Int

    var body: some View {
        let colour = GardenLamps.swiftUIColour(GardenLamps.colour(of: kind))
        let metre = pointsPerMetre
        let lightAt = GardenLamps.height(of: kind) * metre

        ZStack(alignment: .bottom) {
            // The halo round the light itself, added rather than laid over, so
            // it brightens what is behind it instead of fogging it.
            Circle()
                .fill(RadialGradient(
                    colors: [colour.opacity(0.55 * glow), colour.opacity(0)],
                    center: .center, startRadius: 0, endRadius: 0.42 * metre
                ))
                .frame(width: 0.84 * metre, height: 0.84 * metre)
                .offset(y: -lightAt + 0.42 * metre)
                .blendMode(.plusLighter)

            switch kind {
            case .lantern: lantern(colour: colour, metre: metre)
            case .paperLamp: paperLamp(colour: colour, metre: metre)
            case .fireflies: Fireflies(colour: colour, glow: glow, metre: metre, seed: seed)
            }
        }
        .frame(width: 1.0 * metre, height: 1.2 * metre, alignment: .bottom)
    }

    /// A small iron lantern on a short post.
    private func lantern(colour: Color, metre: Double) -> some View {
        let iron = Color(red: 0.10, green: 0.10, blue: 0.11)
        return VStack(spacing: 0) {
            // The cap.
            Triangle()
                .fill(iron)
                .frame(width: 0.15 * metre, height: 0.05 * metre)
            // The body: a frame with the flame's light filling it.
            ZStack {
                RoundedRectangle(cornerRadius: 0.012 * metre)
                    .fill(colour.opacity(0.35 + 0.65 * glow))
                RoundedRectangle(cornerRadius: 0.012 * metre)
                    .strokeBorder(iron, lineWidth: max(0.8, 0.012 * metre))
                Rectangle()
                    .fill(iron)
                    .frame(width: max(0.6, 0.008 * metre))
            }
            .frame(width: 0.11 * metre, height: 0.14 * metre)
            // The post.
            Rectangle()
                .fill(iron)
                .frame(width: max(1, 0.025 * metre), height: 0.18 * metre)
        }
    }

    /// A paper lamp hung from the tip of a bent cane.
    private func paperLamp(colour: Color, metre: Double) -> some View {
        let cane = Color(red: 0.36, green: 0.30, blue: 0.18)
        return ZStack(alignment: .bottom) {
            // The cane, up from the ground and bowing over at the top.
            Path { path in
                let foot = CGPoint(x: 0.5 * metre, y: 1.2 * metre)
                path.move(to: foot)
                path.addQuadCurve(to: CGPoint(x: 0.66 * metre, y: 0.22 * metre),
                                  control: CGPoint(x: 0.47 * metre, y: 0.3 * metre))
            }
            .stroke(cane, style: StrokeStyle(lineWidth: max(0.8, 0.014 * metre), lineCap: .round))
            .frame(width: 1.0 * metre, height: 1.2 * metre)

            // The lamp, hanging from the cane's tip, lit through its paper, with
            // its ribs showing.
            ZStack {
                Ellipse()
                    .fill(colour.opacity(0.4 + 0.6 * glow))
                ForEach(1..<4) { rib in
                    Capsule()
                        .fill(Color.black.opacity(0.18))
                        .frame(width: 0.15 * metre, height: max(0.5, 0.006 * metre))
                        .offset(y: (Double(rib) - 2) * 0.045 * metre)
                }
            }
            .frame(width: 0.16 * metre, height: 0.19 * metre)
            .offset(x: 0.16 * metre, y: -(0.86 - 0.095) * metre)
        }
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

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
