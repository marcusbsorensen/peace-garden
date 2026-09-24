import XCTest
@testable import SeedCore

/// The Coppice's one structure: the stool a fern on a stool grows from, its
/// bark and its cut face.
final class StoolTests: XCTestCase {

    private func wellFormed(_ mesh: StructureMesh, _ name: String) {
        XCTAssertFalse(mesh.indices.isEmpty, "\(name) is empty")
        XCTAssertEqual(mesh.indices.count % 3, 0, "\(name) has a broken triangle")
        XCTAssertEqual(mesh.normals.count, mesh.positions.count, "\(name) is missing normals")
        XCTAssertTrue(mesh.indices.allSatisfy { Int($0) < mesh.positions.count }, "\(name) points past its end")
        XCTAssertTrue(mesh.positions.allSatisfy { $0.x.isFinite && $0.y.isFinite && $0.z.isFinite })
    }

    private func across(_ p: SIMD3<Float>) -> Double {
        (Double(p.x) * Double(p.x) + Double(p.z) * Double(p.z)).squareRoot()
    }

    func testEveryPieceIsWellFormed() {
        wellFormed(Organic.stool(seed: 1), "the bark")
        wellFormed(Organic.stoolFace(seed: 1), "the cut face")
        XCTAssertEqual(Organic.stoolFootprint(seed: 1).count, Organic.stoolAround)
    }

    /// **The width is the seed's, and within the rule's.** Every stool is
    /// between 0.35 and 0.45 m across, and the seeds between them use the whole
    /// of that, so a coupe's five stools are not five of one size.
    func testTheWidthComesFromTheSeedAndStaysInTheRange() {
        let widths = (0..<300).map { Organic.stoolAcross(seed: mix64(UInt64($0))) }
        for width in widths { XCTAssertTrue(Coppice.stoolAcross.contains(width)) }
        XCTAssertLessThan(widths.min()!, 0.36)
        XCTAssertGreaterThan(widths.max()!, 0.44)
    }

    /// **The footprint is the stool's whole extent**, and it wanders: more
    /// than a sawn board's four millimetres, and only ever inward from the
    /// width, so no stool is wider than the width the rule's clearance was
    /// measured at.
    func testTheOutlineWandersInwardAndNothingStandsOutsideIt() {
        for seed in (0..<40).map({ mix64(UInt64($0) &+ 900) }) {
            let half = Organic.stoolAcross(seed: seed) / 2
            let radii = Organic.stoolFootprint(seed: seed).map { ($0.x * $0.x + $0.z * $0.z).squareRoot() }
            // `Organic.turn` is a circle to two parts in a hundred thousand,
            // which on a stool is four microns.
            XCTAssertLessThanOrEqual(radii.max()!, half * (1 + 2e-5))
            XCTAssertGreaterThanOrEqual(radii.min()!, (half - Organic.stoolWander) * (1 - 2e-5))
            XCTAssertGreaterThan(radii.max()! - radii.min()!, 0.012, "a stool as round as a sawn thing")
            XCTAssertLessThanOrEqual(half, Coppice.stoolAcross.upperBound / 2)
            for p in Organic.stool(seed: seed).positions {
                XCTAssertLessThanOrEqual(across(p), half * (1 + 2e-5) + 1e-6)
            }
        }
    }

    /// **The fern's foot stands on the face**: its middle is at
    /// `Coppice.stoolHeight`, the height `stage.add` lifts a fern on a stool
    /// by, and the rest of it stays within the slope of the cut.
    func testTheFaceIsWhereTheFernStands() {
        for seed: UInt64 in [3, 41, 977, 0xDEAD_BEEF] {
            let face = Organic.stoolFace(seed: seed)
            XCTAssertEqual(face.positions[0], SIMD3<Float>(0, Float(Coppice.stoolHeight), 0))
            for p in face.positions {
                XCTAssertEqual(Double(p.y), Coppice.stoolHeight, accuracy: Organic.stoolSlope / 2 + 0.002)
            }
            // The face points up.
            XCTAssertGreaterThan(face.normals[0].y, 0.99)
        }
    }

    /// **The bark meets the face with no gap**: every point on the face's
    /// edge is a point of the bark's top ring, to the bit.
    func testTheBarkMeetsTheFace() {
        let seed: UInt64 = 12
        let bark = Set(Organic.stool(seed: seed).positions.map { [$0.x, $0.y, $0.z] })
        let face = Organic.stoolFace(seed: seed).positions
        for p in face.suffix(Organic.stoolAround + 1) {
            XCTAssertTrue(bark.contains([p.x, p.y, p.z]), "a gap at \(p)")
        }
    }

    /// The bark goes below the ground, so a stool on a slope of the floor is
    /// sunk on its low side, and its top is the cut.
    func testTheStoolIsSunkAndAboutATenthOfAMetreHigh() {
        let bark = Organic.stool(seed: 8)
        let ys = bark.positions.map { Double($0.y) }
        XCTAssertEqual(ys.min()!, -Organic.stoolSunk, accuracy: 1e-6)
        XCTAssertEqual(ys.max()!, Coppice.stoolHeight, accuracy: Organic.stoolSlope / 2 + 0.002)
    }

    /// **A stool is round without `sin` or `cos`**, by `Organic.turn`, so the
    /// page and the phone draw one stool to the bit; and a planting's stool
    /// seed is its seed's first four bytes, which is what the page can hand
    /// the module.
    func testTheStoolSeedIsTheFirstFourBytes() {
        XCTAssertEqual(Coppice.stoolSeed("0a1b2c3d" + String(repeating: "f", count: 56)), 0x0A1B_2C3D)
        let one = Coppice.ambassador
        XCTAssertEqual(one.stoolSeed, UInt64(one.seed.prefix(8), radix: 16))
        XCTAssertEqual(Organic.stoolFootprint(seed: 77), Organic.stoolFootprint(seed: 77))
    }
}
