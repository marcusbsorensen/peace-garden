#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// A hedge, the garden's commonest structure: the Long Walk's two runs, the
/// Quiet Garden's enclosure, the Knot Garden's woven bands and the app's plot.
/// One of `Organic`'s structures; the noise it wanders with is in `Organic`.
extension Organic {

    /// A length of hedge as a mesh: soft-shouldered, bulging a little where
    /// it has grown and dipping where it has not, its top an undulating line
    /// and its ends rounded, as a hedge is after years of being cut by hand.
    ///
    /// Stands on `y = 0`, runs along `z`, centred on the origin.
    /// **`domed` is about what happens at the two ends.** A hedge that stops
    /// has a long shoulder falling to the ground, which is what a hedge looks
    /// like where somebody stopped planting, and it is how the Long Walk's two
    /// runs end. A hedge that goes round an enclosure never stops: each of the
    /// four runs carries on into the next, so its ends are cut square and
    /// buried inside its neighbour. Domed ends there leave a notch at every
    /// corner you can see the sky through, because the shoulder falls away over
    /// half the hedge's height — a metre on a two-metre hedge, which no sane
    /// overlap covers.
    ///
    /// **`bow` is how far the middle of the run stands off the straight line
    /// between its two ends**, in metres, toward `x+`. A run that follows a
    /// curve is the difference between a knot and a trellis: the eye follows a
    /// ribbon through a crossing, and a ribbon drawn with a ruler is a grid
    /// however it is woven. The two ends stay where a straight run's ends are,
    /// so a caller bows a run without moving it, and the crossings of a weave
    /// stay where they were put.
    ///
    /// **The line leaves both ends flat**, along the straight line between
    /// them, and does its standing off in the middle. That is what makes a
    /// bowed run join on to its neighbours: a weave is built out of stretches
    /// that meet at the crossings, and a stretch that arrived at a crossing
    /// still turning would meet the next one at a corner, cut its end at a
    /// slant, and leave the two faces of a joint showing. Flat ends mean a
    /// crossing is the one place on the whole run where nothing is happening,
    /// which is where a weave wants its joints and its cuts.
    ///
    /// So the line is `(1 - f²)²` across `f` in -1...1 rather than a circle's
    /// arc — a polynomial, for the reason `quarter` is one: every host has to
    /// get the same bits. It is also the shape a run of clipped box actually
    /// takes between two fixed points, which a circle's arc is not.
    public static func hedge(length: Double, height: Double, thickness: Double,
                             seed: UInt64, domed: Bool = true,
                             bow: Double = 0) -> StructureMesh {
        let rings = max(4, Int((length / 0.06).rounded()))
        let around = 20
        // The ends: narrowing over about a hedge's thickness, and the top
        // rounding down over half its height, so an end is a long shoulder
        // falling to the ground rather than a cut face with a rounded corner.
        let endWide = domed ? min(thickness * 0.8, length / 2) : 0
        let endHigh = domed ? min(max(thickness, height * 0.5), length / 2) : 0
        var mesh = StructureMesh()

        for r in 0...rings {
            let along = -length / 2 + Double(r) / Double(rings) * length
            let fromEnd = min(along + length / 2, length / 2 - along)
            let wide = fromEnd >= endWide ? 1.0 : squareRoot(max(0, 1 - pow2(1 - fromEnd / endWide)))
            let high = fromEnd >= endHigh ? 1.0 : squareRoot(max(0, 1 - pow2(1 - fromEnd / endHigh)))
            let top = height * (1 + 0.08 * wobble(along, wavelength: 0.7, seed: mix64(seed &+ 3)))
            // Where the bowed line is at this ring, how steeply it leans, and
            // the length of (lean, 1) — which turns the section with the line,
            // so the run keeps its thickness the whole way round the bow
            // instead of thinning where it leans hardest.
            let fraction = 2 * along / length               // -1 at one end, +1 at the other
            let hump = 1 - fraction * fraction
            let stands = bow * hump * hump
            let lean = -8 * bow * fraction * hump / length
            let spread = squareRoot(1 + lean * lean)
            for a in 0...around {
                let angle = Double(a) / Double(around)          // 0 at the ground on one face, round over the top, to 1 at the ground on the other
                let (sx, sy, nx, ny) = section(angle, halfWidth: thickness / 2, height: top)
                let bump = 0.035 * wobble(along, angle * 3.2, wavelength: 0.35, seed: seed)
                let side = (sx + nx * bump) * wide
                let y = sy == 0 ? 0 : (sy + ny * bump) * high
                // A run that does not bow is the line it has always been, to
                // the bit: four areas' hedges are drawn by this call and none
                // of them should move because a fifth one curves.
                let (x, z) = bow == 0
                    ? (side, along)
                    : (stands + side / spread, along - side * lean / spread)
                mesh.positions.append(SIMD3<Float>(Float(x), Float(y), Float(z)))
            }
        }
        let stride = around + 1
        for r in 0..<rings {
            for a in 0..<around {
                let i = UInt32(r * stride + a)
                let j = UInt32((r + 1) * stride + a)
                // Wound so the faces, and the normals made from them, point outward.
                mesh.indices.append(contentsOf: [i, i + 1, j, i + 1, j + 1, j])
            }
        }
        mesh.computeNormals()
        return mesh
    }
}
