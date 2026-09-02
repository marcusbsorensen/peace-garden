import XCTest
@testable import PeaceGarden
import SeedCore

/// What every bank has to be true of, whoever wrote it.
///
/// Each bank was written separately and against the same brief, and a brief is
/// not a guarantee. These are the parts of the brief a machine can check: that
/// no corner of a bank is thin enough to repeat itself, that a passage's theme
/// and subtheme agree, and that nobody quietly translated the English one.
final class QuoteBankTests: XCTestCase {

    /// Ten passages in every subtheme. Below that the draw repeats itself
    /// visibly, so ten is the floor rather than the target — `docs/LANGUAGES.md`
    /// sets it and every commissioning brief repeated it.
    ///
    /// The English bank did not meet it, which is the thing nobody expected to
    /// find by writing seven others: it predated the brief, and thirteen of its
    /// thirty subthemes were under ten with `quietAsASound` at five. It was
    /// filled to twelve afterwards, so the floor is now one number for all
    /// eight and there is no exception left to explain.
    ///
    /// Ten is also the real floor rather than a generous one. Italian sits on it
    /// in two subthemes; the rest of the eight clear it by one or two.
    private let floor = 10

    func testEveryBankCarriesEverySubtheme() {
        for bank in QuoteBank.allCases {
            let grouped = Dictionary(grouping: bank.passages, by: \.subtheme)
            for subtheme in Quotes.Subtheme.allCases {
                let count = grouped[subtheme]?.count ?? 0
                XCTAssertGreaterThanOrEqual(
                    count, floor,
                    "\(bank.rawValue) has \(count) passages in \(subtheme), floor is \(floor)"
                )
            }
        }
    }

    /// Four of the seven commissioned banks independently reported
    /// `quietAsASound` as their hardest subtheme — Dutch has no coinage like
    /// *psithurism*, French spends *bruissement* on silk and crowds, Swedish's
    /// quiet-words are weather and Norwegian's are water. That is some evidence
    /// it is the subtheme rather than any one language, and it is why the
    /// subtheme is named here rather than left to be rediscovered.
    func testTheHardestSubthemeIsCarriedEverywhere() {
        for bank in QuoteBank.allCases {
            let count = bank.passages.filter { $0.subtheme == .quietAsASound }.count
            XCTAssertGreaterThanOrEqual(
                count, floor, "\(bank.rawValue) has \(count) in quietAsASound"
            )
        }
    }

    /// A passage's own theme has to be the one its subtheme belongs to.
    ///
    /// Both are written out by hand on every entry, three hundred times a bank,
    /// so this is the mistake that is certain to be in there somewhere. It
    /// matters because the theme is drawn from the pair and the subtheme from
    /// the child: a passage filed under the wrong theme is reachable from a
    /// meeting it has nothing to do with.
    func testEveryPassageAgreesWithItsOwnSubtheme() {
        for bank in QuoteBank.allCases {
            for passage in bank.passages {
                XCTAssertEqual(
                    passage.subtheme.theme, passage.theme,
                    "\(bank.rawValue): \"\(passage.text)\" is filed under \(passage.theme) "
                        + "but \(passage.subtheme) belongs to \(passage.subtheme.theme)"
                )
            }
        }
    }

    func testNoBankRepeatsItself() {
        for bank in QuoteBank.allCases {
            var seen: Set<String> = []
            for passage in bank.passages where !seen.insert(passage.text).inserted {
                XCTFail("\(bank.rawValue) carries \"\(passage.text)\" twice")
            }
        }
    }

