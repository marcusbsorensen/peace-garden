import CryptoKit
import SeedCore
import XCTest
@testable import PeaceGarden

/// The engine of Zone C (package A4), one half at a time: what a phone does with
/// the `aloft` rows of an answer (find, cross, plant, hand to Autonaut, owe a
/// return) and with the `back` rows (open, check, grow the twin), and every
/// limit the design puts on each. `ZoneCEndToEndTests` runs two engines against
/// a pool.
///
/// Nothing here touches a network, the real App Group or the real `UserDefaults`.
/// A `Phone` is a temporary suite folder and a temporary store, with an engine
/// over them.
final class ZoneCEngineTests: XCTestCase {

    // MARK: - Things that stand in

    final class Box<Value: Sendable>: @unchecked Sendable {
        private let lock = NSLock()
        private var stored: Value

        init(_ value: Value) { stored = value }

        var value: Value {
            get { lock.withLock { stored } }
            set { lock.withLock { stored = newValue } }
        }
    }

    /// What the code did to the suite's folder, in order.
    final class AccessRecord: @unchecked Sendable {
        private let lock = NSLock()
        private var all: [SuiteGroup.Access] = []

        func add(_ access: SuiteGroup.Access) { lock.withLock { all.append(access) } }
        var events: [SuiteGroup.Access] { lock.withLock { all } }
        func clear() { lock.withLock { all = [] } }
    }

    /// One person's phone: a suite folder, an app folder with Zone C's store,
    /// a clock, and the engine and the exchange over them. Autonaut is whatever
    /// the test does to the suite folder.
    final class Phone: @unchecked Sendable {
        let name: String
        let base: URL
        let root: URL
        let store: ZoneCStore
        let accesses: AccessRecord
        let clock: Box<Date>
        let transit: SuiteTransit
        let engine: ZoneCEngine
        let exchange: ZoneCExchange

        /// - Parameters:
        ///   - day: the day number it is, by `ZoneCDay`, at midday UTC.
        ///   - nonce: 16 fixed bytes for the finder's half of a cross, or random.
        init(
            _ name: String,
            day: Int = 20_000,
            nonce: Data? = nil,
            opening: @escaping ZoneCReturns.Opening = ZoneCReturns.realOpening
        ) {
            let base = FileManager.default.temporaryDirectory
                .appendingPathComponent("zonec-engine-\(name)-\(UUID().uuidString)", isDirectory: true)
            let root = base.appendingPathComponent("suite", isDirectory: true)
            let directory = base.appendingPathComponent("app", isDirectory: true)
            try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let store = ZoneCStore(
                fileURL: directory.appendingPathComponent(ZoneCStore.fileName), writeOptions: [.atomic]
            )
            let record = AccessRecord()
            let clock = Box(Date(timeIntervalSince1970: Double(day) * 86_400 + 43_200))
            let transit = SuiteTransit(group: SuiteGroup(
                container: DirectoryContainer(url: root), audit: { record.add($0) }
            ))
            let chosen: @Sendable () -> Data
            if let fixed = nonce {
                chosen = { fixed }
            } else {
                chosen = { Pollination.makeNonce() }
            }
            let engine = ZoneCEngine(
                store: store, transit: transit,
                now: { clock.value }, nonce: chosen, opening: opening
            )
            self.name = name
            self.base = base
            self.root = root
            self.store = store
            self.accesses = record
            self.clock = clock
            self.transit = transit
            self.engine = engine
            self.exchange = ZoneCExchange(
                transit: transit, store: store, bundles: engine, isOn: { true }
            )
        }

        func tearDown() { try? FileManager.default.removeItem(at: base) }

        // The other app

        func installAutonaut() {
            let folder = root.appendingPathComponent("Presence/v1")
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            FileManager.default.createFile(atPath: folder.appendingPathComponent("autonaut").path, contents: Data())
        }

        /// What Autonaut does when the person sends a seed.
        func autonautSends(_ r: Data) {
            let folder = root.appendingPathComponent("Seeds/v1/out")
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let text = #"{"v":1,"r":"\#(SuiteHex.encode(r))"}"#
            try? Data(text.utf8).write(to: folder.appendingPathComponent(SuiteGroup.randomName()))
        }

