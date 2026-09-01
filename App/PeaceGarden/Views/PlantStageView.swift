import SwiftUI
import SeedCore

/// The main screen: your own plant, alone on black.
///
/// Nothing is on screen but the plant until the screen is tapped. The controls
/// fade in, and fade out again on their own if they are not used.
struct PlantStageView: View {
    @Environment(GardenModel.self) private var model
    /// Carried only so it can be handed to Settings, which now opens from here
    /// rather than from inside the seed modal.
    @Environment(PlaceKeeping.self) private var place
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver

    /// On a device the row is hidden until the plant is tapped, so that a
    /// plant is the only thing on screen until somebody asks for more.
    ///
    /// On a simulator it is shown from the start and never hides. The reveal
    /// is a `UITapGestureRecognizer` on the SceneKit view, and injected taps
    /// do not reach it — SpringBoard and SwiftUI buttons take them, that
    /// recogniser does not — so the row is unreachable there and Exchange
    /// with it. Compiled out of every build that runs on a phone.
#if targetEnvironment(simulator)
    @State private var controlsVisible = true
#else
    @State private var controlsVisible = false
#endif
    @State private var hideTask: Task<Void, Never>?
    @State private var showingExchange = false
    @State private var showingGarden = false
    @State private var showingSeed = false
    @State private var showingSettings = false
    /// Whether the cog has unrolled into the full control. See `tapSettings`.
    @State private var settingsExpanded = false
    /// How far down the screen the top chrome reaches, in points. The plant is
    /// framed clear of it.
    @State private var topChromeHeight: CGFloat = 0
    /// Closing the panel is a decision, so it is kept. It belongs in defaults
    /// rather than in the garden: the garden holds seeds and birthdays, and
    /// this is only a note about what one person has already read.
    @AppStorage("meetPanelClosed") private var meetPanelClosed = false

    var body: some View {
        ZStack {
            if let identity = model.identity {
                let growth = model.growth(for: identity.genome, birth: identity.birth)

                StageBackdrop(palette: identity.genome.palette, presence: growth.heightScale)
                    .ignoresSafeArea()

                PlantSceneView(
                    genome: identity.genome,
                    growth: growth,
                    topInset: topChromeHeight,
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

            // Settings arrives from the top, because that is where the cog
            // that opens it is. A sheet rises from the bottom of the screen
            // whatever opened it, which reads as the panel coming from the
            // wrong end — so this is a layer over the stage rather than a
            // presented screen, and it moves the way the eye expects.
            if showingSettings {
                SettingsView(close: { closeSettings() })
                    .environment(model)
                    .environment(place)
                    .transition(settingsTransition)
                    .zIndex(2)
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
                .environment(place)
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
        VStack(spacing: 0) {
            // Settings is a screen about your preferences, and the seed modal
            // is a screen about your seed. Neither is a sub-topic of the other,
            // so this sits in the stage chrome and appears and hides with the
            // row along the bottom — the plant is still the only thing on
            // screen until somebody asks.
            //
            // In its own band above the name rather than laid over it, so
            // however long a plant is called the two never collide.
            HStack {
                Spacer()
                Button { tapSettings() } label: {
                    ChromeIconLabel(
                        glyph: AnyShape(CogShape()),
                        title: "Settings",
                        showsTitle: settingsExpanded
                    )
                    .pressable(horizontal: settingsExpanded ? 18 : 12)
                }
                .buttonStyle(.plain)
            }
            .padding(.trailing, 12)
            .padding(.top, 10)

            VStack(spacing: 8) {
                Text(identity.genome.name.full)
                    .plantName()
                    .foregroundStyle(Chrome.ink)
                Text(growth.summary())
                    .chromeLabel()
                    .foregroundStyle(Chrome.faint)
            }
            .padding(.top, 22)
            .padding(.bottom, 14)
            .multilineTextAlignment(.center)
            // How far down the screen the words reach, handed to the scene so
            // the plant is framed into what is left rather than into the whole
            // view. Measured rather than assumed, because a long binomial wraps
            // onto a second line and takes another thirty points with it.
            //
            // Read from the row even while the chrome is hidden — it is laid
            // out either way, only its opacity changes — so the reserved band
            // is the same whether or not anybody is looking at it.
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { topChromeHeight = proxy.frame(in: .global).maxY }
                        .onChange(of: proxy.frame(in: .global).maxY) { _, new in
                            topChromeHeight = new
                        }
                }
            }

            Spacer()

            HStack(spacing: 4) {
                QuietButton(title: "Seed") { present { showingSeed = true } }
                QuietButton(title: "Meet", isProminent: true) { present { showingExchange = true } }
                QuietButton(title: "Garden") { present { showingGarden = true } }
            }
            .padding(.bottom, 34)
        }
    }

    /// Sliding down is the point, so Reduce Motion gets a crossfade rather
    /// than nothing: the panel still has to arrive.
    private var settingsTransition: AnyTransition {
        reduceMotion ? .opacity : .move(edge: .top)
    }

    /// The cog stands on its own until it is touched, and unrolls into the
    /// full control before it will open anything.
    ///
    /// It is the same bargain the rest of the stage makes — a plant and
    /// nothing else until somebody asks — held one step further for the one
    /// control that is not about the plant at all. The word is what the first
    /// touch buys: you find out what the mark does before you commit to it.
    ///
    /// With VoiceOver the two steps collapse into one. The word is already
    /// being read aloud, so the first touch would buy nothing and cost an
    /// activation.
    private func tapSettings() {
        hideTask?.cancel()
        if settingsExpanded || voiceOver {
            openSettings()
        } else {
            withAnimation(.easeInOut(duration: 0.28)) { settingsExpanded = true }
            scheduleHide()
        }
    }

    private func openSettings() {
        hideTask?.cancel()
        withAnimation(.easeInOut(duration: 0.42)) { showingSettings = true }
    }

    /// The cog rolls back up as the panel leaves, so coming back to the stage
    /// finds it as it was.
    private func closeSettings() {
        withAnimation(.easeInOut(duration: 0.36)) {
            showingSettings = false
            settingsExpanded = false
        }
    }

    /// Controls appear on a tap and see themselves out again.
    private func revealControls() {
#if targetEnvironment(simulator)
        controlsVisible = true
#else
        controlsVisible.toggle()
#endif
        scheduleHide()
    }

    private func scheduleHide() {
#if targetEnvironment(simulator)
        return
#else
        hideTask?.cancel()
        guard controlsVisible else { return }
        hideTask = Task {
            try? await Task.sleep(for: Chrome.controlsIdleTimeout)
            guard !Task.isCancelled else { return }
            controlsVisible = false
            // The cog goes back to standing alone with the rest of the chrome,
            // so the next visit starts where the last one did.
            settingsExpanded = false
        }
#endif
    }

    private func present(_ action: () -> Void) {
        hideTask?.cancel()
        action()
    }
}
