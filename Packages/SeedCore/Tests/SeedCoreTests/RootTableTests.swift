import XCTest
import Foundation
@testable import SeedCore

/// The genus root table, held to the four things that make it a classification
/// rather than a lookup.
///
/// It is a hand-written table over a frozen list, which `docs/NAMES-AND-THEMES.md`
/// already identified as the kind of thing that goes wrong in silence: a root
/// dropped from it costs nobody a compile error and quietly renames a twelfth
/// of every garden. The same argument applies here with more force, because now
/// the table decides what a plant *is* and not only what it is called.
final class RootTableTests: XCTestCase {

    // MARK: - The table is a bijection

    /// Twelve families, two roots each, and the frozen twenty-four used once.
    ///
    /// The three ways this can break are all silent, so all three are named:
    /// a family missing (some plants unnameable), a root used twice (two
    /// families sharing a genus, which is the bug the whole redesign exists to
    /// remove), and a root invented (a genus no theme claims, so a plant with
    /// no passage).
    func testEveryArchetypeHasTwoRootsAndEveryRootIsUsedOnce() {
        XCTAssertEqual(PlantName.roots.count, Archetype.allCases.count)

        var seen: [String: [Archetype]] = [:]
        for archetype in Archetype.allCases {
            let pair = PlantName.roots[archetype]
            XCTAssertNotNil(pair, "\(archetype) has no roots")
            guard let pair else { continue }
            XCTAssertNotEqual(pair.few, pair.many, "\(archetype) uses one root twice")
            seen[pair.few, default: []].append(archetype)
            seen[pair.many, default: []].append(archetype)
        }

        for (root, families) in seen where families.count > 1 {
            XCTFail("\(root) is claimed by \(families.map(String.init(describing:)).joined(separator: " and "))")
        }
        XCTAssertEqual(Set(seen.keys), Set(PlantName.genusHeads),
                       "the roots and the frozen heads are not the same set")
    }

    /// Every drawn plant's genus starts with the root its own flower names.
    ///
    /// The end-to-end version of the table: it goes through `Genome`, so it
    /// would also catch the head being drawn from somewhere else again.
    func testAPlantsGenusIsReadFromItsOwnFlower() {
        for index in 0..<3_000 {
            let genome = Genome(seed: SeedMint.mint(fromEntropy: Data("root-\(index)".utf8)))
            let expected = PlantName.genusHead(for: genome.form.archetype, genome.form.merosity)
            XCTAssertEqual(genome.name.genusHead, expected, "\(genome.name.full)")
            XCTAssertTrue(genome.name.genus.hasPrefix(expected), "\(genome.name.full)")
        }
    }

    // MARK: - The root means something

    /// **Same root, same flower.** The property the whole design is for.
    ///
    /// A genus that groups by nothing is a prefix — `docs/TAXONOMY.md` opens on
    /// that, having measured the old arrangement at 0.3% of the variance in
    /// stem height. So: every plant sharing a root must agree on its floral
    /// plan and on its petal count, give or take the one-in-five variant a real
    /// flora allows.
    func testEveryPlantSharingARootSharesItsFlower() {
        var byRoot: [String: [Genome]] = [:]
        for index in 0..<4_000 {
            let genome = Genome(seed: SeedMint.mint(fromEntropy: Data("flower-\(index)".utf8)))
            byRoot[genome.name.genusHead, default: []].append(genome)
        }
        XCTAssertEqual(byRoot.count, 24, "not every root was reached in 4000 seeds")

        for (root, plants) in byRoot {
            let plans = Set(plants.map(\.branching.inflorescence))
            XCTAssertEqual(plans.count, 1, "\(root) carries more than one inflorescence")

            let archetypes = Set(plants.map(\.form.archetype))
            XCTAssertEqual(archetypes.count, 1, "\(root) belongs to more than one family")

            // *Petals 5, rarely 4 or 6.* The count is the genus's; the spread
            // around it is one either way and no more.
            let counts = plants.map(\.bloom.petalCount)
            let spread = (counts.max() ?? 0) - (counts.min() ?? 0)
            XCTAssertLessThanOrEqual(spread, 2, "\(root) has a petal count of \(counts.min()!)...\(counts.max()!)")
        }
    }

    /// The variant is rare enough to be a variant and common enough to exist.
    ///
    /// Without it a bed of one genus reads as printed rather than grown; with
    /// too much of it the count stops being diagnostic and the key stops
    /// working. Both failures are the kind only a render would otherwise show.
    func testTheVariantIsAboutOnePlantInFive() {
        var plan = 0
        var variant = 0
        for index in 0..<4_000 {
            let genome = Genome(seed: SeedMint.mint(fromEntropy: Data("variant-\(index)".utf8)))
            let profile = ArchetypeProfile.profile(for: genome.form.archetype)
            let expected = genome.form.merosity == .few ? profile.petals.few : profile.petals.many
            if genome.bloom.petalCount == expected { plan += 1 } else { variant += 1 }
        }
        let share = Double(variant) / Double(plan + variant)
        XCTAssertGreaterThan(share, 0.12, "the variant has all but vanished")
        XCTAssertLessThan(share, 0.28, "the variant is no longer a variant")
    }

