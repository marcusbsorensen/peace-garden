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
/// finding its own seed: a record that ends inside an answer leaves its mark in
/// the store's retired marks (`ZoneCState.hasSent`), and the plant a return grows
/// has the sender's space seed for a parent, so the finder passes that seed over
/// whichever comes first. Looking first keeps the record holding its seed back
/// to the end of the answer all the same.
///
/// ## Off the main actor
///
/// All of it runs in one task detached from the caller, at utility priority.
/// The returns are up to 1,024 key agreements, about 100 ms on a Mac and a few
/// hundred on the oldest phone Peace Garden supports (`REVIEW-A2.md`,
/// finding 1), and nobody is waiting for the answer: the launch has already
/// painted. The call is detached rather than left to the executor that happens
/// to run `ask`, so that where the work runs does not depend on the
/// concurrency settings the project is built with, and `ZoneCEngineTests`
/// holds it.
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
        await Task.detached(priority: .utility) { [finder, returns] in
            finder.find(in: aloft)
            returns.receive(back: back)
        }.value
    }
}
