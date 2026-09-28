#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// The Coppice: a wood cut in three coupes, one a winter in turn, with ferns
/// growing back from the stools and stars in flower in the light between.
/// `docs/WEB-GARDENS.md` §*The Coppice, chosen* and §*The Coppice, built*.
///
/// **The ninth area, and the first whose own plants divide by habit.** Every
/// plant here is a fern or a star — the area's genus heads, `Dros` and `Ros`,
/// are given to those two archetypes and to nothing else — so the rule asks a
/// plant its habit before it asks its height (`PlantTraits.habit`). A fern
/// stands on a stool and is cut with its coupe; a star stands on the floor
/// and is never cut, so every flower in the wood is drawn in flower every
/// year.
///
/// **The first area that knows its date.** A coupe's stage — cut this winter,
/// regrowing, grown — is arithmetic on its place in the wood and the year
/// (`stage(plot:coupe:year:)`), and the year turns at the winter solstice. The
/// plot service says which year it is, so two visitors either side of midnight
/// see one wood. Nothing the rule decides depends on it: a place is taken once
/// and never changes, and the stage is a matter of drawing.
///
/// **Marcus's answers, on 24 September**: thirty-three a plot; ferns on the
/// stools and stars on the floor; the stars' colours mixed as they arrive; the
/// rotation turning on 21 December UTC.
///
/// The rule runs in SeedCore so the plot service, the website and the app read
/// one copy. `Server/.api/Coppice.php` is the port, and
/// `tools/reference/check_coppice.php` holds them together.
public enum Coppice {

    // MARK: The plot

    /// The same square every area uses.
    public static let plotSide = 5.2

    /// Three coupes of eleven: five stools down the middle of each, and three
    /// places in the light either side of them, a back row and a front row.
    /// Thirty-three a plot, Marcus's choice on 24 September.
    ///
    /// **The stool share, 45%, is the template's one real number.** Swept
    /// from three to seven stools a coupe, every share between 43% and 47%
    /// filled well; above half the stools are left waiting for ferns, and
    /// below 38% the ferns crowd the floor's front rows.
    public static let coupes = 3
    public static let stools = 5
    public static let floorRow = 3

    /// The middles of the three coupes, in `z` from the middle of the plot.
    /// **Coupe 0 is `z−`**, the far band before the page is turned, and the
    /// coupes are cut in that order.
    public static let coupeZ: [Double] = [-1.80, 0, 1.80]

    /// The two rides between the coupes: their centrelines at `z` ±0.90, each
    /// 0.48 m wide and wandering up to 0.08 m off its line. Drawn, never
    /// planted; the places are set to clear them.
    public static let rideZ = 0.90
    public static let rideWidth = 0.48
    public static let rideWander = 0.08

    /// Along a coupe: the stools 0.9 m apart down its middle, and the floor's
    /// three places 1.35 m apart, in rows 0.40 m either side of the stools.
    public static let stoolX: [Double] = [-1.8, -0.9, 0, 0.9, 1.8]
    public static let floorX: [Double] = [-1.35, 0, 1.35]
    public static let rowFrom = 0.40

    /// How far a plant stands off its place, either way, from the seed.
    /// `Planting.nudge`.
    public static let nudgeReach = 0.06

    /// **How wide a stool is**: a low boss of old wood 0.35 to 0.45 m across
    /// and about 0.10 m high, the width from the seed. At its widest it still
    /// leaves the nearest floor plant 0.05 m clear at the worst nudge of both.
    /// A fern on a stool stands on its cut face.
    public static let stoolAcross = 0.35...0.45
    public static let stoolHeight = 0.10

    /// **A row fills from its middle outward**: stools in the order 2, 1, 3,
    /// 0, 4 and floor places 1, 0, 2. A coupe holding three plants then reads
    /// as a clump, where filling from one end would make it a line. Which place
    /// a plant takes along its row changes no count, so none of this needed
    /// simulating.
    public static let stoolOrder = [2, 1, 3, 0, 4]
    public static let floorOrder = [1, 0, 2]

    // MARK: Which row

    /// **The median of the area's own stars.** The 1,035 stars of the design's
    /// sample (`tools/coppice/sample.json`) stand at a median of 1.001 m, set
    /// at 1.00, and it divides the 1,049 of the fresh sample 49.0% to the back.
    /// A borrowed cut would divide them unevenly: the Orchard's 1.20 puts 28%
    /// at the back, the Long Walk's 0.77 puts 75%. It was 1.10 until the
    /// plants' shapes changed on 24 September 2026, measured the same way.
    public static let backFrom = 1.00

