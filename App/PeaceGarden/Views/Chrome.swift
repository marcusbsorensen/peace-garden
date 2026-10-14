import SwiftUI
import UIKit

/// The app's whole visual vocabulary, in one place.
///
/// Everything is thin, letterspaced and slightly transparent, sitting on the
/// near-black of `StageBackdrop` so the plant is the only saturated thing on
/// screen. Controls are quiet enough to disappear and be forgotten between
/// taps.
enum Chrome {
    // MARK: - The greys
    //
    // Raised across the board after a round on a real phone in real light. The
    // old set was drawn on a bright screen in a dark room, which is the one
    // condition under which 0.28 white on black is legible; anywhere else the
    // growth stage under a plant's name was a smudge. Contrast against black,
    // computed rather than eyeballed, at the sizes each is actually used:
    //
    // | | old | new | contrast |
    // | --- | --- | --- | --- |
    // | `muted` | 0.55 | **0.72** | 10.5:1 |
    // | `faint` | 0.28 | **0.56** | 6.5:1 |
    // | `sectionLabel` | 0.72 | **0.80** | 13.1:1 |
    //
    // All three clear WCAG AA for small text, which 0.28 missed by half. The
    // hierarchy is narrower than it was and now leans on size, weight and
    // letterspacing to carry the difference — which is the right way round,
    // since those survive sunlight and a low opacity does not.
    // Each resolves against the appearance the app is running in, so a light
    // garden is the same hierarchy read the other way up rather than a second
    // set of colours somebody has to keep in step. The alphas are not mirrored:
    // dark type on a light ground reads heavier at the same opacity, so the
    // light values are pulled back a little to keep the three levels apart.
    //
    // **Except `faint` in the light, which was pulled back too far** (mass
    // test, 13 October, finding 8): 0.52 on the light ground is 3.7 : 1, under
    // the 4.5 : 1 small text needs, and it is the small text — the label
    // voice, a plant's place and date, the seed screen's row labels. At 0.60
    // it is 4.8 : 1, still the faintest of the three and still apart from
    // `muted` (6.8 : 1).
    static let ink = adaptive(dark: .white, light: UIColor(white: 0.07, alpha: 1))
    static let muted = adaptive(dark: UIColor(white: 1, alpha: 0.72),
                                light: UIColor(white: 0.07, alpha: 0.70))
    static let faint = adaptive(dark: UIColor(white: 1, alpha: 0.56),
                                light: UIColor(white: 0.07, alpha: 0.60))
    /// Rules and borders, never text. Lifted only enough that a capsule's edge
    /// is visible outdoors.
    static let hairline = adaptive(dark: UIColor(white: 1, alpha: 0.24),
                                   light: UIColor(white: 0.07, alpha: 0.20))

    /// What every screen in the app is painted on.
    ///
    /// Near-black rather than black in the dark, and a warm near-white rather
    /// than white in the light: both give the plant somewhere to sit without
    /// the ground itself becoming the brightest or darkest thing on screen.
    static let ground = adaptive(dark: .black, light: UIColor(white: 0.965, alpha: 1))

    private static func adaptive(dark: UIColor, light: UIColor) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .light ? light : dark })
    }

    /// For the small uppercase labels that head a section.
    ///
    /// `faint` is right for a label standing beside a value it is explaining,
    /// where the value should win. It is not right for a heading somebody is
    /// meant to read on the way past. Letterspacing thins a line of type as
    /// surely as a lighter weight does, so wide-tracked small caps need more of
    /// the ground back than ordinary text of the same size would.
    static let sectionLabel = adaptive(dark: UIColor(white: 1, alpha: 0.80),
                                       light: UIColor(white: 0.07, alpha: 0.78))

    /// What a label becomes once a warm fill has passed under it.
    static let nearBlack = Color(white: 0.05)

    // MARK: - The three warm ones

    /// Colour has been the plants' alone: all chrome is white at four
    /// opacities against black. These three are the exception, and they live
    /// on the three reset rows in Settings — the only places in the app where
    /// something is lost. Keeping them rare is what makes them mean anything.
    ///
    /// Contrast against the label each carries, computed rather than eyeballed:
    /// near-black on `pinkGold` is 9.2:1, near-black on `ochre` 5.3:1, and
    /// `ink` on `crimson` 10.0:1. All three clear AA at this text size with
    /// room to spare, so the crimson had no need to go darker.
    static let pinkGold = Color(red: 0.851, green: 0.659, blue: 0.549)  // #D9A88C
    static let ochre = Color(red: 0.690, green: 0.478, blue: 0.290)     // #B07A4A
    static let crimson = Color(red: 0.494, green: 0.114, blue: 0.157)   // #7E1D28

    // MARK: - On, and the two lights

    /// A switch that is on (Marcus, 13 October 2026: *the calm sage background
    /// instead of light grey*).
    ///
    /// **The sage stop of the logo's own ramp**, in both of the pair BRAND.md
    /// gives it: `#9CC29E` on dark and `#397E3D` on light. Against the screen's
    /// ground, computed rather than eyeballed, the track is 10.6 : 1 on black —
    /// as light as the grey it replaced, so the white knob reads against it as
    /// it did — and 4.6 : 1 on the light ground, where it carries the knob at
    /// 5.0 : 1. Both are well over the 3 : 1 an edge that says *on* needs.
    static let sage = adaptive(dark: rgb(0x9CC29E), light: rgb(0x397E3D))

    /// The sun's strokes, on the chosen answer of *Light and dark*: a warm
    /// orange. `#F2A65A` on dark, 8.6 : 1 on the chosen capsule's wash;
    /// `#B5561A` on light, 3.7 : 1 on the wash and 4.5 : 1 on the ground.
    static let sunOrange = adaptive(dark: rgb(0xF2A65A), light: rgb(0xB5561A))

    /// The moon's strokes, beside the sun's: a pale yellow. `#F4E4A1` on dark,
    /// 13.6 : 1 on the wash. **On light it cannot be pale** — a pale yellow on
    /// a near-white ground is 1.2 : 1 and disappears — so it deepens to a gold,
    /// `#8C6A00`, 3.8 : 1 on the wash and 4.7 : 1 on the ground.
    static let moonYellow = adaptive(dark: rgb(0xF4E4A1), light: rgb(0x8C6A00))

    private static func rgb(_ hex: UInt32) -> UIColor {
        UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1)
    }

    /// Text stops being readable somewhere past this. On an iPad a paragraph
    /// set to the full width of the screen is a wall; the plant is allowed the
    /// whole screen, the words are not.
    static let readableWidth: CGFloat = 440

    // What the stage draws, and how long it stays.
    //
    // Each is read in two places — the stage that obeys it and the switch that
    // sets it — so the keys live here rather than in either. Versioned, because
    // a default whose meaning changes has to be able to leave the old one
    // behind rather than inherit a value that now means something else.

    /// Whether the plant's binomial is drawn under it.
    static let namesPlantKey = "stage.namesPlant.v1"
    /// Whether the growth stage is drawn under the name.
    ///
    /// Separate from the name because they answer different questions. The name
    /// is what this plant *is* and does not change; the stage is what it is
    /// doing this week, and somebody who has learnt to read the plant does not
    /// need to be told.
    static let showsStageKey = "stage.showsStage.v1"
    /// How much of the row along the foot is on screen, and for how long.
    static let menuStyleKey = "stage.menuStyle.v1"
    /// Which way up the app is drawn. See `StageAppearance`.
    static let appearanceKey = "stage.appearance.v1"
    /// How a seed says where it was planted. See `PlantingLocationMode`.
    static let placeModeKey = "places.mode.v1"
    /// What a gardener wrote, when the mode is `.custom`.
    static let placeCustomKey = "places.custom.v1"
    /// How the plant is drawn. See `StagePlantStyle`.
    static let plantStyleKey = "stage.plantStyle.v1"
    /// The colour a monochrome or wireframe plant is drawn in, as `RRGGBB`.
    static let plantTintKey = "stage.plantTint.v1"
    /// A warm bone, which is what a botanical plate is printed in and what a
    /// single colour on black wants to be before anybody chooses otherwise.
    static let plantTintDefault = "D9C9B0"

    /// Whether the plant turns on its own.
    ///
    /// It is a turntable rather than an animation of the plant: the plant does
    /// nothing, the stage under it moves. Somebody who would rather turn it
    /// themselves, or who finds the drift distracting, can stop it — and it is
    /// a real saving on a phone left on a desk with the app open.
    static let turntableKey = "stage.turntable.v1"

    /// Whether the garden follows the clock. See `GardenDaylight`.
    static let daylightKey = "garden.daylight.v1"

    /// Which of its four sides the garden's plot is seen from, in quarter-turns.
    ///
    /// **Kept on the phone rather than on the bed.** It is how somebody likes to
    /// look at their garden, not anything about the garden: a bed is what was
    /// arranged, and nothing in it should change because it was looked at from
    /// the other side. Kept at all because Marcus asked, 1 October, for a
    /// favourite side to come back the next time the garden opens.
    static let plotTurnKey = "garden.turn.v1"

    static let fadeIn = Animation.easeInOut(duration: 0.55)
    static let controlsIdleTimeout: Duration = .seconds(6)
}

/// How much of the row along the foot of the stage is showing.
///
/// Three points on one line — how far you are from the thing you want — rather
/// than three unrelated preferences. Each step trades a tap for a piece of the
/// screen, and there is no right answer: somebody who opens the garden twenty
/// times a day and somebody who wants a plant alone on black are both right.
enum StageMenuStyle: String, CaseIterable, Sendable {
    /// Nothing until the screen is touched, and gone again six seconds later.
    /// Two taps to the row, three to a screen. The bare plant, which is what
    /// this app was for.
    case hidden
    /// The marks, always. One tap unrolls a mark's word, a second opens it.
    case mini
    /// The marks and their words, always. One tap opens anything.
    case full

    var label: LocalizedStringResource {
        switch self {
        case .hidden: return "Hidden"
        case .mini: return "Marks only"
        case .full: return "Marks and words"
        }
    }

    /// Whether the row is drawn without being asked for.
    var isAlwaysOnScreen: Bool { self != .hidden }
    /// Whether every mark carries its word, which is what removes the first tap.
    var namesEveryMark: Bool { self == .full }
}

/// Which way up the app is drawn.
///
/// The garden was black from the first screen, and for a reason: it is the one
/// ground that lets a plant be the only saturated thing in front of somebody.
/// A light garden gives that up, and it is worth having anyway — a phone in
/// sunlight is a different instrument from a phone at night, and so is a person
/// who finds a black screen at breakfast unfriendly.
/// How a seed says where it was planted.
///
/// Three answers to one question, and only one of them can be the answer — so
/// it is one control with three states rather than a menu and a switch that can
/// disagree with each other, which is what it was.
enum PlantingLocationMode: String, CaseIterable, Sendable {
    /// One of the app's own figurative places: *after the storm*, and the rest.
    /// The default, because it is the only one that says something true without
    /// saying anything a stranger could use.
    case abstract
    /// The point on the earth the phone measured, to five decimal places.
    case geographic
    /// Whatever the gardener would rather it said.
    case custom

