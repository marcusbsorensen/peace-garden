import Foundation

/// FNV-1a over bytes, for choosing one of a fixed set from a seed.
///
/// Used wherever the app has to turn 32 bytes into an index and have every
/// phone agree — the passage a meeting gives, the place it suggests. This has
/// to be a pure function of the bytes and of nothing else: both phones compute
/// it independently, and the same seed must give the same answer on a different
/// device, on a later OS, and years from now. That rules out `Hasher`, whose
/// seed is randomised per process, so the algorithm is spelled out here.
///
/// Every byte is folded rather than a prefix taken, so the draw depends on the
/// whole of what it is given. Wrapping arithmetic is the point of the algorithm
/// rather than an accident, which is why it is written with `&*`.
///
/// It is not a hash for keeping secrets and is not used as one. The derivations
/// that must resist being worked backwards live in `SeedCore` and go through
/// SHA-256; by the time anything reaches here it is already a digest.
func deterministicFold(_ bytes: Data) -> UInt64 {
    var hash: UInt64 = 0xCBF2_9CE4_8422_2325
    for byte in bytes {
        hash ^= UInt64(byte)
        hash = hash &* 0x0000_0100_0000_01B3
    }
    return hash
}
