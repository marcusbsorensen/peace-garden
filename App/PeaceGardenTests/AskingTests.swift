import XCTest
import SeedCore
@testable import PeaceGarden

/// The phone's side of the asking, with the service stood in for.
///
/// What is worth testing here is not the JSON — `SharingTests` pins that and
/// `tools/reference/check_offers.php` holds the service to it. It is the three
/// things that only exist on the phone:
///
/// - **Off means no request.** The switch has to stop the question, not the
///   answer, and that is one line that a later refactor could quietly undo.
/// - **One row, two sentences.** The same pending offer is an invitation on one
///   phone and a plant waiting on an answer on the other, and showing somebody
///   a question they themselves asked would be the visible failure.
/// - **A plant's standing is not moved by a service that did not answer.**
final class AskingTests: XCTestCase {

    // MARK: A service that never leaves the room

    /// Answers whatever it is told to, and remembers every request it was given.
    private final class Stub: PlotTransport, @unchecked Sendable {
        var replies: [String: (status: Int, body: String)] = [:]
        private(set) var asked: [String] = []
        private(set) var bodies: [String] = []
        private(set) var methods: [String] = []

        func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
            let path = request.url?.path() ?? ""
            asked.append(path)
            methods.append(request.httpMethod ?? "")
            bodies.append(String(decoding: request.httpBody ?? Data(), as: UTF8.self))
            let answer = replies[path] ?? (status: 200, body: "{}")
            let response = HTTPURLResponse(
                url: request.url!, statusCode: answer.status, httpVersion: nil, headerFields: nil
            )!
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

    @MainActor
    private func model(with plants: [PlantRecord] = []) -> GardenModel {
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("asking-\(UUID().uuidString).json")
        let store = GardenStore(fileURL: file)
        try? store.save(Garden(identity: nil, plants: plants))
        return GardenModel(
            store: store,
            plots: PlotService(transport: stub, origin: URL(string: "https://example.invalid")!)
        )
    }

    // MARK: Which areas are open

