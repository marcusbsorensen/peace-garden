#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// The Seedbed: six drills across a bed of fine tilth, each drill sown with one
/// kind, the drills curving along the contour of a bed that falls toward its
/// low side.
///
/// **The first rule in the garden that groups by sameness.** The five areas
/// before it all sort by difference — the Long Walk grades a border by height,
/// the Quiet Garden reads a group of three, the Crossing ranks a quarter, the
/// Orchard stands its tallest in the middle, the Knot Garden claims a pair by
/// colour and then grades by height. Every one of them asks *how does this
/// plant differ from that one*. A seedbed asks the opposite question, which is
/// the question a nursery row is for: *what is this the same as?*
///
/// **A kind is the epithet, not the whole name.** Across five hundred
/// crossings 490 binomials are unique and the genus is nearly as rare — the
/// commonest stands five times — so a drill claimed by either would hold one
/// plant and wait forever. The epithet repeats: 46 of them over those five
/// hundred, *rubra* thirty times. It is also the truer reading, because an
/// epithet is chosen to say the one thing that is most so about a plant
/// (`Epithet.describing`), where a genus is inherited. A drill of *contorta* is
/// a drill of plants that are actually alike.
///
/// **Some of the drills are under water.** Since 27 September 2026 a drill
/// sown with water lilies is flooded, which is what a nursery does: the
/// aquatics stand in their own rows in water beside the rows of fine tilth.
/// This is one of only two areas a lily can be in — `Areas.genusHeads` sends
/// `Lir` here and `Nyx` to the Cold Frame, and those are the lotus's two
/// roots — and **173 of every 501 arrivals here are lilies**, so the wet rows
/// are a third of the bed rather than a curiosity in the corner.
///
/// **Drills on the contour, since 2 October 2026** (Marcus, from
/// `design/garden-layouts-2026-10-02/RESEARCH.md`, the Seedbed, option A). The
/// six drills were straight and parallel, each labelled at its north end and
/// sown from there. Now they curve as concentric arcs, the way rows follow the
/// fall of a bed, from a table made offline (`PlaceTable.seedbedDrills`):
///
/// - **The water lies low.** The bed falls toward `z+`. A dry kind claims the
///   highest drill nobody has sown and a water kind the lowest, so the flooded
///   drills gather at the foot of the bed like paddies and the dry ones at its
///   head. Which drill a kind claims changes; whether it can claim one, and in
///   which plot, does not.
/// - **A drill is sown from its middle**, not from its label: the place
///   nearest its middle first, then farthest-first, so a drill of one, three
///   or five plants looks sown rather than half written. A flooded drill is
///   sown the same way in pairs, because a lily takes two places side by side.
///   Neither order changes how many plants a drill holds.
/// - **Plots alternate**, mirrored one to the next (`variants`), so the labels
///   stand at the west end of one plot and the east end of the next.
/// - **The drills curve more, closer together**, later the same day: Marcus
///   chose *curve more, narrower gaps*, so the drills are 0.60 m apart where
///   they were 0.74 (`drillGap`), and each bows a third of a metre or more
///   over its length, the dry ones included. On the tighter arcs a plant's
///   nudge is laid along and across its drill where it stands (`along`)
///   rather than along `x` and `z`.
///
/// **Nothing here reads a height.** The drill comes from the kind and the
/// element and the place in it from the order of arrival, so this is the only
/// area whose placement a grown height cannot move. `SeedbedVectorTests`
/// proves it by replaying every arrival with its height thrown away, and that
/// is why this area needs no `placementCannotTurn` check: it has no cuts to
/// stand near. The element is read from the habit, which is picked from the
/// seed's bytes with no `sin` or `pow` in it, so it is exact on every host
/// like the kind. See `.claude/HANDOVER.md` §*The libm divergence*. A place
/// comes from the table and the plot's variant only changes its sign, so a
/// spot is exact on every host too.
///
/// Append-only, like the other five. A plant never moves.
public enum Seedbed {

    /// The same square as every other area, so the map, the camera and the
    /// ground are one piece of work rather than six.
    public static let plotSide = 5.2

