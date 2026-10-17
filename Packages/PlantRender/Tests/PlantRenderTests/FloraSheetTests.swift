import SeedCore
import SwiftUI
import UIKit
import XCTest
import PlantRender

/// The sheet's measurements, in points. Outside the test class so the views
/// that read them do not have to be reasoned about as the test's own.
private enum SheetLayout {
    static let tile: CGFloat = 230
    static let gap: CGFloat = 10
    static let labelWidth: CGFloat = 210
    static let ground = Color(white: 0.09)
}

/// The A to E picture sheet of Zone C's five space flora kinds, for judging them
/// by eye.
///
/// Each plant is drawn the way the garden grid draws one: `ThumbnailRenderer`
/// stills, framed and lit by PlantRender exactly as in Peace Garden, laid over
/// the app's own `StageBackdrop` for that plant's palette, in the dark
/// appearance the app opens in. Nothing here lights, frames or tints a plant of
/// its own.
///
/// The search for specimens runs in every test pass, because it is cheap and
/// pins which seeds the sheets show. The pictures are written only when
/// `PG_SHEET_DIR` names a folder, so a normal run and CI never produce files:
///
///     TEST_RUNNER_PG_SHEET_DIR=/private/tmp/claude-501/pg-flora-sheet \
///       xcodebuild test -scheme PlantRender -only-testing PlantRenderTests/FloraSheetTests …
@MainActor
final class FloraSheetTests: XCTestCase {

    static let perKind = 3

    // MARK: - Which seeds

    /// The first `perKind` seeds, walking a fixed sequence of 16-byte keys, that
    /// draw each kind. The same seeds on every run and every machine.
    static func specimens(limit: Int = 4000) -> [SpaceKind: [SpaceFlora]] {
        var found: [SpaceKind: [SpaceFlora]] = [:]
        var index = 0
        while index < limit, SpaceKind.allCases.contains(where: { (found[$0]?.count ?? 0) < perKind }) {
            let digest = seedDigest("pg.flora-sheet.v1", Data("\(index)".utf8))
            index += 1
            guard let flora = SpaceFlora.draw(r: Data(digest.prefix(16))) else { continue }
            if (found[flora.kind]?.count ?? 0) < perKind { found[flora.kind, default: []].append(flora) }
        }
        return found
    }

    func testEveryKindHasThreeSeedsThatDrawIt() throws {
        let found = Self.specimens()
        for kind in SpaceKind.allCases {
            let plants = try XCTUnwrap(found[kind], "no seeds found for \(kind.displayName)")
            XCTAssertEqual(plants.count, Self.perKind, kind.displayName)
            XCTAssertEqual(Set(plants.map(\.key)).count, Self.perKind, "three different seeds")
            for plant in plants {
                XCTAssertEqual(plant.kind, kind)
                XCTAssertEqual(plant.key.count, 16)
                // And it grows: a mature plant has a mesh with leaves and a flower.
                let mesh = PlantBuilder(genome: plant.genome)
                    .mesh(growth: PlantSceneBuilder.bloomPreview(for: plant.genome))
                XCTAssertFalse(mesh.parts.filter { !$0.indices.isEmpty }.isEmpty, kind.displayName)
            }
        }
    }

    // MARK: - The pictures

    static func sheetFolder() -> URL? {
        guard let path = ProcessInfo.processInfo.environment["PG_SHEET_DIR"], !path.isEmpty else { return nil }
        return URL(fileURLWithPath: path, isDirectory: true)
    }

    /// How far through its life a plant is drawn: a share of the time it takes
    /// to reach full bloom, and at the end the plant at its best, as the app's
    /// reveal shows it (`bloomPreview`).
    private enum Age: CaseIterable {
        case young, halfGrown, mature

        var title: String {
            switch self {
            case .young: return "young"
            case .halfGrown: return "half-grown"
            case .mature: return "mature"
            }
        }

        func state(for genome: Genome) -> GrowthModel.State {
            let model = GrowthModel(genome: genome)
            let share: Double
            switch self {
            case .young: share = 0.12
            case .halfGrown: share = 0.5
            case .mature: return PlantSceneBuilder.bloomPreview(for: genome)
            }
            // Before the bloom starts nothing opens, so the hour of the day the
            // state is read at changes nothing.
            let fullBloomAt = model.end(of: .budding) ?? 0
            let birth = Date(timeIntervalSince1970: 0)
            return model.state(birth: birth, now: birth.addingTimeInterval(fullBloomAt * share))
        }
    }

    private func still(_ flora: SpaceFlora, _ age: Age) throws -> UIImage {
        try XCTUnwrap(
            ThumbnailRenderer.shared.image(genome: flora.genome, growth: age.state(for: flora.genome), size: SheetLayout.tile),
            "no picture of \(flora.name)"
        )
    }

    private struct Tile: View {
        let flora: SpaceFlora
        let image: UIImage
        let caption: String

