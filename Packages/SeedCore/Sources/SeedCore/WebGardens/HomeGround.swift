#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// The Home Ground: a kitchen garden of three beds, a crop to a bed, rows
/// across each, the tall end away from the sun. `docs/WEB-GARDENS.md` §*The
/// Home Ground, chosen*.
///
/// **The tenth area, and the one whose crops are in the name.** The area's
/// genus heads are `Cer`, `Fen` and `Pell`, and `PlantName.roots` gives each
/// of those to one archetype and nothing else: `Cer` is always a spire, `Fen`
/// always an umbel, `Pell` always a succulent. So every plant here is one of
/// three forms in nearly equal shares, and three forms as unlike each other as
/// a grain, a crop run to seed and a salad bed. **The crop is the genus root**,
/// and it is read off the plant's habit (`PlantTraits.habit`), which names the
/// same thing exactly and already travels on every path a plant arrives by.
///
/// **The crop decides the bed, the height decides the end.** A bed is claimed
/// by the first crop sown in it and takes that crop's spacing from then on, as
/// a Seedbed drill takes its kind. Within a bed a plant at least as tall as its
/// crop's cut takes the next place from the north end, and a shorter one the
/// next place from the south; the bed is full when the two meet. A height is
/// compared only with a cut, never with another plant, so nothing is ever
/// displaced: a bed with a place left has a place for any plant of its crop.
///
/// **Marcus's answers, on 24 September**: the crop's own spacing, rosettes at
/// their new width; both ends; trodden-soil paths and mounded beds with no
/// boards; the umbel's cut moved to 0.930 m.
///
/// **Lazy beds that follow the land since 2 October 2026**, option A of the
/// layouts Marcus approved that day (`design/garden-layouts-2026-10-02/RESEARCH.md`):
/// the three beds sway together in a lazy S, as hand-dug ridges follow the
/// ground, with the rows running square to the curve, and a plot is drawn
/// mirrored or not by its number, so the sway alternates. The rule did not
/// change: every slot is the slot it was, and only where it is drawn moved.
/// Where the places are is four tables made offline
/// (`tools/layouts/tables/home_ground_*.py`).
///
/// The rule runs in SeedCore so the plot service, the website and the app read
/// one copy. `Server/.api/HomeGround.php` is the port, and
/// `tools/reference/check_home_ground.php` holds them together.
public enum HomeGround {

    // MARK: The plot

    /// The same square every area uses.
    public static let plotSide = 5.2

    /// **How this area's plots vary**, from each plot's number (`PlotVariant`,
    /// Marcus's decision of 2 October 2026). Mirrored only, so north stays north
    /// and the tall end of every bed with it, and a space of two alternates plot
    /// by plot: the beds sway one way in one plot and the other way in the next.
    public static let variants = PlotVariant.Space(mirror: true)

    /// **Three beds, each 1.2 m wide and 4.2 m long**, running the length of
    /// the plot, their middles swaying about `x` −1.60, 0 and +1.60. Paths of
    /// 0.40 m between them and a headland of 0.5 m at each end. A bed is 1.2 m
    /// so that no soil is ever stood on.
    ///
    /// **They sway 0.15 m either way** (`tools/layouts/tables/_home_ground.py`),
    /// Marcus's choice of 2 October 2026 for a bolder S than the 0.10 m first
    /// built. The paths narrowed from 0.45 m to 0.40 m to make the room: the
    /// outer beds have the 0.18 m between their straight edges and the nearest
    /// any slab's edge comes to move in. `bedX` is the straight line each sways
    /// about; where a bed's middle really runs is `line(of:)`.
    public static let beds = 3
    public static let bedX: [Double] = [-1.60, 0, 1.60]
    public static let bedWidth = 1.2
    public static let bedLength = 4.2

    /// A bed's middle as the plot's variant draws it: a line from its north end
    /// to its south, a point every 5 cm.
    public static func line(of bed: Int, on variant: PlotVariant = .plain) -> [Spot] {
        PlaceTable.homeGroundBeds.curve("bed\(bed)", on: variant).points
    }

