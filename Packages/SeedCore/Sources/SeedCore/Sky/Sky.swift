#if os(WASI)
import FoundationEssentials
import WASILibc
#else
import Foundation
#endif

/// The real sky, put where the person looking at it is.
///
/// **Why the garden has a true sky at all.** The plot floats. There is no
/// ground under it and nothing below to block the view, so the whole celestial
/// sphere is there to be drawn — and the half beneath your feet is not a
/// leftover of that, it is the point. Those are the stars somebody on the far
/// side of the world is looking up at while you look down at them. A garden
/// about two people meeting can put both their skies on one screen, and the
/// line where the two halves meet is the horizon they each have and neither
/// can see past.
///
/// **It asks for nothing.** Where somebody is comes from their time zone, which
/// their phone was already keeping before this app existed. See `Places`, and
/// `docs/PLACE.md` for why a coordinate is not taken instead.
///
/// **What it is not.** J2000 positions, no precession, no nutation, no
/// aberration, no refraction. Precession is the largest of those and has moved
/// the sky about a third of a degree since 2000 — on a screen four hundred
/// points wide showing half the sky, less than a point. The rest are smaller
/// again. This is a sky you can recognise, not a sky you can navigate by.
public enum Sky {

    // MARK: Time

    /// Greenwich mean sidereal time, in degrees.
    ///
    /// Sidereal time is the sky's own clock: the right ascension standing due
    /// south this instant. It runs about four minutes a day fast against the
    /// sun's, which is why a constellation rises four minutes earlier each
    /// night and why the winter sky is a different sky.
    ///
    /// The series is the IAU's, minus the terms too small to reach a pixel.
    public static func greenwichSiderealTime(at date: Date) -> Double {
        // Julian date. 2440587.5 is 1970 in the Julian count.
        let julian = date.timeIntervalSince1970 / 86_400 + 2_440_587.5
        let since2000 = julian - 2_451_545.0
        let centuries = since2000 / 36_525
        let degrees = 280.460_618_37
            + 360.985_647_366_29 * since2000
            + 0.000_387_933 * centuries * centuries
        return wrapped(degrees)
    }

    /// The sidereal time at a longitude: the sky's clock, set locally.
    public static func siderealTime(at date: Date, longitude: Double) -> Double {
        wrapped(greenwichSiderealTime(at: date) + longitude)
    }

    // MARK: Where a star is

    /// Where a star stands for somebody at this latitude, at this sidereal time.
    ///
    /// - `altitude` is degrees above the horizon, and **goes negative**, which
    ///   is the half of the sphere under the observer's feet. Nothing here
    ///   discards it: see the note at the top of this file.
    /// - `azimuth` is degrees clockwise from north, as a compass reads.
    public static func horizon(
        rightAscension: Double,
        declination: Double,
        siderealTime: Double,
        latitude: Double
    ) -> (altitude: Double, azimuth: Double) {
        let hourAngle = radians(wrapped(siderealTime - rightAscension))
        let dec = radians(declination)
        let lat = radians(latitude)

        let sinAltitude = sin(dec) * sin(lat) + cos(dec) * cos(lat) * cos(hourAngle)
        let altitude = asin(max(-1, min(1, sinAltitude)))

        let azimuth = atan2(
            -cos(dec) * sin(hourAngle),
            sin(dec) * cos(lat) - cos(dec) * sin(lat) * cos(hourAngle)
        )
        return (degrees(altitude), wrapped(degrees(azimuth)))
    }

    /// Which way an observer is looking when the screen is drawn.
    ///
    /// **Towards the equator**, which is south from the northern hemisphere and
    /// north from the southern. That is where the sun, the moon and every
    /// planet pass, and it is the half of the sky a person in either hemisphere
    /// thinks of as *the* sky. At the equator itself it is south, arbitrarily,
    /// and it matters least there because everything passes overhead anyway.
    public static func facing(fromLatitude latitude: Double) -> Double {
        latitude < 0 ? 0 : 180
    }

