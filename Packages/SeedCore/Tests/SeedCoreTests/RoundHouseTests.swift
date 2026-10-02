import XCTest
@testable import SeedCore

/// The Glasshouse's structures since 2 October 2026: the round house's bars
/// and glass, the ring of staging, and the pots on it.
final class RoundHouseTests: XCTestCase {

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
        XCTAssertTrue(mesh.normals.allSatisfy { $0.x.isFinite && $0.y.isFinite && $0.z.isFinite })
    }

    private func radius(_ p: SIMD3<Float>) -> Double { Double((p.x * p.x + p.z * p.z).squareRoot()) }

    func testEveryPieceIsWellFormed() {
        wellFormed(Organic.roundHouse(seed: 1), "the bars")
        wellFormed(Organic.roundHouseGlass(seed: 1), "the glass")
        wellFormed(Organic.ringStaging(seed: 1), "the staging")
        wellFormed(Organic.pot(seed: 1), "a pot")
        wellFormed(Organic.potSoil(seed: 1), "its soil")
    }

    /// **The bars face out.** A bar swept along a curve has its normals
    /// pointing away from its own middle line, as the bench's planks do; a
    /// sweep wound the wrong way round would light every bar from inside.
    func testABarSweptAlongACurveFacesOut() {
        let path = (0...10).map { i -> SIMD3<Double> in
            let (c, s) = Organic.turn(Double(i) / 40)
            return SIMD3(c, 1, s)
        }
        var bar = Organic.rod(path, hint: { _ in SIMD3(0, 1, 0) }, width: 0.05, deep: 0.06)
        bar.computeNormals()
        var outward = 0, inward = 0
        for (k, p) in bar.positions.enumerated() where k < 11 * 13 {
            let middle = path[k / 13]
            let away = SIMD3<Float>(p.x - Float(middle.x), p.y - Float(middle.y), p.z - Float(middle.z))
            let n = bar.normals[k]
            if (away * n).sum() > 0 { outward += 1 } else { inward += 1 }
        }
        XCTAssertGreaterThan(outward, inward * 10, "\(inward) of \(outward + inward) normals face in")
    }

    /// The house stands on the floor, inside the plot, round the middle, and
    /// its crown is the height the rule measures its plants against.
    func testTheHouseIsTheSizeTheRuleMeasures() {
        let bars = Organic.roundHouse(seed: 3)
        let (lo, hi) = bounds(bars)
        XCTAssertEqual(Double(lo.y), 0, accuracy: 0.03)
        XCTAssertGreaterThan(Double(hi.y), Glasshouse.crown)
        XCTAssertLessThan(Double(hi.y), Glasshouse.crown + 0.25)
        // Nothing past the wall but the open door, a hand's breadth out.
        let outermost = bars.positions.map(radius).max()!
        XCTAssertLessThan(outermost, Glasshouse.houseRadius + 0.04 + 0.05 + Organic.houseBar)
        XCTAssertLessThan(outermost, Glasshouse.plotSide / 2 - 0.2)
        XCTAssertGreaterThan(outermost, Glasshouse.houseRadius)
    }

    /// **The dome's glass is never under the line the rule measures against**,
    /// so a plant `GlasshouseTests` holds under `Glasshouse.roof` is under the
    /// glass the page draws.
    func testTheRoofGlassLiesOnTheRoof() {
        let glass = Organic.roundHouseGlass(seed: 5)
        var checked = 0
        for p in glass.positions where Double(p.y) > Glasshouse.eaves + 0.01 && radius(p) < Glasshouse.houseRadius - 0.01 {
            XCTAssertGreaterThanOrEqual(Double(p.y), Glasshouse.roof(atRadius: radius(p)) - 0.003)
            checked += 1
        }
        XCTAssertGreaterThan(checked, 1000)
    }

    /// The doorway is left open: no glass stands in it below its head, and no
    /// sill crosses it. The door's own pane stands outside the wall.
    func testTheDoorwayHasNoGlassInIt() {
        let glass = Organic.roundHouseGlass(seed: 7)
        let (dx, dz) = Organic.circle(Glasshouse.doorTurn)
        for t in stride(from: 0, to: glass.indices.count, by: 3) {
            let corners = (0..<3).map { glass.positions[Int(glass.indices[t + $0])] }
            let middle = corners.reduce(SIMD3<Float>.zero, +) / 3
            let r = radius(middle)
            guard r > Glasshouse.houseRadius - 0.05, r < Glasshouse.houseRadius + 0.045 else { continue }
            // How far across the doorway's middle line the triangle is.
            let across = abs(Double(middle.x) * dz - Double(middle.z) * dx)
            let facing = Double(middle.x) * dx + Double(middle.z) * dz
            if facing > 0 && Double(middle.y) < Organic.doorHead - 0.05 {
                XCTAssertGreaterThan(across, Organic.doorHalf - 0.05, "a pane in the doorway at \(middle)")
            }
        }
    }

    /// **The staging is under every pot**, at the height the rule stands
    /// them, and a pot's soil is where it stands their plants.
    func testThePotsStandWhereTheRuleSays() {
        let staging = Organic.ringStaging(seed: 2)
        let (slo, shi) = bounds(staging)
        XCTAssertEqual(Double(slo.y), 0, accuracy: 0.01)
        XCTAssertEqual(Double(shi.y), Glasshouse.stagingTop, accuracy: 0.01)
        let tops = staging.positions.filter { abs(Double($0.y) - Glasshouse.stagingTop) < 0.003 }
        for slot in Glasshouse.slots where slot.bed == .staging {
            // A slat's top within a few centimetres of every pot, on both
            // sides of it across the staging.
            let near = tops.filter {
                let dx = Double($0.x) - slot.spot.x, dz = Double($0.z) - slot.spot.z
                return dx * dx + dz * dz < 0.25 * 0.25
            }
            let radii = near.map(radius)
            let r = (slot.spot.x * slot.spot.x + slot.spot.z * slot.spot.z).squareRoot()
            XCTAssertLessThan(radii.min() ?? .infinity, r - 0.12, "no staging inside \(slot)")
            XCTAssertGreaterThan(radii.max() ?? 0, r + 0.12, "no staging outside \(slot)")
        }
        let (plo, phi) = bounds(Organic.pot(seed: 2))
        XCTAssertEqual(Double(plo.y), 0, accuracy: 0.001)
        XCTAssertGreaterThan(Double(phi.y), Glasshouse.potSoil)
        let (_, soil) = bounds(Organic.potSoil(seed: 2))
        XCTAssertEqual(Double(soil.y), Glasshouse.potSoil + 0.006, accuracy: 0.002)
        // Two pots side by side on the staging do not touch.
        XCTAssertLessThan(Double(phi.x - plo.x) + 0.05, Glasshouse.potGap)
        // And the staging stands clear of the glass.
        XCTAssertLessThan(staging.positions.map(radius).max()!, Glasshouse.houseRadius - 0.1)
    }

    /// A pot is round without `sin` or `cos`, so it is the same on every host.
    /// The series `quarter` sums is good to about five millionths at the end of
    /// a quarter turn, which on a pot 9 cm across is half a micron.
    func testTheTurnIsACircle() {
        for k in 0..<40 {
            let (c, s) = Organic.turn(Double(k) / 40)
            XCTAssertEqual(c * c + s * s, 1, accuracy: 2e-5)
            XCTAssertEqual(c, cos(2 * .pi * Double(k) / 40), accuracy: 1e-5)
            XCTAssertEqual(s, sin(2 * .pi * Double(k) / 40), accuracy: 1e-5)
        }
    }
}
