import CryptoKit
import Foundation

/// The mark that makes 16 random bytes a space seed.
///
/// Autonaut draws `r`, 16 random bytes, and knows nothing else. Peace Garden
/// completes it into the 32-byte space seed `r ‖ mark` before it goes up in the
/// `aloft` slot, and checks the mark on every seed that comes down in a bundle.
/// A pool row that passes was made by a Peace Garden holding K; one that fails
/// is padding, or a stranger's guess. The server holds no K, so for the server
/// the two look the same.
///
/// The mark is 16 bytes, so a row of random bytes passes with probability
/// 2⁻¹²⁸: never, in any number of tries that could be made.
enum ZoneCMark {
    /// Domain-separates this HMAC from any other use of K, in the manner of
    /// `SeedDomain`. Versioned: a change is a `.v2` beside this, never an edit,
    /// because seeds already in the pool carry marks made under this one.
    static let domain = "peacegarden.zonec.mark.v1"

    /// `r`: what Autonaut draws.
    static let randomLength = 16
    /// What follows `r` in a space seed.
    static let markLength = 16
    /// `r ‖ mark`.
    static let spaceSeedLength = randomLength + markLength

    /// The first 16 bytes of HMAC-SHA256(K, `peacegarden.zonec.mark.v1` ‖ r),
    /// or nil unless `r` is exactly 16 bytes. The domain is a fixed string and
    /// `r` a fixed length, so no length prefix is needed to keep the input
    /// unambiguous.
    static func mark(for r: Data, key: SymmetricKey = ZoneCKey.mark) -> Data? {
        guard r.count == randomLength else { return nil }
        let code = HMAC<SHA256>.authenticationCode(for: Data(domain.utf8) + r, using: key)
        return Data(code.prefix(markLength))
    }

    /// `r ‖ mark`, the space seed Peace Garden sends for the `r` Autonaut drew.
    /// Nil unless `r` is exactly 16 bytes.
    static func spaceSeed(from r: Data, key: SymmetricKey = ZoneCKey.mark) -> Data? {
        guard let mark = mark(for: r, key: key) else { return nil }
        return r + mark
    }

    /// Whether these 32 bytes are `r` followed by the mark K gives that `r`.
    static func isValid(_ spaceSeed: Data, key: SymmetricKey = ZoneCKey.mark) -> Bool {
        guard spaceSeed.count == spaceSeedLength else { return false }
        // `Data` slices keep their parent's indices, so copy before using them.
        let r = Data(spaceSeed.prefix(randomLength))
        let claimed = Data(spaceSeed.suffix(markLength))
        guard let expected = mark(for: r, key: key) else { return false }
        return constantTimeEqual(expected, claimed)
    }

    /// The comparison that does not stop at the first differing byte. Nothing
    /// here is remote, so this is a habit rather than a defence: a mark is
    /// checked on this phone, against rows anybody could have written.
    private static func constantTimeEqual(_ a: Data, _ b: Data) -> Bool {
        guard a.count == b.count else { return false }
        var difference: UInt8 = 0
        for (x, y) in zip(a, b) { difference |= x ^ y }
        return difference == 0
    }
}
