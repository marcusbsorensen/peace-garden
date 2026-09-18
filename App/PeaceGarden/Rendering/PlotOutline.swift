import CoreGraphics
import Foundation
import SeedCore
import SwiftUI

/// The plot's edge as it is drawn: SeedCore's `Organic.outline` for this plot's
/// side, worked out once and kept.
///
/// **No straight line anywhere in the garden** (Marcus, 18 September). The
/// ground, the cut under it, the path's ends, the hedges' footings and every
/// check on where a thing may stand all read this one loop, so the edge a plant
/// is kept inside is the edge that is drawn.
///
/// **The seeds are fixed and written down here**, because the website draws the
/// Long Walk from the same functions and has to reach for the same numbers:
///
/// - the ground: `Organic.outline(width: side, length: side, seed: 1)`,
///   the outline `OrganicTests` pins at 5.2 m;
/// - the path's verges: `Organic.verge(z, side: ±1, seed: 2)`, and the two
///   stripe boundaries inside it `Organic.wobble(z, wavelength: 1.3,
///   seed: mix64(2 + boundary))` at a third of a verge's wander;
/// - each hedge: `Organic.hedge(…, seed: mix64(UInt64(bitPattern: side)))` for
///   the hedge on side `-1` or `+1` of the path.
struct PlotOutline: Sendable {
    static let groundSeed: UInt64 = 1
    static let pathSeed: UInt64 = 2
    static func hedgeSeed(side: Int) -> UInt64 { mix64(UInt64(bitPattern: Int64(side))) }

    let plotSide: Double
    /// The loop, anticlockwise from above, about eight centimetres a step.
    let points: [Spot]

    /// Each point's bearing from the middle, sorted, and how far out it is, in
    /// metres. The loop is a worn square, so a bearing meets it once and this
    /// table answers *how far out is the ground here* without walking two
    /// hundred edges — which the shadow march asks sixteen thousand times a
    /// drawing.
    private let bearings: [Double]
    private let radii: [Double]

    init(plotSide: Double) {
        self.plotSide = plotSide
        points = Organic.outline(width: plotSide, length: plotSide, seed: Self.groundSeed)
        let table = points.map { p -> (Double, Double) in
            (atan2(p.z, p.x), (p.x * p.x + p.z * p.z).squareRoot())
        }.sorted { $0.0 < $1.0 }
        bearings = table.map(\.0)
        radii = table.map(\.1)
    }

    // MARK: Kept

    private static let lock = NSLock()
    nonisolated(unsafe) private static var held: [Int: PlotOutline] = [:]

    /// The outline for a plot's side, computed the first time it is asked for.
    static func of(plotSide: Double) -> PlotOutline {
        let key = Int((plotSide * 1000).rounded())
        lock.lock()
        defer { lock.unlock() }
        if let outline = held[key] { return outline }
        let outline = PlotOutline(plotSide: plotSide)
        if held.count > 8 { held.removeAll() }
        held[key] = outline
        return outline
    }

    // MARK: Questions

    /// Whether a place is on the ground, exactly.
    func contains(x: Double, z: Double) -> Bool {
        Organic.contains(points, x: x, z: z)
    }

    /// How far out the ground reaches on a bearing, in metres.
    func reach(bearing: Double) -> Double {
        let n = bearings.count
        guard n > 1 else { return plotSide / 2 }
        // The first bearing past this one, wrapping round at ±π.
        var low = 0, high = n
        while low < high {
            let mid = (low + high) / 2
            if bearings[mid] < bearing { low = mid + 1 } else { high = mid }
        }
        let after = low % n, before = (low - 1 + n) % n
        var a = bearings[before], b = bearings[after]
        if b <= a { b += 2 * .pi }
        var t = bearing
        if t < a { t += 2 * .pi }
        let f = b > a ? (t - a) / (b - a) : 0
        return radii[before] + (radii[after] - radii[before]) * f
    }

