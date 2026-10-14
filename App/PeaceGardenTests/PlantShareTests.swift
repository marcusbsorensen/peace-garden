import AVFoundation
import ImageIO
import SeedCore
import SwiftUI
import XCTest
@testable import PeaceGarden

/// What the Share mark makes: the sizes, the turn, the Live Photo's pairing,
/// and that nothing about the plant but its picture goes into a file.
///
/// The pictures here are small where the size is not the thing being tested —
/// a turn of 240 frames at 1080 wide is a minute on a simulator, and the
/// arithmetic that decides how many frames there are does not care how wide
/// they are.
@MainActor
final class PlantShareTests: XCTestCase {

    private static let genome = Genome(
        seed: SeedID(bytes: seedDigest(SeedDomain.seed, Data("share-tests".utf8)))!
    )
    private static var growth: GrowthModel.State { Maturity.bloomPreview(for: genome) }

    /// A portrait of a size quick to draw, composed as the shared picture is.
    private static func small(_ ground: ShareGround = .recommended,
                              width: CGFloat = 360, height: CGFloat = 450) -> PlantPortrait {
        var portrait = PlantPortrait.picture(genome: genome, growth: growth, ground: ground)
        portrait.pixels = CGSize(width: width, height: height)
        portrait.pixelsPerPoint = width / 480
        return portrait
    }

    private static func backdrop(_ portrait: PlantPortrait) throws -> SharedImage {
        SharedImage(image: try XCTUnwrap(ShareBackdrop.image(for: portrait)))
    }

    // MARK: Sizes

    func testThePictureIsFourByFive() throws {
        let portrait = PlantPortrait.picture(genome: Self.genome, growth: Self.growth)
        let renderer = try XCTUnwrap(PlantPictureRenderer(portrait: portrait,
                                                          backdrop: try Self.backdrop(portrait).image))
        let still = try XCTUnwrap(renderer.still())
        XCTAssertEqual(still.width, 1440)
        XCTAssertEqual(still.height, 1800)
    }

    /// The wallpaper is the screen's own pixels: an iPhone Air's, and a phone
    /// an odd number of pixels wide, whose movie is then one pixel narrower.
    func testTheWallpaperIsTheScreensOwnPixels() throws {
        for (native, scale) in [(CGSize(width: 1260, height: 2736), 3.0),
                                (CGSize(width: 1179, height: 2556), 3.0),
                                (CGSize(width: 750, height: 1334), 2.0)] {
            let portrait = PlantPortrait.wallpaper(genome: Self.genome, growth: Self.growth,
                                                   nativePixels: native, scale: scale)
            XCTAssertEqual(portrait.pixels, native)
            let renderer = try XCTUnwrap(PlantPictureRenderer(portrait: portrait,
                                                              backdrop: try Self.backdrop(portrait).image))
            let still = try XCTUnwrap(renderer.still())
            XCTAssertEqual(still.width, Int(native.width))
            XCTAssertEqual(still.height, Int(native.height))

            let even = portrait.evenSized.pixels
            XCTAssertEqual(Int(even.width) % 2, 0)
            XCTAssertEqual(Int(even.height) % 2, 0)
            XCTAssertLessThanOrEqual(native.width - even.width, 1)
        }
    }

    /// The plant is drawn, and drawn over the ground rather than in a box of
    /// its own: a corner is the ground's own colour, and the middle is not.
    func testThePlantStandsOnTheGround() throws {
        let portrait = Self.small()
        let ground = try Self.backdrop(portrait)
        let renderer = try XCTUnwrap(PlantPictureRenderer(portrait: portrait, backdrop: ground.image))
        let still = try Pixels(try XCTUnwrap(renderer.still()))
        let bare = try Pixels(ground.image)

        XCTAssertLessThan(still.difference(from: bare, in: CGRect(x: 0, y: 0, width: 20, height: 20)), 1,
                          "a corner should be the ground, untouched")
        XCTAssertGreaterThan(still.difference(from: bare, in: CGRect(x: 120, y: 120, width: 120, height: 240)), 4,
                             "the middle should have a plant in it")
    }

    // MARK: The turn

