import SwiftUI
import UIKit
import XCTest
@testable import PeaceGarden

/// **The name and the version on the launch moment**: that they can be read on
/// its ground, that they stay small and below the plant at every text size, and
/// that the update glyph can stand beside the version without moving it.
///
/// The last test writes pictures and asserts nothing, skipped unless
/// `PG_RENDER_LOADING` names a folder, as `LoadingTests`' harness is.
@MainActor
final class LaunchLabelTests: XCTestCase {

    private typealias RGB = Fiddlehead.Palette.RGB

    /// On the launch ground in both appearances, so the colours are fixed: the
    /// name at the chrome's `muted` level and the version at `faint`, both
    /// clear of WCAG AA for small text, and the name the brighter of the two.
    func testTheNameAndVersionAreLegibleOnTheLaunchGround() {
        let ground = Fiddlehead.Palette.launchGround
        let name = LaunchNameplate.landed(LaunchNameplate.nameOpacity).contrast(with: ground)
        let version = LaunchNameplate.landed(LaunchNameplate.versionOpacity).contrast(with: ground)
        XCTAssertEqual(name, 9.1, accuracy: 0.1)
        XCTAssertEqual(version, 5.9, accuracy: 0.1)
        XCTAssertGreaterThan(version, 4.5)
        XCTAssertGreaterThan(name, version)
        // Quieter than the plant's own leaf, which is the brightest thing there.
        XCTAssertLessThan(name, Fiddlehead.Palette.onDark.leaf.contrast(with: ground))
        XCTAssertEqual(LaunchNameplate.ink, RGB(hex: 0xF4F3EF), "the logo's warm white")
    }

    /// Small: smaller than the site's 22 px wordmark, and the chosen placement
    /// is the recommendation.
    func testItIsSmallAndTheRecommendationIsDrawn() {
        for placement in LaunchNameplate.Placement.allCases {
            XCTAssertLessThan(LaunchNameplate.nameSize(placement), 22, "\(placement)")
        }
        XCTAssertEqual(LaunchNameplate.chosen, .stacked)
        XCTAssertEqual(LaunchNameplate.name, "Peace Garden")
        XCTAssertEqual(LaunchNameplate.tracking, 0.18, "the wordmark's letter-spacing")
        XCTAssertLessThanOrEqual(LaunchNameplate.largestType, .xxxLarge)
    }

    /// Where the ink lands, on the launch ground, at the largest text size there
    /// is: below the frame the plant is drawn in, and inside the screen, on a
    /// small phone, a tall one and an iPad, for every placement, with the update
    /// glyph showing. The type stops at `largestType`, so asking for the largest
    /// accessibility size must not push it into the plant.
    func testItStaysBelowThePlantAtEveryTextSize() throws {
        let screens: [(CGSize, CGFloat)] = [
            (CGSize(width: 375, height: 667), 0),
            (CGSize(width: 390, height: 844), 34),
            (CGSize(width: 744, height: 1133), 20),
        ]
        for (screen, inset) in screens {
            let frame = LaunchMoment.markFrame(short: min(screen.width, screen.height))
            let plantFoot = screen.height / 2 + frame.height / 2
            for placement in LaunchNameplate.Placement.allCases {
                for size in [DynamicTypeSize.large, .accessibility5] {
                    let ink = try inkBounds(Self.labelOnly(placement: placement, glyph: true, screen: screen,
                                                           inset: inset, type: size))
                    let tag = "\(placement) \(Int(screen.width))x\(Int(screen.height)) \(size)"
                    XCTAssertGreaterThan(ink.minY, plantFoot, tag)
                    XCTAssertLessThan(ink.maxY, screen.height - inset, tag)
                    XCTAssertGreaterThan(ink.minX, 8, tag)
                    XCTAssertLessThan(ink.maxX, screen.width - 8, tag)
                    if size == .large, placement != .underPlant {
                        XCTAssertLessThan(ink.height, 48, "quiet and small: \(tag)")
                    }
                }
            }
        }
    }

    /// The update glyph hangs beside the version and does not move it: the
    /// version's ink is where it was without the glyph, and the glyph sits on
    /// its trailing side, which under right to left is the left.
    func testTheGlyphStandsBesideTheVersionWithoutMovingIt() throws {
        // The version's row alone: `underPlant` stands it at the foot by itself,
        // and its name, under the plant, is above the rows measured.
        let screen = CGSize(width: 390, height: 844), row = screen.height - 120
        let plain = try inkBounds(Self.labelOnly(placement: .underPlant, glyph: false, screen: screen, inset: 34),
                                  below: row)
        let glyph = try inkBounds(Self.labelOnly(placement: .underPlant, glyph: true, screen: screen, inset: 34),
                                  below: row)
        let rtl = try inkBounds(Self.labelOnly(placement: .underPlant, glyph: true, screen: screen, inset: 34,
                                               rtl: true), below: row)
        XCTAssertEqual(glyph.minX, plain.minX, accuracy: 1, "the name and version stay put")
        XCTAssertGreaterThan(glyph.maxX, plain.maxX + 6, "the glyph, to the right")
        XCTAssertLessThan(rtl.minX, plain.minX - 6, "and to the left under right to left")
        XCTAssertEqual(rtl.maxX, plain.maxX, accuracy: 1)
    }

