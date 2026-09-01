import XCTest
import SeedCore
@testable import PeaceGarden

/// The map from a genus syllable to a passage theme, and from a genus ending
/// to one of that theme's three subthemes.
///
/// It is a hand-written table over two frozen lists, which is the kind of thing
/// that goes wrong silently: a head dropped from the table costs nobody a
/// compile error and quietly sends a tenth of all plants to Beginnings, and a
/// subtheme with no passages behind it is a crash at the one moment the app
/// exists for. Both are cheap to prove and impossible to notice.
final class ThemeMappingTests: XCTestCase {

    // MARK: - Every syllable is spoken for

    func testEveryGenusHeadBelongsToExactlyOneTheme() {
        var claims: [String: [Quotes.Theme]] = [:]
        for theme in Quotes.Theme.allCases {
            for head in theme.genusHeads {
                claims[head, default: []].append(theme)
            }
        }

        for head in PlantName.genusHeads {
            XCTAssertEqual(
                claims[head]?.count, 1,
                "\(head) is claimed by \(claims[head] ?? []) — every head needs exactly one theme"
            )
        }
    }

    func testNoThemeClaimsASyllableThatDoesNotExist() {
        let known = Set(PlantName.genusHeads)
        for theme in Quotes.Theme.allCases {
            for head in theme.genusHeads {
                XCTAssertTrue(known.contains(head), "\(theme) claims \(head), which is not a genus head")
            }
        }
    }

    /// The heads are the file format — see `PlantName.genusHeads`. A
    /// twenty-fifth would shift `pick`'s boundaries and rename every plant on
    /// every phone, so the count is pinned here as well as commented there.
    func testTheGenusSyllablesAreStillTheOnesEveryPlantWasNamedFrom() {
        XCTAssertEqual(PlantName.genusHeads.count, 24)
        XCTAssertEqual(PlantName.genusTails.count, 10)
        XCTAssertEqual(PlantName.genusHeads.first, "Ael")
        XCTAssertEqual(PlantName.genusHeads.last, "Zeph")
    }

    // MARK: - Every theme divides three ways, and every third has passages

    func testEveryThemeHasThreeSubthemes() {
        for theme in Quotes.Theme.allCases {
            XCTAssertEqual(theme.subthemes.count, 3, "\(theme)")
        }
        XCTAssertEqual(Quotes.Subtheme.allCases.count, 30)
    }

    func testEverySubthemeCarriesPassages() {
        let counts = Dictionary(grouping: Quotes.all, by: \.subtheme).mapValues(\.count)
        for subtheme in Quotes.Subtheme.allCases {
            XCTAssertGreaterThan(
                counts[subtheme] ?? 0, 0,
                "\(subtheme) has no passages, which is a crash rather than a gap"
            )
        }
    }

    /// A passage's subtheme has to agree with the theme it was filed under, or
    /// the two halves of the draw disagree and a Peace pair is handed a line
    /// about seed dispersal.
    func testEveryPassageAgreesWithItsOwnSubtheme() {
        for passage in Quotes.all {
            XCTAssertEqual(
                passage.subtheme.theme, passage.theme,
                "\(passage.subtheme) is filed under \(passage.theme)"
            )
        }
    }

    func testTheBankIsStillEvenAcrossThemes() {
        let counts = Dictionary(grouping: Quotes.all, by: \.theme).mapValues(\.count)
        XCTAssertEqual(Quotes.all.count, 300)
        for theme in Quotes.Theme.allCases {
            XCTAssertEqual(counts[theme], 30, "\(theme)")
        }
    }

    // MARK: - The draw

    func testASubthemeDrawnForAThemeAlwaysBelongsToIt() {
        for theme in Quotes.Theme.allCases {
            for index in 0..<200 {
                let genome = Genome(seed: Self.seed(index), lineage: .minted)
                let subtheme = Quotes.subtheme(of: genome, in: theme)
                XCTAssertEqual(subtheme.theme, theme, "\(theme) handed out \(subtheme)")
            }
        }
    }

    /// The hand-written init has to recover a head and an ending from the
    /// spelling, since a name written rather than drawn still has to land in a
    /// theme. Both are longest-match, so `Pell` beats nothing and `ynth` beats
    /// no shorter ending that happens to be a suffix of it.
    func testAHandMadeNameRecoversItsOwnSyllables() {
        for head in PlantName.genusHeads {
            for tail in PlantName.genusTails {
                let name = PlantName(genus: head + tail, epithet: "test")
                XCTAssertEqual(name.genusHead, head, "\(head + tail)")
                XCTAssertEqual(name.genusTail, tail, "\(head + tail)")
            }
        }
    }

    /// All three thirds have to be reachable, or a subtheme is written down and
    /// never shown.
    func testAllThreeSubthemesComeUp() {
        for theme in Quotes.Theme.allCases {
            var seen: Set<Quotes.Subtheme> = []
            for index in 0..<400 {
                let genome = Genome(seed: Self.seed(index), lineage: .minted)
                seen.insert(Quotes.subtheme(of: genome, in: theme))
            }
            XCTAssertEqual(seen.count, 3, "\(theme) only ever reaches \(seen)")
        }
    }

    /// A plant's name and its theme are meant to be the same fact said twice.
    func testAPlantsThemeIsTheSenseOfItsOwnName() {
        for index in 0..<300 {
            let seed = Self.seed(index)
            let genome = Genome(seed: seed, lineage: .minted)
            let theme = Quotes.theme(of: seed)
            XCTAssertTrue(
                theme.genusHeads.contains(genome.name.genusHead),
                "\(genome.name.full) is \(theme), which does not claim \(genome.name.genusHead)"
            )
            XCTAssertTrue(genome.name.genus.hasPrefix(genome.name.genusHead))
        }
    }

    func testEveryThemeIsReachedBySomeSeed() {
        var seen: Set<Quotes.Theme> = []
        for index in 0..<600 {
            seen.insert(Quotes.theme(of: Self.seed(index)))
        }
        XCTAssertEqual(seen.count, Quotes.Theme.allCases.count, "unreached: \(Set(Quotes.Theme.allCases).subtracting(seen))")
    }

    // MARK: -

    /// Seeds that are fixed rather than random, so a failure can be reproduced
    /// from the index printed beside it.
    private static func seed(_ index: Int) -> SeedID {
        var bytes = [UInt8](repeating: 0, count: 32)
        bytes[0] = UInt8(index & 0xFF)
        bytes[1] = UInt8((index >> 8) & 0xFF)
        bytes[2] = 0x5E
        return SeedID(bytes: Data(bytes))!
    }
}