    func testTheTurnsArithmetic() {
        XCTAssertEqual(TurnPlan.video.frameCount, 240)
        XCTAssertEqual(TurnPlan.moving.frameCount, 90)
        for plan in [TurnPlan.video, .moving] {
            // It ends facing the way the still faces.
            XCTAssertEqual(plan.yaw(ofFrame: plan.frameCount - 1, facing: 0.5), 0.5, accuracy: 1e-6)
            // It turns the way the stage's turntable does: yaw rising.
            XCTAssertGreaterThan(plan.yaw(ofFrame: 1, facing: 0.5), plan.yaw(ofFrame: 0, facing: 0.5))
        }
        // A whole turn begins where it ends.
        let start = TurnPlan.video.yaw(ofFrame: 0, facing: 0.5)
        XCTAssertEqual(start + 2 * .pi, 0.5, accuracy: 1e-5)
    }

    /// Eight seconds, 240 frames, and the last frame the first: a seamless
    /// turn, which settles where it began.
    func testTheTurningVideoIsSeamless() async throws {
        let portrait = Self.small()
        let url = try await PlantShareFiles.turning(portrait, backdrop: try Self.backdrop(portrait))
        defer { try? FileManager.default.removeItem(at: url) }
        XCTAssertEqual(url.pathExtension, "mp4")

        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        XCTAssertEqual(duration.seconds, 8.0, accuracy: 0.001)

        let frames = try await Self.frames(of: asset)
        XCTAssertEqual(frames.count, 240)
        let first = try XCTUnwrap(frames.first), last = try XCTUnwrap(frames.last)
        let whole = CGRect(x: 0, y: 0, width: first.width, height: first.height)
        XCTAssertLessThan(first.difference(from: last, in: whole), 1.5,
                          "the last frame should be the first: the plant is back where it began")
        // And it does turn: a frame part way round is not the first.
        XCTAssertGreaterThan(first.difference(from: frames[60], in: whole), 1.5)
    }

    // MARK: The Live Photo