    /// **How this area's plots vary**, from each plot's number (`PlotVariant`,
    /// Marcus's decision of 2 October 2026). Mirrored only, so a plot is laid
    /// as drawn or mirrored across the bed, alternately: the water stays on the
    /// low side and the labels change ends.
    public static let variants = PlotVariant.Space(mirror: true)

    /// Six drills of eight, chosen by Marcus from three offers on 23 September.
    /// Forty-eight is the Long Walk's number; at this plot it left 0.74 m
    /// between drills, which is the width of the space a gardener kneels in,
    /// until the drills curved more on 2 October 2026 (`drillGap`).
    public static let drills = 6
    public static let places = 8

    /// Across the bed, between one drill and the next, and along a drill
    /// between one plant and the next (`tools/layouts/tables/seedbed_drills.py`).
    ///
    /// **0.60 between drills since 2 October 2026**, where the straight bed
    /// and the first contour had 0.74. Marcus chose *curve more, narrower
    /// gaps*: concentric drills 0.74 m apart fill the bed's depth and leave
    /// room for only a gentle bow, so the dry drills read nearly straight.
    /// At 0.60 every drill bows a third of a metre or more over its length.
    /// Along a drill is unchanged.
    public static let drillGap = 0.60
    public static let alongGap = 0.52

    /// The drills and their places, made offline.
    public static let table = PlaceTable.seedbedDrills

    /// Where each place stands in the table, before the plot is mirrored:
    /// `at[drill][index]`, `index` 0 nearest the drill's label.
    static let at: [[Spot]] = {
        var out = Array(repeating: Array(repeating: Spot(x: 0, z: 0), count: places), count: drills)
        for place in table.places(nudge: 0) {
            out[table.tag("drill", of: place)][table.tag("index", of: place)] = place.spot
        }
        return out
    }()

    /// **The order a dry drill is sown in**: each drill's places as the table
    /// lists them, the one nearest its middle first and then farthest-first.
    static let dryOrder: [[Int]] = {
        var out = Array(repeating: [Int](), count: drills)
        for place in table.places(nudge: 0) {
            out[table.tag("drill", of: place)].append(table.tag("index", of: place))
        }
        return out
    }()

    /// **The order a flooded drill is sown in**: by pairs, the table's `pair`
    /// rank, and within a pair the place nearer the label first. A lily takes
    /// a whole pair and a reed the first free place, so two reeds share a pair
    /// before a third opens another and a flooded drill of lilies still holds
    /// four.
    static let wetOrder: [[Int]] = {
        var out = Array(repeating: [(pair: Int, index: Int)](), count: drills)
        for place in table.places(nudge: 0) {
            out[table.tag("drill", of: place)].append((table.tag("pair", of: place), table.tag("index", of: place)))
        }
        return out.map { $0.sorted { ($0.pair, $0.index) < ($1.pair, $1.index) }.map(\.index) }
    }()

    /// **Which drills a plant claims first**: a dry plant the highest, a water
    /// plant the lowest. Drill 0 is the top of the bed and drill 5 its foot.
    static func claimOrder(wet: Bool) -> [Int] {
        wet ? Array((0..<drills).reversed()) : Array(0..<drills)
    }

    /// The variant a plot is laid with: plain, then mirrored, alternately.
    public static func variant(of plot: Int) -> PlotVariant {
        PlotVariant.of(plot: plot, area: .beginnings)
    }

    /// **Where a drill's label stands**, in the table: the first point of its
    /// line, a third of a metre before its first place, at the west end.
    public static func label(of drill: Int) -> Spot {
        table.curve("drill\(drill)", on: PlotVariant.plain).points[0]
    }

    /// **Which way a drill runs at a place**, away from its label, as a unit
    /// direction in the table: from the place before to the place after (a
    /// drill's end to its neighbour), or across a lotus's two places. A
    /// plant's nudge is laid along and across this, so a drill that curves
    /// stays even across its width all the way round. Only a difference, a
    /// square root and a division, so it is the same double on every host.
    static func along(drill: Int, index: Int, span: Int) -> Spot {
        let from = span == 2 ? index : max(0, index - 1)
        let to = min(places - 1, index + 1)
        let a = at[drill][from], b = at[drill][to]
        let dx = b.x - a.x, dz = b.z - a.z
        let length = (dx * dx + dz * dz).squareRoot()
        return Spot(x: dx / length, z: dz / length)
    }

