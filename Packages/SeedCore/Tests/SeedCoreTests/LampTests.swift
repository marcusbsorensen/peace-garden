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

    /// **A light written before it could be turned or resized opens exactly as
    /// it was.** Nothing stored, so it faces the way its identifier has always
    /// dealt it and is drawn at its own size — and written back, it is written
    /// without the new fields, so the file does not change by being opened.
    func testALightFromBeforeTurningOpensAsItWas() throws {
        let json = """
        {"id":"22222222-0000-4000-8000-000000000001","kind":"hare","spot":{"x":1,"z":2}}
        """
        let lamp = try JSONDecoder().decode(Lamp.self, from: Data(json.utf8))

        XCTAssertNil(lamp.facing)
        XCTAssertNil(lamp.scale)
        XCTAssertEqual(lamp.drawnScale, 1)
        // `0x22` is the identifier's second byte, which is what the figures
        // have always faced by.
        XCTAssertEqual(lamp.drawnFacing, 0x22 % 8)

        let written = String(decoding: try JSONEncoder().encode(lamp), as: UTF8.self)
        XCTAssertFalse(written.contains("facing"), written)
        XCTAssertFalse(written.contains("scale"), written)
    }

    /// Turned and resized, and round the file with both kept.
    func testATurnedAndResizedLightRoundTrips() throws {
        var bed = Bed(name: "")
        let hare = Lamp(kind: .hare, spot: Spot(x: 0, z: 0))
        let lantern = Lamp(kind: .lantern, spot: Spot(x: 1, z: 0))
        bed.add(hare)
        bed.add(lantern)

        bed.change(lamp: hare.id) { lamp in
            lamp.facing = lamp.drawnFacing + 3
            lamp.scale = 1.4
        }

        let back = try JSONDecoder().decode(Bed.self, from: JSONEncoder().encode(bed))
        XCTAssertEqual(back, bed)
        let turned = try XCTUnwrap(back.allLamps.first { $0.id == hare.id })
        XCTAssertEqual(turned.drawnFacing, (hare.dealtFacing + 3) % 8)
        XCTAssertEqual(turned.drawnScale, 1.4, accuracy: 1e-9)
        XCTAssertEqual(back.allLamps.first { $0.id == lantern.id }, lantern,
                       "turning one light changed another")
    }

    /// A facing past a whole turn, or a size from a build that allows more, is
    /// drawn as the nearest this one can.
    func testAFacingWrapsAndASizeIsHeldInRange() {
        var lamp = Lamp(kind: .fox, spot: Spot(x: 0, z: 0), facing: -1, scale: 4)
        XCTAssertEqual(lamp.drawnFacing, 7)
        XCTAssertEqual(lamp.drawnScale, Lamp.scales.upperBound)
        lamp.facing = 9
        lamp.scale = 0.1
        XCTAssertEqual(lamp.drawnFacing, 1)
        XCTAssertEqual(lamp.drawnScale, Lamp.scales.lowerBound)
    }

    /// The kinds are the file format, like the trait labels: added to, never
    /// renamed.
    func testTheNamesOfTheLightsAreTheFileFormat() {
        XCTAssertEqual(LampKind.lantern.rawValue, "lantern")
        XCTAssertEqual(LampKind.paperLamp.rawValue, "paperLamp")
        XCTAssertEqual(LampKind.fireflies.rawValue, "fireflies")
        XCTAssertEqual(LampKind.hare.rawValue, "hare")
        XCTAssertEqual(LampKind.fox.rawValue, "fox")
        XCTAssertEqual(LampKind.moth.rawValue, "moth")
        XCTAssertEqual(LampKind.snail.rawValue, "snail")
    }
}
