import SwiftUI
import SeedCore

/// The meeting: two phones, one plant.
///
/// The screen only ever says one thing at a time, because the people using it
/// are looking at each other, not at it.
struct ExchangeView: View {
    @Environment(GardenModel.self) private var model
    @Environment(PlaceKeeping.self) private var place
    @Environment(\.dismiss) private var dismiss

    @State private var service = PollenExchangeService()
    @State private var noteOutcome: ExchangeOutcome?
    @State private var showingOffer = false
    /// Held before the search starts, the first time only. A name is the one
    /// thing the other person is going to see, so this is where it is asked
    /// for — with somebody to answer for, rather than on a first screen where
    /// there was nobody yet.
    @State private var naming = false
    /// Offered once, on the way in, and never again if it is declined. An offer
    /// repeated at every meeting has stopped being an offer.
    @State private var offeringPlace = false
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
            } else if offeringPlace {
                offerPlace
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
                beginAfterNaming()
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
                awaitingTouch(peerName: peerName)
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

    /// The place offer sits between the name and the search, so that the only
    /// system permission prompt this app can raise happens while somebody is
    /// reading about it, rather than in the middle of meeting a person.
    private func beginAfterNaming() {
        if place.shouldOffer {
            offeringPlace = true
        } else {
            startSearching()
        }
    }

    private func startSearching() {
        offeringPlace = false
        guard let identity = model.identity else { return }
        service.start(identity: identity, place: place)
    }

    // MARK: - Where you meet

    private var offerPlace: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Where you meet")
                .chromeHeading(size: 17)
                .foregroundStyle(Chrome.ink)

            Text("A meeting can keep the coordinates of the spot it happened in, shown as numbers you can open in a map. They stay on this phone.")
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Chrome.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Text("A meeting keeps them when both of you have asked for it, and you choose again every time.")
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Chrome.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            HStack(spacing: 14) {
                QuietButton(title: "Not now") {
                    place.declineOffer()
                    startSearching()
                }
                QuietButton(title: "Keep places", isProminent: true) {
                    place.enable()
                    startSearching()
                }
            }
            .padding(.top, 6)

            Spacer()
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: Chrome.readableWidth)
        .frame(maxWidth: .infinity)
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
                .underlining()

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
        beginAfterNaming()
    }

    // MARK: - Phases

    /// The moment before the crossing, where the gesture is waited for.
    ///
    /// On a simulator there is no accelerometer to feel the knock, so the
    /// waiting view takes a tap instead and says so. On a device the stand-in
    /// does not exist and `canFeelTouch` is always true, so this is exactly
    /// the screen it always was.
    @ViewBuilder
    private func awaitingTouch(peerName: String) -> some View {
        let felt = service.hasFeltLocalTouch
#if targetEnvironment(simulator)
        if !service.canFeelTouch {
            waiting(
                title: felt ? "Waiting for \(peerName)" : "Stand in for the knock",
                detail: felt
                    ? "Felt that. They need to tap theirs too."
                    : "\(peerName) is here. This simulator has no accelerometer, so tap anywhere to stand in for touching the phones together."
            )
            .contentShape(Rectangle())
            .onTapGesture { service.standInForTouch() }
        } else {
            knockWaiting(peerName: peerName, felt: felt)
        }
#else
        knockWaiting(peerName: peerName, felt: felt)
#endif
    }

    private func knockWaiting(peerName: String, felt: Bool) -> some View {
        waiting(
            title: felt ? "Waiting for \(peerName)" : "Touch the tops of your phones together",
            detail: felt
                ? "Felt that. They need to tap theirs too."
                : "\(peerName) is here. A light tap, top to top."
        )
    }

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
                service.start(identity: identity, place: place)
            }
            Spacer()
        }
        .padding(.horizontal, 46)
        .frame(maxWidth: Chrome.readableWidth)
        .frame(maxWidth: .infinity)
    }

}
