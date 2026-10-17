import CryptoKit
import Foundation
import SeedCore

/// The finder's half of a find: the `aloft` bundle that comes down in each
/// answer, checked for a space seed, and the cross, the plant, the file for
/// Autonaut and the owed return that one find makes (`DESIGN.md` §5.1 step 3,
/// §5.2, §5.3).
///
/// ## What counts as a find
///
/// Of the 128 rows, almost all padding, a row is a candidate when
///
/// - it is 64 bytes whose second half can be a key (`ZoneCSlots.splitSeedSlot`);
/// - its first half passes the mark (`ZoneCMark.isValid`), so that it was made by
///   a Peace Garden holding K and is not padding or a stranger's guess;
/// - this phone did not send it: it holds no record of it, and the mark is not
///   among those it kept from records that have ended (`ZoneCState.hasSent`);
/// - and it is not already a parent of a plant in Zone C, so a seed found once
///   is not found again.
///
/// **At most one a day** (Q2): the number of the day of the last find is kept in
/// Zone C's store, and a find is allowed on any other day. Of several candidates
/// the first in the bundle's order is taken, and the service orders a bundle at
/// random.
///
/// ## The gates
///
/// Nothing is found unless all of these hold, checked before any work is done
/// and again under the store's lock at the moment of writing:
///
/// - Autonaut is present (`Presence/v1/autonaut`), so there is someone to hand
///   the seed to;
/// - fewer than three files wait in `in/`, which is the stand-in for knowing that
///   Autonaut is still installed (`SuiteTransit.inCapacity`);
/// - fewer than three returns are owed: while three finds' returns are still
///   going out, no new find is planted, and the seed drifts on for someone else.
///
/// ## What a find does, in order
///
/// 1. Zone C's own seed is taken (and minted, if this is the first find).
/// 2. The cross is made: `CrossPollinationResult(localSeed: own, remoteSeed:
///    found, localNonce: n, remoteNonce: r)`, with `n` 16 fresh bytes and `r`
///    the first 16 bytes of the space seed (§5.2). The sender's phone makes the
///    same cross from the other side.
/// 3. **The return is sealed once, before anything is written**, to the seed key
///    in the row. A key CryptoKit refuses leaves the seed not found: nothing
///    is planted, and no day is spent (`REVIEW-A2.md`, finding 4).
/// 4. The found seed goes to `in/` as itself, for Autonaut.
/// 5. In one write, the plant (marked as grown because this person found a
///    seed), the owed return (queued for eight launches) and the day.
///
/// A find writes to the App Group once, to `in/`. If the last write then fails,
/// Autonaut has the seed and Zone C remembers nothing, so the same seed can be
/// found again at the next launch and Autonaut is handed it twice. That is the
/// better way for the two writes to fail: the other order loses a seed.
///
/// Synchronous, and light (one mark per row); `ZoneCEngine` decides where it
/// runs.
struct ZoneCFinder: Sendable {
    let store: ZoneCStore
    let transit: SuiteTransit
    private let now: @Sendable () -> Date
    private let nonce: @Sendable () -> Data

    /// - Parameters:
    ///   - now: the moment of the find, for the day number. Injected so a test
    ///     can say what day it is.
    ///   - nonce: the 16 fresh bytes of the finder's half of the cross. Injected
    ///     so a test can say what they are; the default is what a knock uses.
    init(
        store: ZoneCStore,
        transit: SuiteTransit = SuiteTransit(),
        now: @escaping @Sendable () -> Date = { Date() },
        nonce: @escaping @Sendable () -> Data = { Pollination.makeNonce() }
    ) {
        self.store = store
        self.transit = transit
        self.now = now
        self.nonce = nonce
    }

    private struct Candidate {
        /// `r ‖ mark`, 32 bytes.
        let spaceSeed: Data
        /// `r`, 16 bytes: the sender's nonce.
        let r: Data
        let seed: SeedID
        let seedKey: Curve25519.KeyAgreement.PublicKey
    }

    // MARK: - At an answer

    /// Looks through the `aloft` rows of an answer and makes the one find a day
    /// allows. Returns the plant it grew, or nil.
    @discardableResult
    func find(in rows: [Data]) -> ZoneCPlant? {
        // Cheapest first, and before anything is read from a row.
        guard !rows.isEmpty,
              transit.autonautIsPresent,
              transit.seedsWaitingForAutonaut() < SuiteTransit.inCapacity,
              let state = try? store.load()
        else { return nil }
        let day = ZoneCDay.number(for: now())
        guard state.canFind(onDay: day), state.canOweAnother else { return nil }

        for candidate in candidates(in: rows, given: state) {
            if let plant = take(candidate, onDay: day) { return plant }
        }
        return nil
    }

    // MARK: - Choosing

    /// The rows that are space seeds this phone may find, in the bundle's order,
    /// one for each seed.
    private func candidates(in rows: [Data], given state: ZoneCState) -> [Candidate] {
        var seen = Set<Data>()
        var found: [Candidate] = []
        for row in rows {
            guard let (spaceSeed, seedKey) = ZoneCSlots.splitSeedSlot(row),
                  ZoneCMark.isValid(spaceSeed),
                  seen.insert(spaceSeed).inserted,
                  let seed = SeedID(bytes: spaceSeed)
            else { continue }
            let r = Data(spaceSeed.prefix(ZoneCMark.randomLength))
            // Its own seeds, live or ended, and one found already.
            guard !state.hasSent(spaceSeed: spaceSeed), !state.hasPlant(parentedBy: seed) else { continue }
            found.append(Candidate(spaceSeed: spaceSeed, r: r, seed: seed, seedKey: seedKey))
        }
        return found
    }

    // MARK: - Taking

    private func take(_ candidate: Candidate, onDay day: Int) -> ZoneCPlant? {
        guard let own = try? store.ownSeed() else { return nil }
        // 16 bytes, as at a knock; the same length as `r`.
        let n = nonce()
        guard n.count == ZoneCMark.randomLength else { return nil }

        let cross = CrossPollinationResult(
            localSeed: own,
            remoteSeed: candidate.seed,
            localNonce: n,
            remoteNonce: candidate.r
        )
        guard let payload = ZoneCReturn.Payload(ownSeed: own.bytes, nonce: n, checksum: cross.checksum),
              // Sealed once now, to learn that the key is one that can be sealed
              // to. Each send seals afresh (`ZoneCExchange`), so this copy is
              // thrown away.
              (try? ZoneCReturn.seal(payload, to: candidate.seedKey, spaceSeed: candidate.spaceSeed)) != nil,
              let owed = ZoneCOwedReturn(
                payload: payload.bytes,
                recipientKey: candidate.seedKey.rawRepresentation,
                spaceSeed: candidate.spaceSeed
              )
        else { return nil }

        let plant = ZoneCPlant(cross, side: .finder)
        let transit = self.transit
        return try? store.update { state -> ZoneCPlant? in
            // The gates again, on the state that is about to be written.
            guard state.canFind(onDay: day),
                  state.canOweAnother,
                  !state.hasSent(spaceSeed: candidate.spaceSeed),
                  !state.hasPlant(parentedBy: candidate.seed)
            else { return nil }
            // The file first: a throw leaves the store as it was.
            guard try transit.deliver(foundSeed: candidate.spaceSeed) == .delivered else { return nil }
            state.addPlant(plant)
            state.addOwedReturn(owed)
            state.recordFind(onDay: day)
            return plant
        }
    }
}
