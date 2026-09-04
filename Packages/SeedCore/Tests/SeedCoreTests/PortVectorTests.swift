import XCTest
import Foundation
@testable import SeedCore

/// Pins `tools/preview/vectors.json` to what this package actually computes.
///
/// **`tools/preview/plant_model.py` is a hand-maintained port of everything in
/// this package, and it is how the garden gets looked at.** Nobody can see a
/// vertex buffer, so the defects this repository has actually caught — every
/// leaf the same size, a spire of identical heads at even spacing, a husk wider
/// than the plant was tall — were caught by rendering a plant and looking at it,
/// which happens in Python. A render taken from a drifted port is a decision
/// made about a plant that does not exist.
///
/// It had drifted three times before this file existed, most recently by
/// missing the per-node bloom `ceiling` and the size taper entirely. Both are
/// invisible in a vertex count and neither shows up in any Swift test, because
/// the Swift was right.
///
/// So this is the same bargain `tools/site/export.py --check` strikes with the
/// passage banks: a committed artefact, and both sides held against it. This
/// test says the file is what the Swift computes; `tools/preview/check_port.py`
/// says the file is what the port computes; CI runs both. Neither can pass
/// while the two languages disagree, and the file itself is the diff.
///
/// **To re-record after a deliberate change to the Swift:**
///
/// ```
/// PEACE_GARDEN_RECORD_VECTORS=1 swift test \
///     --package-path Packages/SeedCore --filter PortVectorTests
/// ```
///
/// then run `python3 tools/preview/check_port.py`, which will name every field
/// of the port that has fallen behind. Update the port until it passes, and
/// commit the two together. That chain is the whole point of the file: a change
/// to the Swift cannot land without either the port following it or somebody
/// deciding, in writing, that it should not.
final class PortVectorTests: XCTestCase {

    /// Where the committed file lives, found by walking up out of the package.
    ///
    /// It sits under `tools/preview/` rather than in this target's resources
    /// because the port is its other reader and the port is a script, not a
    /// bundle. A resource copy would put the artefact both sides are held
    /// against inside one of them.
    static var vectorsURL: URL {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { url.deleteLastPathComponent() }   // …/Tests/SeedCoreTests/<this>
        return url.appendingPathComponent("tools/preview/vectors.json")
    }

    static let recordingKey = "PEACE_GARDEN_RECORD_VECTORS"

    func testTheCommittedVectorsAreWhatTheSwiftComputes() throws {
        let rendered = Self.render()

        if ProcessInfo.processInfo.environment[Self.recordingKey] == "1" {
            try rendered.write(to: Self.vectorsURL, atomically: true, encoding: .utf8)
            print("re-recorded \(Self.vectorsURL.path) — now run tools/preview/check_port.py")
        }

        let committed: String
        do {
            committed = try String(contentsOf: Self.vectorsURL, encoding: .utf8)
        } catch {
            return XCTFail("""
                tools/preview/vectors.json is missing. Record it with \
                `\(Self.recordingKey)=1 swift test --package-path Packages/SeedCore \
                --filter PortVectorTests`.
                """)
        }

        guard committed != rendered else { return }

        // The first differing line rather than the whole file: these vectors run
        // to a few thousand lines and a diff of all of them says nothing about
        // which trait moved.
        let old = committed.split(separator: "\n", omittingEmptySubsequences: false)
        let new = rendered.split(separator: "\n", omittingEmptySubsequences: false)
        var where_ = "the file lengths differ — \(old.count) lines committed, \(new.count) computed"
        for (index, pair) in zip(old, new).enumerated() where pair.0 != pair.1 {
            where_ = "line \(index + 1)\n  committed: \(pair.0.trimmingCharacters(in: .whitespaces))"
                + "\n  computed:  \(pair.1.trimmingCharacters(in: .whitespaces))"
            break
        }

        XCTFail("""
            tools/preview/vectors.json is not what SeedCore computes, at \(where_)

            If the Swift changed on purpose, re-record with
              \(Self.recordingKey)=1 swift test --package-path Packages/SeedCore --filter PortVectorTests
            and then run `python3 tools/preview/check_port.py`, which will fail until
            tools/preview/plant_model.py has been brought along with it.
            """)
    }

