import SeedCore
import SwiftUI
import UIKit
import XCTest
@testable import PeaceGarden

/// **The loading animation: what it is made of, how long it runs, and that it
/// stays quiet when asked.**
///
/// Two variants were drawn for Marcus to choose between (`design/loading-2026-10-10`),
/// and what is pinned here is what the choice cannot change: the mark at rest is
/// the app icon's mark, nothing waits on the work behind it, the hand-over is the
/// suite's, and Reduce Motion and `off` take it away.
///
/// The last test writes pictures and asserts nothing. It is skipped unless
/// `PG_RENDER_LOADING` names a folder (passed to the test runner as
/// `TEST_RUNNER_PG_RENDER_LOADING`), as the sky and the worlds are.
@MainActor
final class LoadingTests: XCTestCase {

    // MARK: - The mark at rest is the icon at rest

    /// `tools/icon/icon.svg`, the drawing the app icon is made from, puts the
    /// mouth of the bract at (657.36, 430.62) on its 1024 tile, the coil's tip at
    /// (495.99, 591.99), and draws everything at 41.47. A port that had drifted
    /// from the script would put them elsewhere, and the picture would still look
    /// like a coil.
    func testTheMarkAtRestIsTheIconAtRest() {
        let rest = UnwindingMarkGeometry.rest
        let placement = rest.tilePlacement
        func tile(_ p: CGPoint) -> CGPoint {
            CGPoint(x: p.x * placement.scale + placement.offset.x,
                    y: p.y * placement.scale + placement.offset.y)
        }
        let figure = UnwindingMarkGeometry.figure(coil: 1, bract: 1, spike: 1)

        XCTAssertEqual(figure.coil.count, 513)
        XCTAssertEqual(figure.bract.count, 322)
        XCTAssertEqual(figure.spike.count, 186)

        XCTAssertEqual(tile(figure.coil.first!).x, 495.99, accuracy: 0.05)
        XCTAssertEqual(tile(figure.coil.first!).y, 591.99, accuracy: 0.05)
        XCTAssertEqual(tile(figure.coil.last!).x, 657.36, accuracy: 0.05)
        XCTAssertEqual(tile(figure.coil.last!).y, 430.62, accuracy: 0.05)
        XCTAssertEqual(tile(figure.bract.first!).x, 657.36, accuracy: 0.05)
        XCTAssertEqual(tile(figure.bract.first!).y, 430.62, accuracy: 0.05)
        XCTAssertEqual(tile(figure.spike.first!).x, 674.19, accuracy: 0.05)
        XCTAssertEqual(tile(figure.spike.first!).y, 418.52, accuracy: 0.05)
        XCTAssertEqual(tile(figure.spike.last!).x, 640.52, accuracy: 0.05)
        XCTAssertEqual(tile(figure.spike.last!).y, 442.73, accuracy: 0.05)

        XCTAssertEqual(UnwindingMarkGeometry.stroke * placement.scale, 41.47, accuracy: 0.01)

        // The sweep runs across the coil and the taper, bottom-left to top-right:
        // the icon's `sweep` gradient is (294.03, 834.00) to (729.97, 287.53).
        let sweep = rest.sweepBounds
        XCTAssertEqual(tile(CGPoint(x: sweep.minX, y: sweep.maxY)).x, 294.03, accuracy: 0.05)
        XCTAssertEqual(tile(CGPoint(x: sweep.minX, y: sweep.maxY)).y, 834.00, accuracy: 0.05)
        XCTAssertEqual(tile(CGPoint(x: sweep.maxX, y: sweep.minY)).x, 729.97, accuracy: 0.05)
        XCTAssertEqual(tile(CGPoint(x: sweep.maxX, y: sweep.minY)).y, 287.53, accuracy: 0.05)
    }

    // MARK: - Unwinding is not a trim

