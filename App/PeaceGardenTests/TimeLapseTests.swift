import SeedCore
import XCTest
@testable import PeaceGarden

/// The time-lapse's score: twelve seconds for every plant, and a plant that
/// grows from the sprout to now and never back.
final class TimeLapseTests: XCTestCase {
    static let now = Date(timeIntervalSince1970: 1_791_900_000)

    /// A plant `days` old at `now`.
    static func plant(_ name: String, days: Double, now: Date = now) -> PlantRecord {
        let seed = SeedID(bytes: seedDigest(SeedDomain.seed, Data("time-lapse-\(name)".utf8)))!
        return PlantRecord(seed: seed, lineage: .minted, birth: now.addingTimeInterval(-days * 86_400))
    }

    static var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    static let ages: [Double] = [0.01, 0.2, 2, 9, 30, 150, 400]

    // MARK: Twelve seconds, whatever the age (2A)

    func testTheRunIsTwelveSecondsWhateverTheAge() {
        XCTAssertEqual(TimeLapse.duration, 12, accuracy: 1e-9)
        for (index, days) in Self.ages.enumerated() {
            let record = Self.plant("age-\(index)", days: days)
            let lapse = TimeLapse(record: record, now: Self.now, calendar: Self.utc)
            let frames = lapse.frames(fps: 60)
            XCTAssertEqual(frames.count, 721, "\(days) days")
            XCTAssertEqual(frames.last!.time, 12, accuracy: 1e-9, "\(days) days")
            // Growing is over at the same moment for every plant, and the rest
            // of the run is the plant as it is now.
            let grown = lapse.frame(at: TimeLapse.growthEnd)
            XCTAssertEqual(grown.progress, 1, accuracy: 1e-9, "\(days) days")
            XCTAssertEqual(grown.growth, lapse.final, "\(days) days")
            XCTAssertEqual(frames.last!.growth, lapse.final, "\(days) days")
        }
    }

    // MARK: From the sprout to now, and never back

    func testGrowthRunsFromTheSproutToNowAndNeverBack() {
        for (index, days) in Self.ages.enumerated() {
            let record = Self.plant("age-\(index)", days: days)
            let lapse = TimeLapse(record: record, now: Self.now, calendar: Self.utc)
            let live = GrowthModel(genome: record.genome).state(birth: record.birth, now: Self.now,
                                                                calendar: Self.utc)
            let frames = lapse.frames(fps: 60)

            // The first sprouting: the height's floor, no leaves, no bud.
            let first = frames[0].growth
            XCTAssertEqual(first.heightScale, 0.055, accuracy: 0.002, "\(days) days")
            XCTAssertEqual(first.leafUnfurl, 0, accuracy: 1e-9, "\(days) days")
            XCTAssertEqual(first.budSwell, 0, accuracy: 1e-9, "\(days) days")
            XCTAssertEqual(first.flushDepth, 0, accuracy: 1e-9, "\(days) days")

            // The last: the plant on the screen, field for field.
            let last = frames[frames.count - 1].growth
            XCTAssertEqual(last.heightScale, live.heightScale, accuracy: 1e-12)
            XCTAssertEqual(last.leafUnfurl, live.leafUnfurl, accuracy: 1e-12)
            XCTAssertEqual(last.budSwell, live.budSwell, accuracy: 1e-12)
            XCTAssertEqual(last.bloomOpen, live.bloomOpen, accuracy: 1e-12)
            XCTAssertEqual(last.flush, live.flush, accuracy: 1e-12)
            XCTAssertEqual(last.flushDepth, live.flushDepth, accuracy: 1e-12)

            // Monotone, every field the mesh is drawn from, every frame. The
            // flowers included: they open once rather than with every
            // simulated day.
            for (a, b) in zip(frames, frames.dropFirst()) {
                let x = a.growth, y = b.growth
                XCTAssertGreaterThanOrEqual(y.heightScale, x.heightScale - 1e-12, "\(days) days at \(b.time)")
                XCTAssertGreaterThanOrEqual(y.leafUnfurl, x.leafUnfurl - 1e-12, "\(days) days at \(b.time)")
                XCTAssertGreaterThanOrEqual(y.budSwell, x.budSwell - 1e-12, "\(days) days at \(b.time)")
                XCTAssertGreaterThanOrEqual(y.bloomOpen, x.bloomOpen - 1e-9, "\(days) days at \(b.time)")
                XCTAssertGreaterThanOrEqual(y.flushDepth, x.flushDepth - 1e-12, "\(days) days at \(b.time)")
                XCTAssertGreaterThanOrEqual(b.progress, a.progress - 1e-12, "\(days) days at \(b.time)")
            }
        }
    }

    /// **Steady growing.** Spaced by the calendar, a plant some months old
    /// does nearly all its visible growing in the first second of the run.
    /// Spaced by how much it changes, no second of the growing holds more than
    /// a fifth of it — even would be a little under a ninth, and the ease in
    /// and out puts a little more in the middle.
    func testNoSecondOfTheGrowingHoldsMostOfIt() {
        for (index, days) in [9.0, 30, 150].enumerated() {
            let record = Self.plant("steady-\(index)", days: days)
            let lapse = TimeLapse(record: record, now: Self.now, calendar: Self.utc)
            let frames = lapse.frames(fps: 60)
            var change: [Double] = []
            for (a, b) in zip(frames, frames.dropFirst()) {
                change.append(TimeLapse.visibleChange(from: a.growth, to: b.growth))
            }
            let total = change.reduce(0, +)
            XCTAssertGreaterThan(total, 0, "\(days) days")
            var worst = 0.0
            for start in 0..<(change.count - 60) {
                worst = max(worst, change[start..<(start + 60)].reduce(0, +) / total)
            }
            XCTAssertLessThan(worst, 0.2, "\(days) days: \(Int(worst * 100))% in one second")
        }
    }

    /// The calendar handed to the growth model reads the hour it is now at
    /// any moment of the plant's life, so the petals hold their opening.
    func testEveryMomentIsReadAtTheHourItIsNow() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Copenhagen")!
        let now = Self.now
        let wanted = calendar.dateComponents([.hour, .minute], from: now)
        for days in stride(from: 0.0, through: 200, by: 3.7) {
            let moment = now.addingTimeInterval(-days * 86_400 + 1234.5)
            let held = TimeLapse.calendar(readingTheHourOf: now, at: moment, from: calendar)
            let read = held.dateComponents([.hour, .minute], from: moment)
            XCTAssertEqual(read.hour, wanted.hour, "\(days) days back")
            XCTAssertEqual(read.minute, wanted.minute, "\(days) days back")
        }
    }

    // MARK: Reduce Motion

    func testReduceMotionHoldsTheSkyAndPlaysStills() {
        let record = Self.plant("still", days: 60)
        let lapse = TimeLapse(record: record, now: Self.now, calendar: Self.utc)
        let frames = lapse.frames(fps: 60, reduceMotion: true)
        let elevations = Set(frames.map { ($0.sky.elevation * 1e6).rounded() })
        XCTAssertEqual(elevations.count, 1, "the sky moves under Reduce Motion")
        let held = Set(frames.map { ($0.growth.heightScale * 1e9).rounded() })
        XCTAssertLessThanOrEqual(held.count, TimeLapse.stillCount)
        XCTAssertEqual(frames.last!.growth, lapse.final)
    }
}