    // MARK: - The plants

    /// A seed for each of the twelve families, found by walking a fixed series.
    ///
    /// **Searched rather than listed**, because a hand-picked seed is a seed
    /// somebody chose and would have to choose again. The series is
    /// `peace-garden-port-vector-0`, `-1`, and so on; the first seed to land on
    /// a family not yet held is kept. Anybody can rerun it and get the same
    /// twelve, and the index that found each one is written into the file, so a
    /// reader can check the claim without running anything.
    ///
    /// All twelve families, because the archetype is the one trait that swings
    /// every other: it sets the inflorescence, whether flowers open at the
    /// nodes, and eleven multipliers. Eleven families would leave a twelfth of
    /// the profile table untested, and `ArchetypeProfile` is exactly the kind of
    /// table that gets edited in one place.
    static func searchedSeeds() -> [(index: Int, seed: SeedID, archetype: Archetype)] {
        var found: [Archetype: (Int, SeedID)] = [:]
        var index = 0
        while found.count < Archetype.allCases.count {
            let seed = SeedMint.mint(fromEntropy: Data("peace-garden-port-vector-\(index)".utf8))
            let archetype = Genome(seed: seed).form.archetype
            if found[archetype] == nil {
                found[archetype] = (index, seed)
            }
            index += 1
            // A guard rather than a `while true`: if the archetype draw ever
            // stopped covering all twelve, this would otherwise hang a CI job
            // rather than say what was wrong.
            if index > 5_000 {
                fatalError("no seed found for \(Set(Archetype.allCases).subtracting(found.keys))")
            }
        }
        // Ordered by the enum rather than by the search, so the file reads as a
        // list of families and a family keeps its place when the search moves.
        return Archetype.allCases.map { archetype in
            let entry = found[archetype]!
            return (index: entry.0, seed: entry.1, archetype: archetype)
        }
    }

    // MARK: - The ages

    /// Midnight UTC, so that every age below lands on the hour.
    ///
    /// `GrowthModel.diurnalFactor` reads the wall clock, and a plant that opens
    /// by day is damped to a third of its opening at midnight. That is a real
    /// part of the model and worth pinning — but only if both languages agree
    /// on what time it is, so the hour each sample was taken at is written into
    /// the file rather than recomputed there.
    static let birth = Date(timeIntervalSince1970: 1_699_920_000)

    static var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    /// Four moments in a plant's life, in seconds from its birth.
    ///
    /// Measured against the plant's own tempo rather than in fixed days,
    /// because the tempo is drawn: a genome that blooms for three days is
    /// mature in a fortnight and one that blooms for twelve takes a month, so a
    /// fixed day would catch one plant in bud and the next long past it.
    ///
    /// - a pre-bloom age, halfway to first flower, where `bloomOpen` is nought
    ///   and the leaves are still unfurling;
    /// - first full opening, a third of the way into the blooming stage;
    /// - two phases of the flowering cycle, half a cycle apart and both past
    ///   the first full cycle so that `flushDepth` has reached one. **Half a
    ///   cycle apart is the point**: a flower at a crest and the same flower in
    ///   a trough are what the wave is, and a port missing the wave entirely
    ///   would give identical answers at both.
    ///
    /// Rounded to the hour so the wall clock at each sample is a whole number
    /// and no rounding of it has to be agreed between the two languages.
    static func ages(for genome: Genome) -> [TimeInterval] {
        let day: TimeInterval = 86_400
        let toBloom = genome.tempo.daysToBloom * day
        let matureAt = toBloom + genome.tempo.bloomDays * day
        let cycle = max(day, genome.tempo.bloomDays * day * 2.4)
        return [
            toBloom * 0.5,
            toBloom + genome.tempo.bloomDays * day * 0.35,
            matureAt + cycle * 1.15,
            matureAt + cycle * 1.65
        ].map { (($0 / 3600).rounded() * 3600) }
    }

