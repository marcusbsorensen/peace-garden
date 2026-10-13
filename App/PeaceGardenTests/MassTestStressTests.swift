import SeedCore
import SwiftUI
import UIKit
import XCTest
@testable import PeaceGarden

/// **The garden at 100, 500, 1,000 and 2,000 plants** — measured, not asserted
/// (mass test, 13 October 2026).
///
/// Hosts the real `PlotView` in a window the size of an iPhone Air, over a
/// garden of genuine crosses (`Pollination.cross`, as at a knock), and times
/// what a person would wait for: the file read, the first frame, the plot
/// settling once every plant has been photographed, a frame redrawn when
/// nothing new has to be made (what a pan or a pinch costs), a quarter-turn,
/// and the clock wound on a month at a time. Memory is the process's own
/// footprint at each step, so anything that only ever grows shows as a slope.
///
/// Skipped unless `PG_MASSTEST` names a folder, which `xcodebuild test` passes
/// through as `TEST_RUNNER_PG_MASSTEST`. `PG_MASSTEST_SIZES` picks the sizes
/// (`14,100,500,1000,2000` unless said). One JSON file per size is written as
/// it finishes, so a size that never finishes still leaves the ones before it.
/// `tools/masstest/app/README` (in the report) has the command.
@MainActor
final class MassTestStressTests: XCTestCase {

    /// The iPhone Air's screen, in points: the stress simulator is one.
    private static let screen = CGSize(width: 420, height: 912)

    func testStressTheGarden() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard let folder = environment["PG_MASSTEST"], !folder.isEmpty else {
            throw XCTSkip("PG_MASSTEST is not set")
        }
        try XCTSkipUnless(GardenWorlds.shared.isLoaded)
        try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
        let sizes = (environment["PG_MASSTEST_SIZES"] ?? "14,100,500,1000,2000")
            .split(separator: ",").compactMap { Int($0) }

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
        // Noon, every time: the hour moves the light, and the light is in
        // every sprite's key, so a run that crossed a step of the clock would
        // be measuring the hour rather than the garden.
        defaults.set(GardenDaylight.always.rawValue, forKey: Chrome.daylightKey)
        defaults.set(0, forKey: Chrome.plotTurnKey)
        developer.backToNow()

