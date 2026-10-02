import SwiftUI
import SeedCore

// MARK: - Where the sun is

/// The sun's path as the sky reads it.
///
/// **The same orbit as `GardenLight`, carried on under the horizon.** The
/// light stops at sunset because the moon takes over; the sky needs to know
/// where the sun went, because the last of its light is still in the sky for
/// a while afterwards. By day the two agree exactly.
enum SunPath {
    /// How high the sun is at an hour, in degrees, and negative under the
    /// horizon. `peak` is the orbit's sixty-two degrees unless the season
    /// says otherwise: `Season.noon`.
    static func elevation(atHour hour: Double, peak: Double = 62) -> Double {
        sin(through(hour) * .pi) * peak
    }

    /// The sun's direction in the plot's own axes, under the horizon as well.
    static func direction(atHour hour: Double) -> SIMD3<Double> {
        let along = through(hour)
        let altitude = sin(along * .pi) * GardenGround.Light.peak
        let azimuth = -Double.pi * 0.75 + along * .pi
        return SIMD3(cos(altitude) * sin(azimuth), sin(altitude), cos(altitude) * cos(azimuth))
    }

    /// How far round its whole circle the sun is: `0` rising, `1` setting,
    /// `2` rising again.
    private static func through(_ hour: Double) -> Double {
        var clock = hour.truncatingRemainder(dividingBy: 24)
        if clock < 0 { clock += 24 }
        if clock < 6 { clock += 24 }
        return (clock - 6) / 12
    }
}

extension GardenGround.Light {
    /// The hour this light is for, worked back from where its body stands.
    ///
    /// The sky is handed a light rather than an hour, and the light is what
    /// the settings choose: *Always day* is noon whatever the clock says. So
    /// the hour is read off the light, which is the one that agrees with the
    /// plot, rather than off the date, which may not.
    var hourOfDay: Double {
        var along = (atan2(direction.x, direction.z) + 0.75 * .pi) / .pi
        along -= floor(along)
        return isDay ? 6 + 12 * along : (18 + 12 * along).truncatingRemainder(dividingBy: 24)
    }
}

// MARK: - The colours of a clear sky

/// The colours of a clear sky with the sun at one height.
///
/// **Why the old sky read as petrol.** Its brightest blue was a hue of 205°
/// at under half saturation and under half brightness, everywhere at once:
/// a greyed teal with nothing pale in it and nothing deep. A clear sky is
/// neither of those. It is a saturated blue overhead and a pale, luminous
/// band at the horizon, where the eye looks through so much air that the blue
/// is diluted towards white — aerial perspective — and the difference
/// between the two is most of what makes it read as air.
///
/// The keyframes are by the sun's height, not the hour, so the season can
/// move them by moving the sun.
struct SkyPalette: Equatable {
    /// Straight up, behind the heading.
    var zenith: SIMD3<Double>
    /// At the horizon, which on this screen is behind the plot.
    var horizon: SIMD3<Double>
    /// The half under the horizon: the air under a floating garden.
    var under: SIMD3<Double>
    /// The sun's own colour in the air round it.
    var glow: SIMD3<Double>
    /// How low the sun is as far as colour is concerned: `0` well up, `1` on
    /// the horizon.
    var low: Double

