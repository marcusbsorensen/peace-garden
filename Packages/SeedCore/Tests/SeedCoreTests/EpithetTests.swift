import XCTest
import Foundation
@testable import SeedCore

/// The epithet, held to the two things `docs/TAXONOMY.md` §2 and §3 ask of it:
/// that it be **true of the specimen**, and that it be **Latin**.
///
/// The first is testable directly — take the plants called *pendula* and check
/// that they droop — and that is most of what is below. It is worth having
/// because the failure is silent and total: an epithet that has come unhooked
/// from its trait still reads as a plausible name, and nothing on screen ever
/// says otherwise. That is exactly how the old generator produced
/// *stellifolia* for a plant with no star-shaped anything.
final class EpithetTests: XCTestCase {

    private func plants(_ count: Int, _ tag: String = "epithet") -> [Genome] {
        (0..<count).map { Genome(seed: SeedMint.mint(fromEntropy: Data("\(tag)-\($0)".utf8))) }
    }

    // MARK: - It has to be true

    /// Every plant that claims a foliage character has it.
    ///
    /// Checked against the same positions the epithet was chosen from, which
    /// would be circular if it were only that — so each one also asserts the
    /// *finished trait* sits on the right side of its genus, which is the thing
    /// a person looking at the plant would check.
    func testAFoliageEpithetIsTrueOfTheLeaves() {
        var checked = 0
        for genome in plants(6_000) {
            let source = GeneSource.primary(genome.seed)
            let profile = ArchetypeProfile.profile(for: genome.form.archetype)
            switch genome.name.epithet {
            case "longifolia", "longifolius":
                XCTAssertGreaterThanOrEqual(source.position("foliage.length"), 1 - Epithet.floor)
                // Long against its own genus, which is what the name claims.
                XCTAssertGreaterThan(genome.foliage.length, 0.21 * profile.leafLengthScale)
                checked += 1
            case "brevifolia", "brevifolius":
                XCTAssertLessThanOrEqual(source.position("foliage.length"), Epithet.floor)
                XCTAssertLessThan(genome.foliage.length, 0.13 * profile.leafLengthScale)
                checked += 1
            case "angustifolia", "angustifolius":
                XCTAssertLessThan(genome.foliage.widthRatio, 0.30 * profile.leafWidthScale)
                checked += 1
            case "latifolia", "latifolius":
                XCTAssertGreaterThan(genome.foliage.widthRatio, 0.70 * profile.leafWidthScale)
                checked += 1
            case "serratifolia", "serratifolius":
                XCTAssertGreaterThan(genome.foliage.serration, 0.6)
                checked += 1
            case "integrifolia", "integrifolius":
                XCTAssertLessThan(genome.foliage.serration, 0.4)
                checked += 1
            case "pendula", "pendulus":
                XCTAssertGreaterThan(genome.foliage.droop, 0.55 * profile.leafDroop)
                checked += 1
            default:
                break
            }
        }
        XCTAssertGreaterThan(checked, 400, "too few foliage epithets to have tested anything")
    }

    /// Every plant that claims a colour has it. Colour is absolute — see
    /// `Epithet`'s note on why it is not measured against the genus.
    func testAColourEpithetIsTrueOfTheColour() {
        var checked = 0
        for genome in plants(6_000) {
            let petal = genome.palette.petalBase
            switch genome.name.epithet {
            case "pallida", "pallidus":
                XCTAssertGreaterThan(petal.brightness, 0.75)
                XCTAssertLessThan(petal.saturation, 0.30)
                checked += 1
            case "obscura", "obscurus":
                XCTAssertLessThan(petal.brightness, 0.479)
                checked += 1
            case "aurea", "aureus":
                XCTAssertTrue((0.10...0.18).contains(petal.hue), "hue \(petal.hue) is not gold")
                checked += 1
            case "caerulea", "caeruleus":
                XCTAssertTrue((0.58...0.78).contains(petal.hue), "hue \(petal.hue) is not blue")
                checked += 1
            case "rubra", "ruber":
                XCTAssertTrue(petal.hue > 0.95 || petal.hue < 0.035, "hue \(petal.hue) is not red")
                checked += 1
            case "variegata", "variegatus":
                XCTAssertNotEqual(genome.palette.variegation, .none)
                checked += 1
            case "marginata", "marginatus":
                XCTAssertNotNil(genome.palette.picotee)
                checked += 1
            case "marmorata", "marmoratus":
                XCTAssertNotEqual(genome.palette.marbling, .none)
                checked += 1
            case "noctiflora", "noctiflorus":
                XCTAssertFalse(genome.tempo.opensByDay, "a noctiflora that opens by day")
                checked += 1
            default:
                break
            }
        }
        XCTAssertGreaterThan(checked, 400, "too few colour epithets to have tested anything")
    }

