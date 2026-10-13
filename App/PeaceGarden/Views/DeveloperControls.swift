import Observation
import StoreKit
import SwiftUI
import SeedCore

/// The controls that only exist while this is being built, and in the copies
/// of it being tried out on a phone.
///
/// **Who gets them** (12 October 2026). Until build 7 the whole of this file
/// was inside `#if DEBUG`, which was the whole gate: an Xcode run was a Debug
/// build and had them, and anything that could reach the App Store did not.
/// Then Marcus moved to TestFlight, which installs Release builds, and the
/// imaginary meeting he grew plants with went with it. So the in-app controls
/// are compiled into every build now, and `isAvailable` decides at runtime
/// whether they are shown: always in a Debug build, and in a Release build
/// only when StoreKit says this copy was installed from TestFlight. An App
/// Store copy never shows them, and a check that fails says no.
///
/// **What stays Debug-only** is everything read off the command line —
/// `mintWords`, `stageOnLaunch`, `openOnLaunch`, `plotService`, the `-pg…`
/// screenshot flags — and `hidesShadows`, which only a test sets. A phone
/// installing from TestFlight has no way to pass a launch argument, and a
/// Release build has no business reading one.
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

    // MARK: Who gets these

    /// Whether this copy shows the developer controls at all.
    ///
    /// **Debug: always. Release: only a TestFlight copy**, as StoreKit reports
    /// it once at launch (`checkAvailability()`). False until StoreKit has
    /// answered, and false if it could not answer, so a copy from the App
    /// Store stays clean whatever goes wrong.
    ///
    /// Every control below reads as off where this is false — the clock as no
    /// shift, the switches as unset, the meeting as unasked — whatever an
    /// earlier TestFlight copy left in `UserDefaults`. A call site does not
    /// have to remember to ask.
    var isAvailable: Bool {
#if DEBUG
        !standsInForAppStore
#else
        fromTestFlight
#endif
    }

    static var isAvailable: Bool { shared.isAvailable }

    /// What StoreKit said at launch. Read only by a Release build.
    private var fromTestFlight = false
    @ObservationIgnored private var hasAsked = false

    /// Asks StoreKit where this copy came from, once a launch.
    ///
    /// **Kept for the launch and never written down.** A copy installed from
    /// TestFlight and then replaced by one from the App Store keeps its
    /// `UserDefaults`, so a remembered yes would be a yes in an App Store
    /// copy until it was asked again.
    ///
    /// A Debug build does not ask: it has the controls whatever StoreKit says.
    func checkAvailability() async {
#if !DEBUG
        guard !hasAsked else { return }
        hasAsked = true
        fromTestFlight = await Self.isTestFlight(Self.installedFrom)
#endif
    }

    /// The decision, with where the copy came from handed in, so a test can
    /// say *the App Store*, *TestFlight* or *it failed* without being any of
    /// them.
    ///
    /// **`.sandbox` and nothing else.** That is what StoreKit reports for a
    /// TestFlight install. `.production` is the App Store, and `.xcode` is
    /// StoreKit's local testing, which no copy on anybody's phone is.
    nonisolated static func isTestFlight(
        _ environment: @Sendable () async throws -> AppStore.Environment
    ) async -> Bool {
        do {
            return try await environment() == .sandbox
        } catch {
            return false
        }
    }

    /// Where StoreKit says this copy was installed from.
    ///
    /// The app transaction is the signed record of the install, kept on the
    /// device. An unverified one is a failure rather than an answer.
    nonisolated static func installedFrom() async throws -> AppStore.Environment {
        switch try await AppTransaction.shared {
        case .verified(let transaction): transaction.environment
        case .unverified: throw UnverifiedInstall()
        }
    }

    // MARK: The clock

    private static let shiftKey = "developer.clockShift"

    /// How far ahead of the wall clock the garden is being run, in seconds,
    /// and none at all where the controls are not available.
    var clockShift: TimeInterval { isAvailable ? keptShift : 0 }

    /// Kept in `UserDefaults` rather than in the garden. A garden holds seeds
    /// and birthdays and is the one thing here that has to mean the same in ten
    /// years; how fast somebody was flicking through it on a Tuesday is not
    /// part of that. It does survive a relaunch, which matters on a device
    /// where the app is being stopped and started all afternoon.
    private var keptShift: TimeInterval

    /// The app's idea of now, wherever the developer clock has been wound to.
    ///
    /// **In a Debug build this is every date**: what is shown and what is
    /// written down (`GardenModel.currentDate()`), so a plant met after the
    /// garden was wound on is born at the wound date and starts as a seedling.
    ///
    /// **In a Release build it is only what is shown** — `GardenModel.now`,
    /// which every plant is grown against, and the sky. A date written down
    /// there is the wall clock's, TestFlight included, so nothing kept and
    /// nothing sent to the plot service ever carries a wound date: the month a
    /// released plant can show beside it is the month the meeting really
    /// happened. The cost is that in a TestFlight copy a plant met while the
    /// garden is wound on arrives already that far grown, which for trying
    /// plants out is what was wanted anyway. Back to now puts it right.
    static var now: Date { Date().addingTimeInterval(shared.clockShift) }

    func advance(by interval: TimeInterval) {
        guard isAvailable else { return }
        keptShift += interval
        UserDefaults.standard.set(keptShift, forKey: Self.shiftKey)
    }

    func backToNow() {
        keptShift = 0
        UserDefaults.standard.set(0.0, forKey: Self.shiftKey)
    }

    // MARK: The imaginary meeting

    /// Set by the settings screen, read and cleared by `ExchangeView`.
    ///
    /// A flag rather than an argument because the two screens are three
    /// presentations apart, and threading a developer-only parameter through
    /// `PlantStageView` and a `fullScreenCover` would leave a mark on the
    /// shipping code.
    var wantsImaginaryMeeting: Bool {
        get { isAvailable && askedForImaginaryMeeting }
        set { askedForImaginaryMeeting = newValue }
    }

    private var askedForImaginaryMeeting = false

    private static let imaginaryKey = "developer.imaginarySeeds"

    /// Every plant an imaginary meeting has grown on this phone, by seed.
    ///
    /// **Written down, and read by nothing that sends.** Whether a plant
    /// nobody else grew may go to the live web garden is Marcus's to decide;
    /// until he has, it goes as any plant does. This is kept from the first
    /// imaginary meeting a TestFlight copy holds, so that whichever way it is
    /// decided can be applied to the plants made before the decision as well
    /// as after it. Beside the clock in `UserDefaults` rather than on the
    /// plant: it is a fact about how this phone was being tried out, not about
    /// what the plant is.
    func rememberImaginary(_ seed: SeedID) {
        var seeds = UserDefaults.standard.stringArray(forKey: Self.imaginaryKey) ?? []
        guard !seeds.contains(seed.hex) else { return }
        seeds.append(seed.hex)
        UserDefaults.standard.set(seeds, forKey: Self.imaginaryKey)
    }

    func grewImaginary(_ seed: SeedID) -> Bool {
        (UserDefaults.standard.stringArray(forKey: Self.imaginaryKey) ?? []).contains(seed.hex)
    }

    // MARK: The garden and the sky

    /// Shows the tile grid where the plot would be.
    ///
    /// The grid is the only thing there is to judge the plot against, and the
    /// judgement has to be made on somebody's own garden rather than on a
    /// screenshot of fourteen invented crossings. Kept in `UserDefaults` so the
    /// comparison survives the relaunch between one build and the next.
    var showsTileGrid: Bool {
        get { isAvailable && keptTileGrid }
        set { keptTileGrid = newValue }
    }

    private var keptTileGrid: Bool {
        didSet { UserDefaults.standard.set(keptTileGrid, forKey: Self.gridKey) }
    }

    private static let gridKey = "developer.showsTileGrid"

    /// Draws the day as it was before 2 October — one radial in a petrol
    /// blue — in place of the sky Marcus chose, to compare the two on a real
    /// garden.
    ///
    ///     xcrun simctl launch <device> app.peacegarden -pgOldSky YES
    ///
    /// Kept in `UserDefaults` for the same reason as the grid. In a Debug
    /// build a launch argument wins over what was kept, for screenshots.
    var showsTheOldDay: Bool {
        get { isAvailable && keptOldDay }
        set { keptOldDay = newValue }
    }

    private var keptOldDay: Bool {
        didSet { UserDefaults.standard.set(keptOldDay, forKey: Self.oldDayKey) }
    }

    private static let oldDayKey = "developer.showsTheOldDay"

    // MARK: Where they are

    /// Whether the Testing section is open at the foot of Settings.
    ///
    /// **A Debug build opens it, as it always has. A TestFlight copy keeps it
    /// folded** until the Settings heading is held for two seconds
    /// (`unfoldsDeveloperSection()`), so somebody trying the app who scrolls to
    /// the end of Settings does not walk into a panel of English for whoever
    /// is building it. Held again, it folds. Kept, so it is held once a phone.
    var showsSection: Bool {
        get { isAvailable && sectionOpen }
        set { sectionOpen = newValue }
    }

    private var sectionOpen: Bool {
        didSet { UserDefaults.standard.set(sectionOpen, forKey: Self.sectionKey) }
    }

    private static let sectionKey = "developer.showsSection"

