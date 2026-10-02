import SwiftUI
import SeedCore

// MARK: - Which sky

/// Which sky is drawn behind the garden.
///
/// **Only `now` ships.** The others are the proposals of 2 October, when
/// Marcus said the day sky was nowhere near as pleasing to look at as the
/// night and called it "that slightly petrol blue". They sit behind the
/// developer switch so they can be judged on a real garden as well as on the
/// renders in `design/app-sky-2026-10-02/`, and none of them is the default.
///
/// **The night is the same in all of them**, apart from the last of the light
/// in the hour after sunset and, in C, one planet. The night was the sky he
/// liked; the proposals are all about the day.
///
/// **None of them touches the light on the plot.** `GardenLight`'s orbit, the
/// shadows and the plants are read from the same function as before, so work
/// on the shadows stays valid whichever of these is chosen. Where an option
/// implies the light ought to change, the README beside the renders says so.
enum SkyLook: String, CaseIterable, Sendable {
    /// The sky as it shipped in build 5: a three-stop radial in a petrol blue.
    case now
    /// A. The real colour of the hour: a pale, luminous horizon under a
    /// deeper zenith, a halo round the sun, gold and rose when it is low.
    case hour
    /// B. A, and the day's clouds: the same for everyone on a given date,
    /// and some days none.
    case clouds
    /// C. A, with the real moon by day when it is really up, the sun's height
    /// leaning with the season and the latitude, and the brightest planet at
    /// dusk.
    case season
    /// D. A, and now and again a few birds crossing very high: swifts in
    /// summer, geese in autumn.
    case life
    /// B, C and D together.
    case all

    var letter: String {
        switch self {
        case .now: return "now"
        case .hour: return "A"
        case .clouds: return "B"
        case .season: return "C"
        case .life: return "D"
        case .all: return "BCD"
        }
    }

    /// One plain line, for the developer row. Not in the catalogue: see
    /// `DeveloperSection`.
    var caption: String {
        switch self {
        case .now: return "The sky as it ships"
        case .hour: return "A · the real colour of the hour"
        case .clouds: return "B · A and the day's clouds"
        case .season: return "C · A, the day moon and the season"
        case .life: return "D · A and birds, rarely"
        case .all: return "B, C and D together"
        }
    }

    var paintsTheHour: Bool { self != .now }
    var hasClouds: Bool { self == .clouds || self == .all }
    var knowsTheSeason: Bool { self == .season || self == .all }
    var hasLife: Bool { self == .life || self == .all }
    var moves: Bool { hasClouds || hasLife }

    /// Whichever the developer switch has chosen, and `now` in a Release build.
    @MainActor static var chosen: SkyLook {
        #if DEBUG
        return Developer.shared.skyLook
        #else
        return .now
        #endif
    }

    /// How far the developer clock has the garden wound on, so what moves runs
    /// on the garden's clock rather than the wall's.
    @MainActor static var clockShift: TimeInterval {
        #if DEBUG
        return Developer.shared.clockShift
        #else
        return 0
        #endif
    }
}

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
    /// says otherwise (C).
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
/// The keyframes are by the sun's height, not the hour, so the season (C) can
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
    /// `haze` is the season's, from C: positive is summer air, which whitens
    /// the horizon; negative is winter air, clearer and deeper overhead.
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
    /// follow it: see the README beside the renders.
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

/// The day sky as light rather than as a colour: A, and the ground the other
/// three stand on.
///
/// **Every shape here is an ellipse.** The dome is one flattened ellipse from
/// the horizon outwards, the low sun's colour is another laid along the
/// horizon, the air under the plot a third. A linear gradient would be fewer
/// lines of code and a horizon ruled across the screen, which is the one
/// thing this garden does not have.
enum DaySky {

