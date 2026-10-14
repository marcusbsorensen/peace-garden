import Observation
import SeedCore
import SwiftUI
import UIKit

/// What the Share mark offers.
///
/// **A menu, because it is a handful of things and the system already has the
/// shape for them.** It opens from the mark, says each in a word or three
/// beside a glyph, reads itself to VoiceOver and goes away on its own. A sheet
/// of our own would have been a second screen for a choice that takes one tap.
///
/// The order is the order of the menu: the three that go to the share sheet,
/// then the two that go to Photos.
enum PlantShareAction: String, CaseIterable, Identifiable, Sendable {
    /// A still, handed to the share sheet: Photos, Mail, Messages, anything.
    case picture
    /// Once round, slowly, as a video, handed to the share sheet.
    case turning
    /// The plant's life from its first sprouting to now, the time-lapse its
    /// screen plays, as a film handed to the share sheet (Marcus, 13 October:
    /// 1A; built 14 October).
    case timeLapse
    /// A still the size of this phone's screen, saved to Photos.
    case wallpaper
    /// A Live Photo of a short turn, saved to Photos.
    case movingWallpaper

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .picture: "Share picture"
        case .turning: "Share turning video"
        case .timeLapse: "Share time-lapse"
        case .wallpaper: "Save as wallpaper"
        case .movingWallpaper: "Save as moving wallpaper"
        }
    }

    /// The system's own marks for each, which every iPhone owner has seen on
    /// the same things elsewhere.
    var glyph: String {
        switch self {
        case .picture: "photo"
        case .turning: "rotate.3d"
        case .timeLapse: "timelapse"
        case .wallpaper: "iphone"
        case .movingWallpaper: "livephoto"
        }
    }

    /// Whether this one ends in Photos rather than in the share sheet.
    var savesToPhotos: Bool {
        self == .wallpaper || self == .movingWallpaper
    }
}

/// The line that follows a save, or a share that could not be made.
enum PlantShareHint: Equatable {
    case saved
    case notAllowed
    case failed
}

/// The Share mark: the system's share glyph in the chrome's ring, top right on
/// a plant's screen, beside Close, and top right on the stage, for the
/// person's own plant (Marcus, 14 October 2026: 13A).
///
/// **Glyph, not word**, as Close is: the box with the arrow out of it is the
/// one mark for this on every iPhone, and VoiceOver reads it as *Share*.
///
/// While something is being drawn the glyph steps back and a hairline runs
/// round the ring as the frames are made — the same hairline the ring is drawn
/// in, so the waiting is the control filling rather than a spinner beside it.
/// It is information rather than motion (how much longer), so Reduce Motion
/// keeps it, and it is not animated between steps.
struct PlantShareButton: View {
    /// The plant: its genome for a picture or a turn, and its birthday for the
    /// time-lapse, which replays its life from the first sprouting.
    let record: PlantRecord
    let growth: GrowthModel.State
    /// The moment it is: the hour on this phone's clock is the sky the plant
    /// is shared under (`ShareSky`).
    let now: Date
    /// How far in from the trailing edge the mark stands, for the share
    /// sheet's popover to point at on an iPad.
    var trailingInset: CGFloat = PlantShareButton.besideClose
    /// Told when the mark starts and stops being busy — making something, or
    /// showing the line after it — so a screen whose chrome comes and goes can
    /// keep it up until it is done.
    var onBusy: (Bool) -> Void = { _ in }

    /// How far in from the trailing edge, to stand beside Close: Close's own
    /// inset, its width, and a gap.
    static let besideClose: CGFloat = 12 + 42 + 8

    @State private var work = PlantShareWork()

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            Menu {
                ForEach(PlantShareAction.allCases) { action in
                    Button {
                        work.start(action, record: record, growth: growth, now: now,
                                   trailingInset: trailingInset)
                    } label: {
                        Label(action.title, systemImage: action.glyph)
                    }
                }
            } label: {
                mark
            }
            .menuOrder(.fixed)
            .menuStyle(.button)
            .buttonStyle(.plain)
            .disabled(work.doing != nil)
            .accessibilityLabel(Text("Share"))
            .accessibilityValue(work.doing == nil ? Text(verbatim: "")
                                : Text(work.progress, format: .percent.precision(.fractionLength(0))))