        func autonautTakesEverything() {
            let folder = root.appendingPathComponent("Seeds/v1/in")
            for name in (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? [] {
                try? FileManager.default.removeItem(at: folder.appendingPathComponent(name))
            }
        }

        var outFiles: [String] { names("Seeds/v1/out") }
        var inFiles: [String] { names("Seeds/v1/in") }

        /// The seeds waiting in `in/`, as Autonaut would read them.
        var seedsForAutonaut: [Data] {
            inFiles.compactMap { name in
                guard let data = try? Data(contentsOf: root.appendingPathComponent("Seeds/v1/in/\(name)")),
                      let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      object.keys.sorted() == ["seed", "v"], object["v"] as? Int == 1,
                      let text = object["seed"] as? String
                else { return nil }
                return SuiteHex.decode(text, byteCount: 32)
            }
        }

        private func names(_ relative: String) -> [String] {
            let folder = root.appendingPathComponent(relative).path
            return ((try? FileManager.default.contentsOfDirectory(atPath: folder)) ?? []).sorted()
        }

        // Zone C

        var state: ZoneCState { (try? store.load()) ?? ZoneCState() }

        func advance(days: Int) {
            clock.value = clock.value.addingTimeInterval(Double(days) * 86_400)
        }

        /// A launch: the request, to whichever service, and what follows it.
        @discardableResult
        func launch(_ service: any PlotTransport, tokens: [String] = []) async throws -> PlotService.Pending {
            let plots = PlotService(transport: service, origin: URL(string: "https://example.invalid")!)
            return try await exchange.ask(plots: plots, tokens: tokens)
        }
    }

    // MARK: - Fixtures

    private var phones: [Phone] = []

    override func tearDown() {
        for phone in phones { phone.tearDown() }
        phones = []
        super.tearDown()
    }

    private func phone(
        _ name: String, day: Int = 20_000, nonce: Data? = nil, autonaut: Bool = true,
        opening: @escaping ZoneCReturns.Opening = ZoneCReturns.realOpening
    ) -> Phone {
        let phone = Phone(name, day: day, nonce: nonce, opening: opening)
        if autonaut { phone.installAutonaut() }
        phones.append(phone)
        return phone
    }

    /// 16 bytes, as Autonaut draws `r`.
    private func r(_ n: UInt8) -> Data { Data(repeating: n, count: 16) }

    private func spaceSeed(_ n: UInt8) -> Data { ZoneCMark.spaceSeed(from: r(n))! }

    /// A seed key, kept so that a test can open what is sealed to it.
    private func key(_ n: UInt8) -> Curve25519.KeyAgreement.PrivateKey {
        try! Curve25519.KeyAgreement.PrivateKey(rawRepresentation: SHA256.hash(data: Data("zonec-engine-test-\(n)".utf8)).withUnsafeBytes { Data($0) })
    }

    /// An `aloft` row as the service would hold it: the space seed for `r(n)`
    /// and a seed key.
    private func seedRow(_ n: UInt8, key seedKey: Curve25519.KeyAgreement.PrivateKey? = nil) -> Data {
        spaceSeed(n) + (seedKey ?? key(n)).publicKey.rawRepresentation
    }

    /// Padding the way the real thing is shaped.
    private func aloftPadding() -> Data { ZoneCSlots.seedPadding() }
    private func backPadding() -> Data { ZoneCSlots.returnPadding() }

    private func bundleWithPadding(_ real: [Data], count: Int = 128, at index: Int = 3) -> [Data] {
        var rows = (0..<(count - real.count)).map { _ in aloftPadding() }
        rows.insert(contentsOf: real, at: min(index, rows.count))
        return rows
    }

    /// The record a sender keeps of the seed with `r(n)`, whose key is `key(n)`.
    private func record(_ n: UInt8, plants: Int = 0, launchesLeft: Int = 60) -> ZoneCSentSeed {
        ZoneCSentSeed(
            r: r(n), privateKey: key(n).rawRepresentation, launchesLeft: launchesLeft, plantsGrown: plants
        )!
    }

    /// The finder's seed in Zone C, and the finder's nonce, for the returns made
    /// by hand.
    private func finderSeed(_ n: UInt8) -> SeedID { SeedID(bytes: Data(repeating: n, count: 32))! }
    private func finderNonce(_ n: UInt8) -> Data { Data(repeating: n, count: 16) }

    /// What a finder would send back for the seed with `r(sent)`: the 56 bytes
    /// and the 104 sealed bytes, with the checksum made right unless a test
    /// says otherwise.
    private func finderReturn(
        for sent: UInt8, finder: UInt8 = 0xb1, checksum: Data? = nil, sealedTo sealedKey: Curve25519.KeyAgreement.PrivateKey? = nil,
        asking spaceSeedAsked: Data? = nil
    ) throws -> (payload: ZoneCReturn.Payload, sealed: Data, cross: CrossPollinationResult) {
        let found = SeedID(bytes: spaceSeed(sent))!
        let cross = CrossPollinationResult(
            localSeed: finderSeed(finder), remoteSeed: found,
            localNonce: finderNonce(finder &+ 1), remoteNonce: r(sent)
        )
        let payload = try XCTUnwrap(ZoneCReturn.Payload(
            ownSeed: finderSeed(finder).bytes, nonce: finderNonce(finder &+ 1), checksum: checksum ?? cross.checksum
        ))
        let sealed = try ZoneCReturn.seal(
            payload, to: (sealedKey ?? key(sent)).publicKey, spaceSeed: spaceSeedAsked ?? spaceSeed(sent)
        )
        return (payload, sealed, cross)
    }

