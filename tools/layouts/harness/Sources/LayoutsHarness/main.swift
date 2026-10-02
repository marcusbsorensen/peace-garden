import Foundation
import SeedCore

// How each area fills, on SeedCore's own plants.
//
//   swift run -c release --package-path tools/layouts/harness layouts-harness [options]
//
//   --area NAME       only this area (repeatable): `coppice` or `renewal`,
//                     `long-walk` or `travel`, and so on. Every area by default.
//   --at 10,100,1000  the arrivals to measure after. The last is how many are
//                     drawn.
//   --save FILE       write the figures as JSON, to compare against later.
//   --against FILE    print each figure beside the one in FILE, as `new (old)`:
//                     `tools/layouts/baseline.json` is today's rules.
//
// The arrivals are strangers' crossings filed by name (`Stream`); the first
// run grows them, about a minute for all ten, and later runs read them back.

struct Options {
    var areas: [Area] = Area.allCases
    var at: [Int] = [10, 100, 1000]
    var save: String?
    var against: String?
}

/// The names an area answers to on the command line: its theme word, and
/// the name of the garden it is.
let names: [String: Area] = [
    "travel": .travel, "long-walk": .travel, "walk": .travel,
    "peace": .peace, "quiet-garden": .peace, "quiet": .peace,
    "meeting": .meeting, "crossing": .meeting,
    "kinship": .kinship, "orchard": .kinship,
    "pattern": .pattern, "knot-garden": .pattern, "knot": .pattern,
    "beginnings": .beginnings, "seedbed": .beginnings,
    "waiting": .waiting, "cold-frame": .waiting, "frame": .waiting,
    "light": .light, "glasshouse": .light,
    "renewal": .renewal, "coppice": .renewal,
    "ground": .ground, "home-ground": .ground,
]

let titles: [Area: String] = [
    .travel: "Long Walk", .peace: "Quiet Garden", .meeting: "Crossing", .kinship: "Orchard",
    .pattern: "Knot Garden", .beginnings: "Seedbed", .waiting: "Cold Frame", .light: "Glasshouse",
    .renewal: "Coppice", .ground: "Home Ground",
]

/// The order the research and `BASELINE.md` list the areas in.
let listed: [Area] = [.travel, .peace, .meeting, .kinship, .pattern, .beginnings, .waiting, .light, .renewal, .ground]

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(2)
}

func parse() -> Options {
    var options = Options()
    var picked: [Area] = []
    var args = CommandLine.arguments.dropFirst()
    while let arg = args.popFirst() {
        switch arg {
        case "--area":
            guard let name = args.popFirst(), let area = names[name.lowercased()] else {
                fail("--area wants one of: \(names.keys.sorted().joined(separator: ", "))")
            }
            picked.append(area)
        case "--at":
            guard let list = args.popFirst() else { fail("--at wants counts, as 10,100,1000") }
            options.at = list.split(separator: ",").compactMap { Int($0) }.sorted()
            guard !options.at.isEmpty, options.at.allSatisfy({ $0 > 0 }) else { fail("--at wants counts, as 10,100,1000") }
        case "--save": options.save = args.popFirst()
        case "--against": options.against = args.popFirst()
        case "-h", "--help":
            print("layouts-harness [--area NAME]… [--at 10,100,1000] [--save FILE] [--against FILE]")
            exit(0)
        default: fail("unknown option \(arg); --help says what there is")
        }
    }
    if !picked.isEmpty { options.areas = listed.filter(picked.contains) }
    else { options.areas = listed }
    return options
}

/// The figures as saved: area, then the arrivals each was measured after.
typealias Figures = [String: [String: Measure]]

let options = parse()
let started = Date()
let streams = Cache.stream(options.at.last!, for: options.areas)

var figures: Figures = [:]
for area in options.areas {
    let measures = Fill.run(area, streams[area]!, at: options.at)
    figures[area.rawValue] = Dictionary(uniqueKeysWithValues: measures.map { ("\($0.arrivals)", $0) })
}

let before: Figures? = options.against.flatMap { path in
    guard let data = FileManager.default.contents(atPath: path) else { fail("cannot read \(path)") }
    do { return try JSONDecoder().decode(Figures.self, from: data) } catch { fail("\(path) is not saved figures: \(error)") }
}

func percent(_ share: Double?) -> String {
    guard let share else { return "—" }
    return String(format: "%.1f%%", 100 * share)
}

/// A figure, and beside it the one it is compared against where that differs.
func cell(_ now: String, _ was: String?) -> String {
    guard let was, was != now else { return now }
    return "\(now) (\(was))"
}

print("| Area | Arrivals | Plots | Places held | Held | Settled plots | Held in settled | Empty in settled |")
print("|---|---|---|---|---|---|---|---|")
for area in options.areas {
    for count in options.at {
        guard let m = figures[area.rawValue]?["\(count)"] else { continue }
        let o = before?[area.rawValue]?["\(count)"]
        let row = [
            titles[area]!,
            "\(count)",
            cell("\(m.plots)", o.map { "\($0.plots)" }),
            cell("\(m.held) of \(m.places)", o.map { "\($0.held) of \($0.places)" }),
            cell(percent(m.heldShare), o.map { percent($0.heldShare) }),
            cell("\(m.settledPlots)", o.map { "\($0.settledPlots)" }),
            cell(percent(m.settledShare), o.map { percent($0.settledShare) }),
            cell(m.settledPlots == 0 ? "—" : "\(m.settledEmpty)" + (m.note.map { ", \($0)" } ?? ""),
                 o.map { $0.settledPlots == 0 ? "—" : "\($0.settledEmpty)" + ($0.note.map { ", \($0)" } ?? "") }),
        ]
        print("| " + row.joined(separator: " | ") + " |")
    }
}

if let path = options.save {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    do {
        try encoder.encode(figures).write(to: URL(fileURLWithPath: path))
        FileHandle.standardError.write(Data("saved \(path)\n".utf8))
    } catch {
        fail("cannot write \(path): \(error)")
    }
}
FileHandle.standardError.write(Data(String(format: "%.1f s\n", Date().timeIntervalSince(started)).utf8))