    /// What the *Location description* menu calls each answer. The first is
    /// Marcus's wording of 13 October 2026, which replaced *One of the places*.
    var label: LocalizedStringResource {
        switch self {
        case .abstract: return "A place from abstract list"
        case .geographic: return "Where you actually are"
        case .custom: return "Something you write"
        }
    }

    /// The one line under the menu, for the answer that is chosen and no other
    /// (Marcus, 13 October 2026).
    ///
    /// Each says what that answer does, in a sentence. Until then the section
    /// carried a line under each answer's control and, whichever was chosen,
    /// ninety words on everything that crosses between two phones — which is
    /// an account of the meeting rather than of this setting, and belongs with
    /// the privacy account rather than among the switches.
    ///
    /// *Something you write* keeps the sentence it already had, because it was
    /// already one plain sentence, and true: what is written is used nowhere
    /// else yet (`places.custom.v1`). When a seed does carry it, this is the
    /// sentence to change.
    var note: LocalizedStringResource {
        switch self {
        case .abstract: return "Where you met is given as a place from the abstract list."
        case .geographic: return "Where you met is logged on this phone as the coordinates it measured, when you both ask."
        case .custom: return "What you write here is kept in this phone's settings, and for now it appears only there."
        }
    }
}

enum StageAppearance: String, CaseIterable, Sendable {
    case dark
    case light
    /// Whatever the phone is doing, which is what most people mean by not
    /// having an opinion.
    case system

    var label: LocalizedStringResource {
        switch self {
        case .dark: return "Dark"
        case .light: return "Light"
        case .system: return "Follow the phone"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .dark: return .dark
        case .light: return .light
        case .system: return nil
        }
    }
}

extension EnvironmentValues {
    /// The colour scheme the appearance came to on the screen that opened this
    /// one, carried into a screen that draws itself in a scheme of its own —
    /// the garden's, which is Dark (`PlotView.scheme`). `nil` everywhere else.
    ///
    /// **The scheme as it came out, not the setting.** *Follow the phone* is no
    /// scheme at all until the phone answers, and inside the garden the phone's
    /// answer can no longer be asked: everything there, and everything it
    /// presents, inherits Dark. So it is read where the garden is opened from,
    /// which is still in the appearance, and handed in. Read there, it also
    /// follows the phone turning dark at dusk while the garden is open.
    @Entry var appearanceScheme: ColorScheme? = nil
}

extension View {
    /// A screen presented from one drawn in a scheme of its own, back in the
    /// appearance chosen in Settings — with the status bar over it, when it
    /// covers the screen. Nothing at all outside such a screen.
    ///
    /// A presentation inherits the scheme of the one that presented it, so a
    /// plant's own screen opened from the garden would otherwise be Dark, and
    /// every screen it opened in turn.
    func inTheAppearance() -> some View {
        modifier(InTheAppearance())
    }
}

private struct InTheAppearance: ViewModifier {
    @Environment(\.appearanceScheme) private var scheme

    func body(content: Content) -> some View {
        content
            // Straight away, for the first frame; the preference reaches the
            // presentation itself a moment later, and sets its status bar.
            .transformEnvironment(\.colorScheme) { if let scheme { $0 = scheme } }
            .preferredColorScheme(scheme)
    }
}

/// Whether the garden's own sky follows the clock.
///
/// **Night falls by the clock, and there is an override.** A garden that is dark
/// because it is dark outside is a place; a garden that is dark because somebody
/// pressed a button is a theme picker. So the clock is the default and the sun
/// and moon go round on their own.
///
/// The override exists because this app is used at two in the morning by people
/// who will want to see their garden in daylight, and refusing them that would
/// be purity at somebody else's expense. It is a standing choice, and for a
/// while it lived only in Settings, on the grounds that a switch on the garden
/// would make the hour a thing you set. **Since 1 October it is in the garden's
/// tray as well** (Marcus): Settings is out of reach from the garden, and the
/// person who wants to see their lanterns lit is looking at the lanterns. The
/// clock is still the default, and the tray opens shut.
///
/// The cases are declared in the order Settings lays them out — day, the clock,
/// night — so the control is `allCases` and nothing has to keep a second list
/// in step with it.
enum GardenDaylight: String, CaseIterable, Sendable {
    /// Noon, whatever the hour is. Stored as `always`, its name before night
    /// had a choice of its own, so a garden already set to daylight stays so.
    case always
    /// The sun up from six to six, the moon the other twelve hours.
    case byTheClock
    /// Midnight, whatever the hour is: the moon up, the lamps lit, the figures
    /// glowing. For anyone who comes to the garden for its night.
    case alwaysNight

    var label: LocalizedStringResource {
        switch self {
        case .always: return "Always day"
        case .byTheClock: return "Follows the hour"
        case .alwaysNight: return "Always night"
        }
    }

    /// The mark each answer wears in Settings: the sun, the two together, the
    /// moon.
    var glyph: AnyShape {
        switch self {
        case .always: return AnyShape(SunGlyph())
        case .byTheClock: return AnyShape(SunAndMoonGlyph())
        case .alwaysNight: return AnyShape(MoonGlyph())
        }
    }

    /// Which light a stroke of the mark is, and so the colour it takes when its
    /// answer is the chosen one: the sun warm orange, the moon pale yellow
    /// (Marcus, 13 October 2026).
    enum Light: Sendable {
        case sun, moon

        var colour: Color {
            switch self {
            case .sun: return Chrome.sunOrange
            case .moon: return Chrome.moonYellow
            }
        }
    }

    /// The same mark, drawn a light at a time, so that the middle answer's sun
    /// and moon can each wear their own colour.
    var parts: [(light: Light, shape: AnyShape)] {
        switch self {
        case .always: return [(.sun, AnyShape(SunGlyph()))]
        case .byTheClock: return [(.sun, AnyShape(SunAndMoonGlyph(part: .sun))),
                                  (.moon, AnyShape(SunAndMoonGlyph(part: .moon)))]
        case .alwaysNight: return [(.moon, AnyShape(MoonGlyph()))]
        }
    }

    /// The hour to draw the garden at, given the hour it actually is.
    func hour(when actual: Double) -> Double {
        switch self {
        case .byTheClock: return actual
        case .always: return 12
        case .alwaysNight: return 0
        }
    }
}

/// How the plant itself is drawn.
///
/// Colour has always been the plants' alone in this app — every piece of chrome
/// is white at four opacities on black, precisely so that the one saturated
/// thing on screen is the thing you grew. These two alternatives give that up
/// on purpose, and each is a different reason for wanting to.
enum StagePlantStyle: String, CaseIterable, Sendable {
    /// The plant as its seed drew it: its own palette, lit and shaded.
    case full
    /// One colour, still lit. The normal and roughness maps stay, so the form
    /// is all there and only the hue is gone — which is a botanical plate
    /// rather than a silhouette.
    case monochrome
    /// The mesh itself, unlit. What the plant is made of rather than what it
    /// looks like, and the only view in the app that admits there is geometry
    /// underneath.
    case wireframe

    var label: LocalizedStringResource {
        switch self {
        case .full: return "Full colour"
        case .monochrome: return "One colour"
        case .wireframe: return "Wireframe"
        }
    }

    /// Whether the tint is the plant's whole colour, and therefore worth
    /// letting somebody choose.
    var isTinted: Bool { self != .full }

    /// The system's mark for each answer, on the seed screen's control
    /// (`PlantDrawingToggle`): a palette for the plant's own colours, a drop
    /// for one ink, and the transparent cube that is the system's own word
    /// for a wireframe. Known marks rather than three more words.
    var symbol: String {
        switch self {
        case .full: return "paintpalette"
        case .monochrome: return "drop"
        case .wireframe: return "cube.transparent"
        }
    }
}

extension Chrome {
    /// The languages that are shown the label voice as it was written, rather
    /// than uppercased.
    ///
    /// Uppercasing is not a formatting choice in every language, it is a
    /// transformation that can lose or change a letter — so the decision has to
    /// be made per language rather than applied by one modifier to all of them.
    /// Four cases, and none of them is a language this app currently ships:
    ///
    /// - **Turkish and Azerbaijani** have two letter i's. `i` uppercases to `İ`
    ///   and `ı` to `I`, and getting it the wrong way round changes the word.
    ///   Swift's locale-aware `uppercased()` handles it; a reader who then sees
    ///   `İ` in a tracked-out caption may not.
    /// - **Greek** drops the accent on an uppercased vowel, except on the
    ///   disjunctive ή, so uppercasing is not reversible and a screen reader
    ///   loses the stress.
    /// - **Irish** keeps the lowercase prefix on an uppercased word — `nAthair`
    ///   rather than `NATHAIR` — which no general-purpose uppercaser does.
    ///
    /// The list is the mechanism rather than a finding: a language added to the
    /// catalogue gets the app's ordinary capitals unless it is named here, and
    /// naming it here is a one-line decision rather than a rewrite of the two
    /// voices below. See docs/LANGUAGES.md §"Type".
    static let keepsWrittenCase: Set<String> = ["tr", "az", "el", "ga"]

    /// Scripts with no capitals at all.
    ///
    /// A different fact from `keepsWrittenCase`, which is four languages that
    /// have capitals and are harmed by them. These have none, so `.uppercase`
    /// is a no-op — named here rather than left to the no-op, because a label
    /// voice that says "uppercase" about a script with no case is describing
    /// itself wrongly, and the next person to read it should not have to work
    /// out that nothing happens.
    static let caselessScripts: Set<String> = ["ar", "he", "ja", "zh", "ko", "th", "fa", "ur", "yi"]

    /// Languages the label voice must not letter-space.
    ///
    /// **This one breaks something, where the two lists above only undress it.**
    /// The label voice tracks to 2.4pt, which is a Latin small-caps device. On
    /// Arabic it is a defect rather than a preference: Arabic is a joined
    /// script, and space between letters severs the joins and leaves a row of
    /// disconnected forms for the reader to put back together. Persian and Urdu
    /// are the same script and the same damage.
    ///
    /// CJK is here for a milder reason. Nothing is severed — the glyphs do not
    /// join — but a Han or Kana line tracked to a Latin caption's rhythm reads
    /// as badly set, and the device it imitates has no meaning in a script with
    /// no capitals to space out.
    ///
    /// Hebrew is deliberately absent. It is right to left and caseless, and its
    /// letters do not join, so tracking there is a choice rather than a wound.
    ///
    /// Mirrored by `NEVER_TRACKED` in `Server/assets/js/languages.js`.
    static let neverTracked: Set<String> = ["ar", "fa", "ur", "ja", "zh", "ko"]

