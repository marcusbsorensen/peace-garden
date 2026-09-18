import SeedCore
import UIKit
import XCTest
@testable import PeaceGarden

/// The glow-in-the-dark figures.
///
/// What they look like is looked at, not asserted. What is here is the fault the
/// plants already had once: a figure cut off by the edge of its own frame looks
/// like a figure of a slightly different shape, not like a fault.
@MainActor
final class CreatureTests: XCTestCase {

    private let figures: [LampKind] = LampKind.allCases.filter(GardenCreatures.isCreature)

    /// **No figure touches the edge of its picture, facing any way.** The frame
    /// reaches below the foot for what lies nearer the camera than it, and a
    /// fox with its foot on the bottom edge lost its nose; turned the other
    /// way, the hare's ears are what would go. Every facing, at every turn of
    /// the plot, since a turn is only another facing.
    func testNoFigureIsCutOffByItsFrame() throws {
        XCTAssertEqual(Set(figures), [.hare, .fox, .moth, .snail])

        for kind in figures {
            for facing in 0..<8 {
                let image = try XCTUnwrap(
                    GardenCreatures.shared.picture(kind, step: 4, turn: 0, facing: facing),
                    "\(kind) facing \(facing) did not render"
                )
                let edges = Self.edgesTouched(by: image)
                XCTAssertTrue(edges.isEmpty,
                              "\(kind) facing \(facing) is cut off at the \(edges.joined(separator: ", "))")
            }
        }
    }

    /// And the glow picture is the same figure: something in it, and in the same
    /// place, or the paint would glow beside the animal.
    func testTheGlowLiesOverTheFigure() throws {
        for kind in figures {
            let lit = try XCTUnwrap(GardenCreatures.shared.picture(kind, step: 4, turn: 0, facing: 3))
            let glow = try XCTUnwrap(GardenCreatures.shared.picture(kind, step: nil, turn: 0, facing: 3))
            let a = try XCTUnwrap(Self.bounds(of: lit), "\(kind) rendered empty")
            let b = try XCTUnwrap(Self.bounds(of: glow), "\(kind)'s glow rendered empty")
            XCTAssertEqual(a.midX, b.midX, accuracy: 0.03, "\(kind)")
            XCTAssertEqual(a.midY, b.midY, accuracy: 0.03, "\(kind)")
        }
    }

    /// A figure keeps facing the way it faced, and two lights put out one after
    /// the other do not all face the same way.
    func testFacingComesFromTheLightAndSpreads() {
        XCTAssertEqual(GardenCreatures.facing(seed: 1234), GardenCreatures.facing(seed: 1234))
        let facings = Set((0..<64).map { GardenCreatures.facing(seed: $0 * 37 + 11) })
        XCTAssertEqual(facings.count, 8)
        XCTAssertTrue(facings.allSatisfy { (0..<8).contains($0) })
    }

    // MARK: Reading pictures

    private static func pixels(of image: UIImage) -> (bytes: [UInt8], width: Int, height: Int)? {
        guard let cg = image.cgImage else { return nil }
        let width = cg.width, height = cg.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(
            data: &bytes, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
        return (bytes, width, height)
    }

    /// Which edges of the picture anything opaque reaches, within a pixel.
    private static func edgesTouched(by image: UIImage) -> [String] {
        guard let (bytes, width, height) = pixels(of: image) else { return ["whole picture (unreadable)"] }
        func opaque(_ x: Int, _ y: Int) -> Bool { bytes[(y * width + x) * 4 + 3] > 8 }

        var edges: [String] = []
        if (0..<width).contains(where: { opaque($0, 0) || opaque($0, 1) }) { edges.append("top") }
        if (0..<width).contains(where: { opaque($0, height - 1) || opaque($0, height - 2) }) { edges.append("bottom") }
        if (0..<height).contains(where: { opaque(0, $0) || opaque(1, $0) }) { edges.append("left") }
        if (0..<height).contains(where: { opaque(width - 1, $0) || opaque(width - 2, $0) }) { edges.append("right") }
        return edges
    }

    /// The box round everything opaque, as fractions of the picture.
    private static func bounds(of image: UIImage) -> CGRect? {
        guard let (bytes, width, height) = pixels(of: image) else { return nil }
        var minX = width, minY = height, maxX = -1, maxY = -1
        for y in 0..<height {
            for x in 0..<width where bytes[(y * width + x) * 4 + 3] > 24 {
                minX = min(minX, x); maxX = max(maxX, x)
                minY = min(minY, y); maxY = max(maxY, y)
            }
        }
        guard maxX >= minX else { return nil }
        return CGRect(x: Double(minX) / Double(width), y: Double(minY) / Double(height),
                      width: Double(maxX - minX) / Double(width),
                      height: Double(maxY - minY) / Double(height))
    }
}
