import SeedCore
import SwiftUI
import UIKit
import XCTest
@testable import PeaceGarden

/// **The garden at a hundred plants, held to two promises** (14 October 2026):
/// opening it never stops the screen for half a second in one go, and closing
/// it hands back the memory it took.
///
/// Until 14 October every plant was photographed on the main thread as the
/// garden opened, one after another before the next frame: 3.2 s at a hundred
/// plants with the optimiser on, 32 s without, and 0.45 GB still held after
/// the garden had closed (`design/mass-test-2026-10-13/app/README.md`,
/// findings 1 and 11). `design/garden-perf-2026-10-14/README.md` has what
/// changed. The thresholds are generous on purpose — a target of 100 ms held
/// at 500, on a simulator on a shared Mac — so this fails on the old shape and
/// not on a busy afternoon.
///
/// Also here, skipped unless `PG_PERF_RENDERS` names a folder: the garden at
/// 14 and 100 plants by day and by night, photographed whole, for comparing a
/// build before a change to the drawing with one after it.
@MainActor
final class GardenPerfTests: XCTestCase {

    /// The iPhone Air's screen, in points.
    private static let screen = CGSize(width: 420, height: 912)

    /// The longest the main thread may be held in one go while a hundred-plant
    /// garden opens.
    private static let longestBlockMs = 500.0
    /// How much more the process may hold once the garden has closed than it
    /// did before it opened.
    private static let keptAfterCloseMB = 150.0

    func testAHundredPlantGardenOpensWithoutFreezingAndLetsGoWhenClosed() async throws {
        let defaults = UserDefaults.standard
        let daylightBefore = defaults.string(forKey: Chrome.daylightKey)
        let turnBefore = defaults.object(forKey: Chrome.plotTurnKey)
        defer {
            defaults.set(daylightBefore, forKey: Chrome.daylightKey)
            defaults.set(turnBefore, forKey: Chrome.plotTurnKey)
        }
        defaults.set(GardenDaylight.always.rawValue, forKey: Chrome.daylightKey)
        defaults.set(0, forKey: Chrome.plotTurnKey)

        let model = Self.model(size: 100, now: Date())
        // Settled first, so what is measured after closing is the garden's and
        // not the test's own start-up.
        try await Task.sleep(for: .milliseconds(500))
        let before = Self.footprintMB()

        let counter = FrameCounter()
        counter.start()
        let opened = CACurrentMediaTime()
        var window: UIWindow? = try Self.window(showing: PlotView().environment(model))
        window?.rootViewController?.view.layoutIfNeeded()
        CATransaction.flush()
        let firstFrameMs = (CACurrentMediaTime() - opened) * 1000

        // Long enough for the plot to be drawn and its plants to be coming in.
        try await Task.sleep(for: .seconds(8))
        let longest = max(firstFrameMs, counter.stop().max() ?? 0)
        let open = Self.footprintMB()

        window?.isHidden = true
        window?.rootViewController = nil
        window = nil
        try await Task.sleep(for: .seconds(3))
        let after = Self.footprintMB()

        let summary = String(format: "first frame %.0f ms, longest frame %.0f ms; footprint %.0f MB before, %.0f MB open, %.0f MB after closing",
                             firstFrameMs, longest, before, open, after)
        print("GardenPerfTests: \(summary)")
        XCTAssertLessThan(longest, Self.longestBlockMs, "the garden held the main thread too long: \(summary)")
        XCTAssertLessThan(after - before, Self.keptAfterCloseMB, "the garden kept its memory after closing: \(summary)")
    }

    // MARK: Photographs to compare

    /// A day of its own, so the moon's phase and the season are the same
    /// whichever day the comparison is run: 26 September 2026, as
    /// `PlotRenderTests`.
    private static let photographed: Date = {
        var parts = DateComponents()
        parts.year = 2026; parts.month = 9; parts.day = 26; parts.hour = 12
        return Calendar.current.date(from: parts)!
    }()

    func testPhotographGardensToCompare() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard let folder = environment["PG_PERF_RENDERS"], !folder.isEmpty else {
            throw XCTSkip("PG_PERF_RENDERS is not set")
        }
        try XCTSkipUnless(GardenWorlds.shared.isLoaded)
        try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
        let sizes = (environment["PG_PERF_SIZES"] ?? "14,100").split(separator: ",").compactMap { Int($0) }