#if DEBUG
    private static let sectionOpenAtFirst = true
#else
    private static let sectionOpenAtFirst = false
#endif

    // MARK: Debug only: tests and the command line

#if DEBUG
    /// For tests only: a Debug build answering as an App Store copy would, so
    /// what a copy without the controls does can be checked without building
    /// one.
    var standsInForAppStore = false

    /// Leaves the plot's shadows out, for one reason: so `PlotRenderTests` can
    /// time the same plot with and without them, a few frames of each in
    /// turn, in one run. Timing two builds one after the other on a shared
    /// machine measured the machine.
    var hidesShadows = false

    /// Read once, at launch, and cleared the first time it is acted on.
    /// Reopening the same screen every time the stage came back would make the
    /// panel impossible to close. See `Screen`.
    var openOnLaunch: Screen? = UserDefaults.standard.string(forKey: "pgOpen")
        .flatMap(Screen.init(rawValue:))

    /// A heading in Settings to scroll to as it opens, with `-pgOpen settings`:
    ///
    ///     xcrun simctl launch <device> app.peacegarden -pgOpen settings -pgSettingsAt location
    ///
    /// `display`, `location`, `joint` or `again`. The settings under the fold
    /// are otherwise out of reach of a script, for the reason `Screen` gives:
    /// an injected swipe is not something a screenshot run can count on.
    let settingsAt: String? = UserDefaults.standard.string(forKey: "pgSettingsAt")

    /// A plot of a fixed size, in metres, whatever the garden holds.
    ///
    ///     xcrun simctl launch <device> app.peacegarden -pgPlotSide 5.2
    ///
    /// For looking at a web garden's plot in the app's own renderer: a web plot
    /// is 5.2 m however many plants it has, and a garden's grows with them.
    /// `docs/WEB-GARDENS.md`.
    /// Draw a web garden area's structures on the plot, for looking at one:
    /// `-pgArea longWalk`, with `-pgPlotSide 5.2`.
    let previewArea: String? = UserDefaults.standard.string(forKey: "pgArea")

    /// Point the asking at a plot service of one's own:
    /// `-pgPlots http://localhost:8807`.
    ///
    /// **Debug only, and `PlotService.origin` is a constant for the same
    /// reason.** An address the app would take from anywhere is a way to send
    /// somebody's meetings somewhere else; this exists so the whole flow can be
    /// watched against a local `php -S` before it is watched against the live
    /// one. `Server/README.md` has the command.
    let plotService: URL? = UserDefaults.standard.string(forKey: "pgPlots")
        .flatMap(URL.init(string:))

    let fixedPlotSide: Double? = {
        let side = UserDefaults.standard.double(forKey: "pgPlotSide")
        return side > 0 ? side : nil
    }()

    /// A stage of the own plant's life, wound to at launch:
    ///
    ///     xcrun simctl launch <device> app.peacegarden -pgStage blooming
    ///
    /// Any of `GrowthModel.Stage`'s names. The buttons in Settings step the
    /// clock by fixed amounts, but a plant's stages are its own length, so the
    /// right number of *+1w* presses to reach a bloom differs for every seed —
    /// and a spire's flowers on their stalks were built without anybody having
    /// seen them in the app. This lands on the stage whatever the tempo.
    let stageOnLaunch: GrowthModel.Stage? = UserDefaults.standard.string(forKey: "pgStage")
        .flatMap(GrowthModel.Stage.init(rawValue:))

    /// Words to mint the own seed from, instead of this device's entropy:
    ///
    ///     xcrun simctl launch <device> app.peacegarden -pgMint pedicel-9 -pgStage blooming
    ///
    /// **Read only when a seed is minted**, which is once, at first light on a
    /// fresh install. A garden that already has a seed keeps it: the argument
    /// never replaces one. So a particular plant — a spire, a vine — is looked
    /// at on a simulator of its own, and nobody's plant is swapped out from
    /// under them by a launch argument left in a scheme.
    let mintWords: String? = UserDefaults.standard.string(forKey: "pgMint")
        .flatMap { $0.isEmpty ? nil : $0 }
