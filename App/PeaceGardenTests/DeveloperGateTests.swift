import StoreKit
import XCTest
import SeedCore
@testable import PeaceGarden

/// Who gets the developer controls (12 October 2026).
///
/// - **A TestFlight copy does, an App Store copy does not, and a check that
///   fails does not.** `Developer.isTestFlight` is the decision with the
///   install's environment handed in, so each answer StoreKit could give is
///   tried here without being installed from anywhere.
/// - **Where the gate is shut, every control reads as off**: the clock as no
///   shift whatever was kept, the switches as unset, the meeting as unasked.
///   A Debug build cannot be an App Store copy, so it stands in for one
///   (`standsInForAppStore`).
/// - **The imaginary meeting is the real crossing**, and the plant it grows
///   is remembered as imaginary — the one thing the web-garden decision will
///   need to tell it from a real one.
@MainActor
final class DeveloperGateTests: XCTestCase {

    private struct StoreKitDown: Error {}

    // MARK: Where the copy came from

    func testATestFlightCopyHasThem() async {
        let shown = await Developer.isTestFlight { .sandbox }
        XCTAssertTrue(shown)
    }

    func testAnAppStoreCopyDoesNot() async {
        let shown = await Developer.isTestFlight { .production }
        XCTAssertFalse(shown)
    }

    /// StoreKit's local testing is no copy on anybody's phone.
    func testStoreKitTestingDoesNot() async {
        let shown = await Developer.isTestFlight { .xcode }
        XCTAssertFalse(shown)
    }

    func testAFailedCheckDoesNot() async {
        let shown = await Developer.isTestFlight { throw StoreKitDown() }
        XCTAssertFalse(shown)
    }

    func testADebugBuildAlwaysHasThem() {
        XCTAssertTrue(Developer.isAvailable)
    }

    // MARK: Where the gate is shut

    func testAnAppStoreCopyRunsOnTheWallClock() {
        let developer = Developer.shared
        let before = developer.clockShift
        defer {
            developer.standsInForAppStore = false
            developer.backToNow()
            developer.advance(by: before)
        }
        developer.backToNow()
        developer.advance(by: 30 * 86_400)

        developer.standsInForAppStore = true
        XCTAssertEqual(developer.clockShift, 0)
        XCTAssertEqual(Developer.now.timeIntervalSinceNow, 0, accuracy: 1)
        // And it cannot be wound on from there.
        developer.advance(by: 86_400)

        developer.standsInForAppStore = false
        XCTAssertEqual(developer.clockShift, 30 * 86_400,
                       "what a TestFlight copy kept is ignored by an App Store one, not altered")
    }

    func testAnAppStoreCopyShowsNoSwitchesAndMeetsNobodyImaginary() {
        let developer = Developer.shared
        let grid = developer.showsTileGrid
        let oldDay = developer.showsTheOldDay
        let section = developer.showsSection
        defer {
            developer.standsInForAppStore = false
            developer.showsTileGrid = grid
            developer.showsTheOldDay = oldDay
            developer.showsSection = section
            developer.wantsImaginaryMeeting = false
        }
        developer.showsTileGrid = true
        developer.showsTheOldDay = true
        developer.showsSection = true
        developer.wantsImaginaryMeeting = true

        developer.standsInForAppStore = true
        XCTAssertFalse(developer.showsTileGrid)
        XCTAssertFalse(developer.showsTheOldDay)
        XCTAssertFalse(developer.showsSection)
        XCTAssertFalse(developer.wantsImaginaryMeeting)
    }

    // MARK: The imaginary meeting

    func testAnImaginaryMeetingGrowsARealCrossAndIsRemembered() throws {
        let service = PollenExchangeService()
        defer { service.stop() }
        let identity = Identity(seed: SeedMint.mintOnThisDevice(), birth: Date(), displayName: "Tester")

        service.meetAnImaginaryGardener(as: identity)
        guard case .awaitingTouch(let name) = service.phase else {
            return XCTFail("expected to wait for the knock, got \(service.phase)")
        }
        XCTAssertTrue(PollenExchangeService.imaginaryNames.contains(name))

        service.standInForTouch()
        guard case .grown(let outcome) = service.phase else {
            return XCTFail("expected a plant, got \(service.phase)")
        }
        defer { Self.forget(outcome.result.childSeed) }

        XCTAssertNotEqual(outcome.result.childSeed, identity.seed)
        XCTAssertNotNil(outcome.tokens, "a plant that can be carried through the sharing flow")
        XCTAssertTrue(Developer.shared.grewImaginary(outcome.result.childSeed))
        XCTAssertFalse(Developer.shared.grewImaginary(identity.seed))
    }

    /// Takes a test's plant back out of the list, so the next run starts clean.
    private static func forget(_ seed: SeedID) {
        let key = "developer.imaginarySeeds"
        let kept = UserDefaults.standard.stringArray(forKey: key) ?? []
        UserDefaults.standard.set(kept.filter { $0 != seed.hex }, forKey: key)
    }
}