    /// Where a plant stands in a coupe: on a stool, or in one of the floor's
    /// two rows. **The back row is `z−` of the stools**, further from the eye
    /// before a turn, as the Cold Frame's back rank is.
    public enum Place: Int, Codable, CaseIterable, Sendable {
        case stool = 0, back, front
    }

    /// The floor row a plant's height asks for.
    public static func row(height: Double) -> Place {
        height < backFrom ? .front : .back
    }

    /// **The one question the rule asks of a habit: is this a fern.** A plant
    /// whose habit was never sent is not, and stands in the light as a star
    /// does.
    public static func isFern(_ traits: PlantTraits) -> Bool {
        traits.habit == Archetype.fern.rawValue
    }

    // MARK: Slots

    /// One place in one plot: which coupe, which row of it, and where along
    /// the row, 0 at the `x−` end.
    public struct Slot: Codable, Equatable, Hashable, Sendable {
        public var coupe: Int
        public var place: Place
        public var index: Int

        public init(coupe: Int, place: Place, index: Int) {
            self.coupe = coupe
            self.place = place
            self.index = index
        }

        /// Where the place is, in metres from the middle of its plot.
        public var spot: Spot {
            let z = Coppice.coupeZ[coupe]
            switch place {
            case .stool: return Spot(x: Coppice.stoolX[index], z: z)
            case .back:  return Spot(x: Coppice.floorX[index], z: z - Coppice.rowFrom)
            case .front: return Spot(x: Coppice.floorX[index], z: z + Coppice.rowFrom)
            }
        }
    }

    /// Every place in a plot, coupe by coupe: the stools, then the back row,
    /// then the front, each from `x−`.
    public static let slots: [Slot] = (0..<coupes).flatMap { coupe in
        (0..<stools).map { Slot(coupe: coupe, place: .stool, index: $0) }
            + (0..<floorRow).map { Slot(coupe: coupe, place: .back, index: $0) }
            + (0..<floorRow).map { Slot(coupe: coupe, place: .front, index: $0) }
    }

    // MARK: The rotation

    /// Where a coupe stands in its rotation.
    ///
    /// Only a fern on a stool is drawn by it. A star, and a fern standing on
    /// the floor, is drawn at its best every year, as a plant is everywhere
    /// else in the garden.
    public enum Stage: Int, Codable, CaseIterable, Sendable {
        case cut = 0, regrowing, grown
    }

    /// **A coupe's stage is arithmetic on its place in the wood and the year**:
    /// `(year − (3 × plot + coupe)) mod 3`. The coupes are cut in sequence
    /// along the wood, so the stepped profile — stumps beside half-grown beside
    /// grown — runs unbroken from the last coupe of one plot into the first of
    /// the next, and in every year a third of the stools are at each stage.
    public static func stage(plot: Int, coupe: Int, year: Int) -> Stage {
        let n = (year - (coupes * plot + coupe)) % coupes
        return Stage(rawValue: n < 0 ? n + coupes : n)!
    }

    /// **The year the Coppice opened in**, counted from 21 December 2025, so
    /// that year 0 runs up to 21 December 2026 and in it the first coupe of
    /// plot 0 is the one standing cut.
    public static let openedIn = 2026

    /// **Which year of the rotation a day falls in**: how many winter
    /// solstices, taken as 21 December UTC, have passed since the Coppice
    /// opened. Marcus's answer on 24 September: the wood turns once a year,
    /// when the year does.
    ///
    /// Asked of a calendar date rather than a clock, so the service, the tests
    /// and the page cannot disagree about a leap second or a time zone. The
    /// service asks it of today in UTC and sends the answer with the plantings.
    public static func year(utcYear: Int, month: Int, day: Int) -> Int {
        let turned = month == 12 && day >= 21
        return utcYear - openedIn + (turned ? 1 : 0)
    }

