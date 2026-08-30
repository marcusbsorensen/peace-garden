import SwiftUI
import SeedCore

/// The garden: your own plant, and everything that has grown out of a meeting.
///
/// In this phase the garden is the one on this phone. The shared peace garden —
/// other people's plots, guest books — is the next phase; see docs/PHASES.md.
struct GardenView: View {
    @Environment(GardenModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var selected: PlantRecord?

    private let columns = [GridItem(.adaptive(minimum: 132), spacing: 18)]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    header

                    if model.hybrids.isEmpty {
                        empty
                    } else {
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(model.hybrids) { record in
                                Button {
                                    selected = record
                                } label: {
                                    tile(for: record)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 34)
            }
        }
        .overlay(alignment: .topTrailing) {
            QuietButton(title: "Close") { dismiss() }
                .padding(.trailing, 12)
                .padding(.top, 12)
        }
        .fullScreenCover(item: $selected) { record in
            PlantDetailView(record: record).environment(model)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Peace garden")
                .plantName(size: 26)
                .foregroundStyle(Chrome.ink)
            Text(model.hybrids.isEmpty
                 ? "Nothing has been crossed yet"
                 : "\(model.hybrids.count) grown from meetings")
                .chromeLabel()
                .foregroundStyle(Chrome.faint)
        }
        .padding(.top, 30)
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Every plant here came from meeting someone. Open Meet with another person and touch the tops of your phones together.")
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Chrome.muted)
                .lineSpacing(5)
        }
        .padding(.top, 40)
    }

    private func tile(for record: PlantRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            PlantThumbnail(genome: record.genome, growth: record.growth(now: model.now), size: 150)
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: 4) {
                Text(record.genome.name.full)
                    .font(.system(size: 13, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(Chrome.ink)
                    .lineLimit(1)
                if let encounter = record.encounter {
                    Text(encounter.peerDisplayName)
                        .chromeLabel(size: 9)
                        .foregroundStyle(Chrome.faint)
                        .lineLimit(1)
                }
            }
        }
    }
}