    /// `design/Motion.dc.html`: *trimming a fixed spiral reads as a line being
    /// drawn on.* The coil keeps every point it has, its length does not change,
    /// and it stays fastened where it meets the bract.
    func testTheCoilKeepsItsLengthAndItsMouthWhileItUnwinds() {
        let rest = UnwindingMarkGeometry.figure(coil: 1, bract: 1, spike: 1).coil
        let restLength = UnwindingMarkGeometry.Construction.length(of: rest)
        for open in [0.0, 0.25, 0.5, 0.75, 0.95] {
            let coil = UnwindingMarkGeometry.figure(coil: open, bract: 1, spike: 1).coil
            XCTAssertEqual(coil.count, rest.count)
            XCTAssertEqual(UnwindingMarkGeometry.Construction.length(of: coil), restLength,
                           accuracy: restLength * 1e-9, "length at \(open)")
            XCTAssertEqual(coil.last!.x, rest.last!.x, accuracy: 1e-6)
            XCTAssertEqual(coil.last!.y, rest.last!.y, accuracy: 1e-6)
            XCTAssertGreaterThan(hypot(coil.first!.x - rest.first!.x, coil.first!.y - rest.first!.y), 1,
                                 "the tip should have moved at \(open)")
        }
    }

    func testTheFullyOpenCoilIsExactlyTheMark() {
        let rest = UnwindingMarkGeometry.rest.coil
        XCTAssertEqual(UnwindingMarkGeometry.figure(coil: 1, bract: 1, spike: 1).coil, rest)
        // And more than one is no more than one.
        XCTAssertEqual(UnwindingMarkGeometry.figure(coil: 3, bract: 1, spike: 1).coil, rest)
    }

    /// The bract is stroked at the mark's full weight, so a bract that was merely
    /// narrowed to nothing would be a white bar the length of the leaf. It is
    /// scaled about its mouth instead, so at nothing it is nowhere.
    func testAClosedBractIsAPointAtItsMouth() {
        let figure = UnwindingMarkGeometry.figure(coil: 1, bract: 0, spike: 0)
        let mouth = UnwindingMarkGeometry.rest.spine[0]
        for p in figure.bract {
            XCTAssertEqual(p.x, mouth.x, accuracy: 1e-9)
            XCTAssertEqual(p.y, mouth.y, accuracy: 1e-9)
        }
        let bud = Fiddlehead.figure(open: 0)
        let tip = bud.stem.last!
        for p in bud.bract {
            XCTAssertEqual(p.x, tip.x, accuracy: 1e-9)
            XCTAssertEqual(p.y, tip.y, accuracy: 1e-9)
        }
    }

    /// Marcus's rule is no straight lines anywhere. A coil and a stem that curve
    /// everywhere can be checked, and the stem is the one that nearly failed: at
    /// the backdrop's taper it is a ruler for two thirds of its length.
    func testNeitherDrawingHasAStraightRun() {
        func straightestWindow(_ points: [CGPoint]) -> Double {
            let window = points.count / 5
            var smallest = Double.infinity
            var headings: [Double] = []
            for i in 1..<points.count {
                headings.append(atan2(points[i].y - points[i - 1].y, points[i].x - points[i - 1].x))
            }
            for start in stride(from: 0, to: headings.count - window, by: 4) {
                // Total variation, so that an S-bend whose two halves cancel is
                // still a bend.
                var variation = 0.0
                for i in start..<(start + window - 1) { variation += abs(headings[i + 1] - headings[i]) }
                smallest = min(smallest, variation)
            }
            return smallest * 180 / .pi
        }
        for open in [0.0, 0.5, 1.0] {
            XCTAssertGreaterThan(straightestWindow(UnwindingMarkGeometry.figure(coil: open, bract: 1, spike: 1).coil),
                                 2, "coil at \(open)")
            XCTAssertGreaterThan(straightestWindow(Fiddlehead.figure(open: open).stem), 2, "stem at \(open)")
        }
        XCTAssertGreaterThan(straightestWindow(UnwindingMarkGeometry.rest.spine), 2, "the bract's spine")
    }

    func testTheFrondDoesNotGrowItUncurls() {
        let reference = Fiddlehead.figure(open: 0).stem
        func length(_ p: [CGPoint]) -> Double { UnwindingMarkGeometry.Construction.length(of: p) }
        for open in [0.2, 0.5, 0.9, 1.0] {
            XCTAssertEqual(length(Fiddlehead.figure(open: open).stem), length(reference), accuracy: 1e-6)
        }
    }