    /// **The one that would have caught the old generator.** No plant is ever
    /// given a name for something it has not got.
    ///
    /// The old epithet was two syllables glued together from separate draws, so
    /// *stellifolia* — star-leaved — landed on plants with no star-shaped
    /// anything, and *pallicola* meant pale-dwelling, which is not a thing.
    /// This asserts the property that was missing rather than the symptom: a
    /// claim about the leaves is only made when the leaves are unusual.
    func testNoPlantIsNamedForSomethingItHasNot() {
        for genome in plants(4_000, "unhooked") {
            let source = GeneSource.primary(genome.seed)
            let name = genome.name.epithet
            guard name != "vulgaris" else { continue }

            if name.hasSuffix("folia") || name.hasSuffix("folius") {
                let unusual = [source.position("foliage.length"),
                               source.position("foliage.widthRatio"),
                               source.bellPosition("foliage.serration"),
                               source.position("foliage.pitch")]
                    .contains { $0 <= Epithet.floor || $0 >= 1 - Epithet.floor }
                XCTAssertTrue(unusual, "\(genome.name.full) claims a leaf character it has not got")
            }
        }
    }

    // MARK: - It has to be Latin

    /// The epithet agrees in gender with the genus it stands beside.
    ///
    /// *Aurelia nocturna*, never *Aurelia nocturnum* — the single most visible
    /// tell to anybody who has read a flora, and the reason `-ynth` had to be
    /// decided rather than left.
    func testTheEpithetAgreesWithItsGenus() {
        var masculine = 0
        for genome in plants(6_000) {
            let expected = Epithet.Gender.of(genusTail: genome.name.genusTail)
            if expected == .masculine {
                masculine += 1
                XCTAssertFalse(genome.name.epithet.hasSuffix("a"),
                               "\(genome.name.full) is masculine and its epithet is not")
            }
        }
        // One ending in ten is `-ynth`, so agreement is visible in the garden
        // rather than only in this file.
        XCTAssertGreaterThan(masculine, 300, "no masculine genera were drawn")
    }

    /// Both genders of every form are real words, and the irregular one is
    /// irregular in the right direction.
    func testTheIrregularFormsAreWrittenOutRatherThanDerived() {
        XCTAssertEqual(Epithet.Form("rubra", "ruber").masculine, "ruber")
        XCTAssertEqual(Epithet.Form("rubra", "ruber").feminine, "rubra")
        // Third-declension adjectives do not decline for gender at all.
        XCTAssertEqual(Epithet.ordinary.feminine, Epithet.ordinary.masculine)
        XCTAssertEqual(Epithet.Form.invariant("crassicaulis").masculine, "crassicaulis")
        // The regular pattern, for everything else.
        XCTAssertEqual(Epithet.Form("pallid").feminine, "pallida")
        XCTAssertEqual(Epithet.Form("pallid").masculine, "pallidus")
    }

    // MARK: - The floor

    /// The ordinary plant is ordinary often enough to mean something, and not
    /// so often that the garden is full of one name.
    ///
    /// This is the shape of the answer to §3's third question. Naming *the
    /// extreme* would put this at zero, and every plant would carry a
    /// superlative about a middling trait.
    func testAboutOnePlantInTenHasNothingRemarkableAboutIt() {
        let all = plants(8_000)
        let ordinary = all.filter { $0.name.epithet == "vulgaris" }.count
        let share = Double(ordinary) / Double(all.count)
        // About one plant in fifty, which is lower than it first looks like it
        // should be and is right. Twenty-four characters between them cover a
        // lot of ground, so a plant with *nothing* in any tail and no marking
        // at all is genuinely rare. The floor is still doing its work one
        // character at a time: every claim made is true of the top eighth.
        XCTAssertGreaterThan(share, 0.005, "nothing is ordinary — the floor has stopped biting")
        XCTAssertLessThan(share, 0.20, "too much of the garden is vulgaris")
    }

