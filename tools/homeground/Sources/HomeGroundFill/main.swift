import Foundation
import SeedCore

// The Home Ground's fill, simulated. docs/WEB-GARDENS.md §"The Home Ground,
// chosen" and §"The fill, simulated" are the record of what this printed.
//
// Four streams: 2,000 plants the cuts are measured on, a fresh 500 and a fresh
// 2,000 they were not, and 500 from a village of gardeners who meet unevenly.
// Every stream is placed after the ground's ambassador, as the service places
// every real arrival.

func centile(_ xs: [Double], _ p: Double) -> Double {
    let s = xs.sorted()
    guard !s.isEmpty else { return .nan }
    let i = p * Double(s.count - 1)
    let lo = Int(i.rounded(.down)), hi = min(lo + 1, s.count - 1)
    return s[lo] + (s[hi] - s[lo]) * (i - Double(lo))
}

func f(_ x: Double, _ d: Int = 2) -> String { String(format: "%.\(d)f", x) }
func pc(_ x: Double) -> String { String(format: "%.0f%%", x * 100) }

// MARK: - The plants

let fit = Cache.load("fit-2000") { Stream.strangers(2000, label: "fit") }
let fresh = Cache.load("fresh-2000") { Stream.strangers(2000, label: "arrival") }
let village = Cache.load("village-500") { Stream.gardeners(500, village: 60, label: "village") }
let ambassador = Stream.ambassador

print("THE PLANTS")
print("  \(fit.plants.count) Home Ground plants from \(fit.crossings) crossings: \(pc(Double(fit.plants.count) / Double(fit.crossings))) of all")
print("  crop      share   height: min  25%  50%  75%  max   across: 50%  75%  90%  max")
for crop in Crop.allCases {
    let these = fit.plants.filter { $0.head == crop.rawValue }
    let h = these.map(\.height), w = these.map(\.wide)
    print("  \(crop.rawValue.padding(toLength: 4, withPad: " ", startingAt: 0)) \(Set(these.map(\.archetype)).joined().padding(toLength: 9, withPad: " ", startingAt: 0)) \(pc(Double(these.count) / Double(fit.plants.count)))    ",
          "  \(f(h.min()!)) \(f(centile(h, 0.25))) \(f(centile(h, 0.5))) \(f(centile(h, 0.75))) \(f(h.max()!))",
          "        \(f(centile(w, 0.5))) \(f(centile(w, 0.75))) \(f(centile(w, 0.9))) \(f(w.max()!))")
}
for (name, s) in [("fresh", fresh.plants), ("village", village.plants)] {
    let shares = Crop.allCases.map { c in pc(Double(s.filter { $0.head == c.rawValue }.count) / Double(s.count)) }
    print("  \(name) \(s.count) (\(name == "fresh" ? fresh.crossings : village.crossings) crossings): shares \(shares.joined(separator: " "))")
}
print("  ambassador: \(Ambassadors.of(.ground).genome.name.full), \(ambassador.head) \(ambassador.archetype), \(f(ambassador.height, 3)) m tall, \(f(ambassador.wide, 3)) m across")

// MARK: - The cuts, measured on the fit sample only

var medians: [Crop: Double] = [:], terciles: [Crop: (Double, Double)] = [:]
for crop in Crop.allCases {
    let h = fit.plants.filter { $0.head == crop.rawValue }.map(\.height)
    medians[crop] = (centile(h, 0.5) * 1000).rounded() / 1000
    terciles[crop] = ((centile(h, 1.0 / 3) * 1000).rounded() / 1000, (centile(h, 2.0 / 3) * 1000).rounded() / 1000)
}
print("\nTHE CUTS (fit sample)")
for crop in Crop.allCases {
    print("  \(crop.rawValue): median \(f(medians[crop]!, 3)); terciles \(f(terciles[crop]!.0, 3)) \(f(terciles[crop]!.1, 3))")
}

// How close any fresh plant stands to its crop's cut: the margin a height
// computed by two different libms has to stay clear of.
var nearest = Double.infinity
for p in fresh.plants + village.plants {
    nearest = min(nearest, abs(p.height - medians[Crop(rawValue: p.head)!]!))
}
print("  nearest arrival to its cut, fresh and village: \(String(format: "%.5f", nearest)) m")

