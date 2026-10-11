import SwiftUI

/// **The app's name and its version, low on the launch moment.** Marcus, 11
/// October 2026: *"we just need to write PeaceGarden and the version number
/// somewhere on it, so it can check for updates if it has a network
/// connection."*
///
/// - **The name is a proper noun** and is written as it is in every language,
///   as the site's wordmark is (`site.css` `.wordmark`, `strings.js`): no key and
///   no translation. It is set the way the wordmark is, light and letter-spaced
///   by 0.18 of its size, and smaller and quieter than the wordmark, because here
///   the plant is the picture and this is its caption.
/// - **The version is the bundle's**, `1.0 (7)` (`AppVersion`), and is held left
///   to right under right to left.
/// - **Beside the version there is room for one thing**, the `accessory`: the
///   update glyph when the App Store has something newer (`UpdateCheck`). It
///   stands on the version's trailing side, so under right to left it is on the
///   left.
/// - **On the launch ground in both appearances**, like the moment, so its
///   colours are fixed rather than the app's adaptive greys: the logo's warm
///   white at the chrome's two text levels, `muted` 0.72 for the name and
///   `faint` 0.56 for the version, 9.1:1 and 5.9:1 on `#0D0D1F`.
/// - **Dynamic Type moves it, within limits.** Both sizes scale, and stop at
///   `xxxLarge`, about 1.3 times the default: past that a caption would start to
///   compete with the plant it is under, and an accessibility size gains
///   nothing on a picture that is gone in two seconds.
/// - **VoiceOver hears it once, as one label**, *Peace Garden 1.0 (7)*. The
///   drawing beside it says nothing (`LaunchMoment`), and the update glyph is a
///   button of its own.
enum LaunchNameplate {

    /// **Where it stands and how big it is**, the three options in
    /// `design/launch-label-2026-10-11/choice.png`. `chosen` is the one drawn.
    enum Placement: String, CaseIterable, Sendable {
        /// A, recommended: the name over the version, centred, a little above
        /// the bottom of the screen. Name 13 pt, version 11 pt.
        case stacked
        /// B: one line at the foot, the name and the version side by side,
        /// both 11 pt. The quietest.
        case line
        /// C: the name under the plant at 17 pt, a caption to it, and the
        /// version alone at the foot.
        case underPlant
    }

    static let chosen = Placement.stacked

    /// The name, which is the same in every language.
    static let name = "Peace Garden"

    /// What VoiceOver says, in one go.
    static func spoken(_ version: AppVersion) -> String { "\(name) \(version.display)" }

    // MARK: - Colour

    /// The logo's warm white, `Fiddlehead.Palette.onDark.leaf`.
    static let ink = Fiddlehead.Palette.onDark.leaf
    /// `Chrome.muted`'s level, for the name.
    static let nameOpacity = 0.72
    /// `Chrome.faint`'s level, for the version and the glyph beside it.
    static let versionOpacity = 0.56

    /// The colour a level of the warm white lands as on the launch ground,
    /// for measuring.
    static func landed(_ opacity: Double) -> Fiddlehead.Palette.RGB {
        let g = Fiddlehead.Palette.launchGround
        return .init(g.r + (ink.r - g.r) * opacity, g.g + (ink.g - g.g) * opacity,
                     g.b + (ink.b - g.b) * opacity)
    }

    static var nameColor: Color { ink.color.opacity(nameOpacity) }
    static var versionColor: Color { ink.color.opacity(versionOpacity) }

    // MARK: - Size and place

    /// Points, at the default text size, before Dynamic Type.
    static func nameSize(_ placement: Placement) -> CGFloat {
        switch placement {
        case .stacked: 13
        case .line: 11
        case .underPlant: 17
        }
    }

    static let versionSize: CGFloat = 11

    /// How far the letters stand apart, as a share of the size: the wordmark's
    /// 0.18 em.
    static let tracking: CGFloat = 0.18

    /// The largest text size it follows. See the type's note.
    static let largestType = DynamicTypeSize.xxxLarge

    /// How far above the bottom of the safe area the lowest line sits.
    static func foot(_ placement: Placement) -> CGFloat {
        switch placement {
        case .stacked: 28
        case .line, .underPlant: 14
        }
    }

    /// For `underPlant`: how far under the launch frame's foot the name stands.
    static let underPlantGap: CGFloat = 22
}

// MARK: - The two layers