    /// Two passages in one subtheme that are the same passage differently
    /// worded.
    ///
    /// An exact-match check does not find these, and each bank is written in one
    /// sitting by somebody who cannot hold three hundred lines in their head —
    /// so a subtheme picks up two entries making the same point about the same
    /// word, and the reader who draws both is the one who notices. It is worth a
    /// machine check because round two adds twenty-five more banks and nobody
    /// will read them all.
    ///
    /// Half the interesting words in common is the threshold. Across the banks
    /// that exist the worst genuine pair sits at about 0.38, so this has room
    /// before it starts objecting to two passages that merely share a subject.
    func testNoSubthemeSaysTheSameThingTwice() {
        func interesting(_ text: String) -> Set<String> {
            Set(
                text.lowercased()
                    .components(separatedBy: CharacterSet.letters.inverted)
                    .filter { $0.count >= 4 }
            )
        }

        for bank in QuoteBank.allCases {
            for (_, group) in Dictionary(grouping: bank.passages, by: \.subtheme) {
                let words = group.map { ($0.text, interesting($0.text)) }
                for i in words.indices {
                    for j in words.indices where j > i {
                        let (oneText, one) = words[i]
                        let (otherText, other) = words[j]
                        guard !one.isEmpty, !other.isEmpty else { continue }
                        let overlap =
                            Double(one.intersection(other).count)
                            / Double(one.union(other).count)
                        XCTAssertLessThan(
                            overlap, 0.5,
                            "\(bank.rawValue) says the same thing twice:\n  \(oneText)\n  \(otherText)"
                        )
                    }
                }
            }
        }
    }

    /// Every passage says where it came from, and says it briefly.
    ///
    /// The provenance is there so a line can be trusted and looked up, not so it
    /// can be cited. A `source` that has grown into a citation is a sign
    /// somebody was arguing for a passage they should have dropped.
    func testEveryPassageCarriesItsProvenance() {
        for bank in QuoteBank.allCases {
            for passage in bank.passages {
                XCTAssertFalse(passage.text.isEmpty, "\(bank.rawValue): a passage with no text")
                XCTAssertFalse(
                    passage.source.trimmingCharacters(in: .whitespaces).isEmpty,
                    "\(bank.rawValue): \"\(passage.text)\" says nothing about where it came from"
                )
                XCTAssertLessThan(
                    passage.source.count, 90,
                    "\(bank.rawValue): the source for \"\(passage.text)\" is a citation"
                )
                // One sentence, two at the outside. The screen gives it four
                // lines at 17pt on a 402pt phone.
                XCTAssertLessThan(
                    passage.text.count, 240,
                    "\(bank.rawValue): \"\(passage.text)\" is a paragraph"
                )
            }
        }
    }

    /// A bank is a commission, not a translation.
    ///
    /// About sixty of the English passages are etymologies of English words,
    /// and those are facts *about English* — false in Dutch, and the whole
    /// reason `docs/LANGUAGES.md` says the bank cannot be translated as a class.
    /// A bank that shares many lines with the English one was translated
    /// anyway. Latin and Greek travel, and a handful of shared proverbs are
    /// honest, so this asks only that the overlap is small.
    func testNoBankIsTheEnglishOneTranslated() {
        let english = Set(Quotes.all.map(\.text))
        for bank in QuoteBank.allCases where bank != .english {
            let shared = bank.passages.filter { english.contains($0.text) }
            XCTAssertLessThan(
                Double(shared.count) / Double(bank.passages.count), 0.05,
                "\(bank.rawValue) shares \(shared.count) lines with the English bank"
            )
        }
    }

    // MARK: - Which bank a phone reads

    func testFlemishReadsTheDutchBankAndNynorskTheNorwegianOne() {
        XCTAssertEqual(QuoteBank.bank(for: "nl-BE"), .dutch)
        XCTAssertEqual(QuoteBank.bank(for: "nn-NO"), .norwegian)
        XCTAssertEqual(QuoteBank.bank(for: "no"), .norwegian)
        XCTAssertEqual(QuoteBank.bank(for: "nb-NO"), .norwegian)
        XCTAssertEqual(QuoteBank.bank(for: "en-GB"), .english)
        XCTAssertEqual(QuoteBank.bank(for: "es-419"), .spanish)
        XCTAssertEqual(QuoteBank.bank(for: "de-AT"), .german)
        XCTAssertEqual(QuoteBank.bank(for: "pt-BR"), .portuguese)
        XCTAssertEqual(QuoteBank.bank(for: "pl-PL"), .polish)
    }

