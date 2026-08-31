import SwiftUI
import SeedCore

/// The meeting: two phones, one plant.
///
/// The screen only ever says one thing at a time, because the people using it
/// are looking at each other, not at it.
struct ExchangeView: View {
    @Environment(GardenModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var service = PollenExchangeService()
    @State private var noteOutcome: ExchangeOutcome?
    @State private var showingOffer = false
    /// Held before the search starts, the first time only. A name is the one
    /// thing the other person is going to see, so this is where it is asked
    /// for — with somebody to answer for, rather than on a first screen where
    /// there was nobody yet.
    @State private var naming = false
    @State private var draftName = ""
    @FocusState private var nameFocused: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // The counterpart to first light: two fronds opening rather than
            // one, for the screen where a seed is being made with someone else.
            UnfurlingBackdrop(.pair)

            if naming {
                nameYourself
            } else {
                phases
            }
        }
        .overlay(alignment: .topTrailing) {
            QuietButton(title: closeTitle) { dismiss() }
                .padding(.trailing, 12)
                .padding(.top, 12)
        }
        .sheet(item: $noteOutcome) { outcome in
            EncounterNoteView(outcome: outcome) { note in
                model.save(outcome: outcome, note: note)
                noteOutcome = nil
                dismiss()
            }
            .presentationBackground(.black)
        }
        .fullScreenCover(isPresented: $showingOffer) {
            SeedOfferView().environment(model)
        }
        .onAppear {
            if model.hasChosenName {
                startSearching()
            } else {
                naming = true
            }
        }
        .onDisappear {
            service.stop()
        }
    }

    @ViewBuilder
    private var phases: some View {
        Group {
            switch service.phase {
            case .idle, .searching:
                VStack(spacing: 0) {
                    waiting(
                        title: "Looking for someone nearby",
                        detail: "Ask them to open Meet on their phone too."
                    )
                    QuietButton(title: "They don't have the app") {
                        showingOffer = true
                    }
                    .padding(.bottom, 40)
                }
            case .awaitingTouch(let peerName):
                waiting(
                    title: service.hasFeltLocalTouch ? "Waiting for \(peerName)" : "Touch the tops of your phones together",
                    detail: service.hasFeltLocalTouch
                        ? "Felt that. They need to tap theirs too."
                        : "\(peerName) is here. A light tap, top to top."
                )
            case .crossing(let peerName):
                waiting(title: "Crossing", detail: "Your seed and \(peerName)'s.")
            case .grown(let outcome):
                grown(outcome)
            case .failed(let message):
                failure(message)
            }
        }
    }

    private var closeTitle: String {
        if case .grown = service.phase { return "Not this time" }
        return "Cancel"
    }

    private func startSearching() {
        guard let identity = model.identity else { return }
        service.start(identity: identity)
    }

    // MARK: - A name, once

    /// Asked once, on the way into the first meeting, and never again — the
    /// name lives in Seed after this and can be changed there.
    private var nameYourself: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("What they will see")
                .chromeHeading(size: 17)
                .foregroundStyle(Chrome.ink)

            Text("Your name sits beside your plant on the other person's phone, and in the note they keep of the meeting.")
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Chrome.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            TextField("", text: $draftName, prompt: Text("Gardener").foregroundStyle(Chrome.faint))
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(Chrome.ink)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .focused($nameFocused)
                .submitLabel(.done)
                .onSubmit(acceptName)
                .padding(.top, 6)

            SproutingRule()
                .padding(.horizontal, 60)

            // One button, whichever way they go. Leaving the field alone is a
            // choice with a name on it rather than a step that was skipped.
            QuietButton(
                title: trimmedName.isEmpty ? "Meet as Gardener" : "That's me",
                isProminent: true,
                action: acceptName
            )
            .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal, 46)
        .frame(maxWidth: Chrome.readableWidth)
        .frame(maxWidth: .infinity)
    }

    private var trimmedName: String {
        draftName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func acceptName() {
        nameFocused = false
        // `rename` keeps an empty name out of the garden on its own, so
        // "Gardener" stays the fallback rather than becoming somebody's name.
        model.rename(to: trimmedName)
        naming = false
        startSearching()
    }

    // MARK: - Phases

    private func waiting(title: String, detail: String) -> some View {
        VStack(spacing: 22) {
            Spacer()
            BreathingDot(diameter: 9)
            Text(title)
                .font(.system(size: 20, weight: .light, design: .serif))
                .foregroundStyle(Chrome.ink)
                .multilineTextAlignment(.center)
            Text(detail)
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Chrome.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            Spacer()
        }
        .padding(.horizontal, 46)
        .frame(maxWidth: Chrome.readableWidth)
        .frame(maxWidth: .infinity)
    }

    private func grown(_ outcome: ExchangeOutcome) -> some View {
        PlantRevealView(outcome: outcome) {
            noteOutcome = outcome
        }
    }

    private func failure(_ message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Nothing took")
                .font(.system(size: 20, weight: .light, design: .serif))
                .foregroundStyle(Chrome.ink)
            Text(message)
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Chrome.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            QuietButton(title: "Try again", isProminent: true) {
                guard let identity = model.identity else { return }
                service.start(identity: identity)
            }
            Spacer()
        }
        .padding(.horizontal, 46)
        .frame(maxWidth: Chrome.readableWidth)
        .frame(maxWidth: .infinity)
    }

}