    /// **How a fern on a stool is drawn in the year its coupe is cut**: new
    /// shoots with their leaves not yet open, and no bud. The Cold Frame's
    /// young state without its bud, so the two are the same kind of thing: a
    /// stage assembled for drawing, never stored and never read by the rule.
    /// Draws the area's ferns between 0.08 and 0.38 m, so the shortest star,
    /// 0.43 m, stands over every cut fern.
    public static let cutDrawn: GrowthModel.State = {
        var state = ColdFrame.drawn
        state.heightScale = 0.30
        state.leafUnfurl = 0.6
        state.budSwell = 0
        return state
    }()

    /// **How a fern on a stool is drawn in the year after**: most of its
    /// height, its leaves nearly open, in bud. 0.15 to 0.65 m, median 0.35.
    public static let regrowingDrawn: GrowthModel.State = {
        var state = ColdFrame.drawn
        state.stageProgress = 0.8
        state.overall = 0.65
        state.heightScale = 0.65
        state.leafUnfurl = 0.9
        state.budSwell = 0.4
        return state
    }()

    /// The state a planting is drawn at in a given year, or nil for *at its
    /// best* — `Maturity.bloomPreview`, as everywhere else. Only a fern on a
    /// stool is ever drawn young.
    public static func drawn(_ planting: Planting, year: Int) -> GrowthModel.State? {
        guard planting.slot.place == .stool else { return nil }
        switch stage(plot: planting.plot, coupe: planting.slot.coupe, year: year) {
        case .cut: return cutDrawn
        case .regrowing: return regrowingDrawn
        case .grown: return nil
        }
    }

    // MARK: Planting

    /// One plant in the Coppice, placed for good.
    public struct Planting: Codable, Equatable, Sendable {
        public var seed: String
        public var plot: Int
        public var slot: Slot
        /// The plant's traits, **its habit among them**: the one this area
        /// reads first and no other reads at all.
        public var traits: PlantTraits
        /// A small offset from the place, from the seed: 0.06 m either way.
        /// The nearest two places are 0.40 m apart, and a wood is planted by
        /// eye.
        public var nudge: Spot

        public var spot: Spot {
            Spot(x: slot.spot.x + nudge.x, z: slot.spot.z + nudge.z)
        }
    }

    /// The whole area: every planting, in the order they arrived. Append-only,
    /// as the other eight are.
    public struct Ways: Codable, Equatable, Sendable {
        public private(set) var plantings: [Planting] = []

        public init() {}

        /// **The Coppice as it opened**: the renewal ambassador and nothing
        /// else. Since the re-roll of 28 September 2026 that is *Drosula
        /// vulgaris*, a fern, on the first coupe's middle stool; until then it
        /// was *Rosea caerulea*, a star, in the front row of the first coupe.
        public static func opened() -> Ways {
            var ways = Ways()
            let one = Ambassadors.of(.renewal)
            ways.plant(seed: one.seed, traits: LongWalk.traits(of: one.genome))
            return ways
        }

        public var plots: Int { (plantings.map(\.plot).max() ?? -1) + 1 }

        public func plot(_ index: Int) -> [Planting] {
            plantings.filter { $0.plot == index }
        }

