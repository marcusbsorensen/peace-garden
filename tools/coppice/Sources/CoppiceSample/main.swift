// Grows plants whose names put them in the Coppice and writes down what a
// placement rule could read off each: its grown height and spread, its colour,
// its archetype, and how tall it stands at the two young stages a coppice stool
// would be drawn at.
//
//     swift run -c release --package-path tools/coppice coppice-sample <count> <prefix>
//
// The arrivals are found the way `ColdFrameTests` finds the Cold Frame's:
// crossings of freshly minted pairs, keeping only the children whose genus head
// is `Dros` or `Ros`. A different prefix is a different sample, which is how
// `simulate.py` measures on plants its cut was not fitted to.

import Foundation
import SeedCore

let arguments = CommandLine.arguments
let count = arguments.count > 1 ? Int(arguments[1]) ?? 2000 : 2000
let prefix = arguments.count > 2 ? arguments[2] : "coppice-arrival"

/// A stool in the year it is cut: new shoots, leaves not yet fully open, no bud.
/// `heightScale` stays above 0.25, below which `PlantBuilder` draws the husk.
let cut: GrowthModel.State = {
    // The Cold Frame's young state is public and its initialiser is not, so
    // the two stages are that one with its numbers changed.
    var state = ColdFrame.drawn
    state.heightScale = 0.30
    state.leafUnfurl = 0.6
    state.budSwell = 0
    return state
}()

/// A stool in its second summer: most of its height, in bud.
let regrowing: GrowthModel.State = {
    var state = ColdFrame.drawn
    state.stageProgress = 0.8
    state.overall = 0.65
    state.heightScale = 0.65
    state.leafUnfurl = 0.9
    state.budSwell = 0.4
    return state
}()

func tall(_ mesh: PlantMesh) -> Double { Double(mesh.maxBounds.y - mesh.minBounds.y) }

/// Six decimals: a micrometre of height, and a hue to a millionth of a turn.
/// Enough for a design; the build measures its own vectors. A decimal number,
/// so the file says 0.871949 rather than the double nearest to it.
func round6(_ value: Double) -> NSDecimalNumber { NSDecimalNumber(string: String(format: "%.6f", value)) }

let columns = ["height", "spread", "family", "hue", "saturation", "archetype", "epithet",
               "cutHeight", "regrowingHeight"]
var rows: [[Any]] = []
var crossings = 0
while rows.count < count {
    let a = SeedMint.mint(fromEntropy: Data("\(prefix)-\(crossings)-a".utf8))
    let b = SeedMint.mint(fromEntropy: Data("\(prefix)-\(crossings)-b".utf8))
    crossings += 1
    let meeting = Pollination.encounterID(seedA: a, seedB: b,
                                          nonceA: Data("a".utf8), nonceB: Data("b".utf8))
    let child = Pollination.cross(seedA: a, seedB: b, encounterID: meeting)
    let genome = Genome(seed: child, lineage: .crossed(parentA: a, parentB: b, encounterID: meeting))
    guard Area(genome: genome) == .renewal else { continue }

    let bounds = Maturity.bounds(for: genome)
    let petal = genome.palette.petalBase
    let builder = PlantBuilder(genome: genome)
    rows.append([
        round6(Double(bounds.max.y - bounds.min.y)),
        round6(Double(max(bounds.max.x - bounds.min.x, bounds.max.z - bounds.min.z))),
        LongWalk.family(hue: petal.hue, saturation: petal.saturation),
        round6(petal.hue),
        round6(petal.saturation),
        genome.form.archetype.rawValue,
        genome.name.epithet,
        round6(tall(builder.mesh(growth: cut))),
        round6(tall(builder.mesh(growth: regrowing))),
    ])
}

// The ambassador, grown the same way, so the design can say where it stands.
let one = Ambassadors.of(.renewal)
let oneBounds = Maturity.bounds(for: one.genome)
let onePetal = one.genome.palette.petalBase
let ambassador: [String: Any] = [
    "seed": one.seed.hex,
    "name": "\(one.genome.name.genus) \(one.genome.name.epithet)",
    "height": round6(Double(oneBounds.max.y - oneBounds.min.y)),
    "family": LongWalk.family(hue: onePetal.hue, saturation: onePetal.saturation),
    "archetype": one.genome.form.archetype.rawValue,
]

let out: [String: Any] = [
    "prefix": prefix,
    "crossings": crossings,
    "ambassador": ambassador,
    "columns": columns,
    "arrivals": rows,
]
let data = try JSONSerialization.data(withJSONObject: out, options: [.sortedKeys])
FileHandle.standardOutput.write(data)
FileHandle.standardOutput.write(Data("\n".utf8))