    /// **Held under the plants and under the words.** The zenith stays dark
    /// enough for the white heading to read at the contrast it had on the old
    /// sky's brightest blue, and only the band behind the plot — where there
    /// are no words — is allowed to go pale.
    private static let keys: [(elevation: Double, zenith: SIMD3<Double>, horizon: SIMD3<Double>,
                               under: SIMD3<Double>, glow: SIMD3<Double>)] = [
        (0, SIMD3(0.09, 0.12, 0.27), SIMD3(0.88, 0.56, 0.44), SIMD3(0.16, 0.13, 0.24), SIMD3(1.00, 0.55, 0.30)),
        (5, SIMD3(0.10, 0.16, 0.35), SIMD3(0.92, 0.67, 0.50), SIMD3(0.18, 0.17, 0.30), SIMD3(1.00, 0.65, 0.38)),
        (12, SIMD3(0.12, 0.21, 0.44), SIMD3(0.90, 0.77, 0.62), SIMD3(0.17, 0.21, 0.37), SIMD3(1.00, 0.78, 0.54)),
        (22, SIMD3(0.13, 0.26, 0.53), SIMD3(0.82, 0.80, 0.76), SIMD3(0.15, 0.24, 0.44), SIMD3(1.00, 0.88, 0.70)),
        (34, SIMD3(0.13, 0.29, 0.58), SIMD3(0.72, 0.80, 0.88), SIMD3(0.14, 0.26, 0.49), SIMD3(1.00, 0.94, 0.84)),
        (50, SIMD3(0.13, 0.30, 0.60), SIMD3(0.69, 0.81, 0.92), SIMD3(0.14, 0.27, 0.51), SIMD3(1.00, 0.97, 0.90)),
        (70, SIMD3(0.14, 0.32, 0.63), SIMD3(0.71, 0.83, 0.93), SIMD3(0.15, 0.28, 0.53), SIMD3(1.00, 0.98, 0.93)),
        (90, SIMD3(0.15, 0.34, 0.66), SIMD3(0.73, 0.84, 0.94), SIMD3(0.16, 0.30, 0.55), SIMD3(1.00, 0.99, 0.95))
    ]

    /// The sky with the sun this many degrees up.
    ///
    /// `haze` is the season's: positive is summer air, which whitens the
    /// horizon; negative is winter air, clearer and deeper overhead.
    static func at(elevation: Double, haze: Double = 0) -> SkyPalette {
        let e = min(90, max(0, elevation))
        var index = 0
        while index < keys.count - 2, e > keys[index + 1].elevation { index += 1 }
        let a = keys[index], b = keys[index + 1]
        let t = smooth((e - a.elevation) / (b.elevation - a.elevation))

        var palette = SkyPalette(
            zenith: mix(a.zenith, b.zenith, t),
            horizon: mix(a.horizon, b.horizon, t),
            under: mix(a.under, b.under, t),
            glow: mix(a.glow, b.glow, t),
            low: 1 - smooth(e / 30)
        )

        if haze > 0 {
            let amount = haze * (1 - palette.low)
            palette.horizon = mix(palette.horizon, SIMD3(0.80, 0.82, 0.84), 0.22 * amount)
            palette.zenith = mix(palette.zenith, palette.horizon, 0.07 * amount)
        } else if haze < 0 {
            let amount = -haze
            palette.zenith *= 1 - 0.07 * amount
            palette.horizon = mix(palette.horizon, SIMD3(0.60, 0.72, 0.87), 0.20 * amount * (1 - palette.low))
        }
        return palette
    }

    /// The sun's disc, warmer as it gets lower. The light on the plot does not
    /// follow it yet: `design/app-sky-2026-10-02/README.md` says what would.
    var disc: SIMD3<Double> {
        Self.mix(SIMD3(1.0, 0.96, 0.86), SIMD3(1.0, 0.80, 0.56), low * low)
    }

    static func smooth(_ x: Double) -> Double {
        let t = min(1, max(0, x))
        return t * t * (3 - 2 * t)
    }

    static func mix(_ a: SIMD3<Double>, _ b: SIMD3<Double>, _ t: Double) -> SIMD3<Double> {
        a + (b - a) * t
    }
}

extension Color {
    init(sky rgb: SIMD3<Double>, opacity: Double = 1) {
        self.init(red: min(1, max(0, rgb.x)), green: min(1, max(0, rgb.y)),
                  blue: min(1, max(0, rgb.z)), opacity: opacity)
    }
}

// MARK: - Painting it

/// The day sky as light rather than as a colour: the ground everything else
/// in it stands on.
///
/// **Every shape here is an ellipse.** The dome is one flattened ellipse from
/// the horizon outwards, the low sun's colour is another laid along the
/// horizon, the air under the plot a third. A linear gradient would be fewer
/// lines of code and a horizon ruled across the screen, which is the one
/// thing this garden does not have.
///
/// **Painted small and kept.** None of it has an edge, so none of it needs the
/// screen's resolution: it is painted at half a pixel a point, a thirty-sixth
/// of the pixels a phone's screen has, kept until the hour, the season, the
/// size or the sun's place on the screen changes, and drawn scaled up. On the
/// garden's clock that is once a minute. Painted at full size on every redraw
/// it cost more than twice what the old sky did; kept, a redraw is one picture.
enum DaySky {

