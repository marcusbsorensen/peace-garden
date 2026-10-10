import SeedCore
import SwiftUI
import UIKit
import XCTest
@testable import PeaceGarden

/// **The loading animation: what it is made of, how long it runs, that it can be
/// read on the ground it is drawn on, and that it stays quiet when asked.**
///
/// Marcus chose the fiddlehead on 10 October 2026, in the app's colours, growing
/// up out of the ground as it unfurls, over 2.0 s, on the suite's dark ground in
/// both appearances. What is pinned here is what those choices cannot lose.
///
/// The last test writes pictures and asserts nothing. It is skipped unless
/// `PG_RENDER_LOADING` names a folder (passed to the test runner as
/// `TEST_RUNNER_PG_RENDER_LOADING`), as the sky and the worlds are.
@MainActor
final class LoadingTests: XCTestCase {

    private typealias RGB = Fiddlehead.Palette.RGB

    private func length(_ points: [CGPoint]) -> Double {
        var total = 0.0
        for index in 1..<points.count {
            total += hypot(points[index].x - points[index - 1].x, points[index].y - points[index - 1].y)
        }
        return total
    }

    // MARK: - It grows, and it unfurls while it grows

    /// The root is a fixed point: at every rise and every opening the stem leaves the
    /// same place, whichever anchor puts that place on the screen.
    func testTheRootStaysWhereItLeaves() {
        let root = Fiddlehead.rootPoint
        for rise in [0.0, 0.3, 0.7, 1.0] {
            for open in [0.0, 0.5, 1.0] {
                let stem = Fiddlehead.figure(open: open, rise: rise).stem
                XCTAssertEqual(stem.first!.x, root.x, accuracy: 1e-9)
                XCTAssertEqual(stem.first!.y, root.y, accuracy: 1e-9)
            }
        }
    }

    /// **Variant 1**: the stem enters from the very bottom edge of the screen. At the
    /// first moment its tip is at the edge and nothing is on the screen; at the end
    /// it is still entering from the edge, and the whole plant is on the screen,
    /// across and up.
    func testTheEdgeAnchorEntersFromTheBottomOfTheScreen() {
        for screen in [CGSize(width: 390, height: 844), CGSize(width: 440, height: 956),
                       CGSize(width: 820, height: 1180)] {
            let placement = Fiddlehead.Placement.bottomEdge(in: screen)
            func canvas(_ open: Double, _ rise: Double) -> [CGPoint] {
                let figure = Fiddlehead.figure(open: open, rise: rise)
                return (figure.stem + figure.bract).map(placement.place)
            }
            // The first moment: the highest point is at the edge, to a hair.
            let start = canvas(0, 0)
            XCTAssertEqual(start.map(\.y).min()!, screen.height, accuracy: 0.01, "\(screen)")
            // The root is below the edge at every moment, so the stem always comes in
            // through it, and the edge is the only thing it is fastened to.
            XCTAssertGreaterThanOrEqual(placement.place(Fiddlehead.rootPoint).y, screen.height)
            // And it comes up through the edge: by the time it is half grown its tip
            // is well on the screen.
            XCTAssertLessThan(canvas(0.5, 0.5).map(\.y).min()!, screen.height * 0.9)
            // The grown plant is on the screen, and centred across it within a tenth.
            let grown = canvas(Fiddlehead.composed, 1)
            XCTAssertGreaterThan(grown.map(\.x).min()!, 0, "\(screen)")
            XCTAssertLessThan(grown.map(\.x).max()!, screen.width, "\(screen)")
            XCTAssertGreaterThan(grown.map(\.y).min()!, 0, "\(screen)")
            let middle = (grown.map(\.x).min()! + grown.map(\.x).max()!) / 2
            XCTAssertEqual(middle, screen.width / 2, accuracy: screen.width * 0.1, "\(screen)")
            // And it is tall: at least a third of the screen.
            XCTAssertGreaterThan(screen.height - grown.map(\.y).min()!, screen.height / 3, "\(screen)")
        }
    }

