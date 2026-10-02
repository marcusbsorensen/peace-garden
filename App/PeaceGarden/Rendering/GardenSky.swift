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
    /// Which sky to draw. Left out, it is whichever the developer switch has
    /// chosen, which outside a Debug build is always the one that ships.
    /// `SkyLook` has the proposals of 2 October.
    var look: SkyLook?
    /// Draw what moves as it stands at `date`, in the one canvas, instead of
    /// animating it. For the renders, which are stills.
    var isStill = false

    var body: some View {
        let look = self.look ?? SkyLook.chosen
        if look.moves, light.isDay, !isStill {
            ZStack {
                Canvas { context, size in
                    draw(in: &context, size: size, look: look)
                }
                // What moves, in a canvas of its own, so a cloud sliding a
                // fraction of a point does not repaint the whole sky under it.
                TimelineView(SkyMotionSchedule(clouds: look.hasClouds, life: look.hasLife,
                                               shift: SkyLook.clockShift,
                                               latitude: Whereabouts.place(of: .current, at: date).latitude)) { timeline in
                    Canvas { context, size in
                        drawMotion(in: &context, size: size, look: look,
                                   at: timeline.date.addingTimeInterval(SkyLook.clockShift))
                    }
                }
            }
            .allowsHitTesting(false)
        } else {
            Canvas { context, size in
                draw(in: &context, size: size, look: look)
            }
            .allowsHitTesting(false)
        }
    }

    private func draw(in context: inout GraphicsContext, size: CGSize, look: SkyLook) {
        guard look.paintsTheHour else {
            radial(in: &context, size: size)
            stars(in: &context, size: size)
            body(in: &context, size: size)
            return
        }

        let scene = scene(in: size, look: look)
        if light.isDay {
            DaySky.paint(scene.palette, sun: scene.disc?.centre, in: &context, size: size)
        } else {
            radial(in: &context, size: size)
            let depth = -SunPath.elevation(atHour: scene.hour)
            if let set = onGlass(SunPath.direction(atHour: scene.hour)) {
                DaySky.afterglow(depth: depth, sun: set, in: &context, size: size)
            }
        }
        stars(in: &context, size: size)
        if look.knowsTheSeason {
            planet(in: &context, size: size, place: scene.place)
            dayMoon(in: &context, size: size, scene: scene)
        }
        body(in: &context, size: size, disc: light.isDay ? scene.palette.disc : nil)

        if isStill, light.isDay {
            drawMotion(in: &context, size: size, look: look, at: date)
        }
    }

    /// The clouds and the birds, as they stand at `moment`.
    private func drawMotion(in context: inout GraphicsContext, size: CGSize, look: SkyLook, at moment: Date) {
        let scene = scene(in: size, look: look)
        if look.hasClouds {
            SkyClouds.draw(at: moment, in: &context, size: size, palette: scene.palette,
                           sun: scene.disc?.centre, up: light.up, keepClear: keepClear)
        }
        if look.hasLife {
            SkyLife.draw(at: moment, latitude: scene.place.latitude, in: &context, size: size,
                         palette: scene.palette, up: light.up, keepClear: keepClear)
        }
    }

    /// What the proposed skies all need to know about this moment.
    fileprivate struct Scene {
        var hour: Double
        var place: Place
        var palette: SkyPalette
        var disc: (centre: CGPoint, radius: Double)?
    }

    fileprivate func scene(in size: CGSize, look: SkyLook) -> Scene {
        let hour = light.hourOfDay
        let place = Whereabouts.place(of: .current, at: date)
        let season = look.knowsTheSeason ? Season(date: date, place: place) : nil
        let elevation = SunPath.elevation(atHour: hour, peak: season?.noon ?? 62)
        return Scene(hour: hour, place: place,
                     palette: SkyPalette.at(elevation: elevation, haze: season?.haze ?? 0),
                     disc: disc(in: size))
    }

    /// The sky as it shipped, and still the night in every proposal: a radial
    /// from a fixed point near the top.
    private func radial(in context: inout GraphicsContext, size: CGSize) {
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

        // **The sky turns with the plot.** Turning the garden is the person
        // walking round it, so what they can see of the sky changes with it —
        // which is the same reason both halves of the sphere are drawn. A
        // quarter turn is a quarter of the sky, and after four the same stars
        // are back where they started.
        let here = Whereabouts.place(of: TimeZone.current, at: date)
        let placed = StarField.shared.stars(
            at: date, in: size, place: here,
            facing: StarField.facing(fromLatitude: here.latitude, turn: view.turn)
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
    ///
    /// `disc` is the proposals' sun colour, warmer as it gets lower; nil is
    /// the colour it ships with.
    private func body(in context: inout GraphicsContext, size: CGSize, disc colour: SIMD3<Double>? = nil) {
        guard let placed = disc(in: size) else { return }
        let centre = placed.centre, radius = placed.radius
        let glow = light.isDay ? 0.22 : 0.10
        let tint = colour.map { Color(sky: $0) } ?? self.tint

        context.fill(
            Path(ellipseIn: CGRect(x: centre.x - radius * 2.6, y: centre.y - radius * 2.6,
                                   width: radius * 5.2, height: radius * 5.2)),
            with: .radialGradient(
                Gradient(colors: [tint.opacity(glow), tint.opacity(0)]),
                center: centre, startRadius: 0, endRadius: radius * 2.6
            )
        )

        let face = CGRect(x: centre.x - radius, y: centre.y - radius,
                          width: radius * 2, height: radius * 2)

        if light.isDay {
            context.fill(Path(ellipseIn: face), with: .color(tint))
        } else {
            // The dark limb keeps a trace of earthshine rather than going black,
            // which is what the eye actually sees on a crescent.
            context.fill(Path(ellipseIn: face), with: .color(tint.opacity(0.14)))
            context.fill(MoonDisc(fraction: MoonPhase.fraction(on: date)).path(in: face),
                         with: .color(tint))
        }
    }

    /// Where the disc is drawn, and how big: placed by the light, then moved
    /// off the words.
    private func disc(in size: CGSize) -> (centre: CGPoint, radius: Double)? {
        guard let placed = onGlass(light.direction) else { return nil }
        let radius = light.isDay ? 13.0 : 9.5
        return (Self.clear(placed, of: keepClear, by: radius * 2.6, within: size), radius)
    }

    /// Where a direction in the plot's own axes stands in the sky on screen:
    /// through the plot's projection, at a fixed distance from its middle.
    private func onGlass(_ direction: SIMD3<Double>) -> CGPoint? {
        let along = view.point(x: direction.x, y: direction.y, z: direction.z)
        let away = CGVector(dx: along.x - view.centre.x, dy: along.y - view.centre.y)
        let span = (away.dx * away.dx + away.dy * away.dy).squareRoot()
        guard span > 0.001 else { return nil }

        let far = 340 * view.pointsPerMetre / 42
        return CGPoint(
            x: view.centre.x + away.dx / span * far,
            y: view.centre.y + away.dy / span * far
        )
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

// MARK: - C: the real moon by day, and the brightest planet

extension GardenSky {
    /// The real moon, by day, when it is really up.
    ///
    /// **Pale, because it is.** By day the moon is the sky's own blue with
    /// light added: the dark limb is not there at all, and the lit part is a
    /// white thin enough to see the blue through. The few grey seas on it are
    /// what make it read as the moon rather than as a smudge.
    ///
    /// **Its lit side faces the sun on the screen**, which is not where the
    /// real sun is: the drawn sun keeps the orbit, for the shadows' sake.
    /// Turning the lit limb towards the disc that is actually drawn keeps
    /// right the one thing anybody would notice.
    fileprivate func dayMoon(in context: inout GraphicsContext, size: CGSize, scene: Scene) {
        guard light.isDay else { return }
        // Near new it is lost in the sun's glare, as it is outside.
        guard MoonPhase.lit(on: date) > 0.05 else { return }
        let moon = RealSky.moon(at: date, place: scene.place)
        let showing = SkyPalette.smooth((light.up - 0.03) / 0.12)
            * SkyPalette.smooth((moon.altitude + 0.5) / 3)
        guard showing > 0.01,
              let spot = Self.onGlass(altitude: moon.altitude, azimuth: moon.azimuth,
                                      latitude: scene.place.latitude, turn: view.turn, size: size)
        else { return }

        let radius = 9.5
        let centre = Self.clear(spot, of: keepClear, by: radius * 1.6, within: size)
        let fraction = MoonPhase.fraction(on: date)
        let sun = scene.disc?.centre ?? CGPoint(x: centre.x + 1, y: centre.y)
        // `MoonDisc` lights the right-hand side while waxing and the left
        // while waning; turned so that side faces the drawn sun.
        let towards = atan2(sun.y - centre.y, sun.x - centre.x)
        let turn = fraction < 0.5 ? towards : towards - .pi
        let local = CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2)
        let shape = MoonDisc(fraction: fraction).path(in: local)
            .applying(CGAffineTransform(translationX: centre.x, y: centre.y).rotated(by: turn))

        var lit = context
        lit.blendMode = .screen
        lit.fill(shape, with: .color(Color(sky: SIMD3(0.92, 0.94, 1.0), opacity: 0.46 * showing)))

        // The seas, in the moon's own frame rather than turned with its phase.
        var seas = context
        seas.clip(to: shape)
        let blue = SkyPalette.mix(scene.palette.zenith, scene.palette.horizon, 0.4)
        let maria: [(x: Double, y: Double, r: Double, a: Double)] = [
            (-0.32, -0.34, 0.30, 0.30), (0.22, -0.30, 0.17, 0.30), (0.30, 0.00, 0.21, 0.26),
            (-0.52, 0.06, 0.30, 0.18), (-0.14, 0.40, 0.17, 0.20), (0.46, 0.30, 0.10, 0.20)
        ]
        for mare in maria {
            let r = mare.r * radius
            let at = CGPoint(x: centre.x + mare.x * radius, y: centre.y + mare.y * radius)
            seas.fill(Path(ellipseIn: CGRect(x: at.x - r, y: at.y - r, width: r * 2, height: r * 2)),
                      with: .radialGradient(Gradient(colors: [Color(sky: blue, opacity: mare.a * showing),
                                                              Color(sky: blue, opacity: 0)]),
                                            center: at, startRadius: 0, endRadius: r))
        }
    }

    /// The brightest planet, coming out as the day goes and there all night.
    ///
    /// One point, a little warmer and steadier than the stars round it, and
    /// placed by the same sky they are.
    fileprivate func planet(in context: inout GraphicsContext, size: CGSize, place: Place) {
        let showing = light.isDay ? 1 - SkyPalette.smooth((light.up - 0.06) / 0.28) : 1
        guard showing > 0.01,
              let planet = RealSky.brightestPlanet(at: date, place: place),
              let spot = Self.onGlass(altitude: planet.altitude, azimuth: planet.azimuth,
                                      latitude: place.latitude, turn: view.turn, size: size)
        else { return }
        // By day only above the horizon: the half under it is the night on
        // the other side of the world, and the stars there are not out yet.
        let risen = light.isDay ? SkyPalette.smooth((planet.altitude + 1) / 4) : 1
        let keep = keepClear.reduce(1.0) { min($0, Self.dimming(at: spot, near: $1)) }
        let alpha = showing * risen * keep * (planet.magnitude < -3 ? 0.95 : 0.8)
        guard alpha > 0.01 else { return }

        let tint = Color(red: 1.0, green: 0.97, blue: 0.90)
        context.fill(Path(ellipseIn: CGRect(x: spot.x - 6, y: spot.y - 6, width: 12, height: 12)),
                     with: .radialGradient(Gradient(colors: [tint.opacity(0.32 * alpha), tint.opacity(0)]),
                                           center: spot, startRadius: 0, endRadius: 6))
        context.fill(Path(ellipseIn: CGRect(x: spot.x - 1.6, y: spot.y - 1.6, width: 3.2, height: 3.2)),
                     with: .color(tint.opacity(alpha)))
    }

    /// Where something at this altitude and azimuth stands on the glass, by
    /// the same mapping the stars use, or nil if it is off the side.
    static func onGlass(altitude: Double, azimuth: Double, latitude: Double, turn: Int,
                        size: CGSize) -> CGPoint? {
        let facing = StarField.facing(fromLatitude: latitude, turn: turn)
        let across = Sky.offset(from: facing, to: azimuth)
        guard abs(across) <= Sky.fieldOfView / 2 else { return nil }
        return CGPoint(x: size.width * (0.5 + across / Sky.fieldOfView),
                       y: size.height * (0.5 - altitude / 180))
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
