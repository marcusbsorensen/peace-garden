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
    /// Which mark has unrolled into its word, if any. See
    /// `mark(_:_:_:isProminent:open:)`.
    ///
    /// A mark's own name rather than its word. It used to be the word — which
    /// worked while the word was English and could not survive the word being
    /// translated, since a piece of state compared against a literal is a piece
    /// of state that stops matching the moment the literal is looked up.
    @State private var expandedMark: String?
    /// Where the band at the foot begins, once it has been laid out. The plant
    /// is framed to stand just above it. See `PlantSceneView.bandTop`.
    @State private var bandTop: CGFloat?
    /// Closing the panel is a decision, so it is kept. It belongs in defaults
    /// rather than in the garden: the garden holds seeds and birthdays, and
    /// this is only a note about what one person has already read.
    @AppStorage("meetPanelClosed") private var meetPanelClosed = false
    /// Whether the plant's name and stage are drawn under it. Off leaves the
    /// plant, the light it stands in, and a row of marks — and nothing on
    /// screen in any language. See `Chrome.namesPlantKey`.
    @AppStorage(Chrome.namesPlantKey) private var namesPlant = true
    /// Whether the growth stage is drawn under the name.
    @AppStorage(Chrome.showsStageKey) private var showsStage = true
    /// How much of the row along the foot is on screen. See `StageMenuStyle`.
    @AppStorage(Chrome.menuStyleKey) private var menuStyleRaw = StageMenuStyle.hidden.rawValue
    private var menuStyle: StageMenuStyle {
        StageMenuStyle(rawValue: menuStyleRaw) ?? .hidden
    }
    /// Whether the stage turns on its own.
    @AppStorage(Chrome.turntableKey) private var turntable = true
    /// How the plant is drawn. See `StagePlantStyle`.
    @AppStorage(Chrome.plantStyleKey) private var plantStyleRaw = StagePlantStyle.full.rawValue
    /// The colour it is drawn in, where that is its whole colour.
    @AppStorage(Chrome.plantTintKey) private var plantTint = Chrome.plantTintDefault
    private var plantStyle: StagePlantStyle {
        StagePlantStyle(rawValue: plantStyleRaw) ?? .full
    }

    var body: some View {
        ZStack {
            if let identity = model.identity {
                let growth = model.growth(for: identity.genome, birth: identity.birth)

                StageBackdrop(palette: identity.genome.palette, presence: growth.heightScale)
                    .ignoresSafeArea()

                PlantSceneView(
                    genome: identity.genome,
                    growth: growth,
                    autoRotates: turntable,
                    style: plantStyle,
                    tint: Color(hex: plantTint),
                    bandTop: bandTop,
                    onTap: { revealControls() }
                )
                .ignoresSafeArea()

                // Asked for once in Settings rather than every time on the
                // stage: a row set to stay is a row that stays.
                let rowIsUp = controlsVisible || menuStyle.isAlwaysOnScreen
                controls(identity: identity, growth: growth)
                    .opacity(rowIsUp ? 1 : 0)
                    .allowsHitTesting(rowIsUp)
                    .animation(Chrome.fadeIn, value: rowIsUp)

                // The second thing the app explains, and it explains it
                // once. There is no flag to keep: the hint is for someone
                // who has never crossed a seed, so crossing one retires it.
                if model.hybrids.isEmpty, !meetPanelClosed, !menuStyle.isAlwaysOnScreen {
                    meetPanel
                        .opacity(controlsVisible ? 0 : 1)
                        .animation(Chrome.fadeIn, value: controlsVisible)
                        .transition(.opacity)
                }
            }

            // Settings rises from the foot, because that is where the cog
            // that opens it now is. A layer over the stage rather than a
            // presented screen: a sheet would leave the plant visible behind a
            // rounded card and this is a whole screen, not a card.
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
                .presentationBackground(Chrome.ground)
        }
        .onPreferenceChange(BandTopKey.self) { bandTop = $0 }
        .onAppear { model.refreshNow() }
#if DEBUG
        // A screen named on the command line, opened once. See
        // `Developer.openOnLaunch`.
        .task {
            switch Developer.shared.openOnLaunch {
            case .seed: showingSeed = true
            case .meet: showingExchange = true
            case .garden: showingGarden = true
            case .settings: openSettings()
            case nil: break
            }
            Developer.shared.openOnLaunch = nil
        }
#endif
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
                    .fill(Chrome.ground.opacity(0.66))
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
            Spacer()

            // Everything the chrome has to say is at the foot of the screen
            // now, in one band: what the plant is called, what it is doing, and
            // the four places to go.
            //
            // Three things come of that. The whole top of the screen is the
            // plant and the light it stands in, which is the only part worth
            // looking at. The plant reads as growing *out of* the band rather
            // than as floating above a caption. And every control is under a
            // thumb, which the cog in the far top corner never was.
            VStack(spacing: 0) {
                if namesPlant || showsStage {
                    VStack(spacing: 5) {
                        // Smaller than it was. At twenty-six points an italic
                        // serif binomial was the loudest thing on a screen
                        // whose subject is a plant, and it is a caption.
                        if namesPlant {
                            Text(identity.genome.name.full)
                                .plantName(size: 20)
                                .foregroundStyle(Chrome.ink)
                        }
                        if showsStage {
                            Text(verbatim: growth.caption())
                                .chromeLabel(size: 10)
                                .foregroundStyle(Chrome.faint)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 16)
                    .transition(.opacity)
                }

                HStack(spacing: 6) {
                    mark(SeedGlyph(), "seed", "Seed") { showingSeed = true }
                    // Wider than the others: the stems reach the top corners of
                    // the mark, so the word needs the extra three points that a
                    // seed or a cog does not.
                    mark(MeetGlyph(), "meet", "Meet",
                         isProminent: true, titleSpacing: 10) { showingExchange = true }
                    mark(GardenGlyph(), "garden", "Garden") { showingGarden = true }
                    mark(CogShape(), "settings", "Settings") { openSettings() }
                }
                .animation(.easeInOut(duration: 0.26), value: expandedMark)
            }
            // Measured, and handed to the scene so the plant can stand on it.
            //
            // Measured rather than counted up from the type sizes and the
            // paddings, because two of the four things in this band can be
            // turned off in Settings and the fifth is a safe area that is a
            // different height on every device.
            //
            // Reported whether or not the band is on screen. It is laid out
            // either way — only its opacity changes — so the plant is framed
            // the same in both states, and asking for the row does not resize
            // the one thing on screen that is meant to hold still.
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: BandTopKey.self,
                        value: proxy.frame(in: .global).minY
                    )
                }
            )
            .padding(.bottom, 30)
        }
    }

    /// One mark in the row along the foot.
    ///
    /// **A mark, and its word only once asked for.** The row used to be three
    /// words in three capsules, which is a menu bar; four of them would have
    /// been a menu bar that no longer fitted. Marks are the same bargain the
    /// rest of the stage already makes — nothing on screen until somebody asks
    /// — and they are the same bargain in any language, which words are not.
    ///
    /// **One word at a time, and only the one you touched.** All four unrolled
    /// together first, and four tracked-out words with their marks come to
    /// about 440 points against a phone's 402: SEED was cut off at one end and
    /// SETTINGS at the other. Shrinking the type would have bought the forty
    /// points and spent them again on the next screen size. One word is a
    /// quarter of the width and a better sentence besides — you asked what
    /// *this* mark is, and it answered.
    ///
    /// **Translation turned that from a good decision into a necessary one.**
    /// `tools/type/measure.swift` puts the four-at-once row at 449 points in
    /// English, 460 in Danish and Norwegian, 505 in Swedish, 508 in Dutch, 509
    /// in Spanish, 516 in French and 533 in Italian — a third over the screen,
    /// with no size of phone that would have taken it. One at a time leaves
    /// 207 points for a word, and the widest of the thirty-two is Swedish
    /// INSTÄLLNINGAR at 119.
    ///
    /// **Tap unrolls, tap the same one again to open; a long press opens
    /// straight away.** Two taps to reach the garden is one more than the row
    /// used to cost, and the press gives that back to anybody who has learnt
    /// the marks. A press and a tap are distinct gestures, so neither steals
    /// the other: a long press never fires the tap on release.
    ///
    /// With VoiceOver the unrolling collapses: the word is already being read
    /// aloud, so the first touch would buy nothing and cost an activation.
    private func mark(
        _ glyph: some Shape,
        _ name: String,
        _ title: LocalizedStringKey,
        isProminent: Bool = false,
        titleSpacing: CGFloat = 7,
        open: @escaping () -> Void
    ) -> some View {
        let showsTitle = menuStyle.namesEveryMark || expandedMark == name
        return ChromeIconLabel(
            glyph: AnyShape(glyph),
            title: title,
            tint: isProminent ? Chrome.ink : Chrome.muted,
            titleSpacing: titleSpacing,
            showsTitle: showsTitle,
            axis: menuStyle.namesEveryMark ? .vertical : .horizontal
        )
        .frame(maxWidth: menuStyle.namesEveryMark ? .infinity : nil)
        .pressable(
            isProminent: isProminent,
            horizontal: menuStyle.namesEveryMark ? 4 : (showsTitle ? 16 : 13)
        )
        .contentShape(Capsule())
        .onTapGesture {
            hideTask?.cancel()
            if showsTitle || voiceOver {
                present(open)
            } else {
                expandedMark = name
                scheduleHide()
            }
        }
        .onLongPressGesture(minimumDuration: 0.32) { present(open) }
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { present(open) }
    }

    /// Rising is the point — the cog is at the foot of the screen now, so the
    /// panel comes from where the mark that opened it is. Reduce Motion gets a
    /// crossfade rather than nothing: the panel still has to arrive.
    private var settingsTransition: AnyTransition {
        reduceMotion ? .opacity : .move(edge: .bottom)
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
            expandedMark = nil
        }
