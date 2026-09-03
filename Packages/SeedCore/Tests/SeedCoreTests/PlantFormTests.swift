import XCTest
#if canImport(simd)
import simd
#endif
@testable import SeedCore

/// The three inflorescences, and the one property that could not be fixed later.
///
/// The visual half of this is `tools/preview/archetypes.py`, which puts one
/// plant of each of the twelve archetypes side by side. What is here is what a
/// person cannot see by looking: that a fixed seed still draws the mesh it drew
/// yesterday, and that a head divides gradually rather than between one frame
/// and the next.
final class PlantFormTests: XCTestCase {

    private func genome(_ label: String) -> Genome {
        Genome(seed: SeedMint.mint(fromEntropy: Data(label.utf8)))
    }

    /// The first seed that grows a given archetype.
    ///
    /// Searched rather than chosen: an archetype is drawn from the seed, and
    /// there is no way to ask for one.
    private func genome(growing archetype: Archetype, limit: Int = 4000) -> Genome {
        for index in 0..<limit {
            let candidate = genome("form-\(index)")
            if candidate.form.archetype == archetype { return candidate }
        }
        fatalError("no seed grew a \(archetype) in \(limit) tries")
    }

    private func mature(_ genome: Genome) -> GrowthModel.State {
        let birth = Date(timeIntervalSince1970: 1_700_000_000)
        return GrowthModel(genome: genome)
            .state(birth: birth, now: birth.addingTimeInterval(400 * 86_400))
    }

    // MARK: - Determinism

    /// A seed drawn before the forms went in must still draw the same mesh.
    ///
    /// This is the one thing here that cannot be repaired afterwards: a plant
    /// somebody is already growing must not change under them. `GeneSource`
    /// draws by name rather than by position in a stream, so new keys cannot
    /// shift old ones — but that is a property of the code, and this is the
    /// test that would notice if somebody renamed a key rather than adding one.
    ///
    /// Vertex count and bounds together are enough. A renamed key moves almost
    /// every trait, and any trait that matters moves one or the other.
    ///
    /// **These numbers were moved once, deliberately, on 3 September 2026**,
    /// and the paragraph above is why that needs saying rather than doing
    /// quietly. Making the genus a description of the flower — docs/TAXONOMY.md
    /// — replaced a per-plant petal draw with a per-genus petal count, so every
    /// bloom in every garden changed and three pinned meshes with them. The
    /// umbel lost more than half its vertices, which is the old 3...13 draw
    /// scaled by 1.4 giving way to five petals or eight.
    ///
    /// That cost is the one docs/TAXONOMY.md §"What this costs" accepts: nothing
    /// has shipped, there is no listing, and the only plants that exist are on
    /// one simulator. **It was the last moment it was free**, and it does not
    /// become free again. From these numbers the test is back to doing its
    /// actual job, which is catching the same move made by accident.
    func testAFixedSeedAlwaysDrawsTheSameMesh() {
        // Seed label: vertices, then the mature plant's width and height in
        // centimetres. The three cover one inflorescence each — `vector-a` is
        // an umbel, `vector-b` a lotus, `vector-c` a succulent — which was luck
        // rather than design, but it is worth keeping if these are ever
        // renumbered.
        let expected: [String: (vertices: Int, width: Int, height: Int)] = [
            "vector-a": (9460, 50, 77),
            "vector-b": (3409, 48, 86),
            "vector-c": (4168, 24, 50)
        ]

        for (label, want) in expected.sorted(by: { $0.key < $1.key }) {
            let plant = genome(label)
            let mesh = PlantBuilder(genome: plant).mesh(growth: mature(plant))
            let extent = mesh.maxBounds - mesh.minBounds
            XCTAssertEqual(
                mesh.parts.reduce(0) { $0 + $1.positions.count }, want.vertices,
                "\(label) (\(plant.form.archetype)) changed its vertex count"
            )
            XCTAssertEqual(Int((extent.x * 100).rounded()), want.width, "\(label) width")
            XCTAssertEqual(Int((extent.y * 100).rounded()), want.height, "\(label) height")
        }
    }

    // MARK: - Every archetype claims a form

    func testTheTwelveArchetypesDivideSixTwoAndFour() {
        var counts: [Inflorescence: Int] = [:]
        for archetype in Archetype.allCases {
            counts[ArchetypeProfile.profile(for: archetype).inflorescence, default: 0] += 1
        }
        XCTAssertEqual(counts[.raceme], 6, "racemes")
        XCTAssertEqual(counts[.head], 2, "heads")
        XCTAssertEqual(counts[.solitary], 4, "solitaries")
    }

