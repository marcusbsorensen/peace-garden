import Foundation
import Security
import SeedCore

// Zone C's own records: what this phone keeps so that a seed it sent can be
// recognised when it is found, and so that a seed it found can be answered.
// See design/space-seeds-2026-10-16/DESIGN.md, section 5.
//
// **Nothing here carries a date.** A record that said when a seed was sent, or
// when it was found, would be read out of a backup as a diary. The records
// count launches and plants instead, and the one day that is kept (`ZoneCDay`)
// is a bare number, with no time of day.
//
// Key material is held as raw bytes. The cryptography that makes and opens it
// lives elsewhere (`ZoneCKey`, `ZoneCReturn`); this file only keeps it.

/// A seed this phone sent aloft, kept so that its returns can be opened.
///
/// The phone remembers `r` (from which the space seed is rebuilt with the mark
/// key) and the private half of the key drawn for this seed alone. Nothing else
/// of Autonaut's travels here. A record ends after 60 of the phone's own launch
/// requests, or once three plants have grown from it, and is then removed.
struct ZoneCSentSeed: Codable, Equatable, Sendable {
    static let rLength = 16
    static let privateKeyLength = 32
    /// About a month at two starts a day.
    static let launchesAtStart = 60
    static let plantLimit = 3

    /// The 16 bytes Autonaut drew.
    let r: Data
    /// The seed key's private half. It never leaves the phone: it is the one
    /// thing that lets this phone, and only this phone, open the seed's returns.
    let privateKey: Data
    var launchesLeft: Int
    var plantsGrown: Int

    /// Nil unless the key material is the right size, so a record can never
    /// reach the cryptography with bytes that cannot be a key.
    init?(
        r: Data,
        privateKey: Data,
        launchesLeft: Int = ZoneCSentSeed.launchesAtStart,
        plantsGrown: Int = 0
    ) {
        guard r.count == Self.rLength, privateKey.count == Self.privateKeyLength else { return nil }
        self.r = r
        self.privateKey = privateKey
        self.launchesLeft = launchesLeft
        self.plantsGrown = plantsGrown
    }

    /// A stored record is always live: ended ones are removed as they end.
    var isLive: Bool { launchesLeft > 0 && plantsGrown < Self.plantLimit }

    private enum CodingKeys: String, CodingKey {
        case r, privateKey, launchesLeft, plantsGrown
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        r = try container.bytes(.r, count: Self.rLength)
        privateKey = try container.bytes(.privateKey, count: Self.privateKeyLength)
        launchesLeft = try container.decode(Int.self, forKey: .launchesLeft)
        plantsGrown = try container.decode(Int.self, forKey: .plantsGrown)
    }
}

/// A return this phone owes for a seed it found, to go out in its next launch
/// requests.
///
/// The 56 bytes are the finder's half of the cross, `own seed (32) || nonce (16)
/// || checksum (8)`. They are sealed afresh at each send, so the record also
/// keeps what the sealing needs and cannot be rebuilt from the payload: the
/// sender's public seed key (from the `aloft` row the seed came in) and the
/// space seed itself, which is the context the return is sealed under.
struct ZoneCOwedReturn: Codable, Equatable, Sendable {
    static let payloadLength = 56
    static let recipientKeyLength = 32
    static let spaceSeedLength = 32
    /// Each return rides in this many of the finder's launch requests.
    static let sendsAtStart = 8

    let payload: Data
    /// The public half of the sender's seed key.
    let recipientKey: Data
    /// `r || mark`, 32 bytes. One per find, so it names the record.
    let spaceSeed: Data
    var sendsLeft: Int

    init?(
        payload: Data,
        recipientKey: Data,
        spaceSeed: Data,
        sendsLeft: Int = ZoneCOwedReturn.sendsAtStart
    ) {
        guard payload.count == Self.payloadLength,
              recipientKey.count == Self.recipientKeyLength,
              spaceSeed.count == Self.spaceSeedLength else { return nil }
        self.payload = payload
        self.recipientKey = recipientKey
        self.spaceSeed = spaceSeed
        self.sendsLeft = sendsLeft
    }

    private enum CodingKeys: String, CodingKey {
        case payload, recipientKey, spaceSeed, sendsLeft
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        payload = try container.bytes(.payload, count: Self.payloadLength)
        recipientKey = try container.bytes(.recipientKey, count: Self.recipientKeyLength)
        spaceSeed = try container.bytes(.spaceSeed, count: Self.spaceSeedLength)
        sendsLeft = try container.decode(Int.self, forKey: .sendsLeft)
    }
}

