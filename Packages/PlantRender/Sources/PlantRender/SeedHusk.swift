import SceneKit
import SeedCore
import simd

/// The seed case a plant comes out of, in two halves that part.
///
/// SeedCore draws a husk of its own, and it is the right husk for the job it
/// does: it is measured against the shoot as it is, which is the cap that
/// stopped a newborn plant coming out as a mushroom. The consequence is that it
/// shrinks *with* the shoot, so at the sizes an arrival plays at there is never
/// a seed sitting there — only a smaller and smaller version of the same
/// sprout. Rendering the range and looking at it is what settled that.
///
/// This is the other thing: a seed with a size of its own, which opens and is
/// then gone. It exists for six seconds on one day, so it belongs to the room
/// the plant stands in rather than to the plant, and it lives here rather than
/// in the core.
final class SeedHusk {
    /// Add this to the scene. It holds both halves, so the pair can be given to
    /// the turntable and turn together with the plant.
    let node = SCNNode()

    private let upper = SCNNode()
    private let lower = SCNNode()

    /// Taller than it is wide. At 1.0 a seed reads as a bead, and anywhere near
    /// it a seed reads as a boulder — width is what makes something look heavy.
    static let elongation: Float = 1.45

    /// How far the seed is pushed down, as a fraction of its own half-height.
    /// Enough that the cup's rim is under the foot of the shoot rather than
    /// around it, so a shoot two centimetres tall stands in the open instead of
    /// down a well.
    static let sink: Float = 0.25

    /// No seed is smaller than this, whatever plant it holds.
    ///
    /// `SkeletonBuilder` floors a stem at a centimetre and the arrival starts
    /// below that, so the shortest shoot the app can draw is a centimetre tall
    /// however far the height is wound back. A seed that cannot cover a
    /// centimetre has a spike coming out of the top of it before it opens —
    /// which is what the thinnest-stemmed plants got, and only those.
    static let smallestHalfHeight: Float = 0.019

    /// Half the height of the closed seed — what the camera has to frame.
    ///
    /// Measured against the stem the plant will grow, which is the only thing
    /// in a genome that says how substantial the plant is going to be at all.
    static func halfHeight(for genome: Genome) -> Float {
        max(smallestHalfHeight, Float(genome.stem.baseRadius) * 1.75 * elongation)
    }

    static func radius(for genome: Genome) -> Float {
        halfHeight(for: genome) / elongation
    }

    private let radius: Float

    init(genome: Genome) {
        radius = Self.radius(for: genome)

        // The seam is horizontal and stays horizontal: a seed sown in the
        // ground splits along its middle and the shoot pushes the top off. The
        // lid hinges at its own rim so it tips as it goes rather than lifting
        // off level, which is a lid on a jar.
        upper.geometry = Self.half(radius: radius, pointing: 1)
        // The lid is lit from both sides and the cup from one. Tipped back, a
        // single-sided lid is culled down to its own silhouette and hangs over
        // the shoot as a thin wire crescent; a double-sided cup shows the
        // inside of its far wall as a band of stripes across the one thing
        // anybody is looking at. Each half wants the opposite answer.
        upper.geometry?.firstMaterial = Self.material(for: genome, doubleSided: true)

        lower.geometry = Self.half(radius: radius, pointing: -1)
        lower.geometry?.firstMaterial = Self.material(for: genome, doubleSided: false)

        // Sunk, so that the shoot stands clear of the cup rather than down
        // inside it. Sitting on the surface with its equator at the plant's own
        // origin, the seed buries the first two centimetres of shoot — which is
        // the whole shoot — in a bowl. Dropped, the split happens at about
        // where the ground would be, which is where it happens.
        node.position = SCNVector3(0, -Self.halfHeight(for: genome) * Self.sink, 0)

        node.addChildNode(upper)
        node.addChildNode(lower)
        apply(open: 0)
    }

    /// - Parameter open: `0` is a closed seed; `1` is a lid gone and a cup
    ///   faded into the dark.
    ///
    /// The two halves do very different things, which is the whole reason this
    /// reads as germination rather than as a locket. The **lid** is pushed off:
    /// it tips, then rides up and away and out of the light. The **cup** stays
    /// where it was put and only fades, because that is what a seed case in the
    /// ground does — it stays there and rots, and this is the polite version.
    func apply(open: Double) {
        let t = Float(min(max(open, 0), 1))

        // The tip happens early and finishes early. Everything after it is the
        // lid travelling, so the moment of *opening* is over well before the
        // moment of leaving, and the two do not compete.
        let tip = Self.smoothstep(min(t / 0.42, 1))
        let travel = Self.smoothstep(max((t - 0.30) / 0.70, 0))

        upper.eulerAngles = SCNVector3(-tip * 0.72, 0, 0)
        upper.position = SCNVector3(
            0,
            travel * radius * 4.6,
            -radius + travel * radius * 1.1
        )

        // The lid goes first and the cup outlasts it, so there is always
        // something of the seed left while the shoot is still short.
        upper.opacity = CGFloat(1 - Self.smoothstep(max((t - 0.55) / 0.45, 0)))
        lower.opacity = CGFloat(1 - Self.smoothstep(max((t - 0.74) / 0.26, 0)))
        node.isHidden = t >= 1
    }

    private static func smoothstep(_ t: Float) -> Float {
        let x = min(max(t, 0), 1)
        return x * x * (3 - 2 * x)
    }

    // MARK: - Geometry

    /// One half, as a dome around the vertical. `pointing` is `1` for the lid
    /// and `-1` for the cup.
    private static func half(radius: Float, pointing: Float) -> SCNGeometry? {
        var builder = MeshBuilder()
        builder.addDome(
            role: .stem,
            centre: .zero,
            axis: SIMD3<Float>(0, pointing, 0),
            side: SIMD3<Float>(1, 0, 0),
            radius: radius,
            flatten: elongation,
            rows: 14,
            columns: 22
        )
        guard let part = builder.build().parts.first, !part.indices.isEmpty else { return nil }
        return PlantSceneBuilder.geometry(for: part)
    }

    /// A seed coat is the plant's own colour with the life taken out of it:
    /// pulled most of the way toward a dry brown, darkened, and matte. It is
    /// still recognisably of the same plant, which is the point — this is the
    /// thing that plant came out of.
    private static func material(for genome: Genome, doubleSided: Bool) -> SCNMaterial {
        let stem = PaletteRamp.colour(for: .stem, u: 0.5, v: 0, palette: genome.palette)

        // The short way round the wheel, as everywhere else a hue is blended.
        let brown = 0.085
        var delta = brown - stem.hue
        if delta > 0.5 { delta -= 1 }
        if delta < -0.5 { delta += 1 }
        var hue = (stem.hue + delta * 0.72).truncatingRemainder(dividingBy: 1)
        if hue < 0 { hue += 1 }

        // Held to absolute values rather than scaled off the stem's. Scaled,
        // a pale plant produced a pale seed, and a pale seed at this size is a
        // boulder — the plant has to stay the brightest thing on the screen
        // even on the one screen where it is two centimetres tall.
        let coat = HSB(
            hue: hue,
            saturation: 0.30 + stem.saturation * 0.18,
            brightness: 0.15 + stem.brightness * 0.10
        )

        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = GradientTexture.colour(coat)
        material.roughness.contents = NSNumber(value: 0.94)
        material.metalness.contents = NSNumber(value: 0.0)
        material.isDoubleSided = doubleSided
        return material
    }
}
