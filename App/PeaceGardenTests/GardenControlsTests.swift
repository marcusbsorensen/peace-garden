import SeedCore
import SwiftUI
import UIKit
import XCTest
@testable import PeaceGarden

/// The garden screen's controls (Marcus, 11 October): the plus in the bottom
/// left and the two turns in the bottom right at all times, one way round in
/// every language, and the turn mark's head sitting square on its circle.
///
/// The placement is read off the real `PlotView`, hosted in a window the size
/// of an iPhone Air, through the accessibility tree — the same tree VoiceOver
/// reads, so a control found here is a control a VoiceOver user can reach.
@MainActor
final class GardenControlsTests: XCTestCase {

    // MARK: The turn mark's head

    /// The circle's radius in the tray's 20 pt mark.
    private let radius: CGFloat = 8

    /// **Both free ends the same distance from the circle**, which is what a
    /// head that sits square on a curved stroke means, and the barbs one length.
    func testTheTurnHeadStandsEquallyFarFromItsCircle() {
        let head = TurnGlyph.head(centre: .zero, radius: radius)
        let outer = hypot(head.ends[0].x, head.ends[0].y) - radius
        let inner = radius - hypot(head.ends[1].x, head.ends[1].y)
        XCTAssertGreaterThan(outer, 0, "the outer barb is outside the circle")
        XCTAssertGreaterThan(inner, 0, "the inner barb is inside it")
        XCTAssertEqual(outer, inner, accuracy: 0.01)
        // A head and not a thickening of the stroke: well over two strokes out.
        XCTAssertGreaterThan(outer, 2 * Chrome.monoline.lineWidth)

        let lengths = head.ends.map { hypot($0.x - head.tip.x, $0.y - head.tip.y) }
        XCTAssertEqual(lengths[0], lengths[1], accuracy: 0.001)
    }

    /// The tip is where the stroke ends, so the head is on the circle.
    func testTheTurnHeadIsOnTheStrokesEnd() {
        let head = TurnGlyph.head(centre: .zero, radius: radius)
        XCTAssertEqual(hypot(head.tip.x, head.tip.y), radius, accuracy: 0.001)
    }

    /// **The head keeps clear of the plot in the middle.** Turned to sit square
    /// on the stroke, the inner barb points at the diamond's corner; strokes
    /// closer than this run together at the tray's size. 0.57 pt before 11
    /// October.
    func testTheTurnHeadClearsThePlot() {
        let head = TurnGlyph.head(centre: .zero, radius: radius)
        let w = radius * TurnGlyph.plotHalfWidth, h = w * 0.58
        let corners = [CGPoint(x: 0, y: -h), CGPoint(x: w, y: 0), CGPoint(x: 0, y: h), CGPoint(x: -w, y: 0)]
        var nearest = CGFloat.infinity
        for end in head.ends {
            for i in 0..<4 {
                nearest = min(nearest, Self.gap(head.tip, end, corners[i], corners[(i + 1) % 4]))
            }
        }
        XCTAssertGreaterThan(nearest - Chrome.monoline.lineWidth, 0.55)
    }

    /// **A turn is the screen's.** Mirrored under a right-to-left layout, the
    /// anticlockwise arrow was drawn on the button that turns clockwise.
    func testTheTurnMarkDoesNotMirror() {
        XCTAssertEqual(TurnGlyph().layoutDirectionBehavior, .fixed)
        XCTAssertEqual(TurnGlyph(clockwise: false, aroundPlot: true).layoutDirectionBehavior, .fixed)
    }

    // MARK: Where the controls stand

    /// The iPhone Air's screen, in points.
    private static let screen = CGSize(width: 420, height: 912)

    /// **With the tray shut**, which is how the garden always opens: the plus
    /// in the bottom left, the turns in the bottom right, anticlockwise first,
    /// on one row, inside the safe area.
    func testThePlusAndTheTurnsStandInTheBottomCornersWithTheTrayShut() async throws {
        let found = try await controls(of: PlotView())
        try assertTheFootRow(found)
        XCTAssertNil(found[PlotControls.reset], "Reset view is in the tray, which is shut")
    }

