#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// The one plant that stands for an area, and the ten of them.
/// `docs/WEBSITE.md` §*The ambassador plants*.
///
/// **An ambassador is a real plant, not an illustration.** It grows from a real
/// seed, and the same derivation that draws every other plant on the site draws
/// this one: nothing is special-cased in the renderer and nothing is
/// hand-authored. What is pinned is the seed, because a seed is the whole of a
/// plant.
///
/// **They belong to the garden rather than to anybody.** Nobody put them there,
/// no name attaches to them, no report can be filed against them, and they do
/// not appear in anybody's garden. Nothing here touches a person's own seed,
/// their own garden, or an exchange between two people — it is a property of
/// the shared place, found by a visitor, and the app never mentions it.
///
/// **What a visitor can learn from one is its name.** The proposal was that an
/// ambassador teaches you to recognise an area's plants by eye, and measured
/// over four thousand seeds it cannot: the area explains under 1% of the
/// variance in height, petal count, leaf count or hue, because the name and the
/// shape are drawn from the same seed by separate draws. The key that does work
/// needs nothing built — twenty-four genus syllables over ten areas, so a
/// visitor who learns *Zeph-*, *Ael-* and *Hal-* can read any plant on the site
/// as travel. *Halula crassicaulis* standing in the Long Walk says so without a
/// sentence of explanation.
public enum Ambassadors {

    /// **The day all ten were sown**, a month before the garden opened.
    ///
    /// One date for the ten, the way a gardener sows a batch. A month because
    /// the slowest of them takes a little over three weeks to reach maturity
    /// and the garden should not have opened onto a bed of seedlings;
    /// `AmbassadorTests` holds every one of the ten to being mature on opening
    /// day, so the margin is checked rather than assumed.
    ///
    /// They go on ageing from here, which is the point: an ambassador is the
    /// oldest plant in its area and flowers in its own cycle like every other.
    public static let sown = Date(timeIntervalSince1970: 1_787_184_000)  // 20 August 2026

    /// The day the garden first had a visitor, which is what `sown` is a month
    /// before. Kept here so the margin has something to be a margin from.
    public static let gardenOpened = Date(timeIntervalSince1970: 1_789_862_400)  // 20 September 2026

    /// **How the ten were found.** Minted in order from a fixed label until one
    /// landed on each area, keeping the first hit for each — which is a search,
    /// not a choice. `AmbassadorTests` runs it again and checks it arrives at
    /// these same ten, so nothing here can quietly become hand-picked.
    ///
    /// The tenth took eighty-two tries, which is the Quiet Garden being one of
    /// the six areas with two genus syllables rather than three.
    public static func candidate(_ n: Int) -> SeedID {
        SeedID(bytes: seedDigest(SeedDomain.seed, Data("peace-garden.ambassador.v1/\(n)".utf8)))!
    }

    /// The pinned seed for each area, in the order the areas are declared.
    ///
    /// Hexes rather than the search, because a search is a thing that can
    /// change: `Genome`'s naming moving by one byte would silently repopulate
    /// every area of the garden with different plants. These are the ten, and
    /// if the derivation moves, the test that reproduces them fails and
    /// somebody decides what that means.
    public static let seeds: [Area: SeedID] = [
        .beginnings: seed("526ffb12041c8641eead7cb97614517436806c5748c3f581754dd102738719ae"),
        .waiting: seed("8c0992d3e4221b40489b83d05c0ec3131fc8c771365970ffbb1354a93431ff3f"),
        .renewal: seed("c295b64b290a2e9b3c6ece6c70dafb1816205f60f42a0663e47bfb738b30d292"),
        .light: seed("53b234ab46f50e06243314d3d6159c67d0b26b2c0bc44a5fcd4b83ad28c4bc41"),
        .pattern: seed("75121838c745b4c11d8c34bdf4492890833a1a8ca768942ef26cbbbba7a74b7b"),
        .ground: seed("540d870092386fc9a3e5611499390c1de91fbadddf276bc6ef6eec73dc30326d"),
        .travel: seed("be9dd17805ea1ebab2c56695b13158adb8d985f165564c10804961b543c12d3c"),
        .meeting: seed("9bca751433cf86be586c46b3b6582a504fb4df133036321ce000f066e13d7284"),
        .kinship: seed("ec0850ec7cd6824077a0c51e3c4c8cc670b321bdf66b8eb8f338fff81deb6bf3"),
        .peace: seed("2d1894df5b3f19d3d1c4a12cae8e8d7334a07f942ba60903d37846a190faa4eb"),
    ]

    /// The ambassador of an area. Every area has one, including the nine whose
    /// layouts are still on paper — a seed costs nothing to pin and the area
    /// that opens next should not have to go looking for its plant.
    public static func of(_ area: Area) -> Ambassador {
        Ambassador(area: area, seed: seeds[area]!, sown: sown)
    }

    /// All ten, in the order the areas are declared.
    public static var all: [Ambassador] { Area.allCases.map(of) }

    private static func seed(_ hex: String) -> SeedID {
        guard let id = SeedID(hex: hex) else {
            preconditionFailure("an ambassador's hex is not a seed: \(hex)")
        }
        return id
    }
}

/// One area's ambassador: the seed, the day it was sown, and the area it stands
/// in — which is also the area its own name says, and `AmbassadorTests` holds
/// it to that.
public struct Ambassador: Equatable, Sendable {
    public let area: Area
    public let seed: SeedID
    public let sown: Date

    public init(area: Area, seed: SeedID, sown: Date) {
        self.area = area
        self.seed = seed
        self.sown = sown
    }

    /// The plant. Minted rather than crossed: an ambassador has no parents,
    /// because nobody met to make it.
    public var genome: Genome { Genome(seed: seed) }

    public func growth(now: Date = Date()) -> GrowthModel.State {
        GrowthModel(genome: genome).state(birth: sown, now: now)
    }
}
