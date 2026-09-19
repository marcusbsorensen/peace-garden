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
