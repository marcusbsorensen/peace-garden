import Foundation
import SeedCore
import simd

/// The real sun, moon and planets, near enough to draw: C.
///
/// **Paul Schlyter's low-precision elements** ("How to compute planetary
/// positions"), which are good to a few arcminutes for the sun and planets
/// and to a fraction of a degree for the moon with the main perturbations in.
/// On a screen where the whole sky from zenith to nadir is nine hundred
/// points, a degree is five points, so this is finer than it needs to be and
/// a good deal coarser than an ephemeris. Like `Sky`, it asks for nothing and
/// reads only the clock and the time zone's city.
///
/// **Why the moon by day is placed by the real sky and the moon by night is
/// not.** At night the moon is the light: it casts the shadows, so it has to
/// stand where `GardenLight` puts it. By day it is only something in the sky,
/// so it can stand where it really is — among the stars, which are already
/// where they really are.
enum RealSky {

    // MARK: Where things are

    /// Where the moon stands for somebody here, in degrees: altitude above the
    /// horizon, corrected for parallax, and azimuth clockwise from north.
    static func moon(at date: Date, place: Place) -> (altitude: Double, azimuth: Double) {
        let d = day(date)
        let (ra, dec, distance) = moonEquatorial(d)
        let seen = Sky.horizon(rightAscension: ra, declination: dec,
                               siderealTime: Sky.siderealTime(at: date, longitude: place.longitude),
                               latitude: place.latitude)
        // From the earth's surface rather than its centre, the moon stands
        // about a degree lower: the earth's radius against sixty of them.
        let parallax = asin(1 / distance) * 180 / .pi * cos(seen.altitude * .pi / 180)
        return (seen.altitude - parallax, seen.azimuth)
    }

    /// The brightest planet that is far enough from the sun to be seen, and
    /// where it stands.
    static func brightestPlanet(at date: Date, place: Place)
        -> (name: String, altitude: Double, azimuth: Double, magnitude: Double)? {
        let d = day(date)
        let sun = sunEcliptic(d)
        let sunVector = unit(ra: equatorial(lon: sun.lon, lat: 0, d: d).ra,
                             dec: equatorial(lon: sun.lon, lat: 0, d: d).dec)
        let sidereal = Sky.siderealTime(at: date, longitude: place.longitude)

        var best: (name: String, altitude: Double, azimuth: Double, magnitude: Double)?
        for planet in Planet.all {
            let seen = planet.geocentric(d: d, sun: sun)
            let (ra, dec) = equatorial(lon: seen.lon, lat: seen.lat, d: d)
            let elongation = acos(min(1, max(-1, simd_dot(unit(ra: ra, dec: dec), sunVector)))) * 180 / .pi
            // Under fifteen degrees from the sun, a planet is lost in its glare.
            guard elongation > 15 else { continue }
            let at = Sky.horizon(rightAscension: ra, declination: dec, siderealTime: sidereal,
                                 latitude: place.latitude)
            if best == nil || seen.magnitude < best!.magnitude {
                best = (planet.name, at.altitude, at.azimuth, seen.magnitude)
            }
        }
        return best
    }

    /// The sun's declination today, in degrees: how far north of the equator
    /// it stands, which is the season.
    static func sunDeclination(_ date: Date) -> Double {
        let d = day(date)
        return equatorial(lon: sunEcliptic(d).lon, lat: 0, d: d).dec
    }

    /// The angle between the sun and the moon as seen from here, in degrees.
    /// Only for the tests, which hold it to the phase.
    static func elongationOfMoon(at date: Date) -> Double {
        let d = day(date)
        let sun = sunEcliptic(d)
        let s = equatorial(lon: sun.lon, lat: 0, d: d)
        let m = moonEquatorial(d)
        return acos(min(1, max(-1, simd_dot(unit(ra: s.ra, dec: s.dec), unit(ra: m.ra, dec: m.dec)))))
            * 180 / .pi
    }

    // MARK: The sun

    /// Days since 2000 January 0.0 UT, which is the count the elements use.
    static func day(_ date: Date) -> Double {
        date.timeIntervalSince1970 / 86_400 + 2_440_587.5 - 2_451_543.5
    }

    /// The sun's ecliptic longitude and distance in AU, its geocentric
    /// rectangular position, and its mean anomaly and mean longitude, which
    /// the moon's perturbations need.
    static func sunEcliptic(_ d: Double)
        -> (lon: Double, r: Double, x: Double, y: Double, mean: Double, meanLon: Double) {
        let w = 282.9404 + 4.70935e-5 * d
        let e = 0.016709 - 1.151e-9 * d
        let m = rev(356.0470 + 0.9856002585 * d)
        let ecc = m + degrees * e * sind(m) * (1 + e * cosd(m))
        let xv = cosd(ecc) - e
        let yv = (1 - e * e).squareRoot() * sind(ecc)
        let v = atan2d(yv, xv)
        let r = (xv * xv + yv * yv).squareRoot()
        let lon = rev(v + w)
        return (lon, r, r * cosd(lon), r * sind(lon), m, rev(m + w))
    }

