import XCTest
import SwiftUI
@testable import PeaceGarden

/// What the departure has to do, checked on the pixels it actually draws.
///
/// **A 1.7-second animation cannot be verified by looking at it.** It was tried:
/// a screenshot of the simulator taken the instant the hold completed came back
/// showing the garden, already closed, because the round trip is longer than the
/// flight. Which leaves either a screen recording — a video to scrub through by
/// hand every time this file changes — or rendering the same view at fixed
/// points along the flight and reading the result. This does the second, so the
/// thing that says the animation still works is a thing that runs in CI rather
/// than a person watching.
///
/// `ReleaseFlight` was written to make this possible: the whole flight is one
/// `progress`, nothing in it reads a clock, and the sparks' wobble is a function
/// of their index. Rendering at 0.4 twice gives identical pixels.
final class ReleaseFlightTests: XCTestCase {

    private let size = CGSize(width: 402, height: 874)

    /// Renders the flight at one point along it, on black, and hands back the
    /// pixels. `ImageRenderer` is main-actor work, which is why every test here
    /// is too.
    @MainActor
    private func render(progress: Double) throws -> CGImage {
        let view = ZStack {
            Color.black
            ReleaseFlight(progress: progress, tint: .white)
        }
        .frame(width: size.width, height: size.height)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        let image = try XCTUnwrap(renderer.cgImage, "nothing rendered at \(progress)")
        return image
    }

    /// Where the light is and how far it is spread: the brightest pixel's row,
    /// the lit area, and the topmost and bottommost rows with anything in them.
    ///
    /// The span is the one that matters for the trail. Lit *area* is dominated
    /// by the head's glow, which is widest at the start — measuring it said the
    /// flight shed nothing, when what it actually had was a head three times
    /// the size of its trail. How tall the lit part is says whether there is a
    /// trail behind the head, which is what the eye is reading.
    private func lit(_ image: CGImage) throws
        -> (brightestRow: Int, litPixels: Int, topRow: Int, bottomRow: Int) {
        let width = image.width, height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let context = try XCTUnwrap(CGContext(
            data: &pixels, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        var brightest = 0, brightestRow = height, count = 0
        var topRow = height, bottomRow = -1
        for y in 0..<height {
            for x in 0..<width {
                let value = Int(pixels[(y * width + x) * 4])
                if value > 12 {
                    count += 1
                    topRow = min(topRow, y)
                    bottomRow = max(bottomRow, y)
                }
                if value > brightest { brightest = value; brightestRow = y }
            }
        }
        return (brightestRow, count, topRow, bottomRow)
    }

    /// **The light leaves.** It starts at the plant's base, low on the screen,
    /// and every step of the flight puts it higher than the last. A flight that
    /// went sideways, or stalled, or drifted back down would pass a test that
    /// only asked whether something was drawn.
    @MainActor
    func testTheLightClimbs() throws {
        var rows: [Int] = []
        for progress in [0.05, 0.25, 0.5, 0.75] {
            rows.append(try lit(try render(progress: progress)).brightestRow)
        }
        for (earlier, later) in zip(rows, rows.dropFirst()) {
            XCTAssertLessThan(later, earlier,
                              "the light has to be higher than it was: \(rows)")
        }
        XCTAssertGreaterThan(rows[0], Int(size.height) / 2,
                             "it starts at the plant's base, low on the screen")
    }

    /// **It sheds a trail, and the trail is what says it is alive.** Early on
    /// there is a head and almost nothing behind it; by the middle the lit part
    /// of the screen is many times taller than the head that leads it.
    @MainActor
    func testItShedsSparks() throws {
        let early = try lit(try render(progress: 0.08))
        let middle = try lit(try render(progress: 0.5))
        let earlySpan = early.bottomRow - early.topRow
        let middleSpan = middle.bottomRow - middle.topRow
        XCTAssertGreaterThan(middleSpan, earlySpan * 3,
                             "the trail should be the greater part of what is lit: "
                             + "\(earlySpan) then \(middleSpan)")
        XCTAssertGreaterThan(middleSpan, Int(size.height) / 4,
                             "a trail a quarter of the screen tall reads as one")
    }

    /// **It ends dark.** Whatever is on screen when the record is removed has
    /// to be nothing: a light still burning at the end would be a light that
    /// vanishes on the next frame instead of leaving.
    @MainActor
    func testItEndsWithNothingLit() throws {
        let end = try lit(try render(progress: 1.0)).litPixels
        XCTAssertLessThan(end, 60, "the flight should be over at 1, not fading")
    }

    /// **The same flight every time.** The sparks' wobble is a function of the
    /// spark's index rather than of a random number, which is what makes the
    /// three tests above mean anything at all.
    @MainActor
    func testItIsTheSameFlightEveryTime() throws {
        let once = try lit(try render(progress: 0.4))
        let again = try lit(try render(progress: 0.4))
        XCTAssertEqual(once.brightestRow, again.brightestRow)
        XCTAssertEqual(once.litPixels, again.litPixels)
    }

    /// Writes the flight out as PNGs, for looking at rather than for asserting.
    ///
    ///     PG_FLIGHT_FRAMES=/tmp/flight swift test / xcodebuild test
    ///
    /// Skipped without the variable, so CI renders nothing and nobody has to
    /// keep a directory of images in the repository.
    @MainActor
    func testWriteFramesForLookingAt() throws {
        guard let directory = ProcessInfo.processInfo.environment["PG_FLIGHT_FRAMES"] else {
            throw XCTSkip("set PG_FLIGHT_FRAMES to write the frames out")
        }
        let url = URL(fileURLWithPath: directory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)

        for step in stride(from: 0.0, through: 1.0, by: 0.1) {
            let image = try render(progress: step)
            let file = url.appendingPathComponent(String(format: "flight-%02.0f.png", step * 100))
            let destination = try XCTUnwrap(CGImageDestinationCreateWithURL(
                file as CFURL, "public.png" as CFString, 1, nil))
            CGImageDestinationAddImage(destination, image, nil)
            XCTAssertTrue(CGImageDestinationFinalize(destination))
        }
    }
}
