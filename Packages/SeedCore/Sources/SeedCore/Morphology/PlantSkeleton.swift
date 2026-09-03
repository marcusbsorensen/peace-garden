import Foundation
#if canImport(simd)
import simd
#endif

/// One station along a swept path: where it is, which way it points, and how
/// thick the plant is there.
public struct PathSample: Sendable {
    public var position: SIMD3<Float>
    public var tangent: SIMD3<Float>
    public var normal: SIMD3<Float>
    public var binormal: SIMD3<Float>
    public var radius: Float
    /// Position along the path, `0` at the base and `1` at the tip.
    public var t: Float
}

/// A stalk given off the main stem, carrying one bloom at its tip.
public struct Branch: Sendable {
    /// Where it leaves the main stem.
    public var origin: PathSample
    /// Its own swept path, base to tip.
    public var path: [PathSample]
}

/// The stem, its leaf nodes, its tip, and any stalks it gives off.
public struct PlantSkeleton: Sendable {
    public var stem: [PathSample]
    public var nodes: [PathSample]
    public var apex: PathSample
    /// Empty for `.raceme` and `.solitary`.
    ///
    /// Empty rather than optional, so every consumer walks the same list and
    /// the two unbranched forms need no special case.
    public var branches: [Branch] = []
}

public enum SkeletonBuilder {
    /// Grows the stem for a genome at a given height fraction.
    ///
    /// The curve is integrated step by step rather than evaluated from a
    /// formula, because lean, sway and twist compound along the stem — the same
    /// way a real one accumulates its shape as it grows.
    public static func stem(genome: Genome, heightScale: Float, segments: Int = 28) -> PlantSkeleton {
        let length = max(0.01, Float(genome.stem.height) * heightScale)
        let step = length / Float(segments)
        let leanPerStep = Float(genome.stem.lean) * 0.9 / Float(segments)
        let swayAmplitude = Float(genome.stem.sway) * 0.8
        // A young stem is thin as well as short. Holding the radius at its
        // final value makes a seedling look like a cut-off post.
        let baseRadius = Float(genome.stem.baseRadius) * (0.4 + 0.6 * heightScale)
        let taper = Float(genome.stem.taper)
        let coilTurn = crozierTurn(heightScale: heightScale)
        // A growing point is a few stem-diameters long. Measured as a fraction
        // of the stem instead, it grows with the plant — and on a spire, whose
        // profile is 1.35 times everything else's, a fifth of the stem is a
        // whisker standing well above the leaves.
        let pointSpan = min(0.16, max(0.045, baseRadius * 5 / length))

        var positions: [SIMD3<Float>] = [.zero]
        var radii: [Float] = [baseRadius]
        var direction = SIMD3<Float>(0, 1, 0)
        var position = SIMD3<Float>.zero

        for index in 1...segments {
            let t = Float(index) / Float(segments)
            // Lean tips the whole stem one way; sway waves it back and forth.
            let lean = leanPerStep * (0.6 + 0.8 * t)
            let sway = swayAmplitude * cos(t * .pi * 2.2) / Float(segments)
            // The crozier bends about the same axis as the lean, so a leaning
            // stem relaxes *into* its lean rather than fighting it: one
            // continuous bend from base to growing point.
            direction = rotate(direction, axis: SIMD3<Float>(0, 0, 1),
                               angle: lean + coilStep(at: t, turn: coilTurn, segments: segments))
            direction = rotate(direction, axis: SIMD3<Float>(1, 0, 0), angle: sway)
            direction = simd_normalize(direction)
            position += direction * step
            positions.append(position)
            radii.append(baseRadius * (1 - (1 - taper) * t) * apexPoint(t, span: pointSpan))
        }

        let samples = transportFrames(
            positions: positions,
            radii: radii,
            twist: Float(genome.stem.twist)
        )

        let nodeCount = genome.stem.nodeCount
        var nodes: [PathSample] = []
        nodes.reserveCapacity(nodeCount)
        for index in 0..<nodeCount {
            let fraction: Float = nodeCount == 1
                ? 0.55
                : 0.16 + 0.74 * Float(index) / Float(nodeCount - 1)
            let sampleIndex = min(samples.count - 1, Int((fraction * Float(samples.count - 1)).rounded()))
            nodes.append(samples[sampleIndex])
        }

        return PlantSkeleton(
            stem: samples,
            nodes: nodes,
            apex: samples[samples.count - 1],
            branches: branches(
                genome: genome,
                stem: samples,
                heightScale: heightScale,
                stemLength: length,
                taper: taper
            )
        )
    }