    // MARK: The moon

    /// Right ascension and declination in degrees, and distance in earth radii.
    static func moonEquatorial(_ d: Double) -> (ra: Double, dec: Double, distance: Double) {
        let n = 125.1228 - 0.0529538083 * d
        let i = 5.1454
        let w = 318.0634 + 0.1643573223 * d
        let a = 60.2666
        let e = 0.054900
        let m = rev(115.3654 + 13.0649929509 * d)

        let ecc = kepler(m, e)
        let xv = a * (cosd(ecc) - e)
        let yv = a * (1 - e * e).squareRoot() * sind(ecc)
        let v = atan2d(yv, xv)
        var r = (xv * xv + yv * yv).squareRoot()

        let xh = r * (cosd(n) * cosd(v + w) - sind(n) * sind(v + w) * cosd(i))
        let yh = r * (sind(n) * cosd(v + w) + cosd(n) * sind(v + w) * cosd(i))
        let zh = r * sind(v + w) * sind(i)
        var lon = atan2d(yh, xh)
        var lat = atan2d(zh, (xh * xh + yh * yh).squareRoot())

        // The largest of the perturbations: the sun pulling the moon about.
        let sun = sunEcliptic(d)
        let ms = sun.mean, mm = m
        let lm = rev(n + w + m)
        let dd = rev(lm - sun.meanLon)
        let f = rev(lm - n)
        lon += -1.274 * sind(mm - 2 * dd) + 0.658 * sind(2 * dd) - 0.186 * sind(ms)
            - 0.059 * sind(2 * mm - 2 * dd) - 0.057 * sind(mm - 2 * dd + ms)
            + 0.053 * sind(mm + 2 * dd) + 0.046 * sind(2 * dd - ms) + 0.041 * sind(mm - ms)
            - 0.035 * sind(dd) - 0.031 * sind(mm + ms) - 0.015 * sind(2 * f - 2 * dd)
            + 0.011 * sind(mm - 4 * dd)
        lat += -0.173 * sind(f - 2 * dd) - 0.055 * sind(mm - f - 2 * dd)
            - 0.046 * sind(mm + f - 2 * dd) + 0.033 * sind(f + 2 * dd) + 0.017 * sind(2 * mm + f)
        r += -0.58 * cosd(mm - 2 * dd) - 0.46 * cosd(2 * dd)

        let (ra, dec) = equatorial(lon: lon, lat: lat, d: d)
        return (ra, dec, r)
    }

    // MARK: The planets

    /// The planets bright enough to be *the* planet in a sky: Mercury is
    /// never far enough from the sun, and Uranus and beyond are not bright.
    struct Planet: Sendable {
        let name: String
        /// N, i, w, a, e and M at the epoch, and how fast each moves a day.
        let base: [Double]
        let rate: [Double]
        /// Schlyter's magnitude: `bright + 5 log(r·R) + phaseLoss·FV + cubic·FV³`.
        let bright: Double
        let phaseLoss: Double
        var cubic: Double = 0

        static let all: [Planet] = [
            Planet(name: "Venus",
                   base: [76.6799, 3.3946, 54.8910, 0.723330, 0.006773, 48.0052],
                   rate: [2.46590e-5, 2.75e-8, 1.38374e-5, 0, -1.302e-9, 1.6021302244],
                   bright: -4.34, phaseLoss: 0.013, cubic: 4.2e-7),
            Planet(name: "Mars",
                   base: [49.5574, 1.8497, 286.5016, 1.523688, 0.093405, 18.6021],
                   rate: [2.11081e-5, -1.78e-8, 2.92961e-5, 0, 2.516e-9, 0.5240207766],
                   bright: -1.51, phaseLoss: 0.016),
            Planet(name: "Jupiter",
                   base: [100.4542, 1.3030, 273.8777, 5.20256, 0.048498, 19.8950],
                   rate: [2.76854e-5, -1.557e-7, 1.64505e-5, 0, 4.469e-9, 0.0830853001],
                   bright: -9.25, phaseLoss: 0.014),
            Planet(name: "Saturn",
                   base: [113.6634, 2.4886, 339.3939, 9.55475, 0.055546, 316.9670],
                   rate: [2.38980e-5, -1.081e-7, 2.97661e-5, 0, -9.499e-9, 0.0334442282],
                   bright: -9.0, phaseLoss: 0.044)
        ]