    // MARK: - Rendering the file

    static func render() -> String {
        var plants: [JSON] = []
        for entry in searchedSeeds() {
            let genome = Genome(seed: entry.seed)
            let model = GrowthModel(genome: genome)
            let builder = PlantBuilder(genome: genome)

            var samples: [JSON] = []
            for age in ages(for: genome) {
                let now = birth.addingTimeInterval(age)
                let growth = model.state(birth: birth, now: now, calendar: utc)
                let hour = Double(utc.component(.hour, from: now))
                    + Double(utc.component(.minute, from: now)) / 60.0
                samples.append(.object([
                    ("ageSeconds", .number(age)),
                    ("hourOfDay", .number(hour)),
                    ("growth", .object([
                        ("stage", .string(growth.stage.rawValue)),
                        ("heightScale", .number(growth.heightScale)),
                        ("leafUnfurl", .number(growth.leafUnfurl)),
                        ("budSwell", .number(growth.budSwell)),
                        ("bloomOpen", .number(growth.bloomOpen)),
                        ("flush", .number(growth.flush)),
                        ("flushDepth", .number(growth.flushDepth))
                    ])),
                    ("blooms", .array(builder.bloomPlacementsForTesting(growth: growth).map {
                        .object([
                            ("kind", .string($0.kind.rawValue)),
                            ("index", .int($0.index)),
                            ("t", .number($0.t)),
                            ("budSwell", .number($0.budSwell)),
                            ("bloomOpen", .number($0.bloomOpen)),
                            ("scale", .number($0.scale))
                        ])
                    }))
                ]))
            }

            plants.append(.object([
                ("entropy", .string("peace-garden-port-vector-\(entry.index)")),
                ("seed", .string(entry.seed.hex)),
                ("genome", genomeJSON(genome)),
                ("ages", .array(samples))
            ]))
        }

        let document = JSON.object([
            ("note", .string(
                "Generated by Packages/SeedCore/Tests/SeedCoreTests/PortVectorTests.swift. "
                + "SeedCore is the source; do not edit. "
                + "Re-record with PEACE_GARDEN_RECORD_VECTORS=1 swift test "
                + "--package-path Packages/SeedCore --filter PortVectorTests, then run "
                + "tools/preview/check_port.py."
            )),
            ("decimals", .int(decimals)),
            ("plants", .array(plants))
        ])
        return document.written(indent: 0) + "\n"
    }

    static func genomeJSON(_ genome: Genome) -> JSON {
        .object([
            ("form.archetype", .string(genome.form.archetype.rawValue)),
            ("form.merosity", .string(genome.form.merosity.rawValue)),
            ("form.vigour", .number(genome.form.vigour)),

            ("branching.inflorescence", .string(genome.branching.inflorescence.rawValue)),
            ("branching.count", .int(genome.branching.count)),
            ("branching.spread", .number(genome.branching.spread)),

            ("stem.height", .number(genome.stem.height)),
            ("stem.baseRadius", .number(genome.stem.baseRadius)),
            ("stem.taper", .number(genome.stem.taper)),
            ("stem.lean", .number(genome.stem.lean)),
            ("stem.sway", .number(genome.stem.sway)),
            ("stem.twist", .number(genome.stem.twist)),
            ("stem.nodeCount", .int(genome.stem.nodeCount)),

            ("foliage.leavesPerNode", .int(genome.foliage.leavesPerNode)),
            ("foliage.length", .number(genome.foliage.length)),
            ("foliage.widthRatio", .number(genome.foliage.widthRatio)),
            ("foliage.droop", .number(genome.foliage.droop)),
            ("foliage.fold", .number(genome.foliage.fold)),
            ("foliage.pitch", .number(genome.foliage.pitch)),
            ("foliage.serration", .number(genome.foliage.serration)),
            ("foliage.teeth", .int(genome.foliage.teeth)),
            ("foliage.veinCount", .int(genome.foliage.veinCount)),
            ("foliage.tipSharpness", .number(genome.foliage.tipSharpness)),

            ("bloom.petalCount", .int(genome.bloom.petalCount)),
            ("bloom.layers", .int(genome.bloom.layers)),
            ("bloom.length", .number(genome.bloom.length)),
            ("bloom.widthRatio", .number(genome.bloom.widthRatio)),
            ("bloom.curl", .number(genome.bloom.curl)),
            ("bloom.headPitch", .number(genome.bloom.headPitch)),
            ("bloom.centreRadius", .number(genome.bloom.centreRadius)),

            ("tempo.germinationHours", .number(genome.tempo.germinationHours)),
            ("tempo.seedlingDays", .number(genome.tempo.seedlingDays)),
            ("tempo.vegetativeDays", .number(genome.tempo.vegetativeDays)),
            ("tempo.buddingDays", .number(genome.tempo.buddingDays)),
            ("tempo.bloomDays", .number(genome.tempo.bloomDays)),
            ("tempo.opensByDay", .bool(genome.tempo.opensByDay)),

            ("name.full", .string(genome.name.full))
        ])
    }

