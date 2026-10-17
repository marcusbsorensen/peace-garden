import SceneKit
import SeedCore
@_spi(PeaceGarden) import PlantRender

/// The replayed plant, one SceneKit node per moment, built off the main thread.
///
/// **Genuine renders, every frame.** Each moment is the plant's own genome put
/// through `PlantBuilder` at that moment's growth — the same mesh the stage
/// draws — not a scaled copy of the plant as it is now.
///
/// The materials are made once and shared by every frame. They are the slow
/// part of `PlantSceneBuilder.node(for:palette:)` — each one bakes three
/// textures — and they are the same for the whole life of a seed; only the
/// geometry changes from one moment to the next.
final class TimeLapseNodes: @unchecked Sendable {
    let genome: Genome
    private let builder: PlantBuilder
    private let materials: [MeshRole: SCNMaterial]

    init(genome: Genome) {
        self.genome = genome
        builder = PlantBuilder(genome: genome)
        var materials: [MeshRole: SCNMaterial] = [:]
        for role in MeshRole.allCases {
            materials[role] = PlantSceneBuilder.material(for: role, palette: genome.palette)
        }
        self.materials = materials
    }

    /// The plant at `growth`, as a node ready to hang under the turntable.
    ///
    /// Safe to call from any thread: it reads the genome and the shared
    /// materials and writes nothing but the node it returns.
    func node(for growth: GrowthModel.State) -> SCNNode {
        let mesh = builder.mesh(growth: growth)
        let node = SCNNode()
        for part in mesh.parts where !part.indices.isEmpty {
            let geometry = PlantSceneBuilder.geometry(for: part)
            geometry.firstMaterial = materials[part.role]
            let child = SCNNode(geometry: geometry)
            child.name = part.role.rawValue
            node.addChildNode(child)
        }
        return node
    }
}

/// A node handed from the thread that built it to the one that shows it.
///
/// SceneKit's objects are not `Sendable`; this one is built on one thread,
/// never touched there again, and only then attached to the scene on the
/// main thread, which is the hand-off SceneKit allows.
struct BuiltNode: @unchecked Sendable {
    let node: SCNNode
}