    /// How far a plant stands off its place, from the seed: **0.05 m along the
    /// row and 0.025 m down the bed**. A row across a bed has to read as a row,
    /// for the reason a drill does in the Seedbed, so the tighter reach is the
    /// one that would break it.
    public static let nudgeAcross = 0.05
    public static let nudgeDown = 0.025

    // MARK: The crops

    /// **The three crops, which are the area's three genus roots.** Named by
    /// the root, because that is the fact about the plant; the habit is how the
    /// service comes to know it.
    public enum Crop: String, Codable, CaseIterable, Sendable {
        /// The grain: spires, in a stand.
        case cer = "Cer"
        /// The fennel's family: umbels, flat heads, what carrots and parsnips
        /// are when they run to seed.
        case fen = "Fen"
        /// The earth's skin: low rosettes, packed close, like a salad bed.
        case pell = "Pell"

        /// **How a bed of this crop is set out**, which is what every seed
        /// packet is for: plants across a row, the gap between them, rows down
        /// the bed and the gap between those. Each crop is spaced at about its
        /// own median spread, so neighbours meet as a sown crop's do, and every
        /// crop's rows span the same 3.6 m of the bed's 4.2.
        ///
        /// The rosettes were to be four across at 0.28 m and thirteen rows,
        /// fifty-two a bed. After the plants' shapes changed on 24 September
        /// 2026 they grow 0.38 m across, and 88% would have been wider than the
        /// gap; Marcus chose their new width, which leaves half wider than it,
        /// as the spires and umbels are.
        public var sown: (across: Int, gap: Double, rows: Int, rowGap: Double) {
            switch self {
            case .cer:  return (3, 0.40, 9, 0.45)
            case .fen:  return (2, 0.60, 7, 0.60)
            case .pell: return (3, 0.38, 10, 0.40)
            }
        }

        /// How many plants a bed of this crop holds: 27 spires, 14 umbels, 30
        /// rosettes.
        public var capacity: Int { sown.across * sown.rows }

        /// **Where a bed sown with this crop has its places**, made offline:
        /// every bed's, bed by bed, each in the slots' order.
        public var table: PlaceTable {
            switch self {
            case .cer:  return .homeGroundCer
            case .fen:  return .homeGroundFen
            case .pell: return .homeGroundPell
            }
        }

        /// **The height that sends a plant to the north end**: the crop's own
        /// median, measured over 2,000 Home Ground plants on the new shapes
        /// (`tools/homeground`). Three cuts rather than one, because the three
        /// crops barely overlap, and a single cut would leave a bed of one crop
        /// ungraded.
        ///
        /// **The umbel's is 0.930 m, not the measured 0.932**, where a village
        /// arrival stood 0.009 mm from it: under the hundredth of a millimetre
        /// two hosts' heights are compared to. At 0.930 the nearest plant in
        /// every sample is 0.58 mm away and the tall share is the same, 50.1%.
        /// The spire's 1.346 is 0.89 mm clear and the rosette's 0.275 is
        /// 0.48 mm clear, so both stand as measured. Rounding all three to two
        /// places would not do: 1.35 falls 0.002 mm from a spire.
        ///
        /// **Measured again on 29 September 2026**, after the re-roll of the
        /// 28th, on a fresh 2,000 (`tools/homeground`, its cache cleared): the
        /// spire's median 1.261 m, down from 1.346 since a spire flowers from
        /// below; the rosette's 0.266, down from 0.275; the umbel's still
        /// 0.932, so its 0.930 stands. The nearest plant in any of the tool's
        /// samples is 0.03 mm from its crop's cut.
        public var cut: Double {
            switch self {
            case .cer:  return 1.261
            case .fen:  return 0.930
            case .pell: return 0.266
            }
        }