    /// **Variant 2**: a fixed point in space with nothing beneath it. The root does
    /// not move on the canvas, and nothing at any pose leaves the frame it is given.
    func testTheFixedAnchorIsAPointThatDoesNotMove() {
        let frame = CGSize(width: 187, height: 280)
        let placement = Fiddlehead.Placement.fixedPoint(in: frame)
        let root = placement.place(Fiddlehead.rootPoint)
        var lowest = -Double.infinity
        for rise in stride(from: 0.0, through: 1.0, by: 0.25) {
            for open in stride(from: 0.0, through: 1.0, by: 0.25) {
                let figure = Fiddlehead.figure(open: open, rise: rise)
                XCTAssertEqual(placement.place(figure.stem[0]).x, root.x, accuracy: 1e-9)
                XCTAssertEqual(placement.place(figure.stem[0]).y, root.y, accuracy: 1e-9)
                for p in (figure.stem + figure.bract).map(placement.place) {
                    XCTAssertGreaterThanOrEqual(p.x, 0)
                    XCTAssertLessThanOrEqual(p.x, frame.width)
                    XCTAssertGreaterThanOrEqual(p.y, 0)
                    XCTAssertLessThanOrEqual(p.y, frame.height)
                    lowest = max(lowest, Double(p.y))
                }
            }
        }
        // Nothing is drawn below the root: it is the lowest thing there is.
        XCTAssertEqual(lowest, Double(root.y), accuracy: 1e-6)
        // And the plant is centred in its frame as a whole.
        XCTAssertEqual(placement.place(CGPoint(x: Fiddlehead.travel.midX, y: Fiddlehead.travel.midY)).x,
                       frame.width / 2, accuracy: 1e-9)
        XCTAssertEqual(placement.place(CGPoint(x: Fiddlehead.travel.midX, y: Fiddlehead.travel.midY)).y,
                       frame.height / 2, accuracy: 1e-9)
    }

    /// It *grows*: unlike the backdrop's frond, whose arc length never changes, this
    /// one is longer the higher it has risen, and the curl lets go without changing
    /// the length it has.
    func testTheStemLengthensWithRiseAndNotWithOpening() {
        let full = Fiddlehead.frame.height * Fiddlehead.plan.length
        XCTAssertEqual(length(Fiddlehead.figure(open: 0.5, rise: 1).stem), full, accuracy: full * 1e-9)
        XCTAssertEqual(length(Fiddlehead.figure(open: 0.5, rise: 0).stem), full * Fiddlehead.emerging,
                       accuracy: full * 1e-9)
        var previous = 0.0
        for rise in stride(from: 0.0, through: 1.0, by: 0.1) {
            let now = length(Fiddlehead.figure(open: 0.5, rise: rise).stem)
            XCTAssertGreaterThan(now, previous)
            previous = now
        }
        for open in [0.0, 0.3, 0.6, 1.0] {
            XCTAssertEqual(length(Fiddlehead.figure(open: open, rise: 0.6).stem),
                           length(Fiddlehead.figure(open: 0, rise: 0.6).stem), accuracy: 1e-6)
        }
    }

    /// *"At the start it is a curled tip just emerging."*
    func testItStartsAsASmallCurl() {
        let start = Fiddlehead.figure(open: 0, rise: 0).stem
        let grown = Fiddlehead.figure(open: Fiddlehead.composed, rise: 1).stem
        let root = start[0].y
        let startHeight = root - start.map(\.y).min()!
        let grownHeight = root - grown.map(\.y).min()!
        XCTAssertGreaterThan(startHeight, 0, "it must stand up from its root")
        XCTAssertLessThan(startHeight, grownHeight * 0.25)
        // A curl and not a stick: the stem has turned through more than a turn.
        let end = start.suffix(2)
        let first = start[1].x - start[0].x, second = start[1].y - start[0].y
        let last = end.last!.x - end.first!.x, lastY = end.last!.y - end.first!.y
        let turned = abs(atan2(lastY, last) - atan2(second, first))
        XCTAssertGreaterThan(turned, 0.5)
    }

