import Foundation
@testable import SeedCore

/// A lotus's pads as the page draws them, and the stems standing inside them.
///
/// **The question the Cold Frame's and the Seedbed's lotus rule was decided
/// on**, asked of the plants themselves rather than of a width: since 24
/// September 2026 a lotus is a water lily whose pads lie on the soil further
/// from its stem than the next place along a row, and on 25 September Marcus
/// chose to let it take two places so that no other plant stands in them. The
/// outline is the convex hull of every vertex of the plant's mesh seen from
/// above, which is how the simulation behind that choice measured it, so a
/// test holding it to zero is holding the rule to the reason it exists.
enum LotusPads {

    /// The outline of a plant's leaves on the ground, around its stem, at the
    /// growth the page draws it at.
    static func outline(_ genome: Genome, growth: GrowthModel.State) -> [SIMD2<Double>] {
        let mesh = PlantBuilder(genome: genome).mesh(growth: growth)
        var points: [SIMD2<Double>] = []
        for part in mesh.parts {
            for v in part.positions { points.append(SIMD2(Double(v.x), Double(v.z))) }
        }
        return hull(points)
    }

    /// One stem inside one lotus's pads, in the same plot.
    struct Crowded: CustomStringConvertible {
        var lotus: String
        var stem: String
        var plot: Int
        var description: String { "plot \(plot): \(stem.prefix(8)) stands inside the pads of \(lotus.prefix(8))" }
    }

    /// Every stem standing inside a lotus's pads: each plant is its seed, its
    /// plot, where it stands and its genome; `growth` is how the area draws a
    /// plant. Only lotuses are grown, because only a lotus lies wide enough to
    /// be asked about.
    static func crowded(_ plants: [(seed: String, plot: Int, spot: Spot, genome: Genome)],
                        growth: (Genome) -> GrowthModel.State) -> [Crowded] {
        var found: [Crowded] = []
        let byPlot = Dictionary(grouping: plants, by: \.plot)
        for (plot, here) in byPlot {
            for lotus in here where lotus.genome.form.archetype == .lotus {
                let pads = outline(lotus.genome, growth: growth(lotus.genome))
                for other in here where other.seed != lotus.seed {
                    let at = SIMD2(other.spot.x - lotus.spot.x, other.spot.z - lotus.spot.z)
                    if inside(at, pads) { found.append(Crowded(lotus: lotus.seed, stem: other.seed, plot: plot)) }
                }
            }
        }
        return found
    }

    /// Monotone chain, counter-clockwise in (x, z).
    static func hull(_ points: [SIMD2<Double>]) -> [SIMD2<Double>] {
        let p = points.sorted { $0.x != $1.x ? $0.x < $1.x : $0.y < $1.y }
        if p.count < 3 { return p }
        func cross(_ o: SIMD2<Double>, _ a: SIMD2<Double>, _ b: SIMD2<Double>) -> Double {
            (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
        }
        var lower: [SIMD2<Double>] = [], upper: [SIMD2<Double>] = []
        for q in p {
            while lower.count >= 2 && cross(lower[lower.count - 2], lower[lower.count - 1], q) <= 0 { lower.removeLast() }
            lower.append(q)
        }
        for q in p.reversed() {
            while upper.count >= 2 && cross(upper[upper.count - 2], upper[upper.count - 1], q) <= 0 { upper.removeLast() }
            upper.append(q)
        }
        return Array(lower.dropLast() + upper.dropLast())
    }

    static func inside(_ q: SIMD2<Double>, _ h: [SIMD2<Double>]) -> Bool {
        guard h.count >= 3 else { return false }
        for i in 0..<h.count {
            let a = h[i], b = h[(i + 1) % h.count]
            if (b.x - a.x) * (q.y - a.y) - (b.y - a.y) * (q.x - a.x) < 0 { return false }
        }
        return true
    }
}
