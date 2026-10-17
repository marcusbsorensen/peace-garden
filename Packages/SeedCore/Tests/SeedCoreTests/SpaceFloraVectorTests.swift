import XCTest
import Foundation
@testable import SeedCore

/// Holds `tools/reference/space_flora_vectors.json` to what this host computes.
///
/// **The file is the second implementation's, not this one's.**
/// `tools/reference/space_flora_reference.py` draws the same plants from the same
/// bytes using nothing but SHA-256, and writes the file; this test regenerates
/// every row from the seeds and compares. It runs on macOS, on Linux and inside
/// WebAssembly, so Swift, Python and the browser build all have to agree, and
/// Autonaut holds itself to the same file. Re-recording is the Python's job:
///
/// ```
/// python3 tools/reference/space_flora_reference.py --write
/// ```
///
/// **The inputs are re-derived here, not read.** The file says which seeds it
/// used (`series`), and this test walks the same fixed series itself: three
/// plants of each kind in the order the series reached them, and the crosses whose
/// `r`, mark, own seed and nonce come from the series index. A row whose recorded
/// inputs are not what the series gives fails before any plant is drawn.
///
/// **The tolerance is `VectorFile.power`**, the one that file already names for a
/// number that is arithmetic and nothing else. Every trait here is `+ - * /` over
/// hashed units, with no `sin`, `cos` or `pow`, so the three hosts agree to the
/// last bit and a trillionth is room for a JSON round trip, not for drift. Names,
/// counts and hex are exact.
final class SpaceFloraVectorTests: XCTestCase {
    typealias Value = VectorFile.Value

    static var vectorsURL: URL {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { url.deleteLastPathComponent() }   // …/Tests/SeedCoreTests/<this>
        return url.appendingPathComponent("tools/reference/space_flora_vectors.json")
    }

    // MARK: - The series

    static func bytes(_ label: String, _ index: Int, count: Int) -> Data {
        Data(sha256([Data("peace-garden-space-vector-\(label)-\(index)".utf8)]).prefix(count))
    }

    static func r(_ index: Int) -> Data { bytes("r", index, count: 16) }
    static func mark(_ index: Int) -> Data { bytes("mark", index, count: 16) }
    static func own(_ index: Int) -> Data { bytes("own", index, count: 32) }
    static func nonce(_ index: Int) -> Data { bytes("nonce", index, count: 16) }

    // MARK: - Traits as the file names them

    static func number(_ value: Double) -> Value { .number(value) }
    static func number(_ value: Int) -> Value { .number(Double(value)) }
    static func hsb(_ colour: HSB) -> Value {
        .list([.number(colour.hue), .number(colour.saturation), .number(colour.brightness)])
    }
    static func hex64(_ value: UInt64) -> Value {
        let digits = String(value, radix: 16)
        return .text(String(repeating: "0", count: 16 - digits.count) + digits)
    }

