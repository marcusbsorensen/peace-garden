#if os(WASI)
import FoundationEssentials
import WASILibc
#else
import Foundation
#endif
#if canImport(simd)
import simd
#endif

/// Turns a genome plus a moment in its life into geometry.
///
/// `mesh(growth:)` is pure: the same genome and the same growth state always
/// produce the same vertices, on any device. Per-element jitter is keyed by
/// element index rather than drawn from a running stream, so a leaf keeps its
/// character as later leaves open above it instead of shuffling every time the
/// plant is rebuilt.
public struct PlantBuilder {
    public let genome: Genome

    public init(genome: Genome) {
        self.genome = genome
    }

    public func mesh(growth: GrowthModel.State) -> PlantMesh {
        var builder = MeshBuilder()
        let skeleton = SkeletonBuilder.stem(genome: genome, heightScale: Float(growth.heightScale))

        addStem(&builder, skeleton: skeleton, growth: growth)
        addLeaves(&builder, skeleton: skeleton, growth: growth)
        addBlooms(&builder, skeleton: skeleton, growth: growth)

        return builder.build()
    }

    // MARK: - Stem

    private func addStem(_ builder: inout MeshBuilder, skeleton: PlantSkeleton, growth: GrowthModel.State) {
        builder.addTube(role: .stem, path: skeleton.stem, sides: genome.stem.sides)

        // The stalks of a head, each domed where it leaves the stem.
        //
        // A branch needs the same treatment the foot of the stem gets and for
        // the same reason: `addTube` closes neither end, the material is
        // double-sided, and an open end shows its own lit inside wall. On a
        // join that is worse than on the foot, because there is a stem right
        // there to be seen through the gap.
        for branch in skeleton.branches {
            let base = branch.path[0]
            builder.addTube(role: .stem, path: branch.path, sides: max(4, genome.stem.sides - 2))
            builder.addDome(
                role: .stem,
                centre: base.position,
                axis: -base.tangent,
                side: base.normal,
                radius: base.radius,
                flatten: 0.5,
                rows: 4,
                columns: max(5, genome.stem.sides - 2)
            )
        }

        // The foot of the stem, closed.
        //
        // `addTube` closes neither end, and the material is double-sided, so an
        // open end shows its own lit inside wall and reads as a flat cut. The
        // apex closes itself now — `SkeletonBuilder.apexPoint` runs the radius
        // out to nothing — but the base cannot: a stem is thickest where it
        // meets the ground, so it needs a lid rather than a point.
        //
        // A shallow dome rather than a flat disc, because there is no soil in
        // this scene to bury the join in. It reads as the stem rounding over
        // into ground we are not drawing.
        let foot = skeleton.stem[0]
        builder.addDome(
            role: .stem,
            centre: foot.position,
            axis: -foot.tangent,
            side: foot.normal,
            radius: foot.radius,
            flatten: 0.45,
            rows: 5,
            columns: max(6, genome.stem.sides)
        )

        // The husk the plant came out of. It shrinks away as the shoot takes
        // over rather than vanishing between one frame and the next.
        let husk = Float(((0.25 - growth.heightScale) / 0.23).clamped(to: 0...1))
        if husk > 0.01 {
            // Measured against the shoot as it is now, not against the stem the
            // plant will one day have. `SkeletonBuilder` draws a young stem at a
            // fraction of its final radius, so taking `genome.stem.baseRadius`
            // here made the husk five times the shoot's thickness on the day it
            // was sown — a dome wider than the plant was tall, with the whole
            // sprout hidden inside it.
            let shootRadius = skeleton.stem[0].radius
            let shootLength = Float(genome.stem.height) * Float(growth.heightScale)
            // A seed case sits at the foot of its shoot. Capping it against the
            // shoot's length is what guarantees that, at every age: the husk can
            // never be the tallest thing on the plant.
            let radius = min(shootRadius * 2.4, shootLength * 0.45) * husk
            builder.addDome(
                role: .stem,
                centre: SIMD3<Float>(0, shootRadius * 0.4, 0),
                axis: SIMD3<Float>(0, 1, 0),
                side: SIMD3<Float>(1, 0, 0),
                radius: radius,
                flatten: 0.8,
                rows: 8,
                columns: 12
            )
        }
    }

    // MARK: - Leaves

    private func addLeaves(_ builder: inout MeshBuilder, skeleton: PlantSkeleton, growth: GrowthModel.State) {
        let crown = genome.habit.crownCount
        let onStem = genome.habit.rosette ? 0 : genome.leafCount
        let total = crown + onStem
        guard total > 0, growth.leafUnfurl > 0 else { return }

        // Leaves open from the base upward. The one at the frontier is part
        // grown rather than popping in at full size. The crown is the base, so
        // its leaves are the first out, outermost first.
        let opened = Double(total) * growth.leafUnfurl
        let divergence = Float(genome.foliage.divergence)
        // Leaves grow with the plant rather than arriving full size on a stem
        // that is still a few centimetres tall.
        let vigour = Float(0.45 + 0.55 * growth.heightScale)

        // **A crown leaf that stands up grows as the plant's height does.**
        // Crown leaves open first, and at the stem leaves' `vigour` a young
        // fern — all upright fronds — stood a fifth taller than a young fern
        // did before it had a crown: over the Cold Frame's glass, and level
        // with the Coppice's stars. Tied to the height alone, the opposite
        // went wrong: a young succulent or lotus, whose leaves lie out rather
        // than up, shrank to a few centimetres. So each leaf takes the one
        // growth or the other by how upright it is; see `addCrownLeaf`.
        let upright = Float(0.15 + 0.85 * growth.heightScale)

        for index in 0..<crown {
            let progress = opened - Double(index)
            guard progress > 0 else { return }
            addCrownLeaf(
                &builder, index: index, of: crown, foot: skeleton.stem[0],
                openness: Float(min(1.0, progress)), lying: vigour, upright: upright
            )
        }

        // Stem leaves keep the jitter streams they always had, keyed by their
        // own index rather than by their place in the opening order, so a
        // crown arriving under a plant does not reshuffle the leaves above it.
        for index in 0..<onStem {
            let progress = opened - Double(crown + index)
            guard progress > 0 else { break }
            let openness = Float(min(1.0, progress))

            let nodeIndex = index / max(1, genome.foliage.leavesPerNode)
            guard nodeIndex < skeleton.nodes.count else { break }
            let node = skeleton.nodes[nodeIndex]

            var jitter = SplitMix64(seed: genome.seed, label: "leaf.\(index)")
            let azimuth = divergence * Float(index) + Float(jitter.value(in: -0.12...0.12))
            // A separate stream, so the taper can be added without shifting the
            // azimuth and scale already drawn above it.
            var shape = SplitMix64(seed: genome.seed, label: "leaf.taper.\(index)")
            let scale = openness * vigour
                * Float(jitter.value(in: 0.86...1.14))
                * Self.leafTaper(at: node.t, jitter: &shape)

            // A leaf's age is its own unfurling, held under a ceiling set by
            // how high it sits.
            //
            // The unfurling alone was spent within days: it runs through the
            // leaves fast, so on any plant worth looking at every leaf had
            // reached full maturity and the colour difference had nowhere to
            // show. A plant that is still growing always carries its youngest
            // tissue at the apex — that is where the new leaves come from — so
            // the gradient belongs to position as well as to time, and only
            // then does it survive the plant growing up.
            let ceiling = 1 - 0.6 * min(1, max(0, (node.t - 0.35) / 0.65))
            addLeaf(
                &builder, node: node, azimuth: azimuth,
                scale: scale, maturity: min(openness, ceiling), jitter: &jitter
            )
        }
    }

