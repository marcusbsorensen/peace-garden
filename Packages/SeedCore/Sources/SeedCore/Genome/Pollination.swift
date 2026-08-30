import Foundation

/// The derivations two phones perform independently during an encounter.
///
/// Nothing here consults a clock, a server, or a device identifier: given the
/// same four inputs, both phones produce the same offspring seed, and the
/// checksum lets them prove it before either one saves a plant.
public enum Pollination {
    /// Identifies one meeting between two seeds.
    ///
    /// Each phone contributes a random nonce, so meeting the same person again
    /// tomorrow grows a different plant, and neither side can steer the result
    /// on their own by choosing their nonce carefully.
    public static func encounterID(
        seedA: SeedID,
        seedB: SeedID,
        nonceA: Data,
        nonceB: Data
    ) -> Data {
        let (lowSeed, highSeed) = ordered(seedA, seedB)
        let (lowNonce, highNonce) = orderedBytes(nonceA, nonceB)
        return seedDigest(SeedDomain.encounter, lowSeed.bytes, highSeed.bytes, lowNonce, highNonce)
    }

    /// The offspring seed for one encounter.
    public static func cross(seedA: SeedID, seedB: SeedID, encounterID: Data) -> SeedID {
        let (low, high) = ordered(seedA, seedB)
        return SeedID(digest: seedDigest(SeedDomain.cross, low.bytes, high.bytes, encounterID))
    }

    /// Eight bytes the two phones swap to confirm they grew the same plant. A
    /// mismatch means the versions disagree and the exchange must be abandoned
    /// rather than quietly producing two different plants.
    public static func checksum(of seed: SeedID) -> Data {
        seedDigest(SeedDomain.checksum, seed.bytes).prefix(8)
    }

    /// Fresh nonce for one encounter, from the system CSPRNG.
    public static func makeNonce(byteCount: Int = 16) -> Data {
        var bytes = [UInt8](repeating: 0, count: byteCount)
        for index in bytes.indices {
            bytes[index] = UInt8.random(in: 0...255)
        }
        return Data(bytes)
    }

    static func ordered(_ a: SeedID, _ b: SeedID) -> (SeedID, SeedID) {
        a < b ? (a, b) : (b, a)
    }

    static func orderedBytes(_ a: Data, _ b: Data) -> (Data, Data) {
        lexicographicallyPrecedes(a, b) ? (a, b) : (b, a)
    }

    private static func lexicographicallyPrecedes(_ a: Data, _ b: Data) -> Bool {
        for (left, right) in zip(a, b) where left != right {
            return left < right
        }
        return a.count < b.count
    }
}
