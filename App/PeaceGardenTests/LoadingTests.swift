import SeedCore
import SwiftUI
import UIKit
import XCTest
@testable import PeaceGarden

/// **The loading animation: what it is made of, how long it runs, that it can be
/// read on the ground it is drawn on, and that it stays quiet when asked.**
///
/// Marcus chose the fiddlehead on 10 October 2026, growing up from a fixed point as
/// it unfurls, over 2.0 s, on the suite's dark ground in both appearances. On 11
/// October it took the chosen logo's colours (D-suite) and its leaf was made to
/// finish lifted, up and a little outward. What is pinned here is what those
/// choices cannot lose.
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
    /// same place in the drawing's own frame.
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

    /// **A fixed point in space with nothing beneath it** — Marcus's choice of 10
    /// October 2026. The root does not move on the canvas, nothing at any pose leaves
    /// the frame it is given, and the root is the lowest thing there is.
    func testTheRootIsAFixedPointWithNothingBelowIt() {
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

    /// The same of the launch moment, which is fitted to its own travel because
    /// the lifted plant stands taller than anything the waiting mark does: every
    /// pose it passes through stays in the frame, the root does not move and is
    /// the lowest thing there is, and the plant it ends on — what the hand-over
    /// finds — is centred across the frame.
    func testTheMomentStaysInItsFrameAndEndsCentred() {
        let frame = LaunchMoment.markFrame(short: 390)
        let placement = Fiddlehead.Placement.fixedPoint(in: frame, fit: .moment)
        let root = placement.place(Fiddlehead.rootPoint)
        var lowest = -Double.infinity
        for step in 0...200 {
            let pose = Fiddlehead.pose(atMoment: Double(step) / 200)
            let figure = Fiddlehead.figure(open: pose.open, rise: pose.rise, lift: pose.lift)
            XCTAssertEqual(placement.place(figure.stem[0]).x, root.x, accuracy: 1e-9)
            XCTAssertEqual(placement.place(figure.stem[0]).y, root.y, accuracy: 1e-9)
            for p in (figure.stem + figure.bract).map(placement.place) {
                XCTAssertGreaterThanOrEqual(p.x, 0, "step \(step)")
                XCTAssertLessThanOrEqual(p.x, frame.width, "step \(step)")
                XCTAssertGreaterThanOrEqual(p.y, 0, "step \(step)")
                XCTAssertLessThanOrEqual(p.y, frame.height, "step \(step)")
                lowest = max(lowest, Double(p.y))
            }
        }
        XCTAssertEqual(lowest, Double(root.y), accuracy: 1e-6)
        let end = Fiddlehead.composedBounds
        XCTAssertEqual(placement.place(CGPoint(x: end.midX, y: end.midY)).x, frame.width / 2, accuracy: 1e-9)
        // The waiting mark keeps its own fit, so it is no smaller for a pose it
        // never takes.
        XCTAssertEqual(Fiddlehead.Fit.waiting.travel, Fiddlehead.travel)
        XCTAssertGreaterThan(Fiddlehead.momentTravel.height, Fiddlehead.travel.height)
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
        XCTAssertEqual(first.lift, 0)
        let last = Fiddlehead.pose(atMoment: 1)
        XCTAssertEqual(last.rise, 1, accuracy: 1e-12)
        XCTAssertEqual(last.open, Fiddlehead.composed, accuracy: 1e-12)
        XCTAssertEqual(last.lift, 1, accuracy: 1e-12, "it ends lifted")
        XCTAssertEqual(last.appear, 1)
        XCTAssertEqual(Fiddlehead.pose(atMoment: 2), last, "clamped, not extrapolated")
        XCTAssertLessThan(Fiddlehead.composed, 1)

        var previousRise = -1.0, previousOpen = -1.0, previousLift = -1.0
        for step in 0...40 {
            let pose = Fiddlehead.pose(atMoment: Double(step) / 40)
            XCTAssertGreaterThanOrEqual(pose.rise, previousRise)
            XCTAssertGreaterThanOrEqual(pose.open, previousOpen)
            XCTAssertGreaterThanOrEqual(pose.lift, previousLift)
            previousRise = pose.rise
            previousOpen = pose.open
            previousLift = pose.lift
        }
    }

    // MARK: - The leaf ends lifted

    /// The leaf's axis, mouth to the far end of the outline, as degrees from
    /// straight up: positive to the right, negative to the left.
    private func leafAxis(_ figure: Fiddlehead.Figure) -> (degrees: Double, mouth: CGPoint, tip: CGPoint) {
        let mouth = figure.stem.last!
        let tip = figure.bract.max { hypot($0.x - mouth.x, $0.y - mouth.y) < hypot($1.x - mouth.x, $1.y - mouth.y) }!
        return (atan2(tip.x - mouth.x, mouth.y - tip.y) * 180 / .pi, mouth, tip)
    }

    /// **The leaf finishes lifted, up and a little outward** — Marcus, 11 October
    /// 2026, with the logo's D-suite, whose tall frond carries its leaf so (its
    /// leaf points 35° off upright). On 10 October it ended hanging from the
    /// hook, which is the downward-facing flower that round one's logo was
    /// turned down for, because it looks sad.
    func testTheLeafEndsLiftedUpAndOutward() {
        let end = Fiddlehead.pose(atMoment: 1)
        let lifted = leafAxis(Fiddlehead.figure(open: end.open, rise: end.rise, lift: end.lift))
        let length = hypot(lifted.tip.x - lifted.mouth.x, lifted.tip.y - lifted.mouth.y)
        // Up: the far end is well above the mouth.
        XCTAssertGreaterThan(lifted.mouth.y - lifted.tip.y, length * 0.7)
        // And a little outward, the way the curl turned (`hand`), not sideways.
        let outward = lifted.degrees * Fiddlehead.plan.hand
        XCTAssertGreaterThan(outward, 15)
        XCTAssertLessThan(outward, 45)
        // The 10 October ending, for the record: the same plant without the lift
        // hangs its leaf below the stem's tip.
        let hanging = leafAxis(Fiddlehead.figure(open: Fiddlehead.composed, rise: 1, lift: 0))
        XCTAssertGreaterThan(hanging.tip.y, hanging.mouth.y, "on 10 October the leaf hung down")
    }

    /// **Calm: the lift settles, it does not bounce.** The leaf turns one way only
    /// from the moment the lift begins to the end — no overshoot to come back
    /// from — and the last frames are still.
    func testTheLeafSettlesWithoutABounce() {
        var angles: [Double] = []
        let start = Fiddlehead.liftBeat.lowerBound
        for step in 0...600 {
            let t = start + (1 - start) * Double(step) / 600
            let pose = Fiddlehead.pose(atMoment: t)
            var angle = leafAxis(Fiddlehead.figure(open: pose.open, rise: pose.rise, lift: pose.lift)).degrees
            if let previous = angles.last {
                while angle - previous > 180 { angle -= 360 }
                while angle - previous < -180 { angle += 360 }
            }
            angles.append(angle)
        }
        let direction = (angles.last! - angles.first!).sign
        for index in 1..<angles.count {
            let turned = angles[index] - angles[index - 1]
            XCTAssertTrue(turned == 0 || turned.sign == direction, "it turned back at step \(index)")
        }
        XCTAssertEqual(Fiddlehead.pose(atMoment: 0.99), Fiddlehead.pose(atMoment: 1), "the last frames are still")
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
    ///
    /// **A standing stem is the hard case**, so since 11 October it is asked of
    /// the lifted stem, of the way there, and of every pose the moment passes
    /// through (`Fiddlehead.Lift` says why the lifted sway is 0.4).
    func testTheStemHasNoStraightRun() {
        func gentlestFifth(_ points: [CGPoint]) -> Double {
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
            return smallest * 180 / .pi
        }
        for rise in [0.0, 0.5, 1.0] {
            for open in [0.0, 0.5, 1.0] {
                for lift in [0.0, 0.5, 1.0] {
                    let points = Fiddlehead.figure(open: open, rise: rise, lift: lift).stem
                    XCTAssertGreaterThan(gentlestFifth(points), 2, "stem at open \(open), rise \(rise), lift \(lift)")
                }
            }
        }
        for step in 0...40 {
            let pose = Fiddlehead.pose(atMoment: Double(step) / 40)
            let points = Fiddlehead.figure(open: pose.open, rise: pose.rise, lift: pose.lift).stem
            XCTAssertGreaterThan(gentlestFifth(points), 2, "stem at moment \(step)/40")
        }
        let still = Fiddlehead.still
        XCTAssertGreaterThan(gentlestFifth(Fiddlehead.figure(open: still.open, rise: still.rise, lift: still.lift).stem), 2,
                             "the Reduce Motion still")
    }

    /// **There is no ground.** Marcus took the soil out on 10 October 2026: every
    /// plant in the app is attached to a 3D ground, floating, or 2D with no soil, and
    /// a drawn line matched none. Asked of the pixels rather than of the code: nothing
    /// is lit below the root.
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

        // The lowest lit row is the root's, give or take the half stroke and the halo.
        let frame = CGSize(width: 200, height: 300)
        let drawn = try lit(ZStack {
            LaunchMoment.ground
            FiddleheadView(pose: Fiddlehead.pose(atMoment: 1), palette: .onDark, weight: 1.8, halo: 10, fit: .moment)
        }, width: 200, height: 300)
        let root = Fiddlehead.Placement.fixedPoint(in: frame, fit: .moment).place(Fiddlehead.rootPoint)
        let lowest = drawn.lastIndex { $0.contains(true) }!
        XCTAssertLessThanOrEqual(Double(lowest), Double(root.y) + 7, "nothing below the root")
        // And the stem is there at all, so the row above is not an empty picture.
        XCTAssertGreaterThan(drawn.filter { $0.contains(true) }.count, 100)
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

    /// The chosen logo's stops (D-suite, 11 October 2026) on the suite's ground
    /// are isoluminant at 9.7:1 (`design/logo-2026-10-11/README.md` §3); this
    /// holds the palette to them, and the warm white leaf to its 17.3:1. Until
    /// 11 October these were the old icon's neon greens at 13:1.
    func testTheLaunchMomentIsLegibleOnTheLaunchGround() {
        let ground = Fiddlehead.Palette.launchGround
        let stops = Fiddlehead.Palette.onDark.stem
        XCTAssertEqual(stops, [RGB(hex: 0x9CC29E), RGB(hex: 0x9DC386), RGB(hex: 0xA9C263)], "the logo's own")
        for (index, stop) in stops.enumerated() {
            XCTAssertEqual(stop.contrast(with: ground), 9.7, accuracy: 0.1, "stop \(index)")
        }
        XCTAssertEqual(Fiddlehead.Palette.onDark.leaf, RGB(hex: 0xF4F3EF))
        XCTAssertGreaterThan(Fiddlehead.Palette.onDark.leaf.contrast(with: ground), 17)
        // A breath of colour under the hairline, lowered for a pale sage.
        XCTAssertGreaterThan(Fiddlehead.Palette.onDark.halo, 0)
        XCTAssertLessThan(Fiddlehead.Palette.onDark.halo, 0.07)
    }

    /// The waiting mark follows the app's appearance. On the light ground the
    /// dark-ground stops would not be seen, so it takes the logo's light-ground
    /// stops, 4.6:1, and the leaf is the app's ink.
    func testTheWaitingMarkIsLegibleOnTheLightGround() {
        let ground = Fiddlehead.Palette.lightGround
        let launch = Fiddlehead.Palette.onDark.stem
        XCTAssertLessThan(launch.last!.contrast(with: ground), 2, "the green-gold is a mark nobody can see here")
        XCTAssertEqual(Fiddlehead.Palette.onLight.stem, [RGB(hex: 0x397E3D), RGB(hex: 0x467D25), RGB(hex: 0x60781E)])
        for (index, stop) in Fiddlehead.Palette.onLight.stem.enumerated() {
            XCTAssertEqual(stop.contrast(with: ground), 4.6, accuracy: 0.05, "stop \(index)")
        }
        XCTAssertGreaterThan(Fiddlehead.Palette.onLight.leaf.contrast(with: ground), 12)
        // The same three hues, in the same order: sage, then moss, then
        // green-gold, which is to say the red channel rises along the stem.
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
        XCTAssertTrue(LaunchMomentHost.plays(style: .fixed, reduceMotion: false, alreadyPlayed: false))
        XCTAssertFalse(LaunchMomentHost.plays(style: .fixed, reduceMotion: true, alreadyPlayed: false))
        XCTAssertFalse(LaunchMomentHost.plays(style: .fixed, reduceMotion: false, alreadyPlayed: true),
                       "a second window is not a launch")
        XCTAssertFalse(LaunchMomentHost.plays(style: .off, reduceMotion: false, alreadyPlayed: false))
    }

    /// Still, not blank: **a small standing sprout with its leaf lifted** — Marcus,
    /// 11 October 2026, in place of the half-open tendril whose leaf hung from the
    /// hook. Up and a little outward as the moment's end is, smaller than it, and
    /// inside the waiting mark's own frame with nothing below its root.
    func testTheStillIsASmallSproutWithItsLeafLifted() {
        let still = Fiddlehead.still
        XCTAssertEqual(still.lift, 1, "lifted")
        XCTAssertGreaterThan(still.open, 0.5, "the leaf open")
        XCTAssertLessThan(still.open, 1)
        XCTAssertGreaterThan(still.rise, 0.3, "standing, not a bud")
        XCTAssertLessThan(still.rise, Fiddlehead.pose(atMoment: 1).rise, "smaller than the plant the moment ends on")

        let figure = Fiddlehead.figure(open: still.open, rise: still.rise, lift: still.lift)
        let leaf = leafAxis(figure)
        let length = hypot(leaf.tip.x - leaf.mouth.x, leaf.tip.y - leaf.mouth.y)
        XCTAssertGreaterThan(leaf.mouth.y - leaf.tip.y, length * 0.7, "the leaf points up")
        XCTAssertGreaterThan(leaf.degrees * Fiddlehead.plan.hand, 15, "and a little outward")
        XCTAssertLessThan(leaf.degrees * Fiddlehead.plan.hand, 45)

        let frame = LoadingBusyMark.frame(forSize: 40)
        let placement = Fiddlehead.Placement.fixedPoint(in: frame)
        let root = placement.place(Fiddlehead.rootPoint)
        for p in (figure.stem + figure.bract).map(placement.place) {
            XCTAssertGreaterThanOrEqual(p.x, 0)
            XCTAssertLessThanOrEqual(p.x, frame.width)
            XCTAssertGreaterThanOrEqual(p.y, 0)
            XCTAssertLessThanOrEqual(p.y, root.y + 1e-9, "nothing below the root")
        }
    }

    /// The fixed point is the default, a launch argument can name it or `off`, and a
    /// value from an earlier round — `unwinding`, `frond`, or `edge`, the variant that
    /// entered from the screen's bottom edge and was removed — reads as the default
    /// rather than as nothing.
    func testTheSwitchIsFixedOrOffAndEarlierValuesReadAsTheDefault() throws {
        let suite = "loading-tests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        XCTAssertEqual(LoadingSwitch.style(in: defaults), .fixed)
        XCTAssertEqual(LoadingSwitch.fallback, .fixed, "Marcus, 10 October 2026: the fixed point")
        for style in LoadingStyle.allCases {
            defaults.set(style.rawValue, forKey: LoadingSwitch.key)
            XCTAssertEqual(LoadingSwitch.style(in: defaults), style)
        }
        for earlier in ["unwinding", "frond", "edge", "not a variant"] {
            defaults.set(earlier, forKey: LoadingSwitch.key)
            XCTAssertEqual(LoadingSwitch.style(in: defaults), .fixed, earlier)
        }
        XCTAssertEqual(LoadingSwitch.key, "loading.style.v1")
        XCTAssertEqual(Set(LoadingStyle.allCases), [.off, .fixed])
    }

    /// The two choices left open on 11 October are launch arguments of the same
    /// kind, each defaulting to the recommendation, and a value that names
    /// nothing reads as the recommendation too.
    func testTheTwoOpenChoicesDefaultToTheRecommendation() throws {
        let suite = "loading-tests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        XCTAssertEqual(LoadingSwitch.drawing(in: defaults), Fiddlehead.Style.standard)
        XCTAssertEqual(Fiddlehead.Style.standard, .init(stem: LoadingSwitch.stemFallback, leaf: LoadingSwitch.leafFallback))
        for stem in LoadingStem.allCases {
            defaults.set(stem.rawValue, forKey: LoadingSwitch.stemKey)
            XCTAssertEqual(LoadingSwitch.stem(in: defaults), stem)
        }
        for leaf in LoadingLeaf.allCases {
            defaults.set(leaf.rawValue, forKey: LoadingSwitch.leafKey)
            XCTAssertEqual(LoadingSwitch.leaf(in: defaults), leaf)
        }
        defaults.set("not a choice", forKey: LoadingSwitch.stemKey)
        defaults.set("not a choice", forKey: LoadingSwitch.leafKey)
        XCTAssertEqual(LoadingSwitch.drawing(in: defaults), Fiddlehead.Style.standard)
        XCTAssertEqual(LoadingSwitch.stemKey, "loading.stem.v1")
        XCTAssertEqual(LoadingSwitch.leafKey, "loading.leaf.v1")
        // An even stem is 10 October's hairline; the taper is gentle.
        XCTAssertEqual(Fiddlehead.Style(stem: .even, leaf: .outline).tipShare, 1)
        XCTAssertEqual(Fiddlehead.Style(stem: .tapered, leaf: .outline).tipShare, Fiddlehead.Style.taperedTip)
        XCTAssertGreaterThanOrEqual(Fiddlehead.Style.taperedTip, 0.5)
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
        let dark = try lit(FiddleheadView(pose: Fiddlehead.pose(atMoment: 1), palette: .onDark, fit: .moment),
                           over: LaunchMoment.ground)
        func dressed(_ stem: LoadingStem, _ leaf: LoadingLeaf) throws -> Double {
            try lit(FiddleheadView(pose: Fiddlehead.pose(atMoment: 1), palette: .onDark,
                                   style: .init(stem: stem, leaf: leaf), fit: .moment),
                    over: LaunchMoment.ground)
        }
        let tapered = try dressed(.tapered, .outline)
        let outlined = try dressed(.even, .outline)
        let filled = try dressed(.even, .filled)
        let light = try lit(FiddleheadView(pose: Fiddlehead.still, palette: Fiddlehead.Palette.onLight.small, weight: 1.5, halo: 0),
                            over: Color(white: 0.965))
        let nothing = try lit(FiddleheadView(pose: Fiddlehead.pose(atMoment: 0), palette: .onDark),
                              over: LaunchMoment.ground)
        XCTAssertGreaterThan(dark, 0.002)
        XCTAssertGreaterThan(light, 0.002)
        // Both dials draw: the tapered stem is a filled outline and not nothing,
        // it is lighter than the even one, and a filled leaf puts more ink down
        // than an outlined one.
        XCTAssertGreaterThan(tapered, 0.002)
        XCTAssertLessThan(tapered, outlined)
        XCTAssertGreaterThan(filled, outlined)
        XCTAssertEqual(nothing, 0, accuracy: 1e-9, "the first frame is the ground and nothing else")
    }

    // MARK: - The pictures

    /// Writes the frames the filmstrips and the video are made from. Skipped
    /// unless `PG_RENDER_LOADING` names a folder.
    ///
    /// The launch moment is drawn the way `LaunchMoment` draws it — the launch
    /// ground, then the fiddlehead at the pose the clock gives, and since 11
    /// October 2026 the name and version at the foot — over a stand-in
    /// for the stage: the app's own `StageBackdrop` and a grown plant, in both
    /// appearances, so that the hand-over is seen against what it hands over to.
    /// 30 frames a second, the 2.0 s and then the 180 ms dissolve (`launch-`). The
    /// waiting mark is one 2.4 s breath over a dimmed screen, in each appearance
    /// (`busy-`), and is the same fixed-point drawing.
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

        // The launch moment over both stages, drawn by `LaunchMoment.mark`, the same
        // function the app draws it with.
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
                // The name and version, since 11 October 2026: in over the first
                // 180 ms as `LaunchMoment` fades them in, out with the mark, over a
                // 34-point home indicator as a Face ID phone has.
                let arrived = LoadingTiming.smooth(Double(index) / fps / LoadingTiming.busyFade)
                let content = ZStack {
                    stage(scheme)
                    ZStack {
                        LaunchMoment.ground
                        LaunchMoment.mark(at: t, in: phone, style: .standard)
                            .opacity(markOpacity)
                        LaunchNameplateFoot()
                            .padding(.bottom, 34)
                            .opacity(markOpacity * arrived)
                    }
                    .opacity(fieldOpacity)
                }
                .frame(width: phone.width, height: phone.height)
                .environment(\.colorScheme, scheme)
                let renderer = ImageRenderer(content: content)
                renderer.scale = 2
                try write(renderer.uiImage, "launch-\(mode)-\(String(format: "%03d", index))")
            }
        }

        // The waiting mark: one breath, twelve frames, on the app's own ground and
        // standing in for the dimmed screen it appears over; then held still.
        let breathFrames = 12
        let markSize = LoadingBusyMark.frame(forSize: 40)
        for (scheme, mode) in [(ColorScheme.dark, "dark"), (ColorScheme.light, "light")] {
            let palette = (scheme == .dark ? Fiddlehead.Palette.onDark : Fiddlehead.Palette.onLight).small
            func panel(_ pose: Fiddlehead.Pose, style: Fiddlehead.Style = .standard) -> some View {
                ZStack {
                    Chrome.ground
                    VStack(spacing: 6) {
                        QuietButton(title: "Done", isProminent: true) {}
                        QuietButton(title: "Done") {}
                    }
                    .opacity(0.4)
                    FiddleheadView(pose: pose, palette: palette, weight: 1.5, halo: 0, style: style)
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

            // The two open choices on the waiting mark, at 3×, a phone's own
            // pixels: three points of the breath and the still, in each dress.
            for (style, name) in Self.dresses {
                for (index, phase) in [0.0, 0.25, 0.5].enumerated() {
                    let renderer = ImageRenderer(content: panel(Fiddlehead.pose(atBreath: phase), style: style))
                    renderer.scale = 3
                    try write(renderer.uiImage, "choice-busy-\(name)-\(mode)-\(index)")
                }
                let held = ImageRenderer(content: panel(Fiddlehead.still, style: style))
                held.scale = 3
                try write(held.uiImage, "choice-busy-\(name)-\(mode)-still")
            }
        }

        // The launch moment alone on its ground, in the mark's own frame at 3×:
        // the plant it ends on in each dress and at three halos, and five points
        // of the moment in each dress, for the choices.
        let markFrame = LaunchMoment.markFrame(short: phone.width)
        func alone(_ t: Double, style: Fiddlehead.Style, halo: Double? = nil) -> some View {
            var palette = Fiddlehead.Palette.onDark
            if let halo { palette.halo = halo }
            return ZStack {
                LaunchMoment.ground
                FiddleheadView(pose: Fiddlehead.pose(atMoment: t), palette: palette, weight: 1.8, halo: 10,
                               style: style, fit: .moment)
            }
            .frame(width: markFrame.width, height: markFrame.height)
        }
        for (style, name) in Self.dresses {
            let end = ImageRenderer(content: alone(1, style: style))
            end.scale = 3
            try write(end.uiImage, "final-\(name)")
            for (index, t) in [0.25, 0.45, 0.6, 0.75, 1.0].enumerated() {
                let renderer = ImageRenderer(content: alone(t, style: style))
                renderer.scale = 2
                try write(renderer.uiImage, "choice-moment-\(name)-\(index)")
            }
        }
        for halo in [0.07, 0.04, 0.0] {
            let renderer = ImageRenderer(content: alone(1, style: .standard, halo: halo))
            renderer.scale = 3
            try write(renderer.uiImage, "final-halo-\(String(format: "%03d", Int((halo * 100).rounded())))")
        }

        // A question for Marcus, not a change: the lifted plant stands taller than
        // the 10 October arch, so in the same frame everything before the end is
        // drawn smaller. The same whole screens with the frame 1.8 times as tall
        // as it is wide instead of 1.5, at the frames the before-and-after uses.
        let taller = CGSize(width: markFrame.width, height: markFrame.width * 1.8)
        for index in [9, 21, 30, 39, 45, 51, 60] {
            let content = ZStack {
                LaunchMoment.ground
                FiddleheadView(pose: Fiddlehead.pose(atMoment: Double(index) / Double(momentFrames)),
                               palette: .onDark, weight: 1.8, halo: 10, style: .standard, fit: .moment)
                    .frame(width: taller.width, height: taller.height)
            }
            .frame(width: phone.width, height: phone.height)
            let renderer = ImageRenderer(content: content)
            renderer.scale = 2
            try write(renderer.uiImage, "taller-dark-\(String(format: "%03d", index))")
        }

        try notes.joined(separator: "\n").write(to: folder.appendingPathComponent("notes.txt"),
                                                atomically: true, encoding: .utf8)
    }

    /// The four dresses the two open choices make, named as the pictures are.
    private static let dresses: [(Fiddlehead.Style, String)] = [
        (.init(stem: .even, leaf: .outline), "even-outline"),
        (.init(stem: .tapered, leaf: .outline), "tapered-outline"),
        (.init(stem: .even, leaf: .filled), "even-filled"),
        (.init(stem: .tapered, leaf: .filled), "tapered-filled"),
    ]
}