    /// How large a leaf is for its height up the stem.
    ///
    /// Every leaf being the same size was the loudest thing about a plant. It
    /// is not how anything grows: a stem carries its largest leaves low, where
    /// they have had longest to expand and most light to reach for, and tapers
    /// to small ones under the crown. Even spacing the eye forgives; identical
    /// size at every height it reads immediately as a repeated part.
    ///
    /// The very lowest leaves come back down again, because the first pair a
    /// seedling put out are small and stay small.
    ///
    /// A per-leaf draw on top, wide enough to break the rhythm rather than to
    /// look damaged.
    static func leafTaper(at t: Float, jitter: inout SplitMix64) -> Float {
        let rise = min(1, max(0, t / 0.22))
        let fall = 1 - 0.62 * min(1, max(0, (t - 0.2) / 0.8))
        return rise * fall * Float(jitter.value(in: 0.82...1.2))
    }

    private func addLeaf(
        _ builder: inout MeshBuilder,
        node: PathSample,
        azimuth: Float,
        scale: Float,
        maturity: Float,
        jitter: inout SplitMix64
    ) {
        let foliage = genome.foliage
        let radial = simd_normalize(node.normal * cos(azimuth) + node.binormal * sin(azimuth))
        let pitch = Float(foliage.pitch) + Float(jitter.value(in: -0.1...0.1))
        addBlade(
            &builder,
            origin: node.position + radial * node.radius * 0.8,
            axis: node.tangent,
            radial: radial,
            length: Float(foliage.length * genome.habit.stemLeafScale) * scale,
            pitch: pitch,
            droop: Float(foliage.droop),
            maturity: maturity
        )
    }

    /// One leaf from the crown, at the foot of the stem.
    ///
    /// **Outermost first, and each one in from it smaller and more upright.**
    /// That one rule is a rosette, a fern's vase and a poppy's clump alike: the
    /// oldest leaves have had longest to grow and lie furthest out, the new
    /// ones come up through the middle. The spiral is the golden angle the stem
    /// leaves already use, so a rosette seen from above is a whorl rather than
    /// spokes.
    ///
    /// Laid round the world's up rather than the stem's tangent, because a
    /// leaning stem leans from the crown and the crown itself sits flat on the
    /// ground.
    private func addCrownLeaf(
        _ builder: inout MeshBuilder,
        index: Int,
        of count: Int,
        foot: PathSample,
        openness: Float,
        lying: Float,
        upright: Float
    ) {
        let habit = genome.habit
        // How far in from the outside this leaf is, 0 outermost and 1 at the
        // centre.
        let inward = count > 1 ? Float(index) / Float(count - 1) : 0
        var jitter = SplitMix64(seed: genome.seed, label: "leaf.crown.\(index)")
        let azimuth = Float(genome.foliage.divergence) * Float(index)
            + Float(jitter.value(in: -0.15...0.15))
        let up = SIMD3<Float>(0, 1, 0)
        let radial = SIMD3<Float>(cos(azimuth), 0, sin(azimuth))
        let spread = Float(jitter.value(in: 0.86...1.14))
        // Inner leaves are younger, and a younger leaf is paler.
        let maturity = min(openness, 1 - 0.35 * inward)

        if habit.pads {
            // A pad lies flat, so it grows as a leaf lying out does.
            addPad(
                &builder, foot: foot.position + radial * foot.radius * 0.6,
                radial: radial, inward: inward,
                diameter: Float(habit.crownLength) * (1 - 0.35 * inward) * openness * lying * spread,
                openness: openness, maturity: maturity, jitter: &jitter
            )
            return
        }

        let pitch = Float(habit.crownPitch) * (1 - Float(habit.crownRise) * inward)
            + Float(jitter.value(in: -0.08...0.08))
        // Upright by the cosine of its angle off vertical: a frond standing
        // straight up grows wholly with the height, a leaf lying on the soil
        // wholly as a stem leaf does.
        let standing = max(0, cos(pitch))
        let size = openness * spread * (lying + (upright - lying) * standing)
        let length = Float(habit.crownLength) * (1 - Float(habit.crownTaper) * inward) * size
        // A rosette is stacked rather than flat: each leaf in rises from a
        // little higher on the crown than the one outside it.
        let lift = habit.rosette ? Float(habit.crownLength) * 0.06 * inward * size : 0
        // Crown leaves arch rather than sag — see `addBlade` — by as much as
        // the plant's droop says. A fleshy leaf turns its tip up a little
        // instead, as an echeveria's does; only a little, because a rosette
        // whose every leaf turns up closes into a box.
        //
        // **Held off the ground.** An arch from a crown on the soil turns down
        // toward it, so the turn is capped where the tip comes back to the
        // height it left from: `pitch + arch` no further round than `π - pitch`.
        // Past that the leaf would be drawn through the ground it grows on.
        let turn = habit.fleshiness > 0
            ? -0.18 * Float(habit.fleshiness)
            : Float(genome.foliage.droop) * 1.1
        let arch = min(turn, Float.pi - 2 * pitch - 0.1)
        addBlade(
            &builder,
            origin: foot.position + radial * foot.radius * 0.8 + up * (foot.radius + lift),
            axis: up,
            radial: radial,
            length: length,
            pitch: pitch,
            droop: 0,
            arch: arch,
            pinnae: habit.pinnae,
            maturity: maturity
        )
    }

