import Foundation
import SeedCore

/// The words the app puts on things `SeedCore` only has names for.
///
/// `SeedCore` is a model package with no interface in it and no bundle of its
/// own worth localising: its `displayName`s are English identifiers for a stage
/// and a plant form, useful in a log and in the developer panel, and they are
/// left exactly as they are. Everything a person reads is looked up here
/// instead, against the app's `Localizable.xcstrings`, so there is one
/// catalogue rather than one per package.
///
/// Written as a `switch` over literals rather than as a table keyed on
/// `displayName`, so that the compiler extracts each string and a translator
/// sees them all. A lookup built from a runtime string extracts nothing.

// MARK: - What a plant is doing

extension GrowthModel.Stage {
    var label: LocalizedStringResource {
        switch self {
        case .germinating: return "Germinating"
        case .seedling: return "Seedling"
        case .growing: return "Growing"
        case .budding: return "In bud"
        case .blooming: return "In bloom"
        case .mature: return "Mature"
        }
    }
}

extension GrowthModel.State {
    /// The caption under a plant: what it is doing, and how long until it does
    /// the next thing.
    ///
    /// **The stage is no longer lowercased on its way in.** It used to be —
    /// `summary()` in `SeedCore` still does it — which was invisible here
    /// because every site that draws this caption puts it through
    /// `chromeLabel`, and that uppercases. It stops being invisible in a
    /// language that writes its nouns with a capital, or one that is on
    /// `Chrome.keepsWrittenCase` and is not uppercased at all. The stage
    /// arrives in the case its translator wrote it in.
    ///
    /// The interval is `DateComponentsFormatter`'s, which is localised by the
    /// system: nothing here has to know that Dutch says *3 dagen*.
    func caption(formatter: DateComponentsFormatter = .growthDefault) -> String {
        let stageName = String(localized: stage.label)
        guard let timeToNextStage, stage != .mature else { return stageName }
        let remaining = formatter.string(from: max(60, timeToNextStage)) ?? ""
        return String(
            localized: "stage.caption",
            defaultValue: "\(stageName) · \(remaining)",
            comment: "Under a plant. First the growth stage, then how long until the next one."
        )
    }
}

// MARK: - What kind of plant it is

extension Archetype {
    var label: LocalizedStringResource {
        switch self {
        case .spire: return "Spire"
        case .umbel: return "Umbel"
        case .fern: return "Fern"
        case .orchid: return "Orchid"
        case .lotus: return "Lotus"
        case .thistle: return "Thistle"
        case .vine: return "Vine"
        case .bell: return "Bell"
        case .star: return "Star"
        case .poppy: return "Poppy"
        case .succulent: return "Succulent"
        case .plume: return "Plume"
        case .reed: return "Reed"
        case .cushion: return "Cushion"
        }
    }
}

// MARK: - What a name says