    /// How far out the ground reaches on the bearing of a place, as a fraction
    /// of how far out the square reaches on it. Worked out as two lengths
    /// rather than kept as the fraction, because the square's reach has a kink
    /// at each diagonal that a fraction interpolated across it would smear.
    private func fraction(x: Double, z: Double) -> Double {
        let square = plotSide / 2 * (x * x + z * z).squareRoot() / max(abs(x), abs(z))
        return reach(bearing: atan2(z, x)) / square
    }

    /// Whether a place is on the ground, by the bearing table: the answer for
    /// a loop drawn through the same points, near enough to march a shadow on.
    func reaches(x: Double, z: Double) -> Bool {
        let half = plotSide / 2
        let square = max(abs(x), abs(z))
        guard square > half * 0.8 else { return true }
        return square <= half * fraction(x: x, z: z)
    }

    /// A place on the square, drawn in to the outline.
    ///
    /// The ground is a grid over the square, and warping its outer part is what
    /// makes the grid's own edge the wandering one: the rim lands on the
    /// outline, the cut can hang from the grid's last row, and nothing needs
    /// clipping. **Only the outer half moves**, easing in from nothing, so a
    /// plant in the middle stands on exactly the ground under it and one near
    /// the rim on ground a few centimetres from where it was sampled.
    func warp(x: Double, z: Double) -> (x: Double, z: Double) {
        let half = plotSide / 2
        let square = max(abs(x), abs(z)) / half
        guard square > 0.5 else { return (x, z) }
        let s = fraction(x: x, z: z)
        let t = min(1, (square - 0.5) / 0.5)
        let w = t * t * (3 - 2 * t)
        let f = 1 - (1 - s) * w
        return (x * f, z * f)
    }

    /// Where the ground stops along a line across the plot at `z`, on side `-1`
    /// or `+1` of the middle, as a distance out from `x = 0`.
    func extent(z: Double, side: Int) -> Double? {
        var best: Double?
        var j = points.count - 1
        for i in 0..<points.count {
            let a = points[i], b = points[j]
            j = i
            guard (a.z > z) != (b.z > z) else { continue }
            let x = a.x + (b.x - a.x) * (z - a.z) / (b.z - a.z)
            let out = x * Double(side)
            if out > (best ?? -.infinity) { best = out }
        }
        return best
    }

    /// A place kept on the ground: drawn straight in toward the middle until it
    /// stands `margin` inside the edge. What a plant or a light dropped over
    /// the rim does, since somebody aiming for the edge meant the edge.
    func keepOn(_ spot: Spot, margin: Double = 0.1) -> Spot {
        let length = (spot.x * spot.x + spot.z * spot.z).squareRoot()
        guard length > 0 else { return spot }
        let ux = spot.x / length, uz = spot.z / length
        func fits(_ r: Double) -> Bool {
            contains(x: ux * r, z: uz * r) && contains(x: ux * (r + margin), z: uz * (r + margin))
        }
        if fits(length) { return spot }
        var r = length
        while r > 0, !fits(r) { r -= 0.005 }
        let kept = max(0, r)
        return Spot(x: ux * kept, z: uz * kept)
    }

    /// Whether something let go of here has been carried clearly off the
    /// ground: outside the outline, and more than `beyond` metres outside it.
    func isOff(_ spot: Spot, beyond: Double = 0.15) -> Bool {
        guard !contains(x: spot.x, z: spot.z) else { return false }
        let length = (spot.x * spot.x + spot.z * spot.z).squareRoot()
        guard length > beyond else { return false }
        let pulled = (length - beyond) / length
        return !contains(x: spot.x * pulled, z: spot.z * pulled)
    }

    /// The ground's edge as it lands on screen, at the ground's own heights.
    func path(in view: Isometric, height: (Spot) -> Double = { _ in 0 }) -> Path {
        var path = Path()
        for (n, spot) in points.enumerated() {
            let point = view.point(spot, y: height(spot))
            if n == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}
