import Foundation

/// A seed the person chose to send from Autonaut, taken from `Seeds/v1/out/`.
struct SentSeed: Equatable, Sendable {
    /// The file it came in, so the same file can be deleted once the server has
    /// answered.
    let name: String
    /// The sixteen random bytes, `r`.
    let r: Data

    var hex: String { SuiteHex.encode(r) }
}

/// What happened to a seed Peace Garden found for the person.
enum Delivery: Equatable, Sendable {
    case delivered
    /// Three files already wait in `in/`, so nothing was written.
    case full
}

/// Peace Garden's half of the hand-off with Autonaut: what it takes from
/// `Seeds/v1/out/`, what it puts into `Seeds/v1/in/`, and the two markers that
/// say who is installed. `SuiteGroup` does the file work; this knows the formats
/// and the limits (DESIGN §3).
///
/// Nothing here runs yet. The launch request (A3) calls `prepare()`, takes the
/// seed it finds, and deletes it once the server has answered.
///
/// **No date means anything.** Every file in the folder carries 1 January 2001,
/// so no reader can tell how old one is, and nothing here asks. A caller that
/// wants "the oldest seed" has to settle for the first by name.
struct SuiteTransit: Sendable {
    /// Seeds waiting in `in/` before Peace Garden stops adding more. Autonaut
    /// takes them each time it opens. If it has been deleted nobody does, and
    /// finding stops here rather than filling a folder no one empties. This is
    /// the stand-in for a check that Autonaut is still installed, which a
    /// presence file cannot give.
    static let inCapacity = 3

    /// A valid `out` file is 46 bytes. Anything over this is not one, and is
    /// deleted without being opened.
    static let longestSeedFile = 128

    static let myPresence = "\(SuiteGroup.presenceFolder)/peacegarden"
    static let autonautPresence = "\(SuiteGroup.presenceFolder)/autonaut"
    static let exchangeMarker = "\(SuiteGroup.seedsFolder)/exchange"

    let group: SuiteGroup

    init(group: SuiteGroup = SuiteGroup()) {
        self.group = group
    }

    /// Whether this phone has the suite's folder at all. Without it Zone C is
    /// shut, and nothing below does anything.
    var isAvailable: Bool { group.isAvailable }

    // MARK: - At launch

    /// Makes the folders, clears Peace Garden's own leftovers from `tmp/`, and
    /// writes its presence marker if it is missing.
    ///
    /// The presence marker does not follow the sharing switch: it says Peace
    /// Garden was installed, not that it is asking. A second launch finds it and
    /// writes nothing, so its dates are not touched again.
    func prepare() throws {
        try group.prepareLayout()
        try group.removeOwnStaging()
        try putMarker(Self.myPresence)
    }

    // MARK: - Presence

    /// Whether Autonaut has ever been installed here. Zone C opens when it has.
    /// Only the file's existence is looked at; it is empty.
    var autonautIsPresent: Bool { group.exists(Self.autonautPresence) }

    /// Whether the launch request is switched on, as far as Autonaut can see.
    var exchangeMarkerIsPresent: Bool { group.exists(Self.exchangeMarker) }

    /// Writes `Seeds/v1/exchange` while the launch request is on, and deletes it
    /// when it is off. Autonaut shows "Send as a seed" only while both this and
    /// Peace Garden's presence marker exist. Setting it to what it already is
    /// writes nothing.
    func setExchangeMarker(present: Bool) throws {
        if present {
            try putMarker(Self.exchangeMarker)
        } else if group.exists(Self.exchangeMarker) {
            try group.remove(Self.exchangeMarker)
        }
    }

    /// An empty file, written only when missing.
    private func putMarker(_ path: String) throws {
        guard !group.exists(path) else { return }
        do {
            try group.stage(Data(), to: path)
        } catch SuiteError.alreadyThere {
            // Written between the look and the write. It is there, which is all
            // that was wanted.
        }
    }

    // MARK: - Seeds Autonaut sent

    /// The well-formed seeds waiting in `out/`, in name order. A file that is
    /// not exactly `{"v":1,"r":"<32 lowercase hex>"}` is deleted, and one that is
    /// too long or is not a plain file is deleted without being opened.
    ///
    /// The format is read as JSON, so the keys may come in either order and
    /// whitespace is allowed. What is exact is the set of keys, the version and
    /// the thirty-two lowercase hex characters.
    ///
    /// Quiet about trouble: if the folder cannot be read, nothing is waiting.
    func seedsWaitingToLeave() -> [SentSeed] {
        guard let names = try? group.names(in: SuiteGroup.outFolder) else { return [] }
        var seeds: [SentSeed] = []
        for name in names {
            let path = "\(SuiteGroup.outFolder)/\(name)"
            guard let reading = try? group.readSmallFile(path, maxBytes: Self.longestSeedFile) else {
                continue
            }
            switch reading {
            case .missing:
                continue
            case .notAFile, .tooLong:
                try? group.remove(path)
            case .contents(let data):
                if let r = Self.parseSentSeed(data) {
                    seeds.append(SentSeed(name: name, r: r))
                } else {
                    try? group.remove(path)
                }
            }
        }
        return seeds
    }