    /// A lotus pad: round, held flat on its own stalk from the middle of the
    /// blade.
    ///
    /// The outer pads are the broadest and sit lowest, spreading furthest from
    /// the crown; the inner ones stand a little higher and closer in. Close
    /// enough that neighbours overlap, and low enough that they lie over one
    /// another like a water lily's rather than standing up like dishes on a
    /// table — which is what the first pads, held at up to three-quarters of
    /// their own width, looked like.
    private func addPad(
        _ builder: inout MeshBuilder,
        foot: SIMD3<Float>,
        radial: SIMD3<Float>,
        inward: Float,
        diameter: Float,
        openness: Float,
        maturity: Float,
        jitter: inout SplitMix64
    ) {
        guard diameter > 0.002 else { return }
        let up = SIMD3<Float>(0, 1, 0)
        let radius = diameter * 0.5
        let out = diameter * (0.68 - 0.36 * inward) * Float(jitter.value(in: 0.85...1.15))
        let rise = diameter * (0.03 + 0.2 * inward) * Float(jitter.value(in: 0.7...1.3))
        let centre = foot + radial * out + up * rise

        // The stalk climbs first and leans out after, so it meets the pad from
        // below rather than arriving along the ground. A quadratic through a
        // point above the foot does that without a new curve of its own.
        let bend = foot + up * rise * 0.95 + radial * out * 0.15
        let stalkRadius = max(0.0008, diameter * 0.016)
        var positions: [SIMD3<Float>] = []
        var radii: [Float] = []
        for step in 0...8 {
            let t = Float(step) / 8
            let a = foot + (bend - foot) * t
            let b = bend + (centre - bend) * t
            positions.append(a + (b - a) * t)
            radii.append(stalkRadius * (1 - 0.3 * t))
        }
        // A petiole is part of the leaf, and is drawn as one: the same green,
        // unfolding with it.
        builder.addTube(
            role: .leaf,
            path: SkeletonBuilder.transportFrames(positions: positions, radii: radii, twist: 0),
            sides: 5,
            maturity: maturity
        )

        // Tipped a little outward, so the rim away from the crown is the low
        // one, and cupped, so the rim stands above the middle.
        let tilt = Float(jitter.value(in: 0.02...0.1))
        let normal = simd_normalize(up + radial * tilt)
        let forward = simd_normalize(radial - normal * dot(radial, normal))
        let side = simd_normalize(cross(normal, forward))
        let cup = radius * Float(jitter.value(in: 0.04...0.1)) * openness
        let veinDepth = Float(genome.foliage.veinDepth)

        builder.addSurface(role: .leaf, rows: 19, columns: 11, maturity: maturity) { u, v in
            let x = v * 2 - 1
            let width = max(0, 1 - x * x).squareRoot()
            let y = (u * 2 - 1) * width
            let distance = x * x + y * y
            // Faint ribs out from the centre, as a pad's veins run, enough to
            // catch the light without cutting into the round.
            let rib = veinDepth * radius * 0.03 * (u * 2 - 1) * (u * 2 - 1)
            return centre + forward * (x * radius) + side * (y * radius)
                + normal * (cup * distance + rib)
        }
    }

    /// A blade, from `origin`, leaning `pitch` off `axis` toward `radial`.
    ///
    /// Shared by the stem's leaves and the crown's, which differ only in where
    /// they start and which way is up.
    private func addBlade(
        _ builder: inout MeshBuilder,
        origin: SIMD3<Float>,
        axis: SIMD3<Float>,
        radial: SIMD3<Float>,
        length: Float,
        pitch: Float,
        droop: Float,
        arch: Float = 0,
        pinnae: Int = 0,
        maturity: Float
    ) {
        guard length > 0.001 else { return }
        let foliage = genome.foliage

        let forward = simd_normalize(radial * sin(pitch) + axis * cos(pitch))
        // Built from `radial`, which is always perpendicular to the stem, so
        // the frame stays well defined even for a leaf held close to vertical.
        let side = simd_normalize(cross(axis, radial))
        let up = simd_normalize(cross(forward, side))

        let fleshiness = Float(genome.habit.fleshiness)
        // **A fleshy leaf is smooth, and runs out to a point.** The margin's
        // teeth, the veins and the fold are a thin blade's: laid over a
        // swollen one they crumple it, and a rosette of them read as a bowl
        // of screwed-up paper. And a blunt swollen blade reads as a pebble.
        let smooth = max(0, 1 - fleshiness)
        let halfWidth = length * Float(foliage.widthRatio) * 0.5
        let fold = Float(foliage.fold) * (0.3 + 0.7 * smooth)
        let sharpness = max(Float(foliage.tipSharpness), 1.5 * fleshiness)
        // A pinnate frond is the same saw-toothed margin cut nearly to the
        // midrib: 3.6 takes `bladeProfile`'s tooth four-fifths of the way in.
        let serration = pinnae > 0 ? 3.6 : Float(foliage.serration) * smooth
        let teeth = pinnae > 0 ? pinnae : genome.foliage.teeth
        // Three rows to a leaflet, or the cuts alias into a ragged edge.
        let rows = pinnae > 0 ? 3 * pinnae + 4 : 19

        let veinCount = Float(genome.foliage.veinCount)
        let veinDepth = Float(genome.foliage.veinDepth) * smooth

        // Where the midrib is at `s`, and which way the blade's face looks.
        //
        // **A sagging blade is pushed; an arching one turns.** The sag moves
        // each point of a straight midrib off to one side, which is right for
        // a leaf held out from a stem and wrong for a frond: on one that
        // starts near upright the push goes sideways, and past a droop of
        // about 1.3 the blade kinks back over itself — `ArchetypeProfile`'s
        // fern has a paragraph about it. An arch turns the midrib's own
        // direction a little at a time along its length, so its length is its
        // length however far it bends, and it cannot kink. Constant curvature,
        // so the curve is closed-form rather than integrated per vertex.
        func spine(_ s: Float) -> (position: SIMD3<Float>, up: SIMD3<Float>) {
            guard abs(arch) > 1e-3 else {
                // The blade sags under its own length.
                return (forward * (s * length) + up * (-droop * length * s * s * 0.8), up)
            }
            let heading = pitch + arch * s
            let run = length / arch
            let position = radial * (run * (cos(pitch) - cos(heading)))
                + axis * (run * (sin(heading) - sin(pitch)))
            return (position, axis * sin(heading) - radial * cos(heading))
        }

        func point(_ u: Float, _ v: Float, thickness: Float) -> SIMD3<Float> {
            let s = v
            let profile = Self.bladeProfile(s, sharpness: sharpness, serration: serration, teeth: teeth)
            let across = (u - 0.5) * 2 * halfWidth * profile
            // The blade folds into a shallow V.
            let crease = fold * halfWidth * profile * pow(abs(u - 0.5) * 2, 2)
            // Ribs running out from the midrib, deepening toward the margin.
            let vein = veinDepth * halfWidth * 0.14
                * sin(s * .pi * 2 * veinCount) * (abs(u - 0.5) * 2)
            // A fleshy leaf is swollen across its middle and thin at the edge.
            let x = (u - 0.5) * 2
            let swell = thickness * halfWidth * profile * (1 - x * x)
            let (midrib, face) = spine(s)
            return origin + midrib + face * (crease + vein + swell) + side * across
        }

        // More rows than the blade strictly needs, so the teeth and the veins
        // have something to be cut into.
        builder.addSurface(role: .leaf, rows: rows, columns: 9, maturity: maturity) { u, v in
            point(u, v, thickness: 0.7 * fleshiness)
        }
        // **A succulent's leaf has an underside.** One surface bowed upward is
        // still a sheet, and seen edge-on it is a line. A second, bowed the
        // other way and meeting it at the margin, makes the leaf a body.
        if fleshiness > 0 {
            builder.addSurface(role: .leaf, rows: rows, columns: 9, flipWinding: true, maturity: maturity) { u, v in
                point(u, v, thickness: -0.7 * fleshiness)
            }
        }
    }