    /// Every field the file names, flat and dotted, as `Genome` names them.
    static func traits(_ genome: Genome) -> [String: Value] {
        let g = genome
        var t: [String: Value] = [:]
        t["seed"] = .text(g.seed.hex)

        t["form.archetype"] = .text(g.form.archetype.rawValue)
        t["form.merosity"] = .text(g.form.merosity.rawValue)
        t["form.vigour"] = number(g.form.vigour)

        t["branching.inflorescence"] = .text(g.branching.inflorescence.rawValue)
        t["branching.count"] = number(g.branching.count)
        t["branching.spread"] = number(g.branching.spread)
        t["branching.angle"] = number(g.branching.angle)
        t["branching.bloomScale"] = number(g.branching.bloomScale)

        t["stem.height"] = number(g.stem.height)
        t["stem.baseRadius"] = number(g.stem.baseRadius)
        t["stem.taper"] = number(g.stem.taper)
        t["stem.lean"] = number(g.stem.lean)
        t["stem.sway"] = number(g.stem.sway)
        t["stem.twist"] = number(g.stem.twist)
        t["stem.nodeCount"] = number(g.stem.nodeCount)
        t["stem.sides"] = number(g.stem.sides)

        t["foliage.leavesPerNode"] = number(g.foliage.leavesPerNode)
        t["foliage.length"] = number(g.foliage.length)
        t["foliage.widthRatio"] = number(g.foliage.widthRatio)
        t["foliage.droop"] = number(g.foliage.droop)
        t["foliage.fold"] = number(g.foliage.fold)
        t["foliage.pitch"] = number(g.foliage.pitch)
        t["foliage.divergence"] = number(g.foliage.divergence)
        t["foliage.veinCount"] = number(g.foliage.veinCount)
        t["foliage.veinDepth"] = number(g.foliage.veinDepth)
        t["foliage.tipSharpness"] = number(g.foliage.tipSharpness)

        t["habit.rosette"] = .flag(g.habit.rosette)
        t["habit.crownCount"] = number(g.habit.crownCount)
        t["habit.crownLength"] = number(g.habit.crownLength)
        t["habit.crownPitch"] = number(g.habit.crownPitch)
        t["habit.crownTaper"] = number(g.habit.crownTaper)
        t["habit.crownRise"] = number(g.habit.crownRise)
        t["habit.fleshiness"] = number(g.habit.fleshiness)
        t["habit.stemLeafScale"] = number(g.habit.stemLeafScale)
        t["habit.strap"] = .flag(g.habit.strap)
        t["habit.cushion"] = .flag(g.habit.cushion)
        t["habit.sweep"] = number(g.habit.sweep)
        t["habit.orbit"] = number(g.habit.orbit)
        t["habit.cushionWidth"] = g.habit.cushionWidth.map { number($0) } ?? .nothing
        t["habit.flowerShare"] = number(g.habit.flowerShare)

        t["bloom.petalCount"] = number(g.bloom.petalCount)
        t["bloom.layers"] = number(g.bloom.layers)
        t["bloom.length"] = number(g.bloom.length)
        t["bloom.widthRatio"] = number(g.bloom.widthRatio)
        t["bloom.curl"] = number(g.bloom.curl)
        t["bloom.twist"] = number(g.bloom.twist)
        t["bloom.tipSharpness"] = number(g.bloom.tipSharpness)
        t["bloom.headPitch"] = number(g.bloom.headPitch)
        t["bloom.centreRadius"] = number(g.bloom.centreRadius)
        t["bloom.stamenCount"] = number(g.bloom.stamenCount)
        t["bloom.sepalCount"] = number(g.bloom.sepalCount)
        t["bloom.hasPistil"] = .flag(g.bloom.hasPistil)
        t["bloom.atNodes"] = .flag(g.bloom.atNodes)
        t["bloom.opensFromBelow"] = .flag(g.bloom.opensFromBelow)
        t["bloom.present"] = .flag(g.bloom.present)
        t["bloom.calyx"] = .text(g.bloom.calyx.rawValue)
        t["bloom.sepals"] = .text(g.bloom.sepals.rawValue)
        t["bloom.outline"] = .text(g.bloom.outline.rawValue)

        let p = g.palette
        t["palette.scheme"] = .text(p.scheme.rawValue)
        t["palette.petalBase"] = hsb(p.petalBase)
        t["palette.petalTip"] = hsb(p.petalTip)
        t["palette.petalThroat"] = hsb(p.petalThroat)
        t["palette.petalVein"] = hsb(p.petalVein)
        t["palette.veining"] = number(p.veining)
        t["palette.marbleSeed"] = hex64(p.marbleSeed)
        t["palette.leaf"] = hsb(p.leaf)
        t["palette.leafVein"] = hsb(p.leafVein)
        t["palette.leafVeining"] = number(p.leafVeining)
        t["palette.leafQuilting"] = number(p.leafQuilting)
        t["palette.stem"] = hsb(p.stem)
        t["palette.centre"] = hsb(p.centre)
        t["palette.glow"] = number(p.glow)
        t["palette.sheen"] = number(p.sheen)
        t["palette.speckleSeed"] = hex64(p.speckleSeed)

        t["tempo.germinationHours"] = number(g.tempo.germinationHours)
        t["tempo.seedlingDays"] = number(g.tempo.seedlingDays)
        t["tempo.vegetativeDays"] = number(g.tempo.vegetativeDays)
        t["tempo.buddingDays"] = number(g.tempo.buddingDays)
        t["tempo.bloomDays"] = number(g.tempo.bloomDays)
        t["tempo.opensByDay"] = .flag(g.tempo.opensByDay)
        return t
    }

