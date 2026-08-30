import XCTest
@testable import SeedCore

final class PollinationTests: XCTestCase {
    private func seed(_ label: String) -> SeedID {
        SeedMint.mint(fromEntropy: Data(label.utf8))
    }

    func testCrossIsCommutative() {
        // Neither phone knows which of them "started" the exchange, so the
        // result must not depend on the order the seeds are handed in.
        let a = seed("a")
        let b = seed("b")
        let nonceA = Data(repeating: 7, count: 16)
        let nonceB = Data(repeating: 200, count: 16)

        let one = Pollination.encounterID(seedA: a, seedB: b, nonceA: nonceA, nonceB: nonceB)
        let two = Pollination.encounterID(seedA: b, seedB: a, nonceA: nonceB, nonceB: nonceA)
        XCTAssertEqual(one, two)

        XCTAssertEqual(
            Pollination.cross(seedA: a, seedB: b, encounterID: one),
            Pollination.cross(seedA: b, seedB: a, encounterID: two)
        )
    }

    func testEachEncounterGrowsADifferentPlant() {
        // Meeting the same person again should not hand back the same plant.
        let a = seed("a")
        let b = seed("b")
        var children = Set<SeedID>()
        for index in 0..<250 {
            let encounter = Pollination.encounterID(
                seedA: a,
                seedB: b,
                nonceA: Data(repeating: UInt8(index), count: 16),
                nonceB: Data(repeating: 3, count: 16)
            )
            children.insert(Pollination.cross(seedA: a, seedB: b, encounterID: encounter))
        }
        XCTAssertEqual(children.count, 250)
    }

    func testBothSidesOfAnExchangeAgree() {
        // Simulates the two phones running the protocol independently: each one
        // only ever sees its own seed and nonce plus the other's.
        let mine = seed("mine")
        let theirs = seed("theirs")
        let myNonce = Pollination.makeNonce()
        let theirNonce = Pollination.makeNonce()

        let onMyPhone = CrossPollinationResult(
            localSeed: mine, remoteSeed: theirs, localNonce: myNonce, remoteNonce: theirNonce
        )
        let onTheirPhone = CrossPollinationResult(
            localSeed: theirs, remoteSeed: mine, localNonce: theirNonce, remoteNonce: myNonce
        )

        XCTAssertEqual(onMyPhone.childSeed, onTheirPhone.childSeed)
        XCTAssertEqual(onMyPhone.checksum, onTheirPhone.checksum)
        XCTAssertEqual(onMyPhone.genome, onTheirPhone.genome)
        XCTAssertEqual(onMyPhone.genome.name.full, onTheirPhone.genome.name.full)
    }

    func testChecksumCatchesAMismatch() {
        let a = seed("a")
        let b = seed("b")
        let c = seed("c")
        let encounter = Pollination.encounterID(
            seedA: a, seedB: b, nonceA: Data(repeating: 1, count: 16), nonceB: Data(repeating: 2, count: 16)
        )
        let expected = Pollination.checksum(of: Pollination.cross(seedA: a, seedB: b, encounterID: encounter))
        let wrong = Pollination.checksum(of: Pollination.cross(seedA: a, seedB: c, encounterID: encounter))
        XCTAssertNotEqual(expected, wrong)
        XCTAssertEqual(expected.count, 8)
    }

    func testSeedOrderingIsUnsignedAndLexicographic() {
        // Byte 0x80 must sort above 0x01, not below it as a signed compare would.
        let low = SeedID(bytes: Data([0x01] + [UInt8](repeating: 0xFF, count: 31)))!
        let high = SeedID(bytes: Data([0x80] + [UInt8](repeating: 0x00, count: 31)))!
        XCTAssertTrue(low < high)
        XCTAssertFalse(high < low)
        XCTAssertFalse(low < low)
    }

    func testNonceIsTheRequiredLength() {
        XCTAssertEqual(Pollination.makeNonce().count, ExchangeProtocol.nonceByteCount)
        XCTAssertNotEqual(Pollination.makeNonce(), Pollination.makeNonce())
    }
}
