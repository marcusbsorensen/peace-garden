import Foundation
import SeedCore

/// What Zone C does with the two bundles of an answer: find, cross and queue a
/// return (`ZoneCFinder`), and open the returns that are for this phone's own
/// seeds (`ZoneCReturns`). It is the sink `ZoneCExchange` hands the rows to
/// (`ZoneCBundles`), which does so only after a request was answered and only
/// while Zone C's switch is on (`DESIGN.md` §7, item 16).
///
/// ## The order
///
/// A find first, then the returns. The order is not what keeps a sender from
/// finding its own seed today: a record ends inside an answer only by its third
/// plant, and the plant a return grows has the sender's space seed for a parent,
/// so the finder passes that seed over (`hasPlant(parentedBy:)`) whichever
/// comes first. Looking first keeps the record holding its seed back to the end
/// of the answer, whatever else may end a record later.
///
/// ## What it writes
///
/// To Zone C's own store, always. To the App Group, once per find, to `in/`
/// (`ZoneCFinder`); a return writes nothing there.
struct ZoneCEngine: ZoneCBundles {
    let finder: ZoneCFinder
    let returns: ZoneCReturns

    /// - Parameters:
    ///   - store: Zone C's store, the one `ZoneCExchange` writes its records to.
    ///   - transit: the suite's folder, the one `ZoneCExchange` takes seeds from.
    ///   - now, nonce, opening: leave these alone outside tests.
    init(
        store: ZoneCStore,
        transit: SuiteTransit = SuiteTransit(),
        now: @escaping @Sendable () -> Date = { Date() },
        nonce: @escaping @Sendable () -> Data = { Pollination.makeNonce() },
        opening: @escaping ZoneCReturns.Opening = ZoneCReturns.realOpening
    ) {
        finder = ZoneCFinder(store: store, transit: transit, now: now, nonce: nonce)
        returns = ZoneCReturns(store: store, opening: opening)
    }

    func receive(aloft: [Data], back: [Data]) async {
        finder.find(in: aloft)
        returns.receive(back: back)
    }
}
