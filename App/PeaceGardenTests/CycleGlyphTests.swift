import SwiftUI
import UIKit
import XCTest
@testable import PeaceGarden

/// **The recycling turn, redrawn in the new logo's hand on 11 October 2026**:
/// three of the logo's crozier fronds round a circle, each thick where it starts
/// and thinning as it winds in. What is pinned is what the drawing cannot lose:
/// curves only, inside its box with its stroke, three alike, the taper running
/// one way to the chrome's own hairline, and room between its turns at the
/// smallest size it is drawn, 15 pt on the *Reset everything* row.
///
/// The last test writes pictures and asserts nothing, skipped unless
/// `PG_RENDER_CYCLE` names a folder (`TEST_RUNNER_PG_RENDER_CYCLE`).
@MainActor
final class CycleGlyphTests: XCTestCase {

    /// Marcus chose A on 11 October 2026; B and C are recorded in
    /// `design/recycle-glyph-2026-10-11/` with their dials.
    private let fronds: [(String, CycleGlyph.Frond)] = [("a", .chosen)]
    /// The sizes it is drawn at: the Settings row and the plant's mark row.
    private let sizes: [CGFloat] = [15, 28]

    /// No straight lines anywhere, Marcus's rule: every segment is a cubic
    /// curve, and the outlines close on their own first point, so the closing
    /// segment has no length.
    func testItIsCurvesOnly() {
        for (name, frond) in fronds {
            for size in sizes {
                let path = CycleGlyph(frond: frond).path(in: CGRect(x: 0, y: 0, width: size, height: size))
                var lines = 0, curves = 0, gap: CGFloat = 0
                var start = CGPoint.zero, current = CGPoint.zero
                path.cgPath.applyWithBlock { element in
                    let points = element.pointee.points
                    switch element.pointee.type {
                    case .moveToPoint: start = points[0]; current = points[0]
                    case .addLineToPoint: lines += 1; current = points[0]
                    case .addQuadCurveToPoint: curves += 1; current = points[1]
                    case .addCurveToPoint: curves += 1; current = points[2]
                    case .closeSubpath: gap = max(gap, hypot(current.x - start.x, current.y - start.y))
                    @unknown default: lines += 1
                    }
                }
                XCTAssertEqual(lines, 0, "\(name) at \(size)")
                XCTAssertGreaterThan(curves, 100, "\(name) at \(size)")
                XCTAssertLessThan(gap, 1e-6, "\(name) at \(size): an outline closes where it began")
            }
        }
    }

    /// Inside its frame with the stroke round it: a caller's frame is the box
    /// the glyph is given, and a round end shaved by it would read as a flat.
    func testItStaysInsideItsBoxWithItsStroke() {
        let half = Chrome.monoline.lineWidth / 2
        for (name, frond) in fronds {
            for size in sizes {
                let box = CGRect(x: 0, y: 0, width: size, height: size)
                let ink = CycleGlyph(frond: frond).path(in: box).boundingRect.insetBy(dx: -half, dy: -half)
                XCTAssertTrue(box.insetBy(dx: -0.01, dy: -0.01).contains(ink), "\(name) at \(size): \(ink)")
                // And it fills it, near enough: a glyph that drew itself small
                // would sit adrift in the row.
                XCTAssertGreaterThan(ink.width, size * 0.85, "\(name) at \(size)")
            }
        }
    }

    /// Each frond is thickest where it starts and thins steadily to its tip,
    /// where it is the chrome's hairline and no finer, so its thinnest point is
    /// the weight every other glyph is drawn in. Never thickening again is
    /// §3.2a's growth clause.
    func testEachFrondThinsFromItsStartToTheHairline() {
        for (name, frond) in fronds {
            for line in CycleGlyph.fronds(frond, in: CGRect(x: 0, y: 0, width: 28, height: 28)) {
                XCTAssertEqual(line.first!.band, frond.band, accuracy: 1e-9, name)
                XCTAssertEqual(line.last!.band, 0, accuracy: 1e-9, name)
                for index in 1..<line.count {
                    XCTAssertLessThanOrEqual(line[index].band, line[index - 1].band, "\(name) at \(index)")
                }
            }
            // Heavier than the hairline at the start, and not so heavy that the
            // stroke round its outline leaves a hollow without a centreline.
            XCTAssertGreaterThan(frond.band, 0.4, name)
            XCTAssertLessThanOrEqual(frond.band, 2 * Chrome.monoline.lineWidth, name)
        }
    }

    /// Three fronds, each the last turned a third of the way round: it is one
    /// turning and not three marks.
    func testTheThreeAreOneTurning() {
        for (name, frond) in fronds {
            let box = CGRect(x: 0, y: 0, width: 28, height: 28)
            let lines = CycleGlyph.fronds(frond, in: box)
            XCTAssertEqual(lines.count, 3)
            let angle = 2 * Double.pi / 3
            for (index, line) in lines.enumerated() {
                let next = lines[(index + 1) % 3]
                for (a, b) in zip(line, next) {
                    let x = a.point.x - box.midX, y = a.point.y - box.midY
                    let turned = CGPoint(x: box.midX + x * cos(angle) - y * sin(angle),
                                         y: box.midY + x * sin(angle) + y * cos(angle))
                    XCTAssertEqual(turned.x, b.point.x, accuracy: 1e-6, name)
                    XCTAssertEqual(turned.y, b.point.y, accuracy: 1e-6, name)
                }
            }
        }
    }