    // MARK: - Drawing it

    /// The foot of the moment alone, the plant left out, as it would stand on a
    /// phone with `inset` points of home indicator under it.
    static func labelOnly(placement: LaunchNameplate.Placement, glyph: Bool, screen: CGSize, inset: CGFloat,
                          type: DynamicTypeSize = .large, rtl: Bool = false) -> some View {
        ZStack {
            LaunchMoment.ground
            LaunchNameplateUnderPlant(screen: screen, placement: placement)
            LaunchNameplateFoot(placement: placement) {
                if glyph { LaunchUpdateGlyph {} }
            }
            .padding(.bottom, inset)
        }
        .frame(width: screen.width, height: screen.height)
        .environment(\.dynamicTypeSize, type)
        .environment(\.layoutDirection, rtl ? .rightToLeft : .leftToRight)
        .environment(\.locale, Locale(identifier: rtl ? "ar" : "en"))
    }

    /// The box round everything drawn brighter than the ground, in points.
    private func inkBounds(_ view: some View, below top: CGFloat = 0) throws -> CGRect {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        let image = try XCTUnwrap(renderer.uiImage?.cgImage)
        let data = try XCTUnwrap(image.dataProvider?.data)
        let bytes = try XCTUnwrap(CFDataGetBytePtr(data))
        let row = image.bytesPerRow, step = image.bitsPerPixel / 8
        var minX = Int.max, minY = Int.max, maxX = -1, maxY = -1
        for y in Int(top * 2)..<image.height {
            for x in 0..<image.width {
                let i = y * row + x * step
                // The ground is #0D0D1F; anything with a channel well above it
                // is ink. The order of the channels does not matter for that.
                if max(Int(bytes[i]), Int(bytes[i + 1]), Int(bytes[i + 2])) > 70 {
                    minX = min(minX, x); maxX = max(maxX, x)
                    minY = min(minY, y); maxY = max(maxY, y)
                }
            }
        }
        XCTAssertGreaterThanOrEqual(maxX, 0, "something was drawn")
        return CGRect(x: CGFloat(minX) / 2, y: CGFloat(minY) / 2,
                      width: CGFloat(maxX - minX + 1) / 2, height: CGFloat(maxY - minY + 1) / 2)
    }

    // MARK: - The pictures

    /// The end of the moment as the harness draws it — the launch ground and the
    /// fiddlehead at t = 1 on a 390 × 844 phone, `LaunchMoment.mark` — with each
    /// placement of the name and version over it, with and without the update
    /// glyph, and the recommendation under right to left, at the largest text
    /// size and in the light appearance. A 34-point home indicator is left
    /// under the foot, as a Face ID phone has. Skipped unless `PG_RENDER_LOADING`
    /// names a folder.
    func testWriteTheLaunchLabelFrames() throws {
        guard let path = ProcessInfo.processInfo.environment["PG_RENDER_LOADING"], !path.isEmpty else {
            throw XCTSkip("PG_RENDER_LOADING is not set")
        }
        let folder = URL(fileURLWithPath: path, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let phone = CGSize(width: 390, height: 844)

        func end(_ placement: LaunchNameplate.Placement, glyph: Bool, type: DynamicTypeSize = .large,
                 rtl: Bool = false, scheme: ColorScheme = .dark) -> some View {
            ZStack {
                LaunchMoment.ground
                LaunchMoment.mark(at: 1, in: phone, style: .standard)
                LaunchNameplateUnderPlant(screen: phone, placement: placement)
                LaunchNameplateFoot(placement: placement) {
                    if glyph { LaunchUpdateGlyph {} }
                }
                .padding(.bottom, 34)
            }
            .frame(width: phone.width, height: phone.height)
            .environment(\.dynamicTypeSize, type)
            .environment(\.colorScheme, scheme)
            .environment(\.layoutDirection, rtl ? .rightToLeft : .leftToRight)
            .environment(\.locale, Locale(identifier: rtl ? "ar" : "en"))
        }

        func write(_ view: some View, _ name: String) throws {
            let renderer = ImageRenderer(content: view)
            renderer.scale = 3
            let png = try XCTUnwrap(renderer.uiImage?.pngData())
            try png.write(to: folder.appendingPathComponent("\(name).png"))
        }

        for placement in LaunchNameplate.Placement.allCases {
            try write(end(placement, glyph: false), "label-\(placement.rawValue)")
            try write(end(placement, glyph: true), "label-\(placement.rawValue)-glyph")
        }
        try write(end(.stacked, glyph: true, rtl: true), "label-stacked-glyph-rtl")
        try write(end(.stacked, glyph: true, type: .accessibility5), "label-stacked-glyph-largest")
        try write(end(.stacked, glyph: true, scheme: .light), "label-stacked-glyph-light")
    }
}
