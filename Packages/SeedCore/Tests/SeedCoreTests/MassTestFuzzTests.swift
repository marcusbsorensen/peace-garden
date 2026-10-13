import XCTest
@testable import SeedCore

/// **A hundred thousand random crosses** (mass test, 13 October 2026).
///
/// A population of minted seeds meets at random; each child joins the
/// population in place of a random member, so lineages run many crosses
/// deep. Every child is checked for the things a phone would fall over on or
/// show wrongly: a cross that depends on who knocked first, a genome that is
/// not a pure function of its seed, a trait outside its declared range or not
/// a number at all, a name that is empty, oddly spaced or oddly cased, a
/// growth state with a NaN in it. One child in a hundred is grown into a mesh
/// and its every vertex checked.
///
/// Skipped unless `PG_MASSTEST` is set. `PG_MASSTEST_CROSSES` sets the count
/// (100,000 unless said) and `PG_MASSTEST_FUZZ_OUT` a folder for
/// `fuzz-summary.json` and `fuzz-crosses.json` — a sample of crosses a second
/// implementation (`tools/masstest/app/check_crosses.py`) re-derives.
final class MassTestFuzzTests: XCTestCase {

    func testAHundredThousandRandomCrosses() throws {
        let environment = ProcessInfo.processInfo.environment
        guard environment["PG_MASSTEST"] != nil else { throw XCTSkip("PG_MASSTEST is not set") }
        let total = Int(environment["PG_MASSTEST_CROSSES"] ?? "") ?? 100_000
        let started = Date()

        var random = SplitMix64(seed: 0x6D61_7373_7465_7374)  // "masstest"
        func bytes(_ count: Int) -> Data { Data((0..<count).map { _ in UInt8(truncatingIfNeeded: random.next()) }) }

        var population = (0..<128).map { SeedMint.mint(fromEntropy: Data("masstest-founder-\($0)".utf8)) }
        var problems: [String] = []
        func problem(_ text: String) {
            if problems.count < 200 { problems.append(text) }
        }

        var fingerprint = Data()
        var names = Set<String>()
        var longest: [(String, Int)] = []
        var characters = Set<Character>()
        var archetypes: [String: Int] = [:]
        var stages: [String: Int] = [:]
        var sample: [[String: String]] = []
        var meshes = 0, vertices = 0, tallest: Float = 0
        var lineageDepth = [SeedID: Int]()
        var deepest = 0

        for index in 0..<total {
            let a = population[Int(random.next() % UInt64(population.count))]
            var b = population[Int(random.next() % UInt64(population.count))]
            if a == b { b = population[(population.firstIndex(of: a)! + 1) % population.count] }
            let nonceA = bytes(16), nonceB = bytes(16)

            // Who knocked first must not matter.
            let encounter = Pollination.encounterID(seedA: a, seedB: b, nonceA: nonceA, nonceB: nonceB)
            let mirrored = Pollination.encounterID(seedA: b, seedB: a, nonceA: nonceB, nonceB: nonceA)
            if encounter != mirrored { problem("#\(index): encounter depends on order") }
            let child = Pollination.cross(seedA: a, seedB: b, encounterID: encounter)
            if child != Pollination.cross(seedA: b, seedB: a, encounterID: encounter) {
                problem("#\(index): cross depends on order")
            }

            let genome = Genome.hybrid(child: child, parentA: a, parentB: b, encounterID: encounter)
            if index % 10 == 0,
               genome != Genome.hybrid(child: child, parentA: b, parentB: a, encounterID: encounter) {
                problem("#\(index): genome is not a pure function of its seed and parents")
            }
            check(genome, index: index, problem: problem)

            // The name.
            let name = genome.name
            names.insert(name.full)
            characters.formUnion(name.full)
            if name.genus.isEmpty || name.epithet.isEmpty { problem("#\(index): empty name '\(name.full)'") }
            if name.full.contains("  ") || name.full.hasPrefix(" ") || name.full.hasSuffix(" ") {
                problem("#\(index): badly spaced name '\(name.full)'")
            }
            if name.genus.first.map({ !$0.isUppercase }) ?? true { problem("#\(index): genus not capitalised '\(name.full)'") }
            if name.epithet.contains(where: { $0.isUppercase }) { problem("#\(index): epithet has capitals '\(name.full)'") }
            if name.full.unicodeScalars.contains(where: { $0.properties.generalCategory == .control }) {
                problem("#\(index): control character in name")
            }
            longest.append((name.full, name.full.count))
            if longest.count > 400 {
                longest.sort { $0.1 > $1.1 }
                longest.removeLast(longest.count - 60)
            }
            archetypes[genome.form.archetype.rawValue, default: 0] += 1

            // Growing it, at any age from a seed in the ground to a year and a
            // half.
            let birth = Date(timeIntervalSince1970: 1_790_000_000)
            let age = Double(random.next() % 560) * 86_400 + Double(random.next() % 86_400)
            let state = GrowthModel(genome: genome).state(birth: birth, now: birth.addingTimeInterval(age))
            stages[state.stage.rawValue, default: 0] += 1
            for (label, value) in [("overall", state.overall), ("stageProgress", state.stageProgress),
                                   ("heightScale", state.heightScale), ("leafUnfurl", state.leafUnfurl),
                                   ("budSwell", state.budSwell), ("bloomOpen", state.bloomOpen),
                                   ("flush", state.flush), ("flushDepth", state.flushDepth)] {
                if !value.isFinite { problem("#\(index): growth.\(label) = \(value)") }
                else if value < -1e-9 || value > 1 + 1e-9, label != "heightScale" {
                    problem("#\(index): growth.\(label) = \(value) outside 0...1")
                }
            }

            // One in a hundred grown into the mesh the app draws.
            if index % 100 == 0 {
                let mesh = PlantBuilder(genome: genome).mesh(growth: state)
                meshes += 1
                vertices += mesh.vertexCount
                tallest = max(tallest, mesh.height)
                if mesh.vertexCount == 0 { problem("#\(index): empty mesh") }
                for part in mesh.parts {
                    if part.positions.contains(where: { !($0.x.isFinite && $0.y.isFinite && $0.z.isFinite) }) {
                        problem("#\(index): non-finite vertex in \(part.role)")
                        break
                    }
                    if part.indices.contains(where: { Int($0) >= part.positions.count }) {
                        problem("#\(index): index out of range in \(part.role)")
                        break
                    }
                }
                if mesh.height > 4 { problem("#\(index): mesh \(mesh.height) m tall") }
            }

            // Deterministic across runs: fold everything shown into one hash.
            fingerprint = seedDigest("masstest.fingerprint", fingerprint, child.bytes, Data(name.full.utf8),
                                     Data(String(format: "%.9f", genome.stem.height).utf8))

            if sample.count < 500, index % 200 == 0 {
                sample.append(["a": a.hex, "b": b.hex, "nonceA": nonceA.hexString, "nonceB": nonceB.hexString,
                               "encounter": encounter.hexString, "child": child.hex])
            }

            let depth = max(lineageDepth[a] ?? 0, lineageDepth[b] ?? 0) + 1
            lineageDepth[child] = depth
            deepest = max(deepest, depth)
            population[Int(random.next() % UInt64(population.count))] = child
            if lineageDepth.count > 20_000 {
                let alive = Set(population)
                lineageDepth = lineageDepth.filter { alive.contains($0.key) }
            }
        }

        longest.sort { $0.1 > $1.1 }
        let seconds = Date().timeIntervalSince(started)
        let summary: [String: Any] = [
            "crosses": total,
            "seconds": seconds,
            "problems": problems,
            "distinctNames": names.count,
            "longestNames": longest.prefix(40).map(\.0),
            "nameCharacters": String(characters.sorted()),
            "archetypes": archetypes,
            "stages": stages,
            "meshes": meshes,
            "meanVertices": meshes > 0 ? vertices / meshes : 0,
            "tallestMeshMetres": tallest,
            "deepestLineage": deepest,
            "fingerprint": fingerprint.hexString,
        ]
        if let folder = environment["PG_MASSTEST_FUZZ_OUT"], !folder.isEmpty {
            let url = URL(fileURLWithPath: folder)
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            try JSONSerialization.data(withJSONObject: summary, options: [.prettyPrinted, .sortedKeys])
                .write(to: url.appendingPathComponent("fuzz-summary.json"))
            try JSONSerialization.data(withJSONObject: sample, options: [.prettyPrinted])
                .write(to: url.appendingPathComponent("fuzz-crosses.json"))
        }
        print("mass test fuzz: \(total) crosses in \(Int(seconds)) s, \(problems.count) problems, fingerprint \(fingerprint.hexString.prefix(16))")
        XCTAssertTrue(problems.isEmpty, problems.prefix(20).joined(separator: "\n"))
    }

