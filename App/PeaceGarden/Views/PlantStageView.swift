import SwiftUI
import SeedCore

/// The main screen: your own plant, alone on black.
///
/// Nothing is on screen but the plant until the screen is tapped. The controls
/// fade in, and fade out again on their own if they are not used.
struct PlantStageView: View {
    @Environment(GardenModel.self) private var model

    @State private var controlsVisible = false
    @State private var hideTask: Task<Void, Never>?
    @State private var showingExchange = false
    @State private var showingGarden = false
    @State private var showingSeed = false

    var body: some View {
        ZStack {
            if let identity = model.identity {
                StageBackdrop(palette: identity.genome.palette)
                    .ignoresSafeArea()

                let growth = model.growth(for: identity.genome, birth: identity.birth)

                PlantSceneView(
                    genome: identity.genome,
                    growth: growth,
                    onTap: { revealControls() }
                )
                .ignoresSafeArea()

                controls(identity: identity, growth: growth)
                    .opacity(controlsVisible ? 1 : 0)
                    .allowsHitTesting(controlsVisible)
                    .animation(Chrome.fadeIn, value: controlsVisible)
            }
        }
        // The model is passed in explicitly rather than left to propagate:
        // a presented screen that cannot find it crashes on appearance.
        .fullScreenCover(isPresented: $showingExchange) {
            ExchangeView().environment(model)
        }
        .fullScreenCover(isPresented: $showingGarden) {
            GardenView().environment(model)
        }
        .sheet(isPresented: $showingSeed) {
            SeedView()
                .environment(model)
                .presentationDetents([.medium, .large])
                .presentationBackground(.black)
        }
        .onAppear { model.refreshNow() }
    }

    @ViewBuilder
    private func controls(identity: Identity, growth: GrowthModel.State) -> some View {
        VStack {
            VStack(spacing: 8) {
                Text(identity.genome.name.full)
                    .plantName()
                    .foregroundStyle(Chrome.ink)
                Text(growth.summary())
                    .chromeLabel()
                    .foregroundStyle(Chrome.faint)
            }
            .padding(.top, 64)
            .multilineTextAlignment(.center)

            Spacer()

            HStack(spacing: 4) {
                QuietButton(title: "Seed") { present { showingSeed = true } }
                QuietButton(title: "Meet", isProminent: true) { present { showingExchange = true } }
                QuietButton(title: "Garden") { present { showingGarden = true } }
            }
            .padding(.bottom, 34)
        }
    }

    /// Controls appear on a tap and see themselves out again.
    private func revealControls() {
        controlsVisible.toggle()
        scheduleHide()
    }

    private func scheduleHide() {
        hideTask?.cancel()
        guard controlsVisible else { return }
        hideTask = Task {
            try? await Task.sleep(for: Chrome.controlsIdleTimeout)
            guard !Task.isCancelled else { return }
            controlsVisible = false
        }
    }

    private func present(_ action: () -> Void) {
        hideTask?.cancel()
        action()
    }
}
