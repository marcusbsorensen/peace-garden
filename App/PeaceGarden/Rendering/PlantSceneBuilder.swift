import SceneKit
import SeedCore
import simd

/// Turns `PlantMesh` buffers into a SceneKit node, and builds the room the
/// plant stands in.
///
/// The core hands over plain vertex buffers, so this file is the only part that
/// knows about SceneKit. Moving to RealityKit later means rewriting this file
/// and nothing else.
enum PlantSceneBuilder {

    // MARK: - Geometry

    static func node(for mesh: PlantMesh, palette: Genome.Palette) -> SCNNode {
        let node = SCNNode()
        for part in mesh.parts where !part.indices.isEmpty {
            let child = SCNNode(geometry: geometry(for: part, palette: palette))
            child.name = part.role.rawValue
            node.addChildNode(child)
        }
        return node
    }

    static func geometry(for part: PlantMesh.Part, palette: Genome.Palette) -> SCNGeometry {
        let geometry = geometry(for: part)
        geometry.firstMaterial = material(for: part.role, palette: palette)
        return geometry
    }

    /// The buffers alone, with whatever material SceneKit defaults to. Split out
    /// so that geometry which is not part of the plant — the seed case it comes
    /// out of — can be built by the same code without borrowing a plant's
    /// material for a surface that is not made of plant.
    static func geometry(for part: PlantMesh.Part) -> SCNGeometry {
        let vertices = part.positions.map { SCNVector3($0.x, $0.y, $0.z) }
        let normals = part.normals.map { SCNVector3($0.x, $0.y, $0.z) }
        let coordinates = part.uvs.map { CGPoint(x: CGFloat($0.x), y: CGFloat($0.y)) }

        let element = SCNGeometryElement(
            indices: part.indices.map { Int32($0) },
            primitiveType: .triangles
        )
        var sources = [
            SCNGeometrySource(vertices: vertices),
            SCNGeometrySource(normals: normals),
            SCNGeometrySource(textureCoordinates: coordinates)
        ]
        if let age = maturitySource(part.maturity, vertexCount: vertices.count) {
            sources.append(age)
        }
        return SCNGeometry(sources: sources, elements: [element])
    }

    /// Every vertex's own age, carried as a second set of texture coordinates.
    ///
    /// Not a texture coordinate and not sampled by anything — it is simply the
    /// one per-vertex channel that reaches a shader modifier untouched. The
    /// colour semantic was tried first and is wrong: SceneKit multiplies vertex
    /// colour into the diffuse on its own, before any modifier runs, so a value
    /// meaning *age* in the red channel painted the whole plant red, stem
    /// included. Nothing consumes a spare texcoord set uninvited.
    ///
    /// Only `x` carries anything; the pair is what the semantic wants.
    private static func maturitySource(_ maturity: [Float], vertexCount: Int) -> SCNGeometrySource? {
        guard maturity.count == vertexCount, vertexCount > 0 else { return nil }
        var packed = [SIMD2<Float>]()
        packed.reserveCapacity(vertexCount)
        for value in maturity {
            packed.append(SIMD2<Float>(min(1, max(0, value)), 0))
        }
        let data = packed.withUnsafeBufferPointer { Data(buffer: $0) }
        return SCNGeometrySource(
            data: data,
            semantic: .texcoord,
            vectorCount: vertexCount,
            usesFloatComponents: true,
            componentsPerVector: 2,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<SIMD2<Float>>.stride
        )
    }

    static func material(for role: MeshRole, palette: Genome.Palette) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        // Falls back to a flat colour if the texture could not be made, rather
        // than leaving the material white.
        material.diffuse.contents = GradientTexture.image(for: role, palette: palette)
            ?? GradientTexture.colour(PaletteRamp.colour(for: role, u: 0.5, v: 0.5, palette: palette))
        material.metalness.contents = NSNumber(value: 0.0)

        // Relief and gloss, from the same bake as the colour. Between them they
        // are what stops a surface reading as a moulded panel: the normal map
        // gives the light something to travel over, and the roughness map means
        // a vein can shine while the tissue beside it stays matte.
        //
        // Both fall back to the scalar the material used before them, so a
        // texture that could not be built costs the detail and nothing else.
        material.normal.contents = GradientTexture.normalImage(for: role, palette: palette)
        material.roughness.contents = GradientTexture.roughnessImage(for: role, palette: palette)
            ?? NSNumber(value: scalarRoughness(for: role, palette: palette))

