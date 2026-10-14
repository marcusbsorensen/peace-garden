import AVFoundation
import SceneKit
import SeedCore
import SwiftUI

/// The time-lapse as a film: its frames, or a twelve-second movie, for the
/// share sheet to hand on.
///
/// **For the share export** (`Views/Share/`): *Share time-lapse* calls
/// `writeMovie(_:now:options:to:progress:)` (`PlantShareFiles.timeLapse`) and
/// shares the file, or
/// `render(_:now:options:frame:)` if it wants the frames to put through a
/// pipeline of its own. Nothing here knows about sharing, and nothing in the
/// share code needs to know how a time-lapse is timed.
///
/// **What is in a frame.** The stage the plant's screen stands on
/// (`StageBackdrop`), the time-lapse's sky over it (`TimeLapseSky`), and the
/// plant — a genuine render of its own genome at that moment's growth, framed
/// as the plant's screen frames it, turning on the stage's turntable at the
/// stage's rate. **No words**: no name, no seed, no date. The film is the plant
/// and the light it grew in; anything said about it is the sharer's to say.
///
/// Rendered off screen by SceneKit (`SCNRenderer`), one frame after another,
/// faster or slower than real time depending on the phone; it is the same
/// score (`TimeLapse`) the screen plays, so the two cannot drift apart.
@MainActor
enum TimeLapseFilm {
    struct Options: Sendable {
        /// The frame, in pixels. Portrait 1080 × 1920 by default, which every
        /// place a film is shared to takes as it is.
        var size = CGSize(width: 1080, height: 1920)
        var fps = 30
        var drift: SkyDrift = .chosen
        /// The ground the film is drawn on. Dark by default whatever the
        /// phone's appearance: a film is watched somewhere else.
        var scheme: ColorScheme = .dark
        /// The stills-and-dissolves version (`TimeLapse.frame(at:reduceMotion:)`).
        var reduceMotion = false
        /// Opens on the plant as it is and fades it out before the sprout, as
        /// the screen does. Off for a film, which starts on the sprout.
        var opensOnThePlant = false
        /// Turns on the turntable as the stage does, a little over a seventh
        /// of a turn in the run.
        var turns = true
        /// Whose hour the sky ends on. The phone's own.
        var calendar: Calendar = .current

        init() {}
    }

    /// One frame of the film.
    struct Frame {
        var index: Int
        var time: TimeInterval
        /// How far through the plant's visible growing, `0...1`.
        var progress: Double
        var image: CGImage
    }

    enum Failure: Error {
        case noRenderer
        case cannotDraw
        case cannotWrite(Error?)
    }

    /// Draws every frame of the run, in order, handing each to `frame` as it
    /// is made. Nothing is kept: a twelve-second film at 1080 × 1920 is the
    /// best part of three gigabytes of pixels.
    static func render(_ record: PlantRecord, now: Date, options: Options = Options(),
                       frame body: (Frame) async throws -> Void) async throws {
        let lapse = TimeLapse(record: record, now: now, drift: options.drift, calendar: options.calendar)
        let studio = try Studio(record: record, lapse: lapse, options: options)
        let count = Int((TimeLapse.duration * Double(options.fps)).rounded())
        for index in 0...count {
            try Task.checkCancellation()
            let time = Double(index) / Double(options.fps)
            let moment = lapse.frame(at: time, reduceMotion: options.reduceMotion)
            let image = try studio.draw(moment)
            try await body(Frame(index: index, time: time, progress: moment.progress, image: image))
            // Lets the screen breathe between frames on a long render.
            await Task.yield()
        }
    }