    /// The highest point of the drawing rises, whatever the opening.
    func testTheTipRisesAsItGrows() {
        for open in [0.0, 0.9] {
            var previous = Double.infinity
            for rise in stride(from: 0.0, through: 1.0, by: 0.1) {
                let figure = Fiddlehead.figure(open: open, rise: rise)
                let top = (figure.stem + figure.bract).map(\.y).min()!
                XCTAssertLessThan(top, previous, "open \(open), rise \(rise)")
                previous = top
            }
        }
    }

    /// *"Rising and unfurling overlap; they are not two steps."* In the middle of
    /// the moment both are part way, and neither beat has finished before the other
    /// has begun.
    func testRisingAndUnfurlingOverlap() {
        for t in stride(from: 0.2, through: 0.8, by: 0.1) {
            let pose = Fiddlehead.pose(atMoment: t)
            XCTAssertGreaterThan(pose.rise, 0, "t \(t)")
            XCTAssertLessThan(pose.rise, 1, "t \(t)")
            XCTAssertGreaterThan(pose.open, 0, "t \(t)")
            XCTAssertLessThan(pose.open, Fiddlehead.composed, "t \(t)")
        }
        // By the time the stem has risen half way the curl is already letting go,
        // and by the time the curl is half let go the stem is still rising.
        var halfRise = 0.0
        var halfOpen = 0.0
        for step in 0...1000 {
            let t = Double(step) / 1000
            let pose = Fiddlehead.pose(atMoment: t)
            if halfRise == 0, pose.rise >= 0.5 { halfRise = t; XCTAssertGreaterThan(pose.open, 0.1) }
            if halfOpen == 0, pose.open >= Fiddlehead.composed * 0.5 { halfOpen = t; XCTAssertLessThan(pose.rise, 1) }
        }
        XCTAssertGreaterThan(halfRise, 0)
        XCTAssertGreaterThan(halfOpen, 0)
        XCTAssertLessThan(abs(halfRise - halfOpen), 0.1, "they are one gesture, not a queue")
    }

    func testTheMomentStartsEmptyAndEndsComposed() {
        let first = Fiddlehead.pose(atMoment: 0)
        XCTAssertEqual(first.appear, 0, "the first frame is the ground and nothing else")
        XCTAssertEqual(first.rise, 0)
        XCTAssertEqual(first.open, 0)
        let last = Fiddlehead.pose(atMoment: 1)
        XCTAssertEqual(last.rise, 1, accuracy: 1e-12)
        XCTAssertEqual(last.open, Fiddlehead.composed, accuracy: 1e-12)
        XCTAssertEqual(last.appear, 1)
        XCTAssertEqual(Fiddlehead.pose(atMoment: 2), last, "clamped, not extrapolated")
        XCTAssertLessThan(Fiddlehead.composed, 1)

        var previousRise = -1.0, previousOpen = -1.0
        for step in 0...40 {
            let pose = Fiddlehead.pose(atMoment: Double(step) / 40)
            XCTAssertGreaterThanOrEqual(pose.rise, previousRise)
            XCTAssertGreaterThanOrEqual(pose.open, previousOpen)
            previousRise = pose.rise
            previousOpen = pose.open
        }
    }

    /// UnCubed's argument for why a splash cannot report anything: the pose is a
    /// function of the clock alone. Asked twice, it says the same thing.
    func testThePoseIsAFunctionOfTheClockAlone() {
        for t in stride(from: 0.0, through: 1.0, by: 0.1) {
            XCTAssertEqual(Fiddlehead.pose(atMoment: t), Fiddlehead.pose(atMoment: t))
        }
        for p in stride(from: 0.0, through: 1.0, by: 0.1) {
            XCTAssertEqual(Fiddlehead.pose(atBreath: p), Fiddlehead.pose(atBreath: p))
        }
    }

