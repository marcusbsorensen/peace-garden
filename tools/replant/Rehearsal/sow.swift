// The rehearsal's arrivals, grown by the SeedCore the live service was built
// with, so they carry the heights the phones send today.
//
//     sow <per area> <offers>
//
// Not built with the Replant package: `rehearse.sh` copies it into a package of
// its own beside a copy of the live code taken out of git, and builds it there.
// One JSON object a line: its role (a planting or an offer), its area, its seed,
// both parents, the meeting, and the traits a phone sends with it.
import Foundation
import SeedCore

let perArea = Int(CommandLine.arguments[1])!
let offers = Int(CommandLine.arguments[2])!
let open: [Area] = [.travel, .peace, .meeting, .kinship, .pattern, .beginnings, .waiting, .light, .renewal,
                    .ground]
var wanted = Dictionary(uniqueKeysWithValues: open.map { ($0, perArea) })
var offersLeft = offers
var n = 0
func hex(_ d: Data) -> String { d.map { String(format: "%02x", $0) }.joined() }
while wanted.values.contains(where: { $0 > 0 }) || offersLeft > 0 {
    let a = SeedMint.mint(fromEntropy: Data("replant-rehearsal-\(n)-a".utf8))
    let b = SeedMint.mint(fromEntropy: Data("replant-rehearsal-\(n)-b".utf8))
    n += 1
    let meeting = Pollination.encounterID(seedA: a, seedB: b, nonceA: Data("a".utf8), nonceB: Data("b".utf8))
    let child = Pollination.cross(seedA: a, seedB: b, encounterID: meeting)
    let g = Genome(seed: child, lineage: .crossed(parentA: a, parentB: b, encounterID: meeting))
    let area = Area(genome: g)
    var role = ""
    if let left = wanted[area], left > 0 { wanted[area] = left - 1; role = "plant" }
    else if offersLeft > 0, open.contains(area) { offersLeft -= 1; role = "offer" }
    else { continue }
    let t = LongWalk.traits(of: g)
    var o: [String: Any] = ["role": role, "area": area.rawValue, "seed": child.hex, "parentA": a.hex,
                            "parentB": b.hex, "encounter": hex(meeting), "height": t.height,
                            "family": t.family, "kind": t.kind, "habit": t.habit]
    o["hue"] = t.hue ?? NSNull()
    let data = try JSONSerialization.data(withJSONObject: o, options: [.sortedKeys])
    print(String(decoding: data, as: UTF8.self))
}
