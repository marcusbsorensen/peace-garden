#if os(WASI)
import FoundationEssentials
import WASILibc
#else
import Foundation
#endif

/// The Long Walk: a double herbaceous border either side of a mown path, one of
/// the ten areas of the shared garden on the website. `docs/WEB-GARDENS.md`.
///
/// **Curated by rule, not by hand.** Nobody places a plant here. An arriving
/// plant is given a slot once, by the rule below, and never moves; the rule is
/// what we curate. It lives in SeedCore so the plot service, the website and
/// the app all read the same one.
///
/// The rule is the oldest advice there is about a border, in the three parts
/// every border book gives it:
///
/// 1. **Tall at the back, low at the front.** Three tiers, set from the plant's
///    grown height, so nothing stands in front of something shorter.
/// 2. **Drifts, not dots.** Plants of one colour are set next to each other in
///    groups of three to five, so the eye reads a sweep of colour rather than
///    a confetti of single plants.
/// 3. **Repetition down the length.** Every plant here is unique — it grew from
///    one meeting — so a border cannot repeat a plant the way a nursery border
///    repeats a variety. It repeats a colour instead: a drift, once full, is
///    left, and the same colour starts again further down the walk.
///
/// **Interlocking drifts, since 2 October 2026** (Marcus, from
/// `design/garden-layouts-2026-10-02/RESEARCH.md`, the Long Walk, option A).
/// The tiers were two staggered straight rows each, so a border read as ranks.
/// Now each border's twenty-four places stand in six long, thin lenses
/// slanting from the hedge to the path's edge and overlapping like slates
/// (`PlaceTable.longWalkDrifts`), and the three parts of the rule become:
///
/// 1. **A lens's back is back tier and its tip front tier**, so nothing stands
///    in front of something shorter, by depth, as before.
/// 2. **A lens is a drift.** It is claimed by the colour family of the first
///    plant sown in it, as the Knot Garden claims a pair, and holds only that
///    colour: five places or three, which is the old cap of five.
/// 3. **The same colour never claims the lens beside its own**, in its plot or
///    across the join with the next, so a colour starts again further down the
///    walk.
///
/// **And each plot is graded cool–hot–cool**, as Jekyll's border at Munstead
/// Wood was (Marcus answered yes to it): a warm colour claims the free lens
/// nearest the plot's middle and a cool one the free lens nearest its ends, so
/// the walk pulses plot by plot. That is also what makes a plot of ten plants
/// look finished: ten strokes of colour round its middle and its ends rather
/// than a row from its head.
///
/// **The plot is 5.2 m square**, the app's own, with the walk running down its
/// `z` axis so that on the isometric screen the path runs away diagonally, the
/// way a path is seen from above and to one side. **Plots vary by their
/// number** (`variants`): turned half round, mirrored, or both, so the path
/// stays where it runs and the slant of the drifts changes plot to plot.
public enum LongWalk {

    // MARK: The ground

    /// A web plot's side, the app's fourteen-plant plot. Fixed: a web plot does
    /// not grow with what is in it, because the next plot is where the walk goes on.
    public static let plotSide = 5.2

    /// **How this area's plots vary**, from each plot's number (`PlotVariant`,
    /// Marcus's decision of 2 October 2026). Half turns and mirrors only, so the
    /// path stays where it runs down the walk: four ways, every one of them
    /// within any four plots in a row.
    public static let variants = PlotVariant.Space(turns: 2, mirror: true)

    /// The mown path, either side of `x = 0`. 1.2 m: two people abreast.
    public static let pathHalfWidth = 0.6

    /// Where each border's hedge begins, measured out from the middle of the path.
    public static let hedgeFrom = 2.3

    /// The length of the walk a plot's places are spread over, leaving a little
    /// at each end so one plot's last plant does not stand on the next plot's first.
    public static let plantedLength = 4.8

    /// The borders' places, made offline: twelve lenses, middle first.
    public static let table = PlaceTable.longWalkDrifts

    // MARK: Tiers

