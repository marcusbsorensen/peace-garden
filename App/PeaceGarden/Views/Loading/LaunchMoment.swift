import SwiftUI
import UIKit

/// **The launch moment: the fiddlehead growing upward, played once over the app as
/// it opens.**
///
/// There is no ground in the picture, so there are two ways for the stem to begin
/// (`Fiddlehead.Anchor`), and the style switch holds both until Marcus picks:
/// *edge*, where it enters from the screen's bottom edge, and *fixed*, where it
/// grows from a point in space with nothing beneath it.
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
/// **On the suite's dark ground in both appearances** — Marcus's choice on 10
/// October 2026. The ground is `LaunchGround`, the asset the launch screen is
/// painted from (`Info.plist`'s `UILaunchScreen`), read here by name rather than
/// typed again, so that the icon being tapped, the launch screen and the moment
/// are one colour and cannot drift: the one seam a splash exists to hide.
///
/// **It is an overlay and the app is built underneath it**, which is the opposite
/// of UnCubed's choice and deliberate. UnCubed withholds its root so that nothing
/// behind the splash can claim a one-off while nobody can see it; here the point
/// of the moment is the first frame of the stage — Metal compiling the plant's
/// shaders — happening *behind* it and not after it. (That the hitch is gone is
/// the intention and has not been measured: not on a device, and the
/// simulator's GPU would say nothing true.) What could claim a one-off early is
/// `RootView`'s `hearNext()`, which may raise a sheet for a released plant. That
/// sheet is presented above this overlay, so in that one case the moment is
/// covered rather than the sheet delayed. Recorded as the known edge.
struct LaunchMoment: View {

    let style: LoadingStyle
    let onGone: () -> Void

    /// Fixed when this is first built, so the first frame drawn is the moment's
    /// first frame.
    @State private var startedAt = Date()
    @State private var markOpacity = 1.0
    @State private var fieldOpacity = 1.0
    @State private var isLeaving = false

    /// The ground, by the name the launch screen's plist key uses.
    static let ground = Color("LaunchGround")

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Self.ground.ignoresSafeArea()
                TimelineView(.animation(paused: isLeaving && markOpacity == 0)) { timeline in
                    let t = LoadingTiming.progress(elapsed: timeline.date.timeIntervalSince(startedAt))
                    Self.mark(style, at: t, in: proxy.size)
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
        // Two seconds of a decoration, with nothing in it for VoiceOver to
        // say. Its focus belongs on the app that is about to be there.
        .accessibilityHidden(true)
    }

    /// The drawing at `t`, in the icon's own colours on the dark ground that is the
    /// same in both appearances: the contrast is measured against `#0D0D1F` and not
    /// against whatever the app's ground is.
    ///
    /// *Edge* is drawn across the whole screen, because the screen's bottom edge is
    /// what it grows from. *Fixed* is drawn in a frame in the middle of it.
    @ViewBuilder
    static func mark(_ style: LoadingStyle, at t: Double, in screen: CGSize) -> some View {
        let pose = Fiddlehead.pose(atMoment: t)
        switch style.launchAnchor {
        case .bottomEdge?:
            FiddleheadView(pose: pose, palette: .onDark, weight: 2.0, halo: 10, anchor: .bottomEdge)
                .frame(width: screen.width, height: screen.height)
        case .fixedPoint?:
            let frame = markFrame(short: min(screen.width, screen.height))
            FiddleheadView(pose: pose, palette: .onDark, weight: 1.8, halo: 10, anchor: .fixedPoint)
                .frame(width: frame.width, height: frame.height)
        case nil:
            EmptyView()
        }
    }

    /// **How big the fixed-point drawing is, from the shorter side of the screen.**
    /// Not typed per device: 55 % of the short side wide, capped at 340 pt so an
    /// iPad does not get a poster, and half as tall again, because the plant is a
    /// tall thing.
    static func markFrame(short: CGFloat) -> CGSize {
        let side = min(short * 0.55, 340)
        return CGSize(width: side, height: side * 1.5)
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
