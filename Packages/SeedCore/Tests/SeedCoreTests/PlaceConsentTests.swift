import XCTest
@testable import SeedCore

/// The rule that a coordinate needs both people, and the rounds that keep it.
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

    func testConfirmDropsACoordinateTheOtherSideDidNotAgreeTo() {
        // The direction that matters: being willing myself is not enough. Two
        // people at one meeting stand in the same place, so sending mine would
        // publish theirs.
        let envelope = ExchangeEnvelope.confirm(
            checksum: Data([1, 2, 3]),
            coordinate: somewhere,
            mine: card("mine", shares: true),
            theirs: card("theirs", shares: false)
        )
        XCTAssertNil(envelope.coordinate)
    }

    func testConfirmCarriesACoordinateWhenBothAgreed() {
        let envelope = ExchangeEnvelope.confirm(
            checksum: Data([1, 2, 3]),
            coordinate: somewhere,
            mine: card("mine", shares: true),
            theirs: card("theirs", shares: true)
        )
        XCTAssertEqual(envelope.coordinate, somewhere)
    }

    func testAHelloNeverCarriesACoordinate() {
        // Consent travels a round ahead of what it permits. If a hello could
        // carry a coordinate, whoever spoke first would have disclosed before
        // learning whether the other side agreed.
        let hello = ExchangeEnvelope.hello(
            card: card("mine", shares: true),
            nonce: Data(repeating: 9, count: 16)
        )
        XCTAssertNil(hello.coordinate)
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

    func testACoordinateIsRoundedToAboutAMetreAndSurvivesTheWire() throws {
        let precise = Coordinate(latitude: 51.376_712_345_6, longitude: 1.303_421_098_7)
        XCTAssertEqual(precise.latitude, 51.376_71, accuracy: 1e-9)
        XCTAssertEqual(precise.longitude, 1.303_42, accuracy: 1e-9)

        let envelope = ExchangeEnvelope.confirm(
            checksum: Data([7]),
            coordinate: precise,
            mine: card("a", shares: true),
            theirs: card("b", shares: true)
        )
        let decoded = try ExchangeEnvelope.decode(envelope.encoded())
        XCTAssertEqual(decoded.coordinate, precise)
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