    /// Front, middle and back of a border.
    public enum Tier: Int, Codable, CaseIterable, Sendable {
        case edge, middle, back

        /// Places in this tier on one side of one plot: a lens of five has one
        /// back place, two middle and two front, a lens of three one of each,
        /// so six, nine and nine.
        public var slots: Int { LongWalk.slots.filter { $0.side == .left && $0.tier == self }.count }
    }

    /// The tier a grown plant belongs in.
    ///
    /// **Measured, then set to fit the slots.** Across three hundred crossings
    /// of three hundred different pairs of parents, grown heights run 0.15 m to
    /// 2.31 m with thirds at 0.70 m and 1.09 m. A side of a plot had five front
    /// slots, four middle and three back a row, so the cuts are at the 42nd and 75th
    /// centiles instead, 0.77 m and 1.20 m: set at the thirds, the back rows
    /// filled first and every plot opened with its front edge half empty.
    ///
    /// **Measured again on 24 September 2026**, when the plants' shapes changed
    /// and every area's cuts with them; they were 0.93 m and 1.28 m. Three
    /// thousand crossings put the same two centiles at 0.771 m and 1.185 m, so
    /// three hundred was enough.
    ///
    /// **0.75 and 1.18 since 29 September 2026**, measured again after the
    /// re-roll of the 28th brought the reed and the cushion. This time on three
    /// thousand crossings of three thousand pairs, where the two centiles are
    /// 0.746 m and 1.183 m: three hundred of the same put the lower one at
    /// 0.795, and the Knot Garden's own five hundred at 0.741, so three hundred
    /// is no longer enough to say a number to the centimetre. The heights now
    /// run 0.12 m to 2.47 m, with thirds at 0.62 m and 1.07 m.
    ///
    /// **Kept when the drifts came on 2 October 2026**, though a side now has
    /// nine front places, nine middle and six back where it had ten, eight and
    /// six: a plant that finds its own tier full in a plot stands in the tier
    /// beside it where the heights around it still order, and the fill on the
    /// area's own plants was better than the rows' (`tools/layouts`).
    ///
    /// Crossings of **one** person with forty others ran taller and were half
    /// bells, which is why the sample is three hundred different pairs.
    /// **Named, as the other four areas' cuts are.** They were literals inside
    /// this function until 22 September, which meant a test that wanted to
    /// check how close a plant stands to a tier boundary had to write 0.93 down
    /// a second time — and a second copy of a number is a number that can
    /// drift from the one it copies.
    public static let middleFrom = 0.75
    public static let backFrom = 1.18

    public static func tier(height: Double) -> Tier {
        if height < middleFrom { return .edge }
        if height < backFrom { return .middle }
        return .back
    }

    // MARK: Colour

    /// The colour families a drift is made of: six arcs of the hue circle, and
    /// pale for the flowers too unsaturated to have a hue at all.
    public static let paleFamily = 6

    public static func family(hue: Double, saturation: Double) -> Int {
        if saturation < 0.22 { return paleFamily }
        let turn = hue > 1 ? hue / 360 : hue
        let wrapped = turn - turn.rounded(.down)
        return min(5, Int(wrapped * 6))
    }

    /// **The warm colours**: the reds and oranges, the yellows, and the
    /// magentas — families 0, 1 and 5. They claim lenses from the middle of a
    /// plot out, and the cool ones — the greens, the blues, the violets and
    /// the pale — from its ends in, so each plot runs cool–hot–cool, as
    /// Jekyll's main border at Munstead Wood did.
    public static func isWarm(_ family: Int) -> Bool {
        family == 0 || family == 1 || family == 5
    }

    // MARK: A plant's traits

    /// What a placement rule needs to know about a plant, and nothing else.
    ///
    /// **`PlantTraits` under another name**, since 21 September, when the Quiet
    /// Garden wanted the same two facts. The grown height and the flower's
    /// colour family are facts about a plant rather than about this area; what
    /// belongs to an area is what it reads off them, which is `tier` here and
    /// `stand` there. The spelling stays because it is in
    /// `long_walk_vectors.json` and in the PHP port, and the encoded shape is
    /// the same two fields either way.
    public typealias Traits = PlantTraits