    /// The waiting mark is a smaller version of the same thing: it never gets as
    /// high or as open as the moment ends, never furls as tight as it starts, and
    /// the tip moves up and settles back.
    func testTheWaitingMarkIsASmallerVersionOfTheSameThing() {
        let ends = Fiddlehead.pose(atMoment: 1)
        for step in 0...24 {
            let pose = Fiddlehead.pose(atBreath: Double(step) / 24)
            XCTAssertLessThan(pose.rise, ends.rise)
            XCTAssertLessThan(pose.open, ends.open)
            XCTAssertGreaterThan(pose.rise, 0.3, "the tip is always up")
            XCTAssertGreaterThan(pose.open, 0.1, "and always a curl")
        }
        let low = Fiddlehead.pose(atBreath: 0), high = Fiddlehead.pose(atBreath: 0.5)
        XCTAssertGreaterThan(high.rise, low.rise)
        XCTAssertGreaterThan(high.open, low.open)
        XCTAssertEqual(Fiddlehead.pose(atBreath: 1), low, "it joins itself where it is lowest")
    }

    // MARK: - No straight lines

    /// Marcus's rule is no straight lines anywhere. The stem is the one that nearly
    /// failed, so it is measured at several risings and openings: the total turning
    /// in every fifth of it, which does not let an S-bend whose halves cancel pass
    /// as straight.
    func testTheStemHasNoStraightRun() {
        for rise in [0.0, 0.5, 1.0] {
            for open in [0.0, 0.5, 1.0] {
                let points = Fiddlehead.figure(open: open, rise: rise).stem
                let window = points.count / 5
                var headings: [Double] = []
                for i in 1..<points.count {
                    headings.append(atan2(points[i].y - points[i - 1].y, points[i].x - points[i - 1].x))
                }
                var smallest = Double.infinity
                for start in stride(from: 0, to: headings.count - window, by: 4) {
                    var variation = 0.0
                    for i in start..<(start + window - 1) { variation += abs(headings[i + 1] - headings[i]) }
                    smallest = min(smallest, variation)
                }
                XCTAssertGreaterThan(smallest * 180 / .pi, 2, "stem at open \(open), rise \(rise)")
            }
        }
    }

    /// **There is no ground.** Marcus took the soil out on 10 October 2026: every
    /// plant in the app is attached to a 3D ground, floating, or 2D with no soil, and
    /// a drawn line matched none. Asked of the pixels rather than of the code: in both
    /// variants, nothing is lit below the root, and at the screen's bottom edge only
    /// the stem is, a few pixels of it and not a line across.
    func testNothingIsDrawnBelowTheStem() throws {
        func lit(_ view: some View, width: Int, height: Int) throws -> [[Bool]] {
            let renderer = ImageRenderer(content: view.frame(width: CGFloat(width), height: CGFloat(height)))
            renderer.scale = 1
            let image = try XCTUnwrap(renderer.uiImage?.cgImage)
            let data = try XCTUnwrap(image.dataProvider?.data)
            let bytes = CFDataGetBytePtr(data)!
            let ground = (Int(bytes[0]), Int(bytes[1]), Int(bytes[2]))
            var rows: [[Bool]] = []
            for y in 0..<image.height {
                var row: [Bool] = []
                for x in 0..<image.width {
                    let i = (y * image.width + x) * 4
                    let d = abs(Int(bytes[i]) - ground.0) + abs(Int(bytes[i + 1]) - ground.1)
                        + abs(Int(bytes[i + 2]) - ground.2)
                    row.append(d > 30)
                }
                rows.append(row)
            }
            return rows
        }

        // Variant 2: a fixed point. The lowest lit row is the root's, give or take
        // the half stroke and the halo.
        let frame = CGSize(width: 200, height: 300)
        let fixed = try lit(ZStack {
            LaunchMoment.ground
            FiddleheadView(pose: Fiddlehead.pose(atMoment: 1), palette: .onDark, weight: 1.8, halo: 10,
                           anchor: .fixedPoint)
        }, width: 200, height: 300)
        let root = Fiddlehead.Placement.fixedPoint(in: frame).place(Fiddlehead.rootPoint)
        let lowest = fixed.lastIndex { $0.contains(true) }!
        XCTAssertLessThanOrEqual(Double(lowest), Double(root.y) + 7, "nothing below the root")

        // Variant 1: the screen's edge. In the last rows only the stem is lit.
        let edge = try lit(ZStack {
            LaunchMoment.ground
            FiddleheadView(pose: Fiddlehead.pose(atMoment: 1), palette: .onDark, weight: 2.0, halo: 10,
                           anchor: .bottomEdge)
        }, width: 195, height: 422)
        for row in edge.suffix(4) {
            let count = row.filter { $0 }.count
            XCTAssertGreaterThan(count, 0, "the stem comes in through the edge")
            XCTAssertLessThan(count, 24, "and only the stem does: that row is not a line across")
        }
    }