    // MARK: - The moment

    func testTheMomentStartsEmptyAndEndsOnTheMarkAtRest() {
        let first = UnwindingMark.pose(atMoment: 0)
        XCTAssertEqual(first.appear, 0, "the first frame is not a pop")
        XCTAssertNil(first.sheen)
        XCTAssertEqual(UnwindingMark.pose(atMoment: 1), UnwindingMark.resting)
        XCTAssertEqual(UnwindingMark.pose(atMoment: 2), UnwindingMark.resting, "clamped, not extrapolated")

        XCTAssertEqual(Fiddlehead.pose(atMoment: 0).appear, 0)
        XCTAssertEqual(Fiddlehead.pose(atMoment: 1).open, Fiddlehead.composed, accuracy: 1e-12)
        XCTAssertLessThan(Fiddlehead.composed, 1)
    }

    /// The coil goes first, the bract after it and the taper last, and the light
    /// crosses the mark that has opened rather than the one that is opening.
    func testTheBeatsRunInOrder() {
        let early = UnwindingMark.pose(atMoment: 0.5)
        XCTAssertGreaterThan(early.coil, early.bract)
        XCTAssertGreaterThan(early.bract, early.spike)
        XCTAssertNil(early.sheen, "no light before the mark has opened")

        let late = UnwindingMark.pose(atMoment: 0.75)
        let band = try! XCTUnwrap(late.sheen)
        XCTAssertTrue((-0.25...1.25).contains(band))
        XCTAssertEqual(late.coil, 1, accuracy: 1e-12)

        var previous = -1.0
        for step in 0...20 {
            let coil = UnwindingMark.pose(atMoment: Double(step) / 20).coil
            XCTAssertGreaterThanOrEqual(coil, previous)
            previous = coil
        }
    }

    /// UnCubed's argument for why a splash cannot report anything: the pose is a
    /// function of the clock alone. Asked twice, it says the same thing.
    func testThePoseIsAFunctionOfTheClockAlone() {
        for t in stride(from: 0.0, through: 1.0, by: 0.1) {
            XCTAssertEqual(UnwindingMark.pose(atMoment: t), UnwindingMark.pose(atMoment: t))
            XCTAssertEqual(Fiddlehead.pose(atMoment: t), Fiddlehead.pose(atMoment: t))
        }
    }

    // MARK: - The figures that are the suite's

    func testTheHandOverIsTheSuites() {
        XCTAssertEqual(LoadingTiming.markFade, 0.12, "UnCubed's markFade, FlagFans's MARK_FADE_MS")
        XCTAssertEqual(LoadingTiming.dissolve, 0.18, "UnCubed's dissolve, FlagFans's GROUND_FADE_MS")
        XCTAssertLessThan(LoadingTiming.markFade, LoadingTiming.dissolve,
                          "the mark leaves before the ground, so it never floats over the app")
        XCTAssertEqual(LoadingTiming.busyThreshold, 0.4, "UnCubed's slowWorkThreshold")
    }

    func testTheMomentIsTheAppsOwnArrival() {
        XCTAssertEqual(LoadingTiming.moment, 1.2, "design/Motion.dc.html: a line or a control arriving")
        XCTAssertEqual(LoadingTiming.breath, 2 * LoadingTiming.moment, "open, then furl")
        XCTAssertEqual(LoadingTiming.progress(elapsed: -1), 0)
        XCTAssertEqual(LoadingTiming.progress(elapsed: 0.6), 0.5, accuracy: 1e-12)
        XCTAssertEqual(LoadingTiming.progress(elapsed: 99), 1)
    }

