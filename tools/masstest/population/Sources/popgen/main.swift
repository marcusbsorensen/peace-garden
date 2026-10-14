// popgen: the population test's ground truth.
//
//   popgen plan GARDENERS DAYS MEETINGS_PER_DAY RNG_SEED OUT.jsonl
//       Simulates gardeners meeting at random. Every meeting is SeedCore's own
//       exchange: two seeds, two nonces, the encounter ID, the child seed, the
//       child's traits read off its grown genome, its area read off its name,
//       and a pair of contact tokens. Writes one JSON line per gardener, then
//       one per meeting, in day order.
//
//   popgen verify PLAN.jsonl DUMP.json [POOL.jsonl ...]
//       Reads what the service's database holds (dumped by check.php) and
//       checks every planting against SeedCore and the plan: that the seed is
//       the cross of its parents at its meeting, that it was really grown at
//       that meeting by those two gardeners, and that a wild plant stands in
//       the tile SeedCore says. Prints a JSON report; exits 1 on any violation.
//
// Deterministic: one RNG seed gives the same population byte for byte.

import Foundation
import SeedCore

// MARK: - Determinism

struct SplitMix64 {
    var state: UInt64
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
    mutating func int(_ bound: Int) -> Int { Int(next() % UInt64(bound)) }
    mutating func unit() -> Double { Double(next() >> 11) * 0x1.0p-53 }
    mutating func bytes(_ count: Int) -> Data {
        var data = Data(capacity: count)
        while data.count < count {
            var word = next()
            withUnsafeBytes(of: &word) { data.append(contentsOf: $0.prefix(count - data.count)) }
        }
        return data
    }
}

func hex(_ data: Data) -> String { data.map { String(format: "%02x", $0) }.joined() }

func unhex(_ string: String) -> Data? {
    guard string.count % 2 == 0 else { return nil }
    var data = Data(capacity: string.count / 2)
    var index = string.startIndex
    while index < string.endIndex {
        let next = string.index(index, offsetBy: 2)
        guard let byte = UInt8(string[index..<next], radix: 16) else { return nil }
        data.append(byte)
        index = next
    }
    return data
}

func jsonLine(_ object: [String: Any]) -> String {
    let data = try! JSONSerialization.data(withJSONObject: object, options: [.sortedKeys, .withoutEscapingSlashes])
    return String(decoding: data, as: UTF8.self)
}

// MARK: - Names a gardener might choose

/// Names people choose, including the ones a service gets wrong: right-to-left
/// scripts, combining marks, emoji, CJK, apostrophes and SQL-shaped text. No
/// control or formatting characters — the app strips those before sending
/// (`WildShowing.choosing`); the driver sends some raw on purpose, elsewhere.
let names = [
    "Marcus", "Anna", "Søren", "Zoë", "Ngozi", "Siobhán", "José", "Łucja", "Đặng Thị Hồng",
    "مريم", "דניאל", "فاطمه", "Ἀλέξανδρος", "Владимир", "王小明", "さくら", "김민준", "देवनागरी नाम",
    "ಕನ್ನಡ", "தமிழ்", "🌱", "Rose 🌹", "🌻🌻🌻", "O'Brien", "Robert'); DROP TABLE wild_fields;--",
    "\" OR 1=1 --", "<script>alert(1)</script>", "Ab\u{0301}c\u{0327}", "  padded  ",
    String(repeating: "ę", count: 48), String(repeating: "🌿", count: 48),
]
let places = [
    "Margate", "Kraków", "Hà Nội", "القاهرة", "תל אביב", "東京", "Café de l'Ours", "Broadstairs beach",
    "1' OR '1'='1", "Kew 🌳", String(repeating: "Ł", count: 64),
]

// MARK: - plan

