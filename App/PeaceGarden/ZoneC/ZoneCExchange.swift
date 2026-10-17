import CryptoKit
import Foundation
import SeedCore

/// Zone C's share of the launch request: what goes in its two slots, what is
/// done once the service has answered, and where the answer's bundles go.
///
/// The request is the one `GardenModel.catchUpOnTheAsking` already makes when
/// the app opens, `POST /api/walk/pending`. Every phone with the switch on sends
/// it at each start, with meetings or without, and every request carries two
/// slots, `aloft` (64 bytes) and `back` (104 bytes) as lowercase hex. Most carry
/// padding. A space seed leaving, or a return being sent, is the same length
/// and the same shape, so nothing on the wire singles it out (`DESIGN.md`
/// §4.2, §4.3).
///
/// ## Consent (`DESIGN.md` §7, item 16)
///
/// **Only while Zone C's own switch is on** does this take a seed from `out/`,
/// keep a record of it, carry it, carry a return, or hand the answer's bundles
/// on. While it is off both slots are padding, `out/` is not opened, and the
/// request is otherwise the same. That keeps the crowd whole and takes nothing
/// from the person who has not turned Zone C on. The switch is a setting the app
/// owns (`enabledKey`, off unless set), read through an accessor so that a test
/// can say which way it stands. The launch switch ("News from the garden",
/// `Sharing.wantsInvitations`) is the caller's and still stops the request
/// altogether.
///
/// ## A seed that leaves (R2)
///
/// A request can be lost after the service has stored its slot, and the app
/// cannot tell that from a request that never arrived. So the record of a seed,
/// with the private half of its seed key, is **written before the request goes**,
/// and a seed that has not been answered keeps its `out` file. The next launch
/// finds the file, finds the record, and sends the same key again: the pool
/// takes the same row twice and keeps it once. Had the record been written
/// after the answer, the next launch would draw a new key, put a second row in
/// the pool for one seed, and a finder who met both would grow two plants.
///
/// - The `out` file is deleted only after the request carrying it was answered.
/// - A launch is counted against the records, and a return's send against the
///   return, only then too.
/// - Only the first request of a launch carries a seed or a return. A garden of
///   more than 128 meetings sends two, and the second carries padding.
///
/// ## What goes wrong quietly
///
/// A store that cannot be read or written, a folder that cannot be opened, a
/// key that will not seal: each sends padding in that slot and leaves the file
/// where it is. Zone C never stops the request, because a phone that sends
/// fewer requests is a phone that can be told apart.
///
/// The calls are synchronous file work inside an async function, and run off
/// the main actor when called from it.
struct ZoneCExchange: Sendable {
    /// The setting behind Zone C's switch. Off unless the person has turned it
    /// on, because consent cannot be a switch that starts on (item 16). The row
    /// in Settings is package A5's, and writes this key.
    static let enabledKey = "zonec.enabled.v1"

    /// Whether Zone C is on, as `UserDefaults` has it. Off when nothing is set.
    @Sendable
    static func switchFromDefaults() -> Bool {
        UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? false
    }

    let transit: SuiteTransit
    let store: ZoneCStore
    let bundles: any ZoneCBundles
    private let isOn: @Sendable () -> Bool
    private let keys: ZoneCSlots.KeyGenerator
    private let random: ZoneCSlots.RandomBytes

    /// - Parameters:
    ///   - isOn: whether Zone C's switch is on. Read once for each launch.
    ///   - keys: the source of key pairs, for a seed's key and for padding.
    ///     Leave this and `random` alone outside tests.
    init(
        transit: SuiteTransit = SuiteTransit(),
        store: ZoneCStore,
        bundles: any ZoneCBundles = ZoneCNoBundles(),
        isOn: @escaping @Sendable () -> Bool = ZoneCExchange.switchFromDefaults,
        keys: @escaping ZoneCSlots.KeyGenerator = ZoneCSlots.freshKey,
        random: @escaping ZoneCSlots.RandomBytes = ZoneCSlots.systemRandom
    ) {
        self.transit = transit
        self.store = store
        self.bundles = bundles
        self.isOn = isOn
        self.keys = keys
        self.random = random
    }

    /// Zone C as the app has it: its own store beside the garden's file, the
    /// suite's real folder, and the switch in `UserDefaults`.
    init(besideGardenAt garden: GardenStore) {
        self.init(store: ZoneCStore(besideGardenAt: garden))
    }

    // MARK: - One launch

