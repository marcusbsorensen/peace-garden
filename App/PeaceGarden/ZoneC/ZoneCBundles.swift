import Foundation

/// Where the two bundles of an answer go: the seeds a phone may find in `aloft`,
/// and the returns it may open in `back`.
///
/// `ZoneCExchange` reads the answer and hands the rows here. What is done with
/// them is `ZoneCEngine`'s: check each seed's mark, skip a seed this phone
/// sent, cross and plant one find a day, try every live record's key on every
/// return. `ZoneCNoBundles` takes them and does nothing, for a test that wants
/// the request and not the engine.
///
/// **The rows are unread.** Most are padding and a few are real, and nothing in
/// the answer says which: the service cannot tell, and neither can this
/// protocol. A row is whatever 64 or 104 bytes the pool held.
///
/// **Called only while Zone C is switched on** (`DESIGN.md` §7, item 16): off
/// means this phone looks for no space seed and queues no return, and the way
/// that holds without every implementation having to remember it is that off
/// never reaches this far. It is also called only after a request was answered,
/// never for a failed one, and at most once for a launch: a garden of more than
/// 128 meetings sends two requests and the rows of both arrive together.
///
/// It runs before the launch is counted against the records and the owed
/// returns, so a record on its last launch can still open a return that came
/// down with its own answer.
protocol ZoneCBundles: Sendable {
    /// - Parameters:
    ///   - aloft: rows of 64 bytes each, in the order the service sent them.
    ///   - back: rows of 104 bytes each.
    func receive(aloft: [Data], back: [Data]) async
}

/// A sink that takes the rows and does nothing with them.
struct ZoneCNoBundles: ZoneCBundles {
    func receive(aloft: [Data], back: [Data]) async {}
}