    /// One place in one plot: which drill, and how far along it.
    ///
    /// `index` 0 is the place nearest the label. A drill is not sown in that
    /// order since 2 October 2026 (`dryOrder`, `wetOrder`); the index still
    /// says where along the drill a place is, which is what it is stored as.
    public struct Slot: Codable, Equatable, Hashable, Sendable {
        public var drill: Int
        public var index: Int

        public init(drill: Int, index: Int) {
            self.drill = drill
            self.index = index
        }

        /// Where the place is in the table, before its plot is mirrored.
        public var spot: Spot { Seedbed.at[drill][index] }
    }

    /// Every place in a plot, drill by drill, each drill in the order a dry
    /// drill is sown.
    public static let slots: [Slot] = (0..<drills).flatMap { drill in
        dryOrder[drill].map { Slot(drill: drill, index: $0) }
    }

    /// How many places along a drill a plant takes: **two for a lotus, one
    /// for everything else.** Marcus's choice on 25 September 2026, made for
    /// the Cold Frame and the Seedbed together.
    ///
    /// Since the plants' shapes changed on 24 September a lotus is a water
    /// lily, and grown here its pads reach a median 0.51 m from the stem (0.69
    /// m at the ninetieth percentile) — the 0.52 m between places along a
    /// drill, and more. One plant in twelve stood with its stem inside a
    /// lotus's pads. Standing centred across two places, a lotus has 0.78 m to
    /// the next stem along its drill, and in the simulation made before this
    /// was chosen no stem stood inside a lotus's pads. Five hundred arrivals
    /// take nineteen plots where they took fifteen.
    ///
    /// **This is still an area no height can move.** The habit is picked from
    /// the seed's bytes with no `sin` or `pow` in it, exact on every host like
    /// the kind, so a drill and a place still come from facts the phone and
    /// the service cannot disagree about. A plant whose habit was never sent
    /// is not a lotus, and takes one place.
    public static func span(of traits: PlantTraits) -> Int {
        traits.habit == Archetype.lotus.rawValue ? 2 : 1
    }

    /// One plant standing in the Seedbed.
    public struct Planting: Codable, Equatable, Sendable {
        public var seed: String
        public var plot: Int
        /// The first place it holds, the one nearer the label of a lotus's two.
        public var slot: Slot
        /// How many places along the drill it holds, from `slot` outward:
        /// `Seedbed.span(of:)`, decided when it was sown and kept, as its place
        /// is. **Stored rather than read again off the traits**, because a
        /// planting made before 25 September holds one place whatever it is,
        /// and reads as holding one until the replant sows it again.
        public var span: Int
        public var traits: PlantTraits
        /// A small offset from the place, from the seed, and the only area
        /// whose two directions differ: `x` is 0.06 m along the drill and `z`
        /// 0.035 m across it, laid along the drill where the plant stands
        /// (`Seedbed.along`) since the drills curved more on 2 October 2026.
        /// **A drill has to read as a line**, which is the whole of what a
        /// seedbed looks like, and a line survives being uneven along its
        /// length but not being uneven across it.
        public var nudge: Spot

        /// Where it stands: the middle of the places it holds, and its nudge
        /// laid along and across its drill there, mirrored as its plot is.
        /// **A lotus stands centred across its two**,
        /// half a place further from the label than its first. A plant holding
        /// one place stands on its place, to the last bit.
        public var spot: Spot {
            let a = Seedbed.at[slot.drill][slot.index]
            var middle = a
            if span == 2, slot.index + 1 < Seedbed.places {
                let b = Seedbed.at[slot.drill][slot.index + 1]
                middle = Spot(x: (a.x + b.x) / 2, z: (a.z + b.z) / 2)
            }
            let along = Seedbed.along(drill: slot.drill, index: slot.index, span: span)
            let x = middle.x + (nudge.x * along.x - nudge.z * along.z)
            let z = middle.z + (nudge.x * along.z + nudge.z * along.x)
            return Seedbed.variant(of: plot).apply(Spot(x: x, z: z))
        }

