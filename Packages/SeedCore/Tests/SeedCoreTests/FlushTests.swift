import XCTest
import Foundation
@testable import SeedCore

/// The flowering cycle a plant runs once it has finished growing.
///
/// Everything else about a mature plant reaches 1 and stays there, so before
/// this a plant was fixed but for `diurnalFactor` opening and closing it each
/// day. The flush is the longer rhythm — a wave of open flowers travelling up
/// the stem over one to four weeks.
///
/// **The promise that matters most here is the one botany would not make.** A
/// real spike goes over and stands bare between flushes. A plant in this app
/// stands for a meeting between two people, and one found bare would read as
/// that meeting having faded, so the trough is a bud rather than nothing. That
/// is a decision about what the app means, it is invisible in any single
/// screenshot, and it is the thing most likely to be undone by accident later.
final class FlushTests: XCTestCase {

    private func genome(_ label: String) -> Genome {
        Genome(seed: SeedMint.mint(fromEntropy: Data(label.utf8)))
    }

    private func state(_ genome: Genome, days: Double) -> GrowthModel.State {
        let birth = Date(timeIntervalSince1970: 1_700_000_000)
        return GrowthModel(genome: genome)
            .state(birth: birth, now: birth.addingTimeInterval(days * 86_400))
    }

    // MARK: - Never bare

    /// **No mature plant is ever found without flowers.** The promise above.
    ///
    /// Walked day by day across forty days, over plants of every family, so a
    /// trough that only happens at one phase of one genome's cycle cannot hide.
    func testAMaturePlantIsNeverFoundWithoutFlowers() {
        // Sampled rather than exhaustive, and the numbers are chosen against
        // the cycle rather than picked round: the shortest cycle is about a
        // week, so a day's step cannot step over a trough, and forty days
        // covers the longest cycle nearly twice.
        var checked = 0
        for index in 0..<30 {
            let plant = genome("flush-\(index)")
            guard plant.bloom.present else { continue }
            checked += 1
            for day in stride(from: 40.0, through: 80.0, by: 1.0) {
                let growth = state(plant, days: day)
                guard growth.stage == .mature else { continue }
                let mesh = PlantBuilder(genome: plant).mesh(growth: growth)
                let vertices = mesh.parts.reduce(0) { $0 + $1.positions.count }
                XCTAssertGreaterThan(
                    vertices, 0,
                    "\(plant.name.full) drew nothing at day \(day)"
                )
            }
        }
        XCTAssertGreaterThan(checked, 15, "too few flowering plants to have tested anything")
    }

    /// The trough keeps a flower at about 45% rather than closing it.
    ///
    /// Asserted on the factor itself, because the mesh cannot tell the
    /// difference between a bud and a small flower and this is precisely the
    /// distinction the design turns on.
    func testTheTroughIsABudRatherThanNothing() {
        let plant = genome("flush-trough")
        let deep = GrowthModel.State(
            stage: .mature, stageProgress: 1, overall: 1, heightScale: 1,
            leafUnfurl: 1, budSwell: 1, bloomOpen: 1, age: 0,
            timeToNextStage: nil, flush: 0.5, flushDepth: 1
        )
        // A flower at the very bottom of the wave, half a cycle out of phase.
        let factor = PlantBuilder(genome: plant).flushFactorForTesting(position: 0, growth: deep)
        XCTAssertEqual(factor, 0.45, accuracy: 0.01)
        XCTAssertGreaterThan(factor, 0.2, "a flower out of phase has all but vanished")
    }

    // MARK: - It is a wave, not a pulse

    /// Flowers at different heights are at different points in the cycle.
    ///
    /// Without this the whole plant would open and close in unison, which is
    /// the flat-faced look the per-node `lag` was written to remove from spikes
    /// in the first place — reintroduced on a longer timescale.
    func testTheWaveTravelsRatherThanThePlantBreathing() {
        let growth = GrowthModel.State(
            stage: .mature, stageProgress: 1, overall: 1, heightScale: 1,
            leafUnfurl: 1, budSwell: 1, bloomOpen: 1, age: 0,
            timeToNextStage: nil, flush: 0.25, flushDepth: 1
        )
        let builder = PlantBuilder(genome: genome("flush-wave"))
        let low = builder.flushFactorForTesting(position: 0.4, growth: growth)
        let high = builder.flushFactorForTesting(position: 0.95, growth: growth)
        XCTAssertNotEqual(low, high, accuracy: 0.0001,
                          "every flower is at the same point in the cycle")
    }

    // MARK: - It cannot lurch

    /// A plant does not jump the moment it matures.
    ///
    /// `flushDepth` eases from zero across the first cycle, so the flowers the
    /// plant has spent its whole timeline opening are not snatched away the
    /// instant it arrives. Checked as a bound on how much the mesh may change
    /// between consecutive samples around the boundary.
    func testNothingLurchesWhenThePlantMatures() {
        for index in 0..<12 {
            let plant = genome("lurch-\(index)")
            guard plant.bloom.present else { continue }
            var previous: Int?
            for hour in stride(from: 0.0, through: 72.0, by: 2.0) {
                let growth = state(plant, days: 14 + hour / 24)
                let mesh = PlantBuilder(genome: plant).mesh(growth: growth)
                let vertices = mesh.parts.reduce(0) { $0 + $1.positions.count }
                if let previous, previous > 400 {
                    let jump = abs(vertices - previous)
                    XCTAssertLessThan(
                        Double(jump) / Double(previous), 0.45,
                        "\(plant.name.full) jumped \(previous) to \(vertices) in two hours"
                    )
                }
                previous = vertices
            }
        }
    }

    // MARK: - Two phones still agree

    /// The cycle is a function of the seed and the clock and nothing else.
    ///
    /// This is the property the whole app rests on — a plant is a seed plus a
    /// birthday, and everything else is derived — so a rhythm that remembered
    /// anything would break it. Nothing here is stored; this is the test that
    /// says so.
    func testTheCycleIsDerivedRatherThanRemembered() {
        let plant = genome("flush-agree")
        for day in stride(from: 30.0, through: 90.0, by: 3.0) {
            let first = state(plant, days: day)
            let second = state(Genome(seed: plant.seed), days: day)
            XCTAssertEqual(first.flush, second.flush)
            XCTAssertEqual(first.flushDepth, second.flushDepth)
        }
    }

    /// A plant that carries no flowers has no cycle to run.
    func testAPlantWithNoBloomHasNoFlush() {
        for index in 0..<400 {
            let plant = genome("noflower-\(index)")
            guard !plant.bloom.present else { continue }
            XCTAssertEqual(state(plant, days: 60).flushDepth, 0, "\(plant.name.full)")
            return
        }
    }

    /// The cycle's length is the plant's own, so two plants side by side are
    /// rarely in step — most of what stops a garden looking like one plant
    /// repeated.
    func testCycleLengthsDiffer() {
        var depths: Set<String> = []
        for index in 0..<80 {
            let plant = genome("period-\(index)")
            guard plant.bloom.present else { continue }
            depths.insert(String(format: "%.3f", state(plant, days: 45).flush))
        }
        XCTAssertGreaterThan(depths.count, 20, "every plant is in the same phase on the same day")
    }
}
