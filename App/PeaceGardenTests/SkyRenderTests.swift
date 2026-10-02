import SeedCore
import SwiftUI
import UIKit
import XCTest
@testable import PeaceGarden

/// **The day sky drawn behind a plot the way the garden frames it.**
///
/// Skipped unless `PG_RENDER_SKY` names a folder (passed to the test runner as
/// `TEST_RUNNER_PG_RENDER_SKY`). Nothing else draws the sky and the plot
/// together, and a sky is judged by what it does behind a garden, so this
/// writes the pictures rather than asserting anything about them — `final-07`,
/// `final-13` and `final-17` on 2 October 2026, the day Marcus chose it — and
/// what the sky costs to draw.
///
/// The plot is world 0 at the web plot's 5.2 metres, with five grown plants on
/// it, framed between the heading and the plus as `PlotView.framing` frames it,
/// under the real heading and Close. Shadows are left out: they are drawn
/// elsewhere, and this is about the sky. The birds are rare, so each hour is
/// drawn at the nearest moment a crossing is halfway over, with the light
/// still the hour's; `notes.txt` says when.
@MainActor
final class SkyRenderTests: XCTestCase {
    static let hours = [7, 13, 17]

    func testDrawTheSkyBehindThePlot() async throws {
        guard let path = ProcessInfo.processInfo.environment["PG_RENDER_SKY"], !path.isEmpty else {
            throw XCTSkip("PG_RENDER_SKY is not set")
        }
        let folder = URL(fileURLWithPath: path, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let frame = Self.frame()
        let side = GardenWorlds.drawnForSide
        let relief = GardenWorlds.shared.relief(world: 0, plotSide: side)
        let view = Isometric.fitting(plotSide: side, in: frame.size, area: frame.area,
                                     headroom: GardenSprites.tallestExpected + relief.high,
                                     soilDepth: GardenGround.rimDepth - relief.low)
        let place = Whereabouts.place(of: .current)
        var notes: [String] = [
            "screen \(Int(frame.size.width))x\(Int(frame.size.height)) pt, time zone \(TimeZone.current.identifier), "
                + "latitude \(place.latitude)"
        ]

        for hour in Self.hours {
            let light = GardenGround.Light.at(hour: Double(hour))
            let when = Self.date(hour: hour)
            let moment = Self.crossing(near: when, latitude: place.latitude) ?? when
            let ground = await GardenTerrain.shared.image(world: 0, plotSide: side, view: view,
                                                          size: frame.size, light: light)
            let plants = Self.plants(at: when, hour: Double(hour), view: view, side: side)
            let image = render(light: light, date: moment, view: view, frame: frame,
                               ground: ground, plants: plants)
            try write(image, to: folder.appendingPathComponent("final-\(String(format: "%02d", hour)).png"))
            notes.append("final-\(String(format: "%02d", hour)): \(SkyClouds.day(moment).weather.rawValue) day, "
                + "birds (\(SkyLife.kind(on: moment, latitude: place.latitude).rawValue)) at \(Self.clock(moment)), "
                + "moon at \(Self.round(RealSky.moon(at: moment, place: place).altitude))°")
        }

        notes.append(contentsOf: frameCosts(frame: frame, view: view, latitude: place.latitude))
        try notes.joined(separator: "\n").write(to: folder.appendingPathComponent("notes.txt"),
                                                atomically: true, encoding: .utf8)
    }

    // MARK: What it costs

    /// What the sky costs to draw, at the phone's own scale, averaged.
    ///
    /// **These are the simulator's CPU rasterising into a CoreGraphics
    /// bitmap**, not the phone's GPU drawing a canvas, so they are for
    /// comparing with each other and with the old sky, not a promise about a
    /// frame on a device.
    ///
    /// Two canvases. The still one — the day's light, the stars, the bodies —
    /// is drawn again when the garden's clock ticks, every twenty seconds, and
    /// its picture is painted again at most once a minute. The moving one —
    /// clouds and birds — is drawn every frame, at twelve frames a second for
    /// clouds, thirty during a crossing, and not at all on a clear day between
    /// crossings.
    private func frameCosts(frame: Frame, view: Isometric, latitude: Double) -> [String] {
        let light = GardenGround.Light.at(hour: 10)
        let keepClear = [frame.heading, frame.close]
        // The still canvas alone: a day with no clouds, at a moment with no
        // birds, so nothing that moves is drawn into it.
        let calm = (0..<120).lazy
            .map { Self.date(hour: 10).addingTimeInterval(Double($0) * 86_400) }
            .first { SkyClouds.day($0).clouds.isEmpty && SkyLife.flight(at: $0, latitude: latitude) == nil }
            ?? Self.date(hour: 10)

        var lines = ["", "frame costs at 10:00, ms of CoreGraphics at 3x, mean of 12 after a warm-up",
                     "still canvas (redrawn every 20 s):"]
        func still(_ name: String, asItWas: Bool, repaint: Bool) {
            let ms = Self.cost(size: frame.size) { index in
                if repaint { DaySky.forget() }
                return GardenSky(light: light, date: calm.addingTimeInterval(Double(index) / 1000), view: view,
                                 keepClear: keepClear, asItWas: asItWas, isStill: true)
            }
            lines.append("  \(name): \(String(format: "%.1f", ms))")
        }
        still("the old day", asItWas: true, repaint: false)
        still("chosen, picture kept (every redraw)", asItWas: false, repaint: false)
        still("chosen, picture painted again (once a minute)", asItWas: false, repaint: true)

        // What the picture saves: the same gradients painted at full size,
        // which is what the still canvas did on every redraw before.
        let palette = SkyPalette.at(elevation: SunPath.elevation(atHour: 10, peak: 35))
        let sun = CGPoint(x: 12, y: 180)
        var full: TimeInterval = 0
        for _ in 0..<12 {
            let start = Date()
            _ = DaySky.paint(palette, sun: sun, size: frame.size, perPoint: 3)
            full += Date().timeIntervalSince(start)
        }
        lines.append("  the day's gradients alone, painted full size: \(String(format: "%.1f", full / 12 * 1000))")

        lines.append("moving canvas (redrawn every frame while anything moves):")
        let busy = Self.crossing(near: Self.date(hour: 10), latitude: latitude) ?? Self.date(hour: 10)
        let moving: [(String, Bool, Bool)] = [("clouds", true, false), ("birds, mid-crossing", false, true),
                                              ("both", true, true)]
        for (name, clouds, life) in moving {
            let ms = Self.cost(size: frame.size) { index in
                Canvas { context, size in
                    let moment = busy.addingTimeInterval(Double(index) / 30)
                    if clouds {
                        SkyClouds.draw(at: moment, in: &context, size: size, palette: palette, sun: sun,
                                       up: light.up, keepClear: keepClear)
                    }
                    if life {
                        SkyLife.draw(at: moment, latitude: latitude, in: &context, size: size,
                                     palette: palette, up: light.up, keepClear: keepClear)
                    }
                }
            }
            lines.append("  \(name): \(String(format: "%.2f", ms))")
        }
        return lines
    }

    /// Milliseconds to draw a view into a bitmap of our own through `render`,
    /// which hands over a CoreGraphics context and so cannot answer from a
    /// cache. Each pass gets a slightly different view for the same reason.
    private static func cost<Content: View>(size: CGSize, _ make: (Int) -> Content) -> Double {
        func once(_ index: Int) -> TimeInterval {
            let renderer = ImageRenderer(content: make(index).frame(width: size.width, height: size.height))
            var took: TimeInterval = 0
            renderer.render(rasterizationScale: 3) { drawn, draw in
                guard let bitmap = CGContext(data: nil, width: Int(drawn.width * 3), height: Int(drawn.height * 3),
                                             bitsPerComponent: 8, bytesPerRow: 0,
                                             space: CGColorSpaceCreateDeviceRGB(),
                                             bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
                else { return }
                bitmap.scaleBy(x: 3, y: 3)
                let start = Date()
                draw(bitmap)
                took = Date().timeIntervalSince(start)
            }
            return took
        }
        _ = once(0)
        return (1...12).reduce(0.0) { $0 + once($1) } / 12 * 1000
    }

    // MARK: Drawing a frame

    struct Frame {
        var size: CGSize
        var top: CGFloat
        var bottom: CGFloat
        var heading: CGRect
        var close: CGRect
        var area: CGRect
    }

    /// The screen, and where the heading, Close and the plus stand on it.
    static func frame() -> Frame {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        let size = scene?.screen.bounds.size ?? CGSize(width: 420, height: 912)
        let insets = scene?.windows.first?.safeAreaInsets ?? UIEdgeInsets(top: 62, left: 0, bottom: 34, right: 0)
        let top = max(insets.top, 44)
        let bottom = max(insets.bottom, 20)
        // The heading's frame includes the 44 points over it, as
        // `PlotView`'s measurement does.
        let heading = CGRect(x: 26, y: top, width: 190, height: 44 + 48)
        let close = CGRect(x: size.width - 12 - 42, y: top + 12, width: 42, height: 42)
        let foot = size.height - bottom - 12 - 42
        return Frame(size: size, top: top, bottom: bottom, heading: heading, close: close,
                     area: CGRect(x: 0, y: top, width: size.width, height: foot - top))
    }

    struct Standing {
        var image: UIImage
        var size: CGSize
        var foot: CGPoint
    }

    /// Five plants, grown, on the plot, far to near.
    static func plants(at date: Date, hour: Double, view: Isometric, side: Double) -> [Standing] {
        let spots: [(x: Double, z: Double)] = [(-1.4, -1.2), (0.9, -1.5), (0.1, -0.2), (-1.5, 1.0), (1.3, 0.8)]
        let steps = GardenGround.Light.steps(at: hour)
        let step = steps.blend < 0.5 ? steps.before : steps.after
        var standing: [Standing] = []
        for (index, spot) in spots.enumerated().sorted(by: { $0.element.x + $0.element.z < $1.element.x + $1.element.z }) {
            var bytes = [UInt8](repeating: 0, count: 32)
            bytes[0] = UInt8(index * 37 + 11)
            bytes[1] = 0x5C
            bytes[2] = 0x1E
            guard let seed = SeedID(bytes: Data(bytes)) else { continue }
            let genome = Genome(seed: seed, lineage: .minted)
            // A fortnight into the first flush, as `Developer.wind` lands a
            // mature plant: grown, and flowering if it flowers.
            let model = GrowthModel(genome: genome)
            let age = model.start(of: .mature) + 14 * 86_400
            let growth = model.state(birth: date.addingTimeInterval(-age), now: date)
            guard let sprite = GardenSprites.shared.sprite(genome: genome, growth: growth, step: step) else { continue }
            let y = GardenWorlds.shared.height(world: 0, x: spot.x, z: spot.z, plotSide: side)
            standing.append(Standing(
                image: sprite.image,
                size: GardenSprites.drawnSize(metres: sprite.metres, pointsPerMetre: view.pointsPerMetre),
                foot: view.point(x: spot.x, y: y, z: spot.z)
            ))
        }
        return standing
    }

    private func render(light: GardenGround.Light, date: Date, view: Isometric, frame: Frame,
                        ground: UIImage?, plants: [Standing]) -> UIImage {
        let content = ZStack(alignment: .topLeading) {
            Color.black
            GardenSky(light: light, date: date, view: view, keepClear: [frame.heading, frame.close],
                      asItWas: false, isStill: true)
            if let ground {
                Image(uiImage: ground).resizable().frame(width: frame.size.width, height: frame.size.height)
            }
            ForEach(plants.indices, id: \.self) { index in
                let plant = plants[index]
                Image(uiImage: plant.image)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: plant.size.width, height: plant.size.height)
                    .position(x: plant.foot.x, y: plant.foot.y - plant.size.height / 2)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Peace garden")
                    .chromeHeading(size: 18)
                    .foregroundStyle(Chrome.ink)
                Text("5 grown from meetings")
                    .chromeLabel()
                    .foregroundStyle(Chrome.faint)
            }
            .padding(.top, frame.top + 44)
            .padding(.leading, 26)
            CloseButton {}
                .position(x: frame.close.midX, y: frame.close.midY)
            TrayToggle(isOpen: false) {}
                .position(x: frame.size.width / 2, y: frame.size.height - frame.bottom - 12 - 21)
        }
        .frame(width: frame.size.width, height: frame.size.height)
        .environment(\.colorScheme, .dark)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        return renderer.uiImage ?? UIImage()
    }

    // MARK: Dates

    /// 2 October 2026, the day Marcus chose the sky, at an hour in this time zone.
    static func date(hour: Int, minute: Int = 0) -> Date {
        var parts = DateComponents()
        parts.year = 2026; parts.month = 10; parts.day = 2; parts.hour = hour; parts.minute = minute
        return Calendar.current.date(from: parts)!
    }

    /// The moment nearest `date` at which a crossing is halfway over.
    static func crossing(near date: Date, latitude: Double) -> Date? {
        var best: Date?
        for slot in -6...6 {
            let probe = date.addingTimeInterval(Double(slot) * SkyLife.slot)
            guard let flight = SkyLife.flight(inSlotOf: probe, latitude: latitude) else { continue }
            let middle = flight.start.addingTimeInterval(flight.duration * 0.45)
            if best == nil || abs(middle.timeIntervalSince(date)) < abs(best!.timeIntervalSince(date)) {
                best = middle
            }
        }
        return best
    }

    private static func clock(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        return String(format: "%02d:%02d:%02d", parts.hour ?? 0, parts.minute ?? 0, parts.second ?? 0)
    }

    private static func round(_ value: Double) -> String { String(format: "%.0f", value) }

    private func write(_ image: UIImage, to url: URL) throws {
        let data = try XCTUnwrap(image.pngData())
        try data.write(to: url)
    }
}
