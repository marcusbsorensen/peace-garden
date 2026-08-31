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

                // The second thing the app explains, and it explains it
                // once. There is no flag to keep: the hint is for someone
                // who has never crossed a seed, so crossing one retires it.
                if model.hybrids.isEmpty {
                    meetHint
                        .opacity(controlsVisible ? 0 : 1)
                        .animation(Chrome.fadeIn, value: controlsVisible)
                }
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

    /// Sits under the plant until the first exchange has happened.
    private var meetHint: some View {
        VStack {
            Spacer()
            Text("Your plant can meet others if you tap their device.\nA brand new and unique seed will be formed every time.")
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Chrome.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.horizontal, 34)
                .frame(maxWidth: Chrome.readableWidth)
                .padding(.top, 52)
                .padding(.bottom, 54)
                .frame(maxWidth: .infinity)
                // The plant is framed to fill the screen, so a seedling
                // reaches the bottom of it and the hint would otherwise be
                // set over its own stem. The foot gives the words a ground.
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.72), .black.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .ignoresSafeArea(edges: .bottom)
        .allowsHitTesting(false)
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
