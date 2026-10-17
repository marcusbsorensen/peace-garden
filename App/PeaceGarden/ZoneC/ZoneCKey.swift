import CryptoKit
import Foundation

/// K, the 32-byte key that signs the marks on space seeds (`ZoneCMark`).
///
/// The mark is what lets a phone tell a real space seed from the random bytes
/// that fill the pool, so K has to be a secret from whoever runs the server and
/// whoever reads this repository. Which is the difficulty: the repository is
/// public, and K is compiled into every build. So the production K is not in
/// it. `tools/zonec/make_key.sh` writes it to `ZoneCProductionKey.swift`, which
/// `.gitignore` names, and a Release build cannot be made without that file.
/// The binary still holds K, and anyone who unpacks it can read it; the design
/// accepts that (`design/space-seeds-2026-10-16/DESIGN.md` §4.4). What the
/// design needs is a K that never reaches the repository.
///
/// **A Debug build or a test uses a fixed test K instead.** It is in the open
/// on purpose, and that has a benefit and a cost.
///
/// The benefit: a Debug build and a Release build do not recognise each other's
/// space seeds, so a build from Xcode cannot take a real seed out of the pool or
/// have its own taken for one.
///
/// The cost: the test K is public, so a row marked with it is recognisable to
/// anyone who holds a copy of the pool (20i, a breach, a subpoena, a server
/// altered to log), without taking an app apart. A Debug build whose seed
/// reached the production pool would be that row. So `ZoneCExchange` sends
/// only padding in `aloft` from a Debug build that talks to the production
/// origin (`PlotService.origin`), and leaves the seed in `out/`.
enum ZoneCKey {
    /// K is 32 bytes: the length of SHA-256's output, which is the least that
    /// HMAC-SHA256 wants, and what `make_key.sh` draws.
    static let length = 32

    /// K, as the key `ZoneCMark` signs with.
    static var mark: SymmetricKey {
        let bytes = Self.bytes
        // Only the generated file can be the wrong size, and only by a hand
        // edit; a short K would still sign, quietly, which is the failure this
        // is here to stop.
        precondition(bytes.count == length, "Zone C's key must be \(length) bytes: rerun tools/zonec/make_key.sh")
        return SymmetricKey(data: bytes)
    }

    #if DEBUG
    /// SHA-256 of `peacegarden.zonec.test-key.v1`. Not a secret and not for
    /// release: `ZoneCCryptoTests` pins it, so that changing it is noticed.
    static let testBytes: [UInt8] = [
        0x58, 0x22, 0x7a, 0x1e, 0xab, 0x9f, 0x1f, 0x7f,
        0x68, 0x8a, 0xb2, 0x58, 0x59, 0xd7, 0x8c, 0xf9,
        0xbe, 0x11, 0x57, 0x8d, 0x06, 0x12, 0x2b, 0x74,
        0xb3, 0x4c, 0x39, 0x29, 0x13, 0xcf, 0x9e, 0x8a,
    ]

    private static var bytes: [UInt8] { testBytes }
    #else
    // `ZoneCProductionKey` exists only in the generated, gitignored file. If
    // this line does not compile, that file is missing from this checkout:
    // run `sh tools/zonec/make_key.sh` (or copy the file from the machine that
    // made it, since K must be the same in every build) and `xcodegen generate`.
    private static var bytes: [UInt8] { ZoneCProductionKey.bytes }
    #endif
}
