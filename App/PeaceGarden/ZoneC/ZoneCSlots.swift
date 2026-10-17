import CryptoKit
import Foundation

/// The two fixed-size slots every launch request carries, `aloft` and `back`,
/// and the padding that stands in for them when there is nothing to send.
///
/// The server stores whatever arrives and cannot tell one row from another, so
/// the guarantee lives here: a request that carries a space seed and one that
/// carries padding must be the same length, in the same alphabet, with the same
/// shape in every byte a server can look at (`DESIGN.md` §4.2).
///
///     aloft  64 bytes   space seed `r ‖ mark` (32)  ‖  seed key, public half (32)
///     back  104 bytes   sealed return: HPKE `enc` (32) ‖ ciphertext and tag (72)
///
/// Padding is built from the same parts as the real thing:
///
///     aloft padding   32 fresh random bytes  ‖  public half of a key pair drawn and thrown away
///     back  padding   public half of a key pair drawn and thrown away  ‖  72 fresh random bytes
///
/// Random bytes would not do for the key halves. An X25519 public key is a
/// field element below 2²⁵⁵ − 19, so the top bit of its last byte is always
/// clear, and 32 uniformly random bytes have it set half the time. A pool in
/// which one kind of row has that bit and the other does not would sort itself
/// for anyone who looked. In the real `back` slot the first 32 bytes are the
/// HPKE ephemeral public key, so they have the same shape for the same reason.
enum ZoneCSlots {
    /// The two slots, named as the fields are on the wire.
    enum Slot {
        case aloft
        case back

        /// What the slot holds, in bytes.
        var byteLength: Int {
            switch self {
            case .aloft: return 64
            case .back: return 104
            }
        }

        /// What the slot is on the wire: lowercase hex, two characters a byte.
        var hexLength: Int { byteLength * 2 }
    }

    /// A source of key pairs. Injected so a test can say which private key a
    /// slot's public half must come from; the default draws a fresh one.
    typealias KeyGenerator = @Sendable () -> Curve25519.KeyAgreement.PrivateKey
    /// A source of random bytes, injected for the same reason.
    typealias RandomBytes = @Sendable (Int) -> Data

    static let freshKey: KeyGenerator = { Curve25519.KeyAgreement.PrivateKey() }

    /// The system's random source, which on Apple platforms is the kernel's.
    static let systemRandom: RandomBytes = { count in
        var generator = SystemRandomNumberGenerator()
        return Data((0..<count).map { _ in UInt8.random(in: .min ... .max, using: &generator) })
    }

    // MARK: - Building slots

    /// The `aloft` slot for a space seed this phone is carrying: the 32-byte
    /// space seed, then the public half of `seedKey`. Nil unless `spaceSeed` is
    /// 32 bytes. The public half is derived here from the private key the
    /// record will keep, so the two cannot disagree.
    static func seedSlot(spaceSeed: Data, seedKey: Curve25519.KeyAgreement.PrivateKey) -> Data? {
        guard spaceSeed.count == ZoneCMark.spaceSeedLength else { return nil }
        return spaceSeed + seedKey.publicKey.rawRepresentation
    }

    /// An `aloft` slot with nothing in it.
    static func seedPadding(
        keys: KeyGenerator = freshKey,
        random: RandomBytes = systemRandom
    ) -> Data {
        let body = exactly(ZoneCMark.spaceSeedLength, from: random)
        return body + keys().publicKey.rawRepresentation
    }

    /// A `back` slot with nothing in it. A real one is the 104 bytes
    /// `ZoneCReturn.seal` returns, which needs no building here.
    static func returnPadding(
        keys: KeyGenerator = freshKey,
        random: RandomBytes = systemRandom
    ) -> Data {
        let publicHalf = keys().publicKey.rawRepresentation
        return publicHalf + exactly(Slot.back.byteLength - publicHalf.count, from: random)
    }

    // MARK: - Reading a seed row

    /// The two halves of an `aloft` row from a bundle: the space seed, whose
    /// mark the caller still has to check, and the seed key to seal a return
    /// to. Nil unless the row is 64 bytes and its second half can be a key.
    static func splitSeedSlot(_ row: Data) -> (spaceSeed: Data, seedKey: Curve25519.KeyAgreement.PublicKey)? {
        guard row.count == Slot.aloft.byteLength else { return nil }
        // `Data` slices keep their parent's indices, so copy before using them.
        let spaceSeed = Data(row.prefix(ZoneCMark.spaceSeedLength))
        let keyBytes = Data(row.suffix(row.count - ZoneCMark.spaceSeedLength))
        guard let seedKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: keyBytes) else { return nil }
        return (spaceSeed, seedKey)
    }

    // MARK: - Hex

    /// A slot as the request carries it: lowercase hex, exactly 128 characters
    /// for `aloft` and 208 for `back`. Nil if the bytes are the wrong length.
    static func hex(_ bytes: Data, as slot: Slot) -> String? {
        guard bytes.count == slot.byteLength else { return nil }
        let digits = Array("0123456789abcdef".utf8)
        var text: [UInt8] = []
        text.reserveCapacity(bytes.count * 2)
        for byte in bytes {
            text.append(digits[Int(byte >> 4)])
            text.append(digits[Int(byte & 0x0f)])
        }
        return String(decoding: text, as: UTF8.self)
    }

    /// The bytes of a slot read back from hex, held to the server's own rule:
    /// the exact length, lowercase only. Nil otherwise. (`Data(hexString:)` in
    /// SeedCore is more forgiving, and accepts a sign in front of a digit.)
    static func bytes(fromHex text: String, as slot: Slot) -> Data? {
        let characters = Array(text.utf8)
        guard characters.count == slot.hexLength else { return nil }
        var bytes = Data()
        bytes.reserveCapacity(slot.byteLength)
        var index = 0
        while index < characters.count {
            guard let high = nibble(characters[index]), let low = nibble(characters[index + 1]) else { return nil }
            bytes.append(high << 4 | low)
            index += 2
        }
        return bytes
    }

    private static func nibble(_ character: UInt8) -> UInt8? {
        switch character {
        case UInt8(ascii: "0")...UInt8(ascii: "9"): return character - UInt8(ascii: "0")
        case UInt8(ascii: "a")...UInt8(ascii: "f"): return character - UInt8(ascii: "a") + 10
        default: return nil
        }
    }

    /// Bytes from an injected source, held to the count asked for: a short
    /// read would otherwise make a slot the wrong size, which is the one thing
    /// the server may never see.
    private static func exactly(_ count: Int, from random: RandomBytes) -> Data {
        let bytes = random(count)
        precondition(bytes.count == count, "the random source returned \(bytes.count) bytes, not \(count)")
        return bytes
    }
}
