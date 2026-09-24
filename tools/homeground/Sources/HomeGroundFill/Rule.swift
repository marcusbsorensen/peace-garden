/// The candidate rules, written as plainly as they can be so that the numbers
/// are about the rules and not about the code.
///
/// **A plot is three beds side by side**, each 1.2 m wide and running the
/// length of the plot, with rows across it. A bed's places are numbered in
/// reading order from its north end — row by row, west to east along a row —
/// so place 0 is the north-west corner and the last place the south-east one.
/// North is −z: the end the midday sun is behind, and the far end in the view
/// the page opens on.

/// The three crops of the Home Ground, which are its three genus roots.
enum Crop: String, CaseIterable {
    case cer = "Cer"    // spire: the grain
    case fen = "Fen"    // umbel: the fennel's family
    case pell = "Pell"  // succulent: the rosettes

    /// How a bed of this crop is set out when the crop decides the spacing:
    /// plants across a row, and rows down the bed.
    var sown: (across: Int, rows: Int) {
        switch self {
        case .cer: return (3, 9)    // 0.40 m across, 0.45 m between rows
        case .fen: return (2, 7)    // 0.60 m across, 0.60 m between rows
        case .pell: return (4, 13)  // 0.28 m across, 0.30 m between rows
        }
    }
}

struct Placed {
    var plant: Plant
    /// Where in the bed, in reading order from the north end.
    var place: Int
}

final class Bed {
    let crop: Crop?
    let across: Int, rows: Int
    var plants: [Placed] = []
    /// For the two-ended rule: how many have come in from each end.
    var north = 0, south = 0
    var capacity: Int { across * rows }

    init(crop: Crop?, across: Int, rows: Int) {
        self.crop = crop
        self.across = across
        self.rows = rows
    }

    var isFull: Bool { plants.count >= capacity }
    func row(of place: Int) -> Int { place / across }
}

struct Plot {
    var beds: [Bed?] = [nil, nil, nil]
}

/// How a bed is claimed.
enum Claim { case fixed, claimed }
/// How a claimed bed is spaced.
enum Spacing { case uniform(across: Int, rows: Int), byCrop }
/// How a bed fills.
enum Fill {
    /// In arrival order from the north end. The Glasshouse border's rule.
    case oneEnded
    /// Tall from the north end, short from the south, meeting wherever the
    /// arrivals put the meeting. The cut is the crop's own median.
    case twoEnded([Crop: Double])
    /// Three bands of rows, north, middle and south, each a third of the bed,
    /// graded by two cuts per crop: the Long Walk's tiers down a bed.
    case banded([Crop: (Double, Double)])
}

struct Rule {
    var name: String
    var claim: Claim
    var spacing: Spacing
    var fill: Fill

    func newBed(_ crop: Crop) -> Bed {
        switch spacing {
        case let .uniform(across, rows): return Bed(crop: crop, across: across, rows: rows)
        case .byCrop: return Bed(crop: crop, across: crop.sown.across, rows: crop.sown.rows)
        }
    }
}

final class Garden {
    let rule: Rule
    var plots: [Plot] = []
    var turnedAway = 0

    init(rule: Rule) { self.rule = rule }

    func plant(_ plant: Plant) {
        let crop = Crop(rawValue: plant.head)!
        switch rule.claim {
        case .fixed:
            let i = Crop.allCases.firstIndex(of: crop)!
            for plot in plots.indices {
                if plots[plot].beds[i] == nil { plots[plot].beds[i] = rule.newBed(crop) }
                if let place = take(plant, in: plots[plot].beds[i]!) { record(plant, place, plots[plot].beds[i]!); return }
            }
        case .claimed:
            // A bed of this crop with a place for it, oldest plot first.
            for plot in plots.indices {
                for case let bed? in plots[plot].beds where bed.crop == crop {
                    if let place = take(plant, in: bed) { record(plant, place, bed); return }
                }
            }
            // Otherwise the first bed nobody has sown, oldest plot first.
            for plot in plots.indices {
                if let i = plots[plot].beds.firstIndex(where: { $0 == nil }) {
                    let bed = rule.newBed(crop)
                    plots[plot].beds[i] = bed
                    if let place = take(plant, in: bed) { record(plant, place, bed); return }
                }
            }
        }
        // A new plot.
        var plot = Plot()
        let i = rule.claim == .fixed ? Crop.allCases.firstIndex(of: crop)! : 0
        let bed = rule.newBed(crop)
        plot.beds[i] = bed
        plots.append(plot)
        guard let place = take(plant, in: bed) else { turnedAway += 1; return }
        record(plant, place, bed)
    }

    private func record(_ plant: Plant, _ place: Int, _ bed: Bed) {
        bed.plants.append(Placed(plant: plant, place: place))
    }

    /// The place this plant would take in this bed, and the bed's counters
    /// moved on, or nil if the bed has no place it may take.
    private func take(_ plant: Plant, in bed: Bed) -> Int? {
        guard !bed.isFull else { return nil }
        switch rule.fill {
        case .oneEnded:
            return bed.plants.count
        case let .twoEnded(cuts):
            if plant.height >= cuts[bed.crop!]! {
                defer { bed.north += 1 }
                return bed.north
            } else {
                defer { bed.south += 1 }
                return bed.capacity - 1 - bed.south
            }
        case let .banded(cuts):
            let (low, high) = cuts[bed.crop!]!
            let own = plant.height >= high ? 0 : plant.height >= low ? 1 : 2
            // Own band first, then the band beside it toward the middle, then
            // the far one — each only if nothing north of the plant would be
            // shorter than it and nothing south of it taller.
            let order = own == 1 ? [1, 0, 2] : own == 0 ? [0, 1, 2] : [2, 1, 0]
            for band in order {
                let places = bandPlaces(band, bed)
                let taken = Set(bed.plants.map(\.place))
                guard let free = places.first(where: { !taken.contains($0) }) else { continue }
                let northOf = bed.plants.filter { bandOf($0.place, bed) < band }.map(\.plant.height)
                let southOf = bed.plants.filter { bandOf($0.place, bed) > band }.map(\.plant.height)
                if (northOf.min() ?? .infinity) >= plant.height && (southOf.max() ?? -.infinity) <= plant.height {
                    return free
                }
            }
            return nil
        }
    }

    func bandOf(_ place: Int, _ bed: Bed) -> Int {
        let row = bed.row(of: place)
        let first = (bed.rows + 1) / 3, second = bed.rows - (bed.rows + 1) / 3
        return row < first ? 0 : row < second ? 1 : 2
    }

    func bandPlaces(_ band: Int, _ bed: Bed) -> [Int] {
        (0..<bed.capacity).filter { bandOf($0, bed) == band }
    }
}
