import XCTest
@testable import SeedCore

/// The Glasshouse's structures: the house's bars and glass, the staging, and
/// the pots on it.
final class SpanHouseTests: XCTestCase {

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

    func testEveryPieceIsWellFormed() {
        wellFormed(Organic.spanHouse(seed: 1), "the bars")
        wellFormed(Organic.spanHouseGlass(seed: 1), "the glass")
        wellFormed(Organic.staging(seed: 1), "the staging")
        wellFormed(Organic.pot(seed: 1), "a pot")
        wellFormed(Organic.potSoil(seed: 1), "its soil")
    }

    /// The house stands on the floor, inside the plot, and its ridge is the
    /// height the rule measures its plants against.
    func testTheHouseIsTheSizeTheRuleMeasures() {
        let (lo, hi) = bounds(Organic.spanHouse(seed: 3))
        XCTAssertEqual(Double(lo.y), 0, accuracy: 0.01)
        XCTAssertEqual(Double(hi.y), Glasshouse.ridge + Organic.houseBarDeep / 2, accuracy: 0.02)
        XCTAssertLessThan(Double(hi.x), Glasshouse.houseLength / 2 + 0.05)
        XCTAssertLessThan(Double(hi.z), Glasshouse.houseWidth / 2 + 0.05)
        // The open door stands just outside the door's gable and nowhere else.
        XCTAssertGreaterThan(Double(lo.x), -Glasshouse.houseLength / 2 - 0.1)
        XCTAssertLessThan(Double(lo.x), -Glasshouse.houseLength / 2 - 0.03)
    }

    /// **The roof's glass is never under the line the rule measures against**,
    /// so a plant `GlasshouseTests` holds under `Glasshouse.roof` is under the
    /// glass the page draws.
    func testTheRoofGlassLiesOnTheRoof() {
        let glass = Organic.spanHouseGlass(seed: 5)
        let hx = Glasshouse.houseLength / 2, hz = Glasshouse.houseWidth / 2
        // Between the gables and between the side walls: the roof alone.
        for p in glass.positions where abs(Double(p.x)) < hx - 0.01 && abs(Double(p.z)) < hz - 0.01
            && Double(p.y) > Glasshouse.eaves + 0.01 {
            XCTAssertGreaterThanOrEqual(Double(p.y), Glasshouse.roof(atDepth: Double(p.z)) - 0.003)
        }
    }

    /// The doorway is left open: no glass stands in it.
    func testTheDoorwayHasNoGlassInIt() {
        let glass = Organic.spanHouseGlass(seed: 7)
        let hx = Glasshouse.houseLength / 2
        for t in stride(from: 0, to: glass.indices.count, by: 3) {
            let corners = (0..<3).map { glass.positions[Int(glass.indices[t + $0])] }
            let middle = corners.reduce(SIMD3<Float>.zero, +) / 3
            if abs(Double(middle.x) + hx) < 0.01 {
                XCTAssertFalse(abs(Double(middle.z)) < Organic.doorHalf - 0.05 && Double(middle.y) < Organic.doorHead - 0.05,
                               "a pane in the doorway at \(middle)")
            }
        }
    }

    /// The staging's top is where the rule stands its pots, and a pot's soil
    /// where it stands their plants.
    func testThePotsStandWhereTheRuleSays() {
        let (slo, shi) = bounds(Organic.staging(seed: 2))
        XCTAssertEqual(Double(slo.y), 0, accuracy: 0.01)
        XCTAssertEqual(Double(shi.y), Glasshouse.stagingTop, accuracy: 0.01)
        XCTAssertLessThan(Double(shi.z), Glasshouse.stagingDepth / 2 + 0.01)
        // Every place on the staging stands over it.
        for slot in Glasshouse.slots where slot.bed == .staging {
            XCTAssertLessThan(abs(slot.spot.x), Double(shi.x) - 0.08)
        }
        let (plo, phi) = bounds(Organic.pot(seed: 2))
        XCTAssertEqual(Double(plo.y), 0, accuracy: 0.001)
        XCTAssertGreaterThan(Double(phi.y), Glasshouse.potSoil)
        let (_, soil) = bounds(Organic.potSoil(seed: 2))
        XCTAssertEqual(Double(soil.y), Glasshouse.potSoil + 0.006, accuracy: 0.002)
        // Two pots side by side on the staging do not overlap.
        XCTAssertLessThan(Double(phi.x - plo.x) + 0.01, Glasshouse.alongGap)
        XCTAssertLessThan(Double(phi.x - plo.x) + 0.01, 2 * Glasshouse.rowFrom)
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
