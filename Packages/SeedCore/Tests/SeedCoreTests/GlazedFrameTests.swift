import XCTest
@testable import SeedCore

/// The cold frame's three pieces: the box, the lights' bars, and the glass.
final class GlazedFrameTests: XCTestCase {

    private func bounds(_ mesh: StructureMesh) -> (min: SIMD3<Float>, max: SIMD3<Float>) {
        var lo = SIMD3<Float>(repeating: .greatestFiniteMagnitude)
        var hi = SIMD3<Float>(repeating: -.greatestFiniteMagnitude)
        for p in mesh.positions {
            lo = SIMD3(min(lo.x, p.x), min(lo.y, p.y), min(lo.z, p.z))
            hi = SIMD3(max(hi.x, p.x), max(hi.y, p.y), max(hi.z, p.z))
        }
        return (lo, hi)
    }

    private func wellFormed(_ mesh: StructureMesh, _ name: String) {
        XCTAssertFalse(mesh.indices.isEmpty, "\(name) is empty")
        XCTAssertEqual(mesh.indices.count % 3, 0, "\(name) has a broken triangle")
        XCTAssertEqual(mesh.normals.count, mesh.positions.count, "\(name) is missing normals")
        XCTAssertTrue(mesh.indices.allSatisfy { Int($0) < mesh.positions.count }, "\(name) points past its end")
        XCTAssertTrue(mesh.positions.allSatisfy { $0.x.isFinite && $0.y.isFinite && $0.z.isFinite })
    }

    func testAllThreePiecesAreWellFormed() {
        wellFormed(Organic.coldFrame(seed: 1), "the box")
        wellFormed(Organic.frameLights(seed: 1), "the lights")
        wellFormed(Organic.frameGlass(seed: 1), "the glass")
    }

    func testTheBoxStandsOnTheGroundWithinItsFootprintAndIsHigherAtTheBack() {
        let box = Organic.coldFrame(seed: 7)
        let (lo, hi) = bounds(box)
        XCTAssertEqual(Double(lo.y), 0, accuracy: 0.01)
        XCTAssertLessThan(abs(Double(lo.x)), ColdFrame.frameLength / 2 + 0.01)
        XCTAssertLessThan(Double(hi.x), ColdFrame.frameLength / 2 + 0.01)
        XCTAssertLessThan(Double(hi.z), ColdFrame.frameDepth / 2 + 0.01)
        XCTAssertEqual(Double(hi.y), ColdFrame.backWall, accuracy: 0.01)
        // The highest point at the front is the front wall.
        let frontTop = box.positions.filter { Double($0.z) > ColdFrame.frameDepth / 2 - 0.03 }.map(\.y).max() ?? 0
        XCTAssertEqual(Double(frontTop), ColdFrame.frontWall, accuracy: 0.01)
    }

    /// The ends are cut to the slope, so nowhere along them does a board stand
    /// above the line from the back wall's top to the front's.
    func testTheEndsFollowTheSlope() {
        let box = Organic.coldFrame(seed: 3)
        let depth = ColdFrame.frameDepth
        for p in box.positions where abs(Double(p.x)) > ColdFrame.frameLength / 2 - 0.05 {
            let t = (Double(p.z) + depth / 2) / depth
            let line = ColdFrame.backWall + (ColdFrame.frontWall - ColdFrame.backWall) * min(1, max(0, t))
            XCTAssertLessThan(Double(p.y), line + 0.01)
        }
    }

    func testTheLightsRestOnTheBackWallAndArePropped() {
        let lights = Organic.frameLights(seed: 5)
        let (lo, hi) = bounds(lights)
        // The blocks stand on the front wall; nothing is lower.
        XCTAssertEqual(Double(lo.y), ColdFrame.frontWall, accuracy: 0.01)
        XCTAssertEqual(Double(hi.y), ColdFrame.backWall + Organic.lightBarDeep, accuracy: 0.01)
        // The bars at the front are lifted by the prop.
        let front = lights.positions.filter { Double($0.z) > ColdFrame.frameDepth / 2 - 0.02 }
        let lowestBarAtFront = front.filter { Double($0.y) > ColdFrame.frontWall + ColdFrame.propped - 0.01 }
        XCTAssertFalse(lowestBarAtFront.isEmpty)
    }

    func testTheGlassLiesInTheLightsFacingTheSky() {
        let glass = Organic.frameGlass(seed: 9)
        let (lo, hi) = bounds(glass)
        XCTAssertGreaterThan(Double(lo.x), -ColdFrame.frameLength / 2)
        XCTAssertLessThan(Double(hi.x), ColdFrame.frameLength / 2)
        XCTAssertGreaterThan(Double(lo.z), -ColdFrame.frameDepth / 2)
        XCTAssertLessThan(Double(hi.z), ColdFrame.frameDepth / 2)
        for (p, n) in zip(glass.positions, glass.normals) {
            let under = ColdFrame.glass(atDepth: Double(p.z))
            XCTAssertGreaterThan(Double(p.y), under, "a pane is below the lights' underside")
            XCTAssertLessThan(Double(p.y), under + Organic.lightBarDeep + 0.01, "a pane is above its bars")
            XCTAssertGreaterThan(n.y, 0.95, "a pane faces somewhere other than the sky")
        }
    }

    /// The ripple is small, and it is there: a flat pane would be one tint.
    func testTheGlassIsNotQuiteFlat() {
        let glass = Organic.frameGlass(seed: 11)
        let tilts = glass.normals.map { 1 - $0.y }
        XCTAssertGreaterThan(tilts.max() ?? 0, 1e-5)
        XCTAssertLessThan(tilts.max() ?? 1, 0.05)
    }

    func testTheSameSeedDrawsTheSameFrame() {
        XCTAssertEqual(Organic.coldFrame(seed: 42).positions, Organic.coldFrame(seed: 42).positions)
        XCTAssertNotEqual(Organic.coldFrame(seed: 42).positions, Organic.coldFrame(seed: 43).positions)
    }
}
