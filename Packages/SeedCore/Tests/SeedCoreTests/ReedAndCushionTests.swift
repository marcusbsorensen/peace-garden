import XCTest
@testable import SeedCore

/// The reed and the cushion, the two families added on 28 September 2026.
///
/// Grown first as prototypes on `shape/reed-cushion` and approved as rendered;
/// these are the tests the prototypes carried, asked now of seeds that grow
/// into the real thing.
final class ReedAndCushionTests: XCTestCase {
    /// The first six minted seeds of a family, found by minting until there
    /// are six. A fourteenth of all seeds is each, so this is about ninety.
    private func seeds(of archetype: Archetype) -> [SeedID] {
        var found: [SeedID] = []
        var index = 0
        while found.count < 6 {
            let seed = SeedMint.mint(fromEntropy: Data("reed-cushion-\(index)".utf8))
            if Genome(seed: seed).form.archetype == archetype { found.append(seed) }
            index += 1
        }
        return found
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
        for archetype in [Archetype.reed, .cushion] {
            for (index, seed) in seeds(of: archetype).enumerated() {
                let genome = Genome(seed: seed)
                for state in states(for: genome) {
                    let mesh = PlantBuilder(genome: genome).mesh(growth: state)
                    for part in mesh.parts {
                        for p in part.positions {
                            XCTAssertTrue(p.x.isFinite && p.y.isFinite && p.z.isFinite,
                                          "\(archetype) \(index) at \(state.stage)")
                        }
                    }
                }
            }
        }
    }

    /// A cushion is a mound: wider than it is tall at every age, and never
    /// more than a hand's height.
    func testACushionIsWiderThanItIsTall() {
        for (index, seed) in seeds(of: .cushion).enumerated() {
            let genome = Genome(seed: seed)
            XCTAssertTrue(genome.habit.cushion)
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
        for (index, seed) in seeds(of: .reed).enumerated() {
            let genome = Genome(seed: seed)
            XCTAssertTrue(genome.habit.rosette)
            XCTAssertTrue(genome.habit.strap)
            XCTAssertTrue(genome.bloom.atNodes)
            let grown = Maturity.bloomPreview(for: genome)
            let placements = PlantBuilder(genome: genome).bloomPlacementsForTesting(growth: grown)
            guard genome.bloom.present else { continue }
            XCTAssertFalse(placements.isEmpty, "reed \(index)")
            for placement in placements where placement.kind == .node {
                XCTAssertGreaterThan(placement.t, 0.7, "reed \(index)")
            }
        }
    }

    /// Nothing else is a strap or a cushion: the two habits are the two
    /// families', and no other family's plant grows either by accident.
    func testOnlyTheirOwnFamiliesCarryTheirHabits() {
        for index in 0..<400 {
            let genome = Genome(seed: SeedMint.mint(fromEntropy: Data("habit-\(index)".utf8)))
            XCTAssertEqual(genome.habit.strap, genome.form.archetype == .reed, "seed \(index)")
            XCTAssertEqual(genome.habit.cushion, genome.form.archetype == .cushion, "seed \(index)")
        }
    }

    /// The reed stands in water, as the lily does, and the cushion does not.
    func testTheReedWantsWaterAndTheCushionDoesNot() {
        XCTAssertTrue(Archetype.reed.wantsWater)
        XCTAssertFalse(Archetype.cushion.wantsWater)
        XCTAssertEqual(Archetype.allCases.filter(\.wantsWater), [.lotus, .reed])
    }
}