    /// The film as an H.264 movie at `url`, replacing anything there.
    /// `progress` is told how far through the frames it is, `0...1`, after
    /// each one is written.
    static func writeMovie(_ record: PlantRecord, now: Date, options: Options = Options(),
                           to url: URL, progress: (Double) -> Void = { _ in }) async throws {
        try? FileManager.default.removeItem(at: url)
        let writer: AVAssetWriter
        do { writer = try AVAssetWriter(outputURL: url, fileType: .mp4) } catch { throw Failure.cannotWrite(error) }
        let width = Int(options.size.width), height = Int(options.size.height)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoColorPropertiesKey: [
                AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
                AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
                AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2
            ]
        ])
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height
        ])
        guard writer.canAdd(input) else { throw Failure.cannotWrite(nil) }
        writer.add(input)
        guard writer.startWriting() else { throw Failure.cannotWrite(writer.error) }
        writer.startSession(atSourceTime: .zero)
        let last = Double(max(1, Int((TimeLapse.duration * Double(options.fps)).rounded())))

        try await render(record, now: now, options: options) { frame in
            while !input.isReadyForMoreMediaData { try await Task.sleep(for: .milliseconds(5)) }
            guard let pool = adaptor.pixelBufferPool else { throw Failure.cannotWrite(writer.error) }
            var made: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(nil, pool, &made)
            guard let buffer = made else { throw Failure.cannotWrite(nil) }
            CVPixelBufferLockBaseAddress(buffer, [])
            defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
            guard let context = CGContext(
                data: CVPixelBufferGetBaseAddress(buffer), width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
            ) else { throw Failure.cannotDraw }
            context.draw(frame.image, in: CGRect(x: 0, y: 0, width: width, height: height))
            let at = CMTime(value: CMTimeValue(frame.index), timescale: CMTimeScale(options.fps))
            guard adaptor.append(buffer, withPresentationTime: at) else { throw Failure.cannotWrite(writer.error) }
            progress(min(1, Double(frame.index) / last))
        }

        input.markAsFinished()
        await writer.finishWriting()
        if writer.status != .completed { throw Failure.cannotWrite(writer.error) }
    }

    // MARK: The studio

    /// The scene, the camera and the ground, made once for a whole film.
    @MainActor
    private final class Studio {
        let lapse: TimeLapse
        let options: Options
        let nodes: TimeLapseNodes
        let renderer: SCNRenderer
        let pivot = SCNNode()
        let replay = SCNNode()
        let live: SCNNode?
        let ground: CGImage
        let look: TimeLapseSky.Look
        let pixels: CGSize
        private var kept: (growth: GrowthModel.State, node: SCNNode)?

        init(record: PlantRecord, lapse: TimeLapse, options: Options) throws {
            self.lapse = lapse
            self.options = options
            pixels = CGSize(width: max(1, options.size.width.rounded()), height: max(1, options.size.height.rounded()))
            let genome = record.genome
            nodes = TimeLapseNodes(genome: genome)
            look = .for(options.scheme)

            guard let device = MTLCreateSystemDefaultDevice() else { throw Failure.noRenderer }
            renderer = SCNRenderer(device: device, options: nil)
            let scene = PlantSceneBuilder.makeScene(palette: genome.palette)
            scene.background.contents = UIColor.clear
            let rig = SCNNode(), camera = PlantSceneBuilder.makeCameraNode()
            rig.addChildNode(camera)
            scene.rootNode.addChildNode(pivot)
            scene.rootNode.addChildNode(rig)
            pivot.addChildNode(replay)
            renderer.scene = scene
            renderer.pointOfView = camera

            // Framed as the plant's screen frames it with nothing written under
            // the plant (`PlantSceneView.applyFraming`), and held on the plant
            // as it is now, as the screen holds it while a time-lapse plays.
            let final = PlantBuilder(genome: genome).mesh(growth: lapse.final)
            let reference = PlantSceneBuilder.matureExtent(for: genome)
            let framing = PlantSceneBuilder.framing(min: reference.min, max: reference.max,
                                                    aspect: Float(pixels.width / pixels.height),
                                                    reserved: 0, reach: reference.reach)
            let distance = framing.distance * 1.12
            let halfWorldHeight = distance * tan(PlantSceneBuilder.verticalHalfAngle)
            let aim = (final.minBounds.y + final.maxBounds.y) * 0.5
                + PlantSceneView.Coordinator.settle * halfWorldHeight
            rig.position = SCNVector3(0, aim, 0)
            camera.position = SCNVector3(0, 0, distance)

            if options.opensOnThePlant {
                let node = nodes.node(for: lapse.final)
                pivot.addChildNode(node)
                live = node
            } else {
                live = nil
            }

            // The stage, drawn once: its pool of light is sized to the plant as
            // it is now, as the screen's is while the film plays.
            let stage = StageBackdrop(palette: genome.palette, presence: lapse.final.heightScale)
                .frame(width: pixels.width, height: pixels.height)
                .environment(\.colorScheme, options.scheme)
            let drawer = ImageRenderer(content: stage)
            drawer.scale = 1
            guard let ground = drawer.cgImage else { throw Failure.cannotDraw }
            self.ground = ground
        }

        func draw(_ moment: TimeLapse.Frame) throws -> CGImage {
            // The turntable, at the stage's rate: a turn in ninety seconds.
            if options.turns {
                pivot.eulerAngles.y = Float(moment.time / 90 * 2 * .pi)
            }
            live?.opacity = options.opensOnThePlant ? CGFloat(moment.live) : 0
            replay.opacity = CGFloat(moment.replay)
            for node in replay.childNodes { node.removeFromParentNode() }
            // The arriving and the resting are one plant held still: built once.
            let held: SCNNode
            if let kept, kept.growth == moment.growth {
                held = kept.node
            } else {
                held = nodes.node(for: moment.growth)
                kept = (moment.growth, held)
            }
            held.opacity = 1
            replay.addChildNode(held)
            if let dissolve = moment.dissolve {
                let incoming = nodes.node(for: dissolve.growth)
                incoming.opacity = CGFloat(TimeLapse.smooth(dissolve.amount / 0.65))
                held.opacity = CGFloat(1 - TimeLapse.smooth((dissolve.amount - 0.35) / 0.65))
                replay.addChildNode(incoming)
            }
            let plant = renderer.snapshot(atTime: moment.time, with: pixels, antialiasingMode: .multisampling4X)

            let width = Int(pixels.width), height = Int(pixels.height)
            guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                          bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { throw Failure.cannotDraw }
            let all = CGRect(x: 0, y: 0, width: width, height: height)
            context.draw(ground, in: all)
            // The sky is drawn top-down, as the screen's canvas is.
            context.saveGState()
            context.translateBy(x: 0, y: CGFloat(height))
            context.scaleBy(x: 1, y: -1)
            TimeLapseSky.draw(moment.sky, in: context, size: pixels, look: look)
            context.restoreGState()
            if let picture = plant.cgImage { context.draw(picture, in: all) }
            guard let image = context.makeImage() else { throw Failure.cannotDraw }
            return image
        }
    }
}
