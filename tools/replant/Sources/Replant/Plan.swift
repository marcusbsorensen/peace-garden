import CryptoKit
import Foundation
import SeedCore

/// What the replant will do, worked out on the Mac and carried out on the
/// server by `Server/.api/replant.php`, which checks every line of it first.
struct Plan: Codable {
    static let format = "peace-garden-replant/1"

    var format = Plan.format
    /// A digest of everything below that the server writes, which
    /// `replant.php` works out again from the plan before it trusts it, and
    /// which it records once the plan has run so it cannot run twice.
    var id: String
    var made: String
    var copy: CopyInfo
    var tables: [TablePlan]
    var offers: OffersPlan
    /// Anything about the copy worth a human reading before the plan is run.
    var notes: [String]

    struct CopyInfo: Codable {
        var file: String
        var sha256: String
        var taken: String?
        var kind: String
    }

    /// What a table held when the copy was taken: how many rows, the last
    /// arrival, and a digest of every arrival number with its seed (or its
    /// marker) in order. The server refuses a table that does not match.
    struct Fingerprint: Codable, Equatable {
        var rows: Int
        var last: Int
        var sha256: String
    }

    struct TablePlan: Codable {
        var table: String
        var area: String
        var before: Fingerprint
        /// Every planting still standing, in arrival order, with its traits
        /// grown again and the place the area's rule gives it now.
        var plantings: [Planting]
        /// The arrivals taken back, which the replant removes. See README.md.
        var takenBack: [Int]
        /// How many stored traits the regrowing changed, by name.
        var changed: [String: Int]
        var plotsBefore: Int
        var plotsAfter: Int
        var moved: Int
    }

    struct Planting: Codable {
        var arrival: Int
        var seed: String
        var height: Double
        /// The height's bits, so a height cannot drift on its way through
        /// JSON without the server noticing.
        var heightBits: String
        var family: Int
        var kind: String
        var hue: Double?
        var habit: String
        var wasHeight: Double
        var place: [String: Double]
    }

    struct OffersPlan: Codable {
        var before: Fingerprint
        var pending: [Offer]
    }

    /// An offer still waiting for its answer, whose traits it will be planted
    /// by. **Named by the digest of its seed, not the seed**: an offer that
    /// has not been accepted is not on any page, and the plan is a file that
    /// travels.
    struct Offer: Codable {
        var offer: Int
        var seedSha256: String
        var area: String
        var height: Double
        var heightBits: String
        var family: Int
        var kind: String
        var hue: Double?
        var habit: String
        var wasHeight: Double?
    }
}