#if DEBUG
        // Meet an imaginary gardener, asked for on the screen that is now
        // sliding away. Presenting a full-screen cover over a layer still in
        // motion drops the transition, so this waits for the panel to be gone.
        // `ExchangeView` reads the flag itself; this only opens the door.
        if Developer.shared.wantsImaginaryMeeting {
            Task {
                try? await Task.sleep(for: .milliseconds(380))
                showingExchange = true
            }
        }
#endif
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
        // Asked for, and then kept. Somebody who has turned the row on has said
        // they would rather have it than the bare plant, and taking it away
        // again six seconds later is answering a question they did not ask.
        // Asked for, and then kept. Somebody who has set the row to stay has
        // said they would rather have it than the bare plant, and taking it
        // away six seconds later answers a question they did not ask.
        guard controlsVisible, !menuStyle.isAlwaysOnScreen else { return }
        hideTask = Task {
            try? await Task.sleep(for: Chrome.controlsIdleTimeout)
            guard !Task.isCancelled else { return }
            controlsVisible = false
            // The marks go back to standing alone with the rest of the
            // chrome, so the next visit starts where the last one did.
            expandedMark = nil
        }
#endif
    }

    private func present(_ action: () -> Void) {
        hideTask?.cancel()
        action()
    }
}

/// How far down the screen the band at the foot begins.
///
/// A preference rather than a measurement taken where it is needed: the band is
/// laid out at the foot of the stage and the plant is drawn behind the whole of
/// it, so the view that has the number is not the view that wants it.
private struct BandTopKey: PreferenceKey {
    static let defaultValue: CGFloat? = nil

    /// The topmost, which is the only band there is. `nil` comes from a stage
    /// that has not laid one out yet, and a `nil` never displaces a number.
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        guard let next = nextValue() else { return }
        value = min(value ?? next, next)
    }
}