    /// The two unbranched forms carry no branches, so every consumer can walk
    /// the same list without asking which form it has.
    func testOnlyAHeadGivesOffStalks() {
        for archetype in Archetype.allCases {
            let plant = genome(growing: archetype)
            let skeleton = SkeletonBuilder.stem(
                genome: plant,
                heightScale: Float(mature(plant).heightScale)
            )
            let form = plant.branching.inflorescence
            if form == .head {
                XCTAssertFalse(skeleton.branches.isEmpty, "\(archetype) grew no stalks")
            } else {
                XCTAssertTrue(skeleton.branches.isEmpty, "\(archetype) is \(form) and branched")
            }
        }
    }

    // MARK: - What separates the two heads

    /// A flat-topped head levels its tips; a spray does not.
    ///
    /// This is the whole of the difference between `umbel` and `plume`, and it
    /// is one number. Without the levelling a corymb reads as a bundle sitting
    /// on the tip rather than as a table, which is what it looked like on the
    /// first attempt.
    func testAFlatToppedHeadLevelsItsTipsAndASprayDoesNot() {
        func tipSpread(_ archetype: Archetype) -> (spread: Float, halfWidth: Float, height: Float) {
            let plant = genome(growing: archetype)
            let skeleton = SkeletonBuilder.stem(
                genome: plant,
                heightScale: Float(mature(plant).heightScale)
            )
            let tips = skeleton.branches.compactMap { $0.path.last?.position }
            XCTAssertGreaterThanOrEqual(tips.count, 3, "\(archetype) grew too few stalks")
            let heights = tips.map(\.y)
            let apex = skeleton.apex.position.y
            return (
                (heights.max() ?? 0) - (heights.min() ?? 0),
                tips.map { max(abs($0.x), abs($0.z)) }.max() ?? 0,
                apex
            )
        }

        let flat = tipSpread(.umbel)
        let spray = tipSpread(.plume)

        // A hand's breadth of a plant is generous; the measured value is around
        // four per cent, and a fan would be well over twenty.
        XCTAssertLessThan(flat.spread, flat.height * 0.1,
                          "an umbel's tips are \(flat.spread) apart on a \(flat.height) plant")
        XCTAssertGreaterThan(spray.spread, spray.height * 0.12,
                             "a plume's tips are levelled, which makes it an umbel")

        // A head that is not wider than a stem is not a head.
        XCTAssertGreaterThan(flat.halfWidth, flat.height * 0.25)
        XCTAssertGreaterThan(spray.halfWidth, flat.halfWidth,
                             "a spray should open wider than a flat top")
    }

    // MARK: - A head opens rather than arriving

    /// Before there is an upper stem there are no stalks, and a young head is
    /// drawn as the undivided shoot it actually is.
    func testAYoungHeadHasNotDividedYet() {
        for archetype in [Archetype.umbel, .plume] {
            let plant = genome(growing: archetype)
            for heightScale in [Float(0.055), 0.1, 0.2] {
                let skeleton = SkeletonBuilder.stem(genome: plant, heightScale: heightScale)
                XCTAssertTrue(skeleton.branches.isEmpty,
                              "\(archetype) divided at heightScale \(heightScale)")
            }
        }
    }

