import SwiftUI
import SeedCore

/// Telling a kept plant's story differently.
///
/// Only the told half is here: what the other person was called, what the place
/// was called, and whether the coordinate is still held. The seed, the lineage
/// and the birthday are untouched and unreachable from this screen, so nothing
/// anybody writes can change what grows.
///
/// That split is the whole reason this screen can exist at all. A parent may
/// tell a child more of the story later, or correct a part of it, and none of
/// that alters whose child it is.
struct EncounterEditView: View {
    let record: PlantRecord
    let onSave: (String, String?, Bool) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var peerDisplayName = ""
    @State private var place = ""
    @State private var keepsCoordinate = true

    private var coordinate: Coordinate? { record.encounter?.coordinate }

    var body: some View {
        ZStack {
            Chrome.ground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tell it differently")
                            .chromeHeading(size: 17)
                            .foregroundStyle(Chrome.ink)
                        Text("What this plant says about the meeting. What it grows from stays as it is.")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(Chrome.faint)
                            .lineSpacing(4)
                    }

                    Hairline()

                    field(label: "Met", text: $peerDisplayName, prompt: "Their name")
                    field(label: "Where", text: $place, prompt: "A place, if you like")

                    if let coordinate {
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle(isOn: $keepsCoordinate) {
                                Text("Keep the coordinates")
                                    .font(.system(size: 15, weight: .light))
                                    .foregroundStyle(Chrome.ink)
                            }
                            .tint(Chrome.muted)

                            Text(verbatim: coordinate.written)
                                .font(.system(size: 14, weight: .light).monospacedDigit())
                                .foregroundStyle(keepsCoordinate ? Chrome.muted : Chrome.faint)

                            // Said plainly, because a switch that quietly keeps
                            // the data would make the whole consent worthless.
                            Text("Turning this off removes them from this phone for good.")
                                .font(.system(size: 13, weight: .light))
                                .foregroundStyle(Chrome.faint)
                                .lineSpacing(4)
                        }
                    }

                    HStack {
                        QuietButton(title: "Keep it", isProminent: true) {
                            onSave(
                                peerDisplayName,
                                place.trimmingCharacters(in: .whitespacesAndNewlines),
                                keepsCoordinate
                            )
                            dismiss()
                        }
                        Spacer()
                        QuietButton(title: "Leave it") { dismiss() }
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
        .onAppear {
            guard let encounter = record.encounter else { return }
            peerDisplayName = encounter.peerDisplayName
            place = encounter.place ?? ""
            keepsCoordinate = encounter.coordinate != nil
        }
    }

    private func field(
        label: LocalizedStringKey,
        text: Binding<String>,
        prompt: LocalizedStringKey
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .chromeLabel()
                .foregroundStyle(Chrome.faint)
            TextField(label, text: text, prompt: Text(prompt).foregroundStyle(Chrome.faint))
                .labelsHidden()
                .font(.system(size: 16, weight: .light, design: .serif))
                .foregroundStyle(Chrome.ink)
                .autocorrectionDisabled()
            Hairline()
        }
    }
}