        let developer = Developer.shared
        let shiftBefore = developer.clockShift
        let defaults = UserDefaults.standard
        let daylightBefore = defaults.string(forKey: Chrome.daylightKey)
        let turnBefore = defaults.object(forKey: Chrome.plotTurnKey)
        defer {
            developer.backToNow()
            developer.advance(by: shiftBefore)
            defaults.set(daylightBefore, forKey: Chrome.daylightKey)
            defaults.set(turnBefore, forKey: Chrome.plotTurnKey)
        }
        defaults.set(0, forKey: Chrome.plotTurnKey)
        developer.advance(by: Self.photographed.timeIntervalSince(Developer.now))

        for size in sizes {
            for (name, daylight) in [("day", GardenDaylight.always), ("night", GardenDaylight.alwaysNight)] {
                defaults.set(daylight.rawValue, forKey: Chrome.daylightKey)
                let model = Self.model(size: size, now: Self.photographed)
                model.refreshNow()
                var window: UIWindow? = try Self.window(showing: PlotView().environment(model))
                try await settle(limit: 240)
                // And a moment more for the last shadows and the ground.
                try await Task.sleep(for: .seconds(4))
                let format = UIGraphicsImageRendererFormat()
                format.scale = 3
                format.opaque = true
                let image = UIGraphicsImageRenderer(size: Self.screen, format: format).image { _ in
                    window?.drawHierarchy(in: CGRect(origin: .zero, size: Self.screen), afterScreenUpdates: true)
                }
                try XCTUnwrap(image.pngData()).write(
                    to: URL(fileURLWithPath: folder).appendingPathComponent("garden-\(size)-\(name).png"))
                window?.isHidden = true
                window?.rootViewController = nil
                window = nil
                try await Task.sleep(for: .seconds(1))
            }
        }
    }

    /// **A big garden opened, filled in and closed**, skipped unless
    /// `PG_PERF_BIG` names a size (2,000 for the mass test's largest) and
    /// `PG_PERF_RENDERS` a folder: the first frame, the longest frame until
    /// every plant has its pictures, how long that took, the footprint's peak
    /// sampled every half second, and what is left a few seconds after
    /// closing. The mass test's own harness waits for the plot to hold still,
    /// which a garden this size with a drift of fireflies in it never quite
    /// does; this waits only for the pictures.
    func testOpenABigGarden() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard let folder = environment["PG_PERF_RENDERS"], !folder.isEmpty,
              let size = environment["PG_PERF_BIG"].flatMap({ Int($0) }) else {
            throw XCTSkip("PG_PERF_BIG and PG_PERF_RENDERS are not set")
        }
        try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
        let defaults = UserDefaults.standard
        let daylightBefore = defaults.string(forKey: Chrome.daylightKey)
        defer { defaults.set(daylightBefore, forKey: Chrome.daylightKey) }
        defaults.set(GardenDaylight.always.rawValue, forKey: Chrome.daylightKey)
        defaults.set(0, forKey: Chrome.plotTurnKey)

        let model = Self.model(size: size, now: Date())
        try await Task.sleep(for: .milliseconds(500))
        let before = Self.footprintMB()
        let counter = FrameCounter()
        counter.start()
        let opened = CACurrentMediaTime()
        var window: UIWindow? = try Self.window(showing: PlotView().environment(model))
        window?.rootViewController?.view.layoutIfNeeded()
        CATransaction.flush()
        let firstFrameMs = (CACurrentMediaTime() - opened) * 1000

        var peak = Self.footprintMB()
        var filled: Double?
        while CACurrentMediaTime() - opened < 300 {
            try await Task.sleep(for: .milliseconds(500))
            peak = max(peak, Self.footprintMB())
            let elapsed = CACurrentMediaTime() - opened
            if elapsed > 2, GardenSprites.shared.outstanding == 0 {
                filled = elapsed
                break
            }
        }
        let intervals = counter.stop()
        try await Task.sleep(for: .seconds(3))
        peak = max(peak, Self.footprintMB())
        let open = Self.footprintMB()

        window?.isHidden = true
        window?.rootViewController = nil
        window = nil
        try await Task.sleep(for: .seconds(3))
        let result: [String: Any] = [
            "plants": size, "firstFrameMs": firstFrameMs,
            "longestFrameMs": max(firstFrameMs, intervals.max() ?? 0),
            "framesOver100ms": intervals.filter { $0 > 100 }.count,
            "filledSeconds": filled ?? -1, "footprintBeforeMB": before, "footprintPeakMB": peak,
            "footprintOpenMB": open, "footprintAfterCloseMB": Self.footprintMB(),
        ]
        let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: URL(fileURLWithPath: folder).appendingPathComponent("big-\(size).json"))
    }

    /// Until the plot holds still: two seconds in which no frame took longer
    /// than 50 ms and the main thread was busy less than 60% of the time — the
    /// mass test's own measure.
    private func settle(limit: Double) async throws {
        let counter = FrameCounter()
        counter.start()
        defer { _ = counter.stop() }
        let start = CACurrentMediaTime()
        var marks: [(time: Double, cpu: Double)] = [(0, Self.threadCPU())]
        while CACurrentMediaTime() - start < limit {
            try await Task.sleep(for: .milliseconds(250))
            let t = CACurrentMediaTime() - start
            marks.append((t, Self.threadCPU()))
            guard t > 2.5 else { continue }
            let from = marks.last { $0.time <= t - 2 } ?? marks[0]
            let busy = (marks.last!.cpu - from.cpu) / (t - from.time)
            if busy < 0.6, counter.longest(within: 2) < 50 { return }
        }
    }

    // MARK: The garden

    /// `size` crosses born across the 240 days before `now`, so every stage is
    /// in it — the mass test's garden — and a figure or light for every fifty
    /// plants, six at least, none of them the fireflies, whose drift would
    /// differ between two photographs of the same garden.
    static func model(size: Int, now: Date) -> GardenModel {
        let me = SeedID(bytes: seedDigest(SeedDomain.seed, Data("masstest-me".utf8)))!
        let plants = (0..<size).map { n -> PlantRecord in
            let days = 1 + 239 * (1 - Double(n) / Double(max(1, size - 1)))
            let birth = now.addingTimeInterval(-days * 86_400)
            let them = SeedID(bytes: seedDigest(SeedDomain.seed, Data("masstest-peer-\(n)".utf8)))!
            let encounter = Pollination.encounterID(seedA: me, seedB: them,
                                                    nonceA: Data("na\(n)".utf8), nonceB: Data("nb\(n)".utf8))
            let (low, high) = me < them ? (me, them) : (them, me)
            return PlantRecord(
                id: UUID(uuidString: String(format: "00000000-0000-4000-8000-%012d", n))!,
                seed: Pollination.cross(seedA: me, seedB: them, encounterID: encounter),
                lineage: .crossed(parentA: low, parentB: high, encounterID: encounter),
                birth: birth, savedAt: birth,
                encounter: EncounterNote(peerDisplayName: "Ash", happenedAt: birth, place: "Here")
            )
        }
        let kinds: [LampKind] = [.lantern, .paperLamp, .hare, .fox, .moth, .snail]
        let count = min(40, 6 + size / 50)
        let lamps = (0..<count).map { k -> Lamp in
            let angle = Double(k) * 2.399963
            let radius = 0.25 + 0.85 * (Double(k + 1) / Double(count)).squareRoot()
            return Lamp(id: UUID(uuidString: String(format: "00000000-0000-4000-9000-%012d", k))!,
                        kind: kinds[k % kinds.count],
                        spot: Spot(x: radius * cos(angle), z: radius * sin(angle)))
        }
        let identity = Identity(seed: me, birth: now.addingTimeInterval(-300 * 86_400), displayName: "Wren")
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("garden-perf-\(size)-\(UUID().uuidString).json")
        let store = GardenStore(fileURL: file)
        try? store.save(Garden(identity: identity, plants: plants,
                               beds: [Bed(name: "", template: .thematic, world: 0, lamps: lamps)]))
        return GardenModel(store: store)
    }

    // MARK: Measuring

    private static func threadCPU() -> Double {
        var time = timespec()
        clock_gettime(CLOCK_THREAD_CPUTIME_ID, &time)
        return Double(time.tv_sec) + Double(time.tv_nsec) / 1e9
    }

    /// The process's physical footprint, in MB: what a phone judges an app by.
    static func footprintMB() -> Double {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let status = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return status == KERN_SUCCESS ? Double(info.phys_footprint) / 1_048_576 : -1
    }

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

    /// Display-link intervals, in milliseconds.
    private final class FrameCounter: NSObject {
        private var link: CADisplayLink?
        private var last: CFTimeInterval = 0
        private var stamps: [(at: CFTimeInterval, interval: Double)] = []

        func start() {
            stamps = []
            last = CACurrentMediaTime()
            let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
            link.add(to: .main, forMode: .common)
            self.link = link
        }

        func stop() -> [Double] {
            link?.invalidate()
            link = nil
            return stamps.map(\.interval)
        }

        /// The longest frame in the last `seconds`, counting the one still
        /// being waited for.
        func longest(within seconds: Double) -> Double {
            let now = CACurrentMediaTime()
            let seen = stamps.filter { $0.at >= now - seconds }.map(\.interval).max() ?? 0
            return max(seen, (now - last) * 1000)
        }

        @objc private func tick(_ link: CADisplayLink) {
            stamps.append((link.timestamp, (link.timestamp - last) * 1000))
            last = link.timestamp
        }
    }
}
