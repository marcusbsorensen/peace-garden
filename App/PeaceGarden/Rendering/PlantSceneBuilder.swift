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
        let geometry = SCNGeometry(
            sources: [
                SCNGeometrySource(vertices: vertices),
                SCNGeometrySource(normals: normals),
                SCNGeometrySource(textureCoordinates: coordinates)
            ],
            elements: [element]
        )
        return geometry
    }

    static func material(for role: MeshRole, palette: Genome.Palette) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        // Falls back to a flat colour if the texture could not be made, rather
        // than leaving the material white.
        material.diffuse.contents = GradientTexture.image(for: role, palette: palette)
            ?? GradientTexture.colour(PaletteRamp.colour(for: role, u: 0.5, v: 0.5, palette: palette))
        material.diffuse.wrapS = .clamp
        material.diffuse.wrapT = .clamp
        material.metalness.contents = NSNumber(value: 0.0)

        switch role {
        case .stem:
            material.roughness.contents = NSNumber(value: 0.75)
        case .leaf:
            // Leaves and petals are single surfaces with no thickness, so they
            // have to be lit from both sides or they vanish when they turn away.
            material.roughness.contents = NSNumber(value: 0.62 - palette.sheen * 0.3)
            material.isDoubleSided = true
        case .petal:
            material.roughness.contents = NSNumber(value: 0.45 - palette.sheen * 0.3)
            material.isDoubleSided = true
            material.emission.contents = GradientTexture.colour(palette.petalTip, alpha: 1)
            material.emission.intensity = CGFloat(palette.glow * 0.16)
        case .centre:
            material.roughness.contents = NSNumber(value: 0.55)
            material.emission.contents = GradientTexture.colour(palette.centre, alpha: 1)
            material.emission.intensity = CGFloat(0.1 + palette.glow * 0.35)
        case .stamen:
            material.roughness.contents = NSNumber(value: 0.4)
            material.emission.contents = GradientTexture.colour(palette.centre, alpha: 1)
            material.emission.intensity = CGFloat(0.15 + palette.glow * 0.3)
        }
        return material
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
        key.light?.castsShadow = false
        key.eulerAngles = SCNVector3(-0.6, 0.7, 0)
        scene.rootNode.addChildNode(key)

        let rim = SCNNode()
        rim.light = SCNLight()
        rim.light?.type = .directional
        rim.light?.color = UIColor(red: 0.62, green: 0.72, blue: 1.0, alpha: 1)
        rim.light?.intensity = 620
        rim.eulerAngles = SCNVector3(-0.2, 3.5, 0)
        scene.rootNode.addChildNode(rim)

        // The fill is tinted to the backdrop's own colour, so the plant reads
        // as standing in that light rather than cut out and pasted onto it.
        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light?.type = .ambient
        fill.light?.color = StageBackdrop.glowColour(for: palette)
        fill.light?.intensity = 300
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
    static func framing(
        min minBounds: SIMD3<Float>,
        max maxBounds: SIMD3<Float>,
        aspect: Float
    ) -> (target: SCNVector3, distance: Float) {
        let centre = (minBounds + maxBounds) * 0.5
        let extent = maxBounds - minBounds
        let halfHeight = extent.y * 0.5
        // The plant turns, so its silhouette can be as wide as its deepest axis.
        let halfWidth = Swift.max(extent.x, extent.z) * 0.5

        let horizontalHalfAngle = atan(tan(verticalHalfAngle) * Swift.max(0.2, aspect))

        let distance = Swift.max(
            halfHeight / tan(verticalHalfAngle),
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
