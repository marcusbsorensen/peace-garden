import CryptoKit
import Foundation

/// The sealed return: how a finder tells a sender "your seed was found, and
/// here is my half of the cross" without telling the server, or anyone who
/// holds the pool, anything at all.
///
/// A return is HPKE (RFC 9180) in base mode, sealed to the seed key the sender
/// put beside the space seed. Only the phone that drew that key can open it.
/// The suite is X25519, HKDF-SHA256 and ChaCha20-Poly1305, which is the one
/// CryptoKit calls `Curve25519_SHA256_ChachaPoly`; it is also the suite of the
/// RFC 9180 appendix A.2 test vector that `ZoneCCryptoTests` opens.
///
///     payload  56 bytes   finder's own seed in Zone C (32) ‖ nonce (16) ‖ checksum (8)
///     sealed  104 bytes   HPKE `enc`, a fresh public key (32) ‖ ciphertext (56) ‖ tag (16)
///
/// Sealing is fresh each time: HPKE draws a new ephemeral key for every call,
/// so eight copies of one return share no byte, and the result has the same
/// shape as `ZoneCSlots.returnPadding` (`DESIGN.md` §5.3).
enum ZoneCReturn {
    /// The one cipher suite. Named once so the RFC vector test and the code
    /// that ships cannot drift apart.
    static let ciphersuite = HPKE.Ciphersuite.Curve25519_SHA256_ChachaPoly

    /// The HPKE `info`, before the space seed is appended. Versioned like
    /// `SeedDomain`: a change is a `.v2` beside it, never an edit.
    static let infoDomain = "peacegarden.zonec.back.v1"

    /// What a return carries, in bytes.
    static let payloadLength = 56
    /// The HPKE `enc`: an X25519 public key, the first part of a sealed return.
    static let encapsulatedKeyLength = 32
    /// What a sealed return is, in bytes: the `enc`, the payload and the 16-byte
    /// tag. It is `ZoneCSlots.Slot.back.byteLength`.
    static let sealedLength = encapsulatedKeyLength + payloadLength + 16

    /// The 56 bytes inside a return. The three parts are fixed sizes of random
    /// or hashed bytes, and swapping two of them would still look right, so
    /// they are named and measured once, here.
    struct Payload: Equatable, Sendable {
        /// The finder's own seed in Zone C, the second parent of the cross.
        let ownSeed: Data
        /// The 16 fresh bytes the finder's phone drew at the find.
        let nonce: Data
        /// The cross's checksum, which the sender compares with its own.
        let checksum: Data

        static let ownSeedLength = 32
        static let nonceLength = 16
        static let checksumLength = 8

        /// Nil unless each part is exactly its size.
        init?(ownSeed: Data, nonce: Data, checksum: Data) {
            guard ownSeed.count == Self.ownSeedLength,
                  nonce.count == Self.nonceLength,
                  checksum.count == Self.checksumLength else { return nil }
            self.ownSeed = ownSeed
            self.nonce = nonce
            self.checksum = checksum
        }

        /// Nil unless `bytes` is exactly 56 bytes.
        init?(bytes: Data) {
            guard bytes.count == ZoneCReturn.payloadLength else { return nil }
            // `Data` slices keep their parent's indices, so copy each part.
            let start = bytes.startIndex
            let seedEnd = start + Self.ownSeedLength
            let nonceEnd = seedEnd + Self.nonceLength
            self.init(
                ownSeed: Data(bytes[start..<seedEnd]),
                nonce: Data(bytes[seedEnd..<nonceEnd]),
                checksum: Data(bytes[nonceEnd...])
            )
        }

        var bytes: Data { ownSeed + nonce + checksum }
    }

    enum SealError: Error {
        /// The space seed it answers is not 32 bytes.
        case spaceSeedLength
        /// CryptoKit returned something other than 104 bytes. It should not.
        case sealedLength
    }

    /// Seals `payload` to the seed key of the space seed it answers. Returns the
    /// 104 bytes that go in a `back` slot. Throws if CryptoKit refuses the key
    /// (a row in the pool can carry any 32 bytes) and the caller treats the seed
    /// as not found.
    static func seal(
        _ payload: Payload,
        to seedKey: Curve25519.KeyAgreement.PublicKey,
        spaceSeed: Data
    ) throws -> Data {
        guard spaceSeed.count == ZoneCMark.spaceSeedLength else { throw SealError.spaceSeedLength }
        var sender = try HPKE.Sender(
            recipientKey: seedKey,
            ciphersuite: ciphersuite,
            info: info(for: spaceSeed)
        )
        // No associated data: the space seed is already bound in through `info`.
        let ciphertext = try sender.seal(payload.bytes)
        let sealed = sender.encapsulatedKey + ciphertext
        guard sealed.count == sealedLength else { throw SealError.sealedLength }
        return sealed
    }

    /// Opens one row of a `back` bundle with the private half of a seed key,
    /// for the space seed that key was sent beside. Nil for anything that does
    /// not open: padding, a return for another seed, a return sealed to another
    /// key, a damaged row. Those are not told apart, because the first is the
    /// common case and none is an error.
    ///
    /// This is the call made up to 8 × 128 times at each answer, so it does the
    /// one key agreement and nothing else.
    static func open(
        _ sealed: Data,
        with seedKey: Curve25519.KeyAgreement.PrivateKey,
        spaceSeed: Data
    ) -> Payload? {
        guard sealed.count == sealedLength, spaceSeed.count == ZoneCMark.spaceSeedLength else { return nil }
        // `Data` slices keep their parent's indices, so copy before using them.
        let encapsulatedKey = Data(sealed.prefix(encapsulatedKeyLength))
        let ciphertext = Data(sealed.suffix(sealed.count - encapsulatedKeyLength))
        guard var recipient = try? HPKE.Recipient(
            privateKey: seedKey,
            ciphersuite: ciphersuite,
            info: info(for: spaceSeed),
            encapsulatedKey: encapsulatedKey
        ), let plaintext = try? recipient.open(ciphertext) else { return nil }
        return Payload(bytes: plaintext)
    }

    /// `peacegarden.zonec.back.v1 ‖ space seed`: the context that makes a
    /// return open only for the seed it answers.
    private static func info(for spaceSeed: Data) -> Data {
        Data(infoDomain.utf8) + spaceSeed
    }
}
