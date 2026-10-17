import SeedCore
import SwiftUI
import XCTest
@testable import PeaceGarden
import PlantRender

/// **No flashing.** Marcus, 13 October 2026: *"not one revolution per day as
/// it will flash too fast, just a notion of the sky turning with time so no one
/// gets strobe epilepsy from it."*
///
/// Every frame of the run is drawn and its mean relative luminance measured
/// (`TimeLapseLuminance`), at sixty frames a second, and three things are held:
///
/// 1. **No step from one frame to the next of one per cent of the full range
///    or more** (`largestStep`). Half the two per cent the brief suggested.
/// 2. **The brightness turns round at most once in the run** (`reversals`): it
///    may rise and then fall, or fall and then rise, and that is all. Wiggles
///    smaller than `hysteresis` are not counted as turns.
/// 3. **Nothing WCAG 2.3.1 would call a flash inside any one second**
///    (`flashesInOneSecond`): a flash is a pair of opposing changes of ten per
///    cent of the full range or more, the darker side under 0.8. WCAG allows
///    three a second; this allows none.
///
/// Swept over every drift, both appearances, every second hour of the day,
/// Reduce Motion, and a stop part way through; then the whole frame — stage,
/// sky and a growing plant, as the screen plays it — for a young plant and an
/// old one, and as the share films it, ending under the shared picture's sky.
@MainActor
final class TimeLapseLuminanceTests: XCTestCase {
    static let largestStep = 0.01
    static let hysteresis = 0.01
    static let fps = 60

    // MARK: The sky over the stage, every way it can run

    func testTheSkyNeverFlashes() throws {
        let record = TimeLapseTests.plant("sky", days: 40)
        var worst = (step: 0.0, label: "")
        var report: [String] = []

        for scheme in [ColorScheme.dark, .light] {
            let look = TimeLapseSky.Look.for(scheme)
            let ground = try XCTUnwrap(Self.stage(for: record, scheme: scheme, size: CGSize(width: 40, height: 87)))
            for drift in SkyDrift.allCases {
                for hour in stride(from: 0, through: 22, by: 2) {
                    for reduceMotion in [false, true] {
                        // Night into day does not depend on the hour, and
                        // Reduce Motion is the still sky whatever is chosen.
                        if drift == .nightIntoDay, hour > 0 { continue }
                        if reduceMotion, drift != .chosen { continue }
                        let now = Self.moment(hour: hour)
                        let lapse = TimeLapse(record: record, now: now, drift: drift, calendar: TimeLapseTests.utc)
                        let skies = lapse.frames(fps: Self.fps, reduceMotion: reduceMotion).map(\.sky)
                        let label = "\(scheme == .dark ? "dark" : "light") \(drift.rawValue) \(hour)h\(reduceMotion ? " reduce-motion" : "")"
                        let run = Self.measure(skies, over: ground, look: look)
                        try Self.assertGentle(run, label)
                        if run.largestStep > worst.step { worst = (run.largestStep, label) }
                        report.append(String(format: "%@: largest step %.4f, reversals %d", label,
                                             run.largestStep, run.reversals(Self.hysteresis)))

                        // Stopped a quarter, half and three quarters of the
                        // way through: the sky leaves from wherever it was.
                        guard !reduceMotion, hour % 6 == 0 else { continue }
                        for stop in [3.0, 6.0, 9.0] {
                            let before = skies.prefix(Int(stop * Double(Self.fps)) + 1)
                            let at = before.last!
                            let after = (1...Int(TimeLapse.stopSkyFade * Double(Self.fps)) + 1).map {
                                TimeLapse.sky(stoppedAt: at, since: Double($0) / Double(Self.fps))
                            }
                            let stopped = Self.measure(Array(before) + after, over: ground, look: look)
                            try Self.assertGentle(stopped, label + " stopped at \(Int(stop))s")
                            if stopped.largestStep > worst.step { worst = (stopped.largestStep, label + " stopped") }
                        }
                    }
                }
            }
        }
        print("TIME-LAPSE SKY: worst step \(String(format: "%.4f", worst.step)) (\(worst.label))\n"
              + report.joined(separator: "\n"))
        if let folder = Self.output {
            try report.joined(separator: "\n").write(to: folder.appendingPathComponent("sky-sweep.txt"),
                                                     atomically: true, encoding: .utf8)
        }
    }

    // MARK: The whole frame, as the screen plays it

