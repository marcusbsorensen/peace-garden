#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// What a placement rule needs to know about a grown plant, and nothing else:
/// how tall it came out and what colour its flower is.
///
/// **Two facts, because only two can be read without looking.**
/// `docs/WEB-GARDENS.md` §*Slots and roles* says a template asks questions a
/// plant answers from its genome — height, habit, colour — and these are the
/// two every area has wanted so far. They are stored with a planting rather
/// than read again, because reading them builds the plant's mesh.
///
/// **Shared, because a plant's height is not the Long Walk's property.** Each
/// area reads its own role off these: the Long Walk asks which of three tiers
/// of a border a plant belongs in (`LongWalk.Tier`), the Quiet Garden asks
/// whether it is the back of a group of three or one of its arms
/// (`QuietGarden.Stand`). The facts are the plant's; the reading is the area's.
///
/// `LongWalk.Traits` is a typealias to this, kept because that spelling is in
/// `tools/reference/long_walk_vectors.json` and in the PHP port. The encoded
/// shape is the same two fields whichever name is used.
public struct PlantTraits: Codable, Equatable, Hashable, Sendable {
    public var height: Double
    public var family: Int
    /// The plant's epithet, lower case as it is written: `rubra`, `contorta`.
    ///
    /// **A third fact, because the sixth area asks a question the other two
    /// cannot answer.** The Seedbed sows a drill with one kind, and a kind has
    /// to be something two plants can share: across five hundred crossings the
    /// binomial is unique 490 times and the genus is nearly as rare, while the
    /// epithet repeats — 46 of them, the commonest thirty times. It is also the
    /// one part of a name that is *read off the plant* rather than inherited,
    /// which is what makes a drill of it a drill of things that are alike.
    ///
    /// Empty for a planting made before this existed. `Seedbed.place(for:)`
    /// compares it like any other string, so unnamed plants gather in a drill
    /// of their own rather than being refused — which is the right answer for a
    /// rule about sameness, and a drill nobody should ever see, because every
    /// path a plant arrives by carries its kind. Nothing but the Seedbed reads
    /// it.
    public var kind: String

    public init(height: Double, family: Int, kind: String = "") {
        self.height = height
        self.family = family
        self.kind = kind
    }

    public init(from decoder: any Decoder) throws {
        let fields = try decoder.container(keyedBy: CodingKeys.self)
        height = try fields.decode(Double.self, forKey: .height)
        family = try fields.decode(Int.self, forKey: .family)
        kind = try fields.decodeIfPresent(String.self, forKey: .kind) ?? ""
    }
}
