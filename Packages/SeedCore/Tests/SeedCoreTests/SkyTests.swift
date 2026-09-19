import XCTest
@testable import SeedCore

/// The real sky.
///
/// **Checked against things that are true of the sky rather than against
/// numbers this code produced.** A test that pins what the arithmetic
/// currently returns proves the arithmetic has not changed; these prove it is
/// right. Polaris stands at your latitude. A star on the celestial equator
/// rises due east. The sky turns fifteen degrees an hour. Sirius is where the
/// catalogue has always said Sirius is.
final class SkyTests: XCTestCase {

    // MARK: The sky's own clock

    func testSiderealTimeTurnsOnceADayAndABit() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let solarDayLater = start.addingTimeInterval(86_400)

        let first = Sky.greenwichSiderealTime(at: start)
        let second = Sky.greenwichSiderealTime(at: solarDayLater)

        // A sidereal day is 3 minutes 56 seconds shorter than a solar one, so
        // in one solar day the sky has turned a full circle and 0.9856° more.
        XCTAssertEqual(Sky.offset(from: first, to: second), 0.9856, accuracy: 0.001)
    }

    func testTheSkyTurnsFifteenDegreesAnHour() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let hour = Sky.greenwichSiderealTime(at: start.addingTimeInterval(3_600))
        let now = Sky.greenwichSiderealTime(at: start)
        XCTAssertEqual(Sky.offset(from: now, to: hour), 15.041, accuracy: 0.001)
    }

    func testGreenwichSiderealTimeAtAKnownInstant() {
        // J2000.0 exactly: 2000 January 1 at 12:00 UT. The IAU value for
        // Greenwich mean sidereal time then is 18h 41m 50.55s, which is
        // 280.46062 degrees — the leading term of the series, and the one
        // moment it is the whole of it.
        let j2000 = Date(timeIntervalSince1970: 946_728_000)
        XCTAssertEqual(Sky.greenwichSiderealTime(at: j2000), 280.46062, accuracy: 0.0005)
    }

    func testLongitudeMovesTheClockAndNothingElse() {
        let when = Date(timeIntervalSince1970: 1_700_000_000)
        let greenwich = Sky.siderealTime(at: when, longitude: 0)
        let ninetyEast = Sky.siderealTime(at: when, longitude: 90)
        XCTAssertEqual(Sky.offset(from: greenwich, to: ninetyEast), 90, accuracy: 1e-9)
    }

    // MARK: Where a star stands

    func testPolarisStandsAtYourLatitude() {
        // The oldest piece of navigation there is: the pole star's height above
        // the horizon *is* your latitude. Polaris is three quarters of a degree
        // off the true pole, so it circles that much either side of it.
        let polaris = Star(rightAscension: 37.9529, declination: 89.2642,
                           magnitude: 2.02, colourIndex: 0.6)
        for latitude in [0.0, 23.5, 51.5, 78.0] {
            for hours in stride(from: 0.0, to: 24.0, by: 3.0) {
                let place = Sky.horizon(
                    rightAscension: polaris.rightAscension,
                    declination: polaris.declination,
                    siderealTime: hours * 15,
                    latitude: latitude
                )
                XCTAssertEqual(place.altitude, latitude, accuracy: 0.75,
                               "Polaris at latitude \(latitude), sidereal \(hours)h")
            }
        }
    }

    func testAStarOnTheCelestialEquatorRisesDueEast() {
        // True at every latitude, which is what makes it worth testing: a star
        // with no declination rises at 90° and sets at 270°, whoever is looking.
        for latitude in [-45.0, 0.0, 51.5] {
            // Rising is six hours of hour angle before it transits.
            let rising = Sky.horizon(rightAscension: 0, declination: 0,
                                     siderealTime: 270, latitude: latitude)
            XCTAssertEqual(rising.altitude, 0, accuracy: 1e-9)
            XCTAssertEqual(rising.azimuth, 90, accuracy: 1e-9, "rising at \(latitude)")

            let setting = Sky.horizon(rightAscension: 0, declination: 0,
                                      siderealTime: 90, latitude: latitude)
            XCTAssertEqual(setting.altitude, 0, accuracy: 1e-9)
            XCTAssertEqual(setting.azimuth, 270, accuracy: 1e-9, "setting at \(latitude)")
        }
    }

    func testAStarTransitsDueSouthFromTheNorthAndDueNorthFromTheSouth() {
        // At its highest, a star stands on the meridian. Which way that is
        // depends on whether it passes north or south of you.
        let overhead = Sky.horizon(rightAscension: 0, declination: 10,
                                   siderealTime: 0, latitude: 51.5)
        XCTAssertEqual(overhead.altitude, 90 - 51.5 + 10, accuracy: 1e-9)
        XCTAssertEqual(overhead.azimuth, 180, accuracy: 1e-9)

        let fromTheSouth = Sky.horizon(rightAscension: 0, declination: 10,
                                       siderealTime: 0, latitude: -30)
        XCTAssertEqual(fromTheSouth.altitude, 90 - 40, accuracy: 1e-9)
        XCTAssertEqual(fromTheSouth.azimuth, 0, accuracy: 1e-9)
    }

    func testTheHalfOfTheSkyUnderYourFeetIsKept() {
        // The point of drawing the whole sphere: a star below the horizon has a
        // negative altitude and is not thrown away. It is somebody else's
        // overhead — the antipode's, near enough.
        let under = Sky.horizon(rightAscension: 0, declination: 0,
                                siderealTime: 180, latitude: 51.5)
        XCTAssertEqual(under.altitude, -(90 - 51.5), accuracy: 1e-9)
    }

    func testTheSkyOverheadIsTheSkyUnderfootAtTheAntipode() {
        let here = Place(latitude: 51.5, longitude: -0.13)
        let there = here.antipode
        XCTAssertEqual(there.latitude, -51.5, accuracy: 1e-9)
        XCTAssertEqual(there.longitude, 179.87, accuracy: 1e-9)

        // One sidereal instant, one star: as high above them as it is below us.
        let when = Date(timeIntervalSince1970: 1_700_000_000)
        let star = Star(rightAscension: 101.287, declination: -16.716, magnitude: -1.46, colourIndex: 0)
        let above = Sky.horizon(
            rightAscension: star.rightAscension, declination: star.declination,
            siderealTime: Sky.siderealTime(at: when, longitude: here.longitude),
            latitude: here.latitude
        )
        let below = Sky.horizon(
            rightAscension: star.rightAscension, declination: star.declination,
            siderealTime: Sky.siderealTime(at: when, longitude: there.longitude),
            latitude: there.latitude
        )
        XCTAssertEqual(above.altitude, -below.altitude, accuracy: 1e-6)
    }

    func testFacingIsTowardsTheEquator() {
        XCTAssertEqual(Sky.facing(fromLatitude: 51.5), 180)
        XCTAssertEqual(Sky.facing(fromLatitude: -33.9), 0)
    }

    // MARK: The catalogue

    func testTheCatalogueDecodesToTheStarsItWasMadeFrom() throws {
        let stars = try StarCatalogue.decode(packed())
        XCTAssertEqual(stars.count, 3)

        // Sirius, and the packing has not moved it further than its own
        // resolution: 20 arcseconds in right ascension, 10 in declination.
        XCTAssertEqual(stars[0].rightAscension, 101.287, accuracy: 20.0 / 3600)
        XCTAssertEqual(stars[0].declination, -16.716, accuracy: 10.0 / 3600)
        XCTAssertEqual(stars[0].magnitude, -1.46, accuracy: 1.0 / 32)
        XCTAssertEqual(stars[0].colourIndex, 0.0, accuracy: 0.02)
    }

    func testARightAscensionNearTheWrapDecodesWhereItBelongs() throws {
        // 359.99° is a quarter of an arcminute from zero and must not come back
        // as 360 or as something negative.
        let stars = try StarCatalogue.decode(packed())
        XCTAssertEqual(stars[2].rightAscension, 359.99, accuracy: 20.0 / 3600)
        XCTAssertTrue((0..<360).contains(stars[2].rightAscension))
    }

    func testSomethingThatIsNotACatalogueIsRefused() {
        XCTAssertThrowsError(try StarCatalogue.decode(Data("not a catalogue".utf8))) {
            XCTAssertEqual($0 as? StarCatalogue.Trouble, .notACatalogue)
        }
    }

    func testACatalogueCutShortIsRefusedRatherThanReadPast() {
        var short = packed()
        short.removeLast(4)
        XCTAssertThrowsError(try StarCatalogue.decode(short)) {
            XCTAssertEqual($0 as? StarCatalogue.Trouble, .truncated)
        }
    }

    // MARK: Where somebody is

    func testATimeZoneIsAPlace() throws {
        let london = try XCTUnwrap(Whereabouts.place(ofZone: "Europe/London"))
        XCTAssertEqual(london.latitude, 51.5, accuracy: 0.2)
        XCTAssertEqual(london.longitude, -0.13, accuracy: 0.2)

        let sydney = try XCTUnwrap(Whereabouts.place(ofZone: "Australia/Sydney"))
        XCTAssertLessThan(sydney.latitude, 0, "Sydney is in the southern hemisphere")
        XCTAssertGreaterThan(sydney.longitude, 150)
    }

    func testEveryZoneInTheTableIsSomewhereOnTheGlobe() {
        XCTAssertGreaterThan(Whereabouts.byZone.count, 350)
        for (name, place) in Whereabouts.byZone {
            XCTAssertTrue((-90...90).contains(place.latitude), "\(name) latitude")
            XCTAssertTrue((-180...180).contains(place.longitude), "\(name) longitude")
        }
    }

    func testAZoneNobodyHasHeardOfStillGivesALongitude() {
        // The fallback: the longitude from the standard offset, and the equator
        // for a latitude nobody can guess.
        let invented = TimeZone(secondsFromGMT: 5 * 3600)!
        let place = Whereabouts.place(of: invented)
        XCTAssertEqual(place.longitude, 75, accuracy: 0.001)
        XCTAssertEqual(place.latitude, 0)
    }

    func testDaylightSavingDoesNotMoveAnybody() {
        // The one that would be wrong twice a year and right the rest of the
        // time, which is the hardest kind of wrong to notice.
        let london = TimeZone(identifier: "Europe/London")!
        let january = Date(timeIntervalSince1970: 1_704_110_400)
        let july = Date(timeIntervalSince1970: 1_719_792_000)
        XCTAssertEqual(Whereabouts.place(of: london, at: january),
                       Whereabouts.place(of: london, at: july))
    }

    // MARK: A catalogue to test against

    private func packed() -> Data {
        var bytes = Data("PGSKY1".utf8)
        bytes.append(contentsOf: [3, 0, 0, 0])
        func star(_ ra: Double, _ dec: Double, _ magnitude: Double, _ colour: Double) {
            let r = UInt16((ra / 360 * 65_536).rounded())
            let d = Int16((dec / 90 * 32_767).rounded())
            bytes.append(contentsOf: [UInt8(r & 0xff), UInt8(r >> 8)])
            let dd = UInt16(bitPattern: d)
            bytes.append(contentsOf: [UInt8(dd & 0xff), UInt8(dd >> 8)])
            bytes.append(UInt8(((magnitude + 2) * 16).rounded()))
            bytes.append(UInt8(bitPattern: Int8((colour * 50).rounded())))
        }
        star(101.287, -16.716, -1.46, 0.0)      // Sirius
        star(37.953, 89.264, 2.02, 0.6)         // Polaris
        star(359.99, -0.5, 4.0, -0.2)           // just short of the wrap
        return bytes
    }
}
