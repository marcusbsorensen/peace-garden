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
            lines.append("""
                    {"area": "\(one.area.rawValue)", "seed": "\(one.seed.hex)", \
                "name": "\(one.genome.name.full)", "genusHead": "\(one.genome.name.genusHead)"}\(comma)
                """)
        }
        lines.append("  ]")
        lines.append("}")
        return lines.joined(separator: "\n") + "\n"
    }
}
