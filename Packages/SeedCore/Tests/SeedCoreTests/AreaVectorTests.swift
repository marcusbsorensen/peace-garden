import XCTest
@testable import SeedCore

/// Pins `tools/reference/area_vectors.json` to `Area`, so the plot service
/// cannot disagree with the phone about which areas exist or which are open.
///
/// **Why ten strings need a reference check.** They are small and they are the
/// kind of thing two codebases drift on silently: the day the Orchard opens,
/// `Areas.php` learns it and `Area.swift` does not, and a phone goes on telling
/// a gardener their plant has nowhere to stand while the service would have
/// taken it. Nothing fails, nothing logs, and the gardener is simply told no
/// for a week. `tools/reference/check_areas.php` fails CI instead.
final class AreaVectorTests: XCTestCase {
    static var vectorsURL: URL {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { url.deleteLastPathComponent() }   // …/Tests/SeedCoreTests/<this>
        return url.appendingPathComponent("tools/reference/area_vectors.json")
    }

    static let recordingKey = "PEACE_GARDEN_RECORD_VECTORS"

    /// One line an area, in the order `Area` declares them — which is the order
    /// the service answers `/api/garden` in, and is itself part of what is
    /// pinned: a list in a different order is a different list to anything
    /// reading it by position.
    static func render() -> String {
        let rows = Area.allCases.map { area in
            """
              { "area": "\(area.rawValue)", "open": \(area.isOpen), "table": "\(area.table)" }
            """.trimmingCharacters(in: .whitespaces)
        }
        return "[\n  " + rows.joined(separator: ",\n  ") + "\n]\n"
    }

    func testTheAreasAreWhatTheReferenceSays() throws {
        let rendered = Self.render()
        if ProcessInfo.processInfo.environment[Self.recordingKey] != nil {
            try rendered.write(to: Self.vectorsURL, atomically: true, encoding: .utf8)
            return
        }
        guard let onDisk = try? String(contentsOf: Self.vectorsURL, encoding: .utf8) else {
            XCTFail("""
                tools/reference/area_vectors.json is missing. Record it with \
                \(Self.recordingKey)=1 swift test --filter AreaVectorTests
                """)
            return
        }
        XCTAssertEqual(onDisk, rendered, """
            The areas have changed. If that is intended, record the reference with \
            \(Self.recordingKey)=1 swift test --filter AreaVectorTests — and open \
            Server/.api/Areas.php in the same commit, because check_areas.php \
            holds the two together.
            """)
    }

    /// **An open area has a table and a closed one does not.** The two are one
    /// fact said twice, and a table named for an area with no placement rule is
    /// a promise about a schema nobody has designed.
    // MARK: The syllables

    /// Every genus head belongs to exactly one area, and no area claims a
    /// syllable that is not one. The table is hand-written over a frozen list,
    /// which is the kind of thing that goes wrong silently: a head dropped from
    /// it costs nobody a compile error and quietly sends a tenth of all plants
    /// to the Seedbed.
    func testEveryGenusHeadBelongsToExactlyOneArea() {
        var claims: [String: [Area]] = [:]
        for area in Area.allCases {
            for head in area.genusHeads { claims[head, default: []].append(area) }
        }
        for head in PlantName.genusHeads {
            XCTAssertEqual(
                claims[head]?.count, 1,
                "\(head) is claimed by \(claims[head] ?? []) — every head needs exactly one area"
            )
        }
        XCTAssertEqual(claims.count, PlantName.genusHeads.count)
    }

    func testNoAreaClaimsASyllableThatDoesNotExist() {
        let known = Set(PlantName.genusHeads)
        for area in Area.allCases {
            for head in area.genusHeads {
                XCTAssertTrue(known.contains(head), "\(area) claims \(head), which is not a genus head")
            }
        }
    }

    /// A plant is filed by the name it carries. Minting its seed afresh gives
    /// a different plant with a different name, so reading the area off the
    /// genome and reading it off a fresh mint are different answers, and this
    /// one is the genome's.
    func testAPlantsAreaIsReadFromTheNameItCarries() {
        for i in 0..<64 {
            let seed = SeedID(bytes: seedDigest(SeedDomain.seed, Data("area-\(i)".utf8)))!
            let genome = Genome(seed: seed)
            XCTAssertEqual(Area(genome: genome), Area(genusHead: genome.name.genusHead))
            XCTAssertTrue(Area(genome: genome).genusHeads.contains(genome.name.genusHead))
        }
    }

    func testOnlyAnOpenAreaHasATable() {
        for area in Area.allCases {
            XCTAssertEqual(area.isOpen, !area.table.isEmpty, "\(area.rawValue)")
        }
    }

    /// **Which areas are open, written down where changing it is deliberate.**
    /// Opening one is a decision about the garden rather than a tidy-up, so it
    /// fails here first and somebody edits this line on purpose — the same
    /// reason `check_areas.php` checks the list rather than deriving it.
    func testTheOpenAreasAreTheWalkTheRoomTheCrossingTheOrchardAndTheKnot() {
        XCTAssertEqual(Area.travel.table, "long_walk")
        XCTAssertEqual(Area.meeting.table, "crossing")
        XCTAssertEqual(Area.kinship.table, "orchard")
        XCTAssertEqual(Area.peace.table, "quiet_garden")
        XCTAssertEqual(Area.pattern.table, "knot_garden")
        XCTAssertEqual(Area.open, [.pattern, .travel, .meeting, .kinship, .peace])
    }
}
