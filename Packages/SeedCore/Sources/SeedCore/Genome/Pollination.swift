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

    /// Identifies two seeds as a pair, for as long as both exist.
    ///
    /// The deliberate opposite of `encounterID`: no nonce, so it is the same
    /// every time these two meet, and different for every other pairing. That
    /// makes it the handle for anything that should belong to *the two of them*
    /// rather than to one meeting — the passage shown when they cross is the
    /// first such thing.
    ///
    /// Not steerable, though it has no nonce to prevent it: choosing the pair
    /// digest would mean choosing your seed, and a seed is drawn once and cannot
    /// be drawn again. There is nothing to grind.
    ///
    /// Derives from the two parents alone, so both phones reach it without
    /// sending anything, and it survives a phone being replaced.
    public static func pairID(seedA: SeedID, seedB: SeedID) -> Data {
        let (low, high) = ordered(seedA, seedB)
        return seedDigest(SeedDomain.pair, low.bytes, high.bytes)
    }

    /// A named draw in `[0, 1)` that belongs to a pair.
    ///
    /// The pair's answer to `GeneSource.unit`: same shape, same by-name
    /// discipline, but rolled from `pairID`, so it is settled the first time two
    /// people meet and never moves again. What varies between their meetings has
    /// to come from the child seed instead.
    public static func pairUnit(seedA: SeedID, seedB: SeedID, label: String) -> Double {
        let digest = seedDigest(SeedDomain.pair, pairID(seedA: seedA, seedB: seedB), Data(label.utf8))
        return Double(mix64(digest.leadingUInt64) >> 11) * 0x1.0p-53
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
