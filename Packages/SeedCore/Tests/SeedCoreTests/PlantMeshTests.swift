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

            // Height is deliberately not monotonic: a flower opening outward
            // lowers the crown it was standing in. That is correct; a collapse
            // is not. This used to also say the husk was wider than the shoot
            // it replaced, which was not a fact about plants but the bug in
            // `testAFreshlySownSeedLooksLikeAShootAndNotAMushroom`, written
            // down as though it were intended.
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

    func testAFreshlySownSeedLooksLikeAShootAndNotAMushroom() {
        // The plant a person meets first is the one drawn seconds ago, and for
        // a long time it was the one frame nobody had ever rendered: the husk
        // was sized from `stem.baseRadius` — the radius of the *mature* stem —
        // while the shoot beside it was drawn at a fraction of that, so the
        // seed case came out three times wider than the whole plant was tall
        // and swallowed it. The camera frames whatever it is given, so what
        // arrived on the phone was a mushroom.
        for index in 0..<120 {
            let genome = genome(index)
            let model = GrowthModel(genome: genome)
            let birth = Date(timeIntervalSince1970: 1_700_000_000)

            // The first hours, where the height ramp — measured in days — has
            // barely moved and the husk is at its fullest.
            for hours in [0.0, 0.5, 2.0, 6.0] {
                let state = model.state(birth: birth, now: birth.addingTimeInterval(hours * 3600))
                let mesh = PlantBuilder(genome: genome).mesh(growth: state)
                // The stem part is the tube and the husk and nothing else, so
                // measuring it against the skeleton isolates the husk's own
                // contribution. Early leaves belong to the plant, not the husk.
                guard let stem = mesh.parts.first(where: { $0.role == .stem }) else {
                    return XCTFail("genome \(index) at \(hours)h has no stem")
                }
                var stemMin = SIMD3<Float>(repeating: .greatestFiniteMagnitude)
                var stemMax = SIMD3<Float>(repeating: -.greatestFiniteMagnitude)
                for position in stem.positions {
                    stemMin = simd_min(stemMin, position)
                    stemMax = simd_max(stemMax, position)
                }

                // What the shoot alone fills: its path, fattened by its radius.
                // The assertions are about what the husk *adds* to that, which
                // is the thing that went wrong; a succulent's shoot is a stubby
                // barrel and a spire's is a thread, and both are correct.
                let skeleton = SkeletonBuilder.stem(genome: genome, heightScale: Float(state.heightScale))
                var shootMin = SIMD3<Float>(repeating: .greatestFiniteMagnitude)
                var shootMax = SIMD3<Float>(repeating: -.greatestFiniteMagnitude)
                for sample in skeleton.stem {
                    shootMin = simd_min(shootMin, sample.position - SIMD3(repeating: sample.radius))
                    shootMax = simd_max(shootMax, sample.position + SIMD3(repeating: sample.radius))
                }

                // The sharp one: a seed case sits at the shoot's foot. The
                // moment it is the tallest thing on the plant, what the phone
                // draws is a mushroom.
                XCTAssertLessThanOrEqual(
                    stemMax.y, shootMax.y + 1e-5,
                    "genome \(index) at \(hours)h: the husk stands above the shoot"
                )

                // And it may be wider than the thread it wraps — a seed is —
                // but not by the five-fold it once was.
                let shootExtent = shootMax - shootMin
                let width = Swift.max(stemMax.x - stemMin.x, stemMax.z - stemMin.z)
                let shootWidth = Swift.max(shootExtent.x, shootExtent.z)
                XCTAssertLessThanOrEqual(
                    width, shootWidth * 2.5,
                    "genome \(index) at \(hours)h: the husk is \(width / shootWidth)x the shoot's width"
                )
            }
        }
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