    /// Read from the grown plant. Builds its mesh once, which is why a plant's
    /// traits are stored with it rather than read again.
    ///
    /// Not the Long Walk's alone — every area needs these two — but it lives
    /// here because this is the area that first needed it, and moving it would
    /// rename a function the port and the vectors both know.
    public static func traits(of genome: Genome) -> Traits {
        let bounds = Maturity.bounds(for: genome)
        let petal = genome.palette.petalBase
        return Traits(height: Double(bounds.max.y - bounds.min.y),
                      family: family(hue: petal.hue, saturation: petal.saturation),
                      kind: genome.name.epithet,
                      hue: petal.hue,
                      habit: genome.form.archetype.rawValue)
    }

    // MARK: Slots

    public enum Side: Int, Codable, CaseIterable, Sendable {
        case left = -1
        case right = 1
    }

    /// One place in one plot.
    ///
    /// **`index` is the place's number in the table** since 2 October 2026,
    /// in the order the table offers them; the side and the tier are the
    /// table's for that place, kept beside it because they are what the
    /// service stores and what a reader of a planting asks first.
    public struct Slot: Codable, Equatable, Hashable, Sendable {
        public var side: Side
        public var tier: Tier
        public var index: Int

        public init(side: Side, tier: Tier, index: Int) {
            self.side = side
            self.tier = tier
            self.index = index
        }

        /// The table's place `index`, with its side and tier.
        public init(index: Int) {
            let place = LongWalk.table.places(nudge: 0)[index]
            self.init(side: Side(rawValue: LongWalk.table.tag("side", of: place))!,
                      tier: Tier(rawValue: LongWalk.table.tag("tier", of: place))!,
                      index: index)
        }

        /// Which lens the place is in: its rank from the plot's middle.
        public var lens: Int { LongWalk.lensOf[index] }

        /// Where the place is in the table, before its plot is turned.
        public var spot: Spot { LongWalk.table.places(nudge: 0)[index].spot }
    }

    /// Every place in one plot, in the table's order: the lens nearest the
    /// middle of the plot first, and in each lens its middle first.
    public static let slots: [Slot] = (0..<table.places(nudge: 0).count).map { Slot(index: $0) }

    /// How many lenses a plot has: six a border.
    public static let lenses = 12

    /// Each place's lens, and each lens's places in the table's order.
    static let lensOf: [Int] = table.places(nudge: 0).map { table.tag("lens", of: $0) }
    static let placesIn: [[Int]] = (0..<lenses).map { lens in slots.indices.filter { lensOf[$0] == lens } }

    /// Each lens's side, and where it comes in its border from the head of
    /// the plot, 0 to 5.
    static let sideOf: [Int] = (0..<lenses).map { table.tag("side", of: table.places(nudge: 0)[placesIn[$0][0]]) }
    static let alongOf: [Int] = (0..<lenses).map { table.tag("along", of: table.places(nudge: 0)[placesIn[$0][0]]) }

    /// **The order a colour claims lenses in.** A warm colour takes the lenses
    /// as the table numbers them, middle first; a cool one takes the same
    /// groups of four the other way round, the two at each end first, then the
    /// next two, then the middle.
    static func claimOrder(warm: Bool) -> [Int] {
        warm ? Array(0..<lenses) : [8, 9, 10, 11, 4, 5, 6, 7, 0, 1, 2, 3]
    }

    /// The variant a plot is laid with, from its number.
    public static func variant(of plot: Int) -> PlotVariant {
        PlotVariant.of(plot: plot, area: .travel)
    }