    func testTheLivePhotoPairSharesOneIdentifier() async throws {
        let portrait = Self.small(width: 360, height: 780)
        let pair = try await PlantShareFiles.movingWallpaper(portrait, backdrop: try Self.backdrop(portrait))
        defer { try? FileManager.default.removeItem(at: pair.still.deletingLastPathComponent()) }

        XCTAssertNotNil(UUID(uuidString: pair.identifier))

        // The still: the identifier in the Apple maker note, under 17.
        let source = try XCTUnwrap(CGImageSourceCreateWithURL(pair.still as CFURL, nil))
        let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        let maker = try XCTUnwrap(properties[kCGImagePropertyMakerAppleDictionary] as? [String: Any])
        XCTAssertEqual(maker[LivePhotoPair.makerNoteKey] as? String, pair.identifier)

        // The movie: the same identifier at the top of the file.
        let asset = AVURLAsset(url: pair.movie)
        let items = try await asset.load(.metadata)
        let identifiers = items.filter {
            $0.identifier?.rawValue == "mdta/\(MovieWriter.contentIdentifierKey)"
        }
        XCTAssertEqual(identifiers.count, 1)
        let written = try await identifiers.first?.load(.stringValue)
        XCTAssertEqual(written, pair.identifier)

        // And the still-image-time, on the last frame, where the turn ends.
        let tracks = try await asset.loadTracks(withMediaType: .metadata)
        XCTAssertEqual(tracks.count, 1)
        let track = try XCTUnwrap(tracks.first)
        let descriptions = try await track.load(.formatDescriptions)
        let keys = descriptions.flatMap { (CMMetadataFormatDescriptionGetIdentifiers($0) as? [String]) ?? [] }
        XCTAssertTrue(keys.contains("mdta/\(MovieWriter.stillImageTimeKey)"), "\(keys)")

        // A sparse track: the writer fills the time before the item with an
        // empty group, so the group asked for is the one that carries it.
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
        let groups = AVAssetReaderOutputMetadataAdaptor(assetReaderTrackOutput: output)
        reader.add(output)
        XCTAssertTrue(reader.startReading())
        var stillAt: CMTime?
        while let group = groups.nextTimedMetadataGroup() {
            if group.items.contains(where: {
                $0.identifier?.rawValue == "mdta/\(MovieWriter.stillImageTimeKey)"
            }) {
                stillAt = group.timeRange.start
            }
        }
        let plan = TurnPlan.moving
        XCTAssertEqual(try XCTUnwrap(stillAt).seconds,
                       plan.time(ofFrame: plan.frameCount - 1).seconds, accuracy: 0.001)

        // The movie's last frame is the still.
        let frames = try await Self.frames(of: asset)
        XCTAssertEqual(frames.count, plan.frameCount)
        let still = try Pixels(try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil)))
        let last = try XCTUnwrap(frames.last)
        XCTAssertLessThan(still.difference(from: last, in: CGRect(x: 0, y: 0, width: 360, height: 780)), 2.5)
    }

    // MARK: The menu

    /// **Five things, the time-lapse among them** (Marcus, 14 October): the
    /// three that go to the share sheet, then the two that go to Photos, each
    /// with a mark of its own the system can draw.
    func testTheMenuHasFiveThingsWithTheTimeLapse() throws {
        XCTAssertEqual(PlantShareAction.allCases, [.picture, .turning, .timeLapse, .wallpaper, .movingWallpaper])
        XCTAssertFalse(PlantShareAction.timeLapse.savesToPhotos, "the time-lapse goes to the share sheet")
        XCTAssertEqual(Set(PlantShareAction.allCases.map(\.glyph)).count, PlantShareAction.allCases.count)
        for action in PlantShareAction.allCases {
            XCTAssertNotNil(UIImage(systemName: action.glyph), "\(action.glyph) is a system mark")
        }
        let title = Mirror(reflecting: PlantShareAction.timeLapse.title).children
            .first { $0.label == "key" }?.value as? String
        XCTAssertEqual(title, "Share time-lapse")
    }

    /// **The time-lapse film, as the menu makes it**: the plant's twelve
    /// seconds as an H.264 movie called *Peace Garden*, the ring told how far
    /// it has got, and nothing in the file but the picture — no seed, no
    /// name, no metadata. Small and at four frames a second, because the size
    /// is not what is being tested.
    func testTheTimeLapseFilmCarriesNothingButThePicture() async throws {
        let record = PlantRecord(seed: Self.genome.seed, lineage: .minted,
                                 birth: Date().addingTimeInterval(-40 * 86_400))
        var options = PlantShareFiles.timeLapseOptions()
        XCTAssertEqual(options.drift, .towardsNow, "the sky ends on the phone's hour")
        XCTAssertTrue(options.endsUnderTheHour, "under the shared picture's sky")
        XCTAssertFalse(options.opensOnThePlant, "the film starts on the sprout")
        options.size = CGSize(width: 120, height: 212)
        options.fps = 4
        var reported: [Double] = []
        let url = try await PlantShareFiles.timeLapse(record, now: Date(), options: options) { reported.append($0) }

        XCTAssertEqual(url.lastPathComponent, "\(PlantShareFiles.fileStem).mp4")
        let bytes = try Data(contentsOf: url)
        let name = record.genome.name
        for word in [record.seed.hex, record.seed.hex.uppercased(), name.full, name.genus, name.epithet] {
            XCTAssertNil(bytes.range(of: Data(word.utf8)), "the film carries \(word)")
        }
        let asset = AVURLAsset(url: url)
        let items = try await asset.load(.metadata)
        XCTAssertTrue(items.isEmpty, "the film carries no metadata: \(items)")
        let duration = try await asset.load(.duration).seconds
        XCTAssertEqual(duration, TimeLapse.duration, accuracy: 0.5)
        XCTAssertEqual(reported.last ?? 0, 1, accuracy: 0.001, "the ring fills")
        XCTAssertEqual(reported, reported.sorted(), "and only forwards")
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }

    /// **The shared film ends under the picture's sky** (21C). At dusk, at
    /// night and by day, the last frame of the film, away from the plant, is
    /// the ground a shared picture has at the same hour on the same clock;
    /// and before the plant comes to rest it is still the time-lapse's sky.
    func testTheSharedFilmEndsUnderThePicturesSky() async throws {
        let record = TimeLapseTests.plant("share-end", days: 60)
        var options = PlantShareFiles.timeLapseOptions()
        options.calendar = TimeLapseTests.utc
        options.size = CGSize(width: 180, height: 320)
        options.fps = 2
        options.turns = false
        let top = CGRect(x: 0, y: 0, width: 180, height: 26)
        for (hour, minute) in [(18, 20), (23, 0), (10, 0)] {
            let now = try XCTUnwrap(TimeLapseTests.utc.date(bySettingHour: hour, minute: minute, second: 0,
                                                            of: TimeLapseTests.now))
            var frames: [CGImage] = []
            try await TimeLapseFilm.render(record, now: now, options: options) { frames.append($0.image) }
            let lapse = TimeLapse(record: record, now: now, calendar: TimeLapseTests.utc)
            XCTAssertEqual(lapse.hourNow, Double(hour) + Double(minute) / 60, accuracy: 1e-9)
            let portrait = TimeLapseFilm.hourPortrait(genome: record.genome, growth: lapse.final,
                                                      hour: lapse.hourNow, size: options.size)
            let ground = try Pixels(try XCTUnwrap(ShareBackdrop.image(for: portrait)))
            let last = try Pixels(try XCTUnwrap(frames.last))
            let resting = try Pixels(frames[Int(TimeLapse.growthEnd * Double(options.fps)) - 1])
            XCTAssertLessThan(last.difference(from: ground, in: top), 1,
                              "\(hour):\(minute): the film ends on the picture's ground")
            XCTAssertGreaterThan(resting.difference(from: ground, in: top), 1,
                                 "\(hour):\(minute): and is the time-lapse's sky until then")
        }
    }

    // MARK: The sky of the phone's hour (Marcus, 14 October 2026)

    /// **21C: the time-lapse's sky at dusk and dawn** (Marcus, 14 October).
    /// The garden's day through the day, with no stars; from sunset to twenty
    /// to seven, and from twenty past five to six in the morning, the
    /// time-lapse's sky over the night and none of the day; the two thinning
    /// into each other after that; the garden's starry night alone by nine;
    /// and the night when there is no hour to be had.
    func testTheSkyIsChosenByTheHour() {
        XCTAssertEqual(ShareGround.recommended, .byTheHour)
        for hour in [7.0, 9, 12, 15, 17.5] {
            let sky = ShareSky.at(hour: hour)
            XCTAssertEqual(sky.day, 1, "\(hour): the garden's day")
            XCTAssertEqual(sky.stars, 0, "\(hour): no stars by day")
        }
        for hour in [18.0, 18 + 10.0 / 60, 18.5, 18 + 40.0 / 60, 5 + 20.0 / 60, 5.5, 6] {
            let sky = ShareSky.at(hour: hour)
            XCTAssertEqual(sky.day, 0, accuracy: 1e-9, "\(hour): none of the day")
            XCTAssertEqual(sky.twilight, 1, "\(hour): the time-lapse's sky, all of it")
        }
        XCTAssertEqual(ShareSky.at(hour: 18 + 10.0 / 60).stars, 0, "the stars not out yet at ten past six")
        let deepening = ShareSky.at(hour: 19.25)
        XCTAssertGreaterThan(deepening.twilight, 0, "the dusk thinning into the night")
        XCTAssertLessThan(deepening.twilight, 1)
        XCTAssertEqual(deepening.stars, 1, "and the stars out")
        for hour in [21.0, 23, 2] {
            let sky = ShareSky.at(hour: hour)
            XCTAssertEqual(sky.day, 0, "\(hour)")
            XCTAssertEqual(sky.twilight, 0, "\(hour): the garden's night alone")
            XCTAssertEqual(sky.stars, 1, "\(hour): every star")
            XCTAssertEqual(sky.pool, ShareSky.poolAtNight, "\(hour)")
        }
        let sunrise = ShareSky.at(hour: 6 + 10.0 / 60)
        XCTAssertGreaterThan(sunrise.day, 0, "the day comes in as the sun climbs")
        XCTAssertLessThan(sunrise.day, 1)
        XCTAssertEqual(ShareSky.at(hour: 33), ShareSky.at(hour: 9), "a day and nine hours is nine o'clock")
        XCTAssertEqual(ShareSky.at(hour: nil), .noHour)
        XCTAssertEqual(ShareSky.at(hour: .nan), .noHour)
    }

    /// The hour is the phone's own clock, in its own time zone.
    func testTheHourIsThePhonesOwnClock() throws {
        // 17:30 at Greenwich on 14 October 2026.
        let moment = Date(timeIntervalSince1970: 1_791_999_000)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Europe/London"))
        XCTAssertEqual(try XCTUnwrap(ShareSky.phoneHour(at: moment, calendar: calendar)), 18.5, accuracy: 0.001)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        XCTAssertEqual(try XCTUnwrap(ShareSky.phoneHour(at: moment, calendar: calendar)), 2.5, accuracy: 0.001)
    }

    /// **What is drawn is that sky.** The day is light and its sun on the side
    /// the hour puts it; dusk and dawn are the time-lapse's rose low down, not
    /// the night; and with no hour the ground is the night exactly as it stood
    /// before.
    func testTheGroundIsDrawnForTheHour() throws {
        func ground(_ hour: Double?, _ ground: ShareGround = .byTheHour) throws -> CGImage {
            var portrait = Self.small(ground)
            portrait.hour = hour
            return try XCTUnwrap(ShareBackdrop.image(for: portrait))
        }
        func light(_ image: CGImage, _ region: CGRect) throws -> Double {
            let box = CGRect(x: region.minX * CGFloat(image.width), y: region.minY * CGFloat(image.height),
                             width: region.width * CGFloat(image.width), height: region.height * CGFloat(image.height))
            return TimeLapseLuminance.mean(of: try XCTUnwrap(image.cropping(to: box.integral)))
        }
        let whole = CGRect(x: 0, y: 0, width: 1, height: 1)
        let left = CGRect(x: 0, y: 0.25, width: 0.3, height: 0.3)
        let right = CGRect(x: 0.7, y: 0.25, width: 0.3, height: 0.3)

        let morning = try ground(9), afternoon = try ground(15)
        let dusk = try ground(18 + 20.0 / 60), night = try ground(23), none = try ground(nil)
        XCTAssertGreaterThan(try light(morning, whole), 0.15, "the day is a day")
        XCTAssertLessThan(try light(night, whole), 0.05, "the night is a night")
        XCTAssertGreaterThan(try light(morning, left), try light(morning, right), "the morning sun is on the left")
        XCTAssertGreaterThan(try light(afternoon, right), try light(afternoon, left), "and the afternoon's on the right")

        // Low down, below the plant: rose and mauve at dusk and at dawn, where
        // the garden's own dusk was already the night's dark blue.
        let low = CGRect(x: 0, y: 0.9, width: 1, height: 0.1)
        for (name, image) in [("twenty past six", dusk), ("quarter to six in the morning", try ground(5.75)), ("ten past six", try ground(18 + 10.0 / 60))] {
            let colour = try Self.meanColour(image, in: low)
            XCTAssertGreaterThan(colour.red, colour.blue + 0.03, "\(name) is rose low down: \(colour)")
            XCTAssertGreaterThan(colour.red, colour.green + 0.03, "\(name) is rose low down: \(colour)")
        }
        let nightLow = try Self.meanColour(night, in: low)
        XCTAssertGreaterThan(nightLow.blue, nightLow.red, "the night is the garden's blue: \(nightLow)")

        let dark = try Pixels(none)
        let size = CGSize(width: dark.width, height: dark.height)
        let before = try Pixels(try ground(nil, .nightSky))
        XCTAssertEqual(dark.difference(from: before, in: CGRect(origin: .zero, size: size)), 0,
                       "with no hour, the night it always was")
    }

    /// **No jump from day to dusk to night** (Marcus, 14 October 2026: 21C).
    /// The ground drawn every five minutes from half past five to nine in the
    /// evening, and from three to half past six in the morning: no step in its
    /// mean luminance is more than `largestStep` of the full range, at sunset,
    /// as the stars come out, or where the dusk hands over to the night.
    ///
    /// The garden's own day dims by up to 1.7% of the range in five minutes
    /// in the late afternoon, which is the sun going down and no jump; the
    /// first build's switch from day to dusk at six was 5.9% in one step.
    func testTheSkyByTheHourHasNoJump() throws {
        let largestStep = 0.025
        func sweep(from start: Int, to end: Int) throws -> [(minute: Int, light: Double)] {
            try stride(from: start, through: end, by: 5).map { minute in
                var portrait = Self.small(.byTheHour)
                portrait.hour = Double(minute) / 60
                let ground = try XCTUnwrap(ShareBackdrop.image(for: portrait))
                return (minute, TimeLapseLuminance.mean(of: ground, side: 64))
            }
        }
        for (name, run) in [("dusk", try sweep(from: 17 * 60 + 30, to: 21 * 60)),
                            ("dawn", try sweep(from: 3 * 60, to: 6 * 60 + 30))] {
            var worst = (step: 0.0, at: 0)
            for (a, b) in zip(run, run.dropFirst()) where abs(b.light - a.light) > worst.step {
                worst = (abs(b.light - a.light), b.minute)
            }
            print(String(format: "SHARE SKY %@: worst step %.4f at %02d:%02d\n", name, worst.step,
                         worst.at / 60, worst.at % 60)
                  + run.map { String(format: "%02d:%02d %.4f", $0.minute / 60, $0.minute % 60, $0.light) }
                .joined(separator: "\n"))
            XCTAssertLessThan(worst.step, largestStep,
                              String(format: "%@: a step of %.4f at %02d:%02d", name, worst.step,
                                     worst.at / 60, worst.at % 60))
        }
    }

    // MARK: Nothing but the picture

    /// No seed, no name, no meeting in any of the four files: not as text in
    /// the bytes, and no location or date in the image properties.
    func testNoSeedOrNameIsWritten() async throws {
        let portrait = Self.small()
        let ground = try Self.backdrop(portrait)
        let name = Self.genome.name
        let words = [Self.genome.seed.hex, Self.genome.seed.hex.uppercased(),
                     name.full, name.genus, name.epithet]

        func check(_ url: URL, file: StaticString = #filePath, line: UInt = #line) throws {
            let bytes = try Data(contentsOf: url)
            for word in words {
                XCTAssertNil(bytes.range(of: Data(word.utf8)), "\(url.lastPathComponent) carries \(word)",
                             file: file, line: line)
            }
            XCTAssertTrue(url.lastPathComponent.hasPrefix(PlantShareFiles.fileStem), file: file, line: line)
        }

        func checkImage(_ url: URL, file: StaticString = #filePath, line: UInt = #line) throws {
            let source = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil))
            let properties = (CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]) ?? [:]
            XCTAssertNil(properties[kCGImagePropertyGPSDictionary], "location", file: file, line: line)
            let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any] ?? [:]
            XCTAssertNil(exif[kCGImagePropertyExifDateTimeOriginal], "date", file: file, line: line)
            XCTAssertNil(exif[kCGImagePropertyExifUserComment], file: file, line: line)
            let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any] ?? [:]
            XCTAssertNil(tiff[kCGImagePropertyTIFFDateTime], "date", file: file, line: line)
            XCTAssertNil(tiff[kCGImagePropertyTIFFImageDescription], file: file, line: line)
            XCTAssertNil(tiff[kCGImagePropertyTIFFArtist], file: file, line: line)
        }

        let picture = try PlantShareFiles.picture(portrait, backdrop: ground)
        try check(picture)
        try checkImage(picture)

        let video = try await PlantShareFiles.turning(portrait, backdrop: ground,
                                                       plan: TurnPlan(seconds: 1, framesPerSecond: 30, turns: 1))
        try check(video)
        let videoItems = try await AVURLAsset(url: video).load(.metadata)
        XCTAssertTrue(videoItems.isEmpty, "the shared video carries no metadata: \(videoItems)")

        let pair = try await PlantShareFiles.movingWallpaper(portrait, backdrop: ground)
        try check(pair.still)
        try checkImage(pair.still)
        try check(pair.movie)
        let movieItems = try await AVURLAsset(url: pair.movie).load(.metadata)
        XCTAssertEqual(movieItems.count, 1, "only the pairing identifier: \(movieItems)")
        try? FileManager.default.removeItem(at: pair.still.deletingLastPathComponent())
    }

    // Whether a saved moving wallpaper comes out of Photos as a Live Photo
    // cannot be asked from here: the tests run inside the app, and the app has
    // add-only access and no reason to read the library. It was checked on a
    // scratch simulator from a test runner with read access of its own
    // (`design/share-plant-2026-10-13/README.md`).

    // MARK: Helpers

    /// The mean sRGB colour, `0...1` a channel, over a region given as
    /// fractions of the picture, top-left origin.
    static func meanColour(_ image: CGImage, in region: CGRect) throws -> (red: Double, green: Double, blue: Double) {
        let box = CGRect(x: region.minX * CGFloat(image.width), y: region.minY * CGFloat(image.height),
                         width: region.width * CGFloat(image.width), height: region.height * CGFloat(image.height)).integral
        let crop = try XCTUnwrap(image.cropping(to: box))
        let width = crop.width, height = crop.height
        var data = [UInt8](repeating: 0, count: width * height * 4)
        let drew: Bool = data.withUnsafeMutableBytes { raw in
            guard let context = CGContext(data: raw.baseAddress, width: width, height: height, bitsPerComponent: 8,
                                          bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                          bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
            else { return false }
            context.draw(crop, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drew else { throw CocoaError(.coderInvalidValue) }
        var sums = (0.0, 0.0, 0.0)
        for index in stride(from: 0, to: data.count, by: 4) {
            sums.0 += Double(data[index]); sums.1 += Double(data[index + 1]); sums.2 += Double(data[index + 2])
        }
        let count = Double(width * height) * 255
        return (sums.0 / count, sums.1 / count, sums.2 / count)
    }

    /// Every frame of a movie, decoded.
    static func frames(of asset: AVAsset) async throws -> [Pixels] {
        let tracks = try await asset.loadTracks(withMediaType: .video)
        let track = try XCTUnwrap(tracks.first)
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ])
        reader.add(output)
        guard reader.startReading() else { throw reader.error ?? CocoaError(.fileReadUnknown) }
        var frames: [Pixels] = []
        while let sample = output.copyNextSampleBuffer() {
            guard let buffer = CMSampleBufferGetImageBuffer(sample) else { continue }
            frames.append(Pixels(buffer))
        }
        return frames
    }
}

