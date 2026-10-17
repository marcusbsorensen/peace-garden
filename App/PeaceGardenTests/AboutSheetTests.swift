import SeedCore
import SwiftUI
import XCTest
@testable import PeaceGarden

/// The About sheet (Marcus, 14 October 2026: 4A and 5A): reached from the foot
/// of Settings and from the ⓘ beside *Location description*, and holding, under
/// Privacy, the account Settings let go on 13 October.
///
/// Read through the accessibility tree of a real Settings screen in a window,
/// so what is tested is what is touched.
@MainActor
final class AboutSheetTests: XCTestCase {
    private var host: AccessibilityHost!

    /// The account of a meeting, the catalogue's key: *made*, not *drawn*.
    private static let meeting = "When you meet someone, your phones connect directly, encrypted, and each hands the other its seed, when that seed was made, its plant's name, the name you chose to show, whether a place may be kept with the meeting, and two random numbers: one that makes the new plant, and one the other phone can use later to offer that plant to the web garden. Each phone keeps both second numbers with the plant, and a number for the meeting made from the first two."
    private static let coordinates = "A seed planted while this is on carries the coordinates the phone measured, to five decimal places. Nothing is looked up and no place is named — the numbers are the honest record, and a map can say the rest."

    /// The paragraph on the request at each start (Marcus, 17 October 2026,
    /// word for word), which follows the one on a logged place.
    private static let asking = "Each time the app starts, it asks the web garden for news. The request carries two random-looking values, and the answer brings back a handful of each. Seeds that reach you from Autonaut, and the plants they grow, are kept with your garden in your phone's backups."

    override func setUp() async throws {
        try await super.setUp()
        host = AccessibilityHost()
    }

    override func tearDown() async throws {
        host.tearDown()
        host = nil
        try await super.tearDown()
    }

    /// Settings on a garden of its own, in a temporary file.
    private func settings() -> some View {
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("about-\(UUID().uuidString).json")
        let store = GardenStore(fileURL: file)
        try? store.save(Garden(identity: nil, plants: []))
        let model = GardenModel(store: store)
        return SettingsView(close: {})
            .environment(model)
            .environment(PlaceKeeping())
    }

    /// What the sheet must show once it is up: its heading, Privacy, and both
    /// paragraphs, in the words the catalogue translates.
    private func assertTheSheetShowsPrivacy(file: StaticString = #filePath, line: UInt = #line) async throws {
        let meeting = try await host.element(String(localized: String.LocalizationValue(Self.meeting)))
        XCTAssertNotNil(meeting, "the account of a meeting is on the sheet", file: file, line: line)
        let found = host.elements()
        XCTAssertNotNil(found[String(localized: String.LocalizationValue(Self.coordinates))],
                        "and the paragraph on coordinates", file: file, line: line)
        XCTAssertNotNil(found[String(localized: "Privacy")], "under Privacy", file: file, line: line)
    }

    /// **From the foot of Settings.**
    func testTheRowAtTheFootOpensAbout() async throws {
        try await host.show(settings())
        XCTAssertNil(host.elements()[Self.meeting], "the account is not on Settings itself")

        let row = try XCTUnwrap(host.elements()[String(localized: "About")], "About is at the foot of Settings: \(host.elements().keys.sorted())")
        XCTAssertTrue(row.accessibilityTraits.contains(.button))
        XCTAssertTrue(row.accessibilityActivate())
        try await assertTheSheetShowsPrivacy()
    }

    /// **From the ⓘ beside *Location description***, read as *Privacy*, which
    /// is where it opens the sheet.
    func testTheMarkBesideLocationDescriptionOpensAboutAtPrivacy() async throws {
        try await host.show(settings())
        let mark = try XCTUnwrap(host.elements()[String(localized: "Privacy")],
                                 "the ⓘ beside Location description is read as Privacy")
        XCTAssertTrue(mark.accessibilityTraits.contains(.button))
        XCTAssertTrue(mark.accessibilityActivate())
        try await assertTheSheetShowsPrivacy()
    }

    /// The sheet on its own, opened at Privacy: the heading, the section, both
    /// paragraphs, and the circled X that closes it.
    func testTheSheetHoldsTheAccountAndClosesWithTheX() async throws {
        var closed = false
        try await host.show(AboutView(startsAt: .privacy) { closed = true })
        try await assertTheSheetShowsPrivacy()
        let found = host.elements()
        let heading = try XCTUnwrap(found[String(localized: "About")])
        XCTAssertTrue(heading.accessibilityTraits.contains(.header))

        let close = try XCTUnwrap(found.first { $0.value.accessibilityTraits.contains(.button) }?.value,
                                  "the X is the sheet's one button")
        XCTAssertTrue(close.accessibilityActivate())
        try await Task.sleep(for: .milliseconds(200))
        XCTAssertTrue(closed)
    }

    /// **The request at each start is said under Privacy, after the logged
    /// place**, and Settings keeps to its one short line.
    func testThePrivacyPartSaysWhatTheAppAsksAtEachStart() async throws {
        try await host.show(AboutView(startsAt: .privacy) {})
        try await assertTheSheetShowsPrivacy()
        let found = host.elements()
        let coordinates = try XCTUnwrap(found[String(localized: String.LocalizationValue(Self.coordinates))])
        let asking = try XCTUnwrap(found[String(localized: String.LocalizationValue(Self.asking))],
                                   "the paragraph is on the sheet: \(found.keys.sorted())")
        XCTAssertGreaterThan(asking.accessibilityFrame.minY, coordinates.accessibilityFrame.minY,
                             "after the paragraph on a logged place")
    }

    func testSettingsDoesNotCarryThatParagraph() async throws {
        try await host.show(settings())
        XCTAssertNil(host.elements()[String(localized: String.LocalizationValue(Self.asking))])
    }

    /// The account is the catalogue's translated key, which says *made*, and
    /// the paragraph on coordinates is no longer stale there.
    func testTheWordsAreTheCataloguesTranslatedOnes() throws {
        let url = try XCTUnwrap(Bundle(for: GardenModel.self).url(forResource: "Localizable", withExtension: "strings",
                                                                   subdirectory: nil, localization: "da"),
                                "the Danish strings are in the app")
        let danish = try XCTUnwrap(NSDictionary(contentsOf: url) as? [String: String])
        for key in [Self.meeting, Self.coordinates, "About", "Privacy"] {
            let value = try XCTUnwrap(danish[key], "\(key.prefix(40)) is translated into Danish")
            XCTAssertNotEqual(value, key)
        }
        XCTAssertTrue(Self.meeting.contains("when that seed was made"))
    }
}
