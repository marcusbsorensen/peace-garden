import XCTest
@testable import SeedCore

final class GardenStoreTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PeaceGardenTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeStore() -> GardenStore {
        GardenStore(fileURL: directory.appendingPathComponent("garden.json"))
    }

    func testAnEmptyStoreReadsAsAnEmptyGarden() throws {
        let garden = try makeStore().load()
        XCTAssertNil(garden.identity)
        XCTAssertTrue(garden.plants.isEmpty)
    }

    func testGardenSurvivesARoundTrip() throws {
        let store = makeStore()
        let seed = SeedMint.mint(fromEntropy: Data("round-trip".utf8))
        let partner = SeedMint.mint(fromEntropy: Data("partner".utf8))
        let encounterID = Pollination.encounterID(
            seedA: seed, seedB: partner,
            nonceA: Data(repeating: 1, count: 16), nonceB: Data(repeating: 2, count: 16)
        )
        let child = Pollination.cross(seedA: seed, seedB: partner, encounterID: encounterID)

        let garden = Garden(
            identity: Identity(seed: seed, birth: Date(timeIntervalSince1970: 1_700_000_000), displayName: "Marcus"),
            plants: [
                PlantRecord(
                    seed: child,
                    lineage: .crossed(parentA: seed, parentB: partner, encounterID: encounterID),
                    birth: Date(timeIntervalSince1970: 1_700_100_000),
                    savedAt: Date(timeIntervalSince1970: 1_700_100_500),
                    encounter: EncounterNote(
                        peerDisplayName: "Ada",
                        happenedAt: Date(timeIntervalSince1970: 1_700_100_000),
                        showsDateTime: true,
                        place: "Rye harbour",
                        note: "Waiting for the tide."
                    )
                )
            ]
        )

        try store.save(garden)
        let loaded = try store.load()
        XCTAssertEqual(loaded, garden)
        XCTAssertEqual(loaded.hybrids.count, 1)
        // The plant redraws from the seed alone - nothing about its appearance
        // is stored, so it cannot drift from what was saved.
        XCTAssertEqual(loaded.plants[0].genome, garden.plants[0].genome)
    }

    func testNotesAreTrimmedToTheirLimit() {
        let note = EncounterNote(
            peerDisplayName: "Ada",
            happenedAt: Date(),
            note: String(repeating: "x", count: EncounterNote.noteCharacterLimit + 100)
        )
        XCTAssertEqual(note.note?.count, EncounterNote.noteCharacterLimit)
    }

    func testAGardenFromANewerVersionIsRefusedRatherThanOverwritten() throws {
        let store = makeStore()
        let payload = """
        {"schemaVersion": 99, "plants": []}
        """
        try Data(payload.utf8).write(to: store.fileURL)
        XCTAssertThrowsError(try store.load()) { error in
            guard case GardenStore.StoreError.unsupportedSchema(let found) = error else {
                return XCTFail("unexpected error \(error)")
            }
            XCTAssertEqual(found, 99)
        }
    }

    func testExchangeEnvelopeSurvivesEncoding() throws {
        let card = PollenCard(
            seed: SeedMint.mint(fromEntropy: Data("card".utf8)),
            displayName: "Marcus",
            plantName: "Aurelia nocturna",
            birth: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let envelope = ExchangeEnvelope.hello(card: card, nonce: Data(repeating: 4, count: 16))
        let decoded = try ExchangeEnvelope.decode(envelope.encoded())
        XCTAssertEqual(decoded.kind, .hello)
        XCTAssertEqual(decoded.card, card)
        XCTAssertEqual(decoded.protocolVersion, ExchangeProtocol.version)
    }

    func testAnUnknownMessageKindDecodesInsteadOfThrowing() throws {
        // A future version may send message types this build has never seen; it
        // has to recognise them as unknown and abort, not crash the exchange.
        let payload = """
        {"protocolVersion": 99, "kind": "pollen-storm"}
        """
        let decoded = try ExchangeEnvelope.decode(Data(payload.utf8))
        XCTAssertEqual(decoded.kind, .unknown)
        XCTAssertEqual(decoded.protocolVersion, 99)
    }
}