/// One plant in Zone C.
///
/// Like `PlantRecord`, only the seed and where it came from are kept: the
/// drawing follows from them. It is a different type on purpose, so that no
/// path in the ordinary garden (an offer, a release, a link) can take one.
///
/// **No birthday yet.** Each phone's plant is born where it grows, since no time
/// travels, and whether space flora ages is still to be decided. An optional
/// field can be added then without moving the schema.
struct ZoneCPlant: Codable, Equatable, Identifiable, Sendable {
    /// Which half of the find grew this plant.
    enum Side: String, Codable, Sendable {
        /// The person found someone's space seed.
        case finder
        /// The person's own space seed was found, and the finder's return came back.
        case sender
    }

    var childSeed: SeedID
    /// The two parents in canonical order, the same way round on both phones.
    var parentA: SeedID
    var parentB: SeedID
    var encounterID: Data
    var side: Side

    var lineage: Lineage {
        .crossed(parentA: parentA, parentB: parentB, encounterID: encounterID)
    }

    /// The finder and the sender reach the same child seed, so one phone holds
    /// a given plant once; that is what `ZoneCState.addPlant` relies on.
    var id: String { childSeed.hex }

    init(childSeed: SeedID, parentA: SeedID, parentB: SeedID, encounterID: Data, side: Side) {
        self.childSeed = childSeed
        self.parentA = parentA
        self.parentB = parentB
        self.encounterID = encounterID
        self.side = side
    }

    /// The plant a cross makes, built from the same result at a knock.
    init(_ cross: CrossPollinationResult, side: Side) {
        self.init(
            childSeed: cross.childSeed,
            parentA: cross.parentA,
            parentB: cross.parentB,
            encounterID: cross.encounterID,
            side: side
        )
    }
}

/// Everything Zone C keeps on this phone, in `zonec.json`.
///
/// The rules about limits live here as plain mutations on a value, so they are
/// tested without a file and a caller can make several in one `update` and
/// have them written together or not at all.
struct ZoneCState: Codable, Equatable, Sendable {
    /// Bumped when the on-disk shape changes, so an older file can be migrated
    /// rather than thrown away.
    static let currentSchemaVersion = 1
    /// A ninth pushes out the oldest.
    static let sentSeedLimit = 8
    /// While three returns are still going out, no new find is planted.
    static let owedReturnLimit = 3

    var schemaVersion: Int
    /// Zone C's own seed: 32 random bytes, minted once when first needed and
    /// kept for good. It plays at every find the part the person's own seed
    /// plays at a knock, and is not the garden's `Identity.seed`.
    var ownSeed: SeedID?
    /// Oldest first.
    var sentSeeds: [ZoneCSentSeed]
    var owedReturns: [ZoneCOwedReturn]
    var plants: [ZoneCPlant]
    /// The day of the last find, as `ZoneCDay.number` gives it. A day and no
    /// time, so that "one find a day" can be kept without a clock reading.
    var lastFindDay: Int?

    init(
        schemaVersion: Int = ZoneCState.currentSchemaVersion,
        ownSeed: SeedID? = nil,
        sentSeeds: [ZoneCSentSeed] = [],
        owedReturns: [ZoneCOwedReturn] = [],
        plants: [ZoneCPlant] = [],
        lastFindDay: Int? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.ownSeed = ownSeed
        self.sentSeeds = sentSeeds
        self.owedReturns = owedReturns
        self.plants = plants
        self.lastFindDay = lastFindDay
    }
}

// MARK: - Own seed

extension ZoneCState {
    /// Zone C's own seed, minted from `random` the first time it is asked for.
    mutating func mintOwnSeedIfNeeded(using random: (Int) throws -> Data) throws -> SeedID {
        if let ownSeed { return ownSeed }
        guard let seed = SeedID(bytes: try random(SeedID.byteCount)) else {
            throw ZoneCStore.StoreError.noRandomness(status: errSecParam)
        }
        ownSeed = seed
        return seed
    }
}

// MARK: - Sent seeds

extension ZoneCState {
    func sentSeed(forR r: Data) -> ZoneCSentSeed? {
        sentSeeds.first { $0.r == r }
    }

    /// Keeps a record for a seed about to be sent. A seed already recorded is
    /// left as it is, so a retry after a lost answer reuses the key the first
    /// attempt put in the pool. Returns whether a record was added.
    @discardableResult
    mutating func addSentSeed(_ record: ZoneCSentSeed) -> Bool {
        guard sentSeed(forR: record.r) == nil else { return false }
        sentSeeds.append(record)
        if sentSeeds.count > Self.sentSeedLimit {
            sentSeeds.removeFirst(sentSeeds.count - Self.sentSeedLimit)
        }
        return true
    }