    // MARK: - Writing it out

    /// How many decimal places a number is written to.
    ///
    /// Six, which is the point where the two languages can be expected to agree
    /// without argument. The geometry here is `Float` on this side and a Python
    /// `float` — a double — on the other, and a `Float` carries a little over
    /// seven significant decimal digits, so six places is inside what both can
    /// represent and outside where the difference between them lives. It is
    /// also about four significant figures on the smallest trait recorded, the
    /// stem's base radius, which is finer than any drift that has ever mattered
    /// here by three orders of magnitude.
    static let decimals = 6

    /// A minimal JSON writer, ordered.
    ///
    /// `JSONSerialization` is not used, for two reasons that both come down to
    /// the file being a committed artefact rather than a payload. It sorts or
    /// shuffles keys, so a genome would read as an alphabetical jumble rather
    /// than as a plant; and it formats doubles however it likes, which would
    /// make the file's stability depend on a Foundation implementation detail
    /// that differs between Darwin and Linux — and CI runs on Linux.
    enum JSON {
        case string(String)
        case int(Int)
        case bool(Bool)
        case number(Double)
        case array([JSON])
        case object([(String, JSON)])

        func written(indent: Int) -> String {
            let pad = String(repeating: " ", count: indent)
            let inner = String(repeating: " ", count: indent + 1)
            switch self {
            case let .string(value):
                return JSON.quoted(value)
            case let .int(value):
                return String(value)
            case let .bool(value):
                return value ? "true" : "false"
            case let .number(value):
                // `%.6f` rather than the shortest round-trip, so that every
                // number in the file is the same width and a reader comparing
                // two of them is comparing digits rather than notations.
                // Negative zero is written as zero: it is the same number, and
                // the sign of it depends on which way a trait was clamped.
                let text = String(format: "%.\(decimals)f", value)
                return text == "-0.\(String(repeating: "0", count: decimals))"
                    ? String(text.dropFirst())
                    : text
            case let .array(items):
                guard !items.isEmpty else { return "[]" }
                let body = items.map { inner + $0.written(indent: indent + 1) }
                return "[\n" + body.joined(separator: ",\n") + "\n" + pad + "]"
            case let .object(pairs):
                guard !pairs.isEmpty else { return "{}" }
                let body = pairs.map {
                    inner + JSON.quoted($0.0) + ": " + $0.1.written(indent: indent + 1)
                }
                return "{\n" + body.joined(separator: ",\n") + "\n" + pad + "}"
            }
        }

        static func quoted(_ value: String) -> String {
            var out = "\""
            for character in value.unicodeScalars {
                switch character {
                case "\"": out += "\\\""
                case "\\": out += "\\\\"
                case "\n": out += "\\n"
                case "\t": out += "\\t"
                case let scalar where scalar.value < 0x20:
                    out += String(format: "\\u%04x", scalar.value)
                default: out.unicodeScalars.append(character)
                }
            }
            return out + "\""
        }
    }
}