func plan(gardeners count: Int, days: Int, perDay: Double, rngSeed: UInt64, out: String) throws {
    var rng = SplitMix64(state: rngSeed)
    FileManager.default.createFile(atPath: out, contents: nil)
    guard let file = FileHandle(forWritingAtPath: out) else { throw CocoaError(.fileWriteNoPermission) }
    defer { try? file.close() }
    var buffer = ""
    func write(_ line: String) {
        buffer += line + "\n"
        if buffer.utf8.count > 1 << 20 { file.write(Data(buffer.utf8)); buffer = "" }
    }

    // Towns, so most meetings are between neighbours and lineages run deep
    // rather than every plant being a first cross of two minted seeds.
    let towns = max(1, count / 100)
    var gardens: [[SeedID]] = []
    var townOf: [Int] = []
    var byTown: [[Int]] = Array(repeating: [], count: towns)
    for g in 0..<count {
        let seed = SeedMint.mint(fromEntropy: rng.bytes(32))
        gardens.append([seed])
        let town = rng.int(towns)
        townOf.append(town)
        byTown[town].append(g)
        write(jsonLine(["kind": "gardener", "g": g, "town": town, "name": names[rng.int(names.count)],
                        "place": places[rng.int(places.count)], "seed": seed.hex]))
    }

    var meeting = 0
    var skipped = 0
    let started = Date()
    for day in 0..<days {
        // Roughly Poisson around perDay, by summing coin flips.
        let todays = Int(perDay * (0.75 + rng.unit() * 0.5))
        for _ in 0..<todays {
            let a = rng.int(count)
            let neighbours = byTown[townOf[a]]
            var b = rng.unit() < 0.8 && neighbours.count > 1 ? neighbours[rng.int(neighbours.count)] : rng.int(count)
            if b == a { b = (a + 1) % count }
            // Each brings a plant from their garden, the newest most often.
            func bring(_ garden: [SeedID]) -> SeedID {
                rng.unit() < 0.5 ? garden[garden.count - 1] : garden[rng.int(garden.count)]
            }
            let seedA = bring(gardens[a]), seedB = bring(gardens[b])
            if seedA == seedB { skipped += 1; continue }   // the exchange aborts: "same seed"
            let nonceA = rng.bytes(16), nonceB = rng.bytes(16)
            let tokenA = rng.bytes(16), tokenB = rng.bytes(16)
            let encounter = Pollination.encounterID(seedA: seedA, seedB: seedB, nonceA: nonceA, nonceB: nonceB)
            let child = Pollination.cross(seedA: seedA, seedB: seedB, encounterID: encounter)
            let genome = Genome(seed: child, lineage: .crossed(parentA: seedA, parentB: seedB, encounterID: encounter))
            let traits = LongWalk.traits(of: genome)
            let area = Area(genome: genome)
            gardens[a].append(child)
            gardens[b].append(child)
            if gardens[a].count > 40 { gardens[a].removeFirst() }
            if gardens[b].count > 40 { gardens[b].removeFirst() }
            var row: [String: Any] = [
                "kind": "meeting", "m": meeting, "day": day, "a": a, "b": b,
                "parents": [seedA.hex, seedB.hex], "encounter": hex(encounter), "seed": child.hex,
                "tokenA": hex(tokenA), "tokenB": hex(tokenB),
                "height": traits.height, "family": traits.family, "kind_": traits.kind,
                "habit": traits.habit, "area": area.rawValue, "name": genome.name.full,
            ]
            if let hue = traits.hue { row["hue"] = hue }
            write(jsonLine(row))
            meeting += 1
        }
        if day % 10 == 0 {
            FileHandle.standardError.write(Data(String(format: "day %d: %d meetings, %.0fs\n",
                day, meeting, Date().timeIntervalSince(started)).utf8))
        }
    }
    file.write(Data(buffer.utf8))
    FileHandle.standardError.write(Data("\(meeting) meetings, \(skipped) skipped as same-seed, \(count) gardeners\n".utf8))
}

// MARK: - verify

struct Truth { let parents: Set<String>; let encounter: String; let a: Int; let b: Int }

