#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// The Glasshouse: a round house of painted bars and glass, its pots on a ring
/// of slatted staging round the inside, and a round soil bed in the middle.
/// `docs/WEB-GARDENS.md` §*The Glasshouse, built*, and since 2 October 2026
/// the colour wheel, option A of `design/garden-layouts-2026-10-02/RESEARCH.md`.
///
/// **The eighth area, and the first that sorts by hue.** The Knot Garden and
/// the Cold Frame claim a place by a colour *family*, one of seven; this one
/// stands its pots round the staging as a colour wheel, blue-green just past
/// the door through blue, violet, magenta, red and orange to yellow just
/// before it. Seven families are too coarse to order twelve places by, so a
/// plant's hue travels with it as a trait of its own (`PlantTraits.hue`).
///
/// **Staging and a border**, because `light` plants are the tallest in the
/// garden: 0.44 to 1.88 m over four thousand crossings, median 1.03 m, and
/// none under half a metre. On staging at bench height the tallest would stand
/// 2.7 m, so the tallest quarter stand in a soil bed instead — along the back
/// of the span house it was, and in the middle of the round one, under the
/// dome's crown, where the roof is highest.
///
/// **Three answers from Marcus, on 23 September, and a simulation between
/// them.** Thirty-two a plot, twenty-four pots and a border of eight; a spectrum
/// of colour along the staging; and, once the fill had been simulated, the
/// border planted in order of arrival. The spectrum belongs to the staging
/// alone.
///
/// **The colour wheel, 2 October 2026.** The house became round, the spectrum
/// a wheel round its staging, with the door in the gap where the bench's two
/// ends meet — the green these plants avoid — and the pots 0.43 m apart rather
/// than 0.30. The rule's counts, its bands and its order of plots are as
/// built; what changed is where each place stands (`PlaceTable.glasshouseWheel`,
/// made offline by `tools/layouts/tables/glasshouse_wheel.py`), and the order free
/// places are offered in where the rule offers a choice: a pale pot takes the
/// first free pot from the one opposite the door, farthest-first, and the bed
/// fills from its middle. **The plot does not vary** (`variants`): a colour
/// wheel has one way round.
///
/// The rule runs in SeedCore so the plot service, the website and the app read
/// one copy. `Server/.api/Glasshouse.php` is the port, and
/// `tools/reference/check_glasshouse.php` holds them together.
public enum Glasshouse {

    // MARK: The plot

    /// The same square every area uses.
    public static let plotSide = 5.2

    /// **How this area's plots vary**, from each plot's number (`PlotVariant`,
    /// Marcus's decision of 2 October 2026). **Fixed**: a colour wheel has one
    /// way round. Read all the same, so a plot's spot is found as every other
    /// area's is, and is the plain plan on every plot.
    public static let variants = PlotVariant.Space.fixed

    /// Twelve bands round the staging with two pots in each, and a border of
    /// eight: thirty-two a plot, Marcus's choice on 23 September.
    public static let positions = 12
    public static let rows = 2
    public static let borderPlaces = 8

    /// **The places, made offline**: the staging's pots in the order a pale pot
    /// is offered them, then the bed's in the order it fills. Each is tagged
    /// with its slot, `bed`, `index` and `row`.
    public static let table = PlaceTable.glasshouseWheel

    /// The house, in metres: the radius of its wall, and how high its eaves
    /// and the crown of its dome stand.
    ///
    /// **Set by the plants under the roof, and then by the look of the house.**
    /// A pot holds a plant under 1.16 m and stands it 0.83 m off the floor on
    /// the ring of staging, 1.8 m out from the middle, where the dome stands
    /// 2.63 m; the bed's plants, up to 1.9 m, stand within 0.75 m of the
    /// middle, where it stands 3.35 m. `GlasshouseTests` holds every plant
    /// under it with a tenth of a metre to spare. The plants would have done
    /// with less: the crown is 1.3 m over the eaves because a dome that rises
    /// less than that is hidden, from the page's eye, inside the ellipse its
    /// own eaves make, and reads as a drum with a lid; and the eaves are a
    /// quarter of a metre over the door's head, so the doorway reads as a
    /// door and not as a gap in the wall.
    ///
    /// **The wall is laid by hand**: its radius wanders outward from this by up
    /// to 4 cm (`table.curve("house")`), never inward, so the roof over any
    /// place is at least `roof(atRadius:)`. 2.2 m and the 4 cm keep the glass
    /// 0.3 m inside the slab's worn edge.
    public static let houseRadius = 2.2
    public static let eaves = 2.2
    public static let crown = 3.5

