import SeedCore
import XCTest
@testable import PeaceGarden

/// Turning and resizing a light from its panel.
///
/// What it looks like is looked at. What is here is the promise that made the
/// new fields optional: a light nobody has touched is drawn exactly as it was
/// before they existed.
@MainActor
final class LampPanelTests: XCTestCase {

    /// **An untouched light keeps the seed it always had**, so no figure in a
    /// garden turns round, and no drift of fireflies changes its drift, because
    /// a build that can turn them was installed.
    func testAnUntouchedLightIsDrawnAsBefore() {
        for _ in 0..<64 {
            let lamp = Lamp(kind: .hare, spot: Spot(x: 0, z: 0))
            let before = Int(lamp.id.uuid.0) << 8 | Int(lamp.id.uuid.1)
            XCTAssertEqual(PlotView.seed(of: lamp), before)
        }
    }

    /// A figure turned to a facing is drawn at that facing, and only the facing
    /// moves: the rest of the seed is still the light's own.
    func testATurnedFigureFacesTheWayItWasTurned() {
        var lamp = Lamp(kind: .fox, spot: Spot(x: 0, z: 0))
        let before = PlotView.seed(of: lamp)

        for facing in 0..<8 {
            lamp.facing = facing
            let seed = PlotView.seed(of: lamp)
            XCTAssertEqual(GardenCreatures.facing(seed: seed), facing)
            XCTAssertEqual(seed & ~7, before & ~7)
        }
    }
}
