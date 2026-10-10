import SwiftUI

/// **The waiting mark: the same drawing as the launch moment, small, repeating,
/// for a wait the person started.**
///
/// UnCubed is the one suite app with a counterpart (`BusyMark`, `CheckingRing`),
/// and what it settled is what this takes: show nothing for the first 400 ms; draw
/// a mark in the app's own idiom that is *built and rebuilt* rather than a
/// spinner; keep it small and in ink; and under Reduce Motion keep the statement
/// and lose the movement — the same drawing, held still.
///
/// **In ink, not in the arc's colours, in both variants.** UnCubed's brand rule
/// is that the arc's values are on the mark's own stroke and nowhere else, and
/// this app's chrome is white at four opacities with colour reserved for the
/// plants. The brand dress belongs to the moment, which is on the suite's own
/// ground. On the app's ground, in either appearance, the mark is one colour.
struct LoadingBusyMark: View {

    let style: LoadingStyle
    var size: CGFloat = 40

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startedAt = Date()

    var body: some View {
        switch style {
        case .off:
            EmptyView()
        case .unwinding:
            TimelineView(.animation(paused: reduceMotion)) { timeline in
                UnwindingMarkView(pose: pose(UnwindingMark.pose(atBreath:), still: UnwindingMark.still, at: timeline.date),
                                  dress: .ink(Chrome.ink))
                    .frame(width: size, height: size)
            }
        case .frond:
            TimelineView(.animation(paused: reduceMotion)) { timeline in
                FiddleheadView(pose: pose(Fiddlehead.pose(atBreath:), still: Fiddlehead.still, at: timeline.date),
                               ink: Chrome.ink.opacity(0.85), weight: 1.5, halo: 0)
                    .frame(width: size * 0.8, height: size)
            }
        }
    }

    /// Which pose to draw: the breath at this instant, or the still one.
    private func pose<P>(_ breathing: (Double) -> P, still: P, at date: Date) -> P {
        guard !reduceMotion else { return still }
        return breathing(LoadingTiming.breathPhase(elapsed: date.timeIntervalSince(startedAt)))
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
    let style: LoadingStyle
    @State private var showing = false

    func body(content: Content) -> some View {
        content
            .overlay {
                if showing {
                    LoadingBusyMark(style: style)
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
        modifier(BusyMarkModifier(isBusy: isBusy && style != .off, style: style))
    }
}