    /// Every epithet in the vocabulary is reachable, and none of them runs away
    /// with the garden.
    ///
    /// A character whose threshold is wrong fails silently in one of two ways —
    /// it is never said, or it is said of everything — and both look like a
    /// working name generator from the outside.
    func testEveryEpithetIsReachableAndNoneDominates() {
        var counts: [String: Int] = [:]
        let all = plants(12_000, "reach")
        for genome in all { counts[genome.name.epithet, default: 0] += 1 }

        XCTAssertGreaterThan(counts.count, 24, "only \(counts.count) distinct epithets")
        for (word, count) in counts {
            let share = Double(count) / Double(all.count)
            XCTAssertLessThan(share, 0.25, "\(word) is \(Int(share * 100))% of the garden")
        }
    }

    /// The declared rates are still the real ones.
    ///
    /// `Epithet.Rate` is a table of measurements, and a measurement of a thing
    /// that has since been retuned is a lie the compiler cannot see. The rates
    /// order the whole vocabulary — they are what stops *variegata* eating a
    /// third of the garden — so a palette change that moves one of them has to
    /// fail here rather than quietly restoring that bug.
    ///
    /// The tolerance is wide on purpose. This is a guard against a rate having
    /// *moved*, not a pin on the fourth decimal place of a sample.
    func testTheDeclaredRatesAreTheRealOnes() {
        let all = plants(12_000, "rate")
        func measured(_ predicate: (Genome) -> Bool) -> Double {
            Double(all.filter(predicate).count) / Double(all.count)
        }
        let declared: [(String, Double, (Genome) -> Bool)] = [
            ("variegation", Epithet.Rate.variegation, { $0.palette.variegation != .none }),
            ("marbling", Epithet.Rate.marbling, { $0.palette.marbling != .none }),
            ("night", Epithet.Rate.night, { !$0.tempo.opensByDay }),
            ("leafy", Epithet.Rate.leafy, { $0.leafCount >= 15 }),
            ("picotee", Epithet.Rate.picotee, { $0.palette.picotee != nil }),
            ("vivid", Epithet.Rate.vivid, { $0.palette.petalBase.saturation > 0.888 }),
            ("dark", Epithet.Rate.dark, { $0.palette.petalBase.brightness < 0.479 }),
            ("veined", Epithet.Rate.veined, { $0.palette.veining > 0.546 }),
        ]
        for (name, claimed, predicate) in declared {
            let actual = measured(predicate)
            XCTAssertEqual(actual, claimed, accuracy: 0.05,
                           "Epithet.Rate.\(name) says \(claimed), the garden says \(actual)")
        }
    }

    /// Every character in the vocabulary can actually happen.
    ///
    /// **Three could not, when the thresholds were guessed** — *pallida*,
    /// *obscura* and *venosa* asked for petal brightness and veining outside
    /// the ranges those traits are drawn in, so they were dead words in a
    /// vocabulary that otherwise worked. Nothing said so: the other epithets
    /// simply covered for them.
    func testNoWordInTheVocabularyIsDead() {
        var seen: Set<String> = []
        for genome in plants(12_000, "dead") { seen.insert(genome.name.epithet) }
        let mustAppear = ["pallida", "obscura", "venosa", "vivida", "aurea", "caerulea",
                          "rubra", "variegata", "marmorata", "marginata", "noctiflora",
                          "foliosa", "paniculata", "gracilis", "crassicaulis", "nana",
                          "elata", "declinata", "contorta", "pendula", "longifolia",
                          "brevifolia", "angustifolia", "latifolia", "vulgaris"]
        for word in mustAppear {
            XCTAssertTrue(seen.contains(word), "\(word) is in the vocabulary and never said")
        }
    }
}