    /// What the label and heading voices do to their letters, in this language.
    static func letterCase(in locale: Locale) -> Text.Case? {
        let code = locale.language.languageCode?.identifier ?? ""
        if keepsWrittenCase.contains(code) || caselessScripts.contains(code) { return nil }
        return .uppercase
    }

    /// How far the label and heading voices may track, in this language.
    static func tracking(_ amount: CGFloat, in locale: Locale) -> CGFloat {
        let code = locale.language.languageCode?.identifier ?? ""
        return neverTracked.contains(code) ? 0 : amount
    }
}

/// Tracks out, unless the script would be damaged by it.
///
/// A modifier rather than a plain `.tracking()` for the same reason
/// `ChromeLetterCase` is one: the answer depends on the locale, and the locale
/// is in the environment.
private struct ChromeTracking: ViewModifier {
    @Environment(\.locale) private var locale
    let amount: CGFloat

    init(_ amount: CGFloat) {
        self.amount = amount
    }

    func body(content: Content) -> some View {
        content.tracking(Chrome.tracking(amount, in: locale))
    }
}

/// Uppercases, unless the language would rather it did not.
///
/// **Capitals for the eye, words for the ear** (14 October). `textCase`
/// changes the string itself, so VoiceOver was handed *LOCATION DESCRIPTION*
/// and read it as capitals — letter by letter, for some words — and an
/// explicit label beside it was uppercased too, because the label is
/// resolved in the same environment. So what VoiceOver reads is the same
/// content with the case left as written: one representation, here, for
/// every label and heading in the two voices.
private struct ChromeLetterCase: ViewModifier {
    @Environment(\.locale) private var locale

    func body(content: Content) -> some View {
        content
            .textCase(Chrome.letterCase(in: locale))
            .accessibilityRepresentation { content.textCase(nil) }
    }
}

extension Color {
    /// From `RRGGBB`, falling back to white rather than to nothing.
    init(hex: String) {
        let digits = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let value = UInt64(digits, radix: 16) ?? 0xFFFFFF
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    /// `RRGGBB`, for a default somebody chose with a colour picker.
    var hex: String {
        let components = UIColor(self).cgColor.components ?? [1, 1, 1]
        let channels = components.count >= 3
            ? Array(components.prefix(3))
            : [components[0], components[0], components[0]]
        return channels
            .map { String(format: "%02X", Int((max(0, min(1, $0)) * 255).rounded())) }
            .joined()
    }
}

extension View {
    /// Pins a drawing to the hand it was drawn with.
    ///
    /// **A row of marks mirrors under right-to-left; the marks in it must not.**
    /// Both were happening. Driven in an Arabic locale the stage row correctly
    /// reversed — cog, garden, meet, seed — and every glyph reversed with it, so
    /// the garden's flower stood to the right of its grass, the seed's curl
    /// turned the other way and the cog came out as its own reflection.
    ///
    /// Reversing the row is right: it is a row of controls and reading order
    /// runs the other way. Reversing the glyphs is not. They are pictures of
    /// things rather than directional affordances, and a seed, a flower and a
    /// gear have a shape rather than a handedness — the same rule Apple states
    /// for imagery that does not indicate direction.
    ///
    /// It also keeps the app's hand in one piece. The coil in `Chrome.Tendril`,
    /// the frond in `UnfurlingBackdrop` and the seed on the reset row are all
    /// the same gesture, and the plant on the stage is SceneKit and mirrors for
    /// nobody. Pinning the drawings means an Arabic reader sees the same marks
    /// as everybody else, in a row laid out their way.
    func drawnHand() -> some View {
        environment(\.layoutDirection, .leftToRight)
    }

    /// Type at the size the design set, grown or shrunk with the size of text
    /// the phone is set to. Every `.font(.system(size:))` a person reads goes
    /// through here or through the three voices below. See `ScaledSystemFont`.
    func scaledFont(size: CGFloat, weight: Font.Weight = .light, design: Font.Design = .default,
                    monospacedDigits: Bool = false) -> some View {
        modifier(ScaledSystemFont(size: size, weight: weight, design: design,
                                  monospacedDigits: monospacedDigits))
    }

    /// Small, wide-tracked, uppercase: the app's label voice.
    ///
    /// **Regular below twelve points, light from twelve up** (mass test, 13
    /// October, finding 8). At ten and eleven points the light weight's
    /// strokes are thinner than a pixel, so the capitals never reach the grey
    /// they are drawn in, and the voice failed the contrast audit in Dark too,
    /// where its grey is 6.5 : 1 by arithmetic. One step of weight brings the
    /// strokes up to their colour; the voice stays small, spaced and quiet.
    ///
    /// **It grows as far as AX3** (14 October). Tracked capitals are the
    /// widest type in the app, and a long word in them — Danish and Dutch
    /// make long words — no longer fits an SE's column past AX3, where it
    /// breaks in the middle.
    func chromeLabel(size: CGFloat = 11, weight: Font.Weight = .light) -> some View {
        scaledFont(size: size, weight: size < 12 && weight == .light ? .regular : weight)
            .modifier(ChromeTracking(2.4))
            .modifier(ChromeLetterCase())
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }

    /// The heading voice: uppercase and wide-tracked, like the label voice but
    /// at size. It is what marks the three moments the app explains itself —
    /// the seed forming, the seed planted, two seeds meeting — as one sequence
    /// rather than three unrelated screens.
    ///
    /// **It grows as far as AX2** (14 October), for the label voice's reason
    /// at a larger size: at AX5 *ONTMOETEN* and *PRENDENDO* broke mid-word on
    /// an SE, and at AX2 the heading is already twice its size at Large.
    func chromeHeading(size: CGFloat = 20) -> some View {
        scaledFont(size: size)
            .modifier(ChromeTracking(2.8))
            .modifier(ChromeLetterCase())
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    /// The serif voice, used only for plant names.
    ///
    /// "Only" is meant literally, and for a while it was not true: four screen
    /// titles were wearing it, which claims that "A seed on the wind" and
    /// "Peace garden" are things something is *called*. Every use is a
    /// `genome.name.full` or, on `NameMeaningView`, a piece of one — the head
    /// and the ending, each set beside what it means. Grep before adding
    /// anything that is neither.
    func plantName(size: CGFloat = 26) -> some View {
        scaledFont(size: size, design: .serif)
            .italic()
    }
}

/// A system font at a designed size that follows Dynamic Type.
///
/// **Every size in the app was fixed** (mass test, 13 October, finding 4: of
/// 1,499 texts compared from Large to the accessibility sizes, none grew).
/// The design's sizes are its own — eleven-point tracked capitals, a fifteen-
/// point light paragraph — and none of them is a text style's, so each is
/// scaled by the text style nearest to it rather than replaced by one: at
/// Large every screen is exactly what it was, and at any other size each
/// line grows as the system's own type of that size grows.
///
/// Where a screen cannot hold the largest sizes, it says so with
/// `dynamicTypeSize(...)` at the screen, and that caps this too.
struct ScaledSystemFont: ViewModifier {
    @ScaledMetric private var size: CGFloat
    let weight: Font.Weight
    let design: Font.Design
    let monospacedDigits: Bool

    init(size: CGFloat, weight: Font.Weight, design: Font.Design, monospacedDigits: Bool) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: Self.style(near: size))
        self.weight = weight
        self.design = design
        self.monospacedDigits = monospacedDigits
    }

    func body(content: Content) -> some View {
        let font = Font.system(size: size, weight: weight, design: design)
        content.font(monospacedDigits ? font.monospacedDigit() : font)
    }

    /// The text style whose size at Large is nearest, so a size grows at that
    /// style's rate. The small styles grow fastest — caption 1 goes from 12 to
    /// 43 at the largest size, the large title from 34 to 60 — which is the
    /// system's judgement about what needs the help, taken whole.
    ///
    /// **Nothing follows caption 2**, though the ten- and eleven-point label
    /// voice is nearest it: caption 2 is eleven points at every size from the
    /// smallest to Large, so a label that followed it did not move when the
    /// size was turned down, and the audit called it *partially unsupported*.
    /// Caption 1 moves at every step.
    static func style(near size: CGFloat) -> Font.TextStyle {
        switch size {
        case ..<12.5: return .caption
        case ..<14: return .footnote
        case ..<15.5: return .subheadline
        case ..<16.5: return .callout
        case ..<18.5: return .body
        case ..<21: return .title3
        case ..<25: return .title2
        case ..<31: return .title
        default: return .largeTitle
        }
    }
}

/// Fades its content in after a wait.
///
/// The app arrives a piece at a time, at about the pace the piece is taken in.
/// A screen that appears whole is a screen to be scanned; a screen that unfolds
/// is one to be read, and unfolding is the gesture the whole app is built on.
struct Unfolding<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let after: Double
    @ViewBuilder var content: () -> Content

    @State private var shown = false

    var body: some View {
        content()
            .opacity(shown ? 1 : 0)
            .animation(.easeInOut(duration: 1.2), value: shown)
            .task {
                // Reduce Motion still gets the fade, and gets it at once: the
                // objection is to being made to wait through choreography, not
                // to a crossfade.
                if !reduceMotion, after > 0 {
                    try? await Task.sleep(for: .seconds(after))
                }
                shown = true
            }
    }
}

/// How long a line takes to read, near enough to set a cadence by.
func readingBeat(_ line: String) -> Double {
    0.5 + Double(line.split(separator: " ").count) * 0.22
}

/// A control that reads as a line of text — with an edge, so it also reads as
/// a control.
struct QuietButton: View {
    /// A key rather than a `String`, and the distinction is the whole of what
    /// makes this button translatable. `Text(someString)` is drawn exactly as
    /// handed over; `Text(someKey)` is looked up in `Localizable.xcstrings`
    /// first. Every caller passes a literal, so every caller's word is
    /// extracted and can be translated — which was not true while this said
    /// `String`.
    let title: LocalizedStringKey
    var isProminent: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .chromeLabel()
                .foregroundStyle(isProminent ? Chrome.ink : Chrome.muted)
                .multilineTextAlignment(.center)
                .pressable(isProminent: isProminent)
        }
        .buttonStyle(.plain)
        // **Grows as far as AX1**, where the longest of these (*They don't
        // have the app*) takes two lines inside its capsule on an SE; past
        // that the capsule's ends cut into the words (14 October).
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }
}

/// The way out of a screen: an X in a ring, and no word.
///
/// A word was one more string in forty-two languages for the one control
/// everybody already knows by its shape. The symbol is the system's, so
/// VoiceOver reads it as *Close* in whatever language the phone speaks.
struct CloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Chrome.ink.opacity(0.75))
                .frame(width: 18, height: 18)
                .pressable(horizontal: 12, vertical: 12)
        }
        .buttonStyle(.plain)
    }
}