    /// **Where the door is**: a turn of the circle from `x+` toward `z+`, so a
    /// quarter is `z+`. The staging's two ends stand either side of it, band 0
    /// round toward `x−` and band 11 toward `x+`, and between them is the
    /// green no flower here is.
    public static let doorTurn = 0.25

    /// The staging: a ring of slats at the height a gardener works at, its
    /// middle 1.8 m from the house's, so a fifth of a metre of air is left
    /// between it and the glass for the plants to lean into, and a walk 0.75 m
    /// wide runs round between it and the bed.
    public static let stagingRadius = 1.80
    public static let stagingDepth = 0.40
    public static let stagingTop = 0.70

    /// From one pot to the next round the ring: 0.43 m, against the span
    /// house's 0.30, which 99% of these plants were wider than (the at-scale
    /// work, item 6).
    public static let potGap = 0.43

    /// How high the soil in a pot stands above the staging it sits on, and so
    /// how far a potted plant stands off the floor: `stagingTop` and this.
    public static let potSoil = 0.13

    /// The round bed in the middle, under the crown: its radius, which wanders
    /// 4 cm either way (`table.curve("bed")`). Eight places 0.45 m apart or
    /// more, which is what a tomato or a vine is given.
    public static let bedRadius = 0.85

    // MARK: Which bed

    /// **The border takes the tallest quarter, measured over this area's own
    /// plants**, as the Cold Frame's cut was: the 75th centile of five hundred
    /// `light` arrivals, drawn under a label the tests do not use, is 1.139 m.
    /// Set at 1.14.
    ///
    /// **It was the Orchard's crown until 24 September 2026**, when the plants'
    /// shapes changed. The 75th centile of these plants was 1.294 m and the
    /// Orchard's crown stood at 1.30, so one number served both, borrowed and
    /// named as borrowed. The new shapes brought these plants down further than
    /// the garden's as a whole — their 75th centile by 0.16 m, the garden's by
    /// 0.09 — and at the Orchard's new 1.20 the border would take 18% of them
    /// rather than a quarter. Two facts that no longer agree are two numbers.
    ///
    /// **1.16 since 29 September 2026**, measured the same way after the
    /// re-roll of the 28th: five hundred `light` arrivals under a label the
    /// tests do not use put the 75th centile at 1.160 m, and two thousand at
    /// 1.157. At 1.14 the tests' own five hundred sent 25.8% to the border.
    public static let borderFrom = 1.16

    /// The two beds a plant can stand in.
    public enum Bed: Int, Codable, CaseIterable, Sendable {
        case staging = 0, border
    }

    public static func bed(height: Double) -> Bed {
        height < borderFrom ? .staging : .border
    }

    // MARK: The spectrum

    /// **Where the circle is cut: 114°**, as a turn. Plants of this area avoid
    /// green — hues from 100° to 140° held two plants in five hundred, because
    /// `flowerHue` steps over the leaves' band unless a rare gene allows it —
    /// so the bench starts just past that gap and ends just before it, and its
    /// two ends are the colours flowers are least often. **The door stands in
    /// that gap** since the house became round: the wheel is cut where the
    /// flowers are not, and that is where you walk in.
    public static let cut = 114.0 / 360.0

    /// How far past the cut a hue lies, going round the circle: 0 at the cut,
    /// just under 1 at the other side of it. The spectrum runs along this.
    ///
    /// Subtraction and one addition, and **nothing else**, so it is the same
    /// double on every host and in the PHP port, and so is every comparison
    /// made with it.
    public static func along(hue: Double) -> Double {
        hue >= cut ? hue - cut : hue - cut + 1
    }

