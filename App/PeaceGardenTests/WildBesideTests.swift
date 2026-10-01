import XCTest
import SeedCore
@testable import PeaceGarden

/// Who stands beside a released plant, on the phone (1 October 2026).
///
/// `check_wild_fields.php` holds the service to its half; this is the half
/// only a phone has:
///
/// - **What goes is what was chosen.** The releaser's three switches become
///   `shown`, with this phone's own name, place and month, and nothing at all
///   when nothing was chosen.
/// - **The releaser keeps a note**, so the choice can be changed after the
///   plant has gone.
/// - **The other phone hears of it on the poll it already makes**, once, and
///   not at all with *Alert me* off.
final class WildBesideTests: XCTestCase {

    private final class Stub: PlotTransport, @unchecked Sendable {
        var replies: [String: (status: Int, body: String)] = [:]
        private(set) var asked: [String] = []
        private(set) var bodies: [String: Data] = [:]

        func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
            let path = request.url?.path() ?? ""
            asked.append(path)
            bodies[path] = request.httpBody ?? Data()
            let answer = replies[path] ?? (status: 200, body: "{}")
            let response = HTTPURLResponse(url: request.url!, statusCode: answer.status,
                                           httpVersion: nil, headerFields: nil)!
            return (Data(answer.body.utf8), response)
        }
    }

    private var stub = Stub()

    override func setUp() {
        super.setUp()
        stub = Stub()
        UserDefaults.standard.removeObject(forKey: Sharing.invitationsKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: Sharing.invitationsKey)
        super.tearDown()
    }

    private let ours = Data(repeating: 0x11, count: 16)
    private let theirs = Data(repeating: 0x22, count: 16)

    private func plant() -> PlantRecord {
        let a = SeedID(bytes: seedDigest(SeedDomain.seed, Data("wild-a".utf8)))!
        let b = SeedID(bytes: seedDigest(SeedDomain.seed, Data("wild-b".utf8)))!
        let encounter = Pollination.encounterID(seedA: a, seedB: b,
                                                nonceA: Data("na".utf8), nonceB: Data("nb".utf8))
        let met = ISO8601DateFormatter().date(from: "2026-03-14T12:00:00Z")!
        return PlantRecord(
            seed: Pollination.cross(seedA: a, seedB: b, encounterID: encounter),
            lineage: .crossed(parentA: a, parentB: b, encounterID: encounter),
            birth: met,
            encounter: EncounterNote(peerDisplayName: "Ash", happenedAt: met, place: "On the winds"),
            tokens: MeetingTokens(ours: ours, theirs: theirs)
        )
    }

    @MainActor
    private func model(with plants: [PlantRecord]) -> GardenModel {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("wild-\(UUID().uuidString).json")
        let store = GardenStore(fileURL: file)
        let me = Identity(seed: SeedID(bytes: seedDigest(SeedDomain.seed, Data("me".utf8)))!,
                          birth: Date(timeIntervalSince1970: 0), displayName: "Wren")
        try? store.save(Garden(identity: me, plants: plants))
        return GardenModel(store: store,
                           plots: PlotService(transport: stub, origin: URL(string: "https://example.invalid")!))
    }

    private func notice(_ record: PlantRecord, released: Bool, yours: String = "false,false,false",
                        names: String = "[]") -> String {
        let y = yours.split(separator: ",")
        return #"{"seed":"\#(record.seed.hex)","token":"\#(MeetingTokens(ours: ours, theirs: theirs).oursHex)","released":\#(released),"yours":{"name":\#(y[0]),"place":\#(y[1]),"month":\#(y[2])},"theirs":{"name":true,"place":true,"month":true},"shown":{"names":\#(names),"place":null,"month":null}}"#
    }

    @MainActor
    func testWhatIsChosenGoesWithTheReleaseAndIsKept() async throws {
        let record = plant()
        let model = model(with: [record])
        stub.replies["/api/wild/release"] = (201, #"{"planting":{"seed":"\#(record.seed.hex)"},"beside":\#(notice(record, released: true, yours: "true,false,true", names: #"["Wren"]"#))}"#)

        let result = await model.release(record, showing: WildChoice(name: true, place: false, month: true))
        XCTAssertNoThrow(try result.get())

        let sent = try JSONDecoder().decode(WildRelease.self, from: XCTUnwrap(stub.bodies["/api/wild/release"]))
        XCTAssertEqual(sent.theirs, MeetingTokens(ours: ours, theirs: theirs).theirsHex)
        XCTAssertEqual(sent.shown, WildShowing(name: "Wren", place: nil, month: GardenModel.month(of: record.encounter!.happenedAt)))
        // Kept, so it can be changed after the plant has gone.
        XCTAssertEqual(model.garden.released?.count, 1)
        XCTAssertEqual(model.wildPlants.first?.releasedHere, true)
        XCTAssertEqual(model.wildPlants.first?.choice, WildChoice(name: true, place: false, month: true))
    }

    @MainActor
    func testNothingChosenIsNothingSent() async throws {
        let record = plant()
        let model = model(with: [record])
        stub.replies["/api/wild/release"] = (201, #"{"planting":{"seed":"\#(record.seed.hex)"},"beside":\#(notice(record, released: true))}"#)
        _ = await model.release(record)
        let body = String(decoding: try XCTUnwrap(stub.bodies["/api/wild/release"]), as: UTF8.self)
        XCTAssertFalse(body.contains("shown"), "anonymous is no shown at all")
        XCTAssertFalse(body.contains("Wren"))
    }

    @MainActor
    func testTheOtherPhoneHearsOnceOnThePollItAlreadyMakes() async {
        let record = plant()
        let model = model(with: [record])
        stub.replies["/api/walk/pending"] = (200, #"{"offers":[],"wild":[\#(notice(record, released: false, names: #"["Ash"]"#))]}"#)

        await model.catchUpOnTheAsking()

        XCTAssertEqual(model.wildToHear.count, 1)
        XCTAssertEqual(model.wildToHear.first?.peerDisplayName, "Ash")
        model.heard(model.wildToHear[0])
        XCTAssertTrue(model.wildToHear.isEmpty, "told once")
        XCTAssertNotNil(model.wildPlant(for: record), "and changed from the plant's own screen after")
    }

    @MainActor
    func testOffMeansTheWildFieldsAreNotAskedEither() async {
        UserDefaults.standard.set(false, forKey: Sharing.invitationsKey)
        let model = model(with: [plant()])
        await model.catchUpOnTheAsking()
        XCTAssertTrue(stub.asked.isEmpty)
    }

    @MainActor
    func testAnAnswerSendsTheWholeChoiceInThisPhonesWords() async throws {
        let record = plant()
        let model = model(with: [record])
        stub.replies["/api/walk/pending"] = (200, #"{"offers":[],"wild":[\#(notice(record, released: false))]}"#)
        await model.catchUpOnTheAsking()
        let wild = try XCTUnwrap(model.wildPlant(for: record))
        stub.replies["/api/wild/answer"] = (200, #"{"beside":\#(notice(record, released: false, yours: "true,true,true"))}"#)

        let result = await model.beside(wild, choosing: WildChoice(name: true, place: true, month: true))

        XCTAssertNoThrow(try result.get())
        let sent = String(decoding: try XCTUnwrap(stub.bodies["/api/wild/answer"]), as: UTF8.self)
        XCTAssertTrue(sent.contains("Wren") && sent.contains("On the winds") && sent.contains("2026-03"))
        XCTAssertEqual(model.wildPlant(for: record)?.choice, WildChoice(name: true, place: true, month: true))
    }
}