    /// A language with an interface and no bank of its own reads English, and
    /// is told so.
    ///
    /// **Named languages graduate.** This asserted `cs` and `hu` until wave two
    /// wrote those two banks, at which point the test failed and the app was
    /// fine — the failure was the test naming something that was always going to
    /// change. Thirteen of the twenty-five in `docs/LANGUAGES.md` are still to
    /// come, so hard-coding any of them buys thirteen more of these.
    ///
    /// So the example is *whichever planned language has not arrived yet*, and
    /// the assertion is that one exists and reads English. The day the list is
    /// empty this test says so in its own message rather than by failing
    /// obscurely, and that is the day to retire it.
    func testALanguageWithNoBankBorrowsAndSaysSo() {
        let planned = ["cy", "ga", "eu", "gl", "sq", "is", "fo", "lb", "mt",
                       "kl", "lt", "lv", "et", "sk", "sl", "hr"]
        let waiting = planned.filter { QuoteBank(rawValue: $0) == nil }
        XCTAssertFalse(waiting.isEmpty,
                       "every planned language now has a bank — retire this test")
        for code in waiting {
            XCTAssertNil(QuoteBank.bank(for: code), "\(code) should have no bank yet")
        }

        // And the mechanism on its own, which cannot graduate: `zxx` is the ISO
        // code for no linguistic content, so nothing will ever write it a bank.
        XCTAssertNil(QuoteBank.bank(for: "zxx"))
        XCTAssertNil(QuoteBank.bank(for: "zxx-ZZ"))
    }

    // MARK: - The draw

    /// Two people on different banks draw from the same corner of the same
    /// theme, and read it each in their own language.
    ///
    /// This is the property that replaces "both phones show the same passage",
    /// which stopped being possible the moment a bank stopped being a
    /// translation. What a pair holds in common is the character of the passage
    /// rather than its words.
    func testTwoPhonesOnDifferentBanksAgreeOnTheCornerIfNotTheWords() {
        let a = SeedMint.mint(fromEntropy: Data("bank-a".utf8))
        let b = SeedMint.mint(fromEntropy: Data("bank-b".utf8))
        let encounter = Pollination.encounterID(
            seedA: a, seedB: b,
            nonceA: Data("one".utf8), nonceB: Data("two".utf8)
        )
        let child = Pollination.cross(seedA: a, seedB: b, encounterID: encounter)
        let theme = Quotes.sharedTheme(parentA: a, parentB: b)
        let subtheme = Quotes.subtheme(
            of: Genome(seed: child, lineage: .crossed(parentA: a, parentB: b, encounterID: encounter)),
            in: theme
        )

        for bank in QuoteBank.allCases {
            let drawn = Quotes.passage(
                subtheme: subtheme,
                childSeed: child,
                from: Dictionary(grouping: bank.passages, by: \.subtheme)
            )
            XCTAssertEqual(drawn.subtheme, subtheme, "\(bank.rawValue) left the subtheme")
            XCTAssertEqual(drawn.theme, theme, "\(bank.rawValue) left the theme")
        }
    }

    /// And the same phone, twice, always reads the same line.
    func testTheDrawIsSettledByTheSeedAndNothingElse() {
        let seed = SeedMint.mint(fromEntropy: Data("settled".utf8))
        for bank in QuoteBank.allCases {
            let index = Dictionary(grouping: bank.passages, by: \.subtheme)
            for subtheme in Quotes.Subtheme.allCases {
                let first = Quotes.passage(subtheme: subtheme, childSeed: seed, from: index)
                let again = Quotes.passage(subtheme: subtheme, childSeed: seed, from: index)
                XCTAssertEqual(first.text, again.text, "\(bank.rawValue) \(subtheme)")
            }
        }
    }
}
