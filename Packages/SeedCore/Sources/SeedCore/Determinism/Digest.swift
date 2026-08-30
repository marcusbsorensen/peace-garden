import Foundation
import CryptoKit

/// Domain tags for every derivation in the system.
///
/// Each tag is versioned. Changing a derivation means adding a `.v2` tag, never
/// editing a `.v1` one: seeds already minted on people's phones must keep
/// growing the same plant forever.
public enum SeedDomain {
    public static let seed = "peacegarden.seed.v1"
    public static let encounter = "peacegarden.encounter.v1"
    public static let cross = "peacegarden.cross.v1"
    public static let trait = "peacegarden.trait.v1"
    public static let checksum = "peacegarden.checksum.v1"
}

/// SHA-256 over a domain tag followed by length-prefixed parts.
///
/// The length prefix matters: without it `digest(a, b)` and `digest(a + b, "")`
/// would collide, and a crafted display name could impersonate a seed.
public func seedDigest(_ domain: String, _ parts: [Data]) -> Data {
    var hasher = SHA256()
    hasher.update(data: Data(domain.utf8))
    hasher.update(data: Data([0]))
    for part in parts {
        hasher.update(data: Data(bigEndian: UInt32(part.count)))
        hasher.update(data: part)
    }
    return Data(hasher.finalize())
}

public func seedDigest(_ domain: String, _ parts: Data...) -> Data {
    seedDigest(domain, parts)
}

extension Data {
    init(bigEndian value: UInt32) {
        self.init([
            UInt8(truncatingIfNeeded: value >> 24),
            UInt8(truncatingIfNeeded: value >> 16),
            UInt8(truncatingIfNeeded: value >> 8),
            UInt8(truncatingIfNeeded: value)
        ])
    }

    /// First eight bytes as a big-endian `UInt64`. Zero-padded if shorter.
    var leadingUInt64: UInt64 {
        var value: UInt64 = 0
        for index in 0..<8 {
            let byte = index < count ? self[self.startIndex + index] : 0
            value = (value << 8) | UInt64(byte)
        }
        return value
    }

    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }

    init?(hexString: String) {
        let characters = Array(hexString)
        guard characters.count % 2 == 0 else { return nil }
        var bytes = [UInt8]()
        bytes.reserveCapacity(characters.count / 2)
        var index = 0
        while index < characters.count {
            guard let byte = UInt8(String(characters[index...index + 1]), radix: 16) else { return nil }
            bytes.append(byte)
            index += 2
        }
        self.init(bytes)
    }
}

/// SplitMix64 finaliser. The one place we rely on wrapping arithmetic, so it is
/// spelled out with `&*` / `&+` to make the overflow deliberate.
@inlinable
public func mix64(_ input: UInt64) -> UInt64 {
    var x = input
    x ^= x >> 30
    x = x &* 0xBF58_476D_1CE4_E5B9
    x ^= x >> 27
    x = x &* 0x94D0_49BB_1331_11EB
    x ^= x >> 31
    return x
}

/// Deterministic generator for the incidental noise inside one plant (per-petal
/// jitter and the like). Seeded from the genome, so it is reproducible without
/// paying for a hash per draw.
public struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public init(seed: SeedID, label: String) {
        state = seedDigest(SeedDomain.trait, seed.bytes, Data(label.utf8)).leadingUInt64
    }

    public mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        return mix64(state)
    }

    /// Uniform in `[0, 1)` using the top 53 bits, matching `Double`'s precision.
    public mutating func unit() -> Double {
        Double(next() >> 11) * 0x1.0p-53
    }

    public mutating func value(in range: ClosedRange<Double>) -> Double {
        range.lowerBound + unit() * (range.upperBound - range.lowerBound)
    }

    /// Centre-weighted draw. Averaging three samples gives a soft bell, which
    /// suits traits where extremes should be rare (petal twist, leaf droop).
    public mutating func bell() -> Double {
        (unit() + unit() + unit()) / 3.0
    }
}
