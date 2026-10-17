import CryptoKit
import SeedCore
import XCTest
@testable import PeaceGarden

/// The launch request of Zone C (package A3): what its two slots carry, what
/// is done once the service has answered, and the promises Marcus made about
/// consent (`DESIGN.md` §7, item 16) and the one risk the design had not
/// foreseen (R2, a lost answer).
///
/// The service is `AskingTests.Stub`; the suite's folder is a temporary
/// directory; the sink for the bundles records what it is given. Nothing here
/// touches a network, the real App Group or the real `UserDefaults` key for
/// Zone C's switch.
final class ZoneCExchangeTests: XCTestCase {

    // MARK: Things that stand in

    /// A value several threads may read and write.
    private final class Box<Value: Sendable>: @unchecked Sendable {
        private let lock = NSLock()
        private var stored: Value

        init(_ value: Value) { stored = value }

        var value: Value {
            get { lock.withLock { stored } }
            set { lock.withLock { stored = newValue } }
        }
    }

    /// Everything the exchange hands on, in order.
    private final class Sink: ZoneCBundles, @unchecked Sendable {
        struct Call: Equatable {
            var aloft: [Data]
            var back: [Data]
        }

        private let lock = NSLock()
        private var all: [Call] = []

        func receive(aloft: [Data], back: [Data]) async {
            lock.withLock { all.append(Call(aloft: aloft, back: back)) }
        }

        var calls: [Call] { lock.withLock { all } }
    }

    private var stub = AskingTests.Stub()
    private var sink = Sink()
    private var zoneCIsOn = Box(false)
    private var root = URL(fileURLWithPath: "/")
    private var directory = URL(fileURLWithPath: "/")
    private var store: ZoneCStore!

    /// Two sent seeds. Their file names sort the other way round from their
    /// bytes and from the order they are written, so that "first by name" is the
    /// only order that gives the answer.
    private let r1 = "00112233445566778899aabbccddeeff"
    private let r2 = "ffeeddccbbaa99887766554433221100"
    private let name1 = "11111111111111111111111111111111"
    private let name2 = "22222222222222222222222222222222"

    private let recipient = Curve25519.KeyAgreement.PrivateKey()

    override func setUpWithError() throws {
        try super.setUpWithError()
        stub = AskingTests.Stub()
        sink = Sink()
        zoneCIsOn = Box(false)
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent("zonec-exchange-\(UUID().uuidString)", isDirectory: true)
        root = base.appendingPathComponent("suite", isDirectory: true)
        directory = base.appendingPathComponent("app", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        store = makeStore()
        UserDefaults.standard.removeObject(forKey: Sharing.invitationsKey)
        UserDefaults.standard.removeObject(forKey: ZoneCExchange.enabledKey)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root.deletingLastPathComponent())
        UserDefaults.standard.removeObject(forKey: Sharing.invitationsKey)
        UserDefaults.standard.removeObject(forKey: ZoneCExchange.enabledKey)
        try super.tearDownWithError()
    }

    private var storeFile: URL { directory.appendingPathComponent(ZoneCStore.fileName) }

    /// Atomic and unprotected, as `ZoneCStoreTests` has it: nothing here tests
    /// file protection.
    private func makeStore() -> ZoneCStore {
        ZoneCStore(fileURL: storeFile, writeOptions: [.atomic])
    }

    private func exchange(store: ZoneCStore? = nil) -> ZoneCExchange {
        let switchIsOn = zoneCIsOn
        return ZoneCExchange(
            transit: SuiteTransit(group: SuiteGroup(container: DirectoryContainer(url: root))),
            store: store ?? self.store,
            bundles: sink,
            isOn: { switchIsOn.value }
        )
    }

    private func plots() -> PlotService {
        PlotService(transport: stub, origin: URL(string: "https://example.invalid")!)
    }

    private func ask(_ tokens: [String] = []) async throws -> PlotService.Pending {
        try await exchange().ask(plots: plots(), tokens: tokens)
    }

    // MARK: The other app, and the folder

    private func outFile(_ name: String) -> URL {
        root.appendingPathComponent("Seeds/v1/out").appendingPathComponent(name)
    }

