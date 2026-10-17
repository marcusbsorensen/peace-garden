import XCTest
import Foundation
@testable import SeedCore

/// Space flora: the plants a Zone C seed grows (`peacegarden.space.v1`).
///
/// What is held here is behaviour. What is held against a second implementation
/// is `SpaceFloraVectorTests`, which reads `tools/reference/space_flora_vectors.json`.
final class SpaceFloraTests: XCTestCase {

    // MARK: - Fixtures

    /// 16 bytes, the same on every host.
    static func r(_ index: Int) -> Data {
        Data(sha256([Data("space-test-r-\(index)".utf8)]).prefix(16))
    }

    static func mark(_ index: Int) -> Data {
        Data(sha256([Data("space-test-mark-\(index)".utf8)]).prefix(16))
    }

    static func seed(_ label: String) -> SeedID {
        SeedMint.mint(fromEntropy: Data(label.utf8))
    }

    static func found(_ index: Int) -> SeedID {
        SeedID(bytes: r(index) + mark(index))!
    }

    static func plants(of kind: SpaceKind, count: Int) -> [SpaceFlora] {
        var plants: [SpaceFlora] = []
        var index = 0
        while plants.count < count {
            let plant = SpaceFlora.draw(r: r(index))!
            if plant.kind == kind { plants.append(plant) }
            index += 1
            precondition(index < 20_000, "no \(kind) found")
        }
        return plants
    }

    /// A moment in a plant's life, in seconds from its birth.
    static func state(_ genome: Genome, days: Double) -> GrowthModel.State {
        GrowthModel(genome: genome).state(
            birth: PortVectorTests.birth,
            now: PortVectorTests.birth.addingTimeInterval(days * 86_400),
            calendar: PortVectorTests.utc
        )
    }

    /// Fully grown, and through its first full flowering cycle.
    static func mature(_ genome: Genome) -> GrowthModel.State {
        state(genome, days: genome.tempo.daysToBloom + genome.tempo.bloomDays + 45)
    }

    // MARK: - The kinds

    func testTheFiveKindsAreFrozenInOrder() {
        XCTAssertEqual(SpaceKind.allCases.map(\.rawValue), ["cluster", "comet", "orbit", "crystal", "nebula"])
        XCTAssertEqual(SpaceKind.allCases.map(\.letter), ["A", "B", "C", "D", "E"])
        XCTAssertEqual(
            SpaceKind.allCases.map(\.displayName),
            ["Star Cluster", "Comet Reed", "Orbit Vine", "Crystal Rosette", "Nebula Moss"]
        )
        XCTAssertEqual(SpaceKind.allCases.map(\.form), [.umbel, .reed, .vine, .succulent, .cushion])
        XCTAssertEqual(SeedDomain.space, "peacegarden.space.v1")
    }

    func testTheQuotationsAndTheirSourcesAreExactlyAsChosen() {
        let expected: [SpaceKind: (String, String)] = [
            .cluster: (
                "A mass of innumerable stars planted together in clusters.",
                "Galileo Galilei, Sidereus Nuncius (1610), tr. Edward Stafford Carlos, "
                    + "The Sidereal Messenger (1880)"
            ),
            .comet: (
                "I'll tell you how the sun rose, \u{2014} / A ribbon at a time.",
                "Emily Dickinson, \"A Day\", Poems (First Series, 1890)"
            ),
            .orbit: ("Zero-g and I feel fine.", "John Glenn, Friendship 7, 20 February 1962"),
            .crystal: ("It has a stark beauty all its own.", "Neil Armstrong, Apollo 11, 20 July 1969"),
            .nebula: (
                "they look like little stars. A whole shower of them coming by.",
                "John Glenn, Friendship 7, 20 February 1962"
            )
        ]
        for kind in SpaceKind.allCases {
            XCTAssertEqual(kind.quotation, expected[kind]?.0, "\(kind) quotation")
            XCTAssertEqual(kind.source, expected[kind]?.1, "\(kind) source")
        }
    }

    func testEveryKindIsReachable() {
        var counts: [SpaceKind: Int] = [:]
        for index in 0..<1_000 {
            counts[SpaceFlora.draw(r: Self.r(index))!.kind, default: 0] += 1
        }
        for kind in SpaceKind.allCases {
            // A fifth each, give or take: the kind is sliced from one uniform draw.
            XCTAssertGreaterThan(counts[kind] ?? 0, 140, "\(kind) is hardly ever drawn: \(counts)")
            XCTAssertLessThan(counts[kind] ?? 0, 260, "\(kind) is drawn too often: \(counts)")
        }
    }

