import Foundation

/// Constants and wire types for a face-to-face exchange.
///
/// The whole protocol is four small messages. A seed, a chosen display name and
/// a nonce cross the air, and nothing else unless both people ask for it: there
/// is no account, no server and nothing that identifies the device.
///
/// **Consent travels a round ahead of what it permits.** `hello` carries only a
/// flag saying whether this person is willing to record where the meeting
/// happened. Coordinates ride on `confirm`, which is sent after both hellos have
/// arrived, so neither phone can disclose a location before it knows the other
/// side agreed. Putting the coordinate next to the flag would mean whoever spoke
/// first had already given it away.
///
/// Both or neither, with no middle setting, and that is a privacy rule rather
/// than a simplification: two people at one meeting are standing in the same
/// place, so one person's coordinate is also the other's. Recording mine while
/// you decline would publish exactly what you refused. See docs/PLACE.md.
public enum ExchangeProtocol {
    /// Bumped whenever the wire format changes. Peers on different versions
    /// abort cleanly rather than growing two different plants.
    ///
    /// 2 added the place flag to `PollenCard` and the coordinate to `confirm`.
    public static let version = 2

    /// Bonjour service type. Must also appear in the app's `NSBonjourServices`.
    /// Max 15 characters, lowercase, per Apple's rules for the field.
    public static let serviceType = "pg-pollen"

    public static let nonceByteCount = 16

    /// How long a touch stays "current" while waiting for the other phone to
    /// report theirs. Long enough for two people to be slightly out of step,
    /// short enough that a bump from a minute ago cannot pair with a stranger.
    public static let touchWindow: TimeInterval = 3.0
}

/// What one person hands over: their seed, and enough context to show their
/// plant on the other phone while the exchange is happening.
public struct PollenCard: Codable, Equatable, Sendable {
    public var seed: SeedID
    public var displayName: String
    public var plantName: String
    public var birth: Date
    /// Whether this person is willing for the meeting to carry a coordinate.
    ///
    /// A statement of willingness and nothing more. The coordinate itself comes
    /// later, and only if this was true on both cards. Optional so that a card
    /// written by an older version decodes as a refusal, which is the safe way
    /// for the field to be missing.
    public var sharesPlace: Bool?

    public init(
        seed: SeedID,
        displayName: String,
        plantName: String,
        birth: Date,
        sharesPlace: Bool = false
    ) {
        self.seed = seed
        self.displayName = displayName
        self.plantName = plantName
        self.birth = birth
        self.sharesPlace = sharesPlace
    }

    /// Whether these two cards permit a coordinate to be exchanged at all.
    ///
    /// The only place this question is answered. Anything sending a coordinate
    /// asks here first, so that the rule lives in one spot rather than being
    /// restated at each call site and eventually restated wrongly.
    public static func permitPlace(_ one: PollenCard, _ other: PollenCard) -> Bool {
        one.sharesPlace == true && other.sharesPlace == true
    }
}

public struct ExchangeEnvelope: Codable, Sendable {
    public enum Kind: String, Codable, Sendable {
        /// "My phone was just tapped against something."
        case touch
        case hello
        case confirm
        case abort
        /// Anything a newer version sends that this one has never heard of.
        case unknown

        public init(from decoder: Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = Kind(rawValue: raw) ?? .unknown
        }
    }

    public var protocolVersion: Int
    public var kind: Kind
    public var card: PollenCard?
    public var nonce: Data?
    public var checksum: Data?
    /// Only ever set on `confirm`, and only when both cards said yes.
    public var coordinate: Coordinate?
    public var reason: String?

    public init(
        protocolVersion: Int = ExchangeProtocol.version,
        kind: Kind,
        card: PollenCard? = nil,
        nonce: Data? = nil,
        checksum: Data? = nil,
        coordinate: Coordinate? = nil,
        reason: String? = nil
    ) {
        self.protocolVersion = protocolVersion
        self.kind = kind
        self.card = card
        self.nonce = nonce
        self.checksum = checksum
        self.coordinate = coordinate
        self.reason = reason
    }

    public static func touch() -> ExchangeEnvelope {
        ExchangeEnvelope(kind: .touch)
    }

    public static func hello(card: PollenCard, nonce: Data) -> ExchangeEnvelope {
        ExchangeEnvelope(kind: .hello, card: card, nonce: nonce)
    }

    public static func confirm(checksum: Data) -> ExchangeEnvelope {
        ExchangeEnvelope(kind: .confirm, checksum: checksum)
    }

    /// A confirm that may carry where the meeting happened.
    ///
    /// Both cards are required rather than a `Bool`, so that the rule is applied
    /// here instead of being remembered at each call site. A coordinate passed
    /// in without the other person's agreement is dropped, quietly and always:
    /// the failure mode of this method is to send less than asked, never more.
    public static func confirm(
        checksum: Data,
        coordinate: Coordinate?,
        mine: PollenCard,
        theirs: PollenCard
    ) -> ExchangeEnvelope {
        ExchangeEnvelope(
            kind: .confirm,
            checksum: checksum,
            coordinate: PollenCard.permitPlace(mine, theirs) ? coordinate : nil
        )
    }

    public static func abort(reason: String) -> ExchangeEnvelope {
        ExchangeEnvelope(kind: .abort, reason: reason)
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    public func encoded() throws -> Data {
        try Self.encoder.encode(self)
    }

    public static func decode(_ data: Data) throws -> ExchangeEnvelope {
        try decoder.decode(ExchangeEnvelope.self, from: data)
    }
}

/// The result both phones must agree on before either saves anything.
public struct CrossPollinationResult: Equatable, Sendable {
    public var childSeed: SeedID
    public var encounterID: Data
    public var checksum: Data
    public var genome: Genome
    /// The two parents in canonical order, the same way round on both phones.
    public var parentA: SeedID
    public var parentB: SeedID

    public var lineage: Lineage {
        .crossed(parentA: parentA, parentB: parentB, encounterID: encounterID)
    }

    /// These two people, rather than this meeting. Constant across every
    /// crossing the same pair ever make. See `Pollination.pairID`.
    public var pairID: Data {
        Pollination.pairID(seedA: parentA, seedB: parentB)
    }

    public init(localSeed: SeedID, remoteSeed: SeedID, localNonce: Data, remoteNonce: Data) {
        let encounterID = Pollination.encounterID(
            seedA: localSeed,
            seedB: remoteSeed,
            nonceA: localNonce,
            nonceB: remoteNonce
        )
        let child = Pollination.cross(seedA: localSeed, seedB: remoteSeed, encounterID: encounterID)
        let sorted = Pollination.ordered(localSeed, remoteSeed)
        self.childSeed = child
        self.encounterID = encounterID
        self.checksum = Pollination.checksum(of: child)
        self.parentA = sorted.0
        self.parentB = sorted.1
        self.genome = Genome.hybrid(
            child: child,
            parentA: localSeed,
            parentB: remoteSeed,
            encounterID: encounterID
        )
    }
}
