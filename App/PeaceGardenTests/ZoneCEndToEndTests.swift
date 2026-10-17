import CryptoKit
import SeedCore
import XCTest
@testable import PeaceGarden

/// Two engines and a pool: Ana's seed goes up, Ben finds it, his return comes
/// down to her, and she grows the plant he has (`DESIGN.md` §5.1, §5.3).
///
/// The service is `PoolServer`, an in-memory stand-in for the two pools the
/// real service keeps (S1, S2): a row is stored after the bundles are drawn,
/// the pools are capped at 2,048 and lose a random row when over, a draw is 128
/// distinct rows topped up with padding. Its random choices follow a seed, so a
/// run is the same every time. Each phone is a `ZoneCEngineTests.Phone`: a
/// temporary suite folder, a temporary store, and the real `ZoneCExchange` and
/// `ZoneCEngine` over them.
final class ZoneCEndToEndTests: XCTestCase {

    // MARK: - The pools

    private struct SplitMix64: RandomNumberGenerator {
        var state: UInt64

        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
    }

    /// `POST /api/walk/pending` as the service answers it, and nothing else.
    final class PoolServer: PlotTransport, @unchecked Sendable {
        /// P = Q, and B = R, as the build plan has them.
        static let capacity = 2_048
        static let bundle = 128

        private let lock = NSLock()
        private var generator: SplitMix64
        /// Real public keys, many times over: padding is a key's public half
        /// and random bytes, and making a key for each of the thousands of rows
        /// a crowd adds would cost more than the test is about.
        private let publicKeys: [Data]
        private(set) var aloft: [Data] = []
        private(set) var back: [Data] = []
        private var aloftSet = Set<Data>()
        private var backSet = Set<Data>()
        private var offered: [Data] = []
        private(set) var requests = 0
        /// The slots of the latest request, as the service stored them.
        private(set) var lastAloft: Data?
        private(set) var lastBack: Data?

        init(seed: UInt64) {
            generator = SplitMix64(state: seed)
            publicKeys = (0..<256).map { _ in Curve25519.KeyAgreement.PrivateKey().publicKey.rawRepresentation }
        }

        /// The next draw of `aloft` includes this row, so that a test can say
        /// that a phone was offered a seed without waiting for chance to.
        func offerInNextDraw(aloft row: Data) { lock.withLock { offered.append(row) } }

        /// `count` other phones' requests: padding, stored in both pools.
        func fill(crowd count: Int) {
            lock.withLock {
                for _ in 0..<count {
                    put(aloftPadding(), into: &aloft, &aloftSet)
                    put(backPadding(), into: &back, &backSet)
                }
            }
        }

        func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
            lock.withLock { respond(to: request) }
        }

        // Under the lock from here down.

