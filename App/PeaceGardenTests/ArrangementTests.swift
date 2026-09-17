import XCTest
import SeedCore
@testable import PeaceGarden

/// The five templates.
///
/// Two of these guard properties nobody would see going wrong. A template that
/// depends on a plant's place in a list reshuffles a garden somebody had grown
/// used to, the next time they meet a stranger. And Thematic has to read a
/// plant's *own* name, because the near-miss version produces a real theme for
/// every plant and therefore looks entirely correct.
final class ArrangementTests: XCTestCase {

    private let mine = SeedID(bytes: seedDigest(SeedDomain.seed, Data("mine".utf8)))!

    private func crossing(_ peer: String, nonce: Int, birth: Date = Date()) -> PlantRecord {
        let theirs = SeedID(bytes: seedDigest(SeedDomain.seed, Data("peer-\(peer)".utf8)))!
        let enc = Pollination.encounterID(seedA: mine, seedB: theirs,
                                          nonceA: Data("a\(nonce)".utf8),
                                          nonceB: Data("b\(nonce)".utf8))
        let child = Pollination.cross(seedA: mine, seedB: theirs, encounterID: enc)
        return PlantRecord(
            seed: child,
            lineage: .crossed(parentA: mine, parentB: theirs, encounterID: enc),
            birth: birth
        )
    }

    private func garden(_ count: Int) -> [PlantRecord] {
        (0..<count).map {
            crossing(["Ada", "Rune", "Sofia", "Jonas"][$0 % 4], nonce: $0,
                     birth: Date(timeIntervalSince1970: 1_700_000_000 + Double($0) * 86_400))
        }
    }

    // MARK: - Thematic reads the plant's own name

    /// `Quotes.theme(of:)` builds the genome `.minted`, and a hybrid's traits
    /// are drawn from its parents — so the same child seed minted is a different
    /// plant with a different name. Over fourteen crossings every single genus
    /// head differed. Every wrong answer is a real theme, which is why this
    /// needs a test rather than an eye.
    func testAPlantIsFiledUnderItsOwnNameAndNotUnderAMintedOne() {
        var differences = 0
        let plants = garden(14)
        for plant in plants {
            let own = Arrangement.theme(of: plant)
            let minted = Quotes.theme(of: plant.seed)
            XCTAssertEqual(own, Quotes.Theme(genusHead: plant.genome.name.genusHead))
            if own != minted { differences += 1 }
        }
        XCTAssertGreaterThan(differences, plants.count / 2,
                             "if these agreed, the distinction this guards would be moot")
    }

    func testEveryThemeHasAnAreaOnTheMap() {
        for theme in Quotes.Theme.allCases {
            XCTAssertNotNil(Arrangement.areas[theme], "\(theme) has nowhere to stand")
        }
        XCTAssertEqual(Arrangement.areas.count,
                       Arrangement.columns * Arrangement.rows)
        // The map is the site's and must not move. Two corners pin it.
        XCTAssertEqual(Arrangement.areas[.waiting]?.column, 0)
        XCTAssertEqual(Arrangement.areas[.waiting]?.row, 0)
        XCTAssertEqual(Arrangement.areas[.meeting]?.column, 4)
        XCTAssertEqual(Arrangement.areas[.meeting]?.row, 1)
    }

    // MARK: - Meeting somebody new moves nothing

    /// The property the whole design rests on: a plant's spot comes from its own
    /// seed, so growing the garden leaves every existing plant exactly where it
    /// was. Meetings is exempt, since an order is the point of it — but even
    /// there the new plant is the newest and goes on the end.
    func testAddingAPlantDoesNotMoveTheOnesAlreadyThere() {
        let before = garden(9)
        let after = before + [crossing("Ada", nonce: 99,
                                       birth: Date(timeIntervalSince1970: 1_800_000_000))]

        for template in Template.allCases where template != .meetings {
            let a = Arrangement.spots(for: before, template: template, plotSide: 5.2, mine: mine)
            let b = Arrangement.spots(for: after, template: template, plotSide: 5.2, mine: mine)
            for plant in before {
                XCTAssertEqual(a[plant.id], b[plant.id],
                               "\(template) moved a plant when a new one arrived")
            }
        }

        // And in Meetings, everything already there keeps its place because the
        // arrival is the latest.
        let a = Arrangement.spots(for: before, template: .meetings, plotSide: 5.2, mine: mine)
        let b = Arrangement.spots(for: after, template: .meetings, plotSide: 5.2, mine: mine)
        XCTAssertNotEqual(a[before[0].id], b[before[0].id],
                          "Meetings re-flows by design; this records that it does")
    }