// The cuts as built: the umbel's moved off 0.932, where a village arrival
// stood 0.009 mm from it, to 0.930 (docs/WEB-GARDENS.md §"Decided", 7).
var decided = medians
decided[.fen] = 0.930
var clearest = Double.infinity
for p in fit.plants + fresh.plants + village.plants {
    clearest = min(clearest, abs(p.height - decided[Crop(rawValue: p.head)!]!))
}
print("  as built: \(Crop.allCases.map { "\($0.rawValue) \(f(decided[$0]!, 3))" }.joined(separator: ", ")); nearest plant in any sample \(String(format: "%.5f", clearest)) m")

// MARK: - The spacing

print("\nTHE SPACING (fit sample): how often a plant is wider than the gap to its neighbour")
let gaps: [Crop: (across: Double, along: Double)] = [.cer: (0.40, 0.45), .fen: (0.60, 0.60), .pell: (0.38, 0.40)]
for crop in Crop.allCases {
    let w = fit.plants.filter { $0.head == crop.rawValue }.map(\.wide)
    let g = gaps[crop]!
    let wider = Double(w.filter { $0 > g.across }.count) / Double(w.count)
    // The outermost plant of a row stands this far from the bed's middle.
    let outer: Double = Double(crop.sown.across - 1) / 2 * g.across
    let reaching = w.filter { (x: Double) -> Bool in x / 2 + outer > 0.8 }
    let overBed = Double(reaching.count) / Double(w.count)
    print("  \(crop.rawValue): \(crop.sown.across) across at \(f(g.across)) m, \(crop.sown.rows) rows at \(f(g.along)) m = \(crop.sown.across * crop.sown.rows) a bed; ",
          "\(pc(wider)) wider than the gap across; \(pc(overBed)) reach more than 0.2 m into the path")
}

// The alternative: one spacing for every bed, three across at 0.40 m and
// eight rows at 0.51 m, twenty-four a bed.
for crop in Crop.allCases {
    let w = fit.plants.filter { $0.head == crop.rawValue }.map(\.wide)
    let wider = Double(w.filter { $0 > 0.40 }.count) / Double(w.count)
    let under = Double(w.filter { $0 < 0.20 }.count) / Double(w.count)
    print("  \(crop.rawValue) at one spacing (3 across at 0.40 m, 24 a bed): \(pc(wider)) wider than the gap, \(pc(under)) less than half as wide as it")
}

// MARK: - The rules

let rules: [Rule] = [
    Rule(name: "A  fixed beds, one spacing, arrival order", claim: .fixed, spacing: .uniform(across: 3, rows: 8), fill: .oneEnded),
    Rule(name: "B  fixed beds, one spacing, two ends", claim: .fixed, spacing: .uniform(across: 3, rows: 8), fill: .twoEnded(decided)),
    Rule(name: "C' claimed beds, one spacing, two ends", claim: .claimed, spacing: .uniform(across: 3, rows: 8), fill: .twoEnded(decided)),
    Rule(name: "C  claimed beds, crop's spacing, arrival order", claim: .claimed, spacing: .byCrop, fill: .oneEnded),
    Rule(name: "D  claimed beds, crop's spacing, two ends", claim: .claimed, spacing: .byCrop, fill: .twoEnded(decided)),
    Rule(name: "E  claimed beds, crop's spacing, three bands", claim: .claimed, spacing: .byCrop, fill: .banded(terciles)),
]

struct Result {
    var plots = 0, plants = 0, places = 0, sown = 0, full = 0
    var inOrder = 0.0
    var bedsByCrop: [Crop: Int] = [:]
    var biggest = 0, allThree = 0, turnedAway = 0
    var ownBand = 0.0
    var meeting: [Double] = []
    var fullPlots = 0, halvesApart = 0, twoEndedBeds = 0
}

