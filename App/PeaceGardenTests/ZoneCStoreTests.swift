import Foundation
import SeedCore
import XCTest
@testable import PeaceGarden

// Zone C's store (package A1): the file, the limits on what it holds, and the
// promises Marcus made about it - in the device backup (9B), no dates, and a
// day number rather than a time for "one find a day" (7, item 2).

private func bytes(_ value: UInt8, _ count: Int) -> Data {
    Data(repeating: value, count: count)
}

private func seed(_ n: UInt8) -> SeedID {
    SeedID(bytes: bytes(n, SeedID.byteCount))!
}

/// A sent-seed record whose `r` is `n` repeated, so records can be told apart.
private func sent(_ n: UInt8) -> ZoneCSentSeed {
    ZoneCSentSeed(r: bytes(n, 16), privateKey: bytes(n &+ 100, 32))!
}

/// An owed return whose space seed is `n` repeated.
private func owed(_ n: UInt8) -> ZoneCOwedReturn {
    ZoneCOwedReturn(payload: bytes(n, 56), recipientKey: bytes(n &+ 100, 32), spaceSeed: bytes(n, 32))!
}

/// The mark of the seed whose `r` is `n` repeated, as a record that ends leaves it.
private func mark(_ n: UInt8) -> Data {
    ZoneCMark.mark(for: bytes(n, 16))!
}

private func plant(_ n: UInt8, side: ZoneCPlant.Side = .finder) -> ZoneCPlant {
    ZoneCPlant(
        childSeed: seed(n),
        parentA: seed(n &+ 1),
        parentB: seed(n &+ 2),
        encounterID: bytes(n, 32),
        side: side
    )
}

/// Counts how often the store asks for random bytes, and hands back a run of
/// one value that changes at each draw: 0x41 at the first, 0x42 at the second.
private final class Draws: @unchecked Sendable {
    private let lock = NSLock()
    private var drawn = 0

    var count: Int { lock.withLock { drawn } }

    func next(_ length: Int) -> Data {
        lock.withLock {
            drawn += 1
            return Data(repeating: UInt8(truncatingIfNeeded: 0x40 + drawn), count: length)
        }
    }
}