/// The words `NameMeaningView` sets, which are the website's words.
///
/// **Keyed, rather than written as their English** like everything above. Two
/// reasons, and the first would have been enough on its own: *Light* is already
/// a key — the light appearance in Settings — and a theme called Light filed
/// under the same five letters would have been handed that translation. The
/// second is that these are the site's own entries, its `meaning*` and `area*`
/// keys and the part labels in `meanings.js`, and a key that says which one it
/// is lets whoever fills a language find the site's version before writing a
/// second.
///
/// The site keeps each theme as one line, *Waiting: what is held back…*, and
/// the sheet sets it as a headword and a definition. It is split here, at the
/// colon, rather than when it is drawn: a colon is not where every language
/// puts that break, and French puts a space in front of it.
extension Quotes.Theme {
    /// The theme as a dictionary headword.
    var headword: LocalizedStringResource {
        switch self {
        case .waiting:
            return LocalizedStringResource("theme.waiting", defaultValue: "Waiting",
                comment: "A theme's name, set as a dictionary headword above its definition on the screen that explains a plant's name. A noun: the act of waiting.")
        case .ground:
            return LocalizedStringResource("theme.ground", defaultValue: "Ground",
                comment: "A theme's name, set as a dictionary headword above its definition on the screen that explains a plant's name. The earth, and ground that is one's own.")
        case .beginnings:
            return LocalizedStringResource("theme.beginnings", defaultValue: "Beginnings",
                comment: "A theme's name, set as a dictionary headword above its definition on the screen that explains a plant's name.")
        case .renewal:
            return LocalizedStringResource("theme.renewal", defaultValue: "Renewal",
                comment: "A theme's name, set as a dictionary headword above its definition on the screen that explains a plant's name.")
        case .travel:
            return LocalizedStringResource("theme.travel", defaultValue: "Travel",
                comment: "A theme's name, set as a dictionary headword above its definition on the screen that explains a plant's name. A noun.")
        case .peace:
            return LocalizedStringResource("theme.peace", defaultValue: "Peace",
                comment: "A theme's name, set as a dictionary headword above its definition on the screen that explains a plant's name.")
        case .kinship:
            return LocalizedStringResource("theme.kinship", defaultValue: "Kinship",
                comment: "A theme's name, set as a dictionary headword above its definition on the screen that explains a plant's name.")
        case .pattern:
            return LocalizedStringResource("theme.pattern", defaultValue: "Pattern",
                comment: "A theme's name, set as a dictionary headword above its definition on the screen that explains a plant's name. Order in living things, not a sewing pattern.")
        case .light:
            return LocalizedStringResource("theme.light", defaultValue: "Light",
                comment: "A theme's name, set as a dictionary headword above its definition on the screen that explains a plant's name. The noun, as in sunlight. Not the light appearance in Settings.")
        case .meeting:
            return LocalizedStringResource("theme.meeting", defaultValue: "Meeting",
                comment: "A theme's name, set as a dictionary headword above its definition on the screen that explains a plant's name. Two coming together, not an appointment.")
        }
    }

    /// What the theme holds, as the line after a headword: lower case, and a
    /// phrase rather than a sentence, the way a dictionary gives it.
    var definition: LocalizedStringResource {
        switch self {
        case .waiting:
            return LocalizedStringResource("theme.waiting.definition",
                defaultValue: "what is held back until its time, however long that is, and whoever keeps watch.",
                comment: "The definition under the headword 'Waiting'. The website says the same after 'Waiting:' (key meaningWaiting).")
        case .ground:
            return LocalizedStringResource("theme.ground.definition",
                defaultValue: "the earth a plant stands in, and the earth that is yours.",
                comment: "The definition under the headword 'Ground'. The website says the same after 'Ground:' (key meaningGround).")
        case .beginnings:
            return LocalizedStringResource("theme.beginnings.definition",
                defaultValue: "the first thing a seed does, and how much comes of it.",
                comment: "The definition under the headword 'Beginnings'. The website says the same after 'Beginnings:' (key meaningBeginnings).")
        case .renewal:
            return LocalizedStringResource("theme.renewal.definition",
                defaultValue: "what is cut back and comes again, and what is mended.",
                comment: "The definition under the headword 'Renewal'. The website says the same after 'Renewal:' (key meaningRenewal).")
        case .travel:
            return LocalizedStringResource("theme.travel.definition",
                defaultValue: "the ways a seed and a person go, and the pull of somewhere else.",
                comment: "The definition under the headword 'Travel'. The website says the same after 'Travel:' (key meaningTravel).")
        case .peace:
            return LocalizedStringResource("theme.peace.definition",
                defaultValue: "the quiet a garden is for, and the ease that comes with it.",
                comment: "The definition under the headword 'Peace'. The website says the same after 'Peace:' (key meaningPeace).")
        case .kinship:
            return LocalizedStringResource("theme.kinship.definition",
                defaultValue: "what grows together, and the people kept rather than happened upon.",
                comment: "The definition under the headword 'Kinship'. The website says the same after 'Kinship:' (key meaningKinship).")
        case .pattern:
            return LocalizedStringResource("theme.pattern.definition",
                defaultValue: "the order in living things, and the names given to order.",
                comment: "The definition under the headword 'Pattern'. The website says the same after 'Pattern:' (key meaningPattern).")
        case .light:
            return LocalizedStringResource("theme.light.definition",
                defaultValue: "what a plant turns towards, and the day it keeps time by.",
                comment: "The definition under the headword 'Light'. The website says the same after 'Light:' (key meaningLight).")
        case .meeting:
            return LocalizedStringResource("theme.meeting.definition",
                defaultValue: "two coming together at the right moment, and what each owes the other.",
                comment: "The definition under the headword 'Meeting'. The website says the same after 'Meeting:' (key meaningMeeting).")
        }
    }
}

