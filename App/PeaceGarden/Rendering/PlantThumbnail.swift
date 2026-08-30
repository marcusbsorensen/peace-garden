import SwiftUI
import SceneKit
import SeedCore

/// A still of a plant, for the garden grid.
///
/// A grid of live SceneKit views would run several renderers at once for no
/// benefit; these are rendered once off-screen and cached until the plant
/// visibly changes.
struct PlantThumbnail: View {
    let genome: Genome
    let growth: GrowthModel.State
    var size: CGFloat = 150

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            StageBackdrop(palette: genome.palette)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .transition(.opacity)
            }
        }
        .task(id: ThumbnailRenderer.key(genome: genome, growth: growth, size: size)) {
            image = ThumbnailRenderer.shared.image(genome: genome, growth: growth, size: size)
        }
    }
}

@MainActor
final class ThumbnailRenderer {
    static let shared = ThumbnailRenderer()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 120
    }

    static func key(genome: Genome, growth: GrowthModel.State, size: CGFloat) -> String {
        // Bucketed loosely: a thumbnail does not need to track growth as
        // closely as the full-screen plant does.
        let bucket = Int(growth.overall * 24) * 10 + Int(growth.bloomOpen * 6)
        return "\(genome.seed.hex)-\(bucket)-\(Int(size))"
    }

    func image(genome: Genome, growth: GrowthModel.State, size: CGFloat) -> UIImage? {
        let key = Self.key(genome: genome, growth: growth, size: size) as NSString
        if let cached = cache.object(forKey: key) { return cached }

        let view = SCNView(frame: CGRect(x: 0, y: 0, width: size, height: size))
        view.scene = PlantSceneBuilder.makeScene(palette: genome.palette)
        // Snapshotted with transparency so the tile's own backdrop shows
        // through. If a thumbnail ever comes back as a black square, this is
        // the pair of lines that did it.
        view.backgroundColor = .clear
        view.isOpaque = false
        view.antialiasingMode = .multisampling4X

        let mesh = PlantBuilder(genome: genome).mesh(growth: growth)
        let plant = PlantSceneBuilder.node(for: mesh, palette: genome.palette)
        let framing = PlantSceneBuilder.framing(min: mesh.minBounds, max: mesh.maxBounds, aspect: 1)
        plant.position = SCNVector3(-framing.target.x, -framing.target.y, -framing.target.z)

        let pivot = SCNNode()
        pivot.position = framing.target
        pivot.eulerAngles.y = 0.5
        pivot.addChildNode(plant)
        view.scene?.rootNode.addChildNode(pivot)

        let camera = PlantSceneBuilder.makeCameraNode()
        camera.position = SCNVector3(0, 0, framing.distance)
        let rig = SCNNode()
        rig.position = framing.target
        rig.addChildNode(camera)
        view.scene?.rootNode.addChildNode(rig)
        view.pointOfView = camera

        let snapshot = view.snapshot()
        guard snapshot.size.width > 0 else { return nil }
        cache.setObject(snapshot, forKey: key)
        return snapshot
    }
}
