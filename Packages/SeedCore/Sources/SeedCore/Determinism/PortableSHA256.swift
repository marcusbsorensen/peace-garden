#if os(WASI)
import FoundationEssentials

/// SHA-256 for the browser build, in plain Swift.
///
/// Everywhere else SeedCore hashes with CryptoKit or swift-crypto. swift-crypto
/// imports the whole of Foundation, and in WebAssembly that is some 50 MB, most
/// of it ICU text data, to reach one hash function. This is FIPS 180-4 as
/// written, with only the calls `seedDigest` makes. `PortableSHA256Tests`
/// checks it against the standard's vectors, and the derivation vectors check
/// that it grows the same seeds.
struct SHA256 {
    private var state: [UInt32] = [
        0x6a09_e667, 0xbb67_ae85, 0x3c6e_f372, 0xa54f_f53a,
        0x510e_527f, 0x9b05_688c, 0x1f83_d9ab, 0x5be0_cd19
    ]
    private var pending: [UInt8] = []
    private var length: UInt64 = 0

    mutating func update(data: Data) {
        length &+= UInt64(data.count)
        pending.append(contentsOf: data)
        var start = 0
        while pending.count - start >= 64 {
            compress(pending[start..<start + 64])
            start += 64
        }
        pending.removeFirst(start)
    }

    func finalize() -> [UInt8] {
        var copy = self
        let bits = length &* 8
        copy.pending.append(0x80)
        while copy.pending.count % 64 != 56 { copy.pending.append(0) }
        for shift in stride(from: 56, through: 0, by: -8) {
            copy.pending.append(UInt8(truncatingIfNeeded: bits >> UInt64(shift)))
        }
        for start in stride(from: 0, to: copy.pending.count, by: 64) {
            copy.compress(copy.pending[start..<start + 64])
        }
        var out: [UInt8] = []
        out.reserveCapacity(32)
        for word in copy.state {
            out.append(UInt8(truncatingIfNeeded: word >> 24))
            out.append(UInt8(truncatingIfNeeded: word >> 16))
            out.append(UInt8(truncatingIfNeeded: word >> 8))
            out.append(UInt8(truncatingIfNeeded: word))
        }
        return out
    }

    private mutating func compress(_ block: ArraySlice<UInt8>) {
        var w = [UInt32](repeating: 0, count: 64)
        let base = block.startIndex
        for t in 0..<16 {
            w[t] = UInt32(block[base + t * 4]) << 24
                | UInt32(block[base + t * 4 + 1]) << 16
                | UInt32(block[base + t * 4 + 2]) << 8
                | UInt32(block[base + t * 4 + 3])
        }
        for t in 16..<64 {
            let s0 = rotr(w[t - 15], 7) ^ rotr(w[t - 15], 18) ^ (w[t - 15] >> 3)
            let s1 = rotr(w[t - 2], 17) ^ rotr(w[t - 2], 19) ^ (w[t - 2] >> 10)
            w[t] = w[t - 16] &+ s0 &+ w[t - 7] &+ s1
        }
        var a = state[0], b = state[1], c = state[2], d = state[3]
        var e = state[4], f = state[5], g = state[6], h = state[7]
        for t in 0..<64 {
            let s1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)
            let choice = (e & f) ^ (~e & g)
            let temp1 = h &+ s1 &+ choice &+ Self.k[t] &+ w[t]
            let s0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)
            let majority = (a & b) ^ (a & c) ^ (b & c)
            let temp2 = s0 &+ majority
            h = g; g = f; f = e; e = d &+ temp1
            d = c; c = b; b = a; a = temp1 &+ temp2
        }
        state[0] &+= a; state[1] &+= b; state[2] &+= c; state[3] &+= d
        state[4] &+= e; state[5] &+= f; state[6] &+= g; state[7] &+= h
    }

    private func rotr(_ x: UInt32, _ n: UInt32) -> UInt32 {
        (x >> n) | (x << (32 - n))
    }

    private static let k: [UInt32] = [
        0x428a_2f98, 0x7137_4491, 0xb5c0_fbcf, 0xe9b5_dba5, 0x3956_c25b, 0x59f1_11f1, 0x923f_82a4, 0xab1c_5ed5,
        0xd807_aa98, 0x1283_5b01, 0x2431_85be, 0x550c_7dc3, 0x72be_5d74, 0x80de_b1fe, 0x9bdc_06a7, 0xc19b_f174,
        0xe49b_69c1, 0xefbe_4786, 0x0fc1_9dc6, 0x240c_a1cc, 0x2de9_2c6f, 0x4a74_84aa, 0x5cb0_a9dc, 0x76f9_88da,
        0x983e_5152, 0xa831_c66d, 0xb003_27c8, 0xbf59_7fc7, 0xc6e0_0bf3, 0xd5a7_9147, 0x06ca_6351, 0x1429_2967,
        0x27b7_0a85, 0x2e1b_2138, 0x4d2c_6dfc, 0x5338_0d13, 0x650a_7354, 0x766a_0abb, 0x81c2_c92e, 0x9272_2c85,
        0xa2bf_e8a1, 0xa81a_664b, 0xc24b_8b70, 0xc76c_51a3, 0xd192_e819, 0xd699_0624, 0xf40e_3585, 0x106a_a070,
        0x19a4_c116, 0x1e37_6c08, 0x2748_774c, 0x34b0_bcb5, 0x391c_0cb3, 0x4ed8_aa4a, 0x5b9c_ca4f, 0x682e_6ff3,
        0x748f_82ee, 0x78a5_636f, 0x84c8_7814, 0x8cc7_0208, 0x90be_fffa, 0xa450_6ceb, 0xbef9_a3f7, 0xc671_78f2
    ]
}
#endif
