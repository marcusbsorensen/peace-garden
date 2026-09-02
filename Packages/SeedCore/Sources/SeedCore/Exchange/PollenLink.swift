import Foundation

/// A seed packed into a link, so it can travel by any means at all.
///
/// The face-to-face exchange needs the app on both phones. This is the other
/// way a seed moves: one phone writes its seed into a URL and hands it over —
/// AirDrop, a message, a QR code held up to a camera — and it takes root
/// wherever it lands. See docs/SEEDS-ON-THE-WIND.md.
///
/// The payload lives in the URL's *fragment*, which browsers and servers never
/// receive. If the link is opened on a phone without the app, the page it lands
/// on learns nothing about the seed; only the device does.
public struct PollenLink: Equatable, Sendable {
    public enum Kind: String, Sendable {
        /// "Here is my seed." The first half of a meeting.
        case offer = "o"
        /// "Here is mine back." Lets the sender grow the same plant.
        case reply = "r"
    }

    public static let version = 1

    /// The path an App Clip experience is registered against. The host is
    /// configuration, not something a seed should be tied to, so it is passed
    /// in rather than baked in here.
    public static let path = "/s"

    public var kind: Kind
    public var seed: SeedID
    public var nonce: Data
    public var displayName: String
    public var plantName: String
    public var birth: Date

    /// On a reply, the nonce from the offer being answered.
    ///
    /// Echoing it back is what makes a reply self-contained: the sender needs
    /// both nonces to arrive at the same plant, and echoing means they do not
    /// have to have kept track of an offer they may have sent weeks ago, or
    /// work out which of several a reply belongs to.
    public var echo: Data?

    /// On a reply, the checksum of the plant the sender should end up with.
    /// The same guarantee the face-to-face exchange gets from its confirm step:
    /// if the two sides would grow different plants, neither grows one.
    public var check: Data?

    public init(
        kind: Kind,
        seed: SeedID,
        nonce: Data,
        displayName: String,
        plantName: String,
        birth: Date,
        echo: Data? = nil,
        check: Data? = nil
    ) {
        self.kind = kind
        self.seed = seed
        self.nonce = nonce
        self.displayName = String(displayName.prefix(48))
        self.plantName = String(plantName.prefix(48))
        self.birth = birth
        self.echo = echo
        self.check = check
    }

    /// Builds the reply to an offer, from the result the receiver just grew.
    public static func reply(
        to offer: PollenLink,
        seed: SeedID,
        nonce: Data,
        displayName: String,
        plantName: String,
        birth: Date,
        result: CrossPollinationResult
    ) -> PollenLink {
        PollenLink(
            kind: .reply,
            seed: seed,
            nonce: nonce,
            displayName: displayName,
            plantName: plantName,
            birth: birth,
            echo: offer.nonce,
            check: result.checksum
        )
    }

    // MARK: - Writing