    func testTheKindsHaveFlowersOfTheirOwnColourAndLeavesOfTheGardens() {
        // Hue bands in degrees, which are Marcus's: lemon, ice blue, violet,
        // cobalt, pink; and the garden's sage to moss for every leaf.
        let bands: [SpaceKind: ClosedRange<Double>] = [
            .cluster: 56...66, .comet: 196...207, .orbit: 266...288, .crystal: 223...245, .nebula: 304...324
        ]
        for kind in SpaceKind.allCases {
            let hue = SpaceFloraProfile.profile(for: kind).petalHue
            XCTAssertGreaterThanOrEqual(hue.lowerBound * 360, bands[kind]!.lowerBound - 0.5, "\(kind)")
            XCTAssertLessThanOrEqual(hue.upperBound * 360, bands[kind]!.upperBound + 0.5, "\(kind)")
            let leaf = SpaceFloraProfile.profile(for: kind).leafHue
            XCTAssertGreaterThanOrEqual(leaf.lowerBound * 360, 97 - 0.5, "\(kind) leaves")
            XCTAssertLessThanOrEqual(leaf.upperBound * 360, 119 + 0.5, "\(kind) leaves")
        }
        // No two kinds' flowers are within ten degrees of one another.
        let ordered = SpaceKind.allCases.map { SpaceFloraProfile.profile(for: $0).petalHue }
            .sorted { $0.lowerBound < $1.lowerBound }
        for (low, high) in zip(ordered, ordered.dropFirst()) {
            XCTAssertGreaterThan((high.lowerBound - low.upperBound) * 360, 10)
        }
    }

    // MARK: - A draw from r

    func testADrawFromRAndMarkIsADrawFromR() {
        for index in 0..<60 {
            let r = Self.r(index)
            let plain = SpaceFlora.draw(r: r)!
            let marked = SpaceFlora.draw(seed: Self.found(index))
            XCTAssertTrue(plain == marked, "r and r‖mark draw different plants at \(index)")
            // Whatever the mark is.
            let other = SpaceFlora.draw(seed: SeedID(bytes: r + Data(repeating: 0xA5, count: 16))!)
            XCTAssertTrue(plain == other, "the mark moved the plant at \(index)")
        }
        // And the geometry is the same vertex for vertex, because the mesh's own
        // incidental jitter is keyed by the genome's seed, which `r` alone derives.
        for index in 0..<8 {
            let plain = SpaceFlora.draw(r: Self.r(index))!.genome
            let marked = SpaceFlora.draw(seed: Self.found(index)).genome
            let state = Self.mature(plain)
            let a = PlantBuilder(genome: plain).mesh(growth: state)
            let b = PlantBuilder(genome: marked).mesh(growth: state)
            XCTAssertEqual(a.vertexCount, b.vertexCount)
            XCTAssertTrue(zip(a.parts, b.parts).allSatisfy { $0.positions == $1.positions && $0.indices == $1.indices })
        }
    }

    func testOnlySixteenBytesAreASpaceSeed() {
        XCTAssertNil(SpaceFlora.draw(r: Data()))
        XCTAssertNil(SpaceFlora.draw(r: Data(repeating: 1, count: 15)))
        XCTAssertNil(SpaceFlora.draw(r: Data(repeating: 1, count: 17)))
        XCTAssertNil(SpaceFlora.draw(r: Data(repeating: 1, count: 32)))
        XCTAssertNotNil(SpaceFlora.draw(r: Data(repeating: 1, count: 16)))
    }

    func testADrawIsAPureFunctionOfR() {
        for index in 0..<20 {
            XCTAssertTrue(SpaceFlora.draw(r: Self.r(index)) == SpaceFlora.draw(r: Self.r(index)))
        }
        XCTAssertFalse(SpaceFlora.draw(r: Self.r(1)) == SpaceFlora.draw(r: Self.r(2)))
    }

    func testTheDrawIsNotTheGardens() {
        // The same 16 bytes, padded to a seed, grow an earthly plant of their own
        // under `peacegarden.trait.v1`; the space draw reads the space domain, so
        // the two share nothing but the bytes.
        for index in 0..<10 {
            let seed = Self.found(index)
            let earthly = Genome(seed: seed)
            let space = SpaceFlora.draw(seed: seed).genome
            XCTAssertNotEqual(earthly.seed, space.seed)
            XCTAssertNotEqual(earthly.stem.height, space.stem.height)
        }
    }

    // MARK: - What each kind is

