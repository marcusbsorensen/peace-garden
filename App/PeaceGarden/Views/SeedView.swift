import SwiftUI
import SeedCore

/// What this person's seed actually is, and what leaves the phone.
///
/// People are being asked to carry an identifier around and hand it to
/// strangers; they are owed a plain account of what it is.
struct SeedView: View {
    @Environment(GardenModel.self) private var model
    @Environment(PlaceKeeping.self) private var place
    @Environment(\.dismiss) private var dismiss
    @State private var editingName = false
    @State private var draftName = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let identity = model.identity {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        header(identity: identity)
                        Hairline()
                        traits(identity: identity)
                        Hairline()
                        privacyNote
                    }
                    .padding(.horizontal, 30)
                    // Clear of Close, which sits in its own band across the top
                    // rather than in the scroll.
                    .padding(.top, 68)
                    .padding(.bottom, 34)
                    .frame(maxWidth: Chrome.readableWidth)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            QuietButton(title: "Close") { dismiss() }
                .padding(.trailing, 12)
                .padding(.top, 8)
        }
    }

    @ViewBuilder
    private func header(identity: Identity) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(identity.genome.name.full)
                .plantName(size: 28)
                .foregroundStyle(Chrome.ink)

            Text(identity.genome.form.archetype.displayName)
                .chromeLabel()
                .foregroundStyle(Chrome.faint)

            if editingName {
                TextField("", text: $draftName)
                    .font(.system(size: 17, weight: .light, design: .serif))
                    .foregroundStyle(Chrome.ink)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit {
                        model.rename(to: draftName)
                        editingName = false
                    }
            } else {
                Button {
                    draftName = identity.displayName
                    editingName = true
                } label: {
                    // The worst offender of the lot before it got an edge: a
                    // sentence in the middle of a paragraph that happened to be
                    // the only way to change your name.
                    Text("Seen as \(model.shownName)")
                        .font(.system(size: 15, weight: .light))
                        .foregroundStyle(Chrome.muted)
                        .pressable()
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func traits(identity: Identity) -> some View {
        let genome = identity.genome
        VStack(alignment: .leading, spacing: 14) {
            row("Seed", identity.seed.short)
            row("Drawn", identity.birth.formatted(date: .abbreviated, time: .shortened))
            row("Petals", genome.bloom.present ? "\(genome.bloom.petalCount) across \(genome.bloom.layers)" : "None")
            row("Leaves", "\(genome.leafCount)")
            row("Opens", genome.tempo.opensByDay ? "By day" : "By night")
            row("First bloom", "\(Int(genome.tempo.daysToBloom.rounded())) days from drawing")
        }
    }

    /// The standing choice about places, and the paragraph it changes.
    ///
    /// Kept together on purpose. A switch that alters what leaves the phone
    /// belongs beside the sentence saying what leaves the phone, so that turning
    /// it on and reading what it means are the same glance.
    private var privacyNote: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("What is shared")
                    .chromeLabel()
                    .foregroundStyle(Chrome.faint)
                Text("When you meet someone, your phones exchange this seed, the name above, and a random number for that meeting. That is everything that crosses between you, and it goes directly from phone to phone. The seed cannot be turned back into anything about you or your phone.")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Chrome.muted)
                    .lineSpacing(4)
            }

            Hairline()

            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: placeBinding) {
                    Text("Log where you meet")
                        .font(.system(size: 15, weight: .light))
                        .foregroundStyle(Chrome.ink)
                }
                .tint(Chrome.muted)

                Text("With this on, a meeting can log the coordinates of the spot it happened in. Each phone measures its own and holds it there. A meeting logs them when both of you have asked for it, and you choose again every time.")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Chrome.muted)
                    .lineSpacing(4)
            }
        }
    }

    /// Writes through the one object that owns this, so that the switch, the
    /// system permission and what the exchange promises cannot drift apart.
    private var placeBinding: Binding<Bool> {
        Binding(
            get: { place.isEnabled },
            set: { $0 ? place.enable() : place.disable() }
        )
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .chromeLabel()
                .foregroundStyle(Chrome.faint)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(Chrome.ink)
        }
    }
}
