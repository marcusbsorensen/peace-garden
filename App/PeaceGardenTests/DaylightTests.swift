import XCTest
@testable import PeaceGarden

/// The Light control in Settings: sun, both, moon.
final class DaylightTests: XCTestCase {
    func testTheControlReadsDayThenClockThenNight() {
        XCTAssertEqual(GardenDaylight.allCases, [.always, .byTheClock, .alwaysNight])
    }

    func testEachAnswerDrawsTheGardenAtItsHour() {
        XCTAssertEqual(GardenDaylight.always.hour(when: 3.5), 12)
        XCTAssertEqual(GardenDaylight.byTheClock.hour(when: 3.5), 3.5)
        XCTAssertEqual(GardenDaylight.byTheClock.hour(when: 21), 21)
        XCTAssertEqual(GardenDaylight.alwaysNight.hour(when: 14), 0)
    }

    /// Stored in people's preferences; renaming a case would reset them.
    func testStoredNamesStay() {
        XCTAssertEqual(GardenDaylight.always.rawValue, "always")
        XCTAssertEqual(GardenDaylight.byTheClock.rawValue, "byTheClock")
        XCTAssertEqual(GardenDaylight.alwaysNight.rawValue, "alwaysNight")
    }
}