    func testEachKindIsGrownFromItsOwnForm() {
        for kind in SpaceKind.allCases {
            for plant in Self.plants(of: kind, count: 25) {
                let genome = plant.genome
                XCTAssertEqual(genome.form.archetype, kind.form, "\(kind)")
                XCTAssertEqual(genome.name.full, kind.displayName)
                XCTAssertEqual(plant.name, kind.displayName)
                XCTAssertEqual(genome.bloom.crumple, 0)
                XCTAssertEqual(genome.bloom.notch, 0)
                XCTAssertEqual(genome.foliage.serration, 0, "no space flora is toothed")
                XCTAssertFalse(genome.habit.pads, "no kind has pads")
                XCTAssertEqual(genome.habit.pinnae, 0)
                XCTAssertEqual(genome.palette.marbling, .none)
                XCTAssertNil(genome.palette.picotee)
                XCTAssertEqual(genome.palette.variegation, .none)
                XCTAssertFalse(genome.tempo.opensByDay, "deep space has no day")
                XCTAssertTrue(
                    [ColourScheme.monochrome, .analogous, .ombre].contains(genome.palette.scheme),
                    "\(genome.palette.scheme) is not a calm scheme"
                )
                switch kind {
                case .cluster:
                    XCTAssertEqual(genome.branching.inflorescence, .head)
                    XCTAssertTrue((5...9).contains(genome.branching.count))
                    XCTAssertFalse(genome.habit.rosette)
                    XCTAssertEqual(genome.bloom.outline, .pointed)
                    XCTAssertEqual(genome.bloom.calyx, .lid)
                case .comet:
                    XCTAssertEqual(genome.branching.inflorescence, .solitary)
                    XCTAssertTrue(genome.habit.strap)
                    XCTAssertTrue(genome.habit.rosette)
                    XCTAssertGreaterThanOrEqual(genome.habit.sweep, 0.55)
                    XCTAssertLessThanOrEqual(genome.habit.sweep, 0.85)
                    XCTAssertGreaterThanOrEqual(abs(genome.stem.lean), 0.45, "an arched culm")
                case .orbit:
                    XCTAssertEqual(genome.branching.inflorescence, .raceme)
                    XCTAssertTrue(genome.bloom.atNodes)
                    XCTAssertTrue(genome.bloom.opensFromBelow)
                    XCTAssertGreaterThanOrEqual(genome.habit.orbit, 1.5)
                    XCTAssertLessThanOrEqual(genome.habit.orbit, 3.0)
                    XCTAssertEqual(genome.bloom.sepals, .appressed)
                case .crystal:
                    XCTAssertTrue(genome.habit.rosette)
                    XCTAssertEqual(genome.habit.fleshiness, 1)
                    XCTAssertFalse(genome.habit.strap)
                    XCTAssertFalse(genome.habit.cushion)
                    XCTAssertEqual(genome.bloom.outline, .pointed)
                case .nebula:
                    XCTAssertTrue(genome.habit.cushion)
                    XCTAssertTrue(genome.habit.rosette)
                    XCTAssertNotNil(genome.habit.cushionWidth)
                    XCTAssertGreaterThanOrEqual(genome.habit.flowerShare, 0.25)
                    XCTAssertLessThanOrEqual(genome.habit.flowerShare, 0.45)
                }
                if kind != .comet { XCTAssertEqual(genome.habit.sweep, 0, "\(kind)") }
                if kind != .orbit { XCTAssertEqual(genome.habit.orbit, 0, "\(kind)") }
                if kind != .nebula { XCTAssertNil(genome.habit.cushionWidth, "\(kind)") }
            }
        }
    }