    // MARK: - Branches

    /// The stalks a `.head` gives off its upper stem, each ending in a bloom.
    ///
    /// Every stalk is integrated step by step, the way the stem itself is, so
    /// that its curve accumulates. The alternative — drawing one path and
    /// scaling it per stalk — changes a stalk's curvature with its length, and
    /// a head stops looking flat the moment that happens.
    static func branches(
        genome: Genome,
        stem samples: [PathSample],
        heightScale: Float,
        stemLength: Float,
        taper: Float
    ) -> [Branch] {
        let branching = genome.branching
        guard branching.inflorescence == .head, branching.count > 0, samples.count >= 2 else {
            return []
        }

        // A head opens outward as the plant grows into it. Below this there is
        // no upper stem to give stalks off, and a young `.head` plant is drawn
        // as a raceme that has not divided yet — which is what one is.
        let vigour = smoothstep(0.25, 0.7, heightScale)
        guard vigour > 0.001 else { return [] }

        let spread = Float(branching.spread)
        let apex = samples[samples.count - 1]
        // Where along the stem the stalks leave it. A flat-topped head gives
        // them all off within a short stretch near the top; a spray gives them
        // off over half the stem, and that alone is most of what separates the
        // two silhouettes.
        let zoneStart = 0.78 - 0.33 * spread
        let zoneEnd: Float = 0.95
        let divergence = Float(genome.foliage.divergence)
        let baseAngle = Float(branching.angle)

        var branches: [Branch] = []
        branches.reserveCapacity(branching.count)

        for index in 0..<branching.count {
            let fraction: Float = branching.count == 1
                ? 0.5
                : Float(index) / Float(branching.count - 1)
            let t = zoneStart + (zoneEnd - zoneStart) * fraction
            let sampleIndex = min(samples.count - 1, Int((t * Float(samples.count - 1)).rounded()))
            let origin = samples[sampleIndex]

            var jitter = SplitMix64(seed: genome.seed, label: "branch.\(index)")
            // Stalks are set out on the same golden-angle divergence the leaves
            // use, so they spiral round the stem rather than lining up in a
            // plane and reading as a fan seen edge-on.
            let azimuth = divergence * Float(index)
            let radial = simd_normalize(
                origin.normal * cos(azimuth) + origin.binormal * sin(azimuth)
            )

            // How far the stalk leans off the stem. The jitter widens with
            // spread: a flat-topped head is uniform, and a spray is not.
            let angle = (baseAngle + Float(jitter.value(in: -0.3...0.3)) * (0.2 + 0.8 * spread))
                * vigour

            // The height the tip is aiming for.
            //
            // At spread 0 every tip aims at the same height, and that levelling
            // is the whole reason a flat-topped head reads as flat rather than
            // as a bundle: a stalk leaving the stem lower down simply has
            // further to climb and comes out longer. Scatter the target and the
            // same rule gives a spray — still longer stalks low down, but no
            // table across the top.
            let climb = max(0, apex.position.y - origin.position.y)
            let targetY = apex.position.y
                + spread * climb * Float(jitter.value(in: -0.5...0.5))

            // The `stemLength` term is what keeps the topmost stalk from
            // vanishing: it has almost no height to climb, so without a floor
            // it would terminate the moment it left the stem.
            let reach = min(stemLength * 0.7, climb * 2.4 + stemLength * 0.2) * vigour
            guard reach > stemLength * 0.002 else { continue }

            let path = sweep(
                from: origin,
                radial: radial,
                angle: angle,
                targetY: targetY,
                reach: reach,
                levelling: 0.85 * (1 - 0.55 * spread),
                taper: taper
            )
            guard path.count >= 3 else { continue }
            branches.append(Branch(origin: origin, path: path))
        }
        return branches
    }

