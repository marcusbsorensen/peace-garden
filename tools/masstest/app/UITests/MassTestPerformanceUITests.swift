import XCTest

/// **Launch, the garden opening, and a pan and a turn by real fingers, at one
/// garden size** (mass test, 13 October 2026).
///
/// `PG_MT_SIZE` picks the garden (`garden-<size>.json` from `PG_MT_FIXTURES`);
/// run once per size. Each test writes what it timed by hand to
/// `PG_MT_OUT/perf-<size>-<test>.json`, and the `measure` blocks put XCTest's
/// own metrics — hitches (`XCTHitchMetric`, iOS 26), the app's CPU and memory
/// — in the result bundle, which `report.py` reads back.
///
/// "Responsive" is measured from outside: how long one accessibility query of
/// the app takes. The query is answered on the app's main thread, so while
/// that thread is busy photographing plants the answer waits, exactly as a
/// finger on the glass would.
@MainActor
final class MassTestPerformanceUITests: XCTestCase {

    private var size: Int { Int(MassTest.environment["PG_MT_SIZE"] ?? "14") ?? 14 }

    /// Installed and launched once, so the app has a data container, then
    /// the garden of this size put in it.
    private func prepare() throws {
        continueAfterFailure = true
        let app = XCUIApplication()
        app.launchArguments = ["-loading.style.v1", "off"]
        app.launch()
        app.terminate()
        try MassTest.install(garden: try MassTest.fixture("garden-\(size).json"))
    }

    private func arguments(_ extra: [String] = []) -> [String] {
        ["-loading.style.v1", "off", "-developer.clockShift", "0",
         "-garden.turn.v1", "0", "-garden.daylight.v1", "always",
         "-AppleLanguages", "(en)", "-AppleLocale", "en_GB"] + extra
    }

    /// Cold launches to the stage, until its row of marks answers.
    func testLaunchToInteractive() throws {
        try prepare()
        let out = try MassTest.outputFolder()
        let app = XCUIApplication()
        app.launchArguments = arguments()
        var seconds: [Double] = []
        let options = XCTMeasureOptions()
        options.iterationCount = 3
        measure(metrics: [XCTApplicationLaunchMetric(waitUntilResponsive: true),
                          XCTMemoryMetric(application: app)], options: options) {
            let started = Date()
            app.launch()
            _ = app.buttons.firstMatch.waitForExistence(timeout: 120)
            seconds.append(Date().timeIntervalSince(started))
        }
        try MassTest.write(["size": size, "launchToInteractiveSeconds": seconds],
                           to: out.appendingPathComponent("perf-\(size)-launch.json"))
    }

    /// Launched straight into the garden: until the tray's plus exists, and
    /// until the app answers promptly again.
    func testGardenOpen() throws {
        try prepare()
        let out = try MassTest.outputFolder()
        let app = XCUIApplication()
        app.launchArguments = arguments(["-pgOpen", "garden"])
        var runs: [[String: Any]] = []
        for _ in 0..<2 {
            let started = Date()
            app.launch()
            let appeared = app.buttons["garden.tray"].waitForExistence(timeout: 900)
            let trayAt = Date().timeIntervalSince(started)
            let (settled, probes, calmAt) = waitUntilResponsive(app, limit: 900)
            runs.append(["trayExists": appeared, "traySeconds": trayAt,
                         "responsiveSeconds": calmAt.timeIntervalSince(started),
                         "settled": settled, "slowestProbeSeconds": probes.max() ?? 0])
            try MassTest.write(["size": size, "runs": runs],
                               to: out.appendingPathComponent("perf-\(size)-open.json"))
            app.terminate()
        }
    }

    /// Zoomed in, then panned by one finger across the plot and back.
    func testPan() throws {
        try prepare()
        let out = try MassTest.outputFolder()
        let app = XCUIApplication()
        app.launchArguments = arguments(["-pgOpen", "garden"])
        app.launch()
        _ = app.buttons["garden.tray"].waitForExistence(timeout: 900)
        _ = waitUntilResponsive(app, limit: 900)
        app.pinch(withScale: 2.4, velocity: 2.5)
        _ = waitUntilResponsive(app, limit: 300)

        var seconds: [Double] = []
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        measure(metrics: [XCTHitchMetric(application: app), XCTCPUMetric(application: app),
                          XCTMemoryMetric(application: app), XCTClockMetric()], options: options) {
            let started = Date()
            for (from, to) in [(0.7, 0.3), (0.3, 0.7), (0.5, 0.5)] {
                let a = app.coordinate(withNormalizedOffset: CGVector(dx: from, dy: 0.42))
                let b = app.coordinate(withNormalizedOffset: CGVector(dx: to, dy: from == to ? 0.62 : 0.48))
                a.press(forDuration: 0.02, thenDragTo: b, withVelocity: .slow, thenHoldForDuration: 0)
            }
            seconds.append(Date().timeIntervalSince(started))
        }
        try MassTest.write(["size": size, "panBlockSeconds": seconds],
                           to: out.appendingPathComponent("perf-\(size)-pan.json"))
    }

    /// Two fingers turned far enough to turn the plot a quarter, then the wait
    /// until it answers again: every plant is photographed from the new side.
    func testRotate() throws {
        try prepare()
        let out = try MassTest.outputFolder()
        let app = XCUIApplication()
        app.launchArguments = arguments(["-pgOpen", "garden"])
        app.launch()
        _ = app.buttons["garden.tray"].waitForExistence(timeout: 900)
        _ = waitUntilResponsive(app, limit: 900)

        var runs: [[String: Any]] = []
        let options = XCTMeasureOptions()
        options.iterationCount = 3
        measure(metrics: [XCTHitchMetric(application: app), XCTCPUMetric(application: app),
                          XCTMemoryMetric(application: app), XCTClockMetric()], options: options) {
            let started = Date()
            app.rotate(0.95, withVelocity: 1.6)
            let (settled, probes, calmAt) = waitUntilResponsive(app, limit: 600)
            runs.append(["seconds": calmAt.timeIntervalSince(started), "settled": settled,
                         "slowestProbeSeconds": probes.max() ?? 0])
        }
        try MassTest.write(["size": size, "turns": runs],
                           to: out.appendingPathComponent("perf-\(size)-rotate.json"))
    }

    /// Probes the app with one cheap query a second until three in a row come
    /// back within a quarter of a second. Answers whether it got there, every
    /// probe's time, and when the first of the three quick ones was asked.
    @discardableResult
    private func waitUntilResponsive(_ app: XCUIApplication, limit: Double) -> (Bool, [Double], Date) {
        let started = Date()
        var quick: [Date] = []
        var probes: [Double] = []
        while Date().timeIntervalSince(started) < limit {
            let asked = Date()
            _ = app.buttons["garden.tray"].exists
            let took = Date().timeIntervalSince(asked)
            probes.append(took)
            quick = took < 0.25 ? quick + [asked] : []
            if quick.count >= 3 { return (true, probes, quick[0]) }
            MassTest.pause(max(0, 1 - took))
        }
        return (false, probes, Date())
    }
}
