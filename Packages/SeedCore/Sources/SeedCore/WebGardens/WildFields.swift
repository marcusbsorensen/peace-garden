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

    public init(seed: String, parents: [String], encounter: String, token: String? = nil) {
        self.seed = seed
        self.parents = parents
        self.encounter = encounter
        self.token = token
    }

    /// What this plant would be released as, or nil if it is not a hybrid.
    ///
    /// **A minted plant is somebody's own seed**, and a person's own seed is a
    /// parent of every plant their meetings make. Standing it in a public field
    /// would publish the one seed that ties all of them together, so a minted
    /// plant has no release here at all.
    public init?(record: PlantRecord) {
        guard case let .crossed(parentA, parentB, encounterID) = record.lineage else { return nil }
        self.init(
            seed: record.seed.hex,
            parents: [parentA.hex, parentB.hex],
            encounter: encounterID.hexString,
            token: record.tokens?.oursHex
        )
    }
}
