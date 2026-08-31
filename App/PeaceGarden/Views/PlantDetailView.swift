import SwiftUI
import SeedCore

/// One kept plant, and the meeting it came from.
struct PlantDetailView: View {
    let record: PlantRecord

    @Environment(GardenModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var detailsVisible = false
    @State private var confirmingDelete = false
    @State private var editing = false

    var body: some View {
        ZStack {
            StageBackdrop(
                palette: record.genome.palette,
                presence: record.growth(now: model.now).heightScale
            )
                .ignoresSafeArea()

            PlantSceneView(
                genome: record.genome,
                growth: record.growth(now: model.now),
                onTap: { withAnimation(Chrome.fadeIn) { detailsVisible.toggle() } }
            )
            .ignoresSafeArea()

            details
                .opacity(detailsVisible ? 1 : 0)
                .allowsHitTesting(detailsVisible)
                .animation(Chrome.fadeIn, value: detailsVisible)
        }
        .overlay(alignment: .topTrailing) {
            QuietButton(title: "Close") { dismiss() }
                .padding(.trailing, 12)
                .padding(.top, 12)
        }
        .confirmationDialog("Let this plant go?", isPresented: $confirmingDelete) {
            Button("Let it go", role: .destructive) {
                model.delete(record)
                dismiss()
            }
            Button("Keep it", role: .cancel) {}
        } message: {
            Text("This cannot be undone. The plant cannot be grown again.")
        }
        .sheet(isPresented: $editing) {
            EncounterEditView(record: record) { name, place, keepsCoordinate in
                model.updateEncounter(
                    of: record,
                    peerDisplayName: name,
                    place: .some(place),
                    keepsCoordinate: keepsCoordinate
                )
            }
            .presentationBackground(.black)
        }
    }

    private var details: some View {
        VStack {
            VStack(spacing: 8) {
                Text(record.genome.name.full)
                    .plantName()
                    .foregroundStyle(Chrome.ink)
                Text(record.growth(now: model.now).summary())
                    .chromeLabel()
                    .foregroundStyle(Chrome.faint)
            }
            .padding(.top, 64)

            Spacer()

            if let encounter = record.encounter {
                VStack(spacing: 12) {
                    if let note = encounter.note {
                        Text(note)
                            .font(.system(size: 16, weight: .light, design: .serif))
                            .italic()
                            .foregroundStyle(Chrome.ink)
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                    }

                    VStack(spacing: 4) {
                        Text("with \(encounter.peerDisplayName)")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(Chrome.muted)
                        if let place = encounter.place {
                            Text(place)
                                .chromeLabel(size: 10)
                                .foregroundStyle(Chrome.faint)
                        }
                        if encounter.showsDateTime {
                            Text(encounter.happenedAt.formatted(date: .long, time: .shortened))
                                .chromeLabel(size: 10)
                                .foregroundStyle(Chrome.faint)
                        }
                        // Numbers rather than a place name, and a tap to let a
                        // map say the name if anybody wants it. See
                        // `CoordinateDisplay`.
                        if let coordinate = encounter.coordinate {
                            if let url = coordinate.mapURL {
                                Link(destination: url) {
                                    Text(coordinate.written)
                                        .chromeLabel(size: 10)
                                        .foregroundStyle(Chrome.muted)
                                        .pressable()
                                }
                                .padding(.top, 4)
                            } else {
                                Text(coordinate.written)
                                    .chromeLabel(size: 10)
                                    .foregroundStyle(Chrome.faint)
                            }
                        }
                    }

                    QuietButton(title: "Tell it differently") { editing = true }
                        .padding(.top, 4)
                }
                .padding(.horizontal, 40)
                .frame(maxWidth: Chrome.readableWidth)
                .padding(.bottom, 18)
            }

            QuietButton(title: "Let it go") { confirmingDelete = true }
                .padding(.bottom, 30)
        }
    }
}
