import Foundation

/// Constants and wire types for a face-to-face exchange.
///
/// The whole protocol is four small messages. Only a seed, a chosen display
/// name and a nonce cross the air; there is no account, no server and nothing
/// that identifies the device.
public enum ExchangeProtocol {
    /// Bumped whenever the wire format changes. Peers on different versions
    /// abort cleanly rather than growing two different plants.
    public static let version = 1

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

    public init(seed: SeedID, displayName: String, plantName: String, birth: Date) {
        self.seed = seed
        self.displayName = displayName
        self.plantName = plantName
        self.birth = birth
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
    public var reason: String?

    public init(
        protocolVersion: Int = ExchangeProtocol.version,
        kind: Kind,
        card: PollenCard? = nil,
        nonce: Data? = nil,
        checksum: Data? = nil,
        reason: String? = nil
    ) {
        self.protocolVersion = protocolVersion
        self.kind = kind
        self.card = card
        self.nonce = nonce
        self.checksum = checksum
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
