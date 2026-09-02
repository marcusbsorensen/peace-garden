#if DEBUG
import Observation
import SwiftUI
import SeedCore

/// The controls that only exist while this is being built.
///
/// Everything in this file is inside `#if DEBUG`, so a Release build has no
/// developer clock, no imaginary gardener and no section at the foot of
/// Settings. That is the whole gate: an Xcode run on a device is a Debug build
/// and gets them, and anything that could reach the App Store does not.
///
/// Two things are hard to see otherwise, and both of them are the app's
/// central promises rather than side features:
///
/// - **A plant grows in real days.** That is deliberate — it is something to
///   come back to rather than to scrub through — but it means the difference
///   between a seedling and a bloom is a fortnight of waiting.
/// - **A meeting needs two phones.** Everything after the knock is derived,
///   agreed and shown without a server, and none of it can be looked at alone.
///
/// The answers here are the smallest ones that stay honest. The clock is
/// shifted rather than the birthdays rewritten, so nothing in the garden is
/// altered by looking at it; and the imaginary meeting runs the real crossing
/// against a real seed, so what it grows is a plant that could have been.
@Observable
@MainActor
final class Developer {
    static let shared = Developer()

    private static let shiftKey = "developer.clockShift"

    /// How far ahead of the wall clock the garden is being run, in seconds.
    ///
    /// Kept in `UserDefaults` rather than in the garden. A garden holds seeds
    /// and birthdays and is the one thing here that has to mean the same in ten
    /// years; how fast somebody was flicking through it on a Tuesday is not
    /// part of that. It does survive a relaunch, which matters on a device
    /// where the app is being stopped and started all afternoon.
    private(set) var clockShift: TimeInterval

    /// Set by the settings screen, read and cleared by `ExchangeView`.
    ///
    /// A flag rather than an argument because the two screens are three
    /// presentations apart, and threading a debug-only parameter through
    /// `PlantStageView` and a `fullScreenCover` would leave a mark on the
    /// shipping code that the `#if` could not take back out.
    var wantsImaginaryMeeting = false

    private init() {
        clockShift = UserDefaults.standard.double(forKey: Self.shiftKey)
    }

    /// The app's idea of now, wherever the developer clock has been wound to.
    static var now: Date { Date().addingTimeInterval(shared.clockShift) }

    func advance(by interval: TimeInterval) {
        clockShift += interval
        UserDefaults.standard.set(clockShift, forKey: Self.shiftKey)
    }

    func backToNow() {
        clockShift = 0
        UserDefaults.standard.set(0.0, forKey: Self.shiftKey)
    }
}

// MARK: - The section at the foot of Settings

/// Plain buttons, and deliberately not in the app's voice.
///
/// The rest of Settings is written for somebody who has never seen it before;
/// this is written for whoever is building it. Keeping the register obviously
/// different is the cheapest guard against a developer row being mistaken for a
/// real one in a screenshot.
struct DeveloperSection: View {
    @Environment(GardenModel.self) private var model
    /// Closing is the caller's, the same way it is for every other row here.
    let close: () -> Void

    private var developer: Developer { Developer.shared }

    private static let hour: TimeInterval = 3600
    private static let day: TimeInterval = 86_400

    private static let steps: [(title: String, interval: TimeInterval)] = [
        ("+6h", 6 * hour),
        ("+1d", day),
        ("+1w", 7 * day),
        ("+1m", 30 * day)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Testing")
                .chromeLabel()
                .foregroundStyle(Chrome.sectionLabel)

            clock
            meeting
        }
    }

    // MARK: The clock

    private var clock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Wind the garden on")
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(Chrome.ink)

            // Wrapping rather than one row: four steps and a Back to now do not
            // fit across a phone, and a horizontal scroll view would hide the
            // one control that undoes the others.
            HStack(spacing: 8) {
                ForEach(Self.steps, id: \.title) { step in
                    Button(step.title) {
                        developer.advance(by: step.interval)
                        model.refreshNow()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Chrome.ink)
                    .pressable(horizontal: 12)
                }
            }

            HStack(spacing: 12) {
                Text(standing)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Chrome.muted)

                if developer.clockShift > 0 {
                    Button("Back to now") {
                        developer.backToNow()
                        model.refreshNow()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Chrome.pinkGold)
                }
            }
        }
    }

    /// Where the clock stands, and what the plant is doing there — the stage is
    /// the thing actually being checked, and reading it off the screen behind
    /// this panel means closing the panel.
    private var standing: String {
        let stage = model.ownPlantGrowth()?.stage.displayName ?? "no plant"
        guard developer.clockShift > 0 else { return "Real time · \(stage)" }
        return "\(shiftDescription) ahead · \(stage)"
    }

    private var shiftDescription: String {
        let shift = developer.clockShift
        if shift < Self.day {
            return "\(Int((shift / Self.hour).rounded()))h"
        }
        let days = Int((shift / Self.day).rounded())
        return days < 14 ? "\(days)d" : "\(days / 7)w"
    }

    // MARK: The meeting

    private var meeting: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button("Meet an imaginary gardener") {
                developer.wantsImaginaryMeeting = true
                close()
            }
            .buttonStyle(.plain)
            .font(.system(size: 15, weight: .light))
            .foregroundStyle(Chrome.ink)
            .pressable(isProminent: true)

            Text("Opens Meet against a seed created on the spot. Knock the phone as usual — everything from there is the real crossing.")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Chrome.muted)
                .lineSpacing(4)
        }
    }
}

// MARK: - The imaginary gardener

extension PollenExchangeService {
    /// Names for somebody who is not there.
    ///
    /// Ordinary first names rather than jokes or placeholders. A meeting screen
    /// saying *Test User* tells you the plumbing works; one saying *Nadia*
    /// tells you whether the screen reads as a meeting, which is the only
    /// question worth asking a second phone.
    static let imaginaryNames = [
        "Nadia", "Tomas", "Ines", "Rafi", "Hilde",
        "Owen", "Marta", "Kwame", "Suki", "Bram"
    ]

    /// A birthday for a stranger's plant: somewhere in the last three months,
    /// so the plant they are carrying is grown rather than newly sown.
    ///
    /// It is only ever displayed. The child seed is derived from the two seeds
    /// and the two nonces, and no birthday goes into it.
    static func imaginaryBirth() -> Date {
        Developer.now.addingTimeInterval(-Double.random(in: (14 * 86_400)...(90 * 86_400)))
    }
}
#endif
