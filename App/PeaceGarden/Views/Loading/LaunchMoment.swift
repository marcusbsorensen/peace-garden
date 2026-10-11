import SwiftUI
import UIKit

/// **The launch moment: the fiddlehead growing upward, played once over the app as
/// it opens.**
///
/// There is no ground in the picture: the stem grows from a fixed point in space
/// with nothing beneath it, like the app's 2D plants. Marcus chose that on 10
/// October 2026 over a stem entering from the screen's bottom edge, which is removed.
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
///
/// **The app's name and version stand low on it**, since 11 October 2026
/// (`LaunchNameplate`), and as it starts it asks the App Store once whether
/// there is a newer version (`UpdateCheck`), showing a small arrow beside the
/// version if there is. Neither holds the moment up. Under Reduce Motion there
/// is no moment, so there is neither: the waiting mark's still is not a launch,
/// and a name on it would be repeated at every wait.
struct LaunchMoment: View {

    let onGone: () -> Void

    /// Fixed when this is first built, so the first frame drawn is the moment's
    /// first frame.
    @State private var startedAt = Date()
    @State private var markOpacity = 1.0
    @State private var fieldOpacity = 1.0
    @State private var isLeaving = false
    /// The name and version come in over the launch screen's ground, which is
    /// already there, so they fade rather than arrive (`LoadingTiming.busyFade`).
    @State private var nameplateOpacity = 0.0
    /// Read once, so the moment does not ask the defaults sixty times a second.
    private let style = LoadingSwitch.drawing()
    private let updates = UpdateCheck.shared
    @Environment(\.openURL) private var openURL

    /// The ground, by the name the launch screen's plist key uses.
    static let ground = Color("LaunchGround")

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                ZStack {
                    Self.ground.ignoresSafeArea()
                    TimelineView(.animation(paused: isLeaving && markOpacity == 0)) { timeline in
                        let t = LoadingTiming.progress(elapsed: timeline.date.timeIntervalSince(startedAt))
                        Self.mark(at: t, in: proxy.size, style: style)
                    }
                    .opacity(markOpacity)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .ignoresSafeArea()
            // Any touch ends it, anywhere on the screen. The name and the
            // version take no touch of their own, so a touch on them falls
            // through to here; only the update glyph keeps its own.
            .contentShape(Rectangle())
            .onTapGesture { leave() }
            // Two seconds of a decoration, with nothing in it for VoiceOver to
            // say. Its focus belongs on the app that is about to be there.
            .accessibilityHidden(true)

            // The name and the version, inside the safe area so they stand
            // above the home indicator: the one thing here VoiceOver reads.
            LaunchNameplateFoot {
                if let page = updates.storePage {
                    LaunchUpdateGlyph {
                        openURL(page)
                        leave()
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: LoadingTiming.busyFade), value: updates.storePage)
            .opacity(markOpacity * nameplateOpacity)
        }
        .opacity(fieldOpacity)
        .onAppear {
            withAnimation(.easeIn(duration: LoadingTiming.busyFade)) { nameplateOpacity = 1 }
        }
        .task {
            // Asked as the moment starts and never waited for (`UpdateCheck`).
            updates.start()
            try? await Task.sleep(for: .seconds(LoadingTiming.moment))
            leave()
        }
    }

    /// The drawing at `t`, in the logo's colours on the dark ground that is the
    /// same in both appearances: the contrast is measured against `#0D0D1F` and not
    /// against whatever the app's ground is.
    /// It is drawn in a frame in the middle of the screen, fitted to the moment's
    /// own travel with the plant it ends on centred across it (`Fiddlehead.Fit`).
    static func mark(at t: Double, in screen: CGSize,
                     style: Fiddlehead.Style = LoadingSwitch.drawing()) -> some View {
        let frame = markFrame(short: min(screen.width, screen.height))
        return FiddleheadView(pose: Fiddlehead.pose(atMoment: t), palette: .onDark, weight: 1.8, halo: 10,
                              style: style, fit: .moment)
            .frame(width: frame.width, height: frame.height)
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

    init(style: LoadingStyle = LoadingSwitch.style()) {
        let plays = Self.plays(style: style, reduceMotion: UIAccessibility.isReduceMotionEnabled,
                               alreadyPlayed: LaunchMomentLedger.played)
        _shown = State(initialValue: plays)
        if plays { LaunchMomentLedger.played = true }
    }

    var body: some View {
        if shown {
            LaunchMoment { shown = false }
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
