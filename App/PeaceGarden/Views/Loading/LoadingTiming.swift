import Foundation

/// **Which loading animation the app wears, and the one switch that decides.**
///
/// Two were drawn on 10 October 2026 for Marcus to choose between, and both are
/// wired so that a build of this branch shows either one:
///
/// - `unwinding` — the app's own mark on the suite's ground: the coil lets go
///   and the bract opens, then one band of light crosses it (the Interfulgent
///   pattern, in this app's drawing).
/// - `frond` — the garden's own fiddlehead, the one that already opens behind
///   the seed-making screens, drawn in the app's quiet chrome on the app's own
///   ground.
/// - `off` — nothing is drawn and nothing waits: exactly the app as it was.
///
/// **A launch argument rather than a setting.** Settings rows need words, and
/// every word is forty-two translations for a choice that exists so that one
/// person can look at two pictures. From Xcode: *Edit Scheme › Arguments*, or
/// `xcrun simctl launch <device> app.peacegarden -loading.style.v1 frond`
/// (UserDefaults reads launch arguments of this shape as its own).
enum LoadingStyle: String, CaseIterable, Sendable {
    case off
    case unwinding
    case frond
}

enum LoadingSwitch {
    /// Versioned like every other key in `Chrome`, so a later meaning can leave
    /// this one behind.
    static let key = "loading.style.v1"

    /// The recommended variant when nothing has been said, so that a build of
    /// this branch shows it. Retiring it altogether is `-loading.style.v1 off`.
    static let fallback = LoadingStyle.unwinding

    static func style(in defaults: UserDefaults = .standard) -> LoadingStyle {
        defaults.string(forKey: key).flatMap(LoadingStyle.init(rawValue:)) ?? fallback
    }
}

/// **When things happen, and every figure is a figure this app, or the suite it
/// belongs to, already uses.** Nothing here is a new number.
///
/// The Interfulgent apps agree on a shape rather than on a duration — UnCubed
/// plays 0.6 s, Pfish 0.6 s, FlagFans 2.0 s — so the length is each app's own
/// and this one takes it from its own motion table. The hand-over and the
/// threshold are the suite's, because those *are* shared.
enum LoadingTiming {

    /// **1.2 s, the app's own length for one arrival** — `design/Motion.dc.html`,
    /// *"A line, a heading or a control arriving. Ease in and out."* UnCubed
    /// took its 0.6 s from its `m-turn`, Pfish from its lightning flash, and
    /// this is the same move: the nearest thing the app already does to "one
    /// thing opens, once".
    ///
    /// It is a floor and never a wait. The launch moment is a function of the
    /// clock alone, so it is not the app reporting how long loading takes; it
    /// covers the first frame of the stage being built underneath and then
    /// goes, whatever that took.
    static let moment: TimeInterval = 1.2

    /// **The mark leaves first, over 120 ms, and the ground over 180 ms**, both
    /// started together. UnCubed's `markFade`/`dissolve` and FlagFans's
    /// `MARK_FADE_MS`/`GROUND_FADE_MS`: the same two figures in two apps, which
    /// is as close to a suite rule as this pattern has. The order is what stops
    /// the mark floating, half transparent, over the screen it is handing over
    /// to.
    static let markFade: TimeInterval = 0.12
    static let dissolve: TimeInterval = 0.18

    /// **A wait shows nothing for its first 400 ms.** UnCubed's
    /// `Layout.slowWorkThreshold`, from its design system's *"nothing for the
    /// first 400ms"*: a request that answers at once should not flash a mark
    /// for the length of the answer.
    static let busyThreshold: TimeInterval = 0.4

    /// How long the mark takes to come in once the threshold has passed. The
    /// ground is already there, so this is a fade and not an arrival; 180 ms is
    /// `dissolve` again.
    static let busyFade: TimeInterval = 0.18

    /// **One breath of the waiting mark: 2.4 s, two arrivals** — it opens over
    /// 1.2 s and furls over 1.2 s. The app's own breathing dot is 1.7 s, and a
    /// coil is a larger thing to move than a dot; slower than the dot is also
    /// slower than a heartbeat, which keeps it clear of looking hurried.
    static let breath: TimeInterval = 2.4

    // MARK: - The moment's clock

    /// 0…1 across the moment. Clamped, and a function of elapsed time alone —
    /// UnCubed's rule for why a splash cannot report anything: there is nothing
    /// for the work behind it to retarget.
    static func progress(elapsed: TimeInterval) -> Double {
        min(max(elapsed / moment, 0), 1)
    }

    /// The app's own ease, `GerminationView.ramp`: smoothstep. In and out, no
    /// overshoot — a coil that bounces would be a spring, and nothing here is.
    static func smooth(_ x: Double) -> Double {
        let c = min(max(x, 0), 1)
        return c * c * (3 - 2 * c)
    }

    /// A beat inside the moment: 0 before it, 1 after it, eased between.
    static func beat(_ t: Double, _ range: ClosedRange<Double>) -> Double {
        let width = range.upperBound - range.lowerBound
        guard width > 0 else { return t >= range.upperBound ? 1 : 0 }
        return smooth((t - range.lowerBound) / width)
    }

    /// The same beat, unshaped, for anything that moves at one speed.
    static func span(_ t: Double, _ range: ClosedRange<Double>) -> Double {
        let width = range.upperBound - range.lowerBound
        guard width > 0 else { return t >= range.upperBound ? 1 : 0 }
        return min(max((t - range.lowerBound) / width, 0), 1)
    }

    // MARK: - The waiting mark's clock

    /// 0…1, repeating, from elapsed seconds. 0 is furled and 0.5 is as open as
    /// the breath gets, so the loop joins itself at the furled end where
    /// nothing is moving fast.
    static func breathPhase(elapsed: TimeInterval) -> Double {
        let turn = (elapsed / breath).truncatingRemainder(dividingBy: 1)
        return turn < 0 ? turn + 1 : turn
    }

    /// How open the waiting mark is at a phase of the breath, 0…1. A cosine, so
    /// it rests at both ends of its travel — the same shape `Frond.unfurl(at:)`
    /// already gives the backdrop.
    static func openness(atBreath phase: Double) -> Double {
        0.5 - 0.5 * cos(2 * .pi * phase)
    }

    /// **Where the waiting mark rests when motion is off** — a composed state
    /// and not a frozen mid-stride, `design/Motion.dc.html`'s own rule for Reduce
    /// Motion (*"a tendril rests half open"*). Mostly open, because that is the
    /// shape the mark is.
    static let stillOpenness = 0.8
}
