import SwiftUI
import SeedCore

/// A seed that arrived from somewhere else — a code, a message, a link.
struct IncomingSeedView: View {
    let outcome: ExchangeOutcome
    let reply: URL?

    @Environment(GardenModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var showingNote = false
    @State private var kept = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if kept, let reply {
                sendItBack(reply)
            } else {
                PlantRevealView(
                    outcome: outcome,
                    subtitle: "From \(outcome.peerDisplayName)'s \(outcome.peerPlantName)"
                ) {
                    showingNote = true
                }
            }
        }
        .sheet(isPresented: $showingNote) {
            EncounterNoteView(outcome: outcome) { note in
                model.save(outcome: outcome, note: note)
                showingNote = false
                if reply == nil {
                    finish()
                } else {
                    kept = true
                }
            }
            .presentationBackground(.black)
        }
        .overlay(alignment: .topTrailing) {
            QuietButton(title: kept ? "Done" : "Not this time") { finish() }
                .padding(.trailing, 12)
                .padding(.top, 12)
        }
    }

    /// The other person cannot grow this plant without something back: they
    /// need the seed drawn on this phone. Until this is sent, the plant is
    /// only here.
    private func sendItBack(_ reply: URL) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Send one back")
                .plantName(size: 23)
                .foregroundStyle(Chrome.ink)

            if let code = SeedOfferView.code(for: reply) {
                Image(uiImage: code)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            Text("\(outcome.peerDisplayName) cannot grow this plant without a seed from you. Show them this, or send it.")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Chrome.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 44)

            ShareLink(item: reply) {
                Text("Send it")
                    .chromeLabel()
                    .foregroundStyle(Chrome.ink)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
            }
            Spacer()
        }
    }

    private func finish() {
        model.clearIncoming()
        dismiss()
    }
}
