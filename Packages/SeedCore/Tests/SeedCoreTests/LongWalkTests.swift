import XCTest
@testable import SeedCore

/// The Long Walk's rule: where an arriving plant goes, and that it stays there.
final class LongWalkTests: XCTestCase {

    private func seed(_ label: String) -> SeedID {
        SeedID(bytes: seedDigest(SeedDomain.seed, Data(label.utf8)))!
    }

    /// Arrivals with the height and colour a real garden has, without building
    /// three hundred meshes: heights drawn over the measured range, with the
    /// same thirds, and colours spread across the families.
    private func arrivals(_ count: Int) -> [(SeedID, LongWalk.Traits)] {
        var random = SplitMix64(seed: 2026)
        return (0..<count).map { n in
            let u = Double(random.next() % 10_000) / 10_000
            // Piecewise through the measured centiles: 0.12, 0.62 at a third,
            // 1.07 at two thirds, 2.47 at the top (three thousand crossings
            // after the re-roll of 28 September 2026; they were 0.15, 0.70,
            // 1.09 and 2.31 on the shapes of 24 September, and 0.21, 0.85,
            // 1.19 and 2.22 before).
            let height = u < 1 / 3 ? 0.12 + u * 3 * 0.50
                : u < 2 / 3 ? 0.62 + (u - 1 / 3) * 3 * 0.45
                : 1.07 + (u - 2 / 3) * 3 * 1.40
            let family = Int(random.next() % 7)
            return (seed("arrival-\(n)"), LongWalk.Traits(height: height, family: family))
        }
    }

    private func walk(_ count: Int) -> LongWalk.Walk {
        var walk = LongWalk.Walk()
        for (seed, traits) in arrivals(count) { walk.plant(seed: seed, traits: traits) }
        return walk
    }

    // MARK: - Nothing moves

    /// **A plant never moves once planted**, whatever arrives after it. This is
    /// the one property the seed-derived grid existed to give, and the reason
    /// the walk is append-only.
    func testAPlantedPlantNeverMoves() {
        var walk = LongWalk.Walk()
        var before: [LongWalk.Planting] = []
        for (seed, traits) in arrivals(240) {
            walk.plant(seed: seed, traits: traits)
            XCTAssertEqual(Array(walk.plantings.prefix(before.count)), before,
                           "planting one more moved one already there")
            before = walk.plantings
        }
    }

    /// And the whole walk survives the file it is stored as.
    func testTheWalkRoundTrips() throws {
        let walk = walk(60)
        let back = try JSONDecoder().decode(LongWalk.Walk.self, from: JSONEncoder().encode(walk))
        XCTAssertEqual(back, walk)
    }

    // MARK: - The border

    /// **Nothing stands in front of something shorter than itself**, anywhere
    /// in the walk — the rule the tiers exist to keep, checked plant by plant.
    func testNothingStandsInFrontOfSomethingShorter() {
        let walk = walk(300)
        for planting in walk.plantings {
            for other in walk.plot(planting.plot) where other.slot.side == planting.slot.side
                && other.slot.tier.rawValue > planting.slot.tier.rawValue
                && abs(other.slot.spot.z - planting.slot.spot.z) <= LongWalk.Walk.orderReach {
                XCTAssertLessThanOrEqual(planting.traits.height, other.traits.height,
                                         "a plant of \(planting.traits.height) m in front of one of \(other.traits.height) m")
            }
        }
    }

    /// **A lens's back is back tier and its tip front tier**: every lens runs
    /// from the hedge to the path, so depth and tier agree within a lens.
    func testALensRunsFromTheBackOfTheBorderToItsFront() {
        for lens in 0..<LongWalk.lenses {
            let places = LongWalk.placesIn[lens].map { LongWalk.slots[$0] }
            XCTAssertTrue([3, 5].contains(places.count), "lens \(lens) holds \(places.count)")
            for a in places {
                for b in places where a.tier.rawValue > b.tier.rawValue {
                    XCTAssertGreaterThan(abs(a.spot.x), abs(b.spot.x),
                                         "lens \(lens): a back place stands nearer the path than a front one")
                }
            }
            XCTAssertEqual(Set(places.map(\.tier)), Set(LongWalk.Tier.allCases), "lens \(lens) lacks a tier")
        }
        XCTAssertEqual(LongWalk.Tier.allCases.map(\.slots), [9, 9, 6])
    }

    /// And a plant is out of its own tier only by one row, never front to back.
    func testAPlantIsNeverMoreThanOneRowFromItsTier() {
        for planting in walk(300).plantings {
            XCTAssertLessThanOrEqual(abs(planting.slot.tier.rawValue - planting.traits.tier.rawValue), 1)
        }
    }