    /// **The eleven edges between twelve bands of equal share**, as turns past
    /// the cut. A twelfth of the plants in each band, not a twelfth of the
    /// circle: hue is not spread evenly, and bands of equal width filled only
    /// 68–82% of the staging, because the crowded ones opened new plots while
    /// the thin ones stood empty.
    ///
    /// **Measured on 2,864 hued `light` plants** — 3,000 of the area's own, out
    /// of 23,259 crossings, less the 136 that are pale — drawn under a label
    /// nothing else uses, so the five hundred the tests and the vector file are
    /// run on were not the ones these were fitted to. Fitted to one sample,
    /// bands flatter it: 98% held on the sample they came from, 87% on a fresh
    /// one. Rounded to a thousandth of a turn, a third of a degree.
    ///
    /// In degrees of hue: 166.6, 190.8, 215.9, 239.8, 265.8, 291.0, 315.7,
    /// 345.4, 15.7, 40.3 and 69.6 — so the first band is blue-green, the
    /// fourth blue, the sixth violet, the eighth magenta, the ninth red, the
    /// tenth orange and the last yellow.
    ///
    /// **No tolerance and no margin test.** A hue is exact on every host
    /// (`PlantTraits.hue`), so a plant cannot fall one side of an edge on a
    /// phone and the other in the service.
    public static let bandEdges: [Double] = [
        0.146, 0.213, 0.283, 0.350, 0.422, 0.492, 0.560, 0.643, 0.727, 0.795, 0.877,
    ]

    /// The band a hue belongs to, 0 just past the door to 11 just before it,
    /// going round the wheel: how many edges it lies at or past.
    public static func band(hue: Double) -> Int {
        let u = along(hue: hue)
        return bandEdges.filter { u >= $0 }.count
    }

    /// Whether a hue lies in the upper half of its band, and so nearer the
    /// band after it than the one before. Asked only when a pot's own band is
    /// full, to say which neighbour to try first.
    static func leansOn(hue: Double) -> Bool {
        let u = along(hue: hue)
        let b = band(hue: hue)
        let low = b == 0 ? 0 : bandEdges[b - 1]
        let high = b == bandEdges.count ? 1 : bandEdges[b]
        return u - low >= high - u
    }

    /// A plant whose colour cannot place it along the spectrum: a pale flower,
    /// whose hue is barely there to see (`LongWalk.paleFamily`, saturation
    /// under 0.22), or one whose hue was never sent. Either takes any free
    /// place on the staging.
    public static func isUnplaced(_ traits: PlantTraits) -> Bool {
        traits.family == LongWalk.paleFamily || traits.hue == nil
    }

    // MARK: Slots

    /// One place in one plot: which bed, and where in it.
    ///
    /// On the staging, `index` is the band the pot stands in — its own, for a
    /// pot standing in its own — and `row` is which of the band's two pots:
    /// 0 for the one the table offers first, 1 for the other. In the border,
    /// `index` is the place's turn in the bed's fill order, from the middle
    /// out, and `row` is always 0.
    public struct Slot: Codable, Equatable, Hashable, Sendable {
        public var bed: Bed
        public var index: Int
        public var row: Int

        public init(bed: Bed, index: Int, row: Int = 0) {
            self.bed = bed
            self.index = index
            self.row = row
        }

        /// Where the place is, in metres from the middle of its plot, as the
        /// table has it (`PlaceTable.glasshouseWheel`).
        public var spot: Spot {
            switch bed {
            case .staging: return Glasshouse.potSpots[index][row]
            case .border: return Glasshouse.bedSpots[index]
            }
        }

        /// How far off the floor a plant in this place stands: the soil in a
        /// pot on the staging, or the bed's own soil, which is the floor.
        public var lift: Double {
            bed == .staging ? Glasshouse.stagingTop + Glasshouse.potSoil : 0
        }
    }

