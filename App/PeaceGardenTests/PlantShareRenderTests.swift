import SeedCore
import UIKit
import XCTest
@testable import PeaceGarden

/// **What the Share mark makes, drawn to be looked at** — the three grounds on
/// an iPhone Air's lock screen, the shared picture, the turning video and the
/// Live Photo, written where `PG_RENDERS` says, for
/// `design/share-plant-2026-10-13/`.
///
/// Skipped unless `PG_RENDERS` names a folder, which `xcodebuild test` passes
/// through as `TEST_RUNNER_PG_RENDERS`. `PG_SHARE_SEED` picks the plant; the
/// default is the one the pictures in the design folder show.
@MainActor
final class PlantShareRenderTests: XCTestCase {

    /// An iPhone Air: 420 by 912 points at three pixels a point.
    private static let air = CGSize(width: 1260, height: 2736)

    func testDrawWhatTheShareMarkMakes() async throws {
        guard let folder = ProcessInfo.processInfo.environment["PG_RENDERS"], !folder.isEmpty else {
            throw XCTSkip("PG_RENDERS is not set")
        }
        let out = URL(fileURLWithPath: folder, isDirectory: true)
        try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

        let words = ProcessInfo.processInfo.environment["PG_SHARE_SEED"] ?? "share-render-6"
        let genome = Genome(seed: SeedID(bytes: seedDigest(SeedDomain.seed, Data(words.utf8)))!)
        let growth = Maturity.bloomPreview(for: genome)

        // The three grounds, as wallpapers, bare and on a lock screen.
        for (letter, ground) in zip(["A", "B", "C"], ShareGround.allCases) {
            let portrait = PlantPortrait.wallpaper(genome: genome, growth: growth,
                                                   nativePixels: Self.air, scale: 3, ground: ground)
            let backdrop = try XCTUnwrap(ShareBackdrop.image(for: portrait))
            let renderer = try XCTUnwrap(PlantPictureRenderer(portrait: portrait, backdrop: backdrop))
            let still = try XCTUnwrap(renderer.still())
            try Self.png(still, to: out.appendingPathComponent("wallpaper-\(letter).png"))
            try Self.png(Self.lockScreen(over: still), to: out.appendingPathComponent("lock-\(letter).png"))
        }

        // The shared picture, as the share sheet is handed it.
        let picture = PlantPortrait.picture(genome: genome, growth: growth)
        let pictureURL = try PlantShareFiles.picture(
            picture, backdrop: SharedImage(image: try XCTUnwrap(ShareBackdrop.image(for: picture))))
        try Self.copy(pictureURL, to: out.appendingPathComponent("picture.jpg"))

        // The turning video, whole.
        let turning = PlantPortrait.turning(genome: genome, growth: growth)
        let videoURL = try await PlantShareFiles.turning(
            turning, backdrop: SharedImage(image: try XCTUnwrap(ShareBackdrop.image(for: turning))))
        try Self.copy(videoURL, to: out.appendingPathComponent("turning.mp4"))

        // The moving wallpaper, at an Air's size.
        let moving = PlantPortrait.wallpaper(genome: genome, growth: growth,
                                             nativePixels: Self.air, scale: 3)
        let pair = try await PlantShareFiles.movingWallpaper(
            moving, backdrop: SharedImage(image: try XCTUnwrap(ShareBackdrop.image(for: moving))))
        try Self.copy(pair.still, to: out.appendingPathComponent("moving.\(pair.still.pathExtension)"))
        try Self.copy(pair.movie, to: out.appendingPathComponent("moving.mov"))
    }

