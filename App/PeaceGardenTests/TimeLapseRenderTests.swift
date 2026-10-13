import SeedCore
import SwiftUI
import UIKit
import XCTest
@testable import PeaceGarden

/// **The pictures in `design/time-lapse-2026-10-13/`.**
///
/// Skipped unless `PG_RENDER_TIMELAPSE` names a folder (passed to the test
/// runner as `TEST_RUNNER_PG_RENDER_TIMELAPSE`). Writes film frames as PNGs with
/// a line of notes each; `design/time-lapse-2026-10-13/compose.py` lays them out
/// and labels them. The luminance chart's numbers come from
/// `TimeLapseLuminanceTests`, which writes them to the same folder.
@MainActor
final class TimeLapseRenderTests: XCTestCase {
    /// A plant two days old and one five months old, at three in the afternoon.
    static let young = TimeLapseTests.plant("young", days: 2)
    static let old = TimeLapseTests.plant("old", days: 150)
    static let size = CGSize(width: 420, height: 912)

    func testDrawTheStrips() async throws {
        let folder = try Self.folder()
        for (name, record, reduceMotion) in [("young", Self.young, false), ("old", Self.old, false),
                                             ("old-reduce-motion", Self.old, true)] {
            var options = TimeLapseFilm.Options()
            options.size = Self.size
            options.fps = 60
            options.calendar = TimeLapseTests.utc
            options.reduceMotion = reduceMotion
            // Nine moments through the growing, at an eighth of it apart, and
            // the first frame of the rest.
            let wanted = (0...8).map { TimeLapse.leadIn + (TimeLapse.growthEnd - TimeLapse.leadIn) * Double($0) / 8 }
            var notes: [String] = []
            try await TimeLapseFilm.render(record, now: TimeLapseLuminanceTests.moment(hour: 15),
                                           options: options) { frame in
                guard let slot = wanted.firstIndex(where: { abs($0 - frame.time) < 0.5 / 60 }) else { return }
                try Self.write(frame.image, to: folder.appendingPathComponent("strip-\(name)-\(slot).png"))
                let growth = TimeLapse(record: record, now: TimeLapseLuminanceTests.moment(hour: 15),
                                       calendar: TimeLapseTests.utc)
                    .frame(at: frame.time, reduceMotion: reduceMotion).growth
                notes.append(String(format: "%d,%.3f,%.4f,%.4f", slot, frame.time, frame.progress, growth.heightScale))
            }
            try (["slot,time,progress,height"] + notes).joined(separator: "\n")
                .write(to: folder.appendingPathComponent("strip-\(name).csv"), atomically: true, encoding: .utf8)
        }
    }

    /// A, B and C side by side: the old plant, six moments of each drift, at
    /// three in the afternoon — and A again at ten at night, where it settles
    /// into the dark rather than brightening.
    func testDrawTheThreeSkies() async throws {
        let folder = try Self.folder()
        let rows: [(String, SkyDrift, Int, ColorScheme)] = [
            ("A-15", .towardsNow, 15, .dark), ("A-22", .towardsNow, 22, .dark),
            ("B-15", .nightIntoDay, 15, .dark), ("C-15", .still, 15, .dark), ("A-15-light", .towardsNow, 15, .light)
        ]
        let wanted = [0.6, 2.4, 4.4, 6.4, 8.4, 10.4]
        for (name, drift, hour, scheme) in rows {
            var options = TimeLapseFilm.Options()
            options.size = CGSize(width: 280, height: 608)
            options.fps = 30
            options.drift = drift
            options.scheme = scheme
            options.calendar = TimeLapseTests.utc
            try await TimeLapseFilm.render(Self.old, now: TimeLapseLuminanceTests.moment(hour: hour),
                                           options: options) { frame in
                guard let slot = wanted.firstIndex(where: { abs($0 - frame.time) < 0.5 / 30 }) else { return }
                try Self.write(frame.image, to: folder.appendingPathComponent("sky-\(name)-\(slot).png"))
            }
            // Every frame's luminance, for the chart beside them.
            var values: [String] = ["time,luminance"]
            options.size = CGSize(width: 64, height: 139)
            options.fps = 60
            try await TimeLapseFilm.render(Self.old, now: TimeLapseLuminanceTests.moment(hour: hour),
                                           options: options) { frame in
                values.append(String(format: "%.4f,%.6f", frame.time, TimeLapseLuminance.mean(of: frame.image, side: 64)))
            }
            try values.joined(separator: "\n")
                .write(to: folder.appendingPathComponent("sky-\(name).csv"), atomically: true, encoding: .utf8)
        }
    }

    /// The plant's own screen, held on the simulator to be photographed from
    /// outside (`xcrun simctl io … screenshot`), and the time-lapse played on
    /// it with a tap. Skipped unless `PG_HOLD_PLANT_SCREEN` is set: it waits.
    func testHoldThePlantScreen() async throws {
        guard ProcessInfo.processInfo.environment["PG_HOLD_PLANT_SCREEN"] != nil else {
            throw XCTSkip("PG_HOLD_PLANT_SCREEN is not set")
        }
        let folder = try Self.folder()
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("time-lapse-\(UUID().uuidString).json")
        let store = GardenStore(fileURL: file)
        try store.save(Garden(identity: nil, plants: [Self.old], beds: [Bed(name: "", world: 0)]))
        let model = GardenModel(store: store)
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.rootViewController = UIHostingController(
            rootView: PlantDetailView(record: Self.old).environment(model).preferredColorScheme(.dark)
        )
        window.makeKeyAndVisible()
        try "ready".write(to: folder.appendingPathComponent("holding"), atomically: true, encoding: .utf8)
        try await Task.sleep(for: .seconds(150))
        window.isHidden = true
    }

    static func folder() throws -> URL {
        guard let folder = TimeLapseLuminanceTests.output else { throw XCTSkip("PG_RENDER_TIMELAPSE is not set") }
        return folder
    }

    static func write(_ image: CGImage, to url: URL) throws {
        try XCTUnwrap(UIImage(cgImage: image).pngData()).write(to: url)
    }
}
