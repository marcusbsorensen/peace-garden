import XCTest
@testable import SeedCore

/// What a phone keeps so a plant can be shown on the web, and what it posts.
///
/// Two things are load-bearing here and both are file formats: a garden written
/// before any of this decodes unchanged, and the body posted to the plot
/// service is the one `Server/.api/router.php` validates. Both are pinned.
final class SharingTests: XCTestCase {

    // MARK: Nothing migrates

    func testAGardenWrittenBeforeSharingExistedStillDecodes() throws {
        // A record exactly as version 1 wrote one: no tokens, no standing.
        let json = """
        {
          "id": "6F9619FF-8B86-D011-B42D-00CF4FC964FF",
          "seed": "\(String(repeating: "ab", count: 32))",
          "lineage": { "minted": {} },
          "birth": 0,
          "savedAt": 0
        }
        """
        let decoder = JSONDecoder()
        let record = try decoder.decode(PlantRecord.self, from: Data(json.utf8))

        XCTAssertNil(record.tokens)
        XCTAssertNil(record.standing)
        XCTAssertEqual(record.standingOrHere.state, .here)
    }

    func testAPlantThatWasNeverSharedSaysSoWithoutAFieldForIt() {
        let record = mintedRecord()
        XCTAssertFalse(record.standingOrHere.isShown)
        XCTAssertTrue(record.standingOrHere.canAsk)
    }

    func testAStateFromANewerVersionDecodesRatherThanThrowingTheGardenAway() throws {
        let json = #"{"state":"lifted","changedAt":0}"#
        let standing = try JSONDecoder().decode(Standing.self, from: Data(json.utf8))

        XCTAssertEqual(standing.state, .unknown)
        // And it is not mistaken for a plant that may still be offered.
        XCTAssertFalse(standing.canAsk)
    }

    // MARK: Who may be offered

    func testAMintedPlantCannotBeOfferedBecauseThereIsNoSecondGardener() {
        let record = mintedRecord()
        XCTAssertFalse(record.canBeOffered)
        XCTAssertNil(WalkArrival(record: record))
    }

    func testAHybridFromABeforeTokensExistedCannotBeOffered() {
        // The whole reason the token had to be in the card before phase 2: this
        // plant is a real meeting and can never carry an invitation.
        let record = hybridRecord(remembersTheMeeting: false)
        XCTAssertTrue(record.isHybrid)
        XCTAssertFalse(record.canBeOffered)
        // It can still describe itself; what it cannot do is reach anybody.
        XCTAssertNotNil(WalkArrival(record: record))
    }

    func testAHybridWithTokensCanBeOfferedExactlyOnce() {
        var record = hybridRecord()
        XCTAssertTrue(record.canBeOffered)

        for state in [Standing.State.asked, .invited, .shown, .declined, .unknown] {
            record.standing = Standing(state: state, changedAt: Date())
            XCTAssertFalse(record.canBeOffered, "\(state) should not be offerable again")
        }
    }

    func testDecliningIsFinalAndIsTheBlock() {
        var record = hybridRecord()
        record.standing = Standing(state: .declined, changedAt: Date())
        XCTAssertFalse(record.canBeOffered)
        XCTAssertFalse(record.standingOrHere.isShown)
    }

    // MARK: The tokens

    func testTheTwoTokensAreKeptApartSoAnInvitationHasADirection() {
        let tokens = MeetingTokens(ours: Data(repeating: 1, count: 16),
                                   theirs: Data(repeating: 2, count: 16))
        XCTAssertNotEqual(tokens.ours, tokens.theirs)
        XCTAssertEqual(tokens.oursHex, String(repeating: "01", count: 16))
        XCTAssertEqual(tokens.theirsHex, String(repeating: "02", count: 16))
    }

    func testAMeetingsTokensSurviveASaveAndALoad() throws {
        let record = hybridRecord()
        let data = try JSONEncoder().encode(record)
        let back = try JSONDecoder().decode(PlantRecord.self, from: data)
        XCTAssertEqual(back.tokens, record.tokens)
    }

    func testAFreshTokenIsSixteenBytesAndNotTheSameTwice() {
        let one = PollenCard.makeContactToken()
        let two = PollenCard.makeContactToken()
        XCTAssertEqual(one.count, 16)
        XCTAssertNotEqual(one, two)
    }

    // MARK: What is posted