        private func elements(_ d: Double) -> (n: Double, i: Double, w: Double, a: Double, e: Double, m: Double) {
            let at = zip(base, rate).map { $0 + $1 * d }
            return (at[0], at[1], at[2], at[3], at[4], at[5])
        }

        private func magnitude(_ r: Double, _ distance: Double, _ phase: Double) -> Double {
            bright + 5 * log10(r * distance) + phaseLoss * phase + cubic * phase * phase * phase
        }

        /// Where the planet is seen from the earth, on the ecliptic, and how bright.
        func geocentric(d: Double, sun: (lon: Double, r: Double, x: Double, y: Double,
                                         mean: Double, meanLon: Double))
            -> (lon: Double, lat: Double, magnitude: Double) {
            let (n, i, w, a, e, m) = elements(d)
            let ecc = RealSky.kepler(RealSky.rev(m), e)
            let xv = a * (RealSky.cosd(ecc) - e)
            let yv = a * (1 - e * e).squareRoot() * RealSky.sind(ecc)
            let v = RealSky.atan2d(yv, xv)
            let r = (xv * xv + yv * yv).squareRoot()

            let xh = r * (RealSky.cosd(n) * RealSky.cosd(v + w)
                          - RealSky.sind(n) * RealSky.sind(v + w) * RealSky.cosd(i))
            let yh = r * (RealSky.sind(n) * RealSky.cosd(v + w)
                          + RealSky.cosd(n) * RealSky.sind(v + w) * RealSky.cosd(i))
            let zh = r * RealSky.sind(v + w) * RealSky.sind(i)

            let xg = xh + sun.x, yg = yh + sun.y, zg = zh
            let distance = (xg * xg + yg * yg + zg * zg).squareRoot()
            let lon = RealSky.atan2d(yg, xg)
            let lat = RealSky.atan2d(zg, (xg * xg + yg * yg).squareRoot())

            let cosPhase = (r * r + distance * distance - sun.r * sun.r) / (2 * r * distance)
            let phase = acos(min(1, max(-1, cosPhase))) * RealSky.degrees
            return (lon, lat, magnitude(r, distance, phase))
        }
    }

    // MARK: Small arithmetic

    static let degrees = 180 / Double.pi

    static func equatorial(lon: Double, lat: Double, d: Double) -> (ra: Double, dec: Double) {
        let obliquity = 23.4393 - 3.563e-7 * d
        let x = cosd(lon) * cosd(lat)
        let y = sind(lon) * cosd(lat)
        let z = sind(lat)
        let ye = y * cosd(obliquity) - z * sind(obliquity)
        let ze = y * sind(obliquity) + z * cosd(obliquity)
        return (rev(atan2d(ye, x)), atan2d(ze, (x * x + ye * ye).squareRoot()))
    }

    static func unit(ra: Double, dec: Double) -> SIMD3<Double> {
        SIMD3(cosd(dec) * cosd(ra), cosd(dec) * sind(ra), sind(dec))
    }

    /// The eccentric anomaly, from the mean, by Newton's method.
    static func kepler(_ m: Double, _ e: Double) -> Double {
        var ecc = m + degrees * e * sind(m) * (1 + e * cosd(m))
        for _ in 0..<6 {
            let step = (ecc - degrees * e * sind(ecc) - m) / (1 - e * cosd(ecc))
            ecc -= step
            if abs(step) < 1e-6 { break }
        }
        return ecc
    }

    static func rev(_ x: Double) -> Double { x - floor(x / 360) * 360 }
    static func sind(_ x: Double) -> Double { sin(x / degrees) }
    static func cosd(_ x: Double) -> Double { cos(x / degrees) }
    static func atan2d(_ y: Double, _ x: Double) -> Double { atan2(y, x) * degrees }
}

/// The season and the place, as C reads them.
///
/// **It leans the sky; it does not move the sun.** The orbit still has the
/// sun up from six to six, because the light on the plot is the orbit's.
/// What changes is how high the sky's colours behave as if it were: a London
/// December sky stays low and golden all day, and a June noon is a high,
/// clear blue. A noon in Lagos is higher still.
struct Season: Equatable {
    /// The sun's real height at noon today, in degrees, held where the orbit
    /// can still make a day of it.
    let noon: Double
    /// Summer air (+, hazier at the horizon) or winter air (−, clearer and
    /// deeper overhead), scaled down towards the equator, where there is
    /// little season to speak of.
    let haze: Double

    init(date: Date, place: Place) {
        let declination = RealSky.sunDeclination(date)
        noon = min(88, max(14, 90 - abs(place.latitude - declination)))
        let summer = (place.latitude >= 0 ? 1.0 : -1.0) * declination / 23.44
        haze = summer * min(1, abs(place.latitude) / 45)
    }
}
