import SwiftUI
import SeedCore

/// Which way the sky drifts behind a time-lapse. One drift, once, in the whole
/// run: never a day and a night per simulated day.
///
/// Rendered side by side in `design/time-lapse-2026-10-13/sky-ABC.png`.
enum SkyDrift: String, CaseIterable, Sendable {
    /// **A — first light to now.** The sky starts at first light, a deep blue
    /// with a little rose low down, and drifts to the sky as it is at this
    /// hour: brightening into the day if it is day, settling into the night
    /// if it is night. It ends on the real sky of the moment, so the plant
    /// arrives at now under now.
    case towardsNow
    /// **B — night into day.** Deep night to full day, whatever the hour.
    case nightIntoDay
    /// **C — still.** The sky as it is at this hour, held. Also what Reduce
    /// Motion gets, whichever is chosen.
    case still

    /// The drift the app plays. See the README for the choice.
    static let chosen: SkyDrift = .towardsNow
}

/// The sky behind a time-lapse: a notion of time turning, not a clock.
///
/// **Why it is not `GardenSky`.** The garden's sky is a planet's: the real
/// stars for where the phone is, the real moon, the season's clouds and birds,
/// all placed through the plot's projection. Run at a hundred days in twelve
/// seconds, every one of those would move, and most of them would flicker. This
/// keeps the part of that sky that says *what time of day it is* — the same
/// colours, from the same keyframes (`SkyPalette`), on the sun's same arc
/// (`SunPath`) — and leaves out everything that would say it fast.
///
/// **What it draws.** A gradient with no edge in it, from the zenith at the top
/// of the glass to the sky's palest at the foot; the sun's warmth rising from
/// below the edge while it is near the horizon; and at night a scatter of fixed
/// stars that come out as the sky darkens and fade as it lightens. They do not
/// twinkle and they do not move.
///
/// **What keeps it safe (3A, WCAG 2.3.1).** The sky drifts once in the whole
/// run, so there is at most one passage from dark to light, and it is spread
/// over seconds. Every frame's mean luminance is measured by
/// `TimeLapseLuminanceTests`, at sixty frames a second, for every drift, both
/// appearances, every second hour of the day and a stop part way through; the
/// largest change from one frame to the next has to stay under one per cent
/// of the full range, the brightness may turn round at most once, and there is
/// nothing anywhere in the run that WCAG would count as a flash.
enum TimeLapseSky {
    /// What the sky is doing at one moment.
    struct Moment: Equatable, Sendable {
        /// The sun's height in degrees, negative below the horizon.
        var elevation: Double
        /// How much of the sky is over the stage, `0...1`.
        var presence: Double

        static let absent = Moment(elevation: 0, presence: 0)
    }

    /// Where the drift starts and ends, in degrees of the sun's height.
    static func drift(_ drift: SkyDrift, hourNow: Double) -> (from: Double, to: Double) {
        let now = min(max(SunPath.elevation(atHour: hourNow), deepestNight), highestDay)
        switch drift {
        case .towardsNow: return (firstLight, now)
        case .nightIntoDay: return (deepestNight, 40)
        case .still: return (now, now)
        }
    }

    /// First light: the sun a few degrees under the horizon, the sky a deep
    /// blue with the rose of the horizon just showing.
    static let firstLight = -4.0
    /// Below this the sky is as dark as it goes; a drift into a midnight sun
    /// would spend most of itself on a change nobody can see.
    static let deepestNight = -20.0
    static let highestDay = 62.0

    // MARK: The colours

    struct Colours: Equatable {
        var top: SIMD3<Double>
        var horizon: SIMD3<Double>
        /// The sun's warmth low in the sky, and how strong it is.
        var glow: SIMD3<Double>
        var glowAmount: Double
        /// How far out the stars are, `0...1`.
        var stars: Double
    }

    /// The night's own colours: the garden's night sky (`GardenSky.stops`),
    /// near and far.
    static let nightTop = SIMD3<Double>(0.030, 0.036, 0.062)
    static let nightHorizon = SIMD3<Double>(0.048, 0.058, 0.085)
    /// First light's own colours, overhead and low down.
    static let twilightTop = SIMD3<Double>(0.12, 0.11, 0.26)
    static let twilightLow = SIMD3<Double>(0.52, 0.36, 0.50)