        private func respond(to request: URLRequest) -> (Data, HTTPURLResponse) {
            requests += 1
            guard request.url?.path() == "/api/walk/pending",
                  let object = try? JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any],
                  let aloftText = object["aloft"] as? String,
                  let backText = object["back"] as? String,
                  let aloftRow = ZoneCSlots.bytes(fromHex: aloftText, as: .aloft),
                  let backRow = ZoneCSlots.bytes(fromHex: backText, as: .back)
            else { return (Data(#"{"error":"Not a request."}"#.utf8), status(400, request)) }

            let forced = offered
            offered = []
            let aloftAnswer = draw(from: aloft, forced: forced, padding: { aloftPadding() })
            let backAnswer = draw(from: back, forced: [], padding: { backPadding() })
            // Stored after the bundles are drawn, so never returned to its own request.
            put(aloftRow, into: &aloft, &aloftSet)
            put(backRow, into: &back, &backSet)
            lastAloft = aloftRow
            lastBack = backRow

            let body = #"{"offers":[],"wild":[],"aloft":"\#(hex(aloftAnswer))","back":"\#(hex(backAnswer))"}"#
            return (Data(body.utf8), status(200, request))
        }

        private func status(_ code: Int, _ request: URLRequest) -> HTTPURLResponse {
            HTTPURLResponse(url: request.url!, statusCode: code, httpVersion: nil, headerFields: nil)!
        }

        private func hex(_ rows: [Data]) -> String {
            SuiteHex.encode(rows.reduce(into: Data()) { $0.append($1) })
        }

        private func randomBytes(_ count: Int) -> Data {
            Data((0..<count).map { _ in UInt8(truncatingIfNeeded: generator.next()) })
        }

        private func aloftPadding() -> Data {
            randomBytes(32) + publicKeys[Int(generator.next() % UInt64(publicKeys.count))]
        }

        private func backPadding() -> Data {
            publicKeys[Int(generator.next() % UInt64(publicKeys.count))] + randomBytes(72)
        }

        private func put(_ row: Data, into pool: inout [Data], _ seen: inout Set<Data>) {
            guard seen.insert(row).inserted else { return }
            pool.append(row)
            if pool.count > Self.capacity {
                let victim = Int(generator.next() % UInt64(pool.count))
                seen.remove(pool[victim])
                pool.swapAt(victim, pool.count - 1)
                pool.removeLast()
            }
        }

        /// 128 distinct rows: what `forced` names, then rows chosen at random,
        /// then padding if the pool holds fewer; in no particular order.
        private func draw(from pool: [Data], forced: [Data], padding: () -> Data) -> [Data] {
            var rows = forced
            var order = Array(pool.indices)
            let chosen = min(Self.bundle - rows.count, order.count)
            for index in 0..<chosen {
                let other = index + Int(generator.next() % UInt64(order.count - index))
                order.swapAt(index, other)
                rows.append(pool[order[index]])
            }
            while rows.count < Self.bundle { rows.append(padding()) }
            for index in stride(from: rows.count - 1, to: 0, by: -1) {
                rows.swapAt(index, Int(generator.next() % UInt64(index + 1)))
            }
            return rows
        }
    }

    // MARK: - Phones

    private var phones: [ZoneCEngineTests.Phone] = []

    override func tearDown() {
        for phone in phones { phone.tearDown() }
        phones = []
        super.tearDown()
    }

    private func phone(_ name: String) -> ZoneCEngineTests.Phone {
        let phone = ZoneCEngineTests.Phone(name)
        phone.installAutonaut()
        phones.append(phone)
        return phone
    }

    /// 16 bytes, as Autonaut draws `r`.
    private let r = Data((0..<16).map { UInt8($0 &+ 0x21) })

    private var spaceSeed: Data { ZoneCMark.spaceSeed(from: r)! }

    private func isChange(_ access: SuiteGroup.Access) -> Bool {
        switch access {
        case .createFolder, .write, .setBackupFlag, .setDates, .move, .remove: return true
        case .list, .exists, .inspect, .read: return false
        }
    }

    // MARK: - One find, from end to end

    func testBenFindsAnasSeedAndAnaGrowsTheSamePlant() async throws {
        let server = PoolServer(seed: 1)
        let ana = phone("Ana")
        let ben = phone("Ben")

        // Ana sends a seed from Autonaut, and opens Peace Garden.
        ana.autonautSends(r)
        try await ana.launch(server)
        XCTAssertEqual(ana.outFiles, [], "answered with its bundles, so the seed has gone")
        let record = try XCTUnwrap(ana.state.sentSeeds.first)
        let key = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: record.privateKey)
        XCTAssertEqual(record.r, r)
        XCTAssertEqual(server.aloft, [spaceSeed + key.publicKey.rawRepresentation], "the pool holds her seed and the key's public half")

        // Ben opens Peace Garden. The pool is smaller than a bundle, so every
        // row is offered, Ana's seed among them.
        ben.accesses.clear()
        try await ben.launch(server)
        let bensPlant = try XCTUnwrap(ben.state.plants.first)
        XCTAssertEqual(ben.state.plants.count, 1)
        XCTAssertEqual(bensPlant.side, .finder)
        XCTAssertEqual(ben.seedsForAutonaut, [spaceSeed], "Autonaut is handed Ana's seed, as itself")
        XCTAssertEqual(ben.state.owedReturns.count, 1)
        XCTAssertEqual(ben.state.lastFindDay, ZoneCDay.number(for: ben.clock.value))

        // A find writes only to `in/`.
        let changes = ben.accesses.events.filter(isChange)
        XCTAssertFalse(changes.isEmpty)
        for change in changes {
            switch change {
            case .move(_, let to): XCTAssertTrue(to.hasPrefix("Seeds/v1/in/"), "moved to \(to)")
            case .remove(let path): XCTFail("deleted \(path)")
            case .write(let path): XCTAssertTrue(path.hasPrefix("Seeds/v1/tmp/peacegarden-"), "wrote \(path)")
            default: break
            }
        }

        // Ben's next launch carries the return, sealed to the key Ana put up.
        let payload = try XCTUnwrap(ZoneCReturn.Payload(bytes: ben.state.owedReturns[0].payload))
        try await ben.launch(server)
        let carried = try XCTUnwrap(server.lastBack)
        XCTAssertEqual(ZoneCReturn.open(carried, with: key, spaceSeed: spaceSeed), payload)
        XCTAssertEqual(ben.state.owedReturns.map(\.sendsLeft), [ZoneCOwedReturn.sendsAtStart - 1])

        // Ana opens Peace Garden and the return is in her bundle.
        ana.accesses.clear()
        try await ana.launch(server)
        let anasPlant = try XCTUnwrap(ana.state.plants.first)
        XCTAssertEqual(ana.state.plants.count, 1)
        XCTAssertEqual(anasPlant.side, .sender)
        XCTAssertEqual(ana.state.sentSeeds.map(\.plantsGrown), [1])
        XCTAssertEqual(ana.accesses.events.filter(isChange), [], "a return writes nothing to the group")
        XCTAssertEqual(ana.inFiles, [])

        // The same plant: child, encounter, checksum and parents.
        XCTAssertEqual(anasPlant.childSeed, bensPlant.childSeed)
        XCTAssertEqual(anasPlant.encounterID, bensPlant.encounterID)
        XCTAssertEqual(anasPlant.parentA, bensPlant.parentA)
        XCTAssertEqual(anasPlant.parentB, bensPlant.parentB)

        // And it is what a knock gives. At a knock each phone calls these
        // functions with its own seed and nonce first and the other's second;
        // Ben stands as the one phone, with Zone C's own seed, and Ana as the
        // other, with the space seed she sent and the `r` Autonaut drew.
        let own = try ben.store.ownSeed()
        let sent = try XCTUnwrap(SeedID(bytes: spaceSeed))
        let atBensEnd = CrossPollinationResult(
            localSeed: own, remoteSeed: sent, localNonce: payload.nonce, remoteNonce: r
        )
        let atAnasEnd = CrossPollinationResult(
            localSeed: sent, remoteSeed: own, localNonce: r, remoteNonce: payload.nonce
        )
        for knock in [atBensEnd, atAnasEnd] {
            XCTAssertEqual(knock.childSeed, anasPlant.childSeed)
            XCTAssertEqual(knock.encounterID, anasPlant.encounterID)
            XCTAssertEqual(knock.parentA, anasPlant.parentA)
            XCTAssertEqual(knock.parentB, anasPlant.parentB)
            XCTAssertEqual(knock.checksum, payload.checksum)
        }
        XCTAssertEqual(anasPlant.childSeed, Pollination.cross(
            seedA: sent, seedB: own,
            encounterID: Pollination.encounterID(seedA: sent, seedB: own, nonceA: r, nonceB: payload.nonce)
        ))

        // Ben's return goes on for its eight sends and then stops; copies in the
        // pool grow nothing more on Ana's phone.
        for _ in 0..<7 { try await ben.launch(server) }
        XCTAssertEqual(ben.state.owedReturns, [])
        try await ana.launch(server)
        XCTAssertEqual(ana.state.plants.count, 1)
        XCTAssertEqual(ana.state.sentSeeds.map(\.plantsGrown), [1])
    }