        var log = "mass test, \(Date())\n"
        log += String(format: "sprite render, cache miss: %.1f ms of main-thread CPU each (median of 24)\n", try spriteCost())
        for size in sizes {
            let result = try await measure(size: size)
            let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: URL(fileURLWithPath: folder).appendingPathComponent("stress-\(size).json"))
            log += "\(size): \(result["summary"] ?? "")\n"
            try log.write(to: URL(fileURLWithPath: folder).appendingPathComponent("stress-log.txt"),
                          atomically: true, encoding: .utf8)
            defaults.set(0, forKey: Chrome.plotTurnKey)
            developer.backToNow()
        }
    }

    // MARK: One size

    private func measure(size: Int) async throws -> [String: Any] {
        var result: [String: Any] = ["plants": size]
        let baseline = Self.footprintMB()
        result["footprintBeforeMB"] = baseline

        // The file: written, read, and the model made from it.
        var clock = Self.now()
        let garden = Self.garden(size: size)
        result["makeMs"] = Self.ms(since: clock)
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("masstest-\(size)-\(UUID().uuidString).json")
        let store = GardenStore(fileURL: file)
        clock = Self.now()
        try store.save(garden)
        result["saveMs"] = Self.ms(since: clock)
        result["fileKB"] = ((try? FileManager.default.attributesOfItem(atPath: file.path)[.size] as? Int) ?? 0) / 1024
        clock = Self.now()
        _ = try store.load()
        result["loadMs"] = Self.ms(since: clock)
        clock = Self.now()
        let model = GardenModel(store: store)
        result["modelMs"] = Self.ms(since: clock)
        result["plotSideM"] = model.garden.plotSide

        // The first frame: everything the body does before a single sprite.
        // Wall time and the main thread's own CPU time both: on a shared
        // machine the first is the machine's, the second much more nearly the
        // app's.
        clock = Self.now()
        let cpuBefore = Self.threadCPU()
        let window = try Self.window(showing: PlotView().environment(model))
        window.rootViewController?.view.layoutIfNeeded()
        CATransaction.flush()
        result["firstFrameMs"] = Self.ms(since: clock)
        result["firstFrameCPUms"] = (Self.threadCPU() - cpuBefore) * 1000

        // Opening: until every plant has been photographed and the plot holds
        // still.
        let open = try await settle(limit: size >= 1000 ? 900 : 300)
        result["open"] = open
        result["footprintOpenMB"] = Self.footprintMB()

        // A frame redrawn with nothing new to make, which is what a pan or a
        // pinch asks of it: the clock moved a second a frame.
        result["redraw"] = try await redraw(model: model, frames: 90)

        // A quarter-turn, and the way back. Every plant is photographed again
        // from the new side; the way back is free only while the cache holds
        // the first side.
        var turns: [[String: Any]] = []
        let path = size >= 1000 ? [1, 0] : [1, 2, 3, 0]
        for turn in path {
            UserDefaults.standard.set(turn, forKey: Chrome.plotTurnKey)
            var step = try await settle(limit: size >= 1000 ? 900 : 300)
            step["turn"] = turn
            step["footprintMB"] = Self.footprintMB()
            turns.append(step)
        }
        result["turns"] = turns

        // The clock wound on a month at a time: every plant grows into a new
        // picture, and nothing should pile up.
        var months: [[String: Any]] = []
        let count = size >= 1000 ? 2 : 6
        for month in 1...count {
            Developer.shared.advance(by: 30 * 86_400)
            model.refreshNow()
            var step = try await settle(limit: size >= 1000 ? 900 : 300)
            step["month"] = month
            step["footprintMB"] = Self.footprintMB()
            months.append(step)
        }
        result["months"] = months
        Developer.shared.backToNow()

        // Closed, and given a moment: what the garden leaves behind.
        window.isHidden = true
        window.rootViewController = nil
        try await Task.sleep(for: .seconds(3))
        result["footprintAfterCloseMB"] = Self.footprintMB()
        try? FileManager.default.removeItem(at: file)

        let openSeconds = (open["seconds"] as? Double) ?? -1
        let redraw = result["redraw"] as? [String: Any]
        let firstTurn = turns.first?["seconds"] as? Double ?? -1
        let peak = ([result["footprintOpenMB"] as? Double ?? 0]
                    + turns.compactMap { $0["footprintMB"] as? Double }
                    + months.compactMap { $0["footprintMB"] as? Double }).max() ?? 0
        result["footprintPeakMB"] = peak
        result["summary"] = String(
            format: "load %.0f ms, first frame %.0f ms (%.0f ms CPU), open %.1f s%@, redraw %.1f ms CPU/frame (p95 %.1f ms), turn %.1f s, peak %.0f MB, after close %.0f MB",
            result["loadMs"] as? Double ?? -1, result["firstFrameMs"] as? Double ?? -1,
            result["firstFrameCPUms"] as? Double ?? -1,
            openSeconds, (open["settled"] as? Bool ?? false) ? "" : " (did not settle)",
            redraw?["cpuMsPerFrame"] as? Double ?? -1, redraw?["p95Ms"] as? Double ?? -1,
            firstTurn, peak, result["footprintAfterCloseMB"] as? Double ?? -1)
        return result
    }

    // MARK: Settling

    /// Waits until the plot holds still: two seconds in which no frame took
    /// longer than 50 ms and the main thread was busy less than 60% of the
    /// time. The figures' lights flicker at thirty frames a second for ever, so
    /// "idle" is never zero.
    private func settle(limit: Double) async throws -> [String: Any] {
        let counter = FrameCounter()
        counter.start()
        let start = Self.now()
        var cpuMarks: [(time: Double, cpu: Double)] = [(0, Self.threadCPU())]
        var settledAt: Double?
        var peak = Self.footprintMB()
        while Self.now() - start < limit {
            try await Task.sleep(for: .milliseconds(250))
            let t = Self.now() - start
            cpuMarks.append((t, Self.threadCPU()))
            peak = max(peak, Self.footprintMB())
            guard t > 2.5 else { continue }
            let windowStart = cpuMarks.last { $0.time <= t - 2 } ?? cpuMarks[0]
            let busy = (cpuMarks.last!.cpu - windowStart.cpu) / (t - windowStart.time)
            let longest = counter.longest(since: counter.elapsed - 2)
            if busy < 0.6, longest < 50 {
                settledAt = t - 2
                break
            }
        }
        let intervals = counter.stop()
        let cpuTotal = (cpuMarks.last?.cpu ?? 0) - cpuMarks[0].cpu
        var step = Self.summary(intervals)
        step["seconds"] = settledAt ?? limit
        step["settled"] = settledAt != nil
        step["mainThreadCPUSeconds"] = cpuTotal
        step["peakDuringMB"] = peak
        return step
    }

    /// The clock moved a second a frame, `frames` times: nothing is made
    /// again, but the whole plot is redrawn.
    private func redraw(model: GardenModel, frames: Int) async throws -> [String: Any] {
        let counter = FrameCounter()
        counter.start()
        let before = Self.threadCPU()
        let started = Self.now()
        for _ in 0..<frames {
            Developer.shared.advance(by: 1)
            model.refreshNow()
            try await Task.sleep(for: .milliseconds(16))
        }
        let cpu = (Self.threadCPU() - before) * 1000 / Double(frames)
        var step = Self.summary(counter.stop())
        step["cpuMsPerFrame"] = cpu
        step["wallMsPerFrame"] = Self.ms(since: started) / Double(frames)
        return step
    }

    /// One plant photographed from nothing: what each of the 2N waits at
    /// opening costs.
    private func spriteCost() throws -> Double {
        let birth = Date().addingTimeInterval(-120 * 86_400)
        var costs: [Double] = []
        for n in 0..<24 {
            let record = Self.record(n + 50_000, birth: birth)
            let growth = GrowthModel(genome: record.genome).state(birth: birth, now: Date())
            // The main thread's CPU, not the wall: see `firstFrameCPUms`.
            let cpu = Self.threadCPU()
            _ = GardenSprites.shared.sprite(genome: record.genome, growth: growth, step: 3, turn: 3,
                                            season: Season.here(at: Date()))
            costs.append((Self.threadCPU() - cpu) * 1000)
        }
        return costs.sorted()[costs.count / 2]
    }

    // MARK: The garden

    private static func record(_ n: Int, birth: Date) -> PlantRecord {
        let me = SeedID(bytes: seedDigest(SeedDomain.seed, Data("masstest-me".utf8)))!
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

    /// `size` crosses born across the last 240 days, so every stage is in it,
    /// and a figure or light for every fifty plants (six at least, forty at
    /// most) on a spiral inside the smallest plot.
    private static func garden(size: Int) -> Garden {
        let now = Date()
        let plants = (0..<size).map { n -> PlantRecord in
            let days = 1 + 239 * (1 - Double(n) / Double(max(1, size - 1)))
            return record(n, birth: now.addingTimeInterval(-days * 86_400))
        }
        let kinds: [LampKind] = [.lantern, .paperLamp, .fireflies, .hare, .fox, .moth, .snail]
        let count = min(40, 6 + size / 50)
        let lamps = (0..<count).map { k -> Lamp in
            let angle = Double(k) * 2.399963
            let radius = 0.25 + 0.85 * (Double(k + 1) / Double(count)).squareRoot()
            return Lamp(id: UUID(uuidString: String(format: "00000000-0000-4000-9000-%012d", k))!,
                        kind: kinds[k % kinds.count],
                        spot: Spot(x: radius * cos(angle), z: radius * sin(angle)))
        }
        let me = Identity(seed: SeedID(bytes: seedDigest(SeedDomain.seed, Data("masstest-me".utf8)))!,
                          birth: now.addingTimeInterval(-300 * 86_400), displayName: "Wren")
        return Garden(identity: me, plants: plants,
                      beds: [Bed(name: "", template: .thematic, world: 0, lamps: lamps)])
    }

    // MARK: Measuring

    private static func now() -> Double { CACurrentMediaTime() }

    private static func ms(since start: Double) -> Double { (now() - start) * 1000 }

    /// The calling thread's own CPU time, in seconds. Called from the main
    /// actor, so it is the main thread's.
    private static func threadCPU() -> Double {
        var time = timespec()
        clock_gettime(CLOCK_THREAD_CPUTIME_ID, &time)
        return Double(time.tv_sec) + Double(time.tv_nsec) / 1e9
    }

    /// The process's physical footprint, which is what the system judges an
    /// app's memory by, in MB.
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

    private static func summary(_ intervals: [Double]) -> [String: Any] {
        guard !intervals.isEmpty else { return ["frames": 0] }
        let sorted = intervals.sorted()
        func at(_ q: Double) -> Double { sorted[min(sorted.count - 1, Int(Double(sorted.count) * q))] }
        return [
            "frames": intervals.count,
            "meanMs": intervals.reduce(0, +) / Double(intervals.count),
            "p50Ms": at(0.5), "p95Ms": at(0.95), "worstMs": sorted.last ?? 0,
            "over34ms": intervals.filter { $0 > 34 }.count,
            "over100ms": intervals.filter { $0 > 100 }.count,
            "over1s": intervals.filter { $0 > 1000 }.count,
        ]
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
        private var first: CFTimeInterval = 0
        private var last: CFTimeInterval = 0
        private var stamps: [(at: Double, interval: Double)] = []

        var elapsed: Double { last - first }

        func start() {
            stamps = []
            first = CACurrentMediaTime()
            last = first
            let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
            link.add(to: .main, forMode: .common)
            self.link = link
        }

        func stop() -> [Double] {
            link?.invalidate()
            link = nil
            return stamps.map(\.interval)
        }

        /// The longest frame since `time` seconds after the start, counting
        /// the frame still being waited for.
        func longest(since time: Double) -> Double {
            let pending = (CACurrentMediaTime() - last) * 1000
            let seen = stamps.filter { $0.at >= time }.map(\.interval).max() ?? 0
            return max(seen, pending)
        }

        @objc private func tick(_ link: CADisplayLink) {
            let now = link.timestamp
            stamps.append((now - first, (now - last) * 1000))
            last = now
        }
    }
}
