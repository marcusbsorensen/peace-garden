import SwiftUI
import SeedCore

/// The meeting: two phones, one plant.
///
/// The screen only ever says one thing at a time, because the people using it
/// are looking at each other, not at it.
struct ExchangeView: View {
    @Environment(GardenModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var service = PollenExchangeService()
    @State private var noteOutcome: ExchangeOutcome?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch service.phase {
            case .idle, .searching:
                waiting(
                    title: "Looking for someone nearby",
                    detail: "Ask them to open Meet on their phone too."
                )
            case .awaitingTouch(let peerName):
                waiting(
                    title: service.hasFeltLocalTouch ? "Waiting for \(peerName)" : "Touch the tops of your phones together",
                    detail: service.hasFeltLocalTouch
                        ? "Felt that. They need to tap theirs too."
                        : "\(peerName) is here. A light tap, top to top."
                )
            case .crossing(let peerName):
                waiting(title: "Crossing", detail: "Your seed and \(peerName)'s.")
            case .grown(let outcome):
                grown(outcome)
            case .failed(let message):
                failure(message)
            }
        }
        .overlay(alignment: .topTrailing) {
            QuietButton(title: closeTitle) { dismiss() }
                .padding(.trailing, 12)
                .padding(.top, 12)
        }
        .sheet(item: $noteOutcome) { outcome in
            EncounterNoteView(outcome: outcome) { note in
                model.save(outcome: outcome, note: note)
                noteOutcome = nil
                dismiss()
            }
            .presentationBackground(.black)
        }
        .onAppear {
            guard let identity = model.identity else { return }
            service.start(identity: identity)
        }
        .onDisappear {
            service.stop()
        }
    }

    private var closeTitle: String {
        if case .grown = service.phase { return "Not this time" }
        return "Cancel"
    }

    // MARK: - Phases

    private func waiting(title: String, detail: String) -> some View {
        VStack(spacing: 22) {
            Spacer()
            BreathingDot(diameter: 9)
            Text(title)
                .font(.system(size: 20, weight: .light, design: .serif))
                .foregroundStyle(Chrome.ink)
                .multilineTextAlignment(.center)
            Text(detail)
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Chrome.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            Spacer()
        }
        .padding(.horizontal, 46)
    }

    private func grown(_ outcome: ExchangeOutcome) -> some View {
        let genome = outcome.result.genome
        // Shown as it will be in bloom. A plant born a second ago is a speck,
        // and the point of this moment is to see what the two of you made.
        let preview = Self.bloomPreview(for: genome)

        return VStack(spacing: 0) {
            PlantSceneView(genome: genome, growth: preview, autoRotates: true)
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 10) {
                Text(genome.name.full)
                    .plantName(size: 24)
                    .foregroundStyle(Chrome.ink)
                Text("Your plant and \(outcome.peerPlantName), together")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Chrome.muted)
                Text("It will open like this in \(Int(genome.tempo.daysToBloom.rounded())) days")
                    .chromeLabel()
                    .foregroundStyle(Chrome.faint)
                    .padding(.top, 2)

                QuietButton(title: "Keep this plant", isProminent: true) {
                    noteOutcome = outcome
                }
                .padding(.top, 10)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 34)
            .padding(.bottom, 40)
        }
    }

    private func failure(_ message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Nothing took")
                .font(.system(size: 20, weight: .light, design: .serif))
                .foregroundStyle(Chrome.ink)
            Text(message)
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Chrome.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            QuietButton(title: "Try again", isProminent: true) {
                guard let identity = model.identity else { return }
                service.start(identity: identity)
            }
            Spacer()
        }
        .padding(.horizontal, 46)
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
