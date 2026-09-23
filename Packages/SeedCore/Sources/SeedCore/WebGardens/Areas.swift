#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// The ten areas of the shared garden, and which of them a plant can stand in
/// today. `docs/WEB-GARDENS.md`.
///
/// **An area is a theme with a layout.** The themes are the app's — a plant's
/// comes from its genus head, and the same ten order the passages — and each
/// one is laid out as the kind of garden its name is: the Knot Garden as a
/// knot garden, the Orchard on a quincunx, the Long Walk as a double border
/// either side of a mown path. The layout is the one that kind of garden has
/// always had, which is the whole of what best practice means here.
///
/// **This type exists because the service needed to be able to say no.** Until
/// now the plot service was a Long Walk service: one table, one rule, and a
/// plant went into it whatever it was. A garden of ten areas can only be built
/// one area at a time, so there has to be somewhere that says which ones are
/// finished — and a gardener whose plant belongs to an unbuilt one has to be
/// told that, rather than having it quietly put somewhere else.
///
/// It lives in SeedCore so the phone, the website and the plot service read one
/// list. `Server/.api/Areas.php` is the port and `tools/reference/check_areas.php`
/// holds it to this.
public enum Area: String, CaseIterable, Sendable, Codable {
    case beginnings, waiting, renewal, light, pattern
    case ground, travel, meeting, kinship, peace

    /// **Whether a plant can stand here yet.**
    ///
    /// Seven of ten. The Long Walk was built first because its rule is the
    /// plainest best practice there is — tall at the back, drifts, repetition —
    /// and because its plots open end to end, so the map is a line before it
    /// has to be a shape (`docs/WEB-GARDENS.md` §*What has to exist first*).
    /// The Quiet Garden was built second, on 21 September, because its rule is
    /// the opposite one — the fewest plants per plot of any area — and a
    /// second area that only repeated the first would not have told us whether
    /// a template is a thing this garden can have two of.
    ///
    /// The Crossing was built third, the same day, because it is the first
    /// whose plot is not one bed: four quarters that have to be kept level with
    /// each other, and the first structure in the garden that is neither hedge
    /// nor bench.
    ///
    /// The Orchard was built fourth, on 21 September, because its rule is the
    /// Crossing's inside out — one guild finished before the next is begun,
    /// where the Crossing shares every arrival out to keep four beds level. A
    /// fourth area that levelled its plot again would have tested nothing; this
    /// one asks whether the template survives a rule that leaves half the plot
    /// deliberately bare. It is also the first area holding a structure taller
    /// than anything a gardener can grow.
    ///
    /// The Knot Garden was built fifth, on 22 September, because it is the
    /// first area whose rule reads something other than a height. Four areas
    /// have now graded by height alone, and a template that could only ever ask
    /// one question of a plant would be a template for one kind of garden. This
    /// one asks a plant's colour first and its height second, which is what a
    /// knot garden is: symmetrical in colour, graded in height.
    ///
    /// The Seedbed was built sixth, on 23 September, because it is the first
    /// rule that groups by sameness rather than sorting by difference.
    ///
    /// The Cold Frame was built seventh, on 23 September, because it is the
    /// first area that draws a plant as something other than what it will
    /// be: every plant young, placed by the height it will grow to.
    ///
    /// **An area is open when it has a placement rule, not when it has a
    /// name.** All ten have names, layouts on paper and a place on the map.
    /// What the other three do not have is a rule that says which slot an
    /// arriving plant takes and never moves it, which is what makes a garden
    /// curated rather than scattered.
    public var isOpen: Bool {
        self == .travel || self == .peace || self == .meeting
            || self == .kinship || self == .pattern || self == .beginnings
            || self == .waiting
    }

    /// The areas a plant can be offered to today.
    public static var open: [Area] { allCases.filter(\.isOpen) }