    /// One stalk, integrated out and up until its tip reaches `targetY`.
    ///
    /// The direction turns from its outward start toward vertical along the
    /// stalk, and the position accumulates from it a step at a time. Where the
    /// stalk *stops* is solved rather than drawn: it runs until it crosses the
    /// target height, so its length is whatever reaching that height costs from
    /// where it started.
    private static func sweep(
        from origin: PathSample,
        radial: SIMD3<Float>,
        angle: Float,
        targetY: Float,
        reach: Float,
        levelling: Float,
        taper: Float
    ) -> [PathSample] {
        let segments = 14
        let step = reach / Float(segments)
        // A third of its reach before the target can stop it, so a stalk is
        // never a stub — and so every stalk has enough samples to sweep a tube.
        let minimum = reach * 0.34
        let up = SIMD3<Float>(0, 1, 0)
        let start = simd_normalize(origin.tangent * cos(angle) + radial * sin(angle))

        var position = origin.position + radial * origin.radius * 0.6
        var positions: [SIMD3<Float>] = [position]
        var travelled: Float = 0

        for index in 1...segments {
            let s = Float(index) / Float(segments)
            // Turning from the initial direction rather than from the previous
            // one, so a stalk that has been cut short by the target height has
            // the same curvature as the stretch of a longer one beside it.
            let turn = levelling * pow(s, 1.45)
            let direction = simd_normalize(start * (1 - turn) + up * turn)
            let previous = position
            position += direction * step
            travelled += step
            positions.append(position)
            guard travelled >= minimum, position.y >= targetY else { continue }
            // Stop *at* the crossing rather than at the sample after it.
            //
            // Landing on an integration step quantises the tip: as the stalk
            // lengthens with the plant, the step it stops on jumps from one to
            // the next and the whole head snaps outward by a step. It is a
            // couple of per cent of the plant, it happens while somebody is
            // watching the head open, and `testAHeadDividesGradually…` is what
            // found it — no render at any single age could have.
            let rise = position.y - previous.y
            if rise > 1e-6 {
                let crossing = (targetY - previous.y) / rise
                positions[positions.count - 1] = previous
                    + (position - previous) * min(1, max(0, crossing))
                travelled -= step * (1 - min(1, max(0, crossing)))
            }
            break
        }

        // A stalk is a stem, and ends like one: it leaves the axis at a
        // fraction of its thickness and runs out to a point through the same
        // ogive the stem's own tip uses.
        let base = origin.radius * 0.45
        let span = min(0.2, max(0.06, base * 5 / max(0.0001, travelled)))
        let last = Float(positions.count - 1)
        let radii = positions.indices.map { index -> Float in
            let s = Float(index) / last
            return base * (1 - (1 - taper) * s) * apexPoint(s, span: span)
        }
        return transportFrames(positions: positions, radii: radii, twist: 0)
    }

    // MARK: - The growing point

    /// How much of its full thickness the stem still has at `t`.
    ///
    /// `genome.stem.taper` is drawn from `0.16...0.86`, so on its own it leaves
    /// the apex somewhere between a sixth and most of the base width — a
    /// cylinder that gets narrower and then stops. Since
    /// `MeshBuilder.addTube` closes neither end and the plant material is
    /// double-sided, what that showed was the lit inside wall of the tube seen
    /// through its own opening, which shades exactly like a flat disc.
    ///
    /// A shoot apex is the finest tissue on the plant — it is the meristem,
    /// where the growing happens — so the last stretch runs out to nothing.
    /// That closes the tube as well: the final ring collapses to a point, and
    /// there is no hole left to look into.
    ///
    /// An ogive rather than a cone, because a growing point is drawn out rather
    /// than chamfered: the profile leaves the stem tangentially and only turns
    /// in at the very end.
    ///
    /// `span` is how much of the stem the point takes, and the caller sizes it
    /// against the stem's *thickness* rather than its length. A fixed fraction
    /// looks right on one plant and wrong on the next: the same fifth-of-a-stem
    /// that is a tidy point on a lotus is a whisker on a spire.
    static func apexPoint(_ t: Float, span: Float) -> Float {
        let start = 1 - span
        guard t > start else { return 1 }
        let s = (t - start) / span
        // Clamped before the root, because `1 - (1 - span)` does not round back
        // to `span`. At the last sample `t` is exactly 1, so `s` comes out a few
        // parts in ten million over it, `1 - s * s` goes negative, and the
        // square root of that is a NaN in the one vertex at the very tip of
        // every plant in the garden. `PlantMeshTests` caught it; it is invisible
        // on screen until something downstream divides by a normal.
        return max(0, 1 - s * s).squareRoot()
    }

