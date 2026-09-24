// replant plan <copy> [--out plan.json]
//
// Reads a copy of the live garden (a `walk-*.sql.gz` from tools/backup.sh, or a
// SQLite file), grows every stored seed again with SeedCore as it is now, and
// writes the plan Server/.api/replant.php carries out. Prints what the plan
// does, area by area. Writes nothing but the plan.

import Foundation

let arguments = Array(CommandLine.arguments.dropFirst())
guard arguments.first == "plan", arguments.count >= 2 else {
    FileHandle.standardError.write(Data("usage: replant plan <copy> [--out plan.json]\n".utf8))
    exit(2)
}
let source = arguments[1]
var out = "plan-" + URL(fileURLWithPath: source).lastPathComponent
    .replacingOccurrences(of: ".sql.gz", with: "").replacingOccurrences(of: ".sqlite", with: "") + ".json"
if let flag = arguments.firstIndex(of: "--out"), flag + 1 < arguments.count { out = arguments[flag + 1] }

do {
    let copy = try Copy.read(source)
    print("The copy: \(copy.file), a \(copy.kind)\(copy.taken.map { ", taken \($0)" } ?? "")")
    let plan = try Planner.make(from: copy)

    for table in plan.tables {
        let deltas = table.plantings.map { abs($0.height - $0.wasHeight) }.sorted()
        let median = deltas.isEmpty ? 0 : deltas[deltas.count / 2]
        let changed = table.changed.isEmpty ? "nothing else"
            : table.changed.sorted { $0.key < $1.key }.map { "\($0.key) \($0.value)" }.joined(separator: ", ")
        let name = table.table.padding(toLength: 13, withPad: " ", startingAt: 0)
        print("  \(name)\(table.plantings.count) standing, \(table.takenBack.count) taken back; "
              + "plots \(table.plotsBefore) -> \(table.plotsAfter); \(table.moved) move; changed: \(changed); "
              + String(format: "median height change %.3f m", median))
    }
    print("  walk_offers  \(plan.offers.pending.count) waiting, grown again")
    for note in plan.notes { print("  note: \(note)") }

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    try encoder.encode(plan).write(to: URL(fileURLWithPath: out))
    print("Plan \(plan.id.prefix(12)) written to \(out)")
} catch {
    FileHandle.standardError.write(Data("replant: \(error)\n".utf8))
    exit(1)
}