/// A picture's pixels as bytes, BGRA or RGBA alike: the comparison is of the
/// three colour channels taken together.
struct Pixels {
    let width: Int
    let height: Int
    private let bytes: [UInt8]
    private let rowBytes: Int
    /// Where red is in each pixel: 0 for RGBA, 2 for BGRA.
    private let red: Int

    init(_ image: CGImage) throws {
        let wide = image.width, tall = image.height
        width = wide
        height = tall
        rowBytes = wide * 4
        red = 0
        var data = [UInt8](repeating: 0, count: wide * tall * 4)
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        let drew: Bool = data.withUnsafeMutableBytes { raw in
            guard let context = CGContext(data: raw.baseAddress, width: wide, height: tall,
                                          bitsPerComponent: 8, bytesPerRow: wide * 4, space: space,
                                          bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
            else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: wide, height: tall))
            return true
        }
        guard drew else { throw CocoaError(.coderInvalidValue) }
        bytes = data
    }

    init(_ buffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        width = CVPixelBufferGetWidth(buffer)
        height = CVPixelBufferGetHeight(buffer)
        rowBytes = CVPixelBufferGetBytesPerRow(buffer)
        red = 2
        let base = CVPixelBufferGetBaseAddress(buffer)!.assumingMemoryBound(to: UInt8.self)
        bytes = Array(UnsafeBufferPointer(start: base, count: rowBytes * height))
    }

    private func rgb(_ x: Int, _ y: Int) -> (Int, Int, Int) {
        let at = y * rowBytes + x * 4
        return (Int(bytes[at + red]), Int(bytes[at + 1]), Int(bytes[at + 2 - red]))
    }

    /// The mean difference per channel, `0...255`, over a region in this
    /// picture's pixels, top-left origin.
    func difference(from other: Pixels, in region: CGRect) -> Double {
        let box = region.intersection(CGRect(x: 0, y: 0, width: min(width, other.width),
                                             height: min(height, other.height)))
        guard !box.isEmpty else { return .infinity }
        var total = 0, count = 0
        for y in Int(box.minY)..<Int(box.maxY) {
            for x in Int(box.minX)..<Int(box.maxX) {
                let a = rgb(x, y), b = other.rgb(x, y)
                total += abs(a.0 - b.0) + abs(a.1 - b.1) + abs(a.2 - b.2)
                count += 3
            }
        }
        return Double(total) / Double(count)
    }
}
