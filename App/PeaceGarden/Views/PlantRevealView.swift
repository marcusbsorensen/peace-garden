import SwiftUI
import SeedCore

/// The moment a new plant is shown for the first time.
///
/// Used both by a face-to-face exchange and by a seed that arrived as a link,
/// because from here on they are the same thing: a plant that came from meeting
/// someone, waiting to be kept.
struct PlantRevealView: View {
    @Environment(GardenModel.self) private var model
    let outcome: ExchangeOutcome
    var subtitle: String?
    let onKeep: () -> Void

    /// The third and last thing the app explains itself with. Someone holding
    /// no crossed plants has never seen this happen, so this is the moment it
    /// is worth saying what just happened; after that the screen is the quieter
    /// one, because by then they know.
    private var isFirstMeeting: Bool { model.hybrids.isEmpty }

    var body: some View {
        let genome = outcome.result.genome
        // Shown as it will be in bloom. A plant born a second ago is a speck,
        // and the point of this moment is to see what the two of you made.
        let preview = PlantSceneBuilder.bloomPreview(for: genome)

        VStack(spacing: 0) {
            PlantSceneView(genome: genome, growth: preview, autoRotates: true)
                .background(StageBackdrop(palette: genome.palette))
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 10) {
                if isFirstMeeting {
                    Text("Your plants have created a brand new seed.")
                        .chromeHeading(size: 16)
                        .foregroundStyle(Chrome.ink)
                        .padding(.bottom, 4)

                    Text(Quotes.line(for: outcome.result.childSeed))
                        .font(.system(size: 15, weight: .light))
                        .foregroundStyle(Chrome.muted)
                        .lineSpacing(5)
                        .padding(.bottom, 6)
                } else {
                    Text(genome.name.full)
                        .plantName(size: 24)
                        .foregroundStyle(Chrome.ink)
                    Text(subtitle ?? "Your plant and \(outcome.peerPlantName), together")
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(Chrome.muted)
                }

                Text("It will open like this in \(Int(genome.tempo.daysToBloom.rounded())) days")
                    .chromeLabel()
                    .foregroundStyle(Chrome.faint)
                    .padding(.top, 2)

                QuietButton(
                    title: isFirstMeeting ? "Plant in peace garden" : "Keep this plant",
                    isProminent: true,
                    action: onKeep
                )
                .padding(.top, 10)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 34)
            .padding(.bottom, 40)
            .frame(maxWidth: Chrome.readableWidth)
            .frame(maxWidth: .infinity)
        }
    }

}