    // MARK: - Blooms

    /// Where one flower sits on the plant, and the state it is drawn in.
    ///
    /// Three numbers per flower, and none of them survives into the mesh as
    /// anything a reader could recover. `budSwell` and `bloomOpen` become an
    /// angle and a length; `scale` is folded into both. Two flowers a whole
    /// half-cycle apart differ by a few hundred vertices in a plant that has
    /// several thousand — which is why the drift this type exists to catch went
    /// three revisions without anybody noticing.
    struct BloomPlacement: Equatable, Sendable {
        /// The three places a plant carries a flower.
        enum Kind: String, Equatable, Sendable {
            /// The terminal flower, at the growing point. Every flowering plant
            /// has one, and on a young `.head` it is the only one.
            case crown
            /// One at the tip of each stalk of a `.head`.
            case branch
            /// One at each node above `t` 0.35, for the forms that flower up
            /// the stem rather than only at the tip.
            case node
        }

        var kind: Kind
        /// What keys this flower's own noise. Shared with `addBloom`, so two
        /// flowers reported with the same index would be drawn identically.
        var index: Int
        /// Where it sits along the path carrying it: the stem for a node, the
        /// stalk for a branch. `1` at a tip, which is where a crown always is.
        var t: Double
        /// Its own swelling, after the lag, the ceiling and the wave.
        var budSwell: Double
        /// Its own opening, likewise.
        var bloomOpen: Double
        /// How large it is drawn, against a raceme's terminal flower.
        var scale: Double
    }

    /// The wave, reachable from a test.
    ///
    /// `flushFactor` is the whole of the never-bare promise and the whole of
    /// what makes the cycle a wave rather than a pulse, and neither property
    /// can be read back off a finished mesh — a mesh cannot tell a bud from a
    /// small flower. So it is exposed rather than tested through the geometry.
    func flushFactorForTesting(position: Double, growth: GrowthModel.State) -> Double {
        Self.flushFactor(position: position, growth: growth)
    }

    /// Every flower this plant carries, in the order they are drawn.
    ///
    /// Same argument as `flushFactorForTesting`, one level up. A mesh cannot be
    /// asked how open its third flower is, so anything holding the port in
    /// `tools/preview/plant_model.py` to the same answers has to be given the
    /// answers directly — see `PortVectorTests` and `tools/preview/check_port.py`.
    ///
    /// It goes through `forEachBloom`, which is also what `addBlooms` draws
    /// from, so this cannot report one placement and the geometry use another.
    /// A second walk written to be read by a test would be a third
    /// implementation of the thing that has already drifted three times.
    func bloomPlacementsForTesting(growth: GrowthModel.State) -> [BloomPlacement] {
        let skeleton = SkeletonBuilder.stem(genome: genome, heightScale: Float(growth.heightScale))
        var placements: [BloomPlacement] = []
        forEachBloom(skeleton: skeleton, growth: growth) { placement, _ in
            placements.append(placement)
        }
        return placements
    }

    /// One flower's state, with the cycle applied.
    ///
    /// For the flowers that carry no `lag` or `ceiling` of their own — the
    /// crown, and the tip of each stalk on a head — the cycle is the only thing
    /// modulating them, so it is applied to the state whole rather than folded
    /// into an existing expression.
    private static func flushed(_ growth: GrowthModel.State, position: Double) -> GrowthModel.State {
        let factor = flushFactor(position: position, growth: growth)
        guard factor < 1 else { return growth }
        var flushed = growth
        flushed.budSwell *= factor
        flushed.bloomOpen *= factor
        return flushed
    }

    /// How far through its own flowering this flower is, `0...1`.
    ///
    /// **The wave travels up the stem.** A flower peaks when the cycle's phase
    /// reaches its own height, so the band of open flowers climbs and new ones
    /// take over at the crown — which is what an indeterminate inflorescence
    /// does, and the same argument the `lag` and `ceiling` below already make
    /// for the first flowering. This carries it on past maturity instead of
    /// letting it stop there.
    ///
    /// **Nothing ever closes completely**, which is a decision about what this
    /// app means rather than about botany. A real spike goes over and stands
    /// bare between flushes; a plant here stands for a meeting between two
    /// people, and one found bare would read as that meeting having faded. So
    /// the trough is a bud rather than nothing: at full depth a flower out of
    /// phase sits at 45% of what it would otherwise be, which reads as young or
    /// spent rather than absent.
    ///
    /// `position` is the flower's own place in the wave — height up the stem
    /// for a spike, an even share of the cycle for the stalks of a head.
    ///
    /// **Looked at in the app on 4 September, and 0.55 is enough.** A mature
    /// spire sampled at four points around one cycle went from an open star to
    /// a shut bud and back, and the visible change is larger than the number:
    /// the factor takes 55% off `bloomOpen`, and a flower closing loses far
    /// more than 55% of its silhouette. Four times as many petal pixels at the
    /// peak as at the trough, counted rather than judged by eye.
    ///
    /// It has to be looked at **at the plant's own peak hour**, which for a
    /// night-opening genome is one in the morning. `diurnalFactor` damps a
    /// night-opener to a third at midday, and a third of a flush trough is a
    /// plant that appears to be doing nothing at all.

    private static func flushFactor(position: Double, growth: GrowthModel.State) -> Double {
        guard growth.flushDepth > 0 else { return 1 }
        let phase = growth.flush - position
        let wave = 0.5 + 0.5 * cos(2 * Double.pi * phase)
        // Depth is how much the trough takes away. At 0.55 a flower out of
        // phase keeps 45%.
        return 1 - growth.flushDepth * 0.55 * (1 - wave)
    }