        // Clamping matters on every channel, not only the colour: a normal map
        // that repeats puts a seam of inverted lighting down the edge of a blade.
        for property in [material.diffuse, material.normal, material.roughness] {
            property.wrapS = .clamp
            property.wrapT = .clamp
        }

        material.shaderModifiers = agingModifier(for: role)

        switch role {
        case .stem:
            break
        case .leaf:
            // Leaves and petals are single surfaces with no thickness, so they
            // have to be lit from both sides or they vanish when they turn away.
            material.isDoubleSided = true
        case .petal:
            material.isDoubleSided = true
            material.emission.contents = GradientTexture.colour(palette.petalTip, alpha: 1)
            material.emission.intensity = CGFloat(palette.glow * 0.16)
        case .centre:
            material.emission.contents = GradientTexture.colour(palette.centre, alpha: 1)
            material.emission.intensity = CGFloat(0.1 + palette.glow * 0.35)
        case .stamen:
            material.emission.contents = GradientTexture.colour(palette.centre, alpha: 1)
            material.emission.intensity = CGFloat(0.15 + palette.glow * 0.3)
        }
        return material
    }

    /// Tints a surface toward the colour it was when it was younger.
    ///
    /// A texture is shared by every leaf on a plant, so the age difference
    /// between a leaf at the frontier and one at the base cannot live in it.
    /// The mesh carries each vertex's own maturity instead and this reads it.
    ///
    /// What it does is the pigment story, not a fade: a new leaf has not
    /// finished laying down chlorophyll, so it is paler, yellower and much less
    /// saturated than the same leaf a fortnight later; a petal in bud is
    /// greener and duller at the back, and its colour arrives as it opens. Both
    /// are a move toward the young end rather than a change of hue.
    ///
    /// Two entry points, because a vertex attribute has to be carried across
    /// into the fragment stage by hand.
    private static func agingModifier(for role: MeshRole) -> [SCNShaderModifierEntryPoint: String]? {
        guard let tint = youngTint(for: role) else { return nil }
        let geometry = """
        #pragma varyings
        float plantAge;
        #pragma body
        out.plantAge = _geometry.texcoords[1].x;
        """
        // `1 - age` so a brand new surface is fully tinted and a grown one is
        // untouched. Eased, because tissue colours up quickly at first and then
        // spends a long time finishing.
        let surface = """
        #pragma varyings
        float plantAge;
        #pragma body
        float young = 1.0 - clamp(in.plantAge, 0.0, 1.0);
        young = young * young * (3.0 - 2.0 * young);
        float3 youngColour = float3(\(tint.red), \(tint.green), \(tint.blue));
        _surface.diffuse.rgb = mix(_surface.diffuse.rgb, youngColour, young * \(tint.strength));
        """
        return [.geometry: geometry, .surface: surface]
    }

    /// Where a surface's colour starts out, before it has finished becoming
    /// itself, and how far toward it a brand new one goes.
    private static func youngTint(
        for role: MeshRole
    ) -> (red: Float, green: Float, blue: Float, strength: Float)? {
        switch role {
        case .leaf:
            // Pale yellow-green: chlorophyll is the last thing a new leaf
            // finishes, and until it does the carotenoids underneath show.
            return (0.78, 0.85, 0.46, 0.72)
        case .petal:
            // A petal in bud is the calyx's colour and only becomes the
            // flower's as it opens.
            return (0.55, 0.66, 0.42, 0.85)
        case .centre, .stamen:
            // Pollen arrives late. A closed flower's centre is pale and dry.
            return (0.72, 0.72, 0.58, 0.6)
        case .stem:
            return nil
        }
    }

    /// What a role's roughness was before it became a texture, kept as the
    /// fallback so a failed bake degrades to the old look rather than to white.
    private static func scalarRoughness(for role: MeshRole, palette: Genome.Palette) -> Double {
        switch role {
        case .stem: return 0.75
        case .leaf: return 0.62 - palette.sheen * 0.3
        case .petal: return 0.45 - palette.sheen * 0.3
        case .centre: return 0.55
        case .stamen: return 0.4
        }
    }

    // MARK: - Scene

    /// The lighting: a warm key, a cool rim, and just enough fill that the
    /// shadow side is dark rather than absent.
    ///
    /// The scene deliberately has no background of its own. The view behind it
    /// is transparent, and `StageBackdrop` paints the pool of light — a
    /// gradient is far cheaper and far more controllable in SwiftUI than as a
    /// SceneKit environment, which would also swing around as the plant turns.
    static func makeScene(palette: Genome.Palette) -> SCNScene {
        let scene = SCNScene()

        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.color = UIColor(white: 1.0, alpha: 1)
        // The plant is the brightest thing on screen by a wide margin; the
        // backdrop only gives it somewhere to stand.
        key.light?.intensity = 1050
        key.eulerAngles = SCNVector3(-0.6, 0.7, 0)

        // Self-shadowing was tried here and abandoned. Both `.forward` and
        // `.deferred` were driven on a device with the light stood off along
        // its own direction and the orthographic box sized to a plant rather
        // than to the metre-scale default, and neither put a leaf's shadow on
        // the leaf beneath it. The likeliest reason is that every leaf and
        // petal is `isDoubleSided` — a single surface with no thickness, which
        // is lit from both faces precisely so it does not vanish when it turns
        // away, and which correspondingly has no back to cast from.
        //
        // Worth another look only alongside giving blades a thickness. Written
        // down so the next reader spends the afternoon on the geometry rather
        // than on the shadow settings, which are not the problem.
        key.light?.castsShadow = false
        scene.rootNode.addChildNode(key)

        let rim = SCNNode()
        rim.light = SCNLight()
        rim.light?.type = .directional
        rim.light?.color = UIColor(red: 0.62, green: 0.72, blue: 1.0, alpha: 1)
        rim.light?.intensity = 620
        rim.eulerAngles = SCNVector3(-0.2, 3.5, 0)
        scene.rootNode.addChildNode(rim)

        // A bounce, from low and in front, standing in for the light a plant
        // gets back off the ground it is standing on.
        //
        // Without it every surface turned away from the key fell to the ambient
        // alone, and the ambient is tinted to a near-black backdrop — so a leaf
        // that happened to face the wrong way went out completely and read as a
        // hole cut in the plant rather than as a leaf in shade. Shade wants to
        // be the darker side of a surface, not the absence of one.
        let bounce = SCNNode()
        bounce.light = SCNLight()
        bounce.light?.type = .directional
        bounce.light?.color = UIColor(red: 0.86, green: 0.92, blue: 0.88, alpha: 1)
        bounce.light?.intensity = 260
        bounce.eulerAngles = SCNVector3(0.85, -0.4, 0)
        scene.rootNode.addChildNode(bounce)

        // The fill is tinted to the backdrop's own colour, so the plant reads
        // as standing in that light rather than cut out and pasted onto it.
        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light?.type = .ambient
        fill.light?.color = StageBackdrop.glowColour(for: palette)
        fill.light?.intensity = 420
        scene.rootNode.addChildNode(fill)

        return scene
    }

    /// The vertical field of view. Pinned to vertical rather than left on
    /// `.automatic`, which switches to a horizontal angle on a wide screen and
    /// would crop the top off a tall plant the moment an iPad turned sideways.
    static let fieldOfView: CGFloat = 36

    /// Half the vertical field of view, in radians. Everything that works out
    /// how far away to stand needs it.
    static var verticalHalfAngle: Float { Float(fieldOfView * .pi / 180) / 2 }

    static func makeCameraNode() -> SCNNode {
        let camera = SCNCamera()
        camera.fieldOfView = fieldOfView
        camera.projectionDirection = .vertical
        camera.zNear = 0.01
        camera.zFar = 40
        camera.wantsHDR = true
        camera.bloomIntensity = 0.45
        camera.bloomThreshold = 0.82
        camera.bloomBlurRadius = 14
        camera.wantsExposureAdaptation = false

        let node = SCNNode()
        node.camera = camera
        return node
    }

    /// The plant as it will be when it is grown.
    ///
    /// Pinned to the hour this genome opens widest, so it is the plant at its
    /// best rather than whatever time it happens to be.
    static func bloomPreview(for genome: Genome) -> GrowthModel.State {
        let birth = Date(timeIntervalSince1970: 0)
        let atBloom = birth.addingTimeInterval(
            (genome.tempo.daysToBloom + genome.tempo.bloomDays * 0.45) * 86_400
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        let hour = genome.tempo.opensByDay ? 13 : 1
        let pinned = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: atBloom) ?? atBloom
        return GrowthModel(genome: genome).state(birth: birth, now: pinned, calendar: calendar)
    }

    /// The space this plant will eventually fill.
    ///
    /// The stage frames against these rather than against the plant as it is
    /// now. Framing each moment to fill the screen made every stage the same
    /// size on screen, which is the one thing a growing plant is not: a sprout
    /// arrived looking like a mature plant drawn badly. Held against what it
    /// will become, a seedling is small in a large space and spends weeks
    /// growing into it, which is the whole of what there is to watch.
    static func matureBounds(for genome: Genome) -> (min: SIMD3<Float>, max: SIMD3<Float>) {
        let mesh = PlantBuilder(genome: genome).mesh(growth: bloomPreview(for: genome))
        return (mesh.minBounds, mesh.maxBounds)
    }

    /// Frames the plant so it fills the same proportion of the view at every
    /// size — a seedling or a plant in full bloom, an iPhone held upright or an
    /// iPad turned on its side.
    ///
    /// Both dimensions are fitted rather than the larger one guessed at: a tall
    /// plant is limited by the height on a phone and by the width on nothing,
    /// but the same plant in a short, wide window is limited by the height much
    /// sooner. Taking the greater of the two distances covers every shape.
    ///
    /// `reserved` is the fraction of the view's height the chrome has spoken
    /// for — the plant's name, what it is doing, and the row of marks, in their
    /// band across the foot of the screen. The plant is fitted into what is
    /// left rather than into the whole view, so it stands on that band rather
    /// than growing down through it.
    ///
    /// Which end the band is at does not matter here: reserving height costs
    /// the same distance either way. Only the aim differs, and that is the
    /// caller's — see `PlantSceneView.applyFraming`.
    ///
    /// Reserved whether or not the chrome is on screen. The band comes and goes
    /// on a tap, and re-framing with it would pull the plant a little smaller
    /// every time somebody asked for the controls and push it back when they
    /// stopped — motion nobody asked for, in the one part of the app that is
    /// meant to hold still.
    static func framing(
        min minBounds: SIMD3<Float>,
        max maxBounds: SIMD3<Float>,
        aspect: Float,
        reserved: Float = 0
    ) -> (target: SCNVector3, distance: Float) {
        let centre = (minBounds + maxBounds) * 0.5
        let extent = maxBounds - minBounds
        let halfHeight = extent.y * 0.5
        // The plant turns, so its silhouette can be as wide as its deepest axis.
        let halfWidth = Swift.max(extent.x, extent.z) * 0.5

        let horizontalHalfAngle = atan(tan(verticalHalfAngle) * Swift.max(0.2, aspect))

        // The floor is a guard against a chrome band that has somehow eaten the
        // screen, not a design value: at a third of the view the plant would
        // already be too far off to read.
        let usable = Swift.max(0.35, 1 - reserved)
        let distance = Swift.max(
            halfHeight / (tan(verticalHalfAngle) * usable),
            halfWidth / tan(horizontalHalfAngle)
        )
        // The guard belongs on the distance, not on the plant's measurements. A
        // floor on the extent silently pretends every plant is at least a
        // handspan across, which is true of a mature one and false of every
        // seedling — and it is the seedling that then gets pushed away and
        // rendered as a speck. This only catches a degenerate mesh, and it
        // stays clear of the camera's `zNear`.
        return (SCNVector3(centre.x, centre.y, centre.z), Swift.max(0.04, distance * 1.25))
    }

    /// How far to stand off the closed seed at the start of an arrival.
    ///
    /// Given as a fraction of half the screen's height, so the closed seed
    /// stands about a sixth of the screen tall.
    ///
    /// At twice this it read as a boulder: something huge being looked at from
    /// close up, rather than something small being looked at closely. The
    /// difference between those two is entirely how much dark is left around
    /// it. Much below this and it is a speck being stared at, which is the
    /// thing the camera came in to avoid.
    static let seedHeightOnScreen: Float = 0.16

    static func seedDistance(halfHeight: Float) -> Float {
        Swift.max(0.05, halfHeight / (tan(verticalHalfAngle) * seedHeightOnScreen))
    }
}
