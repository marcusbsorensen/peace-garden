import XCTest
@testable import SeedCore

/// Where a plant stands, and how a garden that has never heard of beds reads one.
///
/// Two of these guard properties that are invisible until they are wrong on
/// somebody's phone: a garden file written before this feature existed has to
/// keep opening, and `placed` has to encode as a JSON object rather than as the
/// flat array Swift reaches for by default.
final class ArrangingTests: XCTestCase {

    private func plant(_ label: String) -> PlantRecord {
        let seed = SeedID(bytes: seedDigest(SeedDomain.seed, Data(label.utf8)))!
        return PlantRecord(seed: seed, lineage: .minted, birth: Date())
    }

    // MARK: - Nothing migrates

    /// A garden written before beds existed. If this ever fails, every person
    /// who has used the app loses their seed, which is not recoverable.
    func testAGardenFromBeforeBedsExistedStillOpens() throws {
        let json = """
        {
          "schemaVersion": 1,
          "plants": [],
          "identity": {
            "seed": "\(SeedID(bytes: seedDigest(SeedDomain.seed, Data("old".utf8)))!.hex)",
            "birth": 700000000,
            "displayName": "Gardener"
          }
        }
        """

        let garden = try JSONDecoder().decode(Garden.self, from: Data(json.utf8))
        XCTAssertNil(garden.beds)
        XCTAssertEqual(garden.identity?.displayName, "Gardener")
        XCTAssertEqual(garden.schemaVersion, Garden.currentSchemaVersion,
                       "beds must not move the schema version")
    }

    /// And it is handed one bed rather than none, so nothing downstream has to
    /// hold an empty case.
    func testAGardenWithNoBedsIsGivenOne() {
        let garden = Garden()
        XCTAssertEqual(garden.arrangements.count, 1)
        XCTAssertEqual(garden.arrangements.first?.template, .thematic)
    }

    // MARK: - The dictionary is an object

    /// `JSONEncoder` writes a dictionary keyed by anything other than `String`
    /// or `Int` as a flat array of alternating keys and values. Keying `placed`
    /// by `uuidString` is what keeps a garden file readable by anything that is
    /// not Swift, and this is the test that says so.
    func testPlacementsEncodeAsAnObjectAndNotAsAnArray() throws {
        let rose = plant("rose")
        var bed = Bed(name: "", template: .colours)
        bed.place(rose, at: Spot(x: 1.25, z: -0.5))

        let data = try JSONEncoder().encode(bed)
        let any = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let placed = try XCTUnwrap(any?["placed"] as? [String: Any],
                                  "placed must be a JSON object, not an array")
        XCTAssertEqual(placed.count, 1)
        XCTAssertNotNil(placed[rose.id.uuidString])

        let back = try JSONDecoder().decode(Bed.self, from: data)
        XCTAssertEqual(back.spot(for: rose), Spot(x: 1.25, z: -0.5))
    }

    // MARK: - Sparse by design

    func testOnlyWhatWasMovedIsKept() {
        let a = plant("a"), b = plant("b")
        var bed = Bed(name: "", template: .meetings)
        XCTAssertNil(bed.spot(for: a))

        bed.place(a, at: Spot(x: 0.5, z: 0.5))
        XCTAssertEqual(bed.placed.count, 1, "b is the template's business, not the bed's")

        bed.putBack(a)
        XCTAssertTrue(bed.placed.isEmpty)

        bed.place(a, at: Spot(x: 1, z: 1))
        bed.place(b, at: Spot(x: 2, z: 2))
        bed.reset()
        XCTAssertTrue(bed.placed.isEmpty)
    }

    /// A spot pointing at a plant that has gone decodes perfectly and draws
    /// nothing, so it is dropped rather than carried.
    func testAPlacementOutlivingItsPlantIsForgotten() {
        let kept = plant("kept"), released = plant("released")
        var bed = Bed(name: "", template: .kinship)
        bed.place(kept, at: Spot(x: 0, z: 0))
        bed.place(released, at: Spot(x: 1, z: 1))

        bed.forget(absentFrom: [kept])
        XCTAssertEqual(bed.placed.count, 1)
        XCTAssertNotNil(bed.spot(for: kept))
        XCTAssertNil(bed.spot(for: released))
    }

    // MARK: - The plot