            if let hint = work.hint {
                hintLine(hint)
                    .transition(.opacity)
            }
        }
        // A crossfade under Reduce Motion too: nothing moves, and the line
        // still has to arrive (the house rule, `PlantStageView`'s Settings).
        .animation(Chrome.fadeIn, value: work.hint)
        .onChange(of: work.isBusy) { _, busy in onBusy(busy) }
    }

    private var mark: some View {
        Image(systemName: "square.and.arrow.up")
            .font(.system(size: 14, weight: .light))
            .foregroundStyle(Chrome.ink.opacity(work.doing == nil ? 0.75 : 0.3))
            // The arrow stands above the box, so the glyph's own middle is
            // high; a point down sits it in the ring as the X sits in Close's.
            .offset(y: -1)
            .frame(width: 18, height: 18)
            .pressable(horizontal: 12, vertical: 12)
            .overlay {
                if work.doing != nil {
                    Circle()
                        .trim(from: 0, to: max(0.02, work.progress))
                        .stroke(Chrome.ink.opacity(0.7), style: Chrome.monoline)
                        .rotationEffect(.degrees(-90))
                        .padding(0.5)
                }
            }
            .contentShape(Circle())
    }

    private func hintLine(_ hint: PlantShareHint) -> some View {
        Group {
            switch hint {
            case .saved:
                // The glyph is the one just pressed, so the hint points at a
                // thing the reader has already found.
                Text("Saved to Photos. Open it there, tap \(Image(systemName: "square.and.arrow.up")), then Use as Wallpaper.")
            case .notAllowed:
                Text("Allow Peace Garden to add to Photos in Settings.")
            case .failed:
                Text("Try again")
            }
        }
        .scaledFont(size: 13, weight: .light)
        .foregroundStyle(Chrome.ink)
        .multilineTextAlignment(.center)
        .lineSpacing(3)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: 260)
        // One panel, the ground's own colour, so the line reads over a plant
        // without the screen growing a frame round everything.
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Chrome.ground.opacity(0.82))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Chrome.hairline, lineWidth: 1))
        )
        .onTapGesture { work.hint = nil }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spoken(hint))
        .accessibilityAddTraits(.isStaticText)
    }

    /// The line as VoiceOver reads it: the glyph drawn in it has no words of
    /// its own, so it is read as the word the mark itself is read as. The same
    /// key as the written line, with *Share* where the glyph is.
    private func spoken(_ hint: PlantShareHint) -> Text {
        switch hint {
        case .saved:
            Text("Saved to Photos. Open it there, tap \(Text("Share")), then Use as Wallpaper.")
        case .notAllowed:
            Text("Allow Peace Garden to add to Photos in Settings.")
        case .failed:
            Text("Try again")
        }
    }
}

/// The work behind the mark: drawing, writing, and handing it on.
///
/// The drawing is done off the main thread (`PlantShareFiles`), and only the
/// ground — a few thousand stars from a catalogue the main actor keeps — is
/// painted here first.
@Observable
@MainActor
final class PlantShareWork {
    /// What is being made, while it is.
    var doing: PlantShareAction?
    /// How far the frames have got, `0...1`.
    var progress: Double = 0
    var hint: PlantShareHint? {
        didSet { scheduleHintAway() }
    }
    /// Making something, or saying what came of it.
    var isBusy: Bool { doing != nil || hint != nil }
    /// Where the mark stands in from the trailing edge, for the popover.
    @ObservationIgnored private var trailingInset = PlantShareButton.besideClose

    @ObservationIgnored private var hintTask: Task<Void, Never>?