func run(_ rule: Rule, _ stream: [Plant]) -> Result {
    let garden = Garden(rule: rule)
    garden.plant(ambassador)
    for p in stream { garden.plant(p) }
    var r = Result()
    r.plots = garden.plots.count
    r.turnedAway = garden.turnedAway
    var pairs = 0, ordered = 0
    for plot in garden.plots {
        var here = 0
        let beds = plot.beds.compactMap { $0 }
        if Set(beds.compactMap(\.crop)).count == 3 { r.allThree += 1 }
        for slot in plot.beds {
            guard let bed = slot else {
                // An unsown bed in a fixed plan is part of the plan and is empty.
                if rule.claim == .fixed, case let .uniform(a, rows) = rule.spacing { r.places += a * rows }
                continue
            }
            r.sown += 1
            r.places += bed.capacity
            r.plants += bed.plants.count
            here += bed.plants.count
            if bed.isFull { r.full += 1 }
            r.bedsByCrop[bed.crop!, default: 0] += 1
            // Every pair standing in different rows: is the north one at least
            // as tall? Half would be, by chance.
            for a in bed.plants {
                for b in bed.plants where bed.row(of: a.place) < bed.row(of: b.place) {
                    pairs += 1
                    if a.plant.height >= b.plant.height { ordered += 1 }
                }
            }
            if case .banded(let cuts) = rule.fill {
                let (low, high) = cuts[bed.crop!]!
                for p in bed.plants {
                    let own = p.plant.height >= high ? 0 : p.plant.height >= low ? 1 : 2
                    if garden.bandOf(p.place, bed) == own { r.ownBand += 1 }
                }
            }
            if case .twoEnded(let cuts) = rule.fill {
                if bed.isFull { r.meeting.append(Double(bed.north) / Double(bed.capacity)) }
                // Everything that came in from the north end is at least as
                // tall as everything that came in from the south.
                // Read off where they stand, not off the cut that sent them:
                // the north end's places are 0..<north.
                _ = cuts
                let north = bed.plants.filter { $0.place < bed.north }.map(\.plant.height)
                let south = bed.plants.filter { $0.place >= bed.north }.map(\.plant.height)
                r.twoEndedBeds += 1
                if (north.min() ?? .infinity) >= (south.max() ?? -.infinity) { r.halvesApart += 1 }
            }
        }
        r.biggest = max(r.biggest, here)
        if plot.beds.allSatisfy({ $0?.isFull == true }) { r.fullPlots += 1 }
    }
    r.inOrder = pairs > 0 ? Double(ordered) / Double(pairs) : 1
    r.ownBand /= Double(r.plants)
    return r
}

for (name, stream) in [("FIT 2,000 (the sample the cuts were measured on)", fit.plants),
                       ("FRESH 500", Array(fresh.plants.prefix(500))),
                       ("FRESH 2,000", fresh.plants),
                       ("VILLAGE 500 (60 gardeners meeting unevenly)", village.plants)] {
    print("\n\(name), after the ambassador")
    print("  rule                                            plots  full  held   beds sown/full  cer/fen/pell  all-three  largest  pairs in order")
    for rule in rules {
        let r = run(rule, stream)
        let crops = Crop.allCases.map { "\(r.bedsByCrop[$0] ?? 0)" }.joined(separator: "/")
        var line = "  \(rule.name.padding(toLength: 47, withPad: " ", startingAt: 0))  \(String(r.plots).padding(toLength: 5, withPad: " ", startingAt: 0))  \(String(r.fullPlots).padding(toLength: 4, withPad: " ", startingAt: 0))  \(pc(Double(r.plants) / Double(r.places)).padding(toLength: 5, withPad: " ", startingAt: 0))  \(String(r.sown).padding(toLength: 3, withPad: " ", startingAt: 0)) / \(String(r.full).padding(toLength: 8, withPad: " ", startingAt: 0))  \(crops.padding(toLength: 12, withPad: " ", startingAt: 0))  \(String(r.allThree).padding(toLength: 9, withPad: " ", startingAt: 0))  \(String(r.biggest).padding(toLength: 7, withPad: " ", startingAt: 0))  \(pc(r.inOrder))"
        if case .banded = rule.fill { line += ", \(pc(r.ownBand)) in own band" }
        if !r.meeting.isEmpty {
            line += ", tall share of a full bed \(f(r.meeting.min()!)) to \(f(r.meeting.max()!))"
        }
        if r.twoEndedBeds > 0 { line += ", halves apart in \(r.halvesApart) of \(r.twoEndedBeds) beds" }
        if r.turnedAway > 0 { line += ", \(r.turnedAway) turned away" }
        print(line)
    }
}