    /// The head opens outward continuously, so nobody watching sees it appear.
    ///
    /// A stalk cannot fade in — it is geometry — so what this asks is that one
    /// arrives at nearly no length and grows, rather than springing out at
    /// full reach. Both halves are ratios rather than measurements, because a
    /// fixed threshold is either looser than a pop or tighter than the growth
    /// itself: the head opens over about half the plant's life, so the honest
    /// question is whether any single step stands out from the rest of them.
    ///
    /// The step this walks is far finer than a growth tick, so anything
    /// continuous here is continuous on screen.
    func testAHeadDividesGraduallyRatherThanAllAtOnce() {
        for archetype in [Archetype.umbel, .plume] {
            let plant = genome(growing: archetype)
            var reaches: [Float] = []
            var counts: [Int] = []

            for step in 0...400 {
                let heightScale = 0.05 + 0.95 * Float(step) / 400
                let skeleton = SkeletonBuilder.stem(genome: plant, heightScale: heightScale)
                // Tip against the stalk's own base, not against the stem's
                // axis and not against the sample it left. A stalk of no length
                // still starts a stem's radius out from the axis, so either of
                // those measures steps the moment one exists — which reads as a
                // pop in the numbers and is nothing at all on screen.
                reaches.append(
                    skeleton.branches
                        .compactMap { branch -> Float? in
                            guard let tip = branch.path.last, let base = branch.path.first
                            else { return nil }
                            return simd_length(tip.position - base.position)
                        }
                        .max() ?? 0
                )
                counts.append(skeleton.branches.count)
            }

            for index in 1..<counts.count {
                XCTAssertGreaterThanOrEqual(
                    counts[index], counts[index - 1],
                    "\(archetype) lost a stalk at step \(index)"
                )
            }
            XCTAssertGreaterThan(counts.last ?? 0, 2, "\(archetype) never divided")

            let steps = (1..<reaches.count).map { reaches[$0] - reaches[$0 - 1] }
            let growing = steps.filter { $0 > 1e-6 }
            let typical = growing.reduce(0, +) / Float(growing.count)
            let worst = steps.max() ?? 0

            // The largest single step is the moment the stalks first exist,
            // and it should be of a piece with the growth either side of it.
            XCTAssertLessThan(
                worst, typical * 3,
                "\(archetype)'s head jumped \(worst)m against a typical \(typical)m"
            )
            // And whatever that step is, it is a fraction of a percent of the
            // plant, which is the check that survives somebody retuning the
            // growth curve underneath it.
            XCTAssertLessThan(
                worst, Float(plant.stem.height) * 0.01,
                "\(archetype) arrives \(worst)m long on a \(plant.stem.height)m plant"
            )
        }
    }

    // MARK: - Solitary

    /// Fewer blooms is what buys the size, so the plants cost the same.
    func testASolitaryPlantSpendsItsWholeBudgetOnOneFlower() {
        for archetype in [Archetype.poppy, .orchid, .lotus, .thistle] {
            let plant = genome(growing: archetype)
            XCTAssertEqual(plant.branching.inflorescence, .solitary, "\(archetype)")
            XCTAssertFalse(plant.bloom.atNodes, "\(archetype) blooms up its stem")
            XCTAssertGreaterThan(plant.branching.bloomScale, 1.5, "\(archetype)")
        }
        for archetype in [Archetype.spire, .star, .bell, .vine, .succulent, .fern] {
            XCTAssertEqual(genome(growing: archetype).branching.bloomScale, 1, "\(archetype)")
        }
    }

    /// Six of the twelve got shorter, because a plant with somewhere else to
    /// put its growth stops putting it all upward.
    func testTheFormsThatBranchOrBloomOnceAreShorterThanTheTowers() {
        for archetype in [Archetype.poppy, .orchid, .lotus, .thistle, .umbel] {
            let profile = ArchetypeProfile.profile(for: archetype)
            XCTAssertLessThan(profile.heightScale, 1.0, "\(archetype) is still a tower")
        }
        XCTAssertGreaterThan(ArchetypeProfile.profile(for: .spire).heightScale, 1.2)
        XCTAssertGreaterThan(ArchetypeProfile.profile(for: .vine).heightScale, 1.2)
    }

    // MARK: - Nothing new has to cross

    /// A hybrid's form comes free with the archetype its own seed draws.
    ///
    /// `Pollination` needs no change for any of this, and this is the test that
    /// says so: both sides of an exchange reach the same form from the same
    /// child seed, having sent each other nothing but seeds.
    func testBothSidesOfAMeetingGrowTheSameForm() {
        for index in 0..<60 {
            let a = genome("meet-a-\(index)")
            let b = genome("meet-b-\(index)")
            let encounter = Pollination.encounterID(
                seedA: a.seed, seedB: b.seed,
                nonceA: Data("nonce-a-\(index)".utf8),
                nonceB: Data("nonce-b-\(index)".utf8)
            )
            let child = Pollination.cross(seedA: a.seed, seedB: b.seed, encounterID: encounter)

            let mine = Genome(seed: child, lineage: .crossed(
                parentA: a.seed, parentB: b.seed, encounterID: encounter))
            let theirs = Genome(seed: child, lineage: .crossed(
                parentA: b.seed, parentB: a.seed, encounterID: encounter))

            XCTAssertEqual(mine.branching, theirs.branching, "meeting \(index)")
        }
    }
}