    /// Every drawn trait is inside the kind's own range, and the leaves and
    /// stems are inside the garden's sage to moss.
    static func stray(_ plant: SpaceFlora) -> [String] {
        let g = plant.genome
        let p = SpaceFloraProfile.profile(for: plant.kind)
        let slack = 1e-9
        var out: [String] = []
        func within(_ name: String, _ value: Double, _ range: ClosedRange<Double>) {
            if value < range.lowerBound - slack || value > range.upperBound + slack {
                out.append("\(name) \(value) outside \(range)")
            }
        }
        func within(_ name: String, _ value: Int, _ range: ClosedRange<Int>) {
            if !range.contains(value) { out.append("\(name) \(value) outside \(range)") }
        }

        within("vigour", g.form.vigour, p.vigour)
        within("branch.count", g.branching.count, p.branchCount)
        within("branch.spread", g.branching.spread, p.branchSpread)
        within("branch.angle", g.branching.angle, p.branchAngle)
        // A rosette that does not flower sends up a stub and no stalk.
        let drawnHeight = p.rosette && !g.bloom.present
            ? (g.stem.height - 0.08) / 0.25 / g.form.vigour
            : g.stem.height / g.form.vigour
        within("height", drawnHeight, p.height)
        within("baseRadius", g.stem.baseRadius, p.baseRadius)
        within("taper", g.stem.taper, p.taper)
        within("|lean|", abs(g.stem.lean), p.lean)
        within("sway", g.stem.sway, p.sway)
        within("|twist|", abs(g.stem.twist), p.twist)
        within("nodeCount", g.stem.nodeCount, p.nodeCount)
        within("sides", g.stem.sides, 6...9)

        within("leavesPerNode", g.foliage.leavesPerNode, p.leavesPerNode)
        within("leaf length", g.foliage.length / g.form.vigour, p.leafLength)
        within("leaf widthRatio", g.foliage.widthRatio, p.leafWidthRatio)
        within("droop", g.foliage.droop, p.droop)
        within("fold", g.foliage.fold, p.fold)
        within("pitch", g.foliage.pitch, p.pitch)
        within("veinCount", g.foliage.veinCount, p.veinCount)
        within("tipSharpness", g.foliage.tipSharpness, p.leafTip)
        within("crownPitch", g.habit.crownPitch, p.crownPitch)
        within("sweep", g.habit.sweep, p.sweep)
        within("orbit", g.habit.orbit, p.orbit)
        if p.cushion {
            within("cushionWidth", g.habit.cushionWidth ?? -1, p.cushionWidth)
            within("flowerShare", g.habit.flowerShare, p.flowerShare)
        }

        // The flower: a plan of six or more, so the variant never makes four.
        let plan = g.form.merosity == .few ? p.petals.few : p.petals.many
        within("petalCount", g.bloom.petalCount, (plan - 1)...(plan + 1))
        if g.bloom.petalCount < 5 { out.append("a flower of \(g.bloom.petalCount) petals reads as a cross") }
        within("layers", g.bloom.layers, p.layers)
        within("petal length", g.bloom.length, p.petalLength)
        within("petal widthRatio", g.bloom.widthRatio, p.petalWidthRatio)
        within("curl", g.bloom.curl, p.curl)
        within("petal twist", g.bloom.twist, p.petalTwist)
        within("headPitch", g.bloom.headPitch, p.headPitch)
        within("centreRadius", g.bloom.centreRadius, p.centreRadius)
        within("stamens", g.bloom.stamenCount, p.stamens)

        within("tempo.germinationHours", g.tempo.germinationHours, 6...24)
        within("tempo.seedlingDays", g.tempo.seedlingDays, 1...3)
        within("tempo.vegetativeDays", g.tempo.vegetativeDays, 3...8)
        within("tempo.buddingDays", g.tempo.buddingDays, 2...5)
        within("tempo.bloomDays", g.tempo.bloomDays, 10...30)

        // Colour. The petals' base is the kind's hue; the tip may walk a few
        // degrees; the leaves and the stem are the garden's.
        let palette = g.palette
        within("petalBase.hue", palette.petalBase.hue, p.petalHue)
        within("petalBase.saturation", palette.petalBase.saturation, p.petalSaturation)
        within("petalBase.brightness", palette.petalBase.brightness / 0.82, p.petalBrightness)
        within("petalTip.hue", palette.petalTip.hue,
               (p.petalHue.lowerBound - 0.06)...(p.petalHue.upperBound + 0.06))
        within("leaf.hue", palette.leaf.hue, p.leafHue)
        within("leaf.saturation", palette.leaf.saturation, p.leafSaturation)
        within("leaf.brightness", palette.leaf.brightness, p.leafBrightness)
        within("stem.hue", palette.stem.hue, p.leafHue)
        within("leafVein.hue", palette.leafVein.hue, p.leafHue)
        let centreBand = SpaceFloraProfile.profile(for: plant.centreKind ?? plant.kind).petalHue
        within("centre.hue", palette.centre.hue, centreBand)
        within("glow", palette.glow, p.glow)
        return out
    }

    func testEveryTraitStaysInItsKindsRange() {
        for kind in SpaceKind.allCases {
            for plant in Self.plants(of: kind, count: 120) {
                let strays = Self.stray(plant)
                XCTAssertTrue(strays.isEmpty, "\(kind) \(plant.key.hexString): \(strays.prefix(3))")
            }
        }
    }

    func testAllFiveGrowIntoSoundMeshesAtEveryAge() {
        for kind in SpaceKind.allCases {
            for plant in Self.plants(of: kind, count: 8) {
                let genome = plant.genome
                let toBloom = genome.tempo.daysToBloom
                for days in [0.3, toBloom * 0.5, toBloom + genome.tempo.bloomDays * 0.4,
                             toBloom + genome.tempo.bloomDays + 45] {
                    let state = Self.state(genome, days: days)
                    let mesh = PlantBuilder(genome: genome).mesh(growth: state)
                    let label = "\(kind) \(plant.key.hexString) day \(days)"
                    XCTAssertGreaterThan(mesh.vertexCount, 0, label)
                    XCTAssertLessThan(mesh.vertexCount, 250_000, label)
                    for part in mesh.parts {
                        for position in part.positions {
                            XCTAssertTrue(position.x.isFinite && position.y.isFinite && position.z.isFinite, label)
                        }
                        for normal in part.normals {
                            XCTAssertTrue(normal.x.isFinite && normal.y.isFinite && normal.z.isFinite, label)
                        }
                        XCTAssertTrue(part.indices.allSatisfy { Int($0) < part.positions.count }, label)
                    }
                    let size = mesh.maxBounds - mesh.minBounds
                    XCTAssertLessThan(max(size.x, size.y, size.z), 4, "\(label) is \(size) across")
                }
            }
        }
    }