    /// The bract is stroked at the mark's weight, so a bract that was merely
    /// narrowed to nothing would be a bar the length of the leaf. It is scaled
    /// about its mouth instead, so at nothing it is nowhere.
    func testAClosedBractIsAPointAtItsMouth() {
        let bud = Fiddlehead.figure(open: 0, rise: 0.5)
        let tip = bud.stem.last!
        for p in bud.bract {
            XCTAssertEqual(p.x, tip.x, accuracy: 1e-9)
            XCTAssertEqual(p.y, tip.y, accuracy: 1e-9)
        }
    }

    // MARK: - The figures that are the suite's, and the app's

    func testTheHandOverIsTheSuites() {
        XCTAssertEqual(LoadingTiming.markFade, 0.12, "UnCubed's markFade, FlagFans's MARK_FADE_MS")
        XCTAssertEqual(LoadingTiming.dissolve, 0.18, "UnCubed's dissolve, FlagFans's GROUND_FADE_MS")
        XCTAssertLessThan(LoadingTiming.markFade, LoadingTiming.dissolve,
                          "the mark leaves before the ground, so it never floats over the app")
        XCTAssertEqual(LoadingTiming.busyThreshold, 0.4, "UnCubed's slowWorkThreshold")
    }

    func testTheMomentIsTwoSeconds() {
        XCTAssertEqual(LoadingTiming.moment, 2.0, "Marcus, 10 October 2026: FlagFans's length")
        XCTAssertEqual(LoadingTiming.breath, 2.4, "two of the app's own 1.2 s arrivals")
        XCTAssertEqual(LoadingTiming.progress(elapsed: -1), 0)
        XCTAssertEqual(LoadingTiming.progress(elapsed: 1.0), 0.5, accuracy: 1e-12)
        XCTAssertEqual(LoadingTiming.progress(elapsed: 99), 1)
    }

    func testTheBreathJoinsItselfAtTheLowEnd() {
        XCTAssertEqual(LoadingTiming.openness(atBreath: 0), 0, accuracy: 1e-12)
        XCTAssertEqual(LoadingTiming.openness(atBreath: 0.5), 1, accuracy: 1e-12)
        XCTAssertEqual(LoadingTiming.openness(atBreath: 1), LoadingTiming.openness(atBreath: 0), accuracy: 1e-12)
        XCTAssertEqual(LoadingTiming.breathPhase(elapsed: LoadingTiming.breath), 0, accuracy: 1e-12)
        XCTAssertEqual(LoadingTiming.breathPhase(elapsed: LoadingTiming.breath * 2.25), 0.25, accuracy: 1e-9)
        XCTAssertEqual(LoadingTiming.breathPhase(elapsed: -LoadingTiming.breath * 0.25), 0.75, accuracy: 1e-9)
    }

    // MARK: - The colours can be read on the ground they are drawn on

    /// The icon's own greens on the suite's ground are 13.00:1 by construction;
    /// this holds the palette to it, and the white bract to more.
    func testTheLaunchMomentIsLegibleOnTheLaunchGround() {
        let ground = Fiddlehead.Palette.launchGround
        for (index, stop) in Fiddlehead.Palette.onDark.stem.enumerated() {
            XCTAssertEqual(stop.contrast(with: ground), 13.0, accuracy: 0.1, "stop \(index)")
        }
        XCTAssertGreaterThan(Fiddlehead.Palette.onDark.leaf.contrast(with: ground), 18)
    }