        /// **The crop a plant's habit names.** A spire is a `Cer`, an umbel a
        /// `Fen`, a succulent a `Pell`, exactly, in this area.
        ///
        /// **A plant whose habit was never sent is sown as an umbel**: an
        /// offer from a phone that predates the Coppice, or anything the naming
        /// table would never put here. The umbel's spacing is the widest, so
        /// whatever the plant is it has room, and its crop is the commonest and
        /// the ambassador's. It is planted rather than refused, as every area
        /// plants an older phone's plant, and a replant from the seeds puts it
        /// in its own crop's bed.
        public init(habit: String) {
            switch habit {
            case Archetype.spire.rawValue:     self = .cer
            case Archetype.succulent.rawValue: self = .pell
            default:                           self = .fen
            }
        }
    }

    /// Which end of a bed a plant's height asks for.
    public enum End: Int, Codable, CaseIterable, Sendable {
        case north = 0, south
    }

    /// The end a plant of this crop and height is sown from. **Compared with a
    /// cut and never with another plant**, so the one place two hosts can
    /// disagree about a placement is at the three cuts, and
    /// `HomeGroundVectorTests` holds the recorded arrivals clear of them.
    public static func end(_ traits: PlantTraits) -> End {
        traits.height >= Crop(habit: traits.habit).cut ? .north : .south
    }

    // MARK: Slots

    /// One place in one plot: which bed, the crop it is sown with, and where
    /// in it, numbered in reading order from the north end — row by row, west
    /// to east along a row — so place 0 is the north-west corner and the last
    /// the south-east, as the table draws the plot.
    ///
    /// **The crop is in the slot because the spacing is**: the same index is a
    /// different spot in a bed of spires and a bed of rosettes.
    public struct Slot: Codable, Equatable, Hashable, Sendable {
        public var bed: Int
        public var crop: Crop
        public var index: Int

        public init(bed: Int, crop: Crop, index: Int) {
            self.bed = bed
            self.crop = crop
            self.index = index
        }

        public var row: Int { index / crop.sown.across }
        public var column: Int { index % crop.sown.across }

        /// Where the place is, in metres from the middle of its plot, as the
        /// table draws the plot: a plot mirrored by its number draws it the
        /// other way round (`HomeGround.Planting.spot`). **North is `z−`**, the
        /// end the page's midday sun is behind.
        ///
        /// **Read from the crop's table**, bed by bed and in this order within
        /// each: the row's place along the bed's line, square to it, `gap`
        /// apart, worked out once with the curve and written down to the
        /// millimetre, so every host holds the same number.
        public var spot: Spot {
            crop.table.places(nudge: 0)[bed * crop.capacity + index].spot
        }
    }

    /// Every place in a bed sown with this crop, north end first.
    public static func slots(bed: Int, crop: Crop) -> [Slot] {
        (0..<crop.capacity).map { Slot(bed: bed, crop: crop, index: $0) }
    }

    // MARK: Planting

    /// One plant in the Home Ground, placed for good.
    public struct Planting: Codable, Equatable, Sendable {
        public var seed: String
        public var plot: Int
        public var slot: Slot
        /// The plant's traits, **its habit among them**, which names its crop.
        public var traits: PlantTraits
        /// A small offset from the place, from the seed: 0.05 m along the row,
        /// 0.025 m down the bed.
        public var nudge: Spot

        /// **Where the plant stands**: its place and its nudge added as the
        /// table draws the plot, then the sum mirrored if the plot is
        /// (`PlotVariant`). In that order because the nudge is narrower one way
        /// than the other, and it has to turn with its row.
        public var spot: Spot {
            let place = slot.spot
            return PlotVariant.of(plot: plot, area: .ground)
                .apply(Spot(x: place.x + nudge.x, z: place.z + nudge.z))
        }
    }

    /// The whole area: every planting, in the order they arrived. Append-only,
    /// as the other nine are.
    public struct Ways: Codable, Equatable, Sendable {
        public private(set) var plantings: [Planting] = []

        public init() {}

        /// **The Home Ground as it opened**: the ground ambassador, *Fenunora
        /// patentifolia*, an umbel over its cut, at the north-west corner of
        /// the first bed, and nothing else.
        public static func opened() -> Ways {
            var ways = Ways()
            let one = Ambassadors.of(.ground)
            ways.plant(seed: one.seed, traits: LongWalk.traits(of: one.genome))
            return ways
        }