    /// The day sky for this palette and sun, from the kept picture if nothing
    /// has changed since it was painted.
    @MainActor
    static func picture(_ palette: SkyPalette, sun: CGPoint?, size: CGSize) -> Image? {
        let key = Key(palette: palette, size: size,
                      sun: sun.map { CGPoint(x: ($0.x * 2).rounded() / 2, y: ($0.y * 2).rounded() / 2) })
        if let kept, kept.key == key { return kept.image }
        guard let painted = paint(palette, sun: key.sun, size: size, perPoint: perPoint) else { return nil }
        let image = Image(decorative: painted, scale: perPoint).interpolation(.medium)
        kept = (key, image)
        return image
    }

    /// Throws the kept picture away, so the next redraw paints. For measuring.
    @MainActor static func forget() { kept = nil }

    /// Pixels a point. Half: the softest thing in the sky, the sun's aureole,
    /// is still thirty pixels across.
    static let perPoint: CGFloat = 0.5

    private struct Key: Equatable {
        var palette: SkyPalette
        var size: CGSize
        var sun: CGPoint?
    }

    @MainActor private static var kept: (key: Key, image: Image)?

    /// The whole of a day sky, before the stars, the bodies and anything in
    /// it, as a bitmap at `perPoint` pixels a point.
    static func paint(_ palette: SkyPalette, sun: CGPoint?, size: CGSize, perPoint: CGFloat) -> CGImage? {
        let pixels = CGSize(width: max(1, (size.width * perPoint).rounded(.up)),
                            height: max(1, (size.height * perPoint).rounded(.up)))
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let cg = CGContext(data: nil, width: Int(pixels.width), height: Int(pixels.height),
                                 bitsPerComponent: 8, bytesPerRow: 0, space: space,
                                 bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        // Top-left, y down, in points, as the canvas has it.
        cg.translateBy(x: 0, y: pixels.height)
        cg.scaleBy(x: perPoint, y: -perPoint)

        let w = size.width, h = size.height
        // The horizon is where the stars have it: across the middle, where
        // the plot floats. `StarField` and `Sky.onGlass` put it there.
        let horizon = CGPoint(x: w / 2, y: h / 2)

        // The dome. Pale at the horizon and deepening away from it, quickly
        // at first and then slowly, which is the shape of looking through
        // less and less air.
        let wide: CGFloat = 2.4
        let reach = hypot(w / 2 / wide, h / 2) * 1.03
        let dome: [Stop] = [0, 0.04, 0.10, 0.18, 0.28, 0.40, 0.55, 0.75, 1].map { s in
            (SkyPalette.mix(palette.horizon, palette.zenith, pow(s, 0.62)), 1, s)
        }
        ellipse(cg, space: space, centre: horizon, wide: wide, radius: reach, stops: dome, covering: true)

        // The air under the plot: deeper, cooler, and a little nearer violet,
        // so the half below the horizon is not the half above turned over.
        ellipse(cg, space: space, centre: CGPoint(x: w / 2, y: h * 1.06), wide: 1.5, radius: h * 0.6, stops: [
            (palette.under, 0.92, 0), (palette.under, 0.55, 0.45), (palette.under, 0, 1)
        ])

        guard let sun else { return cg.makeImage() }

        // A low sun colours the whole horizon, most on its own side. The
        // opposite side gets the rose band that real twilight puts above the
        // earth's shadow.
        if palette.low > 0.01 {
            let side = min(w * 0.85, max(w * 0.15, sun.x))
            let warm = SkyPalette.mix(palette.glow, palette.horizon, 0.3)
            ellipse(cg, space: space, centre: CGPoint(x: side, y: horizon.y), wide: 3.2, radius: h * 0.27, stops: [
                (warm, 0.55 * palette.low, 0), (warm, 0.26 * palette.low, 0.4), (warm, 0, 1)
            ])
            let rose = SIMD3(0.80, 0.56, 0.63)
            ellipse(cg, space: space, centre: CGPoint(x: w - side, y: horizon.y - h * 0.08), wide: 3.6,
                    radius: h * 0.15, stops: [(rose, 0.30 * palette.low * palette.low, 0), (rose, 0, 1)])
        }

        // The sun's halo: a broad warm glow, broader and warmer the lower the
        // sun, and a tight bright aureole. Screened, so it lightens what is
        // under it the way light does rather than painting over it.
        cg.saveGState()
        cg.setBlendMode(.screen)
        let broad = h * (0.30 + 0.28 * palette.low)
        let strength = 0.26 + 0.26 * palette.low
        ellipse(cg, space: space, centre: sun, wide: 1, radius: broad, stops: [
            (palette.glow, strength, 0), (palette.glow, strength * 0.5, 0.18),
            (palette.glow, strength * 0.2, 0.45), (palette.glow, 0, 1)
        ])
        ellipse(cg, space: space, centre: sun, wide: 1, radius: 58 + 26 * palette.low, stops: [
            (palette.glow, 0.50, 0), (palette.glow, 0.18, 0.35), (palette.glow, 0, 1)
        ])
        cg.restoreGState()
        return cg.makeImage()
    }

    /// The last of the light, on the side the sun went down, for the first
    /// hour of the night and the last hour before dawn. Drawn straight onto
    /// the night rather than kept: it is there three hours a day.
    ///
    /// `depth` is how far under the horizon the sun is, in degrees: amber
    /// just after sunset, violet by seven, and gone a little after eighteen,
    /// which is where astronomers say the night begins.
    static func afterglow(depth: Double, sun: CGPoint, in context: inout GraphicsContext, size: CGSize) {
        // The orbit's twilight is short — the sun drops sixteen degrees in
        // the first hour — so the glow is let run a little past eighteen, or
        // it would be over before anybody opened the garden after dinner.
        guard depth < 24 else { return }
        let fade = pow(1 - depth / 24, 1.4)
        let colour = depth < 7
            ? SkyPalette.mix(SIMD3(0.62, 0.32, 0.22), SIMD3(0.30, 0.18, 0.34), depth / 7)
            : SkyPalette.mix(SIMD3(0.30, 0.18, 0.34), SIMD3(0.13, 0.13, 0.30), (depth - 7) / 17)
        let radius = size.height * 0.5
        var lit = context
        lit.blendMode = .screen
        lit.translateBy(x: sun.x, y: sun.y)
        lit.scaleBy(x: 1.6, y: 1)
        lit.fill(Path(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2)),
                 with: .radialGradient(Gradient(stops: [
                     .init(color: Color(sky: colour, opacity: 0.60 * fade), location: 0),
                     .init(color: Color(sky: colour, opacity: 0.30 * fade), location: 0.35),
                     .init(color: Color(sky: colour, opacity: 0), location: 1)
                 ]), center: .zero, startRadius: 0, endRadius: radius))
    }