    /// Walks the flowers this plant carries, in the order they are drawn.
    ///
    /// Split out of `addBlooms` so that the geometry and
    /// `bloomPlacementsForTesting` read the same walk rather than two walks
    /// that agree today. `body` is non-escaping, so the drawing side can hand
    /// its `inout` builder straight through.
    private func forEachBloom(
        skeleton: PlantSkeleton,
        growth: GrowthModel.State,
        body: (BloomPlacement, PathSample) -> Void
    ) {
        guard genome.bloom.present, growth.budSwell > 0.02 else { return }

        let bloomScale = Float(genome.branching.bloomScale)
        // The crown leads the cycle, so its position in the wave is zero.
        let crown = Self.flushed(growth, position: 0)
        body(
            BloomPlacement(
                kind: .crown, index: 0, t: Double(skeleton.apex.t),
                budSwell: crown.budSwell, bloomOpen: crown.bloomOpen,
                scale: Double(bloomScale)
            ),
            skeleton.apex
        )

        // One bloom at the tip of each stalk.
        //
        // The terminal flower above stays: before the plant is tall enough to
        // divide there are no stalks, so it is the only flower a young head
        // has, and it goes on being the one at the middle of the cluster.
        for (offset, branch) in skeleton.branches.enumerated() {
            guard let tip = branch.path.last else { continue }
            var size = SplitMix64(seed: genome.seed, label: "bloom.size.branch.\(offset)")
            // A head has no up and down to run a wave along, so its stalks take
            // an even share of the cycle instead. Without it every floret in an
            // umbel opens and fades in unison, which is the flat-faced look the
            // per-node lag was written to remove from spikes.
            let position = Double(offset + 1) / Double(skeleton.branches.count + 1)
            let scale = bloomScale * Float(size.value(in: 0.86...1.1))
            let local = Self.flushed(growth, position: position)
            body(
                BloomPlacement(
                    kind: .branch, index: offset + 1, t: Double(tip.t),
                    budSwell: local.budSwell, bloomOpen: local.bloomOpen,
                    scale: Double(scale)
                ),
                tip
            )
        }

        guard genome.bloom.atNodes else { return }
        for (offset, node) in skeleton.nodes.enumerated() where node.t > 0.35 {
            // Lower flowers on a spike open later than the crown, and go on
            // being behind it.
            //
            // The lag used to be spent: it delayed a flower during the opening
            // window and then every flower reached fully open and stayed there,
            // so a mature spike was a column of identical faces. A spike that
            // keeps producing at its tip is never uniform — that is what an
            // indeterminate inflorescence is — so the lag has to survive
            // maturity, and `ceiling` is what makes it.
            let lag = Double(1 - node.t) * 0.5
            // How far open this flower ever gets. The crown reaches full and
            // the lowest on the spike stay half-shut buds for good, which is
            // both what a spike looks like and what makes the smaller flowers
            // read as younger rather than merely scaled down.
            let ceiling = 0.45 + 0.55 * Double(node.t)
            // A flower's place in the wave is where it stands on the stem.
            let flush = Self.flushFactor(position: Double(node.t), growth: growth)
            let budSwell = min(ceiling, max(0, growth.budSwell - lag) / max(0.01, 1 - lag)) * flush
            let bloomOpen = min(ceiling, max(0, growth.bloomOpen - lag) / max(0.01, 1 - lag)) * flush
            guard budSwell > 0.02 else { continue }
            // Every lateral flower was drawn at exactly 0.62, which gave a
            // spire nine identical heads at even spacing — the single strongest
            // tell that a plant had been generated rather than grown. A real
            // spike swells toward its crown and thins away below it.
            var size = SplitMix64(seed: genome.seed, label: "bloom.size.\(offset)")
            let up = min(1, max(0, (Float(node.t) - 0.35) / 0.65))
            let scale = (0.4 + 0.34 * up) * Float(size.value(in: 0.88...1.12))
            // **On its stalk, not on the stem.** Until 27 September 2026 the
            // node's own sample was handed straight on, so the flower was
            // built coaxial with the stem and the stem ran up through it and
            // out the top. `pedicels` is filled in the same order this walks
            // the nodes, so the tip of the one for this node is where the
            // flower stands; if a pedicel was too short to sweep, the flower
            // stays where it was rather than going missing.
            let sample = skeleton.pedicels[offset]?.path.last ?? node
            body(
                BloomPlacement(
                    kind: .node, index: offset + 1, t: Double(node.t),
                    budSwell: budSwell, bloomOpen: bloomOpen, scale: Double(scale)
                ),
                sample
            )
        }
    }

    private func addBlooms(_ builder: inout MeshBuilder, skeleton: PlantSkeleton, growth: GrowthModel.State) {
        // **A stalk is drawn with its flower or not at all.** `forEachBloom`
        // passes over a flower too young to have swelled, and a bare pedicel
        // standing out from the stem is a worse fault than the threaded
        // flower this fixes — a seedling would put out stalks before it put
        // out leaves.
        forEachBloom(skeleton: skeleton, growth: growth) { placement, sample in
            if placement.kind == .node, let pedicel = skeleton.pedicels[placement.index - 1] {
                let base = pedicel.path[0]
                builder.addTube(role: .stem, path: pedicel.path,
                                sides: max(4, self.genome.stem.sides - 2))
                builder.addDome(
                    role: .stem,
                    centre: base.position,
                    axis: -base.tangent,
                    side: base.normal,
                    radius: base.radius,
                    flatten: 0.5,
                    rows: 4,
                    columns: max(5, self.genome.stem.sides - 2)
                )
            }
            // Only the two the placement carries move; a flower's stage, age
            // and phase are the plant's own and are passed through untouched.
            var local = growth
            local.budSwell = placement.budSwell
            local.bloomOpen = placement.bloomOpen
            addBloom(
                &builder,
                at: sample,
                scale: Float(placement.scale),
                growth: local,
                index: placement.index
            )
        }
    }

