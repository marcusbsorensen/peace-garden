import Foundation

/// A 32-byte seed: the whole of a person's plant, and the only thing that ever
/// crosses between two phones.
///
/// Ordering is unsigned byte-lexicographic and is load-bearing — cross
/// pollination sorts the two parents so both phones agree on the result
/// without agreeing on who initiated.
public struct SeedID: Hashable, Comparable, Sendable, CustomStringConvertible {
    public static let byteCount = 32

    public let bytes: Data

    public init?(bytes: Data) {
        guard bytes.count == Self.byteCount else { return nil }
        self.bytes = bytes
    }

    public init?(hex: String) {
        guard let data = Data(hexString: hex) else { return nil }
        self.init(bytes: data)
    }

    /// For values that are known-good by construction (digest output).
    init(digest: Data) {
        precondition(digest.count == Self.byteCount, "seed digests are always 32 bytes")
        bytes = digest
    }

    public var hex: String { bytes.hexString }

    /// Six characters is enough to tell two seeds apart in the UI without
    /// pretending the whole seed is human-readable.
    public var short: String { String(hex.prefix(6)) }

    public var description: String { "Seed(\(short))" }

    public static func < (lhs: SeedID, rhs: SeedID) -> Bool {
        for (left, right) in zip(lhs.bytes, rhs.bytes) where left != right {
            return left < right
        }
        return false
    }
}

extension SeedID: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let hex = try container.decode(String.self)
        guard let seed = SeedID(hex: hex) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "not a 32-byte hex seed")
        }
        self = seed
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(hex)
    }
}
