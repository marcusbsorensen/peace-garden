#if os(WASI)
import FoundationEssentials
import WASILibc
#else
import Foundation
#endif

/// The Wild Fields: where a released plant stands, and what a phone sends to
/// put it there.
///
/// **The opposite of the ten areas, and the rule says so.** An area places an
/// arrival by its template against everything that arrived before it, and
/// stores the place it gave (`docs/WEB-GARDENS.md` §*What this reverses*). The
/// wild has no template and no curator, so a released plant's place is read off
/// its own seed and nothing else, the way the whole garden was placed before
/// 18 September: no order of arrival, no neighbours consulted, and nothing
/// stored that the seed does not already say. A plant released today and one
/// released next year stand where they would have stood had they come the
/// other way round.
///
/// **One field with no edge.** The ground is a square `side` metres across
/// whose far edges meet its near ones, so walking off one side is walking on
/// in from the other and there is nowhere a reader meets the end of it. That is
/// the property the design asks for — the wild does not have an edge — said as
/// geometry rather than as a field too big to reach the end of.
///
/// **Collisions are allowed and drawn.** Two seeds whose first bytes agree
/// stand together, as two plants in a field do. Nothing nudges one aside,
/// because a nudge would make a place depend on which arrived first.
///
/// Decided on 1 October 2026, when Marcus asked for the Wild Fields to be
/// built so that release sends a plant somewhere. `Server/.api/WildFields.php`
/// is the port the service places by, held to `wild_fields_vectors.json`.
public enum WildFields {

    /// How far the field runs before it comes round again, in metres.
    ///
    /// **Sixty-four, about four thousand square metres**, chosen against the
    /// number of plants likely to be in it rather than against a screen. A
    /// page's view is about a dozen metres across, so the field is some thirty
    /// views: a few hundred released plants already read as a field rather
    /// than a search, and a thousand stand one to every four square metres,
    /// which is a meadow rather than a bed.
    ///
    /// **It can never change.** Every place in the field is a fraction of this
    /// number, so a field made larger is every plant in it moved.
    public static let side = 64.0

    /// The square the service is asked for at a time, in metres. A page walks
    /// the field by fetching the tiles it can see, which is what lets a field
    /// with no edge be read in pieces.
    public static let tile = 8.0

    /// Tiles along each side of the field.
    public static var tiles: Int { Int(side / tile) }

    /// How finely a place is read off a seed: two bytes on each axis, so a
    /// step of `side / 65536`, about a millimetre.
    static let steps = 65536.0

    /// Where a released plant stands, in metres from the field's corner along
    /// each axis, both in `0 ..< side`.
    ///
    /// **Two slices of the seed**, the first two bytes across and the next two
    /// along, each in the middle of its step. The seed is already a SHA-256
    /// digest, so there is nothing to gain by hashing it again, and nothing
    /// that then has to agree between the app, the site and the service. Every
    /// value is a whole number of 1/1024ths of a metre, so it is exactly the
    /// same double on every host that reads it.
    public static func spot(of seed: SeedID) -> (x: Double, z: Double) {
        let b = [UInt8](seed.bytes.prefix(4))
        let across = Double(UInt16(b[0]) << 8 | UInt16(b[1]))
        let along = Double(UInt16(b[2]) << 8 | UInt16(b[3]))
        return ((across + 0.5) / steps * side, (along + 0.5) / steps * side)
    }

    /// Which tile a released plant stands in.
    public static func tile(of seed: SeedID) -> (x: Int, z: Int) {
        let (x, z) = spot(of: seed)
        return (Int(x / tile), Int(z / tile))
    }
}

/// One plant released to the Wild Fields, in exactly the shape
/// `POST /api/wild/release` reads it.
///
/// **What a field needs to grow it, and what proves the plant is real.** A
/// hybrid is grown from its child seed and both parents' seeds, so those three
/// go and are kept (`docs/WEBSITE.md`, amended 18 September). The meeting's ID
/// goes too, so the service can check the child really is the cross of those
/// parents at that meeting, and is then dropped: it is not kept, because the
/// field does not need it to draw anything.
///
/// **No height, colour or name.** An area's rule places a plant by what the
/// grown plant is; the field places it by its seed, so nothing grown is sent.
///
/// **And the token, whenever the meeting left one.** A plant that stood in one
/// of the ten areas had its seed, its parents and its meeting published while
/// it stood, so those three no longer prove that whoever sends them grew it.
/// The token the meeting left on this phone does, and the service asks for it
/// when it finds an offer for the plant — and takes the plant out of the area
/// it is standing in, because a plant stands in one public place. It is sent
/// even when this phone believes the plant was never offered, because the
/// other gardener may have offered it while this phone was not asking
/// (*Alert me* off); the service compares it and keeps nothing of it.
public struct WildRelease: Codable, Equatable, Sendable {
    public var seed: String
    /// Both parents, in the canonical order the lineage holds them.
    public var parents: [String]
    public var encounter: String
    /// This phone's own token from the meeting, or nil for a plant grown
    /// before tokens were kept, or from a link. `MeetingTokens.oursHex`.
    public var token: String?
    /// The token the other phone minted, sent with `token`, so the other
    /// gardener can be told and can answer for themselves about what stands
    /// beside the plant. The service keeps a fingerprint of it, never the
    /// token. Since 1 October 2026.
    public var theirs: String?
    /// What the releaser chose to show beside it. Nil, or every field nil, is
    /// nothing at all, which is the default.
    public var shown: WildShowing?