    /// The sky with the sun at `elevation` degrees.
    ///
    /// Day is `SkyPalette`'s, the keyframes Marcus chose on 2 October. Night is
    /// the garden's. Between them the change is spread across eighteen degrees
    /// of the sun's height, from twelve under the horizon to six above — the
    /// whole of twilight, and a little of the morning — so no drift can pass
    /// through it quickly.
    static func colours(elevation: Double) -> Colours {
        let day = SkyPalette.at(elevation: max(0, elevation))
        let d = smooth((elevation + 12) / 18)
        // Halfway between night and day, a dimmed sunrise orange is brown. A
        // little violet at the middle of twilight keeps it the rose and mauve
        // of first light rather than the colour of a dusty road.
        let twilight = 4 * d * (1 - d)
        return Colours(
            top: SkyPalette.mix(SkyPalette.mix(nightTop, day.zenith, d), twilightTop, 0.30 * twilight),
            horizon: SkyPalette.mix(SkyPalette.mix(nightHorizon, day.horizon, d), twilightLow, 0.38 * twilight),
            glow: day.glow,
            glowAmount: day.low * d * 0.24,
            stars: 1 - smooth((elevation + 16) / 12)
        )
    }

    /// How much the sky visibly changes between two heights of the sun: the
    /// colours that fill most of the screen, the glow, and the stars.
    static func visibleChange(from a: Double, to b: Double) -> Double {
        let x = colours(elevation: a), y = colours(elevation: b)
        func distance(_ p: SIMD3<Double>, _ q: SIMD3<Double>) -> Double {
            abs(p.x - q.x) + abs(p.y - q.y) + abs(p.z - q.z)
        }
        return distance(x.top, y.top) + distance(x.horizon, y.horizon)
            + abs(x.glowAmount - y.glowAmount) + abs(x.stars - y.stars) * 0.2
    }

    // MARK: How it sits on the stage

    /// How the sky is laid over the ground of each appearance.
    struct Look: Equatable, Sendable {
        /// The screen's own ground, which the sky is drawn over.
        var ground: SIMD3<Double>
        /// How far the sky's colours are taken towards the ground. On a light
        /// ground a night sky at full depth would be a dark slab arriving over
        /// a white screen; lifted, it is the same hours told in a paler key.
        var lift: Double
        /// How opaque the sky is at full presence.
        var strength: Double
        var drawsStars: Bool

        /// Over black. Not quite opaque, so the pool of light the plant stands
        /// in still shows through.
        static let dark = Look(ground: SIMD3(0, 0, 0), lift: 0, strength: 0.8, drawsStars: true)
        /// Over `Chrome.ground`'s warm near-white.
        static let light = Look(ground: SIMD3(repeating: 0.965), lift: 0.7, strength: 0.9, drawsStars: false)

        static func `for`(_ scheme: ColorScheme) -> Look { scheme == .light ? .light : .dark }
    }

    /// **No horizon on the plant's screen.** A pale band across the middle,
    /// with darker air under it, was a ground line by another name: the plant
    /// stood on it, which is the one idiom the stage does not use — a plant
    /// here grows from a point, not from a drawn ground. So the sky grades one
    /// way only, from the zenith at the top to its palest at the foot of the
    /// glass, and the sun's warmth rises from below the edge.
    static let middleAt = 0.55

    /// Draws the sky into `cg`, origin at the top left, over whatever is there.
    static func draw(_ moment: Moment, in cg: CGContext, size: CGSize, look: Look) {
        guard moment.presence > 0.0005, size.width > 0, size.height > 0 else { return }
        let sky = colours(elevation: moment.elevation)
        let alpha = min(1, max(0, moment.presence)) * look.strength
        func lifted(_ c: SIMD3<Double>) -> SIMD3<Double> { SkyPalette.mix(c, look.ground, look.lift) }
        func colour(_ c: SIMD3<Double>, _ a: Double) -> CGColor {
            let l = lifted(c)
            return CGColor(srgbRed: l.x, green: l.y, blue: l.z, alpha: a)
        }

        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        let colours = [
            colour(sky.top, alpha),
            colour(SkyPalette.mix(sky.top, sky.horizon, 0.4), alpha),
            colour(sky.horizon, alpha)
        ] as CFArray
        let locations: [CGFloat] = [0, CGFloat(middleAt), 1]
        if let gradient = CGGradient(colorsSpace: space, colors: colours, locations: locations) {
            cg.saveGState()
            cg.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size.height),
                                  options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
            cg.restoreGState()
        }

