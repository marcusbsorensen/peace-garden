#if os(WASI)
import FoundationEssentials
import WASILibc
#else
import Foundation
#endif

/// What the plot service says about one offer.
///
/// It carries the two tokens back so a phone can tell which of its plants an
/// offer is about. That is the whole of the correspondence: the phone asked
/// with a bag of tokens and is answered in the same terms, and the service is
/// never told which plants the phone holds, nor learns that two offers concern
/// the same pair of gardeners.
///
/// `state` is the service's word, kept as a string rather than an enum. The two
/// sides deploy separately, and a service that learns a new word should not stop
/// an older phone reading the rest of the row.
public struct SharedOffer: Codable, Equatable, Sendable {
    public var seed: String
    /// The token it was addressed to: the one its recipient minted.
    public var to: String
    /// The token of whoever offered it.
    public var from: String
    public var state: String
    /// Seconds since 1970, as the service counts them.
    public var offeredAt: Int?
    public var answeredAt: Int?

    public init(seed: String, to: String, from: String, state: String,
                offeredAt: Int? = nil, answeredAt: Int? = nil) {
        self.seed = seed
        self.to = to
        self.from = from
        self.state = state
        self.offeredAt = offeredAt
        self.answeredAt = answeredAt
    }

    /// The service's words for the state of an offer.
    public enum Word {
        public static let offered = "offered"
        public static let accepted = "accepted"
        public static let declined = "declined"
        public static let withdrawn = "withdrawn"
    }

    /// Where the plant stands, **read from the phone that minted `ours`**.
    ///
    /// The same row means two different things on the two phones, and this is
    /// the only place that difference is worked out. An offer still waiting is
    /// an invitation to the gardener it was addressed to and a plant waiting on
    /// an answer to the one who made it — one row, two sentences, and getting
    /// them the wrong way round would show somebody a question they had already
    /// asked.
    ///
    /// Nil where neither token is ours: a row that is none of this phone's
    /// business, discarded rather than displayed.
    public func standing(forOurToken ours: String, unknownAt now: Date) -> Standing? {
        let when = Date(timeIntervalSince1970: TimeInterval(answeredAt ?? offeredAt ?? 0))
        let mineToAnswer = ours == to
        let mineToWaitOn = ours == from
        guard mineToAnswer || mineToWaitOn else { return nil }

        switch state {
        case Word.offered:
            return Standing(state: mineToAnswer ? .invited : .asked, changedAt: when)
        case Word.accepted:
            return Standing(state: .shown, changedAt: when)
        case Word.declined:
            return Standing(state: .declined, changedAt: when)
        case Word.withdrawn:
            return Standing(state: .withdrawn, changedAt: when)
        default:
            // A word this version has never heard. The plant is somewhere in
            // the asking and is certainly not simply here, so it is held as
            // unknown, which cannot be offered again — the safe way to be wrong.
            return Standing(state: .unknown, changedAt: now)
        }
    }
}
