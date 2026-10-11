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
/// **A smaller version of the same thing.** The tip comes up out of nothing,
/// uncurls a little and settles back, over `LoadingTiming.breath`; it never rises
/// as far as the launch moment's stem or opens as far.
///
/// **It follows the app's own appearance** — Marcus's choice on 10 October 2026 —
/// because it sits inside the app's screens, on the app's ground, and not on the
/// launch ground. On the dark ground it is the logo's sage-to-green-gold and warm
/// white leaf; on the light ground the logo's light-ground stops, 4.6:1, and the
/// app's ink for the leaf (`Fiddlehead.Palette`), since the dark-ground green-gold
/// would be 1.8:1 there.
///
/// **Its breath does not lift.** The leaf lifting is how the launch moment ends;
/// the breathing mark is a curl and stays one, fitted to its own travel
/// (`Fiddlehead.Fit.waiting`), so it is no smaller than it was. Under Reduce
/// Motion it holds still as a small standing sprout with its leaf lifted
/// (`Fiddlehead.still`, Marcus, 11 October 2026), inside the same fit.
struct LoadingBusyMark: View {

    /// The mark's width; its height is half as much again, a plant being tall.
    var size: CGFloat = 40
    /// The stem's taper and the leaf's fill: the launch arguments, or the
    /// recommendation (`Fiddlehead.Style`).
    var style: Fiddlehead.Style = LoadingSwitch.drawing()

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var startedAt = Date()

    /// The frame it is drawn in: the same fixed-point drawing as the launch moment.
    /// It sits inside a screen, and Marcus asked for it that way on 10 October 2026,
    /// when the launch moment still had a second variant that entered from the
    /// screen's bottom edge, which a mark inside a screen could not do.
    static func frame(forSize size: CGFloat) -> CGSize {
        CGSize(width: size, height: size * 1.5)
    }

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            FiddleheadView(pose: pose(at: timeline.date), palette: palette, weight: 1.5, halo: 0, style: style)
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