    func start(_ action: PlantShareAction, record: PlantRecord, growth: GrowthModel.State, now: Date,
               trailingInset: CGFloat = PlantShareButton.besideClose) {
        guard doing == nil else { return }
        self.trailingInset = trailingInset
        doing = action
        progress = 0
        hint = nil

        // The film draws its own frames, sky and all, on the main actor as the
        // screen's time-lapse does, a frame at a time with a breath between,
        // and reports each one to the ring as the turning video does.
        if action == .timeLapse {
            Task {
                do {
                    let url = try await PlantShareFiles.timeLapse(record, now: now) { value in
                        self.progress = value
                    }
                    present(url)
                } catch {
                    finish(.failed)
                }
            }
            return
        }

        let genome = record.genome

        // The sky of the hour on this phone's clock, and the night if it
        // cannot be had (Marcus, 14 October 2026).
        let hour = ShareSky.phoneHour(at: now)
        let portrait: PlantPortrait
        switch action {
        case .picture:
            portrait = .picture(genome: genome, growth: growth, hour: hour)
        case .turning:
            portrait = .turning(genome: genome, growth: growth, hour: hour)
        case .wallpaper, .movingWallpaper:
            let screen = Self.screen()
            portrait = .wallpaper(genome: genome, growth: growth,
                                  nativePixels: screen.pixels, scale: screen.scale, hour: hour)
        case .timeLapse:
            return
        }
        guard let ground = ShareBackdrop.image(for: portrait) else {
            finish(.failed)
            return
        }
        let backdrop = SharedImage(image: ground)
        let report: @Sendable (Double) -> Void = { [weak self] value in
            Task { @MainActor in self?.progress = value }
        }

        Task {
            do {
                switch action {
                case .picture:
                    let url = try await Task.detached(priority: .userInitiated) {
                        try PlantShareFiles.picture(portrait, backdrop: backdrop)
                    }.value
                    progress = 1
                    present(url)
                case .turning:
                    let url = try await Task.detached(priority: .userInitiated) {
                        try await PlantShareFiles.turning(portrait, backdrop: backdrop, progress: report)
                    }.value
                    present(url)
                case .wallpaper:
                    let url = try await Task.detached(priority: .userInitiated) {
                        try PlantShareFiles.wallpaper(portrait, backdrop: backdrop)
                    }.value
                    progress = 1
                    finish(Self.hint(for: await PhotosSaving.save(still: url)))
                case .movingWallpaper:
                    let pair = try await Task.detached(priority: .userInitiated) {
                        try await PlantShareFiles.movingWallpaper(portrait, backdrop: backdrop, progress: report)
                    }.value
                    finish(Self.hint(for: await PhotosSaving.save(pair)))
                case .timeLapse:
                    break
                }
            } catch {
                finish(.failed)
            }
        }
    }

    private static func hint(for outcome: PhotosSaving.Outcome) -> PlantShareHint {
        switch outcome {
        case .saved: .saved
        case .notAllowed: .notAllowed
        case .failed: .failed
        }
    }

    private func finish(_ hint: PlantShareHint?) {
        doing = nil
        progress = 0
        self.hint = hint
        if let hint {
            AccessibilityNotification.Announcement(Self.spoken(hint)).post()
        }
    }

    /// The hint as VoiceOver says it: the glyph in the written line is said as
    /// the word the button is read as.
    private static func spoken(_ hint: PlantShareHint) -> String {
        switch hint {
        case .saved:
            String(localized: "Saved to Photos. Open it there, tap \(String(localized: "Share")), then Use as Wallpaper.")
        case .notAllowed:
            String(localized: "Allow Peace Garden to add to Photos in Settings.")
        case .failed:
            String(localized: "Try again")
        }
    }

    /// Long enough to read twice, then gone. A tap takes it sooner.
    private func scheduleHintAway() {
        hintTask?.cancel()
        guard hint != nil else { return }
        hintTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(8))
            guard !Task.isCancelled else { return }
            self?.hint = nil
        }
    }

    /// Hands a file to the share sheet, and empties the folder once it is done.
    private func present(_ url: URL) {
        doing = nil
        progress = 0
        guard let top = Self.topController() else {
            finish(.failed)
            return
        }
        let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        sheet.completionWithItemsHandler = { _, _, _, _ in
            try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
        }
        if let popover = sheet.popoverPresentationController {
            // On an iPad the sheet is a popover, and it points at the mark.
            popover.sourceView = top.view
            popover.sourceRect = CGRect(x: top.view.bounds.maxX - trailingInset - 21,
                                        y: top.view.safeAreaInsets.top + 12 + 42, width: 1, height: 1)
            popover.permittedArrowDirections = .up
        }
        top.present(sheet, animated: true)
    }

    private static func topController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        guard var top = scene?.keyWindow?.rootViewController ?? scene?.windows.first?.rootViewController
        else { return nil }
        while let presented = top.presentedViewController, !presented.isBeingDismissed {
            top = presented
        }
        return top
    }

    /// This phone's screen in its real pixels, and how many of them a point is.
    private static func screen() -> (pixels: CGSize, scale: CGFloat) {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let screen = (scenes.first { $0.activationState == .foregroundActive } ?? scenes.first)?.screen
        guard let screen else { return (CGSize(width: 1179, height: 2556), 3) }
        return (screen.nativeBounds.size, screen.nativeScale)
    }
}