    /// Asks the service, with the two slots filled as the rules above say, and
    /// does what a launch does about the answer. Returns what `pending` heard,
    /// and throws what it throws.
    func ask(plots: PlotService, tokens: [String]) async throws -> PlotService.Pending {
        // Read once. The slots, the sink and the counting all follow the same
        // answer, so a switch turned over while the request is out cannot
        // leave a seed half taken.
        let zoneCIsOn = isOn()
        let first = firstRequest(zoneCIsOn: zoneCIsOn)
        let answered = Answered()
        let keys = self.keys
        let random = self.random

        let outcome: Result<PlotService.Pending, any Error>
        do {
            outcome = .success(try await plots.pending(
                tokens: tokens,
                slots: { request in
                    request == 0 ? first.slots : AskingSlots.padding(keys: keys, random: random)
                },
                answered: { request in
                    if request == 0 { answered.mark() }
                }
            ))
        } catch {
            outcome = .failure(error)
        }

        // The first request was answered, even if a later one was not: the
        // seed and the return it carried have arrived, and the launch counts.
        if answered.isMarked {
            if zoneCIsOn, case .success(let heard) = outcome {
                await bundles.receive(aloft: heard.aloft, back: heard.back)
            }
            conclude(first)
        }
        return try outcome.get()
    }

    // MARK: - What the first request carries

    private struct FirstRequest: Sendable {
        var slots: AskingSlots
        /// The `out` file whose seed rides in `aloft`, if one does.
        var seed: SentSeed?
        /// The space seed of the owed return that rides in `back`, if one does.
        var returnSpaceSeed: Data?
    }

    private func firstRequest(zoneCIsOn: Bool) -> FirstRequest {
        let sending = zoneCIsOn ? seedToSend() : nil
        let returning = zoneCIsOn ? returnToSend() : nil
        let slots = AskingSlots(
            aloft: sending?.slot ?? ZoneCSlots.seedPadding(keys: keys, random: random),
            back: returning?.slot ?? ZoneCSlots.returnPadding(keys: keys, random: random)
        ) ?? AskingSlots.padding(keys: keys, random: random)
        return FirstRequest(
            slots: slots,
            seed: sending?.seed,
            returnSpaceSeed: returning?.spaceSeed
        )
    }

    private enum Trouble: Error {
        case notAKey
    }

    /// The first seed waiting in `out/`, by name (every date in the folder is
    /// the same, so a name is all there is to order by), with its record
    /// already in the store and the `aloft` slot built from the record's key.
    ///
    /// Nil, and so padding, when nothing waits or when the record cannot be
    /// kept: a seed that leaves without its record is the failure R2 is about.
    private func seedToSend() -> (seed: SentSeed, slot: Data)? {
        guard let seed = transit.seedsWaitingToLeave().min(by: { $0.name < $1.name }),
              let spaceSeed = ZoneCMark.spaceSeed(from: seed.r) else { return nil }
        do {
            // One write: the record that is already there, from an attempt
            // that was not answered, or a new one with a key drawn now.
            let keyBytes = try store.update { state -> Data in
                if let record = state.sentSeed(forR: seed.r) { return record.privateKey }
                let key = keys().rawRepresentation
                guard let record = ZoneCSentSeed(r: seed.r, privateKey: key) else { throw Trouble.notAKey }
                state.addSentSeed(record)
                return key
            }
            let seedKey = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: keyBytes)
            guard let slot = ZoneCSlots.seedSlot(spaceSeed: spaceSeed, seedKey: seedKey) else { return nil }
            return (seed, slot)
        } catch {
            return nil
        }
    }

    /// The owed return whose turn it is, sealed afresh to its sender's seed
    /// key, so that no two copies share a byte.
    private func returnToSend() -> (spaceSeed: Data, slot: Data)? {
        guard let owed = (try? store.load())?.nextOwedReturn(),
              let payload = ZoneCReturn.Payload(bytes: owed.payload),
              let recipient = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: owed.recipientKey),
              let sealed = try? ZoneCReturn.seal(payload, to: recipient, spaceSeed: owed.spaceSeed)
        else { return nil }
        return (owed.spaceSeed, sealed)
    }

    // MARK: - After the answer

    /// The first request of the launch was answered. The seed it carried is
    /// the service's now, so its file goes; the launch is counted against every
    /// record, which is what ends them; and the return it carried has been
    /// sent once more.
    ///
    /// The launch is counted whether or not Zone C is on. A record counts the
    /// phone's own launch requests, and one that went with padding is one.
    private func conclude(_ first: FirstRequest) {
        if let seed = first.seed { try? transit.finish(seed) }
        try? store.update { state in
            state.countLaunch()
            if let spaceSeed = first.returnSpaceSeed {
                state.countReturnSent(forSpaceSeed: spaceSeed)
            }
        }
    }
}

/// Whether the first request was answered. Written from wherever `pending`
/// runs, read once it has finished.
private final class Answered: @unchecked Sendable {
    private let lock = NSLock()
    private var marked = false

    func mark() { lock.withLock { marked = true } }
    var isMarked: Bool { lock.withLock { marked } }
}