    private func backBundle(_ real: [Data], count: Int = 128) -> [Data] {
        var rows = (0..<(count - real.count)).map { _ in backPadding() }
        rows.insert(contentsOf: real, at: min(5, rows.count))
        return rows
    }

    // MARK: - A find

    func testAFindCrossesPlantsHandsOnAndOwesAReturn() async throws {
        let ben = phone("Ben", nonce: finderNonce(0x42))

        await ben.engine.receive(aloft: bundleWithPadding([seedRow(1)]), back: [])

        let own = try ben.store.ownSeed()
        let state = ben.state
        let plant = try XCTUnwrap(state.plants.first)
        XCTAssertEqual(state.plants.count, 1)
        XCTAssertEqual(plant.side, .finder)

        // The same three functions a knock calls, with Zone C's own seed standing
        // where a phone's own seed stands, and `r` where the other nonce stands.
        let found = SeedID(bytes: spaceSeed(1))!
        let encounter = Pollination.encounterID(seedA: own, seedB: found, nonceA: finderNonce(0x42), nonceB: r(1))
        let child = Pollination.cross(seedA: own, seedB: found, encounterID: encounter)
        XCTAssertEqual(plant.childSeed, child)
        XCTAssertEqual(plant.encounterID, encounter)
        XCTAssertEqual([plant.parentA, plant.parentB], [min(own, found), max(own, found)])

        // The found seed, as itself, for Autonaut.
        XCTAssertEqual(ben.seedsForAutonaut, [spaceSeed(1)])

        // The return: own seed ‖ nonce ‖ checksum, to be sealed to the row's key.
        let owed = try XCTUnwrap(state.owedReturns.first)
        XCTAssertEqual(state.owedReturns.count, 1)
        XCTAssertEqual(owed.payload, own.bytes + finderNonce(0x42) + Pollination.checksum(of: child))
        XCTAssertEqual(owed.recipientKey, key(1).publicKey.rawRepresentation)
        XCTAssertEqual(owed.spaceSeed, spaceSeed(1))
        XCTAssertEqual(owed.sendsLeft, ZoneCOwedReturn.sendsAtStart)

        XCTAssertEqual(state.lastFindDay, ZoneCDay.number(for: ben.clock.value))
    }

    func testTheSenderReachesTheSameChildEncounterAndChecksumFromTheOtherSide() async throws {
        let ben = phone("Ben", nonce: finderNonce(0x42))
        let ana = phone("Ana")
        try ana.store.update { $0.addSentSeed(record(1)) }

        await ben.engine.receive(aloft: bundleWithPadding([seedRow(1)]), back: [])
        let owed = try XCTUnwrap(ben.state.owedReturns.first)
        let sealed = try ZoneCReturn.seal(
            try XCTUnwrap(ZoneCReturn.Payload(bytes: owed.payload)),
            to: try Curve25519.KeyAgreement.PublicKey(rawRepresentation: owed.recipientKey),
            spaceSeed: owed.spaceSeed
        )
        await ana.engine.receive(aloft: [], back: backBundle([sealed]))

        let finders = try XCTUnwrap(ben.state.plants.first)
        let senders = try XCTUnwrap(ana.state.plants.first)
        XCTAssertEqual(senders.childSeed, finders.childSeed)
        XCTAssertEqual(senders.encounterID, finders.encounterID)
        XCTAssertEqual(senders.parentA, finders.parentA)
        XCTAssertEqual(senders.parentB, finders.parentB)
        XCTAssertEqual(Pollination.checksum(of: senders.childSeed), Data(owed.payload.suffix(8)))
        XCTAssertEqual(finders.side, .finder)
        XCTAssertEqual(senders.side, .sender)
    }