final class ZoneCStoreTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PeaceGardenZoneCTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private var fileURL: URL { directory.appendingPathComponent(ZoneCStore.fileName) }

    /// Atomic, and deliberately unprotected: on a Mac `GardenStore.guarded`
    /// ties readability to the screen lock, so tests that use it pass all day
    /// and fail overnight (see `GardenStoreTests`). Nothing here tests file
    /// protection; `testItIsWrittenTheWayTheGardenIs` checks the default.
    private func makeStore(draws: Draws = Draws()) -> ZoneCStore {
        ZoneCStore(fileURL: fileURL, writeOptions: [.atomic], randomBytes: { draws.next($0) })
    }

    /// One of everything, so a round trip and a file inspection have something
    /// to find.
    private func fullState() -> ZoneCState {
        let cross = CrossPollinationResult(
            localSeed: seed(1),
            remoteSeed: seed(2),
            localNonce: bytes(3, 16),
            remoteNonce: bytes(4, 16)
        )
        var state = ZoneCState(ownSeed: seed(9), lastFindDay: 20_743, retiredMarks: [bytes(7, 16), bytes(8, 16)])
        state.addSentSeed(sent(1))
        state.addSentSeed(ZoneCSentSeed(r: bytes(2, 16), privateKey: bytes(102, 32), launchesLeft: 17, plantsGrown: 2)!)
        state.addOwedReturn(owed(1))
        state.addOwedReturn(ZoneCOwedReturn(payload: bytes(2, 56), recipientKey: bytes(3, 32), spaceSeed: bytes(4, 32), sendsLeft: 5)!)
        state.addPlant(ZoneCPlant(cross, side: .finder))
        state.addPlant(plant(50, side: .sender))
        return state
    }

    // MARK: - The file

    func testAnEmptyStoreReadsAsEmptyAndWritesNothing() throws {
        let store = makeStore()
        XCTAssertEqual(try store.load(), ZoneCState())
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
    }

    func testZoneCSurvivesARoundTrip() throws {
        let state = fullState()
        let store = makeStore()
        try store.save(state)

        XCTAssertEqual(try store.load(), state)
        // A fresh store on the same file, as after a relaunch or a restore.
        XCTAssertEqual(try makeStore().load(), state)
    }

    func testTheCrossAPlantComesFromIsKeptInTheOrderBothPhonesAgree() throws {
        let cross = CrossPollinationResult(
            localSeed: seed(2),
            remoteSeed: seed(1),
            localNonce: bytes(3, 16),
            remoteNonce: bytes(4, 16)
        )
        let kept = ZoneCPlant(cross, side: .sender)
        XCTAssertEqual(kept.childSeed, cross.childSeed)
        XCTAssertEqual(kept.encounterID, cross.encounterID)
        XCTAssertEqual([kept.parentA, kept.parentB], [seed(1), seed(2)])
        XCTAssertEqual(kept.lineage, cross.lineage)
    }

    func testItIsWrittenTheWayTheGardenIs() {
        let store = ZoneCStore(fileURL: fileURL)
        XCTAssertEqual(store.writeOptions, GardenStore.guarded)
    }

    func testItSitsBesideTheGardenFile() {
        let garden = GardenStore(fileURL: directory.appendingPathComponent("garden.json"))
        let store = ZoneCStore(besideGardenAt: garden)
        XCTAssertEqual(store.fileURL, directory.appendingPathComponent("zonec.json"))
    }

    func testTheStoreIsInTheDeviceBackup() throws {
        let store = makeStore()
        try store.save(fullState())

        let values = try fileURL.resourceValues(forKeys: [.isExcludedFromBackupKey])
        XCTAssertEqual(values.isExcludedFromBackup, false)
        let folder = try directory.resourceValues(forKeys: [.isExcludedFromBackupKey])
        XCTAssertEqual(folder.isExcludedFromBackup, false)
    }

    func testEraseRemovesTheFileAndTheNextSeedIsNewlyMinted() throws {
        let store = makeStore()
        let before = try store.ownSeed()
        try store.update { $0.addSentSeed(sent(1)) }
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        try store.erase()

        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertEqual(try store.load(), ZoneCState())
        XCTAssertNotEqual(try store.ownSeed(), before)
        // Nothing to remove is not a failure.
        try store.erase()
        try store.erase()
    }

    func testAFileFromANewerVersionIsRefusedAndLeftAlone() throws {
        let future = Data(#"{"schemaVersion": 99, "sentSeeds": [], "owedReturns": [], "plants": []}"#.utf8)
        try future.write(to: fileURL)
        let store = makeStore()

        XCTAssertThrowsError(try store.load()) { error in
            guard case ZoneCStore.StoreError.unsupportedSchema(let found) = error else {
                return XCTFail("unexpected error \(error)")
            }
            XCTAssertEqual(found, 99)
        }
        XCTAssertThrowsError(try store.update { $0.recordFind(onDay: 1) })
        XCTAssertThrowsError(try store.ownSeed())
        XCTAssertEqual(try Data(contentsOf: fileURL), future)
    }

    func testKeyMaterialOfTheWrongSizeIsNeverKept() throws {
        XCTAssertNil(ZoneCSentSeed(r: bytes(1, 15), privateKey: bytes(1, 32)))
        XCTAssertNil(ZoneCSentSeed(r: bytes(1, 16), privateKey: bytes(1, 31)))
        XCTAssertNil(ZoneCOwedReturn(payload: bytes(1, 55), recipientKey: bytes(1, 32), spaceSeed: bytes(1, 32)))
        XCTAssertNil(ZoneCOwedReturn(payload: bytes(1, 56), recipientKey: bytes(1, 33), spaceSeed: bytes(1, 32)))
        XCTAssertNil(ZoneCOwedReturn(payload: bytes(1, 56), recipientKey: bytes(1, 32), spaceSeed: bytes(1, 16)))

        // And a file that holds such a record is refused whole, not half read.
        var damaged = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(fullState())) as? [String: Any]
        )
        var records = try XCTUnwrap(damaged["sentSeeds"] as? [[String: Any]])
        records[0]["privateKey"] = bytes(1, 31).base64EncodedString()
        damaged["sentSeeds"] = records
        try JSONSerialization.data(withJSONObject: damaged).write(to: fileURL)

        XCTAssertThrowsError(try makeStore().load()) { error in
            guard case ZoneCStore.StoreError.unreadable = error else {
                return XCTFail("unexpected error \(error)")
            }
        }
    }

    // MARK: - Updates

    func testAnUpdateThatThrowsWritesNothing() throws {
        struct Refused: Error {}
        let store = makeStore()
        try store.save(ZoneCState(lastFindDay: 5))
        let before = try Data(contentsOf: fileURL)

        XCTAssertThrowsError(try store.update { state in
            state.addPlant(plant(1))
            state.recordFind(onDay: 6)
            throw Refused()
        })
        XCTAssertEqual(try Data(contentsOf: fileURL), before)
        XCTAssertEqual(try store.load().lastFindDay, 5)
    }

    func testAnUpdateThatChangesNothingWritesNothing() throws {
        let store = makeStore()
        try store.update { _ in }
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
    }

    func testAFindLandsAsOneWrite() throws {
        let store = makeStore()
        let own = try store.ownSeed()
        let found = seed(7)
        let cross = CrossPollinationResult(
            localSeed: own,
            remoteSeed: found,
            localNonce: bytes(1, 16),
            remoteNonce: bytes(2, 16)
        )

        try store.update { state in
            state.addPlant(ZoneCPlant(cross, side: .finder))
            state.addOwedReturn(owed(7))
            state.recordFind(onDay: 20_743)
        }

        let loaded = try store.load()
        XCTAssertEqual(loaded.plants.map(\.childSeed), [cross.childSeed])
        XCTAssertEqual(loaded.owedReturns.count, 1)
        XCTAssertEqual(loaded.lastFindDay, 20_743)
        XCTAssertEqual(loaded.ownSeed, own)
    }

    func testChangesFromSeveralThreadsAreNotLost() throws {
        let store = makeStore()
        DispatchQueue.concurrentPerform(iterations: 40) { index in
            _ = try? store.update { $0.addPlant(plant(UInt8(index))) }
        }
        XCTAssertEqual(try store.load().plants.count, 40)
    }

    // MARK: - Zone C's own seed

    func testTheOwnSeedIsMintedOnceAndStaysTheSame() throws {
        let draws = Draws()
        let store = makeStore(draws: draws)

        let first = try store.ownSeed()
        XCTAssertEqual(draws.count, 1)
        // 32 bytes, and the random source's own: nothing is derived or hashed.
        XCTAssertEqual(first.bytes, bytes(0x41, 32))

        XCTAssertEqual(try store.ownSeed(), first)
        // A relaunch: a new store on the same file draws nothing.
        let relaunched = makeStore(draws: draws)
        XCTAssertEqual(try relaunched.ownSeed(), first)
        XCTAssertEqual(draws.count, 1)
        // It is on disk, not only in memory.
        XCTAssertEqual(try relaunched.load().ownSeed, first)
    }

    func testTheSystemSourceGivesEachPhoneItsOwnSeed() throws {
        let one = try ZoneCStore(fileURL: fileURL, writeOptions: [.atomic]).ownSeed()
        let other = try ZoneCStore(
            fileURL: directory.appendingPathComponent("other.json"),
            writeOptions: [.atomic]
        ).ownSeed()

        XCTAssertEqual(one.bytes.count, 32)
        XCTAssertNotEqual(one, other)
        XCTAssertNotEqual(one.bytes, bytes(0, 32))
    }

    // MARK: - Sent-seed records

    func testANinthRecordPushesOutTheOldest() throws {
        let store = makeStore()
        for n in 1...9 { try store.update { $0.addSentSeed(sent(UInt8(n))) } }

        let kept = try store.load().sentSeeds
        XCTAssertEqual(kept.count, ZoneCState.sentSeedLimit)
        XCTAssertEqual(kept.map { $0.r.first }, (2...9).map { UInt8($0) })
        XCTAssertNil(try store.load().sentSeed(forR: bytes(1, 16)))
    }

    func testARecordEndsAfterSixtyLaunches() throws {
        let store = makeStore()
        try store.update { $0.addSentSeed(sent(1)) }
        XCTAssertEqual(try store.load().sentSeeds[0].launchesLeft, 60)

        for _ in 1...59 { try store.update { $0.countLaunch() } }
        XCTAssertEqual(try store.load().sentSeeds.map(\.launchesLeft), [1])

        try store.update { $0.countLaunch() }
        XCTAssertTrue(try store.load().sentSeeds.isEmpty)
    }

    func testLaunchesAreCountedAgainstEveryRecordFromWhenItWasKept() throws {
        var state = ZoneCState()
        state.addSentSeed(sent(1))
        for _ in 1...10 { state.countLaunch() }
        state.addSentSeed(sent(2))
        for _ in 1...50 { state.countLaunch() }

        XCTAssertEqual(state.sentSeeds.map { $0.r.first }, [2])
        XCTAssertEqual(state.sentSeeds[0].launchesLeft, 10)
    }

    func testARecordEndsAtThreePlants() throws {
        let store = makeStore()
        try store.update { $0.addSentSeed(sent(1)) }
        let r = bytes(1, 16)

        try store.update { XCTAssertTrue($0.countPlantGrown(forR: r)) }
        try store.update { XCTAssertTrue($0.countPlantGrown(forR: r)) }
        XCTAssertEqual(try store.load().sentSeeds.map(\.plantsGrown), [2])

        try store.update { XCTAssertTrue($0.countPlantGrown(forR: r)) }
        XCTAssertTrue(try store.load().sentSeeds.isEmpty)
        // Nothing to count it against any more.
        try store.update { XCTAssertFalse($0.countPlantGrown(forR: r)) }
    }

    func testASeedAlreadyRecordedKeepsItsFirstKey() {
        var state = ZoneCState()
        XCTAssertTrue(state.addSentSeed(ZoneCSentSeed(r: bytes(1, 16), privateKey: bytes(11, 32))!))
        XCTAssertFalse(state.addSentSeed(ZoneCSentSeed(r: bytes(1, 16), privateKey: bytes(22, 32))!))

        XCTAssertEqual(state.sentSeeds.count, 1)
        XCTAssertEqual(state.sentSeed(forR: bytes(1, 16))?.privateKey, bytes(11, 32))
    }

    // MARK: - Retired marks

    func testARecordThatEndsByLaunchesLeavesItsMark() throws {
        let store = makeStore()
        try store.update {
            $0.addSentSeed(ZoneCSentSeed(r: bytes(1, 16), privateKey: bytes(101, 32), launchesLeft: 2)!)
            $0.addSentSeed(sent(2))
        }
        try store.update { $0.countLaunch() }
        XCTAssertEqual(try store.load().retiredMarks, [], "it has one launch left")

        try store.update { $0.countLaunch() }

        let state = try store.load()
        XCTAssertEqual(state.sentSeeds.map { $0.r.first }, [2])
        XCTAssertEqual(state.retiredMarks, [mark(1)])
        XCTAssertTrue(state.hasSent(spaceSeed: ZoneCMark.spaceSeed(from: bytes(1, 16))!), "the seed that ended")
        XCTAssertTrue(state.hasSent(spaceSeed: ZoneCMark.spaceSeed(from: bytes(2, 16))!), "the seed that lives")
        XCTAssertFalse(state.hasSent(spaceSeed: ZoneCMark.spaceSeed(from: bytes(3, 16))!), "and a stranger's")
    }

    func testARecordThatEndsByPlantsLeavesItsMark() throws {
        var state = ZoneCState()
        state.addSentSeed(sent(1))
        state.addSentSeed(sent(2))
        state.countPlantGrown(forR: bytes(1, 16))
        state.countPlantGrown(forR: bytes(1, 16))
        XCTAssertEqual(state.retiredMarks, [], "two plants are not three")

        state.countPlantGrown(forR: bytes(1, 16))

        XCTAssertEqual(state.sentSeeds.map { $0.r.first }, [2])
        XCTAssertEqual(state.retiredMarks, [mark(1)])
        // A plant counted against a record that has ended changes nothing.
        XCTAssertFalse(state.countPlantGrown(forR: bytes(1, 16)))
        XCTAssertEqual(state.retiredMarks, [mark(1)])
    }

    func testARecordPushedOutOfTheEightLeavesItsMark() throws {
        var state = ZoneCState()
        for n in 1...8 { state.addSentSeed(sent(UInt8(n))) }
        XCTAssertEqual(state.retiredMarks, [])

        state.addSentSeed(sent(9))

        XCTAssertEqual(state.sentSeeds.map { $0.r.first }, (2...9).map { UInt8($0) })
        XCTAssertEqual(state.retiredMarks, [mark(1)])
    }

    func testOnlyTheLatestSixtyFourMarksAreKept() throws {
        let store = makeStore()
        // Seventy are pushed out, one at a time, by the 71st to the 78th.
        for n in 1...78 { try store.update { $0.addSentSeed(sent(UInt8(n))) } }

        let state = try store.load()
        XCTAssertEqual(state.sentSeeds.map { $0.r.first }, (71...78).map { UInt8($0) })
        XCTAssertEqual(state.retiredMarks.count, ZoneCState.retiredMarkLimit)
        XCTAssertEqual(ZoneCState.retiredMarkLimit, 64)
        XCTAssertEqual(state.retiredMarks, (7...70).map { mark(UInt8($0)) }, "oldest first, the first six dropped")
        XCTAssertTrue(state.retiredMarks.allSatisfy { $0.count == 16 })
        XCTAssertFalse(state.hasSent(spaceSeed: ZoneCMark.spaceSeed(from: bytes(6, 16))!), "dropped")
        XCTAssertTrue(state.hasSent(spaceSeed: ZoneCMark.spaceSeed(from: bytes(7, 16))!), "kept")
        // The list is what the file holds.
        XCTAssertEqual(try makeStore().load().retiredMarks, state.retiredMarks)
    }

    func testAMarkIsKeptOnceAndTheNewestIsLast() {
        var state = ZoneCState()
        state.addSentSeed(ZoneCSentSeed(r: bytes(1, 16), privateKey: bytes(101, 32), launchesLeft: 1)!)
        state.addSentSeed(ZoneCSentSeed(r: bytes(2, 16), privateKey: bytes(102, 32), launchesLeft: 1)!)
        state.countLaunch()
        XCTAssertEqual(state.retiredMarks, [mark(1), mark(2)], "oldest record first")

        // The same seed sent again ends again: its mark moves to the end.
        state.addSentSeed(ZoneCSentSeed(r: bytes(1, 16), privateKey: bytes(103, 32), launchesLeft: 1)!)
        state.countLaunch()

        XCTAssertEqual(state.retiredMarks, [mark(2), mark(1)])
    }

    func testASeedOfTheWrongLengthIsNobodys() {
        var state = ZoneCState()
        state.addSentSeed(sent(1))
        state.retiredMarks = [mark(2)]

        XCTAssertFalse(state.hasSent(spaceSeed: bytes(1, 16)))
        XCTAssertFalse(state.hasSent(spaceSeed: Data()))
        XCTAssertFalse(state.hasSent(spaceSeed: ZoneCMark.spaceSeed(from: bytes(1, 16))! + [0]))
    }

    /// A phone that updates keeps its file: `retiredMarks` was added to the
    /// shape without a new schema version, and an older file has no such key.
    func testAFileWithoutRetiredMarksStillLoads() throws {
        var older = fullState()
        older.retiredMarks = []
        var object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(older)) as? [String: Any]
        )
        XCTAssertNotNil(object.removeValue(forKey: "retiredMarks"), "the file is as the older version wrote it")
        try JSONSerialization.data(withJSONObject: object).write(to: fileURL)
        let store = makeStore()

        let state = try store.load()
        XCTAssertEqual(state, older)
        XCTAssertEqual(state.retiredMarks, [])
        XCTAssertEqual(state.schemaVersion, 1)

        // And it goes on from there: a record that ends leaves its mark in the file.
        try store.update {
            $0.addSentSeed(ZoneCSentSeed(r: bytes(5, 16), privateKey: bytes(105, 32), launchesLeft: 1)!)
            $0.countLaunch()
        }
        XCTAssertEqual(try makeStore().load().retiredMarks, [mark(5)])
    }

    func testRetiredMarksSurviveARoundTripInTheirOrder() throws {
        var state = fullState()
        state.retiredMarks = [bytes(3, 16), bytes(1, 16), bytes(2, 16)]
        try makeStore().save(state)

        XCTAssertEqual(try makeStore().load().retiredMarks, [bytes(3, 16), bytes(1, 16), bytes(2, 16)])
    }

    func testAMarkOfTheWrongSizeRefusesTheFile() throws {
        var damaged = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(fullState())) as? [String: Any]
        )
        damaged["retiredMarks"] = [bytes(1, 15).base64EncodedString()]
        try JSONSerialization.data(withJSONObject: damaged).write(to: fileURL)

        XCTAssertThrowsError(try makeStore().load()) { error in
            guard case ZoneCStore.StoreError.unreadable = error else {
                return XCTFail("unexpected error \(error)")
            }
        }
    }

    func testEraseTakesTheRetiredMarksWithTheRest() throws {
        let store = makeStore()
        try store.save(fullState())
        XCTAssertFalse(try store.load().retiredMarks.isEmpty)

        try store.erase()

        XCTAssertEqual(try store.load().retiredMarks, [])
        XCTAssertEqual(try store.load(), ZoneCState())
    }

    // MARK: - Owed returns

    func testNoMoreThanThreeReturnsAreOwed() {
        var state = ZoneCState()
        XCTAssertTrue(state.addOwedReturn(owed(1)))
        XCTAssertTrue(state.addOwedReturn(owed(2)))
        XCTAssertTrue(state.canOweAnother)
        XCTAssertTrue(state.addOwedReturn(owed(3)))

        XCTAssertFalse(state.canOweAnother)
        XCTAssertFalse(state.addOwedReturn(owed(4)))
        XCTAssertEqual(state.owedReturns.count, 3)
    }

    func testAReturnIsQueuedOncePerFind() {
        var state = ZoneCState()
        XCTAssertTrue(state.addOwedReturn(owed(1)))
        XCTAssertFalse(state.addOwedReturn(owed(1)))
        XCTAssertEqual(state.owedReturns.count, 1)
    }

    func testAReturnRidesInEightRequestsThenEnds() {
        var state = ZoneCState()
        state.addOwedReturn(owed(1))
        for sendsLeft in stride(from: 8, through: 1, by: -1) {
            XCTAssertEqual(state.nextOwedReturn()?.sendsLeft, sendsLeft)
            state.countReturnSent(forSpaceSeed: bytes(1, 32))
        }
        XCTAssertNil(state.nextOwedReturn())
        XCTAssertTrue(state.owedReturns.isEmpty)
    }

    func testTwoOwedReturnsTakeTurns() {
        var state = ZoneCState()
        state.addOwedReturn(owed(1))
        state.addOwedReturn(owed(2))

        var order: [UInt8] = []
        while let next = state.nextOwedReturn() {
            order.append(next.spaceSeed[0])
            state.countReturnSent(forSpaceSeed: next.spaceSeed)
        }
        XCTAssertEqual(order, [1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2])
    }

    func testALaterReturnCatchesUpWithAnEarlierOne() {
        var state = ZoneCState()
        state.addOwedReturn(owed(1))
        for _ in 1...3 { state.countReturnSent(forSpaceSeed: bytes(1, 32)) }
        state.addOwedReturn(owed(2))

        // The new one has more sends left, so it goes first.
        XCTAssertEqual(state.nextOwedReturn()?.spaceSeed, bytes(2, 32))
    }

    // MARK: - Plants

    func testAPlantIsHeldOnce() {
        var state = ZoneCState()
        XCTAssertTrue(state.addPlant(plant(1, side: .finder)))
        // The same child arriving again, from the other side of the find.
        XCTAssertFalse(state.addPlant(plant(1, side: .sender)))

        XCTAssertEqual(state.plants.count, 1)
        XCTAssertEqual(state.plants[0].side, .finder)
        XCTAssertTrue(state.hasPlant(childSeed: seed(1)))
        XCTAssertFalse(state.hasPlant(childSeed: seed(2)))
    }

    func testASpaceSeedAlreadyAParentIsKnown() {
        var state = ZoneCState()
        state.addPlant(plant(10))

        XCTAssertTrue(state.hasPlant(parentedBy: seed(11)))
        XCTAssertTrue(state.hasPlant(parentedBy: seed(12)))
        XCTAssertFalse(state.hasPlant(parentedBy: seed(13)))
    }

    // MARK: - One find a day

    func testOneFindADay() throws {
        let store = makeStore()
        XCTAssertTrue(try store.load().canFind(onDay: 20_743))

        try store.update { $0.recordFind(onDay: 20_743) }
        let state = try store.load()
        XCTAssertFalse(state.canFind(onDay: 20_743))
        XCTAssertTrue(state.canFind(onDay: 20_744))
        // A clock set back, or a flight west, does not shut finding out.
        XCTAssertTrue(state.canFind(onDay: 20_742))
    }

    func testADayIsTheCalendarDateWherever() throws {
        let gmt = TimeZone(secondsFromGMT: 0)!
        XCTAssertEqual(ZoneCDay.number(for: Date(timeIntervalSince1970: 0), timeZone: gmt), 0)

        let london = try XCTUnwrap(TimeZone(identifier: "Europe/London"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = london
        func moment(day: Int, hour: Int, minute: Int) throws -> Date {
            try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute)))
        }

        XCTAssertEqual(ZoneCDay.number(for: try moment(day: 17, hour: 0, minute: 5), timeZone: london), 20_743)
        XCTAssertEqual(ZoneCDay.number(for: try moment(day: 17, hour: 23, minute: 55), timeZone: london), 20_743)
        XCTAssertEqual(ZoneCDay.number(for: try moment(day: 18, hour: 0, minute: 5), timeZone: london), 20_744)

        // One instant is two different days on opposite sides of the date line.
        let instant = Date(timeIntervalSince1970: 20_743 * 86_400 + 23 * 3_600 + 30 * 60)
        let auckland = try XCTUnwrap(TimeZone(secondsFromGMT: 13 * 3_600))
        let losAngeles = try XCTUnwrap(TimeZone(secondsFromGMT: -7 * 3_600))
        XCTAssertEqual(ZoneCDay.number(for: instant, timeZone: auckland), 20_744)
        XCTAssertEqual(ZoneCDay.number(for: instant, timeZone: losAngeles), 20_743)
    }

    // MARK: - No dates

    func testNoRecordCarriesADate() throws {
        let store = makeStore()
        try store.save(fullState())

        let text = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertNil(text.range(of: #"\d{4}-\d{2}-\d{2}"#, options: .regularExpression),
                     "nothing in the file reads as a date")

        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: fileURL)) as? [String: Any])
        XCTAssertEqual(Set(root.keys),
                       ["schemaVersion", "ownSeed", "sentSeeds", "owedReturns", "plants", "lastFindDay", "retiredMarks"])
        // The one day that is kept is a whole number, with no time of day.
        XCTAssertEqual(root["lastFindDay"] as? Int, 20_743)

        let expected: [String: Set<String>] = [
            "sentSeeds": ["r", "privateKey", "launchesLeft", "plantsGrown"],
            "owedReturns": ["payload", "recipientKey", "spaceSeed", "sendsLeft"],
            "plants": ["childSeed", "parentA", "parentB", "encounterID", "side"],
        ]
        for (name, keys) in expected {
            let records = try XCTUnwrap(root[name] as? [[String: Any]], name)
            XCTAssertFalse(records.isEmpty, name)
            for record in records {
                XCTAssertEqual(Set(record.keys), keys, name)
                for key in record.keys {
                    for word in ["date", "time", "birth", "stamp", "when", "created"] {
                        XCTAssertFalse(key.lowercased().contains(word), "\(name).\(key) reads as a date")
                    }
                }
            }
        }
    }
}