    func testTheBreathJoinsItselfAtTheFurledEnd() {
        XCTAssertEqual(LoadingTiming.openness(atBreath: 0), 0, accuracy: 1e-12)
        XCTAssertEqual(LoadingTiming.openness(atBreath: 0.5), 1, accuracy: 1e-12)
        XCTAssertEqual(LoadingTiming.openness(atBreath: 1), LoadingTiming.openness(atBreath: 0), accuracy: 1e-12)
        XCTAssertEqual(LoadingTiming.breathPhase(elapsed: LoadingTiming.breath), 0, accuracy: 1e-12)
        XCTAssertEqual(LoadingTiming.breathPhase(elapsed: LoadingTiming.breath * 2.25), 0.25, accuracy: 1e-9)
        XCTAssertEqual(LoadingTiming.breathPhase(elapsed: -LoadingTiming.breath * 0.25), 0.75, accuracy: 1e-9)
    }

    // MARK: - Asking it to be quiet

    /// All three suite apps give Reduce Motion no moment at all, not a shorter one.
    func testReduceMotionAndOffTakeTheMomentAway() {
        XCTAssertTrue(LaunchMomentHost.plays(style: .unwinding, reduceMotion: false, alreadyPlayed: false))
        XCTAssertTrue(LaunchMomentHost.plays(style: .frond, reduceMotion: false, alreadyPlayed: false))
        XCTAssertFalse(LaunchMomentHost.plays(style: .unwinding, reduceMotion: true, alreadyPlayed: false))
        XCTAssertFalse(LaunchMomentHost.plays(style: .frond, reduceMotion: true, alreadyPlayed: false))
        XCTAssertFalse(LaunchMomentHost.plays(style: .off, reduceMotion: false, alreadyPlayed: false))
        XCTAssertFalse(LaunchMomentHost.plays(style: .unwinding, reduceMotion: false, alreadyPlayed: true),
                       "a second window is not a launch")
    }

    func testTheWaitingMarkHoldsStillWithTheStatementKept() {
        // Still, not blank: the mark itself, and the frond half open.
        XCTAssertEqual(UnwindingMark.still, UnwindingMark.resting)
        XCTAssertGreaterThan(Fiddlehead.still.open, 0.5)
        XCTAssertLessThan(Fiddlehead.still.open, 1)
    }

    func testTheSwitchDefaultsToTheRecommendedVariantAndReadsALaunchArgument() throws {
        let suite = "loading-tests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        XCTAssertEqual(LoadingSwitch.style(in: defaults), .unwinding)
        for style in LoadingStyle.allCases {
            defaults.set(style.rawValue, forKey: LoadingSwitch.key)
            XCTAssertEqual(LoadingSwitch.style(in: defaults), style)
        }
        defaults.set("not a variant", forKey: LoadingSwitch.key)
        XCTAssertEqual(LoadingSwitch.style(in: defaults), .unwinding)
        XCTAssertEqual(LoadingSwitch.key, "loading.style.v1")
    }

    // MARK: - It draws something

    /// A smoke test: both drawings put ink on the ground in both dresses. It would
    /// catch a `Canvas` that drew nothing, which is the failure a geometry test
    /// cannot see.
    func testBothDrawingsPutInkOnTheGround() throws {
        func inkFraction(_ view: some View) throws -> Double {
            let renderer = ImageRenderer(content: view.frame(width: 120, height: 120))
            renderer.scale = 1
            let image = try XCTUnwrap(renderer.uiImage?.cgImage)
            let data = try XCTUnwrap(image.dataProvider?.data)
            let bytes = CFDataGetBytePtr(data)!
            let count = image.width * image.height
            var lit = 0
            for i in 0..<count {
                let r = Int(bytes[i * 4]), g = Int(bytes[i * 4 + 1]), b = Int(bytes[i * 4 + 2])
                if r + g + b > 120 { lit += 1 }
            }
            return Double(lit) / Double(count)
        }
        let brand = try inkFraction(ZStack {
            UnwindingMark.ground
            UnwindingMarkView(pose: UnwindingMark.resting)
        })
        let ink = try inkFraction(ZStack {
            Color.black
            UnwindingMarkView(pose: UnwindingMark.still, dress: .ink(.white))
        })
        let frond = try inkFraction(ZStack {
            Color.black
            FiddleheadView(pose: Fiddlehead.pose(atMoment: 1), ink: Fiddlehead.gold, weight: 2, halo: 0)
        })
        XCTAssertGreaterThan(brand, 0.04)
        XCTAssertGreaterThan(ink, 0.04)
        XCTAssertGreaterThan(frond, 0.01)
        let nothing = try inkFraction(ZStack {
            UnwindingMark.ground
            UnwindingMarkView(pose: UnwindingMark.pose(atMoment: 0))
        })
        XCTAssertEqual(nothing, 0, accuracy: 1e-9, "the first frame is the ground and nothing else")
    }

