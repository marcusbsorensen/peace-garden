import Foundation
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

        // The husk the plant came out of. It shrinks away as the shoot takes
        // over rather than vanishing between one frame and the next.
        let husk = Float(((0.25 - growth.heightScale) / 0.23).clamped(to: 0...1))
        if husk > 0.01 {
            builder.addDome(
                role: .stem,
                centre: SIMD3<Float>(0, Float(genome.stem.baseRadius) * 0.4, 0),
                axis: SIMD3<Float>(0, 1, 0),
                side: SIMD3<Float>(1, 0, 0),
                radius: Float(genome.stem.baseRadius) * 2.4 * husk,
                flatten: 0.8,
                rows: 8,
                columns: 12
            )
        }
    }

    // MARK: - Leaves

    private func addLeaves(_ builder: inout MeshBuilder, skeleton: PlantSkeleton, growth: GrowthModel.State) {
        let total = genome.leafCount
        guard total > 0, growth.leafUnfurl > 0 else { return }

        // Leaves open from the base upward. The one at the frontier is part
        // grown rather than popping in at full size.
        let opened = Double(total) * growth.leafUnfurl
        let divergence = Float(genome.foliage.divergence)
        // Leaves grow with the plant rather than arriving full size on a stem
        // that is still a few centimetres tall.
        let vigour = Float(0.45 + 0.55 * growth.heightScale)

        for index in 0..<total {
            let progress = opened - Double(index)
            guard progress > 0 else { break }
            let openness = Float(min(1.0, progress))

            let nodeIndex = index / max(1, genome.foliage.leavesPerNode)
            guard nodeIndex < skeleton.nodes.count else { break }
            let node = skeleton.nodes[nodeIndex]

            var jitter = SplitMix64(seed: genome.seed, label: "leaf.\(index)")
            let azimuth = divergence * Float(index) + Float(jitter.value(in: -0.12...0.12))
            let scale = openness * vigour * Float(jitter.value(in: 0.86...1.14))

            addLeaf(&builder, node: node, azimuth: azimuth, scale: scale, jitter: &jitter)
        }
    }

    private func addLeaf(
        _ builder: inout MeshBuilder,
        node: PathSample,
        azimuth: Float,
        scale: Float,
        jitter: inout SplitMix64
    ) {
        let foliage = genome.foliage
        let length = Float(foliage.length) * scale
        guard length > 0.001 else { return }

        let axis = node.tangent
        let radial = simd_normalize(node.normal * cos(azimuth) + node.binormal * sin(azimuth))
        let pitch = Float(foliage.pitch) + Float(jitter.value(in: -0.1...0.1))
        let forward = simd_normalize(radial * sin(pitch) + axis * cos(pitch))
        // Built from `radial`, which is always perpendicular to the stem, so
        // the frame stays well defined even for a leaf held close to vertical.
        let side = simd_normalize(cross(axis, radial))
        let up = simd_normalize(cross(forward, side))
        let origin = node.position + radial * node.radius * 0.8

        let halfWidth = length * Float(foliage.widthRatio) * 0.5
        let droop = Float(foliage.droop)
        let fold = Float(foliage.fold)
        let sharpness = Float(foliage.tipSharpness)
        let serration = Float(foliage.serration)

        let teeth = genome.foliage.teeth
        let veinCount = Float(genome.foliage.veinCount)
        let veinDepth = Float(genome.foliage.veinDepth)

        // More rows than the blade strictly needs, so the teeth and the veins
        // have something to be cut into.
        builder.addSurface(role: .leaf, rows: 19, columns: 9) { u, v in
            let s = v
            let profile = Self.bladeProfile(s, sharpness: sharpness, serration: serration, teeth: teeth)
            let across = (u - 0.5) * 2 * halfWidth * profile
            // The blade sags under its own length, and folds into a shallow V.
            let sag = -droop * length * s * s * 0.8
            let crease = fold * halfWidth * profile * pow(abs(u - 0.5) * 2, 2)
            // Ribs running out from the midrib, deepening toward the margin.
            let vein = veinDepth * halfWidth * 0.14
                * sin(s * .pi * 2 * veinCount) * (abs(u - 0.5) * 2)
            return origin + forward * (s * length) + up * (sag + crease + vein) + side * across
        }
    }

    // MARK: - Blooms

    private func addBlooms(_ builder: inout MeshBuilder, skeleton: PlantSkeleton, growth: GrowthModel.State) {
        guard genome.bloom.present, growth.budSwell > 0.02 else { return }

        addBloom(&builder, at: skeleton.apex, scale: 1.0, growth: growth, index: 0)

        guard genome.bloom.atNodes else { return }
        for (offset, node) in skeleton.nodes.enumerated() where node.t > 0.35 {
            // Lower flowers on a spike open later than the crown.
            let lag = Double(1 - node.t) * 0.5
            let localGrowth = GrowthModel.State(
                stage: growth.stage,
                stageProgress: growth.stageProgress,
                overall: growth.overall,
                heightScale: growth.heightScale,
                leafUnfurl: growth.leafUnfurl,
                budSwell: max(0, growth.budSwell - lag) / max(0.01, 1 - lag),
                bloomOpen: max(0, growth.bloomOpen - lag) / max(0.01, 1 - lag),
                age: growth.age,
                timeToNextStage: growth.timeToNextStage
            )
            guard localGrowth.budSwell > 0.02 else { continue }
            addBloom(&builder, at: node, scale: 0.62, growth: localGrowth, index: offset + 1)
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
        let nodAxis = simd_normalize(cross(sample.tangent, sample.normal))
        let axis = simd_normalize(
            SkeletonBuilder.rotate(sample.tangent, axis: nodAxis, angle: Float(bloom.headPitch))
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

        let origin = sample.position + axis * petalLength * 0.08
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
                    length: petalLength * layerScale * Float(petalJitter.value(in: 0.92...1.08)),
                    bloomOpen: Float(growth.bloomOpen)
                )
            }
        }

        let centreRadius = petalLength * Float(bloom.centreRadius) * 1.6
        builder.addDome(
            role: .centre,
            centre: origin,
            axis: axis,
            side: refA,
            radius: centreRadius,
            flatten: 0.55 + Float(jitter.unit()) * 0.4,
            rows: 8,
            columns: 14
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

        // The green collar under the flower, present from the bud onward — it
        // is what wrapped the petals before they opened.
        if bloom.sepalCount > 0 {
            addSepals(
                &builder,
                origin: sample.position,
                axis: axis,
                refA: refA,
                refB: refB,
                length: petalLength * 0.5,
                width: petalLength * 0.2
            )
        }
    }

    /// A whorl of short green blades, swept back beneath the petals.
    private func addSepals(
        _ builder: inout MeshBuilder,
        origin: SIMD3<Float>,
        axis: SIMD3<Float>,
        refA: SIMD3<Float>,
        refB: SIMD3<Float>,
        length: Float,
        width: Float
    ) {
        guard length > 0.002 else { return }
        let count = genome.bloom.sepalCount

        for index in 0..<count {
            var jitter = SplitMix64(seed: genome.seed, label: "sepal.\(index)")
            let azimuth = 2 * .pi * Float(index) / Float(count) + Float(jitter.value(in: -0.1...0.1))
            let radial = simd_normalize(refA * cos(azimuth) + refB * sin(azimuth))
            // Past a right angle to the axis, so they fold back down the stem.
            let pitch = Float(jitter.value(in: 1.75...2.25))
            let forward = simd_normalize(radial * sin(pitch) + axis * cos(pitch))
            let side = simd_normalize(cross(axis, radial))
            let up = simd_normalize(cross(forward, side))
            let halfWidth = width * 0.5

            builder.addSurface(role: .leaf, rows: 7, columns: 5) { u, v in
                let profile = Self.bladeProfile(v, sharpness: 1.3, serration: 0, teeth: 0)
                let across = (u - 0.5) * 2 * halfWidth * profile
                let curve = -0.25 * length * v * v
                return origin + forward * (v * length) + up * curve + side * across
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
        bloomOpen: Float
    ) {
        let bloom = genome.bloom
        let radial = simd_normalize(refA * cos(azimuth) + refB * sin(azimuth))
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

        builder.addSurface(role: .petal, rows: 13, columns: 9) { u, v in
            let s = v
            let profile = Self.bladeProfile(s, sharpness: sharpness, serration: 0, teeth: 0)
            let across = (u - 0.5) * 2 * halfWidth * profile
            let bend = curl * length * s * s * 0.75
            let twistAngle = twist * s
            let localSide = side * cos(twistAngle) + up * sin(twistAngle)
            let localUp = up * cos(twistAngle) - side * sin(twistAngle)
            // A cleft cut into the very tip, dying away toward the base.
            let cleft = notch * length * 0.2 * exp(-pow((u - 0.5) * 5, 2)) * pow(s, 6)
            return origin + forward * (s * length - cleft) + localSide * across + localUp * bend
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
