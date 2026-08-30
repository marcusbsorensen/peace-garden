import XCTest
@testable import SeedCore

/// A seed in a link has to survive every channel a person might send it
/// through, and has to be readable by a build that did not write it.
final class PollenLinkTests: XCTestCase {
    private var seed: SeedID { SeedMint.mint(fromEntropy: Data("peace-garden-reference-entropy-A".utf8)) }
    private var nonce: Data { Data((0..<16).map { UInt8($0) }) }

    private func makeLink(kind: PollenLink.Kind = .offer) -> PollenLink {
        PollenLink(
            kind: kind,
            seed: seed,
            nonce: nonce,
            displayName: "Marcus",
            plantName: "Aurelia nocturna",
            birth: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }

    func testFragmentMatchesReference() {
        // From tools/reference/derivation_reference.py, so a link written by
        // one implementation is readable by the other.
        let expected = "1.o.Ku7e0d-lNwWEMUuvt60W5NfNA4L-0el_yvIjjCHISDM"
            + ".AAECAwQFBgcICQoLDA0ODw.1700000000.TWFyY3Vz"
            + ".QXVyZWxpYSBub2N0dXJuYQ...Ztri7XhK"
        XCTAssertEqual(makeLink().fragment, expected)
    }

    func testRoundTripThroughAURL() throws {
        let link = makeLink()
        let url = try XCTUnwrap(link.url(host: "peacegarden.app"))
        XCTAssertEqual(url.scheme, "https")
        XCTAssertEqual(url.path, PollenLink.path)
        XCTAssertEqual(try PollenLink.parse(url), link)
    }

    func testTheSeedStaysOutOfTheQueryString() throws {
        // The payload must ride in the fragment: a fragment never reaches the
        // server, so opening the link on a phone without the app tells the host
        // nothing about the seed.
        let url = try XCTUnwrap(makeLink().url(host: "peacegarden.app"))
        XCTAssertNil(url.query)
        XCTAssertFalse(url.absoluteString.replacingOccurrences(of: url.fragment ?? "", with: "")
            .contains(seed.hex.prefix(8)))
    }

    func testNamesWithAwkwardCharactersSurvive() throws {
        let link = PollenLink(
            kind: .reply,
            seed: seed,
            nonce: nonce,
            displayName: "Ada . Lovelace #1 🌱",
            plantName: "Wyn ynth · sylvatica",
            birth: Date(timeIntervalSince1970: 1_700_000_000),
            echo: Data(repeating: 9, count: 16),
            check: Data(repeating: 3, count: 8)
        )
        // Names are base64'd rather than escaped, so a full stop in someone's
        // name cannot be mistaken for a field separator.
        let parsed = try PollenLink.parse(fragment: link.fragment)
        XCTAssertEqual(parsed.displayName, "Ada . Lovelace #1 🌱")
        XCTAssertEqual(parsed.plantName, "Wyn ynth · sylvatica")
        XCTAssertEqual(parsed.kind, .reply)
    }

    func testAMangledLinkIsRefusedRatherThanMisread() {
        var fragment = makeLink().fragment
        fragment.removeLast(4)
        fragment += "aaaa"
        XCTAssertThrowsError(try PollenLink.parse(fragment: fragment)) { error in
            XCTAssertEqual(error as? PollenLink.LinkError, .damaged)
        }
    }

    func testALinkFromANewerVersionSaysSoPlainly() {
        let fragment = "2.o.abc.def.1700000000.TWFyY3Vz.QXVy...aaaaaa"
        XCTAssertThrowsError(try PollenLink.parse(fragment: fragment)) { error in
            XCTAssertEqual(error as? PollenLink.LinkError, .unsupportedVersion(2))
        }
    }

    func testAnUnrelatedURLIsNotASeed() throws {
        let url = try XCTUnwrap(URL(string: "https://example.com/hello"))
        XCTAssertThrowsError(try PollenLink.parse(url)) { error in
            XCTAssertEqual(error as? PollenLink.LinkError, .notAPollenLink)
        }
    }

    func testAReplyWithoutItsEchoIsRefused() {
        // Without the echo the sender cannot reach the same plant, and without
        // the checksum they could not tell that they had not.
        let offer = makeLink()
        let stripped = offer.fragment.replacingOccurrences(of: ".o.", with: ".r.")
        XCTAssertThrowsError(try PollenLink.parse(fragment: stripped))
    }

    func testAReplyThatWouldGrowADifferentPlantIsRefused() throws {
        let sender = seed
        let senderNonce = Pollination.makeNonce()
        let offer = PollenLink(
            kind: .offer, seed: sender, nonce: senderNonce,
            displayName: "Marcus", plantName: "Aurelia nocturna", birth: Date()
        )
        let receiver = SeedMint.mint(fromEntropy: Data("someone else".utf8))
        let tampered = PollenLink(
            kind: .reply, seed: receiver, nonce: Pollination.makeNonce(),
            displayName: "Ada", plantName: "Whatever", birth: Date(),
            echo: offer.nonce,
            check: Data(repeating: 0, count: 8)
        )
        XCTAssertNil(tampered.cross(withLocalSeed: sender, localNonce: senderNonce))
    }

    func testBothSidesOfALinkExchangeGrowTheSamePlant() throws {
        // The receiver mints their own seed and crosses with what arrived; the
        // reply carries theirs back so the sender lands on the identical plant.
        let sender = seed
        let senderNonce = Pollination.makeNonce()
        let offer = PollenLink(
            kind: .offer,
            seed: sender,
            nonce: senderNonce,
            displayName: "Marcus",
            plantName: "Aurelia nocturna",
            birth: Date()
        )

        let received = try PollenLink.parse(fragment: offer.fragment)
        let receiver = SeedMint.mint(fromEntropy: Data("a brand new phone".utf8))
        let receiverNonce = Pollination.makeNonce()

        let onReceiver = CrossPollinationResult(
            localSeed: receiver,
            remoteSeed: received.seed,
            localNonce: receiverNonce,
            remoteNonce: received.nonce
        )

        let reply = PollenLink.reply(
            to: received,
            seed: receiver,
            nonce: receiverNonce,
            displayName: "Ada",
            plantName: onReceiver.genome.name.full,
            birth: Date(),
            result: onReceiver
        )

        // The sender kept nothing: everything needed is in the reply itself.
        let backAtSender = try PollenLink.parse(fragment: reply.fragment)
        let onSender = try XCTUnwrap(
            backAtSender.cross(withLocalSeed: sender, localNonce: Data())
        )

        XCTAssertEqual(onSender.childSeed, onReceiver.childSeed)
        XCTAssertEqual(onSender.genome, onReceiver.genome)
    }
}
