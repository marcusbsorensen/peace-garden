import XCTest
@testable import SeedCore

final class GrowthTests: XCTestCase {
    private func genome(_ index: Int) -> Genome {
        Genome(seed: SeedMint.mint(fromEntropy: Data("growth-\(index)".utf8)))
    }

    /// Fixed noon so the day/night rhythm does not make the assertions flaky.
    private func noon(daysAfter birth: Date, _ days: Double) -> Date {
        birth.addingTimeInterval(days * 86_400)
    }

    func testAPlantStartsAsASeed() {
        let genome = genome(1)
        let birth = Date()
        let state = GrowthModel(genome: genome).state(birth: birth, now: birth)
        XCTAssertEqual(state.stage, .germinating)
        XCTAssertLessThan(state.heightScale, 0.1)
        XCTAssertEqual(state.leafUnfurl, 0, accuracy: 1e-9)
        XCTAssertEqual(state.bloomOpen, 0, accuracy: 1e-9)
    }

    func testHeightNeverGoesBackwards() {
        for index in 0..<40 {
            let model = GrowthModel(genome: genome(index))
            let birth = Date(timeIntervalSince1970: 1_700_000_000)
            var previous = -1.0
            for step in stride(from: 0.0, through: 30.0, by: 0.25) {
                let state = model.state(birth: birth, now: noon(daysAfter: birth, step))
                XCTAssertGreaterThanOrEqual(state.heightScale, previous - 1e-9)
                previous = state.heightScale
            }
        }
    }

    func testStagesArriveInOrderAndSettleAtMature() {
        let genome = genome(2)
        let model = GrowthModel(genome: genome)
        let birth = Date(timeIntervalSince1970: 1_700_000_000)
        let expected: [GrowthModel.Stage] = [.germinating, .seedling, .growing, .budding, .blooming, .mature]

        var seen: [GrowthModel.Stage] = []
        for step in stride(from: 0.0, through: 60.0, by: 0.05) {
            let stage = model.state(birth: birth, now: noon(daysAfter: birth, step)).stage
            if seen.last != stage { seen.append(stage) }
        }

        XCTAssertEqual(seen, expected)
        let farFuture = model.state(birth: birth, now: noon(daysAfter: birth, 3650))
        XCTAssertEqual(farFuture.stage, .mature)
        XCTAssertNil(farFuture.timeToNextStage)
    }

    func testBloomOpensAfterTheBudSwells() {
        let genome = genome(5)
        let model = GrowthModel(genome: genome)
        let birth = Date(timeIntervalSince1970: 1_700_000_000)
        // Halfway through the budding window, whatever this genome's tempo is.
        let budStart = genome.tempo.germinationHours / 24 + genome.tempo.seedlingDays + genome.tempo.vegetativeDays
        let midBudding = birth.addingTimeInterval((budStart + genome.tempo.buddingDays * 0.5) * 86_400)
        let budding = model.state(birth: birth, now: midBudding)
        XCTAssertGreaterThan(budding.budSwell, 0)
        XCTAssertEqual(budding.bloomOpen, 0, accuracy: 1e-9)
    }

    func testDayFlowersCloseAtNight() {
        // Find a genome that opens by day, then compare noon against midnight.
        guard let genome = (0..<50).lazy.map(genome).first(where: { $0.tempo.opensByDay && $0.bloom.present }) else {
            return XCTFail("no day-blooming genome in the sample")
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!

        let birth = Date(timeIntervalSince1970: 1_700_000_000)
        let bloomTime = birth.addingTimeInterval(genome.tempo.daysToBloom * 86_400 + 86_400 * 2)
        let dayStart = calendar.startOfDay(for: bloomTime)
        let model = GrowthModel(genome: genome)

        let atNoon = model.state(birth: birth, now: dayStart.addingTimeInterval(13 * 3600), calendar: calendar)
        let atMidnight = model.state(birth: birth, now: dayStart.addingTimeInterval(1 * 3600), calendar: calendar)
        XCTAssertGreaterThan(atNoon.bloomOpen, atMidnight.bloomOpen)
    }

    func testPlantsWithoutFlowersNeverBloom() {
        guard let genome = (0..<400).lazy.map(genome).first(where: { !$0.bloom.present }) else {
            return XCTFail("no flowerless genome in the sample")
        }
        let birth = Date(timeIntervalSince1970: 1_700_000_000)
        let state = GrowthModel(genome: genome).state(birth: birth, now: birth.addingTimeInterval(86_400 * 400))
        XCTAssertEqual(state.bloomOpen, 0, accuracy: 1e-9)
    }
}