    func testTheArrivalIsTheShapeThePlotServiceValidates() throws {
        let record = hybridRecord()
        let arrival = try XCTUnwrap(WalkArrival(record: record))

        let data = try JSONEncoder().encode(arrival)
        let body = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        // router.php reads exactly these five and no others.
        XCTAssertEqual(Set(body.keys), ["seed", "parents", "encounter", "height", "family"])

        let seed = try XCTUnwrap(body["seed"] as? String)
        let parents = try XCTUnwrap(body["parents"] as? [String])
        let encounter = try XCTUnwrap(body["encounter"] as? String)
        for hex in [seed, encounter] + parents {
            XCTAssertTrue(isHex32(hex), "\(hex) is not 64 lowercase hex characters")
        }
        XCTAssertEqual(parents.count, 2)

        // And the two the rule places by, in the ranges router.php holds them to.
        let height = try XCTUnwrap(body["height"] as? Double)
        let family = try XCTUnwrap(body["family"] as? Int)
        XCTAssertTrue((0.05...4.0).contains(height), "height \(height) is outside what a plant reaches")
        XCTAssertTrue((0...LongWalk.paleFamily).contains(family))
    }

    func testTheArrivalCarriesTheParentsInTheLineagesOwnOrder() throws {
        let record = hybridRecord()
        let arrival = try XCTUnwrap(WalkArrival(record: record))
        let (a, b) = try XCTUnwrap(record.lineage.parents)
        XCTAssertEqual(arrival.parents, [a.hex, b.hex])
    }

    func testTheArrivalsSeedIsTheCrossOfItsParentsAtThatMeeting() throws {
        // The one thing the service checks for itself, checked here too so a
        // change on either side is caught by whichever suite runs first.
        let record = hybridRecord()
        let arrival = try XCTUnwrap(WalkArrival(record: record))
        guard case let .crossed(a, b, encounter) = record.lineage else {
            return XCTFail("not a hybrid")
        }
        XCTAssertEqual(Pollination.cross(seedA: a, seedB: b, encounterID: encounter).hex, arrival.seed)
    }

    func testTheArrivalsTraitsArePlacedWhereTheGrownPlantWouldBe() throws {
        let record = hybridRecord()
        let arrival = try XCTUnwrap(WalkArrival(record: record))
        XCTAssertEqual(arrival.traits, LongWalk.traits(of: record.genome))
    }

    func testEveryHybridArrivesWithinWhatTheServiceAccepts() throws {
        // Across a spread of real crossings, because a height outside the range
        // is a 400 from the service and there is no retry that would fix it.
        for index in 0..<120 {
            let a = SeedID(digest: seedDigest("test.parentA", Data("\(index)".utf8)))
            let b = SeedID(digest: seedDigest("test.parentB", Data("\(index)".utf8)))
            let encounter = Pollination.encounterID(
                seedA: a, seedB: b,
                nonceA: Data(repeating: UInt8(index % 251), count: 16),
                nonceB: Data(repeating: UInt8((index * 7) % 251), count: 16)
            )
            let child = Pollination.cross(seedA: a, seedB: b, encounterID: encounter)
            let record = PlantRecord(
                seed: child,
                lineage: .crossed(parentA: a, parentB: b, encounterID: encounter),
                birth: Date(timeIntervalSince1970: 0),
                tokens: tokens()
            )
            let arrival = try XCTUnwrap(WalkArrival(record: record))
            XCTAssertTrue((0.05...4.0).contains(arrival.height),
                          "seed \(index) grows to \(arrival.height) m, which the service refuses")
            XCTAssertTrue((0...LongWalk.paleFamily).contains(arrival.family))
        }
    }

    // MARK: Fixtures

    private func tokens() -> MeetingTokens {
        MeetingTokens(ours: Data(repeating: 0xA1, count: 16),
                      theirs: Data(repeating: 0xB2, count: 16))
    }

    private func mintedRecord() -> PlantRecord {
        PlantRecord(
            seed: SeedID(digest: seedDigest("test.minted", Data())),
            lineage: .minted,
            birth: Date(timeIntervalSince1970: 0)
        )
    }

    private func hybridRecord(remembersTheMeeting: Bool = true) -> PlantRecord {
        let a = SeedID(digest: seedDigest("test.a", Data()))
        let b = SeedID(digest: seedDigest("test.b", Data()))
        let encounter = Pollination.encounterID(
            seedA: a, seedB: b,
            nonceA: Data(repeating: 3, count: 16),
            nonceB: Data(repeating: 4, count: 16)
        )
        return PlantRecord(
            seed: Pollination.cross(seedA: a, seedB: b, encounterID: encounter),
            lineage: .crossed(parentA: a, parentB: b, encounterID: encounter),
            birth: Date(timeIntervalSince1970: 0),
            tokens: remembersTheMeeting ? tokens() : nil
        )
    }

    private func isHex32(_ text: String) -> Bool {
        text.count == 64 && text.allSatisfy { "0123456789abcdef".contains($0) }
    }
}