    /// The waiting mark follows the app's appearance. On the light ground the
    /// icon's own values would not be seen, so the same hues are solved to 4.5:1
    /// and the leaf is the app's ink.
    func testTheWaitingMarkIsLegibleOnTheLightGround() {
        let ground = Fiddlehead.Palette.lightGround
        let icons = Fiddlehead.Palette.onDark.stem
        XCTAssertLessThan(icons.last!.contrast(with: ground), 2, "the icon's yellow is a mark nobody can see here")
        for (index, stop) in Fiddlehead.Palette.onLight.stem.enumerated() {
            XCTAssertGreaterThanOrEqual(stop.contrast(with: ground), 4.45, "stop \(index)")
        }
        XCTAssertGreaterThan(Fiddlehead.Palette.onLight.leaf.contrast(with: ground), 12)
        // The same three hues, in the same order: forest green, then lime, then
        // yellow, which is to say the red channel rises along the stem.
        let reds = Fiddlehead.Palette.onLight.stem.map(\.r)
        XCTAssertEqual(reds, reds.sorted())
    }

    /// The moment is drawn on the colour the launch screen is painted in, read from
    /// the same asset, and the plist names it: the icon being tapped, the launch
    /// screen and the moment are one colour.
    func testTheMomentGroundIsTheLaunchScreenGroundInBothAppearances() throws {
        let expected = Fiddlehead.Palette.launchGround
        for style in [UIUserInterfaceStyle.light, .dark] {
            let colour = try XCTUnwrap(UIColor(named: "LaunchGround", in: .main,
                                               compatibleWith: UITraitCollection(userInterfaceStyle: style)))
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            colour.getRed(&r, green: &g, blue: &b, alpha: &a)
            XCTAssertEqual(Double(r), expected.r, accuracy: 0.002, "\(style.rawValue)")
            XCTAssertEqual(Double(g), expected.g, accuracy: 0.002)
            XCTAssertEqual(Double(b), expected.b, accuracy: 0.002)
        }
        let launch = try XCTUnwrap(Bundle.main.object(forInfoDictionaryKey: "UILaunchScreen") as? [String: Any])
        XCTAssertEqual(launch["UIColorName"] as? String, "LaunchGround")
    }

    // MARK: - Asking it to be quiet

    /// All three suite apps give Reduce Motion no moment at all, not a shorter one.
    func testReduceMotionAndOffTakeTheMomentAway() {
        for style in [LoadingStyle.edge, .fixed] {
            XCTAssertTrue(LaunchMomentHost.plays(style: style, reduceMotion: false, alreadyPlayed: false))
            XCTAssertFalse(LaunchMomentHost.plays(style: style, reduceMotion: true, alreadyPlayed: false))
            XCTAssertFalse(LaunchMomentHost.plays(style: style, reduceMotion: false, alreadyPlayed: true),
                           "a second window is not a launch")
        }
        XCTAssertFalse(LaunchMomentHost.plays(style: .off, reduceMotion: false, alreadyPlayed: false))
    }

    /// Still, not blank: standing, and a tendril half open or more.
    func testTheWaitingMarkHoldsStillWithTheStatementKept() {
        XCTAssertGreaterThanOrEqual(Fiddlehead.still.open, 0.5)
        XCTAssertLessThan(Fiddlehead.still.open, 1)
        XCTAssertGreaterThan(Fiddlehead.still.rise, 0.5)
    }

