import AVFoundation
import ImageIO
import Photos
import SeedCore
import UIKit
import UniformTypeIdentifiers

/// What the Share mark makes, as files: a picture, a turning video, a
/// wallpaper, and a moving wallpaper.
///
/// **The files say nothing about the plant but its picture.** No seed, no
/// name, no other gardener, no meeting, no place and no date: not in the
/// pixels, not in the metadata, not in the file name. A JPEG is written by
/// ImageIO with no properties but its orientation, a movie by AVFoundation
/// with none but a Live Photo's pairing identifier, which is a fresh random
/// UUID each time. `PlantShareTests` reads every byte for the seed and the name.
///
/// They are written to a folder of their own in the temporary directory, which
/// is emptied before each export, so the phone keeps no copies.
enum PlantShareFiles {

    /// What each file is called, wherever it ends up: the app's name and
    /// nothing else. A mail attachment shows it, and a plant's name in it would
    /// be the one thing in the file that is not a picture.
    static let fileStem = "Peace Garden"

    /// The folder they are written to, emptied first.
    static func freshFolder() throws -> URL {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("Share", isDirectory: true)
        try? FileManager.default.removeItem(at: folder)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    // MARK: Stills

    /// A JPEG of `image`, with nothing in it but the picture.
    ///
    /// `extra` is for a Live Photo's still, which has to carry its pairing
    /// identifier; nothing else passes any.
    static func writeJPEG(_ image: CGImage, to url: URL, extra: [CFString: Any] = [:]) throws {
        try writeImage(image, to: url, type: .jpeg, extra: extra)
    }

    static func writeImage(_ image: CGImage, to url: URL, type: UTType,
                           extra: [CFString: Any] = [:]) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL, type.identifier as CFString, 1, nil
        ) else { throw MovieWriter.Failure(reason: "image destination \(type.identifier)") }
        var properties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.92,
            kCGImagePropertyOrientation: CGImagePropertyOrientation.up.rawValue,
        ]
        properties.merge(extra) { _, new in new }
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw MovieWriter.Failure(reason: "image finalize")
        }
    }

    // MARK: The four

    /// The plant as it is now, as a picture to send.
    static func picture(_ portrait: PlantPortrait, backdrop: SharedImage) throws -> URL {
        guard let renderer = PlantPictureRenderer(portrait: portrait, backdrop: backdrop.image),
              let still = renderer.still()
        else { throw MovieWriter.Failure(reason: "render") }
        let url = try freshFolder().appendingPathComponent("\(fileStem).jpg")
        try writeJPEG(still, to: url)
        return url
    }

    /// The plant once round, as a video to send.
    static func turning(_ portrait: PlantPortrait, backdrop: SharedImage,
                        plan: TurnPlan = .video,
                        progress: (Double) -> Void = { _ in }) async throws -> URL {
        let portrait = portrait.evenSized
        guard let renderer = PlantPictureRenderer(portrait: portrait, backdrop: backdrop.image)
        else { throw MovieWriter.Failure(reason: "render") }
        let url = try freshFolder().appendingPathComponent("\(fileStem).mp4")
        try await MovieWriter.write(
            to: url, fileType: .mp4, size: portrait.pixels,
            frames: plan.frameCount, framesPerSecond: plan.framesPerSecond,
            bitsPerSecond: 10_000_000, progress: progress
        ) { index, context in
            renderer.draw(yaw: plan.yaw(ofFrame: index, facing: portrait.facing), in: context)
        }
        return url
    }

    /// The plant as a wallpaper-sized still, ready for Photos.
    static func wallpaper(_ portrait: PlantPortrait, backdrop: SharedImage) throws -> URL {
        try picture(portrait, backdrop: backdrop)
    }

    /// The plant as a Live Photo: the wallpaper still, and a short turn that
    /// comes to rest on it.
    static func movingWallpaper(_ portrait: PlantPortrait, backdrop: SharedImage,
                                plan: TurnPlan = .moving,
                                progress: (Double) -> Void = { _ in }) async throws -> LivePhotoPair {
        // The still at the screen's own pixels; the movie at the nearest even
        // size, which is the same picture a pixel narrower at most.
        let moving = portrait.evenSized
        guard let stillRenderer = PlantPictureRenderer(portrait: portrait, backdrop: backdrop.image),
              let still = stillRenderer.still(),
              let renderer = PlantPictureRenderer(portrait: moving, backdrop: backdrop.image)
        else { throw MovieWriter.Failure(reason: "render") }
        let folder = try freshFolder()
        return try await LivePhotoPair.write(still: still, plan: plan, size: moving.pixels,
                                             in: folder, progress: progress) { index, context in
            renderer.draw(yaw: plan.yaw(ofFrame: index, facing: moving.facing), in: context)
        }
    }
}

