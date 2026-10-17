import CryptoKit
import Foundation
import SeedCore

/// The sender's half of a find: the returns that come down in each answer, tried
/// against every live record, and the plants they grow (`DESIGN.md` §5.3,
/// "Opening a return").
///
/// ## At each answer
///
/// The `back` bundle is 128 rows, almost all padding. Each row is tried with
/// the key of each live record, at most 8 × 128 = 1,024 key agreements. A row
/// opens only for the record whose seed key it was sealed to, and only for the
/// space seed it answers (the HPKE context binds it), so a row for another
/// sender, a damaged row and padding all fail the same way and are not told
/// apart. For each return that opens:
///
/// 1. the cross is rebuilt from what this phone already knows (the space seed it
///    sent, and its own `r`) and what the return carries (the finder's own seed
///    in Zone C and the finder's nonce), as the sender's side of the cross
///    (`DESIGN.md` §5.2): `CrossPollinationResult(localSeed: space seed,
///    remoteSeed: finder's seed, localNonce: r, remoteNonce: nonce)`;
/// 2. the checksum is compared with the one in the return. A difference means the
///    two phones are on different versions, so nothing grows, as with a link's
///    reply;
/// 3. a plant Zone C already holds is passed over, so the eight copies of one
///    return grow one plant;
/// 4. otherwise the plant is grown, marked as grown because the person's seed
///    was found, and the record counts it. A record ends at the third.
///
/// **Nothing is written to the App Group.** A return only ever adds to Zone C's
/// own store.
///
/// ## Where it runs
///
/// These are synchronous, and `receive(back:)` is the 1,024 key agreements: about
/// 100 ms on a Mac and a few hundred on the oldest phone Peace Garden supports.
/// It must not run on the main actor. `ZoneCEngine` is the one place that
/// decides where the work runs, and it puts all of it off the main actor.
struct ZoneCReturns: Sendable {
    /// One attempt to open one row, with one record's seed key, for the space
    /// seed that key was sent beside. Injected so that a test can see where the
    /// work runs and how often.
    typealias Opening = @Sendable (
        _ row: Data,
        _ seedKey: Curve25519.KeyAgreement.PrivateKey,
        _ spaceSeed: Data
    ) -> ZoneCReturn.Payload?

    static let realOpening: Opening = { row, seedKey, spaceSeed in
        ZoneCReturn.open(row, with: seedKey, spaceSeed: spaceSeed)
    }

    /// A return that opened, with the record whose key opened it.
    struct Opened: Equatable, Sendable {
        /// The `r` of the record: Autonaut's 16 bytes, and the sender's nonce.
        let r: Data
        /// `r ‖ mark`, 32 bytes: the seed that was found.
        let spaceSeed: Data
        let payload: ZoneCReturn.Payload
    }

    let store: ZoneCStore
    private let opening: Opening

    init(store: ZoneCStore, opening: @escaping Opening = ZoneCReturns.realOpening) {
        self.store = store
        self.opening = opening
    }

    // MARK: - At an answer

    /// Opens what the `back` bundle holds for this phone's live records, and
    /// grows the plants. Returns the plants that grew.
    @discardableResult
    func receive(back rows: [Data]) -> [ZoneCPlant] {
        openedReturns(in: rows).compactMap { grow(from: $0) }
    }

    // MARK: - Opening

    /// The returns in `rows` that open, in the order of the rows. Reads the
    /// store and writes nothing.
    ///
    /// A phone with no live record does no cryptography at all. A row that opens
    /// for one record is not tried against the others: it was sealed to one key.
    func openedReturns(in rows: [Data]) -> [Opened] {
        guard !rows.isEmpty, let records = try? store.load().sentSeeds, !records.isEmpty else { return [] }
        // Made once for the whole bundle, not once for each row.
        let keyed: [(r: Data, spaceSeed: Data, seedKey: Curve25519.KeyAgreement.PrivateKey)] = records.compactMap {
            guard let spaceSeed = ZoneCMark.spaceSeed(from: $0.r),
                  let seedKey = try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: $0.privateKey)
            else { return nil }
            return ($0.r, spaceSeed, seedKey)
        }
        var opened: [Opened] = []
        for row in rows {
            for record in keyed {
                if let payload = opening(row, record.seedKey, record.spaceSeed) {
                    opened.append(Opened(r: record.r, spaceSeed: record.spaceSeed, payload: payload))
                    break
                }
            }
        }
        return opened
    }

    // MARK: - Growing

    /// The plant one opened return makes, or nil: the checksum differs, Zone C
    /// holds the plant already, the record has ended, or the store would not
    /// take it.
    ///
    /// The record, the plant and the count are changed together in one write,
    /// and the record is looked for in that write, so a return that arrives as
    /// the third plant of a record is the last the record takes however many
    /// copies came down in the same answer.
    func grow(from opened: Opened) -> ZoneCPlant? {
        guard let sent = SeedID(bytes: opened.spaceSeed),
              let finders = SeedID(bytes: opened.payload.ownSeed) else { return nil }
        // The sender's side of the cross: the seed it sent is its own, and the
        // finder's seed in Zone C is the other's.
        let cross = CrossPollinationResult(
            localSeed: sent,
            remoteSeed: finders,
            localNonce: opened.r,
            remoteNonce: opened.payload.nonce
        )
        guard cross.checksum == opened.payload.checksum else { return nil }
        let plant = ZoneCPlant(cross, side: .sender)
        return try? store.update { state -> ZoneCPlant? in
            guard state.sentSeed(forR: opened.r) != nil, state.addPlant(plant) else { return nil }
            state.countPlantGrown(forR: opened.r)
            return plant
        }
    }
}
