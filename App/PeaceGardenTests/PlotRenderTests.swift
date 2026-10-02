import SeedCore
import SwiftUI
import UIKit
import XCTest
@testable import PeaceGarden

/// **The whole plot, plants and figures standing on it, drawn as the app draws
/// it** — to be looked at, not asserted.
///
/// Every other render test draws one part: the worlds alone, a light alone.
/// What a shadow looks like is a question about all of them together — the
/// ground it falls on, the plant beside it, the rim it stops at — so this hosts
/// the real `PlotView` in a window of its own, lets it fetch its pictures the
/// way it does on a phone, and photographs it.
///
/// Skipped unless `PG_RENDERS` names a folder, which `xcodebuild test` passes
/// through as `TEST_RUNNER_PG_RENDERS`. `PG_RENDERS_PREFIX` names the files
/// (`plot` unless said), `PG_RENDERS_HOURS` the hours (8, 12, 17 and midnight
/// unless said), `PG_RENDERS_WORLD` the ground (the first unless said) and
/// `PG_RENDERS_TURN` the plot's quarter-turns.
/// `PG_FRAMES`, also set, times frames while the clock is wound round.
@MainActor
final class PlotRenderTests: XCTestCase {

    /// The iPhone Air's screen, in points.
    private static let screen = CGSize(width: 420, height: 912)

    /// A night with the moon full, so the moon's shadows are at their
    /// strongest: 26 September 2026. The day ones are taken on the same date.
    private static func date(hour: Int) -> Date {
        var parts = DateComponents()
        parts.year = 2026; parts.month = 9; parts.day = hour < 6 ? 27 : 26
        parts.hour = hour; parts.minute = 0
        return Calendar.current.date(from: parts)!
    }

    func testDrawThePlotRoundTheClock() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard let folder = environment["PG_RENDERS"], !folder.isEmpty else {
            throw XCTSkip("PG_RENDERS is not set")
        }
        try XCTSkipUnless(GardenWorlds.shared.isLoaded)
        try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
        let prefix = environment["PG_RENDERS_PREFIX"] ?? "plot"
        let hours = environment["PG_RENDERS_HOURS"]?.split(separator: ",").compactMap { Int($0) }
            ?? [8, 12, 17, 0]
        let world = environment["PG_RENDERS_WORLD"].flatMap { Int($0) } ?? 0
        let turn = environment["PG_RENDERS_TURN"].flatMap { Int($0) } ?? 0

        let developer = Developer.shared
        let shiftBefore = developer.clockShift
        let daylightBefore = UserDefaults.standard.string(forKey: Chrome.daylightKey)
        let turnBefore = UserDefaults.standard.object(forKey: Chrome.plotTurnKey)
        defer {
            developer.backToNow()
            developer.advance(by: shiftBefore)
            UserDefaults.standard.set(daylightBefore, forKey: Chrome.daylightKey)
            UserDefaults.standard.set(turnBefore, forKey: Chrome.plotTurnKey)
        }
        UserDefaults.standard.set(GardenDaylight.byTheClock.rawValue, forKey: Chrome.daylightKey)
        UserDefaults.standard.set(turn, forKey: Chrome.plotTurnKey)

        wind(to: Self.date(hour: hours.first ?? 12))
        let model = Self.model(world: world)
        let window = try Self.window(showing: PlotView().environment(model))
        defer { window.isHidden = true }

        var first = true
        for hour in hours {
            wind(to: Self.date(hour: hour))
            model.refreshNow()
            // Long enough for every plant and figure to be photographed at the
            // two steps either side of the hour, and the ground drawn.
            try await Task.sleep(for: .seconds(first ? 10 : 6))
            first = false
            let name = String(format: "%@-%02d", prefix, hour)
            try write(window, to: URL(fileURLWithPath: folder).appendingPathComponent("\(name).png"),
                      scale: 2, crop: CGRect(x: 0, y: 290, width: Self.screen.width, height: 400))
            // And a closer look at the middle of it, at the phone's own
            // resolution.
            try write(window, to: URL(fileURLWithPath: folder).appendingPathComponent("\(name)-close.png"),
                      scale: 3, crop: CGRect(x: 80, y: 370, width: 300, height: 250))
        }