func verify(planPath: String, dumpPath: String, morePlans: [String] = []) throws -> Int32 {
    var truth: [String: Truth] = [:]
    // The population's plan, and any pool plans the adversary and the load
    // test grew their true crosses from: all of them are meetings that happened.
    for path in [planPath] + morePlans {
    let planText = try String(contentsOfFile: path, encoding: .utf8)
    for line in planText.split(separator: "\n") {
        guard let row = try JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any],
              row["kind"] as? String == "meeting",
              let seed = row["seed"] as? String, let parents = row["parents"] as? [String],
              let encounter = row["encounter"] as? String else { continue }
        truth[seed] = Truth(parents: Set(parents), encounter: encounter, a: row["a"] as! Int, b: row["b"] as! Int)
    }
    }
    // Seeds the driver made up on purpose (forged, wrong meeting) or grew for
    // the load test outside the plan: the dump says which were extra and why.
    let dump = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: dumpPath))) as! [String: Any]
    let extra = Set((dump["extra_genuine"] as? [String]) ?? [])
    var violations: [String] = []
    var checked = 0, crossed = 0, markers = 0
    func note(_ text: String) { if violations.count < 200 { violations.append(text) } }

    func checkCross(_ seed: String, _ pa: String, _ pb: String, _ encounter: String?) -> Bool {
        guard let s = SeedID(hex: seed), let a = SeedID(hex: pa), let b = SeedID(hex: pb) else { return false }
        guard let encounter else { return true }
        guard let e = unhex(encounter) else { return false }
        return Pollination.cross(seedA: a, seedB: b, encounterID: e) == s
    }

    let areas = dump["areas"] as? [String: [[String: Any]]] ?? [:]
    for (table, rows) in areas {
        for row in rows {
            let seed = row["seed"] as! String
            if seed.hasPrefix("withdrawn:") { markers += 1; continue }
            checked += 1
            let pa = row["parent_a"] as! String, pb = row["parent_b"] as! String
            let encounter = row["encounter"] as! String
            if !checkCross(seed, pa, pb, encounter) { note("\(table): \(seed) is not the cross of its parents at its meeting"); continue }
            crossed += 1
            guard let t = truth[seed] else {
                if !extra.contains(seed) { note("\(table): \(seed) was never grown at any meeting") }
                continue
            }
            if t.parents != Set([pa, pb]) { note("\(table): \(seed) names parents that did not meet") }
            if t.encounter != encounter { note("\(table): \(seed) names the wrong meeting") }
        }
    }
    let wild = dump["wild"] as? [[String: Any]] ?? []
    for row in wild {
        checked += 1
        let seed = row["seed"] as! String
        let pa = row["parent_a"] as! String, pb = row["parent_b"] as! String
        guard let s = SeedID(hex: seed) else { note("wild: unreadable seed \(seed)"); continue }
        let tile = WildFields.tile(of: s)
        if tile.x != row["tile_x"] as! Int || tile.z != row["tile_z"] as! Int {
            note("wild: \(seed) stored in tile \(row["tile_x"]!),\(row["tile_z"]!) but SeedCore puts it in \(tile.x),\(tile.z)")
        }
        let spot = WildFields.spot(of: s)
        if !(0..<64).contains(spot.x) || !(0..<64).contains(spot.z) { note("wild: \(seed) stands outside the field") }
        guard let t = truth[seed] else {
            // An invented lineage the adversary released on purpose: a true
            // cross of parents nobody holds, which the service takes by design.
            if extra.contains(seed) { crossed += 1 } else { note("wild: \(seed) was never grown at any meeting") }
            continue
        }
        if t.parents != Set([pa, pb]) { note("wild: \(seed) names parents that did not meet") }
        // The wild keeps no meeting, so the cross is checked against the plan's.
        if !checkCross(seed, pa, pb, t.encounter) { note("wild: \(seed) is not the cross of its parents") } else { crossed += 1 }
    }
    let report: [String: Any] = ["planted_checked": checked, "true_crosses": crossed, "taken_back_markers": markers,
                                 "plan_meetings": truth.count, "violations": violations]
    print(jsonLine(report))
    return violations.isEmpty ? 0 : 1
}

// MARK: - main

let args = CommandLine.arguments
switch args.count > 1 ? args[1] : "" {
case "plan" where args.count == 7:
    try plan(gardeners: Int(args[2])!, days: Int(args[3])!, perDay: Double(args[4])!,
             rngSeed: UInt64(args[5])!, out: args[6])
case "verify" where args.count >= 4:
    exit(try verify(planPath: args[2], dumpPath: args[3], morePlans: Array(args.dropFirst(4))))
default:
    FileHandle.standardError.write(Data("usage: popgen plan GARDENERS DAYS PER_DAY RNG_SEED OUT | verify PLAN DUMP [POOL ...]\n".utf8))
    exit(2)
}