#endif

    private init() {
        keptShift = UserDefaults.standard.double(forKey: Self.shiftKey)
        keptTileGrid = UserDefaults.standard.bool(forKey: Self.gridKey)
        let keptDay = UserDefaults.standard.bool(forKey: Self.oldDayKey)
#if DEBUG
        keptOldDay = UserDefaults.standard.object(forKey: "pgOldSky") != nil
            ? UserDefaults.standard.bool(forKey: "pgOldSky")
            : keptDay
#else
        keptOldDay = keptDay
#endif
        sectionOpen = UserDefaults.standard.object(forKey: Self.sectionKey) as? Bool
            ?? Self.sectionOpenAtFirst
    }
}

/// An app transaction StoreKit could not verify, which is no answer at all.
private struct UnverifiedInstall: Error {}

#if DEBUG
extension Developer {
    /// One of the four screens behind a mark, opened as the stage appears.
    ///
    ///     xcrun simctl launch <device> app.peacegarden -pgOpen settings
    ///
    /// **The marks at the foot of the stage answer a tap gesture rather than a
    /// button, and an injected tap does not reach a gesture recogniser** — the
    /// same reason the whole row is drawn from the start on a simulator instead
    /// of waiting to be revealed. So the seed, the garden and the settings are
    /// behind a control that nothing but a thumb can press, which is fine until
    /// somebody has to take the same four screenshots in eight languages. That
    /// is what a language costs each time one is added, and this is how it is
    /// paid.
    ///
    /// A launch argument rather than a control, because it has to happen before
    /// anything is on screen. `UserDefaults` parses `-key value` off the command
    /// line for free, which is the same mechanism `-AppleLanguages` uses.
    enum Screen: String {
        case seed, meet, garden, settings
    }