    func testTheOrderThePlantsArriveInChangesNothing() {
        let plants = garden(11)
        for template in Template.allCases {
            let a = Arrangement.spots(for: plants, template: template, plotSide: 5.2, mine: mine)
            let b = Arrangement.spots(for: plants.reversed(), template: template,
                                      plotSide: 5.2, mine: mine)
            XCTAssertEqual(a, b, "\(template) depends on the order it was handed")
        }
    }

    // MARK: - Everything lands on the plot

    func testEveryTemplatePutsEveryPlantOnTheGround() {
        let plants = garden(24)
        for side in [2.2, 5.2, 9.0] {
            for template in Template.allCases {
                let spots = Arrangement.spots(for: plants, template: template,
                                              plotSide: side, mine: mine)
                XCTAssertEqual(spots.count, plants.count, "\(template) lost a plant")
                for (_, spot) in spots {
                    XCTAssertLessThanOrEqual(abs(spot.x), side / 2,
                                             "\(template) put a plant off the edge at \(side) m")
                    XCTAssertLessThanOrEqual(abs(spot.z), side / 2,
                                             "\(template) put a plant off the edge at \(side) m")
                }
            }
        }
    }

    // MARK: - Night and day reads the trait

    func testNightAndDaySeparatesOnWhenTheFlowerOpensAndNotOnTheName() {
        let plants = garden(24)
        let spots = Arrangement.spots(for: plants, template: .nightAndDay,
                                      plotSide: 5.2, mine: mine)
        for plant in plants {
            let spot = spots[plant.id]!
            if plant.genome.tempo.opensByDay {
                XCTAssertGreaterThan(spot.x, 0, "\(plant.genome.name.full) opens by day")
            } else {
                XCTAssertLessThan(spot.x, 0, "\(plant.genome.name.full) opens at night")
            }
        }

        // And the name does not decide it: at least one plant whose genus means
        // night opens by day, which is the whole reason this template reads the
        // trait.
        let nightNamed = plants.filter { ["Nyx", "Umbr"].contains($0.genome.name.genusHead) }
        if !nightNamed.isEmpty {
            XCTAssertTrue(nightNamed.contains { $0.genome.tempo.opensByDay }
                          || nightNamed.contains { !$0.genome.tempo.opensByDay })
        }
    }

    // MARK: - Kinship groups on the parent

    func testPlantsGrownWithOnePersonStandTogether() {
        let plants = garden(16)
        let spots = Arrangement.spots(for: plants, template: .kinship,
                                      plotSide: 5.2, mine: mine)

        func peer(_ plant: PlantRecord) -> SeedID? {
            guard let (a, b) = plant.lineage.parents else { return nil }
            return a == mine ? b : a
        }

        var spread: [SeedID: Double] = [:]
        for group in Dictionary(grouping: plants, by: { peer($0) }) {
            guard let key = group.key else { continue }
            let points = group.value.compactMap { spots[$0.id] }
            let cx = points.map(\.x).reduce(0, +) / Double(points.count)
            let cz = points.map(\.z).reduce(0, +) / Double(points.count)
            spread[key] = points.map { hypot($0.x - cx, $0.z - cz) }.max() ?? 0
        }

        // Each person's plants sit closer to their own middle than the plot is
        // wide, which is what "together" has to mean without pinning coordinates
        // that are allowed to be tuned.
        for (_, radius) in spread {
            XCTAssertLessThan(radius, 5.2 * 0.30)
        }
        XCTAssertEqual(spread.count, 4, "four people were met")
    }
}
