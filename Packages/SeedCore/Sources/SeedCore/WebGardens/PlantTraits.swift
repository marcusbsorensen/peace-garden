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

    public init(height: Double, family: Int) {
        self.height = height
        self.family = family
    }
}