extension View {
    /// For a scroll view on a screen that closes: the X in a band of its own
    /// across the top, and the scrolling content faded out before it reaches
    /// the band, so nothing scrolls over the way out.
    ///
    /// A fade rather than a strip of ground colour, because some of these
    /// screens have a plant standing behind the words and a strip would cut
    /// it in half.
    func closingBar(_ close: @escaping () -> Void) -> some View {
        let band: CGFloat = 62
        return contentMargins(.top, band, for: .scrollContent)
            .mask {
                VStack(spacing: 0) {
                    Color.clear.frame(height: band - 14)
                    LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                        .frame(height: 18)
                    Color.black
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .overlay(alignment: .topTrailing) {
                CloseButton(action: close)
                    .padding(.trailing, 12)
                    .padding(.top, 8)
            }
    }

    /// For a column centred between two spacers: it stands exactly as it did
    /// while it fits the screen, and scrolls once it does not.
    ///
    /// **Why at all.** A column of words between spacers on a 667-point SE was
    /// already full at the type sizes the design set, and once the type follows
    /// Dynamic Type (mass test, 13 October, findings 4 and 7) a column that
    /// does not fit gives up height line by line and ends in an ellipsis. In a
    /// scroll view whose content is at least the screen tall, the spacers
    /// still centre the column whenever it fits, and the scroll view neither
    /// bounces nor scrolls until it has to.
    func scrollsWhenTooTall() -> some View {
        GeometryReader { proxy in
            ScrollView {
                self.frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    /// Lays a `SproutingRule` along the bottom edge of this view, so the rule's
    /// *line* — not the box its tendrils curl in — sits exactly where the view
    /// ends.
    ///
    /// For a text field this makes the rule the thing the name is written on,
    /// with a tendril turning at either end of it. Set below the field with
    /// ordinary spacing it read as a separate ornament that happened to follow,
    /// and the name floated above nothing.
    ///
    /// Pass `curlingDown` where the value on the rule is aligned to the leading
    /// edge rather than centred. The tendrils open *upward* from the line and
    /// their coils sit about twenty points in from either end, which is clear
    /// air under a centred name and is the first two letters of a
    /// leading-aligned one. Turning the pair over puts the coils in the empty
    /// band below the line instead. They are still mirrored, so the rule still
    /// reads as one thing sprouting rather than as two ornaments that match.
    func underlining(curlingDown: Bool = false) -> some View {
        overlay(alignment: .bottom) {
            SproutingRule()
                .scaleEffect(y: curlingDown ? -1 : 1)
                .alignmentGuide(.bottom) { _ in SproutingRule.height / 2 }
        }
        // Room for the half of the rule that now hangs below this view.
        .padding(.bottom, SproutingRule.height / 2)
    }

    /// The edge that tells a line of text it can be pressed.
    ///
    /// Everything in this app is thin, letterspaced and half-transparent, which
    /// is the point — and it left the buttons indistinguishable from the labels
    /// standing next to them. A hairline capsule is the least that can be added
    /// and still answer the question, without the screen growing a chrome.
    ///
    /// Anything that is a button wears this, including the ones that are not
    /// `QuietButton`: a `ShareLink` styled to match, and the rename affordance
    /// in Seed, which was the worst of them — a sentence that happened to be
    /// tappable.
    ///
    /// `horizontal` is for a control with nothing but a glyph in it, where the
    /// standing inset makes a wide oval out of something that should be round.
    ///
    /// `vertical` is for the one row that has to stand taller than a line of
    /// text in a capsule — the marks along the foot of the stage, which are
    /// this app's navigation rather than a button inside a panel somebody is
    /// already reading. It is a parameter rather than a new number here because
    /// the other nine callers are that second kind, and growing every button in
    /// the app was not what the row needed.
    func pressable(
        isProminent: Bool = false,
        horizontal: CGFloat = 18,
        vertical: CGFloat = 12
    ) -> some View {
        padding(.horizontal, horizontal)
            .padding(.vertical, vertical)
            .overlay(
                ControlEdge().strokeBorder(
                    // The prominent one is brighter, so the hierarchy survives
                    // now that both have an outline. Well under the text it
                    // surrounds either way: an edge that competes with its own
                    // label has stopped being an edge.
                    isProminent ? Chrome.ink.opacity(0.32) : Chrome.hairline,
                    lineWidth: 1
                )
            )
            // Rectangular on purpose, though it is drawn as a capsule. These
            // are small targets and the corners are worth having; a tap just
            // outside the outline is a tap meant for the button.
            .contentShape(Rectangle())
    }
}

/// The edge `pressable` draws: a capsule round one line, and round more than
/// one a rounded rectangle whose corners stop at the capsule's.
///
/// **Why not a capsule always** (14 October). With the type following
/// Dynamic Type, a label can take two or three lines, and a capsule round
/// three lines is a lozenge whose ends cut through the first and last words.
/// The corners never grow past 24 points — the radius of the 48-point marks
/// at the foot of the stage, which stay circles — so every one-line control
/// is exactly the capsule it was.
struct ControlEdge: InsettableShape {
    var inset: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let box = rect.insetBy(dx: inset, dy: inset)
        let radius = max(0, min(24 - inset, box.height / 2, box.width / 2))
        return Path(roundedRect: box, cornerRadius: radius)
    }

    func inset(by amount: CGFloat) -> ControlEdge {
        var edge = self
        edge.inset += amount
        return edge
    }
}

/// A slow breath, for the screens that are waiting on something.
struct BreathingDot: View {
    var diameter: CGFloat = 8
    @State private var expanded = false

    var body: some View {
        Circle()
            .fill(Chrome.ink)
            .frame(width: diameter, height: diameter)
            .scaleEffect(expanded ? 1.0 : 0.55)
            .opacity(expanded ? 0.9 : 0.3)
            .animation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true), value: expanded)
            .onAppear { expanded = true }
    }
}

/// Divider hairline, used sparingly.
struct Hairline: View {
    var body: some View {
        Rectangle()
            .fill(Chrome.hairline)
            .frame(height: 1)
    }
}

/// A tendril, part way through opening.
///
/// The coil *relaxes* rather than the line being drawn on: curvature is highest
/// at the tip and falls as `unfurl` rises, which is how a fiddlehead actually
/// opens. Trimming a fixed spiral would read as a line growing, which is a
/// different gesture and a duller one.
struct Tendril: Shape {
    /// `0` is furled tight, `1` is nearly open.
    var unfurl: Double

    var animatableData: Double {
        get { unfurl }
        set { unfurl = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let steps = 80
        // Arc length is constant, so the tendril does not grow and shrink as it
        // opens — only its coil changes. The tip travels because the coil lets go.
        let length = rect.width * 1.7
        let step = length / Double(steps)
        let turn = Double.pi * (0.6 + 5.2 * (1 - unfurl))

        // Leaves from the middle of its own height, so it meets the rule it grows
        // out of rather than hanging below it.
        var point = CGPoint(x: rect.minX, y: rect.midY)
        var path = Path()
        path.move(to: point)
        for index in 1...steps {
            let s = Double(index) / Double(steps)
            // The turn accumulates toward the tip, so the tendril leaves its
            // base almost straight and keeps the curl at the far end.
            let angle = -turn * pow(s, 1.7)
            point.x += cos(angle) * step
            point.y += sin(angle) * step
            path.addLine(to: point)
        }
        return path
    }
}

/// The rule under the name, with a tendril opening from each end.
///
/// The pair are mirrored in direction, so the line reads as one thing sprouting
/// rather than two decorations that happen to match — but **they are not at the
/// same stage of opening**. They were, and a rule with two identical coils is a
/// bracket: the eye reads it as a container with the name inside it, which is
/// the opposite of a thing growing.
///
/// The left is held tighter and the right runs looser, so the pair reads as one
/// gesture caught partway rather than as a matched set. Both still move, and
/// both still stay short of letting go entirely.
struct SproutingRule: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var open = false

    /// The tendrils need room to curl, so the rule is drawn in a box this tall
    /// with the line itself across the middle of it.
    ///
    /// Anything wanting the *line* somewhere precise — under a text field, say,
    /// so that a name sits on it — has to allow for that half. See
    /// `underlining()`.
    static let height: CGFloat = 46

    // Never fully open: past about 0.7 the coil has let go entirely, and what is
    // left reads as a stray hook on the end of the line rather than as a tendril.
    private var unfurl: Double { reduceMotion ? 0.5 : (open ? 0.66 : 0.12) }

    /// The near end, still wound. Roughly half the other one's opening, which is
    /// enough to read as a difference at 40 points and not so much that the coil
    /// becomes a blot.
    private var tighter: Double { unfurl * 0.5 }
    /// The far end, well on its way — and stopped short of 0.72, past which
    /// there is no coil left to see.
    private var looser: Double { min(0.72, unfurl + 0.18) }

    var body: some View {
        HStack(spacing: 0) {
            tendril(tighter).scaleEffect(x: -1, y: 1)
            Hairline()
            tendril(looser)
        }
        .animation(
            reduceMotion ? nil
                : .easeInOut(duration: 6).repeatForever(autoreverses: true),
            value: open
        )
        .onAppear { open = true }
    }

    // A shade brighter than the rule it grows from, and large enough that the
    // opening is perceptible: at hairline weight and 30pt the motion measured
    // 41 levels of change against the ground, which is real but invisible.
    private func tendril(_ unfurl: Double) -> some View {
        Tendril(unfurl: unfurl)
            .stroke(Chrome.faint, style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            .frame(width: 40, height: 46)
    }
}

// MARK: - Drawn marks

extension Chrome {
    /// Monoline, round free ends, even weight — [BRAND.md](../../../docs/BRAND.md)
    /// §3.2, the rule the app icon is drawn to. Every glyph in the chrome wears
    /// it, so the cog at the top of the stage and the seed on a reset row are
    /// visibly the same hand.
    static let monoline = StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round)
}

/// The box a mark draws in, which is not the box it is given.
///
/// **The four marks in the stage row are not one size.** A cog fills its square
/// corner to corner and a seed is a small closed shape, so drawn at equal frames
/// the cog swamps everything beside it. Each takes a centred share of its frame
/// instead, sized by how much it has to say: the garden is two whole plants and
/// takes all of it, the meeting and the cog sit between, and the seed is the
/// smallest thing in this app and now looks it.
///
/// **The stroke does not scale with them.** `Chrome.monoline` is one width, so a
/// smaller mark is a lighter mark as well as a shorter one, and that is half of
/// why this works at all. It is also why the share is set here rather than by
/// giving each mark its own `glyphSize`, which would have moved the tap target
/// and the baseline along with the drawing.
func markBox(_ rect: CGRect, _ share: CGFloat) -> CGRect {
    let side = min(rect.width, rect.height) * share
    return CGRect(x: rect.midX - side / 2, y: rect.midY - side / 2,
                  width: side, height: side)
}

private func polar(_ centre: CGPoint, _ radius: CGFloat, _ angle: Double) -> CGPoint {
    CGPoint(x: centre.x + radius * cos(angle), y: centre.y + radius * sin(angle))
}

/// A cog, and deliberately the ordinary one.
///
/// Three drawings before this, and every one of them was a sun. A ring with
/// things radiating off it is a sun, a star, a gear or a loading spinner, and
/// which of those a reader lands on is not something proportion can settle —
/// long rays gave the brightness glyph, short detached ticks gave a spinner,
/// and the ring with teeth grown straight out of it gave a wheel with bumps.
///
/// So this one stops trying to be a house-style instrument and is a gear.
/// **Recognition wins on the one mark whose whole job is to be found without
/// being read**, and there is no right angle anywhere in it: the tooth profile
/// is a flattened cosine, which gives square-ish tops and roots with quick
/// flanks and no corner at any point along it.
///
/// **Seven teeth, phased from twelve o'clock.** The profile used to be measured
/// from the x axis while the mark is drawn from the top, which put the top of
/// the cog halfway up a flank — arbitrary, and it looked it. Measured from the
/// top, a spoke stands vertically; and because seven is odd, that forces a
/// notch exactly opposite it at the foot and leaves the mark no mirror line.
struct CogShape: Shape {
    var teeth: Int = 7
    /// Points per tooth. Fifteen is smooth at any size the app draws this at.
    var resolution: Int = 15

    func path(in rect: CGRect) -> Path {
        let box = markBox(rect, 0.84)
        let centre = CGPoint(x: box.midX, y: box.midY)
        let half = box.width / 2 - 0.9
        let tip = half, root = half * 0.70
        let mid = (tip + root) / 2, amplitude = (tip - root) / 2

        var path = Path()
        let steps = teeth * resolution
        for step in 0...steps {
            let phase = 2 * Double.pi * Double(step) / Double(steps)
            let bearing = phase - .pi / 2
            let radius = mid + amplitude * CGFloat(tanh(2.6 * cos(Double(teeth) * phase)))
            let point = polar(centre, radius, bearing)
            if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()

        let bore = root * 0.52
        path.addEllipse(in: CGRect(x: centre.x - bore, y: centre.y - bore,
                                   width: bore * 2, height: bore * 2))
        return path
    }
}

/// A pencil, as thin as the cog. An affordance beside the name rather than a
/// button: it says the line next to it is yours to fill in.
struct PencilShape: Shape {
    func path(in rect: CGRect) -> Path {
        func at(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
        }
        var path = Path()
        path.move(to: at(0.06, 0.94))          // the point
        path.addLine(to: at(0.24, 0.66))
        path.addLine(to: at(0.78, 0.16))       // up the shaft
        path.addLine(to: at(0.94, 0.34))
        path.addLine(to: at(0.38, 0.84))
        path.closeSubpath()
        // Where the sharpening stops.
        path.move(to: at(0.24, 0.66))
        path.addLine(to: at(0.38, 0.84))
        return path
    }
}

/// A seed: nearly an oval, one end a little drawn and the other a little fuller.
///
/// **The taper was the whole fault, for a long time.** Run the point over most
/// of the height and the mark is a water drop, or a flame, or a leaf — anything
/// except a seed. A real seed is barely pointed. So the crown's controls sit a
/// sixth of the way down and well out from the axis, which *turns* the tip
/// rather than drawing it out, and the foot's leave horizontally, which is what
/// keeps the foot round rather than making a second point.
///
/// **Upright, it was a specimen.** Nothing else in this app sits square to the
/// frame, and the eye finds the odd one out at once. Twenty degrees says the
/// seed is lying where it fell.
///
/// **The shade line is computed, not placed.** It samples the flank it sits
/// under and steps in along that curve's own normal, so the gap between the two
/// is constant. Drawn by hand it was a chord across the corner — close to the
/// outline at one end and far from it at the other — which reads as a crack
/// rather than as a surface turning away. Of the two normals it takes whichever
/// lands nearer the middle of the shape: guessing the sign from which flank
/// this is fails at the foot, where the curve turns through the vertical and
/// the flanks swap over.
struct SeedGlyph: Shape {
    /// Clockwise, in degrees.
    var tilt: Double = 20

    func path(in rect: CGRect) -> Path {
        let box = markBox(rect, 0.70)
        let side = box.width
        // Taller than it is wide. Width is what makes something look heavy, and
        // a seed is not heavy.
        var w = min(side, side / 1.30)
        let x = box.minX + side / 2 - w / 2 + 0.9
        let y = box.minY + 0.9
        let h = side - 1.8
        w -= 1.8
        let mid = x + w / 2, top = y, bot = y + h

        var path = Path()
        path.move(to: CGPoint(x: mid, y: bot))
        path.addCurve(to: CGPoint(x: mid, y: top),
                      control1: CGPoint(x: x + w * 1.16, y: bot),
                      control2: CGPoint(x: mid + w * 0.34, y: y + h * 0.17))
        path.addCurve(to: CGPoint(x: mid, y: bot),
                      control1: CGPoint(x: mid - w * 0.34, y: y + h * 0.17),
                      control2: CGPoint(x: x - w * 0.16, y: bot))
        path.closeSubpath()

        // The left flank, crown to foot, exactly as the outline above draws it.
        let start = CGPoint(x: mid, y: top)
        let handleA = CGPoint(x: mid - w * 0.34, y: y + h * 0.17)
        let handleB = CGPoint(x: x - w * 0.16, y: bot)
        let finish = CGPoint(x: mid, y: bot)
        func flank(_ t: CGFloat) -> CGPoint {
            let u = 1 - t
            return CGPoint(
                x: u * u * u * start.x + 3 * u * u * t * handleA.x
                    + 3 * u * t * t * handleB.x + t * t * t * finish.x,
                y: u * u * u * start.y + 3 * u * u * t * handleA.y
                    + 3 * u * t * t * handleB.y + t * t * t * finish.y)
        }

        let inset = w * 0.135
        let heart = CGPoint(x: mid, y: y + h * 0.55)
        for step in 0...8 {
            let t = 0.54 + 0.22 * CGFloat(step) / 8
            let here = flank(t), ahead = flank(t + 0.006)
            let run = max(hypot(ahead.x - here.x, ahead.y - here.y), 0.0001)
            let nx = -(ahead.y - here.y) / run, ny = (ahead.x - here.x) / run
            let outward = CGPoint(x: here.x + nx * inset, y: here.y + ny * inset)
            let inward = CGPoint(x: here.x - nx * inset, y: here.y - ny * inset)
            let nearer = hypot(outward.x - heart.x, outward.y - heart.y)
                < hypot(inward.x - heart.x, inward.y - heart.y) ? outward : inward
            if step == 0 { path.move(to: nearer) } else { path.addLine(to: nearer) }
        }

        return path.applying(
            CGAffineTransform(translationX: box.midX, y: box.midY)
                .rotated(by: tilt * .pi / 180)
                .translatedBy(x: -box.midX, y: -box.midY)
        )
    }
}

/// A garden: a flower, and a tuft of grass beside it.
///
/// It was three stems on a bed line with a different thing on each head, and it
/// read as three squiggles. Before that it was three identical ovoids, and
/// before that three upright stems on a full-width line, which is a colonnade.
/// **Two plants a reader can name is worth more than three that read as marks**,
/// and at fifteen points two is what there is room for.
///
/// **The flower is one closed outline of five lobes**, not five petals radiating
/// from a centre. Radiating strokes at this size are a sun however few of them
/// there are — the same trap the cog fell into three times.
///
/// **The grass is three blades, because a seed head cannot be drawn at this
/// size.** It was a thirteen-turn zigzag, and the arithmetic was never going to
/// work: thirteen turns across a 13.2pt box is 0.55pt a turn, under a stroke
/// 1.2pt wide. A stroke twice the size of the feature it draws fills the gaps
/// in, so what reached the screen was a threaded rod — a screw, or a comb, and
/// the one mark in the set whose subject could not be recovered without its
/// word. This was the first thing the row was ever looked at for on a device,
/// and it is what the device said.
///
/// Five larger turns read as a lightning bolt; a leaf on a stem merged into a
/// mitten; a closed bud read well but rhymed with `SeedGlyph` two places along
/// the row. Blades carry no feature smaller than the stroke, which is the point.
/// Three rather than two: two splay from one foot and the near one parallels the
/// flower's stem, which is three uprights side by side and the colonnade this
/// mark was drawn to get away from.
///
/// It costs ink. 30.6% of the frame against the zigzag's 27.6%, which makes this
/// the heaviest mark in the row, ahead of the cog at 28.7% — so the ordering
/// `markBox` describes is now true of the drawing as well as of the box.
/// Separated strokes read lighter than that number; the zigzag merged into a
/// solid bar and read heavier than its own.
struct GardenGlyph: Shape {
    /// The three blades: start, two control points and end, in fractions of the
    /// box. The middle one stands; the outer two lean away and stop shorter, so
    /// the tuft has a silhouette rather than a top edge. Shared with
    /// `tools/glyphs/shapes.py`, which is where they were judged.
    private static let grass: [(CGPoint, CGPoint, CGPoint, CGPoint)] = [
        (CGPoint(x: 0.70, y: 1.00), CGPoint(x: 0.665, y: 0.76),
         CGPoint(x: 0.625, y: 0.58), CGPoint(x: 0.585, y: 0.40)),
        (CGPoint(x: 0.70, y: 1.00), CGPoint(x: 0.715, y: 0.72),
         CGPoint(x: 0.725, y: 0.46), CGPoint(x: 0.715, y: 0.20)),
        (CGPoint(x: 0.70, y: 1.00), CGPoint(x: 0.750, y: 0.76),
         CGPoint(x: 0.815, y: 0.60), CGPoint(x: 0.865, y: 0.46)),
    ]

    func path(in rect: CGRect) -> Path {
        let box = markBox(rect, 1.0).insetBy(dx: 0.9, dy: 0.9)
        func at(_ u: CGFloat, _ v: CGFloat) -> CGPoint {
            CGPoint(x: box.minX + box.width * u, y: box.minY + box.height * v)
        }
        let w = box.width
        var path = Path()

        // The flower: five lobes on one closed outline, and a stem under it.
        let heart = at(0.33, 0.30)
        let tip = w * 0.20, valley = w * 0.075, lift = tip * 1.42
        for petal in 0..<5 {
            let a0 = -Double.pi / 2 + Double(petal) * 2 * .pi / 5
            let a1 = a0 + 2 * .pi / 5
            let from = polar(heart, valley, a0 - .pi / 5)
            let to = polar(heart, valley, a1 - .pi / 5)
            if petal == 0 { path.move(to: from) }
            path.addCurve(to: to,
                          control1: polar(heart, lift, a0 - 0.40),
                          control2: polar(heart, lift, a0 + 0.40))
        }
        path.closeSubpath()
        path.move(to: at(0.37, 1.00))
        path.addCurve(to: at(0.33, 0.50), control1: at(0.36, 0.76), control2: at(0.32, 0.66))

        // The grass: three blades out of one foot, each a single curve.
        for (from, handleA, handleB, to) in Self.grass {
            path.move(to: at(from.x, from.y))
            path.addCurve(to: at(to.x, to.y),
                          control1: at(handleA.x, handleA.y),
                          control2: at(handleB.x, handleB.y))
        }

        // The bed: under their feet, not the width of the frame.
        path.move(to: at(0.25, 1.00))
        path.addLine(to: at(0.79, 1.00))
        return path
    }
}

/// A recycling turn, without the corporate triangle, in the logo's hand.
///
/// Three arrows meeting at right angles is a glyph from another visual system
/// and this app has none of those angles. **Since 11 October 2026 it is the
/// new logo's second frond said three times** (Marcus: *"fix the recycling
/// glyph to match the new logo"*): each frond grows from a thick start on a
/// circle, runs a third of the way round it, and winds inward into a coil,
/// thinning as it goes, as the logo's crozier does (`tools/icon/make_icon.py`,
/// `curl()` and `profiles()`). Each coil turns in just short of where the next
/// frond starts, so the three read as one turning, and it keeps the meaning
/// worth having — that the material returns, rather than that it is destroyed.
/// Until then it was three logarithmic spirals opening outward from the
/// centre, the old icon's spiral repeated.
///
/// **A taper drawn with the chrome's own pen.** Every caller strokes a glyph
/// with `Chrome.monoline`, one width, in its own ink, and a stroke cannot vary
/// along a path. So each frond is the closed outline of a band that is
/// `Frond.band` wide at its start and nothing at its tip, and the caller's
/// stroke round that outline makes the line: `monoline + band` at the start,
/// exactly `monoline` at the tip. The thinnest point is the hairline every other
/// glyph is drawn in, so it never falls under a pixel the way the logo's tip
/// would at this size (`suite-brand.md` §3.2a(5)), and the ink is whatever the
/// caller already strokes with. A band wider than the stroke would leave a
/// hollow down its middle, so past that a centreline is stroked inside it too.
///
/// Curves only: the sides and the centreline are Catmull–Rom splines, as the
/// logo's are, and the outline closes on its own first point.
///
/// **The frond is Marcus's choice, 11 October 2026**: A of three, a turn of
/// coil and a start almost twice the stroke. The other two, more coil and a
/// heavier start (B) and the logo's small-drawing hook (C), are recorded with
/// their dials in `design/recycle-glyph-2026-10-11/`.
struct CycleGlyph: Shape {
    var frond: Frond = .chosen

    /// One frond's shape: how far it runs round the circle, how it coils, and
    /// how heavy its start is. In units of the circle's radius, except `band`,
    /// which is points, as the stroke is.
    struct Frond: Equatable, Sendable {
        /// How far round the circle it runs before it turns in, in radians.
        var arc: Double
        /// The coil: turns, and the radius of curvature it enters and ends at.
        var turns: Double
        var entry: Double
        var eye: Double
        /// How much wider than the stroke the start is, in points.
        var band: CGFloat
        /// The logo's ease-out: the band falls as `(1 − u)^ease` along the
        /// frond's length, front-loading the thinning (`TENDRIL_EASE`).
        var ease: Double

        /// **Marcus's choice, A**: a turn of coil, and a start almost twice the
        /// stroke, 2.2 pt thinning to the tip's 1.2. Its tightest gap at 15 pt
        /// is 0.49 pt, a pixel and a half on a 3× phone.
        static let chosen = Frond(arc: 1.2, turns: 0.95, entry: 0.44, eye: 0.16, band: 1.0, ease: 2.5)
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let stroke = Chrome.monoline.lineWidth
        for line in Self.fronds(frond, in: rect) {
            let count = line.count
            // The band's two sides, the tip where they meet, and a round end
            // at the start, as one closed outline.
            var sideA: [CGPoint] = [], sideB: [CGPoint] = []
            for (index, sample) in line.enumerated() {
                let previous = line[max(index - 1, 0)].point, next = line[min(index + 1, count - 1)].point
                let length = max(hypot(next.x - previous.x, next.y - previous.y), 1e-9)
                let normal = CGPoint(x: -(next.y - previous.y) / length, y: (next.x - previous.x) / length)
                let half = sample.band / 2
                sideA.append(CGPoint(x: sample.point.x + normal.x * half, y: sample.point.y + normal.y * half))
                sideB.append(CGPoint(x: sample.point.x - normal.x * half, y: sample.point.y - normal.y * half))
            }
            let start = line[0].point, along = line[1].point
            let heading = atan2(along.y - start.y, along.x - start.x)
            let radius = line[0].band / 2
            // From side B's start, round the back, to side A's.
            let cap = (1..<6).map { step -> CGPoint in
                let angle = heading + 1.5 * .pi - .pi * Double(step) / 6
                return CGPoint(x: start.x + radius * cos(angle), y: start.y + radius * sin(angle))
            }
            addSpline(sideA + Array(sideB.reversed().dropFirst()) + cap, closed: true, to: &path)
            if line[0].band > stroke {
                addSpline(line.map(\.point), closed: false, to: &path)
            }
        }
        return path
    }

    /// One point of a frond's centreline and the band's width there.
    struct Sample {
        var point: CGPoint
        var band: CGFloat
    }

    /// The three centrelines in `rect`, evenly resampled, start to tip, each
    /// with its band. Exposed so a test can measure the gaps the drawing keeps.
    static func fronds(_ frond: Frond, in rect: CGRect, samples: Int = 70) -> [[Sample]] {
        let stroke = Chrome.monoline.lineWidth
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        // The circle, leaving room for the heaviest line's outer edge.
        let ring = min(rect.width, rect.height) / 2 - (stroke + frond.band) / 2 - 0.1
        return (0..<3).map { index in
            let start = -Double.pi / 2 + Double(index) * 2 * .pi / 3
            var raw: [CGPoint] = []
            // Round the circle, clockwise on the screen.
            let arcSteps = 40
            for step in 0...arcSteps {
                let angle = start + frond.arc * Double(step) / Double(arcSteps)
                raw.append(CGPoint(x: centre.x + ring * cos(angle), y: centre.y + ring * sin(angle)))
            }
            // Then the coil: a logarithmic spiral entered on the circle's own
            // heading, its radius of curvature falling from `entry` to `eye`,
            // as `make_icon.py`'s `curl()` integrates it.
            let total = 2 * Double.pi * frond.turns
            let coilSteps = 80
            var heading = start + frond.arc + .pi / 2
            var point = raw[raw.count - 1]
            for step in 1...coilSteps {
                let t = total * (Double(step) - 0.5) / Double(coilSteps)
                let curvature = frond.entry * pow(frond.eye / frond.entry, t / total) * ring
                heading = start + frond.arc + .pi / 2 + t
                point.x += cos(heading) * curvature * total / Double(coilSteps)
                point.y += sin(heading) * curvature * total / Double(coilSteps)
                raw.append(point)
            }
            return resample(raw, count: samples).enumerated().map { offset, point in
                let u = Double(offset) / Double(samples - 1)
                return Sample(point: point, band: frond.band * CGFloat(pow(1 - u, frond.ease)))
            }
        }
    }

    /// `count` points evenly spaced along the polyline through `points`.
    private static func resample(_ points: [CGPoint], count: Int) -> [CGPoint] {
        var lengths: [CGFloat] = [0]
        for index in 1..<points.count {
            let a = points[index - 1], b = points[index]
            lengths.append(lengths[index - 1] + hypot(b.x - a.x, b.y - a.y))
        }
        let total = lengths[lengths.count - 1]
        var out: [CGPoint] = []
        var segment = 1
        for step in 0..<count {
            let target = total * CGFloat(step) / CGFloat(count - 1)
            while segment < points.count - 1 && lengths[segment] < target { segment += 1 }
            let span = max(lengths[segment] - lengths[segment - 1], 1e-9)
            let f = min(max((target - lengths[segment - 1]) / span, 0), 1)
            let a = points[segment - 1], b = points[segment]
            out.append(CGPoint(x: a.x + (b.x - a.x) * f, y: a.y + (b.y - a.y) * f))
        }
        return out
    }

    /// Catmull–Rom through `points` as cubic Béziers, so every segment is a
    /// curve; points closer than a thousandth of a point, where the two sides
    /// meet at the tip, are taken once. Closed, it ends on its own first point.
    private func addSpline(_ input: [CGPoint], closed: Bool, to path: inout Path) {
        var p: [CGPoint] = []
        for point in input where p.last.map({ hypot(point.x - $0.x, point.y - $0.y) > 1e-3 }) ?? true {
            p.append(point)
        }
        if closed, p.count > 1, hypot(p[0].x - p[p.count - 1].x, p[0].y - p[p.count - 1].y) <= 1e-3 {
            p.removeLast()
        }
        let n = p.count
        guard n > 2 else { return }
        func at(_ i: Int) -> CGPoint { closed ? p[(i % n + n) % n] : p[min(max(i, 0), n - 1)] }
        path.move(to: p[0])
        for i in 0..<(closed ? n : n - 1) {
            let p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2)
            path.addCurve(to: p2,
                          control1: CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6),
                          control2: CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6))
        }
        // Already back on its first point, so this closes a gap of nothing.
        if closed { path.closeSubpath() }
    }
}