    // MARK: Small arithmetic

    static func wrapped(_ degrees: Double) -> Double {
        let turn = degrees.truncatingRemainder(dividingBy: 360)
        return turn < 0 ? turn + 360 : turn
    }

    /// The shortest way round from one bearing to another, in −180...180.
    public static func offset(from bearing: Double, to other: Double) -> Double {
        var difference = wrapped(other - bearing)
        if difference > 180 { difference -= 360 }
        return difference
    }

    static func radians(_ degrees: Double) -> Double { degrees * .pi / 180 }
    static func degrees(_ radians: Double) -> Double { radians * 180 / .pi }
}

// MARK: - The sky on a screen

/// Where a star lands on the glass, and how it is drawn there.
///
/// **Here rather than in the renderer**, because there are two renderers: the
/// app draws the field with a SwiftUI `Canvas` and the web walk draws it on a
/// 2-D canvas in a browser. A constant kept in one of them is a second sky, and
/// the point of this one is that somebody holding the phone and somebody
/// walking the garden in a browser are under the same stars. The browser's copy
/// is a port — `tools/wasm/web/sky.js` — and `tools/reference/check_sky.mjs`
/// holds it to vectors this produced, the way `check_long_walk.php` holds the
/// service's placing rule.
///
/// Nothing here knows about a colour type or a drawing context. The tint comes
/// back as three numbers and each renderer makes its own colour of them.
public extension Sky {

    /// How faint a star has to be before it is left out.
    ///
    /// Six is a dark country sky: about five thousand stars. The catalogue
    /// carries half a magnitude more so that this is a decision about how the
    /// garden looks rather than about what was shipped.
    static var faintest: Double { 6.0 }

    /// How much of the sky is across the screen.
    ///
    /// A little over half a turn, so the sky spills past both edges rather than
    /// ending at them. Altitude is not scaled to match: the whole hundred and
    /// eighty degrees from zenith to nadir is always on screen, because leaving
    /// the other person's half off it would be the one thing this is for.
    static var fieldOfView: Double { 220.0 }

    /// One star, placed and dressed, in the coordinates of the glass.
    struct Placement: Equatable, Sendable {
        public var x: Double
        public var y: Double
        public var radius: Double
        public var alpha: Double
        /// The clamped B−V the tint came from, kept so a renderer can put stars
        /// of a like colour in one band and fill them together.
        public var warmth: Double
        /// Red, green and blue in 0...1.
        public var tint: (red: Double, green: Double, blue: Double)

        public static func == (a: Placement, b: Placement) -> Bool {
            a.x == b.x && a.y == b.y && a.radius == b.radius && a.alpha == b.alpha
                && a.warmth == b.warmth && a.tint == b.tint
        }
    }

    /// Where this star is on a screen of this size, or nil if it is off the
    /// side or too faint to draw.
    static func place(
        _ star: Star,
        siderealTime: Double,
        latitude: Double,
        facing towards: Double,
        width: Double,
        height: Double
    ) -> Placement? {
        guard star.magnitude <= faintest else { return nil }
        let (altitude, azimuth) = horizon(
            rightAscension: star.rightAscension,
            declination: star.declination,
            siderealTime: siderealTime,
            latitude: latitude
        )
        let across = offset(from: towards, to: azimuth)
        guard abs(across) <= fieldOfView / 2 else { return nil }

        return Placement(
            x: width * (0.5 + across / fieldOfView),
            // Zenith at the top, nadir at the foot, the horizon across the
            // middle where the plot floats.
            y: height * (0.5 - altitude / 180),
            radius: radius(ofMagnitude: star.magnitude),
            alpha: alpha(ofMagnitude: star.magnitude),
            warmth: warmth(ofColourIndex: star.colourIndex),
            tint: tint(ofColourIndex: star.colourIndex)
        )
    }

