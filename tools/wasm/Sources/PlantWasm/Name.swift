#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif
import SeedCore

// A plant's name, for the panel an area page opens when a plant is tapped.
//
//   pg_name(words, length)  the words `pg_grow` or `pg_grow_hybrid` takes — a
//                           seed alone, or the seed, both parents and the
//                           meeting — and the name into the result as JSON:
//
//     {"name":"Cerina vulgaris","head":"Cer","tail":"ina"}
//
//   and, for a crossed plant, the three facts the app draws its passage from:
//
//     "pair":{"heads":["Zeph","Mel"],"inherit":0.41,"axis":0.77}
//
// **The name is SeedCore's and nothing else's.** The page could read a genus
// back into its syllables (`passages.js` `syllables` does, for a name somebody
// typed), but it cannot make one: a binomial is drawn from the same genes as
// the body, and a second copy of that draw in JavaScript would be a second
// garden that agrees with this one until the day it does not. So the page asks
// the module that grew the plant, with the same words it grew it from.
//
// **The pair is for the passage, which the app draws at the meeting.**
// `Quotes.passage(for:)` takes the theme from the two parents — mostly one or
// the other, otherwise one lying between them — and the part from the child's
// own name. The theme table and its positions are the app's, not SeedCore's, so
// the page keeps a mirror of them (`passages.js` `sharedTheme`) and this hands
// it what only SeedCore can work out: each parent's own genus head, and the
// pair's two rolls. **Both parents in the app's order, the lower seed first**,
// as `CrossPollinationResult` keeps them, because *mine* and *theirs* are not
// interchangeable in that draw even though the pair's rolls are.

private struct Named: Encodable {
    struct Pair: Encodable {
        let heads: [String]
        let inherit: Double
        let axis: Double
    }
    let name: String
    let head: String
    let tail: String
    let pair: Pair?
}

@_expose(wasm, "pg_name")
@_cdecl("pg_name")
public func pgName(_ text: UnsafePointer<UInt8>, _ length: Int32) -> Int32 {
    let words = String(decoding: UnsafeBufferPointer(start: text, count: Int(length)), as: UTF8.self)
        .split(separator: " ").map(String.init)
    let named: Named
    switch words.count {
    case 1:
        guard let seed = SeedID(hex: words[0]) else { return 0 }
        let name = Genome(seed: seed).name
        named = Named(name: name.full, head: name.genusHead, tail: name.genusTail, pair: nil)
    case 4:
        guard let child = SeedID(hex: words[0]), let one = SeedID(hex: words[1]),
              let other = SeedID(hex: words[2]), let encounter = SeedID(hex: words[3])?.bytes else { return 0 }
        let (low, high) = one < other ? (one, other) : (other, one)
        let name = Genome.hybrid(child: child, parentA: low, parentB: high, encounterID: encounter).name
        let heads = [low, high].map { Genome(seed: $0, lineage: .minted).name.genusHead }
        named = Named(
            name: name.full, head: name.genusHead, tail: name.genusTail,
            pair: .init(
                heads: heads,
                inherit: Pollination.pairUnit(seedA: low, seedB: high, label: "passage.theme.inherit.v1"),
                axis: Pollination.pairUnit(seedA: low, seedB: high, label: "passage.theme.axis.v1")
            )
        )
    default:
        return 0
    }
    guard let json = try? JSONEncoder().encode(named) else { return 0 }
    setResult(Array(json))
    return Int32(json.count)
}
