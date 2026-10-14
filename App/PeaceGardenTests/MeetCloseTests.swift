import SwiftUI
import XCTest
@testable import PeaceGarden

/// The way out of Meet (Marcus, 14 October 2026: 3A): the circled X while it
/// looks for somebody, as every other screen closes, and the words *Not this
/// time* over a plant just made, the one moment closing leaves something
/// unkept.
@MainActor
final class MeetCloseTests: XCTestCase {
    private var host: AccessibilityHost!

    override func setUp() async throws {
        try await super.setUp()
        host = AccessibilityHost()
    }

    override func tearDown() async throws {
        host.tearDown()
        host = nil
        try await super.tearDown()
    }

    /// **Over a plant just made, the corner is the words**: a button read as
    /// *Not this time*, as wide as its words in their capsule rather than the
    /// X's forty-two-point ring.
    func testOverAPlantJustMadeTheCornerSaysNotThisTime() async throws {
        var closed = false
        try await host.show(MeetCloseControl(overAPlantJustMade: true) { closed = true })
        let found = host.elements()

        let words = try XCTUnwrap(found[String(localized: "Not this time")], "the words are on screen: \(found.keys.sorted())")
        XCTAssertNil(found[String(localized: "Cancel")], "and not the X")
        XCTAssertGreaterThan(words.accessibilityFrame.width, 80,
                             "drawn as words in a capsule, not as a ring: \(words.accessibilityFrame)")
        XCTAssertTrue(words.accessibilityTraits.contains(.button))
        XCTAssertTrue(words.accessibilityActivate())
        try await Task.sleep(for: .milliseconds(200))
        XCTAssertTrue(closed, "it closes Meet, as the X does")
    }

    /// **Everywhere else on Meet, the circled X**, read as *Cancel*.
    func testWhileLookingTheCornerIsTheCircledX() async throws {
        try await host.show(MeetCloseControl(overAPlantJustMade: false) {})
        let found = host.elements()

        let ring = try XCTUnwrap(found[String(localized: "Cancel")], "the X is read as Cancel")
        XCTAssertNil(found[String(localized: "Not this time")])
        XCTAssertLessThan(ring.accessibilityFrame.width, 60,
                          "the forty-two-point ring: \(ring.accessibilityFrame)")
    }
}