    /// The whole of a day sky, before the stars, the bodies and anything in it.
    static func paint(_ palette: SkyPalette, sun: CGPoint?, in context: inout GraphicsContext,
                      size: CGSize) {
        let w = size.width, h = size.height
        // The horizon is where the stars have it: across the middle, where
        // the plot floats. `StarField` and `Sky.onGlass` put it there.
        let horizon = CGPoint(x: w / 2, y: h / 2)

        // The dome. Pale at the horizon and deepening away from it, quickly
        // at first and then slowly, which is the shape of looking through
        // less and less air.
        let wide: CGFloat = 2.4
        let reach = hypot(w / 2 / wide, h / 2) * 1.03
        let dome: [Gradient.Stop] = [0, 0.04, 0.10, 0.18, 0.28, 0.40, 0.55, 0.75, 1].map { s in
            .init(color: Color(sky: SkyPalette.mix(palette.horizon, palette.zenith, pow(s, 0.62))),
                  location: s)
        }
        ellipse(&context, centre: horizon, wide: wide, radius: reach, stops: dome, covering: size)

        // The air under the plot: deeper, cooler, and a little nearer violet,
        // so the half below the horizon is not the half above turned over.
        ellipse(&context, centre: CGPoint(x: w / 2, y: h * 1.06), wide: 1.5, radius: h * 0.6, stops: [
            .init(color: Color(sky: palette.under, opacity: 0.92), location: 0),
            .init(color: Color(sky: palette.under, opacity: 0.55), location: 0.45),
            .init(color: Color(sky: palette.under, opacity: 0), location: 1)
        ])

        guard let sun else { return }

        // A low sun colours the whole horizon, most on its own side. The
        // opposite side gets the rose band that real twilight puts above the
        // earth's shadow.
        if palette.low > 0.01 {
            let side = min(w * 0.85, max(w * 0.15, sun.x))
            let warm = SkyPalette.mix(palette.glow, palette.horizon, 0.3)
            ellipse(&context, centre: CGPoint(x: side, y: horizon.y), wide: 3.2, radius: h * 0.27, stops: [
                .init(color: Color(sky: warm, opacity: 0.55 * palette.low), location: 0),
                .init(color: Color(sky: warm, opacity: 0.26 * palette.low), location: 0.4),
                .init(color: Color(sky: warm, opacity: 0), location: 1)
            ])
            let rose = SIMD3(0.80, 0.56, 0.63)
            ellipse(&context, centre: CGPoint(x: w - side, y: horizon.y - h * 0.08), wide: 3.6,
                    radius: h * 0.15, stops: [
                .init(color: Color(sky: rose, opacity: 0.30 * palette.low * palette.low), location: 0),
                .init(color: Color(sky: rose, opacity: 0), location: 1)
            ])
        }

        // The sun's halo: a broad warm glow, broader and warmer the lower the
        // sun, and a tight bright aureole. Screened, so it lightens what is
        // under it the way light does rather than painting over it.
        var lit = context
        lit.blendMode = .screen
        let broad = h * (0.30 + 0.28 * palette.low)
        let strength = 0.26 + 0.26 * palette.low
        ellipse(&lit, centre: sun, wide: 1, radius: broad, stops: [
            .init(color: Color(sky: palette.glow, opacity: strength), location: 0),
            .init(color: Color(sky: palette.glow, opacity: strength * 0.5), location: 0.18),
            .init(color: Color(sky: palette.glow, opacity: strength * 0.2), location: 0.45),
            .init(color: Color(sky: palette.glow, opacity: 0), location: 1)
        ])
        ellipse(&lit, centre: sun, wide: 1, radius: 58 + 26 * palette.low, stops: [
            .init(color: Color(sky: palette.glow, opacity: 0.50), location: 0),
            .init(color: Color(sky: palette.glow, opacity: 0.18), location: 0.35),
            .init(color: Color(sky: palette.glow, opacity: 0), location: 1)
        ])
    }

    /// The last of the light, on the side the sun went down, for the first
    /// hour of the night and the last hour before dawn.
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
        var lit = context
        lit.blendMode = .screen
        ellipse(&lit, centre: sun, wide: 1.6, radius: size.height * 0.5, stops: [
            .init(color: Color(sky: colour, opacity: 0.60 * fade), location: 0),
            .init(color: Color(sky: colour, opacity: 0.30 * fade), location: 0.35),
            .init(color: Color(sky: colour, opacity: 0), location: 1)
        ])
    }

    /// A radial gradient squashed into an ellipse `wide` times as wide as it
    /// is tall. With `covering`, it fills the whole screen; without, only the
    /// ellipse it fades out inside, which is all an overlay needs.
    static func ellipse(_ context: inout GraphicsContext, centre: CGPoint, wide: CGFloat, radius: CGFloat,
                        stops: [Gradient.Stop], covering size: CGSize? = nil) {
        var layer = context
        layer.translateBy(x: centre.x, y: centre.y)
        layer.scaleBy(x: wide, y: 1)
        let shape: Path
        if let size {
            shape = Path(CGRect(x: -centre.x / wide, y: -centre.y,
                                width: size.width / wide, height: size.height))
        } else {
            shape = Path(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2))
        }
        layer.fill(shape, with: .radialGradient(Gradient(stops: stops), center: .zero,
                                                startRadius: 0, endRadius: radius))
    }
}
