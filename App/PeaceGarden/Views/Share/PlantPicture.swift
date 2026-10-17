import SceneKit
import SeedCore
import UIKit
import PlantRender

/// What a picture of a plant is made of: the plant as it is now, the ground it
/// stands on, and the size of the picture in pixels.
///
/// **The plant and nothing about it.** A portrait carries the genome only so the
/// plant can be built; nothing here writes the seed, the name, the other
/// gardener, the meeting's place or its date into the pixels, and the files the
/// share writes carry no metadata of their own beyond what a format requires
/// (`PlantShareFiles`). What somebody sends is a picture of a plant.
///
/// One portrait is one composition. A still, every frame of a turn, and the
/// still a Live Photo settles on are all drawn from the same portrait, so the
/// moving wallpaper comes to rest on exactly the picture saved beside it.
struct PlantPortrait: Sendable {
    var genome: Genome
    var growth: GrowthModel.State
    /// The picture's size in whole pixels, width by height.
    var pixels: CGSize
    /// How many pixels a point is, for what the ground draws in points — a
    /// star is drawn the size it is on a phone, whatever size the picture is.
    var pixelsPerPoint: CGFloat
    /// The band of the picture's height the plant is framed into, measured down
    /// from the top. The grown plant fits inside it, and the plant stands on
    /// its foot.
    var band: Band
    var ground: ShareGround = .recommended
    /// The hour on this phone's clock, `0..<24`, for a ground that follows it
    /// (`ShareGround.byTheHour`); nil draws the night. See `ShareSky`.
    var hour: Double?
    /// Which way the plant faces in the still, in radians about its stem. A
    /// turn starts and ends here.
    ///
    /// Half a radian, which is the angle the garden's tiles show every plant
    /// at (`ThumbnailRenderer`), so a shared plant is the plant as the garden
    /// pictures it.
    var facing: Float = 0.5

    struct Band: Sendable, Equatable {
        var top: Double
        var foot: Double
    }

    /// The shared still: four by five, which a message, a mail and a feed all
    /// show whole, and which suits a plant, being taller than it is wide.
    static func picture(genome: Genome, growth: GrowthModel.State,
                        ground: ShareGround = .recommended, hour: Double? = nil) -> PlantPortrait {
        PlantPortrait(genome: genome, growth: growth,
                      pixels: CGSize(width: 1440, height: 1800), pixelsPerPoint: 3,
                      band: Band(top: 0.10, foot: 0.90), ground: ground, hour: hour)
    }

    /// The turning video: the same composition as the still at 1080 wide, the
    /// width a phone plays a video at.
    static func turning(genome: Genome, growth: GrowthModel.State,
                        ground: ShareGround = .recommended, hour: Double? = nil) -> PlantPortrait {
        PlantPortrait(genome: genome, growth: growth,
                      pixels: CGSize(width: 1080, height: 1350), pixelsPerPoint: 2.25,
                      band: Band(top: 0.10, foot: 0.90), ground: ground, hour: hour)
    }

    /// A wallpaper: the phone's own screen, pixel for pixel, with the plant
    /// below the lock screen's clock.
    ///
    /// **Where the clock is.** The date and time take the top quarter of a lock
    /// screen and a row of widgets can sit under them to about a third; the
    /// torch and the camera sit in the bottom tenth. So the plant stands in the
    /// band between, its foot just above the two buttons and its crown clear of
    /// the widgets. `design/share-plant-2026-10-13/` has it on a mock lock
    /// screen.
    ///
    /// `nativePixels` is the screen's `nativeBounds` — its real pixels, which on
    /// a phone that scales its picture are not its points times its scale — and
    /// `scale` its `nativeScale`.
    static func wallpaper(genome: Genome, growth: GrowthModel.State,
                          nativePixels: CGSize, scale: CGFloat,
                          ground: ShareGround = .recommended, hour: Double? = nil) -> PlantPortrait {
        PlantPortrait(genome: genome, growth: growth,
                      pixels: wallpaperPixels(native: nativePixels), pixelsPerPoint: max(1, scale),
                      band: Band(top: 0.37, foot: 0.86), ground: ground, hour: hour)
    }

