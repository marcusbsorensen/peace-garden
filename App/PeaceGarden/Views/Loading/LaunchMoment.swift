import SwiftUI
import UIKit

/// **The launch moment: the chosen loading animation, played once over the app
/// as it opens.**
///
/// Everything about *how* it behaves is the Interfulgent pattern, and the sources
/// are named so that none of it is this file's invention:
///
/// - **It is a function of the clock and of nothing else** (UnCubed's
///   `LaunchSplashView`, Pfish's `LaunchCurtainView`): `TimelineView` with a phase
///   derived from elapsed time, never an animation retargeted by what the app is
///   doing. That is the argument that it cannot report progress it does not have.
/// - **Any touch ends it** (all three apps' `anyTouchLiftsIt` / *Tap to skip*).
///   Somebody who has opened the app to look at their plant taps straight through.
/// - **The mark leaves over 120 ms and the ground over 180 ms, started together**
///   (UnCubed and FlagFans, the same two figures): the mark never floats over the
///   screen it is handing over to.
/// - **Reduce Motion gets nothing at all** (all three): not a shorter moment. A
///   120 ms curtain would still be a curtain. See `LaunchMomentHost`.
///
/// **It is an overlay and the app is built underneath it**, which is the opposite
/// of UnCubed's choice and deliberate. UnCubed withholds its root so that nothing
/// behind the splash can claim a one-off while nobody can see it; here the point
/// of the moment is the first frame of the stage — Metal compiling the plant's
/// shaders — happening *behind* it and not after it. (That the hitch is gone is
/// the intention and has not been measured: not on a device, and the
/// simulator's GPU would say nothing true.) What could claim a one-off
/// early is `RootView`'s `hearNext()`, which may raise a sheet for a released
/// plant. That sheet is presented above this overlay, so in that one case the
/// moment is covered rather than the sheet delayed. Recorded as the known edge.
struct LaunchMoment: View {

    let style: LoadingStyle
    let onGone: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    /// Fixed when this is first built, so the first frame drawn is the moment's
    /// first frame.
    @State private var startedAt = Date()
    @State private var markOpacity = 1.0
    @State private var fieldOpacity = 1.0
    @State private var isLeaving = false

    var body: some View {
        GeometryReader { proxy in
            let frame = Self.markFrame(for: style, short: min(proxy.size.width, proxy.size.height))
            ZStack {
                ground.ignoresSafeArea()
                TimelineView(.animation(paused: isLeaving && markOpacity == 0)) { timeline in
                    let t = LoadingTiming.progress(elapsed: timeline.date.timeIntervalSince(startedAt))
                    mark(at: t)
                        .frame(width: frame.width, height: frame.height)
                }
                .opacity(markOpacity)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .opacity(fieldOpacity)
        .contentShape(Rectangle())
        .onTapGesture { leave() }
        .task {
            try? await Task.sleep(for: .seconds(LoadingTiming.moment))
            leave()
        }
        // Sixty-odd frames of a decoration, with nothing in them for VoiceOver to
        // say. Its focus belongs on the app that is about to be there.
        .accessibilityHidden(true)
    }

    /// **How big the mark is, from the shorter side of the screen.** Not typed per
    /// device: 46 % of the short side, capped at 320 pt so an iPad does not get a
    /// poster. The frond is a tall thin drawing and is given a taller frame, so
    /// that its hairline and its leaf are as present as the coil is.
    static func markFrame(for style: LoadingStyle, short: CGFloat) -> CGSize {
        let side = min(short * 0.46, 320)
        switch style {
        case .frond: return CGSize(width: side * 0.9, height: side * 1.25)
        case .unwinding, .off: return CGSize(width: side, height: side)
        }
    }

    private var ground: Color {
        switch style {
        case .unwinding: return UnwindingMark.ground
        case .frond, .off: return Chrome.ground
        }
    }

    @ViewBuilder
    private func mark(at t: Double) -> some View {
        switch style {
        case .unwinding:
            UnwindingMarkView(pose: UnwindingMark.pose(atMoment: t), dress: .brand)
        case .frond:
            // Gold on the dark ground, as the backdrop's; on the light ground gold
            // would be 1.8:1, so the app's ink carries the line and the gold stays
            // as the halo it sits in.
            FiddleheadView(pose: Fiddlehead.pose(atMoment: t),
                           ink: colorScheme == .dark ? Fiddlehead.gold.opacity(0.95) : Chrome.ink.opacity(0.8),
                           weight: 1.8, halo: 10)
        case .off:
            EmptyView()
        }
    }

    /// One place the moment begins to go, so a touch and the clock arriving in
    /// the same frame are one hand-over and not two.
    private func leave() {
        guard !isLeaving else { return }
        isLeaving = true
        withAnimation(.easeOut(duration: LoadingTiming.markFade)) { markOpacity = 0 }
        withAnimation(.easeInOut(duration: LoadingTiming.dissolve)) { fieldOpacity = 0 }
        Task {
            try? await Task.sleep(for: .seconds(LoadingTiming.dissolve))
            onGone()
        }
    }
}

/// **Decides whether the moment plays at all, once, as the app opens.**
///
/// Not when the switch says `off`, not under Reduce Motion, and not a second time
/// in the same process — a second window or a scene reconnecting is not a launch.
struct LaunchMomentHost: View {

    @State private var shown: Bool
    private let style: LoadingStyle

    init(style: LoadingStyle = LoadingSwitch.style()) {
        self.style = style
        let plays = Self.plays(style: style, reduceMotion: UIAccessibility.isReduceMotionEnabled,
                               alreadyPlayed: LaunchMomentLedger.played)
        _shown = State(initialValue: plays)
        if plays { LaunchMomentLedger.played = true }
    }

    var body: some View {
        if shown {
            LaunchMoment(style: style) { shown = false }
        }
    }

    /// The whole decision, as a function of its three inputs so that a test can
    /// ask it every question.
    static func plays(style: LoadingStyle, reduceMotion: Bool, alreadyPlayed: Bool) -> Bool {
        style != .off && !reduceMotion && !alreadyPlayed
    }
}

@MainActor
enum LaunchMomentLedger {
    static var played = false
}