        // The sun's warmth, low down, while it is near the horizon.
        let glow = sky.glowAmount * alpha
        if glow > 0.002 {
            let centre = CGPoint(x: size.width / 2, y: size.height * 1.08)
            let radius = max(size.width, size.height) * 0.72
            let warm = [colour(sky.glow, glow), colour(sky.glow, 0)] as CFArray
            if let gradient = CGGradient(colorsSpace: space, colors: warm, locations: [0, 1]) {
                cg.saveGState()
                cg.drawRadialGradient(gradient, startCenter: centre, startRadius: 0,
                                      endCenter: centre, endRadius: radius, options: [])
                cg.restoreGState()
            }
        }

        // Fixed stars: out as the sky darkens, gone as it lightens. They do
        // not twinkle; they do not move.
        let starlight = sky.stars * min(1, max(0, moment.presence))
        if look.drawsStars, starlight > 0.01 {
            cg.saveGState()
            for star in stars {
                let r = star.radius
                cg.setFillColor(CGColor(srgbRed: 0.90, green: 0.92, blue: 1.0, alpha: star.alpha * starlight))
                cg.fillEllipse(in: CGRect(x: star.x * size.width - r, y: star.y * size.height - r,
                                          width: r * 2, height: r * 2))
            }
            cg.restoreGState()
        }
    }

    /// Ninety stars dealt once, from a fixed seed, over the upper sky.
    struct Star { var x: Double; var y: Double; var radius: Double; var alpha: Double }
    static let stars: [Star] = {
        var state: UInt64 = 0x5EED_0F_7_1A5E
        func next() -> Double {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Double(state >> 11) / Double(1 << 53)
        }
        return (0..<90).map { _ in
            let size = next()
            return Star(x: next(), y: pow(next(), 1.3) * 0.64,
                        radius: 0.45 + 0.85 * size * size, alpha: 0.25 + 0.6 * next())
        }
    }()

    static func smooth(_ x: Double) -> Double {
        let c = min(max(x, 0), 1)
        return c * c * (3 - 2 * c)
    }
}

/// The sky, on the plant's screen, while a time-lapse plays.
struct TimeLapseSkyView: View {
    let moment: TimeLapseSky.Moment
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let look = TimeLapseSky.Look.for(scheme)
        Canvas { context, size in
            context.withCGContext { cg in
                TimeLapseSky.draw(moment, in: cg, size: size, look: look)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Measuring it

/// The mean relative luminance of a picture, `0...1`: every pixel's sRGB
/// linearised and weighted as WCAG weights it (0.2126 R + 0.7152 G + 0.0722 B).
///
/// What the flash rules are written against, and what the tests measure every
/// frame of the run by.
enum TimeLapseLuminance {
    static func mean(of image: CGImage, side: Int = 48) -> Double {
        let width = side, height = max(1, Int(Double(side) * Double(image.height) / Double(max(1, image.width))))
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                      bytesPerRow: width * 4, space: space,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return 0 }
        context.interpolationQuality = .medium
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return mean(of: context)
    }

    /// The same, of whatever is already drawn in an RGBA8 context.
    static func mean(of context: CGContext) -> Double {
        guard let data = context.data else { return 0 }
        let width = context.width, height = context.height, row = context.bytesPerRow
        let bytes = data.bindMemory(to: UInt8.self, capacity: row * height)
        var total = 0.0
        for y in 0..<height {
            for x in 0..<width {
                let at = y * row + x * 4
                total += 0.2126 * linear[Int(bytes[at])]
                    + 0.7152 * linear[Int(bytes[at + 1])]
                    + 0.0722 * linear[Int(bytes[at + 2])]
            }
        }
        return total / Double(width * height)
    }

    /// sRGB's transfer curve, undone, for every 8-bit value.
    static let linear: [Double] = (0...255).map { value in
        let c = Double(value) / 255
        return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }
}
