import SwiftUI

/// **The waiting mark: the same fiddlehead as the launch moment, smaller, for a
/// wait the person started.**
///
/// UnCubed is the one suite app with a counterpart (`BusyMark`, `CheckingRing`),
/// and what it settled is what this takes: show nothing for the first 400 ms; draw
/// a mark in the app's own idiom that is *built and rebuilt* rather than a
/// spinner; keep it small; and under Reduce Motion keep the statement and lose the
/// movement — the same drawing, held still.
///
/// **A smaller version of the same thing.** The tip comes up out of the soil,
/// uncurls a little and settles back, over `LoadingTiming.breath`; it never rises
/// as far as the launch moment's stem or opens as far.
///
/// **It follows the app's own appearance** — Marcus's choice on 10 October 2026 —
/// because it sits inside the app's screens, on the app's ground, and not on the
/// launch ground. On the dark ground it is the icon's greens and white bract; on
/// the light ground the same hues solved to 4.5:1 and the app's ink for the leaf
/// (`Fiddlehead.Palette`), since the icon's own values would be 1.4:1 there.
struct LoadingBusyMark: View {

    /// The mark's height; its width follows, the soil being wider than the stem.
    var size: CGFloat = 40

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var startedAt = Date()

    /// The frame it is drawn in: wider than tall, because the soil is.
    static func frame(forSize size: CGFloat) -> CGSize {
        CGSize(width: size * 2.1, height: size * 1.6)
    }

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            FiddleheadView(pose: pose(at: timeline.date), palette: palette, weight: 1.5, halo: 0)
                .frame(width: Self.frame(forSize: size).width, height: Self.frame(forSize: size).height)
        }
    }

    private var palette: Fiddlehead.Palette {
        (colorScheme == .dark ? Fiddlehead.Palette.onDark : Fiddlehead.Palette.onLight).small
    }

    /// The breath at this instant, or the still pose when motion is off.
    private func pose(at date: Date) -> Fiddlehead.Pose {
        guard !reduceMotion else { return Fiddlehead.still }
        return Fiddlehead.pose(atBreath: LoadingTiming.breathPhase(elapsed: date.timeIntervalSince(startedAt)))
    }
}

/// **Draws the waiting mark over a view while a request is out, once it has been
/// out for 400 ms.**
///
/// The threshold is counted from when the wait begins, which is `isBusy` turning
/// true, and a request that answers before it never shows a mark at all. The view
/// underneath is the caller's to dim; the mark is not dimmed with it.
private struct BusyMarkModifier: ViewModifier {

    let isBusy: Bool
    @State private var showing = false

    func body(content: Content) -> some View {
        content
            .overlay {
                if showing {
                    LoadingBusyMark()
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }
            }
            .animation(.easeInOut(duration: LoadingTiming.busyFade), value: showing)
            .task(id: isBusy) {
                guard isBusy else {
                    showing = false
                    return
                }
                try? await Task.sleep(for: .seconds(LoadingTiming.busyThreshold))
                guard !Task.isCancelled else { return }
                showing = true
            }
    }
}

extension View {
    /// The waiting mark, after the threshold. Nothing at all while the switch
    /// says `off`, which is the app exactly as it was.
    func busyMark(_ isBusy: Bool, style: LoadingStyle = LoadingSwitch.style()) -> some View {
        modifier(BusyMarkModifier(isBusy: isBusy && style != .off))
    }
}