    /// Every trait against the range it is declared in, and every number in
    /// the genome a number.
    private func check(_ genome: Genome, index: Int, problem: (String) -> Void) {
        func expect(_ ok: Bool, _ what: @autoclosure () -> String) {
            if !ok { problem("#\(index) \(genome.form.archetype): \(what())") }
        }
        expect((3...40).contains(genome.bloom.petalCount), "petalCount \(genome.bloom.petalCount)")
        expect((1...20).contains(genome.stem.nodeCount), "nodeCount \(genome.stem.nodeCount)")
        expect((6...9).contains(genome.stem.sides), "sides \(genome.stem.sides)")
        expect(genome.stem.height > (genome.habit.cushion ? 0.04 : 0.06) && genome.stem.height < 3.0,
               "height \(genome.stem.height)")
        expect(genome.stem.baseRadius > 0, "baseRadius \(genome.stem.baseRadius)")
        expect((1...3).contains(genome.bloom.layers), "layers \(genome.bloom.layers)")
        expect((-1.0...1.0).contains(genome.bloom.curl), "curl \(genome.bloom.curl)")
        expect((0...1.9).contains(genome.bloom.headPitch), "headPitch \(genome.bloom.headPitch)")
        expect((1...3).contains(genome.foliage.leavesPerNode), "leavesPerNode \(genome.foliage.leavesPerNode)")
        expect((3...17).contains(genome.foliage.teeth), "teeth \(genome.foliage.teeth)")
        expect((2...9).contains(genome.foliage.veinCount), "veinCount \(genome.foliage.veinCount)")
        expect((0...9).contains(genome.bloom.stamenCount), "stamenCount \(genome.bloom.stamenCount)")
        expect(genome.bloom.sepalCount == 0 || (3...6).contains(genome.bloom.sepalCount), "sepalCount \(genome.bloom.sepalCount)")
        expect((3...7).contains(genome.branching.count), "branch count \(genome.branching.count)")
        expect((0...1).contains(genome.branching.spread), "branch spread \(genome.branching.spread)")
        expect((3...20).contains(genome.tempo.germinationHours), "germinationHours \(genome.tempo.germinationHours)")
        expect(genome.tempo.daysToBloom > 0 && genome.tempo.daysToBloom < 60, "daysToBloom \(genome.tempo.daysToBloom)")

        let palette = genome.palette
        var colours = [palette.petalBase, palette.petalTip, palette.petalThroat, palette.petalVein,
                       palette.marble, palette.leaf, palette.leafAccent, palette.leafVein,
                       palette.stem, palette.centre]
        if let picotee = palette.picotee { colours.append(picotee) }
        for colour in colours {
            expect((0...1).contains(colour.hue) && (0...1).contains(colour.saturation)
                   && (0...1).contains(colour.brightness),
                   "colour \(colour.hue), \(colour.saturation), \(colour.brightness)")
        }

        // Every Double anywhere in the genome, by reflection: a NaN draws as
        // nothing and an infinity as a crash further down.
        var bad: [String] = []
        func walk(_ value: Any, _ path: String) {
            if let d = value as? Double { if !d.isFinite { bad.append("\(path)=\(d)") }; return }
            if let f = value as? Float { if !f.isFinite { bad.append("\(path)=\(f)") }; return }
            if value is String || value is Int || value is Bool || value is SeedID || value is Data { return }
            for child in Mirror(reflecting: value).children {
                walk(child.value, path + "." + (child.label ?? "?"))
            }
        }
        if index % 4 == 0 { walk(genome, "genome") }
        expect(bad.isEmpty, "not a number: \(bad.prefix(3).joined(separator: ", "))")
    }
}

private extension Data {
    var hexString: String { map { String(format: "%02x", $0) }.joined() }
}