    /// No two plants in one slot.
    func testNoSlotIsTakenTwice() {
        let walk = walk(300)
        for plot in 0..<walk.plots {
            let slots = walk.plot(plot).map(\.slot)
            XCTAssertEqual(slots.count, Set(slots).count, "plot \(plot) has a slot taken twice")
        }
    }

    /// Everything stands in the border and not on the path or in the hedge.
    func testEverythingStandsInTheBorder() {
        for planting in walk(300).plantings {
            let out = abs(planting.spot.x)
            XCTAssertGreaterThan(out, LongWalk.pathHalfWidth, "a plant on the path")
            XCTAssertLessThan(out, LongWalk.hedgeFrom, "a plant in the hedge")
            XCTAssertLessThan(abs(planting.spot.z), LongWalk.plotSide / 2, "a plant off the end of its plot")
        }
    }

    /// **Plots fill before the walk goes on.** Measured at six hundred
    /// arrivals, with two rows a tier: every plot but the newest four was
    /// full. Filling by row alone left eleven plots of the first fifteen at six
    /// to nine plants.
    ///
    /// **Since the drifts of 2 October 2026 a lens holds one colour**, so a
    /// plot can be left waiting for a colour to fill its lens: at six hundred
    /// of these arrivals, which come in seven colours equally, the first nine
    /// plots hold 48 or 47 and the growing end is five plots, 44, 45, 40, 34
    /// and 6. On the area's own thousand plants (`tools/layouts`) 98.9% of
    /// every settled place is held, where the rows held 92.2%.
    func testPlotsFillBeforeTheWalkGoesOn() {
        let walk = walk(600)
        let perPlot = LongWalk.slots.count
        XCTAssertEqual(perPlot, 48)
        let settled = (0..<max(0, walk.plots - 5)).map { walk.plot($0).count }
        print("LONG WALK: \((0..<walk.plots).map { walk.plot($0).count })")
        XCTAssertGreaterThan(settled.count, 8)
        for (plot, count) in settled.enumerated() {
            XCTAssertGreaterThanOrEqual(count, perPlot - 1, "plot \(plot) left with \(count) of \(perPlot)")
        }
        XCTAssertLessThanOrEqual(walk.plots, 14)
    }

    // MARK: - Drifts

    /// **A lens is a drift**: it holds one colour, the colour of the first
    /// plant sown in it, and so a drift is five at most, three in a lens of
    /// three. Most plants stand with another of their colour.
    func testALensHoldsOneColour() {
        let walk = walk(300)
        var inDrift = 0
        for plot in 0..<walk.plots {
            let here = walk.plot(plot)
            for lens in 0..<LongWalk.lenses {
                let sown = here.filter { $0.slot.lens == lens }
                XCTAssertLessThanOrEqual(Set(sown.map(\.traits.family)).count, 1,
                                         "lens \(lens) of plot \(plot) holds two colours")
                XCTAssertEqual(walk.claim(of: lens, in: plot), sown.first?.traits.family)
                if sown.count >= 2 { inDrift += sown.count }
            }
        }
        XCTAssertGreaterThan(Double(inDrift) / Double(walk.plantings.count), 0.6,
                             "only \(inDrift) of \(walk.plantings.count) plants stand in a drift")
    }

    /// **The same colour starts again further down the walk**: no colour holds
    /// two lenses beside each other in one border, nor the two that meet across
    /// the join between one plot and the next, as the walk is drawn.
    func testAColourNeverHoldsTwoLensesSideBySide() {
        let walk = walk(600)
        for plot in 0..<walk.plots {
            for a in 0..<LongWalk.lenses {
                for b in 0..<LongWalk.lenses where a < b && LongWalk.sideOf[a] == LongWalk.sideOf[b]
                    && abs(LongWalk.alongOf[a] - LongWalk.alongOf[b]) == 1 {
                    if let colour = walk.claim(of: a, in: plot) {
                        XCTAssertNotEqual(walk.claim(of: b, in: plot), colour, "plot \(plot), lenses \(a) and \(b)")
                    }
                }
            }
            guard plot + 1 < walk.plots else { continue }
            for a in 0..<LongWalk.lenses {
                for b in 0..<LongWalk.lenses {
                    let foot = LongWalk.onTheWalk(a, in: plot), head = LongWalk.onTheWalk(b, in: plot + 1)
                    guard foot.along == 5, head.along == 0, foot.side == head.side,
                          let colour = walk.claim(of: a, in: plot) else { continue }
                    XCTAssertNotEqual(walk.claim(of: b, in: plot + 1), colour,
                                      "one colour runs on across the join after plot \(plot)")
                }
            }
        }
    }

