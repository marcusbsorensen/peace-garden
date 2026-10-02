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
        XCTAssertGreaterThan(furthest, side / 2 - 0.05)
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

    /// **A run that does not bow is the run four areas already draw, to the
    /// bit.** The Knot Garden's curve goes through the call the Long Walk, the
    /// Quiet Garden and the app's hedges all make, and none of their hedges
    /// should move a millimetre because a fifth area asked for a curve.
    func testAHedgeThatDoesNotBowIsTheHedgeItWas() {
        let asked = Organic.hedge(length: 5.2, height: 2.0, thickness: 0.36, seed: 5, bow: 0)
        let never = Organic.hedge(length: 5.2, height: 2.0, thickness: 0.36, seed: 5)
        XCTAssertEqual(asked.positions, never.positions)
        XCTAssertEqual(asked.normals, never.normals)
    }

    /// **A bow moves the middle of a run and leaves both its ends**, which is
    /// what lets the Knot Garden curve its bands without moving a crossing or a
    /// compartment — and it turns the section with the line rather than
    /// leaning it over, so a bowed run is as thick as a straight one the whole
    /// way along.
    func testABowedHedgeKeepsItsEndsAndItsThickness() {
        let length = 1.44, bow = 0.13
        let straight = Organic.hedge(length: length, height: 0.17, thickness: 0.18,
                                     seed: 7, domed: false)
        let bowed = Organic.hedge(length: length, height: 0.17, thickness: 0.18,
                                  seed: 7, domed: false, bow: bow)
        XCTAssertEqual(bowed.positions.count, straight.positions.count)

        // A ring's two ground vertices are its first and its last; the point
        // between them is where the run's own line is.
        let stride = 21
        let rings = straight.positions.count / stride
        func line(_ mesh: StructureMesh, _ ring: Int) -> SIMD3<Float> {
            (mesh.positions[ring * stride] + mesh.positions[ring * stride + stride - 1]) / 2
        }
        for end in [0, rings - 1] {
            XCTAssertEqual(line(bowed, end).x, line(straight, end).x, accuracy: 0.005,
                           "a bow moved an end of the run")
            XCTAssertEqual(line(bowed, end).z, line(straight, end).z, accuracy: 0.02,
                           "a bow shortened the run")
        }
        XCTAssertEqual(Double(line(bowed, rings / 2).x - line(straight, rings / 2).x),
                       bow, accuracy: 1e-5, "the middle does not stand off by the bow")

        func across(_ mesh: StructureMesh, _ ring: Int) -> Double {
            let d = mesh.positions[ring * stride] - mesh.positions[ring * stride + stride - 1]
            return Double((d * d).sum().squareRoot())
        }
        for ring in 0..<rings {
            XCTAssertEqual(across(bowed, ring), across(straight, ring), accuracy: 1e-5,
                           "the bow thinned the run at ring \(ring)")
        }
    }

    /// Pinned, so the browser's build is held to the phone's: a host whose
    /// arithmetic drew a different edge would fail here, in the wasm run too.
    func testTheEdgesArePinned() {
        let outline = Organic.outline(width: 5.2, length: 5.2, seed: 1)
        XCTAssertEqual(outline.count, 230)
        XCTAssertEqual(outline[37].x, Self.pinnedX, accuracy: 0)
        XCTAssertEqual(Organic.verge(1.25, side: -1, seed: 9), Self.pinnedVerge, accuracy: 0)
    }

    // Recorded from the Mac on 18 September.
    static let pinnedX = 2.5134835866491474
    static let pinnedVerge = -0.03701313226545083

    // MARK: - A tree

    /// The Orchard's trees are structures nobody planted, so nothing about them
    /// is checked by a placement vector. These are the properties the drawing
    /// depends on.
    func testATreeStandsOnTheGroundAndClearsItsOwnGuild() {
        let tree = Organic.tree(seed: 5)
        XCTAssertFalse(tree.positions.isEmpty)
        XCTAssertEqual(tree.normals.count, tree.positions.count)
        XCTAssertEqual(tree.indices.count % 3, 0)
        for i in tree.indices { XCTAssertLessThan(Int(i), tree.positions.count) }

        let low = tree.positions.map(\.y).min() ?? 1
        let high = tree.positions.map(\.y).max() ?? 0
        XCTAssertEqual(low, 0, accuracy: 1e-5, "a tree has to stand on the ground")
        XCTAssertGreaterThan(high, 3.0, "a tree has to be taller than any plant")

        // Every normal is a unit vector, including the two poles of the canopy,
        // whose vertices are all at one point and are given one averaged normal
        // rather than the star `computeNormals` would leave.
        for n in tree.normals {
            XCTAssertEqual((n.x * n.x + n.y * n.y + n.z * n.z).squareRoot(), 1, accuracy: 1e-4)
        }

        // **Nothing is drawn where a guild stands.** A plant sits
        // `Orchard.guildRadius` from an outer trunk, and the middle tree's four
        // `Orchard.middleRadius` from theirs, further in under the canopy
        // (since 2 October 2026); the canopy's lowest point out past the
        // nearer of the two has to be above the tallest plant this garden
        // grows.
        let reach = Float(min(Orchard.guildRadius, Orchard.middleRadius))
        let overhead = tree.positions
            .filter { ($0.x * $0.x + $0.z * $0.z).squareRoot() > reach - 0.03 && $0.y > 1 }
            .map(\.y).min() ?? 0
        XCTAssertGreaterThan(overhead, 2.35, "the canopy dips into the guild beneath it")
    }

    /// The same seed is the same tree, and a different seed is a different one —
    /// so a plot is the same on every visit and five trees are not one tree
    /// drawn five times.
    func testATreeIsItsSeed() {
        XCTAssertEqual(Organic.tree(seed: 11).positions, Organic.tree(seed: 11).positions)
        XCTAssertNotEqual(Organic.tree(seed: 11).positions, Organic.tree(seed: 12).positions)
    }

    private func stride_(from: Int, to: Int) -> [Int] { from < to ? Array(from..<to) : [] }
}