        public var plots: Int { (plantings.map(\.plot).max() ?? -1) + 1 }

        public func plot(_ index: Int) -> [Planting] {
            plantings.filter { $0.plot == index }
        }

        /// The crop this bed of this plot is sown with, or nil if nobody has
        /// sown it. **Read off the plants rather than stored**, as the
        /// Seedbed's drills are: a claim that is the plants cannot disagree
        /// with them.
        public func crop(of bed: Int, in plot: Int) -> Crop? {
            self.plot(plot).first { $0.slot.bed == bed }?.slot.crop
        }

        /// The place this end of a bed would give next, or nil if the bed is
        /// full. **The first free place counted from that end**, so the north
        /// end fills 0, 1, 2… and the south end the last place, the one before
        /// it…, and the two meet wherever the arrivals put the meeting.
        func next(_ end: End, bed: Int, crop: Crop, among plot: [Planting]) -> Int? {
            let taken = Set(plot.filter { $0.slot.bed == bed }.map(\.slot.index))
            let places = 0..<crop.capacity
            switch end {
            case .north: return places.first { !taken.contains($0) }
            case .south: return places.last { !taken.contains($0) }
            }
        }

        /// Where the next plant with these traits would go, without planting
        /// it.
        ///
        /// 1. A bed already sown with this plant's crop and not yet full,
        ///    oldest plot first, beds west to east.
        /// 2. Otherwise the first bed nobody has sown, oldest plot first. It
        ///    takes this crop's spacing from then on.
        /// 3. Otherwise a new plot, its west bed.
        ///
        /// Within the bed, the end the plant's height asks for. **Claimed,
        /// never reserved**, which is what kept the simulation's village at 89%
        /// where beds fixed to a crop in every plot held 77%: a garden short of
        /// one crop does not leave that crop's bed half empty in every plot.
        public func place(for traits: PlantTraits) -> (plot: Int, slot: Slot) {
            let crop = Crop(habit: traits.habit)
            let end = HomeGround.end(traits)
            let opened = plots
            let byPlot = (0..<opened).map { self.plot($0) }
            let claims = byPlot.indices.map { p in (0..<HomeGround.beds).map { self.crop(of: $0, in: p) } }

            for plot in byPlot.indices {
                for bed in 0..<HomeGround.beds where claims[plot][bed] == crop {
                    if let index = next(end, bed: bed, crop: crop, among: byPlot[plot]) {
                        return (plot, Slot(bed: bed, crop: crop, index: index))
                    }
                }
            }
            for plot in byPlot.indices {
                if let bed = claims[plot].firstIndex(where: { $0 == nil }) {
                    return (plot, Slot(bed: bed, crop: crop, index: HomeGround.first(end, crop: crop)))
                }
            }
            return (opened, Slot(bed: 0, crop: crop, index: HomeGround.first(end, crop: crop)))
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
                                    nudge: Spot(x: jitter(26, HomeGround.nudgeAcross),
                                                z: jitter(27, HomeGround.nudgeDown)))
            plantings.append(planting)
            return planting
        }
    }

    /// The first place an empty bed gives from this end.
    static func first(_ end: End, crop: Crop) -> Int {
        end == .north ? 0 : crop.capacity - 1
    }

    /// **The first plant in the Home Ground**, and the one it is drawn with
    /// before anybody has released anything into it: `Ambassadors.of(.ground)`
    /// placed by this rule into an empty area. An umbel 1.100 m tall, over the
    /// umbel's cut, so it opens the west bed of plot 0 for umbels at its north
    /// end: the head of the garden. It is 1.06 m across, wider than nine umbels
    /// in ten, and leans into the row beside it, which the first plant in a bed
    /// is allowed to do. Derived rather than stored, as the other nine are.
    public static let ambassador: Planting = Ways.opened().plantings[0]
}

/// The Home Ground's reading of a plant: its crop, and the end of the bed its
/// height asks for.
extension PlantTraits {
    public var crop: HomeGround.Crop { HomeGround.Crop(habit: habit) }
    public var homeGroundEnd: HomeGround.End { HomeGround.end(self) }
}