    /// **With the tray open**, the turns stay where they were, under it, and
    /// *Reset view* is in the tray above them, and says so to VoiceOver.
    func testTheTurnsStayInTheCornerWithTheTrayOpen() async throws {
        UserDefaults.standard.set(true, forKey: "pgTray")
        defer { UserDefaults.standard.removeObject(forKey: "pgTray") }
        let found = try await controls(of: PlotView())
        try assertTheFootRow(found)
        let reset = try XCTUnwrap(found[PlotControls.reset], "Reset view is in the open tray")
        let clockwise = try XCTUnwrap(found[PlotControls.turnClockwise])
        XCTAssertLessThan(reset.maxY, clockwise.minY, "the tray stands above the row at the foot")
        // Marcus's name for it, 12 October, rather than a system symbol's.
        XCTAssertEqual(lastLabels[PlotControls.reset], "Reset view")
    }

    /// **One way round in every language**, the web garden's rule for its pad:
    /// under Arabic or Hebrew the plus is still bottom left and anticlockwise
    /// is still left of clockwise. And with the largest Dynamic Type, which
    /// the row's fixed sizes do not follow, nothing moves either.
    func testTheRowDoesNotMirrorOrMoveUnderRightToLeftAndLargeType() async throws {
        let found = try await controls(of: PlotView()
            .environment(\.layoutDirection, .rightToLeft)
            .environment(\.dynamicTypeSize, .accessibility5))
        try assertTheFootRow(found)
    }

    private func assertTheFootRow(_ found: [String: CGRect], file: StaticString = #filePath,
                                  line: UInt = #line) throws {
        let plus = try XCTUnwrap(found[PlotControls.tray], "the plus", file: file, line: line)
        let left = try XCTUnwrap(found[PlotControls.turnAnticlockwise], "the anticlockwise turn",
                                 file: file, line: line)
        let right = try XCTUnwrap(found[PlotControls.turnClockwise], "the clockwise turn",
                                  file: file, line: line)
        let screen = Self.screen
        let safeBottom = screen.height - lastSafeArea.bottom

        XCTAssertLessThan(plus.midX, screen.width / 4, "the plus is at the left", file: file, line: line)
        XCTAssertGreaterThan(left.midX, screen.width / 2, "the turns are at the right", file: file, line: line)
        XCTAssertGreaterThan(right.maxX, screen.width - 60, "against the right edge", file: file, line: line)
        XCTAssertLessThan(left.maxX, right.minX, "anticlockwise, then clockwise", file: file, line: line)

        for (name, frame) in [("plus", plus), ("anticlockwise", left), ("clockwise", right)] {
            XCTAssertGreaterThan(frame.minY, screen.height * 0.8, "\(name) is at the foot", file: file, line: line)
            XCTAssertLessThanOrEqual(frame.maxY, safeBottom + 0.5, "\(name) clears the home indicator",
                                     file: file, line: line)
            XCTAssertGreaterThanOrEqual(frame.minX, 0, file: file, line: line)
            XCTAssertLessThanOrEqual(frame.maxX, screen.width, file: file, line: line)
            XCTAssertGreaterThanOrEqual(frame.width, 40, "\(name) is big enough to press", file: file, line: line)
        }
        XCTAssertEqual(plus.midY, left.midY, accuracy: 1, "one row", file: file, line: line)
        XCTAssertEqual(left.midY, right.midY, accuracy: 1, "one row", file: file, line: line)
    }

    // MARK: Hosting it

    private var lastSafeArea = UIEdgeInsets.zero
    /// What VoiceOver says for each control, read alongside its frame.
    private var lastLabels: [String: String] = [:]

    /// **SwiftUI builds its accessibility tree only for somebody reading it.**
    /// With no VoiceOver and no UI test attached, a hosting view answers that
    /// it holds nothing at all. So the test says it is automation, the way a
    /// UI test runner does, for as long as it reads, and puts the setting back.
    private typealias AXGet = @convention(c) () -> Bool
    private typealias AXSet = @convention(c) (Bool) -> Void
    private var automationBefore: Bool?