    /// The ten as the service answers them, with these ones open.
    private func gardenJSON(open: [String]) -> String {
        let rows = ["beginnings", "waiting", "renewal", "light", "pattern",
                    "ground", "travel", "meeting", "kinship", "peace"]
            .map { #"{"area":"\#($0)","open":\#(open.contains($0))}"# }
        return #"{"areas":[\#(rows.joined(separator: ","))]}"#
    }

    /// **The app believes the service, not itself.** This is the whole point:
    /// the garden is planted one area at a time by somebody who is not shipping
    /// an app, so a phone that read its own list learned that an area had
    /// opened when it was next updated.
    @MainActor
    func testItAsksTheGardenWhichAreasAreOpen() async {
        let model = model()
        stub.replies["/api/garden"] = (200, gardenJSON(open: ["travel", "peace"]))

        let open = await model.openAreas()

        XCTAssertEqual(stub.asked, ["/api/garden"])
        XCTAssertEqual(open.areas, [.travel, .peace])
    }

    /// An area this build has never heard of is shut as far as it is concerned,
    /// and is dropped rather than read as the Long Walk the way a stored record
    /// would be. A list with an eleventh area in it must not open a tenth.
    @MainActor
    func testAnAreaThisBuildHasNeverHeardOfIsIgnoredRatherThanGuessedAt() async {
        let model = model()
        stub.replies["/api/garden"] = (200, #"{"areas":[{"area":"travel","open":true},{"area":"orangery","open":true}]}"#)

        let open = await model.openAreas()

        XCTAssertEqual(open.areas, [.travel])
    }

    /// **And it believes it when the answer is fewer.** A build that shipped
    /// with an area open must stop offering to it if the service closes it,
    /// which is the half a compiled list could never do.
    @MainActor
    func testAnAreaThisBuildThinksIsOpenClosesWhenTheServiceSaysSo() async {
        let model = model()
        XCTAssertTrue(OpenAreas.builtIn.has(.travel), "this build ships with travel open")
        stub.replies["/api/garden"] = (200, gardenJSON(open: []))

        let open = await model.openAreas()

        XCTAssertFalse(open.has(.travel))
    }

    /// Unreachable, refused or unreadable, the answer is what this build was
    /// compiled believing — which says *not yet* about anything it has not
    /// heard of, so it cannot promise a planting the service would refuse.
    @MainActor
    func testWhenTheServiceCannotBeReachedItFallsBackToItsOwnList() async {
        for reply in [(503, "nothing doing"), (200, "{}"), (200, #"{"areas":[]}"#)] {
            stub = Stub()
            let model = model()
            stub.replies["/api/garden"] = reply

            let open = await model.openAreas()

            XCTAssertEqual(open, .builtIn, "\(reply) should have fallen back")
        }
    }

    /// **Once a session, not once a screen.** A gardener opening the question
    /// for four plants in a row is one request.
    @MainActor
    func testItAsksOnceAndKeepsTheAnswer() async {
        let model = model()
        stub.replies["/api/garden"] = (200, gardenJSON(open: ["travel"]))

        _ = await model.openAreas()
        _ = await model.openAreas()
        _ = await model.openAreas()

        XCTAssertEqual(stub.asked, ["/api/garden"])
    }

    /// It carries nothing: no token, no seed, no body. The one request in this
    /// app that says nothing about the person making it.
    @MainActor
    func testTheQuestionCarriesNothing() async {
        let model = model()
        stub.replies["/api/garden"] = (200, gardenJSON(open: ["travel"]))

        _ = await model.openAreas()

        XCTAssertEqual(stub.bodies, [""])
        XCTAssertEqual(stub.methods, ["GET"])
    }

    /// **The reply it reads is the reply the service sends.**
    ///
    /// The JSON above is written by hand, which is the way an app test drifts
    /// from a service: both sides go on passing their own tests while agreeing
    /// about nothing. `tools/reference/area_vectors.json` is what SeedCore says
    /// the garden is and what `check_areas.php` holds `Areas.php` to, so this
    /// builds `GET /api/garden`'s answer out of it and reads that instead.
    ///
    /// It pins the **shape**, not the agreement: the two lists are allowed to
    /// differ — that is the whole point of asking — but the app has to be able
    /// to read whatever the service sends.
    @MainActor
    func testItCanReadWhatTheServiceActuallySends() async throws {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<3 { url.deleteLastPathComponent() }   // …/App/PeaceGardenTests/<this>
        url.appendPathComponent("tools/reference/area_vectors.json")
        guard let data = try? Data(contentsOf: url) else {
            throw XCTSkip("tools/reference/area_vectors.json is not beside this checkout")
        }

        struct Row: Decodable { var area: String; var open: Bool }
        let rows = try JSONDecoder().decode([Row].self, from: data)
        let sent = rows.map { #"{"area":"\#($0.area)","open":\#($0.open)}"# }

        let model = model()
        stub.replies["/api/garden"] = (200, #"{"areas":[\#(sent.joined(separator: ","))]}"#)

        let open = await model.openAreas()

        XCTAssertEqual(open.areas, Set(rows.filter(\.open).compactMap { Area(rawValue: $0.area) }))
        XCTAssertFalse(open.areas.isEmpty, "the reference says no area is open")
    }

    // MARK: Offering

    @MainActor
    func testOfferingAPlantLeavesItWaitingOnTheOtherGardener() async throws {
        let plant = hybrid()
        let model = model(with: [plant])
        stub.replies["/api/walk/offer"] = (200, offerJSON(plant, state: "offered"))

        let result = await model.offer(plant)

        XCTAssertEqual(stub.asked, ["/api/walk/offer"])
        XCTAssertEqual(try result.get().state, .asked)
        XCTAssertEqual(model.garden.plants[0].standingOrHere.state, .asked)
        // And it cannot be asked about a second time, which is what makes the
        // other gardener's no final.
        XCTAssertFalse(model.garden.plants[0].canBeOffered)
    }

    @MainActor
    func testAnOfferIsAddressedToTheTokenTheOtherGardenerMinted() async throws {
        let plant = hybrid()
        let model = model(with: [plant])
        stub.replies["/api/walk/offer"] = (200, offerJSON(plant, state: "offered"))

        await model.offer(plant)

        let body = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(stub.bodies[0].utf8)) as? [String: Any]
        )
        XCTAssertEqual(body["to"] as? String, plant.tokens?.theirsHex)
        XCTAssertEqual(body["from"] as? String, plant.tokens?.oursHex)
        // The plant goes with it, because the service cannot grow one.
        let sent = try XCTUnwrap(body["plant"] as? [String: Any])
        XCTAssertEqual(sent["seed"] as? String, plant.seed.hex)
        // With what three areas place by and the service cannot measure: the
        // Glasshouse's hue, and the habit the Coppice and the Home Ground read.
        // A build without them sows every Home Ground arrival as an umbel.
        let traits = LongWalk.traits(of: plant.genome)
        XCTAssertEqual(sent["habit"] as? String, traits.habit)
        XCTAssertFalse(traits.habit.isEmpty)
        XCTAssertEqual(try XCTUnwrap(sent["hue"] as? Double), try XCTUnwrap(traits.hue), accuracy: 1e-9)
        XCTAssertEqual(try XCTUnwrap(sent["height"] as? Double), traits.height, accuracy: 1e-9)
    }

    @MainActor
    func testAPlantFromAMeetingWithNoTokensIsNeverOffered() async {
        let plant = hybrid(remembersTheMeeting: false)
        let model = model(with: [plant])

        let result = await model.offer(plant)

        XCTAssertTrue(stub.asked.isEmpty, "nothing should have been sent")
        if case .success = result { XCTFail("a meeting with no tokens cannot be offered") }
    }

    // MARK: Answering

    @MainActor
    func testSayingYesPutsItInTheGarden() async throws {
        let plant = hybrid(standing: Standing(state: .invited, changedAt: .distantPast))
        let model = model(with: [plant])
        stub.replies["/api/walk/answer"] = (200, offerJSON(plant, state: "accepted"))

        let result = await model.answer(plant, yes: true)

        XCTAssertEqual(try result.get().state, .shown)
        XCTAssertEqual(model.shown.count, 1)
    }

    @MainActor
    func testSayingNoIsFinal() async throws {
        let plant = hybrid(standing: Standing(state: .invited, changedAt: .distantPast))
        let model = model(with: [plant])
        stub.replies["/api/walk/answer"] = (200, offerJSON(plant, state: "declined"))

        let result = await model.answer(plant, yes: false)

        XCTAssertEqual(try result.get().state, .declined)
        XCTAssertFalse(model.garden.plants[0].canBeOffered)
        XCTAssertTrue(model.shown.isEmpty)
    }

    @MainActor
    func testAnAnswerIsSignedWithOurOwnToken() async throws {
        let plant = hybrid(standing: Standing(state: .invited, changedAt: .distantPast))
        let model = model(with: [plant])
        stub.replies["/api/walk/answer"] = (200, offerJSON(plant, state: "accepted"))

        await model.answer(plant, yes: true)

        let body = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(stub.bodies[0].utf8)) as? [String: Any]
        )
        // Ours, because an offer is addressed to the token its recipient minted
        // and this phone is the recipient.
        XCTAssertEqual(body["to"] as? String, plant.tokens?.oursHex)
        XCTAssertEqual(body["yes"] as? Bool, true)
    }

    // MARK: Taking it back

    @MainActor
    func testEitherGardenerCanTakeItBack() async throws {
        let plant = hybrid(standing: Standing(state: .shown, changedAt: .distantPast))
        let model = model(with: [plant])
        stub.replies["/api/walk/withdraw"] = (200, offerJSON(plant, state: "withdrawn"))

        let result = await model.withdraw(plant)

        XCTAssertEqual(try result.get().state, .withdrawn)
        XCTAssertTrue(model.shown.isEmpty)
        // It does not go back: there was one offer for this plant and that was it.
        XCTAssertFalse(model.garden.plants[0].canBeOffered)
    }

    // MARK: Catching up

    @MainActor
    func testOffMeansNoRequestAtAll() async {
        UserDefaults.standard.set(false, forKey: Sharing.invitationsKey)
        let model = model(with: [hybrid()])

        await model.catchUpOnTheAsking()

        XCTAssertTrue(stub.asked.isEmpty, "off has to stop the question, not the answer")
    }

    @MainActor
    func testAGardenWithNothingToAskAboutAsksNothing() async {
        let model = model(with: [hybrid(remembersTheMeeting: false)])
        await model.catchUpOnTheAsking()
        XCTAssertTrue(stub.asked.isEmpty)
    }

    @MainActor
    func testAnOfferAddressedToUsReadsAsAnInvitation() async {
        let plant = hybrid()
        let model = model(with: [plant])
        // Addressed *to* our own token: somebody else asked.
        stub.replies["/api/walk/pending"] = (200, """
        {"offers":[{"seed":"\(plant.seed.hex)","to":"\(plant.tokens!.oursHex)",
          "from":"\(plant.tokens!.theirsHex)","state":"offered","offeredAt":1,"answeredAt":null}]}
        """)

        await model.catchUpOnTheAsking()

        XCTAssertEqual(model.garden.plants[0].standingOrHere.state, .invited)
        XCTAssertEqual(model.invited.count, 1)
    }

    @MainActor
    func testTheSameRowReadTheOtherWayRoundIsOurOwnAsking() async {
        let plant = hybrid()
        let model = model(with: [plant])
        // Addressed to *their* token: we asked, and they have not answered.
        stub.replies["/api/walk/pending"] = (200, pendingJSON(plant, state: "offered"))

        await model.catchUpOnTheAsking()

        XCTAssertEqual(model.garden.plants[0].standingOrHere.state, .asked)
        XCTAssertTrue(model.invited.isEmpty)
    }

    @MainActor
    func testAnOfferAboutSomebodyElsesMeetingIsIgnored() async {
        let plant = hybrid()
        let model = model(with: [plant])
        stub.replies["/api/walk/pending"] = (200, """
        {"offers":[{"seed":"\(plant.seed.hex)","to":"\(String(repeating: "cd", count: 16))",
          "from":"\(String(repeating: "ef", count: 16))","state":"accepted","offeredAt":1,"answeredAt":2}]}
        """)

        await model.catchUpOnTheAsking()

        XCTAssertEqual(model.garden.plants[0].standingOrHere.state, .here)
    }

    /// **A withdrawal the other gardener made is still heard.** The service
    /// erases a withdrawn offer and can no longer say which seed it was about,
    /// so it answers with an empty seed and the token this phone asked with.
    @MainActor
    func testAWithdrawalWithNoSeedIsFoundByOurOwnToken() async {
        var plant = hybrid()
        plant.standing = Standing(state: .shown, changedAt: Date(timeIntervalSince1970: 1))
        let model = model(with: [plant])
        stub.replies["/api/walk/pending"] = (200, """
        {"offers":[{"seed":"","to":"","from":"\(plant.tokens!.oursHex)",
          "state":"withdrawn","offeredAt":1,"answeredAt":2}]}
        """)

        await model.catchUpOnTheAsking()

        XCTAssertEqual(model.garden.plants[0].standingOrHere.state, .withdrawn)
    }

    @MainActor
    func testARowWithNoSeedAndNoTokenOfOursIsIgnored() async {
        var plant = hybrid()
        plant.standing = Standing(state: .shown, changedAt: Date(timeIntervalSince1970: 1))
        let model = model(with: [plant])
        stub.replies["/api/walk/pending"] = (200, """
        {"offers":[{"seed":"","to":"\(String(repeating: "cd", count: 16))","from":"",
          "state":"withdrawn","offeredAt":1,"answeredAt":2}]}
        """)

        await model.catchUpOnTheAsking()

        XCTAssertEqual(model.garden.plants[0].standingOrHere.state, .shown)
    }

    @MainActor
    func testAServiceThatCannotAnswerLeavesThePlantWhereItWas() async {
        let plant = hybrid()
        let model = model(with: [plant])
        stub.replies["/api/walk/pending"] = (500, #"{"error":"The plot service could not answer."}"#)

        await model.catchUpOnTheAsking()

        XCTAssertEqual(model.garden.plants[0].standingOrHere.state, .here)
        XCTAssertTrue(model.garden.plants[0].canBeOffered)
    }

    @MainActor
    func testARefusedOfferIsReportedAndChangesNothing() async {
        let plant = hybrid()
        let model = model(with: [plant])
        stub.replies["/api/walk/offer"] = (422, #"{"error":"That seed is not the cross of those parents at that meeting."}"#)

        let result = await model.offer(plant)

        guard case let .failure(trouble) = result else { return XCTFail("a 422 is not a success") }
        XCTAssertEqual(trouble, .refused(status: 422, said: "That seed is not the cross of those parents at that meeting."))
        XCTAssertEqual(model.garden.plants[0].standingOrHere.state, .here)
    }

    // MARK: Which area it is offered to

    /// The area on the wire is the plant's own, and the way to prove it is a
    /// plant that does not belong to travel — otherwise *it sent the right
    /// area* and *it sent travel, as it always did* are the same answer.
    @MainActor
    func testTheOfferCarriesThePlantsOwnAreaRatherThanAlwaysTheLongWalk() async {
        guard let outsider = (0..<40).map({ hybrid("area-\($0)") })
            .first(where: { Arrangement.area(of: $0) != .travel })
        else { return XCTFail("forty crossings and every one of them travel") }
        let model = model(with: [outsider])

        await model.offer(outsider)

        let area = Arrangement.area(of: outsider).rawValue
        XCTAssertEqual(stub.bodies.count, 1)
        XCTAssertTrue(stub.bodies[0].contains("\"area\":\"\(area)\""), stub.bodies[0])
    }

    /// A service that says the area is shut leaves the plant where it was, the
    /// same as any other refusal. The screen keeps it from getting this far;
    /// an app older than the service's list of open areas would not.
    @MainActor
    func testAnAreaThatIsNotPlantedYetIsRefusedAndChangesNothing() async {
        let plant = hybrid()
        let model = model(with: [plant])
        stub.replies["/api/walk/offer"] = (409, #"{"error":"That area of the garden is not open yet."}"#)

        let result = await model.offer(plant)

        guard case let .failure(trouble) = result else { return XCTFail("a 409 is not a success") }
        XCTAssertEqual(trouble, .refused(status: 409, said: "That area of the garden is not open yet."))
        XCTAssertEqual(model.garden.plants[0].standingOrHere.state, .here)
        XCTAssertTrue(model.garden.plants[0].canBeOffered)
    }

    // MARK: Starting again

    @MainActor
    func testOnlyWhatTheGardenIsStillHoldingIsInTheAsking() {
        let model = model(with: [
            hybrid("shown", standing: Standing(state: .shown, changedAt: .distantPast)),
            hybrid("asked", standing: Standing(state: .asked, changedAt: .distantPast)),
            hybrid("invited", standing: Standing(state: .invited, changedAt: .distantPast)),
            // Settled, so there is nothing left to take back.
            hybrid("declined", standing: Standing(state: .declined, changedAt: .distantPast)),
            hybrid("withdrawn", standing: Standing(state: .withdrawn, changedAt: .distantPast)),
            hybrid("here"),
            // Never reached the service at all.
            hybrid("untokened", remembersTheMeeting: false,
                   standing: Standing(state: .shown, changedAt: .distantPast)),
        ])

        XCTAssertEqual(model.stillInTheAsking.count, 3)
    }

    @MainActor
    func testStartingAgainAsksTheGardenToLetGoOfEverythingFirst() async {
        // The failure this prevents: the contact tokens live in this garden and
        // nowhere else, so wiping it while a plant is standing leaves the plant
        // standing for good, with no phone anywhere able to take it down.
        let model = model(with: [
            hybrid("shown", standing: Standing(state: .shown, changedAt: .distantPast)),
            hybrid("asked", standing: Standing(state: .asked, changedAt: .distantPast)),
            hybrid("here"),
        ])
        stub.replies["/api/walk/withdraw"] = (200, offerJSON(hybrid("shown"), state: "withdrawn"))

        let left = await model.takeEverythingBack()

        XCTAssertTrue(left.isEmpty)
        XCTAssertEqual(stub.asked.filter { $0 == "/api/walk/withdraw" }.count, 2)
        XCTAssertTrue(model.stillInTheAsking.isEmpty)
    }

    @MainActor
    func testAPlantTheGardenWillNotLetGoOfIsHandedBackRatherThanForgotten() async {
        let model = model(with: [
            hybrid("shown", standing: Standing(state: .shown, changedAt: .distantPast)),
        ])
        stub.replies["/api/walk/withdraw"] = (503, "")

        let left = await model.takeEverythingBack()

        // The caller is told, and the plant is still standing — which is what
        // stops Settings resetting anything.
        XCTAssertEqual(left.count, 1)
        XCTAssertEqual(model.shown.count, 1)
    }

    // MARK: Fixtures

    private let mine = SeedID(bytes: seedDigest(SeedDomain.seed, Data("asking-mine".utf8)))!

    private func hybrid(_ named: String = "asking-theirs",
                        remembersTheMeeting: Bool = true, standing: Standing? = nil) -> PlantRecord {
        let theirs = SeedID(bytes: seedDigest(SeedDomain.seed, Data(named.utf8)))!
        let encounter = Pollination.encounterID(
            seedA: mine, seedB: theirs,
            nonceA: Data("nonce-a".utf8), nonceB: Data("nonce-b".utf8)
        )
        return PlantRecord(
            seed: Pollination.cross(seedA: mine, seedB: theirs, encounterID: encounter),
            lineage: .crossed(parentA: mine, parentB: theirs, encounterID: encounter),
            birth: Date(timeIntervalSince1970: 0),
            tokens: remembersTheMeeting
                ? MeetingTokens(ours: Data(repeating: 0x11, count: 16),
                                theirs: Data(repeating: 0x22, count: 16))
                : nil,
            standing: standing
        )
    }

    /// The service's answer about a plant this phone offered.
    private func offerJSON(_ plant: PlantRecord, state: String) -> String {
        """
        {"offer":\(row(plant, state: state))}
        """
    }

    /// The same row, as `/pending` returns it: a list, because a phone asks
    /// about its whole garden at once.
    private func pendingJSON(_ plant: PlantRecord, state: String) -> String {
        """
        {"offers":[\(row(plant, state: state))]}
        """
    }

    private func row(_ plant: PlantRecord, state: String) -> String {
        """
        {"seed":"\(plant.seed.hex)","to":"\(plant.tokens?.theirsHex ?? "")",
          "from":"\(plant.tokens?.oursHex ?? "")","state":"\(state)","offeredAt":1,"answeredAt":2}
        """
    }
}