    /// Shifts the clock so a plant born at `birth` is halfway through `stage`,
    /// on the hour it opens widest when that hour falls inside the stage.
    ///
    /// Halfway because the edges of a stage look like the stages either side
    /// of it. The hour matters because a bloom closes to a third overnight, and
    /// a flower half shut is not the one being looked for. `mature` never ends,
    /// so it is taken a fortnight in, into the first flush.
    ///
    /// The shift can come out negative, for a plant already past the stage.
    /// That winds the garden back, which is as honest as winding it on: nothing
    /// stored is touched, and Back to now undoes it.
    ///
    /// Debug only: `-pgStage` is the one caller.
    func wind(to stage: GrowthModel.Stage, genome: Genome, birth: Date) {
        let growth = GrowthModel(genome: genome)
        let start = growth.start(of: stage)
        let end = growth.end(of: stage)
        let middle = end.map { (start + $0) / 2 } ?? start + 14 * 86_400
        var target = birth.addingTimeInterval(middle)

        let hour = genome.tempo.opensByDay ? 13 : 1
        if let pinned = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: target) {
            let age = pinned.timeIntervalSince(birth)
            if age > start, age < (end ?? .infinity) { target = pinned }
        }

        keptShift = target.timeIntervalSince(Date())
        UserDefaults.standard.set(keptShift, forKey: Self.shiftKey)
    }
}
#endif

// MARK: - The way in