/// A glyph and a word, in the app's label voice.
///
/// The word can be withheld, and the glyph then stands alone — animate
/// `showsTitle` and the control unrolls. What it is called goes to VoiceOver
/// either way, so nothing depends on the word being drawn.
struct ChromeIconLabel: View {
    let glyph: AnyShape
    let title: LocalizedStringKey
    var tint: Color = Chrome.muted
    /// Twenty-eight, and the circle it sits in is forty-eight.
    ///
    /// It was fifteen, in a capsule 41 by 39, and every one of those numbers
    /// was wrong for what this row does. The four marks along the foot of the
    /// stage are the whole of this app's navigation, and they were smaller than
    /// the minimum a target is meant to be — under a plant that fills the
    /// screen, they read as a footnote to it rather than as the way out of it.
    ///
    /// **The circle and the drawing in it were raised separately**, because
    /// they are two faults. Forty-eight is the circle, which is a target. The
    /// drawing is more than half of it, where fifteen in forty-one was under a
    /// half and the two smallest marks — a seed at 0.70 of its frame, a cog at
    /// 0.84 — were a third of theirs, adrift in a ring with nothing to do.
    /// `markBox` keeps that ordering; this makes it visible.
    ///
    /// Fifteen was already two over the thirteen the spec asked for, because
    /// eight teeth on a ring at the hairline weight do not survive thirteen:
    /// see `CogShape`. That was a floor, and it was being used as a size.
    ///
    /// The stroke does not follow it up. `Chrome.monoline` is one width at
    /// every size, so the marks are airier than they were as well as bigger,
    /// which is the weight a row this size wants.
    var glyphSize: CGFloat = 28
    /// How far the word stands off the mark once it unrolls.
    ///
    /// Seven suits a mark whose ink stops short of its own box. A mark that
    /// fills its width — `MeetGlyph`'s two stems part at the top corners — puts
    /// a stroke right against the first letter and reads as crowded at the same
    /// number. It is a property of the drawing, not of the row, so it is set
    /// per mark rather than raised for all four.
    var titleSpacing: CGFloat = 7
    var showsTitle: Bool = true
    /// Beside the mark, or under it.
    ///
    /// Under it is how four words fit at once. Side by side they do not: the
    /// four-up row measures 449 points in English and 533 in Italian against a
    /// phone's 402, which is what `mark(_:_:_:)` on the stage was built to
    /// avoid by unrolling one word at a time. Stacked, each word has its own
    /// quarter of the screen and only has to fit a hundred of them.
    var axis: Axis = .horizontal