    /// A colour, its opacity and where it stands along the gradient.
    typealias Stop = (colour: SIMD3<Double>, opacity: Double, at: CGFloat)

    /// A radial gradient squashed into an ellipse `wide` times as wide as it
    /// is tall. Covering, its last colour carries on to the edges; otherwise
    /// it fades out inside the ellipse, which is all an overlay needs.
    private static func ellipse(_ cg: CGContext, space: CGColorSpace, centre: CGPoint, wide: CGFloat,
                                radius: CGFloat, stops: [Stop], covering: Bool = false) {
        let colours = stops.map { stop -> CGColor in
            CGColor(colorSpace: space, components: [
                min(1, max(0, stop.colour.x)), min(1, max(0, stop.colour.y)),
                min(1, max(0, stop.colour.z)), stop.opacity
            ]) ?? CGColor(gray: 0, alpha: 0)
        }
        guard let gradient = CGGradient(colorsSpace: space, colors: colours as CFArray,
                                        locations: stops.map(\.at)) else { return }
        cg.saveGState()
        cg.translateBy(x: centre.x, y: centre.y)
        cg.scaleBy(x: wide, y: 1)
        cg.drawRadialGradient(gradient, startCenter: .zero, startRadius: 0, endCenter: .zero,
                              endRadius: radius, options: covering ? [.drawsAfterEndLocation] : [])
        cg.restoreGState()
    }
}
