import SeedCore
import SwiftUI

// The pieces of the garden screen's tray, and the small panel a long press
// opens on a light. `PlotView` lays them out; these are only what they are.
// `docs/ARRANGING.md` §*The tray, and turning a figure*.

/// What the garden screen's controls are found by in a test. Never shown, and
/// never read aloud: VoiceOver reads each control's label.
enum PlotControls {
    static let tray = "garden.tray"
    static let turnAnticlockwise = "garden.turn.anticlockwise"
    static let turnClockwise = "garden.turn.clockwise"
    static let reset = "garden.reset"
}

/// The backing each figure in the tray stands on.
///
/// **Why there is one** (Marcus, 11 October): at night a lantern's flame or a
/// glowing hare in the row is a bright point on a sky full of them, and which
/// bright points could be put on the garden was hard to tell. By day the
/// clouds drift behind the row the same way. A plate under each figure takes
/// the sky out from behind it and says *this is a thing to pick up*.
///
/// **A blurred material rather than a flat fill.** Behind a blur the stars
/// and the clouds go to nothing, which is the whole job, while the sky's own
/// colour still comes through, so the plate is a piece of the sky made quiet
/// rather than a hole cut in it. A rounded rectangle, because the tray is
/// chrome and not the scene, and its corners are the radius every plate and
/// capsule in the app's chrome already has.
///
/// Three strengths were drawn and Marcus is choosing between them
/// (`design/garden-controls-2026-10-11/`); `chosen` is the one built, and the
/// others, and the row as it was, are a word away.
enum FigurePlate: String, CaseIterable {
    /// **A**: a thin blur, darkened a little, with a hairline edge.
    case soft
    /// **B**: the thinnest blur and nothing else, no edge.
    case faint
    /// **C**: a thicker blur, darker, with the edge.
    case firm
    /// No plate: the row as it was until 11 October.
    case none

    static let chosen: FigurePlate = .soft

    /// What is drawn: `chosen`, or in a Debug build whatever `-pgPlate` names,
    /// so the three can be photographed from one build.
    static var current: FigurePlate {
        #if DEBUG
        if let tried = UserDefaults.standard.string(forKey: "pgPlate").flatMap(FigurePlate.init(rawValue:)) {
            return tried
        }
        #endif
        return chosen
    }

    private var material: Material {
        switch self {
        case .faint, .soft, .none: return .ultraThinMaterial
        case .firm: return .thinMaterial
        }
    }

    /// The ground's colour laid over the blur, so a glowing figure has
    /// something darker than itself to glow against.
    private var tint: Double {
        switch self {
        case .faint, .none: return 0
        case .soft: return 0.22
        case .firm: return 0.42
        }
    }

    private var hasEdge: Bool { self == .soft || self == .firm }

    /// How far the plate reaches past the figure's button: enough above for
    /// the paper lamp's halo, which hangs past the top.
    var reach: EdgeInsets {
        self == .none ? EdgeInsets() : EdgeInsets(top: 6, leading: 3, bottom: 2, trailing: 3)
    }

    /// Between one button and the next, so the plates stand apart rather than
    /// running into one bar.
    var spacing: CGFloat { self == .none ? 10 : 12 }

    private static let corner: CGFloat = 13