    public init(seed: String, parents: [String], encounter: String, token: String? = nil,
                theirs: String? = nil, shown: WildShowing? = nil) {
        self.seed = seed
        self.parents = parents
        self.encounter = encounter
        self.token = token
        self.theirs = theirs
        self.shown = shown
    }

    /// What this plant would be released as, or nil if it is not a hybrid.
    ///
    /// **A minted plant is somebody's own seed**, and a person's own seed is a
    /// parent of every plant their meetings make. Standing it in a public field
    /// would publish the one seed that ties all of them together, so a minted
    /// plant has no release here at all.
    ///
    /// `shown` goes only with a meeting's tokens: without them there is no
    /// other gardener to tell, and no way for this phone to change its mind
    /// later, so a plant from before tokens, or from a link, is released with
    /// nothing beside it whatever was chosen.
    public init?(record: PlantRecord, shown: WildShowing? = nil) {
        guard case let .crossed(parentA, parentB, encounterID) = record.lineage else { return nil }
        self.init(
            seed: record.seed.hex,
            parents: [parentA.hex, parentB.hex],
            encounter: encounterID.hexString,
            token: record.tokens?.oursHex,
            theirs: record.tokens?.theirsHex,
            shown: record.tokens == nil || shown?.isNothing != false ? nil : shown
        )
    }
}

// MARK: - Who stands beside a released plant

/// What one gardener chooses to show beside a plant in the Wild Fields, in
/// exactly the shape `shown` takes on `POST /api/wild/release` and
/// `POST /api/wild/answer`. Since 1 October 2026 (Marcus's decision that day;
/// `docs/WEB-GARDENS.md` §*The Wild Fields*, *Who stands beside it*).
///
/// **Three things and no free text.** The gardener name this person chose
/// for meetings, the meeting's place as this phone kept it, and the month the
/// meeting happened, `YYYY-MM`. Each is the value to show, or nil for not.
///
/// **A name is its owner's alone to show; the place and the month are the
/// meeting's.** The service shows those two only once both gardeners have
/// chosen them and both phones sent the same words, so each phone sends its
/// own account and neither publishes the other's.
public struct WildShowing: Codable, Equatable, Sendable {
    public var name: String?
    public var place: String?
    public var month: String?

    public init(name: String? = nil, place: String? = nil, month: String? = nil) {
        self.name = name
        self.place = place
        self.month = month
    }

    /// Anonymous: nothing of this gardener beside the plant.
    public static let nothing = WildShowing()

    public var isNothing: Bool { name == nil && place == nil && month == nil }

    /// Which of the three this says yes to.
    public var choice: WildChoice {
        WildChoice(name: name != nil, place: place != nil, month: month != nil)
    }

    /// The most the service takes of each, in characters: the name as the app
    /// holds it (`PollenLink`), and a place.
    public static let nameLength = 48
    public static let placeLength = 64

    /// The month a meeting happened, as the field shows it: `YYYY-MM`, read in
    /// the calendar the meeting was kept in — the two phones were in one place,
    /// so in one time zone, and they agree.
    public static func month(year: Int, month: Int) -> String {
        let y = String(year), m = String(month)
        return String(repeating: "0", count: max(0, 4 - y.count)) + y + "-"
            + (m.count < 2 ? "0" + m : m)
    }

    /// The three, each kept only where the matching yes is, and held to what
    /// the service takes: trimmed, a name or place cut to its length, and an
    /// empty one dropped rather than sent.
    public static func choosing(_ choice: WildChoice, name: String?, place: String?, month: String?) -> WildShowing {
        // The standard library only, so it is the same on the phone and in
        // WebAssembly: controls and formatting characters out (the service
        // refuses them), whitespace off both ends, cut to length.
        func tidy(_ value: String?, _ most: Int) -> String? {
            guard let value else { return nil }
            var scalars = String.UnicodeScalarView()
            for scalar in value.unicodeScalars {
                switch scalar.properties.generalCategory {
                case .control, .format, .lineSeparator, .paragraphSeparator: continue
                default: scalars.append(scalar)
                }
            }
            var kept = Substring(String(scalars))
            while let first = kept.first, first.isWhitespace { kept.removeFirst() }
            // Cut by whole characters, counted as the service counts them —
            // in code points — so no character is cut in half and nothing
            // sent is longer than the service takes.
            var cut = ""
            var count = 0
            for character in kept {
                count += character.unicodeScalars.count
                if count > most { break }
                cut.append(character)
            }
            while let last = cut.last, last.isWhitespace { cut.removeLast() }
            return cut.isEmpty ? nil : cut
        }
        return WildShowing(
            name: choice.name ? tidy(name, nameLength) : nil,
            place: choice.place ? tidy(place, placeLength) : nil,
            month: choice.month ? month : nil
        )
    }
}