    /// Every number the file records is arithmetic, and is held to `power`.
    static var tolerance: [String: Double] {
        var slack: [String: Double] = [:]
        for key in traits(SpaceFlora.draw(r: r(0))!.genome).keys { slack[key] = VectorFile.power }
        return slack
    }

    // MARK: - The file

    static func committed() throws -> [String: Value] {
        let text = try String(contentsOf: vectorsURL, encoding: .utf8)
        guard case let .object(fields)? = Value(json: text) else {
            throw NSError(domain: "SpaceFloraVectorTests", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "tools/reference/space_flora_vectors.json is not a JSON object"
            ])
        }
        return fields
    }

    static func list(_ fields: [String: Value], _ key: String) -> [[String: Value]] {
        guard case let .list(rows)? = fields[key] else { return [] }
        return rows.compactMap { if case let .object(row) = $0 { return row } else { return nil } }
    }

    static func text(_ row: [String: Value], _ key: String) -> String? {
        if case let .text(text)? = row[key] { return text }
        return nil
    }

    static func integer(_ row: [String: Value], _ key: String) -> Int? {
        if case let .number(number)? = row[key] { return Int(number) }
        return nil
    }

    static func agree(_ was: Value, _ now: Value, _ what: String,
                      file: StaticString = #filePath, line: UInt = #line) {
        var quarrels: [String] = []
        Value.compare(was, now, at: what, tolerant: tolerance, quarrels: &quarrels)
        XCTAssertTrue(quarrels.isEmpty, """
            \(what): the recorded vectors and what this host computes disagree about \
            \(quarrels.count) thing(s):
              \(quarrels.prefix(6).joined(separator: "\n  "))
            If the derivation changed on purpose, `peacegarden.space.v1` is pinned: add a v2 \
            rather than editing it. Otherwise one of the two implementations has moved.
            """, file: file, line: line)
    }

    // MARK: - The tests

    func testTheFileIsTheShapeThePythonWritesAndPinsTheDomain() throws {
        let file = try Self.committed()
        XCTAssertEqual(Set(file.keys), ["note", "domain", "kinds", "draws", "crosses"])
        XCTAssertEqual(Self.text(file, "domain"), SeedDomain.space)
        XCTAssertEqual(Self.text(file, "domain"), "peacegarden.space.v1")
    }

    func testTheKindsTableIsTheKindsData() throws {
        let rows = Self.list(try Self.committed(), "kinds")
        XCTAssertEqual(rows.count, SpaceKind.allCases.count)
        for (row, kind) in zip(rows, SpaceKind.allCases) {
            Self.agree(
                .object(row),
                .object([
                    "kind": .text(kind.rawValue),
                    "letter": .text(kind.letter),
                    "name": .text(kind.displayName),
                    "form": .text(kind.form.rawValue),
                    "quotation": .text(kind.quotation),
                    "source": .text(kind.source)
                ]),
                "kinds[\(kind.rawValue)]"
            )
        }
    }

    func testThePlantsDrawnFromRAreThePlantsThePythonDraws() throws {
        let rows = Self.list(try Self.committed(), "draws")

        // The series, walked again: three of each kind, in the order reached.
        var found: [SpaceKind: [Int]] = [:]
        var index = 0
        while found.count < SpaceKind.allCases.count || found.values.contains(where: { $0.count < 3 }) {
            let kind = SpaceFlora.draw(r: Self.r(index))!.kind
            if (found[kind]?.count ?? 0) < 3 { found[kind, default: []].append(index) }
            index += 1
            XCTAssertLessThan(index, 5_000, "a kind could not be reached")
            if index >= 5_000 { break }
        }
        let series = SpaceKind.allCases.flatMap { found[$0] ?? [] }
        XCTAssertEqual(rows.count, series.count)
        XCTAssertEqual(rows.compactMap { Self.integer($0, "series") }, series, "the series moved")

        for (row, seriesIndex) in zip(rows, series) {
            let r = Self.r(seriesIndex)
            let flora = SpaceFlora.draw(r: r)!
            XCTAssertEqual(Self.text(row, "r"), r.hexString)
            Self.agree(
                .object(row),
                .object([
                    "series": Self.number(seriesIndex),
                    "r": .text(r.hexString),
                    "kind": .text(flora.kind.rawValue),
                    "traits": .object(Self.traits(flora.genome))
                ]),
                "draws[\(seriesIndex)]"
            )
            // And what Peace Garden holds, `r ‖ mark`, draws the same plant.
            let held = SpaceFlora.draw(seed: SeedID(bytes: r + Self.mark(seriesIndex))!)
            XCTAssertTrue(held == flora, "r‖mark drew a different plant at \(seriesIndex)")
        }
    }

    func testTheZoneCCrossesAreTheCrossesThePythonDraws() throws {
        let rows = Self.list(try Self.committed(), "crosses")
        XCTAssertFalse(rows.isEmpty)
        var classes = Set<String>()

        for row in rows {
            let index = try XCTUnwrap(Self.integer(row, "series"))
            let r = Self.r(1_000 + index)
            let found = SeedID(bytes: r + Self.mark(index))!
            let own = SeedID(bytes: Self.own(index))!
            let nonce = Self.nonce(index)

            // The recorded inputs are what the series gives.
            XCTAssertEqual(Self.text(row, "found"), found.hex)
            XCTAssertEqual(Self.text(row, "own"), own.hex)
            XCTAssertEqual(Self.text(row, "ownNonce"), nonce.hexString)

            // The finder's phone and the sender's, as `CrossPollinationResult`
            // is called on each. The plant is drawn from either.
            let finders = CrossPollinationResult(localSeed: own, remoteSeed: found, localNonce: nonce, remoteNonce: r)
            let senders = CrossPollinationResult(localSeed: found, remoteSeed: own, localNonce: r, remoteNonce: nonce)
            XCTAssertEqual(finders.childSeed, senders.childSeed, "child at \(index)")
            XCTAssertEqual(finders.encounterID, senders.encounterID, "encounter at \(index)")
            XCTAssertEqual(finders.checksum, senders.checksum, "checksum at \(index)")
            XCTAssertTrue(finders.spaceFlora == senders.spaceFlora, "plant at \(index)")
            let flora = finders.spaceFlora

            // How the kind was reached, from the same rolls the draw reads.
            let key = Data(finders.childSeed.bytes.prefix(16))
            let roll = SpaceGenes.rawUnit(key, "inherit:space.kind")
            let how: String
            if roll < GeneSource.inheritFirstParent { how = "first parent" }
            else if roll < GeneSource.inheritSecondParent { how = "second parent" }
            else if roll < GeneSource.inheritBlend { how = "coin" }
            else { how = "mutation" }
            classes.insert(how)

            Self.agree(
                .object(row),
                .object([
                    "series": Self.number(index),
                    "found": .text(found.hex),
                    "own": .text(own.hex),
                    "ownNonce": .text(nonce.hexString),
                    "encounter": .text(finders.encounterID.hexString),
                    "child": .text(finders.childSeed.hex),
                    "checksum": .text(finders.checksum.hexString),
                    "ownKind": .text(SpaceFlora.kind(of: Data(own.bytes.prefix(16))).rawValue),
                    "foundKind": .text(SpaceFlora.kind(of: Data(found.bytes.prefix(16))).rawValue),
                    "kind": .text(flora.kind.rawValue),
                    "kindFrom": .text(how),
                    "centreKind": flora.centreKind.map { .text($0.rawValue) } ?? .nothing,
                    "traits": .object(Self.traits(flora.genome))
                ]),
                "crosses[\(index)]"
            )
        }
        // The file covers every way a child can come by its kind.
        XCTAssertEqual(classes, ["first parent", "second parent", "coin", "mutation"])
    }
}