    // MARK: - The four traits the morphology gained

    func testEveryExistingPlantTakesTheDefaultsOfTheFourTraits() {
        for index in 0..<400 {
            let genome = Genome(seed: Self.seed("space-default-\(index)"))
            XCTAssertEqual(genome.habit.sweep, 0)
            XCTAssertEqual(genome.habit.orbit, 0)
            XCTAssertNil(genome.habit.cushionWidth)
            XCTAssertEqual(genome.habit.flowerShare, 0.45)
        }
        for index in 0..<100 {
            let a = Self.seed("space-default-a-\(index)"), b = Self.seed("space-default-b-\(index)")
            let encounter = Pollination.encounterID(
                seedA: a, seedB: b, nonceA: Self.r(index), nonceB: Self.mark(index)
            )
            let child = Pollination.cross(seedA: a, seedB: b, encounterID: encounter)
            let genome = Genome.hybrid(child: child, parentA: a, parentB: b, encounterID: encounter)
            XCTAssertEqual(genome.habit.sweep, 0)
            XCTAssertEqual(genome.habit.orbit, 0)
            XCTAssertNil(genome.habit.cushionWidth)
            XCTAssertEqual(genome.habit.flowerShare, 0.45)
        }
    }

    func testSweepStreamsTheCometsStrapsToItsLeanSide() {
        var leanedTo = 0, swept = 0
        for plant in Self.plants(of: .comet, count: 30) {
            let genome = plant.genome
            var habit = genome.habit
            habit.sweep = 0
            let plain = genome.replacing(habit: habit)
            let state = Self.mature(genome)
            func centroidX(_ g: Genome) -> Float {
                let leaves = PlantBuilder(genome: g).mesh(growth: state).parts.first { $0.role == .leaf }!
                return leaves.positions.reduce(0) { $0 + $1.x } / Float(leaves.positions.count)
            }
            let with = centroidX(genome), without = centroidX(plain)
            // A positive lean takes the stem toward -x; the straps follow it.
            let side: Float = genome.stem.lean > 0 ? -1 : 1
            if with * side > 0 { leanedTo += 1 }
            if abs(with) > abs(without) * 2 { swept += 1 }
        }
        XCTAssertEqual(leanedTo, 30, "every comet's straps should sweep to its lean side")
        XCTAssertGreaterThanOrEqual(swept, 28, "the sweep should gather the straps well past the spiral's own spread")
    }

    func testTheBearingPullGoesTheShortWayRound() {
        // A positive lean is -x, a bearing of pi; a negative one is +x, a bearing of 0.
        XCTAssertEqual(PlantBuilder.swept(0.2, share: 1, leaning: 0.5), .pi, accuracy: 1e-5)
        XCTAssertEqual(PlantBuilder.swept(6.0, share: 1, leaning: -0.5), 2 * .pi, accuracy: 1e-5)
        XCTAssertEqual(PlantBuilder.swept(2.0, share: 0.5, leaning: 0.5), 2.0 + (.pi - 2.0) * 0.5, accuracy: 1e-5)
        // Over the seam: 5.5 to 0 is a short way up through 2 pi, not 5.5 back down.
        XCTAssertEqual(PlantBuilder.swept(5.5, share: 1, leaning: -1), 2 * .pi, accuracy: 1e-5)
        XCTAssertEqual(PlantBuilder.swept(1.3, share: 0, leaning: 1), 1.3)
    }

    func testOrbitCarriesTheStemRoundItsAxisInLoops() {
        for plant in Self.plants(of: .orbit, count: 20) {
            let genome = plant.genome
            var habit = genome.habit
            habit.orbit = 0
            let straight = genome.replacing(habit: habit)
            let looped = SkeletonBuilder.stem(genome: genome, heightScale: 1).stem
            let line = SkeletonBuilder.stem(genome: straight, heightScale: 1).stem
            XCTAssertEqual(looped.count, line.count)

            let length = Float(genome.stem.height)
            var turned: Float = 0
            var previous: Float = 0
            for (a, b) in zip(looped, line) {
                let offset = a.position - b.position
                XCTAssertEqual(offset.y, 0, accuracy: 1e-5, "the loops are horizontal")
                // The loops open out of the foot over a fifth of the stem.
                let opening = Self.smoothstep(a.t / 0.2)
                let radius = hypot(offset.x, offset.z)
                XCTAssertEqual(radius, 0.16 * length * opening, accuracy: 1e-4 * max(1, length))
                if radius > 1e-3 {
                    var angle = atan2(offset.z, offset.x)
                    // Unwrapped, so the turns accumulate.
                    while angle - previous > .pi { angle -= 2 * .pi }
                    while angle - previous < -.pi { angle += 2 * .pi }
                    previous = angle
                    turned = angle
                }
            }
            // Foot to tip, `orbit` turns, to the sample before the first
            // that was too close to the axis to give a bearing.
            XCTAssertEqual(Double(turned) / (2 * .pi), genome.habit.orbit, accuracy: 0.1, "\(plant.key.hexString)")
        }
    }