    func testNothingInTheBundleThatPassesTheMarkIsNothingToFind() async throws {
        let ben = phone("Ben")
        let wrongKey = SymmetricKey(data: Data(repeating: 9, count: 32))
        let wrongMark = ZoneCMark.spaceSeed(from: r(2), key: wrongKey)! + key(2).publicKey.rawRepresentation
        var flipped = seedRow(3)
        flipped[20] ^= 0x01
        let rows = bundleWithPadding([wrongMark, flipped, Data(repeating: 7, count: 63), seedRow(4) + Data([0])])

        await ben.engine.receive(aloft: rows, back: [])

        XCTAssertEqual(ben.state.plants, [])
        XCTAssertEqual(ben.inFiles, [])
        XCTAssertFalse(FileManager.default.fileExists(atPath: ben.store.fileURL.path), "not even Zone C's own seed was minted")
    }

    func testAnEmptyBundleDoesNothing() async throws {
        let ben = phone("Ben")

        await ben.engine.receive(aloft: [], back: [])

        XCTAssertFalse(FileManager.default.fileExists(atPath: ben.store.fileURL.path))
        XCTAssertEqual(ben.accesses.events, [], "and the folder was not so much as looked at")
    }

    func testTheSameSeedTwiceInOneBundleIsOneCandidate() async throws {
        let ben = phone("Ben")

        await ben.engine.receive(
            aloft: bundleWithPadding([seedRow(1), seedRow(1, key: key(9))]), back: []
        )

        XCTAssertEqual(ben.state.plants.count, 1)
        XCTAssertEqual(ben.seedsForAutonaut, [spaceSeed(1)])
    }

    // MARK: - The gates

    func testNothingIsFoundWhileAutonautIsNotThere() async throws {
        let ben = phone("Ben", autonaut: false)

        await ben.engine.receive(aloft: bundleWithPadding([seedRow(1)]), back: [])

        XCTAssertEqual(ben.state.plants, [])
        XCTAssertEqual(ben.inFiles, [])
        XCTAssertFalse(FileManager.default.fileExists(atPath: ben.store.fileURL.path))
    }

    func testNothingIsFoundWhileThreeFilesWaitInIn() async throws {
        let ben = phone("Ben")
        for n in 1...3 { await ben.engine.receive(aloft: bundleWithPadding([seedRow(UInt8(n))]), back: []); ben.advance(days: 1) }
        XCTAssertEqual(ben.inFiles.count, 3)
        // Returns owed would stop it too: clear them so only `in/` is in the way.
        try ben.store.update { $0.owedReturns = [] }

        await ben.engine.receive(aloft: bundleWithPadding([seedRow(4)]), back: [])
        XCTAssertEqual(ben.state.plants.count, 3, "three are waiting for Autonaut")

        ben.autonautTakesEverything()
        await ben.engine.receive(aloft: bundleWithPadding([seedRow(4)]), back: [])
        XCTAssertEqual(ben.state.plants.count, 4, "and when Autonaut has taken them, finding goes on")
    }

    func testNothingIsFoundWhileThreeReturnsAreOwed() async throws {
        let ben = phone("Ben")
        for n in 1...3 { await ben.engine.receive(aloft: bundleWithPadding([seedRow(UInt8(n))]), back: []); ben.advance(days: 1) }
        ben.autonautTakesEverything()
        XCTAssertEqual(ben.state.owedReturns.count, 3)

        await ben.engine.receive(aloft: bundleWithPadding([seedRow(4)]), back: [])

        XCTAssertEqual(ben.state.plants.count, 3, "three returns are still going out")
        XCTAssertEqual(ben.inFiles, [])

        // One finishes its eight sends.
        try ben.store.update { $0.owedReturns.removeFirst() }
        await ben.engine.receive(aloft: bundleWithPadding([seedRow(4)]), back: [])
        XCTAssertEqual(ben.state.plants.count, 4)
    }

    func testOneFindADayAndTheNextDayTheOtherSeed() async throws {
        let ben = phone("Ben")
        let rows = bundleWithPadding([seedRow(1), seedRow(2)])

        await ben.engine.receive(aloft: rows, back: [])
        XCTAssertEqual(ben.state.plants.count, 1, "two seeds, one find")
        let first = try XCTUnwrap(ben.state.plants.first)

        await ben.engine.receive(aloft: rows, back: [])
        XCTAssertEqual(ben.state.plants.count, 1, "and none more the same day")

        ben.advance(days: 1)
        await ben.engine.receive(aloft: rows, back: [])
        XCTAssertEqual(ben.state.plants.count, 2, "the next day it takes the other, not the one it has")
        XCTAssertNotEqual(ben.state.plants[1].childSeed, first.childSeed)
        XCTAssertEqual(Set(ben.seedsForAutonaut), [spaceSeed(1), spaceSeed(2)])
    }

