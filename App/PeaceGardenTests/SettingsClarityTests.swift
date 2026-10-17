import SwiftUI
import XCTest
@testable import PeaceGarden

/// Settings as Marcus asked for it on 13 October 2026: *Location description*
/// with one line for the chosen answer, and the two lights in colour.
final class SettingsClarityTests: XCTestCase {
    /// The line under the menu is the chosen answer's, and only its.
    func testEachAnswerHasItsOwnLine() {
        XCTAssertEqual(PlantingLocationMode.abstract.note.key,
                       "Where you met is given as a place from the abstract list.")
        XCTAssertEqual(PlantingLocationMode.geographic.note.key,
                       "Where you met is logged on this phone as the coordinates it measured, when you both ask.")
        XCTAssertEqual(PlantingLocationMode.custom.note.key,
                       "What you write here is kept in this phone's settings, and for now it appears only there.")
        let lines = Set(PlantingLocationMode.allCases.map { $0.note.key })
        XCTAssertEqual(lines.count, PlantingLocationMode.allCases.count)
    }

    func testTheAnswersAreMarcussWords() {
        XCTAssertEqual(PlantingLocationMode.allCases.map { $0.label.key },
                       ["A place from abstract list", "Where you actually are", "Something you write"])
    }

    /// Stored in people's preferences; renaming a case would reset them.
    func testStoredNamesStay() {
        XCTAssertEqual(PlantingLocationMode.abstract.rawValue, "abstract")
        XCTAssertEqual(PlantingLocationMode.geographic.rawValue, "geographic")
        XCTAssertEqual(PlantingLocationMode.custom.rawValue, "custom")
    }

    /// Stored in people's preferences; the label moved on 17 October 2026 and
    /// the key did not, so nobody's choice did either (A5). Zone C's own switch
    /// has a key of its own and is off until it is turned on.
    func testTheTwoSwitchesKeepTheirStoredNames() {
        XCTAssertEqual(Sharing.invitationsKey, "sharing.invitations.v1")
        XCTAssertEqual(ZoneCExchange.enabledKey, "zonec.enabled.v1")
        XCTAssertTrue(Sharing.invitationsDefault)

        let before = UserDefaults.standard.object(forKey: ZoneCExchange.enabledKey)
        defer {
            if let before {
                UserDefaults.standard.set(before, forKey: ZoneCExchange.enabledKey)
            } else {
                UserDefaults.standard.removeObject(forKey: ZoneCExchange.enabledKey)
            }
        }
        UserDefaults.standard.removeObject(forKey: ZoneCExchange.enabledKey)
        XCTAssertFalse(ZoneCExchange.switchFromDefaults(), "consent cannot start on")
    }

    /// The sun is orange and the moon yellow, and the middle answer has both.
    func testEachLightTakesItsOwnColour() {
        XCTAssertEqual(GardenDaylight.always.parts.map { $0.light }, [.sun])
        XCTAssertEqual(GardenDaylight.byTheClock.parts.map { $0.light }, [.sun, .moon])
        XCTAssertEqual(GardenDaylight.alwaysNight.parts.map { $0.light }, [.moon])
    }

    /// Drawn a light at a time, the middle mark is still the whole mark, with
    /// the sun up and to the leading side of the moon.
    func testTheSunAndTheMoonMakeTheWholeMark() {
        let rect = CGRect(x: 0, y: 0, width: 22, height: 22)
        let whole = SunAndMoonGlyph().path(in: rect).boundingRect
        let sun = SunAndMoonGlyph(part: .sun).path(in: rect).boundingRect
        let moon = SunAndMoonGlyph(part: .moon).path(in: rect).boundingRect
        let both = sun.union(moon)

        XCTAssertEqual(both.minX, whole.minX, accuracy: 0.001)
        XCTAssertEqual(both.minY, whole.minY, accuracy: 0.001)
        XCTAssertEqual(both.maxX, whole.maxX, accuracy: 0.001)
        XCTAssertEqual(both.maxY, whole.maxY, accuracy: 0.001)
        XCTAssertLessThan(sun.midX, moon.midX)
        XCTAssertLessThan(sun.midY, moon.midY)
    }
}
