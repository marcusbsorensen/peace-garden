import SeedCore
import simd
import XCTest
@testable import PeaceGarden

/// The day sky chosen on 2 October: the arithmetic under it, which a
/// render would show wrong without saying why.
final class DaySkyTests: XCTestCase {

    /// The sky is handed a light, not an hour, and has to get the hour back.
    func testTheHourComesBackOffTheLight() {
        for hour in stride(from: 0.0, to: 24, by: 0.5) {
            let back = GardenGround.Light.at(hour: hour).hourOfDay
            XCTAssertEqual(back, hour, accuracy: 0.01, "\(hour) came back as \(back)")
        }
    }

    /// By day the sky's sun and the light's sun are one sun.
    func testTheSkysSunIsTheLightsSunByDay() {
        for hour in stride(from: 7.0, through: 17, by: 1) {
            let light = GardenGround.Light.at(hour: hour).direction
            let sky = simd_normalize(SunPath.direction(atHour: hour))
            XCTAssertEqual(simd_dot(light, sky), 1, accuracy: 0.01, "at \(hour)")
        }
        XCTAssertLessThan(SunPath.elevation(atHour: 19), 0, "the sun is under the horizon after six")
    }

    /// No step in the colour as the sun climbs: a jump between two keyframes
    /// would be a visible flicker once an hour.
    func testThePaletteHasNoStepsInIt() {
        var previous = SkyPalette.at(elevation: 0)
        for tenth in 1...900 {
            let next = SkyPalette.at(elevation: Double(tenth) / 10)
            let jump = simd_length(next.zenith - previous.zenith) + simd_length(next.horizon - previous.horizon)
            XCTAssertLessThan(jump, 0.02, "at \(Double(tenth) / 10)°")
            previous = next
        }
    }

    /// **The zenith stays under the words.** The heading is white and stands
    /// at the top of the sky, so the top of the sky may not get much brighter
    /// than the old sky's brightest blue did.
    func testTheZenithStaysDarkEnoughForTheHeading() {
        func luminance(_ c: SIMD3<Double>) -> Double {
            func linear(_ v: Double) -> Double { v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
            return 0.2126 * linear(c.x) + 0.7152 * linear(c.y) + 0.0722 * linear(c.z)
        }
        for elevation in stride(from: 0.0, through: 90, by: 5) {
            let zenith = SkyPalette.at(elevation: elevation).zenith
            let contrast = 1.05 / (luminance(zenith) + 0.05)
            XCTAssertGreaterThan(contrast, 5.5, "white on the zenith at \(elevation)°")
        }
    }

    /// **The day's light is painted at half a pixel a point** and kept, which
    /// is what makes redrawing the sky cheap.
    func testTheDaysPictureIsSmall() {
        let image = DaySky.paint(SkyPalette.at(elevation: 30), sun: CGPoint(x: 40, y: 200),
                                 size: CGSize(width: 420, height: 912), perPoint: DaySky.perPoint)
        XCTAssertEqual(image?.width, 210)
        XCTAssertEqual(image?.height, 456)
    }

    /// **Held to two eclipses**, which are the moments the sun and moon are
    /// known to the minute to stand together and opposite: the total solar
    /// eclipse of 8 April 2024 at 18:21 UTC, and the total lunar eclipse of
    /// 3 March 2026 at 11:38 UTC.
    func testTheMoonIsWhereTheEclipsesPutIt() {
        XCTAssertEqual(RealSky.elongationOfMoon(at: Date(timeIntervalSince1970: 1_712_600_460)), 0, accuracy: 1)
        XCTAssertEqual(RealSky.elongationOfMoon(at: Date(timeIntervalSince1970: 1_772_537_880)), 180, accuracy: 1)
    }

    /// The moon's place and its phase come from two different calculations,
    /// and they have to agree about how far it stands from the sun. Not
    /// closely: the phase is one mean month against a known new moon, which
    /// ignores the orbit's eccentricity and can be most of a day out.
    func testTheMoonStandsRoughlyWhereItsPhaseSays() {
        let start = Date(timeIntervalSince1970: 1_790_000_000)
        for day in stride(from: 0, to: 60, by: 3) {
            let date = start.addingTimeInterval(Double(day) * 86_400)
            let fraction = MoonPhase.fraction(on: date)
            let expected = fraction <= 0.5 ? fraction * 360 : (1 - fraction) * 360
            XCTAssertEqual(RealSky.elongationOfMoon(at: date), expected, accuracy: 13, "day \(day)")
        }
    }

    /// The sun's declination is the season: north in June, south in December.
    func testTheSeasonIsTheRightWayRound() {
        var june = DateComponents(); june.year = 2026; june.month = 6; june.day = 21; june.hour = 12
        var december = june; december.month = 12
        let calendar = Calendar(identifier: .gregorian)
        XCTAssertEqual(RealSky.sunDeclination(calendar.date(from: june)!), 23.4, accuracy: 0.5)
        XCTAssertEqual(RealSky.sunDeclination(calendar.date(from: december)!), -23.4, accuracy: 0.5)

        let london = Place(latitude: 51.5, longitude: -0.12)
        let summer = Season(date: calendar.date(from: june)!, place: london)
        let winter = Season(date: calendar.date(from: december)!, place: london)
        XCTAssertEqual(summer.noon, 62, accuracy: 1, "the orbit's peak is London's midsummer")
        XCTAssertEqual(winter.noon, 15, accuracy: 1)
        XCTAssertGreaterThan(summer.haze, 0)
        XCTAssertLessThan(winter.haze, 0)
    }

    /// Everybody on the same day gets the same clouds.
    func testTheCloudsAreTheDays() {
        let date = Date(timeIntervalSince1970: 1_790_000_000)
        let morning = SkyClouds.day(date)
        let evening = SkyClouds.day(date.addingTimeInterval(3600 * 5))
        if SkyClouds.dayNumber(date) == SkyClouds.dayNumber(date.addingTimeInterval(3600 * 5)) {
            XCTAssertEqual(morning.weather, evening.weather)
            XCTAssertEqual(morning.clouds.count, evening.clouds.count)
        }
    }

    /// **A moment, not a screensaver.** Over a month, birds are in the sky
    /// for a few per cent of the time at most, and never not at all.
    func testBirdsAreRare() {
        let start = Date(timeIntervalSince1970: 1_790_000_000)
        var flying = 0, total = 0
        for minute in stride(from: 0, to: 30 * 24 * 60, by: 1) {
            total += 1
            if SkyLife.flight(at: start.addingTimeInterval(Double(minute) * 60), latitude: 51.5) != nil {
                flying += 1
            }
        }
        let share = Double(flying) / Double(total)
        XCTAssertLessThan(share, 0.03)
        XCTAssertGreaterThan(share, 0.002)
    }
}