    @ViewBuilder
    var plate: some View {
        if self != .none {
            let shape = RoundedRectangle(cornerRadius: Self.corner, style: .continuous)
            shape
                .fill(material)
                .overlay(shape.fill(Chrome.ground.opacity(tint)))
                .overlay(shape.strokeBorder(Chrome.hairline.opacity(hasEdge ? 0.7 : 0), lineWidth: 0.75))
                .padding(EdgeInsets(top: -reach.top, leading: -reach.leading,
                                    bottom: -reach.bottom, trailing: -reach.trailing))
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

/// How the row of grounds says which one the garden stands on.
///
/// **Until 11 October the rest stood back at 0.42**, and Marcus could not tell
/// them apart: a landscape at under half strength on a night sky is a dark
/// lozenge, and by day the sky's blue came through every one of them alike.
/// Each treatment brings them up; they differ in how the chosen one is still
/// told apart. Being decided, as `FigurePlate` is.
enum GroundMarking: String, CaseIterable {
    /// **A**: every ground at full strength, and a short bar under the chosen
    /// one — the mark a row of tabs uses for *this one*. A bar and not a dot,
    /// because at night a white dot under a landscape is one more star.
    case bar
    /// **B**: the rest brought up to three quarters, and nothing added.
    case brighter
    /// **C**: every ground at full strength, and the chosen one standing in a
    /// pool of light, the garden's own way of saying *look here*.
    case pool
    /// The rest at 0.42: the row as it was until 11 October.
    case standBack

    static let chosen: GroundMarking = .bar

    /// `chosen`, or in a Debug build whatever `-pgGrounds` names.
    static var current: GroundMarking {
        #if DEBUG
        if let tried = UserDefaults.standard.string(forKey: "pgGrounds").flatMap(GroundMarking.init(rawValue:)) {
            return tried
        }
        #endif
        return chosen
    }

    /// How strongly the grounds that are not chosen are drawn.
    var others: Double {
        switch self {
        case .bar, .pool: return 1
        case .brighter: return 0.75
        case .standBack: return 0.42
        }
    }

    /// The bar: as long as a word is tall, and as thick as a stroke.
    static let barSize = CGSize(width: 14, height: 2.5)

    /// Between the foot of a ground and the top of its bar.
    static let barGap: CGFloat = 5

    /// Room under the row for the bar.
    var footRoom: CGFloat { self == .bar ? Self.barSize.height + Self.barGap + 2 : 0 }
}

/// The plus at the foot of the garden that opens the tray, and the minus that
/// shuts it again.
///
/// **Shut by default, every time.** The garden is for looking at, and the tray
/// is for changing it; a row of figures and grounds standing open under every
/// visit made the screen a workbench. Not remembered between visits, because
/// somebody who opened it last time was doing something, and that is done.
struct TrayToggle: View {
    let isOpen: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            TrayGlyph(openness: isOpen ? 1 : 0)
                .stroke(Chrome.ink.opacity(0.75), style: Chrome.monoline)
                .frame(width: 16, height: 16)
                .pressable(horizontal: 13, vertical: 13)
        }
        .buttonStyle(.plain)
        // No new word: the system's own plus says what it is in every language
        // the phone speaks, and *Done* is already translated.
        .accessibilityLabel(isOpen ? Text("Done") : Text(Image(systemName: "plus")))
    }
}

/// A row that scrolls sideways and says when there is more of it.
///
/// **Marcus's double chevron**, 1 October: the row of grounds ran off the edge
/// of the screen and nothing said there were more of them. The row's far end
/// fades, and a small double chevron stands in the fade. Only while there is
/// more that way — a chevron at the end of a row that has ended would be
/// pointing at nothing — and at the near end too, once it has been scrolled.
struct ContinuingRow<Content: View>: View {
    @ViewBuilder let content: () -> Content

    /// The content's frame in the scroll view's own space, which is where it
    /// has been scrolled to.
    @State private var laid: CGRect = .zero
    @State private var width: CGFloat = 0

    private var moreAfter: Bool { width > 0 && laid.maxX > width + 1 }
    private var moreBefore: Bool { laid.minX < -1 }