    public func url(host: String) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = Self.path
        components.fragment = fragment
        return components.url
    }

    var fragment: String {
        let body = Self.body(of: self)
        return body + "." + Self.checksum(of: body)
    }

    /// Fields are base64'd rather than escaped, so a full stop in someone's
    /// name can never be mistaken for a separator. Unused fields are empty, so
    /// the count is fixed and a truncated link fails to parse rather than
    /// parsing as something else.
    private static func body(of link: PollenLink) -> String {
        [
            String(version),
            link.kind.rawValue,
            link.seed.bytes.base64URLEncoded,
            link.nonce.base64URLEncoded,
            String(Int(link.birth.timeIntervalSince1970)),
            Data(link.displayName.utf8).base64URLEncoded,
            Data(link.plantName.utf8).base64URLEncoded,
            link.echo?.base64URLEncoded ?? "",
            link.check?.base64URLEncoded ?? ""
        ].joined(separator: ".")
    }

    /// Six bytes is plenty to catch a link that a messaging app has wrapped,
    /// truncated or otherwise mangled — which is the only failure this needs to
    /// catch. It is not a signature and cannot prove who sent anything.
    static func checksum(of body: String) -> String {
        seedDigest("peacegarden.link.v1", Data(body.utf8)).prefix(6).base64URLEncoded
    }

    // MARK: - Reading

    public enum LinkError: Error, LocalizedError, Equatable {
        case notAPollenLink
        case unsupportedVersion(Int)
        case damaged

        public var errorDescription: String? {
            switch self {
            case .notAPollenLink:
                return "That link does not carry a seed."
            case .unsupportedVersion(let version):
                return "That seed came from a newer version of Peace Garden (format \(version))."
            case .damaged:
                return "That link arrived damaged, so the seed could not be read."
            }
        }
    }

    public static func parse(_ url: URL) throws -> PollenLink {
        guard let fragment = URLComponents(url: url, resolvingAgainstBaseURL: false)?.fragment,
              !fragment.isEmpty else {
            throw LinkError.notAPollenLink
        }
        return try parse(fragment: fragment)
    }

    public static func parse(fragment: String) throws -> PollenLink {
        let fields = fragment.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        guard fields.count == 10 else { throw LinkError.notAPollenLink }

        guard let version = Int(fields[0]) else { throw LinkError.notAPollenLink }
        guard version == Self.version else { throw LinkError.unsupportedVersion(version) }

        let body = fields[0..<9].joined(separator: ".")
        guard checksum(of: body) == fields[9] else { throw LinkError.damaged }

        guard let kind = Kind(rawValue: fields[1]),
              let seedBytes = Data(base64URLEncoded: fields[2]),
              let seed = SeedID(bytes: seedBytes),
              let nonce = Data(base64URLEncoded: fields[3]),
              nonce.count == ExchangeProtocol.nonceByteCount,
              let birthSeconds = TimeInterval(fields[4]),
              let nameData = Data(base64URLEncoded: fields[5]),
              let name = String(data: nameData, encoding: .utf8),
              let plantData = Data(base64URLEncoded: fields[6]),
              let plant = String(data: plantData, encoding: .utf8)
        else {
            throw LinkError.damaged
        }

        let echo = fields[7].isEmpty ? nil : Data(base64URLEncoded: fields[7])
        let check = fields[8].isEmpty ? nil : Data(base64URLEncoded: fields[8])
        if kind == .reply, echo == nil || check == nil {
            // A reply without both is unusable: the sender could not reach the
            // same plant, and could not tell that they had not.
            throw LinkError.damaged
        }

        return PollenLink(
            kind: kind,
            seed: seed,
            nonce: nonce,
            displayName: name,
            plantName: plant,
            birth: Date(timeIntervalSince1970: birthSeconds),
            echo: echo,
            check: check
        )
    }

    /// Grows the plant this link makes, from the point of view of whoever
    /// received it. Returns `nil` if a reply's checksum does not agree — which
    /// means the two phones would grow different plants, so neither should.
    public func cross(withLocalSeed localSeed: SeedID, localNonce: Data) -> CrossPollinationResult? {
        // A reply carries the nonce the sender used, so the sender does not
        // need to have remembered it.
        let ownNonce = kind == .reply ? (echo ?? localNonce) : localNonce
        let result = CrossPollinationResult(
            localSeed: localSeed,
            remoteSeed: seed,
            localNonce: ownNonce,
            remoteNonce: nonce
        )
        if let check, check != result.checksum { return nil }
        return result
    }

    /// The card the other side would hand over in a face-to-face exchange.
    ///
    /// Marked `.sent` rather than `.met`, and carrying no contact token. A link
    /// went through somebody's messages and may have been forwarded, so there
    /// is nobody on the other end of it to invite — the token is minted by a
    /// phone that was present, and this one was not.
    public var card: PollenCard {
        PollenCard(
            seed: seed, displayName: displayName, plantName: plantName, birth: birth,
            arrival: .sent
        )
    }
}

extension Data {
    /// Base64 without the characters that need escaping in a URL.
    var base64URLEncoded: String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    init?(base64URLEncoded string: String) {
        var padded = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while padded.count % 4 != 0 { padded += "=" }
        guard let data = Data(base64Encoded: padded) else { return nil }
        self = data
    }
}
