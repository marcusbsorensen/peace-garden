import XCTest
@testable import SeedCore

/// Locks the derivation to fixed values.
///
/// Two phones only grow the same hybrid if they agree on every byte of these
/// steps, and a seed already on someone's phone has to keep growing the same
/// plant across every future release. The vectors come from
/// `tools/reference/derivation_reference.py`, an independent implementation in
/// another language — if these two ever disagree, one of them has drifted.
final class DerivationVectorTests: XCTestCase {
    static let entropyA = Data("peace-garden-reference-entropy-A".utf8)
    static let entropyB = Data("peace-garden-reference-entropy-B".utf8)

    static let seedAHex = "2aeeded1dfa5370584314bafb7ad16e4d7cd0382fed1e97fcaf2238c21c84833"
    static let seedBHex = "accf26ec3a93059982076724e1096d5882757f3fc5e6e34c77efc449ec733181"
    static let encounterHex = "e00640bfd64b9e26af2b18435e0b22890389c0ec5d74f3875f0a8d092943def7"
    static let childHex = "6d2169afad6442dcfed740ed3b6468a66eb457830e7c0cc199795bc4f27ae090"
    static let checksumHex = "9d5fb6273529480c"

    static var seedA: SeedID { SeedMint.mint(fromEntropy: entropyA) }
    static var seedB: SeedID { SeedMint.mint(fromEntropy: entropyB) }
    static var nonceA: Data { Data((0..<16).map { UInt8($0) }) }
    static var nonceB: Data { Data((100..<116).map { UInt8($0) }) }

    func testMintedSeedsMatchReference() {
        XCTAssertEqual(Self.seedA.hex, Self.seedAHex)
        XCTAssertEqual(Self.seedB.hex, Self.seedBHex)
    }

    func testEncounterAndCrossMatchReference() {
        let encounter = Pollination.encounterID(
            seedA: Self.seedA,
            seedB: Self.seedB,
            nonceA: Self.nonceA,
            nonceB: Self.nonceB
        )
        XCTAssertEqual(encounter.hexString, Self.encounterHex)

        let child = Pollination.cross(seedA: Self.seedA, seedB: Self.seedB, encounterID: encounter)
        XCTAssertEqual(child.hex, Self.childHex)
        XCTAssertEqual(Pollination.checksum(of: child).hexString, Self.checksumHex)
    }

    func testGeneDrawsMatchReference() {
        let cases: [(String, UInt64, Double)] = [
            ("stem.height", 6_595_262_273_377_147_441, 0.357_529_884_245_359_47),
            ("bloom.petalCount", 8_226_418_299_885_638_431, 0.445_955_029_625_525_91),
            ("palette.petalHue", 11_362_108_213_488_047_308, 0.615_941_120_453_956_66),
            ("form.archetype", 17_548_255_107_286_716_898, 0.951_292_815_532_505_33)
        ]
        for (label, expectedRaw, expectedUnit) in cases {
            XCTAssertEqual(GeneSource.rawUInt64(Self.seedA, label), expectedRaw, label)
            XCTAssertEqual(GeneSource.rawUnit(Self.seedA, label), expectedUnit, accuracy: 1e-15, label)
        }
    }

    func testInheritedDrawsMatchReference() {
        let encounter = Pollination.encounterID(
            seedA: Self.seedA, seedB: Self.seedB, nonceA: Self.nonceA, nonceB: Self.nonceB
        )
        let child = Pollination.cross(seedA: Self.seedA, seedB: Self.seedB, encounterID: encounter)
        let source = GeneSource.hybrid(child: child, parentA: Self.seedA, parentB: Self.seedB)

        let expected: [String: Double] = [
            "stem.height": 0.098_507_388_403_157_869,
            "bloom.petalCount": 0.512_853_369_018_144_6,
            "palette.petalHue": 0.615_941_120_453_956_66,
            "form.archetype": 0.951_292_815_532_505_33
        ]
        for (label, value) in expected {
            XCTAssertEqual(source.unit(label), value, accuracy: 1e-15, label)
        }
    }

    func testDigestIsLengthPrefixed() {
        // Without length prefixes these two would hash identically, and a long
        // display name could be made to collide with a seed.
        let split = seedDigest("test", Data("ab".utf8), Data("c".utf8))
        let joined = seedDigest("test", Data("a".utf8), Data("bc".utf8))
        XCTAssertNotEqual(split, joined)
    }

    func testDigestIsDomainSeparated() {
        let payload = Data("same".utf8)
        XCTAssertNotEqual(seedDigest(SeedDomain.seed, payload), seedDigest(SeedDomain.cross, payload))
    }
}