    /// The staging's pots by band and row, and the bed's places in fill order,
    /// read once out of the table.
    static let potSpots: [[Spot]] = {
        var out = [[Spot]](repeating: [Spot](repeating: Spot(x: 0, z: 0), count: rows), count: positions)
        for place in table.places(nudge: 0) where table.tag("bed", of: place) == Bed.staging.rawValue {
            out[table.tag("index", of: place)][table.tag("row", of: place)] = place.spot
        }
        return out
    }()

    static let bedSpots: [Spot] = table.places(nudge: 0)
        .filter { table.tag("bed", of: $0) == Bed.border.rawValue }
        .map(\.spot)

    /// **The order a pot with no place on the spectrum is offered the staging
    /// in**: the pot opposite the door, then each time the pot farthest from
    /// those already offered, so a pale pot or two never bunch at one end of
    /// the wheel. The table's order; a band's row 0 always comes before its
    /// row 1.
    public static let paleOrder: [Slot] = table.places(nudge: 0)
        .filter { table.tag("bed", of: $0) == Bed.staging.rawValue }
        .map { Slot(bed: .staging, index: table.tag("index", of: $0), row: table.tag("row", of: $0)) }

    /// Every place in a plot: the staging band by band, row 0 before row 1 at
    /// each, then the bed in its fill order.
    public static let slots: [Slot] =
        (0..<positions).flatMap { p in (0..<rows).map { Slot(bed: .staging, index: p, row: $0) } }
        + (0..<borderPlaces).map { Slot(bed: .border, index: $0) }

    /// **How high the underside of the dome stands**, `r` metres from the
    /// middle of the house: the eaves at the wall, rising to the crown in the
    /// middle as `1 − (r / R)²` does, so it is steepest at the eaves and
    /// flattens over the bed. Asked of the plants by `GlasshouseTests`, and of
    /// `Organic` by the drawing, so the two measure one roof. The wall stands
    /// at `houseRadius` or a little outside it, and the dome over a wall
    /// further out is higher, so this is the lowest the roof is anywhere.
    public static func roof(atRadius r: Double) -> Double {
        let f = min(1, abs(r) / houseRadius)
        return eaves + (crown - eaves) * (1 - f * f)
    }

    // MARK: Planting

    /// One plant in the Glasshouse, placed for good.
    public struct Planting: Codable, Equatable, Sendable {
        public var seed: String
        public var plot: Int
        public var slot: Slot
        /// The plant's traits, **its hue among them**: the one this area reads
        /// and no other does.
        public var traits: PlantTraits
        /// A small offset from the place, from the seed. 0.015 m either way on
        /// the staging, where a pot is stood in a line with its neighbours and
        /// a pot out of line is a pot knocked; 0.05 m in the border, which is
        /// planted by eye.
        public var nudge: Spot

        /// Where it stands: its place and its nudge, in the table's frame, as
        /// the plot's variant lays them — which in this area is always the
        /// plan as drawn (`variants`). Exact on every host.
        public var spot: Spot {
            PlotVariant.of(plot: plot, area: .light)
                .apply(Spot(x: slot.spot.x + nudge.x, z: slot.spot.z + nudge.z))
        }
    }

    /// The whole area: every planting, in the order they arrived. Append-only,
    /// as the other seven are.
    public struct Ways: Codable, Equatable, Sendable {
        public private(set) var plantings: [Planting] = []

        public init() {}

