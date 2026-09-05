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
    static let ink = adaptive(dark: .white, light: UIColor(white: 0.07, alpha: 1))
    static let muted = adaptive(dark: UIColor(white: 1, alpha: 0.72),
                                light: UIColor(white: 0.07, alpha: 0.70))
    static let faint = adaptive(dark: UIColor(white: 1, alpha: 0.56),
                                light: UIColor(white: 0.07, alpha: 0.52))
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

    var label: LocalizedStringResource {
        switch self {
        case .abstract: return "One of the places"
        case .geographic: return "Where you actually are"
        case .custom: return "Something you write"
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
private struct ChromeLetterCase: ViewModifier {
    @Environment(\.locale) private var locale

    func body(content: Content) -> some View {
        content.textCase(Chrome.letterCase(in: locale))
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

    /// Small, wide-tracked, uppercase: the app's label voice.
    func chromeLabel(size: CGFloat = 11, weight: Font.Weight = .light) -> some View {
        font(.system(size: size, weight: weight, design: .default))
            .modifier(ChromeTracking(2.4))
            .modifier(ChromeLetterCase())
    }

    /// The heading voice: uppercase and wide-tracked, like the label voice but
    /// at size. It is what marks the three moments the app explains itself —
    /// the seed forming, the seed planted, two seeds meeting — as one sequence
    /// rather than three unrelated screens.
    func chromeHeading(size: CGFloat = 20) -> some View {
        font(.system(size: size, weight: .light, design: .default))
            .modifier(ChromeTracking(2.8))
            .modifier(ChromeLetterCase())
    }

    /// The serif voice, used only for plant names.
    ///
    /// "Only" is meant literally, and for a while it was not true: four screen
    /// titles were wearing it, which claims that "A seed on the wind" and
    /// "Peace garden" are things something is *called*. It is now on four
    /// views, all of them a `genome.name.full`. Grep before adding a fifth.
    func plantName(size: CGFloat = 26) -> some View {
        font(.system(size: size, weight: .light, design: .serif))
            .italic()
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
                .pressable(isProminent: isProminent)
        }
        .buttonStyle(.plain)
    }
}

extension View {
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

    /// `horizontal` is for a control with nothing but a glyph in it, where the
    /// standing inset makes a wide oval out of something that should be round.
    func pressable(isProminent: Bool = false, horizontal: CGFloat = 18) -> some View {
        padding(.horizontal, horizontal)
            .padding(.vertical, 12)
            .overlay(
                Capsule().strokeBorder(
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

/// A recycling turn, without the corporate triangle.
///
/// Three arrows meeting at right angles is a glyph from another visual system
/// and this app has none of those angles. Three logarithmic fronds chasing one
/// another round is the app's own spiral said three times, and it carries the
/// meaning worth having — that the material returns, rather than that it is
/// destroyed.
struct CycleGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2 - 0.7
        let inner = outer * 0.34
        // Each frond overruns its own third of the circle, so its open tip
        // reaches past the tight start of the next one and the three read as
        // chasing rather than as three separate marks.
        let sweep = Double.pi * 140 / 180
        let steps = 26

        var path = Path()
        for frond in 0..<3 {
            let start = Double(frond) * 2 * .pi / 3 - .pi / 2
            for step in 0...steps {
                let along = Double(step) / Double(steps)
                // Logarithmic, like the mark: tight at the centre, opening as
                // it turns. An even gain reads as wound rather than as growing.
                let radius = inner * pow(outer / inner, along)
                let point = polar(centre, radius, start + sweep * along)
                if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
        }
        return path
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
    /// Two points over the thirteen the spec asked for. Eight teeth on a ring
    /// at the hairline weight do not survive thirteen: see `CogShape`.
    var glyphSize: CGFloat = 15
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
                // than clip, which is the one place in the chrome where type
                // is not a fixed size.
                .lineLimit(1)
                .minimumScaleFactor(axis == .horizontal ? 1 : 0.75)
                .fixedSize(horizontal: axis == .horizontal, vertical: true)
                .transition(.opacity)
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
/// **Only a phone can test this.** Injected touches on a simulator are not
/// sustained however long a path says to hold for: the press arrives and is
/// released in the same instant, so a hold begins and is abandoned before a
/// frame is drawn and nothing is ever seen. Each link was proved separately
/// there — the press registers, the fill animates, its completion fires the
/// action — but the whole gesture end to end has to be done with a thumb. Two
/// things to watch when it is: that three seconds is right rather than long,
/// and that a thumb drifting during the hold does not hand the touch to the
/// scroll view and cancel it.
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
        VStack(alignment: .leading, spacing: 8) {
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

            if holding {
                Text(consequence)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Chrome.muted)
                    .lineSpacing(4)
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
            Rectangle()
                .fill(tint)
                // Scaling a rectangle from its leading edge keeps the advancing
                // edge straight and needs no measurement; the capsule below
                // shapes the two ends.
                .scaleEffect(x: progress, anchor: .leading)

            row(glyphTint: tint, textTint: Chrome.ink)

            row(glyphTint: filledForeground, textTint: filledForeground)
                .mask(alignment: .leading) {
                    Rectangle().scaleEffect(x: progress, anchor: .leading)
                }
        }
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Chrome.hairline, lineWidth: 1))
        .contentShape(Rectangle())
    }

    private func row(glyphTint: Color, textTint: Color) -> some View {
        HStack(spacing: 10) {
            glyph
                .stroke(glyphTint, style: Chrome.monoline)
                .frame(width: 15, height: 15)
            Text(title)
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(textTint)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

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