/// **The part at the foot of the screen**, laid out inside the safe area, so
/// that it stands above the home indicator. Carries the one accessibility
/// label whatever the placement.
struct LaunchNameplateFoot<Accessory: View>: View {
    var placement: LaunchNameplate.Placement = LaunchNameplate.chosen
    var version: AppVersion = .current
    @ViewBuilder var accessory: () -> Accessory

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            content
                .padding(.bottom, LaunchNameplate.foot(placement))
        }
        .frame(maxWidth: .infinity)
        .dynamicTypeSize(...LaunchNameplate.largestType)
    }

    @ViewBuilder
    private var content: some View {
        switch placement {
        case .stacked:
            VStack(spacing: 6) {
                LaunchName(size: LaunchNameplate.nameSize(.stacked))
                versionRow
            }
        case .line:
            HStack(spacing: 12) {
                LaunchName(size: LaunchNameplate.nameSize(.line))
                versionRow
            }
        case .underPlant:
            versionRow
        }
    }

    /// The version, and the accessory on its trailing side. The version is
    /// centred and the accessory hangs beside it, so the version stands where it
    /// would stand alone and nothing shifts when the glyph arrives.
    private var versionRow: some View {
        LaunchVersion(version: version)
            .overlay(alignment: .trailing) {
                accessory()
                    .fixedSize()
                    .alignmentGuide(.trailing) { $0[.leading] - 6 }
            }
    }
}

extension LaunchNameplateFoot where Accessory == EmptyView {
    init(placement: LaunchNameplate.Placement = LaunchNameplate.chosen, version: AppVersion = .current) {
        self.init(placement: placement, version: version) { EmptyView() }
    }
}

/// **The part under the plant**, for `underPlant` alone: drawn in the moment's
/// full-screen layer, where the launch frame's foot is known. VoiceOver hears
/// the name with the version, at the foot, so this one is hidden.
struct LaunchNameplateUnderPlant: View {
    let screen: CGSize
    var placement: LaunchNameplate.Placement = LaunchNameplate.chosen

    var body: some View {
        if placement == .underPlant {
            let frame = LaunchMoment.markFrame(short: min(screen.width, screen.height))
            LaunchName(size: LaunchNameplate.nameSize(.underPlant))
                .dynamicTypeSize(...LaunchNameplate.largestType)
                .fixedSize()
                .position(x: screen.width / 2,
                          y: screen.height / 2 + frame.height / 2 + LaunchNameplate.underPlantGap)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - The pieces

/// The name, light and letter-spaced, as the wordmark.
private struct LaunchName: View {
    let size: CGFloat
    @ScaledMetric private var scaled: CGFloat

    init(size: CGFloat) {
        self.size = size
        _scaled = ScaledMetric(wrappedValue: size, relativeTo: .footnote)
    }

    var body: some View {
        Text(verbatim: LaunchNameplate.name)
            .font(.system(size: scaled, weight: .light))
            .tracking(scaled * LaunchNameplate.tracking)
            .foregroundStyle(LaunchNameplate.nameColor)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            // Any touch ends the moment: this one falls through to the ground.
            .allowsHitTesting(false)
            // Spoken with the version, as one label.
            .accessibilityHidden(true)
    }
}

/// The version, `1.0 (7)`, held left to right. **The one label VoiceOver
/// reads**, *Peace Garden 1.0 (7)*, so the name and the version are heard
/// together and once, and the update glyph beside it stays a button of its own.
private struct LaunchVersion: View {
    let version: AppVersion
    @ScaledMetric(relativeTo: .caption2) private var scaled: CGFloat = LaunchNameplate.versionSize

    var body: some View {
        Text(verbatim: version.drawn)
            .font(.system(size: scaled, weight: .light).monospacedDigit())
            .foregroundStyle(LaunchNameplate.versionColor)
            .lineLimit(1)
            .allowsHitTesting(false)
            .accessibilityLabel(Text(verbatim: LaunchNameplate.spoken(version)))
    }
}

/// **The update glyph**: an up-arrow in a circle beside the version, when the
/// App Store has a newer one. An SF Symbol and no word, so it costs no
/// translations; VoiceOver hears one short key. It is drawn at the version's
/// size and touched through a 44-point target, so a glyph the size of a numeral
/// is still a place a thumb can find.
struct LaunchUpdateGlyph: View {
    let action: () -> Void
    @ScaledMetric(relativeTo: .caption2) private var scaled: CGFloat = LaunchNameplate.versionSize + 2

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.up.circle")
                .font(.system(size: scaled, weight: .light))
                .foregroundStyle(LaunchNameplate.nameColor)
                .padding(16)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(-16)
        .accessibilityLabel(Text("Newer version in the App Store",
                                 comment: "VoiceOver only. The small arrow beside the version on the opening picture, shown when the App Store has a newer version of the app. Opens the App Store."))
    }
}
