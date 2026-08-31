import SwiftUI
import SeedCore

/// What this person's seed actually is, and what leaves the phone.
///
/// People are being asked to carry an identifier around and hand it to
/// strangers; they are owed a plain account of what it is.
struct SeedView: View {
    @Environment(GardenModel.self) private var model
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
                    .padding(.vertical, 34)
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
                    Text("Seen as \(model.shownName)")
                        .font(.system(size: 15, weight: .light))
                        .foregroundStyle(Chrome.muted)
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

    private var privacyNote: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What is shared")
                .chromeLabel()
                .foregroundStyle(Chrome.faint)
            Text("When you meet someone, your phones exchange this seed, the name above, and a random number for that meeting. Nothing else: no account, no contacts, no location, and nothing is sent to a server. The seed cannot be turned back into anything about you or your phone.")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Chrome.muted)
                .lineSpacing(4)
        }
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
