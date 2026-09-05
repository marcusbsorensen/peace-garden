import SwiftUI

/// A released plant leaving: a point of light, and the sparks it sheds going.
///
/// **What the animation has to say is that the plant went somewhere**, rather
/// than that it stopped existing. A fade would say the second. So the plant
/// gathers to a point at its own base, and the point climbs and drifts off the
/// top of the screen, shedding small lights that fall behind it and go out —
/// the path of something alive, not the dissolve of something deleted.
///
/// Drawn in one `Canvas` from a single `progress`, so the whole flight is one
/// animatable number and can be scrubbed, reversed or cut short by whatever is
/// driving it. Nothing here reads the clock.
struct ReleaseFlight: View {
    /// 0 is the moment of release, 1 is gone.
    var progress: Double
    /// Where the plant stood, in this view's own space. The flight starts at
    /// the base rather than the middle, because that is where the plant meets
    /// the ground and the last thing to leave should be the thing that was
    /// rooted.
    var origin: UnitPoint = UnitPoint(x: 0.5, y: 0.78)
    var tint: Color = Color(white: 1)

    /// How many sparks the flight sheds. Enough to read as a trail at a
    /// glance, few enough that each one is a light rather than a texture.
    private static let sparkCount = 26

    var body: some View {
        Canvas { context, size in
            let start = CGPoint(x: origin.x * size.width, y: origin.y * size.height)
            let head = point(at: progress, in: size, from: start)

            // The sparks are shed *behind* the head, so each one is the head's
            // own position a moment ago and inherits the curve for free.
            for index in 0..<Self.sparkCount {
                let shedAt = Double(index) / Double(Self.sparkCount)
                guard progress > shedAt else { continue }

                // How long ago this one was shed, as a fraction of the flight.
                let age = (progress - shedAt) / max(1 - shedAt, 0.001)
                let fade = pow(1 - age, 1.3)
                guard fade > 0.01 else { continue }

                var at = point(at: shedAt, in: size, from: start)
                // A spark falls a little and wanders a little once it is off
                // the path — otherwise eighteen lights sit on one line and the
                // trail reads as a drawn curve rather than as sparks.
                let drift = jitter(index)
                at.x += drift.dx * age * 62
                at.y += (drift.dy * 20 + age * age * 30)

                let radius = (2.1 + drift.size * 2.6) * fade
                let dot = Path(ellipseIn: CGRect(x: at.x - radius, y: at.y - radius,
                                                 width: radius * 2, height: radius * 2))
                context.fill(dot, with: .color(tint.opacity(0.9 * fade)))
            }

            // The head itself: brightest at the start, when it is still the
            // plant, and thinning as it goes.
            let headFade = pow(1 - progress, 0.5)
            let headRadius = 5.0 * (0.6 + headFade * 0.9)
            let glow = Path(ellipseIn: CGRect(x: head.x - headRadius * 3,
                                              y: head.y - headRadius * 3,
                                              width: headRadius * 6,
                                              height: headRadius * 6))
            context.fill(glow, with: .radialGradient(
                Gradient(colors: [tint.opacity(0.45 * headFade), tint.opacity(0)]),
                center: head, startRadius: 0, endRadius: headRadius * 3))
            let core = Path(ellipseIn: CGRect(x: head.x - headRadius,
                                              y: head.y - headRadius,
                                              width: headRadius * 2,
                                              height: headRadius * 2))
            context.fill(core, with: .color(tint.opacity(0.95 * headFade)))
        }
        .allowsHitTesting(false)
    }

    /// The flight path: up, and leaning aside, the way something light does.
    ///
    /// A quadratic curve rather than a line. The control point sits above and
    /// to one side of the start, so the light leaves vertically — as if let go
    /// — and only afterwards drifts, which is the difference between a thing
    /// rising and a thing thrown.
    private func point(at t: Double, in size: CGSize, from start: CGPoint) -> CGPoint {
        let control = CGPoint(x: start.x + size.width * 0.30,
                              y: start.y - size.height * 0.44)
        let end = CGPoint(x: start.x - size.width * 0.34,
                          y: -size.height * 0.12)
        let u = 1 - t
        return CGPoint(
            x: u * u * start.x + 2 * u * t * control.x + t * t * end.x,
            y: u * u * start.y + 2 * u * t * control.y + t * t * end.y
        )
    }

    /// Fixed per-spark wobble. Deterministic on the index, so the flight looks
    /// the same every time it is played and a screenshot of it is a test.
    private func jitter(_ index: Int) -> (dx: Double, dy: Double, size: Double) {
        let a = sin(Double(index) * 12.9898) * 43758.5453
        let b = sin(Double(index) * 78.233) * 12345.6789
        let c = sin(Double(index) * 39.425) * 24634.6345
        return (dx: (a - a.rounded(.down)) * 2 - 1,
                dy: (b - b.rounded(.down)) * 2 - 1,
                size: c - c.rounded(.down))
    }
}