/// A Live Photo as Photos takes one: a still and a movie that say they belong
/// together.
///
/// **What pairs them** is one identifier written into both — in the still's
/// Apple maker note under key `17`, and at the top of the movie as
/// `com.apple.quicktime.content.identifier` — and a timed `still-image-time`
/// item in the movie saying which moment the still is. Here that is the last
/// frame, so the motion ends on the picture.
struct LivePhotoPair: Sendable {
    var still: URL
    var movie: URL
    var identifier: String

    /// The maker note's key for the pairing identifier.
    static let makerNoteKey = "17"

    static func write(
        still: CGImage,
        plan: TurnPlan,
        size: CGSize,
        in folder: URL,
        progress: (Double) -> Void = { _ in },
        draw: (Int, CGContext) throws -> Void
    ) async throws -> LivePhotoPair {
        let identifier = UUID().uuidString
        let stillURL = folder.appendingPathComponent("\(PlantShareFiles.fileStem).heic")
        let movieURL = folder.appendingPathComponent("\(PlantShareFiles.fileStem).mov")
        let maker: [CFString: Any] = [
            kCGImagePropertyMakerAppleDictionary: [makerNoteKey: identifier]
        ]
        // HEIC, as the camera writes; JPEG where this phone cannot encode it.
        let wroteStill: URL
        do {
            try PlantShareFiles.writeImage(still, to: stillURL, type: .heic, extra: maker)
            wroteStill = stillURL
        } catch {
            let jpeg = folder.appendingPathComponent("\(PlantShareFiles.fileStem).jpg")
            try PlantShareFiles.writeJPEG(still, to: jpeg, extra: maker)
            wroteStill = jpeg
        }

        let last = plan.time(ofFrame: plan.frameCount - 1)
        try await MovieWriter.write(
            to: movieURL, fileType: .mov, size: size,
            frames: plan.frameCount, framesPerSecond: plan.framesPerSecond,
            bitsPerSecond: 16_000_000,
            extras: MovieWriter.Extras(
                metadata: [MovieWriter.contentIdentifierItem(identifier)],
                stillImageTime: last
            ),
            progress: progress, draw: draw
        )
        return LivePhotoPair(still: wroteStill, movie: movieURL, identifier: identifier)
    }
}

/// Adding to Photos, with the narrowest permission there is.
///
/// **Add-only.** The app asks to put things in Photos and never to see what is
/// there (`NSPhotoLibraryAddUsageDescription`), so it cannot look back at what
/// it saved either. Whether a saved moving wallpaper came out as a Live Photo
/// is checked by `PlantShareTests` on a simulator given full access, not here.
enum PhotosSaving {

    enum Outcome: Equatable {
        case saved
        case notAllowed
        case failed
    }

    static func ask() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        return status == .authorized || status == .limited
    }

    /// Saves a still, moving it out of the temporary folder.
    static func save(still: URL) async -> Outcome {
        guard await ask() else { return .notAllowed }
        return await perform { request in
            request.addResource(with: .photo, fileURL: still, options: moving())
        }
    }

    /// Saves a Live Photo: its still and its movie, as one asset.
    static func save(_ pair: LivePhotoPair) async -> Outcome {
        guard await ask() else { return .notAllowed }
        return await perform { request in
            request.addResource(with: .photo, fileURL: pair.still, options: moving())
            request.addResource(with: .pairedVideo, fileURL: pair.movie, options: moving())
        }
    }

    /// The identifier of what was made, for a check that has full access.
    static func saveReturningIdentifier(_ pair: LivePhotoPair) async throws -> String? {
        let made = Made()
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, fileURL: pair.still, options: nil)
            request.addResource(with: .pairedVideo, fileURL: pair.movie, options: nil)
            made.identifier = request.placeholderForCreatedAsset?.localIdentifier
        }
        return made.identifier
    }

    /// Carried out of the change block, which Photos runs on a queue of its
    /// own and has finished with before `performChanges` returns.
    private final class Made: @unchecked Sendable {
        var identifier: String?
    }

    private static func moving() -> PHAssetResourceCreationOptions {
        let options = PHAssetResourceCreationOptions()
        options.shouldMoveFile = true
        return options
    }

    private static func perform(
        _ add: @escaping @Sendable (PHAssetCreationRequest) -> Void
    ) async -> Outcome {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                add(PHAssetCreationRequest.forAsset())
            }
            return .saved
        } catch {
            return .failed
        }
    }
}
