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
        geometry.firstMaterial = material(for: part.role, palette: palette)
        return geometry
    }

    static func material(for role: MeshRole, palette: Genome.Palette) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = GradientTexture.image(for: role, palette: palette)
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

    static func makeCameraNode() -> SCNNode {
        let camera = SCNCamera()
        camera.fieldOfView = 36
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

    /// Frames the plant so it fills the same proportion of the screen at every
    /// size, from a seedling to a plant in full bloom.
    static func framing(for mesh: PlantMesh) -> (target: SCNVector3, distance: Float) {
        let centre = mesh.centre
        let extent = mesh.maxBounds - mesh.minBounds
        let radius = max(0.06, max(extent.y, max(extent.x, extent.z)) * 0.5)
        let distance = radius / tan(Float(36 * Double.pi / 180) / 2) * 1.5
        return (SCNVector3(centre.x, centre.y, centre.z), distance)
    }
}
