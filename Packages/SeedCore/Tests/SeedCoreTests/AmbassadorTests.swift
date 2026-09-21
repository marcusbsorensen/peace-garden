import XCTest
@testable import SeedCore

/// The ten plants that stand for the ten areas.
///
/// Three things can go wrong here and none of them would show up as a crash. A
/// pinned seed could stop landing in the area it is pinned to, and the Long
/// Walk's ambassador would quietly be a Knot Garden plant. The hexes could
/// drift from the search that found them, and become ten plants somebody chose.
/// And a seed sown too late would have the garden opening onto seedlings.
final class AmbassadorTests: XCTestCase {

    // MARK: Each one belongs where it stands

    func testEveryAmbassadorIsOfTheAreaItStandsIn() {
        for ambassador in Ambassadors.all {
            XCTAssertEqual(
                Area(genome: ambassador.genome), ambassador.area,
                "\(ambassador.genome.name.full) is pinned to \(ambassador.area) "
                    + "and its name says \(Area(genome: ambassador.genome))"
            )
        }
    }

    func testThereIsOneForEachAreaAndNoSeedIsUsedTwice() {
        XCTAssertEqual(Ambassadors.all.count, Area.allCases.count)
        XCTAssertEqual(Set(Ambassadors.seeds.keys), Set(Area.allCases))
        XCTAssertEqual(Set(Ambassadors.seeds.values).count, Area.allCases.count)
    }

    // MARK: Found rather than chosen

    /// The search that found them, run again. If this fails, either the seed
    /// label moved or `Genome`'s naming did — and the answer is not to record
    /// new hexes without saying so, because that is every area of the garden
    /// replanted with different plants.
    func testTheSearchArrivesAtTheSameTen() {
        var found: [Area: SeedID] = [:]
        var n = 0
        while found.count < Area.allCases.count && n < 20_000 {
            let seed = Ambassadors.candidate(n)
            let area = Area(genome: Genome(seed: seed))
            if found[area] == nil { found[area] = seed }
            n += 1
        }
        XCTAssertEqual(found, Ambassadors.seeds)
        // The last of the ten. Recorded so that a search which starts needing
        // thousands of tries is visible rather than merely slow.
        XCTAssertEqual(n, 82)
    }

    // MARK: Mature when the gates opened

    func testEveryAmbassadorWasFullGrownOnTheDayTheGardenOpened() {
        for ambassador in Ambassadors.all {
            let growth = ambassador.growth(now: Ambassadors.gardenOpened)
            XCTAssertEqual(
                growth.heightScale, 1, accuracy: 0.001,
                "\(ambassador.genome.name.full) was still growing on opening day"
            )
            XCTAssertEqual(growth.stage, .mature, "\(ambassador.genome.name.full) is \(growth.stage)")
        }
    }

    func testTheyWereAllSownTogetherAMonthBefore() {
        XCTAssertEqual(Set(Ambassadors.all.map(\.sown)).count, 1)
        let month = Ambassadors.gardenOpened.timeIntervalSince(Ambassadors.sown) / 86_400
        XCTAssertEqual(month, 31, accuracy: 0.01)
    }

    // MARK: Standing in the garden

    /// **The walk opens with its ambassador at its head, in its own tier.**
    ///
    /// Not a reserved slot and not a role in a template: it is the first thing
    /// the rule placed, and the rule placed it the way it places everything.
    /// `LongWalk.ambassador` says why that is the right reading of "specimen"
    /// for an area whose plots open end to end and never reach an end.
    func testTheWalkOpensWithItsAmbassadorAtItsHead() {
        let walk = LongWalk.Walk.opened()
        XCTAssertEqual(walk.plantings.count, 1)
        XCTAssertEqual(walk.plots, 1)

        let standing = LongWalk.ambassador
        let travel = Ambassadors.of(.travel)
        XCTAssertEqual(standing.seed, travel.seed.hex)
        XCTAssertEqual(standing.plot, 0)
        XCTAssertEqual(standing.slot.tier, standing.traits.tier,
                       "the ambassador was put somewhere other than its own tier")

        // The first slot of its tier in tie-breaking order, which is the start
        // of the plot: an empty plot scores every open slot alike, so the tie
        // is broken down the walk and the ambassador stands where a visitor
        // coming down onto plot 0 meets it first.
        let first = LongWalk.slots.first { $0.tier == standing.traits.tier }
        XCTAssertEqual(standing.slot, first)
    }