    /// **Each plot runs cool–hot–cool**: the warm colours stand mostly in the
    /// four lenses nearest a plot's middle and the cool ones mostly in the
    /// eight nearer its ends.
    func testEachPlotIsGradedCoolHotCool() {
        let walk = walk(600)
        var warmMiddle = 0, warm = 0, coolMiddle = 0, cool = 0
        for planting in walk.plantings where planting.plot < walk.plots - 2 {
            let middle = planting.slot.lens < 4
            if LongWalk.isWarm(planting.traits.family) {
                warm += 1; if middle { warmMiddle += 1 }
            } else {
                cool += 1; if middle { coolMiddle += 1 }
            }
        }
        XCTAssertGreaterThan(Double(warmMiddle) / Double(warm), 0.5, "the warm colours are not in the middle")
        XCTAssertLessThan(Double(coolMiddle) / Double(cool), 0.15, "the cool colours are in the middle")
    }

    /// **A plot of ten looks finished**: the first plants of a walk stand in
    /// the middle of plot 0 and at its ends, not in a row from its head.
    func testTheFirstTenSpreadOverThePlot() {
        let walk = walk(10)
        XCTAssertEqual(walk.plots, 1)
        let lenses = Set(walk.plantings.map(\.slot.lens))
        XCTAssertGreaterThanOrEqual(lenses.count, 4, "ten plants in \(lenses.count) lenses")
        let sides = Set(walk.plantings.map(\.slot.side))
        XCTAssertEqual(sides.count, 2, "ten plants down one side of the path")
        let along = walk.plantings.map(\.slot.spot.z)
        XCTAssertGreaterThan(along.max()! - along.min()!, 2.0, "ten plants bunched at one end")
    }

    // MARK: - The plot's variant

    /// **Plots are turned half round and mirrored by their number**, and a
    /// plant stands where its place is on its plot as turned: the same
    /// distance from the path, the same distance from the plot's middle.
    func testAPlantStandsOnItsPlaceAsItsPlotIsTurned() {
        let walk = walk(300)
        var seen = Set<PlotVariant>()
        for planting in walk.plantings {
            let variant = LongWalk.variant(of: planting.plot)
            seen.insert(variant)
            XCTAssertTrue(variant.turn == 0 || variant.turn == 2, "a quarter turn would lay the path across")
            let back = variant.undo(planting.spot)
            XCTAssertEqual(back.x, planting.slot.spot.x + planting.nudge.x, accuracy: 1e-12)
            XCTAssertEqual(back.z, planting.slot.spot.z + planting.nudge.z, accuracy: 1e-12)
        }
        XCTAssertEqual(seen.count, 4, "every way round a plot can be laid")
        XCTAssertEqual(LongWalk.variant(of: 0), .plain)
    }

    // MARK: - Reading a real plant

    /// A real crossing's traits: a grown height in the measured range and a
    /// colour family that exists.
    func testARealPlantHasTraitsTheRuleCanUse() {
        let a = seed("walker-a"), b = seed("walker-b")
        let encounter = Pollination.encounterID(seedA: a, seedB: b,
                                                nonceA: Data("a".utf8), nonceB: Data("b".utf8))
        let child = Pollination.cross(seedA: a, seedB: b, encounterID: encounter)
        let genome = Genome(seed: child, lineage: .crossed(parentA: a, parentB: b, encounterID: encounter))
        let traits = LongWalk.traits(of: genome)
        XCTAssertTrue((0.12...2.6).contains(traits.height), "height \(traits.height)")
        XCTAssertTrue((0...LongWalk.paleFamily).contains(traits.family))
    }

    /// The cuts, where the measurement put them.
    func testTheTiersAreCutWhereTheyWereMeasured() {
        // 0.75 and 1.18 since 29 September 2026; 0.77 and 1.20 until then.
        XCTAssertEqual(LongWalk.tier(height: 0.5), .edge)
        XCTAssertEqual(LongWalk.tier(height: 0.74), .edge)
        XCTAssertEqual(LongWalk.tier(height: 0.75), .middle)
        XCTAssertEqual(LongWalk.tier(height: 1.17), .middle)
        XCTAssertEqual(LongWalk.tier(height: 1.18), .back)
        XCTAssertEqual(LongWalk.family(hue: 0.1, saturation: 0.1), LongWalk.paleFamily)
        XCTAssertEqual(LongWalk.family(hue: 0.99, saturation: 0.8), 5)
        XCTAssertEqual(LongWalk.family(hue: 350, saturation: 0.8), 5)
    }
}