        if environment["PG_FRAMES"] != nil {
            try await timeFrames(model: model, folder: folder, prefix: prefix)
        }
    }

    // MARK: Timing

    /// What a frame of the plot costs.
    ///
    /// **Held still, then redrawn every frame.** The clock is moved a second a
    /// frame, which changes nothing that is cached — no sprite, no shadow, no
    /// ground is made again — but has the whole plot drawn again each frame,
    /// as a drag or a pan does. That is the cost of having the shadows on the
    /// screen at all, and it is measured as the main thread's own CPU time.
    /// Then the clock is run from seven in the morning to five in the
    /// afternoon in four seconds, twice, which makes everything again that
    /// the light touches: the ground, the sprites, the shadows.
    private func timeFrames(model: GardenModel, folder: String, prefix: String) async throws {
        let counter = FrameCounter()
        let held = Self.date(hour: 0)
        counter.start()
        let cpuBefore = Self.threadCPU()
        for frame in 0..<180 {
            wind(to: held.addingTimeInterval(Double(frame + 1)))
            model.refreshNow()
            try await Task.sleep(for: .milliseconds(16))
        }
        let cpu = (Self.threadCPU() - cpuBefore) * 1000 / 180
        let steady = counter.stop()

        // **With and without, in turn.** Forty frames with the shadows and
        // forty without, six times over, in this one run: the machine's load
        // moves between two runs by more than the shadows cost, and within
        // one it falls on both alike.
        var shown: [Double] = [], hidden: [Double] = []
        var second = 200
        for round in 0..<12 {
            Developer.shared.hidesShadows = round % 2 == 1
            try await Task.sleep(for: .milliseconds(100))
            let before = Self.threadCPU()
            for _ in 0..<40 {
                second += 1
                wind(to: held.addingTimeInterval(Double(second)))
                model.refreshNow()
                try await Task.sleep(for: .milliseconds(16))
            }
            let each = (Self.threadCPU() - before) * 1000 / 40
            if round % 2 == 1 { hidden.append(each) } else { shown.append(each) }
        }
        Developer.shared.hidesShadows = false
        func middle(_ values: [Double]) -> Double { values.sorted()[values.count / 2] }

        let start = Self.date(hour: 7)
        func sweep() async throws -> [Double] {
            counter.start()
            for frame in 0..<240 {
                wind(to: start.addingTimeInterval(Double(frame) * 10 * 3_600 / 240))
                model.refreshNow()
                try await Task.sleep(for: .milliseconds(16))
            }
            return counter.stop()
        }
        let cold = try await sweep()
        try await Task.sleep(for: .seconds(6))
        let warm = try await sweep()

        func summary(_ intervals: [Double]) -> String {
            guard !intervals.isEmpty else { return "no frames" }
            let sorted = intervals.sorted()
            let mean = intervals.reduce(0, +) / Double(intervals.count)
            let p95 = sorted[min(sorted.count - 1, Int(Double(sorted.count) * 0.95))]
            let long = intervals.filter { $0 > 1000.0 / 50 }.count
            return String(format: "%d frames, mean %.1f ms, median %.1f ms, p95 %.1f ms, worst %.1f ms, %d over 20 ms",
                          intervals.count, mean, sorted[sorted.count / 2], p95, sorted.last ?? 0, long)
        }
        let rounds = { (values: [Double]) in values.map { String(format: "%.1f", $0) }.joined(separator: ", ") }
        let report = String(format: "redrawn every frame, nothing new to make: main thread %.2f ms CPU a frame\n", cpu)
            + "  display link: \(summary(steady))\n"
            + String(format: "  in turn, main thread a frame: with shadows %.2f ms, without %.2f ms (medians of six)\n",
                     middle(shown), middle(hidden))
            + "    with: \(rounds(shown)); without: \(rounds(hidden))\n"
            + "clock run 07-17 in 4 s, first time: \(summary(cold))\n"
            + "clock run 07-17 in 4 s, again: \(summary(warm))\n"
        try report.write(to: URL(fileURLWithPath: folder).appendingPathComponent("\(prefix)-frames.txt"),
                         atomically: true, encoding: .utf8)
    }

    /// The calling thread's own CPU time, in seconds.
    private static func threadCPU() -> Double {
        var time = timespec()
        clock_gettime(CLOCK_THREAD_CPUTIME_ID, &time)
        return Double(time.tv_sec) + Double(time.tv_nsec) / 1e9
    }

    /// Display-link intervals, in milliseconds.
    private final class FrameCounter: NSObject {
        private var link: CADisplayLink?
        private var last: CFTimeInterval = 0
        private var intervals: [Double] = []

        func start() {
            intervals = []
            last = 0
            let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
            link.add(to: .main, forMode: .common)
            self.link = link
        }

        func stop() -> [Double] {
            link?.invalidate()
            link = nil
            return intervals
        }

        @objc private func tick(_ link: CADisplayLink) {
            if last > 0 { intervals.append((link.timestamp - last) * 1000) }
            last = link.timestamp
        }
    }

    // MARK: The garden

    private func wind(to date: Date) {
        Developer.shared.advance(by: date.timeIntervalSince(Developer.now))
    }

    private static func id(_ n: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-4000-8000-%012d", n))!
    }

    /// Fourteen grown plants from fixed seeds, and every figure and light that
    /// stands on the ground, each beside a plant.
    private static func model(world: Int) -> GardenModel {
        let met = date(hour: 12).addingTimeInterval(-200 * 86_400)
        let plants = (0..<14).map { n -> PlantRecord in
            let a = SeedID(bytes: seedDigest(SeedDomain.seed, Data("shadow-a-\(n)".utf8)))!
            let b = SeedID(bytes: seedDigest(SeedDomain.seed, Data("shadow-b-\(n)".utf8)))!
            let encounter = Pollination.encounterID(seedA: a, seedB: b,
                                                    nonceA: Data("na\(n)".utf8), nonceB: Data("nb\(n)".utf8))
            return PlantRecord(
                id: id(n),
                seed: Pollination.cross(seedA: a, seedB: b, encounterID: encounter),
                lineage: .crossed(parentA: a, parentB: b, encounterID: encounter),
                birth: met.addingTimeInterval(Double(n) * 3_600),
                savedAt: met.addingTimeInterval(Double(n) * 3_600),
                encounter: EncounterNote(peerDisplayName: "Ash", happenedAt: met, place: "Here")
            )
        }
        let lamps = [
            Lamp(id: id(101), kind: .hare, spot: Spot(x: -0.55, z: 0.95)),
            Lamp(id: id(102), kind: .fox, spot: Spot(x: 0.95, z: 0.35)),
            Lamp(id: id(103), kind: .snail, spot: Spot(x: 0.25, z: 1.25)),
            Lamp(id: id(104), kind: .moth, spot: Spot(x: -1.15, z: -0.25)),
            Lamp(id: id(105), kind: .lantern, spot: Spot(x: 0.35, z: -0.85)),
            Lamp(id: id(106), kind: .paperLamp, spot: Spot(x: 1.35, z: -0.95)),
        ]
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("plot-render-\(UUID().uuidString).json")
        let store = GardenStore(fileURL: file)
        let me = Identity(seed: SeedID(bytes: seedDigest(SeedDomain.seed, Data("shadow-me".utf8)))!,
                          birth: met, displayName: "Wren")
        try? store.save(Garden(identity: me, plants: plants,
                               beds: [Bed(name: "", template: .thematic, world: world, lamps: lamps)]))
        return GardenModel(store: store)
    }

    // MARK: The window and the picture

    private static func window(showing view: some View) throws -> UIWindow {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(origin: .zero, size: screen)
        window.windowLevel = .alert + 1
        window.rootViewController = UIHostingController(rootView: view)
        window.makeKeyAndVisible()
        return window
    }

    private func write(_ window: UIWindow, to url: URL, scale: CGFloat, crop: CGRect) throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        let image = UIGraphicsImageRenderer(size: crop.size, format: format).image { _ in
            window.drawHierarchy(in: CGRect(origin: CGPoint(x: -crop.minX, y: -crop.minY),
                                            size: window.bounds.size),
                                 afterScreenUpdates: true)
        }
        try XCTUnwrap(image.pngData()).write(to: url)
    }
}