enum Planner {
    static func make(from copy: Copy) throws -> Plan {
        var notes: [String] = []
        var tables: [Plan.TablePlan] = []

        for spec in AreaTable.all {
            guard let rows = copy.rows[spec.table] else {
                notes.append("\(spec.table): not in the copy, so it held nothing when the copy was taken; the server will check it still does")
                continue
            }
            let ordered = rows.sorted { ($0["arrival"]?.int ?? 0) < ($1["arrival"]?.int ?? 0) }
            var standing: [(arrival: Int, seed: SeedID, traits: PlantTraits, was: Row)] = []
            var takenBack: [Int] = []
            var changed: [String: Int] = [:]

            for row in ordered {
                guard let arrival = row["arrival"]?.int, let seedText = row["seed"]?.string else {
                    throw CopyError("\(spec.table): a row with no arrival or no seed")
                }
                if seedText.hasPrefix("withdrawn:") || (row["hidden"]?.int ?? 0) != 0 {
                    takenBack.append(arrival)
                    continue
                }
                let genome = try regrow(seed: seedText, parentA: row["parent_a"]?.string,
                                        parentB: row["parent_b"]?.string, encounter: row["encounter"]?.string,
                                        where: "\(spec.table) arrival \(arrival)")
                let traits = LongWalk.traits(of: genome)
                if Area(genome: genome) != spec.area {
                    notes.append("\(spec.table) arrival \(arrival): its name puts it in \(Area(genome: genome).rawValue), not \(spec.area.rawValue); it stays where it was planted")
                }
                if row["family"]?.int != traits.family { changed["family", default: 0] += 1 }
                if let kind = row["kind"], kind.string != traits.kind { changed["kind", default: 0] += 1 }
                if let hue = row["hue"], hue.double != traits.hue { changed["hue", default: 0] += 1 }
                if let habit = row["habit"], habit.string != traits.habit { changed["habit", default: 0] += 1 }
                if row["height"]?.double != traits.height { changed["height", default: 0] += 1 }
                guard let seed = SeedID(hex: seedText) else { throw CopyError("bad seed at \(spec.table) \(arrival)") }
                standing.append((arrival, seed, traits, row))
            }

            let places = spec.replay(standing.map { ($0.seed, $0.traits) })
            var plantings: [Plan.Planting] = []
            var moved = 0
            for (item, place) in zip(standing, places) {
                let wasPlace = ["plot"] + spec.slot
                let same = wasPlace.allSatisfy { key in
                    let column = key == "index" ? "slot_index"
                        : key == "rank" ? "slot_rank" : key == "row" ? "slot_row"
                        : key == "span" ? "slot_span" : key
                    // A copy from before the lotus rule has no span, and
                    // every planting in it held one place.
                    let was = item.was[column]?.double ?? (key == "span" ? 1 : nil)
                    return was == place[key]
                }
                if !same { moved += 1 }
                plantings.append(Plan.Planting(
                    arrival: item.arrival, seed: item.seed.hex,
                    height: item.traits.height, heightBits: bits(item.traits.height),
                    family: item.traits.family, kind: item.traits.kind, hue: item.traits.hue,
                    habit: item.traits.habit, wasHeight: item.was["height"]?.double ?? 0,
                    place: place))
            }
            let plotsBefore = (ordered.compactMap { $0["plot"]?.int }.max() ?? -1) + 1
            let plotsAfter = Int(places.map { $0["plot"] ?? 0 }.max() ?? -1) + 1
            tables.append(Plan.TablePlan(
                table: spec.table, area: spec.area.rawValue, before: fingerprint(ordered, key: "arrival"),
                plantings: plantings, takenBack: takenBack, changed: changed,
                plotsBefore: max(plotsBefore, 1), plotsAfter: max(plotsAfter, 1), moved: moved))
        }

        // The asking: every offer still waiting, grown again, so that when it
        // is accepted it is planted by the shapes the garden now has.
        let offerRows = (copy.rows["walk_offers"] ?? []).sorted { ($0["offer"]?.int ?? 0) < ($1["offer"]?.int ?? 0) }
        let waiting = offerRows.filter { $0["state"]?.string == "offered" }
        var pending: [Plan.Offer] = []
        for row in waiting {
            guard let offer = row["offer"]?.int, let seedText = row["seed"]?.string else {
                throw CopyError("walk_offers: a waiting offer with no number or no seed")
            }
            let genome = try regrow(seed: seedText, parentA: row["parent_a"]?.string,
                                    parentB: row["parent_b"]?.string, encounter: row["encounter"]?.string,
                                    where: "offer \(offer)")
            let traits = LongWalk.traits(of: genome)
            if let area = row["area"]?.string, area != Area(genome: genome).rawValue {
                notes.append("offer \(offer): offered for \(area), and its name puts it in \(Area(genome: genome).rawValue); left for \(area)")
            }
            pending.append(Plan.Offer(
                offer: offer, seedSha256: sha256(seedText), area: row["area"]?.string ?? "travel",
                height: traits.height, heightBits: bits(traits.height), family: traits.family,
                kind: traits.kind, hue: traits.hue, habit: traits.habit, wasHeight: row["height"]?.double))
        }
        let offersBefore = fingerprint(waiting, key: "offer", seedDigest: true)

        var plan = Plan(id: "", made: ISO8601DateFormatter().string(from: Date()),
                        copy: .init(file: copy.file, sha256: copy.sha256, taken: copy.taken, kind: copy.kind),
                        tables: tables, offers: .init(before: offersBefore, pending: pending), notes: notes)
        plan.id = identity(plan)
        return plan
    }