    /// The total turn a young shoot's coiled tip carries, in radians.
    ///
    /// A shoot comes up with its growing point curled over and opens as it
    /// grows into it. It is also the gesture the rest of the app is drawn
    /// with — `Tendril` under a plant's name is a fiddlehead relaxing, and the
    /// app mark is an unwinding spiral — so the plant itself arrives carrying
    /// it.
    ///
    /// Gone by the time the plant is half its height, which is the point: the
    /// coil belongs to the moment somebody meets their plant, and a grown one
    /// is exactly as it was before this existed.
    static func crozierTurn(heightScale: Float) -> Float {
        // `heightScale` floors at 0.055 the moment a seed is sown and eases out
        // to 1, so the window is measured from there rather than from zero.
        let unfurl = smoothstep(0.06, 0.5, heightScale)
        // A little under a full turn at its tightest. Past this the tip begins
        // to curl back into the stem it grew from.
        return 1.6 * .pi * (1 - unfurl)
    }

    /// The coil's share of one integration step.
    ///
    /// The turn accumulates as `s^1.7` toward the tip — the same easing
    /// `Tendril` uses — so the shoot leaves the ground almost straight and
    /// keeps the curl at the growing end. This is its derivative, which is what
    /// a step-by-step integration needs.
    private static func coilStep(at t: Float, turn: Float, segments: Int) -> Float {
        // The bottom third stays upright, or the shoot has nothing to stand on.
        let start: Float = 0.35
        guard turn > 0, t > start else { return 0 }
        let span = 1 - start
        let s = (t - start) / span
        return turn * 1.7 * pow(s, 0.7) / (Float(segments) * span)
    }

    private static func smoothstep(_ edge0: Float, _ edge1: Float, _ x: Float) -> Float {
        // `clamped(to:)` in this package is a `Double` helper, and reaching for
        // it here silently resolves to `Duration`'s.
        let t = min(1, max(0, (x - edge0) / (edge1 - edge0)))
        return t * t * (3 - 2 * t)
    }

    /// Rotation-minimising frames.
    ///
    /// A naive up-vector frame flips when the stem passes vertical and makes
    /// leaves jump round the stem; carrying the previous frame forward through
    /// the tangent's rotation avoids that.
    static func transportFrames(
        positions: [SIMD3<Float>],
        radii: [Float],
        twist: Float
    ) -> [PathSample] {
        guard positions.count >= 2 else { return [] }

        var tangents: [SIMD3<Float>] = []
        tangents.reserveCapacity(positions.count)
        for index in positions.indices {
            let previous = positions[max(0, index - 1)]
            let next = positions[min(positions.count - 1, index + 1)]
            let delta = next - previous
            tangents.append(simd_length_squared(delta) < 1e-12 ? SIMD3<Float>(0, 1, 0) : simd_normalize(delta))
        }

        var normal = arbitraryPerpendicular(to: tangents[0])
        var samples: [PathSample] = []
        samples.reserveCapacity(positions.count)

        for index in positions.indices {
            if index > 0 {
                normal = rotate(normal, from: tangents[index - 1], to: tangents[index])
                // Re-orthogonalise: floating point drift accumulates over a
                // couple of dozen segments and shows up as a twisted stem.
                normal = normal - tangents[index] * dot(normal, tangents[index])
                let lengthSquared = simd_length_squared(normal)
                normal = lengthSquared < 1e-12
                    ? arbitraryPerpendicular(to: tangents[index])
                    : simd_normalize(normal)
            }

            let t = Float(index) / Float(positions.count - 1)
            let twisted = rotate(normal, axis: tangents[index], angle: twist * t)
            samples.append(
                PathSample(
                    position: positions[index],
                    tangent: tangents[index],
                    normal: twisted,
                    binormal: simd_normalize(cross(tangents[index], twisted)),
                    radius: radii[min(radii.count - 1, index)],
                    t: t
                )
            )
        }
        return samples
    }

    static func arbitraryPerpendicular(to vector: SIMD3<Float>) -> SIMD3<Float> {
        let reference = abs(vector.y) > 0.9 ? SIMD3<Float>(1, 0, 0) : SIMD3<Float>(0, 1, 0)
        return simd_normalize(cross(vector, reference))
    }

    static func rotate(_ vector: SIMD3<Float>, axis: SIMD3<Float>, angle: Float) -> SIMD3<Float> {
        guard abs(angle) > 1e-7 else { return vector }
        return simd_quatf(angle: angle, axis: simd_normalize(axis)).act(vector)
    }

    static func rotate(_ vector: SIMD3<Float>, from: SIMD3<Float>, to: SIMD3<Float>) -> SIMD3<Float> {
        let axis = cross(from, to)
        let sine = simd_length(axis)
        guard sine > 1e-7 else { return vector }
        let angle = atan2(sine, dot(from, to))
        return simd_quatf(angle: angle, axis: axis / sine).act(vector)
    }
}
