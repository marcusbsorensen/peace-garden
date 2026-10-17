import CryptoKit
import XCTest
@testable import PeaceGarden

/// Zone C's cryptography: the mark on a space seed, the two fixed-size slots,
/// and the sealed return.
///
/// Cryptography fails by working. A mark that accepts anything, a slot a byte
/// short, a return that opens for the wrong seed all look like a feature that
/// functions, until the day somebody who knows what to look for looks. So these
/// tests assert the refusals as hard as the successes, and check the pieces
/// against values made somewhere else: an independent HMAC and HPKE written in
/// Python for the marks, and RFC 9180's own appendix for the return.
final class ZoneCCryptoTests: XCTestCase {

    // MARK: - Helpers

    /// Hex to bytes. The loose parser is fine here: these are literals.
    private func bytes(_ hex: String) -> Data {
        var data = Data()
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            data.append(UInt8(hex[index..<next], radix: 16)!)
            index = next
        }
        return data
    }

    private func random(_ count: Int) -> Data {
        var buffer = [UInt8](repeating: 0, count: count)
        XCTAssertEqual(SecRandomCopyBytes(kSecRandomDefault, count, &buffer), errSecSuccess)
        return Data(buffer)
    }

    /// The test K written out again here, so that an edit to `ZoneCKey`'s copy
    /// is caught by `testTheDebugKeyIsTheFixedTestKey` and not followed.
    private var testK: SymmetricKey {
        SymmetricKey(data: bytes("58227a1eab9f1f7f688ab25859d78cf9be11578d06122b74b34c392913cf9e8a"))
    }

    private func isLowercaseHex(_ text: String, length: Int) -> Bool {
        text.utf8.count == length && text.utf8.allSatisfy { ($0 >= 0x30 && $0 <= 0x39) || ($0 >= 0x61 && $0 <= 0x66) }
    }

    private let payload = ZoneCReturn.Payload(
        ownSeed: Data(repeating: 0x11, count: 32),
        nonce: Data(repeating: 0x22, count: 16),
        checksum: Data(repeating: 0x33, count: 8)
    )!

    private func newSpaceSeed() -> Data {
        ZoneCMark.spaceSeed(from: random(16), key: testK)!
    }

    // MARK: - The mark

    /// Three marks made by Python's `hmac` over the same key, domain and `r`,
    /// so the Swift is checked against something that did not come from it.
    /// The domain, the order (domain then `r`) and the truncation are all here.
    func testAMarkIsTheFirstSixteenBytesOfHMACOverTheDomainThenR() {
        let vectors: [(r: String, mark: String)] = [
            ("000102030405060708090a0b0c0d0e0f", "939fc180ccde6a689d4782f1d286460b"),
            ("00000000000000000000000000000000", "d29ac397d1bb19319c114b87b90912a5"),
            ("ffffffffffffffffffffffffffffffff", "28935c5e97992653c02e1c3c82ac25df"),
        ]
        for vector in vectors {
            let r = bytes(vector.r)
            XCTAssertEqual(ZoneCMark.mark(for: r, key: testK), bytes(vector.mark))
            XCTAssertEqual(ZoneCMark.spaceSeed(from: r, key: testK), r + bytes(vector.mark))
        }
    }

    #if DEBUG
    /// Debug builds and tests sign with a fixed K that is in the open. Pinning
    /// what it signs keeps anyone from changing it without meaning to: a
    /// changed K is a new mark, and a seed made before it would be passed over.
    func testTheDebugKeyIsTheFixedTestKey() {
        XCTAssertEqual(ZoneCKey.testBytes.count, ZoneCKey.length)
        XCTAssertEqual(
            ZoneCMark.mark(for: bytes("000102030405060708090a0b0c0d0e0f")),
            bytes("939fc180ccde6a689d4782f1d286460b")
        )
    }
    #endif

    func testASpaceSeedPassesItsOwnMark() {
        for _ in 0..<200 {
            let seed = newSpaceSeed()
            XCTAssertEqual(seed.count, 32)
            XCTAssertTrue(ZoneCMark.isValid(seed, key: testK))
        }
    }

    /// Every one of the 256 bits, in `r` and in the mark alike. A mark that
    /// ignored its last byte, or the first, would pass the ones above.
    func testAnyFlippedBitIsRejected() {
        for _ in 0..<4 {
            let seed = newSpaceSeed()
            for bit in 0..<(seed.count * 8) {
                var damaged = seed
                damaged[bit / 8] ^= 1 << UInt8(bit % 8)
                XCTAssertFalse(ZoneCMark.isValid(damaged, key: testK), "bit \(bit) was accepted")
            }
        }
    }

    /// The point of the mark: pool rows that are padding must not pass. 100,000
    /// random strings at 2⁻¹²⁸ each; one pass would mean the check is broken,
    /// not that the dice were kind.
    func testNoRandom32BytesPassIn100000Tries() {
        let tries = 100_000
        let pool = random(tries * 32)
        let key = testK
        var passes = 0
        for index in 0..<tries {
            let row = pool.subdata(in: index * 32..<(index + 1) * 32)
            if ZoneCMark.isValid(row, key: key) { passes += 1 }
        }
        XCTAssertEqual(passes, 0)
    }

    /// The mark belongs to K. A seed made under another key is padding to this
    /// phone, which is what keeps a Debug build's seeds out of a Release
    /// build's finds, and the reverse.
    func testASeedMadeUnderAnotherKeyIsRejected() {
        let other = SymmetricKey(data: random(32))
        for _ in 0..<50 {
            let seed = ZoneCMark.spaceSeed(from: random(16), key: other)!
            XCTAssertTrue(ZoneCMark.isValid(seed, key: other))
            XCTAssertFalse(ZoneCMark.isValid(seed, key: testK))
        }
    }

    func testAMarkIsOnlyMadeAndCheckedAtTheRightLengths() {
        XCTAssertNil(ZoneCMark.mark(for: random(15), key: testK))
        XCTAssertNil(ZoneCMark.mark(for: random(17), key: testK))
        XCTAssertNil(ZoneCMark.spaceSeed(from: Data(), key: testK))
        let seed = newSpaceSeed()
        XCTAssertFalse(ZoneCMark.isValid(seed.dropLast(), key: testK))
        XCTAssertFalse(ZoneCMark.isValid(seed + [0], key: testK))
        XCTAssertFalse(ZoneCMark.isValid(Data(), key: testK))
    }

    // MARK: - The slots

    private let injectedKey = Curve25519.KeyAgreement.PrivateKey()

    /// 128 and 208 characters of lowercase hex, whether the slot carries
    /// something or nothing. The server refuses anything else with a 400 and
    /// must never see a difference between the two.
    func testEverySlotIsExactlyItsHexLengthRealAndPaddingAlike() throws {
        let seedKey = Curve25519.KeyAgreement.PrivateKey()
        let spaceSeed = newSpaceSeed()
        let sealed = try ZoneCReturn.seal(payload, to: seedKey.publicKey, spaceSeed: spaceSeed)

        let aloft = [
            ZoneCSlots.seedSlot(spaceSeed: spaceSeed, seedKey: seedKey)!,
            ZoneCSlots.seedPadding(),
        ]
        let back = [sealed, ZoneCSlots.returnPadding()]

        for slot in aloft {
            XCTAssertEqual(slot.count, 64)
            let text = try XCTUnwrap(ZoneCSlots.hex(slot, as: .aloft))
            XCTAssertEqual(text.count, 128)
            XCTAssertTrue(isLowercaseHex(text, length: 128))
        }
        for slot in back {
            XCTAssertEqual(slot.count, 104)
            let text = try XCTUnwrap(ZoneCSlots.hex(slot, as: .back))
            XCTAssertEqual(text.count, 208)
            XCTAssertTrue(isLowercaseHex(text, length: 208))
        }
    }

    /// The padding's key half has to be a real public key: that half is
    /// `injectedKey`'s, byte for byte, and the other half is exactly what the
    /// random source gave and nothing else.
    func testSeedPaddingIsRandomBytesThenAPublicKeyDerivedFromAPrivateKey() {
        let key = injectedKey
        let padding = ZoneCSlots.seedPadding(
            keys: { key },
            random: { count in Data(repeating: 0xAB, count: count) }
        )
        XCTAssertEqual(padding.count, 64)
        XCTAssertEqual(padding.prefix(32), Data(repeating: 0xAB, count: 32))
        XCTAssertEqual(padding.suffix(32), key.publicKey.rawRepresentation)
    }

    func testReturnPaddingIsAPublicKeyDerivedFromAPrivateKeyThenRandomBytes() {
        let key = injectedKey
        let padding = ZoneCSlots.returnPadding(
            keys: { key },
            random: { count in Data(repeating: 0xCD, count: count) }
        )
        XCTAssertEqual(padding.count, 104)
        XCTAssertEqual(padding.prefix(32), key.publicKey.rawRepresentation)
        XCTAssertEqual(padding.suffix(72), Data(repeating: 0xCD, count: 72))
    }

    /// A real seed's slot gets its public half from the private key the record
    /// will keep, so a return sealed to it opens with that key.
    func testARealSeedSlotCarriesThePublicHalfOfTheKeyThatOpensItsReturns() throws {
        let seedKey = injectedKey
        let spaceSeed = newSpaceSeed()
        let slot = try XCTUnwrap(ZoneCSlots.seedSlot(spaceSeed: spaceSeed, seedKey: seedKey))
        XCTAssertEqual(slot.prefix(32), spaceSeed)
        XCTAssertEqual(slot.suffix(32), seedKey.publicKey.rawRepresentation)

        // Read the way a finder reads it, then sealed to and opened.
        let found = try XCTUnwrap(ZoneCSlots.splitSeedSlot(slot))
        XCTAssertEqual(found.spaceSeed, spaceSeed)
        XCTAssertTrue(ZoneCMark.isValid(found.spaceSeed, key: testK))
        let sealed = try ZoneCReturn.seal(payload, to: found.seedKey, spaceSeed: found.spaceSeed)
        XCTAssertEqual(ZoneCReturn.open(sealed, with: seedKey, spaceSeed: spaceSeed), payload)

        XCTAssertNil(ZoneCSlots.seedSlot(spaceSeed: spaceSeed.dropLast(), seedKey: seedKey))
        XCTAssertNil(ZoneCSlots.splitSeedSlot(slot.dropLast()))
        XCTAssertNil(ZoneCSlots.splitSeedSlot(slot + [0]))
    }

    /// Why padding carries real keys: a key's top bit (of its last byte) is
    /// always clear, and random bytes have it set half the time. If padding were
    /// random, that bit alone would sort the pool. The control says the check
    /// can tell the two apart; the rest says nothing here can be told from a key.
    func testPaddingHasTheShapeOfARealKeyAndRandomBytesDoNot() throws {
        func topBitSet(_ byte: UInt8) -> Bool { byte & 0x80 != 0 }

        var randomWithBitSet = 0
        for _ in 0..<2_000 where topBitSet(random(32).last!) { randomWithBitSet += 1 }
        XCTAssertGreaterThan(randomWithBitSet, 800, "the control no longer separates random bytes from keys")

        let seedKey = Curve25519.KeyAgreement.PrivateKey()
        let spaceSeed = newSpaceSeed()
        for _ in 0..<2_000 {
            XCTAssertFalse(topBitSet(ZoneCSlots.seedPadding().last!))
            XCTAssertFalse(topBitSet(ZoneCSlots.returnPadding()[31]))
        }
        for _ in 0..<200 {
            // A real return's first half is HPKE's ephemeral key: same shape.
            let sealed = try ZoneCReturn.seal(payload, to: seedKey.publicKey, spaceSeed: spaceSeed)
            XCTAssertFalse(topBitSet(sealed[31]))
            XCTAssertFalse(topBitSet(ZoneCSlots.seedSlot(spaceSeed: spaceSeed, seedKey: seedKey)!.last!))
        }
    }

    func testTwoPaddingsDiffer() {
        XCTAssertNotEqual(ZoneCSlots.seedPadding(), ZoneCSlots.seedPadding())
        XCTAssertNotEqual(ZoneCSlots.returnPadding(), ZoneCSlots.returnPadding())
    }

    /// Hex goes out as the server expects it and comes back under the same rule:
    /// lowercase only, the exact length, no sign, no space.
    func testHexRoundTripsAndRefusesAnythingLoose() throws {
        let aloft = ZoneCSlots.seedPadding()
        let back = ZoneCSlots.returnPadding()
        let aloftText = try XCTUnwrap(ZoneCSlots.hex(aloft, as: .aloft))
        let backText = try XCTUnwrap(ZoneCSlots.hex(back, as: .back))
        XCTAssertEqual(ZoneCSlots.bytes(fromHex: aloftText, as: .aloft), aloft)
        XCTAssertEqual(ZoneCSlots.bytes(fromHex: backText, as: .back), back)

        // Wrong byte length in: nil. Wrong slot for the text: nil.
        XCTAssertNil(ZoneCSlots.hex(aloft, as: .back))
        XCTAssertNil(ZoneCSlots.hex(aloft.dropLast(), as: .aloft))
        XCTAssertNil(ZoneCSlots.bytes(fromHex: aloftText, as: .back))
        XCTAssertNil(ZoneCSlots.bytes(fromHex: String(aloftText.dropLast()), as: .aloft))
        XCTAssertNil(ZoneCSlots.bytes(fromHex: aloftText + "0", as: .aloft))

        // Loose: uppercase, a sign, a space, a multi-byte character, in a
        // string that is otherwise the right length.
        XCTAssertNil(ZoneCSlots.bytes(fromHex: aloftText.uppercased(), as: .aloft), "uppercase")
        for loose in ["+f", "-0", " 0", "0x", "g0", "é"] {
            let text = loose + String(aloftText.dropFirst(loose.utf8.count))
            XCTAssertNil(ZoneCSlots.bytes(fromHex: text, as: .aloft), "accepted \(loose)")
        }
    }

    // MARK: - The return

    func testAReturnSeals56BytesInto104() throws {
        XCTAssertEqual(payload.bytes.count, 56)
        let seedKey = Curve25519.KeyAgreement.PrivateKey()
        let spaceSeed = newSpaceSeed()
        let sealed = try ZoneCReturn.seal(payload, to: seedKey.publicKey, spaceSeed: spaceSeed)
        XCTAssertEqual(sealed.count, 104)
        XCTAssertEqual(ZoneCReturn.open(sealed, with: seedKey, spaceSeed: spaceSeed), payload)
    }

    /// The payload's three parts keep their sizes and their order.
    func testThePayloadIsOwnSeedThenNonceThenChecksum() {
        XCTAssertEqual(payload.bytes.prefix(32), payload.ownSeed)
        XCTAssertEqual(payload.bytes.dropFirst(32).prefix(16), payload.nonce)
        XCTAssertEqual(payload.bytes.suffix(8), payload.checksum)
        XCTAssertEqual(ZoneCReturn.Payload(bytes: payload.bytes), payload)
        XCTAssertNil(ZoneCReturn.Payload(bytes: payload.bytes.dropLast()))
        XCTAssertNil(ZoneCReturn.Payload(bytes: payload.bytes + [0]))
        XCTAssertNil(ZoneCReturn.Payload(ownSeed: Data(count: 31), nonce: payload.nonce, checksum: payload.checksum))
        XCTAssertNil(ZoneCReturn.Payload(ownSeed: payload.ownSeed, nonce: Data(count: 17), checksum: payload.checksum))
        XCTAssertNil(ZoneCReturn.Payload(ownSeed: payload.ownSeed, nonce: payload.nonce, checksum: Data(count: 9)))
    }

    /// Opens with the sender's private key and the space seed it answers, and
    /// with nothing else: not another key, not another seed, not a seed one
    /// bit away.
    func testAReturnOpensOnlyWithTheRightPrivateKeyAndTheRightSpaceSeed() throws {
        let seedKey = Curve25519.KeyAgreement.PrivateKey()
        let spaceSeed = newSpaceSeed()
        let sealed = try ZoneCReturn.seal(payload, to: seedKey.publicKey, spaceSeed: spaceSeed)

        XCTAssertEqual(ZoneCReturn.open(sealed, with: seedKey, spaceSeed: spaceSeed), payload)
        XCTAssertNil(ZoneCReturn.open(sealed, with: Curve25519.KeyAgreement.PrivateKey(), spaceSeed: spaceSeed))
        XCTAssertNil(ZoneCReturn.open(sealed, with: seedKey, spaceSeed: newSpaceSeed()))
        for bit in 0..<(spaceSeed.count * 8) {
            var nearby = spaceSeed
            nearby[bit / 8] ^= 1 << UInt8(bit % 8)
            XCTAssertNil(ZoneCReturn.open(sealed, with: seedKey, spaceSeed: nearby), "opened for a seed with bit \(bit) flipped")
        }
    }

    /// Sealed afresh each time, so the eight copies a finder sends share no
    /// byte for anyone to match them by, and every one still opens.
    func testTwoSealsOfOnePayloadDiffer() throws {
        let seedKey = Curve25519.KeyAgreement.PrivateKey()
        let spaceSeed = newSpaceSeed()
        let first = try ZoneCReturn.seal(payload, to: seedKey.publicKey, spaceSeed: spaceSeed)
        let second = try ZoneCReturn.seal(payload, to: seedKey.publicKey, spaceSeed: spaceSeed)

        XCTAssertNotEqual(first, second)
        XCTAssertNotEqual(first.prefix(32), second.prefix(32), "the same ephemeral key was used twice")
        XCTAssertNotEqual(first.suffix(72), second.suffix(72))
        XCTAssertEqual(ZoneCReturn.open(first, with: seedKey, spaceSeed: spaceSeed), payload)
        XCTAssertEqual(ZoneCReturn.open(second, with: seedKey, spaceSeed: spaceSeed), payload)
    }

    /// One bit changed anywhere in the 104 bytes, in the key half or the
    /// ciphertext or the tag, and nothing opens.
    func testADamagedReturnDoesNotOpen() throws {
        let seedKey = Curve25519.KeyAgreement.PrivateKey()
        let spaceSeed = newSpaceSeed()
        let sealed = try ZoneCReturn.seal(payload, to: seedKey.publicKey, spaceSeed: spaceSeed)
        for index in 0..<sealed.count {
            var damaged = sealed
            damaged[index] ^= 0x01
            XCTAssertNil(ZoneCReturn.open(damaged, with: seedKey, spaceSeed: spaceSeed), "byte \(index) was not checked")
        }
        XCTAssertNil(ZoneCReturn.open(sealed.dropLast(), with: seedKey, spaceSeed: spaceSeed))
        XCTAssertNil(ZoneCReturn.open(sealed + [0], with: seedKey, spaceSeed: spaceSeed))
        XCTAssertNil(ZoneCReturn.open(sealed, with: seedKey, spaceSeed: spaceSeed.dropLast()))
    }

    /// Most rows in a bundle are padding, and padding must open to nothing.
    func testReturnPaddingNeverOpens() {
        let seedKey = Curve25519.KeyAgreement.PrivateKey()
        let spaceSeed = newSpaceSeed()
        for _ in 0..<300 {
            XCTAssertNil(ZoneCReturn.open(ZoneCSlots.returnPadding(), with: seedKey, spaceSeed: spaceSeed))
        }
    }

    /// A pool row can hold any 32 bytes where a seed key should be. Sealing to
    /// the all-zero key, which is no key at all, must come back as an error to
    /// be dropped, not as a return that anyone could open.
    func testSealingToAKeyThatIsNoKeyThrows() throws {
        let zero = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: Data(count: 32))
        XCTAssertThrowsError(try ZoneCReturn.seal(payload, to: zero, spaceSeed: newSpaceSeed()))
        XCTAssertThrowsError(
            try ZoneCReturn.seal(payload, to: injectedKey.publicKey, spaceSeed: Data(count: 31))
        )
    }

    /// **Every weak public key, not only zero.** `splitSeedSlot` takes any 32
    /// bytes as a seed key and CryptoKit does not check that a point is a good
    /// one. What protects a finder is that sealing to a low-order point fails
    /// because the shared secret is all zero (RFC 9180 section 7.1.4, RFC 7748
    /// section 6.1); had it sealed, the secret would be known to everyone and
    /// the finder's own seed readable by anyone holding the pool (A2 review,
    /// finding 4). So the whole blocklist is walked, each with the top bit of
    /// the last byte set as well (RFC 7748 masks it): 0 and 1, the two points
    /// of order 8, and p - 1, p and p + 1, which are the same classes written
    /// non-canonically. All fourteen were checked to be refused by an
    /// independent X25519 (OpenSSL) before they were listed.
    func testSealingToAnyWeakPublicKeyThrows() throws {
        func little(_ lowest: UInt8, fill: UInt8 = 0, last: UInt8 = 0) -> Data {
            Data([lowest] + [UInt8](repeating: fill, count: 30) + [last])
        }
        let weakKeys: [(name: String, key: Data)] = [
            ("0", little(0x00)),
            ("1", little(0x01)),
            ("order 8, first", bytes("e0eb7a7c3b41b8ae1656e3faf19fc46ada098deb9c32b1fd866205165f49b800")),
            ("order 8, second", bytes("5f9c95bca3508c24b1d0b1559c83ef5b04445cc4581c8e86d8224eddd09f1157")),
            ("p - 1", little(0xec, fill: 0xff, last: 0x7f)),
            ("p", little(0xed, fill: 0xff, last: 0x7f)),
            ("p + 1", little(0xee, fill: 0xff, last: 0x7f)),
        ]

        // The control: a good key seals, so a loop of throws is not a seal that
        // always fails.
        let good = Curve25519.KeyAgreement.PrivateKey()
        XCTAssertNoThrow(try ZoneCReturn.seal(payload, to: good.publicKey, spaceSeed: newSpaceSeed()))

        for (name, key) in weakKeys {
            for topBitSet in [false, true] {
                var bytes = key
                if topBitSet { bytes[31] |= 0x80 }
                let weakKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: bytes)
                XCTAssertThrowsError(
                    try ZoneCReturn.seal(payload, to: weakKey, spaceSeed: newSpaceSeed()),
                    "sealed to the weak key \(name)\(topBitSet ? " with the top bit set" : "")"
                )
            }
        }
    }

    /// RFC 9180 appendix A.2.1: DHKEM(X25519, HKDF-SHA256), HKDF-SHA256,
    /// ChaCha20-Poly1305, base mode. The RFC's own ciphertexts, opened through
    /// the same `ciphersuite` constant the app seals with. CryptoKit cannot
    /// seal with a chosen ephemeral key, so this is the half that can be checked
    /// against a published value: the key agreement, the key schedule and the
    /// AEAD, in that order, and the nonce counting up for the second message.
    /// (Both were also re-derived in an independent Python implementation of
    /// the RFC from the vector's `ikmE` and `ikmR`.)
    func testRFC9180AppendixA2CiphertextOpensWithThisSuite() throws {
        let skRm = try Curve25519.KeyAgreement.PrivateKey(
            rawRepresentation: bytes("8057991eef8f1f1af18f4a9491d16a1ce333f695d4db8e38da75975c4478e0fb")
        )
        XCTAssertEqual(
            skRm.publicKey.rawRepresentation,
            bytes("4310ee97d88cc1f088a5576c77ab0cf5c3ac797f3d95139c6c84b5429c59662a"),
            "pkRm"
        )

        var recipient = try HPKE.Recipient(
            privateKey: skRm,
            ciphersuite: ZoneCReturn.ciphersuite,
            info: bytes("4f6465206f6e2061204772656369616e2055726e"),  // "Ode on a Grecian Urn"
            encapsulatedKey: bytes("1afa08d3dec047a643885163f1180476fa7ddb54c6a8029ea33f95796bf2ac4a")
        )
        let plaintext = bytes("4265617574792069732074727574682c20747275746820626561757479")  // "Beauty is truth, truth beauty"

        let sequence0 = try recipient.open(
            bytes("1c5250d8034ec2b784ba2cfd69dbdb8af406cfe3ff938e131f0def8c8b60b4db21993c62ce81883d2dd1b51a28"),
            authenticating: bytes("436f756e742d30")  // "Count-0"
        )
        XCTAssertEqual(sequence0, plaintext)

        let sequence1 = try recipient.open(
            bytes("6b53c051e4199c518de79594e1c4ab18b96f081549d45ce015be002090bb119e85285337cc95ba5f59992dc98c"),
            authenticating: bytes("436f756e742d31")  // "Count-1"
        )
        XCTAssertEqual(sequence1, plaintext)
    }

    /// **A return sealed outside the app, in the app's own framing.** The RFC
    /// vector above pins the suite, the key schedule and the AEAD, but not what
    /// Zone C puts around them: the info string (`peacegarden.zonec.back.v1`
    /// then the space seed, in that order, with nothing between) and the 56-byte
    /// payload. Every other return test seals and opens through the same
    /// `info(for:)`, so a reordered info string would pass them all while
    /// returns from the old build and the new build stopped opening for each
    /// other. This one was made by a hand-written RFC 9180 key schedule in
    /// Python (A2 review, finding 3), which also opens both of the RFC's own
    /// ciphertexts, and is opened here by the real `ZoneCReturn.open`.
    ///
    /// Inputs: the recipient's private key is SHA-256 of
    /// `peacegarden.zonec.test-seed-key.v1`; the ephemeral key was SHA-256 of
    /// `peacegarden.zonec.test-ephemeral.v1`; the space seed is `r` then its
    /// mark under the test K (the first vector in `testAMarkIs...`); no
    /// associated data. Both keys come from public labels and guard nothing.
    func testAReturnMadeOutsideTheAppOpensSoTheFramingIsPinned() throws {
        let seedKey = try Curve25519.KeyAgreement.PrivateKey(
            rawRepresentation: Data(SHA256.hash(data: Data("peacegarden.zonec.test-seed-key.v1".utf8)))
        )
        let spaceSeed = try XCTUnwrap(ZoneCMark.spaceSeed(from: bytes("000102030405060708090a0b0c0d0e0f"), key: testK))
        XCTAssertEqual(spaceSeed, bytes("000102030405060708090a0b0c0d0e0f939fc180ccde6a689d4782f1d286460b"))
        XCTAssertEqual(payload.bytes, Data(repeating: 0x11, count: 32) + Data(repeating: 0x22, count: 16)
                       + Data(repeating: 0x33, count: 8), "the payload the vector was made from")

        let sealed = bytes(
            "b92453afc2b9a737652487217cfedcf522e4675314e137c8cf040b70aa18ec70"
            + "3d8e3bffb6e68de987748cc0c4f53686bdca2ef8751a75f919dc770ac81fb4d2"
            + "cf84a9d5328217f32d85616cb190434713f2130c7f6c490ed0cff1f87c4f24bd"
            + "2460b60ebd2ba9c2"
        )
        XCTAssertEqual(sealed.count, 104)
        XCTAssertEqual(ZoneCReturn.open(sealed, with: seedKey, spaceSeed: spaceSeed), payload)

        // And it is the framing that opens it: the same bytes under the space
        // seed's halves swapped, or with nothing but the mark, are no return.
        let swapped = spaceSeed.suffix(16) + spaceSeed.prefix(16)
        XCTAssertNil(ZoneCReturn.open(sealed, with: seedKey, spaceSeed: swapped))
    }

    // MARK: - Cost

    /// 8 records, 128 rows, one genuine return among the padding, and a pass
    /// that tries every record's key on every row, as a sender does at each
    /// answer.
    private func openingFixture() throws -> (rows: Int, pass: () -> (milliseconds: Double, opened: [ZoneCReturn.Payload])) {
        let records = 8
        let rowCount = 128
        let keys = (0..<records).map { _ in Curve25519.KeyAgreement.PrivateKey() }
        let spaceSeeds = (0..<records).map { _ in newSpaceSeed() }

        // One genuine return among the padding, for record 5 at row 77.
        var rows = (0..<rowCount).map { _ in ZoneCSlots.returnPadding() }
        rows[77] = try ZoneCReturn.seal(payload, to: keys[5].publicKey, spaceSeed: spaceSeeds[5])
        let all = rows

        return (records * rowCount, {
            var opened: [ZoneCReturn.Payload] = []
            let start = DispatchTime.now().uptimeNanoseconds
            for record in 0..<records {
                for row in all {
                    if let found = ZoneCReturn.open(row, with: keys[record], spaceSeed: spaceSeeds[record]) {
                        opened.append(found)
                    }
                }
            }
            let elapsed = DispatchTime.now().uptimeNanoseconds - start
            return (Double(elapsed) / 1_000_000, opened)
        })
    }

    /// A sender tries each live record's key on every row of the answer: at
    /// most 8 records × 128 rows, one key agreement apiece (`DESIGN.md` §5).
    /// About 90 ms on a Mac, a few hundred on the oldest phone the app runs on,
    /// off the main thread.
    ///
    /// **The bound is 300 ms, and it is there for an order of magnitude**, not
    /// for the last 10%: a key generated for every row, or the work done on the
    /// main thread, would show here at a second or more. It used to be 100 ms,
    /// which a parallel build, Spotlight or a warm laptop could break with the
    /// code unchanged (A2 review, finding 1). The real figure is tracked by
    /// `testTheCostOfTheOpeningsIsMeasured`.
    ///
    /// Best of five passes after one unmeasured, because this runs on a shared
    /// Mac and a pass that lost its core says nothing about the code. The
    /// pass-by-pass times are printed.
    func testAThousandAndTwentyFourOpeningsTakeUnderThreeHundredMilliseconds() throws {
        let fixture = try openingFixture()
        XCTAssertEqual(fixture.rows, 1_024)

        _ = fixture.pass()
        var times: [Double] = []
        for _ in 0..<5 {
            let result = fixture.pass()
            XCTAssertEqual(result.opened, [payload], "exactly the one genuine return opens")
            times.append(result.milliseconds)
        }
        let best = times.min()!
        print("ZoneC 1,024 openings, ms per pass:", times.map { String(format: "%.1f", $0) }.joined(separator: ", "),
              "| best:", String(format: "%.1f", best))
        XCTAssertLessThan(best, 300, "1,024 openings took \(best) ms at best")
    }

    /// The real figure, kept where it can be read and compared: Xcode's own
    /// measurement of the same pass, with the clock as its metric. It asserts
    /// nothing, since a baseline stored in the project would not survive
    /// `xcodegen generate` and one that failed under load would be the flake
    /// finding 1 removed. `xcodebuild` prints each run's average
    /// ("Clock Monotonic Time") in the test log, and the result bundle keeps
    /// them; compare those across builds and across machines.
    func testTheCostOfTheOpeningsIsMeasured() throws {
        let fixture = try openingFixture()
        _ = fixture.pass()
        measure(metrics: [XCTClockMetric()]) {
            _ = fixture.pass()
        }
    }
}