        /// Every place it holds, from the label outward.
        public var slots: [Slot] {
            (0..<span).map { Slot(drill: slot.drill, index: slot.index + $0) }
        }

        public init(seed: String, plot: Int, slot: Slot, span: Int = 1, traits: PlantTraits, nudge: Spot) {
            self.seed = seed
            self.plot = plot
            self.slot = slot
            self.span = span
            self.traits = traits
            self.nudge = nudge
        }

        /// **A planting stored before 25 September has no span**, and holds
        /// one place: the one it was sown in, lotus or not.
        public init(from decoder: any Decoder) throws {
            let fields = try decoder.container(keyedBy: CodingKeys.self)
            seed = try fields.decode(String.self, forKey: .seed)
            plot = try fields.decode(Int.self, forKey: .plot)
            slot = try fields.decode(Slot.self, forKey: .slot)
            span = try fields.decodeIfPresent(Int.self, forKey: .span) ?? 1
            traits = try fields.decode(PlantTraits.self, forKey: .traits)
            nudge = try fields.decode(Spot.self, forKey: .nudge)
        }
    }

    /// One drill of one plot as the rule reads it: what claimed it, whether
    /// it is under water, and which of its places are held.
    struct Drill {
        var kind: String?
        var wet: Bool?
        var held: Set<Int> = []
    }

    /// The whole area: every planting, in the order they arrived.
    public struct Ways: Codable, Equatable, Sendable {
        public private(set) var plantings: [Planting] = []

        public init() {}

        /// **The Seedbed as it opened**: the beginnings ambassador in the first
        /// drill, and nothing else.
        public static func opened() -> Ways {
            var ways = Ways()
            let one = Ambassadors.of(.beginnings)
            ways.plant(seed: one.seed, traits: LongWalk.traits(of: one.genome))
            return ways
        }

        public var plots: Int { (plantings.map(\.plot).max() ?? -1) + 1 }

        public func plot(_ index: Int) -> [Planting] {
            plantings.filter { $0.plot == index }
        }

        /// The kind sown in this drill of this plot, or nil if nobody has
        /// claimed it.
        ///
        /// **Read off the plants rather than stored**, as the Knot Garden's
        /// colour claim is: a claim that lives in a column can go stale, be
        /// restored wrong, or disagree with the plants standing in it. This one
        /// cannot, because it *is* the plants.
        public func kind(of drill: Int, in plot: Int) -> String? {
            self.plot(plot).first { $0.slot.drill == drill }?.traits.kind
        }

        /// **Whether this drill is under water.** A drill sown with water
        /// lilies is flooded, and a nursery does exactly this: the aquatics
        /// go in their own rows, standing in water, beside the rows of fine
        /// tilth. Read off the first plant in the drill, as the kind is.
        ///
        /// Nil if nobody has claimed it — an unclaimed drill is neither, and
        /// becomes whichever the plant that claims it needs.
        public func isWater(_ drill: Int, in plot: Int) -> Bool? {
            self.plot(plot).first { $0.slot.drill == drill }?.traits.wantsWater
        }

        /// How many places in a drill are held, a lotus's two counted as two.
        /// A drill is full at `Seedbed.places`.
        public func sown(_ drill: Int, in plot: Int) -> Int {
            self.plot(plot).filter { $0.slot.drill == drill }.map(\.span).reduce(0, +)
        }

        /// Every drill of every plot, read in one pass over the plantings.
        func drills(_ count: Int) -> [[Drill]] {
            var out = Array(repeating: Array(repeating: Drill(), count: Seedbed.drills), count: count)
            for p in plantings where p.plot < count {
                if out[p.plot][p.slot.drill].kind == nil {
                    out[p.plot][p.slot.drill].kind = p.traits.kind
                    out[p.plot][p.slot.drill].wet = p.traits.wantsWater
                }
                for slot in p.slots { out[p.plot][p.slot.drill].held.insert(slot.index) }
            }
            return out
        }