    static func smoothstep(_ x: Float) -> Float {
        let t = min(1, max(0, x))
        return t * t * (3 - 2 * t)
    }

    func testTheNebulaIsTheWidthItSaysAndFlowersAsMuchAsItSays() {
        var shares: [Double] = []
        for plant in Self.plants(of: .nebula, count: 16) {
            let genome = plant.genome
            let width = genome.habit.cushionWidth!
            let state = Self.mature(genome)
            let mesh = PlantBuilder(genome: genome).mesh(growth: state)
            let across = Double(max(mesh.maxBounds.x - mesh.minBounds.x, mesh.maxBounds.z - mesh.minBounds.z))
            XCTAssertGreaterThan(across, width * 0.9, "the dome should be about \(width) across, not \(across)")
            XCTAssertLessThan(across, width * 1.25, "the dome should be about \(width) across, not \(across)")

            // The flowers: a centre dome of twelve vertices each. Every rosette
            // flowers when the share is one, so the plant against itself at one
            // gives the share it drew.
            var habit = genome.habit
            habit.flowerShare = 1
            let all = PlantBuilder(genome: genome.replacing(habit: habit)).mesh(growth: state)
            func flowers(_ mesh: PlantMesh) -> Int {
                (mesh.parts.first { $0.role == .centre }?.positions.count ?? 0) / 12
            }
            XCTAssertGreaterThan(flowers(all), 60)
            shares.append(Double(flowers(mesh)) / Double(flowers(all)) - genome.habit.flowerShare)
        }
        // Each plant is a sample of a couple of hundred coin flips, so a plant is
        // within a few per cent of its share and the sixteen are centred on it.
        XCTAssertLessThan(abs(shares.reduce(0, +) / Double(shares.count)), 0.02)
        XCTAssertTrue(shares.allSatisfy { abs($0) < 0.12 }, "\(shares)")
    }

    // MARK: - Crosses

    /// One Zone C cross, from both sides.
    struct ZoneCross {
        var own: SeedID
        var found: SeedID
        var ownNonce: Data
        var r: Data
        var finders: CrossPollinationResult
        var senders: CrossPollinationResult

        init(_ index: Int) {
            own = SpaceFloraTests.seed("space-own-\(index)")
            found = SpaceFloraTests.found(index)
            r = SpaceFloraTests.r(index)
            ownNonce = SpaceFloraTests.mark(index + 5_000)
            // The finder's phone: (own, found, its fresh nonce, the found seed's r).
            finders = CrossPollinationResult(
                localSeed: own, remoteSeed: found, localNonce: ownNonce, remoteNonce: r
            )
            // The sender's: (found, own, r, the finder's nonce it was sent).
            senders = CrossPollinationResult(
                localSeed: found, remoteSeed: own, localNonce: r, remoteNonce: ownNonce
            )
        }
    }

    func testBothSidesOfAZoneCCrossReachTheSameChildEncounterChecksumAndPlant() {
        for index in 0..<120 {
            let cross = ZoneCross(index)
            XCTAssertEqual(cross.finders.childSeed, cross.senders.childSeed)
            XCTAssertEqual(cross.finders.encounterID, cross.senders.encounterID)
            XCTAssertEqual(cross.finders.checksum, cross.senders.checksum)
            XCTAssertEqual(cross.finders.checksum.count, 8)
            XCTAssertEqual(cross.finders.parentA, cross.senders.parentA)
            XCTAssertEqual(cross.finders.parentB, cross.senders.parentB)
            XCTAssertEqual(cross.finders.parentA, min(cross.own, cross.found))
            XCTAssertEqual(Pollination.checksum(of: cross.finders.childSeed), cross.finders.checksum)
            XCTAssertTrue(
                cross.finders.spaceFlora == cross.senders.spaceFlora,
                "the two phones drew different plants at \(index)"
            )
            XCTAssertEqual(cross.finders.spaceFlora.genome.lineage, cross.finders.lineage)
            XCTAssertTrue(cross.finders.spaceFlora.genome.isHybrid)
        }
        // And the geometry, vertex for vertex.
        for index in 0..<6 {
            let cross = ZoneCross(index)
            let a = cross.finders.spaceFlora.genome, b = cross.senders.spaceFlora.genome
            let state = Self.mature(a)
            let meshA = PlantBuilder(genome: a).mesh(growth: state)
            let meshB = PlantBuilder(genome: b).mesh(growth: state)
            XCTAssertTrue(zip(meshA.parts, meshB.parts).allSatisfy { $0.positions == $1.positions })
        }
    }

