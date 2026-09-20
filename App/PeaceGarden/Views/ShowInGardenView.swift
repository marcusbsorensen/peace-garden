import SwiftUI
import SeedCore

/// The one screen where a plant is put into the shared garden, or kept out of it.
///
/// **One screen for both gardeners**, because they are being told the same
/// facts and only the question at the end differs. `docs/WEBSITE.md` worked out
/// that the invitation the second gardener receives has to ask the same large
/// question as the first one answered — *anyone can come across this* — and the
/// surest way for two screens not to drift into a large question and a small
/// one is for there to be one screen.
///
/// **What it does not do yet.** A plant in the Long Walk stands there as a
/// plant: what is published is its seed, its parents' seeds and the meeting's
/// ID, which is what a browser needs to grow it, and nothing that was written
/// about the meeting. The name-and-note flow WEBSITE.md specifies belongs to a
/// plant's own page, which does not exist; when it does, it is a second consent
/// with its own screen, and the sentence *nothing publishes prose on a yes
/// given to a different question* is the reason it cannot be folded into this
/// one.
struct ShowInGardenView: View {
    let record: PlantRecord

    @Environment(GardenModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var working = false
    @State private var trouble: String?

    /// Whether this phone is being asked, rather than doing the asking.
    private var isBeingAsked: Bool { record.standingOrHere.state == .invited }

    private var peer: String {
        record.encounter?.peerDisplayName ?? String(localized: "the other gardener")
    }

    var body: some View {
        ZStack {
            // **The plant is on the screen it is about.** This was the one
            // screen in the app with no plant on it, which made the question
            // abstract: *show this plant* with nothing to look at is a
            // checkbox. It stands here the way it stands everywhere else, and
            // the words are read over it through the same veil the detail
            // screen uses, for the same reason — a plant is the subject and
            // has nowhere else to go.
            StageBackdrop(
                palette: record.genome.palette,
                presence: record.growth(now: model.now).heightScale
            )
            .ignoresSafeArea()

            PlantSceneView(genome: record.genome, growth: record.growth(now: model.now))
                .ignoresSafeArea()

            StageVeil(cut: .reading)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            content
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 22) {
                    Text(record.genome.name.full)
                        .plantName()
                        .foregroundStyle(Chrome.ink)
                        // Clear of Close, which sits in the same corner of the
                        // same screen and was catching the long names.
                        .padding(.horizontal, 64)
                        .padding(.top, 62)

                    if isBeingAsked {
                        headline("\(peer) would like this plant to stand in the peace garden.")
                    } else {
                        headline("Show this plant in the peace garden.")
                    }

                    VStack(spacing: 16) {
                        fact("The garden is open. Anyone walking it can come across this plant.")
                        fact("What stands there is the plant itself, grown from its seed at its real age, the way it grows here.")
                        fact("Your name, what you wrote about the meeting and the day it happened stay on this phone.")
                        // The load-bearing one, and the reason there is a second
                        // gardener to ask at all.
                        if isBeingAsked {
                            fact("It grew from your seed and \(peer)'s together, so the garden carries both. That is why you are being asked.")
                        } else {
                            fact("It grew from your seed and \(peer)'s together, so the garden carries both. They are asked before it goes anywhere.")
                        }
                    }
                    .padding(.horizontal, 40)
                    .frame(maxWidth: Chrome.readableWidth)

                    if let trouble {
                        Text(verbatim: trouble)
                            .chromeLabel()
                            .foregroundStyle(Chrome.ochre)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
                .padding(.bottom, 28)
            }

            VStack(spacing: 6) {
                if isBeingAsked {
                    QuietButton(title: "Let it stand there", isProminent: true) { answer(yes: true) }
                    QuietButton(title: "Keep it here") { answer(yes: false) }
                    // Said plainly, because it is the one irreversible half of
                    // this screen and a decline is also the block: there is one
                    // invitation for a plant and this is it.
                    // **Prose, in the plain voice.** It wore the app's label
                    // voice — small, uppercase, wide-tracked — which is for
                    // one or two words on a control. Two sentences in it came
                    // out as three ragged lines of capitals that nobody reads,
                    // and this is the sentence on the screen that most needs
                    // reading.
                    Text("Keeping it here is final for this plant. Yours stays exactly where it is either way.")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Chrome.faint)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 6)
                } else {
                    QuietButton(title: "Ask \(peer)", isProminent: true) { ask() }
                    QuietButton(title: "Not now") { dismiss() }
                    Text("It appears in the garden only once they say yes.")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Chrome.faint)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 6)
                }
            }
            .frame(maxWidth: Chrome.readableWidth)
            .padding(.bottom, 34)
            .opacity(working ? 0.4 : 1)
            .allowsHitTesting(!working)
            .animation(Chrome.fadeIn, value: working)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topTrailing) {
            QuietButton(title: "Close") { dismiss() }
                .padding(.trailing, 12)
                .padding(.top, 12)
        }
    }

    private func headline(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.system(size: 19, weight: .light, design: .serif))
            .foregroundStyle(Chrome.ink)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .padding(.horizontal, 40)
            .frame(maxWidth: Chrome.readableWidth)
    }

    private func fact(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.system(size: 14, weight: .light))
            .foregroundStyle(Chrome.muted)
            .multilineTextAlignment(.center)
            .lineSpacing(3)
            .frame(maxWidth: .infinity)
    }

    // MARK: Doing it

    private func ask() {
        run { await model.offer(record) }
    }

    private func answer(yes: Bool) {
        run { await model.answer(record, yes: yes) }
    }

    private func run(_ work: @escaping () async -> Result<Standing, PlotService.Trouble>) {
        guard !working else { return }
        working = true
        trouble = nil
        Task {
            switch await work() {
            case .success:
                dismiss()
            case .failure:
                // One sentence, in this person's language, saying what to do
                // rather than what the service said. The service writes in
                // English and its words are for the log.
                //
                // **One sentence for all three troubles**, and it has to be
                // true of each: no signal, a service that refused, and a
                // service saying this address has written too much lately.
                // *When you have a signal* was true of one of them and wrong
                // about the other two. Telling them apart on screen would mean
                // a duration in forty-two languages for a case an ordinary
                // person never meets.
                trouble = String(localized: "The garden could not be reached just now. Nothing has changed; try again in a little while.")
                working = false
            }
        }
    }
}