    /// Both launch variants are behind the switch until Marcus picks. The recommended
    /// one is the default; a launch argument names either, or `off`; and a value from
    /// an earlier round reads as the default rather than as nothing.
    func testTheSwitchHoldsBothVariantsAndReadsALaunchArgument() throws {
        let suite = "loading-tests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        XCTAssertEqual(LoadingSwitch.style(in: defaults), LoadingSwitch.fallback)
        XCTAssertEqual(LoadingSwitch.fallback, .fixed, "the recommendation: README, 10 October 2026")
        for style in LoadingStyle.allCases {
            defaults.set(style.rawValue, forKey: LoadingSwitch.key)
            XCTAssertEqual(LoadingSwitch.style(in: defaults), style)
        }
        for earlier in ["unwinding", "frond", "not a variant"] {
            defaults.set(earlier, forKey: LoadingSwitch.key)
            XCTAssertEqual(LoadingSwitch.style(in: defaults), LoadingSwitch.fallback, earlier)
        }
        XCTAssertEqual(LoadingSwitch.key, "loading.style.v1")
        XCTAssertEqual(Set(LoadingStyle.allCases), [.off, .edge, .fixed])
        XCTAssertNil(LoadingStyle.off.launchAnchor)
        XCTAssertEqual(LoadingStyle.edge.launchAnchor, .bottomEdge)
        XCTAssertEqual(LoadingStyle.fixed.launchAnchor, .fixedPoint)
    }

    // MARK: - It draws something

    /// A smoke test: the drawing puts ink on the ground in each of its dresses, and
    /// the first frame is the ground and nothing else. It would catch a `Canvas`
    /// that drew nothing, which is the failure a geometry test cannot see.
    func testTheDrawingPutsInkOnTheGround() throws {
        func lit(_ view: some View, over ground: Color) throws -> Double {
            let renderer = ImageRenderer(content: ZStack { ground; view }.frame(width: 240, height: 180))
            renderer.scale = 1
            let image = try XCTUnwrap(renderer.uiImage?.cgImage)
            let data = try XCTUnwrap(image.dataProvider?.data)
            let bytes = CFDataGetBytePtr(data)!
            let count = image.width * image.height
            let reference = (Int(bytes[0]), Int(bytes[1]), Int(bytes[2]))
            var different = 0
            for i in 0..<count {
                let d = abs(Int(bytes[i * 4]) - reference.0) + abs(Int(bytes[i * 4 + 1]) - reference.1)
                    + abs(Int(bytes[i * 4 + 2]) - reference.2)
                if d > 90 { different += 1 }
            }
            return Double(different) / Double(count)
        }
        let dark = try lit(FiddleheadView(pose: Fiddlehead.pose(atMoment: 1), palette: .onDark), over: LaunchMoment.ground)
        let light = try lit(FiddleheadView(pose: Fiddlehead.still, palette: Fiddlehead.Palette.onLight.small, weight: 1.5, halo: 0),
                            over: Color(white: 0.965))
        let nothing = try lit(FiddleheadView(pose: Fiddlehead.pose(atMoment: 0), palette: .onDark),
                              over: LaunchMoment.ground)
        XCTAssertGreaterThan(dark, 0.002)
        XCTAssertGreaterThan(light, 0.002)
        XCTAssertEqual(nothing, 0, accuracy: 1e-9, "the first frame is the ground and nothing else")
    }

    // MARK: - The pictures

    /// Writes the frames the filmstrips and the video are made from. Skipped
    /// unless `PG_RENDER_LOADING` names a folder.
    ///
    /// The launch moment is drawn the way `LaunchMoment` draws it — the launch
    /// ground, then the fiddlehead at the pose the clock gives — over a stand-in
    /// for the stage: the app's own `StageBackdrop` and a grown plant, in both
    /// appearances, so that the hand-over is seen against what it hands over to.
    /// 30 frames a second, the 2.0 s and then the 180 ms dissolve, for variant 1
    /// (`v1-`, the bottom edge) and variant 2 (`v2-`, a fixed point). The waiting
    /// mark is one 2.4 s breath over a dimmed screen, in each appearance, and is the
    /// fixed-point drawing in both.
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
        let notes: [String] = [
            "phone \(Int(phone.width))x\(Int(phone.height)) pt at 2x, \(Int(fps)) fps",
            "moment \(LoadingTiming.moment) s = \(momentFrames) frames (0...\(momentFrames)); "
                + "dissolve \(LoadingTiming.dissolve) s = \(dissolveFrames) frames after it",
        ]

