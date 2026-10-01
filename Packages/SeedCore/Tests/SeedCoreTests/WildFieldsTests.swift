import XCTest
@testable import SeedCore

/// The Wild Fields: a place read off a seed, and the release a phone posts.
///
/// The place is pinned in `tools/reference/wild_fields_vectors.json`, which
/// `check_wild_fields.php` holds the service's port to. It needs no tolerance
/// anywhere: every place is a whole number of 1/1024ths of a metre.
final class WildFieldsTests: XCTestCase {

    static var vectorsURL: URL {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { url.deleteLastPathComponent() }
        return url.appendingPathComponent("tools/reference/wild_fields_vectors.json")
    }

    static let recordingKey = "PEACE_GARDEN_RECORD_VECTORS"

    /// Three hundred seeds, and the four corners of the byte space, which are
    /// the places a port that rounded instead of truncating, or that read the
    /// bytes in the other order, would get wrong first.
    static func seeds() -> [SeedID] {
        var seeds = (0..<300).map { SeedID(digest: seedDigest("wild.vectors", Data("\($0)".utf8))) }
        for corner in [[0x00, 0x00, 0x00, 0x00], [0xff, 0xff, 0xff, 0xff],
                       [0x00, 0xff, 0xff, 0x00], [0x1f, 0xff, 0x20, 0x00]] as [[UInt8]] {
            seeds.append(SeedID(bytes: Data(corner + [UInt8](repeating: 0x5a, count: 28)))!)
        }
        return seeds
    }

    static func render() -> String {
        let lines = seeds().map { seed -> String in
            let (x, z) = WildFields.spot(of: seed)
            let tile = WildFields.tile(of: seed)
            return #"{"seed":"\#(seed.hex)","spot":[\#(x),\#(z)],"tile":[\#(tile.x),\#(tile.z)]}"#
        }
        return "[\n" + lines.joined(separator: ",\n") + "\n]\n"
    }

    func testTheRecordedPlacesAreStillWhatTheRuleDoes() throws {
        let rendered = Self.render()
        if ProcessInfo.processInfo.environment[Self.recordingKey] == "1" {
            try rendered.write(to: Self.vectorsURL, atomically: true, encoding: .utf8)
            print("recorded \(Self.vectorsURL.path)")
            return
        }
        let committed = try String(contentsOf: Self.vectorsURL, encoding: .utf8)
        VectorFile.same(committed: committed, rendered: rendered, tolerant: [:],
                        recordWith: """
                            re-record with PEACE_GARDEN_RECORD_VECTORS=1 swift test \
                            --package-path Packages/SeedCore --filter WildFieldsTests, \
                            then run php tools/reference/check_wild_fields.php.
                            """)
    }

    // MARK: The place

    func testEveryPlaceIsInsideTheField() {
        for seed in Self.seeds() {
            let (x, z) = WildFields.spot(of: seed)
            XCTAssert((0..<WildFields.side).contains(x) && (0..<WildFields.side).contains(z),
                      "\(seed) stands at \(x), \(z)")
            let tile = WildFields.tile(of: seed)
            XCTAssert((0..<WildFields.tiles).contains(tile.x) && (0..<WildFields.tiles).contains(tile.z))
        }
    }

    func testAPlaceIsTheFirstFourBytesAndNothingElse() {
        // Two seeds that share their first four bytes stand in one place: a
        // collision, allowed and drawn.
        let one = SeedID(bytes: Data([0x12, 0x34, 0x56, 0x78] + [UInt8](repeating: 1, count: 28)))!
        let two = SeedID(bytes: Data([0x12, 0x34, 0x56, 0x78] + [UInt8](repeating: 2, count: 28)))!
        XCTAssertEqual(WildFields.spot(of: one).x, WildFields.spot(of: two).x)
        XCTAssertEqual(WildFields.spot(of: one).z, WildFields.spot(of: two).z)
        // Across is the first two bytes, along the next two.
        XCTAssertEqual(WildFields.spot(of: one).x, (Double(0x1234) + 0.5) / 65536 * 64)
        XCTAssertEqual(WildFields.spot(of: one).z, (Double(0x5678) + 0.5) / 65536 * 64)
    }

    func testThereAreEightTilesEachWay() {
        XCTAssertEqual(WildFields.tiles, 8)
        XCTAssertEqual(WildFields.tile * Double(WildFields.tiles), WildFields.side)
    }

    // MARK: The release

    func testAHybridIsReleasedWithItsLineageAndItsToken() throws {
        let record = hybrid(tokens: MeetingTokens(ours: Data(repeating: 7, count: 16),
                                                  theirs: Data(repeating: 8, count: 16)))
        let release = try XCTUnwrap(WildRelease(record: record))
        XCTAssertEqual(release.seed, record.seed.hex)
        XCTAssertEqual(release.parents.count, 2)
        XCTAssertEqual(release.token, String(repeating: "07", count: 16))
        XCTAssertEqual(release.theirs, String(repeating: "08", count: 16))

        // Exactly the five keys the service reads, and nothing grown: since 1
        // October 2026 the other phone's token goes too, so the other gardener
        // can be told and answer. Nothing shown is nothing sent.
        // Decoded by hand rather than through `JSONSerialization`, which the
        // WebAssembly build does not link (`VectorFile.Value`).
        let body = try JSONDecoder().decode([String: VectorFile.Value].self, from: JSONEncoder().encode(release))
        XCTAssertEqual(Set(body.keys), ["seed", "parents", "encounter", "token", "theirs"])
    }

