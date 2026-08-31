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
    /// Closing the panel is a decision, so it is kept. It belongs in defaults
    /// rather than in the garden: the garden holds seeds and birthdays, and
    /// this is only a note about what one person has already read.
    @AppStorage("meetPanelClosed") private var meetPanelClosed = false

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
                if model.hybrids.isEmpty, !meetPanelClosed {
                    meetPanel
                        .opacity(controlsVisible ? 0 : 1)
                        .animation(Chrome.fadeIn, value: controlsVisible)
                        .transition(.opacity)
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

    /// The second beat of the walk-through, as a panel someone can close.
    ///
    /// It retires itself on the first exchange, so closing it is only for
    /// someone who has read it and wants their plant back.
    private var meetPanel: some View {
        VStack {
            Spacer()
            VStack(spacing: 16) {
                Text("Your plant can meet others if you tap their device. A brand new and unique seed will be formed every time.")
                    .font(.system(size: 17, weight: .light))
                    .foregroundStyle(Chrome.ink.opacity(0.84))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)

                QuietButton(title: "Close") {
                    withAnimation(Chrome.fadeIn) { meetPanelClosed = true }
                }
            }
            .padding(.horizontal, 26)
            .padding(.top, 26)
            .padding(.bottom, 10)
            .frame(maxWidth: Chrome.readableWidth)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.black.opacity(0.66))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Chrome.hairline, lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
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
