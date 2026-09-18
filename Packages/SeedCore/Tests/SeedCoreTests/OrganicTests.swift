import XCTest
@testable import SeedCore

/// The garden's irregular edges: that they are irregular, that they stay where
/// the things drawn to them expect, and that every host draws the same one.
final class OrganicTests: XCTestCase {

    /// The outline wanders, but only inward: nothing drawn to the full square
    /// shows past it, and a plant clamped inside the square can be tested
    /// against it.
    func testTheOutlineWandersInsideItsRectangle() {
        let side = 5.2
        let outline = Organic.outline(width: side, length: side, seed: 7)
        var nearest = Double.infinity, furthest = 0.0
        for p in outline {
            XCTAssertLessThanOrEqual(abs(p.x), side / 2 + 1e-9)
            XCTAssertLessThanOrEqual(abs(p.z), side / 2 + 1e-9)
            let edge = max(abs(p.x), abs(p.z))
            nearest = min(nearest, edge)
            furthest = max(furthest, edge)
        }
        // Not a ruled line: along the straight stretches the edge moves in and out.
        let straights = outline.filter { abs($0.z) < 1.5 && $0.x > 0 }.map(\.x)
        XCTAssertGreaterThan(straights.max()! - straights.min()!, 0.04, "the x+ side is nearly straight")
        XCTAssertGreaterThan(furthest, side / 2 - 0.03)
    }

    /// The loop meets itself without a step.
    func testTheOutlineHasNoSeam() {
        let outline = Organic.outline(width: 5.2, length: 5.2, seed: 11)
        var worst = 0.0
        for i in 0..<outline.count {
            let a = outline[i], b = outline[(i + 1) % outline.count]
            worst = max(worst, ((a.x - b.x) * (a.x - b.x) + (a.z - b.z) * (a.z - b.z)).squareRoot())
        }
        XCTAssertLessThan(worst, 0.15, "a step of \(worst) m in the outline")
    }

    func testContainsFindsTheMiddleAndNotTheCorner() {
        let outline = Organic.outline(width: 5.2, length: 5.2, seed: 3)
        XCTAssertTrue(Organic.contains(outline, x: 0, z: 0))
        XCTAssertTrue(Organic.contains(outline, x: 2.3, z: 0))
        XCTAssertFalse(Organic.contains(outline, x: 2.59, z: 2.59), "a worn corner is not ground")
        XCTAssertFalse(Organic.contains(outline, x: 3, z: 0))
    }

    /// A hedge stays within its length, stands on the ground, and is no box:
    /// its top is not level.
    func testAHedgeIsAHedgeNotABox() {
        let mesh = Organic.hedge(length: 5.2, height: 2.0, thickness: 0.36, seed: 5)
        XCTAssertFalse(mesh.indices.isEmpty)
        XCTAssertEqual(mesh.normals.count, mesh.positions.count)
        let ys = mesh.positions.map(\.y), zs = mesh.positions.map(\.z)
        XCTAssertGreaterThanOrEqual(ys.min()!, 0)
        XCTAssertLessThanOrEqual(zs.map(abs).max()!, 2.6 + 1e-5)
        // The top line: the highest point of each ring along the middle stretch.
        var tops: [Float] = []
        let stride = 21
        for ring in stride_(from: 10, to: mesh.positions.count / stride - 10) {
            tops.append(mesh.positions[ring * stride ..< ring * stride + stride].map(\.y).max()!)
        }
        XCTAssertGreaterThan(tops.max()! - tops.min()!, 0.05, "the hedge's top is level")
        // Its faces point outward: the top of the middle ring faces the sky.
        let middle = (mesh.positions.count / stride / 2) * stride + stride / 2
        XCTAssertGreaterThan(mesh.normals[middle].y, 0.5, "the hedge's normals point inward")
        // Its ends fall away: a quarter of the way into the end's shoulder, the
        // top is already well below the hedge's height.
        let nearEnd = mesh.positions.filter { $0.z > 2.6 - 0.25 }.map(\.y).max()!
        XCTAssertLessThan(nearEnd, 1.6, "the hedge's end is a cut face")
    }

    /// Pinned, so the browser's build is held to the phone's: a host whose
    /// arithmetic drew a different edge would fail here, in the wasm run too.
    func testTheEdgesArePinned() {
        let outline = Organic.outline(width: 5.2, length: 5.2, seed: 1)
        XCTAssertEqual(outline.count, 236)
        XCTAssertEqual(outline[37].x, Self.pinnedX, accuracy: 0)
        XCTAssertEqual(Organic.verge(1.25, side: -1, seed: 9), Self.pinnedVerge, accuracy: 0)
    }

    // Recorded from the Mac on 18 September.
    static let pinnedX = 2.5520523177413876
    static let pinnedVerge = -0.04130876521794288

    private func stride_(from: Int, to: Int) -> [Int] { from < to ? Array(from..<to) : [] }
}
