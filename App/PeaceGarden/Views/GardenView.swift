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

    // A maximum as well as a minimum: without it an iPad shows either a great
    // many small tiles or a few enormous ones.
    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 210), spacing: 18)]

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
                .chromeHeading(size: 18)
                .foregroundStyle(Chrome.ink)
            // The count carries a plural, so it is a catalogue entry with two
            // variations rather than one string with a number pushed into it.
            // English needs that at one — *1 grown from meetings* is wrong —
            // and every other language needs it at a different set of numbers
            // again.
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
        .frame(maxWidth: Chrome.readableWidth, alignment: .leading)
        .padding(.top, 40)
    }

    /// A plant, its name, and what it is doing.
    ///
    /// Centred under the picture rather than ranged left against it. A caption
    /// set to one edge of a square reads as a label filed beside the thing;
    /// centred, it reads as belonging to it, which is what a plant and its name
    /// are to each other.
    ///
    /// **The stage joins the gardener on one line.** A garden is somewhere to
    /// come back to, and what has changed since the last visit is the only
    /// thing here that moves — a tile that says only who you met says nothing
    /// about why you would open it today. Both on one line rather than two,
    /// separated the way `PlantStageView` already separates a stage from an
    /// age, because a third line under a tile this size is a paragraph.
    private func tile(for record: PlantRecord) -> some View {
        VStack(spacing: 10) {
            PlantThumbnail(genome: record.genome, growth: record.growth(now: model.now), size: 150)
                .frame(height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            VStack(spacing: 4) {
                Text(record.genome.name.full)
                    .plantName(size: 13)
                    .foregroundStyle(Chrome.ink)
                    .lineLimit(1)
                Text(verbatim: caption(for: record))
                    .chromeLabel(size: 9)
                    .foregroundStyle(Chrome.faint)
                    .lineLimit(1)
                    // Shrunk rather than truncated. A tracked-out label is wide
                    // for its point size, and a long name beside a long stage
                    // would otherwise lose its ending to an ellipsis — which is
                    // the half that says what the plant is doing.
                    .minimumScaleFactor(0.75)
            }
            .multilineTextAlignment(.center)
        }
    }

    /// A format string with two arguments rather than two values joined by a
    /// separator, so a translator can put the person first if their language
    /// would.
    ///
    /// It has a key of its own rather than being written as `%1$@ · %2$@`,
    /// because the caption under a plant on the stage has exactly that shape
    /// and means something else — a stage and an interval, where this is a
    /// stage and a person. Two entries that read the same and are translated
    /// differently cannot share a key.
    private func caption(for record: PlantRecord) -> String {
        let stage = String(localized: record.growth(now: model.now).stage.label)
        guard let name = record.encounter?.peerDisplayName, !name.isEmpty else { return stage }
        return String(
            localized: "tile.caption",
            defaultValue: "\(stage) · \(name)",
            comment: "Under a plant in the garden. First what the plant is doing, then who it was grown with."
        )
    }
}