/// The areas of the shared garden, by the names the website's map gives them.
///
/// **Named, not translated.** `tools/strings/NAMING.md` is the brief the site
/// commissions these under, and a language that has them there has them here.
extension Area {
    var label: LocalizedStringResource {
        switch self {
        case .waiting:
            return LocalizedStringResource("area.waiting", defaultValue: "The Cold Frame",
                comment: "A place in the shared garden, where plants of the theme Waiting stand. A name, not a description: use the website's name for it (key areaWaiting; the brief is tools/strings/NAMING.md).")
        case .ground:
            return LocalizedStringResource("area.ground", defaultValue: "The Home Ground",
                comment: "A place in the shared garden, where plants of the theme Ground stand. A name, not a description: use the website's name for it (key areaGround; the brief is tools/strings/NAMING.md).")
        case .beginnings:
            return LocalizedStringResource("area.beginnings", defaultValue: "The Seedbed",
                comment: "A place in the shared garden, where plants of the theme Beginnings stand. A name, not a description: use the website's name for it (key areaBeginnings; the brief is tools/strings/NAMING.md).")
        case .renewal:
            return LocalizedStringResource("area.renewal", defaultValue: "The Coppice",
                comment: "A place in the shared garden, where plants of the theme Renewal stand. A name, not a description: use the website's name for it (key areaRenewal; the brief is tools/strings/NAMING.md).")
        case .travel:
            return LocalizedStringResource("area.travel", defaultValue: "The Long Walk",
                comment: "A place in the shared garden, where plants of the theme Travel stand. A name, not a description: use the website's name for it (key areaTravel; the brief is tools/strings/NAMING.md).")
        case .peace:
            return LocalizedStringResource("area.peace", defaultValue: "The Quiet Garden",
                comment: "A place in the shared garden, where plants of the theme Peace stand. A name, not a description: use the website's name for it (key areaPeace; the brief is tools/strings/NAMING.md).")
        case .kinship:
            return LocalizedStringResource("area.kinship", defaultValue: "The Orchard",
                comment: "A place in the shared garden, where plants of the theme Kinship stand. A name, not a description: use the website's name for it (key areaKinship; the brief is tools/strings/NAMING.md).")
        case .pattern:
            return LocalizedStringResource("area.pattern", defaultValue: "The Knot Garden",
                comment: "A place in the shared garden, where plants of the theme Pattern stand. A name, not a description: use the website's name for it (key areaPattern; the brief is tools/strings/NAMING.md).")
        case .light:
            return LocalizedStringResource("area.light", defaultValue: "The Glasshouse",
                comment: "A place in the shared garden, where plants of the theme Light stand. A name, not a description: use the website's name for it (key areaLight; the brief is tools/strings/NAMING.md).")
        case .meeting:
            return LocalizedStringResource("area.meeting", defaultValue: "The Crossing",
                comment: "A place in the shared garden, where plants of the theme Meeting stand. A name, not a description: use the website's name for it (key areaMeeting; the brief is tools/strings/NAMING.md).")
        }
    }
}

