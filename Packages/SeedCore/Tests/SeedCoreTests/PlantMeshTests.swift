import XCTest
#if canImport(simd)
import simd
#endif
@testable import SeedCore

final class PlantMeshTests: XCTestCase {
    private func genome(_ index: Int) -> Genome {
        Genome(seed: SeedMint.mint(fromEntropy: Data("mesh-\(index)".utf8)))
    }

    private func states(for genome: Genome) -> [GrowthModel.State] {
        let model = GrowthModel(genome: genome)
        let birth = Date(timeIntervalSince1970: 1_700_000_000)
        return [0.0, 0.5, 2.0, 6.0, 12.0, 40.0, 400.0].map {
            model.state(birth: birth, now: birth.addingTimeInterval($0 * 86_400))
        }
    }

    func testEveryPlantProducesValidGeometry() {
        // The mesh maths involves normalising vectors that can collapse at tips
        // and poles; one NaN reaches the GPU as a black hole in the middle of
        // someone's flower, so check the whole sweep of genomes and stages.
        for index in 0..<120 {
            let genome = genome(index)
            let builder = PlantBuilder(genome: genome)
            for state in states(for: genome) {
                let mesh = builder.mesh(growth: state)
                XCTAssertFalse(mesh.parts.isEmpty, "genome \(index) produced nothing")

                for part in mesh.parts {
                    XCTAssertEqual(part.positions.count, part.normals.count)
                    XCTAssertEqual(part.positions.count, part.uvs.count)
                    XCTAssertEqual(part.indices.count % 3, 0)

                    for position in part.positions {
                        XCTAssertTrue(position.x.isFinite && position.y.isFinite && position.z.isFinite,
                                      "non-finite position in \(part.role) of genome \(index)")
                    }
                    for normal in part.normals {
                        XCTAssertTrue(normal.x.isFinite && normal.y.isFinite && normal.z.isFinite,
                                      "non-finite normal in \(part.role) of genome \(index)")
                        XCTAssertEqual(simd_length(normal), 1.0, accuracy: 1e-3,
                                       "un-normalised normal in \(part.role) of genome \(index)")
                    }
                    let vertexCount = UInt32(part.positions.count)
                    for index in part.indices {
                        XCTAssertLessThan(index, vertexCount, "index out of range in \(part.role)")
                    }
                }
            }
        }
    }

    func testTheSameMomentAlwaysDrawsTheSamePlant() {
        let genome = genome(7)
        let builder = PlantBuilder(genome: genome)
        let state = states(for: genome)[4]
        let first = builder.mesh(growth: state)
        let second = PlantBuilder(genome: genome).mesh(growth: state)

        XCTAssertEqual(first.parts.count, second.parts.count)
        for (left, right) in zip(first.parts, second.parts) {
            XCTAssertEqual(left.positions, right.positions)
            XCTAssertEqual(left.indices, right.indices)
        }
    }

    func testPlantsEndUpTallerAndFullerThanTheyStarted() {
        for index in 0..<40 {
            let genome = genome(index)
            let builder = PlantBuilder(genome: genome)
            let sequence = states(for: genome).map { builder.mesh(growth: $0) }

            XCTAssertGreaterThan(sequence.last!.height, sequence.first!.height,
                                 "plant \(index) ended up no taller than its seed")
            XCTAssertGreaterThan(sequence.last!.vertexCount, sequence.first!.vertexCount,
                                 "plant \(index) never filled out")

            // Height is deliberately not monotonic. The seed husk is wider than
            // the shoot that replaces it, and a flower opening outward lowers
            // the crown it was standing in. Both are correct; a collapse is not.
            for (earlier, later) in zip(sequence, sequence.dropFirst()) {
                XCTAssertGreaterThan(later.height, earlier.height * 0.5,
                                     "plant \(index) collapsed between stages")
            }
        }
    }

    func testAMatureFloweringPlantHasEveryPart() {
        guard let genome = (0..<80).lazy.map(genome).first(where: {
            $0.bloom.present && $0.bloom.stamenCount > 0 && $0.leafCount > 0
        }) else {
            return XCTFail("no flowering genome in the sample")
        }
        let model = GrowthModel(genome: genome)
        let birth = Date(timeIntervalSince1970: 1_700_000_000)
        // Pick the moment the flower is widest open rather than assuming one.
        let states = stride(from: genome.tempo.daysToBloom, through: genome.tempo.daysToBloom + 20, by: 0.2)
            .map { model.state(birth: birth, now: birth.addingTimeInterval($0 * 86_400)) }
        guard let peak = states.max(by: { $0.bloomOpen < $1.bloomOpen }) else {
            return XCTFail("no growth states")
        }
        XCTAssertGreaterThan(peak.bloomOpen, 0.5)

        let roles = Set(PlantBuilder(genome: genome).mesh(growth: peak).parts.map(\.role))
        XCTAssertTrue(roles.isSuperset(of: [.stem, .leaf, .petal, .centre, .stamen]),
                      "missing parts: \(Set(MeshRole.allCases).subtracting(roles))")
    }

    func testGeometryStaysWithinAReasonableBudget() {
        // The scene redraws this on every growth tick and the garden shows
        // several at once, so a plant that runs to a million triangles is a bug.
        for index in 0..<80 {
            let genome = genome(index)
            let model = GrowthModel(genome: genome)
            let birth = Date(timeIntervalSince1970: 1_700_000_000)
            let mature = model.state(birth: birth, now: birth.addingTimeInterval(400 * 86_400))
            let mesh = PlantBuilder(genome: genome).mesh(growth: mature)
            XCTAssertLessThan(mesh.triangleCount, 120_000,
                              "genome \(index) built \(mesh.triangleCount) triangles")
        }
    }
}