    override func setUp() async throws {
        try await super.setUp()
        guard let library = dlopen("/usr/lib/libAccessibility.dylib", RTLD_NOW),
              let get = dlsym(library, "_AXSAutomationEnabled"),
              let set = dlsym(library, "_AXSSetAutomationEnabled") else { return }
        automationBefore = unsafeBitCast(get, to: AXGet.self)()
        unsafeBitCast(set, to: AXSet.self)(true)
    }

    override func tearDown() async throws {
        if let before = automationBefore,
           let library = dlopen("/usr/lib/libAccessibility.dylib", RTLD_NOW),
           let set = dlsym(library, "_AXSSetAutomationEnabled") {
            unsafeBitCast(set, to: AXSet.self)(before)
        }
        try await super.tearDown()
    }

    /// The garden screen in a window, and the frame of every control with an
    /// identifier, read from the accessibility tree once it has settled.
    private func controls(of view: some View) async throws -> [String: CGRect] {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(origin: .zero, size: Self.screen)
        window.windowLevel = .alert + 1
        window.rootViewController = UIHostingController(rootView: view.environment(Self.model()))
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        window.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(800))
        window.layoutIfNeeded()
        lastSafeArea = window.safeAreaInsets

        var found: [String: CGRect] = [:]
        var stack: [NSObject] = [window]
        var visited = 0
        while let node = stack.popLast(), visited < 20_000 {
            visited += 1
            // SwiftUI's nodes answer `accessibilityIdentifier` without
            // declaring `UIAccessibilityIdentification`, so it is asked for by
            // name rather than through the protocol.
            let identifier = Selector(("accessibilityIdentifier"))
            if node.responds(to: identifier),
               let id = node.perform(identifier)?.takeUnretainedValue() as? String,
               !id.isEmpty, found[id] == nil {
                found[id] = node.accessibilityFrame
                lastLabels[id] = node.accessibilityLabel
            }
            if let elements = node.accessibilityElements as? [NSObject] {
                stack.append(contentsOf: elements)
            } else {
                let count = node.accessibilityElementCount()
                if count != NSNotFound, count > 0 {
                    for index in 0..<count {
                        if let element = node.accessibilityElement(at: index) as? NSObject {
                            stack.append(element)
                        }
                    }
                }
            }
            if let view = node as? UIView { stack.append(contentsOf: view.subviews) }
        }
        return found
    }

    /// A garden with one plant in it, so the screen is the garden and not the
    /// sentence about how to start one.
    private static func model() -> GardenModel {
        let a = SeedID(bytes: seedDigest(SeedDomain.seed, Data("controls-a".utf8)))!
        let b = SeedID(bytes: seedDigest(SeedDomain.seed, Data("controls-b".utf8)))!
        let encounter = Pollination.encounterID(seedA: a, seedB: b,
                                                nonceA: Data("na".utf8), nonceB: Data("nb".utf8))
        let met = Date(timeIntervalSince1970: 1_780_000_000)
        let plant = PlantRecord(
            id: UUID(),
            seed: Pollination.cross(seedA: a, seedB: b, encounterID: encounter),
            lineage: .crossed(parentA: a, parentB: b, encounterID: encounter),
            birth: met, savedAt: met,
            encounter: EncounterNote(peerDisplayName: "Ash", happenedAt: met, place: "Here")
        )
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("controls-\(UUID().uuidString).json")
        let store = GardenStore(fileURL: file)
        try? store.save(Garden(identity: nil, plants: [plant]))
        return GardenModel(store: store)
    }

    /// The nearest two straight segments come to each other.
    private static func gap(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint, _ d: CGPoint) -> CGFloat {
        func toSegment(_ p: CGPoint, _ s: CGPoint, _ e: CGPoint) -> CGFloat {
            let dx = e.x - s.x, dy = e.y - s.y
            let t = max(0, min(1, ((p.x - s.x) * dx + (p.y - s.y) * dy) / (dx * dx + dy * dy)))
            return hypot(p.x - s.x - t * dx, p.y - s.y - t * dy)
        }
        var nearest = CGFloat.infinity
        for step in 0...200 {
            let t = CGFloat(step) / 200
            nearest = min(nearest,
                          toSegment(CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t), c, d),
                          toSegment(CGPoint(x: c.x + (d.x - c.x) * t, y: c.y + (d.y - c.y) * t), a, b))
        }
        return nearest
    }
}