    func testTheDayIsAWholeDayNumberAndNoTime() async throws {
        let ben = phone("Ben", day: 20_123)

        await ben.engine.receive(aloft: bundleWithPadding([seedRow(1)]), back: [])

        XCTAssertEqual(ben.state.lastFindDay, ZoneCDay.number(for: ben.clock.value))
        // Later the same day is the same day.
        ben.clock.value = ben.clock.value.addingTimeInterval(60)
        await ben.engine.receive(aloft: bundleWithPadding([seedRow(2)]), back: [])
        XCTAssertEqual(ben.state.plants.count, 1)
    }

    func testASeedItHoldsARecordForIsPassedOver() async throws {
        let ana = phone("Ana")
        try ana.store.update { $0.addSentSeed(record(1)) }

        await ana.engine.receive(aloft: bundleWithPadding([seedRow(1)]), back: [])

        XCTAssertEqual(ana.state.plants, [])
        XCTAssertEqual(ana.inFiles, [], "her own seed is not handed back to her Autonaut")

        // Another seed in the same bundle is still found.
        await ana.engine.receive(aloft: bundleWithPadding([seedRow(1), seedRow(2)]), back: [])
        XCTAssertEqual(ana.seedsForAutonaut, [spaceSeed(2)])
    }

    func testASeedThatIsAlreadyAParentOfAPlantIsPassedOver() async throws {
        let ben = phone("Ben")
        await ben.engine.receive(aloft: bundleWithPadding([seedRow(1)]), back: [])
        ben.advance(days: 1)
        ben.autonautTakesEverything()

        await ben.engine.receive(aloft: bundleWithPadding([seedRow(1)]), back: [])

        XCTAssertEqual(ben.state.plants.count, 1, "a seed found once is not found again")
        XCTAssertEqual(ben.inFiles, [])
        XCTAssertEqual(ben.state.owedReturns.count, 1)
    }

    // MARK: - A key that will not do (REVIEW-A2, finding 4)

    func testAKeyThatCannotBeSealedToLeavesTheSeedNotFoundAndNoDaySpent() async throws {
        let ben = phone("Ben")
        let zeroKey = spaceSeed(1) + Data(repeating: 0, count: 32)

        await ben.engine.receive(aloft: bundleWithPadding([zeroKey]), back: [])

        XCTAssertEqual(ben.state.plants, [], "nothing is planted for a seed that could not be answered")
        XCTAssertEqual(ben.inFiles, [], "nothing goes to Autonaut")
        XCTAssertEqual(ben.state.owedReturns, [])
        XCTAssertNil(ben.state.lastFindDay, "and the day is still to be had")

        // The same bundle with a good seed in it: that one is found.
        await ben.engine.receive(aloft: bundleWithPadding([zeroKey, seedRow(2)]), back: [])
        XCTAssertEqual(ben.seedsForAutonaut, [spaceSeed(2)])
    }

    // MARK: - What a find writes

    /// A find writes to the suite's folder once, to `in/`, by way of `tmp/`; it
    /// reads Autonaut's marker without opening it and lists `in/` for a count.
    func testAFindWritesOnlyToIn() async throws {
        let ben = phone("Ben")
        ben.accesses.clear()

        await ben.engine.receive(aloft: bundleWithPadding([seedRow(1)]), back: [])

        XCTAssertFalse(ben.accesses.events.isEmpty)
        let staging = "Seeds/v1/tmp/peacegarden-"
        let folders = Set(SuiteGroup.datedFolders)
        var moves = 0
        for event in ben.accesses.events {
            switch event {
            case .exists(let path):
                XCTAssertEqual(path, SuiteTransit.autonautPresence)
            case .list(let path):
                XCTAssertEqual(path, SuiteGroup.inFolder)
            case .write(let path):
                XCTAssertTrue(path.hasPrefix(staging), "wrote \(path)")
            case .setBackupFlag(let path):
                XCTAssertTrue(path.hasPrefix(staging) || path == SuiteGroup.seedsFolder, "flagged \(path)")
            case .setDates(let path):
                XCTAssertTrue(path.hasPrefix(staging) || folders.contains(path), "dated \(path)")
            case .createFolder(let path):
                XCTAssertTrue(folders.contains(path), "made \(path)")
            case .move(let from, let to):
                moves += 1
                XCTAssertTrue(from.hasPrefix(staging))
                XCTAssertTrue(to.hasPrefix("\(SuiteGroup.inFolder)/"), "moved to \(to)")
            case .remove(let path):
                XCTFail("deleted \(path)")
            case .inspect(let path), .read(let path):
                XCTFail("opened \(path)")
            }
        }
        XCTAssertEqual(moves, 1)
    }