        /// Where the next plant with these traits would go, without planting
        /// it.
        ///
        /// **A fern:**
        ///
        /// 1. A free stool in the oldest plot that has one, in whichever of
        ///    that plot's coupes holds fewest ferns on stools. A tie goes to
        ///    the lowest coupe.
        /// 2. Failing that, the floor, by a star's rule below, **but no more
        ///    than one fern to a coupe's floor**. A fern on the floor is not
        ///    cut, as a fern on a woodland floor is not.
        /// 3. Failing that, a new plot, on the middle stool of its first coupe.
        ///
        /// **A star:**
        ///
        /// 1. Its own row of the floor — the back from 1.00 m up, the front
        ///    below — oldest plot first, and within a plot the coupe with
        ///    fewest on its floor.
        /// 2. Failing that, the other row on the same terms, but only if
        ///    nothing would stand out of order: nothing in a coupe's front row
        ///    taller than anything in its back row.
        /// 3. Failing that, a new plot, in its own row of the first coupe.
        ///
        /// **The Crossing's loops**, row outside, plot inside, the emptiest
        /// coupe within the plot, with coupes standing in for quarters. That
        /// keeps a plot's three coupes level, so each stage of the rotation
        /// has plants from a plot's first few arrivals — which matters more
        /// here than anywhere, because one coupe is always in its cut year.
        ///
        /// **The cap of one fern to a floor was found by simulating, not
        /// guessed.** Stools are 45% of the places and ferns 48% of the
        /// arrivals, so some ferns must stand on the floor. With none allowed
        /// the floor fell behind for good; with no limit a long run of ferns
        /// took the floor from the stars, and the plots the stars opened
        /// afterwards had stools no fern came to.
        public func place(for traits: PlantTraits) -> (plot: Int, slot: Slot) {
            let opened = plots
            let byPlot = (0..<opened).map { self.plot($0) }

            if Coppice.isFern(traits) {
                for plot in 0..<opened {
                    var best: (coupe: Int, taken: Int)?
                    for coupe in 0..<Coppice.coupes {
                        let taken = byPlot[plot].filter { $0.slot.coupe == coupe && $0.slot.place == .stool }.count
                        if taken < Coppice.stools, taken < (best?.taken ?? Int.max) {
                            best = (coupe, taken)
                        }
                    }
                    if let best {
                        return (plot, Slot(coupe: best.coupe, place: .stool,
                                           index: Coppice.stoolOrder[best.taken]))
                    }
                }
                let room = { (floor: [Planting]) in
                    floor.filter { Coppice.isFern($0.traits) }.count < 1
                }
                if let found = floor(for: traits, in: byPlot, where: room) { return found }
                return (opened, Slot(coupe: 0, place: .stool, index: Coppice.stoolOrder[0]))
            }

            if let found = floor(for: traits, in: byPlot, where: { _ in true }) { return found }
            return (opened, Slot(coupe: 0, place: Coppice.row(height: traits.height),
                                 index: Coppice.floorOrder[0]))
        }

        /// A place on the floor: the plant's own row, then the other, each
        /// across every open plot oldest first, and within a plot the coupe
        /// with fewest on its floor that has room in the row, keeps the rows
        /// in order, and passes `room`.
        func floor(for traits: PlantTraits, in byPlot: [[Planting]],
                   where room: ([Planting]) -> Bool) -> (plot: Int, slot: Slot)? {
            let own = Coppice.row(height: traits.height)
            for row in [own, own == .back ? Place.front : .back] {
                for plot in byPlot.indices {
                    var best: (coupe: Int, taken: Int, onFloor: Int)?
                    for coupe in 0..<Coppice.coupes {
                        let floor = byPlot[plot].filter { $0.slot.coupe == coupe && $0.slot.place != .stool }
                        let taken = floor.filter { $0.slot.place == row }.count
                        guard taken < Coppice.floorRow, inOrder(traits.height, in: row, among: floor),
                              room(floor), floor.count < (best?.onFloor ?? Int.max) else { continue }
                        best = (coupe, taken, floor.count)
                    }
                    if let best {
                        return (plot, Slot(coupe: best.coupe, place: row,
                                           index: Coppice.floorOrder[best.taken]))
                    }
                }
            }
            return nil
        }

        /// Whether a plant this tall can stand in this row of a coupe's floor:
        /// nothing in the front row taller than anything in the back. The Cold
        /// Frame's `inOrder`, asked of a floor. The stools are not in it: a
        /// fern on a stool is drawn at its coupe's stage, so its height is the
        /// year's before it is the plant's.
        func inOrder(_ height: Double, in row: Place, among floor: [Planting]) -> Bool {
            for other in floor where other.slot.place != row {
                if row == .back, height < other.traits.height { return false }
                if row == .front, height > other.traits.height { return false }
            }
            return true
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
                                    nudge: Spot(x: jitter(26, Coppice.nudgeReach),
                                                z: jitter(27, Coppice.nudgeReach)))
            plantings.append(planting)
            return planting
        }
    }

    /// **The first plant in the Coppice**, and the one it is drawn with
    /// before anybody has released anything into it: `Ambassadors.of(.renewal)`
    /// placed by this rule into an empty area. A fern, so it opens plot 0 on
    /// coupe 0's middle stool — the coupe cut in year 0, so it is drawn cut
    /// until 21 December 2026. (A star under 1.00 m until the re-roll of 28
    /// September 2026, in the front row.) Derived rather than stored, as the
    /// other eight are.
    public static let ambassador: Planting = Ways.opened().plantings[0]
}

/// The Coppice's reading of a plant: whether it stands on a stool, and which
/// row of the floor its height asks for.
extension PlantTraits {
    public var isFern: Bool { Coppice.isFern(self) }
    public var coppiceRow: Coppice.Place { Coppice.row(height: height) }
}
