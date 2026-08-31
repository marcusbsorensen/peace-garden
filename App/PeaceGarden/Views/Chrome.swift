import SwiftUI

/// The app's whole visual vocabulary, in one place.
///
/// Everything is thin, letterspaced and slightly transparent, sitting on the
/// near-black of `StageBackdrop` so the plant is the only saturated thing on
/// screen. Controls are quiet enough to disappear and be forgotten between
/// taps.
enum Chrome {
    static let ink = Color.white
    static let muted = Color.white.opacity(0.55)
    static let faint = Color.white.opacity(0.28)
    static let hairline = Color.white.opacity(0.16)

    /// Text stops being readable somewhere past this. On an iPad a paragraph
    /// set to the full width of the screen is a wall; the plant is allowed the
    /// whole screen, the words are not.
    static let readableWidth: CGFloat = 440

    static let fadeIn = Animation.easeInOut(duration: 0.55)
    static let controlsIdleTimeout: Duration = .seconds(6)
}

extension View {
    /// Small, wide-tracked, uppercase: the app's label voice.
    func chromeLabel(size: CGFloat = 11, weight: Font.Weight = .light) -> some View {
        font(.system(size: size, weight: weight, design: .default))
            .tracking(2.4)
            .textCase(.uppercase)
    }

    /// The heading voice: uppercase and wide-tracked, like the label voice but
    /// at size. It is what marks the three moments the app explains itself —
    /// the seed forming, the seed planted, two seeds meeting — as one sequence
    /// rather than three unrelated screens.
    func chromeHeading(size: CGFloat = 20) -> some View {
        font(.system(size: size, weight: .light, design: .default))
            .tracking(2.8)
            .textCase(.uppercase)
    }

    /// The serif voice, used only for plant names.
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

/// A control that reads as a line of text rather than a button.
struct QuietButton: View {
    let title: String
    var isProminent: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .chromeLabel()
                .foregroundStyle(isProminent ? Chrome.ink : Chrome.muted)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
/// The pair are mirrored, so whatever one does the other does — the line reads
/// as one thing sprouting rather than two decorations that happen to match.
struct SproutingRule: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var open = false

    // Never fully open: past about 0.7 the coil has let go entirely, and what is
    // left reads as a stray hook on the end of the line rather than as a tendril.
    private var unfurl: Double { reduceMotion ? 0.5 : (open ? 0.66 : 0.12) }

    var body: some View {
        HStack(spacing: 0) {
            tendril.scaleEffect(x: -1, y: 1)
            Hairline()
            tendril
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
    private var tendril: some View {
        Tendril(unfurl: unfurl)
            .stroke(Chrome.faint, style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            .frame(width: 40, height: 46)
    }
}