    // MARK: - What the arrangement was chosen for

    /// **No family takes both its roots from one theme.**
    ///
    /// Themes are the garden's ten areas, so a family sitting inside one theme
    /// is an area of a single repeated shape. This is the property that makes
    /// the pairings a design rather than an arbitrary matching, and it is not
    /// visible from the table itself — it needs the head → theme map, which
    /// lives in the app. The map is restated here as a fixture rather than
    /// imported, and `testTheRestatedThemeMapIsTheAppsOwn` is what stops the
    /// two drifting apart.
    func testNoFamilyKeepsBothRootsInOneTheme() {
        for archetype in Archetype.allCases {
            guard let pair = PlantName.roots[archetype] else { continue }
            let few = Self.themes[pair.few]
            let many = Self.themes[pair.many]
            XCTAssertNotNil(few, "\(pair.few) is in no theme")
            XCTAssertNotNil(many, "\(pair.many) is in no theme")
            XCTAssertNotEqual(few, many,
                              "\(archetype) keeps both roots in \(few ?? "?") — that area is one shape")
        }
    }

    /// Every theme still receives at least two families, so no area of the
    /// garden is thin.
    func testEveryThemeHoldsMoreThanOneKindOfPlant() {
        var families: [String: Set<Archetype>] = [:]
        for archetype in Archetype.allCases {
            guard let pair = PlantName.roots[archetype] else { continue }
            for root in [pair.few, pair.many] {
                guard let theme = Self.themes[root] else { continue }
                families[theme, default: []].insert(archetype)
            }
        }
        XCTAssertEqual(families.count, 10)
        for (theme, kinds) in families {
            XCTAssertGreaterThanOrEqual(kinds.count, 2, "\(theme) holds only \(kinds)")
        }
    }

    /// The fixture above is the app's map, and this is the guard on saying so.
    ///
    /// SeedCore cannot see `Quotes.Theme` — the banks live in the app target —
    /// so the map is restated. A restatement that can drift is worse than no
    /// test, so this pins its shape: the ten themes, the twenty-four roots, and
    /// each root claimed once. `ThemeMappingTests` in the app holds the other
    /// end against the real thing.
    func testTheRestatedThemeMapIsTheAppsOwn() {
        XCTAssertEqual(Set(Self.themes.keys), Set(PlantName.genusHeads))
        XCTAssertEqual(Set(Self.themes.values).count, 10)
        // Four themes take three roots and six take two — the only division of
        // twenty-four that keeps every theme populated. docs/NAMES-AND-THEMES.md.
        var sizes: [Int: Int] = [:]
        for theme in Set(Self.themes.values) {
            sizes[Self.themes.values.filter { $0 == theme }.count, default: 0] += 1
        }
        XCTAssertEqual(sizes[3], 4)
        XCTAssertEqual(sizes[2], 6)
    }

    /// `docs/NAMES-AND-THEMES.md` §"The map", restated. See above.
    private static let themes: [String: String] = [
        "Thal": "beginnings", "Lir": "beginnings", "Ver": "beginnings",
        "Nyx": "waiting", "Umbr": "waiting",
        "Dros": "renewal", "Ros": "renewal",
        "El": "light", "Aur": "light", "Sel": "light",
        "Cal": "pattern", "Quin": "pattern",
        "Cer": "ground", "Fen": "ground", "Pell": "ground",
        "Zeph": "travel", "Ael": "travel", "Hal": "travel",
        "Mel": "meeting", "Ith": "meeting",
        "Wyn": "kinship", "Cyn": "kinship",
        "Ol": "peace", "Bel": "peace",
    ]

    // MARK: - The family

    /// A family is named from its type genus, the way Oleaceae is named from
    /// *Olea* — derived rather than written into a second table that could
    /// disagree with the first.
    func testEveryFamilyIsNamedFromItsTypeGenus() {
        var names: Set<String> = []
        for archetype in Archetype.allCases {
            let name = archetype.familyName
            XCTAssertTrue(name.hasSuffix("aceae"), "\(archetype) is \(name)")
            XCTAssertTrue(name.hasPrefix(PlantName.genusHead(for: archetype, .few)),
                          "\(name) is not named from its own type genus")
            names.insert(name)
        }
        XCTAssertEqual(names.count, Archetype.allCases.count, "two families share a name")
    }
}
