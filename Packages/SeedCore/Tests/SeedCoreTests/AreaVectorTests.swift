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
    func testOnlyAnOpenAreaHasATable() {
        for area in Area.allCases {
            XCTAssertEqual(area.isOpen, !area.table.isEmpty, "\(area.rawValue)")
        }
    }

    func testTheLongWalkIsTheTravelArea() {
        XCTAssertEqual(Area.travel.table, "long_walk")
        XCTAssertEqual(Area.open, [.travel])
    }
}
