import SwiftUI
import SeedCore

/// The standing choices, and the two ways to start again.
///
/// Everything here is a preference rather than a fact about a plant. The seed,
/// the lineage and the birthday are not reachable from this screen and are not
/// meant to be: they are what a plant *is*, and the only thing anybody can do
/// to a seed is draw a different one.
///
/// The two resets are the reason this screen exists at all. Both are worded for
/// what survives them rather than for what they take, because the thing people
/// need to know before tapping is what they still have afterwards.
struct SettingsView: View {
    @Environment(GardenModel.self) private var model
    @Environment(PlaceKeeping.self) private var place
    @Environment(\.dismiss) private var dismiss

    @State private var draftName = ""
    @State private var editingName = false
    @State private var confirming: Reset?
    @AppStorage(Places.preferredKey) private var preferredPlace = ""
    @AppStorage(Sharing.invitationsKey) private var wantsInvitations = Sharing.invitationsDefault

    /// The two irreversible ones, and the one that only forgets plants.
    private enum Reset: String, Identifiable {
        case seed
        case plants
        case everything

        var id: String { rawValue }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    Text("Settings")
                        .chromeHeading()
                        .foregroundStyle(Chrome.ink)

                    name
                    Hairline()
                    places
                    Hairline()
                    whereYouMeet
                    Hairline()
                    beingTold
                    Hairline()
                    startingAgain
                }
                .padding(.horizontal, 30)
                .padding(.top, 34)
                .padding(.bottom, 60)
                .frame(maxWidth: Chrome.readableWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .overlay(alignment: .topTrailing) {
            QuietButton(title: "Close") { dismiss() }
                .padding(.trailing, 12)
                .padding(.top, 8)
        }
        // An alert rather than a confirmation dialog. The dialog rendered its
        // destructive button and dropped the cancel entirely on a sheet with a
        // black presentation background, which leaves an irreversible action
        // with no visible way out of it. An alert shows both, every time.
        .alert(
            confirming.map(title) ?? "",
            isPresented: confirmingBinding,
            presenting: confirming
        ) { reset in
            Button("Leave it", role: .cancel) {}
            Button(confirmLabel(reset), role: .destructive) { perform(reset) }
        } message: { reset in
            Text(consequence(reset))
        }
    }

    // MARK: - The name

    private var name: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What people see when you meet")
                .chromeLabel()
                .foregroundStyle(Chrome.faint)

            if editingName {
                TextField("", text: $draftName)
                    .font(.system(size: 17, weight: .light, design: .serif))
                    .foregroundStyle(Chrome.ink)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .underlining()
                    .onSubmit {
                        model.rename(to: draftName)
                        editingName = false
                    }
            } else {
                Button {
                    draftName = model.identity?.displayName ?? ""
                    editingName = true
                } label: {
                    Text(model.shownName)
                        .font(.system(size: 17, weight: .light, design: .serif))
                        .foregroundStyle(Chrome.ink)
                        .pressable()
                }
                .buttonStyle(.plain)
            }

