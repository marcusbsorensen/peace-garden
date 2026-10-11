import SeedCore
import SwiftUI
import UIKit
import XCTest
@testable import PeaceGarden

/// **The whole row of grounds, in each of the ways it can say which is
/// chosen** — to be looked at, not asserted: `GroundMarking`.
///
/// A phone's row shows five of the eight and scrolls for the rest, so this
/// hosts the real `PlotView`, tray open, in a window wide enough for all of
/// them, at night and by day, and photographs the foot of it.
///
/// Skipped unless `PG_RENDERS` names a folder, which `xcodebuild test` passes
/// through as `TEST_RUNNER_PG_RENDERS`.
@MainActor
final class GardenControlsRenderTests: XCTestCase {

    private static let window = CGSize(width: 760, height: 912)

    func testDrawTheRowOfGroundsEachWay() async throws {
        guard let folder = ProcessInfo.processInfo.environment["PG_RENDERS"], !folder.isEmpty else {
            throw XCTSkip("PG_RENDERS is not set")
        }
        try XCTSkipUnless(GardenWorlds.shared.isLoaded)
        try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)

        let defaults = UserDefaults.standard
        let daylightBefore = defaults.string(forKey: Chrome.daylightKey)
        defer {
            defaults.set(daylightBefore, forKey: Chrome.daylightKey)
            for key in ["pgTray", "pgGrounds", "pgPlate"] { defaults.removeObject(forKey: key) }
        }
        defaults.set(true, forKey: "pgTray")

        for light in [GardenDaylight.alwaysNight, .always] {
            // Once through first and thrown away: the first window in a light
            // draws the plot in it and all eight grounds from nothing, one
            // after the other on the terrain's actor, and six seconds is not
            // long enough for that on a simulator. Every window after it is
            // handed them drawn.
            defaults.set(light.rawValue, forKey: Chrome.daylightKey)
            let warming = try Self.window(showing: PlotView().environment(Self.model()))
            try await Task.sleep(for: .seconds(20))
            warming.isHidden = true

            for marking in GroundMarking.allCases {
                defaults.set(light.rawValue, forKey: Chrome.daylightKey)
                defaults.set(marking.rawValue, forKey: "pgGrounds")
                // Today's row had no plates either.
                defaults.set(marking == .standBack ? FigurePlate.none.rawValue : FigurePlate.chosen.rawValue,
                             forKey: "pgPlate")
                let window = try Self.window(showing: PlotView().environment(Self.model()))
                try await Task.sleep(for: .seconds(6))
                let name = "grounds-\(light == .always ? "day" : "night")-\(marking.rawValue).png"
                try Self.write(window, to: URL(fileURLWithPath: folder).appendingPathComponent(name),
                               crop: CGRect(x: 0, y: Self.window.height - 330,
                                            width: Self.window.width, height: 330))
                window.isHidden = true
            }
        }
    }

    /// Fourteen plants, because a ground in the row is drawn as the plot it
    /// would be, and fourteen is a plot of 5.2 m, the size the web garden's are.
    private static func model() -> GardenModel {
        let met = Date(timeIntervalSince1970: 1_780_000_000)
        let plants = (0..<14).map { n -> PlantRecord in
            let a = SeedID(bytes: seedDigest(SeedDomain.seed, Data("grounds-a-\(n)".utf8)))!
            let b = SeedID(bytes: seedDigest(SeedDomain.seed, Data("grounds-b-\(n)".utf8)))!
            let encounter = Pollination.encounterID(seedA: a, seedB: b,
                                                    nonceA: Data("na\(n)".utf8), nonceB: Data("nb\(n)".utf8))
            return PlantRecord(
                id: UUID(),
                seed: Pollination.cross(seedA: a, seedB: b, encounterID: encounter),
                lineage: .crossed(parentA: a, parentB: b, encounterID: encounter),
                birth: met, savedAt: met,
                encounter: EncounterNote(peerDisplayName: "Ash", happenedAt: met, place: "Here")
            )
        }
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("grounds-\(UUID().uuidString).json")
        let store = GardenStore(fileURL: file)
        try? store.save(Garden(identity: nil, plants: plants, beds: [Bed(name: "", world: 0)]))
        return GardenModel(store: store)
    }

    private static func window(showing view: some View) throws -> UIWindow {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(origin: .zero, size: Self.window)
        window.windowLevel = .alert + 1
        window.rootViewController = UIHostingController(rootView: view)
        window.makeKeyAndVisible()
        return window
    }

    private static func write(_ window: UIWindow, to url: URL, crop: CGRect) throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        format.opaque = true
        let image = UIGraphicsImageRenderer(size: crop.size, format: format).image { _ in
            window.drawHierarchy(in: CGRect(origin: CGPoint(x: -crop.minX, y: -crop.minY),
                                            size: window.bounds.size),
                                 afterScreenUpdates: true)
        }
        try XCTUnwrap(image.pngData()).write(to: url)
    }
}