    func testACrossIsCommutativeWhoeverHoldsWhichParent() {
        for index in 0..<200 {
            let a = Self.seed("space-cross-a-\(index)"), b = Self.found(index)
            let encounter = Pollination.encounterID(
                seedA: a, seedB: b, nonceA: Self.r(index), nonceB: Self.mark(index)
            )
            let child = Pollination.cross(seedA: a, seedB: b, encounterID: encounter)
            let forward = SpaceFloraHybrid.draw(child: child, parentA: a, parentB: b, encounterID: encounter)
            let backward = SpaceFloraHybrid.draw(child: child, parentA: b, parentB: a, encounterID: encounter)
            XCTAssertTrue(forward == backward, "the cross depends on who is first at \(index)")
        }
    }

    func testAParentIsReadByItsFirstSixteenBytes() {
        for index in 0..<30 {
            let a = Self.seed("space-front-\(index)")
            let b = Self.found(index)
            let encounter = Pollination.encounterID(
                seedA: a, seedB: b, nonceA: Self.r(index), nonceB: Self.mark(index)
            )
            let child = Pollination.cross(seedA: a, seedB: b, encounterID: encounter)
            let plain = SpaceFloraHybrid.draw(child: child, parentA: a, parentB: b, encounterID: encounter)

            // The same parents with anything after their first 16 bytes. The
            // sorted order can change, and must not matter to the plant.
            let altered = SeedID(bytes: a.bytes.prefix(16) + Data(repeating: 0xFF, count: 16))!
            let marked = SeedID(bytes: b.bytes.prefix(16) + Data(repeating: 0x00, count: 16))!
            let again = SpaceFloraHybrid.draw(child: child, parentA: altered, parentB: marked, encounterID: encounter)
            XCTAssertEqual(plain.kind, again.kind)
            XCTAssertEqual(plain.genome.form, again.genome.form)
            XCTAssertEqual(plain.genome.branching, again.genome.branching)
            XCTAssertEqual(plain.genome.stem, again.genome.stem)
            XCTAssertEqual(plain.genome.foliage, again.genome.foliage)
            XCTAssertEqual(plain.genome.habit, again.genome.habit)
            XCTAssertEqual(plain.genome.bloom, again.genome.bloom)
            XCTAssertEqual(plain.genome.palette, again.genome.palette)
            XCTAssertEqual(plain.genome.tempo, again.genome.tempo)
            XCTAssertEqual(plain.genome.seed, again.genome.seed)
        }
    }

    /// The ladder `GeneSource` has, over the space domain: 36 in 100 the first
    /// parent's draw, 36 the second's, 22 a blend, 6 its own.
    func testEveryNamedTraitInheritsOnTheThirtySixThirtySixTwentyTwoSixLadder() {
        var counts = (first: 0, second: 0, blend: 0, own: 0)
        let total = 12_000
        for index in 0..<total {
            let first = Self.r(index * 3), second = Self.r(index * 3 + 1), child = Self.r(index * 3 + 2)
            let genes = SpaceGenes.hybrid(child: child, first: first, second: second)
            let label = "space.stem.height"
            let value = genes.unit(label)
            let a = SpaceGenes.rawUnit(first, label), b = SpaceGenes.rawUnit(second, label)
            if value == a {
                counts.first += 1
            } else if value == b {
                counts.second += 1
            } else if value > min(a, b) && value < max(a, b) {
                counts.blend += 1
            } else {
                counts.own += 1
            }
        }
        func share(_ n: Int) -> Double { Double(n) / Double(total) }
        XCTAssertEqual(share(counts.first), 0.36, accuracy: 0.02)
        XCTAssertEqual(share(counts.second), 0.36, accuracy: 0.02)
        // A blend lands between the two; one in five-ish of the 6% do so too.
        XCTAssertEqual(share(counts.blend), 0.22 + 0.06 / 3, accuracy: 0.025)
        XCTAssertEqual(share(counts.own), 0.06 * 2 / 3, accuracy: 0.015)
    }