    /// Brightness is a ratio, not a number of points: each magnitude is two and
    /// a half times the light of the next. Drawn straight, Sirius would be a
    /// disc and everything else a speck, so this is flattened hard — the eye
    /// reads a bright star as *bigger* as well as brighter, and only a little
    /// of each is needed to tell them apart.
    static func radius(ofMagnitude magnitude: Double) -> Double {
        let brightness = max(0, faintest - magnitude)
        return 0.32 + pow(brightness, 1.45) * 0.24
    }

    static func alpha(ofMagnitude magnitude: Double) -> Double {
        let brightness = max(0, faintest - magnitude)
        return min(1, 0.16 + brightness * 0.16)
    }

    /// B−V, held inside the range real starlight occupies.
    static func warmth(ofColourIndex index: Double) -> Double {
        max(-0.4, min(1.9, index))
    }

    /// A star's colour, from B−V: how much brighter it is in blue light than in
    /// yellow. Rigel is about −0.03 and blue-white, the sun is +0.65,
    /// Betelgeuse is +1.85 and orange.
    ///
    /// **Held well short of what the numbers would give.** Real starlight at
    /// this size is almost white — the colour is there at the edge of seeing,
    /// and a sky of frank blue and orange dots is a chart of star types rather
    /// than a sky.
    static func tint(ofColourIndex index: Double) -> (red: Double, green: Double, blue: Double) {
        let warm = warmth(ofColourIndex: index)
        if warm <= 0 {
            // Blue-white.
            let t = min(1, -warm / 0.4)
            return (1 - 0.10 * t, 1 - 0.04 * t, 1)
        }
        let t = min(1, warm / 1.9)
        return (1, 1 - 0.13 * t, 1 - 0.28 * t)
    }
}

// MARK: - The catalogue

/// One star, as the packed catalogue holds it.
public struct Star: Equatable, Sendable {
    /// Degrees, J2000.
    public var rightAscension: Double
    /// Degrees, J2000.
    public var declination: Double
    /// Visual magnitude. Smaller is brighter, and Sirius is −1.46.
    public var magnitude: Double
    /// B−V: how blue a star is against how red. About −0.3 for Rigel and +1.9
    /// for a carbon star; the sun is +0.65.
    public var colourIndex: Double

    public init(rightAscension: Double, declination: Double, magnitude: Double, colourIndex: Double) {
        self.rightAscension = rightAscension
        self.declination = declination
        self.magnitude = magnitude
        self.colourIndex = colourIndex
    }
}

/// The Yale Bright Star Catalogue, packed at six bytes a star.
///
/// Written by `tools/sky/pack.py`, which is also where the field widths are
/// argued. Brightest first, so a renderer that wants the brightest few thousand
/// takes a prefix and stops.
public enum StarCatalogue {
    static let magic = Array("PGSKY1".utf8)

    public enum Trouble: Error, Equatable {
        case notACatalogue
        case truncated
    }

    public static func decode(_ data: Data) throws -> [Star] {
        let bytes = [UInt8](data)
        guard bytes.count >= 10, Array(bytes[0..<6]) == magic else { throw Trouble.notACatalogue }

        func word(_ at: Int) -> UInt16 { UInt16(bytes[at]) | UInt16(bytes[at + 1]) << 8 }

        let count = Int(UInt32(word(6)) | UInt32(word(8)) << 16)
        guard bytes.count >= 10 + count * 6 else { throw Trouble.truncated }

        var stars: [Star] = []
        stars.reserveCapacity(count)
        for index in 0..<count {
            let at = 10 + index * 6
            let ra = Double(word(at)) / 65_536 * 360
            let dec = Double(Int16(bitPattern: word(at + 2))) / 32_767 * 90
            let magnitude = Double(bytes[at + 4]) / 16 - 2
            let colour = Double(Int8(bitPattern: bytes[at + 5])) / 50
            stars.append(Star(rightAscension: ra, declination: dec,
                              magnitude: magnitude, colourIndex: colour))
        }
        return stars
    }
}