    /// One of the phone's own launch requests was answered: every record has
    /// one fewer, and those that reach none end.
    mutating func countLaunch() {
        for index in sentSeeds.indices { sentSeeds[index].launchesLeft -= 1 }
        sentSeeds.removeAll { !$0.isLive }
    }

    /// A plant has grown from the seed with this `r`. The record ends at the
    /// third. Returns whether a live record was found.
    @discardableResult
    mutating func countPlantGrown(forR r: Data) -> Bool {
        guard let index = sentSeeds.firstIndex(where: { $0.r == r }) else { return false }
        sentSeeds[index].plantsGrown += 1
        if !sentSeeds[index].isLive { sentSeeds.remove(at: index) }
        return true
    }
}

// MARK: - Owed returns

extension ZoneCState {
    /// Whether another find may be planted, as far as the returns still going
    /// out are concerned.
    var canOweAnother: Bool { owedReturns.count < Self.owedReturnLimit }

    /// Queues a return. Refused while three are going out, and for a space seed
    /// already queued. Returns whether it was added.
    @discardableResult
    mutating func addOwedReturn(_ owed: ZoneCOwedReturn) -> Bool {
        guard canOweAnother, !owedReturns.contains(where: { $0.spaceSeed == owed.spaceSeed }) else {
            return false
        }
        owedReturns.append(owed)
        return true
    }

    /// The return to send in this launch's request. When two or three are
    /// owed they take turns: the one with the most sends left goes next, the
    /// earliest of any tie.
    func nextOwedReturn() -> ZoneCOwedReturn? {
        var next: ZoneCOwedReturn?
        for owed in owedReturns where owed.sendsLeft > (next?.sendsLeft ?? 0) { next = owed }
        return next
    }

    /// The request that carried this return was answered. It ends after the
    /// last of its sends.
    mutating func countReturnSent(forSpaceSeed spaceSeed: Data) {
        guard let index = owedReturns.firstIndex(where: { $0.spaceSeed == spaceSeed }) else { return }
        owedReturns[index].sendsLeft -= 1
        if owedReturns[index].sendsLeft <= 0 { owedReturns.remove(at: index) }
    }
}

// MARK: - Plants

extension ZoneCState {
    func hasPlant(childSeed: SeedID) -> Bool {
        plants.contains { $0.childSeed == childSeed }
    }

    /// Whether a plant already has this seed for a parent: a space seed found
    /// once is not found again.
    func hasPlant(parentedBy seed: SeedID) -> Bool {
        plants.contains { $0.parentA == seed || $0.parentB == seed }
    }

    /// Returns whether the plant was added; one already held is passed over.
    @discardableResult
    mutating func addPlant(_ plant: ZoneCPlant) -> Bool {
        guard !hasPlant(childSeed: plant.childSeed) else { return false }
        plants.append(plant)
        return true
    }
}

// MARK: - One find a day

extension ZoneCState {
    /// A find is allowed on any day but the day of the last one. Not "after":
    /// a clock set back, or a flight west, must not shut finding out for days.
    func canFind(onDay day: Int) -> Bool { lastFindDay != day }

    mutating func recordFind(onDay day: Int) { lastFindDay = day }
}

/// The number of a day: whole days since 1 January 1970 on the calendar date
/// the person is living, with no time of day.
///
/// The date is read in `timeZone` and then counted as if it were UTC, so a day
/// is the person's own day wherever they are, and two moments on one calendar
/// date have one number.
enum ZoneCDay {
    static func number(for date: Date, timeZone: TimeZone = .current) -> Int {
        var local = Calendar(identifier: .gregorian)
        local.timeZone = timeZone
        let parts = local.dateComponents([.year, .month, .day], from: date)
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = .gmt
        let midnight = utc.date(from: parts) ?? date
        return Int((midnight.timeIntervalSince1970 / 86_400).rounded(.down))
    }
}

private extension KeyedDecodingContainer {
    /// Bytes of exactly this length, or the whole file is refused as corrupt.
    func bytes(_ key: Key, count: Int) throws -> Data {
        let data = try decode(Data.self, forKey: key)
        guard data.count == count else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: self,
                debugDescription: "expected \(count) bytes, found \(data.count)"
            )
        }
        return data
    }
}
