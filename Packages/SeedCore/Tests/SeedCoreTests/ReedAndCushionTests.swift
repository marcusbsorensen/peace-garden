import XCTest
@_spi(Prototype) @testable import SeedCore

/// The reed and the cushion, grown as prototypes before they are archetypes.
/// See `ArchetypeProfile.Prototype`.
final class PrototypeFormTests: XCTestCase {
    private func seed(_ index: Int) -> SeedID {
        SeedMint.mint(fromEntropy: Data("prototype-\(index)".utf8))
    }

    private func states(for genome: Genome) -> [GrowthModel.State] {
        let model = GrowthModel(genome: genome)
        let birth = Date(timeIntervalSince1970: 1_700_000_000)
        return [0.5, 6.0, 40.0].map {
            model.state(birth: birth, now: birth.addingTimeInterval($0 * 86_400))
        }
    }

    /// One NaN reaches the GPU as a hole in somebody's plant.
    func testBothShapesGrowValidGeometryAtEveryAge() {
        for prototype in ArchetypeProfile.Prototype.allCases {
            for index in 0..<6 {
                let genome = Genome(seed: seed(index), prototype: prototype)
                for state in states(for: genome) {
                    let mesh = PlantBuilder(genome: genome).mesh(growth: state)
                    for part in mesh.parts {
                        for p in part.positions {
                            XCTAssertTrue(p.x.isFinite && p.y.isFinite && p.z.isFinite,
                                          "\(prototype) \(index) at \(state.stage)")
                        }
                    }
                }
            }
        }
    }

    /// A cushion is a mound: wider than it is tall at every age, and never
    /// more than a hand's height.
    func testACushionIsWiderThanItIsTall() {
        for index in 0..<6 {
            let genome = Genome(seed: seed(index), prototype: .cushion)
            for state in states(for: genome) where state.leafUnfurl > 0 {
                let mesh = PlantBuilder(genome: genome).mesh(growth: state)
                let extent = mesh.maxBounds - mesh.minBounds
                XCTAssertGreaterThan(Swift.max(extent.x, extent.z), extent.y * 1.3, "cushion \(index)")
                XCTAssertLessThan(mesh.maxBounds.y, 0.3, "cushion \(index)")
            }
        }
    }

    /// A reed's flowers are all near the top of a bare culm, and its leaves
    /// are all at the foot.
    func testAReedFlowersAtTheTopOfABareCulm() {
        for index in 0..<6 {
            let genome = Genome(seed: seed(index), prototype: .reed)
            XCTAssertTrue(genome.habit.rosette)
            XCTAssertTrue(genome.habit.strap)
            XCTAssertTrue(genome.bloom.atNodes)
            let grown = Maturity.bloomPreview(for: genome)
            let placements = PlantBuilder(genome: genome).bloomPlacementsForTesting(growth: grown)
            XCTAssertFalse(placements.isEmpty, "reed \(index)")
            for placement in placements where placement.kind == .node {
                XCTAssertGreaterThan(placement.t, 0.7, "reed \(index)")
            }
        }
    }

    /// Growing a seed as a prototype leaves the seed's own plant as it was.
    func testAPrototypeDoesNotChangeTheSeedsOwnPlant() {
        for index in 0..<8 {
            let before = Genome(seed: seed(index))
            _ = Genome(seed: seed(index), prototype: .reed)
            _ = Genome(seed: seed(index), prototype: .cushion)
            XCTAssertEqual(Genome(seed: seed(index)), before)
            XCTAssertFalse(before.habit.strap)
            XCTAssertFalse(before.habit.cushion)
        }
    }
}