    // MARK: - The pictures

    /// Writes the frames the filmstrips and the video are made from. Skipped
    /// unless `PG_RENDER_LOADING` names a folder.
    ///
    /// The launch moment is drawn the way `LaunchMoment` draws it — ground, then
    /// the mark at the pose the clock gives — over a stand-in for the stage: the
    /// app's own `StageBackdrop` and a grown plant, in both appearances, so that
    /// the hand-over is seen against the thing it hands over to. 30 frames a
    /// second, the moment and then the 180 ms dissolve.
    func testWriteTheLoadingFrames() async throws {
        guard let path = ProcessInfo.processInfo.environment["PG_RENDER_LOADING"], !path.isEmpty else {
            throw XCTSkip("PG_RENDER_LOADING is not set")
        }
        let folder = URL(fileURLWithPath: path, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let seed = SeedID(bytes: seedDigest(SeedDomain.seed, Data("loading-frames".utf8)))!
        let genome = Genome(seed: seed, lineage: .minted)
        let birth = Date(timeIntervalSinceNow: -60 * 86_400)
        let growth = GrowthModel(genome: genome).state(birth: birth, now: Date())
        let plant = ThumbnailRenderer.shared.image(genome: genome, growth: growth, size: 360)

        let phone = CGSize(width: 390, height: 844)
        let fps = 30.0
        let momentFrames = Int((LoadingTiming.moment * fps).rounded())
        let dissolveFrames = Int((LoadingTiming.dissolve * fps).rounded())
        var notes: [String] = [
            "phone \(Int(phone.width))x\(Int(phone.height)) pt at 2x, \(Int(fps)) fps",
            "moment \(LoadingTiming.moment) s = \(momentFrames) frames; dissolve \(LoadingTiming.dissolve) s = \(dissolveFrames) frames",
        ]

        func stage(_ scheme: ColorScheme) -> some View {
            ZStack {
                Chrome.ground
                StageBackdrop(palette: genome.palette)
                if let plant { Image(uiImage: plant).resizable().scaledToFit().padding(.horizontal, 20) }
            }
            .environment(\.colorScheme, scheme)
        }

        func frame(_ name: String, style: LoadingStyle, scheme: ColorScheme, t: Double,
                   markOpacity: Double, fieldOpacity: Double) throws {
            let markFrame = LaunchMoment.markFrame(for: style, short: min(phone.width, phone.height))
            let content = ZStack {
                stage(scheme)
                ZStack {
                    (style == .unwinding ? UnwindingMark.ground : Chrome.ground)
                    switch style {
                    case .unwinding:
                        UnwindingMarkView(pose: UnwindingMark.pose(atMoment: t), dress: .brand)
                            .frame(width: markFrame.width, height: markFrame.height)
                            .opacity(markOpacity)
                    case .frond:
                        FiddleheadView(pose: Fiddlehead.pose(atMoment: t),
                                       ink: scheme == .dark ? Fiddlehead.gold.opacity(0.95) : Chrome.ink.opacity(0.8),
                                       weight: 1.8, halo: 10)
                            .frame(width: markFrame.width, height: markFrame.height)
                            .opacity(markOpacity)
                    case .off:
                        EmptyView()
                    }
                }
                .opacity(fieldOpacity)
            }
            .frame(width: phone.width, height: phone.height)
            .environment(\.colorScheme, scheme)
            let renderer = ImageRenderer(content: content)
            renderer.scale = 2
            let image = try XCTUnwrap(renderer.uiImage)
            try XCTUnwrap(image.pngData()).write(to: folder.appendingPathComponent("\(name).png"))
        }

        for (style, label) in [(LoadingStyle.unwinding, "a"), (LoadingStyle.frond, "b")] {
            for (scheme, mode) in [(ColorScheme.dark, "dark"), (ColorScheme.light, "light")] {
                // The moment, then the rest frame once more, then the dissolve.
                for index in 0...momentFrames {
                    let t = Double(index) / Double(momentFrames)
                    try frame("\(label)-\(mode)-\(String(format: "%03d", index))", style: style, scheme: scheme,
                              t: t, markOpacity: 1, fieldOpacity: 1)
                }
                for step in 1...dissolveFrames {
                    let seconds = Double(step) / fps
                    // easeOut for the mark and easeInOut for the ground, as
                    // `LaunchMoment.leave()` asks for; the curves are approximated
                    // by their quadratic and smoothstep cousins.
                    let leaving = min(seconds / LoadingTiming.markFade, 1)
                    let markOpacity = (1 - leaving) * (1 - leaving)
                    let fieldOpacity = 1 - LoadingTiming.smooth(seconds / LoadingTiming.dissolve)
                    try frame("\(label)-\(mode)-\(String(format: "%03d", momentFrames + step))", style: style,
                              scheme: scheme, t: 1, markOpacity: markOpacity, fieldOpacity: fieldOpacity)
                }
                notes.append("\(label)-\(mode): \(momentFrames + dissolveFrames + 1) frames")
            }
        }

        // The waiting mark: one breath, twelve frames, on the app's ground and
        // standing in for the dimmed screen it appears over.
        let breathFrames = 12
        for (label, style) in [("a", LoadingStyle.unwinding), ("b", LoadingStyle.frond)] {
            for (scheme, mode) in [(ColorScheme.dark, "dark"), (ColorScheme.light, "light")] {
                for index in 0..<breathFrames {
                    let phase = Double(index) / Double(breathFrames)
                    let panel = ZStack {
                        Chrome.ground
                        VStack(spacing: 6) {
                            QuietButton(title: "Done", isProminent: true) {}
                            QuietButton(title: "Done") {}
                        }
                        .opacity(0.4)
                        Group {
                            switch style {
                            case .unwinding:
                                UnwindingMarkView(pose: UnwindingMark.pose(atBreath: phase), dress: .ink(Chrome.ink))
                                    .frame(width: 40, height: 40)
                            case .frond:
                                FiddleheadView(pose: Fiddlehead.pose(atBreath: phase),
                                               ink: Chrome.ink.opacity(0.85), weight: 1.5, halo: 0)
                                    .frame(width: 32, height: 40)
                            case .off:
                                EmptyView()
                            }
                        }
                    }
                    .frame(width: 220, height: 150)
                    .environment(\.colorScheme, scheme)
                    let renderer = ImageRenderer(content: panel)
                    renderer.scale = 3
                    let image = try XCTUnwrap(renderer.uiImage)
                    try XCTUnwrap(image.pngData()).write(
                        to: folder.appendingPathComponent("\(label)-busy-\(mode)-\(String(format: "%02d", index)).png"))
                }
            }
        }

        // Reduce Motion: the waiting mark held still.
        for (label, style) in [("a", LoadingStyle.unwinding), ("b", LoadingStyle.frond)] {
            let still = ZStack {
                Chrome.ground
                switch style {
                case .unwinding:
                    UnwindingMarkView(pose: UnwindingMark.still, dress: .ink(Chrome.ink)).frame(width: 40, height: 40)
                case .frond:
                    FiddleheadView(pose: Fiddlehead.still, ink: Chrome.ink.opacity(0.85), weight: 1.5, halo: 0)
                        .frame(width: 32, height: 40)
                case .off:
                    EmptyView()
                }
            }
            .frame(width: 220, height: 150)
            .environment(\.colorScheme, .dark)
            let renderer = ImageRenderer(content: still)
            renderer.scale = 3
            try XCTUnwrap(XCTUnwrap(renderer.uiImage).pngData())
                .write(to: folder.appendingPathComponent("\(label)-busy-reduce-motion.png"))
        }

        try notes.joined(separator: "\n").write(to: folder.appendingPathComponent("notes.txt"),
                                                atomically: true, encoding: .utf8)
    }
}