    func testAReturnWritesNothingToTheGroup() async throws {
        let ana = phone("Ana")
        try ana.store.update { $0.addSentSeed(record(1)) }
        let sealed = try finderReturn(for: 1).sealed
        ana.accesses.clear()

        await ana.engine.receive(aloft: [], back: backBundle([sealed]))

        XCTAssertEqual(ana.state.plants.count, 1, "the plant grew")
        XCTAssertEqual(ana.accesses.events, [], "and the suite's folder was not touched")
        XCTAssertEqual(ana.inFiles, [])
    }

    // MARK: - A return

    func testAReturnGrowsTheTwinAndTheRecordCountsIt() async throws {
        let ana = phone("Ana")
        try ana.store.update { $0.addSentSeed(record(1)) }
        let made = try finderReturn(for: 1)

        await ana.engine.receive(aloft: [], back: backBundle([made.sealed]))

        let plant = try XCTUnwrap(ana.state.plants.first)
        XCTAssertEqual(ana.state.plants.count, 1)
        XCTAssertEqual(plant.side, .sender, "grown because her seed was found")
        XCTAssertEqual(plant.childSeed, made.cross.childSeed)
        XCTAssertEqual(plant.encounterID, made.cross.encounterID)
        XCTAssertEqual(plant.parentA, made.cross.parentA)
        XCTAssertEqual(plant.parentB, made.cross.parentB)
        XCTAssertEqual(ana.state.sentSeeds.map(\.plantsGrown), [1])
    }

    func testEightCopiesOfOneReturnGrowOnePlant() async throws {
        let ana = phone("Ana")
        try ana.store.update { $0.addSentSeed(record(1)) }
        let made = try finderReturn(for: 1)
        let copies = try (0..<8).map { _ in
            try ZoneCReturn.seal(made.payload, to: key(1).publicKey, spaceSeed: spaceSeed(1))
        }
        XCTAssertEqual(Set(copies).count, 8, "sealed afresh, so no two alike")

        await ana.engine.receive(aloft: [], back: backBundle(copies))

        XCTAssertEqual(ana.state.plants.count, 1)
        XCTAssertEqual(ana.state.sentSeeds.map(\.plantsGrown), [1])

        // And again in the next answer.
        await ana.engine.receive(aloft: [], back: backBundle(copies))
        XCTAssertEqual(ana.state.plants.count, 1)
        XCTAssertEqual(ana.state.sentSeeds.map(\.plantsGrown), [1])
    }

    func testSeveralFindersGrowSeveralPlantsAndTheRecordEndsAtThree() async throws {
        let ana = phone("Ana")
        try ana.store.update { $0.addSentSeed(record(1)) }
        let returns = try (1...4).map { try finderReturn(for: 1, finder: UInt8(0x10 * $0)) }

        await ana.engine.receive(aloft: [], back: backBundle(returns.prefix(2).map(\.sealed)))
        XCTAssertEqual(ana.state.plants.count, 2)
        XCTAssertEqual(ana.state.sentSeeds.map(\.plantsGrown), [2])

        await ana.engine.receive(aloft: [], back: backBundle(returns.map(\.sealed)))
        XCTAssertEqual(ana.state.plants.count, 3, "up to three from one seed")
        XCTAssertEqual(ana.state.sentSeeds, [], "and then the record is done")
        XCTAssertEqual(Set(ana.state.plants.map(\.childSeed)).count, 3)
        for plant in ana.state.plants { XCTAssertTrue(returns.map(\.cross.childSeed).contains(plant.childSeed)) }

        // The fourth, and anything after, has no record to open it.
        await ana.engine.receive(aloft: [], back: backBundle([returns[3].sealed]))
        XCTAssertEqual(ana.state.plants.count, 3)
    }

    func testAReturnForAnotherSenderGrowsNothing() async throws {
        let ana = phone("Ana")
        try ana.store.update { $0.addSentSeed(record(1)) }
        let someoneElses = try finderReturn(for: 2).sealed
        let sealedToOthersKey = try finderReturn(for: 1, sealedTo: key(2)).sealed

        await ana.engine.receive(aloft: [], back: backBundle([someoneElses, sealedToOthersKey]))

        XCTAssertEqual(ana.state.plants, [])
        XCTAssertEqual(ana.state.sentSeeds.map(\.plantsGrown), [0])
    }

    func testAReturnSealedForAnotherSpaceSeedGrowsNothing() async throws {
        let ana = phone("Ana")
        try ana.store.update { $0.addSentSeed(record(1)) }
        let wrongContext = try finderReturn(for: 1, asking: spaceSeed(2)).sealed

        await ana.engine.receive(aloft: [], back: backBundle([wrongContext]))

        XCTAssertEqual(ana.state.plants, [])
    }

