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

    /// `matureBounds` builds a whole second mesh, and it is the same answer for
    /// the whole life of a seed. A grid asks for it once per tile per growth
    /// bucket, so it is worth keeping — the stage holds the same thing against
    /// `referenceSeed` for the same reason.
    private var matureBoundsBySeed: [String: (min: SIMD3<Float>, max: SIMD3<Float>)] = [:]

    private init() {
        cache.countLimit = 120
    }

    private func matureBounds(for genome: Genome) -> (min: SIMD3<Float>, max: SIMD3<Float>) {
        let key = genome.seed.hex
        if let held = matureBoundsBySeed[key] { return held }
        let bounds = PlantSceneBuilder.matureBounds(for: genome)
        matureBoundsBySeed[key] = bounds
        return bounds
    }

    /// How little of its tile a plant may fill before the frame comes in to
    /// meet it. Measured on height, because that is the dimension a plant
    /// grows in and the one that decides whether a tile reads as a plant.
    private static let smallestShareOfATile: Float = 0.28

    /// The box a tile is framed against.
    ///
    /// The mature plant, so a tile shows what it will grow into and a young
    /// one has somewhere to go — but drawn in toward the plant while it would
    /// otherwise be too small to see. A stage is nine hundred points tall and
    /// a tile is a hundred and fifty, so the same proportion that makes a
    /// seedling small and hopeful on the stage makes it a speck here, low in
    /// an empty square, and the plant just grown with somebody is the one it
    /// happens to. Scaling the box about the origin brings the camera's aim
    /// down with it, so a seedling is centred rather than sitting on the floor
    /// of its tile — a plant stands on its own base, so the origin is the foot.
    private func referenceBounds(
        for genome: Genome,
        current: (min: SIMD3<Float>, max: SIMD3<Float>)
    ) -> (min: SIMD3<Float>, max: SIMD3<Float>) {
        let mature = matureBounds(for: genome)
        let matureHeight = mature.max.y - mature.min.y
        let height = current.max.y - current.min.y
        guard matureHeight > 0, height > 0 else { return mature }

        // At the floor the plant fills exactly `smallestShareOfATile`; above
        // it the mature box is used unchanged and growth shows as growth.
        let scale = min(1, height / (matureHeight * Self.smallestShareOfATile))
        return (mature.min * scale, mature.max * scale)
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
        // Framed against what the plant will grow into, not against what it is
        // today — the same rule the stage follows. Framing a tile on the mesh
        // in front of it zooms all the way in on whatever is there, so a plant
        // sown an hour ago filled its tile as a wide dome on a stub: the
        // mushroom again, made by the camera this time rather than by the
        // geometry, and landing on the newest plant in the garden.
        let reference = referenceBounds(for: genome, current: (mesh.minBounds, mesh.maxBounds))
        let framing = PlantSceneBuilder.framing(min: reference.min, max: reference.max, aspect: 1)
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