    private static var fade: CGFloat { 30 }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            content()
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .scrollView) } action: { laid = $0 }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .mask {
            HStack(spacing: 0) {
                LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
                    .frame(width: moreBefore ? Self.fade : 0)
                Color.black
                LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(width: moreAfter ? Self.fade : 0)
            }
        }
        .overlay(alignment: .trailing) { hint(towardsTrailing: true, shown: moreAfter) }
        .overlay(alignment: .leading) { hint(towardsTrailing: false, shown: moreBefore) }
        .animation(.easeOut(duration: 0.2), value: moreAfter)
        .animation(.easeOut(duration: 0.2), value: moreBefore)
    }

    private func hint(towardsTrailing: Bool, shown: Bool) -> some View {
        DoubleChevronGlyph(towardsTrailing: towardsTrailing)
            .stroke(Chrome.muted, style: Chrome.monoline)
            .frame(width: 12, height: 11)
            .opacity(shown ? 1 : 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// One mark in the tray or the panel: a drawn glyph in a round edge.
///
/// **Labelled by a system symbol rather than a word.** The glyph is drawn in
/// this garden's own hand, and what VoiceOver says is the system symbol's own
/// name for the same action, in the phone's own language — so the mark costs
/// no translations.
struct TrayMark<Glyph: Shape>: View {
    let glyph: Glyph
    let says: String
    var isEnabled = true
    var size: CGFloat = 20
    /// Its own round edge, as every button here wears. Not inside the panel,
    /// whose capsule is already the edge: a ring in a ring is a diagram.
    var ringed = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            let mark = glyph
                .stroke(isEnabled ? Chrome.ink.opacity(0.8) : Chrome.faint.opacity(0.5),
                        style: Chrome.monoline)
                .frame(width: size, height: size)
            if ringed {
                mark.pressable(horizontal: 11, vertical: 11)
            } else {
                mark.frame(width: 40, height: 40).contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(Text(Image(systemName: says)))
    }
}

/// What a long press on a light opens, if the finger lets go without carrying
/// it anywhere: turn it, and make it smaller or larger.
///
/// **Held and let go, rather than a second gesture.** A long press already
/// lifts a light to carry it, and nobody has to learn a new one: a light that
/// is lifted and put straight back down was not being moved, so the same press
/// is taken as asking about it. Carrying is unchanged.
///
/// Turning is offered only to the figures. They are modelled and rendered at
/// eight facings; a lantern on a post and a drift of fireflies look the same
/// from every side, and a control that changes nothing is worse than none.
struct LampPanel: View {
    let lamp: Lamp
    let change: (_ edit: (inout Lamp) -> Void) -> Void

    private var turns: Bool {
        lamp.known.map(GardenCreatures.isCreature) ?? false
    }

    private static var steps: Int {
        Int(((Lamp.scales.upperBound - Lamp.scales.lowerBound) / Lamp.scaleStep).rounded())
    }

    private var step: Int {
        Int(((lamp.drawnScale - Lamp.scales.lowerBound) / Lamp.scaleStep).rounded())
    }

    var body: some View {
        HStack(spacing: 2) {
            if turns {
                // A positive facing is a turn about the upright that is
                // anticlockwise seen from above, which is how it is seen here.
                TrayMark(glyph: TurnGlyph(clockwise: false), says: "rotate.left", size: 18, ringed: false) {
                    change { $0.facing = ($0.drawnFacing + 1) % 8 }
                }
                TrayMark(glyph: TurnGlyph(clockwise: true), says: "rotate.right", size: 18, ringed: false) {
                    change { $0.facing = ($0.drawnFacing + 7) % 8 }
                }
                Rectangle()
                    .fill(Chrome.hairline)
                    .frame(width: 1, height: 22)
                    .padding(.horizontal, 4)
            }

            TrayMark(glyph: SizeGlyph(larger: false), says: "arrow.down.right.and.arrow.up.left",
                     isEnabled: step > 0, size: 18, ringed: false) {
                resize(by: -1)
            }

            // Where it is between the smallest and the largest, so the range is
            // seen rather than found by pressing until nothing happens.
            HStack(spacing: 4) {
                ForEach(0...Self.steps, id: \.self) { index in
                    Circle()
                        .fill(index == step ? Chrome.ink : Chrome.faint.opacity(0.6))
                        .frame(width: index == step ? 5 : 3, height: index == step ? 5 : 3)
                }
            }
            .frame(height: 5)
            .padding(.horizontal, 2)
            .accessibilityHidden(true)

            TrayMark(glyph: SizeGlyph(larger: true), says: "arrow.up.left.and.arrow.down.right",
                     isEnabled: step < Self.steps, size: 18, ringed: false) {
                resize(by: 1)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(Capsule().fill(Chrome.ground.opacity(0.78)))
        .overlay(Capsule().strokeBorder(Chrome.hairline, lineWidth: 1))
        .sensoryFeedback(.selection, trigger: lamp)
    }

    /// A step smaller or larger. Back at its own size, nothing is stored, so a
    /// light that was tried larger and put back is written exactly as before.
    private func resize(by steps: Int) {
        change { lamp in
            let next = min(max(step + steps, 0), Self.steps)
            let scale = Lamp.scales.lowerBound + Double(next) * Lamp.scaleStep
            lamp.scale = abs(scale - 1) < 0.001 ? nil : scale
        }
    }
}