        /// The first place in this drill a plant of this span and element can
        /// take, in the order the drill is sown, or nil if it has none.
        ///
        /// **A lotus takes a whole pair**, the next free one in the flooded
        /// order. A drill of its kind whose free places are not two of one pair
        /// has no room for it, and it goes on as a plant finding the drill full
        /// does; the place stays for a plant of one place of that kind.
        static func free(in drill: Int, held: Set<Int>, span: Int, wet: Bool) -> Int? {
            let order = wet ? Seedbed.wetOrder[drill] : Seedbed.dryOrder[drill]
            for index in order where !held.contains(index) {
                if span == 1 { return index }
                if index % 2 == 0, index + 1 < Seedbed.places, !held.contains(index + 1) { return index }
            }
            return nil
        }

        /// Where this plant goes, without planting it.
        ///
        /// Three steps, oldest plot first: a drill already sown with this kind
        /// and not yet full; failing that an unclaimed drill; failing that a
        /// new plot. **A drill is claimed, never reserved** — a kind that has
        /// not arrived holds nothing — which is what keeps a rare kind from
        /// pinning a drill open in every plot.
        ///
        /// **A drill is claimed by kind and by element**, since 27 September
        /// 2026. A kind is an epithet and an epithet says what is most so
        /// about a plant, not what it is — *rubra* is red and a water lily can
        /// be red — so two plants of one kind may want different ground. A
        /// lily joins a flooded drill of its kind and a dry plant a dry one;
        /// neither will take the other's, and a half-flooded drill is not a
        /// thing a nursery has.
        ///
        /// **And from its own side of the bed**, since 2 October 2026: a dry
        /// plant claims the highest unclaimed drill, a water plant the lowest
        /// (`claimOrder`), and takes the first place its drill is sown in. Both
        /// steps still look at every drill of a plot before the next plot, so
        /// which plot a plant goes to, and so how many plots there are, is what
        /// it was.
        public func place(for traits: PlantTraits) -> (plot: Int, slot: Slot) {
            let count = max(plots, 1)
            let span = Seedbed.span(of: traits)
            let wet = traits.wantsWater
            let order = Seedbed.claimOrder(wet: wet)
            let state = drills(count)

            // A drill of this kind and this element with room in it, oldest
            // plot first.
            for plot in 0..<count {
                for drill in order {
                    let here = state[plot][drill]
                    guard here.kind == traits.kind, here.wet == wet else { continue }
                    if let index = Ways.free(in: drill, held: here.held, span: span, wet: wet) {
                        return (plot, Slot(drill: drill, index: index))
                    }
                }
            }

            // Otherwise the first drill nobody has sown on its own side of the
            // bed, oldest plot first.
            for plot in 0..<count {
                for drill in order where state[plot][drill].kind == nil {
                    return (plot, Slot(drill: drill, index: Ways.free(in: drill, held: [], span: span, wet: wet)!))
                }
            }

            return (count, Slot(drill: order[0], index: Ways.free(in: order[0], held: [], span: span, wet: wet)!))
        }

        /// Plant one arrival, and say where it went.
        @discardableResult
        public mutating func plant(seed: SeedID, traits: PlantTraits) -> Planting {
            let (plot, slot) = place(for: traits)
            let bytes = [UInt8](seed.bytes)
            func jitter(_ i: Int, _ reach: Double) -> Double {
                guard bytes.count > i else { return 0 }
                return (Double(bytes[i]) / 255 - 0.5) * 2 * reach
            }
            let planting = Planting(seed: seed.hex, plot: plot, slot: slot, span: Seedbed.span(of: traits),
                                    traits: traits, nudge: Spot(x: jitter(26, 0.06), z: jitter(27, 0.035)))
            plantings.append(planting)
            return planting
        }
    }

    /// The first plant in the Seedbed, and the one the area is drawn with
    /// before anybody has released anything into it.
    public static let ambassador: Planting = Ways.opened().plantings[0]
}