    /// The last three are the film the share makes, which ends under the
    /// shared picture's sky for the hour (`TimeLapseFilm.Options.endsUnderTheHour`):
    /// by day, at dusk going into the night, and at night.
    func testTheWholeFrameNeverFlashes() async throws {
        let runs: [(name: String, days: Double, scheme: ColorScheme, hour: Int, shared: Bool)] = [
            ("young", 2, .dark, 10, false), ("old", 150, .dark, 10, false), ("old", 150, .dark, 22, false),
            ("old", 150, .light, 10, false),
            ("old", 150, .dark, 10, true), ("old", 150, .dark, 19, true), ("old", 150, .dark, 22, true)
        ]
        for (name, days, scheme, hour, shared) in runs {
            let record = TimeLapseTests.plant(name, days: days)
            do {
                var options = shared ? PlantShareFiles.timeLapseOptions() : TimeLapseFilm.Options()
                options.calendar = TimeLapseTests.utc
                options.size = CGSize(width: 64, height: 139)
                options.fps = Self.fps
                options.scheme = scheme
                options.opensOnThePlant = !shared
                options.turns = true
                var values: [Double] = []
                try await TimeLapseFilm.render(record, now: Self.moment(hour: hour), options: options) { frame in
                    values.append(TimeLapseLuminance.mean(of: frame.image, side: 64))
                }
                let run = Run(values: values)
                let label = "\(name) plant, \(scheme == .dark ? "dark" : "light"), \(hour)h\(shared ? ", shared" : "")"
                try Self.assertGentle(run, label)
                print(String(format: "TIME-LAPSE FRAME %@: largest step %.4f, reversals %d, range %.3f to %.3f",
                             label, run.largestStep, run.reversals(Self.hysteresis),
                             values.min() ?? 0, values.max() ?? 0))
                if let folder = Self.output {
                    let rows = values.enumerated().map { String(format: "%.4f,%.6f", Double($0.offset) / Double(Self.fps), $0.element) }
                    try (["time,luminance"] + rows).joined(separator: "\n")
                        .write(to: folder.appendingPathComponent("luminance-\(name)-\(scheme == .dark ? "dark" : "light")-\(hour)h\(shared ? "-shared" : "").csv"),
                               atomically: true, encoding: .utf8)
                }
            }
        }
    }

    // MARK: Measuring

    struct Run {
        var values: [Double]

        var largestStep: Double {
            zip(values, values.dropFirst()).map { abs($1 - $0) }.max() ?? 0
        }

        /// How many times the brightness turns round, ignoring wiggles smaller
        /// than `hysteresis`.
        func reversals(_ hysteresis: Double) -> Int {
            guard let first = values.first else { return 0 }
            var rising: Bool?
            var extreme = first, low = first, high = first
            var turns = 0
            for value in values.dropFirst() {
                switch rising {
                case nil:
                    low = min(low, value); high = max(high, value)
                    if value - low > hysteresis { rising = true; extreme = value }
                    else if high - value > hysteresis { rising = false; extreme = value }
                case true?:
                    if value > extreme { extreme = value }
                    else if extreme - value > hysteresis { rising = false; extreme = value; turns += 1 }
                case false?:
                    if value < extreme { extreme = value }
                    else if value - extreme > hysteresis { rising = true; extreme = value; turns += 1 }
                }
            }
            return turns
        }

        /// The most WCAG flashes inside any one second: pairs of opposing
        /// changes of a tenth of the range or more, the darker side under 0.8.
        func flashesInOneSecond(fps: Int) -> Int {
            // The swings between turning points.
            var turning = [0]
            for index in 1..<max(1, values.count - 1) {
                let a = values[index - 1], b = values[index], c = values[index + 1]
                if (b - a) * (c - b) < 0 { turning.append(index) }
            }
            turning.append(values.count - 1)
            var swings: [(start: Int, end: Int, rising: Bool)] = []
            for (a, b) in zip(turning, turning.dropFirst()) {
                let from = values[a], to = values[b]
                if abs(to - from) >= 0.1, min(from, to) < 0.8 { swings.append((a, b, to > from)) }
            }
            var flashes: [(start: Int, end: Int)] = []
            for (a, b) in zip(swings, swings.dropFirst()) where a.rising != b.rising {
                flashes.append((a.start, b.end))
            }
            var most = 0
            for flash in flashes {
                let window = flash.start + fps
                most = max(most, flashes.filter { $0.start >= flash.start && $0.end <= window }.count)
            }
            return most
        }
    }

    static func assertGentle(_ run: Run, _ label: String) throws {
        XCTAssertLessThan(run.largestStep, largestStep, "\(label): a step of \(run.largestStep) between frames")
        XCTAssertLessThanOrEqual(run.reversals(hysteresis), 1, "\(label): turns round more than once")
        XCTAssertEqual(run.flashesInOneSecond(fps: fps), 0, "\(label): a flash inside one second")
    }

    /// The mean luminance of every sky, drawn over the stage.
    static func measure(_ skies: [TimeLapseSky.Moment], over ground: CGImage, look: TimeLapseSky.Look) -> Run {
        let width = ground.width, height = ground.height
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let size = CGSize(width: width, height: height)
        var values: [Double] = []
        values.reserveCapacity(skies.count)
        for sky in skies {
            context.draw(ground, in: CGRect(origin: .zero, size: size))
            context.saveGState()
            context.translateBy(x: 0, y: CGFloat(height))
            context.scaleBy(x: 1, y: -1)
            TimeLapseSky.draw(sky, in: context, size: size, look: look)
            context.restoreGState()
            values.append(TimeLapseLuminance.mean(of: context))
        }
        return Run(values: values)
    }

    /// The plant's screen with nothing on it: its ground and its pool of light.
    static func stage(for record: PlantRecord, scheme: ColorScheme, size: CGSize) -> CGImage? {
        let view = StageBackdrop(palette: record.genome.palette,
                                 presence: record.growth(now: TimeLapseTests.now).heightScale)
            .frame(width: size.width, height: size.height)
            .environment(\.colorScheme, scheme)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        return renderer.cgImage
    }

    /// `TimeLapseTests.now`'s day, at `hour` UTC.
    static func moment(hour: Int) -> Date {
        let calendar = TimeLapseTests.utc
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: TimeLapseTests.now)!
    }

    /// Where the measurements are written, if anywhere: `PG_RENDER_TIMELAPSE`.
    static var output: URL? {
        guard let path = ProcessInfo.processInfo.environment["PG_RENDER_TIMELAPSE"], !path.isEmpty else { return nil }
        let folder = URL(fileURLWithPath: path, isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }
}