    /// A screen's own pixels, upright.
    static func wallpaperPixels(native: CGSize) -> CGSize {
        CGSize(width: min(native.width, native.height).rounded(),
               height: max(native.width, native.height).rounded())
    }

    /// The same composition with an even number of pixels each way, for a
    /// movie: H.264 works in pairs of pixels, and several iPhones are an odd
    /// number wide (1179 is common). One pixel narrower, at most, and nothing
    /// in it moves.
    var evenSized: PlantPortrait {
        var even = self
        even.pixels = CGSize(width: (pixels.width / 2).rounded(.down) * 2,
                             height: (pixels.height / 2).rounded(.down) * 2)
        return even
    }

    /// The size in points, which is what the ground is drawn in.
    var points: CGSize {
        CGSize(width: pixels.width / pixelsPerPoint, height: pixels.height / pixelsPerPoint)
    }

    /// Where, down the picture, the middle of the plant is — what the pool of
    /// light behind it is centred on. A little above the band's middle, as the
    /// stage's pool sits a little above the screen's (`StageBackdrop`).
    var plantCentre: Double { band.top + (band.foot - band.top) * 0.46 }
}

/// What a shared plant stands on.
///
/// The first three were drawn for Marcus to choose from in
/// `design/share-plant-2026-10-13/backgrounds-ABC.png`, and the letters there
/// are the order here. He answered with a fourth (14 October 2026): *"can we
/// follow the time of day/night on the user's phone? Otherwise night sky"*.
enum ShareGround: String, CaseIterable, Sendable {
    /// A: the garden's night sky, with the plant's own pool of light behind it.
    case nightSky
    /// B: the garden's day sky, mid-morning.
    case daySky
    /// C: the plant's own stage as a dark phone shows it — black, and the pool
    /// of light.
    case stage
    /// The sky for the hour on this phone's clock — the garden's day, the
    /// time-lapse's dusk and dawn (21C), the garden's night — over the fixed
    /// stars, and the night when there is no hour (`ShareSky`). The portrait
    /// carries the hour.
    case byTheHour

    /// What is drawn: Marcus's answer of 14 October.
    static let recommended: ShareGround = .byTheHour
}

// MARK: - Drawing

/// Draws a portrait, one frame at a time, off the main thread.
///
/// **One per export, used from one task.** SceneKit's offscreen renderer is
/// built for this — no view, no window, no display link — and nothing here is
/// shared with the plant on the screen, so an export can run while the stage
/// keeps turning.
///
/// The plant is drawn on a clear ground and laid over the backdrop, which is
/// how the stage does it too: `StageBackdrop` paints the light and the
/// SceneKit view over it is transparent. The scene, the lights and the camera
/// are the stage's own (`PlantSceneBuilder`), so a shared plant is lit the way
/// the person has been looking at it.
final class PlantPictureRenderer {
    let portrait: PlantPortrait
    private let renderer: SCNRenderer
    private let pivot = SCNNode()
    private let backdrop: CGImage

    /// `backdrop` is the ground at the portrait's size; see `ShareBackdrop`.
    init?(portrait: PlantPortrait, backdrop: CGImage) {
        guard let device = MTLCreateSystemDefaultDevice() else { return nil }
        self.portrait = portrait
        self.backdrop = backdrop
        renderer = SCNRenderer(device: device, options: nil)

        let genome = portrait.genome
        let scene = PlantSceneBuilder.makeScene(palette: genome.palette)
        scene.background.contents = UIColor.clear

        let mesh = PlantBuilder(genome: genome).mesh(growth: portrait.growth)
        let plant = PlantSceneBuilder.node(for: mesh, palette: genome.palette)
        pivot.addChildNode(plant)
        scene.rootNode.addChildNode(pivot)

        let camera = PlantSceneBuilder.makeCameraNode()
        let rig = SCNNode()
        rig.addChildNode(camera)
        scene.rootNode.addChildNode(rig)

        let framing = Self.framing(for: portrait, current: (mesh.minBounds, mesh.maxBounds))
        rig.position = SCNVector3(0, framing.aim, 0)
        camera.position = SCNVector3(0, 0, framing.distance)

        renderer.scene = scene
        renderer.pointOfView = camera
    }

