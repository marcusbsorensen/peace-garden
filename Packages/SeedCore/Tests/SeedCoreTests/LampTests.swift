import XCTest
@testable import SeedCore

/// The lights somebody puts out in a bed.
///
/// One of these guards the property that matters most and would never be seen
/// going wrong until it was: a garden written by a later build, holding a light
/// this build has never heard of, has to open here.
final class LampTests: XCTestCase {

    /// **A light this build cannot draw must not cost the garden.** A Swift
    /// enum that meets an unknown raw value while decoding throws, and in a
    /// `Codable` garden that takes every plant down with it. So a lamp's kind is
    /// stored as the string it was written as, and an unknown one decodes and is
    /// simply not drawn.
    func testAGardenWithALightFromTheFutureStillOpens() throws {
        let json = """
        {"id":"11111111-1111-4111-8111-111111111111","name":"","template":"thematic",
         "placed":{},"world":2,
         "lamps":[
           {"id":"22222222-0000-4000-8000-000000000001","kind":"lantern","spot":{"x":1,"z":2}},
           {"id":"22222222-0000-4000-8000-000000000002","kind":"glowworm","spot":{"x":0,"z":0}}
         ]}
        """
        let bed = try JSONDecoder().decode(Bed.self, from: Data(json.utf8))

        XCTAssertEqual(bed.allLamps.count, 2)
        XCTAssertEqual(bed.allLamps[0].known, .lantern)
        XCTAssertNil(bed.allLamps[1].known, "a light from the future was taken for one of ours")
        XCTAssertEqual(bed.world, 2)
    }

    /// And a bed written before lights existed decodes as having none, without
    /// anything having to migrate.
    func testABedFromBeforeLightsHasNone() throws {
        let json = """
        {"id":"11111111-1111-4111-8111-111111111111","name":"","template":"colours","placed":{}}
        """
        let bed = try JSONDecoder().decode(Bed.self, from: Data(json.utf8))
        XCTAssertNil(bed.lamps)
        XCTAssertTrue(bed.allLamps.isEmpty)
    }

    /// Put out, moved and taken away again, and each change only to the light it
    /// was meant for.
    func testALightIsPutOutMovedAndTakenAway() throws {
        var bed = Bed(name: "")
        let lantern = Lamp(kind: .lantern, spot: Spot(x: 0, z: 0))
        let drift = Lamp(kind: .fireflies, spot: Spot(x: 1, z: 1))

        bed.add(lantern)
        bed.add(drift)
        bed.move(lamp: lantern.id, to: Spot(x: -1, z: 0.5))

        XCTAssertEqual(bed.allLamps.first { $0.id == lantern.id }?.spot, Spot(x: -1, z: 0.5))
        XCTAssertEqual(bed.allLamps.first { $0.id == drift.id }?.spot, Spot(x: 1, z: 1))

        bed.remove(lamp: lantern.id)
        XCTAssertEqual(bed.allLamps.map(\.id), [drift.id])

        // And round the file, as it is written.
        let back = try JSONDecoder().decode(Bed.self, from: JSONEncoder().encode(bed))
        XCTAssertEqual(back, bed)
    }

    /// The kinds are the file format, like the trait labels: added to, never
    /// renamed.
    func testTheNamesOfTheLightsAreTheFileFormat() {
        XCTAssertEqual(LampKind.lantern.rawValue, "lantern")
        XCTAssertEqual(LampKind.paperLamp.rawValue, "paperLamp")
        XCTAssertEqual(LampKind.fireflies.rawValue, "fireflies")
    }
}