    private func addBloom(
        _ builder: inout MeshBuilder,
        at sample: PathSample,
        scale: Float,
        growth: GrowthModel.State,
        index: Int
    ) {
        let bloom = genome.bloom
        var jitter = SplitMix64(seed: genome.seed, label: "bloom.\(index)")

        // A nodding head tips away from the stem's axis.
        //
        // The pitch is a genome-wide trait, so before this every head on a
        // spike tipped by exactly the same angle in exactly the same plane and
        // the whole spike leaned as one object. Its own stream, so the existing
        // draws below keep their order.
        var lean = SplitMix64(seed: genome.seed, label: "bloom.lean.\(index)")
        let nodAxis = simd_normalize(cross(sample.tangent, sample.normal))
        let pitch = Float(bloom.headPitch) + Float(lean.value(in: -0.22...0.22))
        let axis = simd_normalize(
            SkeletonBuilder.rotate(sample.tangent, axis: nodAxis, angle: pitch)
        )
        // The bloom is radially symmetric, so any perpendicular pair will do;
        // per-petal jitter supplies the variation, not the starting phase.
        let refA = SkeletonBuilder.arbitraryPerpendicular(to: axis)
        let refB = simd_normalize(cross(axis, refA))

        // Petals stand almost closed as a bud, then swing out as it opens.
        let budScale = Float(0.4 + 0.6 * growth.budSwell)
        let petalLength = Float(bloom.length) * scale * budScale
        guard petalLength > 0.002 else { return }

        let closedAngle: Float = 0.08
        let openAngle = 1.05 + Float(bloom.curl) * 0.35
        let open = closedAngle + (openAngle - closedAngle) * Float(growth.bloomOpen)

        // The flower stands off the tip it grows from, so that a bud is a body
        // rather than a cone closing on a point.
        let origin = sample.position + axis * petalLength * 0.08

        // The receptacle, which is that stand-off closed.
        //
        // Everything the flower is made of is built from `origin`, and the stem
        // or stalk under it ends at `sample.position`. Nothing was drawn across
        // the gap. The sepal collar spanned it — those are laid from
        // `sample.position` for exactly that reason — but `bloom.hasSepals` is
        // a seven-in-ten chance, so three plants in ten had an open join.
        //
        // It went unnoticed because it is usually covered by accident. The
        // centre's rim is a flat circle several times wider than the stand-off
        // is tall, so on an upright head it overhangs the tip and the stalk
        // reads as disappearing behind the flower. A head that nods far enough
        // carries that rim away sideways and leaves the join in the open.
        //
        // The same answer the foot of the stem and the base of every stalk
        // already take: a shallow dome in the stem's own material. It rises
        // along `axis` rather than along the stem's tangent, because that is
        // the line the stand-off was taken along — so it spans the gap at every
        // angle a head can nod to. Narrower than the centre above it, so it is
        // inside the flower's own footprint and is never the thing you see.
        builder.addDome(
            role: .stem,
            centre: sample.position,
            axis: axis,
            side: refA,
            radius: petalLength * 0.10,
            flatten: 0.9,
            rows: 4,
            columns: max(5, genome.stem.sides - 2)
        )

        // **The centre is a third of a petal at most, and the petals stand on
        // its rim.** It was sized by the gene alone — `centreRadius` times 1.6,
        // so a lotus's reached nine-tenths of a petal — and centred on the
        // one point every petal sprang from, so the petals pierced it and its
        // rim hung outside them: the ring under every flower in the garden.
        // Capped here rather than in the gene, so the gene still orders centres
        // from small to large and nothing about a seed's draw changes. The
        // petals start at nine-tenths of the rim, and are shortened by half of
        // that, so the flower is as wide as it was.
        let centreRadius = min(petalLength * Float(bloom.centreRadius) * 1.6, petalLength * 0.34)
        let baseRing = centreRadius * 0.9
        let perLayer = max(3, bloom.petalCount)

        for layer in 0..<max(1, bloom.layers) {
            let layerFraction = Float(layer) / Float(max(1, bloom.layers))
            let layerScale = 1.0 - layerFraction * 0.28
            let layerOpen = open * (1.0 - layerFraction * 0.35)

            for petal in 0..<perLayer {
                let azimuth = 2 * .pi * (Float(petal) + 0.5 * Float(layer)) / Float(perLayer)
                    + Float(bloom.twist) * layerFraction
                var petalJitter = SplitMix64(seed: genome.seed, label: "petal.\(index).\(layer).\(petal)")
                addPetal(
                    &builder,
                    origin: origin,
                    axis: axis,
                    refA: refA,
                    refB: refB,
                    azimuth: azimuth + Float(petalJitter.value(in: -0.05...0.05)),
                    open: layerOpen,
                    length: (petalLength - baseRing * 0.5) * layerScale
                        * Float(petalJitter.value(in: 0.92...1.08)),
                    bloomOpen: Float(growth.bloomOpen),
                    // Inner layers stand a little further in, so they rise
                    // from inside the outer ones rather than through them.
                    baseRing: baseRing * (1 - layerFraction * 0.3)
                )
            }
        }

        builder.addDome(
            role: .centre,
            centre: origin,
            axis: axis,
            side: refA,
            radius: centreRadius,
            flatten: 0.55 + Float(jitter.unit()) * 0.4,
            rows: 8,
            columns: 14,
            maturity: Float(growth.bloomOpen)
        )

        if growth.bloomOpen > 0.3, bloom.stamenCount > 0 {
            addStamens(
                &builder,
                origin: origin,
                axis: axis,
                refA: refA,
                refB: refB,
                radius: centreRadius,
                length: petalLength * 0.42 * Float(growth.bloomOpen)
            )
        }

        if bloom.hasPistil, growth.bloomOpen > 0.25 {
            addPistil(
                &builder,
                origin: origin,
                axis: axis,
                side: refA,
                radius: centreRadius,
                length: petalLength * 0.55 * Float(growth.bloomOpen)
            )
        }

        let rim = addCalyx(
            &builder, origin: origin, axis: axis, side: refA,
            centreRadius: centreRadius, petalLength: petalLength
        )

        // The sepals, present from the bud onward — they are what wrapped the
        // petals before they opened. A bell always has its five; everyone
        // else has them where `bloom.hasSepals` drew them, and carries them
        // the way the family does.
        let sepals = bloom.sepals
        let count = sepals == .spreading ? 5 : bloom.sepalCount
        guard count > 0, sepals != .none else { return }
        let cupSide = origin - axis * rim.depth * 0.25
        switch sepals {
        case .none:
            break
        case .reflexed:
            // From partway down the cup, past a right angle to the axis, so
            // they fold back down the stem.
            addSepals(
                &builder, count: count, origin: origin - axis * rim.depth * 0.6, ring: rim.radius * 0.7,
                axis: axis, refA: refA, refB: refB, pitch: 1.75...2.25,
                length: petalLength * 0.5, width: petalLength * 0.2, curve: -0.25
            )
        case .spreading:
            addSepals(
                &builder, count: count, origin: cupSide, ring: rim.radius * 0.95,
                axis: axis, refA: refA, refB: refB, pitch: 1.0...1.3,
                length: petalLength * 0.42, width: petalLength * 0.07, curve: -0.1
            )
        case .appressed:
            // Short, and held up close under the petals, curving in to them.
            addSepals(
                &builder, count: count, origin: cupSide, ring: rim.radius * 0.95,
                axis: axis, refA: refA, refB: refB, pitch: 0.55...0.8,
                length: petalLength * 0.28, width: petalLength * 0.13, curve: 0.12
            )
        }
    }