    /// The plant a row names, grown from its seed and the meeting it came
    /// from. **Refused rather than grown differently** if the seed is not the
    /// cross of its parents at that meeting: the service checked that when
    /// the plant arrived, so a row that fails it is not a row this should
    /// guess about.
    static func regrow(seed: String, parentA: String?, parentB: String?, encounter: String?,
                       where place: String) throws -> Genome {
        guard let child = SeedID(hex: seed), let a = parentA.flatMap(SeedID.init(hex:)),
              let b = parentB.flatMap(SeedID.init(hex:)), let meeting = encounter.flatMap(hexData) else {
            throw CopyError("\(place): the seed, a parent or the meeting is missing or not hex")
        }
        guard Pollination.cross(seedA: a, seedB: b, encounterID: meeting) == child else {
            throw CopyError("\(place): the seed is not the cross of its parents at its meeting")
        }
        return Genome(seed: child, lineage: .crossed(parentA: a, parentB: b, encounterID: meeting))
    }

    static func hexData(_ hex: String) -> Data? {
        let chars = Array(hex.utf8)
        guard chars.count % 2 == 0 else { return nil }
        var out = Data()
        var i = 0
        while i < chars.count {
            guard let byte = UInt8(String(decoding: chars[i...i + 1], as: UTF8.self), radix: 16) else { return nil }
            out.append(byte)
            i += 2
        }
        return out
    }

    static func bits(_ value: Double) -> String {
        let hex = String(value.bitPattern, radix: 16)
        return String(repeating: "0", count: 16 - hex.count) + hex
    }

    static func sha256(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    /// `replant.php`'s `fingerprint()`, the same lines digested the same way.
    static func fingerprint(_ rows: [Row], key: String, seedDigest: Bool = false) -> Plan.Fingerprint {
        var lines = ""
        var last = 0
        for row in rows {
            let number = row[key]?.int ?? 0
            last = max(last, number)
            let seed = row["seed"]?.string ?? ""
            lines += "\(number) \(seedDigest ? sha256(seed) : seed)\n"
        }
        return Plan.Fingerprint(rows: rows.count, last: last, sha256: sha256(lines))
    }

    /// `replant.php`'s `identity()`: one line for everything the server
    /// writes, in order, digested. Worked out again on the server from the
    /// plan's own contents, so a plan edited or cut short is refused.
    static func identity(_ plan: Plan) -> String {
        var lines = "\(Plan.format)\n\(plan.copy.sha256)\n"
        for table in plan.tables {
            lines += "\(table.table) before \(table.before.rows) \(table.before.last) \(table.before.sha256)\n"
            for p in table.plantings {
                lines += "\(table.table) \(p.arrival) \(p.seed) \(p.heightBits) \(p.family) \(p.kind) \(p.hue.map(bits) ?? "-") \(p.habit)"
                for key in p.place.keys.sorted() { lines += " \(key)=\(bits(p.place[key]!))" }
                lines += "\n"
            }
            for arrival in table.takenBack { lines += "\(table.table) \(arrival) taken back\n" }
        }
        lines += "walk_offers before \(plan.offers.before.rows) \(plan.offers.before.last) \(plan.offers.before.sha256)\n"
        for o in plan.offers.pending {
            lines += "walk_offers \(o.offer) \(o.seedSha256) \(o.heightBits) \(o.family) \(o.kind) \(o.hue.map(bits) ?? "-") \(o.habit)\n"
        }
        return sha256(lines)
    }
}
