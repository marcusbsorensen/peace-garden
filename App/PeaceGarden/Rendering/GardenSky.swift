import SwiftUI
import SeedCore

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
    /// Where the screen's words are — the heading, the count under it, Close —
    /// in this canvas's coordinates. The sun and moon stand clear of them.
    var keepClear: [CGRect] = []

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

    /// The real sky, for where this phone is, at the hour it is.
    ///
    /// **It used to be a hundred and ninety dots dealt from a fixed seed**, and
    /// the comment here said why: a sky whose stars wander is the one thing
    /// that would give away that they are drawn. That was the right answer
    /// while they were invented. They are not invented now — they wander
    /// because the earth turns, which is the opposite of giving the game away.
    ///
    /// **The whole sphere, both halves.** Zenith at the top of the screen,
    /// nadir at the foot, and the horizon across the middle where the plot
    /// floats. The half below is the sky somebody on the other side of the
    /// world has overhead at this moment; a garden about two people meeting
    /// shows both their skies and the line between them that neither can see
    /// past. Nothing draws that line — the plot is on it.
    ///
    /// Drawn in bands rather than one fill a star: five thousand fills a
    /// redraw is five thousand calls into the rasteriser for a backdrop, and
    /// the eye cannot tell a magnitude 5.1 star from a 5.2 one anyway.
    private func stars(in context: inout GraphicsContext, size: CGSize) {
        let showing = light.isDay ? max(0, 1 - light.up * 5) : 1
        guard showing > 0.01 else { return }

        let placed = StarField.shared.stars(
            at: date, in: size, place: Whereabouts.place(of: TimeZone.current, at: date)
        )
        guard !placed.isEmpty else { return }

        // Sixteen bands of brightness against six of colour: ninety-six fills
        // at the very most, and in practice a good deal fewer.
        var bands: [Int: (radius: Double, alpha: Double, tint: Color, path: Path)] = [:]
        for star in placed {
            // The stars keep off the words, as the sun and the moon do. A body
            // can be moved aside; a constellation cannot, so these are dimmed
            // where the words are instead — and dimmed *gradually*, over a
            // dozen points, because a star-free rectangle is a straight line
            // drawn by leaving something out.
            let clear = keepClear.reduce(1.0) { least, box in
                min(least, Self.dimming(at: star.at, near: box))
            }
            guard clear > 0.02 else { continue }
            let alpha = star.alpha * clear
            let brightness = min(15, Int(alpha * 16))
            let warmth = min(5, max(0, Int((star.warmth + 0.4) / 2.3 * 6)))
            let key = brightness * 6 + warmth
            var band = bands[key] ?? (star.radius, alpha, star.tint, Path())
            band.path.addEllipse(in: CGRect(
                x: star.at.x - star.radius, y: star.at.y - star.radius,
                width: star.radius * 2, height: star.radius * 2
            ))
            bands[key] = band
        }

        for band in bands.values {
            context.fill(band.path, with: .color(band.tint.opacity(band.alpha * showing)))
        }
    }

    /// How much light a star keeps this near a line of words: nothing inside
    /// them, all of it a dozen points out, and a smooth ramp between.
    static func dimming(at point: CGPoint, near box: CGRect) -> Double {
        guard !box.isNull, !box.isEmpty else { return 1 }
        let fade = 14.0
        let outside = box.insetBy(dx: -fade, dy: -fade)
        guard outside.contains(point) else { return 1 }
        if box.contains(point) { return 0 }

        let dx = max(box.minX - point.x, point.x - box.maxX, 0)
        let dy = max(box.minY - point.y, point.y - box.maxY, 0)
        let away = (dx * dx + dy * dy).squareRoot()
        return min(1, away / fade)
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
        let placed = CGPoint(
            x: view.centre.x + away.dx / span * far,
            y: view.centre.y + away.dy / span * far
        )
        let radius = light.isDay ? 13.0 : 9.5
        let glow = light.isDay ? 0.22 : 0.10
        let centre = Self.clear(placed, of: keepClear, by: radius * 2.6, within: size)

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

    /// **The sun never sits on the words.** Placed by the light alone, the sun
    /// rose through the heading in the morning and the moon set through Close.
    /// A body that would overlap one of them is moved just outside it, below or
    /// to the side, whichever is the shorter move, so it still stands nearly
    /// where the light says and slides round the words rather than jumping.
    /// `reach` covers the disc and the whole of its glow, so not even the halo
    /// lies over a letter.
    static func clear(_ point: CGPoint, of rects: [CGRect], by reach: CGFloat,
                      within size: CGSize) -> CGPoint {
        var point = point
        for rect in rects where !rect.isNull && !rect.isEmpty {
            let zone = rect.insetBy(dx: -reach, dy: -reach)
            guard zone.contains(point) else { continue }
            // Never above: the words are at the top, and above them is off the screen.
            var moves: [CGPoint] = [CGPoint(x: point.x, y: zone.maxY)]
            if zone.minX > reach { moves.append(CGPoint(x: zone.minX, y: point.y)) }
            if zone.maxX < size.width - reach { moves.append(CGPoint(x: zone.maxX, y: point.y)) }
            point = moves.min { a, b in
                hypot(a.x - point.x, a.y - point.y) < hypot(b.x - point.x, b.y - point.y)
            }!
        }
        return point
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
