#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// The Seedbed: six drills across a bed of fine tilth, each drill sown with one
/// kind, filling from the labelled end.
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
/// **Nothing here reads a height.** The drill comes from the kind and the place
/// in it from the order of arrival, so this is the only area whose placement a
/// grown height cannot move. `SeedbedVectorTests` proves it by replaying every
/// arrival with its height thrown away, and that is why this area needs no
/// `placementCannotTurn` check: it has no cuts to stand near. See
/// `.claude/HANDOVER.md` §*The libm divergence*.
///
/// Append-only, like the other five. A plant never moves, and a drill's order
/// is the order it was sown in.
public enum Seedbed {

    /// The same square as every other area, so the map, the camera and the
    /// ground are one piece of work rather than six.
    public static let plotSide = 5.2

    /// Six drills of eight, chosen by Marcus from three offers on 23 September.
    /// Forty-eight is the Long Walk's number; at this plot it leaves 0.74 m
    /// between drills, which is the width of the space a gardener kneels in.
    public static let drills = 6
    public static let places = 8

    /// Across the bed, between one drill and the next.
    public static let drillGap = 0.74
    /// Along a drill, between one plant and the next.
    public static let alongGap = 0.52

    /// Where a drill's label stands, in `z`: a little beyond the first plant,
    /// at the end the drill fills from.
    public static let labelAt = -2.15

    /// One place in one plot: which drill, and how far along it.
    ///
    /// `index` 0 is the place nearest the label, and a drill fills from there
    /// outward, so reading a drill from its label is reading it in the order it
    /// was sown.
    public struct Slot: Codable, Equatable, Hashable, Sendable {
        public var drill: Int
        public var index: Int

        public init(drill: Int, index: Int) {
            self.drill = drill
            self.index = index
        }

        public var spot: Spot {
            Spot(x: (Double(drill) - Double(Seedbed.drills - 1) / 2) * Seedbed.drillGap,
                 z: (Double(index) - Double(Seedbed.places - 1) / 2) * Seedbed.alongGap)
        }
    }

    /// Every place in a plot, drill by drill.
    public static let slots: [Slot] = (0..<drills).flatMap { drill in
        (0..<places).map { Slot(drill: drill, index: $0) }
    }

    /// One plant standing in the Seedbed.
    public struct Planting: Codable, Equatable, Sendable {
        public var seed: String
        public var plot: Int
        public var slot: Slot
        public var traits: PlantTraits
        /// A small offset from the place, from the seed, and the only area
        /// whose two directions differ: 0.035 m across the drill and 0.06 m
        /// along it. **A drill has to read as a line**, which is the whole of
        /// what a seedbed looks like, and a line survives being uneven along
        /// its length but not being uneven across it. It leaves 0.40 m between
        /// neighbours in a drill at worst, and 0.67 m between drills.
        public var nudge: Spot

        public var spot: Spot {
            Spot(x: slot.spot.x + nudge.x, z: slot.spot.z + nudge.z)
        }
    }

    /// The whole area: every planting, in the order they arrived.
    public struct Ways: Codable, Equatable, Sendable {
        public private(set) var plantings: [Planting] = []

        public init() {}

        /// **The Seedbed as it opened**: the beginnings ambassador at the head
        /// of the first drill, and nothing else.
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

        /// How many plants are in a drill. A drill fills from the label, so
        /// this is also the index of its next place.
        public func sown(_ drill: Int, in plot: Int) -> Int {
            self.plot(plot).filter { $0.slot.drill == drill }.count
        }

        /// Where this plant goes, without planting it.
        ///
        /// Three steps, oldest plot first: a drill already sown with this kind
        /// and not yet full; failing that an unclaimed drill; failing that a
        /// new plot. **A drill is claimed, never reserved** — a kind that has
        /// not arrived holds nothing — which is what keeps a rare kind from
        /// pinning a drill open in every plot.
        public func place(for traits: PlantTraits) -> (plot: Int, slot: Slot) {
            let count = max(plots, 1)

            // A drill of this kind with room in it, oldest plot first.
            for plot in 0..<count {
                for drill in 0..<Seedbed.drills where kind(of: drill, in: plot) == traits.kind {
                    let next = sown(drill, in: plot)
                    if next < Seedbed.places { return (plot, Slot(drill: drill, index: next)) }
                }
            }

            // Otherwise the first drill nobody has sown, oldest plot first.
            for plot in 0..<count {
                for drill in 0..<Seedbed.drills where kind(of: drill, in: plot) == nil {
                    return (plot, Slot(drill: drill, index: 0))
                }
            }

            return (count, Slot(drill: 0, index: 0))
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
            let planting = Planting(seed: seed.hex, plot: plot, slot: slot, traits: traits,
                                    nudge: Spot(x: jitter(26, 0.035), z: jitter(27, 0.06)))
            plantings.append(planting)
            return planting
        }
    }

    /// The first plant in the Seedbed, and the one the area is drawn with
    /// before anybody has released anything into it.
    public static let ambassador: Planting = Ways.opened().plantings[0]
}
