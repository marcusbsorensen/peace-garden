import SwiftUI
import SeedCore

/// What to remember about the meeting.
///
/// All of it is optional and typed by hand. The date and time are offered
/// because they were part of the meeting, not captured because they were
/// available — and the place is a text field, not the device's location.
struct EncounterNoteView: View {
    let outcome: ExchangeOutcome
    let onKeep: (EncounterNote) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showsDateTime = true
    @State private var place = ""
    @State private var note = ""
    @FocusState private var noteFocused: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    VStack(alignment: .leading, spacing: 8) {
                        // The heading voice uppercases, so this shouts a
                        // person's name back at whoever just met them. Left
                        // that way for now because the alternative — a heading
                        // that opts out of the heading voice — is worse, but it
                        // is the one place the rule chafes.
                        Text("Met \(outcome.peerDisplayName)")
                            .chromeHeading(size: 17)
                            .foregroundStyle(Chrome.ink)
                        Text(outcome.happenedAt.formatted(date: .complete, time: .shortened))
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(Chrome.faint)
                    }

                    Hairline()

                    Toggle(isOn: $showsDateTime) {
                        Text("Remember the date and time")
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(Chrome.muted)
                    }
                    .tint(Chrome.muted)

                    field(label: "Where", text: $place, prompt: "A place, if you like")

                    VStack(alignment: .leading, spacing: 10) {
                        Text("About this meeting")
                            .chromeLabel()
                            .foregroundStyle(Chrome.faint)
                        TextField(
                            "",
                            text: $note,
                            prompt: Text("A line to remember it by").foregroundStyle(Chrome.faint),
                            axis: .vertical
                        )
                        .font(.system(size: 16, weight: .light, design: .serif))
                        .foregroundStyle(Chrome.ink)
                        .lineLimit(3...6)
                        .focused($noteFocused)
                        .onChange(of: note) { _, newValue in
                            if newValue.count > EncounterNote.noteCharacterLimit {
                                note = String(newValue.prefix(EncounterNote.noteCharacterLimit))
                            }
                        }
                        Hairline()
                        Text("\(EncounterNote.noteCharacterLimit - note.count) left")
                            .chromeLabel(size: 10)
                            .foregroundStyle(Chrome.faint)
                    }

                    HStack {
                        QuietButton(title: "Keep it") { keep() }
                        Spacer()
                        QuietButton(title: "Discard") { dismiss() }
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 34)
                .frame(maxWidth: Chrome.readableWidth)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private func field(label: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .chromeLabel()
                .foregroundStyle(Chrome.faint)
            TextField("", text: text, prompt: Text(prompt).foregroundStyle(Chrome.faint))
                .font(.system(size: 16, weight: .light, design: .serif))
                .foregroundStyle(Chrome.ink)
                .autocorrectionDisabled()
            Hairline()
        }
    }

    private func keep() {
        noteFocused = false
        onKeep(
            EncounterNote(
                peerDisplayName: outcome.peerDisplayName,
                happenedAt: outcome.happenedAt,
                showsDateTime: showsDateTime,
                place: place.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : place,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note
            )
        )
    }
}