        /// **The Glasshouse as it opened**: the light ambassador and nothing
        /// else. Since the re-roll of 28 September 2026 that is *Elora
        /// elata*, a star of 1.45 m, in the border's first place — the middle
        /// of the round bed since 2 October 2026, the place from the door
        /// before it; until the re-roll it was *Aurea pallida* in a pot at
        /// its own place in the spectrum.
        public static func opened() -> Ways {
            var ways = Ways()
            let one = Ambassadors.of(.light)
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
        /// **Height picks the bed, and then each bed has its own rule.**
        ///
        /// A plant of 1.16 m or more goes in the border: the next place in the
        /// bed's fill order — the middle, then farthest-first — in the oldest
        /// plot that has one, and failing that a new plot. Nothing about its
        /// colour is asked.
        ///
        /// A plant under that goes on the staging, in order:
        ///
        /// 1. **Its own band**, in every open plot, oldest first.
        /// 2. **One band off**, in every open plot, oldest first — the
        ///    neighbour its hue is nearer before the other one, and never
        ///    across the cut, where the two ends of the bench are the two ends
        ///    of the spectrum rather than neighbours, with the door between
        ///    them.
        /// 3. A new plot, at its own band.
        ///
        /// A pale plant, or one whose hue was never sent, takes the first free
        /// pot in the oldest plot in `paleOrder` — the pot opposite the door,
        /// then farthest-first — and opens a new plot at that pot if there is
        /// none. It was the first free pot from the door until 2 October 2026,
        /// which stood every pale pot in band 0 and band 1 first.
        ///
        /// **Plot outside, band inside**, as the other claimed areas have it,
        /// except that the bands are tried across every plot before the next
        /// one is: a pot one band off in plot 0 matters less than a pot in its
        /// own band in plot 3. That order is what the simulation measured —
        /// 86% of pots in their own band on a fresh sample, and none more than
        /// one place off.
        public func place(for traits: PlantTraits) -> (plot: Int, slot: Slot) {
            let opened = plots
            let byPlot = (0..<opened).map { self.plot($0) }

            if Glasshouse.bed(height: traits.height) == .border {
                for plot in 0..<opened {
                    let taken = byPlot[plot].filter { $0.slot.bed == .border }.count
                    if taken < Glasshouse.borderPlaces {
                        return (plot, Slot(bed: .border, index: taken))
                    }
                }
                return (opened, Slot(bed: .border, index: 0))
            }

            func free(_ position: Int, in plot: Int) -> Slot? {
                let taken = byPlot[plot].filter { $0.slot.bed == .staging && $0.slot.index == position }
                guard taken.count < Glasshouse.rows else { return nil }
                return Slot(bed: .staging, index: position, row: taken.count)
            }

            guard let hue = traits.hue, !Glasshouse.isUnplaced(traits) else {
                for plot in 0..<opened {
                    let taken = Set(byPlot[plot].map(\.slot))
                    if let slot = Glasshouse.paleOrder.first(where: { !taken.contains($0) }) {
                        return (plot, slot)
                    }
                }
                return (opened, Glasshouse.paleOrder[0])
            }

            let own = Glasshouse.band(hue: hue)
            for plot in 0..<opened {
                if let slot = free(own, in: plot) { return (plot, slot) }
            }
            let near = Glasshouse.leansOn(hue: hue) ? [own + 1, own - 1] : [own - 1, own + 1]
            let neighbours = near.filter { (0..<Glasshouse.positions).contains($0) }
            for plot in 0..<opened {
                for position in neighbours {
                    if let slot = free(position, in: plot) { return (plot, slot) }
                }
            }
            return (opened, Slot(bed: .staging, index: own))
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
            let reach = slot.bed == .staging ? 0.015 : 0.05
            let planting = Planting(seed: seed.hex, plot: plot, slot: slot, traits: traits,
                                    nudge: Spot(x: jitter(26, reach), z: jitter(27, reach)))
            plantings.append(planting)
            return planting
        }
    }

    /// **The first plant in the Glasshouse**, and the one it is drawn with
    /// before anybody has released anything into it: `Ambassadors.of(.light)`
    /// placed by this rule into an empty area. Derived rather than stored, as
    /// the other seven are.
    public static let ambassador: Planting = Ways.opened().plantings[0]
}

/// The Glasshouse's reading of a plant: which bed it belongs in, and which
/// band of the staging's spectrum, if its colour has one.
extension PlantTraits {
    public var glasshouseBed: Glasshouse.Bed { Glasshouse.bed(height: height) }

    public var glasshouseBand: Int? {
        guard let hue, !Glasshouse.isUnplaced(self) else { return nil }
        return Glasshouse.band(hue: hue)
    }
}