    /// Deletes the file a seed came in. Called once the server has answered the
    /// request that carried it; until then the file stays, so a failed request
    /// loses nothing.
    func finish(_ seed: SentSeed) throws {
        try group.remove("\(SuiteGroup.outFolder)/\(seed.name)")
    }

    /// The sixteen bytes in an `out` file, or nil unless it is exactly
    /// `{"v":1,"r":"<32 lowercase hex>"}` in the sense above.
    static func parseSentSeed(_ data: Data) -> Data? {
        guard let file = try? JSONDecoder().decode(SentSeedFile.self, from: data) else { return nil }
        return file.r
    }

    // MARK: - Seeds Peace Garden found

    /// How many files wait in `in/` for Autonaut to take.
    func seedsWaitingForAutonaut() -> Int {
        (try? group.names(in: SuiteGroup.inFolder).count) ?? 0
    }

    /// Writes a found seed to `in/<random>` as `{"v":1,"seed":"<64 hex>"}`, but
    /// only while fewer than three files wait there.
    ///
    /// - Parameter seed: the 32-byte space seed, as itself. Zone C grows the
    ///   cross; Autonaut draws the found seed.
    func deliver(foundSeed seed: Data) throws -> Delivery {
        guard seed.count == 32 else { throw SuiteError.notASeed }
        guard try group.names(in: SuiteGroup.inFolder).count < Self.inCapacity else {
            return .full
        }
        // Built by hand, not encoded, so the keys and their order are the ones
        // agreed and cannot move with a library.
        let body = Data(#"{"v":1,"seed":"\#(SuiteHex.encode(seed))"}"#.utf8)
        try group.stage(body, to: "\(SuiteGroup.inFolder)/\(group.newName())")
        return .delivered
    }
}

/// The contents of an `out` file, held to the format. A `Decodable` would ignore
/// a key it did not expect, so the keys are counted by hand.
private struct SentSeedFile: Decodable {
    let r: Data

    private struct Key: CodingKey {
        let stringValue: String
        var intValue: Int? { nil }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { return nil }
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        guard Set(container.allKeys.map(\.stringValue)) == ["v", "r"] else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath, debugDescription: "the keys are not exactly v and r"
            ))
        }
        let version = try container.decode(Int.self, forKey: Key(stringValue: "v")!)
        let text = try container.decode(String.self, forKey: Key(stringValue: "r")!)
        guard version == 1, let bytes = SuiteHex.decode(text, byteCount: 16) else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath, debugDescription: "not version 1 with 32 lowercase hex"
            ))
        }
        r = bytes
    }
}

/// Lowercase hex, the only kind the suite's files use.
enum SuiteHex {
    private static let digits = Array("0123456789abcdef".utf8)

    static func encode(_ data: Data) -> String {
        var text: [UInt8] = []
        text.reserveCapacity(data.count * 2)
        for byte in data {
            text.append(digits[Int(byte >> 4)])
            text.append(digits[Int(byte & 0x0f)])
        }
        return String(decoding: text, as: UTF8.self)
    }

    /// The bytes, or nil unless `text` is exactly `byteCount * 2` characters of
    /// `0-9a-f`. Uppercase is not accepted.
    static func decode(_ text: String, byteCount: Int) -> Data? {
        let characters = Array(text.utf8)
        guard characters.count == byteCount * 2 else { return nil }
        func value(_ character: UInt8) -> UInt8? {
            switch character {
            case UInt8(ascii: "0")...UInt8(ascii: "9"): return character - UInt8(ascii: "0")
            case UInt8(ascii: "a")...UInt8(ascii: "f"): return character - UInt8(ascii: "a") + 10
            default: return nil
            }
        }
        var bytes: [UInt8] = []
        bytes.reserveCapacity(byteCount)
        var index = 0
        while index < characters.count {
            guard let high = value(characters[index]), let low = value(characters[index + 1]) else {
                return nil
            }
            bytes.append(high << 4 | low)
            index += 2
        }
        return Data(bytes)
    }
}
