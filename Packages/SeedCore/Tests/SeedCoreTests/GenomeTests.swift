import XCTest
@testable import SeedCore

final class GenomeTests: XCTestCase {
    private func seed(_ index: Int) -> SeedID {
        SeedMint.mint(fromEntropy: Data("seed-\(index)".utf8))
    }

    func testGenomeIsAPureFunctionOfItsSeed() {
        let seed = seed(1)
        XCTAssertEqual(Genome(seed: seed), Genome(seed: seed))
    }

    func testDistinctSeedsGrowDistinctPlants() {
        var names = Set<String>()
        var signatures = Set<String>()
        for index in 0..<400 {
            let genome = Genome(seed: seed(index))
            names.insert(genome.name.full)
            signatures.insert("\(genome.form.archetype)-\(genome.bloom.petalCount)-\(Int(genome.palette.petalBase.hue * 360))")
        }
        // Names are drawn from a finite syllable set, so a few collisions in 400
        // are expected; wholesale collapse is not.
        XCTAssertGreaterThan(names.count, 320)
        XCTAssertGreaterThan(signatures.count, 340)
    }

    func testEveryTraitStaysInsideItsDeclaredRange() {
        for index in 0..<500 {
            let genome = Genome(seed: seed(index))
            XCTAssertGreaterThanOrEqual(genome.bloom.petalCount, 3)
            XCTAssertLessThanOrEqual(genome.bloom.petalCount, 40)
            XCTAssertGreaterThanOrEqual(genome.stem.nodeCount, 1)
            XCTAssertLessThanOrEqual(genome.stem.nodeCount, 20)
            XCTAssertTrue((6...9).contains(genome.stem.sides))
            XCTAssertGreaterThan(genome.stem.height, 0.1)
            XCTAssertLessThan(genome.stem.height, 3.0)
            XCTAssertGreaterThan(genome.stem.baseRadius, 0)
            XCTAssertTrue((1...3).contains(genome.bloom.layers))
            XCTAssertTrue((-1.0...1.0).contains(genome.bloom.curl))

            for colour in [genome.palette.petalBase, genome.palette.petalTip,
                           genome.palette.leaf, genome.palette.stem, genome.palette.centre] {
                XCTAssertTrue((0...1).contains(colour.hue), "hue \(colour.hue)")
                XCTAssertTrue((0...1).contains(colour.saturation), "saturation \(colour.saturation)")
                XCTAssertTrue((0...1).contains(colour.brightness), "brightness \(colour.brightness)")
            }

            XCTAssertFalse(genome.name.genus.isEmpty)
            XCTAssertFalse(genome.name.epithet.isEmpty)
        }
    }

    func testEveryArchetypeIsReachable() {
        var seen = Set<Archetype>()
        for index in 0..<600 {
            seen.insert(Genome(seed: seed(index)).form.archetype)
        }
        XCTAssertEqual(seen.count, Archetype.allCases.count)
    }

    func testHybridsMostlyResembleTheirParents() {
        // A cross should read as descended from both plants. Across many
        // crosses, most traits should be recognisably one parent's value.
        let labels = ["stem.height", "bloom.petalCount", "palette.petalHue",
                      "foliage.length", "form.archetype", "bloom.curl"]
        var inheritedCount = 0
        var total = 0

        for index in 0..<200 {
            let parentA = seed(index)
            let parentB = seed(index + 1000)
            let encounter = Pollination.encounterID(
                seedA: parentA,
                seedB: parentB,
                nonceA: Data(repeating: UInt8(index % 256), count: 16),
                nonceB: Data(repeating: 9, count: 16)
            )
            let child = Pollination.cross(seedA: parentA, seedB: parentB, encounterID: encounter)
            let source = GeneSource.hybrid(child: child, parentA: parentA, parentB: parentB)

            for label in labels {
                total += 1
                let value = source.unit(label)
                if value == GeneSource.rawUnit(parentA, label) || value == GeneSource.rawUnit(parentB, label) {
                    inheritedCount += 1
                }
            }
        }

        let ratio = Double(inheritedCount) / Double(total)
        XCTAssertGreaterThan(ratio, 0.6, "hybrids drifted away from their parents (\(ratio))")
        XCTAssertLessThan(ratio, 0.85, "hybrids never surprise anyone (\(ratio))")
    }

    func testHybridLineageIsRecordedInACanonicalOrder() {
        let parentA = seed(3)
        let parentB = seed(4)
        let encounter = Data(repeating: 1, count: 32)
        let child = Pollination.cross(seedA: parentA, seedB: parentB, encounterID: encounter)

        let one = Genome.hybrid(child: child, parentA: parentA, parentB: parentB, encounterID: encounter)
        let two = Genome.hybrid(child: child, parentA: parentB, parentB: parentA, encounterID: encounter)
        XCTAssertEqual(one, two)
        XCTAssertTrue(one.isHybrid)

        guard let parents = one.lineage.parents else { return XCTFail("hybrid lost its parents") }
        XCTAssertTrue(parents.0 < parents.1)
    }
}
