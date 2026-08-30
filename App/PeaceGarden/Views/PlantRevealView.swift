import SwiftUI
import SeedCore

/// The moment a new plant is shown for the first time.
///
/// Used both by a face-to-face exchange and by a seed that arrived as a link,
/// because from here on they are the same thing: a plant that came from meeting
/// someone, waiting to be kept.
struct PlantRevealView: View {
    let outcome: ExchangeOutcome
    var subtitle: String?
    let onKeep: () -> Void

    var body: some View {
        let genome = outcome.result.genome
        // Shown as it will be in bloom. A plant born a second ago is a speck,
        // and the point of this moment is to see what the two of you made.
        let preview = Self.bloomPreview(for: genome)

        VStack(spacing: 0) {
            PlantSceneView(genome: genome, growth: preview, autoRotates: true)
                .background(StageBackdrop(palette: genome.palette))
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 10) {
                Text(genome.name.full)
                    .plantName(size: 24)
                    .foregroundStyle(Chrome.ink)
                Text(subtitle ?? "Your plant and \(outcome.peerPlantName), together")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Chrome.muted)
                Text("It will open like this in \(Int(genome.tempo.daysToBloom.rounded())) days")
                    .chromeLabel()
                    .foregroundStyle(Chrome.faint)
                    .padding(.top, 2)

                QuietButton(title: "Keep this plant", isProminent: true, action: onKeep)
                    .padding(.top, 10)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 34)
            .padding(.bottom, 40)
        }
    }

    static func bloomPreview(for genome: Genome) -> GrowthModel.State {
        let birth = Date(timeIntervalSince1970: 0)
        let atBloom = birth.addingTimeInterval(
            (genome.tempo.daysToBloom + genome.tempo.bloomDays * 0.45) * 86_400
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        // Pinned to the hour this genome opens widest, so the preview is the
        // plant at its best rather than whatever time it happens to be.
        let hour = genome.tempo.opensByDay ? 13 : 1
        let pinned = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: atBloom) ?? atBloom
        return GrowthModel(genome: genome).state(birth: birth, now: pinned, calendar: calendar)
    }
}