    /// What Autonaut does when the person sends a seed.
    private func autonautSends(_ r: String, named name: String) {
        writeToOut(#"{"v":1,"r":"\#(r)"}"#, named: name)
    }

    private func writeToOut(_ text: String, named name: String) {
        let folder = root.appendingPathComponent("Seeds/v1/out")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try? Data(text.utf8).write(to: folder.appendingPathComponent(name))
    }

    private func outNames() -> [String] {
        let folder = root.appendingPathComponent("Seeds/v1/out").path
        return ((try? FileManager.default.contentsOfDirectory(atPath: folder)) ?? []).sorted()
    }

    private func hex(_ data: Data) -> String { SuiteHex.encode(data) }

    /// `r ‖ mark`, as the slot carries it.
    private func spaceSeed(_ r: String) -> Data {
        ZoneCMark.spaceSeed(from: SuiteHex.decode(r, byteCount: 16)!)!
    }

    // MARK: What the request said

    private func body(_ request: Int) throws -> [String: Any] {
        try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(stub.bodies[request].utf8)) as? [String: Any]
        )
    }

    /// A slot exactly as it was sent: the text, which is lowercase hex of the
    /// right length or `nil`.
    private func slotText(_ request: Int, _ field: String) throws -> String {
        try XCTUnwrap(try body(request)[field] as? String)
    }

    private func aloftBytes(_ request: Int) throws -> Data {
        try XCTUnwrap(ZoneCSlots.bytes(fromHex: try slotText(request, "aloft"), as: .aloft))
    }

    private func backBytes(_ request: Int) throws -> Data {
        try XCTUnwrap(ZoneCSlots.bytes(fromHex: try slotText(request, "back"), as: .back))
    }

    // MARK: Zone C's records

    private func sentRecords() throws -> [ZoneCSentSeed] { try store.load().sentSeeds }

    private func owed(sendsLeft: Int = 8) -> ZoneCOwedReturn {
        ZoneCOwedReturn(
            payload: Data((0..<56).map { UInt8($0) }),
            recipientKey: recipient.publicKey.rawRepresentation,
            spaceSeed: ZoneCMark.spaceSeed(from: Data(repeating: 0x5a, count: 16))!,
            sendsLeft: sendsLeft
        )!
    }

    /// A record as one earlier launch left it.
    private func record(_ n: UInt8, launchesLeft: Int = ZoneCSentSeed.launchesAtStart) -> ZoneCSentSeed {
        ZoneCSentSeed(
            r: Data(repeating: n, count: 16),
            privateKey: Curve25519.KeyAgreement.PrivateKey().rawRepresentation,
            launchesLeft: launchesLeft
        )!
    }

    // MARK: A garden with meetings

    @MainActor
    private func model(meetings: Int) throws -> GardenModel {
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("zonec-garden-\(UUID().uuidString).json")
        let garden = GardenStore(fileURL: file, writeOptions: [.atomic])
        let mine = SeedID(bytes: seedDigest(SeedDomain.seed, Data("zonec-mine".utf8)))!
        let plants = (0..<meetings).map { index -> PlantRecord in
            let theirs = SeedID(bytes: seedDigest(SeedDomain.seed, Data("zonec-theirs-\(index)".utf8)))!
            let encounter = Pollination.encounterID(
                seedA: mine, seedB: theirs,
                nonceA: Data("a\(index)".utf8), nonceB: Data("b\(index)".utf8)
            )
            // A token for each meeting, and different for each.
            let ours = Data([UInt8(index >> 8), UInt8(index & 0xff)] + Array(repeating: 0x11, count: 14))
            return PlantRecord(
                seed: Pollination.cross(seedA: mine, seedB: theirs, encounterID: encounter),
                lineage: .crossed(parentA: mine, parentB: theirs, encounterID: encounter),
                birth: Date(timeIntervalSince1970: 0),
                tokens: MeetingTokens(ours: ours, theirs: Data(repeating: 0x22, count: 16))
            )
        }
        try garden.save(Garden(identity: nil, plants: plants))
        return GardenModel(store: garden, plots: plots())
    }

    // MARK: - Every phone asks

    @MainActor
    func testAGardenWithNoMeetingsAsksWithBothSlotsFull() async throws {
        let model = try model(meetings: 0)

        await model.catchUpOnTheAsking(zoneC: exchange())

        XCTAssertEqual(stub.asked, ["/api/walk/pending"])
        XCTAssertEqual(try body(0)["tokens"] as? [String], [])
        XCTAssertEqual(try slotText(0, "aloft").count, 128)
        XCTAssertEqual(try slotText(0, "back").count, 208)
    }

    /// The service refuses a slot that is not exactly its length in lowercase
    /// hex (400), and a slot that is a different length from the next one is
    /// the one thing it may never be able to read. Four ways to be on or off,
    /// with a seed and a return waiting or without.
    func testBothSlotsAreTheirLengthInLowercaseHexInEveryCase() async throws {
        let cases: [(isOn: Bool, seedWaiting: Bool, returnOwed: Bool)] = [
            (false, false, false), (false, true, true),
            (true, false, false), (true, true, false), (true, false, true), (true, true, true),
        ]
        for (number, current) in cases.enumerated() {
            setUpWorld()
            zoneCIsOn.value = current.isOn
            if current.seedWaiting { autonautSends(r1, named: name1) }
            if current.returnOwed { try store.update { $0.addOwedReturn(owed()) } }

            _ = try await ask()

            let aloft = try slotText(0, "aloft")
            let back = try slotText(0, "back")
            XCTAssertEqual(aloft.utf8.count, 128, "case \(number): \(current)")
            XCTAssertEqual(back.utf8.count, 208, "case \(number): \(current)")
            XCTAssertNotNil(ZoneCSlots.bytes(fromHex: aloft, as: .aloft), "case \(number): \(current)")
            XCTAssertNotNil(ZoneCSlots.bytes(fromHex: back, as: .back), "case \(number): \(current)")
        }
    }

    /// The same request is made again from a clean room, so that each case in a
    /// loop starts from nothing.
    private func setUpWorld() {
        stub = AskingTests.Stub()
        sink = Sink()
        try? FileManager.default.removeItem(at: root)
        try? FileManager.default.removeItem(at: storeFile)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        store = makeStore()
    }

    func testTheRequestIsTheSameLengthWithARealSeedAndAReturnAsWithPadding() async throws {
        // A seed on its way, and a return.
        zoneCIsOn.value = true
        autonautSends(r1, named: name1)
        try store.update { $0.addOwedReturn(owed()) }
        _ = try await ask(["aa", "bb"])
        let real = stub.bodies[0].utf8.count
        XCTAssertTrue(try slotText(0, "aloft").hasPrefix(hex(spaceSeed(r1))), "a real seed went")

        // Nothing at all.
        setUpWorld()
        zoneCIsOn.value = false
        _ = try await ask(["aa", "bb"])
        let padded = stub.bodies[0].utf8.count

        XCTAssertEqual(real, padded)
    }

    @MainActor
    func testAGardenOf129MeetingsSendsTwoRequestsRealSlotsInTheFirstAndPaddingInTheSecond() async throws {
        zoneCIsOn.value = true
        autonautSends(r1, named: name1)
        try store.update { $0.addOwedReturn(owed()) }
        try store.update { $0.addSentSeed(record(7)) }
        let model = try model(meetings: 129)

        await model.catchUpOnTheAsking(zoneC: exchange())

        XCTAssertEqual(stub.asked, ["/api/walk/pending", "/api/walk/pending"])
        XCTAssertEqual((try body(0)["tokens"] as? [String])?.count, 128)
        XCTAssertEqual((try body(1)["tokens"] as? [String])?.count, 1)

        // The first request carries the seed and the return.
        XCTAssertEqual(Data(try aloftBytes(0).prefix(32)), spaceSeed(r1))
        let opened = ZoneCReturn.open(try backBytes(0), with: recipient, spaceSeed: owed().spaceSeed)
        XCTAssertEqual(opened?.bytes, owed().payload)

        // The second is padding in both, and the right length.
        XCTAssertNotEqual(Data(try aloftBytes(1).prefix(32)), spaceSeed(r1))
        XCTAssertNil(ZoneCReturn.open(try backBytes(1), with: recipient, spaceSeed: owed().spaceSeed))
        XCTAssertEqual(try slotText(1, "aloft").utf8.count, 128)
        XCTAssertEqual(try slotText(1, "back").utf8.count, 208)

        // One launch, not two: the record has one launch fewer, and the return
        // one send fewer.
        let records = try sentRecords()
        XCTAssertEqual(records.map(\.launchesLeft), [ZoneCSentSeed.launchesAtStart - 1, ZoneCSentSeed.launchesAtStart - 1])
        XCTAssertEqual(try store.load().owedReturns.map(\.sendsLeft), [7])
        XCTAssertEqual(outNames(), [], "the seed has gone")
    }

    // MARK: - What a service may answer

    private func bundle(_ bytes: [UInt8], as slot: ZoneCSlots.Slot) -> String {
        bytes.map { byte in
            String(repeating: String(format: "%02x", byte), count: slot.byteLength)
        }.joined()
    }

    private func offerRow(_ state: String) -> String {
        #"{"seed":"ab","to":"cd","from":"ef","state":"\#(state)","offeredAt":1,"answeredAt":2}"#
    }

    func testAnAnswerWithNoSlotsIsReadAsFarAsItGoes() async throws {
        // An older service: offers, and no bundles at all.
        stub.replies["/api/walk/pending"] = (200, #"{"offers":[\#(offerRow("offered"))]}"#)

        let heard = try await plots().pending(tokens: ["aa"])

        XCTAssertEqual(heard.offers.count, 1)
        XCTAssertEqual(heard.aloft, [])
        XCTAssertEqual(heard.back, [])
    }

    func testBundlesThatAreNotStringsDoNotSpoilTheRestOfTheAnswer() async throws {
        stub.replies["/api/walk/pending"] = (200, #"{"offers":[\#(offerRow("offered"))],"aloft":7,"back":["x"]}"#)

        let heard = try await plots().pending(tokens: ["aa"])

        XCTAssertEqual(heard.offers.count, 1)
        XCTAssertEqual(heard.aloft, [])
        XCTAssertEqual(heard.back, [])
    }

    func testRowsOfTheWrongLengthAreTolerated() async throws {
        let short = String(repeating: "a", count: 127)
        let leftOver = bundle([1, 2], as: .back) + "ab"
        stub.replies["/api/walk/pending"] = (
            200, #"{"offers":[\#(offerRow("offered"))],"aloft":"\#(short)","back":"\#(leftOver)"}"#
        )

        let heard = try await plots().pending(tokens: ["aa"])

        XCTAssertEqual(heard.offers.count, 1, "the rest of the answer is still read")
        XCTAssertEqual(heard.aloft, [], "127 characters are not a row")
        XCTAssertEqual(heard.back, [], "a bundle that does not cut into whole rows is not guessed at")
    }

    func testARowThatIsNotLowercaseHexIsPassedOverAndTheOthersAreKept() async throws {
        let good1 = bundle([0x11], as: .aloft)
        let upper = String(repeating: "AB", count: 64)
        let good2 = bundle([0x22], as: .aloft)
        stub.replies["/api/walk/pending"] = (200, #"{"aloft":"\#(good1)\#(upper)\#(good2)"}"#)

        let heard = try await plots().pending(tokens: ["aa"])

        XCTAssertEqual(heard.aloft, [Data(repeating: 0x11, count: 64), Data(repeating: 0x22, count: 64)])
    }

    func testTheRowsComeInTheOrderTheServiceSentThem() async throws {
        let aloft = bundle([1, 2, 3], as: .aloft)
        let back = bundle([9, 8], as: .back)
        stub.replies["/api/walk/pending"] = (200, #"{"aloft":"\#(aloft)","back":"\#(back)"}"#)

        let heard = try await plots().pending(tokens: [])

        XCTAssertEqual(heard.aloft.map { $0[0] }, [1, 2, 3])
        XCTAssertEqual(heard.aloft.map(\.count), [64, 64, 64])
        XCTAssertEqual(heard.back.map { $0[0] }, [9, 8])
        XCTAssertEqual(heard.back.map(\.count), [104, 104])
    }

    func testABundleLongerThanAnyThePhoneWasToldToExpectIsReadOnlyToALimit() async throws {
        let many = (0..<(AskingSlots.rowLimit + 5)).map { _ in UInt8(0x33) }
        stub.replies["/api/walk/pending"] = (200, #"{"aloft":"\#(bundle(many, as: .aloft))"}"#)

        let heard = try await plots().pending(tokens: [])

        XCTAssertEqual(heard.aloft.count, AskingSlots.rowLimit)
    }

    // MARK: - Switches

    @MainActor
    func testTheNewsSwitchOffStillSendsNothingEvenWithZoneCOnAndASeedWaiting() async throws {
        UserDefaults.standard.set(false, forKey: Sharing.invitationsKey)
        zoneCIsOn.value = true
        autonautSends(r1, named: name1)
        let model = try model(meetings: 0)

        await model.catchUpOnTheAsking(zoneC: exchange())

        XCTAssertTrue(stub.asked.isEmpty)
        XCTAssertEqual(outNames(), [name1], "and the seed stays where it is")
        XCTAssertFalse(FileManager.default.fileExists(atPath: storeFile.path), "and no record is made")
    }

    @MainActor
    func testItAsksOncePerStartHoweverOftenItIsCalled() async throws {
        let model = try model(meetings: 0)
        let exchange = exchange()

        await model.catchUpOnTheAsking(zoneC: exchange)
        await model.catchUpOnTheAsking(zoneC: exchange)
        await model.catchUpOnTheAsking(zoneC: exchange)

        XCTAssertEqual(stub.asked, ["/api/walk/pending"])
    }

    @MainActor
    func testAnOffSwitchDoesNotUseUpTheStart() async throws {
        UserDefaults.standard.set(false, forKey: Sharing.invitationsKey)
        let model = try model(meetings: 0)
        await model.catchUpOnTheAsking(zoneC: exchange())
        XCTAssertTrue(stub.asked.isEmpty)

        // Turned on, and the next call is the start's one.
        UserDefaults.standard.set(true, forKey: Sharing.invitationsKey)
        await model.catchUpOnTheAsking(zoneC: exchange())

        XCTAssertEqual(stub.asked, ["/api/walk/pending"])
    }

    func testZoneCIsOffUnlessTheSettingSaysOtherwise() {
        XCTAssertEqual(ZoneCExchange.enabledKey, "zonec.enabled.v1")
        XCTAssertFalse(ZoneCExchange.switchFromDefaults(), "nothing set is off: consent does not start on")

        UserDefaults.standard.set(true, forKey: ZoneCExchange.enabledKey)
        XCTAssertTrue(ZoneCExchange.switchFromDefaults())

        UserDefaults.standard.set(false, forKey: ZoneCExchange.enabledKey)
        XCTAssertFalse(ZoneCExchange.switchFromDefaults())
    }

    // MARK: - Zone C off

    func testZoneCOffSendsPaddingInBothSlotsAndLeavesOutAlone() async throws {
        zoneCIsOn.value = false
        autonautSends(r1, named: name1)
        // A file that, were `out/` read, would be deleted on sight.
        writeToOut("not what Autonaut writes", named: name2)
        let before = outNames().map { try? Data(contentsOf: outFile($0)) }
        try store.update { $0.addOwedReturn(owed()) }

        _ = try await ask()

        XCTAssertEqual(outNames(), [name1, name2], "neither file was opened, taken or deleted")
        XCTAssertEqual(outNames().map { try? Data(contentsOf: outFile($0)) }, before)
        XCTAssertFalse(try slotText(0, "aloft").hasPrefix(hex(spaceSeed(r1))), "the seed did not go")
        XCTAssertNil(
            ZoneCReturn.open(try backBytes(0), with: recipient, spaceSeed: owed().spaceSeed),
            "nor did the return"
        )
        XCTAssertEqual(try sentRecords(), [], "no record was made")
        XCTAssertEqual(try store.load().owedReturns.map(\.sendsLeft), [8], "and nothing was sent of what is owed")
    }

    func testZoneCOffHandsNothingToTheEngine() async throws {
        zoneCIsOn.value = false
        stub.replies["/api/walk/pending"] = (
            200, #"{"aloft":"\#(bundle([1], as: .aloft))","back":"\#(bundle([2], as: .back))"}"#
        )

        _ = try await ask()

        XCTAssertEqual(sink.calls, [], "off finds nothing and opens nothing")
    }

    func testZoneCOffMakesNoFileOfItsOwn() async throws {
        zoneCIsOn.value = false

        _ = try await ask(["aa"])

        XCTAssertFalse(FileManager.default.fileExists(atPath: storeFile.path))
    }

    /// A record counts the phone's own launches. One that went with padding is
    /// one, so records end on schedule whether or not Zone C is on.
    func testAnOffLaunchStillCountsAgainstTheRecordsButNotAgainstWhatIsOwed() async throws {
        zoneCIsOn.value = false
        try store.update {
            $0.addSentSeed(record(1))
            $0.addOwedReturn(owed())
        }

        _ = try await ask()

        XCTAssertEqual(try sentRecords().map(\.launchesLeft), [ZoneCSentSeed.launchesAtStart - 1])
        XCTAssertEqual(try store.load().owedReturns.map(\.sendsLeft), [8])
    }

    // MARK: - Zone C on

    func testZoneCOnTakesTheFirstSeedByNameAndKeepsTheOther() async throws {
        zoneCIsOn.value = true
        // Written the other way round, so that neither creation order nor
        // bytes give the answer.
        autonautSends(r2, named: name2)
        autonautSends(r1, named: name1)

        _ = try await ask()

        XCTAssertEqual(Data(try aloftBytes(0).prefix(32)), spaceSeed(r1))
        XCTAssertEqual(outNames(), [name2], "the first has gone, and only after the answer")
        XCTAssertEqual(try sentRecords().map(\.r), [SuiteHex.decode(r1, byteCount: 16)!])

        // The next launch takes the next.
        _ = try await ask()

        XCTAssertEqual(Data(try aloftBytes(1).prefix(32)), spaceSeed(r2))
        XCTAssertEqual(outNames(), [])
        XCTAssertEqual(try sentRecords().count, 2)
    }

    func testTheSeedKeyInTheSlotIsTheOneTheRecordHolds() async throws {
        zoneCIsOn.value = true
        autonautSends(r1, named: name1)

        _ = try await ask()

        let record = try XCTUnwrap(try sentRecords().first)
        let key = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: record.privateKey)
        XCTAssertEqual(Data(try aloftBytes(0).suffix(32)), key.publicKey.rawRepresentation)
        XCTAssertEqual(record.r, SuiteHex.decode(r1, byteCount: 16))
    }

    func testNothingWaitingSendsPaddingAndKeepsNothing() async throws {
        zoneCIsOn.value = true

        _ = try await ask(["aa"])

        XCTAssertEqual(try slotText(0, "aloft").utf8.count, 128)
        XCTAssertFalse(FileManager.default.fileExists(atPath: storeFile.path), "nothing was worth writing")
    }

    func testAnOwedReturnGoesSealedAndFreshEachTime() async throws {
        zoneCIsOn.value = true
        try store.update { $0.addOwedReturn(owed()) }

        _ = try await ask()
        _ = try await ask()

        let first = try backBytes(0)
        let second = try backBytes(1)
        XCTAssertEqual(ZoneCReturn.open(first, with: recipient, spaceSeed: owed().spaceSeed)?.bytes, owed().payload)
        XCTAssertEqual(ZoneCReturn.open(second, with: recipient, spaceSeed: owed().spaceSeed)?.bytes, owed().payload)
        XCTAssertNotEqual(first, second, "no two copies look alike")
        XCTAssertEqual(try store.load().owedReturns.map(\.sendsLeft), [6])
    }

    func testAReturnEndsAfterItsLastSend() async throws {
        zoneCIsOn.value = true
        try store.update { $0.addOwedReturn(owed(sendsLeft: 2)) }

        _ = try await ask()
        XCTAssertEqual(try store.load().owedReturns.map(\.sendsLeft), [1])

        _ = try await ask()
        XCTAssertEqual(try store.load().owedReturns, [])

        _ = try await ask()
        XCTAssertNil(ZoneCReturn.open(try backBytes(2), with: recipient, spaceSeed: owed().spaceSeed))
    }

    func testARecordEndsAtItsLastLaunch() async throws {
        zoneCIsOn.value = true
        try store.update { $0.addSentSeed(record(1, launchesLeft: 1)) }

        _ = try await ask()

        XCTAssertEqual(try sentRecords(), [])
    }

    func testAStoreThatCannotBeWrittenSendsPaddingAndKeepsTheFile() async throws {
        zoneCIsOn.value = true
        autonautSends(r1, named: name1)
        // A file where the store's folder should be.
        let blocker = directory.appendingPathComponent("blocker")
        try Data().write(to: blocker)
        let broken = ZoneCStore(
            fileURL: blocker.appendingPathComponent(ZoneCStore.fileName), writeOptions: [.atomic]
        )

        _ = try await exchange(store: broken).ask(plots: plots(), tokens: [])

        XCTAssertEqual(stub.asked, ["/api/walk/pending"], "Zone C never stops the request")
        XCTAssertFalse(try slotText(0, "aloft").hasPrefix(hex(spaceSeed(r1))), "a seed does not leave without its record")
        XCTAssertEqual(outNames(), [name1])
    }

    // MARK: - The record is written first (R2)

    func testTheRecordIsWrittenBeforeTheRequestGoesOut() async throws {
        zoneCIsOn.value = true
        autonautSends(r1, named: name1)
        let seen = Box<(records: Int, fileThere: Bool)>((-1, false))
        let store = store!
        let file = outFile(name1)
        stub.onSend = { _ in
            seen.value = (
                (try? store.load().sentSeeds.count) ?? -1,
                FileManager.default.fileExists(atPath: file.path)
            )
        }

        _ = try await ask()

        XCTAssertEqual(seen.value.records, 1, "the record was there when the request went")
        XCTAssertTrue(seen.value.fileThere, "and so was the file")
    }

    /// A request can be lost after the service has stored its slot, so the
    /// next launch has to send the very same row.
    private func lostAnswerThenRetry(
        losing: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        zoneCIsOn.value = true
        autonautSends(r1, named: name1)

        losing()
        do {
            _ = try await ask()
            XCTFail("the answer was lost", file: file, line: line)
        } catch {}

        let sent = try slotText(0, "aloft")
        let kept = try XCTUnwrap(try sentRecords().first, file: file, line: line)
        XCTAssertEqual(outNames(), [name1], "the file stays until an answer", file: file, line: line)
        XCTAssertEqual(try sentRecords().count, 1, file: file, line: line)
        XCTAssertEqual(kept.launchesLeft, ZoneCSentSeed.launchesAtStart, "a launch that was not answered is not counted", file: file, line: line)

        // Next launch, answered.
        stub.unreachable = false
        stub.script = []
        stub.replies["/api/walk/pending"] = (200, "{}")
        _ = try await ask()

        XCTAssertEqual(try slotText(1, "aloft"), sent, "the same row, so the pool takes it once", file: file, line: line)
        let after = try sentRecords()
        XCTAssertEqual(after.count, 1, "one record for one seed", file: file, line: line)
        XCTAssertEqual(after.first?.privateKey, kept.privateKey, "the same key", file: file, line: line)
        XCTAssertEqual(after.first?.launchesLeft, ZoneCSentSeed.launchesAtStart - 1, file: file, line: line)
        XCTAssertEqual(outNames(), [], "and now it has gone", file: file, line: line)
    }

    func testATimeoutLeavesTheFileAndTheNextLaunchReusesTheKey() async throws {
        try await lostAnswerThenRetry { stub.unreachable = true }
    }

    func testATooManyRequestsAnswerLeavesTheFileAndTheNextLaunchReusesTheKey() async throws {
        try await lostAnswerThenRetry {
            stub.replies["/api/walk/pending"] = (429, #"{"error":"Slow down."}"#)
        }
    }

    func testAServerErrorLeavesTheFileToo() async throws {
        try await lostAnswerThenRetry {
            stub.replies["/api/walk/pending"] = (503, "")
        }
    }

    /// A page from a hotel's network can answer 200 and be nothing of ours.
    func testAnAnswerThatIsNotOursIsNotAnAnswer() async throws {
        try await lostAnswerThenRetry {
            stub.replies["/api/walk/pending"] = (200, "<html>Please sign in</html>")
        }
    }

    func testAFailedLaunchCountsNothingAgainstRecordsOrReturns() async throws {
        zoneCIsOn.value = true
        try store.update {
            $0.addSentSeed(record(1))
            $0.addOwedReturn(owed())
        }
        stub.unreachable = true

        do { _ = try await ask(); XCTFail("lost") } catch {}

        XCTAssertEqual(try sentRecords().map(\.launchesLeft), [ZoneCSentSeed.launchesAtStart])
        XCTAssertEqual(try store.load().owedReturns.map(\.sendsLeft), [8])
    }

    @MainActor
    func testASecondRequestThatFailsStillCountsTheFirst() async throws {
        zoneCIsOn.value = true
        autonautSends(r1, named: name1)
        let model = try model(meetings: 129)
        stub.script = [(200, "{}"), (503, "")]

        await model.catchUpOnTheAsking(zoneC: exchange())

        XCTAssertEqual(stub.asked.count, 2)
        XCTAssertEqual(outNames(), [], "the first request carried the seed and was answered")
        XCTAssertEqual(try sentRecords().map(\.launchesLeft), [ZoneCSentSeed.launchesAtStart - 1])
        XCTAssertEqual(sink.calls, [], "but half an answer is not handed on")
    }

    // MARK: - The bundles

    func testTheBundlesGoOnAfterAnAnswerWhileZoneCIsOn() async throws {
        zoneCIsOn.value = true
        stub.replies["/api/walk/pending"] = (
            200, #"{"aloft":"\#(bundle([1, 2], as: .aloft))","back":"\#(bundle([3], as: .back))"}"#
        )

        _ = try await ask()

        XCTAssertEqual(sink.calls, [Sink.Call(
            aloft: [Data(repeating: 1, count: 64), Data(repeating: 2, count: 64)],
            back: [Data(repeating: 3, count: 104)]
        )])
    }

    func testBothRequestsRowsArriveTogetherInOneHandOver() async throws {
        zoneCIsOn.value = true
        stub.script = [
            (200, #"{"aloft":"\#(bundle([1], as: .aloft))"}"#),
            (200, #"{"aloft":"\#(bundle([2], as: .aloft))"}"#),
        ]

        _ = try await ask((0..<129).map { String(format: "%032lx", $0) })

        XCTAssertEqual(sink.calls.count, 1)
        XCTAssertEqual(sink.calls.first?.aloft.map { $0[0] }, [1, 2])
    }

    func testNothingIsHandedOnAfterALostAnswer() async throws {
        zoneCIsOn.value = true
        stub.unreachable = true

        do { _ = try await ask(); XCTFail("lost") } catch {}

        XCTAssertEqual(sink.calls, [])
    }

    /// The records are counted after the bundles are handed on, so a record on
    /// its last launch can still open a return that came down with its answer.
    func testTheLaunchIsCountedAfterTheBundlesAreHandedOn() async throws {
        zoneCIsOn.value = true
        try store.update { $0.addSentSeed(record(1, launchesLeft: 1)) }
        let store = store!
        let seen = Box<Int>(-1)
        let watcher = Watcher(store: store, seen: seen)
        let exchange = ZoneCExchange(
            transit: SuiteTransit(group: SuiteGroup(container: DirectoryContainer(url: root))),
            store: store,
            bundles: watcher,
            isOn: { true }
        )

        _ = try await exchange.ask(plots: plots(), tokens: [])

        XCTAssertEqual(seen.value, 1, "the record was still there when the bundles arrived")
        XCTAssertEqual(try sentRecords(), [], "and it ended with the launch")
    }

    private struct Watcher: ZoneCBundles {
        let store: ZoneCStore
        let seen: Box<Int>

        func receive(aloft: [Data], back: [Data]) async {
            seen.value = (try? store.load().sentSeeds.count) ?? -1
        }
    }
}
