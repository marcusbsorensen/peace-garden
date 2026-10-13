import AVFoundation
import CoreGraphics
import CoreVideo

/// A turn of the plant on its stem: how long, how far, and how smoothly.
///
/// **It ends on the picture it is a turn of.** The last frame is the plant
/// facing exactly as the still faces, so a Live Photo comes to rest on its own
/// key photo, and a whole turn's last frame is its first: played on a loop it
/// holds that one frame twice, a thirtieth of a second, which at this speed
/// nobody can see.
///
/// The same way round as the stage's turntable (`PlantSceneView`), so the plant
/// in the video turns the way the plant on the phone does.
struct TurnPlan: Sendable, Equatable {
    var seconds: Double
    var framesPerSecond: Int32
    /// How far it goes, in whole turns. One is all the way round.
    var turns: Double

    /// The shared video: once round, slowly, in eight seconds.
    static let video = TurnPlan(seconds: 8, framesPerSecond: 30, turns: 1)

    /// The moving wallpaper: three seconds, the length of a Live Photo the
    /// camera takes and of what the lock screen will play, at the video's own
    /// pace — so three-eighths of a turn, coming to rest on the still.
    static let moving = TurnPlan(seconds: 3, framesPerSecond: 30, turns: 3.0 / 8.0)

    var frameCount: Int { max(2, Int((seconds * Double(framesPerSecond)).rounded())) }

    /// The plant's angle in frame `index`, for a plant whose still faces
    /// `facing`: it arrives there on the last frame.
    func yaw(ofFrame index: Int, facing: Float) -> Float {
        let last = Double(frameCount - 1)
        let behind = (1 - Double(index) / last) * turns * 2 * .pi
        return facing - Float(behind)
    }

    /// When frame `index` is shown.
    func time(ofFrame index: Int) -> CMTime {
        CMTime(value: CMTimeValue(index), timescale: framesPerSecond)
    }

    /// One frame's length.
    var frameDuration: CMTime { CMTime(value: 1, timescale: framesPerSecond) }
}

/// Writes frames into a movie: H.264, one frame at a time, drawn by the caller.
///
/// **Anything that can draw a frame can be a movie.** The turn hands it the
/// plant at an angle; a time-lapse can hand it the plant at an age. What it
/// draws into is the encoder's own pixel buffer, so a frame is drawn once and
/// copied nowhere.
///
/// Run it off the main thread: it waits on the encoder between frames.
enum MovieWriter {

    struct Failure: Error {
        var reason: String
    }

    /// What the file says about itself, beyond the pictures.
    struct Extras {
        /// Items written at the top of the file. A Live Photo's content
        /// identifier goes here.
        var metadata: [AVMetadataItem] = []
        /// When the still a Live Photo is paired with sits in the movie. Written
        /// as the timed `still-image-time` item a Live Photo's movie carries.
        var stillImageTime: CMTime?
    }