    func testAWrongChecksumGrowsNothing() async throws {
        let ana = phone("Ana")
        try ana.store.update { $0.addSentSeed(record(1)) }
        let wrong = try finderReturn(for: 1, checksum: Data(repeating: 0, count: 8)).sealed

        await ana.engine.receive(aloft: [], back: backBundle([wrong]))

        XCTAssertEqual(ana.state.plants, [], "the two phones would grow different plants, so neither does")
        XCTAssertEqual(ana.state.sentSeeds.map(\.plantsGrown), [0])
    }

    func testAFlippedBitGrowsNothing() async throws {
        let ana = phone("Ana")
        try ana.store.update { $0.addSentSeed(record(1)) }
        let sealed = try finderReturn(for: 1).sealed
        var damaged: [Data] = []
        for index in 0..<sealed.count {
            var copy = sealed
            copy[index] ^= 0x01
            damaged.append(copy)
        }
        // A whole bundle of them, 104 rows.
        await ana.engine.receive(aloft: [], back: damaged)

        XCTAssertEqual(ana.state.plants, [], "no byte of a return can be changed")
    }

    func testRowsOfTheWrongLengthAndPaddingGrowNothing() async throws {
        let ana = phone("Ana")
        try ana.store.update { $0.addSentSeed(record(1)) }
        let sealed = try finderReturn(for: 1).sealed

        await ana.engine.receive(
            aloft: [],
            back: backBundle([Data(), sealed.dropLast(), sealed + Data([0]), Data(repeating: 0, count: 104)])
        )

        XCTAssertEqual(ana.state.plants, [])
    }

    func testAPlantAlreadyHeldIsPassedOverAndNotCounted() async throws {
        let ana = phone("Ana")
        let made = try finderReturn(for: 1)
        try ana.store.update {
            $0.addSentSeed(record(1))
            $0.addPlant(ZoneCPlant(made.cross, side: .sender))
        }

        await ana.engine.receive(aloft: [], back: backBundle([made.sealed]))

        XCTAssertEqual(ana.state.plants.count, 1)
        XCTAssertEqual(ana.state.sentSeeds.map(\.plantsGrown), [0])
    }

    // MARK: - Trying the keys

    /// Counts calls and notes which thread each ran on.
    private final class Tries: @unchecked Sendable {
        private let lock = NSLock()
        private var threads: [Bool] = []

        func note() { lock.withLock { threads.append(Thread.isMainThread) } }
        var count: Int { lock.withLock { threads.count } }
        var anyOnTheMainThread: Bool { lock.withLock { threads.contains(true) } }
    }

    private func counting(_ tries: Tries) -> ZoneCReturns.Opening {
        { row, seedKey, spaceSeed in
            tries.note()
            return ZoneCReturn.open(row, with: seedKey, spaceSeed: spaceSeed)
        }
    }

    func testEveryLiveRecordsKeyIsTriedOnEveryRow() async throws {
        let tries = Tries()
        let ana = phone("Ana", opening: counting(tries))
        try ana.store.update { state in
            for n in 1...8 { state.addSentSeed(record(UInt8(n))) }
        }

        await ana.engine.receive(aloft: [], back: backBundle([]))

        XCTAssertEqual(tries.count, 8 * 128, "1,024 attempts, none skipped")
    }

    func testARowThatOpensIsNotTriedWithTheOtherKeys() async throws {
        let tries = Tries()
        let ana = phone("Ana", opening: counting(tries))
        try ana.store.update { state in
            for n in 1...8 { state.addSentSeed(record(UInt8(n))) }
        }
        let first = try finderReturn(for: 1).sealed

        await ana.engine.receive(aloft: [], back: [first])

        XCTAssertEqual(tries.count, 1, "the first record's key opened it")
    }

    func testAPhoneWithNoRecordTriesNoKey() async throws {
        let tries = Tries()
        let ben = phone("Ben", opening: counting(tries))

        await ben.engine.receive(aloft: [], back: backBundle([]))

        XCTAssertEqual(tries.count, 0, "no cryptography at all for a phone that sent nothing")
    }

    /// 1,024 key agreements take about 100 ms on a Mac and a few hundred on an
    /// old phone (REVIEW-A2, finding 1), so they must not run on the main actor
    /// whichever actor calls the engine.
    @MainActor
    func testTheOpeningLoopRunsOffTheMainActor() async throws {
        let tries = Tries()
        let ana = phone("Ana", opening: counting(tries))
        try ana.store.update { state in
            for n in 1...8 { state.addSentSeed(record(UInt8(n))) }
        }
        XCTAssertTrue(Thread.isMainThread, "the test itself is on the main actor")

        await ana.engine.receive(aloft: [], back: backBundle([]))

        XCTAssertEqual(tries.count, 8 * 128)
        XCTAssertFalse(tries.anyOnTheMainThread, "not one of them ran on the main thread")
        XCTAssertTrue(Thread.isMainThread, "and the caller is back where it was")
    }