    /// The closed body under a flower, from a little way down its stalk to just
    /// outside the centre's rim, where it turns in underneath it.
    ///
    /// **Closed, so nothing is hollow from any side.** It starts from a point
    /// on the stalk and ends tucked under the centre, and the centre's dome
    /// covers the rest, so the flower is one body and the web's two-sided
    /// lighting has no inside to show. Its normals face out: it is a surface
    /// of revolution taken clockwise, which `addSurface` reads as outward.
    ///
    /// Returns the rim's radius and the cup's depth, for the sepals.
    private func addCalyx(
        _ builder: inout MeshBuilder,
        origin: SIMD3<Float>,
        axis: SIMD3<Float>,
        side: SIMD3<Float>,
        centreRadius: Float,
        petalLength: Float
    ) -> (radius: Float, depth: Float) {
        let up = simd_normalize(axis)
        let right = simd_normalize(side - up * dot(side, up))
        let forward = cross(up, right)
        let calyx = genome.bloom.calyx

        let role: MeshRole
        let rim: Float
        let depth: Float
        // How fast the profile widens from its foot: below 1 a bowl, above 1
        // a stalk flaring at the top.
        let flare: Float
        switch calyx {
        case .lid:
            role = .stem; rim = centreRadius * 0.92; depth = petalLength * 0.1; flare = 0.5
        case .swelling:
            role = .stem; rim = centreRadius * 0.92; depth = petalLength * 0.22; flare = 1.6
        case .stalk:
            role = .stem; rim = centreRadius * 0.92; depth = petalLength * 0.45; flare = 2.2
        case .cup:
            role = .calyx; rim = centreRadius * 1.04
            depth = max(petalLength * 0.14, rim * 0.45); flare = 0.55
        case .shallowCup:
            role = .calyx; rim = centreRadius * 1.08; depth = rim * 0.32; flare = 0.45
        case .urn:
            role = .calyx; rim = centreRadius * 1.04; depth = rim * 1.5; flare = 1
        }
        let base = origin - up * depth
        let tuck = centreRadius * 0.85
        // The lip sits just under the petals' bases, so they rest on it
        // rather than fighting it for the same plane.
        let lip = depth - centreRadius * 0.04

        let urn = calyx == .urn
        builder.addSurface(role: role, rows: urn ? 25 : 11, columns: urn ? 25 : 17) { u, v in
            let azimuth = -u * 2 * .pi
            var radius: Float
            var height: Float
            if v < 0.82 {
                let s = v / 0.82
                height = lip * s
                if urn {
                    // Swells to a fifth past the rim two-thirds of the way up,
                    // then draws in to it: an urn tapering into the stalk.
                    let belly = rim * 1.2
                    radius = s < 0.68
                        ? belly * sin(.pi * 0.5 * s / 0.68)
                        : belly + (rim - belly) * ((s - 0.68) / 0.32)
                    // Scales: rows of bracts overlapping upward, each flaring at
                    // its tip, and alternate columns half a row out of step.
                    let column = Int(u * 12)
                    let row = s * 6 + (column % 2 == 0 ? 0 : 0.5)
                    radius *= 1 + 0.09 * (row - row.rounded(.down)) * s
                } else {
                    radius = rim * pow(s, flare)
                }
            } else {
                // Over the rim and in under the centre.
                let w = (v - 0.82) / 0.18
                height = lip
                radius = rim + (tuck - rim) * w
            }
            return base + up * height + right * (radius * cos(azimuth)) + forward * (radius * sin(azimuth))
        }
        return (rim, depth)
    }

    /// A whorl of short green blades round the cup.
    ///
    /// `pitch` is the angle off the flower's axis: past a right angle they
    /// fold back down the stalk, well under one they stand up against the
    /// petals. `curve` bends each one along its length, back for negative.
    private func addSepals(
        _ builder: inout MeshBuilder,
        count: Int,
        origin: SIMD3<Float>,
        ring: Float,
        axis: SIMD3<Float>,
        refA: SIMD3<Float>,
        refB: SIMD3<Float>,
        pitch: ClosedRange<Double>,
        length: Float,
        width: Float,
        curve: Float
    ) {
        guard length > 0.002 else { return }

        for index in 0..<count {
            var jitter = SplitMix64(seed: genome.seed, label: "sepal.\(index)")
            let azimuth = 2 * .pi * Float(index) / Float(count) + Float(jitter.value(in: -0.1...0.1))
            let radial = simd_normalize(refA * cos(azimuth) + refB * sin(azimuth))
            let angle = Float(jitter.value(in: pitch))
            let forward = simd_normalize(radial * sin(angle) + axis * cos(angle))
            let side = simd_normalize(cross(axis, radial))
            let up = simd_normalize(cross(forward, side))
            let halfWidth = width * 0.5
            let start = origin + radial * ring

            builder.addSurface(role: .calyx, rows: 7, columns: 5) { u, v in
                let profile = Self.bladeProfile(v, sharpness: 1.3, serration: 0, teeth: 0)
                let across = (u - 0.5) * 2 * halfWidth * profile
                let bend = curve * length * v * v
                return start + forward * (v * length) + up * bend + side * across
            }
        }
    }

    /// The column at the flower's centre, standing above the stamens.
    private func addPistil(
        _ builder: inout MeshBuilder,
        origin: SIMD3<Float>,
        axis: SIMD3<Float>,
        side: SIMD3<Float>,
        radius: Float,
        length: Float
    ) {
        guard length > 0.002 else { return }
        let stalkRadius = max(0.0008, length * 0.055)
        let tip = origin + axis * (radius * 0.4 + length)
        let base = origin + axis * radius * 0.3

        let samples = SkeletonBuilder.transportFrames(
            positions: [base, (base + tip) * 0.5, tip],
            radii: [stalkRadius, stalkRadius * 0.9, stalkRadius * 0.75],
            twist: 0
        )
        builder.addTube(role: .stamen, path: samples, sides: 5)
        builder.addDome(
            role: .stamen,
            centre: tip,
            axis: axis,
            side: side,
            radius: stalkRadius * 2.2,
            flatten: 1.0,
            rows: 5,
            columns: 10
        )
    }