    /// The same plant under the sky of four hours on the phone's clock — nine
    /// in the morning, ten past six and half past six at dusk, eleven at night
    /// — as wallpapers on the lock screen, its clock saying the hour, and as
    /// the shared picture, for
    /// `design/ui-followups-2026-10-14/backgrounds-hours.png`. Two at dusk,
    /// because the garden's is short: amber just after the sun goes at six,
    /// violet and faint by half past.
    func testDrawTheSkyByTheHour() throws {
        guard let folder = ProcessInfo.processInfo.environment["PG_RENDERS"], !folder.isEmpty else {
            throw XCTSkip("PG_RENDERS is not set")
        }
        let out = URL(fileURLWithPath: folder, isDirectory: true)
        try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

        let words = ProcessInfo.processInfo.environment["PG_SHARE_SEED"] ?? "share-render-6"
        let genome = Genome(seed: SeedID(bytes: seedDigest(SeedDomain.seed, Data(words.utf8)))!)
        let growth = Maturity.bloomPreview(for: genome)
        for (name, hour, clock) in [("0900", 9.0, "9:00"), ("1810", 18.0 + 10.0 / 60, "18:10"),
                                    ("1830", 18.5, "18:30"), ("2300", 23.0, "23:00")] {
            let wallpaper = PlantPortrait.wallpaper(genome: genome, growth: growth, nativePixels: Self.air,
                                                    scale: 3, ground: .byTheHour, hour: hour)
            let ground = try XCTUnwrap(ShareBackdrop.image(for: wallpaper))
            let still = try XCTUnwrap(PlantPictureRenderer(portrait: wallpaper, backdrop: ground)?.still())
            try Self.png(Self.lockScreen(over: still, time: clock),
                         to: out.appendingPathComponent("lock-hour-\(name).png"))

            let picture = PlantPortrait.picture(genome: genome, growth: growth, hour: hour)
            let pictureGround = try XCTUnwrap(ShareBackdrop.image(for: picture))
            let shared = try XCTUnwrap(PlantPictureRenderer(portrait: picture, backdrop: pictureGround)?.still())
            try Self.png(shared, to: out.appendingPathComponent("picture-hour-\(name).png"))

            // For comparison only, not drawn by the app: the time-lapse's sky
            // (`TimeLapseSky`) for the same hour over the stage, which has no
            // horizon and whose twilight is rose and mauve over the whole glass.
            let lapse = try Self.lapseGround(for: wallpaper, hour: hour)
            let lapsed = try XCTUnwrap(PlantPictureRenderer(portrait: wallpaper, backdrop: lapse)?.still())
            try Self.png(Self.lockScreen(over: lapsed, time: clock),
                         to: out.appendingPathComponent("lock-hour-\(name)-lapse.png"))
        }
    }

    /// Black, the time-lapse's sky at full presence over it, as the film
    /// draws it in Dark, and the stage's pool showing through.
    private static func lapseGround(for portrait: PlantPortrait, hour: Double) throws -> CGImage {
        var stage = portrait
        stage.ground = .stage
        let pool = try XCTUnwrap(ShareBackdrop.image(for: stage))
        let format = UIGraphicsImageRendererFormat()
        format.scale = portrait.pixelsPerPoint
        format.opaque = true
        let image = UIGraphicsImageRenderer(size: portrait.points, format: format).image { drawing in
            let context = drawing.cgContext
            context.saveGState()
            context.translateBy(x: 0, y: portrait.points.height)
            context.scaleBy(x: 1, y: -1)
            context.draw(pool, in: CGRect(origin: .zero, size: portrait.points))
            context.restoreGState()
            let moment = TimeLapseSky.Moment(elevation: SunPath.elevation(atHour: hour), presence: 1)
            TimeLapseSky.draw(moment, in: context, size: portrait.points, look: .dark)
        }
        return try XCTUnwrap(image.cgImage)
    }