    /// Writes `frames` frames of `size` pixels at `framesPerSecond` to `url`.
    ///
    /// `draw` is handed the frame's number and a context over that frame's
    /// pixels, top-left origin of the image at the top, as any `CGContext`
    /// draws an image upright. `progress` hears how far it has got, `0...1`.
    static func write(
        to url: URL,
        fileType: AVFileType,
        size: CGSize,
        frames: Int,
        framesPerSecond: Int32,
        bitsPerSecond: Int,
        extras: Extras = Extras(),
        progress: (Double) -> Void = { _ in },
        draw: (Int, CGContext) throws -> Void
    ) async throws {
        try? FileManager.default.removeItem(at: url)
        let writer = try AVAssetWriter(outputURL: url, fileType: fileType)
        writer.metadata = extras.metadata
        // Nothing else: no creation date, no location, no software tag that is
        // not the encoder's own. `PlantShareFiles` checks the bytes.

        let width = Int(size.width), height = Int(size.height)
        let video = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: bitsPerSecond,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                AVVideoExpectedSourceFrameRateKey: framesPerSecond,
                AVVideoMaxKeyFrameIntervalKey: Int(framesPerSecond),
            ],
            // sRGB pictures, said as such, so a player does not guess at them.
            AVVideoColorPropertiesKey: [
                AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
                AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
                AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2,
            ],
        ])
        video.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: video,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height,
                kCVPixelBufferCGImageCompatibilityKey as String: true,
                kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            ]
        )
        guard writer.canAdd(video) else { throw Failure(reason: "video input") }
        writer.add(video)

        var still: (input: AVAssetWriterInput, adaptor: AVAssetWriterInputMetadataAdaptor)?
        if extras.stillImageTime != nil {
            let made = try stillImageTimeInput()
            guard writer.canAdd(made.input) else { throw Failure(reason: "metadata input") }
            writer.add(made.input)
            still = made
        }

        guard writer.startWriting() else {
            throw writer.error ?? Failure(reason: "start")
        }
        writer.startSession(atSourceTime: .zero)

        let frameDuration = CMTime(value: 1, timescale: framesPerSecond)
        if let still, let at = extras.stillImageTime {
            try await waitUntilReady(still.input, writer: writer)
            let group = AVTimedMetadataGroup(items: [stillImageTimeItem()],
                                             timeRange: CMTimeRange(start: at, duration: frameDuration))
            guard still.adaptor.append(group) else {
                throw writer.error ?? Failure(reason: "still-image-time")
            }
            still.input.markAsFinished()
        }

        for index in 0..<frames {
            try Task.checkCancellation()
            try await waitUntilReady(video, writer: writer)
            guard let pool = adaptor.pixelBufferPool else { throw Failure(reason: "pool") }
            var made: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(nil, pool, &made)
            guard let buffer = made else { throw Failure(reason: "buffer") }

            CVPixelBufferLockBaseAddress(buffer, [])
            let drawn: Bool
            if let space = CGColorSpace(name: CGColorSpace.sRGB),
               let context = CGContext(
                   data: CVPixelBufferGetBaseAddress(buffer),
                   width: width, height: height, bitsPerComponent: 8,
                   bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: space,
                   bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
                       | CGBitmapInfo.byteOrder32Little.rawValue
               ) {
                do {
                    try draw(index, context)
                    drawn = true
                } catch {
                    CVPixelBufferUnlockBaseAddress(buffer, [])
                    writer.cancelWriting()
                    throw error
                }
            } else {
                drawn = false
            }
            CVPixelBufferUnlockBaseAddress(buffer, [])
            guard drawn else {
                writer.cancelWriting()
                throw Failure(reason: "context")
            }

            let time = CMTime(value: CMTimeValue(index), timescale: framesPerSecond)
            guard adaptor.append(buffer, withPresentationTime: time) else {
                throw writer.error ?? Failure(reason: "append \(index)")
            }
            progress(Double(index + 1) / Double(frames))
        }

        video.markAsFinished()
        writer.endSession(atSourceTime: CMTime(value: CMTimeValue(frames), timescale: framesPerSecond))
        await writer.finishWriting()
        guard writer.status == .completed else {
            throw writer.error ?? Failure(reason: "finish")
        }
    }

    /// The encoder takes frames as fast as it can, and says when it cannot.
    private static func waitUntilReady(_ input: AVAssetWriterInput, writer: AVAssetWriter) async throws {
        while !input.isReadyForMoreMediaData {
            guard writer.status == .writing else {
                throw writer.error ?? Failure(reason: "writer stopped")
            }
            try await Task.sleep(for: .milliseconds(4))
        }
    }

    // MARK: Live Photo

    static let contentIdentifierKey = "com.apple.quicktime.content.identifier"
    static let stillImageTimeKey = "com.apple.quicktime.still-image-time"

    /// The item that pairs a movie with its still, by the identifier the still
    /// carries too (`LivePhotoPair`).
    static func contentIdentifierItem(_ identifier: String) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.keySpace = .quickTimeMetadata
        item.key = contentIdentifierKey as NSString
        item.value = identifier as NSString
        item.dataType = kCMMetadataBaseDataType_UTF8 as String
        return item
    }

    private static func stillImageTimeItem() -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.keySpace = .quickTimeMetadata
        item.key = stillImageTimeKey as NSString
        item.value = 0 as NSNumber
        item.dataType = kCMMetadataBaseDataType_SInt8 as String
        return item
    }

    private static func stillImageTimeInput() throws
        -> (input: AVAssetWriterInput, adaptor: AVAssetWriterInputMetadataAdaptor) {
        let specification: NSDictionary = [
            kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier as String:
                "mdta/\(stillImageTimeKey)",
            kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType as String:
                kCMMetadataBaseDataType_SInt8 as String,
        ]
        var description: CMFormatDescription?
        let status = CMMetadataFormatDescriptionCreateWithMetadataSpecifications(
            allocator: kCFAllocatorDefault,
            metadataType: kCMMetadataFormatType_Boxed,
            metadataSpecifications: [specification] as CFArray,
            formatDescriptionOut: &description
        )
        guard status == noErr, let description else { throw Failure(reason: "metadata format") }
        let input = AVAssetWriterInput(mediaType: .metadata, outputSettings: nil,
                                       sourceFormatHint: description)
        input.expectsMediaDataInRealTime = false
        return (input, AVAssetWriterInputMetadataAdaptor(assetWriterInput: input))
    }
}
