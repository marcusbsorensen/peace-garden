#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// An orchard tree. One of `Organic`'s structures; the noise it wanders with
/// is in `Organic`.
extension Organic {

    /// An orchard tree: a trunk that leans and a canopy that is not a ball. It
    /// stands on `y = 0`, centred on the origin, and is the tallest thing in the
    /// Orchard by a clear margin over anything a gardener can grow.
    ///
    /// **Grown rather than sawn**, which puts it on the hedge's side of the line
    /// the bench is on the other side of. The trunk wanders as it rises and the
    /// canopy is lumpy at two scales, because a tree drawn as a cylinder under a
    /// sphere is the clip art `docs/WEB-GARDENS.md` warns about, and no amount
    /// of good colour rescues it.
    ///
    /// **The canopy's roughness is sampled in space, not in angle.** Perturbing
    /// a ring by its angle leaves a seam where the angle wraps from one to zero;
    /// perturbing it by where the vertex actually is cannot, because the ring
    /// closes in space and so does the noise. The same trick does the trunk. It
    /// is why there is no `seamless` call here although the roundel beside it
    /// needs one — the roundel's noise runs *along* its edge, and this runs
    /// across a surface the edge lies on.
    ///
    /// **The canopy's underside clears the planting beneath it, completely.**
    /// A guild stands `Orchard.guildRadius` from the trunk, which is exactly the
    /// canopy's widest radius, so a guild plant stands at the drip line with the
    /// whole canopy above it — its lower surface there is 2.5 m up and the
    /// tallest plant this garden grows is 2.2 m.
    ///
    /// **It was not so at the first size tried.** A 1.7 m spread on a 1.55 m
    /// crown put the canopies so low and so close that they covered the planting
    /// from every angle, which fails the one thing this area is for: an orchard
    /// where you cannot see the guild is five trees. Lifting the crown and
    /// drawing it narrower leaves a clear 0.9 m between neighbouring canopies
    /// and every plant in open view.
    ///
    /// **The crown sits at 2.10 m rather than the 1.95 m that looked enough.**
    /// At 1.95 the lumpiness pulled the canopy's underside down to 2.24 m over
    /// the guild — clear of a 2.2 m plant by four centimetres, and *not* clear
    /// of the 2.35 m one the Crossing's three hundred threw up. The clearance is
    /// checked in `OrganicTests` against that 2.35 rather than against the
    /// tallest plant anybody has happened to grow.
    public static func tree(height: Double = 3.25, spread: Double = 1.5,
                            crownBase: Double = 2.10, seed: UInt64) -> StructureMesh {
        let around = 14
        let trunkRings = 12
        // **Coarse on purpose.** The first canopy was drawn at thirty segments
        // and twenty rings, and at that fineness it took one smooth highlight
        // and read as a green balloon on a stick — the roundel's mistake in
        // leaf. A canopy is clumps of foliage, so its faces have to be big
        // enough to be clumps: eighteen by twelve gives facets a few
        // centimetres across, which is the size a bunch of leaves is.
        let segments = 24
        let rings = 16
        let halfSpread = spread / 2
        let crownTop = max(crownBase + 0.4, height)
        let canopy = crownTop - crownBase
        var mesh = StructureMesh()

        /// How far the trunk's axis has wandered off plumb by this height. It is
        /// held to zero at the ground, so the tree is planted rather than
        /// floating, and the canopy rides the same wander so that no join shows.
        func lean(_ y: Double) -> (x: Double, z: Double) {
            let ramp = min(1, y / max(0.25, crownBase * 0.7))
            let reach = 0.07 * ramp * ramp
            return (reach * wobble(y, wavelength: 1.9, seed: mix64(seed &+ 5)),
                    reach * wobble(y, wavelength: 1.9, seed: mix64(seed &+ 6)))
        }

        /// Two scales of lumpiness, read from where a vertex is rather than from
        /// how far round it is.
        ///
        /// **The first octave is nearly as broad as the tree**, which is what
        /// makes a canopy lopsided rather than merely bumpy. The second is a
        /// third of that, for the lobes inside it. Drawn the other way round —
        /// both octaves short — the canopy stayed a sphere with a texture on it,
        /// and a sphere with a texture on it is still a sphere.
        func rough(_ x: Double, _ y: Double, _ z: Double) -> Double {
            0.66 * wobble(x, z, wavelength: 1.35, seed: seed)
                + 0.34 * wobble(z * 1.25, y * 1.7, wavelength: 0.48, seed: mix64(seed &+ 7))
        }

        // The trunk, from the ground to a little way into the canopy so that
        // nothing can open between the two.
        let trunkTop = crownBase + canopy * 0.22
        for r in 0...trunkRings {
            let t = Double(r) / Double(trunkRings)
            let y = t * trunkTop
            let axis = lean(y)
            // Thick at the foot, where a tree flares into its roots, and evenly
            // slimmer above it.
            let flare = t < 0.12 ? 1 + 0.9 * pow2(1 - t / 0.12) : 1
            let radius = (0.125 - 0.052 * t) * flare
            for a in 0...around {
                let (cx, cz) = circle(Double(a) / Double(around))
                let px = axis.x + radius * cx, pz = axis.z + radius * cz
                let bark = 1 + 0.11 * rough(px * 2.4, y * 2.4, pz * 2.4)
                mesh.positions.append(SIMD3<Float>(
                    Float(axis.x + radius * cx * bark),
                    Float(y),
                    Float(axis.z + radius * cz * bark)
                ))
            }
        }
        let trunkStride = around + 1
        for r in 0..<trunkRings {
            for a in 0..<around {
                let i = UInt32(r * trunkStride + a), j = UInt32((r + 1) * trunkStride + a)
                // Wound the opposite way round from the roundel's, because this
                // surface stands up where that one lies flat: the same order
                // that points a disc's faces at the sky points a cylinder's into
                // its own middle.
                mesh.indices.append(contentsOf: [i, j, i + 1, i + 1, j, j + 1])
            }
        }

        // The canopy: an ellipsoid on the trunk's own axis, pulled about.
        let base = UInt32(mesh.positions.count)
        for r in 0...rings {
            let t = Double(r) / Double(rings)
            let y = crownBase + t * canopy
            let axis = lean(y)
            let profile = squareRoot(max(0, 1 - pow2(2 * t - 1)))
            for a in 0...segments {
                let (cx, cz) = circle(Double(a) / Double(segments))
                let ideal = halfSpread * profile
                let px = axis.x + ideal * cx, pz = axis.z + ideal * cz
                // The lumpiness fades out at the two poles with the profile
                // itself, or a radius of nothing would be pulled into a spike.
                // **0.55, not the 0.20 the first pass used.** `wobble` is in
                // -1...1 but value noise only touches its ends: a typical
                // reading is about a third of the range, so a coefficient set
                // by the range gives a third of the lumpiness it looks like it
                // asks for. 0.20 drew a ball. This is a canopy a third of its
                // own radius out of true, which is about what a fruit tree is.
                let out = ideal + 0.55 * profile * rough(px, y, pz)
                mesh.positions.append(SIMD3<Float>(
                    Float(axis.x + out * cx),
                    Float(y),
                    Float(axis.z + out * cz)
                ))
            }
        }
        let stride = segments + 1
        for r in 0..<rings {
            for a in 0..<segments {
                let i = base + UInt32(r * stride + a), j = base + UInt32((r + 1) * stride + a)
                mesh.indices.append(contentsOf: [i, j, i + 1, i + 1, j, j + 1])
            }
        }

        mesh.computeNormals()

        // **The two poles are one point held by `segments + 1` vertices**, and
        // `computeNormals` gives each of them only the faces it happens to
        // touch — which draws a star of slightly different greens at the top of
        // every tree, the canopy's own mesh showing through exactly as the
        // roundel's rings once did. One averaged normal for the ring puts it
        // right, and it is the only place in this mesh where a vertex's normal
        // is not simply what its faces say.
        for ring in [0, rings] {
            let start = Int(base) + ring * stride
            guard mesh.normals.count >= start + stride else { continue }
            var sum = SIMD3<Float>(0, 0, 0)
            for a in 0...segments { sum += mesh.normals[start + a] }
            let length = (sum.x * sum.x + sum.y * sum.y + sum.z * sum.z).squareRoot()
            guard length > 0 else { continue }
            let unit = sum / length
            for a in 0...segments { mesh.normals[start + a] = unit }
        }
        return mesh
    }
}