    /// **Asking twice gives the same plant in the same place.**
    ///
    /// This is the property that lets the service derive the ambassador instead
    /// of storing it. If a slot or a nudge ever stopped being a pure function of
    /// the pinned seed, an ambassador would move between two requests — which
    /// is the one thing nothing in this garden is allowed to do.
    func testItsPlacementIsDerivedAndNotDrawnAfresh() {
        XCTAssertEqual(LongWalk.Walk.opened().plantings[0], LongWalk.Walk.opened().plantings[0])
        XCTAssertEqual(LongWalk.ambassador, LongWalk.Walk.opened().plantings[0])
    }

    /// **Six hundred arrivals later it has not moved, and nobody is standing on
    /// it.**
    ///
    /// The point of handing the ambassador to the rule ahead of the stored rows
    /// rather than drawing it on afterwards: everything planted since has been
    /// graded against a plant that is really there.
    func testTheWalkFillsAroundIt() {
        var walk = LongWalk.Walk.opened()
        let standing = LongWalk.ambassador
        for (seed, traits) in LongWalkVectorTests.arrivals() {
            let planting = walk.plant(seed: seed, traits: traits)
            XCTAssertFalse(planting.plot == standing.plot && planting.slot == standing.slot,
                           "\(planting.seed) was planted on top of the ambassador")
        }
        XCTAssertEqual(walk.plantings.first, standing, "the ambassador moved")
    }

    // MARK: What the rest of the site reads

    /// Pins `tools/reference/ambassador_vectors.json`, the way `AreaVectorTests`
    /// pins the areas: the website grows these plants from this package compiled
    /// to wasm, and the plot service has to name the same ten seeds in the same
    /// areas without being able to derive a single one of them.
    func testTheAmbassadorsAreWhatTheReferenceSays() throws {
        let rendered = Self.rendered()
        if ProcessInfo.processInfo.environment[Self.recordingKey] != nil {
            try rendered.write(to: Self.vectorsURL, atomically: true, encoding: .utf8)
            return
        }
        guard let onDisk = try? String(contentsOf: Self.vectorsURL, encoding: .utf8) else {
            return XCTFail("""
                tools/reference/ambassador_vectors.json is missing. Record it with \
                \(Self.recordingKey)=1 swift test --package-path Packages/SeedCore
                """)
        }
        XCTAssertEqual(onDisk, rendered, "the ambassadors have moved since the reference was recorded")
    }

    // MARK: Fixtures

    static let recordingKey = "PEACE_GARDEN_RECORD_VECTORS"

    static var vectorsURL: URL {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { url.deleteLastPathComponent() }
        return url.appendingPathComponent("tools/reference/ambassador_vectors.json")
    }

    /// Hand-rolled rather than `JSONEncoder`, so the file is in the areas'
    /// declared order and reads as a list somebody can check by eye.
    private static func rendered() -> String {
        var lines = [
            "{",
            "  \"sown\": \(Int(Ambassadors.sown.timeIntervalSince1970)),",
            "  \"gardenOpened\": \(Int(Ambassadors.gardenOpened.timeIntervalSince1970)),",
            "  \"ambassadors\": [",
        ]
        for (i, one) in Ambassadors.all.enumerated() {
            let comma = i == Area.allCases.count - 1 ? "" : ","
            let traits = one.traits
            lines.append("""
                    {"area": "\(one.area.rawValue)", "seed": "\(one.seed.hex)", \
                "name": "\(one.genome.name.full)", "genusHead": "\(one.genome.name.genusHead)", \
                "height": \(traits.height), "family": \(traits.family)}\(comma)
                """)
        }
        lines.append("  ],")
        // The ambassadors that are actually standing in a garden today, each
        // with the slot its own area's rule put it in. **The two shapes differ**
        // — a walk planting names a side and a tier, a room planting names a
        // corner and a place in a group — because the areas do, which is the
        // same reason they have a table each. The plot service derives both
        // placements from the pinned seed rather than storing them, and
        // `check_ambassador.php` is where the two derivations are held together.
        let walk = LongWalk.ambassador
        lines.append("""
              "longWalk": {"seed": "\(walk.seed)", "plot": \(walk.plot), \
            "side": \(walk.slot.side.rawValue), "tier": \(walk.slot.tier.rawValue), \
            "index": \(walk.slot.index), "nudge": [\(walk.nudge.x), \(walk.nudge.z)]},
            """)
        let room = QuietGarden.ambassador
        lines.append("""
              "quietGarden": {"seed": "\(room.seed)", "plot": \(room.plot), \
            "corner": \(room.slot.corner.rawValue), "index": \(room.slot.index), \
            "nudge": [\(room.nudge.x), \(room.nudge.z)]}
            """)
        lines.append("}")
        return lines.joined(separator: "\n") + "\n"
    }
}