    /// How far back the camera stands and how high it looks.
    ///
    /// **The stage's arithmetic, with one change.** The distance comes from the
    /// grown plant and the turn it sweeps (`PlantSceneBuilder.framing`), so a
    /// turning plant stays in the picture all the way round; the aim puts the
    /// plant's base on the band's foot, as the stage puts it on the band of
    /// words (`PlantSceneView.applyFraming`).
    ///
    /// The change is for a young plant. On the stage a seedling is small in a
    /// large space and spends weeks growing into it, which is the whole of what
    /// there is to watch; in a picture somebody sends, a speck at the foot of
    /// an empty frame reads as a picture of nothing. So the frame comes in to
    /// meet a plant that would fill less than `smallestShare` of the band — the
    /// garden's tiles do the same, for the same reason (`ThumbnailRenderer`).
    static func framing(
        for portrait: PlantPortrait,
        current: (min: SIMD3<Float>, max: SIMD3<Float>)
    ) -> (aim: Float, distance: Float) {
        let grown = PlantSceneBuilder.matureExtent(for: portrait.genome)
        let grownHeight = grown.max.y - grown.min.y
        let height = current.max.y - current.min.y
        let scale: Float = (grownHeight > 0 && height > 0)
            ? min(1, height / (grownHeight * smallestShare))
            : 1

        let bandHeight = max(0.2, portrait.band.foot - portrait.band.top)
        let aspect = Float(portrait.pixels.width / max(1, portrait.pixels.height))
        let framing = PlantSceneBuilder.framing(
            min: grown.min * scale, max: grown.max * scale,
            aspect: aspect,
            reserved: Float(1 - bandHeight),
            reach: grown.reach * scale
        )
        // The stage's own margin on the way in.
        let distance = framing.distance * 1.12
        let halfWorldHeight = distance * tan(PlantSceneBuilder.verticalHalfAngle)
        // The foot, as a fraction of the height up from the bottom.
        let foot = Float(1 - portrait.band.foot)
        let aim = current.min.y - (2 * foot - 1) * halfWorldHeight
        return (aim, distance)
    }

    /// How little of its band a plant may fill before the frame comes in.
    static let smallestShare: Float = 0.45

    /// The same plant at another age, in the same frame: for a run of frames
    /// in which the plant grows rather than turns. The camera stays where the
    /// portrait put it, so a plant growing is seen growing, not reframed.
    func show(growth: GrowthModel.State) {
        let genome = portrait.genome
        let mesh = PlantBuilder(genome: genome).mesh(growth: growth)
        let plant = PlantSceneBuilder.node(for: mesh, palette: genome.palette)
        pivot.childNodes.forEach { $0.removeFromParentNode() }
        pivot.addChildNode(plant)
    }

    /// The plant turned to `yaw`, on its ground, drawn into `context`, which
    /// must be the portrait's size in pixels.
    func draw(yaw: Float, in context: CGContext) {
        let rect = CGRect(origin: .zero, size: portrait.pixels)
        context.interpolationQuality = .high
        context.draw(backdrop, in: rect)
        pivot.eulerAngles = SCNVector3(0, yaw, 0)
        let plant = renderer.snapshot(atTime: 0, with: portrait.pixels, antialiasingMode: .multisampling4X)
        if let image = plant.cgImage {
            context.draw(image, in: rect)
        }
    }

    /// One frame as an image.
    func image(yaw: Float) -> CGImage? {
        guard let context = Self.context(size: portrait.pixels) else { return nil }
        draw(yaw: yaw, in: context)
        return context.makeImage()
    }

    /// The still: the plant facing the way it faces at rest.
    func still() -> CGImage? { image(yaw: portrait.facing) }

    /// An opaque sRGB bitmap of this size.
    static func context(size: CGSize) -> CGContext? {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        return CGContext(data: nil, width: Int(size.width), height: Int(size.height),
                         bitsPerComponent: 8, bytesPerRow: 0, space: space,
                         bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
    }
}

/// A `CGImage` handed from the main actor, where the ground is drawn, to the
/// task that draws the plant over it. Nothing writes to it after it is made.
struct SharedImage: @unchecked Sendable {
    let image: CGImage
}