extension View {
    /// The way to the Testing section in a TestFlight copy: a two-second hold
    /// on whatever this is attached to, which is the Settings heading. No word
    /// and no mark, so nothing for a tester to find and nothing to translate.
    ///
    /// Nothing at all in a copy without the controls.
    func unfoldsDeveloperSection() -> some View {
        modifier(DeveloperHold())
    }
}

private struct DeveloperHold: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        let developer = Developer.shared
        if developer.isAvailable {
            content
                .onLongPressGesture(minimumDuration: 2) {
                    withAnimation(.easeInOut(duration: 0.3)) { developer.showsSection.toggle() }
                }
                // Felt rather than seen: the section opens at the foot of a
                // screen that may be scrolled to the top.
                .sensoryFeedback(.selection, trigger: developer.showsSection)
        } else {
            content
        }
    }
}

// MARK: - The section at the foot of Settings

/// Plain buttons, and deliberately not in the app's voice.
///
/// The rest of Settings is written for somebody who has never seen it before;
/// this is written for whoever is building it. Keeping the register obviously
/// different is the cheapest guard against a developer row being mistaken for a
/// real one in a screenshot.
///
/// **Every word here is verbatim, so none of it is extracted.** Not because
/// developers read English, but because nobody but a developer, or Marcus
/// trying a TestFlight copy, is ever shown it: forty-odd translations of *Wind
/// the garden on* would be read by nobody. When this file was inside `#if
/// DEBUG` there was a second reason — a catalogue synced from a Release build
/// would have marked the literals stale — and verbatim kept the builds agreeing
/// then too.
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
            Text(verbatim: "Testing")
                .chromeLabel()
                .foregroundStyle(Chrome.sectionLabel)

            clock
            meeting
            garden
            sky
        }
    }

    // MARK: The clock

    private var clock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(verbatim: "Wind the garden on")
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
                Text(verbatim: standing)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Chrome.muted)

                if developer.clockShift != 0 {
                    Button {
                        developer.backToNow()
                        model.refreshNow()
                    } label: {
                        Text(verbatim: "Back to now")
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
        guard developer.clockShift != 0 else { return "Real time · \(stage)" }
        let direction = developer.clockShift > 0 ? "ahead" : "behind"
        return "\(shiftDescription) \(direction) · \(stage)"
    }

    /// `-pgStage` can wind the clock back as well as on.
    private var shiftDescription: String {
        let shift = abs(developer.clockShift)
        if shift < Self.day {
            return "\(Int((shift / Self.hour).rounded()))h"
        }
        let days = Int((shift / Self.day).rounded())
        return days < 14 ? "\(days)d" : "\(days / 7)w"
    }

    // MARK: The garden

    private var garden: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                developer.showsTileGrid.toggle()
            } label: {
                Text(verbatim: developer.showsTileGrid ? "Garden: tile grid" : "Garden: plot")
            }
            .buttonStyle(.plain)
            .font(.system(size: 15, weight: .light))
            .foregroundStyle(Chrome.ink)
            .pressable(isProminent: true)

            Text(verbatim: "Which screen the garden mark opens. The grid is what the plot replaced; it is kept here so the two can be compared on a real garden.")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Chrome.muted)
                .lineSpacing(4)
        }
    }

    // MARK: The sky

    private var sky: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                developer.showsTheOldDay.toggle()
            } label: {
                Text(verbatim: developer.showsTheOldDay ? "Sky: the old day" : "Sky: as chosen")
            }
            .buttonStyle(.plain)
            .font(.system(size: 15, weight: .light))
            .foregroundStyle(Chrome.ink)
            .pressable(isProminent: true)

            Text(verbatim: "The day sky Marcus chose on 2 October, or the petrol one it replaced, to compare the two. The night is the same in both.")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Chrome.muted)
                .lineSpacing(4)
        }
    }

    // MARK: The meeting

    private var meeting: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                developer.wantsImaginaryMeeting = true
                close()
            } label: {
                Text(verbatim: "Meet an imaginary gardener")
            }
            .buttonStyle(.plain)
            .font(.system(size: 15, weight: .light))
            .foregroundStyle(Chrome.ink)
            .pressable(isProminent: true)

            Text(verbatim: "Opens Meet against a seed created on the spot. Knock the phone as usual — everything from there is the real crossing.")
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
