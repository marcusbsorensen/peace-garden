#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// The Glasshouse: a span house of painted bars and glass, pots on slatted
/// staging along its sunny side and a soil border along the back.
/// `docs/WEB-GARDENS.md` §*The Glasshouse, built*.
///
/// **The eighth area, and the first that sorts by hue.** The Knot Garden and
/// the Cold Frame claim a place by a colour *family*, one of seven; this one
/// stands its pots in a run of colour along the staging, blue-green at the door
/// end through blue, violet, magenta, red and orange to yellow at the far one.
/// Seven families are too coarse to order twelve places by, so a plant's hue
/// travels with it as a trait of its own (`PlantTraits.hue`).
///
/// **Staging and a border**, because `light` plants are the tallest in the
/// garden: 0.44 to 1.88 m over four thousand crossings, median 1.03 m, and
/// none under half a metre. On staging at bench height the tallest would stand
/// 2.7 m, so the tallest quarter go in a soil border along the back instead,
/// where they cannot shade the pots. That is how a glasshouse grows its
/// tomatoes.
///
/// **Three answers from Marcus, on 23 September, and a simulation between
/// them.** Thirty-two a plot, twenty-four pots and a border of eight; a spectrum
/// of colour along the staging; and, once the fill had been simulated, the
/// border planted in order of arrival from the door. The spectrum belongs to
/// the staging alone.
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
    /// way round. Declared but not yet read: the area's new layout reads it.
    public static let variants = PlotVariant.Space.fixed

    /// Twelve positions along the staging with two pots at each, and a border
    /// of eight: thirty-two a plot, Marcus's choice on 23 September.
    public static let positions = 12
    public static let rows = 2
    public static let borderPlaces = 8

    /// The house's outside, in metres: its length along `x`, its width across
    /// `z`, and how high its eaves and its ridge stand.
    ///
    /// **Set by the plants under the roof, not by the look of the house.** A
    /// pot on the staging held a plant of up to 1.30 m — anything taller went
    /// in the border — and stood it 0.83 m off the floor, so the glass over
    /// the staging had to clear 2.13 m. With the eaves at 2.1 and the ridge at
    /// 2.9 it cleared the tallest in the test sample by a fifth of a metre.
    /// Since the plants' shapes changed on 24 September 2026 the border takes
    /// everything from 1.14 m, the glass over a pot need clear only 1.97 m,
    /// and the nearest plant stands 0.39 m under the roof; the house was left
    /// as built, with more air over the pots rather than less. The roof
    /// pitches at 25°, which is what a glasshouse is built to, steep
    /// enough to shed rain and shallow enough to take the winter sun.
    /// `GlasshouseTests` holds every plant under it.
    public static let houseLength = 4.4
    public static let houseWidth = 3.4
    public static let eaves = 2.1
    public static let ridge = 2.9

    /// The staging: slatted, at the height a gardener works at, running the
    /// length of the house on the sunny side (`z+`) — the sun in this garden
    /// stands at `z+`, and staging is always put where the light is.
    ///
    /// Its middle stands 1.0 m from the house's, so a hand's breadth under
    /// half a metre of air is left between the staging and the side glass for
    /// the plants to lean into, and a path 1.5 m wide runs between it and the
    /// border.
    public static let stagingZ = 1.0
    public static let stagingDepth = 0.62
    public static let stagingTop = 0.70

    /// Along the staging, between one position and the next; and how far
    /// either row of pots stands from the staging's middle. Twelve positions
    /// at 0.33 m run 3.6 m, most of the house's length.
    public static let alongGap = 0.33
    public static let rowFrom = 0.15

    /// How high the soil in a pot stands above the staging it sits on, and so
    /// how far a potted plant stands off the floor: `stagingTop` and this.
    public static let potSoil = 0.13

    /// The border: a strip of soil along the back (`z−`), where the tallest
    /// plants stand on the ground and shade nothing but the path. Eight
    /// places 0.5 m apart, which is what a tomato or a vine is given.
    public static let borderZ = -1.15
    public static let borderGap = 0.50

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
    /// two ends are the colours flowers are least often.
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

    /// The band a hue belongs to, 0 at the door end of the staging to 11 at
    /// the far end: how many edges it lies at or past.
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
    /// On the staging, `index` is the position along it — which is the band,
    /// for a pot standing in its own — and `row` is which of the two pots at
    /// that position: 0 by the side glass, 1 by the path. In the border,
    /// `index` is the place counted from the door and `row` is always 0.
    public struct Slot: Codable, Equatable, Hashable, Sendable {
        public var bed: Bed
        public var index: Int
        public var row: Int

        public init(bed: Bed, index: Int, row: Int = 0) {
            self.bed = bed
            self.index = index
            self.row = row
        }

        /// Where the place is, in metres from the middle of its plot. **Index
        /// 0 is at the door**, which is the house's `x−` end, in both beds.
        public var spot: Spot {
            switch bed {
            case .staging:
                return Spot(x: (Double(index) - Double(Glasshouse.positions - 1) / 2) * Glasshouse.alongGap,
                            z: Glasshouse.stagingZ + (row == 0 ? Glasshouse.rowFrom : -Glasshouse.rowFrom))
            case .border:
                return Spot(x: (Double(index) - Double(Glasshouse.borderPlaces - 1) / 2) * Glasshouse.borderGap,
                            z: Glasshouse.borderZ)
            }
        }

        /// How far off the floor a plant in this place stands: the soil in a
        /// pot on the staging, or the border's own soil, which is the floor.
        public var lift: Double {
            bed == .staging ? Glasshouse.stagingTop + Glasshouse.potSoil : 0
        }
    }

    /// Every place in a plot: the staging position by position, the glass row
    /// before the path row at each, then the border from the door.
    public static let slots: [Slot] =
        (0..<positions).flatMap { p in (0..<rows).map { Slot(bed: .staging, index: p, row: $0) } }
        + (0..<borderPlaces).map { Slot(bed: .border, index: $0) }

    /// How high the underside of the roof stands, `z` metres from the ridge
    /// line: the eaves at either side and the ridge in the middle, straight
    /// between. Asked of the plants by `GlasshouseTests`, and of `Organic` by
    /// the drawing, so the two measure one roof.
    public static func roof(atDepth z: Double) -> Double {
        let t = min(1, abs(z) / (houseWidth / 2))
        return ridge - (ridge - eaves) * t
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

        public var spot: Spot {
            Spot(x: slot.spot.x + nudge.x, z: slot.spot.z + nudge.z)
        }
    }

    /// The whole area: every planting, in the order they arrived. Append-only,
    /// as the other seven are.
    public struct Ways: Codable, Equatable, Sendable {
        public private(set) var plantings: [Planting] = []

        public init() {}

        /// **The Glasshouse as it opened**: the light ambassador and nothing
        /// else. Since the re-roll of 28 September 2026 that is *Elora
        /// elata*, a star of 1.45 m, in the border's first place from the
        /// door; until then it was *Aurea pallida* in a pot at its own place
        /// in the spectrum.
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
        /// A plant of 1.14 m or more goes in the border: the next place from
        /// the door in the oldest plot that has one, and failing that a new
        /// plot. Nothing about its colour is asked.
        ///
        /// A plant under that goes on the staging, in order:
        ///
        /// 1. **Its own band**, in every open plot, oldest first.
        /// 2. **One band off**, in every open plot, oldest first — the
        ///    neighbour its hue is nearer before the other one, and never
        ///    across the cut, where the two ends of the bench are the two ends
        ///    of the spectrum rather than neighbours.
        /// 3. A new plot, at its own band.
        ///
        /// A pale plant, or one whose hue was never sent, takes the first free
        /// pot in the oldest plot, counting from the door, and opens a new plot
        /// at the door end if there is none.
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
                    for position in 0..<Glasshouse.positions {
                        if let slot = free(position, in: plot) { return (plot, slot) }
                    }
                }
                return (opened, Slot(bed: .staging, index: 0))
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