    var body: some View {
        Group {
            if axis == .horizontal {
                HStack(spacing: showsTitle ? titleSpacing : 0) { mark; word }
            } else {
                VStack(spacing: 5) { mark; word }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
    }

    private var mark: some View {
        glyph
            .stroke(tint, style: Chrome.monoline)
            .frame(width: glyphSize, height: glyphSize)
            // The row reverses under right-to-left; the mark in it does not.
            .drawnHand()
            // Uppercase text carries descender room it never uses, so its box
            // centres below the letters. A point up puts the glyph on the cap
            // height rather than on the line.
            .offset(y: axis == .horizontal ? -1 : 0)
    }

    @ViewBuilder
    private var word: some View {
        if showsTitle {
            Text(title)
                .chromeLabel(size: axis == .horizontal ? 11 : 9)
                .foregroundStyle(tint)
                // Beside the mark it arrives at its full width and fades, and
                // is never wrapped or truncated. Stacked, it has a hundred
                // points and the longest word in the catalogue is Swedish
                // INSTÄLLNINGAR — so it is allowed to shrink a little rather
                // than clip.
                //
                // **It grows with Dynamic Type only as far as XL**, and then
                // shrinks back rather than clip (14 October). One word at a
                // time leaves about 140 points for it beside the other three
                // marks on an SE, and INSTÄLLNINGAR takes 119 at Large: the
                // row has no more room to give, and VoiceOver reads every
                // word at whatever size the phone asks for.
                .lineLimit(1)
                .minimumScaleFactor(axis == .horizontal ? 0.8 : 0.75)
                .fixedSize(horizontal: false, vertical: true)
                .dynamicTypeSize(...DynamicTypeSize.xLarge)
                .transition(.opacity)
        }
    }
}

/// The mark that opened a screen, standing before that screen's title.
///
/// **The row at the foot of the stage names four screens by their marks**, and
/// each screen it opens says its own name in capitals at the top (Marcus,
/// 13 October: *"show the glyphs from the lower menu next to each title on the
/// screens they open"*). The mark beside the title is the same drawing as the
/// one that was touched, so the screen answers *which one did I open* in the
/// language the row already speaks.
///
/// **The same drawing at the same weight, sized to the capitals.** The frame
/// runs from the baseline to the cap height, plus the 0.9 pt every mark keeps
/// clear inside its box for its own stroke, and the mark takes its usual share
/// of it (`markBox`): the garden stands on the baseline and reaches the top of
/// the capitals, and a rounder mark sits centred on them, as each sits in its
/// circle at the foot. `Chrome.monoline` does not scale, as it does not in the
/// row.
///
/// **Coloured as the title is**, because it strokes in the foreground style the
/// title is set in, so one `foregroundStyle` after `titleGlyph(_:size:)` reaches
/// both. Silent to VoiceOver, which already reads the title, and pinned to the
/// hand it was drawn with (`drawnHand()`); under right-to-left the mark still
/// stands before the title, which is then on its right.
struct TitleGlyph: View {
    let glyph: AnyShape
    /// The title's point size as it is drawn: the designed size, grown with
    /// Dynamic Type at the rate `chromeHeading` grows it, so the mark keeps to
    /// the capitals at every size.
    @ScaledMetric private var size: CGFloat

    init(glyph: AnyShape, size: CGFloat) {
        self.glyph = glyph
        _size = ScaledMetric(wrappedValue: size, relativeTo: ScaledSystemFont.style(near: size))
    }

    /// The room a mark keeps inside its box for its own stroke.
    static let inset: CGFloat = 0.9

    /// Baseline to cap height, plus the stroke's room above and below.
    static func side(for size: CGFloat) -> CGFloat {
        UIFont.systemFont(ofSize: size, weight: .light).capHeight + 2 * inset
    }

    var body: some View {
        let side = Self.side(for: size)
        glyph
            .stroke(.foreground, style: Chrome.monoline)
            .frame(width: side, height: side)
            .drawnHand()
            // The box's floor, less the stroke's room, on the title's baseline.
            .alignmentGuide(.firstTextBaseline) { $0[.bottom] - Self.inset }
            .alignmentGuide(.lastTextBaseline) { $0[.bottom] - Self.inset }
            .accessibilityHidden(true)
    }
}

extension View {
    /// This title, with the mark that opened its screen before it. See
    /// `TitleGlyph`. `size` is the title's own point size.
    func titleGlyph(_ glyph: some Shape, size: CGFloat) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: (size * 0.5).rounded()) {
            TitleGlyph(glyph: AnyShape(glyph), size: size)
                // Capped where the heading voice is, so it stays the height
                // of the capitals beside it.
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            self
        }
    }
}

