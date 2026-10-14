import SeedCore
import SwiftUI
import XCTest
@testable import PeaceGarden

/// Share on the stage (Marcus, 14 October 2026: 13A): the mark a plant's own
/// screen has beside Close, top right on the stage, for your own plant.
///
/// On a simulator the stage's row is always up (`PlantStageView`), so the mark
/// that comes and goes with it is up too.
@MainActor
final class StageShareTests: XCTestCase {
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

    func testTheStageHasTheShareMarkTopRight() async throws {
        let seed = try XCTUnwrap(SeedID(bytes: seedDigest(SeedDomain.seed, Data("stage-share".utf8))))
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("stage-share-\(UUID().uuidString).json")
        let store = GardenStore(fileURL: file)
        try store.save(Garden(identity: Identity(seed: seed, birth: Date().addingTimeInterval(-30 * 86_400),
                                                 displayName: "Gardener"),
                              plants: []))
        let model = GardenModel(store: store)
        try await host.show(PlantStageView().environment(model).environment(PlaceKeeping()))

        let found = try await host.element(String(localized: "Share"))
        let share = try XCTUnwrap(found, "the Share mark is on the stage: \(host.elements().keys.sorted())")
        let frame = share.accessibilityFrame
        XCTAssertGreaterThan(frame.midX, AccessibilityHost.screen.width * 0.75, "at the right: \(frame)")
        XCTAssertLessThan(frame.midY, AccessibilityHost.screen.height * 0.2, "at the top: \(frame)")
    }
}