/// Yes or no to each of the three, which is all the service says back about
/// anybody's choice: the words are on the phones and, once shown, in the field.
public struct WildChoice: Codable, Equatable, Sendable {
    public var name: Bool
    public var place: Bool
    public var month: Bool

    public init(name: Bool = false, place: Bool = false, month: Bool = false) {
        self.name = name
        self.place = place
        self.month = month
    }

    /// Anonymous, which is where every choice starts.
    public static let none = WildChoice()

    public var isNone: Bool { !name && !place && !month }
}

/// What the field shows beside a plant: the names chosen, in alphabetical
/// order so nothing says which of the two let it go, and the place and the
/// month once both chose the same.
public struct WildShown: Codable, Equatable, Sendable {
    public var names: [String]
    public var place: String?
    public var month: String?

    public init(names: [String] = [], place: String? = nil, month: String? = nil) {
        self.names = names
        self.place = place
        self.month = month
    }
}

/// What the plot service tells one phone about a released plant one of its
/// meetings grew: on `pending`, on the release, and on an answer.
///
/// **Keyed by the token the phone asked with**, as an offer is, so the phone
/// finds its plant by the token it minted and the service is never told which
/// plants it holds. `released` says whether this token's phone let it go —
/// the other one is the one being told.
public struct WildNotice: Codable, Equatable, Sendable {
    public var seed: String
    public var token: String
    public var released: Bool
    /// What this phone chose.
    public var yours: WildChoice
    /// What the other gardener chose: yes or no, never the words.
    public var theirs: WildChoice
    public var shown: WildShown

    public init(seed: String, token: String, released: Bool, yours: WildChoice = .none,
                theirs: WildChoice = .none, shown: WildShown = WildShown()) {
        self.seed = seed
        self.token = token
        self.released = released
        self.yours = yours
        self.theirs = theirs
        self.shown = shown
    }
}

/// A plant of this garden that the other gardener released into the Wild
/// Fields, as this phone keeps it: what the service last said, and whether
/// this person has been told yet. On `PlantRecord.wild`; absent on every plant
/// nobody has released.
public struct InTheWild: Codable, Equatable, Sendable {
    public var notice: WildNotice
    /// Whether the notice has been put in front of this person. It is put
    /// there once; after that the plant's own screen is where it is changed.
    public var heard: Bool

    public init(notice: WildNotice, heard: Bool = false) {
        self.notice = notice
        self.heard = heard
    }
}

/// A plant this phone released into the Wild Fields, kept so that what it
/// chose to show beside the plant can be changed or withdrawn later.
///
/// **Only what that needs**: the plant (its seed and lineage, so it can be
/// drawn and named on the screen that changes it), the meeting's tokens, the
/// other gardener's name as this phone knows it, and this phone's own account
/// of where and when — the words it would send. Not the note, the coordinate
/// or anything else the meeting kept: those left with the plant. On
/// `Garden.released`; only a plant released with a meeting's tokens is kept.
public struct ReleasedPlant: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var seed: SeedID
    public var lineage: Lineage
    public var birth: Date
    public var tokens: MeetingTokens
    public var peerDisplayName: String
    public var place: String?
    public var happenedAt: Date
    public var notice: WildNotice?

    public init(id: UUID = UUID(), seed: SeedID, lineage: Lineage, birth: Date, tokens: MeetingTokens,
                peerDisplayName: String, place: String?, happenedAt: Date, notice: WildNotice? = nil) {
        self.id = id
        self.seed = seed
        self.lineage = lineage
        self.birth = birth
        self.tokens = tokens
        self.peerDisplayName = peerDisplayName
        self.place = place
        self.happenedAt = happenedAt
        self.notice = notice
    }

    /// What is kept of a plant as it is released, or nil for one with no
    /// meeting's tokens or no meeting written down.
    public init?(record: PlantRecord, notice: WildNotice?) {
        guard let tokens = record.tokens, let encounter = record.encounter, record.isHybrid else { return nil }
        self.init(seed: record.seed, lineage: record.lineage, birth: record.birth, tokens: tokens,
                  peerDisplayName: encounter.peerDisplayName, place: encounter.place,
                  happenedAt: encounter.happenedAt, notice: notice)
    }

    public var genome: Genome { Genome(seed: seed, lineage: lineage) }
}