    /// What the service calls this area's plantings.
    ///
    /// **A table for each, rather than one table with an area column.** Two
    /// reasons, and the second is the one that decided it. A table of plantings
    /// with an `area` column would hold rows whose meaning depends on that
    /// column — `plot`, `side`, `tier` and `slot_index` mean a double border on
    /// a travel row and would mean a compartment and a quarter on a knot garden
    /// row — which is a table pretending to be ten tables. And the Long Walk's
    /// table is **live and append-only**: adding a column to it is a migration
    /// against real plantings, where adding an area is a new table beside it
    /// and cannot touch what is already planted.
    public var table: String {
        switch self {
        case .travel: return "long_walk"
        case .peace: return "quiet_garden"
        case .meeting: return "crossing"
        case .kinship: return "orchard"
        case .pattern: return "knot_garden"
        case .beginnings: return "seedbed"
        case .waiting: return "cold_frame"
        // The five that are not open have no table, and a name for one here
        // would be a promise about a schema nobody has designed. They get one
        // when they get a rule.
        default: return ""
        }
    }

    // MARK: Which area a plant is

    /// The genus syllables that mean this area.
    ///
    /// **This is the table the app used to hold**, moved here on 20 September
    /// for one reason: the website has to file a plant into an area, and the
    /// website is this package compiled to wasm rather than the app. Leaving
    /// the syllables in `Quotes.Theme` meant the one place that needed to know
    /// which area a plant belongs to could not be told — and copying them
    /// would be two tables that agree until the day they do not.
    ///
    /// Every one of `PlantName.genusHeads` appears exactly once across the
    /// ten, which is what makes `init(genusHead:)` total. The list is frozen —
    /// see `PlantName.genusHeads` for why a twenty-fifth syllable cannot
    /// simply be added — so the areas were fitted to the syllables rather than
    /// the syllables chosen for the areas. Four areas take three heads and six
    /// take two, which leaves a plant half again as likely to be born to the
    /// Seedbed as to the Quiet Garden. Documented rather than corrected:
    /// correcting it means either renaming every plant that exists or
    /// weighting the draw, and a weighted draw would break the one thing this
    /// design is for, which is that the name and the area are the same fact
    /// said twice.
    public var genusHeads: [String] {
        switch self {
        case .beginnings: return ["Thal", "Lir", "Ver"]   // a shoot, a lily, the spring
        case .waiting:    return ["Nyx", "Umbr"]          // night, shade
        case .renewal:    return ["Dros", "Ros"]          // dew, and dew again
        case .light:      return ["El", "Aur", "Sel"]     // sun, dawn, moon
        case .pattern:    return ["Cal", "Quin"]          // the shapely, the five
        case .ground:     return ["Cer", "Fen", "Pell"]   // grain, fen, the earth's skin
        case .travel:     return ["Zeph", "Ael", "Hal"]   // west wind, gust, salt sea
        case .meeting:    return ["Mel", "Ith"]           // honey, Ithaca
        case .kinship:    return ["Vin", "Cyn"]           // a bond, the dog at the door
        case .peace:      return ["Ol", "Bel"]            // the olive, a clear sky
        }
    }

    /// The area a plant's name says it belongs to.
    ///
    /// Total by construction, and defended by `AreaVectorTests`: every head is
    /// claimed once, and none twice.
    public init(genusHead: String) {
        self = Area.allCases.first { $0.genusHeads.contains(genusHead) } ?? .beginnings
    }

    /// The area a plant belongs to, read off the plant.
    ///
    /// **The plant's own name, not the one its seed would mint.** A hybrid's
    /// traits are drawn from its parents, so the same child seed minted afresh
    /// is a different plant with a different name — over fourteen crossings
    /// drawn for the mockup, all fourteen genus heads differed. Taking the
    /// genome's own name is the only reading that files a plant where its
    /// label says it stands.
    public init(genome: Genome) {
        self.init(genusHead: genome.name.genusHead)
    }

    /// **An area this version has never heard of reads as the Long Walk.**
    ///
    /// The same rule `Standing` follows and for the same reason: a payload
    /// written by a newer version must decode rather than throw, or one unknown
    /// word discards whatever it was part of. The fallback is the Long Walk
    /// because that is what an absent area means to the service too — one rule
    /// in two places rather than two that can differ.
    ///
    /// It is a fallback and not a guess: an area named here and unknown to this
    /// build is an area built after it, and a phone that cannot place a plant
    /// is better off treating it as the one area that has always existed than
    /// refusing to read the record at all.
    public init(from decoder: any Decoder) throws {
        let named = try decoder.singleValueContainer().decode(String.self)
        self = Area(rawValue: named) ?? .travel
    }
}