    /// **Where a lens is on the walk as drawn**: which side of the path, and
    /// where it comes from the head of its plot, once the plot is turned. Read
    /// by turning a point at the lens's side and its place along the border, so
    /// it is exact: half-integers, turned by a sign.
    static func onTheWalk(_ lens: Int, in plot: Int) -> (side: Int, along: Int) {
        let at = variant(of: plot).apply(Spot(x: Double(sideOf[lens]), z: Double(alongOf[lens]) - 2.5))
        return (at.x < 0 ? -1 : 1, Int(at.z + 2.5))
    }

    // MARK: Planting

    /// One plant in the walk, placed for good.
    public struct Planting: Codable, Equatable, Sendable {
        public var seed: String
        public var plot: Int
        public var slot: Slot
        public var traits: Traits
        /// A small offset from the place, from the seed, so plants set by a
        /// rule do not stand exactly where the table says. Kept, like
        /// everything else here.
        public var nudge: Spot

        /// Where it stands in its plot: its place and its nudge, turned as its
        /// plot is.
        public var spot: Spot {
            LongWalk.variant(of: plot).apply(Spot(x: slot.spot.x + nudge.x, z: slot.spot.z + nudge.z))
        }
    }

    /// One plot as the rule reads it: which places are taken, what claimed
    /// each lens, and who stands where.
    struct Plot {
        var taken = Set<Int>()
        var claims = [Int?](repeating: nil, count: LongWalk.lenses)
        var here: [Planting] = []
    }

    /// The whole walk: every planting, in the order they arrived.
    ///
    /// **Append-only.** `plant` adds one and changes nothing already there. That
    /// is the property the old seed-derived grid existed to give — a place
    /// visited yesterday is the same place today — kept without deriving the
    /// place from the seed, which could not know which bed has room.
    public struct Walk: Codable, Equatable, Sendable {
        public private(set) var plantings: [Planting] = []

        public init() {}

        /// **The walk as it opened**: the travel ambassador standing in it, and
        /// nothing else. `LongWalk.ambassador` is the planting.
        ///
        /// Kept apart from `init()` deliberately. An empty walk is what the rule
        /// is judged against — `LongWalkVectorTests` plants six hundred arrivals
        /// into one and pins where each went — and a walk that arrived with a
        /// plant already in it would move every one of those placements.
        public static func opened() -> Walk {
            var walk = Walk()
            let one = Ambassadors.of(.travel)
            walk.plant(seed: one.seed, traits: LongWalk.traits(of: one.genome))
            return walk
        }

        /// Plots opened so far.
        public var plots: Int { (plantings.map(\.plot).max() ?? -1) + 1 }

        /// The colour family that claimed a lens of a plot: the first plant
        /// sown in it. Nil if nobody has. **Read off the plants rather than
        /// stored**, as the Knot Garden's pairs and the Seedbed's drills are.
        public func claim(of lens: Int, in plot: Int) -> Int? {
            plantings.first { $0.plot == plot && $0.slot.lens == lens }?.traits.family
        }

        /// Every plot up to `count`, read in one pass over the plantings.
        func read(_ count: Int) -> [Plot] {
            var out = Array(repeating: Plot(), count: count)
            for p in plantings where p.plot < count {
                out[p.plot].taken.insert(p.slot.index)
                if out[p.plot].claims[p.slot.lens] == nil { out[p.plot].claims[p.slot.lens] = p.traits.family }
                out[p.plot].here.append(p)
            }
            return out
        }