    private func addPetal(
        _ builder: inout MeshBuilder,
        origin: SIMD3<Float>,
        axis: SIMD3<Float>,
        refA: SIMD3<Float>,
        refB: SIMD3<Float>,
        azimuth: Float,
        open: Float,
        length: Float,
        bloomOpen: Float,
        baseRing: Float
    ) {
        let bloom = genome.bloom
        let radial = simd_normalize(refA * cos(azimuth) + refB * sin(azimuth))
        // Each petal leaves the centre's rim, not its middle.
        let origin = origin + radial * baseRing
        let forward = simd_normalize(radial * sin(open) + axis * cos(open))
        let side = simd_normalize(cross(axis, radial))
        let up = simd_normalize(cross(side, forward))

        let halfWidth = length * Float(bloom.widthRatio) * 0.5
        // A closed bud cups inward whatever the genome says; the plant's own
        // curl only takes over as the flower opens.
        let curl = Float(bloom.curl) * bloomOpen - (1 - bloomOpen) * 0.7
        let twist = Float(bloom.twist)
        let sharpness = Float(bloom.tipSharpness)

        let notch = Float(bloom.notch)
        let rounded = bloom.outline == .rounded
        let crumple = Float(bloom.crumple)
        // Where the creases fall, from the petal's own place round the flower,
        // so no two petals of a poppy are creased alike and no draw is spent.
        let creasePhase = azimuth * 2.7

        // **Seventeen rows, drawn in toward the tip.** Thirteen evenly spaced
        // rows made a petal's edge a polygon of twelve straight sides, and the
        // last of them closed on the tip in one straight cut, which is where a
        // round end has all its curve. `petalRow` spaces them so the rows fall
        // evenly round the end rather than along the midrib.
        builder.addSurface(role: .petal, rows: 17, columns: 9, maturity: bloomOpen) { u, v in
            let s = Self.petalRow(v)
            let profile = rounded
                ? Self.petalProfile(s, sharpness: sharpness)
                : Self.bladeProfile(s, sharpness: sharpness, serration: 0, teeth: 0)
            let x = (u - 0.5) * 2
            let across = x * halfWidth * profile
            let bend = curl * length * s * s * 0.75
            // A round petal is dished a little across its width, its edges
            // turned in toward the flower's middle, as a petal is and a blade
            // is not. It is also what makes the round end read as round from
            // the side, where a flat one is a line.
            let dish = rounded ? -0.22 * halfWidth * profile * x * x : 0
            // Creased silk: two soft waves at an angle to the midrib, stronger
            // toward the edge and the tip, where a poppy's petal is thinnest.
            let crease = crumple == 0 ? 0 : crumple * halfWidth * profile * 0.12 * (0.35 + 0.65 * abs(x)) * s
                * (0.6 * sin(.pi * (3 * s + 1.2 * x) + creasePhase)
                   + 0.4 * sin(.pi * (5 * s - 0.9 * x) + 2 * creasePhase))
            let twistAngle = twist * s
            let localSide = side * cos(twistAngle) + up * sin(twistAngle)
            let localUp = up * cos(twistAngle) - side * sin(twistAngle)
            // A cleft cut into the very tip, dying away toward the base.
            let cleft = notch * length * 0.2 * exp(-pow(x * 2.5, 2)) * pow(s, 6)
            return origin + forward * (s * length - cleft) + localSide * across
                + localUp * (bend + dish + crease)
        }
    }

    private func addStamens(
        _ builder: inout MeshBuilder,
        origin: SIMD3<Float>,
        axis: SIMD3<Float>,
        refA: SIMD3<Float>,
        refB: SIMD3<Float>,
        radius: Float,
        length: Float
    ) {
        let count = genome.bloom.stamenCount
        guard count > 0, length > 0.001 else { return }
        let filamentRadius = max(0.0006, length * 0.035)

        for index in 0..<count {
            var jitter = SplitMix64(seed: genome.seed, label: "stamen.\(index)")
            let azimuth = 2 * .pi * Float(index) / Float(count) + Float(jitter.value(in: -0.2...0.2))
            let radial = simd_normalize(refA * cos(azimuth) + refB * sin(azimuth))
            let lean = Float(jitter.value(in: 0.15...0.5))
            let direction = simd_normalize(axis + radial * lean)
            let base = origin + radial * radius * 0.55 + axis * radius * 0.35
            let tip = base + direction * length

            let samples = SkeletonBuilder.transportFrames(
                positions: [base, base + direction * length * 0.5, tip],
                radii: [filamentRadius, filamentRadius * 0.85, filamentRadius * 0.7],
                twist: 0
            )
            builder.addTube(role: .stamen, path: samples, sides: 4)
            builder.addDome(
                role: .stamen,
                centre: tip,
                axis: direction,
                side: radial,
                radius: filamentRadius * 2.6,
                flatten: 1.0,
                rows: 5,
                columns: 8
            )
        }
    }

    // MARK: - Petal outline

    /// How far along a petal row `v` of its grid stands, `0` at the base and
    /// `1` at the tip: `v + v² − v³`.
    ///
    /// Even at the base, closest together at the tip, and smooth between, so
    /// no step in the spacing shows. Near the tip what is left of the petal
    /// goes as the square of what is left of the grid, which is what spaces
    /// the rows evenly round a round end: there the width goes as the square
    /// root of what is left of the petal. The length along the midrib is the
    /// petal's length whatever this does, since only where the rows fall moves.
    static func petalRow(_ v: Float) -> Float {
        v + v * v - v * v * v
    }

    /// Width of a round petal at `s` along its length, `0` at the base, `1`
    /// at its widest and `0` at the tip, with no corner anywhere between.
    ///
    /// From a narrow claw it widens on a quarter sine to its widest point, and
    /// closes from there on a quarter of a superellipse, whose tangent at the
    /// tip is square to the midrib: a round end, never a point. The tip gene,
    /// which drew a lens out into a needle, says instead how round: at its
    /// bluntest the widest point stands at 0.62 of the petal and the end is
    /// fuller than a circle; at its sharpest the widest point is at 0.48 and the
    /// end an oval running to a soft point. The widest is as wide as the lens's
    /// was, so a flower's petals are no wider for it, only fuller at the end.
    static func petalProfile(_ s: Float, sharpness: Float) -> Float {
        let k = max(0, min(1, (sharpness - 0.6) / 1.8))
        let widest = 0.62 - 0.14 * k
        let fullness = 2.6 - 0.8 * k
        let s = max(0, min(1, s))
        if s <= widest {
            return pow(sin(.pi * 0.5 * s / widest), 0.8)
        }
        let t = (s - widest) / (1 - widest)
        return pow(max(0, 1 - pow(t, fullness)), 1 / fullness)
    }

    // MARK: - Shared profile

    /// Width of a blade at `s` along its length, `0` at both ends.
    ///
    /// `sharpness` above 1 pulls the widest point down and draws the tip out.
    /// `serration` cuts the margin into `teeth` — a sawtooth rather than a
    /// sine, because a leaf's teeth lean toward the tip instead of scalloping
    /// evenly in and out.
    static func bladeProfile(_ s: Float, sharpness: Float, serration: Float, teeth: Int) -> Float {
        let base = sin(.pi * pow(max(0, min(1, s)), 0.7))
        let shaped = pow(max(0, base), max(0.3, sharpness))
        guard serration > 0, teeth > 0 else { return shaped }
        let phase = s * Float(teeth)
        let sawtooth = phase - floor(phase)
        return shaped * (1 - serration * 0.22 * pow(sawtooth, 1.5))
    }
}