        func stage(_ scheme: ColorScheme) -> some View {
            ZStack {
                Chrome.ground
                StageBackdrop(palette: genome.palette)
                if let plant { Image(uiImage: plant).resizable().scaledToFit().padding(.horizontal, 20) }
            }
            .environment(\.colorScheme, scheme)
        }

        func write(_ image: UIImage?, _ name: String) throws {
            try XCTUnwrap(XCTUnwrap(image).pngData()).write(to: folder.appendingPathComponent("\(name).png"))
        }

        // Both launch variants, each over both stages: v1 enters from the screen's
        // bottom edge, v2 grows from a fixed point. Drawn by `LaunchMoment.mark`, the
        // same function the app draws them with.
        for (style, variant) in [(LoadingStyle.edge, "v1"), (LoadingStyle.fixed, "v2")] {
            for (scheme, mode) in [(ColorScheme.dark, "dark"), (ColorScheme.light, "light")] {
                for index in 0...(momentFrames + dissolveFrames) {
                    let moment = min(index, momentFrames)
                    let t = Double(moment) / Double(momentFrames)
                    var markOpacity = 1.0, fieldOpacity = 1.0
                    if index > momentFrames {
                        let seconds = Double(index - momentFrames) / fps
                        // easeOut for the mark and easeInOut for the ground, as
                        // `LaunchMoment.leave()` asks for; approximated by their
                        // quadratic and smoothstep cousins.
                        let leaving = min(seconds / LoadingTiming.markFade, 1)
                        markOpacity = (1 - leaving) * (1 - leaving)
                        fieldOpacity = 1 - LoadingTiming.smooth(seconds / LoadingTiming.dissolve)
                    }
                    let content = ZStack {
                        stage(scheme)
                        ZStack {
                            LaunchMoment.ground
                            LaunchMoment.mark(style, at: t, in: phone)
                                .opacity(markOpacity)
                        }
                        .opacity(fieldOpacity)
                    }
                    .frame(width: phone.width, height: phone.height)
                    .environment(\.colorScheme, scheme)
                    let renderer = ImageRenderer(content: content)
                    renderer.scale = 2
                    try write(renderer.uiImage, "\(variant)-\(mode)-\(String(format: "%03d", index))")
                }
            }
        }

        // The waiting mark: one breath, twelve frames, on the app's own ground and
        // standing in for the dimmed screen it appears over; then held still.
        let breathFrames = 12
        let markSize = LoadingBusyMark.frame(forSize: 40)
        for (scheme, mode) in [(ColorScheme.dark, "dark"), (ColorScheme.light, "light")] {
            let palette = (scheme == .dark ? Fiddlehead.Palette.onDark : Fiddlehead.Palette.onLight).small
            func panel(_ pose: Fiddlehead.Pose) -> some View {
                ZStack {
                    Chrome.ground
                    VStack(spacing: 6) {
                        QuietButton(title: "Done", isProminent: true) {}
                        QuietButton(title: "Done") {}
                    }
                    .opacity(0.4)
                    FiddleheadView(pose: pose, palette: palette, weight: 1.5, halo: 0)
                        .frame(width: markSize.width, height: markSize.height)
                }
                .frame(width: 200, height: 150)
                .environment(\.colorScheme, scheme)
            }
            for index in 0..<breathFrames {
                let renderer = ImageRenderer(content: panel(Fiddlehead.pose(atBreath: Double(index) / Double(breathFrames))))
                renderer.scale = 3
                try write(renderer.uiImage, "busy-\(mode)-\(String(format: "%02d", index))")
            }
            let still = ImageRenderer(content: panel(Fiddlehead.still))
            still.scale = 3
            try write(still.uiImage, "busy-still-\(mode)")
        }

        try notes.joined(separator: "\n").write(to: folder.appendingPathComponent("notes.txt"),
                                                atomically: true, encoding: .utf8)
    }
}
