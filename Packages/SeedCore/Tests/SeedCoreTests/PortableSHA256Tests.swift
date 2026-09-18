import XCTest
@testable import SeedCore

/// The browser build's SHA-256 against FIPS 180-4's own examples.
///
/// Runs on every host, because `seedDigest` is SHA-256 on every host: on the
/// phone and in CI these check CryptoKit and swift-crypto, which cannot fail
/// them, and in the WebAssembly run they check `PortableSHA256`, which can.
final class PortableSHA256Tests: XCTestCase {
    private func hex(_ text: String, repeating count: Int = 1) -> String {
        sha256(Array(repeating: Data(text.utf8), count: count)).hexString
    }

    func testEmpty() {
        XCTAssertEqual(hex(""), "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
    }

    func testOneBlock() {
        XCTAssertEqual(hex("abc"), "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }

    /// 56 bytes: the padding no longer fits, so a second block is needed.
    func testTwoBlocks() {
        XCTAssertEqual(
            hex("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"),
            "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1"
        )
    }

    /// A million bytes fed in pieces that do not line up with blocks.
    func testMillionAs() {
        XCTAssertEqual(
            hex(String(repeating: "a", count: 1000), repeating: 1000),
            "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0"
        )
    }
}