    /// The side goes as the square root of the count, so the ground each plant
    /// has to itself stays about the same however big the garden gets. Growing
    /// the side in proportion to the count would leave a large garden looking
    /// abandoned.
    func testThePlotGrowsWithItsGardenAndKeepsTheRoomPerPlantSteady() {
        func garden(hybrids: Int) -> Garden {
            let mine = SeedID(bytes: seedDigest(SeedDomain.seed, Data("mine".utf8)))!
            let plants = (0..<hybrids).map { i -> PlantRecord in
                let theirs = SeedID(bytes: seedDigest(SeedDomain.seed, Data("peer\(i)".utf8)))!
                let enc = Pollination.encounterID(seedA: mine, seedB: theirs,
                                                  nonceA: Data("a\(i)".utf8),
                                                  nonceB: Data("b\(i)".utf8))
                let child = Pollination.cross(seedA: mine, seedB: theirs, encounterID: enc)
                return PlantRecord(seed: child,
                                   lineage: .crossed(parentA: mine, parentB: theirs,
                                                     encounterID: enc),
                                   birth: Date())
            }
            return Garden(plants: plants)
        }

        XCTAssertEqual(garden(hybrids: 0).plotSide, Garden.smallestPlot,
                       "an empty garden still stands on something")
        XCTAssertEqual(garden(hybrids: 1).plotSide, Garden.smallestPlot,
                       accuracy: 1e-9)

        // Fixed against the mockup: fourteen plants read as a garden with room
        // to walk in it at 5.2 m.
        XCTAssertEqual(garden(hybrids: 14).plotSide, 5.2, accuracy: 0.02)

        // Four times the plants is twice the side, which is the whole point of
        // the square root.
        let small = garden(hybrids: 16).plotSide
        let large = garden(hybrids: 64).plotSide
        XCTAssertEqual(large / small, 2.0, accuracy: 1e-6)

        // And it never shrinks as the garden grows.
        var previous = 0.0
        for n in 0...40 {
            let side = garden(hybrids: n).plotSide
            XCTAssertGreaterThanOrEqual(side, previous)
            previous = side
        }
    }

    func testTheEdgeOnlyEverMovesOutward() {
        let far = Spot(x: 2.4, z: 2.4)
        let mine = SeedID(bytes: seedDigest(SeedDomain.seed, Data("mine".utf8)))!
        let small = Garden()
        XCTAssertFalse(small.holds(far), "a 2.2 m plot does not reach 2.4 m out")

        let many = (0..<64).map { i -> PlantRecord in
            let theirs = SeedID(bytes: seedDigest(SeedDomain.seed, Data("p\(i)".utf8)))!
            let enc = Pollination.encounterID(seedA: mine, seedB: theirs,
                                              nonceA: Data("a\(i)".utf8), nonceB: Data("b\(i)".utf8))
            return PlantRecord(seed: Pollination.cross(seedA: mine, seedB: theirs, encounterID: enc),
                               lineage: .crossed(parentA: mine, parentB: theirs, encounterID: enc),
                               birth: Date())
        }
        XCTAssertTrue(Garden(plants: many).holds(far))
    }

    // MARK: - The names are the file format

    /// A garden on disk names its template by these strings. Renaming a case
    /// drops every bed that used it back to the default without a compile error
    /// anywhere, so the spellings are pinned here as well as commented there.
    func testTheTemplateNamesAreStillTheOnesGardensWereSavedWith() {
        XCTAssertEqual(Set(Template.allCases.map(\.rawValue)),
                       ["thematic", "nightAndDay", "colours", "meetings", "kinship"])
    }

    func testABedSurvivesARoundTrip() throws {
        let a = plant("a")
        var bed = Bed(name: "Night", template: .nightAndDay)
        bed.place(a, at: Spot(x: -1.75, z: 0.25))

        let garden = Garden(plants: [a], beds: [bed])
        let data = try JSONEncoder().encode(garden)
        let back = try JSONDecoder().decode(Garden.self, from: data)

        XCTAssertEqual(back.beds?.count, 1)
        XCTAssertEqual(back.beds?.first?.template, .nightAndDay)
        XCTAssertEqual(back.beds?.first?.spot(for: a), Spot(x: -1.75, z: 0.25))
    }
}