/// A theme's three parts, as `meanings.js` labels them.
///
/// The site keeps these as English data rather than catalogue keys, and says
/// that moving them into a catalogue is mechanical once they are commissioned.
/// The app has nowhere to keep English-only data that a translator would not
/// see, so here they are keys from the start, falling back to the English
/// until somebody writes them.
extension Quotes.Subtheme {
    var label: LocalizedStringResource {
        switch self {
        case .theFirstAct:
            return LocalizedStringResource("subtheme.theFirstAct", defaultValue: "The first act",
                comment: "One of the three parts of the theme Beginnings: germination, the first root. Listed on the screen that explains a plant's name.")
        case .smallToLarge:
            return LocalizedStringResource("subtheme.smallToLarge", defaultValue: "Small to large",
                comment: "One of the three parts of the theme Beginnings: the acorn and the oak. Listed on the screen that explains a plant's name.")
        case .whatAStartSettles:
            return LocalizedStringResource("subtheme.whatAStartSettles", defaultValue: "What a start settles",
                comment: "One of the three parts of the theme Beginnings: what a beginning decides about everything after it. Listed on the screen that explains a plant's name.")
        case .heldBack:
            return LocalizedStringResource("subtheme.heldBack", defaultValue: "Held back",
                comment: "One of the three parts of the theme Waiting: dormancy, a seed that will not germinate yet. Listed on the screen that explains a plant's name.")
        case .theLongCount:
            return LocalizedStringResource("subtheme.theLongCount", defaultValue: "The long count",
                comment: "One of the three parts of the theme Waiting: very long waits, seeds that germinated after centuries. Listed on the screen that explains a plant's name.")
        case .standingAndWatching:
            return LocalizedStringResource("subtheme.standingAndWatching", defaultValue: "Standing and watching",
                comment: "One of the three parts of the theme Waiting: patience, keeping watch. Listed on the screen that explains a plant's name.")
        case .cutAndComeAgain:
            return LocalizedStringResource("subtheme.cutAndComeAgain", defaultValue: "Cut and come again",
                comment: "One of the three parts of the theme Renewal: a plant cut back that grows again. A gardener's phrase. Listed on the screen that explains a plant's name.")
        case .theTurningYear:
            return LocalizedStringResource("subtheme.theTurningYear", defaultValue: "The turning year",
                comment: "One of the three parts of the theme Renewal: the seasons coming round. Listed on the screen that explains a plant's name.")
        case .madeWhole:
            return LocalizedStringResource("subtheme.madeWhole", defaultValue: "Made whole",
                comment: "One of the three parts of the theme Renewal: mending and healing, what was broken made whole. Listed on the screen that explains a plant's name.")
        case .theEdgesOfTheDay:
            return LocalizedStringResource("subtheme.theEdgesOfTheDay", defaultValue: "The edges of the day",
                comment: "One of the three parts of the theme Light: dawn and dusk. Listed on the screen that explains a plant's name.")
        case .readingTheLight:
            return LocalizedStringResource("subtheme.readingTheLight", defaultValue: "Reading the light",
                comment: "One of the three parts of the theme Light: how a plant senses light and turns to it. Listed on the screen that explains a plant's name.")
        case .lightItself:
            return LocalizedStringResource("subtheme.lightItself", defaultValue: "Light itself",
                comment: "One of the three parts of the theme Light: sunlight as a thing in itself. Listed on the screen that explains a plant's name.")
        case .counted:
            return LocalizedStringResource("subtheme.counted", defaultValue: "Counted",
                comment: "One of the three parts of the theme Pattern: patterns that are numbers, spirals and the golden angle. Listed on the screen that explains a plant's name.")
        case .fittedTogether:
            return LocalizedStringResource("subtheme.fittedTogether", defaultValue: "Fitted together",
                comment: "One of the three parts of the theme Pattern: shapes that tile and interlock. Listed on the screen that explains a plant's name.")
        case .orderNamed:
            return LocalizedStringResource("subtheme.orderNamed", defaultValue: "Order named",
                comment: "One of the three parts of the theme Pattern: the words people have for order. Listed on the screen that explains a plant's name.")
        case .theSoilItself:
            return LocalizedStringResource("subtheme.theSoilItself", defaultValue: "The soil itself",
                comment: "One of the three parts of the theme Ground: soil, and what lives in it. Listed on the screen that explains a plant's name.")
        case .aPlaceYouAreFrom:
            return LocalizedStringResource("subtheme.aPlaceYouAreFrom", defaultValue: "A place you are from",
                comment: "One of the three parts of the theme Ground: home ground, belonging to a place. Listed on the screen that explains a plant's name.")
        case .aKeptPlace:
            return LocalizedStringResource("subtheme.aKeptPlace", defaultValue: "A kept place",
                comment: "One of the three parts of the theme Ground: a garden as a place enclosed and tended. Listed on the screen that explains a plant's name.")
        case .howASeedGoes:
            return LocalizedStringResource("subtheme.howASeedGoes", defaultValue: "How a seed goes",
                comment: "One of the three parts of the theme Travel: how seeds are carried by wind and water. Listed on the screen that explains a plant's name.")
        case .theRoad:
            return LocalizedStringResource("subtheme.theRoad", defaultValue: "The road",
                comment: "One of the three parts of the theme Travel: journeys and pilgrims. Listed on the screen that explains a plant's name.")
        case .farOff:
            return LocalizedStringResource("subtheme.farOff", defaultValue: "Far off",
                comment: "One of the three parts of the theme Travel: distance, and the longing for somewhere else. Listed on the screen that explains a plant's name.")
        case .theMoment:
            return LocalizedStringResource("subtheme.theMoment", defaultValue: "The moment",
                comment: "One of the three parts of the theme Meeting: the right moment, a chance meeting. Listed on the screen that explains a plant's name.")
        case .twoThatNeedEachOther:
            return LocalizedStringResource("subtheme.twoThatNeedEachOther", defaultValue: "Two that need each other",
                comment: "One of the three parts of the theme Meeting: a flower and its pollinator. Listed on the screen that explains a plant's name.")
        case .theMannersOfIt:
            return LocalizedStringResource("subtheme.theMannersOfIt", defaultValue: "The manners of it",
                comment: "One of the three parts of the theme Meeting: hospitality, how a guest is received. Listed on the screen that explains a plant's name.")
        case .grownTogether:
            return LocalizedStringResource("subtheme.grownTogether", defaultValue: "Grown together",
                comment: "One of the three parts of the theme Kinship: grafts, lichen, roots and fungi joined. Listed on the screen that explains a plant's name.")
        case .theWordsForIt:
            return LocalizedStringResource("subtheme.theWordsForIt", defaultValue: "The words for it",
                comment: "One of the three parts of the theme Kinship: the words people have for kin and companions. Listed on the screen that explains a plant's name.")
        case .twoPeople:
            return LocalizedStringResource("subtheme.twoPeople", defaultValue: "Two people",
                comment: "One of the three parts of the theme Kinship: friendship between two people. Listed on the screen that explains a plant's name.")
        case .quietAsASound:
            return LocalizedStringResource("subtheme.quietAsASound", defaultValue: "Quiet as a sound",
                comment: "One of the three parts of the theme Peace: quiet as something heard, wind in trees, snow. Listed on the screen that explains a plant's name.")
        case .theWordsForStopping:
            return LocalizedStringResource("subtheme.theWordsForStopping", defaultValue: "The words for stopping",
                comment: "One of the three parts of the theme Peace: the words for rest and ceasing. Listed on the screen that explains a plant's name.")
        case .atEase:
            return LocalizedStringResource("subtheme.atEase", defaultValue: "At ease",
                comment: "One of the three parts of the theme Peace: comfort, being at ease with others. Listed on the screen that explains a plant's name.")
        }
    }
}