/// A few answers to one question, as marks in one capsule.
///
/// **The capsule of Settings' Light row** (`LightToggle`): the hairline round
/// the whole, and round the chosen answer a capsule of its own, a faint wash
/// inside the prominent edge, which slides between answers. Lifted out generic
/// so the seed screen's plant drawing is that control and not one that looks
/// like it.
///
/// **How a chosen mark is drawn is the caller's**, because `mark` is handed
/// whether its answer is chosen. The seed screen lifts its mark from `faint` to
/// `ink`. The Light row no longer does: since 13 October its chosen sun is
/// orange and its moon yellow (`Chrome.sunOrange`, `Chrome.moonYellow`), so
/// the two controls share the capsule and differ in the chosen mark's colour.
/// `LightToggle` could still move onto this, drawing its colours in `mark`;
/// its answers are 58 points wide to this one's 52.
///
/// Each answer is read aloud by its own label and the whole by `label`, so a
/// VoiceOver user hears the question and which answer is selected.
struct MarkChooser<Option: Hashable, Mark: View>: View {
    let options: [Option]
    let selection: Option
    let label: Text
    let optionLabel: (Option) -> Text
    @ViewBuilder let mark: (Option, Bool) -> Mark
    let choose: (Option) -> Void

    @Namespace private var wash

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                segment(option)
            }
        }
        .padding(3)
        .overlay(Capsule().strokeBorder(Chrome.hairline, lineWidth: 1))
        .animation(.easeInOut(duration: 0.22), value: selection)
        .sensoryFeedback(.selection, trigger: selection)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
    }

    private func segment(_ option: Option) -> some View {
        let chosen = option == selection
        return Button { choose(option) } label: {
            mark(option, chosen)
                .frame(minWidth: 52, minHeight: 44)
                .background {
                    if chosen {
                        Capsule()
                            .fill(Chrome.ink.opacity(0.10))
                            .overlay(Capsule().strokeBorder(Chrome.ink.opacity(0.32), lineWidth: 1))
                            .matchedGeometryEffect(id: "wash", in: wash)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(optionLabel(option))
        .accessibilityAddTraits(chosen ? .isSelected : [])
    }
}

/// One mark: a glyph in a circle that unrolls its word when it is touched.
///
/// **Lifted out of the stage's row**, which is where the bargain was struck:
/// nothing on screen until somebody asks, and the same bargain in any language,
/// which words are not. `PlantStageView.mark` says why one word at a time and
/// not four — four tracked-out words come to 533 points in Italian against a
/// phone's 402. Anywhere else in the app that wants a row of actions wants
/// exactly this, and a second implementation of it would be two rows that
/// looked alike until one of them was changed.
///
/// **Tap unrolls, tap the same one again to act, a long press acts straight
/// away.** With VoiceOver the unrolling collapses: the word is already being
/// read aloud, so the first touch would buy nothing and cost an activation.
///
/// `expanded` is shared by every mark in a row, so unrolling one rolls up the
/// rest — the row is one width wide and only one word fits in it.
struct ChromeMark: View {
    let glyph: AnyShape
    /// What this mark is called among its neighbours. Only `expanded` reads it.
    let name: String
    let title: LocalizedStringKey
    var isProminent: Bool = false
    var titleSpacing: CGFloat = 7
    /// Every word shown at once, stacked, which is the Settings menu style.
    var namesEveryMark: Bool = false
    @Binding var expanded: String?
    let act: () -> Void

    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @State private var hideTask: Task<Void, Never>?

    /// How long an unrolled word stays before it rolls back up.
    static let wordLingers: Duration = .seconds(4)

    private var showsTitle: Bool { namesEveryMark || expanded == name }

    var body: some View {
        ChromeIconLabel(
            glyph: glyph,
            title: title,
            tint: isProminent ? Chrome.ink : Chrome.muted,
            titleSpacing: titleSpacing,
            showsTitle: showsTitle,
            axis: namesEveryMark ? .vertical : .horizontal
        )
        .frame(maxWidth: namesEveryMark ? .infinity : nil)
        // Ten all round puts a 28-point glyph in a circle of 48 — round,
        // because the two insets are the same, and over the forty-four a target
        // is meant to be. Eighteen once a word unrolls: the cap of a 48-point
        // capsule curves through twenty-four, so a word set at ten would start
        // inside its own end.
        .pressable(
            isProminent: isProminent,
            horizontal: namesEveryMark ? 4 : (showsTitle ? 18 : 10),
            vertical: 10
        )
        .contentShape(Capsule())
        .onTapGesture {
            hideTask?.cancel()
            if showsTitle || voiceOver {
                expanded = nil
                act()
            } else {
                expanded = name
                scheduleHide()
            }
        }
        .onLongPressGesture(minimumDuration: 0.32) {
            hideTask?.cancel()
            expanded = nil
            act()
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { act() }
        .animation(Chrome.fadeIn, value: showsTitle)
    }

    /// A word that was asked for and then left alone rolls back up, so a row
    /// returns to being a row of marks rather than staying half-open.
    private func scheduleHide() {
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(for: Self.wordLingers)
            guard !Task.isCancelled else { return }
            withAnimation(Chrome.fadeIn) { if expanded == name { expanded = nil } }
        }
    }
}

// MARK: - Holding rather than tapping

/// Reports whether a button is being pressed, and draws nothing of its own.
///
/// This is how `HoldToConfirm` knows a finger is down, and it is the second
/// answer: the first was a `DragGesture(minimumDistance: 0)`, which never
/// began at all. Inside a `ScrollView` the scroll view's own pan takes the
/// touch first and hands it on only once it is satisfied the finger is not
/// scrolling — which for a finger that is deliberately holding still may be
/// never. A button does not have that problem, because deferring and then
/// delivering a still touch is exactly what a button in a scrolling list has
/// always had to do.
///
/// It is also better behaved than the gesture would have been. `isPressed`
/// goes false when the finger leaves the button or the scroll view claims the
/// touch back, so wandering off mid-hold abandons it without any bookkeeping.
struct PressReporting: ButtonStyle {
    let onChange: (Bool) -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in onChange(pressed) }
    }
}

