import SwiftUI

/// What is behind the plot: space, darkening with the hour, with the stars out
/// at night and whichever body is up standing in it.
///
/// **There is no pool of light on a world.** `StageBackdrop`'s glow is a lamp
/// behind a subject, which is right for a plant photographed for a box; a planet
/// is lit by its own sun. So the background darkens with the hour rather than
/// closing in.
struct GardenSky: View {
    let light: GardenGround.Light
    let date: Date
    /// The plot's own projection, so the body stands where the light comes from.
    let view: Isometric

    var body: some View {
        Canvas { context, size in
            draw(in: &context, size: size)
        }
        .allowsHitTesting(false)
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let centre = CGPoint(x: size.width / 2, y: size.height * 0.24)
        let reach = max(size.width, size.height) * 1.6

        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .radialGradient(
                Gradient(stops: stops),
                center: centre,
                startRadius: size.width * 0.025,
                endRadius: reach
            )
        )

        stars(in: &context, size: size)
        body(in: &context, size: size)
    }

    // MARK: The sky itself

    /// **A day sky that reads as sky, and a night that is not a black screen.**
    ///
    /// The first pass came off the mockup, where the sky is nearly black at every
    /// hour: the plot is the picture there, and the page around it is a page. In
    /// the app it is the whole screen behind a garden, and a noon that is a dark
    /// navy says the garden is somewhere underground.
    ///
    /// So daylight runs to a real blue, deepening away from the sun, and night
    /// keeps enough in it to be a night sky rather than an absence. It is the one
    /// place `Chrome`'s rule about the plant being the only saturated thing is
    /// deliberately relaxed — a sky is not chrome, and a blue behind a garden is
    /// what tells you the garden is outdoors. It is still held well under the
    /// plants: the brightest the sky goes is under half, where a petal goes to
    /// the top of its range.
    private var stops: [Gradient.Stop] {
        let up = light.up
        let near = light.isDay
            ? Color(hue: 205 / 360, saturation: 0.46, brightness: 0.13 + 0.33 * up)
            : Color(hue: 224 / 360, saturation: 0.44, brightness: 0.085 + 0.055 * up)
        let middle = light.isDay
            ? Color(hue: 214 / 360, saturation: 0.50, brightness: 0.09 + 0.22 * up)
            : Color(hue: 222 / 360, saturation: 0.46, brightness: 0.062 + 0.030 * up)
        let far = light.isDay
            ? Color(hue: 222 / 360, saturation: 0.52, brightness: 0.05 + 0.11 * up)
            : Color(red: 0.030, green: 0.036, blue: 0.062)

        return [
            .init(color: near, location: 0),
            .init(color: middle, location: 0.58),
            .init(color: far, location: 1)
        ]
    }

    /// **Fixed, not drifting.** A sky whose stars wander is the one thing that
    /// would give away that they are drawn, so they are dealt once from a fixed
    /// seed and stay where they were put. They come out as the sun goes down,
    /// and the plot is drawn over them, so it occludes its own patch of sky.
    private func stars(in context: inout GraphicsContext, size: CGSize) {
        let showing = light.isDay ? max(0, 1 - light.up * 5) : 1
        guard showing > 0.01 else { return }

        var seed: UInt32 = 20_260_917
        func next() -> Double {
            seed = seed &* 1_664_525 &+ 1_013_904_223
            return Double(seed) / Double(UInt32.max)
        }

        for _ in 0..<190 {
            let x = next() * Double(size.width)
            let y = next() * Double(size.height) * 0.74
            let magnitude = next()
            let radius = 0.35 + magnitude * magnitude * 1.5
            let alpha = (0.18 + magnitude * 0.72) * showing

            context.fill(
                Path(ellipseIn: CGRect(x: x - radius, y: y - radius,
                                       width: radius * 2, height: radius * 2)),
                with: .color(.white.opacity(alpha))
            )
        }
    }

    // MARK: Whichever body is up

    /// Placed by the light direction itself, so the shadows on the ground point
    /// away from the thing casting them without anything having to be kept in
    /// step by hand.
    private func body(in context: inout GraphicsContext, size: CGSize) {
        let along = view.point(x: light.direction.x, y: light.direction.y, z: light.direction.z)
        let away = CGVector(dx: along.x - view.centre.x, dy: along.y - view.centre.y)
        let span = (away.dx * away.dx + away.dy * away.dy).squareRoot()
        guard span > 0.001 else { return }

        let far = 340 * view.pointsPerMetre / 42
        let centre = CGPoint(
            x: view.centre.x + away.dx / span * far,
            y: view.centre.y + away.dy / span * far
        )
        let radius = light.isDay ? 13.0 : 9.5
        let glow = light.isDay ? 0.22 : 0.10

        context.fill(
            Path(ellipseIn: CGRect(x: centre.x - radius * 2.6, y: centre.y - radius * 2.6,
                                   width: radius * 5.2, height: radius * 5.2)),
            with: .radialGradient(
                Gradient(colors: [tint.opacity(glow), tint.opacity(0)]),
                center: centre, startRadius: 0, endRadius: radius * 2.6
            )
        )

        let disc = CGRect(x: centre.x - radius, y: centre.y - radius,
                          width: radius * 2, height: radius * 2)

        if light.isDay {
            context.fill(Path(ellipseIn: disc), with: .color(tint))
        } else {
            // The dark limb keeps a trace of earthshine rather than going black,
            // which is what the eye actually sees on a crescent.
            context.fill(Path(ellipseIn: disc), with: .color(tint.opacity(0.14)))
            context.fill(MoonDisc(fraction: MoonPhase.fraction(on: date)).path(in: disc),
                         with: .color(tint))
        }
    }

    private var tint: Color {
        light.isDay
            ? Color(red: 1.0, green: 0.96, blue: 0.86)
            : Color(red: 0.88, green: 0.91, blue: 0.98)
    }
}

/// The lit part of the moon, for the phase it is actually in.
///
/// A semicircle for the limb, plus a semi-ellipse for the terminator whose
/// x-radius is `R cos(phase)` — **signed**, so it bulges outward for a crescent
/// and inward for a gibbous, and the two are one piece of arithmetic rather than
/// two drawings. Waning is the same shape mirrored.
struct MoonDisc: Shape {
    let fraction: Double

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let terminator = cos(2 * .pi * fraction)
        let waning = fraction >= 0.5
        let samples = 48

        func point(_ index: Int, scale: Double) -> CGPoint {
            let angle = .pi / 2 - Double(index) / Double(samples) * .pi
            let x = radius * scale * cos(angle) * (waning ? -1 : 1)
            return CGPoint(x: centre.x + x, y: centre.y - radius * sin(angle))
        }

        var path = Path()
        path.move(to: point(0, scale: 1))
        for index in 1...samples { path.addLine(to: point(index, scale: 1)) }
        for index in stride(from: samples, through: 0, by: -1) {
            path.addLine(to: point(index, scale: terminator))
        }
        path.closeSubpath()
        return path
    }
}
