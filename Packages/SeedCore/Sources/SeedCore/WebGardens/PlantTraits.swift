#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// What a placement rule needs to know about a grown plant, and nothing else:
/// how tall it came out and what colour its flower is — and, since the Seedbed,
/// the Glasshouse and the Coppice, its kind, its hue and its habit.
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
    /// The hue of the plant's flower, as a turn of the colour circle: 0 up to
    /// but not including 1, red at 0, as `Genome.Palette.petalBase` holds it.
    ///
    /// **A fourth fact, because the eighth area sorts by the one thing a colour
    /// family throws away.** The Glasshouse stands its pots along the staging
    /// as a run of colour, a place for each twelfth of the plants, and seven
    /// families are too coarse to order twelve places by. `family` is a hue cut
    /// into six arcs; this is the hue before it was cut.
    ///
    /// **Exact on every host**, unlike a height. It is drawn from the seed's
    /// bytes by `+ − × ÷` alone — no `sin`, no `pow`, no mesh — so Apple's
    /// libm and wasi-libc never get a say in it, and a band edge laid across it
    /// needs no tolerance and no margin test.
    ///
    /// **Nil where it was never sent**: a planting made before this existed,
    /// or an offer from a phone that predates it. `Glasshouse.place(for:)`
    /// reads nil as it reads a pale flower — a plant whose colour cannot place
    /// it along the spectrum takes any free place — so an older phone's plant
    /// is planted rather than refused. Nothing but the Glasshouse reads it.
    public var hue: Double?
    /// The plant's habit: the name of its archetype, as `Archetype` spells it
    /// — `fern`, `star`, `spire`.
    ///
    /// **A fifth fact, because the ninth area's own plants divide by habit,
    /// and exactly.** The Coppice's genus heads are `Dros` and `Ros`, and
    /// `PlantName.roots` gives those to many-merous ferns and many-merous stars
    /// and to nothing else, so every plant there is one or the other. The
    /// Coppice stands its ferns on stools, cut with their coupe, and its stars
    /// in the light between. Height cannot tell the two apart — they overlap
    /// from half a metre to one and a half — and colour cannot either, because
    /// a fern has almost no bloom to show one.
    ///
    /// **Exact on every host**, like the hue: an archetype is picked from the
    /// seed's bytes, with no `sin` or `pow` involved, so a phone and the
    /// service cannot disagree about it.
    ///
    /// **Empty where it was never sent**: a planting made before this existed,
    /// or an offer from a phone that predates it. `Coppice.place(for:)` asks
    /// only whether a plant is a fern, so an unknown habit is placed as a star
    /// is — in the light, never cut — and is planted rather than refused.
    ///
    /// **Four areas read it now, each asking one thing.** The Coppice asks
    /// whether a plant is a fern, the Home Ground which crop it is, and since
    /// 25 September 2026 the Cold Frame and the Seedbed whether it is a lotus,
    /// which takes two places (`ColdFrame.span(of:)`). Each reads an unknown
    /// habit as the answer that asks least of the area.
    public var habit: String

    /// **Whether this plant wants standing water**, which every area asks from
    /// 27 September 2026 because every area has somewhere wet to put it.
    ///
    /// The lotus has been a water lily since the shapes changed on 24
    /// September — pads that lie one against another, a flower smaller than
    /// the pads — and until the pools were dug there was nowhere in the garden
    /// for it but a drill of dry soil. `Archetype.wantsWater` is the list, kept
    /// there because it is a fact about a plant's shape and not about an area,
    /// and asked here because a habit crosses the wire as a string and an area
    /// should not be parsing one.
    ///
    /// An unknown habit wants no water. That is the answer that asks least, as
    /// every other reading of `habit` here does: a plant nobody can identify is
    /// planted in soil, where most plants live.
    public var wantsWater: Bool {
        Archetype(rawValue: habit)?.wantsWater ?? false
    }

    public init(height: Double, family: Int, kind: String = "", hue: Double? = nil,
                habit: String = "") {
        self.height = height
        self.family = family
        self.kind = kind
        self.hue = hue
        self.habit = habit
    }

    public init(from decoder: any Decoder) throws {
        let fields = try decoder.container(keyedBy: CodingKeys.self)
        height = try fields.decode(Double.self, forKey: .height)
        family = try fields.decode(Int.self, forKey: .family)
        kind = try fields.decodeIfPresent(String.self, forKey: .kind) ?? ""
        hue = try fields.decodeIfPresent(Double.self, forKey: .hue)
        habit = try fields.decodeIfPresent(String.self, forKey: .habit) ?? ""
    }
}