    // MARK: - Several finders

    func testSeveralFindersGrowSeveralPlantsOnAnasPhoneUpToThree() async throws {
        let server = PoolServer(seed: 3)
        let ana = phone("Ana")
        let finders = ["Ben", "Cleo", "Dev", "Eve"].map { phone($0) }
        ana.autonautSends(r)
        try await ana.launch(server)

        // Each finds the seed on one launch and sends the return on the next.
        for finder in finders { try await finder.launch(server) }
        for finder in finders { try await finder.launch(server) }
        let theirs = finders.compactMap { $0.state.plants.first?.childSeed }
        XCTAssertEqual(Set(theirs).count, 4, "four finders, four different plants")

        try await ana.launch(server)

        XCTAssertEqual(ana.state.plants.count, 3, "up to three from one seed")
        XCTAssertEqual(ana.state.sentSeeds, [], "and then the record is done")
        XCTAssertTrue(ana.state.plants.allSatisfy { $0.side == .sender })
        XCTAssertEqual(Set(ana.state.plants.map(\.childSeed)).count, 3)
        XCTAssertTrue(Set(ana.state.plants.map(\.childSeed)).isSubset(of: Set(theirs)), "each is the twin of a finder's plant")

        // Later launches grow no fourth: the record that would open it has gone.
        try await ana.launch(server)
        try await ana.launch(server)
        XCTAssertEqual(ana.state.plants.count, 3)
    }