    // MARK: Who stands beside it

    func testWhatIsChosenGoesWithTheRelease() throws {
        let record = hybrid(tokens: MeetingTokens(ours: Data(repeating: 7, count: 16),
                                                  theirs: Data(repeating: 8, count: 16)))
        let shown = WildShowing(name: "Wren", month: "2026-03")
        let release = try XCTUnwrap(WildRelease(record: record, shown: shown))
        XCTAssertEqual(release.shown, shown)
        let body = try JSONDecoder().decode([String: VectorFile.Value].self, from: JSONEncoder().encode(release))
        XCTAssertEqual(Set(body.keys), ["seed", "parents", "encounter", "token", "theirs", "shown"])
        // Anonymous is nothing sent rather than an empty object.
        XCTAssertNil(try XCTUnwrap(WildRelease(record: record, shown: .nothing)).shown)
    }

    func testNothingIsShownWithoutTheMeetingsTokens() throws {
        // No other gardener to tell, and no way to change it later.
        let release = try XCTUnwrap(WildRelease(record: hybrid(tokens: nil), shown: WildShowing(name: "Wren")))
        XCTAssertNil(release.shown)
        XCTAssertNil(release.theirs)
    }

    func testOnlyWhatIsChosenIsSentAndItIsTidied() {
        let choosing = WildShowing.choosing(WildChoice(name: true, place: false, month: true),
                                            name: "  Wren\u{202E} ", place: "On the winds", month: "2026-03")
        XCTAssertEqual(choosing, WildShowing(name: "Wren", place: nil, month: "2026-03"))
        XCTAssertEqual(choosing.choice, WildChoice(name: true, place: false, month: true))
        // Cut by whole characters, counted in code points as the service counts.
        let long = WildShowing.choosing(WildChoice(place: true), name: nil,
                                        place: String(repeating: "é", count: 70), month: nil)
        XCTAssertEqual(long.place?.unicodeScalars.count, WildShowing.placeLength)
        XCTAssertEqual(WildShowing.choosing(WildChoice(name: true), name: "   ", place: nil, month: nil), .nothing)
    }

    func testAMonthIsWrittenAsTheFieldShowsIt() {
        XCTAssertEqual(WildShowing.month(year: 2026, month: 3), "2026-03")
        XCTAssertEqual(WildShowing.month(year: 2026, month: 11), "2026-11")
    }

    /// The shape `WildStore::seen` answers in, so the two cannot drift apart
    /// without one side noticing.
    func testWhatTheServiceSaysIsRead() throws {
        let json = #"{"seed":"ab","token":"cd","released":false,"yours":{"name":false,"place":false,"month":false},"theirs":{"name":true,"place":true,"month":false},"shown":{"names":["Wren"],"place":null,"month":null}}"#
        let notice = try JSONDecoder().decode(WildNotice.self, from: Data(json.utf8))
        XCTAssertFalse(notice.released)
        XCTAssertEqual(notice.theirs, WildChoice(name: true, place: true))
        XCTAssertEqual(notice.shown, WildShown(names: ["Wren"]))
    }

    func testAGardenFromBeforeReleasedPlantsStillReads() throws {
        let old = #"{"schemaVersion":1,"plants":[]}"#
        let garden = try JSONDecoder().decode(Garden.self, from: Data(old.utf8))
        XCTAssertNil(garden.released)
    }

    func testAPlantFromBeforeTokensSendsNone() throws {
        let release = try XCTUnwrap(WildRelease(record: hybrid(tokens: nil)))
        XCTAssertNil(release.token)
        let body = try JSONDecoder().decode([String: VectorFile.Value].self, from: JSONEncoder().encode(release))
        XCTAssertNil(body["token"], "absent rather than null")
    }

    func testAMintedPlantHasNoRelease() {
        let record = PlantRecord(seed: SeedID(digest: seedDigest("test.minted", Data())),
                                 lineage: .minted, birth: Date(timeIntervalSince1970: 0))
        XCTAssertNil(WildRelease(record: record))
    }

    func testTheChildIsTheCrossOfWhatIsSent() throws {
        let record = hybrid(tokens: nil)
        let release = try XCTUnwrap(WildRelease(record: record))
        let a = try XCTUnwrap(SeedID(hex: release.parents[0]))
        let b = try XCTUnwrap(SeedID(hex: release.parents[1]))
        let encounter = try XCTUnwrap(Data(hexString: release.encounter))
        XCTAssertEqual(Pollination.cross(seedA: a, seedB: b, encounterID: encounter).hex, release.seed)
    }

    private func hybrid(tokens: MeetingTokens?) -> PlantRecord {
        let a = SeedID(digest: seedDigest("test.a", Data()))
        let b = SeedID(digest: seedDigest("test.b", Data()))
        let encounter = Pollination.encounterID(seedA: a, seedB: b,
                                                nonceA: Data(repeating: 3, count: 16),
                                                nonceB: Data(repeating: 4, count: 16))
        return PlantRecord(seed: Pollination.cross(seedA: a, seedB: b, encounterID: encounter),
                           lineage: .crossed(parentA: a, parentB: b, encounterID: encounter),
                           birth: Date(timeIntervalSince1970: 0), tokens: tokens)
    }
}
