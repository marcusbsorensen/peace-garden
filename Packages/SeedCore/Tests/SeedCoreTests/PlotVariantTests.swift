import XCTest
@testable import SeedCore

/// How a plot is turned, mirrored and given a feature variant from its number
/// (`PlotVariant`), said as the properties the design asked for rather than as
/// samples of them. `PlotVariantVectorTests` pins the samples for the ports.
final class PlotVariantTests: XCTestCase {

    /// Every space an area could declare.
    static let spaces: [PlotVariant.Space] = [1, 2, 4].flatMap { turns in
        [false, true].flatMap { mirror in
            [1, 2, 3, 5].map { PlotVariant.Space(turns: turns, mirror: mirror, nudges: $0) }
        }
    }

    func testASpaceListsEachOfItsVariantsOnce() {
        for space in Self.spaces {
            let all = (0..<space.count).map(space.variant)
            XCTAssertEqual(Set(all).count, space.count, "\(space)")
            XCTAssertEqual(all.first, .plain)
            for v in all {
                XCTAssertEqual(v.turn % (4 / space.turns), 0, "\(space) turned \(v.turn)")
                XCTAssertTrue(space.mirror || !v.mirror)
                XCTAssertTrue((0..<space.nudges).contains(v.nudge))
            }
        }
    }

    /// **Plot 0 is the plan as drawn**, in every area and every space.
    func testEveryAreasFirstPlotIsPlain() {
        for area in Area.allCases {
            XCTAssertEqual(PlotVariant.of(plot: 0, area: area), .plain, "\(area)")
        }
        for space in Self.spaces {
            XCTAssertEqual(PlotVariant.of(plot: 0, salt: 12345, in: space), .plain)
        }
    }

    /// **No plot is laid as the plot before it**, wherever a space has more
    /// than one variant, and every block of `count` plots holds them all.
    func testNeighboursDifferAndEveryBlockHoldsEveryVariant() {
        for (n, space) in Self.spaces.enumerated() where space.varies {
            let salt = PlotVariant.salt(of: Area.allCases[n % Area.allCases.count])
            let dealt = (0..<(space.count * 40)).map { PlotVariant.of(plot: $0, salt: salt, in: space) }
            for plot in 1..<dealt.count {
                XCTAssertNotEqual(dealt[plot], dealt[plot - 1], "\(space): plots \(plot - 1) and \(plot)")
            }
            for block in stride(from: 0, to: dealt.count, by: space.count) {
                XCTAssertEqual(Set(dealt[block..<(block + space.count)]).count, space.count,
                               "\(space): the block from plot \(block) repeats a variant")
            }
        }
    }

    /// **A space of two alternates**, which is what the Home Ground's bow
    /// was asked to do.
    func testASpaceOfTwoAlternates() {
        let space = PlotVariant.Space(mirror: true)
        for plot in 0..<50 {
            XCTAssertEqual(PlotVariant.of(plot: plot, salt: 99, in: space).mirror, plot % 2 == 1)
        }
    }

    /// The shuffle is not one order for every block, or every area: the first
    /// forty blocks of an eight-way space are not all dealt alike, and two
    /// areas with the same space do not turn in step.
    func testTheDealIsShuffled() {
        let space = PlotVariant.Space(turns: 4, mirror: true)
        let salt = PlotVariant.salt(of: .peace)
        let blocks = Set((0..<40).map { block in
            (0..<8).map { PlotVariant.of(plot: block * 8 + $0, salt: salt, in: space) }
        })
        XCTAssertGreaterThan(blocks.count, 30)
        let other = PlotVariant.salt(of: .meeting)
        let same = (0..<400).filter {
            PlotVariant.of(plot: $0, salt: salt, in: space) == PlotVariant.of(plot: $0, salt: other, in: space)
        }.count
        XCTAssertLessThan(same, 100, "the Quiet Garden and the Crossing turn in step")
        XCTAssertEqual(Set(Area.allCases.map(PlotVariant.salt)).count, Area.allCases.count)
    }

    /// **The Knot Garden and the Glasshouse are laid one way; the other eight
    /// vary** (Marcus, 2 October 2026).
    func testTheKnotGardenAndTheGlasshouseAreFixedAndTheRestVary() {
        for area in Area.allCases {
            let fixed = area == .pattern || area == .light
            XCTAssertEqual(area.plotVariants.varies, !fixed, "\(area)")
            if fixed {
                for plot in 0..<20 { XCTAssertEqual(PlotVariant.of(plot: plot, area: area), .plain) }
            }
        }
    }

    // MARK: Where a place is drawn

    /// **Turning and mirroring are exact**: the same two numbers come out,
    /// signs changed and axes swapped, and undoing gives back the place to the
    /// bit. A quarter turn takes `x+` to `z+`.
    func testTurningAndMirroringAreExactAndUndo() {
        XCTAssertEqual(PlotVariant(turn: 1, mirror: false, nudge: 0).apply(Spot(x: 1, z: 0)).z, 1)
        XCTAssertEqual(PlotVariant(turn: 1, mirror: false, nudge: 0).apply(Spot(x: 0, z: 1)).x, -1)
        XCTAssertEqual(PlotVariant(turn: 0, mirror: true, nudge: 0).apply(Spot(x: 1.25, z: 0.5)).x, -1.25)
        var rng = SplitMix64(seed: 7)
        for _ in 0..<200 {
            let spot = Spot(x: Double(rng.next() % 5_200) / 1000 - 2.6, z: Double(rng.next() % 5_200) / 1000 - 2.6)
            for turn in 0..<4 {
                for mirror in [false, true] {
                    let v = PlotVariant(turn: turn, mirror: mirror, nudge: 0)
                    let moved = v.apply(spot)
                    XCTAssertEqual(Set([abs(moved.x), abs(moved.z)]), Set([abs(spot.x), abs(spot.z)]))
                    XCTAssertEqual(v.undo(moved), spot)
                    XCTAssertEqual(moved.x * moved.x + moved.z * moved.z, spot.x * spot.x + spot.z * spot.z)
                }
            }
        }
        // Four quarter turns are none.
        let quarter = PlotVariant(turn: 1, mirror: false, nudge: 0)
        let p = Spot(x: 0.37, z: -1.91)
        XCTAssertEqual(quarter.apply(quarter.apply(quarter.apply(quarter.apply(p)))), p)
    }

    /// A place on an axis stays at `+0`, so a vector file never prints `-0.0`.
    func testAPlaceOnAnAxisStaysPositiveZero() {
        for turn in 0..<4 {
            for mirror in [false, true] {
                let moved = PlotVariant(turn: turn, mirror: mirror, nudge: 0).apply(Spot(x: 0, z: 0))
                XCTAssertEqual(moved.x.sign, .plus)
                XCTAssertEqual(moved.z.sign, .plus)
            }
        }
    }
}