    // MARK: - How often it arrives (DESIGN §5.3)

    /// One sender among a crowd that makes 1,000 starts a day, with the pools
    /// full, a bundle of 128, and a sender who opens Peace Garden twice a day.
    /// §5.3 gives "about 9 in 10" for that, from 8 copies × 128 × (her starts ÷
    /// all starts): about two offers of a copy, so a copy is drawn at least once
    /// with a probability near 1 − e⁻² = 87%. The finder is offered the seed at
    /// his first launch, since finding it is a separate chance, and sends his
    /// return at his next eight.
    private func trial(seed: UInt64) async throws -> Int? {
        let server = PoolServer(seed: seed)
        server.fill(crowd: PoolServer.capacity)
        let ana = ZoneCEngineTests.Phone("Ana")
        let ben = ZoneCEngineTests.Phone("Ben")
        ana.installAutonaut()
        ben.installAutonaut()
        defer { ana.tearDown(); ben.tearDown() }

        ana.autonautSends(r)
        try await ana.launch(server)
        server.offerInNextDraw(aloft: try XCTUnwrap(server.lastAloft))

        var anasLaunches = 0
        for _ in 0..<7 {
            for _ in 0..<2 {
                server.fill(crowd: 500)
                try await ben.launch(server)
                try await ana.launch(server)
                anasLaunches += 1
                if !ana.state.plants.isEmpty { return anasLaunches }
            }
            ben.advance(days: 1)
            ana.advance(days: 1)
        }
        return nil
    }

    func testTheTwinAppearsInsideTheDeliveryBandAtAThousandStartsADay() async throws {
        let trials = 24
        var launches: [Int] = []
        for seed in 1...UInt64(trials) {
            if let found = try await trial(seed: seed) { launches.append(found) }
        }
        let share = Double(launches.count) / Double(trials)
        print("A4 delivery band: \(launches.count) of \(trials) reached their sender, after launches \(launches.sorted())")

        // About 87% are expected; §5.3 says "about 9 in 10". Well under it
        // would mean returns are lost, and 100% in every run would mean the
        // bundles were not being drawn at random.
        XCTAssertGreaterThanOrEqual(share, 0.65, "\(launches.count) of \(trials)")
        XCTAssertGreaterThan(Set(launches).count, 1, "it takes a different number of launches, as chance does")
        // The earliest is the second launch: the first launch after the find
        // carried padding, and the return rides in the next.
        XCTAssertGreaterThanOrEqual(launches.min() ?? 2, 2)
    }
}