    /// The same, from the exchange, which is how the app reaches the engine.
    @MainActor
    func testTheOpeningLoopRunsOffTheMainActorWhenTheExchangeCallsIt() async throws {
        let tries = Tries()
        let ana = phone("Ana", opening: counting(tries))
        try ana.store.update { state in
            for n in 1...8 { state.addSentSeed(record(UInt8(n))) }
        }
        let rows = backBundle([]).map { SuiteHex.encode($0) }.joined()
        let service = AskingTests.Stub()
        service.replies["/api/walk/pending"] = (
            200, #"{"aloft":"\#(String(repeating: "ab", count: 64 * 2))","back":"\#(rows)"}"#
        )

        try await ana.launch(service)

        XCTAssertEqual(tries.count, 8 * 128)
        XCTAssertFalse(tries.anyOnTheMainThread)
    }

    // MARK: - The order

    /// The third return ends a record in the same answer that carries its own
    /// seed. The seed is not found by its sender: the plant that return grew has
    /// the seed for a parent, and the record held it back until then.
    func testASenderDoesNotFindItsOwnSeedWhenThisAnswerEndsItsRecord() async throws {
        let ana = phone("Ana")
        try ana.store.update { $0.addSentSeed(record(1, plants: 2)) }
        let third = try finderReturn(for: 1).sealed

        await ana.engine.receive(aloft: bundleWithPadding([seedRow(1)]), back: backBundle([third]))

        XCTAssertEqual(ana.state.sentSeeds, [], "the third plant ended the record")
        XCTAssertEqual(ana.state.plants.count, 1)
        XCTAssertEqual(ana.state.plants.first?.side, .sender)
        XCTAssertNil(ana.state.lastFindDay, "and she did not find her own seed")
        XCTAssertEqual(ana.inFiles, [])
    }

    func testAFindAndAReturnInTheSameAnswerAreBothTaken() async throws {
        let ana = phone("Ana")
        try ana.store.update { $0.addSentSeed(record(1)) }
        let made = try finderReturn(for: 1).sealed

        await ana.engine.receive(aloft: bundleWithPadding([seedRow(2)]), back: backBundle([made]))

        XCTAssertEqual(Set(ana.state.plants.map(\.side)), [.finder, .sender])
        XCTAssertEqual(ana.seedsForAutonaut, [spaceSeed(2)])
    }

    // MARK: - Where the app reaches it

    /// The model's own asking, with no exchange handed in, is the app's path:
    /// the switches, the suite it holds, the store beside its file, the engine.
    @MainActor
    func testTheModelsOwnAskingFindsASeedThroughTheEngine() async throws {
        let ben = phone("Ben")
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("zonec-engine-model-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: file) }
        let garden = GardenStore(fileURL: file, writeOptions: [.atomic])
        let service = AskingTests.Stub()
        service.replies["/api/walk/pending"] = (
            200, #"{"aloft":"\#(SuiteHex.encode(bundleWithPadding([seedRow(1)]).reduce(into: Data()) { $0.append($1) }))"}"#
        )
        let model = GardenModel(
            store: garden,
            plots: PlotService(transport: service, origin: URL(string: "https://example.invalid")!),
            suite: ben.transit
        )
        UserDefaults.standard.set(true, forKey: Sharing.invitationsKey)
        UserDefaults.standard.set(true, forKey: ZoneCExchange.enabledKey)
        defer {
            UserDefaults.standard.removeObject(forKey: Sharing.invitationsKey)
            UserDefaults.standard.removeObject(forKey: ZoneCExchange.enabledKey)
        }

        await model.catchUpOnTheAsking()

        let state = try ZoneCStore(besideGardenAt: garden).load()
        XCTAssertEqual(state.plants.count, 1)
        XCTAssertEqual(state.plants.first?.side, .finder)
        XCTAssertEqual(ben.seedsForAutonaut, [spaceSeed(1)])
        XCTAssertEqual(state.owedReturns.count, 1)
    }

    func testTheAppsOwnExchangeHandsTheBundlesToTheEngine() throws {
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("zonec-engine-garden-\(UUID().uuidString).json")
        let exchange = ZoneCExchange(besideGardenAt: GardenStore(fileURL: file, writeOptions: [.atomic]))

        XCTAssertTrue(exchange.bundles is ZoneCEngine)
    }
}
