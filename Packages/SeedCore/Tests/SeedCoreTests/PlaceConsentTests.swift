import XCTest
@testable import SeedCore

/// The rule that a location needs both people, and the fact that one never
/// travels: each phone stamps its own reading.
final class PlaceConsentTests: XCTestCase {
    private func card(_ label: String, shares: Bool) -> PollenCard {
        PollenCard(
            seed: SeedMint.mint(fromEntropy: Data(label.utf8)),
            displayName: label,
            plantName: "Ithora solaria",
            birth: Date(timeIntervalSince1970: 0),
            sharesPlace: shares
        )
    }

    private let somewhere = Coordinate(latitude: 51.376_71, longitude: 1.303_42)

    func testACoordinateNeedsBothPeople() {
        let yes = card("yes", shares: true)
        let no = card("no", shares: false)

        XCTAssertTrue(PollenCard.permitPlace(yes, yes))
        XCTAssertFalse(PollenCard.permitPlace(yes, no))
        XCTAssertFalse(PollenCard.permitPlace(no, yes))
        XCTAssertFalse(PollenCard.permitPlace(no, no))
    }

    func testBeingWillingYourselfIsNotEnough() {
        // The direction that matters. Two people at one meeting stand in the
        // same place, so stamping mine would record theirs.
        XCTAssertFalse(PollenCard.permitPlace(
            card("mine", shares: true), card("theirs", shares: false)
        ))
    }

    func testNoCoordinateEverCrossesTheAir() throws {
        // The strongest form of the guarantee: there is nowhere on the wire for
        // a location to sit, whatever anyone agreed to. Each phone stamps its
        // own reading, so the measurement never leaves the device that took it.
        let envelopes = [
            ExchangeEnvelope.touch(),
            ExchangeEnvelope.hello(card: card("mine", shares: true), nonce: Data(repeating: 9, count: 16)),
            ExchangeEnvelope.confirm(checksum: Data([1, 2, 3])),
            ExchangeEnvelope.abort(reason: "same seed"),
        ]
        for envelope in envelopes {
            let wire = String(decoding: try envelope.encoded(), as: UTF8.self).lowercased()
            XCTAssertFalse(wire.contains("latitude"), "\(envelope.kind) carries a latitude")
            XCTAssertFalse(wire.contains("longitude"), "\(envelope.kind) carries a longitude")
            XCTAssertFalse(wire.contains("coordinate"), "\(envelope.kind) carries a coordinate")
        }
    }

    func testACardFromAnOlderVersionCountsAsARefusal() throws {
        // sharesPlace is absent from a version 1 card. Decoding one must not
        // produce a yes by accident, so the field is optional and missing is no.
        let seed = SeedMint.mint(fromEntropy: Data("old".utf8))
        let older = """
        {"seed":"\(seed.hex)","displayName":"Gardener",\
        "plantName":"Ithora solaria","birth":"1970-01-01T00:00:00Z"}
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let old = try decoder.decode(PollenCard.self, from: Data(older.utf8))

        XCTAssertNil(old.sharesPlace)
        XCTAssertFalse(PollenCard.permitPlace(old, card("new", shares: true)))
    }

    func testACoordinateIsRoundedToAboutAMetre() {
        let precise = Coordinate(latitude: 51.376_712_345_6, longitude: 1.303_421_098_7)
        XCTAssertEqual(precise.latitude, 51.376_71, accuracy: 1e-9)
        XCTAssertEqual(precise.longitude, 1.303_42, accuracy: 1e-9)
    }

    func testANoteKeepsPlaceAndCoordinateApart() {
        // What someone typed is theirs and local; the coordinate is the agreed
        // fact. Neither is derived from the other, in either direction, and both
        // can be changed afterwards.
        var note = EncounterNote(
            peerDisplayName: "Ada",
            happenedAt: Date(timeIntervalSince1970: 0),
            place: "On the winds",
            coordinate: somewhere
        )

        note.place = "The bench by the harbour"
        XCTAssertEqual(note.coordinate, somewhere)

        note.coordinate = nil
        XCTAssertEqual(note.place, "The bench by the harbour")
    }
}