        var body: some View {
            ZStack(alignment: .bottomLeading) {
                StageBackdrop(palette: flora.genome.palette)
                Image(uiImage: image).resizable().scaledToFit()
                Text(caption)
                    .font(.system(size: 12, weight: .light).monospaced())
                    .foregroundStyle(.white.opacity(0.62))
                    .padding(8)
            }
            .frame(width: SheetLayout.tile, height: SheetLayout.tile)
            .clipped()
        }
    }

    private struct KindLabel: View {
        let kind: SpaceKind

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(kind.letter).font(.system(size: 64, weight: .ultraLight))
                Text(kind.displayName).font(.system(size: 20, weight: .light))
                Text(kind.form.rawValue)
                    .font(.system(size: 13, weight: .light).monospaced())
                    .foregroundStyle(.white.opacity(0.55))
            }
            .foregroundStyle(.white.opacity(0.92))
            .frame(width: SheetLayout.labelWidth, alignment: .leading)
        }
    }

    private struct Sheet<Rows: View>: View {
        let title: String
        let columns: [String]
        let rows: Rows

        var body: some View {
            VStack(alignment: .leading, spacing: SheetLayout.gap) {
                Text(title)
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(.white.opacity(0.8))
                HStack(spacing: SheetLayout.gap) {
                    Color.clear.frame(width: SheetLayout.labelWidth, height: 1)
                    ForEach(columns, id: \.self) { column in
                        Text(column)
                            .font(.system(size: 13, weight: .light).monospaced())
                            .foregroundStyle(.white.opacity(0.55))
                            .frame(width: SheetLayout.tile, alignment: .leading)
                    }
                }
                rows
            }
            .padding(SheetLayout.gap * 2)
            .background(SheetLayout.ground)
            .environment(\.colorScheme, .dark)
        }
    }

    /// Renders `content`, at the largest scale up to 2 whose PNG stays under
    /// about 2 MB, and writes it.
    private func write<Content: View>(_ content: Content, as name: String, to folder: URL) throws {
        var written = 0
        for scale in [2.0, 1.75, 1.5, 1.25, 1.0] {
            let renderer = ImageRenderer(content: content)
            renderer.scale = scale
            let image = try XCTUnwrap(renderer.uiImage, "\(name) did not render")
            let data = try XCTUnwrap(image.pngData())
            try data.write(to: folder.appendingPathComponent("\(name).png"))
            written = data.count
            print("FLORA SHEET \(name).png: \(Int(image.size.width * image.scale))x\(Int(image.size.height * image.scale)) px, \(data.count) bytes at \(scale)x")
            if data.count < 1_950_000 { break }
        }
        XCTAssertLessThan(written, 2_000_000, "\(name).png is over about 2 MB at its smallest scale")
    }

    func testWriteTheFloraSheets() throws {
        guard let folder = Self.sheetFolder() else {
            throw XCTSkip("PG_SHEET_DIR is not set")
        }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let found = Self.specimens()

        // The stills first, outside any view: drawing a view is not the place to
        // be rendering a scene.
        var mature: [SpaceKind: [UIImage]] = [:]
        var growing: [SpaceKind: [UIImage]] = [:]
        for kind in SpaceKind.allCases {
            let plants = found[kind] ?? []
            mature[kind] = try plants.map { try still($0, .mature) }
            if let first = plants.first {
                growing[kind] = try Age.allCases.map { try still(first, $0) }
            }
        }

        // Sheet one: five kinds, three seeds each, every plant mature.
        let kinds = VStack(alignment: .leading, spacing: SheetLayout.gap) {
            ForEach(SpaceKind.allCases, id: \.self) { kind in
                HStack(spacing: SheetLayout.gap) {
                    KindLabel(kind: kind)
                    ForEach(Array((found[kind] ?? []).enumerated()), id: \.offset) { offset, flora in
                        Tile(flora: flora, image: mature[kind]?[offset] ?? UIImage(),
                             caption: "\(kind.letter)\(offset + 1)")
                    }
                }
            }
        }
        try write(
            Sheet(title: "Space flora · mature · three seeds of each kind",
                  columns: ["1", "2", "3"], rows: kinds),
            as: "flora-sheet-kinds", to: folder
        )

        // Sheet two: the first seed of each kind at three ages.
        let ages = VStack(alignment: .leading, spacing: SheetLayout.gap) {
            ForEach(SpaceKind.allCases, id: \.self) { kind in
                HStack(spacing: SheetLayout.gap) {
                    KindLabel(kind: kind)
                    if let flora = found[kind]?.first {
                        ForEach(Array(Age.allCases.enumerated()), id: \.offset) { offset, age in
                            Tile(flora: flora, image: growing[kind]?[offset] ?? UIImage(),
                                 caption: "\(kind.letter)1 · \(age.title)")
                        }
                    }
                }
            }
        }
        try write(
            Sheet(title: "Space flora · the first seed of each kind, growing",
                  columns: Age.allCases.map(\.title), rows: ages),
            as: "flora-sheet-ages", to: folder
        )
    }
}