    /// **It reads at 15 pt.** The clearest gap between any two parts of the
    /// drawing that are not neighbours along one line — a coil and the turn
    /// outside it, a coil and the next frond's start — with each line at its
    /// full width (the stroke and the band). It keeps more than a device pixel
    /// on a 3× phone (1/3 pt): 0.49 pt as drawn.
    func testItReadsAtItsSmallestSize() {
        func clearance(_ frond: CycleGlyph.Frond, size: CGFloat) -> CGFloat {
            let stroke = Chrome.monoline.lineWidth
            let lines = CycleGlyph.fronds(frond, in: CGRect(x: 0, y: 0, width: size, height: size))
            var best = CGFloat.greatestFiniteMagnitude
            for (f, line) in lines.enumerated() {
                let spacing = hypot(line[1].point.x - line[0].point.x, line[1].point.y - line[0].point.y)
                for (g, other) in lines.enumerated() where g >= f {
                    for (i, a) in line.enumerated() {
                        for (j, b) in other.enumerated() {
                            let width = stroke + (a.band + b.band) / 2
                            if f == g {
                                guard j > i, CGFloat(j - i) * spacing > 2.5 * width else { continue }
                            }
                            best = min(best, hypot(a.point.x - b.point.x, a.point.y - b.point.y) - width)
                        }
                    }
                }
            }
            return best
        }
        XCTAssertGreaterThan(clearance(.chosen, size: 15), 0.45)
        for (name, frond) in fronds {
            XCTAssertGreaterThan(clearance(frond, size: 28), 1.5, "\(name) at 28")
        }
    }

    // MARK: - The pictures

    /// The chosen frond and the old glyph at the sizes they are drawn, in the
    /// inks they are drawn in, in both appearances, and enlarged; and the
    /// plant's row of marks with each, as `ChromeMark` draws it. Skipped unless
    /// `PG_RENDER_CYCLE` names a folder.
    func testWriteTheCycleGlyphs() throws {
        guard let path = ProcessInfo.processInfo.environment["PG_RENDER_CYCLE"], !path.isEmpty else {
            throw XCTSkip("PG_RENDER_CYCLE is not set")
        }
        let folder = URL(fileURLWithPath: path, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        func write(_ view: some View, _ name: String, scale: CGFloat = 3) throws {
            let renderer = ImageRenderer(content: view)
            renderer.scale = scale
            try XCTUnwrap(renderer.uiImage?.pngData()).write(to: folder.appendingPathComponent("\(name).png"))
        }

        let shapes: [(String, AnyShape)] = fronds.map { ($0.0, AnyShape(CycleGlyph(frond: $0.1))) }
            + [("old", AnyShape(OldCycleGlyph()))]
        for (name, shape) in shapes {
            for (scheme, mode) in [(ColorScheme.dark, "dark"), (ColorScheme.light, "light")] {
                // The Settings row's ink, crimson, and the plant row's, muted.
                for (tint, ink) in [(Chrome.crimson, "crimson"), (Chrome.muted, "muted")] {
                    for size in sizes {
                        try write(shape.stroke(tint, style: Chrome.monoline)
                                    .frame(width: size, height: size)
                                    .padding(2)
                                    .background(Chrome.ground)
                                    .environment(\.colorScheme, scheme),
                                  "glyph-\(name)-\(Int(size))-\(ink)-\(mode)")
                    }
                }
                // Enlarged: the 28-point drawing at twelve times.
                try write(shape.stroke(Chrome.muted, style: Chrome.monoline)
                            .frame(width: 28, height: 28)
                            .padding(2)
                            .background(Chrome.ground)
                            .environment(\.colorScheme, scheme),
                          "glyph-\(name)-enlarged-\(mode)", scale: 12)

                // The plant's row, the turn's word unrolled, as when it has
                // just been touched.
                var expanded: String? = "back"
                let binding = Binding(get: { expanded }, set: { expanded = $0 })
                let row = HStack(spacing: 10) {
                    ChromeMark(glyph: AnyShape(PencilShape()), name: "meeting", title: "The meeting",
                               expanded: binding) {}
                    ChromeMark(glyph: shape, name: "back", title: "Take it back", expanded: binding) {}
                    ChromeMark(glyph: AnyShape(MeetGlyph()), name: "wild", title: "The Wild Fields",
                               expanded: binding) {}
                }
                .padding(16)
                .background(Chrome.ground)
                .environment(\.colorScheme, scheme)
                try write(row, "row-\(name)-\(mode)")
            }
        }
    }
}

/// **The glyph as it was until 11 October 2026**, kept here and nowhere else,
/// for the before-and-after picture: three logarithmic spirals opening outward
/// from the centre, drawn as 26 short segments each.
private struct OldCycleGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2 - 0.7
        let inner = outer * 0.34
        let sweep = Double.pi * 140 / 180
        let steps = 26
        var path = Path()
        for frond in 0..<3 {
            let start = Double(frond) * 2 * .pi / 3 - .pi / 2
            for step in 0...steps {
                let along = Double(step) / Double(steps)
                let radius = inner * pow(outer / inner, along)
                let angle = start + sweep * along
                let point = CGPoint(x: centre.x + radius * cos(angle), y: centre.y + radius * sin(angle))
                if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
        }
        return path
    }
}