        /// Where the next plant with these traits would go, without planting it.
        ///
        /// **The rule is not "tall ones in the back row".** It is that nothing
        /// stands in front of something shorter than itself, which is what the
        /// back row is for. Filling by row alone broke on the first real mix:
        /// a few more tall plants than back slots, and each surplus one opened a
        /// plot of its own, so the walk trailed off into beds holding six back-row
        /// plants each and nothing in front of them.
        ///
        /// So, in each plot from the oldest, before the walk goes on:
        ///
        /// 1. A lens its colour has claimed, in its own tier.
        /// 2. A lens nobody has claimed, in its own tier, taken in its colour's
        ///    order — middle first if it is warm, ends first if it is cool —
        ///    and never one beside a lens of its colour (`besideItsColour`).
        /// 3. A lens its colour has claimed, in the tier beside its own, where
        ///    everything near it in front is shorter and everything behind is
        ///    taller.
        ///
        /// Then a new plot, the first lens in its colour's order. In a lens a
        /// plant takes the first free place of its tier in the table's order,
        /// the lens's middle first. The ordering is checked for every placement,
        /// its own tier included, so it holds everywhere and not on average.
        public func place(for traits: Traits) -> (plot: Int, slot: Slot) {
            let own = traits.tier
            let beside = Tier.allCases.filter { abs($0.rawValue - own.rawValue) == 1 }
            let order = LongWalk.claimOrder(warm: LongWalk.isWarm(traits.family))
            let count = plots
            var state = read(count + 1)

            for plot in 0..<count {
                for lens in order where state[plot].claims[lens] == traits.family {
                    if let slot = open(lens, in: state[plot], tiers: [own], height: traits.height) {
                        return (plot, slot)
                    }
                }
                for lens in order where state[plot].claims[lens] == nil
                    && !besideItsColour(lens, in: plot, family: traits.family, state: state) {
                    if let slot = open(lens, in: state[plot], tiers: [own], height: traits.height) {
                        return (plot, slot)
                    }
                }
                for lens in order where state[plot].claims[lens] == traits.family {
                    if let slot = open(lens, in: state[plot], tiers: beside, height: traits.height) {
                        return (plot, slot)
                    }
                }
            }
            // A new plot. It is empty, so every lens has a place of every tier
            // and the only thing that can refuse one is its colour beside it
            // across the join.
            state[count] = Plot()
            for lens in order where !besideItsColour(lens, in: count, family: traits.family, state: state) {
                if let slot = open(lens, in: state[count], tiers: [own], height: traits.height) {
                    return (count, slot)
                }
            }
            return (count, open(order[0], in: state[count], tiers: [own], height: traits.height)!)
        }

        /// The first free place of these tiers in a lens, in the table's order,
        /// where a plant this tall stands in order with those around it.
        func open(_ lens: Int, in plot: Plot, tiers: [Tier], height: Double) -> Slot? {
            for index in LongWalk.placesIn[lens] where !plot.taken.contains(index) {
                let slot = LongWalk.slots[index]
                if tiers.contains(slot.tier) && inOrder(height, at: slot, among: plot.here) { return slot }
            }
            return nil
        }

        /// **Whether a lens is beside one its colour holds**: the lens before
        /// or after it in its own border, or, at the end of a plot, the lens it
        /// meets across the join with the plot before or after, as the walk is
        /// drawn. A colour that took it would run two drifts into one, past
        /// five, and the repetition down the walk is a colour starting again
        /// somewhere else.
        func besideItsColour(_ lens: Int, in plot: Int, family: Int, state: [Plot]) -> Bool {
            let side = LongWalk.sideOf[lens], along = LongWalk.alongOf[lens]
            for other in 0..<LongWalk.lenses where LongWalk.sideOf[other] == side
                && abs(LongWalk.alongOf[other] - along) == 1 && state[plot].claims[other] == family {
                return true
            }
            let drawn = LongWalk.onTheWalk(lens, in: plot)
            for (neighbour, end, meets) in [(plot - 1, 0, 5), (plot + 1, 5, 0)]
                where drawn.along == end && neighbour >= 0 && neighbour < state.count {
                for other in 0..<LongWalk.lenses where state[neighbour].claims[other] == family {
                    let there = LongWalk.onTheWalk(other, in: neighbour)
                    if there.side == drawn.side && there.along == meets { return true }
                }
            }
            return false
        }