/// A button that is held for three seconds, with the hold as the confirmation.
///
/// An alert is a reflex: the hand taps, the eye reads nothing, and the thumb
/// finds the rightmost button. Three seconds of deliberate pressure cannot be
/// done by reflex, and — unlike an alert — it can be abandoned halfway through
/// by simply letting go, which is the gentlest way out of a decision somebody
/// has started making by accident.
///
/// The consequence appears underneath as the hold begins, which is the whole
/// reason the hold is long: three seconds is about how long the sentence takes
/// to read, so the words and the fill finish together. The screen stays short
/// while it is being read and explains itself while a decision is being made,
/// which is the only moment those words were ever for.
///
/// **The gesture has now been driven end to end on a simulator, 6 September
/// 2026**, and this note used to say it could not be. The old claim was that
/// injected touches are never sustained however long a path says to hold for —
/// the press arrives and is released in the same instant, a hold begins and is
/// abandoned before a frame is drawn. That is true of a `simctl` tap and it is
/// not true of a touch path carrying its own per-sample delays, which holds a
/// contact down for as long as it is told to. Nobody had tried one.
///
/// What was proved: a one-second press on *Release to the Wild Fields* leaves
/// the plant where it is, and a four-second press releases it, dismisses the
/// detail and returns a garden reading *nothing has been crossed yet*. So the
/// mechanism works and an accidental press cannot fire it.
///
/// **A thumb is still owed, for the judgement rather than the mechanism.** Two
/// things a driven touch cannot answer: whether three seconds is right rather
/// than long, and whether a thumb drifting during the hold hands the touch to
/// the scroll view and cancels it. A synthesised path holds perfectly still,
/// which is exactly the case a real hand does not test.
struct HoldToConfirm: View {
    /// A resource rather than a `LocalizedStringKey`, because the consequence
    /// below is spoken as well as drawn and `AccessibilityNotification` wants a
    /// `String`. A resource can be handed to `Text` and resolved to a `String`;
    /// a key can only be drawn.
    let title: LocalizedStringResource
    /// Shown beneath the button while it is held, and carried by the alert on
    /// the assisted path. One set of words, said in whichever place is
    /// reachable.
    let consequence: LocalizedStringResource
    let glyph: AnyShape
    /// The fill, and the glyph's colour before the fill reaches it.
    let tint: Color
    /// What the glyph and the label become once the fill has passed under them.
    let filledForeground: Color
    /// Fired the moment the fill completes. There is no further confirmation.
    let action: () -> Void
    /// Called instead of `action` when a sustained press is not available, so
    /// the caller can put its confirmation alert back.
    let askInstead: () -> Void

    /// How the control is dressed.
    ///
    /// **Two sets of clothes, one behaviour.** In Settings this is a row among
    /// rows and wears their type: a small glyph, a sentence beside it, the full
    /// width. In a row of marks it has to be a mark or it is the one control on
    /// the screen in a different font, which is what it was on the plant. The
    /// hold is the same hold either way — the thing that made it a hold is that
    /// it cannot be undone, and that is true of it wherever it is drawn.
    enum Dress {
        /// A full-width row, as the three in Settings are.
        case row
        /// A mark among marks: the glyph at twenty-eight, the word tracked out
        /// in caps beside it, and the word shown only once it has been asked
        /// for. `ChromeMark` is its neighbour and this matches it exactly.
        case mark(showsTitle: Bool)
    }

    var dress: Dress = .row

    private var isMark: Bool {
        if case .mark = dress { return true }
        return false
    }

    private var showsWord: Bool {
        switch dress {
        case .row: return true
        case .mark(let shows): return shows
        }
    }

    static let duration: Double = 3
    /// Faster than it filled, so letting go reads as a release rather than as a
    /// rewind.
    private static let drain: Double = 0.32

    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControl
    @State private var assistiveTouch = UIAccessibility.isAssistiveTouchRunning

    @State private var fill: CGFloat = 0
    @State private var holding = false
    @State private var completions = 0

    /// A three-second hold is a motor task, and some people cannot make one.
    /// For them the row is an ordinary button again and the alert comes back.
    private var wantsPlainButton: Bool { voiceOver || switchControl || assistiveTouch }

    var body: some View {
        VStack(alignment: isMark ? .center : .leading, spacing: 8) {
            if wantsPlainButton {
                Button(action: askInstead) { face(0) }
                    .buttonStyle(.plain)
            } else {
                // The hold is what fires the action, so a completed tap does
                // nothing at all.
                Button {} label: { face(fill) }
                    .buttonStyle(PressReporting { pressed in
                        pressed ? begin() : abandon()
                    })
                    .accessibilityHint("Hold for 3 seconds.")
            }

            // A mark's sentence is its screen's to place: under a mark it set
            // the width of the whole column, which dragged the fill out to the
            // width of an unwrapped line and took the sentence off the glass.
            if holding, !isMark {
                Text(consequence)
                    .scaledFont(size: 13, weight: .light)
                    .foregroundStyle(Chrome.muted)
                    .lineSpacing(4)
                    .multilineTextAlignment(isMark ? .center : .leading)
                    .transition(.opacity)
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIAccessibility.assistiveTouchStatusDidChangeNotification
            )
        ) { _ in
            assistiveTouch = UIAccessibility.isAssistiveTouchRunning
        }
        // A light tick as the hold takes, and a heavier one on completion.
        .sensoryFeedback(trigger: holding) { _, started in
            started ? .impact(weight: .light) : nil
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: completions)
    }

    // MARK: The face

    /// The label is drawn twice and the second copy masked to the fill's
    /// leading edge, so the words wipe from one colour to the other exactly as
    /// the fill reaches them. One mechanism for the glyph and the text at once,
    /// and it makes the fill feel like it is passing *through* the button
    /// rather than sliding behind it.
    private func face(_ progress: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            // A mark takes its neighbours' grey rather than the ink a Settings
            // row takes. This is the one thing on the row that cannot be
            // undone, and a control that shouts about that is a control people
            // reach for by accident because it caught their eye.
            row(glyphTint: tint, textTint: isMark ? Chrome.muted : Chrome.ink)

            // The second copy is ink, not words: VoiceOver reads the first one
            // only. Left in, every row was read twice — *Reset everything,
            // Reset everything*, *Release, Release* (mass test, 13 October,
            // finding 10).
            row(glyphTint: filledForeground, textTint: filledForeground)
                .mask(alignment: .leading) {
                    Rectangle().scaleEffect(x: progress, anchor: .leading)
                }
                .accessibilityHidden(true)
        }
        // Behind the label rather than beside it in the stack, so the face is
        // exactly as wide as what it says and never as wide as what it is
        // offered. Scaling a rectangle from its leading edge keeps the
        // advancing edge straight and needs no measurement; the capsule shapes
        // the two ends.
        .background(alignment: .leading) {
            Rectangle()
                .fill(tint)
                .scaleEffect(x: progress, anchor: .leading)
        }
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Chrome.hairline, lineWidth: 1))
        .contentShape(Rectangle())
        // **A pill grows as far as AX2.** The fill wipes across a capsule,
        // and a capsule round three lines of words is a lozenge whose ends cut
        // into the first and last letters; at AX2 the longest of the four
        // labels is still one line on an SE (14 October).
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    @ViewBuilder
    private func row(glyphTint: Color, textTint: Color) -> some View {
        if isMark {
            // `ChromeIconLabel`'s own metrics, and the padding `pressable`
            // would have given it, so this sits in a row of marks at exactly
            // their height and their weight. It draws its own capsule, because
            // the fill has to be clipped to it.
            ChromeIconLabel(
                glyph: glyph,
                title: title2,
                tint: textTint,
                showsTitle: showsWord
            )
            .padding(.horizontal, showsWord ? 18 : 10)
            .padding(.vertical, 10)
        } else {
            HStack(spacing: 10) {
                glyph
                    .stroke(glyphTint, style: Chrome.monoline)
                    .frame(width: 15, height: 15)
                Text(title)
                    .scaledFont(size: 15, weight: .light)
                    .foregroundStyle(textTint)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
    }

    /// The title as a key, for `ChromeIconLabel`.
    ///
    /// `title` is a resource because the consequence beside it is spoken as
    /// well as drawn; the label wants a key. One string, resolved twice.
    private var title2: LocalizedStringKey { LocalizedStringKey(String(localized: title)) }

    // MARK: The hold

    private func begin() {
        guard !holding else { return }
        withAnimation(.easeInOut(duration: 0.28)) { holding = true }
        // Reduce Motion keeps this. The fill is the only thing saying how much
        // longer to hold, which makes it information rather than decoration.
        withAnimation(.linear(duration: Self.duration), completionCriteria: .removed) {
            fill = 1
        } completion: {
            // Abandoning drains the fill, which removes this animation and
            // arrives here too. `holding` is already false by then.
            guard holding else { return }
            complete()
        }
        // Said aloud as it appears, rather than left to the fill to imply.
        AccessibilityNotification.Announcement(String(localized: consequence)).post()
    }

    private func abandon() {
        guard holding else { return }
        withAnimation(.easeInOut(duration: 0.28)) { holding = false }
        withAnimation(.easeOut(duration: Self.drain)) { fill = 0 }
    }

    private func complete() {
        holding = false
        fill = 0
        completions += 1
        action()
    }
}