    func testTheKindIsInheritedOnTheSameLadderWithTheBlendAsACoin() {
        var tally = (first: 0, second: 0, neither: 0, total: 0)
        var reached = Set<SpaceKind>()
        for index in 0..<20_000 {
            let a = Self.r(index * 3), b = Self.r(index * 3 + 1), child = Self.r(index * 3 + 2)
            let kindA = SpaceFlora.kind(of: a), kindB = SpaceFlora.kind(of: b)
            // The very function the draw calls, so a plant need not be grown for each.
            let kind = SpaceFlora.inheritedKind(
                genes: SpaceGenes.hybrid(child: child, first: a, second: b),
                parentKinds: (kindA, kindB)
            )
            reached.insert(kind)
            guard kindA != kindB else { continue }
            tally.total += 1
            if kind == kindA { tally.first += 1 }
            else if kind == kindB { tally.second += 1 }
            else { tally.neither += 1 }
        }
        // 36 + half of 22 + a fifth of 6 each, and 3 fifths of 6 for a kind
        // neither parent was: about one cross in twenty-eight.
        let total = Double(tally.total)
        XCTAssertEqual(Double(tally.first + tally.second) / total, 0.964, accuracy: 0.01)
        XCTAssertEqual(Double(tally.neither) / total, 0.036, accuracy: 0.008)
        XCTAssertEqual(Double(tally.first) / Double(tally.first + tally.second), 0.5, accuracy: 0.03)
        XCTAssertEqual(reached, Set(SpaceKind.allCases), "a cross can grow any kind")

        // And a grown plant's kind is that draw.
        for index in 0..<150 {
            let a = Self.found(index), b = Self.seed("space-ladder-\(index)")
            let encounter = Pollination.encounterID(
                seedA: a, seedB: b, nonceA: Self.r(index), nonceB: Self.mark(index)
            )
            let child = Pollination.cross(seedA: a, seedB: b, encounterID: encounter)
            let flora = SpaceFloraHybrid.draw(child: child, parentA: a, parentB: b, encounterID: encounter)
            let sorted = a < b ? (a, b) : (b, a)
            let kinds = (SpaceFlora.kind(of: Data(sorted.0.bytes.prefix(16))),
                         SpaceFlora.kind(of: Data(sorted.1.bytes.prefix(16))))
            let genes = SpaceGenes.hybrid(child: child.bytes, first: sorted.0.bytes, second: sorted.1.bytes)
            XCTAssertEqual(flora.kind, SpaceFlora.inheritedKind(genes: genes, parentKinds: kinds))
        }
    }

    func testAChildsStructureAndRangesAreItsOwnKindsAndTheOtherParentsPointIsInTheCentre() {
        var twoKinds = 0, oneKind = 0
        for index in 0..<400 {
            let cross = ZoneCross(index)
            let plant = cross.finders.spaceFlora
            let p = SpaceFloraProfile.profile(for: plant.kind)
            let g = plant.genome

            // Structure is the child's kind's, never a parent's.
            XCTAssertEqual(g.habit.strap, p.strap)
            XCTAssertEqual(g.habit.cushion, p.cushion)
            XCTAssertEqual(g.habit.rosette, p.rosette)
            XCTAssertEqual(g.branching.inflorescence, p.inflorescence)
            XCTAssertEqual(g.bloom.calyx, p.calyx)
            XCTAssertEqual(g.bloom.outline, p.outline)
            XCTAssertEqual(g.form.archetype, plant.kind.form)

            // The traits read through the child's ranges.
            let strays = Self.stray(plant)
            XCTAssertTrue(strays.isEmpty, "cross \(index) (\(plant.kind)): \(strays.prefix(3))")

            // One small point of the other kind.
            let parentKinds = [SpaceFlora.kind(of: Data(cross.own.bytes.prefix(16))),
                               SpaceFlora.kind(of: Data(cross.found.bytes.prefix(16)))]
            if let centre = plant.centreKind {
                twoKinds += 1
                XCTAssertNotEqual(centre, plant.kind)
                XCTAssertTrue(parentKinds.contains(centre))
                XCTAssertTrue(
                    SpaceFloraProfile.profile(for: centre).petalHue.contains(g.palette.centre.hue),
                    "the centre should be \(centre)'s colour"
                )
            } else {
                oneKind += 1
                XCTAssertEqual(parentKinds.filter { $0 != plant.kind }.count, 0, "both parents are of the child's kind")
            }
            // And the petals are always the child's own.
            XCTAssertTrue(p.petalHue.contains(g.palette.petalBase.hue))
        }
        XCTAssertGreaterThan(twoKinds, 100)
        XCTAssertGreaterThan(oneKind, 30)
    }

    func testACrossRecordsItsLineage() {
        let cross = ZoneCross(7)
        let genome = cross.finders.spaceFlora.genome
        guard case let .crossed(parentA, parentB, encounterID) = genome.lineage else {
            return XCTFail("a cross should be crossed")
        }
        XCTAssertEqual(parentA, min(cross.own, cross.found))
        XCTAssertEqual(parentB, max(cross.own, cross.found))
        XCTAssertEqual(encounterID, cross.finders.encounterID)
        XCTAssertEqual(cross.finders.spaceFlora.key, Data(cross.finders.childSeed.bytes.prefix(16)))
    }
}