        /// Whether a plant this tall can stand in this slot: shorter than what
        /// is near it behind, taller than what is near it in front. Asked of
        /// the table's places, before the plot is turned, which a turn moves
        /// without changing how far apart they are.
        func inOrder(_ height: Double, at slot: Slot, among here: [Planting]) -> Bool {
            for other in here where other.slot.side == slot.side
                && abs(other.slot.spot.z - slot.spot.z) <= Self.orderReach {
                let behind = other.slot.tier.rawValue > slot.tier.rawValue
                let inFront = other.slot.tier.rawValue < slot.tier.rawValue
                if behind && other.traits.height < height { return false }
                if inFront && other.traits.height > height { return false }
            }
            return true
        }

        /// Plant one arrival, and say where it went.
        @discardableResult
        public mutating func plant(seed: SeedID, traits: Traits) -> Planting {
            let (plot, slot) = place(for: traits)
            let bytes = [UInt8](seed.bytes)
            func jitter(_ i: Int, _ reach: Double) -> Double {
                guard bytes.count > i else { return 0 }
                return (Double(bytes[i]) / 255 - 0.5) * 2 * reach
            }
            let planting = Planting(seed: seed.hex, plot: plot, slot: slot, traits: traits,
                                    nudge: Spot(x: jitter(20, Self.nudge), z: jitter(21, Self.nudge)))
            plantings.append(planting)
            return planting
        }

        /// The plantings in one plot.
        public func plot(_ index: Int) -> [Planting] {
            plantings.filter { $0.plot == index }
        }

        /// How far along the walk "in front of" and "behind" reach, for the
        /// rule that nothing stands in front of something shorter.
        static let orderReach = 1.3

        /// **How far a plant is nudged from its place**, either way. 0.05 m
        /// since the drifts: the places no longer stand on a grid for a nudge
        /// to hide, and in a lens of five they stand 0.36 m apart, where the
        /// rows' 0.1 m and 0.14 m would have stood two plants nearly touching.
        static let nudge = 0.05
    }

    // MARK: The ambassador

    /// **The plant standing where the walk begins.**
    ///
    /// *Zephea pallida* — `Ambassadors.of(.travel)`, sown a month before
    /// the garden opened — placed by this rule into an empty walk, which is the
    /// whole of what makes it the specimen. `docs/WEB-GARDENS.md` asks which
    /// slot of a template an ambassador stands in; for this area the answer is
    /// that it stands in the first one the rule filled. A double border's
    /// feature belongs at the end of its vista, and this walk has no end — its
    /// plots open end to end for as long as people go on meeting — so what it
    /// has instead is a first plot, and the oldest plant in the area stands in
    /// it. **Since the drifts it stands in the middle of that plot**, at the tip
    /// of the first lens a warm colour claims, because it is red.
    ///
    /// **It takes its own tier, like anything else.** *Zephea* is 0.52 m, which
    /// is the edge of a border rather than the back of one, and three of the
    /// ten ambassadors are back-tier plants. A specimen slot fixed at the back
    /// of a border would have stood a short plant behind taller ones in seven
    /// areas out of ten, which is the one rule the walk is built on. (Until
    /// the re-roll of 28 September 2026 it was *Halula crassicaulis*, 1.02 m,
    /// in the middle tier, and one of the ten was a back-tier plant.)
    ///
    /// **It is not a row anywhere.** A slot and a nudge are both pure functions
    /// of the seed, and the seed is pinned, so asking for the placement again
    /// gives the same answer for ever — there is nothing to store. That is also
    /// what keeps it out of `long_walk`: nobody offered it, so it is not in the
    /// table of things people offered, and there is no row for a withdrawal or a
    /// report to reach. The rule still sees it, because the service hands it to
    /// the rule ahead of the stored arrivals, so everything planted afterwards
    /// is graded against a plant that is standing there.
    public static let ambassador: Planting = Walk.opened().plantings[0]
}

/// The Long Walk's reading of a plant: which tier of a border it belongs in.
///
/// An extension rather than a property of `PlantTraits`, because the reading
/// belongs to the area and not to the plant. The Quiet Garden's `stand` sits
/// beside it in that area's own file, and a third area will add a third.
extension PlantTraits {
    public var tier: LongWalk.Tier { LongWalk.tier(height: height) }
}