    /// A few plants at a glance, to choose the one the pictures show.
    func testDrawCandidatePlants() throws {
        guard let folder = ProcessInfo.processInfo.environment["PG_RENDERS"], !folder.isEmpty,
              ProcessInfo.processInfo.environment["PG_SHARE_CANDIDATES"] != nil else {
            throw XCTSkip("PG_RENDERS and PG_SHARE_CANDIDATES are not both set")
        }
        let out = URL(fileURLWithPath: folder, isDirectory: true)
        try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
        for n in 1...8 {
            let genome = Genome(seed: SeedID(bytes: seedDigest(SeedDomain.seed, Data("share-render-\(n)".utf8)))!)
            var portrait = PlantPortrait.picture(genome: genome, growth: Maturity.bloomPreview(for: genome))
            portrait.pixels = CGSize(width: 360, height: 450)
            portrait.pixelsPerPoint = 0.75
            let backdrop = try XCTUnwrap(ShareBackdrop.image(for: portrait))
            let still = try XCTUnwrap(PlantPictureRenderer(portrait: portrait, backdrop: backdrop)?.still())
            try Self.png(still, to: out.appendingPathComponent("candidate-\(n).png"))
        }
    }

    // MARK: The lock screen

    /// A lock screen drawn over a wallpaper, near enough to judge the
    /// composition by: the date and the time where iOS sets them, the torch and
    /// the camera at the foot, and the home indicator. Not the system's own
    /// drawing — the clock's face and weight vary with the phone's settings —
    /// but its places and its sizes.
    static func lockScreen(over wallpaper: CGImage, time: String = "9:41") -> CGImage {
        let points = CGSize(width: CGFloat(wallpaper.width) / 3, height: CGFloat(wallpaper.height) / 3)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
        format.opaque = true
        let image = UIGraphicsImageRenderer(size: points, format: format).image { drawing in
            let context = drawing.cgContext
            context.saveGState()
            context.translateBy(x: 0, y: points.height)
            context.scaleBy(x: 1, y: -1)
            context.draw(wallpaper, in: CGRect(origin: .zero, size: points))
            context.restoreGState()

            let white = UIColor(white: 1, alpha: 0.92)
            func centred(_ text: String, font: UIFont, top: CGFloat, colour: UIColor = white) {
                let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: colour]
                let size = (text as NSString).size(withAttributes: attributes)
                (text as NSString).draw(at: CGPoint(x: (points.width - size.width) / 2, y: top),
                                        withAttributes: attributes)
            }
            let date = UIFont.systemFont(ofSize: 21, weight: .semibold)
            centred("Tuesday 13 October", font: date, top: 66)
            let rounded = UIFont.systemFont(ofSize: 104, weight: .semibold)
            let clockFace = rounded.fontDescriptor.withDesign(.rounded).map { UIFont(descriptor: $0, size: 104) } ?? rounded
            centred(time, font: clockFace, top: 84)

            // The torch and the camera.
            for x in [48.0, points.width - 48] {
                let disc = CGRect(x: x - 25, y: points.height - 112, width: 50, height: 50)
                context.setFillColor(UIColor(white: 0.1, alpha: 0.45).cgColor)
                context.fillEllipse(in: disc)
                let glyph = UIImage(systemName: x < points.width / 2 ? "flashlight.off.fill" : "camera.fill",
                                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 19, weight: .regular))?
                    .withTintColor(.white, renderingMode: .alwaysOriginal)
                if let glyph {
                    glyph.draw(at: CGPoint(x: disc.midX - glyph.size.width / 2, y: disc.midY - glyph.size.height / 2))
                }
            }
            // The home indicator.
            context.setFillColor(UIColor(white: 1, alpha: 0.85).cgColor)
            context.addPath(UIBezierPath(roundedRect: CGRect(x: (points.width - 140) / 2, y: points.height - 14,
                                                             width: 140, height: 5), cornerRadius: 2.5).cgPath)
            context.fillPath()
        }
        return image.cgImage!
    }

    // MARK: Files

    static func png(_ image: CGImage, to url: URL) throws {
        try? FileManager.default.removeItem(at: url)
        try XCTUnwrap(UIImage(cgImage: image).pngData()).write(to: url)
    }

    static func copy(_ from: URL, to url: URL) throws {
        try? FileManager.default.removeItem(at: url)
        try FileManager.default.copyItem(at: from, to: url)
    }
}