            Text("Sent to the other phone during a meeting, and to nowhere else. Change it whenever; plants already grown keep the name you had at the time, because that is who they met.")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Chrome.muted)
                .lineSpacing(4)
        }
    }

    // MARK: - The place a note arrives holding

    /// A standing answer for the Where field.
    ///
    /// Left alone, each meeting is offered the place its own seed travelled
    /// through — see `Places`. Choosing one here says the same thing every
    /// time instead, which suits somebody who meets people in one place.
    private var places: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Where a meeting starts out saying")
                .chromeLabel()
                .foregroundStyle(Chrome.faint)

            Menu {
                Button("Wherever the seed travelled") { preferredPlace = "" }
                Divider()
                ForEach(Places.all, id: \.self) { option in
                    Button(option) { preferredPlace = option }
                }
            } label: {
                HStack(spacing: 10) {
                    Text(preferredPlace.isEmpty ? "Wherever the seed travelled" : preferredPlace)
                        .font(.system(size: 15, weight: .light))
                        .foregroundStyle(Chrome.ink)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .light))
                        .foregroundStyle(Chrome.faint)
                }
                .pressable()
            }

            Text("The Where field arrives already filled, and typing over it is always the point. What you write stays on this phone: two people at one meeting can remember it by different names.")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Chrome.muted)
                .lineSpacing(4)
        }
    }

    // MARK: - Places on the earth

    /// The same switch as the one on the seed screen, writing through the same
    /// owner. It appears twice because it answers two different questions —
    /// "what leaves my phone" over there, and "what is turned on" here — and
    /// `PlaceKeeping` is the single thing either one sets.
    private var whereYouMeet: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: placeBinding) {
                Text("Keep where you meet")
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(Chrome.ink)
            }
            .tint(Chrome.muted)

            Text("With this on, a meeting can keep the coordinates of the spot it happened in. Each phone measures its own and holds it there. A meeting keeps them when both of you have asked for it, and you choose again every time.")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Chrome.muted)
                .lineSpacing(4)
        }
    }

    private var placeBinding: Binding<Bool> {
        Binding(
            get: { place.isEnabled },
            set: { $0 ? place.enable() : place.disable() }
        )
    }

    // MARK: - Being told about a share

    /// The one thing the shared garden will ever ask of somebody who is not
    /// using it.
    ///
    /// A plant belongs to two people, so one of them putting it in the peace
    /// garden is one of them speaking, and the page carries that person's name
    /// alone. This is the offer to be named alongside them — and the offer is
    /// all it is, because until somebody accepts, the page says nothing about
    /// them at all.
    ///
    /// The switch does nothing today: phase 1 makes no network request, so
    /// there is nothing that could tell this phone a plant was shared. It is
    /// here because it is a decision about what somebody agrees to be told, and
    /// that belongs beside their other decisions rather than arriving with the
    /// feature. See docs/PHASES.md.
    private var beingTold: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $wantsInvitations) {
                Text("Tell me when a plant we made is shared")
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(Chrome.ink)
            }
            .tint(Chrome.muted)

            Text("When somebody puts a plant the two of you grew into the peace garden, it carries their name. You will be asked whether you would like yours on it as well, and the page waits for your answer before it says anything about you. Turning this off leaves their share exactly as it is.")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Chrome.muted)
                .lineSpacing(4)
        }
    }

    // MARK: - Starting again

    private var startingAgain: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Starting again")
                .chromeLabel()
                .foregroundStyle(Chrome.faint)

            resetRow(
                .seed,
                title: "Draw a new seed",
                detail: "A seed is drawn once, and this draws another. Your garden keeps every plant you have grown with somebody."
            )

            if !model.hybrids.isEmpty {
                resetRow(
                    .plants,
                    title: "Empty the garden",
                    detail: "Your own seed and the plant it grows stay. The \(model.hybrids.count) grown with other people leave this phone."
                )
            }

            resetRow(
                .everything,
                title: "Start from nothing",
                detail: "This phone keeps nothing, and the app opens on first light the way it did the day you installed it."
            )

            // The reassurance that actually matters, said once, at the bottom,
            // in terms of what stays rather than what cannot happen.
            Text("Plants other people grew with you stay in their gardens. Those were derived on their phones the moment you met, from a seed of their own.")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Chrome.muted)
                .lineSpacing(4)
        }
    }

    private func resetRow(_ reset: Reset, title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                confirming = reset
            } label: {
                Text(title)
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(Chrome.ink)
                    .pressable()
            }
            .buttonStyle(.plain)

            Text(detail)
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Chrome.muted)
                .lineSpacing(4)
        }
    }

    // MARK: - Confirming

    private var confirmingBinding: Binding<Bool> {
        Binding(
            get: { confirming != nil },
            set: { if !$0 { confirming = nil } }
        )
    }

    private func title(_ reset: Reset) -> String {
        switch reset {
        case .seed: return "Draw a new seed?"
        case .plants: return "Empty the garden?"
        case .everything: return "Start from nothing?"
        }
    }

    private func confirmLabel(_ reset: Reset) -> String {
        switch reset {
        case .seed: return "Draw a new seed"
        case .plants: return "Empty it"
        case .everything: return "Start from nothing"
        }
    }

    private func consequence(_ reset: Reset) -> String {
        switch reset {
        case .seed:
            return "The plant you have now was drawn once and this draws another. Your garden keeps every plant you have grown with somebody, and so do they."
        case .plants:
            return "Your own seed and its plant stay. The people you grew those plants with keep theirs."
        case .everything:
            return "Your seed, your plant and your garden all go. The people you have met keep the plants you grew together."
        }
    }

    private func perform(_ reset: Reset) {
        switch reset {
        case .seed: model.resetSeed()
        case .plants: model.forgetPlants()
        case .everything: model.resetEverything()
        }
        confirming = nil
        dismiss()
    }
}
