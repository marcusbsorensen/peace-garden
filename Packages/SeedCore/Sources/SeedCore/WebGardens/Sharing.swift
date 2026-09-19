#if os(WASI)
import FoundationEssentials
import WASILibc
#else
import Foundation
#endif

/// What a phone keeps so that a plant made at a meeting can later be shown in
/// the shared garden on the web — and what it posts when it is.
///
/// **Sharing a hybrid publishes both parents' seeds.** A hybrid is grown from
/// its child seed, both parents and the meeting's ID, and a browser cannot draw
/// it from less (`docs/WEBSITE.md`, amended 18 September). So it is not one
/// gardener's plant to publish: it takes both of them, and the whole of this
/// file exists to let the second one be asked.
///
/// The asking cannot use an account, because there is none, and cannot use the
/// seed, because a seed is handed to strangers on purpose. It uses the tokens
/// the meeting left behind.

// MARK: - The tokens a meeting leaves behind

/// The two sets of sixteen bytes one crossing leaves on the two phones.
///
/// Each phone mints its own in its `PollenCard` and receives the other's, so a
/// meeting leaves a pair rather than a single secret. That is worth the extra
/// field: **an invitation is addressed to the token its recipient minted**, so
/// asking *is there anything for me* returns only what somebody sent *to* this
/// phone, and direction never has to be spelled out in a flag that could be set
/// the wrong way round.
///
/// They identify a meeting and not a person. Fresh bytes each time mean two
/// people who meet twice are not linkable by anybody holding both pairs, which
/// is the property a per-person identifier would lose. See
/// `PollenCard.contactToken`.
public struct MeetingTokens: Codable, Equatable, Sendable {
    /// Minted here and handed over. What this phone is addressed at.
    public var ours: Data
    /// Minted on the other phone and received here. Where this phone addresses
    /// the other gardener, and the only thing it ever learns about them.
    public var theirs: Data

    public init(ours: Data, theirs: Data) {
        self.ours = ours
        self.theirs = theirs
    }

    public var oursHex: String { ours.hexString }
    public var theirsHex: String { theirs.hexString }
}

// MARK: - Where a plant stands

/// Whether a plant also stands in the shared garden on the web, and how far the
/// asking has got.
///
/// **Absent means here and nowhere else**, which is what every plant already
/// grown decodes as, so no garden is migrated to gain this.
///
/// A struct with a named state rather than an enum with associated values,
/// because this is a file format: the shape on disk stays one object with two
/// keys whatever states are added later, and a state this version has never
/// heard of decodes as `.unknown` instead of throwing the whole garden away.
/// `ExchangeEnvelope.Kind` is the precedent.
public struct Standing: Codable, Equatable, Sendable {

    public enum State: String, Codable, Sendable {
        /// In this garden only.
        case here
        /// This gardener has asked for it to be shown and the other has not answered.
        case asked
        /// The other gardener asked. This phone has not answered.
        case invited
        /// Both said yes. It stands in the peace garden.
        case shown
        /// One of them said no. Final for this plant — there is one invitation
        /// per plant, and declining it is the block (`docs/WEBSITE.md`).
        case declined
        /// Written by a newer version of the app than this one.
        case unknown

        public init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = State(rawValue: raw) ?? .unknown
        }
    }

    public var state: State
    /// When it last changed. Shown to nobody as a fact about the other gardener;
    /// it is here so a plant asked about weeks ago can be told from one asked
    /// about this morning.
    public var changedAt: Date

    public init(state: State, changedAt: Date) {
        self.state = state
        self.changedAt = changedAt
    }

    public static let here = Standing(state: .here, changedAt: .distantPast)

    /// Whether the plant is on the web right now.
    public var isShown: Bool { state == .shown }

    /// Whether this phone is waiting on the other gardener.
    public var isWaiting: Bool { state == .asked }

    /// Whether this plant can still be asked about.
    ///
    /// Declining is final, and a plant already shown or already asked about is
    /// not asked about twice — one invitation per plant is the rule the decline
    /// relies on to be a block.
    public var canAsk: Bool {
        switch state {
        case .here: return true
        case .asked, .invited, .shown, .declined, .unknown: return false
        }
    }
}

// MARK: - What is posted

/// One plant offered to the Long Walk, in exactly the shape
/// `POST /api/walk/plant` reads it.
///
/// Every field is either already in the record or derived from it — nothing
/// here is stored on the phone as an appearance, which is the rule
/// `docs/ARCHITECTURE.md` sets. `height` and `family` are the two the placement
/// rule needs and the only two a service cannot work out for itself: they come
/// from the grown mesh, and only a phone grows one.
public struct WalkArrival: Codable, Equatable, Sendable {
    public var seed: String
    /// Both parents, in the canonical order the lineage holds them.
    public var parents: [String]
    public var encounter: String
    /// Metres, grown.
    public var height: Double
    /// One of the seven colour families. `LongWalk.family`.
    public var family: Int

    public init(seed: String, parents: [String], encounter: String, height: Double, family: Int) {
        self.seed = seed
        self.parents = parents
        self.encounter = encounter
        self.height = height
        self.family = family
    }

    /// What this plant would arrive as, or nil if it is not a hybrid.
    ///
    /// **A minted plant has no second gardener**, so there is nobody to ask and
    /// nothing here can express its arrival. Whether a gardener may show a plant
    /// of their own is a separate question with a separate answer; it is not
    /// this one refused quietly.
    public init?(record: PlantRecord) {
        guard case let .crossed(parentA, parentB, encounterID) = record.lineage else { return nil }
        let traits = LongWalk.traits(of: record.genome)
        self.init(
            seed: record.seed.hex,
            parents: [parentA.hex, parentB.hex],
            encounter: encounterID.hexString,
            height: traits.height,
            family: traits.family
        )
    }

    /// The traits the placement rule reads, without going back to the mesh.
    public var traits: LongWalk.Traits {
        LongWalk.Traits(height: height, family: family)
    }
}
